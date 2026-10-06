import { formatNumber as fm, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import { expectedOf, ns } from "../../_tape-family/steps";
import { slips, tapStep } from "../../grade4/_kit";

/** [one big unit, many big units, small units, small units in one big unit] */
export type UnitPair = [string, string, string, number];

/** The current app's conversions. */
export const UNITS: UnitPair[] = [
  ["foot", "feet", "inches", 12], ["yard", "yards", "feet", 3], ["meter", "meters", "centimeters", 100], ["kilogram", "kilograms", "grams", 1000],
  ["hour", "hours", "minutes", 60], ["gallon", "gallons", "quarts", 4], ["pound", "pounds", "ounces", 16],
];

/** one small unit, and the mix-ups for "how many in one?" (g4-convert's, for the units it has) */
const SMALL_ONE: Record<string, string> = { inches: "inch", feet: "foot", centimeters: "centimeter", grams: "gram", minutes: "minute", quarts: "quart", ounces: "ounce" };
const MIX_UPS: Record<string, [number, string, string][]> = {
  foot: [[10, "Used 10", "A foot is 12 inches, not 10. Look at a ruler: it goes up to 12."], [3, "Mixed up yards and feet", "3 is the feet in a yard. A foot is 12 inches."]],
  yard: [[12, "Mixed up feet and inches", "12 is the inches in a foot. A yard is 3 feet."], [36, "Counted inches", "36 is the inches in a yard. A yard is 3 feet."]],
  meter: [[10, "Used 10", "A meter is 100 centimeters. \"Centi\" means a hundredth."], [1000, "Mixed up millimeters", "1,000 is the millimeters in a meter. A meter is 100 centimeters."]],
  kilogram: [[100, "Used 100", "\"Kilo\" means a thousand: a kilogram is 1,000 grams."], [10, "Used 10", "\"Kilo\" means a thousand: a kilogram is 1,000 grams."]],
  hour: [[100, "Counted time by 100s", "Clocks don't count by 100s. An hour is 60 minutes."], [24, "Mixed up a day", "24 is the hours in a day. An hour is 60 minutes."]],
  gallon: [[8, "Mixed up pints", "8 is the pints in a gallon. A gallon is 4 quarts."], [2, "Mixed up pints and quarts", "2 is the pints in a quart. A gallon is 4 quarts."]],
  pound: [[12, "Used 12", "12 is the inches in a foot. A pound is 16 ounces."], [10, "Used 10", "A pound is 16 ounces, not 10."]],
};
const cap = (w: string) => w[0]!.toUpperCase() + w.slice(1);

/**
 * n big units = ? small units (the current app's only kind), or with `up`, n small units = ? big units.
 * Big units may be a half (3.5 kilograms) and small-to-big answers may come out a half (250 centimeters = 2.5 meters).
 */
export interface UnitConversionProblem { u: UnitPair; n: number; up?: boolean }

export function createUnitConversion(one: string, n: number, up = false): UnitConversionProblem {
  const u = UNITS.find(x => x[0] === one);
  const big = u && (up ? n / u[3] : n);
  if (!u || !(n > 0) || !Number.isInteger(2 * big!) || !Number.isInteger(up ? n : n * u[3])) throw new Error(`not a unit conversion: ${n} ${up ? u?.[2] : one}`);
  return up ? { u, n, up } : { u, n };
}

/** how many big units the problem is about */
const bigCount = ({ u, n, up }: UnitConversionProblem) => (up ? n / u[3] : n);

/**
 * The current app's problems first (any conversion, 2–12 big units, big to small), then small to big,
 * then halves both ways.
 */
export function generateUnitConversion(rng: Rng, index = 0): UnitConversionProblem {
  const u = rng.pick(UNITS), f = u[3], half = index >= 6 && f % 2 === 0;
  if (index < 3) return createUnitConversion(u[0], rng.int(2, 12));
  const up = index < 6 || rng.next() < 0.5, w = rng.int(2, 9) + (half ? 0.5 : 0);
  return up ? createUnitConversion(u[0], w * f, true) : createUnitConversion(u[0], w);
}

/** "3.5 kilograms" or "250 centimeters": the amount the problem starts from */
const given = (p: UnitConversionProblem) => (p.up ? `${fm(p.n)} ${p.n === 1 ? SMALL_ONE[p.u[2]] : p.u[2]}` : `${fm(p.n)} ${p.n === 1 ? p.u[0] : p.u[1]}`);

const givenMath = (p: UnitConversionProblem): MathText => [num(p.n), text(given(p).slice(fm(p.n).length))];

function answers(p: UnitConversionProblem): AnswerModel {
  const { u: [one, many, small, f], n, up } = p, target = up ? many : small, ans = up ? n / f : n * f;
  const steps: AnswerStep[] = [
    { ...ns({ id: "one", l: "How many in one?", q: `1 ${one} = how many ${small}?`, a: s => s, ans: f, h: `Think of one ${one}. How many ${small} fit in it?`,
      w: slips(f, MIX_UPS[one] ?? []) }), explain: `1 ${one} is ${f} ${small}.` },
    tapStep({
      id: "more", label: "More or fewer?", question: `Will the answer be more or fewer ${target} than ${fm(n)}?`, prompt: [...givenMath(p), op("="), text(`? ${target}`)],
      choices: ["More", "Fewer"], ans: up ? 1 : 0,
      wrong: up ? { 0: ["Bigger units, more of them", `${cap(many)} are bigger than ${small}, so you need fewer of them.`] }
        : { 1: ["Smaller units, fewer of them", `${cap(small)} are smaller than ${many}, so you need more of them.`] },
      hint: `Which is bigger, a ${one} or a ${SMALL_ONE[small] ?? small}?`,
      explain: up ? `${cap(many)} are bigger, so it takes fewer of them.` : `${cap(small)} are smaller, so it takes more of them.`,
      work: [text(up ? `Fewer ${many}` : `More ${small}`)],
    }),
    up
      ? { ...ns({ id: "multiply", l: "Divide", a: s => [num(n), op("÷"), num(f), op("="), ...s], ans,
          h: `Every ${f} ${small} make one ${one}. How many ${f}s fit in ${fm(n)}?`,
          w: [[n * f, "Multiplied instead of divided", `${cap(many)} are bigger, so there are fewer of them: divide.`], [n - f, "Subtracted", `Take away ${f} again and again, or divide: ${fm(n)} ÷ ${f}.`]] }),
        explain: `${fm(n)} ÷ ${f} = ${fm(ans)} ${many}.` }
      : { ...ns({ id: "multiply", l: "Multiply", a: s => [num(n), op("×"), num(f), op("="), ...s], ans,
          h: `Every ${one} is ${f} ${small}, and there are ${fm(n)} of them.`,
          w: [[n + f, "Added instead of multiplied", `Each ${one} is ${f} ${small}, so multiply.`], [n / f, "Divided instead of multiplied", `${cap(small)} are smaller, so there are more of them: multiply.`]] }),
        explain: `${fm(n)} × ${f} = ${fm(ans)} ${small}.` },
  ];
  return { steps, finalParts: [-1] };
}

/** A bar of big units (the last one part full for a half). Beat 1 fills the first with f small units; beat 3 fills them all. */
export function unitConversionPicture(p: UnitConversionProblem) {
  const { u: [one, many, small, f], up } = p, W = bigCount(p), P = Math.ceil(W), smalls = W * f;
  const piece = (i: number) => (i < Math.floor(W) ? f : (W - Math.floor(W)) * f);
  return buildTape({
    rows: [{
      length: 1, parts: P, fills: [{ a: 0, b: 1 / P, tone: "on", from: 1 }, { a: 1 / P, b: W / P, tone: "on", from: 3 }],
      each: [{ text: () => `1`, until: 0 }, { text: () => `${f}`, from: 1, until: 2, only: i => i === 0 }, { text: i => fm(piece(i)), from: 3 }],
    }],
    brackets: [
      { row: 0, a: 0, b: W / P, text: up ? `${fm(smalls)} ${small}` : `${fm(W)} ${W === 1 ? one : many}`, side: "above" },
      { row: 0, a: 0, b: 1 / P, text: `1 ${one} = ${f} ${small}`, side: "below", from: 1, until: 2 },
      { row: 0, a: 0, b: W / P, text: up ? `${fm(smalls)} ÷ ${f} = ${fm(W)} ${many}` : `${fm(W)} × ${f} = ${fm(smalls)} ${small}`, side: "below", from: 3, acc: true },
    ],
    alt: `A bar of ${fm(W)} ${many}, each ${f} ${small}: ${fm(smalls)} ${small} in all.`,
  });
}

function explain(p: UnitConversionProblem, model: AnswerModel): Explanation {
  const { u: [one, many, small], n, up } = p, f = expectedOf(model.steps, "one"), all = expectedOf(model.steps, "multiply");
  return {
    heading: up ? "Small to big: divide" : "Big to small: multiply",
    idea: [
      "A big unit holds many small units, so the same length takes more small units and fewer big ones.",
      "Big to small: multiply. Small to big: divide.",
    ],
    statement: [...givenMath(p), op("="), text(`? ${up ? many : small}`)],
    diagram: unitConversionPicture(p),
    caption: up ? `1 ${one} is ${f} ${small}, so ${fm(n)} ${small} is ${fm(n)} ÷ ${f} = ${fm(all)} ${many}.`
      : `1 ${one} is ${f} ${small}, so ${given(p)} is ${fm(n)} × ${f} = ${fm(all)} ${small}.`,
    timeline: beats(4),
    steps: [
      { id: "one", state: 1, answerStep: "one", result: f, math: [num(1), text(` ${one}`), op("="), num(f), text(` ${small}`)],
        narration: `Start with one: 1 ${one} is ${f} ${small}.` },
      { id: "more", state: 2, answerStep: "more", math: [...givenMath(p), op("="), text(`? ${up ? many : small}`)],
        narration: up ? `${cap(many)} are bigger, so there will be fewer of them than ${fm(n)}.` : `${cap(small)} are smaller, so there will be more of them than ${fm(n)}.` },
      up
        ? { id: "multiply", state: 3, answerStep: "multiply", result: all, math: [num(n), op("÷"), num(f), op("="), num(all)],
          narration: `Every ${f} ${small} make one ${one}, so divide: ${fm(n)} ÷ ${f} = ${fm(all)} ${many}.` }
        : { id: "multiply", state: 3, answerStep: "multiply", result: all, math: [num(n), op("×"), num(f), op("="), num(all)],
          narration: `Every ${one} is another ${f} ${small}, so multiply: ${fm(n)} × ${f} = ${fm(all)} ${small}.` },
    ],
  };
}

/** A story that fits what the unit measures (the current app said "a rope is 8 kilograms long" for every unit). */
function story(p: UnitConversionProblem) {
  const { u: [one, many, small], up } = p, N = `**${given(p).replace(/ /, "** ")}`, ask = up ? many : small;
  const text = ["kilogram", "pound"].includes(one) ? `A bag of flour weighs ${N}. How many ${ask} is that?`
    : one === "hour" ? `A road trip takes ${N}. How many ${ask} is that?`
    : one === "gallon" ? `A fish tank holds ${N} of water. How many ${ask} is that?`
    : `A rope is ${N} long. How many ${ask} long is it?`;
  return { op: up ? ("÷" as const) : ("×" as const), text };
}

export const lesson: LessonDefinition<UnitConversionProblem> = {
  id: "g5-units",
  grade: 5,
  unit: "Measurement",
  title: "Converting units",
  pre: "g4-convert",
  // the current app's card and picture: 3 feet = 36 inches
  reference: createUnitConversion("foot", 3),
  generate: (rng, index) => generateUnitConversion(rng, index),
  restore: raw => {
    if (!raw || typeof raw !== "object") return null;
    const r = raw as Record<string, unknown>, u = r.u;
    const one = Array.isArray(u) ? u[0] : u;
    if (typeof one !== "string" || typeof r.n !== "number") return null;
    try { return createUnitConversion(one, r.n, r.up === true); } catch { return null; }
  },
  display: (p): MathText => [...givenMath(p), op("="), text(`? ${p.up ? p.u[1] : p.u[2]}`)],
  answers,
  explain,
  story,
};
