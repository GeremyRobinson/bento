// More, less or the same: count two rows, line them up dot under dot, and see which row has dots left over.
import { num, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { pairRows } from "../../../../explanations/diagrams/early-k/groups";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { TEN, countUp, slips, tapStep, words } from "../kit";
import { count } from "../../../text";

/** two rows of dots, 1 to 10 each */
export interface CompareProblem { top: number; bottom: number }

export function createCompare(top: number, bottom: number): CompareProblem {
  wholeIn("top", top, 1, TEN);
  wholeIn("bottom", bottom, 1, TEN);
  return { top, bottom };
}

export const CHOICES = ["More than", "Less than", "The same as"];
/** 0 more, 1 less, 2 the same */
const verdict = (top: number, bottom: number) => (top > bottom ? 0 : top < bottom ? 1 : 2);
const sentence = (top: number, bottom: number): MathText => [num(top), text(` is ${CHOICES[verdict(top, bottom)]!.toLowerCase()} `), num(bottom)];

function answers({ top, bottom }: CompareProblem): AnswerModel {
  const right = verdict(top, bottom), extra = Math.abs(top - bottom);
  const why = right === 2 ? `Both rows have ${top}. Every dot has a partner.`
    : `Line them up: the ${right === 0 ? "top" : "bottom"} row has ${extra} left over with no partner.`;
  return {
    steps: [
      oneBox({
        id: "top", label: "Count the top row", question: "How many dots are in the top row?",
        prompt: s => [text("Top: "), s], ans: top,
        wrong: slips(top, [
          [bottom, "Counted the wrong row", "That's the bottom row. Count the **top** row first."],
          [top - 1, "Skipped a dot", "One short. Touch each dot as you count."],
          [top + 1, "Counted a dot twice", "One too many. Touch each dot only once."],
        ]),
        hint: "Touch each dot in the top row and count.",
        explain: `${countUp(1, top)}. The top row has ${top}.`,
      }),
      oneBox({
        id: "bottom", label: "Count the bottom row", question: "How many dots are in the bottom row?",
        prompt: s => [text("Bottom: "), s], ans: bottom,
        wrong: slips(bottom, [
          [top, "Counted the wrong row", "That's the top row. Now count the **bottom** row."],
          [bottom - 1, "Skipped a dot", "One short. Touch each dot as you count."],
          [bottom + 1, "Counted a dot twice", "One too many. Touch each dot only once."],
        ]),
        hint: "Touch each dot in the bottom row and count.",
        explain: `${countUp(1, bottom)}. The bottom row has ${bottom}.`,
      }),
      tapStep({
        id: "compare", label: "Compare", question: `Is ${top} more than, less than or the same as ${bottom}?`,
        prompt: [num(top), text(" and "), num(bottom)],
        choices: CHOICES, right,
        wrong: i => i === 2
          ? ["Said the same", `They are not the same. ${top} and ${bottom} are different numbers. ${why}`]
          : right === 2
            ? ["Missed that they match", `Look again: both rows have ${top}. Every dot has a partner, so they are the same.`]
            : ["Mixed up more and less", `${top > bottom ? top : bottom} is the bigger number, so ${top} is ${CHOICES[right]!.toLowerCase()} ${bottom}. ${why}`],
        hint: "Match each top dot with a bottom dot. Which row has dots left over?",
        explain: `${why} So ${top} is ${CHOICES[right]!.toLowerCase()} ${bottom}.`,
        work: sentence(top, bottom),
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: CompareProblem, model: AnswerModel): Explanation {
  const top = expectedOf(model, "top"), bottom = expectedOf(model, "bottom"), right = expectedOf(model, "compare", "c");
  const extra = Math.abs(top - bottom);
  const matched = right === 2 ? `Every dot has a partner. ${top} is the same as ${bottom}.`
    : `The ${right === 0 ? "top" : "bottom"} row has ${extra} left over. So ${top} is ${CHOICES[right]!.toLowerCase()} ${bottom}.`;
  return {
    heading: "Match them up",
    idea: ["When you match the dots in pairs, the row with dots left over has more."],
    statement: words("Which row has more?"),
    diagram: pairRows({ top: p.top, bottom: p.bottom, beats: { top: 0, bottom: 1, match: 2 },
      alt: `${count(top, "dot")} on top and ${count(bottom, "dot")} below, matched in pairs. ${matched}` }),
    caption: matched,
    timeline: beats(3),
    steps: [
      { id: "top", narration: `Count the top row: ${countUp(1, top)}. That's **${top}**.`, math: [text("Top: "), num(top)], state: 0, answerStep: "top", result: top },
      { id: "bottom", narration: `Count the bottom row: ${countUp(1, bottom)}. That's **${bottom}**.`, math: [text("Bottom: "), num(bottom)], state: 1, answerStep: "bottom", result: bottom },
      { id: "compare", narration: `Match each top dot with a bottom dot. ${matched}`, math: sentence(top, bottom), state: 2, answerStep: "compare", result: right },
    ],
  };
}

export const lesson: LessonDefinition<CompareProblem> = {
  id: "k-compare",
  grade: 0,
  unit: "Counting",
  title: "More, less or the same",
  pre: "k-count20",
  reference: createCompare(6, 4),
  generate: (rng, index) => {
    const hi = index < 3 ? 5 : TEN, top = rng.int(1, hi);
    if (index >= 3 && rng.int(0, 4) === 0) return createCompare(top, top);
    // a different number for the bottom row; early problems differ by at least 2
    const gap = index < 3 ? 2 : 1;
    const options = Array.from({ length: hi }, (_, i) => i + 1).filter(v => Math.abs(v - top) >= gap);
    return createCompare(top, rng.pick(options));
  },
  restore: raw => restoreVia(raw, ["top", "bottom"] as const, v => createCompare(v.top, v.bottom)),
  display: () => words("Which row has more?"),
  displayNote: () => "Count each row. They might be the same!",
  picture: p => pairRows({ top: p.top, bottom: p.bottom, alt: `${count(p.top, "dot")} on top and ${count(p.bottom, "dot")} below` }),
  answers,
  explain,
};
