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
export function generateMixedToImproper(rng: Rng): MixedToImproperProblem {
  const d = rng.int(2, 9), n = coprimeTop(rng, d);
  return createMixedToImproper(rng.int(1, 6), n, d);
}

function answers({ w, n, d }: MixedToImproperProblem): AnswerModel {
  const S = w * d + n;
  return {
    steps: [
      ns({ id: "wholes", l: "Wholes into pieces", a: s => [num(w), op("×"), num(d), op("="), ...s], ans: w * d, h: `Each whole has ${count(d, "piece")}.`,
        w: [[w + d, "Added instead of multiplied", `${count(w, "whole")} with ${count(d, "piece")} each: multiply.`]] }),
      ns({ id: "extra", l: "Add the extra pieces", a: s => [num(w * d), op("+"), num(n), op("="), ...s], ans: S, h: `Add the ${count(n, "extra piece")}.` }),
      ms({ id: "fraction", l: "Write the fraction", a: X => [num(w), frac(n, d), op("="), frac(X.n!, X.d!)], ans: { n: S, d },
        h: `${count(S, "piece")}, each a ${d === 2 ? "half" : "1/" + d}. The bottom stays ${d}.`,
        w: [[{ n: S, d: w * d }, "Changed the bottom", "The piece size doesn't change: the bottom stays " + d + "."]] }),
    ],
    finalParts: [-1],
  };
}

/** One full bar per whole and a bar with n of d pieces; the running count of pieces grows down the right side. */
export function mixedToImproperPicture({ w, n, d }: MixedToImproperProblem) {
  const S = w * d + n;
  const rows: TapeRow[] = Array.from({ length: w }, (_, j): TapeRow => ({
    length: 1, parts: d, fills: [{ a: 0, b: 1, tone: "on" }], label: [{ text: "1" }],
    total: [{ text: `${(j + 1) * d}`, from: 1, acc: j === w - 1 }],
  }));
  rows.push({ length: 1, parts: d, fills: [{ a: 0, b: n / d, tone: "two" }], label: [{ text: `${n}/${d}` }],
    total: [{ text: `${S}`, from: 2, until: 2, acc: true }, { text: `${S}/${d}`, from: 3, acc: true }] });
  return buildTape({ rows, alt: `${w} whole bars of ${count(d, "piece")} and a bar with ${n} of ${count(d, "piece")}: ${count(S, "piece")} in all, so ${w} ${n}/${d} = ${S}/${d}.` });
}

function explain(p: MixedToImproperProblem, model: AnswerModel): Explanation {
  const { w, n, d } = p, W = expectedOf(model.steps, "wholes"), S = expectedOf(model.steps, "extra");
  const pieces = (k: number) => `${k} ${pieceName(d, k !== 1)}`;
  return {
    heading: "Count all the pieces",
    statement: [num(w), frac(n, d), op("="), frac("?", d)],
    diagram: mixedToImproperPicture(p),
    caption: `Each whole is ${pieces(d)}.`,
    timeline: beats(4),
    steps: [
      { id: "wholes", state: 1, answerStep: "wholes", result: W, math: [num(w), op("×"), num(d), op("="), num(W)],
        narration: `Each whole is ${pieces(d)}, so ${w} ${w === 1 ? "whole is" : "wholes are"} ${w} × ${d} = ${pieces(W)}.` },
      { id: "extra", state: 2, answerStep: "extra", result: S, math: [num(W), op("+"), num(n), op("="), num(S)],
        narration: `Add the ${n} extra ${n === 1 ? "piece" : "pieces"}: ${W} + ${n} = ${S}.` },
      { id: "fraction", state: 3, answerStep: "fraction", math: [num(w), frac(n, d), op("="), frac(S, d)],
        narration: `${count(S, "piece")}, each one ${pieceName(d, false)}. The bottom stays ${d}: ${w} ${n}/${d} = ${S}/${d}.` },
    ],
  };
}

export const lesson: LessonDefinition<MixedToImproperProblem> = {
  id: "g5-improper",
  grade: 5,
  unit: "Fractions",
  title: "Mixed numbers to fractions",
  pre: "g4-equiv",
  // the current app's card and picture: 2 3/4 = 11/4
  reference: createMixedToImproper(2, 3, 4),
  generate: rng => generateMixedToImproper(rng),
  restore: raw => {
    const r = ints(raw, ["w", "n", "d"] as const);
    try { return r && createMixedToImproper(r.w, r.n, r.d); } catch { return null; }
  },
  display: (p): MathText => [num(p.w), frac(p.n, p.d)],
  displayNote: () => "Write it as one fraction.",
  answers,
  explain,
};
