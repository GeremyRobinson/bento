import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildMeanBars } from "../../../../explanations/diagrams/bars/build";
import { asRecord, expected, listOf, mt, ns } from "../../_geometry/kit";

/** A list of whole numbers whose mean is a whole number. */
export interface MeanProblem {
  kind: "data.mean";
  v: number[];
}

export function createMean(v: number[]): MeanProblem {
  if (v.length < 2 || !v.every(x => Number.isInteger(x) && x > 0)) throw new Error("at least two positive whole numbers");
  return { kind: "data.mean", v: [...v] };
}

export function restoreMean(raw: unknown): MeanProblem | null {
  const r = asRecord(raw);
  if (!r || !Array.isArray(r.v) || !r.v.every(x => typeof x === "number")) return null;
  try { return createMean(r.v as number[]); } catch { return null; }
}

const total = (v: number[]) => v.reduce((x, y) => x + y, 0);

export function meanAnswers({ v }: MeanProblem): AnswerModel {
  const T = total(v);
  return {
    steps: [
      ns({ id: "sum", label: "Add them up", prompt: s => mt`${listOf(v, "+")} = ${s}`, ans: T, hint: "Add all the numbers.",
        wrong: [[T - v[v.length - 1]!, "Left one out", "Add every number in the list, the last one too."]] }),
      ns({ id: "count", label: "Count them", question: "How many numbers are there?", prompt: s => [s], ans: v.length, hint: "Count the numbers in the list.",
        wrong: [[T, "Wrote the total", "Count how many numbers there are, not what they add up to."], [v.length - 1, "Missed one", "Count every number in the list."]] }),
      ns({ id: "divide", label: "Divide", prompt: s => mt`${T} ÷ ${v.length} = ${s}`, ans: T / v.length, hint: "Share the total equally.",
        wrong: [[T * v.length, "Multiplied", "Sharing out equally is dividing."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainMean({ v }: MeanProblem, answers: AnswerModel): Explanation {
  const T = expected(answers, "sum"), n = expected(answers, "count"), mean = expected(answers, "divide");
  return {
    heading: "Share it out equally",
    idea: ["The mean is what each would get if the total were shared out equally."],
    statement: mt`(${listOf(v, "+")}) ÷ ${n}`,
    caption: `${T} shared equally by ${n}: ${mean} each.`,
    diagram: buildMeanBars({
      values: v, mean, sumBeat: 1, countBeat: 2, shareBeat: 3,
      sumNote: `${v.join(" + ")} = ${T}`, countNote: `${T} in all, ${n} numbers`, shareNote: `share it out: ${T} ÷ ${n} = ${mean} each`,
      alt: `Bars of heights ${v.join(", ")} level out to ${mean} each.`,
    }),
    timeline: beats(4),
    steps: [
      { id: "bars", narration: `Each number is a bar: ${v.join(", ")}.`, math: listOf(v), state: 0 },
      { id: "sum", narration: `Put them all together: ${v.join(" + ")} = ${T}.`, math: mt`${listOf(v, "+")} = ${T}`, state: 1, answerStep: "sum", result: T },
      { id: "count", narration: `There are ${n} numbers to share it between.`, math: mt`${n}`, state: 2, answerStep: "count", result: n },
      { id: "divide", narration: `Share ${T} out equally: ${T} ÷ ${n} = ${mean}. Every bar ends up the same height.`, math: mt`${T} ÷ ${n} = ${mean}`, state: 3, answerStep: "divide", result: mean },
    ],
  };
}

export const lesson: LessonDefinition<MeanProblem> = {
  id: "g6-mean",
  grade: 6,
  unit: "Statistics",
  title: "Find the mean",
  reference: createMean([4, 6, 8]),
  generate: rng => {
    const n = rng.int(4, 6);
    let v: number[];
    do v = Array.from({ length: n }, () => rng.int(1, 20));
    while (total(v) % n);
    return createMean(v);
  },
  restore: restoreMean,
  display: p => listOf(p.v),
  displayNote: () => "Find the mean (average).",
  answers: meanAnswers,
  explain: explainMean,
};
