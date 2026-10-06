// Make a ten to add (the current app's G1_TEN): 8 + 5 = 8 + 2 + 3 = 10 + 3.
import { answer, mark, num, op } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { chainExplanation } from "../../../../explanations/diagrams/chain/build";
import { tenFrames } from "../../../../explanations/diagrams/number-line/counters";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";

/** a (6–9) plus b, where b is big enough to go past 10 */
export interface MakeTenProblem { a: number; b: number }

export function createMakeTen(a: number, b: number): MakeTenProblem {
  wholeIn("a", a, 6, 9);
  wholeIn("b", b, 11 - a, 9);
  return { a, b };
}

function answers({ a, b }: MakeTenProblem): AnswerModel {
  const need = 10 - a, left = b - need;
  return {
    steps: [
      oneBox({
        id: "ten", label: "Make a ten", prompt: s => [num(a), op("+"), s, op("="), num(10)], ans: need,
        wrong: [
          [10, "Wrote the full frame", `10 is the full frame. How many empty boxes does ${a} leave?`],
          [a, "Wrote the dots already there", `That's the dots already there. Count the empty boxes.`],
        ],
        hint: `Count up from ${a} to 10. How many did you count?`, explain: `${a} + ${need} = 10.`,
      }),
      oneBox({
        id: "break", label: `Break apart ${b}`, prompt: s => [num(b), op("="), num(need), op("+"), s], ans: left,
        wrong: [
          [b + need, "Breaking apart", `Both parts have to be smaller than ${b}. What is ${b} take away ${need}?`],
          [b, "Kept all of it", `That's all ${b}. ${need} of them went into the ten frame. How many are still outside?`],
        ],
        hint: `${b} take away ${need}.`, explain: `${b} − ${need} = ${left}.`,
      }),
      oneBox({
        id: "add", label: "Add to the ten", prompt: s => [num(10), op("+"), num(left), op("="), s], ans: a + b,
        wrong: [[left, "Forgot the ten", `That's only the dots left over. The full frame is 10 more: 10 and ${left} is ${a + b}.`]],
        hint: `10 plus ${left} is ten and ${left} more.`, explain: `10 + ${left} = ${a + b}.`,
        work: [num(a), op("+"), num(b), op("="), num(10), op("+"), num(left), op("="), answer("x", a + b)],
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: MakeTenProblem, model: AnswerModel) {
  const { a, b } = p, need = expectedOf(model, "ten"), left = expectedOf(model, "break"), sum = expectedOf(model, "add");
  return chainExplanation({
    heading: "Make a ten first",
    idea: ["10 is easy to add to. So fill the first ten frame: move some dots from the second number until the frame is full. Now it is 10 and the dots that are left."],
    statement: [num(a), op("+"), num(b)],
    caption: `Borrow ${need} from the ${b} to fill the ten.`,
    alt: `${a} + ${b} becomes ${a} + ${need} + ${left}, then 10 + ${left} = ${sum}.`,
    beats: [
      { id: "ten", narration: `${a} needs ${need} more to make 10.`, math: [num(a), op("+"), num(need), op("="), num(10)],
        lines: [[num(a), op("+"), num(b)]], answerStep: "ten", result: need },
      { id: "break", narration: `Break ${b} into ${need} and ${left}.`, math: [num(b), op("="), num(need), op("+"), num(left)],
        lines: [[num(a), op("+"), mark(need), op("+"), num(left)]], answerStep: "break", result: left },
      { id: "add", narration: `Now it's 10 + ${left} = ${sum}.`, math: [num(10), op("+"), num(left), op("="), num(sum)],
        lines: [[mark(10), op("+"), num(left), op("="), num(sum)]], answerStep: "add", result: sum },
    ],
  });
}

export const lesson: LessonDefinition<MakeTenProblem> = {
  id: "g1-ten",
  grade: 1,
  unit: "Adding and subtracting",
  title: "Make a ten to add",
  pre: "k-make10",
  reference: createMakeTen(8, 5),
  // the first three fill the frame with 1 or 2 dots, and the second number stays small
  generate: (rng, index) => { const a = index < 3 ? rng.int(8, 9) : rng.int(6, 9); return createMakeTen(a, rng.int(11 - a, index < 3 ? 6 : 9)); },
  restore: raw => restoreVia(raw, ["a", "b"] as const, v => createMakeTen(v.a, v.b)),
  display: p => [num(p.a), op("+"), num(p.b)],
  picture: p => tenFrames([p.a, p.b], `A ten frame with ${p.a} and a ten frame with ${p.b}`),
  answers,
  explain,
};
