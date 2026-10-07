// Taking away within 10: count them all, cross out the ones taken away, count what is left.
import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { changeDots } from "../../../../explanations/diagrams/early-k/groups";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { TEN, countUp, slips } from "../kit";
import { count, isAre } from "../../../text";

/** a dots, b of them taken away; 0 to a left */
export interface TakeAwayProblem { a: number; b: number }

export function createTakeAway(a: number, b: number): TakeAwayProblem {
  wholeIn("a", a, 2, TEN);
  wholeIn("b", b, 1, a);
  return { a, b };
}

const leftWords = (n: number) => (n === 0 ? "none are left" : n === 1 ? "1 is left" : `${n} are left`);

function answers({ a, b }: TakeAwayProblem): AnswerModel {
  const left = a - b;
  return {
    steps: [
      oneBox({
        id: "all", label: "Count them all", question: "How many dots are there to start?",
        prompt: s => [text("To start: "), s], ans: a,
        wrong: slips(a, [
          [b, "Counted the wrong number", `${b} is how many go away. First count **all** the dots.`],
          [a - 1, "Skipped a dot", "One short. Touch each dot as you count."],
          [a + 1, "Counted a dot twice", "One too many. Touch each dot only once."],
        ]),
        hint: "Touch each dot and count them all.",
        explain: `${countUp(1, a)}. There ${isAre(a)} ${count(a, "dot")} to start.`,
      }),
      oneBox({
        id: "left", label: "Take away", question: `Cross out ${b}. How many are left?`,
        prompt: s => [num(a), op("−"), num(b), op("="), s], ans: left,
        wrong: slips(left, [
          [a + b, "Added instead", `That's ${a} and ${b} put together. Taking away leaves **fewer** than ${a}.`],
          [b, "Counted the ones taken away", `${b} is how many you took away. Count the dots that are **not** crossed out.`],
          [a, "Didn't take any away", `That's how many you started with. Cross out ${b}, then count the rest.`],
          [left + 1, "One too many", "One too many. Skip the crossed-out dots when you count."],
          [left - 1, "One short", "One short. Count every dot that is not crossed out."],
        ]),
        hint: `Cross out ${count(b, "dot")}. Then count the dots that are left.`,
        explain: `Cross out ${b} of the ${a}. Count the rest: ${left ? countUp(1, left) : "there are none"}. So ${leftWords(left)}.`,
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: TakeAwayProblem, model: AnswerModel): Explanation {
  const { b } = p, a = expectedOf(model, "all"), left = expectedOf(model, "left");
  return {
    heading: "Take away and count",
    idea: ["Taking away leaves fewer, and the ones that are left are the answer."],
    statement: [num(a), op("−"), num(b)],
    diagram: changeDots({ start: p.a, change: b, kind: "take", beats: { start: 0, change: 1, end: 2 },
      alt: `${count(a, "dot")}. ${b} ${isAre(b)} crossed out and ${leftWords(left)}.` }),
    caption: `${a} take away ${b} leaves ${left}.`,
    timeline: beats(3),
    steps: [
      { id: "all", narration: `Count them all: ${countUp(1, a)}. You start with **${a}**.`, math: [text("To start: "), num(a)], state: 0, answerStep: "all", result: a },
      { id: "cross", narration: `Take away ${b}: cross out ${b === 1 ? "1 dot" : `${count(b, "dot")}`}.`, math: [num(a), op("−"), num(b)], state: 1 },
      { id: "left", narration: left ? `Count the dots that are left: ${countUp(1, left)}. **${left}** left.` : "Every dot is crossed out. **0** left.",
        math: [num(a), op("−"), num(b), op("="), num(left)], state: 2, answerStep: "left", result: left },
    ],
  };
}

export const lesson: LessonDefinition<TakeAwayProblem> = {
  id: "k-sub",
  grade: 0,
  unit: "Adding and subtracting",
  title: "Taking away within 10",
  pre: "k-add",
  reference: createTakeAway(7, 3),
  generate: (rng, index) => {
    const a = rng.int(index < 3 ? 2 : 4, index < 3 ? 5 : TEN);
    return createTakeAway(a, rng.int(1, index < 3 ? a - 1 : a));
  },
  restore: raw => restoreVia(raw, ["a", "b"] as const, v => createTakeAway(v.a, v.b)),
  display: p => [num(p.a), op("−"), num(p.b)],
  picture: p => changeDots({ start: p.a, change: p.b, kind: "take", alt: `${count(p.a, "dot")}` }),
  answers,
  explain,
};
