// The three picture kinds added for the equation-only lessons (Curriculum fixes-02, Part B): expression boxes,
// factor chips and the term table. Each is laid out from what it is given, times its stages within a beat, and
// keeps every shape inside its canvas.
import { buildExprBoxes, type XNode } from "../../explanations/diagrams/algebra/boxes";
import { buildFactorChips, CHIPS } from "../../explanations/diagrams/algebra/chips";
import { buildTermTable, TERMS } from "../../explanations/diagrams/algebra/terms";
import type { SceneDiagram, SceneItem } from "../../explanations/diagrams/scene/schema";

type Rect = Extract<SceneItem, { type: "rect" }>;
type Text = Extract<SceneItem, { type: "text" }>;
const rects = (d: SceneDiagram, cls: RegExp) => d.items.filter((i): i is Rect => i.type === "rect" && cls.test(i.cls ?? ""));
const texts = (d: SceneDiagram) => d.items.filter((i): i is Text => i.type === "text");
const shownAt = (d: SceneDiagram, beat: number) => d.items.filter(i => (i.from ?? 0) <= beat && (i.until == null || beat <= i.until));
const inside = (d: SceneDiagram) => d.items.every(i => i.type !== "rect" || (i.x >= -0.5 && i.y >= -0.5 && i.x + i.w <= d.width + 0.5 && i.y + i.h <= d.height + 0.5));
const px = (v: unknown) => parseFloat(String(v));

describe("expression boxes", () => {
  const T = (text: string): XNode => ({ t: "text", text });
  const tree = (lit = false): XNode[] => [{ t: "box", id: "outer", part: "p1", kids: [T("2"), T("×"), { t: "box", id: "inner", part: "p0", kids: [T("(5 − 1)")], lit }] }];
  const d = buildExprBoxes({
    header: "2 × (5 − 1)",
    stages: [
      { beat: 0, at: 0, tree: tree() },
      { beat: 0, at: 1.2, tree: tree(true) },
      { beat: 0, at: 2.4, tree: [{ t: "box", id: "outer", part: "p1", kids: [T("2"), T("×"), { t: "chip", id: "four", text: "4", part: "p0", from: "inner" }] }] },
      { beat: 1, at: 0, tree: [{ t: "chip", text: "8", part: "pq", pop: true }] },
    ],
    alt: "a",
  });

  it("draws a box round everything it holds", () => {
    const boxes = rects(d, /\bxbox\b/).filter(r => r.from === 0 && r.until === 0 && !/outsoon/.test(r.cls ?? ""));
    const [outer, inner] = boxes;
    expect(inner!.x).toBeGreaterThan(outer!.x);
    expect(inner!.x + inner!.w).toBeLessThan(outer!.x + outer!.w);
    expect(inner!.y).toBeGreaterThan(outer!.y);
    expect(inner!.y + inner!.h).toBeLessThan(outer!.y + outer!.h);
  });

  it("plays a beat's stages in turn: each gives way when the next comes in, and the beat's last stays", () => {
    // the picture opens by fading in its first stage, which gives way at 1.2 s; the lit stage comes in then and goes at 2.4 s
    const flashes = d.items.filter(i => i.enter === "flash");
    expect(flashes.filter(i => i.delay === 0).every(i => i.vars?.["--d2"] === "1.20s")).toBe(true);
    expect(flashes.filter(i => i.delay === 1.2).every(i => i.vars?.["--d2"] === "2.40s")).toBe(true);
    expect(flashes.filter(i => i.delay === 0).length).toBeGreaterThan(0);
    expect(flashes.filter(i => i.delay === 1.2).length).toBeGreaterThan(0);
    // the beat's last stage stays to the end of the beat
    expect(d.items.filter(i => i.from === 0 && i.enter !== "flash" && i.until === 0).length).toBeGreaterThan(0);
    // the lit stage outlines the box it is about
    expect(d.items.some(i => i.cls?.includes("hlline") && i.enter === "flash")).toBe(true);
    // the last stage of all has no last beat
    expect(d.items.filter(i => i.from === 1).every(i => i.until == null)).toBe(true);
  });

  it("slides a chip from where its box was, and pops a result", () => {
    const chip = rects(d, /\bxchip p0\b/).find(r => r.enter === "slide")!;
    const before = rects(d, /\bxbox p0\b/).find(r => r.enter === "flash" && r.delay === 1.2)!;
    expect(chip.x + chip.w / 2 + px(chip.vars!["--dx"])).toBeCloseTo(before.x + before.w / 2, 0);
    expect(rects(d, /\bxchip pq\b/)[0]!.enter).toBe("pop");
  });

  it("shows the expression as written above it the whole time, and fits its canvas", () => {
    expect(texts(d).find(t => t.text === "2 × (5 − 1)")!.from ?? 0).toBe(0);
    expect(inside(d)).toBe(true);
  });
});

describe("factor chips", () => {
  const d = buildFactorChips([
    { chips: [0, 1, 2].map(col => ({ row: 0, col, text: "x", at: 0.2 * col })), labels: [{ row: -0.6, col: 1, text: "x³ ÷ x" }] },
    { chips: [...[0, 1, 2].map(col => ({ row: 0, col, text: "x", ...(col === 2 ? { strike: 0.4 } : {}) })), { row: 1, col: 2, text: "x", part: "p1", strike: 0.4 }],
      bars: [{ row: 0, from: 0, to: 2 }], brackets: [{ row: 1, from: 0, to: 1, label: "x²", part: "p0", above: true, at: 1 }] },
    { chips: [{ row: 0, col: 0, text: "1", part: "pq", ghost: true }, { row: 2, col: 0, text: "2", part: "p1", from: [0, 1], at: 0.3 }] },
  ], "alt");

  it("shows frame i at beat i, and the last frame stays", () => {
    expect(shownAt(d, 0).filter(i => i.type === "rect")).toHaveLength(3);
    expect(shownAt(d, 1).filter(i => i.type === "rect")).toHaveLength(4);
    expect(d.items.filter(i => i.from === 2).every(i => i.until == null)).toBe(true);
    expect(d.items.filter(i => i.from === 0).every(i => i.until === 0)).toBe(true);
  });

  it("lines a cancelled pair up, one over the other, both struck", () => {
    const [top, bottom] = shownAt(d, 1).filter((i): i is Rect => i.type === "rect" && (i.x === shownAt(d, 1).filter((j): j is Rect => j.type === "rect")[2]!.x));
    expect(bottom!.y - top!.y).toBe(CHIPS.row);
    expect(shownAt(d, 1).filter(i => i.type === "line" && i.cls === "ln2")).toHaveLength(2);
  });

  it("draws a missing chip dashed, and slides a chip from its old spot", () => {
    expect(rects(d, /\bghost\b/)).toHaveLength(1);
    const s = rects(d, /\bxchip p1\b/).find(r => r.enter === "slide")!;
    expect(px(s.vars!["--dx"])).toBe(CHIPS.pitch);
    expect(px(s.vars!["--dy"])).toBe(-2 * CHIPS.row);
  });

  it("frames everything inside its canvas", () => expect(inside(d)).toBe(true));
});

describe("term table", () => {
  const d = buildTermTable({
    cols: [{ label: "x", sup: "2", part: "p0" }, { label: "x", part: "p1" }, { label: "1", part: "p2" }],
    rows: [{ label: "f" }, { label: "f′", from: 1 }],
    cells: [
      { row: 0, col: 0, text: "4", from: 0 },
      { row: 1, col: 1, text: "8", from: 1, slideFrom: [0, 0], at: 0.8 },
      { row: 1, col: 2, text: "0", from: 2, tone: "faded" },
    ],
    notes: [{ row: -0.55, col: 0, text: "2 ×", from: 1, until: 1, enter: "drop", at: 0.2 }],
    arrows: [{ kind: "down", a: [0, 2], b: [1, 2], from: 2 }, { kind: "across", a: [1, 0], b: [0, 1], label: "× 3", from: 2 }],
    marks: [{ row: "head", col: 0, kind: "ring", from: 0, until: 0 }],
    dropRoom: true,
    lines: [{ text: "2 × 4 = 8", from: 1, until: 1 }, { text: "f′(x) = 8x", from: 2 }],
    alt: "a",
  });

  it("gives each column its own part colour, header and wash", () => {
    for (const p of ["p0", "p1", "p2"]) {
      expect(rects(d, new RegExp(`fillsoft ${p}`))).toHaveLength(1);
      expect(texts(d).some(t => t.cls === `lbl big ${p}`)).toBe(true);
    }
    expect(rects(d, /\bxbox p1\b/)).toHaveLength(1);
  });

  it("slides a term one column right and one row down", () => {
    const s = rects(d, /\bxbox\b/).find(r => r.enter === "slide")!;
    expect(px(s.vars!["--dx"])).toBe(-TERMS.cw);
    expect(px(s.vars!["--dy"])).toBe(-TERMS.rh);
  });

  it("drops a note in from above, fades a 0 that drops out, and rings a header", () => {
    expect(texts(d).find(t => t.text === "2 ×")!.enter).toBe("drop");
    expect(rects(d, /\bcut\b/)).toHaveLength(1);
    expect(rects(d, /\bxring\b/)[0]!.y).toBeLessThan(TERMS.head);
  });

  it("runs an add-down arrow beside its column, inside the column's wash", () => {
    const wash = rects(d, /fillsoft p2/)[0]!;
    const down = d.items.find((i): i is Extract<SceneItem, { type: "line" }> => i.type === "line" && i.x1 === i.x2 && /pq/.test(i.cls ?? ""))!;
    expect(down.x1).toBeGreaterThan(wash.x);
    expect(down.x1).toBeLessThan(wash.x + wash.w);
  });

  it("shares a row between lines that are never on screen together, and fits", () => {
    const [a, b] = texts(d).filter(t => t.text === "2 × 4 = 8" || t.text === "f′(x) = 8x");
    expect(a!.y).toBe(b!.y);
    expect(inside(d)).toBe(true);
  });
});
