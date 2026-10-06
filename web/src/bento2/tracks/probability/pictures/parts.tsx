// Small shared pieces for Probability's pictures: the colours (as the room's tokens, never raw), a scale, histogram
// bars, action buttons, and a reveal clock that plays a run out once (with Less motion it shows the finished run).
import type { ReactNode } from "react";
import { useClock } from "../../../ui/kit";

/** each colour is one part of the idea; green and red only ever mean right and wrong */
export const K = {
  sky: "var(--b2-sky)", pink: "var(--b2-pink)", amber: "var(--b2-amber)", mint: "var(--b2-mint)", trav: "var(--b2-violet)",
  text: "var(--text)", muted: "var(--muted)", faint: "var(--faint)", line: "var(--b2-line)", grid: "var(--b2-grid)",
  right: "var(--ok)", wrong: "var(--b2-wrong)",
} as const;
export type Tone = "sky" | "pink" | "amber" | "mint" | "trav";

/** a linear map from [d0, d1] to [r0, r1] */
export const lin = (d0: number, d1: number, r0: number, r1: number) => (x: number) => r0 + ((x - d0) / (d1 - d0)) * (r1 - r0);
export const clamp = (x: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, x));

/** a row of action buttons under a picture */
export function Acts({ children }: { children: ReactNode }) {
  return <span className="b2acts" style={{ display: "inline-flex", flexWrap: "wrap", gap: "6px" }}>{children}</span>;
}
export function Act({ onClick, children, on, label }: { onClick: () => void; children: ReactNode; on?: boolean; label?: string }) {
  return <button type="button" className="ctl" aria-pressed={on} aria-label={label} onClick={onClick}>{children}</button>;
}

/** histogram bars from counts: x positions for each bin's left edge, heights scaled to the tallest (or to `top`) */
export function Bars({ counts, x, w, base, height, tone, top, opacity = 0.85, outline }: {
  counts: number[]; x: (i: number) => number; w: number; base: number; height: number; tone: string; top?: number; opacity?: number; outline?: boolean;
}) {
  const max = top ?? Math.max(1e-12, ...counts);
  return (
    <g>
      {counts.map((c, i) => {
        const h = (c / max) * height;
        return h > 0.2 ? <rect key={i} x={x(i)} y={base - h} width={Math.max(0.5, w)} height={h} rx={Math.min(2, w / 3)}
          style={outline ? { fill: "none", stroke: tone, strokeWidth: 1.5 } : { fill: tone, fillOpacity: opacity }} /> : null;
      })}
    </g>
  );
}

/**
 * Progress of a run that plays out once over `secs` seconds (0 → 1) and then holds at 1. A new `key` starts it again.
 * With Less motion it is 1 at once, so the finished picture shows everything.
 */
export function useRunOut(play: boolean, secs: number, key = 0): number {
  const t = useClock(play, 1e6 + key * 1e-3);
  return play ? Math.min(1, t / secs) : 1;
}

/** "1,234" */
export const commas = (n: number) => Math.round(n).toLocaleString("en-US");

/** a Toggle whose buttons wrap onto a second line in a narrow card (tool panel, phone), for pickers with many choices */
export function WrapToggle<T extends string>({ value, options, onChange, label }: { value: T; options: { v: T; label: string }[]; onChange: (v: T) => void; label: string }) {
  return (
    <span className="b2toggle" role="group" aria-label={label} style={{ flexWrap: "wrap", borderRadius: "18px", maxWidth: "100%" }}>
      {options.map(o => <button type="button" key={o.v} aria-pressed={o.v === value} onClick={() => onChange(o.v)}>{o.label}</button>)}
    </span>
  );
}
