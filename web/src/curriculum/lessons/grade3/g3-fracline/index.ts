import { frac, num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildFracLine } from "../../../../explanations/diagrams/early-g3/frac-line";
import { box, expectedOf, fracBoxes, plural, restoreVia, wholeIn } from "../_kit/steps";
import { count } from "../../../text";

/** A point a/b on a number line from 0 to w, each whole cut into b equal spaces. */
export interface FracLineProblem { a: number; b: number; w: number }

const DENS = [2, 3, 4, 6, 8];

export function createFracLine(a: number, b: number, w: number): FracLineProblem {
  if (!DENS.includes(b)) throw new Error(`3rd grade cuts into ${DENS.join(", ")} parts`);
  wholeIn("w", w, 1, 2);
  wholeIn("a", a, 1, w * b - 1);
  if (a % b === 0) throw new Error(`${a}/${b} is a whole number`);
  if (w === 2 && b > 6) throw new Error("two wholes of eighths are too tight to read");
  return { a, b, w };
}

/** Early problems: halves, thirds or fourths between 0 and 1. Later: up to eighths, sometimes past 1 on a line to 2. */
export function generateFracLine(rng: Rng, index: number): FracLineProblem {
  const b = index < 3 ? rng.pick([2, 3, 4]) : rng.pick([3, 4, 6, 8]);
  const w = index >= 3 && b <= 6 && rng.next() < 0.3 ? 2 : 1;
  let a: number;
  do a = rng.int(1, w * b - 1); while (a % b === 0 || (w === 2 && a < b));
  return createFracLine(a, b, w);
}

function answers({ a, b, w }: FracLineProblem): AnswerModel {
  return {
    steps: [
      box({
        id: "spaces", label: "Count the spaces", question: "From 0 to 1, how many equal spaces are there?",
        prompt: x => [text("spaces "), op("="), x], ans: b,
        wrong: [
          [b + 1, "Counted the tick marks", `There are ${b + 1} tick marks from 0 to 1, but only ${b} spaces between them. Count the spaces.`],
          [w * b, "Counted all the way to 2", `Count only from 0 to 1. That's one whole.`],
          [b - 1, "Missed a space", "Count every space between 0 and 1. Start at 0 and stop at 1."],
        ],
        hint: "Count the gaps between the tick marks, from 0 to 1.",
        explain: `0 to 1 is cut into ${b} equal spaces, so each space is 1/${b}.`,
      }),
      box({
        id: "jumps", label: "Count the jumps", question: "How many spaces from 0 to the point?",
        prompt: x => [text("jumps "), op("="), x], ans: a,
        wrong: [
          [a + 1, "Counted the tick at 0", `Start at 0 and count each jump, not each tick. It takes ${count(a, "jump")}.`],
          [a - 1, "Missed a jump", "Count every jump from 0, right up to the point."],
          ...(a > b ? [[a - b, "Started counting at 1", `Count from 0, not from 1. The jumps past 1 are only part of it.`] as [number, string, string]] : []),
        ],
        hint: "Jump one space at a time from 0 to the point.",
        explain: `It takes ${plural(a, "jump")} of 1/${b} to reach the point.`,
      }),
      fracBoxes({
        id: "name", label: "Name the point", question: `${plural(a, "jump")} of 1/${b} is…`,
        prompt: f => [text("point "), op("="), f], N: a, D: b,
        wrong: [
          [b, a, "Flipped the fraction", `The bottom is the number of spaces in one whole: ${b}. The top is the number of jumps: ${a}.`],
          [a, b + 1, "Used the tick marks", `The bottom counts spaces, not tick marks. One whole has ${b} spaces.`],
          ...(w === 2 ? [[a, w * b, "Used all the spaces to 2", `The bottom counts the spaces in one whole, 0 to 1. That's ${b}.`] as [number, number, string, string]] : []),
        ],
        hint: `Top: the jumps, ${a}. Bottom: the spaces in one whole, ${b}.`,
        explain: `${plural(a, "jump")} of 1/${b} ${a === 1 ? "lands" : "land"} on ${a}/${b}.`,
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: FracLineProblem, model: AnswerModel): Explanation {
  const { a, b, w } = p, B = expectedOf(model, "spaces"), A = expectedOf(model, "jumps");
  return {
    heading: "Count the jumps from 0",
    idea: ["Each whole is cut into equal spaces, and the bottom number tells how many."],
    statement: [text("point "), op("="), text("?")],
    diagram: buildFracLine({
      den: b, wholes: w, at: a, spacesBeat: 1, hopsBeat: 2, nameBeat: 3,
      alt: `A number line from 0 to ${w}. Each whole is cut into ${b} equal spaces. The point is ${count(a, "jump")} from 0, at ${a}/${b}.`,
    }),
    caption: `A number line from 0 to ${w}, with a point on it.`,
    timeline: beats(4),
    steps: [
      { id: "spaces", state: 1, answerStep: "spaces", result: B, math: [text("spaces "), op("="), num(B)],
        narration: `From 0 to 1 there are ${B} equal spaces, so each space is 1/${B}.` },
      { id: "jumps", state: 2, answerStep: "jumps", result: A, math: [text("jumps "), op("="), num(A)],
        narration: `Jump from 0 to the point, one space at a time. That's ${plural(A, "jump")}.` },
      { id: "name", state: 3, answerStep: "name", result: a, math: [text("point "), op("="), frac(A, B)],
        narration: `${plural(A, "jump")} of 1/${B} is ${A}/${B}.${A > B ? ` It's past 1, because ${A} is more than ${B}.` : ""}` },
    ],
  };
}

export const lesson: LessonDefinition<FracLineProblem> = {
  id: "g3-fracline",
  grade: 3,
  unit: "Fractions",
  title: "Fractions on a number line",
  pre: "g3-unitfrac",
  reference: createFracLine(3, 4, 1),
  generate: generateFracLine,
  restore: raw => restoreVia(raw, ["a", "b", "w"] as const, v => createFracLine(v.a, v.b, v.w)),
  display: () => [text("point "), op("="), text("?")],
  displayNote: () => "What fraction is at the point?",
  picture: p => buildFracLine({ den: p.b, wholes: p.w, at: p.a, alt: `A number line from 0 to ${p.w}, each whole cut into ${p.b} equal spaces, with a point on it.` }),
  answers,
  explain,
};
