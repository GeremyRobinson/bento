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
    items.push(path([M([cx - h, cy - h]), L([cx + h, cy + h]), M([cx + h, cy - h]), L([cx - h, cy + h])], "xmark", b ? { from: b.drop, enter: "drop", delay: 0.22 * i } : {}));
  });
  items.push(t(W / 2, -24 - top * XP - 18, s.title, "sm"));
  items.push(t(W / 2, 54, "inches", "xs"));
  return frame("line-plot", items, s.alt, 14, { w: 360 });
}
