// Measure length with cubes laid end to end, with no gaps, from the very start of the thing. Then compare two lengths.
import { answer, num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildMeasure } from "../../../../explanations/diagrams/early-g1/measure";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { plural, slips } from "../_kit";
import { cap } from "../../../text";

export const THINGS = ["pencil", "crayon", "ribbon", "straw", "spoon", "leaf", "brush", "key"] as const;

/** two things (indexes into THINGS) with lengths a and b in cubes */
export interface MeasureProblem { x: number; y: number; a: number; b: number }

export function createMeasure(x: number, y: number, a: number, b: number): MeasureProblem {
  wholeIn("x", x, 0, THINGS.length - 1);
  wholeIn("y", y, 0, THINGS.length - 1);
  if (x === y) throw new Error("two different things");
  wholeIn("a", a, 2, 12);
  wholeIn("b", b, 2, 12);
  if (a === b) throw new Error("the lengths must differ");
  return { x, y, a, b };
}

const cubes = (n: number) => plural(n, "cube", "cubes");

function answers({ x, y, a, b }: MeasureProblem): AnswerModel {
  const one = THINGS[x]!, two = THINGS[y]!, diff = Math.abs(a - b);
  const longer = a > b ? one : two, shorter = a > b ? two : one;
  return {
    steps: [
      oneBox({
        id: "first", label: `Measure the ${one}`, question: `How many cubes long is the ${one}?`,
        prompt: s => [text(`${cap(one)}: `), s, text(" cubes")], ans: a,
        wrong: slips(a, [
          [b, "Measured the other one", `That's the ${two}. Count the cubes under the **${one}**.`],
          [a + 1, "Counted one cube twice", "One too many. Touch each cube just once as you count."],
          [a - 1, "Missed a cube", "One short. Start with the very first cube at the dashed line."],
        ]),
        hint: `Count the cubes under the ${one}, starting at the dashed line.`,
        explain: `The ${one} is ${cubes(a)} long.`,
      }),
      oneBox({
        id: "second", label: `Measure the ${two}`, question: `How many cubes long is the ${two}?`,
        prompt: s => [text(`${cap(two)}: `), s, text(" cubes")], ans: b,
        wrong: slips(b, [
          [a, "Measured the other one", `That's the ${one}. Count the cubes under the **${two}**.`],
          [b + 1, "Counted one cube twice", "One too many. Touch each cube just once as you count."],
          [b - 1, "Missed a cube", "One short. Start with the very first cube at the dashed line."],
        ]),
        hint: `Count the cubes under the ${two}, starting at the dashed line.`,
        explain: `The ${two} is ${cubes(b)} long.`,
      }),
      oneBox({
        id: "diff", label: "How much longer?", question: `How many cubes longer is the ${longer} than the ${shorter}?`,
        prompt: s => [num(Math.max(a, b)), op("−"), num(Math.min(a, b)), op("="), s], ans: diff,
        wrong: slips(diff, [
          [a + b, "Added the lengths", `That's both together. Find the **extra** cubes the ${longer} has.`],
          [Math.max(a, b), "Gave the longer length", `That's how long the ${longer} is. How many cubes **more** than the ${shorter}?`],
        ]),
        hint: `Count the cubes the ${longer} has past the end of the ${shorter}.`,
        explain: `${Math.max(a, b)} − ${Math.min(a, b)} = ${diff}. The ${longer} is ${cubes(diff)} longer.`,
        work: [num(Math.max(a, b)), op("−"), num(Math.min(a, b)), op("="), answer("x", diff), text(diff === 1 ? " cube longer" : " cubes longer")],
      }),
    ],
    finalParts: [-1],
  };
}

function explain({ x, y }: MeasureProblem, model: AnswerModel): Explanation {
  const a = expectedOf(model, "first"), b = expectedOf(model, "second"), diff = expectedOf(model, "diff");
  const one = THINGS[x]!, two = THINGS[y]!, longer = a > b ? one : two, shorter = a > b ? two : one;
  return {
    heading: "Measure with cubes",
    idea: ["Cubes lined up with no gaps cover the whole length, so their count is the length."],
    statement: [text(`${one} and ${two}`)],
    diagram: buildMeasure({
      things: [{ name: one, length: a }, { name: two, length: b }],
      beats: { rows: [0, 1], diff: 2 },
      diffText: `${diff} more`,
      alt: `The ${one} is ${cubes(a)} long and the ${two} is ${cubes(b)} long. The ${longer} has ${diff} extra.`,
    }),
    caption: `The ${longer} is ${cubes(diff)} longer than the ${shorter}.`,
    timeline: beats(3),
    steps: [
      { id: "first", narration: `Count the cubes under the ${one}: **${a}**.`, math: [text(`${cap(one)}: `), num(a), text(" cubes")], state: 0, answerStep: "first", result: a },
      { id: "second", narration: `Count the cubes under the ${two}: **${b}**.`, math: [text(`${cap(two)}: `), num(b), text(" cubes")], state: 1, answerStep: "second", result: b },
      { id: "diff", narration: `Both start at the same line. The ${longer} goes on for **${diff}** more ${diff === 1 ? "cube" : "cubes"}.`, math: [num(Math.max(a, b)), op("−"), num(Math.min(a, b)), op("="), num(diff)], state: 2, answerStep: "diff", result: diff },
    ],
  };
}

export const lesson: LessonDefinition<MeasureProblem> = {
  id: "g1-measure",
  grade: 1,
  unit: "Measurement and shapes",
  title: "Measure length",
  pre: "k-length",
  reference: createMeasure(0, 2, 7, 4),
  generate: (rng, index) => {
    const [x, y] = rng.shuffle(THINGS.map((_, i) => i)) as [number, number];
    const hi = index < 3 ? 8 : 12, a = rng.int(2, hi);
    let b = rng.int(2, hi - 1); if (b >= a) b++;
    return createMeasure(x, y, a, b);
  },
  restore: raw => restoreVia(raw, ["x", "y", "a", "b"] as const, v => createMeasure(v.x, v.y, v.a, v.b)),
  display: p => [text(`${THINGS[p.x]} and ${THINGS[p.y]}`)],
  displayNote: () => "Count the cubes under each one.",
  lead: p => `How long are the ${THINGS[p.x]} and the ${THINGS[p.y]}? Count the cubes under each one.`,
  picture: p => buildMeasure({ things: [{ name: THINGS[p.x]!, length: p.a }, { name: THINGS[p.y]!, length: p.b }], alt: `A ${THINGS[p.x]} and a ${THINGS[p.y]}, each with cubes under it` }),
  answers,
  explain,
};
