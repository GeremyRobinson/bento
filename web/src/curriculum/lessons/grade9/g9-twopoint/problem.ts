import type { Rng } from "../../../generators/rng";
import { attempt, ints, nz } from "../../_plane/kit";

/** The line y = m·x + b through the points at x1 and x2. */
export interface TwoPointProblem {
  kind: "line.twoPoints";
  m: number;
  b: number;
  x1: number;
  x2: number;
  y1: number;
  y2: number;
}

export function createTwoPoint(m: number, b: number, x1: number, x2: number): TwoPointProblem {
  if (x1 === x2) throw new Error("the two points need different x");
  if (m === 0) throw new Error("the slope must not be 0");
  return { kind: "line.twoPoints", m, b, x1, x2, y1: m * x1 + b, y2: m * x2 + b };
}

/** Same ranges as the current app: m ±1..4, b −8..8, x1 −4..2, x2 1..4 to the right of it. */
export function generateTwoPoint(rng: Rng): TwoPointProblem {
  // neither point on the y-axis, where the rise would be drawn over the axis
  const m = nz(rng, -4, 4), b = rng.int(-8, 8);
  let x1: number, x2: number;
  do { x1 = rng.int(-4, 2); x2 = x1 + rng.int(1, 4); } while (x1 === 0 || x2 === 0);
  return createTwoPoint(m, b, x1, x2);
}

export function restoreTwoPoint(raw: unknown): TwoPointProblem | null {
  const r = ints(raw, ["m", "b", "x1", "x2"] as const);
  return r && attempt(() => createTwoPoint(r.m, r.b, r.x1, r.x2));
}
