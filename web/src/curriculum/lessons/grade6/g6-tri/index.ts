import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildAreaGrid } from "../../../../explanations/diagrams/area-model/grid";
import { r1 } from "../../../../explanations/diagrams/scene/helpers";
import { expectedOf, ns, readNumbers } from "../../area-common/steps";
import { aNum } from "../../../text";

/** A triangle with base b and height h; b × h is even so the area is whole. */
export interface TriangleProblem { b: number; h: number }

export function createTriangle(b: number, h: number): TriangleProblem {
  if (!(b > 0 && h > 0)) throw new Error("base and height are positive");
  return { b, h };
}

/** Same as the current app: base and height 2–20, with an even product. */
export function generateTriangle(rng: Rng): TriangleProblem {
  let b: number, h: number;
  do { b = rng.int(2, 20); h = rng.int(2, 20); } while ((b * h) % 2);
  return { b, h };
}

export function triangleAnswers({ b, h }: TriangleProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "rect", label: "Base × height", prompt: x => [num(b), op("×"), num(h), op("="), x], ans: b * h, hint: "Multiply the base and the height.",
        wrong: [[b + h, "Added instead of multiplied", "Multiply base × height."]] }),
      ns({ id: "half", label: "Half of it", prompt: x => [num(b * h), op("÷"), num(2), op("="), x], ans: (b * h) / 2, hint: "A triangle is half of a rectangle.",
        wrong: [[b * h, "Forgot to halve", "A triangle is half of a rectangle: divide by 2."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainTriangle(p: TriangleProblem, answers: AnswerModel): Explanation {
  const { b, h } = p, R = expectedOf(answers.steps, "rect"), A = expectedOf(answers.steps, "half");
  return {
    heading: "Half a rectangle",
    idea: ["A triangle is half of the rectangle around it."],
    statement: [text("base "), num(b), text(", height "), num(h)],
    diagram: buildAreaGrid({
      cols: [{ label: `base ${b}`, size: b }],
      rows: [{ label: `height ${h}`, size: h }],
      cells: [[{ from: 1, color: 0 }]],
      units: 1,
      outlineFrom: 1,
      extras: g => {
        const x0 = g.left, y0 = g.top, x1 = g.left + g.width, y1 = g.top + g.height;
        const tri: [number, number][] = [[x0, y1], [x1, y1], [x0, y0]].map(([x, y]) => [r1(x!), r1(y!)]);
        const twin: [number, number][] = [[x1, y0], [x0, y0], [x1, y1]].map(([x, y]) => [r1(x!), r1(y!)]);
        return [
          { type: "polygon", points: twin, cls: "tri c1", from: 2, enter: "fade", delay: 0.2 },
          { type: "polygon", points: tri, cls: "tri c0", from: 0, enter: "pop" },
          { type: "text", x: r1((2 * x0 + x1) / 3), y: r1((2 * y1 + y0) / 3), text: String(A), cls: "lbl", from: 2, enter: "rise", delay: 0.5 },
          { type: "text", x: r1((x0 + 2 * x1) / 3), y: r1((y1 + 2 * y0) / 3), text: String(A), cls: "lbl", from: 2, enter: "rise", delay: 0.7 },
        ];
      },
      lines: [
        { text: `rectangle: ${b} × ${h} = ${R}`, from: 1, until: 1 },
        { text: `${b} × ${h} = ${R}, half is ${A}`, from: 2 },
      ],
      alt: `A triangle with base ${b} and height ${h} inside ${aNum(b)} by ${h} rectangle of ${R}; the triangle is half, ${A}.`,
    }),
    caption: `The triangle is half of its ${b} by ${h} rectangle.`,
    timeline: beats(3),
    steps: [
      { id: "rect", narration: `Draw the rectangle around it: ${b} × ${h} = ${R}.`, math: [num(b), op("×"), num(h), op("="), num(R)], state: 1, answerStep: "rect", result: R },
      { id: "half", narration: `Two copies of the triangle fill the rectangle, so the triangle is half: ${A}.`, math: [num(R), op("÷"), num(2), op("="), num(A)], state: 2, answerStep: "half", result: A },
    ],
  };
}

export const lesson: LessonDefinition<TriangleProblem> = {
  id: "g6-tri",
  grade: 6,
  unit: "Geometry",
  title: "Area of a triangle",
  pre: "g4-area",
  reference: createTriangle(6, 4),
  generate: rng => generateTriangle(rng),
  restore: raw => { const r = readNumbers(raw, ["b", "h"] as const); try { return r && createTriangle(r.b, r.h); } catch { return null; } },
  display: p => [text("base "), num(p.b), text(", height "), num(p.h)],
  displayNote: () => "Area = base × height ÷ 2",
  answers: triangleAnswers,
  explain: explainTriangle,
};
