// The math behind AI: the generators, 60 seeds each (every step's answer matches the spec's oracle, the rounded
// answer is accepted, every slip fires with its own message, every word reads right), the spec's worked examples, and
// the track's own maths: the digit reader trains and overfits as the lessons say, the measured numbers the guesses use
// are what the seeded runs give, backprop matches finite differences, and the goal sandbox shows its loophole.
import { describe, expect, it } from "vitest";
import { createRng } from "../../curriculum/generators/rng";
import { aOrAn } from "../../curriculum/text";
import { checkB2Step, formatAnswer, toleranceOf } from "../../bento2/steps";
import { trackByCode } from "../../bento2/registry";
import type { AnyB2Lesson, B2Step } from "../../bento2/model";
import {
  DEFAULT_PLAN, OVERFIT_PLAN, SCALING_ERR, SCALING_SIZES, TEST_N, TOP_BIN, TRAIN_N, digitData, evaluate, forward, newReader, pixelMap, predictions,
  rasterize, readerParams, scalingPlan, trainReader, trainRun,
} from "../../bento2/tracks/ai/digits";
import {
  BIN_REWARD, DEFAULT_REWARD, QUERIES, SENTENCE, WORDS, attentionRow, bestLine, cosine, lineText, mlpForward, mlpStep, newMlp, nearestWord, patternDots, reliability, sweep, wordVec,
} from "../../bento2/tracks/ai/maths";
import { newPatchNet, patchForward, patchGrad, patchParams } from "../../bento2/tracks/ai/patches";
import { CTX, START_TEXT, encode, letterForward, letterGrad, newLetterModel } from "../../bento2/tracks/ai/letters";

const track = trackByCode("ai")!;
const SEEDS = 60;
const problems = (l: AnyB2Lesson) => Array.from({ length: SEEDS }, (_, s) => { const i = s % 8; return { i, p: l.workIt.generate(createRng(1000 + s), i) }; });
const flat = (steps: B2Step[]) => steps.flatMap(s => s.answer);

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
  // the learner is never tested or graded: held-out data is "held-out", never a "test set"
  if (/\btests?\b|\bgrades?\b/i.test(t)) bad.push("test/grade word");
  if (/− −|- −/.test(t)) bad.push("− −");
  if (/undefined|NaN|Infinity|\[object/.test(t)) bad.push("undefined");
  if (/\d\.\d*0000\d|\d\.\d*9999\d/.test(t)) bad.push("float noise");
  if (/\d-\d/.test(t.replace(/b2-\w+-\d+|[a-z]\d+-\w+/g, ""))) bad.push("hyphen as minus");
  for (const m of t.matchAll(/\b(an?) (\d[\d,]*)(?![\d.])/gi)) if (m[1]!.toLowerCase() !== aOrAn(+m[2]!.replace(/,/g, ""))) bad.push(`a/an: ${m[0]}`);
  if (/(?<![\d.,/−-])\b1 (years|seconds|days|bits|blocks|epochs|points|tokens|decades|neurons)\b/.test(t)) bad.push("1 with a plural");
  if (/(^|[^\w.])1(x|w|h|β|γ|c|d|n)\b/.test(t)) bad.push("coefficient of 1");
  return bad.map(b => `${b}: ${t}`);
}

describe("The math behind AI: the track", () => {
  it("has 16 lessons, b2-ai-01 to b2-ai-16, in five units", () => {
    expect(track.lessons.map(l => l.id)).toEqual(Array.from({ length: 16 }, (_, i) => `b2-ai-${String(i + 1).padStart(2, "0")}`));
    expect(track.units.map(u => track.lessons.filter(l => l.unit === u.n).length)).toEqual([3, 4, 2, 3, 4]);
    expect(track.projects.map(p => p.after)).toEqual(["b2-ai-03", "b2-ai-07", "b2-ai-09", "b2-ai-12", "b2-ai-16"]);
    expect(track.projects.filter(p => p.build).map(p => p.id)).toEqual(["ai-notes"]);
  });
  it("every lesson has every part of the spec block, and its tool chips are real tools", () => {
    const toolIds = new Set([...track.tools.map(t => t.id), "calc", "graph2d", "graph3d", "matrix", "shelf", "units", "scratch", "notebook"]);
    for (const l of track.lessons) {
      expect(l.youCan, l.id).toMatch(/^[a-z]/);
      expect(l.nameIt.say.length, l.id).toBeGreaterThanOrEqual(1);
      expect(l.nameIt.say.length, l.id).toBeLessThanOrEqual(3);
      expect(l.nameIt.formula.length, l.id).toBeGreaterThan(0);
      expect(l.deeper.length, l.id).toBeGreaterThanOrEqual(2);
      expect(l.useIt.say.length, l.id).toBeGreaterThan(0);
      for (const t of l.tools) expect(toolIds.has(t), `${l.id} ${t}`).toBe(true);
      if (l.guess.kind === "choice") expect(l.guess.options[l.guess.answer], l.id).toBeDefined();
      if (l.useIt.project) expect(track.projects.some(p => p.id === l.useIt.project), l.id).toBe(true);
    }
  });
  it("the reference problems give the spec's worked examples", () => {
    const answers = (id: string) => { const l = track.lessons.find(x => x.id === id)!; return l.workIt.steps(l.workIt.reference).map(s => s.answer.map(a => formatAnswer(a, s.choices ? "whole" : s.form)).join(", ")); };
    const tapped = (id: string, k: number) => { const l = track.lessons.find(x => x.id === id)!; const s = l.workIt.steps(l.workIt.reference)[k]!; return s.choices![s.answer[0]!]; };
    expect(answers("b2-ai-01")).toEqual(["1, 2, 3", "−1, 1, 0", "2", "2/3"]);
    expect(answers("b2-ai-02")).toEqual(["−10", "1.00", "−5.00", "1.50"]);
    expect(answers("b2-ai-03").filter((_, k) => k !== 1)).toEqual(["0.60", "5.16", "1/2"]);
    expect(tapped("b2-ai-03", 1)).toBe("Creeps in from one side");
    expect(answers("b2-ai-04").filter((_, k) => k !== 1)).toEqual(["1", "0.73", "1"]);
    expect(tapped("b2-ai-04", 1)).toMatch(/^Orange/);
    expect(answers("b2-ai-05")).toEqual(["4, −2", "4, 0", "3"]);
    expect(answers("b2-ai-06")).toEqual(["6", "2.0", "2", "4", "12"]);
    expect(answers("b2-ai-07")).toEqual(["0, −2, −2", "0.79", "0.35", "−0.21"]);
    expect(answers("b2-ai-08")).toEqual(["64", "1,024", "16", "170", "1,210"]);
    expect(answers("b2-ai-08")).toHaveLength(5);
    expect(answers("b2-ai-09").slice(0, 3)).toEqual(["30", "300", "90.0"]);
    expect(tapped("b2-ai-09", 3)).toBe("A 7 read as 1");
    expect(answers("b2-ai-10").slice(0, 4)).toEqual(["24", "5, 5", "0.96", "5, 8"]);
    expect(tapped("b2-ai-10", 4)).toBe("queen");
    expect(answers("b2-ai-11")).toEqual(["2, 0, 1", "1.0, 0.0, 0.5", "0.51", "6.3"]);
    expect(answers("b2-ai-12")).toEqual(["16,384", "32,768", "98,304", "104,704", "8"]);
    expect(answers("b2-ai-13")[0]).toBe("−0.15");
    expect(tapped("b2-ai-13", 1)).toBe("No");
    expect(answers("b2-ai-13")[2]).toBe("0.08");
    expect(tapped("b2-ai-13", 3)).toBe("100");
    expect(answers("b2-ai-14")).toEqual(["1.2, 18.0", "1,200", "20", "20"]);
    expect(tapped("b2-ai-15", 0)).toBe("B");
    expect(answers("b2-ai-15").slice(1)).toEqual(["3", "4", "0.80", "8.00"]);
    expect(answers("b2-ai-16").slice(0, 3)).toEqual(["0.60, 0.70, 0.80", "0.00, 0.10, 0.15", "0.095"]);
    expect(tapped("b2-ai-16", 3)).toBe("Overconfident");
    expect(tapped("b2-ai-16", 4)).toBe("Greater than 1");
  });
  it("the worked examples' slips say what the spec says", () => {
    const msg = (id: string, k: number, typed: (string | number)[]) => { const l = track.lessons.find(x => x.id === id)!; const r = checkB2Step(l.workIt.steps(l.workIt.reference)[k]!, typed); return r.ok ? "ok" : r.message; };
    expect(msg("b2-ai-01", 2, ["0"])).toMatch(/cancel/);
    expect(msg("b2-ai-01", 3, ["2"])).toMatch(/That is the total/);
    expect(msg("b2-ai-01", 3, ["1"])).toMatch(/n − 1/);
    expect(msg("b2-ai-02", 1, ["−1"])).toMatch(/uphill/);
    expect(msg("b2-ai-02", 1, ["10"])).toMatch(/learning rate/);
    expect(msg("b2-ai-02", 0, ["−5"])).toMatch(/Keep the 2/);
    expect(msg("b2-ai-03", 0, ["1.4"])).toMatch(/1 − 2ηa/);
    expect(msg("b2-ai-03", 2, ["21"])).toMatch(/r³, not 3r/);
    expect(msg("b2-ai-03", 3, ["1/4"])).toMatch(/twice that/);
    expect(msg("b2-ai-04", 0, ["0"])).toMatch(/bias/);
    expect(msg("b2-ai-04", 2, ["1"])).toMatch(/That is z/);
    expect(msg("b2-ai-04", 3, ["−1"])).toMatch(/−b\/w₂/);
    expect(msg("b2-ai-05", 0, ["1", "4"])).toMatch(/row 1 is \(1, 2\)/);
    expect(msg("b2-ai-05", 2, ["−3"])).toMatch(/ReLU turns the −2 into 0/);
    expect(msg("b2-ai-06", 4, ["6"])).toMatch(/Multiply by x = 2/);
    expect(msg("b2-ai-06", 1, ["4"])).toMatch(/half of 4 is 2/);
    expect(msg("b2-ai-07", 1, ["0.6"])).toMatch(/e to each score/);
    expect(msg("b2-ai-07", 3, ["0.79"])).toMatch(/p − 1/);
    expect(msg("b2-ai-08", 4, ["1184"])).toMatch(/add h \+ 10/);
    expect(msg("b2-ai-08", 4, ["90"])).toMatch(/connections/);
    expect(msg("b2-ai-08", 0, ["8"])).toMatch(/s² = 64/);
    expect(msg("b2-ai-09", 1, ["30"])).toMatch(/one epoch/);
    expect(msg("b2-ai-09", 3, [1])).toMatch(/a 7 read as 1/);
    expect(msg("b2-ai-10", 2, ["24"])).toMatch(/both lengths/);
    expect(msg("b2-ai-10", 3, ["13", "10"])).toMatch(/Subtract man/);
    expect(msg("b2-ai-10", 4, [1])).toMatch(/queen is 1 away, prince is √10 ≈ 3.16/);
    expect(msg("b2-ai-11", 1, ["2", "0", "1"])).toMatch(/√d = 2/);
    expect(msg("b2-ai-11", 3, ["4.7"])).toMatch(/weighted average/);
    expect(msg("b2-ai-11", 2, ["2/3"])).toMatch(/through softmax/);
    expect(msg("b2-ai-12", 0, ["256"])).toMatch(/4d²/);
    expect(msg("b2-ai-12", 2, ["49152"])).toMatch(/L = 2/);
    expect(msg("b2-ai-12", 1, ["16384"])).toMatch(/8d²/);
    expect(msg("b2-ai-13", 0, ["−0.08"])).toMatch(/not E₂ − E₁/);
    expect(msg("b2-ai-13", 0, ["−0.30"])).toMatch(/2 decades/);
    expect(msg("b2-ai-13", 1, [0])).toMatch(/shaded zone/);
    expect(msg("b2-ai-13", 2, ["0"])).toMatch(/never reach 0/);
    expect(msg("b2-ai-14", 0, ["2", "17"])).toMatch(/6 operations/);
    expect(msg("b2-ai-14", 0, ["1.2", "72"])).toMatch(/adds exponents/);
    expect(msg("b2-ai-14", 0, ["4", "17"])).toMatch(/6ND/);
    expect(msg("b2-ai-15", 0, [2])).toMatch(/only sees the proxy/);
    expect(msg("b2-ai-15", 3, ["0.25"])).toMatch(/4\/5/);
    expect(msg("b2-ai-15", 3, ["0.2"])).toMatch(/4\/5/);
    expect(msg("b2-ai-15", 4, ["10"])).toMatch(/partly luck/);
    expect(msg("b2-ai-16", 2, ["0.083"])).toMatch(/Weight each gap/);
    expect(msg("b2-ai-16", 3, [1])).toMatch(/overconfident/);
    expect(msg("b2-ai-16", 4, [1])).toMatch(/T > 1/);
  });
  it("lines are written with no coefficient of 1 and no plus before a minus", () => {
    expect(lineText(1, 1)).toBe("y = x + 1");
    expect(lineText(-1, -2)).toBe("y = −x − 2");
    expect(lineText(2, 0)).toBe("y = 2x");
    expect(lineText(0, -3)).toBe("y = −3");
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
            const tol = toleranceOf(s.form) / 1.0001;
            expect(checkB2Step(s, s.answer.map(a => a + tol * 0.99)).ok).toBe(true);
            expect(checkB2Step(s, s.answer.map(a => a + tol * 2.5)).ok).toBe(false);
          }
          if (s.choices) expect(s.answer[0]!, `${l.id} ${s.label}`).toBeLessThan(s.choices.length);
          for (const sl of s.slips) {
            slips++;
            const r = checkB2Step(s, s.choices ? sl.values : sl.values.map(v => (s.form === "fraction" ? v : Number(v.toFixed(typeof s.form === "number" ? s.form : 6)))));
            expect(r.ok, `${l.id} ${s.label} slip ${sl.kind} for ${JSON.stringify(p)}`).toBe(false);
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
        expect(nums.every(n => Math.abs(n) <= 2000), `${l.id} early ${JSON.stringify(p)}`).toBe(true);
        // every answer of an early problem is short: a whole number or at most 2 places
        for (const st of l.workIt.steps(p)) for (const a of st.answer) expect(Math.abs(a * 100 - Math.round(a * 100)) < 1e-6 || st.form === "fraction" || typeof st.form === "number", `${l.id} ${st.label} ${a}`).toBe(true);
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

describe("the track's own maths", () => {
  it("the attention toy: \"it\" looks most at \"cat\" (11's guess), other words elsewhere, and hiding the future keeps rows summing to 1", () => {
    const tops = QUERIES.map(q => { const w = attentionRow(q); return SENTENCE[w.indexOf(Math.max(...w))]; });
    expect(tops[4]).toBe("cat");
    expect(tops.filter(t => t === "cat").length).toBeLessThanOrEqual(2);
    QUERIES.forEach((q, i) => { const w = attentionRow(q, i + 1); expect(w.reduce((a, b) => a + b, 0)).toBeCloseTo(1, 12); expect(w.slice(i + 1).every(v => v === 0)).toBe(true); });
  });
  it("the line fitter's bottom of the bowl is the least-squares line", () => {
    const [w, b] = bestLine([[0, 1], [1, 3], [2, 5]]);
    expect(w).toBeCloseTo(2, 9); expect(b).toBeCloseTo(1, 9);
  });
  it("the tiny network learns XOR with a hidden layer, and its gradient matches finite differences", () => {
    const dots = patternDots("xor", 3, 40);
    const X = dots.map(d => [d.x, d.y]), Y = dots.map(d => d.c);
    const net = newMlp([2, 4, 2], "relu", 1);
    // finite differences on one weight
    const loss = () => X.reduce((s, x, k) => s - Math.log2(mlpForward(net, x).outs.at(-1)![Y[k]!]!), 0) / X.length;
    const w0 = net.W[0]![3]!, h = 1e-6;
    net.W[0]![3] = w0 + h; const up = loss(); net.W[0]![3] = w0 - h; const dn = loss(); net.W[0]![3] = w0;
    const fd = ((up - dn) / (2 * h)) * Math.LN2;
    const copy = { ...net, W: net.W.map(w => Float64Array.from(w)), b: net.b.map(b => Float64Array.from(b)) };
    mlpStep(copy, X, Y, 1);
    expect((w0 - copy.W[0]![3]!) / 1).toBeCloseTo(fd, 5);
    let last = 0;
    for (let k = 0; k < 1500; k++) last = mlpStep(net, X, Y, 0.5);
    expect(last).toBeLessThan(0.35);
  });
  it("the next-letter model's backprop matches finite differences", () => {
    const m = newLetterModel(START_TEXT);
    const ids = encode(m, "the cat s").slice(0, CTX), tgt = encode(m, "a")[0]!;
    const g = letterGrad(m, ids, tgt);
    const L = () => { const { z } = letterForward(m, ids); const mx = Math.max(...z), e = [...z].map(v => Math.exp(v - mx)); return -Math.log(e[tgt]! / e.reduce((a, b) => a + b, 0)); };
    for (const key of ["E", "P", "Wq", "Wk", "Wv", "Wo", "W1", "W2", "U", "bu"] as const) {
      const W = m[key];
      for (let t = 0; t < 4; t++) {
        const i = (t * 37 + 5) % W.length, o = W[i]!;
        W[i] = o + 1e-5; const a = L(); W[i] = o - 1e-5; const b = L(); W[i] = o;
        expect(g[key][i]!, `${key}[${i}]`).toBeCloseTo((a - b) / 2e-5, 5);
      }
    }
  });
  it("the word map: kitten beats dog by at least 0.1 in cosine to cat, and king − man + woman lands nearest queen", () => {
    const c = wordVec("cat");
    expect(cosine(c, wordVec("kitten")) - cosine(c, wordVec("dog"))).toBeGreaterThan(0.1);
    expect(cosine(c, wordVec("kitten"))).toBeGreaterThan(cosine(c, wordVec("car")));
    const an = (a: string, b: string, d: string) => { const [x, y] = [wordVec(a)[0] - wordVec(b)[0] + wordVec(d)[0], wordVec(a)[1] - wordVec(b)[1] + wordVec(d)[1]]; return nearestWord([x, y], [a, b, d]); };
    expect(an("king", "man", "woman")).toBe("queen");
    expect(an("paris", "france", "italy")).toBe("rome");
    expect(an("tokyo", "japan", "france")).not.toBe("paris");
    expect(new Set(WORDS.map(w => w[0])).size).toBe(WORDS.length);
    expect(WORDS.length).toBeGreaterThanOrEqual(45);
  });
  it("the goal sandbox: with the camera reward, true cleanliness rises then falls; counting the bin, it keeps rising", () => {
    const cam = sweep(DEFAULT_REWARD), bin = sweep(BIN_REWARD);
    const top = Math.max(...cam.map(o => o.clean));
    expect(cam.find(o => o.n === 10)!.clean).toBeLessThan(top);
    expect(cam.at(-1)!.clean).toBeLessThan(top - 0.05);
    expect(cam.at(-1)!.reward).toBeCloseTo(25, 9);
    expect(bin.at(-1)!.clean).toBeGreaterThan(bin.find(o => o.n === 10)!.clean + 0.05);
  });
});

describe("the Digit reader", () => {
  const data = digitData();
  it("has 3,823 training digits and 1,797 held back, every digit in both, 64 counts from 0 to 16 each", () => {
    expect(data.train.y).toHaveLength(TRAIN_N);
    expect(data.test.y).toHaveLength(TEST_N);
    for (let d = 0; d < 10; d++) { expect(data.train.y.filter(y => y === d).length).toBeGreaterThan(300); expect(data.test.y.filter(y => y === d).length).toBeGreaterThan(150); }
    for (const x of data.train.x.slice(0, 50)) { expect(x).toHaveLength(64); expect([...x].every(v => v >= 0 && v <= 1 && Number.isInteger(v * 16))).toBe(true); }
  });
  it("the pad shrinks a stroke the same way: 4 × 4 blocks of a 32 × 32 picture", () => {
    const counts = rasterize([[[0.5, 0.1], [0.5, 0.9]]], 0.1);
    expect(Math.max(...counts)).toBeLessThanOrEqual(16);
    expect(counts.reduce((a, b) => a + b, 0)).toBeGreaterThan(40);
    expect(counts[0]).toBe(0);
  });
  it("a 64 → 16 → 10 reader has 1,210 numbers, and the default run reads most held-out digits", () => {
    expect(readerParams(16)).toBe(1210);
    const net = trainReader(DEFAULT_PLAN);
    const { error } = evaluate(net, data.test);
    expect(error).toBeLessThan(0.1);
    expect(error).toBeCloseTo(SCALING_ERR[3]!, 12);
    const map = pixelMap(net, data.test.x[0]!, data.test.y[0]!);
    expect(map.some(v => v !== 0)).toBe(true);
    const preds = predictions(net, data.test), top = preds.filter(q => q.conf >= 0.9);
    expect([top.length, top.filter(q => q.right).length]).toEqual(TOP_BIN);
    const { bins } = reliability(preds);
    expect(bins.reduce((s, b) => s + b.n, 0)).toBe(TEST_N);
  }, 30000);
  it("the scaling runs give the errors the guess records, falling with more data", () => {
    const errs = SCALING_SIZES.map(n => evaluate(trainReader(scalingPlan(n)), data.test).error);
    errs.forEach((e, k) => expect(e).toBeCloseTo(SCALING_ERR[k]!, 12));
    for (let k = 1; k < errs.length; k++) expect(errs[k]!).toBeLessThan(errs[k - 1]!);
  }, 60000);
  it("the overfitting preset: training error goes to 0 and the test loss turns back up", () => {
    const bits: number[] = [];
    let net = newReader(OVERFIT_PLAN.h, OVERFIT_PLAN.seed);
    for (const s of trainRun(OVERFIT_PLAN)) { net = s.net; if (s.epoch % 5 === 0) bits.push(evaluate(net, data.test, 600).bits); }
    expect(evaluate(net, data.train, OVERFIT_PLAN.n).error).toBe(0);
    const low = Math.min(...bits);
    expect(bits.indexOf(low)).toBeLessThan(bits.length / 3);
    expect(bits.at(-1)!).toBeGreaterThan(low * 1.2);
    expect(forward(net, data.test.x[0]!).p.reduce((a, b) => a + b, 0)).toBeCloseTo(1, 9);
  }, 60000);
  it("the patch reader's backprop matches finite differences, and its sizes add up", () => {
    const n = newPatchNet(3), img = data.train.x[0]!, y = data.train.y[0]!, g = patchGrad(n, img, y);
    const L = () => -Math.log(patchForward(n, img).p[y]!);
    for (const key of ["E", "pos", "Wq", "Wk", "Wv", "Wo", "U", "bu"] as const) {
      const W = n[key];
      for (let t = 0; t < 4; t++) {
        const i = (t * 31 + 3) % W.length, o = W[i]!;
        W[i] = o + 1e-5; const a = L(); W[i] = o - 1e-5; const b = L(); W[i] = o;
        expect(Math.abs((a - b) / 2e-5 - g[key][i]!)).toBeLessThan(1e-6);
      }
    }
    expect(Object.values(n).reduce((s, w) => s + w.length, 0)).toBe(patchParams());
    expect(patchForward(n, img).A.every(row => Math.abs(row.reduce((s, v) => s + v, 0) - 1) < 1e-12)).toBe(true);
  });
});
