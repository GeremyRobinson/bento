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
  "g4-divide": "area-model",
  "g5-divide": "area-model",
  "g5-multdec": "area-model",
  "g9-radical": "area-model",
  "g11-radical": "area-model",
  "g6-divide": "tape",
  "g6-eval": "tape",
  "g5-adddec": "columns",
  "g5-divdec": "double-line",
  "g9-elim": "balance",
  "g11-evalpoly": "plane",
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
  it("g5-order lights the box that goes first, then collapses the boxes in order, each into the value its step finds, ending on the answer", () => {
    const l = lesson("g5-order");
    for (const p of problemsOf(l, 30)) {
      const d = sceneOf(l, p);
      expect(shownAt(d, 0).some(i => i.type === "rect" && /\bhlline\b/.test(i.cls ?? ""))).toBe(true);
      expect(chipsAt(d, 0)).toHaveLength(0);
      ["s0", "s1"].forEach((id, k) => expect(finalText(d, k + 1)).toContain(String(value(l, p, id))));
      expect(finalText(d, 3)).toEqual(expect.arrayContaining([String(value(l, p, "s2"))]));
      expect(chipsAt(d, 3, /\bxchip pq\b/)).toHaveLength(1);
    }
  });
  it("g6-expo opens the power into exactly n copies of a, never a × n", () => {
    const l = lesson("g6-expo");
    for (const p of problemsOf(l, 30) as { a: number; n: number }[]) {
      const opened = textsAt(sceneOf(l, p), 0).map(t => t.text).filter(t => t.includes("×") && !t.includes("+"));
      expect(opened).toContain(Array(p.n).fill(p.a).join(" × "));
    }
  });
  it("g11-compose works inside out: g's value is written into f's slot on the next line, and f gives the answer", () => {
    const l = lesson("g11-compose");
    for (const p of problemsOf(l, 30)) {
      const d = sceneOf(l, p), g = value(l, p, "inside"), out = value(l, p, "outside");
      const k = textsAt(d, 0).find(t => /\bxchip\b|acc/.test(t.cls ?? "") && t.from === 0 && !/muted/.test(t.cls ?? ""))!;
      const written = d.items.find((i): i is Text => i.from === 1 && i.type === "text" && i.text === fmt(g) && !/dimmed/.test(i.cls ?? ""))!;
      expect(written.y).toBeGreaterThan(k.y);
      expect(finalText(d, 2)).toContain(fmt(out));
    }
  });
  it("g12-chain keeps the inside dashed and untouched, sends its rate to the front, and merges n × a", () => {
    const l = lesson("g12-chain");
    for (const p of problemsOf(l, 30) as { a: number; n: number }[]) {
      const d = sceneOf(l, p);
      for (let b = 0; b < 5; b++) expect(shownAt(d, b).some(i => /\bxbox p1 dash\b/.test(i.cls ?? ""))).toBe(true);
      // why: the inside's own rate is named on its box before it moves
      expect(textsAt(d, 2).map(t => t.text)).toContain(`moves ${p.a} per 1`);
      // the rate is written at the front of the next line (nothing slides across)
      expect(d.items.some(i => i.from === 3 && i.enter === "rise" && i.type === "text" && i.text === String(p.a))).toBe(true);
      expect(finalText(d, 4)).toContain(String(p.a * p.n));
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
  it("g11-synth ends with 1, q and the remainder (ringed when it lands, checked at r) in the bottom row", () => {
    const l = lesson("g11-synth");
    for (const p of problemsOf(l, 40)) {
      const d = sceneOf(l, p), bottom = Math.max(...cellsAt(d, 6).map(t => t.y)), rem = value(l, p, "rem");
      expect(cellsAt(d, 6).filter(t => t.y === bottom).sort((a, b) => a.x - b.x).map(t => t.text)).toEqual(["1", fmt(value(l, p, "add1")), fmt(rem)]);
      expect(rects(d, 4, /\bxring\b/).length).toBeGreaterThan(0);
      expect(finalText(d, 5).join(" ")).toContain(`check:`);
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

// ---- the lessons on the existing families ----
describe("area-model lessons", () => {
  it("g4-divide fills a T column, then an O column, and leaves r unit squares beside it, too few for a column", () => {
    const l = lesson("g4-divide");
    for (const p of problemsOf(l) as { dv: number; q: number; r: number }[]) {
      const d = sceneOf(l, p), T = p.q - (p.q % 10), O = p.q % 10;
      // beat 0 only asks how many fit; the T column and its product arrive on beat 1
      expect(textsAt(d, 0).map(t => t.text)).toContain(`${p.dv} × ? ≤ ${p.dv * p.q + p.r}`);
      expect(textsAt(d, 1).map(t => t.text)).toContain(String(p.dv * T));
      expect(textsAt(d, 2).map(t => t.text)).toContain(String(p.dv * O));
      const stub = rects(d, 4, /\bxchip pq\b/) as Rect[], column = (rects(d, 4, /^pend$/) as Rect[]).at(-1)!;
      expect(stub).toHaveLength(p.r);
      // dv of the remainder's squares would fill the column next to them
      if (p.r) expect(column.h / (stub[0]!.h + 3)).toBeCloseTo(p.dv, 1);
      expect(finalText(d, 4)).toContain(p.r ? `${p.r} left over: ${p.q} R ${p.r}` : `${p.dv * p.q} ÷ ${p.dv} = ${p.q} exactly`);
    }
  });
  it("g5-divide fills the rest exactly, with no remainder, and joins the two widths into the answer", () => {
    const l = lesson("g5-divide");
    for (const p of problemsOf(l) as { dv: number; qt: number }[]) {
      const d = sceneOf(l, p), T = p.qt - (p.qt % 10), O = p.qt % 10;
      expect(rects(d, 3, /\bxchip\b/)).toHaveLength(0);
      expect(finalText(d, 3)).toContain(`${T} + ${O} = ${p.qt}`);
    }
  });
  it("g5-multdec lays an A by B block of small pieces on whole unit squares, and names the place they count", () => {
    const l = lesson("g5-multdec"), PLACE = ["ones", "tenths", "hundredths", "thousandths"];
    for (const p of problemsOf(l) as { A: number; B: number; pa?: number; pb?: number }[]) {
      const pa = p.pa ?? 1, pb = p.pb ?? 1, x = p.A / 10 ** pa, y = p.B / 10 ** pb;
      const d = sceneOf(l, p), lines = shownAt(d, 0).filter(i => i.type === "line" && i.cls === "grid");
      const vertical = lines.filter(i => i.type === "line" && i.x1 === i.x2).length, flat = lines.length - vertical;
      // every cut is drawn whole, or left out where its lines would run together; tenths by tenths always shows
      expect([0, p.A - 1]).toContain(vertical);
      expect([0, p.B - 1]).toContain(flat);
      if (pa === 1 && pb === 1) expect([vertical, flat]).toEqual([p.A - 1, p.B - 1]);
      expect(rects(d, 0, /^ax$/)).toHaveLength(Math.ceil(x - 1e-9) * Math.ceil(y - 1e-9));
      expect(finalText(d, 0)).toContain(`${p.A} × ${p.B} = ${p.A * p.B} small pieces`);
      expect(finalText(d, 2).join(" ")).toContain(`${p.A * p.B} ${PLACE[pa + pb]} = `);
      expect(rects(d, 1, /\bxring\b/)).toHaveLength(1);
    }
  });
  it("g9-radical cuts the square into k × k tiles of m, and its side into k√m", () => {
    const l = lesson("g9-radical");
    for (const p of problemsOf(l) as { k: number; m: number }[]) {
      const d = sceneOf(l, p);
      expect(rects(d, 1, /^cell /)).toHaveLength(p.k * p.k);
      expect(textsAt(d, 1).filter(t => t.text === String(p.m))).toHaveLength(p.k * p.k);
      expect(textsAt(d, 3).map(t => t.text)).toContain(`${p.k}√${p.m}`);
    }
  });
  it("g11-radical splits the b × b unit squares into the + a and x, spilling over when x is not more than 0", () => {
    const l = lesson("g11-radical");
    const cases = [...problemsOf(l), { a: 6, b: 2 }, { a: 4, b: 2 }, { a: -9, b: 9 }].map(p => l.restore(p) as { a: number; b: number; x: number });
    for (const p of cases) {
      const d = sceneOf(l, p), sq = p.b * p.b;
      const inA = Math.max(0, Math.min(p.a, sq));
      expect(rects(d, 3, /\bxchip p0\b/)).toHaveLength(inA);
      expect(rects(d, 3, /\bxchip p2\b/)).toHaveLength(sq - inA);
      const outside = p.a < 0 ? -p.a : Math.max(0, p.a - sq);
      expect(rects(d, 3, /\bdash\b/)).toHaveLength(outside);
      expect(shownAt(d, 3).filter(i => i.type === "line" && i.cls === "ln2")).toHaveLength(p.a > 0 ? outside : 0);
      expect(finalText(d, 3).join(" ")).toContain(`= ${fmt(p.x)}`);
    }
  });
});

describe("tape lessons", () => {
  type FracP = { a: number; b: number; c: number; d: number };
  it("g6-divide measures a/b with copies of c/d: whole copies, then a short one in the accent", () => {
    const l = lesson("g6-divide");
    for (const p of problemsOf(l) as FracP[]) {
      const d = sceneOf(l, p), S = p.a * p.d, L = p.b * p.c;
      const copies = d.items.filter(i => i.type === "rect" && i.from === 3 && /\bseg on\b/.test(i.cls ?? ""));
      expect(copies).toHaveLength(Math.ceil(S / L));
      expect(copies.filter(i => i.vars?.["--tint"] === "var(--acc)")).toHaveLength(S % L ? 1 : 0);
      expect(textsAt(d, 2).map(t => t.text)).toEqual(expect.arrayContaining([`${S} small pieces`, `${L} small pieces`]));
      // never in grade 6's lime (right) part colour
      expect(d.items.filter(i => /\bp1\b/.test(i.cls ?? ""))).toEqual([]);
    }
  });
  it("g6-eval draws a boxes of x and b boxes of y on one scale, then both lengths in one bar", () => {
    const l = lesson("g6-eval");
    for (const p of problemsOf(l) as { a: number; b: number; x: number; y: number }[]) {
      const d = sceneOf(l, p), segs = (b: number) => d.items.filter((i): i is Rect => i.type === "rect" && i.cls === "seg" && (i.from ?? 0) === b);
      expect(segs(0)).toHaveLength(p.a);
      expect(segs(1)).toHaveLength(p.b);
      const len = (rs: Rect[]) => Math.max(...rs.map(r => r.x + r.w)) - Math.min(...rs.map(r => r.x));
      // within the parts' small insets (a few px at each end of a bar); when one kind of box would be too small to read,
      // it is drawn at the minimum size instead, so then every box is at least that wide
      const widths = [...segs(0), ...segs(1)].map(r => r.w);
      if (Math.min(...widths) > 20) expect(Math.abs((len(segs(0)) + 3) / (len(segs(1)) + 3) / ((p.a * p.x) / (p.b * p.y)) - 1)).toBeLessThan(0.05);
      else expect(Math.min(...widths)).toBeGreaterThanOrEqual(14);
      expect(textsAt(d, 2).map(t => t.text)).toContain(String(p.a * p.x + p.b * p.y));
      // a letter in a box gives way to its number
      for (const t of d.items.filter((i): i is Text => i.type === "text" && (i.text === "x" || i.text === "y"))) expect(t.cls).toMatch(/a-outsoon/);
    }
  });
});

describe("columns, double line, balance and plane lessons", () => {
  it("g5-adddec lines the points up, writes in the zeros, and adds the whole and decimal partials into the sum", () => {
    const l = lesson("g5-adddec");
    for (const p of problemsOf(l) as { a: number; b: number }[]) {
      const d = sceneOf(l, p), sum = Math.round((p.a + p.b) * 100);
      const pads = [p.a, p.b].reduce((s, v) => s + 2 - (String(v).split(".")[1]?.length ?? 0), 0);
      expect(textsAt(d, 0).filter(t => t.cls === "lbl big acc")).toHaveLength(pads);
      const answer = textsAt(d, 3).filter(t => t.cls === "lbl big acc" && t.from === 3 && t.text !== ".").sort((x, y) => x.x - y.x).map(t => t.text).join("");
      expect(answer).toBe(String(sum));
    }
  });
  it("g5-divdec matches the lines tick for tick and hops qt times", () => {
    const l = lesson("g5-divdec");
    for (const p of problemsOf(l) as { d: number; qt: number }[]) {
      const d = sceneOf(l, p);
      const hops = d.items.filter(i => i.type === "path" && i.cls === "ln thin pq" && i.from === 2);
      expect(hops).toHaveLength(2 * p.qt);
      expect(textsAt(d, 2).map(t => t.text)).toEqual(expect.arrayContaining([String(p.qt), String(p.d * p.qt)]));
    }
  });
  it("g9-elim strikes y and −y together, and the late blocks are 2x, x and y", () => {
    const l = lesson("g9-elim");
    for (const p of problemsOf(l) as { x: number; y: number }[]) {
      const d = sceneOf(l, p);
      expect(shownAt(d, 2).filter(i => i.type === "rect" && /\btile y\b/.test(i.cls ?? ""))).toHaveLength(2);
      const late = [2, 3, 4].map(b => textsAt(d, b).find(t => t.delay === 1 && t.cls === "lbl acc")!.text);
      expect(late).toEqual([fmt(2 * p.x), fmt(p.x), fmt(p.y)]);
    }
  });
  it("g11-evalpoly stacks the three pieces and lands on the curve at (k, f(k))", () => {
    const l = lesson("g11-evalpoly");
    for (const p of problemsOf(l) as { a: number; b: number; c: number; k: number }[]) {
      const d = sceneOf(l, p), total = p.a * p.k * p.k + p.b * p.k + p.c;
      const pieces = d.items.filter(i => i.type === "path" && /\bln p[012]\b/.test(i.cls ?? ""));
      expect(pieces).toHaveLength(p.c ? 3 : 2);
      expect(textsAt(d, 3).map(t => t.text)).toContain(`f(${fmt(p.k)}) = ${fmt(total)}`);
      expect(shownAt(d, 3).some(i => i.type === "circle" && /\bdota\b/.test(i.cls ?? ""))).toBe(true);
    }
  });
});
