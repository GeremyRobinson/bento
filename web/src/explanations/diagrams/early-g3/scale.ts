// A scale dial (design/pictures-k4.md §4, g3-mass): a 240° arc opening downward, a long labeled mark every 5 small
// marks, and a needle from the hub. Practice never labels the needle. In Learn the labels light, the small marks
// between the first two labels count up, the needle swings out from 0 and the count carries on to it.
import type { SceneDiagram } from "../scene/schema";
import { arc, frame, path, polar, t, M, L, type Draft, type Pt } from "../geo/kit";

export const DIAL_MARKS = 20;
const R = 120, C: Pt = [0, 0];
/** degrees (counterclockwise from right) for v of max: 0 at lower left, max at lower right, clockwise over the top */
const angle = (v: number, max: number) => 210 - (240 * v) / max;

export interface ScaleSpec {
  unit: "g" | "kg";
  /** what each small mark is worth */
  step: number;
  value: number;
  beats?: { labels: number; count: number; needle: number };
  alt: string;
}

export function buildScale(s: ScaleSpec): SceneDiagram {
  const max = s.step * DIAL_MARKS, b = s.beats, items: Draft[] = [];
  if (!(s.value >= 0 && s.value <= max && Number.isInteger(s.value / s.step))) throw new Error("scale: the needle sits on a mark");
  items.push({ type: "circle", cx: 0, cy: 0, r: R + 18, cls: "dialface" } as Draft);
  items.push(path(arc(C, R, 210, -30), "ax thin"));
  const fmt = (v: number) => v.toLocaleString("en-US");
  for (let k = 0; k <= DIAL_MARKS; k++) {
    const a = angle(k * s.step, max), long = k % 5 === 0;
    items.push(path([M(polar(C, R, a)), L(polar(C, R - (long ? 14 : 7), a))], long ? "ax" : "tk"));
    if (long) {
      const [x, y] = polar(C, R - 34, a);
      items.push(t(x, y, fmt(k * s.step), "sm"));
      if (b) items.push(t(x, y, fmt(k * s.step), "sm acc", { from: b.labels, until: b.labels, enter: "fade", delay: 0.15 * (k / 5) }));
    }
  }
  items.push(t(0, 44, s.unit, "sm muted"));
  const tip = polar(C, R - 10, angle(s.value, max));
  const needle: Draft = path([M(C), L(tip)], "needle", b ? { from: b.needle, enter: "swing" as Draft["enter"], vars: { "--from": `${(-240 * s.value) / max}deg` } } : {});
  items.push(needle, { type: "circle", cx: 0, cy: 0, r: 6, cls: "hub" } as Draft);
  if (b) {
    // the small marks between 0 and the first label count up by step, then on to the needle
    const marks = Math.round(s.value / s.step);
    for (let k = 1; k <= 5; k++) {
      const [x, y] = polar(C, R + 16, angle(k * s.step, max));
      items.push(t(x, y, fmt(k * s.step), k === 5 ? "xs acc" : "xs", { from: b.count, until: b.count, enter: "pop", delay: 0.3 * k }));
    }
    const lastLabel = Math.floor(marks / 5) * 5;
    for (let k = lastLabel + 1; k <= marks; k++) {
      const [x, y] = polar(C, R + 16, angle(k * s.step, max));
      items.push(t(x, y, fmt(k * s.step), k === marks ? "xs acc" : "xs", { from: b.needle, enter: "pop", delay: 0.9 + 0.3 * (k - lastLabel) }));
    }
    items.push(t(0, 76, `${fmt(s.value)} ${s.unit}`, "lbl big acc", { from: b.needle, enter: "rise", delay: 1.2 + 0.3 * (marks - lastLabel) }));
  }
  const sc = frame("scale-dial", items, s.alt, 14, { w: 300 });
  // the needle turns about the hub, wherever framing moved it
  const hub = sc.items.find(i => i.type === "circle" && i.cls === "hub") as { cx: number; cy: number } | undefined;
  if (hub) for (const it of sc.items) if (it.cls === "needle") it.vars = { ...it.vars, "--ox": `${hub.cx}px`, "--oy": `${hub.cy}px` };
  return sc;
}
