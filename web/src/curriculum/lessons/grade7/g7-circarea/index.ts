import { sup } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildCircleArea } from "../../../../explanations/diagrams/circle/build";
import { asRecord, expected, mt, ns, numberField, round6 } from "../../_geometry/kit";
import { aNum } from "../../../text";

/** A circle with radius r; the lesson uses 3.14 for π. */
export interface CircleAreaProblem {
  kind: "geometry.circleArea";
  r: number;
}

export function createCircleArea(r: number): CircleAreaProblem {
  if (!(r > 0)) throw new Error("the radius must be positive");
  return { kind: "geometry.circleArea", r };
}

export function restoreCircleArea(raw: unknown): CircleAreaProblem | null {
  const r = asRecord(raw), v = r && numberField(r, "r");
  if (v == null) return null;
  try { return createCircleArea(v); } catch { return null; }
}

export function circleAreaAnswers({ r }: CircleAreaProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "square", label: "Square the radius", prompt: s => mt`${r}${sup("2")} = ${s}`, ans: r * r, hint: `${r} × ${r}.`, wrong: [[2 * r, "Squared as times 2", `Squared means ${r} × ${r}.`]] }),
      ns({ id: "times-pi", label: "Times π", prompt: s => mt`${r * r} × 3.14 = ${s}`, ans: round6(r * r * 3.14), hint: `${r * r} × 3.14.`,
        // fixes-02 A6: the two formulas learners mix up
        wrong: [
          [round6(2 * r * 3.14), "Used the circumference", "That's the distance around. Area uses r × r."],
          [round6(4 * r * r * 3.14), "Squared the diameter", "Square the radius, not the diameter."],
        ] }),
    ],
    finalParts: [-1],
  };
}

export function explainCircleArea({ r }: CircleAreaProblem, answers: AnswerModel): Explanation {
  const r2 = expected(answers, "square"), area = expected(answers, "times-pi");
  return {
    heading: "A = π × r × r",
    idea: ["Make a square on the radius: r × r.", "The circle holds about 3.14 of those squares."],
    statement: mt`A = 3.14 × ${r}${sup("2")}`,
    caption: `The circle holds 3.14 squares of ${r2}: ${area}.`,
    diagram: buildCircleArea({ r, r2, area, pi: "3.14", squareBeat: 1, areaBeat: 2, alt: `A circle of radius ${r} with ${aNum(r)} by ${r} square on its radius. The circle holds about 3.14 of those squares: ${area}.` }),
    timeline: beats(3),
    steps: [
      { id: "circle", narration: `A circle with radius ${r}.`, math: mt`r = ${r}`, state: 0 },
      { id: "square", narration: `Build a square on the radius: ${r} × ${r} = ${r2}.`, math: mt`${r}${sup("2")} = ${r2}`, state: 1, answerStep: "square", result: r2 },
      { id: "times-pi", narration: `The circle holds about 3.14 of those squares: ${r2} × 3.14 = ${area}.`, math: mt`${r2} × 3.14 = ${area}`, state: 2, answerStep: "times-pi", result: area },
    ],
  };
}

export const lesson: LessonDefinition<CircleAreaProblem> = {
  id: "g7-circarea",
  grade: 7,
  unit: "Geometry",
  title: "Area of a circle",
  pre: "g6-expo",
  reference: createCircleArea(3),
  generate: rng => createCircleArea(rng.int(2, 12)),
  restore: restoreCircleArea,
  display: p => mt`radius ${p.r}`,
  displayNote: () => "Area = π × r². Use 3.14 for π.",
  answers: circleAreaAnswers,
  explain: explainCircleArea,
};
