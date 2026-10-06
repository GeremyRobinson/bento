import { Pill } from "../components/primitives/Pill";
import { useEffect, useMemo, useState } from "react";
import { useApp } from "../app/AppState";
import { gradeOf } from "../curriculum/grades";
import { lessonsInGrade, requireLesson } from "../curriculum/registry";
import { HELP_TIERS, tierFor } from "../engine/adaptive-help/policy";
import { LEVELS } from "../engine/mastery/levels";
import { lastScore } from "../engine/mastery/progress";
import { when } from "../app/format";
import { Diagram } from "../components/diagrams/Diagram";
import { entriesInGrade, isReady } from "../app/curriculum";
import { BuildUp } from "../components/BuildUp";
import type { Rng } from "../curriculum/generators/rng";
import type { AnyLesson } from "../curriculum/schemas/lesson";
import { Chevron } from "../components/primitives/icons";
import { MathLine, Rich } from "../components/primitives/MathLine";
import { ScoreChip } from "../components/primitives/Score";
import type { Explanation } from "../explanations/schema";

const PLAY_MS = 1800;
/** the last lesson page shown, so the next one can glide its pill over from there */
let lastPage: { chapter: string; i: number } | null = null;
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

  const grade = lessonsInGrade(lesson.grade), k = grade.indexOf(lesson);
  const prev = grade[k - 1], next = grade[k + 1];
  const sc = lastScore(progress, lesson.id), rep = reports[lesson.id], tier = tierFor(sc);
  const low = sc != null && sc <= 1;
  const all = entriesInGrade(lesson.grade), place = all.findIndex(c => c.id === lesson.id);
  const unit = all.filter(c => (c.unit || "") === (all[place]?.unit || ""));
  // the pill for this lesson glides over from the one you came from, like turning a slide
  const page = unit.findIndex(c => c.id === lesson.id), chapter = all[place]?.unit || "";
  const [shownPage, setShownPage] = useState(() => lastPage && lastPage.chapter === chapter && !reduceMotion() ? lastPage.i : page);
  useEffect(() => {
    lastPage = { chapter, i: page };
    const t = requestAnimationFrame(() => setShownPage(page));
    return () => cancelAnimationFrame(t);
  }, [chapter, page]);

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

  return (
    <>
      <div className="bar lbar">
        <Pill circ disabled={!prev} onClick={() => prev && go({ name: "learn", lessonId: prev.id }, "prev")} aria-label="Previous lesson"><Chevron dir="left" /></Pill>
        <span className="dots-nav grow" role="group" aria-label={`Lesson ${unit.indexOf(all[place]!) + 1} of ${unit.length} in ${all[place]?.unit || gradeOf(lesson.grade).name}`}>
          {unit.map((c, i) => (
            <button key={c.id} className={`dot ${i === shownPage ? "busy" : lastScore(progress, c.id) != null ? "ok" : ""}`} disabled={c.id === lesson.id || !isReady(c.id)}
              onClick={() => go({ name: "learn", lessonId: c.id }, i < shownPage ? "prev" : "next")} aria-label={c.title} aria-current={c.id === lesson.id ? "page" : undefined} />
          ))}
        </span>
        <Pill className="pbtn" onClick={() => startLesson(lesson.id)}>Practice</Pill>
        <Pill circ disabled={!next} onClick={() => next && go({ name: "learn", lessonId: next.id }, "next")} aria-label="Next lesson"><Chevron dir="right" /></Pill>
      </div>
      <div className="blearn">
        <section className="panel learn walk">
          <div className="card">
            <h2 className={`label${/[=²³√ⁿ₀-₉]/.test(ex.heading) ? " formula" : ""}`}>{ex.heading}</h2>
            {ex.idea?.map((t, i) => <p key={i} className="idea"><Rich text={t} /></p>)}
            <div className="math"><MathLine math={ex.statement} /></div>
            {ex.diagram && <Diagram diagram={ex.diagram} timeline={ex.timeline} at={at === 0 || (reduceMotion() && playing) ? last : at} />}
            {ex.caption && <p className="caption muted"><Rich text={ex.caption} /></p>}
            <ol className="beats" aria-live="polite">
              {ex.steps.map((s, i) => (
                <li key={s.id} className="beat" data-state={beatState(s.state, at)}>
                  <button disabled={s.state === at} onClick={() => { setPlaying(false); setAt(s.state); }} aria-label={`Go to step ${i + 1}`}>
                    <span className="badge">{i + 1}</span>
                    <span className="say"><MathLine math={s.math} /><span><Rich text={s.narration} /></span></span>
                  </button>
                </li>
              ))}
            </ol>
            {(finished || at === 0) && <p className="note">{finished ? "That's the whole problem. Your turn." : ex.diagram?.kind === "areaModel" ? "Tap Play to watch it split up." : "Tap Play to watch it step by step."}</p>}
          </div>
          <div className="actions" style={{ justifyContent: "space-between" }}>
            <Pill disabled={at === 0} onClick={() => step(-1)}>Back</Pill>
            <span className="actions">
              {finished ? (
                <>
                  <Pill onClick={() => { setExample(fresh()); setAt(0); }}>Show another</Pill>
                  <Pill go onClick={() => startLesson(lesson.id)}>Start practice</Pill>
                </>
              ) : (
                <>
                  <Pill onClick={() => { setPlaying(false); setAt(last); }}>Show all</Pill>
                  {!playing && at === 0
                    ? <Pill go onClick={() => { setAt(1); setPlaying(true); }}>Play</Pill>
                    : <Pill go onClick={() => { setPlaying(false); setAt(a => Math.min(last, a + 1)); }}>Next</Pill>}
                </>
              )}
            </span>
          </div>
        </section>
        <aside className="lside">
          <section className="tile lmap">
            <span className="k">{lesson.unit || gradeOf(lesson.grade).name} · lesson {place + 1} of {all.length}</span>
            <div className="outline">
              {unit.map(c => {
                const n = all.indexOf(c) + 1, here = c.id === lesson.id, s = lastScore(progress, c.id);
                return (
                  <button key={c.id} className={here ? "on" : s != null ? "seen" : ""} disabled={here || !isReady(c.id)}
                    onClick={() => go({ name: "learn", lessonId: c.id }, all.indexOf(c) < place ? "prev" : "next")}>
                    <span className="badge">{n}</span><span className="name">{c.title}</span>
                  </button>
                );
              })}
            </div>
            <Pill go onClick={() => startLesson(lesson.id)}>Start practice ›</Pill>
          </section>
          {rep && (
            <button className="lesson" onClick={() => go({ name: "report", key: rep.key })}>
              <ScoreChip n={rep.level} /><span className="name">Last time: {LEVELS[rep.level]}</span><span className="muted">{when(rep.date)} ›</span>
            </button>
          )}
          {sc != null && (
            <section className="tile helptile">
              <span className="k">Help in practice</span><b>{HELP_TIERS[tier]}</b>
              <span className="muted">{["It fades as your score grows.", "Score 3 to switch to final answers only.", "Miss one and the steps come back."][tier]}</span>
            </section>
          )}
          {low && <BuildUp lessonId={lesson.id} />}
          <span className="visually-hidden">{gradeOf(lesson.grade).name}</span>
        </aside>
      </div>
    </>
  );
}
