// Dividing by a decimal (the current app's g5-divdec): multiply both numbers by 10, then divide whole numbers.
import { formatNumber as f, mark, num, op } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { chainExplanation } from "../../../../explanations/diagrams/chain/build";
import { expectedOf, oneBox, restoreVia, round6, wholeIn } from "../../_number-line/steps";
import { buildDoubleLine } from "../../../../explanations/diagrams/early-g4/double-line";

/** (d × qt)/10 ÷ d/10, so the answer is the whole number qt */
export interface DivDecimalProblem { d: number; qt: number }

export function createDivDecimal(d: number, qt: number): DivDecimalProblem {
  wholeIn("d", d, 2, 9);
  wholeIn("qt", qt, 2, 12);
  return { d, qt };
}

function answers({ d, qt }: DivDecimalProblem): AnswerModel {
  const x = (d * qt) / 10, y = d / 10;
  return {
    steps: [
      oneBox({ id: "divisor", label: "Make the divisor whole", prompt: s => [num(y), op("×"), num(10), op("="), s], ans: d, hint: "Move its decimal point one place right.",
        wrong: [[d * 10, "Moved the point too far", "Times 10 moves the point just one place."], [round6(y / 10), "Moved the point the wrong way", "Times 10 makes it bigger: the point moves right."]] }),
      oneBox({
        id: "other", label: "Do the same to the other number", prompt: s => [num(x), op("×"), num(10), op("="), s], ans: d * qt,
        hint: "Multiply it by 10 too, so the answer doesn't change.", wrong: [[round6(x), "Changed only one number", "Multiply both numbers by 10."]],
      }),
      oneBox({ id: "divide", label: "Divide", prompt: s => [num(d * qt), op("÷"), num(d), op("="), s], ans: qt, hint: `How many ${d}s make ${d * qt}?`,
        wrong: [[round6(qt / 10), "Put the point back", "Both numbers grew ten times, so the answer didn't change: there's no point to put back."], [d * qt * d, "Multiplied", `How many ${d}s fit in ${d * qt}? That's dividing.`]] }),
    ],
    finalParts: [-1],
  };
}

function explain(p: DivDecimalProblem, model: AnswerModel) {
  const x = (p.d * p.qt) / 10, y = p.d / 10;
  const d = expectedOf(model, "divisor"), n = expectedOf(model, "other"), qt = expectedOf(model, "divide");
  return chainExplanation({
    heading: "Make the divisor a whole number",
    idea: ["Making both numbers ten times bigger doesn't change how many times one fits in the other."],
    statement: [num(x), op("÷"), num(y)],
    caption: `Move both points one place: ${f(x)} ÷ ${f(y)} and ${n} ÷ ${d} have the same answer.`,
    alt: `${f(x)} ÷ ${f(y)} becomes ${n} ÷ ${d} = ${qt}.`,
    diagram: buildDoubleLine({
      n: qt, per: d, extra: 0, top: "", bottom: "", between: "× 10",
      topText: j => f(round6(j * y)), bottomText: j => String(j * d),
      beats: { one: 0, all: 1, extra: null, total: 2 }, hops: { from: 2 },
      lines: [{ text: `${f(y)} × 10 = ${d}`, from: 0, until: 0 }, { text: `${f(x)} × 10 = ${n}`, from: 1, until: 1 }],
      total: `${n} ÷ ${d} = ${qt}, and ${f(x)} ÷ ${f(y)} = ${qt}`,
      alt: `A double number line: the top counts by ${f(y)} up to ${f(x)}, the bottom by ${d} up to ${n}, tick for tick. ${qt} hops on each line, so both divisions are ${qt}.`,
    }),
    beats: [
      { id: "divisor", narration: `Make the divisor whole: ${f(y)} × 10 = ${d}.`, math: [num(y), op("×"), num(10), op("="), num(d)],
        lines: [[num(x), op("÷"), num(y)], [num(y), op("×"), num(10), op("="), num(d)]], answerStep: "divisor", result: d },
      { id: "other", narration: `Do the same to ${f(x)}: ${f(x)} × 10 = ${n}.`, math: [num(x), op("×"), num(10), op("="), num(n)],
        lines: [[mark(n), op("÷"), mark(d)]], answerStep: "other", result: n },
      { id: "divide", narration: `${n} ÷ ${d} = ${qt}.`, math: [num(n), op("÷"), num(d), op("="), num(qt)],
        lines: [[num(qt)]], answerStep: "divide", result: qt },
    ],
  });
}

export const lesson: LessonDefinition<DivDecimalProblem> = {
  id: "g5-divdec",
  grade: 5,
  unit: "Decimals",
  title: "Dividing by a decimal",
  pre: "g5-divide",
  reference: createDivDecimal(6, 8), // 4.8 ÷ 0.6 = 8, the current app's example
  generate: rng => { const d = rng.int(2, 9), qt = rng.int(2, 12); return createDivDecimal(d, qt); },
  restore: raw => restoreVia(raw, ["d", "qt"] as const, v => createDivDecimal(v.d, v.qt)),
  display: p => [num((p.d * p.qt) / 10), op("÷"), num(p.d / 10)],
  answers,
  explain,
  story: p => ({ op: "÷", text: `You have **${f((p.d * p.qt) / 10)}** liters of juice. Each cup holds **${f(p.d / 10)}** liters. How many cups can you fill?` }),
};
