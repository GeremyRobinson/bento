import { num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import { expectedOf, gcd, ints, ns } from "../../_tape-family/steps";
import { count, verb } from "../../../text";

/** a : b = ? : b·k */
export interface RatioProblem { a: number; b: number; k: number }

export function createRatio(a: number, b: number, k: number): RatioProblem {
  if (![a, b, k].every(Number.isInteger) || a < 1 || b < 1 || k < 2) throw new Error(`not a ratio problem: ${a} : ${b} × ${k}`);
  return { a, b, k };
}

/** Same ranges as the current app: a 1–9 and b 2–9 in lowest terms and different, scaled by 2–9. */
export function generateRatio(rng: Rng): RatioProblem {
  let a: number, b: number;
  do { a = rng.int(1, 9); b = rng.int(2, 9); } while (gcd(a, b) !== 1 || a === b);
  return createRatio(a, b, rng.int(2, 9));
}

function answers({ a, b, k }: RatioProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "factor", l: "Find the scale factor", a: s => [num(b), op("×"), ...s, op("="), num(b * k)], ans: k, h: `What times ${b} makes ${b * k}?`,
        w: [[b * k - b, "Added instead of multiplied", "Ratios grow by multiplying, not adding."]] }),
      ns({ id: "scale", l: "Scale the other number", a: s => [num(a), op("×"), num(k), op("="), ...s], ans: a * k, h: `Multiply ${a} by the same ${k}.`,
        w: [[a + b * k - b, "Added instead of multiplied", "Use the same multiply on both numbers."]] }),
    ],
    finalParts: [-1],
  };
}

/**
 * A ratio tape: a equal boxes over b equal boxes (same box size). The b boxes make b·k, so each box is k (beat 1);
 * then the a boxes make a·k (beat 2).
 */
export function ratioPicture({ a, b, k }: RatioProblem) {
  return buildTape({
    rows: [
      { length: a, parts: a, fills: [{ a: 0, b: a, tone: "on", from: 2 }], each: [{ text: () => `${k}`, from: 2 }], label: [{ text: `${a} part${a === 1 ? "" : "s"}` }],
        total: [{ text: "?", until: 1 }, { text: `${a * k}`, from: 2, acc: true }] },
      { length: b, parts: b, fills: [{ a: 0, b, tone: "two", from: 1 }], each: [{ text: () => `${k}`, from: 1 }], label: [{ text: `${b} part${b === 1 ? "" : "s"}` }],
        total: [{ text: `${b * k}` }] },
    ],
    alt: `A ratio tape: ${count(a, "box", "boxes")} and ${count(b, "box", "boxes")} of the same size. ${count(b, "box", "boxes")} ${verb(b, "makes", "make")} ${b * k}, so each box is ${k} and ${count(a, "box", "boxes")} ${verb(a, "makes", "make")} ${a * k}.`,
  });
}

function explain(p: RatioProblem, model: AnswerModel): Explanation {
  const { a, b } = p, k = expectedOf(model.steps, "factor"), ak = expectedOf(model.steps, "scale");
  return {
    heading: "Multiply both parts the same",
    statement: [num(a), text(" : "), num(b), op("="), text("? : "), num(b * k)],
    diagram: ratioPicture(p),
    caption: `Every box is the same size: ${k}.`,
    timeline: beats(3),
    steps: [
      { id: "factor", state: 1, answerStep: "factor", result: k, math: [num(b), op("×"), num(k), op("="), num(b * k)],
        narration: `${b} equal parts make ${b * k}, so each part is ${k}: ${b} × ${k} = ${b * k}.` },
      { id: "scale", state: 2, answerStep: "scale", result: ak, math: [num(a), op("×"), num(k), op("="), num(ak)],
        narration: `The other side has ${a} of the same parts: ${a} × ${k} = ${ak}. So ${a} : ${b} = ${ak} : ${b * k}.` },
    ],
  };
}

export const lesson: LessonDefinition<RatioProblem> = {
  id: "g6-ratio",
  grade: 6,
  unit: "Ratios and percents",
  title: "Equivalent ratios",
  // the current app's card and picture: 2 : 3 = 8 : 12
  reference: createRatio(2, 3, 4),
  generate: rng => generateRatio(rng),
  restore: raw => {
    const r = ints(raw, ["a", "b", "k"] as const);
    try { return r && createRatio(r.a, r.b, r.k); } catch { return null; }
  },
  display: (p): MathText => [num(p.a), text(" : "), num(p.b), op("="), text("? : "), num(p.b * p.k)],
  answers,
  explain,
};
