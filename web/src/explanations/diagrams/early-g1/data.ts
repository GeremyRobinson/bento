// Data pictures for 1st to 3rd grade (design/pictures-k4.md §6): tally charts, picture graphs (one picture per thing, or a
// key that makes each picture stand for more, with half pictures) and scaled bar graphs. Rows never show their counts in
// practice; each row or bar takes its own grade color, like the older lessons' parts.
import type { SceneDiagram } from "../scene/schema";
import { frame, path, t, M, L, Z, type Draft, type Pt, type Seg } from "../geo/kit";
import { P, tint } from "../early-k/fit";

export type Icon = "apple" | "paw" | "star" | "cookie";
type Timing = { from?: number; until?: number; enter?: Draft["enter"]; delay?: number };

const circlePts = (c: Pt, r: number, n = 24): Pt[] => Array.from({ length: n }, (_, i) => [c[0] + r * Math.cos((2 * Math.PI * i) / n), c[1] + r * Math.sin((2 * Math.PI * i) / n)]);
const starPts = (c: Pt, r: number): Pt[] => Array.from({ length: 10 }, (_, i) => {
  const a = -Math.PI / 2 + (Math.PI * i) / 5, rr = i % 2 ? r * 0.45 : r;
  return [c[0] + rr * Math.cos(a), c[1] + rr * Math.sin(a)];
});

/** the part of a polygon left of the vertical line x = cx */
function leftHalf(pts: Pt[], cx: number): Pt[] {
  const out: Pt[] = [];
  pts.forEach((p, i) => {
    const q = pts[(i + 1) % pts.length]!, pin = p[0] <= cx, qin = q[0] <= cx;
    if (pin) out.push(p);
    if (pin !== qin) out.push([cx, p[1] + ((cx - p[0]) * (q[1] - p[1])) / (q[0] - p[0])]);
  });
  return out;
}
const polySegs = (pts: Pt[]): Seg[] => [M(pts[0]!), ...pts.slice(1).map(L), Z];

/** one picture (about 28 across) at (x, y), or its left half */
export function icon(kind: Icon, x: number, y: number, cls: string, o: Timing, half = false): Draft[] {
  const main = kind === "star" ? starPts([x, y], 14) : kind === "paw" ? circlePts([x, y + 4], 9) : circlePts([x, y + (kind === "apple" ? 2 : 0)], 13);
  const shape = path(polySegs(half ? leftHalf(main, x) : main), cls, o);
  if (half) return [shape];
  const extra: Draft[] = [];
  if (kind === "apple") extra.push(path([M([x, y - 10]), L([x + 2, y - 15])], `${cls}-line`, o), path(polySegs(circlePts([x + 6, y - 13], 3.5, 10)), cls, o));
  if (kind === "paw") for (const [dx, dy] of [[-9, -8], [0, -12], [9, -8]]) extra.push(path(polySegs(circlePts([x + dx!, y + dy!], 4, 10)), cls, o));
  if (kind === "cookie") for (const [dx, dy] of [[-5, -4], [4, -2], [-1, 5]]) extra.push({ type: "circle", cx: x + dx!, cy: y + dy!, r: 2.2, cls: "pin", ...o } as Draft);
  return [shape, ...extra];
}

const nameW = (s: string) => [...s].length * 15 * 0.58;

export interface RowsSpec {
  kind: "tally" | "pictures";
  title: string;
  names: string[];
  counts: number[];
  icon: Icon;
  /** pictures only: each picture stands for this many (a key shows under the graph when it's more than 1) */
  scale?: number;
  /** the word for the things, for the key */
  things?: string;
  /**
   * beats: rows fill one mark or picture at a time; rows read (their counts written at the end); the extra pictures
   * of `more[0]` over `more[1]` lit and counted. Leave out for practice.
   */
  beats?: { fill: number; read?: number; more?: number };
  read?: number[];
  more?: [number, number];
  alt: string;
}

const PITCH = 36, ROW = 46;

export function buildRows(s: RowsSpec): SceneDiagram {
  const items: Draft[] = [], b = s.beats, scale = s.scale ?? 1, colX = Math.max(...s.names.map(nameW)) + 46;
  items.push(t(0, -36, s.title, "sm start"));
  s.names.forEach((name, r) => {
    const y = r * ROW, n = s.counts[r]!;
    items.push(t(colX - 16, y, name, "sm end"));
    items.push({ type: "line", x1: colX - 4, y1: y - ROW / 2 + 2, x2: colX - 4, y2: y + ROW / 2 - 2, cls: "grid" } as Draft);
    let last = colX;
    const o = (k: number): Timing => (b ? { from: b.fill, enter: "pop", delay: 0.12 * k + 0.3 * r } : {});
    if (s.kind === "tally") {
      for (let k = 0; k < n; k++) {
        const bundle = Math.floor(k / 5), j = k % 5, x0 = colX + 12 + bundle * 64;
        if (j < 4) items.push(path([M([x0 + j * 10, y - 14]), L([x0 + j * 10, y + 14])], `tally ${P(r)}`, o(k)));
        else items.push(path([M([x0 - 6, y + 10]), L([x0 + 36, y - 10])], `tally ${P(r)}`, o(k)));
        last = x0 + (j < 4 ? j * 10 : 36);
      }
    } else {
      const whole = Math.floor(n / scale), half = n % scale !== 0;
      for (let k = 0; k < whole + (half ? 1 : 0); k++) {
        const x = colX + 18 + k * PITCH;
        items.push(...tint(icon(s.icon, x, y, "glyph", o(k), half && k === whole), r));
        last = x + 14;
      }
    }
    if (b?.read != null && s.read?.includes(r)) {
      items.push({ type: "rect", x: colX - 2, y: y - ROW / 2 + 4, w: last - colX + 16, h: ROW - 8, rx: (ROW - 8) / 2, cls: "hlrow", from: b.read, enter: "fade" } as Draft);
      items.push(t(last + 26, y, String(n), "lbl big start", { from: b.read, enter: "rise", delay: 0.4 }));
    }
  });
  if (b?.more != null && s.more && s.kind === "pictures") {
    const [hi, lo] = s.more, y = hi * ROW, from = Math.floor(s.counts[lo]! / scale);
    for (let k = from; k < Math.floor(s.counts[hi]! / scale); k++) {
      const x = colX + 18 + k * PITCH;
      items.push(...icon(s.icon, x, y, "glyph acc", { from: b.more, enter: "pop", delay: 0.3 * (k - from) }));
      items.push(t(x, y + 24, String(k - from + 1), "xs", { from: b.more, enter: "fade", delay: 0.3 * (k - from) }));
    }
    items.push({ type: "line", x1: colX + 18 + from * PITCH - PITCH / 2, y1: Math.min(hi, lo) * ROW - 22, x2: colX + 18 + from * PITCH - PITCH / 2, y2: Math.max(hi, lo) * ROW + 22, cls: "ln2 dash", from: b.more, enter: "draw" } as Draft);
  }
  // every graph of a kind is as wide as the fullest one can be, so pictures stay one size from problem to problem
  const right = s.kind === "tally" ? colX + 12 + 2 * 64 + 36 + 44 : colX + 18 + (Math.max(9, Math.ceil(Math.max(...s.counts) / scale)) - 1) * PITCH + 44;
  items.push({ type: "line", x1: right, y1: 0, x2: right, y2: 0, cls: "spacer" } as Draft);
  if (scale > 1 && s.kind === "pictures") {
    const y = s.names.length * ROW - 6, label = `= ${scale} ${s.things ?? ""}`.trim();
    const w = 40 + nameW(label);
    items.push({ type: "rect", x: colX + 4, y: y - 16, w, h: 32, rx: 16, cls: "keypill" } as Draft);
    items.push(...icon(s.icon, colX + 22, y, "glyph", {}));
    items.push(t(colX + 40, y, label, "sm start"));
  }
  return frame("data-rows", items, s.alt, 14, { w: 360 });
}

export interface ScaledBarsSpec {
  title: string;
  names: string[];
  counts: number[];
  scale: number;
  /** beats: bars grow; bars read with a guide line to the axis */
  beats?: { grow: number; read?: number };
  read?: number[];
  alt: string;
}

/** A bar graph whose axis goes up by `scale`, with grid lines at each step; a bar can end halfway between lines. */
export function buildScaledBars(s: ScaledBarsSpec): SceneDiagram {
  const items: Draft[] = [], b = s.beats, U = 34, BW = 52, BG = 26;
  const steps = Math.ceil(Math.max(...s.counts) / s.scale) + 1, y = (v: number) => -(v / s.scale) * U;
  const bx = (i: number) => 22 + i * (BW + BG), W = bx(s.counts.length) - BG + 14;
  for (let k = 0; k <= steps; k++) {
    if (k) items.push({ type: "line", x1: 0, y1: -k * U, x2: W, y2: -k * U, cls: "grid" } as Draft);
    items.push(t(-10, -k * U, String(k * s.scale), "xs end"));
  }
  items.push({ type: "line", x1: 0, y1: 0, x2: W, y2: 0, cls: "ax" } as Draft, { type: "line", x1: 0, y1: 0, x2: 0, y2: -steps * U - 8, cls: "ax" } as Draft);
  s.counts.forEach((v, i) => {
    items.push({ type: "rect", x: bx(i), y: y(v), w: BW, h: -y(v), rx: 4, cls: `bar ${P(i)}`, ...(b ? { from: b.grow, enter: "growy", delay: 0.15 * i } : {}) } as Draft);
    items.push(t(bx(i) + BW / 2, 20, s.names[i]!, "sm"));
    if (b?.read != null && s.read?.includes(i)) {
      items.push({ type: "line", x1: bx(i), y1: y(v), x2: 0, y2: y(v), cls: "ln2 dash", from: b.read, enter: "draw" } as Draft);
      items.push(t(bx(i) + BW / 2, y(v) - 16, String(v), "lbl", { from: b.read, enter: "rise", delay: 0.4 }));
    }
  });
  items.push(t(W / 2, -steps * U - 34, s.title, "sm"));
  return frame("data-bars", items, s.alt, 14, { w: 360 });
}
