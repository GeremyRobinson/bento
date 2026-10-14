// The tape family: bar lengths, shading and labels follow the problem's values, and every picture any problem
// can produce fits its canvas.
import { buildTape, layoutTape, textWidth } from "../../explanations/diagrams/tape/build";
import type { SceneDiagram, SceneItem } from "../../explanations/diagrams/scene/schema";
import { lessonById } from "../../curriculum/registry";
import { createRng } from "../../curriculum/generators/rng";
import { equivPicture, createEquiv, cutChain } from "../../curriculum/lessons/grade4/g4-equiv";
import { likeFractionsPicture, createLikeFractions } from "../../curriculum/lessons/grade4/g4-likefrac";
import { percentWholePicture, createPercentWhole } from "../../curriculum/lessons/grade6/g6-pctwhole";
import { unlikePicture, createUnlikeFractions } from "../../curriculum/lessons/_tape-family/unlike";
import { ratioPicture, createRatio } from "../../curriculum/lessons/grade6/g6-ratio";

type Rect = Extract<SceneItem, { type: "rect" }>;

describe("g5-unitdiv counts one whole at a time (Review g5 #6)", () => {
  it("each running count lands after the one before it, the first three on beats of their own, the answer step last", () => {
    const l = lessonById("g5-unitdiv")!;
    for (const [W, d] of [[2, 3], [3, 4], [5, 2], [10, 8]] as const) {
      const p = { W, d }, ex = l.explain(p, l.answers(p)), sc = ex.diagram as SceneDiagram, last = ex.timeline.length - 1;
      const counts = Array.from({ length: W }, (_, j) => sc.items.find(i => i.type === "text" && i.text === String((j + 1) * d) && (i.from ?? 0) > 0)!);
      // when each count lands: its beat, then its delay inside the beat
      const when = counts.map(c => (c.from ?? 0) * 100 + (c.delay ?? 0));
      for (let j = 1; j < W; j++) expect(when[j]!).toBeGreaterThan(when[j - 1]!);
      expect(new Set(counts.slice(0, 3).map(c => c.from)).size).toBe(Math.min(W, 3));
      expect(ex.steps.at(-1)!.state).toBe(last);
      expect(counts.at(-1)!.from).toBe(last);
    }
  });
});
const shownAt = (d: SceneDiagram, at: number) => d.items.filter(i => (i.from ?? 0) <= at && (i.until == null || at <= i.until));
const rects = (d: SceneDiagram, at: number, cls: string) => shownAt(d, at).filter((i): i is Rect => i.type === "rect" && i.cls === cls);
const rowOf = (y: number) => (r: Rect) => r.y === y;
const span = (rs: Rect[]) => Math.max(...rs.map(r => r.x + r.w)) - Math.min(...rs.map(r => r.x));
const texts = (d: SceneDiagram, at: number) => shownAt(d, at).flatMap(i => (i.type === "text" ? [i.text] : []));

describe("buildTape", () => {
  it("uses one scale for every row, so lengths are in proportion", () => {
    const d = buildTape({ rows: [{ length: 1, parts: 4 }, { length: 0.25, parts: 1 }, { length: 2, parts: 8, wholes: true }], alt: "t" });
    const L = layoutTape({ rows: [{ length: 1, parts: 4 }, { length: 0.25, parts: 1 }, { length: 2, parts: 8, wholes: true }], alt: "t" });
    const segs = rects(d, 0, "seg");
    const [a, b, c] = L.rowTops.map(y => segs.filter(rowOf(y)));
    expect(a).toHaveLength(4);
    expect(b).toHaveLength(1);
    expect(c).toHaveLength(8);
    expect(span(b!) / span(a!)).toBeCloseTo(0.25, 1);
    expect(span(c!) / span(a!)).toBeCloseTo(2, 1);
    expect(L.x0 + 2 * L.unit).toBeLessThanOrEqual(L.width);
  });

  it("shades exactly the stretch it is given, cut at the parts", () => {
    const spec = { rows: [{ length: 1, parts: 8, fills: [{ a: 0, b: 3 / 8, tone: "on" as const }] }], alt: "t" };
    const d = buildTape(spec), L = layoutTape(spec);
    const on = rects(d, 0, "seg on");
    expect(on).toHaveLength(3);
    expect(span(on) / L.unit).toBeCloseTo(3 / 8, 1);
  });

  it("re-cuts a bar at a later beat and keeps the shading in step with the new parts", () => {
    const d = buildTape({ rows: [{ length: 1, parts: [{ count: 1, from: 0 }, { count: 5, from: 1 }], fills: [{ a: 0, b: 1, tone: "on" }] }], alt: "t" });
    expect(rects(d, 0, "seg")).toHaveLength(1);
    expect(rects(d, 1, "seg")).toHaveLength(5);
    expect(rects(d, 0, "seg on")).toHaveLength(1);
    expect(rects(d, 1, "seg on")).toHaveLength(5);
  });

  it("drops part labels that would not fit, and keeps the ones that do", () => {
    const narrow = buildTape({ rows: [{ length: 1, parts: 40, each: [{ text: () => "$100" }] }], alt: "t" });
    expect(texts(narrow, 0)).not.toContain("$100");
    const wide = buildTape({ rows: [{ length: 1, parts: 4, each: [{ text: i => `${i + 1}` }] }], alt: "t" });
    expect(texts(wide, 0)).toEqual(["1", "2", "3", "4"]);
  });

  it("shows a label only for its beats", () => {
    const d = buildTape({ rows: [{ length: 1, parts: 2, label: [{ text: "?", until: 0 }, { text: "done", from: 1 }] }], alt: "t" });
    expect(texts(d, 0)).toEqual(["?"]);
    expect(texts(d, 1)).toEqual(["done"]);
  });
});

describe("pictures follow the problem", () => {
  it("equivalent fractions: every bar shades a/b of its length, cut into b·m pieces", () => {
    for (const [a, b, k] of [[1, 2, 4], [3, 4, 2], [5, 6, 5], [2, 5, 3]] as const) {
      const p = createEquiv(a, b, k), d = equivPicture(p);
      const tops = [...new Set(rects(d, 2, "seg").map(r => r.y))];
      expect(tops).toHaveLength(1 + cutChain(k).length);
      const first = rects(d, 2, "seg").filter(r => r.y === tops[0]), last = rects(d, 2, "seg").filter(r => r.y === tops.at(-1));
      expect(first).toHaveLength(b);
      expect(last).toHaveLength(b * k);
      const shaded = shownAt(d, 2).filter((i): i is Rect => i.type === "rect" && i.cls === "seg on");
      expect(shaded.filter(r => r.y === tops.at(-1))).toHaveLength(a * k);
      expect(span(shaded.filter(r => r.y === tops.at(-1))) / span(last)).toBeCloseTo(a / b, 1);
      // labels read on one line now (picture system): the count is the top of "4/8"
      expect(texts(d, 2).some(t => t === String(a * k) || t.startsWith(`${a * k}/`))).toBe(true);
      expect(texts(d, 1).some(t => t === "?" || t.startsWith("?/"))).toBe(true);
    }
    expect(cutChain(4)).toEqual([2, 2]);
    expect(cutChain(5)).toEqual([5]);
  });

  it("like fractions: the sum bar holds a + c pieces, over two bars past one whole", () => {
    const d = likeFractionsPicture(createLikeFractions(5, 6, 8));
    const shaded = shownAt(d, 1).filter((i): i is Rect => i.type === "rect" && (i.cls ?? "").startsWith("seg on"));
    expect(shaded).toHaveLength(5 + 6 + 11);
    expect(texts(d, 2)).toContain("11 eighths");
  });

  it("find the whole: 100/p blocks of the part make the whole", () => {
    const d = percentWholePicture(createPercentWhole(20, 7));
    expect(rects(d, 2, "seg").length).toBe(1 + 5);
    expect(texts(d, 2)).toContain("35");
  });

  it("unlike fractions: both bars are re-cut into the LCD, and subtraction strikes C pieces", () => {
    const p = createUnlikeFractions(3, 4, 1, 6, "−"), d = unlikePicture(p);
    expect(p).toMatchObject({ L: 12, A: 9, C: 2, S: 7 });
    expect(rects(d, 0, "seg")).toHaveLength(4 + 6);
    expect(rects(d, 5, "seg")).toHaveLength(12 * 3);
    expect(rects(d, 5, "seg on cut")).toHaveLength(2);
  });

  it("unlike fractions: the LCD step cuts the third into sixths (knife lines, then the pieces split), not a swap", () => {
    const d = unlikePicture(createUnlikeFractions(2, 3, 1, 6, "+"));
    const knives = d.items.filter(i => i.type === "line" && i.cls === "ln2" && i.from === 1);
    expect(knives).toHaveLength(3); // through the middle of each third
    const split = d.items.filter(i => i.type === "rect" && i.from === 1 && i.enter === "slide");
    expect(split.length).toBeGreaterThanOrEqual(6);
    expect(split.every(i => i.vars?.["--dx"] != null && (i.delay ?? 0) > 0)).toBe(true);
    for (let beat = 1; beat <= 4; beat++) expect(d.items.some(i => i.from === beat), `beat ${beat}`).toBe(true);
  });

  it("mixed numbers: one whole is counted per beat, its pieces numbered, and the fraction lands last", () => {
    const ex = lessonById("g5-improper")!, p = { w: 2, n: 2, d: 3 } as never, e = ex.explain(p, ex.answers(p)), d = e.diagram as SceneDiagram;
    expect(e.timeline).toHaveLength(5);
    expect(texts(d, 1)).toEqual(expect.arrayContaining(["1", "2", "3"]));
    expect(texts(d, 2)).toEqual(expect.arrayContaining(["4", "5", "6"]));
    expect(texts(d, 3)).toEqual(expect.arrayContaining(["7", "8"]));
    expect(texts(d, 4)).toContain("8/3");
    expect(texts(d, 3)).not.toContain("8/3");
  });

  it("text too big for its part never shrinks under 14px: one or two parts lead it outside, more leave it to the bracket", () => {
    const one = buildTape({ rows: [{ length: 1, parts: 12, each: [{ text: () => "1000", only: i => i === 0 }] }], alt: "t" });
    const out = one.items.find(i => i.type === "text" && i.text === "1000");
    expect(out?.cls).toBe("sm res");
    expect(one.items.some(i => i.type === "line" && i.cls === "ax thin")).toBe(true);
    const many = buildTape({ rows: [{ length: 1, parts: 12, each: [{ text: () => "1000" }] }], alt: "t" });
    expect(texts(many, 0)).not.toContain("1000");
  });

  it("ratio tape: a boxes over b boxes of one size", () => {
    const d = ratioPicture(createRatio(2, 7, 3));
    const segs = rects(d, 0, "seg");
    expect(segs).toHaveLength(9);
    expect(new Set(segs.map(r => r.w)).size).toBe(1);
  });
});

// every tape lesson, the reference and many generated problems: every shape and label inside the canvas
const TAPE = ["g4-equiv", "g4-likefrac", "g4-fracwhole", "g4-dec", "add", "sub", "mix", "g5-improper", "g5-fracof", "g5-unitdiv", "g5-units",
  "g6-ratio", "g6-rate", "g6-pctof", "g6-pctwhole", "g7-prop", "g7-scale", "g7-discount", "g7-pctchange"];

function bounds(i: SceneItem): [number, number, number, number] {
  switch (i.type) {
    case "rect": return [i.x, i.y, i.x + i.w, i.y + i.h];
    case "line": return [Math.min(i.x1, i.x2), Math.min(i.y1, i.y2), Math.max(i.x1, i.x2), Math.max(i.y1, i.y2)];
    case "path": { const n = i.d.match(/-?[\d.]+/g)!.map(Number), xs = n.filter((_, k) => k % 2 === 0), ys = n.filter((_, k) => k % 2 === 1);
      return [Math.min(...xs), Math.min(...ys), Math.max(...xs), Math.max(...ys)]; }
    case "text": {
      const c = i.cls ?? "", size = c.includes("xs") ? 12 : c.includes("sm") ? 15 : 17, w = textWidth(i.text, size);
      const x0 = c.includes("start") ? i.x : c.includes("end") ? i.x - w : i.x - w / 2;
      return [x0, i.y - size / 2, x0 + w, i.y + size / 2];
    }
    default: return [0, 0, 0, 0];
  }
}

describe.each(TAPE)("%s pictures fit", id => {
  it("for the reference and 150 generated problems", () => {
    const lesson = lessonById(id)!;
    expect(lesson).toBeDefined();
    const rng = createRng(4242);
    const problems = [lesson.reference, ...Array.from({ length: 150 }, (_, i) => lesson.generate(rng, i % 4))];
    for (const p of problems) {
      const ex = lesson.explain(p, lesson.answers(p)), d = ex.diagram as SceneDiagram;
      expect(d.kind).toBe("scene");
      expect(d.family).toBe("tape");
      expect(d.width).toBeLessThanOrEqual(480);
      expect(d.height).toBeLessThanOrEqual(420);
      for (const it of d.items) {
        const [x0, y0, x1, y1] = bounds(it);
        const where = `${id} ${JSON.stringify(p)} ${it.type} ${it.type === "text" ? it.text : ""}`;
        expect(x0, where).toBeGreaterThanOrEqual(-1);
        expect(y0, where).toBeGreaterThanOrEqual(-1);
        expect(x1, where).toBeLessThanOrEqual(d.width + 1);
        expect(y1, where).toBeLessThanOrEqual(d.height + 1);
        if (it.type === "rect") expect(it.w, where).toBeGreaterThan(0);
        expect(it.from ?? 0).toBeLessThan(ex.timeline.length);
      }
    }
  });
});
