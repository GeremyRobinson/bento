// Tape diagrams and fraction bars: from a lesson's TapeSpec (computed from its problem) to a scene of shapes.
// One scale for every row, so bar lengths stay in proportion; text sizes, columns and row heights are worked out
// from the labels so nothing runs off the canvas or overlaps.
import type { SceneDiagram, SceneItem } from "../scene/schema";
import { r1 } from "../scene/helpers";
import type { Beats, TapeRow, TapeSpec, TapeText } from "./schema";
import { PIC } from "../scene/picture-system";

const M = 10; // outer margin
const BRACKET = 28; // room for a bracket and its text
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
  const gap = tapeGap(spec); // between rows: the same gap as between pieces (picture system)
  // labels read on one line ("2/3"), as in the model: a stacked fraction is taller than the gap between rows
  const stacked = false;
  const wOf = (t: TapeText, size: number) => {
    const m = stacked ? t.text.match(FRAC) : null;
    return m ? Math.max(m[1]!.length, m[2]!.length) * size * 0.6 + 8 : textWidth(t.text, size);
  };
  const labelMax = Math.max(0, ...rows.flatMap(r => (r.label ?? []).map(t => wOf(t, FS.label))));
  const labelW = labelMax ? labelMax + PIC.labelGap : 0;
  const x0 = M + labelW;
  const unitsWide = Math.max(...rows.map(r => (r.start ?? 0) + r.length));
  // one scale for every row: each bar plus its total must fit
  let unit = (W - M - x0) / unitsWide;
  for (const r of rows) {
    const tw = Math.max(0, ...(r.total ?? []).map(t => wOf(t, FS.total)));
    if (tw) unit = Math.min(unit, (W - M - x0 - PIC.labelGap - tw) / ((r.start ?? 0) + r.length));
  }
  const rowTops: number[] = [];
  let y = M;
  rows.forEach((row, i) => {
    const br = spec.brackets ?? [];
    // part text too big for its part goes outside under a leader: the room for it is kept like a bracket's
    const free = { below: !br.some(b => b.row === i && b.side === "below"), above: !br.some(b => b.row === i && b.side === "above") && i === 0 };
    const out = (row.each ?? []).map(e => eachFit(e, (row.length / layersAt(row, e.from ?? row.from ?? 0).count) * unit, rowHeight, layersAt(row, e.from ?? row.from ?? 0).count, free));
    if (br.some(b => b.row === i && b.side === "above") || out.includes("above")) y += BRACKET;
    rowTops.push(y);
    y += rowHeight;
    if (br.some(b => b.row === i && b.side === "below") || out.includes("below")) y += BRACKET;
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
  const pushLit = (lit: Beats[] | undefined, it: SceneItem) => { items.push(...litRuns(it, lit)); };
  const when = (from: number, until?: number) => ({ ...(from ? { from } : {}), ...(until != null ? { until } : {}) });

  // a label or total: a stacked fraction when there is room, otherwise one line
  const textAt = (t: TapeText, cx: number, cy: number, cls: string, anchor: "end" | "start" | "middle", run: { from: number; until?: number }) => {
    const m = L.stacked ? t.text.match(FRAC) : null;
    // a "?" is the unknown, so it's amber; a total that isn't is ink (the whole), never a part color
    const c = `${cls}${t.acc || t.text === "?" ? " acc" : ""}`;
    if (!m) {
      push({ type: "text", x: r1(cx), y: r1(cy), text: t.text, cls: `${c}${anchor === "middle" ? "" : ` ${anchor}`}`, enter: "rise", ...(t.delay ? { delay: t.delay } : {}), ...when(run.from, run.until) });
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
    const inset = (pw: number) => Math.min(tapeGap(spec) / 2, pw * 0.2);

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
    // the parts of each cut
    layers.forEach((lay, li) => {
      const pw = span(lay) * unit, ins = inset(pw), step = Math.min(0.06, 0.6 / lay.count);
      for (let i = 0; i < lay.count; i++) {
        push({ type: "rect", x: r1(X(start) + i * pw + ins), y: top, w: r1(pw - 2 * ins), h, rx: r1(Math.min(PIC.corner.bar, pw / 3, h / 4)), cls: "seg",
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
          const xb = Math.max(X(hi) - (Math.abs(hi - p1) < EPS ? ins : 0), Math.min(xa + MIN_FILL, X(p1) - ins));
          const dx = split ? splitDx(li, i) : 0;
          pushLit(fill.tone === "cut" ? undefined : row.lit, { type: "rect", x: r1(xa), y: top, w: r1(Math.max(0.5, xb - xa)), h, rx: r1(Math.min(PIC.corner.bar, (xb - xa) / 3, h / 4)),
            cls: fill.tone === "cut" ? "seg on cut" : fill.tone === "two" ? "seg on p1" : "seg on",
            ...(fill.tone === "acc" || dx ? { vars: { ...(fill.tone === "acc" ? { "--tint": "var(--acc)" } : {}), ...(dx ? { "--dx": `${dx}px` } : {}) } } : {}),
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
          push({ type: "text", x: r1(X(c)), y: r1(top + h / 2), text: e.text(i), cls: big ? (shaded ? "lbl res onmid" : "lbl res") : shaded ? "xs onlbl" : "xs", ...(k === 0 ? { enter: "rise" as const, delay: r1(((e.lead ?? 0) + shown.indexOf(i) * (e.stagger ?? 0.04)) * 100) / 100 } : {}), ...when(b, end) });
        });
      }
    }

    for (const t of row.label ?? []) {
      const run = within(t.from ?? 0, t.until, row);
      // side labels end one label gap before the bars, so a label held at its on-screen floor (phones) grows away
      // from its bar, never into it
      if (run) { const at = items.length; textAt(t, X(0) - PIC.labelGap, top + h / 2, "lbl", "end", run); items.splice(at, items.length - at, ...items.slice(at).flatMap(x => litRuns(x, row.lit))); }
    }
    for (const t of row.total ?? []) {
      const run = within(t.from ?? 0, t.until, row);
      if (run) textAt(t, X(start + row.length) + PIC.labelGap, top + h / 2, "lbl pw", "start", run);
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

  return { kind: "scene", family: "tape", width: L.width, height: L.height, items, alt: spec.alt, ...(spec.two ? { two: true } : {}) };
}
