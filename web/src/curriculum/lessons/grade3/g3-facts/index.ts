import { num, op, text, type MathText, type MathToken } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildArray } from "../../../../explanations/diagrams/early-g3/array";
import { box, expectedOf, restoreVia, wholeIn } from "../_kit/steps";
import { count } from "../../../text";

/** a × b as a rows of b: skip count by b, a times, then turn it around. */
export interface FactProblem { a: number; b: number }

export function createFact(a: number, b: number): FactProblem {
  wholeIn("a", a, 2, 10);
  wholeIn("b", b, 2, 10);
  return { a, b };
}

/**
 * Early problems count by 2, 5 or 10 a few times, never a square (5 × 5 turned around is still 5 × 5, so the turn step
 * would show nothing); later ones use any fact up to 10 × 10.
 */
export function generateFact(rng: Rng, index: number): FactProblem {
  if (index < 3) {
    const b = rng.pick([2, 5, 10]);
    return createFact(b === 5 ? rng.pick([3, 4, 6]) : rng.int(3, 6), b);
  }
  let a: number, b: number;
  do { a = rng.int(2, 10); b = rng.int(3, 9); } while (a === b && rng.next() < 0.6);
  return createFact(a, b);
}

/** The skip-count list up to the last box: "6, 12, …, 42, ?" (the first two and last two counts when the list is long). */
function skipList({ a, b }: FactProblem, last: MathToken): MathText {
  const counts = Array.from({ length: a - 1 }, (_, i) => (i + 1) * b);
  const shown: (number | null)[] = counts.length > 4 ? [counts[0]!, counts[1]!, null, counts[a - 3]!, counts[a - 2]!] : counts;
  return [...shown.flatMap((v): MathText => [v == null ? text("…") : num(v), text(", ")]), last];
}

function answers(p: FactProblem): AnswerModel {
  const { a, b } = p, P = a * b;
  const count1 = box({
    id: "count", label: `Count by ${b}s`, question: `Count by ${b}s, ${a} times. What is the last number?`,
    prompt: x => skipList(p, x), ans: P,
    wrong: [
      [(a - 1) * b + 1, "Counted on by 1", `Each jump is ${b}, not 1. ${(a - 1) * b} + ${b} = ${P}.`],
      [(a - 1) * b, "Stopped one jump short", `That's only ${count(a - 1, "jump")} of ${b}. Make ${count(a, "jump")}.`],
      [(a + 1) * b, "One jump too many", `That's ${count(a + 1, "jump")} of ${b}. Stop after ${count(a, "jump")}.`],
      [a + b, "Added the two numbers", `${a} + ${b} puts them together once. You need ${count(a, "group")} of ${b}.`],
    ],
    hint: `Add ${b} to the last number you see.`,
    explain: `${count(a, "jump")} of ${b} land on ${P}.`,
  });
  // a square turned around is the same square, so there is nothing new to find
  if (a === b) return { steps: [count1], finalParts: [-1] };
  return {
    steps: [
      count1,
      box({
        id: "turn", label: "Turn it around", question: `${count(a, "group")} of ${b} is the same as ${count(b, "group")} of ${a}.`,
        prompt: x => [num(b), op("×"), num(a), op("="), x], ans: P,
        wrong: [
          [a + b, "Added instead of multiplied", `× means groups. ${count(b, "group")} of ${a} is ${P}, not ${a + b}.`],
          [b * b, "Used the same number twice", `That's ${b} × ${b}. Here it is ${count(b, "group")} of ${a}.`],
        ],
        hint: `Turn the array on its side. The rows become columns, but no dots are added or taken away, so the total is the same as the ${a} × ${b} you just counted.`,
        explain: `${b} × ${a} = ${P}, the same as ${a} × ${b}.`,
      }),
    ],
    finalParts: [-1],
  };
}

/**
 * a rows of b dots; the running count appears at the end of each row, then columns of a show it turned around.
 * A square (a = b) looks the same turned around, so it stops after the count.
 */
export function factPicture({ a, b }: FactProblem, P: number) {
  const square = a === b;
  return buildArray({
    rows: a, cols: b,
    rowTotals: { from: 1, text: r => String((r + 1) * b), acc: r => r === a - 1 },
    ...(square ? {} : { colBoxes: { from: 2, text: () => String(a) } }),
    lines: [
      { text: `${count(a, "row")} of ${b}`, from: 0, until: 0, cls: "lbl" },
      { text: `${a} × ${b} = ${P}`, from: 1, ...(square ? {} : { until: 1 }) },
      ...(square ? [] : [{ text: `${count(b, "column")} of ${a}: ${b} × ${a} = ${P}`, from: 2 }]),
    ],
    alt: `${count(a, "row")} of ${count(b, "dot")}. Counting by ${b}s row by row reaches ${P}.${square ? "" : ` Seen as ${count(b, "column")} of ${a}, it is still ${P}.`}`,
  });
}

function explain(p: FactProblem, model: AnswerModel): Explanation {
  const { a, b } = p, P = expectedOf(model, "count"), square = a === b, T = square ? P : expectedOf(model, "turn");
  return {
    heading: "Count equal groups",
    idea: ["Multiplying counts equal groups, so you can count by the group size."],
    statement: [num(a), op("×"), num(b)],
    diagram: factPicture(p, P),
    caption: `${count(a, "row")} with ${count(b, "dot")} in each row.`,
    timeline: beats(square ? 2 : 3),
    steps: [
      { id: "count", state: 1, answerStep: "count", result: P, math: [num(a), op("×"), num(b), op("="), num(P)],
        narration: `Count by ${b}s, one row at a time: ${Array.from({ length: Math.min(a, 3) }, (_, i) => (i + 1) * b).join(", ")}${a > 3 ? `, and on to ${P}` : ""}. That's ${count(a, "row")}, so ${a} × ${b} = ${P}.` },
      ...(square ? [] : [{ id: "turn", state: 2, answerStep: "turn", result: T, math: [num(b), op("×"), num(a), op("="), num(T)],
        narration: `Now look down the columns. There are ${count(b, "column")} of ${a}, and still ${count(T, "dot")}.` }]),
    ],
  };
}

export const lesson: LessonDefinition<FactProblem> = {
  id: "g3-facts",
  grade: 3,
  unit: "Multiplication and division",
  title: "Multiplication facts",
  pre: "g2-arrays",
  reference: createFact(4, 6),
  generate: generateFact,
  restore: raw => restoreVia(raw, ["a", "b"] as const, v => createFact(v.a, v.b)),
  display: p => [num(p.a), op("×"), num(p.b)],
  answers,
  explain,
  story: ({ a, b }) => ({ op: "×", text: `There are **${a}** boxes. Each box holds **${b}** crayons. How many crayons are there?` }),
};
