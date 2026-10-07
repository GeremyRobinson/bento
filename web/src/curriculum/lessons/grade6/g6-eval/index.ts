// Evaluate expressions (the current app's g6-eval): swap the numbers in for x and y, multiply, then add.
import { mark, num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { chainExplanation } from "../../../../explanations/diagrams/chain/build";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { evaluatePicture } from "./picture";

/** ax + by when x and y are given */
export interface EvaluateProblem { a: number; b: number; x: number; y: number }

export function createEvaluate(a: number, b: number, x: number, y: number): EvaluateProblem {
  wholeIn("a", a, 2, 9); wholeIn("b", b, 2, 9); wholeIn("x", x, 1, 9); wholeIn("y", y, 1, 9);
  return { a, b, x, y };
}

const X = text("x"), Y = text("y");

function answers({ a, b, x, y }: EvaluateProblem): AnswerModel {
  return {
    steps: [
      oneBox({ id: "ax", label: `Find ${a}x`, prompt: s => [num(a), op("×"), num(x), op("="), s], ans: a * x, hint: `${a}x means ${a} times x.`,
        wrong: [[Number(`${a}${x}`), "Wrote the numbers side by side", `${a}x means ${a} × ${x}.`], [a + x, "Added instead of multiplied", `${a}x means ${a} × ${x}.`]] }),
      oneBox({ id: "by", label: `Find ${b}y`, prompt: s => [num(b), op("×"), num(y), op("="), s], ans: b * y, hint: `${b}y means ${b} times y.`,
        wrong: [[Number(`${b}${y}`), "Wrote the numbers side by side", `${b}y means ${b} × ${y}.`]] }),
      oneBox({ id: "add", label: "Add", prompt: s => [num(a * x), op("+"), num(b * y), op("="), s], ans: a * x + b * y, hint: "The + sign between the two parts means add them.",
        wrong: [[a * x * b * y, "Multiplied the parts", `The sign between ${a * x} and ${b * y} is +, so add.`]] }),
    ],
    finalParts: [-1],
  };
}

function explain(p: EvaluateProblem, model: AnswerModel) {
  const { a, b, x, y } = p, AX = expectedOf(model, "ax"), BY = expectedOf(model, "by"), S = expectedOf(model, "add");
  return chainExplanation({
    heading: "Swap in the numbers",
    idea: ["A letter stands for a number, so the number can take its place."],
    statement: [num(a), X, op("+"), num(b), Y, text(", "), X, op("="), num(x), text(", "), Y, op("="), num(y)],
    alt: `${a}x + ${b}y with x = ${x} and y = ${y}: ${AX} + ${BY} = ${S}.`,
    diagram: evaluatePicture({ a, b, x, y, AX, BY, S }),
    beats: [
      { id: "ax", narration: `Swap in x = ${x}: ${a}x means ${a} × ${x} = ${AX}.`, math: [num(a), op("×"), num(x), op("="), num(AX)],
        lines: [[num(a), mark([X]), op("+"), num(b), mark([Y])], [mark([num(a), op("×"), num(x)]), op("+"), num(b), op("×"), num(y)]], answerStep: "ax", result: AX },
      { id: "by", narration: `Swap in y = ${y}: ${b}y means ${b} × ${y} = ${BY}.`, math: [num(b), op("×"), num(y), op("="), num(BY)],
        lines: [[num(AX), op("+"), mark([num(b), op("×"), num(y)])]], answerStep: "by", result: BY },
      { id: "add", narration: `Add the two parts: ${AX} + ${BY} = ${S}.`, math: [num(AX), op("+"), num(BY), op("="), num(S)],
        lines: [[num(AX), op("+"), num(BY), op("="), num(S)]], answerStep: "add", result: S },
    ],
  });
}

export const lesson: LessonDefinition<EvaluateProblem> = {
  id: "g6-eval",
  grade: 6,
  unit: "Expressions and equations",
  title: "Evaluate expressions",
  reference: createEvaluate(3, 2, 4, 5), // 3x + 2y with x = 4, y = 5, the current app's example
  // the first three: small numbers all round
  generate: (rng, index) => { const t = index < 3 ? 5 : 9; return createEvaluate(rng.int(2, t), rng.int(2, t), rng.int(1, t), rng.int(1, t)); },
  restore: raw => restoreVia(raw, ["a", "b", "x", "y"] as const, v => createEvaluate(v.a, v.b, v.x, v.y)),
  display: p => [num(p.a), X, op("+"), num(p.b), Y],
  displayNote: p => `when x = ${p.x} and y = ${p.y}`,
  answers,
  explain,
};
