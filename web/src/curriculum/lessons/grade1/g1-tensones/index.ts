// Tens and ones: count the rods (tens) and the cubes (ones), then name the number they make.
import { answer, num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTensOnes } from "../../../../explanations/diagrams/early-g1/blocks";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { count, onesOf, plural, slips, tensOf } from "../_kit";
import { singularWork } from "../../gradeK/kit";

/** a two-digit number shown as tens rods and ones cubes */
export interface TensOnesProblem { n: number }

export function createTensOnes(n: number): TensOnesProblem {
  wholeIn("n", n, 11, 99);
  return { n };
}

function answers({ n }: TensOnesProblem): AnswerModel {
  const t = tensOf(n), o = onesOf(n), tensValue = t * 10;
  const tw = t === 1 ? " ten and " : " tens and ", ow = o === 1 ? " one is " : " ones is ";
  return {
    steps: [
      oneBox({
        id: "tens", label: "Count the tens", question: "How many long rods? Each rod is a ten.",
        prompt: s => [s, text(" tens")], ans: t,
        wrong: slips(t, [
          [o, "Counted the ones", "Those are the little cubes. Count only the **long rods**."],
          [tensValue, "Counted the cubes in the rods", `You counted every cube in the rods. Count each rod as one ten.`],
          [n, "Typed the whole number", "Just the rods for now. How many long rods are there?"],
        ]),
        hint: "Touch each long rod and count: 1, 2, 3...",
        explain: `There ${t === 1 ? "is" : "are"} ${plural(t, "rod", "rods")}, so ${plural(t, "ten", "tens")}.`,
      }),
      oneBox({
        id: "ones", label: "Count the ones", question: "How many little cubes are on their own?",
        prompt: s => [s, text(" ones")], ans: o,
        wrong: slips(o, [
          [t, "Counted the tens", "That's how many rods. Now count the **little cubes** on the side."],
          [n, "Typed the whole number", "Just the little cubes for now. How many are there?"],
        ]),
        hint: o ? "Count the little cubes on their own, one at a time." : "Look beside the rods. Are there any cubes on their own?",
        explain: `There ${o === 1 ? "is" : "are"} ${plural(o, "cube", "cubes")} on ${o === 1 ? "its" : "their"} own, so ${plural(o, "one", "ones")}.`,
      }),
      oneBox({
        id: "number", label: "Name the number", prompt: s => [num(t), text(tw), num(o), text(ow), s], ans: n,
        wrong: slips(n, [
          [t + o, "Added the digits", `Each rod is worth 10, not 1. ${plural(t, "ten", "tens")} is ${tensValue}.`],
          [o * 10 + t, "Swapped tens and ones", `The tens come first. Write ${t}, then ${o}.`],
          [tensValue, "Left out the ones", `That's just the tens. Add the ${plural(o, "one", "ones")} too.`],
        ]),
        hint: o ? "Count the rods by 10s. Then count on the cubes by 1s." : "Count the rods by 10s. Are there any cubes to count on?",
        explain: `${tensValue} and ${o} more is ${n}.`,
        work: [num(t), text(tw), num(o), text(ow), answer("x", n)],
      }),
    ],
    finalParts: [-1],
  };
}

function explain(_p: TensOnesProblem, model: AnswerModel): Explanation {
  const t = expectedOf(model, "tens"), o = expectedOf(model, "ones"), n = expectedOf(model, "number");
  const byTen = Array.from({ length: t }, (_, i) => String((i + 1) * 10));
  return {
    heading: "Tens and ones",
    idea: ["A long rod is ten cubes stuck together, so you can count rods by tens."],
    statement: [text("? tens and ? ones")],
    diagram: buildTensOnes({
      tens: t, ones: o, tensCount: byTen,
      text: { tens: plural(t, "ten", "tens"), ones: plural(o, "one", "ones"), total: `${t * 10} + ${o} = ${n}` },
      beats: { tens: 0, ones: 1, total: 2 },
      alt: `${plural(t, "tens rod", "tens rods")} and ${plural(o, "ones cube", "ones cubes")} make ${n}.`,
    }),
    caption: `${plural(t, "ten", "tens")} and ${plural(o, "one", "ones")} make ${n}.`,
    timeline: beats(3),
    steps: [
      { id: "tens", narration: `Count the long rods by tens: ${byTen.join(", ")}. That's **${t}** tens.`, math: count(t, "ten", "tens"), state: 0, answerStep: "tens", result: t },
      { id: "ones", narration: o ? `Now the little cubes: **${o}** ones.` : "There are no little cubes on their own: **0** ones.", math: count(o, "one", "ones"), state: 1, answerStep: "ones", result: o },
      { id: "number", narration: `${t * 10} and ${o} more makes **${n}**. The tens digit is ${t}, the ones digit is ${o}.`, math: [num(t * 10), op("+"), num(o), op("="), num(n)], state: 2, answerStep: "number", result: n },
    ],
  };
}

export const lesson: LessonDefinition<TensOnesProblem> = {
  id: "g1-tensones",
  grade: 1,
  unit: "Place value",
  title: "Tens and ones",
  pre: "k-teens",
  reference: createTensOnes(34),
  generate: (rng, index) => createTensOnes(index < 3 ? rng.int(11, 39) : rng.int(11, 99)),
  restore: raw => restoreVia(raw, ["n"] as const, v => createTensOnes(v.n)),
  display: () => [text("What number is it?")],
  displayNote: () => "Count the tens rods and the ones cubes.",
  picture: p => buildTensOnes({ tens: tensOf(p.n), ones: onesOf(p.n), alt: `${plural(tensOf(p.n), "tens rod", "tens rods")} and ${plural(onesOf(p.n), "ones cube", "ones cubes")}` }),
  answers: p => singularWork(answers(p)),
  explain,
};
