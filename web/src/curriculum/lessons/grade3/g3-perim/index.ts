import { num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPerimeter, type PerimeterSide } from "../../../../explanations/diagrams/early-g3/perimeter";
import type { Pt } from "../../../../explanations/diagrams/geo/kit";
import { box, restoreVia, wholeIn } from "../_kit/steps";

/**
 * The distance around a shape, in centimetres. kind 0: a rectangle a by b (only two sides are labeled);
 * kind 1: a square of side a; kind 2: a triangle with base a and sides b and c.
 */
export interface PerimProblem { kind: number; a: number; b: number; c: number }

export function createPerim(kind: number, a: number, b: number, c: number): PerimProblem {
  if (kind === 0) {
    wholeIn("length", a, 2, 15); wholeIn("width", b, 2, 12);
    if (a === b || c !== 0) throw new Error("a rectangle has two different side lengths");
  } else if (kind === 1) {
    wholeIn("side", a, 2, 12);
    if (b !== 0 || c !== 0) throw new Error("a square has one side length");
  } else if (kind === 2) {
    for (const [n, v] of [["a", a], ["b", b], ["c", c]] as const) wholeIn(n, v, 3, 15);
    if (a >= b + c || b >= a + c || c >= a + b) throw new Error(`${a}, ${b}, ${c} do not make a triangle`);
  } else throw new Error("kind is 0, 1 or 2");
  return { kind, a, b, c };
}

/** Early problems are rectangles; later ones are rectangles, squares or triangles. */
export function generatePerim(rng: Rng, index: number): PerimProblem {
  const kind = index < 3 ? 0 : rng.pick([0, 0, 1, 2]);
  if (kind === 0) {
    let a: number, b: number;
    do { a = rng.int(3, index < 3 ? 9 : 15); b = rng.int(2, index < 3 ? 6 : 10); } while (a === b);
    return createPerim(0, Math.max(a, b), Math.min(a, b), 0);
  }
  if (kind === 1) return createPerim(1, rng.int(2, 12), 0, 0);
  for (;;) {
    const a = rng.int(5, 14), b = rng.int(4, 12), c = rng.int(4, 12);
    // a comfortable triangle: not too flat, apex above the base
    if (b + c - a >= 3 && a + c - b >= 3 && a + b - c >= 3 && Math.abs(b - c) < a) return createPerim(2, a, b, c);
  }
}

const cm = (n: number) => `${n} cm`;
const plusLine = (vs: number[]): MathText => vs.flatMap((v, i) => (i ? [op("+"), num(v)] : [num(v)]));
/** Every side's length, in order around the shape. */
export const sidesOf = ({ kind, a, b, c }: PerimProblem) => (kind === 0 ? [a, b, a, b] : kind === 1 ? [a, a, a, a] : [a, b, c]);

function answers(p: PerimProblem): AnswerModel {
  const { kind, a, b, c } = p, P = sidesOf(p).reduce((x, y) => x + y, 0), n = sidesOf(p).length;
  let steps: AnswerStep[];
  if (kind === 0) {
    steps = [
      box({
        id: "two", label: "Two sides", question: "Add the length and the width.",
        prompt: x => [num(a), op("+"), num(b), op("="), x], ans: a + b,
        wrong: [[a * b, "Multiplied", `Perimeter adds up lengths. ${a} × ${b} would be the squares inside.`]],
        hint: `Add the long side and the short side.`, explain: `${a} + ${b} = ${a + b}.`,
      }),
      box({
        id: "around", label: "All the way around", question: "The sides across from each other are the same length.",
        prompt: x => [...plusLine([a, b, a, b]), op("="), x, text(" cm")], ans: P,
        wrong: [
          [a + b, "Added only two sides", `A rectangle has ${n} sides. The two sides without labels are ${a} cm and ${b} cm too.`],
          [a * b, "Found the area", `${a * b} counts squares inside. Perimeter walks around the edge: add all ${n} sides.`],
          [2 * a + b, "Missed a side", `That's only ${n - 1} sides. Add the last ${b} cm side too.`],
          [a + 2 * b, "Missed a side", `That's only ${n - 1} sides. Add the last ${a} cm side too.`],
        ],
        hint: `Two sides make ${a + b}. The other two sides are the same, so add ${a + b} again.`,
        explain: `${a + b} + ${a + b} = ${P}. The perimeter is ${P} cm.`,
      }),
    ];
  } else if (kind === 1) {
    steps = [
      box({
        id: "count", label: "Count the sides", question: `A square has equal sides. How many sides are ${a} cm long?`,
        prompt: x => [text("sides "), op("="), x], ans: n,
        wrong: [[1, "Counted only the labeled side", `Only one side has a label, but all the sides of a square are the same. Count them all.`]],
        hint: "Trace around the square and count the sides.", explain: `A square has ${n} sides, all the same length.`,
      }),
      box({
        id: "around", label: "All the way around", question: `Add ${a} cm for each side.`,
        prompt: x => [...plusLine([a, a, a, a]), op("="), x, text(" cm")], ans: P,
        wrong: [
          [a, "Used only one side", `That's one side. Walk all the way around: ${n} sides of ${a} cm.`],
          [2 * a, "Added only two sides", `That's two sides. A square has ${n} sides of ${a} cm.`],
          [a * a, "Found the area", `${a} × ${a} counts squares inside. Perimeter adds all ${n} sides.`],
        ],
        hint: `Count by ${a}s, once for each side.`, explain: `${n} sides of ${a} cm make ${P} cm.`,
      }),
    ];
  } else {
    steps = [
      box({
        id: "two", label: "Add two sides", prompt: x => [num(a), op("+"), num(b), op("="), x], ans: a + b,
        wrong: [[a * b, "Multiplied", "Perimeter adds up the lengths of the sides."]],
        hint: `Start with the bottom and the right side.`, explain: `${a} + ${b} = ${a + b}.`,
      }),
      box({
        id: "around", label: "Add the last side", prompt: x => [num(a + b), op("+"), num(c), op("="), x, text(" cm")], ans: P,
        wrong: [
          [a + b, "Added only two sides", `A triangle has ${n} sides. Add the ${c} cm side too.`],
        ],
        hint: `Add the third side, ${c} cm.`, explain: `${a + b} + ${c} = ${P}. The perimeter is ${P} cm.`,
      }),
    ];
  }
  return { steps, finalParts: [-1] };
}

/** The shape drawn from its side lengths, with labels outside each side and the trace for each step. */
export function perimPicture(p: PerimProblem, P: number, withBeats = true) {
  const { kind, a, b, c } = p;
  let corners: Pt[], sides: PerimeterSide[];
  if (kind === 0 || kind === 1) {
    const w = kind === 0 ? b : a;
    corners = [[0, 0], [a, 0], [a, w], [0, w]];
    sides = kind === 0
      ? [{ text: cm(a), trace: 1 }, { text: cm(w), trace: 1 }, { text: cm(a), from: 2, acc: true, trace: 2 }, { text: cm(w), from: 2, acc: true, trace: 2 }]
      : [{ text: cm(a), trace: 2 }, { text: cm(a), from: 1, acc: true, trace: 2 }, { text: cm(a), from: 1, acc: true, trace: 2 }, { text: cm(a), from: 1, acc: true, trace: 2 }];
  } else {
    // base a along the bottom; the left side is c, the right side is b
    const x = (a * a + c * c - b * b) / (2 * a), y = Math.sqrt(Math.max(0, c * c - x * x));
    corners = [[0, y], [a, y], [x, 0]];
    sides = [{ text: cm(a), trace: 1 }, { text: cm(b), trace: 1 }, { text: cm(c), trace: 2 }];
  }
  if (!withBeats) sides = sides.map(s => ({ text: (s.from ?? 0) === 0 ? s.text : "" }));
  const all = sidesOf(p);
  return buildPerimeter({
    corners, sides,
    lines: withBeats ? [{ text: `${all.join(" + ")} = ${P} cm`, from: 2 }] : [],
    // the practice picture says only what it shows: the labeled sides, never the total
    alt: withBeats
      ? `A ${kind === 0 ? "rectangle" : kind === 1 ? "square" : "triangle"} with sides ${all.map(cm).join(", ")}. All the way around is ${P} cm.`
      : `A ${kind === 0 ? "rectangle" : kind === 1 ? "square" : "triangle"} with ${sides.filter(s => s.text).map(s => s.text).join(" and ")} labeled.`,
  });
}

function explain(p: PerimProblem, model: AnswerModel): Explanation {
  const { kind, a, b, c } = p, all = sidesOf(p);
  const first = model.steps[0]!, last = model.steps[model.steps.length - 1]!;
  const r1 = first.slots[0]!.expected!, P = last.slots[0]!.expected!;
  return {
    heading: "Walk around the edge",
    idea: ["Perimeter is the whole distance around a shape, so every side counts."],
    statement: [text("perimeter "), op("="), text("?")],
    diagram: perimPicture(p, P),
    caption: kind === 0 ? `Only two sides are labeled. The sides across from them match.` : kind === 1 ? `A square: every side is ${a} cm.` : `A triangle has ${all.length} sides.`,
    timeline: beats(3),
    steps: [
      kind === 0 ? { id: "two", state: 1, answerStep: "two", result: r1, math: [num(a), op("+"), num(b), op("="), num(r1)], narration: `Walk along the top and down the side: ${a} + ${b} = ${r1} cm.` }
        : kind === 1 ? { id: "count", state: 1, answerStep: "count", result: r1, math: [text("sides "), op("="), num(r1)], narration: `A square has ${r1} sides, and they are all ${a} cm long.` }
        : { id: "two", state: 1, answerStep: "two", result: r1, math: [num(a), op("+"), num(b), op("="), num(r1)], narration: `Walk along the bottom and up the right side: ${a} + ${b} = ${r1} cm.` },
      { id: "around", state: 2, answerStep: "around", result: P, math: [...plusLine(all), op("="), num(P)],
        narration: kind === 0 ? `The other two sides match the first two, so add another ${r1}: ${r1} + ${r1} = ${P} cm all the way around.`
          : kind === 1 ? `Go around all ${all.length} sides: ${all.join(" + ")} = ${P} cm.`
          : `Finish with the last side: ${r1} + ${c} = ${P} cm all the way around.` },
    ],
  };
}

export const lesson: LessonDefinition<PerimProblem> = {
  id: "g3-perim",
  grade: 3,
  unit: "Measurement",
  title: "Perimeter",
  reference: createPerim(0, 7, 4, 0),
  generate: generatePerim,
  restore: raw => restoreVia(raw, ["kind", "a", "b", "c"] as const, v => createPerim(v.kind, v.a, v.b, v.c)),
  display: () => [text("perimeter "), op("="), text("?")],
  displayNote: p => (p.kind === 0 ? "Find the distance around the rectangle. The sides across from each other are the same length." : p.kind === 1 ? "Find the distance around the square. All its sides are the same length." : "Find the distance around the triangle. Add every side."),
  picture: p => perimPicture(p, 0, false),
  answers,
  explain,
};
