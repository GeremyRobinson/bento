import { formatNumber as f, m, mark, num, op, text, toPlainText, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition, RichText } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { fP, ns, P, poly, v, xp, type Slip } from "../../algebra-kit/steps";
import { attempt, nz, readInts, rule } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { coef, term } from "../../../text";
import { polynomialSumPicture } from "./picture";
import { withEasyStart } from "../../easy-start";

/** (ax² + bx + c) ± (dx² + ex + f). */
export interface PolynomialSum { kind: "polynomials.addSubtract"; a: number; b: number; c: number; d: number; e: number; f: number; sub: boolean }

export function createPolynomialSum(a: number, b: number, c: number, d: number, e: number, f: number, sub: boolean): PolynomialSum {
  rule([a, b, c, d, e, f].every(Number.isInteger), "whole coefficients");
  return { kind: "polynomials.addSubtract", a, b, c, d, e, f, sub };
}

/** Same ranges as the current app: every coefficient from −9 to 9 but not 0; plus or minus, half and half. */
export function generatePolynomialSum(rng: Rng): PolynomialSum {
  const [a, b, c, d, e, g] = Array.from({ length: 6 }, () => nz(rng, -9, 9)) as [number, number, number, number, number, number];
  return createPolynomialSum(a, b, c, d, e, g, rng.next() < 0.5);
}

export function restorePolynomialSum(raw: unknown): PolynomialSum | null {
  const r = readInts(raw, ["a", "b", "c", "d", "e", "f"] as const);
  const sub = raw && typeof raw === "object" ? (raw as Record<string, unknown>).sub : undefined;
  return r && typeof sub === "boolean" ? attempt(() => createPolynomialSum(r.a, r.b, r.c, r.d, r.e, r.f, sub)) : null;
}

const X2 = xp(2);
const X1: MathText = [v()];
const quad = (p: number, q: number, r: number) => poly([[p, X2], [q, X1], [r, []]]);
const sign = (p: PolynomialSum) => (p.sub ? "−" : "+") as "−" | "+";
const problem = (p: PolynomialSum, marks = false): MathText => {
  const first = marks ? [mark(poly([[p.a, X2]])), ...poly([[1, []], [p.b, X1], [p.c, []]]).slice(1)] : quad(p.a, p.b, p.c);
  const second = marks ? [mark(poly([[p.d, X2]])), ...poly([[1, []], [p.e, X1], [p.f, []]]).slice(1)] : quad(p.d, p.e, p.f);
  return [text("("), ...first, text(")"), op(sign(p)), text("("), ...second, text(")")];
};

export function polynomialSumAnswers(p: PolynomialSum): AnswerModel {
  const k = p.sub ? -1 : 1, o = sign(p), how = p.sub ? "Take the second away from the first." : "Add them.";
  const W = (x: number, y: number): Slip[] => [[x - k * y, p.sub ? "Forgot to subtract" : "Subtracted instead of added", p.sub ? `The minus reaches every term in the second polynomial, including this one: ${f(x)} − ${fP(y)}.` : `Both polynomials are added, so add their numbers: ${f(x)} + ${fP(y)}.`]];
  const combine = (id: string, l: string, x: number, y: number, h: RichText) =>
    ns({ id, l, a: s => [num(x), op(o), ...P(y), op("="), ...s], ans: x + k * y, h, w: W(x, y) });
  return {
    steps: [
      combine("x2", "x² terms", p.a, p.d, `Find the x² term in each polynomial. ${how} Only x² goes with x².`),
      combine("x1", "x terms", p.b, p.e, `Find the x term in each polynomial. ${how}`),
      combine("x0", "Numbers", p.c, p.f, `Find the number on its own in each polynomial. ${how}`),
    ],
    finalParts: [-3, -2, -1],
  };
}

export function explainPolynomialSum(p: PolynomialSum, model: AnswerModel) {
  const o = sign(p);
  const [A, B, C] = model.steps.map(s => s.slots[0]!.expected!) as [number, number, number];
  const pending = (x: number, y: number, vp: MathText): MathText => [text("("), num(x), op(o), ...P(y), text(")"), ...vp];
  const word = p.sub ? "minus" : "plus";
  return beatExplanation({
    heading: "Combine like terms",
    idea: ["Only like terms combine, the same way 3 apples and 5 apples make 8 apples."],
    statement: problem(p),
    caption: `Only like terms combine: x² with x², x with x, numbers with numbers.`,
    diagram: polynomialSumPicture({ ...p, A, B, C, answer: toPlainText(quad(A, B, C)) }),
    alt: `${coef(p.a, "x²")} ${o} ${term(p.d, "x²")} = ${coef(A, "x²")}, ${coef(p.b, "x")} ${o} ${term(p.e, "x")} = ${coef(B, "x")}, ${f(p.c)} ${o} ${fP(p.f)} = ${f(C)}.`,
    steps: [
      { id: "problem", narration: `Two polynomials, ${word}. Line up the matching kinds: x² under x², x under x, numbers under numbers.`, math: problem(p, true) },
      { id: "x2", narration: `x² terms: ${f(p.a)} ${o} ${fP(p.d)} = ${f(A)}.`, math: m(p.a, op(o), ...P(p.d), op("="), A),
        line: [...(A ? poly([[A, X2]]) : [num(0)]), op("+"), ...pending(p.b, p.e, X1), op("+"), ...pending(p.c, p.f, [])], answerStep: "x2", result: A },
      { id: "x1", narration: `x terms: ${f(p.b)} ${o} ${fP(p.e)} = ${f(B)}.`, math: m(p.b, op(o), ...P(p.e), op("="), B),
        line: [...(A || B ? poly([[A, X2], [B, X1]]) : [num(0)]), op("+"), ...pending(p.c, p.f, [])], answerStep: "x1", result: B },
      { id: "x0", narration: `Numbers: ${f(p.c)} ${o} ${fP(p.f)} = ${f(C)}. So the answer is ${toPlainText(quad(A, B, C))}.`, math: m(p.c, op(o), ...P(p.f), op("="), C),
        line: quad(A, B, C), answerStep: "x0", result: C },
    ],
  });
}

export const lesson: LessonDefinition<PolynomialSum> = withEasyStart({
  id: "g9-polyadd",
  grade: 9,
  unit: "Polynomials and quadratics",
  title: "Add and subtract polynomials",
  reference: createPolynomialSum(2, 3, -1, 1, -5, 4, false),
  generate: rng => generatePolynomialSum(rng),
  restore: restorePolynomialSum,
  display: p => problem(p),
  answers: polynomialSumAnswers,
  explain: explainPolynomialSum,
});
