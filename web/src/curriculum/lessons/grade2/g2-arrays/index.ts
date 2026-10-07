// Arrays: count the rows and how many are in each row, then add the same number once for every row.
import { num, op, text, type MathText, type MathToken } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildArray } from "../../../../explanations/diagrams/early-g2/counting";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { count, slips } from "../kit";
import { count as countOf } from "../../../text";

/** Dots in `rows` rows with `cols` in each row. */
export interface ArrayProblem { rows: number; cols: number }

export function createArray(rows: number, cols: number): ArrayProblem {
  wholeIn("rows", rows, 2, 5);
  wholeIn("cols", cols, 2, 5);
  return { rows, cols };
}

/** Early arrays are at most 4 by 4; later ones up to 5 by 5. */
const generate = (rng: Rng, index: number) => {
  const hi = index < 3 ? 4 : 5;
  return createArray(rng.int(2, hi), rng.int(2, hi));
};

/** c + c + … once per row, with the answer (or a box) after the equals sign. */
const repeated = (rows: number, cols: number, end: MathToken): MathText => [
  ...Array.from({ length: rows }, (_, i) => (i ? [op("+"), num(cols)] : [num(cols)])).flat(), op("="), end,
];

function answers({ rows, cols }: ArrayProblem): AnswerModel {
  const total = rows * cols;
  return {
    steps: [
      oneBox({
        id: "rows", label: "Count the rows", question: "Rows go across. How many rows are there?",
        prompt: s => [text("Rows: "), s], ans: rows,
        wrong: slips(rows, [
          [cols, "Counted across", "That's how many dots are in one row. Count the rows going down."],
          [total, "Counted every dot", "Count the rows, not the dots."],
        ]),
        hint: "Point to each row from top to bottom and count.",
        explain: `There ${rows === 1 ? "is" : "are"} ${count(rows, "row")}.`,
      }),
      oneBox({
        id: "cols", label: "Count one row", question: "How many dots are in each row?",
        prompt: s => [text("In each row: "), s], ans: cols,
        wrong: slips(cols, [
          [rows, "Counted the rows", "That's how many rows there are. Count the dots across one row."],
          [total, "Counted every dot", "Count just one row, from left to right."],
        ]),
        hint: "Count the dots in the top row, left to right.",
        explain: `Each row has ${count(cols, "dot")}.`,
      }),
      oneBox({
        id: "total", label: "Add the rows", question: `Add ${cols} once for each of the ${countOf(rows, "row")}.`,
        prompt: s => repeated(rows, cols, s), ans: total,
        wrong: slips(total, [
          [rows + cols, "Added rows and dots", `Add ${cols} once for every row: that's ${rows} times.`],
          [total - cols, "Left out a row", `There are ${countOf(rows, "row")}, so add ${cols} ${rows} times.`],
          [total + cols, "Added an extra row", `There are only ${countOf(rows, "row")}. Add ${cols} ${rows} times.`],
        ]),
        hint: `Skip count by ${cols}s, once for each row${rows > 2 ? `: ${cols}, ${2 * cols}, and on` : ""}.`,
        explain: `${Array.from({ length: rows }, (_, i) => cols * (i + 1)).join(", ")}. There are ${countOf(total, "dot")}.`,
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: ArrayProblem, model: AnswerModel): Explanation {
  const rows = expectedOf(model, "rows"), cols = expectedOf(model, "cols"), total = expectedOf(model, "total");
  const sum = `${Array.from({ length: rows }, () => cols).join(" + ")} = ${total}`;
  return {
    heading: "Rows of the same size",
    idea: ["All the rows in an array are the same size, so one row's count repeats for every row."],
    statement: [num(p.rows), text(" rows of "), num(p.cols)],
    diagram: buildArray({
      rows: p.rows, cols: p.cols, beats: { rows: 1, cols: 2, total: 3 }, total: sum,
      alt: `An array of dots: ${count(rows, "row")} with ${cols} in each row. ${sum}.`,
    }),
    caption: `Each row has ${cols}.`,
    timeline: beats(4),
    steps: [
      { id: "rows", narration: `Count the rows going down: ${rows}.`, math: [text("Rows: "), num(rows)], state: 1, answerStep: "rows", result: rows },
      { id: "cols", narration: `Count across one row: ${cols}. Every row is the same.`, math: [text("In each row: "), num(cols)], state: 2, answerStep: "cols", result: cols },
      { id: "total", narration: `Add ${cols} for every row: ${Array.from({ length: rows }, (_, i) => cols * (i + 1)).join(", ")}.`, math: repeated(rows, cols, num(total)), state: 3, answerStep: "total", result: total },
    ],
  };
}

export const lesson: LessonDefinition<ArrayProblem> = {
  id: "g2-arrays",
  grade: 2,
  unit: "Getting ready to multiply",
  title: "Arrays",
  pre: "g2-skip",
  reference: createArray(3, 4),
  generate,
  restore: raw => restoreVia(raw, ["rows", "cols"] as const, v => createArray(v.rows, v.cols)),
  display: () => [text("How many dots?")],
  displayNote: () => "Count the rows, then add them up.",
  picture: p => buildArray({ rows: p.rows, cols: p.cols, beats: { rows: 1, cols: 1, total: 1 }, total: "", bare: true, alt: "An array of dots in rows and columns." }),
  answers,
  explain,
  story: ({ rows, cols }) => ({ op: "+", text: `A box of muffins has **${rows}** rows with **${cols}** muffins in each row. How many muffins are in the box?` }),
};
