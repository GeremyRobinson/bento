import { createRng } from "../curriculum/generators/rng";
import type { AnyLesson } from "../curriculum/schemas/lesson";
import type { Explanation } from "../explanations/schema";

/**
 * The lesson preview (Design, handoff 5): the picture of the very problem the learner gets first. The detail draws it
 * from a seed; starting the lesson hands that same problem to the lesson screen, so the numbers match.
 */
export interface Preview { problem: unknown; ex: Explanation }

export function previewOf(lesson: AnyLesson, seed: number): Preview | null {
  const rng = createRng(seed);
  for (let i = 0; i < 3; i++) {
    try { const problem = lesson.generate(rng, 0); return { problem, ex: lesson.explain(problem, lesson.answers(problem)) }; } catch { /* try another */ }
  }
  try { return { problem: lesson.reference, ex: lesson.explain(lesson.reference, lesson.answers(lesson.reference)) }; } catch { return null; }
}

const handed = new Map<string, unknown>();
/** the problem the preview showed, for the lesson screen to open on */
export const handOff = (lessonId: string, problem: unknown) => { handed.set(lessonId, problem); };
export const takeHandOff = (lessonId: string): unknown | undefined => handed.get(lessonId);
/** once the lesson is on screen the hand-off is spent; a later visit gets a fresh problem */
export const spendHandOff = (lessonId: string) => { handed.delete(lessonId); };
