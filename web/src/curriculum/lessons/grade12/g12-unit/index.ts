import { frac } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildUnitCircle } from "../../../../explanations/diagrams/circle/build";
import { asRecord, expected, fracText, fs, mt, ns, numberField } from "../../_geometry/kit";
import { withEasyStart } from "../../easy-start";

/** sin or cos of an angle whose reference angle is 30° or 60°, so the value is ±1/2. */
export interface UnitCircleProblem {
  kind: "trig.unitCircle";
  f: "sin" | "cos";
  t: number;
}

export function createUnitCircle(f: string, t: number): UnitCircleProblem {
  if (f !== "sin" && f !== "cos") throw new Error(`unknown function ${f}`);
  const ok = f === "sin" ? [30, 150, 210, 330] : [60, 120, 240, 300];
  if (!ok.includes(t)) throw new Error(`${f} ${t}° is not ±1/2`);
  return { kind: "trig.unitCircle", f, t };
}

export function restoreUnitCircle(raw: unknown): UnitCircleProblem | null {
  const r = asRecord(raw), t = r && numberField(r, "t");
  if (t == null || typeof r!.f !== "string") return null;
  try { return createUnitCircle(r!.f, t); } catch { return null; }
}

const facts = ({ f, t }: UnitCircleProblem) => {
  const quad = Math.floor(t / 90) + 1, ref = [t, 180 - t, t - 180, 360 - t][quad - 1]!;
  const pos = f === "sin" ? quad <= 2 : quad === 1 || quad === 4;
  return { quad, ref, pos };
};

export function unitCircleAnswers(p: UnitCircleProblem): AnswerModel {
  const { f, t } = p, { quad, ref, pos } = facts(p);
  return {
    steps: [
      ns({ id: "quadrant", label: "Quadrant", prompt: s => mt`${t}° is in quadrant ${s}`, ans: quad, hint: "I is 0–90°, II is 90–180°, III is 180–270°, IV is 270–360°.", wrong: [[5 - quad, "Turned clockwise", "Angles turn counterclockwise from the right, through I, II, III, IV."]] }),
      ns({ id: "reference", label: "Reference angle", prompt: s => mt`reference angle = ${s}°`, ans: ref, hint: "The angle back to the nearest x-axis, whichever side is closer.", wrong: [[90 - ref, "Measured to the y-axis", "The reference angle goes back to the x-axis, not the y-axis."]] }),
      fs({ id: "value", label: "Value", prompt: s => mt`${f} ${t}° = ${s}`, N: pos ? 1 : -1, D: 2, note: "Put any minus sign on the top.",
        hint: `${f} ${ref}° = 1/2. ${f === "sin" ? "Sine" : "Cosine"} is ${pos ? "positive" : "negative"} in quadrant ${quad}.`,
        wrong: [[pos ? -1 : 1, 2, "Wrong sign", f === "sin" ? "Sine is the y value: positive above the x-axis." : "Cosine is the x value: positive right of the y-axis."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainUnitCircle(p: UnitCircleProblem, answers: AnswerModel): Explanation {
  const { f, t } = p;
  const quad = expected(answers, "quadrant"), ref = expected(answers, "reference");
  const n = expected(answers, "value", "n"), d = expected(answers, "value", "d");
  const value = fracText(n, d), pos = n > 0;
  const where = f === "sin" ? (pos ? "above the x-axis" : "below the x-axis") : pos ? "right of the y-axis" : "left of the y-axis";
  return {
    heading: "Reference angle, then sign",
    idea: ["Find the quadrant and the angle back to the x-axis.", "The size comes from the reference angle; the sign comes from where the point sits."],
    statement: mt`${f} ${t}°`,
    caption: `Quadrant ${quad}, reference ${ref}°: ${f} ${t}° = ${value}.`,
    diagram: buildUnitCircle({
      t, f, quadrant: quad, ref, value, quadrantBeat: 1, refBeat: 2, valueBeat: 3,
      alt: `The unit circle with an angle of ${t}° in quadrant ${quad}. Its reference angle is ${ref}°, and ${f} ${t}° = ${value}.`,
    }),
    timeline: beats(4),
    steps: [
      { id: "angle", narration: `Start on the right of the x-axis and turn ${t}° counterclockwise.`, math: mt`${f} ${t}°`, state: 0 },
      { id: "quadrant", narration: `${t}° lands in quadrant ${quad}.`, math: mt`quadrant ${quad}`, state: 1, answerStep: "quadrant", result: quad },
      { id: "reference", narration: `The angle back to the nearest x-axis is ${ref}°.`, math: mt`reference angle = ${ref}°`, state: 2, answerStep: "reference", result: ref },
      { id: "value", narration: `${f} ${ref}° = 1/2, and the point is ${where}, so ${f} ${t}° = ${value}.`, math: mt`${f} ${t}° = ${frac(n, d)}`, state: 3, answerStep: "value", result: n },
    ],
  };
}

export const lesson: LessonDefinition<UnitCircleProblem> = withEasyStart({
  id: "g12-unit",
  grade: 12,
  unit: "Trigonometry",
  title: "Unit circle values",
  pre: "g10-special",
  reference: createUnitCircle("sin", 210),
  // the first three problems stay in quadrant I, where every value is positive
  generate: (rng, i) => (i % 2 ? createUnitCircle("sin", i < 3 ? 30 : rng.pick([30, 150, 210, 330])) : createUnitCircle("cos", i < 3 ? 60 : rng.pick([60, 120, 240, 300]))),
  restore: restoreUnitCircle,
  display: p => mt`${p.f} ${p.t}°`,
  answers: unitCircleAnswers,
  explain: explainUnitCircle,
});
