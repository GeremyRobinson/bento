import { frac, num, op, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTape, textWidth } from "../../../../explanations/diagrams/tape/build";
import type { TapeBracket, TapeFill } from "../../../../explanations/diagrams/tape/schema";
import { expectedOf, finalForm, gcd, ints, mixedLabel, mixedMath, ns, pieceName, simplifyStep } from "../../_tape-family/steps";
import { coprimeTop } from "../g4-equiv";
import { count as countOf } from "../../../text";

/** W × n/d: W groups of n pieces, each piece 1/d. */
export interface FractionTimesWholeProblem { n: number; d: number; W: number }

export function createFractionTimesWhole(n: number, d: number, W: number): FractionTimesWholeProblem {
  if (![n, d, W].every(Number.isInteger) || d < 2 || n < 1 || n >= d || W < 1) throw new Error(`not a fraction-times-whole problem: ${W} × ${n}/${d}`);
  return { n, d, W };
}

/** Same ranges as the current app: bottom 3–8, a top in lowest terms, times 2–6. */
export function generateFractionTimesWhole(rng: Rng): FractionTimesWholeProblem {
  const d = rng.int(3, 8);
  return createFractionTimesWhole(coprimeTop(rng, d), d, rng.int(2, 6));
}

const count = (k: number, d: number) => `${k} ${pieceName(d, k !== 1)}`;

function answers({ n, d, W }: FractionTimesWholeProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "top", l: "Multiply the top", a: s => [num(W), op("×"), num(n), op("="), ...s], ans: W * n, h: `${countOf(W, "group")} of ${countOf(n, "piece")}.`,
        w: [[W * d, "Multiplied the bottom", "The pieces stay the same size. Only the number of pieces changes."]] }),
      simplifyStep(W * n, d, "Write as a mixed number"),
    ],
    finalParts: [-1],
  };
}

/**
 * Top: the W groups side by side, each one whole bar with n pieces shaded (groups alternate colours).
 * Bottom: the same pieces packed together, still pieces of 1/d, filling as many wholes as they need.
 */
export function fractionTimesWholePicture({ n, d, W }: FractionTimesWholeProblem) {
  const S = W * n, wholes = Math.ceil(S / d);
  const tone = (g: number) => (g % 2 ? "acc" : "on") as TapeFill["tone"];
  const groups: TapeFill[] = Array.from({ length: W }, (_, g) => ({ a: g, b: g + n / d, tone: tone(g) }));
  const packed: TapeFill[] = Array.from({ length: W }, (_, g) => ({ a: (g * n) / d, b: ((g + 1) * n) / d, tone: tone(g), from: 1 }));
  const label = `${n}/${d}`;
  // a bracket over each group when its fraction fits above it; the canvas is 460 wide at most
  const fits = textWidth(label, 15) + 8 < 440 / W;
  const brackets: TapeBracket[] = fits ? Array.from({ length: W }, (_, g) => ({ row: 0, a: g, b: g + 1, text: label, side: "above" as const })) : [];
  brackets.push({ row: 1, a: 0, b: S / d, text: count(S, d), side: "below", from: 1 });
  const F = finalForm(S, d), same = F.whole === 0 && F.den === d;
  return buildTape({
    rows: [
      { length: W, parts: W * d, wholes: true, fills: groups, ...(fits ? {} : { label: [{ text: `${W} × ${label}` }] }) },
      { length: wholes, parts: wholes * d, wholes: true, from: 1, fills: packed,
        total: [{ text: `${S}/${d}`, from: 1, ...(same ? {} : { until: 1 }) }, ...(same ? [] : [{ text: `= ${mixedLabel(S, d)}`, from: 2, acc: true }])] },
    ],
    brackets,
    alt: `${W} bars, each with ${n} of ${countOf(d, "piece")} shaded; together they make ${countOf(S, "piece")} of size 1/${d}, which is ${mixedLabel(S, d)}.`,
  });
}

function explain(p: FractionTimesWholeProblem, model: AnswerModel): Explanation {
  const { n, d, W } = p, S = expectedOf(model.steps, "top"), F = finalForm(S, d), g = gcd(S, d);
  const simple = S >= d
    ? `${count(S, d)} is ${mixedLabel(S, d)}: every ${countOf(d, "piece")} make one whole.`
    : g > 1 ? `Divide the top and the bottom by ${g}: ${S}/${d} = ${mixedLabel(S, d)}.`
    : `No number but 1 divides both ${S} and ${d}, so ${S}/${d} is already as simple as it gets.`;
  return {
    heading: "Groups of pieces",
    statement: [num(W), op("×"), frac(n, d)],
    diagram: fractionTimesWholePicture(p),
    caption: `${countOf(W, "group")} of ${count(n, d)}.`,
    timeline: beats(3),
    steps: [
      { id: "top", state: 1, answerStep: "top", result: S, math: [num(W), op("×"), num(n), op("="), num(S)],
        narration: `${countOf(W, "group")} of ${count(n, d)} make ${count(S, d)}. The pieces stay the same size.` },
      { id: "simplify", state: 2, answerStep: "simplify", ...(F.num === 0 ? { result: F.whole } : {}), math: S < d && g === 1 ? [frac(S, d)] : [frac(S, d), op("="), ...mixedMath(S, d)], narration: simple },
    ],
  };
}

export const lesson: LessonDefinition<FractionTimesWholeProblem> = {
  id: "g4-fracwhole",
  grade: 4,
  unit: "Fractions",
  title: "Fraction times a whole number",
  // the current app's card and picture: 3 × 2/5 = 6/5
  reference: createFractionTimesWhole(2, 5, 3),
  generate: rng => generateFractionTimesWhole(rng),
  restore: raw => {
    const r = ints(raw, ["n", "d", "W"] as const);
    try { return r && createFractionTimesWhole(r.n, r.d, r.W); } catch { return null; }
  },
  display: (p): MathText => [num(p.W), op("×"), frac(p.n, p.d)],
  answers,
  explain,
  story: ({ n, d, W }) => ({ op: "×", text: `Each muffin uses ${n}/${d} cup of milk. How much milk do **${W}** muffins use?` }),
};
