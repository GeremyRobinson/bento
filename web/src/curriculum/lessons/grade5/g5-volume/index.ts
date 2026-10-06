import { num, op } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildBox3d } from "../../../../explanations/diagrams/box3d/build";
import { expectedOf, ns, readNumbers } from "../../area-common/steps";
import { count } from "../../../text";

/** A box l cm long, w cm wide and h cm tall, filled with centimeter cubes. */
export interface BoxProblem { l: number; w: number; h: number }

export function createBox(l: number, w: number, h: number): BoxProblem {
  if (![l, w, h].every(v => Number.isInteger(v) && v > 0)) throw new Error("sides are whole numbers");
  return { l, w, h };
}

/**
 * Boxes small enough to count on a phone (fixes-02 A3): length and width 2–8, height 2–6 (up to 384 cubes); the first
 * three problems 2–5 on every side, so they can be counted cube by cube.
 */
export const generateBox = (rng: Rng, index = 3): BoxProblem => index < 3
  ? { l: rng.int(2, 5), w: rng.int(2, 5), h: rng.int(2, 5) }
  : { l: rng.int(2, 8), w: rng.int(2, 8), h: rng.int(2, 6) };

export function boxAnswers({ l, w, h }: BoxProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "base", label: "Area of the base", prompt: x => [num(l), op("×"), num(w), op("="), x], ans: l * w, hint: "Length times width.",
        wrong: [[l + w, "Added instead of multiplied", "Area means length × width."]] }),
      ns({ id: "volume", label: "Times the height", prompt: x => [num(l * w), op("×"), num(h), op("="), x], ans: l * w * h, hint: "Stack the base layer up the height.",
        wrong: [[l * w + h, "Added instead of multiplied", "Each layer is the base. Multiply by the number of layers."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainBox(p: BoxProblem, answers: AnswerModel): Explanation {
  const { l, w, h } = p, base = expectedOf(answers.steps, "base"), V = expectedOf(answers.steps, "volume");
  return {
    heading: "Volume = length × width × height",
    idea: ["Volume counts the cubes that fill a box, and every layer holds the same number of cubes as the bottom one.", "So the cubes in one layer times the number of layers is the volume."],
    statement: [num(l), op("×"), num(w), op("×"), num(h)],
    diagram: buildBox3d({
      mode: "cubes", l, w, h, layerBeats: [1, ...Array.from({ length: h - 1 }, () => 2)],
      labels: { l: String(l), w: String(w), h: String(h), from: 0 },
      lines: [
        { text: `${l} × ${w} = ${count(base, "cube")} in a layer`, from: 1, until: 1 },
        { text: `${h} layers: ${base} × ${h} = ${V}`, from: 2 },
      ],
      alt: `A box ${l} by ${w} by ${h} built from cubes: ${base} in each layer, ${h} layers, ${V} in all.`,
    }),
    caption: `${count(base, "cube")} in a layer, ${h} layers: ${V}.`,
    timeline: beats(3),
    steps: [
      { id: "base", narration: `The bottom layer is ${l} by ${w}: ${count(base, "cube")}.`, math: [num(l), op("×"), num(w), op("="), num(base)], state: 1, answerStep: "base", result: base },
      { id: "volume", narration: `Stack ${h} layers of ${base}: ${V} cubic cm.`, math: [num(base), op("×"), num(h), op("="), num(V)], state: 2, answerStep: "volume", result: V },
    ],
  };
}

export const lesson: LessonDefinition<BoxProblem> = {
  id: "g5-volume",
  grade: 5,
  unit: "Measurement",
  title: "Volume of a box",
  pre: "g4-area",
  reference: createBox(4, 3, 2),
  generate: (rng, index) => generateBox(rng, index),
  restore: raw => { const r = readNumbers(raw, ["l", "w", "h"] as const); try { return r && createBox(r.l, r.w, r.h); } catch { return null; } },
  display: p => [num(p.l), op("×"), num(p.w), op("×"), num(p.h)],
  displayNote: ({ l, w, h }) => `A box ${l} cm long, ${w} cm wide and ${h} cm tall. How many cubic cm?`,
  answers: boxAnswers,
  explain: explainBox,
};
