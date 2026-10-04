// A jug marked in liters (design/pictures-k4.md §5, g3-liters): a tall jug, width 0.6 of its height, with a spout and
// an open handle; marks on the left wall, the top mark 12% below the brim. Water fills flat to the value. In Learn it
// fills from empty, then the marks count up to the surface.
import type { SceneDiagram } from "../scene/schema";
import { frame, path, t, M, L, Z, type Draft } from "../geo/kit";

export interface JugSpec {
  cap: number;
  step: number;
  value: number;
  beats?: { fill: number; count: number };
  alt: string;
}

const H = 260, W = H * 0.6;

export function buildJug(s: JugSpec): SceneDiagram {
  const { cap, step, value } = s, b = s.beats, items: Draft[] = [];
  if (!(Number.isInteger(cap / step) && value >= 0 && value <= cap && Number.isInteger(value / step))) throw new Error("jug: the water sits on a mark");
  const top = 0, base = H, markTop = top + 0.12 * H, y = (v: number) => base - ((base - markTop) * v) / cap;
  // water first, so the jug's outline draws over it
  if (value > 0) {
    const o = b ? { from: b.fill, enter: "level" as const, vars: { "--from": 0 } } : {};
    items.push({ type: "path", segs: [M([2, y(value)]), L([W - 2, y(value)]), L([W - 2, base - 12]), { c: "Q", q: [W - 2, base - 2], p: [W - 12, base - 2] }, L([12, base - 2]), { c: "Q", q: [2, base - 2], p: [2, base - 12] }, Z], cls: "water", ...o } as Draft);
    items.push({ type: "path", segs: [M([2, y(value)]), L([W - 2, y(value)])], cls: "surface", ...(b ? { from: b.fill, enter: "fade", delay: 1 } : {}) } as Draft);
  }
  // the jug: a spout notch top left, a flat base with round corners, an open handle on the right
  items.push(path([M([-14, top - 10]), L([0, top + 18]), L([0, base - 12]), { c: "Q", q: [0, base], p: [12, base] }, L([W - 12, base]), { c: "Q", q: [W, base], p: [W, base - 12] }, L([W, top])], "jugline"));
  items.push(path([M([W, top + 40]), { c: "C", c1: [W + 62, top + 40], c2: [W + 62, top + 150], p: [W, top + 150] }], "jugline"));
  const fmt = (v: number) => String(v);
  const n = cap / step, labelEvery = n <= 10 ? 1 : n <= 20 ? 2 : 5;
  for (let k = 1; k <= n; k++) {
    const long = k % labelEvery === 0 || k === n, yy = y(k * step);
    items.push(path([M([0, yy]), L([long ? 14 : 7, yy])], long ? "ax" : "tk"));
    if (long) items.push(t(-12, yy, fmt(k * step), "sm end muted"));
  }
  items.push(t(-12, y(cap) - 22, "L", "sm end muted"));
  if (b) {
    const marks = value / step;
    for (let k = 1; k <= marks; k++) items.push(t(26, y(k * step), fmt(k * step), k === marks ? "xs acc start" : "xs start", { from: b.count, enter: "pop", delay: 0.15 * k }));
    items.push(t(W / 2, base + 36, `${value} ${value === 1 ? "liter" : "liters"}`, "lbl big acc", { from: b.count, enter: "rise", delay: 0.15 * marks + 0.3 }));
  }
  return frame("jug", items, s.alt, 14, { w: 300 });
}
