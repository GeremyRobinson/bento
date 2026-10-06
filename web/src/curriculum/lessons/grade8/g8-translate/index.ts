import type { LessonDefinition } from "../../../schemas/lesson";
import { ptM } from "../../_plane/kit";
import { translateAnswers } from "./answers";
import { explainTranslate, moveWords } from "./explanation";
import { createTranslate, generateTranslate, restoreTranslate, type TranslateProblem } from "./problem";
import { withEasyStart } from "../../easy-start";

export const lesson: LessonDefinition<TranslateProblem> = withEasyStart({
  id: "g8-translate",
  grade: 8,
  unit: "Geometry",
  title: "Translations",
  reference: createTranslate(2, 3, 4, -5),
  generate: rng => generateTranslate(rng),
  restore: restoreTranslate,
  display: p => ptM(p.x, p.y),
  displayNote: p => { const [a, b] = moveWords(p); return `Move it ${a} and ${b}.`; },
  answers: translateAnswers,
  explain: explainTranslate,
});
