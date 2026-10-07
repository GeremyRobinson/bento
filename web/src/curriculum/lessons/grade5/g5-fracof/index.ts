import { frac, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import { expectedOf, ints, ns } from "../../_tape-family/steps";
import { coprimeTop } from "../../grade4/g4-equiv";
import { count, isAre } from "../../../text";

/** n/d of W: split W into d equal groups, take n of them. W is a multiple of d. */
export interface FractionOfNumberProblem { n: number; d: number; W: number }

export function createFractionOfNumber(n: number, d: number, W: number): FractionOfNumberProblem {
  if (![n, d, W].every(Number.isInteger) || d < 2 || n < 1 || n >= d || W < d || W % d !== 0) throw new Error(`not a fraction-of problem: ${n}/${d} of ${W}`);
  return { n, d, W };
}

/** Same ranges as the current app: bottom 2–9, a top in lowest terms, the number 2–12 groups of the bottom. */
export function generateFractionOfNumber(rng: Rng, index = 3): FractionOfNumberProblem {
  // the first three: one group (a unit fraction) of a small number
  if (index < 3) { const d = rng.int(2, 5); return createFractionOfNumber(1, d, d * rng.int(2, 6)); }
  const d = rng.int(2, 9), n = coprimeTop(rng, d);
  return createFractionOfNumber(n, d, d * rng.int(2, 12));
}

function answers({ n, d, W }: FractionOfNumberProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "groups", l: "Split into equal groups", a: s => [num(W), op("÷"), num(d), op("="), ...s], ans: W / d, h: `The bottom number tells how many equal groups: ${d}.`,
        w: [[W * d, "Multiplied instead of divided", `Split ${W} into ${d} equal groups: divide.`]] }),
      ns({ id: "take", l: "Take that many groups", a: s => [num(W / d), op("×"), num(n), op("="), ...s], ans: (W / d) * n, h: `The top number tells how many groups to take: ${n}.`,
        w: [[W / d + n, "Added", `Take ${count(n, "group")} of ${W / d}: that's multiplying.`], [W - (W / d) * n, "Found the part not taken", `That's the groups left over. Take the ${n} the top number says.`]] }),
    ],
    finalParts: [-1],
  };
}

/** One bar for W; beat 1 splits it into d groups of W/d, beat 2 shades n of them. */
export function fractionOfNumberPicture({ n, d, W }: FractionOfNumberProblem) {
  const g = W / d, R = g * n;
  return buildTape({
    rows: [{
      length: 1, parts: [{ count: 1, from: 0 }, { count: d, from: 1 }], fills: [{ a: 0, b: n / d, tone: "on", from: 2 }],
      each: [{ text: () => `${g}`, from: 1 }], label: [{ text: `${W}` }],
      total: [{ text: `${n} × ${g} = ${R}`, from: 2, acc: true }],
    }],
    brackets: [{ row: 0, a: 0, b: n / d, text: `${n}/${d}`, side: "below", from: 2 }],
    alt: `A bar for ${W} split into ${d} equal groups of ${g}; ${count(n, "group")} ${isAre(n)} shaded: ${R}.`,
  });
}

function explain(p: FractionOfNumberProblem, model: AnswerModel): Explanation {
  const { n, d, W } = p, g = expectedOf(model.steps, "groups"), R = expectedOf(model.steps, "take");
  return {
    heading: "Equal groups, then take some",
    idea: ["The bottom says how many equal groups to make, and the top says how many to take."],
    statement: [frac(n, d), text(" of "), num(W)],
    diagram: fractionOfNumberPicture(p),
    caption: `Split ${W} into ${count(d, "group")}. Take ${n} of them.`,
    timeline: beats(3),
    steps: [
      { id: "groups", state: 1, answerStep: "groups", result: g, math: [num(W), op("÷"), num(d), op("="), num(g)],
        narration: `The bottom says ${d} equal groups: ${W} ÷ ${d} = ${g} in each.` },
      { id: "take", state: 2, answerStep: "take", result: R, math: [num(g), op("×"), num(n), op("="), num(R)],
        narration: `The top says take ${n} of them: ${g} × ${n} = ${R}.` },
    ],
  };
}

export const lesson: LessonDefinition<FractionOfNumberProblem> = {
  id: "g5-fracof",
  grade: 5,
  unit: "Fractions",
  title: "Fraction of a number",
  pre: "g4-fracwhole",
  // the current app's card and picture: 3/4 of 20 = 15
  reference: createFractionOfNumber(3, 4, 20),
  generate: (rng, index) => generateFractionOfNumber(rng, index),
  restore: raw => {
    const r = ints(raw, ["n", "d", "W"] as const);
    try { return r && createFractionOfNumber(r.n, r.d, r.W); } catch { return null; }
  },
  display: (p): MathText => [frac(p.n, p.d), text(" of "), num(p.W)],
  answers,
  explain,
  story: ({ n, d, W }) => ({ op: "×", text: `There are **${W}** marbles in a bag. ${n}/${d} of them are blue. How many marbles are blue?` }),
};
