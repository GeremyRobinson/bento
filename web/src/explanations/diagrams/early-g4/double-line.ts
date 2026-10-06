// Converting measurements (4th grade): a double number line, big units on top and small units below,
// tick for tick. One big unit is matched first, then every tick is counted up; extra small units hop on at the end.
import type { SceneDiagram } from "../scene/schema";
import { frame, path, seg, t, M, type Draft } from "../geo/kit";

export interface DoubleLineSpec {
  /** big units counted (0 to n), small units in one big unit, and extra small units after n */
  n: number;
  per: number;
  extra: number;
  /** unit names for the two lines, e.g. "feet" and "inches" */
  top: string;
  bottom: string;
  beats: { one: number; all: number; extra: number | null; total: number };
  /** the finished sentence under the lines, e.g. "3 feet = 36 inches" */
  total: string;
  /** what the ticks read; by default the top counts 0, 1, 2 … and the bottom j × per */
  topText?: (j: number) => string;
  bottomText?: (j: number) => string;
  /** a note between the two lines' names, e.g. "× 10" */
  between?: string;
  /** hops tick to tick along both lines from this beat, counted 1 to n, the count landing in the accent */
  hops?: { from: number };
  /** lines under the picture before the total (each in the total's row while it shows) */
  lines?: { text: string; from: number; until?: number }[];
  alt: string;
}

const GAP = 78;

export function buildDoubleLine(s: DoubleLineSpec): SceneDiagram {
  const units = s.extra ? s.n + 1 : s.n;
  const step = Math.min(64, 440 / Math.max(units, 1));
  const X = (u: number) => u * step, y0 = 0, y1 = GAP;
  const items: Draft[] = [];
  const end = X(units) + 18;

  items.push(seg([-8, y0], [end, y0], "ax"), seg([-8, y1], [end, y1], "ax"));
  items.push(t(-20, y0, s.top, "sm end"), t(-20, y1, s.bottom, "sm end"));
  if (s.between) items.push(t(-20, (y0 + y1) / 2, s.between, "sm acc end"));
  const topText = s.topText ?? String, bottomText = s.bottomText ?? ((j: number) => String(j * s.per));
  // long top labels (10.8) take the smaller size when the ticks are close
  const topCls = Math.max(...Array.from({ length: units + 1 }, (_, j) => topText(j).length)) * 15 * 0.6 > step - 6 ? "xs" : "sm";
  for (let j = 0; j <= units; j++) {
    const x = X(j), at = j === 0 ? 0 : j === 1 ? s.beats.one : s.beats.all, k = Math.max(0, j - 2);
    items.push(seg([x, y0 - 7], [x, y0 + 7], "tk"), seg([x, y1 - 7], [x, y1 + 7], "tk"));
    items.push(t(x, y0 - 20, topText(j), topCls));
    // the matching small-unit count appears as the ticks are counted up
    const isTotal = !s.extra && j === s.n;
    items.push(t(x, y1 + 22, bottomText(j), "sm", { from: at, enter: "rise", delay: Math.round(k * 0.12 * 100) / 100, ...(isTotal ? { until: s.beats.total - 1 } : {}) }));
    if (isTotal) items.push(t(x, y1 + 22, bottomText(j), "lbl acc", { from: s.beats.total, enter: "pop" }));
    if (j > 0 && j <= s.n) items.push(seg([x, y0 + 10], [x, y1 - 10], "wire", { from: at, enter: "draw", delay: Math.round(k * 0.12 * 100) / 100 }));
  }
  // one big unit, matched
  items.push(seg([X(0), y0], [X(1), y0], "hl", { from: s.beats.one, until: s.beats.one, enter: "growx" }));
  items.push(seg([X(0), y1], [X(1), y1], "hl", { from: s.beats.one, until: s.beats.one, enter: "growx", delay: 0.3 }));
  // n big units, matched
  items.push(seg([X(0), y0], [X(s.n), y0], "hl", { from: s.beats.all, enter: "growx" }));
  items.push(seg([X(0), y1], [X(s.n), y1], "hl", { from: s.beats.all, enter: "growx", delay: 0.4 }));
  items.push({ type: "circle", cx: X(s.n), cy: y0, r: 7, cls: "dotp", from: s.beats.all, enter: "pop", delay: 0.6 } as Draft);
  items.push({ type: "circle", cx: X(s.n), cy: y1, r: 7, cls: "dotp", from: s.beats.all, enter: "pop", delay: 0.8 } as Draft);

  if (s.extra && s.beats.extra != null) {
    const xe = X(s.n + s.extra / s.per), xn = X(s.n), b = s.beats.extra;
    items.push(path([M([xn, y1]), { c: "Q", q: [(xn + xe) / 2, y1 - 44], p: [xe, y1] }], "ln2", { from: b, enter: "draw" }));
    // the label sits just past the hop, where no tick line runs between the two lines
    items.push(t(xe + 6, y1 - 26, `+${s.extra}`, "sm acc start", { from: b, enter: "rise", delay: 0.4 }));
    items.push({ type: "circle", cx: xe, cy: y1, r: 7, cls: "dota", from: b, enter: "pop", delay: 0.6 } as Draft);
    items.push({ type: "circle", cx: xe, cy: y0, r: 7, cls: "dota", from: b, enter: "pop", delay: 0.6 } as Draft);
  }
  // hops tick to tick, above the top line's labels and below the bottom line's, counted as they land
  let yText = y1 + 62;
  if (s.hops) {
    const hh = Math.min(22, step * 0.45), b = s.hops.from, yt = y0 - 34, yb = y1 + 36;
    for (let j = 1; j <= s.n; j++) {
      const xa = X(j - 1), xb = X(j), delay = Math.round((0.2 + 0.25 * (j - 1)) * 100) / 100;
      items.push(path([M([xa + 2, yt]), { c: "Q", q: [(xa + xb) / 2, yt - 2 * hh], p: [xb - 2, yt] }], "ln thin pq", { from: b, enter: "draw", delay }));
      items.push(path([M([xa + 2, yb]), { c: "Q", q: [(xa + xb) / 2, yb + 2 * hh], p: [xb - 2, yb] }], "ln thin pq", { from: b, enter: "draw", delay }));
      items.push(t((xa + xb) / 2, yt - hh - 12, String(j), j === s.n ? "sm acc" : "xs", { from: b, enter: "rise", delay: Math.round((delay + 0.2) * 100) / 100 }));
    }
    yText = yb + hh + 30;
  }
  for (const l of s.lines ?? []) items.push(t(X(units) / 2, yText, l.text, "lbl acc", { from: l.from, ...(l.until != null ? { until: l.until } : {}), enter: "rise" }));
  if (s.total) items.push(t(X(units) / 2, yText, s.total, "lbl acc", { from: s.beats.total, enter: "rise" }));
  return frame("double-line", items, s.alt, 14, { w: 320 });
}
