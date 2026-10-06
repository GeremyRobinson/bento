import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildAngle } from "../../../../explanations/diagrams/angle/build";
import { asRecord, expected, mt, ns, numberField } from "../../_geometry/kit";

/** Supplementary (sup) or complementary angles; a is the one we know. */
export interface AnglePairProblem {
  kind: "geometry.anglePair";
  sup: boolean;
  a: number;
}

export function createAnglePair(sup: boolean, a: number): AnglePairProblem {
  const T = sup ? 180 : 90;
  if (!Number.isInteger(a) || a <= 0 || a >= T) throw new Error(`the known angle must be between 0 and ${T}`);
  return { kind: "geometry.anglePair", sup, a };
}

export function restoreAnglePair(raw: unknown): AnglePairProblem | null {
  const r = asRecord(raw);
  const a = r && numberField(r, "a");
  if (a == null || typeof r!.sup !== "boolean") return null;
  try { return createAnglePair(r!.sup, a); } catch { return null; }
}

export function anglePairAnswers({ sup, a }: AnglePairProblem): AnswerModel {
  const T = sup ? 180 : 90;
  return {
    steps: [
      ns({ id: "total", label: "What do they add up to?", question: `${sup ? "Supplementary" : "Complementary"} angles add up to how many degrees?`, prompt: s => mt`${s}°`, ans: T,
        hint: "Complementary makes a right angle. Supplementary makes a straight line.", wrong: [[sup ? 90 : 180, "Mixed up the two", "Complementary = 90°, supplementary = 180°."]] }),
      ns({ id: "missing", label: "Missing angle", prompt: s => mt`${T}° − ${a}° = ${s}°`, ans: T - a, hint: `Subtract ${a} from ${T}.`,
        wrong: [[T + a, "Added", "The missing angle is part of the whole, so it's smaller than it."], [(sup ? 90 : 180) - a, "Used the wrong whole", `${sup ? "Supplementary angles make 180°" : "Complementary angles make 90°"}.`]] }),
    ],
    finalParts: [-1],
  };
}

export function explainAnglePair(p: AnglePairProblem, answers: AnswerModel): Explanation {
  const T = expected(answers, "total"), rest = expected(answers, "missing"), { a, sup } = p;
  const word = sup ? "supplementary" : "complementary";
  return {
    heading: "90 or 180",
    idea: ["Complementary angles make a right angle: 90°.", "Supplementary angles make a straight line: 180°."],
    statement: mt`${a}° + ? = ${T}°`,
    caption: `${word[0]!.toUpperCase() + word.slice(1)}: ${a}° + ${rest}° = ${T}°.`,
    diagram: buildAngle({ total: sup ? 180 : 90, part: a, wholeBeat: 1, missingBeat: 2, wholeNote: `${sup ? "Supplementary" : "Complementary"} angles make ${T}°`, alt: `${a}° and ${rest}° are ${word}: together they make ${T}°.` }),
    timeline: beats(3),
    steps: [
      { id: "pair", narration: `The angles are ${word}. One is ${a}°.`, math: mt`${a}° and ?`, state: 0 },
      { id: "total", narration: sup ? "Supplementary angles make a straight line: 180°." : "Complementary angles make a right angle: 90°.", math: mt`${T}°`, state: 1, answerStep: "total", result: T },
      { id: "missing", narration: `The other angle is what's left: ${T}° − ${a}° = ${rest}°.`, math: mt`${T}° − ${a}° = ${rest}°`, state: 2, answerStep: "missing", result: rest },
    ],
  };
}

export const lesson: LessonDefinition<AnglePairProblem> = {
  id: "g7-angles",
  grade: 7,
  unit: "Geometry",
  title: "Complementary and supplementary",
  pre: "g4-angles",
  reference: createAnglePair(true, 35),
  generate: rng => { const sup = rng.next() < 0.5; return createAnglePair(sup, sup ? rng.int(20, 160) : rng.int(10, 80)); },
  restore: restoreAnglePair,
  display: p => mt`${p.a}° and ?`,
  displayNote: p => `The angles are ${p.sup ? "supplementary" : "complementary"}.`,
  answers: anglePairAnswers,
  explain: explainAnglePair,
};
