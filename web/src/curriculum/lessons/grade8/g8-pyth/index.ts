import { answer, sup } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Explanation } from "../../../../explanations/schema";
import { beats } from "../../../../explanations/schema";
import { buildRightTriangle } from "../../../../explanations/diagrams/right-triangle/build";
import { asRecord, expected, mt, ns, numberField, TRIPLES } from "../../_geometry/kit";
import type { Rng } from "../../../generators/rng";
import { withEasyStart } from "../../easy-start";

/** A right triangle with legs a (drawn up) and b (drawn across); c is the long side. */
export interface PythagorasProblem {
  kind: "geometry.pythagoras";
  a: number;
  b: number;
  c: number;
}

export function createPythagoras(a: number, b: number, c: number): PythagorasProblem {
  if (![a, b, c].every(v => Number.isInteger(v) && v > 0)) throw new Error("sides must be positive whole numbers");
  if (a * a + b * b !== c * c) throw new Error(`${a}, ${b}, ${c} is not a right triangle`);
  return { kind: "geometry.pythagoras", a, b, c };
}

/** Same as the current app: a triple from its list, legs in either order. */
export function generatePythagoras(rng: Rng): PythagorasProblem {
  const [a, b, c] = rng.pick(TRIPLES);
  return rng.next() < 0.5 ? createPythagoras(a, b, c) : createPythagoras(b, a, c);
}

export function restorePythagoras(raw: unknown): PythagorasProblem | null {
  const r = asRecord(raw);
  if (!r) return null;
  const a = numberField(r, "a"), b = numberField(r, "b"), c = numberField(r, "c");
  if (a == null || b == null || c == null) return null;
  try { return createPythagoras(a, b, c); } catch { return null; }
}

export function pythagorasAnswers({ a, b, c }: PythagorasProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "square-a", label: "Square a", prompt: s => mt`${a}${sup("2")} = ${s}`, ans: a * a, hint: `Squared means the side times itself: ${a} × ${a}.`,
        wrong: [[2 * a, "Squared as times 2", `Squared means ${a} × ${a}, not ${a} × 2.`]],
        explain: `Squared means the side times itself: ${a} × ${a} = ${a * a}.`, work: mt`${a}${sup("2")} = ${a * a}` }),
      ns({ id: "square-b", label: "Square b", prompt: s => mt`${b}${sup("2")} = ${s}`, ans: b * b, hint: `Squared means the side times itself: ${b} × ${b}.`,
        wrong: [[2 * b, "Squared as times 2", `Squared means ${b} × ${b}, not ${b} × 2.`]],
        explain: `Squared means the side times itself: ${b} × ${b} = ${b * b}.`, work: mt`${b}${sup("2")} = ${b * b}` }),
      ns({ id: "add", label: "Add them", prompt: s => mt`${a * a} + ${b * b} = c${sup("2")} = ${s}`, ans: c * c, hint: "The two small squares together fill the square on the long side: add them.", wrong: [[a + b, "Added the sides", "Add the two squares, not the sides."]],
        explain: `${a * a} + ${b * b} = ${c * c}.`, work: mt`c${sup("2")} = ${c * c}` }),
      ns({ id: "root", label: "Square root", prompt: s => mt`c = √${c * c} = ${s}`, ans: c, hint: `What number times itself makes ${c * c}?`,
        wrong: [[a + b, "Added the legs", `You can't just add the legs. Find the number that times itself makes ${c * c}.`],
          [(c * c) / 2, "Square root", `Square root isn't half. What number times itself is ${c * c}?`]],
        explain: `${c} × ${c} = ${c * c}, so c = ${c}.`, work: mt`c = ${answer("x", c)}` }),
    ],
    finalParts: [-1],
  };
}

export function explainPythagoras(p: PythagorasProblem, answers: AnswerModel): Explanation {
  const { a, b } = p;
  const A = expected(answers, "square-a"), B = expected(answers, "square-b"), C2 = expected(answers, "add"), c = expected(answers, "root");
  return {
    heading: "a² + b² = c²",
    idea: ["In a right triangle, the squares on the two short sides add up to the square on the long side."],
    statement: mt`${a}${sup("2")} + ${b}${sup("2")} = c${sup("2")}`,
    caption: `${A} + ${B} = ${C2}: the two small squares fill the big one.`,
    diagram: buildRightTriangle({
      a, b,
      sides: { a: { text: String(a) }, b: { text: String(b) }, c: { text: "c", acc: true } },
      squares: {
        a: { from: 1, top: [{ text: String(a), sup: "2" }], area: String(A), areaFrom: 1 },
        b: { from: 2, top: [{ text: String(b), sup: "2" }], area: String(B), areaFrom: 2 },
        c: { from: 3, top: [{ text: "c", sup: "2", until: 3 }, { text: `c = ${c}`, from: 4, cls: "lbl acc" }], area: String(C2), areaFrom: 3 },
      },
      alt: `A right triangle with legs ${a} and ${b}, a square on each side: ${A} and ${B} fill the square of ${C2} on the long side, which is ${c}.`,
    }),
    timeline: beats(5),
    steps: [
      { id: "triangle", narration: `A right triangle with legs ${a} and ${b}. The long side c is across from the square corner.`, math: mt`a = ${a}, b = ${b}, c = ?`, state: 0 },
      { id: "square-a", narration: `Build a square on the side of ${a}. It holds ${a} × ${a} = ${A}.`, math: mt`${a}${sup("2")} = ${A}`, state: 1, answerStep: "square-a", result: A },
      { id: "square-b", narration: `The square on the side of ${b} holds ${b} × ${b} = ${B}.`, math: mt`${b}${sup("2")} = ${B}`, state: 2, answerStep: "square-b", result: B },
      { id: "add", narration: `Together the two small squares fill the square on c: ${A} + ${B} = ${C2}.`, math: mt`${A} + ${B} = c${sup("2")} = ${C2}`, state: 3, answerStep: "add", result: C2 },
      { id: "root", narration: `The big square's side is the number that times itself makes ${C2}. ${c} × ${c} = ${C2}, so c = ${c}.`, math: mt`c = √${C2} = ${c}`, state: 4, answerStep: "root", result: c },
    ],
  };
}

export const lesson: LessonDefinition<PythagorasProblem> = withEasyStart({
  id: "g8-pyth",
  grade: 8,
  unit: "Geometry",
  title: "Pythagorean theorem",
  pre: "g8-roots",
  reference: createPythagoras(3, 4, 5),
  generate: rng => generatePythagoras(rng),
  restore: restorePythagoras,
  display: p => mt`a = ${p.a}, b = ${p.b}, c = ?`,
  displayNote: p => `Right triangle with legs ${p.a} and ${p.b}. Find the long side, c.\na² + b² = c²`,
  answers: pythagorasAnswers,
  explain: explainPythagoras,
});
