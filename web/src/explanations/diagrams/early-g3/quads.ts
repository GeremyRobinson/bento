// Quadrilaterals (g3-quads): the shape from its own numbers, turned. Practice shows only the shape; Learn traces and
// counts the sides, marks the square corners, ticks equal sides and runs parallel sides out as dashed lines.
import type { SceneDiagram } from "../scene/schema";
import { frame, path, t, M, L, Z, type Draft, type Pt } from "../geo/kit";

export const QUAD_NAMES = ["Square", "Rectangle", "Rhombus", "Parallelogram", "Trapezoid", "Quadrilateral"] as const;
export const TURNS = [0, 20, 45, -30];

/** The four corners, in order around the shape, before turning. */
export function quadCorners(shape: number, w: number, h: number, slant: number, top: number): Pt[] {
  switch (shape) {
    case 0: return [[0, 0], [w, 0], [w, w], [0, w]];
    case 1: return [[0, 0], [w, 0], [w, h], [0, h]];
    case 2: { const hh = Math.sqrt(w * w - slant * slant); return [[slant, 0], [slant + w, 0], [w, hh], [0, hh]]; }
    case 3: return [[slant, 0], [slant + w, 0], [w, h], [0, h]];
    case 4: return [[slant, 0], [slant + top, 0], [w, h], [0, h]];
    default: return [[0, slant], [w, 0], [w - top, h], [top / 3, h - slant / 2]];
  }
}

const sub = (a: Pt, b: Pt): Pt => [a[0] - b[0], a[1] - b[1]];
const len = (v: Pt) => Math.hypot(v[0], v[1]);
const cross = (a: Pt, b: Pt) => a[0] * b[1] - a[1] * b[0];
const dot = (a: Pt, b: Pt) => a[0] * b[0] + a[1] * b[1];

/** What the shape has: right corners (which ones), side lengths, which opposite sides are parallel, and its most special name. */
export function classify(v: Pt[]) {
  const sides = v.map((p, i) => sub(v[(i + 1) % 4]!, p)), lens = sides.map(len);
  const right = v.map((_, i) => Math.abs(dot(sides[i]!, sides[(i + 3) % 4]!)) / (lens[i]! * lens[(i + 3) % 4]!) < 0.02);
  const par = [0, 1].map(i => Math.abs(cross(sides[i]!, sides[i + 2]!)) / (lens[i]! * lens[i + 2]!) < 0.02);
  const allEqual = lens.every(l => Math.abs(l - lens[0]!) < 1);
  const nRight = right.filter(Boolean).length, nPar = par.filter(Boolean).length;
  const name = nRight === 4 && allEqual ? 0 : nRight === 4 ? 1 : allEqual ? 2 : nPar === 2 ? 3 : nPar === 1 ? 4 : 5;
  // convex, with no side too short to see
  const convex = v.every((_, i) => cross(sides[i]!, sides[(i + 1) % 4]!) > 0) || v.every((_, i) => cross(sides[i]!, sides[(i + 1) % 4]!) < 0);
  return { right, nRight, lens, allEqual, par, nPar, name, ok: convex && Math.min(...lens) >= 40 };
}

export function turned(v: Pt[], deg: number): Pt[] {
  const cx = v.reduce((s, p) => s + p[0], 0) / 4, cy = v.reduce((s, p) => s + p[1], 0) / 4, a = (deg * Math.PI) / 180;
  return v.map(([x, y]) => [cx + (x - cx) * Math.cos(a) - (y - cy) * Math.sin(a), cy + (x - cx) * Math.sin(a) + (y - cy) * Math.cos(a)]);
}

export interface QuadSpec {
  corners: Pt[];
  beats?: { sides: number; corners: number; equal: number; parallel: number; name: number };
  name?: string;
  alt: string;
}

export function buildQuad(s: QuadSpec): SceneDiagram {
  const v = s.corners, c = classify(v), b = s.beats, items: Draft[] = [];
  items.push(path([M(v[0]!), ...v.slice(1).map(L), Z], "cell c0"));
  if (b) {
    const cx = v.reduce((q, p) => q + p[0], 0) / 4, cy = v.reduce((q, p) => q + p[1], 0) / 4;
    v.forEach((p, i) => {
      const q = v[(i + 1) % 4]!, m: Pt = [(p[0] + q[0]) / 2, (p[1] + q[1]) / 2], out = sub(m, [cx, cy]), k = 26 / len(out);
      items.push(path([M(p), L(q)], "litedge", { from: b.sides, until: b.sides, enter: "draw", delay: 0.5 * i }));
      items.push(t(m[0] + out[0] * k, m[1] + out[1] * k, String(i + 1), "lbl acc", { from: b.sides, until: b.sides, enter: "pop", delay: 0.5 * i + 0.3 }));
    });
    // a square-corner mark wherever it fits
    v.forEach((p, i) => {
      if (!c.right[i]) return;
      const a = sub(v[(i + 1) % 4]!, p), d = sub(v[(i + 3) % 4]!, p), ka = 16 / len(a), kd = 16 / len(d);
      const p1: Pt = [p[0] + a[0] * ka, p[1] + a[1] * ka], p3: Pt = [p[0] + d[0] * kd, p[1] + d[1] * kd], p2: Pt = [p1[0] + d[0] * kd, p1[1] + d[1] * kd];
      items.push(path([M(p1), L(p2), L(p3)], "ln2", { from: b.corners, enter: "draw", delay: 0.4 * i }));
    });
    // matching ticks on equal sides: one tick for the first length, two for the next
    const groups: number[] = [];
    c.lens.forEach(l => { if (!groups.some(g => Math.abs(g - l) < 1)) groups.push(l); });
    v.forEach((p, i) => {
      const g = groups.findIndex(x => Math.abs(x - c.lens[i]!) < 1), same = c.lens.filter(l => Math.abs(l - c.lens[i]!) < 1).length;
      if (same < 2) return;
      const q = v[(i + 1) % 4]!, dir = sub(q, p), u: Pt = [dir[0] / len(dir), dir[1] / len(dir)], n: Pt = [-u[1], u[0]];
      for (let k = 0; k <= g; k++) {
        const off = (k - g / 2) * 6, m: Pt = [(p[0] + q[0]) / 2 + u[0] * off, (p[1] + q[1]) / 2 + u[1] * off];
        items.push(path([M([m[0] - n[0] * 8, m[1] - n[1] * 8]), L([m[0] + n[0] * 8, m[1] + n[1] * 8])], "ln2", { from: b.equal, enter: "fade", delay: 0.2 * i }));
      }
    });
    // parallel sides run on as dashed lines that never meet
    c.par.forEach((on, i) => {
      if (!on) return;
      for (const j of [i, i + 2]) {
        const p = v[j]!, q = v[(j + 1) % 4]!, dir = sub(q, p), u: Pt = [dir[0] / len(dir), dir[1] / len(dir)];
        items.push(path([M([p[0] - u[0] * 50, p[1] - u[1] * 50]), L([q[0] + u[0] * 50, q[1] + u[1] * 50])], "ln2 dash", { from: b.parallel, until: b.parallel, enter: "draw", delay: 0.3 * i }));
      }
    });
    if (s.name) {
      const bottom = Math.max(...v.map(p => p[1]));
      items.push(t(cx, bottom + 40, s.name, "lbl big acc", { from: b.name, enter: "rise" }));
    }
  }
  return frame("quad", items, s.alt, 24, { w: 320 });
}
