// Halves and fourths: count the equal parts, name them, then count the shaded ones.
import { answer, num, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildParts, cutLines, cutsAllowed, SHAPE_NAMES, type ShapeKind } from "../../../../explanations/diagrams/early-g1/parts";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { choiceStep, slips } from "../_kit";

/** a shape (0 rectangle, 1 square, 2 circle) cut into 2 or 4 equal parts, `shaded` of them shaded */
export interface HalvesProblem { shape: number; parts: number; cut: number; shaded: number }

export function createHalves(shape: number, parts: number, cut: number, shaded: number): HalvesProblem {
  wholeIn("shape", shape, 0, 2);
  if (parts !== 2 && parts !== 4) throw new Error("parts must be 2 or 4");
  if (!cutsAllowed(shape as ShapeKind).includes(cut)) throw new Error("that cut doesn't fit the shape");
  wholeIn("shaded", shaded, 1, parts - 1);
  return { shape, parts, cut, shaded };
}

const CHOICES = ["wholes", "halves", "fourths"];
const nameOf = (parts: number) => (parts === 2 ? "halves" : "fourths");
const oneName = (parts: number) => (parts === 2 ? "half" : "fourth");
const partWord = (n: number, parts: number) => (n === 1 ? oneName(parts) : nameOf(parts));
const picture = (p: HalvesProblem) => ({ shape: p.shape as ShapeKind, parts: p.parts as 2 | 4, cut: p.cut });

function answers(p: HalvesProblem): AnswerModel {
  const { parts, shaded } = p, shape = SHAPE_NAMES[p.shape]!, name = nameOf(parts), lines = cutLines(parts as 2 | 4, p.cut);
  const right = parts === 2 ? 1 : 2;
  return {
    steps: [
      oneBox({
        id: "parts", label: "Count the equal parts", question: `The ${shape} is cut into equal parts. How many parts?`,
        prompt: s => [s, text(" equal parts")], ans: parts,
        wrong: slips(parts, [
          [shaded, "Counted only the shaded parts", "Count **every** part, shaded or not."],
          [lines, "Counted the cut lines", "Those are the lines. Count the pieces between them."],
        ]),
        hint: "Touch each piece and count it once.",
        explain: `The ${shape} is cut into ${parts} equal parts.`,
      }),
      choiceStep({
        id: "name", label: "Name the parts", question: `${parts} equal parts. What are the parts called?`,
        prompt: [text("The parts are called ?")],
        choices: CHOICES, ans: right,
        wrong: [
          [0, "Picked wholes", `The whole is the full ${shape}. Each part is a smaller piece of it.`],
          [parts === 2 ? 2 : 1, "Mixed up halves and fourths", parts === 2 ? "Fourths means **4** equal parts. Here there are 2." : "Halves means **2** equal parts. Here there are 4."],
        ],
        hint: "2 equal parts are halves. 4 equal parts are fourths.",
        explain: `${parts} equal parts are ${name}. Each part is one ${oneName(parts)}.`,
        work: [text(`The parts are ${name}`)],
      }),
      oneBox({
        id: "shaded", label: `Count the shaded ${name}`, question: `How many ${name} are shaded?`,
        prompt: s => [s, text(` of ${parts} ${name}`)], ans: shaded,
        wrong: slips(shaded, [
          [parts - shaded, "Counted the white parts", "Those are the parts that are **not** shaded. Count the colored ones."],
          [parts, "Counted every part", "Count only the **shaded** parts."],
        ]),
        hint: "Count only the colored parts.",
        explain: `${shaded} of the ${parts} ${name} ${shaded === 1 ? "is" : "are"} shaded.`,
        work: [answer("x", shaded), text(` ${partWord(shaded, parts)} shaded`)],
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: HalvesProblem, model: AnswerModel): Explanation {
  const parts = expectedOf(model, "parts"), shaded = expectedOf(model, "shaded"), shape = SHAPE_NAMES[p.shape]!, name = nameOf(parts);
  return {
    heading: "Halves and fourths",
    idea: ["2 equal parts are halves, and 4 equal parts are fourths."],
    statement: [text("Halves or fourths?")],
    diagram: buildParts({
      ...picture(p), shaded,
      beats: { count: 0, one: 1, shaded: 2 },
      text: { count: `${parts} equal parts`, one: `each part is one ${oneName(parts)}`, shaded: `${shaded} ${partWord(shaded, parts)} shaded` },
      alt: `A ${shape} cut into ${parts} equal parts, ${shaded} of them shaded.`,
    }),
    caption: `${parts} equal parts are ${name}.`,
    timeline: beats(3),
    steps: [
      { id: "parts", narration: `Count the pieces: **${parts}** equal parts, all the same size.`, math: [num(parts), text(" equal parts")], state: 0, answerStep: "parts", result: parts },
      { id: "name", narration: `${parts} equal parts are **${name}**. Each one is one ${oneName(parts)} of the ${shape}.`, math: [text(`one ${oneName(parts)}`)], state: 1, answerStep: "name" },
      { id: "shaded", narration: `**${shaded}** of the ${parts} ${name} ${shaded === 1 ? "is" : "are"} shaded.`, math: [num(shaded), text(` ${partWord(shaded, parts)} shaded`)], state: 2, answerStep: "shaded", result: shaded },
    ],
  };
}

export const lesson: LessonDefinition<HalvesProblem> = {
  id: "g1-halves",
  grade: 1,
  unit: "Measurement and shapes",
  title: "Halves and fourths",
  pre: "k-shapes",
  reference: createHalves(0, 4, 0, 3),
  generate: (rng, index) => {
    const shape = rng.int(0, 2), parts = index === 1 ? 2 : rng.pick([2, 4]);
    return createHalves(shape, parts, rng.pick(cutsAllowed(shape as ShapeKind)), rng.int(1, parts - 1));
  },
  restore: raw => restoreVia(raw, ["shape", "parts", "cut", "shaded"] as const, v => createHalves(v.shape, v.parts, v.cut, v.shaded)),
  display: () => [text("Halves or fourths?")],
  displayNote: p => `The ${SHAPE_NAMES[p.shape]} is cut into equal parts.`,
  picture: p => buildParts({ ...picture(p), shaded: p.shaded, alt: `A ${SHAPE_NAMES[p.shape]} cut into equal parts, some shaded` }),
  answers,
  explain,
};
