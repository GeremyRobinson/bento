import { frac, num, op, sqrt, text } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import { expected, f, fP, parabolaFit, poly, polyText } from "../../_plane/kit";
import { discriminantMath } from "./answers";
import type { QuadFormProblem } from "./problem";

export const quadFormMath = ({ b, c }: QuadFormProblem) => [...poly([[1, "x²"], [b, "x"], [c, ""]]), op("="), num(0)];

export function explainQuadForm(p: QuadFormProblem, model: AnswerModel): Explanation {
  const { b, c } = p;
  const D = expected(model, "D"), s = expected(model, "root");
  const h = -b / 2, hi = (-b + s) / 2, lo = (-b - s) / 2;
  const F = (x: number) => x * x + b * x + c;
  const eq = polyText([[1, "x²"], [b, "x"], [c, ""]]);
  return {
    heading: "Discriminant first",
    idea: ["x = (−b ± √(b² − 4ac)) ÷ 2a. Work out b² − 4ac first; its square root says how far apart the two answers are."],
    statement: quadFormMath(p),
    caption: `The two answers sit √${D} = ${f(s)} apart, centred on x = ${f(h)}: x = ${f(lo)} and x = ${f(hi)}.`,
    diagram: buildPlane({
      alt: `Graph of y = ${eq}, crossing the x-axis at ${f(lo)} and ${f(hi)}, which are ${f(s)} apart around x = ${f(h)}.`,
      fit: parabolaFit(1, b, c, [lo, hi]),
      items: [
        { kind: "curve", f: F, label: { text: `y = ${eq}`, optional: true } },
        { kind: "vline", x: h, cls: "ln thin dash", from: 1, label: { text: `x = ${f(h)}`, optional: true } },
        { kind: "segment", a: [lo, 0], b: [hi, 0], cls: "ln2", from: 2, label: { text: `${f(s)} apart`, acc: true, prefer: ["ne", "nw", "se", "sw"] } },
        { kind: "point", at: [lo, 0], cls: "dota", from: 3, label: { text: f(lo), acc: true, prefer: ["sw", "nw", "w"] } },
        { kind: "point", at: [hi, 0], cls: "dota", from: 3, delay: 0.3, label: { text: f(hi), acc: true, prefer: ["se", "ne", "e"] } },
      ],
    }),
    timeline: beats(4),
    steps: [
      { id: "eq", narration: `Here a = 1, b = ${f(b)} and c = ${f(c)}. The answers are where the graph crosses 0.`, math: quadFormMath(p), state: 0 },
      { id: "D", narration: `Discriminant: b² − 4ac = ${b * b} − ${fP(4 * c)} = ${f(D)}. It is positive, so there are two answers.`,
        math: [...discriminantMath(p), op("="), num(D)], state: 1, answerStep: "D", result: D },
      { id: "root", narration: `√${D} = ${f(s)}. The two answers are ${f(s)} apart, one on each side of x = −b ÷ 2 = ${f(h)}.`,
        math: [sqrt(D), op("="), num(s)], state: 2, answerStep: "root", result: s },
      { id: "roots", narration: `(${f(-b)} + ${f(s)}) ÷ 2 = ${f(hi)} and (${f(-b)} − ${f(s)}) ÷ 2 = ${f(lo)}.`,
        math: [text("x"), op("="), frac([num(-b), op("±"), num(s)], [num(2)]), op("="), num(hi), text(" or "), num(lo)], state: 3, answerStep: "roots", result: p.r1 },
    ],
  };
}
