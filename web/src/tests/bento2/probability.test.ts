// Probability's generators, 60 seeds each: every step's answer matches the spec's oracle, the rounded answer is
// accepted, every slip fires with its own message, and every word reads right.
import { describe, expect, it } from "vitest";
import { createRng } from "../../curriculum/generators/rng";
import { aOrAn } from "../../curriculum/text";
import { checkB2Step, formatAnswer, toleranceOf } from "../../bento2/steps";
import { trackByCode } from "../../bento2/registry";
import type { AnyB2Lesson, B2Step } from "../../bento2/model";

const track = trackByCode("pr")!;
const SEEDS = 60;
const problems = (l: AnyB2Lesson) => Array.from({ length: SEEDS }, (_, s) => { const i = s % 8; return { i, p: l.workIt.generate(createRng(1000 + s), i) }; });
const flat = (steps: B2Step[]) => steps.flatMap(s => s.answer);

/** every string a learner can see in a value, deep */
const strings = (v: unknown, out: string[] = []): string[] => {
  if (typeof v === "string") out.push(v);
  else if (Array.isArray(v)) v.forEach(x => strings(x, out));
  else if (v && typeof v === "object") Object.values(v).forEach(x => strings(x, out));
  return out;
};
/** Bento's voice rules: no em-dashes, no "+ −", no float noise or undefined, a/an right before numbers */
function lint(t: string): string[] {
  const bad: string[] = [];
  if (/—/.test(t)) bad.push("em-dash");
  if (/\+ [−-]/.test(t)) bad.push("+ −");
  if (/undefined|NaN|Infinity|\[object/.test(t)) bad.push("undefined");
  if (/\d\.\d*0000\d|\d\.\d*9999\d/.test(t)) bad.push("float noise");
  for (const m of t.matchAll(/\b(an?) (\d[\d,]*)(?![\d.])/gi)) if (m[1]!.toLowerCase() !== aOrAn(+m[2]!.replace(/,/g, ""))) bad.push(`a/an: ${m[0]}`);
  if (/(?<![\d.,/−-])\b1 (years|light-years|seconds|days|clocks)\b/.test(t)) bad.push("1 with a plural");
  if (/(^|[^\w.])1(x|β|γ|c)\b/.test(t)) bad.push("coefficient of 1");
  return bad.map(b => `${b}: ${t}`);
}

describe("Probability: the track", () => {
  it("has 20 lessons, b2-pr-01 to b2-pr-20, in five units of four", () => {
    expect(track.lessons.map(l => l.id)).toEqual(Array.from({ length: 20 }, (_, i) => `b2-pr-${String(i + 1).padStart(2, "0")}`));
    expect(track.units.map(u => track.lessons.filter(l => l.unit === u.n).length)).toEqual([4, 4, 4, 4, 4]);
    expect(track.projects.map(p => p.after)).toEqual(["b2-pr-04", "b2-pr-08", "b2-pr-12", "b2-pr-16", "b2-pr-20"]);
    expect(track.buildPieces).toHaveLength(20);
    expect(track.pickerId).toBe("prob");
  });
  it("every lesson has every part of the spec block, and every shelf name is a build piece", () => {
    for (const l of track.lessons) {
      expect(l.youCan, l.id).toMatch(/^[a-z]/);
      expect(l.nameIt.say.length, l.id).toBeGreaterThanOrEqual(1);
      expect(l.nameIt.say.length, l.id).toBeLessThanOrEqual(3);
      expect(l.nameIt.formula.length, l.id).toBeGreaterThan(0);
      expect(l.deeper.length, l.id).toBeGreaterThan(0);
      expect(l.useIt.say.length, l.id).toBeGreaterThan(0);
      if (l.guess.kind === "choice") expect(l.guess.options[l.guess.answer], l.id).toBeDefined();
      if (l.useIt.saves) expect(track.buildPieces, l.id).toContain(l.useIt.saves.name);
      if (l.useIt.project) expect(track.projects.map(p => p.id), l.id).toContain(l.useIt.project);
    }
    for (const p of track.projects) for (const n of p.shelf) expect(track.buildPieces).toContain(n);
  });
  it("the reference problems give the spec's worked examples", () => {
    const answers = (id: string) => { const l = track.lessons.find(x => x.id === id)!; return l.workIt.steps(l.workIt.reference).map(s => s.answer.map(a => formatAnswer(a, s.choices ? "whole" : s.form)).join(", ")); };
    expect(answers("b2-pr-01")).toEqual(["0.0150", "1,800", "0.010"]);
    expect(answers("b2-pr-02")).toEqual(["0", "1/50", "45", "9/10"]);
    expect(answers("b2-pr-03")).toEqual(["36", "7", "19", "36"]);
    expect(answers("b2-pr-04")).toEqual(["200", "190", "490", "27.9"]);
    expect(answers("b2-pr-05")).toEqual(["3.0", "0.0498", "0.2240", "0.9502"]);
    expect(answers("b2-pr-06")).toEqual(["1/4", "0.3679", "0.2387", "2.77"]);
    expect(answers("b2-pr-07")).toEqual(["200", "25", "2.00", "0.0228"]);
    expect(answers("b2-pr-08")).toEqual(["0.60", "2", "1.20", "66.00", "4.00"]);
    expect(answers("b2-pr-09")).toEqual(["0", "0", "3/4", "27/16"]);
    expect(answers("b2-pr-10")).toEqual(["45", "−15", "25, 13", "1"]);
    expect(answers("b2-pr-11")).toEqual(["0.296", "10", "21, 35"]);
    expect(answers("b2-pr-12")).toEqual(["9", "5", "9/14", "5/7"]);
    expect(answers("b2-pr-13")).toEqual(["20", "6.00", "2", "1/10", "1"]);
    expect(answers("b2-pr-14")).toEqual(["2.00", "2.80", "0.7995", "196"]);
    expect(answers("b2-pr-15")).toEqual(["1.00", "0.6415", "0.0025", "1", "3"]);
    expect(answers("b2-pr-16")).toEqual(["100", "80", "45", "36.0"]);
    expect(answers("b2-pr-17")).toEqual(["0.64", "1.28", "106.4", "2"]);
    expect(answers("b2-pr-18")).toEqual(["90", "50", "80", "40", "58.0, 72.0", "70.0, 60.0", "0"]);
    expect(answers("b2-pr-19")).toEqual(["3/4", "2/3", "10.0", "11/16"]);
    expect(answers("b2-pr-20")).toEqual(["0.010", "2.5", "0.0054, 0.0446", "1", "95.2"]);
  });
  it("the spec's other worked numbers", () => {
    const l = (id: string) => track.lessons.find(x => x.id === id)!;
    const ans = (id: string, p: unknown) => l(id).workIt.steps(p).map(s => s.answer.map(a => formatAnswer(a, s.choices ? "whole" : s.form)).join(", "));
    // flips: n = 21 → 5; collector n = 3, 4, 6 → 11/2, 25/3, 147/10
    expect(ans("b2-pr-02", { kind: "b", n: 21, d: 4, j: 1, rot: 0 })[3]).toBe("5");
    expect(ans("b2-pr-02", { kind: "c", n: 3, d: 0, j: 1, rot: 0 })[1]).toBe("11/2");
    expect(ans("b2-pr-02", { kind: "c", n: 4, d: 0, j: 1, rot: 0 })[1]).toBe("25/3");
    expect(ans("b2-pr-02", { kind: "c", n: 6, d: 0, j: 1, rot: 0 })[1]).toBe("147/10");
    // Poisson: λ = 1 → 0.3679; λ = 2, k = 2 → 0.2707
    expect(ans("b2-pr-05", { r: 1, hourly: false, t: 1, k: 1, later: false })[1]).toBe("0.3679");
    expect(ans("b2-pr-05", { r: 2, hourly: false, t: 1, k: 2, later: false })[2]).toBe("0.2707");
    // exponential median, m = 10 → 6.93
    expect(ans("b2-pr-06", { m: 10, t: 10, a: 0, b: 5 })[3]).toBe("6.93");
    // bootstrap: n = 4 → 0.316, n = 10 → 0.349, n = 5 → 126 resamples
    expect(ans("b2-pr-11", { n: 4, vals: Array.from({ length: 40 }, (_, i) => i) })[0]).toBe("0.316");
    expect(ans("b2-pr-11", { n: 10, vals: Array.from({ length: 40 }, (_, i) => i) })[0]).toBe("0.349");
    expect(ans("b2-pr-11", { n: 5, vals: Array.from({ length: 40 }, (_, i) => i) })[1]).toBe("126");
    // many tests: m = 5 → 0.2262
    expect(ans("b2-pr-15", { m: 5, ps: [0.001, 0.2, 0.3, 0.4], gap: false })[1]).toBe("0.2262");
    // the coin's Bayes factor: k = 8, n = 10 → 6.41
    expect(ans("b2-pr-16", { kind: "b", r: 0, pw: 0, n: 10, k: 8, prior: 1 })[0]).toBe("6.41");
    // Luck detector, m = 1: 80.0%
    expect(ans("b2-pr-20", { s1: 0.006, s2: 0.008, z: 2.5, m: 1, r: 20, pw: 80 })[4]).toBe("80.0");
  });
  it("early problems are the friendly ones the spec names", () => {
    const early = (id: string) => Array.from({ length: 40 }, (_, s) => track.lessons.find(x => x.id === id)!.workIt.generate(createRng(s), s % 3)) as any[];
    expect(early("b2-pr-01").every(p => p.k === 2 && p.n0 === 100)).toBe(true);
    expect(early("b2-pr-02").every(p => p.kind === "b" || (p.kind === "a" && p.n <= 6))).toBe(true);
    expect(early("b2-pr-03").every(p => p.c === 0 || p.c === 2)).toBe(true);
    expect(early("b2-pr-04").every(p => p.prev === 10 && p.spec === 90)).toBe(true);
    expect(early("b2-pr-05").every(p => [1, 2].includes(p.r) && !p.hourly)).toBe(true);
    expect(early("b2-pr-06").every(p => p.t === p.m)).toBe(true);
    expect(early("b2-pr-07").every(p => p.z === 1 || p.z === 2)).toBe(true);
    expect(early("b2-pr-08").every(p => p.rho === 0.5 && p.k === 2)).toBe(true);
    expect(early("b2-pr-09").every(p => p.kind === "a" && p.n <= 6)).toBe(true);
    expect(early("b2-pr-10").every(p => p.s2 === 100 && [2, 4, 5].includes(p.n))).toBe(true);
    expect(early("b2-pr-11").every(p => p.n <= 3)).toBe(true);
    expect(early("b2-pr-12").every(p => p.a === 1 && p.b === 1 && p.n <= 5)).toBe(true);
    expect(early("b2-pr-13").every(p => p.T.length + p.C.length === 6)).toBe(true);
    expect(early("b2-pr-14").every(p => [1.96, 2.96].includes(p.shift))).toBe(true);
    expect(early("b2-pr-15").every(p => [2, 5].includes(p.m) && !p.gap)).toBe(true);
    expect(early("b2-pr-16").every(p => p.kind === "a" && p.r === 50)).toBe(true);
    expect(early("b2-pr-17").every(p => (p.T === 8 && p.N === 8) || (p.T === 3 && p.N === 1))).toBe(true);
    expect(early("b2-pr-18").every(p => p.am + p.as === 100 && p.bm + p.bs === 100)).toBe(true);
    expect(early("b2-pr-19").every(p => [p.a, p.b].every(v => v === 1 / 2 || v === 1 / 4))).toBe(true);
    expect(early("b2-pr-20").every(p => p.s1 === 0.006 && p.m === 1)).toBe(true);
  });
  it("Simpson problems reverse about two thirds of the time, and always at first", () => {
    const l = track.lessons.find(x => x.id === "b2-pr-18")!;
    let rev = 0;
    for (let s = 0; s < 300; s++) {
      const p = l.workIt.generate(createRng(5000 + s), 3 + (s % 5)) as any;
      const steps = l.workIt.steps(p), [A, B] = steps[4]!.answer, best = steps[6]!.answer[0];
      if ((A! > B! ? 0 : 1) !== best) rev++;
    }
    expect(rev / 300).toBeGreaterThan(0.55);
    expect(rev / 300).toBeLessThan(0.78);
  });
  it("BH problems have a miss before a pass in about half the later problems", () => {
    const l = track.lessons.find(x => x.id === "b2-pr-15")!;
    const gaps = Array.from({ length: 200 }, (_, s) => (l.workIt.generate(createRng(7000 + s), 3 + (s % 5)) as any).gap).filter(Boolean).length;
    expect(gaps).toBeGreaterThan(70);
    expect(gaps).toBeLessThan(130);
  });
});

for (const l of track.lessons) {
  describe(`${l.id} · ${l.title}`, () => {
    it(`${SEEDS} problems: the steps' answers match the oracle`, () => {
      for (const { i, p } of problems(l)) {
        const got = flat(l.workIt.steps(p)), want = l.oracle(p);
        expect(got.length, `${l.id} #${i} ${JSON.stringify(p)}`).toBe(want.length);
        got.forEach((g, k) => expect(Math.abs(g - want[k]!), `${l.id} #${i} step value ${k}: ${g} vs ${want[k]} for ${JSON.stringify(p)}`).toBeLessThan(1e-6 * Math.max(1, Math.abs(want[k]!))));
      }
    });
    it("the answer typed as the step asks is accepted; a slip's numbers bring its own message", () => {
      let slips = 0;
      for (const { p } of problems(l)) {
        for (const s of l.workIt.steps(p)) {
          const typed = s.choices ? [s.answer[0]!] : s.answer.map(a => formatAnswer(a, s.form));
          expect(checkB2Step(s, typed).ok, `${l.id} ${s.label} typed ${typed} for ${JSON.stringify(p)}`).toBe(true);
          if (!s.choices && typeof s.form === "number") {
            // one unit off in the last place is still accepted; two units off is not
            const tol = toleranceOf(s.form) / 1.0001;
            expect(checkB2Step(s, s.answer.map(a => a + tol * 0.99)).ok).toBe(true);
            expect(checkB2Step(s, s.answer.map(a => a + tol * 2.5)).ok).toBe(false);
          }
          for (const sl of s.slips) {
            slips++;
            const r = checkB2Step(s, s.choices ? sl.values : sl.values.map(v => (s.form === "fraction" ? v : Number(v.toFixed(typeof s.form === "number" ? s.form : 6)))));
            expect(r.ok, `${l.id} ${s.label} slip ${sl.kind}`).toBe(false);
            if (!r.ok && !r.soft) { expect(r.kind, `${l.id} ${s.label}`).toBe(sl.kind); expect(r.message).toBe(sl.message); }
          }
        }
      }
      expect(slips, "the lesson's slips fire").toBeGreaterThan(SEEDS);
    });
    it("early problems (index < 3) use the friendly numbers", () => {
      for (let s = 0; s < 30; s++) for (let i = 0; i < 3; i++) {
        const p = l.workIt.generate(createRng(s), i);
        const nums = JSON.stringify(p).match(/-?\d+(\.\d+)?/g)?.map(Number) ?? [];
        expect(nums.every(n => Math.abs(n) < 1e9), `${l.id} early ${JSON.stringify(p)}`).toBe(true);
      }
    });
    it("every word reads right", () => {
      const bad: string[] = [];
      const texts = [l.title, l.youCan, l.play.say, l.guess.ask, l.guess.reveal, ...l.nameIt.say, ...l.nameIt.formula, ...l.useIt.say, ...l.deeper,
        ...(l.guess.kind === "choice" ? l.guess.options : [])];
      for (const { p } of problems(l)) texts.push(l.workIt.show(p), ...strings(l.workIt.steps(p).map(s => ({ label: s.label, ask: s.ask, hint: s.hint, done: s.done, unit: s.unit, choices: s.choices, slips: s.slips.map(x => x.message) }))));
      for (const t of texts) bad.push(...lint(t));
      expect([...new Set(bad)]).toEqual([]);
    });
  });
}
