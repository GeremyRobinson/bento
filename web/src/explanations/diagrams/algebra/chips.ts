// Factor chips (Curriculum fixes-02, Part B): a power written out as a row of chips (x x x, 2 2 2 2), with brackets
// around groups, an optional fraction bar with chips under it, pairs that cancel (struck through) and value labels.
// Built from frames like the balance: frame i shows at beat i (the last frame stays). Everything sits on one grid of
// columns and rows, so a chip keeps its place from frame to frame and a cancelled pair lines up top and bottom.
// Inside a beat a piece can come in at `at` seconds and go at `leave`, so one beat can count up or count down.
import type { Enter, SceneDiagram, SceneItem } from "../scene/schema";
import { r1 } from "../scene/helpers";

interface Timed {
  /** seconds into the beat it comes in (with its entrance); without it, it is simply there */
  at?: number;
  /** seconds into the beat it goes */
  leave?: number;
}
/** One chip at a grid spot. Columns may be fractional (a gap between groups). */
export interface FChip extends Timed {
  row: number; col: number; text: string; sup?: string;
  /** part role: p0, p1, p2 or pq (the accent) */
  part?: string;
  /** dashed and empty: a chip that is missing, or a place holder */
  ghost?: boolean;
  /** columns it spans (a wide value chip) */
  span?: number;
  /** struck through at this many seconds into the beat */
  strike?: number;
  /** dimmed: cancelled or taken away on an earlier beat */
  cut?: boolean;
  /** slides in from this grid spot instead of popping */
  from?: [row: number, col: number];
  enter?: Enter;
}
/** A bracket under (or over) chips `from`..`to` of a row, with a label. */
export interface FBracket extends Timed { row: number; from: number; to: number; label: string; sup?: string; part?: string; above?: boolean }
/** Text at a grid spot: a count, a value, an operation. */
export interface FLabel extends Timed { row: number; col: number; text: string; sup?: string; cls?: string; anchor?: "start" | "end" }
/** A fraction bar across columns `from`..`to`, between `row` and the row under it. */
export interface FBar extends Timed { row: number; from: number; to: number }

export interface ChipFrame { chips?: FChip[]; brackets?: FBracket[]; labels?: FLabel[]; bars?: FBar[] }

export const CHIPS = { pitch: 46, chip: 38, row: 66, pad: 16 } as const;
const CH = 17 * 0.6;
const sizeOf = (cls = "") => (/\bbig\b/.test(cls) ? (/\blbl\b/.test(cls) ? 22 : 28) : /\bsm\b/.test(cls) ? 15 : /\bxs\b/.test(cls) ? 12 : 17);

/** Builds the picture from its frames. */
export function buildFactorChips(frames: ChipFrame[], alt: string, family = "factor-chips"): SceneDiagram {
  const { pitch, chip, row: RH, pad } = CHIPS;
  const items: SceneItem[] = [], brackets: [number, number, number, number][] = [];
  frames.forEach((f, i) => {
    const last = i === frames.length - 1;
    const when = (t: Timed, enter: Enter, cls: string): Partial<SceneItem> => {
      const base = { from: i, ...(last ? {} : { until: i }) };
      if (t.at != null && t.leave != null) return { ...base, cls, enter: "flash", delay: t.at, vars: { "--d2": `${t.leave.toFixed(2)}s` } };
      if (t.leave != null) return { ...base, cls: `${cls} a-outsoon`, delay: t.leave };
      if (t.at != null) return { ...base, cls, enter, delay: t.at };
      return { ...base, cls };
    };
    const X = (col: number) => col * pitch, Y = (row: number) => row * RH;
    for (const c of f.chips ?? []) {
      const span = c.span ?? 1, w = span * pitch - (pitch - chip), x = X(c.col) - chip / 2, y = Y(c.row) - chip / 2;
      const part = c.part ?? "p0";
      const slide = c.from ? { enter: "slide" as Enter, vars: { "--dx": `${r1(X(c.from[1]) - X(c.col))}px`, "--dy": `${r1(Y(c.from[0]) - Y(c.row))}px` } } : null;
      const t = slide && c.at == null ? { ...c, at: 0 } : c;
      const box = when(t, c.enter ?? "pop", `xchip ${part}${c.ghost ? " ghost" : ""}${c.cut ? " cut" : ""}`);
      const txt = when(t, c.enter ?? "pop", `${c.ghost || part === "pq" ? `lbl big ${part === "pq" ? "acc" : part}` : "lbl big onlbl"}${c.cut ? " cut" : ""}`);
      items.push({ type: "rect", x: r1(x), y: r1(y), w: r1(w), h: chip, rx: 10, ...box, ...(slide && t.leave == null ? { enter: "slide", vars: slide.vars } : {}) } as SceneItem);
      items.push({ type: "text", x: r1(x + w / 2), y: r1(Y(c.row)), text: c.text, ...(c.sup ? { sup: c.sup } : {}), ...txt, ...(slide && t.leave == null ? { enter: "slide", vars: slide.vars } : {}) } as SceneItem);
      if (c.strike != null) items.push({ type: "line", x1: r1(x - 4), y1: r1(y + chip + 4), x2: r1(x + w + 4), y2: r1(y - 4), ...when({ at: c.strike, leave: c.leave }, "draw", "ln2") } as SceneItem);
    }
    for (const b of f.brackets ?? []) {
      const x0 = X(b.from) - chip / 2, x1 = X(b.to) + chip / 2, s = b.above ? -1 : 1, y = Y(b.row) + s * (chip / 2 + 8);
      const part = b.part ?? "pw";
      brackets.push([x0, x1, Math.min(y, y + s * 8), Math.max(y, y + s * 8)]);
      items.push({ type: "path", d: `M${r1(x0)} ${r1(y)} v${s * 8} H${r1(x1)} v${-s * 8}`, ...when(b, "draw", `ln thin ${part}`) } as SceneItem);
      items.push({ type: "text", x: r1((x0 + x1) / 2), y: r1(y + s * 22), text: b.label, ...(b.sup ? { sup: b.sup } : {}), ...when(b, "rise", `lbl ${part}`) } as SceneItem);
    }
    for (const b of f.bars ?? []) {
      const y = Y(b.row + 0.5);
      items.push({ type: "line", x1: r1(X(b.from) - chip / 2 - 6), y1: r1(y), x2: r1(X(b.to) + chip / 2 + 6), y2: r1(y), ...when(b, "draw", "ax") } as SceneItem);
    }
    for (const l of f.labels ?? []) {
      const cls = `${l.cls ?? "lbl pw"}${l.anchor ? ` ${l.anchor}` : ""}`;
      items.push({ type: "text", x: r1(X(l.col)), y: r1(Y(l.row)), text: l.text, ...(l.sup ? { sup: l.sup } : {}), ...when(l, "rise", cls) } as SceneItem);
    }
  });
  // frame the content: every shape and label, with room round it
  let x0 = Infinity, x1 = -Infinity, y0 = Infinity, y1 = -Infinity;
  const grow = (a: number, b: number, c: number, d: number) => { x0 = Math.min(x0, a); x1 = Math.max(x1, b); y0 = Math.min(y0, c); y1 = Math.max(y1, d); };
  for (const it of items) {
    if (it.type === "rect") grow(it.x, it.x + it.w, it.y, it.y + it.h);
    else if (it.type === "line") grow(Math.min(it.x1, it.x2), Math.max(it.x1, it.x2), Math.min(it.y1, it.y2), Math.max(it.y1, it.y2));
    else if (it.type === "text") {
      const size = sizeOf(it.cls), w = (it.text.length + (it.sup ? it.sup.length * 0.65 : 0)) * size * 0.6;
      const a = /\bstart\b/.test(it.cls ?? "") ? it.x : /\bend\b/.test(it.cls ?? "") ? it.x - w : it.x - w / 2;
      grow(a, a + w, it.y - size / 2, it.y + size / 2);
    }
  }
  for (const b of brackets) grow(...b);
  const W = Math.max(320, x1 - x0 + 2 * pad), dx = (W - (x1 - x0)) / 2 - x0, dy = pad - y0;
  const moved = items.map(it => shift(it, dx, dy));
  return { kind: "scene", family, width: r1(W), height: r1(y1 - y0 + 2 * pad), items: moved, alt };
}

function shift(it: SceneItem, dx: number, dy: number): SceneItem {
  switch (it.type) {
    case "rect": return { ...it, x: r1(it.x + dx), y: r1(it.y + dy) };
    case "line": return { ...it, x1: r1(it.x1 + dx), y1: r1(it.y1 + dy), x2: r1(it.x2 + dx), y2: r1(it.y2 + dy) };
    case "text": return { ...it, x: r1(it.x + dx), y: r1(it.y + dy) };
    case "path": {
      // the bracket paths are "M x y v a H x v b": move the absolute numbers only
      const [m, rest] = [it.d.slice(0, it.d.indexOf(" v")), it.d.slice(it.d.indexOf(" v"))];
      const [x, y] = m.slice(1).split(" ").map(Number);
      return { ...it, d: `M${r1(x! + dx)} ${r1(y! + dy)}${rest.replace(/H(-?[\d.]+)/, (_, h) => `H${r1(Number(h) + dx)}`)}` };
    }
    default: return it;
  }
}
export const chipTextWidth = (s: string) => s.length * CH;
