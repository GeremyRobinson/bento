import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { ms, ns, P } from "../../_plane/kit";
import type { TangentProblem } from "./problem";

export function tangentAnswers({ a, b, k }: TangentProblem): AnswerModel {
  return {
    steps: [
      ms({ id: "derivative", label: "Derivative", prompt: S => [text("f′(x)"), op("="), ...S.p!, text("x"), op("+"), ...S.r!], ans: { p: 2 * a, r: b },
        hint: "Power rule on each term: x²'s exponent comes down and multiplies its number, the x term keeps its number, and the constant drops out.",
        wrong: [[{ p: a, r: b }, "Didn't bring the 2 down", "The 2 in x² comes down and multiplies the number in front."]] }),
      ns({ id: "slope", label: "Plug in", prompt: s => [num(2 * a), op("·"), ...P(k), op("+"), ...P(b), op("="), ...s], ans: 2 * a * k + b,
        hint: "The slope of the tangent line is f′ at that point.", wrong: [[a * k * k + b * k, "Used f instead of f′", "Slope comes from the derivative, not f itself."]] }),
    ],
    finalParts: [-1],
  };
}
