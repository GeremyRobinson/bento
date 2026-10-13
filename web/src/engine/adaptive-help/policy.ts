/**
 * Help fades as a skill grows, in every grade.
 * New or a score of 0–1: every step, named. 2: the student picks what comes next before each step.
 * 3–4: final answer only; a miss brings the steps back.
 */
export const HELP_TIERS = ["Every step shown", "You plan the steps", "Final answer only"] as const;
export type Tier = 0 | 1 | 2;

export const tierFor = (lastScore: number | null | undefined): Tier =>
  lastScore == null || lastScore <= 1 ? 0 : lastScore === 2 ? 1 : 2;

/** A lesson is 6 problems (v2 model); after a low score it is 8. A miss adds no problems. */
export const LESSON_LENGTH = 6;
export const LESSON_LENGTH_AFTER_LOW_SCORE = 8;
export const lessonLength = (lastScore: number | null | undefined) =>
  lastScore != null && lastScore <= 1 ? LESSON_LENGTH_AFTER_LOW_SCORE : LESSON_LENGTH;

/** About one hint for every two problems. */
export const hintBudget = (problems: number) => Math.ceil(problems / 2);

/** A hint opens only after a first try, or after 15 seconds of thinking. */
export const HINT_WAIT_MS = 15000;

/** Tries in quick succession look like guessing. */
export const RUSHED_MS = 4000;

/** "Show me" opens after two misses, or one miss once a hint was used. Never in tests. */
export const canShowMe = (o: { test: boolean; misses: number; hinted: boolean }) =>
  !o.test && (o.misses >= 2 || (o.hinted && o.misses >= 1));

/** The final-answer shortcut is offered at the top help tier, outside tests. */
export const canSkip = (o: { test: boolean; tier: Tier }) => !o.test && o.tier === 2;
