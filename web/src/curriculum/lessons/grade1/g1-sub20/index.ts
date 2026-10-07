// Subtract within 20 by going back through 10: 14 − 6 is 14 − 4 = 10, then 10 − 2 = 8.
import { answer, num, op } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildNumberLine } from "../../../../explanations/diagrams/number-line/build";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { slips } from "../_kit";
import { count, isAre } from "../../../text";

const TEN = 10;

/** a − b, where a is a teen number and b is big enough to go past 10 */
export interface Sub20Problem { a: number; b: number }

export function createSub20(a: number, b: number): Sub20Problem {
  wholeIn("a", a, 11, 18);
  wholeIn("b", b, a - TEN + 1, 9);
  return { a, b };
}

function answers({ a, b }: Sub20Problem): AnswerModel {
  const first = a - TEN, rest = b - first, res = a - b;
  return {
    steps: [
      oneBox({
        id: "to-ten", label: "Back to 10", question: `How many do you take away from ${a} to get to 10?`,
        prompt: s => [num(a), op("−"), s, op("="), num(TEN)], ans: first,
        wrong: slips(first, [
          [b, "Took it all at once", `Take away just enough to land on 10 first. ${a} is 10 and ${first} more.`],
          [TEN, "Took away the ten", `Keep the 10. Take away only the ${count(first, "one")} on top of it.`],
        ]),
        hint: `${a} is 10 and how many more?`,
        explain: `${a} is 10 and ${first} more, so take away ${first} to get to 10.`,
      }),
      oneBox({
        id: "rest", label: `Break apart ${b}`, question: `You took ${first} of the ${b}. How many are left to take?`,
        prompt: s => [num(b), op("="), num(first), op("+"), s], ans: rest,
        wrong: slips(rest, [
          [b + first, "Added", `The parts must be smaller than ${b}. What is ${b} take away ${first}?`],
          [first, "Repeated the first part", `${first} + ${first} isn't ${b}. Count up from ${first} to ${b}.`],
        ]),
        hint: `Count up from ${first} to ${b}.`,
        explain: `${b} is ${first} and ${rest}, so ${rest} ${isAre(rest)} left to take.`,
      }),
      oneBox({
        id: "from-ten", label: "Take the rest from 10", prompt: s => [num(TEN), op("−"), num(rest), op("="), s], ans: res,
        wrong: slips(res, [
          [TEN + rest, "Added", `This is taking away, so the answer is less than 10. Count back ${rest} from 10.`],
          [res + 1, "One short on the count back", `Count back one number for each: start at ${TEN - 1}, not 10.`],
          [res - 1, "Counted back too far", `Count back exactly ${rest}.`],
        ]),
        hint: `Count back ${rest} from 10.`,
        explain: `10 take away ${rest} is ${res}.`,
        work: [num(a), op("−"), num(b), op("="), answer("x", res)],
      }),
    ],
    finalParts: [-1],
  };
}

function explain({ a, b }: Sub20Problem, model: AnswerModel): Explanation {
  const first = expectedOf(model, "to-ten"), rest = expectedOf(model, "rest"), res = expectedOf(model, "from-ten");
  const min = Math.max(0, res - 2), max = a + 2;
  return {
    heading: "Go back through 10",
    idea: ["Take away in two hops. First hop back to 10, then take away the rest from 10."],
    statement: [num(a), op("−"), num(b)],
    diagram: buildNumberLine({
      min, max, labelAt: [TEN],
      marks: [{ v: a, label: `start ${a}`, beat: 0, until: 1 }, { v: res, label: String(res), beat: 3, cls: "dota" }],
      hops: [
        { from: a, to: TEN, below: true, label: `−${first}`, beat: 1 },
        { from: TEN, to: res, below: true, label: `−${rest}`, beat: 2, start: false },
      ],
      spans: [{ from: res, to: a, beat: 3 }],
      alt: `Number line from ${min} to ${max}: hop back ${first} from ${a} to 10, then ${rest} more to ${res}.`,
    }),
    caption: `${b} is ${first} and ${rest}. Back ${first} to 10, then back ${rest} more.`,
    // beat 0 is the bare line, so practice's first step doesn't show the hop it asks for
    timeline: beats(4),
    steps: [
      { id: "to-ten", narration: `${a} is 10 and ${first} more. Hop back **${first}** to land on 10.`, math: [num(a), op("−"), num(first), op("="), num(TEN)], state: 1, answerStep: "to-ten", result: first },
      { id: "rest", narration: `You still need to take ${b} in all. ${b} is ${first} and **${rest}**.`, math: [num(b), op("="), num(first), op("+"), num(rest)], state: 2, answerStep: "rest", result: rest },
      { id: "from-ten", narration: `Hop back ${rest} from 10. You land on **${res}**.`, math: [num(TEN), op("−"), num(rest), op("="), num(res)], state: 3, answerStep: "from-ten", result: res },
    ],
  };
}

export const lesson: LessonDefinition<Sub20Problem> = {
  id: "g1-sub20",
  grade: 1,
  unit: "Adding and subtracting",
  title: "Subtract within 20",
  pre: "g1-ten",
  reference: createSub20(14, 6),
  generate: (rng, index) => {
    const a = rng.int(11, index < 3 ? 14 : 18);
    return createSub20(a, rng.int(a - TEN + 1, 9));
  },
  restore: raw => restoreVia(raw, ["a", "b"] as const, v => createSub20(v.a, v.b)),
  display: p => [num(p.a), op("−"), num(p.b)],
  answers,
  explain,
};
