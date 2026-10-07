// The g11-compose picture (Curriculum fixes-02, Part B): f's box around g's box around k. g works on k first and
// collapses to its value; that value slides into f's slot; then f works on it. The nesting itself shows the order.
// Every stage lands inside its beat (Learn plays a beat every 1.8 s), in the narration's order: the rule with the
// number put in, then its value (review v45 blocker 3: the collapse was timed at 2.6 s, past the beat's end).
import { buildExprBoxes, type XNode } from "../../../../explanations/diagrams/algebra/boxes";
import type { SceneDiagram } from "../../../../explanations/diagrams/scene/schema";
import { formatNumber as f } from "../../../schemas/math-text";
import { coef } from "../../../text";

const PF = "p2", PG = "p1";
/** "− 3" after a term; nothing for 0 */
const plus = (v: number) => (v ? ` ${v < 0 ? "−" : "+"} ${Math.abs(v)}` : "");
const bracket = (v: number) => (v < 0 ? `(${f(v)})` : f(v));

export function compositionPicture(o: { a: number; b: number; c: number; d: number; k: number; g: number; out: number }): SceneDiagram {
  const { a, b, c, d, k, g, out } = o;
  const ruleF = `f(x) = ${coef(a, "x")}${plus(b)}`, ruleG = `g(x) = ${coef(c, "x")}${plus(d)}`;
  const T = (text: string): XNode => ({ t: "text", text });
  const G = (kids: XNode[], lit = false): XNode => ({ t: "box", id: "G", part: PG, name: "g", under: ruleG, kids, lit });
  const F = (kids: XNode[], lit = false): XNode[] => [{ t: "box", id: "F", part: PF, name: "f", under: ruleF, kids, lit }];
  const K: XNode = { t: "chip", id: "k", text: f(k), part: "pq" };
  return buildExprBoxes({
    header: `f(g(${f(k)}))`,
    stages: [
      { beat: 0, at: 0, tree: F([G([K])]) },
      { beat: 1, at: 0, tree: F([G([K], true)]) },
      // g's rule with k put in
      { beat: 1, at: 0.4, tree: F([G([T(`${f(c)} ·`), { ...K, text: bracket(k), id: "k2", from: "k" }, ...(d ? [T(plus(d).trim())] : [])], true)]) },
      // g collapses; its value goes into f's slot
      { beat: 1, at: 1.2, tree: F([{ t: "chip", id: "g", text: f(g), part: PG, from: "G" }]) },
      { beat: 2, at: 0, tree: F([{ t: "chip", id: "g", text: f(g), part: PG }], true) },
      { beat: 2, at: 0.4, tree: F([T(`${f(a)} ·`), { t: "chip", id: "g2", text: bracket(g), part: PG }, ...(b ? [T(plus(b).trim())] : [])], true) },
      { beat: 2, at: 1.2, tree: [{ t: "chip", text: f(out), part: "pq", pop: true }] },
    ],
    alt: `f's box around g's box around ${f(k)}. Inside first: g(${f(k)}) = ${f(g)}; that goes into f: f(${f(g)}) = ${f(out)}.`,
  });
}
