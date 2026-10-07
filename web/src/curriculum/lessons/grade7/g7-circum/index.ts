import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildCircumference } from "../../../../explanations/diagrams/circle/build";
import { asRecord, expected, mt, ns, numberField, round6 } from "../../_geometry/kit";

/** A circle with radius r; the lesson uses 3.14 for π. */
export interface CircumferenceProblem {
  kind: "geometry.circumference";
  r: number;
}

export function createCircumference(r: number): CircumferenceProblem {
  if (!(r > 0)) throw new Error("the radius must be positive");
  return { kind: "geometry.circumference", r };
}

export function restoreCircumference(raw: unknown): CircumferenceProblem | null {
  const r = asRecord(raw), v = r && numberField(r, "r");
  if (v == null) return null;
  try { return createCircumference(v); } catch { return null; }
}

export function circumferenceAnswers({ r }: CircumferenceProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "diameter", label: "Diameter", prompt: s => mt`2 × ${r} = ${s}`, ans: 2 * r, hint: "The diameter is twice the radius.",
        wrong: [[round6(r / 2), "Halved the radius", "The diameter goes all the way across: two radii."], [r * r, "Squared the radius", "Twice the radius is 2 × r, not r × r."]] }),
      ns({ id: "times-pi", label: "Times π", prompt: s => mt`${2 * r} × 3.14 = ${s}`, ans: round6(2 * r * 3.14), hint: `${2 * r} × 3.14.`,
        wrong: [[round6(r * 3.14), "Used the radius", "Use the diameter, which is 2 × the radius."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainCircumference({ r }: CircumferenceProblem, answers: AnswerModel): Explanation {
  const d = expected(answers, "diameter"), c = expected(answers, "times-pi");
  return {
    heading: "C = π × d",
    idea: ["The distance around a circle is always π, about 3.14, times the diameter."],
    statement: mt`C = 3.14 × d`,
    caption: `About 3.14 diameters of ${d} go around: ${c}.`,
    diagram: buildCircumference({ r, d, c, pi: "3.14", diameterBeat: 1, aroundBeat: 2, alt: `A circle of radius ${r} and diameter ${d}, unrolled into a line about 3.14 diameters long: ${c}.` }),
    timeline: beats(3),
    steps: [
      { id: "circle", narration: `A circle with radius ${r}.`, math: mt`r = ${r}`, state: 0 },
      { id: "diameter", narration: `The diameter goes all the way across: twice the radius, 2 × ${r} = ${d}.`, math: mt`2 × ${r} = ${d}`, state: 1, answerStep: "diameter", result: d },
      { id: "times-pi", narration: `Unroll the edge: it is about 3.14 diameters long. ${d} × 3.14 = ${c}.`, math: mt`${d} × 3.14 = ${c}`, state: 2, answerStep: "times-pi", result: c },
    ],
  };
}

export const lesson: LessonDefinition<CircumferenceProblem> = {
  id: "g7-circum",
  grade: 7,
  unit: "Geometry",
  title: "Circumference",
  reference: createCircumference(5),
  // the first three: small circles
  generate: (rng, index) => createCircumference(index < 3 ? rng.int(2, 5) : rng.int(2, 12)),
  restore: restoreCircumference,
  display: p => mt`radius ${p.r}`,
  displayNote: () => "Circumference = π × diameter. Use 3.14 for π.",
  answers: circumferenceAnswers,
  explain: explainCircumference,
};
