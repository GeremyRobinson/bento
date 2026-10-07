// Area of a trapezoid (the current app's g6-trap): add the bases, times the height, then half.
import { formatNumber as f, num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { chainExplanation } from "../../../../explanations/diagrams/chain/build";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { trapezoidPicture } from "./picture";

/** bases a ≠ b (2–15) and height h (2–12), with a whole-number area */
export interface TrapezoidProblem { a: number; b: number; h: number }

export function createTrapezoid(a: number, b: number, h: number): TrapezoidProblem {
  wholeIn("a", a, 2, 15); wholeIn("b", b, 2, 15); wholeIn("h", h, 2, 12);
  if (a === b) throw new Error("the bases differ");
  if (((a + b) * h) % 2) throw new Error("the area is a whole number");
  return { a, b, h };
}

function answers({ a, b, h }: TrapezoidProblem): AnswerModel {
  return {
    steps: [
      oneBox({ id: "sum", label: "Add the bases", prompt: s => [num(a), op("+"), num(b), op("="), s], ans: a + b,
        hint: `The two copies lie end to end along the bottom: ${a} + ${b}.`, explain: `End to end, the bottom is ${a} + ${b} = ${a + b} long.`,
        wrong: [[a * b, "Multiplied the bases", "Put the bases end to end: add them."]] }),
      oneBox({ id: "times", label: "Times the height", prompt: s => [num(a + b), op("×"), num(h), op("="), s], ans: (a + b) * h,
        hint: `A parallelogram's area is length × height: ${a + b} × ${h}.`, explain: `The parallelogram is ${a + b} × ${h} = ${(a + b) * h}.`,
        wrong: [[a + b + h, "Added the height", "Area is length times height."]] }),
      oneBox({ id: "half", label: "Half of it", prompt: s => [num((a + b) * h), op("÷"), num(2), op("="), s], ans: ((a + b) * h) / 2,
        hint: "That area holds two trapezoids. Take half.", explain: `One trapezoid is half: ${(a + b) * h} ÷ 2 = ${((a + b) * h) / 2}.`,
        wrong: [[(a + b) * h, "Forgot to halve", "Divide by 2 at the end."]] }),
    ],
    finalParts: [-1],
  };
}

function explain(p: TrapezoidProblem, model: AnswerModel) {
  const { a, b, h } = p, S = expectedOf(model, "sum"), P = expectedOf(model, "times"), A = expectedOf(model, "half");
  return chainExplanation({
    heading: "Two copies make a parallelogram",
    idea: ["Two copies of a trapezoid make a parallelogram, so the trapezoid is half of it."],
    statement: [text("bases "), num(a), text(" and "), num(b), text(", height "), num(h)],
    caption: `Same as averaging the bases: (${a} + ${b}) ÷ 2 = ${f(S / 2)}, and ${f(S / 2)} × ${h} = ${A}.`,
    alt: `Trapezoid area: (${a} + ${b}) × ${h} ÷ 2 = ${A}.`,
    diagram: trapezoidPicture({ a, b, h, S, P, A }),
    beats: [
      { id: "sum", narration: `Lay a flipped copy next to it: along the bottom, the bases ${a} and ${b} sit end to end, ${a} + ${b} = ${S}.`, math: [num(a), op("+"), num(b), op("="), num(S)],
        lines: [[num(a), op("+"), num(b), op("="), num(S)]], answerStep: "sum", result: S },
      { id: "times", narration: `The two copies make a parallelogram ${S} long and ${h} high: ${S} × ${h} = ${P}.`, math: [num(S), op("×"), num(h), op("="), num(P)],
        lines: [[num(S), op("×"), num(h), op("="), num(P)]], answerStep: "times", result: P },
      { id: "half", narration: `That's two trapezoids, so one is half: ${P} ÷ 2 = ${A}.`, math: [num(P), op("÷"), num(2), op("="), num(A)],
        lines: [[num(P), op("÷"), num(2), op("="), num(A)]], answerStep: "half", result: A },
    ],
  });
}

export const lesson: LessonDefinition<TrapezoidProblem> = {
  id: "g6-trap",
  grade: 6,
  unit: "Geometry",
  title: "Area of a trapezoid",
  pre: "g6-tri",
  reference: createTrapezoid(4, 8, 5), // bases 4 and 8, height 5, the current app's example
  generate: rng => {
    let a: number, b: number, h: number;
    do { a = rng.int(2, 15); b = rng.int(2, 15); h = rng.int(2, 12); } while (a === b || ((a + b) * h) % 2);
    return createTrapezoid(a, b, h);
  },
  restore: raw => restoreVia(raw, ["a", "b", "h"] as const, v => createTrapezoid(v.a, v.b, v.h)),
  display: p => [text("bases "), num(p.a), text(" and "), num(p.b), text(", height "), num(p.h)],
  displayNote: () => "Area = (base + base) × height ÷ 2",
  answers,
  explain,
};
