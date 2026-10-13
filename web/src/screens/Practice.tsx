import { Pill } from "../components/primitives/Pill";
import { useEffect, useMemo, useRef, useState, type CSSProperties } from "react";
import { playTone, readAloudOn, readSettings, speak } from "../app/settings";
import { useApp } from "../app/AppState";
import { withTransition } from "../app/transition";
import { MathLine, Rich } from "../components/primitives/MathLine";
import { plainProblem, ProblemLine, problemShape, ProblemView } from "../components/practice/ProblemView";
import { Diagram } from "../components/diagrams/Diagram";
import { requireLesson } from "../curriculum/registry";
import type { Explanation } from "../explanations/schema";
import { formatNumber, type MathText, type MathToken } from "../curriculum/schemas/math-text";
import { Keypad } from "../components/practice/Keypad";
import { Cover } from "../components/Cover";
import type { PracticeSession } from "../engine/session/types";
import { ScratchPad, type Stroke } from "../components/practice/ScratchPad";
import { FitScreen } from "../components/screen/Screen";
import { ALL_LESSONS, SHOW_ME, SKILL_CHECK } from "../app/copy";
import { isCheckKey } from "../engine/mastery/skills";
import {
  bandOfSession, canPick, check, choose, currentItem, currentStep, focusSlot, goToProblem, hint, isLastProblem, lessonOfItem, nextProblem,
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

/** the lessons that offer the scratch pad so far: a first try on one lesson (G 2026-10-09, "Show your work") */
const SCRATCH = new Set(["g5-mult2"]);

const BulbIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M9 18h6M10 21h4M12 3a6 6 0 0 0-3.5 10.9c.6.5 1 1.2 1 2.1h5c0-.9.4-1.6 1-2.1A6 6 0 0 0 12 3z" /></svg>
);
const ListIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" aria-hidden="true"><rect x="4" y="4" width="6.5" height="6.5" rx="2" /><rect x="13.5" y="4" width="6.5" height="6.5" rx="2" /><rect x="4" y="13.5" width="6.5" height="6.5" rx="2" /><rect x="13.5" y="13.5" width="6.5" height="6.5" rx="2" /></svg>
);
const PadIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M4 20l1-4.5L15.5 5a2.1 2.1 0 0 1 3 3L8 18.5z" /><path d="M13.5 7l3 3" /></svg>
);

/** answers lie in even rows, never one left on its own (G 2026-10-08 "3 answers is kind of odd"): up to 3 in one row, 4 as two by two */
const balanced = (n: number) => (n === 4 ? 2 : n > 4 ? 3 : n);


export function Practice() {
  const { progress, go, act, finish } = useApp();
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
      // the problem list open in place takes Escape for itself: it closes, and the page stays (Review)
      if (e.key === "Escape" && zoomOut) { e.preventDefault(); setZoomOut(false); return; }
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
    if (!s || (s.mode === "test" && !isCheckKey(s.key))) return [null, false];
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
  const [hintOpen, setHintOpen] = useState(false), [, setStepsOpen] = useState(wideSteps), [asking] = useState(false);
  // every problem zoomed out, to pick which one comes next (G 2026-10-08): a pinch closed or a tap on "Problem 2 of 6"
  const [zoomOut, setZoomOut] = useState(false);
  // the scratch pad: open or not stays as the learner left it; its ink stays until the next problem (G 2026-10-09)
  const [scratch, setScratch] = useState(false), [ink, setInk] = useState<Stroke[]>([]);
  useEffect(() => { setInk([]); }, [s?.i, s?.t0]);
  // a new problem (or the skill check starting) opens the solve panel at its top, its step bar showing, wherever the
  // focused key had scrolled it to on a phone
  useEffect(() => { const el = document.querySelector("#app .v-solve"); if (el) el.scrollTop = 0; }, [s?.i, s?.t0]);
  // the pad and the picture swap with a fade of their own tile only, out then in; the page around them stays still (G 2026-10-09
  // "the blink animation it does is too much just fade that box")
  const [padFade, setPadFade] = useState(false);
  const swapPad = () => {
    const still = typeof matchMedia !== "undefined" && matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (still) { setScratch(o => !o); return; }
    setPadFade(true);
    setTimeout(() => { setScratch(o => !o); requestAnimationFrame(() => setPadFade(false)); }, 250);
  };
  useEffect(() => {
    const on = () => { setHintOpen(false); setZoomOut(true); };
    addEventListener("bento:problems", on);
    return () => removeEventListener("bento:problems", on);
  }, []);
  // with no picture the question is the whole problem, so the steps start folded and the question leads (G 2026-10-08)
  const picRef = useRef(true);
  const askRef = useRef(false);
  // the steps stay open where there's room for them: beside a picture, or in a test whose question sits in the pad once
  // there's work done to show (a test lists only the steps done and the one you're on)
  const openSteps = () => wideSteps() && (picRef.current || (askRef.current && (s?.step ?? 0) > 0));
  useEffect(() => { setHintOpen(false); setStepsOpen(openSteps()); }, [s?.i, s?.step, s?.solved]); // eslint-disable-line react-hooks/exhaustive-deps
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
  const test = s.mode === "test", mixed = s.mode !== "practice" && !isCheckKey(s.key), band = bandOfSession(s);
  // the skill check after a lesson: 4 problems on your own, each asked in one go (v2 model)
  const skill = isCheckKey(s.key);
  const tapOnly = !!s.pick || !!step?.choices;
  const at = `${s.i}-${s.step}`, mark = (i: number) => tapped?.at === at && tapped.i === i && fb ? (fb.type === "bad" ? " no" : " ok") : "";
  const nextLabel = !isLastProblem(s) ? "Next problem" : skill ? "See how you did" : test ? "Finish test" : s.mode === "review" ? "Finish review" : "Start the skill check";
  // "Solved." carries the lesson's last idea, in this problem's numbers
  const idea = !s.solved ? undefined : full?.solved ?? (full?.steps.length ? full.steps[full.steps.length - 1]!.narration : undefined);
  const shape = problemShape(it.lessonId, problemOf(it), !!it.story);
  // tests go without the explanation's picture (ex is null), but a problem drawn as its own picture keeps it: it IS the problem
  const canScratch = SCRATCH.has(it.lessonId), scratchOn = canScratch && scratch;
  // the scratch pad takes the picture's tile (or that room, where there's no picture)
  const pic = !!ex || shape.picture || scratchOn;
  picRef.current = pic;
  // the steps: done ones with their finished line, the one being answered, the ones still to come by number only
  // (their names could give a plan-the-step choice away)
  const steps = stepsOf(s), here = s.solved ? steps.length : s.step;
  const solo = !s.solved && steps[here] ? soloAsk(steps[here]!.prompt) : null;
  const lastWork = s.work[s.work.length - 1]?.math ?? [], lastTok = lastWork[lastWork.length - 1];
  const solvedAns = s.solved && lastTok?.t === "answer" ? lastTok.v : null;
  // in a test a wrong answer is shown, not solved: that step gets no tick, and the problem never says "Solved." or
  // lights its answer green (G 2026-10-08 "it shouldnt mark green or solve this is clearly wrong")
  const given = (k: number) => test && !!s.work[k]?.shown;
  const missed = s.solved && s.work.some((_, k) => given(k));
  function onNext() {
    if (s && isLastProblem(s)) finish();
    // the next problem is a step along the row, not a step deeper: it slides, the page never zooms (Review)
    else withTransition(() => act((st, p, d) => nextProblem(st, p, d)), "next");
  }

  const hintable = !test && !!step && !s.pick && !s.solved;
  const listOn = zoomOut && !test;
  // what the say line carries: wrong and right always with their cross or tick (G 2026-10-13: red and green only mean
  // wrong and right, never on their own); hints in the plain hint look
  const say = fbAway ? null : s.solved && fb?.type !== "hint"
    ? { cls: missed ? "slip" : "good", lead: missed ? "\u2715 Not this time." : test || full?.solved ? "\u2713 Right." : "\u2713 Solved.",
      text: missed ? (fb?.missed ? fb.text : undefined) : skill ? `${problemText(it)} = ${solvedAns != null ? formatNumber(solvedAns) : ""}.` : idea }
    : fb ? { cls: fb.type === "bad" ? "slip" : fb.type === "good" ? "good" : "hint",
      lead: fb.type === "bad" ? `\u2715 ${fb.strong ?? "Not quite."}` : fb.type === "good" ? `\u2713 ${fb.strong ?? "Right."}` : fb.strong, text: fb.text, lines: fb.lines }
    : skill && s.i === 0 && !s.prob.wrong && !s.work.length ? { cls: "hint", lead: undefined, text: `${SKILL_CHECK}: ${n} problems on your own, no hints. It shows how much stuck.`, lines: undefined } : null;
  // a wrong try wears red; a test's missed step only on a skill check's one answer, which keeps what was typed (v2 model)
  const askNo = !fbAway && fb?.type === "bad" && (!fb.missed || (skill && s.solved));
  const typedMiss = skill && missed ? s.mistakes[s.mistakes.length - 1]?.typed : undefined;
  const doneLines = steps.map((_, k) => s.work[k]).filter((w, k) => !!w && (k < here));
  return (
    <div className={`screen v-work v-prac${test ? " test" : ""}${s.solved ? " solved" : ""}`}>
      {/* the stage: the problem big, and its picture (or the scratch pad, or every problem in place) */}
      <section className={`v-panel v-stage${listOn ? " all" : ""}`} aria-label="Problem">
        {listOn ? <ProblemList s={s} pick={k => { setZoomOut(false); if (k !== s.i) withTransition(() => act((st, p, d) => goToProblem(st, k, p, d)), "next"); }} /> : <>
          {mixed && <span className="v-label">{lesson.title}</span>}
          <div className="v-prob pprob"><ProblemView lessonId={it.lessonId} problem={problemOf(it)} story={!!it.story} solved={s.solved} part="text" /></div>
          {scratchOn ? <ScratchPad className={`v-pad${padFade ? " pfade" : ""}`} ink={ink} setInk={setInk} /> : pic && (
            <div className={`v-ppic${padFade ? " pfade" : ""}`} aria-label="Picture of this problem" role="img">
              <div className="viz">{ex
                ? <Diagram key={s.i} diagram={ex.diagram!} timeline={ex.timeline} fit turn={!it.story} {...pictureAt(ex, steps.map(st => st.id), here, s.solved)} />
                : <ProblemView lessonId={it.lessonId} problem={problemOf(it)} story={!!it.story} part="picture" step={s.solved ? undefined : steps[here]?.id} />}</div>
            </div>
          )}
        </>}
      </section>
      {/* the working side: where you are in the steps, what you've worked out, the question, the say line, the tools, the keys */}
      <section className="v-panel v-solve" aria-label="Solve">
        <div className="v-steps">
          {skill ? <>
            <span className="n">{SKILL_CHECK}</span>
            <span className="v-seg" aria-hidden>{s.items.map((_, k) => <i key={k} className={(s.done ?? []).includes(k) || (k === s.i && s.solved) ? "on" : undefined} />)}</span>
          </> : s.solved ? <span className="n">{missed ? "Done" : "Solved"}</span> : <>
            <span className="n">{s.pick ? "What comes next?" : `Step ${Math.min(here + 1, steps.length)} of ${steps.length}`}</span>
            <span className="v-seg" aria-hidden>{steps.map((_, k) => <i key={k} className={k < here ? "on" : undefined} />)}</span>
          </>}
          {test && !skill && <span className="v-meta">{s.title}: no hints, one try per step</span>}
        </div>
        {doneLines.length > 0 && !skill && <ol className="v-lines" aria-label="Your work so far">{doneLines.map((w, k) => (
          <li key={k} className={w!.shown ? "shown" : undefined}><MathLine math={w!.math} />{!w!.shown && <b aria-hidden>{"\u2713"}</b>}</li>
        ))}</ol>}
        <div className={`v-ask${askNo ? " no" : ""}${s.fx === "shake" ? " shake" : ""}`}>
          {step && !s.pick ? <>
            {skill && step.id === "final" && !it.story ? <>
              <span className="q2">What is {problemText(it)}?</span>
              <div className="v-ans" key={`${at}-${s.mistakes.length}`}>
                <MathLine math={step.prompt} values={s.values} active={s.active} onSlot={id => act(st => focusSlot(st, id))} />
              </div>
            </> : <>
            {step.question && <span className="q"><Rich text={step.question} /></span>}
            {solo ? <>
              {/* one number to find: the question in words, then the answer pill (v2 spec P7, P8) */}
              {!step.question && <span className="q2">What is <MathLine math={solo.expr} />?</span>}
              <div className="v-ans" key={`${at}-${s.mistakes.length}`}>
                <MathLine math={[solo.slot]} values={s.values} active={s.active} onSlot={id => act(st => focusSlot(st, id))} />
              </div>
            </> : <div className="ask" key={`${at}-${s.mistakes.length}`}>
              <MathLine math={step.prompt} values={s.values} active={s.active} onSlot={id => act(st => focusSlot(st, id))} />
            </div>}
            {step.note && !skill && <span className="note"><Rich text={step.note} /></span>}
            </>}
          </> : s.pick ? <span className="q">You plan this one: tap the step that comes next.</span>
            : solvedAns != null ? <><span className="q2">{missed ? (skill ? "Not this time." : "Here's the answer.") : skill ? "Right." : "Solved."}</span>
              <div className={`v-ans ${missed ? "given" : "ok"}`}><span className="slot">{typedMiss ?? formatNumber(solvedAns)}</span></div></>
            : <div className={`ask ${missed ? "given" : "ok"}`}><MathLine math={s.work[s.work.length - 1]?.math ?? []} /></div>}
        </div>
        <div className={`v-say${say ? ` ${say.cls}` : ""}`} role="status" aria-live="polite">
          {say && <>{say.lead && <b><Rich text={say.lead} /></b>}{say.lead && say.text ? " " : ""}{say.text && <Rich text={say.text} />}
            {say.lines?.filter(l => !/Show me/.test(l)).map((l, i) => <span key={i}> <Rich text={l} /></span>)}
            {!s.solved && fb?.type !== "good" && showMeAvailable(s) && <button className="v-link" onClick={() => act((st, p, d) => showMe(st, p, d))}>{SHOW_ME} the step</button>}</>}
        </div>
        <div className="v-tools" role="toolbar" aria-label="Tools">
          {!test && <button className="v-tool" disabled={!hintable || (!s.hintsLeft && !s.hinted)} aria-label={`Hint, ${s.hintsLeft} left`} onClick={() => { setZoomOut(false); act((st, _p, d) => hint(st, d)); }}>
            <BulbIcon /><em aria-hidden>{s.hintsLeft}</em></button>}
          {canScratch && <button className="v-tool" aria-pressed={scratchOn} aria-label="Scratch pad" onClick={() => { setZoomOut(false); swapPad(); }}><PadIcon /></button>}
          {!test && n > 1 && <button className="v-tool" aria-pressed={listOn} aria-label="Problems" onClick={() => { if (scratchOn) setScratch(false); setZoomOut(o => !o); }}><ListIcon /></button>}
          <button className="v-tool" aria-label="Read it to me" onClick={() => speak([step?.question, document.querySelector("#app .pprob")?.textContent].filter(Boolean).join(". ").replace(/\*\*/g, ""))}><SpeakerIcon /></button>
          {skipAvailable(s) && <button className="v-plain v-skip" onClick={() => act((st, _p, d) => toggleSkip(st, d))}>{s.skip ? "Show steps" : "Final answer only"}</button>}
        </div>
        <Keypad band={band} tap={step && tapOnly ? (
          <div className="tappad">
            <div className="choices" style={{ "--cols": balanced((s.pick ? s.pick.options : step.choices!).length) } as CSSProperties}>{s.pick
              ? s.pick.options.map((o, i) => <button key={`${i}-${o}`} className={`choice${mark(i)}`} onClick={() => { setTapped({ at, i }); act(st => pickPlan(st, i)); }}>{o}</button>)
              : step.choices!.map((o, i) => <button key={`${i}-${o}`} className={`choice${mark(i)}`} onClick={() => { setTapped({ at, i }); act((st, p, d) => choose(st, i, p, d)); }}>{o}</button>)}</div>
          </div>) : undefined}
          solved={s.solved} plain={plain} onKey={key => { if (fb?.type === "bad") setFbAway(true); act(st => pressKey(st, key)); }}
          go={s.solved ? { label: nextLabel, run: onNext } : tapOnly ? undefined : { label: "Check", run: () => act((st, p, d) => check(st, p, d)) }} />
      </section>
    </div>
  );
}

/**
 * Every problem in place (G 2026-10-13): the stage swaps its picture for a tile per problem, the box's own cover tile with
 * the problem big on top, a small ring for its steps and one word. Tap one to go there; Problems again to go back.
 */
function ProblemList({ s, pick }: { s: PracticeSession; pick: (k: number) => void }) {
  const done = new Set(s.done ?? []), n = s.items.length;
  return (<div className="v-plist">
    <div className="v-bh"><b>This practice</b><span className="v-meta">{done.size} of {n} done</span></div>
    {s.items.map((item, k) => {
      const finished = done.has(k) || (k === s.i && s.solved), now = k === s.i, open = now || canPick(s, k);
      const word = finished ? "Done" : now ? "Now" : "To do";
      return <Cover key={k} pick={now} disabled={!open} className="v-ptile" pic={<span className="v-pq"><ProblemLine lessonId={item.lessonId} problem={problemOf(item)} solved={finished} /></span>}
        p={finished ? 1 : now ? s.step / Math.max(1, stepsOf(s).length) : 0} word={word} tone={now && !finished ? "next" : undefined}
        onClick={() => pick(k)} aria-label={`Problem ${k + 1}, ${word}`} />;
    })}
  </div>);
}

/** A Web Animations timing taken from the motion tokens: one of the --m-* durations, on --m-ease. */

/**
 * Where the lesson's picture stands on this step (v2 spec G3, G5): every part already worked out is shown with its
 * result, and the part being asked about now is lit (filled, its labels deep) without its answer. Steps are matched to
 * the picture by their answer step id, since a worked example can have steps the child doesn't answer (the split).
 */
export function pictureAt(ex: Explanation, ids: string[], here: number, solved: boolean): { at: number; ask?: number } {
  const last = ex.timeline.length - 1;
  if (solved) return { at: last };
  // a worked example that doesn't name its answer steps lines up with them one to one, as before
  if (!ex.steps.some(e => e.answerStep)) return { at: Math.min(last, here > 0 ? ex.steps[here - 1]?.state ?? 0 : 0) };
  const stateOf = (id: string | undefined) => ex.steps.find(e => e.answerStep === id)?.state;
  const done = ids.slice(0, here).map(stateOf).filter((x): x is number => x != null);
  return { at: Math.min(last, Math.max(0, ...done)), ask: stateOf(ids[here]) };
}

/** a problem as one plain line ("24 × 13"), for the skill check's question and its say line */
const problemText = (it: ReturnType<typeof currentItem>) => plainProblem(it.lessonId, problemOf(it));

/** A step that asks for one number at the end ("13 × 10 = □") reads as a question and an answer pill, like the model. */
export function soloAsk(prompt: MathText): { expr: MathText; slot: MathToken } | null {
  const n = prompt.length, last = prompt[n - 1], eq = prompt[n - 2];
  if (n < 3 || last?.t !== "slot" || eq?.t !== "op" || eq.v !== "=" || prompt.slice(0, -1).some(t => t.t === "slot" || t.t === "answer")) return null;
  return { expr: prompt.slice(0, -2), slot: last };
}
