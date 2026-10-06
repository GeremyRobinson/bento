import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { ns, P } from "../../_plane/kit";
import type { SlopeProblem } from "./problem";

const round6 = (x: number) => Math.round(x * 1e6) / 1e6;

export function slopeAnswers({ x1, y1, x2, y2, m }: SlopeProblem): AnswerModel {
  const rise = y2 - y1, run = x2 - x1;
  return {
    steps: [
      ns({ id: "rise", label: "Rise", prompt: s => [num(y2), op("−"), ...P(y1), op("="), ...s], ans: rise, hint: "Subtract the y values.",
        wrong: [[y1 - y2, "Subtracted in the wrong order", "Keep the same order for both: second point minus first."]] }),
      ns({ id: "run", label: "Run", prompt: s => [num(x2), op("−"), ...P(x1), op("="), ...s], ans: run, hint: "Subtract the x values in the same order as the y values, so rise and run match.", wrong: [[-run, "Subtracted the other way", "Take the x values in the same order you took the y values: second minus first."]] }),
      ns({ id: "slope", label: "Slope", prompt: s => [text("m"), op("="), num(rise), op("÷"), num(run), op("="), ...s], ans: m, hint: "Rise over run.",
        wrong: [[round6(run / rise), "Flipped rise and run", "Slope is rise ÷ run: the y change goes on top."]] }),
    ],
    finalParts: [-1],
  };
}
