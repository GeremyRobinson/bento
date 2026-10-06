import { formatNumber as f, m, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { ns, v } from "../../algebra-kit/steps";
import { attempt, readInts, rule } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { block, buildBalance, xTiles } from "../../../../explanations/diagrams/algebra/balance";
import { count } from "../../../text";
import { withEasyStart } from "../../easy-start";

/** a(x + b) = a·(x + b). */
export interface MultiStepEquation { kind: "equation.multiStep"; a: number; b: number; x: number; c: number }

export function createMultiStep(a: number, b: number, x: number): MultiStepEquation {
  rule(a >= 2 && b >= 1 && x >= 1, "a ≥ 2, b ≥ 1, x ≥ 1");
  return { kind: "equation.multiStep", a, b, x, c: a * (x + b) };
}

/** Same ranges as the current app: a 2–9, b 1–9, x 1–12. */
export const generateMultiStep = (rng: Rng) => { const a = rng.int(2, 9), b = rng.int(1, 9), x = rng.int(1, 12); return createMultiStep(a, b, x); };

export function restoreMultiStep(raw: unknown): MultiStepEquation | null {
  const r = readInts(raw, ["a", "b", "x"] as const);
  return r && attempt(() => createMultiStep(r.a, r.b, r.x));
}

const equation = ({ a, b, c }: MultiStepEquation): MathText => [num(a), text("("), v(), op("+"), num(b), text(")"), op("="), num(c)];

export function multiStepAnswers({ a, b, x, c }: MultiStepEquation): AnswerModel {
  return {
    steps: [
      ns({ id: "distribute", l: "Distribute", a: s => [num(a), v(), op("+"), ...s, op("="), num(c)], ans: a * b, h: `Multiply ${f(a)} by ${f(b)} too.`,
        w: [[b, "Only multiplied the first term", `Multiply ${f(a)} by **both** x and ${f(b)}.`]] }),
      ns({ id: "subtract", l: "Subtract", a: s => [num(a), v(), op("="), ...s], ans: a * x, h: `To undo + ${f(a * b)}, take ${f(a * b)} off both sides: ${f(c)} − ${f(a * b)}.`,
        w: [[c + a * b, "Added instead of subtracted", `To undo + ${f(a * b)}, subtract ${f(a * b)} from both sides.`], [c - b, "Took off the number before distributing", `After distributing, the number is ${f(a)} × ${f(b)} = ${f(a * b)}. Take that off.`]] }),
      ns({ id: "divide", l: "Divide", a: s => [v(), op("="), ...s], ans: x, h: `${f(a)}x means ${f(a)} groups of x. Split both sides into ${f(a)} equal groups.`,
        w: [[a * x - a, "Subtracted instead of divided", `${f(a)}x is ${f(a)} times x, so divide by ${f(a)}.`]] }),
    ],
    finalParts: [-1],
  };
}

export function explainMultiStep(p: MultiStepEquation, model: AnswerModel) {
  const { a, b, c } = p;
  const [ab, ax, x] = model.steps.map(s => s.slots[0]!.expected!) as [number, number, number];
  const diagram = buildBalance([
    { left: Array.from({ length: a }, () => [...xTiles(1), block(b)]), right: [[block(c)]], note: `${f(a)}(x + ${f(b)}) = ${f(c)}` },
    { left: [xTiles(a), [block(ab)]], right: [[block(c)]], note: `${f(a)}(x + ${f(b)}) → ${f(a)}x + ${f(ab)} = ${f(c)}` },
    { left: [xTiles(a), [block(ab, { off: true })]], right: [[block(ax)], [block(ab, { off: true })]], note: `take ${f(ab)} off both` },
    { left: xTiles(a).map(t => [t]), right: Array.from({ length: a }, () => [block(x)]), note: `split into ${f(a)}: x = ${f(x)}` },
  ], `A balance with ${count(f(a), "group")} of x and ${f(b)} against ${f(c)}. That is ${f(a)} x's and ${f(ab)}; taking ${f(ab)} off both pans and splitting into ${f(a)} shows x = ${f(x)}.`);
  return beatExplanation({
    heading: "Distribute, then undo",
    idea: ["A number outside parentheses multiplies everything inside, so multiply it out first.", "Then undo the adding and the multiplying, doing the same thing to both sides so the balance stays level."],
    statement: equation(p),
    diagram,
    alt: diagram.alt,
    steps: [
      { id: "equation", narration: `${count(f(a), "group")} of x + ${f(b)} balance ${f(c)}.`, math: equation(p) },
      { id: "distribute", narration: `Distribute: ${f(a)} × x and ${f(a)} × ${f(b)} = ${f(ab)}, so ${f(a)}x + ${f(ab)} = ${f(c)}.`, math: m(a, v(), op("+"), ab, op("="), c), answerStep: "distribute", result: ab },
      { id: "subtract", narration: `Subtract ${f(ab)} from both sides: ${f(a)}x = ${f(ax)}.`, math: m(a, v(), op("="), c, op("−"), ab, op("="), ax), answerStep: "subtract", result: ax },
      { id: "divide", narration: `Divide by ${f(a)}: x = ${f(x)}.`, math: m(v(), op("="), ax, op("÷"), a, op("="), x), answerStep: "divide", result: x },
    ],
  });
}

export const lesson: LessonDefinition<MultiStepEquation> = withEasyStart({
  id: "g9-multistep",
  grade: 9,
  unit: "Equations",
  title: "Multi-step equations",
  pre: "g8-both",
  reference: createMultiStep(3, 4, 5),
  generate: rng => generateMultiStep(rng),
  restore: restoreMultiStep,
  display: equation,
  answers: multiStepAnswers,
  explain: explainMultiStep,
});
