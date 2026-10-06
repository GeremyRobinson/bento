// Grams and kilograms: pick the unit and a sensible guess, read a scale dial, or solve a one-step story about mass.
import { text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildScale, DIAL_MARKS } from "../../../../explanations/diagrams/early-g3/scale";
import { buildStoryBoxes } from "../../../../explanations/diagrams/early-g3/story-boxes";
import { buildEstimateThing } from "../../../../explanations/diagrams/early-g3/things";
import { oneBox, wholeIn } from "../../_number-line/steps";
import { tapStep, words } from "../../gradeK/kit";
import { slips } from "../../grade2/kit";
import { count } from "../../../text";
import { OPS, WHO, apply, checkStory, operationStep, solveStep, storyNumbers, withCommas, type Op } from "../_measure";

/** the things to weigh, with a sensible mass: light ones in grams, heavy ones in kilograms */
export const MASS_THINGS = [
  { name: "paper clip", kg: false, v: 1 }, { name: "grape", kg: false, v: 5 }, { name: "coin", kg: false, v: 5 }, { name: "pencil", kg: false, v: 10 }, { name: "key", kg: false, v: 20 },
  { name: "dog", kg: true, v: 30 }, { name: "bag of flour", kg: true, v: 2 }, { name: "watermelon", kg: true, v: 5 }, { name: "bike", kg: true, v: 15 }, { name: "backpack", kg: true, v: 5 },
];
const STEPS = { g: [1, 10, 50, 100], kg: [1, 2, 5] } as const;

/**
 * kind 0: which unit for MASS_THINGS[thing]; kind 1: read a dial (unit 0 g, 1 kg; each small mark is `step`) at `value`;
 * kind 2: a story with operation op (0 + … 3 ÷) on a and b, in unit, told about WHO[who].
 */
export interface MassProblem { kind: number; thing: number; unit: number; step: number; value: number; op: number; a: number; b: number; who: number }

export function createMass(p: MassProblem): MassProblem {
  const { kind, thing, unit, step, value, op, a, b, who } = p;
  wholeIn("kind", kind, 0, 2);
  if (kind === 0) {
    wholeIn("thing", thing, 0, MASS_THINGS.length - 1);
    return { kind, thing, unit: 0, step: 1, value: 0, op: 0, a: 0, b: 0, who: 0 };
  }
  wholeIn("unit", unit, 0, 1);
  if (kind === 1) {
    if (!(STEPS[unit ? "kg" : "g"] as readonly number[]).includes(step)) throw new Error("a step this scale uses");
    wholeIn("value", value, step, step * DIAL_MARKS);
    if (value % step) throw new Error("the needle sits on a mark");
    return { kind, thing: 0, unit, step, value, op: 0, a: 0, b: 0, who: 0 };
  }
  wholeIn("who", who, 0, WHO.length - 1);
  checkStory(op, a, b, unit ? 50 : 500);
  return { kind, thing: 0, unit, step: 1, value: 0, op, a, b, who };
}

const UNIT = (u: number) => (u ? "kg" : "g");
const unitWord = (u: number) => (u ? "kilograms" : "grams");

/** grams written as a label, "2,000 g" */
const gramLabel = (g: number) => `${withCommas(g)} g`;

/** something a child has held that weighs about this much, to say how heavy or light a wrong guess really is */
export function feelsLike(label: string): string {
  const g = gramsOf(label);
  if (g >= 1000 && label.endsWith(" kg")) return g === 1000 ? "a big bottle of water" : `${count(g / 1000, "big bottle")} of water`;
  if (g <= 2) return "a paper clip";
  if (g <= 30) return "a key";
  if (g <= 60) return "a handful of coins";
  if (g <= 200) return "an apple";
  if (g <= 600) return "a few apples";
  return "a big book";
}

/** a guess label ("500 g", "2 kg") in grams */
export const gramsOf = (label: string) => {
  const m = /^([\d,]+) (g|kg)$/.exec(label);
  if (!m) throw new Error(`not a mass label: ${label}`);
  return Number(m[1]!.replace(/,/g, "")) * (m[2] === "kg" ? 1000 : 1);
};

/**
 * The 3 guesses for a thing, in an order that changes. A gram thing gets the sensible guess, one 100 times too heavy
 * and one 1,000 times too heavy (so there is no "too light" choice: small is -1). A kilogram thing gets the sensible
 * guess, one far too light (in grams) and one 100 times too heavy.
 */
export function guesses(thing: number) {
  const th = MASS_THINGS[thing]!, v = th.v;
  const vals = th.kg ? [`${v} kg`, gramLabel(v * 10), `${withCommas(v * 100)} kg`] : [`${v} g`, gramLabel(v * 100), `${v} kg`];
  const k = thing % 3, order = [0, 1, 2].map(i => (i + k) % 3);
  return { labels: order.map(i => vals[i]!), right: order.indexOf(0), small: th.kg ? order.indexOf(1) : -1, heavy: th.kg ? -1 : order.indexOf(1), big: order.indexOf(2) };
}

/** the message for a wrong guess, by which way it is wrong */
function guessSlip(thing: number, i: number): [string, string] {
  const th = MASS_THINGS[thing]!, g = guesses(thing), label = g.labels[i]!;
  if (i === g.small) return ["Guessed far too light", `${label} is about as light as ${feelsLike(label)}. A ${th.name} is much heavier than that.`];
  if (th.kg) return ["Guessed far too heavy", `${label} is far too heavy for a ${th.name}. A ${th.name} is much lighter than that.`];
  return [i === g.heavy ? "Guessed too heavy" : "Guessed far too heavy", `${label} is about as heavy as ${feelsLike(label)}. A ${th.name} is much lighter than that.`];
}

export function massStory(p: MassProblem): string {
  const who = WHO[p.who]!, u = UNIT(p.unit), a = withCommas(p.a), b = withCommas(p.b);
  switch (OPS[p.op]!) {
    case "+": return `${who} has a bag of rice of ${a} ${u} and a bag of beans of ${b} ${u}. How heavy are the two bags together?`;
    case "−": return `A box of books weighs ${a} ${u}. ${who} takes out ${b} ${u} of books. How heavy is the box now?`;
    case "×": return `${who} stacks ${p.a} boxes. Each box weighs ${b} ${u}. How heavy are all the boxes?`;
    default: return `${who} shares ${a} ${u} of sand equally into ${p.b} buckets. How much sand goes in each bucket?`;
  }
}

function answers(p: MassProblem): AnswerModel {
  if (p.kind === 0) {
    const th = MASS_THINGS[p.thing]!, g = guesses(p.thing);
    return {
      steps: [
        tapStep({
          id: "unit", label: "Pick the unit", question: `Would you weigh a ${th.name} in grams or kilograms?`,
          prompt: [text("Grams or kilograms?")], choices: ["Grams", "Kilograms"], right: th.kg ? 1 : 0,
          wrong: () => (th.kg ? ["Picked grams for something heavy", `A ${th.name} would be thousands of grams. Use kilograms.`] : ["Picked kilograms for something light", `A kilogram is as heavy as a big bottle of water. A ${th.name} is much lighter: grams.`]),
          hint: "A paper clip is about 1 gram. A big bottle of water is about 1 kilogram.",
          explain: th.kg ? `A ${th.name} is heavy, so kilograms.` : `A ${th.name} is light, so grams.`,
          work: [text(th.kg ? "kilograms" : "grams")],
        }),
        tapStep({
          id: "guess", label: "Best guess", question: "About how heavy is it?",
          prompt: [text(`A ${th.name} is about ?`)], choices: g.labels, right: g.right,
          wrong: i => guessSlip(p.thing, i),
          hint: "Think of something you've held that weighs about the same.",
          explain: `A ${th.name} is about ${g.labels[g.right]}.`,
          work: [text(`about ${g.labels[g.right]}`)],
        }),
      ],
      finalParts: [0, 1],
    };
  }
  if (p.kind === 1) {
    const u = UNIT(p.unit), L2 = 5 * p.step, marks = p.value / p.step, label = Math.floor(marks / 5) * 5 * p.step;
    return {
      steps: [
        oneBox({
          id: "step", label: "Read the scale", question: "How much is each small mark worth?",
          prompt: s => [s, text(` ${u} each mark`)], ans: p.step,
          wrong: slips(p.step, [[1, "Counted each mark as 1", `The marks jump by ${p.step} each, not 1. Look at the labels: 0 to ${withCommas(L2)}.`], [L2, "Read a label", `${withCommas(L2)} is the label. There are 5 small spaces from 0 to ${withCommas(L2)}.`]]),
          hint: "Find two labeled numbers. How many small spaces are between them?",
          explain: `5 small spaces from 0 to ${withCommas(L2)}, so each is ${withCommas(p.step)} ${u}.`,
        }),
        oneBox({
          id: "read", label: "Read the needle", question: "What is the mass?",
          prompt: s => [s, text(` ${u}`)], ans: p.value,
          wrong: slips(p.value, [
            label !== p.value && [label, "Read the label before", `The needle is past ${withCommas(label)}. Count on the small marks.`],
            [p.value - p.step, "One mark short", `The needle is one mark further on. Count the spaces from the label ${withCommas(label)} right up to the needle.`],
            [p.value + p.step, "One mark too many", `That mark is past the needle. Count the spaces from the label ${withCommas(label)} and stop at the needle.`],
            p.step !== 1 && [label + (marks % 5), "Counted the marks by 1", `Each mark is ${p.step} ${u}. Count on by ${p.step} from ${withCommas(label)}.`],
          ]),
          hint: label === p.value ? "Find the label the needle points straight at." : `Start at ${withCommas(label)} and count on by ${p.step} to the needle.`,
          explain: label === p.value ? `The needle points at ${withCommas(p.value)} ${u}.` : `From ${withCommas(label)}, count on ${marks % 5} ${marks % 5 === 1 ? "mark" : "marks"} of ${p.step}: ${withCommas(p.value)} ${u}.`,
        }),
      ],
      finalParts: [-1],
    };
  }
  const o = OPS[p.op]! as Op;
  return { steps: [operationStep(o, massStory(p), p.a, UNIT(p.unit)), solveStep(o, p.a, p.b, UNIT(p.unit))], finalParts: [-1] };
}

const scaleAlt = (p: MassProblem) => `A scale in ${unitWord(p.unit)} with labels ${[0, 1, 2, 3, 4].map(k => withCommas(k * 5 * p.step)).join(", ")}.`;
function picture(p: MassProblem) {
  if (p.kind === 0) return buildEstimateThing({ thing: MASS_THINGS[p.thing]!.name, alt: `A ${MASS_THINGS[p.thing]!.name}.` });
  if (p.kind === 1) return buildScale({ unit: UNIT(p.unit) as "g" | "kg", step: p.step, value: p.value, alt: scaleAlt(p) });
  return buildStoryBoxes({ op: OPS[p.op]!, a: p.a, b: p.b, unit: UNIT(p.unit), alt: `Boxes showing ${withCommas(p.a)} and ${withCommas(p.b)} ${unitWord(p.unit)}.` });
}

function explain(p: MassProblem, model: AnswerModel): Explanation {
  const steps = model.steps.map((s, i) => ({ id: s.id, narration: s.explain, math: s.work ?? [], state: i + 1, answerStep: s.id, result: s.slots[0]!.expected! }));
  const idea = ["Mass is how heavy something is. A paper clip is about 1 gram. A big bottle of water is about 1 kilogram, which is 1,000 grams."];
  if (p.kind === 1) {
    return {
      heading: "Read a scale", idea, statement: words("What is the mass?"),
      diagram: buildScale({ unit: UNIT(p.unit) as "g" | "kg", step: p.step, value: p.value, beats: { labels: 0, count: 1, needle: 2 },
        alt: `${scaleAlt(p)} The marks count up by ${p.step}, the needle swings to ${withCommas(p.value)} ${UNIT(p.unit)}.` }),
      caption: `Each mark is ${p.step} ${UNIT(p.unit)}. The needle shows ${withCommas(p.value)} ${UNIT(p.unit)}.`,
      timeline: beats(3),
      steps: [{ id: "labels", narration: "Find the labels first.", math: words("Read the labels."), state: 0 }, ...steps],
    };
  }
  if (p.kind === 2) {
    const ans = apply(OPS[p.op]!, p.a, p.b);
    return {
      heading: "Mass stories", idea, statement: [text(massStory(p))],
      diagram: buildStoryBoxes({ op: OPS[p.op]!, a: p.a, b: p.b, unit: UNIT(p.unit), answer: 2, alt: `Boxes showing the story's amounts. The answer is ${withCommas(ans)} ${UNIT(p.unit)}.` }),
      caption: `${withCommas(ans)} ${unitWord(p.unit)}.`,
      timeline: beats(3),
      steps: [{ id: "read", narration: "Read the story. Draw the amounts.", math: words("Read it."), state: 0 }, ...steps],
    };
  }
  const th = MASS_THINGS[p.thing]!, right = guesses(p.thing);
  return {
    heading: "Grams or kilograms", idea, statement: words("Grams or kilograms?"),
    diagram: buildEstimateThing({
      thing: th.name, scale: { reading: right.labels[right.right]!, cue: th.kg ? "Heavy, so kilograms" : "Light, so grams", beats: { unit: 1, guess: 2 } },
      alt: `A ${th.name} on a kitchen scale. It is ${th.kg ? "heavy, so kilograms" : "light, so grams"}, and the scale reads about ${right.labels[right.right]}.`,
    }),
    caption: `${model.steps[1]!.explain}`,
    timeline: beats(3),
    steps: [{ id: "look", narration: `Imagine holding a ${th.name} in your hand. Is it light or heavy?`, math: words("Light or heavy?"), state: 0 }, ...steps],
  };
}

export const lesson: LessonDefinition<MassProblem> = {
  id: "g3-mass",
  grade: 3,
  unit: "Measurement",
  title: "Grams and kilograms",
  reference: createMass({ kind: 1, thing: 0, unit: 0, step: 10, value: 130, op: 0, a: 0, b: 0, who: 0 }),
  generate: (rng, index) => {
    const early = index < 3, kind = early ? index % 2 : index % 3;
    const base = { kind, thing: 0, unit: 0, step: 1, value: 0, op: 0, a: 0, b: 0, who: 0 };
    if (kind === 0) return createMass({ ...base, thing: (index * 3 + rng.int(0, 2)) % MASS_THINGS.length });
    const unit = rng.int(0, 1);
    if (kind === 1) {
      const steps = (STEPS[unit ? "kg" : "g"] as readonly number[]).filter(s => !early || s === 1 || s === 10);
      const step = rng.pick(steps);
      // early: the needle sits on a label; later: between labels
      const marks = early ? 5 * rng.int(1, 4) : rng.pick(Array.from({ length: DIAL_MARKS - 1 }, (_, i) => i + 1).filter(m => m % 5));
      return createMass({ ...base, kind, unit, step, value: marks * step });
    }
    const op = rng.int(0, 3), [a, b] = storyNumbers(rng, op, unit ? 50 : 500, unit ? 1 : 10);
    return createMass({ ...base, kind, unit, op, a, b, who: rng.int(0, WHO.length - 1) });
  },
  restore: raw => {
    const r = raw as Partial<MassProblem> | null;
    if (!r || typeof r !== "object") return null;
    try { return createMass(r as MassProblem); } catch { return null; }
  },
  display: p => (p.kind === 0 ? [text(`Would you weigh a ${MASS_THINGS[p.thing]!.name} in grams or kilograms?`)] : p.kind === 1 ? words("What is the mass?") : [text(massStory(p))]),
  picture,
  answers,
  explain,
  pre: "g3-addsub",
};
