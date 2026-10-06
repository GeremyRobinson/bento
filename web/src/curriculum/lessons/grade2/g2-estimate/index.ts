// Estimate length: make a smart guess with a benchmark you know (a paper clip is about an inch, a cube is a
// centimeter), then measure with the ruler.
import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildEstimate, type EstimateThing } from "../../../../explanations/diagrams/early-g2/estimate";
import { oneBox, wholeIn } from "../../_number-line/steps";
import { tapStep } from "../../gradeK/kit";
import { count, slips } from "../kit";

interface Thing { name: EstimateThing; lo: number; hi: number }
const THINGS: Thing[][] = [
  [{ name: "crayon", lo: 3, hi: 4 }, { name: "marker", lo: 5, hi: 5 }, { name: "pencil", lo: 6, hi: 7 }, { name: "spoon", lo: 6, hi: 6 }, { name: "shoe", lo: 9, hi: 10 }, { name: "book", lo: 11, hi: 11 }],
  [{ name: "paper clip", lo: 3, hi: 3 }, { name: "crayon", lo: 9, hi: 9 }, { name: "eraser", lo: 5, hi: 5 }, { name: "marker", lo: 13, hi: 13 }, { name: "spoon", lo: 15, hi: 15 }, { name: "pencil", lo: 18, hi: 18 }],
];
const UNITS = [
  { abbr: "in" as const, one: "inch", many: "inches", max: 12, bench: "paper clips", benchOne: "paper clip", far: 12 },
  { abbr: "cm" as const, one: "centimeter", many: "centimeters", max: 20, bench: "cubes", benchOne: "cube", far: 30 },
];

/** unit 0 inches, 1 centimeters; thing indexes that unit's list; len its length; start where it begins on the ruler */
export interface EstimateProblem { unit: number; thing: number; len: number; start: number }

export function createEstimate(unit: number, thing: number, len: number, start: number): EstimateProblem {
  wholeIn("unit", unit, 0, 1);
  wholeIn("thing", thing, 0, THINGS[unit]!.length - 1);
  const th = THINGS[unit]![thing]!;
  wholeIn("len", len, th.lo, th.hi);
  wholeIn("start", start, 0, 2);
  if (start + len > UNITS[unit]!.max) throw new Error("the thing fits on the ruler");
  return { unit, thing, len, start };
}

const guesses = (p: EstimateProblem) => {
  const len = p.len, small = Math.max(1, Math.round(len / (p.unit ? 5 : 4))), big = len * (p.unit ? 5 : 4);
  return { small, big };
};
/** the three choices, in an order that changes with the problem */
const choicesOf = (p: EstimateProblem) => {
  const { small, big } = guesses(p), u = UNITS[p.unit]!, k = (p.thing + p.start + p.len) % 3;
  const vals = [p.len, small, big];
  const order = [vals.slice(k), vals.slice(0, k)].flat();
  return { order, labels: order.map(v => count(v, u.one, u.many)) };
};

function answers(p: EstimateProblem): AnswerModel {
  const u = UNITS[p.unit]!, name = THINGS[p.unit]![p.thing]!.name, { small, big } = guesses(p), { order, labels } = choicesOf(p);
  const end = p.start + p.len, L = p.len;
  return {
    steps: [
      tapStep({
        id: "estimate", label: "Estimate", question: `About how long is the ${name}?`,
        prompt: [text(`The ${u.benchOne} is about 1 ${u.one}.`)], choices: labels, right: order.indexOf(L),
        wrong: i => order[i] === small
          ? ["Guessed too small", `${count(small, u.one, u.many)} is about ${count(small, u.benchOne, u.bench)}. The ${name} is much longer than that.`]
          : ["Guessed too big", `${count(big, u.one, u.many)} is longer than ${big > u.far ? "a whole ruler" : "that"}.`],
        hint: `How many ${u.bench} would fit along the ${name}?`,
        explain: `About ${L} ${u.bench} fit along it, so about ${count(L, u.one, u.many)}.`,
        work: [text(`about ${count(L, u.one, u.many)}`)],
      }),
      oneBox({
        id: "measure", label: "Measure", question: "Now measure it. How long is it?",
        prompt: s => (p.start ? [num(end), op("−"), num(p.start), op("="), s, text(` ${u.abbr}`)] : [s, text(` ${u.abbr}`)]), ans: L,
        wrong: slips(L, [
          p.start > 0 && [end, "Read the end number", `The ${name} starts at ${p.start}, not 0. Count the spaces from ${p.start} to ${end}.`],
          [L + 1, "Counted the marks", "Count the spaces between the marks, not the marks."],
        ]),
        hint: p.start ? `It starts at ${p.start}. Count the spaces from ${p.start} to ${end}.` : "It starts at 0, so read the number at its end.",
        explain: p.start ? `${end} − ${p.start} = ${L}. The ${name} is ${count(L, u.one, u.many)} long.` : `The ${name} is ${count(L, u.one, u.many)} long.`,
      }),
    ],
    finalParts: [0, 1],
  };
}

// a centimeter ruler only as long as the picture needs, so its numbers stay readable
// the ruler runs just past the thing, not always to 12 inches, so the picture stays big enough to read on a phone (v43)
const spec = (p: EstimateProblem) => ({ unit: UNITS[p.unit]!.abbr, max: p.unit ? Math.max(10, p.start + p.len + 2) : Math.min(UNITS[0]!.max, Math.max(6, p.start + p.len + 2)), start: p.start, len: p.len, thing: THINGS[p.unit]![p.thing]!.name });
const alt = (p: EstimateProblem) => `A ${THINGS[p.unit]![p.thing]!.name} above ${p.unit ? "a centimeter ruler, with a centimeter cube" : "an inch ruler, with a paper clip"} beside it.`;

function explain(p: EstimateProblem, model: AnswerModel): Explanation {
  const u = UNITS[p.unit]!;
  return {
    heading: "Estimate, then measure",
    idea: ["Before you measure, make a smart guess. Use something you know: a paper clip is about 1 inch, your finger is about 1 centimeter wide. A ruler is 30 cm."],
    statement: [text(`About how long is the ${THINGS[p.unit]![p.thing]!.name}?`)],
    diagram: buildEstimate({ ...spec(p), beats: { lay: 1, ruler: 2 },
      alt: `${alt(p)} ${p.len} ${u.bench} lay end to end along it, then the ruler shows it is ${count(p.len, u.one, u.many)} long.` }),
    caption: `About ${p.len} ${u.bench}, so about ${count(p.len, u.one, u.many)}. The ruler says exactly ${p.len}.`,
    timeline: beats(3),
    steps: [
      { id: "look", narration: `One ${u.benchOne} is about 1 ${u.one}.`, math: [text(`1 ${u.benchOne} ≈ 1 ${u.abbr}`)], state: 0 },
      ...model.steps.map((s, i) => ({ id: s.id, narration: s.explain, math: s.work ?? [num(s.slots[0]!.expected as number), text(` ${u.abbr}`)], state: i + 1, answerStep: s.id, result: s.slots[0]!.expected! })),
    ],
  };
}

export const lesson: LessonDefinition<EstimateProblem> = {
  id: "g2-estimate",
  grade: 2,
  unit: "Measurement and data",
  title: "Estimate length",
  reference: createEstimate(0, 2, 6, 0),
  generate: (rng, index) => {
    const early = index < 3, unit = early ? 0 : rng.int(0, 1), n = THINGS[unit]!.length;
    // a different thing every time: step through the list
    const thing = (index * 5 + 2) % n, th = THINGS[unit]![thing]!, len = rng.int(th.lo, th.hi);
    const start = early ? 0 : Math.min(rng.int(0, 2), UNITS[unit]!.max - len);
    return createEstimate(unit, thing, len, start);
  },
  restore: raw => {
    const r = raw as Partial<EstimateProblem> | null;
    if (!r || typeof r !== "object") return null;
    try { return createEstimate(r.unit as number, r.thing as number, r.len as number, r.start as number); } catch { return null; }
  },
  display: p => [text(`About how long is the ${THINGS[p.unit]![p.thing]!.name}?`)],
  displayNote: p => `Estimate in ${UNITS[p.unit]!.many}, then measure.`,
  picture: p => buildEstimate({ ...spec(p), alt: alt(p) }),
  answers,
  explain,
  pre: "g2-measure",
};
