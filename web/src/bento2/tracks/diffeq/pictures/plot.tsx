// The pieces every Differential equations picture is drawn with: a box that maps numbers to the picture, arrows, an
// arrow field, paths that run in over time, and a tap that starts a solution where the finger lands.
import { ArrowHead, path, useClock } from "../../../ui/kit";
import { solve, type Field, type Method } from "../maths";

export interface Box { l: number; r: number; t: number; b: number }
/** maps (x, y) in [x0, x1] × [y0, y1] into the box, y up */
export function frame(x0: number, x1: number, y0: number, y1: number, box: Box) {
  const X = (x: number) => box.l + ((x - x0) / (x1 - x0)) * (box.r - box.l);
  const Y = (y: number) => box.b - ((y - y0) / (y1 - y0)) * (box.b - box.t);
  const ix = (px: number) => x0 + ((px - box.l) / (box.r - box.l)) * (x1 - x0);
  const iy = (py: number) => y0 + ((box.b - py) / (box.b - box.t)) * (y1 - y0);
  return { X, Y, ix, iy, x0, x1, y0, y1, box };
}
export type Frame = ReturnType<typeof frame>;

/** a straight arrow with a head */
export function Arrow({ x1, y1, x2, y2, cls = "", w = 2 }: { x1: number; y1: number; x2: number; y2: number; cls?: string; w?: number }) {
  if (Math.hypot(x2 - x1, y2 - y1) < 2) return null;
  return (
    <g>
      <line x1={x1} y1={y1} x2={x2} y2={y2} className={`b2leg ${cls}`} style={{ strokeWidth: w }} />
      <ArrowHead x1={x1} y1={y1} x2={x2} y2={y2} className={`b2dot ${cls}`} />
    </g>
  );
}

/** a field of small arrows, all the same length, pointing the way the flow goes */
export function FieldArrows({ fr, f, n = 11, len = 11, faint = true }: { fr: Frame; f: (x: number, y: number) => [number, number]; n?: number; len?: number; faint?: boolean }) {
  const out = [];
  const { box } = fr, dx = (box.r - box.l) / n, dy = (box.b - box.t) / n;
  for (let i = 0; i < n; i++) for (let j = 0; j < n; j++) {
    const px = box.l + (i + 0.5) * dx, py = box.t + (j + 0.5) * dy;
    const [u, v] = f(fr.ix(px), fr.iy(py));
    // the direction in picture units (y flips)
    const a = (u * (box.r - box.l)) / (fr.x1 - fr.x0), b = (-v * (box.b - box.t)) / (fr.y1 - fr.y0), m = Math.hypot(a, b);
    if (!Number.isFinite(m)) continue;
    if (m < 1e-9) { out.push(<circle key={`${i}-${j}`} cx={px} cy={py} r="1.5" className="b2dot" opacity={0.35} />); continue; }
    const ex = px + (a / m) * len, ey = py + (b / m) * len;
    out.push(
      <g key={`${i}-${j}`} opacity={faint ? 0.45 : 0.8}>
        <line x1={px - (a / m) * len * 0.4} y1={py - (b / m) * len * 0.4} x2={ex} y2={ey} className="b2axis" style={{ strokeWidth: 1.2 }} />
        <ArrowHead x1={px} y1={py} x2={ex} y2={ey} className="b2dot" />
      </g>,
    );
  }
  return <g aria-hidden>{out}</g>;
}

/** a 2D system's path from a start, forward for tmax (and backward when asked), as picture points */
export function trajectory(fr: Frame, f: (x: number, y: number) => [number, number], start: [number, number], tmax: number, h = 0.02, method: Method = "rk4", back = false) {
  const F: Field = (_t, y) => f(y[0]!, y[1]!);
  const keep = (pts: { y: number[] }[]) => {
    const out: [number, number][] = [];
    const big = 4 * Math.max(fr.x1 - fr.x0, fr.y1 - fr.y0);
    for (const p of pts) {
      if (Math.abs(p.y[0]! - (fr.x0 + fr.x1) / 2) > big || Math.abs(p.y[1]! - (fr.y0 + fr.y1) / 2) > big) break;
      out.push([fr.X(p.y[0]!), fr.Y(p.y[1]!)]);
    }
    return out;
  };
  const fwd = keep(solve(F, start, 0, tmax, h, method));
  if (!back) return fwd;
  const bwd = keep(solve((t, y) => F(t, y).map(v => -v), start, 0, tmax, h, method)).reverse();
  return [...bwd, ...fwd.slice(1)];
}

/** the first share k (0 to 1) of a path */
export const part = (pts: [number, number][], k: number) => path(pts.slice(0, Math.max(2, Math.ceil(pts.length * Math.min(1, Math.max(0, k))))));

/** a run that plays once over `secs` and then holds; Less motion shows it finished */
export function useRun(play: boolean, secs: number) {
  const t = useClock(play, 1e6);
  return play ? Math.min(1, t / secs) : 0;
}
/** a picture that keeps moving (a swing, a bounce): seconds, looping; Less motion holds `still` */
export const useLoop = (still = 0) => useClock(true, still);
