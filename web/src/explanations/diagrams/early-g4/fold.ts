// Folding for symmetry (design/pictures-k4.md §7, g4-symmetry): a shape with a dashed fold line. In Learn the half on
// one side flips across the line (a flat squash, not 3D), the result shows (a check when the halves match, the parts
// that stick out in err when they don't), and it unfolds again so it ends still and flat. Counting shows each line
// of symmetry drawn in turn with a running count.
import type { SceneDiagram } from "../scene/schema";
import { frame, path, t, M, L, Z, type Draft, type Pt } from "../geo/kit";

export type Poly = Pt[];

/** the line through the origin at deg degrees (counterclockwise from right, screen y down) */
const dirOf = (deg: number): Pt => [Math.cos((deg * Math.PI) / 180), -Math.sin((deg * Math.PI) / 180)];
export function reflect(p: Pt, deg: number): Pt {
  const [ux, uy] = dirOf(deg), d = p[0] * ux + p[1] * uy;
  return [2 * d * ux - p[0], 2 * d * uy - p[1]];
}
const side = (p: Pt, deg: number) => { const [ux, uy] = dirOf(deg); return ux * p[1] - uy * p[0]; };

/** the part of a polygon on the positive side of the line */
export function halfOf(poly: Poly, deg: number): Poly {
  const out: Pt[] = [];
  poly.forEach((p, i) => {
    const q = poly[(i + 1) % poly.length]!, sp = side(p, deg), sq = side(q, deg);
    if (sp >= 0) out.push(p);
    if ((sp >= 0) !== (sq >= 0)) { const k = sp / (sp - sq); out.push([p[0] + (q[0] - p[0]) * k, p[1] + (q[1] - p[1]) * k]); }
  });
  return out;
}

/** does folding on the line land the shape on itself? (every corner lands on the outline) */
export function isSymmetry(poly: Poly, deg: number): boolean {
  const onOutline = (r: Pt) => poly.some((p, i) => {
    const q = poly[(i + 1) % poly.length]!, d: Pt = [q[0] - p[0], q[1] - p[1]], l2 = d[0] * d[0] + d[1] * d[1];
    const k = Math.max(0, Math.min(1, ((r[0] - p[0]) * d[0] + (r[1] - p[1]) * d[1]) / l2));
    return Math.hypot(p[0] + d[0] * k - r[0], p[1] + d[1] * k - r[1]) < 1.5;
  });
  return poly.every(p => onOutline(reflect(p, deg)));
}

const segs = (poly: Poly) => [M(poly[0]!), ...poly.slice(1).map(L), Z];
const turn = (p: Pt, deg: number): Pt => { const a = (-deg * Math.PI) / 180; return [p[0] * Math.cos(a) - p[1] * Math.sin(a), p[0] * Math.sin(a) + p[1] * Math.cos(a)]; };

export interface FoldSpec {
  poly: Poly;
  /** the dashed line, for "is this a line of symmetry?" */
  line?: number;
  /** every line of symmetry, for counting */
  lines?: number[];
  /** the whole picture turned this many degrees */
  rotate: number;
  beats?: { fold?: number; count?: number };
  alt: string;
}

export function buildFold(s: FoldSpec): SceneDiagram {
  const R = s.rotate, poly = s.poly.map(p => turn(p, R)), b = s.beats, items: Draft[] = [];
  const ext = Math.max(...s.poly.map(p => Math.hypot(...p))) + 12;
  const lineSegs = (deg: number) => { const u = dirOf(deg + R); return [M([-u[0] * ext, -u[1] * ext]), L([u[0] * ext, u[1] * ext])]; };
  items.push(path(segs(poly), "foldshape"));
  if (s.line != null) {
    const deg = s.line + R, ok = isSymmetry(poly, deg);
    if (b?.fold != null) {
      const u = dirOf(deg), screen = (Math.atan2(u[1], u[0]) * 180) / Math.PI;
      items.push(path(segs(halfOf(poly, deg)), "foldhalf p1", { from: b.fold, enter: "fold" as Draft["enter"], vars: { "--r": `${screen.toFixed(1)}deg` } }));
      if (ok) items.push(t(ext * 0.7 * u[0] + 26, ext * 0.7 * u[1] - 20, "✓", "lbl big okmark", { from: b.fold, enter: "pop", delay: 1.6 }));
      else items.push(path(segs(poly.map(p => reflect(p, deg))), "misfit", { from: b.fold, enter: "fade", delay: 1.6 }));
    }
    items.push(path(lineSegs(s.line), "foldline"));
  }
  if (s.lines && b?.count != null) {
    s.lines.forEach((deg, i) => {
      items.push(path(lineSegs(deg), "symline", { from: b.count, enter: "draw", delay: 0.5 * i }));
      items.push(t(ext + 34, -ext + 10, String(i + 1), i === s.lines!.length - 1 ? "lbl big acc" : "lbl big acc", { from: b.count, enter: i === s.lines!.length - 1 ? "pop" : ("flash" as Draft["enter"]), delay: 0.5 * i, ...(i === s.lines!.length - 1 ? {} : { vars: { "--d2": `${(0.5 * i + 0.5).toFixed(2)}s` } }) }));
    });
    if (!s.lines.length) items.push(t(ext + 34, -ext + 10, "0", "lbl big acc", { from: b.count, enter: "pop" }));
  }
  const sc = frame("fold", [...items, { type: "line", x1: -ext, y1: -ext, x2: -ext, y2: -ext, cls: "spacer" } as Draft, { type: "line", x1: ext + 50, y1: ext, x2: ext + 50, y2: ext, cls: "spacer" } as Draft, { type: "circle", cx: 0, cy: 0, r: 0, cls: "spacer" } as Draft], s.alt, 14, {});
  // the half flips about the shape's center, wherever framing moved it
  const o = sc.items.find(i => i.type === "circle" && i.cls === "spacer") as { cx: number; cy: number } | undefined;
  if (o) for (const it of sc.items) if (it.cls?.startsWith("foldhalf")) it.vars = { ...it.vars, "--ox": `${o.cx}px`, "--oy": `${o.cy}px` };
  return sc;
}
