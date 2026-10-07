// Coordinate plane lessons: where the rebuild intentionally differs from the current app, and why.
import { CHECKS, EXPLAIN, HINT } from "./fixes02-8-12";
export const deviations: Record<string, Partial<Record<string, string>>> = {
  "g11-seq": { hint: HINT, explain: EXPLAIN, checks: `${CHECKS}. Also: the off-by-one slip says \"22 minus 1, which is 21 jumps\" instead of \"22 − 1 jumps\", which read aloud as \"1 jumps\" (Curriculum fixes-01, 2026-10-03)` },
  "g11-geo": { pre: "g11-seq: geometric sequences multiply where arithmetic ones (g11-seq) add; Curriculum fixes-02 \"Missing pre links\", so \"Build up first\" after a low score points at the lesson this one builds on", hint: HINT, explain: EXPLAIN, checks: `${CHECKS}. Also: the off-by-one slip says \"22 minus 1, which is 21 jumps\" instead of \"22 − 1 jumps\", which read aloud as \"1 jumps\" (Curriculum fixes-01, 2026-10-03)` },
  "g12-series": { pre: "g11-seq: the series adds the terms of an arithmetic sequence (g11-seq); Curriculum fixes-02 \"Missing pre links\", so \"Build up first\" after a low score points at the lesson this one builds on", hint: HINT, explain: EXPLAIN, checks: `${CHECKS}. Also: the off-by-one slip says \"22 minus 1, which is 21 jumps\" instead of \"22 − 1 jumps\", which read aloud as \"1 jumps\" (Curriculum fixes-01, 2026-10-03)` },
  "g12-limit": { work: "K–12 lesson check (Review 2026-10-07): worked line is signed (\"(x − 3)\", not \"(x + −3)\")", pre: "g9-factor: the hole cancels by factoring (g9-factor); Curriculum fixes-02 \"Missing pre links\", so \"Build up first\" after a low score points at the lesson this one builds on", hint: `plug into x − 3, not x + −3 (Curriculum fixes-01, 2026-10-03); then ${HINT}`, explain: EXPLAIN, checks: `the same hint text appears in the slip message; ${CHECKS}` },
  "g12-defint": {
    work: "K–12 lesson check (Review 2026-10-07): no coefficient 1 (\"x³\", not \"1x³\")",
    pre: "g12-anti: the area is an antiderivative (g12-anti) evaluated at the ends; Curriculum fixes-02 \"Missing pre links\", so \"Build up first\" after a low score points at the lesson this one builds on",
    hint: HINT,
    explain: EXPLAIN,
    checks: `${CHECKS}. New slips on the antiderivative step: not dividing by the new power, taking the derivative (fixes-02 A5)`,
    show: "For n = 1 the current app writes 6x<sup></sup> dx: an empty superscript that shows nothing. The rebuild writes plain 6x dx, which looks the same on screen; the recorded text keeps the empty ^() and so can't match. Every other problem shows the same.",
  },
};
