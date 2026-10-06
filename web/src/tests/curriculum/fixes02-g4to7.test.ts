// Curriculum fixes-02 (2026-10-06), grades 4 to 7: the content bugs, generator and slip fixes and lesson rewrites,
// each checked on generated problems so they can't come back.
import { describe, expect, it } from "vitest";
import { lessonById } from "../../curriculum/registry";
import { createRng } from "../../curriculum/generators/rng";
import type { AnswerStep, LessonDefinition } from "../../curriculum/schemas/lesson";
import { checkAnswerStep } from "../../engine/evaluation/steps";

/* eslint-disable @typescript-eslint/no-explicit-any */
const L = (id: string) => lessonById(id) as LessonDefinition<any>;
const many = (id: string, n = 300) => { const l = L(id), rng = createRng(47); return Array.from({ length: n }, (_, i) => ({ i: i % 10, p: l.generate(rng, i % 10) })); };
const kindOf = (s: AnswerStep, v: Record<string, number | null>) => { const r = checkAnswerStep(s, v); return r.ok ? "ok" : r.soft ? "soft" : r.kind; };
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

describe("Part A generator and slip fixes", () => {
  it("A1 g4-partial: never a whole number of hundreds; a 0 place says so; leaving out a part is named", () => {
    for (const { p } of many("g4-partial")) expect(p.n % 100).not.toBe(0);
    const p = L("g4-partial").restore({ n: 502, m: 7 })!;
    expect(step("g4-partial", p, "tens").hint).toBe("There are no tens, so this part is 0.");
    const q = L("g4-partial").restore({ n: 346, m: 7 })!;
    expect(kindOf(step("g4-partial", q, "sum"), { x: 2100 + 280 })).toBe("Left out a part");
  });
  it("A2 g5-round: rounding to the other place is named, and problem 6 always rolls a 9 over", () => {
    const p = L("g5-round").restore({ N: 51647, p: 2 })!;
    expect(kindOf(step("g5-round", p, "round"), { x: 51.6 })).toBe("Rounded to the wrong place");
    for (const { i, p: q } of many("g5-round")) {
      if (i !== 5) continue;
      const unit = 10 ** (3 - q.p), T = Math.floor(q.N / unit);
      expect(T % 10, JSON.stringify(q)).toBe(9);
      expect(Math.round(q.N / unit) % 10, JSON.stringify(q)).toBe(0);
    }
    const roll = L("g5-round").restore({ N: 4960, p: 1 })!;
    expect(kindOf(step("g5-round", roll, "round"), { x: 5 })).toBe("ok");
    expect(kindOf(step("g5-round", roll, "round"), { x: 5.0 })).toBe("ok");
  });
  it("A3 g5-volume: boxes fit a phone, early ones can be counted, and the layers note waits for the last layer", () => {
    for (const { i, p } of many("g5-volume")) {
      const top = i < 3 ? [5, 5, 5] : [8, 8, 6];
      expect([p.l, p.w, p.h].every((v: number, k: number) => v >= 2 && v <= top[k]!), JSON.stringify(p)).toBe(true);
      const d: any = L("g5-volume").explain(p, L("g5-volume").answers(p)).diagram;
      const items: any[] = d.items;
      const note = items.find(x => typeof x.text === "string" && /layers:/.test(x.text));
      const cubes = items.filter(x => x !== note && typeof x.from === "number");
      expect(note).toBeTruthy();
      expect(note.from).toBeGreaterThanOrEqual(Math.max(...cubes.map(x => x.from)));
    }
  });
  it("A6 g7-circarea: the circumference and the diameter squared are named slips", () => {
    const p = L("g7-circarea").restore({ r: 5 })!, s = step("g7-circarea", p, "times-pi");
    expect(kindOf(s, { x: 31.4 })).toBe("Used the circumference");
    expect(kindOf(s, { x: 314 })).toBe("Squared the diameter");
  });
});
