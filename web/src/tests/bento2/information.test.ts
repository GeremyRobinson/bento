// Information's generators, 60 seeds each: every step's answer matches the spec's oracle, the rounded answer is
// accepted, every slip fires with its own message, and every word reads right.
import { describe, expect, it } from "vitest";
import { createRng } from "../../curriculum/generators/rng";
import { aOrAn } from "../../curriculum/text";
import { checkB2Step, formatAnswer, toleranceOf } from "../../bento2/steps";
import { trackByCode } from "../../bento2/registry";
import type { AnyB2Lesson, B2Step } from "../../bento2/model";
import { sceneByName } from "../../bento2/scenes";
import { toolMeta } from "../../bento2/tools/ToolShell";

const track = trackByCode("in")!;
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
  if (/(?<![\d.,/−-])\b1 (years|light-years|seconds|days|clocks|bits|questions|letters|outcomes|flips|labels|blocks|copies)\b/.test(t)) bad.push("1 with a plural");
  if (/(^|[^\w.])1(x|β|γ|c)\b/.test(t)) bad.push("coefficient of 1");
  return bad.map(b => `${b}: ${t}`);
}

describe("Information: the track", () => {
  it("has 12 lessons, b2-in-01 to b2-in-12, in three units", () => {
    expect(track.lessons.map(l => l.id)).toEqual(Array.from({ length: 12 }, (_, i) => `b2-in-${String(i + 1).padStart(2, "0")}`));
    expect(track.units.map(u => track.lessons.filter(l => l.unit === u.n).length)).toEqual([4, 4, 4]);
    expect(track.projects.map(p => p.after)).toEqual(["b2-in-04", "b2-in-06", "b2-in-08", "b2-in-12"]);
    expect(track.buildPieces).toEqual(["bits_flat", "H_msg", "code_msg", "model_msg", "xent_msg", "armor", "final_bpl"]);
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
  });
  it("the reference problems give the spec's worked examples", () => {
    const answers = (id: string) => { const l = track.lessons.find(x => x.id === id)!; return l.workIt.steps(l.workIt.reference).map(s => s.choices ? s.choices[s.answer[0]!]! : s.answer.map(a => formatAnswer(a, s.form)).join(", ")); };
    expect(answers("b2-in-01")).toEqual(["7", "4.70", "14.10"]);
    expect(answers("b2-in-02")).toEqual(["4", "5", "p = 1/6"]);
    expect(answers("b2-in-03")).toEqual(["1, 2, 2", "Multiply each surprise by its p", "1.500", "(1/4, 1/4, 1/4, 1/4)"]);
    expect(answers("b2-in-04")).toEqual(["3.322", "0.152", "0.469", "469"]);
    expect(answers("b2-in-05")).toEqual(["1", "Yes", "A C B A D"]);
    expect(answers("b2-in-06")).toEqual(["C and D", "1", "20", "2.00", "30"]);
    expect(answers("b2-in-07")).toEqual(["16", "15", "1/128", "0.987", "L = 1.75"]);
    expect(answers("b2-in-08")).toEqual(["1, 2, 1, 3", "7", "1/128", "1"]);
    expect(answers("b2-in-09")).toEqual(["1.750", "2.000", "0.250", "1.00"]);
    expect(answers("b2-in-10")).toEqual(["1.000", "0.811", "1.500", "0.311"]);
    expect(answers("b2-in-11")).toEqual(["1, 2, 3, 5", "5", "1,110,000", "0.028", "0.531"]);
    expect(answers("b2-in-12")).toEqual(["3,200", "2.25", "3.56", "1,575", "1.85"]);
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
