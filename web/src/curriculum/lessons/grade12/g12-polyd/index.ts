import { formatNumber as f, m, mark, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { fP, ns, P, poly, v, xp } from "../../algebra-kit/steps";
import { attempt, nz, readInts } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { coef } from "../../../text";
import { polynomialDerivativePicture } from "./picture";
import { withEasyStart } from "../../easy-start";

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

export function polynomialDerivativeAnswers({ a, b, c, d }: PolynomialDerivative): AnswerModel {
  return {
    steps: [
      ns({ id: "x3", l: "x³ term", a: s => [...s, ...xp(2)], ans: 3 * a, h: `Power rule: the exponent comes down and multiplies the ${f(a)} in front, and x³ becomes x².`, w: [[a, "Didn't bring the 3 down", `Bring the 3 down: 3 × ${f(a)}.`]] }),
      ns({ id: "x2", l: "x² term", a: s => [...s, v()], ans: 2 * b, h: `The exponent comes down and multiplies the ${f(b)} in front, and x² becomes x.`, w: [[b, "Didn't bring the 2 down", `Bring the 2 down: 2 × ${f(b)}.`]] }),
      ns({ id: "x1", l: "x term", a: s => s, ans: c, h: "cx is a line with slope c, so its derivative is c. The constant is flat, so it disappears.", w: [[0, "Dropped the x term", "cx is a line with slope c; it does not vanish. Only the constant does."]] }),
      ns({ id: "at1", l: "f′(1)", a: s => [num(3 * a), op("+"), ...P(2 * b), op("+"), ...P(c), op("="), ...s], ans: 3 * a + 2 * b + c, h: "f′(1) is how steep the graph is at x = 1. Every power of 1 is 1, so add the derivative's numbers.",
        w: [[a + b + c + d, "Used f instead of f′", `That is f(1), the height. f′(1) uses the derivative's numbers: ${f(3 * a)}, ${fP(2 * b)}, ${fP(c)}.`]] }),
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
    idea: ["The slope of a sum is the sum of the slopes, so take the derivative one term at a time.", "A constant is a flat line with slope 0, so it drops out. f′(1) is how steep the graph is at x = 1."],
    statement: fx(p),
    caption: d ? `The constant ${f(d)} drops out: its derivative is 0.` : "Each term follows the power rule on its own.",
    alt: `f′(x) = ${f(A)}x² + ${fP(B)}x + ${fP(C)}, and f′(1) = ${f(total)}.`,
    diagram: polynomialDerivativePicture({ a, b, c: p.c, d, A, B, C, total }),
    steps: [
      { id: "problem", narration: `Take the derivative one term at a time.${d ? ` The ${f(d)} on its own will drop out.` : ""}`, math: [text("f(x)"), op("="), ...poly([[a, xp(3)], [b, xp(2)], [p.c, X]]), ...(d ? [op(d < 0 ? "−" : "+"), mark(Math.abs(d))] : [])] },
      { id: "x3", narration: `x³ term: bring the 3 down, 3 × ${f(a)} = ${f(A)}, and x³ becomes x².`, math: m(3, op("×"), ...P(a), op("="), A), line: fprime([[A, xp(2)]]), answerStep: "x3", result: A },
      { id: "x2", narration: `x² term: 2 × ${f(b)} = ${f(B)}, and x² becomes x.`, math: m(2, op("×"), ...P(b), op("="), B), line: fprime([[A, xp(2)], [B, X]]), answerStep: "x2", result: B },
      { id: "x1", narration: `The derivative of ${coef(C, "x")} is ${f(C)}.${d ? ` The constant ${f(d)} becomes 0.` : ""}`, math: [num(C), v(), op("→"), num(C)], line: fprime([[A, xp(2)], [B, X], [C, []]]), answerStep: "x1", result: C },
      { id: "at1", narration: `At x = 1 every power of x is 1, so f′(1) = ${f(total)}: ${total > 0 ? `the graph climbs ${f(total)} for each 1 across at that point` : total < 0 ? `the graph falls ${f(-total)} for each 1 across at that point` : "the graph is flat at that point"}.`, math: m(text("f′(1)"), op("="), A, op("+"), ...P(B), op("+"), ...P(C), op("="), total), answerStep: "at1", result: total },
    ],
  });
}

export const lesson: LessonDefinition<PolynomialDerivative> = withEasyStart({
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
});
