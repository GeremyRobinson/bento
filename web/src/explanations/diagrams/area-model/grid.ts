// The general area model: a rectangle cut into rows and columns, as a scene.
// Every use of the current app's areaModel (cell grids, algebra areas, factor rectangles, a triangle as half a rectangle,
// complex FOIL) is one of these, with sizes, labels and beats all computed from the problem by the lesson.
import type { SceneDiagram, SceneItem } from "../scene/schema";
import { r1 } from "../scene/helpers";

/** One side piece: its label and its length in problem units. */
export interface AreaSide {
  label: string;
  /** superscript after the label, e.g. "2" in x² */
  sup?: string;
  /** length in problem units (absolute value; a negative part is drawn by its size) */
  size: number;
  /** beat the label appears at */
  from?: number;
  /** extra text class, e.g. "acc" */
  cls?: string;
}

/** One cell: what it holds and when it shows. */
export interface AreaCell {
  text?: string;
  sup?: string;
  /** beat the cell appears at */
  from?: number;
  /** beat its text appears at, when later than the cell */
  textFrom?: number;
  /** cell colour 0–2; defaults to the current app's (row + column) % 3 */
  color?: number;
  /** beats at which the cell is outlined as the one being talked about */
  focus?: number[];
}

export interface AreaGridSpec {
  family?: string;
  cols: AreaSide[];
  rows: AreaSide[];
  /** cells[row][col]; null leaves that spot empty (e.g. a term with no partner) */
  cells: (AreaCell | null)[][];
  /** draw the unit squares from this beat (only when every side is a whole number and squares stay big enough) */
  units?: number;
  /** lines of text under the picture */
  lines?: PictureLine[];
  /** extra shapes drawn over the grid, placed with the computed layout */
  extras?: (g: AreaGeometry) => SceneItem[];
  /** beat a plain outline of the whole rectangle appears at. Off unless a lesson needs the edge itself (a perimeter, the
      rectangle a triangle is half of): the coloured cells and grid already show the shape (G, 2026-10-03) */
  outlineFrom?: number | null;
  maxWidth?: number;
  maxHeight?: number;
  /** smallest row height, for strips far longer than they are tall (default 34) */
  minRow?: number;
  alt: string;
}

export interface AreaGeometry {
  left: number;
  top: number;
  width: number;
  height: number;
  /** column edges and row edges, in SVG units */
  xs: number[];
  ys: number[];
  /** SVG units per problem unit along each axis; equal when the picture is to scale */
  unitX: number;
  unitY: number;
  /** true when every column and row is drawn at the same scale */
  toScale: boolean;
}

/** A line of text under a picture, shown from one beat (until another). */
export interface PictureLine { text: string; from: number; until?: number; cls?: string }

/** Puts lines that are never on screen together in the same row; returns each line's row and how many rows there are. */
export function lineRows(lines: PictureLine[]): { rowOf: number[]; count: number } {
  const rows: { from: number; until: number }[][] = [], rowOf: number[] = [];
  for (const l of lines) {
    const span = { from: l.from, until: l.until ?? Infinity };
    let row = rows.findIndex(r => r.every(o => span.until < o.from || o.until < span.from));
    if (row < 0) { row = rows.length; rows.push([]); }
    rows[row]!.push(span);
    rowOf.push(row);
  }
  return { rowOf, count: rows.length };
}

const FONT = 17;
/** Rough width of a label in the app's number font. */
export const textWidth = (s: string, size = FONT) => s.length * size * 0.6;
const sideText = (s: AreaSide) => s.label + (s.sup ?? "");
const cellText = (c: AreaCell | null) => (c?.text ?? "") + (c?.sup ?? "");

/**
 * Splits `max` units of room among parts in proportion to their sizes, but never below each part's minimum.
 * Returns the lengths and the scale used for the parts that were not held at their minimum.
 */
export function fitParts(sizes: number[], mins: number[], max: number, scale: number): { lengths: number[]; unit: number } {
  let unit = scale, held = sizes.map(() => false);
  for (let k = 0; k <= sizes.length; k++) {
    const next = sizes.map((s, i) => held[i]! || s * unit < mins[i]! - 1e-9);
    const minsTotal = mins.reduce((a, m, i) => a + (next[i] ? m : 0), 0);
    const free = sizes.reduce((a, s, i) => a + (next[i] ? 0 : s), 0);
    unit = free > 0 ? Math.min(scale, Math.max(0, (max - minsTotal) / free)) : scale;
    const stable = next.every((h, i) => h === held[i]);
    held = next;
    if (stable) break;
  }
  return { lengths: sizes.map((s, i) => (held[i] ? mins[i]! : s * unit)), unit };
}

/** Where everything goes: one scale for both axes when it fits, larger parts shrinking so small parts can hold their labels. */
export function layoutAreaGrid(spec: AreaGridSpec): AreaGeometry {
  const maxW = spec.maxWidth ?? 380, maxH = spec.maxHeight ?? 240;
  const colSizes = spec.cols.map(c => Math.abs(c.size)), rowSizes = spec.rows.map(r => Math.abs(r.size));
  const sw = colSizes.reduce((a, b) => a + b, 0), sh = rowSizes.reduce((a, b) => a + b, 0);
  const scale = Math.min(maxW / sw, maxH / sh);
  const colMins = spec.cols.map((c, i) => Math.max(30, textWidth(sideText(c)) + 10, ...spec.rows.map((_, j) => textWidth(cellText(spec.cells[j]?.[i] ?? null)) + 22)));
  const rowMins = spec.rows.map(() => spec.minRow ?? 34);
  const cw = fitParts(colSizes, colMins, maxW, scale), rh = fitParts(rowSizes, rowMins, maxH, scale);
  const left = Math.max(40, ...spec.rows.map(r => textWidth(sideText(r)) + 22)), top = 34;
  const xs = [left], ys = [top];
  cw.lengths.forEach(w => xs.push(xs[xs.length - 1]! + w));
  rh.lengths.forEach(h => ys.push(ys[ys.length - 1]! + h));
  const toScale = cw.lengths.every((w, i) => Math.abs(w - colSizes[i]! * scale) < 1e-6) && rh.lengths.every((h, i) => Math.abs(h - rowSizes[i]! * scale) < 1e-6);
  return { left, top, width: xs[xs.length - 1]! - left, height: ys[ys.length - 1]! - top, xs, ys, unitX: cw.unit, unitY: rh.unit, toScale };
}

/** The picture: labels on the sides, a coloured cell per product, optional unit squares, lines of text under it. */
export function buildAreaGrid(spec: AreaGridSpec): SceneDiagram & { geometry: AreaGeometry } {
  const lay = layoutAreaGrid(spec), items: SceneItem[] = [];
  const lines = spec.lines ?? [];
  const lineW = Math.max(0, ...lines.map(l => textWidth(l.text)));
  // when the text under it is wider, the grid moves to the middle
  const shift = Math.max(0, (lineW + 24 - (lay.left + lay.width + 14)) / 2);
  const g: AreaGeometry = { ...lay, left: lay.left + shift, xs: lay.xs.map(x => x + shift) };
  const { left, top, xs, ys } = g;
  const label = (x: number, y: number, s: AreaSide, cls: string, delay: number): SceneItem =>
    ({ type: "text", x: r1(x), y: r1(y), text: s.label, ...(s.sup ? { sup: s.sup } : {}), cls: `${cls}${s.cls ? ` ${s.cls}` : ""}`, from: s.from ?? 0, enter: "rise", delay });

  spec.cols.forEach((c, i) => items.push(label((xs[i]! + xs[i + 1]!) / 2, top - 16, c, "lbl", 0.1 + i * 0.15)));
  spec.rows.forEach((r, j) => items.push(label(left - 12, (ys[j]! + ys[j + 1]!) / 2, r, "lbl end", 0.1 + j * 0.15)));

  // cells
  spec.cells.forEach((row, j) => row.forEach((c, i) => {
    if (!c) return;
    const w = xs[i + 1]! - xs[i]!, h = ys[j + 1]! - ys[j]!;
    items.push({ type: "rect", x: r1(xs[i]! + 2), y: r1(ys[j]! + 2), w: r1(w - 4), h: r1(h - 4), rx: r1(Math.min(8, w / 4, h / 4)), cls: `cell c${c.color ?? (i + j) % 3}`, from: c.from ?? 0, enter: "pop", delay: 0.1 });
  }));

  // unit squares, when the picture is to scale and each square is big enough to see
  const whole = [...spec.cols, ...spec.rows].every(s => Number.isInteger(s.size));
  if (spec.units != null && whole && g.toScale && g.unitX >= 6) {
    spec.cells.forEach((row, j) => row.forEach((c, i) => {
      if (!c) return;
      const from = Math.max(spec.units!, c.from ?? 0);
      for (let k = 1; k < Math.abs(spec.cols[i]!.size); k++) {
        const x = r1(xs[i]! + k * g.unitX);
        items.push({ type: "line", x1: x, y1: r1(ys[j]! + 2), x2: x, y2: r1(ys[j + 1]! - 2), cls: "grid", from, enter: "fade", delay: 0.3 });
      }
      for (let k = 1; k < Math.abs(spec.rows[j]!.size); k++) {
        const y = r1(ys[j]! + k * g.unitY);
        items.push({ type: "line", x1: r1(xs[i]! + 2), y1: y, x2: r1(xs[i + 1]! - 2), y2: y, cls: "grid", from, enter: "fade", delay: 0.3 });
      }
    }));
  }
  if (spec.outlineFrom != null) items.push({ type: "rect", x: r1(left), y: r1(top), w: r1(g.width), h: r1(g.height), cls: "ax thin", from: spec.outlineFrom, enter: "fade" });

  // which cell the beat is about
  spec.cells.forEach((row, j) => row.forEach((c, i) => {
    for (const b of c?.focus ?? []) {
      items.push({ type: "rect", x: r1(xs[i]! + 7), y: r1(ys[j]! + 7), w: r1(xs[i + 1]! - xs[i]! - 14), h: r1(ys[j + 1]! - ys[j]! - 14), rx: 4, cls: "hlline", from: b, until: b, enter: "fade" });
    }
  }));

  items.push(...(spec.extras?.(g) ?? []));

  // cell texts last, so nothing covers them
  spec.cells.forEach((row, j) => row.forEach((c, i) => {
    if (!c?.text) return;
    items.push({ type: "text", x: r1((xs[i]! + xs[i + 1]!) / 2), y: r1((ys[j]! + ys[j + 1]!) / 2), text: c.text, ...(c.sup ? { sup: c.sup } : {}), cls: "lbl", from: Math.max(c.from ?? 0, c.textFrom ?? 0), enter: "rise", delay: 0.3 });
  }));

  const width = Math.max(left + g.width + 14, lineW + 24);
  const cx = Math.min(Math.max(left + g.width / 2, lineW / 2 + 12), width - lineW / 2 - 12);
  const { rowOf, count } = lineRows(lines);
  lines.forEach((l, k) => items.push({ type: "text", x: r1(cx), y: r1(top + g.height + 28 + rowOf[k]! * 26), text: l.text, cls: l.cls ?? "lbl acc", from: l.from, ...(l.until != null ? { until: l.until } : {}), enter: "rise" }));

  return {
    kind: "scene", family: spec.family ?? "area-model",
    width: r1(width), height: r1(top + g.height + (count ? 14 + count * 26 : 12)),
    items, alt: spec.alt, geometry: g,
  };
}
