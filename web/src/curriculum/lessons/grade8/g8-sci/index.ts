// Scientific notation (the current app's g8-sci): move the point after the first digit and count the places.
import { formatNumber as f, num, op, sup, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildDecimalShift } from "../../../../explanations/diagrams/number-line/decimal-shift";
import { expectedOf, manyBoxes, oneBox, restoreVia, wholeIn, withCommas } from "../../_number-line/steps";
import { withEasyStart } from "../../easy-start";

/** the number (c / 10) × 10^e, written out in full: c is two digits, e is 3 to 7 */
export interface SciProblem { c: number; e: number }

export function createSci(c: number, e: number): SciProblem {
  wholeIn("c", c, 11, 99);
  wholeIn("e", e, 3, 7);
  return { c, e };
}

const full = ({ c, e }: SciProblem) => c * 10 ** (e - 1);

function answers(p: SciProblem): AnswerModel {
  const { c, e } = p, big = withCommas(full(p));
  return {
    steps: [
      oneBox({ id: "places", label: "Count the places", question: "Put the point after the first digit. How many places did it move?", prompt: s => [s], ans: e, hint: "Count the digits after the first one.",
        wrong: [[e + 1, "Counted every digit", "Count only the digits after the first one: the first digit stays in front of the point."]] }),
      manyBoxes({
        id: "write", label: "Write it",
        prompt: b => [text(big), op("="), b.c!, op("×"), num(10), sup([b.e!])], ans: { c: c / 10, e }, small: ["e"],
        hint: "Each place the point moves is one more × 10. The front number has to be at least 1 and less than 10.",
        wrong: [[{ c, e: e - 1 }, "Front number too big", "The front number has to be at least 1 and less than 10."]],
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: SciProblem, model: AnswerModel): Explanation {
  const n = full(p), digits = String(n), e = expectedOf(model, "places"), front = expectedOf(model, "write", "c");
  return {
    heading: "A number from 1 to 10, times a power of 10",
    idea: ["Move the decimal point until it sits just after the first digit. The number of places it moved is the power of 10."],
    statement: [text(withCommas(n)), op("="), num(front), op("×"), num(10), sup(e)],
    diagram: buildDecimalShift({
      digits, from: digits.length, to: digits.length - e, beat: 0, moveBeat: 1,
      label: `${e} hops left → ${f(front)}`,
      result: { text: `${f(front)} × 10`, sup: String(e), beat: 2 },
      alt: `The decimal point at the end of ${withCommas(n)} moves ${e} places left, giving ${f(front)} × 10 to the ${e}.`,
    }),
    timeline: beats(3),
    steps: [
      { id: "start", narration: `A whole number's decimal point sits at its end: ${withCommas(n)} is ${digits}.`, math: [text(withCommas(n))], state: 0 },
      { id: "places", narration: `Move the point to just after the first digit, ${digits[0]}. It moves ${e} places.`, math: [num(e), text(" places")], state: 1, answerStep: "places", result: e },
      { id: "write", narration: `The front number is ${f(front)}, between 1 and 10, and the power of 10 is the ${e} places: ${f(front)} × 10${"⁰¹²³⁴⁵⁶⁷⁸⁹"[e]}.`,
        math: [num(front), op("×"), num(10), sup(e)], state: 2, answerStep: "write", result: front },
    ],
  };
}

export const lesson: LessonDefinition<SciProblem> = withEasyStart({
  id: "g8-sci",
  grade: 8,
  unit: "Exponents and roots",
  title: "Scientific notation",
  reference: createSci(45, 4), // 45,000 = 4.5 × 10⁴, the current app's example
  generate: rng => createSci(rng.int(11, 99), rng.int(3, 7)),
  restore: raw => restoreVia(raw, ["c", "e"] as const, v => createSci(v.c, v.e)),
  display: p => [text(withCommas(full(p)))],
  displayNote: () => "Write it in scientific notation.",
  answers,
  explain,
});
