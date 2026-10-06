import { formatNumber as f, m, mark, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { fP, ns, P, poly, v, xp } from "../../algebra-kit/steps";
import { attempt, nz, readInts } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { coef } from "../../../text";
import { polynomialDerivativePicture } from "./picture";

/** f(x) = ax³ + bx² + cx + d; f′(x) = 3ax² + 2bx + c, and f′(1). */
export interface PolynomialDerivative { kind: "derivatives.polynomial"; a: number; b: number; c: number; d: number }

export const createPolynomialDerivative = (a: number, b: number, c: number, d: number): PolynomialDerivative => ({ kind: "derivatives.polynomial", a, b, c, d });

/** Same ranges as the current app: a −4–4, b −6–6, c −9–9 (none 0), d −9–9. */
export function generatePolynomialDerivative(rng: Rng): PolynomialDerivative {
  const a = nz(rng, -4, 4), b = nz(rng, -6, 6), c = nz(rng, -9, 9), d = rng.int(-9, 9);
  return createPolynomialDerivative(a, b, c, d);
}

export function restorePolynomialDerivative(raw: unknown): PolynomialDerivative | null {
  const r = readInts(raw, ["a", "b", "c", "d"] as const);
  return r && attempt(() => createPolynomialDerivative(r.a, r.b, r.c, r.d));
}

const X: MathText = [v()];
const fx = ({ a, b, c, d }: PolynomialDerivative): MathText => [text("f(x)"), op("="), ...poly([[a, xp(3)], [b, xp(2)], [c, X], [d, []]])];

export function polynomialDerivativeAnswers({ a, b, c }: PolynomialDerivative): AnswerModel {
  return {
    steps: [
      ns({ id: "x3", l: "x³ term", a: s => [...s, ...xp(2)], ans: 3 * a, h: `3 × ${f(a)}.` }),
      ns({ id: "x2", l: "x² term", a: s => [...s, v()], ans: 2 * b, h: `2 × ${f(b)}.` }),
      ns({ id: "x1", l: "x term", a: s => s, ans: c, h: "The derivative of cx is c. The constant disappears." }),
      ns({ id: "at1", l: "f′(1)", a: s => [num(3 * a), op("+"), ...P(2 * b), op("+"), ...P(c), op("="), ...s], ans: 3 * a + 2 * b + c, h: "With x = 1 every power of x is 1, so just add." }),
    ],
    finalParts: [-1],
  };
}

export function explainPolynomialDerivative(p: PolynomialDerivative, model: AnswerModel) {
  const { a, b, d } = p;
  const [A, B, C, total] = model.steps.map(s => s.slots[0]!.expected!) as [number, number, number, number];
  const fprime = (terms: [number, MathText][]): MathText => [text("f′(x)"), op("="), ...poly(terms)];
  return beatExplanation({
    heading: "One term at a time",
    statement: fx(p),
    caption: d ? `The constant ${f(d)} drops out: its derivative is 0.` : "Each term follows the power rule on its own.",
    alt: `f′(x) = ${f(A)}x² + ${fP(B)}x + ${fP(C)}, and f′(1) = ${f(total)}.`,
    diagram: polynomialDerivativePicture({ a, b, c: p.c, d, A, B, C, total }),
    steps: [
      { id: "problem", narration: `Take the derivative one term at a time.${d ? ` The ${f(d)} on its own will drop out.` : ""}`, math: [text("f(x)"), op("="), ...poly([[a, xp(3)], [b, xp(2)], [p.c, X]]), ...(d ? [op(d < 0 ? "−" : "+"), mark(Math.abs(d))] : [])] },
      { id: "x3", narration: `x³ term: bring the 3 down, 3 × ${f(a)} = ${f(A)}, and x³ becomes x².`, math: m(3, op("×"), ...P(a), op("="), A), line: fprime([[A, xp(2)]]), answerStep: "x3", result: A },
      { id: "x2", narration: `x² term: 2 × ${f(b)} = ${f(B)}, and x² becomes x.`, math: m(2, op("×"), ...P(b), op("="), B), line: fprime([[A, xp(2)], [B, X]]), answerStep: "x2", result: B },
      { id: "x1", narration: `The derivative of ${coef(C, "x")} is ${f(C)}.${d ? ` The constant ${f(d)} becomes 0.` : ""}`, math: [num(C), v(), op("→"), num(C)], line: fprime([[A, xp(2)], [B, X], [C, []]]), answerStep: "x1", result: C },
      { id: "at1", narration: `At x = 1 every power of x is 1, so just add: f′(1) = ${f(total)}.`, math: m(text("f′(1)"), op("="), A, op("+"), ...P(B), op("+"), ...P(C), op("="), total), answerStep: "at1", result: total },
    ],
  });
}

export const lesson: LessonDefinition<PolynomialDerivative> = {
  id: "g12-polyd",
  grade: 12,
  unit: "Derivatives",
  title: "Derivative of a polynomial",
  reference: createPolynomialDerivative(2, -1, 5, 7),
  generate: rng => generatePolynomialDerivative(rng),
  restore: restorePolynomialDerivative,
  display: fx,
  displayNote: () => "Find f′(x), then f′(1).",
  answers: polynomialDerivativeAnswers,
  explain: explainPolynomialDerivative,
};
