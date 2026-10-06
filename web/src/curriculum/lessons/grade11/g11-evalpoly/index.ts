import { formatNumber as f, m, mark, num, op, sup, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { fP, ns, P, poly, v, xp } from "../../algebra-kit/steps";
import { attempt, nz, readInts } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { evaluatePolynomialPicture } from "./picture";

/** f(x) = ax² + bx + c, evaluated at x = k. */
export interface EvaluatePolynomial { kind: "polynomials.evaluate"; a: number; b: number; c: number; k: number }

export const createEvaluatePolynomial = (a: number, b: number, c: number, k: number): EvaluatePolynomial => ({ kind: "polynomials.evaluate", a, b, c, k });

/** Same ranges as the current app: a and k from −4 to 4, b from −9 to 9 (none of them 0), c from −9 to 9. */
export function generateEvaluatePolynomial(rng: Rng): EvaluatePolynomial {
  const a = nz(rng, -4, 4), b = nz(rng, -9, 9), c = rng.int(-9, 9), k = nz(rng, -4, 4);
  return createEvaluatePolynomial(a, b, c, k);
}

export function restoreEvaluatePolynomial(raw: unknown): EvaluatePolynomial | null {
  const r = readInts(raw, ["a", "b", "c", "k"] as const);
  return r && attempt(() => createEvaluatePolynomial(r.a, r.b, r.c, r.k));
}

const fx = (p: EvaluatePolynomial): MathText => [text("f(x)"), op("="), ...poly([[p.a, xp(2)], [p.b, [v()]], [p.c, []]])];
const at = (k: number): MathText => [text("f("), num(k), text(")")];

export function evaluateAnswers({ a, b, c, k }: EvaluatePolynomial): AnswerModel {
  return {
    steps: [
      ns({ id: "square", l: "Square term", a: s => [num(a), op("·"), ...P(k), sup(2), op("="), ...s], ans: a * k * k, h: `Square ${f(k)} first (${f(k * k)}), then multiply by ${f(a)}.`,
        w: [[-a * k * k, "Sign of the square", "A negative squared is positive."], [a * 2 * k, "Doubled instead of squared", "Squared means times itself."]] }),
      ns({ id: "linear", l: "x term", a: s => [num(b), op("·"), ...P(k), op("="), ...s], ans: b * k, h: "Watch the signs." }),
      ns({ id: "total", l: "Add it up", a: s => [num(a * k * k), op("+"), ...P(b * k), op("+"), ...P(c), op("="), ...s], ans: a * k * k + b * k + c, h: "Add the three parts." }),
    ],
    finalParts: [-1],
  };
}

export function explainEvaluate(p: EvaluatePolynomial, model: AnswerModel) {
  const { a, b, c, k } = p;
  const [A, B, total] = model.steps.map(s => s.slots[0]!.expected!) as [number, number, number];
  const K = () => [text("("), mark(k), text(")")];
  // the polynomial with (k) in place of every x
  const plugged: MathText = [
    ...(a === 1 ? [] : a === -1 ? [text("−")] : [num(a)]), ...K(), sup(2),
    op(b < 0 ? "−" : "+"), ...(Math.abs(b) === 1 ? [] : [num(Math.abs(b))]), ...K(),
    ...(c ? [op(c < 0 ? "−" : "+"), num(Math.abs(c))] : []),
  ];
  return beatExplanation({
    heading: "Plug in, then simplify",
    statement: [...fx(p), text(",  "), ...at(k)],
    caption: `Put ${f(k)} in for every x, then work out each part.`,
    diagram: evaluatePolynomialPicture({ a, b, c, k, A, B, total }),
    alt: `f(${f(k)}) = ${f(A)} + ${fP(B)} + ${fP(c)} = ${f(total)}.`,
    steps: [
      { id: "plug", narration: `Put ${f(k)} in place of every x.`, math: [...at(k), op("="), ...plugged] },
      { id: "square", narration: `Square ${f(k)} first: ${f(k * k)}. Times ${f(a)} makes ${f(A)}.`, math: m(a, op("·"), ...P(k), sup(2), op("="), A),
        line: [num(A), op(b < 0 ? "−" : "+"), ...(Math.abs(b) === 1 ? [] : [num(Math.abs(b))]), ...K(), ...(c ? [op(c < 0 ? "−" : "+"), num(Math.abs(c))] : [])], answerStep: "square", result: A },
      { id: "linear", narration: `${f(b)} times ${f(k)} is ${f(B)}. Watch the signs.`, math: m(b, op("·"), ...P(k), op("="), B),
        line: m(A, op("+"), ...P(B), op("+"), ...P(c)), answerStep: "linear", result: B },
      { id: "total", narration: `Add the three parts: f(${f(k)}) = ${f(total)}.`, math: m(...at(k), op("="), total), answerStep: "total", result: total },
    ],
  });
}

export const lesson: LessonDefinition<EvaluatePolynomial> = {
  id: "g11-evalpoly",
  grade: 11,
  unit: "Polynomials",
  title: "Evaluate a polynomial",
  reference: createEvaluatePolynomial(2, -3, 1, -2),
  generate: rng => generateEvaluatePolynomial(rng),
  restore: restoreEvaluatePolynomial,
  display: fx,
  displayNote: p => `Find f(${f(p.k)}).`,
  answers: evaluateAnswers,
  explain: explainEvaluate,
};
