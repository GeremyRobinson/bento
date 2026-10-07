import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import { expected, f, parabolaFit, poly, polyText } from "../../_plane/kit";
import type { SolveFactorProblem } from "./problem";

export const solveFactorMath = ({ b, c }: SolveFactorProblem) => [...poly([[1, "x²"], [b, "x"], [c, ""]]), op("="), num(0)];

export function explainSolveFactor(p: SolveFactorProblem, model: AnswerModel): Explanation {
  const { b, c } = p;
  const m = expected(model, "roots", "m"), n = expected(model, "roots", "n");
  const F = (x: number) => x * x + b * x + c;
  const lo = Math.min(m, n), hi = Math.max(m, n);
  return {
    heading: "Factor, then set each part to 0",
    idea: ["If two numbers multiply to 0, one of them must be 0."],
    statement: solveFactorMath(p),
    caption: `The graph crosses 0 at x = ${f(lo)} and x = ${f(hi)}.`,
    diagram: buildPlane({
      alt: `Graph of y = ${polyText([[1, "x²"], [b, "x"], [c, ""]])}, crossing the x-axis at ${f(lo)} and ${f(hi)}.`,
      fit: parabolaFit(1, b, c, [m, n]),
      items: [
        { kind: "curve", f: F, label: { text: `y = (x − ${f(m)})(x − ${f(n)})`, from: 1, optional: true } },
        { kind: "point", at: [lo, 0], cls: "dota", from: 2, label: { text: `x = ${f(lo)}`, acc: true, prefer: ["nw", "n", "sw"] } },
        { kind: "point", at: [hi, 0], cls: "dota", from: 2, delay: 0.3, label: { text: `x = ${f(hi)}`, acc: true, prefer: ["ne", "n", "se"] } },
      ],
    }),
    timeline: beats(3),
    steps: [
      { id: "eq", narration: `Find the x values that make ${polyText([[1, "x²"], [b, "x"], [c, ""]])} equal 0: where the graph crosses the x-axis.`, math: solveFactorMath(p), state: 0 },
      { id: "factor", narration: `Find two numbers that multiply to ${f(c)} and add to ${f(-b)}: ${f(m)} and ${f(n)}.`,
        math: [text("(x − "), num(m), text(")(x − "), num(n), text(")"), op("="), num(0)], state: 1, answerStep: "factor", result: m },
      { id: "roots", narration: `Set each factor to 0: x − ${f(m)} = 0 gives x = ${f(m)}, and x − ${f(n)} = 0 gives x = ${f(n)}.`,
        math: [text("x"), op("="), num(m), text(" or x"), op("="), num(n)], state: 2, answerStep: "roots", result: m },
    ],
  };
}
