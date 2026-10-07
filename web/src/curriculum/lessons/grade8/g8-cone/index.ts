import { sup } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildCylinder } from "../../../../explanations/diagrams/cylinder/build";
import { asRecord, expected, mt, ns, numberField, round6 } from "../../_geometry/kit";
import { withEasyStart } from "../../easy-start";

/** A cone with radius r and height h, where r² × h divides by 3; the lesson uses 3.14 for π. */
export interface ConeProblem {
  kind: "geometry.coneVolume";
  r: number;
  h: number;
}

export function createCone(r: number, h: number): ConeProblem {
  if (!(r > 0 && h > 0)) throw new Error("radius and height must be positive");
  return { kind: "geometry.coneVolume", r, h };
}

export function restoreCone(raw: unknown): ConeProblem | null {
  const o = asRecord(raw), r = o && numberField(o, "r"), h = o && numberField(o, "h");
  if (r == null || h == null) return null;
  try { return createCone(r, h); } catch { return null; }
}

export function coneAnswers({ r, h }: ConeProblem): AnswerModel {
  const base = round6(r * r * 3.14), cyl = round6(base * h);
  return {
    steps: [
      ns({ id: "base", label: "Base area", prompt: s => mt`3.14 × ${r}${sup("2")} = ${s}`, ans: base, hint: `The base is a circle. A circle's area is π × r × r: 3.14 × ${r} × ${r}.`,
        wrong: [[r * r, "Left out π", `${r} × ${r} is a square. The base is a circle: multiply by 3.14.`], [round6(2 * 3.14 * r), "Used the circumference", "2 × π × r is the distance around. The base area is π × r × r."]] }),
      ns({ id: "cylinder", label: "Times the height", prompt: s => mt`${base} × ${h} = ${s}`, ans: cyl, hint: `The cylinder around the cone is the base stacked ${h} high.` }),
      ns({ id: "third", label: "Take a third", prompt: s => mt`${cyl} ÷ 3 = ${s}`, ans: round6(cyl / 3), hint: "A cone holds a third of the cylinder that just fits around it.",
        wrong: [[cyl, "Forgot the ÷ 3", "A cone holds a third of a cylinder: divide by 3."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainCone({ r, h }: ConeProblem, answers: AnswerModel): Explanation {
  const base = expected(answers, "base"), cyl = expected(answers, "cylinder"), v = expected(answers, "third");
  return {
    heading: "A third of a cylinder",
    idea: ["A cone holds a third of the cylinder around it."],
    statement: mt`V = 3.14 × ${r}${sup("2")} × ${h} ÷ 3`,
    caption: `The base is a circle of ${base} square units. The cylinder holds ${base} × ${h} = ${cyl}, and the cone a third of it: ${v}.`,
    diagram: buildCylinder({
      cone: true, r, h, baseBeat: 1, fillBeat: 3,
      notes: [{ text: `3.14 × ${r}² = ${base}`, from: 1 }, { text: `${base} × ${h} = ${cyl}`, from: 2 }, { text: `${cyl} ÷ 3 = ${v}`, from: 3, acc: true }],
      alt: `A cone with radius ${r} and height ${h} inside its cylinder. It holds a third: 3.14 × ${r * r} × ${h} ÷ 3 = ${v}.`,
    }),
    timeline: beats(4),
    steps: [
      { id: "solid", narration: `A cone with radius ${r} and height ${h}, inside the cylinder that just fits it.`, math: mt`r = ${r}, h = ${h}`, state: 0 },
      { id: "base", narration: `The base is a circle: 3.14 × ${r} × ${r} = ${base} square units.`, math: mt`3.14 × ${r}${sup("2")} = ${base}`, state: 1, answerStep: "base", result: base },
      { id: "cylinder", narration: `Stack the base ${h} high for the cylinder: ${base} × ${h} = ${cyl}.`, math: mt`${base} × ${h} = ${cyl}`, state: 2, answerStep: "cylinder", result: cyl },
      { id: "third", narration: `The cone holds a third of that: ${cyl} ÷ 3 = ${v}.`, math: mt`${cyl} ÷ 3 = ${v}`, state: 3, answerStep: "third", result: v },
    ],
  };
}

export const lesson: LessonDefinition<ConeProblem> = withEasyStart({
  id: "g8-cone",
  grade: 8,
  unit: "Geometry",
  title: "Volume of a cone",
  reference: createCone(3, 4),
  generate: rng => { let r: number, h: number; do { r = rng.int(1, 6); h = rng.int(2, 12); } while ((r * r * h) % 3); return createCone(r, h); },
  restore: restoreCone,
  display: p => mt`radius ${p.r}, height ${p.h}`,
  displayNote: () => "V = π × r² × h ÷ 3. Use 3.14 for π.",
  answers: coneAnswers,
  explain: explainCone,
});
