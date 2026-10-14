// A fraction of a fraction (the current app's fracGrid): a whole cut into rows × cols squares,
// the first r rows shaded for one fraction, the first c columns for the other; the overlap is the product.
import type { SceneDiagram, SceneItem } from "../scene/schema";
import { r1 } from "../scene/helpers";
import { lineRows, type PictureLine } from "../area-model/grid";
import { PIC, growDown } from "../scene/picture-system";
import { litRuns } from "../tape/build";
import type { Beats } from "../tape/schema";

export interface FracGridSpec {
  /** the whole is rows × cols squares */
  rows: number;
  cols: number;
  /** shaded rows (top fraction r/rows) and shaded columns (c/cols) */
  r: number;
  c: number;
  /** beats: the empty grid, the rows, the columns, the overlap. Beats may be the same: then they build one after
   *  another inside that beat (a practice picture shows both fractions before the first step) */
  beats: { grid: number; rows: number; cols: number; both: number;
    /** the overlap squares counted, a number popping into each one after another */
    count?: number };
  /** the beats the shaded rows, the shaded columns and the overlap are the step's part (picture system `lit`) */
  lit?: { rows?: Beats[]; cols?: Beats[]; both?: Beats[] };
  /** labels for the shaded rows and columns, e.g. "2/3" */
  rowLabel: string;
  colLabel: string;
  /** lines under the grid, e.g. "6 of 12 squares" at the overlap beat; lines never shown together share a row */
  notes?: PictureLine[];
  alt: string;
}

export interface FracGridGeometry { left: number; top: number; cell: number }

export function fracGridGeometry(spec: Pick<FracGridSpec, "rows" | "cols">): FracGridGeometry {
  // big enough to be the hero on an iPad (Review #11): a 2 by 2 grid drew at under a third of its panel
  const cell = Math.min(72, 320 / spec.cols, 260 / spec.rows);
  return { left: 64, top: 44, cell };
}

export function buildFracGrid(spec: FracGridSpec): SceneDiagram {
  const { rows, cols, r, c, beats } = spec;
  if (r > rows || c > cols || r < 0 || c < 0) throw new Error("frac grid: shaded part bigger than the whole");
  const { left, top, cell } = fracGridGeometry(spec);
  const items: SceneItem[] = [];
  const lit = spec.lit ?? {};
  const box = (i: number, j: number, inset: number) => ({ x: r1(left + j * cell + inset), y: r1(top + i * cell + inset), w: r1(cell - 2 * inset), h: r1(cell - 2 * inset) });
  // each square is its own part, one area-model gap apart (picture system)
  const g = PIC.gap.area / 2, rx = PIC.corner.part;
  // shading that shares a beat with what comes before it waits its turn, so the rows, then the columns, then the
  // overlap build in front of the child
  const rowsAt = beats.rows === beats.grid ? 0.2 : 0;
  const colsAt = beats.cols === beats.rows ? rowsAt + 0.2 + r * 0.08 : beats.cols === beats.grid ? 0.2 : 0;
  const bothAt = beats.both === beats.cols ? colsAt + 0.2 + c * 0.08 : 0;
  for (let i = 0; i < rows; i++) for (let j = 0; j < cols; j++) items.push({ type: "rect", ...box(i, j, g), rx, cls: "seg", from: beats.grid, enter: "fade", delay: (i * cols + j) * 0.01 });
  // rows only: the first fraction's colour; columns only: the second's; shaded twice: ONE darker colour of the grade
  // family (its deep), so the overlap squares stand out to be counted
  for (let i = 0; i < r; i++) for (let j = 0; j < cols; j++) items.push(...litRuns({ type: "rect", ...box(i, j, g), rx, cls: "shadeA", from: beats.rows, enter: "fade", delay: r1(rowsAt + 0.1 + i * 0.08) }, lit.rows));
  for (let j = 0; j < c; j++) for (let i = 0; i < rows; i++) items.push(...litRuns({ type: "rect", ...box(i, j, g), rx, cls: "shadeA p1", from: beats.cols, enter: "fade", delay: r1(colsAt + 0.1 + j * 0.08) }, lit.cols));
  for (let i = 0; i < r; i++) for (let j = 0; j < c; j++) {
    items.push(...litRuns({ type: "rect", ...box(i, j, g), rx, cls: "shadeA lap", vars: { "--tint": "var(--pic-deep)", "--deep": "var(--pic-deep)" }, from: beats.both, enter: "fade", delay: r1(bothAt + 0.1 + (i * c + j) * Math.min(0.04, 0.4 / (r * c))) }, lit.both));
  }
  // counted: 1, 2, 3 ... in the overlap squares, row by row, in the card colour on the deep squares
  const nums = String(r * c).length, fits = cell - 2 * g >= nums * PIC.label * 0.62 + 6;
  if (beats.count != null && fits) {
    const tick = Math.min(0.2, 1.4 / Math.max(1, r * c));
    for (let i = 0; i < r; i++) for (let j = 0; j < c; j++) {
      const b = box(i, j, g);
      items.push({ type: "text", x: r1(b.x + b.w / 2), y: r1(b.y + b.h / 2), text: String(i * c + j + 1), cls: "lbl lit", vars: { "--deep": "var(--v-card)" }, from: beats.count, enter: "rise", delay: r1((i * c + j) * tick) });
    }
  }
  // roles (handoff-6): the first fraction (rows) blue, the second (columns) orange, the overlap being found amber
  // brackets along the shaded rows (left) and the shaded columns (top), with their fractions
  if (r > 0) {
    const y0 = top + 2, y1 = top + r * cell - 2, x = left - 10;
    items.push({ type: "path", d: `M${r1(x + 6)} ${r1(y0)} H${r1(x)} V${r1(y1)} H${r1(x + 6)}`, cls: "ln", from: beats.rows, enter: "draw", delay: rowsAt });
    items.push(...litRuns({ type: "text", x: r1(x - PIC.labelGap), y: r1((y0 + y1) / 2), text: spec.rowLabel, cls: "lbl end", from: beats.rows, enter: "rise", delay: r1(rowsAt + 0.3) }, lit.rows));
  }
  if (c > 0) {
    const x0 = left + 2, x1 = left + c * cell - 2, y = top - 10;
    items.push({ type: "path", d: `M${r1(x0)} ${r1(y + 6)} V${r1(y)} H${r1(x1)} V${r1(y + 6)}`, cls: "ln p1", from: beats.cols, enter: "draw", delay: r1(colsAt) });
    items.push(...litRuns({ type: "text", x: r1((x0 + x1) / 2), y: r1(y - PIC.labelGap - PIC.label / 2), text: spec.colLabel, cls: "lbl p1", from: beats.cols, enter: "rise", delay: r1(colsAt + 0.3) }, lit.cols));
  }
  const gridH = rows * cell, notes = spec.notes ?? [];
  const noteW = Math.max(0, ...notes.map(n => n.text.length * 10.2));
  const width = Math.max(left + cols * cell + 20, noteW + 24);
  const { rowOf, count } = lineRows(notes);
  const cx = Math.min(Math.max(left + (cols * cell) / 2, noteW / 2 + 12), width - noteW / 2 - 12);
  // notes hang from their top edge and move down by what the rows above them grew on a phone; they are captions (.cap),
  // which practice leaves out (the work list shows each worked line)
  notes.forEach((n, k) => items.push({ type: "text", x: r1(cx), y: r1(top + gridH + 12 + rowOf[k]! * 26), text: n.text, cls: `${n.cls ?? "lbl"} down cap`, from: n.from, ...(n.until != null ? { until: n.until } : {}), enter: "rise", delay: 0.4, vars: growDown(1 + rowOf[k]!) }));
  return {
    kind: "scene", family: "frac-grid",
    width: r1(width),
    height: r1(top + gridH + (count ? 12 + count * 26 : 16)),
    items, alt: spec.alt,
    // two fractions must be told apart, and their overlap is the answer
    two: true,
  };
}
