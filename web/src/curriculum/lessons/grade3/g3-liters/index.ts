// Liters: read the water level on a marked jug, or solve a one-step story about liters.
import { text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildJug } from "../../../../explanations/diagrams/early-g3/jug";
import { buildStoryBoxes } from "../../../../explanations/diagrams/early-g3/story-boxes";
import { oneBox, wholeIn } from "../../_number-line/steps";
import { words } from "../../gradeK/kit";
import { slips } from "../../grade2/kit";
import { OPS, WHO, apply, checkStory, operationStep, solveStep, storyNumbers, type Op } from "../_measure";

/** kind 0: a jug holding `cap` liters, a mark every `step`, water at `value`; kind 1: a story (op 0 + … 3 ÷) on a and b */
export interface LitersProblem { kind: number; cap: number; step: number; value: number; op: number; a: number; b: number; who: number }

export function createLiters(p: LitersProblem): LitersProblem {
  const { kind, cap, step, value, op, a, b, who } = p;
  wholeIn("kind", kind, 0, 1);
  if (kind === 0) {
    if (![5, 10, 20].includes(cap)) throw new Error("jugs hold 5, 10 or 20 liters");
    if (!(step === 1 || (cap === 20 && (step === 2 || step === 5)) || (cap === 10 && step === 2))) throw new Error("marks every liter, every 2 on the 10 liter jug, or every 2 or 5 on the big jug");
    wholeIn("value", value, step, cap - step);
    if (value % step) throw new Error("the water sits on a mark");
    return { kind, cap, step, value, op: 0, a: 0, b: 0, who: 0 };
  }
  wholeIn("who", who, 0, WHO.length - 1);
  checkStory(op, a, b, 50);
  return { kind, cap: 0, step: 1, value: 0, op, a, b, who };
}

const lit = (n: number) => `${n} ${n === 1 ? "liter" : "liters"}`;

export function litersStory(p: LitersProblem): string {
  const who = WHO[p.who]!;
  switch (OPS[p.op]!) {
    case "+": return `${who} pours ${lit(p.a)} of water into a tub, then ${p.b} more ${p.b === 1 ? "liter" : "liters"}. How many liters are in the tub?`;
    case "−": return `A fish tank holds ${lit(p.a)}. ${who} drains ${lit(p.b)} to clean it. How many liters are left?`;
    case "×": return `${who} fills ${p.a} bottles with ${lit(p.b)} of juice each. How many liters is that in all?`;
    default: return `${who} pours ${lit(p.a)} of lemonade equally into ${p.b} jugs. How many liters go in each jug?`;
  }
}

function answers(p: LitersProblem): AnswerModel {
  if (p.kind === 1) { const o = OPS[p.op]! as Op; return { steps: [operationStep(o, litersStory(p), p.a, "L"), solveStep(o, p.a, p.b, "L")], finalParts: [-1] }; }
  const n = p.cap / p.step, every = n <= 10 ? 1 : n <= 20 ? 2 : 5, labelStep = every * p.step;
  const marks = p.value / p.step, below = Math.floor(p.value / labelStep) * labelStep;
  return {
    steps: [
      oneBox({
        id: "step", label: "Each mark", question: "How many liters is each mark?",
        prompt: s => [s, text(" L each mark")], ans: p.step,
        wrong: slips(p.step, [
          p.step !== 1 && [1, "Counted each mark as 1", `The marks jump by ${p.step} each, not 1. Look at the labels.`],
          [p.cap, "Read a label", `${p.cap} is a label. Count the spaces from 0 to ${p.cap}: each one is ${p.step} L.`],
          p.step !== 1 && [n, "Counted the marks", `There are ${n} marks up to ${p.cap}, but the labels jump by ${p.step}. Each mark is worth ${p.step} L.`],
        ]),
        hint: "Find two labeled marks. How many spaces are between them?",
        explain: `Each mark is ${p.step} ${p.step === 1 ? "liter" : "liters"}.`,
      }),
      oneBox({
        id: "read", label: "Read the level", question: "How many liters of water are in the jug?",
        prompt: s => [s, text(" L")], ans: p.value,
        wrong: slips(p.value, [
          [p.cap, "Read the top of the jug", "That's how much the jug can hold. Read where the water is."],
          below !== p.value && [below, "Read the label below", `The water is past ${below}. Count on the small marks.`],
          [p.value - p.step, "One mark short", "The water is one mark higher. Count up from the last label to the very top of the water."],
          [p.value + p.step, "One mark too many", "That mark is above the water. Stop at the top of the water."],
          p.step !== 1 && [marks, "Counted the marks by 1", `Each mark is ${p.step} liters. Count by ${p.step}s.`],
        ]),
        hint: `Find the top of the water. Count up the marks by ${p.step}.`,
        explain: `The water comes up to ${lit(p.value)}.`,
      }),
    ],
    finalParts: [-1],
  };
}

const jugAlt = "A jug marked in liters, partly full.";

function explain(p: LitersProblem, model: AnswerModel): Explanation {
  const steps = model.steps.map((s, i) => ({ id: s.id, narration: s.explain, math: s.work ?? [], state: i === model.steps.length - 1 ? 2 : 1, answerStep: s.id, result: s.slots[0]!.expected! }));
  const idea = ["A liter is a fixed amount, about one big bottle of water."];
  if (p.kind === 1) {
    const ans = apply(OPS[p.op]!, p.a, p.b);
    return {
      heading: "Liter stories", idea, statement: [text(litersStory(p))],
      diagram: buildStoryBoxes({ op: OPS[p.op]!, a: p.a, b: p.b, unit: "L", answer: 2, alt: `Boxes showing the story's amounts. The answer is ${ans} liters.` }),
      caption: `${ans} liters.`, timeline: beats(3),
      steps: [{ id: "readit", narration: "Read the story. Draw the amounts.", math: words("Read it."), state: 0 }, ...steps],
    };
  }
  return {
    heading: "Read a jug", idea, statement: words("How many liters of water are in the jug?"),
    diagram: buildJug({ cap: p.cap, step: p.step, value: p.value, beats: { fill: 0, count: 2 }, alt: `${jugAlt} It fills, then the marks count up by ${p.step} to ${lit(p.value)}.` }),
    caption: `Each mark is ${p.step} L. The water is at ${p.value} L.`, timeline: beats(3),
    steps: [{ id: "fill", narration: "Water pours in.", math: words("Watch it fill."), state: 0 }, ...steps],
  };
}

export const lesson: LessonDefinition<LitersProblem> = {
  id: "g3-liters",
  grade: 3,
  unit: "Measurement",
  title: "Liters",
  reference: createLiters({ kind: 0, cap: 10, step: 1, value: 7, op: 0, a: 0, b: 0, who: 0 }),
  generate: (rng, index) => {
    const base = { kind: 0, cap: 10, step: 1, value: 0, op: 0, a: 0, b: 0, who: 0 };
    if (index < 3 || index % 2 === 0) {
      // problem 0 counts liters one by one; problems 1 and 2 use a 10 liter jug marked every 2, so the scale step matters
      const cap = index === 0 ? rng.pick([5, 10]) : index < 3 ? 10 : rng.pick([5, 10, 20]);
      const step = index === 0 ? 1 : index < 3 ? 2 : cap === 20 ? rng.pick([1, 2, 5]) : cap === 10 ? rng.pick([1, 2]) : 1;
      return createLiters({ ...base, cap, step, value: step * rng.int(1, cap / step - 1) });
    }
    const op = rng.int(0, 3), [a, b] = storyNumbers(rng, op, 50, 1);
    return createLiters({ ...base, kind: 1, cap: 0, op, a, b, who: rng.int(0, WHO.length - 1) });
  },
  restore: raw => {
    const r = raw as Partial<LitersProblem> | null;
    if (!r || typeof r !== "object") return null;
    try { return createLiters(r as LitersProblem); } catch { return null; }
  },
  display: p => (p.kind === 0 ? words("How many liters of water are in the jug?") : [text(litersStory(p))]),
  picture: p => (p.kind === 0 ? buildJug({ cap: p.cap, step: p.step, value: p.value, alt: jugAlt }) : buildStoryBoxes({ op: OPS[p.op]!, a: p.a, b: p.b, unit: "L", alt: `Boxes showing ${p.a} and ${p.b} liters.` })),
  answers,
  explain,
  pre: "g3-mass",
};
