// Three numbers to add (g1-three): three ten frames, each addend its own part color (blue, orange, violet) with its
// label in the same color, and the sums being made in amber; the easy pair lights up and joins first, then the last group.
import type { SceneDiagram } from "../scene/schema";
import { frame, t, type Draft } from "../geo/kit";
import { P } from "../early-k/fit";

const CELL = 30, DOT = 10, GAP = 34;

type Timing = { from?: number; until?: number; enter?: Draft["enter"]; delay?: number };

/** n dots (0 to 20) in ten frames side by side at (x, y); returns the items and the width used */
function frames(n: number, x: number, y: number, cls: string | ((d: number) => string), o: Timing): { items: Draft[]; w: number } {
  const count = Math.max(1, Math.ceil(n / 10)), items: Draft[] = [];
  for (let f = 0; f < count; f++) {
    const x0 = x + f * (5 * CELL + 10);
    for (let i = 0; i < 10; i++) {
      items.push({ type: "rect", x: x0 + (i % 5) * CELL, y: y + Math.floor(i / 5) * CELL, w: CELL, h: CELL, cls: "seg", ...o } as Draft);
      if (f * 10 + i < n) items.push({ type: "circle", cx: x0 + (i % 5) * CELL + CELL / 2, cy: y + Math.floor(i / 5) * CELL + CELL / 2, r: DOT, cls: typeof cls === "string" ? cls : cls(f * 10 + i), ...o, delay: (o.delay ?? 0) + 0.04 * i } as Draft);
    }
  }
  return { items, w: count * (5 * CELL) + (count - 1) * 10 };
}

export interface ThreeSpec {
  nums: [number, number, number];
  /** which two are added first (indexes) */
  pair?: [number, number];
  /** beats: the three groups, the pair joined, the last one added. Leave out for practice. */
  beats?: { groups: number; pair: number; last: number };
  alt: string;
}

export function buildThree(s: ThreeSpec): SceneDiagram {
  const items: Draft[] = [], fw = 5 * CELL, b = s.beats;
  s.nums.forEach((n, i) => {
    const x = i * (fw + GAP);
    items.push(...frames(n, x, 0, `dotp ${P(i)}`, { from: 0, enter: "pop", delay: b ? 0.3 * i : 0 }).items);
    if (i) items.push(t(x - GAP / 2, CELL, "+", "big"));
    if (b) items.push(t(x + fw / 2, 2 * CELL + 18, String(n), `lbl ${P(i)}`, { from: b.groups, enter: "rise", delay: 0.3 * i }));
  });
  if (b && s.pair) {
    const [i, j] = s.pair, k = [0, 1, 2].find(q => q !== i && q !== j)!;
    const first = s.nums[i]! + s.nums[j]!, z = s.nums[k]!, sum = first + z;
    for (const q of [i, j]) items.push({ type: "rect", x: q * (fw + GAP) - 6, y: -6, w: fw + 12, h: 2 * CELL + 12, rx: 10, cls: "ring", from: b.pair, until: b.last - 1, enter: "fade" } as Draft);
    const y2 = 2 * CELL + 64;
    const a = frames(first, 0, y2, d => `dotp ${P(d < s.nums[i]! ? i : j)}`, { from: b.pair, enter: "pop" });
    items.push(...a.items);
    items.push(t(a.w / 2, y2 + 2 * CELL + 18, `${s.nums[i]} + ${s.nums[j]} = ${first}`, "lbl acc", { from: b.pair, enter: "rise" }));
    const x3 = a.w + GAP;
    items.push(t(x3 - GAP / 2, y2 + CELL, "+", "big", { from: b.last, enter: "fade" }));
    items.push(...frames(z, x3, y2, `dotp ${P(k)}`, { from: b.last, enter: "pop" }).items);
    items.push(t(x3 + fw / 2, y2 + 2 * CELL + 18, `${first} + ${z} = ${sum}`, "lbl acc", { from: b.last, enter: "rise" }));
  }
  return frame("early-three", items, s.alt, 14);
}
