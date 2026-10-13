// K–12 lesson check (Review, 2026-10-07): intended wording fixes in lessons that had no deviations entry yet.
export const deviations: Record<string, Partial<Record<string, string>>> = {
  "g7-angles": { prompt: "K–12 lesson check (Review 2026-10-07): the question is shortened (\"Complementary angles add to?\") so it doesn't wrap and push the picture out of its card" },
  "g4-area": { pre: "g3-area: both halves of it are taught in 3rd grade (curriculum/specs/v2/grade4.md §1)", hint: "K–12 lesson check (Review 2026-10-07): the hint names rows and squares the way the grid and narration draw them (3 rows of 7, not 7 rows of 3)", explain: "K–12 lesson check (Review 2026-10-07): the worked answer says rows and squares the same way as the grid", checks: "K–12 lesson check (Review 2026-10-07): \"Not quite.\" repeats the corrected hint" },
};
