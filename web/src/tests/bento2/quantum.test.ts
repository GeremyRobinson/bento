// Quantum's generators, 60 seeds each: every step's answer matches the spec's oracle, the rounded answer is
// accepted, every slip fires with its own message, and every word reads right.
import { describe, expect, it } from "vitest";
import { createRng } from "../../curriculum/generators/rng";
import { aOrAn } from "../../curriculum/text";
import { checkB2Step, formatAnswer, toleranceOf } from "../../bento2/steps";
import { trackByCode } from "../../bento2/registry";
import type { AnyB2Lesson, B2Step } from "../../bento2/model";
import { sceneByName } from "../../bento2/scenes";
import { toolMeta } from "../../bento2/tools/ToolShell";

const track = trackByCode("qu")!;
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
  if (/(?<![\d.,/−-])\b1 (years|seconds|days|shots|rounds|qubits|looks|pairs|amplitudes|items)\b/.test(t)) bad.push("1 with a plural");
  if (/(^|[^\w.])1(x|β|γ|c)\b/.test(t)) bad.push("coefficient of 1");
  return bad.map(b => `${b}: ${t}`);
}

describe("Quantum: the track", () => {
  it("has 12 lessons, b2-qu-01 to b2-qu-12, in four units", () => {
    expect(track.lessons.map(l => l.id)).toEqual(Array.from({ length: 12 }, (_, i) => `b2-qu-${String(i + 1).padStart(2, "0")}`));
    expect(track.units.map(u => track.lessons.filter(l => l.unit === u.n).length)).toEqual([3, 3, 3, 3]);
    expect(track.projects.map(p => p.after)).toEqual(["b2-qu-03", "b2-qu-06", "b2-qu-09", "b2-qu-12"]);
    expect(track.buildPieces).toEqual(["psi", "dial", "bell", "grover"]);
    expect(track.projects.at(-1)!.build).toBe(true);
  });
  it("every lesson has every part of the spec block, and every picture and tool it names exists", () => {
    for (const l of track.lessons) {
      expect(l.youCan, l.id).toMatch(/^[a-z]/);
      expect(l.nameIt.say.length, l.id).toBeGreaterThanOrEqual(1);
      expect(l.nameIt.say.length, l.id).toBeLessThanOrEqual(3);
      expect(l.nameIt.formula.length, l.id).toBeGreaterThan(0);
      expect(l.deeper.length, l.id).toBeGreaterThan(0);
      expect(l.useIt.say.length, l.id).toBeGreaterThan(0);
      if (l.guess.kind === "choice") expect(l.guess.options[l.guess.answer], l.id).toBeDefined();
      const scenes = [l.play.scene, l.guess.scene, l.useIt.scene?.scene, l.workIt.scene?.(l.workIt.reference).scene].filter(Boolean) as string[];
      for (const s of scenes) expect(sceneByName(s), `${l.id} scene ${s}`).toBeDefined();
      for (const t of l.tools) expect(toolMeta(t, track), `${l.id} tool ${t}`).toBeDefined();
      if (l.useIt.project) expect(track.projects.map(p => p.id)).toContain(l.useIt.project);
    }
    for (const p of track.projects) expect(sceneByName(p.scene.scene), p.id).toBeDefined();
    for (const t of track.tools) expect(sceneByName(t.id), t.id).toBeDefined();
  });
  const answers = (id: string, p?: unknown) => { const l = track.lessons.find(x => x.id === id)!; return l.workIt.steps(p ?? l.workIt.reference).map(s => s.answer.map(a => formatAnswer(a, s.choices ? "whole" : s.form)).join(", ")); };
  it("the reference problems give the spec's worked examples", () => {
    expect(answers("b2-qu-01")).toEqual(["0.25", "0.12", "0.37", "0.25"]);
    expect(answers("b2-qu-02")).toEqual(["5", "5", "5", "10", "50"]);
    expect(answers("b2-qu-03")).toEqual(["9", "1/3", "5/9", "4/9", "500"]);
    expect(answers("b2-qu-04")).toEqual(["1/4", "−1/2", "0.8", "36.9"]);
    expect(answers("b2-qu-05")).toEqual(["7/5", "−1/5", "7/5, −1/5", "49/50", "3/5, 4/5"]);
    expect(answers("b2-qu-06")).toEqual(["1/2", "−1/2", "1/4"]);
    expect(answers("b2-qu-07")).toEqual(["3/13", "36/65", "4/13", "48/65", "16/169"]);
    expect(answers("b2-qu-08")).toEqual(["3/5, 0, 4/5, 0", "3/5, 0, 0, 4/5", "12/25", "0", "1"]);
    expect(answers("b2-qu-09")).toEqual(["3/4", "1/4", "0.854", "3/4"]);
    expect(answers("b2-qu-10")).toEqual(["1, −1, −1, 1", "0", "3", "1"]);
    expect(answers("b2-qu-11")).toEqual(["−1, 1", "3/4", "5/2", "1/2", "25/32"]);
    expect(answers("b2-qu-12")).toEqual(["1, 1, 1, 1", "1, 1, −1, 1", "1, −1, 1, 1", "1, 1, −1, −1", "0, 0, 2, 0", "1"]);
  });
  it("the spec's other worked cases", () => {
    expect(answers("b2-qu-01", { a: 3, b: 4, th: 180 }).at(2)).toBe("0.01");
    expect(answers("b2-qu-01", { a: 3, b: 4, th: 0 }).at(2)).toBe("0.49");
    expect(answers("b2-qu-06", { phi: 45, P: null }).at(2)).toBe("0.854");
    expect(answers("b2-qu-06", { phi: null, P: 3 / 4 })).toEqual(["1/2", "60"]);
    expect(answers("b2-qu-10", { f: [0, 0, 1, 1] }).at(2)).toBe("2");
    expect(answers("b2-qu-10", { f: [0, 1, 0, 1] }).at(2)).toBe("1");
    expect(answers("b2-qu-10", { f: [1, 1, 1, 1] }).slice(1)).toEqual(["−1", "0", "0"]);
    expect(answers("b2-qu-11", { N: 4, k: 1 }).slice(2)).toEqual(["2", "0", "1"]);
    expect(answers("b2-qu-11", { N: 16, k: 1 }).at(-1)).toBe("121/256");
    expect(answers("b2-qu-11", { N: 16, k: 2 }).at(-1)).toBe("3721/4096");
    expect(answers("b2-qu-11", { N: 16, k: 3 }).at(-1)).toBe("0.961");
    expect(answers("b2-qu-12", { m: 3, gates: false })).toEqual(["1, 1, 1, 1", "1, 1, 1, −1", "1, 1, 1, −1", "1, −1, −1, 1", "0, 0, 0, 2", "1"]);
  });
  it("the build always finds the marked item: one round on four items, chance 1, whichever is marked", () => {
    for (const m of [0, 1, 2, 3]) {
      const s = track.lessons[11]!.workIt.steps({ m, gates: true });
      expect(s[0]!.choices![s[0]!.answer[0]!]).toBe(["X on both, CZ, X on both", "X on the top qubit, CZ, X on the top qubit", "X on the bottom qubit, CZ, X on the bottom qubit", "CZ"][m]);
      expect(s.at(-2)!.answer).toEqual([0, 1, 2, 3].map(i => (i === m ? 2 : 0)));
    }
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
