import { frac, num, op, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import type { TapeRow } from "../../../../explanations/diagrams/tape/schema";
import { expectedOf, gcd, ints, ns } from "../../_tape-family/steps";
import { count } from "../../../text";

/** a/b = ?/(b·k): the bottom is multiplied by k, so the top must be too. */
export interface EquivProblem { a: number; b: number; k: number }

export function createEquiv(a: number, b: number, k: number): EquivProblem {
  if (![a, b, k].every(Number.isInteger) || a < 1 || b < 2 || a >= b || k < 2) throw new Error(`not a proper fraction problem: ${a}/${b} × ${k}`);
  return { a, b, k };
}

/** A top for denominator d with no common factor (the current app's top1). */
export function coprimeTop(rng: Rng, d: number): number {
  let n: number;
  do n = rng.int(1, d - 1);
  while (gcd(n, d) !== 1);
  return n;
}

/** Same ranges as the current app: bottom 2–6, a top in lowest terms, multiplied by 2–5. */
export function generateEquiv(rng: Rng): EquivProblem {
  const b = rng.int(2, 6);
  const a = coprimeTop(rng, b);
  return createEquiv(a, b, rng.int(2, 5));
}

function answers({ a, b, k }: EquivProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "times", l: "Times what?", q: `The bottom went from ${b} to ${b * k}. What was it multiplied by?`, a: s => [num(b), op("×"), ...s, op("="), num(b * k)], ans: k,
        h: `Count by ${b}s up to ${b * k}.`, w: [[b * k - b, "Added instead of multiplied", "Fractions grow by multiplying, not adding."]] }),
      ns({ id: "top", l: "Same to the top", a: s => [num(a), op("×"), num(k), op("="), ...s], ans: a * k, h: "Whatever the bottom was multiplied by, multiply the top by the same number.",
        w: [[a, "Changed only the bottom", "Whatever you multiply the bottom by, multiply the top by too."], [a + b * k - b, "Added instead of multiplied", `Multiply the top by ${k}.`]] }),
    ],
    finalParts: [-1],
  };
}

/** k as a chain of prime cuts (4 = 2 × 2), so the picture can show 1/2 → 2/4 → 4/8 like the current app's card. */
export function cutChain(k: number): number[] {
  const out: number[] = [];
  for (let p = 2, r = k; r > 1; ) if (r % p === 0) { out.push(p); r /= p; } else p++;
  return out;
}

/**
 * Fraction bars: a/b, then the same bar cut into more pieces for each prime factor of k.
 * Beat 1 cuts the pieces (the bottom grows), beat 2 shades the same amount (the top grows by the same factor).
 */
export function equivPicture({ a, b, k }: EquivProblem) {
  const rows: TapeRow[] = [{ length: 1, parts: b, fills: [{ a: 0, b: a / b, tone: "on" }], label: [{ text: `${a}/${b}` }] }];
  let m = 1;
  for (const f of cutChain(k)) {
    m *= f;
    rows.push({
      length: 1, parts: b * m, from: 1,
      fills: [{ a: 0, b: a / b, tone: m === k ? "acc" : "on", from: 2 }],
      label: [{ text: `?/${b * m}`, until: 1 }, { text: `${a * m}/${b * m}`, from: 2, acc: m === k }],
      total: [{ text: `× ${f}` }],
    });
  }
  return buildTape({
    rows,
    guides: [{ at: a / b, rows: [0, rows.length - 1], from: 2 }],
    alt: `Fraction bars: ${a}/${b} shaded, then the same bar cut into ${count(b * k, "piece")} with ${a * k} shaded. The shaded amount is the same.`,
    width: 420,
  });
}

function explain(p: EquivProblem, model: AnswerModel): Explanation {
  const { a, b, k } = p;
  const K = expectedOf(model.steps, "times"), top = expectedOf(model.steps, "top");
  return {
    heading: "Same amount, smaller pieces",
    idea: ["When every piece is cut in 2, there are twice as many pieces, each half as big, so the amount stays the same.", "So multiply the top and the bottom by the same number."],
    statement: [frac(a, b), op("="), frac("?", b * k)],
    diagram: equivPicture(p),
    caption: `The same amount, cut into ${k} times as many pieces.`,
    timeline: beats(3),
    steps: [
      { id: "times", state: 1, answerStep: "times", result: K, math: [num(b), op("×"), num(K), op("="), num(b * k)],
        narration: `The bottom went from ${b} to ${b * k}: ${b} × ${K} = ${b * k}. Every piece is cut into ${K} smaller pieces.` },
      { id: "top", state: 2, answerStep: "top", result: top, math: [num(a), op("×"), num(K), op("="), num(top)],
        narration: `Do the same to the top: ${a} × ${K} = ${top}. The shaded part has not changed, so ${a}/${b} = ${top}/${b * k}.` },
    ],
  };
}

export const lesson: LessonDefinition<EquivProblem> = {
  id: "g4-equiv",
  grade: 4,
  unit: "Fractions",
  title: "Equivalent fractions",
  // the current app's card and picture: 1/2 = 2/4 = 4/8
  reference: createEquiv(1, 2, 4),
  generate: rng => generateEquiv(rng),
  restore: raw => {
    const r = ints(raw, ["a", "b", "k"] as const);
    try { return r && createEquiv(r.a, r.b, r.k); } catch { return null; }
  },
  display: (p): MathText => [frac(p.a, p.b), op("="), frac("?", p.b * p.k)],
  answers,
  explain,
};
