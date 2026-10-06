import type { LessonDefinition } from "../../../schemas/lesson";
import { quadFormAnswers } from "./answers";
import { explainQuadForm, quadFormMath } from "./explanation";
import { createQuadForm, generateQuadForm, restoreQuadForm, type QuadFormProblem } from "./problem";
import { withEasyStart } from "../../easy-start";

export const lesson: LessonDefinition<QuadFormProblem> = withEasyStart({
  id: "g9-quadform",
  grade: 9,
  unit: "Polynomials and quadratics",
  title: "The quadratic formula",
  pre: "g9-solvefactor",
  reference: createQuadForm(4, -2),
  generate: (rng, i) => generateQuadForm(rng, i),
  restore: restoreQuadForm,
  display: quadFormMath,
  displayNote: () => "x = (−b ± √(b² − 4ac)) ÷ 2a",
  answers: quadFormAnswers,
  explain: explainQuadForm,
});
