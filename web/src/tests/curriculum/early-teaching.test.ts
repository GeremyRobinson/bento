// Curriculum's teaching-quality pass for kindergarten to grade 3 (fixes-02, Part C): the content bugs it found stay
// fixed, and the rewritten lessons keep the behaviour their drafts ask for.
import { LESSONS, requireLesson } from "../../curriculum/registry";
import { createRng } from "../../curriculum/generators/rng";
import { checkAnswerStep } from "../../engine/evaluation/steps";
import { MASS_THINGS, gramsOf, guesses } from "../../curriculum/lessons/grade3/g3-mass";

/* eslint-disable @typescript-eslint/no-explicit-any */
const many = (id: string, n = 200, seed = 5) => {
  const l = requireLesson(id), rng = createRng(seed);
  return Array.from({ length: n }, (_, i) => { const p = l.generate(rng, i % 10) as any; return { i: i % 10, p, m: l.answers(p) }; });
};
const tapMessage = (step: any, i: number) => { const r = checkAnswerStep(step, { c: i }); return r.ok ? null : r.message; };

describe("g3-mass: the best-guess step tells the truth", () => {
  it("every too-light guess is lighter than the right one, and every other wrong guess heavier", () => {
    MASS_THINGS.forEach((_, t) => {
      const g = guesses(t), right = gramsOf(g.labels[g.right]!);
      if (g.small >= 0) expect(gramsOf(g.labels[g.small]!), MASS_THINGS[t]!.name).toBeLessThan(right);
      g.labels.forEach((l, i) => { if (i !== g.right && i !== g.small) expect(gramsOf(l), `${l} for ${MASS_THINGS[t]!.name}`).toBeGreaterThan(right); });
    });
  });
  it("a gram thing has no too-light guess, and its wrong guesses say too heavy", () => {
    const lesson = requireLesson("g3-mass");
    MASS_THINGS.forEach((th, t) => {
      const p = lesson.restore({ kind: 0, thing: t, unit: 0, step: 1, value: 0, op: 0, a: 0, b: 0, who: 0 })!, step = lesson.answers(p).steps[1]!;
      const g = guesses(t);
      g.labels.forEach((l, i) => {
        if (i === g.right) return;
        const msg = tapMessage(step, i)!;
        if (!th.kg) expect(msg, `${l} for a ${th.name}`).toMatch(/heavy as .*much lighter/);
        else if (i === g.small) expect(msg, `${l} for a ${th.name}`).toMatch(/light as .*much heavier/);
        expect(msg).not.toMatch(/handful of paper clips/);
      });
    });
  });
});

describe("g3-facts: early problems turn around into something new", () => {
  it("problems 0 to 2 never multiply a number by itself", () => {
    for (const { i, p } of many("g3-facts", 600)) if (i < 3) expect(p.a, JSON.stringify(p)).not.toBe(p.b);
  });
  it("a square has no turn-it-around step", () => {
    const l = requireLesson("g3-facts"), p = l.restore({ a: 6, b: 6 })!;
    expect(l.answers(p).steps.map(s => s.id)).toEqual(["count"]);
    expect(l.answers(l.restore({ a: 6, b: 4 })!).steps.map(s => s.id)).toEqual(["count", "turn"]);
  });
});

describe("worked lines read right in kindergarten to grade 3 (v43: \"1 halves\")", () => {
  const plain = (v: unknown): string => {
    if (v == null) return "";
    if (typeof v === "string" || typeof v === "number") return String(v);
    if (Array.isArray(v)) return v.map(plain).join("");
    const o = v as { t?: string; v?: unknown; n?: unknown; d?: unknown };
    if (o.t === "frac") return `${plain(o.n)}/${plain(o.d)}`;
    if (o.t === "op") return ` ${plain(o.v)} `;
    if (o.t === "slot") return "[ ]";
    if (o.t === "br") return " | ";
    return plain(o.v);
  };
  const OK = new Set(["is", "plus", "minus", "less", "times", "equals", "makes", "was", "has", "goes", "gets", "means", "stays"]);
  it.each(LESSONS.filter(l => l.grade <= 3).map(l => [l.id, l] as const))("%s", (_id, lesson) => {
    const rng = createRng(13), bad = new Set<string>();
    for (let i = 0; i < 60; i++) {
      const p = lesson.generate(rng, i % 10), m = lesson.answers(p);
      for (const s of m.steps) {
        const line = plain(s.work).replace(/\s+/g, " ");
        for (const x of line.matchAll(/(?<![\d.,/\-−^])\b1 ([a-z]+s)\b/g)) if (!OK.has(x[1]!)) bad.add(`${s.id}: ${line}`);
      }
    }
    expect([...bad].slice(0, 5)).toEqual([]);
  });
});
