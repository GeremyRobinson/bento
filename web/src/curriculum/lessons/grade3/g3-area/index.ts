import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildSquares } from "../../../../explanations/diagrams/early-g3/squares";
import { box, expectedOf, restoreVia, wholeIn } from "../_kit/steps";
import { count } from "../../../text";

/** A rectangle l squares long and w squares high: its area is the number of unit squares inside. */
export interface AreaProblem { l: number; w: number }

export function createArea(l: number, w: number): AreaProblem {
  wholeIn("l", l, 2, 10);
  wholeIn("w", w, 2, 8);
  return { l, w };
}

/** Early problems are small (up to 5 by 4); later ones up to 10 by 8. */
export function generateArea(rng: Rng, index: number): AreaProblem {
  return index < 3 ? createArea(rng.int(3, 5), rng.int(2, 4)) : createArea(rng.int(3, 10), rng.int(2, 8));
}

function answers({ l, w }: AreaProblem): AnswerModel {
  const A = l * w;
  return {
    steps: [
      box({
        id: "row", label: "Count one row", question: "How many squares are in the top row?",
        prompt: x => [text("one row "), op("="), x], ans: l,
        wrong: [
          [l + 1, "Counted the lines", `That counts the lines between squares. Count the squares themselves: there are ${l}.`],
          [w, "Counted down instead of across", `${w} is how many rows there are. Count across the top row.`],
        ],
        hint: "Touch each square in the top row as you count.",
        explain: `The top row has ${count(l, "square")}.`,
      }),
      box({
        id: "rows", label: "Count the rows", question: "How many rows are there?",
        prompt: x => [text("rows "), op("="), x], ans: w,
        wrong: [
          [w + 1, "Counted the lines", `That counts the lines between rows. Count the rows of squares: there are ${w}.`],
          [l, "Counted across instead of down", `${l} is how many squares are in one row. Count the rows going down.`],
        ],
        hint: "Count the rows going down the side.",
        explain: `There are ${count(w, "row")}.`,
      }),
      box({
        id: "area", label: "Find the area", question: `${count(w, "row")} of ${count(l, "square")}.`,
        prompt: x => [num(w), op("×"), num(l), op("="), x, text(" square units")], ans: A,
        wrong: [
          [2 * (l + w), "Found the perimeter", `${2 * (l + w)} is the distance around the edge. Area counts the squares inside.`],
          [l + w, "Added instead of multiplied", `${l} + ${w} counts one row and one column. Every row has ${count(l, "square")}, so multiply.`],
          [A - l, "Missed a row", `That's ${count(w - 1, "row")}. Count all ${count(w, "row")} of ${l}.`],
        ],
        hint: `Count by ${l}s, once for each of the ${count(w, "row")}.`,
        explain: `${count(w, "row")} of ${count(l, "square")} make ${count(A, "square")}, so the area is ${A} square units.`,
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: AreaProblem, model: AnswerModel): Explanation {
  const { l, w } = p, L = expectedOf(model, "row"), W = expectedOf(model, "rows"), A = expectedOf(model, "area");
  return {
    heading: "Count the squares inside",
    idea: ["Area is how many squares cover a shape, and equal rows of squares can be multiplied."],
    statement: [text("area "), op("="), text("?")],
    diagram: buildSquares({
      cols: l, rows: w, rowBeat: 1, colBeat: 2, fillBeat: 3,
      topLabel: `${L} in a row`, sideLabel: `${count(W, "row")}`, note: `${W} × ${L} = ${A} square units`,
      alt: `A rectangle of unit squares, ${l} across and ${w} down. ${count(w, "row")} of ${l} make ${count(A, "square")}.`,
    }),
    caption: `A rectangle made of unit squares.`,
    timeline: beats(4),
    steps: [
      { id: "row", state: 1, answerStep: "row", result: L, math: [text("one row "), op("="), num(L)], narration: `Count across the top row: ${count(L, "square")}.` },
      { id: "rows", state: 2, answerStep: "rows", result: W, math: [text("rows "), op("="), num(W)], narration: `Count down the side: ${count(W, "row")}, each just like the first.` },
      { id: "area", state: 3, answerStep: "area", result: A, math: [num(W), op("×"), num(L), op("="), num(A)],
        narration: `${count(W, "row")} of ${count(L, "square")} is ${W} × ${L} = ${A}. The area is ${A} square units.` },
    ],
  };
}

export const lesson: LessonDefinition<AreaProblem> = {
  id: "g3-area",
  grade: 3,
  unit: "Measurement",
  title: "Area by counting squares",
  pre: "g2-arrays",
  reference: createArea(6, 4),
  generate: generateArea,
  restore: raw => restoreVia(raw, ["l", "w"] as const, v => createArea(v.l, v.w)),
  display: () => [text("area "), op("="), text("?")],
  displayNote: () => "Each square is one square unit. What is the area?",
  picture: p => buildSquares({ cols: p.l, rows: p.w, alt: `A rectangle of unit squares, ${p.l} across and ${p.w} down.` }),
  answers,
  explain,
};
