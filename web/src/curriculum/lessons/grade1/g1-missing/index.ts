// Missing numbers: 8 + ? = 13. Count up from 8 to 13, going through 10, and add up the hops.
import { answer, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildNumberLine } from "../../../../explanations/diagrams/number-line/build";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { slips } from "../_kit";

const TEN = 10;

/** a + ? = c (or ? + a = c when first = 1); counting up from a to c passes 10 */
export interface MissingProblem { a: number; c: number; first: number }

export function createMissing(a: number, c: number, first: number): MissingProblem {
  wholeIn("a", a, 2, 9);
  wholeIn("c", c, 11, Math.min(18, a + 9));
  wholeIn("first", first, 0, 1);
  return { a, c, first };
}

const Q = text("?");
const equation = ({ a, c, first }: MissingProblem, box: MathText = [Q]): MathText =>
  first ? [...box, op("+"), num(a), op("="), num(c)] : [num(a), op("+"), ...box, op("="), num(c)];

function answers(p: MissingProblem): AnswerModel {
  const { a, c } = p, up = TEN - a, rest = c - TEN, miss = c - a;
  return {
    steps: [
      oneBox({
        id: "to-ten", label: "Count up to 10", question: `Start at ${a}. How many to get to 10?`,
        prompt: s => [num(a), op("+"), s, op("="), num(TEN)], ans: up,
        wrong: slips(up, [
          [TEN, "Typed 10", `10 is where you stop. How many hops from ${a} to 10?`],
          [up + 1, "Counted the start", `Don't count ${a} itself. Your first hop lands on ${a + 1}.`],
        ]),
        hint: `Count up from ${a} to 10 on your fingers.`,
        explain: `${a} + ${up} = 10.`,
      }),
      oneBox({
        id: "past-ten", label: `Count up to ${c}`, question: `Now from 10. How many to get to ${c}?`,
        prompt: s => [num(TEN), op("+"), s, op("="), num(c)], ans: rest,
        wrong: slips(rest, [
          [c, "Typed the total", `${c} is where you stop. How many hops from 10 to ${c}?`],
        ]),
        hint: `${c} is 10 and how many more?`,
        explain: `10 + ${rest} = ${c}.`,
      }),
      oneBox({
        id: "missing", label: "Add up the hops", prompt: s => [num(up), op("+"), num(rest), op("="), s], ans: miss,
        wrong: slips(miss, [
          [c, "Typed the total", `${c} is already there. The missing number is how far it is from ${a} to ${c}.`],
          [c + a, "Added everything", `That adds ${a} too. Only add the hops: ${up} and ${rest}.`],
          [up, "Used one hop", `Add both hops: ${up} to get to 10, and ${rest} more.`],
        ]),
        hint: `Put the hops together: ${up} and ${rest}.`,
        explain: `${up} + ${rest} = ${miss}, so the missing number is ${miss}.`,
        work: equation(p, [answer("x", miss)]),
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: MissingProblem, model: AnswerModel): Explanation {
  const { a, c } = p, up = expectedOf(model, "to-ten"), rest = expectedOf(model, "past-ten"), miss = expectedOf(model, "missing");
  const min = Math.max(0, a - 2), max = c + 2;
  return {
    heading: "Count up to find it",
    idea: ["To find a missing part, count up from the part you know to the total. Stop at 10 on the way, it makes the counting easy."],
    statement: equation(p),
    diagram: buildNumberLine({
      min, max, labelAt: [TEN],
      marks: [{ v: a, label: `start ${a}`, beat: 0, until: 1 }],
      hops: [
        { from: a, to: TEN, label: `+${up}`, beat: 1 },
        { from: TEN, to: c, label: `+${rest}`, beat: 2, start: false },
      ],
      spans: [{ from: a, to: c, beat: 3, label: `${up} + ${rest} = ${miss}` }],
      alt: `Number line from ${min} to ${max}: hop ${up} from ${a} to 10, then ${rest} more to ${c}. The hops make ${miss}.`,
    }),
    caption: `From ${a} to ${c} is ${miss}.`,
    // beat 0 is the bare line, so practice's first step doesn't show the hop it asks for
    timeline: beats(4),
    steps: [
      { id: "to-ten", narration: `Start at ${a}. Hop **${up}** to get to 10.`, math: [num(a), op("+"), num(up), op("="), num(TEN)], state: 1, answerStep: "to-ten", result: up },
      { id: "past-ten", narration: `From 10, hop **${rest}** more to get to ${c}.`, math: [num(TEN), op("+"), num(rest), op("="), num(c)], state: 2, answerStep: "past-ten", result: rest },
      { id: "missing", narration: `The hops are ${up} and ${rest}. Together that's **${miss}**, the missing number.`, math: equation(p, [num(miss)]), state: 3, answerStep: "missing", result: miss },
    ],
  };
}

export const lesson: LessonDefinition<MissingProblem> = {
  id: "g1-missing",
  grade: 1,
  unit: "Adding and subtracting",
  title: "Missing numbers",
  pre: "g1-sub20",
  reference: createMissing(8, 13, 0),
  generate: (rng, index) => {
    const a = rng.int(index < 3 ? 6 : 2, 9);
    return createMissing(a, rng.int(11, Math.min(18, a + 9)), index < 3 ? 0 : rng.int(0, 1));
  },
  restore: raw => restoreVia(raw, ["a", "c", "first"] as const, v => createMissing(v.a, v.c, v.first)),
  display: p => equation(p),
  displayNote: () => "What number is missing?",
  answers,
  explain,
};
