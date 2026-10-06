// Exponents and order (the current app's g6-expo): aⁿ + b × c, exponent first, then multiply, then add.
import { mark, num, op, sup, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { chainExplanation } from "../../../../explanations/diagrams/chain/build";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { exponentOrderPicture } from "./picture";

export interface ExponentOrderProblem { a: number; n: number; b: number; c: number }

export function createExponentOrder(a: number, n: number, b: number, c: number): ExponentOrderProblem {
  wholeIn("a", a, 2, 5); wholeIn("n", n, 2, 3); wholeIn("b", b, 2, 9); wholeIn("c", c, 2, 9);
  return { a, n, b, c };
}

const SUP = "⁰¹²³⁴⁵⁶⁷⁸⁹";
/** "4²", for messages */
const power = (a: number, n: number) => `${a}${SUP[n]}`;
const pow = (a: number, n: number): MathText => [num(a), sup(n)];

function answers({ a, n, b, c }: ExponentOrderProblem): AnswerModel {
  const times = Array(n).fill(a).join(" × ");
  return {
    steps: [
      oneBox({ id: "exp", label: "Exponent first", prompt: s => [...pow(a, n), op("="), s], ans: a ** n, hint: `${power(a, n)} means ${times}.`,
        wrong: [[a * n, "Multiplied the base by the exponent", `${power(a, n)} means ${times}, not ${a} × ${n}.`]] }),
      oneBox({ id: "mul", label: "Multiply", prompt: s => [num(b), op("×"), num(c), op("="), s], ans: b * c, hint: "Multiply before adding." }),
      oneBox({ id: "add", label: "Add", prompt: s => [num(a ** n), op("+"), num(b * c), op("="), s], ans: a ** n + b * c, hint: "Add last." }),
    ],
    finalParts: [-1],
  };
}

function explain(p: ExponentOrderProblem, model: AnswerModel) {
  const { a, n, b, c } = p, E = expectedOf(model, "exp"), M = expectedOf(model, "mul"), S = expectedOf(model, "add");
  return chainExplanation({
    heading: "Exponents come before × and +",
    idea: ["Work out exponents first. Then multiply. Add last."],
    statement: [...pow(a, n), op("+"), num(b), op("×"), num(c)],
    alt: `${power(a, n)} + ${b} × ${c}: ${E} + ${M} = ${S}.`,
    diagram: exponentOrderPicture({ a, n, b, c, E, M, S }),
    beats: [
      { id: "exp", narration: `Exponent first: ${power(a, n)} = ${Array(n).fill(a).join(" × ")} = ${E}.`, math: [...pow(a, n), op("="), num(E)],
        lines: [[mark(pow(a, n)), op("+"), num(b), op("×"), num(c)]], answerStep: "exp", result: E },
      { id: "mul", narration: `Then multiply: ${b} × ${c} = ${M}.`, math: [num(b), op("×"), num(c), op("="), num(M)],
        lines: [[num(E), op("+"), mark([num(b), op("×"), num(c)])]], answerStep: "mul", result: M },
      { id: "add", narration: `Add last: ${E} + ${M} = ${S}.`, math: [num(E), op("+"), num(M), op("="), num(S)],
        lines: [[num(E), op("+"), num(M), op("="), num(S)]], answerStep: "add", result: S },
    ],
  });
}

export const lesson: LessonDefinition<ExponentOrderProblem> = {
  id: "g6-expo",
  grade: 6,
  unit: "Expressions and equations",
  title: "Exponents and order",
  reference: createExponentOrder(2, 3, 4, 3), // 2³ + 4 × 3 = 20, the current app's example
  generate: rng => createExponentOrder(rng.int(2, 5), rng.int(2, 3), rng.int(2, 9), rng.int(2, 9)),
  restore: raw => restoreVia(raw, ["a", "n", "b", "c"] as const, v => createExponentOrder(v.a, v.n, v.b, v.c)),
  display: p => [...pow(p.a, p.n), op("+"), num(p.b), op("×"), num(p.c)],
  answers,
  explain,
};
