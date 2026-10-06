// Multivariable's generators, 60 seeds each: every step's answer matches the spec's oracle, the rounded answer is
// accepted, every slip fires with its own message, and every word reads right.
import { describe, expect, it } from "vitest";
import { createRng } from "../../curriculum/generators/rng";
import { aOrAn } from "../../curriculum/text";
import { checkB2Step, formatAnswer, toleranceOf } from "../../bento2/steps";
import { trackByCode } from "../../bento2/registry";
import type { AnyB2Lesson, B2Step } from "../../bento2/model";
import { MV_LESSONS } from "../../bento2/tracks/multivariable/lessons";
import { flatSpots, LAND, LAND_BOX, mono, terms } from "../../bento2/tracks/multivariable/maths";

const track = trackByCode("mv")!;
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
  if (/(?<![\d.,/−-])\b1 (years|seconds|days|steps|times|balls|valleys|boxes)\b/.test(t)) bad.push("1 with a plural");
  if (/(^|[^\w.])1(x|y|t|λ|β|γ|c)\b/.test(t)) bad.push("coefficient of 1");
  return bad.map(b => `${b}: ${t}`);
}

describe("Multivariable: the track", () => {
  it("has 20 lessons, b2-mv-01 to b2-mv-20, in six units", () => {
    expect(track.lessons.map(l => l.id)).toEqual(Array.from({ length: 20 }, (_, i) => `b2-mv-${String(i + 1).padStart(2, "0")}`));
    expect(track.units.map(u => track.lessons.filter(l => l.unit === u.n).length)).toEqual([4, 4, 2, 4, 3, 3]);
    expect(track.projects.map(p => p.after)).toEqual(["b2-mv-04", "b2-mv-08", "b2-mv-12", "b2-mv-16", "b2-mv-20"]);
    expect(track.projects.map(p => p.shelf).flat()).toEqual(["land", "lakeVolume", "lakeArea", "basins", "fencedBest", "lowest"]);
    expect(track.pickerId).toBe("hills");
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
      if (l.useIt.project) expect(track.projects.some(p => p.id === l.useIt.project), l.id).toBe(true);
    }
  });
  const answers = (id: string, p?: unknown) => { const l = track.lessons.find(x => x.id === id)!; return l.workIt.steps(p ?? l.workIt.reference).map(s => s.answer.map(a => formatAnswer(a, s.choices ? "whole" : s.form)).join(", ")); };
  const tapped = (id: string, p?: unknown) => { const l = track.lessons.find(x => x.id === id)!; return l.workIt.steps(p ?? l.workIt.reference).filter(s => s.choices).map(s => s.choices![s.answer[0]!]); };
  it("the reference problems give the spec's worked examples", () => {
    expect(answers("b2-mv-01")).toEqual(["8", "6", "3", "1"]);
    expect(tapped("b2-mv-01")).toEqual(["y"]);
    expect(answers("b2-mv-02")).toEqual(["0", "10", "0", "8"]);
    expect(tapped("b2-mv-02")).toEqual(["6xy − 2", "3x² + 5"]);
    expect(answers("b2-mv-03")).toEqual(["3", "8", "−1", "3.9"]);
    expect(answers("b2-mv-04")).toEqual(["2, 1", "4, 4", "1, 2", "12"]);
    expect(answers("b2-mv-05")).toEqual(["6", "0", "33", "11/2"]);
    expect(tapped("b2-mv-05")).toEqual(["15x/2 + 9"]);
    expect(answers("b2-mv-06")).toEqual(["2", "0", "4/3", "0"]);
    expect(tapped("b2-mv-06")).toEqual(["y = x² to y = 2x", "y from 0 to 4, x from y/2 to √y"]);
    expect(answers("b2-mv-07")).toEqual(["1", "0, 2", "2", "4"]);
    expect(tapped("b2-mv-07")).toEqual(["π", "r³"]);
    expect(answers("b2-mv-08")).toEqual(["−2", "8", "4"]);
    expect(answers("b2-mv-09")).toEqual(["2, −1", "1", "3, 1", "2", "0"]);
    expect(tapped("b2-mv-09")).toEqual(["Spreads"]);
    expect(answers("b2-mv-10")).toEqual(["6", "3"]);
    expect(answers("b2-mv-10", { loop: true, a: 0, b: 1, c: 2, d: 0, p: 0, q: 0, m: 2, n: 3 })).toEqual(["1", "6", "6"]);
    expect(answers("b2-mv-11")).toEqual(["5, 3", "5", "3/5, 4/5", "27/5"]);
    expect(answers("b2-mv-12")).toEqual(["6, 8", "10.00", "0", "0"]);
    expect(tapped("b2-mv-12")).toEqual(["⟨−6, −8⟩"]);
    expect(answers("b2-mv-13")).toEqual(["2", "1", "6, 4, 0", "24", "0", "2"]);
    expect(tapped("b2-mv-13")).toEqual(["Pit", "Pass"]);
    expect(answers("b2-mv-14")).toEqual(["8, 8", "2, 0", "1/2", "1", "1/2"]);
    expect(answers("b2-mv-15")).toEqual(["0", "6", "4", "24", "2"]);
    expect(tapped("b2-mv-15")).toEqual(["y = 2λ, x = 3λ"]);
    expect(answers("b2-mv-16")).toEqual(["1", "2, 1", "1", "10"]);
    expect(answers("b2-mv-17")).toEqual(["0, 2, 9, 5", "5/2", "3"]);
    expect(answers("b2-mv-17", { ys: [1, 2, 4, 5] })).toEqual(["12, 25", "7/5", "9/10"]);
    expect(answers("b2-mv-18")).toEqual(["4, 2, 3", "−1", "1"]);
    expect(answers("b2-mv-18", { kindB: true, a: 1, b: 0, c: 4 })).toEqual(["4"]);
    expect(answers("b2-mv-19")).toEqual(["3", "1/4", "1/2", "10", "1"]);
    expect(answers("b2-mv-20")).toEqual(["1", "−1", "1", "1", "0.368"]);
    expect(tapped("b2-mv-20")).toEqual(["The right bottom"]);
  });
  it("the spec's checked values: 19's step counts, 06 and 07 against midpoint sums", () => {
    const l19 = MV_LESSONS[18]!;
    const n = (a: number, b: number) => l19.workIt.steps({ a, b })[3]!.answer[0];
    expect([n(1, 2), n(1, 3), n(2, 3), n(1, 4), n(1, 9), n(1, 30)]).toEqual([7, 10, 5, 14, 31, 104]);
    // 06: ∬ over x² ≤ y ≤ kx by a 400 × 400 midpoint sum, within 0.01
    for (const k of [1, 2, 3]) for (const f of [0, 1, 2]) {
      const N = 400, dx = k / N, dy = (k * k) / N;
      let s = 0;
      for (let i = 0; i < N; i++) for (let j = 0; j < N; j++) { const x = (i + 0.5) * dx, y = (j + 0.5) * dy; if (y >= x * x && y <= k * x) s += [1, x, y][f]! * dx * dy; }
      const want = MV_LESSONS[5]!.oracle({ k, f, o2: [0, 1, 2, 3], o4: [0, 1, 2, 3] })[2]!;
      expect(Math.abs(s - want) / Math.max(1, want), `k ${k} f ${f}`).toBeLessThan(0.01);
    }
    // 07: a 400-ring polar midpoint sum (the integrand doesn't depend on θ)
    for (const [kind, a, b, nn] of [[0, 0, 2, 0], [1, 0, 2, 2], [2, 0, 3, 1], [3, 1, 3, 2]] as const) {
      const ang = [2, 1, 0.5, 2][kind]! * Math.PI, N = 400, dr = (b - a) / N;
      let s = 0;
      for (let i = 0; i < N; i++) { const r = a + (i + 0.5) * dr; s += r ** nn * r * dr * ang; }
      expect(Math.abs(s / Math.PI - MV_LESSONS[6]!.oracle({ kind, a, b, n: nn })[4]!)).toBeLessThan(0.01);
    }
  });
  it("Two lakes is where the spec says: lowest near (−1.03, 0) at −0.254, a higher bottom near (0.97, 0), a pass near (0.06, 0)", () => {
    const s = flatSpots(LAND, LAND_BOX);
    expect(s.map(p => p.kind)).toEqual(["pit", "pass", "pit"]);
    expect(s[0]!.x).toBeCloseTo(-1.03, 2); expect(s[0]!.z).toBeCloseTo(-0.254, 3);
    expect(s[1]!.x).toBeCloseTo(0.06, 2);
    expect(s[2]!.x).toBeCloseTo(0.97, 2); expect(s[2]!.z).toBeCloseTo(0.246, 3);
  });
  it("the term printer drops 1s and 0s and never prints + −", () => {
    expect(terms([[1, "x²"], [-1, "y"], [0, "xy"], [-3, ""]])).toBe("x² − y − 3");
    expect(terms([[-1, mono(1, 1)], [2, mono(0, 0)]])).toBe("−xy + 2");
    expect(terms([[0, "x"]])).toBe("0");
    expect(mono(1, 0)).toBe("x");
    expect(mono(2, 3)).toBe("x²y³");
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
