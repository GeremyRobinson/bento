import { frac, num, op, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import type { TapeRow } from "../../../../explanations/diagrams/tape/schema";
import { expectedOf, fs, gcd, ints, ns, pieceName } from "../../_tape-family/steps";
import { count as countOf } from "../../../text";

/** a/d + c/d: same-size pieces, so only the tops add. */
export interface LikeFractionsProblem { a: number; c: number; d: number }

export function createLikeFractions(a: number, c: number, d: number): LikeFractionsProblem {
  if (![a, c, d].every(Number.isInteger) || d < 2 || a < 1 || c < 1 || a >= d || c >= d) throw new Error(`not a like-fractions problem: ${a}/${d} + ${c}/${d}`);
  return { a, c, d };
}

/** Same ranges as the current app: bottoms 3, 4, 5, 6, 8, 10 or 12, and a sum already in lowest terms. */
export function generateLikeFractions(rng: Rng): LikeFractionsProblem {
  const d = rng.pick([3, 4, 5, 6, 8, 10, 12]);
  let a: number, c: number;
  do { a = rng.int(1, d - 1); c = rng.int(1, d - 1); } while (gcd(a + c, d) !== 1);
  return createLikeFractions(a, c, d);
}

const count = (n: number, d: number) => `${n} ${pieceName(d, n !== 1)}`;

function answers({ a, c, d }: LikeFractionsProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "tops", l: "Add the tops", a: s => [num(a), op("+"), num(c), op("="), ...s], ans: a + c, h: `Count the pieces: ${count(a, d)} and ${count(c, d)}.` }),
      fs({ id: "bottom", l: "Keep the bottom", a: s => [frac(a, d), op("+"), frac(c, d), op("="), ...s], N: a + c, D: d, h: `The pieces are still ${pieceName(d)}, so the bottom stays ${d}.`,
        w: [[a + c, 2 * d, "Added the bottoms", `The bottom is the size of the pieces. ${pieceName(d)} plus ${pieceName(d)} are still ${pieceName(d)}.`]], n: "Bigger than 1 is fine here." }),
    ],
    finalParts: [-1],
  };
}

/**
 * Two bars of d pieces, a shaded and c shaded in the second part color (orange); then the pieces put together in a sum bar
 * (two bars when the sum is more than one whole), still cut into d pieces.
 */
export function likeFractionsPicture({ a, c, d }: LikeFractionsProblem) {
  const S = a + c, wholes = Math.ceil(S / d);
  const rows: TapeRow[] = [
    { length: 1, parts: d, fills: [{ a: 0, b: a / d, tone: "on" }], label: [{ text: `${a}/${d}` }] },
    { length: 1, parts: d, fills: [{ a: 0, b: c / d, tone: "two" }], label: [{ text: `${c}/${d}` }] },
  ];
  for (let w = 0; w < wholes; w++) {
    const on = [Math.max(0, -w * d), Math.min(d, a - w * d)], acc = [Math.max(0, a - w * d), Math.min(d, S - w * d)];
    rows.push({
      length: 1, parts: d, from: 1,
      fills: [
        ...(on[1]! > on[0]! ? [{ a: on[0]! / d, b: on[1]! / d, tone: "on" as const }] : []),
        ...(acc[1]! > acc[0]! ? [{ a: acc[0]! / d, b: acc[1]! / d, tone: "two" as const }] : []),
      ],
      label: w === 0 ? [{ text: "?", until: 1 }, { text: `${S}/${d}`, from: 2, acc: true }] : [],
      total: w === wholes - 1 ? [{ text: count(S, d) }] : [],
    });
  }
  return buildTape({
    rows,
    alt: `Fraction bars: ${a}/${d} and ${c}/${d}, then together ${countOf(S, "piece")} of size 1/${d}, which is ${S}/${d}.`,
  });
}

function explain(p: LikeFractionsProblem, model: AnswerModel): Explanation {
  const { a, c, d } = p, S = expectedOf(model.steps, "tops");
  return {
    heading: "Same pieces: add the tops",
    idea: ["The bottom tells the size of the pieces, so it stays the same."],
    statement: [frac(a, d), op("+"), frac(c, d)],
    diagram: likeFractionsPicture(p),
    caption: `${count(a, d)} and ${count(c, d)} make ${count(S, d)}.`,
    timeline: beats(3),
    steps: [
      { id: "tops", state: 1, answerStep: "tops", result: S, math: [num(a), op("+"), num(c), op("="), num(S)],
        narration: `Count the pieces: ${count(a, d)} and ${count(c, d)} make ${count(S, d)}.` },
      { id: "bottom", state: 2, answerStep: "bottom", math: [frac(a, d), op("+"), frac(c, d), op("="), frac(S, d)],
        narration: `The pieces are still ${pieceName(d)}, so the bottom stays ${d}: ${S}/${d}.` },
    ],
  };
}

export const lesson: LessonDefinition<LikeFractionsProblem> = {
  id: "g4-likefrac",
  grade: 4,
  unit: "Fractions",
  title: "Adding like fractions",
  pre: "g4-equiv",
  // the current app's card and picture: 2/8 + 3/8 = 5/8
  reference: createLikeFractions(2, 3, 8),
  generate: rng => generateLikeFractions(rng),
  restore: raw => {
    const r = ints(raw, ["a", "c", "d"] as const);
    try { return r && createLikeFractions(r.a, r.c, r.d); } catch { return null; }
  },
  display: (p): MathText => [frac(p.a, p.d), op("+"), frac(p.c, p.d)],
  answers,
  explain,
  // one pizza can't hold more than d/d, so when a + c > d Ana's share comes from a second pizza of the same size
  story: ({ a, c, d }) => ({ op: "+", text: a + c <= d
    ? `Sam ate ${a}/${d} of a pizza. Ana ate ${c}/${d} of the same pizza. How much pizza did they eat together?`
    : `Sam ate ${a}/${d} of a pizza. Ana ate ${c}/${d} of another pizza the same size. How much pizza did they eat together?` }),
};
