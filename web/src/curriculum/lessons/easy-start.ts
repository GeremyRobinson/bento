// The first problems of a run are the friendly ones (Curriculum fixes-02, Part C: "the first problems aren't easier").
// For index 0, 1 and 2 a lesson draws a few problems the usual way and keeps the one with the smallest numbers, so
// every rule of its generator still holds and the numbers stay random. From index 3 on it generates as before.
import type { LessonDefinition } from "../schemas/lesson";
import type { Rng } from "../generators/rng";
import { toPlainText } from "../schemas/math-text";

/** How many draws an early problem picks from. */
const DRAWS = 6;
/** Problems before this index are the easy start. */
export const EASY_START = 3;

/** How big a problem's numbers are: the numbers it shows plus every number its steps ask for, by size. */
export function problemSize<P>(lesson: Pick<LessonDefinition<P>, "display" | "answers">, p: P): number {
  const shown = (toPlainText(lesson.display(p)).match(/\d+(\.\d+)?/g) ?? []).map(Number);
  const asked = lesson.answers(p).steps.flatMap(s => (s.choices ? [] : s.slots.map(x => Math.abs(x.expected ?? 0))));
  return [...shown, ...asked].reduce((a, b) => a + b, 0);
}

/** The lesson with an easy start: its first three problems have the smallest numbers of a few draws. */
export function withEasyStart<P>(lesson: LessonDefinition<P>): LessonDefinition<P> {
  const generate = (rng: Rng, index: number): P => {
    let best = lesson.generate(rng, index);
    if (index >= EASY_START) return best;
    let size = problemSize(lesson, best);
    for (let k = 1; k < DRAWS; k++) {
      const p = lesson.generate(rng, index), s = problemSize(lesson, p);
      if (s < size) { best = p; size = s; }
    }
    return best;
  };
  return { ...lesson, generate };
}
