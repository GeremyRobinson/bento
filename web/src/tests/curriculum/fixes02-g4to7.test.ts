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

// Review v43 items 10 and 13: a worked line says something new ("2/3 = 2/3", "R 0", "+ 0" teach nothing)
const plain = (v: any): string => v == null ? "" : typeof v === "string" || typeof v === "number" ? String(v) : Array.isArray(v) ? v.map(plain).join("")
  : v.t === "frac" ? `${plain(v.n)}/${plain(v.d)}` : v.t === "op" ? ` ${v.v} ` : plain(v.v);
describe("worked lines in grades 4 to 7 say something", () => {
  const ids = ["g4-partial", "g4-divide", "g4-fracwhole", "g5-divide", "g6-divide", "g7-prob", "g4-lines"];
  it.each(ids)("%s", id => {
    const l = L(id), bad: string[] = [];
    for (const { p } of many(id, 200)) {
      const e = l.explain(p, l.answers(p));
      for (const s of e.steps) {
        const t = plain(s.math).replace(/\s+/g, " ").trim(), sides = t.split(" = ");
        if (sides.length > 1 && new Set(sides).size < sides.length) bad.push(t);
        if (/\+ 0\b|R 0\b|\b1 of them are\b|\b1 endpoints\b/.test(`${t} ${s.narration} ${e.caption ?? ""}`)) bad.push(`${t} | ${s.narration}`);
        if (/^(\d+) ÷ (\d+) = (\d+)\.$/.test(s.narration)) bad.push(s.narration);
      }
    }
    expect(bad.slice(0, 3)).toEqual([]);
  });
});
