// The g6-expo picture (Curriculum fixes-02, Part B): the power box aⁿ, the product box b × c, joined by +. The power box
// opens into n copies of a (never "a × n") before it collapses; then the product box; then the + gives the answer.
import { buildExprBoxes, type XNode } from "../../../../explanations/diagrams/algebra/boxes";
import type { SceneDiagram } from "../../../../explanations/diagrams/scene/schema";
import { supText } from "../../algebra-kit/steps";

/** Grade 6's second part colour is green (right), so the two boxes take its first and third. */
const PE = "p0", PM = "p2";

export function exponentOrderPicture(o: { a: number; n: number; b: number; c: number; E: number; M: number; S: number }): SceneDiagram {
  const { a, n, b, c, E, M, S } = o;
  const T = (text: string, sup?: string): XNode => ({ t: "text", text, ...(sup ? { sup } : {}) });
  const chip = (v: number, part: string, pop = false): XNode => ({ t: "chip", text: String(v), part, pop });
  const power = (kids: XNode[], lit = false): XNode => ({ t: "box", part: PE, kids, lit });
  const product = (lit = false): XNode => ({ t: "box", part: PM, kids: [T(`${b} × ${c}`)], lit });
  const sum = (kids: XNode[], lit = false): XNode[] => [{ t: "box", part: "pw", kids, lit }];
  const repeated = T(Array(n).fill(String(a)).join(" × "));
  return buildExprBoxes({
    header: `${a}${supText(n)} + ${b} × ${c}`,
    stages: [
      { beat: 0, at: 0, tree: sum([power([T(String(a), String(n))]), T("+"), product()]) },
      { beat: 0, at: 1, tree: sum([power([T(String(a), String(n))], true), T("+"), product()]) },
      // the exponent says how many copies of a to multiply (beat 0 counts them; beat 1 works them out)
      { beat: 0, at: 2, tree: sum([power([repeated], true), T("+"), product()]) },
      { beat: 1, at: 0, tree: sum([power([repeated], true), T("+"), product()]) },
      { beat: 1, at: 1.2, tree: sum([chip(E, PE, true), T("+"), product()]) },
      { beat: 2, at: 0, tree: sum([chip(E, PE), T("+"), product(true)]) },
      { beat: 2, at: 1.2, tree: sum([chip(E, PE), T("+"), chip(M, PM, true)]) },
      { beat: 3, at: 0, tree: sum([chip(E, PE), T("+"), chip(M, PM)], true) },
      { beat: 3, at: 1.2, tree: [chip(S, "pq", true)] },
    ],
    alt: `${a}${supText(n)} + ${b} × ${c} in boxes: the power opens into ${n} copies of ${a} and becomes ${E}, then ${b} × ${c} becomes ${M}, then ${E} + ${M} = ${S}.`,
  });
}
