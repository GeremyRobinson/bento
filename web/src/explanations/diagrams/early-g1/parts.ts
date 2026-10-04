// A shape cut into equal parts: a rectangle, a square or a circle, in halves or quarters,
// cut straight down, across, into strips or corner to corner. Parts are numbered, one lights up, then the shaded ones fill.
import type { SceneDiagram } from "../scene/schema";
import { arc, frame, path, t, M, L, Z, type Draft, type Pt, type Seg } from "../geo/kit";

export type ShapeKind = 0 | 1 | 2; // rectangle, square, circle
export const SHAPE_NAMES = ["rectangle", "square", "circle"] as const;

/** cut 0: straight down (halves) or a cross (quarters); cut 1: across (halves) or strips (quarters); cut 2: corner to corner (squares only) */
export function cutsAllowed(shape: ShapeKind): number[] {
  if (shape === 2) return [0];
  if (shape === 1) return [0, 1, 2];
  return [0, 1];
}

/** The cuts that fit a shape for 2, 3 or 4 parts; cut 3 is strips across (4 parts), and 3 parts are strips down (0) or across (1). */
export function cutsFor(shape: ShapeKind, parts: 2 | 3 | 4): number[] {
  if (shape === 2) return [0];
  if (parts === 3) return [0, 1];
  return [...cutsAllowed(shape), ...(parts === 4 ? [3] : [])];
}

/** How many straight cut lines make the parts (a child may count those instead of the parts). */
export function cutLines(parts: 2 | 3 | 4, cut: number, shape: ShapeKind = 0): number {
  if (parts === 2) return 1;
  if (parts === 3) return shape === 2 ? 3 : 2;
  return cut === 1 || cut === 3 ? 3 : 2;
}

export interface Part { segs: Seg[]; c: Pt }

export function partsOf(shape: ShapeKind, parts: 2 | 3 | 4, cut: number): { outline: Seg[]; parts: Part[]; cuts: [Pt, Pt][] } {
  if (shape === 2) {
    const r = 86, C: Pt = [0, 0];
    const wedge = (a0: number, a1: number): Part => {
      const mid = (a0 + a1) / 2, c: Pt = [Math.cos((mid * Math.PI) / 180) * r * 0.5, -Math.sin((mid * Math.PI) / 180) * r * 0.5];
      return { segs: [M(C), ...arc(C, r, a0, a1, true), Z], c };
    };
    const outline = [...arc(C, r, 0, 359.9), Z];
    if (parts === 2) return { outline, parts: [wedge(90, 270), wedge(-90, 90)], cuts: [[[0, -r], [0, r]]] };
    if (parts === 3) {
      const rim = (a: number): Pt => [Math.cos((a * Math.PI) / 180) * r, -Math.sin((a * Math.PI) / 180) * r];
      return { outline, parts: [wedge(90, 210), wedge(210, 330), wedge(330, 450)], cuts: [[C, rim(90)], [C, rim(210)], [C, rim(330)]] };
    }
    return { outline, parts: [wedge(90, 180), wedge(0, 90), wedge(180, 270), wedge(270, 360)], cuts: [[[0, -r], [0, r]], [[-r, 0], [r, 0]]] };
  }
  const w = shape === 1 ? 170 : 240, h = shape === 1 ? 170 : 150;
  const box = (x0: number, y0: number, x1: number, y1: number): Part => ({ segs: [M([x0, y0]), L([x1, y0]), L([x1, y1]), L([x0, y1]), Z], c: [(x0 + x1) / 2, (y0 + y1) / 2] });
  const tri = (a: Pt, b: Pt, c: Pt): Part => ({ segs: [M(a), L(b), L(c), Z], c: [(a[0] + b[0] + c[0]) / 3, (a[1] + b[1] + c[1]) / 3] });
  const outline = [M([0, 0]), L([w, 0]), L([w, h]), L([0, h]), Z];
  const TL: Pt = [0, 0], TR: Pt = [w, 0], BR: Pt = [w, h], BL: Pt = [0, h], O: Pt = [w / 2, h / 2];
  if (parts === 3) {
    if (cut === 0) return { outline, parts: [0, 1, 2].map(i => box((i * w) / 3, 0, ((i + 1) * w) / 3, h)), cuts: [1, 2].map((i): [Pt, Pt] => [[(i * w) / 3, 0], [(i * w) / 3, h]]) };
    return { outline, parts: [0, 1, 2].map(i => box(0, (i * h) / 3, w, ((i + 1) * h) / 3)), cuts: [1, 2].map((i): [Pt, Pt] => [[0, (i * h) / 3], [w, (i * h) / 3]]) };
  }
  if (parts === 2) {
    if (cut === 0) return { outline, parts: [box(0, 0, w / 2, h), box(w / 2, 0, w, h)], cuts: [[[w / 2, 0], [w / 2, h]]] };
    if (cut === 1) return { outline, parts: [box(0, 0, w, h / 2), box(0, h / 2, w, h)], cuts: [[[0, h / 2], [w, h / 2]]] };
    return { outline, parts: [tri(TL, TR, BL), tri(TR, BR, BL)], cuts: [[TR, BL]] };
  }
  if (cut === 0) return { outline, parts: [box(0, 0, w / 2, h / 2), box(w / 2, 0, w, h / 2), box(0, h / 2, w / 2, h), box(w / 2, h / 2, w, h)], cuts: [[[w / 2, 0], [w / 2, h]], [[0, h / 2], [w, h / 2]]] };
  if (cut === 1) return { outline, parts: [0, 1, 2, 3].map(i => box((i * w) / 4, 0, ((i + 1) * w) / 4, h)), cuts: [1, 2, 3].map((i): [Pt, Pt] => [[(i * w) / 4, 0], [(i * w) / 4, h]]) };
  if (cut === 3) return { outline, parts: [0, 1, 2, 3].map(i => box(0, (i * h) / 4, w, ((i + 1) * h) / 4)), cuts: [1, 2, 3].map((i): [Pt, Pt] => [[0, (i * h) / 4], [w, (i * h) / 4]]) };
  return { outline, parts: [tri(TL, TR, O), tri(TR, BR, O), tri(BR, BL, O), tri(BL, TL, O)], cuts: [[TL, BR], [TR, BL]] };
}

export interface PartsSpec {
  shape: ShapeKind;
  parts: 2 | 4;
  cut: number;
  shaded: number;
  /** beats: parts counted, one part named, the shaded parts; leave out for the plain picture (cut and shaded) */
  beats?: { count: number; one: number; shaded: number };
  /** labels under the shape for those beats, from the problem */
  text?: { count: string; one: string; shaded: string };
  alt: string;
}

export function buildParts(s: PartsSpec): SceneDiagram {
  if (!cutsAllowed(s.shape).includes(s.cut)) throw new Error("parts: that cut doesn't fit this shape");
  if (s.shaded < 0 || s.shaded > s.parts) throw new Error("parts: more shaded than there are parts");
  const g = partsOf(s.shape, s.parts, s.cut), b = s.beats;
  const items: Draft[] = [path(g.outline, "fillsoft", { enter: "fade" })];
  g.parts.forEach((p, i) => {
    if (i < s.shaded) items.push(path(p.segs, "shadeA", b ? { from: b.shaded, enter: "fade", delay: 0.2 + 0.25 * i } : { enter: "fade" }));
  });
  if (b) items.push(path(g.parts[0]!.segs, "shadeB", { from: b.one, until: b.one, enter: "fade", delay: 0.2 }));
  g.cuts.forEach(([p, q], i) => items.push(path([M(p), L(q)], "ln2", b ? { from: b.count, enter: "draw", delay: 0.2 + 0.3 * i } : {})));
  items.push(path(g.outline, "ax", { enter: "fade" }));
  if (b) g.parts.forEach((p, i) => items.push(t(p.c[0], p.c[1], String(i + 1), "lbl", { from: b.count, enter: "pop", delay: 0.6 + 0.2 * i })));
  if (b && s.text) {
    const ys = g.parts.flatMap(p => p.segs.flatMap(sg => (sg.c === "Z" ? [] : [sg.p[1]])));
    const y = Math.max(...ys) + 34, x = s.shape === 2 ? 0 : (s.shape === 1 ? 170 : 240) / 2;
    items.push(t(x, y, s.text.count, "lbl", { from: b.count, until: b.count, enter: "rise", delay: 0.3 }));
    items.push(t(x, y, s.text.one, "lbl acc", { from: b.one, until: b.one, enter: "rise", delay: 0.3 }));
    items.push(t(x, y, s.text.shaded, "lbl", { from: b.shaded, enter: "rise", delay: 0.3 }));
  }
  return frame("equal-parts", items, s.alt, 14, { w: 520 });
}
