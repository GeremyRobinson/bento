import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTriangleAngles } from "../../../../explanations/diagrams/triangle-angles/build";
import { asRecord, expected, mt, ns, numberField } from "../../_geometry/kit";
import { withEasyStart } from "../../easy-start";

/** Two angles of a triangle, a and b; the third is missing. */
export interface TriangleAnglesProblem {
  kind: "geometry.triangleAngles";
  a: number;
  b: number;
}

export function createTriangleAngles(a: number, b: number): TriangleAnglesProblem {
  if (![a, b].every(v => Number.isInteger(v) && v > 0) || a + b >= 180) throw new Error("two angles of a triangle add to less than 180°");
  return { kind: "geometry.triangleAngles", a, b };
}

export function restoreTriangleAngles(raw: unknown): TriangleAnglesProblem | null {
  const r = asRecord(raw);
  const a = r && numberField(r, "a"), b = r && numberField(r, "b");
  if (a == null || b == null) return null;
  try { return createTriangleAngles(a, b); } catch { return null; }
}

export function triangleAnglesAnswers({ a, b }: TriangleAnglesProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "add", label: "Add the two angles", prompt: s => mt`${a}° + ${b}° = ${s}°`, ans: a + b, hint: "The two angles you know take up this much of the 180°: add them.", wrong: [[Math.abs(a - b), "Subtracted", "Put the two known angles together: add them."]] }),
      ns({ id: "third", label: "Subtract from 180", prompt: s => mt`180° − ${a + b}° = ${s}°`, ans: 180 - a - b, hint: "A triangle's angles add up to 180°.",
        wrong: [[360 - a - b, "Used 360°", "Triangles add up to 180°. 360° is for four-sided shapes."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainTriangleAngles(p: TriangleAnglesProblem, answers: AnswerModel): Explanation {
  const { a, b } = p, sum = expected(answers, "add"), c = expected(answers, "third");
  return {
    heading: "Triangles add up to 180°",
    idea: ["Tear off the three corners of any triangle and line them up: they make a straight line, 180°.", "Add the two you know, then take that away from 180."],
    statement: mt`${a}° + ${b}° + ? = 180°`,
    caption: `${a}° + ${b}° + ${c}° = 180°.`,
    diagram: buildTriangleAngles({
      left: a, right: b,
      labels: { left: [{ text: `${a}°` }], right: [{ text: `${b}°` }], top: [{ text: "?", acc: true, until: 1 }, { text: `${c}°`, acc: true, from: 2 }] },
      accent: { top: 0 },
      // labels clear of their arcs
      labelGap: 20,
      notes: [{ text: `${a}° + ${b}° = ${sum}°`, from: 1, until: 1 }, { text: `180° − ${sum}° = ${c}°`, from: 2 }],
      alt: `A triangle drawn with angles of ${a}° and ${b}°; the third angle is ${c}°.`,
    }),
    timeline: beats(3),
    steps: [
      { id: "triangle", narration: `A triangle with angles of ${a}° and ${b}°. The third corner is missing.`, math: mt`${a}°, ${b}°, ?`, state: 0 },
      { id: "add", narration: `Put the two known angles together: ${a}° + ${b}° = ${sum}°.`, math: mt`${a}° + ${b}° = ${sum}°`, state: 1, answerStep: "add", result: sum },
      { id: "third", narration: `All three make 180°, so the third angle is 180° − ${sum}° = ${c}°.`, math: mt`180° − ${sum}° = ${c}°`, state: 2, answerStep: "third", result: c },
    ],
  };
}

export const lesson: LessonDefinition<TriangleAnglesProblem> = withEasyStart({
  id: "g8-tri",
  grade: 8,
  unit: "Geometry",
  title: "Angles in a triangle",
  reference: createTriangleAngles(50, 60),
  generate: rng => { const a = rng.int(20, 100); return createTriangleAngles(a, rng.int(20, 150 - a)); },
  restore: restoreTriangleAngles,
  display: p => mt`${p.a}°, ${p.b}°, ?`,
  displayNote: () => "Two angles of a triangle. Find the third.",
  answers: triangleAnglesAnswers,
  explain: explainTriangleAngles,
});
