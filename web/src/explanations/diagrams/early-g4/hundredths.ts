// Comparing decimals (4th grade): each decimal's part after the point shaded on its own hundredths grid,
// tenths as whole columns and hundredths as single squares, so the bigger amount is the one with more shaded.
import type { SceneDiagram } from "../scene/schema";
import { frame, t, type Draft } from "../geo/kit";

export interface HundredthsGrid {
  /** the decimal as written, above the grid */
  label: string;
  /** hundredths shaded (0 to 100) */
  count: number;
  /** the line under the grid, e.g. "50 hundredths" */
  note: string;
  beat: number;
}

export interface HundredthsSpec {
  grids: [HundredthsGrid, HundredthsGrid];
  /** the sign between the grids */
  sign: { text: string; beat: number };
  /** the first decimal is part blue and the second part orange; the sign being found is amber */
  alt: string;
}

const C = 13, G = C * 10, SPACE = 74;

export function buildHundredths(s: HundredthsSpec): SceneDiagram {
  const items: Draft[] = [];
  s.grids.forEach((g, k) => {
    const x0 = k * (G + SPACE), on = k === 1 ? "seg on p1" : "seg on";
    items.push(t(x0 + G / 2, -24, g.label, k === 1 ? "lbl big p1" : "lbl big p0", { enter: "fade" }));
    items.push({ type: "rect", x: x0, y: 0, w: G, h: G, rx: 3, cls: "seg", enter: "fade" } as Draft);
    const full = Math.floor(g.count / 10), part = g.count % 10;
    for (let c = 0; c < full; c++) {
      items.push({ type: "rect", x: x0 + c * C, y: 0, w: C, h: G, cls: on, from: g.beat, enter: "growy", delay: Math.round(c * 0.08 * 100) / 100 } as Draft);
    }
    if (part) items.push({ type: "rect", x: x0 + full * C, y: 0, w: C, h: part * C, cls: on, from: g.beat, enter: "growy", delay: Math.round(full * 0.08 * 100) / 100 } as Draft);
    for (let j = 1; j < 10; j++) {
      items.push({ type: "line", x1: x0 + j * C, y1: 0, x2: x0 + j * C, y2: G, cls: "grid", enter: "fade" } as Draft);
      items.push({ type: "line", x1: x0, y1: j * C, x2: x0 + G, y2: j * C, cls: "grid", enter: "fade" } as Draft);
    }
    items.push({ type: "rect", x: x0, y: 0, w: G, h: G, rx: 3, cls: "ax thin", enter: "fade" } as Draft);
    items.push(t(x0 + G / 2, G + 24, g.note, "sm", { from: g.beat, enter: "rise", delay: 0.5 }));
  });
  items.push(t(G + SPACE / 2, G / 2, s.sign.text, "big acc", { from: s.sign.beat, enter: "pop" }));
  return frame("hundredths", items, s.alt, 14);
}

/**
 * Tenths and hundredths on the master grid (G 2026-10-15): one cell of the grid is one hundredth, a column of ten cells
 * is one tenth and a 10 by 10 square is one whole, so the grid itself does the counting. The squares sit on the bold
 * every-ten lines, so pulling back from one cell shows the tens and then the hundreds.
 */
export interface HundredthsSumSpec {
  /** tenths in the first number (1 to 9) */
  a: number;
  /** hundredths in the second number (1 to 99) */
  b: number;
  /** the total written as a decimal, e.g. "0.55" */
  decimal: string;
  alt: string;
}

const CELL = 10, BOX = CELL * 10;
type Spot = { x: number; y: number };
interface SumLayout { w: number; h: number; a: Spot; b: Spot; plus: Spot; sum: Spot[]; eq?: Spot; total: "right" | "over"; major?: [number, number] }

/** where the squares go in each master: the square and wide masters keep every square on the bold lines, the strip
 *  is one row, two cells taller than its master so the labels, held at the phone's floor, clear the squares */
function sumLayout(shape: "square" | "wide" | "strip", wholes: number): SumLayout {
  if (shape === "strip") {
    const sum = wholes === 1 ? [{ x: 280, y: 70 }] : [{ x: 260, y: 70 }, { x: 370, y: 70 }];
    return { w: 480, h: 180, a: { x: 10, y: 70 }, b: { x: 140, y: 70 }, plus: { x: 125, y: 120 }, sum, ...(wholes === 1 ? { eq: { x: 260, y: 120 } } : {}), total: wholes === 1 ? "right" : "over" };
  }
  const dx = shape === "wide" ? 90 : 0;
  const sum = wholes === 1 ? [{ x: dx + 130, y: 240 }] : [{ x: dx + 30, y: 240 }, { x: dx + 230, y: 240 }];
  return { w: shape === "wide" ? 540 : 360, h: 360, a: { x: dx + 30, y: 40 }, b: { x: dx + 230, y: 40 }, plus: { x: dx + 180, y: 90 }, sum, total: wholes === 1 ? "right" : "over", major: [dx + 30, 40] };
}

/** shades hundredths `lo` to `hi` of a square, a tenth (column) at a time, top down, each column growing in turn */
function shade(items: Draft[], at: Spot, lo: number, hi: number, cls: string, from: number, lead = 0) {
  for (let c = Math.floor(lo / 10); c * 10 < hi; c++) {
    const top = Math.max(lo, c * 10) - c * 10, bot = Math.min(hi, c * 10 + 10) - c * 10;
    items.push({ type: "rect", x: at.x + c * CELL, y: at.y + top * CELL, w: CELL, h: (bot - top) * CELL, rx: 0, cls: `${cls} flat`, ...(cls.includes("p1") ? { vars: { "--tint": "var(--pic-mid)" } } : {}), from, enter: "growy",
      delay: Math.round((lead + (c - Math.floor(lo / 10)) * 0.06) * 100) / 100 } as Draft);
  }
}

/** a whole: blank paper, its tenths (columns) from `tenths`, its hundredths (rows) from `hundredths`, and its edge */
function square(items: Draft[], at: Spot, from: number, tenths: number, hundredths: number, fills: () => void) {
  items.push({ type: "rect", x: at.x, y: at.y, w: BOX, h: BOX, rx: 0, cls: "seg flat", from, enter: "fade" } as Draft);
  fills();
  for (let j = 1; j < 10; j++) {
    items.push({ type: "line", x1: at.x + j * CELL, y1: at.y, x2: at.x + j * CELL, y2: at.y + BOX, cls: "cellln ten", from: tenths, enter: "fade" } as Draft);
    items.push({ type: "line", x1: at.x, y1: at.y + j * CELL, x2: at.x + BOX, y2: at.y + j * CELL, cls: "cellln", from: hundredths, enter: "fade", delay: Math.round(j * 0.04 * 100) / 100 } as Draft);
  }
  items.push({ type: "rect", x: at.x, y: at.y, w: BOX, h: BOX, rx: 0, cls: "box100", from, enter: "fade" } as Draft);
}

function buildSumIn(s: HundredthsSumSpec, shape: "square" | "wide" | "strip"): SceneDiagram {
  const { a, b } = s, S = 10 * a + b, wholes = Math.ceil(S / 100), L = sumLayout(shape, wholes), items: Draft[] = [];
  const over = (p: Spot) => p.y - CELL * (shape === "strip" ? 2.5 : 1.5);
  // beat 0: a tenths and b hundredths; beat 1 cuts the tenths into hundredths
  square(items, L.a, 0, 0, 1, () => shade(items, L.a, 0, 10 * a, "seg on", 0));
  items.push(t(L.a.x + BOX / 2, over(L.a), `${a}/10`, "lbl", { until: 0, enter: "fade" }));
  items.push(t(L.a.x + BOX / 2, over(L.a), `${10 * a}/100`, "lbl", { from: 1, enter: "fade" }));
  items.push(t(L.plus.x, L.plus.y, "+", "big", { enter: "fade" }));
  square(items, L.b, 0, 0, 0, () => shade(items, L.b, 0, b, "seg on p1", 0));
  // a phone's strip with two wholes needs the room over the second square for the total at the end
  items.push(t(L.b.x + BOX / 2, over(L.b), `${b}/100`, "lbl", { enter: "fade", ...(shape === "strip" && wholes > 1 ? { until: 2 } : {}) }));
  // beat 2: the same hundredths put together, filling one whole before the next
  L.sum.forEach((p, w) => square(items, p, 2, 2, 2, () => {
    const on = [Math.max(0, -w * 100), Math.min(100, 10 * a - w * 100)], two = [Math.max(0, 10 * a - w * 100), Math.min(100, S - w * 100)];
    if (on[1]! > on[0]!) shade(items, p, on[0]!, on[1]!, "seg on", 2, 0.3 + w * 0.6);
    if (two[1]! > two[0]!) shade(items, p, two[0]!, two[1]!, "seg on p1", 2, 0.3 + w * 0.6 + (on[1]! > on[0]! ? (on[1]! - on[0]!) / 10 * 0.06 : 0));
  }));
  if (L.eq) items.push(t(L.eq.x, L.eq.y, "=", "big", { from: 2, enter: "fade" }));
  const first = L.sum[0]!, last = L.sum[L.sum.length - 1]!;
  if (L.total === "right") {
    items.push(t(first.x + BOX / 2, over(first), `${S}/100`, "lbl", { from: 2, enter: "fade", delay: 0.3 }));
    items.push(t(last.x + BOX + CELL, last.y + BOX / 2, `= ${s.decimal}`, "lbl pw acc start", { from: 3, enter: "rise" }));
  } else if (shape === "strip") {
    // two squares side by side leave no room for two labels: one line over them, flush right, names the total, then the decimal
    const ex = last.x + BOX;
    items.push(t(ex, over(first), `${S}/100`, "lbl end", { from: 2, until: 2, enter: "fade", delay: 0.3 }));
    items.push(t(ex, over(first), `${S}/100 = ${s.decimal}`, "lbl end", { from: 3, enter: "fade" }));
  } else {
    items.push(t(first.x, over(first), `${S}/100`, "lbl start", { from: 2, enter: "fade", delay: 0.3 }));
    items.push(t(last.x + BOX, over(last), `= ${s.decimal}`, "lbl pw acc end", { from: 3, enter: "rise" }));
  }
  return { kind: "scene", family: "hundredths", width: L.w, height: L.h, items: items as SceneDiagram["items"], alt: s.alt, square: true, camera: true, shape, ...(L.major ? { major: L.major } : {}), block: BOX };
}

export function buildHundredthsSum(s: HundredthsSumSpec): SceneDiagram {
  const square = buildSumIn(s, "square");
  return { ...square, shapes: { square, wide: buildSumIn(s, "wide"), strip: buildSumIn(s, "strip") } };
}
