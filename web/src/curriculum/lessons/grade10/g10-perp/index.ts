import { op, text } from "../../../schemas/math-text";
import type { LessonDefinition } from "../../../schemas/lesson";
import { perpAnswers, slopeMath } from "./answers";
import { explainPerp } from "./explanation";
import { createPerp, generatePerp, restorePerp, type PerpProblem } from "./problem";
import { withEasyStart } from "../../easy-start";

export const lesson: LessonDefinition<PerpProblem> = withEasyStart({
  id: "g10-perp",
  grade: 10,
  unit: "Coordinate geometry",
  title: "Perpendicular slopes",
  pre: "g8-slope",
  reference: createPerp(2, 3),
  generate: rng => generatePerp(rng),
  restore: restorePerp,
  display: q => [text("m"), op("="), ...slopeMath(q)],
  displayNote: () => "Find the slope of a perpendicular line.",
  answers: perpAnswers,
  explain: explainPerp,
});
