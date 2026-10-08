import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import { expected, f, fP, lineText, P, pt, ptM } from "../../_plane/kit";
import type { TwoPointProblem } from "./problem";

export const twoPointMath = ({ x1, y1, x2, y2 }: TwoPointProblem) => [...ptM(x1, y1), text(" and "), ...ptM(x2, y2)];

export function explainTwoPoint(p: TwoPointProblem, model: AnswerModel): Explanation {
  const { x1, y1, x2, y2 } = p;
  const m = expected(model, "m"), b = expected(model, "b");
  const rise = y2 - y1, run = x2 - x1, up = rise > 0, line = lineText(m, b);
  return {
    heading: "Slope first, then b",
    idea: ["Two points fix a line, so they give both its slope and where it crosses."],
    statement: twoPointMath(p),
    caption: `Rise ${f(rise)} over run ${f(run)} gives m = ${f(m)}; the line crosses the y-axis at b = ${f(b)}.`,
    diagram: buildPlane({
      alt: `Graph: the line ${line} through ${pt(x1, y1)} and ${pt(x2, y2)}, crossing the y-axis at ${f(b)}.`,
      fit: [[x1, y1], [x2, y2], [0, b]],
      items: [
        { kind: "line", m, b, from: 3, label: { text: line }, labelX: x2 + 0.8 },
        { kind: "segment", a: [x1, y1], b: [x2, y1], cls: "ln p0 dash", from: 1, label: { text: `run ${f(run)}`, part: 0, prefer: up ? ["s", "n"] : ["n", "s"] } },
        { kind: "segment", a: [x2, y1], b: [x2, y2], cls: "ln p1 dash", from: 1, delay: 0.4, label: { text: `rise ${f(rise)}`, part: 1, prefer: ["e", "w"] } },
        { kind: "point", at: [0, b], cls: "dota", from: 2, label: { text: `b = ${f(b)}`, acc: true, prefer: m > 0 ? ["nw", "w", "se"] : ["sw", "w", "ne"] } },
        { kind: "point", at: [x1, y1], label: { text: pt(x1, y1), prefer: up ? ["nw", "w", "n"] : ["sw", "w", "s"] } },
        { kind: "point", at: [x2, y2], label: { text: pt(x2, y2), prefer: up ? ["nw", "n", "w"] : ["sw", "s", "w"] } },
      ],
    }),
    timeline: beats(4),
    steps: [
      { id: "points", narration: `Plot ${pt(x1, y1)} and ${pt(x2, y2)}. One line goes through both.`, math: twoPointMath(p), state: 0 },
      { id: "m", narration: `Rise over run: (${f(y2)} − ${fP(y1)}) ÷ (${f(x2)} − ${fP(x1)}) = ${f(rise)} ÷ ${f(run)} = ${f(m)}.`,
        math: [text("m"), op("="), num(rise), op("÷"), num(run), op("="), num(m)], state: 1, answerStep: "m", result: m },
      { id: "b", narration: `Use the first point: b = y − mx = ${f(y1)} − ${fP(m)} × ${fP(x1)} = ${f(b)}. That is where the line crosses the y-axis.`,
        math: [text("b"), op("="), num(y1), op("−"), ...P(m), op("×"), ...P(x1), op("="), num(b)], state: 2, answerStep: "b", result: b },
      { id: "line", narration: `Put them together: ${line}.`, math: [text(line)], state: 3, answerStep: "line", result: m },
    ],
  };
}
