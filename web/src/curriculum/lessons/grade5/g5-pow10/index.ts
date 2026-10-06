// Multiply by 10, 100, 1000 (the current app's g5-pow10): each zero moves the decimal point one place right.
import { formatNumber as f, num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildDecimalShift } from "../../../../explanations/diagrams/number-line/decimal-shift";
import { expectedOf, oneBox, restoreVia, round6, wholeIn } from "../../_number-line/steps";

/** x (two decimal places at most, 1.01 to 99.99) × 10^k */
export interface PowerOfTenProblem { x: number; k: number }

export function createPowerOfTen(x: number, k: number): PowerOfTenProblem {
  wholeIn("x × 100", round6(x * 100), 101, 9999);
  wholeIn("k", k, 1, 3);
  return { x: round6(x), k };
}

const plural = (k: number, word: string) => `${k} ${word}${k > 1 ? "s" : ""}`;
const WORDS = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"];

function answers({ x, k }: PowerOfTenProblem): AnswerModel {
  const m = 10 ** k, ans = round6(x * m);
  return {
    steps: [
      oneBox({ id: "zeros", label: "Count the zeros", question: `How many zeros does ${m} have?`, prompt: s => [s], ans: k, hint: `Count the 0s in ${m}.`,
        wrong: [[k + 1, "Counted the 1 too", `The 1 isn't a zero. Count only the 0s in ${m}.`], [m, "Wrote the number", `That's the whole number. How many 0s are in it?`]] }),
      oneBox({
        id: "move", label: "Move the decimal point", question: `Move the point ${plural(k, "place")} to the right.`,
        prompt: s => [num(x), op("×"), num(m), op("="), s], ans, hint: "Each zero moves the point one place to the right.",
        wrong: [
          [round6((x * m) / 10), "Moved the point too few places", "Move it one place for each zero."],
          [round6(x * m * 10), "Moved the point too far", "Move it one place for each zero, no more."],
          [round6(x / m), "Moved the point the wrong way", `Multiplying by ${m} makes the number bigger, so the point moves right.`],
        ],
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: PowerOfTenProblem, model: AnswerModel): Explanation {
  const { x } = p, k = expectedOf(model, "zeros"), m = 10 ** k, ans = expectedOf(model, "move");
  const [whole, frac = ""] = f(x).split(".");
  return {
    heading: "Each zero moves the point",
    idea: ["Times 10 makes every digit worth ten times as much, so each digit shifts one place left and the point seems to hop one place right.", "Each zero in 10, 100 or 1000 is one hop."],
    statement: [num(x), op("×"), num(m), op("="), text("?")],
    diagram: buildDecimalShift({
      digits: whole! + frac, from: whole!.length, to: whole!.length + k, beat: 0, moveBeat: 1,
      label: `× ${m}: ${WORDS[k]} ${k > 1 ? "hops" : "hop"} right → ${f(ans)}`,
      alt: `The decimal point in ${f(x)} moves ${plural(k, "place")} to the right, making ${f(ans)}.`,
    }),
    timeline: beats(2),
    steps: [
      { id: "zeros", narration: `${m} has ${plural(k, "zero")}, so the decimal point moves ${plural(k, "place")} to the right.`,
        math: [num(m), text(` has ${plural(k, "zero")}`)], state: 0, answerStep: "zeros", result: k },
      { id: "move", narration: `Hop the point ${plural(k, "place")} right${frac.length < k ? ", writing a 0 in each empty place" : ""}: ${f(x)} × ${m} = ${f(ans)}.`,
        math: [num(x), op("×"), num(m), op("="), num(ans)], state: 1, answerStep: "move", result: ans },
    ],
  };
}

export const lesson: LessonDefinition<PowerOfTenProblem> = {
  id: "g5-pow10",
  grade: 5,
  unit: "Decimals",
  title: "Multiply by 10, 100, 1000",
  pre: "g4-dec",
  reference: createPowerOfTen(3.47, 2), // 3.47 × 100 = 347, the current app's example
  // the first three: a one-digit whole part times 10
  generate: (rng, index) => (index < 3 ? createPowerOfTen(rng.int(101, 999) / 100, 1) : createPowerOfTen(rng.int(101, 9999) / 100, rng.int(1, 3))),
  restore: raw => restoreVia(raw, ["x", "k"] as const, v => createPowerOfTen(v.x, v.k)),
  display: p => [num(p.x), op("×"), num(10 ** p.k)],
  answers,
  explain,
};
