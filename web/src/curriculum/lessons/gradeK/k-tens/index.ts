// Count by tens to 100: count the rows of ten, then say 10, 20, 30... one ten for each row.
import { answer, num, text, type MathText, type MathToken } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { tensRows } from "../../../../explanations/diagrams/early-k/counting";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { TEN, slips, words } from "../kit";
import { count } from "../../../text";

/** rows full rows of ten dots, 2 to 10 */
export interface TensProblem { rows: number }

export function createTens(rows: number): TensProblem {
  wholeIn("rows", rows, 2, TEN);
  return { rows };
}

/** "10, 20, 30, " up to the ten before the last, then the last one as given */
const tensUpTo = (rows: number, last: MathToken): MathText => [
  ...Array.from({ length: rows - 1 }, (_, i) => [num((i + 1) * TEN), text(", ")]).flat(),
  last,
];

function answers({ rows }: TensProblem): AnswerModel {
  const total = rows * TEN;
  return {
    steps: [
      oneBox({
        id: "rows", label: "Count the rows", question: `How many rows of ${TEN} are there?`,
        prompt: s => [text("Rows: "), s], ans: rows,
        wrong: slips(rows, [
          [total, "Counted the dots", "That's how many dots there are. First count just the **rows**."],
          [TEN, "Counted one row's dots", `Each row has ${count(TEN, "dot")}. Count the rows from top to bottom.`],
          [rows - 1, "Missed a row", "You missed a row. Put your finger on each row as you count."],
          [rows + 1, "Counted a row twice", "One too many. Count each row only once."],
        ]),
        hint: "Touch each row, top to bottom, and count.",
        explain: `There are ${count(rows, "row")}.`,
      }),
      oneBox({
        id: "tens", label: "Count by tens", question: `Say ${TEN} for the first row, then keep counting by tens.`,
        prompt: s => tensUpTo(rows, s), ans: total,
        wrong: slips(total, [
          [rows, "Counted by ones", `That's the number of rows. Each row is ${TEN}, so count ${TEN}, ${2 * TEN}, ${3 * TEN}...`],
          [total - TEN, "Missed a row", `One ten short. Say one ten for **every** row, ${count(rows, "ten")} in all.`],
          [total + TEN, "Counted a row twice", `One ten too many. There are only ${count(rows, "row")}.`],
          [total - TEN + 1, "Counted by ones at the end", `Count by tens all the way. After ${total - TEN} comes ${total}.`],
        ]),
        hint: `Point at each row and say ${TEN}, ${2 * TEN}, ${3 * TEN}...`,
        explain: `${Array.from({ length: rows }, (_, i) => (i + 1) * TEN).join(", ")}. That's ${total}.`,
        work: tensUpTo(rows, answer("x", total)),
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: TensProblem, model: AnswerModel): Explanation {
  const rows = expectedOf(model, "rows"), total = expectedOf(model, "tens");
  const said = Array.from({ length: rows }, (_, i) => (i + 1) * TEN);
  return {
    heading: "Count by tens",
    idea: ["Every row has 10, so each row is one ten."],
    statement: words("How many dots?"),
    diagram: tensRows(p.rows, `${count(rows, "row")} of ${count(TEN, "dot")}, counted by tens: ${said.join(", ")}.`, { rowBeat: 0, tensBeat: 1 }),
    caption: `${count(rows, "row")} of ${TEN} make ${total}.`,
    timeline: beats(2),
    steps: [
      { id: "rows", narration: `Count the rows: there are **${rows}**. Each row has ${count(TEN, "dot")}.`, math: [text("Rows: "), num(rows)], state: 0, answerStep: "rows", result: rows },
      { id: "tens", narration: `Say one ten for each row: ${said.join(", ")}. That's **${total}** dots.`, math: tensUpTo(rows, num(total)), state: 1, answerStep: "tens", result: total },
    ],
  };
}

export const lesson: LessonDefinition<TensProblem> = {
  id: "k-tens",
  grade: 0,
  unit: "Counting",
  title: "Count by tens to 100",
  pre: "k-count20",
  reference: createTens(4),
  generate: (rng, index) => createTens(rng.int(2, index < 3 ? 5 : TEN)),
  restore: raw => restoreVia(raw, ["rows"] as const, v => createTens(v.rows)),
  display: () => words("How many dots?"),
  picture: p => tensRows(p.rows, `${count(p.rows, "row")} of ${count(TEN, "dot")}`),
  answers,
  explain,
};
