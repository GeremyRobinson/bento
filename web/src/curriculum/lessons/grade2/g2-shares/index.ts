// Halves, thirds and fourths: count the equal parts, name them, count the shaded ones and how many make the whole.
// Some problems first ask whether parts cut two different ways are the same size.
import { answer, num, text } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { cutLines, cutsFor, SHAPE_NAMES, type ShapeKind } from "../../../../explanations/diagrams/early-g1/parts";
import { buildShares } from "../../../../explanations/diagrams/early-g2/shares";
import { oneBox, wholeIn } from "../../_number-line/steps";
import { tapStep } from "../../gradeK/kit";
import { slips } from "../kit";

/** shape 0 rectangle, 1 square, 2 circle, cut into `parts` equal parts, `shaded` shaded; `other` is a second copy's cut, or -1 */
export interface SharesProblem { shape: number; parts: number; cut: number; shaded: number; other: number }

export function createShares(shape: number, parts: number, cut: number, shaded: number, other = -1): SharesProblem {
  wholeIn("shape", shape, 0, 2);
  wholeIn("parts", parts, 2, 4);
  const cuts = cutsFor(shape as ShapeKind, parts as 2 | 3 | 4);
  if (!cuts.includes(cut)) throw new Error("that cut doesn't fit the shape");
  wholeIn("shaded", shaded, 1, parts);
  if (other !== -1 && (shape === 2 || other === cut || !cuts.includes(other))) throw new Error("the second copy is cut another way");
  return { shape, parts, cut, shaded, other };
}

const NAMES = ["Halves", "Thirds", "Fourths"];
const many = (parts: number) => NAMES[parts - 2]!.toLowerCase();
const one = (parts: number) => ["half", "third", "fourth"][parts - 2]!;
const word = (n: number, parts: number) => (n === 1 ? one(parts) : many(parts));

function answers(p: SharesProblem): AnswerModel {
  const { parts, shaded } = p, shape = SHAPE_NAMES[p.shape]!, name = many(parts), lines = cutLines(parts as 2 | 3 | 4, p.cut, p.shape as ShapeKind);
  const same: AnswerStep[] = p.other === -1 ? [] : [tapStep({
    id: "same", label: "Same size?", question: `Is one of these ${name} the same size as one of those?`,
    prompt: [text(`Both ${shape}s are the same size, each cut into ${parts} equal parts.`)],
    choices: ["Yes", "No"], right: 0,
    wrong: () => ["Went by the look", `They look different, but each is 1 of ${parts} equal parts of the same whole. They're the same size.`],
    hint: `Each ${shape} is the same whole, cut into ${parts} equal parts.`,
    explain: `Each part is one ${one(parts)} of the same ${shape}, so they're the same size, even cut a different way.`,
    work: [text(`Yes: each is one ${one(parts)}`)],
  })];
  return {
    steps: [
      ...same,
      oneBox({
        id: "parts", label: "Count the parts", question: "How many equal parts?",
        prompt: s => [s, text(" equal parts")], ans: parts,
        wrong: slips(parts, [
          [lines, "Counted the cut lines", "That's the cut lines. Count the pieces between them."],
          shaded < parts && [shaded, "Counted only the shaded parts", "Count **every** part, shaded or not."],
          [parts + 1, "Counted a piece twice", "One too many. Touch each piece once, and count it once."],
          [parts - 1, "Missed a piece", "One short. Every piece counts, even the one at the edge."],
        ]),
        hint: "Touch each piece and count it once.",
        explain: `The ${shape} is cut into ${parts} equal parts.`,
      }),
      tapStep({
        id: "name", label: "Name the parts", question: "What are the parts called?",
        prompt: [text(`${parts} equal parts are called ?`)],
        choices: NAMES, right: parts - 2,
        wrong: i => i === 0
          ? ["Picked halves", `Halves means 2 equal parts. Here there are ${parts}.`]
          : i === 1 ? ["Picked thirds", `There are ${parts} parts: ${name}.`] : ["Picked fourths", `${parts} equal parts are ${name}.`],
        hint: "2 equal parts are halves, 3 are thirds, 4 are fourths.",
        explain: `${parts} equal parts are ${name}. Each part is one ${one(parts)}.`,
        work: [text(`The parts are ${name}`)],
      }),
      oneBox({
        id: "shaded", label: "Count the shaded parts", question: `How many ${name} are shaded?`,
        prompt: s => [s, text(` of ${parts} ${name}`)], ans: shaded,
        wrong: slips(shaded, [
          shaded < parts && [parts - shaded, "Counted the white parts", "Those are the parts that are **not** shaded. Count the colored ones."],
          shaded < parts && [parts, "Counted every part", "Count only the **shaded** parts."],
          [shaded + 1, "Counted a white part", "One too many. Count only the colored parts."],
          [shaded - 1, "Missed a shaded part", "One short. Look for every colored part."],
        ]),
        hint: "Count only the colored parts.",
        explain: `${shaded} ${word(shaded, parts)} ${shaded === 1 ? "is" : "are"} shaded.`,
        work: [answer("x", shaded), text(` ${word(shaded, parts)} shaded`)],
      }),
      oneBox({
        id: "whole", label: "The whole", question: `How many ${name} make the whole ${shape}?`,
        prompt: s => [s, text(` ${name} make 1 whole`)], ans: parts,
        wrong: slips(parts, [
          shaded < parts && [shaded, "Counted only the shaded ones", "That's only the shaded ones. Count every part."],
          [1, "Called the whole one part", `The whole ${shape} is made of all the parts. How many ${name} fit in it?`],
        ]),
        hint: `Count every part of the ${shape}.`,
        explain: `${parts} ${name} make the whole ${shape}.`,
        work: [num(parts), text(` ${name} = 1 whole`)],
      }),
    ],
    finalParts: [-3, -2],
  };
}

const alt = (p: SharesProblem) => `A ${SHAPE_NAMES[p.shape]} cut into equal parts, some shaded.${p.other === -1 ? "" : ` Beside it, the same ${SHAPE_NAMES[p.shape]} cut another way.`}`;
const spec = (p: SharesProblem) => ({ shape: p.shape as ShapeKind, parts: p.parts as 2 | 3 | 4, cut: p.cut, shaded: p.shaded });

function explain(p: SharesProblem, model: AnswerModel): Explanation {
  const { parts, shaded } = p, shape = SHAPE_NAMES[p.shape]!, name = many(parts);
  const state: Record<string, number> = { same: 1, parts: 1, name: 2, shaded: 3, whole: 3 };
  return {
    heading: "Equal shares",
    idea: ["Equal shares are the same size, and together they make one whole."],
    statement: [text(`A ${shape} cut into ${name}.`)],
    diagram: buildShares({
      ...spec(p), beats: { count: 0, match: 1, one: 2, shaded: 3 },
      text: { count: `${parts} equal parts`, match: "every part is the same size", one: `each part is one ${one(parts)}`, shaded: `${shaded} ${word(shaded, parts)} shaded` },
      alt: `A ${shape} cut into ${parts} equal parts. The parts lift out and land on top of each other: they match. ${shaded} of them ${shaded === 1 ? "is" : "are"} shaded.`,
    }),
    caption: `${parts} equal parts are ${name}. ${shaded} ${word(shaded, parts)} shaded.`,
    timeline: beats(4),
    steps: [
      { id: "cut", narration: `The whole ${shape}, cut into parts.`, math: [text(`1 whole ${shape}`)], state: 0 },
      ...model.steps.map(s => ({ id: s.id, narration: s.explain, math: s.work ?? [num(s.slots[0]!.expected as number)], state: state[s.id]!, answerStep: s.id, result: s.slots[0]!.expected! })),
    ],
  };
}

export const lesson: LessonDefinition<SharesProblem> = {
  id: "g2-shares",
  grade: 2,
  unit: "Shapes",
  title: "Halves, thirds and fourths",
  reference: createShares(0, 3, 0, 2),
  generate: (rng, index) => {
    const early = index < 3, parts = early ? rng.pick([2, 4]) : rng.int(2, 4);
    const sameStep = index % 4 === 3;
    const shape = sameStep ? rng.int(0, 1) : rng.int(0, 2), cuts = cutsFor(shape as ShapeKind, parts as 2 | 3 | 4);
    const cut = rng.pick(cuts), shaded = early ? 1 : rng.int(1, parts);
    return createShares(shape, parts, cut, shaded, sameStep ? rng.pick(cuts.filter(c => c !== cut)) : -1);
  },
  restore: raw => {
    const r = raw as Partial<SharesProblem> | null;
    if (!r || typeof r !== "object") return null;
    try { return createShares(r.shape as number, r.parts as number, r.cut as number, r.shaded as number, (r.other ?? -1) as number); } catch { return null; }
  },
  display: p => [text(`A ${SHAPE_NAMES[p.shape]} cut into equal parts.`)],
  picture: p => buildShares({ ...spec(p), ...(p.other === -1 ? {} : { other: p.other }), alt: alt(p) }),
  answers,
  explain,
  pre: "g1-halves",
};
