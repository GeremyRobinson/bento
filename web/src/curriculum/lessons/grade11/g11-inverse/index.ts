import { num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import { attempt, expected, f, fP, ints, ns, nz, P, poly, polyText, pt } from "../../_plane/kit";
import { withEasyStart } from "../../easy-start";

/** f(x) = a·x + b; find f⁻¹(a·x + b), which is x. */
export interface InverseProblem { kind: "function.inverse"; a: number; b: number; x: number; y: number }

const AS = [2, 3, 4, 5, -2, -3];
export function createInverse(a: number, b: number, x: number): InverseProblem {
  if (!AS.includes(a) || b === 0) throw new Error("a from the list, b not 0");
  return { kind: "function.inverse", a, b, x, y: a * x + b };
}

/** Same as the current app: a from 2..5, −2, −3; b −9..9 not 0; x −6..9. */
export const generateInverse = (rng: Rng) => createInverse(rng.pick(AS), nz(rng, -9, 9), rng.int(-6, 9));

export function restoreInverse(raw: unknown): InverseProblem | null {
  const v = ints(raw, ["a", "b", "x"] as const);
  return v && attempt(() => createInverse(v.a, v.b, v.x));
}

export const inverseMath = ({ a, b }: InverseProblem): MathText => [text("f(x) = "), ...poly([[a, "x"], [b, ""]])];

export function inverseAnswers({ a, b, x, y }: InverseProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "sub", label: "Undo the adding", prompt: s => [num(y), op("−"), ...P(b), op("="), ...s], ans: a * x,
        hint: "The inverse undoes f in reverse order: subtract first.", wrong: [[a * x + 2 * b, "Added instead", "Undo + with −."]] }),
      ns({ id: "x", label: "Undo the multiplying", prompt: s => [num(a * x), op("÷"), ...P(a), op("="), ...s], ans: x, hint: "f multiplied first, so the inverse undoes that last: divide.", wrong: [[a * x * a, "Multiplied again", `f multiplied by ${f(a)}; the inverse divides by ${f(a)}.`]] }),
    ],
    finalParts: [-1],
  };
}

export function explainInverse(p: InverseProblem, model: AnswerModel): Explanation {
  const { a, b, y } = p, ax = expected(model, "sub"), x = expected(model, "x");
  const fx = polyText([[a, "x"], [b, ""]]);
  return {
    heading: "Run it backwards",
    idea: ["The inverse undoes f. f multiplies first and adds last, so the inverse undoes the adding first, then the multiplying.", "On a graph the inverse is the mirror image across y = x: the point (x, y) becomes (y, x)."],
    statement: [...inverseMath(p), text(",  f⁻¹("), num(y), text(")")],
    caption: `f takes ${f(x)} to ${f(y)}, so f⁻¹ takes ${f(y)} back to ${f(x)}: ${pt(x, y)} mirrors to ${pt(y, x)}.`,
    diagram: buildPlane({
      alt: `Graph: y = ${fx}, its mirror image across y = x, and the points ${pt(x, y)} and ${pt(y, x)}.`,
      equal: true,
      fit: [[x, y], [y, x], [0, 0], [Math.min(x, y) - 2, Math.min(x, y) - 2], [Math.max(x, y) + 2, Math.max(x, y) + 2]],
      items: [
        { kind: "line", m: 1, b: 0, cls: "ax dash", label: { text: "y = x", optional: true } },
        { kind: "line", m: a, b, cls: "ln", label: { text: `f`, optional: true } },
        { kind: "line", m: 1 / a, b: -b / a, cls: "ln2", from: 2, label: { text: "f⁻¹", acc: true, optional: true } },
        { kind: "point", at: [x, y], label: { text: pt(x, y) } },
        { kind: "segment", a: [x, y], b: [y, x], cls: "ln2 dash", from: 2 },
        { kind: "point", at: [y, x], cls: "dota", from: 2, delay: 0.4, label: { text: pt(y, x), acc: true } },
      ],
    }),
    timeline: beats(3),
    steps: [
      { id: "ask", narration: `f(x) = ${fx}. Which input gives ${f(y)}? Undo f's steps in reverse order.`, math: [...inverseMath(p)], state: 0 },
      { id: "sub", narration: `f adds ${fP(b)} last, so undo it first: ${f(y)} − ${fP(b)} = ${f(ax)}.`, math: [num(y), op("−"), ...P(b), op("="), num(ax)], state: 1, answerStep: "sub", result: ax },
      { id: "x", narration: `Then undo × ${fP(a)}: ${f(ax)} ÷ ${fP(a)} = ${f(x)}. Check: f(${f(x)}) = ${f(y)}.`, math: [num(ax), op("÷"), ...P(a), op("="), num(x)], state: 2, answerStep: "x", result: x },
    ],
  };
}

export const lesson: LessonDefinition<InverseProblem> = withEasyStart({
  id: "g11-inverse",
  grade: 11,
  unit: "Functions",
  title: "Inverse functions",
  reference: createInverse(3, 2, 4),
  generate: rng => generateInverse(rng),
  restore: restoreInverse,
  display: inverseMath,
  displayNote: p => `Find f⁻¹(${f(p.y)}).`,
  answers: inverseAnswers,
  explain: explainInverse,
});
