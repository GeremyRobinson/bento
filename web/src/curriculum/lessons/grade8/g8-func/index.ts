import type { LessonDefinition } from "../../../schemas/lesson";
import { f } from "../../_plane/kit";
import { funcAnswers } from "./answers";
import { explainFunc, funcMath } from "./explanation";
import { createFunc, generateFunc, restoreFunc, type FuncProblem } from "./problem";
import { withEasyStart } from "../../easy-start";

export const lesson: LessonDefinition<FuncProblem> = withEasyStart({
  id: "g8-func",
  grade: 8,
  unit: "Functions and slope",
  title: "Evaluate a function",
  reference: createFunc(3, -5, 4),
  generate: rng => generateFunc(rng),
  restore: restoreFunc,
  display: funcMath,
  displayNote: p => `Find f(${f(p.x)}).`,
  answers: funcAnswers,
  explain: explainFunc,
});
