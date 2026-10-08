import { num, op, sup } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane, tickText } from "../../../../explanations/diagrams/plane/build";
import type { PlaneItem } from "../../../../explanations/diagrams/plane/schema";
import { expected, supText } from "../../_plane/kit";
import { growWord } from "./answers";
import type { GrowthProblem } from "./problem";
import { count } from "../../../text";

export function explainGrowth(p: GrowthProblem, model: AnswerModel): Explanation {
  const { P, r, t } = p;
  const factor = expected(model, "factor"), total = expected(model, "total");
  const hours = Array.from({ length: t + 1 }, (_, h) => h);
  const n = tickText;
  return {
    heading: "Multiply again and again",
    idea: ["Growing by the same factor again and again is a power."],
    statement: [num(P), op("×"), num(r), sup(t)],
    caption: `${growWord(r) === "double" ? "Doubling" : "Tripling"}: ${hours.map(h => n(P * r ** h)).join(", ")}.`,
    diagram: buildPlane({
      alt: `Graph of the count each hour: ${hours.map(h => n(P * r ** h)).join(", ")}.`,
      fit: [[t, total], [t + 0.3, 0]],
      items: [
        { kind: "curve", f: x => P * r ** x, x0: 0, x1: t, cls: "ln thin dash", from: 1 },
        // the start sits on the y-axis just above the x-axis, so its label is placed first and goes above-right,
        // clear of both axes (Review v43 #20); the hour labels then take what room is left
        { kind: "point", at: [0, P], label: { text: n(P), prefer: ["nw", "w"], clearAxes: true } },
        ...hours.slice(1, -1).map((h): PlaneItem => ({ kind: "point", at: [h, P * r ** h], from: 1, delay: 0.3 * h, small: true,
          label: { text: n(P * r ** h), optional: true, prefer: ["nw", "w", "n"] } })),
        { kind: "point", at: [t, total], cls: "dota", from: 2, label: { text: n(total), acc: true, prefer: ["w", "nw", "sw"] } },
        { kind: "label", at: [t, 0], from: 1, label: { text: `${count(t, "hour")}`, optional: true, prefer: ["n", "nw"] } },
      ],
    }),
    timeline: beats(3),
    steps: [
      { id: "start", narration: `Start with ${n(P)} bacteria. Every hour they ${growWord(r)}: × ${r}.`, math: [num(P)], state: 0 },
      { id: "factor", narration: `${count(t, "hour")} means × ${r}, ${t} times: ${Array(t).fill(r).join(" × ")} = ${r}${supText(t)} = ${n(factor)}.`,
        math: [num(r), sup(t), op("="), num(factor)], state: 1, answerStep: "factor", result: factor },
      { id: "total", narration: `Multiply the start by the growth factor: ${n(P)} × ${n(factor)} = ${n(total)} bacteria after ${count(t, "hour")}.`,
        math: [num(P), op("×"), num(factor), op("="), num(total)], state: 2, answerStep: "total", result: total },
    ],
  };
}

export const growthDisplay = ({ P, r, t }: GrowthProblem) => [num(P), op("×"), num(r), sup(t)];
export const growthNote = ({ P, r, t }: GrowthProblem) => `${P} bacteria ${growWord(r)} every hour. How many after ${count(t, "hour")}?`;
