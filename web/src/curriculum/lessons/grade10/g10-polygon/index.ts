import { formatNumber as f } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPolygonSplit } from "../../../../explanations/diagrams/polygon-split/build";
import { asRecord, expected, mt, ns, numberField } from "../../_geometry/kit";
import { withEasyStart } from "../../easy-start";

/** A regular polygon with n sides. */
export interface PolygonAnglesProblem {
  kind: "geometry.polygonAngles";
  n: number;
}

export const POLYGON_SIDES = [5, 6, 8, 9, 10, 12, 15, 18, 20] as const;

export function createPolygonAngles(n: number): PolygonAnglesProblem {
  if (!Number.isInteger(n) || n < 3) throw new Error("a polygon has at least 3 sides");
  return { kind: "geometry.polygonAngles", n };
}

export function restorePolygonAngles(raw: unknown): PolygonAnglesProblem | null {
  const r = asRecord(raw);
  const n = r && numberField(r, "n");
  if (n == null) return null;
  try { return createPolygonAngles(n); } catch { return null; }
}

export function polygonAnglesAnswers({ n }: PolygonAnglesProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "triangles", label: "Triangles inside", prompt: s => mt`${n} − 2 = ${s}`, ans: n - 2, hint: "Lines from one corner split the polygon into triangles: the two sides next to that corner don't make one of their own, so it's sides − 2.",
        wrong: [[n, "One per side", "From one corner, the two sides next to it don't make triangles of their own: it's sides − 2."]] }),
      ns({ id: "total", label: "Total degrees", prompt: s => mt`${n - 2} × 180° = ${s}°`, ans: (n - 2) * 180, hint: "Each triangle has 180°.",
        wrong: [[n * 180, "Used n instead of n − 2", `It's ${n} − 2 triangles, not ${n}.`]] }),
      ns({ id: "each", label: "Each angle", prompt: s => mt`${(n - 2) * 180}° ÷ ${n} = ${s}°`, ans: ((n - 2) * 180) / n, hint: "Regular means all angles are equal, so share the total out equally among the corners.", wrong: [[(n - 2) * 180 / (n - 2), "Divided by the triangles", `Share the total among the ${n} corners, not the ${n - 2} triangles.`]] }),
    ],
    finalParts: [-1],
  };
}

export function explainPolygonAngles({ n }: PolygonAnglesProblem, answers: AnswerModel): Explanation {
  const tri = expected(answers, "triangles"), total = expected(answers, "total"), each = expected(answers, "each");
  return {
    heading: "(n − 2) × 180°",
    idea: ["Cut a polygon into triangles from one corner: there are always 2 fewer triangles than sides.", "Each triangle holds 180°. In a regular polygon every angle gets an equal share."],
    statement: mt`(${n} − 2) × 180° ÷ ${n}`,
    caption: `${tri} triangles × 180° = ${total}°, shared by ${n} equal angles.`,
    diagram: buildPolygonSplit({
      n, trianglesBeat: 1, angleBeat: 3, angleText: `${f(each)}°`,
      notes: [
        { text: `${tri} triangles`, from: 1 },
        { text: `${tri} × 180° = ${total}°`, from: 2 },
        { text: `${total}° ÷ ${n} = ${f(each)}°`, from: 3, acc: true },
      ],
      alt: `A regular polygon with ${n} sides cut into ${tri} triangles from one corner. Its angles add to ${total}°, so each is ${f(each)}°.`,
    }),
    timeline: beats(4),
    steps: [
      { id: "polygon", narration: `A regular polygon with ${n} equal sides and ${n} equal angles.`, math: mt`${n} sides`, state: 0 },
      { id: "triangles", narration: `Draw lines from one corner to every other corner. That makes ${n} − 2 = ${tri} triangles.`, math: mt`${n} − 2 = ${tri}`, state: 1, answerStep: "triangles", result: tri },
      { id: "total", narration: `Each triangle holds 180°, so all the angles add to ${tri} × 180° = ${total}°.`, math: mt`${tri} × 180° = ${total}°`, state: 2, answerStep: "total", result: total },
      { id: "each", narration: `The ${n} angles are equal, so each gets ${total}° ÷ ${n} = ${f(each)}°.`, math: mt`${total}° ÷ ${n} = ${each}°`, state: 3, answerStep: "each", result: each },
    ],
  };
}

export const lesson: LessonDefinition<PolygonAnglesProblem> = withEasyStart({
  id: "g10-polygon",
  grade: 10,
  unit: "Angles and triangles",
  title: "Angles in a polygon",
  pre: "g8-tri",
  reference: createPolygonAngles(6),
  generate: rng => createPolygonAngles(rng.pick(POLYGON_SIDES)),
  restore: restorePolygonAngles,
  display: p => mt`a regular ${p.n}-sided polygon`,
  displayNote: () => "How big is each inside angle?",
  answers: polygonAnglesAnswers,
  explain: explainPolygonAngles,
});
