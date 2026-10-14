import { canShowMe, canSkip, hintBudget, lessonLength, tierFor } from "../../engine/adaptive-help/policy";
import { diagnose, nudge } from "../../engine/diagnosis/diagnose";
import { levelOf, problemXp, stepPoints } from "../../engine/mastery/levels";
import { parseNumber } from "../../engine/evaluation/numbers";

describe("scoring (same thresholds as the current app)", () => {
  it.each([[1, 4], [0.9, 4], [0.89, 3], [0.75, 3], [0.74, 2], [0.5, 2], [0.49, 1], [0.25, 1], [0.24, 0], [0, 0]])("%s of step points is a %s", (pct, lvl) => {
    expect(levelOf(pct)).toBe(lvl);
  });
  it("gives step points by how the step went", () => {
    expect(stepPoints({ shown: false, test: false, misses: 0, hinted: false })).toBe(1);
    expect(stepPoints({ shown: false, test: false, misses: 0, hinted: true })).toBe(0.5);
    expect(stepPoints({ shown: false, test: false, misses: 1, hinted: false })).toBe(0.5);
    expect(stepPoints({ shown: false, test: false, misses: 3, hinted: true })).toBe(0.25);
    expect(stepPoints({ shown: true, test: false, misses: 2, hinted: true })).toBe(0);
    expect(stepPoints({ shown: false, test: true, misses: 0, hinted: false })).toBe(1);
  });
  it("gives XP per problem", () => {
    expect(problemXp({ test: false, wrong: 0, hints: 0, shown: 0 })).toBe(15);
    expect(problemXp({ test: false, wrong: 0, hints: 1, shown: 0 })).toBe(12);
    expect(problemXp({ test: false, wrong: 2, hints: 1, shown: 0 })).toBe(10);
    expect(problemXp({ test: false, wrong: 2, hints: 1, shown: 1 })).toBe(5);
    expect(problemXp({ test: true, wrong: 0, hints: 0, shown: 0 })).toBe(15);
    expect(problemXp({ test: true, wrong: 1, hints: 0, shown: 0 })).toBe(5);
  });
});

describe("adaptive help", () => {
  it("fades with the last score", () => {
    expect([null, 0, 1, 2, 3, 4].map(tierFor)).toEqual([0, 0, 0, 1, 2, 2]);
  });
  it("starts longer after a low score, and budgets hints", () => {
    expect([null, 0, 1, 2, 4].map(lessonLength)).toEqual([6, 8, 8, 6, 6]);
    expect([8, 9, 10, 12].map(hintBudget)).toEqual([4, 5, 5, 6]);
  });
  it("opens Show me after two misses, or a miss after a hint, never in tests", () => {
    expect(canShowMe({ test: false, misses: 1, hinted: false })).toBe(false);
    expect(canShowMe({ test: false, misses: 2, hinted: false })).toBe(true);
    expect(canShowMe({ test: false, misses: 1, hinted: true })).toBe(true);
    expect(canShowMe({ test: true, misses: 5, hinted: true })).toBe(false);
  });
  it("offers final-answer-only at the top tier only", () => {
    expect(canSkip({ test: false, tier: 2 })).toBe(true);
    expect(canSkip({ test: false, tier: 1 })).toBe(false);
    expect(canSkip({ test: true, tier: 2 })).toBe(false);
  });
});

describe("mistake diagnosis", () => {
  const one = (want: number, typed: number, earlier: number[] = []) => diagnose({ x: want }, { x: typed }, earlier);
  it.each([
    [282, -282, "sign"], [1692, 1410, "reuse"], [1410, 141, "place"], [282, 283, "off1"],
    [282, 228, "digits"], [1692, 1700, "close"], [282, 9000, "method"],
  ] as const)("expected %s, typed %s: %s", (want, typed, cat) => {
    expect(one(want, typed, cat === "reuse" ? [1410, 282] : [])).toBe(cat);
  });
  it("spots swapped boxes and flipped fractions", () => {
    expect(diagnose({ p: 2, q: 5 }, { p: 5, q: 2 }, [])).toBe("swap");
    expect(diagnose({ n: 2, d: 3 }, { n: 3, d: 2 }, [])).toBe("flip");
  });
  it("nudges by size, in words that fit the age", () => {
    expect(nudge({ x: 10 }, { x: 12 }, "kid")).toBe("That's too big.");
    expect(nudge({ x: 10 }, { x: 8 }, "little")).toBe("Too few. Count again.");
  });
});

describe("number entry", () => {
  it("reads the keypad's minus sign and decimals", () => {
    expect(parseNumber("−12")).toBe(-12);
    expect(parseNumber("0.5")).toBe(0.5);
    expect(parseNumber("")).toBeNull();
    expect(parseNumber("−")).toBeNull();
  });
});
