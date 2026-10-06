// Big ten frames for kindergarten: a full ten and some more ones (teen numbers), or one frame filled up to 10.
// Counts come from the lesson; the labels are built from them.
import type { SceneDiagram } from "../scene/schema";
import { frame, t, type Draft } from "../geo/kit";
import { WIDE } from "./fit";

const CELL = 46, DOT = 16, TEN = 10;

/** One empty frame (two rows of five) at x0, shown from `beat`. */
function grid(x0: number, beat: number): Draft[] {
  return Array.from({ length: TEN }, (_, i) =>
    ({ type: "rect", x: x0 + (i % 5) * CELL, y: Math.floor(i / 5) * CELL, w: CELL, h: CELL, cls: "seg", from: beat, enter: "fade" } as Draft));
}

const center = (x0: number, i: number): [number, number] => [x0 + (i % 5) * CELL + CELL / 2, Math.floor(i / 5) * CELL + CELL / 2];

/**
 * A full ten frame and a frame holding `ones`. With `beats`: the ten at `ten`, the ones at `ones`,
 * then "10 + ones = number" under both at `whole`. Without: plain frames for a practice problem.
 */
export function teenFrames(ones: number, alt: string, beats?: { ten: number; ones: number; whole: number }): SceneDiagram {
  if (!Number.isInteger(ones) || ones < 1 || ones > 9) throw new Error("a teen number has 1 to 9 ones");
  const GAP = 40, x1 = 5 * CELL + GAP, items: Draft[] = [...grid(0, 0), ...grid(x1, 0)];
  const b = beats ?? { ten: 0, ones: 0, whole: 0 };
  for (let i = 0; i < TEN; i++) {
    const [cx, cy] = center(0, i);
    items.push({ type: "circle", cx, cy, r: DOT, cls: "dotp", from: b.ten, enter: "pop", delay: beats ? 0.08 * i : 0 } as Draft);
  }
  for (let i = 0; i < ones; i++) {
    const [cx, cy] = center(x1, i);
    items.push({ type: "circle", cx, cy, r: DOT, cls: "dotp p1", from: b.ones, enter: "pop", delay: beats ? 0.25 * i : 0 } as Draft);
  }
  if (beats) {
    const under = 2 * CELL + 26;
    items.push(t(2.5 * CELL, under, `${TEN} ones`, "lbl", { from: beats.ten, enter: "rise", delay: 0.9 }));
    items.push(t(x1 + 2.5 * CELL, under, `${ones} more`, "lbl p1", { from: beats.ones, enter: "rise", delay: 0.25 * ones }));
    items.push(t((x1 + 5 * CELL) / 2, under + 46, `${TEN} + ${ones} = ${TEN + ones}`, "lbl big pw", { from: beats.whole, enter: "rise", delay: 0.2 }));
  }
  return frame("early-frames", items, alt, 14, WIDE);
}

/**
 * One ten frame holding `have`. With `beats`: the dots at `have`, the empty boxes filled and counted 1, 2, ... at `fill`,
 * and "have + need = 10" under it at `whole`. Without: the frame with its dots, for a practice problem.
 */
export function fillTen(have: number, alt: string, beats?: { have: number; fill: number; whole: number }): SceneDiagram {
  if (!Number.isInteger(have) || have < 0 || have > TEN) throw new Error("a ten frame holds 0 to 10");
  const items: Draft[] = grid(0, 0), need = TEN - have;
  for (let i = 0; i < have; i++) {
    const [cx, cy] = center(0, i);
    items.push({ type: "circle", cx, cy, r: DOT, cls: "dotp", from: beats?.have ?? 0, enter: "pop", delay: beats ? 0.1 * i : 0 } as Draft);
  }
  if (beats) {
    for (let k = 0; k < need; k++) {
      const [cx, cy] = center(0, have + k);
      items.push({ type: "circle", cx, cy, r: DOT, cls: "dota", from: beats.fill, enter: "pop", delay: 0.35 * k } as Draft);
      items.push(t(cx, cy, String(k + 1), "onlbl", { from: beats.fill, enter: "fade", delay: 0.35 * k + 0.15 }));
    }
    const under = 2 * CELL + 30;
    items.push(t(2.5 * CELL, under, `${have} + ${need} = ${TEN}`, "lbl big pw", { from: beats.whole, enter: "rise", delay: 0.2 }));
  }
  return frame("early-frames", items, alt, 14, WIDE);
}
