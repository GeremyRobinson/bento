import { createRng } from "../../curriculum/generators/rng";
import { formatNumber } from "../../curriculum/schemas/math-text";
import { entriesInGrade, isReady } from "../../app/curriculum";
import { upNext } from "../../app/today";
import { chapterRings, gradeRing } from "../../app/rings";
import { emptyProgress, type Progress } from "../../engine/mastery/progress";
import type { Level } from "../../engine/mastery/levels";
import { CHECK_LENGTH, checkKey, dependsOn, learned, recordCheck, REVIEW_DAYS, stepBack, type CheckRecord } from "../../engine/mastery/skills";
import { check, choose, currentStep, finishRun, focusSlot, nextProblem, pressKey, reviewPool, startReview, startTest, type Deps } from "../../engine/session/practice";
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

  it("a miss in the review brings a learned lesson back tomorrow", () => {
    const now = t;
    const p0 = base({ scores: { "g5-mult2": score(3), "g5-divide": score(3) }, checks: { "g5-mult2": rec(4, now - 10 * DAY, now - DAY) } });
    const p = run(startReview(p0, deps()), p0, id => id !== "g5-mult2");
    expect(p.checks["g5-mult2"]).toMatchObject({ last: 2, passes: 0 });
    expect(p.checks["g5-divide"]).toBeUndefined(); // only lessons with a check are counted
  });
});

describe("learned", () => {
  it("counts a check of 3 or 4; before checks existed, a practice score of 3 or 4", () => {
    const p = base({ scores: { a: score(3), b: score(2), c: score(4) }, checks: { c: rec(2, 0) } });
    expect(learned(p, "a")).toBe(true);
    expect(learned(p, "b")).toBe(false);
    expect(learned(p, "c")).toBe(false); // the check wins over the old practice score
  });

  it("reads what a lesson builds on from the catalog until Curriculum lists it", () => {
    expect(dependsOn("g5-order")).toEqual(["g5-mult2"]);
  });

  it("steps back only after a 0 or 1, and only to a lesson underneath that was tried and isn't solid", () => {
    const low = base({ checks: { "g5-order": rec(1, 0) } });
    expect(stepBack(low, "g5-order")).toBeNull(); // g5-mult2 never tried
    const shaky = base({ checks: { "g5-order": rec(1, 0) }, scores: { "g5-mult2": score(2) } });
    expect(stepBack(shaky, "g5-order")).toBe("g5-mult2");
    expect(stepBack({ ...shaky, checks: { "g5-order": rec(2, 0) } }, "g5-order")).toBeNull();
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
    expect(upNext(base({ lessons: { [a!.id]: 1 }, checks: { [a!.id]: rec(3, t) } }), 5)).toMatchObject({ entry: { id: b!.id }, why: "next" });
  });

  it("goes over a low check first, the oldest first", () => {
    const p = base({ checks: { [ready[3]!.id]: rec(2, t - DAY), [ready[5]!.id]: rec(2, t - 2 * DAY) } });
    expect(upNext(p, 5)).toMatchObject({ entry: { id: ready[5]!.id }, again: true, why: "go-over" });
  });

  it("steps back to the lesson underneath after a 0 or 1", () => {
    const p = base({ checks: { "g5-order": rec(0, t) }, scores: { "g5-mult2": score(1) } });
    expect(upNext(p, 5)).toMatchObject({ entry: { id: "g5-mult2" }, why: "step-back" });
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
