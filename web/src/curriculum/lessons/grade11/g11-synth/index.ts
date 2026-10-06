import { formatNumber as f, m, mark, muted, num, op, sup, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { fP, ms, ns, P, poly, v, xp } from "../../algebra-kit/steps";
import { attempt, nz, readInts, rule } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { withEasyStart } from "../../easy-start";

/**
 * (x − r)(x − s) + e = x² + bx + c divided by (x − r): the quotient is x − s and the remainder is e.
 * Problems saved before the remainder existed have e = 0.
 */
export interface SyntheticDivision { kind: "polynomials.synthetic"; r: number; s: number; e: number; b: number; c: number }

export function createSyntheticDivision(r: number, s: number, e = 0): SyntheticDivision {
  rule(r !== 0 && s !== 0 && r !== s, "r and s not 0 and different");
  return { kind: "polynomials.synthetic", r, s, e, b: -(r + s), c: r * s + e };
}

/**
 * r and s from −6 to 6, not 0, different; the first three problems keep both within 3.
 * Every third problem has a remainder from −5 to 5 (not 0), so the last column means something.
 */
export function generateSyntheticDivision(rng: Rng, index = 0): SyntheticDivision {
  const lim = index < 3 ? 3 : 6;
  let r: number, s: number;
  do { r = nz(rng, -lim, lim); s = nz(rng, -lim, lim); } while (r === s);
  return createSyntheticDivision(r, s, index % 3 === 2 ? nz(rng, -5, 5) : 0);
}

export function restoreSyntheticDivision(raw: unknown): SyntheticDivision | null {
  const p = readInts(raw, ["r", "s"] as const);
  const e = readInts(raw, ["e"] as const)?.e ?? 0;
  return p && attempt(() => createSyntheticDivision(p.r, p.s, e));
}

const dividend = ({ b, c }: SyntheticDivision) => poly([[1, xp(2)], [b, [v()]], [c, []]]);
const divisor = ({ r }: SyntheticDivision): MathText => [v(), op(r < 0 ? "+" : "−"), num(Math.abs(r))];
const problem = (p: SyntheticDivision): MathText => [text("("), ...dividend(p), text(")"), op("÷"), text("("), ...divisor(p), text(")")];

const SUBTRACTED = "Add down each column. The flipped sign in the box already does the subtracting.";

export function syntheticAnswers({ r, b, c, e }: SyntheticDivision): AnswerModel {
  const q = b + r, sign = r < 0 ? "+" : "−";
  const quotHint = "The bottom row is the answer's numbers: the 1 goes with x, and the number you got by adding is the number on its own.";
  return {
    steps: [
      ns({ id: "mul1", l: "Multiply", a: s => [num(1), op("×"), ...P(r), op("="), ...s], ans: r, h: `Multiply the number you brought down by ${f(r)}.`, n: "Use the number from the divisor with its sign flipped.",
        w: [[-r, "Kept the divisor's sign", `x ${sign} ${f(Math.abs(r))} is 0 when x = ${f(r)}, so the box holds ${f(r)}.`]] }),
      ns({ id: "add1", l: "Add", a: s => [num(b), op("+"), ...P(r), op("="), ...s], ans: q, h: "Add down the column.", w: [[b - r, "Subtracted the column", SUBTRACTED]] }),
      ns({ id: "mul2", l: "Multiply", a: s => [num(q), op("×"), ...P(r), op("="), ...s], ans: q * r, h: `Multiply the new bottom number by the box number, ${f(r)}, and write it under the next column.`,
        w: [[-q * r, "Kept the divisor's sign", `The box holds ${f(r)}, so multiply by ${f(r)}.`]] }),
      ns({ id: "rem", l: "Remainder", a: s => [num(c), op("+"), ...P(q * r), op("="), ...s], ans: e, h: "Add the last column. If it's 0, it divides evenly.", w: [[c - q * r, "Subtracted the column", SUBTRACTED]] }),
      e === 0
        ? ns({ id: "quot", l: "Quotient", a: s => [v(), op("+"), ...s], ans: q, h: quotHint, n: "Answer: x + (the middle number).", w: [[b - r, "Subtracted the column", SUBTRACTED]] })
        : ms({ id: "quot", l: "Quotient", a: S => [v(), op("+"), ...S.q!, text(", remainder "), ...S.e!], ans: { q, e }, h: `${quotHint} The last number is the remainder.`,
          n: "Answer: x + (the middle number), remainder (the last number).", w: [[{ q: b - r, e }, "Subtracted the column", SUBTRACTED], [{ q: e, e: q }, "Swapped them", "The middle number goes after x +, and the last number is the remainder."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainSynthetic(p: SyntheticDivision, model: AnswerModel) {
  const { r, b, c } = p;
  const [rr, q, qr, rem] = model.steps.map(s => s.slots[0]!.expected!) as [number, number, number, number];
  const quot = q;
  const gap = text(" ");
  const fr = (x: number) => x * x + b * x + c;
  return beatExplanation({
    heading: "Multiply, add, repeat",
    idea: [
      "Synthetic division is long division with only the numbers kept. The box holds r, the number that makes x − r equal 0, so each subtraction becomes an addition.",
      "The last number is the remainder. It equals the polynomial's value at r, so a remainder of 0 means x − r is a factor.",
    ],
    statement: problem(p),
    caption: `${f(r)} makes x ${r < 0 ? "+" : "−"} ${f(Math.abs(r))} equal 0, so ${f(r)} goes in the box.`,
    alt: `Synthetic division by ${f(r)}: the row 1, ${f(b)}, ${f(c)} becomes 1, ${f(quot)}, ${f(rem)}, so the answer is x ${quot < 0 ? "−" : "+"} ${f(Math.abs(quot))}, remainder ${f(rem)}.`,
    steps: [
      { id: "setup", narration: `Put ${f(r)} in the box and the numbers of the polynomial in a row: 1, ${f(b)}, ${f(c)}.`, math: [num(r), text("|"), num(1), gap, num(b), gap, num(c)] },
      { id: "mul1", narration: `Bring down the 1. Multiply it by ${f(r)}: ${f(rr)}.`, math: m(muted("bring down 1"), op("→"), 1, op("×"), ...P(r), op("="), rr), answerStep: "mul1", result: rr },
      { id: "add1", narration: `Add down the column: ${f(b)} + ${fP(r)} = ${f(q)}.`, math: m(b, op("+"), ...P(r), op("="), mark(q)), answerStep: "add1", result: q },
      { id: "mul2", narration: `Multiply ${f(q)} by ${f(r)}: ${f(qr)}.`, math: m(q, op("×"), ...P(r), op("="), qr), answerStep: "mul2", result: qr },
      { id: "rem", narration: `Add the last column: ${f(c)} + ${fP(qr)} = ${f(rem)}. ${rem === 0 ? "It divides evenly." : `${f(rem)} is left over: the remainder.`}`, math: m(c, op("+"), ...P(qr), op("="), mark(rem)), answerStep: "rem", result: rem },
      { id: "check", narration: `Check: put ${f(r)} into the polynomial and you get ${f(fr(r))}, the same as the remainder.`, math: m(...P(r), sup(2), op("+"), ...P(b), op("·"), ...P(r), op("+"), ...P(c), op("="), fr(r)) },
      { id: "quot", narration: `The bottom row 1, ${f(quot)} means x + ${fP(quot)}, remainder ${f(rem)}.`, math: [v(), op(quot < 0 ? "−" : "+"), num(Math.abs(quot)), text(", remainder "), num(rem)], answerStep: "quot", result: quot },
    ],
  });
}

export const lesson: LessonDefinition<SyntheticDivision> = withEasyStart({
  id: "g11-synth",
  grade: 11,
  unit: "Polynomials",
  title: "Synthetic division",
  reference: createSyntheticDivision(2, -3),
  generate: (rng, i) => generateSyntheticDivision(rng, i),
  restore: restoreSyntheticDivision,
  display: problem,
  displayNote: p => `Use ${f(p.r)} in the box. Bring down the 1.`,
  answers: syntheticAnswers,
  explain: explainSynthetic,
});
