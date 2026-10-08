import { br, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import { expected, f, pt } from "../../_plane/kit";
import type { SystemProblem } from "./problem";

/** y = 4x and x + y = 15, one equation per line */
export const systemMath = ({ k, s }: SystemProblem): MathText =>
  [text("y"), op("="), num(k), text("x"), br(), text("x + y"), op("="), num(s)];

export function explainSystem(p: SystemProblem, model: AnswerModel): Explanation {
  const { k, s } = p;
  const c = expected(model, "sub"), x = expected(model, "x"), y = expected(model, "y");
  return {
    heading: "Swap one equation into the other",
    idea: ["When one equation says what y is, that can stand in for y in the other one."],
    statement: systemMath(p),
    caption: `The answer is where the lines cross: ${pt(x, y)}.`,
    diagram: buildPlane({
      alt: `Graph: the lines y = ${k}x and x + y = ${s} cross at ${pt(x, y)}.`,
      fit: [[x, y], [x * 1.6, 0], [0, y * 1.15]],
      items: [
        { kind: "line", m: k, b: 0, label: { text: `y = ${k}x` }, labelX: x * 0.5 },
        { kind: "line", m: -1, b: s, cls: "ln2", delay: 0.6, label: { text: `x + y = ${s}`, acc: true } },
        { kind: "segment", a: [x, 0], b: [x, y], cls: "ln thin dash", from: 2, label: { text: `x = ${f(x)}`, prefer: ["e", "w"] } },
        { kind: "segment", a: [0, y], b: [x, y], cls: "ln thin dash", from: 3, label: { text: `y = ${f(y)}`, prefer: ["e", "ne"], clearAxes: true } },
        { kind: "point", at: [x, y], cls: "dota", from: 3, label: { text: pt(x, y), acc: true, prefer: ["ne", "e", "n"] } },
      ],
    }),
    timeline: beats(4),
    steps: [
      { id: "lines", narration: `Each equation is a line. The answer is the point on both lines.`, math: systemMath(p), state: 0 },
      { id: "sub", narration: `y is ${k}x, so put ${k}x in place of y: x + ${k}x. One x plus ${k} x's makes ${c}x.`,
        math: [text("x"), op("+"), num(k), text("x"), op("="), num(c), text("x"), op("="), num(s)], state: 1, answerStep: "sub", result: c },
      { id: "x", narration: `${c}x = ${s}, so x = ${s} ÷ ${c} = ${f(x)}. That is where the lines cross, left to right.`,
        math: [num(c), text("x"), op("="), num(s), text(", so x"), op("="), num(x)], state: 2, answerStep: "x", result: x },
      { id: "y", narration: `Put x = ${f(x)} back into y = ${k}x: y = ${k} × ${f(x)} = ${f(y)}. The lines cross at ${pt(x, y)}.`,
        math: [text("y"), op("="), num(k), op("×"), num(x), op("="), num(y)], state: 3, answerStep: "y", result: y },
    ],
  };
}
