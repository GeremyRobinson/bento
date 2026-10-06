// Term table (Curriculum fixes-02, Part B): columns by power (x³, x², x, 1), each column in its own part colour, and
// rows of coefficients that appear beat by beat. Three motions: a note dropping onto a coefficient (an exponent coming
// down to multiply it), a term sliding one column right (derivative) or left (antiderivative), and arrows for
// "add down" and "multiply across" (synthetic division). Every value comes from the lesson; this only places and times.
import type { Enter, SceneDiagram, SceneItem } from "../scene/schema";
import { arrowHead, r1 } from "../scene/helpers";

/** When a piece shows: from beat `from` (until beat `until`), coming in `at` seconds into its beat, going at `leave`. */
export interface When { from: number; until?: number; at?: number; leave?: number }
export interface TermCol { label: string; sup?: string; part: string }
export interface TermCell extends When {
  row: number; col: number; text: string;
  /** "acc" for the result being found, "faded" for a 0 that drops out */
  tone?: "acc" | "faded";
  /** slides in from this grid spot */
  slideFrom?: [row: number, col: number];
  enter?: Enter;
}
/** Free text on the grid (a drop note such as "3 ×", a row label, "+ C"); `col` −1 is the label column. */
export interface TermNote extends When { row: number; col: number; text: string; sup?: string; cls?: string; enter?: Enter; anchor?: "start" | "end" }
/** "down": straight down a column; "across": from a cell to the next column's cell (multiply across); "back": a faint check arrow. */
export interface TermArrow extends When { kind: "down" | "across" | "back"; a: [row: number, col: number]; b: [row: number, col: number]; label?: string }
/** An outline round a cell (or a run of cells along a row): `ring` circles a value, `focus` lights the one talked about,
    `strike` crosses out a term that drops out. */
export interface TermMark extends When { /** "head": round the column's header */ row: number | "head"; col: number; toCol?: number; kind: "ring" | "focus" | "strike" }
/** A line of text under the table. */
export interface TermLine extends When { text: string; cls?: string }

export interface TermTableSpec {
  cols: TermCol[];
  /** row labels down the left (e.g. "f", "f′", "+"); a row label may change over time through notes instead */
  rows: { label?: string; from?: number }[];
  cells: TermCell[];
  notes?: TermNote[];
  arrows?: TermArrow[];
  marks?: TermMark[];
  /** a rule above this row (the "add up to here" line) */
  ruleAbove?: { row: number; from: number }[];
  lines?: TermLine[];
  /** leave room between the headers and the first row for notes dropping onto it (row −0.55) */
  dropRoom?: boolean;
  alt: string;
}

export const TERMS = { cw: 86, rh: 58, cell: 44, head: 40, left: 64, pad: 14 } as const;

export function buildTermTable(s: TermTableSpec): SceneDiagram {
  const { cw, rh, cell, left, pad } = TERMS, head = TERMS.head + (s.dropRoom ? 26 : 0);
  const nCols = s.cols.length, nRows = s.rows.length;
  // one spare column on the right for a constant falling off or a "+ C"
  const X = (c: number) => left + c * cw + cw / 2, Y = (r: number) => head + r * rh + rh / 2;
  const items: SceneItem[] = [];
  const time = (w: When, cls: string, enter: Enter = "fade"): Partial<SceneItem> => {
    const base = { from: w.from, ...(w.until != null ? { until: w.until } : {}) };
    if (w.at != null && w.leave != null) return { ...base, cls, enter: "flash", delay: w.at, vars: { "--d2": `${w.leave.toFixed(2)}s` } };
    if (w.leave != null) return { ...base, cls: `${cls} a-outsoon`, delay: w.leave };
    if (w.at != null) return { ...base, cls, enter, delay: w.at };
    return { ...base, cls };
  };
  // headers: the power each column holds, in its colour, over a faint column wash
  s.cols.forEach((c, i) => {
    items.push({ type: "rect", x: r1(X(i) - cw / 2 + 4), y: r1(TERMS.head - 6), w: cw - 8, h: r1(head - TERMS.head + nRows * rh + 8), rx: 12, cls: `fillsoft ${c.part}` });
    items.push({ type: "text", x: r1(X(i)), y: r1(TERMS.head / 2), text: c.label, ...(c.sup ? { sup: c.sup } : {}), cls: `lbl big ${c.part}` });
  });
  s.rows.forEach((r, j) => { if (r.label) items.push({ type: "text", x: r1(left - 10), y: r1(Y(j)), text: r.label, cls: "lbl end pw", from: r.from ?? 0, enter: "fade" }); });
  for (const u of s.ruleAbove ?? []) items.push({ type: "line", x1: r1(left - 4), y1: r1(head + u.row * rh), x2: r1(left + nCols * cw), y2: r1(head + u.row * rh), cls: "ax", from: u.from, enter: "draw" });
  for (const m of s.marks ?? []) {
    const to = m.toCol ?? m.col, x0 = X(m.col) - cell / 2 - 8, x1 = X(to) + cell / 2 + 8;
    const ym = m.row === "head" ? TERMS.head / 2 : Y(m.row);
    if (m.kind === "strike") {
      items.push({ type: "line", x1: r1(X(m.col) - cell / 2 - 4), y1: r1(ym + cell / 2 + 4), x2: r1(X(to) + cell / 2 + 4), y2: r1(ym - cell / 2 - 4), ...time(m, "ln2", "draw") } as SceneItem);
      continue;
    }
    const mh = m.row === "head" ? TERMS.head - 4 : cell + 12;
    items.push({ type: "rect", x: r1(x0), y: r1(ym - mh / 2), w: r1(x1 - x0), h: mh, rx: 14, ...time(m, m.kind === "ring" ? "xring" : "hlline") } as SceneItem);
  }
  for (const c of s.cells) {
    const part = s.cols[c.col]?.part ?? "pw";
    const box = `xbox ${part}${c.tone === "faded" ? " cut" : ""}`, txt = c.tone === "acc" ? "lbl big acc" : `lbl big pw${c.tone === "faded" ? " cut" : ""}`;
    const w = Math.max(cell, c.text.length * 13 + 16);
    const slide = c.slideFrom ? { enter: "slide" as Enter, vars: { "--dx": `${r1(X(c.slideFrom[1]) - X(c.col))}px`, "--dy": `${r1(Y(c.slideFrom[0]) - Y(c.row))}px` } } : null;
    const t = slide && c.at == null ? { ...c, at: 0 } : c;
    const sl = slide && t.leave == null ? slide : {};
    items.push({ type: "rect", x: r1(X(c.col) - w / 2), y: r1(Y(c.row) - cell / 2), w: r1(w), h: cell, rx: 10, ...time(t, box, c.enter ?? "pop"), ...sl } as SceneItem);
    items.push({ type: "text", x: r1(X(c.col)), y: r1(Y(c.row)), text: c.text, ...time(t, txt, c.enter ?? "pop"), ...sl } as SceneItem);
  }
  for (const a of s.arrows ?? []) {
    const [r0, c0] = a.a, [r2, c2] = a.b;
    let x0 = X(c0), y0 = Y(r0), x1 = X(c2), y1 = Y(r2);
    if (a.kind === "down") {
      // "add down" runs beside the column, past the cells it adds, to the row it lands in
      x0 = x1 = X(c0) + (cw - 8) / 2 - 7; y0 = Y(r0) - cell / 2; y1 = Y(r2) + 4;
    }
    // start and stop at the cells' edges, not their middles
    const len = Math.hypot(x1 - x0, y1 - y0), ux = (x1 - x0) / len, uy = (y1 - y0) / len, cut = a.kind === "down" ? 0 : cell / 2 + 6;
    x0 += ux * cut; y0 += uy * cut; x1 -= ux * cut; y1 -= uy * cut;
    const cls = a.kind === "back" ? "ln faint" : "ln thin pq";
    items.push({ type: "line", x1: r1(x0), y1: r1(y0), x2: r1(x1), y2: r1(y1), ...time(a, cls, "draw") } as SceneItem);
    items.push({ ...arrowHead(r1(x1), r1(y1), Math.atan2(y1 - y0, x1 - x0), 10), ...time({ ...a, at: (a.at ?? 0) + 0.5 }, a.kind === "back" ? "dotp pw cut" : "dota", "fade") } as SceneItem);
    if (a.label) {
      // the label sits beside the arrow's middle, on its outer side
      const mx = (x0 + x1) / 2, my = (y0 + y1) / 2, nx = -uy, ny = ux, side = 1;
      items.push({ type: "text", x: r1(mx + nx * 22 * side), y: r1(my + ny * 22 * side), text: a.label, ...time({ ...a, at: (a.at ?? 0) + 0.3 }, a.kind === "back" ? "sm muted" : "sm acc", "fade") } as SceneItem);
    }
  }
  for (const n of s.notes ?? []) {
    const x = n.col < 0 ? left - 10 : X(n.col);
    items.push({ type: "text", x: r1(x + (n.anchor === "start" ? -cw / 2 + 6 : 0)), y: r1(Y(n.row)), text: n.text, ...(n.sup ? { sup: n.sup } : {}), ...time(n, `${n.cls ?? "lbl acc"}${n.anchor ? ` ${n.anchor}` : n.col < 0 ? " end" : ""}`, n.enter ?? "rise") } as SceneItem);
  }
  // lines under the table share rows when they are never on screen together
  const lines = s.lines ?? [], rows: { from: number; until: number }[][] = [], rowOf: number[] = [];
  for (const l of lines) {
    const span = { from: l.from, until: l.until ?? Infinity };
    let k = rows.findIndex(r => r.every(o => span.until < o.from || o.until < span.from));
    if (k < 0) { k = rows.length; rows.push([]); }
    rows[k]!.push(span); rowOf.push(k);
  }
  const extraCol = [...s.cells.map(c => c.col), ...(s.notes ?? []).map(n => n.col)].some(c => c >= nCols) ? 1 : 0;
  const tableW = left + (nCols + extraCol) * cw;
  const lineSize = (l: TermLine) => (/\bbig\b/.test(l.cls ?? "lbl big") ? 22 : /\bsm\b/.test(l.cls ?? "") ? 15 : 17);
  const lineW = Math.max(0, ...lines.map(l => l.text.length * lineSize(l) * 0.6));
  const W = Math.max(tableW + pad, lineW + 2 * pad, 300), cx = Math.max(lineW / 2 + pad, (left + nCols * cw) / 2);
  const top = head + nRows * rh + 8;
  lines.forEach((l, k) => items.push({ type: "text", x: r1(cx), y: r1(top + 20 + rowOf[k]! * 28), text: l.text, ...time(l, l.cls ?? "lbl big acc", "rise") } as SceneItem));
  return { kind: "scene", family: "term-table", width: r1(W), height: r1(top + (rows.length ? 12 + rows.length * 28 : 4)), items, alt: s.alt };
}
