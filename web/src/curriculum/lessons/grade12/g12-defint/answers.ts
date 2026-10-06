import { num, op, sup, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { ms, ns } from "../../_plane/kit";
import type { DefIntProblem } from "./problem";

/** c·k^(n+1) − c·j^(n+1) */
export const topMinusBottom = ({ c, j, k, n }: DefIntProblem): MathText =>
  [num(c), op("·"), num(k), sup(n + 1), op("−"), num(c), op("·"), num(j), sup(n + 1)];

export function defIntAnswers(p: DefIntProblem): AnswerModel {
  const { n, a, j, k, c } = p;
  return {
    steps: [
      ms({ id: "anti", label: "Antiderivative", prompt: S => [...S.c!, text("x"), sup(S.e!)], ans: { c, e: n + 1 }, small: ["e"], hint: `Raise ${n} to ${n + 1}, then ${a} ÷ ${n + 1}.`,
        wrong: [
          [{ c: a, e: n + 1 }, "Didn't divide", `Divide by the new power: ${a} ÷ ${n + 1}.`],
          [{ c: a * n, e: n - 1 }, "Took the derivative", "That's the derivative. Antiderivatives raise the power by 1."],
          [{ c, e: n - 1 }, "Lowered the power", "That's the derivative's power. Antiderivatives raise the power by 1."],
        ] }),
      ns({ id: "area", label: "Top minus bottom", prompt: s => [...topMinusBottom(p), op("="), ...s], ans: p.area,
        hint: j === 0 ? `Plug in ${k}, then subtract the value at 0 (which is 0).` : `Plug in ${k}, then subtract the value at ${j}: the area from 0 to ${j} isn't part of it.`,
        wrong: j === 0 ? [] : [[c * k ** (n + 1), "Forgot the bottom", `That is the area from 0 to ${k}. Take away F(${j}) = ${c * j ** (n + 1)}, the part from 0 to ${j}.`]] }),
    ],
    finalParts: [-1],
  };
}
