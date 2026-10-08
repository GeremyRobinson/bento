// Converting measurements (new in the rebuild): a big unit holds a fixed number of small units, so multiply,
// then add any small units left over. Feet and inches, meters and centimeters, hours and minutes, pounds and ounces.
import { num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation, type ExplanationStep } from "../../../../explanations/schema";
import { buildDoubleLine } from "../../../../explanations/diagrams/early-g4/double-line";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { slips } from "../_kit";
import { count } from "../../../text";

interface Unit {
  big: [string, string];
  small: [string, string];
  per: number;
  /** a mix-up for "how many in one?", with the reason it's wrong */
  mixUps: [number, string, string][];
  /** extra small units a problem may add, smallest and biggest, counted by `by` */
  extra: [number, number, number];
  story: (amount: string, small: string) => string;
}

export const UNITS: Unit[] = [
  { big: ["foot", "feet"], small: ["inch", "inches"], per: 12, extra: [3, 11, 1],
    mixUps: [[10, "Used 10", "A foot is 12 inches, not 10. Look at a ruler: it goes up to 12."], [3, "Mixed up yards and feet", "3 is the feet in a yard. A foot is 12 inches."]],
    story: (a, s) => `A rope is **${a}** long. How many ${s} is that?` },
  { big: ["meter", "meters"], small: ["centimeter", "centimeters"], per: 100, extra: [20, 95, 5],
    mixUps: [[10, "Used 10", "A meter is 100 centimeters. \"Centi\" means a hundredth."], [1000, "Mixed up millimeters", "1,000 is the millimeters in a meter. A meter is 100 centimeters."]],
    story: (a, s) => `A table is **${a}** long. How many ${s} is that?` },
  { big: ["hour", "hours"], small: ["minute", "minutes"], per: 60, extra: [15, 55, 5],
    mixUps: [[100, "Counted time by 100s", "Clocks don't count by 100s. An hour is 60 minutes."], [24, "Mixed up a day", "24 is the hours in a day. An hour is 60 minutes."]],
    story: (a, s) => `A road trip takes **${a}**. How many ${s} is that?` },
  { big: ["pound", "pounds"], small: ["ounce", "ounces"], per: 16, extra: [4, 15, 1],
    mixUps: [[12, "Used 12", "12 is the inches in a foot. A pound is 16 ounces."], [10, "Used 10", "A pound is 16 ounces, not 10."]],
    story: (a, s) => `A bag of flour weighs **${a}**. How many ${s} is that?` },
];

/** n big units and m small units, written in small units. k picks the pair of units. */
export interface ConvertProblem { k: number; n: number; m: number }

export function createConvert(k: number, n: number, m: number): ConvertProblem {
  wholeIn("k", k, 0, UNITS.length - 1);
  wholeIn("n", n, 1, 9);
  wholeIn("m", m, 0, UNITS[k]!.per - 1);
  return { k, n, m };
}

/** Early problems are mostly whole big units; later ones often have small units left over. */
export function generateConvert(rng: Rng, index: number): ConvertProblem {
  const k = rng.int(0, UNITS.length - 1), u = UNITS[k]!, [lo, hi, by] = u.extra;
  const m = rng.next() < (index < 3 ? 0.35 : 0.65) ? by * rng.int(Math.ceil(lo / by), Math.floor(hi / by)) : 0;
  return createConvert(k, rng.int(2, index < 3 ? 5 : 9), m);
}

const name = (pair: [string, string], x: number) => (x === 1 ? pair[0] : pair[1]);
/** "3 feet 5 inches" or "3 feet" */
export const amount = ({ k, n, m }: ConvertProblem) => {
  const u = UNITS[k]!;
  return `${n} ${name(u.big, n)}${m ? ` ${m} ${name(u.small, m)}` : ""}`;
};
const shown = ({ k, n, m }: ConvertProblem): MathText => {
  const u = UNITS[k]!;
  return [num(n), text(` ${name(u.big, n)}`), ...(m ? [text(" "), num(m), text(` ${name(u.small, m)}`)] : [])];
};

function answers(p: ConvertProblem): AnswerModel {
  const { k, n, m } = p, u = UNITS[k]!, one = u.big[0], smalls = u.small[1], f = u.per, all = n * f;
  const steps: AnswerStep[] = [
    oneBox({
      id: "one", label: "How many in one?", prompt: s => [num(1), text(` ${one}`), op("="), s, text(` ${smalls}`)], ans: f,
      wrong: slips(f, u.mixUps), hint: `Think of one ${one}. How many ${smalls} fit in it?`, explain: `1 ${one} is ${f} ${smalls}.`,
    }),
    oneBox({
      id: "multiply", label: "Multiply", question: `Each ${one} is ${f} ${smalls}. How many ${smalls} in ${n} ${name(u.big, n)}?`,
      prompt: s => [num(n), op("×"), num(f), op("="), s], ans: all,
      wrong: slips(all, [
        [n * 10, "Multiplied by 10", `That's ${n} × 10. Each ${one} is ${f} ${smalls}, so multiply by ${f}.`],
        [n + f, "Added instead of multiplied", `There are ${n} ${name(u.big, n)}, each ${f} ${smalls}. That's ${count(n, "group")} of ${f}: multiply.`],
      ]),
      hint: `Big unit to small unit: multiply. ${count(n, "group")} of ${f}.`, explain: `${n} × ${f} = ${all} ${smalls}.`,
    }),
  ];
  if (m) steps.push(oneBox({
    id: "extra", label: "Add the extra", question: `Don't forget the ${m} ${name(u.small, m)} on the end.`,
    prompt: s => [num(all), op("+"), num(m), op("="), s], ans: all + m,
    wrong: slips(all + m, [
      [all, "Left off the extra", `${amount(p)} has ${m} more ${name(u.small, m)}. Add them on.`],
      [all + m * f, "Multiplied the extra too", `The ${m} ${name(u.small, m)} are already small units. Just add them.`],
    ]),
    hint: `${all} + ${m}.`, explain: `${all} + ${m} = ${all + m} ${smalls}.`,
  }));
  return { steps, finalParts: [-1] };
}

function explain(p: ConvertProblem, model: AnswerModel): Explanation {
  const { k, n, m } = p, u = UNITS[k]!, one = u.big[0], smalls = u.small[1];
  const f = expectedOf(model, "one"), all = expectedOf(model, "multiply"), total = m ? expectedOf(model, "extra") : all;
  const last = m ? 3 : 2;
  const steps: ExplanationStep[] = [
    { id: "start", state: 0, math: [...shown(p), op("="), text(`? ${smalls}`)], narration: `The top line counts ${u.big[1]}. The bottom line counts ${smalls} for the same amount.` },
    { id: "one", state: 1, answerStep: "one", result: f, math: [num(1), text(` ${one}`), op("="), num(f), text(` ${smalls}`)],
      narration: `Start with one: 1 ${one} lines up with ${f} ${smalls}.` },
    { id: "multiply", state: 2, answerStep: "multiply", result: all, math: [num(n), op("×"), num(f), op("="), num(all)],
      narration: `Every ${one} adds ${f} more ${smalls}. ${n} ${name(u.big, n)} line up with ${n} × ${f} = ${all} ${smalls}.` },
  ];
  if (m) steps.push({ id: "extra", state: 3, answerStep: "extra", result: total, math: [num(all), op("+"), num(m), op("="), num(total)],
    narration: `Then hop on the ${m} extra ${name(u.small, m)}: ${all} + ${m} = ${total} ${smalls}.` });
  return {
    heading: "Big unit to small unit: multiply",
    idea: ["One big unit is always the same number of small units."],
    statement: [...shown(p), op("="), text(`? ${smalls}`)],
    diagram: buildDoubleLine({
      n, per: f, extra: m, top: u.big[1], bottom: smalls,
      beats: { one: 1, all: 2, extra: m ? 3 : null, total: last },
      total: `${amount(p)} = ${total} ${smalls}`,
      alt: `A double number line: ${u.big[1]} on top, ${smalls} below. 1 ${one} matches ${f} ${smalls}, so ${amount(p)} is ${total} ${smalls}.`,
    }),
    caption: `1 ${one} = ${f} ${smalls}`,
    timeline: beats(last + 1),
    steps,
  };
}

export const lesson: LessonDefinition<ConvertProblem> = {
  id: "g4-convert",
  grade: 4,
  unit: "Measurement",
  title: "Converting measurements",
  reference: createConvert(0, 3, 5),
  generate: (rng, index) => generateConvert(rng, index),
  restore: raw => restoreVia(raw, ["k", "n", "m"] as const, v => createConvert(v.k, v.n, v.m)),
  display: p => [...shown(p), op("="), text(`? ${UNITS[p.k]!.small[1]}`)],
  answers,
  explain,
  story: p => ({ op: "×", text: UNITS[p.k]!.story(amount(p), UNITS[p.k]!.small[1]) }),
};
