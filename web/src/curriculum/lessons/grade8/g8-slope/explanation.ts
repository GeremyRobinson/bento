import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import { expected, f, P, pt, ptM } from "../../_plane/kit";
import type { SlopeProblem } from "./problem";

export function explainSlope(p: SlopeProblem, model: AnswerModel): Explanation {
  const { x1, y1, x2, y2 } = p;
  const rise = expected(model, "rise"), run = expected(model, "run"), m = expected(model, "slope");
  const up = rise > 0;
  const statement = [...ptM(x1, y1), text(" and "), ...ptM(x2, y2)];
  return {
    heading: "Rise over run",
    idea: ["Slope is how far a line goes up for each step across."],
    statement,
    caption: `Rise ${f(rise)} over run ${f(run)}: slope ${f(m)}.`,
    diagram: buildPlane({
      alt: `Graph: the points ${pt(x1, y1)} and ${pt(x2, y2)}, a rise of ${f(rise)} and a run of ${f(run)}, slope ${f(m)}.`,
      items: [
        { kind: "line", m, b: y1 - m * x1, cls: "ln thin", from: 3, label: { text: `slope ${f(m)}`, acc: true }, labelX: x2 + run * 0.6 },
        { kind: "segment", a: [x1, y1], b: [x2, y2] },
        { kind: "segment", a: [x2, y1], b: [x2, y2], cls: "ln p1 dash", from: 1, label: { text: `rise ${f(rise)}`, part: 1, prefer: ["e", "w"] } },
        { kind: "segment", a: [x1, y1], b: [x2, y1], cls: "ln p0 dash", from: 2, label: { text: `run ${f(run)}`, part: 0, prefer: up ? ["s", "n"] : ["n", "s"] } },
        { kind: "point", at: [x1, y1], label: { text: pt(x1, y1), prefer: up ? ["w", "nw", "sw", "s"] : ["w", "sw", "nw", "n"], clearAxes: true } },
        { kind: "point", at: [x2, y2], label: { text: pt(x2, y2), prefer: up ? ["n", "nw", "w"] : ["s", "sw", "w"], clearAxes: true } },
      ],
    }),
    timeline: beats(4),
    steps: [
      { id: "plot", narration: `Plot the two points. The second one is ${pt(x2, y2)}.`, math: statement, state: 0 },
      { id: "rise", narration: `From the first point to the second, y goes ${up ? "up" : "down"} ${f(Math.abs(rise))}: the rise is ${f(rise)}.`,
        math: [num(y2), op("−"), ...P(y1), op("="), num(rise)], state: 1, answerStep: "rise", result: rise },
      { id: "run", narration: `In the same order, x goes across ${f(run)}: the run is ${f(run)}.`,
        math: [num(x2), op("−"), ...P(x1), op("="), num(run)], state: 2, answerStep: "run", result: run },
      { id: "slope", narration: `Rise over run: ${f(rise)} ÷ ${f(run)} = ${f(m)}. The line goes ${up ? "up" : "down"} ${f(Math.abs(m))} for every 1 across.`,
        math: [text("m"), op("="), num(rise), op("÷"), num(run), op("="), num(m)], state: 3, answerStep: "slope", result: m },
    ],
  };
}
