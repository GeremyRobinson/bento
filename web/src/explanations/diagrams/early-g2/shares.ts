// Equal shares for 2nd grade (g2-shares): a shape cut into halves, thirds or fourths. In Learn the cut parts lift out
// and land on one spot beside the shape, one on top of the next, so "equal" is something you see. A second copy cut
// another way can sit beside the first ("Same size?").
import type { SceneDiagram } from "../scene/schema";
import { frame, path, t, M, L, type Draft, type Pt, type Seg } from "../geo/kit";
import { cutsFor, partsOf, type ShapeKind } from "../early-g1/parts";

const shift = (segs: Seg[], dx: number, dy = 0): Seg[] => segs.map(s => {
  const m = (p: Pt): Pt => [p[0] + dx, p[1] + dy];
  switch (s.c) {
    case "Z": return s;
    case "A": return { ...s, p: m(s.p), samples: s.samples.map(m) };
    case "Q": return { ...s, q: m(s.q), p: m(s.p) };
    case "C": return { ...s, c1: m(s.c1), c2: m(s.c2), p: m(s.p) };
    default: return { ...s, p: m(s.p) };
  }
});
const xsOf = (segs: Seg[]) => segs.flatMap(s => (s.c === "Z" ? [] : s.c === "A" ? [s.p[0], ...s.samples.map(q => q[0])] : [s.p[0]]));
const ysOf = (segs: Seg[]) => segs.flatMap(s => (s.c === "Z" ? [] : s.c === "A" ? [s.p[1], ...s.samples.map(q => q[1])] : [s.p[1]]));

export interface SharesSpec {
  shape: ShapeKind;
  parts: 2 | 3 | 4;
  cut: number;
  shaded: number;
  /** a second copy of the shape, cut this other way into the same number of parts */
  other?: number;
  /** beats: cuts drawn and parts numbered; the parts stack to show they match; one part named; the shaded parts fill */
  beats?: { count: number; match: number; one: number; shaded: number };
  text?: { count: string; match: string; one: string; shaded: string };
  alt: string;
}

/** one cut shape at x offset dx; returns its items and right edge */
function cutShape(s: { shape: ShapeKind; parts: 2 | 3 | 4; cut: number; shaded: number }, dx: number, b?: SharesSpec["beats"]) {
  const g = partsOf(s.shape, s.parts, s.cut), items: Draft[] = [];
  const outline = shift(g.outline, dx);
  items.push(path(outline, "fillsoft", { enter: "fade" }));
  g.parts.forEach((p, i) => {
    if (i < s.shaded) items.push(path(shift(p.segs, dx), "shadeA", b ? { from: b.shaded, enter: "fade", delay: 0.2 + 0.25 * i } : { enter: "fade" }));
  });
  if (b) items.push(path(shift(g.parts[0]!.segs, dx), "shadeB", { from: b.one, until: b.one, enter: "fade", delay: 0.2 }));
  g.cuts.forEach(([p, q], i) => items.push(path([M([p[0] + dx, p[1]]), L([q[0] + dx, q[1]])], "ln2", b ? { from: b.count, enter: "draw", delay: 0.2 + 0.3 * i } : {})));
  items.push(path(outline, "ax", { enter: "fade" }));
  if (b) g.parts.forEach((p, i) => items.push(t(p.c[0] + dx, p.c[1], String(i + 1), "lbl", { from: b.count, until: b.match, enter: "pop", delay: 0.6 + 0.2 * i })));
  return { items, g, right: Math.max(...xsOf(outline)), left: Math.min(...xsOf(outline)) };
}

export function buildShares(s: SharesSpec): SceneDiagram {
  if (!cutsFor(s.shape, s.parts).includes(s.cut)) throw new Error("shares: that cut doesn't fit this shape");
  if (s.other != null && (s.other === s.cut || !cutsFor(s.shape, s.parts).includes(s.other))) throw new Error("shares: the second copy is cut another way");
  if (!Number.isInteger(s.shaded) || s.shaded < 0 || s.shaded > s.parts) throw new Error("shares: more shaded than there are parts");
  const b = s.beats, main = cutShape(s, 0, b), items = [...main.items];
  let right = main.right;
  const ys = main.g.parts.flatMap(p => ysOf(p.segs)), bottom = Math.max(...ys), top = Math.min(...ys);
  if (s.other != null) {
    const second = cutShape({ shape: s.shape, parts: s.parts, cut: s.other, shaded: 0 }, right + 56 - Math.min(...xsOf(partsOf(s.shape, s.parts, s.other).outline)));
    items.push(...second.items);
    right = second.right;
  }
  if (b) {
    // every part lifts out and lands on the same spot to the right: each one covers the last exactly
    const p0 = main.g.parts[0]!, x0 = Math.min(...xsOf(p0.segs)), spot = right + 64 - x0;
    // each part starts from its own place in the shape (across and up or down, so stacked strips move too)
    main.g.parts.forEach((p, i) => {
      const vars = { "--dx": `${Math.round(p.c[0] - (p0.c[0] + spot))}px`, "--dy": `${Math.round(p.c[1] - p0.c[1])}px` };
      items.push(path(shift(p0.segs, spot), i === main.g.parts.length - 1 ? "shadeB" : "fillsoft", { from: b.match, until: b.match, enter: "slide", delay: 0.5 * i, vars }));
      items.push(path(shift(p0.segs, spot), "ln2", { from: b.match, until: b.match, enter: "slide", delay: 0.5 * i, vars }));
    });
    const sx = (Math.min(...xsOf(p0.segs)) + Math.max(...xsOf(p0.segs))) / 2 + spot;
    items.push(t(sx, Math.min(...ysOf(p0.segs)) - 22, "same size", "lbl acc", { from: b.match, until: b.match, enter: "rise", delay: 0.5 * main.g.parts.length }));
    if (s.text) {
      const y = bottom + 34, x = (main.left + main.right) / 2;
      items.push(t(x, y, s.text.count, "lbl", { from: b.count, until: b.count, enter: "rise", delay: 0.3 }));
      items.push(t(x, y, s.text.match, "lbl", { from: b.match, until: b.match, enter: "rise", delay: 0.3 }));
      items.push(t(x, y, s.text.one, "lbl acc", { from: b.one, until: b.one, enter: "rise", delay: 0.3 }));
      items.push(t(x, y, s.text.shaded, "lbl", { from: b.shaded, enter: "rise", delay: 0.3 }));
    }
    // keep room for the stack even when it's gone, so the picture never jumps
    const far = spot + Math.max(...xsOf(p0.segs));
    items.push({ type: "line", x1: far, y1: top, x2: far, y2: top, cls: "spacer" } as Draft);
  }
  return frame("equal-shares", items, s.alt, 14, { w: 520 });
}
