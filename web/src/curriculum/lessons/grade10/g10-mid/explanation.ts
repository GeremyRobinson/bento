import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import { expected, f, pt, ptM } from "../../_plane/kit";
import { halfSum, halfSumText } from "./answers";
import type { MidProblem } from "./problem";

export const midMath = ({ x1, y1, x2, y2 }: MidProblem) => [...ptM(x1, y1), text(" and "), ...ptM(x2, y2)];

export function explainMid(p: MidProblem, model: AnswerModel): Explanation {
  const { x1, y1, x2, y2 } = p;
  const mx = expected(model, "mx"), my = expected(model, "my");
  // which side of the segment is free for the midpoint's label
  const steepUp = (y2 - y1) * (x2 - x1) > 0;
  return {
    heading: "Average each coordinate",
    idea: ["The midpoint is halfway across and halfway up."],
    statement: midMath(p),
    caption: `Halfway in x is ${f(mx)} and halfway in y is ${f(my)}: the midpoint is ${pt(mx, my)}.`,
    diagram: buildPlane({
      alt: `Graph: the segment from ${pt(x1, y1)} to ${pt(x2, y2)} with its midpoint ${pt(mx, my)}.`,
      equal: true,
      items: [
        { kind: "segment", a: [x1, y1], b: [x2, y2] },
        { kind: "vline", x: mx, cls: "ln2 dash", from: 1, label: { text: `x = ${f(mx)}`, acc: true, optional: true }, labelY: Math.min(y1, y2) },
        { kind: "line", m: 0, b: my, cls: "ln2 dash", from: 2, label: { text: `y = ${f(my)}`, acc: true, optional: true } },
        { kind: "point", at: [x1, y1], label: { text: pt(x1, y1) } },
        { kind: "point", at: [x2, y2], label: { text: pt(x2, y2) } },
        { kind: "point", at: [mx, my], cls: "dota", from: 2, delay: 0.5, label: { text: pt(mx, my), acc: true, prefer: steepUp ? ["se", "nw", "e"] : ["ne", "sw", "e"] } },
      ],
    }),
    timeline: beats(3),
    steps: [
      { id: "points", narration: `The midpoint is halfway between ${pt(x1, y1)} and ${pt(x2, y2)}.`, math: midMath(p), state: 0 },
      { id: "mx", narration: `Halfway in x: ${halfSumText(x1, x2)} = ${f(mx)}.`, math: [...halfSum(x1, x2), op("="), num(mx)], state: 1, answerStep: "mx", result: mx },
      { id: "my", narration: `Halfway in y: ${halfSumText(y1, y2)} = ${f(my)}. The midpoint is ${pt(mx, my)}.`,
        math: [...halfSum(y1, y2), op("="), num(my)], state: 2, answerStep: "my", result: my },
    ],
  };
}
