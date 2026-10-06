import type { LessonDefinition } from "../../../schemas/lesson";
import { midAnswers } from "./answers";
import { explainMid, midMath } from "./explanation";
import { createMid, generateMid, restoreMid, type MidProblem } from "./problem";
import { withEasyStart } from "../../easy-start";

export const lesson: LessonDefinition<MidProblem> = withEasyStart({
  id: "g10-mid",
  grade: 10,
  unit: "Coordinate geometry",
  title: "Midpoint",
  reference: createMid(2, 3, 6, 9),
  generate: rng => generateMid(rng),
  restore: restoreMid,
  display: midMath,
  displayNote: () => "Find the midpoint.",
  answers: midAnswers,
  explain: explainMid,
});
