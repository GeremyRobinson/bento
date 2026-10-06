import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTriangleAngles } from "../../../../explanations/diagrams/triangle-angles/build";
import { asRecord, expected, mt, ns, numberField } from "../../_geometry/kit";

/** Two inside angles a and b of a triangle; the outside angle at the third corner is wanted. */
export interface ExteriorAngleProblem {
  kind: "geometry.exteriorAngle";
  a: number;
  b: number;
}

export function createExteriorAngle(a: number, b: number): ExteriorAngleProblem {
  if (![a, b].every(v => Number.isInteger(v) && v > 0) || a + b >= 180) throw new Error("two angles of a triangle add to less than 180°");
  return { kind: "geometry.exteriorAngle", a, b };
}

export function restoreExteriorAngle(raw: unknown): ExteriorAngleProblem | null {
  const r = asRecord(raw);
  const a = r && numberField(r, "a"), b = r && numberField(r, "b");
  if (a == null || b == null) return null;
  try { return createExteriorAngle(a, b); } catch { return null; }
}

export function exteriorAngleAnswers({ a, b }: ExteriorAngleProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "inside", label: "Third inside angle", prompt: s => mt`180° − ${a}° − ${b}° = ${s}°`, ans: 180 - a - b, hint: "Inside angles add to 180°." }),
      ns({ id: "outside", label: "Outside angle", prompt: s => mt`180° − ${180 - a - b}° = ${s}°`, ans: a + b, hint: "The outside angle and the inside one make a straight line.",
        wrong: [[180 - a - b, "Gave the inside angle", "The outside angle is the other part of the straight line."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainExteriorAngle(p: ExteriorAngleProblem, answers: AnswerModel): Explanation {
  const { a, b } = p, c = expected(answers, "inside"), out = expected(answers, "outside");
  return {
    heading: "Exterior = the two far angles added",
    idea: ["An outside angle and the inside angle next to it make a straight line: 180°.", "So the outside angle equals the two far inside angles added together."],
    // the problem asks for the outside angle, the one angle the picture marks "?"
    statement: mt`outside angle = ?`,
    caption: `The outside angle is ${a} + ${b} = ${out}°.`,
    diagram: buildTriangleAngles({
      // the third corner sits bottom right, so its outside angle opens along the base
      left: a, right: c,
      labels: { left: [{ text: `${a}°` }], top: [{ text: `${b}°` }], right: [{ text: `${c}°`, from: 1 }] },
      exterior: { labels: [{ text: "?", until: 1 }, { text: `${out}°`, from: 2 }] },
      notes: [{ text: `180° − ${a}° − ${b}° = ${c}°`, from: 1, until: 1 }, { text: `outside = ${a}° + ${b}° = ${out}°`, from: 2 }],
      alt: `A triangle with inside angles ${a}°, ${b}° and ${c}°. The base runs on past the ${c}° corner, making an outside angle of ${out}°.`,
    }),
    timeline: beats(3),
    steps: [
      { id: "triangle", narration: `Two inside angles are ${a}° and ${b}°. The side runs on past the third corner, making an outside angle.`, math: mt`${a}° and ${b}°`, state: 0 },
      { id: "inside", narration: `The inside angles add to 180°, so the third one is 180° − ${a}° − ${b}° = ${c}°.`, math: mt`180° − ${a}° − ${b}° = ${c}°`, state: 1, answerStep: "inside", result: c },
      { id: "outside", narration: `The outside angle and the ${c}° make a straight line: 180° − ${c}° = ${out}°. That's ${a} + ${b}, the two far angles.`, math: mt`180° − ${c}° = ${out}°`, state: 2, answerStep: "outside", result: out },
    ],
  };
}

export const lesson: LessonDefinition<ExteriorAngleProblem> = {
  id: "g10-exterior",
  grade: 10,
  unit: "Angles and triangles",
  title: "Exterior angle",
  reference: createExteriorAngle(50, 60),
  generate: rng => createExteriorAngle(rng.int(20, 80), rng.int(20, 80)),
  restore: restoreExteriorAngle,
  display: p => mt`${p.a}° and ${p.b}°`,
  displayNote: () => "Two inside angles of a triangle. Find the outside angle at the third corner.",
  answers: exteriorAngleAnswers,
  explain: explainExteriorAngle,
};
