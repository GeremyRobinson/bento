// Multiplying and dividing integers (the current app's g7-mulint): work with the sizes, then pick the sign.
import { formatNumber as f, num, op, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildNumberLine, fitRange, type Hop, type Mark } from "../../../../explanations/diagrams/number-line/build";
import { expectedOf, numbersOf, oneBox, paren, wholeIn } from "../../_number-line/steps";

/** a × b, or (a × b) ÷ b when div; a and b nonzero, −12 to 12 */
export interface MulIntegersProblem { a: number; b: number; div: boolean }

export function createMulIntegers(a: number, b: number, div: boolean): MulIntegersProblem {
  wholeIn("a", a, -12, 12); wholeIn("b", b, -12, 12);
  if (a === 0 || b === 0) throw new Error("neither number is 0");
  return { a, b, div };
}

const shown = ({ a, b, div }: MulIntegersProblem): MathText => (div ? [num(a * b), op("÷"), ...paren(b)] : [num(a), op("×"), ...paren(b)]);

function answers(p: MulIntegersProblem): AnswerModel {
  const { a, b, div } = p, ans = div ? a : a * b;
  return {
    steps: [
      oneBox({ id: "size", label: "Ignore the signs", prompt: s => (div ? [num(Math.abs(a * b)), op("÷"), num(Math.abs(b)), op("="), s] : [num(Math.abs(a)), op("×"), num(Math.abs(b)), op("="), s]),
        ans: Math.abs(ans), hint: div ? "Divide the sizes." : "Multiply the sizes." }),
      oneBox({ id: "sign", label: "Pick the sign", prompt: s => [...shown(p), op("="), s], ans, hint: "Same signs make a positive. Different signs make a negative.",
        wrong: [[-ans, "Wrong sign", "Same signs give a positive answer. Different signs give a negative one."]] }),
    ],
    finalParts: [-1],
  };
}

function explain(p: MulIntegersProblem, model: AnswerModel): Explanation {
  const { a, b, div } = p, size = expectedOf(model, "size"), ans = expectedOf(model, "sign");
  // sizes first, on the positive side: jumps of one size, as many as the other
  const jump = div ? Math.abs(b) : Math.abs(a), count = div ? size : Math.abs(b), reach = jump * count;
  // the signs that decide the answer: the factors when multiplying, the dividend a × b and the divisor b when dividing
  const differ = Math.sign(div ? a * b : a) !== Math.sign(b);
  const hops: Hop[] = Array.from({ length: count }, (_, i) => ({ from: i * jump, to: (i + 1) * jump, label: String(jump), beat: 0, delay: r(0.35 * i * Math.min(1, 6 / count)), start: i === 0 }));
  const jumps = `${count} ${count === 1 ? "jump" : "jumps"} of ${jump}`;
  const marks: Mark[] = [];
  let values: number[];
  if (div) {
    // the count of jumps is the size; the real jump, b, points toward the real dividend (positive) or away (negative)
    const n = a * b;
    marks.push({ v: reach, beat: 0, label: jumps, delay: 0.3 });
    hops.push({ from: 0, to: b, label: `jump ${f(b)}`, below: true, beat: 1 });
    if (n < 0) marks.push({ v: n, beat: 1, cls: "dota", label: f(n) });
    values = [0, reach, n, b];
  } else {
    // the product's size is where the jumps land; different signs flip it to the other side of 0
    if (differ) hops.push({ from: size, to: -size, label: "other sign", below: true, beat: 1, start: false });
    else marks.push({ v: size, beat: 1, cls: "dota" });
    values = differ ? [-size, reach, 0] : [0, reach];
  }
  const sign = differ ? "The signs are different, so it's negative." : "The signs match, so it's positive.";
  return {
    heading: "Same signs: positive. Different: negative.",
    idea: ["Work with the sizes first and ignore the signs. Then pick the sign: same signs make a positive, different signs make a negative."],
    statement: [...shown(p), op("="), num(ans)],
    diagram: buildNumberLine({
      ...fitRange(values, { maxTicks: 30, pad: 1, minStep: 1 }), labelAt: div ? [] : [size, ...(differ ? [-size] : [])],
      hops, marks,
      alt: `Number line: ${jumps} reach ${reach}; the answer is ${f(ans)}.`,
    }),
    caption: div ? `${jumps} make ${reach}, so the size is ${size}. ${sign}` : `${jumps} land on ${reach}. ${sign}`,
    timeline: beats(2),
    steps: [
      { id: "size", narration: div ? `Ignore the signs: ${Math.abs(a * b)} ÷ ${Math.abs(b)} = ${size}, because ${size} jump${size === 1 ? "" : "s"} of ${jump} make ${reach}.`
          : `Ignore the signs: ${Math.abs(a)} × ${Math.abs(b)} = ${size}, ${count} jump${count === 1 ? "" : "s"} of ${jump}.`,
        math: div ? [num(Math.abs(a * b)), op("÷"), num(Math.abs(b)), op("="), num(size)] : [num(Math.abs(a)), op("×"), num(Math.abs(b)), op("="), num(size)],
        state: 0, answerStep: "size", result: size },
      { id: "sign", narration: (differ ? `${f(div ? a * b : a)} and ${f(b)} have different signs, so the answer is negative: ${f(ans)}.`
          : `${f(div ? a * b : a)} and ${f(b)} have the same sign, so the answer is positive: ${f(ans)}.`)
          + (div ? ` A jump of ${f(b)} points ${differ ? "away from" : "toward"} ${f(a * b)}.` : ""),
        math: [...shown(p), op("="), num(ans)], state: 1, answerStep: "sign", result: ans },
    ],
  };
}

const r = (x: number) => Math.round(x * 100) / 100;

export const lesson: LessonDefinition<MulIntegersProblem> = {
  id: "g7-mulint",
  grade: 7,
  unit: "Integers",
  title: "Multiplying and dividing integers",
  reference: createMulIntegers(-6, 4, false), // −6 × 4 = −24, the current app's example
  generate: rng => {
    const nz = () => { let x: number; do x = rng.int(-12, 12); while (x === 0); return x; };
    const a = nz(), b = nz();
    return createMulIntegers(a, b, rng.next() < 0.5);
  },
  restore: raw => {
    const v = numbersOf(raw, ["a", "b"] as const), div = (raw as { div?: unknown } | null)?.div;
    if (!v || (div !== undefined && typeof div !== "boolean" && div !== 0 && div !== 1)) return null;
    try { return createMulIntegers(v.a, v.b, !!div); } catch { return null; }
  },
  display: shown,
  answers,
  explain,
};
