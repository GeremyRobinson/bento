import type { LessonDefinition } from "../../../schemas/lesson";
import { solveFactorAnswers } from "./answers";
import { explainSolveFactor, solveFactorMath } from "./explanation";
import { createSolveFactor, generateSolveFactor, restoreSolveFactor, type SolveFactorProblem } from "./problem";
import { withEasyStart } from "../../easy-start";

export const lesson: LessonDefinition<SolveFactorProblem> = withEasyStart({
  id: "g9-solvefactor",
  grade: 9,
  unit: "Polynomials and quadratics",
  title: "Solve by factoring",
  pre: "g9-factor",
  reference: createSolveFactor(2, 3),
  generate: rng => generateSolveFactor(rng),
  restore: restoreSolveFactor,
  display: solveFactorMath,
  answers: solveFactorAnswers,
  explain: explainSolveFactor,
});
