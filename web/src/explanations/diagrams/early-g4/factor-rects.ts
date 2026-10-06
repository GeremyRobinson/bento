// Factors and multiples (4th grade): n squares arranged in every rectangle they make, one factor pair each,
// then a try with t rows that either comes out even or leaves squares over.
import type { SceneDiagram } from "../scene/schema";
import { frame, t, type Draft } from "../geo/kit";

export interface FactorRectsSpec {
  n: number;
  /** each pair as rows × columns, with the beat it appears at */
  pairs: { a: number; b: number; beat: number }[];
  /** the try: t rows of squares */
  test: { t: number; beat: number };
  /** the list of factors under the picture */
  list: { text: string; beat: number };
  alt: string;
}

// every rectangle is the same n squares, so they share one color (part blue), not a color each for variety (handoff-6)
const TONE = "cell c0";

export function buildFactorRects(s: FactorRectsSpec): SceneDiagram {
  const cs = Math.min(18, 440 / s.n), gap = 16;
  const items: Draft[] = [];
  const labelX = s.n * cs + 22;
  let y = 0;
  const square = (row: number, col: number, top: number, cls: string, from: number, k: number) =>
    items.push({ type: "rect", x: col * cs + 1, y: top + row * cs + 1, w: cs - 2, h: cs - 2, rx: Math.min(3, cs / 5), cls, from, enter: "pop", delay: Math.round(Math.min(0.8, k * 0.012) * 100) / 100 } as Draft);

  s.pairs.forEach(p => {
    let c = 0;
    for (let col = 0; col < p.b; col++) for (let row = 0; row < p.a; row++) square(row, col, y, TONE, p.beat, c++);
    items.push(t(labelX, y + (p.a * cs) / 2, `${p.a} × ${p.b}`, "lbl start", { from: p.beat, enter: "rise", delay: 0.3 }));
    y += p.a * cs + gap;
  });

  // the try: fill t rows column by column; squares that don't make a full column are left over
  const q = Math.floor(s.n / s.test.t), r = s.n % s.test.t;
  let c = 0;
  for (let col = 0; col < q; col++) for (let row = 0; row < s.test.t; row++) square(row, col, y, "sq", s.test.beat, c++);
  for (let row = 0; row < r; row++) square(row, q, y, "sq big", s.test.beat, c++);
  const tryLabel = r ? `${s.test.t} rows: ${r} left over` : `${s.test.t} × ${q}`;
  items.push(t(labelX, y + (s.test.t * cs) / 2, tryLabel, r ? "lbl acc start" : "lbl start", { from: s.test.beat, enter: "rise", delay: 0.4 }));
  y += s.test.t * cs + gap + 14;

  items.push(t(0, y, s.list.text, "lbl acc start", { from: s.list.beat, enter: "rise" }));
  return frame("factor-rects", items, s.alt, 14, { w: 320 });
}
