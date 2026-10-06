// Bars for a list of numbers, heights true to the values: they level out to the mean,
// or slide into order so the middle one is the median.
import type { SceneDiagram } from "../scene/schema";
import { frame, seg, t, type Draft } from "../geo/kit";

const BW = 46, GAP = 16, H = 170;
const x = (i: number) => i * (BW + GAP);

export interface MeanBarsSpec {
  values: number[];
  mean: number;
  /** the note above the bars at each beat, e.g. "4 + 6 + 8 = 18", "18 in all, 3 numbers", "18 ÷ 3 = 6 each" */
  sumNote: string; countNote: string; shareNote: string;
  sumBeat: number; countBeat: number; shareBeat: number;
  alt: string;
}

export function buildMeanBars(s: MeanBarsSpec): SceneDiagram {
  const max = Math.max(...s.values), sc = H / max, n = s.values.length, W = x(n) - GAP;
  const items: Draft[] = [seg([-10, 0], [W + 10, 0], "ax")];
  s.values.forEach((v, i) => {
    items.push({ type: "rect", x: x(i), y: -v * sc, w: BW, h: v * sc, rx: 8, cls: "bar", until: s.shareBeat - 1, enter: "growy", delay: i * 0.08 } as Draft);
    items.push(t(x(i) + BW / 2, -v * sc - 14, String(v), "lbl", { until: s.shareBeat - 1, enter: "rise", delay: 0.3 + i * 0.08 }));
    // each bar shares out to the mean height
    items.push({ type: "rect", x: x(i), y: -s.mean * sc, w: BW, h: s.mean * sc, rx: 8, cls: "bar", from: s.shareBeat, enter: "level", vars: { "--from": Math.round((v / s.mean) * 1000) / 1000 } } as Draft);
    items.push(t(x(i) + BW / 2, 16, String(i + 1), "xs", { from: s.countBeat, enter: "fade", delay: i * 0.12 }));
  });
  items.push(seg([-10, -s.mean * sc], [W + 10, -s.mean * sc], "ln2 dash", { from: s.shareBeat, enter: "draw", delay: 1 }));
  // the level line says what level it is
  items.push(t(W + 18, -s.mean * sc, String(s.mean), "lbl acc start", { from: s.shareBeat, enter: "rise", delay: 1.2 }));
  const top = -H - 40;
  items.push(t(W / 2, top, s.sumNote, "lbl", { from: s.sumBeat, until: s.countBeat - 1, enter: "rise" }));
  items.push(t(W / 2, top, s.countNote, "lbl", { from: s.countBeat, until: s.shareBeat - 1, enter: "rise" }));
  items.push(t(W / 2, top, s.shareNote, "lbl acc", { from: s.shareBeat, enter: "rise", delay: 1.2 }));
  return frame("bars", items, s.alt, 14, { w: 320 });
}

export interface MedianBarsSpec {
  values: number[];
  /** beats: counted, sorted with the middle spot marked, the median named */
  countBeat: number; sortBeat: number; medianBeat: number;
  countNote: string; spotNote: string; medianNote: string;
  alt: string;
}

export function buildMedianBars(s: MedianBarsSpec): SceneDiagram {
  const n = s.values.length, max = Math.max(...s.values), sc = H / max, W = x(n) - GAP;
  const order = s.values.map((v, i) => [v, i] as const).sort((p, q) => p[0] - q[0] || p[1] - q[1]);
  const middle = (n - 1) / 2;
  const items: Draft[] = [seg([-10, 0], [W + 10, 0], "ax")];
  s.values.forEach((v, i) => {
    items.push({ type: "rect", x: x(i), y: -v * sc, w: BW, h: v * sc, rx: 8, cls: "bar", until: s.sortBeat - 1, enter: "growy", delay: i * 0.08 } as Draft);
    items.push(t(x(i) + BW / 2, -v * sc - 14, String(v), "lbl", { until: s.sortBeat - 1, enter: "rise", delay: 0.3 + i * 0.08 }));
  });
  order.forEach(([v, from], to) => {
    const slide = { enter: "slide" as const, vars: { "--dx": `${x(from) - x(to)}px` } };
    const mid = to === middle;
    items.push({ type: "rect", x: x(to), y: -v * sc, w: BW, h: v * sc, rx: 8, cls: "bar", from: s.sortBeat, ...(mid ? { until: s.medianBeat - 1 } : {}), ...slide } as Draft);
    if (mid) items.push({ type: "rect", x: x(to), y: -v * sc, w: BW, h: v * sc, rx: 8, cls: "bar mid", from: s.medianBeat } as Draft);
    items.push(t(x(to) + BW / 2, -v * sc - 14, String(v), mid ? "lbl acc" : "lbl", { from: s.sortBeat, ...slide }));
  });
  // spot numbers under the bars, the middle one marked once the list is sorted
  for (let i = 0; i < n; i++) {
    items.push(t(x(i) + BW / 2, 16, String(i + 1), "xs", { from: s.countBeat, ...(i === middle ? { until: s.sortBeat - 1 } : {}), enter: "fade", delay: i * 0.1 }));
    if (i === middle) items.push(t(x(i) + BW / 2, 18, String(i + 1), "lbl acc", { from: s.sortBeat, enter: "pop", delay: 1 }));
  }
  const top = -H - 40;
  items.push(t(W / 2, top, s.countNote, "lbl", { from: s.countBeat, until: s.sortBeat - 1, enter: "rise" }));
  items.push(t(W / 2, top, s.spotNote, "lbl", { from: s.sortBeat, until: s.medianBeat - 1, enter: "rise", delay: 1 }));
  items.push(t(W / 2, top, s.medianNote, "lbl acc", { from: s.medianBeat, enter: "rise" }));
  return frame("bars", items, s.alt, 14, { w: 320 });
}
