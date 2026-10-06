import { num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import { attempt, expected, f, fP, ints, ns, nz, parabolaFit, poly, polyText, pt } from "../../_plane/kit";
import { withEasyStart } from "../../easy-start";

/** y = a·x² + b·x + c with a whole-number vertex x = h (b = −2ah). */
export interface VertexProblem { kind: "parabola.vertex"; a: number; b: number; c: number; h: number }

const AS = [1, 2, -1, -2, 3];
export function createVertex(a: number, h: number, c: number): VertexProblem {
  if (!AS.includes(a) || h === 0) throw new Error("a from the list and h not 0");
  return { kind: "parabola.vertex", a, b: -2 * a * h, c, h };
}

/** Same as the current app: a from 1, 2, −1, −2, 3; h −5..5 not 0; c −9..9. */
export function generateVertex(rng: Rng): VertexProblem {
  const a = rng.pick(AS), h = nz(rng, -5, 5);
  return createVertex(a, h, rng.int(-9, 9));
}

export function restoreVertex(raw: unknown): VertexProblem | null {
  const v = ints(raw, ["a", "c", "h"] as const);
  return v && attempt(() => createVertex(v.a, v.h, v.c));
}

const terms = ({ a, b, c }: VertexProblem): [number, string][] => [[a, "x²"], [b, "x"], [c, ""]];
export const vertexMath = (p: VertexProblem): MathText => [text("y = "), ...poly(terms(p))];
const xPrompt = (a: number, b: number) => [text("x = −("), num(b), text(") ÷ (2 · "), text(fP(a)), text(")")];
const yPrompt = (a: number, b: number, c: number, h: number) => [text(`y = ${f(a)}(${f(h)})² + ${fP(b)}(${f(h)}) + ${fP(c)}`)];

export function vertexAnswers({ a, b, c, h }: VertexProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "x", label: "x of the vertex", prompt: s => [...xPrompt(a, b), op("="), ...s], ans: h, hint: "The vertex sits halfway between the two places the parabola has the same height: x = −b ÷ (2 × a).",
        wrong: [[-h, "Forgot the minus", "The formula starts with −b."]] }),
      ns({ id: "y", label: "y of the vertex", prompt: s => [...yPrompt(a, b, c, h), op("="), ...s], ans: a * h * h + b * h + c, wrong: [[a * h * h + b * h, "Left out c", "Keep the number on its own: add c too."], [-a * h * h + b * h + c, "Sign of the square", "A negative squared is positive."]], hint: `The vertex is on the parabola, so its y is the height at x = ${f(h)}: put it in for every x.` }),
    ],
    finalParts: [-2, -1],
  };
}

export function explainVertex(p: VertexProblem, model: AnswerModel): Explanation {
  const { a, b, c } = p, h = expected(model, "x"), k = expected(model, "y");
  const F = (x: number) => a * x * x + b * x + c;
  return {
    heading: "x = −b ÷ 2a",
    idea: ["A parabola is symmetric, and its vertex sits on the line of symmetry x = −b ÷ 2a. Plug that x back in to get the vertex's y."],
    statement: vertexMath(p),
    caption: `The vertex sits on the line of symmetry, x = ${f(h)}: it is ${pt(h, k)}.`,
    diagram: buildPlane({
      alt: `Graph of y = ${polyText(terms(p))}, symmetric about x = ${f(h)}, with its vertex at ${pt(h, k)}.`,
      fit: parabolaFit(a, b, c),
      items: [
        { kind: "curve", f: F, label: { text: `y = ${polyText(terms(p))}`, optional: true } },
        { kind: "vline", x: h, cls: "ln2 dash", from: 1, label: { text: `x = ${f(h)}`, acc: true, optional: true } },
        { kind: "point", at: [h, k], cls: "dota", from: 2, label: { text: pt(h, k), acc: true, prefer: a > 0 ? ["s", "se", "sw"] : ["n", "ne", "nw"] } },
      ],
    }),
    timeline: beats(3),
    steps: [
      { id: "eq", narration: `Here a = ${f(a)} and b = ${f(b)}.`, math: vertexMath(p), state: 0 },
      { id: "x", narration: `x = −b ÷ 2a = −(${f(b)}) ÷ ${f(2 * a)} = ${f(h)}. That is the line of symmetry.`, math: [...xPrompt(a, b), op("="), num(h)], state: 1, answerStep: "x", result: h },
      { id: "y", narration: `Plug x = ${f(h)} back in: y = ${f(k)}. The vertex is ${pt(h, k)}.`, math: [...yPrompt(a, b, c, h), op("="), num(k)], state: 2, answerStep: "y", result: k },
    ],
  };
}

export const lesson: LessonDefinition<VertexProblem> = withEasyStart({
  id: "g11-vertex",
  grade: 11,
  unit: "Functions",
  title: "Vertex of a parabola",
  reference: createVertex(1, 3, 5),
  generate: rng => generateVertex(rng),
  restore: restoreVertex,
  display: vertexMath,
  displayNote: () => "Find the vertex.",
  answers: vertexAnswers,
  explain: explainVertex,
});
