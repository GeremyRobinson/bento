// Term table (Curriculum fixes-02, Part B): columns by power (x³, x², x, 1), each column in its own part colour, and
// rows of coefficients that appear beat by beat. Three motions: a note dropping onto a coefficient (an exponent coming
// down to multiply it), a term sliding one column right (derivative) or left (antiderivative), and arrows for
// "add down" and "multiply across" (synthetic division). Every value comes from the lesson; this only places and times.
import type { Enter, SceneDiagram, SceneItem } from "../scene/schema";
import { arrowHead, r1 } from "../scene/helpers";
import { giveWay, growDown, shortUp } from "../scene/picture-system";

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

/**
 * Drawn at about a phone's picture size (units ≈ px in a phone's 160px box), so the label floor barely grows the text
 * there and the rows keep apart; a tablet draws it up to 3 times bigger, its text up to 1.5 times.
 */
export const TERMS = { cw: 50, rh: 30, cell: 24, head: 28, left: 42, pad: 10 } as const;

const CELL_FONT = "max(var(--d-text-lg), calc(16px * var(--px, 0)))";
/** a worked line under the table is a caption, not a label: held at 16px on a phone so a long one still fits across */
const LINE_FONT = "max(var(--d-text-lg), calc(16px * var(--px, 0)))";

export function buildTermTable(s: TermTableSpec): SceneDiagram {
  // the label column takes its longest row label (a 20px label: about 12 units a character)
  const { cw, rh, cell, pad } = TERMS, head = TERMS.head + (s.dropRoom ? 24 : 0);
  const left = Math.max(TERMS.left, 14 + Math.max(0, ...s.rows.map(r => (r.label ?? "").length * 12)));
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
    items.push({ type: "rect", x: r1(X(i) - cw / 2 + 3), y: r1(TERMS.head - 4), w: cw - 6, h: r1(head - TERMS.head + nRows * rh + 6), rx: 8, cls: `fillsoft ${c.part}` });
    items.push({ type: "text", x: r1(X(i)), y: r1(TERMS.head / 2 - 1), text: c.label, ...(c.sup ? { sup: c.sup } : {}), cls: `lbl big ${c.part}` });
  });
  s.rows.forEach((r, j) => { if (r.label) items.push({ type: "text", x: r1(left - 8), y: r1(Y(j)), text: r.label, cls: "lbl end pw", from: r.from ?? 0, enter: "fade" }); });
  for (const u of s.ruleAbove ?? []) items.push({ type: "line", x1: r1(left - 4), y1: r1(head + u.row * rh), x2: r1(left + nCols * cw), y2: r1(head + u.row * rh), cls: "ax", from: u.from, enter: "draw" });
  for (const m of s.marks ?? []) {
    const to = m.toCol ?? m.col, x0 = X(m.col) - cell / 2 - 5, x1 = X(to) + cell / 2 + 5;
    const ym = m.row === "head" ? TERMS.head / 2 : Y(m.row);
    if (m.kind === "strike") {
      items.push({ type: "line", x1: r1(X(m.col) - cell / 2 - 4), y1: r1(ym + cell / 2 + 4), x2: r1(X(to) + cell / 2 + 4), y2: r1(ym - cell / 2 - 4), ...time(m, "ln2", "draw") } as SceneItem);
      continue;
    }
    const mh = m.row === "head" ? TERMS.head - 2 : cell + 8;
    items.push({ type: "rect", x: r1(x0), y: r1(ym - mh / 2), w: r1(x1 - x0), h: mh, rx: 10, ...time(m, m.kind === "ring" ? "xring" : "hlline") } as SceneItem);
  }
  for (const c of s.cells) {
    const part = s.cols[c.col]?.part ?? "pw";
    const box = `xbox ${part}${c.tone === "faded" ? " cut" : ""}`, txt = c.tone === "acc" ? "lbl big acc" : `lbl big pw${c.tone === "faded" ? " cut" : ""}`;
    const w = Math.max(cell, c.text.length * 13 + 8);
    const slide = c.slideFrom ? { enter: "slide" as Enter, vars: { "--dx": `${r1(X(c.slideFrom[1]) - X(c.col))}px`, "--dy": `${r1(Y(c.slideFrom[0]) - Y(c.row))}px` } } : null;
    const t = slide && c.at == null ? { ...c, at: 0 } : c;
    const sl = slide && t.leave == null ? slide : {};
    items.push({ type: "rect", x: r1(X(c.col) - w / 2), y: r1(Y(c.row) - cell / 2), w: r1(w), h: cell, rx: 7, ...time(t, box, c.enter ?? "pop"), ...sl } as SceneItem);
    // a coefficient is a number in its cell, like a digit on its card: held at 16px on a phone (not the 20px label floor),
    // so a table's rows still stand apart in a phone's short box
    const tt = time(t, txt, c.enter ?? "pop"), tv = { ...(tt.vars ?? {}), ...((sl as { vars?: Record<string, string> }).vars ?? {}), fontSize: CELL_FONT };
    items.push({ type: "text", x: r1(X(c.col)), y: r1(Y(c.row)), text: c.text, ...tt, ...sl, vars: tv } as SceneItem);
  }
  for (const a of s.arrows ?? []) {
    const [r0, c0] = a.a, [r2, c2] = a.b;
    let x0 = X(c0), y0 = Y(r0), x1 = X(c2), y1 = Y(r2);
    if (a.kind === "down") {
      // "add down" runs beside the column, past the cells it adds, to the row it lands in
      x0 = x1 = X(c0) + (cw - 6) / 2 - 5; y0 = Y(r0) - cell / 2; y1 = Y(r2) + 4;
    }
    // start and stop at the cells' edges, not their middles
    const len = Math.hypot(x1 - x0, y1 - y0), ux = (x1 - x0) / len, uy = (y1 - y0) / len, cut = a.kind === "down" ? 0 : cell / 2 + 4;
    x0 += ux * cut; y0 += uy * cut; x1 -= ux * cut; y1 -= uy * cut;
    const cls = a.kind === "back" ? "ln faint" : "ln thin pq";
    items.push({ type: "line", x1: r1(x0), y1: r1(y0), x2: r1(x1), y2: r1(y1), ...time(a, cls, "draw") } as SceneItem);
    items.push({ ...arrowHead(r1(x1), r1(y1), Math.atan2(y1 - y0, x1 - x0), 8), ...time({ ...a, at: (a.at ?? 0) + 0.5 }, a.kind === "back" ? "dotp pw cut" : "dota", "fade") } as SceneItem);
    if (a.label) {
      // the label sits beside the arrow's middle, on its outer side (a check arrow back: on the side away from the cell it leaves for)
      const mx = (x0 + x1) / 2, my = (y0 + y1) / 2, nx = -uy, ny = ux, side = a.kind === "back" ? -1 : 1;
      items.push({ type: "text", x: r1(mx + nx * 16 * side), y: r1(my + ny * 16 * side), text: a.label, ...time({ ...a, at: (a.at ?? 0) + 0.3 }, a.kind === "back" ? "sm muted" : "sm acc", "fade") } as SceneItem);
    }
  }
  for (const n of s.notes ?? []) {
    const x = n.col < 0 ? left - 8 : X(n.col);
    // a note dropping onto the first row stands on that row's cells (.up): on a phone it grows up into the drop room,
    // away from the cell it multiplies, and on a tablet it still sits just above it
    // (in the small note size: a phone's short box has no room for a label row between the headers and the cells)
    const drop = n.row < 0 && n.row > -1, y = drop ? Y(0) - cell / 2 - 2 : Y(n.row);
    items.push({ type: "text", x: r1(x + (n.anchor === "start" ? -cw / 2 + 6 : 0)), y: r1(y), text: n.text, ...(n.sup ? { sup: n.sup } : {}), ...time(n, `${drop ? (n.cls ?? "lbl acc").replace(/\blbl\b/, "sm") : n.cls ?? "lbl acc"}${n.anchor ? ` ${n.anchor}` : n.col < 0 ? " end" : ""}${drop ? " up" : ""}`, n.enter ?? "rise") } as SceneItem);
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
  const W = Math.max(tableW + pad, lineW + 2 * pad, 200), cx = Math.max(lineW / 2 + pad, (left + nCols * cw) / 2);
  const top = head + nRows * rh + 6;
  // each line hangs from its top (.down) and moves down by what the lines above it grew on a phone; they are the worked
  // lines, so practice leaves them to the work list (.cap)
  // lines, and in a phone's short box they are written on one line, each giving way to the next as it comes (shortUp)
  const start = (l: TermLine) => l.from + (l.at ?? 0) / 100;
  const lastBeat = Math.max(...items.map(i => Math.max(i.from ?? 0, i.until ?? 0)), ...lines.map(l => Math.max(l.from, l.until ?? 0)));
  lines.forEach((l, k) => {
    const it = time(l, `${l.cls ?? "lbl big acc"} down cap`, "rise");
    const line = { type: "text", x: r1(cx), y: r1(top + 4 + rowOf[k]! * 26), text: l.text, ...it, vars: { ...(it.vars ?? {}), ...growDown(rowOf[k]!), ...shortUp(rowOf[k]! * 26), fontSize: LINE_FONT } } as SceneItem;
    // the first line written after this one while this one still shows
    const next = l.leave == null ? lines.filter(o => start(o) > start(l) && (l.until == null || o.from <= l.until)).sort((a, b) => start(a) - start(b))[0] : undefined;
    items.push(...(next ? giveWay(line, next.from, next.at ?? 0, lastBeat) : [line]));
  });
  return { kind: "scene", family: "term-table", width: r1(W), height: r1(top + (rows.length ? 8 + rows.length * 26 : 4)), items, alt: s.alt };
}
