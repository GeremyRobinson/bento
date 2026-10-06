// Geometry and data lessons (circle, right-triangle, angle, triangle-angles, polygon-split, similar, bars, marbles,
// cylinder families). Every recorded problem, step, hint, worked line and verdict matches the current app, so there
// are no text or checking deviations. Picture differences are not recorded here: every picture is now computed from
// the problem instead of being a fixed illustration.
export const deviations: Record<string, Partial<Record<string, string>>> = {
  "g10-exterior": {
    pre: "g8-tri: the exterior angle uses only the triangle sum (g8-tri); Curriculum fixes-02 \"Missing pre links\", so \"Build up first\" after a low score points at the lesson this one builds on",
    hint: "the Third inside angle hint says why (the three share 180°) (fixes-02 Part C, pattern 3)",
    explain: "Show me repeats the new hint, then \"That makes …\" as before",
    checks: "new named slips: taking only one angle off 180°, and 180 − a on the outside step (fixes-02 A4); the generic message quotes the new hint",
    steps: "a third step, \"Check with the far angles\" (a° + b° = ?), is added after the two recorded steps so the lesson's heading (outside = the two far angles added) is practised, not only stated. The two recorded steps keep their labels, prompts, answers and hints (Curriculum fixes-02 A4, 2026-10-06)",
  },
};
