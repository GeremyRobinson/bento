import { sub, sup, text } from "../../../schemas/math-text";
import type { LessonDefinition } from "../../../schemas/lesson";
import { defIntAnswers } from "./answers";
import { explainDefInt, powerTerm } from "./explanation";
import { createDefInt, generateDefInt, restoreDefInt, type DefIntProblem } from "./problem";
import { withEasyStart } from "../../easy-start";

export const lesson: LessonDefinition<DefIntProblem> = withEasyStart({
  id: "g12-defint",
  grade: 12,
  unit: "Integrals",
  title: "Definite integrals",
  reference: createDefInt(2, 3, 2),
  generate: (rng, i) => generateDefInt(rng, i),
  restore: restoreDefInt,
  display: p => [text("∫"), sub(p.j), sup(p.k), text(" "), ...powerTerm(p.a, p.n), text(" dx")],
  answers: defIntAnswers,
  explain: explainDefInt,
});
