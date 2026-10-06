import { answer, num, op, slot, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep } from "../../../schemas/lesson";
import { leadingDigit, placeName } from "../../../generators/place-value";
import { formatNumber as f } from "../../../schemas/math-text";
import type { SplitMultiplicationProblem } from "./problem";

const plusChain = (values: number[]): MathText =>
  values.flatMap((v, i) => (i ? [op("+"), num(v)] : [num(v)]));

/**
 * The derived answer model. Step labels, hints and the known place-value slip
 * keep the current app's wording; every number comes from the problem.
 */
export function splitMultiplicationAnswers(p: SplitMultiplicationProblem): AnswerModel {
  const a = p.firstFactor;
  const steps: AnswerStep[] = p.parts.map((part, i) => {
    const expected = p.partialProducts[i]!;
    const zeros = String(part).length - 1;
    const digit = leadingDigit(part);
    const hint = zeros === 0
      ? `${f(a)} × ${f(part)}.`
      : `Do ${f(a)} × ${f(digit)}, then add ${zeros === 1 ? "a zero" : `${zeros} zeros`}.`;
    return {
      id: `partial-${i}`,
      label: `Multiply by the ${placeName(part)}`,
      prompt: [num(a), op("×"), num(part), op("="), slot("x")],
      slots: [{ id: "x", expected }],
      // a ones part of 1 has no adding slip to name (a + 1 is also the off-by-one try)
      known: zeros === 0 ? (part === 1 ? [] : [{ values: { x: a + part }, kind: "Added instead of multiplied", message: `This part is ${f(a)} times ${f(part)}, not plus.` }]) : [{
        values: { x: a * digit },
        kind: "Lost the place value",
        message: `That's ${f(a)} × ${f(digit)}. The ${placeName(part)} digit stands for ${f(part)}, so add ${zeros === 1 ? "a zero" : `${zeros} zeros`}.`,
      }],
      hint,
      explain: `${hint} That makes ${f(expected)}.`,
      work: [num(a), op("×"), num(part), op("="), answer("x", expected)],
    };
  });
  if (p.parts.length > 1) {
    const hint = p.parts.length === 2 ? "Add the two partial products." : "Add the partial products.";
    steps.push({
      id: "sum",
      label: "Add the parts",
      prompt: [...plusChain(p.partialProducts), op("="), slot("x")],
      slots: [{ id: "x", expected: p.product }],
      // the commonest slip: a part left out
      known: p.partialProducts.map(x => ({ values: { x: p.product - x }, kind: "Left out a part", message: `Add every part: ${p.partialProducts.map(f).join(" + ")}.` }))
        // not where the current app's place-value or off-by-one tries land, so those keep their recorded messages
        .filter((k, i, all) => k.values.x !== p.product + 1 && !p.parts.some(part => k.values.x === a * leadingDigit(part)) && all.findIndex(o => o.values.x === k.values.x) === i),
      hint,
      explain: `${hint} That makes ${f(p.product)}.`,
      work: [...plusChain(p.partialProducts), op("="), answer("x", p.product)],
    });
  }
  return { steps, finalParts: [-1] };
}
