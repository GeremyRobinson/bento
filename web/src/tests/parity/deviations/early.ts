// The early grades now have full years, so their single lessons moved from "Skills" into real units (G, 2026-10-03).
export const deviations: Record<string, Partial<Record<string, string>>> = {
  "k-add": { unit: "kindergarten has units now; this lesson lives in Adding and subtracting", hint: "\"There is 1 dot\", not \"There are 1 dot\" (Curriculum fixes-01, 2026-10-03)", explain: "same wording fix as the hint" },
  "g1-ten": { unit: "1st grade has units now; this lesson lives in Adding and subtracting" },
  "g2-regroup": { unit: "2nd grade has units now; this lesson lives in Adding and subtracting",
    hint: "the ones and tens hints name the problem's own digits, \"Add just the ones: 7 + 8.\" (Review v40 little things 4: hints use the live numbers, 2026-10-06)",
    checks: "a wrong try's message repeats the step's hint, so it names the digits too (same review item)" },
  "g4-divide": { prompt: "the tens step asks for the biggest tens number, so only one answer fits (reviewer, 2026-10-03)", checks: "a new slip for too few tens; (Curriculum fixes-02 Part C, 2026-10-06) named slips on Subtract, Divide what's left and The answer",
    pre: "g3-divfacts: division facts come first (Curriculum fixes-02 Part C, 2026-10-06, Order 2)" },
  "g5-divide": { prompt: "the tens step asks for the biggest tens number, so only one answer fits (reviewer, 2026-10-03)",
    checks: "new named slips on Subtract and Divide what's left: \"Added instead of took away\", \"One too many\", \"One too few\" (Curriculum fixes-02 Part C, 2026-10-06)" },
  "g4-fracwhole": { steps: "the last step is named \"Write as a mixed number\", not \"Simplify\" (reviewer, 2026-10-03)", checks: "step names appear in slip messages; a wrong top repeats the new hint",
    hint: "the top hint asks \"Each group has 1 piece. How many pieces are in all the groups?\": \"5 groups of 1 piece\" gave the answer (Curriculum fixes-02 Part C, 2026-10-06)", explain: "Show me starts from the new hint",
    pre: "g4-likefrac: W × n/d is adding like fractions again and again (Curriculum fixes-02 Part C, 2026-10-06, Order 2)" },
  "g3-split": { unit: "3rd grade has units now; this lesson lives in Multiplication and division" },
};
