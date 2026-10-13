import { frac, num, op, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import type { TapeRow } from "../../../../explanations/diagrams/tape/schema";
import { expectedOf, ints, ms, ns, pieceName } from "../../_tape-family/steps";
import { coprimeTop } from "../../grade4/g4-equiv";
import { count } from "../../../text";

/** w n/d as one fraction: (w·d + n)/d. */
export interface MixedToImproperProblem { w: number; n: number; d: number }

export function createMixedToImproper(w: number, n: number, d: number): MixedToImproperProblem {
  if (![w, n, d].every(Number.isInteger) || w < 1 || d < 2 || n < 1 || n >= d) throw new Error(`not a mixed number: ${w} ${n}/${d}`);
  return { w, n, d };
}

/** Same ranges as the current app: bottom 2–9, a top in lowest terms, 1–6 wholes. */
export function generateMixedToImproper(rng: Rng, index = 3): MixedToImproperProblem {
  // the first three: 1 or 2 wholes cut into halves to fifths
  const early = index < 3, d = rng.int(2, early ? 5 : 9), n = coprimeTop(rng, d);
  return createMixedToImproper(rng.int(1, early ? 2 : 6), n, d);
}

function answers({ w, n, d }: MixedToImproperProblem): AnswerModel {
  const S = w * d + n;
  return {
    steps: [
      ns({ id: "wholes", l: "Wholes into pieces", a: s => [num(w), op("×"), num(d), op("="), ...s], ans: w * d, h: `How many pieces are in one whole? Then in all ${w === 1 ? "of it" : `${w} wholes`}?`,
        w: [[w + d, "Added instead of multiplied", `${count(w, "whole")} with ${count(d, "piece")} each: multiply.`]] }),
      ns({ id: "extra", l: "Add the extra pieces", a: s => [num(w * d), op("+"), num(n), op("="), ...s], ans: S, h: `Add the ${count(n, "extra piece")}.`,
        w: [[w + n, "Added the whole number", `Use the ${w * d} pieces the wholes make, not the ${w}.`]] }),
      { ...ms({ id: "fraction", l: "Write the fraction", a: X => [num(w), frac(n, d), op("="), frac(X.n!, X.d!)], ans: { n: S, d },
        h: "The top counts every piece. The bottom says how big each piece is.",
        w: [[{ n: S, d: w * d }, "Changed the bottom", "The piece size doesn't change: the bottom stays " + d + "."]] }),
        explain: `${count(S, "piece")}, each a ${d === 2 ? "half" : "1/" + d}: ${S}/${d}.` },
    ],
    finalParts: [-1],
  };
}

/**
 * One bar per whole and a bar with n of d pieces, all waiting to be counted. Whole j fills at beat j + 1, its
 * pieces filling one by one as they are counted and the running count beside it; the extra pieces are counted next
 * (the count reaches S); the last beat writes S/d.
 */
export function mixedToImproperPicture({ w, n, d }: MixedToImproperProblem) {
  const S = w * d + n, extra = w + 1, last = w + 2, tick = Math.min(0.35, 1.2 / d), r2 = (x: number) => Math.round(x * 100) / 100;
  const rows: TapeRow[] = Array.from({ length: w }, (_, j): TapeRow => ({
    // lit while it is counted, and again when the last step counts every piece
    lit: [{ from: j + 1, until: j + 1 }, { from: last }],
    length: 1, parts: d, fills: [{ a: 0, b: 1, tone: "on", from: j + 1, stagger: tick }], label: [{ text: "1" }],
    // its pieces counted one by one, the count carrying on from the whole before
    each: [{ text: i => `${j * d + i + 1}`, from: j + 1, stagger: tick }],
    total: [{ text: `${(j + 1) * d}`, from: j + 1, acc: j === w - 1, delay: r2(d * tick) }],
  }));
  rows.push({ lit: [{ from: extra }], length: 1, parts: d, fills: [{ a: 0, b: n / d, tone: "two", from: extra, stagger: tick }], label: [{ text: `${n}/${d}` }],
    each: [{ text: i => `${w * d + i + 1}`, from: extra, only: i => i < n, stagger: tick }],
    total: [{ text: `${S}`, from: extra, until: extra, acc: true, delay: r2(n * tick) }, { text: `${S}/${d}`, from: last, acc: true }] });
  return buildTape({ rows, gap: "mixed",
    alt: `${w} whole bars of ${count(d, "piece")} and a bar with ${n} of ${count(d, "piece")}: ${count(S, "piece")} in all, so ${w} ${n}/${d} = ${S}/${d}.` });
}

function explain(p: MixedToImproperProblem, model: AnswerModel): Explanation {
  const { w, n, d } = p, W = expectedOf(model.steps, "wholes"), S = expectedOf(model.steps, "extra");
  const pieces = (k: number) => `${k} ${pieceName(d, k !== 1)}`;
  return {
    heading: "Count all the pieces",
    idea: ["When every whole is cut into the same pieces, all the pieces can be counted as one fraction."],
    statement: [num(w), frac(n, d), op("="), frac("?", d)],
    diagram: mixedToImproperPicture(p),
    caption: `Each whole is ${pieces(d)}.`,
    // a beat per whole, counted one at a time, then the extra pieces and the fraction
    timeline: beats(w + 3),
    steps: [
      { id: "wholes", state: w, answerStep: "wholes", result: W, math: [num(w), op("×"), num(d), op("="), num(W)],
        narration: `Each whole is ${pieces(d)}.` },
      { id: "extra", state: w + 1, answerStep: "extra", result: S, math: [num(W), op("+"), num(n), op("="), num(S)],
        narration: `Add the ${n} extra ${n === 1 ? "piece" : "pieces"}.` },
      { id: "fraction", state: w + 2, answerStep: "fraction", math: [num(w), frac(n, d), op("="), frac(S, d)],
        narration: `The pieces are still ${pieceName(d)}, so the bottom stays ${d}.` },
    ],
  };
}

export const lesson: LessonDefinition<MixedToImproperProblem> = {
  id: "g5-improper",
  grade: 5,
  unit: "Fractions",
  title: "Mixed numbers to fractions",
  pre: "g4-mixed",
  // the current app's card and picture: 2 3/4 = 11/4
  reference: createMixedToImproper(2, 3, 4),
  generate: (rng, index) => generateMixedToImproper(rng, index),
  restore: raw => {
    const r = ints(raw, ["w", "n", "d"] as const);
    try { return r && createMixedToImproper(r.w, r.n, r.d); } catch { return null; }
  },
  display: (p): MathText => [num(p.w), frac(p.n, p.d)],
  displayNote: () => "Write it as one fraction.",
  answers,
  explain,
};
