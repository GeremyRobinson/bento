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

describe("weakest lessons, rewritten to the fixes-02 drafts", () => {
  it("g6-divide: first sizes the answer; the first problems divide by a unit fraction that fits more than once", () => {
    for (const { i, p } of many("g6-divide")) {
      const s = step("g6-divide", p, "size"), more = p.a * p.d > p.b * p.c;
      expect(s.slots[0]!.expected).toBe(more ? 0 : 1);
      expect(kindOf(s, { c: more ? 1 : 0 })).toBe("Compared the wrong way");
      if (i < 3) { expect(p.c).toBe(1); expect(more).toBe(true); }
    }
    expect(L("g6-divide").pre).toBe("g5-unitdiv");
  });
  it("g5-multdec: the places answer is 1, then 2, then 3, and a misplaced point is named", () => {
    const by = new Map<number, Set<number>>();
    for (const { i, p } of many("g5-multdec")) {
      const places = step("g5-multdec", p, "places").slots[0]!.expected!;
      by.set(i, (by.get(i) ?? new Set()).add(places));
      const place = step("g5-multdec", p, "place"), ans = place.slots[0]!.expected!;
      expect(kindOf(place, { x: Math.round(ans * 10 * 1e6) / 1e6 })).toBe("Point in the wrong place");
    }
    expect([...by.get(0)!]).toEqual([1]); expect([...by.get(4)!]).toEqual([2]); expect([...by.get(8)!]).toEqual([3]);
  });
  it("g5-order: the first step asks what goes first, and left to right is a named slip", () => {
    const p = L("g5-order").reference; // 3 + 4 × (6 − 2)
    const s = step("g5-order", p, "first");
    expect(s.choices).toEqual(["3 + 4", "4 × 6", "6 − 2"]);
    expect(kindOf(s, { c: 0 })).toBe("Worked left to right");
    expect(kindOf(s, { c: 2 })).toBe("ok");
  });
  it("g6-expo: counts the factors first, and adding before multiplying is named on the whole expression", () => {
    const p = L("g6-expo").reference; // 2³ + 4 × 3
    expect(step("g6-expo", p, "count").slots[0]!.expected).toBe(3);
    expect(kindOf(step("g6-expo", p, "count"), { x: 2 })).toBe("Read the base");
    expect(kindOf(step("g6-expo", p, "add"), { x: (8 + 4) * 3 })).toBe("Added before multiplying");
  });
  it("g7-prop: one part, then x; later problems may have a half for one part", () => {
    const p = L("g7-prop").reference; // 3/4 = x/20
    expect(step("g7-prop", p, "cross").slots[0]!.expected).toBe(5);
    expect(kindOf(step("g7-prop", p, "cross"), { x: 16 })).toBe("Added instead of scaled");
    const halves = many("g7-prop").filter(({ p: q }) => !Number.isInteger(q.k));
    expect(halves.length).toBeGreaterThan(0);
    for (const { i, p: q } of halves) { expect(i).toBeGreaterThanOrEqual(4); expect(Number.isInteger(q.a * q.k)).toBe(true); }
    expect(L("g7-prop").restore({ a: 6, b: 4, k: 2.5 })).toEqual({ a: 6, b: 4, k: 2.5 });
  });
  it("g5-units: small to big divides, and more-or-fewer is asked", () => {
    const l = L("g5-units"), p = l.restore({ u: "meter", n: 250, up: true })!;
    const m = l.answers(p);
    expect(m.steps.at(-1)!.slots[0]!.expected).toBe(2.5);
    expect(kindOf(m.steps.find(s => s.id === "more")!, { c: 0 })).toBe("Bigger units, more of them");
    expect(l.restore({ u: ["foot", "feet", "inches", 12], n: 3 })).toEqual(l.reference);
    expect(many("g5-units").some(({ p: q }) => q.up)).toBe(true);
  });
  it("g4-angles: the missing part is asked as an addition, and the wrong whole is named", () => {
    const p = L("g4-angles").reference; // 35° + ? = 90°
    const s = step("g4-angles", p, "missing");
    expect(kindOf(s, { x: 145 })).toBe("Used the wrong whole");
    for (const { i, p: q } of many("g4-angles")) if (i < 3) expect(q.a % 10).toBe(0);
  });
  it("g4-lineplot: sprouts are tall, and reading the next mark is named", () => {
    for (const { p } of many("g4-lineplot")) {
      const qs = L("g4-lineplot").answers(p).steps.map(s => s.question ?? "").join(" ");
      if (p.thing === 2) expect(qs).not.toMatch(/\blong(est)?\b|seed/);
    }
    const p = L("g4-lineplot").reference, s = step("g4-lineplot", p, "max"); // longest 7/4 = 1 3/4
    expect(kindOf(s, { w: 1, n: 2, d: 4 })).toBe("Read the next mark");
  });
  it("g7-subint and g6-pctof: the new slips are named", () => {
    expect(kindOf(step("g7-subint", L("g7-subint").reference, "add"), { x: -8 })).toBe("Wrong sign");
    expect(kindOf(step("g6-pctof", L("g6-pctof").reference, "scale"), { x: 56 })).toBe("Found what's left");
  });
  it("g4-deccompare: the first number is always part colour 0 and the second part colour 2", () => {
    const l = L("g4-deccompare");
    for (const { p } of many("g4-deccompare", 60)) {
      const d = l.explain(p, l.answers(p)).diagram as { items: { type: string; x?: number; cls?: string }[] };
      const shaded = d.items.filter(it => it.type === "rect" && /\bon\b/.test(it.cls ?? ""));
      // the two grids' outlines: a rect from the second one's left edge on belongs to the second number
      const second = Math.max(...d.items.filter(it => it.type === "rect" && it.cls === "seg").map(it => it.x!));
      for (const r of shaded) expect(r.cls).toMatch(r.x! < second - 0.5 ? /\bp0\b/ : /\bp2\b/);
      expect(d.items.filter(it => /\bp1\b/.test(it.cls ?? ""))).toEqual([]);
    }
  });
});

describe("fixes-02 Order, grades 4 to 7", () => {
  it("puts each lesson after the one it builds on", async () => {
    const { CATALOG } = await import("../../curriculum/catalog");
    const at = (id: string) => CATALOG.findIndex(c => c.id === id);
    const before = (a: string, b: string) => expect(at(a), `${a} before ${b}`).toBeLessThan(at(b));
    before("g4-lines", "g4-angles"); before("g4-angles", "g4-symmetry"); before("g4-equiv", "g4-fraccompare"); before("g4-fraccompare", "g4-likefrac");
    before("g5-fracof", "g5-multfrac"); before("mix", "g5-fracof"); before("g5-multfrac", "g5-unitdiv"); before("g6-lcm", "g6-gcf");
    expect(CATALOG.find(c => c.id === "g4-angles")!.unit).toBe("Lines and shapes");
    // every grade 4-7 pre is a lesson that comes earlier
    for (const c of CATALOG.filter(c => c.grade >= 4 && c.grade <= 7 && c.pre)) before(c.pre!, c.id);
  });
});
