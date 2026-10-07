import { frac } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildRadians } from "../../../../explanations/diagrams/circle/build";
import { asRecord, expected, fs, gcd, mt, ns, numberField, piText } from "../../_geometry/kit";
import { count } from "../../../text";
import { withEasyStart } from "../../easy-start";

/** An angle in degrees to write in radians. */
export interface DegreesToRadiansProblem {
  kind: "trig.degreesToRadians";
  t: number;
}

export const RADIAN_ANGLES = [30, 45, 60, 90, 120, 135, 150, 210, 225, 240, 270, 300, 315, 330] as const;

export function createDegreesToRadians(t: number): DegreesToRadiansProblem {
  if (!Number.isInteger(t) || t <= 0 || t >= 360) throw new Error("an angle between 0° and 360°");
  return { kind: "trig.degreesToRadians", t };
}

export function restoreDegreesToRadians(raw: unknown): DegreesToRadiansProblem | null {
  const r = asRecord(raw), t = r && numberField(r, "t");
  if (t == null) return null;
  try { return createDegreesToRadians(t); } catch { return null; }
}

export function degreesToRadiansAnswers({ t }: DegreesToRadiansProblem): AnswerModel {
  const g = gcd(t, 180);
  // the biggest common factor below g, the usual near miss
  let smaller = g - 1;
  while (smaller > 1 && g % smaller) smaller--;
  return {
    steps: [
      ns({ id: "gcf", label: "Common factor", prompt: s => mt`GCF of ${t} and 180 = ${s}`, ans: g, hint: "The biggest number that divides both: it splits the half turn into equal pieces that fit the angle exactly.",
        wrong: smaller > 1 ? [[smaller, "Not the biggest", `${smaller} divides both, but a bigger number does too.`]] : [] }),
      fs({ id: "radians", label: "Radians", prompt: s => mt`${t}° × ${frac("π", 180)} = ${s} π`, N: t, D: 180, hint: `π is a half turn, 180°. Divide the top and the bottom by ${g} to write ${t}/180 in lowest terms.`, wrong: [[180, t, "Upside down", "Degrees go on top: the angle over the half turn, 180."]], note: "Write the number in front of π, in lowest terms." }),
    ],
    finalParts: [-1],
  };
}

export function explainDegreesToRadians({ t }: DegreesToRadiansProblem, answers: AnswerModel): Explanation {
  const g = expected(answers, "gcf"), n = expected(answers, "radians", "n"), d = expected(answers, "radians", "d");
  return {
    heading: "Multiply by π/180",
    idea: ["A half turn is 180°, and in radians it is π."],
    statement: mt`${t}° × ${frac("π", 180)}`,
    caption: `${t}° is ${count(n, "piece")} of ${g}°, and ${d} of those pieces make a half turn (π): ${piText(n, d)}.`,
    diagram: buildRadians({
      t, piece: g, pieceBeat: 1, angleBeat: 2,
      pieceNote: `${g}° pieces: ${180 / g} of them make π`,
      answerNote: `${t}° = ${n} piece${n === 1 ? "" : "s"} = ${piText(n, d)}`,
      alt: `A circle with the half turn marked as π and cut into ${g}° pieces. An angle of ${t}° covers ${n} of them, so it is ${piText(n, d)}.`,
    }),
    timeline: beats(3),
    steps: [
      { id: "half-turn", narration: `A half turn is 180°, which is π radians. Write ${t}° as a share of it.`, math: mt`${t}° × ${frac("π", 180)}`, state: 0 },
      { id: "gcf", narration: `The biggest number that divides both ${t} and 180 is ${g}. Cut the half turn into ${g}° pieces: there are ${180 / g}.`, math: mt`180 ÷ ${g} = ${180 / g}`, state: 1, answerStep: "gcf", result: g },
      { id: "radians", narration: `${t}° is ${n} of those pieces, so it is ${n}/${d} of π: ${piText(n, d)}.`, math: mt`${frac(t, 180)} = ${frac(n, d)}`, state: 2, answerStep: "radians", result: n },
    ],
  };
}

export const lesson: LessonDefinition<DegreesToRadiansProblem> = withEasyStart({
  id: "g12-rad",
  grade: 12,
  unit: "Trigonometry",
  title: "Degrees to radians",
  reference: createDegreesToRadians(120),
  generate: rng => createDegreesToRadians(rng.pick(RADIAN_ANGLES)),
  restore: restoreDegreesToRadians,
  display: p => mt`${p.t}°`,
  displayNote: () => "Write it in radians.",
  answers: degreesToRadiansAnswers,
  explain: explainDegreesToRadians,
});
