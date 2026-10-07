// Count to 20: count a full row of ten, then keep counting the second row.
import { answer, num, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { countStrip } from "../../../../explanations/diagrams/early-k/counting";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { TEN, countUp, slips, words } from "../kit";
import { count } from "../../../text";

/** n dots, 11 to 20: a row of ten and a shorter row */
export interface CountProblem { n: number }

export function createCount(n: number): CountProblem {
  wholeIn("n", n, TEN + 1, 2 * TEN);
  return { n };
}

function answers({ n }: CountProblem): AnswerModel {
  const rest = n - TEN;
  return {
    steps: [
      oneBox({
        id: "row", label: "Count the top row", question: "How many dots are in the top row?",
        prompt: s => [text("Top row: "), s], ans: TEN,
        wrong: slips(TEN, [
          [TEN - 1, "Skipped a dot", "You missed one dot. Touch each dot as you say its number."],
          [TEN + 1, "Counted a dot twice", "You counted one dot two times. Touch each dot only once."],
          [rest, "Counted the wrong row", "That's the bottom row. Count the dots in the **top** row."],
        ]),
        hint: "Touch each dot in the top row and count out loud.",
        explain: `${countUp(1, TEN)}. The top row has ${count(TEN, "dot")}.`,
      }),
      oneBox({
        id: "count-on", label: "Keep counting", question: `Start at ${TEN}. Keep counting the bottom row.`,
        prompt: s => [text("All the dots: "), s], ans: n,
        wrong: slips(n, [
          [rest, "Started over", `That's just the bottom row. Don't start again at 1. Say ${TEN}, then keep going: ${TEN + 1}, ${TEN + 2}...`],
          [n - 1, "Skipped a dot", "One short. Make sure you count every dot in the bottom row."],
          [n + 1, "Counted a dot twice", `One too many. The first dot in the bottom row is ${TEN + 1}.`],
          [10 * rest + 1, "Mixed up the digits", `Close! You have the right digits, but write ${n} with the 1 first.`],
        ]),
        hint: `Say ${TEN}. Then count on, one number for each dot in the bottom row.`,
        explain: `${TEN}, then ${countUp(TEN + 1, n)}. There are ${count(n, "dot")}.`,
        work: [text("All the dots: "), answer("x", n)],
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: CountProblem, model: AnswerModel): Explanation {
  const { n } = p, row = expectedOf(model, "row"), all = expectedOf(model, "count-on");
  return {
    heading: "Count on from 10",
    idea: ["After one full row of ten, you can keep counting on from 10."],
    statement: words("How many dots?"),
    diagram: countStrip(n, `${count(row, "dot")} in the top row and ${n - row} in the bottom row, counted 1 to ${all}.`, { firstBeat: 0, restBeat: 1 }),
    caption: `${row} and ${n - row} more make ${all}.`,
    timeline: beats(2),
    steps: [
      { id: "row", narration: `Count the top row: ${countUp(1, row)}. That's **${row}**.`, math: [text("Top row: "), num(row)], state: 0, answerStep: "row", result: row },
      { id: "count-on", narration: `Keep going from ${row}: ${countUp(row + 1, all)}. There are **${all}** dots.`, math: [text("All the dots: "), num(all)], state: 1, answerStep: "count-on", result: all },
    ],
  };
}

export const lesson: LessonDefinition<CountProblem> = {
  id: "k-count20",
  grade: 0,
  unit: "Counting",
  title: "Count to 20",
  reference: createCount(14),
  generate: (rng, index) => createCount(rng.int(TEN + 1, index < 3 ? TEN + 5 : 2 * TEN)),
  restore: raw => restoreVia(raw, ["n"] as const, v => createCount(v.n)),
  display: () => words("How many dots?"),
  picture: p => countStrip(p.n, `A full row of ${count(TEN, "dot")}, and more dots in the row below to count.`),
  answers,
  explain,
};
