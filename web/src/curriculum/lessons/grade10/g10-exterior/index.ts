import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTriangleAngles } from "../../../../explanations/diagrams/triangle-angles/build";
import { asRecord, expected, mt, ns, numberField } from "../../_geometry/kit";
import { withEasyStart } from "../../easy-start";

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
      ns({ id: "inside", label: "Third inside angle", prompt: s => mt`180° − ${a}° − ${b}° = ${s}°`, ans: 180 - a - b, hint: "The three inside angles share 180°, so the third is what's left after the two you know.", wrong: [[180 - a, "Took away only one", `Take both known angles off 180°: ${a}° and ${b}°.`]] }),
      ns({ id: "outside", label: "Outside angle", prompt: s => mt`180° − ${180 - a - b}° = ${s}°`, ans: a + b, hint: "The outside angle and the inside one make a straight line.",
        wrong: [[180 - a - b, "Gave the inside angle", "The outside angle is the other part of the straight line."], [180 - a, "Used a far angle", `Use the inside angle next to it: ${180 - a - b}°.`]] }),
      ns({ id: "check", label: "Check with the far angles", prompt: s => mt`${a}° + ${b}° = ${s}°`, ans: a + b, hint: "The outside angle equals the two far inside angles.", wrong: [[Math.abs(a - b), "Subtracted", "The two far angles together make the outside angle: add them."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainExteriorAngle(p: ExteriorAngleProblem, answers: AnswerModel): Explanation {
  const { a, b } = p, c = expected(answers, "inside"), out = expected(answers, "outside");
  return {
    heading: "Exterior = the two far angles added",
    idea: ["An outside angle and the inside angle next to it make a straight line."],
    // the problem asks for the outside angle, the one angle the picture marks "?"
    statement: mt`outside angle = ?`,
    caption: `The outside angle is ${a} + ${b} = ${out}°.`,
    diagram: buildTriangleAngles({
      // the third corner sits bottom right, so its outside angle opens along the base
      left: a, right: c,
      labels: { left: [{ text: `${a}°`, until: 2 }, { text: `${a}°`, from: 3, acc: true }], top: [{ text: `${b}°`, until: 2 }, { text: `${b}°`, from: 3, acc: true }], right: [{ text: `${c}°`, from: 1 }] },
      // the last beat lights the two far angles and the outside angle together
      accent: { left: 3, top: 3 },
      exterior: { labels: [{ text: "?", until: 1 }, { text: `${out}°`, from: 2 }] },
      notes: [{ text: `180° − ${a}° − ${b}° = ${c}°`, from: 1, until: 1 }, { text: `outside = 180° − ${c}° = ${out}°`, from: 2, until: 2 }, { text: `${a}° + ${b}° = ${out}°, the outside angle`, from: 3 }],
      alt: `A triangle with inside angles ${a}°, ${b}° and ${c}°. The base runs on past the ${c}° corner, making an outside angle of ${out}°.`,
    }),
    timeline: beats(4),
    steps: [
      { id: "triangle", narration: `Two inside angles are ${a}° and ${b}°. The side runs on past the third corner, making an outside angle.`, math: mt`${a}° and ${b}°`, state: 0 },
      { id: "inside", narration: `The inside angles add to 180°, so the third one is 180° − ${a}° − ${b}° = ${c}°.`, math: mt`180° − ${a}° − ${b}° = ${c}°`, state: 1, answerStep: "inside", result: c },
      { id: "outside", narration: `The outside angle and the ${c}° make a straight line: 180° − ${c}° = ${out}°. `, math: mt`180° − ${c}° = ${out}°`, state: 2, answerStep: "outside", result: out },
      { id: "check", narration: `Now add the two far angles: ${a}° + ${b}° = ${out}°, the same as the outside angle. That's the shortcut.`, math: mt`${a}° + ${b}° = ${out}°`, state: 3, answerStep: "check", result: out },
    ],
  };
}

export const lesson: LessonDefinition<ExteriorAngleProblem> = withEasyStart({
  id: "g10-exterior",
  grade: 10,
  unit: "Angles and triangles",
  title: "Exterior angle",
  pre: "g8-tri",
  reference: createExteriorAngle(50, 60),
  generate: rng => createExteriorAngle(rng.int(20, 80), rng.int(20, 80)),
  restore: restoreExteriorAngle,
  display: p => mt`${p.a}° and ${p.b}°`,
  displayNote: () => "Two inside angles of a triangle. Find the outside angle at the third corner.",
  answers: exteriorAngleAnswers,
  explain: explainExteriorAngle,
});
