// The coordinate plane family. Everything is computed from the problem's values: the window fits the points the
// lesson names, the grid step and tick labels follow the window, and labels are placed where they cover nothing.
import { formatNumber } from "../../../curriculum/schemas/math-text";
import type { SceneDiagram, SceneItem } from "../scene/schema";
import { arrowHead, r1 } from "../scene/helpers";
import type { PlaneItem, PlaneLabel, PlaneSpec, Pt, Side } from "./schema";

/** Longest side of the plot area (px) and the short side when the two axes have their own scales. */
const PLOT = 296, PLOT_SHORT = 232;
/** A picture drawn with one scale is never narrower than this ratio (so it stays readable when small). */
const MAX_RATIO = 1.3;
const FONT = { lbl: 17, xs: 12 } as const;
const DOT = 6.5;
/** How far (px) the canvas may grow on one side to fit a label. */
const MAX_GROW = 70;
/** How much a label should avoid covering a drawn line, per sampled point (axes count less). */
const LINE = 16, AXIS = 6;

interface Pads { l: number; r: number; t: number; b: number }
const NO_PADS: Pads = { l: 0, r: 0, t: 0, b: 0 };

/** 1, 2, 5, 10, 20, 50, ... : the smallest whole step that cuts `span` into at most `most` pieces. */
export function niceStep(span: number, most = 12): number {
  for (let e = 0; ; e++) for (const k of [1, 2, 5]) if (span / (k * 10 ** e) <= most) return k * 10 ** e;
}

/** Tick labels: grouped thousands so 48600 reads 48,600. */
export function tickText(v: number): string {
  const s = formatNumber(v), neg = s.startsWith("−"), body = neg ? s.slice(1) : s;
  if (Math.abs(v) < 1000 || body.includes(".")) return s;
  return (neg ? "−" : "") + body.replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

/** Rough width of a label in the app's rounded number font. */
export const textWidth = (s: string, size: number) => [...s].length * size * 0.6 + 4;

/** A range around [lo, hi] with room for labels, rounded out to a tidy unit. */
function extent(lo: number, hi: number): [number, number] {
  const span = Math.max(hi - lo, 1);
  const unit = span <= 8 ? 0.5 : span <= 40 ? 1 : niceStep(span) / 2;
  const pad = Math.max(span * 0.1, unit);
  return [Math.floor((lo - pad) / unit) * unit, Math.ceil((hi + pad) / unit) * unit];
}

/** The data points an item asks the window to show. */
function fitOf(it: PlaneItem): Pt[] {
  switch (it.kind) {
    case "point": case "label": case "rightAngle": case "angle": return [it.at];
    case "segment": return [it.a, it.b];
    case "circle": return [[it.c[0] - it.r, it.c[1] - it.r], [it.c[0] + it.r, it.c[1] + it.r]];
    case "area": {
      let top = 0, bottom = 0;
      for (let i = 0; i <= 40; i++) { const y = it.f(it.a + ((it.b - it.a) * i) / 40); if (Number.isFinite(y)) { top = Math.max(top, y); bottom = Math.min(bottom, y); } }
      return [[it.a, bottom], [it.b, top]];
    }
    default: return [];
  }
}

export interface PlaneFrame {
  x: [number, number];
  y: [number, number];
  /** pixels per unit on each axis */
  sx: number;
  sy: number;
  /** grid step and labelled step on each axis */
  step: [number, number];
  labelStep: [number, number];
  width: number;
  height: number;
  X: (v: number) => number;
  Y: (v: number) => number;
}

const labelEvery = (span: number, step: number) => step * ([1, 2, 5, 10].find(k => span / (step * k) <= 7) ?? 10);
const multiples = (lo: number, hi: number, k: number) => {
  const out: number[] = [];
  for (let v = Math.ceil(lo / k - 1e-9) * k; v <= hi + 1e-9; v += k) out.push(Math.round(v * 1e6) / 1e6);
  return out;
};
const clamp = (v: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, v));

/** Window, scales and canvas size for a spec. The window always shows the origin, so the axes are always drawn. */
export function planeFrame(spec: PlaneSpec, extra: Pads = NO_PADS): PlaneFrame {
  let x: [number, number], y: [number, number];
  if (spec.window) ({ x, y } = spec.window);
  else {
    const pts = [[0, 0] as Pt, ...spec.items.flatMap(fitOf), ...(spec.fit ?? [])].filter(p => Number.isFinite(p[0]) && Number.isFinite(p[1]));
    x = extent(Math.min(...pts.map(p => p[0])), Math.max(...pts.map(p => p[0])));
    y = extent(Math.min(...pts.map(p => p[1])), Math.max(...pts.map(p => p[1])));
    if (spec.equal) {
      const xr = x[1] - x[0], yr = y[1] - y[0];
      if (yr / xr > MAX_RATIO) { const g = (yr / MAX_RATIO - xr) / 2; x = [Math.floor(x[0] - g), Math.ceil(x[1] + g)]; }
      else if (xr / yr > MAX_RATIO) { const g = (xr / MAX_RATIO - yr) / 2; y = [Math.floor(y[0] - g), Math.ceil(y[1] + g)]; }
    }
  }
  const xr = x[1] - x[0], yr = y[1] - y[0], ratio = yr / xr;
  const same = spec.equal || (ratio > 0.6 && ratio < 1.6);
  const sx = same ? PLOT / Math.max(xr, yr) : PLOT / xr, sy = same ? sx : PLOT_SHORT / yr;
  const sxStep = same ? niceStep(Math.max(xr, yr)) : niceStep(xr), syStep = same ? sxStep : niceStep(yr, 10);
  const lx = labelEvery(xr, sxStep), ly = labelEvery(yr, syStep);

  // room for the tick labels: y labels sit left of the y-axis, x labels under the x-axis
  const ax = clamp(0, x[0], x[1]), ay = clamp(0, y[0], y[1]);
  const yLabels = multiples(y[0], y[1], ly).filter(v => v !== 0), xLabels = multiples(x[0], x[1], lx).filter(v => v !== 0);
  const wY = Math.max(0, ...yLabels.map(v => textWidth(tickText(v), FONT.xs)));
  const lastX = xLabels[xLabels.length - 1];
  let padL = Math.max(18, 10 + wY - (ax - x[0]) * sx);
  let padB = Math.max(18, 24 - (ay - y[0]) * sy);
  let padR = Math.max(18, lastX == null ? 0 : textWidth(tickText(lastX), FONT.xs) / 2 + 3 - (x[1] - lastX) * sx);
  const padT = 18 + extra.t;
  padL += extra.l; padR += extra.r; padB += extra.b;
  const width = padL + xr * sx + padR, height = padT + yr * sy + padB;
  return {
    x, y, sx, sy, step: [sxStep, syStep], labelStep: [lx, ly], width, height,
    X: v => padL + (v - x[0]) * sx,
    Y: v => padT + (y[1] - v) * sy,
  };
}

interface Box { x0: number; y0: number; x1: number; y1: number }
const overlap = (a: Box, b: Box) => a.x0 < b.x1 && b.x0 < a.x1 && a.y0 < b.y1 && b.y0 < a.y1;
const boxAt = (cx: number, cy: number, w: number, h: number): Box => ({ x0: cx - w / 2, y0: cy - h / 2, x1: cx + w / 2, y1: cy + h / 2 });
const grow = (b: Box, m: number): Box => ({ x0: b.x0 - m, y0: b.y0 - m, x1: b.x1 + m, y1: b.y1 + m });

const SIDES: Record<Side, [number, number]> = { n: [0, -1], s: [0, 1], e: [1, 0], w: [-1, 0], ne: [1, -1], nw: [-1, -1], se: [1, 1], sw: [-1, 1], c: [0, 0] };
const ORDER: Side[] = ["n", "ne", "e", "se", "s", "sw", "w", "nw"];

/**
 * Builds the scene. Pure: the same spec always gives the same picture.
 * A label that only fits outside the plot widens the canvas on that side, then the picture is laid out again.
 */
export function buildPlane(spec: PlaneSpec): SceneDiagram {
  let extra = NO_PADS;
  for (let pass = 0; ; pass++) {
    const { scene, over } = layout(spec, extra);
    if (pass === 2 || (over.l + over.r + over.t + over.b) < 1) return scene;
    extra = { l: extra.l + over.l, r: extra.r + over.r, t: extra.t + over.t, b: extra.b + over.b };
  }
}

function layout(spec: PlaneSpec, extra: Pads): { scene: SceneDiagram; over: Pads } {
  const F = planeFrame(spec, extra);
  const { X, Y, width: W, height: H } = F;
  const [x0, x1] = F.x, [y0, y1] = F.y;
  const inY = (v: number) => v >= y0 - 1e-9 && v <= y1 + 1e-9;

  const grid: SceneItem[] = [], ticks: SceneItem[] = [], axes: SceneItem[] = [], under: SceneItem[] = [], shapes: SceneItem[] = [], dots: SceneItem[] = [], texts: SceneItem[] = [];
  /** sampled pixel points of everything drawn, with how much a label should avoid them */
  const samples: { x: number; y: number; w: number }[] = [];
  const dotsAt: { x: number; y: number; r: number }[] = [];
  const pending: { anchors: [number, number][]; gap: number; label: PlaneLabel; from: number; until?: number; delay: number; rank: number }[] = [];

  const sampleLine = (pa: [number, number], pb: [number, number], w: number) => {
    const n = Math.max(1, Math.ceil(Math.hypot(pb[0] - pa[0], pb[1] - pa[1]) / 5));
    for (let i = 0; i <= n; i++) samples.push({ x: pa[0] + ((pb[0] - pa[0]) * i) / n, y: pa[1] + ((pb[1] - pa[1]) * i) / n, w });
  };
  const timing = (it: { from?: number; until?: number; delay?: number }) => ({
    ...(it.from ? { from: it.from } : {}), ...(it.until != null ? { until: it.until } : {}), ...(it.delay ? { delay: it.delay } : {}),
  });
  const queue = (anchor: [number, number] | [number, number][], gap: number, label: PlaneLabel | undefined, it: { from?: number; until?: number; delay?: number }, rank: number) => {
    if (label) pending.push({ anchors: typeof anchor[0] === "number" ? [anchor as [number, number]] : (anchor as [number, number][]), gap, label, from: label.from ?? it.from ?? 0, ...(it.until != null ? { until: it.until } : {}), delay: (it.delay ?? 0) + 0.25, rank });
  };

  // grid and axes
  for (const v of multiples(x0, x1, F.step[0])) grid.push({ type: "line", x1: r1(X(v)), y1: r1(Y(y0)), x2: r1(X(v)), y2: r1(Y(y1)), cls: "grid", enter: "fade" });
  for (const v of multiples(y0, y1, F.step[1])) grid.push({ type: "line", x1: r1(X(x0)), y1: r1(Y(v)), x2: r1(X(x1)), y2: r1(Y(v)), cls: "grid", enter: "fade" });
  const ax = clamp(0, x0, x1), ay = clamp(0, y0, y1);
  if (x0 <= 0 && x1 >= 0) { axes.push({ type: "path", d: `M${r1(X(0))} ${r1(Y(y0))} V${r1(Y(y1))}`, cls: "ax", enter: "draw" }); sampleLine([X(0), Y(y0)], [X(0), Y(y1)], AXIS); }
  if (y0 <= 0 && y1 >= 0) { axes.push({ type: "path", d: `M${r1(X(x0))} ${r1(Y(0))} H${r1(X(x1))}`, cls: "ax", enter: "draw" }); sampleLine([X(x0), Y(0)], [X(x1), Y(0)], AXIS); }

  // a polyline of f, cut cleanly at the window's top and bottom
  const trace = (f: (x: number) => number, a: number, b: number, n = 220): [number, number][][] => {
    const runs: [number, number][][] = [];
    let run: [number, number][] = [], prev: [number, number] | null = null;
    for (let i = 0; i <= n; i++) {
      const xv = a + ((b - a) * i) / n, yv = f(xv);
      const ok = Number.isFinite(yv) && inY(yv);
      if (ok) {
        if (!run.length && prev && Number.isFinite(prev[1])) {
          const yb = prev[1] > y1 ? y1 : y0, t = (yb - prev[1]) / (yv - prev[1]);
          run.push([prev[0] + t * (xv - prev[0]), yb]);
        }
        run.push([xv, yv]);
      } else if (run.length) {
        if (Number.isFinite(yv) && prev) {
          const yb = yv > y1 ? y1 : y0, t = (yb - prev[1]) / (yv - prev[1]);
          run.push([prev[0] + t * (xv - prev[0]), yb]);
        }
        runs.push(run); run = [];
      }
      prev = [xv, yv];
    }
    if (run.length) runs.push(run);
    return runs.filter(r => r.length > 1);
  };
  const pathOf = (runs: [number, number][][]) => runs.map(r => r.map(([xv, yv], i) => `${i ? "L" : "M"}${r1(X(xv))} ${r1(Y(yv))}`).join(" ")).join(" ");
  const sampleRuns = (runs: [number, number][][], w: number) => runs.forEach(r => r.slice(1).forEach((p, i) => sampleLine([X(r[i]![0]), Y(r[i]![1])], [X(p[0]), Y(p[1])], w)));
  /** where a curve's label may go: near x = `at` when given, otherwise a few places along it, best first */
  const anchorsOn = (runs: [number, number][][], at?: number): [number, number][] => {
    const all = runs.flat();
    if (!all.length) return [];
    const spread = [0.82, 0.62, 0.4, 0.18, 0.95].map(t => all[Math.floor((all.length - 1) * t)]!);
    // the asked-for spot first; the others are fallbacks for when that spot is crowded (near the origin, say)
    const ps = at == null ? spread : [all.reduce((best, q) => (Math.abs(q[0] - at) < Math.abs(best[0] - at) ? q : best)), ...spread];
    return ps.map(p => [X(p[0]), Y(p[1])]);
  };

  for (const it of spec.items) {
    const t = timing(it);
    switch (it.kind) {
      case "area": {
        const top = (xv: number) => clamp(it.f(xv), y0, y1);
        let d = `M${r1(X(it.a))} ${r1(Y(ay))}`;
        for (let i = 0; i <= 80; i++) { const xv = it.a + ((it.b - it.a) * i) / 80; d += ` L${r1(X(xv))} ${r1(Y(top(xv)))}`; }
        under.push({ type: "path", d: `${d} L${r1(X(it.b))} ${r1(Y(ay))} Z`, cls: "fill", enter: "growy", ...t });
        const lx = it.labelAt?.[0] ?? it.a + (it.b - it.a) * 0.72, ly = it.labelAt?.[1] ?? top(lx) * 0.4;
        queue([X(lx), Y(ly)], 0, it.label && { prefer: ["c", "w", "n"], ...it.label }, it, 1);
        break;
      }
      case "curve": case "line": {
        const runs = it.kind === "line" ? trace(v => it.m * v + it.b, x0, x1, 2) : trace(it.f, it.x0 ?? x0, it.x1 ?? x1);
        if (!runs.length) break;
        shapes.push({ type: "path", d: pathOf(runs), cls: it.cls ?? "ln", enter: it.kind === "curve" ? "draw slow" : "draw", ...t });
        sampleRuns(runs, LINE);
        const a = anchorsOn(runs, it.labelX);
        if (a.length) queue(a, 5, it.label, it, 1);
        break;
      }
      case "vline": {
        if (it.x < x0 || it.x > x1) break;
        shapes.push({ type: "path", d: `M${r1(X(it.x))} ${r1(Y(y0))} V${r1(Y(y1))}`, cls: it.cls ?? "ln", enter: "draw", ...t });
        sampleLine([X(it.x), Y(y0)], [X(it.x), Y(y1)], LINE);
        queue([X(it.x), Y(it.labelY ?? y0 + (y1 - y0) * 0.85)], 5, it.label && { prefer: ["e", "w"], ...it.label }, it, 1);
        break;
      }
      case "segment": {
        const pa: [number, number] = [X(it.a[0]), Y(it.a[1])], pb: [number, number] = [X(it.b[0]), Y(it.b[1])];
        const ang = Math.atan2(pb[1] - pa[1], pb[0] - pa[0]), len = Math.hypot(pb[0] - pa[0], pb[1] - pa[1]);
        const head = Math.min(13, Math.max(8, len * 0.4)), cut = it.arrow ? Math.min(head * 0.55, len / 2) : 0, end: [number, number] = [pb[0] - cut * Math.cos(ang), pb[1] - cut * Math.sin(ang)];
        const cls = it.cls ?? "ln";
        shapes.push({ type: "path", d: `M${r1(pa[0])} ${r1(pa[1])} L${r1(end[0])} ${r1(end[1])}`, cls, enter: it.slow ? "draw slow" : "draw", ...t });
        if (it.arrow && len > 1) shapes.push(arrowHead(r1(pb[0]), r1(pb[1]), ang, head, { cls: cls.includes("ln2") ? "dota" : "dotp", enter: "pop", ...t, delay: (it.delay ?? 0) + 0.6 }));
        sampleLine(pa, pb, LINE);
        // a label beside the middle, on whichever side is free
        const vertical = Math.abs(pb[0] - pa[0]) < 1, flat = Math.abs(pb[1] - pa[1]) < 1;
        queue([(pa[0] + pb[0]) / 2, (pa[1] + pb[1]) / 2], 4, it.label && { prefer: vertical ? ["e", "w"] : flat ? ["n", "s"] : ["nw", "se", "ne", "sw"], ...it.label }, it, 1);
        break;
      }
      case "circle": {
        const cx = X(it.c[0]), cy = Y(it.c[1]), rr = it.r * F.sx;
        shapes.push({ type: "path", d: `M${r1(cx)} ${r1(cy - rr)} A${r1(rr)} ${r1(rr)} 0 1 1 ${r1(cx)} ${r1(cy + rr)} A${r1(rr)} ${r1(rr)} 0 1 1 ${r1(cx)} ${r1(cy - rr)}`, cls: it.cls ?? "ln", enter: "draw slow", ...t });
        const n = Math.max(24, Math.ceil((2 * Math.PI * rr) / 5));
        for (let i = 0; i < n; i++) samples.push({ x: cx + rr * Math.cos((2 * Math.PI * i) / n), y: cy + rr * Math.sin((2 * Math.PI * i) / n), w: LINE });
        break;
      }
      case "rightAngle": case "angle": {
        const px = X(it.at[0]), py = Y(it.at[1]);
        const unit = (d: Pt) => { const vx = d[0] * F.sx, vy = -d[1] * F.sy, l = Math.hypot(vx, vy) || 1; return [vx / l, vy / l] as const; };
        const u = unit(it.u), v = unit(it.v);
        if (it.kind === "rightAngle") {
          const s = 12;
          shapes.push({ type: "path", d: `M${r1(px + s * u[0])} ${r1(py + s * u[1])} L${r1(px + s * (u[0] + v[0]))} ${r1(py + s * (u[1] + v[1]))} L${r1(px + s * v[0])} ${r1(py + s * v[1])}`, cls: "ax thin", enter: "fade", ...t });
        } else {
          const R = 26, a1 = Math.atan2(u[1], u[0]);
          let turn = Math.atan2(v[1], v[0]) - a1;
          while (turn <= -Math.PI) turn += 2 * Math.PI;
          while (turn > Math.PI) turn -= 2 * Math.PI;
          const a2 = a1 + turn, mid = a1 + turn / 2;
          shapes.push({ type: "path", d: `M${r1(px + R * Math.cos(a1))} ${r1(py + R * Math.sin(a1))} A${R} ${R} 0 0 ${turn > 0 ? 1 : 0} ${r1(px + R * Math.cos(a2))} ${r1(py + R * Math.sin(a2))}`, cls: it.cls ?? "ln2", enter: "draw", ...t });
          for (let i = 0; i <= 8; i++) samples.push({ x: px + R * Math.cos(a1 + (turn * i) / 8), y: py + R * Math.sin(a1 + (turn * i) / 8), w: LINE });
          queue([px + (R + 4) * Math.cos(mid), py + (R + 4) * Math.sin(mid)], 6, it.label && { prefer: [nearestSide(Math.cos(mid), Math.sin(mid))], ...it.label }, it, 1);
        }
        break;
      }
      case "point": {
        const px = X(it.at[0]), py = Y(it.at[1]), r = it.small ? 5 : DOT;
        dots.push({ type: "circle", cx: r1(px), cy: r1(py), r, cls: it.cls ?? "dotp", enter: "pop", ...t });
        dotsAt.push({ x: px, y: py, r: r + 2 });
        queue([px, py], r, it.label, it, 0);
        break;
      }
      case "label":
        queue([X(it.at[0]), Y(it.at[1])], 2, it.label, it, 1);
        break;
    }
  }

  // labels: points first, each where it covers the least
  const placed: Box[] = [];
  const tickBoxes: Box[] = [];
  const xTicks = multiples(x0, x1, F.labelStep[0]).filter(v => v !== 0), yTicks = multiples(y0, y1, F.labelStep[1]).filter(v => v !== 0);
  const xTick = xTicks.map(v => ({ v, s: tickText(v), cx: X(v), cy: Y(ay) + 14 }));
  const yTick = yTicks.map(v => ({ v, s: tickText(v), cx: X(ax) - 7, cy: Y(v) }));
  xTick.forEach(t => tickBoxes.push(boxAt(t.cx, t.cy, textWidth(t.s, FONT.xs), FONT.xs * 1.1)));
  yTick.forEach(t => { const w = textWidth(t.s, FONT.xs); tickBoxes.push(boxAt(t.cx - w / 2, t.cy, w, FONT.xs * 1.1)); });

  const score = (b: Box) => {
    let s = 0;
    const out = Math.max(0, 2 - b.x0) + Math.max(0, 2 - b.y0) + Math.max(0, b.x1 - (W - 2)) + Math.max(0, b.y1 - (H - 2));
    if (out > MAX_GROW) s += 1000;
    else if (out > 0) s += 6 + out * 0.5;
    // labels keep a little air between them: two labels touching near the origin read as one
    for (const p of placed) if (overlap(b, p)) s += 500; else if (overlap(b, grow(p, 5))) s += 60;
    for (const d of dotsAt) if (overlap(b, { x0: d.x - d.r, y0: d.y - d.r, x1: d.x + d.r, y1: d.y + d.r })) s += 300;
    // a line just under or over a label reads as crossing it, so lines keep a little room above and below
    for (const p of samples) if (p.x > b.x0 - 2 && p.x < b.x1 + 2 && p.y > b.y0 - 3 && p.y < b.y1 + 3) s += p.w;
    for (const tb of tickBoxes) if (overlap(b, tb)) s += 4;
    return s;
  };
  for (const q of [...pending].sort((a, b) => a.rank - b.rank)) {
    const size = FONT.lbl, w = textWidth(q.label.text, size), h = size * 1.15;
    const prefer = q.label.prefer ?? [];
    const sides = [...prefer, ...ORDER.filter(s => !prefer.includes(s))];
    let best: { b: Box; cx: number; cy: number; s: number } | null = null;
    for (const [ai, anchor] of q.anchors.entries()) for (const ring of [0, 14, 30]) {
      sides.forEach((side, k) => {
        const [ux, uy] = SIDES[side];
        if (side === "c" && ring) return;
        const diag = ux !== 0 && uy !== 0;
        const cx = anchor[0] + ux * ((diag ? q.gap * 0.7 : q.gap) + 4 + ring + w / 2);
        const cy = anchor[1] + uy * ((diag ? q.gap * 0.7 : q.gap) + 3 + ring + h / 2);
        const b = boxAt(cx, cy, w, h);
        const s = score(b) + (k < prefer.length ? k : 10 + k) + ring + ai * 3;
        if (!best || s < best.s) best = { b, cx, cy, s };
      });
    }
    const chosen = best as { b: Box; cx: number; cy: number; s: number } | null;
    if (!chosen || (q.label.optional && chosen.s >= 40)) continue;
    placed.push(chosen.b);
    texts.push({
      type: "text", x: r1(chosen.cx), y: r1(chosen.cy), text: q.label.text, cls: `lbl${q.label.acc ? " acc" : q.label.part != null ? ` p${q.label.part}` : ""}`, enter: "rise",
      ...(q.from ? { from: q.from } : {}), ...(q.until != null ? { until: q.until } : {}), delay: q.delay,
    });
  }

  // tick labels that would sit under a label or a dot are left out
  const free = (b: Box) => !placed.some(p => overlap(b, p)) && !dotsAt.some(d => overlap(b, { x0: d.x - d.r, y0: d.y - d.r, x1: d.x + d.r, y1: d.y + d.r }))
    && !samples.some(p => p.w >= LINE && p.x > b.x0 - 1 && p.x < b.x1 + 1 && p.y > b.y0 - 1 && p.y < b.y1 + 1);
  xTick.forEach((t, i) => { if (free(tickBoxes[i]!)) ticks.push({ type: "text", x: r1(t.cx), y: r1(t.cy), text: t.s, cls: "xs", enter: "fade", delay: 0.3 }); });
  yTick.forEach((t, i) => { if (free(tickBoxes[xTick.length + i]!)) ticks.push({ type: "text", x: r1(t.cx), y: r1(t.cy), text: t.s, cls: "xs end", enter: "fade", delay: 0.3 }); });

  const over: Pads = { l: 0, r: 0, t: 0, b: 0 };
  for (const b of placed) {
    over.l = Math.max(over.l, 3 - b.x0); over.t = Math.max(over.t, 3 - b.y0);
    over.r = Math.max(over.r, b.x1 - (W - 3)); over.b = Math.max(over.b, b.y1 - (H - 3));
  }
  return { scene: { kind: "scene", family: "plane", width: r1(W), height: r1(H), items: [...grid, ...under, ...axes, ...ticks, ...shapes, ...dots, ...texts], alt: spec.alt }, over };
}

function nearestSide(c: number, s: number): Side {
  const a = Math.atan2(-s, c), k = Math.round(a / (Math.PI / 4));
  return (["e", "ne", "n", "nw", "w", "sw", "s", "se"] as Side[])[(k + 8) % 8]!;
}

/** "(3, −4)" */
export const coord = (x: number, y: number) => `(${formatNumber(x)}, ${formatNumber(y)})`;
