// Subtracting integers (the current app's g7-subint): subtracting is adding the opposite.
import { formatNumber as f, num, op } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildNumberLine, fitRange } from "../../../../explanations/diagrams/number-line/build";
import { expectedOf, oneBox, paren, restoreVia, wholeIn } from "../../_number-line/steps";

/** a − b, both nonzero (−12 to 12) */
export interface SubtractIntegersProblem { a: number; b: number }

export function createSubtractIntegers(a: number, b: number): SubtractIntegersProblem {
  wholeIn("a", a, -12, 12); wholeIn("b", b, -12, 12);
  if (a === 0 || b === 0) throw new Error("neither number is 0");
  return { a, b };
}

function answers({ a, b }: SubtractIntegersProblem): AnswerModel {
  const dir = b < 0 ? "right" : "left", B = Math.abs(b);
  return {
    steps: [
      oneBox({ id: "opp", label: "Add the opposite", question: `What is the opposite of ${f(b)}?`, prompt: s => [s], ans: -b, hint: "The opposite has the other sign.",
        wrong: [[b, "Kept the same sign", "The opposite flips the sign."]] }),
      oneBox({ id: "add", label: "Now add", prompt: s => [num(a), op("+"), ...paren(-b), op("="), s], ans: a - b,
        hint: `Start at ${f(a)} and move ${B} ${dir}.`, explain: `From ${f(a)}, moving ${B} ${dir} lands on ${f(a - b)}.`,
        wrong: [[a + b, "Forgot to change the sign", "Subtracting means adding the opposite."],
          [-(a - b), "Wrong sign", `From ${f(a)}, moving ${B} ${dir} lands on ${f(a - b)}.`]] }),
    ],
    finalParts: [-1],
  };
}

function explain(p: SubtractIntegersProblem, model: AnswerModel): Explanation {
  const { a, b } = p, opp = expectedOf(model, "opp"), diff = expectedOf(model, "add");
  const dir = opp > 0 ? "right" : "left", B = Math.abs(b);
  return {
    heading: "Subtracting is adding the opposite",
    idea: ["Taking away a debt makes you richer, so subtracting a negative adds."],
    statement: [num(a), op("−"), ...paren(b), op("="), num(a), op("+"), ...paren(opp)],
    diagram: buildNumberLine({
      ...fitRange([a, b, opp, diff, 0], { maxTicks: 34, pad: 1, minStep: 1 }),
      marks: [{ v: a, label: f(a), beat: 0, until: 1 }, { v: b, beat: 1, cls: "hole" }, { v: diff, label: f(diff), beat: 2, cls: "dota", delay: 0.6 }],
      hops: [
        { from: b, to: opp, label: "opposite", below: true, beat: 1, start: false },
        { from: a, to: diff, label: opp > 0 ? `+${opp}` : `+ (${f(opp)})`, beat: 2, land: false },
      ],
      alt: `Number line: ${f(b)} turns into ${f(opp)}; then from ${f(a)} move ${B} ${dir} to ${f(diff)}.`,
    }),
    caption: `Taking away ${f(b)} moves you ${B} ${dir}.`,
    timeline: beats(3),
    steps: [
      { id: "start", narration: `Start at ${f(a)}. Subtracting ${f(b)} is the same as adding its opposite.`, math: [num(a), op("−"), ...paren(b)], state: 0 },
      { id: "opp", narration: `The opposite of ${f(b)} is ${f(opp)}: the same distance from 0, on the other side.`, math: [num(b), op("→"), num(opp)], state: 1, answerStep: "opp", result: opp },
      { id: "add", narration: `Now add: ${f(a)} + ${opp < 0 ? `(${f(opp)})` : opp} = ${f(diff)}. Move ${B} ${dir}.`, math: [num(a), op("+"), ...paren(opp), op("="), num(diff)], state: 2, answerStep: "add", result: diff },
    ],
  };
}

export const lesson: LessonDefinition<SubtractIntegersProblem> = {
  id: "g7-subint",
  grade: 7,
  unit: "Integers",
  title: "Subtracting integers",
  pre: "g7-addint",
  reference: createSubtractIntegers(5, -3), // 5 − (−3) = 5 + 3 = 8, the current app's example
  generate: (rng, index = 3) => {
    // the first problems take away a negative from a positive: the case the idea is about
    if (index < 3) return createSubtractIntegers(rng.int(1, 6), -rng.int(1, 5));
    const nz = () => { let x: number; do x = rng.int(-12, 12); while (x === 0); return x; };
    const a = nz();
    return createSubtractIntegers(a, nz());
  },
  restore: raw => restoreVia(raw, ["a", "b"] as const, v => createSubtractIntegers(v.a, v.b)),
  display: p => [num(p.a), op("−"), ...paren(p.b)],
  answers,
  explain,
};
