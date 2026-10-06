// Differential equations' generators, 60 seeds each: every step's answer matches the spec's oracle, the rounded answer is
// accepted, every slip fires with its own message, and every word reads right.
import { describe, expect, it } from "vitest";
import { createRng } from "../../curriculum/generators/rng";
import { aOrAn } from "../../curriculum/text";
import { checkB2Step, formatAnswer, toleranceOf } from "../../bento2/steps";
import { trackByCode } from "../../bento2/registry";
import { sceneByName } from "../../bento2/scenes";
import type { AnyB2Lesson, B2Step } from "../../bento2/model";
import { de02, de10, de14, de15 } from "../../bento2/tracks/diffeq/lessons";

const track = trackByCode("de")!;
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
  if (/(?<![\d.,/−-])\b1 (years|seconds|days|minutes|hours|swings|steps|turns|halvings|doublings)\b/.test(t)) bad.push("1 with a plural");
  if (/(^|[^\w.,])1(x|y|t|P|θ|λ|c₁|c₂|xy|x′|y′|y″|x″)(?![\w₀-₉])/.test(t)) bad.push("coefficient of 1");
  return bad.map(b => `${b}: ${t}`);
}

describe("Differential equations: the track", () => {
  it("has 15 lessons, b2-de-01 to b2-de-15, in four units, with chaos as the optional Deeper lesson", () => {
    expect(track.pickerId).toBe("change");
    expect(track.lessons.map(l => l.id)).toEqual(Array.from({ length: 15 }, (_, i) => `b2-de-${String(i + 1).padStart(2, "0")}`));
    expect(track.units.map(u => track.lessons.filter(l => l.unit === u.n).length)).toEqual([4, 4, 3, 4]);
    expect(track.lessons.filter(l => l.optional).map(l => l.id)).toEqual(["b2-de-15"]);
    expect(track.projects.map(p => p.after)).toEqual(["b2-de-04", "b2-de-08", "b2-de-11", "b2-de-14", "b2-de-14"]);
    expect(track.projects.filter(p => p.build).map(p => p.id)).toEqual(["de-models"]);
    expect(track.buildPieces).toEqual(["allee_A", "K_fish", "stepper", "H_safe", "A_pend", "A_saddle", "A_node", "A_spiral", "A_center", "zeta", "L_pend", "T_pend", "A_drive", "R0", "vax_needed"]);
  });
  it("every lesson has every part of the spec block, and every tool and picture it names exists", () => {
    const tools = new Set([...track.tools.map(t => t.id), "calc", "graph2d", "graph3d", "matrix", "shelf", "units", "scratch", "notebook"]);
    for (const l of track.lessons) {
      expect(l.youCan, l.id).toMatch(/^[a-z]/);
      expect(l.nameIt.say.length, l.id).toBeGreaterThanOrEqual(1);
      expect(l.nameIt.say.length, l.id).toBeLessThanOrEqual(3);
      expect(l.nameIt.formula.length, l.id).toBeGreaterThan(0);
      expect(l.deeper.length, l.id).toBeGreaterThan(0);
      expect(l.useIt.say.length, l.id).toBeGreaterThan(0);
      if (l.guess.kind === "choice") expect(l.guess.options[l.guess.answer], l.id).toBeDefined();
      for (const t of l.tools) expect(tools.has(t), `${l.id} tool ${t}`).toBe(true);
      const scenes = [l.play.scene, l.guess.scene, l.useIt.scene?.scene, l.workIt.scene?.(l.workIt.reference).scene].filter(Boolean) as string[];
      for (const sc of scenes) expect(sceneByName(sc), `${l.id} scene ${sc}`).toBeDefined();
      if (l.useIt.project) expect(track.projects.some(p => p.id === l.useIt.project), l.id).toBe(true);
    }
    for (const p of track.projects) expect(sceneByName(p.scene.scene), p.id).toBeDefined();
    for (const t of track.tools) expect(sceneByName(t.id), t.id).toBeDefined();
  });
  it("the reference problems give the spec's worked examples", () => {
    const answers = (id: string, p?: unknown) => { const l = track.lessons.find(x => x.id === id)!; return l.workIt.steps(p ?? l.workIt.reference).map(s => s.answer.map(a => formatAnswer(a, s.choices ? "whole" : s.form)).join(", ")); };
    expect(answers("b2-de-01")).toEqual(["−1, 2, 4", "6", "0", "2"]);
    expect(answers("b2-de-02")).toEqual(["64", "3", "28", "0.0693"]);
    // kind 1: y′ + (2/t)y = 4t, y(1) = 3: factor t², C = 2, y(2) = 9/2
    const k1 = { kind: 1, n: 2, m: 2, a: 1, y0: 3, order: [0, 1, 2, 3] } as const;
    expect(answers("b2-de-02", k1)).toEqual(["0", "2", "9/2"]);
    expect(de02.workIt.steps({ ...k1, order: [...k1.order] })[0]!.choices).toEqual(["t²", "2t", "e^(2t)", "2 ln t"]);
    expect(de02.workIt.steps({ ...k1, n: 1, order: [...k1.order] })[0]!.choices).toEqual(["t", "t²", "eᵗ", "ln t"]);
    expect(answers("b2-de-03")).toEqual(["1", "3/2", "2", "7/4", "0"]);
    expect(answers("b2-de-04")).toEqual(["25", "20, 80", "1", "0"]);
    expect(answers("b2-de-05")).toEqual(["0, 1, −2, −3", "−1, 1", "1"]);
    expect(answers("b2-de-06")).toEqual(["2, −3", "3, −1", "1", "2", "2, 1"]);
    expect(answers("b2-de-07")).toEqual(["−2, 5", "−16", "−1, 2", "0", "1", "0.043"]);
    expect(answers("b2-de-08")).toEqual(["−6, 8", "4", "1", "0"]);
    expect(answers("b2-de-09")).toEqual(["3", "2.09", "12", "1/2", "1"]);
    expect(answers("b2-de-10")).toEqual(["2.01", "2", "6.26", "0.99"]);
    expect([0.25, 0.5, 2].map(L => { const s = de10.workIt.steps({ L }); return [formatAnswer(s[0]!.answer[0]!, 2), formatAnswer(s[2]!.answer[0]!, 2)]; }))
      .toEqual([["1.00", "3.13"], ["1.42", "4.43"], ["2.84", "8.86"]]);
    expect(answers("b2-de-11")).toEqual(["9", "12", "15", "2", "1"]);
    expect(answers("b2-de-12")).toEqual(["−2, 0, 2", "8", "−8", "0", "3"]);
    expect(answers("b2-de-13")).toEqual(["50", "20", "1/2", "8.89", "0"]);
    expect(answers("b2-de-14")).toEqual(["4", "75.0", "1/4", "40.3"]);
    expect(([[0.5, 4], [0.5, 5], [0.6, 5], [0.5, 10]] as const).map(([beta, D]) => formatAnswer(de14.workIt.steps({ beta, D })[3]!.answer[0]!, 1))).toEqual(["15.3", "23.3", "30.0", "47.8"]);
    expect(answers("b2-de-15")).toEqual(["3/5", "−1/2", "0"]);
    expect(de15.workIt.steps({ kind: 1, k: 6, G: 0.1 }).map(s => s.answer[0])).toEqual([17]);
  });
  it("tolerance edges: the rounding rule works on the track's own decimals and fractions", () => {
    const k = de02.workIt.steps({ kind: 0, A: 20, gap: 64, h: 10, n: 3 })[3]!;
    expect(checkB2Step(k, ["0.0693"]).ok).toBe(true);
    expect(checkB2Step(k, ["0.0694"]).ok).toBe(true);
    expect(checkB2Step(k, ["0.0696"]).ok).toBe(false);
    expect(checkB2Step(k, ["0.0301"])).toMatchObject({ ok: false, kind: "log base 10" });
    const T = de10.workIt.steps({ L: 1 })[0]!;
    expect(checkB2Step(T, ["2.01"]).ok).toBe(true);
    expect(checkB2Step(T, ["2"]).ok).toBe(true);
    expect(checkB2Step(T, ["2.04"]).ok).toBe(false);
    const f = de15.workIt.steps({ kind: 0, r: 5 / 2 })[0]!;
    expect(checkB2Step(f, ["6/10"]).ok).toBe(true);
    expect(checkB2Step(f, ["0.6"]).ok).toBe(true);
    expect(checkB2Step(f, ["2/5"])).toMatchObject({ ok: false, kind: "1/r" });
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
    it("early problems (index < 3) use the friendly numbers: small inputs, short answers", () => {
      for (let s = 0; s < 30; s++) for (let i = 0; i < 3; i++) {
        const p = l.workIt.generate(createRng(s), i);
        const nums = JSON.stringify(p).match(/-?\d+(\.\d+)?/g)?.map(Number) ?? [];
        expect(nums.every(n => Math.abs(n) <= 200), `${l.id} early ${JSON.stringify(p)}`).toBe(true);
        for (const st of l.workIt.steps(p)) for (const a of st.answer) {
          const shown = formatAnswer(a, st.choices ? "whole" : st.form);
          expect(shown.replace(/[−,.]/g, "").length, `${l.id} early ${st.label} ${shown}`).toBeLessThanOrEqual(5);
        }
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
