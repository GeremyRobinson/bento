import { LESSONS, lessonsInGrade } from "../../curriculum/registry";
import { NO_UNIT } from "../../app/copy";
import { createRng } from "../../curriculum/generators/rng";
import { formatNumber } from "../../curriculum/schemas/math-text";
import { emptyProgress, type Progress } from "../../engine/mastery/progress";
import {
  canResume, check, choose, currentStep, finishRun, focusSlot, hint, isLastProblem, nextProblem, pickPlan, pressKey,
  showMe, showMeAvailable, startPractice, startTest, testKey, toggleSkip, canPick, goToProblem, CHECKUP_LENGTH, UNIT_TEST_LENGTH, type Deps,
} from "../../engine/session/practice";
import { expectedValues } from "../../engine/evaluation/steps";
import type { PracticeSession } from "../../engine/session/types";

let t = Date.UTC(2026, 9, 2, 15);
const deps = (): Deps => ({ now: (t += 5000), rng });
let rng = createRng(1);
beforeEach(() => { rng = createRng(1); t = Date.UTC(2026, 9, 2, 15); });

function type(s: PracticeSession, values: Record<string, number>): PracticeSession {
  for (const [id, v] of Object.entries(values)) {
    s = focusSlot(s, id);
    for (const ch of formatNumber(v)) s = pressKey(s, ch);
  }
  return s;
}
function solveStep(s: PracticeSession, p: Progress) {
  const step = currentStep(s)!;
  return step.choices ? choose(s, expectedValues(step).c!, p, deps()) : check(type(s, expectedValues(step)), p, deps());
}
function solveProblem(s: PracticeSession, p: Progress) {
  while (currentStep(s)) s = solveStep(s, p);
  return s;
}
const withScore = (score: 0 | 1 | 2 | 3 | 4): Progress => ({ ...emptyProgress(), scores: { "g5-mult2": { last: score, best: score, pct: 0, date: 0, mastered: false } } });

describe("a practice run", () => {
  it("starts with 8 problems, every step shown, and half as many hints", () => {
    const s = startPractice("g5-mult2", emptyProgress(), deps());
    expect(s.items).toHaveLength(8);
    expect(s.tier).toBe(0);
    expect(s.hintsLeft).toBe(4);
    expect(currentStep(s)!.label).toBe("Step 1 · Multiply by the tens");
    expect(s.active).toBe("x");
  });

  it("starts with 10 after a low score", () => {
    expect(startPractice("g5-mult2", withScore(1), deps()).items).toHaveLength(10);
  });

  it("goes through every step and records the worked lines", () => {
    const p = emptyProgress();
    let s = startPractice("g5-mult2", p, deps());
    s = solveStep(s, p);
    expect(s.feedback?.type).toBe("good");
    expect(s.work).toHaveLength(1);
    s = solveProblem(s, p);
    expect(s.solved).toBe(true);
    expect(s.work).toHaveLength(3);
    expect(s.feedback?.strong).toBe("Solved! +15 XP");
    expect(s.clean).toBe(1);
  });

  it("explains a place-value slip and lets Show me finish the step after two misses", () => {
    const p = emptyProgress();
    let s = startPractice("g5-mult2", p, deps());
    const want = expectedValues(currentStep(s)!).x!;
    s = check(type(s, { x: want / 10 }), p, deps());
    expect(s.feedback).toMatchObject({ type: "bad", strong: "Look again." });
    expect(s.feedback?.text).toMatch(/The tens digit stands for \d+0, so add a zero\./);
    expect(s.mistakes[0]).toMatchObject({ kind: "Lost the place value", cat: "concept" });
    expect(showMeAvailable(s)).toBe(false);
    s = check(type({ ...s, values: {} }, { x: want + 1 }), p, deps());
    expect(s.mistakes[1]!.cat).toBe("off1");
    expect(showMeAvailable(s)).toBe(true);
    s = showMe(s, p, deps());
    expect(s.work[0]).toMatchObject({ shown: true });
    expect(s.shown).toBe(1);
    s = solveProblem(s, p);
    // a missed problem earns one more like it
    expect(s.items).toHaveLength(9);
    expect(s.extra).toBe(1);
  });

  it("holds the hint until a first try", () => {
    const p = emptyProgress();
    let s = startPractice("g5-mult2", p, deps());
    s = hint(s, { now: s.stepT0 + 1000, rng });
    expect(s.hinted).toBe(false);
    expect(s.feedback?.text).toMatch(/Try it once first/);
    s = hint(s, { now: s.stepT0 + 16000, rng });
    expect(s.hinted).toBe(true);
    expect(s.hintsLeft).toBe(3);
    expect(s.feedback?.text).toMatch(/then add a zero/);
    expect(s.feedback?.left).toBe(3);
  });

  it("says kindly when the hints are used up", () => {
    const p = emptyProgress();
    let s = { ...startPractice("g5-mult2", p, deps()), hintsLeft: 0 };
    s = hint(s, { now: s.stepT0 + 16000, rng });
    expect(s.hinted).toBe(false);
    expect(s.feedback?.text).toBe("No hints left in this lesson. You can do it.");
  });

  it("asks for the plan first at a score of 2", () => {
    const p = withScore(2);
    let s = startPractice("g5-mult2", p, deps());
    expect(s.tier).toBe(1);
    expect(s.pick?.options).toContain("Multiply by the tens");
    const wrong = s.pick!.options.findIndex(o => o !== s.pick!.right);
    s = pickPlan(s, wrong);
    expect(s.feedback?.strong).toBe("Look again.");
    expect(s.mistakes[0]!.cat).toBe("plan");
    s = pickPlan(s, s.pick!.options.indexOf(s.pick!.right));
    expect(s.pick).toBeNull();
    expect(s.feedback?.strong).toBe("Good plan.");
  });

  it("goes straight to the final answer at a score of 3, and brings the steps back after a miss", () => {
    const p = withScore(3);
    let s = startPractice("g5-mult2", p, deps());
    expect(s.collapsed).toBe(true);
    expect(currentStep(s)!.label).toBe("Final answer");
    s = check(type(s, { x: 1 }), p, deps());
    expect(s.collapsed).toBe(false);
    expect(s.feedback?.text).toBe("This one needs the steps. Here they are.");
    expect(currentStep(s)!.label).toBe("Step 1 · Multiply by the tens");
    // and "Show steps" turns the shortcut off by choice
    let s2 = startPractice("g5-mult2", p, deps());
    s2 = toggleSkip(s2, deps());
    expect(s2.collapsed).toBe(false);
    expect(s2.skip).toBe(false);
  });

  it("finishes with a score, XP, a streak and a log entry", () => {
    let p = emptyProgress();
    let s = startPractice("g5-mult2", p, deps());
    for (;;) {
      s = solveProblem(s, p);
      if (isLastProblem(s)) break;
      s = nextProblem(s, p, deps())!;
    }
    expect(nextProblem(s, p, deps())).toBeNull();
    const r = finishRun(s, p, t);
    p = r.progress;
    expect(r.report).toMatchObject({ level: 4, pct: 1, total: 8, clean: 8, xp: 120 });
    expect(p.scores["g5-mult2"]).toMatchObject({ last: 4, best: 4, mastered: false });
    expect(p).toMatchObject({ xp: 120, streak: 1, done: 1, run: null });
    expect(p.gxp[5]).toBe(120);
    expect(p.lessons["g5-mult2"]).toBe(1);
    expect(p.log[0]).toMatchObject({ key: "g5-mult2", level: 4, total: 8 });
    // the next day keeps the streak going
    const next = finishRun(s, p, t + 864e5);
    expect(next.progress.streak).toBe(2);
  });

  it("can resume a saved run, and refuses a broken one", () => {
    const s = startPractice("g5-mult2", emptyProgress(), deps());
    expect(canResume(JSON.parse(JSON.stringify(s)))).toBe(true);
    expect(canResume({ ...s, items: [{ lessonId: "nope", problem: {} }] })).toBe(false);
    expect(canResume(null)).toBe(false);
  });
});

// G 2026-10-07: "I did the same problem 4 times in a row". A lesson never gives the same problem twice in a row, and
// gives a run problems it hasn't had yet wherever the lesson can make enough different ones.
describe("no repeated problems", () => {
  const key = (p: unknown) => JSON.stringify(p);
  it("no lesson repeats a problem back to back, and each run is as varied as the lesson allows", () => {
    for (const l of LESSONS) for (let s = 1; s <= 12; s++) {
      rng = createRng(s * 7919);
      const run = startPractice(l.id, emptyProgress(), deps());
      const ps = run.items.map(x => key(x.problem));
      for (let i = 1; i < ps.length; i++) expect(ps[i], `${l.id} seed ${s} item ${i}`).not.toBe(ps[i - 1]);
    }
  });
  it("the narrowest lessons still give a run all different problems", () => {
    for (const id of ["k-tens", "k-make10", "g7-circum", "g3-unitfrac", "g10-polygon"]) for (let s = 1; s <= 12; s++) {
      rng = createRng(s * 104729);
      const run = startPractice(id, emptyProgress(), deps());
      expect(new Set(run.items.map(x => key(x.problem))).size, `${id} seed ${s}`).toBe(run.items.length);
    }
  });
});

describe("picking which problem comes next (G 2026-10-08)", () => {
  it("jumps to any problem before you start one, and comes back for the ones skipped", () => {
    const p = emptyProgress();
    let s = startPractice("g5-mult2", p, deps());
    expect(canPick(s, 5)).toBe(true);
    s = goToProblem(s, 5, p, deps());
    expect(s.i).toBe(5);
    s = solveProblem(s, p);
    expect(s.done).toEqual([5]);
    // next goes on from where you are, then wraps round to the start
    s = nextProblem(s, p, deps())!;
    expect(s.i).toBe(6);
    for (let k = 0; k < 6; k++) { s = solveProblem(s, p); s = nextProblem(s, p, deps())!; }
    expect(s.i).toBe(4);
    expect(isLastProblem(s)).toBe(true);
    s = solveProblem(s, p);
    expect(nextProblem(s, p, deps())).toBeNull();
    expect(s.done).toHaveLength(8);
  });

  it("keeps you on a problem you've started until it's solved", () => {
    const p = emptyProgress();
    let s = startPractice("g5-mult2", p, deps());
    s = solveStep(s, p);
    expect(canPick(s, 3)).toBe(false);
    expect(goToProblem(s, 3, p, deps())).toBe(s);
    s = solveProblem(s, p);
    expect(canPick(s, 3)).toBe(true);
    expect(canPick(s, 0)).toBe(false); // already done
  });
});

describe("tests", () => {
  // G 2026-10-08: "Tests need more problems no? 12-20": a unit test is 12, a grade check-up 20, an even mix of the
  // lessons, and never the same problem twice
  it("every unit test has 12 problems and every check-up 20, shared evenly, none repeated", () => {
    for (let g = 0; g <= 12; g++) {
      const lessons = lessonsInGrade(g);
      if (!lessons.length) continue;
      const units = [...new Set(lessons.map(l => l.unit || NO_UNIT))];
      for (const k of [testKey(g), ...units.map(u => testKey(g, u))]) for (let s = 1; s <= 3; s++) {
        rng = createRng(s * 6151);
        const run = startTest(k, emptyProgress(), deps());
        expect(run.items, k).toHaveLength(k.startsWith("unit") ? UNIT_TEST_LENGTH : CHECKUP_LENGTH);
        const per = [...run.items.reduce((m, x) => m.set(x.lessonId, (m.get(x.lessonId) ?? 0) + 1), new Map<string, number>()).values()];
        expect(Math.max(...per) - Math.min(...per), `${k}: an even mix`).toBeLessThanOrEqual(1);
        expect(new Set(run.items.map(x => x.lessonId + JSON.stringify(x.problem))).size, `${k} seed ${s}: no repeats`).toBe(run.items.length);
      }
    }
  });
});
