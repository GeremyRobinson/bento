// The number-line family (the current app's numberLine()): ticks, hops, points and highlighted stretches,
// every position computed from the values. Lessons pass values and beats; this decides all the geometry,
// including where labels go so that no two labels shown at the same time overlap.
import { formatNumber } from "../../../curriculum/schemas/math-text";
import type { SceneDiagram, SceneItem } from "../scene/schema";
import { r1 } from "../scene/helpers";

/** A jump along the line, drawn as an arc. Hops below the line count the other way: what's taken away, part orange. */
export interface Hop {
  from: number;
  to: number;
  label?: string;
  below?: boolean;
  beat: number;
  until?: number;
  /** stagger within the beat, in seconds */
  delay?: number;
  /** draw a dot where the hop starts (default true) */
  start?: boolean;
  /** draw a dot where it lands (default true) */
  land?: boolean;
}

/** A point on the line, with an optional label above it. */
export interface Mark {
  v: number;
  label?: string;
  beat: number;
  until?: number;
  delay?: number;
  cls?: "dotp" | "dota" | "hole";
  /** the label goes under the line, below the hops drawn there, in their part colour: for a label that counts those hops */
  below?: boolean;
}

/** A highlighted stretch of the line (the original's `seg`), with an optional label under the tick numbers. */
export interface Span {
  from: number;
  to: number;
  beat: number;
  until?: number;
  label?: string;
}

export interface NumberLineSpec {
  min: number;
  max: number;
  /** distance between ticks (default 1) */
  step?: number;
  /** label every n-th tick; default: as often as the labels fit */
  every?: number;
  /** tick values that are always labelled (e.g. a halfway mark); regular labels that would touch them step aside */
  labelAt?: number[];
  width?: number;
  hops?: Hop[];
  marks?: Mark[];
  spans?: Span[];
  alt: string;
}

/** Rough width of a label in the picture's number font. */
export const textWidth = (s: string, size = 15) => s.length * size * 0.6 + 4;

const round6 = (x: number) => Math.round(x * 1e6) / 1e6;
const MARGIN = 30;
/** how tall an arc gets for a jump of dx pixels (the current app's rule) */
export const hopHeight = (dx: number) => Math.min(56, Math.abs(dx) * 0.45 + 12);

/**
 * Picks min, max and tick step so every value fits with at most `maxTicks` ticks, using steps of 1, 2 or 5 × 10ⁿ.
 * `pad` adds that many ticks of room at each end; `minStep` keeps whole-number lines from getting fractional ticks.
 */
export function fitRange(values: number[], opts: { maxTicks?: number; pad?: number; minStep?: number } = {}): { min: number; max: number; step: number } {
  const { maxTicks = 24, pad = 1, minStep = 1e-6 } = opts;
  if (!values.length) throw new Error("fitRange needs at least one value");
  const lo = Math.min(...values), hi = Math.max(...values);
  for (let e = -6; e <= 9; e++) {
    for (const m of [1, 2, 5]) {
      const step = round6(m * 10 ** e);
      if (step < minStep - 1e-9) continue;
      const min = round6(Math.floor(round6(lo / step)) * step - pad * step);
      const max = round6(Math.ceil(round6(hi / step)) * step + pad * step);
      if ((max - min) / step <= maxTicks + 1e-9) return { min, max, step };
    }
  }
  throw new Error("values too far apart for a number line");
}

type Box = { x: number; y: number; w: number; h: number; from: number; until: number };
type Arc = { x1: number; x2: number; mx: number; c: number; y0: number };
type Draft = SceneItem | (Omit<Extract<SceneItem, { type: "path" }>, "type" | "d"> & { type: "arc"; arc: Arc });

/** Builds the scene. Throws when a value lies off the line, so a lesson can never draw a wrong picture silently. */
export function buildNumberLine(spec: NumberLineSpec): SceneDiagram {
  const { min, max, step = 1, hops = [], marks = [], spans = [], labelAt = [] } = spec;
  const W = spec.width ?? 520;
  if (!(max > min)) throw new Error(`number line needs max > min (got ${min}..${max})`);
  const n = Math.round((max - min) / step);
  if (Math.abs(n * step - (max - min)) > 1e-6) throw new Error("the range must be a whole number of steps");
  const inside = (v: number) => v >= min - 1e-9 && v <= max + 1e-9;
  for (const v of [...hops.flatMap(h => [h.from, h.to]), ...marks.map(m => m.v), ...spans.flatMap(s => [s.from, s.to])]) {
    if (!inside(v)) throw new Error(`${v} is off the number line ${min}..${max}`);
  }
  const x = (v: number) => MARGIN + ((v - min) / (max - min)) * (W - 2 * MARGIN);
  const px = (W - 2 * MARGIN) / n;

  // tick labels as often as they fit
  const tickLabel = (i: number) => formatNumber(round6(min + i * step));
  const widest = Math.max(...Array.from({ length: n + 1 }, (_, i) => textWidth(tickLabel(i))));
  let every = spec.every ?? 1;
  if (spec.every == null) {
    const options = [1, 2, 5, 10, 20, 25, 50, 100, 200, 500, 1000];
    every = options.find(k => k * px >= widest + 6) ?? n;
  }

  // Everything is laid out with the axis at height 0 (negative is up), then moved down to fit the canvas.
  const placed: Box[] = [];
  const meets = (a: Box, b: Box) => a.from <= b.until && b.from <= a.until
    && Math.abs(a.x - b.x) < (a.w + b.w) / 2 + 2 && Math.abs(a.y - b.y) < (a.h + b.h) / 2 + 1;
  const windowOf = (o: { beat: number; until?: number }) => ({ from: o.beat, until: o.until ?? Infinity });
  const clampX = (cx: number, w: number) => Math.min(W - w / 2 - 2, Math.max(w / 2 + 2, cx));
  /** finds a free spot for a label, moving away from the line (dir −1 up, +1 down) until nothing is in the way */
  const place = (s: string, cx: number, y0: number, dir: -1 | 1, size: number, win: { from: number; until: number }) => {
    const w = textWidth(s, size), h = size + 4;
    const box: Box = { x: clampX(cx, w), y: y0, w, h, ...win };
    for (let k = 0; k < 8 && placed.some(o => meets(o, box)); k++) box.y += dir * (h + 2);
    placed.push(box);
    return box;
  };

  const raw: Draft[] = [{ type: "line", x1: 16, y1: 0, x2: W - 16, y2: 0, cls: "ax", enter: "fade" }];
  const forced = labelAt.map(v => Math.round((v - min) / step)).filter(i => i >= 0 && i <= n);
  const clash = (i: number, j: number) => Math.abs(i - j) * px < (textWidth(tickLabel(i)) + textWidth(tickLabel(j))) / 2 + 4;
  // regular labels sit on round values (multiples of every × step), not just every n-th tick from the left end
  const first = Math.round(min / step);
  const shown = (i: number) => forced.includes(i) || ((((first + i) % every) + every) % every === 0 && !forced.some(j => clash(i, j)));
  for (let i = 0; i <= n; i++) {
    const xv = r1(x(min + i * step)), delay = r1(i * 0.02 * Math.min(1, 24 / n));
    raw.push({ type: "line", x1: xv, y1: -6, x2: xv, y2: 6, cls: "tk", enter: "fade", delay });
    if (shown(i)) {
      placed.push({ x: xv, y: 22, w: textWidth(tickLabel(i)), h: 18, from: 0, until: Infinity });
      raw.push({ type: "text", x: xv, y: 22, text: tickLabel(i), cls: "sm", enter: "fade", delay });
    }
  }
  const timing = (o: { beat: number; until?: number; delay?: number }, extra = 0) => ({
    from: o.beat,
    ...(o.until != null ? { until: o.until } : {}),
    ...(o.delay != null || extra ? { delay: r1((o.delay ?? 0) + extra) } : {}),
  });

  // hops: arcs and dots, then labels; in a run of short hops a label that would hit its neighbour's is left off.
  // Arcs below the line hang from under the tick numbers, so they never run through them.
  const UNDER = 34;
  const hopLabels: Box[] = [];
  for (const h of hops) {
    if (h.from === h.to) continue;
    const x1 = x(h.from), x2 = x(h.to), hh = hopHeight(x2 - x1), mx = (x1 + x2) / 2, dir = h.below ? 1 : -1;
    if (h.start !== false) raw.push({ type: "circle", cx: r1(x1), cy: 0, r: 7, cls: "dotp", enter: "pop", ...timing(h) });
    const p1 = !!h.below;
    raw.push({ type: "arc", arc: { x1, x2, mx, c: dir * hh * 2, y0: h.below ? UNDER : 0 }, cls: p1 ? "ln p1" : "ln", enter: "draw", ...timing(h, 0.1) });
    if (h.land !== false) raw.push({ type: "circle", cx: r1(x2), cy: 0, r: 7, cls: p1 ? "dotp p1" : "dotp", enter: "pop", ...timing(h, 0.55) });
    if (!h.label) continue;
    const w = textWidth(h.label, 17), ly = h.below ? UNDER + hh + 14 : -hh - 14;
    const probe: Box = { x: clampX(mx, w), y: ly, w, h: 60, ...windowOf(h) };
    if (hopLabels.some(o => meets(o, probe))) continue;
    const box = place(h.label, mx, ly, h.below ? 1 : -1, 17, windowOf(h));
    hopLabels.push(box);
    raw.push({ type: "text", x: r1(box.x), y: r1(box.y), text: h.label, cls: p1 ? "lbl p1" : "lbl", enter: "rise", ...timing(h, 0.35) });
  }
  // span labels go under the tick numbers, and under any arcs below the line
  const belowDepth = Math.max(0, ...hops.filter(h => h.below && h.from !== h.to).map(h => UNDER + hopHeight(x(h.to) - x(h.from)) + 14 + 22));
  for (const s of spans) {
    raw.push({ type: "line", x1: r1(x(s.from)), y1: 0, x2: r1(x(s.to)), y2: 0, cls: "hl", enter: "growx", ...timing(s) });
    if (!s.label) continue;
    const box = place(s.label, (x(s.from) + x(s.to)) / 2, Math.max(44, belowDepth), 1, 17, windowOf(s));
    raw.push({ type: "text", x: r1(box.x), y: r1(box.y), text: s.label, cls: "lbl acc", enter: "rise", ...timing(s, 0.3) });
  }
  for (const m of marks) {
    raw.push({ type: "circle", cx: r1(x(m.v)), cy: 0, r: 7, cls: m.cls ?? "dotp", enter: "pop", ...timing(m) });
    if (!m.label) continue;
    if (m.below) {
      // with the hops it counts: under the line, past the arcs and labels hanging there (review v45 blocker 4)
      const box = place(m.label, x(m.v), Math.max(44, belowDepth), 1, 17, windowOf(m));
      raw.push({ type: "text", x: r1(box.x), y: r1(box.y), text: m.label, cls: "lbl p1", enter: "rise", ...timing(m, 0.2) });
      continue;
    }
    // above any arc that passes over the mark, so the label never sits on a hop; when hops only end at the mark,
    // the label sits beside the point on the side away from them instead of floating over the arc
    const up = hops.filter(h => !h.below && h.from !== h.to && Math.min(h.from, h.to) <= m.v && m.v <= Math.max(h.from, h.to));
    const ends = up.filter(h => Math.abs(h.from - m.v) < 1e-9 || Math.abs(h.to - m.v) < 1e-9);
    const away = new Set(ends.map(h => (Math.max(h.from, h.to) - m.v < 1e-9 ? 1 : -1)));
    let beside = up.length > 0 && ends.length === up.length && away.size === 1 ? [...away][0]! : 0;
    const lw = textWidth(m.label, 17), bx = x(m.v) + beside * (lw / 2 + 6);
    if (bx - lw / 2 < 2 || bx + lw / 2 > W - 2) beside = 0; // no room beside it at the end of the line: back over the arcs
    const over = beside ? [] : up.map(h => hopHeight(Math.abs(x(h.to) - x(h.from))) + 30);
    const box = place(m.label, x(m.v) + beside * (lw / 2 + 6), -Math.max(22, ...over), -1, 17, windowOf(m));
    raw.push({ type: "text", x: r1(box.x), y: r1(box.y), text: m.label, cls: "lbl", enter: "rise", ...timing(m, 0.2) });
  }

  // fit the canvas around everything: an arc reaches half its control height, a label half its size
  const extent = (it: Draft): [number, number] => {
    switch (it.type) {
      case "arc": return [it.arc.y0 + Math.min(0, it.arc.c / 2), it.arc.y0 + Math.max(0, it.arc.c / 2)];
      case "text": return [it.y - 11, it.y + 11];
      case "circle": return [it.cy - it.r, it.cy + it.r];
      case "line": return [Math.min(it.y1, it.y2), Math.max(it.y1, it.y2)];
      default: return [0, 0];
    }
  };
  const top = Math.min(...raw.map(it => extent(it)[0])), bottom = Math.max(...raw.map(it => extent(it)[1]));
  const dy = r1(12 - top);
  const items: SceneItem[] = raw.map((it): SceneItem => {
    switch (it.type) {
      case "arc": {
        const { arc, type: _t, ...rest } = it;
        const y = r1(dy + arc.y0);
        return { ...rest, type: "path", d: `M${r1(arc.x1)} ${y} Q${r1(arc.mx)} ${r1(y + arc.c)} ${r1(arc.x2)} ${y}` };
      }
      case "line": return { ...it, y1: r1(it.y1 + dy), y2: r1(it.y2 + dy) };
      case "circle": return { ...it, cy: r1(it.cy + dy) };
      case "text": return { ...it, y: r1(it.y + dy) };
      default: return it;
    }
  });
  return { kind: "scene", family: "number-line", width: W, height: r1(bottom - top + 24), items, alt: spec.alt };
}
