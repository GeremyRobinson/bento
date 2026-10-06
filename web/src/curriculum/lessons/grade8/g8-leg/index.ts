import { sup } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildRightTriangle } from "../../../../explanations/diagrams/right-triangle/build";
import { asRecord, expected, mt, ns, numberField, TRIPLES } from "../../_geometry/kit";
import { withEasyStart } from "../../easy-start";

/** A right triangle with leg a (drawn up), long side c, and the missing leg b (drawn across). */
export interface MissingLegProblem {
  kind: "geometry.missingLeg";
  a: number;
  b: number;
  c: number;
}

export function createMissingLeg(a: number, b: number, c: number): MissingLegProblem {
  if (![a, b, c].every(v => Number.isInteger(v) && v > 0)) throw new Error("sides must be positive whole numbers");
  if (a * a + b * b !== c * c) throw new Error(`${a}, ${b}, ${c} is not a right triangle`);
  return { kind: "geometry.missingLeg", a, b, c };
}

export function restoreMissingLeg(raw: unknown): MissingLegProblem | null {
  const r = asRecord(raw);
  const a = r && numberField(r, "a"), b = r && numberField(r, "b"), c = r && numberField(r, "c");
  if (a == null || b == null || c == null) return null;
  try { return createMissingLeg(a, b, c); } catch { return null; }
}

export function missingLegAnswers({ a, b, c }: MissingLegProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "square-c", label: "Square c", prompt: s => mt`${c}${sup("2")} = ${s}`, ans: c * c, hint: `Squared means the side times itself: ${c} × ${c}.`, wrong: [[2 * c, "Squared as times 2", `Squared means ${c} × ${c}.`]] }),
      ns({ id: "square-a", label: "Square a", prompt: s => mt`${a}${sup("2")} = ${s}`, ans: a * a, hint: `Squared means the side times itself: ${a} × ${a}.`, wrong: [[2 * a, "Squared as times 2", `Squared means ${a} × ${a}.`]] }),
      ns({ id: "subtract", label: "Subtract", prompt: s => mt`b${sup("2")} = ${c * c} − ${a * a} = ${s}`, ans: b * b, hint: "For a leg, subtract.",
        wrong: [[c * c + a * a, "Added instead of subtracted", "c is the longest side, so subtract to find a leg."]] }),
      ns({ id: "root", label: "Square root", prompt: s => mt`b = √${b * b} = ${s}`, ans: b, hint: `What number times itself is ${b * b}?`, wrong: [[b * b / 2, "Halved instead of taking the root", `The root is the number that times itself makes ${b * b}, not half of it.`]] }),
    ],
    finalParts: [-1],
  };
}

export function explainMissingLeg(p: MissingLegProblem, answers: AnswerModel): Explanation {
  const { a, b, c } = p;
  const C2 = expected(answers, "square-c"), A2 = expected(answers, "square-a"), B2 = expected(answers, "subtract"), leg = expected(answers, "root");
  return {
    heading: "Subtract to find a leg",
    idea: ["c is the long side, so its square is the biggest.", "Take the known leg's square away from it, then find the square root."],
    statement: mt`${a}${sup("2")} + b${sup("2")} = ${c}${sup("2")}`,
    caption: `${C2} − ${A2} = ${B2}, and √${B2} = ${leg}.`,
    diagram: buildRightTriangle({
      a: a, b: b,
      sides: { a: { text: String(a) }, b: { text: "b", acc: true }, c: { text: String(c) } },
      squares: {
        c: { from: 1, top: [{ text: String(c), sup: "2" }], area: String(C2), areaFrom: 1 },
        a: { from: 2, top: [{ text: String(a), sup: "2" }], area: String(A2), areaFrom: 2 },
        b: { from: 3, top: [{ text: "b", sup: "2", until: 3 }, { text: `b = ${leg}`, from: 4, cls: "lbl acc" }], area: String(B2), areaFrom: 3 },
      },
      alt: `A right triangle with leg ${a} and long side ${c}. The square on the long side holds ${C2}; take away the ${A2} on leg ${a} and ${B2} is left for the square on the missing leg, so it is ${leg}.`,
    }),
    timeline: beats(5),
    steps: [
      { id: "triangle", narration: `A right triangle with one leg ${a} and the long side ${c}. The other leg, b, is missing.`, math: mt`a = ${a}, c = ${c}, b = ?`, state: 0 },
      { id: "square-c", narration: `The square on the long side holds ${c} × ${c} = ${C2}.`, math: mt`${c}${sup("2")} = ${C2}`, state: 1, answerStep: "square-c", result: C2 },
      { id: "square-a", narration: `The square on the leg of ${a} holds ${a} × ${a} = ${A2}.`, math: mt`${a}${sup("2")} = ${A2}`, state: 2, answerStep: "square-a", result: A2 },
      { id: "subtract", narration: `The two leg squares fill the big one, so the missing square is what's left: ${C2} − ${A2} = ${B2}.`, math: mt`b${sup("2")} = ${C2} − ${A2} = ${B2}`, state: 3, answerStep: "subtract", result: B2 },
      { id: "root", narration: `${leg} × ${leg} = ${B2}, so the missing leg is ${leg}.`, math: mt`b = √${B2} = ${leg}`, state: 4, answerStep: "root", result: leg },
    ],
  };
}

export const lesson: LessonDefinition<MissingLegProblem> = withEasyStart({
  id: "g8-leg",
  grade: 8,
  unit: "Geometry",
  title: "Find a missing leg",
  pre: "g8-pyth",
  reference: createMissingLeg(6, 8, 10),
  generate: rng => { const [a, b, c] = rng.pick(TRIPLES); return rng.next() < 0.5 ? createMissingLeg(a, b, c) : createMissingLeg(b, a, c); },
  restore: restoreMissingLeg,
  display: p => mt`a = ${p.a}, c = ${p.c}, b = ?`,
  displayNote: () => "Right triangle: c is the long side. a² + b² = c²",
  answers: missingLegAnswers,
  explain: explainMissingLeg,
});
