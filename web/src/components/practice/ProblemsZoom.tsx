import { useEffect, useRef, useState, type CSSProperties } from "react";
import { createPortal } from "react-dom";
import { Pill } from "../primitives/Pill";
import { Check } from "../primitives/icons";
import { ProblemLine } from "./ProblemView";
import { reduceMotion } from "../../app/transition";
import { canPick, problemOf } from "../../engine/session/practice";
import type { PracticeSession } from "../../engine/session/types";

/**
 * The lesson or test zoomed out (G 2026-10-08: "a function similar to the zoom in out thing ... see how many questions
 * they have on a test and pick and choose which ones they'd like to answer first"). The same zoom as the contents: the
 * page steps back and every problem lies out as a card, solved ones with their answer. Tap one to do it next. A problem
 * you've started stays yours until it's solved, so one try per step still means one try.
 */
export function ProblemsZoom({ s, pick, close }: { s: PracticeSession; pick: (index: number) => void; close: () => void }) {
  const [closing, setClosing] = useState(false);
  const box = useRef<HTMLDivElement>(null);
  const done = new Set(s.done ?? []), n = s.items.length;
  // a started problem keeps you until it's solved: every other open card waits
  const held = !s.solved && !s.items.some((_, k) => canPick(s, k));
  const shut = (then?: () => void) => {
    if (closing) return;
    if (reduceMotion() || typeof matchMedia === "undefined") { then?.(); close(); return; }
    if (then) { then(); close(); return; }
    setClosing(true);
    setTimeout(close, 360);
  };

  // the page steps back while the problems are out, as it does for the contents
  useEffect(() => {
    const root = document.documentElement;
    if (!closing) root.dataset.zoomed = ""; else delete root.dataset.zoomed;
    return () => { delete root.dataset.zoomed; };
  }, [closing]);

  useEffect(() => {
    const el = box.current!;
    el.querySelector<HTMLElement>(".zprob.now")?.focus({ preventScroll: true });
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape" || e.key === "=" || e.key === "+") { e.preventDefault(); shut(); } };
    // pinching open (or a trackpad pinch out) zooms back into the problem
    let d0 = 0, acc = 0;
    const dist = (t: TouchList) => Math.hypot(t[0]!.clientX - t[1]!.clientX, t[0]!.clientY - t[1]!.clientY);
    const onStart = (e: TouchEvent) => { d0 = e.touches.length === 2 ? dist(e.touches) : 0; };
    const onMove = (e: TouchEvent) => {
      if (!d0 || e.touches.length !== 2) return;
      e.preventDefault();
      if (dist(e.touches) / d0 > 1.4) { d0 = 0; shut(); }
    };
    const onWheel = (e: WheelEvent) => {
      if (!e.ctrlKey) return;
      e.preventDefault();
      acc += e.deltaY;
      if (acc < -40) { acc = 0; shut(); }
    };
    addEventListener("keydown", onKey);
    el.addEventListener("touchstart", onStart, { passive: true });
    el.addEventListener("touchmove", onMove, { passive: false });
    el.addEventListener("wheel", onWheel, { passive: false });
    return () => { removeEventListener("keydown", onKey); el.removeEventListener("touchstart", onStart); el.removeEventListener("touchmove", onMove); el.removeEventListener("wheel", onWheel); };
  });

  const left = n - done.size;
  const lead = held ? `Finish problem ${s.i + 1} first. Then pick any problem you like.` : left ? "Tap a problem to do it next." : "Every problem is done.";
  const app = document.getElementById("app") ?? document.body;

  return createPortal(
    <div className={`zoom zprobs${closing ? " closing" : ""}`} ref={box} role="dialog" aria-modal="true" aria-label="Problems" onClick={e => { if (e.target === e.currentTarget) shut(); }}>
      <div className="zbar-top">
        <span />
        <span className="zcount">{done.size} of {n} solved</span>
        <Pill className="zclose" onClick={() => shut()}>Done</Pill>
      </div>
      <div className="zstage out">
        <section className="zplist">
          <header><span className="k">{s.title}</span><h2>{n} problem{n === 1 ? "" : "s"}</h2><p className="muted">{lead}</p></header>
          <div className="zpgrid">{s.items.map((item, k) => {
            const solved = done.has(k), now = k === s.i, open = canPick(s, k);
            const state = solved ? "Solved" : now ? (s.solved ? "Solved" : "Now") : "To do";
            return (
              <button key={k} className={`zcard zprob${solved || (now && s.solved) ? " done" : ""}${now ? " now on" : ""}`} style={{ "--i": k } as CSSProperties}
                disabled={!now && !open} aria-current={now ? "step" : undefined} aria-label={`Problem ${k + 1}, ${state.toLowerCase()}`}
                onClick={() => now ? shut() : shut(() => pick(k))}>
                <span className="zphead"><span className="badge">{solved || (now && s.solved) ? <Check /> : k + 1}</span><span className="k">{state}</span></span>
                <span className="zpline"><ProblemLine lessonId={item.lessonId} problem={problemOf(item)} solved={solved || (now && s.solved)} /></span>
              </button>
            );
          })}</div>
        </section>
      </div>
    </div>,
    app,
  );
}
