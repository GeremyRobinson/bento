import { num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import { attempt, expected, f, ints, ns, P } from "../../_plane/kit";
import { TRIPLES } from "../../_geometry/kit";
import { withEasyStart } from "../../easy-start";

/** v = ⟨x, y⟩ with a whole length m. */
export interface VecMagProblem { kind: "vector.magnitude"; x: number; y: number; m: number }

export function createVecMag(x: number, y: number): VecMagProblem {
  const m = Math.hypot(x, y);
  if (x === 0 || y === 0 || !Number.isInteger(m)) throw new Error("both parts non-zero with a whole length");
  return { kind: "vector.magnitude", x, y, m };
}

/** Same as the current app: a triple's legs with random signs, either way round. */
export function generateVecMag(rng: Rng): VecMagProblem {
  const [p, r] = rng.pick(TRIPLES), s1 = rng.pick([1, -1]), s2 = rng.pick([1, -1]);
  return rng.next() < 0.5 ? createVecMag(s1 * p, s2 * r) : createVecMag(s1 * r, s2 * p);
}

export function restoreVecMag(raw: unknown): VecMagProblem | null {
  const v = ints(raw, ["x", "y"] as const);
  return v && attempt(() => createVecMag(v.x, v.y));
}

const vec = (x: number, y: number): MathText => [text("⟨"), num(x), text(", "), num(y), text("⟩")];
export const vecMagMath = ({ x, y }: VecMagProblem): MathText => [text("v = "), ...vec(x, y)];
const sq = (v: number): MathText => [...P(v), text("²")];

export function vecMagAnswers({ x, y, m }: VecMagProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "sum", label: "Square and add", prompt: s => [...sq(x), op("+"), ...sq(y), op("="), ...s], ans: x * x + y * y,
        hint: "The two parts are the legs of a right triangle: square each, then add.", wrong: [[x + y, "Forgot to square", "Square each part first."]] }),
      ns({ id: "m", label: "Square root", prompt: s => [text("√"), num(x * x + y * y), op("="), ...s], ans: m, hint: "The length is the long side of that right triangle: the number that times itself makes the sum.", wrong: [[Math.abs(x) + Math.abs(y), "Added the parts", "The straight arrow is shorter than going across and then up."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainVecMag(p: VecMagProblem, model: AnswerModel): Explanation {
  const { x, y } = p, S = expected(model, "sum"), m = expected(model, "m");
  return {
    heading: "√(x² + y²)",
    idea: ["A vector's length is the long side of the right triangle its parts make: square both parts, add, and take the square root."],
    statement: vecMagMath(p),
    caption: `Legs ${f(Math.abs(x))} and ${f(Math.abs(y))}: |v| = ${f(m)}.`,
    diagram: buildPlane({
      alt: `Graph: the vector ⟨${f(x)}, ${f(y)}⟩ from the origin, with legs ${f(Math.abs(x))} and ${f(Math.abs(y))} and length ${f(m)}.`,
      equal: true,
      fit: [[0, 0], [x, y]],
      items: [
        { kind: "segment", a: [0, 0], b: [x, 0], cls: "ln2 dash", from: 1, label: { text: f(Math.abs(x)), acc: true, prefer: y > 0 ? ["s", "n"] : ["n", "s"] } },
        { kind: "segment", a: [x, 0], b: [x, y], cls: "ln2 dash", from: 1, delay: 0.3, label: { text: f(Math.abs(y)), acc: true, prefer: x > 0 ? ["e", "w"] : ["w", "e"] } },
        { kind: "rightAngle", at: [x, 0], u: [-Math.sign(x), 0], v: [0, Math.sign(y)], from: 1 },
        { kind: "segment", a: [0, 0], b: [x, y], arrow: true, label: { text: `|v| = ${f(m)}`, acc: true, from: 2, prefer: ["nw", "ne", "n"] } },
      ],
    }),
    timeline: beats(3),
    steps: [
      { id: "v", narration: `v goes ${f(Math.abs(x))} ${x > 0 ? "right" : "left"} and ${f(Math.abs(y))} ${y > 0 ? "up" : "down"}.`, math: vecMagMath(p), state: 0 },
      { id: "sum", narration: `Those are the legs of a right triangle. Square and add: ${f(x * x)} + ${f(y * y)} = ${f(S)}.`, math: [...sq(x), op("+"), ...sq(y), op("="), num(S)], state: 1, answerStep: "sum", result: S },
      { id: "m", narration: `The length is the square root: √${f(S)} = ${f(m)}.`, math: [text("√"), num(S), op("="), num(m)], state: 2, answerStep: "m", result: m },
    ],
  };
}

export const lesson: LessonDefinition<VecMagProblem> = withEasyStart({
  id: "g12-vecmag",
  grade: 12,
  unit: "Vectors and series",
  title: "Vector length",
  reference: createVecMag(3, -4),
  generate: rng => generateVecMag(rng),
  restore: restoreVecMag,
  display: vecMagMath,
  displayNote: () => "Find |v|.",
  answers: vecMagAnswers,
  explain: explainVecMag,
});
