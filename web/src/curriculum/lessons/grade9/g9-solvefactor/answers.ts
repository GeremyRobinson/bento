import { op, text } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { ms } from "../../_plane/kit";
import type { SolveFactorProblem } from "./problem";

export function solveFactorAnswers({ p, r }: SolveFactorProblem): AnswerModel {
  return {
    steps: [
      ms({ id: "factor", label: "Factor", prompt: S => [text("(x − "), ...S.m!, text(")(x − "), ...S.n!, text(")")], ans: { m: p, n: r }, anyOrder: true,
        hint: "Find two numbers that multiply to the number on its own and add to the x number, then write them in.",
        wrong: [[{ m: -p, n: -r }, "Flipped the signs", "(x − m)(x − n) multiplies out to x² − (m + n)x + mn: check the signs."]] }),
      ms({ id: "roots", label: "Solutions", prompt: S => [text("x"), op("="), ...S.m!, text(" or x"), op("="), ...S.n!], ans: { m: p, n: r }, anyOrder: true,
        hint: "If two numbers multiply to 0, one of them is 0. Set each factor to 0: x − m = 0 means x = m.", wrong: [[{ m: -p, n: -r }, "Flipped the signs", `x − ${p} = 0 means x = ${p}.`]] }),
    ],
    finalParts: [-1],
  };
}
