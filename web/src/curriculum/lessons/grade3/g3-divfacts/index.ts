import { num, op } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildArray } from "../../../../explanations/diagrams/early-g3/array";
import { box, expectedOf, restoreVia, wholeIn } from "../_kit/steps";
import { count } from "../../../text";

/** a ÷ b, where a = b × q: share a into b equal groups. */
export interface DivFactProblem { a: number; b: number }

export function createDivFact(a: number, b: number): DivFactProblem {
  wholeIn("b", b, 2, 10);
  if (!Number.isInteger(a) || a % b !== 0) throw new Error(`${a} ÷ ${b} must come out even`);
  wholeIn("a ÷ b", a / b, 2, 10);
  return { a, b };
}

/** Early problems divide by 2, 5 or 10; later ones use any fact up to 100 ÷ 10. */
export function generateDivFact(rng: Rng, index: number): DivFactProblem {
  const b = index < 3 ? rng.pick([2, 5, 10]) : rng.int(3, 9);
  const q = index < 3 ? rng.int(2, 6) : rng.int(2, 10);
  return createDivFact(b * q, b);
}

function answers({ a, b }: DivFactProblem): AnswerModel {
  const q = a / b;
  return {
    steps: [
      box({
        id: "think", label: "Think multiplication", question: `${count(b, "group")} of what make ${a}?`,
        prompt: x => [num(b), op("×"), x, op("="), num(a)], ans: q,
        wrong: [
          [a - b, "Subtracted", `Taking ${b} away once leaves ${a - b}. You want ${b} equal groups that make ${a}.`],
          [q + 1, "One too many in each group", `${b} × ${q + 1} = ${b * (q + 1)}. That's more than ${a}.`],
          [q - 1, "One too few in each group", `${b} × ${q - 1} = ${b * (q - 1)}. That's less than ${a}.`],
          [a, "Wrote the total", `${a} is all the dots together. How many go in each of the ${count(b, "group")}?`],
        ],
        hint: `Count by ${b}s until you reach ${a}. Count how many jumps it took.`,
        explain: `Counting by ${b}s reaches ${a} after ${count(q, "jump")}, so ${b} × ${q} = ${a}.`,
      }),
      box({
        id: "divide", label: "Divide", question: `So ${a} shared into ${b} equal groups is…`,
        prompt: x => [num(a), op("÷"), num(b), op("="), x], ans: q,
        wrong: [
          [b, "Wrote the number of groups", `${b} is how many groups there are. How many are in each group?`],
          [a * b, "Multiplied", `Dividing shares ${a} out, so the answer is smaller than ${a}.`],
        ],
        hint: `It's the missing number from ${b} × ? = ${a}.`,
        explain: `${a} ÷ ${b} = ${q}, because ${b} × ${q} = ${a}.`,
      }),
    ],
    finalParts: [-1],
  };
}

/** a dots in b rows: the rows are circled as b equal groups, each holding q. */
export function divPicture({ a, b }: DivFactProblem, q: number) {
  return buildArray({
    rows: b, cols: q,
    rowBoxes: { from: 1 },
    rowTotals: { from: 1, text: () => String(q), acc: () => true },
    lines: [
      { text: `${count(a, "dot")}`, from: 0, until: 0, cls: "lbl" },
      { text: `${count(b, "group")} of ${q}: ${b} × ${q} = ${a}`, from: 1, until: 1 },
      { text: `${a} ÷ ${b} = ${q}`, from: 2 },
    ],
    alt: `${count(a, "dot")} shared into ${b} equal rows. Each row holds ${q}, so ${a} ÷ ${b} = ${q}.`,
  });
}

function explain(p: DivFactProblem, model: AnswerModel): Explanation {
  const { a, b } = p, q = expectedOf(model, "think"), d = expectedOf(model, "divide");
  return {
    heading: "Share into equal groups",
    idea: ["Dividing shares a number into equal groups, so every division fact has a times fact inside it."],
    statement: [num(a), op("÷"), num(b)],
    diagram: divPicture(p, q),
    caption: `Share ${count(a, "dot")} into ${b} equal groups.`,
    timeline: beats(3),
    steps: [
      { id: "think", state: 1, answerStep: "think", result: q, math: [num(b), op("×"), num(q), op("="), num(a)],
        narration: `Put the ${count(a, "dot")} in ${b} equal rows. Each row gets ${q}, because ${b} × ${q} = ${a}.` },
      { id: "divide", state: 2, answerStep: "divide", result: d, math: [num(a), op("÷"), num(b), op("="), num(d)],
        narration: `So ${a} ÷ ${b} = ${d}. Each group has ${d}.` },
    ],
  };
}

export const lesson: LessonDefinition<DivFactProblem> = {
  id: "g3-divfacts",
  grade: 3,
  unit: "Multiplication and division",
  title: "Division facts",
  pre: "g3-facts",
  reference: createDivFact(24, 4),
  generate: generateDivFact,
  restore: raw => restoreVia(raw, ["a", "b"] as const, v => createDivFact(v.a, v.b)),
  display: p => [num(p.a), op("÷"), num(p.b)],
  answers,
  explain,
  story: ({ a, b }) => ({ op: "÷", text: `**${a}** stickers are shared equally by **${b}** friends. How many stickers does each friend get?` }),
};
