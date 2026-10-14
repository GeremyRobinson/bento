// The number-line family (the current app's numberLine()): ticks, hops, points and highlighted stretches,
// every position computed from the values. Lessons pass values and beats; this decides all the geometry,
// including where labels go so that no two labels shown at the same time overlap.
import { formatNumber } from "../../../curriculum/schemas/math-text";
import type { SceneDiagram, SceneItem } from "../scene/schema";
import { r1 } from "../scene/helpers";
import { PIC, growDown, roomLeft, thinOut } from "../scene/picture-system";

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
  /** working the step under the picture already says: a phone's short box leaves the label out (.shortgo) */
  long?: boolean;
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
const MARGIN = 24;
/**
 * The line is drawn at about a phone's picture width (a box 280-310 wide), so its labels laid out here at their phone
 * size land where they are drawn; on a tablet the picture grows to its box and its text grows less (SceneDiagram).
 * Labels are laid out at the label floor (LBL); tick numbers at what the 14px text floor makes them on a phone (TICK).
 * On the smallest boxes a label still draws a little bigger than its units, so widths are checked GROWS bigger.
 */
const WIDTH = 330, LBL = PIC.label, TICK = 17, GROWS = 1.2, ROW = LBL * 1.2;
/** a stacked label's row k moves away from the line by what the k rows nearer it grew at the phone floor */
const rowShift = (dir: -1 | 1, k: number): Record<string, string> =>
  k <= 0 ? {} : dir > 0 ? growDown(k) : { transform: `translateY(calc(${-Math.round(k * 125) / 100} * (max(${LBL}, ${LBL} * var(--px, 0)) - ${LBL}) * 1px))` };
/** what hangs under the tick numbers moves down by what they grew at the 14px floor (they draw at 15 units) */
const UNDER_TICKS = { transform: "translateY(calc(0.7 * max(0, 14 * var(--px, 0) - 15) * 1px))" };
const under = (k: number): Record<string, string> => (k <= 0 ? UNDER_TICKS : { transform: `translateY(calc((0.7 * max(0, 14 * var(--px, 0) - 15) + ${Math.round(k * 125) / 100} * (max(${LBL}, ${LBL} * var(--px, 0)) - ${LBL})) * 1px))` });
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
  const W = spec.width ?? WIDTH;
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
  const widest = Math.max(...Array.from({ length: n + 1 }, (_, i) => textWidth(tickLabel(i), 15)));
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
  /**
   * finds a free spot for a label held by its edge nearest the line at `edge`, moving it away from the line (dir −1 up,
   * +1 down) a row at a time until nothing is in the way. The label is checked at its phone width; `row` is how many
   * rows it moved, so it can move on by what those rows grow on a phone (rowShift).
   */
  const place = (s: string, cx: number, edge: number, dir: -1 | 1, win: { from: number; until: number }) => {
    const w = textWidth(s, LBL) * GROWS, h = ROW;
    const box: Box & { row: number; edge: number } = { x: clampX(cx, textWidth(s, LBL)), y: edge + dir * h / 2, w, h, ...win, row: 0, edge };
    for (let k = 0; k < 8 && placed.some(o => meets(o, box)); k++) { box.y += dir * (h + 2); box.edge += dir * (h + 2); box.row++; }
    placed.push(box);
    return box;
  };

  const raw: Draft[] = [{ type: "line", x1: 16, y1: 0, x2: W - 16, y2: 0, cls: "ax", enter: "fade" }];
  const forced = labelAt.map(v => Math.round((v - min) / step)).filter(i => i >= 0 && i <= n);
  const clash = (i: number, j: number) => Math.abs(i - j) * px < (textWidth(tickLabel(i), TICK) + textWidth(tickLabel(j), TICK)) / 2 + 4;
  // regular labels sit on round values (multiples of every × step), not just every n-th tick from the left end
  const first = Math.round(min / step);
  const shown = (i: number) => forced.includes(i) || ((((first + i) % every) + every) % every === 0 && !forced.some(j => clash(i, j)));
  // where the floor still grows regular numbers into each other, every other one fades (the odd multiples first)
  const chars = Math.max(...Array.from({ length: n + 1 }, (_, i) => tickLabel(i).replace(/[−-]/, "").length + (/[−-]/.test(tickLabel(i)) ? 0.9 : 0)));
  const thin = (i: number) => {
    if (forced.includes(i)) return {};
    const k = Math.round((first + i) / every);
    if (!k) return {};
    const level = Math.abs(k) & -Math.abs(k);
    const near = forced.map(j => Math.abs(i - j) * px).filter(d => d < level * every * px);
    return { vars: thinOut(roomLeft(Math.min(level * every * px, ...near), chars, 15)) };
  };
  for (let i = 0; i <= n; i++) {
    const xv = r1(x(min + i * step)), delay = r1(i * 0.02 * Math.min(1, 24 / n));
    raw.push({ type: "line", x1: xv, y1: -6, x2: xv, y2: 6, cls: "tk", enter: "fade", delay });
    if (shown(i)) {
      placed.push({ x: xv, y: 22, w: textWidth(tickLabel(i), TICK), h: TICK * 1.2, from: 0, until: Infinity });
      raw.push({ type: "text", x: xv, y: 22, text: tickLabel(i), cls: "sm", enter: "fade", delay, ...thin(i) });
    }
  }
  const timing = (o: { beat: number; until?: number; delay?: number }, extra = 0) => ({
    from: o.beat,
    ...(o.until != null ? { until: o.until } : {}),
    ...(o.delay != null || extra ? { delay: r1((o.delay ?? 0) + extra) } : {}),
  });

  // which side of its point a mark's label sits: above any arc that passes over the mark, so the label never sits on a
  // hop; when hops only end at the mark, beside the point on the side away from them instead of floating over the arc
  const besideOf = (m: Mark): -1 | 0 | 1 => {
    if (!m.label || m.below) return 0;
    const up = hops.filter(h => !h.below && h.from !== h.to && Math.min(h.from, h.to) <= m.v && m.v <= Math.max(h.from, h.to));
    const ends = up.filter(h => Math.abs(h.from - m.v) < 1e-9 || Math.abs(h.to - m.v) < 1e-9);
    const away = new Set(ends.map(h => (Math.max(h.from, h.to) - m.v < 1e-9 ? 1 : -1)));
    const beside = up.length > 0 && ends.length === up.length && away.size === 1 ? [...away][0]! : 0;
    const lw = textWidth(m.label, LBL), bx = x(m.v) + beside * (lw / 2 + 6);
    return bx - lw / 2 < 2 || bx + lw / 2 > W - 2 ? 0 : (beside as -1 | 1); // no room beside it at the end of the line: back over the arcs
  };
  // a label beside its point sits on the line's own height, its bottom BESIDE above the axis, and grows away from the point
  const stacked = new Set<Mark>();
  const BESIDE = 10;
  /** a label's text item: held by its edge nearest the line (.up above it, .down under it), moved on by the rows it stepped */
  const textAt = (box: ReturnType<typeof place>, dir: -1 | 1, text: string, cls: string, extra: Record<string, string> = rowShift(dir, box.row)) =>
    ({ type: "text" as const, x: r1(box.x), y: r1(box.edge), text, cls: `${cls} ${dir < 0 ? "up" : "down"}`, vars: extra, enter: "rise" as const });

  // hops: arcs and dots, then labels; in a run of short hops a label that would hit its neighbour's is left off.
  // Arcs below the line hang from under the tick numbers, so they never run through them.
  const UNDER = 36;
  const hopLabels: Box[] = [];
  for (const h of hops) {
    if (h.from === h.to) continue;
    const x1 = x(h.from), x2 = x(h.to), hh = hopHeight(x2 - x1), mx = (x1 + x2) / 2, dir = h.below ? 1 : -1;
    if (h.start !== false) raw.push({ type: "circle", cx: r1(x1), cy: 0, r: 7, cls: "dotp", enter: "pop", ...timing(h) });
    const p1 = !!h.below;
    raw.push({ type: "arc", arc: { x1, x2, mx, c: dir * hh * 2, y0: h.below ? UNDER : 0 }, cls: p1 ? "ln p1" : "ln", enter: "draw", ...timing(h, 0.1) });
    if (h.land !== false) raw.push({ type: "circle", cx: r1(x2), cy: 0, r: 7, cls: p1 ? "dotp p1" : "dotp", enter: "pop", ...timing(h, 0.55) });
    if (!h.label) continue;
    const w = textWidth(h.label, LBL) * GROWS;
    // a short hop with a mark's label beside one of its ends (round's 46.499 → 46.5): its label stacks over that one,
    // lifted by what that label grows on a phone, so the two never meet at any size
    const nextTo = marks.find(m => besideOf(m) && (Math.abs(m.v - h.from) < 1e-9 || Math.abs(m.v - h.to) < 1e-9)
      && Math.abs(x(m.v) + besideOf(m) * (textWidth(m.label!, LBL) / 2 + BESIDE) - mx) < (w + textWidth(m.label!, LBL)) * 0.9);
    if (nextTo) stacked.add(nextTo);
    // a label stands on its arc (or hangs under one below the line)
    const edge = h.below ? UNDER + hh + 3 : -hh - 3;
    const probe: Box = { x: clampX(mx, w), y: edge + dir * 30, w, h: 60, ...windowOf(h) };
    if (hopLabels.some(o => meets(o, probe))) continue;
    if (nextTo) {
      // above that label, and lifted by what it grows (one row)
      const box = place(h.label, mx, Math.min(-hh - 3, -BESIDE - ROW - 2), -1, windowOf(h));
      hopLabels.push(box);
      raw.push({ ...textAt(box, -1, h.label, p1 ? "lbl p1" : "lbl", rowShift(-1, box.row + 1)), ...timing(h, 0.35) });
      continue;
    }
    const box = place(h.label, mx, edge, h.below ? 1 : -1, windowOf(h));
    hopLabels.push(box);
    raw.push({ ...textAt(box, h.below ? 1 : -1, h.label, p1 ? "lbl p1" : "lbl"), ...timing(h, 0.35) });
  }
  // span labels hang under the tick numbers (moving down by what those grow on a phone), or under any arcs below the line
  const belowArcs = hops.filter(h => h.below && h.from !== h.to);
  const belowDepth = Math.max(0, ...belowArcs.map(h => UNDER + hopHeight(x(h.to) - x(h.from)) + 3 + ROW + 4));
  const underEdge = Math.max(UNDER, belowDepth);
  const underVars = (box: ReturnType<typeof place>) => (belowArcs.length ? rowShift(1, box.row + 1) : under(box.row));
  for (const s of spans) {
    raw.push({ type: "line", x1: r1(x(s.from)), y1: 0, x2: r1(x(s.to)), y2: 0, cls: "hl", enter: "growx", ...timing(s) });
    if (!s.label) continue;
    const box = place(s.label, (x(s.from) + x(s.to)) / 2, underEdge, 1, windowOf(s));
    raw.push({ ...textAt(box, 1, s.label, "lbl acc", underVars(box)), ...timing(s, 0.3) });
  }
  for (const m of marks) {
    raw.push({ type: "circle", cx: r1(x(m.v)), cy: 0, r: 7, cls: m.cls ?? "dotp", enter: "pop", ...timing(m) });
    if (!m.label) continue;
    if (m.below) {
      // with the hops it counts: under the line, past the arcs and labels hanging there (review v45 blocker 4)
      const box = place(m.label, x(m.v), underEdge, 1, windowOf(m));
      raw.push({ ...textAt(box, 1, m.label, `lbl p1${m.long ? " shortgo" : ""}`, underVars(box)), ...timing(m, 0.2) });
      continue;
    }
    const beside = besideOf(m), lw = textWidth(m.label, LBL);
    if (beside && stacked.has(m)) {
      // beside its point: anchored at the point's edge, so a label held at its phone floor grows away from the dot
      placed.push({ x: x(m.v) + beside * (lw * GROWS / 2 + BESIDE), y: -BESIDE - ROW / 2, w: lw * GROWS, h: ROW, ...windowOf(m) });
      raw.push({ type: "text", x: r1(x(m.v) + beside * BESIDE), y: -BESIDE, text: m.label, cls: `lbl up ${beside < 0 ? "end" : "start"}${m.long ? " shortgo" : ""}`, enter: "rise", ...timing(m, 0.2) });
      continue;
    }
    const up = hops.filter(h => !h.below && h.from !== h.to && Math.min(h.from, h.to) <= m.v && m.v <= Math.max(h.from, h.to));
    // over the arcs that pass over it (clear of their own labels), else just over its dot
    const over = beside ? [] : up.map(h => hopHeight(Math.abs(x(h.to) - x(h.from))) + 6);
    const box = place(m.label, x(m.v) + beside * (lw / 2 + 6), -Math.max(11, ...over), -1, windowOf(m));
    raw.push({ ...textAt(box, -1, m.label, `lbl${m.long ? " shortgo" : ""}`), ...timing(m, 0.2) });
  }

  // fit the canvas around everything: an arc reaches half its control height, a label half its size
  const extent = (it: Draft): [number, number] => {
    switch (it.type) {
      case "arc": return [it.arc.y0 + Math.min(0, it.arc.c / 2), it.arc.y0 + Math.max(0, it.arc.c / 2)];
      case "text": return /\bup\b/.test(it.cls ?? "") ? [it.y - ROW, it.y] : /\bdown\b/.test(it.cls ?? "") ? [it.y, it.y + ROW] : [it.y - 11, it.y + 11];
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
      // a label that would run past either end of the picture is pinned to that edge instead of centred, so it stays
      // inside at any font size (a phone draws the picture smaller but its labels at a readable size; smoke: g6-lcm's
      // "60 ÷ 4 = 15 jumps" spilled its landing card)
      case "text": {
        const half = (/\blbl\b/.test(it.cls ?? "") ? textWidth(it.text, LBL) * GROWS : textWidth(it.text, TICK)) / 2, y = r1(it.y + dy);
        if (/\b(end|start)\b/.test(it.cls ?? "")) return { ...it, y };
        if (it.x + half > W - 4) return { ...it, x: W - 4, y, cls: `${it.cls ?? ""} end`.trim() };
        if (it.x - half < 4) return { ...it, x: 4, y, cls: `${it.cls ?? ""} start`.trim() };
        return { ...it, y };
      }
      default: return it;
    }
  });
  return { kind: "scene", family: "number-line", width: W, height: r1(bottom - top + 24), items, alt: spec.alt };
}
