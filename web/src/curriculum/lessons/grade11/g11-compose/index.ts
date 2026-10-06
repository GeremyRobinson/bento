import { br, formatNumber as f, m, mark, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { fP, ns, P, poly, v } from "../../algebra-kit/steps";
import { attempt, nz, readInts } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { compositionPicture } from "./picture";
import { withEasyStart } from "../../easy-start";

/** f(x) = ax + b and g(x) = cx + d; find f(g(k)). */
export interface Composition { kind: "functions.compose"; a: number; b: number; c: number; d: number; k: number }

export const createComposition = (a: number, b: number, c: number, d: number, k: number): Composition => ({ kind: "functions.compose", a, b, c, d, k });

/** Same ranges as the current app: a and c from −5 to 5, b and d from −9 to 9, k from −4 to 4, none of them 0. */
export function generateComposition(rng: Rng): Composition {
  const a = nz(rng, -5, 5), b = nz(rng, -9, 9), c = nz(rng, -5, 5), d = nz(rng, -9, 9), k = nz(rng, -4, 4);
  return createComposition(a, b, c, d, k);
}

export function restoreComposition(raw: unknown): Composition | null {
  const r = readInts(raw, ["a", "b", "c", "d", "k"] as const);
  return r && attempt(() => createComposition(r.a, r.b, r.c, r.d, r.k));
}

const call = (name: string, arg: MathText): MathText => [text(`${name}(`), ...arg, text(")")];
const fx = ({ a, b }: Composition): MathText => [text("f(x)"), op("="), ...poly([[a, [v()]], [b, []]])];
const gx = ({ c, d }: Composition): MathText => [text("g(x)"), op("="), ...poly([[c, [v()]], [d, []]])];

export function compositionAnswers({ a, b, c, d, k }: Composition): AnswerModel {
  const g = c * k + d;
  return {
    steps: [
      ns({ id: "inside", l: "Inside first", a: s => [...call("g", [num(k)]), op("="), num(c), op("·"), ...P(k), op("+"), ...P(d), op("="), ...s], ans: g, h: "Work from the inside out: g gets the number first, so find g's answer.", w: [[c * k - d, "Sign slip", `Keep the sign of ${fP(d)}: ${f(c * k)} + ${fP(d)}.`]] }),
      ns({ id: "outside", l: "Then the outside", a: s => [...call("f", [num(g)]), op("="), num(a), op("·"), ...P(g), op("+"), ...P(b), op("="), ...s], ans: a * g + b, h: `What g gave back, ${f(g)}, is what goes into f.`,
        w: [[c * (a * k + b) + d, "Wrong order", "f(g(x)) means g first, then f."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainComposition(p: Composition, model: AnswerModel) {
  const { a, b, c, d, k } = p;
  const [g, out] = model.steps.map(s => s.slots[0]!.expected!) as [number, number];
  return beatExplanation({
    heading: "Inside out",
    idea: ["f(g(x)) is a chain of two machines: g works on x first, and whatever comes out goes into f.", "So work from the inside out: find g's answer, then put that number into f."],
    statement: [...fx(p), br(), ...gx(p), br(), ...call("f", call("g", [num(k)]))],
    caption: `g works on ${f(k)} first; f works on what g gives back.`,
    diagram: compositionPicture({ a, b, c, d, k, g, out }),
    alt: `g(${f(k)}) = ${f(g)}, then f(${f(g)}) = ${f(out)}.`,
    steps: [
      { id: "problem", narration: `f(g(${f(k)})) means: put ${f(k)} into g, then put that answer into f.`, math: call("f", call("g", [mark(k)])) },
      { id: "inside", narration: `Inside first: g(${f(k)}) = ${f(c)} · ${fP(k)} + ${fP(d)} = ${f(g)}.`, math: m(...call("g", [num(k)]), op("="), c, op("·"), ...P(k), op("+"), ...P(d), op("="), mark(g)), answerStep: "inside", result: g },
      { id: "outside", narration: `Then the outside: f(${f(g)}) = ${f(a)} · ${fP(g)} + ${fP(b)} = ${f(out)}.`, math: m(...call("f", [num(g)]), op("="), a, op("·"), ...P(g), op("+"), ...P(b), op("="), out), answerStep: "outside", result: out },
    ],
  });
}

export const lesson: LessonDefinition<Composition> = withEasyStart({
  id: "g11-compose",
  grade: 11,
  unit: "Functions",
  title: "Composing functions",
  reference: createComposition(1, 1, 2, 0, 3),
  generate: rng => generateComposition(rng),
  restore: restoreComposition,
  display: p => [...fx(p), br(), ...gx(p)],
  displayNote: p => `Find f(g(${f(p.k)})).`,
  answers: compositionAnswers,
  explain: explainComposition,
});
