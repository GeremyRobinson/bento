import type { Rng } from "../../../generators/rng";
import { attempt, ints } from "../../_plane/kit";

/** ∫ from j to k of a·xⁿ dx, with a a multiple of n + 1 so the antiderivative's coefficient is whole. */
export interface DefIntProblem {
  kind: "integral.definitePower";
  n: number;
  a: number;
  /** the bottom bound (0 on the first problems and on problems saved before it existed) */
  j: number;
  k: number;
  /** a ÷ (n + 1), the antiderivative's coefficient */
  c: number;
  /** c·k^(n+1) − c·j^(n+1): the area */
  area: number;
}

export function createDefInt(n: number, a: number, k: number, j = 0): DefIntProblem {
  if (n < 1 || k < 1 || a === 0 || a % (n + 1)) throw new Error("need n ≥ 1, k ≥ 1 and a a multiple of n + 1");
  if (!(Number.isInteger(j) && j >= 0 && j < k)) throw new Error("the bottom bound is a whole number below the top");
  const c = a / (n + 1);
  return { kind: "integral.definitePower", n, a, j, k, c, area: c * k ** (n + 1) - c * j ** (n + 1) };
}

/**
 * The first three problems start at 0 with small numbers (n 1..2, a = (n + 1) × 1..2, k 1..3), so the bottom value is 0.
 * After that the bottom bound j is 1..k − 1 with k 2..4, so "F(top) − F(bottom)" really subtracts something.
 */
export function generateDefInt(rng: Rng, index = 0): DefIntProblem {
  if (index < 3) {
    const n = rng.int(1, 2);
    return createDefInt(n, (n + 1) * rng.int(1, 2), rng.int(1, 3));
  }
  const n = rng.int(1, 3), k = rng.int(2, 4);
  return createDefInt(n, (n + 1) * rng.int(1, 3), k, rng.int(1, k - 1));
}

export function restoreDefInt(raw: unknown): DefIntProblem | null {
  const r = ints(raw, ["n", "a", "k"] as const);
  const j = raw && typeof raw === "object" && typeof (raw as { j?: unknown }).j === "number" ? (raw as { j: number }).j : 0;
  return r && attempt(() => createDefInt(r.n, r.a, r.k, j));
}
