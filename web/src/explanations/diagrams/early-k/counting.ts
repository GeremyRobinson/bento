// Counting pictures for kindergarten: dots in rows of ten, counted one by one (to 20) or a row at a time (by tens).
// Every count and label comes from the numbers the lesson passes in.
import type { SceneDiagram } from "../scene/schema";
import { frame, t, type Draft } from "../geo/kit";
import { WIDE } from "./fit";

const ROW = 10;

/**
 * Dots in rows of ten. With `counted`, each dot gets its counting number under it:
 * the first row at `firstBeat`, the rest at `restBeat`, and the last number is ringed at `restBeat`.
 * Without it, plain dots (the picture shown with a practice problem).
 */
export function countStrip(n: number, alt: string, counted?: { firstBeat: number; restBeat: number }): SceneDiagram {
  if (!Number.isInteger(n) || n < 1 || n > 20) throw new Error("a count strip holds 1 to 20 dots");
  const GAP = 42, R = 13, ROWGAP = counted ? 76 : 40;
  const items: Draft[] = [];
  for (let i = 0; i < n; i++) {
    const row = Math.floor(i / ROW), col = i % ROW, cx = col * GAP, cy = row * ROWGAP;
    const beat = counted ? (row === 0 ? counted.firstBeat : counted.restBeat) : 0;
    // a row counts in about a second, so the top row is full before the steps move on to the next one (v43: the picture
    // showed 7 + 2 while the words said "keep going from 10")
    const delay = counted ? 0.11 * col : 0.03 * i;
    const last = i === n - 1;
    items.push({ type: "circle", cx, cy, r: R, cls: row === 0 ? "dotp" : "dotp p1", from: beat, enter: "pop", delay } as Draft);
    if (!counted) continue;
    items.push(t(cx, cy + 30, String(i + 1), last ? "lbl acc" : "sm", { from: beat, enter: "rise", delay: delay + 0.1 }));
    if (last) items.push({ type: "circle", cx, cy, r: R + 6, cls: "ln2", from: counted.restBeat, enter: "pop", delay: delay + 0.4 } as Draft);
  }
  return frame("early-count", items, alt, 16, WIDE);
}

/**
 * `rows` rows of ten small dots. With `counted`, each row gets its number on the left at `rowBeat`
 * and its running total (10, 20, ...) on the right at `tensBeat`; the last total is the answer.
 */
export function tensRows(rows: number, alt: string, counted?: { rowBeat: number; tensBeat: number }): SceneDiagram {
  if (!Number.isInteger(rows) || rows < 1 || rows > 10) throw new Error("tens rows hold 1 to 10 rows");
  const GAP = 30, R = 10, ROWH = 34;
  const items: Draft[] = [];
  for (let r = 0; r < rows; r++) {
    const cy = r * ROWH;
    const beat = counted ? counted.rowBeat : 0, delay = counted ? 0.22 * r : 0;
    // a soft strip behind each row, so a row reads as one ten
    items.push({ type: "rect", x: -R - 5, y: cy - R - 4, w: (ROW - 1) * GAP + 2 * R + 10, h: 2 * R + 8, rx: R + 4, cls: "fillsoft", from: beat, enter: "growx", delay } as Draft);
    for (let i = 0; i < ROW; i++) items.push({ type: "circle", cx: i * GAP, cy, r: R, cls: "dotp", from: beat, enter: "pop", delay: delay + 0.02 * i } as Draft);
    if (!counted) continue;
    items.push(t(-R - 22, cy, String(r + 1), "xs", { from: counted.rowBeat, enter: "fade", delay }));
    const last = r === rows - 1;
    items.push(t((ROW - 1) * GAP + R + 34, cy, String((r + 1) * ROW), last ? "lbl acc" : "lbl", { from: counted.tensBeat, enter: "rise", delay: 0.45 * r }));
  }
  return frame("early-tens", items, alt, 14, WIDE);
}
