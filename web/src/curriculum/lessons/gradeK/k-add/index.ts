// Adding within 10 by counting on (the current app's K_ADD).
import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildNumberLine, type Hop } from "../../../../explanations/diagrams/number-line/build";
import { dotGroups } from "../../../../explanations/diagrams/number-line/counters";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { count, isAre, noun } from "../../../text";
import { slips } from "../kit";

/** a dots and b more; the sum stays within 10 */
export interface CountOnProblem { a: number; b: number }

export function createCountOn(a: number, b: number): CountOnProblem {
  wholeIn("a", a, 1, 5);
  wholeIn("b", b, 1, 5);
  if (a + b > 10) throw new Error("the sum must stay within 10");
  return { a, b };
}

function answers({ a, b }: CountOnProblem): AnswerModel {
  return {
    steps: [
      oneBox({
        id: "first", label: "Count the first group", question: "How many dots are in the first group?",
        prompt: s => [s], ans: a,
        wrong: slips(a, [
          [b, "Counted the wrong group", "That's the second group. Count the dots **before** the + sign."],
          [a + b, "Counted both groups", `That's all the dots. Count only the first group, the dots **before** the + sign.`],
          [a + 1, "Counted a dot twice", `One too many. Touch each dot in the first group once.`],
          [a - 1, "Skipped a dot", `One short. Touch every dot in the first group, even the last one.`],
        ]),
        hint: "Touch each dot in the first group and count out loud.",
        explain: `There ${isAre(a)} ${count(a, "dot")} in the first group.`,
        work: [text("First group: "), { t: "answer", id: "x", v: a }],
      }),
      oneBox({
        id: "count-on", label: "Count on", question: `Start at ${a}. Count on ${b} more.`,
        prompt: s => [num(a), op("+"), num(b), op("="), s], ans: a + b,
        wrong: [
          [a + b + 1, "Counting on", `One too many. Start after ${a}: say ${a + 1} for the first dot.`],
          [a + b - 1, "Counting on", "One short. Count every dot in the second group once."],
        ],
        hint: `Say ${a}, then count up one number for each dot in the second group.`,
        explain: `${a}, then ${Array.from({ length: b }, (_, i) => a + i + 1).join(", ")}.`,
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: CountOnProblem, model: AnswerModel): Explanation {
  const { a, b } = p, first = expectedOf(model, "first"), sum = expectedOf(model, "count-on");
  const counted = Array.from({ length: b }, (_, i) => a + i + 1);
  // the first group counted from 0, then one more hop for every dot of the second group; every hop arcs
  // above the line (below would mean taking away), so counting reads as one run from 0 to the sum
  const hops: Hop[] = [
    ...Array.from({ length: a }, (_, i): Hop => ({ from: i, to: i + 1, label: String(i + 1), beat: 0, delay: 0.25 * i, start: i === 0, land: i === a - 1 })),
    ...counted.map((v, i): Hop => ({ from: v - 1, to: v, label: String(v), beat: 1, delay: 0.45 * i, start: false })),
  ];
  return {
    heading: "Count on",
    idea: ["Adding puts two groups together, so you can keep counting from the first group."],
    statement: [num(a), op("+"), num(b)],
    diagram: buildNumberLine({ min: 0, max: 10, hops, alt: `Number line from 0 to 10: count ${a}, then hop on ${b} more to ${sum}.` }),
    caption: `Start at ${a} and count on ${b}: ${sum}.`,
    timeline: beats(2),
    steps: [
      { id: "first", narration: `Count the first group: **${first}** ${noun(first, "dot")}. That brings you to ${first}.`, math: [text("First group: "), num(first)], state: 0, answerStep: "first", result: first },
      { id: "count-on", narration: `Count on ${b} more, one hop for each dot: ${counted.join(", ")}.`, math: [num(a), op("+"), num(b), op("="), num(sum)], state: 1, answerStep: "count-on", result: sum },
    ],
  };
}

export const lesson: LessonDefinition<CountOnProblem> = {
  id: "k-add",
  grade: 0,
  unit: "Adding and subtracting",
  title: "Adding within 10",
  reference: createCountOn(3, 4), // the current app's picture: start at 3, count on 4
  // the first three problems are small: a total of 5 or less
  generate: (rng, index) => { const a = index < 3 ? rng.int(1, 3) : rng.int(1, 5); return createCountOn(a, rng.int(1, index < 3 ? 2 : Math.min(5, 10 - a))); },
  restore: raw => restoreVia(raw, ["a", "b"] as const, v => createCountOn(v.a, v.b)),
  display: p => [num(p.a), op("+"), num(p.b)],
  picture: p => dotGroups([p.a, p.b], `${count(p.a, "dot")} plus ${count(p.b, "dot")}`),
  answers,
  explain,
};
