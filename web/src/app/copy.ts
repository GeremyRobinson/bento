/**
 * Words that appear in more than one place. A screen, the island and the settings all say the same thing the same
 * way, so a wording change is made once here. Only phrases used two or more times live here; one-off sentences stay
 * next to the screen that says them. No imports, so the engine can read it too.
 */

export const CHOOSE_GRADE = "Choose your grade";
/** the landing page's one button: it opens the grade picker, like walking into the app (G 2026-10-06) */
export const START_LEARNING = "Start learning";
export const FIND_MY_LEVEL = "Find my level";
export const GRADE_CHECKUP = "Grade check-up";
export const ALL_LESSONS = "All lessons";
export const PRACTICE = "Practice";
export const PRACTICE_AGAIN = "Practice again";
export const UP_NEXT = "Up next";
export const REVIEW = "Review";
export const TODAYS_REVIEW = "Today's review";
export const FACT_SPRINT = "Fact sprint";
export const SHOW_ME = "Show me";
export const CONTENTS = "Contents";
export const THIS_YEAR = "This year";
export const FINISHED = "Finished";
export const YOUR_BENTO = "Your Bento";
export const GROWN_UP = "For the grown-up";
export const REPORT = "Report";

/** a chapter with no unit of its own; screens show the grade's name in its place */
export const NO_UNIT = "Skills";

/** the settings, in the island's quick settings and on Me */
export const SETTING = {
  motion: "Less motion",
  colorSafe: "Color-blind friendly",
  readAloud: "Read aloud",
  sounds: "Sounds",
} as const;

/** how long a lesson takes, as the plan and the book show it */
export const LESSON_MINUTES = 8;
export const minLabel = (n: number) => `${n} min`;

/** a chapter or grade's progress line: "6 lessons", "2 of 6 done", "Finished" */
export const lessonCount = (done: number, total: number) =>
  done === 0 ? `${total} lesson${total === 1 ? "" : "s"}` : done === total ? FINISHED : `${done} of ${total} done`;
