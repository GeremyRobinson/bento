import { sup } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildCylinder } from "../../../../explanations/diagrams/cylinder/build";
import { asRecord, expected, mt, ns, numberField, round6 } from "../../_geometry/kit";
import { withEasyStart } from "../../easy-start";

/** A cylinder with radius r and height h; the lesson uses 3.14 for π. */
export interface CylinderProblem {
  kind: "geometry.cylinderVolume";
  r: number;
  h: number;
}

export function createCylinder(r: number, h: number): CylinderProblem {
  if (!(r > 0 && h > 0)) throw new Error("radius and height must be positive");
  return { kind: "geometry.cylinderVolume", r, h };
}

export function restoreCylinder(raw: unknown): CylinderProblem | null {
  const o = asRecord(raw), r = o && numberField(o, "r"), h = o && numberField(o, "h");
  if (r == null || h == null) return null;
  try { return createCylinder(r, h); } catch { return null; }
}

export function cylinderAnswers({ r, h }: CylinderProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "square", label: "Square the radius", prompt: s => mt`${r}${sup("2")} = ${s}`, ans: r * r, hint: `Squared means the radius times itself: ${r} × ${r}.`, wrong: [[2 * r, "Squared as times 2", `Squared means ${r} × ${r}.`]] }),
      ns({ id: "height", label: "Times the height", prompt: s => mt`${r * r} × ${h} = ${s}`, ans: r * r * h, hint: "Each unit of height stacks one more layer.", wrong: [[r * r * h / 3, "Divided by 3", "÷ 3 is for a cone. A cylinder is the whole stack."]] }),
      ns({ id: "times-pi", label: "Times π", prompt: s => mt`${r * r * h} × 3.14 = ${s}`, ans: round6(r * r * h * 3.14), hint: "The base is a circle, not a square: a circle holds about 3.14 times r × r.",
        wrong: [[round6(r * r * h * 2 * 3.14), "Used 2π", "2 × π is for the distance around. The area of a circle uses π once."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainCylinder({ r, h }: CylinderProblem, answers: AnswerModel): Explanation {
  const r2 = expected(answers, "square"), rh = expected(answers, "height"), v = expected(answers, "times-pi");
  return {
    heading: "Base area × height",
    idea: ["A cylinder is its circle base stacked up to the height.", "Volume = π × r² × h: the base area, then times the height."],
    statement: mt`V = 3.14 × ${r}${sup("2")} × ${h}`,
    caption: `Stack the base up ${h} high: ${r2} × ${h} = ${rh}, times 3.14 is ${v}.`,
    diagram: buildCylinder({
      cone: false, r, h, baseBeat: 1, fillBeat: 2,
      notes: [{ text: `${r}² = ${r2}`, from: 1 }, { text: `${r2} × ${h} = ${rh}`, from: 2 }, { text: `${rh} × 3.14 = ${v}`, from: 3, acc: true }],
      alt: `A cylinder with radius ${r} and height ${h}. Its volume is 3.14 × ${r2} × ${h} = ${v}.`,
    }),
    timeline: beats(4),
    steps: [
      { id: "solid", narration: `A cylinder with radius ${r} and height ${h}.`, math: mt`r = ${r}, h = ${h}`, state: 0 },
      { id: "square", narration: `Start with the base: ${r} × ${r} = ${r2}.`, math: mt`${r}${sup("2")} = ${r2}`, state: 1, answerStep: "square", result: r2 },
      { id: "height", narration: `Stack it up ${h} high: ${r2} × ${h} = ${rh}.`, math: mt`${r2} × ${h} = ${rh}`, state: 2, answerStep: "height", result: rh },
      { id: "times-pi", narration: `The base is a circle, so multiply by 3.14: ${rh} × 3.14 = ${v}.`, math: mt`${rh} × 3.14 = ${v}`, state: 3, answerStep: "times-pi", result: v },
    ],
  };
}

export const lesson: LessonDefinition<CylinderProblem> = withEasyStart({
  id: "g8-cyl",
  grade: 8,
  unit: "Geometry",
  title: "Volume of a cylinder",
  reference: createCylinder(2, 5),
  generate: rng => createCylinder(rng.int(1, 6), rng.int(2, 10)),
  restore: restoreCylinder,
  display: p => mt`radius ${p.r}, height ${p.h}`,
  displayNote: () => "V = π × r² × h. Use 3.14 for π.",
  answers: cylinderAnswers,
  explain: explainCylinder,
});
