import { useLayoutEffect, useRef, type CSSProperties, type ReactNode } from "react";
import { Rich } from "../primitives/MathLine";
import { Pill } from "../primitives/Pill";
import type { Feedback } from "../../engine/session/types";

const DOT = { good: "ok", bad: "err", hint: "busy" } as const;

/** Bento's own little celebration: a burst of short rays (bigger for a whole problem done), in place of an emoji. */
const Burst = ({ big }: { big?: boolean }) => (
  <svg className={`pop${big ? " big" : ""}`} viewBox="0 0 24 24" width={big ? 26 : 20} height={big ? 26 : 20} aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round">
    {Array.from({ length: big ? 8 : 6 }, (_, i) => { const a = (i / (big ? 8 : 6)) * Math.PI * 2; return <line key={i} x1={12 + Math.cos(a) * 5} y1={12 + Math.sin(a) * 5} x2={12 + Math.cos(a) * 10} y2={12 + Math.sin(a) * 10} />; })}
  </svg>
);

/**
 * Feedback floats over the problem as a stack of pills that ripple in one at a time (UI notes preview): the message,
 * each extra line, how many hints are left, the lesson's last idea once it's solved, and one big next button.
 */
export function FeedbackBox({ fb, idea, next }: { fb: Feedback; idea?: string; next?: { label: string; go: () => void } }) {
  const rows: ReactNode[] = [
    <div key="m" className={`fpill fbm fb-${fb.type}`} role="status">
      <span className={`dot ${DOT[fb.type]}`} />
      <span>
        {fb.pop === "big" && <><Burst big /> </>}
        {fb.pop === "star" && <><Burst /> </>}
        {fb.strong && <strong><Rich text={fb.strong} /></strong>}{fb.strong && fb.text ? " " : ""}{fb.text && <Rich text={fb.text} />}
      </span>
    </div>,
    ...(idea ? [<div key="idea" className="fpill fbl"><span><Rich text={idea} /></span></div>] : []),
    ...(fb.lines ?? []).map((l, i) => <div key={`l${i}`} className="fpill fbl"><span><Rich text={l} /></span></div>),
    ...(fb.left != null ? [<div key="left" className="fpill fbl muted">{fb.left ? `${fb.left} hint${fb.left === 1 ? "" : "s"} left` : "That was the last hint in this lesson."}</div>] : []),
    ...(next ? [<Pill key="go" go className="fbgo" onClick={next.go}>{next.label}</Pill>] : []),
  ];
  // on a wide screen it floats over the bottom of the problem column, never below the screen's edge; once the problem
  // is solved the keypad is gone, so it moves to that side and leaves the finished picture in view
  const ref = useRef<HTMLDivElement>(null), done = !!next;
  useLayoutEffect(() => {
    const el = ref.current, col = done ? el?.closest(".split")?.lastElementChild ?? el?.parentElement : el?.parentElement;
    if (!el || !col) return;
    const place = () => {
      const r = col.getBoundingClientRect();
      el.style.setProperty("--fb-left", `${r.left}px`);
      el.style.setProperty("--fb-width", `${r.width}px`);
      el.style.setProperty("--fb-bottom", `${Math.max(0, innerHeight - r.bottom)}px`);
      el.style.setProperty("--fb-top", `${Math.max(0, r.top)}px`);
    };
    place();
    addEventListener("resize", place); addEventListener("scroll", place, true);
    return () => { removeEventListener("resize", place); removeEventListener("scroll", place, true); };
  }, [done]);
  return (
    <div ref={ref} className={`fstack pfb${done ? " side" : ""}`} style={{ "--n": rows.length } as CSSProperties}>
      {rows.map((r, i) => <div key={i} className="fbrow" style={{ "--i": i } as CSSProperties}>{r}</div>)}
    </div>
  );
}
