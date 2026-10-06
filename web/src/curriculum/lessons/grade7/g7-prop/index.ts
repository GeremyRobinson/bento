import { frac, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import { expectedOf, ints, ns } from "../../_tape-family/steps";
import { count, verb } from "../../../text";

/** a/b = x/(b·k) */
export interface ProportionProblem { a: number; b: number; k: number }

export function createProportion(a: number, b: number, k: number): ProportionProblem {
  if (![a, b, k].every(Number.isInteger) || a < 1 || b < 1 || k < 1) throw new Error(`not a proportion: ${a}/${b} = x/${b * k}`);
  return { a, b, k };
}

/** Same ranges as the current app: a 1–9, b 2–9, different, k 2–8. */
export function generateProportion(rng: Rng): ProportionProblem {
  let a: number, b: number;
  do { a = rng.int(1, 9); b = rng.int(2, 9); } while (a === b);
  return createProportion(a, b, rng.int(2, 8));
}

function answers({ a, b, k }: ProportionProblem): AnswerModel {
  const cross = a * b * k;
  return {
    steps: [
      ns({ id: "cross", l: "Cross multiply", a: s => [num(a), op("×"), num(b * k), op("="), ...s], ans: cross, h: "Multiply the top-left by the bottom-right." }),
      ns({ id: "divide", l: "Divide", a: s => [text("x"), op("="), num(cross), op("÷"), num(b), op("="), ...s], ans: a * k, h: "Divide by the number across from x.",
        w: [[cross * b, "Multiplied instead of divided", `x × ${b} = ${cross}, so divide by ${b}.`]] }),
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
      { length: a, parts: a, fills: [{ a: 0, b: a, tone: "on", from: 2 }], each: [{ text: () => `${k}`, from: 2 }], label: [{ text: "top" }],
        total: [{ text: `${a}`, until: 0 }, { text: "x", from: 1, until: 1 }, { text: `x = ${a * k}`, from: 2, acc: true }] },
      { length: b, parts: b, fills: [{ a: 0, b, tone: "two", from: 2 }], each: [{ text: () => `${k}`, from: 2 }], label: [{ text: "bottom" }],
        total: [{ text: `${b}`, until: 0 }, { text: `${b * k}`, from: 1 }] },
    ],
    alt: `${count(a, "box", "boxes")} over ${count(b, "box", "boxes")} of the same size. When the ${count(b, "box", "boxes")} ${verb(b, "makes", "make")} ${b * k}, each box is ${k}, so the ${count(a, "box", "boxes")} ${verb(a, "makes", "make")} ${a * k}.`,
  });
}

function explain(p: ProportionProblem, model: AnswerModel): Explanation {
  const { a, b, k } = p, cross = expectedOf(model.steps, "cross"), x = expectedOf(model.steps, "divide");
  return {
    heading: "Cross multiply, then divide",
    statement: [frac(a, b), op("="), frac("x", b * k)],
    diagram: proportionPicture(p),
    caption: `${a}/${b} = ${x}/${b * k}: each box is ${k}.`,
    timeline: beats(3),
    steps: [
      { id: "cross", state: 1, answerStep: "cross", result: cross, math: [num(a), op("×"), num(b * k), op("="), num(cross)],
        narration: `Cross multiply: the top-left times the bottom-right, ${a} × ${b * k} = ${cross}. That is x × ${b}.` },
      { id: "divide", state: 2, answerStep: "divide", result: x, math: [text("x"), op("="), num(cross), op("÷"), num(b), op("="), num(x)],
        narration: `Divide by the ${b} across from x: ${cross} ÷ ${b} = ${x}. In the picture each box is ${k}, and x is ${a} box${a === 1 ? "" : "es"}.` },
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
  generate: rng => generateProportion(rng),
  restore: raw => {
    const r = ints(raw, ["a", "b", "k"] as const);
    try { return r && createProportion(r.a, r.b, r.k); } catch { return null; }
  },
  display: (p): MathText => [frac(p.a, p.b), op("="), frac("x", p.b * p.k)],
  answers,
  explain,
};
