import { formatNumber as f, m, mark, num, op, sqrt, sup, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { fpm, ns, pm, v } from "../../algebra-kit/steps";
import { attempt, nz, readInts, rule } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { radicalEquationPicture } from "./picture";
import { withEasyStart } from "../../easy-start";

/** √(x + a) = b, so x = b² − a. */
export interface RadicalEquation { kind: "equation.radical"; a: number; b: number; x: number }

export function createRadicalEquation(a: number, b: number): RadicalEquation {
  rule(a !== 0 && b >= 1, "a ≠ 0 and b ≥ 1");
  return { kind: "equation.radical", a, b, x: b * b - a };
}

/** Same ranges as the current app: a from −9 to 9 (not 0), b from 2 to 9. */
export const generateRadicalEquation = (rng: Rng) => { const a = nz(rng, -9, 9), b = rng.int(2, 9); return createRadicalEquation(a, b); };

export function restoreRadicalEquation(raw: unknown): RadicalEquation | null {
  const r = readInts(raw, ["a", "b"] as const);
  return r && attempt(() => createRadicalEquation(r.a, r.b));
}

const inside = (a: number): MathText => [v(), ...pm(a)];
const root = (a: number): MathText => [sqrt([text("("), ...inside(a), text(")")])];

export function radicalAnswers({ a, b }: RadicalEquation): AnswerModel {
  return {
    steps: [
      ns({ id: "square", l: "Square both sides", a: s => [...inside(a), op("="), num(b), sup(2), op("="), ...s], ans: b * b, h: `Squaring undoes the square root: ${f(b)} × ${f(b)}.`,
        w: [[2 * b, "Doubled instead", "Squared means times itself."]] }),
      ns({ id: "solve", l: "Solve", a: s => [v(), op("="), ...s], ans: b * b - a, h: `Do the same to both sides: undo the ${fpm(a)} by ${a > 0 ? "subtracting" : "adding"} ${f(Math.abs(a))}.`, w: [[b * b + a, "Wrong direction", `x ${fpm(a)} = ${f(b * b)}: to undo ${fpm(a)}, ${a > 0 ? "subtract" : "add"} ${f(Math.abs(a))}.`]] }),
    ],
    finalParts: [-1],
  };
}

export function explainRadical(p: RadicalEquation, model: AnswerModel) {
  const { a, b } = p;
  const [sq, x] = model.steps.map(s => s.slots[0]!.expected!) as [number, number];
  return beatExplanation({
    heading: "Square to undo the root",
    idea: ["Squaring undoes a square root, and doing the same thing to both sides keeps them equal.", "Squaring can sneak in an answer that doesn't work, so put your answer back into the root to check it."],
    statement: [...root(a), op("="), num(b)],
    caption: `Squaring both sides keeps them equal and removes the root.`,
    diagram: radicalEquationPicture({ a, b, sq, x }),
    alt: `√(x ${fpm(a)}) = ${f(b)}. Squaring gives x ${fpm(a)} = ${f(sq)}, so x = ${f(x)}.`,
    steps: [
      { id: "problem", narration: `x is stuck under a square root.`, math: [...root(a), op("="), num(b)] },
      { id: "both", narration: `Square both sides. Squaring undoes the square root.`, math: [mark("("), ...root(a), mark(")"), sup(2), op("="), num(b), sup([mark(2)])] },
      { id: "square", narration: `${f(b)} × ${f(b)} = ${f(sq)}, so x ${fpm(a)} = ${f(sq)}.`, math: [...inside(a), op("="), num(sq)], answerStep: "square", result: sq },
      { id: "solve", narration: `Undo the ${fpm(a)}: x = ${f(x)}.`, math: m(v(), op("="), sq, op(a < 0 ? "+" : "−"), Math.abs(a), op("="), x), answerStep: "solve", result: x },
      { id: "check", narration: `Check: √(${f(x)} ${fpm(a)}) = √${f(sq)} = ${f(b)}. ✓`, math: m(sqrt([text("("), num(x), ...pm(a), text(")")]), op("="), sqrt(sq), op("="), b) },
    ],
  });
}

export const lesson: LessonDefinition<RadicalEquation> = withEasyStart({
  id: "g11-radical",
  grade: 11,
  unit: "Functions",
  title: "Radical equations",
  reference: createRadicalEquation(3, 5),
  generate: rng => generateRadicalEquation(rng),
  restore: restoreRadicalEquation,
  display: p => [...root(p.a), op("="), num(p.b)],
  displayNote: () => "Solve for x.",
  answers: radicalAnswers,
  explain: explainRadical,
});
