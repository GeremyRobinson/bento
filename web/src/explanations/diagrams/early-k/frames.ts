// Big ten frames for kindergarten: a full ten and some more ones (teen numbers), or one frame filled up to 10.
// Counts come from the lesson; the labels are built from them.
import type { SceneDiagram } from "../scene/schema";
import { frame, path, t, type Draft } from "../geo/kit";
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

/**
 * Make a ten to add (g1-ten): a frame holding `a` and a frame holding `b`. At `ten` the empty boxes of the first frame
 * are counted 1, 2, ... (the ones it needs); at `break` that many dots slide over from the second frame into them
 * (the last dots of the second frame, which may sit in its top row) and "b = need + left" shows under it;
 * at `add` the full first frame is ringed "10" and "10 + left = sum" rises under both.
 * `parts` are the part colours of the two numbers (the grade's two part roles that are neither right nor wrong).
 */
export function makeTenFrames(o: { a: number; b: number; beats: { ten: number; break: number; add: number }; alt: string; parts?: [string, string] }): SceneDiagram {
  const { a, b, beats } = o, [pa, pb] = o.parts ?? ["p0", "p1"];
  if (!Number.isInteger(a) || a < 1 || a > 9) throw new Error("the first number fills part of a ten frame");
  const need = TEN - a, left = b - need;
  if (!Number.isInteger(b) || b > TEN || left < 1) throw new Error("the second number goes past ten");
  const GAP = 40, x1 = 5 * CELL + GAP;
  // each frame is outlined in its own number's colour (in dark mode the empty boxes take it too)
  const items: Draft[] = [...grid(0, 0).map(d => ({ ...d, cls: `seg ${pa}` }) as Draft), ...grid(x1, 0).map(d => ({ ...d, cls: `seg ${pb}` }) as Draft)];
  for (let i = 0; i < a; i++) {
    const [cx, cy] = center(0, i);
    items.push({ type: "circle", cx, cy, r: DOT, cls: `dotp ${pa}`, from: 0, enter: "pop", delay: 0.06 * i } as Draft);
  }
  // the empty boxes the first number needs, counted up in the accent
  for (let k = 0; k < need; k++) {
    const [cx, cy] = center(0, a + k);
    items.push({ type: "circle", cx, cy, r: DOT, cls: "hole pq dash", from: beats.ten, until: beats.break - 1, enter: "pop", delay: 0.8 + 0.4 * k } as Draft);
    items.push(t(cx, cy, String(k + 1), "lbl pq", { from: beats.ten, until: beats.break - 1, enter: "fade", delay: 0.95 + 0.4 * k }));
  }
  for (let i = 0; i < b; i++) {
    const [cx, cy] = center(x1, i), moves = i >= left;
    items.push({ type: "circle", cx, cy, r: DOT, cls: `dotp ${pb}`, from: 0, ...(moves ? { until: beats.break - 1 } : {}), enter: "pop", delay: 0.4 + 0.06 * i } as Draft);
    if (!moves) continue;
    // the same dot, now in the first frame: it slides there from where it was
    const [tx, ty] = center(0, a + (i - left));
    items.push({ type: "circle", cx: tx, cy: ty, r: DOT, cls: `dotp ${pb}`, from: beats.break, enter: "slide", delay: 0.3 * (i - left),
      vars: { "--dx": `${cx - tx}px`, "--dy": `${cy - ty}px` } } as Draft);
  }
  const under = 2 * CELL + 26;
  items.push(t(2.5 * CELL, under, String(a), `lbl ${pa}`, { from: 0, until: beats.add - 1, enter: "rise", delay: 0.3 }));
  items.push(t(x1 + 2.5 * CELL, under, String(b), `lbl ${pb}`, { from: 0, until: beats.break - 1, enter: "rise", delay: 0.6 }));
  items.push(t(x1 + 2.5 * CELL, under, `${b} = ${need} + ${left}`, `lbl ${pb}`, { from: beats.break, enter: "rise", delay: 0.3 * need + 0.6 }));
  // the full ten, ringed
  const R = 10, X0 = -6, Y0 = -6, X1 = 5 * CELL + 6, Y1 = 2 * CELL + 6;
  items.push(path([
    { c: "M", p: [X0 + R, Y0] }, { c: "L", p: [X1 - R, Y0] }, { c: "Q", q: [X1, Y0], p: [X1, Y0 + R] }, { c: "L", p: [X1, Y1 - R] }, { c: "Q", q: [X1, Y1], p: [X1 - R, Y1] },
    { c: "L", p: [X0 + R, Y1] }, { c: "Q", q: [X0, Y1], p: [X0, Y1 - R] }, { c: "L", p: [X0, Y0 + R] }, { c: "Q", q: [X0, Y0], p: [X0 + R, Y0] },
  ], "ring", { from: beats.add, enter: "draw" }));
  items.push(t(2.5 * CELL, under, String(TEN), "lbl pw", { from: beats.add, enter: "rise", delay: 0.5 }));
  items.push(t((x1 + 5 * CELL) / 2, under + 46, `${TEN} + ${left} = ${TEN + left}`, "lbl big pw", { from: beats.add, enter: "rise", delay: 0.9 }));
  return frame("early-frames", items, o.alt, 14, WIDE);
}
