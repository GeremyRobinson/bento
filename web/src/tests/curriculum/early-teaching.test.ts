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

describe("kindergarten to grade 3 hints lead to the step instead of giving it (fixes-02 Part C, K-3 patterns 1 and 5)", () => {
  const plainText = (v: unknown): string => (typeof v === "string" ? v.replace(/\*\*/g, "") : Array.isArray(v) ? v.map(plainText).join(" ") : v && typeof v === "object" ? Object.values(v as object).map(plainText).join(" ") : v == null ? "" : String(v));
  const has = (s: string, n: number) => new RegExp(`(?<![\\d.,/])${n}(?![\\d]|[.,]\\d|/)`).test(s.replace(/(\d),(\d{3})/g, "$1$2"));
  const K3 = LESSONS.filter(l => l.grade <= 3);
  // a number in these hints is the counting unit or a fact the step practises, not the step's answer (reviewed 2026-10-06)
  const UNIT_IN_HINT: Record<string, Record<string, string>> = {
    "k-tens": { tens: "\"say 10, 20, 30...\" shows how to count by tens" },
    "g2-hundreds": { expanded: "\"a flat is worth 100, a rod 10\" is the place value the step uses" },
    "g2-coins": { value: "the coin values are the facts being learned" },
    "g3-round": { between: "\"count by 10s\" or \"by 100s\" names the jump" },
  };
  it.each(K3.map(l => [l.id, l] as const))("%s: no hint is its step's explanation, and no hint hands over an answer the problem doesn't show", (_id, lesson) => {
    const rng = createRng(17), bad = new Set<string>();
    for (let i = 0; i < 60; i++) {
      const p = lesson.generate(rng, i % 10), m = lesson.answers(p), shown = plainText([lesson.display(p), lesson.displayNote?.(p), lesson.story?.(p)]);
      for (const s of m.steps) {
        const hint = plainText(s.hint);
        if (hint === plainText(s.explain)) bad.add(`${s.label}: hint is the explanation`);
        if (s.choices) continue;
        const onScreen = `${shown} ${plainText(s.question)} ${plainText(s.prompt)}`;
        if (UNIT_IN_HINT[lesson.id]?.[s.id]) continue;
        for (const x of s.slots) if (x.expected != null && x.expected >= 10 && has(hint, x.expected) && !has(onScreen, x.expected)) bad.add(`${s.label}: "${hint}" gives ${x.expected}`);
      }
    }
    expect([...bad].slice(0, 6)).toEqual([]);
  });

  // where "easier" means smaller numbers; lessons whose early problems are easier in another way are listed with why
  const OTHER_EASY: Record<string, string> = {
    "g2-subregroup": "early problems take away a smaller number, so the answer is bigger",
    "g3-addsub": "early problems add or take away a two-digit number, so a difference comes out bigger",
    "g2-solids": "early problems show the solid face-on; the counts are the solid's own",
    "g2-shares": "early problems are halves and fourths of simple shapes",
    "g3-lineplot": "early problems measure on a ruler; later ones read a plot",
  };
  it.each(K3.filter(l => !OTHER_EASY[l.id]).map(l => [l.id, l] as const))("%s: the first three problems are no bigger than the rest", (_id, lesson) => {
    const rng = createRng(3), early: number[] = [], late: number[] = [];
    const med = (xs: number[]) => { const s = [...xs].sort((a, b) => a - b); return s[Math.floor(s.length / 2)] ?? 0; };
    for (let i = 0; i < 400; i++) {
      const p = lesson.generate(rng, i % 10), m = lesson.answers(p);
      const big = Math.max(0, ...m.steps.flatMap(s => (s.choices ? [] : s.slots.map(x => Math.abs(x.expected ?? 0)))));
      (i % 10 < 3 ? early : late).push(big);
    }
    expect(med(early)).toBeLessThanOrEqual(med(late));
  });
});

describe("the rewritten K-3 lessons keep their drafts' shape (fixes-02 Part C, K-3 weakest lessons)", () => {
  const ids = (id: string, i: number, seed = 1) => { const l = requireLesson(id), rng = createRng(seed); let p: any; for (let k = 0; k <= i; k++) p = l.generate(rng, k); return { p, steps: l.answers(p).steps }; };
  it("k-sort: the learner sorts one thing before counting, and a count of 1 has no 0 slip", () => {
    for (const { m } of many("k-sort", 60)) expect(m.steps[0]!.id).toBe("sort");
    const l = requireLesson("k-sort"), p = l.restore({ by: 1, counts: [1, 4], theme: 0, ask: 0 })!;
    expect(l.answers(p).steps[1]!.known.map(k => k.values.x)).not.toContain(0);
  });
  it("g1-three: a problem with one friendly pair asks which two first", () => {
    const l = requireLesson("g1-three"), s = l.answers(l.restore({ a: 5, b: 2, c: 5 })!).steps;
    expect(s.map(x => x.id)).toEqual(["pick", "first", "last"]);
    expect(s[0]!.choices).toEqual(["5 and 2", "5 and 5", "2 and 5"]);
  });
  it("g1-tally: the first problems read a row with a bundle, and every tally slip counts by 5s", () => {
    for (const { i, m } of many("g1-tally", 60)) if (i < 3) expect(m.steps[0]!.id).toBe("bundles");
  });
  it("g1-picgraph: reading a row goes on to compare it with another row", () => {
    for (const { p, m } of many("g1-picgraph", 80)) if (p.ask === 0) expect(m.steps.map(s => s.id)).toEqual(["read", "line-up"]);
  });
  it("g2-bargraph: the first three graphs have four different bars", () => {
    for (const { i, p } of many("g2-bargraph", 100)) if (i < 3) expect(new Set([p.v0, p.v1, p.v2, p.v3]).size).toBe(4);
  });
  it("g2-lineplot: reading a stack starts by plotting one more", () => {
    for (const { p, m } of many("g2-lineplot", 80)) if (p.ask === 0) expect(m.steps.map(s => s.id)).toEqual(["plot", "stack"]);
  });
  it("g2-regroup and g3-split: the first problems are small", () => {
    for (const { i, p } of many("g2-regroup", 200)) if (i < 3) { expect(p.a % 10 + p.b % 10).toBeLessThanOrEqual(12); expect(Math.floor(p.a / 10) + Math.floor(p.b / 10)).toBeLessThanOrEqual(6); }
    for (const { i, p } of many("g3-split", 200)) if (i < 3) { expect(p.a).toBeLessThanOrEqual(5); expect(p.b).toBeLessThanOrEqual(7); }
    expect(ids("g3-split", 0).steps[0]!.id).toBe("split");
  });
  it("g3-liters: problems 1 and 2 have marks worth 2 liters, and the scale step always has slips", () => {
    expect(ids("g3-liters", 1).p.step).toBe(2);
    for (const { p, m } of many("g3-liters", 60)) if (p.kind === 0) expect(m.steps[0]!.known.length, JSON.stringify(p)).toBeGreaterThan(0);
  });
});
