import { describe, expect, it } from "vitest";
import { spoken } from "../../app/settings";

// Read aloud says symbols the way a teacher says them (Copy rewrites-05, G 2026-10-14); the screen text is unchanged
describe("read aloud speaks symbols as words", () => {
  it.each([
    ["3/4 of 12", "3 over 4 of 12"],
    ["2⁵ = 32", "2 to the power 5 = 32"],
    ["x² + 1", "x squared + 1"],
    ["log₂ 8", "log base 2 of 8"],
    ["aₙ = a₁ + (n − 1)d", "a sub n = a sub 1 + (n minus 1)d"],
    ["f′(x)", "f prime(x)"],
    ["√25 = 5", "the square root of 25 = 5"],
    ["sin 30° = 1/2", "sine 30 degrees = 1 over 2"],
    ["7 × 8 − 3 ÷ 1", "7 times 8 minus 3 divided by 1"],
    ["π/6", "pi over 6"],
    ["2^10", "2 to the power 10"],
  ])("%s", (t, said) => expect(spoken(t)).toBe(said));
});
