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
  const r2 = r * r, base = round6(r2 * 3.14);
  return {
    steps: [
      ns({ id: "square", label: "Square the radius", prompt: s => mt`${r}${sup("2")} = ${s}`, ans: r2, hint: `Squared means the radius times itself: ${r} × ${r}.`, wrong: [[2 * r, "Squared as times 2", `Squared means ${r} × ${r}.`]] }),
      ns({ id: "base", label: "Base area", prompt: s => mt`3.14 × ${r2} = ${s}`, ans: base, hint: "The base is a circle. A circle's area is π × r × r, and π is about 3.14.",
        wrong: [[round6(2 * 3.14 * r), "Used the circumference", "2 × π × r is the distance around. The base area is π × r × r."]] }),
      ns({ id: "height", label: "Base × height", prompt: s => mt`${base} × ${h} = ${s}`, ans: round6(base * h), hint: `Each unit of height stacks one more layer of the base, and there are ${h} layers.`,
        wrong: [[round6((base * h) / 3), "Divided by 3", "÷ 3 is for a cone. A cylinder is the whole stack."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainCylinder({ r, h }: CylinderProblem, answers: AnswerModel): Explanation {
  const r2 = expected(answers, "square"), base = expected(answers, "base"), v = expected(answers, "height");
  return {
    heading: "Base area × height",
    idea: ["A cylinder is its circle base stacked up to the height.", "Volume = π × r² × h: find the base area first, then times the height."],
    statement: mt`V = 3.14 × ${r}${sup("2")} × ${h}`,
    caption: `The base is a circle of ${base} square units. Stack it ${h} high: ${base} × ${h} = ${v}.`,
    diagram: buildCylinder({
      cone: false, r, h, baseBeat: 2, fillBeat: 3,
      notes: [{ text: `${r}² = ${r2}`, from: 1 }, { text: `3.14 × ${r2} = ${base}`, from: 2 }, { text: `${base} × ${h} = ${v}`, from: 3, acc: true }],
      alt: `A cylinder with radius ${r} and height ${h}. Its base is 3.14 × ${r2} = ${base}, and its volume is ${base} × ${h} = ${v}.`,
    }),
    timeline: beats(4),
    steps: [
      { id: "solid", narration: `A cylinder with radius ${r} and height ${h}.`, math: mt`r = ${r}, h = ${h}`, state: 0 },
      { id: "square", narration: `Square the radius: ${r} × ${r} = ${r2}.`, math: mt`${r}${sup("2")} = ${r2}`, state: 1, answerStep: "square", result: r2 },
      { id: "base", narration: `The base is a circle: 3.14 × ${r} × ${r} = ${base} square units.`, math: mt`3.14 × ${r2} = ${base}`, state: 2, answerStep: "base", result: base },
      { id: "height", narration: `Stack ${h} layers of that base: ${base} × ${h} = ${v}.`, math: mt`${base} × ${h} = ${v}`, state: 3, answerStep: "height", result: v },
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
