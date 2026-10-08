import { Pill } from "../components/primitives/Pill";
import { Check, Chevron, GridIcon } from "../components/primitives/icons";
import { useEffect, useMemo, useRef, useState, type CSSProperties } from "react";
import { playTone, readAloudOn, readSettings, speak } from "../app/settings";
import { useApp } from "../app/AppState";
import { withTransition } from "../app/transition";
import { MathLine, Rich } from "../components/primitives/MathLine";
import { problemShape, ProblemView } from "../components/practice/ProblemView";
import { Diagram } from "../components/diagrams/Diagram";
import { requireLesson } from "../curriculum/registry";
import type { Explanation } from "../explanations/schema";
import { FeedbackBox } from "../components/practice/FeedbackBox";
import { Confirm } from "../components/Confirm";
import { Keypad } from "../components/practice/Keypad";
import { ProblemsZoom } from "../components/practice/ProblemsZoom";
import { FitScreen } from "../components/screen/Screen";
import { ListGroup } from "../components/screen/ListGroup";
import { ALL_LESSONS, SHOW_ME } from "../app/copy";
import {
  bandOfSession, check, choose, currentItem, currentStep, focusSlot, goToProblem, hint, isLastProblem, lessonOfItem, nextProblem,
  pickPlan, pressKey, problemOf, showMe, showMeAvailable, skipAvailable, stepsOf, toggleSkip,
} from "../engine/session/practice";

const SpeakerIcon = () => (
  <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M4 9.5h3.5L12 5.5v13l-4.5-4H4z" /><path d="M15.5 9a4 4 0 0 1 0 6M18 6.5a7.5 7.5 0 0 1 0 11" /></svg>
);

/**
 * One problem at a time, picture first (Design, practice-spec.md, approved by G 2026-10-06). It sits on Learn's grid
 * master: the problem and its steps on the left (on top in portrait), the hero with the step's equation and answer box,
 * the feedback line and the picture, and the keypad docked under the hero, sharing its left and right edges. On a
 * phone the problem moves into the island and the steps fold into one bar above the keypad. Hints open from the
 * island's light bulb as a Settings-style stack.
 */
// on a larger screen the solve panel has the room, so the steps stay open (G 2026-10-07 22:00); same query as the wide layout
const wideSteps = () => typeof matchMedia !== "undefined" && matchMedia("(min-width: 900px) and (orientation: landscape)").matches;

/** whether the screen is wide (the same query as wideSteps), kept up to date as the window turns or resizes */
function useWide() {
  const [wide, setWide] = useState(wideSteps);
  useEffect(() => {
    if (typeof matchMedia === "undefined") return;
    const m = matchMedia("(min-width: 900px) and (orientation: landscape)"), on = () => setWide(m.matches);
    m.addEventListener("change", on);
    return () => m.removeEventListener("change", on);
  }, []);
  return wide;
}

export function Practice() {
  const { progress, go, act, finish, quit } = useApp();
  const s = progress.run;
  const prefs = readSettings(progress.settings), aloud = readAloudOn(prefs, progress.grade);
  const wide = useWide();

  // sounds: a soft tone when a step comes out right or a try is wrong
  const counts = useRef({ work: s?.work.length ?? 0, miss: s?.mistakes.length ?? 0, key: `${s?.i}` });
  useEffect(() => {
    if (!s) return;
    const c = counts.current, key = `${s.i}`;
    if (prefs.sounds && c.key === key) {
      if (s.mistakes.length > c.miss) playTone("wrong");
      else if (s.work.length > c.work) playTone("right");
    }
    counts.current = { work: s.work.length, miss: s.mistakes.length, key };
  }, [s?.work.length, s?.mistakes.length, s?.i]); // eslint-disable-line react-hooks/exhaustive-deps

  // read aloud: each new problem is read out, as on screen
  useEffect(() => {
    if (!s || !aloud) return;
    const t = setTimeout(() => speak(document.querySelector("#app .pprob")?.textContent ?? ""), 350);
    return () => clearTimeout(t);
  }, [s?.i, aloud]); // eslint-disable-line react-hooks/exhaustive-deps

  // read aloud: what the feedback says, as it appears
  const said = s?.feedback ? `${s.feedback.strong ?? ""} ${s.feedback.text ?? ""}`.replace(/\*\*/g, "").trim() : "";
  useEffect(() => { if (aloud && said) speak(said); }, [said, aloud]);

  // a physical keyboard works too: digits, minus, point, Backspace, Tab for the next box, Enter to check
  useEffect(() => {
    if (!s) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.metaKey || e.ctrlKey || e.altKey || asking || zoomOut) return;
      // an open hint or steps stack takes Escape for itself, so the page underneath doesn't also step back (Review)
      if (e.key === "Escape") { if (document.querySelector("#app :is(.fstack[role=dialog],.phint)")) e.preventDefault(); setHintOpen(false); setStepsOpen(openSteps()); return; }
      // tap-to-answer steps and planning: 1–4 pick a choice
      const st = currentStep(s);
      if (s.pick || st?.choices) {
        if (/^[1-4]$/.test(e.key)) document.querySelectorAll<HTMLButtonElement>("#app .choice")[Number(e.key) - 1]?.click();
        return;
      }
      const map: Record<string, string> = { Backspace: "back", "-": "−", ".": ".", Tab: "next" };
      const key = /^\d$/.test(e.key) ? e.key : map[e.key];
      if (key) { e.preventDefault(); if (s.feedback?.type === "bad") setFbAway(true); act(st => pressKey(st, key)); }
      else if (e.key === "Enter") {
        e.preventDefault();
        if (s.solved) onNext(); else act((st, p, d) => check(st, p, d));
      }
    };
    addEventListener("keydown", onKey);
    return () => removeEventListener("keydown", onKey);
  });

  // the problem's own picture, as the lesson drew it: it starts on the set-up and grows one step behind the learner,
  // so it helps without giving the answer away (Review v39 item 15). Tests go without, so they stay fair.
  const [full, ownPic] = useMemo<[Explanation | null, boolean]>(() => {
    if (!s || s.mode === "test") return [null, false];
    const item = currentItem(s), l = requireLesson(item.lessonId), p = problemOf(item);
    try { return [l.explain(p, l.answers(p)), !!l.picture?.(p)]; } catch { return [null, false]; }
  }, [s?.i, s?.mode, s?.t0]); // eslint-disable-line react-hooks/exhaustive-deps
  // the problem already shows its own picture when the lesson draws one
  const ex = full && !ownPic && full.diagram && full.diagram.kind !== "chain" ? full : null;

  // a session whose answers are all whole numbers, none below zero, needs no "." or "−" key: the keypad drops them and
  // its keys grow (G 2026-10-07). Worked out from every answer in the session, so no one problem gives itself away.
  const plain = useMemo(() => {
    if (!s) return false;
    try {
      return s.items.every(item => {
        const l = requireLesson(item.lessonId);
        return l.answers(problemOf(item)).steps.every(st => !!st.choices || st.slots.every(sl => sl.expected == null || (Number.isInteger(sl.expected) && sl.expected >= 0)));
      });
    } catch { return false; }
  }, [s?.t0]); // eslint-disable-line react-hooks/exhaustive-deps

  // the tapped answer wears right or wrong on itself (UI notes preview)
  const [tapped, setTapped] = useState<{ at: string; i: number } | null>(null);
  // the hint stack, the phone's steps stack and the quit question: one at a time
  const [hintOpen, setHintOpen] = useState(false), [stepsOpen, setStepsOpen] = useState(wideSteps), [asking, setAsking] = useState(false);
  // every problem zoomed out, to pick which one comes next (G 2026-10-08): a pinch closed or a tap on "Problem 2 of 6"
  const [zoomOut, setZoomOut] = useState(false);
  useEffect(() => {
    const on = () => { setHintOpen(false); setZoomOut(true); };
    addEventListener("bento:problems", on);
    return () => removeEventListener("bento:problems", on);
  }, []);
  // with no picture the question is the whole problem, so the steps start folded and the question leads (G 2026-10-08)
  const picRef = useRef(true);
  const openSteps = () => wideSteps() && picRef.current;
  useEffect(() => { setHintOpen(false); setStepsOpen(openSteps()); }, [s?.i, s?.step, s?.solved]); // eslint-disable-line react-hooks/exhaustive-deps
  useEffect(() => { dispatchEvent(new CustomEvent("bento:hintopen", { detail: hintOpen })); }, [hintOpen]);
  // the steps are the Contents accordion itself (the ListGroup master): it opens and folds on the master's own motion
  const toggleSteps = () => setStepsOpen(o => !o);
  // feedback and quick settings never overlap: opening settings puts the feedback away, and new feedback closes settings
  const [fbAway, setFbAway] = useState(false);
  const fbKey = s?.feedback ? `${s.i}-${s.step}-${s.mistakes.length}-${s.hints}-${s.feedback.strong}-${s.feedback.text}-${s.feedback.left}` : "";
  useEffect(() => {
    setFbAway(false);
    if (fbKey && s?.feedback?.type !== "hint") dispatchEvent(new CustomEvent("bento:panel", { detail: "feedback" }));
  }, [fbKey]);
  useEffect(() => {
    const onPanel = (e: Event) => { if ((e as CustomEvent).detail === "settings") { setFbAway(true); setHintOpen(false); setStepsOpen(false); } };
    // the light bulb up top asks for a hint, and the hint opens as a stack (reopening it shows the same hint, free)
    const onHint = () => { act((st, _p, d) => hint(st, d)); setStepsOpen(openSteps()); setHintOpen(true); dispatchEvent(new CustomEvent("bento:panel", { detail: "feedback" })); };
    addEventListener("bento:panel", onPanel); addEventListener("bento:hint", onHint);
    return () => { removeEventListener("bento:panel", onPanel); removeEventListener("bento:hint", onHint); };
  }, [act]);

  if (!s) {
    return (
      <FitScreen className="pnone"><section className="panel"><p className="empty">No lesson in progress.</p>
        <div className="actions"><Pill go onClick={() => go({ name: "home" })}>{ALL_LESSONS}</Pill></div></section></FitScreen>
    );
  }

  const it = currentItem(s), lesson = lessonOfItem(it), step = currentStep(s), fb = s.feedback, n = s.items.length;
  const test = s.mode === "test", mixed = s.mode !== "practice", band = bandOfSession(s);
  const tapOnly = !!s.pick || !!step?.choices;
  const at = `${s.i}-${s.step}`, mark = (i: number) => tapped?.at === at && tapped.i === i && fb ? (fb.type === "bad" ? " no" : " ok") : "";
  const nextLabel = !isLastProblem(s) ? "Next problem" : test ? "Finish test" : s.mode === "review" ? "Finish review" : "Finish lesson";
  // "Solved." carries the lesson's last idea, in this problem's numbers
  const idea = s.solved && full?.steps.length ? full.steps[full.steps.length - 1]!.narration : undefined;
  // the light bulb's own answers open in the hint stack, not on the feedback line
  const bulbHint = fb?.type === "hint" && (fb.strong === "Hint:" || /^No hints left/.test(fb.text ?? ""));
  const shape = problemShape(it.lessonId, problemOf(it), !!it.story);
  // tests go without the explanation's picture (ex is null), but a problem drawn as its own picture keeps it: it IS the problem
  const pic = !!ex || shape.picture;
  picRef.current = pic;
  // the steps: done ones with their finished line, the one being answered, the ones still to come by number only
  // (their names could give a plan-the-step choice away)
  const steps = stepsOf(s), here = s.solved ? steps.length : s.step;
  // in a test a wrong answer is shown, not solved: that step gets no tick, and the problem never says "Solved." or
  // lights its answer green (G 2026-10-08 "it shouldnt mark green or solve this is clearly wrong")
  const given = (k: number) => test && !!s.work[k]?.shown;
  const missed = s.solved && s.work.some((_, k) => given(k));
  const won = s.solved && !missed;
  const beats = steps.map((st, k) => ({ k, state: k < here ? (given(k) ? "missed" : "done") : k === here ? "now" : "later", label: k === here && s.pick ? "What comes next?" : k <= here ? st.base : `Step ${k + 1}`, line: s.work[k] }));
  const now = beats.find(b => b.state === "now");
  // quitting asks only when answers would be lost
  const started = (s.done?.length ?? 0) > 0 || s.work.length > 0 || s.mistakes.length > 0 || s.solved;
  const onQuit = () => (started ? setAsking(true) : quit());
  const dots = <span className="pdots" aria-hidden>{s.items.map((_, i) => <i key={i} className={i === s.i ? "now" : s.done?.includes(i) ? "ok" : ""} />)}</span>;
  function onNext() {
    if (s && isLastProblem(s)) finish();
    // the next problem is a step along the row, not a step deeper: it slides, the page never zooms (Review)
    else withTransition(() => act((st, p, d) => nextProblem(st, p, d)), "next");
  }
  const beatList = (
    <ol className="beats pbeats">
      {beats.map(b => (
        <li key={b.k} className={`beat${b.line && s.fx === "line" && b.k === s.work.length - 1 ? " enter" : ""}`} data-state={b.state}>
          <span className="badge">{b.state === "done" ? <Check /> : b.k + 1}</span>
          <span className="say"><b>{b.label}</b>{b.line && <span className={`pline${b.line.shown ? " shown" : ""}`}><MathLine math={b.line.math} /></span>}</span>
        </li>
      ))}
    </ol>
  );
  // a test on a wide screen asks in the pad's panel, where it's answered (G 2026-10-08 "put the questions inside the
  // other panel since it's the panel used to solve the problem"); the left panel keeps the problem and its steps
  const askInPad = test && wide;
  const ask = <>
        <div className="lmath pmath">
          {step && !s.pick ? <>
            {step.question && <span className="q"><Rich text={step.question} /></span>}
            <div className={`ask${fb?.type === "bad" && !fbAway ? " no" : ""}${s.fx === "shake" ? " shake" : ""}`} key={`${at}-${s.mistakes.length}`}>
              <MathLine math={step.prompt} values={s.values} active={s.active} onSlot={id => act(st => focusSlot(st, id))} />
            </div>
            {step.note && <span className="note"><Rich text={step.note} /></span>}
          </> : s.pick ? <span className="q">Step {s.step + 1} · What comes next?</span>
            : <div className={`ask ${s.work[s.work.length - 1]?.shown ? "given" : "ok"}`}><MathLine math={s.work[s.work.length - 1]?.math ?? []} /></div>}
          <button className="speak" aria-label="Read it to me" onClick={() => speak([step?.question, document.querySelector("#app .pprob")?.textContent].filter(Boolean).join(". ").replace(/\*\*/g, ""))}><SpeakerIcon /></button>
        </div>
        <FeedbackBox key={fbKey} fb={fbAway || bulbHint ? null : fb} idea={idea} solved={s.solved && !fbAway && fb?.type !== "hint"} />
  </>;
  const extras = <>
    {skipAvailable(s) && <Pill onClick={() => act((st, _p, d) => toggleSkip(st, d))}>{s.skip ? "Show steps" : "Final answer only"}</Pill>}
    <Pill className="pquit" onClick={onQuit}>Quit</Pill>
  </>;

  return (
    <FitScreen className={`lscreen pscreen${test ? " ptest" : ""}${pic ? "" : " nopic"}${shape.short ? "" : " pwordy"}${test && shape.short ? " pshow" : ""}${askInPad ? " paskpad" : ""}${s.solved ? " psolved" : ""}${hintOpen ? " hinting" : ""}${stepsOpen ? " stepsopen" : ""}`}
      style={{ "--steps": steps.length } as CSSProperties}>
      {/* the problem and how it's going: where you are, the problem with its "?", and the steps */}
      <section className="lintro pintro">
        <p className="k"><button className="pzoom" onClick={() => setZoomOut(true)} aria-haspopup="dialog" aria-label={`Problem ${s.i + 1} of ${n}. See every problem`}><span>Problem {s.i + 1} of {n}</span>{dots}</button></p>
        {test && <p className="ptestk">{s.title}: no hints, one try per step</p>}
        {mixed && <div className="label plabel">{lesson.title}</div>}
        {beatList}
        <div className="pextra">{extras}</div>
      </section>
      {/* the hero: the step's equation with its answer box, its feedback line, and the picture */}
      <figure className="lshero phero">
        {!askInPad && ask}
        {/* a phone: the steps fold into one bar at the top of the problem's tile, over its math (G 17:38: steps on top); it opens as an accordion that
          pushes the picture down, and when the problem is solved the bar is where "Solved." and its idea land (G 2026-10-07) */}
        {/* the steps are the lesson list's accordion (ListGroup master, G 19:39 "use the same accordion"): the bar is its head row
          and the steps are its rows, the one you're on shaded like the current lesson */}
        {/* a word problem's own words sit at the top of the solve panel, over its steps (G 2026-10-07 22:29) */}
        <div className="pprob"><ProblemView lessonId={it.lessonId} problem={problemOf(it)} story={!!it.story} solved={s.solved} part="text" /></div>
        <div className="pbar">
          {/* where you are in the set, always in view: tapping it zooms out to every problem (G 2026-10-08) */}
          <button className="pwhere pzoom" onClick={() => setZoomOut(true)} aria-haspopup="dialog" aria-label={`Problem ${s.i + 1} of ${n}. See every problem`}><span className="sname">Problem {s.i + 1} of {n}</span>{dots}<span className="chev" aria-hidden><GridIcon /></span></button>
          <ListGroup open={stepsOpen} head={
            <button key={fb?.type === "good" && !s.solved ? fbKey : "bar"} className={`srow chap stepbar${won ? " solved" : missed ? " missed" : ""}${fb?.type === "good" && !s.solved && !fbAway ? " flash" : ""}`} onClick={toggleSteps} aria-expanded={stepsOpen} aria-label={`Steps: ${now?.label ?? "done"}, ${Math.min(here + 1, steps.length)} of ${steps.length}`}>
              <span className="badge">{won ? <Check /> : s.solved ? steps.length : here + 1}{fb?.type === "good" && !s.solved && !fbAway && <span className="tick"><Check /></span>}</span>
              <span className="sname"><b>{s.solved ? <><strong>{missed ? "Not this time." : "Solved."}</strong>{idea && <> <Rich text={idea} /></>}</> : now?.label}</b></span>
              {!s.solved && <small className="smeta">{Math.min(here + 1, steps.length)} of {steps.length}</small>}<span className="chev" aria-hidden><Chevron dir="down" /></span>
            </button>}>
            {beats.map(b => (
              <div key={b.k} className={`srow sles pstep${b.state === "now" ? " on" : ""}`} data-state={b.state}>
                <span className="badge">{b.state === "done" ? <Check /> : b.k + 1}</span>
                <span className="sname"><b>{b.label}</b>{b.line && <span className={`pline${b.line.shown ? " shown" : ""}`}><MathLine math={b.line.math} /></span>}</span>
              </div>
            ))}
            {skipAvailable(s) && <div className="hrow"><Pill onClick={() => act((st, _p, d) => toggleSkip(st, d))}>{s.skip ? "Show steps" : "Final answer only"}</Pill></div>}
          </ListGroup>
        </div>
        {/* the hint opens in the solve panel's own room under the question, not over the screen (G 2026-10-07 22:31) */}
        {hintOpen && step && (
          <section className="phint" role="region" aria-label="Hint">
            {/* before a first try the hint waits, so say that, not "none left" (Review v45 #2) */}
            <span className="k">{s.hintsLeft ? `Hint · ${s.hintsLeft} left` : "No hints left"}</span>
            <p className="htext"><Rich text={s.hinted ? step.hint : s.hintsLeft ? (fb?.type === "hint" && fb.text ? fb.text : "Try it once first. Then the hint opens.") : "No hints left in this lesson. You can do it."} /></p>
            <div className="hrow">
              {showMeAvailable(s) && <Pill onClick={() => { setHintOpen(false); act((st, p, d) => showMe(st, p, d)); }}>{SHOW_ME} the step</Pill>}
              <Pill go autoFocus onClick={() => setHintOpen(false)}>Got it</Pill>
            </div>
          </section>
        )}
      </figure>
      {pic && (
        <div className={`lpic ppic${s.hinted ? " hinted" : ""}`} aria-label="Picture of this problem" role="img">
          <div className="viz">{ex
            ? <Diagram key={s.i} diagram={ex.diagram!} timeline={ex.timeline} fit turn={!it.story}
              at={s.solved ? ex.timeline.length - 1 : Math.min(ex.timeline.length - 1, s.step > 0 ? ex.steps[s.step - 1]?.state ?? 0 : 0)} />
            : <ProblemView lessonId={it.lessonId} problem={problemOf(it)} story={!!it.story} part="picture" step={s.solved ? undefined : steps[here]?.id} />}</div>
        </div>
      )}
      <Keypad band={band} tap={step && tapOnly ? (
        <div className="tappad">
          {!askInPad && <div className="tapnote muted">{s.pick ? "You plan this one: tap the step that comes next." : "Tap your answer."}</div>}
          <div className="choices">{s.pick
            ? s.pick.options.map((o, i) => <button key={`${i}-${o}`} className={`choice${mark(i)}`} onClick={() => { setTapped({ at, i }); act(st => pickPlan(st, i)); }}>{o}</button>)
            : step.choices!.map((o, i) => <button key={`${i}-${o}`} className={`choice${mark(i)}`} onClick={() => { setTapped({ at, i }); act((st, p, d) => choose(st, i, p, d)); }}>{o}</button>)}</div>
        </div>) : undefined}
        solved={s.solved} plain={plain} head={askInPad ? ask : undefined} onKey={key => { if (fb?.type === "bad") setFbAway(true); act(st => pressKey(st, key)); }}
        go={s.solved ? { label: nextLabel, run: onNext } : tapOnly ? undefined : { label: "Check", run: () => act((st, p, d) => check(st, p, d)) }} />
      {zoomOut && <ProblemsZoom s={s} close={() => setZoomOut(false)} pick={k => withTransition(() => act((st, p, d) => goToProblem(st, k, p, d)), "next")} />}
      {asking && (
        <Confirm title={`Quit ${s.title}?`} body="Your answers so far won't be kept." confirm="Quit"
          onCancel={() => setAsking(false)} onConfirm={() => { setAsking(false); quit(); }} />
      )}
    </FitScreen>
  );
}

/** A Web Animations timing taken from the motion tokens: one of the --m-* durations, on --m-ease. */
