import { num, op, sup } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { ns } from "../../_plane/kit";
import type { GrowthProblem } from "./problem";
import { count } from "../../../text";

export const growWord = (r: number) => (r === 2 ? "double" : "triple");

export function growthAnswers({ P, r, t }: GrowthProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "factor", label: "Growth factor", prompt: s => [num(r), sup(t), op("="), ...s], ans: r ** t, hint: `Multiply ${count(t, "copy", "copies")} of ${r}.`,
        wrong: [[r * t, "Multiplied instead of using a power", `${r === 2 ? "Doubling" : "Tripling"} ${t} times means ${Array(t).fill(r).join(" × ")}.`]] }),
      ns({ id: "total", label: "Times the start", prompt: s => [num(P), op("×"), num(r ** t), op("="), ...s], ans: P * r ** t, hint: `Start with ${P}, and every one of them grows by the whole factor: multiply.`, wrong: [[P + r ** t, "Added", "Each one of the start grows by the factor: multiply."]] }),
    ],
    finalParts: [-1],
  };
}
