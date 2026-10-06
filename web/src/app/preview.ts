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

/**
 * Where a preview's picture should stop: the beat that shows the problem as its header writes it. Some pictures go on
 * past it (3rd grade facts turn the array around, b × a); a preview stops at a × b so its picture and header agree.
 */
export function statementBeat(ex: Explanation): number {
  const last = ex.timeline.length - 1, want = JSON.stringify(ex.statement);
  for (const st of ex.steps) {
    const m = st.math;
    if (!m || m.length <= ex.statement.length) continue;
    if (JSON.stringify(m.slice(0, ex.statement.length)) === want && JSON.stringify(m[ex.statement.length]).includes("=")) return Math.min(last, Math.max(0, st.state));
  }
  return last;
}
