import { formatNumber as f, m, num, op, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { ns, v } from "../../algebra-kit/steps";
import { attempt, readInts, rule } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { block, buildBalance, xTiles, type BalanceFrame } from "../../../../explanations/diagrams/algebra/balance";

/** ax + b = cx + d with a > c, so x = (d − b) ÷ (a − c). */
export interface BothSidesEquation { kind: "equation.bothSides"; a: number; b: number; c: number; d: number; x: number }

export function createBothSides(a: number, b: number, c: number, x: number): BothSidesEquation {
  rule(a > c && c >= 1 && b >= 1 && x >= 1, "a > c ≥ 1, b ≥ 1, x ≥ 1");
  return { kind: "equation.bothSides", a, b, c, d: (a - c) * x + b, x };
}

/** Same ranges as the current app: a 3–9, c below a, x 1–10, b 1–20. */
export function generateBothSides(rng: Rng): BothSidesEquation {
  const a = rng.int(3, 9), c = rng.int(1, a - 1), x = rng.int(1, 10), b = rng.int(1, 20);
  return createBothSides(a, b, c, x);
}

export function restoreBothSides(raw: unknown): BothSidesEquation | null {
  const r = readInts(raw, ["a", "b", "c", "d", "x"] as const);
  return r && r.d === (r.a - r.c) * r.x + r.b ? attempt(() => createBothSides(r.a, r.b, r.c, r.x)) : null;
}

/** "cx", written "x" when c is 1. */
const cx = (c: number): MathText => (c === 1 ? [v()] : [num(c), v()]);
const cxText = (c: number) => `${c === 1 ? "" : f(c)}x`;
const equation = ({ a, b, c, d }: BothSidesEquation): MathText => [num(a), v(), op("+"), num(b), op("="), ...cx(c), op("+"), num(d)];

export function bothSidesAnswers({ a, b, c, d, x }: BothSidesEquation): AnswerModel {
  return {
    steps: [
      ns({ id: "gather", l: "Get x on one side", n: `Subtract ${cxText(c)} from both sides.`, a: s => [...s, v(), op("+"), num(b), op("="), num(d)], ans: a - c,
        h: `${f(a)} − ${f(c)}.`, w: [[a + c, "Added instead of subtracted", `Subtract ${cxText(c)} from both sides.`]] }),
      ns({ id: "move", l: "Move the number", a: s => [num(a - c), v(), op("="), ...s], ans: d - b, h: `Subtract ${f(b)} from both sides.`,
        w: [[d + b, "Added instead of subtracted", `To undo + ${f(b)}, subtract ${f(b)}.`]] }),
      ns({ id: "divide", l: "Divide", a: s => [v(), op("="), ...s], ans: x, h: `${f(d - b)} ÷ ${f(a - c)}.` }),
    ],
    finalParts: [-1],
  };
}

export function explainBothSides(p: BothSidesEquation, model: AnswerModel) {
  const { a, b, c, d } = p;
  const [k, rest, x] = model.steps.map(s => s.slots[0]!.expected!) as [number, number, number];
  const split: BalanceFrame = k > 1
    ? { left: xTiles(k).map(t => [t]), right: Array.from({ length: k }, () => [block(x)]), note: `split both sides into ${f(k)}: x = ${f(x)}` }
    : { left: [xTiles(1)], right: [[block(x)]], note: `x = ${f(x)}` };
  const diagram = buildBalance([
    { left: [xTiles(a), [block(b)]], right: [xTiles(c), [block(d)]], note: `${f(a)}x + ${f(b)} = ${cxText(c)} + ${f(d)}` },
    { left: [xTiles(k), xTiles(c, true), [block(b)]], right: [xTiles(c, true), [block(d)]], note: `take ${cxText(c)} off both` },
    { left: [xTiles(k), [block(b, { off: true })]], right: [[block(rest)], [block(b, { off: true })]], note: `take ${f(b)} off both` },
    split,
  ], `A balance with ${f(a)} x tiles and ${f(b)} against ${f(c)} x tiles and ${f(d)}. Taking ${cxText(c)} and then ${f(b)} off both pans leaves ${f(k)} x's against ${f(rest)}, so x = ${f(x)}.`);
  return beatExplanation({
    heading: "Gather the x's, then solve",
    idea: ["An equation is a balance: taking the same thing off both sides keeps it level.", "So take x's off one side until they're all on the other, then solve the one-step equation that's left."],
    statement: equation(p),
    diagram,
    alt: diagram.alt,
    steps: [
      { id: "equation", narration: `There are x's on both sides. The pans balance.`, math: equation(p) },
      { id: "gather", narration: `Subtract ${cxText(c)} from both sides: ${f(a)} − ${f(c)} = ${f(k)}, so ${cxText(k)} + ${f(b)} = ${f(d)}.`, math: m(...cx(k), op("+"), b, op("="), d), answerStep: "gather", result: k },
      { id: "move", narration: `Subtract ${f(b)} from both sides: ${cxText(k)} = ${f(rest)}.`, math: m(...cx(k), op("="), d, op("−"), b, op("="), rest), answerStep: "move", result: rest },
      k > 1
        ? { id: "divide", narration: `Divide both sides by ${f(k)}: x = ${f(x)}.`, math: m(v(), op("="), rest, op("÷"), k, op("="), x), answerStep: "divide", result: x }
        : { id: "divide", narration: `Only one x is left, so x = ${f(x)}.`, math: m(v(), op("="), x), answerStep: "divide", result: x },
    ],
  });
}

export const lesson: LessonDefinition<BothSidesEquation> = {
  id: "g8-both",
  grade: 8,
  unit: "Linear equations",
  title: "Variables on both sides",
  pre: "g7-eq",
  reference: createBothSides(5, 3, 2, 5),
  generate: rng => generateBothSides(rng),
  restore: restoreBothSides,
  display: equation,
  answers: bothSidesAnswers,
  explain: explainBothSides,
};
