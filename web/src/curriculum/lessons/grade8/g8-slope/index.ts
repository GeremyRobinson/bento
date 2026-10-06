import { text } from "../../../schemas/math-text";
import type { LessonDefinition } from "../../../schemas/lesson";
import { ptM } from "../../_plane/kit";
import { slopeAnswers } from "./answers";
import { explainSlope } from "./explanation";
import { createSlope, generateSlope, restoreSlope, type SlopeProblem } from "./problem";
import { withEasyStart } from "../../easy-start";

export const lesson: LessonDefinition<SlopeProblem> = withEasyStart({
  id: "g8-slope",
  grade: 8,
  unit: "Functions and slope",
  title: "Slope from two points",
  reference: createSlope(1, 2, 3, 8),
  generate: rng => generateSlope(rng),
  restore: restoreSlope,
  display: p => [...ptM(p.x1, p.y1), text(" and "), ...ptM(p.x2, p.y2)],
  displayNote: () => "Find the slope.",
  answers: slopeAnswers,
  explain: explainSlope,
});
