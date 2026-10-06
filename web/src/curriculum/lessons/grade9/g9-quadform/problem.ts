import type { Rng } from "../../../generators/rng";
import { attempt, ints } from "../../_plane/kit";

/** x² + b·x + c = 0 built from its two roots, so the discriminant is always a perfect square. */
export interface QuadFormProblem {
  kind: "quadratic.formula";
  r1: number;
  r2: number;
  b: number;
  c: number;
  /** b² − 4ac with a = 1 */
  D: number;
}

export function createQuadForm(r1: number, r2: number): QuadFormProblem {
  if (r1 === r2) throw new Error("the two roots must differ");
  const b = -(r1 + r2), c = r1 * r2;
  return { kind: "quadratic.formula", r1, r2, b, c, D: b * b - 4 * c };
}

/** Same ranges as the current app: two different roots from −8 to 8. */
/** Roots −8..8, different; the first three problems have no root at 0, so c is never 0 (no "x² − x = 0"). */
export function generateQuadForm(rng: Rng, index = 3): QuadFormProblem {
  let r1: number, r2: number;
  do { r1 = rng.int(-8, 8); r2 = rng.int(-8, 8); } while (r1 === r2 || (index < 3 && r1 * r2 === 0));
  return createQuadForm(r1, r2);
}

export function restoreQuadForm(raw: unknown): QuadFormProblem | null {
  const v = ints(raw, ["r1", "r2"] as const);
  return v && attempt(() => createQuadForm(v.r1, v.r2));
}
