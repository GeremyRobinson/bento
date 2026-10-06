import { formatNumber as f, frac, m, mark, num, op, sup, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { ns, poly, supText, v, xp } from "../../algebra-kit/steps";
import { attempt, readInts, rule } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { antiderivativePicture } from "./picture";
import { withEasyStart } from "../../easy-start";

/** ∫ a·xⁿ dx = (a ÷ (n + 1))·xⁿ⁺¹ + C, with a a multiple of n + 1. */
export interface Antiderivative { kind: "integrals.power"; a: number; n: number }

export function createAntiderivative(a: number, n: number): Antiderivative {
  rule(n >= 1 && a !== 0 && a % (n + 1) === 0, "n ≥ 1 and a a multiple of n + 1");
  return { kind: "integrals.power", a, n };
}

/** Same ranges as the current app: n 1–5, a = (n + 1) × one of 1, 2, 3, 4, −1, −2. */
export function generateAntiderivative(rng: Rng): Antiderivative {
  const n = rng.int(1, 5);
  return createAntiderivative((n + 1) * rng.pick([1, 2, 3, 4, -1, -2]), n);
}

export function restoreAntiderivative(raw: unknown): Antiderivative | null {
  const r = readInts(raw, ["a", "n"] as const);
  return r && attempt(() => createAntiderivative(r.a, r.n));
}

/** c·xᵉ as message text: "x⁶" and "−x⁶" for ±1. */
const termText = (c: number, e: number) => `${c === 1 ? "" : c === -1 ? "−" : f(c)}x${supText(e)}`;
const coef = (a: number): MathText => (a === 1 ? [] : [num(a)]);
const integral = ({ a, n }: Antiderivative, e: MathText = [num(n)]): MathText => [text("∫"), ...coef(a), v(), sup(e), text("dx")];

export function antiderivativeAnswers({ a, n }: Antiderivative): AnswerModel {
  return {
    steps: [
      ns({ id: "raise", l: "Raise the exponent", a: s => [num(n), op("+"), num(1), op("="), ...s], ans: n + 1, h: "Integrating goes the other way from derivatives: up by 1.",
        w: [[n - 1, "Lowered instead", "That's the derivative. Antiderivatives go up."]] }),
      ns({ id: "divide", l: "Divide by it", a: s => [num(a), op("÷"), num(n + 1), op("="), ...s], ans: a / (n + 1), h: "The derivative would multiply by the new exponent, so divide by it to undo that.", w: [[a * (n + 1), "Multiplied", `That's what the derivative does. Going back, divide by ${f(n + 1)}.`]],
        n: `Answer: (that)x${supText(n + 1)} + C` }),
    ],
    finalParts: [-2, -1],
  };
}

export function explainAntiderivative(p: Antiderivative, model: AnswerModel) {
  const { a, n } = p;
  const [up, c] = model.steps.map(s => s.slots[0]!.expected!) as [number, number];
  return beatExplanation({
    heading: "Up one, divide by the new power",
    idea: ["An antiderivative runs the power rule backwards: find the function whose derivative is the one you have.", "The derivative lowers the power by 1 and multiplies by it, so going back you raise the power by 1 and divide by the new power. Check by taking the derivative."],
    statement: integral(p),
    caption: `Check: the derivative of ${termText(c, up)} is ${f(up)} × ${termText(c, n)} = ${termText(a, n)}.`,
    alt: `∫ ${termText(a, n)} dx: the exponent goes up to ${f(up)}, and ${f(a)} ÷ ${f(up)} = ${f(c)}, so ${termText(c, up)} + C.`,
    diagram: antiderivativePicture({ a, n, up, c }),
    steps: [
      { id: "problem", narration: `Integrating goes the other way from derivatives.`, math: integral(p, [mark(n)]) },
      { id: "raise", narration: `Raise the exponent by 1: ${f(n)} + 1 = ${f(up)}.`, math: m(n, op("+"), 1, op("="), up), line: [frac([...coef(a), v(), sup([mark(up)])], [mark(up)])], answerStep: "raise", result: up },
      { id: "divide", narration: `Divide by the new exponent: ${f(a)} ÷ ${f(up)} = ${f(c)}. Add + C for any constant.`, math: m(a, op("÷"), up, op("="), c),
        line: [...poly([[c, xp(up)]]), op("+"), text("C")], answerStep: "divide", result: c },
      { id: "check", narration: `Check by going forward: the derivative of ${termText(c, up)} is ${f(up)} × ${termText(c, n)} = ${termText(a, n)}, the function we started with.`,
        math: [text("d/dx"), text(" "), ...poly([[c, xp(up)]]), op("="), ...poly([[a, n === 1 ? [v()] : xp(n)]])], line: null },
    ],
  });
}

export const lesson: LessonDefinition<Antiderivative> = withEasyStart({
  id: "g12-anti",
  grade: 12,
  unit: "Integrals",
  title: "Antiderivatives",
  pre: "g12-power",
  reference: createAntiderivative(6, 2),
  generate: rng => generateAntiderivative(rng),
  restore: restoreAntiderivative,
  display: p => integral(p),
  answers: antiderivativeAnswers,
  explain: explainAntiderivative,
});
