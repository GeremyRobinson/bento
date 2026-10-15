// Tape diagrams and fraction bars: from a lesson's TapeSpec (computed from its problem) to a scene of shapes.
// One scale for every row, so bar lengths stay in proportion; text sizes, columns and row heights are worked out
// from the labels so nothing runs off the canvas or overlaps.
import type { SceneDiagram, SceneItem } from "../scene/schema";
import { r1 } from "../scene/helpers";
import type { Beats, TapeRow, TapeSpec, TapeText } from "./schema";
import { PIC, SQUARE, MASTERS, cells, fitIn, roomLeft, spreadRows, thinOut } from "../scene/picture-system";

const M = 10; // outer margin
const BRACKET = 28; // room for a bracket and its text
const OVER = 30; // tall layout: the line over a bar that holds its label and total
/** tall layout: the finished picture aims to be this tall for its width (a square box), and a bar is at most this thick */
const SQUARE_AIM = 0.9, TALL_MAX = 140;
// labels and totals at the picture system's label size; text in a part as big as fits (FS.each), else small (FS.small)
const FS = { label: PIC.label, total: PIC.label, each: PIC.label, small: 12, bracket: 15 };
/** the gap between pieces, and between rows, for a spec */
export const tapeGap = (spec: TapeSpec) => (spec.gap === "mixed" ? PIC.gap.mixed : PIC.gap.bar);
const EPS = 1e-9;
/** what small part text (12 units) grows to on a phone, where the 14px floor holds and a 480-unit picture is ~350px wide */
const SMALL_ON_PHONE = 19;
/** narrowest a shaded piece is drawn, in px */
const MIN_FILL = 9;

/**
 * One shape split at the beats it is lit (the step is about it): those runs wear the picture's `lit` role (picture
 * system: a part goes soft to mid with a deeper outline, a label muted to deep). Only the first run plays the shape's
 * entrance; the others take over in place. Shared by every scene family that lights its worked step.
 */
export function litRuns(it: SceneItem, lit: Beats[] | undefined): SceneItem[] {
  if (!lit?.length) return [it];
  const f = it.from ?? 0, u = it.until;
  const cuts = new Set<number>([f]);
  for (const b of lit) {
    if (b.from > f && (u == null || b.from <= u)) cuts.add(b.from);
    if (b.until != null && b.until + 1 > f && (u == null || b.until + 1 <= u)) cuts.add(b.until + 1);
  }
  const starts = [...cuts].sort((a, b) => a - b);
  const on = (beat: number) => lit.some(b => b.from <= beat && (b.until == null || beat <= b.until));
  return starts.map((s0, k) => {
    const end = k + 1 < starts.length ? starts[k + 1]! - 1 : u;
    const { enter: _e, delay: _d, ...rest } = it;
    const base = k === 0 ? it : rest;
    return { ...base, from: s0, ...(end != null ? { until: end } : {}), cls: on(s0) ? `${it.cls ?? ""} lit`.trim() : it.cls } as SceneItem;
  });
}

/** Rough width of text in the picture fonts. */
export const textWidth = (s: string, size: number) => s.length * size * 0.62;
const FRAC = /^(\d+|\?|x)\/(\d+)$/;
/** a mixed number on one line keeps a clear gap between its whole and its fraction: SVG draws a plain space so thin
 * that "1 1/6" read as "11/6" (Review g5 re-walk). An en space never collapses. */
const mixedGap = (text: string) => text.replace(/(\d) (?=\d+\/\d+$)/, "$1\u2002");

type Layer = { count: number; from: number; until?: number; delay?: number };

/** The cuts of a row as layers, each shown from its beat until the next cut starts. */
export function layersOf(row: TapeRow): Layer[] {
  const from0 = row.from ?? 0;
  const list = typeof row.parts === "number" ? [{ count: row.parts, from: from0 }] : [...row.parts].sort((a, b) => a.from - b.from);
  return list.map((l, i) => {
    const next = list[i + 1];
    const until = next ? next.from - 1 : row.until;
    return { count: l.count, from: Math.max(l.from, from0), ...(until != null ? { until } : {}), ...("delay" in l && l.delay ? { delay: l.delay } : {}) };
  });
}
const layerAt = (layers: Layer[], beat: number) => [...layers].reverse().find(l => l.from <= beat) ?? layers[0]!;

/** What a run of beats [from, until] looks like: shown if it overlaps the row's own run. */
const within = (from: number, until: number | undefined, row: TapeRow) => {
  const f = Math.max(from, row.from ?? 0);
  const u = until == null ? row.until : row.until == null ? until : Math.min(until, row.until);
  return u != null && u < f ? null : { from: f, ...(u != null ? { until: u } : {}) };
};

type Each = NonNullable<TapeRow["each"]>[number];
/** How a row's part text fits its parts: inside at label size, inside small, outside under a leader (one or two parts,
 *  with no bracket on that side), or not at all. Small text is drawn at 12 but never reads under 14px on screen
 *  (picture system), about 19 units on a phone, so it must fit the part at that size too. */
function eachFit(e: Each, pw: number, h: number, count: number, side: { above: boolean; below: boolean }): "big" | "small" | "above" | "below" | null {
  const shown = Array.from({ length: count }, (_, i) => i).filter(i => !e.only || e.only(i));
  if (h >= 30 && shown.every(i => textWidth(e.text(i), FS.each) + 8 <= pw)) return "big";
  if (h >= 18 && shown.every(i => textWidth(e.text(i), SMALL_ON_PHONE) + 4 <= pw)) return "small";
  if (shown.length > 2) return null;
  return side.below ? "below" : side.above ? "above" : null;
}
const layersAt = (row: TapeRow, beat: number) => layerAt(layersOf(row), beat);
/** A count in a piece fades where the phone floor would grow it past its piece, every other count first (2, 4, 6 …), so
 *  the pieces still count up and no two numbers ever touch (Review g5 re-walk: improper's 1-31, add's 1 2 3). */
const thinCount = (k: number, pw: number, h: number, chars: number, big: boolean) => {
  const size = big ? FS.each : FS.small, floor = big ? PIC.label : 14;
  // across: room for the number in its piece (every other one first); up: room for its height in the bar (1.2 of its size)
  // it shrinks to fit its piece first (fitIn), so only what can't fit even at 14 on screen thins out
  return { vars: { ...fitIn(pw, chars, size, floor), ...thinOut(roomLeft((k & -k) * pw, chars, 14), roomLeft(h + 4, 1.94, 14)) } };
};

export interface TapeLayout {
  width: number;
  height: number;
  /** pixels per unit */
  unit: number;
  rowHeight: number;
  /** left edge of unit 0 */
  x0: number;
  rowTops: number[];
  stacked: boolean;
  /** the tall arrangement: labels and totals on a line over each bar */
  over: boolean;
  /** square, wrapped: a bar's total hangs under its last line (from overYs) */
  under?: boolean;
  /** tall: the line each row's label and total stand on */
  overYs: number[];
}

export function layoutTape(spec: TapeSpec): TapeLayout {
  if (spec.square) return squareTape(spec);
  const W = spec.width ?? 480, rows = spec.rows, n = rows.length, over = !!spec.over;
  // tall: the labels move over the bars, so the bars take the whole width and may stand half again as thick
  const baseRow = Math.round(Math.min(spec.maxRowHeight ?? 46, Math.max(22, Math.floor(280 / n) - 14)) * (over ? 1.5 : 1));
  const gap = tapeGap(spec); // between rows: the same gap as between pieces (picture system)
  // labels read on one line ("2/3"), as in the model: a stacked fraction is taller than the gap between rows
  const stacked = false;
  const wOf = (t: TapeText, size: number) => {
    const m = stacked ? t.text.match(FRAC) : null;
    return m ? Math.max(m[1]!.length, m[2]!.length) * size * 0.6 + 8 : textWidth(t.text, size);
  };
  const labelMax = Math.max(0, ...rows.flatMap(r => (r.label ?? []).map(t => wOf(t, FS.label))));
  const labelW = labelMax && !over ? labelMax + PIC.labelGap : 0;
  const x0 = M + labelW;
  const unitsWide = Math.max(...rows.map(r => (r.start ?? 0) + r.length));
  // one scale for every row: each bar plus its total must fit
  let unit = (W - M - x0) / unitsWide;
  for (const r of rows) {
    const tw = Math.max(0, ...(r.total ?? []).map(t => wOf(t, FS.total)));
    if (tw && !over) unit = Math.min(unit, (W - M - x0 - PIC.labelGap - tw) / ((r.start ?? 0) + r.length));
  }
  // drawn for zoom (G 2026-10-15): the tall arrangement is the one a square box gets, so its bars thicken until the
  // finished picture is about as tall as it is wide and fills the box. A piece is never taller than it is wide, so a bar
  // still reads as a bar, and never thinner than the plain tall row
  let rowHeight = baseRow;
  if (over) {
    const narrowest = Math.min(...rows.map(r => (r.length / Math.max(...layersOf(r).map(l => l.count))) * unit));
    const br = (spec.brackets ?? []).length * BRACKET, lines = rows.filter(r => r.label?.length || r.total?.length).length * OVER;
    const room = (W * SQUARE_AIM - 2 * M - br - lines - (n - 1) * gap) / n;
    rowHeight = Math.round(Math.max(baseRow, Math.min(room, narrowest, TALL_MAX)));
  }
  const rowTops: number[] = [], overYs: number[] = [];
  let y = M;
  rows.forEach((row, i) => {
    const br = spec.brackets ?? [];
    // part text too big for its part goes outside under a leader: the room for it is kept like a bracket's
    const free = { below: !br.some(b => b.row === i && b.side === "below"), above: !br.some(b => b.row === i && b.side === "above") && i === 0 };
    const out = (row.each ?? []).map(e => eachFit(e, (row.length / layersAt(row, e.from ?? row.from ?? 0).count) * unit, rowHeight, layersAt(row, e.from ?? row.from ?? 0).count, free));
    if (over && (row.label?.length || row.total?.length)) y += OVER;
    overYs.push(y - 6);
    if (br.some(b => b.row === i && b.side === "above") || out.includes("above")) y += BRACKET;
    rowTops.push(y);
    y += rowHeight;
    if (br.some(b => b.row === i && b.side === "below") || out.includes("below")) y += BRACKET;
    y += gap;
  });
  return { width: W, height: Math.round(y - gap + M), unit, rowHeight, x0, rowTops, stacked, over, overYs };
}

/**
 * The bars on the master square's grid (G 2026-10-14): the label column, every part, every row, the gaps between rows and
 * the room for brackets are whole cells, and the picture sits centred in the square by whole cells. A bar's parts are
 * each a whole number of cells where the square has room for it (halves to twelfths always do), else exact and centred.
 */
function squareTape(spec: TapeSpec): TapeLayout {
  const { cell, pad } = SQUARE, { w: W, h: Hs } = MASTERS[spec.shape ?? "square"], rows = spec.rows, over = !!spec.over;
  const room = W - 2 * pad, roomY = Hs - 2 * pad, wrapped = rows.some(r => r.cont);
  const wOf = (t: TapeText, size: number) => textWidth(t.text, size);
  const labelMax = Math.max(0, ...rows.flatMap(r => (r.label ?? []).map(t => wOf(t, FS.label))));
  const totalMax = Math.max(0, ...rows.flatMap(r => (r.total ?? []).map(t => wOf(t, FS.total))));
  // a wrapped bar's total stands under its last line, at its right end, so the lines keep the width for their parts
  const under = wrapped && !over;
  const labelW = labelMax && !over ? cells(labelMax + PIC.labelGap) : 0, totalW = totalMax && !over && !under ? cells(totalMax + PIC.labelGap) : 0;
  const unitsWide = Math.max(...rows.map(r => (r.start ?? 0) + r.length));
  // the grid is the maths (G 2026-10-15): every part is a whole number of grid cells and the parts of a bar touch, so its
  // cuts are grid lines and its pieces can be counted in cells; wholes drawn as wholes stand a cell apart. Cells per
  // whole: the most that fits that makes every part of every row whole cells, two a part where they fit, else one; a bar
  // cut too finely even for that is split exactly instead
  const gaps = wholeGaps(spec);
  const roomBar = room - labelW - totalW - gaps * cell;
  const most = Math.max(1, Math.floor(roomBar / (unitsWide * cell) + 1e-9));
  const spans = rows.flatMap(r => layersOf(r).map(l => r.length / l.count));
  // a part that holds a count or a value takes a cell more, so its text has room on a phone (Review 31ee827)
  const parts = rows.flatMap(r => layersOf(r).map(l => ({ sp: r.length / l.count, more: r.each?.length ? 1 : 0 })));
  const whole = (u: number, least: number) => parts.every(({ sp, more }) => Math.abs(u * sp - Math.round(u * sp)) < 1e-6 && u * sp >= least + more - 1e-6);
  let u = most;
  while (u > 0 && !whole(u, 2)) u--;
  if (!u) { u = most; while (u > 0 && !whole(u, 1)) u--; }
  const unit = (u > 0 ? u : roomBar / (unitsWide * cell)) * cell;
  // a bar is as thick as the old rule asks, rounded to whole cells, and a cell thinner at a time while the rows don't fit
  const stackRows = (rowHeight: number) => {
    const rowTops: number[] = [], overYs: number[] = [];
    let y = 0;
    rows.forEach((row, i) => {
      const br = spec.brackets ?? [];
      const free = { below: !br.some(b => b.row === i && b.side === "below"), above: !br.some(b => b.row === i && b.side === "above") && i === 0 };
      const out = (row.each ?? []).map(e => eachFit(e, (row.length / layersAt(row, e.from ?? row.from ?? 0).count) * unit, rowHeight, layersAt(row, e.from ?? row.from ?? 0).count, free));
      // the lines of one wrapped bar sit a cell apart, different bars two (G 2026-10-14)
      if (i > 0 && wrapped && !row.cont) y += cell;
      if (over && (row.label?.length || row.total?.length)) y += cells(OVER);
      overYs.push(y - 6);
      if (br.some(b => b.row === i && b.side === "above") || out.includes("above")) y += cells(BRACKET);
      rowTops.push(y);
      y += rowHeight;
      if (br.some(b => b.row === i && b.side === "below") || out.includes("below")) y += cells(BRACKET);
      if (under && row.total?.length) { overYs[i] = y + 6; y += cells(OVER); }
      y += cell;
    });
    return { rowTops, overYs, y };
  };
  let rowHeight = cells(Math.min(spec.maxRowHeight ?? 46, Math.max(22, Math.floor(280 / rows.length) - 14)) * (over ? 1.5 : 1));
  let stacked = stackRows(rowHeight);
  while (stacked.y - cell > roomY && rowHeight > 2 * cell) stacked = stackRows((rowHeight -= cell));
  // and a cell thicker at a time, up to 6 cells, while the rows still fit: a picture of one or two bars fills more of
  // the square instead of leaving it empty above and below (G 2026-10-14: the picture fills its box)
  // (a bar of a few wide parts may stand as tall as its parts are wide, up to 12 cells, so the parts read as blocks)
  const widest = Math.max(6 * cell, Math.min(12 * cell, Math.min(...spans) * unit));
  while (rowHeight < widest && stackRows(rowHeight + cell).y - cell <= roomY) stacked = stackRows((rowHeight += cell));
  const { rowTops, overYs, y } = stacked;
  const tall = y - cell, wide = labelW + unitsWide * unit + gaps * cell + totalW;
  // centred by whole cells, so everything stays on the grid; a picture taller than the square grows it
  const H = Math.max(Hs, cells(tall) + 2 * pad);
  const dx = pad + Math.floor((room - wide) / 2 / cell) * cell, dy = pad + Math.floor((H - 2 * pad - tall) / 2 / cell) * cell;
  return { width: W, height: H, unit, rowHeight, x0: dx + labelW, rowTops: rowTops.map(t => t + dy), stacked: false, over, under, overYs: overYs.map(t => t + dy) };
}

/** Builds the scene. Every coordinate comes from the spec, which the lesson computed from its problem. */
/** On the grid, the cells between wholes when the picture draws its bars as wholes: one between each two */
const wholeGaps = (spec: TapeSpec) => (spec.square && spec.rows.some(r => r.wholes) ? Math.max(0, Math.ceil(Math.max(...spec.rows.map(r => (r.start ?? 0) + r.length)) - EPS) - 1) : 0);
/**
 * In the master square a part is at least two cells wide with a cell after it (G 2026-10-14). A bar cut too finely for
 * that on one line (twelfths) wraps onto two lines, each holding half its parts, one under the other: every row becomes
 * its lines, with the parts, shading, counts and knife lines of each, the label on the first line and the total on the
 * last (G 23:08: "wrap the bar"). Null when nothing needs wrapping, or the cuts don't halve evenly.
 */
function wrapTape(spec: TapeSpec): TapeSpec | null {
  if (!spec.square || spec.rows.some(r => r.cont)) return null;
  // a part that holds a count needs a cell more, or on a phone (text held at its floor) the count fills it edge to edge
  // (Review 31ee827: g6-pctwhole's "10"s)
  const narrowIn = (s: TapeSpec) => { const L = layoutTape(s); return s.rows.some(r => layersOf(r).some(l => (r.length / l.count) * L.unit < (r.each?.length ? 3 : 2) * SQUARE.cell - 1e-6)); };
  const narrow = narrowIn(spec);
  // labels over the bars free the width; when that alone gives every part two cells, the bars stay on one line
  if (narrow && spec.tall && !spec.over) { const O = { ...spec, over: true }; if (!narrowIn(O) && layoutTape(O).height <= MASTERS[spec.shape ?? "square"].h) return null; }
  const n = 2;
  // a bar already no longer than one line (g6-pctwhole's 10% block over its 100%) stays as it is, over the first line
  const longest = Math.max(...spec.rows.map(r => (r.start ?? 0) + r.length)), short = (r: TapeRow) => (r.start ?? 0) + r.length <= longest / n + 1e-9;
  if (!narrow || spec.rows.some(r => !short(r) && ((r.start ?? 0) !== 0 || layersOf(r).some(l => l.count % n)))) return null;
  const map: number[] = [];
  const rows: TapeRow[] = [];
  spec.rows.forEach(row => {
    map.push(rows.length);
    if (short(row)) { rows.push(row); return; }
    const len = row.length / n, layers = layersOf(row);
    const countAt = (beat: number) => (layers.find(l => l.from <= beat && (l.until == null || beat <= l.until)) ?? layers[0]!).count;
    for (let k = 0; k < n; k++) {
      const a0 = k * len, b0 = a0 + len;
      const off = (beat: number) => (k * countAt(beat)) / n;
      rows.push({
        ...row, length: len, cont: k > 0,
        parts: typeof row.parts === "number" ? row.parts / n : row.parts.map(l => ({ ...l, count: l.count / n })),
        fills: (row.fills ?? []).filter(f => f.b > a0 && f.a < b0).map(f => ({ ...f, a: Math.max(f.a, a0) - a0, b: Math.min(f.b, b0) - a0 })),
        ticks: row.ticks?.map(t => ({ ...t, count: t.count / n })),
        each: row.each?.map(e => ({ ...e, text: (i: number) => e.text(i + off(e.from ?? row.from ?? 0)),
          ...(e.only ? { only: (i: number) => e.only!(i + off(e.from ?? row.from ?? 0)) } : {}),
          ...(k ? { lead: (e.lead ?? 0) + (countAt(e.from ?? row.from ?? 0) / n) * (e.stagger ?? 0.04) } : {}) })),
        label: k === 0 ? row.label : undefined,
        // over the bars the total stands on the label's line, so a wrapped bar's lines stay one cell apart
        total: k === (spec.over ? 0 : n - 1) ? row.total : undefined,
      });
    }
  });
  const len = (r: number) => spec.rows[r]!.length / n;
  const out: TapeSpec = {
    ...spec, rows,
    brackets: spec.brackets?.map(b => { if (short(spec.rows[b.row]!)) return { ...b, row: map[b.row]! }; const k = Math.min(n - 1, Math.floor(b.a / len(b.row) + 1e-9)); return { ...b, row: map[b.row]! + k, a: b.a - k * len(b.row), b: Math.min(b.b - k * len(b.row), len(b.row)) }; }),
    // a guide down from a bar that stays whole to the first line of a wrapped one keeps its place
    guides: spec.guides?.filter(g => g.at <= longest / n + 1e-9 && g.rows.every(r => short(spec.rows[r]!) || r === Math.max(...g.rows))).map(g => ({ ...g, rows: g.rows.map(r => map[r]!) as [number, number] })),
  };
  // only when the lines still fit the square (a stack of mixed-number wholes in twelfths stays on one line each)
  return layoutTape(out).height <= MASTERS[spec.shape ?? "square"].h ? out : null;
}

/** Builds the scene; a picture in the master square is laid out in every master shape, the square one first. */
export function buildTape(given: TapeSpec): SceneDiagram {
  // every fraction bar is drawn on the master grid (G 2026-10-15 05:47: "yes add it"), with labels over the bars where
  // that draws them bigger
  const spec: TapeSpec = { ...given, square: given.square ?? true, tall: given.tall ?? true };
  if (!spec.square || spec.shape) return buildOne(spec);
  const square = buildOne({ ...spec, shape: "square" });
  return { ...square, shape: "square", shapes: { square, wide: { ...buildOne({ ...spec, shape: "wide" }), shape: "wide" }, strip: { ...buildOne({ ...spec, ...spec.strip, shape: "strip" }), shape: "strip" } } };
}

function buildOne(spec: TapeSpec): SceneDiagram {
  // over the bars, the total of a bar laid out as several wholes stands on its label's line, not between its wholes
  if (spec.square && spec.over && spec.rows.some((r, i) => i > 0 && r.total?.length && !r.label?.length)) {
    const rows = spec.rows.map(r => ({ ...r }));
    rows.forEach((r, i) => {
      if (!i || !r.total?.length || r.label?.length) return;
      let k = i - 1;
      while (k > 0 && !rows[k]!.label?.length) k--;
      if (rows[k]!.total?.length) return;
      rows[k] = { ...rows[k]!, total: r.total };
      rows[i] = { ...r, total: undefined };
    });
    return buildOne({ ...spec, rows });
  }
  const wrapped = wrapTape(spec);
  if (wrapped) return buildOne(wrapped);
  const L = layoutTape(spec);
  const { unit, rowHeight: h, x0 } = L;
  // wholes stand a cell apart (wholeGaps): a point on the line between two wholes is the start of the one after it, or
  // with `end` the end of the one before it
  const gaps = wholeGaps(spec);
  const X = (u: number, end = false) => r1(x0 + u * unit + (gaps ? Math.max(0, Math.min(gaps, end ? Math.ceil(u - EPS) - 1 : Math.floor(u + EPS))) * SQUARE.cell : 0));
  // on the grid the parts touch: their cuts are grid lines (G 2026-10-15), and their corners are square so they meet
  const grid = !!spec.square, cellsExact = grid && spec.rows.every(r => layersOf(r).every(l => { const c = (r.length / l.count) * unit / SQUARE.cell; return Math.abs(c - Math.round(c)) < 1e-6; }));
  const longest = Math.max(...spec.rows.map(r => (r.start ?? 0) + r.length));
  const items: SceneItem[] = [];
  const push = (it: SceneItem | null) => { if (it) items.push(it); };
  const pushLit = (lit: Beats[] | undefined, it: SceneItem) => { items.push(...litRuns(it, lit)); };
  const when = (from: number, until?: number) => ({ ...(from ? { from } : {}), ...(until != null ? { until } : {}) });
  // tall: the line a row's label and total stand on, over its bar (and over its bracket or leader, when it has one above)
  const overY = (ri: number) => L.overYs[ri]!;

  // a label or total: a stacked fraction when there is room, otherwise one line
  const textAt = (t: TapeText, cx: number, cy: number, cls: string, anchor: "end" | "start" | "middle", run: { from: number; until?: number }) => {
    const m = L.stacked ? t.text.match(FRAC) : null;
    // a "?" is the unknown, so it's amber; a total that isn't is ink (the whole), never a part color
    const c = `${cls}${t.acc || t.text === "?" ? " acc" : ""}`;
    if (!m) {
      push({ type: "text", x: r1(cx), y: r1(cy), text: mixedGap(t.text), cls: `${c}${anchor === "middle" ? "" : ` ${anchor}`}`, enter: "rise", ...(t.delay ? { delay: t.delay } : {}), ...when(run.from, run.until) });
      return;
    }
    const size = cls.includes("lbl") ? FS.total : FS.label;
    const w = Math.max(m[1]!.length, m[2]!.length) * size * 0.6 + 8;
    const mid = anchor === "end" ? cx - w / 2 : anchor === "start" ? cx + w / 2 : cx;
    push({ type: "text", x: r1(mid), y: r1(cy - size * 0.68), text: m[1]!, cls: c, enter: "rise", ...when(run.from, run.until) });
    push({ type: "line", x1: r1(mid - w / 2 + 2), y1: r1(cy), x2: r1(mid + w / 2 - 2), y2: r1(cy), cls: "ax thin", enter: "draw", ...when(run.from, run.until) });
    push({ type: "text", x: r1(mid), y: r1(cy + size * 0.68), text: m[2]!, cls: c, enter: "rise", ...when(run.from, run.until) });
  };

  spec.rows.forEach((row, ri) => {
    const top = L.rowTops[ri]!, start = row.start ?? 0, layers = layersOf(row);
    const span = (lay: Layer) => row.length / lay.count;
    // half the picture system's gap each side of a piece, so pieces sit one gap apart (narrow pieces keep most of their width)
    // in the master square half a cell each side, so parts sit one cell apart with their edges on grid lines
    const inset = (pw: number) => (grid ? 0 : Math.min(tapeGap(spec) / 2, pw * 0.2));

    // a re-cut splits: each new piece starts packed against its brothers inside the part it was cut from (where the
    // knife lines were) and slides apart to its place, so the cut opens up. Popping every part again would read as the
    // bar rebuilding; a piece that isn't nested in the cut before just stays put
    const splitDx = (li: number, i: number): number => {
      const lay = layers[li]!, prev = layers[li - 1];
      if (!prev || lay.count <= prev.count || lay.count % prev.count) return 0;
      const q = lay.count / prev.count, c = i % q, pw = span(lay) * unit, ppw = span(prev) * unit;
      const cw = pw - 2 * inset(pw), mid = X(start) + Math.floor(i / q) * ppw + ppw / 2;
      // twice the packed offset: the brothers start overlapping, one piece, and visibly come apart
      return r1(2 * (mid - (q * cw) / 2 + c * cw - (X(start) + i * pw + inset(pw))));
    };
    const enterOf = (li: number, i: number, delay: number) => {
      if (li === 0) return { enter: "pop" as const, delay };
      const dx = splitDx(li, i);
      return dx ? { enter: "slide" as const, vars: { "--dx": `${dx}px` }, delay: layers[li]!.delay ?? 0 } : {};
    };
    // the parts of each cut; on the grid an empty part is blank paper and shading is what fills it (G 2026-10-15 mock)
    layers.forEach((lay, li) => {
      const pw = span(lay) * unit, ins = inset(pw), step = Math.min(0.06, 0.6 / lay.count);
      for (let i = 0; i < lay.count; i++) {
        const xa = X(start + i * span(lay)), xw = X(start + (i + 1) * span(lay), true) - xa;
        push({ type: "rect", x: r1(xa + ins), y: top, w: r1(xw - 2 * ins), h, rx: grid ? 0 : r1(Math.min(PIC.corner.bar, xw / 3, h / 4)), cls: "seg",
          ...enterOf(li, i, r1(i * step * 100) / 100), ...when(lay.from, lay.until) });
      }
    });

    // shading, cut at the parts showing when it appears so the gaps between parts stay
    for (const fill of row.fills ?? []) {
      const run = within(fill.from ?? 0, fill.until, row);
      if (!run) continue;
      // one set of rects per cut that shows while the fill does, so a re-cut bar keeps its gaps
      layers.forEach((lay, li) => {
        const from = Math.max(run.from, lay.from);
        const until = run.until == null ? lay.until : lay.until == null ? run.until : Math.min(run.until, lay.until);
        if (until != null && until < from) return;
        const pu = span(lay), pw = pu * unit, ins = inset(pw);
        // shading pops in with its bar, fades in when it arrives later, and splits with its piece when only the cut under it changes
        const split = from === lay.from && li > 0;
        const enter = from === (row.from ?? 0) ? "pop" : split ? undefined : "fade";
        let k = 0;
        for (let i = 0; i < lay.count; i++) {
          const p0 = start + i * pu, p1 = p0 + pu, lo = Math.max(fill.a, p0), hi = Math.min(fill.b, p1);
          if (hi - lo < EPS) continue;
          const xa = X(lo) + (Math.abs(lo - p0) < EPS ? ins : 0);
          // a sliver (one hundredth past the tenths) keeps a readable minimum width inside its part, not a hairline
          const xb = Math.max(X(hi, true) - (Math.abs(hi - p1) < EPS ? ins : 0), Math.min(xa + MIN_FILL, X(p1, true) - ins));
          const dx = split ? splitDx(li, i) : 0;
          pushLit(fill.tone === "cut" ? undefined : row.lit, { type: "rect", x: r1(xa), y: top, w: r1(Math.max(0.5, xb - xa)), h, rx: grid ? 0 : r1(Math.min(PIC.corner.bar, (xb - xa) / 3, h / 4)),
            cls: fill.tone === "cut" ? "seg on cut" : fill.tone === "two" ? "seg on p1" : "seg on",
            ...(fill.tone === "acc" || dx ? { vars: { ...(fill.tone === "acc" ? { "--tint": grid ? "var(--pic-mid)" : "var(--acc)" } : {}), ...(dx ? { "--dx": `${dx}px` } : {}) } } : {}),
            ...(dx ? { enter: "slide" as const } : enter ? { enter } : {}), delay: dx ? lay.delay ?? 0 : r1(k++ * (fill.stagger ?? Math.min(0.06, 0.6 / lay.count)) * 100) / 100, ...when(from, until) });
        }
      });
      if (fill.tone === "cut") {
        push({ type: "line", x1: r1(X(fill.a) + 4), y1: top + h - 5, x2: r1(X(fill.b) - 4), y2: top + 5, cls: "ln p1", enter: "draw", delay: 0.4, ...when(run.from, run.until) });
      }
    }

    // finer cuts drawn as thin lines
    for (const t of row.ticks ?? []) {
      const run = within(t.from ?? 0, t.until, row);
      if (!run) continue;
      // the knife cuts the parts showing before its beat (the new cut lands with it), other ticks the parts at it
      const lay = layerAt(layers, t.cut && run.from > 0 ? run.from - 1 : run.from), pu = span(lay), tu = row.length / t.count;
      let k = 0;
      for (let j = 1; j < t.count; j++) {
        const at = j * tu, onPart = Math.abs(at / pu - Math.round(at / pu)) < 1e-6;
        if (onPart && !(t.cut && t.all)) continue;
        // the knife: a deep line drawn top to bottom through the bar, one cut after another
        if (t.cut) push({ type: "line", x1: X(start + at), y1: top - 3, x2: X(start + at), y2: top + h + 3, cls: "ln2", enter: "draw", delay: r1(Math.min(0.6, k++ * 0.08) * 100) / 100, ...when(run.from, run.until) });
        else push({ type: "line", x1: X(start + at), y1: r1(t.dashed ? top + 4 : top + h * 0.62), x2: X(start + at), y2: top + h - 4, cls: t.dashed ? "wire" : "tk", enter: "fade",
          delay: r1(Math.min(0.6, j * 0.01) * 100) / 100, ...when(run.from, run.until) });
      }
    }

    // the cells inside each bar, faint, over its shading: a piece reads as so many cells (G 2026-10-15: the grid is the maths)
    // (not in a bar whose parts hold their counts or values: there the text names the amount and the lines would cross it)
    if (cellsExact && !row.each?.length) {
      const c = SQUARE.cell, segs = row.wholes && gaps ? Array.from({ length: Math.ceil(row.length - EPS) }, (_, k) => [start + k, Math.min(start + row.length, start + k + 1)]) : [[start, start + row.length]];
      for (const [a, b] of segs) {
        const xa = X(a!), xb = X(b!, true);
        for (let x = xa + c; x < xb - 1e-6; x += c) push({ type: "line", x1: r1(x), y1: top, x2: r1(x), y2: top + h, cls: "cellln", enter: "fade", ...when(row.from ?? 0, row.until) });
        for (let y = top + c; y < top + h - 1e-6; y += c) push({ type: "line", x1: r1(xa), y1: r1(y), x2: r1(xb), y2: r1(y), cls: "cellln", enter: "fade", ...when(row.from ?? 0, row.until) });
      }
    }

    // whole outlines
    if (row.wholes && !spec.square) {
      for (let k = 0; k < Math.ceil(row.length - EPS); k++) {
        const len = Math.min(1, row.length - k);
        push({ type: "rect", x: X(start + k), y: top - 1, w: r1(len * unit), h: h + 2, rx: 8, cls: "ax thin", enter: "fade", ...when(row.from ?? 0, row.until) });
      }
    }

    // text in each part, white on shaded parts; dropped for a cut whose parts are too narrow for it
    for (const e of row.each ?? []) {
      const run = within(e.from ?? 0, e.until, row);
      if (!run) continue;
      const lay = layerAt(layers, run.from), pu = span(lay), pw = pu * unit;
      const shown = Array.from({ length: lay.count }, (_, i) => i).filter(i => !e.only || e.only(i));
      const br = spec.brackets ?? [];
      const fit = eachFit(e, pw, h, lay.count, { below: !br.some(b => b.row === ri && b.side === "below"), above: !br.some(b => b.row === ri && b.side === "above") && ri === 0 });
      if (!fit) continue; // too many to lead out: the row's bracket or total says it
      if (fit === "above" || fit === "below") {
        // outside: the text sits a bracket's room off the part, a short leader from the part's edge to it
        for (const [k, i] of shown.entries()) {
          const cx = X(start + (i + 0.5) * pu), up = fit === "above";
          const y0 = up ? top - 3 : top + h + 3, y1 = up ? top - 12 : top + h + 12, ty = up ? top - 20 : top + h + 21;
          const tx = Math.min(Math.max(cx, M + textWidth(e.text(i), FS.bracket) / 2), L.width - M - textWidth(e.text(i), FS.bracket) / 2);
          push({ type: "line", x1: r1(cx), y1: r1(y0), x2: r1(tx), y2: r1(y1), cls: "ax thin", enter: "draw", delay: r1(((e.lead ?? 0) + k * (e.stagger ?? 0.04)) * 100) / 100, ...when(run.from, run.until) });
          push({ type: "text", x: r1(tx), y: r1(ty), text: e.text(i), cls: "sm res", enter: "rise", delay: r1(((e.lead ?? 0) + k * (e.stagger ?? 0.04) + 0.2) * 100) / 100, ...when(run.from, run.until) });
        }
        continue;
      }
      const big = fit === "big";
      for (const i of shown) {
        const c = start + (i + 0.5) * pu;
        // split the text's run wherever the shading under it changes
        const marks = new Set<number>([run.from]);
        for (const f of row.fills ?? []) {
          if (f.a > c || f.b < c) continue;
          if ((f.from ?? 0) > run.from) marks.add(f.from ?? 0);
          if (f.until != null && f.until + 1 > run.from) marks.add(f.until + 1);
        }
        const cuts = [...marks].filter(b => run.until == null || b <= run.until).sort((a, b) => a - b);
        cuts.forEach((b, k) => {
          const end = k + 1 < cuts.length ? cuts[k + 1]! - 1 : run.until;
          const shaded = (row.fills ?? []).some(f => f.tone !== "cut" && f.a <= c && f.b >= c && (f.from ?? 0) <= b && (f.until == null || f.until >= b));
          // on the step's accent piece (light in dark mode), the count takes the page's colour (styles/modes.css)
          const onAcc = (row.fills ?? []).some(f => f.tone === "acc" && f.a <= c && f.b >= c && (f.from ?? 0) <= b && (f.until == null || f.until >= b));
          push({ type: "text", x: r1(X(c)), y: r1(top + h / 2), text: e.text(i), cls: `${big ? (shaded ? "lbl res onmid" : "lbl res") : shaded ? "xs onlbl" : "xs"}${onAcc ? " onacc" : ""}`, ...thinCount(shown.indexOf(i) + 1, pw, h, e.text(i).length, big), ...(k === 0 ? { enter: "rise" as const, delay: r1(((e.lead ?? 0) + shown.indexOf(i) * (e.stagger ?? 0.04)) * 100) / 100 } : {}), ...when(b, end) });
        });
      }
    }

    // rows thinner than a label at its floor (phones): fractions, and any two rows' labels, spread apart (add's 2/6 and
    // 5/6); more rows' whole-number labels fade every other row, the top row's label and the bottom row's total always kept (unit-divide's 1s
    // and its 3, 6, 9, 12, 15)
    const n = spec.rows.length, pitch = (L.rowTops[1] ?? top + h) - (L.rowTops[0] ?? top);
    const frac = spec.rows.some(r => (r.label ?? []).concat(r.total ?? []).some(t => t.text.includes("/")));
    const fitRow = (k: number) => (x: SceneItem): SceneItem =>
      n > 1 && (n === 2 || frac) && (x.type === "text" || x.type === "line") ? { ...x, vars: { ...x.vars, ...spreadRows(ri, n, pitch) } }
        : n > 2 && k > 0 && x.type === "text" ? { ...x, vars: { ...x.vars, ...thinOut(roomLeft((k & -k) * pitch, 1.94, FS.label, PIC.label)) } }
        : x;
    const thinRowLabel = fitRow(ri), thinRowTotal = fitRow(n - 1 - ri);
    for (const t of row.label ?? []) {
      const run = within(t.from ?? 0, t.until, row);
      // side labels end one label gap before the bars, so a label held at its on-screen floor (phones) grows away
      // from its bar, never into it
      // tall: on the line over its bar, from the bar's left end
      if (run && L.over) { const at = items.length; textAt(t, X(start), overY(ri), "lbl up", "start", run); items.splice(at, items.length - at, ...items.slice(at).flatMap(x => litRuns(x, row.lit))); }
      else if (run) { const at = items.length; textAt(t, X(0) - PIC.labelGap, top + h / 2, "lbl", "end", run); items.splice(at, items.length - at, ...items.slice(at).flatMap(x => litRuns(x, row.lit)).map(x => thinRowLabel(x))); }
    }
    for (const t of row.total ?? []) {
      const run = within(t.from ?? 0, t.until, row);
      // over a short bar the total keeps clear of the label on its line: it moves right until a label gap after it
      const labelEnd = Math.max(0, ...(row.label ?? []).map(l => textWidth(l.text, FS.label)));
      const clear = labelEnd ? X(start) + labelEnd + PIC.labelGap + textWidth(t.text, FS.total) : 0;
      // and a bar shorter than the longest, with room after it, takes its total beside its end instead: on a phone the
      // label and total are held at their floor and outgrow the line over a short bar (Review 31ee827: "numeratorx = 40")
      const after = (longest - start - row.length) * L.unit;
      if (run && L.over && after >= PIC.labelGap + 2 * textWidth(t.text, FS.total)) { const at = items.length; textAt(t, X(start + row.length, true) + PIC.labelGap, top + h / 2, "lbl pw", "start", run); items.splice(at, items.length - at, ...items.slice(at).map(thinRowTotal)); }
      else if (run && L.over) textAt(t, Math.max(X(start + row.length, true), clear), overY(ri), "lbl pw up", "end", run);
      else if (run && L.under) textAt(t, X(start + row.length, true), overY(ri), "lbl pw down", "end", run);
      else if (run) { const at = items.length; textAt(t, X(start + row.length, true) + PIC.labelGap, top + h / 2, "lbl pw", "start", run); items.splice(at, items.length - at, ...items.slice(at).map(thinRowTotal)); }
    }
  });

  for (const b of spec.brackets ?? []) {
    const row = spec.rows[b.row]!, top = L.rowTops[b.row]!;
    const run = within(b.from ?? 0, b.until, row);
    if (!run) continue;
    const xa = X(b.a) + 2, xb = X(b.b, true) - 2, above = b.side === "above";
    const y = above ? top - 7 : top + h + 7, tick = above ? 6 : -6;
    push({ type: "path", d: `M${r1(xa)} ${r1(y + tick)} L${r1(xa)} ${r1(y)} L${r1(xb)} ${r1(y)} L${r1(xb)} ${r1(y + tick)}`, cls: "ax thin", enter: "draw", ...when(run.from, run.until) });
    const tw = textWidth(b.text, FS.bracket);
    const cx = Math.min(Math.max((xa + xb) / 2, M + tw / 2), L.width - M - tw / 2);
    // the text stands on a bracket above its row and hangs from one below, so the phone floor grows it away from the
    // bars and the row's own labels (g7-pctchange's "15 ÷ 50 = 0.3" under its "+30%")
    push({ type: "text", x: r1(cx), y: r1(above ? y - 3 : y + 3), text: b.text, cls: `${b.acc ? "sm acc" : "sm"} ${above ? "up" : "down"}`, enter: "rise", delay: 0.2, ...when(run.from, run.until) });
  }

  for (const g of spec.guides ?? []) {
    const [r0, r1_] = g.rows;
    // over the bars it stops for each bar's label line and picks up again on the bar (Review 31ee827: it ran through
    // "100%"); on the grid it runs down the middle of the cell between two parts
    const gx = X(g.at);
    const runs: [number, number][] = L.over ? Array.from({ length: r1_ - r0 + 1 }, (_, k) => [L.rowTops[r0 + k]! - 4, L.rowTops[r0 + k]! + h + 4]) : [[L.rowTops[r0]! - 4, L.rowTops[r1_]! + h + 4]];
    for (const [y1, y2] of runs) push({ type: "line", x1: gx, y1, x2: gx, y2, cls: "wire", enter: "draw", ...when(g.from ?? 0) });
  }

  const scene: SceneDiagram = { kind: "scene", family: "tape", width: L.width, height: L.height, items, alt: spec.alt, camera: true, ...(spec.two ? { two: true } : {}), ...(spec.square ? { square: true } : {}),
    ...((spec.tall ?? true) && !spec.over && !spec.square ? { layouts: [buildOne({ ...spec, over: true })] } : {}) };
  // in the master square the box is always the same shape, so of the two arrangements the one with the bigger bars is
  // the picture (labels beside the bars, or over them)
  if (spec.square && (spec.tall ?? true) && !spec.over) {
    const tall = buildOne({ ...spec, over: true });
    const T = layoutTape({ ...spec, over: true });
    // the arrangement whose parts are the bigger blocks: the narrower of a part's width and its bar's height
    const block = (A: TapeLayout) => Math.min(Math.min(...spec.rows.flatMap(r => layersOf(r).map(l => (r.length / l.count) * A.unit))), A.rowHeight);
    if ((block(T) > block(L) || (block(T) === block(L) && T.unit > L.unit)) && T.height <= L.height) return { ...tall, block: block(T) };
    return { ...scene, block: block(L) };
  }
  return scene;
}
