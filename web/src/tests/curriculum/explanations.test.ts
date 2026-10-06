// Every rebuilt lesson's lesson page is built from its problem: the beats fit the timeline, the picture's numbers are real,
// beat results agree with the answer model, and a different problem draws a different picture.
import { LESSONS, requireLesson } from "../../curriculum/registry";
import { createRng } from "../../curriculum/generators/rng";
import { toPlainText } from "../../curriculum/schemas/math-text";
import type { DiagramModel } from "../../explanations/schema";

const numbersOf = (d: DiagramModel): number[] =>
  d.kind === "scene" ? d.items.flatMap(i => Object.entries(i).filter(([k, v]) => typeof v === "number" && k !== "from" && k !== "until" && k !== "delay").map(([, v]) => v as number).concat(i.type === "polygon" ? i.points.flat() : []))
    : [];

describe.each(LESSONS.map(l => [l.id, l] as const))("%s lesson page", (_id, lesson) => {
  const rng = createRng(7);
  const problems = [lesson.reference, ...Array.from({ length: 6 }, (_, i) => lesson.generate(rng, i))];

  it.each(problems.map((p, i) => [i, p] as const))("is derived from problem %i", (_i, p) => {
    const model = lesson.answers(p), ex = lesson.explain(p, model);
    expect(ex.timeline.length).toBeGreaterThan(0);
    expect(ex.steps.length).toBeGreaterThan(0);
    for (const s of ex.steps) {
      expect(s.state).toBeGreaterThanOrEqual(0);
      expect(s.state).toBeLessThan(ex.timeline.length);
      if (s.answerStep && s.result != null) {
        const step = model.steps.find(a => a.id === s.answerStep);
        expect(step, `beat ${s.id} names answer step ${s.answerStep}`).toBeDefined();
        expect(step!.slots.map(x => x.expected)).toContain(s.result);
      }
    }
    if (ex.diagram) {
      if (ex.diagram.kind !== "areaModel") expect(ex.diagram.alt.length).toBeGreaterThan(0);
      for (const n of numbersOf(ex.diagram)) expect(Number.isFinite(n)).toBe(true);
      if (ex.diagram.kind === "scene") for (const i of ex.diagram.items) expect(i.from ?? 0).toBeLessThan(ex.timeline.length);
      if (ex.diagram.kind === "chain") for (const l of ex.diagram.lines) expect(l.from).toBeLessThan(ex.timeline.length);
    }
  });

  it("draws a different picture for a different problem", () => {
    const shown = new Set(problems.map(p => toPlainText(lesson.display(p))));
    if (shown.size < 2) return; // a lesson whose problems all look alike
    const pics = new Set(problems.map(p => JSON.stringify(lesson.explain(p, lesson.answers(p)).diagram ?? null)));
    if (pics.has("null") && pics.size === 1) return; // no picture at all
    expect(pics.size).toBeGreaterThan(1);
  });
});

describe("the landing page's pictures", () => {
  it("every hero pool lesson exists and draws a picture that fits a tile, never an equation ladder", async () => {
    const { HERO_POOLS, showcasePicture } = await import("../../screens/Welcome");
    for (const id of HERO_POOLS.flat()) for (let s = 1; s <= 20; s++) {
      const ex = showcasePicture(id, createRng(s));
      expect(ex, id).not.toBeNull();
      expect(ex!.diagram.kind, id).not.toBe("chain");
    }
  });
});

describe("pictures and words agree (review v39)", () => {
  const explain = (id: string, p: unknown) => { const l = requireLesson(id); return l.explain(p as never, l.answers(p as never)); };
  const texts = (id: string, p: unknown) => { const d = explain(id, p).diagram; return d?.kind === "scene" ? d.items.flatMap(i => (i.type === "text" ? [i.text] : [])) : []; };

  it("a solid rolls or slides in the picture as its own words say: a cube slides, a sphere rolls", () => {
    const l = requireLesson("k-solids"), rng = createRng(3);
    for (let i = 0; i < 60; i++) {
      const p = l.generate(rng, i) as { shape: number }, ex = explain("k-solids", p), said = ex.steps.find(s => s.id === "roll")!.narration;
      const drawn = texts("k-solids", p).find(t => t === "it rolls" || t === "it slides")!;
      expect(said.includes("**rolls**")).toBe(drawn === "it rolls");
      if (toPlainText(ex.steps.at(-1)!.math).includes("cube")) expect(drawn).toBe("it slides");
      if (toPlainText(ex.steps.at(-1)!.math).includes("sphere")) expect(drawn).toBe("it rolls");
    }
  });

  it("never states the answer before it is worked", () => {
    for (const id of ["g5-round", "g5-pow10", "g10-exterior"]) {
      const l = requireLesson(id), rng = createRng(5);
      for (let i = 0; i < 20; i++) expect(toPlainText(explain(id, l.generate(rng, i)).statement), id).toContain("?");
    }
    expect(toPlainText(explain("g4-partial", { n: 600, m: 4 }).statement)).toBe("600 × 4");
  });

  it("g5-round never asks to round a number that is already rounded", () => {
    const l = requireLesson("g5-round"), rng = createRng(11);
    for (let i = 0; i < 300; i++) { const p = l.generate(rng, i) as { N: number; p: number }; expect(p.N % 10 ** (3 - p.p)).not.toBe(0); }
  });
});
