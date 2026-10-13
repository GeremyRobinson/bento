import { num, op, sub, sup, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import { expected, f, supText } from "../../_plane/kit";
import { topMinusBottom } from "./answers";
import type { DefIntProblem } from "./problem";

/** a·xⁿ, with x¹ written as plain x */
export const powerTerm = (a: number, n: number): MathText => [num(a), text("x"), ...(n === 1 ? [] : [sup(n)])];
export const powerText = (a: number, n: number) => `${f(a)}x${n === 1 ? "" : supText(n)}`;
/** the antiderivative as a learner would write it: 1x⁴ is just x⁴ */
const antiTerm = (c: number, n: number): MathText => (c === 1 ? [text("x"), ...(n === 1 ? [] : [sup(n)])] : powerTerm(c, n));

export function explainDefInt(p: DefIntProblem, model: AnswerModel): Explanation {
  const { n, a, j, k } = p;
  const c = expected(model, "anti", "c"), area = expected(model, "area");
  const F = (x: number) => a * x ** n;
  return {
    heading: "F(top) − F(bottom)",
    idea: ["F(top) is all the area up to the top, so F(bottom) takes off the part before the start."],
    statement: [text("∫"), sub(j), sup(k), text(" "), ...powerTerm(a, n), text(" dx")],
    caption: `The shaded area under y = ${powerText(a, n)} from ${f(j)} to ${f(k)} is ${f(area)}.`,
    diagram: buildPlane({
      alt: `Graph of y = ${powerText(a, n)} with the area from x = ${f(j)} to x = ${f(k)} shaded; it is ${f(area)}.`,
      fit: [[k, F(k)]],
      items: [
        { kind: "area", f: F, a: j, b: k, from: 2, label: { text: f(area), acc: true } },
        { kind: "curve", f: F, label: { text: `y = ${powerText(a, n)}`, optional: true } },
        { kind: "segment", a: [k, 0], b: [k, F(k)], cls: "ln2 dash", from: 1, label: { text: `x = ${f(k)}`, acc: true, prefer: ["e", "w"] } },
        ...(j ? [{ kind: "segment" as const, a: [j, 0] as [number, number], b: [j, F(j)] as [number, number], cls: "ln2 dash", from: 1, label: { text: `x = ${f(j)}`, acc: true, prefer: ["w", "e"] as ("w" | "e")[] } }] : []),
      ],
    }),
    timeline: beats(3),
    steps: [
      { id: "curve", narration: `It is the area under y = ${powerText(a, n)} from x = ${f(j)} to ${f(k)}.`,
        math: [text("∫"), sub(j), sup(k), text(" "), ...powerTerm(a, n), text(" dx")], state: 0 },
      { id: "anti", narration: "Run the power rule backwards: raise the power, then divide by it.",
        math: [text("F(x)"), op("="), ...antiTerm(c, n + 1)], state: 1, answerStep: "anti", result: c },
      { id: "area", narration: j === 0 ? `F(${f(k)}) is the area from 0 up to ${f(k)}, and F(0) is 0.`
          : `F(${f(k)}) − F(${f(j)}): take away the area from 0 to ${f(j)}.`,
        math: [...topMinusBottom(p), op("="), num(area)], state: 2, answerStep: "area", result: area },
    ],
  };
}
