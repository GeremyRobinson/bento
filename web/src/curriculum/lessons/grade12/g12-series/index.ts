import { formatNumber as f, m, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { ns } from "../../algebra-kit/steps";
import { attempt, readInts, rule } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { buildPairs } from "../../../../explanations/diagrams/algebra/pairs";
import { count, noun } from "../../../text";
import { withEasyStart } from "../../easy-start";

/** The first n terms of a, a + d, a + 2d, … added up. */
export interface ArithmeticSeries { kind: "series.arithmetic"; a: number; d: number; n: number; last: number; sum: number }

export function createSeries(a: number, d: number, n: number): ArithmeticSeries {
  rule(d >= 1 && n >= 2, "d ≥ 1 and n ≥ 2");
  const last = a + (n - 1) * d;
  return { kind: "series.arithmetic", a, d, n, last, sum: ((a + last) * n) / 2 };
}

/** Same ranges as the current app: first term 1–20, step 1–9, 6–30 terms. */
export const generateSeries = (rng: Rng) => { const a = rng.int(1, 20), d = rng.int(1, 9), n = rng.int(6, 30); return createSeries(a, d, n); };

export function restoreSeries(raw: unknown): ArithmeticSeries | null {
  const r = readInts(raw, ["a", "d", "n"] as const);
  return r && attempt(() => createSeries(r.a, r.d, r.n));
}

const firstTerms = ({ a, d }: ArithmeticSeries): MathText => [0, 1, 2].flatMap((k, i) => (i ? [op("+"), num(a + k * d)] : [num(a + k * d)]));

export function seriesAnswers({ a, d, n, last }: ArithmeticSeries): AnswerModel {
  return {
    steps: [
      ns({ id: "last", l: "Last term", a: s => [num(a), op("+"), num(n - 1), op("×"), num(d), op("="), ...s], ans: last, h: "You start on the first term, so the last term is one jump fewer than the number of terms away.",
        w: [[a + n * d, "Off by one", `It's ${f(n)} minus 1, which is ${count(n - 1, "jump")}.`]] }),
      ns({ id: "pair", l: "First plus last", a: s => [num(a), op("+"), num(last), op("="), ...s], ans: a + last, h: "Pair the first and last terms: every pair adds to this same total.", w: [[last - a, "Subtracted", "A pair is the two terms added together."]] }),
      ns({ id: "sum", l: "Sum", a: s => [num(a + last), op("×"), num(n), op("÷"), num(2), op("="), ...s], ans: ((a + last) * n) / 2, h: `There are ${f(n)} ÷ 2 pairs, each worth ${f(a + last)}.`,
        w: [[(a + last) * n, "Forgot to halve", "Each pair uses two terms, so divide by 2."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainSeries(p: ArithmeticSeries, model: AnswerModel) {
  const { a, d, n } = p;
  const [last, pair, sum] = model.steps.map(s => s.slots[0]!.expected!) as [number, number, number];
  const diagram = buildPairs({ first: a, step: d, count: n, beats: { terms: 0, last: 1, pair: 2, total: 3 } });
  const pairs = n % 2 === 0
    ? `There are ${f(n / 2)} pairs, each worth ${f(pair)}: ${f(pair)} × ${f(n)} ÷ 2 = ${f(sum)}.`
    : `${f(n)} terms make ${f(n)} ÷ 2 pairs (the middle term is half a pair), each worth ${f(pair)}: ${f(pair)} × ${f(n)} ÷ 2 = ${f(sum)}.`;
  return beatExplanation({
    heading: "Pair them up",
    idea: ["The first and last terms add to the same total as every other pair."],
    statement: [...firstTerms(p), op("+"), text("…"), op("+"), num(last)],
    caption: `The second and second-to-last terms make ${f(pair)} too: one goes up by ${f(d)} while the other goes down by ${f(d)}.`,
    diagram,
    alt: diagram.alt,
    steps: [
      { id: "terms", narration: `Start at ${f(a)} and go up by ${f(d)} each time. Add the first ${f(n)} terms.`, math: [...firstTerms(p), op("+"), text("…")] },
      { id: "last", narration: `Term ${f(n)} is ${f(n - 1)} ${noun(n - 1, "jump")} of ${f(d)} from the first: ${f(last)}.`, math: m(a, op("+"), n - 1, op("×"), d, op("="), last), answerStep: "last", result: last },
      { id: "pair", narration: `Pair the first and last terms: ${f(a)} + ${f(last)} = ${f(pair)}.`, math: m(a, op("+"), last, op("="), pair), answerStep: "pair", result: pair },
      { id: "sum", narration: pairs, math: m(pair, op("×"), n, op("÷"), 2, op("="), sum), answerStep: "sum", result: sum },
    ],
  });
}

export const lesson: LessonDefinition<ArithmeticSeries> = withEasyStart({
  id: "g12-series",
  grade: 12,
  unit: "Vectors and series",
  title: "Arithmetic series",
  pre: "g11-seq",
  reference: createSeries(1, 1, 100),
  generate: rng => generateSeries(rng),
  restore: restoreSeries,
  display: p => [...firstTerms(p), op("+"), text("…")],
  displayNote: p => `Add the first ${f(p.n)} terms.`,
  answers: seriesAnswers,
  explain: explainSeries,
});
