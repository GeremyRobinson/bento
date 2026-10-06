// Equal groups as an array: rows of dots (or of "10" chips for tens), with running totals at the end of each row,
// outlines around each row (a group) or each column, and lines of text under it. Every count comes from the lesson.
import type { SceneDiagram } from "../scene/schema";
import { frame, t, type Draft } from "../geo/kit";

export interface ArrayText { text: string; from: number; until?: number; cls?: string }

export interface ArraySpec {
  rows: number;
  cols: number;
  /** text on each item, e.g. "10" for tens chips; plain dots when absent */
  chip?: string;
  /** beat each row appears at (default 0 for all) */
  rowFrom?: (r: number) => number;
  /** a running total at the end of each row, e.g. "6", "12", "18" */
  rowTotals?: { from: number; until?: number; text: (r: number) => string; acc?: (r: number) => boolean };
  /** a label before each row, e.g. "group 1" */
  rowLabels?: { from: number; until?: number; text: (r: number) => string };
  /** outline every row, as one group each */
  rowBoxes?: { from: number; until?: number };
  /** outline every column (the array turned around), with a count under each */
  colBoxes?: { from: number; until?: number; text?: (c: number) => string };
  /** items drawn in the accent colour from a beat, e.g. the first row */
  accent?: { from: number; until?: number; only: (r: number, c: number) => boolean }[];
  /** lines of text under the array */
  lines?: ArrayText[];
  alt: string;
}

export function buildArray(s: ArraySpec): SceneDiagram {
  const chip = s.chip != null;
  const px = chip ? 46 : 32, py = chip ? 32 : 32, R = 11, cw = 38, ch = 22;
  const items: Draft[] = [];
  const W = (s.cols - 1) * px, H = (s.rows - 1) * py;
  const when = (from: number, until?: number) => ({ from, ...(until != null ? { until } : {}) });
  const itemAt = (r: number, c: number, cls: string, from: number, until: number | undefined, delay: number) => {
    const x = c * px, y = r * py;
    if (!chip) items.push({ type: "circle", cx: x, cy: y, r: R, cls, enter: "pop", delay, ...when(from, until) } as Draft);
    else {
      items.push({ type: "rect", x: x - cw / 2, y: y - ch / 2, w: cw, h: ch, rx: 6, cls: cls === "dota" ? "sq big" : "cell c0", enter: "pop", delay, ...when(from, until) } as Draft);
      items.push(t(x, y, s.chip!, "xs", { enter: "fade", delay, ...when(from, until) }));
    }
  };
  for (let r = 0; r < s.rows; r++) {
    const from = s.rowFrom?.(r) ?? 0;
    for (let c = 0; c < s.cols; c++) itemAt(r, c, "dotp", from, undefined, Math.round(((s.rowFrom ? 0 : r * 0.08) + c * 0.03) * 100) / 100);
  }
  for (const a of s.accent ?? []) {
    for (let r = 0; r < s.rows; r++) for (let c = 0; c < s.cols; c++) if (a.only(r, c)) itemAt(r, c, "dota", a.from, a.until, Math.round(c * 0.03 * 100) / 100);
  }
  const padX = (chip ? cw / 2 : R) + 7, padY = (chip ? ch / 2 : R) + 6;
  if (s.rowBoxes) {
    const b = s.rowBoxes;
    for (let r = 0; r < s.rows; r++) {
      items.push({ type: "rect", x: -padX, y: r * py - padY + 2, w: W + 2 * padX, h: 2 * padY - 4, rx: 12, cls: "ax thin", enter: "fade", delay: r * 0.12, ...when(b.from, b.until) } as Draft);
    }
  }
  if (s.colBoxes) {
    const b = s.colBoxes;
    for (let c = 0; c < s.cols; c++) {
      items.push({ type: "rect", x: c * px - padX + 3, y: -padY, w: 2 * padX - 6, h: H + 2 * padY, rx: 12, cls: "ax thin", enter: "fade", delay: c * 0.08, ...when(b.from, b.until) } as Draft);
      if (b.text) items.push(t(c * px, H + padY + 14, b.text(c), "sm", { enter: "rise", delay: c * 0.08, ...when(b.from, b.until) }));
    }
  }
  if (s.rowTotals) {
    const b = s.rowTotals;
    for (let r = 0; r < s.rows; r++) {
      items.push(t(W + padX + 12, r * py, b.text(r), `lbl start${b.acc?.(r) ? " acc" : ""}`, { enter: "rise", delay: Math.round(r * 0.25 * 100) / 100, ...when(b.from, b.until) }));
    }
  }
  if (s.rowLabels) {
    const b = s.rowLabels;
    for (let r = 0; r < s.rows; r++) items.push(t(-padX - 10, r * py, b.text(r), "sm end", { enter: "rise", delay: r * 0.1, ...when(b.from, b.until) }));
  }
  const base = H + padY + (s.colBoxes?.text ? 44 : 26);
  // lines never on screen together share a row
  const rowsUsed: { from: number; until: number }[][] = [];
  for (const l of s.lines ?? []) {
    const span = { from: l.from, until: l.until ?? Infinity };
    let k = rowsUsed.findIndex(rw => rw.every(o => span.until < o.from || o.until < span.from));
    if (k < 0) { k = rowsUsed.length; rowsUsed.push([]); }
    rowsUsed[k]!.push(span);
    items.push(t(W / 2, base + k * 28, l.text, l.cls ?? "lbl acc", { enter: "rise", delay: 0.3, ...when(l.from, l.until) }));
  }
  return frame("array", items, s.alt, 14, { w: 540 });
}
