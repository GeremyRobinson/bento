import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildMedianBars } from "../../../../explanations/diagrams/bars/build";
import { asRecord, expected, listOf, mt, ns } from "../../_geometry/kit";
import { withEasyStart } from "../../easy-start";

/** An odd-length list of whole numbers. */
export interface MedianProblem {
  kind: "data.median";
  v: number[];
}

export function createMedian(v: number[]): MedianProblem {
  if (v.length % 2 === 0 || !v.every(x => Number.isFinite(x))) throw new Error("an odd number of numbers");
  return { kind: "data.median", v: [...v] };
}

export function restoreMedian(raw: unknown): MedianProblem | null {
  const r = asRecord(raw);
  if (!r || !Array.isArray(r.v) || !r.v.every(x => typeof x === "number")) return null;
  try { return createMedian(r.v as number[]); } catch { return null; }
}

const sorted = (v: number[]) => [...v].sort((a, b) => a - b);

export function medianAnswers({ v }: MedianProblem): AnswerModel {
  const s2 = sorted(v), mid = (v.length + 1) / 2;
  return {
    steps: [
      ns({ id: "count", label: "Count them", question: "How many numbers are there?", prompt: s => [s], ans: v.length, hint: "Count every number in the list, repeats too.", wrong: [[new Set(v).size === v.length ? v.length - 1 : new Set(v).size, "Missed one", "Count every number, including any that repeat."]] }),
      ns({ id: "spot", label: "Middle spot", prompt: s => mt`(${v.length} + 1) ÷ 2 = ${s}`, ans: mid, hint: "The middle spot has as many numbers before it as after it.", wrong: [[v.length / 2, "Forgot the + 1", `Add 1 before halving: (${v.length} + 1) ÷ 2.`]] }),
      ns({ id: "median", label: "Median", question: `Put them in order: ${s2.join(", ")}. What's in spot ${mid}?`, prompt: s => mt`median = ${s}`, ans: s2[mid - 1]!,
        hint: "Count to the middle spot of the sorted list.",
        wrong: v[mid - 1] !== s2[mid - 1] ? [[v[mid - 1]!, "Didn't sort first", "Put the numbers in order from least to greatest first."]] : [] }),
    ],
    finalParts: [-1],
  };
}

export function explainMedian({ v }: MedianProblem, answers: AnswerModel): Explanation {
  const n = expected(answers, "count"), mid = expected(answers, "spot"), med = expected(answers, "median");
  const s2 = sorted(v);
  return {
    heading: "Sort, then take the middle",
    idea: ["The median is the middle number once the list is in order."],
    statement: listOf(v),
    caption: `Sorted: ${s2.join(", ")}. The middle one is ${med}.`,
    diagram: buildMedianBars({
      values: v, countBeat: 1, sortBeat: 2, medianBeat: 3,
      countNote: `${n} numbers`, spotNote: `in order: the middle spot is ${mid}`, medianNote: `middle spot ${mid}: median = ${med}`,
      alt: `Bars of heights ${v.join(", ")} slide into order: ${s2.join(", ")}. The middle one, in spot ${mid}, is ${med}.`,
    }),
    timeline: beats(4),
    steps: [
      { id: "bars", narration: `Each number is a bar: ${v.join(", ")}.`, math: listOf(v), state: 0 },
      { id: "count", narration: `There are ${n} numbers.`, math: mt`${n}`, state: 1, answerStep: "count", result: n },
      { id: "spot", narration: `Put them in order. With ${n} numbers the middle spot is (${n} + 1) ÷ 2 = ${mid}.`, math: mt`(${n} + 1) ÷ 2 = ${mid}`, state: 2, answerStep: "spot", result: mid },
      { id: "median", narration: `Spot ${mid} of ${s2.join(", ")} holds ${med}. That's the median.`, math: mt`median = ${med}`, state: 3, answerStep: "median", result: med },
    ],
  };
}

export const lesson: LessonDefinition<MedianProblem> = withEasyStart({
  id: "g9-median",
  grade: 9,
  unit: "Data",
  title: "Find the median",
  reference: createMedian([7, 2, 9, 4, 5]),
  generate: rng => { const n = rng.pick([5, 7]); return createMedian(Array.from({ length: n }, () => rng.int(1, 30))); },
  restore: restoreMedian,
  display: p => listOf(p.v),
  displayNote: () => "Find the median.",
  answers: medianAnswers,
  explain: explainMedian,
});
