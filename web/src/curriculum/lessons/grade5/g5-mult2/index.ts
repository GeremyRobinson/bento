import { num, op } from "../../../schemas/math-text";
import type { LessonDefinition } from "../../../schemas/lesson";
import { splitMultiplicationAnswers } from "./answers";
import { explainSplitMultiplication } from "./explanation";
import { createSplitMultiplication, generateSplitMultiplication, restoreSplitMultiplication, type SplitMultiplicationProblem } from "./problem";

export const lesson: LessonDefinition<SplitMultiplicationProblem> = {
  id: "g5-mult2", // same id as the current app, so saved scores carry over
  grade: 5,
  unit: "Whole numbers",
  title: "Multiply two-digit numbers",
  pre: "g4-mult2x2",
  reference: createSplitMultiplication(47, 36),
  generate: (rng, index) => generateSplitMultiplication(rng, index),
  restore: restoreSplitMultiplication,
  display: p => [num(p.firstFactor), op("×"), num(p.secondFactor)],
  answers: splitMultiplicationAnswers,
  explain: explainSplitMultiplication,
  story: p => ({ op: "×", text: `A theater has **${p.firstFactor}** rows. Each row has **${p.secondFactor}** seats. How many seats are there?` }),
};

export const splitMultiplication = lesson;
