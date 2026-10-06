// The g12-anti picture (Curriculum fixes-02, Part B): an antiderivative undoes the power rule. The term moves one
// column left (up one power), its coefficient is divided by the new exponent, + C joins, and a faint arrow back
// to the right is the check: the derivative gives the term again.
import { buildTermTable } from "../../../../explanations/diagrams/algebra/terms";
import type { SceneDiagram } from "../../../../explanations/diagrams/scene/schema";
import { formatNumber as f } from "../../../schemas/math-text";
import { supText } from "../../algebra-kit/steps";

/** c·xᵉ as written: "x⁶" and "−x⁶" for ±1 */
const termText = (c: number, e: number) => `${c === 1 ? "" : c === -1 ? "−" : f(c)}x${e === 1 ? "" : supText(e)}`;

export function antiderivativePicture(o: { a: number; n: number; up: number; c: number }): SceneDiagram {
  const { a, n, up, c } = o;
  return buildTermTable({
    cols: [{ label: "x", sup: String(up), part: "p1" }, { label: "x", ...(n === 1 ? {} : { sup: String(n) }), part: "p0" }],
    // a spare row between the integral and its answer, for the term moving up and the division dropping in
    rows: [{ label: "∫" }, {}, { label: "=", from: 1 }],
    cells: [
      { row: 0, col: 1, text: f(a), from: 0, at: 0.2 },
      { row: 2, col: 0, text: f(a), from: 1, until: 1, slideFrom: [0, 1], at: 0.3 },
      { row: 2, col: 0, text: f(a), from: 2, until: 2, leave: 1.1 },
      { row: 2, col: 0, text: f(c), tone: "acc", from: 2, at: 1.2 },
    ],
    notes: [
      { row: -0.55, col: 1, text: "↑", cls: "lbl acc", from: 0, until: 0, at: 0.6 },
      { row: 1.1, col: 0, text: `÷ ${up}`, cls: "lbl big acc", from: 2, until: 2, at: 0.2, enter: "drop" },
      { row: 2, col: 1, text: "+ C", cls: "lbl big pw", from: 2, at: 1.6 },
    ],
    dropRoom: true,
    marks: [{ row: "head", col: 1, kind: "ring", from: 0, until: 0, at: 0.3 }],
    // the check: the derivative takes the answer back to where the term started
    arrows: [{ kind: "back", a: [2, 0], b: [0, 1], from: 2, at: 2 }],
    lines: [
      { text: `${n} + 1 = ${up}`, from: 1, until: 1, at: 0.9 },
      { text: `${f(a)} ÷ ${up} = ${f(c)}: ${termText(c, up)} + C`, from: 2, at: 1.3 },
      { text: `check: its derivative is ${termText(a, n)} again`, from: 2, at: 2.2, cls: "sm muted" },
    ],
    alt: `${termText(a, n)} in the x${n === 1 ? "" : supText(n)} column moves one column left to x${supText(up)}, and ${f(a)} ÷ ${up} = ${f(c)}: ${termText(c, up)} + C. Its derivative gives ${termText(a, n)} back.`,
  });
}
