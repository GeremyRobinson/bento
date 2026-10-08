import { frac, num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import type { TapeText } from "../../../../explanations/diagrams/tape/schema";
import { pieceName } from "../../_tape-family/steps";
import { box, expectedOf, fracBoxes, restoreVia, wholeIn } from "../_kit/steps";
import { count, isAre } from "../../../text";

/** A bar cut into b equal parts with k of them shaded: each part is 1/b, so k parts are k/b. */
export interface UnitFracProblem { b: number; k: number }

const DENS = [2, 3, 4, 6, 8];

export function createUnitFrac(b: number, k: number): UnitFracProblem {
  if (!DENS.includes(b)) throw new Error(`3rd grade cuts into ${DENS.join(", ")} parts`);
  wholeIn("k", k, 1, b - 1);
  return { b, k };
}

/** Early problems shade one part of 2, 3 or 4; later ones shade one or more parts of up to 8. */
export function generateUnitFrac(rng: Rng, index: number): UnitFracProblem {
  if (index < 3) return createUnitFrac(rng.pick([2, 3, 4]), 1);
  const b = rng.pick([3, 4, 6, 8]);
  return createUnitFrac(b, rng.next() < 0.35 ? 1 : rng.int(2, b - 1));
}

function answers({ b, k }: UnitFracProblem): AnswerModel {
  const steps: AnswerStep[] = [
    box({
      id: "parts", label: "Count the equal parts", question: "How many equal parts is the whole bar cut into?",
      prompt: x => [text("equal parts "), op("="), x], ans: b,
      wrong: [
        [b - 1, "Counted the cut lines", `There ${isAre(b - 1)} ${count(b - 1, "cut line")}, but ${count(b, "part")}. Count the pieces, not the lines.`],
        [k, "Counted only the shaded parts", `Count every part of the bar, shaded or not.`],
      ],
      hint: "Touch each part of the bar as you count it.",
      explain: `The bar is cut into ${b} equal parts.`,
    }),
    fracBoxes({
      id: "one", label: "Name one part", question: `One part of ${b} equal parts is…`,
      prompt: f => [text("one part "), op("="), f], N: 1, D: b,
      wrong: [
        [b, 1, "Flipped the fraction", `The bottom number says how many equal parts make the whole: ${b}. The top says how many you take: 1.`],
        [1, b - 1, "Counted the other parts", `The bottom counts all ${count(b, "part")} of the whole, not just the other ${b - 1}.`],
      ],
      hint: `The whole is cut into ${count(b, "part")} and you take 1. That's 1 on top, ${b} on the bottom.`,
      explain: `One of ${b} equal parts is 1/${b}, one ${pieceName(b, false)}.`,
    }),
  ];
  if (k > 1) {
    steps.push(fracBoxes({
      id: "shaded", label: "Name the shaded part", question: `${count(k, "part")} ${isAre(k)} shaded. Each part is 1/${b}.`,
      prompt: f => [text("shaded "), op("="), f], N: k, D: b,
      wrong: [
        [k, b - k, "Compared shaded to not shaded", `The bottom counts all ${count(b, "part")} of the whole, not just the ${b - k} that ${isAre(b - k)} not shaded.`],
        [b - k, b, "Counted the parts not shaded", `${count(b - k, "part")} ${isAre(b - k)} not shaded. Count the shaded parts for the top.`],
        [b, k, "Flipped the fraction", `The bottom says how many parts make the whole: ${b}. The top counts the shaded parts: ${k}.`],
        [1, b, "Named only one part", `That's one part. ${count(k, "part")} ${isAre(k)} shaded, so count ${count(k, "piece")} of 1/${b}.`],
      ],
      hint: `Count the shaded parts for the top. The whole still has ${count(b, "part")}.`,
      explain: `${count(k, "part")} of 1/${b} make ${k}/${b}.`,
    }));
  }
  return { steps, finalParts: [-1] };
}

/** The bar with its shaded parts: numbered, then one part named 1/b, then all shaded parts named k/b. */
export function unitFracPicture({ b, k }: UnitFracProblem, beatsOn = true) {
  const total: TapeText[] = !beatsOn ? [] : k > 1
    ? [{ text: `1/${b}`, from: 2, until: 2, acc: true }, { text: `${k}/${b}`, from: 3, acc: true }]
    : [{ text: `1/${b}`, from: 2, acc: true }];
  return buildTape({
    rows: [{
      length: 1, parts: b,
      fills: [{ a: 0, b: k / b, tone: "on" }, ...(beatsOn ? [{ a: 0, b: 1 / b, tone: "acc" as const, from: 2, ...(k > 1 ? { until: 2 } : {}) }] : [])],
      each: beatsOn ? [{ text: (i: number) => String(i + 1), from: 1, until: 1 }, { text: () => `1/${b}`, from: 2, only: (i: number) => k > 1 || i === 0 }] : [],
      total,
    }],
    maxRowHeight: 64,
    width: 540,
    alt: beatsOn ? `A bar cut into ${b} equal parts with ${k} shaded. Each part is 1/${b}, so the shaded part is ${k}/${b}.` : `A bar cut into ${b} equal parts with ${k} shaded.`,
  });
}

function explain(p: UnitFracProblem, model: AnswerModel): Explanation {
  const { b, k } = p, B = expectedOf(model, "parts");
  const one = model.steps.find(s => s.id === "one")!, d = one.slots.find(s => s.id === "d")!.expected!;
  return {
    heading: "Equal parts of a whole",
    idea: ["The bottom says how many equal parts make the whole, and the top says how many you have."],
    statement: [text("shaded "), op("="), text("?")],
    diagram: unitFracPicture(p),
    caption: `${k === 1 ? "One part" : `${count(k, "part")}`} of the bar ${k === 1 ? "is" : "are"} shaded.`,
    timeline: beats(k > 1 ? 4 : 3),
    steps: [
      { id: "parts", state: 1, answerStep: "parts", result: B, math: [text("equal parts "), op("="), num(B)],
        narration: `Count the parts: the bar is cut into ${B} equal parts.` },
      { id: "one", state: 2, answerStep: "one", result: d, math: [text("one part "), op("="), frac(1, d)],
        narration: `Each part is one of ${d}, so each part is 1/${d}, one ${pieceName(d, false)}.` },
      ...(k > 1 ? [{ id: "shaded", state: 3, answerStep: "shaded", result: k, math: [text("shaded "), op("="), frac(k, b)],
        narration: `${count(k, "part")} ${isAre(k)} shaded. ${count(k, "piece")} of 1/${b} make ${k}/${b}.` }] : []),
    ],
  };
}

export const lesson: LessonDefinition<UnitFracProblem> = {
  id: "g3-unitfrac",
  grade: 3,
  unit: "Fractions",
  title: "Unit fractions",
  pre: "g1-halves",
  reference: createUnitFrac(4, 3),
  generate: generateUnitFrac,
  restore: raw => restoreVia(raw, ["b", "k"] as const, v => createUnitFrac(v.b, v.k)),
  display: () => [text("shaded "), op("="), text("?")],
  displayNote: () => "What fraction of the bar is shaded?",
  picture: p => unitFracPicture(p, false),
  answers,
  explain,
};
