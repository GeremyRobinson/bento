// Add tens to a number: 23 + 30. Add tens to tens; the ones stay the same.
import { answer, num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildAddTens } from "../../../../explanations/diagrams/early-g1/blocks";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { count, onesOf, plural, slips, tensOf } from "../_kit";
import { count as countOf, verb } from "../../../text";
import { singularWork } from "../../gradeK/kit";

/** n + k tens; the sum stays under 100 */
export interface AddTensProblem { n: number; k: number }

export function createAddTens(n: number, k: number): AddTensProblem {
  wholeIn("n", n, 11, 89);
  wholeIn("k", k, 1, 9 - tensOf(n));
  return { n, k };
}

function answers({ n, k }: AddTensProblem): AnswerModel {
  const t = tensOf(n), o = onesOf(n), add = k * 10, tens = t + k, sum = n + add;
  return {
    steps: [
      oneBox({
        id: "k", label: `How many tens in ${add}?`,
        prompt: s => [num(add), op("="), s, text(" tens")], ans: k,
        wrong: slips(k, [[add, "Typed the number", `That's the number itself. How many tens make ${add}? Count by tens: 10, 20...`]]),
        hint: `Count by tens up to ${add}.`,
        explain: `${add} is ${plural(k, "ten", "tens")}.`,
      }),
      oneBox({
        id: "tens", label: "Add the tens", question: `${n} has ${plural(t, "ten", "tens")}. Add ${plural(k, "ten", "tens")} more.`,
        prompt: s => [num(t), op("+"), num(k), op("="), s, text(" tens")], ans: tens,
        wrong: slips(tens, [
          [o + k, "Added to the ones", `${o} is the ones. Add the tens to the **tens**: ${t} + ${k}.`],
          [t + add, "Added the whole number", `Add ${plural(k, "ten", "tens")}, not ${add}: ${t} + ${k}.`],
        ]),
        hint: `${t} + ${k}. Count on ${k} from ${t}.`,
        explain: `${countOf(t, "ten")} + ${countOf(k, "ten")} = ${countOf(tens, "ten")}.`,
      }),
      oneBox({
        id: "sum", label: "Put it together", note: "The ones stay the same.",
        prompt: s => [num(n), op("+"), num(add), op("="), s], ans: sum,
        wrong: slips(sum, [
          [n + k, "Added ones", `You added ${plural(k, "one", "ones")}. ${add} is ${plural(k, "ten", "tens")}, so the **tens** go up by ${k}.`],
          [tens * 10, "Left out the ones", `Don't forget the ${plural(o, "one", "ones")} from ${n}.`],
          [tens + o, "Added the digits", `${plural(tens, "ten", "tens")} is ${tens * 10}. Then the ${plural(o, "one", "ones")}.`],
        ]),
        hint: `${plural(tens, "ten", "tens")} and ${plural(o, "one", "ones")}.`,
        explain: `${plural(tens, "ten", "tens")} and ${plural(o, "one", "ones")} is ${sum}.`,
        work: [num(n), op("+"), num(add), op("="), answer("x", sum)],
      }),
    ],
    finalParts: [-1],
  };
}

function explain({ n }: AddTensProblem, model: AnswerModel): Explanation {
  const k = expectedOf(model, "k"), tens = expectedOf(model, "tens"), sum = expectedOf(model, "sum");
  const t = tensOf(n), o = onesOf(n), add = k * 10;
  return {
    heading: "Add tens to tens",
    idea: ["Adding tens only changes the tens. Put the tens rods together, and the ones stay just as they were."],
    statement: [num(n), op("+"), num(add)],
    diagram: buildAddTens({
      n, k,
      text: { start: `${n}: ${plural(t, "ten", "tens")}, ${plural(o, "one", "ones")}`, added: `+ ${plural(k, "ten", "tens")}`, tens: `${plural(tens, "ten", "tens")}, ${plural(o, "one", "ones")}`, total: `${n} + ${add} = ${sum}` },
      beats: { added: 1, tens: 2, total: 3 },
      alt: `${n} as tens rods and ones cubes; ${plural(k, "more rod", "more rods")} join the tens to make ${sum}.`,
    }),
    caption: `The tens go from ${t} to ${tens}. The ${countOf(o, "one")} ${verb(o, "stays", "stay")}.`,
    timeline: beats(4),
    steps: [
      { id: "start", narration: `Here is ${n}: ${plural(t, "ten", "tens")} and ${plural(o, "one", "ones")}.`, math: [num(n)], state: 0 },
      { id: "k", narration: `${add} is **${k}** tens rods. Bring them in next to the other tens.`, math: [num(add), op("="), ...count(k, "ten", "tens")], state: 1, answerStep: "k", result: k },
      { id: "tens", narration: `Count the rods: ${t} + ${k} = **${tens}** tens.`, math: [num(t), op("+"), num(k), op("="), num(tens)], state: 2, answerStep: "tens", result: tens },
      { id: "sum", narration: `${plural(tens, "ten", "tens")} and the same ${plural(o, "one", "ones")} make **${sum}**.`, math: [num(n), op("+"), num(add), op("="), num(sum)], state: 3, answerStep: "sum", result: sum },
    ],
  };
}

export const lesson: LessonDefinition<AddTensProblem> = {
  id: "g1-addtens",
  grade: 1,
  unit: "Adding and subtracting",
  title: "Add tens to a number",
  pre: "g1-tenmore",
  reference: createAddTens(23, 3),
  generate: (rng, index) => {
    const t = rng.int(1, index < 3 ? 4 : 8), n = t * 10 + rng.int(1, 9);
    return createAddTens(n, rng.int(index < 3 ? 2 : 1, Math.min(index < 3 ? 3 : 9, 9 - t)));
  },
  restore: raw => restoreVia(raw, ["n", "k"] as const, v => createAddTens(v.n, v.k)),
  display: p => [num(p.n), op("+"), num(p.k * 10)],
  answers: p => singularWork(answers(p)),
  explain,
};
