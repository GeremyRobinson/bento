import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildArray } from "../../../../explanations/diagrams/early-g3/array";
import { box, expectedOf, restoreVia, wholeIn } from "../_kit/steps";
import { count } from "../../../text";

/** a × t, where t is a whole number of tens: a groups of (t ÷ 10) tens. */
export interface Mult10Problem { a: number; t: number }

export function createMult10(a: number, t: number): Mult10Problem {
  wholeIn("a", a, 2, 9);
  if (!Number.isInteger(t) || t % 10 !== 0) throw new Error(`${t} is not a multiple of 10`);
  wholeIn("tens", t / 10, 2, 9);
  return { a, t };
}

/** Early problems use small facts (up to 5 × 5); later ones any fact up to 9 × 90. */
export function generateMult10(rng: Rng, index: number): Mult10Problem {
  const hi = index < 3 ? 5 : 9;
  return createMult10(rng.int(2, hi), rng.int(2, hi) * 10);
}

function answers({ a, t }: Mult10Problem): AnswerModel {
  const m = t / 10, f = a * m;
  return {
    steps: [
      box({
        id: "fact", label: "Multiply the tens", question: `${t} is ${count(m, "ten")}. First find ${a} × ${m}.`,
        prompt: x => [num(a), op("×"), num(m), op("="), x], ans: f,
        wrong: [[a + m, "Added instead of multiplied", `× means groups: ${count(a, "group")} of ${m}, not ${a} + ${m}.`]],
        hint: `Count by ${m}s, ${a} times.`,
        explain: `${a} × ${m} = ${f}, so ${a} × ${count(m, "ten")} is ${count(f, "ten")}.`,
      }),
      box({
        id: "tens", label: "Make them tens", question: `${count(f, "ten")} is how much?`,
        prompt: x => [num(a), op("×"), num(t), op("="), x], ans: a * t,
        wrong: [
          [f, "Forgot they are tens", `${f} is how many tens. Each ten is 10, so ${count(f, "ten")} is ${f * 10}.`],
          [f * 100, "One zero too many", `${count(f, "ten")} is ${f} × 10, which is ${f * 10}. You wrote ${count(f, "hundred")}.`],
          [a + t, "Added instead of multiplied", `${count(a, "group")} of ${t} is much more than ${a} + ${t}.`],
        ],
        hint: `Each ten is 10 ones. How much are ${count(f, "ten")}? Count by 10s, or think of ${f} in the tens place.`,
        explain: `${count(f, "ten")} = ${f * 10}: ${f} moves to the tens place, and 0 ones fill the ones place.`,
      }),
    ],
    finalParts: [-1],
  };
}

/** a rows of m tens chips: count the chips as a fact, then count them as tens. */
export function mult10Picture({ a, t }: Mult10Problem, f: number, P: number) {
  const m = t / 10;
  return buildArray({
    rows: a, cols: m, chip: "10",
    rowTotals: { from: 2, text: r => String((r + 1) * t), acc: r => r === a - 1 },
    lines: [
      { text: `${count(a, "row")} of ${count(m, "ten")}`, from: 0, until: 0, cls: "lbl" },
      { text: `${a} × ${m} = ${count(f, "ten")}`, from: 1, until: 1 },
      { text: `${count(f, "ten")} = ${P}`, from: 2 },
    ],
    alt: `${count(a, "row")} of ${count(m, "ten")}. That's ${a} × ${m} = ${count(f, "ten")}, and ${count(f, "ten")} is ${P}.`,
  });
}

function explain(p: Mult10Problem, model: AnswerModel): Explanation {
  const { a, t } = p, m = t / 10, f = expectedOf(model, "fact"), P = expectedOf(model, "tens");
  return {
    heading: "Multiply tens like ones",
    idea: ["Tens can be counted just like ones.", "Find the fact, then remember the answer is in tens."],
    statement: [num(a), op("×"), num(t), op("="), num(a), op("×"), num(m), text(" tens")],
    diagram: mult10Picture(p, f, P),
    caption: `${count(a, "row")} with ${count(m, "ten")} in each row.`,
    timeline: beats(3),
    steps: [
      { id: "fact", state: 1, answerStep: "fact", result: f, math: [num(a), op("×"), num(m), op("="), num(f)],
        narration: `Count the tens: ${count(a, "row")} of ${m} make ${count(f, "ten")}.` },
      { id: "tens", state: 2, answerStep: "tens", result: P, math: [num(a), op("×"), num(t), op("="), num(P)],
        narration: `Each ten is worth 10, so ${count(f, "ten")} is ${P}. Count by ${t}s down the rows to check.` },
    ],
  };
}

export const lesson: LessonDefinition<Mult10Problem> = {
  id: "g3-mult10",
  grade: 3,
  unit: "Multiplication and division",
  title: "Multiply by multiples of 10",
  pre: "g3-facts",
  reference: createMult10(4, 30),
  generate: generateMult10,
  restore: raw => restoreVia(raw, ["a", "t"] as const, v => createMult10(v.a, v.t)),
  display: p => [num(p.a), op("×"), num(p.t)],
  answers,
  explain,
  story: ({ a, t }) => ({ op: "×", text: `A shop packs **${t}** pencils in each box. How many pencils are in **${a}** boxes?` }),
};
