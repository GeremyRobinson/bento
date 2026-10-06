import type { LessonDefinition } from "../../../schemas/lesson";
import { interceptAnswers } from "./answers";
import { explainIntercept, interceptMath } from "./explanation";
import { createIntercept, generateIntercept, restoreIntercept, type InterceptProblem } from "./problem";
import { withEasyStart } from "../../easy-start";

export const lesson: LessonDefinition<InterceptProblem> = withEasyStart({
  id: "g8-intercept",
  grade: 8,
  unit: "Functions and slope",
  title: "Slope-intercept form",
  reference: createIntercept(2, 3, 7),
  generate: rng => generateIntercept(rng),
  restore: restoreIntercept,
  display: interceptMath,
  displayNote: () => "Write the line as y = mx + b.",
  answers: interceptAnswers,
  explain: explainIntercept,
});
