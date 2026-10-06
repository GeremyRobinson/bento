// The g12-polyd picture (Curriculum fixes-02, Part B): the derivative term by term. Each beat an exponent drops onto
// its coefficient and the term slides one column right into the f′ row; the constant falls off; at x = 1 the row adds up.
import { buildTermTable, type TermCell, type TermNote } from "../../../../explanations/diagrams/algebra/terms";
import type { SceneDiagram } from "../../../../explanations/diagrams/scene/schema";
import { formatNumber as f } from "../../../schemas/math-text";
import { coef } from "../../../text";

/** a negative number in brackets after an operator */
const P = (v: number) => (v < 0 ? `(${f(v)})` : f(v));

export function polynomialDerivativePicture(o: { a: number; b: number; c: number; d: number; A: number; B: number; C: number; total: number }): SceneDiagram {
  const { a, b, c, d, A, B, C, total } = o;
  const top: TermCell[] = [a, b, c, d].map((v, k) => ({ row: 0, col: k, text: f(v), from: 0, at: 0.2 + 0.2 * k, ...(k === 3 && v === 0 ? { tone: "faded" as const } : {}) }));
  const notes: TermNote[] = [
    // the exponent comes down onto its coefficient
    { row: -0.55, col: 0, text: "3 ×", cls: "lbl acc", from: 1, until: 1, at: 0.2, enter: "drop" },
    { row: -0.55, col: 1, text: "2 ×", cls: "lbl acc", from: 2, until: 2, at: 0.2, enter: "drop" },
    { row: -0.55, col: 2, text: "1 ×", cls: "lbl acc", from: 3, until: 3, at: 0.2, enter: "drop" },
  ];
  return buildTermTable({
    cols: [{ label: "x", sup: "3", part: "p0" }, { label: "x", sup: "2", part: "p1" }, { label: "x", part: "p2" }, { label: "1", part: "pw" }],
    rows: [{ label: "f" }, { label: "f′", from: 1 }, { label: "x = 1", from: 4 }],
    cells: [
      ...top,
      { row: 1, col: 1, text: f(A), from: 1, slideFrom: [0, 0], at: 0.9 },
      { row: 1, col: 2, text: f(B), from: 2, slideFrom: [0, 1], at: 0.9 },
      { row: 1, col: 3, text: f(C), from: 3, slideFrom: [0, 2], at: 0.9 },
      // at x = 1 every power is 1: each f′ term is just its coefficient
      ...[A, B, C].map((v, k): TermCell => ({ row: 2, col: k + 1, text: f(v), from: 4, slideFrom: [1, k + 1], at: 0.2 + 0.25 * k })),
    ],
    notes,
    marks: [
      ...(d ? [{ row: 0, col: 3, kind: "focus" as const, from: 0, until: 0, at: 1 }] : []),
      { row: 0, col: 0, kind: "focus", from: 1, until: 1, at: 0.1 },
      { row: 0, col: 1, kind: "focus", from: 2, until: 2, at: 0.1 },
      { row: 0, col: 2, kind: "focus", from: 3, until: 3, at: 0.1 },
      // the constant drops out: its derivative is 0
      ...(d ? [{ row: 0, col: 3, kind: "strike" as const, from: 3, at: 1.6 }] : []),
    ],
    dropRoom: true,
    lines: [
      { text: `3 × ${P(a)} = ${f(A)}, and x³ becomes x²`, from: 1, until: 1, at: 1, cls: "lbl pw" },
      { text: `2 × ${P(b)} = ${f(B)}, and x² becomes x`, from: 2, until: 2, at: 1, cls: "lbl pw" },
      { text: d ? `${coef(c, "x")} becomes ${f(C)}; the ${f(d)} becomes 0` : `${coef(c, "x")} becomes ${f(C)}`, from: 3, until: 3, at: 1, cls: "lbl pw" },
      { text: `f′(1) = ${f(A)} + ${P(B)} + ${P(C)} = ${f(total)}`, from: 4, at: 1.4 },
    ],
    alt: `A table with x³, x², x and number columns. Each term's exponent comes down and the term moves one column right: ${f(A)}, ${f(B)}, ${f(C)}${d ? `; the constant ${f(d)} drops out` : ""}. At x = 1 they add to ${f(total)}.`,
  });
}
