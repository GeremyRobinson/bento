import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildBox3d } from "../../../../explanations/diagrams/box3d/build";
import { expectedOf, ns, readNumbers } from "../../area-common/steps";
import { aNum } from "../../../text";
import { withEasyStart } from "../../easy-start";

/** A pyramid on a square base of side s, height h; s·s·h divides by 3. */
export interface PyramidProblem { s: number; h: number }

export function createPyramid(s: number, h: number): PyramidProblem {
  if (![s, h].every(v => Number.isInteger(v) && v > 0)) throw new Error("whole numbers only");
  return { s, h };
}

/** Same as the current app: side 2–10, height 2–15, volume a whole number. */
export function generatePyramid(rng: Rng): PyramidProblem {
  let s: number, h: number;
  do { s = rng.int(2, 10); h = rng.int(2, 15); } while ((s * s * h) % 3);
  return { s, h };
}

export function pyramidAnswers({ s, h }: PyramidProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "base", label: "Base area", prompt: x => [num(s), op("×"), num(s), op("="), x], ans: s * s, hint: `The base is a square: its area is the side times itself, ${s} × ${s}.`, wrong: [[4 * s, "Found the perimeter", "That is the distance around. The area is side × side."]] }),
      ns({ id: "box", label: "Times the height", prompt: x => [num(s * s), op("×"), num(h), op("="), x], ans: s * s * h, hint: "The box around the pyramid stacks the base as high as the pyramid.", wrong: [[s * s + h, "Added", "Stacking the base layer by layer multiplies by the height."]] }),
      ns({ id: "third", label: "Divide by 3", prompt: x => [num(s * s * h), op("÷"), num(3), op("="), x], ans: (s * s * h) / 3, hint: "A pyramid is a third of a box.",
        wrong: [[s * s * h, "Forgot the ÷ 3", "A pyramid holds a third of a box with the same base and height."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainPyramid(p: PyramidProblem, answers: AnswerModel): Explanation {
  const { s, h } = p, B = expectedOf(answers.steps, "base"), box = expectedOf(answers.steps, "box"), V = expectedOf(answers.steps, "third");
  return {
    heading: "A third of a box",
    idea: ["A pyramid holds a third of the box with the same base and height: base area × height ÷ 3."],
    statement: [text("square base "), num(s), text(", height "), num(h)],
    diagram: buildBox3d({
      // the base is drawn from the start, so its side labels never float over an empty card (review v43 item 8);
      // its area arrives as the first line of working
      mode: "pyramid", l: s, w: s, h, beats: { base: 0, box: 2, pyramid: 3 },
      labels: { l: String(s), w: String(s), h: String(h), from: 0 },
      lines: [
        { text: `base: ${s} × ${s} = ${B}`, from: 1, until: 1 },
        { text: `box: ${B} × ${h} = ${box}`, from: 2, until: 2 },
        { text: `pyramid: ${box} ÷ 3 = ${V}`, from: 3 },
      ],
      alt: `A pyramid on ${aNum(s)} by ${s} base, ${h} tall, inside its box of ${box}; the pyramid is a third, ${V}.`,
    }),
    caption: "A pyramid fills a third of its box.",
    timeline: beats(4),
    steps: [
      { id: "base", narration: `The base is ${aNum(s)} by ${s} square: ${B}.`, math: [num(s), op("×"), num(s), op("="), num(B)], state: 1, answerStep: "base", result: B },
      { id: "box", narration: `A box on that base, ${h} tall, holds ${box}.`, math: [num(B), op("×"), num(h), op("="), num(box)], state: 2, answerStep: "box", result: box },
      { id: "third", narration: `The pyramid holds a third of the box: ${V}.`, math: [num(box), op("÷"), num(3), op("="), num(V)], state: 3, answerStep: "third", result: V },
    ],
  };
}

export const lesson: LessonDefinition<PyramidProblem> = withEasyStart({
  id: "g10-pyramid",
  grade: 10,
  unit: "Area and volume",
  title: "Volume of a pyramid",
  reference: createPyramid(6, 5),
  generate: rng => generatePyramid(rng),
  restore: raw => { const r = readNumbers(raw, ["s", "h"] as const); try { return r && createPyramid(r.s, r.h); } catch { return null; } },
  display: p => [text("square base "), num(p.s), text(", height "), num(p.h)],
  displayNote: () => "V = base area × height ÷ 3",
  answers: pyramidAnswers,
  explain: explainPyramid,
});
