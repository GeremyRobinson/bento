// 10 more, 10 less: only the tens change, by one. On the hundreds chart it is one row down or up.
import { answer, num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildHundredRows } from "../../../../explanations/diagrams/early-g1/chart";
import { buildTensOnes } from "../../../../explanations/diagrams/early-g1/blocks";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { count, onesOf, plural, slips, tensOf } from "../_kit";
import { count as countOf, verb } from "../../../text";
import { singularWork } from "../../gradeK/kit";

const TEN = 10;

/** n, and whether we want 10 more (more = 1) or 10 less (more = 0) */
export interface TenMoreProblem { n: number; more: number }

export function createTenMore(n: number, more: number): TenMoreProblem {
  wholeIn("n", n, 11, 89);
  wholeIn("more", more, 0, 1);
  return { n, more };
}

const words = (more: number) => (more ? "more" : "less");

function answers({ n, more }: TenMoreProblem): AnswerModel {
  const t = tensOf(n), o = onesOf(n), d = more ? 1 : -1, newT = t + d, res = n + d * TEN, w = words(more);
  return {
    steps: [
      oneBox({
        id: "tens", label: "Find the tens", prompt: s => [num(n), text(" has "), s, text(" tens")], ans: t,
        wrong: slips(t, [
          [o, "Read the ones digit", `That's the ones. The tens digit is the **first** digit of ${n}.`],
          [n, "Typed the whole number", `How many tens are in ${n}? Look at the first digit.`],
        ]),
        hint: `The first digit of ${n} tells the tens.`,
        explain: `${n} is ${plural(t, "ten", "tens")} and ${plural(o, "one", "ones")}.`,
      }),
      oneBox({
        id: "newtens", label: `One ten ${w}`, question: `10 ${w} means one ten ${w}.`,
        prompt: s => [...count(t, "ten", "tens"), op(more ? "+" : "−"), num(1), text(" ten"), op("="), s, text(" tens")], ans: newT,
        wrong: slips(newT, [
          [t, "Tens didn't change", `10 ${w} changes the tens by one. Go one ${more ? "up" : "down"} from ${t}.`],
          [t - d, "Went the wrong way", `That's one ten ${more ? "less" : "more"}. You want 10 ${w}, so go ${more ? "up" : "down"}.`],
        ]),
        hint: `Count ${more ? "up" : "back"} one from ${t}.`,
        explain: `${t} ${more ? "+" : "−"} 1 = ${newT}. Now there ${newT === 1 ? "is" : "are"} ${plural(newT, "ten", "tens")}.`,
      }),
      oneBox({
        id: "number", label: "Find the number", note: "The ones stay the same.",
        prompt: s => [num(n), op(more ? "+" : "−"), num(TEN), op("="), s], ans: res,
        wrong: slips(res, [
          [n + d, "Changed the ones", `That's 1 ${w}. For 10 ${w}, change the **tens** and keep the ${plural(o, "one", "ones")}.`],
          [n - d * TEN, "Went the wrong way", `That's 10 ${more ? "less" : "more"}. You want 10 ${w}.`],
          [newT, "Left out the ones", `That's just the tens. Put the ${plural(o, "one", "ones")} back on the end.`],
        ]),
        hint: `${plural(newT, "ten", "tens")} and ${plural(o, "one", "ones")}.`,
        explain: `${plural(newT, "ten", "tens")} and ${plural(o, "one", "ones")} is ${res}.`,
        work: [num(n), op(more ? "+" : "−"), num(TEN), op("="), answer("x", res)],
      }),
    ],
    finalParts: [-1],
  };
}

function explain({ n, more }: TenMoreProblem, model: AnswerModel): Explanation {
  const t = expectedOf(model, "tens"), newT = expectedOf(model, "newtens"), res = expectedOf(model, "number"), o = onesOf(n), w = words(more);
  const sign = more ? "+" : "−";
  return {
    heading: "10 more, 10 less",
    idea: ["Adding or taking 10 changes only the tens digit, by one. The ones stay the same. On the hundreds chart, that's one row down or one row up."],
    statement: [num(n), op(sign), num(TEN)],
    diagram: buildHundredRows({
      from: n, to: res, jump: `${sign}${TEN}`,
      notes: [
        { text: `${n} has ${plural(t, "ten", "tens")}`, beat: 0, until: 0 },
        { text: `one ten ${w}: ${plural(newT, "ten", "tens")}`, beat: 1, until: 1 },
        { text: `${n} ${sign} ${TEN} = ${res}`, beat: 2 },
      ],
      beats: { start: 0, jump: 1, land: 2 },
      alt: `Hundreds chart: from ${n}, jump one row ${more ? "down" : "up"} to ${res}.`,
    }),
    caption: `Only the tens change: ${t} becomes ${newT}. The ${countOf(o, "one")} ${verb(o, "stays", "stay")}.`,
    timeline: beats(3),
    steps: [
      { id: "tens", narration: `Find ${n} on the chart. It has **${t}** tens.`, math: count(t, "ten", "tens"), state: 0, answerStep: "tens", result: t },
      { id: "newtens", narration: `10 ${w} is one ten ${w}: ${t} ${sign} 1 = **${newT}** tens. On the chart, jump one row ${more ? "down" : "up"}.`, math: [num(t), op(sign), num(1), op("="), num(newT)], state: 1, answerStep: "newtens", result: newT },
      { id: "number", narration: `You land on **${res}**. The ones digit stayed ${o}.`, math: [num(n), op(sign), num(TEN), op("="), num(res)], state: 2, answerStep: "number", result: res },
    ],
  };
}

export const lesson: LessonDefinition<TenMoreProblem> = {
  id: "g1-tenmore",
  grade: 1,
  unit: "Place value",
  title: "10 more, 10 less",
  pre: "g1-tensones",
  reference: createTenMore(34, 1),
  generate: (rng, index) => {
    const more = index < 2 ? 1 : rng.int(0, 1);
    let n = rng.int(11, 89);
    if (!more && n < 20) n += 10; // keep the answer a two-digit number
    if (n % 10 === 0 && index < 4) n += rng.int(1, 9); // early problems have some ones to keep
    return createTenMore(n, more);
  },
  restore: raw => restoreVia(raw, ["n", "more"] as const, v => createTenMore(v.n, v.more)),
  display: p => [num(p.n), op(p.more ? "+" : "−"), num(TEN)],
  displayNote: p => `What is 10 ${words(p.more)} than ${p.n}?`,
  picture: p => buildTensOnes({ tens: tensOf(p.n), ones: onesOf(p.n), alt: `${p.n} as tens rods and ones cubes` }),
  answers: p => singularWork(answers(p)),
  explain,
};
