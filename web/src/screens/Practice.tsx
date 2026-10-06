import { Pill, PillLabel } from "../components/primitives/Pill";
import { useEffect, useMemo, useRef, useState } from "react";
import { playTone, readAloudOn, readSettings, speak } from "../app/settings";
import { useApp } from "../app/AppState";
import { withTransition } from "../app/transition";
import { MathLine, Rich } from "../components/primitives/MathLine";
import { ProblemView } from "../components/practice/ProblemView";
import { Diagram } from "../components/diagrams/Diagram";
import { requireLesson } from "../curriculum/registry";
import type { Explanation } from "../explanations/schema";
import { FeedbackBox } from "../components/practice/FeedbackBox";
import { Keypad } from "../components/practice/Keypad";
import { FitScreen, WorkScreen } from "../components/screen/Screen";
import { ALL_LESSONS, SHOW_ME } from "../app/copy";
import {
  bandOfSession, check, choose, currentItem, currentStep, focusSlot, hint, isLastProblem, lessonOfItem, nextProblem,
  pickPlan, pressKey, problemOf, showMe, showMeAvailable, skipAvailable, toggleSkip,
} from "../engine/session/practice";

const SpeakerIcon = () => (
  <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M4 9.5h3.5L12 5.5v13l-4.5-4H4z" /><path d="M15.5 9a4 4 0 0 1 0 6M18 6.5a7.5 7.5 0 0 1 0 11" /></svg>
);

/** One problem at a time: the problem and the finished lines on one side, the step, feedback and keypad on the other. */
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
    const t = setTimeout(() => speak(document.querySelector("#app .card")?.textContent ?? ""), 350);
    return () => clearTimeout(t);
  }, [s?.i, aloud]); // eslint-disable-line react-hooks/exhaustive-deps

  // read aloud: what the feedback says, as it appears
  const said = s?.feedback ? `${s.feedback.strong ?? ""} ${s.feedback.text ?? ""}`.replace(/\*\*/g, "").trim() : "";
  useEffect(() => { if (aloud && said) speak(said); }, [said, aloud]);

  // a physical keyboard works too: digits, minus, point, Backspace, Tab for the next box, Enter to check
  useEffect(() => {
    if (!s) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.metaKey || e.ctrlKey || e.altKey) return;
      // tap-to-answer steps and planning: 1–4 pick a choice
      const st = currentStep(s);
      if (s.pick || st?.choices) {
        if (/^[1-4]$/.test(e.key)) document.querySelectorAll<HTMLButtonElement>("#app .choice")[Number(e.key) - 1]?.click();
        return;
      }
      const map: Record<string, string> = { Backspace: "back", "-": "−", ".": ".", Tab: "next" };
      const key = /^\d$/.test(e.key) ? e.key : map[e.key];
      if (key) { e.preventDefault(); act(st => pressKey(st, key)); }
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

  // the tapped answer wears right or wrong on itself (UI notes preview)
  const [tapped, setTapped] = useState<{ at: string; i: number } | null>(null);
  // feedback and quick settings never overlap: opening settings puts the feedback away, and new feedback closes settings
  const [fbAway, setFbAway] = useState(false);
  const fbKey = s?.feedback ? `${s.i}-${s.step}-${s.mistakes.length}-${s.hints}-${s.feedback.strong}-${s.feedback.text}-${s.feedback.left}` : "";
  useEffect(() => {
    setFbAway(false);
    if (fbKey) dispatchEvent(new CustomEvent("bento:panel", { detail: "feedback" }));
  }, [fbKey]);
  useEffect(() => {
    const onPanel = (e: Event) => { if ((e as CustomEvent).detail === "settings") setFbAway(true); };
    // the light bulb up top asks for a hint
    const onHint = () => act((st, _p, d) => hint(st, d));
    addEventListener("bento:panel", onPanel); addEventListener("bento:hint", onHint);
    return () => { removeEventListener("bento:panel", onPanel); removeEventListener("bento:hint", onHint); };
  }, [act]);

  if (!s) {
    return (
      <FitScreen className="wnone"><section className="panel"><p className="empty">No lesson in progress.</p>
        <div className="actions"><Pill go onClick={() => go({ name: "home" })}>{ALL_LESSONS}</Pill></div></section></FitScreen>
    );
  }

  const it = currentItem(s), lesson = lessonOfItem(it), step = currentStep(s), fb = s.feedback, n = s.items.length;
  const test = s.mode === "test", mixed = s.mode !== "practice", band = bandOfSession(s);
  const tapOnly = !!s.pick || !!step?.choices;
  const at = `${s.i}-${s.step}`, mark = (i: number) => tapped?.at === at && tapped.i === i && fb ? (fb.type === "bad" ? " no" : " ok") : "";
  const nextLabel = s.i < n - 1 ? "Next problem" : test ? "Finish test" : s.mode === "review" ? "Finish review" : "Finish lesson";
  // "Right." carries the lesson's last idea, in this problem's numbers
  const idea = s.solved && full?.steps.length ? full.steps[full.steps.length - 1]!.narration : undefined;
  const showFb = !!fb && !fbAway;
  function onNext() {
    if (s && isLastProblem(s)) finish();
    else withTransition(() => act((st, p, d) => nextProblem(st, p, d)), "fwd");
  }

  return (
    <WorkScreen
      head={<>
        {mixed && <Pill onClick={quit}>Quit</Pill>}
        <span className="steps" aria-label={`Problem ${s.i + 1} of ${n}`}>
          {s.items.map((_, i) => <span key={i} className={`dot ${i < s.i ? "ok" : i === s.i ? "busy" : ""}`} />)}
        </span>
        <PillLabel badged><span className="badge on">{s.i + 1}</span>of <span className="mono">{n}</span></PillLabel>
      </>}
      kicker={test ? `${s.title}: no hints, one try per step` : undefined}
      problem={<>
        <div className="card wq">
          {mixed && <div className="label">{lesson.title}</div>}
          <ProblemView lessonId={it.lessonId} problem={problemOf(it)} story={!!it.story} />
          <div className="work">
            {s.work.map((w, k) => (
              <div key={k} className={`workline${w.shown ? " shown" : ""}${s.fx === "line" && k === s.work.length - 1 ? " enter" : ""}`}>
                <span className="k">Step {k + 1}</span><span className="wl"><MathLine math={w.math} /></span>
              </div>
            ))}
          </div>
        </div>
        {step && (
          <div key={`${s.i}-${s.step}-${s.collapsed}-${s.mistakes.length}`} className={`card wstep${s.fx === "shake" ? " shake" : ""}${s.fx === "line" ? " enter" : ""}`}>
            {s.pick ? (
              <div className="label">Step {s.step + 1} · What comes next?</div>
            ) : (
              <>
                <div className="label lspeak">{step.label}
                  <button className="speak" aria-label="Read it to me" onClick={() => speak([step.question, document.querySelector("#app .card")?.textContent].filter(Boolean).join(". ").replace(/\*\*/g, ""))}><SpeakerIcon /></button>
                </div>
                <div className={`ask${fb?.type === "bad" && !fbAway ? " no" : ""}`}>
                  {step.question && <span className="q"><Rich text={step.question} /></span>}
                  <MathLine math={step.prompt} values={s.values} active={s.active} onSlot={id => act(st => focusSlot(st, id))} />
                </div>
                {step.note && <div className="note"><Rich text={step.note} /></div>}
              </>
            )}
          </div>
        )}
        {showFb && <FeedbackBox key={fbKey} fb={fb!} idea={idea} next={step ? undefined : { label: nextLabel, go: onNext }} />}
        {ex && (
          <figure className="card ppic" aria-label="Picture of this problem">
            <div className="viz"><Diagram key={s.i} diagram={ex.diagram!} timeline={ex.timeline}
              at={s.solved ? ex.timeline.length - 1 : Math.min(ex.timeline.length - 1, s.step > 0 ? ex.steps[s.step - 1]?.state ?? 0 : 0)} /></div>
          </figure>
        )}
      </>}
      pad={<>
        {step && tapOnly && (
          // tap answers sit where the keypad goes, so they never fall below the fold beside a long problem
          <div className="tappad">
            <div className="tapnote muted">{s.pick ? "You plan this one: tap the step that comes next." : "Tap your answer."}</div>
            <div className="choices">{s.pick
              ? s.pick.options.map((o, i) => <button key={`${i}-${o}`} className={`choice${mark(i)}`} onClick={() => { setTapped({ at, i }); act(st => pickPlan(st, i)); }}>{o}</button>)
              : step.choices!.map((o, i) => <button key={`${i}-${o}`} className={`choice${mark(i)}`} onClick={() => { setTapped({ at, i }); act((st, p, d) => choose(st, i, p, d)); }}>{o}</button>)}</div>
          </div>
        )}
        {step && !tapOnly && <Keypad band={band} onKey={key => act(st => pressKey(st, key))} />}
        {step ? (
          <div className="actions">
            {showMeAvailable(s) && <Pill onClick={() => act((st, p, d) => showMe(st, p, d))}>{SHOW_ME}</Pill>}
            {skipAvailable(s) && <Pill onClick={() => act((st, _p, d) => toggleSkip(st, d))}>{s.skip ? "Show steps" : "Final answer only"}</Pill>}
            {!tapOnly && <Pill go onClick={() => act((st, p, d) => check(st, p, d))}>Check</Pill>}
          </div>
        ) : !showFb && (
          // the next button rides in the feedback stack; it waits here only while that stack is put away
          <div className="actions"><Pill go onClick={onNext}>{nextLabel}</Pill></div>
        )}
      </>}
    />
  );
}
