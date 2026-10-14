// Drawing kit the geometry and data families share: paths as data (so a whole picture can be moved and measured),
// text sizes, arcs in degrees, and a fit step that frames the picture so nothing runs off the canvas.
import type { SceneDiagram, SceneItem } from "../scene/schema";

export type Pt = [number, number];
export type Seg = { c: "M" | "L"; p: Pt } | { c: "A"; r: number; ry?: number; large: 0 | 1; sweep: 0 | 1; p: Pt; samples: Pt[] } | { c: "Q"; q: Pt; p: Pt } | { c: "C"; c1: Pt; c2: Pt; p: Pt } | { c: "Z" };

type PathItem = Extract<SceneItem, { type: "path" }>;
/** A scene item while a family builds it: paths are kept as segments until the picture is framed. */
export type Draft = Exclude<SceneItem, PathItem> | (Omit<PathItem, "d"> & { segs: Seg[] });

export const r1 = (x: number) => Math.round(x * 10) / 10;
export const rad = (deg: number) => (deg * Math.PI) / 180;
/** A point at `deg` degrees (counterclockwise on screen, 0 = pointing right) and distance r from c. */
export const polar = (c: Pt, r: number, deg: number): Pt => [c[0] + r * Math.cos(rad(deg)), c[1] - r * Math.sin(rad(deg))];
export const add = (p: Pt, q: Pt): Pt => [p[0] + q[0], p[1] + q[1]];
export const mid = (p: Pt, q: Pt): Pt => [(p[0] + q[0]) / 2, (p[1] + q[1]) / 2];
export const dist = (p: Pt, q: Pt) => Math.hypot(q[0] - p[0], q[1] - p[1]);

export const M = (p: Pt): Seg => ({ c: "M", p });
export const L = (p: Pt): Seg => ({ c: "L", p });
export const Z: Seg = { c: "Z" };

/** Arc around c from angle a0 to a1 (degrees, counterclockwise when a1 > a0), starting with a move unless `join`. */
export function arc(c: Pt, r: number, a0: number, a1: number, join = false): Seg[] {
  const ccw = a1 >= a0, span = Math.abs(a1 - a0);
  const samples: Pt[] = Array.from({ length: 13 }, (_, i) => polar(c, r, a0 + ((a1 - a0) * i) / 12));
  const start = polar(c, r, a0);
  return [
    ...(join ? [L(start)] : [M(start)]),
    { c: "A", r, large: span > 180 ? 1 : 0, sweep: ccw ? 0 : 1, p: polar(c, r, a1), samples },
  ];
}

/** A full ellipse (for cylinders and cones), as two half arcs. */
export function ellipse(c: Pt, rx: number, ry: number): Seg[] {
  const samples = Array.from({ length: 25 }, (_, i): Pt => [c[0] + rx * Math.cos((i / 24) * 2 * Math.PI), c[1] + ry * Math.sin((i / 24) * 2 * Math.PI)]);
  return [M([c[0] - rx, c[1]]), { c: "A", r: rx, ry, large: 0, sweep: 0, p: [c[0] + rx, c[1]], samples }, { c: "A", r: rx, ry, large: 0, sweep: 0, p: [c[0] - rx, c[1]], samples: [] }, Z];
}

/** Font size each text style draws at (styles/components.css, `.viz-svg text`). */
export function fontSize(cls = ""): number {
  const c = ` ${cls} `;
  if (c.includes(" big ") && c.includes(" lbl ")) return 22;
  if (c.includes(" big ")) return 28;
  if (c.includes(" sm ")) return 15;
  if (c.includes(" xs ")) return 12;
  return 17;
}

/** The box a text item covers, estimated from its length (wide enough for digits and bold letters). */
export function textBox(t: { x: number; y: number; text: string; sup?: string; cls?: string }): { x0: number; y0: number; x1: number; y1: number } {
  const s = fontSize(t.cls);
  const w = [...t.text].length * s * 0.6 + (t.sup ? [...t.sup].length * s * 0.42 : 0);
  const c = ` ${t.cls ?? ""} `;
  const x0 = c.includes(" end ") ? t.x - w : c.includes(" start ") ? t.x : t.x - w / 2;
  return { x0, y0: t.y - s * 0.55 - (t.sup ? s * 0.25 : 0), x1: x0 + w, y1: t.y + s * 0.55 };
}

function pointsOf(it: Draft): Pt[] {
  switch (it.type) {
    case "rect": return [[it.x, it.y], [it.x + it.w, it.y + it.h]];
    case "line": return [[it.x1, it.y1], [it.x2, it.y2]];
    case "circle": return [[it.cx - it.r, it.cy - it.r], [it.cx + it.r, it.cy + it.r]];
    case "polygon": return it.points;
    case "path": return it.segs.flatMap(s => (s.c === "Z" ? [] : s.c === "A" ? [s.p, ...s.samples] : s.c === "Q" ? [s.p, s.q] : s.c === "C" ? [s.p, s.c1, s.c2] : [s.p]));
    case "text": { const b = textBox(it); return [[b.x0, b.y0], [b.x1, b.y1]]; }
  }
}

const ff = (x: number) => String(r1(x));
function writePath(segs: Seg[], dx: number, dy: number): string {
  const P = (p: Pt) => `${ff(p[0] + dx)} ${ff(p[1] + dy)}`;
  return segs.map(s => {
    switch (s.c) {
      case "M": case "L": return `${s.c}${P(s.p)}`;
      case "Q": return `Q${P(s.q)} ${P(s.p)}`;
      case "C": return `C${P(s.c1)} ${P(s.c2)} ${P(s.p)}`;
      case "Z": return "Z";
      case "A": return `A${ff(s.r)} ${ff(s.ry ?? s.r)} 0 ${s.large} ${s.sweep} ${P(s.p)}`;
    }
  }).join(" ");
}

function move(it: Draft, dx: number, dy: number): SceneItem {
  switch (it.type) {
    case "rect": return { ...it, x: r1(it.x + dx), y: r1(it.y + dy), w: r1(it.w), h: r1(it.h) };
    case "line": return { ...it, x1: r1(it.x1 + dx), y1: r1(it.y1 + dy), x2: r1(it.x2 + dx), y2: r1(it.y2 + dy) };
    case "circle": return { ...it, cx: r1(it.cx + dx), cy: r1(it.cy + dy), r: r1(it.r) };
    case "polygon": return { ...it, points: it.points.map(([x, y]): Pt => [r1(x + dx), r1(y + dy)]) };
    case "text": return { ...it, x: r1(it.x + dx), y: r1(it.y + dy) };
    case "path": { const { segs, ...rest } = it; return { ...rest, d: writePath(segs, dx, dy) }; }
  }
}

/** Frames a drafted picture: everything moves so the outermost shape or label sits `pad` from the edge. */
export function frame(family: string, items: Draft[], alt: string, pad = 14, min: { w?: number; h?: number; grow?: number } = {}): SceneDiagram {
  const pts = items.flatMap(pointsOf);
  let x0 = Math.min(...pts.map(p => p[0])), x1 = Math.max(...pts.map(p => p[0]));
  let y0 = Math.min(...pts.map(p => p[1])), y1 = Math.max(...pts.map(p => p[1]));
  // a narrow picture is centred in its minimum width rather than stretched
  if (min.w && x1 - x0 + 2 * pad < min.w) { const extra = (min.w - (x1 - x0 + 2 * pad)) / 2; x0 -= extra; x1 += extra; }
  if (min.h && y1 - y0 + 2 * pad < min.h) { const extra = (min.h - (y1 - y0 + 2 * pad)) / 2; y0 -= extra; y1 += extra; }
  const dx = pad - x0, dy = pad - y0;
  return { kind: "scene", family, width: Math.ceil(x1 - x0 + 2 * pad), height: Math.ceil(y1 - y0 + 2 * pad), items: items.map(it => move(it, dx, dy)), alt, ...(min.grow ? { grow: min.grow } : {}) };
}

/** Text helper: `t(x, y, "70°", "lbl acc", { from: 2, enter: "rise" })`. */
export const t = (x: number, y: number, text: string, cls = "", extra: Partial<Draft> = {}): Draft => ({ type: "text", x, y, text, cls, ...extra }) as Draft;
export const path = (segs: Seg[], cls: string, extra: Partial<Draft> = {}): Draft => ({ type: "path", segs, cls, ...extra }) as Draft;
export const seg = (p: Pt, q: Pt, cls: string, extra: Partial<Draft> = {}): Draft => path([M(p), L(q)], cls, extra);
export const poly = (pts: Pt[], cls: string, extra: Partial<Draft> = {}): Draft => path([M(pts[0]!), ...pts.slice(1).map(L), Z], cls, extra);

/**
 * Where to put an angle's label: along the bisector of the angle at vertex v between directions d0 and d1 (degrees),
 * far enough out that a label `w` wide clears both arms.
 */
export function angleLabelAt(v: Pt, d0: number, d1: number, w: number, minR = 40, maxR = 400): Pt {
  const span = Math.abs(d1 - d0), bis = (d0 + d1) / 2;
  const half = Math.max(rad(span / 2), 0.05);
  // the label's half-diagonal plus a margin, over the sine of half the angle
  const need = (Math.hypot(w / 2, 10) + 5) / Math.sin(Math.min(half, Math.PI / 2));
  return polar(v, Math.min(maxR, Math.max(minR, need)), bis);
}
