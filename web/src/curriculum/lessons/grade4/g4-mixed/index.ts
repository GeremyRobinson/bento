// Adding mixed numbers (new in the rebuild): same-size pieces, so add the wholes, add the pieces,
// and trade a full whole's worth of pieces for one more whole.
import { frac, num, op, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation, type ExplanationStep } from "../../../../explanations/schema";
import { buildMixedBars } from "../../../../explanations/diagrams/early-g4/mixed-bars";
import { gcd, pieceName } from "../../_tape-family/steps";
import { expectedOf, manyBoxes, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { boxSlips, slips } from "../_kit";
import { count } from "../../../text";

/** w1 n1/d + w2 n2/d */
export interface MixedProblem { w1: number; n1: number; w2: number; n2: number; d: number }

const BOTTOMS = [3, 4, 5, 6, 8];

export function createMixed(w1: number, n1: number, w2: number, n2: number, d: number): MixedProblem {
  if (!BOTTOMS.includes(d)) throw new Error(`bottom ${d} isn't one we draw`);
  wholeIn("w1", w1, 1, 4);
  wholeIn("w2", w2, 1, 4);
  wholeIn("n1", n1, 1, d - 1);
  wholeIn("n2", n2, 1, d - 1);
  if (n1 + n2 === d) throw new Error("the pieces make exactly one whole");
  if (gcd((n1 + n2) % d, d) !== 1) throw new Error("the answer's fraction isn't in lowest terms");
  return { w1, n1, w2, n2, d };
}

/** Early problems need a trade half the time; later ones mostly do. Wholes are 1 to 3. */
export function generateMixed(rng: Rng, index: number): MixedProblem {
  const trade = rng.next() < (index < 3 ? 0.5 : 0.75);
  for (;;) {
    const d = rng.pick(BOTTOMS), n1 = rng.int(1, d - 1), n2 = rng.int(1, d - 1), S = n1 + n2;
    if (gcd(n1, d) !== 1 || gcd(n2, d) !== 1 || S === d || (S > d) !== trade) continue;
    try { return createMixed(rng.int(1, 3), n1, rng.int(1, 3), n2, d); } catch { /* try again */ }
  }
}

const mixed = (w: number, n: number, d: number): MathText => [num(w), frac(n, d)];
const label = (w: number, n: number, d: number) => `${w} ${n}/${d}`;
const wholes = (w: number) => `${w} ${w === 1 ? "whole" : "wholes"}`;
const pieces = (n: number, d: number) => `${n} ${pieceName(d, n !== 1)}`;
const cap = (s: string) => s[0]!.toUpperCase() + s.slice(1);

function parts({ w1, n1, w2, n2, d }: MixedProblem) {
  const W = w1 + w2, S = n1 + n2, trade = S > d;
  return { W, S, trade, R: trade ? S - d : S, total: trade ? W + 1 : W };
}

function answers(p: MixedProblem): AnswerModel {
  const { w1, n1, w2, n2, d } = p, { W, S, trade, R, total } = parts(p), piece = pieceName(d);
  const sum: MathText = [...mixed(w1, n1, d), op("+"), ...mixed(w2, n2, d)];
  const steps: AnswerStep[] = [
    oneBox({
      id: "wholes", label: "Add the wholes", prompt: s => [num(w1), op("+"), num(w2), op("="), s], ans: W,
      wrong: slips(W, [[w1 * w2, "Multiplied the wholes", `This is adding: ${w1} + ${w2}.`]]),
      hint: `Just the big numbers: ${w1} + ${w2}.`, explain: `${wholes(w1)} and ${wholes(w2)} make ${wholes(W)}.`,
    }),
    manyBoxes({
      id: "pieces", label: "Add the pieces", note: `The pieces are all ${piece}.`,
      prompt: b => [frac(n1, d), op("+"), frac(n2, d), op("="), frac([b.n!], [b.d!])], ans: { n: S, d },
      wrong: boxSlips({ n: S, d }, [[{ n: S, d: 2 * d }, "Added the bottoms", `The bottom is the size of the pieces. ${cap(piece)} plus ${piece} are still ${piece}, so it stays ${d}.`]]),
      hint: "Count the pieces in both. Do the pieces change size when you put them together?",
      explain: `${n1} + ${n2} = ${pieces(S, d)}. They are still ${piece}, so the bottom stays ${d}: ${S}/${d}.`,
    }),
  ];
  if (trade) steps.push(manyBoxes({
    id: "trade", label: "Make a whole", question: `${S}/${d} is more than 1. ${d} ${piece} make 1 whole. What's left?`,
    prompt: b => [frac(S, d), op("="), b.w!, frac([b.n!], d)], ans: { w: 1, n: R }, small: ["w"],
    wrong: boxSlips({ w: 1, n: R }, [
      [{ w: 1, n: S }, "Kept every piece", `${d} of the pieces became the whole, so take ${d} away: ${S} − ${d} = ${R}.`],
      [{ w: 0, n: S }, "Didn't make a whole", `${S} is ${d} or more, so ${d} of them make 1 whole.`],
    ]),
    hint: `${d}/${d} is 1 whole. Take ${count(d, "piece")} out of ${S}.`,
    explain: `${S} − ${d} = ${R}, so ${S}/${d} is 1 whole and ${R}/${d}.`,
  }));
  const fin: [Record<string, number>, string, string][] = trade
    ? [
      [{ w: W, n: S }, "Forgot to regroup", `${S}/${d} is more than 1 whole. Trade ${d} ${piece} for 1 whole first.`],
      [{ w: W, n: R }, "Lost the new whole", `The ${d} ${piece} you traded made 1 more whole. Add it: ${W} + 1.`],
    ]
    : [[{ w: W + 1, n: R }, "Added a whole too many", `${S}/${d} is less than 1, so there's no whole to trade.`]];
  steps.push(manyBoxes({
    id: "answer", label: "Put it together", question: trade ? `${wholes(W)}, plus 1 whole and ${R}/${d}.` : `${wholes(W)} and ${S}/${d}.`,
    prompt: b => [...sum, op("="), b.w!, frac([b.n!], d)], ans: { w: total, n: R }, small: ["w"],
    wrong: boxSlips({ w: total, n: R }, fin),
    hint: trade ? "The wholes you added, plus the 1 whole you just made. Then the pieces that were left over." : "The wholes you added, then the pieces you added.",
    explain: trade ? `${wholes(W)} and 1 more make ${wholes(total)}, with ${R}/${d} left: ${total} ${R}/${d}.` : `${wholes(W)} and ${S}/${d}: ${total} ${R}/${d}.`,
  }));
  return { steps, finalParts: [-1] };
}

function explain(p: MixedProblem, model: AnswerModel): Explanation {
  const { w1, n1, w2, n2, d } = p, { trade } = parts(p), piece = pieceName(d);
  const W = expectedOf(model, "wholes"), S = expectedOf(model, "pieces", "n");
  const total = expectedOf(model, "answer", "w"), R = expectedOf(model, "answer", "n");
  const last = trade ? 4 : 3;
  const steps: ExplanationStep[] = [
    { id: "start", state: 0, math: [...mixed(w1, n1, d), op("+"), ...mixed(w2, n2, d)],
      narration: `Each number is some whole bars and some ${piece}.` },
    { id: "wholes", state: 1, answerStep: "wholes", result: W, math: [num(w1), op("+"), num(w2), op("="), num(W)],
      narration: `Put the wholes together: ${w1} + ${w2} = ${W}.` },
    { id: "pieces", state: 2, answerStep: "pieces", result: S, math: [frac(n1, d), op("+"), frac(n2, d), op("="), frac(S, d)],
      narration: `Now the pieces: ${n1} + ${n2} = ${pieces(S, d)}.${trade ? ` That's more than one bar's worth.` : ""}` },
  ];
  if (trade) steps.push({ id: "trade", state: 3, answerStep: "trade", result: expectedOf(model, "trade", "n"), math: [frac(S, d), op("="), num(1), frac(R, d)],
    narration: `${d} ${piece} fill a bar, and that's 1 whole. ${S} − ${d} leaves ${pieces(R, d)}.` });
  steps.push({ id: "answer", state: last, answerStep: "answer", result: R, math: [...mixed(w1, n1, d), op("+"), ...mixed(w2, n2, d), op("="), ...mixed(total, R, d)],
    narration: trade ? `${wholes(W)} and 1 more make ${total}, with ${R}/${d} left: ${label(total, R, d)}.` : `${wholes(W)} and ${S}/${d}: ${label(total, R, d)}.` });
  return {
    heading: "Wholes with wholes, pieces with pieces",
    idea: ["Wholes and pieces are different sizes, so wholes go with wholes and pieces go with pieces."],
    statement: [...mixed(w1, n1, d), op("+"), ...mixed(w2, n2, d)],
    diagram: buildMixedBars({
      d, first: { w: w1, n: n1, label: label(w1, n1, d) }, second: { w: w2, n: n2, label: label(w2, n2, d) },
      beats: { wholes: 1, pieces: 2, regroup: trade ? 3 : null, total: last }, total: `= ${label(total, R, d)}`,
      alt: `${label(w1, n1, d)} and ${label(w2, n2, d)} as whole bars and ${piece}. Together: ${wholes(W)} and ${S}/${d}${trade ? `, and ${d} ${piece} make 1 more whole` : ""}, so ${label(total, R, d)}.`,
    }),
    caption: `Every bar is one whole, cut into ${piece}.`,
    timeline: beats(last + 1),
    steps,
  };
}

export const lesson: LessonDefinition<MixedProblem> = {
  id: "g4-mixed",
  grade: 4,
  unit: "Fractions",
  title: "Adding mixed numbers",
  pre: "g4-likefrac",
  reference: createMixed(2, 3, 1, 4, 5),
  generate: (rng, index) => generateMixed(rng, index),
  restore: raw => restoreVia(raw, ["w1", "n1", "w2", "n2", "d"] as const, v => createMixed(v.w1, v.n1, v.w2, v.n2, v.d)),
  display: p => [...mixed(p.w1, p.n1, p.d), op("+"), ...mixed(p.w2, p.n2, p.d)],
  answers,
  explain,
  story: p => ({ op: "+", text: `Mia walks **${label(p.w1, p.n1, p.d)}** miles on Monday and **${label(p.w2, p.n2, p.d)}** miles on Tuesday. How far does she walk in all?` }),
};
