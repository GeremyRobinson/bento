// Review v43 item 3: dividing −27 by −3 said "different signs, so the answer is negative: 9". The words about the
// signs must name the numbers on screen and agree with the answer's own sign, for both × and ÷.
import { describe, expect, it } from "vitest";
import { createMulIntegers, lesson } from "../../curriculum/lessons/grade7/g7-mulint";
import { createRng } from "../../curriculum/generators/rng";

const signWords = (a: number, b: number, div: boolean) => {
  const p = createMulIntegers(a, b, div), e = lesson.explain(p, lesson.answers(p));
  return { narration: e.steps.find(s => s.id === "sign")!.narration, caption: e.caption ?? "", ans: div ? a : a * b };
};

describe("g7-mulint names the right sign", () => {
  it("−27 ÷ (−3) is positive: same signs", () => {
    const w = signWords(9, -3, true);
    expect(w.narration).toContain("same sign");
    expect(w.narration).toContain("positive: 9");
    expect(w.caption).toContain("positive");
  });
  it("27 ÷ (−3) is negative: different signs", () => {
    const w = signWords(-9, -3, true);
    expect(w.narration).toContain("different signs");
    expect(w.narration).toContain("negative: −9");
  });
  it("agrees with the answer on every generated problem", () => {
    const rng = createRng(47);
    for (let i = 0; i < 400; i++) {
      const p = lesson.generate(rng, i % 10), w = signWords(p.a, p.b, p.div);
      expect(w.narration.includes("negative"), `${JSON.stringify(p)}: ${w.narration}`).toBe(w.ans < 0);
      expect(w.caption.includes("negative"), `${JSON.stringify(p)}: ${w.caption}`).toBe(w.ans < 0);
    }
  });
});
