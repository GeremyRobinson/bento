export const deviations: Record<string, Partial<Record<string, string>>> = {
  "g11-complex": {
    pre: "g9-foil: multiplying complex numbers is FOIL (g9-foil) with i² = −1; Curriculum fixes-02 \"Missing pre links\", so \"Build up first\" after a low score points at the lesson this one builds on",
    show: "1i is written i and −1i is −i, as a teacher writes them: (2 − i), not (2 − 1i) (Review v43 item 7, 2026-10-06)",
    prompt: "the Last × last line writes the i terms whole, 6i · (−3i) and 4i · (−i), instead of 6i · (−3)i and 4i · (−1)i (Review v43 item 7)",
    work: "the worked line is the prompt with the answer in it, so it changes the same way",
    hint: "the Real part and Imaginary part hints say why (fixes-02 Part C, pattern 3)",
    explain: "Show me repeats the new hint, then \"That makes …\" as before",
    checks: "new named slips: keeping i² as +1 in the real part, subtracting the i terms; the generic message quotes the new hint (fixes-02 Part C, pattern 5)",
  },
};
