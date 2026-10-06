// Computation's generators, 60 seeds each: every step's answer matches the spec's oracle, the rounded answer is
// accepted, every slip fires with its own message, and every word reads right.
import { describe, expect, it } from "vitest";
import { createRng } from "../../curriculum/generators/rng";
import { aOrAn } from "../../curriculum/text";
import { checkB2Step, formatAnswer, toleranceOf } from "../../bento2/steps";
import { trackByCode } from "../../bento2/registry";
import type { AnyB2Lesson, B2Step } from "../../bento2/model";
import { sceneByName } from "../../bento2/scenes";
import { toolMeta } from "../../bento2/tools/ToolShell";

const track = trackByCode("cs")!;
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
  if (/(?<![\d.,/−-])\b1 (years|light-years|seconds|days|clocks|bits|questions|letters|outcomes|flips|labels|blocks|copies|steps|rows|moves|adds|gates|roads|swaps|comparisons|tours|subsets|NANDs|disks|cards|items|digits)\b/.test(t)) bad.push("1 with a plural");
  if (/(^|[^\w.])1(x|β|γ|c)\b/.test(t)) bad.push("coefficient of 1");
  return bad.map(b => `${b}: ${t}`);
}

describe("Computation: the track", () => {
  it("has 15 lessons, b2-cs-01 to b2-cs-15, in three units", () => {
    expect(track.lessons.map(l => l.id)).toEqual(Array.from({ length: 15 }, (_, i) => `b2-cs-${String(i + 1).padStart(2, "0")}`));
    expect(track.units.map(u => track.lessons.filter(l => l.unit === u.n).length)).toEqual([5, 5, 5]);
    expect(track.projects.map(p => p.after)).toEqual(["b2-cs-05", "b2-cs-08", "b2-cs-12", "b2-cs-15"]);
    expect(track.projects.map(p => p.shelf[0])).toEqual(["adder4", "race_card", "puzzle", "mult4"]);
    expect(track.buildPieces).toEqual(["xor", "adder4", "race_card", "puzzle", "mult4"]);
    for (const l of track.lessons) if (l.useIt.project) expect(track.projects.map(p => p.id), l.id).toContain(l.useIt.project);
  });
  it("every lesson has every part of the spec block, and its pictures exist", () => {
    for (const l of track.lessons) {
      expect(l.youCan, l.id).toMatch(/^[a-z]/);
      expect(l.nameIt.say.length, l.id).toBeGreaterThanOrEqual(1);
      expect(l.nameIt.say.length, l.id).toBeLessThanOrEqual(3);
      expect(l.nameIt.formula.length, l.id).toBeGreaterThan(0);
      expect(l.deeper.length, l.id).toBeGreaterThan(0);
      expect(l.useIt.say.length, l.id).toBeGreaterThan(0);
      if (l.guess.kind === "choice") expect(l.guess.options[l.guess.answer], l.id).toBeDefined();
      for (const s of [l.play, l.guess, l.useIt.scene, l.workIt.scene?.(l.workIt.reference)]) if (s) expect(sceneByName(s.scene), `${l.id} ${s.scene}`).toBeDefined();
      for (const t of l.tools) expect(toolMeta(t, track), `${l.id} tool ${t}`).toBeDefined();
    }
    for (const p of track.projects) expect(sceneByName(p.scene.scene), p.id).toBeDefined();
    for (const t of track.tools) expect(sceneByName(t.id), t.id).toBeDefined();
  });
  it("every Guess picture starts quiet, so nothing gives the answer away before Lock in", () => {
    for (const l of track.lessons) expect(l.guess.props?.quiet, l.id).toBe(true);
  });
  it("the reference problems give the spec's worked examples", () => {
    const answers = (id: string) => { const l = track.lessons.find(x => x.id === id)!; return l.workIt.steps(l.workIt.reference).map(s => s.choices ? s.choices[s.answer[0]!]! : s.answer.map(a => formatAnswer(a, s.form)).join(", ")); };
    expect(answers("b2-cs-01")).toEqual(["8", "T", "3"]);
    expect(answers("b2-cs-02")).toEqual(["T", "2", "No", "If the street is dry, it didn't rain."]);
    expect(answers("b2-cs-03")).toEqual(["1", "9", "Induction hypothesis", "100"]);
    expect(answers("b2-cs-04")).toEqual(["0", "1", "3"]);
    expect(answers("b2-cs-05")).toEqual(["1, 0", "1", "1", "17", "160"]);
    expect(answers("b2-cs-06")).toEqual(["1,000", "10", "45 → 12 → 23"]);
    expect(answers("b2-cs-07")).toEqual(["1, 4, 2, 5, 8", "4", "28", "17"]);
    expect(answers("b2-cs-08")).toEqual(["100", "300", "1,000", "2ⁿ"]);
    expect(answers("b2-cs-09")).toEqual(["15", "1,023", "24"]);
    expect(answers("b2-cs-10")).toEqual(["B", "6", "A–C–D"]);
    expect(answers("b2-cs-11")).toEqual(["181,440", "16", "1.9"]);
    expect(answers("b2-cs-12")).toEqual(["32", "Valid", "12 + 9", "In P"]);
    expect(answers("b2-cs-13")).toEqual(["(carry, 1) → (0, L, carry)", "1,100", "3", "12"]);
    expect(answers("b2-cs-14")).toEqual(["L, H, L, L", "3", "Yes"]);
    expect(answers("b2-cs-15")).toEqual(["110", "2", "13, 19", "78", "1,048,576, 59,049"]);
  });
  it("the spec's other examples hold", () => {
    const step = (id: string, p: unknown, k: number) => { const l = track.lessons.find(x => x.id === id)!; return l.workIt.steps(p)[k]!; };
    // cs-06: 15 → 4, 16 → 5, 100 → 7, 1,000,000 → 20
    for (const [n, b] of [[15, 4], [16, 5], [100, 7], [1000000, 20]] as const) expect(step("b2-cs-06", { n, list: [2, 5, 8, 12, 16, 23, 38, 45, 56, 72, 77, 81, 90, 94, 99], t: 23 }, 1).answer[0]).toBe(b);
    // cs-07: merge worst case at 1,024 is 9,217
    expect(step("b2-cs-07", { list: [5, 1, 4, 2, 8], n: 1024 }, 3).answer[0]).toBe(9217);
    // cs-09: T(16) = 64, T(1,024) = 10,240
    expect(step("b2-cs-09", { h: 4, N: 10, T: 16 }, 2).answer[0]).toBe(64);
    expect(step("b2-cs-09", { h: 4, N: 10, T: 1024 }, 2).answer[0]).toBe(10240);
    // cs-11: 4 → 3, 5 → 12, 6 → 60, 8 → 2,520; the nearest-neighbor tour A–B–D–C–A is 18
    for (const [n, t] of [[4, 3], [5, 12], [6, 60], [8, 2520]] as const) expect(step("b2-cs-11", { n, D: [[0, 2, 9, 5], [2, 0, 6, 4], [9, 6, 0, 3], [5, 4, 3, 0]], m: 20 }, 0).answer[0]).toBe(t);
    expect(step("b2-cs-11", { n: 4, D: [[0, 2, 9, 5], [2, 0, 6, 4], [9, 6, 0, 3], [5, 4, 3, 0]], m: 20 }, 1).slips.map(s => s.values[0])).toContain(18);
    // cs-13: 111 → 1000 in 4 steps
    const s13 = track.lessons.find(x => x.id === "b2-cs-13")!.workIt.steps({ m: "add1", input: "111" });
    expect([s13[1]!.answer[0], s13[2]!.answer[0], s13[3]!.answer[0]]).toEqual([1000, 4, 8]);
    // cs-13: the unary adder, 111 + 11 → 11111
    expect(track.lessons.find(x => x.id === "b2-cs-13")!.workIt.steps({ m: "unary", input: "111011" })[1]!.answer[0]).toBe(11111);
    // cs-15: dropping the carry in 13 × 6 gives 14
    expect(step("b2-cs-15", { a: 13, b: 6, n: 1024 }, 3).slips.map(s => s.values[0])).toContain(14);
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
        const nums = JSON.stringify(p, (_k, v) => (typeof v === "string" ? undefined : v)).match(/-?\d+(\.\d+)?/g)?.map(Number) ?? [];
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
