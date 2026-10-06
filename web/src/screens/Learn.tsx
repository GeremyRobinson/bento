import { Pill } from "../components/primitives/Pill";
import { useEffect, useMemo, useState } from "react";
import { useApp } from "../app/AppState";
import { gradeOf } from "../curriculum/grades";
import { requireLesson } from "../curriculum/registry";
import { HELP_TIERS, tierFor } from "../engine/adaptive-help/policy";
import { LEVELS } from "../engine/mastery/levels";
import { lastScore } from "../engine/mastery/progress";
import { when } from "../app/format";
import { Diagram } from "../components/diagrams/Diagram";
import { entriesInGrade } from "../app/curriculum";
import { BuildUp } from "../components/BuildUp";
import type { Rng } from "../curriculum/generators/rng";
import type { AnyLesson } from "../curriculum/schemas/lesson";
import { Chevron } from "../components/primitives/icons";
import { FitScreen } from "../components/screen/Screen";
import { MathLine, Rich } from "../components/primitives/MathLine";
import { ScoreChip } from "../components/primitives/Score";
import type { Explanation } from "../explanations/schema";

const PLAY_MS = 1800;
import { reduceMotion } from "../app/transition";
import { spendHandOff, takeHandOff } from "../app/preview";
import { readAloudOn, readSettings, speak } from "../app/settings";
import { toPlainText } from "../curriculum/schemas/math-text";

/** A freshly generated problem for the lesson; the reference problem only if generating fails. */
export function firstExample(lesson: AnyLesson, rng: Rng): unknown {
  try {
    const p = lesson.generate(rng, 0);
    lesson.explain(p, lesson.answers(p));
    return p;
  } catch {
    return lesson.reference;
  }
}

/** Which beat a timeline position belongs to: done, playing now, or still to come. */
export const beatState = (beatAt: number, at: number) => (beatAt < at ? "done" : beatAt === at ? "now" : "later");

/**
 * The lesson: the problem, its picture and its narration, all from one explanation model.
 * Each "Next" moves one state along the timeline; the picture, the highlighted beat and the dots follow it.
 */
export function Learn({ lessonId }: { lessonId: string }) {
  const { progress, reports, go, startLesson, deps } = useApp();
  const lesson = requireLesson(lessonId);
  // every visit opens on a fresh problem; the reference problem is only the fallback
  const fresh = () => firstExample(lesson, deps().rng);
  // the first visit opens on the problem the lesson preview showed, when there was one
  const opening = () => { const p = takeHandOff(lesson.id); return p === undefined ? fresh() : p; };
  const [example, setExample] = useState<unknown>(opening);
  useEffect(() => spendHandOff(lesson.id), [lesson.id]);
  const [shownFor, setShownFor] = useState(lesson.id);
  const [at, setAt] = useState(0);
  const [playing, setPlaying] = useState(false);
  if (shownFor !== lesson.id) { setShownFor(lesson.id); setExample(opening()); setAt(0); setPlaying(false); }

  const ex: Explanation = useMemo(() => lesson.explain(example, lesson.answers(example)), [lesson, example]);
  const last = ex.timeline.length - 1, finished = at >= last;
  // read aloud: the problem first, then each step as it plays
  const readAloud = readAloudOn(readSettings(progress.settings), lesson.grade);
  useEffect(() => {
    if (!readAloud) return;
    const beat = ex.steps.find(s => s.state === at);
    const text = at === 0 ? `${ex.heading}. ${toPlainText(ex.statement)}` : beat ? `${toPlainText(beat.math)}. ${beat.narration.replace(/[*_]/g, "")}` : "";
    if (text) speak(text);
  }, [at, ex, readAloud]);

  useEffect(() => {
    if (!playing) return;
    if (finished) { setPlaying(false); return; }
    const t = setTimeout(() => setAt(a => Math.min(last, a + 1)), PLAY_MS);
    return () => clearTimeout(t);
  }, [playing, at, finished, last]);

  const sc = lastScore(progress, lesson.id), rep = reports[lesson.id], tier = tierFor(sc);
  const low = sc != null && sc <= 1;
  const all = entriesInGrade(lesson.grade), place = all.findIndex(c => c.id === lesson.id);
  const unit = all.filter(c => (c.unit || "") === (all[place]?.unit || ""));
  const page = unit.findIndex(c => c.id === lesson.id);

  const step = (d: 1 | -1) => { setPlaying(false); setAt(a => Math.max(0, Math.min(last, a + d))); };
  // arrow keys and a sideways swipe move through the explanation, like the current app's lesson cards
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.metaKey || e.ctrlKey || e.altKey) return;
      if (e.key === "ArrowRight") step(1); else if (e.key === "ArrowLeft") step(-1);
    };
    let touch: { x: number; y: number } | null = null;
    const onStart = (e: TouchEvent) => { if (e.touches.length === 1) touch = { x: e.touches[0]!.clientX, y: e.touches[0]!.clientY }; };
    const onEnd = (e: TouchEvent) => {
      if (!touch) return;
      const dx = e.changedTouches[0]!.clientX - touch.x, dy = e.changedTouches[0]!.clientY - touch.y; touch = null;
      if (Math.abs(dx) > 60 && Math.abs(dx) > Math.abs(dy) * 1.5) step(dx < 0 ? 1 : -1);
    };
    addEventListener("keydown", onKey);
    document.addEventListener("touchstart", onStart, { passive: true });
    document.addEventListener("touchend", onEnd, { passive: true });
    return () => { removeEventListener("keydown", onKey); document.removeEventListener("touchstart", onStart); document.removeEventListener("touchend", onEnd); };
  });

  const now = ex.steps.find(st => st.state === at);
  // the picture starts from its first beat and only ever builds forward on Play; showing the finished picture first
  // made every Play un-build it in reverse before building it again (G 2026-10-06: the glitch at the start of most
  // diagrams). Without motion, playing jumps straight to the end.
  const shownAt = reduceMotion() && playing ? last : at;
  return (
    <FitScreen className="lscreen">
      {/* the brief intro: what this picture is about, then the steps that explain it, each one tied to the picture */}
      <section className="lintro">
        <p className="k">{lesson.unit || gradeOf(lesson.grade).name} · lesson {page + 1} of {unit.length}
          {sc != null && <> · last <ScoreChip n={sc} /></>}</p>
        <h1 className={/[=²³√ⁿ₀-₉]/.test(ex.heading) ? "formula" : undefined}>{ex.heading}</h1>
        {ex.idea?.slice(0, 2).map((t, i) => <p key={i} className="idea"><Rich text={t} /></p>)}
        <ol className="beats" aria-live="polite">
          {ex.steps.map((st, i) => (
            <li key={st.id} className="beat" data-state={beatState(st.state, at)}>
              <button disabled={st.state === at} onClick={() => { setPlaying(false); setAt(st.state); }} aria-label={`Go to step ${i + 1}`}>
                <span className="badge">{i + 1}</span>
                <span className="say"><MathLine math={st.math} /><span><Rich text={st.narration} /></span></span>
              </button>
            </li>
          ))}
        </ol>
        {finished && <p className="lhelp">That's the whole problem. Your turn.</p>}
        {low && <BuildUp lessonId={lesson.id} />}
        {sc != null && <p className="lhelp">Help in practice: <b>{HELP_TIERS[tier]}</b></p>}
        {rep && <button className="tlink" onClick={() => go({ name: "report", key: rep.key })}>Last time: {LEVELS[rep.level]}, {when(rep.date)} ›</button>}
      </section>
      {/* the hero: the problem and its picture, as big as the screen allows */}
      <figure className="lshero">
        <div className="lmath"><MathLine math={ex.statement} /></div>
        {ex.diagram && (
          <div className={ex.diagram.kind === "chain" ? "lpic flow" : "lpic"}>
            <div className="viz"><Diagram diagram={ex.diagram} timeline={ex.timeline} at={shownAt} /></div>
          </div>
        )}
        {/* on a narrow screen only the step being shown sits under the picture */}
        <p className="lnow" aria-hidden>{now ? <><MathLine math={now.math} /> <Rich text={now.narration} /></> : ex.caption ? <Rich text={ex.caption} /> : null}</p>
        {ex.caption && <figcaption className="caption muted"><Rich text={ex.caption} /></figcaption>}
      </figure>
      {/* the controls float under it all: back a step, where you are, and the one thing to do next */}
      <div className="lctl">
        <button className="icon" disabled={at === 0} onClick={() => step(-1)} aria-label="Back a step"><Chevron dir="left" /></button>
        <span className="ldots" aria-label={`Step ${Math.max(1, ex.steps.findIndex(st => st.state === at) + 1)} of ${ex.steps.length}`}>
          {ex.steps.map(st => <i key={st.id} className={beatState(st.state, at)} />)}
        </span>
        {finished ? (
          <>
            <Pill onClick={() => { setExample(fresh()); setAt(0); }}>Show another</Pill>
            <Pill go onClick={() => startLesson(lesson.id)}>Your turn ›</Pill>
          </>
        ) : (
          <>
            <Pill onClick={() => { setPlaying(false); setAt(last); }}>Show all</Pill>
            {!playing && at === 0
              ? <Pill go onClick={() => { setAt(1); setPlaying(true); }}>Play</Pill>
              : <Pill go onClick={() => { setPlaying(false); setAt(a => Math.min(last, a + 1)); }}>Next</Pill>}
          </>
        )}
      </div>
      <span className="visually-hidden">{gradeOf(lesson.grade).name}</span>
    </FitScreen>
  );
}
