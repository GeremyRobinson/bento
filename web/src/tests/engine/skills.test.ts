import { createRng } from "../../curriculum/generators/rng";
import { lessonsInGrade } from "../../curriculum/registry";
import { CHECKS } from "../../curriculum/checks";
import { DEPENDS } from "../../curriculum/depends";
import { CATALOG } from "../../curriculum/catalog";
import { formatNumber } from "../../curriculum/schemas/math-text";
import { entriesInGrade, isReady } from "../../app/curriculum";
import { upNext } from "../../app/today";
import { chapterRings, gradeRing } from "../../app/rings";
import { emptyProgress, type Progress } from "../../engine/mastery/progress";
import { migrateProgress } from "../../persistence/migrations";
import type { Level } from "../../engine/mastery/levels";
import { CHECK_LENGTH, checkKey, dependsOn, learned, ready, recordCheck, REVIEW_DAYS, stepBack, type CheckRecord } from "../../engine/mastery/skills";
import { checkItems, check, choose, currentStep, finishRun, focusSlot, nextProblem, pressKey, reviewDue, reviewPlan, reviewPool, startReview, startTest, type Deps } from "../../engine/session/practice";
import { expectedValues } from "../../engine/evaluation/steps";
import type { PracticeSession } from "../../engine/session/types";

const DAY = 864e5;
let t = Date.UTC(2026, 9, 13, 15);
let rng = createRng(1);
const deps = (): Deps => ({ now: (t += 5000), rng });
beforeEach(() => { rng = createRng(1); t = Date.UTC(2026, 9, 13, 15); });

function type(s: PracticeSession, values: Record<string, number>): PracticeSession {
  for (const [id, v] of Object.entries(values)) {
    s = focusSlot(s, id);
    for (const ch of formatNumber(v)) s = pressKey(s, ch);
  }
  return s;
}
/** right answers, or one wrong try on every step (a test moves on after it; a review takes the right one next) */
function answer(s: PracticeSession, p: Progress, right: boolean) {
  for (let guard = 0; currentStep(s); guard++) {
    if (guard > 200) throw new Error("stuck on a step");
    const step = currentStep(s)!, ex = expectedValues(step), wrong = !right && (s.mode === "test" || s.prob.wrong === 0);
    if (step.choices) s = choose(s, wrong ? (ex.c! + 1) % step.choices.length : ex.c!, p, deps());
    else s = check(type(s, wrong ? Object.fromEntries(Object.entries(ex).map(([k, v]) => [k, v + 7])) : ex), p, deps());
  }
  return s;
}
/** a whole run; `right` says, for each problem's lesson, whether to answer it right */
function run(s: PracticeSession, p: Progress, right: (lessonId: string) => boolean) {
  for (;;) {
    s = answer(s, p, right(s.items[s.i]!.lessonId));
    const n = nextProblem(s, p, deps());
    if (!n) return finishRun(s, p, t).progress;
    s = n;
  }
}
const rec = (last: Level, date: number, due = date + 3 * DAY): CheckRecord => ({ last, best: last, date, due, passes: last >= 3 ? 1 : 0 });
const score = (last: Level) => ({ last, best: last, pct: 0, date: 0, mastered: false });
const base = (p: Partial<Progress> = {}): Progress => ({ ...emptyProgress(), grade: 5, chosen: true, ...p });

describe("the skill check", () => {
  it("is a few of the lesson's problems, no hints, one try per step, under its own key", () => {
    const s = startTest(checkKey(5, "g5-mult2"), emptyProgress(), deps());
    expect(s.items).toHaveLength(CHECK_LENGTH);
    expect(s.items.every(i => i.lessonId === "g5-mult2")).toBe(true);
    expect(s).toMatchObject({ mode: "test", key: "check:5:g5-mult2", hintsLeft: 0, tier: 0 });
  });

  it("a miss gives the answer and how it's worked out, without repeating \"Not this time.\" (v2 spec C2)", () => {
    let s = startTest(checkKey(5, "g5-mult2"), emptyProgress(), deps());
    s = answer(s, emptyProgress(), false);
    const pr = s.items[0]!.problem as { partialProducts: number[]; product: number };
    expect(s.feedback).toMatchObject({ type: "bad", missed: true, strong: `It\u2019s **${formatNumber(pr.product)}**.` });
    expect(s.feedback?.text).toBe(`Split it into tens and ones: ${pr.partialProducts.map(formatNumber).join(" + ")}.`);
  });

  it("is saved apart from the practice score and the tests", () => {
    const p0 = base({ scores: { "g5-mult2": score(2) } });
    const p = run(startTest(checkKey(5, "g5-mult2"), p0, deps()), p0, () => true);
    expect(p.checks["g5-mult2"]).toMatchObject({ last: 4, passes: 1 });
    expect(p.scores["g5-mult2"]!.last).toBe(2);
    expect(p.tests).toEqual({});
    expect(p.done).toBe(0);
  });

  it("a low check marks the lesson to go over", () => {
    const p = run(startTest(checkKey(5, "g5-mult2"), base(), deps()), base(), () => false);
    expect(p.checks["g5-mult2"]!.last).toBeLessThan(3);
    expect(learned(p, "g5-mult2")).toBe(false);
  });
});

describe("spacing", () => {
  it("brings a passed lesson back after 3, 7, 21, then 60 days, and a miss tomorrow", () => {
    const now = t;
    let r: CheckRecord | undefined;
    for (const days of [...REVIEW_DAYS, 60]) {
      r = recordCheck(r, 3, now);
      expect((r.due - now) / DAY).toBe(days);
    }
    r = recordCheck(r, 2, now);
    expect(r).toMatchObject({ passes: 0, last: 2, best: 3 });
    expect((r.due - now) / DAY).toBe(1);
  });

  it("puts a lesson that's due back three times over in the review, and a clean review pushes it out", () => {
    const now = t;
    const p0 = base({ scores: { "g5-mult2": score(3), "g5-divide": score(3) }, checks: { "g5-mult2": rec(4, now - 10 * DAY, now - DAY), "g5-divide": rec(4, now - DAY, now + 2 * DAY) } });
    const pool = reviewPool(p0, now);
    const w = (id: string) => pool.find(x => x.lesson.id === id)!.weight;
    expect(w("g5-mult2")).toBeCloseTo(w("g5-divide") * 3);
    const p = run(startReview(p0, deps()), p0, () => true);
    expect(p.checks["g5-mult2"]).toMatchObject({ last: 4, passes: 2 });
    expect((p.checks["g5-mult2"]!.due - p.checks["g5-mult2"]!.date) / DAY).toBe(7);
  });

  it("a miss in the review brings a learned lesson back tomorrow, still learned", () => {
    const now = t;
    const p0 = base({ scores: { "g5-mult2": score(3), "g5-divide": score(3) }, checks: { "g5-mult2": rec(4, now - 10 * DAY, now - DAY) } });
    const p = run(startReview(p0, deps()), p0, id => id !== "g5-mult2");
    expect(p.checks["g5-mult2"]).toMatchObject({ last: 4, passes: 0 });
    expect((p.checks["g5-mult2"]!.due - t) / DAY).toBeCloseTo(1, 1);
    expect(learned(p, "g5-mult2")).toBe(true);
    expect(p.checks["g5-divide"]).toBeUndefined(); // only lessons with a check are counted
  });
});

describe("learned", () => {
  it("counts only a check of 3 or 4, never practice alone", () => {
    const p = base({ scores: { a: score(4), c: score(4) }, checks: { b: rec(3, 0), c: rec(2, 0) } });
    expect(learned(p, "a")).toBe(false);
    expect(learned(p, "b")).toBe(true);
    expect(learned(p, "c")).toBe(false);
  });

  it("turns an old save's practice scores of 3+ into checks once, when it loads", () => {
    const old = { ...base({ scores: { a: { ...score(3), date: t }, b: score(2) } }) } as Partial<Progress>;
    delete old.checks;
    const p = migrateProgress(old);
    expect(p.checks).toEqual({ a: { last: 3, best: 3, date: t, due: t + 3 * DAY, passes: 1 } });
    expect(learned(p, "a")).toBe(true);
    // a save that already has checks is left alone, so new practice never counts
    expect(migrateProgress({ ...p, scores: { ...p.scores, c: score(4) } }).checks).toEqual(p.checks);
  });

  it("reads what a lesson builds on from the catalog until Curriculum lists it", () => {
    expect(dependsOn("g4-mixed")).toEqual(entriesInGrade(4).find(c => c.id === "g4-mixed")!.pre ? [entriesInGrade(4).find(c => c.id === "g4-mixed")!.pre!] : []);
  });

  it("reads Curriculum's list first, across grades", () => {
    expect(dependsOn("g5-divdec")).toEqual(["g5-pow10", "g3-divfacts"]);
  });

  it("steps back only after a 0 or 1: to the main lesson underneath, tried or not, else to one whose check was low", () => {
    expect(stepBack(base({ checks: { "g5-divdec": rec(1, 0) } }), "g5-divdec")).toBe("g5-pow10");
    // the main one is learned and g3-divfacts was never tried: no further back
    expect(stepBack(base({ checks: { "g5-divdec": rec(1, 0), "g5-pow10": rec(4, 0) } }), "g5-divdec")).toBeNull();
    expect(stepBack(base({ checks: { "g5-divdec": rec(1, 0), "g5-pow10": rec(4, 0), "g3-divfacts": rec(2, 0) } }), "g5-divdec")).toBe("g3-divfacts");
    expect(stepBack(base({ checks: { "g5-divdec": rec(2, 0) } }), "g5-divdec")).toBeNull();
  });

  it("counts an earlier grade's lessons as learned for starting, until one of their checks comes back low", () => {
    expect(ready(base(), "g5-order")).toBe(true); // g3 lessons never done
    expect(ready(base({ checks: { "g3-facts": rec(1, 0) } }), "g5-order")).toBe(false);
    expect(ready(base(), "g5-divdec")).toBe(false); // g5-pow10, same grade, not learned
    expect(ready(base({ checks: { "g5-pow10": rec(3, 0) } }), "g5-divdec")).toBe(true);
  });
});

describe("Today's pick", () => {
  const ready = entriesInGrade(5).filter(c => isReady(c.id));

  it("starts with the first lesson", () => {
    expect(upNext(base(), 5)).toMatchObject({ entry: { id: ready[0]!.id }, again: false, why: "next" });
  });

  it("moves on once a lesson is learned, and offers a finished lesson again until it is", () => {
    const [a, b] = ready;
    expect(upNext(base({ lessons: { [a!.id]: 1 }, scores: { [a!.id]: score(2) } }), 5)).toMatchObject({ entry: { id: a!.id }, again: true, why: "next" });
    // the lesson that builds on it comes first when there is one (what Today promised), else the next in order
    const builds = ready.find(c => dependsOn(c.id).includes(a!.id));
    expect(upNext(base({ lessons: { [a!.id]: 1 }, checks: { [a!.id]: rec(3, t) } }), 5)).toMatchObject({ entry: { id: (builds ?? b)!.id }, why: "next" });
  });

  it("after a lesson is learned, brings one that builds on it (Curriculum's depends-on list), else the next in order", () => {
    // nothing in 5th grade lists Multiply two-digit numbers, so Today goes on in order: Long division
    expect(upNext(base({ lessons: { "g5-mult2": 1 }, checks: { "g5-mult2": rec(3, t) } }), 5)).toMatchObject({ entry: { id: "g5-divide" }, why: "next" });
    // Subtracting fractions builds on Adding fractions, so it comes straight after, ahead of the order
    const before = ready.slice(0, ready.findIndex(c => c.id === "add")).map(c => c.id);
    const done = Object.fromEntries([...before, "add"].map(id => [id, rec(3, t - DAY)]));
    expect(upNext(base({ checks: { ...done, add: rec(4, t) } }), 5)).toMatchObject({ entry: { id: "sub" }, why: "next" });
  });

  it("goes over a low check first, the oldest first", () => {
    const p = base({ checks: { [ready[3]!.id]: rec(2, t - DAY), [ready[5]!.id]: rec(2, t - 2 * DAY) } });
    expect(upNext(p, 5)).toMatchObject({ entry: { id: ready[5]!.id }, again: true, why: "go-over" });
  });

  it("steps back to the lesson underneath after a 0 or 1", () => {
    const p = base({ checks: { "g5-divdec": rec(0, t) } });
    expect(upNext(p, 5)).toMatchObject({ entry: { id: "g5-pow10" }, why: "step-back" });
  });

  it("skips a lesson whose lesson underneath came back low, when another is ready", () => {
    const before = ready5().slice(0, ready5().findIndex(c => c.id === "g5-order"));
    const after = ready5()[ready5().findIndex(c => c.id === "g5-order") + 1]!;
    const checks = { ...Object.fromEntries(before.map(c => [c.id, rec(4, t)])), "g3-facts": rec(1, t) };
    expect(upNext(base({ checks }), 5)).toMatchObject({ entry: { id: after.id }, why: "next" });
    expect(upNext(base({ checks: { ...checks, "g3-facts": rec(3, t) } }), 5)).toMatchObject({ entry: { id: "g5-order" }, why: "next" });
  });

  it("once everything is learned, offers the one checked longest ago", () => {
    const checks = Object.fromEntries(ready.map((c, k) => [c.id, rec(4, t - k * DAY)]));
    expect(upNext(base({ checks }), 5)).toMatchObject({ entry: { id: ready.at(-1)!.id }, why: "oldest" });
  });
});

describe("rings", () => {
  it("count lessons learned per chapter, and the chapters add up to the grade", () => {
    const [a, b] = ready5();
    const p = base({ checks: { [a!.id]: rec(4, t), [b!.id]: rec(2, t) } });
    const g = gradeRing(p, 5), ch = chapterRings(p, 5);
    expect(g.learned).toBe(1);
    expect(g.total).toBe(entriesInGrade(5).length);
    expect(ch.reduce((n, c) => n + c.ring.learned, 0)).toBe(g.learned);
    expect(ch.reduce((n, c) => n + c.ring.total, 0)).toBe(g.total);
  });
});
const ready5 = () => entriesInGrade(5).filter(c => isReady(c.id));

describe.each([...new Set(Object.keys(CHECKS).map(id => CATALOG.find(c => c.id === id)!.grade))])("grade %i's check recipes", g => {
  const lessons = lessonsInGrade(g);
  it("cover every lesson in the grade", () => expect(lessons.filter(l => CHECKS[l.id]).map(l => l.id)).toEqual(lessons.map(l => l.id)));

  it("draw each item so its condition holds, story items last, in order where asked, every problem valid", () => {
    const misses: string[] = [];
    for (const l of lessons) {
      const recipe = CHECKS[l.id]!;
      let held = 0, wanted = 0;
      for (let seed = 1; seed <= 60; seed++) {
        const items = checkItems(l, createRng(seed));
        expect(items).toHaveLength(recipe.items.length);
        expect(items.every(x => x.lessonId === l.id && l.restore(x.problem) != null)).toBe(true);
        const stories = l.story ? recipe.items.filter(c => c.story).length : 0;
        expect(items.slice(items.length - stories).every(x => x.story)).toBe(true);
        expect(items.slice(0, items.length - stories).some(x => x.story)).toBe(false);
        if (recipe.inOrder) recipe.items.forEach((c, k) => { if (c.where) { wanted++; if (c.where(items[k]!.problem)) held++; } });
        else for (const c of recipe.items.filter(c => c.where)) { wanted++; if (items.some(x => c.where!(x.problem))) held++; }
      }
      if (held < wanted * 0.95) misses.push(`${l.id}: ${held}/${wanted}`);
    }
    expect(misses).toEqual([]);
  });

  it("an item built directly when the draws miss fits whenever it makes a valid problem (g5-volume, g2 rare items)", () => {
    for (const l of lessons) for (const c of CHECKS[l.id]!.items.filter(c => c.fix)) {
      let made = 0;
      for (let seed = 1; seed <= 300; seed++) {
        const fixed = l.restore(c.fix!(l.generate(createRng(seed), c.i)));
        if (fixed == null) continue;
        made++;
        if (c.where!(l.generate(createRng(seed), c.i))) continue; // already fit: the fix isn't used
        expect(c.where!(fixed), `${l.id} i${c.i} seed ${seed}`).toBe(true);
      }
      expect(made, `${l.id} i${c.i}`).toBeGreaterThan(150);
    }
  });
});

describe("depends-on lists", () => {
  it("name real lessons from the same grade or earlier", () => {
    for (const [id, deps] of Object.entries(DEPENDS)) {
      const g = CATALOG.find(c => c.id === id)?.grade;
      expect(g, id).toBeDefined();
      for (const d of deps) expect(CATALOG.find(c => c.id === d)?.grade, `${id} → ${d}`).toBeLessThanOrEqual(g!);
    }
  });
  // one source of truth (coordinator 2026-10-13): the catalog's pre is each list's first id, in every grade, so they can't drift
  it("start with the catalog's build-up lesson", () => {
    for (const [id, deps] of Object.entries(DEPENDS)) if (deps.length)
       expect(CATALOG.find(c => c.id === id)!.pre, id).toBe(deps[0]);
  });
});


describe("Today's review on home", () => {
  it("is offered when a learned lesson is due back, says which and how many problems, and goes once it's done today", () => {
    const p = base({ checks: { "g5-mult2": rec(4, t - 20 * DAY, t - DAY), "g5-divide": rec(3, t - 2 * DAY) },
      scores: { "g5-mult2": score(4), "g5-divide": score(3) } });
    expect(reviewDue(p, t)).toBe(true);
    expect(reviewPlan(p, t)).toEqual({ due: ["g5-mult2"], problems: 8 });
    expect(reviewDue({ ...p, reviews: { [new Date(t).toDateString()]: 4 } } as Progress, t)).toBe(false);
    // nothing due back: no review offered
    expect(reviewDue(base({ checks: { "g5-mult2": rec(4, t) }, scores: { "g5-mult2": score(4), "g5-divide": score(3) } }), t)).toBe(false);
  });
});
