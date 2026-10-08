// Distance on a number line (the current app's g6-numline): from a negative to a positive, add the steps on each side of 0.
import { formatNumber as f, num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildNumberLine, fitRange } from "../../../../explanations/diagrams/number-line/build";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { count } from "../../../text";

/** from a (−12 to −1) to b (1 to 12) */
export interface DistanceProblem { a: number; b: number }

export function createDistance(a: number, b: number): DistanceProblem {
  wholeIn("a", a, -12, -1);
  wholeIn("b", b, 1, 12);
  return { a, b };
}

const abs = (x: number) => [text("|"), num(x), text("|")];

function answers({ a, b }: DistanceProblem): AnswerModel {
  return {
    steps: [
      oneBox({ id: "neg", label: "From the negative to 0", prompt: s => [...abs(a), op("="), s], ans: -a, hint: "Count the steps from the left dot to 0.",
        wrong: [[a, "Distance is never negative", "Distance counts steps, so it's always positive."]] }),
      oneBox({ id: "pos", label: "From 0 to the positive", prompt: s => [...abs(b), op("="), s], ans: b, hint: "Count the steps from 0 to the right dot.",
        wrong: [[b + 1, "Counted the marks, not the steps", "Count the jumps between marks, starting after 0."]] }),
      oneBox({ id: "sum", label: "Add the distances", prompt: s => [num(-a), op("+"), num(b), op("="), s], ans: b - a, hint: "You cross 0, so add the two distances.",
        wrong: [[b + a, "Subtracted the distances", "Going from a negative to a positive crosses 0, so add."]] }),
    ],
    finalParts: [-1],
  };
}

function explain(p: DistanceProblem, model: AnswerModel): Explanation {
  const { a, b } = p, left = expectedOf(model, "neg"), right = expectedOf(model, "pos"), total = expectedOf(model, "sum");
  return {
    heading: "Cross zero, add the distances",
    idea: ["Distance counts steps, so it is never negative."],
    statement: [num(a), text(" to "), num(b)],
    diagram: buildNumberLine({
      ...fitRange([a, b], { maxTicks: 26, pad: 1, minStep: 1 }), labelAt: [a, 0, b],
      marks: [{ v: b, beat: 0, cls: "hole" }],
      hops: [{ from: a, to: 0, label: String(left), beat: 0 }, { from: 0, to: b, label: String(right), beat: 1, start: false }],
      spans: [{ from: a, to: b, beat: 2, label: `${left} + ${right} = ${total} apart` }],
      alt: `Number line: from ${f(a)} to 0 is ${count(left, "step")}, from 0 to ${b} is ${count(right, "step")}, ${total} in all.`,
    }),
    caption: `${left} + ${right} = ${total} apart.`,
    timeline: beats(3),
    steps: [
      { id: "neg", narration: `From ${f(a)} to 0 is ${left} ${left === 1 ? "step" : "steps"}.`, math: [...abs(a), op("="), num(left)], state: 0, answerStep: "neg", result: left },
      { id: "pos", narration: `From 0 to ${b} is ${right} ${right === 1 ? "step" : "steps"}.`, math: [...abs(b), op("="), num(right)], state: 1, answerStep: "pos", result: right },
      { id: "sum", narration: `You cross 0, so add the two distances: ${left} + ${right} = ${total}.`, math: [num(left), op("+"), num(right), op("="), num(total)], state: 2, answerStep: "sum", result: total },
    ],
  };
}

export const lesson: LessonDefinition<DistanceProblem> = {
  id: "g6-numline",
  grade: 6,
  unit: "Number system",
  title: "Distance on a number line",
  reference: createDistance(-3, 5), // −3 to 5 is 8 apart, the current app's example
  // the first three stay within 5 of 0
  generate: (rng, index) => (index < 3 ? createDistance(-rng.int(1, 5), rng.int(1, 5)) : createDistance(-rng.int(1, 12), rng.int(1, 12))),
  restore: raw => restoreVia(raw, ["a", "b"] as const, v => createDistance(v.a, v.b)),
  display: p => [num(p.a), text(" to "), num(p.b)],
  displayNote: () => "How far apart are they on the number line?",
  answers,
  explain,
};
