import { num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import type { Side } from "../../../../explanations/diagrams/plane/schema";
import { attempt, expected, f, fP, ints, ns, nz, P } from "../../_plane/kit";
import { withEasyStart } from "../../easy-start";

/** ⟨a, b⟩ · ⟨c, d⟩ */
export interface DotProblem { kind: "vector.dot"; a: number; b: number; c: number; d: number }

export function createDot(a: number, b: number, c: number, d: number): DotProblem {
  if ([a, b, c, d].includes(0)) throw new Error("no part is 0");
  return { kind: "vector.dot", a, b, c, d };
}

/** Same as the current app: every part −9..9, not 0. Skips parallel arrows (a·d = b·c): one would cover the other, with no angle to mark. */
export function generateDot(rng: Rng): DotProblem {
  let q: DotProblem;
  do q = createDot(nz(rng, -9, 9), nz(rng, -9, 9), nz(rng, -9, 9), nz(rng, -9, 9)); while (q.a * q.d === q.b * q.c);
  return q;
}

export function restoreDot(raw: unknown): DotProblem | null {
  const v = ints(raw, ["a", "b", "c", "d"] as const);
  return v && attempt(() => createDot(v.a, v.b, v.c, v.d));
}

const vec = (x: number, y: number): MathText => [text("⟨"), num(x), text(", "), num(y), text("⟩")];
const vt = (x: number, y: number) => `⟨${f(x)}, ${f(y)}⟩`;
export const dotMath = ({ a, b, c, d }: DotProblem): MathText => [...vec(a, b), op("·"), ...vec(c, d)];

export function dotAnswers({ a, b, c, d }: DotProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "x", label: "x parts", prompt: s => [num(a), op("×"), ...P(c), op("="), ...s], ans: a * c, hint: "The x parts are the first numbers of each arrow: multiply them.", wrong: [[a + c, "Added", "Multiply the x parts; adding comes last."]] }),
      ns({ id: "y", label: "y parts", prompt: s => [num(b), op("×"), ...P(d), op("="), ...s], ans: b * d, hint: "The y parts are the second numbers of each arrow: multiply them.", wrong: [[a * d, "Mixed the parts", "Match x with x and y with y: the second number times the second number."]] }),
      ns({ id: "dot", label: "Add", prompt: s => [num(a * c), op("+"), ...P(b * d), op("="), ...s], ans: a * c + b * d,
        hint: "The dot product is one number: add the two products.", wrong: [[a * c * b * d, "Multiplied", "Multiply within each part, then add the parts."]], note: "If it's 0, the vectors are perpendicular." }),
    ],
    finalParts: [-1],
  };
}

export function explainDot(p: DotProblem, model: AnswerModel): Explanation {
  const { a, b, c, d } = p, X = expected(model, "x"), Y = expected(model, "y"), D = expected(model, "dot");
  const sense = D > 0 ? "less than a right angle apart" : D < 0 ? "more than a right angle apart" : "perpendicular";
  return {
    heading: "Multiply matching parts, then add",
    idea: ["The dot product is positive when the arrows point the same way and 0 when they're perpendicular."],
    statement: dotMath(p),
    caption: `${f(a)} × ${fP(c)} + ${fP(b)} × ${fP(d)} = ${f(D)}: the arrows are ${sense}.`,
    diagram: buildPlane({
      alt: `Graph: the vectors ${vt(a, b)} and ${vt(c, d)} from the origin; their dot product is ${f(D)}.`,
      equal: true,
      fit: [[0, 0], [a, b], [c, d]],
      items: [
        { kind: "segment", a: [0, 0], b: [a, b], arrow: true, label: { text: vt(a, b) } },
        { kind: "segment", a: [0, 0], b: [c, d], arrow: true, cls: "ln2", delay: 0.4, label: { text: vt(c, d), acc: true } },
        // beat 1: drop each tip to the x-axis (the x parts); beat 2: across to the y-axis (the y parts)
        { kind: "segment", a: [a, b], b: [a, 0], cls: "ln faint dash", from: 1, label: { text: `${f(a)} × ${fP(c)} = ${f(X)}`, optional: true, prefer: ["s", "e", "w"] } },
        { kind: "segment", a: [c, d], b: [c, 0], cls: "ln faint dash", from: 1 },
        { kind: "segment", a: [a, b], b: [0, b], cls: "ln faint dash", from: 2, label: { text: `${f(b)} × ${fP(d)} = ${f(Y)}`, optional: true, prefer: ["n", "w", "e"] } },
        { kind: "segment", a: [c, d], b: [0, d], cls: "ln faint dash", from: 2 },
        // beat 3: the dot product itself, on the angle it describes
        ...(D === 0 ? [{ kind: "rightAngle" as const, at: [0, 0] as const, u: [a, b] as const, v: [c, d] as const, from: 3 },
          { kind: "label" as const, at: [0, 0] as const, from: 3, label: { text: "dot = 0", acc: true, prefer: ["sw", "nw", "se", "ne"] as Side[] } }]
          : [{ kind: "angle" as const, at: [0, 0] as const, u: [a, b] as const, v: [c, d] as const, from: 3, label: { text: `dot = ${f(D)}`, acc: true } }]),
      ],
    }),
    timeline: beats(4),
    steps: [
      { id: "vs", narration: `Two arrows: ${vt(a, b)} and ${vt(c, d)}.`, math: dotMath(p), state: 0 },
      { id: "x", narration: `Multiply the x parts: ${f(a)} × ${fP(c)} = ${f(X)}.`, math: [num(a), op("×"), ...P(c), op("="), num(X)], state: 1, answerStep: "x", result: X },
      { id: "y", narration: `Multiply the y parts: ${f(b)} × ${fP(d)} = ${f(Y)}.`, math: [num(b), op("×"), ...P(d), op("="), num(Y)], state: 2, answerStep: "y", result: Y },
      { id: "dot", narration: `Add: ${f(X)} + ${fP(Y)} = ${f(D)}. ${D === 0 ? "0 means the arrows are perpendicular." : D > 0 ? "Positive: the arrows point roughly the same way." : "Negative: the arrows point apart."}`,
        math: [num(X), op("+"), ...P(Y), op("="), num(D)], state: 3, answerStep: "dot", result: D },
    ],
  };
}

export const lesson: LessonDefinition<DotProblem> = withEasyStart({
  id: "g12-dot",
  grade: 12,
  unit: "Vectors and series",
  title: "Dot product",
  pre: "g12-vecmag",
  reference: createDot(2, 3, 4, -1),
  generate: rng => generateDot(rng),
  restore: restoreDot,
  display: dotMath,
  answers: dotAnswers,
  explain: explainDot,
});
