import { formatNumber as f, m, mark, num, op, sup, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { big, fpm, ns, pm, v } from "../../algebra-kit/steps";
import { attempt, nz, readInts, rule } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { withEasyStart } from "../../easy-start";

/** b to the (x + c) = bᵏ, so x + c = k. */
export interface ExponentialEquation { kind: "equation.exponential"; b: number; k: number; c: number; value: number; x: number }

export function createExponentialEquation(b: number, k: number, c: number): ExponentialEquation {
  rule(b >= 2 && k >= 1 && c !== 0, "base ≥ 2, k ≥ 1, c ≠ 0");
  return { kind: "equation.exponential", b, k, c, value: b ** k, x: k - c };
}

/** Same ranges as the current app: base 2, 3 or 5; k up to 7 for base 2 and up to 4 otherwise; c from −5 to 5, not 0. */
export function generateExponentialEquation(rng: Rng): ExponentialEquation {
  const b = rng.pick([2, 3, 5]), k = rng.int(2, b === 2 ? 7 : 4);
  return createExponentialEquation(b, k, nz(rng, -5, 5));
}

export function restoreExponentialEquation(raw: unknown): ExponentialEquation | null {
  const r = readInts(raw, ["b", "k", "c"] as const);
  return r && attempt(() => createExponentialEquation(r.b, r.k, r.c));
}

const exponent = (c: number): MathText => [v(), ...pm(c)];
const lhs = (p: ExponentialEquation): MathText => [num(p.b), sup(exponent(p.c))];

export function exponentialAnswers({ b, k, c, value }: ExponentialEquation): AnswerModel {
  return {
    steps: [
      ns({ id: "base", l: "Same base", a: s => [text(big(value)), op("="), num(b), sup(s)], ans: k, h: `Count how many times the base multiplies to make ${big(value)}.`,
        w: [[value / b, "Divided", `That is ${big(value)} ÷ ${f(b)}. Count how many ${f(b)}'s multiply together to make ${big(value)}.`]] }),
      ns({ id: "solve", l: "Set exponents equal", a: s => [...exponent(c), op("="), num(k), text(", so "), v(), op("="), ...s], ans: k - c,
        h: `Same base means the exponents match. Undo the ${fpm(c)}.`, w: [[k + c, "Wrong direction", `x ${fpm(c)} = ${f(k)} means x is ${c > 0 ? "less" : "more"} than ${f(k)} by ${f(Math.abs(c))}, so ${c > 0 ? "subtract" : "add"} ${f(Math.abs(c))}.`]] }),
    ],
    finalParts: [-1],
  };
}

export function explainExponential(p: ExponentialEquation, model: AnswerModel) {
  const { b, c, value } = p;
  const [k, x] = model.steps.map(s => s.slots[0]!.expected!) as [number, number];
  return beatExplanation({
    heading: "Make the bases match",
    idea: ["Each power of 3 is a different number: 3, 9, 27, 81 and so on. So if 3 to one power equals 3 to another, the powers must be the same.", "Write both sides as powers of the same base, then set the exponents equal."],
    statement: [...lhs(p), op("="), text(big(value))],
    caption: `Write ${big(value)} as a power of ${f(b)}, then the exponents must be equal.`,
    alt: `${f(b)} to the x ${fpm(c)} = ${big(value)} = ${f(b)} to the ${f(k)}, so x ${fpm(c)} = ${f(k)} and x = ${f(x)}.`,
    steps: [
      { id: "problem", narration: `The left side is a power of ${f(b)}. Can ${big(value)} be one too?`, math: [...lhs(p), op("="), mark(big(value))] },
      { id: "base", narration: `${f(k)} ${f(b)}'s multiply to ${big(value)}, so ${big(value)} = ${f(b)} to the ${f(k)}.`, math: [text(big(value)), op("="), num(b), sup(k)],
        line: [...lhs(p), op("="), num(b), sup([mark(k)])], answerStep: "base", result: k },
      { id: "match", narration: `Same base, so the exponents match.`, math: [...exponent(c), op("="), num(k)] },
      { id: "solve", narration: `Undo the ${fpm(c)}: x = ${f(x)}.`, math: m(v(), op("="), k, op(c < 0 ? "+" : "−"), Math.abs(c), op("="), x), answerStep: "solve", result: x },
    ],
  });
}

export const lesson: LessonDefinition<ExponentialEquation> = withEasyStart({
  id: "g11-expeq",
  grade: 11,
  unit: "Exponents and logs",
  title: "Exponential equations",
  reference: createExponentialEquation(2, 4, 1),
  generate: rng => generateExponentialEquation(rng),
  restore: restoreExponentialEquation,
  display: p => [...lhs(p), op("="), text(big(p.value))],
  displayNote: () => "Solve for x.",
  answers: exponentialAnswers,
  explain: explainExponential,
});
