// Dividing fractions (the current app's G6_DIVIDE): keep, change, flip, then multiply and simplify.
import { answer, frac, mark, num, op, slot, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition, StepCheck } from "../../../schemas/lesson";
import { chainExplanation } from "../../../../explanations/diagrams/chain/build";
import { gcd, restoreVia, wholeIn } from "../../_number-line/steps";

/** a/b ÷ c/d, both fractions proper and in lowest terms, bottoms 2–9 */
export interface DivideFractionsProblem { a: number; b: number; c: number; d: number }

export function createDivideFractions(a: number, b: number, c: number, d: number): DivideFractionsProblem {
  wholeIn("b", b, 2, 9); wholeIn("d", d, 2, 9);
  wholeIn("a", a, 1, b - 1); wholeIn("c", c, 1, d - 1);
  if (gcd(a, b) !== 1 || gcd(c, d) !== 1) throw new Error("both fractions are in lowest terms");
  return { a, b, c, d };
}

/** S/L as a whole number and a fraction in lowest terms (the current app's finalForm) */
export function finalForm(S: number, L: number) {
  const g = gcd(S, L), n = S / g, d = L / g;
  return { whole: Math.floor(n / d), num: n % d, den: d };
}

/** the simplified value as math; boxes' answers carry their ids so finished work shows them bold */
function finalMath(S: number, L: number, ids = false): MathText {
  const F = finalForm(S, L);
  const v = (id: string, x: number) => (ids ? answer(id, x) : num(x));
  if (F.num === 0) return [v("w", F.whole)];
  return [...(F.whole ? [v("w", F.whole)] : []), frac([v("n", F.num)], [v("d", F.den)])];
}

/** Simplify S/L to lowest terms or a mixed number (the current app's simplifyStep), same notes, checks and messages. */
export function simplifyStep(S: number, L: number, label: string, id = "simplify"): AnswerStep {
  const F = finalForm(S, L), hasWhole = F.whole > 0, fracPart = F.num > 0;
  const check = (v: Record<string, number | null>): StepCheck => {
    const w = v.w || 0, n = v.n || 0, dd = v.d;
    if (v.n != null && dd == null) return { ok: false, soft: true, message: "Fill in the bottom number too." };
    if (dd === 0) return { ok: false, soft: true, message: "The bottom can't be 0." };
    const den = dd || 1;
    if ((w * den + n) * L !== S * den) {
      return { ok: false, kind: "Simplifying", generic: false, message: S > L
        ? `That's not equal to ${S}/${L}. How many whole ${L}s fit into ${S}? That's the whole number. What's left over goes on top.`
        : `That's not equal to ${S}/${L}. Divide the top **and** the bottom by the same number.` };
    }
    if (dd && n >= dd) return { ok: false, soft: true, message: `That's the right amount! Now write it as a mixed number: how many whole ${dd}s fit into ${n}?` };
    if (dd && n > 0 && gcd(n, dd) > 1) return { ok: false, kind: "Not fully simplified", generic: false, message: `Same amount, good! But ${n}/${dd} can still be simplified: both ${n} and ${dd} divide by ${gcd(n, dd)}.` };
    return { ok: true };
  };
  return {
    id,
    label,
    prompt: [frac(S, L), op("="), slot("w", true), frac([slot("n")], [slot("d")])],
    note: S > L ? "The top is bigger than the bottom, so pull out the wholes. Use the small box for the whole number."
      : S === L ? "Top and bottom are the same. What whole number is that?"
      : gcd(S, L) > 1 ? "Can both numbers be divided by the same number?"
      : "If it can't be simplified, just copy it. Leave the whole-number box empty.",
    slots: [
      { id: "w", expected: hasWhole ? F.whole : null },
      { id: "n", expected: fracPart ? F.num : null },
      { id: "d", expected: fracPart ? F.den : null },
    ],
    known: [],
    check,
    hint: S % L === 0 ? `${S} ÷ ${L} = ${S / L} exactly, so it's a whole number.`
      : S >= L ? `${S} ÷ ${L} = ${Math.floor(S / L)} remainder ${S % L}. The remainder goes on top.`
      : gcd(S, L) > 1 ? `Both ${S} and ${L} can be divided by ${gcd(S, L)}.` : `No number (other than 1) divides both ${S} and ${L}. It's already simplest.`,
    explain: S % L === 0 ? `${S} ÷ ${L} = ${S / L} exactly, so it's the whole number ${S / L}.`
      : S >= L ? `${S} ÷ ${L} = ${Math.floor(S / L)} remainder ${S % L}, then simplify.` : gcd(S, L) > 1 ? `Divide top and bottom by ${gcd(S, L)}.` : "It was already as simple as it gets.",
    work: [frac(S, L), op("="), ...finalMath(S, L, true)],
  };
}

const fracBoxes = () => frac([slot("n")], [slot("d")]);
const both = (v: Record<string, number | null>) => v.n == null || v.d == null;

function answers({ a, b, c, d }: DivideFractionsProblem): AnswerModel {
  return {
    steps: [
      {
        id: "flip", label: "Flip the second fraction",
        prompt: [frac(c, d), op("→"), fracBoxes()], note: "Flip means the top and bottom trade places.",
        slots: [{ id: "n", expected: d }, { id: "d", expected: c }], known: [],
        check: v => {
          if (both(v)) return { ok: false, soft: true, message: "Fill in both boxes, the top and the bottom." };
          if (v.n === d && v.d === c) return { ok: true };
          if (v.n === c && v.d === d) return { ok: false, kind: "Didn't flip", message: "That's the same fraction. Swap the top and the bottom.", generic: false };
          if (v.n === b && v.d === a) return { ok: false, kind: "Flipped the wrong fraction", message: "Keep the first fraction. Flip the **second** one.", generic: false };
          return { ok: false, kind: "Flipping", message: `Swap them: the ${d} goes on top, the ${c} on the bottom.`, generic: false };
        },
        hint: "Top goes to the bottom, bottom goes to the top.", explain: `${c}/${d} flipped is ${d}/${c}.`,
        work: [op("÷"), frac(c, d), { t: "text", v: " becomes " }, op("×"), frac([answer("n", d)], [answer("d", c)])],
      },
      {
        id: "multiply", label: "Multiply",
        prompt: [frac(a, b), op("×"), frac(d, c), op("="), fracBoxes()], note: "Top times top, bottom times bottom.",
        slots: [{ id: "n", expected: a * d }, { id: "d", expected: b * c }], known: [],
        check: v => {
          if (both(v)) return { ok: false, soft: true, message: "Fill in both boxes, the top and the bottom." };
          if (v.n === a * d && v.d === b * c) return { ok: true };
          if (v.n === a * c && v.d === b * d) return { ok: false, kind: "Multiplied without flipping", message: "Use the flipped fraction from step 1.", generic: false };
          return { ok: false, kind: "Multiplying fractions", message: `Top: ${a} × ${d}. Bottom: ${b} × ${c}.`, generic: false };
        },
        hint: `${a} × ${d} on top, ${b} × ${c} on the bottom.`, explain: `${a} × ${d} = ${a * d} and ${b} × ${c} = ${b * c}.`,
        work: [frac(a, b), op("×"), frac(d, c), op("="), frac([answer("n", a * d)], [answer("d", b * c)])],
      },
      simplifyStep(a * d, b * c, "Simplify"),
    ],
    finalParts: [-1],
  };
}

function explain(p: DivideFractionsProblem) {
  const { a, b, c, d } = p, S = a * d, L = b * c, F = finalForm(S, L);
  const simplified = finalMath(S, L);
  const same = F.whole === 0 && F.num === S && F.den === L;
  return chainExplanation({
    heading: "Keep, change, flip",
    idea: ["Keep the first fraction, change ÷ to ×, and flip the second fraction. Then multiply and simplify."],
    statement: [frac(a, b), op("÷"), frac(c, d)],
    alt: `${a}/${b} ÷ ${c}/${d} becomes ${a}/${b} × ${d}/${c} = ${S}/${L}.`,
    beats: [
      { id: "flip", narration: `Keep ${a}/${b}, change ÷ to ×, and flip ${c}/${d} to ${d}/${c}.`, math: [frac(c, d), op("→"), frac(d, c)],
        lines: [[frac(a, b), op("÷"), mark([frac(c, d)])], [frac(a, b), mark([op("×")]), mark([frac(d, c)])]], answerStep: "flip" },
      { id: "multiply", narration: `Top times top, bottom times bottom: ${a} × ${d} = ${S} and ${b} × ${c} = ${L}.`, math: [frac(a, b), op("×"), frac(d, c), op("="), frac(S, L)],
        lines: [[frac(S, L)]], answerStep: "multiply" },
      { id: "simplify", narration: same ? `${S}/${L} is already as simple as it gets.` : S % L === 0 ? `${S} ÷ ${L} = ${S / L} exactly, so ${S}/${L} is the whole number ${S / L}.` : S >= L ? `${S} ÷ ${L} = ${Math.floor(S / L)} remainder ${S % L}, so ${S}/${L} is ${F.num ? `${F.whole ? `${F.whole} and ` : ""}${F.num}/${F.den}` : F.whole}.`
          : `Divide the top and the bottom by ${gcd(S, L)}: ${F.num}/${F.den}.`,
        math: [frac(S, L), op("="), ...simplified], lines: same ? [] : [[frac(S, L), op("="), ...simplified]], answerStep: "simplify",
        ...(F.num === 0 ? { result: F.whole } : {}) },
    ],
  });
}

export const lesson: LessonDefinition<DivideFractionsProblem> = {
  id: "g6-divide",
  grade: 6,
  unit: "Number system",
  title: "Dividing fractions",
  pre: "g5-multfrac",
  reference: createDivideFractions(2, 3, 1, 4), // 2/3 ÷ 1/4 = 8/3 = 2 2/3, the current app's example
  generate: rng => {
    const top = (den: number) => { let n: number; do n = rng.int(1, den - 1); while (gcd(n, den) !== 1); return n; };
    const b = rng.int(2, 9), d = rng.int(2, 9);
    return createDivideFractions(top(b), b, top(d), d);
  },
  restore: raw => restoreVia(raw, ["a", "b", "c", "d"] as const, v => createDivideFractions(v.a, v.b, v.c, v.d)),
  display: p => [frac(p.a, p.b), op("÷"), frac(p.c, p.d)],
  answers,
  explain,
  story: p => ({ op: "÷", text: `You have ${p.a}/${p.b} yard of ribbon. Each bow needs ${p.c}/${p.d} yard. How many bows can you make?` }),
};
