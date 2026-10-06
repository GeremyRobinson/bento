import { num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import { expectedOf, ints, ns } from "../../_tape-family/steps";
import { count, isAre } from "../../../text";

export const PERCENTS = [10, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90];

/** p% of W, found from 10% (or from 25% for 25 and 75). */
export interface PercentOfProblem { p: number; W: number }

export function createPercentOf(p: number, W: number): PercentOfProblem {
  if (!Number.isInteger(p) || !Number.isInteger(W) || p <= 0 || p >= 100 || (p % 10 !== 0 && p % 25 !== 0) || W <= 0) throw new Error(`not a percent-of problem: ${p}% of ${W}`);
  return { p, W };
}

/** Same ranges as the current app: one of its percents, of 20–400 in steps of 20. */
export const generatePercentOf = (rng: Rng) => createPercentOf(rng.pick(PERCENTS), 20 * rng.int(1, 20));

export const baseOf = (p: number) => (p % 10 === 0 ? 10 : 25);

function answers({ p, W }: PercentOfProblem): AnswerModel {
  const base = baseOf(p), part = (W * base) / 100;
  return {
    steps: [
      ns({ id: "base", l: `Find ${base}%`, a: s => [num(base), text("% of "), num(W), op("="), ...s], ans: part,
        h: base === 10 ? `10% is one tenth: ${W} ÷ 10.` : `25% is one quarter: ${W} ÷ 4.`,
        w: [[W * base, "Multiplied instead of divided", `${base}% is a part of ${W}, so it's smaller than ${W}.`]] }),
      ns({ id: "scale", l: `Scale up to ${p}%`, a: s => [num(p / base), op("×"), num(part), op("="), ...s], ans: (W * p) / 100, h: `${p}% is ${count(p / base, "group")} of ${base}%.`,
        w: [...(p > base ? [[part * p, "Multiplied by the percent", `${p}% is ${p / base} blocks of ${base}%. Multiply ${part} by ${p / base}, not ${p}.`] as [number, string, string]] : []),
          [W - (W * p) / 100, "Found what's left", `That's the part not taken. ${p}% is the shaded part.`]] }),
    ],
    finalParts: [-1],
  };
}

/** A bar for W cut into blocks of base% (10 or 4 blocks). Beat 1 names each block's value, beat 2 shades p% of the bar. */
export function percentOfPicture({ p, W }: PercentOfProblem) {
  const base = baseOf(p), part = (W * base) / 100, blocks = 100 / base;
  return buildTape({
    rows: [{ length: 1, parts: blocks, fills: [{ a: 0, b: p / 100, tone: "on", from: 2 }], each: [{ text: () => `${part}`, from: 1 }], label: [{ text: `${W}` }] }],
    brackets: [
      { row: 0, a: 0, b: base / 100, text: `${base}%`, side: "above", from: 1 },
      { row: 0, a: 0, b: p / 100, text: `${p}% = ${(W * p) / 100}`, side: "below", from: 2, acc: true },
    ],
    alt: `A bar for ${W} cut into ${count(blocks, "block")} of ${base}%, each ${part}; ${count(p / base, "block")} ${isAre(p / base)} shaded: ${(W * p) / 100}.`,
  });
}

function explain(pr: PercentOfProblem, model: AnswerModel): Explanation {
  const { p, W } = pr, base = baseOf(p), part = expectedOf(model.steps, "base"), R = expectedOf(model.steps, "scale");
  return {
    heading: base === 10 ? "Start from 10%" : "Start from 25%",
    idea: [
      `Percent means out of 100: ${p}% of a number is ${p} of every 100 parts of it, the same as ${p}/100.`,
      base === 10 ? "10% is one tenth, so find 10% and build the percent from it." : "25% is one quarter, so find 25% and build the percent from it.",
    ],
    statement: [num(p), text("% of "), num(W)],
    diagram: percentOfPicture(pr),
    caption: `Each block is ${base}%, which is ${part}.`,
    timeline: beats(3),
    steps: [
      { id: "base", state: 1, answerStep: "base", result: part, math: [num(base), text("% of "), num(W), op("="), num(part)],
        narration: base === 10 ? `Cut ${W} into 10 equal blocks: each is 10%, which is ${W} ÷ 10 = ${part}.` : `Cut ${W} into 4 equal blocks: each is 25%, which is ${W} ÷ 4 = ${part}.` },
      { id: "scale", state: 2, answerStep: "scale", result: R, math: [num(p / base), op("×"), num(part), op("="), num(R)],
        narration: `${p}% is ${p / base} of those blocks: ${p / base} × ${part} = ${R}.` },
    ],
  };
}

export const lesson: LessonDefinition<PercentOfProblem> = {
  id: "g6-pctof",
  grade: 6,
  unit: "Ratios and percents",
  title: "Percent of a number",
  pre: "g5-fracof",
  // the current app's card and picture: 30% of 80 = 24
  reference: createPercentOf(30, 80),
  generate: rng => generatePercentOf(rng),
  restore: raw => {
    const r = ints(raw, ["p", "W"] as const);
    try { return r && createPercentOf(r.p, r.W); } catch { return null; }
  },
  display: (pr): MathText => [num(pr.p), text("% of "), num(pr.W)],
  answers,
  explain,
};
