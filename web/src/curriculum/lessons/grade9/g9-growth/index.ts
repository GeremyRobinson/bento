import type { LessonDefinition } from "../../../schemas/lesson";
import { growthAnswers } from "./answers";
import { explainGrowth, growthDisplay, growthNote } from "./explanation";
import { createGrowth, generateGrowth, restoreGrowth, type GrowthProblem } from "./problem";
import { withEasyStart } from "../../easy-start";

export const lesson: LessonDefinition<GrowthProblem> = withEasyStart({
  id: "g9-growth",
  grade: 9,
  unit: "Exponents",
  title: "Exponential growth",
  reference: createGrowth(100, 2, 3),
  generate: rng => generateGrowth(rng),
  restore: restoreGrowth,
  display: growthDisplay,
  displayNote: growthNote,
  answers: growthAnswers,
  explain: explainGrowth,
});
