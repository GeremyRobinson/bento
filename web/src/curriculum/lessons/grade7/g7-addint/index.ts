// Adding integers (the current app's g7-addint): work with the sizes, then pick the sign.
import { formatNumber as f, num, op } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildNumberLine, fitRange, type Span } from "../../../../explanations/diagrams/number-line/build";
import { expectedOf, oneBox, paren, restoreVia, wholeIn } from "../../_number-line/steps";

/** a + b, both nonzero (−15 to 15), never both positive */
export interface AddIntegersProblem { a: number; b: number }

export function createAddIntegers(a: number, b: number): AddIntegersProblem {
  wholeIn("a", a, -15, 15); wholeIn("b", b, -15, 15);
  if (a === 0 || b === 0) throw new Error("neither number is 0");
  if (a > 0 && b > 0) throw new Error("at least one number is negative");
  return { a, b };
}

const sameSigns = ({ a, b }: AddIntegersProblem) => Math.sign(a) === Math.sign(b);

function answers(p: AddIntegersProblem): AnswerModel {
  const { a, b } = p, same = sameSigns(p), A = Math.abs(a), B = Math.abs(b);
  return {
    steps: [
      same
        ? oneBox({ id: "size", label: "Same signs: add the sizes", prompt: s => [num(A), op("+"), num(B), op("="), s], ans: A + B, hint: "Both are negative, so add their sizes.",
          wrong: A !== B ? [[Math.abs(A - B), "Subtracted the sizes", "Both numbers step the same way, so their sizes add."]] : [] })
        : oneBox({ id: "size", label: "Different signs: subtract the sizes", prompt: s => [num(Math.max(A, B)), op("−"), num(Math.min(A, B)), op("="), s], ans: Math.abs(A - B),
          hint: "Take the smaller size from the bigger one.",
          wrong: [[A + B, "Added the sizes", "One steps up and one steps down: the steps toward 0 cancel, so subtract the sizes."]] }),
      oneBox({
        id: "sign", label: "Pick the sign", prompt: s => [num(a), op("+"), ...paren(b), op("="), s], ans: a + b,
        hint: same ? "Two negatives make a negative." : "The answer takes the sign of the number farther from 0.",
        wrong: a + b !== 0 ? [[-(a + b), "Wrong sign", same ? "Both numbers are negative, so the answer is negative." : "Use the sign of the number with the bigger size."]] : [],
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: AddIntegersProblem, model: AnswerModel): Explanation {
  const { a, b } = p, same = sameSigns(p), A = Math.abs(a), B = Math.abs(b);
  const size = expectedOf(model, "size"), sum = expectedOf(model, "sign");
  const far = A > B ? a : b;
  const spans: Span[] = sum !== 0 ? [{ from: Math.min(0, sum), to: Math.max(0, sum), beat: 1, label: `${size} from 0` }] : [];
  return {
    heading: "Sizes and signs",
    idea: ["A negative number steps left of 0 and a positive steps right, so steps the same way add up and steps opposite ways cancel.", "The answer takes the sign of whichever side has more steps."],
    statement: [num(a), op("+"), ...paren(b), op("="), num(sum)],
    diagram: buildNumberLine({
      ...fitRange([a, sum, 0], { maxTicks: 34, pad: 1, minStep: 1 }),
      marks: [{ v: a, label: f(a), beat: 0, until: 0 }, { v: sum, label: f(sum), beat: 2, cls: "dota" }],
      hops: [{ from: a, to: sum, label: b > 0 ? `+${b}` : f(b), beat: 1 }],
      spans,
      alt: `Number line: start at ${f(a)} and move ${B} ${b > 0 ? "right" : "left"} to ${f(sum)}.`,
    }),
    caption: `Start at ${f(a)} and move ${B} ${b > 0 ? "right" : "left"}.`,
    timeline: beats(3),
    steps: [
      { id: "start", narration: `Start at ${f(a)}. Adding ${f(b)} moves ${B} to the ${b > 0 ? "right" : "left"}.`, math: [num(a), op("+"), ...paren(b)], state: 0 },
      { id: "size", narration: same ? `Same signs: add the sizes, ${A} + ${B} = ${size}.`
          : `Different signs: the steps toward 0 cancel, so subtract the sizes: ${Math.max(A, B)} − ${Math.min(A, B)} = ${size}.`,
        math: same ? [num(A), op("+"), num(B), op("="), num(size)] : [num(Math.max(A, B)), op("−"), num(Math.min(A, B)), op("="), num(size)],
        state: 1, answerStep: "size", result: size },
      { id: "sign", narration: same ? `Two negatives make a negative: ${f(sum)}.`
          : sum === 0 ? `The sizes are equal, so they cancel: ${f(sum)}.`
          : `${f(far)} is farther from 0 and it's ${far > 0 ? "positive" : "negative"}, so the answer is ${f(sum)}.`,
        math: [num(a), op("+"), ...paren(b), op("="), num(sum)], state: 2, answerStep: "sign", result: sum },
    ],
  };
}

export const lesson: LessonDefinition<AddIntegersProblem> = {
  id: "g7-addint",
  grade: 7,
  unit: "Integers",
  title: "Adding integers",
  pre: "g6-numline",
  reference: createAddIntegers(-7, 12), // −7 + 12 = 5, the current app's example
  generate: rng => {
    const nz = () => { let x: number; do x = rng.int(-15, 15); while (x === 0); return x; };
    let a: number, b: number;
    do { a = nz(); b = nz(); } while (a > 0 && b > 0);
    return createAddIntegers(a, b);
  },
  restore: raw => restoreVia(raw, ["a", "b"] as const, v => createAddIntegers(v.a, v.b)),
  display: p => [num(p.a), op("+"), ...paren(p.b)],
  answers,
  explain,
};
