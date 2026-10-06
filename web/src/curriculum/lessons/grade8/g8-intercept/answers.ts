import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { ms, ns, P } from "../../_plane/kit";
import type { InterceptProblem } from "./problem";

export function interceptAnswers({ m, x0, y0, b }: InterceptProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "mx", label: "m times x", prompt: s => [...P(m), op("×"), ...P(x0), op("="), ...s], ans: m * x0, hint: "Multiply the slope by the point's x.",
        wrong: [[-m * x0, "Sign slip", `${m < 0 ? "Negative" : "Positive"} times ${x0 < 0 ? "negative" : "positive"} is ${m * x0 < 0 ? "negative" : "positive"}.`]] }),
      ns({ id: "b", label: "Find b", prompt: s => [text("b"), op("="), num(y0), op("−"), ...P(m * x0), op("="), ...s], ans: b, hint: "b = y − mx.",
        wrong: [[y0 + m * x0, "Added instead of subtracted", "b = y − mx: subtract."]] }),
      ms({ id: "line", label: "Write the line", prompt: S => [text("y"), op("="), ...S.m!, text("x"), op("+"), ...S.b!], ans: { m, b }, hint: "The slope goes in front of x, and the b you found is the number on its own.",
        wrong: [[{ m: b, b: m }, "Swapped m and b", "The slope goes with x. b is where the line crosses the y-axis."]] }),
    ],
    finalParts: [-1],
  };
}
