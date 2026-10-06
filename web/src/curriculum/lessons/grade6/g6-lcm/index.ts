// Least common multiple (the current app's g6-lcm): count by the bigger number until the smaller one goes into it.
import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildNumberLine, fitRange, type Hop } from "../../../../explanations/diagrams/number-line/build";
import { expectedOf, lcm, oneBox, restoreVia, sparseEvery, wholeIn } from "../../_number-line/steps";
import { count } from "../../../text";

/** LCM(a, b) with 2 ≤ a < b ≤ 12; when they share no factor, a × b is at most 60 */
export interface LcmProblem { a: number; b: number }

export function createLcm(a: number, b: number): LcmProblem {
  wholeIn("a", a, 2, 12);
  wholeIn("b", b, 2, 12);
  if (a >= b) throw new Error("a is the smaller number");
  if (lcm(a, b) === a * b && a * b > 60) throw new Error("numbers with no common factor have a product of at most 60");
  return { a, b };
}

function answers({ a, b }: LcmProblem): AnswerModel {
  const L = lcm(a, b);
  return {
    steps: [
      oneBox({
        id: "count", label: "Count by the bigger number", question: `Count by ${b}s: ${b}, ${2 * b}, ${3 * b}, … Which is the first one ${a} goes into?`,
        prompt: s => [s], ans: L, hint: `Check each number as you count: does ${a} divide it evenly?`,
        wrong: L !== a * b ? [[a * b, "Common multiple, but not the least", `${a * b} works, but there's a smaller one.`]] : [],
      }),
      oneBox({ id: "check", label: "Check it", prompt: s => [num(L), op("÷"), num(a), op("="), s], ans: L / a, hint: "It should come out even.",
        wrong: [[L / b, "Divided by the other number", `Check with ${a}, the smaller number: does it go in evenly?`]] }),
    ],
    finalParts: [0],
  };
}

function explain(p: LcmProblem, model: AnswerModel): Explanation {
  const { a, b } = p, L = expectedOf(model, "count"), k = expectedOf(model, "check");
  const big = Array.from({ length: L / b }, (_, i) => (i + 1) * b);
  const misses = big.slice(0, -1);
  // labels on round values only, so counting in 4s to 60 doesn't crowd a phone (review v43 item 9)
  const range = fitRange([0, L], { maxTicks: 30, pad: 0, minStep: 1 });
  const hops: Hop[] = [
    ...big.map((v, i): Hop => ({ from: v - b, to: v, label: `+${b}`, beat: 0, delay: 0.5 * i, start: i === 0 })),
    ...Array.from({ length: k }, (_, i): Hop => ({ from: i * a, to: (i + 1) * a, label: `+${a}`, below: true, beat: 1, delay: 0.4 * i, start: false })),
  ];
  return {
    heading: "The first number both go into",
    idea: ["A common multiple is a number both counts land on, so the first one they share is the least common multiple.", "Count by the bigger number and check each one."],
    statement: [text("LCM("), num(a), text(", "), num(b), text(")"), op("="), num(L)],
    diagram: buildNumberLine({
      ...range, every: sparseEvery(range),
      hops, marks: [{ v: L, beat: 2, cls: "dota", label: `${L} ÷ ${a} = ${count(k, "jump")}` }],
      alt: `Number line from 0 to ${L}: jumps of ${b} above and jumps of ${a} below both land on ${L}.`,
    }),
    caption: `Both land on ${L} first.`,
    timeline: beats(3),
    steps: [
      { id: "count-big", narration: `Count by ${b}s: ${big.join(", ")}.`, math: big.flatMap((v, i) => (i ? [text(", "), num(v)] : [num(v)])), state: 0 },
      { id: "count", narration: misses.length ? `${a} doesn't go into ${misses.join(" or ")}, but it does go into ${L}: counting by ${a}s lands there too.` : `${a} goes into ${L} already: counting by ${a}s lands there too.`,
        math: [text("LCM("), num(a), text(", "), num(b), text(")"), op("="), num(L)], state: 1, answerStep: "count", result: L },
      { id: "check", narration: `Check it: ${L} ÷ ${a} = ${k}. It comes out even.`, math: [num(L), op("÷"), num(a), op("="), num(k)], state: 2, answerStep: "check", result: k },
    ],
  };
}

export const lesson: LessonDefinition<LcmProblem> = {
  id: "g6-lcm",
  grade: 6,
  unit: "Number system",
  title: "Least common multiple",
  reference: createLcm(4, 6), // LCM(4, 6) = 12, the current app's example
  generate: rng => {
    let a: number, b: number;
    do { a = rng.int(2, 12); b = rng.int(2, 12); } while (a === b || (lcm(a, b) === a * b && a * b > 60));
    return createLcm(Math.min(a, b), Math.max(a, b));
  },
  restore: raw => restoreVia(raw, ["a", "b"] as const, v => createLcm(v.a, v.b)),
  display: p => [text("LCM("), num(p.a), text(", "), num(p.b), text(")")],
  answers,
  explain,
};
