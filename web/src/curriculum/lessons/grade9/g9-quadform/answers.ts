import { num, op, sqrt, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { f, ms, ns, P } from "../../_plane/kit";
import type { QuadFormProblem } from "./problem";

/** b² − 4ac = 3² − 4(1)(2) */
export const discriminantMath = (p: QuadFormProblem): MathText => [text("b² − 4ac"), op("="), ...discriminantSum(p)];
/** 3² − 4(1)(2), the prompt's short form */
const discriminantSum = ({ b, c }: QuadFormProblem): MathText => [...P(b), text("²"), op("−"), text("4(1)("), num(c), text(")")];

export function quadFormAnswers(p: QuadFormProblem): AnswerModel {
  const { r1, r2, b, c, D } = p, s = Math.sqrt(D);
  return {
    steps: [
      ns({ id: "D", label: "Discriminant", prompt: x => [...discriminantSum(p), op("="), ...x], ans: D, hint: `b² − 4ac: square b, then take away 4 × a × c, with c = ${f(c)}.`,
        wrong: [[b * b + 4 * c, "Sign slip", `Careful: − 4ac with c = ${f(c)}.`]] }),
      ns({ id: "root", label: "Square root", prompt: x => [sqrt(D), op("="), ...x], ans: s, hint: `What number times itself is ${D}?`, wrong: [[D / 2, "Halved it", `The root is the number that times itself makes ${D}.`]] }),
      ms({ id: "roots", label: "Both answers", prompt: S => [text("x"), op("="), ...S.m!, text(" or x"), op("="), ...S.n!], ans: { m: r1, n: r2 }, anyOrder: true,
        hint: "x = (−b ± the root) ÷ 2a: −b plus the root, and −b minus the root, each divided by 2a.",
        wrong: [[{ m: -r1, n: -r2 }, "Used +b", "The formula starts with −b, the opposite of b."], [{ m: 2 * r1, n: 2 * r2 }, "Didn't divide by 2a", "Divide both by 2a, which is 2 here."]] }),
    ],
    finalParts: [-1],
  };
}
