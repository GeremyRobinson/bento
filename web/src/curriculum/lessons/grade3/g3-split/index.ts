import { answer, num, op } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildAreaGrid } from "../../../../explanations/diagrams/area-model/grid";
import { expectedOf, numStep, readNumbers } from "../../area-common/steps";
import { count, aNum, cap } from "../../../text";

/** a × b, with b split into 5 + (b − 5). */
export interface SplitFactProblem { a: number; b: number }

export function createSplitFact(a: number, b: number): SplitFactProblem {
  if (!Number.isInteger(a) || a < 1 || !Number.isInteger(b) || b < 6) throw new Error("a × b needs a whole a and b of 6 or more");
  return { a, b };
}

/** The current app's range, a 3–9 and b 6–9; the first three problems are small, a 2–5 and b 6 or 7. */
export const generateSplitFact = (rng: Rng, index = 9): SplitFactProblem =>
  (index < 3 ? { a: rng.int(2, 5), b: rng.int(6, 7) } : { a: rng.int(3, 9), b: rng.int(6, 9) });

export function splitFactAnswers({ a, b }: SplitFactProblem): AnswerModel {
  const r = b - 5;
  return {
    steps: [
      numStep({ id: "split", label: "Split each row", question: `${b} is 5 and how many more?`, prompt: x => [num(b), op("="), num(5), op("+"), x], ans: r,
        wrong: [[b, "Wrote the whole row", `${b} is the whole row. How many are left after the first 5?`], [5, "Wrote the first part", "5 is the part you cut off first. How many are on the other side of the cut?"]],
        hint: `Cut each row of ${b} after 5. How many are on the other side?`, explain: `${b} = 5 + ${r}: the cut leaves ${r} in each row.`, work: [num(b), op("="), num(5), op("+"), answer("x", r)] }),
      numStep({ id: "five", label: "Multiply by 5", question: `How many in the ${count(a, "row")} of 5?`, prompt: x => [num(a), op("×"), num(5), op("="), x], ans: a * 5,
        wrong: [[a + 5, "Added instead of multiplied", `× means ${count(a, "group")} of 5, not ${a} + 5.`]],
        hint: `Count by 5s, ${a} times.`, explain: `${count(a, "row")} of 5 is ${a} fives: ${a} × 5 = ${a * 5}.`, work: [num(a), op("×"), num(5), op("="), num(a * 5)] }),
      numStep({ id: "rest", label: `Multiply by ${r}`, question: `How many in the ${count(a, "row")} of ${r}?`, prompt: x => [num(a), op("×"), num(r), op("="), x], ans: a * r,
        wrong: [[a + r, "Added instead of multiplied", `× means ${count(a, "group")} of ${r}.`]],
        hint: `${count(a, "group")} of ${r}.`, explain: `${count(a, "row")} of ${r} is the other small array: ${a} × ${r} = ${a * r}.`, work: [num(a), op("×"), num(r), op("="), num(a * r)] }),
      numStep({ id: "sum", label: "Add the parts", question: "Put the two small arrays back together.", prompt: x => [num(a * 5), op("+"), num(a * r), op("="), x], ans: a * b,
        wrong: [
          [a * 5, "Kept only the first part", `That's just the first part. Add the ${count(a, "row")} of ${r} too.`],
          [a * r, "Kept only the second part", `That's just the second part. Add the ${count(a, "row")} of 5 too.`],
          [a * b + a, "Added a part wrong", `Check each part again: ${count(a, "row")} of ${r} is ${a * r}.`],
        ],
        hint: `${b} is 5 + ${r}, so add the two answers.`, explain: `The two small arrays make the whole ${a} by ${b} array: ${a * 5} + ${a * r} = ${a * b}.`, work: [num(a), op("×"), num(b), op("="), answer("x", a * b)] }),
    ],
    finalParts: [-1],
  };
}

export function explainSplitFact(p: SplitFactProblem, answers: AnswerModel): Explanation {
  const { a, b } = p, r = b - 5;
  const five = expectedOf(answers.steps, "five"), rest = expectedOf(answers.steps, "rest"), sum = expectedOf(answers.steps, "sum");
  return {
    heading: "Break a hard fact apart",
    idea: ["A big array is two smaller arrays side by side. Find each small one with a fact you know, then put them back together."],
    statement: [num(a), op("×"), num(b), op("="), num(a), op("×"), num(5), op("+"), num(a), op("×"), num(r)],
    diagram: buildAreaGrid({
      cols: [{ label: "5", size: 5 }, { label: String(r), size: r }],
      rows: [{ label: String(a), size: a }],
      cells: [[{ text: String(five), from: 1, focus: [1] }, { text: String(rest), from: 2, focus: [2] }]],
      units: 0,
      lines: [{ text: `${a} × ${b} = ${five} + ${rest} = ${sum}`, from: 3 }],
      alt: `${cap(aNum(a))} by ${b} rectangle cut into ${a} by 5 = ${five} and ${a} by ${r} = ${rest}. Together ${sum}.`,
    }),
    caption: `${b} is 5 + ${r}, so the ${a} by ${b} rectangle splits into two easy parts.`,
    timeline: beats(4),
    steps: [
      { id: "split", narration: `${count(a, "row")} of ${b} is hard to count. Cut each row after 5: ${b} is 5 and ${r}.`, math: [num(b), op("="), num(5), op("+"), num(r)], state: 0, answerStep: "split", result: r },
      { id: "five", narration: `${count(a, "row")} of 5: ${a} × 5 = ${five}.`, math: [num(a), op("×"), num(5), op("="), num(five)], state: 1, answerStep: "five", result: five },
      { id: "rest", narration: `${count(a, "row")} of ${r}: ${a} × ${r} = ${rest}.`, math: [num(a), op("×"), num(r), op("="), num(rest)], state: 2, answerStep: "rest", result: rest },
      { id: "sum", narration: `Put the parts back together: ${five} + ${rest} = ${sum}.`, math: [num(five), op("+"), num(rest), op("="), num(sum)], state: 3, answerStep: "sum", result: sum },
    ],
  };
}

export const lesson: LessonDefinition<SplitFactProblem> = {
  id: "g3-split",
  grade: 3,
  unit: "Multiplication and division",
  title: "Multiply by breaking apart",
  pre: "g3-facts",
  reference: createSplitFact(7, 8),
  generate: (rng, index) => generateSplitFact(rng, index),
  restore: raw => { const r = readNumbers(raw, ["a", "b"] as const); try { return r && createSplitFact(r.a, r.b); } catch { return null; } },
  display: p => [num(p.a), op("×"), num(p.b)],
  answers: splitFactAnswers,
  explain: explainSplitFact,
  story: ({ a, b }) => ({ op: "×", text: `There are **${a}** bags. Each bag has **${b}** apples. How many apples are there?` }),
};
