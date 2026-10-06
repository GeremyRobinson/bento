import { formatNumber as f, m, mark, num, op, sup, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { fpm, ns, pm, supText, v } from "../../algebra-kit/steps";
import { attempt, nz, readInts, rule } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { chainRulePicture } from "./picture";
import { withEasyStart } from "../../easy-start";

/** f(x) = (ax + b)ⁿ, so f′(x) = n·a·(ax + b)ⁿ⁻¹. */
export interface ChainRule { kind: "derivatives.chain"; a: number; b: number; n: number }

export function createChainRule(a: number, b: number, n: number): ChainRule {
  rule(a >= 2 && b !== 0 && n >= 2, "a ≥ 2, b ≠ 0, n ≥ 2");
  return { kind: "derivatives.chain", a, b, n };
}

/** Same ranges as the current app: a 2–5, b −9–9 (not 0), n 2–5. */
export const generateChainRule = (rng: Rng) => { const a = rng.pick([2, 3, 4, 5]), b = nz(rng, -9, 9), n = rng.int(2, 5); return createChainRule(a, b, n); };

export function restoreChainRule(raw: unknown): ChainRule | null {
  const r = readInts(raw, ["a", "b", "n"] as const);
  return r && attempt(() => createChainRule(r.a, r.b, r.n));
}

const inner = (a: number, b: number): MathText => [num(a), v(), ...pm(b)];
const wrapped = (a: number, b: number, e: MathText | number, inside: MathText = inner(a, b)): MathText => [text("("), ...inside, text(")"), sup(e)];
const innerText = (a: number, b: number) => `${f(a)}x ${fpm(b)}`;

export function chainRuleAnswers({ a, b, n }: ChainRule): AnswerModel {
  return {
    steps: [
      ns({ id: "outside", l: "Outside: power rule", a: s => [num(n), ...wrapped(a, b, s)], ans: n - 1, h: `Treat (${innerText(a, b)}) as one block, u. The power rule on uⁿ lowers the exponent by 1.`, w: [[n, "Kept the exponent", `Lower the exponent by 1: ${f(n)} − 1.`]] }),
      ns({ id: "inside", l: "Inside's derivative", a: s => [text("d/dx"), text("("), ...inner(a, b), text(")"), op("="), ...s], ans: a, h: "ax + b is a line, and its slope is a.", w: [[b, "Took the number", `The derivative of the number ${f(b)} is 0. The derivative of ${f(a)}x is ${f(a)}.`]] }),
      ns({ id: "front", l: "Multiply in front", a: s => [text("f′(x)"), op("="), ...s, ...wrapped(a, b, n - 1)], ans: n * a, h: `Multiply the ${f(n)} that came down by the inside's slope, ${f(a)}.`,
        w: [[n, "Forgot the inside", "The chain rule multiplies by the inside's derivative too."], [a, "Dropped the power's number", `Keep the ${f(n)} that the power rule brought down too: ${f(n)} × ${f(a)}.`]] }),
    ],
    finalParts: [-1],
  };
}

export function explainChainRule(p: ChainRule, model: AnswerModel) {
  const { a, b, n } = p;
  const [e, da, front] = model.steps.map(s => s.slots[0]!.expected!) as [number, number, number];
  return beatExplanation({
    heading: "Outside, then times inside",
    idea: ["f is a function inside a function. When x moves a little, the inside moves by its own slope, and the outside responds to the inside's change.", "Rates of change multiply, like gears: f′ = (the outside's derivative) × (the inside's derivative)."],
    statement: [text("f(x)"), op("="), ...wrapped(a, b, n)],
    caption: `The power rule on the outside, times the inside's derivative, ${f(da)}.`,
    diagram: chainRulePicture({ a, b, n, e, da, front, inner: innerText(a, b) }),
    alt: `(${innerText(a, b)})${supText(n)}: ${f(n)}(${innerText(a, b)})${supText(e)} × ${f(da)} = ${f(front)}(${innerText(a, b)})${supText(e)}.`,
    steps: [
      { id: "problem", narration: `The outside is a power. The inside is ${innerText(a, b)}.`, math: wrapped(a, b, n, [mark(inner(a, b))]) },
      { id: "outside", narration: `Outside first: the power rule brings ${f(n)} down and lowers the exponent to ${f(e)}.`, math: [num(n), ...wrapped(a, b, e)], answerStep: "outside", result: e },
      { id: "why", narration: `Why multiply: the inside ${innerText(a, b)} moves ${f(a)} for each 1 that x moves, so whatever the outside does happens ${f(a)} times as fast.`, math: m(text("d/dx"), text("("), ...inner(a, b), text(")"), op("="), a), line: null },
      { id: "inside", narration: `Then multiply by the inside's derivative: the derivative of ${innerText(a, b)} is ${f(da)}.`, math: m(text("d/dx"), text("("), ...inner(a, b), text(")"), op("="), da),
        line: [num(n), ...wrapped(a, b, e), op("·"), mark(da)], answerStep: "inside", result: da },
      { id: "front", narration: `${f(n)} × ${f(da)} = ${f(front)} goes in front: f′(x) = ${f(front)}(${innerText(a, b)})${supText(e)}.`, math: [text("f′(x)"), op("="), num(front), ...wrapped(a, b, e)], answerStep: "front", result: front },
    ],
  });
}

export const lesson: LessonDefinition<ChainRule> = withEasyStart({
  id: "g12-chain",
  grade: 12,
  unit: "Derivatives",
  title: "Chain rule",
  reference: createChainRule(3, 1, 4),
  generate: rng => generateChainRule(rng),
  restore: restoreChainRule,
  display: p => [text("f(x)"), op("="), ...wrapped(p.a, p.b, p.n)],
  displayNote: () => "Find f′(x).",
  answers: chainRuleAnswers,
  explain: explainChainRule,
});
