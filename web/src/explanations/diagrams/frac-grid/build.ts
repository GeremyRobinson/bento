// A fraction of a fraction (the current app's fracGrid): a whole cut into rows × cols squares,
// the first r rows shaded for one fraction, the first c columns for the other; the overlap is the product.
import type { SceneDiagram, SceneItem } from "../scene/schema";
import { r1 } from "../scene/helpers";
import { lineRows, type PictureLine } from "../area-model/grid";

export interface FracGridSpec {
  /** the whole is rows × cols squares */
  rows: number;
  cols: number;
  /** shaded rows (top fraction r/rows) and shaded columns (c/cols) */
  r: number;
  c: number;
  /** beats: the empty grid, the rows, the columns, the overlap */
  beats: { grid: number; rows: number; cols: number; both: number };
  /** labels for the shaded rows and columns, e.g. "2/3" */
  rowLabel: string;
  colLabel: string;
  /** lines under the grid, e.g. "6 of 12 squares" at the overlap beat; lines never shown together share a row */
  notes?: PictureLine[];
  alt: string;
}

export interface FracGridGeometry { left: number; top: number; cell: number }

export function fracGridGeometry(spec: Pick<FracGridSpec, "rows" | "cols">): FracGridGeometry {
  const cell = Math.min(46, 320 / spec.cols, 260 / spec.rows);
  return { left: 64, top: 34, cell };
}

export function buildFracGrid(spec: FracGridSpec): SceneDiagram {
  const { rows, cols, r, c, beats } = spec;
  if (r > rows || c > cols || r < 0 || c < 0) throw new Error("frac grid: shaded part bigger than the whole");
  const { left, top, cell } = fracGridGeometry(spec);
  const items: SceneItem[] = [];
  const box = (i: number, j: number, inset: number) => ({ x: r1(left + j * cell + inset), y: r1(top + i * cell + inset), w: r1(cell - 2 * inset), h: r1(cell - 2 * inset) });
  for (let i = 0; i < rows; i++) for (let j = 0; j < cols; j++) items.push({ type: "rect", ...box(i, j, 2), rx: 6, cls: "seg", from: beats.grid, enter: "fade", delay: (i * cols + j) * 0.01 });
  for (let i = 0; i < r; i++) for (let j = 0; j < cols; j++) items.push({ type: "rect", ...box(i, j, 2), rx: 6, cls: "shadeA", from: beats.rows, enter: "fade", delay: 0.2 + i * 0.15 });
  for (let j = 0; j < c; j++) for (let i = 0; i < rows; i++) items.push({ type: "rect", ...box(i, j, 2), rx: 6, cls: "shadeA p1", from: beats.cols, enter: "fade", delay: 0.2 + j * 0.15 });
  for (let i = 0; i < r; i++) for (let j = 0; j < c; j++) items.push({ type: "rect", ...box(i, j, 6), rx: 4, cls: "both pq", from: beats.both, enter: "pop", delay: 0.2 + (i * c + j) * 0.06 });
  // roles (handoff-6): the first fraction (rows) blue, the second (columns) orange, the overlap being found amber
  // brackets along the shaded rows (left) and the shaded columns (top), with their fractions
  if (r > 0) {
    const y0 = top + 2, y1 = top + r * cell - 2, x = left - 10;
    items.push({ type: "path", d: `M${r1(x + 6)} ${r1(y0)} H${r1(x)} V${r1(y1)} H${r1(x + 6)}`, cls: "ln", from: beats.rows, enter: "draw" });
    items.push({ type: "text", x: r1(x - 8), y: r1((y0 + y1) / 2), text: spec.rowLabel, cls: "lbl end", from: beats.rows, enter: "rise", delay: 0.3 });
  }
  if (c > 0) {
    const x0 = left + 2, x1 = left + c * cell - 2, y = top - 10;
    items.push({ type: "path", d: `M${r1(x0)} ${r1(y + 6)} V${r1(y)} H${r1(x1)} V${r1(y + 6)}`, cls: "ln p1", from: beats.cols, enter: "draw" });
    items.push({ type: "text", x: r1((x0 + x1) / 2), y: r1(y - 12), text: spec.colLabel, cls: "lbl p1", from: beats.cols, enter: "rise", delay: 0.3 });
  }
  const gridH = rows * cell, notes = spec.notes ?? [];
  const noteW = Math.max(0, ...notes.map(n => n.text.length * 10.2));
  const width = Math.max(left + cols * cell + 20, noteW + 24);
  const { rowOf, count } = lineRows(notes);
  const cx = Math.min(Math.max(left + (cols * cell) / 2, noteW / 2 + 12), width - noteW / 2 - 12);
  notes.forEach((n, k) => items.push({ type: "text", x: r1(cx), y: r1(top + gridH + 24 + rowOf[k]! * 26), text: n.text, cls: n.cls ?? "lbl", from: n.from, ...(n.until != null ? { until: n.until } : {}), enter: "rise", delay: 0.4 }));
  return {
    kind: "scene", family: "frac-grid",
    width: r1(width),
    height: r1(top + gridH + (count ? 12 + count * 26 : 16)),
    items, alt: spec.alt,
  };
}
