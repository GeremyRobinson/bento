// Multiplying decimals (the current app's g5-multdec): multiply without the points, count the places, place the point.
import { formatNumber as f, mark, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { chainExplanation } from "../../../../explanations/diagrams/chain/build";
import { expectedOf, oneBox, restoreVia, round6, wholeIn } from "../../_number-line/steps";
import { multiplyDecimalsPicture } from "./picture";

/**
 * A/10^pa × B/10^pb. The current app always had tenths × tenths (pa = pb = 1, A two digits, B one digit);
 * the first problems now take a whole second number (pb = 0) and the last ones hundredths (pa = 2, A three digits).
 */
export interface MultDecimalsProblem { A: number; B: number; pa?: number; pb?: number }

export function createMultDecimals(A: number, B: number, pa = 1, pb = 1): MultDecimalsProblem {
  wholeIn("pa", pa, 1, 2); wholeIn("pb", pb, 0, 1);
  wholeIn("A", A, pa === 1 ? 11 : 101, pa === 1 ? 99 : 999);
  wholeIn("B", B, 2, 9);
  return pa === 1 && pb === 1 ? { A, B } : { A, B, pa, pb };
}

const placesOf = (p: MultDecimalsProblem) => ({ pa: p.pa ?? 1, pb: p.pb ?? 1 });
const valuesOf = (p: MultDecimalsProblem) => { const { pa, pb } = placesOf(p); return { x: round6(p.A / 10 ** pa), y: round6(p.B / 10 ** pb) }; };
const PLACE = ["ones", "tenths", "hundredths", "thousandths"];
const placeWord = (n: number) => (n === 1 ? "1 place" : `${n} places`);
type Slip = [number, string, string];

function answers(p: MultDecimalsProblem): AnswerModel {
  const { A, B } = p, { pa, pb } = placesOf(p), { x, y } = valuesOf(p), P = A * B, n = pa + pb, ans = round6(P / 10 ** n);
  const big = round6(P / 10 ** (n - 1)), small = round6(P / 10 ** (n + 1)), near = Math.round(x) * y;
  return {
    steps: [
      oneBox({ id: "whole", label: "Multiply without the points", prompt: s => [num(A), op("×"), num(B), op("="), s], ans: P,
        hint: `Leave the points out for now: ${f(x)} has the same digits as ${A}.`, explain: `Without the points it's ${A} × ${B} = ${P}.`,
        wrong: [[A + B, "Added instead of multiplied", `The sign is ×: ${A} × ${B}.`]] }),
      oneBox({ id: "places", label: "Count the decimal places", question: "How many digits come after the points, in both numbers together?", prompt: s => [s], ans: n,
        hint: `How many digits are after the point in ${f(x)}? And in ${f(y)}? Add them.`,
        explain: `${f(x)} has ${pa} and ${f(y)} has ${pb}, so ${n} in all.`,
        wrong: [pa, pb].filter((v, i, all) => v !== n && all.indexOf(v) === i).map((v): Slip => [v, "Counted one number", "Count the places in both numbers, not just one."]) }),
      oneBox({
        id: "place", label: "Place the point", prompt: s => [num(x), op("×"), num(y), op("="), s], ans,
        hint: `The answer counts ${PLACE[n]}, so ${placeWord(n)} ${n === 1 ? "goes" : "go"} after the point.`,
        explain: `Put the point ${placeWord(n)} from the right of ${P}: ${f(ans)}.`,
        wrong: [
          [big, "Point in the wrong place", pb ? `${f(big)} is too big. ${f(y)} is less than 1, so the answer must be less than ${f(x)}.`
            : `${f(big)} is too big. ${f(x)} × ${y} is close to ${Math.round(x)} × ${y} = ${near}.`],
          ...(small !== ans ? [[small, "Point in the wrong place", `${f(small)} is too small. Count the places again: ${pa} + ${pb} = ${n}.`] as Slip] : []),
          ...(P !== big ? [[P, "Forgot the decimal point", `Put the decimal point back, ${placeWord(n)} from the right.`] as Slip] : []),
        ],
      }),
    ],
    finalParts: [-1],
  };
}

/** the digits of a whole number with the point put `places` from the right; the digits after it are marked */
export function placePoint(digitsOf: number, places: number): MathText {
  const s = String(digitsOf).padStart(places + 1, "0");
  const whole = s.slice(0, -places), after = s.slice(-places);
  const value = round6(digitsOf / 10 ** places);
  const line: MathText = [text(`${whole}.`), mark(after)];
  return f(value) === `${whole}.${after}` ? line : [...line, op("="), num(value)];
}

function explain(p: MultDecimalsProblem, model: AnswerModel) {
  const { A, B } = p, { pa, pb } = placesOf(p), { x, y } = valuesOf(p);
  const P = expectedOf(model, "whole"), places = expectedOf(model, "places"), ans = expectedOf(model, "place");
  return chainExplanation({
    heading: "Multiply, then place the point",
    idea: [
      "A tenth of a tenth is a hundredth: 0.1 × 0.1 = 0.01.",
      `So ${f(x)} × ${f(y)} has the same digits as ${A} × ${B}, but the answer counts ${PLACE[places]}.`,
    ],
    statement: [num(x), op("×"), num(y)],
    caption: `${f(x)} × ${f(y)} has the same digits as ${A} × ${B}; the ${places} decimal places say where the point goes.`,
    alt: `${f(x)} × ${f(y)}: ${A} × ${B} = ${P}, ${places} decimal places, so ${f(ans)}.`,
    diagram: multiplyDecimalsPicture({ A, B, pa, pb, P, ans }),
    beats: [
      { id: "whole", narration: `Ignore the points: ${A} × ${B} = ${P}.`, math: [num(A), op("×"), num(B), op("="), num(P)],
        lines: [[num(x), op("×"), num(y)], [num(A), op("×"), num(B), op("="), mark(P)]], answerStep: "whole", result: P },
      { id: "places", narration: `${f(x)} has ${pa} decimal place${pa === 1 ? "" : "s"} and ${f(y)} has ${pb}, so ${places} in all.`, math: [num(pa), op("+"), num(pb), op("="), num(places)],
        lines: [[num(pa), op("+"), num(pb), op("="), num(places), text(places === 1 ? " decimal place" : " decimal places")]], answerStep: "places", result: places },
      { id: "place", narration: `The answer counts ${PLACE[places]}, so put the point ${placeWord(places)} from the right of ${P}: ${f(ans)}.`, math: [num(x), op("×"), num(y), op("="), num(ans)],
        lines: [placePoint(P, places)], answerStep: "place", result: ans },
    ],
  });
}

export const lesson: LessonDefinition<MultDecimalsProblem> = {
  id: "g5-multdec",
  grade: 5,
  unit: "Decimals",
  title: "Multiplying decimals",
  pre: "g5-mult2",
  reference: createMultDecimals(24, 3), // 2.4 × 0.3 = 0.72, the current app's example
  generate: (rng, index = 3) => {
    // tenths × a whole number first, then tenths × tenths, then hundredths × tenths, so the places answer changes
    const [pa, pb] = index < 3 ? [1, 0] : index < 6 ? [1, 1] : [2, 1];
    let A: number;
    do A = pa === 1 ? rng.int(11, 99) : rng.int(101, 999); while (A % 10 === 0);
    return createMultDecimals(A, rng.int(2, 9), pa, pb);
  },
  restore: raw => {
    const r = raw as Partial<MultDecimalsProblem> | null;
    return restoreVia(raw, ["A", "B"] as const, v => createMultDecimals(v.A, v.B, r?.pa ?? 1, r?.pb ?? 1));
  },
  display: p => { const { x, y } = valuesOf(p); return [num(x), op("×"), num(y)]; },
  answers,
  explain,
  story: p => ({ op: "×", text: `A garden bed is **${f(valuesOf(p).x)}** m long and **${f(valuesOf(p).y)}** m wide. What is its area in square meters?` }),
};
