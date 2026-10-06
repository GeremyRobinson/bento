// Curriculum fixes-02 (2026-10-06), grades 4 to 7: the content bugs, generator and slip fixes and lesson rewrites,
// each checked on generated problems so they can't come back.
import { describe, expect, it } from "vitest";
import { lessonById } from "../../curriculum/registry";
import { createRng } from "../../curriculum/generators/rng";
import type { AnswerStep, LessonDefinition } from "../../curriculum/schemas/lesson";

/* eslint-disable @typescript-eslint/no-explicit-any */
const L = (id: string) => lessonById(id) as LessonDefinition<any>;
const many = (id: string, n = 300) => { const l = L(id), rng = createRng(47); return Array.from({ length: n }, (_, i) => ({ i: i % 10, p: l.generate(rng, i % 10) })); };
const step = (id: string, p: any, sid: string) => L(id).answers(p).steps.find(s => s.id === sid) as AnswerStep;

describe("content bugs", () => {
  it("g4-likefrac: one pizza never holds more than one whole", () => {
    for (const { p } of many("g4-likefrac")) {
      const t = L("g4-likefrac").story!(p).text;
      if (p.a + p.c > p.d) expect(t, t).not.toContain("the same pizza");
    }
  });
  it("g6-divide: a whole answer gets no 'remainder 0' hint", () => {
    const l = L("g6-divide"), p = l.restore({ a: 2, b: 3, c: 1, d: 3 })!; // 6/3 = 2
    const s = step("g6-divide", p, "simplify");
    expect(s.hint).toBe("6 ÷ 3 = 2 exactly, so it's a whole number.");
    for (const { p: q } of many("g6-divide")) expect(step("g6-divide", q, "simplify").hint).not.toMatch(/remainder 0/);
  });
});
