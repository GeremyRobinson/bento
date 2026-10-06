// Small pieces the orbit pictures share: an arrow, a conic drawn as an SVG path, and number formats.
import { ArrowHead, path } from "../../../ui/kit";
import { conicPoints, type Conic } from "../maths";

/** an arrow from (x1, y1) to (x2, y2), coloured by its part of the idea */
export function Arrow({ x1, y1, x2, y2, tone, thin }: { x1: number; y1: number; x2: number; y2: number; tone: string; thin?: boolean }) {
  if (Math.hypot(x2 - x1, y2 - y1) < 1.5) return null;
  return (
    <g className={tone}>
      <line x1={x1} y1={y1} x2={x2} y2={y2} className={thin ? "b2curve" : "b2leg"} style={thin ? { strokeWidth: 1.5 } : undefined} />
      <ArrowHead x1={x1} y1={y1} x2={x2} y2={y2} className="b2dot" />
    </g>
  );
}

/** a conic around the body at (cx, cy), `s` pixels per unit, cut at `rmax` units; SVG y points down */
export const conicPath = (c: Conic, cx: number, cy: number, s: number, rmax: number, part: "all" | "out" | "in" = "all") =>
  path(conicPoints(c, rmax, 160, part).map(([x, y]) => [cx + x * s, cy - y * s]));

/** "6,671" */
export const km = (x: number) => Math.round(x).toLocaleString("en-US");
/** a fixed number of places with a real minus sign and thousands commas */
export const nf = (x: number, places = 2) => (x < 0 && Math.abs(x) >= 0.5 * 10 ** -places ? "−" : "") + Math.abs(x).toLocaleString("en-US", { minimumFractionDigits: places, maximumFractionDigits: places });
/** a time in the friendliest unit */
export const dur = (s: number) => (s < 5400 ? `${nf(s / 60, 1)} min` : s < 3 * 86400 ? `${nf(s / 3600, 2)} h` : s < 3 * 365.25 * 86400 ? `${nf(s / 86400, 0)} days` : `${nf(s / (365.25 * 86400), 1)} years`);
