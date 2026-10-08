import { frac, num, op, text } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import { expected, fracText } from "../../_plane/kit";
import { sizeOf, slopeMath } from "./answers";
import type { PerpProblem } from "./problem";

export function explainPerp(q: PerpProblem, model: AnswerModel): Explanation {
  const { p, r } = q, ap = Math.abs(p);
  const fn = expected(model, "flip", "n"), fd = expected(model, "flip", "d");
  const pn = expected(model, "perp", "n"), pd = expected(model, "perp", "d");
  const m1 = fracText(p, r), m2 = fracText(pn, pd), L = Math.max(r, ap) + 1;
  const rotated = p > 0 ? "left" : "right";
  return {
    heading: "Flip and change the sign",
    idea: ["A quarter turn swaps rise and run and changes a sign, so the slopes multiply to −1."],
    statement: [text("m"), op("="), ...slopeMath(q)],
    caption: `Turn the slope triangle a quarter turn: ${r} right and ${ap} ${p > 0 ? "up" : "down"} becomes ${r} up and ${ap} ${rotated}. Slope ${m1} becomes ${m2}.`,
    diagram: buildPlane({
      alt: `Graph: the line with slope ${m1} and the perpendicular line with slope ${m2}, meeting at a right angle at the origin.`,
      equal: true,
      fit: [[-L, -L], [L, L]],
      items: [
        { kind: "line", m: p / r, b: 0, label: { text: `m = ${m1}` }, labelX: L * 0.8 },
        { kind: "segment", a: [0, 0], b: [r, 0], cls: "ln thin dash", label: { text: `${r} right`, prefer: p > 0 ? ["s", "n"] : ["n", "s"], optional: true } },
        { kind: "segment", a: [r, 0], b: [r, p], cls: "ln thin dash", label: { text: `${ap} ${p > 0 ? "up" : "down"}`, prefer: ["e", "w"], optional: true } },
        { kind: "segment", a: [0, 0], b: [0, r], cls: "ln2 dash", from: 1, label: { text: `${r} up`, acc: true, prefer: p > 0 ? ["e", "w"] : ["w", "e"], optional: true } },
        { kind: "segment", a: [0, r], b: [-p, r], cls: "ln2 dash", from: 1, delay: 0.4, label: { text: `${ap} ${rotated}`, acc: true, prefer: ["n", "s"], optional: true } },
        { kind: "line", m: -r / p, b: 0, cls: "ln2", from: 2, label: { text: `m = ${m2}`, acc: true }, labelX: (p > 0 ? -1 : 1) * L * 0.55 },
        { kind: "rightAngle", at: [0, 0], u: [r, p], v: [-p, r], from: 2 },
      ],
    }),
    timeline: beats(3),
    steps: [
      { id: "slope", narration: `Slope ${m1}: ${r} across and ${ap} ${p > 0 ? "up" : "down"}.`, math: [text("m"), op("="), ...slopeMath(q)], state: 0 },
      { id: "flip", narration: `Flip it: ${ap} and ${r} swap places, giving ${fracText(fn, fd)}.`,
        math: [text("flip "), ...sizeOf(q), op("→"), ...(fd === 1 ? [num(fn)] : [frac(fn, fd)])], state: 1, answerStep: "flip", result: fn },
      { id: "perp", narration: `Change the sign: ${m1} becomes ${m2}. Check: ${m1} × ${m2} = −1.`,
        math: [text("perpendicular slope"), op("="), ...(pd === 1 ? [num(pn)] : [frac(pn, pd)])], state: 2, answerStep: "perp", result: pn },
    ],
  };
}
