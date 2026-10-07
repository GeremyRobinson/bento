import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import { expected, f, pt, ptM } from "../../_plane/kit";
import type { TranslateProblem } from "./problem";

export const moveWords = ({ dx, dy }: { dx: number; dy: number }) =>
  [`${f(Math.abs(dx))} ${dx > 0 ? "right" : "left"}`, `${f(Math.abs(dy))} ${dy > 0 ? "up" : "down"}`] as const;

export function explainTranslate(p: TranslateProblem, model: AnswerModel): Explanation {
  const { x, y, dx, dy } = p;
  const nx = expected(model, "x"), ny = expected(model, "y");
  const [across, upDown] = moveWords(p);
  return {
    heading: "Slide the point",
    idea: ["A translation slides a point without turning it."],
    statement: [...ptM(x, y), text(`: ${across} and ${upDown}`)],
    caption: `Slide ${across}, then ${upDown}: ${pt(x, y)} lands on ${pt(nx, ny)}.`,
    diagram: buildPlane({
      alt: `Graph: the point ${pt(x, y)} slides ${across} and ${upDown} to ${pt(nx, ny)}.`,
      equal: true,
      items: [
        { kind: "segment", a: [x, y], b: [nx, y], cls: "ln2", arrow: true, from: 1, label: { text: across, acc: true, prefer: dy < 0 ? ["n", "s"] : ["s", "n"] } },
        { kind: "point", at: [nx, y], cls: "dota", small: true, from: 1, until: 1, delay: 0.7 },
        { kind: "segment", a: [nx, y], b: [nx, ny], cls: "ln2", arrow: true, from: 2, label: { text: upDown, acc: true, prefer: dx > 0 ? ["e", "w"] : ["w", "e"] } },
        { kind: "point", at: [x, y], label: { text: pt(x, y), prefer: dx > 0 ? ["w", "nw", "sw"] : ["e", "ne", "se"] } },
        { kind: "point", at: [nx, ny], cls: "dota", from: 2, delay: 0.8, label: { text: pt(nx, ny), acc: true, prefer: dy > 0 ? ["n", "ne", "nw"] : ["s", "se", "sw"] } },
      ],
    }),
    timeline: beats(3),
    steps: [
      { id: "start", narration: `Start at ${pt(x, y)}.`, math: ptM(x, y), state: 0 },
      { id: "x", narration: `${dx > 0 ? "Right adds to x" : "Left subtracts from x"}: slide ${across}, so x becomes ${f(nx)}.`,
        math: [num(x), op(dx > 0 ? "+" : "−"), num(Math.abs(dx)), op("="), num(nx)], state: 1, answerStep: "x", result: nx },
      { id: "y", narration: `${dy > 0 ? "Up adds to y" : "Down subtracts from y"}: slide ${upDown}, so y becomes ${f(ny)}. The new point is ${pt(nx, ny)}.`,
        math: [num(y), op(dy > 0 ? "+" : "−"), num(Math.abs(dy)), op("="), num(ny)], state: 2, answerStep: "y", result: ny },
    ],
  };
}
