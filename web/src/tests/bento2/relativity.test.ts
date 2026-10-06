// Relativity's generators, 60 seeds each: every step's answer matches the spec's oracle, the rounded answer is
// accepted, every slip fires with its own message, and every word reads right.
import { describe, expect, it } from "vitest";
import { createRng } from "../../curriculum/generators/rng";
import { aOrAn } from "../../curriculum/text";
import { checkB2Step, formatAnswer, toleranceOf } from "../../bento2/steps";
import { trackByCode } from "../../bento2/registry";
import type { AnyB2Lesson, B2Step } from "../../bento2/model";

const track = trackByCode("re")!;
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

describe("Relativity: the track", () => {
  it("has 12 lessons, b2-re-01 to b2-re-12, in four units", () => {
    expect(track.lessons.map(l => l.id)).toEqual(Array.from({ length: 12 }, (_, i) => `b2-re-${String(i + 1).padStart(2, "0")}`));
    expect(track.units.map(u => track.lessons.filter(l => l.unit === u.n).length)).toEqual([3, 4, 2, 3]);
    expect(track.projects.map(p => p.after)).toEqual(["b2-re-03", "b2-re-06", "b2-re-09", "b2-re-12"]);
    expect(track.buildPieces).toEqual(["c_light", "gamma", "boost", "twin", "sr_drift", "gr_drift", "gps_net"]);
  });
  it("every lesson has every part of the spec block", () => {
    for (const l of track.lessons) {
      expect(l.youCan, l.id).toMatch(/^[a-z]/);
      expect(l.nameIt.say.length, l.id).toBeGreaterThanOrEqual(1);
      expect(l.nameIt.say.length, l.id).toBeLessThanOrEqual(3);
      expect(l.nameIt.formula.length, l.id).toBeGreaterThan(0);
      expect(l.deeper.length, l.id).toBeGreaterThan(0);
      expect(l.useIt.say.length, l.id).toBeGreaterThan(0);
      if (l.guess.kind === "choice") expect(l.guess.options[l.guess.answer], l.id).toBeDefined();
    }
  });
  it("the reference problems give the spec's worked examples", () => {
    const answers = (id: string) => { const l = track.lessons.find(x => x.id === id)!; return l.workIt.steps(l.workIt.reference).map(s => s.answer.map(a => formatAnswer(a, s.choices ? "whole" : s.form)).join(", ")); };
    expect(answers("b2-re-01")).toEqual(["67.4", "3.0", "299.8"]);
    expect(answers("b2-re-02")).toEqual(["9/25", "4/5", "5/4", "10"]);
    expect(answers("b2-re-03")).toEqual(["2.60", "5.72", "1.58", "0.61", "3.85"]);
    expect(answers("b2-re-04")).toEqual(["5/4", "−3", "5", "1"]);
    expect(answers("b2-re-05")).toEqual(["5/4, 3/4", "4", "0", "16, 16", "1"]);
    expect(answers("b2-re-06")).toEqual(["16", "0", "4"]);
    expect(answers("b2-re-07")).toEqual(["6/5", "34/25", "15/17", "1"]);
    expect(answers("b2-re-08")).toEqual(["5", "5/3", "4/5", "2"]);
    expect(answers("b2-re-09")).toEqual(["58.83", "3.27", "28.3"]);
    expect(answers("b2-re-10")).toEqual(["0", "1.09", "9.43"]);
    expect(answers("b2-re-11")).toEqual(["0.2398", "0.7602", "45.7"]);
    expect(answers("b2-re-12")).toEqual(["7.2", "45.7", "38.5", "0", "11.5"]);
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

describe("review fixes", () => {
  it("the boost goes to the Matrix pad exactly: det 1 at β = 0.3, fractions where they exist", async () => {
    const { boostCells } = await import("../../bento2/tracks/relativity/pictures/Spacetime");
    const { calc } = await import("../../bento2/tools/expr");
    const read = (c: string[][]) => c.map(r => r.map(x => { const v = calc(x); if (!v.ok) throw new Error(x); return v.value; }));
    expect(boostCells(0.3)).toEqual([["10/√(91)", "-3/√(91)"], ["-3/√(91)", "10/√(91)"]]);
    const M = read(boostCells(0.3));
    expect(M[0]![0]! * M[1]![1]! - M[0]![1]! * M[1]![0]!).toBeCloseTo(1, 12);
    expect(boostCells(0.6)).toEqual([["5/4", "-3/4"], ["-3/4", "5/4"]]);
    expect(boostCells(-0.8)).toEqual([["5/3", "4/3"], ["4/3", "5/3"]]);
    expect(boostCells(0)).toEqual([["1", "0"], ["0", "1"]]);
  });
  it("a light-speed value saved as c by an older version reads back as c_light", async () => {
    const { readB2 } = await import("../../bento2/progress");
    const b = readB2({ shelf: { c: { value: 299792458, unit: "m/s", from: "b2-re-01", at: 1 } } });
    expect(Object.keys(b.shelf)).toEqual(["c_light"]);
    expect(track.buildPieces[0]).toBe("c_light");
  });
});
