// The area-and-grids family: area grids, place-value blocks, fraction grids and boxes follow the problem's values,
// and every lesson's picture stays on its canvas for any problem the generator makes.
import { createRng } from "../../curriculum/generators/rng";
import { buildSplitAreaDiagram, labelWidth } from "../../explanations/diagrams/area-model/build";
import { createSplitMultiplication } from "../../curriculum/lessons/grade5/g5-mult2/problem";
import { lessonById } from "../../curriculum/registry";
import { buildAreaGrid, fitParts, layoutAreaGrid, lineRows, textWidth } from "../../explanations/diagrams/area-model/grid";
import { buildRegroupBlocks } from "../../explanations/diagrams/area-model/blocks";
import { buildFracGrid } from "../../explanations/diagrams/frac-grid/build";
import { boxUnit, buildBox3d } from "../../explanations/diagrams/box3d/build";
import type { SceneDiagram, SceneItem } from "../../explanations/diagrams/scene/schema";

const AREA_LESSONS = ["g2-regroup", "g3-split", "g4-partial", "g4-area", "g6-gcf", "g6-tri", "g7-distribute", "g8-roots", "g9-factor", "g9-foil", "g9-gcf", "g11-complex", "g5-multfrac", "g5-volume", "g10-surface", "g10-pyramid"];
const scene = (id: string, p: unknown) => { const l = lessonById(id)!; return l.explain(p, l.answers(p)).diagram as SceneDiagram; };
const texts = (d: SceneDiagram) => d.items.filter((i): i is Extract<SceneItem, { type: "text" }> => i.type === "text");
const near = (a: number, b: number, eps = 0.15) => Math.abs(a - b) <= eps;

describe("fitting parts along a side", () => {
  it("keeps proportion when every part has room", () => {
    const { lengths, unit } = fitParts([5, 3], [30, 30], 400, 40);
    expect(lengths).toEqual([200, 120]);
    expect(unit).toBe(40);
  });
  it("holds a tiny part at its minimum and shrinks the rest to fit", () => {
    const { lengths } = fitParts([300, 40, 6], [50, 50, 40], 380, 380 / 346);
    expect(lengths[1]).toBe(50);
    expect(lengths[2]).toBe(40);
    expect(lengths.reduce((a, b) => a + b, 0)).toBeCloseTo(380, 6);
  });
});

describe("area grid", () => {
  const spec = { cols: [{ label: "5", size: 5 }, { label: "3", size: 3 }], rows: [{ label: "7", size: 7 }], cells: [[{ text: "35" }, { text: "21" }]], units: 0, alt: "7 by 8" };
  it("draws to one scale on both axes when it fits", () => {
    const g = layoutAreaGrid(spec);
    expect(g.toScale).toBe(true);
    expect(g.unitX).toBe(g.unitY);
    expect((g.xs[1]! - g.xs[0]!) / (g.xs[2]! - g.xs[1]!)).toBeCloseTo(5 / 3);
    expect(g.height / g.width).toBeCloseTo(7 / 8);
  });
  it("draws one line between each pair of unit squares", () => {
    const d = buildAreaGrid(spec);
    // 7 by 5: 4 + 6 lines; 7 by 3: 2 + 6 lines
    expect(d.items.filter(i => i.cls === "grid")).toHaveLength(18);
  });
  it("skips the unit squares when the picture cannot be to scale", () => {
    const d = buildAreaGrid({ ...spec, cols: [{ label: "300", size: 300 }, { label: "6", size: 6 }], rows: [{ label: "7", size: 7 }], cells: [[{ text: "2100" }, { text: "42" }]] });
    expect(d.items.some(i => i.cls === "grid")).toBe(false);
  });
  it("shares a row between lines that are never shown together", () => {
    expect(lineRows([{ text: "a", from: 1, until: 1 }, { text: "b", from: 2, until: 2 }, { text: "c", from: 3 }])).toEqual({ rowOf: [0, 0, 0], count: 1 });
    expect(lineRows([{ text: "a", from: 1 }, { text: "b", from: 2 }]).count).toBe(2);
  });
});

describe("lesson pictures follow the problem", () => {
  it("g3-split: the two parts are 5 and b − 5 wide, holding a × 5 and a × (b − 5)", () => {
    for (const [a, b] of [[7, 8], [3, 6], [9, 9]] as const) {
      const d = scene("g3-split", { a, b });
      expect(texts(d).map(t => t.text)).toEqual(expect.arrayContaining(["5", String(b - 5), String(a), String(a * 5), String(a * (b - 5)), `${a} × ${b} = ${a * 5} + ${a * (b - 5)} = ${a * b}`]));
      const cells = d.items.filter(i => i.type === "rect" && i.cls?.startsWith("cell")) as Extract<SceneItem, { type: "rect" }>[];
      expect((cells[0]!.w + 4) / (cells[1]!.w + 4)).toBeCloseTo(5 / (b - 5), 1);
    }
  });
  it("g4-area: the perimeter path goes round a rectangle in the ratio length : width", () => {
    const d = scene("g4-area", { l: 12, w: 4 });
    const box = d.items.find(i => i.type === "rect" && i.cls === "ax thin") as Extract<SceneItem, { type: "rect" }>;
    expect(box.w / box.h).toBeCloseTo(3, 1);
    expect(d.items.filter(i => i.cls === "grid")).toHaveLength(11 + 3);
    expect(texts(d).some(t => t.text === "around: 12 + 4 + 12 + 4 = 32 m")).toBe(true);
  });
  it("g6-tri: the triangle is exactly half of its rectangle", () => {
    const d = scene("g6-tri", { b: 10, h: 12 });
    const tri = d.items.find(i => i.type === "polygon" && i.cls === "tri c0") as Extract<SceneItem, { type: "polygon" }>;
    const box = d.items.find(i => i.type === "rect" && i.cls === "ax thin") as Extract<SceneItem, { type: "rect" }>;
    const [[x1, y1], [x2, y2], [x3, y3]] = tri.points as [[number, number], [number, number], [number, number]];
    const area = Math.abs((x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1)) / 2;
    expect(area / (box.w * box.h)).toBeCloseTo(0.5, 2);
    expect(texts(d).filter(t => t.text === "60")).toHaveLength(2);
  });
  it("g9-foil: negative parts are drawn by their size and labelled with their sign", () => {
    const d = scene("g9-foil", { a: -4, b: -2 });
    expect(texts(d).map(t => t.text)).toEqual(expect.arrayContaining(["−4", "−2", "−4x", "−2x", "8", "(−4) × (−2) = 8", "x² − 6x + 8"]));
  });
  it("g11-complex: the i² corner turns into a plain number", () => {
    const d = scene("g11-complex", { a: 2, b: 3, c: 1, d: 4 });
    expect(texts(d).map(t => t.text)).toEqual(expect.arrayContaining(["2", "8i", "3i", "12i² = −12", "real: 2 − 12 = −10", "= −10 + 11i"]));
  });
});

describe("place-value blocks", () => {
  it("one rod per ten, one square per one, and ten ones become the carried rod", () => {
    const d = buildRegroupBlocks({ a: 47, b: 38, beats: { blocks: 0, ones: 1, regroup: 2, tens: 3, total: 4 }, text: { ones: "", regroup: "", tens: "", total: "" }, alt: "" });
    const at = (k: number) => d.items.filter(i => i.type === "rect" && (i.from ?? 0) <= k && (i.until == null || k <= i.until) && i.cls !== "hlline");
    expect(at(0)).toHaveLength((4 + 3) * 10 + 15);
    expect(at(2)).toHaveLength((4 + 3 + 1) * 10 + 5);
  });
  it("needs the ones to make a ten", () => {
    expect(() => buildRegroupBlocks({ a: 41, b: 32, beats: { blocks: 0, ones: 1, regroup: 2, tens: 3, total: 4 }, text: { ones: "", regroup: "", tens: "", total: "" }, alt: "" })).toThrow();
  });
});

describe("fraction grid", () => {
  it("shades r of the rows, c of the columns, and the overlap is r × c squares", () => {
    const d = buildFracGrid({ rows: 3, cols: 4, r: 2, c: 3, beats: { grid: 0, rows: 1, cols: 2, both: 3 }, rowLabel: "2/3", colLabel: "3/4", alt: "" });
    const count = (cls: string) => d.items.filter(i => i.cls === cls).length;
    expect([count("seg"), count("shadeA"), count("shadeA p1"), count("both pq")]).toEqual([12, 8, 9, 6]);
    expect(d.items.filter(i => i.cls === "both pq").every(i => i.from === 3)).toBe(true);
  });
  it("g5-multfrac follows the problem", () => {
    const d = scene("g5-multfrac", { a: 3, b: 4, c: 1, d: 4 });
    expect(d.items.filter(i => i.cls === "both pq")).toHaveLength(3);
    expect(texts(d).map(t => t.text)).toEqual(expect.arrayContaining(["3/4", "1/4", "3 of 16 squares", "3/16 is already simplest"]));
  });
});

describe("boxes", () => {
  it("uses the current app's size rule", () => expect(boxUnit(4, 3, 2)).toBeCloseTo(200 / 7));
  it("builds a layer per unit of height, each a top, a front and a side", () => {
    const d = buildBox3d({ mode: "cubes", l: 4, w: 3, h: 2, layerBeats: [1, 2], alt: "" });
    expect(d.items.filter(i => i.type === "polygon" && i.cls === "cf cube top")).toHaveLength(2);
    expect(d.items.filter(i => i.cls === "edge" && i.from === 2)).toHaveLength(3);
    expect(d.items.filter(i => i.cls === "cf cube" && i.from === 1)).toHaveLength((3 + 2) * 2);
  });
  it("puts each face's area on it", () => {
    const d = scene("g10-surface", { l: 2, w: 3, h: 4 });
    expect(texts(d).map(t => t.text)).toEqual(expect.arrayContaining(["6", "8", "12", "2 × (6 + 8 + 12) = 52"]));
  });
  it("puts the pyramid's top over the middle of its base", () => {
    const d = buildBox3d({ mode: "pyramid", l: 6, w: 6, h: 5, beats: { base: 1, box: 2, pyramid: 3 }, alt: "" });
    const base = d.items.find(i => i.type === "polygon" && i.cls === "cf top") as Extract<SceneItem, { type: "polygon" }>;
    const axis = d.items.find(i => i.type === "line" && i.cls === "ln2 dash") as Extract<SceneItem, { type: "line" }>;
    const cx = base.points.reduce((a, p) => a + p[0], 0) / 4, cy = base.points.reduce((a, p) => a + p[1], 0) / 4;
    expect(near(axis.x2, cx) && near(axis.y2, cy)).toBe(true);
    expect(near(axis.x1, cx)).toBe(true);
  });
});

describe.each(AREA_LESSONS)("%s picture fits its canvas", id => {
  it("for the reference and 150 generated problems", () => {
    const l = lessonById(id)!, rng = createRng(99);
    const problems = [l.reference, ...Array.from({ length: 150 }, (_, i) => l.generate(rng, i))];
    for (const p of problems) {
      const d = scene(id, p), W = d.width + 1, H = d.height + 1;
      const inside = (x: number, y: number) => x >= -1 && x <= W && y >= -1 && y <= H;
      for (const it of d.items) {
        const where = `${JSON.stringify(p)} ${JSON.stringify(it)}`;
        switch (it.type) {
          case "rect": expect(inside(it.x, it.y) && inside(it.x + it.w, it.y + it.h), where).toBe(true); break;
          case "line": expect(inside(it.x1, it.y1) && inside(it.x2, it.y2), where).toBe(true); break;
          case "polygon": expect(it.points.every(([x, y]) => inside(x, y)), where).toBe(true); break;
          case "text": {
            const w = textWidth(it.text + (it.sup ?? "")), c = it.cls ?? "";
            const x0 = c.includes("end") ? it.x - w : c.includes("start") ? it.x : it.x - w / 2;
            expect(inside(x0, it.y - 9) && inside(x0 + w, it.y + 9), where).toBe(true);
            break;
          }
          default: break;
        }
      }
    }
  });
});

describe("split area model labels", () => {
  const boxes = (rows: { x: number; label: string; row: number }[]) => rows.map(r => ({ ...r, w: labelWidth(r.label, 20) }));
  const apart = (ls: ReturnType<typeof boxes>) => ls.every((a, i) => ls.slice(i + 1).every(b => a.row !== b.row || Math.abs(a.x - b.x) >= (a.w + b.w) / 2));
  it("never lets two labels in the same row touch, for any problem", () => {
    for (let a = 12; a <= 98; a += 5) for (let b = 12; b <= 98; b++) {
      if (b % 10 === 0) continue;
      const d = buildSplitAreaDiagram(createSplitMultiplication(a, b));
      expect(apart(boxes(d.regions.map(r => ({ x: r.x + r.width / 2, label: r.partLabel, row: r.partRow }))))).toBe(true);
      expect(apart(boxes(d.regions.filter(r => r.labelPlacement === "below").map(r => ({ x: r.x + r.width / 2, label: r.productLabel, row: r.productRow }))))).toBe(true);
      expect(d.regions.every(r => r.y === d.vertical.start)).toBe(true);
    }
  });
  it("steps the second label of a narrow 77 × 17 down a row", () => {
    const d = buildSplitAreaDiagram(createSplitMultiplication(77, 17));
    expect(d.regions.map(r => r.productRow)).toEqual([0, 1]);
  });
});
