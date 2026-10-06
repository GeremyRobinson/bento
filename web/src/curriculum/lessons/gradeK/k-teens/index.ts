// Teen numbers: a full ten frame and some more ones. 10 and 6 more make 16.
import { answer, num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { teenFrames } from "../../../../explanations/diagrams/early-k/frames";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { TEN, countUp, slips, words } from "../kit";
import { count } from "../../../text";

/** ten and `ones` more, ones from 1 to 9 */
export interface TeenProblem { ones: number }

export function createTeen(ones: number): TeenProblem {
  wholeIn("ones", ones, 1, 9);
  return { ones };
}

function answers({ ones }: TeenProblem): AnswerModel {
  const n = TEN + ones;
  return {
    steps: [
      oneBox({
        id: "ones", label: "Count the extra ones", question: `The first frame is full: that's ${TEN}. How many dots are in the second frame?`,
        prompt: s => [text("Extra ones: "), s], ans: ones,
        wrong: slips(ones, [
          [TEN, "Counted the full frame", "That's the full frame. Count the dots in the **second** frame."],
          [n, "Counted every dot", `That's all the dots. Just count the second frame this time.`],
          [ones - 1, "Skipped a dot", "One short. Touch each dot in the second frame."],
          [ones + 1, "Counted a dot twice", "One too many. Touch each dot only once."],
        ]),
        hint: "Touch each dot in the second frame and count.",
        explain: `${countUp(1, ones)}. There ${ones === 1 ? "is 1 extra one" : `are ${ones} extra ones`}.`,
      }),
      oneBox({
        id: "teen", label: "Make the teen number", question: `${TEN} and ${ones} more make what number?`,
        prompt: s => [num(TEN), op("+"), num(ones), op("="), s], ans: n,
        wrong: slips(n, [
          [10 * ones + 1, "Mixed up the digits", `You have the right digits, but the 1 for the ten comes first: ${n}.`],
          [ones, "Forgot the ten", `Don't forget the full frame. Start at ${TEN} and count on ${ones}.`],
          [n - 1, "Counted on one short", `Start at ${TEN}, then say ${TEN + 1} for the first extra dot.`],
          [n + 1, "Counted on one too many", `One too many. Start at ${TEN} and count on just ${ones}.`],
        ]),
        hint: `Say ${TEN} for the full frame. Then count on, one number for each dot in the second frame.`,
        explain: `${TEN} and ${ones} more make ${n}. A teen number is a ten and some ones.`,
        work: [num(TEN), op("+"), num(ones), op("="), answer("x", n)],
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: TeenProblem, model: AnswerModel): Explanation {
  const ones = expectedOf(model, "ones"), n = expectedOf(model, "teen");
  return {
    heading: "A ten and some ones",
    idea: ["Every teen number is one full ten frame and some more ones."],
    statement: words("What number is this?"),
    diagram: teenFrames(p.ones, `A full ten frame and a frame with ${ones}: ${TEN} + ${ones} = ${n}.`, { ten: 0, ones: 1, whole: 2 }),
    caption: `${TEN} and ${ones} more is ${n}.`,
    timeline: beats(3),
    steps: [
      { id: "ten", narration: `The first frame is full. That's **${TEN}**.`, math: [num(TEN)], state: 0 },
      { id: "ones", narration: `Count the second frame: ${countUp(1, ones)}. That's **${ones}** more.`, math: [text("Extra ones: "), num(ones)], state: 1, answerStep: "ones", result: ones },
      { id: "teen", narration: `${TEN} and ${ones} more make **${n}**. See the ${ones} in ${n}?`, math: [num(TEN), op("+"), num(ones), op("="), num(n)], state: 2, answerStep: "teen", result: n },
    ],
  };
}

export const lesson: LessonDefinition<TeenProblem> = {
  id: "k-teens",
  grade: 0,
  unit: "Counting",
  title: "Teen numbers",
  pre: "k-count20",
  reference: createTeen(6),
  generate: (rng, index) => createTeen(rng.int(1, index < 3 ? 5 : 9)),
  restore: raw => restoreVia(raw, ["ones"] as const, v => createTeen(v.ones)),
  display: () => words("What number is this?"),
  picture: p => teenFrames(p.ones, `A full ten frame and a frame with ${count(p.ones, "dot")}`),
  answers,
  explain,
};
