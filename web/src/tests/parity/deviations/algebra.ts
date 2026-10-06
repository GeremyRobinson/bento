// Intentional differences in the algebra lessons (balance, pairs and equation-chain pictures).
// tests/diagrams/algebra.test.ts still replays every recorded try for these lessons and allows only the change named here.
export const deviations: Record<string, Partial<Record<string, string>>> = {
  "g8-exp": {
    checks: "For x^(a+b) ÷ x^b the current app used −1 as a stand-in slip when (a+b) ÷ b isn't whole, so typing −1 said \"Divided the exponents\". The rebuild only names that slip when dividing the exponents really gives a whole number; −1 now gets the ordinary \"Not quite\" hint. Every other try is judged the same.",
  },
  "g11-ratexp": {
    pre: "g8-roots: a fractional exponent is a root (g8-roots); Curriculum fixes-02 \"Missing pre links\", so \"Build up first\" after a low score points at the lesson this one builds on",
    hint: "the hints say what the fraction's bottom and top do instead of naming the numbers (fixes-02 Part C, pattern 3)",
    explain: "Show me repeats the new hint, then \"That makes …\" as before",
    checks: "fixes-02: \"Not quite\" quotes the new hint and r × top is a named slip (tests/diagrams/algebra.test.ts replays exactly this). Before that: the \"Divided by the bottom\" message showed a superscript 1/n (\"^(1/2) is a root\"); messages are plain text here, so it reads \"A power of 1/2 is a root, not dividing by 2.\" Same slip, same kind, same verdicts.",
  },
  // g11-synth remainders (fixes-02: "remainder always 0"): every third problem now has a remainder e, with a two-box
  // quotient step. The recorded problems have e = 0 and restore with e = 0, so they ask the same numbers; no answers: entry.
  "g11-synth": {
    pre: "g11-evalpoly: the remainder is the value of the polynomial at r (g11-evalpoly); Curriculum fixes-02 \"Missing pre links\", so \"Build up first\" after a low score points at the lesson this one builds on",
    hint: "the Multiply and Quotient hints say what to do and why (\"Multiply the new bottom number by the box number …\") instead of restating the arithmetic (\"−4 times −1.\") or the answer (Curriculum fixes-02, g11-synth, 2026-10-06)",
    explain: "Show me repeats the new hint, then \"That makes …\" as before",
    checks: "new named slips: keeping the divisor's sign (−r in the box) and subtracting a column instead of adding. Tries the current app called \"Not quite\" now get those messages; every other verdict is the same (fixes-02, g11-synth)",
  },
};
