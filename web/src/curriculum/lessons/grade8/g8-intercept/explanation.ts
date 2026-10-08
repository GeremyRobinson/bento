import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import { expected, f, fP, lineText, P, pt } from "../../_plane/kit";
import type { InterceptProblem } from "./problem";

export const interceptMath = ({ m, x0, y0 }: InterceptProblem) => [text("slope "), num(m), text(", through ("), num(x0), text(", "), num(y0), text(")")];

export function explainIntercept(p: InterceptProblem, model: AnswerModel): Explanation {
  const { m, x0, y0 } = p;
  const mx = expected(model, "mx"), b = expected(model, "b");
  const line = lineText(m, b);
  return {
    heading: "Find b with the point",
    idea: ["b is where the line crosses the y-axis, and the point you know sits on the line."],
    statement: interceptMath(p),
    caption: `From the y-axis to x = ${f(x0)}, the line changes by ${f(m)} × ${fP(x0)} = ${f(mx)}, so it crosses the y-axis at b = ${f(b)}.`,
    diagram: buildPlane({
      alt: `Graph: the line ${line} through ${pt(x0, y0)}, crossing the y-axis at ${f(b)}.`,
      fit: [[x0, y0], [0, b], [x0 + Math.sign(x0), y0 + m * Math.sign(x0)]],
      items: [
        { kind: "line", m, b, from: 3, cls: "ln", label: { text: line }, labelX: x0 + Math.sign(x0) * 0.9 },
        { kind: "segment", a: [0, b], b: [x0, b], cls: "ln2 dash", from: 1, label: { text: `${f(x0)} across`, acc: true, optional: true, prefer: mx > 0 ? ["s", "n"] : ["n", "s"] } },
        { kind: "segment", a: [x0, b], b: [x0, y0], cls: "ln2 dash", from: 1, delay: 0.4, label: { text: `${f(m)} × ${fP(x0)} = ${f(mx)}`, acc: true, prefer: x0 > 0 ? ["e", "w"] : ["w", "e"] } },
        { kind: "point", at: [0, b], cls: "dota", from: 2, label: { text: `b = ${f(b)}`, acc: true, prefer: x0 > 0 ? ["w", "nw", "sw"] : ["e", "ne", "se"] } },
        { kind: "point", at: [x0, y0], label: { text: pt(x0, y0), prefer: mx > 0 ? ["n", "ne", "nw"] : ["s", "se", "sw"] } },
      ],
    }),
    timeline: beats(4),
    steps: [
      { id: "point", narration: `The line has slope ${f(m)} and goes through ${pt(x0, y0)}.`, math: interceptMath(p), state: 0 },
      { id: "mx", narration: `Going from the y-axis to x = ${f(x0)}, the line changes by slope × x: ${f(m)} × ${fP(x0)} = ${f(mx)}.`,
        math: [...P(m), op("×"), ...P(x0), op("="), num(mx)], state: 1, answerStep: "mx", result: mx },
      { id: "b", narration: `So the line crosses the y-axis ${f(mx)} away from ${f(y0)}: b = ${f(y0)} − ${fP(mx)} = ${f(b)}.`,
        math: [text("b"), op("="), num(y0), op("−"), ...P(mx), op("="), num(b)], state: 2, answerStep: "b", result: b },
      { id: "line", narration: `Slope ${f(m)} and b = ${f(b)}: the line is ${line}.`, math: [text(line)], state: 3, answerStep: "line", result: m },
    ],
  };
}
