// Place value and rounding (4th grade): a place-value chart of the number's digits above a number line
// from the round number below it to the round number above it. Every digit, tick and label comes from the spec,
// which the lesson computes from its problem.
import type { SceneDiagram } from "../scene/schema";
import { frame, t, type Draft } from "../geo/kit";

/** "47,382": a whole number with thousands commas. */
export const commas = (n: number) => n.toLocaleString("en-US");

/** A place's name over its column, on one or two lines. */
export function placeName(place: number): string[] {
  switch (place) {
    case 1: return ["ones"];
    case 10: return ["tens"];
    case 100: return ["hundreds"];
    case 1000: return ["thousands"];
    case 10000: return ["ten", "thousands"];
    case 100000: return ["hundred", "thousands"];
    default: return [commas(place)];
  }
}

export interface RoundingSpec {
  n: number;
  /** the place to round to: 10, 100, ... 100,000 */
  place: number;
  /** the round numbers on either side and the one n rounds to */
  lo: number;
  hi: number;
  result: number;
  beats: { place: number; line: number; next: number; round: number };
  alt: string;
}

/** column pitch (wide enough for "thousands"), digit box width and height, and the gap where the comma goes */
const CW = 80, BOX = 62, CH = 52, GAP = 14;

export function buildRounding(s: RoundingSpec): SceneDiagram {
  const digits = String(s.n).split(""), L = digits.length;
  const valueOf = (i: number) => 10 ** (L - 1 - i);
  // the thousands sit a little apart from the hundreds, like the comma does
  const base = (i: number) => i * CW + CW / 2 + (L > 3 && valueOf(i) < 1000 ? GAP : 0);
  const chartW = base(L - 1) + CW / 2, W = Math.max(chartW, 380);
  // the chart sits centred over the number line
  const cx = (i: number) => base(i) + (W - chartW) / 2;
  const items: Draft[] = [];

  digits.forEach((_, i) => {
    const x = cx(i) - BOX / 2, v = valueOf(i);
    items.push({ type: "rect", x, y: 0, w: BOX, h: CH, rx: 8, cls: "seg", enter: "pop", delay: i * 0.05 } as Draft);
    if (v === s.place) items.push({ type: "rect", x, y: 0, w: BOX, h: CH, rx: 8, cls: "sq", from: s.beats.place, enter: "pop" } as Draft);
    if (v * 10 === s.place) items.push({ type: "rect", x, y: 0, w: BOX, h: CH, rx: 8, cls: "sq big", from: s.beats.next, enter: "pop" } as Draft);
  });
  digits.forEach((d, i) => {
    const v = valueOf(i), name = placeName(v);
    const head = v === s.place ? "xs lbl" : "xs";
    name.forEach((w, k) => items.push(t(cx(i), -12 - (name.length - 1 - k) * 14, w, head, { enter: "fade", delay: i * 0.05 })));
    items.push(t(cx(i), CH / 2, d, "big", { enter: "rise", delay: i * 0.05 }));
  });

  // the number line under the chart: lo to hi in tenths of the place
  const y = CH + 92, x0 = 24, x1 = W - 24;
  const X = (v: number) => x0 + ((v - s.lo) / (s.hi - s.lo)) * (x1 - x0);
  const at = { from: s.beats.line, enter: "fade" as const };
  items.push({ type: "line", x1: x0 - 14, y1: y, x2: x1 + 14, y2: y, cls: "ax", ...at } as Draft);
  for (let j = 0; j <= 10; j++) {
    const v = s.lo + (j * s.place) / 10, big = j === 0 || j === 10;
    if (j === 5) continue;
    items.push({ type: "line", x1: X(v), y1: y - (big ? 7 : 5), x2: X(v), y2: y + (big ? 7 : 5), cls: "tk", ...at, delay: j * 0.03 } as Draft);
  }
  const mid = s.lo + s.place / 2;
  items.push({ type: "line", x1: X(mid), y1: y - 12, x2: X(mid), y2: y + 12, cls: "ln2", from: s.beats.next, enter: "draw" } as Draft);
  items.push(t(X(mid), y + 26, commas(mid), "xs acc", { from: s.beats.next, enter: "rise" }));
  for (const v of [s.lo, s.hi]) {
    const isResult = v === s.result;
    items.push(t(X(v), y + 26, commas(v), "sm", { ...at, ...(isResult ? { until: s.beats.round - 1 } : {}) }));
    if (isResult) items.push(t(X(v), y + 26, commas(v), "lbl acc", { from: s.beats.round, enter: "pop" }));
  }
  // the number itself, then its trip to the nearer end
  items.push({ type: "line", x1: X(s.n), y1: y, x2: X(s.result), y2: y, cls: "hl", from: s.beats.round, enter: "growx" } as Draft);
  items.push({ type: "circle", cx: X(s.result), cy: y, r: 8, cls: "dota", from: s.beats.round, enter: "pop", delay: 0.4 } as Draft);
  items.push({ type: "circle", cx: X(s.n), cy: y, r: 7, cls: "dotp", from: s.beats.line, enter: "pop", delay: 0.3 } as Draft);
  items.push(t(X(s.n), y - 24, commas(s.n), "lbl", { from: s.beats.line, enter: "rise", delay: 0.4 }));

  return frame("place-value", items, s.alt, 14, { w: W + 28 });
}
