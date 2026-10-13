import type { Rng } from "../../../generators/rng";
import { splitByPlaceValue } from "../../../generators/place-value";

/**
 * The canonical model for 47 × 36 = (40 + 7) × (30 + 6): both numbers split into tens and ones, four parts
 * (v2 model, G 2026-10-13: "the preview doesn't look like the model").
 * This object is the only source of truth: the answer model, diagram, narration,
 * answer checks and animation are all computed from it.
 */
export interface SplitMultiplicationProblem {
  kind: "multiply.splitAreaModel";
  /** runs across the top */
  firstFactor: number;
  /** runs down the side */
  secondFactor: number;
  strategy: "splitBoth";
  /** place-value parts of firstFactor, biggest first: the columns */
  firstParts: number[];
  /** place-value parts of secondFactor, biggest first: the rows */
  secondParts: number[];
  /** one per part, row by row (each row of secondParts, then each column of firstParts): the order the steps ask them */
  cells: { first: number; second: number }[];
  /** cells[i].first × cells[i].second */
  partialProducts: number[];
  /** firstFactor × secondFactor, which is also the sum of partialProducts */
  product: number;
}

export function createSplitMultiplication(firstFactor: number, secondFactor: number): SplitMultiplicationProblem {
  for (const [name, v] of [["firstFactor", firstFactor], ["secondFactor", secondFactor]] as const) {
    if (!Number.isInteger(v) || v <= 0) throw new Error(`${name} must be a positive whole number, got ${v}`);
  }
  const firstParts = splitByPlaceValue(firstFactor), secondParts = splitByPlaceValue(secondFactor);
  const cells = secondParts.flatMap(second => firstParts.map(first => ({ first, second })));
  const partialProducts = cells.map(c => c.first * c.second);
  return {
    kind: "multiply.splitAreaModel",
    firstFactor,
    secondFactor,
    strategy: "splitBoth",
    firstParts,
    secondParts,
    cells,
    partialProducts,
    product: partialProducts.reduce((a, b) => a + b, 0),
  };
}

/** Both factors 12–98 and neither a multiple of ten, so every problem has its four parts. */
export function generateSplitMultiplication(rng: Rng, index = 3): SplitMultiplicationProblem {
  // the first three are friendlier: 12–39 times 12–29
  const early = index < 3;
  const pick = (hi: number) => { for (;;) { const n = rng.int(12, hi); if (n % 10) return n; } };
  const first = pick(early ? 39 : 98);
  return createSplitMultiplication(first, pick(early ? 29 : 98));
}

/** Every rule the model must satisfy. An empty list means the problem is sound. */
export function checkInvariants(p: SplitMultiplicationProblem): string[] {
  const errors: string[] = [];
  const sum = (xs: number[]) => xs.reduce((a, b) => a + b, 0);
  if (p.strategy !== "splitBoth") errors.push("unknown strategy");
  if (sum(p.firstParts) !== p.firstFactor) errors.push("parts do not add up to the first factor");
  if (sum(p.secondParts) !== p.secondFactor) errors.push("parts do not add up to the second factor");
  if ([...p.firstParts, ...p.secondParts].some(x => x <= 0)) errors.push("a part is not positive");
  if (p.cells.length !== p.firstParts.length * p.secondParts.length) errors.push("one part per column and row");
  p.cells.forEach((c, i) => {
    if (p.partialProducts[i] !== c.first * c.second) errors.push(`partial product ${i} is not first part × second part`);
  });
  if (p.partialProducts.length !== p.cells.length) errors.push("one partial product per part");
  if (sum(p.partialProducts) !== p.product) errors.push("partial products do not add up to the product");
  if (p.product !== p.firstFactor * p.secondFactor) errors.push("product is not firstFactor × secondFactor");
  return errors;
}

/** Accepts a stored model, or the current app's saved {a, b}, and rebuilds it from its factors. */
export function restoreSplitMultiplication(raw: unknown): SplitMultiplicationProblem | null {
  if (!raw || typeof raw !== "object") return null;
  const r = raw as Record<string, unknown>;
  const first = r.firstFactor ?? r.a, second = r.secondFactor ?? r.b;
  if (typeof first !== "number" || typeof second !== "number") return null;
  try {
    return createSplitMultiplication(first, second);
  } catch {
    return null;
  }
}
