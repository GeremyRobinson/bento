import { num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import { expectedOf, ints, ns, round6 } from "../../_tape-family/steps";
import { count } from "../../../text";

/** P is p% of ?, with p dividing 100. */
export interface PercentWholeProblem { p: number; P: number }

export function createPercentWhole(p: number, P: number): PercentWholeProblem {
  if (!Number.isInteger(p) || !Number.isInteger(P) || p <= 0 || p >= 100 || 100 % p !== 0 || P <= 0) throw new Error(`not a find-the-whole problem: ${P} is ${p}%`);
  return { p, P };
}

/** Same ranges as the current app: 10, 20, 25 or 50 percent of a part 2–30. */
// the first three: halves and tenths of small wholes
export const generatePercentWhole = (rng: Rng, index = 3) => (index < 3 ? createPercentWhole(rng.pick([10, 50]), rng.int(2, 10)) : createPercentWhole(rng.pick([10, 20, 25, 50]), rng.int(2, 30)));

function answers({ p, P }: PercentWholeProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "parts", l: "Parts in 100%", a: s => [num(p), text("%"), op("×"), ...s, op("="), num(100), text("%")], ans: 100 / p, h: "How many of those parts make 100%? Count up by the percent you know.",
        w: [[100 - p, "Subtracted", `How many ${p}%s fit in 100%? Count them, don't take ${p} away.`]] }),
      ns({ id: "whole", l: "Find the whole", a: s => [num(P), op("×"), num(100 / p), op("="), ...s], ans: (P * 100) / p, h: `The whole is ${100 / p} of those parts.`,
        w: [[round6((P * p) / 100), "Took a percent again", `You want the whole, so it's bigger than ${P}.`]] }),
    ],
    finalParts: [-1],
  };
}

/** A short bar for p% holding P; beat 1 lays 100/p of them end to end to make 100%; beat 2 fills them in and adds up. */
export function percentWholePicture({ p, P }: PercentWholeProblem) {
  const k = 100 / p;
  return buildTape({
    rows: [
      { length: p / 100, parts: 1, fills: [{ a: 0, b: p / 100, tone: "on" }], each: [{ text: () => `${P}` }], label: [{ text: `${p}%` }] },
      { length: 1, parts: k, from: 1, fills: [{ a: 0, b: 1, tone: "on", from: 2 }],
        each: [{ text: () => `${P}`, from: 2 }], label: [{ text: "100%" }],
        total: [{ text: "?", until: 1 }, { text: `${P * k}`, from: 2, acc: true }] },
    ],
    guides: [{ at: p / 100, rows: [0, 1], from: 1 }],
    alt: `${p}% is ${P}. ${count(k, "block")} of ${p}% make 100%, so the whole is ${k} × ${P} = ${P * k}.`,
  });
}

function explain(pr: PercentWholeProblem, model: AnswerModel): Explanation {
  const { p, P } = pr, k = expectedOf(model.steps, "parts"), W = expectedOf(model.steps, "whole");
  return {
    heading: "Count up to 100%",
    idea: ["A percent is a part out of 100, so one part you know can count up to 100%."],
    statement: [num(P), text(" is "), num(p), text("% of ?")],
    diagram: percentWholePicture(pr),
    caption: `${count(k, "block")} of ${p}% make 100%.`,
    timeline: beats(3),
    steps: [
      { id: "parts", state: 1, answerStep: "parts", result: k, math: [num(p), text("%"), op("×"), num(k), op("="), num(100), text("%")],
        narration: `${p}% ${k === 1 ? "once" : `${k} times`} makes 100%: 100 ÷ ${p} = ${k}.` },
      { id: "whole", state: 2, answerStep: "whole", result: W, math: [num(P), op("×"), num(k), op("="), num(W)],
        narration: `Each ${p}% block is ${P}, so the whole is ${P} × ${k} = ${W}.` },
    ],
  };
}

export const lesson: LessonDefinition<PercentWholeProblem> = {
  id: "g6-pctwhole",
  grade: 6,
  unit: "Ratios and percents",
  title: "Find the whole",
  pre: "g6-pctof",
  // the current app's card and picture: 15 is 25% of 60
  reference: createPercentWhole(25, 15),
  generate: (rng, index) => generatePercentWhole(rng, index),
  restore: raw => {
    const r = ints(raw, ["p", "P"] as const);
    try { return r && createPercentWhole(r.p, r.P); } catch { return null; }
  },
  display: (pr): MathText => [num(pr.P), text(" is "), num(pr.p), text("% of ?")],
  answers,
  explain,
};
