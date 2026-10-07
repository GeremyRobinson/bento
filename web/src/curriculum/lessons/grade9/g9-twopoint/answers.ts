import { frac, num, op, text } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { ms, ns, P } from "../../_plane/kit";
import type { TwoPointProblem } from "./problem";

const round6 = (x: number) => Math.round(x * 1e6) / 1e6;

export function twoPointAnswers({ m, b, x1, x2, y1, y2 }: TwoPointProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "m", label: "Slope", prompt: s => [text("m"), op("="), frac([num(y2), op("−"), ...P(y1)], [num(x2), op("−"), ...P(x1)]), op("="), ...s],
        ans: m, hint: "Rise over run.", wrong: [[round6((x2 - x1) / (y2 - y1)), "Flipped rise and run", "The y change goes on top."]] }),
      ns({ id: "b", label: "Find b", prompt: s => [text("b"), op("="), num(y1), op("−"), ...P(m), op("×"), ...P(x1), op("="), ...s], ans: b, hint: "The first point is on the line, so its y = m × its x + b. Take m × x off its y.",
        wrong: [[y1 + m * x1, "Added instead of subtracted", "b = y − mx: subtract m × x."]] }),
      ms({ id: "line", label: "Write the line", prompt: S => [text("y"), op("="), ...S.m!, text("x"), op("+"), ...S.b!], ans: { m, b }, hint: "The slope you found goes in front of x, and b is the number on its own.",
        wrong: [[{ m: b, b: m }, "Swapped m and b", "The slope goes with x. b is where the line crosses the y-axis."]] }),
    ],
    finalParts: [-1],
  };
}
