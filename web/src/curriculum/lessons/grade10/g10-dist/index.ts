import { answer, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import { attempt, expected, f, ints, ns, pt, ptM } from "../../_plane/kit";
import { TRIPLES } from "../../_geometry/kit";
import { withEasyStart } from "../../easy-start";

/** Two points whose distance is whole: across and up are the legs of a Pythagorean triple. */
export interface DistProblem { kind: "coordinate.distance"; x1: number; y1: number; x2: number; y2: number; dx: number; dy: number; d: number }

export function createDist(x1: number, y1: number, x2: number, y2: number): DistProblem {
  const dx = x2 - x1, dy = y2 - y1, d = Math.hypot(dx, dy);
  if (dx <= 0 || dy <= 0 || !Number.isInteger(d)) throw new Error("across and up must be positive with a whole distance");
  return { kind: "coordinate.distance", x1, y1, x2, y2, dx, dy, d };
}

/** Same as the current app: a triple's legs (either way round) from a start point in 0..6. */
export function generateDist(rng: Rng): DistProblem {
  let [dx, dy] = rng.pick(TRIPLES);
  if (rng.next() < 0.5) [dx, dy] = [dy, dx];
  const x1 = rng.int(0, 6), y1 = rng.int(0, 6);
  return createDist(x1, y1, x1 + dx, y1 + dy);
}

export function restoreDist(raw: unknown): DistProblem | null {
  const v = ints(raw, ["x1", "y1", "x2", "y2"] as const);
  return v && attempt(() => createDist(v.x1, v.y1, v.x2, v.y2));
}

const sq = (v: number): MathText => [num(v), text("²")];

export function distAnswers({ x1, y1, x2, y2, dx, dy, d }: DistProblem): AnswerModel {
  const S = dx * dx + dy * dy;
  return {
    steps: [
      ns({ id: "dx", label: "Change in x", prompt: s => [num(x2), op("−"), num(x1), op("="), ...s], ans: dx,
        wrong: [[x2 + x1, "Added instead of subtracted", "Distance across is the **difference**: subtract."]],
        hint: `How far across: take the first x from the second, ${x2} − ${x1}.`, explain: `How far across: ${x2} − ${x1} = ${dx}.`, work: [text("Across: "), answer("x", dx)] }),
      ns({ id: "dy", label: "Change in y", prompt: s => [num(y2), op("−"), num(y1), op("="), ...s], ans: dy,
        wrong: [[y2 + y1, "Added instead of subtracted", "Distance up is the **difference**: subtract."]],
        hint: `How far up: take the first y from the second, ${y2} − ${y1}.`, explain: `How far up: ${y2} − ${y1} = ${dy}.`, work: [text("Up: "), answer("x", dy)] }),
      ns({ id: "sum", label: "Square and add", prompt: s => [...sq(dx), op("+"), ...sq(dy), op("="), ...s], ans: S,
        wrong: [[2 * dx + 2 * dy, "Squared as times 2", "Squared means a number times itself."], [dx + dy, "Forgot to square", "Square each one first."]],
        hint: "Across and up are the legs of a right triangle: square each, then add.", explain: `Square each leg and add: ${dx * dx} + ${dy * dy} = ${S}.`, work: [...sq(dx), op("+"), ...sq(dy), op("="), num(S)] }),
      ns({ id: "d", label: "Square root", prompt: s => [text("d"), op("="), text("√"), num(S), op("="), ...s], ans: d,
        wrong: [[dx + dy, "Added the sides", "The straight line is shorter than going across and up."]],
        hint: `What number times itself makes ${S}?`, explain: `${d} × ${d} = ${d * d}.`, work: [text("d"), op("="), answer("x", d)] }),
    ],
    finalParts: [-1],
  };
}

export const distMath = ({ x1, y1, x2, y2 }: DistProblem): MathText => [...ptM(x1, y1), text(" to "), ...ptM(x2, y2)];

export function explainDist(p: DistProblem, model: AnswerModel): Explanation {
  const { x1, y1, x2, y2 } = p;
  const dx = expected(model, "dx"), dy = expected(model, "dy"), S = expected(model, "sum"), d = expected(model, "d");
  return {
    heading: "It's a hidden right triangle",
    idea: ["Go across, then up. Those two moves are the legs of a right triangle, and the distance is its long side: square the legs, add, and take the square root."],
    statement: distMath(p),
    caption: `Legs ${f(dx)} and ${f(dy)}: the distance is ${f(d)}.`,
    diagram: buildPlane({
      alt: `Graph: the points ${pt(x1, y1)} and ${pt(x2, y2)}, ${f(dx)} across and ${f(dy)} up, ${f(d)} apart.`,
      equal: true,
      items: [
        { kind: "segment", a: [x1, y1], b: [x2, y1], cls: "ln p0 dash", from: 1, label: { text: f(dx), part: 0, prefer: ["s", "n"] } },
        { kind: "segment", a: [x2, y1], b: [x2, y2], cls: "ln p1 dash", from: 2, label: { text: f(dy), part: 1, prefer: ["e", "w"] } },
        { kind: "rightAngle", at: [x2, y1], u: [-1, 0], v: [0, 1], from: 2 },
        { kind: "segment", a: [x1, y1], b: [x2, y2], cls: "ln pq", from: 4, slow: true, label: { text: `d = ${f(d)}`, acc: true, prefer: ["nw", "w", "n"] } },
        { kind: "point", at: [x1, y1], label: { text: pt(x1, y1), prefer: ["w", "sw", "s"] } },
        { kind: "point", at: [x2, y2], label: { text: pt(x2, y2), prefer: ["n", "e", "ne"] } },
      ],
    }),
    timeline: beats(5),
    steps: [
      { id: "points", narration: `How far is it from ${pt(x1, y1)} to ${pt(x2, y2)} in a straight line?`, math: distMath(p), state: 0 },
      { id: "dx", narration: `Across: ${f(x2)} − ${f(x1)} = ${f(dx)}.`, math: [num(x2), op("−"), num(x1), op("="), num(dx)], state: 1, answerStep: "dx", result: dx },
      { id: "dy", narration: `Up: ${f(y2)} − ${f(y1)} = ${f(dy)}. Across and up make a right angle.`, math: [num(y2), op("−"), num(y1), op("="), num(dy)], state: 2, answerStep: "dy", result: dy },
      { id: "sum", narration: `Square both legs and add: ${f(dx * dx)} + ${f(dy * dy)} = ${f(S)}.`, math: [...sq(dx), op("+"), ...sq(dy), op("="), num(S)], state: 3, answerStep: "sum", result: S },
      { id: "d", narration: `The distance is the square root: √${f(S)} = ${f(d)}.`, math: [text("d"), op("="), text("√"), num(S), op("="), num(d)], state: 4, answerStep: "d", result: d },
    ],
  };
}

export const lesson: LessonDefinition<DistProblem> = withEasyStart({
  id: "g10-dist",
  grade: 10,
  unit: "Coordinate geometry",
  title: "Distance between points",
  pre: "g8-pyth",
  reference: createDist(1, 2, 4, 6),
  generate: rng => generateDist(rng),
  restore: restoreDist,
  display: distMath,
  displayNote: () => "How far apart are the two points?",
  answers: distAnswers,
  explain: explainDist,
});
