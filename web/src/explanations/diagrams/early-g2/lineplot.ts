// Line plots for 2nd to 4th grade (g2-lineplot, g3-lineplot, g4-lineplot): a number line marked in wholes, halves,
// fourths or eighths of an inch, with an X stacked above the mark for each thing measured. Values are whole counts of
// d-ths, so fractions stay exact. Practice shows the plot only; Learn drops the X's in one at a time, then lights the
// stacks the question is about.
import type { SceneDiagram } from "../scene/schema";
import { frame, path, t, M, L, type Draft } from "../geo/kit";

const VULGAR: Record<string, string> = { "1/2": "½", "1/4": "¼", "3/4": "¾", "1/8": "⅛", "3/8": "⅜", "5/8": "⅝", "7/8": "⅞" };
const gcd = (a: number, b: number): number => (b ? gcd(b, a % b) : a);

/** v d-ths as a short label: 2, ½, 1¾, 2⅜ */
export function plotLabel(v: number, d: number): string {
  const whole = Math.floor(v / d), rest = v % d;
  if (!rest) return String(whole);
  const g = gcd(rest, d), frac = VULGAR[`${rest / g}/${d / g}`] ?? `${rest / g}/${d / g}`;
  return whole ? `${whole}${frac}` : frac;
}

export interface LinePlotSpec {
  /** marks per inch: 1, 2, 4 or 8 */
  d: number;
  /** the first and last marks, in d-ths */
  lo: number;
  hi: number;
  /** every measurement, in d-ths, in the order they were measured */
  data: number[];
  title: string;
  /** beats: the X's drop in one at a time; the stacks in `light` light up */
  beats?: { drop: number; light?: number };
  light?: number[];
  alt: string;
}

const XS = 18, XP = 22;

export function buildLinePlot(s: LinePlotSpec): SceneDiagram {
  if (![1, 2, 4, 8].includes(s.d) || !(s.lo < s.hi) || s.data.some(v => !Number.isInteger(v) || v < s.lo || v > s.hi)) throw new Error("line plot: every value on the line");
  const pitch = s.d === 1 ? 52 : s.d === 8 ? 38 : 46, x = (v: number) => (v - s.lo) * pitch, b = s.beats, items: Draft[] = [];
  const W = x(s.hi);
  items.push(path([M([-16, 0]), L([W + 16, 0])], "ax"));
  for (let v = s.lo; v <= s.hi; v++) {
    const whole = v % s.d === 0;
    items.push(path([M([x(v), -7]), L([x(v), 7])], whole ? "ax" : "ax thin"));
    items.push(t(x(v), 28, plotLabel(v, s.d), whole ? "sm" : "xs"));
  }
  const height = new Map<number, number>(), top = Math.max(1, ...[...new Set(s.data)].map(v => s.data.filter(u => u === v).length));
  if (b?.light != null && s.light) for (const v of s.light) {
    const n = s.data.filter(u => u === v).length;
    items.push({ type: "rect", x: x(v) - 17, y: -14 - Math.max(n, 1) * XP, w: 34, h: Math.max(n, 1) * XP + 6, rx: 17, cls: "hlrow", from: b.light, enter: "fade" } as Draft);
  }
  s.data.forEach((v, i) => {
    const k = height.get(v) ?? 0;
    height.set(v, k + 1);
    const cx = x(v), cy = -18 - k * XP, h = XS / 2 - 2;
    const x2 = [M([cx - h, cy - h]), L([cx + h, cy + h]), M([cx + h, cy - h]), L([cx - h, cy + h])];
    items.push(path(x2, "xmark", b ? { from: b.drop, enter: "drop", delay: 0.22 * i } : {}));
    // every X is the same kind of thing (blue); the stacks the question asks about turn amber when they light up
    if (b?.light != null && s.light?.includes(v)) items.push(path(x2, "xmark pq", { from: b.light, enter: "fade" }));
  });
  items.push(t(W / 2, -24 - top * XP - 18, s.title, "sm"));
  items.push(t(W / 2, 54, "inches", "xs"));
  return frame("line-plot", items, s.alt, 14, { w: 360 });
}

export interface FracRulerSpec {
  /** length in fourths of an inch */
  len: number;
  /** the ruler's last whole inch */
  max: number;
  /** marks the reader counts in: 2 halves or 4 fourths */
  to: number;
  beats?: { whole: number; extra: number };
  text?: string;
  alt: string;
}

/** An inch ruler with half and quarter marks, a thing lying on it from 0. Learn hops whole inches, then the extra part. */
export function buildFracRuler(s: FracRulerSpec): SceneDiagram {
  const U = 96, q = U / 4, x = (fourths: number) => fourths * q, b = s.beats, items: Draft[] = [];
  if (!(Number.isInteger(s.len) && s.len > 0 && s.len <= 4 * s.max)) throw new Error("ruler: the thing fits");
  items.push({ type: "rect", x: -14, y: 0, w: x(4 * s.max) + 28, h: 52, rx: 6, cls: "fillsoft" } as Draft, { type: "rect", x: -14, y: 0, w: x(4 * s.max) + 28, h: 52, rx: 6, cls: "ax thin" } as Draft);
  for (let k = 0; k <= 4 * s.max; k++) {
    const h = k % 4 === 0 ? 20 : k % 2 === 0 ? 14 : 9;
    items.push(path([M([x(k), 0]), L([x(k), h])], k % 4 === 0 ? "ax thin" : "tk"));
    if (k % 4 === 0) items.push(t(x(k), 34, String(k / 4), "sm"));
  }
  items.push(t(x(4 * s.max) + 22, 28, "in", "sm start"));
  const top = -40, tip = Math.min(22, x(s.len) / 4);
  items.push({ type: "rect", x: 0, y: top, w: x(s.len) - tip, h: 24, rx: 3, cls: "cell c0" } as Draft);
  items.push({ type: "polygon", points: [[x(s.len) - tip, top], [x(s.len), top + 12], [x(s.len) - tip, top + 24]], cls: "cell c0" } as Draft);
  if (b) {
    const whole = Math.floor(s.len / 4), per = 4 / s.to;
    for (let k = 0; k < whole; k++) {
      items.push(path([{ c: "M", p: [x(4 * k), 60] }, { c: "Q", q: [x(4 * k + 2), 92], p: [x(4 * k + 4), 60] }], "ln", { from: b.whole, enter: "draw", delay: 0.3 * k }));
      items.push(t(x(4 * k + 2), 98, String(k + 1), "sm", { from: b.whole, enter: "rise", delay: 0.3 * k + 0.2 }));
    }
    for (let k = 0; k * per < s.len - 4 * whole; k++) {
      const a = 4 * whole + k * per;
      items.push(path([{ c: "M", p: [x(a), 60] }, { c: "Q", q: [x(a + per / 2), 80], p: [x(a + per), 60] }], "ln2", { from: b.extra, enter: "draw", delay: 0.3 * k }));
    }
    items.push(path([M([x(s.len), top - 10]), L([x(s.len), 0])], "ln2 dash", { from: b.extra, enter: "draw" }));
    if (s.text) items.push(t(x(s.len) / 2, top - 30, s.text, "lbl big acc", { from: b.extra, enter: "rise", delay: 0.8 }));
  }
  return frame("frac-ruler", items, s.alt, 14, { w: 360 });
}
