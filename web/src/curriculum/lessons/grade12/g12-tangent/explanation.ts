import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import type { Pt } from "../../../../explanations/diagrams/plane/schema";
import { expected, f, lineText, P, poly, polyText, pt } from "../../_plane/kit";
import type { TangentProblem } from "./problem";
import { paren, signed } from "../../../text";

/** The window shows the whole bend near the touching point: x from 0 to 1.5 past k, and the vertex when it is close. */
export function tangentFit({ a, b, k }: TangentProblem): Pt[] {
  const F = (x: number) => a * x * x + b * x, v = -b / (2 * a);
  const xs = [0, k - 1.5, k + 1.5, ...(Math.abs(v - k) <= 3.5 ? [v] : [])];
  const lo = Math.min(...xs), hi = Math.max(...xs);
  const pts: Pt[] = [];
  for (let i = 0; i <= 24; i++) { const x = lo + ((hi - lo) * i) / 24; pts.push([x, F(x)]); }
  return pts;
}

export function explainTangent(p: TangentProblem, model: AnswerModel): Explanation {
  const { a, b, k, fk } = p;
  const da = expected(model, "derivative", "p"), slope = expected(model, "slope");
  const F = (x: number) => a * x * x + b * x;
  const fx = polyText([[a, "x²"], [b, "x"]]);
  // the tangent is drawn as a piece around the touching point, so the curve's bend shows on both sides
  const fit = tangentFit(p), reach = 0.32 * (Math.max(...fit.map(q => q[0])) - Math.min(...fit.map(q => q[0])));
  return {
    heading: "Slope = f′(x)",
    idea: ["A tangent line touches the curve at one point, and its slope is the derivative there."],
    statement: [text("f(x)"), op("="), ...poly([[a, "x²"], [b, "x"]]), text(`, at x = ${f(k)}`)],
    caption: `The tangent line touches at x = ${f(k)} with slope ${f(slope)}.`,
    diagram: buildPlane({
      alt: `Graph of f(x) = ${fx} with its tangent line at ${pt(k, fk)}, slope ${f(slope)}.`,
      fit,
      items: [
        { kind: "curve", f: F, label: { text: `f(x) = ${fx}`, optional: true } },
        { kind: "curve", f: x => fk + slope * (x - k), x0: k - reach, x1: k + reach, cls: "ln2", from: 2, label: { text: `slope ${f(slope)}`, acc: true }, labelX: k + reach * (slope >= 0 ? 0.8 : -0.8) },
        { kind: "point", at: [k, fk], from: 1, label: { text: pt(k, fk), prefer: a > 0 ? ["s", "se", "sw"] : ["n", "ne", "nw"] } },
      ],
    }),
    timeline: beats(3),
    steps: [
      { id: "curve", narration: `This is f(x) = ${fx}. Find how steep it is at x = ${f(k)}.`, math: [text("f(x)"), op("="), ...poly([[a, "x²"], [b, "x"]])], state: 0 },
      { id: "derivative", narration: `Bring each power down: 2 × ${f(a)} = ${f(da)} for x², and ${f(b)} stays for the x term. So f′(x) = ${lineText(da, b, "").slice(3)}.`,
        math: [text("f′(x)"), op("="), ...poly([[da, "x"], [b, ""]])], state: 1, answerStep: "derivative", result: da },
      { id: "slope", narration: `The tangent's slope is f′ at x = ${f(k)}: ${f(da)} · ${paren(k)} ${signed(b)} = ${f(slope)}. The line touches the curve at ${pt(k, fk)}.`,
        math: [num(da), op("·"), ...P(k), op("+"), ...P(b), op("="), num(slope)], state: 2, answerStep: "slope", result: slope },
    ],
  };
}
