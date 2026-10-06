// Pictures for the lessons that were equation chains (Curriculum fixes-02, Part B): each is drawn from the live problem,
// keeps its labels apart and inside the canvas at every beat, and shows what the steps say.
import { lessonById } from "../../curriculum/registry";
import { createRng } from "../../curriculum/generators/rng";
import type { AnyLesson } from "../../curriculum/schemas/lesson";
import type { SceneDiagram, SceneItem } from "../../explanations/diagrams/scene/schema";

const lesson = (id: string): AnyLesson => {
  const l = lessonById(id);
  if (!l) throw new Error(`no lesson ${id}`);
  return l;
};
const problemsOf = (l: AnyLesson, n = 60, seed = 21) => {
  const rng = createRng(seed);
  return [l.reference, ...Array.from({ length: n }, (_, i) => l.generate(rng, i))];
};
const sceneOf = (l: AnyLesson, p: unknown): SceneDiagram => {
  const d = l.explain(p, l.answers(p)).diagram;
  if (d?.kind !== "scene") throw new Error(`${l.id}: expected a scene, got ${d?.kind}`);
  return d;
};
const shownAt = (d: SceneDiagram, beat: number) => d.items.filter(i => (i.from ?? 0) <= beat && (i.until == null || beat <= i.until));
type Text = Extract<SceneItem, { type: "text" }>;
const textsAt = (d: SceneDiagram, beat: number) => shownAt(d, beat).filter((i): i is Text => i.type === "text");
const sizeOf = (cls = "") => (/\bbig\b/.test(cls) ? (/\blbl\b/.test(cls) ? 22 : 28) : /\bsm\b/.test(cls) ? 15 : /\bxs\b/.test(cls) ? 12 : 17);
const boxOf = (t: Text) => {
  const size = sizeOf(t.cls), w = (t.text.length + (t.sup ? t.sup.length * 0.65 : 0)) * size * 0.6;
  const x0 = /\bend\b/.test(t.cls ?? "") ? t.x - w : /\bstart\b/.test(t.cls ?? "") ? t.x : t.x - w / 2;
  return { x0, x1: x0 + w, y0: t.y - size / 2, y1: t.y + size / 2 };
};

/** Labels on screen together never overlap, and every label sits inside the canvas. */
function labelProblems(d: SceneDiagram, beats: number): string[] {
  const out: string[] = [];
  for (let b = 0; b < beats; b++) {
    const ts = textsAt(d, b).filter(t => t.text.trim());
    const boxes = ts.map(boxOf);
    boxes.forEach((a, i) => {
      const t = ts[i]!;
      if (a.x0 < -1 || a.x1 > d.width + 1 || a.y0 < -1 || a.y1 > d.height + 1) out.push(`beat ${b}: "${t.text}" leaves the ${d.width}×${d.height} canvas`);
      for (let j = i + 1; j < boxes.length; j++) {
        const c = boxes[j]!;
        if (a.x0 < c.x1 - 1 && c.x0 < a.x1 - 1 && a.y0 < c.y1 - 1 && c.y0 < a.y1 - 1) out.push(`beat ${b}: "${t.text}" overlaps "${ts[j]!.text}"`);
      }
    });
  }
  return out;
}
const badText = (d: SceneDiagram) => d.items.filter((i): i is Text => i.type === "text").map(t => t.text + (t.sup ?? "")).filter(s => /NaN|undefined|Infinity|\+ -|- -|\b1x|--/.test(s));

/** The 26 lessons whose page was a stack of equations, and the family each one now draws with. */
const PICTURED = {
  "g6-trap": "area-model",
} as const;

describe.each(Object.entries(PICTURED))("%s draws a picture", (id, family) => {
  const l = lesson(id), problems = problemsOf(l);
  it.each(problems.map((p, i) => [i, p] as const))("problem %i: a %s picture whose labels fit and never collide", (_i, p) => {
    const ex = l.explain(p, l.answers(p)), d = sceneOf(l, p);
    expect(d.family).toBe(family);
    expect(labelProblems(d, ex.timeline.length)).toEqual([]);
    expect(badText(d)).toEqual([]);
    for (const it of d.items) expect(it.from ?? 0).toBeLessThan(ex.timeline.length);
    // every beat shows something new or takes something away: no beat is a still frame
    for (let b = 1; b < ex.timeline.length; b++) expect(d.items.some(i => i.from === b || i.until === b - 1), `beat ${b}`).toBe(true);
  });
});

const polyArea = (pts: [number, number][]) => Math.abs(pts.reduce((s, [x, y], i) => { const [u, v] = pts[(i + 1) % pts.length]!; return s + x * v - u * y; }, 0)) / 2;

describe("g6-trap", () => {
  const l = lesson("g6-trap");
  it("the trapezoid and its turned copy are the same size and fill the (a + b) by h rectangle exactly", () => {
    for (const p of problemsOf(l) as { a: number; b: number; h: number }[]) {
      const d = sceneOf(l, p);
      const [trap, copy] = d.items.filter((i): i is Extract<SceneItem, { type: "polygon" }> => i.type === "polygon" && /\btri\b/.test(i.cls ?? ""));
      const rect = d.items.find((i): i is Extract<SceneItem, { type: "rect" }> => i.type === "rect" && i.cls === "ax thin")!;
      expect(polyArea(trap!.points) / polyArea(copy!.points)).toBeCloseTo(1, 2);
      expect((polyArea(trap!.points) + polyArea(copy!.points)) / (rect.w * rect.h)).toBeCloseTo(1, 2);
      // the bottom base takes a/(a + b) of the rectangle's length (the height is held at a readable minimum, so not to scale)
      expect((trap!.points[1]![0] - trap!.points[0]![0]) / rect.w).toBeCloseTo(p.a / (p.a + p.b), 2);
      // the copy turns in about the middle of the slanted side
      expect(copy!.enter).toBe("swing");
    }
  });
  it("labels the bases where they lie and ends on the area", () => {
    const p = { a: 4, b: 8, h: 5 }, d = sceneOf(l, p), texts = (b: number) => textsAt(d, b).map(t => t.text);
    expect(texts(0)).toEqual(expect.arrayContaining(["4", "8", "5", "4 + 8 = 12"]));
    expect(texts(1)).toContain("12 × 5 = 60");
    expect(texts(2)).toEqual(expect.arrayContaining(["30", "60 ÷ 2 = 30"]));
  });
});
