import { op, text } from "../../../schemas/math-text";
import type { LessonDefinition } from "../../../schemas/lesson";
import { f, poly } from "../../_plane/kit";
import { tangentAnswers } from "./answers";
import { explainTangent } from "./explanation";
import { createTangent, generateTangent, restoreTangent, type TangentProblem } from "./problem";
import { withEasyStart } from "../../easy-start";

export const lesson: LessonDefinition<TangentProblem> = withEasyStart({
  id: "g12-tangent",
  grade: 12,
  unit: "Derivatives",
  title: "Slope of a tangent line",
  reference: createTangent(1, 3, 2),
  generate: rng => generateTangent(rng),
  restore: restoreTangent,
  display: p => [text("f(x)"), op("="), ...poly([[p.a, "x²"], [p.b, "x"]])],
  displayNote: p => `Find the slope at x = ${f(p.k)}.`,
  answers: tangentAnswers,
  explain: explainTangent,
});
