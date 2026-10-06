import { br, formatNumber as f, m, mark, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { fP, ns, P, v } from "../../algebra-kit/steps";
import { attempt, readInts } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";

/** x + y = sum and x − y = difference, solved by adding the equations. */
export interface EliminationSystem { kind: "system.elimination"; x: number; y: number; sum: number; difference: number }

export const createElimination = (x: number, y: number): EliminationSystem => ({ kind: "system.elimination", x, y, sum: x + y, difference: x - y });

/** Same ranges as the current app: x and y from −6 to 12. */
export const generateElimination = (rng: Rng) => { const x = rng.int(-6, 12), y = rng.int(-6, 12); return createElimination(x, y); };

export function restoreElimination(raw: unknown): EliminationSystem | null {
  const r = readInts(raw, ["x", "y"] as const);
  return r && attempt(() => createElimination(r.x, r.y));
}

const first = (s: number, y: MathText = [v("y")]): MathText => [v(), op("+"), ...y, op("="), num(s)];
const second = (d: number, y: MathText = [v("y")]): MathText => [v(), op("−"), ...y, op("="), num(d)];
/** The two equations, one after the other (the current app put a line break between them). */
const system = (p: EliminationSystem): MathText => [...first(p.sum), br(), ...second(p.difference)];

export function eliminationAnswers({ x, y, sum, difference }: EliminationSystem): AnswerModel {
  return {
    steps: [
      ns({ id: "add", l: "Add the equations", n: "The y's cancel.", a: s => [num(2), v(), op("="), ...s], ans: 2 * x, h: `${f(sum)} + ${fP(difference)}.` }),
      ns({ id: "x", l: "Solve for x", a: s => [v(), op("="), ...s], ans: x, h: `${f(2 * x)} ÷ 2.` }),
      ns({ id: "y", l: "Find y", a: s => [num(x), op("+"), v("y"), op("="), num(sum), text(", "), v("y"), op("="), ...s], ans: y, h: `${f(sum)} − ${fP(x)}.` }),
    ],
    finalParts: [-2, -1],
  };
}

export function explainElimination(p: EliminationSystem, model: AnswerModel) {
  const { sum, difference } = p;
  const [twoX, x, y] = model.steps.map(s => s.slots[0]!.expected!) as [number, number, number];
  return beatExplanation({
    heading: "Add to cancel a variable",
    idea: ["Adding equal amounts to both sides keeps an equation true, and the second equation's two sides are equal amounts. So you can add one whole equation to the other.", "Add when a variable has opposite signs, like + y and − y: it cancels and leaves one variable to solve."],
    statement: system(p),
    caption: "Add the equations: +y and −y cancel.",
    alt: `x + y = ${f(sum)} and x − y = ${f(difference)}. Adding them gives 2x = ${f(twoX)}, so x = ${f(x)}; then y = ${f(y)}.`,
    steps: [
      { id: "first", narration: `The first equation has + y.`, math: first(sum, [mark("y")]) },
      { id: "second", narration: `The second has − y. Added together, + y and − y make 0.`, math: second(difference, [mark("y")]) },
      { id: "add", narration: `Add the equations: x + x = 2x and ${f(sum)} + ${fP(difference)} = ${f(twoX)}.`, math: m(2, v(), op("="), sum, op("+"), ...P(difference), op("="), twoX), answerStep: "add", result: twoX },
      { id: "x", narration: `Divide by 2: x = ${f(x)}.`, math: m(v(), op("="), twoX, op("÷"), 2, op("="), x), answerStep: "x", result: x },
      { id: "y", narration: `Put x = ${f(x)} back into x + y = ${f(sum)}: y = ${f(sum)} − ${fP(x)} = ${f(y)}.`, math: m(x, op("+"), v("y"), op("="), sum, text(", so "), v("y"), op("="), y), answerStep: "y", result: y },
    ],
  });
}

export const lesson: LessonDefinition<EliminationSystem> = {
  id: "g9-elim",
  grade: 9,
  unit: "Equations",
  title: "Systems by elimination",
  reference: createElimination(7, 3),
  generate: rng => generateElimination(rng),
  restore: restoreElimination,
  display: system,
  answers: eliminationAnswers,
  explain: explainElimination,
};
