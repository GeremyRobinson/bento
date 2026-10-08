// Tape diagrams and fraction bars: from a lesson's TapeSpec (computed from its problem) to a scene of shapes.
// One scale for every row, so bar lengths stay in proportion; text sizes, columns and row heights are worked out
// from the labels so nothing runs off the canvas or overlaps.
import type { SceneDiagram, SceneItem } from "../scene/schema";
import { r1 } from "../scene/helpers";
import type { TapeRow, TapeSpec, TapeText } from "./schema";

const M = 10; // outer margin
const BRACKET = 28; // room for a bracket and its text
const FS = { label: 15, total: 17, each: 12, bracket: 15 };
const EPS = 1e-9;
/** narrowest a shaded piece is drawn, in px */
const MIN_FILL = 9;

/** Rough width of text in the picture fonts. */
export const textWidth = (s: string, size: number) => s.length * size * 0.62;
const FRAC = /^(\d+|\?|x)\/(\d+)$/;

type Layer = { count: number; from: number; until?: number };

/** The cuts of a row as layers, each shown from its beat until the next cut starts. */
export function layersOf(row: TapeRow): Layer[] {
  const from0 = row.from ?? 0;
  const list = typeof row.parts === "number" ? [{ count: row.parts, from: from0 }] : [...row.parts].sort((a, b) => a.from - b.from);
  return list.map((l, i) => {
    const next = list[i + 1];
    const until = next ? next.from - 1 : row.until;
    return { count: l.count, from: Math.max(l.from, from0), ...(until != null ? { until } : {}) };
  });
}
const layerAt = (layers: Layer[], beat: number) => [...layers].reverse().find(l => l.from <= beat) ?? layers[0]!;

/** What a run of beats [from, until] looks like: shown if it overlaps the row's own run. */
const within = (from: number, until: number | undefined, row: TapeRow) => {
  const f = Math.max(from, row.from ?? 0);
  const u = until == null ? row.until : row.until == null ? until : Math.min(until, row.until);
  return u != null && u < f ? null : { from: f, ...(u != null ? { until: u } : {}) };
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
}

export function layoutTape(spec: TapeSpec): TapeLayout {
  const W = spec.width ?? 480, rows = spec.rows, n = rows.length;
  const rowHeight = Math.min(spec.maxRowHeight ?? 46, Math.max(22, Math.floor(280 / n) - 14));
  const gap = rowHeight < 30 ? 8 : 14; // between rows
  const stacked = rowHeight >= 40;
  const wOf = (t: TapeText, size: number) => {
    const m = stacked ? t.text.match(FRAC) : null;
    return m ? Math.max(m[1]!.length, m[2]!.length) * size * 0.6 + 8 : textWidth(t.text, size);
  };
  const labelMax = Math.max(0, ...rows.flatMap(r => (r.label ?? []).map(t => wOf(t, FS.label))));
  const labelW = labelMax ? labelMax + 12 : 0;
  const x0 = M + labelW;
  const unitsWide = Math.max(...rows.map(r => (r.start ?? 0) + r.length));
  // one scale for every row: each bar plus its total must fit
  let unit = (W - M - x0) / unitsWide;
  for (const r of rows) {
    const tw = Math.max(0, ...(r.total ?? []).map(t => wOf(t, FS.total)));
    if (tw) unit = Math.min(unit, (W - M - x0 - 14 - tw) / ((r.start ?? 0) + r.length));
  }
  const rowTops: number[] = [];
  let y = M;
  rows.forEach((_, i) => {
    const br = spec.brackets ?? [];
    if (br.some(b => b.row === i && b.side === "above")) y += BRACKET;
    rowTops.push(y);
    y += rowHeight;
    if (br.some(b => b.row === i && b.side === "below")) y += BRACKET;
    y += gap;
  });
  return { width: W, height: Math.round(y - gap + M), unit, rowHeight, x0, rowTops, stacked };
}

/** Builds the scene. Every coordinate comes from the spec, which the lesson computed from its problem. */
export function buildTape(spec: TapeSpec): SceneDiagram {
  const L = layoutTape(spec);
  const { unit, rowHeight: h, x0 } = L;
  const X = (u: number) => r1(x0 + u * unit);
  const items: SceneItem[] = [];
  const push = (it: SceneItem | null) => { if (it) items.push(it); };
  const when = (from: number, until?: number) => ({ ...(from ? { from } : {}), ...(until != null ? { until } : {}) });

  // a label or total: a stacked fraction when there is room, otherwise one line
  const textAt = (t: TapeText, cx: number, cy: number, cls: string, anchor: "end" | "start" | "middle", run: { from: number; until?: number }) => {
    const m = L.stacked ? t.text.match(FRAC) : null;
    // a "?" is the unknown, so it's amber; a total that isn't is ink (the whole), never a part color
    const c = `${cls}${t.acc || t.text === "?" ? " acc" : ""}`;
    if (!m) {
      push({ type: "text", x: r1(cx), y: r1(cy), text: t.text, cls: `${c}${anchor === "middle" ? "" : ` ${anchor}`}`, enter: "rise", ...when(run.from, run.until) });
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
    const inset = (pw: number) => Math.min(1.5, pw * 0.12);

    // the parts of each cut
    for (const lay of layers) {
      const pw = span(lay) * unit, ins = inset(pw), step = Math.min(0.06, 0.6 / lay.count);
      for (let i = 0; i < lay.count; i++) {
        // a re-cut swaps in place (the dashed marks already showed where): popping every part again reads as the bar rebuilding
        push({ type: "rect", x: r1(X(start) + i * pw + ins), y: top, w: r1(pw - 2 * ins), h, rx: r1(Math.min(7, pw / 3, h / 4)), cls: "seg",
          ...(lay === layers[0] ? { enter: "pop" as const, delay: r1(i * step * 100) / 100 } : {}), ...when(lay.from, lay.until) });
      }
    }

    // shading, cut at the parts showing when it appears so the gaps between parts stay
    for (const fill of row.fills ?? []) {
      const run = within(fill.from ?? 0, fill.until, row);
      if (!run) continue;
      // one set of rects per cut that shows while the fill does, so a re-cut bar keeps its gaps
      for (const lay of layers) {
        const from = Math.max(run.from, lay.from);
        const until = run.until == null ? lay.until : lay.until == null ? run.until : Math.min(run.until, lay.until);
        if (until != null && until < from) continue;
        const pu = span(lay), pw = pu * unit, ins = inset(pw);
        // shading pops in with its bar, fades in when it arrives later, and swaps in place when only the cut under it changes
        const enter = from === (row.from ?? 0) ? "pop" : from === lay.from && lay !== layers[0] ? undefined : "fade";
        let k = 0;
        for (let i = 0; i < lay.count; i++) {
          const p0 = start + i * pu, p1 = p0 + pu, lo = Math.max(fill.a, p0), hi = Math.min(fill.b, p1);
          if (hi - lo < EPS) continue;
          const xa = X(lo) + (Math.abs(lo - p0) < EPS ? ins : 0);
          // a sliver (one hundredth past the tenths) keeps a readable minimum width inside its part, not a hairline
          const xb = Math.max(X(hi) - (Math.abs(hi - p1) < EPS ? ins : 0), Math.min(xa + MIN_FILL, X(p1) - ins));
          push({ type: "rect", x: r1(xa), y: top, w: r1(Math.max(0.5, xb - xa)), h, rx: r1(Math.min(7, (xb - xa) / 3, h / 4)),
            cls: fill.tone === "cut" ? "seg on cut" : fill.tone === "two" ? "seg on p1" : "seg on", ...(fill.tone === "acc" ? { vars: { "--tint": "var(--acc)" } } : {}),
            ...(enter ? { enter } : {}), delay: r1(k++ * Math.min(0.06, 0.6 / lay.count) * 100) / 100, ...when(from, until) });
        }
      }
      if (fill.tone === "cut") {
        push({ type: "line", x1: r1(X(fill.a) + 4), y1: top + h - 5, x2: r1(X(fill.b) - 4), y2: top + 5, cls: "ln p1", enter: "draw", delay: 0.4, ...when(run.from, run.until) });
      }
    }

    // finer cuts drawn as thin lines
    for (const t of row.ticks ?? []) {
      const run = within(t.from ?? 0, t.until, row);
      if (!run) continue;
      const lay = layerAt(layers, run.from), pu = span(lay), tu = row.length / t.count;
      for (let j = 1; j < t.count; j++) {
        const at = j * tu, onPart = Math.abs(at / pu - Math.round(at / pu)) < 1e-6;
        if (onPart) continue;
        push({ type: "line", x1: X(start + at), y1: r1(t.dashed ? top + 4 : top + h * 0.62), x2: X(start + at), y2: top + h - 4, cls: t.dashed ? "wire" : "tk", enter: "fade",
          delay: r1(Math.min(0.6, j * 0.01) * 100) / 100, ...when(run.from, run.until) });
      }
    }

    // whole outlines
    if (row.wholes) {
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
      const fits = h >= 18 && shown.every(i => textWidth(e.text(i), FS.each) + 8 <= pw);
      if (!fits) continue;
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
          push({ type: "text", x: r1(X(c)), y: r1(top + h / 2), text: e.text(i), cls: shaded ? "xs onlbl" : "xs", ...(k === 0 ? { enter: "rise" as const, delay: r1(i * 0.04 * 100) / 100 } : {}), ...when(b, end) });
        });
      }
    }

    for (const t of row.label ?? []) {
      const run = within(t.from ?? 0, t.until, row);
      if (run) textAt(t, x0 - 10, top + h / 2, "sm", "end", run);
    }
    for (const t of row.total ?? []) {
      const run = within(t.from ?? 0, t.until, row);
      if (run) textAt(t, X(start + row.length) + 10, top + h / 2, "lbl pw", "start", run);
    }
  });

  for (const b of spec.brackets ?? []) {
    const row = spec.rows[b.row]!, top = L.rowTops[b.row]!;
    const run = within(b.from ?? 0, b.until, row);
    if (!run) continue;
    const xa = X(b.a) + 2, xb = X(b.b) - 2, above = b.side === "above";
    const y = above ? top - 7 : top + h + 7, tick = above ? 6 : -6;
    push({ type: "path", d: `M${r1(xa)} ${r1(y + tick)} L${r1(xa)} ${r1(y)} L${r1(xb)} ${r1(y)} L${r1(xb)} ${r1(y + tick)}`, cls: "ax thin", enter: "draw", ...when(run.from, run.until) });
    const tw = textWidth(b.text, FS.bracket);
    const cx = Math.min(Math.max((xa + xb) / 2, M + tw / 2), L.width - M - tw / 2);
    push({ type: "text", x: r1(cx), y: r1(above ? y - 11 : y + 12), text: b.text, cls: b.acc ? "sm acc" : "sm", enter: "rise", delay: 0.2, ...when(run.from, run.until) });
  }

  for (const g of spec.guides ?? []) {
    const [r0, r1_] = g.rows;
    push({ type: "line", x1: X(g.at), y1: L.rowTops[r0]! - 4, x2: X(g.at), y2: L.rowTops[r1_]! + h + 4, cls: "wire", enter: "draw", ...when(g.from ?? 0) });
  }

  return { kind: "scene", family: "tape", width: L.width, height: L.height, items, alt: spec.alt };
}
