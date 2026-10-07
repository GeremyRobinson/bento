import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import { call, expected, f, fP, P, poly, polyText, pt } from "../../_plane/kit";
import type { FuncProblem } from "./problem";
import { coef } from "../../../text";

export const funcMath = ({ a, b }: FuncProblem) => [text("f(x)"), op("="), ...poly([[a, "x"], [b, ""]])];

export function explainFunc(p: FuncProblem, model: AnswerModel): Explanation {
  const { a, b, x } = p;
  const ax = expected(model, "ax"), v = expected(model, "value");
  const fx = polyText([[a, "x"], [b, ""]]);
  const up = b > 0;
  return {
    heading: "Plug in x",
    idea: ["f(x) is a rule, so any number can go in for x."],
    statement: [...funcMath(p), text(", find "), ...call("f", x)],
    caption: `Above x = ${f(x)}, ${coef(a, "x")} reaches ${f(ax)}; the ${up ? "+" : "−"} ${f(Math.abs(b))} moves it to f(${f(x)}) = ${f(v)}.`,
    diagram: buildPlane({
      alt: `Graph of f(x) = ${fx}. At x = ${f(x)}, ${coef(a, "x")} is ${f(ax)} and f(${f(x)}) is ${f(v)}.`,
      fit: [[x, 0], [x, ax], [x, v], [x - 2, 0], [x + 2, 0]],
      items: [
        { kind: "line", m: a, b: 0, cls: "ln thin", from: 1, label: { text: `y = ${polyText([[a, "x"]])}`, optional: true } },
        { kind: "line", m: a, b, label: { text: `f(x) = ${fx}` } },
        { kind: "segment", a: [x, 0], b: [x, ax], cls: "ln thin dash", from: 1 },
        { kind: "point", at: [x, 0], small: true, label: { text: `x = ${f(x)}`, prefer: ax > 0 ? ["s", "se", "sw"] : ["n", "ne", "nw"] } },
        { kind: "point", at: [x, ax], from: 1, label: { text: `${f(a)} × ${fP(x)} = ${f(ax)}`, prefer: up ? ["s", "e", "w", "se", "sw"] : ["n", "e", "w", "ne", "nw"] } },
        { kind: "segment", a: [x, ax], b: [x, v], cls: "ln2", arrow: true, from: 2, label: { text: `${up ? "+" : "−"} ${f(Math.abs(b))}`, acc: true, prefer: ["e", "w"] } },
        { kind: "point", at: [x, v], cls: "dota", from: 2, delay: 0.7, label: { text: `f(${f(x)}) = ${f(v)}`, acc: true, prefer: up ? ["n", "ne", "nw", "e", "w"] : ["s", "se", "sw", "e", "w"] } },
      ],
    }),
    timeline: beats(3),
    steps: [
      { id: "rule", narration: `The rule is f(x) = ${fx}. Find its value at x = ${f(x)}.`, math: funcMath(p), state: 0 },
      { id: "ax", narration: `Put ${f(x)} in for x: ${f(a)} × ${fP(x)} = ${f(ax)}.`, math: [...P(a), op("×"), ...P(x), op("="), num(ax)], state: 1, answerStep: "ax", result: ax },
      { id: "value", narration: `Add the constant: ${f(ax)} + ${fP(b)} = ${f(v)}. The point ${pt(x, v)} is on the graph.`,
        math: [...call("f", x), op("="), num(ax), op("+"), ...P(b), op("="), num(v)], state: 2, answerStep: "value", result: v },
    ],
  };
}
