// Skip counting: find the jump between the first numbers, then keep counting by 2s, 5s, 10s or 100s.
import { num, text, type MathText, type MathToken } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildSkipLine } from "../../../../explanations/diagrams/early-g2/lines";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { slips } from "../kit";

/** Six counts start, start + by, …; the first three are shown. */
export interface SkipProblem { start: number; by: number }

const JUMPS = [2, 5, 10, 100];
const SHOWN = 3, COUNTS = 6;

export function createSkip(start: number, by: number): SkipProblem {
  if (!JUMPS.includes(by)) throw new Error("count by 2, 5, 10 or 100");
  wholeIn("start", start, 0, 1000 - (COUNTS - 1) * by);
  return { start, by };
}

const countsOf = ({ start, by }: SkipProblem) => Array.from({ length: COUNTS }, (_, i) => start + i * by);

/** Early problems count by 2s, 5s or 10s from a multiple; later ones count by 5s, 10s or 100s from anywhere sensible. */
function generate(rng: Rng, index: number): SkipProblem {
  if (index < 3) {
    const by = rng.pick([2, 5, 10]);
    return createSkip(by * rng.int(0, 6), by);
  }
  const by = rng.pick([5, 10, 100]);
  if (by === 5) return createSkip(5 * rng.int(2, 30), 5);
  if (by === 10) return createSkip(rng.int(1, 60), 10);
  return createSkip(rng.int(1, 4) * 100 + rng.pick([0, 20, 50, rng.int(1, 99)]), 100);
}

const list = (vals: (number | MathToken)[]): MathText =>
  vals.flatMap((v, i) => [...(i ? [text(", ")] : []), typeof v === "number" ? num(v) : v]);

function answers(p: SkipProblem): AnswerModel {
  const { by } = p, v = countsOf(p);
  const nextStep = (i: number, id: string, label: string) => {
    const before = v[i - 1]!, ans = v[i]!;
    return oneBox({
      id, label, question: i === SHOWN ? `What comes after ${before}?` : "Keep going.",
      prompt: s => list([v[i - 2]!, before, s]), ans,
      wrong: slips(ans, [
        [before + 1, "Counted by ones", `Jump by ${by}, not by 1: ${before} + ${by}.`],
        by !== 10 && [before + 10, "Jumped by 10", `The jump is ${by}, not 10: ${before} + ${by}.`],
        [before - by, "Counted back", `The numbers are getting bigger, so count up: ${before} + ${by}.`],
      ]),
      hint: `Add ${by} to ${before}.`,
      explain: `${before} + ${by} = ${ans}.`,
    });
  };
  return {
    steps: [
      oneBox({
        id: "jump", label: "Find the jump", question: `How far is it from ${v[0]} to ${v[1]}?`,
        prompt: s => [num(v[0]!), text(" to "), num(v[1]!), text(" is a jump of "), s], ans: by,
        wrong: slips(by, [
          [1, "Counted by ones", by === 10 ? "Only the tens digit changes, by 1 ten. So the jump is 10." : by === 100 ? "Only the hundreds digit changes, by 1 hundred. So the jump is 100." : `The numbers grow by more than 1. Count up from ${v[0]} to ${v[1]}.`],
          by === 100 && [10, "Jumped by 10", "The tens digit stays the same. The hundreds digit grows by 1, so the jump is 100."],
          [v[1]!, "Wrote the next number", `${v[1]} is the next number. How far is the jump from ${v[0]}?`],
        ]),
        hint: `Count up from ${v[0]} to ${v[1]}.`,
        explain: `${v[0]} + ${by} = ${v[1]}, and ${v[1]} + ${by} = ${v[2]}. The jump is ${by}.`,
      }),
      nextStep(3, "next1", "Count on"),
      nextStep(4, "next2", "Count on again"),
      nextStep(5, "next3", "One more jump"),
    ],
    finalParts: [-1],
  };
}

function explain(p: SkipProblem, model: AnswerModel): Explanation {
  const v = countsOf(p), by = expectedOf(model, "jump");
  const a = expectedOf(model, "next1"), b = expectedOf(model, "next2"), c = expectedOf(model, "next3");
  return {
    heading: `Count by ${by}s`,
    idea: ["The numbers grow by the same jump every time."],
    statement: list([v[0]!, v[1]!, v[2]!, text("?"), text("?"), text("?")]),
    diagram: buildSkipLine({
      values: v, given: SHOWN, hop: `+${by}`, jumpBeat: 1, revealBeats: [2, 3, 4],
      alt: `A number line with ${v.slice(0, SHOWN).join(", ")}, then hops of ${by} to ${a}, ${b} and ${c}.`,
    }),
    caption: `Every hop is ${by}.`,
    timeline: beats(5),
    steps: [
      { id: "jump", narration: `From ${v[0]} to ${v[1]} is a jump of ${by}. So is ${v[1]} to ${v[2]}.`, math: [num(v[0]!), text(" to "), num(v[1]!), text(" is "), text("+"), num(by)], state: 1, answerStep: "jump", result: by },
      { id: "next1", narration: `Hop ${by} more from ${v[2]}: ${a}.`, math: list([v[1]!, v[2]!, a]), state: 2, answerStep: "next1", result: a },
      { id: "next2", narration: `Another hop of ${by}: ${b}.`, math: list([v[2]!, a, b]), state: 3, answerStep: "next2", result: b },
      { id: "next3", narration: `One more hop of ${by}: ${c}.`, math: list([a, b, c]), state: 4, answerStep: "next3", result: c },
    ],
  };
}

export const lesson: LessonDefinition<SkipProblem> = {
  id: "g2-skip",
  grade: 2,
  unit: "Place value",
  title: "Skip counting",
  pre: "k-tens",
  reference: createSkip(15, 5),
  generate,
  restore: raw => restoreVia(raw, ["start", "by"] as const, v => createSkip(v.start, v.by)),
  display: p => { const v = countsOf(p); return list([v[0]!, v[1]!, v[2]!, text("?"), text("?"), text("?")]); },
  displayNote: () => "Keep counting. What comes next?",
  answers,
  explain,
};
