import { num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import { attempt, expected, f, ints, ms, ns, nz, pt } from "../../_plane/kit";
import { withEasyStart } from "../../easy-start";

/** (x − h)² + (y − k)² = r² */
export interface CircleProblem { kind: "coordinate.circle"; h: number; k: number; r: number }

export function createCircle(h: number, k: number, r: number): CircleProblem {
  if (h === 0 || k === 0 || r < 1) throw new Error("center off the axes and a positive radius");
  return { kind: "coordinate.circle", h, k, r };
}

/** Same as the current app: center −9..9 (not 0), radius 1..9. */
export const generateCircle = (rng: Rng) => createCircle(nz(rng, -9, 9), nz(rng, -9, 9), rng.int(1, 9));

export function restoreCircle(raw: unknown): CircleProblem | null {
  const v = ints(raw, ["h", "k", "r"] as const);
  return v && attempt(() => createCircle(v.h, v.k, v.r));
}

const shift = (v: string, c: number) => `(${v} ${c < 0 ? "+" : "−"} ${Math.abs(c)})²`;
export const circleMath = ({ h, k, r }: CircleProblem): MathText => [text(shift("x", h)), op("+"), text(shift("y", k)), op("="), num(r * r)];

export function circleAnswers({ h, k, r }: CircleProblem): AnswerModel {
  return {
    steps: [
      ms({ id: "center", label: "Center", prompt: S => [text("("), ...S.h!, text(", "), ...S.k!, text(")")], ans: { h, k },
        hint: "(x − h)² is 0 when x = h, and that is the center. So the center has the opposite sign of the number you see: a + inside means a negative center.",
        wrong: [[{ h: -h, k: -k }, "Flipped the signs", "(x − h)²: the center's x is h, so x + 3 means h = −3."]] }),
      ns({ id: "r", label: "Radius", prompt: s => [text("r"), op("="), text("√"), num(r * r), op("="), ...s], ans: r,
        hint: `The equation shows r² = ${r * r}.`, wrong: [[r * r, "Forgot the square root", "The right side is r², so take the square root."]] }),
    ],
    finalParts: [-2, -1],
  };
}

export function explainCircle(p: CircleProblem, model: AnswerModel): Explanation {
  const { h, k } = p, r = expected(model, "r");
  return {
    heading: "(x − h)² + (y − k)² = r²",
    idea: ["Every point on a circle is the same distance r from the center (h, k). The equation hides the center with opposite signs, and the right side is r²."],
    statement: circleMath(p),
    caption: `Center ${pt(h, k)}, radius √${f(r * r)} = ${f(r)}.`,
    diagram: buildPlane({
      alt: `Graph: a circle with center ${pt(h, k)} and radius ${f(r)}.`,
      equal: true,
      fit: [[h - r, k - r], [h + r, k + r]],
      items: [
        { kind: "point", at: [h, k], cls: "dota", from: 1, label: { text: pt(h, k), acc: true, prefer: ["s", "sw", "se"] } },
        { kind: "segment", a: [h, k], b: [h + r, k], cls: "ln2", from: 2, label: { text: `r = ${f(r)}`, acc: true, prefer: ["n", "s"] } },
        { kind: "circle", c: [h, k], r, from: 2, delay: 0.3 },
      ],
    }),
    timeline: beats(3),
    steps: [
      { id: "eq", narration: "Read the circle's center and radius straight from its equation.", math: circleMath(p), state: 0 },
      { id: "center", narration: `Flip the signs inside the parentheses: the center is ${pt(h, k)}.`, math: [text(`(${f(h)}, ${f(k)})`)], state: 1 },
      { id: "r", narration: `The right side is r² = ${f(r * r)}, so the radius is √${f(r * r)} = ${f(r)}.`, math: [text("r"), op("="), text("√"), num(r * r), op("="), num(r)], state: 2, answerStep: "r", result: r },
    ],
  };
}

export const lesson: LessonDefinition<CircleProblem> = withEasyStart({
  id: "g10-circle",
  grade: 10,
  unit: "Coordinate geometry",
  title: "Equation of a circle",
  pre: "g10-dist",
  reference: createCircle(2, -3, 4),
  generate: rng => generateCircle(rng),
  restore: restoreCircle,
  display: circleMath,
  displayNote: () => "Find the center and radius.",
  answers: circleAnswers,
  explain: explainCircle,
});
