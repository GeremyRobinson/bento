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

/** When within beat `b` a shape is on screen, in seconds: it comes in at its delay (on its own beat) and goes when it fades out. */
function windowOf(t: SceneItem, b: number): [number, number] {
  const mine = (t.from ?? 0) === b;
  const start = mine && t.enter ? t.delay ?? 0 : 0;
  const end = /a-outsoon/.test(t.cls ?? "") ? t.delay ?? 0 : t.enter === "flash" ? parseFloat(String(t.vars?.["--d2"] ?? "Infinity")) : Infinity;
  return [start, end];
}

/** Labels on screen together never overlap, and every label sits inside the canvas. */
function labelProblems(d: SceneDiagram, beats: number): string[] {
  const out: string[] = [];
  for (let b = 0; b < beats; b++) {
    const ts = textsAt(d, b).filter(t => t.text.trim());
    const boxes = ts.map(boxOf), spans = ts.map(t => windowOf(t, b));
    boxes.forEach((a, i) => {
      const t = ts[i]!;
      if (a.x0 < -1 || a.x1 > d.width + 1 || a.y0 < -1 || a.y1 > d.height + 1) out.push(`beat ${b}: "${t.text}" leaves the ${d.width}×${d.height} canvas`);
      for (let j = i + 1; j < boxes.length; j++) {
        const c = boxes[j]!;
        const together = spans[i]![0] < spans[j]![1] && spans[j]![0] < spans[i]![1];
        if (together && a.x0 < c.x1 - 1 && c.x0 < a.x1 - 1 && a.y0 < c.y1 - 1 && c.y0 < a.y1 - 1) out.push(`beat ${b}: "${t.text}" overlaps "${ts[j]!.text}"`);
      }
    });
  }
  return out;
}
const badText = (d: SceneDiagram) => d.items.filter((i): i is Text => i.type === "text").map(t => t.text + (t.sup ?? "")).filter(s => /NaN|undefined|Infinity|\+ -|- -|\b1x|--/.test(s));

/** The 26 lessons whose page was a stack of equations, and the family each one now draws with. */
const PICTURED = {
  "g1-ten": "early-frames",
  "g6-trap": "area-model",
  "g5-order": "expression-boxes",
  "g6-expo": "expression-boxes",
  "g11-compose": "expression-boxes",
  "g12-chain": "expression-boxes",
  "g8-exp": "factor-chips",
  "g9-negexp": "factor-chips",
  "g11-expeq": "factor-chips",
  "g11-ratexp": "factor-chips",
  "g9-polyadd": "term-table",
  "g11-synth": "term-table",
  "g12-polyd": "term-table",
  "g12-power": "term-table",
  "g12-anti": "term-table",
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

describe("g1-ten", () => {
  const l = lesson("g1-ten");
  type Circle = Extract<SceneItem, { type: "circle" }>;
  it("fills the first frame with dots that slide over from the second, leaving the rest there", () => {
    for (const p of problemsOf(l) as { a: number; b: number }[]) {
      const d = sceneOf(l, p), need = 10 - p.a, left = p.b - need;
      const cells = d.items.filter(i => i.type === "rect" && /\bseg\b/.test(i.cls ?? "")) as Extract<SceneItem, { type: "rect" }>[];
      const split = (cells[4]!.x + cells[4]!.w + cells[10]!.x) / 2;
      const dots = (b: number) => shownAt(d, b).filter((i): i is Circle => i.type === "circle" && /\bdotp\b/.test(i.cls ?? ""));
      const count = (b: number) => [dots(b).filter(c => c.cx < split).length, dots(b).filter(c => c.cx > split).length];
      expect(count(0)).toEqual([p.a, p.b]);
      expect(count(1)).toEqual([10, left]);
      expect(count(2)).toEqual([10, left]);
      // the counted empty boxes are the ones the moving dots land in
      expect(shownAt(d, 0).filter(i => i.type === "circle" && /\bpq\b/.test(i.cls ?? "")).length).toBe(need);
      // each sliding dot starts exactly where one of the second frame's last dots was
      const before = dots(0).filter(c => c.cx > split).slice(left);
      const moved = dots(1).filter(c => c.enter === "slide");
      expect(moved.length).toBe(need);
      moved.forEach((c, k) => {
        const dx = parseFloat(String(c.vars!["--dx"])), dy = parseFloat(String(c.vars!["--dy"]));
        expect([c.cx + dx, c.cy + dy]).toEqual([before[k]!.cx, before[k]!.cy]);
      });
      expect(textsAt(d, 2).map(t => t.text)).toEqual(expect.arrayContaining(["10", `${p.b} = ${need} + ${left}`, `10 + ${left} = ${p.a + p.b}`]));
    }
  });
  it("never draws a number in grade 1's green (right) part colour", () => {
    const d = sceneOf(l, l.reference);
    expect(d.items.filter(i => /\bp0\b/.test(i.cls ?? ""))).toEqual([]);
  });
});

// ---- the lessons on the three new kinds ----
type Rect = Extract<SceneItem, { type: "rect" }>;
const finalText = (d: SceneDiagram, beat: number) => textsAt(d, beat).filter(t => !/a-outsoon/.test(t.cls ?? "") && t.enter !== "flash").map(t => t.text);
const chipsAt = (d: SceneDiagram, beat: number, cls = /\bxchip\b/) => shownAt(d, beat).filter((i): i is Rect => i.type === "rect" && cls.test(i.cls ?? "") && !/a-outsoon/.test(i.cls ?? "") && i.enter !== "flash");
const value = (l: AnyLesson, p: unknown, id: string) => l.answers(p).steps.find(s => s.id === id)!.slots[0]!.expected!;
const fmt = (n: number) => (n < 0 ? `−${-n}` : String(n));

describe("expression-box lessons", () => {
  it("g5-order collapses the boxes in order, each into the value its step finds, ending on the answer", () => {
    const l = lesson("g5-order");
    for (const p of problemsOf(l, 30)) {
      const d = sceneOf(l, p);
      ["s0", "s1"].forEach((id, beat) => expect(finalText(d, beat)).toContain(String(value(l, p, id))));
      expect(finalText(d, 2)).toEqual(expect.arrayContaining([String(value(l, p, "s2"))]));
      expect(chipsAt(d, 2, /\bxchip pq\b/)).toHaveLength(1);
    }
  });
  it("g6-expo opens the power into exactly n copies of a, never a × n", () => {
    const l = lesson("g6-expo");
    for (const p of problemsOf(l, 30) as { a: number; n: number }[]) {
      const opened = textsAt(sceneOf(l, p), 0).map(t => t.text).filter(t => t.includes("×") && !t.includes("+"));
      expect(opened).toContain(Array(p.n).fill(p.a).join(" × "));
    }
  });
  it("g11-compose works inside out: g's value slides into f's slot, and f gives the answer", () => {
    const l = lesson("g11-compose");
    for (const p of problemsOf(l, 30)) {
      const d = sceneOf(l, p), g = value(l, p, "inside"), out = value(l, p, "outside");
      const slid = d.items.find(i => i.from === 1 && i.enter === "slide" && i.type === "text")!;
      expect((slid as { text: string }).text).toBe(fmt(g));
      expect(finalText(d, 2)).toContain(fmt(out));
    }
  });
  it("g12-chain keeps the inside dashed and untouched, sends its rate to the front, and merges n × a", () => {
    const l = lesson("g12-chain");
    for (const p of problemsOf(l, 30) as { a: number; n: number }[]) {
      const d = sceneOf(l, p);
      for (let b = 0; b < 4; b++) expect(shownAt(d, b).some(i => /\bxbox p1 dash\b/.test(i.cls ?? ""))).toBe(true);
      expect(d.items.some(i => i.from === 2 && i.enter === "slide" && i.type === "text" && i.text === String(p.a))).toBe(true);
      expect(finalText(d, 3)).toContain(String(p.a * p.n));
    }
  });
});

describe("factor-chip lessons", () => {
  it("g8-exp writes out every x, counts the ones left to the new exponent, then turns them into 2s", () => {
    const l = lesson("g8-exp");
    for (const p of problemsOf(l, 40) as { t: number; a: number; b: number; exponent: number }[]) {
      const d = sceneOf(l, p), e = p.exponent;
      const xs = chipsAt(d, 1).length;
      expect(xs).toBe([p.a + p.b, p.a + 2 * p.b, p.a * p.b][p.t]);
      const counts = textsAt(d, 2).filter(t => /\bpq\b/.test(t.cls ?? "") && /^\d+$/.test(t.text));
      expect(counts.map(t => Number(t.text)).sort((x, y) => x - y)).toEqual(Array.from({ length: e }, (_, i) => i + 1));
      expect(textsAt(d, 3).filter(t => t.text === "2" && t.enter === "pop")).toHaveLength(e);
      if (p.t === 1) expect(shownAt(d, 2).filter(i => i.type === "line" && i.cls === "ln2")).toHaveLength(2 * p.b);
    }
  });
  it("g9-negexp takes the chips away one by one to an empty 1, then brings them back under a bar", () => {
    const l = lesson("g9-negexp");
    for (const p of problemsOf(l, 30) as { a: number; n: number }[]) {
      const d = sceneOf(l, p);
      expect(chipsAt(d, 0)).toHaveLength(p.n);
      expect(shownAt(d, 1).filter(i => i.type === "rect" && /a-outsoon/.test(i.cls ?? ""))).toHaveLength(p.n);
      expect(rects(d, 1, /\bghost\b/)).toHaveLength(1);
      expect(chipsAt(d, 2, /\bxchip p1\b/)).toHaveLength(p.n);
      expect(finalText(d, 2).at(-1)).toBe(`${p.a}⁻${"⁰¹²³"[p.n]} = 1/${p.a ** p.n}`);
    }
  });
  it("g11-expeq writes the value as k chips of the base, and the chips left over (or missing) give x", () => {
    const l = lesson("g11-expeq");
    for (const p of problemsOf(l, 60) as { b: number; k: number; c: number; x: number }[]) {
      const d = sceneOf(l, p);
      expect(chipsAt(d, 1, /\bxchip p0\b/)).toHaveLength(p.k);
      expect(finalText(d, 3).join(" ")).toContain(`= ${fmt(p.x)}`);
      if (p.c < 0) expect(rects(d, 3, /\bghost\b/)).toHaveLength(-p.c);
      if (p.c > p.k) expect(shownAt(d, 3).filter(i => i.type === "line" && i.cls === "ln2")).toHaveLength(p.c - p.k);
    }
  });
  it("g11-ratexp splits the base into n equal chips, lifts one out, and lines up m copies", () => {
    const l = lesson("g11-ratexp");
    for (const p of problemsOf(l, 30) as { n: number; r: number; m: number }[]) {
      const d = sceneOf(l, p);
      expect(chipsAt(d, 0, /\bxchip p0\b/)).toHaveLength(p.n);
      expect(chipsAt(d, 2, /\bxchip p1\b/)).toHaveLength(p.m);
      expect(d.items.some(i => i.type === "text" && i.text.includes("÷"))).toBe(false);
    }
  });
});
const rects = (d: SceneDiagram, beat: number, cls: RegExp) => shownAt(d, beat).filter(i => i.type === "rect" && cls.test(i.cls ?? ""));

describe("term-table lessons", () => {
  const cellsAt = (d: SceneDiagram, beat: number) => textsAt(d, beat).filter(t => /^−?\d+$/.test(t.text) && /\blbl big (pw|acc)\b/.test(t.cls ?? "") && !/a-outsoon/.test(t.cls ?? "") && t.enter !== "flash");
  it("g9-polyadd adds each column down into the answer row", () => {
    const l = lesson("g9-polyadd");
    for (const p of problemsOf(l, 40)) {
      const d = sceneOf(l, p), ans = ["x2", "x1", "x0"].map(id => fmt(value(l, p, id)));
      const bottom = Math.max(...cellsAt(d, 3).map(t => t.y));
      expect(cellsAt(d, 3).filter(t => t.y === bottom && t.text !== "=").sort((a, b) => a.x - b.x).map(t => t.text)).toEqual(ans);
    }
  });
  it("g11-synth ends with 1, q and a ringed 0 in the bottom row", () => {
    const l = lesson("g11-synth");
    for (const p of problemsOf(l, 40)) {
      const d = sceneOf(l, p), bottom = Math.max(...cellsAt(d, 5).map(t => t.y));
      expect(cellsAt(d, 5).filter(t => t.y === bottom).sort((a, b) => a.x - b.x).map(t => t.text)).toEqual(["1", fmt(value(l, p, "add1")), "0"]);
      expect(rects(d, 5, /\bxring\b/).length).toBeGreaterThan(0);
    }
  });
  it("g12-polyd slides each term one column right with its exponent brought down", () => {
    const l = lesson("g12-polyd");
    for (const p of problemsOf(l, 40)) {
      const d = sceneOf(l, p), ids = ["x3", "x2", "x1"];
      ids.forEach((id, k) => expect(d.items.some(i => i.from === k + 1 && i.enter === "slide" && i.type === "text" && i.text === fmt(value(l, p, id)))).toBe(true));
      expect(finalText(d, 4).join(" ")).toContain(`= ${fmt(value(l, p, "at1"))}`);
      if ((p as { d: number }).d) expect(shownAt(d, 3).some(i => i.type === "line" && i.cls === "ln2")).toBe(true);
    }
  });
  it("g12-power and g12-anti move the term one column (right, then left) to its new coefficient", () => {
    for (const [id, beat, dir] of [["g12-power", 2, -1], ["g12-anti", 1, 1]] as const) {
      const l = lesson(id);
      for (const p of problemsOf(l, 30)) {
        const s = sceneOf(l, p).items.find(i => i.from === beat && i.enter === "slide" && i.type === "rect")!;
        expect(Math.sign(parseFloat(String(s.vars!["--dx"])))).toBe(dir);
      }
    }
  });
});
