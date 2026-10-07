import { Pill } from "../components/primitives/Pill";
import { Check, Chevron } from "../components/primitives/icons";
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
import { FitScreen } from "../components/screen/Screen";
import { ALL_LESSONS, SHOW_ME } from "../app/copy";
import {
  bandOfSession, check, choose, currentItem, currentStep, focusSlot, hint, isLastProblem, lessonOfItem, nextProblem,
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
export function Practice() {
  const { progress, go, act, finish, quit } = useApp();
  const s = progress.run;
  const prefs = readSettings(progress.settings), aloud = readAloudOn(prefs, progress.grade);

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
      if (e.metaKey || e.ctrlKey || e.altKey || asking) return;
      // an open hint or steps stack takes Escape for itself, so the page underneath doesn't also step back (Review)
      if (e.key === "Escape") { if (document.querySelector("#app .fstack[role=dialog]")) e.preventDefault(); setHintOpen(false); setStepsOpen(false); return; }
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
  const [hintOpen, setHintOpen] = useState(false), [stepsOpen, setStepsOpen] = useState(false), [asking, setAsking] = useState(false);
  useEffect(() => { setHintOpen(false); setStepsOpen(false); }, [s?.i, s?.step, s?.solved]);
  useEffect(() => { dispatchEvent(new CustomEvent("bento:hintopen", { detail: hintOpen })); }, [hintOpen]);
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
    const onHint = () => { act((st, _p, d) => hint(st, d)); setStepsOpen(false); setHintOpen(true); dispatchEvent(new CustomEvent("bento:panel", { detail: "feedback" })); };
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
  const nextLabel = s.i < n - 1 ? "Next problem" : test ? "Finish test" : s.mode === "review" ? "Finish review" : "Finish lesson";
  // "Solved." carries the lesson's last idea, in this problem's numbers
  const idea = s.solved && full?.steps.length ? full.steps[full.steps.length - 1]!.narration : undefined;
  // the light bulb's own answers open in the hint stack, not on the feedback line
  const bulbHint = fb?.type === "hint" && (fb.strong === "Hint:" || /^No hints left/.test(fb.text ?? ""));
  const shape = problemShape(it.lessonId, problemOf(it), !!it.story);
  // tests go without the explanation's picture (ex is null), but a problem drawn as its own picture keeps it: it IS the problem
  const pic = !!ex || shape.picture;
  // the steps: done ones with their finished line, the one being answered, the ones still to come by number only
  // (their names could give a plan-the-step choice away)
  const steps = stepsOf(s), here = s.solved ? steps.length : s.step;
  const beats = steps.map((st, k) => ({ k, state: k < here ? "done" : k === here ? "now" : "later", label: k === here && s.pick ? "What comes next?" : k <= here ? st.base : `Step ${k + 1}`, line: s.work[k] }));
  const now = beats.find(b => b.state === "now");
  // quitting asks only when answers would be lost
  const started = s.i > 0 || s.work.length > 0 || s.mistakes.length > 0 || s.solved;
  const onQuit = () => (started ? setAsking(true) : quit());
  const dots = <span className="pdots" aria-hidden>{s.items.map((_, i) => <i key={i} className={i < s.i ? "ok" : i === s.i ? "now" : ""} />)}</span>;
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
  const extras = <>
    {skipAvailable(s) && <Pill onClick={() => act((st, _p, d) => toggleSkip(st, d))}>{s.skip ? "Show steps" : "Final answer only"}</Pill>}
    <Pill className="pquit" onClick={onQuit}>Quit</Pill>
  </>;

  return (
    <FitScreen className={`lscreen pscreen${test ? " ptest" : ""}${pic ? "" : " nopic"}${shape.short ? "" : " pwordy"}${s.solved ? " psolved" : ""}${hintOpen ? " hinting" : ""}${stepsOpen ? " stepsopen" : ""}`}
      style={{ "--steps": steps.length } as CSSProperties}>
      {/* the problem and how it's going: where you are, the problem with its "?", and the steps */}
      <section className="lintro pintro">
        <p className="k"><span>Problem {s.i + 1} of {n}</span>{dots}</p>
        {test && <p className="ptestk">{s.title}: no hints, one try per step</p>}
        {mixed && <div className="label plabel">{lesson.title}</div>}
        <div className="pprob"><ProblemView lessonId={it.lessonId} problem={problemOf(it)} story={!!it.story} solved={s.solved} part="text" /></div>
        {beatList}
        <div className="pextra">{extras}</div>
      </section>
      {/* the hero: the step's equation with its answer box, its feedback line, and the picture */}
      <figure className="lshero phero">
        <div className="lmath pmath">
          {step && !s.pick ? <>
            {step.question && <span className="q"><Rich text={step.question} /></span>}
            <div className={`ask${fb?.type === "bad" && !fbAway ? " no" : ""}${s.fx === "shake" ? " shake" : ""}`} key={`${at}-${s.mistakes.length}`}>
              <MathLine math={step.prompt} values={s.values} active={s.active} onSlot={id => act(st => focusSlot(st, id))} />
            </div>
            {step.note && <span className="note"><Rich text={step.note} /></span>}
          </> : s.pick ? <span className="q">Step {s.step + 1} · What comes next?</span>
            : <div className="ask ok"><MathLine math={s.work[s.work.length - 1]?.math ?? []} /></div>}
          <button className="speak" aria-label="Read it to me" onClick={() => speak([step?.question, document.querySelector("#app .pprob")?.textContent].filter(Boolean).join(". ").replace(/\*\*/g, ""))}><SpeakerIcon /></button>
        </div>
        <FeedbackBox key={fbKey} fb={fbAway || bulbHint ? null : fb} idea={idea} solved={s.solved && !fbAway && fb?.type !== "hint"} />
        {/* a phone: the steps fold into one bar at the top of the problem's tile, over its math (G 17:38: steps on top); it opens as an accordion that
          pushes the picture down, and when the problem is solved the bar is where "Solved." and its idea land (G 2026-10-07) */}
        <div className="pbar">
          <button key={fb?.type === "good" && !s.solved ? fbKey : "bar"} className={`fpill stepbar${s.solved ? " solved" : ""}${fb?.type === "good" && !s.solved && !fbAway ? " flash" : ""}`} onClick={() => setStepsOpen(o => !o)} aria-expanded={stepsOpen} aria-label={`Steps: ${now?.label ?? "done"}, ${Math.min(here + 1, steps.length)} of ${steps.length}`}>
            <span className="badge">{s.solved ? <Check /> : here + 1}{fb?.type === "good" && !s.solved && !fbAway && <span className="tick"><Check /></span>}</span><span className="sbl">{s.solved ? <><b>Solved.</b>{idea && <> <Rich text={idea} /></>}</> : now?.label}</span>
            <small>{Math.min(here + 1, steps.length)} of {steps.length}</small><span className="chev" aria-hidden><Chevron dir="down" /></span>
          </button>
        </div>
        {stepsOpen && (
          <div className="pacc" role="region" aria-label="Steps">
            <p className="pwhere">Problem {s.i + 1} of {n}{dots}</p>
            {beatList}
            {skipAvailable(s) && <div className="hrow"><Pill onClick={() => act((st, _p, d) => toggleSkip(st, d))}>{s.skip ? "Show steps" : "Final answer only"}</Pill></div>}
          </div>
        )}
        {pic && (
          <div className={`lpic ppic${s.hinted ? " hinted" : ""}`} aria-label="Picture of this problem" role="img">
            <div className="viz">{ex
              ? <Diagram key={s.i} diagram={ex.diagram!} timeline={ex.timeline} fit
                at={s.solved ? ex.timeline.length - 1 : Math.min(ex.timeline.length - 1, s.step > 0 ? ex.steps[s.step - 1]?.state ?? 0 : 0)} />
              : <ProblemView lessonId={it.lessonId} problem={problemOf(it)} story={!!it.story} part="picture" />}</div>
          </div>
        )}
      </figure>
      <Keypad band={band} tap={step && tapOnly ? (
        <div className="tappad">
          <div className="tapnote muted">{s.pick ? "You plan this one: tap the step that comes next." : "Tap your answer."}</div>
          <div className="choices">{s.pick
            ? s.pick.options.map((o, i) => <button key={`${i}-${o}`} className={`choice${mark(i)}`} onClick={() => { setTapped({ at, i }); act(st => pickPlan(st, i)); }}>{o}</button>)
            : step.choices!.map((o, i) => <button key={`${i}-${o}`} className={`choice${mark(i)}`} onClick={() => { setTapped({ at, i }); act((st, p, d) => choose(st, i, p, d)); }}>{o}</button>)}</div>
        </div>) : undefined}
        solved={s.solved} plain={plain} onKey={key => { if (fb?.type === "bad") setFbAway(true); act(st => pressKey(st, key)); }}
        go={s.solved ? { label: nextLabel, run: onNext } : tapOnly ? undefined : { label: "Check", run: () => act((st, p, d) => check(st, p, d)) }} />
      {hintOpen && step && (
        <>
          <div className="fdim phdim" onClick={() => setHintOpen(false)} />
          <div className="fstack phint" role="dialog" aria-label="Hint" style={{ "--n": 4 } as CSSProperties}>
            {/* before a first try the hint waits, so say that, not "none left" (Review v45 #2) */}
            <span className="flbl" style={{ "--i": 0 } as CSSProperties}>{s.hinted ? `Hint · ${s.hintsLeft} left` : s.hintsLeft ? `Hint · ${s.hintsLeft} left` : "No hints left"}</span>
            <span className="fpill htext" style={{ "--i": 1 } as CSSProperties}><span><Rich text={s.hinted ? step.hint : s.hintsLeft ? (fb?.type === "hint" && fb.text ? fb.text : "Try it once first. Then the hint opens.") : "No hints left in this lesson. You can do it."} /></span></span>
            <span className="hrow" style={{ "--i": 2 } as CSSProperties}>
              {showMeAvailable(s) && <button className="fpill" onClick={() => { setHintOpen(false); act((st, p, d) => showMe(st, p, d)); }}>{SHOW_ME} the step</button>}
              <button className="fpill go" autoFocus onClick={() => setHintOpen(false)}>Got it</button>
            </span>
          </div>
        </>
      )}
      {asking && (
        <Confirm title={`Quit ${s.title}?`} body="Your answers so far won't be kept." confirm="Quit"
          onCancel={() => setAsking(false)} onConfirm={() => { setAsking(false); quit(); }} />
      )}
    </FitScreen>
  );
}
