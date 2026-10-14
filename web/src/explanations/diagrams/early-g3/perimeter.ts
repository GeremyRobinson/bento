// A shape with its side lengths, traced around side by side for perimeter. The lesson gives the corners
// (in problem units) and the label of each side; the builder scales the shape, puts each label outside its side,
// and draws the trace of each side at the beat it is added.
import type { SceneDiagram } from "../scene/schema";
import { frame, M, L as Lto, path, t, type Draft, type Pt } from "../geo/kit";
import { growDown } from "../scene/picture-system";

export interface PerimeterSide {
  /** label beside the side, e.g. "7 cm" (empty: no label) */
  text: string;
  /** beat the label shows from (default 0) */
  from?: number;
  /** accent colour, for lengths the learner works out */
  acc?: boolean;
  /** beat this side is traced */
  trace?: number;
}

export interface PerimeterSpec {
  /** corners in order; side i runs from corner i to corner i + 1 (y grows downward) */
  corners: Pt[];
  sides: PerimeterSide[];
  /** a line under the shape, e.g. "7 + 4 + 7 + 4 = 22 cm" */
  lines?: { text: string; from: number; until?: number }[];
  alt: string;
}

export function buildPerimeter(s: PerimeterSpec): SceneDiagram {
  if (s.corners.length !== s.sides.length) throw new Error("one label per side");
  const xs = s.corners.map(p => p[0]), ys = s.corners.map(p => p[1]);
  const w = Math.max(...xs) - Math.min(...xs), h = Math.max(...ys) - Math.min(...ys);
  // drawn at about a phone strip's size, so its labels, laid out at their phone size, land where they are drawn
  const k = Math.min(210 / w, 110 / h);
  const P = s.corners.map(([x, y]): Pt => [(x - Math.min(...xs)) * k, (y - Math.min(...ys)) * k]);
  const cx = P.reduce((a, p) => a + p[0], 0) / P.length, cy = P.reduce((a, p) => a + p[1], 0) / P.length;
  const items: Draft[] = [];
  items.push(path([M(P[0]!), ...P.slice(1).map(Lto), { c: "Z" }], "fillsoft", { enter: "fade" }));
  items.push(path([M(P[0]!), ...P.slice(1).map(Lto), { c: "Z" }], "ax", { enter: "fade" }));
  s.sides.forEach((side, i) => {
    const a = P[i]!, b = P[(i + 1) % P.length]!;
    const mx = (a[0] + b[0]) / 2, my = (a[1] + b[1]) / 2;
    const len = Math.hypot(b[0] - a[0], b[1] - a[1]);
    let nx = -(b[1] - a[1]) / len, ny = (b[0] - a[0]) / len;
    if (nx * (mx - cx) + ny * (my - cy) < 0) { nx = -nx; ny = -ny; }
    // a side's label is held by its edge nearest the side (start / end / up / down), so the phone's floor grows it
    // away from the shape and the lines under it, and on a tablet it still sits right beside its side
    const hold = Math.abs(nx) > 0.7 ? (nx > 0 ? " start" : " end") : Math.abs(ny) > 0.7 ? (ny > 0 ? " down" : " up") : "";
    const off = hold ? 9 : 14 + Math.abs(nx) * side.text.length * 4.6;
    if (side.text) items.push(t(mx + nx * off, my + ny * (off + (hold ? 0 : 2)), side.text, `${side.acc ? "lbl acc" : "lbl"}${hold}`, { from: side.from ?? 0, enter: "rise", delay: 0.2 }));
    if (side.trace != null) items.push(path([M(a), Lto(b)], "ln2", { from: side.trace, enter: "draw", delay: Math.round(s.sides.slice(0, i).filter(o => o.trace === side.trace).length * 0.45 * 100) / 100 }));
  });
  // the working hangs under the bottom side's label and moves down by what that label (and the rows above) grew on a
  // phone; it is a caption (.cap): practice leaves it out, since the work list already shows each worked line
  const bottom = Math.max(...P.map(p => p[1])) + 38;
  const rows: { from: number; until: number }[][] = [];
  for (const l of s.lines ?? []) {
    const span = { from: l.from, until: l.until ?? Infinity };
    let r = rows.findIndex(rw => rw.every(o => span.until < o.from || o.until < span.from));
    if (r < 0) { r = rows.length; rows.push([]); }
    rows[r]!.push(span);
    items.push(t(cx, bottom + r * 26, l.text, "lbl acc down cap", { from: l.from, ...(l.until != null ? { until: l.until } : {}), enter: "rise", delay: 0.6, vars: growDown(1 + r) }));
  }
  return frame("perimeter", items, s.alt, 14, { w: 240 });
}
