// The g9-polyadd picture (Curriculum fixes-02, Part B): a term table with an x² column, an x column and a number column.
// Each polynomial is a row; for subtraction the second row's signs flip in place first; then each beat adds one column down.
import { buildTermTable, type TermCell, type TermNote } from "../../../../explanations/diagrams/algebra/terms";
import type { SceneDiagram } from "../../../../explanations/diagrams/scene/schema";
import { formatNumber as f } from "../../../schemas/math-text";

export function polynomialSumPicture(o: { a: number; b: number; c: number; d: number; e: number; f: number; sub: boolean; A: number; B: number; C: number; answer: string }): SceneDiagram {
  const { sub, A, B, C } = o, first = [o.a, o.b, o.c], second = [o.d, o.e, o.f], sums = [A, B, C];
  const cells: TermCell[] = [
    ...first.map((v, k): TermCell => ({ row: 0, col: k, text: f(v), from: 0, at: 0.2 + 0.25 * k })),
    // the second row as written; when it is subtracted, each sign flips in place (amber) before anything is added
    ...second.map((v, k): TermCell => sub
      ? { row: 1, col: k, text: f(v), from: 0, until: 0, at: 1 + 0.25 * k, leave: 2 + 0.3 * k }
      : { row: 1, col: k, text: f(v), from: 0, at: 1 + 0.25 * k }),
    ...(sub ? second.map((v, k): TermCell => ({ row: 1, col: k, text: f(-v), tone: "acc", from: 0, until: 0, at: 2.05 + 0.3 * k })) : []),
    ...(sub ? second.map((v, k): TermCell => ({ row: 1, col: k, text: f(-v), from: 1 })) : []),
    ...sums.map((v, k): TermCell => ({ row: 2, col: k, text: f(v), from: k + 1, at: 0.7, ...(v === 0 ? { tone: "faded" as const } : {}) })),
  ];
  const notes: TermNote[] = [
    { row: 1, col: -1, text: sub ? "−" : "+", cls: "lbl big pw", from: 0, ...(sub ? { until: 0, at: 0.9, leave: 2 } : { at: 0.9 }) },
    ...(sub ? [{ row: 1, col: -1, text: "+", cls: "lbl big acc", from: 0, at: 2.05 } as TermNote] : []),
    ...(sub ? [{ row: 1, col: 1, text: "flip every sign", cls: "sm acc", from: 0, until: 0, at: 2.05 } as TermNote].map(n => ({ ...n, row: 1.62 })) : []),
  ];
  return buildTermTable({
    cols: [{ label: "x", sup: "2", part: "p0" }, { label: "x", part: "p1" }, { label: "1", part: "p2" }],
    rows: [{}, {}, { label: "=", from: 1 }],
    cells,
    notes,
    ruleAbove: [{ row: 2, from: 1 }],
    arrows: [0, 1, 2].map(k => ({ kind: "down" as const, a: [0, k] as [number, number], b: [2, k] as [number, number], from: k + 1, until: k + 1, at: 0.1 })),
    lines: [{ text: o.answer, from: 3, at: 1.2 }],
    alt: `A table with an x² column, an x column and a number column. Each column adds on its own: ${f(A)}, ${f(B)} and ${f(C)}, so ${o.answer}.`,
  });
}
