// Multiplying decimals (the current app's g5-multdec): multiply without the points, count the places, place the point.
import { formatNumber as f, mark, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { chainExplanation } from "../../../../explanations/diagrams/chain/build";
import { expectedOf, oneBox, restoreVia, round6, wholeIn } from "../../_number-line/steps";
import { multiplyDecimalsPicture } from "./picture";

/** A/10 × B/10: A is two digits, B one digit */
export interface MultDecimalsProblem { A: number; B: number }

export function createMultDecimals(A: number, B: number): MultDecimalsProblem {
  wholeIn("A", A, 11, 99);
  wholeIn("B", B, 2, 9);
  return { A, B };
}

function answers({ A, B }: MultDecimalsProblem): AnswerModel {
  const x = A / 10, y = B / 10;
  return {
    steps: [
      oneBox({ id: "whole", label: "Multiply without the points", prompt: s => [num(A), op("×"), num(B), op("="), s], ans: A * B, hint: "Ignore the decimal points for now." }),
      oneBox({ id: "places", label: "Count the decimal places", question: "How many digits come after the points, in both numbers together?", prompt: s => [s], ans: 2,
        hint: `${f(x)} has 1 and ${f(y)} has 1.` }),
      oneBox({
        id: "place", label: "Place the point", prompt: s => [num(x), op("×"), num(y), op("="), s], ans: round6((A * B) / 100),
        hint: `Put the point 2 places from the right of ${A * B}.`,
        wrong: [[round6((A * B) / 10), "Point in the wrong place", "Count both numbers' decimal places: 1 + 1 = 2."],
          [A * B, "Forgot the decimal point", "Put the decimal point back, 2 places from the right."]],
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
  const { A, B } = p, x = A / 10, y = B / 10;
  const P = expectedOf(model, "whole"), places = expectedOf(model, "places"), ans = expectedOf(model, "place");
  return chainExplanation({
    heading: "Multiply, then place the point",
    idea: ["Multiply as if there were no decimal points. Then count the decimal places in both numbers together, and put that many digits after the point."],
    statement: [num(x), op("×"), num(y)],
    caption: `${f(x)} × ${f(y)} has the same digits as ${A} × ${B}; the ${places} decimal places say where the point goes.`,
    alt: `${f(x)} × ${f(y)}: ${A} × ${B} = ${P}, ${places} decimal places, so ${f(ans)}.`,
    diagram: multiplyDecimalsPicture({ A, B, P, ans }),
    beats: [
      { id: "whole", narration: `Ignore the points: ${A} × ${B} = ${P}.`, math: [num(A), op("×"), num(B), op("="), num(P)],
        lines: [[num(x), op("×"), num(y)], [num(A), op("×"), num(B), op("="), mark(P)]], answerStep: "whole", result: P },
      { id: "places", narration: `${f(x)} has 1 decimal place and ${f(y)} has 1, so ${places} in all.`, math: [num(1), op("+"), num(1), op("="), num(places)],
        lines: [[num(1), op("+"), num(1), op("="), num(places), text(" decimal places")]], answerStep: "places", result: places },
      { id: "place", narration: `Put the point ${places} places from the right of ${P}: ${f(ans)}.`, math: [num(x), op("×"), num(y), op("="), num(ans)],
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
  generate: rng => createMultDecimals(rng.int(11, 99), rng.int(2, 9)),
  restore: raw => restoreVia(raw, ["A", "B"] as const, v => createMultDecimals(v.A, v.B)),
  display: p => [num(p.A / 10), op("×"), num(p.B / 10)],
  answers,
  explain,
  story: p => ({ op: "×", text: `A garden bed is **${f(p.A / 10)}** m long and **${f(p.B / 10)}** m wide. What is its area in square meters?` }),
};
