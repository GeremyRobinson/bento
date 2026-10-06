// A Bento² lesson: one loop, Play → Guess → Name it → Work it → Use it, with an optional Deeper layer. The lesson
// card sits beside its live picture (on a phone, under it); the stages are tabs the learner can take in any order.
// Guesses are recorded but never scored; Work it's steps are typed, with named slips; Use it saves to the Number shelf
// or opens the project. Nothing on this screen is a grade, a score or a level.
import { useEffect, useMemo, useRef, useState, type CSSProperties } from "react";
import { useApp } from "../../app/AppState";
import { FitScreen } from "../../components/screen/Screen";
import { Pill } from "../../components/primitives/Pill";
import { Rich } from "../../components/primitives/MathLine";
import { reduceMotion } from "../../app/transition";
import { STAGES, STAGE_NAMES, type AnyB2Lesson, type B2Step, type SceneRef, type Stage } from "../model";
import { isDone, markDone, recordGuess, recordSlip, recordSolved } from "../progress";
import { lessonNumber, projectById, trackByPickerId } from "../registry";
import { sceneByName, type SceneValues } from "../scenes";
import { checkB2Step, formatAnswer } from "../steps";
import { unitFor } from "../make";
import { openTool, useB2 } from "../ui/useB2";
import { toolMeta } from "../tools/ToolShell";
import { shelfText } from "../tools/ShelfTool";

// before the guess is locked in, every picture stays quiet: no readout, label or count may give the answer away
const GUESSING: SceneValues = { quiet: true };

type Fb = { tone: "slip" | "generic" | "soft"; text: string } | null;
const KEYS = ["7", "8", "9", "back", "4", "5", "6", "/", "1", "2", "3", "−", "0", ".", "next"];
const KEY_LABEL: Record<string, string> = { back: "⌫", next: "⇥" };
const KEY_ARIA: Record<string, string> = { back: "Erase", next: "Next box", "/": "Fraction bar", "−": "Negative", ".": "Decimal point" };

/** The live picture for a stage: its scene, keyed by its numbers so new numbers start it fresh. */
function Picture({ scene, extra, marker, onMarker, place = "lesson" }: { scene: SceneRef; extra?: SceneValues; marker?: [number, number]; onMarker?: (p: [number, number]) => void; place?: "lesson" | "project" }) {
  const C = sceneByName(scene.scene);
  const props = { ...(scene.props ?? {}), ...(extra ?? {}) };
  if (!C) return null;
  return <C key={`${scene.scene}:${JSON.stringify(props)}`} props={props} place={place} marker={marker} onMarker={onMarker} />;
}

export function LessonScreen({ trackId, lessonId }: { trackId: string; lessonId: string }) {
  const { go, deps } = useApp();
  const { b2, updateB2, now } = useB2();
  const track = trackByPickerId(trackId)!;
  const lesson = track.lessons.find(l => l.id === lessonId)! as AnyB2Lesson;
  const [stage, setStage] = useState<Stage>("play");
  const [deeper, setDeeper] = useState<"open" | "closing" | null>(null);
  // on a phone a project's Use it opens the project full screen, then comes back to the lesson card
  const [projOpen, setProjOpen] = useState(false);
  useEffect(() => setProjOpen(false), [stage]);

  // Guess: what the learner predicts; the reveal shows the answer in the picture. Recorded, never scored.
  const gs = lesson.guess;
  const [guess, setGuess] = useState<number | [number, number] | null>(gs.kind === "slider" ? gs.start ?? (gs.min + gs.max) / 2 : gs.kind === "point" ? gs.start : null);
  const [revealed, setRevealed] = useState(false);
  const lockIn = () => {
    if (guess == null || revealed) return;
    const right = gs.kind === "choice" ? guess === gs.answer
      : gs.kind === "slider" ? Math.abs((guess as number) - gs.answer) <= gs.near
        : Math.hypot((guess as [number, number])[0] - gs.answer[0], (guess as [number, number])[1] - gs.answer[1]) <= gs.near;
    updateB2(b => recordGuess(b, lesson.id, right, now()));
    setRevealed(true);
  };
  const guessText = (g: typeof guess) => g == null ? "" : gs.kind === "choice" ? gs.options[g as number]! : gs.kind === "slider" ? `${gs.format ? gs.format(g as number) : g}${gs.unit ? ` ${gs.unit}` : ""}` : `(${(g as number[]).join(", ")})`;

  // Work it: a problem from the seeded generator; the first ones (index < 3) are the friendly ones
  const [wi, setWi] = useState(0);
  const [problem, setProblem] = useState<unknown>(() => lesson.workIt.generate(deps().rng, 0));
  const steps = useMemo(() => lesson.workIt.steps(problem), [lesson, problem]);
  const [k, setK] = useState(0);
  const [boxes, setBoxes] = useState<string[]>([]);
  const [active, setActive] = useState(0);
  const [fb, setFb] = useState<Fb>(null);
  const [misses, setMisses] = useState(0);
  const [hint, setHint] = useState(false);
  const step: B2Step | undefined = steps[k];
  const solved = k >= steps.length;
  useEffect(() => { setBoxes(step ? step.answer.map(() => "") : []); setActive(0); setFb(null); setMisses(0); setHint(false); }, [k, problem]); // eslint-disable-line react-hooks/exhaustive-deps
  // the step you're on stays in view as the steps go by
  useEffect(() => { document.querySelector(".b2steps>li[data-state=\"now\"]")?.scrollIntoView?.({ block: "nearest" }); }, [k, problem]);
  const another = () => { const i = wi + 1; setWi(i); setProblem(lesson.workIt.generate(deps().rng, i)); setK(0); };
  const advance = () => {
    const next = k + 1;
    setK(next);
    if (next >= steps.length) updateB2(b => recordSolved(b, lesson.id, now()));
  };
  const check = (typed?: (string | number)[]) => {
    if (!step) return;
    const r = checkB2Step(step, typed ?? boxes);
    if (r.ok) { advance(); return; }
    if (r.soft) { setFb({ tone: "soft", text: r.message }); return; }
    setMisses(m => m + 1);
    updateB2(b => recordSlip(b, lesson.id, r.kind, now()));
    setFb({ tone: r.generic ? "generic" : "slip", text: r.message });
  };
  const showMe = () => { if (!step) return; if (!step.choices) setBoxes(step.answer.map(a => formatAnswer(a, step.form))); advance(); };
  const press = (key: string) => {
    if (!step || step.choices) return;
    setFb(f => (f?.tone === "soft" ? null : f));
    if (key === "next") { setActive(a => (a + 1) % step.answer.length); return; }
    setBoxes(bs => bs.map((b, i) => (i !== active ? b : key === "back" ? b.slice(0, -1) : key === "−" ? (b.startsWith("−") ? b.slice(1) : `−${b}`) : b.length < 14 ? b + key : b)));
  };
  // a keyboard works too: digits, minus, point, slash, Backspace, Tab for the next box, Enter to check
  const keyRef = useRef({ press, check, stage, solved });
  keyRef.current = { press, check, stage, solved };
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const { press: p, check: c, stage: s, solved: done } = keyRef.current;
      if (s !== "work" || done || e.metaKey || e.ctrlKey || e.altKey) return;
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement || e.target instanceof HTMLSelectElement) return;
      const map: Record<string, string> = { Backspace: "back", "-": "−", ".": ".", "/": "/", Tab: "next" };
      const key = /^\d$/.test(e.key) ? e.key : map[e.key];
      if (key) { e.preventDefault(); p(key); } else if (e.key === "Enter") { e.preventDefault(); c(); }
    };
    addEventListener("keydown", onKey);
    return () => removeEventListener("keydown", onKey);
  }, []);

  // reaching Use it finishes the lesson: its ability shows on the track
  useEffect(() => { if (stage === "use" && !isDone(b2, lesson.id)) updateB2(b => markDone(b, lesson.id, now())); }, [stage]); // eslint-disable-line react-hooks/exhaustive-deps
  useEffect(() => {
    if (deeper !== "closing") return;
    const t = setTimeout(() => setDeeper(null), reduceMotion() ? 0 : 240);
    return () => clearTimeout(t);
  }, [deeper]);

  const at = STAGES.indexOf(stage);
  const nextStage = STAGES[at + 1];
  const project = lesson.useIt.project ? projectById(track, lesson.useIt.project) : undefined;
  const saves = lesson.useIt.saves;
  const savedNow = saves && saves.name in b2.shelf;

  // the picture for each stage
  let picture;
  if (stage === "guess") {
    const marker: [number, number] | undefined = gs.kind === "point" ? (guess as [number, number]) : gs.kind === "slider" && guess != null ? [guess as number, 0] : undefined;
    picture = <Picture scene={gs} extra={revealed ? { quiet: false, hide: false, hideEvent: false, ...gs.revealProps } : GUESSING} marker={marker} onMarker={gs.kind === "point" && !revealed ? p => setGuess(p) : undefined} />;
  } else if (stage === "work") picture = <Picture scene={lesson.workIt.scene?.(problem) ?? lesson.play} />;
  else if (stage === "use") picture = project ? <Picture scene={project.scene} place="project" /> : <Picture scene={lesson.useIt.scene ?? lesson.play} />;
  else picture = <Picture scene={lesson.play} />;

  const tools = (
    <div className="b2chips">
      <small>Open</small>
      {lesson.tools.map(t => { const m = toolMeta(t, track); return <button type="button" key={t} className="b2chip" onClick={() => openTool(t)}>{m?.name ?? t}{m?.star ? " ★" : ""}</button>; })}
    </div>
  );

  let body;
  if (stage === "play") body = <>
    <p className="b2say"><Rich text={lesson.play.say} /></p>
    <p className="b2small">Everything in the picture is live: drag it, or use the sliders.</p>
    {tools}
  </>;
  else if (stage === "guess") body = <>
    <p className="b2say"><Rich text={gs.ask} /></p>
    {gs.kind === "choice" && (
      <div className="b2choices" role="radiogroup" aria-label="Your guess">
        {gs.options.map((o, i) => <button type="button" key={o} role="radio" aria-checked={guess === i} disabled={revealed} className={`b2choice${guess === i ? " on" : ""}`} onClick={() => setGuess(i)}>{o}</button>)}
      </div>
    )}
    {gs.kind === "slider" && (
      <label className="b2slider big">
        <span className="b2sl"><span>Your guess</span><b>{guessText(guess)}</b></span>
        <input type="range" min={gs.min} max={gs.max} step={gs.step} value={guess as number} disabled={revealed} aria-valuetext={guessText(guess)} onChange={e => setGuess(Number(e.currentTarget.value))} />
      </label>
    )}
    {gs.kind === "point" && <p className="b2small">Drag the marker in the picture. Now at <b>{guessText(guess)}</b>.</p>}
    {revealed && <div className="b2reveal" aria-live="polite"><p className="b2small">Your guess: <b>{guessText(guess)}</b></p><p><Rich text={gs.reveal} /></p></div>}
  </>;
  else if (stage === "name") body = <>
    {lesson.nameIt.say.map((t, i) => <p key={i} className="b2say"><Rich text={t} /></p>)}
    <div className="b2formula" aria-label="The formula">{lesson.nameIt.formula.map((f, i) => <span key={i}>{f}</span>)}</div>
  </>;
  else if (stage === "work") body = <>
    <ol className="b2steps">
      {steps.map((s, i) => (
        <li key={`${wi}-${s.id}`} data-state={i < k ? "done" : i === k ? "now" : "later"}>
          <span className="badge">{i < k ? "✓" : i + 1}</span>
          {i < k ? <span className="b2done"><Rich text={s.done} /></span>
            : i === k ? (
              <div className="b2now">
                <b><small className="b2of">Step {i + 1} of {steps.length}</small>{s.label}</b>
                {s.ask && <span className="b2ask"><Rich text={s.ask} /></span>}
                {s.choices
                  ? <div className="b2choices">{s.choices.map((c, j) => <button type="button" key={c} className="b2choice" onClick={() => check([j])}>{c}</button>)}</div>
                  : <div className="b2boxes">
                    {s.answer.map((_, j) => (
                      <button type="button" key={j} className={`b2box${j === active ? " on" : ""}${fb && fb.tone !== "soft" ? " no" : ""}`} onClick={() => setActive(j)}
                        aria-label={`${s.boxes?.[j] ?? s.label}${s.form === "fraction" ? ", a fraction" : typeof s.form === "number" ? `, to ${s.form} ${s.form === 1 ? "place" : "places"}` : ""}: ${boxes[j] || "empty"}`}>
                        {s.boxes && <small>{s.boxes[j]}</small>}
                        <span>{boxes[j] || " "}</span>
                      </button>
                    ))}
                    {s.unit && <span className="b2unitl">{unitFor(Number(boxes[0]?.replace("−", "-")), s.unit)}</span>}
                  </div>}
                {fb && <p className={`b2fb ${fb.tone}`} role="status"><Rich text={fb.text} /></p>}
                <span className="b2help">
                  <button type="button" className="tlink" onClick={() => setHint(h => !h)}>{hint ? "Hide the hint" : "Hint"}</button>
                  {misses >= 2 && <button type="button" className="tlink" onClick={showMe}>Show me</button>}
                </span>
                {hint && <p className="b2small"><Rich text={s.hint} /></p>}
              </div>
            ) : <span className="b2later">{s.label}</span>}
        </li>
      ))}
    </ol>
    {solved && <p className="b2say">That's the whole problem.</p>}
  </>;
  else body = <>
    {lesson.useIt.say.map((t, i) => <p key={i} className="b2say"><Rich text={t.replace(/`([^`]+)`/g, "**$1**")} /></p>)}
    {saves && (
      <div className="b2savecard">
        <span>Keep <b>{saves.name}</b> on your Number shelf: {shelfText({ value: saves.value(), unit: saves.unit, from: lesson.id, at: 0 })}</span>
        <Pill go={!savedNow} aria-pressed={!!savedNow} onClick={() => updateB2(b => ({ ...b, shelf: { ...b.shelf, [saves.name]: { value: saves.value(), unit: saves.unit, labels: saves.labels, from: lesson.id, note: saves.note, at: now() } } }))}>{savedNow ? "On your shelf ✓" : "Save"}</Pill>
      </div>
    )}
    {project && <p className="b2small">{project.build ? "The build" : "Your project"}, <b>{project.name}</b>, is in the picture. Set it up and save it there.</p>}
    {project && <Pill go className="b2projbtn" onClick={() => setProjOpen(true)}>Open {project.name} ›</Pill>}
    <p className="b2can on">You can {lesson.youCan}</p>
  </>;

  const stepLeft = !solved && stage === "work" && !step?.choices;
  return (
    <FitScreen className={`b2lesson st-${stage}${stepLeft ? " typing" : ""}${stage === "use" && project ? " proj" : ""}${projOpen ? " projopen" : ""}`}>
      <section className="b2card" aria-labelledby="b2title">
        <header className="b2lhead">
          <div><small className="b2kick">{track.name} · Unit {lesson.unit} · {lessonNumber(lesson.id)}</small><h1 id="b2title">{lesson.title}</h1></div>
          <button type="button" className="ctl b2deep" aria-expanded={!!deeper} onClick={() => setDeeper("open")}>Deeper</button>
        </header>
        <div className="b2stages" role="tablist" aria-label="The lesson's loop" style={{ "--at": at } as CSSProperties}>
          <span className="b2sk" aria-hidden />
          {STAGES.map(s => <button key={s} role="tab" aria-selected={s === stage} onClick={() => setStage(s)}>{STAGE_NAMES[s]}</button>)}
        </div>
        {/* the problem stays pinned above its steps, so working down the steps never scrolls it away */}
        {stage === "work" && <p className="b2prob"><Rich text={lesson.workIt.show(problem)} /></p>}
        <div className="b2body" key={stage}>{body}</div>
        <div className="b2foot">
          {stage === "work" && !solved && !step?.choices && (
            <div className="b2pad">
              {KEYS.map(key => <button type="button" key={key} aria-label={KEY_ARIA[key]} onClick={() => press(key)}>{KEY_LABEL[key] ?? key}</button>)}
              <Pill go className="b2check" onClick={() => check()}>Check</Pill>
            </div>
          )}
          <div className="b2nav">
            {at > 0 && <Pill onClick={() => setStage(STAGES[at - 1]!)}>‹ {STAGE_NAMES[STAGES[at - 1]!]}</Pill>}
            <span className="grow" />
            {!(stage === "guess" && !revealed) && <button type="button" className="ctl b2deep b2deepm" aria-expanded={!!deeper} onClick={() => setDeeper("open")}>Deeper</button>}
            {!(stage === "guess" && !revealed) && <span className="grow b2deepm" />}
            {stage === "work" && solved && <Pill onClick={another}>Another problem</Pill>}
            {stage === "guess" && !revealed ? <Pill go disabled={guess == null} onClick={lockIn}>Lock in my guess</Pill> : nextStage
              ? <Pill go={stage !== "work" || solved} onClick={() => setStage(nextStage)}>{STAGE_NAMES[nextStage]} ›</Pill>
              : <Pill go onClick={() => go({ name: "b2track", track: trackId }, "back")}>Back to {track.name} ›</Pill>}
          </div>
        </div>
      </section>
      <figure className="b2stage" aria-label="The live picture">
        {projOpen && <Pill className="b2projback" onClick={() => setProjOpen(false)}>‹ Back to the lesson</Pill>}
        {picture}
      </figure>
      {deeper && (
        <>
          <div className={`fdim${deeper === "closing" ? " out" : ""}`} onClick={() => setDeeper("closing")} />
          <div className={`fstack b2deeper${deeper === "closing" ? " out" : ""}`} role="dialog" aria-label="Deeper" style={{ "--n": lesson.deeper.length + 2 } as CSSProperties}>
            <span className="flbl" style={{ "--i": 0 } as CSSProperties}>Deeper · optional, for more rigor</span>
            {lesson.deeper.map((t, i) => <p key={i} className="fpill" style={{ "--i": i + 1 } as CSSProperties}><Rich text={t} /></p>)}
            <button className="fpill go" autoFocus style={{ "--i": lesson.deeper.length + 1 } as CSSProperties} onClick={() => setDeeper("closing")}>Back to the lesson</button>
          </div>
        </>
      )}
    </FitScreen>
  );
}
