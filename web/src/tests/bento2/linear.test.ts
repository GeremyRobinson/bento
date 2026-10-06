// Linear algebra's generators, 60 seeds each: every step's answer matches the spec's oracle, the rounded answer is
// accepted (one unit off in the last place too, two and a half not), every slip fires with its own message, early
// problems use friendly numbers, every word reads right, and the reference problems give the spec's worked examples.
import { describe, expect, it } from "vitest";
import { createRng } from "../../curriculum/generators/rng";
import { aOrAn } from "../../curriculum/text";
import { checkB2Step, formatAnswer, toleranceOf } from "../../bento2/steps";
import { trackByCode } from "../../bento2/registry";
import { sceneByName } from "../../bento2/scenes";
import type { AnyB2Lesson, B2Step } from "../../bento2/model";
import { lin, svd, rebuild, energyKept, storage, largestK, samplePhoto, IMG0 } from "../../bento2/tracks/linear/maths";

const track = trackByCode("la")!;
const SEEDS = 60;
const problems = (l: AnyB2Lesson) => Array.from({ length: SEEDS }, (_, s) => { const i = s % 8; return { i, p: l.workIt.generate(createRng(1000 + s), i) }; });
const flat = (steps: B2Step[]) => steps.flatMap(s => s.answer);
const lesson = (id: string) => track.lessons.find(x => x.id === id)!;
const answers = (id: string, p?: unknown) => { const l = lesson(id); return l.workIt.steps(p ?? l.workIt.reference).map(s => s.answer.map(a => formatAnswer(a, s.choices ? "whole" : s.form)).join(", ")); };

/** every string a learner can see in a value, deep */
const strings = (v: unknown, out: string[] = []): string[] => {
  if (typeof v === "string") out.push(v);
  else if (Array.isArray(v)) v.forEach(x => strings(x, out));
  else if (v && typeof v === "object") Object.values(v).forEach(x => strings(x, out));
  return out;
};
/** Bento's voice rules: no em-dashes, no "+ −", no float noise or undefined, a/an right before numbers, no coefficient of 1 */
function lint(t: string): string[] {
  const bad: string[] = [];
  if (/—/.test(t)) bad.push("em-dash");
  if (/\+ [−-]/.test(t)) bad.push("+ −");
  if (/− −|− -/.test(t)) bad.push("− −");
  if (/undefined|NaN|Infinity|\[object/.test(t)) bad.push("undefined");
  if (/\d\.\d*0000\d|\d\.\d*9999\d/.test(t)) bad.push("float noise");
  if (/-\d/.test(t.replace(/b2-[a-z]{2}-\d\d|g\d+-[a-z]+|st-[a-z]+/g, ""))) bad.push("hyphen for a minus");
  for (const m of t.matchAll(/\b(an?) (\d[\d,]*)(?![\d.])/gi)) if (m[1]!.toLowerCase() !== aOrAn(+m[2]!.replace(/,/g, ""))) bad.push(`a/an: ${m[0]}`);
  if (/(?<![\d.,/−-])\b1 (layers|arrows|rows|points|steps|numbers|pixels)\b/.test(t)) bad.push("1 with a plural");
  if (/(^|[^\w.,/²³])[−]?1(u|v|w|a|b|x|y|z|λ|p|q|c₁|c₂)\b/.test(t)) bad.push("coefficient of 1");
  // a scale of 1 on an arrow: "1·(3, 1)" or "−1·(3, 1)"
  if (/(^|[^\d.])−?1·\([^()]*,/.test(t)) bad.push("times 1");
  return bad.map(b => `${b}: ${t}`);
}

describe("Linear algebra: the track", () => {
  it("has 20 lessons, b2-la-01 to b2-la-20, in five units", () => {
    expect(track.lessons.map(l => l.id)).toEqual(Array.from({ length: 20 }, (_, i) => `b2-la-${String(i + 1).padStart(2, "0")}`));
    expect(track.units.map(u => track.lessons.filter(l => l.unit === u.n).length)).toEqual([4, 4, 3, 4, 5]);
    expect(track.projects.map(p => p.after)).toEqual(["b2-la-04", "b2-la-08", "b2-la-11", "b2-la-14", "b2-la-18", "b2-la-20"]);
    expect(track.projects.at(-1)!.build).toBe(true);
    expect(track.buildPieces).toEqual(["img", "basis", "shear", "layer1", "M", "Minv", "fit", "lam", "steady", "sigmaM", "plaid", "k", "sigma"]);
  });
  it("every lesson has every part of the spec block, and every picture it names exists", () => {
    const tools = new Set([...track.tools.map(t => t.id), "calc", "graph2d", "graph3d", "matrix", "shelf", "units", "scratch", "notebook"]);
    for (const l of track.lessons) {
      expect(l.youCan, l.id).toMatch(/^[a-z]/);
      expect(l.nameIt.say.length, l.id).toBeGreaterThanOrEqual(1);
      expect(l.nameIt.say.length, l.id).toBeLessThanOrEqual(3);
      expect(l.nameIt.formula.length, l.id).toBeGreaterThan(0);
      expect(l.deeper.length, l.id).toBeGreaterThanOrEqual(2);
      expect(l.useIt.say.length, l.id).toBeGreaterThan(0);
      if (l.guess.kind === "choice") expect(l.guess.options[l.guess.answer], l.id).toBeDefined();
      for (const s of [l.play, l.guess, l.useIt.scene, l.workIt.scene?.(l.workIt.reference)]) if (s) expect(sceneByName(s.scene), `${l.id} ${s.scene}`).toBeDefined();
      for (const t of l.tools) expect(tools.has(t), `${l.id} tool ${t}`).toBe(true);
      if (l.useIt.project) expect(track.projects.some(p => p.id === l.useIt.project), l.id).toBe(true);
    }
    for (const p of track.projects) expect(sceneByName(p.scene.scene), p.id).toBeDefined();
    for (const t of track.tools) expect(sceneByName(t.id), t.id).toBeDefined();
  });
  it("a project saves every name the spec gives it, and each shelf name comes from somewhere", () => {
    const fromLessons = track.lessons.flatMap(l => (l.useIt.saves ? [l.useIt.saves.name] : []));
    const fromProjects = track.projects.flatMap(p => p.shelf);
    // img (the grid editor in 01's Use it) and sigmaM (the stretch finder in 17's Use it) save from their pictures
    expect(new Set([...fromLessons, ...fromProjects, "img", "sigmaM"])).toEqual(new Set(track.buildPieces));
  });
  it("the reference problems give the spec's worked examples", () => {
    expect(answers("b2-la-01")).toEqual(["6, −2", "−1, −2", "5, −4"]);
    expect(answers("b2-la-02")).toEqual(["0", "2", "1"]);
    expect(lesson("b2-la-02").workIt.steps(lesson("b2-la-02").workIt.reference)[0]!.choices![0]).toBe("2a + b = 5 and a + b = 3");
    expect(answers("b2-la-03")).toEqual(["10", "5", "2", "4, 2", "0"]);
    expect(answers("b2-la-04")).toEqual(["2", "3", "7", "0"]);
    expect(answers("b2-la-04", { u: [1, 0, 2], v: [0, 1, 1], a: 2, b: 3, e: -2 })).toEqual(["2", "3", "7", "1"]);
    expect(answers("b2-la-05")).toEqual(["4, 2", "−1, 1", "3, 3"]);
    expect(answers("b2-la-06")).toEqual(["0, 1", "−1, 2", "1"]);
    expect(answers("b2-la-07")).toEqual(["12", "2", "10", "30", "0"]);
    expect(answers("b2-la-07", { kind: 3, A: [[1, 2, 0], [0, 1, 3], [2, 0, 1]] })).toEqual(["1", "−12", "0", "13", "13", "0"]);
    expect(answers("b2-la-08")).toEqual(["1", "3, −1, −5, 2", "3, −1, −5, 2", "1, 2"]);
    expect(answers("b2-la-09")).toEqual(["2", "1", "1", "3", "2", "1"]);
    expect(answers("b2-la-10")).toEqual(["2", "1", "−2, −3, 1"]);
    expect(answers("b2-la-10", { kind: "r1", c: [[1, 2, -1]], p: 2, q: -1, r: 0, s: 0, t: 0 })).toEqual(["1", "2", "−2", "1"]);
    expect(answers("b2-la-10", { kind: "w4", c: [[1, 0, 2], [0, 1, 1]], p: 2, q: 3, r: 1, s: -1, t: 0 })).toEqual(["2", "2", "−1, 1, 0, 1"]);
    expect(answers("b2-la-11")).toEqual(["2, 0, 0, 3", "5, 9", "5/2", "3"]);
    expect(answers("b2-la-11", { xs: [0, 1, 2, 3], ys: [1, 3, 2, 5] })).toEqual(["14, 6, 6, 4", "22, 11", "11/10", "11/10"]);
    expect(answers("b2-la-12")).toEqual(["2, −1, −1, 1", "1, 2", "3, 3", "−1, −2", "3, 0, 0, −1"]);
    expect(answers("b2-la-13")).toEqual(["7", "10", "5, 2", "1", "−2"]);
    const l14 = answers("b2-la-14");
    expect(l14.slice(1)).toEqual(["0.4", "2/3", "667"]);
    expect(lesson("b2-la-14").workIt.steps(lesson("b2-la-14").workIt.reference)[0]!.choices![+l14[0]!]).toBe("[[0.8, 0.4], [0.2, 0.6]]");
    expect(answers("b2-la-15")).toEqual(["6, 1", "1/2", "−2", "0", "0"]);
    expect(answers("b2-la-16")).toEqual(["9", "9", "1", "2, −2, 1", "3", "0"]);
    expect(answers("b2-la-17")).toEqual(["25, 20, 20, 25", "45, 5", "6.71", "2.24", "15"]);
    expect(answers("b2-la-17", { A: [[2, 0], [0, -3]] }).slice(2, 4)).toEqual(["3", "2"]);
    expect(answers("b2-la-18")).toEqual(["50", "72.0", "2.24", "2"]);
    expect(answers("b2-la-19")).toEqual(["5, 3", "10, 8, 8, 10", "18, 2", "90.0", "1"]);
    expect(answers("b2-la-20")).toEqual(["2,010", "10,000", "20.1", "49"]);
  });
  it("the sign helper never prints a coefficient of 1 or a plus before a minus", () => {
    expect(lin([[2, "u"], [-3, "v"]])).toBe("2u − 3v");
    expect(lin([[1, "u"], [-1, "v"]])).toBe("u − v");
    expect(lin([[-1, "u"], [0, "v"]])).toBe("−u");
    expect(lin([[0, "x"], [0, "y"]])).toBe("0");
    expect(lin([[-4, ""], [-3, ""], [7, ""]])).toBe("−4 − 3 + 7");
  });
  it("the SVD rebuilds a picture exactly, its layers' energy adds up, and the build's storage rule holds", () => {
    const d = svd(IMG0);
    const back = rebuild(d, 8);
    back.forEach((r, i) => r.forEach((v, j) => expect(Math.abs(v - IMG0[i]![j]!)).toBeLessThan(1e-9)));
    const total = IMG0.flat().reduce((s, v) => s + v * v, 0);
    expect(Math.abs(d.s.reduce((s, x) => s + x * x, 0) - total)).toBeLessThan(1e-8);
    for (let k = 1; k < 8; k++) expect(d.s[k]!).toBeLessThanOrEqual(d.s[k - 1]! + 1e-12);
    expect(energyKept(d.s, 8)).toBeCloseTo(1, 12);
    const ph = svd(samplePhoto(40, 40));
    expect(energyKept(ph.s, 10)).toBeGreaterThan(0.95);
    expect(storage(10, 100, 100)).toBe(2010);
    for (const [m, n] of [[100, 100], [64, 128], [200, 512]] as [number, number][]) {
      const k = largestK(m, n);
      expect(storage(k, m, n)).toBeLessThan(m * n);
      expect(storage(k + 1, m, n)).toBeGreaterThanOrEqual(m * n);
    }
  });
});

/** what "friendly" means for each lesson's early problems: the largest number that may appear */
const EARLY_MAX: Record<string, number> = { "b2-la-14": 1000, "b2-la-18": 99, "b2-la-20": 100 };

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
          if (s.choices) expect(new Set(s.choices).size, `${l.id} ${s.label} choices are distinct`).toBe(s.choices.length);
        }
      }
      expect(slips, "the lesson's slips fire").toBeGreaterThan(SEEDS);
    });
    it("early problems (index < 3) use the friendly numbers", () => {
      const max = EARLY_MAX[l.id] ?? 12;
      for (let s = 0; s < 30; s++) for (let i = 0; i < 3; i++) {
        const p = l.workIt.generate(createRng(s), i);
        const nums = JSON.stringify(p).match(/-?\d+(\.\d+)?/g)?.map(Number) ?? [];
        expect(nums.every(n => Math.abs(n) <= max), `${l.id} early ${JSON.stringify(p)}`).toBe(true);
        // and the answers are whole or short
        for (const st of l.workIt.steps(p)) for (const a of st.answer) expect(Math.abs(a * 100 - Math.round(a * 100)) < 1e-6 || typeof st.form === "number" || st.form === "fraction", `${l.id} early answer ${a}`).toBe(true);
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
