import { ProblemView } from "../components/practice/ProblemView";
import { useEffect, useMemo, useState } from "react";
import { useApp } from "../app/AppState";
import { gradeOf } from "../curriculum/grades";
import { requireLesson } from "../curriculum/registry";
import { lastScore } from "../engine/mastery/progress";
import { Diagram } from "../components/diagrams/Diagram";
import { BuildUp } from "../components/BuildUp";
import type { Rng } from "../curriculum/generators/rng";
import type { AnyLesson } from "../curriculum/schemas/lesson";
import { MathLine, pictureSettlesIn, Rich } from "../components/primitives/MathLine";
import { Marks } from "../components/Masters";
import { dressStatement, partsLook, toneMath, tonesOf } from "../components/primitives/statement";
import type { Explanation } from "../explanations/schema";

/** the model's Watch one beat */
const PLAY_MS = 1300;
/** once a beat's picture has come in, how long it stays to be read before the next beat */
const READ_MS = 500;
import { reduceMotion } from "../app/transition";
import { spendHandOff, takeHandOff } from "../app/preview";
import { readAloudOn, readSettings, speak } from "../app/settings";
import { toPlainText, type MathText } from "../curriculum/schemas/math-text";

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

/** True when the narration already reads out the step's math, so it isn't shown twice. */
export function saysMath(narration: string, math: MathText): boolean {
  const norm = (t: string) => t.replace(/\*\*/g, "").replace(/\s+/g, " ").trim().toLowerCase();
  const m = norm(toPlainText(math));
  return !!m && norm(narration).includes(m);
}

/** Which beat a timeline position belongs to: done, playing now, or still to come. */
export const beatState = (beatAt: number, at: number) => (beatAt < at ? "done" : beatAt === at ? "now" : "later");

/**
 * The lesson: the problem, its picture and its narration, all from one explanation model.
 * Each "Next" moves one state along the timeline; the picture, the highlighted beat and the dots follow it.
 */
export function Learn({ lessonId }: { lessonId: string }) {
  const { progress, startLesson, deps } = useApp();
  const lesson = requireLesson(lessonId);
  // every visit opens on a fresh problem; the reference problem is only the fallback
  const fresh = () => firstExample(lesson, deps().rng);
  // the first visit opens on the problem the lesson preview showed, when there was one
  const opening = () => { const p = takeHandOff(lesson.id); return p === undefined ? fresh() : p; };
  const [example, setExample] = useState<unknown>(opening);
  useEffect(() => spendHandOff(lesson.id), [lesson.id]);
  const [shownFor, setShownFor] = useState(lesson.id);
  const [at, setAt] = useState(0);
  // it plays on its own as soon as it opens (v2): a child watches one solved before trying
  const [playing, setPlaying] = useState(true);
  if (shownFor !== lesson.id) { setShownFor(lesson.id); setExample(opening()); setAt(0); setPlaying(false); }

  const ex: Explanation = useMemo(() => lesson.explain(example, lesson.answers(example)), [lesson, example]);
  const last = ex.timeline.length - 1, finished = at >= last;
  // the statement with its parts in their picture colours and the unknown boxed; the steps colour the same numbers
  const look = partsLook(ex.diagram);
  const statement = useMemo(() => dressStatement(ex.statement, look), [ex, look]);
  const tones = useMemo(() => tonesOf(statement), [statement]);
  // read aloud: the problem first, then each step as it plays
  const readAloud = readAloudOn(readSettings(progress.settings), lesson.grade);
  useEffect(() => {
    if (!readAloud) return;
    // every line that appears on this beat (several can share one, and state-0 lines show with the problem)
    const lines = ex.steps.filter(s => s.state === at).map(b => `${toPlainText(b.math)}. ${b.narration.replace(/[*_]/g, "")}`);
    const text = [at === 0 ? `${ex.heading}. ${toPlainText(ex.statement)}` : "", ...lines].filter(Boolean).join(" ");
    if (text) speak(text);
  }, [at, ex, readAloud]);

  useEffect(() => {
    if (!playing) return;
    if (finished) { setPlaying(false); return; }
    // a beat lasts the model's beat, or until the picture's parts for it have all come in and can be read (a beat cut short
    // would blink its hops or its ring out half drawn), whichever is longer
    const stage = document.querySelector(".v-learn .v-stage");
    const settle = stage ? pictureSettlesIn(stage) : 0;
    const t = setTimeout(() => setAt(a => Math.min(last, a + 1)), Math.max(PLAY_MS, settle ? settle + READ_MS : 0));
    return () => clearTimeout(t);
  }, [playing, at, finished, last]);

  const sc = lastScore(progress, lesson.id);
  const low = sc != null && sc <= 1;

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

  // the picture starts from its first beat and only ever builds forward on Play; showing the finished picture first
  // made every Play un-build it in reverse before building it again (G 2026-10-06: the glitch at the start of most
  // diagrams). Without motion, playing jumps straight to the end.
  const shownAt = reduceMotion() && playing ? last : at;
  // v2 (G 2026-10-13): the same workspace as practice. The picture builds on the stage while the steps write themselves
  // on the right, one worked line at a time; then Watch again or Try one
  // every worked line is there from the start, the ones still to come faint (v2 spec L3, like the model); each lights up
  // on its beat, and a state-0 line is part of the starting picture
  const lines = ex.steps;
  // the step bar's marks: one per worked line, the newest solid and long
  const shown = lines.filter(st => st.state <= shownAt).length;
  return (
    <div className={`o-state prac v-prac v-learn parts-${look}`}>
      <section className="o-panel v-stage" aria-label="Problem">
        <div className="v-prob pprob"><ProblemView lessonId={lesson.id} problem={example} story={false} solved={finished} part="text" /></div>
        {ex.diagram && (
          <div className="o-art v-ppic"><div className="viz"><Diagram diagram={ex.diagram} timeline={ex.timeline} at={shownAt} fit /></div></div>
        )}
      </section>
      <section className="o-panel v-solve v-lside" aria-label="Watch one">
        <div className="v-steps"><span className="n">Watch one</span><Marks n={lines.length} on={Math.max(0, shown - 1)} now={shown - 1} /></div>
        {ex.idea?.[0] && <p className="v-idea"><Rich text={ex.idea[0]} /></p>}
        {/* every worked line is laid out from the start; each one rises in on its beat (the model's chips) */}
        <ol className="v-wl" aria-live="polite">
          {lines.map(st => (
            <li key={st.id} className={st.state > shownAt ? "later" : undefined} aria-hidden={st.state > shownAt || undefined}>
              <MathLine math={toneMath(st.math, tones)} /><small><Rich text={st.narration} tones={tones} /></small></li>
          ))}
        </ol>
        {low && <BuildUp lessonId={lesson.id} />}
        <div className="o-row v-lbtns">
          {/* the model's two buttons, from the start (no Show all): Watch again plays a fresh one from its first beat */}
          <button className="o-btn" onClick={() => { setExample(fresh()); setAt(0); setPlaying(true); }}>Watch again</button>
          <button className="o-btn fill" onClick={() => startLesson(lesson.id)}>Try one</button>
        </div>
      </section>
      <span className="visually-hidden">{gradeOf(lesson.grade).name}</span>
    </div>
  );
}
