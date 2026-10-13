import { answer, num, op, slot, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep } from "../../../schemas/lesson";
import { leadingDigit, placeName } from "../../../generators/place-value";
import { formatNumber as f } from "../../../schemas/math-text";
import type { SplitMultiplicationProblem } from "./problem";

const plusChain = (values: number[]): MathText =>
  values.flatMap((v, i) => (i ? [op("+"), num(v)] : [num(v)]));

const zerosOf = (n: number) => String(n).length - 1;
const zerosWord = (z: number) => (z === 1 ? "a zero" : `${z} zeros`);
const COUNT = ["", "one", "two", "three", "four", "five", "six"];

/**
 * The derived answer model: one step per part of the area model (row by row, as the picture reads), then the sum.
 * Every number comes from the problem.
 */
export function splitMultiplicationAnswers(p: SplitMultiplicationProblem): AnswerModel {
  const steps: AnswerStep[] = p.cells.map(({ first, second }, i) => {
    const expected = p.partialProducts[i]!;
    const zeros = zerosOf(first) + zerosOf(second);
    const facts = leadingDigit(first) * leadingDigit(second);
    const hint = zeros === 0
      ? (first === 1 || second === 1 ? "Times 1 leaves a number as it is." : `${f(first)} groups of ${f(second)}: skip-count by ${f(second)}s.`)
      : `Do ${leadingDigit(first)} × ${leadingDigit(second)}, then add ${zerosWord(zeros)}.`;
    const known = zeros === 0
      ? (first + second === expected + 1 ? [] : [{ values: { x: first + second }, kind: "Added instead of multiplied", message: `This part is ${f(first)} times ${f(second)}, not plus.` }])
      : [{ values: { x: facts }, kind: "Lost the place value", message: `That's ${leadingDigit(first)} × ${leadingDigit(second)}. The part is ${f(first)} by ${f(second)}, so add ${zerosWord(zeros)}.` },
         ...(zeros > 1 ? [{ values: { x: facts * 10 }, kind: "Lost a zero", message: `Tens times tens makes hundreds: add ${zerosWord(zeros)} to ${facts}.` }] : [])];
    return {
      id: `partial-${i}`,
      label: `${placeName(first)[0]!.toUpperCase()}${placeName(first).slice(1)} × ${placeName(second)}`,
      prompt: [num(first), op("×"), num(second), op("="), slot("x")],
      slots: [{ id: "x", expected }],
      known: known.filter(k => k.values.x !== expected),
      hint,
      look: `Look again at the lit part: it's ${f(first)} across and ${f(second)} down.`,
      explain: `${f(first)} × ${f(second)} = ${f(expected)}.`,
      work: [num(first), op("×"), num(second), op("="), answer("x", expected)],
    };
  });
  if (p.cells.length > 1) {
    const n = p.cells.length;
    steps.push({
      id: "sum",
      label: "Add the parts",
      prompt: [...plusChain(p.partialProducts), op("="), slot("x")],
      slots: [{ id: "x", expected: p.product }],
      // the commonest slip: a part left out
      known: p.partialProducts.map(x => ({ values: { x: p.product - x }, kind: "Left out a part", message: `${COUNT[n] ?? n} parts, ${COUNT[n] ?? n} numbers to add. Did you add ${f(x)}?`.replace(/^./, c => c.toUpperCase()) }))
        .filter((k, i, all) => k.values.x !== p.product + 1 && all.findIndex(o => o.values.x === k.values.x) === i),
      hint: "Line them up by place value and add them all.",
      look: `Look again: add all ${COUNT[n] ?? n} parts in the picture.`,
      explain: `${p.partialProducts.map(f).join(" + ")} = ${f(p.product)}.`,
      work: [...plusChain(p.partialProducts), op("="), answer("x", p.product)],
    });
  }
  return { steps, finalParts: [-1] };
}
