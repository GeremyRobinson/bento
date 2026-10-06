import { useLayoutEffect, useRef, useState, type CSSProperties, type ReactNode } from "react";

/**
 * Screen (master): the frame every app screen sits in, under the island. Instances only say what differs:
 * `split` for a list beside its detail (on a phone, one at a time), `fit` for a screen that must fit without the
 * page scrolling, `solve` (WorkScreen) for one problem at a time (the problem beside its answer pad). Only a list or a sheet may scroll inside itself (Design, handoff 5).
 */
export function SplitScreen({ list, detail, show, label }: { list: ReactNode; detail: ReactNode; show: "list" | "detail"; label: string }) {
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
    <div className={`screen split show-${show}`}>
      <nav className={`slist${more ? " more" : ""}`} aria-label={label} ref={nav} onScroll={check}>{list}</nav>
      <section className="sdetail">{detail}</section>
    </div>
  );
}

export function FitScreen({ children, className, style }: { children: ReactNode; className?: string; style?: CSSProperties }) {
  return <div className={`screen fit${className ? ` ${className}` : ""}`} style={style}>{children}</div>;
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
