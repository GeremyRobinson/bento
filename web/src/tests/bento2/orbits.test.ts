// Orbits' generators, 60 seeds each: every step's answer matches the spec's oracle, the rounded answer is
// accepted, every slip fires with its own message, and every word reads right.
import { describe, expect, it } from "vitest";
import { createRng } from "../../curriculum/generators/rng";
import { aOrAn } from "../../curriculum/text";
import { checkB2Step, formatAnswer, toleranceOf } from "../../bento2/steps";
import { trackByCode } from "../../bento2/registry";
import type { AnyB2Lesson, B2Step } from "../../bento2/model";
import { sceneNames } from "../../bento2/scenes";
import { MU_E, conicOf, energy, hohmann, marsPlan, propagator, step, transferDrift, type State } from "../../bento2/tracks/orbits/maths";

const track = trackByCode("or")!;
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
  if (/(?<![\d.,/−-])\b1 (years|light-years|seconds|days|clocks|hours|minutes|times)\b/.test(t)) bad.push("1 with a plural");
  if (/(^|[^\w.])1(x|β|γ|c|r|v|a)\b/.test(t)) bad.push("coefficient of 1");
  return bad.map(b => `${b}: ${t}`);
}

describe("Orbits: the track", () => {
  it("has 12 lessons, b2-or-01 to b2-or-12, in four units", () => {
    expect(track.lessons.map(l => l.id)).toEqual(Array.from({ length: 12 }, (_, i) => `b2-or-${String(i + 1).padStart(2, "0")}`));
    expect(track.units.map(u => track.lessons.filter(l => l.unit === u.n).length)).toEqual([3, 3, 3, 3]);
    expect(track.projects.map(p => p.after)).toEqual(["b2-or-03", "b2-or-06", "b2-or-09", "b2-or-12"]);
    expect(track.buildPieces).toEqual(["v_LEO", "vratio_mars", "h_step", "ve", "dv_hohmann", "phase_mars", "dv_depart", "dv_capture", "mission"]);
  });
  it("every lesson has every part of the spec block, and every picture it names exists", () => {
    const pics = new Set(sceneNames());
    for (const l of track.lessons) {
      expect(l.youCan, l.id).toMatch(/^[a-z]/);
      expect(l.nameIt.say.length, l.id).toBeGreaterThanOrEqual(1);
      expect(l.nameIt.say.length, l.id).toBeLessThanOrEqual(3);
      expect(l.nameIt.formula.length, l.id).toBeGreaterThan(0);
      expect(l.deeper.length, l.id).toBeGreaterThan(0);
      expect(l.useIt.say.length, l.id).toBeGreaterThan(0);
      if (l.guess.kind === "choice") expect(l.guess.options[l.guess.answer], l.id).toBeDefined();
      const refs = [l.play, l.guess, l.useIt.scene, l.workIt.scene?.(l.workIt.reference)].filter(Boolean) as { scene: string }[];
      for (const r of refs) expect(pics.has(r.scene), `${l.id} ${r.scene}`).toBe(true);
      if (l.useIt.project) expect(track.projects.some(p => p.id === l.useIt.project), l.id).toBe(true);
    }
    for (const t of track.tools) expect(pics.has(t.id), t.id).toBe(true);
    for (const p of track.projects) expect(pics.has(p.scene.scene), p.id).toBe(true);
  });
  it("every Guess picture starts with its answer hidden (quiet or hide) and the reveal turns it on", () => {
    for (const l of track.lessons) expect(l.guess.props?.quiet === true || l.guess.props?.hide === true, l.id).toBe(true);
  });
  const answers = (id: string, p?: unknown) => {
    const l = track.lessons.find(x => x.id === id)!;
    return l.workIt.steps(p ?? l.workIt.reference).map(s => s.answer.map(a => formatAnswer(a, s.choices ? "whole" : s.form)).join(", "));
  };
  it("the reference problems give the spec's worked examples", () => {
    expect(answers("b2-or-01")).toEqual(["6,771", "8.69", "89"]);
    expect(answers("b2-or-02")).toEqual(["6,671", "7.73"]);
    expect(answers("b2-or-03")).toEqual(["1", "42,164"]);
    expect(answers("b2-or-04")).toEqual(["5", "3", "3/5", "4"]);
    expect(answers("b2-or-05")).toEqual(["10"]);
    expect(answers("b2-or-06")).toEqual(["24,500", "9.88", "1.65"]);
    expect(answers("b2-or-07")).toEqual(["−1, 0", "1, 1/2", "−1/2, 1", "−0.269", "0", "3/4, 1/2"]);
    expect(answers("b2-or-08")).toEqual(["4.41", "2.26", "55.7"]);
    expect(answers("b2-or-09")).toEqual(["5/2", "1.26", "0.26", "0.18"]);
    expect(answers("b2-or-10")).toEqual(["998", "11.87", "97", "0", "399"]);
    expect(answers("b2-or-11")).toEqual(["10.93", "11.34", "3.61"]);
    expect(answers("b2-or-12")).toEqual(["2.95", "2.65", "259", "44", "3.59", "2.08", "5.67", "72.3"]);
  });
  it("the spec's other worked numbers", () => {
    const last = (id: string, p: unknown) => answers(id, p).at(-1);
    expect([400, 2000, 6371, 35786].map(h => answers("b2-or-01", { kind: 1, h })[1])).toEqual(["8.69", "5.68", "2.45", "0.22"]);
    expect([2, 3, 4, 5, 10].map(k => answers("b2-or-01", { kind: 0, k })[0])).toEqual(["1/4", "1/9", "1/16", "1/25", "1/100"]);
    expect([400, 500, 1000, 2000, 20200].map(h => last("b2-or-02", { kind: 1, h }))).toEqual(["7.67", "7.62", "7.35", "6.90", "3.87"]);
    expect([4, 9, 16, 25].map(k => last("b2-or-02", { kind: 0, k }))).toEqual(["1/2", "1/3", "1/4", "1/5"]);
    expect([1, 4, 9, 16, 25].map(a => last("b2-or-03", { kind: 0, a }))).toEqual(["1", "8", "27", "64", "125"]);
    expect([8, 27, 64].map(T => last("b2-or-03", { kind: 1, T }))).toEqual(["4", "9", "16"]);
    expect([300, 400, 2000].map(h => last("b2-or-03", { kind: 2, h }))).toEqual(["90.4", "92.4", "127.0"]);
    expect(answers("b2-or-04", { c: 8, b: 6, a: 10, unit: "AU" })).toEqual(["10", "8", "4/5", "6"]);
    expect(last("b2-or-05", { kind: 1, body: "Earth", rn: 0.9833, rf: 1.0167, vn: 30.29 })).toBe("29.29");
    expect([[1, 5], [1, 3], [1, 2], [3, 5]].map(([en, ed]) => last("b2-or-05", { kind: 2, en, ed }))).toEqual(["3/2", "2", "3", "4"]);
    expect(answers("b2-or-06", { kind: 0, mu: 8, r: 2, v: 1 })).toEqual(["−3.5", "0", "8/7"]);
    expect(answers("b2-or-06", { kind: 0, mu: 8, r: 2, v: 2 })).toEqual(["−2.0", "1", "2"]);
    expect(answers("b2-or-06", { kind: 0, mu: 8, r: 2, v: 3 })).toEqual(["0.5", "2"]);
    expect(answers("b2-or-06", { kind: 0, mu: 8, r: 4, v: 2 })).toEqual(["0.0", "2"]);
    expect([0, 1, 2].map(where => last("b2-or-06", { kind: 1, where }))).toEqual(["11.19", "10.93", "5.03"]);
    expect([4, 5, 10].map(hd => answers("b2-or-07", { hd })[3])).toEqual(["−0.439", "−0.461", "−0.490"]);
    expect(answers("b2-or-07", { hd: 4 }).at(-1)).toBe("15/16, 1/4");
    expect([[3, 0, 2], [3, 4, 0], [2.5, 5, 0]].map(([ve, n, e]) => last("b2-or-08", { kind: 0, ve, n, e }))).toEqual(["6.00", "4.16", "4.02"]);
    expect([300, 350].map(isp => answers("b2-or-08", { kind: 1, isp, dv: 3.59 })[0])).toEqual(["2.94", "3.43"]);
    expect([2, 3, 9].map(r2 => answers("b2-or-09", { kind: 0, r2 }).slice(1))).toEqual([["1.15", "0.15", "0.13"], ["1.22", "0.22", "0.17"], ["1.34", "0.34", "0.18"]]);
    expect(answers("b2-or-09", { kind: 1, h1: 300, r2: 42164, name: "geostationary orbit" })).toEqual(["24,418", "2.43", "1.47", "3.90", "5.27"]);
    expect(answers("b2-or-10", { kind: 1, name: "Venus" })).toEqual(["146", "0.61", "54", "1", "583"]);
    expect(answers("b2-or-10", { kind: 1, name: "Saturn" })).toEqual(["2,208", "29.45", "106", "0", "378"]);
    expect([2, 3, 4, 8].map(T2 => last("b2-or-10", { kind: 0, T2 }))).toEqual(["2", "3/2", "4/3", "8/7"]);
    expect([2.5, 3.5].map(vinf => answers("b2-or-11", { kind: 0, h: 300, vinf }).slice(1))).toEqual([["11.21", "3.48"], ["11.48", "3.75"]]);
    expect(answers("b2-or-11", { kind: 1, vinf: 2.65 })).toEqual(["4.75", "3.36", "2.08"]);
    expect([2, 3].map(vinf => last("b2-or-11", { kind: 1, vinf }))).toEqual(["1.80", "2.26"]);
  });
  it("Use it saves the shelf values the spec names", () => {
    const saved = Object.fromEntries(track.lessons.flatMap(l => (l.useIt.saves ? [[l.useIt.saves.name, l.useIt.saves.value()]] : [])));
    expect(Object.keys(saved)).toEqual(["g_ISS", "v_LEO", "halley_a", "vratio_mars", "h_step", "ve", "phase_mars"]);
    expect((saved.g_ISS as number).toFixed(2)).toBe("8.69");
    expect((saved.v_LEO as number).toFixed(2)).toBe("7.73");
    expect((saved.halley_a as number).toFixed(3)).toBe("17.843");
    expect(saved.vratio_mars).toBe(1.524);
    expect((saved.ve as number).toFixed(2)).toBe("4.41");
    expect(Math.round(saved.phase_mars as number)).toBe(44);
    // h_step: the largest whole number of hours that keeps the transfer within 0.1%, and one more hour doesn't
    const h = saved.h_step as number;
    expect(transferDrift(h)).toBeLessThanOrEqual(0.001);
    expect(transferDrift(h + 1)).toBeGreaterThan(0.001);
    const m = marsPlan(300, 400, 450);
    expect([m.dep, m.cap, m.total].map(x => x.toFixed(2))).toEqual(["3.59", "2.08", "5.67"]);
    expect(m.days.toFixed(0)).toBe("259");
  });
  it("the orbit engine: conics, Kepler's equation and the steppers agree with the formulas", () => {
    // a launch 10% above circular speed has its far point at 1.21/0.79 of the start distance
    const c = conicOf(1, 1, 0, 0, 1.1);
    expect(c.kind).toBe("ellipse");
    expect(c.far).toBeCloseTo(1.21 / 0.79, 9);
    expect(conicOf(1, 1, 0, 0, Math.SQRT2 * 1.01).kind).toBe("hyperbola");
    expect(conicOf(1, 1, 0, 0, 1).kind).toBe("circle");
    // after one full period the propagated body is back where it started; an open orbit moves away for good
    const pr = propagator(1, 1, 0, 0.2, 1.1)!;
    const back = pr.pos(pr.period);
    expect(back.x).toBeCloseTo(1, 6);
    expect(back.y).toBeCloseTo(0, 6);
    const hy = propagator(1, 1, 0, 0, 1.6)!;
    expect(hy.pos(50).r).toBeGreaterThan(hy.pos(10).r);
    // Euler's energy climbs, symplectic Euler's stays near −0.5 over 100 orbits
    let a: State = { x: 1, y: 0, vx: 0, vy: 1 }, b = a;
    for (let i = 0; i < 6283; i++) { a = step(a, 0.1, 1, "symplectic"); if (Math.hypot(b.x, b.y) < 50) b = step(b, 0.1, 1, "euler"); }
    expect(Math.abs(energy(a, 1) + 0.5)).toBeLessThan(0.01);
    expect(energy(b, 1)).toBeGreaterThan(-0.1);
    expect(hohmann(MU_E, 6671e3, 42164e3).dv1 / 1000).toBeCloseTo(2.428, 3);
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
