import { useEffect, useLayoutEffect, useRef, useState, type CSSProperties, type ReactNode } from "react";
import { reduceMotion } from "../../app/transition";

/**
 * Screen (master): the frame every app screen sits in, under the island. Instances only say what differs:
 * `split` for a list beside its detail (on a phone, one at a time), `fit` for a screen that must fit without the
 * page scrolling, `solve` (WorkScreen) for one problem at a time (the problem beside its answer pad). Only a list or a sheet may scroll inside itself (Design, handoff 5).
 */
export function SplitScreen({ list, detail, show, label, className, detailLabel }: { list: ReactNode; detail: ReactNode; show: "list" | "detail"; label: string; className?: string; /** id of the detail's heading */ detailLabel?: string }) {
  // a list taller than its pane fades out at the bottom while more waits below (Review v39 item 12)
  const nav = useRef<HTMLElement>(null);
  const [more, setMore] = useState(false);
  const check = () => { const n = nav.current; if (n) setMore(n.scrollHeight - n.scrollTop - n.clientHeight > 4); };
  useLayoutEffect(() => {
    check();
    if (typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver(check);
    if (nav.current) { ro.observe(nav.current); for (const c of nav.current.children) ro.observe(c); }
    return () => ro.disconnect();
  });
  return (
    <div className={`screen split show-${show}${className ? ` ${className}` : ""}`}>
      <nav className={`slist${more ? " more" : ""}`} aria-label={label} ref={nav} onScroll={check}>{list}</nav>
      <section className="sdetail" aria-labelledby={detailLabel}>{detail}</section>
    </div>
  );
}

export function FitScreen({ children, className, style }: { children: ReactNode; className?: string; style?: CSSProperties }) {
  const root = useRef<HTMLDivElement>(null);
  useFollowStep(root);
  return <div className={`screen fit${className ? ` ${className}` : ""}`} style={style} ref={root}>{children}</div>;
}

/**
 * A column that scrolls inside itself follows the step that's now (`data-state="now"`, Learn's steps): as a step becomes
 * current it is brought into view, and on the last step whatever closes the column under it ("That's the whole
 * problem. Your turn.") comes into view with it, without pushing the step's top out (v44 sweep item 1). It only moves
 * when the current step changes or the column grows, so it never fights your own scrolling. Less motion jumps there.
 */
function useFollowStep(root: { current: HTMLElement | null }) {
  useEffect(() => {
    const el = root.current;
    if (!el || typeof MutationObserver === "undefined") return;
    let last: Element | null = null, lastH = 0, frame = 0;
    const follow = () => {
      frame = 0;
      const now = el.querySelector<HTMLElement>('[data-state="now"]');
      if (!now) { last = null; return; }
      let box = now.parentElement;
      while (box && box !== el && !/(auto|scroll)/.test(getComputedStyle(box).overflowY)) box = box.parentElement;
      if (!box || box === el || box.scrollHeight <= box.clientHeight + 1) { last = now; return; }
      if (now === last && box.scrollHeight <= lastH) return;
      last = now; lastH = box.scrollHeight;
      const pad = 8, b = box.getBoundingClientRect(), r = now.getBoundingClientRect();
      // the last step brings the rest of its column (the closing line) along
      const end = now.nextElementSibling ? r.bottom : b.top - box.scrollTop + box.scrollHeight;
      let by = 0;
      if (r.top < b.top + pad) by = r.top - b.top - pad;
      else if (end > b.bottom - pad) by = Math.min(end - b.bottom + pad, r.top - b.top - pad);
      if (Math.abs(by) > 1 && typeof box.scrollBy === "function") box.scrollBy({ top: by, behavior: reduceMotion() ? "auto" : "smooth" });
    };
    const mo = new MutationObserver(() => { if (!frame) frame = requestAnimationFrame(follow); });
    mo.observe(el, { subtree: true, childList: true, attributes: true, attributeFilter: ["data-state"] });
    return () => { mo.disconnect(); if (frame) cancelAnimationFrame(frame); };
  }, [root]);
}

/**
 * `solve` (WorkScreen): one problem at a time, in every mode (lessons, unit tests, check-ups, review, Find my level, a facts sprint).
 * Where you are rides on top (`head`), and a test says its rules in a kicker line over the problem, not a bar of its
 * own. The problem sits on one side and the answer pad on the other; in portrait and on a phone they stack, the pad at
 * the bottom. Nothing makes the page scroll: a long problem shrinks its picture, then scrolls inside its own column.
 */
export function WorkScreen({ head, kicker, problem, pad, className }: { head?: ReactNode; kicker?: ReactNode; problem: ReactNode; pad: ReactNode; className?: string }) {
  const root = useRef<HTMLDivElement>(null);
  useLayoutEffect(() => {
    const el = root.current;
    if (!el) return;
    const fit = () => el.querySelectorAll<HTMLElement>(FIT_LINES).forEach(fitLine);
    fit();
    if (typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver(fit);
    ro.observe(el);
    return () => ro.disconnect();
  });
  return (
    <div className={`screen solve${className ? ` ${className}` : ""}`} ref={root}>
      {head && <header className="whead">{head}</header>}
      <section className="panel split wbody">
        <div className="col wprob">{kicker && <p className="wkick">{kicker}</p>}{problem}</div>
        <div className="col wpad">{pad}</div>
      </section>
    </div>
  );
}

/** the problem's lines and the step's line: each one fits its card (G 2026-10-06, a check-up's line ran off the card) */
const FIT_LINES = ".wq .math, .wq .workline .wl, .wstep .ask, .fq .fask";
/** the smallest a line steps down to: still easy to read on a phone */
const MIN_PX = 12;
/** No line can run off its card: one that can't wrap (a limit, a long equation) steps its type down until it fits. */
function fitLine(el: HTMLElement) {
  el.style.fontSize = "";
  const over = () => el.scrollWidth > el.clientWidth + 1 || [...el.children].some(c => c.scrollWidth > c.clientWidth + 1 || c.getBoundingClientRect().width > el.clientWidth + 1);
  let size = parseFloat(getComputedStyle(el).fontSize);
  for (let i = 0; i < 12 && size > MIN_PX && over(); i++) { size = Math.max(MIN_PX, size * 0.9); el.style.fontSize = `${size}px`; }
}
