import { formatNumber as f, frac, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import { expectedOf, ints, ns } from "../../_tape-family/steps";
import { count, verb } from "../../../text";

/** a/b = x/(b·k); one part k is whole, or a half when a and b are both even (6/4 = x/10, one part 2.5) */
export interface ProportionProblem { a: number; b: number; k: number }

export function createProportion(a: number, b: number, k: number): ProportionProblem {
  if (![a, b, 2 * k, b * k, a * k].every(Number.isInteger) || a < 1 || b < 1 || k < 1) throw new Error(`not a proportion: ${a}/${b} = x/${b * k}`);
  return { a, b, k };
}

/**
 * The current app's ranges (a 1–9, b 2–9, different, k 2–8) for the first problems, the step g6-ratio already took.
 * From the fifth problem on, one part is often a half (6/4 = x/10: one part is 2.5), the step past g6-ratio.
 */
export function generateProportion(rng: Rng, index = 0): ProportionProblem {
  if (index >= 4 && rng.next() < 0.6) {
    let a: number, b: number;
    do { a = 2 * rng.int(1, 4); b = 2 * rng.int(1, 4); } while (a === b);
    return createProportion(a, b, rng.int(1, 4) + 0.5);
  }
  let a: number, b: number;
  do { a = rng.int(1, 9); b = rng.int(2, 9); } while (a === b);
  return createProportion(a, b, rng.int(2, 8));
}

function answers({ a, b, k }: ProportionProblem): AnswerModel {
  const B = b * k, x = a * k;
  // the ids stay "cross" and "divide" so saved progress still matches; the steps now find one part, then build x
  return {
    steps: [
      { ...ns({ id: "cross", l: "One part", q: `${b} parts make ${B}. How big is one part?`, a: s => [text("one part"), op("="), num(B), op("÷"), num(b), op("="), ...s], ans: k,
        h: `${b} equal parts share ${B}. How much does each one get?`,
        w: [[B - b, "Added instead of scaled", "Equal ratios grow by multiplying, not adding."], [B * b, "Multiplied instead of divided", `${B} is shared by ${b} parts, so divide.`]] }),
      explain: `${B} ÷ ${b} = ${f(k)}, so each part is ${f(k)}.` },
      { ...ns({ id: "divide", l: "Build x", q: `The top has ${a} of those parts.`, a: s => [text("x"), op("="), num(a), op("×"), num(k), op("="), ...s], ans: x,
        h: `x is ${a} part${a === 1 ? "" : "s"}, each ${f(k)}.`,
        w: [[a + k, "Added the part", `x is ${a} part${a === 1 ? "" : "s"}, each ${f(k)}: multiply.`], [a + B - b, "Added instead of scaled", "Equal ratios grow by multiplying, not adding."]] }),
      explain: `${a} × ${f(k)} = ${f(x)}.` },
    ],
    finalParts: [-1],
  };
}

/**
 * A ratio tape for the two tops and the two bottoms: a boxes over b boxes of the same size.
 * Beat 1: the bottom is now b·k (and the top is x). Beat 2: each box is k, so x is a boxes: a·k.
 */
export function proportionPicture({ a, b, k }: ProportionProblem) {
  return buildTape({
    rows: [
      { length: a, parts: a, fills: [{ a: 0, b: a, tone: "on", from: 2 }], each: [{ text: () => f(k), from: 2 }], label: [{ text: "top" }],
        total: [{ text: `${a}`, until: 0 }, { text: "x", from: 1, until: 1 }, { text: `x = ${a * k}`, from: 2, acc: true }] },
      { length: b, parts: b, fills: [{ a: 0, b, tone: "two", from: 2 }], each: [{ text: () => f(k), from: 2 }], label: [{ text: "bottom" }],
        total: [{ text: `${b}`, until: 0 }, { text: `${b * k}`, from: 1 }] },
    ],
    alt: `${count(a, "box", "boxes")} over ${count(b, "box", "boxes")} of the same size. When the ${count(b, "box", "boxes")} ${verb(b, "makes", "make")} ${b * k}, each box is ${f(k)}, so the ${count(a, "box", "boxes")} ${verb(a, "makes", "make")} ${a * k}.`,
  });
}

function explain(p: ProportionProblem, model: AnswerModel): Explanation {
  const { a, b } = p, k = expectedOf(model.steps, "cross"), x = expectedOf(model.steps, "divide");
  return {
    heading: "Same scale, top and bottom",
    idea: [
      "Two fractions are equal when the top and the bottom were scaled by the same number.",
      "Find how big one part is from the side you know, then build the other side.",
    ],
    statement: [frac(a, b), op("="), frac("x", b * k)],
    diagram: proportionPicture(p),
    caption: `${a}/${b} = ${f(x)}/${f(b * k)}: each box is ${f(k)}.`,
    timeline: beats(3),
    steps: [
      { id: "cross", state: 1, answerStep: "cross", result: k, math: [num(b * k), op("÷"), num(b), op("="), num(k)],
        narration: `The bottom's ${b} boxes now make ${f(b * k)}, so one box is ${f(b * k)} ÷ ${b} = ${f(k)}.` },
      { id: "divide", state: 2, answerStep: "divide", result: x, math: [text("x"), op("="), num(a), op("×"), num(k), op("="), num(x)],
        narration: `The top is ${a} box${a === 1 ? "" : "es"} of the same size: x = ${a} × ${f(k)} = ${f(x)}. Check: ${a} × ${f(b * k)} and ${b} × ${f(x)} both make ${f(a * b * k)}.` },
    ],
  };
}

export const lesson: LessonDefinition<ProportionProblem> = {
  id: "g7-prop",
  grade: 7,
  unit: "Proportions and percents",
  title: "Solve a proportion",
  // the current app's card and picture: 3/4 = x/20, x = 15
  reference: createProportion(3, 4, 5),
  pre: "g6-ratio",
  generate: (rng, index) => generateProportion(rng, index),
  restore: raw => {
    const r = ints(raw, ["a", "b", "k"] as const);
    try { return r && createProportion(r.a, r.b, r.k); } catch { return null; }
  },
  display: (p): MathText => [frac(p.a, p.b), op("="), frac("x", p.b * p.k)],
  answers,
  explain,
};
