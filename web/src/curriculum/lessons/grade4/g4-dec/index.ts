import { formatNumber as f, frac, num, op, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import type { TapeRow } from "../../../../explanations/diagrams/tape/schema";
import { expectedOf, ints, ns, pieceName } from "../../_tape-family/steps";

/** a/10 + b/100, written as a decimal. */
export interface TenthsHundredthsProblem { a: number; b: number }

export function createTenthsHundredths(a: number, b: number): TenthsHundredthsProblem {
  if (![a, b].every(Number.isInteger) || a < 1 || a > 9 || b < 1 || b > 99) throw new Error(`not a tenths and hundredths problem: ${a}/10 + ${b}/100`);
  return { a, b };
}

/** Same ranges as the current app: 1–9 tenths and 1–99 hundredths. */
export const generateTenthsHundredths = (rng: Rng) => createTenthsHundredths(rng.int(1, 9), rng.int(1, 99));

const count = (k: number, d: number) => `${k} ${pieceName(d, k !== 1)}`;

function answers({ a, b }: TenthsHundredthsProblem): AnswerModel {
  const S = 10 * a + b;
  return {
    steps: [
      ns({ id: "hundredths", l: "Tenths to hundredths", a: s => [frac(a, 10), op("="), frac(s, 100)], ans: 10 * a, h: "Multiply the top and bottom by 10.",
        w: [[a, "Changed only the bottom", "Multiply the top by 10 too."]] }),
      ns({ id: "add", l: "Add the hundredths", a: s => [frac(10 * a, 100), op("+"), frac(b, 100), op("="), frac(s, 100)], ans: S, h: "Same-size pieces: add the tops." }),
      ns({ id: "decimal", l: "Write it as a decimal", a: s => [frac(S, 100), op("="), ...s], ans: S / 100, h: "Hundredths go two places after the point.",
        w: [[S / 10, "Point in the wrong place", "Hundredths need two places after the decimal point."]] }),
    ],
    finalParts: [-1],
  };
}

/**
 * Bars cut into tenths. The first shows a tenths; the second b hundredths (each tenth carries ten thin hundredth lines).
 * Beat 1 cuts the first bar's tenths into hundredths too, beat 2 puts the pieces together (two bars past one whole),
 * beat 3 names the total as a decimal.
 */
export function tenthsHundredthsPicture({ a, b }: TenthsHundredthsProblem) {
  const S = 10 * a + b, wholes = Math.ceil(S / 100);
  const rows: TapeRow[] = [
    { length: 1, parts: 10, ticks: [{ count: 100, from: 1 }], fills: [{ a: 0, b: a / 10, tone: "on" }],
      label: [{ text: `${a}/10`, until: 0 }, { text: `${10 * a}/100`, from: 1 }] },
    { length: 1, parts: 10, ticks: [{ count: 100 }], fills: [{ a: 0, b: b / 100, tone: "two" }], label: [{ text: `${b}/100` }] },
  ];
  for (let w = 0; w < wholes; w++) {
    const on = [Math.max(0, -w * 100), Math.min(100, 10 * a - w * 100)], acc = [Math.max(0, 10 * a - w * 100), Math.min(100, S - w * 100)];
    rows.push({
      length: 1, parts: 10, ticks: [{ count: 100, from: 2 }], from: 2,
      fills: [
        ...(on[1]! > on[0]! ? [{ a: on[0]! / 100, b: on[1]! / 100, tone: "on" as const }] : []),
        ...(acc[1]! > acc[0]! ? [{ a: acc[0]! / 100, b: acc[1]! / 100, tone: "two" as const }] : []),
      ],
      label: w === 0 ? [{ text: `${S}/100` }] : [],
      total: w === wholes - 1 ? [{ text: `= ${f(S / 100)}`, from: 3, acc: true }] : [],
    });
  }
  return buildTape({ rows, alt: `Bars cut into tenths and hundredths: ${a}/10 is ${10 * a}/100; with ${b}/100 that makes ${S}/100, which is ${f(S / 100)}.` });
}

function explain(p: TenthsHundredthsProblem, model: AnswerModel): Explanation {
  const { a, b } = p;
  const A = expectedOf(model.steps, "hundredths"), S = expectedOf(model.steps, "add"), D = expectedOf(model.steps, "decimal");
  return {
    heading: "Make the pieces match",
    statement: [frac(a, 10), op("+"), frac(b, 100)],
    diagram: tenthsHundredthsPicture(p),
    caption: `${a}/10 is the same as ${A}/100.`,
    timeline: beats(4),
    steps: [
      { id: "hundredths", state: 1, answerStep: "hundredths", result: A, math: [frac(a, 10), op("="), frac(A, 100)],
        narration: `Cut every tenth into 10 hundredths: ${count(a, 10)} is the same as ${count(A, 100)}.` },
      { id: "add", state: 2, answerStep: "add", result: S, math: [frac(A, 100), op("+"), frac(b, 100), op("="), frac(S, 100)],
        narration: `Same-size pieces now: ${A} + ${b} = ${count(S, 100)}.` },
      { id: "decimal", state: 3, answerStep: "decimal", result: D, math: [frac(S, 100), op("="), num(D)],
        narration: `Hundredths go two places after the point: ${count(S, 100)} is written ${f(D)}.` },
    ],
  };
}

export const lesson: LessonDefinition<TenthsHundredthsProblem> = {
  id: "g4-dec",
  grade: 4,
  unit: "Decimals",
  title: "Tenths and hundredths",
  // the current app's card: 3/10 + 25/100 = 0.55
  reference: createTenthsHundredths(3, 25),
  generate: rng => generateTenthsHundredths(rng),
  restore: raw => {
    const r = ints(raw, ["a", "b"] as const);
    try { return r && createTenthsHundredths(r.a, r.b); } catch { return null; }
  },
  display: (p): MathText => [frac(p.a, 10), op("+"), frac(p.b, 100)],
  displayNote: () => "Write the answer as a decimal.",
  answers,
  explain,
};
