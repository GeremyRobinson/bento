// The algebra family: balance, pairs and equation chains are computed from each problem's values.
import { lessonById } from "../../curriculum/registry";
import { createRng } from "../../curriculum/generators/rng";
import { toPlainText } from "../../curriculum/schemas/math-text";
import type { AnyLesson } from "../../curriculum/schemas/lesson";
import { checkAnswerStep } from "../../engine/evaluation/steps";
import { buildBalance, packPan, BALANCE, block, xTiles } from "../../explanations/diagrams/algebra/balance";
import { buildPairs, shownTerms } from "../../explanations/diagrams/algebra/pairs";
import type { SceneDiagram, SceneItem } from "../../explanations/diagrams/scene/schema";
import type { ChainDiagram } from "../../explanations/diagrams/chain/schema";
import { legacyRich, squash } from "../parity/legacy-text";

const lesson = (id: string): AnyLesson => {
  const l = lessonById(id);
  if (!l) throw new Error(`no lesson ${id}`);
  return l;
};
const problemsOf = (l: AnyLesson, n = 40) => {
  const rng = createRng(11);
  return [l.reference, ...Array.from({ length: n }, (_, i) => l.generate(rng, i))];
};
const sceneOf = (l: AnyLesson, p: unknown) => {
  const d = l.explain(p, l.answers(p)).diagram;
  if (d?.kind !== "scene") throw new Error("expected a scene");
  return d;
};
const shownAt = (d: SceneDiagram, beat: number) => d.items.filter(i => (i.from ?? 0) <= beat && (i.until == null || beat <= i.until));
const num = (s: string) => Number(s.replace("−", "-"));

const BALANCE_LESSONS = ["g6-onestep", "g7-eq", "g8-both", "g9-multistep"];

describe("balance", () => {
  it("packs a pan into rows no wider than the pan, centred", () => {
    const { placed, rows } = packPan([xTiles(9), [block(120)]]);
    expect(rows).toBeGreaterThan(1);
    for (let r = 0; r < rows; r++) {
      const row = placed.filter(p => p.row === r);
      const left = Math.min(...row.map(p => p.x)), right = Math.max(...row.map(p => p.x + p.width));
      expect(right - left).toBeLessThanOrEqual(BALANCE.panWidth);
      expect(Math.abs(left + right)).toBeLessThan(1e-9);
    }
  });

  it("grows taller when a pan needs more rows", () => {
    const one = buildBalance([{ left: [xTiles(2)], right: [[block(4)]], note: "2x = 4" }], "a");
    const many = buildBalance([{ left: Array.from({ length: 9 }, () => [...xTiles(1), block(9)]), right: [[block(162)]], note: "9(x + 9) = 162" }], "b");
    expect(many.height).toBeGreaterThan(one.height);
  });

  describe.each(BALANCE_LESSONS)("%s", id => {
    const l = lesson(id);
    const problems = problemsOf(l);

    it.each(problems.map((p, i) => [i, p] as const))("problem %i: the pans really balance at every beat, and nothing overlaps or leaves the picture", (_i, p) => {
      const d = sceneOf(l, p);
      const ex = l.explain(p, l.answers(p));
      const x = (p as { x: number }).x;
      for (let beat = 0; beat < ex.timeline.length; beat++) {
        const items = shownAt(d, beat);
        const rects = items.filter((i): i is Extract<SceneItem, { type: "rect" }> => i.type === "rect");
        const texts = items.filter((i): i is Extract<SceneItem, { type: "text" }> => i.type === "text");
        expect(rects.length, `beat ${beat} shows weights`).toBeGreaterThan(0);
        // inside the canvas, below the note
        for (const r of rects) {
          expect(r.x).toBeGreaterThanOrEqual(0);
          expect(r.x + r.w).toBeLessThanOrEqual(d.width);
          expect(r.y).toBeGreaterThanOrEqual(BALANCE.noteY + 12);
          expect(r.y + r.h).toBeLessThanOrEqual(d.height);
        }
        // no two weights overlap
        for (let i = 0; i < rects.length; i++) for (let j = i + 1; j < rects.length; j++) {
          const a = rects[i]!, b = rects[j]!;
          const apart = a.x + a.w <= b.x || b.x + b.w <= a.x || a.y + a.h <= b.y || b.y + b.h <= a.y;
          expect(apart, `beat ${beat}: weights ${i} and ${j} overlap`).toBe(true);
        }
        // every weight's label sits on it, and the two pans hold the same amount
        let left = 0, right = 0;
        for (const r of rects) {
          const t = texts.find(t => t.x === r.x + r.w / 2 && t.y === r.y + r.h / 2);
          expect(t, `beat ${beat}: weight without a label`).toBeDefined();
          const label = t!.text;
          const value = label === "x" ? x : label.startsWith("x ÷ ") ? x / num(label.slice(4)) : num(label);
          expect(Number.isFinite(value), `label ${label}`).toBe(true);
          if (r.x + r.w / 2 < d.width / 2) left += value; else right += value;
        }
        expect(left, `beat ${beat} balances`).toBeCloseTo(right, 6);
        const note = texts.find(t => t.y === BALANCE.noteY);
        expect(note, `beat ${beat} has its note`).toBeDefined();
        expect(note!.text.length * 9.5).toBeLessThan(d.width);
      }
    });
  });

  it("draws the reference equation's own tiles: 3 x tiles and a 5 against 20 for 3x + 5 = 20", () => {
    const l = lesson("g7-eq"), d = sceneOf(l, l.reference);
    const first = shownAt(d, 0).filter(i => i.type === "text").map(i => (i as { text: string }).text);
    expect(first.filter(t => t === "x")).toHaveLength(3);
    expect(first).toEqual(expect.arrayContaining(["5", "20", "3x + 5 = 20"]));
  });
});

describe("pairs", () => {
  it("shows every term when there are few, and the ends with … between when there are many", () => {
    expect(shownTerms(6)).toEqual([0, 1, 2, 3, 4, 5]);
    expect(shownTerms(17)).toEqual([0, 1, 2, null, 14, 15, 16]);
  });

  it("labels the terms, the pair total and the sum from the series", () => {
    const d = buildPairs({ first: 5, step: 8, count: 17, beats: { terms: 0, last: 1, pair: 2, total: 3 } });
    const texts = d.items.filter(i => i.type === "text").map(i => (i as { text: string }).text);
    expect(texts).toEqual(expect.arrayContaining(["5", "13", "21", "…", "117", "125", "133", "term 17", "each pair makes 138", "17 × 138 ÷ 2 = 1,173"]));
    const even = buildPairs({ first: 1, step: 1, count: 100, beats: { terms: 0, last: 1, pair: 2, total: 3 } });
    expect(even.items.some(i => i.type === "text" && i.text === "50 pairs × 101 = 5,050")).toBe(true);
  });

  it.each(problemsOf(lesson("g12-series")).map((p, i) => [i, p] as const))("g12-series problem %i fits its canvas", (_i, p) => {
    const d = sceneOf(lesson("g12-series"), p);
    for (const t of d.items) {
      if (t.type !== "text") continue;
      const half = (t.text.length * 9.5) / 2;
      expect(t.x - half).toBeGreaterThanOrEqual(-4);
      expect(t.x + half).toBeLessThanOrEqual(d.width + 4);
      expect(t.y).toBeLessThan(d.height);
    }
  });
});

const CHAIN_LESSONS = ["g8-exp", "g9-elim", "g9-negexp", "g9-radical", "g9-polyadd", "g11-expeq", "g11-ratexp", "g11-evalpoly", "g11-synth", "g11-compose", "g11-radical", "g12-power", "g12-polyd", "g12-chain", "g12-anti"];

describe.each(CHAIN_LESSONS)("%s equation chain", id => {
  const l = lesson(id);
  it.each(problemsOf(l, 12).map((p, i) => [i, p] as const))("problem %i: lines appear in order and the beats arrive at the answer model's values", (_i, p) => {
    const model = l.answers(p), ex = l.explain(p, model);
    const d = ex.diagram as ChainDiagram;
    expect(d.kind).toBe("chain");
    expect(d.lines.length).toBeGreaterThan(1);
    d.lines.forEach((line, i) => { if (i) expect(line.from).toBeGreaterThanOrEqual(d.lines[i - 1]!.from); });
    // every answer step is reached by some beat, with its own value
    for (const s of model.steps) {
      const beat = ex.steps.find(b => b.answerStep === s.id);
      expect(beat, `a beat explains ${s.id}`).toBeDefined();
      expect(s.slots.map(x => x.expected)).toContain(beat!.result);
      expect(toPlainText(beat!.math)).not.toBe("");
    }
  });
});

// The two lessons with recorded deviations still judge every other try exactly as the current app did.
interface Check { v: Record<string, number | null>; ok: boolean; soft: boolean; kind: string | null; msg: string | null; generic: boolean }
interface Fixture { cases: { p: unknown; steps: { label: string; checks: Check[] }[] }[] }
const fixtures = import.meta.glob<Fixture>("../fixtures/legacy/{g8-exp,g11-ratexp}.json", { eager: true, import: "default" });
const fixture = (id: string) => Object.entries(fixtures).find(([k]) => k.endsWith(`/${id}.json`))![1];

describe.each([
  ["g8-exp", (p: { t: number; a: number; b: number }, k: number, c: Check) =>
    // the −1 stand-in: only where (a + b) ÷ b isn't whole; it now gets the ordinary hint
    k === 0 && p.t === 1 && !Number.isInteger((p.a + p.b) / p.b) && c.v.x === -1
      ? { ...c, kind: "New exponent", msg: "Not quite. Dividing powers: subtract the exponents.", generic: true } : c],
  ["g11-ratexp", (p: { n: number; r: number; m: number }, k: number, c: Check) => {
    if (c.kind === "Divided by the bottom") return { ...c, msg: `A power of 1/${p.n} is a root, not dividing by ${p.n}.` };
    // fixes-02 (2026-10-06): the hints say why, so "Not quite. <hint>" quotes the new hint, and r × top is a named slip
    if (c.ok || c.soft || !c.generic) return c;
    if (k === 1 && c.v.x === p.r * p.m) return { ...c, kind: "Multiplied by the top", msg: `The top is a power: ${p.r} times itself, not ${p.r} × ${p.m}.`, generic: false };
    return { ...c, msg: `Not quite. ${k === 0 ? `The bottom of the fraction picks the root: here it is the ${p.n === 2 ? "square" : "cube"} root.` : "The top of the fraction is the power: multiply the root by itself that many times."}` };
  }],
] as const)("%s deviation is only what it says", (id, expected) => {
  it("judges every other recorded try the same way", () => {
    const l = lesson(id);
    let changed = 0;
    for (const c of fixture(id).cases) {
      const p = l.restore(c.p), model = l.answers(p);
      model.steps.forEach((s, k) => {
        for (const t of c.steps[k]!.checks) {
          const want = (expected as (p: unknown, k: number, c: Check) => Check)(c.p, k, t);
          if (want !== t) changed++;
          const r = checkAnswerStep(s, t.v);
          const got = { ok: r.ok, soft: !r.ok && !!r.soft, kind: !r.ok && !r.soft ? r.kind : null, msg: r.ok ? null : squash(legacyRich(r.message)), generic: !r.ok && !r.soft ? r.generic : false };
          expect(got, `${id} step ${k + 1} typed ${JSON.stringify(t.v)}`).toEqual({ ok: want.ok, soft: want.soft, kind: want.soft ? null : want.kind, msg: want.msg == null ? null : squash(want.msg), generic: want.generic });
        }
      });
    }
    expect(changed).toBeGreaterThan(0);
  });
});
