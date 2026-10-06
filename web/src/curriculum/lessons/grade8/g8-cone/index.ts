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
  const rh = r * r * h;
  return {
    steps: [
      ns({ id: "cylinder", label: "r² × h", prompt: s => mt`${r}${sup("2")} × ${h} = ${s}`, ans: rh, hint: "Square the radius, then stack it as high as the cone: r × r × h.", wrong: [[2 * r * h, "Squared as times 2", `Squared means ${r} × ${r}.`]] }),
      ns({ id: "third", label: "Divide by 3", prompt: s => mt`${rh} ÷ 3 = ${s}`, ans: rh / 3, hint: "A cone is a third of a cylinder.",
        wrong: [[rh, "Forgot the ÷ 3", "A cone holds a third of a cylinder: divide by 3."]] }),
      ns({ id: "times-pi", label: "Times π", prompt: s => mt`${rh / 3} × 3.14 = ${s}`, ans: round6((rh / 3) * 3.14), hint: "The base is a circle, not a square: a circle holds about 3.14 times r × r.",
        wrong: [[round6((rh / 3) * 6.28), "Used 2π", "2 × π is for the distance around. The area of a circle uses π once."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainCone({ r, h }: ConeProblem, answers: AnswerModel): Explanation {
  const rh = expected(answers, "cylinder"), third = expected(answers, "third"), v = expected(answers, "times-pi");
  return {
    heading: "A third of a cylinder",
    idea: ["A cone holds a third of the cylinder around it.", "Volume = π × r² × h ÷ 3."],
    statement: mt`V = 3.14 × ${r}${sup("2")} × ${h} ÷ 3`,
    caption: `The cone fills a third of its cylinder: ${rh} ÷ 3 = ${third}, times 3.14 is ${v}.`,
    diagram: buildCylinder({
      cone: true, r, h, baseBeat: 1, fillBeat: 2,
      notes: [{ text: `${r}² × ${h} = ${rh}`, from: 1 }, { text: `${rh} ÷ 3 = ${third}`, from: 2 }, { text: `${third} × 3.14 = ${v}`, from: 3, acc: true }],
      alt: `A cone with radius ${r} and height ${h} inside its cylinder. It holds a third: 3.14 × ${rh} ÷ 3 = ${v}.`,
    }),
    timeline: beats(4),
    steps: [
      { id: "solid", narration: `A cone with radius ${r} and height ${h}, inside the cylinder that just fits it.`, math: mt`r = ${r}, h = ${h}`, state: 0 },
      { id: "cylinder", narration: `For the cylinder: ${r} × ${r} × ${h} = ${rh}.`, math: mt`${r}${sup("2")} × ${h} = ${rh}`, state: 1, answerStep: "cylinder", result: rh },
      { id: "third", narration: `The cone holds a third of that: ${rh} ÷ 3 = ${third}.`, math: mt`${rh} ÷ 3 = ${third}`, state: 2, answerStep: "third", result: third },
      { id: "times-pi", narration: `The base is a circle, so multiply by 3.14: ${third} × 3.14 = ${v}.`, math: mt`${third} × 3.14 = ${v}`, state: 3, answerStep: "times-pi", result: v },
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
