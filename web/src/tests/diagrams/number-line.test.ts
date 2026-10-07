// The number-line family: geometry follows the values, labels never overlap, and every generated problem fits its canvas.
import { buildNumberLine, fitRange, textWidth } from "../../explanations/diagrams/number-line/build";
import { buildDecimalShift, shiftDigits } from "../../explanations/diagrams/number-line/decimal-shift";
import { dotGroups, tenFrames } from "../../explanations/diagrams/number-line/counters";
import { buildChain, chainExplanation } from "../../explanations/diagrams/chain/build";
import type { SceneDiagram, SceneItem } from "../../explanations/diagrams/scene/schema";
import { lessonById } from "../../curriculum/registry";
import { createRng } from "../../curriculum/generators/rng";
import { num, op } from "../../curriculum/schemas/math-text";

const texts = (d: SceneDiagram) => d.items.filter((i): i is Extract<SceneItem, { type: "text" }> => i.type === "text");
const circles = (d: SceneDiagram) => d.items.filter((i): i is Extract<SceneItem, { type: "circle" }> => i.type === "circle");
const sizeOf = (cls = "") => (/\bbig\b/.test(cls) ? (/\blbl\b/.test(cls) ? 22 : 28) : /\bsm\b/.test(cls) ? 15 : /\bxs\b/.test(cls) ? 12 : 17);

/** Label boxes that are on screen together must not overlap, and everything must sit inside the canvas. */
export function layoutProblems(d: SceneDiagram, beatsCount: number): string[] {
  const out: string[] = [];
  const boxes = texts(d).map(t => {
    const size = sizeOf(t.cls), w = textWidth(t.text + (t.sup ?? ""), size);
    return { t, x0: t.x - w / 2, x1: t.x + w / 2, y0: t.y - size / 2, y1: t.y + size / 2, from: t.from ?? 0, until: t.until ?? beatsCount };
  });
  for (const b of boxes) {
    if (b.x0 < -1 || b.x1 > d.width + 1 || b.y0 < -1 || b.y1 > d.height + 1) out.push(`"${b.t.text}" runs off the ${d.width}×${d.height} canvas`);
  }
  for (let i = 0; i < boxes.length; i++) for (let j = i + 1; j < boxes.length; j++) {
    const a = boxes[i]!, b = boxes[j]!;
    if (a.from > b.until || b.from > a.until) continue;
    if (a.x0 < b.x1 - 1 && b.x0 < a.x1 - 1 && a.y0 < b.y1 - 1 && b.y0 < a.y1 - 1) out.push(`"${a.t.text}" overlaps "${b.t.text}"`);
  }
  for (const c of circles(d)) if (c.cx - c.r < -1 || c.cx + c.r > d.width + 1 || c.cy - c.r < -1 || c.cy + c.r > d.height + 1) out.push(`a dot at ${c.cx},${c.cy} is off the canvas`);
  return out;
}

describe("fitRange", () => {
  it("covers the values with whole steps of 1, 2 or 5 × 10ⁿ", () => {
    for (const vals of [[-3, 5], [0, 60], [3.47, 3.48], [-24, 0, 12], [17, 152]]) {
      const r = fitRange(vals, { maxTicks: 24 });
      expect(r.min).toBeLessThanOrEqual(Math.min(...vals));
      expect(r.max).toBeGreaterThanOrEqual(Math.max(...vals));
      expect((r.max - r.min) / r.step).toBeLessThanOrEqual(24 + 1e-9);
      expect(Math.abs(Math.round((r.max - r.min) / r.step) * r.step - (r.max - r.min))).toBeLessThan(1e-6);
    }
    expect(fitRange([-3, 5], { minStep: 1 }).step).toBe(1);
    expect(fitRange([0, 60], { maxTicks: 30, pad: 0, minStep: 1 })).toEqual({ min: 0, max: 60, step: 2 });
  });
});

describe("buildNumberLine", () => {
  const line = buildNumberLine({ min: -4, max: 6, hops: [{ from: -3, to: 0, label: "3", beat: 0 }, { from: 0, to: 5, label: "5", beat: 1 }], alt: "test" });

  it("puts ticks in proportion to the values", () => {
    const ticks = line.items.filter(i => i.type === "line" && i.cls === "tk") as Extract<SceneItem, { type: "line" }>[];
    expect(ticks).toHaveLength(11);
    const gaps = ticks.slice(1).map((t, i) => t.x1 - ticks[i]!.x1);
    for (const g of gaps) expect(g).toBeCloseTo(46, 0);
    expect(texts(line).filter(t => t.cls === "sm").map(t => t.text)).toEqual(["−4", "−3", "−2", "−1", "0", "1", "2", "3", "4", "5", "6"]);
  });

  it("starts and ends each hop on its values, on its beat", () => {
    const xOf = (v: number) => 30 + ((v + 4) / 10) * 460;
    const paths = line.items.filter(i => i.type === "path") as Extract<SceneItem, { type: "path" }>[];
    expect(paths.map(p => p.from)).toEqual([0, 1]);
    const ends = paths.map(p => p.d.match(/^M([\d.]+) [\d.]+ Q[\d.]+ -?[\d.]+ ([\d.]+)/)!.slice(1).map(Number));
    expect(ends).toEqual([[xOf(-3), xOf(0)], [xOf(0), xOf(5)]].map(e => e.map(v => Math.round(v * 10) / 10)));
    expect(texts(line).filter(t => t.cls === "lbl").map(t => t.text)).toEqual(["3", "5"]);
  });

  it("refuses values off the line", () => {
    expect(() => buildNumberLine({ min: 0, max: 10, marks: [{ v: 11, beat: 0 }], alt: "x" })).toThrow();
  });

  it("keeps labels apart: a label that would overlap moves away from the line", () => {
    const d = buildNumberLine({ min: 0, max: 10, hops: [{ from: 6, to: 7, label: "+1", beat: 0 }], marks: [{ v: 7, label: "7", beat: 0 }, { v: 6, label: "six", beat: 0 }], alt: "x" });
    expect(layoutProblems(d, 1)).toEqual([]);
  });

  it("labels only some hops in a long run of short ones", () => {
    const hops = Array.from({ length: 29 }, (_, i) => ({ from: i, to: i + 1, label: "+9", beat: 0 }));
    const d = buildNumberLine({ min: 0, max: 29, hops, alt: "x" });
    const n = texts(d).filter(t => t.cls === "lbl").length;
    expect(n).toBeGreaterThan(3);
    expect(n).toBeLessThan(29);
    expect(layoutProblems(d, 1)).toEqual([]);
  });
});

describe("decimal shift", () => {
  it("pads zeros where the point moves past the digits", () => {
    expect(shiftDigits("837", 1, 4)).toEqual({ digits: "8370", from: 1, to: 4, added: [3] });
    expect(shiftDigits("45000", 5, 1)).toEqual({ digits: "45000", from: 5, to: 1, added: [] });
    expect(shiftDigits("5", 1, -1)).toEqual({ digits: "005", from: 3, to: 1, added: [1, 0] });
  });

  it("moves the point one box per hop, from where it starts to where it lands", () => {
    const d = buildDecimalShift({ digits: "347", from: 1, to: 3, beat: 0, moveBeat: 1, label: "× 100", alt: "x" });
    const digits = texts(d).filter(t => /big/.test(t.cls ?? ""));
    expect(digits.map(t => t.text)).toEqual(["3", "4", "7"]);
    const [p0, was, p1] = circles(d);
    expect(p1!.cx - p0!.cx).toBeCloseTo(2 * 46, 5);
    expect(was!.cx).toBe(p0!.cx); // the start stays behind as a ring, so the hops leave from it
    expect(was!.until).toBeUndefined();
    expect(d.items.filter(i => i.type === "path" && /arrow/.test(i.cls ?? ""))).toHaveLength(2);
    // the point sits in the gap, clear of both boxes' outlines
    const boxes = d.items.filter(i => i.type === "rect") as { x: number; w: number }[];
    for (const c of [p0!, p1!]) for (const b of boxes) expect(c.cx + c.r <= b.x || c.cx - c.r >= b.x + b.w).toBe(true);
  });
});

describe("counting pictures", () => {
  it("draws one dot per counter", () => {
    expect(circles(dotGroups([3, 4], "x"))).toHaveLength(7);
    expect(circles(tenFrames([8, 5], "x"))).toHaveLength(13);
    expect(tenFrames([8, 5], "x").items.filter(i => i.type === "rect")).toHaveLength(20);
  });
  it("fits every dot inside the picture", () => {
    for (const a of [1, 5]) for (const b of [1, 5]) expect(layoutProblems(dotGroups([a, b], "x"), 1)).toEqual([]);
  });
});

describe("chain helper", () => {
  it("adds each beat's lines on that beat", () => {
    const ex = chainExplanation({
      heading: "h", statement: [num(1)], alt: "a",
      beats: [
        { id: "a", narration: "one", math: [num(1)], lines: [[num(1)], [num(2)]] },
        { id: "b", narration: "two", math: [num(3)], lines: [[num(3)]], answerStep: "b", result: 3 },
      ],
    });
    expect(ex.timeline).toHaveLength(2);
    expect(ex.diagram.lines.map(l => l.from)).toEqual([0, 0, 1]);
    expect(ex.steps.map(s => s.state)).toEqual([0, 1]);
    expect(buildChain([{ math: [num(1)] }, { math: [num(2), op("+"), num(3)] }, { math: [num(5)], from: 4 }], "x").lines.map(l => l.from)).toEqual([0, 1, 4]);
  });

  it("draws a given picture instead of the chain, with the same steps", () => {
    const pic: SceneDiagram = { kind: "scene", family: "test", width: 10, height: 10, items: [], alt: "p" };
    const o = {
      heading: "h", statement: [num(1)], alt: "a",
      beats: [{ id: "a", narration: "one", math: [num(1)], lines: [[num(1)]], answerStep: "a", result: 1 }],
    };
    const ex = chainExplanation({ ...o, diagram: pic });
    expect(ex.diagram).toBe(pic);
    expect(ex.steps).toEqual(chainExplanation(o).steps);
  });
});

// every picture this family draws, for the reference problem and many generated ones: nothing overlaps, nothing runs off
const SCENE_LESSONS = ["k-add", "g5-round", "g6-lcm", "g6-numline", "g7-addint", "g7-subint", "g7-mulint", "g11-seq", "g5-pow10", "g8-sci"];
describe.each(SCENE_LESSONS)("%s pictures fit", id => {
  const lesson = lessonById(id)!;
  it("for the reference and 300 generated problems", () => {
    const rng = createRng(11);
    const problems = [lesson.reference, ...Array.from({ length: 300 }, (_, i) => lesson.generate(rng, i))];
    for (const p of problems) {
      const ex = lesson.explain(p, lesson.answers(p));
      const d = ex.diagram as SceneDiagram;
      expect(d.kind).toBe("scene");
      expect(layoutProblems(d, ex.timeline.length - 1), JSON.stringify(p)).toEqual([]);
      const pic = lesson.picture?.(p) as SceneDiagram | undefined;
      if (pic) expect(layoutProblems(pic, 0), JSON.stringify(p)).toEqual([]);
    }
  });
});

describe("pictures follow the problem", () => {
  it("k-add counts the first group from 0, then hops on from a to a + b, every hop above the line", () => {
    const l = lessonById("k-add")!, p = l.generate(createRng(3), 0) as { a: number; b: number };
    const d = l.explain(p, l.answers(p)).diagram as SceneDiagram;
    const top = texts(d).filter(t => t.cls === "lbl").map(t => Number(t.text));
    expect(top).toEqual(Array.from({ length: p.a + p.b }, (_, i) => i + 1));
    // a hop below the line means taking away (v44 sweep #3): none here, so no arc is drawn in the second part colour
    const arcs = d.items.filter(it => it.type === "path" && /\bln\b/.test((it as { cls?: string }).cls ?? ""));
    expect(arcs).toHaveLength(p.a + p.b);
    expect(arcs.filter(it => /\bp1\b/.test((it as { cls?: string }).cls ?? ""))).toEqual([]);
  });
  it("g6-numline's hops are labelled with the two distances", () => {
    const l = lessonById("g6-numline")!, p = l.restore({ a: -7, b: 4 });
    const d = l.explain(p, l.answers(p)).diagram as SceneDiagram;
    expect(texts(d).filter(t => /lbl/.test(t.cls ?? "")).map(t => t.text)).toEqual(["7", "4", "7 + 4 = 11 apart"]);
  });
  it("g8-sci moves the point as many places as the power of ten", () => {
    const l = lessonById("g8-sci")!, p = l.restore({ c: 54, e: 7 });
    const d = l.explain(p, l.answers(p)).diagram as SceneDiagram;
    expect(texts(d).filter(t => /big/.test(t.cls ?? "") && !/lbl/.test(t.cls ?? "")).map(t => t.text).join("")).toBe("54000000");
    expect(d.items.filter(i => i.type === "path" && /arrow/.test(i.cls ?? ""))).toHaveLength(7);
  });
});
