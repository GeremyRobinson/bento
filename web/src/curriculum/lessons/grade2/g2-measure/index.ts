// Inches and centimetres: read where an object starts and ends on a ruler, then count the units between.
import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildRuler, THINGS } from "../../../../explanations/diagrams/early-g2/measure";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { count, slips } from "../kit";

/** An object on a ruler. unit 0 is inches, 1 is centimetres; thing picks the object. */
export interface MeasureProblem { unit: number; start: number; end: number; thing: number }

const UNITS = [
  { abbr: "in" as const, one: "inch", many: "inches", max: 10, min: 2 },
  { abbr: "cm" as const, one: "centimeter", many: "centimeters", max: 15, min: 3 },
];

export function createMeasure(unit: number, start: number, end: number, thing: number): MeasureProblem {
  wholeIn("unit", unit, 0, 1);
  wholeIn("thing", thing, 0, THINGS.length - 1);
  const u = UNITS[unit]!;
  wholeIn("start", start, 0, u.max - u.min);
  wholeIn("end", end, start + u.min, u.max);
  return { unit, start, end, thing };
}

/** Early problems start at 0; later ones start further along the ruler. */
function generate(rng: Rng, index: number): MeasureProblem {
  const unit = rng.int(0, 1), u = UNITS[unit]!, thing = rng.int(0, THINGS.length - 1);
  const len = rng.int(u.min, unit ? 11 : 7);
  const start = index < 3 ? 0 : rng.int(1, u.max - len);
  return createMeasure(unit, start, start + len, thing);
}

function answers(p: MeasureProblem): AnswerModel {
  const { start, end } = p, u = UNITS[p.unit]!, name = THINGS[p.thing]!.name, L = end - start;
  return {
    steps: [
      oneBox({
        id: "start", label: "Find the start", question: `Where does the left end of the ${name} line up?`,
        prompt: s => [text("Starts at "), s], ans: start,
        wrong: slips(start, [
          start === 0 && [1, "Started at 1", "A ruler starts at 0, not 1. The 0 mark is at the very edge."],
          [end, "Read the other end", `That's where the ${name} ends. Look at its left end.`],
        ]),
        hint: `Look straight down from the left end of the ${name} to the ruler.`,
        explain: `The ${name} starts at ${start}.`,
      }),
      oneBox({
        id: "end", label: "Find the end", question: `Where does the right end of the ${name} line up?`,
        prompt: s => [text("Ends at "), s], ans: end,
        wrong: slips(end, [
          [start, "Read the start", `That's where the ${name} starts. Look at its right end.`],
          [end - 1, "Read the mark before", "Look straight down from the very tip, not the mark before it."],
          [end + 1, "Read the mark after", "Look straight down from the very tip, not the mark after it."],
        ]),
        hint: `Look straight down from the right end of the ${name} to the ruler.`,
        explain: `The ${name} ends at ${end}.`,
      }),
      oneBox({
        id: "length", label: "Find the length",
        question: start ? `Count the ${u.many} from ${start} to ${end}.` : `It starts at 0, so the end number is the length.`,
        prompt: s => (start ? [num(end), op("−"), num(start), op("="), s, text(` ${u.abbr}`)] : [text("Length: "), s, text(` ${u.abbr}`)]), ans: L,
        wrong: slips(L, [
          start > 0 && [end, "Read the end number", `The ${name} starts at ${start}, not 0. Count the spaces from ${start} to ${end}.`],
          [L + 1, "Counted the marks", "Count the spaces between the marks, not the marks themselves."],
          start > 0 && [end + start, "Added the start", `Take away the start: the ruler before ${start} is not part of the ${name}.`],
        ]),
        hint: start ? `Count the jumps from ${start} to ${end}, or take ${start} away from ${end}.` : `Read the number at the right end.`,
        explain: start ? `${end} − ${start} = ${L}. The ${name} is ${count(L, u.one, u.many)} long.` : `The ${name} is ${count(L, u.one, u.many)} long.`,
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: MeasureProblem, model: AnswerModel): Explanation {
  const u = UNITS[p.unit]!, name = THINGS[p.thing]!.name;
  const start = expectedOf(model, "start"), end = expectedOf(model, "end"), L = expectedOf(model, "length");
  const sum = start ? `${end} − ${start} = ${L} ${u.abbr}` : `${L} ${u.abbr} long`;
  return {
    heading: `Measure in ${u.many}`,
    idea: ["The units between where something starts and ends on the ruler make its length."],
    statement: [text(`How long is the ${name}?`)],
    diagram: buildRuler({
      unit: u.abbr, max: u.max, start: p.start, end: p.end, thing: p.thing,
      beats: { start: 1, end: 2, count: 3 },
      text: { start: `start: ${start}`, end: `end: ${end}`, count: sum },
      alt: `A ${name} on a ruler in ${u.many}. It starts at ${start} and ends at ${end}, so it is ${count(L, u.one, u.many)} long.`,
    }),
    caption: `Count the spaces between the marks, not the marks.`,
    timeline: beats(4),
    steps: [
      { id: "start", narration: start ? `The ${name} starts at ${start}, not at 0.` : `The ${name} starts right at 0.`, math: [text("Starts at "), num(start)], state: 1, answerStep: "start", result: start },
      { id: "end", narration: `Its tip lines up with ${end}.`, math: [text("Ends at "), num(end)], state: 2, answerStep: "end", result: end },
      { id: "length", narration: `Count the ${u.many} from ${start} to ${end}: ${count(L, u.one, u.many)}.`, math: start ? [num(end), op("−"), num(start), op("="), num(L), text(` ${u.abbr}`)] : [text("Length: "), num(L), text(` ${u.abbr}`)], state: 3, answerStep: "length", result: L },
    ],
  };
}

export const lesson: LessonDefinition<MeasureProblem> = {
  id: "g2-measure",
  grade: 2,
  unit: "Measurement and data",
  title: "Inches and centimeters",
  pre: "g1-measure",
  reference: createMeasure(1, 2, 9, 0),
  generate,
  restore: raw => restoreVia(raw, ["unit", "start", "end", "thing"] as const, v => createMeasure(v.unit, v.start, v.end, v.thing)),
  display: p => [text(`How long is the ${THINGS[p.thing]!.name}?`)],
  displayNote: p => `Measure in ${UNITS[p.unit]!.many}.`,
  picture: p => buildRuler({
    unit: UNITS[p.unit]!.abbr, max: UNITS[p.unit]!.max, start: p.start, end: p.end, thing: p.thing,
    beats: { start: 1, end: 1, count: 1 }, text: { start: "", end: "", count: "" }, bare: true,
    alt: `A ${THINGS[p.thing]!.name} on a ruler in ${UNITS[p.unit]!.many}.`,
  }),
  answers,
  explain,
};
