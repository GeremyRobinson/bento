// The g12-power picture (Curriculum fixes-02, Part B): one term in the xⁿ column; its exponent drops down to multiply
// the coefficient, and the term slides one column right into xⁿ⁻¹. The same motions as g12-polyd, so the two look alike.
import { buildTermTable } from "../../../../explanations/diagrams/algebra/terms";
import type { SceneDiagram } from "../../../../explanations/diagrams/scene/schema";
import { formatNumber as f } from "../../../schemas/math-text";
import { supText } from "../../algebra-kit/steps";

export function powerRulePicture(o: { a: number; n: number; c: number; e: number }): SceneDiagram {
  const { a, n, c, e } = o, term = `${f(c)}x${e === 1 ? "" : supText(e)}`;
  return buildTermTable({
    cols: [{ label: "x", sup: String(n), part: "p0" }, { label: "x", ...(e === 1 ? {} : { sup: String(e) }), part: "p1" }],
    rows: [{ label: "f" }, { label: "f′", from: 2 }],
    cells: [
      { row: 0, col: 0, text: f(a), from: 0, until: 0, at: 0.2 },
      { row: 0, col: 0, text: f(a), from: 1, until: 1, leave: 1.2 },
      { row: 0, col: 0, text: f(c), tone: "acc", from: 1, until: 1, at: 1.3 },
      { row: 0, col: 0, text: f(c), from: 2, until: 2, leave: 0.4 },
      { row: 1, col: 1, text: f(c), from: 2, slideFrom: [0, 0], at: 0.4 },
    ],
    notes: [
      // the exponent, marked, then coming down to the front
      { row: -0.55, col: 0.4, text: "↓", cls: "lbl acc", from: 0, until: 0, at: 0.6 },
      { row: -0.55, col: 0, text: `${n} ×`, cls: "lbl acc", from: 1, until: 1, at: 0.2, enter: "rise" },
    ],
    dropRoom: true,
    marks: [
      { row: "head", col: 0, kind: "ring", from: 0, until: 0, at: 0.3 },
      // the slope at x = 1 is just the new coefficient
      { row: 1, col: 1, kind: "focus", from: 4, at: 0.2 },
    ],
    lines: [
      { text: `${n} × ${a} = ${c}`, from: 1, until: 1, at: 1.3 },
      { text: `${n} − 1 = ${e}`, from: 2, until: 2, at: 0.8 },
      { text: `f′(x) = ${term}`, from: 3, at: 0.2 },
      { text: `at x = 1: f′(1) = ${f(c)}`, from: 4, at: 0.5 },
    ],
    alt: `${a}x${supText(n)} in the x${supText(n)} column: the exponent ${n} comes down, ${n} × ${a} = ${c}, and the term moves to the x${e === 1 ? "" : supText(e)} column: f′(x) = ${term}.`,
  });
}
