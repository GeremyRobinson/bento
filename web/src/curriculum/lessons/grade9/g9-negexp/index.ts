import { formatNumber as f, frac, m, num, op, sup, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { fs, ns, supText } from "../../algebra-kit/steps";
import { attempt, readInts, rule } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { count } from "../../../text";
import { negativeExponentPicture } from "./picture";

/** a to the −n: 1 over aⁿ. */
export interface NegativeExponent { kind: "exponents.negative"; a: number; n: number; power: number }

export function createNegativeExponent(a: number, n: number): NegativeExponent {
  rule(a >= 2 && n >= 1, "a ≥ 2 and n ≥ 1");
  return { kind: "exponents.negative", a, n, power: a ** n };
}

/** Same ranges as the current app: a 2–5, n 1–3. */
export const generateNegativeExponent = (rng: Rng) => { const a = rng.int(2, 5), n = rng.int(1, 3); return createNegativeExponent(a, n); };

export function restoreNegativeExponent(raw: unknown): NegativeExponent | null {
  const r = readInts(raw, ["a", "n"] as const);
  return r && attempt(() => createNegativeExponent(r.a, r.n));
}

const pow = (a: number, e: number): MathText => [num(a), sup(e)];

export function negativeExponentAnswers({ a, n }: NegativeExponent): AnswerModel {
  return {
    steps: [
      ns({ id: "positive", l: "Make the exponent positive", a: s => [...pow(a, n), op("="), ...s], ans: a ** n, h: `Multiply ${count(f(n), "copy", "copies")} of ${f(a)}.` }),
      fs({ id: "flip", l: "Flip it", a: s => [...pow(a, -n), op("="), ...s], N: 1, D: a ** n, n: "A negative exponent means 1 over the power.", h: `1 over ${f(a ** n)}.`,
        w: [[-(a ** n), 1, "Thought it was a negative number", "A negative exponent doesn't make the number negative. It flips it: 1 over the power."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainNegativeExponent(p: NegativeExponent, model: AnswerModel) {
  const { a, n } = p;
  const power = model.steps[0]!.slots[0]!.expected!;
  const flip = model.steps[1]!.slots.find(s => s.id === "d")!.expected!;
  // counting down from aⁿ: every step down divides by a
  const down = Array.from({ length: n }, (_, i) => n - 1 - i).map(e => m(...pow(a, e), op("="), a ** e));
  const below = Array.from({ length: n }, (_, i) => i + 1).map(k => m(...pow(a, -k), op("="), frac(1, a ** k)));
  return beatExplanation({
    heading: "Negative exponent = flip",
    idea: ["Anything to the 0 power is 1."],
    statement: pow(a, -n),
    caption: `Each step down divides by ${f(a)}.`,
    diagram: negativeExponentPicture({ a, n, power }),
    alt: `Powers of ${f(a)} counting down from ${f(a)}${supText(n)} = ${f(power)} to ${f(a)}⁰ = 1, then ${f(a)}${supText(-n)} = 1/${f(flip)}.`,
    steps: [
      { id: "positive", narration: `Start with the positive power: ${f(n)} cop${n === 1 ? "y" : "ies"} of ${f(a)} make ${f(power)}.`, math: m(...pow(a, n), op("="), power), answerStep: "positive", result: power },
      { id: "down", narration: `Each step down divides by ${f(a)}, all the way to ${f(a)}⁰ = 1.`, math: m(...pow(a, 0), op("="), 1), lines: down },
      { id: "flip", narration: `Keep dividing past 0: ${f(a)}${supText(-n)} is 1 over ${f(a)}${supText(n)}, which is 1/${f(flip)}.`, math: m(...pow(a, -n), op("="), frac(1, flip)), lines: below, answerStep: "flip", result: flip },
    ],
  });
}

export const lesson: LessonDefinition<NegativeExponent> = {
  id: "g9-negexp",
  grade: 9,
  unit: "Exponents",
  title: "Zero and negative exponents",
  reference: createNegativeExponent(2, 3),
  generate: rng => generateNegativeExponent(rng),
  restore: restoreNegativeExponent,
  display: p => pow(p.a, -p.n),
  answers: negativeExponentAnswers,
  explain: explainNegativeExponent,
};
