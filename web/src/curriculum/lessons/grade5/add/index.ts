import type { LessonDefinition } from "../../../schemas/lesson";
import { createUnlikeFractions, explainUnlike, generateUnlikeFractions, restoreUnlikeFractions, showUnlike, storyFor, unlikeAnswers, type UnlikeFractionsProblem } from "../../_tape-family/unlike";

export const lesson: LessonDefinition<UnlikeFractionsProblem> = {
  id: "add", // the current app's first lesson; saved scores use this id
  grade: 5,
  unit: "Fractions",
  title: "Adding fractions",
  pre: "g4-fraccompare",
  // the current app's cards: 1/2 + 1/3 = 3/6 + 2/6 = 5/6
  reference: createUnlikeFractions(1, 2, 1, 3, "+"),
  generate: (rng, i) => generateUnlikeFractions(rng, i, "+"),
  restore: raw => restoreUnlikeFractions(raw, "+"),
  display: showUnlike,
  answers: unlikeAnswers,
  explain: explainUnlike("add"),
  story: storyFor("add"),
};
