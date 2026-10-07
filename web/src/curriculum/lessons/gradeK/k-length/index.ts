// Longer and shorter: line two things up at the same start, measure each in cubes, and see which one sticks out.
import { num, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { lengthBars } from "../../../../explanations/diagrams/early-k/lengths";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { TEN, countUp, indexIn, slips, tapStep, words } from "../kit";
import { count } from "../../../text";

const THINGS = ["pencil", "crayon", "ribbon", "spoon", "snake", "straw"] as const;

/** two things (top and bottom pick from THINGS), a and b cubes long */
export interface LengthProblem { top: number; bottom: number; a: number; b: number }

export function createLength(top: number, bottom: number, a: number, b: number): LengthProblem {
  indexIn("top", top, THINGS);
  indexIn("bottom", bottom, THINGS);
  if (top === bottom) throw new Error("the two things must be different");
  wholeIn("a", a, 2, TEN);
  wholeIn("b", b, 2, TEN);
  return { top, bottom, a, b };
}

const cap = (s: string) => `${s[0]!.toUpperCase()}${s.slice(1)}`;
const cubes = (n: number) => (n === 1 ? "1 cube" : `${count(n, "cube")}`);

function answers(p: LengthProblem): AnswerModel {
  const { a, b } = p, top = THINGS[p.top]!, bottom = THINGS[p.bottom]!;
  const right = a > b ? 0 : a < b ? 1 : 2, extra = Math.abs(a - b);
  const longer = a > b ? top : bottom, shorter = a > b ? bottom : top;
  const choices = [`The ${top}`, `The ${bottom}`, "Same length"];
  const why = right === 2 ? `Both are ${cubes(a)} long.` : `The ${longer} is ${cubes(Math.max(a, b))} long. The ${shorter} is only ${cubes(Math.min(a, b))}.`;
  const sentence: MathText = right === 2
    ? [text(`The ${top} and the ${bottom} are the same length.`)]
    : [text(`The ${longer} is longer by `), num(extra), text(extra === 1 ? " cube." : " cubes.")];
  const measure = (id: string, name: string, n: number, other: number) => oneBox({
    id, label: `Measure the ${name}`, question: `How many cubes long is the ${name}?`,
    prompt: s => [text(`${cap(name)}: `), s, text(" cubes")], ans: n,
    wrong: slips(n, [
      [other, "Measured the other one", `That's the other one. Count the cubes along the **${name}**.`],
      [n - 1, "Skipped a cube", "One short. Touch each cube as you count."],
      [n + 1, "Counted a cube twice", "One too many. Touch each cube only once."],
    ]),
    hint: `Start at the line on the left. Count each cube along the ${name}.`,
    explain: `${countUp(1, n)}. The ${name} is ${cubes(n)} long.`,
  });
  return {
    steps: [
      measure("top", top, a, b),
      measure("bottom", bottom, b, a),
      tapStep({
        id: "longer", label: "Which is longer?", question: `Which is longer, the ${top} or the ${bottom}?`,
        prompt: [num(a), text(" cubes and "), num(b), text(" cubes")],
        choices, right,
        wrong: i => i === 2
          ? ["Said the same", `They are not the same. ${why}`]
          : right === 2
            ? ["Missed that they match", `Look again: both are ${cubes(a)} long. They end at the same place.`]
            : ["Picked the shorter one", `${why} The ${longer} sticks out past the end of the ${shorter}.`],
        hint: "Both start at the same line. Which one sticks out further at the end?",
        explain: right === 2 ? `${why} They are the same length.` : `${why} ${Math.max(a, b)} is more than ${Math.min(a, b)}, so the ${longer} is longer.`,
        work: sentence,
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: LengthProblem, model: AnswerModel): Explanation {
  const top = THINGS[p.top]!, bottom = THINGS[p.bottom]!;
  const a = expectedOf(model, "top"), b = expectedOf(model, "bottom"), right = expectedOf(model, "longer", "c");
  const extra = Math.abs(a - b), longer = a > b ? top : bottom;
  const verdict = right === 2 ? "They end at the same place: the same length." : `The ${longer} sticks out ${cubes(extra)} more. It is longer.`;
  return {
    heading: "Line them up",
    idea: ["When both start at the same line, the one that sticks out further is longer."],
    statement: words("Which is longer?"),
    diagram: lengthBars({
      top: { name: top, cubes: p.a }, bottom: { name: bottom, cubes: p.b }, beats: { top: 0, bottom: 1, compare: 2 },
      alt: `The ${top} is ${cubes(a)} long and the ${bottom} is ${cubes(b)} long. ${verdict}`,
    }),
    caption: verdict,
    timeline: beats(3),
    steps: [
      { id: "top", narration: `Count the cubes along the ${top}: ${countUp(1, a)}. It's **${a}** cubes long.`, math: [text(`${cap(top)}: `), num(a), text(" cubes")], state: 0, answerStep: "top", result: a },
      { id: "bottom", narration: `Now the ${bottom}: ${countUp(1, b)}. It's **${b}** cubes long.`, math: [text(`${cap(bottom)}: `), num(b), text(" cubes")], state: 1, answerStep: "bottom", result: b },
      { id: "longer", narration: verdict, math: right === 2 ? [text("Same length")] : [text(`The ${longer} is longer.`)], state: 2, answerStep: "longer", result: right },
    ],
  };
}

export const lesson: LessonDefinition<LengthProblem> = {
  id: "k-length",
  grade: 0,
  unit: "Shapes and measuring",
  title: "Longer and shorter",
  reference: createLength(0, 2, 7, 4),
  generate: (rng, index) => {
    const [top, bottom] = rng.shuffle(THINGS.map((_, i) => i)) as [number, number];
    const easy = index < 3, hi = easy ? 8 : TEN, a = rng.int(2, hi);
    if (!easy && rng.int(0, 5) === 0) return createLength(top, bottom, a, a);
    // early problems differ by at least 3 cubes, so the longer one is easy to see
    const options = Array.from({ length: hi - 1 }, (_, i) => i + 2).filter(v => Math.abs(v - a) >= (easy ? 3 : 1));
    return createLength(top, bottom, a, rng.pick(options));
  },
  restore: raw => restoreVia(raw, ["top", "bottom", "a", "b"] as const, v => createLength(v.top, v.bottom, v.a, v.b)),
  display: () => words("Which is longer?"),
  displayNote: p => `The ${THINGS[p.top]!} or the ${THINGS[p.bottom]!}?`,
  picture: p => lengthBars({ top: { name: THINGS[p.top]!, cubes: p.a }, bottom: { name: THINGS[p.bottom]!, cubes: p.b }, alt: `A ${THINGS[p.top]!} and a ${THINGS[p.bottom]!} lined up` }),
  answers,
  explain,
};
