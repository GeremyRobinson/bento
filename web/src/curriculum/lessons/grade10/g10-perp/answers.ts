import { frac, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { fs } from "../../_plane/kit";
import type { PerpProblem } from "./problem";

/** p/r without its sign: 2/3, or 3 when r is 1 */
export const sizeOf = ({ p, r }: PerpProblem): MathText => (r === 1 ? [num(Math.abs(p))] : [frac(Math.abs(p), r)]);
/** the slope with its sign: −2/3 */
export const slopeMath = (q: PerpProblem): MathText => (q.r === 1 ? [num(q.p)] : [...(q.p < 0 ? [text("−")] : []), ...sizeOf(q)]);

export function perpAnswers(q: PerpProblem): AnswerModel {
  const { p, r } = q, ap = Math.abs(p);
  return {
    steps: [
      fs({ id: "flip", label: "Flip it", prompt: s => [text("flip "), ...sizeOf(q), op("→"), ...s], N: r, D: ap,
        note: "Ignore the sign for now and flip top and bottom.", hint: "A quarter turn swaps the rise and the run, so the top and bottom trade places.",
        wrong: ap !== r ? [[ap, r, "Didn't flip", "Turning a line a quarter turn swaps rise and run: the bottom goes on top."]] : [] }),
      fs({ id: "perp", label: "Change the sign", prompt: s => [text("perpendicular slope"), op("="), ...s], N: p > 0 ? -r : r, D: ap,
        hint: "Perpendicular slopes have opposite signs.", note: "Opposite sign, flipped. Put any minus sign on top.",
        wrong: [[p > 0 ? r : -r, ap, "Forgot to change the sign", "Perpendicular means flip **and** change the sign."]] }),
    ],
    finalParts: [-1],
  };
}
