// The flat plane every 2D picture in this track draws on: picture coordinates to SVG and back, the grid, arrows with
// heads, and soft fills in the room's picture colours (sky, pink, amber, mint, violet). Green and red are never used
// here: they stay for right and wrong.
import type { CSSProperties, ReactNode } from "react";
import { ArrowHead } from "../../../ui/kit";
import { matNum } from "../../../tools/MatrixPad";

export type Tone = "sky" | "pink" | "amber" | "mint" | "trav";
const VAR: Record<Tone, string> = { sky: "--b2-sky", pink: "--b2-pink", amber: "--b2-amber", mint: "--b2-mint", trav: "--b2-violet" };
/** a soft fill in one of the picture colours */
export const tint = (t: Tone, o = 0.14): CSSProperties => ({ fill: `var(${VAR[t]})`, fillOpacity: o, stroke: "none" });
/** a fill and a hairline edge */
export const tintEdge = (t: Tone, o = 0.14): CSSProperties => ({ fill: `var(${VAR[t]})`, fillOpacity: o, stroke: `var(${VAR[t]})`, strokeWidth: 1.5 });
/** a stroke in one of the picture colours */
export const ink = (t: Tone, w = 2, dash?: string): CSSProperties => ({ stroke: `var(${VAR[t]})`, strokeWidth: w, fill: "none", ...(dash ? { strokeDasharray: dash } : {}) });

export interface Plane {
  W: number; H: number; s: number;
  X: (x: number) => number; Y: (y: number) => number;
  P: (v: number[]) => [number, number];
  back: (px: number, py: number) => [number, number];
  x0: number; x1: number; y0: number; y1: number;
}

/** A plane showing x from x0 to x1 and y from y0 to y1, centered in a W × H picture, the same scale both ways. */
export function plane(x0: number, x1: number, y0: number, y1: number, W = 360, H = 280): Plane {
  const s = Math.min(W / (x1 - x0), H / (y1 - y0));
  const ox = (W - (x1 - x0) * s) / 2, oy = (H - (y1 - y0) * s) / 2;
  const X = (x: number) => ox + (x - x0) * s, Y = (y: number) => H - oy - (y - y0) * s;
  // what's visible, which can be wider than asked for in one direction
  const vx0 = x0 - ox / s, vx1 = x1 + ox / s, vy0 = y0 - oy / s, vy1 = y1 + oy / s;
  return { W, H, s, X, Y, P: v => [X(v[0]!), Y(v[1]!)], back: (px, py) => [x0 + (px - ox) / s, y0 + (H - oy - py) / s], x0: vx0, x1: vx1, y0: vy0, y1: vy1 };
}

/** whole-number grid lines and the two axes */
export function Grid({ p, step = 1 }: { p: Plane; step?: number }) {
  const xs: number[] = [], ys: number[] = [];
  for (let x = Math.ceil(p.x0 / step) * step; x <= p.x1; x += step) xs.push(x);
  for (let y = Math.ceil(p.y0 / step) * step; y <= p.y1; y += step) ys.push(y);
  return (
    <g>
      {xs.map(x => <line key={`x${x}`} x1={p.X(x)} y1={0} x2={p.X(x)} y2={p.H} className={x === 0 ? "b2axis" : "b2grid"} />)}
      {ys.map(y => <line key={`y${y}`} x1={0} y1={p.Y(y)} x2={p.W} y2={p.Y(y)} className={y === 0 ? "b2axis" : "b2grid"} />)}
    </g>
  );
}

/** A grid made of two arrows' steps (a skewed grid): lines k·a + t·b and t·a + k·b. */
export function SkewGrid({ p, a, b, n = 8, tone = "trav", o = 0.5 }: { p: Plane; a: number[]; b: number[]; n?: number; tone?: Tone; o?: number }) {
  const L = 40, lines: ReactNode[] = [];
  for (let k = -n; k <= n; k++) {
    const A = [k * a[0]! - L * b[0]!, k * a[1]! - L * b[1]!], B = [k * a[0]! + L * b[0]!, k * a[1]! + L * b[1]!];
    const C = [k * b[0]! - L * a[0]!, k * b[1]! - L * a[1]!], D = [k * b[0]! + L * a[0]!, k * b[1]! + L * a[1]!];
    lines.push(<line key={`a${k}`} x1={p.X(A[0]!)} y1={p.Y(A[1]!)} x2={p.X(B[0]!)} y2={p.Y(B[1]!)} style={{ ...ink(tone, k === 0 ? 1.6 : 1), opacity: k === 0 ? 0.9 : o }} />);
    lines.push(<line key={`b${k}`} x1={p.X(C[0]!)} y1={p.Y(C[1]!)} x2={p.X(D[0]!)} y2={p.Y(D[1]!)} style={{ ...ink(tone, k === 0 ? 1.6 : 1), opacity: k === 0 ? 0.9 : o }} />);
  }
  return <g>{lines}</g>;
}

/** An arrow from `from` to `to` (picture units) in a colour, with an optional label at its tip. */
export function Arrow({ p, from = [0, 0], to, tone, label, width = 2.6, dash, faint }: {
  p: Plane; from?: number[]; to: number[]; tone: Tone; label?: string; width?: number; dash?: string; faint?: boolean;
}) {
  const [x1, y1] = p.P(from), [x2, y2] = p.P(to);
  const len = Math.hypot(x2 - x1, y2 - y1);
  const ux = len ? (x2 - x1) / len : 0, uy = len ? (y2 - y1) / len : 0;
  return (
    <g className={tone} opacity={faint ? 0.45 : 1}>
      <line x1={x1} y1={y1} x2={x2 - ux * 5} y2={y2 - uy * 5} className="b2curve" style={{ strokeWidth: width, ...(dash ? { strokeDasharray: dash } : {}) }} />
      {len > 4 && <ArrowHead x1={x1} y1={y1} x2={x2} y2={y2} className="b2dot" />}
      {label && <text x={x2 + (ux >= 0 ? 6 : -6)} y={y2 + (uy > 0 ? 16 : -7)} textAnchor={ux >= 0 ? "start" : "end"} className={`b2t ${tone}`}>{label}</text>}
    </g>
  );
}

/** A round handle you can drag (a tip, a point, a test arrow). */
export function Handle({ at, drag, tone, r = 7 }: { at: [number, number]; drag?: object; tone?: Tone; r?: number }) {
  return (
    <g className={tone}>
      <circle cx={at[0]} cy={at[1]} r={r} className="b2handle" />
      {drag && <circle cx={at[0]} cy={at[1]} r={22} className="b2hit" {...drag} />}
    </g>
  );
}

/** A polygon through picture points. */
export const poly = (p: Plane, pts: number[][]) => pts.map(v => p.P(v).map(n => n.toFixed(1)).join(",")).join(" ");

/** "(3, −1)" for readouts, rounded to `places` (whole numbers stay whole) */
export const pt = (v: number[], places = 1) => `(${v.map(x => (Math.abs(x - Math.round(x)) < 1e-9 ? fmtInt(Math.round(x)) : fmtDec(x, places))).join(", ")})`;
const fmtInt = (x: number) => (x < 0 ? `−${-x}` : String(x));
const fmtDec = (x: number, k: number) => { const s = Math.abs(x).toFixed(k); return x < 0 && Number(s) ? `−${s}` : s; };
/** snap to the nearest half (or whole) so dragged arrows land on friendly numbers */
export const snap = (x: number, to = 1) => Math.round(x / to) * to;

/** A matrix as a readout: its name beside its entries, in brackets (2 × 2 or 3 × 3). */
export function MatRead({ label, M, tone, hide }: { label: string; M: number[][]; tone?: Tone; hide?: boolean }) {
  return (
    <span className="b2mat" aria-label={`${label}: ${M.map(r => r.map(x => matNum(x)).join(", ")).join("; ")}`}>
      <small>{label}</small>
      <span className={`b2grid2${tone ? ` tone-${tone}` : ""}`} style={{ gridTemplateColumns: `repeat(${M[0]!.length}, auto)` }}>
        {M.flat().map((x, i) => <b key={i}>{hide ? "?" : matNum(x)}</b>)}
      </span>
    </span>
  );
}
