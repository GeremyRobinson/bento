// The g11-synth picture (Curriculum fixes-02, Part B): synthetic division as a rhythm on the coefficient row. r in the
// box, the coefficients 1, b, c on top; bring down, multiply by r into the next column, add down; the bottom row is the answer.
import { buildTermTable } from "../../../../explanations/diagrams/algebra/terms";
import type { SceneDiagram } from "../../../../explanations/diagrams/scene/schema";
import { formatNumber as f } from "../../../schemas/math-text";

/** a negative number in brackets after an operator */
const P = (v: number) => (v < 0 ? `(${f(v)})` : f(v));

export function syntheticPicture(o: { r: number; b: number; c: number; rr: number; q: number; qr: number; rem: number }): SceneDiagram {
  const { r, b, c, rr, q, qr, rem } = o, R = `× ${f(r)}`;
  return buildTermTable({
    cols: [{ label: "x", sup: "2", part: "p0" }, { label: "x", part: "p1" }, { label: "1", part: "p2" }],
    rows: [{}, {}, {}],
    cells: [
      { row: 0, col: 0, text: "1", from: 0, at: 0.5 }, { row: 0, col: 1, text: f(b), from: 0, at: 0.75 }, { row: 0, col: 2, text: f(c), from: 0, at: 1 },
      // bring the 1 down, then the rhythm: × r across, add down
      { row: 2, col: 0, text: "1", from: 1, slideFrom: [0, 0] },
      { row: 1, col: 1, text: f(rr), from: 1, at: 1.4 },
      { row: 2, col: 1, text: f(q), from: 2, at: 0.8 },
      { row: 1, col: 2, text: f(qr), from: 3, at: 1.1 },
      { row: 2, col: 2, text: f(rem), from: 4, at: 0.8, tone: "acc" },
    ],
    notes: [
      // r in its box at the left of the top row
      { row: 0, col: -1, text: f(r), cls: "lbl big acc", from: 0, at: 0.1 },
    ],
    marks: [
      { row: 0, col: -0.75, kind: "ring", from: 0, at: 0.1 },
      { row: 2, col: 2, kind: "ring", from: 4, at: 1.1 },
      { row: 2, col: 0, toCol: 1, kind: "focus", from: 5, at: 0.2 },
    ],
    ruleAbove: [{ row: 2, from: 1 }],
    arrows: [
      { kind: "across", a: [2, 0], b: [1, 1], label: R, from: 1, until: 1, at: 0.7 },
      { kind: "down", a: [0, 1], b: [2, 1], from: 2, until: 2, at: 0.1 },
      { kind: "across", a: [2, 1], b: [1, 2], label: R, from: 3, until: 3, at: 0.2 },
      { kind: "down", a: [0, 2], b: [2, 2], from: 4, until: 4, at: 0.1 },
    ],
    lines: [
      { text: `bring down 1, then 1 × ${P(r)} = ${f(rr)}`, from: 1, until: 1, at: 1.6, cls: "lbl pw" },
      { text: `${f(b)} + ${P(rr)} = ${f(q)}`, from: 2, until: 2, at: 0.9, cls: "lbl pw" },
      { text: `${f(q)} × ${P(r)} = ${f(qr)}`, from: 3, until: 3, at: 1.2, cls: "lbl pw" },
      { text: `${f(c)} + ${P(qr)} = ${f(rem)}: no remainder`, from: 4, until: 4, at: 1, cls: "lbl pw" },
      { text: `x ${q < 0 ? "−" : "+"} ${f(Math.abs(q))}, remainder ${f(rem)}`, from: 5, at: 0.5 },
    ],
    alt: `Synthetic division with ${f(r)} in the box: the top row 1, ${f(b)}, ${f(c)}; bring down 1, multiply by ${f(r)} and add down each column, giving 1, ${f(q)} and ${f(rem)}: x ${q < 0 ? "−" : "+"} ${f(Math.abs(q))}, remainder ${f(rem)}.`,
  });
}
