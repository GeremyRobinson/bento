import { formatNumber as f, m, mark, muted, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { fP, ns, P, poly, v, xp } from "../../algebra-kit/steps";
import { attempt, nz, readInts, rule } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { syntheticPicture } from "./picture";

/** (x − r)(x − s) = x² + bx + c divided by (x − r): the quotient is x − s, remainder 0. */
export interface SyntheticDivision { kind: "polynomials.synthetic"; r: number; s: number; b: number; c: number }

export function createSyntheticDivision(r: number, s: number): SyntheticDivision {
  rule(r !== 0 && s !== 0 && r !== s, "r and s not 0 and different");
  return { kind: "polynomials.synthetic", r, s, b: -(r + s), c: r * s };
}

/** Same ranges as the current app: r and s from −6 to 6, not 0, different. */
export function generateSyntheticDivision(rng: Rng): SyntheticDivision {
  let r: number, s: number;
  do { r = nz(rng, -6, 6); s = nz(rng, -6, 6); } while (r === s);
  return createSyntheticDivision(r, s);
}

export function restoreSyntheticDivision(raw: unknown): SyntheticDivision | null {
  const p = readInts(raw, ["r", "s"] as const);
  return p && attempt(() => createSyntheticDivision(p.r, p.s));
}

const dividend = ({ b, c }: SyntheticDivision) => poly([[1, xp(2)], [b, [v()]], [c, []]]);
const divisor = ({ r }: SyntheticDivision): MathText => [v(), op(r < 0 ? "+" : "−"), num(Math.abs(r))];
const problem = (p: SyntheticDivision): MathText => [text("("), ...dividend(p), text(")"), op("÷"), text("("), ...divisor(p), text(")")];

export function syntheticAnswers({ r, b, c }: SyntheticDivision): AnswerModel {
  const q = b + r;
  return {
    steps: [
      ns({ id: "mul1", l: "Multiply", a: s => [num(1), op("×"), ...P(r), op("="), ...s], ans: r, h: `Multiply the number you brought down by ${f(r)}.`, n: "Use the number from the divisor with its sign flipped." }),
      ns({ id: "add1", l: "Add", a: s => [num(b), op("+"), ...P(r), op("="), ...s], ans: q, h: "Add down the column." }),
      ns({ id: "mul2", l: "Multiply", a: s => [num(q), op("×"), ...P(r), op("="), ...s], ans: q * r, h: `${f(q)} times ${f(r)}.` }),
      ns({ id: "rem", l: "Remainder", a: s => [num(c), op("+"), ...P(q * r), op("="), ...s], ans: 0, h: "Add the last column. If it's 0, it divides evenly." }),
      ns({ id: "quot", l: "Quotient", a: s => [v(), op("+"), ...s], ans: q, h: "The bottom row is the answer: 1 and the number you got by adding.", n: "Answer: x + (the middle number)." }),
    ],
    finalParts: [-1],
  };
}

export function explainSynthetic(p: SyntheticDivision, model: AnswerModel) {
  const { r, b, c } = p;
  const [rr, q, qr, rem, quot] = model.steps.map(s => s.slots[0]!.expected!) as [number, number, number, number, number];
  const gap = text(" ");
  return beatExplanation({
    heading: "Multiply, add, repeat",
    statement: problem(p),
    caption: `${f(r)} goes in the box: the divisor's number with its sign flipped.`,
    diagram: syntheticPicture({ r, b, c, rr, q, qr, rem }),
    alt: `Synthetic division by ${f(r)}: the row 1, ${f(b)}, ${f(c)} becomes 1, ${f(quot)}, ${f(rem)}, so the answer is x ${quot < 0 ? "−" : "+"} ${f(Math.abs(quot))}, remainder ${f(rem)}.`,
    steps: [
      { id: "setup", narration: `Put ${f(r)} in the box and the numbers of the polynomial in a row: 1, ${f(b)}, ${f(c)}.`, math: [num(r), text("|"), num(1), gap, num(b), gap, num(c)] },
      { id: "mul1", narration: `Bring down the 1. Multiply it by ${f(r)}: ${f(rr)}.`, math: m(muted("bring down 1"), op("→"), 1, op("×"), ...P(r), op("="), rr), answerStep: "mul1", result: rr },
      { id: "add1", narration: `Add down the column: ${f(b)} + ${fP(r)} = ${f(q)}.`, math: m(b, op("+"), ...P(r), op("="), mark(q)), answerStep: "add1", result: q },
      { id: "mul2", narration: `Multiply ${f(q)} by ${f(r)}: ${f(qr)}.`, math: m(q, op("×"), ...P(r), op("="), qr), answerStep: "mul2", result: qr },
      { id: "rem", narration: `Add the last column: ${f(c)} + ${fP(qr)} = ${f(rem)}. It divides evenly.`, math: m(c, op("+"), ...P(qr), op("="), mark(rem)), answerStep: "rem", result: rem },
      { id: "quot", narration: `The bottom row 1, ${f(quot)} means x + ${fP(quot)}, remainder 0.`, math: [v(), op(quot < 0 ? "−" : "+"), num(Math.abs(quot)), text(", remainder "), num(rem)], answerStep: "quot", result: quot },
    ],
  });
}

export const lesson: LessonDefinition<SyntheticDivision> = {
  id: "g11-synth",
  grade: 11,
  unit: "Polynomials",
  title: "Synthetic division",
  reference: createSyntheticDivision(2, -3),
  generate: rng => generateSyntheticDivision(rng),
  restore: restoreSyntheticDivision,
  display: problem,
  displayNote: p => `Use ${f(p.r)} in the box. Bring down the 1.`,
  answers: syntheticAnswers,
  explain: explainSynthetic,
};
