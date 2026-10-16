import { formatNumber as f, frac, num, op, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildHundredthsSum } from "../../../../explanations/diagrams/early-g4/hundredths";
import { expectedOf, ints, ns } from "../../_tape-family/steps";

/** a/10 + b/100, written as a decimal. */
export interface TenthsHundredthsProblem { a: number; b: number }

export function createTenthsHundredths(a: number, b: number): TenthsHundredthsProblem {
  if (![a, b].every(Number.isInteger) || a < 1 || a > 9 || b < 1 || b > 99) throw new Error(`not a tenths and hundredths problem: ${a}/10 + ${b}/100`);
  return { a, b };
}

/** Same ranges as the current app: 1–9 tenths and 1–99 hundredths. */
export const generateTenthsHundredths = (rng: Rng) => createTenthsHundredths(rng.int(1, 9), rng.int(1, 99));

function answers({ a, b }: TenthsHundredthsProblem): AnswerModel {
  const S = 10 * a + b;
  return {
    steps: [
      ns({ id: "hundredths", l: "Tenths to hundredths", a: s => [frac(a, 10), op("="), frac(s, 100)], ans: 10 * a, h: "Multiply the top and bottom by 10.",
        w: [[a, "Changed only the bottom", "Multiply the top by 10 too."]] }),
      ns({ id: "add", l: "Add the hundredths", a: s => [frac(10 * a, 100), op("+"), frac(b, 100), op("="), frac(s, 100)], ans: S, h: "Same-size pieces: add the tops.",
        w: [[a + b, "Used the tenths as they were", `Tenths are bigger pieces. Use the ${10 * a} hundredths from the step before.`]] }),
      ns({ id: "decimal", l: "Write it as a decimal", a: s => [frac(S, 100), op("="), ...s], ans: S / 100, h: "Hundredths go two places after the point.",
        w: [[S / 10, "Point in the wrong place", "Hundredths need two places after the decimal point."]] }),
    ],
    finalParts: [-1],
  };
}

/**
 * Hundredths on the grid (G 2026-10-15): a cell is one hundredth, a column of ten is one tenth, a 10 by 10 square is
 * one whole. The first square shows a tenths as whole columns, the second b hundredths. Beat 1 cuts the tenths into
 * hundredths, beat 2 puts the cells together (past one whole they fill a second square), beat 3 names the decimal.
 */
export function tenthsHundredthsPicture({ a, b }: TenthsHundredthsProblem) {
  const S = 10 * a + b;
  return buildHundredthsSum({ a, b, decimal: f(S / 100), alt: `Hundredths squares: ${a}/10 is ${a} column${a === 1 ? "" : "s"}, ${10 * a}/100; with ${b}/100 that makes ${S}/100, which is ${f(S / 100)}.` });
}

function explain(p: TenthsHundredthsProblem, model: AnswerModel): Explanation {
  const { a, b } = p;
  const A = expectedOf(model.steps, "hundredths"), S = expectedOf(model.steps, "add"), D = expectedOf(model.steps, "decimal");
  return {
    heading: "Make the pieces match",
    idea: ["1 tenth is the same as 10 hundredths, so both can be written in hundredths."],
    statement: [frac(a, 10), op("+"), frac(b, 100)],
    diagram: tenthsHundredthsPicture(p),
    caption: `${a}/10 is the same as ${A}/100.`,
    timeline: beats(4),
    steps: [
      { id: "hundredths", state: 1, answerStep: "hundredths", result: A, math: [frac(a, 10), op("="), frac(A, 100)],
        narration: "Cut every tenth into 10 hundredths." },
      { id: "add", state: 2, answerStep: "add", result: S, math: [frac(A, 100), op("+"), frac(b, 100), op("="), frac(S, 100)],
        narration: "Same-size pieces now, so add the tops." },
      { id: "decimal", state: 3, answerStep: "decimal", result: D, math: [frac(S, 100), op("="), num(D)],
        narration: `Hundredths go two places after the point.${S >= 100 ? " 100 hundredths make 1 whole." : ""}` },
    ],
  };
}

export const lesson: LessonDefinition<TenthsHundredthsProblem> = {
  id: "g4-dec",
  grade: 4,
  unit: "Decimals",
  title: "Tenths and hundredths",
  pre: "g4-equiv",
  // the current app's card: 3/10 + 25/100 = 0.55
  reference: createTenthsHundredths(3, 25),
  generate: rng => generateTenthsHundredths(rng),
  restore: raw => {
    const r = ints(raw, ["a", "b"] as const);
    try { return r && createTenthsHundredths(r.a, r.b); } catch { return null; }
  },
  display: (p): MathText => [frac(p.a, 10), op("+"), frac(p.b, 100)],
  displayNote: () => "Write the answer as a decimal.",
  answers,
  explain,
};
