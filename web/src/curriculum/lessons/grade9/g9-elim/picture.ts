// The g9-elim picture (Curriculum fixes-02, Part B): each equation is a level balance. Adding the two equations puts
// both left sides on one pan and both right sides on the other; + y and − y cancel, and only x is left. Then halve both
// pans, and put x back into the first balance to read y. Built on the balance, with a y tile.
import { block, buildBalance, xTiles, type Weight } from "../../../../explanations/diagrams/algebra/balance";
import type { SceneDiagram } from "../../../../explanations/diagrams/scene/schema";
import { formatNumber as f } from "../../../schemas/math-text";

const Y = (neg = false, off = false): Weight => ({ kind: "y", ...(neg ? { neg } : {}), ...(off ? { off } : {}) });

export function eliminationPicture(o: { sum: number; difference: number; twoX: number; x: number; y: number }): SceneDiagram {
  const { sum, difference, twoX, x, y } = o;
  return buildBalance([
    { left: [[...xTiles(1), Y()]], right: [[block(sum)]], note: `x + y = ${f(sum)}` },
    { left: [[...xTiles(1), Y(true)]], right: [[block(difference)]], note: `x − y = ${f(difference)}` },
    {
      left: [[...xTiles(1), Y(false, true)], [...xTiles(1), Y(true, true)]],
      right: [[block(sum, { off: true }), block(difference, { off: true })], [block(twoX, { late: true, added: true })]],
      note: `add them: y and −y cancel, 2x = ${f(twoX)}`,
    },
    { left: [xTiles(1), xTiles(1, true)], right: [[block(twoX, { off: true })], [block(x, { late: true, added: true })]], note: `halve both pans: x = ${f(x)}` },
    { left: [[block(x, { off: true }), Y()]], right: [[block(sum, { off: true })], [block(y, { late: true, added: true })]], note: `take ${f(x)} off both pans: y = ${f(y)}` },
  ], `Two balances, x + y = ${f(sum)} and x − y = ${f(difference)}. Put together, y and −y cancel: 2x = ${f(twoX)}, so x = ${f(x)}. Back in the first, y = ${f(y)}.`);
}
