// The general area model: a rectangle cut into rows and columns, as a scene.
// Every use of the current app's areaModel (cell grids, algebra areas, factor rectangles, a triangle as half a rectangle,
// complex FOIL) is one of these, with sizes, labels and beats all computed from the problem by the lesson.
import { PIC, growDown, roomLeft, spreadRows, thinOut } from "../scene/picture-system";
import type { SceneDiagram, SceneItem } from "../scene/schema";
import { r1 } from "../scene/helpers";
import { seatLines } from "./seats";

/** The gap between an area model's parts. An area model is drawn up to 3x (iPad), so 7.5 here shows as the same gap
 * on screen as the 5th grade fraction grids' (PIC.gap.area at their size): one gap across pictures (G 2026-10-14) */
export const AM_GAP = 7.5;

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
  /** draw every seat (or, when seats are too small to see, every block of ten) inside each cell from this beat, at each
      cell's own scale, so a part held wider for its label still shows its seats */
  seats?: number;
  /** the side of the squares `units` draws, in problem units (default 1; 0.1 cuts each unit square 10 by 10) */
  unitStep?: number;
  /** beat whole unit squares appear at as outlines behind everything, covering the rectangle rounded up to whole units */
  wholeOutlines?: number;
  /** lines of text under the picture */
  lines?: PictureLine[];
  /** label rows a builder puts between the picture and its lines (they grow on a phone too, so the lines move past them) */
  linesLead?: number;
  /** extra shapes drawn over the grid, placed with the computed layout */
  extras?: (g: AreaGeometry) => SceneItem[];
  /** beat a plain outline of the whole rectangle appears at. Off unless a lesson needs the edge itself (a perimeter, the
      rectangle a triangle is half of): the coloured cells and grid already show the shape (G, 2026-10-03) */
  outlineFrom?: number | null;
  maxWidth?: number;
  maxHeight?: number;
  /** how far a small box may grow the frame for this picture's text at the phone floor (SceneDiagram; default 1.7 with lines
      of text under it, else 1.5) */
  grow?: number;
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

/**
 * A line of text under a picture is held at the 20px label floor on a phone, so one longer than a phone's picture box
 * holds at that size (about LINE_CHARS characters) is broken in two at its most natural place: after a comma or colon,
 * else before its "=", else before a + or ×; whichever of those leaves the two halves most even.
 */
export const LINE_CHARS = 23;
/** how wide a run of text reads, in characters of an average digit (spaces and signs are narrower than digits) */
const reads = (t: string) => [...t].reduce((a, ch) => a + (ch === " " ? 0.5 : /[.,:;()²³]/.test(ch) ? 0.6 : /[mw]/.test(ch) ? 1.4 : 1), 0) * 0.92;
export function wrapLine(text: string, most = LINE_CHARS): string[] {
  if (reads(text) <= most) return [text];
  const cuts: { at: number; skip: number; rank: number }[] = [];
  for (const m of text.matchAll(/[,:;] /g)) cuts.push({ at: m.index! + 1, skip: 1, rank: 0 });
  for (const m of text.matchAll(/ = /g)) cuts.push({ at: m.index!, skip: 1, rank: 1 });
  for (const m of text.matchAll(/ [+×−] /g)) cuts.push({ at: m.index!, skip: 1, rank: 2 });
  const fits = (c: { at: number; skip: number }) => Math.max(reads(text.slice(0, c.at)), reads(text.slice(c.at + c.skip)));
  const best = cuts.sort((a, b) => (fits(a) <= most ? 0 : 1) - (fits(b) <= most ? 0 : 1) || a.rank - b.rank || fits(a) - fits(b))[0];
  if (!best || fits(best) > reads(text) - 2) return [text];
  return [text.slice(0, best.at), text.slice(best.at + best.skip)];
}

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

/**
 * A number inside a part: the label's size (as the picture's text tokens set it, so a tablet holds it like every other
 * label) while it fits its part, then shrunk to fit, never under the 14px floor on screen.
 */
export const fitPart = (room: number, chars: number): Record<string, string> => ({
  fontSize: `max(calc(14px * var(--px, 0)), min(max(var(--pic-label, 20px), calc(20px * var(--px, 0))), calc((${r1(room)} - 4 * var(--px, 0)) / ${Math.round(chars * 62) / 100} * 1px)))`,
});
/** Each row of lines under the picture sits one line of text (at its size on screen) under the one above it. */
export const lineStep = (rows: number): Record<string, string> =>
  rows > 0 ? { transform: `translateY(calc(${rows} * 1.25 * max(var(--pic-label, 20px), calc(20px * var(--px, 0)))))` } : {};
/** A label's width at the 20px label floor. */
const labelWidth = (s: string) => s.length * PIC.label * 0.62;
/**
 * The picture is drawn at about a phone's picture size (a box 280-310 by 143-187, its labels at the 20px floor), so the
 * labels laid out here land where they are drawn and the parts keep the room that is left; on a tablet the picture grows
 * to its box and its text grows less (SceneDiagram). A lesson's maxWidth / maxHeight set the picture's proportions; the
 * whole picture (labels and lines included) is brought down to PHONE.
 */
const PHONE = { w: 360, h: 210 };
function phoneLayout(spec: AreaGridSpec, lineW: number, lineCount: number): AreaGeometry {
  const maxW = spec.maxWidth ?? 380, maxH = spec.maxHeight ?? 240, minRow = spec.minRow ?? 34;
  let k = 1, lay = layoutAreaGrid(spec);
  for (let n = 0; n < 4; n++) {
    // a row of text under it is a line of text at its size on a phone (lineStep), a little over 26
    const rows = lineCount + (spec.linesLead ?? 0);
    const w = Math.max(lay.left + lay.width + 14, lineW + 24), h = lay.top + lay.height + (rows ? 14 + rows * 30 : 12);
    const f = Math.min(1, PHONE.w / w, PHONE.h / h);
    if (f > 0.97) break;
    k *= f;
    lay = layoutAreaGrid({ ...spec, maxWidth: maxW * k, maxHeight: maxH * k, minRow: Math.min(minRow, Math.max(30, minRow * k)) });
  }
  return lay;
}

/** Where everything goes: one scale for both axes when it fits, larger parts shrinking so small parts can hold their labels. */
export function layoutAreaGrid(spec: AreaGridSpec): AreaGeometry {
  const maxW = spec.maxWidth ?? 380, maxH = spec.maxHeight ?? 240;
  const colSizes = spec.cols.map(c => Math.abs(c.size)), rowSizes = spec.rows.map(r => Math.abs(r.size));
  const sw = colSizes.reduce((a, b) => a + b, 0), sh = rowSizes.reduce((a, b) => a + b, 0);
  const scale = Math.min(maxW / sw, maxH / sh);
  const colMins = spec.cols.map((c, i) => Math.max(30, labelWidth(sideText(c)) + 10, ...spec.rows.map((_, j) => Math.min(labelWidth(cellText(spec.cells[j]?.[i] ?? null)), cellText(spec.cells[j]?.[i] ?? null).length * 0.62 * 14 * 1.4) + 22)));
  const rowMins = spec.rows.map(() => spec.minRow ?? 34);
  const cw = fitParts(colSizes, colMins, maxW, scale), rh = fitParts(rowSizes, rowMins, maxH, scale);
  const left = Math.max(40, ...spec.rows.map(r => labelWidth(sideText(r)) + 22)), top = 34;
  const xs = [left], ys = [top];
  cw.lengths.forEach(w => xs.push(xs[xs.length - 1]! + w));
  rh.lengths.forEach(h => ys.push(ys[ys.length - 1]! + h));
  const toScale = cw.lengths.every((w, i) => Math.abs(w - colSizes[i]! * scale) < 1e-6) && rh.lengths.every((h, i) => Math.abs(h - rowSizes[i]! * scale) < 1e-6);
  return { left, top, width: xs[xs.length - 1]! - left, height: ys[ys.length - 1]! - top, xs, ys, unitX: cw.unit, unitY: rh.unit, toScale };
}

/** The picture: labels on the sides, a coloured cell per product, optional unit squares, lines of text under it. */
export function buildAreaGrid(spec: AreaGridSpec): SceneDiagram & { geometry: AreaGeometry } {
  const items: SceneItem[] = [];
  const lines = (spec.lines ?? []).flatMap(l => wrapLine(l.text).map(text => ({ ...l, text })));
  const lineW = Math.max(0, ...lines.map(l => labelWidth(l.text)));
  const lay = phoneLayout(spec, lineW, lineRows(lines).count);
  // when the text under it is wider, the grid moves to the middle
  const shift = Math.max(0, (lineW + 24 - (lay.left + lay.width + 14)) / 2);
  const g: AreaGeometry = { ...lay, left: lay.left + shift, xs: lay.xs.map(x => x + shift) };
  const { left, top, xs, ys } = g;
  const label = (x: number, y: number, s: AreaSide, cls: string, delay: number): SceneItem =>
    ({ type: "text", x: r1(x), y: r1(y), text: s.label, ...(s.sup ? { sup: s.sup } : {}), cls: `${cls}${s.cls ? ` ${s.cls}` : ""}`, from: s.from ?? 0, enter: "rise", delay });

  // labels one label gap from their part (parts sit half an area gap inside the grid lines)
  const lg = AM_GAP / 2 - PIC.labelGap;
  // top labels stand on their edge, so a label held at its phone floor grows up, away from its part
  // a side cut into many equal pieces with the same label (6 tiles of √2): where the floor grows them into each other,
  // every other one fades: the top's first always showing, the side's last, so the two never meet at the corner
  const thin = (sides: AreaSide[], edges: number[], i: number, chars: number, fromEnd = false) => {
    const same = sides.length > 2 && sides.every(o => sideText(o) === sideText(sides[0]!));
    const at = fromEnd ? sides.length - 1 - i : i;
    if (!same || at === 0) return {};
    const level = at & -at;
    return { vars: thinOut(roomLeft(Math.min(...sides.map((_, k) => edges[k + 1]! - edges[k]!)) * level, chars, PIC.label, PIC.label)) };
  };
  spec.cols.forEach((c, i) => items.push({ ...label((xs[i]! + xs[i + 1]!) / 2, top + lg + 2, c, "lbl up", 0.1 + i * 0.15), ...thin(spec.cols, xs, i, sideText(c).length) }));
  // a row's height holds a label about 2 characters wide
  // different labels on rows thinner than a label at its floor spread apart (2 and +3i beside a short row), so they never touch
  const rowsSame = spec.rows.length > 2 && spec.rows.every(o => sideText(o) === sideText(spec.rows[0]!));
  const pitch = Math.min(...spec.rows.map((_, j) => ys[j + 1]! - ys[j]!));
  const spread = (j: number) => (!rowsSame && spec.rows.filter(r => sideText(r)).length > 1 ? { vars: spreadRows(j, spec.rows.length, pitch) } : {});
  spec.rows.forEach((r, j) => items.push({ ...label(left + lg, (ys[j]! + ys[j + 1]!) / 2, r, "lbl end", 0.1 + j * 0.15), ...thin(spec.rows, ys, j, 2, true), ...spread(j) }));

  // whole unit squares behind everything, when the sides are not whole (a strip of tenths laid on whole squares)
  const wholeCols = Math.ceil(spec.cols.reduce((a, c) => a + Math.abs(c.size), 0) - 1e-9), wholeRows = Math.ceil(spec.rows.reduce((a, r) => a + Math.abs(r.size), 0) - 1e-9);
  if (spec.wholeOutlines != null && g.toScale) {
    for (let r = 0; r < wholeRows; r++) for (let k = 0; k < wholeCols; k++) {
      items.push({ type: "rect", x: r1(left + k * g.unitX), y: r1(top + r * g.unitY), w: r1(g.unitX), h: r1(g.unitY), cls: "ax", from: spec.wholeOutlines, enter: "fade" });
    }
  }

  // parts one gap apart, each cell half a gap inside its column and row
  const IN = AM_GAP / 2;
  // cells
  spec.cells.forEach((row, j) => row.forEach((c, i) => {
    if (!c) return;
    const w = xs[i + 1]! - xs[i]!, h = ys[j + 1]! - ys[j]!;
    // until its turn, each part waits as a faint empty box, so the picture opens on the whole rectangle to fill
    // rather than on labels floating over nothing (Review v39 item 1)
    if ((c.from ?? 0) > 0) items.push({ type: "rect", x: r1(xs[i]! + IN), y: r1(ys[j]! + IN), w: r1(w - 2 * IN), h: r1(h - 2 * IN), rx: r1(Math.min(PIC.corner.part, w / 4, h / 4)), cls: "pend", from: 0, until: c.from! - 1, enter: "fade" });
    items.push({ type: "rect", x: r1(xs[i]! + IN), y: r1(ys[j]! + IN), w: r1(w - 2 * IN), h: r1(h - 2 * IN), rx: r1(Math.min(PIC.corner.part, w / 4, h / 4)), cls: `cell c${c.color ?? (i + j) % 3}`, from: c.from ?? 0, enter: "pop", delay: 0.1 });
  }));

  // which cell the beat is about: the step's part takes the 60% fill for that beat (style guide), under its seats and text
  spec.cells.forEach((row, j) => row.forEach((c, i) => {
    const w = xs[i + 1]! - xs[i]!, h = ys[j + 1]! - ys[j]!;
    for (const b of c?.focus ?? []) {
      items.push({ type: "rect", x: r1(xs[i]! + IN), y: r1(ys[j]! + IN), w: r1(w - 2 * IN), h: r1(h - 2 * IN), rx: r1(Math.min(PIC.corner.part, w / 4, h / 4)), cls: "cell focus", from: b, until: b, enter: "fade" });
    }
  }));

  // unit squares, when the picture is to scale and each square is big enough to see
  const step = spec.unitStep ?? 1, steps = (v: number) => Math.round(Math.abs(v) / step);
  const whole = [...spec.cols, ...spec.rows].every(s => Math.abs(Math.abs(s.size) / step - steps(s.size)) < 1e-6);
  // whole unit squares need 6 units to be seen; a finer cut is drawn as lines down to 3 units apart
  if (spec.units != null && whole && g.toScale && g.unitX * step >= (step < 1 ? 3 : 6)) {
    spec.cells.forEach((row, j) => row.forEach((c, i) => {
      if (!c) return;
      const from = Math.max(spec.units!, c.from ?? 0);
      for (let k = 1; k < steps(spec.cols[i]!.size); k++) {
        const x = r1(xs[i]! + k * step * g.unitX);
        items.push({ type: "line", x1: x, y1: r1(ys[j]! + IN), x2: x, y2: r1(ys[j + 1]! - IN), cls: "grid", from, enter: "fade", delay: 0.3 });
      }
      for (let k = 1; k < steps(spec.rows[j]!.size); k++) {
        const y = r1(ys[j]! + k * step * g.unitY);
        items.push({ type: "line", x1: r1(xs[i]! + IN), y1: y, x2: r1(xs[i + 1]! - IN), y2: y, cls: "grid", from, enter: "fade", delay: 0.3 });
      }
    }));
  }
  if (spec.seats != null) spec.cells.forEach((row, j) => row.forEach((c, i) => {
    if (!c) return;
    const from = Math.max(spec.seats!, c.from ?? 0);
    for (const l of seatLines(xs[i]! + IN, ys[j]! + IN, xs[i + 1]! - xs[i]! - 2 * IN, ys[j + 1]! - ys[j]! - 2 * IN, Math.abs(spec.cols[i]!.size), Math.abs(spec.rows[j]!.size))) {
      items.push({ type: "line", x1: l.x1, y1: l.y1, x2: l.x2, y2: l.y2, cls: l.ten ? "seat ten" : "seat", from, enter: "fade", delay: 0.2 });
    }
  }));
  if (spec.outlineFrom != null) items.push({ type: "rect", x: r1(left), y: r1(top), w: r1(g.width), h: r1(g.height), cls: "ax thin", from: spec.outlineFrom, enter: "fade" });


  items.push(...(spec.extras?.(g) ?? []));

  // cell texts last, so nothing covers them
  const cellTexts = spec.cells.flat().filter(c => c?.text).map(c => cellText(c));
  const repeated = cellTexts.length > 4 && cellTexts.every(t => t === cellTexts[0]);
  spec.cells.forEach((row, j) => row.forEach((c, i) => {
    if (!c?.text) return;
    // held at the label floor while it fits its part, then shrunk to fit it (never under 14px on screen)
    const chars = c.text.length + (c.sup ? 0.6 * c.sup.length : 0);
    const room = Math.min(xs[i + 1]! - xs[i]! - 2 * IN - 4, ((ys[j + 1]! - ys[j]! - 2 * IN) / 1.2) * chars * 0.62);
    // the same number in many small tiles (6 × 6 tiles of 2) shows only while it fits its tile at the floor (the lines
    // under the picture say it too)
    const fade = repeated ? thinOut(roomLeft(xs[i + 1]! - xs[i]! - 2 * IN, chars, 0), roomLeft(ys[j + 1]! - ys[j]! - 2 * IN, 1.94, 0)) : {};
    items.push({ type: "text", x: r1((xs[i]! + xs[i + 1]!) / 2), y: r1((ys[j]! + ys[j + 1]!) / 2), text: c.text, ...(c.sup ? { sup: c.sup } : {}), cls: "lbl res onmid", from: Math.max(c.from ?? 0, c.textFrom ?? 0), enter: "rise", delay: 0.3, vars: { ...fitPart(room, chars), ...fade } });
  }));

  const outlineW = spec.wholeOutlines != null && g.toScale ? wholeCols * g.unitX : g.width;
  const width = Math.max(left + Math.max(g.width, outlineW) + 14, lineW + 24);
  const cx = Math.min(Math.max(left + g.width / 2, lineW / 2 + 12), width - lineW / 2 - 12);
  const { rowOf, count } = lineRows(lines);
  // each line hangs from its top edge and moves down by what the rows above it grew on a phone (growDown)
  // (and by what the last row's label grows below its row's middle, or what spreading rows moved it)
  const lead = (spec.linesLead ?? 0) + 0.5;
  // (rows past the first: one line of text each at its size on screen, so a line broken in two reads as one at any size)
  lines.forEach((l, k) => {
    const lift = lead ? growDown(lead).transform! : "", step = lineStep(rowOf[k]!).transform ?? "";
    const transform = [lift, step].filter(Boolean).join(" ");
    items.push({ type: "text", x: r1(cx), y: r1(top + g.height + 16), text: l.text, cls: `${l.cls ?? "lbl acc"} down cap`, from: l.from, ...(l.until != null ? { until: l.until } : {}), enter: "rise", ...(transform ? { vars: { transform } } : {}) });
  });

  return {
    kind: "scene", family: spec.family ?? "area-model", ...(spec.grow || lines.length ? { grow: spec.grow ?? 1.7 } : {}),
    width: r1(width), height: r1(top + g.height + (count ? 14 + count * 26 : 12)),
    items, alt: spec.alt, geometry: g,
  };
}
