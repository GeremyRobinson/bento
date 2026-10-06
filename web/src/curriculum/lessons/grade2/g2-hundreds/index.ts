// Hundreds, tens and ones: a three-digit number taken apart by place, then written in expanded form.
import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlaceBlocks } from "../../../../explanations/diagrams/early-g2/blocks";
import { expectedOf, manyBoxes, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { count, slips } from "../kit";
import { isAre } from "../../../text";

/** A three-digit number. */
export interface HundredsProblem { n: number }

export function createHundreds(n: number): HundredsProblem {
  wholeIn("n", n, 100, 999);
  return { n };
}

const digits = (n: number) => ({ h: Math.floor(n / 100), t: Math.floor(n / 10) % 10, o: n % 10 });

/** Early problems have no zeros; later ones may have a zero in the tens or the ones. */
function generate(rng: { int(lo: number, hi: number): number }, index: number): HundredsProblem {
  const lo = index < 3 ? 1 : 0;
  return createHundreds(rng.int(1, 9) * 100 + rng.int(lo, 9) * 10 + rng.int(lo, 9));
}

function answers({ n }: HundredsProblem): AnswerModel {
  const { h, t, o } = digits(n);
  const expanded = { h: h * 100, t: t * 10, o };
  const same = (v: Record<string, number>) => v.h === expanded.h && v.t === expanded.t && v.o === expanded.o;
  return {
    steps: [
      oneBox({
        id: "hundreds", label: "Count the hundreds", question: `How many hundreds are in ${n}?`,
        prompt: s => [text("Hundreds: "), s], ans: h,
        wrong: slips(h, [
          [h * 100, "Wrote the value", `${count(h, "hundred")} ${isAre(h)} worth ${h * 100}. The question asks how many hundreds: just ${h}.`],
          [t, "Read the tens digit", `${t} is the middle digit, the tens. The hundreds digit is the first one on the left.`],
          [o, "Read the ones digit", `${o} is the last digit, the ones. The hundreds digit is the first one on the left.`],
        ]),
        hint: "Each big flat is one hundred. Count the flats: the hundreds digit, first on the left, says how many.",
        explain: `${n} starts with ${h}, so it has ${count(h, "hundred")}.`,
      }),
      oneBox({
        id: "tens", label: "Count the tens", question: `How many tens are left after the hundreds?`,
        prompt: s => [text("Tens: "), s], ans: t,
        wrong: slips(t, [
          [t * 10, "Wrote the value", `${count(t, "ten")} ${isAre(t)} worth ${t * 10}. The question asks how many tens: just ${t}.`],
          [h, "Read the hundreds digit", `${h} is the first digit, the hundreds. The tens digit is in the middle.`],
          [o, "Read the ones digit", `${o} is the last digit, the ones. The tens digit is in the middle.`],
        ]),
        hint: "Each long rod is one ten. Count the rods: the tens digit, in the middle, says how many.",
        explain: `The middle digit of ${n} is ${t}, so it has ${count(t, "ten")}.`,
      }),
      oneBox({
        id: "ones", label: "Count the ones", question: "How many ones are left?",
        prompt: s => [text("Ones: "), s], ans: o,
        wrong: slips(o, [
          [h, "Read the hundreds digit", `${h} is the first digit, the hundreds. The ones digit is the last one.`],
          [t, "Read the tens digit", `${t} is the middle digit, the tens. The ones digit is the last one.`],
        ]),
        hint: "Each small cube is one. Count the cubes: the ones digit, last on the right, says how many.",
        explain: `The last digit of ${n} is ${o}, so it has ${count(o, "one")}.`,
      }),
      manyBoxes({
        id: "expanded", label: "Write what each digit is worth", question: "Write the number as hundreds + tens + ones.",
        prompt: b => [num(n), op("="), b.h!, op("+"), b.t!, op("+"), b.o!], ans: expanded,
        wrong: ([
          [{ h, t, o }, "Wrote the digits", `Each digit is worth its place. ${count(h, "hundred")} is ${h * 100}, and ${count(t, "ten")} is ${t * 10}.`],
          [{ h: h * 100, t, o }, "Tens as ones", `The ${t} is in the tens place, so it is worth ${t * 10}.`],
          [{ h, t: t * 10, o }, "Hundreds as ones", `The ${h} is in the hundreds place, so it is worth ${h * 100}.`],
        ] as [Record<string, number>, string, string][]).filter(([v]) => !same(v)),
        hint: "A flat is worth 100, a rod is worth 10 and a cube is worth 1. What are all the flats worth? All the rods?",
        explain: `${count(h, "hundred")} is ${h * 100}, ${count(t, "ten")} is ${t * 10}, and ${count(o, "one")} is ${o}.`,
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: HundredsProblem, model: AnswerModel): Explanation {
  const { n } = p;
  const h = expectedOf(model, "hundreds"), t = expectedOf(model, "tens"), o = expectedOf(model, "ones");
  const H = expectedOf(model, "expanded", "h"), T = expectedOf(model, "expanded", "t");
  const total = `${H} + ${T} + ${o} = ${n}`;
  return {
    heading: "Hundreds, tens and ones",
    idea: ["Each digit tells how many blocks of its size. A flat is a hundred, a rod is a ten and a cube is a one."],
    statement: [num(n)],
    diagram: buildPlaceBlocks({
      hundreds: h, tens: t, ones: o,
      beats: { hundreds: 1, tens: 2, ones: 3, total: 4 },
      text: { hundreds: `${count(h, "hundred")} = ${H}`, tens: `${count(t, "ten")} = ${T}`, ones: count(o, "one"), total },
      alt: `${n} as ${count(h, "hundred flat")}, ${count(t, "ten rod")} and ${count(o, "one cube")}: ${total}.`,
    }),
    caption: `${n} is ${count(h, "hundred")}, ${count(t, "ten")} and ${count(o, "one")}.`,
    timeline: beats(5),
    steps: [
      { id: "hundreds", narration: `The first digit is ${h}. That's ${h} flat${h === 1 ? "" : "s"}, ${count(h, "hundred")}.`, math: [text("Hundreds: "), num(h)], state: 1, answerStep: "hundreds", result: h },
      { id: "tens", narration: `The middle digit is ${t}. That's ${t} rod${t === 1 ? "" : "s"}, ${count(t, "ten")}.`, math: [text("Tens: "), num(t)], state: 2, answerStep: "tens", result: t },
      { id: "ones", narration: `The last digit is ${o}. That's ${o} cube${o === 1 ? "" : "s"}, ${count(o, "one")}.`, math: [text("Ones: "), num(o)], state: 3, answerStep: "ones", result: o },
      { id: "expanded", narration: `Put the values together: ${total}.`, math: [num(n), op("="), num(H), op("+"), num(T), op("+"), num(o)], state: 4, answerStep: "expanded", result: H },
    ],
  };
}

export const lesson: LessonDefinition<HundredsProblem> = {
  id: "g2-hundreds",
  grade: 2,
  unit: "Place value",
  title: "Hundreds, tens and ones",
  pre: "g1-tensones",
  reference: createHundreds(347),
  generate,
  restore: raw => restoreVia(raw, ["n"] as const, v => createHundreds(v.n)),
  display: p => [num(p.n)],
  displayNote: () => "Find the hundreds, tens and ones.",
  answers,
  explain,
};
