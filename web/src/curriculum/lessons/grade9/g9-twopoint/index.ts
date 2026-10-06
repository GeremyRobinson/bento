import type { LessonDefinition } from "../../../schemas/lesson";
import { twoPointAnswers } from "./answers";
import { explainTwoPoint, twoPointMath } from "./explanation";
import { createTwoPoint, generateTwoPoint, restoreTwoPoint, type TwoPointProblem } from "./problem";
import { withEasyStart } from "../../easy-start";

export const lesson: LessonDefinition<TwoPointProblem> = withEasyStart({
  id: "g9-twopoint",
  grade: 9,
  unit: "Linear functions",
  title: "Line through two points",
  pre: "g8-intercept",
  reference: createTwoPoint(2, 3, 1, 3),
  generate: rng => generateTwoPoint(rng),
  restore: restoreTwoPoint,
  display: twoPointMath,
  displayNote: () => "Write the line as y = mx + b.",
  answers: twoPointAnswers,
  explain: explainTwoPoint,
});
