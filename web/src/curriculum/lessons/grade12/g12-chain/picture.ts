// The g12-chain picture (Curriculum fixes-02, Part B): an outer power box around a dashed inner box. The outside gets the
// power rule while the inside stays as it is; then the inside's own rate a (how fast it moves with x) leaves the inner box for the front, and n × a merges.
import { buildExprBoxes, type XNode } from "../../../../explanations/diagrams/algebra/boxes";
import type { SceneDiagram } from "../../../../explanations/diagrams/scene/schema";
import { supText } from "../../algebra-kit/steps";

const PO = "p0", PI = "p1";

export function chainRulePicture(o: { a: number; b: number; n: number; e: number; da: number; front: number; inner: string }): SceneDiagram {
  const { n, e, da, front, inner } = o;
  const I = (lit = false, under?: string): XNode => ({ t: "box", id: "I", part: PI, dash: true, lit, kids: [{ t: "text", text: inner }], ...(under ? { under } : {}) });
  const outer = (kids: XNode[], power: number): XNode => ({ t: "box", id: "P", part: PO, kids, ...(power === 1 ? {} : { sup: String(power) }) });
  const N: XNode = { t: "chip", id: "n", text: String(n), part: PO };
  const dot: XNode = { t: "text", text: "·" };
  return buildExprBoxes({
    header: `f(x) = (${inner})${supText(n)}`,
    stages: [
      { beat: 0, at: 0, tree: [outer([I(true, "inside")], n)] },
      { beat: 1, at: 0, tree: [outer([I()], n)] },
      // the power rule on the outside only: n comes to the front, the power drops by one, the inside is untouched
      { beat: 1, at: 1, tree: [{ ...N, pop: true }, outer([I(false, "unchanged")], e)] },
      // why: the inside moves da for each 1 that x moves, so it has a rate of its own
      { beat: 2, at: 0, tree: [N, outer([I(true, `moves ${da} per 1`)], e)] },
      { beat: 3, at: 0, tree: [N, outer([I(true)], e)] },
      { beat: 3, at: 1.1, tree: [{ t: "chip", id: "a", text: String(da), part: "pq", from: "I" }, dot, N, outer([I()], e)] },
      { beat: 4, at: 0, tree: [{ t: "chip", id: "a", text: String(da), part: "pq" }, dot, N, outer([I()], e)] },
      { beat: 4, at: 1, tree: [{ t: "chip", text: String(front), part: "pq", pop: true }, outer([I()], e)] },
    ],
    alt: `(${inner})${supText(n)} as an outer power box around the inside. The power rule gives ${n}(${inner})${e === 1 ? "" : supText(e)} with the inside unchanged; the inside's derivative ${da} comes to the front, and ${n} × ${da} = ${front}.`,
  });
}
