import { formatNumber as f, m, mark, num, op, sup, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { ns, supText } from "../../algebra-kit/steps";
import { attempt, readInts, rule } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { rationalExponentPicture } from "./picture";
import { withEasyStart } from "../../easy-start";

/** (rⁿ) to the m/n: the n-th root is r, then r to the m. */
export interface RationalExponent { kind: "exponents.rational"; n: 2 | 3; r: number; m: number; base: number }

export function createRationalExponent(n: number, r: number, m: number): RationalExponent {
  rule((n === 2 || n === 3) && r >= 2 && m >= 1 && m !== n, "square or cube root, r ≥ 2, top 1 or more and not the bottom");
  return { kind: "exponents.rational", n: n as 2 | 3, r, m, base: r ** n };
}

/** Same ranges as the current app: square roots of 4–81 or cube roots of 8–125, tops 1–4. */
export function generateRationalExponent(rng: Rng): RationalExponent {
  const n = rng.pick([2, 3]), r = n === 2 ? rng.int(2, 9) : rng.int(2, 5), m = rng.int(1, 3);
  return createRationalExponent(n, r, m === n ? m + 1 : m);
}

export function restoreRationalExponent(raw: unknown): RationalExponent | null {
  const p = readInts(raw, ["n", "r", "m"] as const);
  return p && attempt(() => createRationalExponent(p.n, p.r, p.m));
}

const rootSign = (n: number) => (n === 2 ? "√" : "∛");
const exponent = (top: number, bottom: number): MathText => [num(top), text("/"), num(bottom)];

export function rationalAnswers({ n, r, m: top, base }: RationalExponent): AnswerModel {
  return {
    steps: [
      ns({ id: "root", l: "Take the root", a: s => [text(rootSign(n)), num(base), op("="), ...s], ans: r, h: `The bottom of the fraction picks the root: here it is the ${n === 2 ? "square" : "cube"} root.`,
        w: [[base / n, "Divided by the bottom", `A power of 1/${f(n)} is a root, not dividing by ${f(n)}.`]] }),
      ns({ id: "power", l: "Raise to the top", a: s => [num(r), sup(top), op("="), ...s], ans: r ** top, h: "The top of the fraction is the power: multiply the root by itself that many times.", w: [[r * top, "Multiplied by the top", `The top is a power: ${f(r)} times itself, not ${f(r)} × ${f(top)}.`]] }),
    ],
    finalParts: [-1],
  };
}

export function explainRational(p: RationalExponent, model: AnswerModel) {
  const { n, m: top, base } = p;
  const [r, value] = model.steps.map(s => s.slots[0]!.expected!) as [number, number];
  const root = n === 2 ? "square" : "cube";
  return beatExplanation({
    heading: "Bottom is the root, top is the power",
    idea: ["Taking a root twice of the same size undoes squaring, so a power of 1/2 has to be the square root: (a to the 1/2) × (a to the 1/2) = a to the 1.", "A fraction power m/n splits into two moves: the bottom n takes the root, and the top m raises to a power. Root first keeps the numbers small."],
    statement: [num(base), sup(exponent(top, n))],
    caption: `${rootSign(n)}${f(base)} = ${f(r)}, then ${f(r)}${supText(top)} = ${f(value)}.`,
    diagram: rationalExponentPicture({ n, m: top, r, base, value }),
    alt: `${f(base)} to the ${f(top)}/${f(n)} is the ${root} root of ${f(base)}, ${f(r)}, to the power ${f(top)}: ${f(value)}.`,
    steps: [
      { id: "problem", narration: `The exponent is a fraction: the bottom ${f(n)} is a ${root} root, the top ${f(top)} is a power.`, math: [num(base), sup([mark(exponent(top, n))])] },
      { id: "root", narration: `Take the ${root} root first: ${rootSign(n)}${f(base)} = ${f(r)}, because ${Array.from({ length: n }, () => f(r)).join(" × ")} = ${f(base)}.`,
        math: m(rootSign(n), base, op("="), r), line: [text("("), mark([text(rootSign(n)), num(base)]), text(")"), sup(top)], answerStep: "root", result: r },
      { id: "power", narration: `Then raise it to the top ${f(top)}: ${f(r)}${supText(top)} = ${f(value)}.`, math: m(r, sup(top), op("="), value), answerStep: "power", result: value },
    ],
  });
}

export const lesson: LessonDefinition<RationalExponent> = withEasyStart({
  id: "g11-ratexp",
  grade: 11,
  unit: "Exponents and logs",
  title: "Rational exponents",
  pre: "g8-roots",
  reference: createRationalExponent(3, 2, 2),
  generate: rng => generateRationalExponent(rng),
  restore: restoreRationalExponent,
  display: p => [num(p.base), sup(exponent(p.m, p.n))],
  answers: rationalAnswers,
  explain: explainRational,
});
