// A scale dial (design/pictures-k4.md §4, g3-mass): a 240° arc opening downward, a long labeled mark every 5 small
// marks, and a needle from the hub. Practice never labels the needle. In Learn the labels light, the small marks
// between the first two labels count up, the needle swings out from 0 and the count carries on to it.
import type { SceneDiagram } from "../scene/schema";
import { arc, frame, path, polar, t, M, L, type Draft, type Pt } from "../geo/kit";
import { roomLeft, thinOut } from "../scene/picture-system";

export const DIAL_MARKS = 20;
/** drawn at about a phone strip's size, so its numbers, laid out at their phone size, land where they are drawn */
const R = 90, C: Pt = [0, 0];
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
      // the plain number gives way to its lit copy for the beat the labels light (one number on the spot, never two)
      items.push(t(x, y, fmt(k * s.step), "sm", b ? { until: b.labels - 1 } : {}));
      if (b) items.push(t(x, y, fmt(k * s.step), "sm", { from: b.labels + 1 }));
      if (b) items.push(t(x, y, fmt(k * s.step), "sm acc", { from: b.labels, until: b.labels, enter: "fade", delay: 0.15 * (k / 5) }));
    }
  }
  items.push(t(0, 34, s.unit, "sm muted up"));
  const tip = polar(C, R - 10, angle(s.value, max));
  const needle: Draft = path([M(C), L(tip)], "needle", b ? { from: b.needle, enter: "swing" as Draft["enter"], vars: { "--from": `${(-240 * s.value) / max}deg` } } : {});
  items.push(needle, { type: "circle", cx: 0, cy: 0, r: 6, cls: "hub" } as Draft);
  if (b) {
    // the small marks between 0 and the first label count up by step, then on to the needle. A count on the dial's
    // left or right side is held by its edge nearest the dial, so the floor grows it outward; where a phone's floor
    // grows neighbours into each other, every other one fades (the lit one stays), so no two counts touch
    const marks = Math.round(s.value / s.step);
    const side = (x: number) => (x < -R * 0.3 ? " end" : x > R * 0.3 ? " start" : "");
    const pitch = ((R + 14) * 12 * Math.PI) / 180, low = (k: number) => k & -k;
    const thin = (k: number, room: number) => ({ vars: thinOut(roomLeft(pitch * room, fmt(k * s.step).length, 12)) });
    for (let k = 1; k <= 5; k++) {
      const [x, y] = polar(C, R + 14, angle(k * s.step, max));
      items.push(t(x, y, fmt(k * s.step), `${k === 5 ? "xs acc" : "xs"}${side(x)}`, { from: b.count, until: b.count, enter: "pop", delay: 0.3 * k, ...(k === 5 ? {} : thin(k, Math.min(low(k), 5 - k))) }));
    }
    const lastLabel = Math.floor(marks / 5) * 5;
    for (let k = lastLabel + 1; k <= marks; k++) {
      const [x, y] = polar(C, R + 14, angle(k * s.step, max));
      items.push(t(x, y, fmt(k * s.step), `${k === marks ? "xs acc" : "xs"}${side(x)}`, { from: b.needle, enter: "pop", delay: 0.9 + 0.3 * (k - lastLabel), ...(k === marks ? {} : thin(k, Math.min(low(k - lastLabel), marks - k))) }));
    }
    items.push(t(0, 40, `${fmt(s.value)} ${s.unit}`, "lbl big acc down", { from: b.needle, enter: "rise", delay: 1.2 + 0.3 * (marks - lastLabel) }));
  }
  const sc = frame("scale-dial", items, s.alt, 14, { w: 300 });
  // the needle turns about the hub, wherever framing moved it
  const hub = sc.items.find(i => i.type === "circle" && i.cls === "hub") as { cx: number; cy: number } | undefined;
  if (hub) for (const it of sc.items) if (it.cls === "needle") it.vars = { ...it.vars, "--ox": `${hub.cx}px`, "--oy": `${hub.cy}px` };
  return sc;
}
