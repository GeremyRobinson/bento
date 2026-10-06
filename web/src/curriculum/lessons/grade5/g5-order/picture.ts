// The g5-order picture (Curriculum fixes-02, Part B): the expression in nested boxes, parentheses innermost (part 1),
// the × or ÷ group around or beside it (part 2), the + or − joining what is left (ink). Each beat collapses one box.
import { buildExprBoxes, type XNode, type XStage } from "../../../../explanations/diagrams/algebra/boxes";
import type { SceneDiagram } from "../../../../explanations/diagrams/scene/schema";

const T = (text: string): XNode => ({ t: "text", text });
const chip = (text: number | string, part: string, id?: string, pop = false): XNode => ({ t: "chip", text: String(text), part, ...(id ? { id } : {}), ...(pop ? { pop } : {}) });

export function orderPicture(o: { t: 0 | 1 | 2; a: number; b: number; c: number; d: number; r0: number; r1: number; r2: number }): SceneDiagram {
  const { t, a, b, c, d, r0, r1, r2 } = o;
  const box = (part: string, kids: XNode[], lit = false): XNode => ({ t: "box", part, kids, lit });
  // the looks of each step: as it was (the first only), its box lit, then the box collapsed into its value
  const trees: { before: XNode[]; lit: XNode[]; after: XNode[] }[] =
    t === 1 ? [
      { before: [box("pw", [box("p1", [box("p0", [T(`(${a} + ${b})`)]), T("×"), T(`${c}`)]), T("−"), T(`${d}`)])],
        lit: [box("pw", [box("p1", [box("p0", [T(`(${a} + ${b})`)], true), T("×"), T(`${c}`)]), T("−"), T(`${d}`)])],
        after: [box("pw", [box("p1", [chip(r0, "p0", "r0", true), T("×"), T(`${c}`)]), T("−"), T(`${d}`)])] },
      { before: [], lit: [box("pw", [box("p1", [chip(r0, "p0"), T("×"), T(`${c}`)], true), T("−"), T(`${d}`)])],
        after: [box("pw", [chip(r1, "p1", "r1", true), T("−"), T(`${d}`)])] },
      { before: [], lit: [box("pw", [chip(r1, "p1"), T("−"), T(`${d}`)], true)], after: [chip(r2, "pq", "r2", true)] },
    ] : t === 2 ? [
      { before: [box("pw", [box("p0", [T(`${a} × ${b}`)]), T("−"), box("p1", [T(`${c} ÷ ${d}`)])])],
        lit: [box("pw", [box("p0", [T(`${a} × ${b}`)], true), T("−"), box("p1", [T(`${c} ÷ ${d}`)])])],
        after: [box("pw", [chip(r0, "p0", "r0", true), T("−"), box("p1", [T(`${c} ÷ ${d}`)])])] },
      { before: [], lit: [box("pw", [chip(r0, "p0"), T("−"), box("p1", [T(`${c} ÷ ${d}`)], true)])],
        after: [box("pw", [chip(r0, "p0"), T("−"), chip(r1, "p1", "r1", true)])] },
      { before: [], lit: [box("pw", [chip(r0, "p0"), T("−"), chip(r1, "p1")], true)], after: [chip(r2, "pq", "r2", true)] },
    ] : [
      { before: [box("pw", [T(`${a}`), T("+"), box("p1", [T(`${b}`), T("×"), box("p0", [T(`(${c} − ${d})`)])])])],
        lit: [box("pw", [T(`${a}`), T("+"), box("p1", [T(`${b}`), T("×"), box("p0", [T(`(${c} − ${d})`)], true)])])],
        after: [box("pw", [T(`${a}`), T("+"), box("p1", [T(`${b}`), T("×"), chip(r0, "p0", "r0", true)])])] },
      { before: [], lit: [box("pw", [T(`${a}`), T("+"), box("p1", [T(`${b}`), T("×"), chip(r0, "p0")], true)])],
        after: [box("pw", [T(`${a}`), T("+"), chip(r1, "p1", "r1", true)])] },
      { before: [], lit: [box("pw", [T(`${a}`), T("+"), chip(r1, "p1")], true)], after: [chip(r2, "pq", "r2", true)] },
    ];
  // beat 0 asks which part goes first: the whole expression draws in, then the box that goes first lights up.
  // Each later beat collapses one box (beat 1 the first, beat 2 the next, beat 3 the last into the answer).
  const stages: XStage[] = [
    { beat: 0, at: 0, tree: trees[0]!.before },
    { beat: 0, at: 1.2, tree: trees[0]!.lit },
    ...trees.flatMap((s, i) => [
      { beat: i + 1, at: 0, tree: s.lit },
      { beat: i + 1, at: 1.2, tree: s.after },
    ]),
  ];
  const shape = t === 1 ? `(${a} + ${b}) × ${c} − ${d}` : t === 2 ? `${a} × ${b} − ${c} ÷ ${d}` : `${a} + ${b} × (${c} − ${d})`;
  return buildExprBoxes({ stages, header: shape, alt: `${shape} in nested boxes, one per operation; each box collapses into its value in turn: ${r0}, then ${r1}, then ${r2}.` });
}
