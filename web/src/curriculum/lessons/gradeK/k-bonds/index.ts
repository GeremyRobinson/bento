// Number bonds: a whole breaks into two parts. Count the whole, the first group, then the other group.
import { num, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { numberBond } from "../../../../explanations/diagrams/early-k/bond";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { countUp, slips, words } from "../kit";
import { count } from "../../../text";

/** whole dots, the first `part` of them in the first group */
export interface BondProblem { whole: number; part: number }

export function createBond(whole: number, part: number): BondProblem {
  wholeIn("whole", whole, 2, 10);
  wholeIn("part", part, 0, whole);
  return { whole, part };
}

function answers({ whole, part }: BondProblem): AnswerModel {
  const rest = whole - part;
  return {
    steps: [
      oneBox({
        id: "whole", label: "The whole", question: "How many dots in all?",
        prompt: x => [text("In all: "), x], ans: whole,
        wrong: slips(whole, [
          [part, "Counted one group", "That's just the first group. Count them all."],
          [whole - 1, "Skipped a dot", "One short. Touch each dot as you count."],
          [whole + 1, "Counted a dot twice", "One too many. Touch each dot only once."],
        ]),
        hint: "Count every dot.",
        explain: `${countUp(1, whole)}. There are ${count(whole, "dot")} in all.`,
      }),
      oneBox({
        id: "part", label: "One part", question: "How many are in the first group?",
        prompt: x => [text("First group: "), x], ans: part,
        wrong: slips(part, [
          [rest, "Counted the other group", "That's the other group. Count the first group."],
          [whole, "Counted all the dots", "That's all the dots. Count only the first group."],
        ]),
        hint: "Count only the dots in the first group.",
        explain: part ? `${countUp(1, part)}. The first group has ${part}.` : "The first group is empty: 0.",
      }),
      oneBox({
        id: "rest", label: "The other part", question: "How many are in the other group?",
        prompt: x => [text("Other group: "), x], ans: rest,
        wrong: slips(rest, [
          [part, "Counted the first group", "That's the first group again. Count the other group."],
          [whole, "Counted the whole", "That's the whole. The other group is smaller."],
          [whole + part, "Added the parts", "The parts are smaller than the whole. Count only the other group."],
        ]),
        hint: "Cover the first group. Count the rest.",
        explain: `${whole} is ${part} and ${rest}.`,
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: BondProblem, model: AnswerModel): Explanation {
  const w = expectedOf(model, "whole"), a = expectedOf(model, "part"), r = expectedOf(model, "rest");
  return {
    heading: "Break apart a number",
    idea: ["A number can break into two parts that make the whole again."],
    statement: words(w, "is", a, "and how many?"),
    diagram: numberBond({ whole: p.whole, part: p.part, beats: { whole: 0, first: 1, other: 2, sentence: 3 },
      alt: `A number bond: ${w} on top, ${a} and ${r} below. ${count(w, "dot")}: ${a} in the first group, ${r} in the other group.` }),
    caption: `${w} is ${a} and ${r}.`,
    timeline: beats(4),
    steps: [
      { id: "whole", narration: `Count all the dots: ${countUp(1, w)}. The whole is **${w}**.`, math: [text("In all: "), num(w)], state: 0, answerStep: "whole", result: w },
      { id: "part", narration: a ? `The first group has **${a}**.` : "The first group is empty: **0**.", math: [text("First group: "), num(a)], state: 1, answerStep: "part", result: a },
      { id: "rest", narration: `The other group has **${r}**.`, math: [text("Other group: "), num(r)], state: 2, answerStep: "rest", result: r },
      { id: "sentence", narration: `Put the parts together: ${w} is ${a} and ${r}.`, math: [num(w), text(" is "), num(a), text(" and "), num(r)], state: 3 },
    ],
  };
}

export const lesson: LessonDefinition<BondProblem> = {
  id: "k-bonds",
  grade: 0,
  unit: "Adding and subtracting",
  title: "Number bonds",
  reference: createBond(5, 2),
  generate: (rng, index) => {
    const whole = index < 3 ? rng.int(3, 5) : rng.int(4, 10);
    // "5 and 0 make 5" comes up once in a while, never early
    const part = index >= 6 && rng.int(0, 5) === 0 ? 0 : rng.int(1, whole - 1);
    return createBond(whole, part);
  },
  restore: raw => restoreVia(raw, ["whole", "part"] as const, v => createBond(v.whole, v.part)),
  display: () => words("How many are in the other group?"),
  picture: p => numberBond({ whole: p.whole, part: p.part, alt: `A number bond: ${p.whole} on top, ${p.part} and an empty circle below. ${count(p.whole, "dot")}: ${p.part} in the first group, the rest in the other group.` }),
  answers,
  explain,
  pre: "k-add",
};
