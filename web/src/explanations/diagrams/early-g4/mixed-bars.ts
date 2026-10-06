// Adding mixed numbers (4th grade): each number as whole bars and one bar cut into d pieces.
// Below, the wholes come together, then the pieces; a bar the pieces fill up is traded for one more whole.
import type { SceneDiagram } from "../scene/schema";
import { frame, t, type Draft } from "../geo/kit";

export interface MixedBarsSpec {
  d: number;
  /** the two mixed numbers: wholes and pieces */
  first: { w: number; n: number; label: string };
  second: { w: number; n: number; label: string };
  beats: { wholes: number; pieces: number; regroup: number | null; total: number };
  /** the answer, written under the bottom row */
  total: string;
  alt: string;
}

const U = 66, H = 32, GAP = 8, ROW = 54;
// the second mixed number is part orange (it was the accent colour, which now means only "the unknown")
const ACC = { "--tint": "var(--c1)" };

export function buildMixedBars(s: MixedBarsSpec): SceneDiagram {
  const { d } = s, items: Draft[] = [];
  const pw = U / d;
  const whole = (x: number, y: number, acc: boolean, from: number, delay: number) => {
    items.push({ type: "rect", x, y, w: U, h: H, rx: 6, cls: "seg on", ...(acc ? { vars: ACC } : {}), from, enter: "pop", delay } as Draft);
    items.push(t(x + U / 2, y + H / 2, "1", "sm onlbl", { from, enter: "fade", delay }));
  };
  /** one bar of d pieces: pieces before `on` are shaded tint, then up to `acc` in the accent colour */
  const bar = (x: number, y: number, on: number, acc: number, from: number, until?: number) => {
    for (let i = 0; i < d; i++) {
      const tone = i < on ? "seg on" : i < acc ? "seg on" : "seg";
      items.push({ type: "rect", x: x + i * pw + 0.75, y, w: pw - 1.5, h: H, rx: Math.min(4, pw / 3), cls: tone,
        ...(i >= on && i < acc ? { vars: ACC } : {}), from, ...(until != null ? { until } : {}), enter: "pop", delay: Math.round(i * 0.03 * 100) / 100 } as Draft);
    }
  };
  const label = (y: number, text: string, from = 0, cls = "lbl") => items.push(t(-14, y + H / 2, text, `${cls} end`, { from, enter: "rise" }));

  // the two numbers
  [s.first, s.second].forEach((m, r) => {
    const y = r * ROW, acc = r === 1;
    for (let k = 0; k < m.w; k++) whole(k * (U + GAP), y, acc, 0, k * 0.05);
    const x = m.w * (U + GAP);
    if (acc) bar(x, y, 0, m.n, 0);
    else bar(x, y, m.n, m.n, 0);
    label(y, m.label, 0, acc ? "lbl p1" : "lbl");
  });

  // together: the wholes, then the pieces, then a full bar of pieces becomes a whole
  const y = 2 * ROW + 40, W = s.first.w + s.second.w;
  items.push({ type: "line", x1: -70, y1: y - 30, x2: (W + 2) * (U + GAP), y2: y - 30, cls: "ax thin", from: s.beats.wholes, enter: "draw" } as Draft);
  for (let k = 0; k < W; k++) whole(k * (U + GAP), y, k >= s.first.w, s.beats.wholes, k * 0.06);
  label(y, "together", s.beats.wholes, "sm");
  const S = s.first.n + s.second.n, x = W * (U + GAP);
  bar(x, y, s.first.n, Math.min(S, d), s.beats.pieces);
  if (S > d) bar(x + U + GAP, y, 0, S - d, s.beats.pieces);
  if (s.beats.regroup != null && S >= d) {
    items.push({ type: "rect", x: x - 4, y: y - 4, w: U + 8, h: H + 8, rx: 9, cls: "ln2", from: s.beats.regroup, enter: "pop" } as Draft);
    items.push(t(x + U / 2, y - 17, "1 whole", "sm acc", { from: s.beats.regroup, enter: "rise", delay: 0.2 }));
  }
  items.push(t(-70, y + H + 34, s.total, "lbl acc start", { from: s.beats.total, enter: "rise" }));
  return frame("mixed-bars", items, s.alt, 14, { w: 320 });
}
