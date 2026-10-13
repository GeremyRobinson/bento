import type { Rng } from "../../../generators/rng";
import { splitByPlaceValue } from "../../../generators/place-value";

/**
 * The canonical model for 47 × 36 = 47 × (30 + 6).
 * This object is the only source of truth: the answer model, diagram, narration,
 * answer checks and animation are all computed from it.
 */
export interface SplitMultiplicationProblem {
  kind: "multiply.splitAreaModel";
  /** owns the vertical axis */
  firstFactor: number;
  /** owns the horizontal axis and is the factor that gets split */
  secondFactor: number;
  strategy: "splitSecondFactor";
  /** place-value parts of secondFactor, biggest first; they add up to secondFactor */
  parts: number[];
  /** firstFactor × parts[i] */
  partialProducts: number[];
  /** firstFactor × secondFactor, which is also the sum of partialProducts */
  product: number;
}

export function createSplitMultiplication(firstFactor: number, secondFactor: number): SplitMultiplicationProblem {
  for (const [name, v] of [["firstFactor", firstFactor], ["secondFactor", secondFactor]] as const) {
    if (!Number.isInteger(v) || v <= 0) throw new Error(`${name} must be a positive whole number, got ${v}`);
  }
  const parts = splitByPlaceValue(secondFactor);
  const partialProducts = parts.map(part => firstFactor * part);
  return {
    kind: "multiply.splitAreaModel",
    firstFactor,
    secondFactor,
    strategy: "splitSecondFactor",
    parts,
    partialProducts,
    product: partialProducts.reduce((a, b) => a + b, 0),
  };
}

/** Same ranges as the current app: both factors 12–98, and the second never a multiple of ten. */
export function generateSplitMultiplication(rng: Rng, index = 3): SplitMultiplicationProblem {
  // the first three are friendlier: 12–39 times 12–29
  const early = index < 3;
  let second: number;
  do second = rng.int(12, early ? 29 : 98);
  while (second % 10 === 0);
  return createSplitMultiplication(rng.int(12, early ? 39 : 98), second);
}

/** Every rule the model must satisfy. An empty list means the problem is sound. */
export function checkInvariants(p: SplitMultiplicationProblem): string[] {
  const errors: string[] = [];
  const sum = (xs: number[]) => xs.reduce((a, b) => a + b, 0);
  if (p.strategy !== "splitSecondFactor") errors.push("unknown strategy");
  if (sum(p.parts) !== p.secondFactor) errors.push("parts do not add up to the second factor");
  if (p.parts.some(x => x <= 0)) errors.push("a part is not positive");
  p.parts.forEach((part, i) => {
    if (p.partialProducts[i] !== p.firstFactor * part) errors.push(`partial product ${i} is not firstFactor × part`);
  });
  if (p.partialProducts.length !== p.parts.length) errors.push("one partial product per part");
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
