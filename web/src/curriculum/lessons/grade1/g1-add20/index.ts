// Add within 20: start with the bigger number, then count on the smaller one, one hop at a time.
import { answer, num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildNumberLine, type Hop } from "../../../../explanations/diagrams/number-line/build";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { slips } from "../_kit";

/** a + b, one of them small (2 to 5); the sum is 11 to 20 */
export interface Add20Problem { a: number; b: number }

export function createAdd20(a: number, b: number): Add20Problem {
  wholeIn("a", a, 2, 18);
  wholeIn("b", b, 2, 18);
  if (Math.min(a, b) > 5) throw new Error("one number must be small enough to count on (5 or less)");
  if (a + b < 11 || a + b > 20) throw new Error("the sum must be 11 to 20");
  return { a, b };
}

function answers({ a, b }: Add20Problem): AnswerModel {
  const big = Math.max(a, b), small = Math.min(a, b), sum = a + b;
  const counted = Array.from({ length: small }, (_, i) => big + i + 1);
  return {
    steps: [
      oneBox({
        id: "start", label: "Start with the bigger one", question: "Which number will you start counting from?",
        prompt: s => [text("Start at "), s], ans: big,
        wrong: slips(big, [[small, "Started with the smaller number", `You can, but it's a long count! Start at ${big}, then you only count on ${small}.`]]),
        hint: `Which is bigger, ${a} or ${b}? Start there.`,
        explain: a === big ? `${big} is bigger, so start at ${big}.` : `${big} is bigger. You can add in any order, so start at ${big}.`,
        work: [text("Start at "), answer("x", big)],
      }),
      oneBox({
        id: "count-on", label: "Count on", question: `Start at ${big}. Count on ${small} more.`,
        prompt: s => [num(a), op("+"), num(b), op("="), s], ans: sum,
        wrong: slips(sum, [
          [sum - 1, "Counted the start", `One short. Don't count ${big} again: your first hop lands on ${big + 1}.`],
          [sum + 1, "One too many", `One too many. Make exactly ${small} hops: ${counted.join(", ")}.`],
          [big - small, "Took away", "That's taking away. Adding makes the number bigger."],
        ]),
        hint: `Say ${big}, then count ${small} more: one number for each.`,
        explain: `${big}, then ${counted.join(", ")}. That's ${sum}.`,
      }),
    ],
    finalParts: [-1],
  };
}

function explain({ a, b }: Add20Problem, model: AnswerModel): Explanation {
  const big = expectedOf(model, "start"), sum = expectedOf(model, "count-on"), small = sum - big;
  const counted = Array.from({ length: small }, (_, i) => big + i + 1);
  const min = Math.max(0, big - 4), max = sum + 2;
  const hops: Hop[] = counted.map((v, i): Hop => ({ from: v - 1, to: v, label: String(v), beat: 1, delay: 0.5 * i, start: false }));
  return {
    heading: "Start big, count on",
    idea: ["You can add in any order, so starting with the bigger number means fewer hops."],
    statement: [num(a), op("+"), num(b)],
    diagram: buildNumberLine({
      min, max, hops, labelAt: [big],
      marks: [{ v: big, label: `start ${big}`, beat: 0 }, { v: sum, beat: 1, delay: 0.5 * small, cls: "dota" }],
      alt: `Number line from ${min} to ${max}: start at ${big}, hop ${small} times to ${sum}.`,
    }),
    caption: `${big} and ${small} more is ${sum}.`,
    timeline: beats(2),
    steps: [
      { id: "start", narration: a === big ? `${big} is the bigger number. Start there.` : `${b} + ${a} is the same as ${a} + ${b}, so start with the bigger number, **${big}**.`, math: [text("Start at "), num(big)], state: 0, answerStep: "start", result: big },
      { id: "count-on", narration: `Hop ${small} times, one for each: ${counted.join(", ")}. You land on **${sum}**.`, math: [num(a), op("+"), num(b), op("="), num(sum)], state: 1, answerStep: "count-on", result: sum },
    ],
  };
}

export const lesson: LessonDefinition<Add20Problem> = {
  id: "g1-add20",
  grade: 1,
  unit: "Adding and subtracting",
  title: "Add within 20",
  pre: "k-add",
  reference: createAdd20(3, 9),
  generate: (rng, index) => {
    const small = rng.int(2, index < 3 ? 3 : 5);
    const big = rng.int(Math.max(small + 1, 11 - small), 20 - small);
    return rng.int(0, 1) ? createAdd20(small, big) : createAdd20(big, small);
  },
  restore: raw => restoreVia(raw, ["a", "b"] as const, v => createAdd20(v.a, v.b)),
  display: p => [num(p.a), op("+"), num(p.b)],
  answers,
  explain,
};
