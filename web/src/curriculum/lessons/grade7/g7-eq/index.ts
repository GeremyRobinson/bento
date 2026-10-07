import { answer, formatNumber as f, m, num, op, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { numStep, v } from "../../algebra-kit/steps";
import { attempt, readInts, rule } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { block, buildBalance, xTiles } from "../../../../explanations/diagrams/algebra/balance";
import { count } from "../../../text";

/** ax + b = c, with c = a·x + b. */
export interface TwoStepEquation { kind: "equation.twoStep"; a: number; b: number; c: number; x: number }

export function createTwoStep(a: number, b: number, x: number): TwoStepEquation {
  rule(a >= 2 && b >= 1 && x >= 1, "a ≥ 2, b ≥ 1, x ≥ 1");
  return { kind: "equation.twoStep", a, b, c: a * x + b, x };
}

/** Same ranges as the current app: x 2–12, a 2–9, b 1–20. */
export const generateTwoStep = (rng: Rng) => { const x = rng.int(2, 12), a = rng.int(2, 9), b = rng.int(1, 20); return createTwoStep(a, b, x); };

export function restoreTwoStep(raw: unknown): TwoStepEquation | null {
  const r = readInts(raw, ["a", "b", "c", "x"] as const);
  return r && r.c === r.a * r.x + r.b ? attempt(() => createTwoStep(r.a, r.b, r.x)) : null;
}

const lhs = (a: number): MathText => [num(a), v()];

export function twoStepAnswers({ a, b, c, x }: TwoStepEquation): AnswerModel {
  return {
    steps: [
      numStep({ id: "undo-add", l: `Undo the + ${f(b)}`, a: s => [...lhs(a), op("="), ...s], n: `Subtract ${f(b)} from both sides.`, ans: c - b,
        w: [[c + b, "Undid with the wrong operation", `To undo + ${f(b)}, **subtract** ${f(b)} from both sides.`]],
        h: `${f(c)} − ${f(b)}.`, explain: `${f(c)} − ${f(b)} = ${f(c - b)}.`, work: m(...lhs(a), op("="), c, op("−"), b, op("="), c - b) }),
      numStep({ id: "undo-mul", l: `Undo the × ${f(a)}`, a: s => [v(), op("="), ...s], n: `Divide both sides by ${f(a)}.`, ans: x,
        w: [[c - b - a, "Undid with the wrong operation", `${f(a)}x means ${f(a)} **times** x. Undo times by dividing.`], [(c - b) * a, "Undid with the wrong operation", `Undo times by **dividing** by ${f(a)}.`]],
        h: `${f(c - b)} ÷ ${f(a)}.`, explain: `${f(c - b)} ÷ ${f(a)} = ${f(x)}.`, work: m(v(), op("="), c - b, op("÷"), a, op("="), answer("x", x)) }),
    ],
    finalParts: [-1],
  };
}

export function explainTwoStep(p: TwoStepEquation, model: AnswerModel) {
  const { a, b, c, x } = p;
  const [undoAdd, undoMul] = model.steps.map(s => s.slots[0]!.expected!) as [number, number];
  const diagram = buildBalance([
    { left: [xTiles(a), [block(b)]], right: [[block(c)]], note: `${f(a)}x + ${f(b)} = ${f(c)}` },
    { left: [xTiles(a), [block(b, { off: true })]], right: [[block(c - b)], [block(b, { off: true })]], note: `take ${f(b)} off both sides` },
    { left: xTiles(a).map(t => [t]), right: Array.from({ length: a }, () => [block(x)]), note: `split both sides into ${f(a)}` },
    { left: [xTiles(1)], right: [[block(x)]], note: `x = ${f(x)}` },
  ], `A balance with ${f(a)} x tiles and ${f(b)} on one pan and ${f(c)} on the other. Taking ${f(b)} off both pans leaves ${f(a)} x's against ${f(c - b)}; splitting both into ${count(f(a), "group")} shows x = ${f(x)}.`);
  return beatExplanation({
    heading: "Undo in reverse order",
    idea: ["x had two things done to it, so they come undone in reverse order."],
    statement: [...lhs(a), op("+"), num(b), op("="), num(c)],
    caption: `Undo the + ${f(b)} first, then the × ${f(a)}.`,
    diagram,
    alt: diagram.alt,
    steps: [
      { id: "balance", narration: `The pans balance: ${f(a)} x's and ${f(b)} on one side, ${f(c)} on the other.`, math: [...lhs(a), op("+"), num(b), op("="), num(c)] },
      { id: "undo-add", narration: `Undo the + ${f(b)} first by subtracting ${f(b)} from both sides: ${f(a)}x = ${f(undoAdd)}.`, math: m(...lhs(a), op("="), c, op("−"), b, op("="), undoAdd), answerStep: "undo-add", result: undoAdd },
      { id: "undo-mul", narration: `Then undo the × ${f(a)} by dividing both sides by ${f(a)}: x = ${f(undoMul)}.`, math: m(v(), op("="), c - b, op("÷"), a, op("="), undoMul), answerStep: "undo-mul", result: undoMul },
      { id: "check", narration: `Check: ${f(a)} × ${f(x)} + ${f(b)} = ${f(c)}, so the pans still balance.`, math: m(a, op("×"), x, op("+"), b, op("="), c) },
    ],
  });
}

export const lesson: LessonDefinition<TwoStepEquation> = {
  id: "g7-eq",
  grade: 7,
  unit: "Expressions and equations",
  title: "Two-step equations",
  pre: "g6-onestep",
  reference: createTwoStep(3, 5, 5),
  generate: rng => generateTwoStep(rng),
  restore: restoreTwoStep,
  display: p => [...lhs(p.a), op("+"), num(p.b), op("="), num(p.c)],
  answers: twoStepAnswers,
  explain: explainTwoStep,
};

