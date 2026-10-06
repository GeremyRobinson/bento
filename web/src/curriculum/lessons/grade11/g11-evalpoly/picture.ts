// The g11-evalpoly picture (Curriculum fixes-02, Part B): f(k) is the height of the graph at x = k, built from three
// pieces stacked along the line x = k: a·k² (from 0), then b·k, then c, landing on the curve. Built on the plane.
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import type { PlaneItem } from "../../../../explanations/diagrams/plane/schema";
import type { SceneDiagram } from "../../../../explanations/diagrams/scene/schema";
import { formatNumber as f } from "../../../schemas/math-text";

const signed = (v: number) => `${v < 0 ? "−" : "+"} ${f(Math.abs(v))}`;

export function evaluatePolynomialPicture(o: { a: number; b: number; c: number; k: number; A: number; B: number; total: number }): SceneDiagram {
  const { a, b, c, k, A, B, total } = o;
  const fx = (x: number) => a * x * x + b * x + c;
  const reach = Math.abs(k) + 1, ys = [0, A, A + B, total];
  const span = Math.max(...ys) - Math.min(...ys) || 1;
  // the pieces stand side by side a little apart, stepping right, so one going down never hides one going up;
  // the last one stands on x = k and lands on the curve
  const n = c ? 3 : 2, s = (2 * reach) * 0.035, xAt = (i: number) => k - (n - 1 - i) * s;
  const arrow = (v: number) => Math.abs(v) >= span * 0.06;
  const pieces: PlaneItem[] = [
    { kind: "segment", a: [xAt(0), 0], b: [xAt(0), A], cls: "ln p2", arrow: arrow(A), from: 1, label: { text: f(A), part: 2, prefer: ["w"] } },
    { kind: "segment", a: [xAt(0), A], b: [xAt(1), A], cls: "wire", from: 2 },
    { kind: "segment", a: [xAt(1), A], b: [xAt(1), A + B], cls: "ln p1", arrow: arrow(B), from: 2, delay: 0.2, label: { text: signed(B), part: 1, prefer: ["e", "w"] } },
  ];
  if (c) pieces.push(
    { kind: "segment", a: [xAt(1), A + B], b: [xAt(2), A + B], cls: "wire", from: 3 },
    { kind: "segment", a: [xAt(2), A + B], b: [xAt(2), total], cls: "ln p0", arrow: arrow(c), from: 3, delay: 0.2, label: { text: signed(c), part: 0, prefer: ["e", "w"] } },
  );
  return buildPlane({
    items: [
      { kind: "curve", f: fx, cls: "ln pw" },
      { kind: "vline", x: k, cls: "wire", label: { text: `x = ${f(k)}`, prefer: ["e", "w"] } },
      { kind: "label", at: [k, total], label: { text: "?", acc: true, prefer: ["ne", "nw", "e", "w"] }, until: 2 },
      ...pieces,
      { kind: "point", at: [k, total], cls: "dota", from: 3, delay: 0.9, label: { text: `f(${f(k)}) = ${f(total)}`, acc: true, prefer: ["e", "w", "ne", "nw"] } },
    ],
    fit: [[-reach, 0], [reach, 0], [k, A], [k, A + B], [k, total]],
    alt: `The graph of f with the line x = ${f(k)}. From 0, ${f(A)} for ${f(a)}·(${f(k)})², then ${signed(B)} for ${f(b)}·${f(k)}${c ? `, then ${signed(c)}` : ""}, landing on the curve at f(${f(k)}) = ${f(total)}.`,
  });
}
