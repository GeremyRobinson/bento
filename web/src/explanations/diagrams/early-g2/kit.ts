// Shapes the 2nd grade pictures share: base-ten blocks (cubes, rods and flats) and a cross-out mark.
// Every block is drawn as plain rects and lines so a lesson can time each one by beat.
import type { Draft } from "../geo/kit";

export type Timing = { from?: number; until?: number; enter?: Draft["enter"]; delay?: number; vars?: Record<string, string> };

const time = (o: Timing): Partial<Draft> => ({
  ...(o.from != null ? { from: o.from } : {}),
  ...(o.until != null ? { until: o.until } : {}),
  ...(o.enter ? { enter: o.enter } : {}),
  ...(o.delay != null ? { delay: Math.round(o.delay * 100) / 100 } : {}),
  ...(o.vars ? { vars: o.vars } : {}),
});

export const rect = (x: number, y: number, w: number, h: number, cls: string, o: Timing = {}, rx = 2): Draft =>
  ({ type: "rect", x, y, w, h, rx, cls, ...time(o) }) as Draft;
export const line = (x1: number, y1: number, x2: number, y2: number, cls: string, o: Timing = {}): Draft =>
  ({ type: "line", x1, y1, x2, y2, cls, ...time(o) }) as Draft;
export const circle = (cx: number, cy: number, r: number, cls: string, o: Timing = {}): Draft =>
  ({ type: "circle", cx, cy, r, cls, ...time(o) }) as Draft;

/** One ones cube, s wide, top-left at (x, y). */
export const cube = (x: number, y: number, s: number, cls: string, o: Timing = {}): Draft[] => [rect(x, y, s, s, cls, o)];

/** A tens rod: ten cubes stacked, s wide and 10s tall, top-left at (x, y). */
export function rod(x: number, y: number, s: number, cls: string, o: Timing = {}): Draft[] {
  const out = [rect(x, y, s, 10 * s, cls, o)];
  const inner = { ...o, enter: "fade" as const };
  for (let k = 1; k < 10; k++) out.push(line(x, y + k * s, x + s, y + k * s, cls, inner));
  return out;
}

/** A hundreds flat: ten rods side by side, `size` wide and tall, top-left at (x, y). */
export function flat(x: number, y: number, size: number, cls: string, o: Timing = {}): Draft[] {
  const out = [rect(x, y, size, size, cls, o)];
  const inner = { ...o, enter: "fade" as const };
  const s = size / 10;
  for (let k = 1; k < 10; k++) {
    out.push(line(x + k * s, y, x + k * s, y + size, cls, inner));
    out.push(line(x, y + k * s, x + size, y + k * s, cls, inner));
  }
  return out;
}

/** A taken-away block: a faint ghost with a slash through it, shown from `from`. */
export function crossOut(x: number, y: number, w: number, h: number, from: number, delay = 0): Draft[] {
  return [
    rect(x, y, w, h, "seg cut", { from, enter: "fade", delay }),
    line(x - 2, y + h + 2, x + w + 2, y - 2, "ln2", { from, enter: "draw", delay }),
  ];
}

/** "1 thing", "3 things". */
export const plural = (n: number, one: string, many = `${one}s`) => `${n} ${n === 1 ? one : many}`;
