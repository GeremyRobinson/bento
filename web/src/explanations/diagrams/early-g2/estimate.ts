// Estimate, then measure (g2-estimate): a thing above a ruler, with a benchmark beside its start (a paper clip is about
// an inch, a cube is a centimeter). In Learn the benchmarks lay end to end along the thing, then the ruler slides in
// under it and the end lines up with the length.
import type { SceneDiagram } from "../scene/schema";
import { ellipse, frame, path, t, M, L, Z, type Draft, type Pt, type Seg } from "../geo/kit";
import { line, rect, type Timing } from "./kit";

export type EstimateThing = "crayon" | "marker" | "pencil" | "spoon" | "shoe" | "book" | "paper clip" | "eraser";

const poly = (pts: Pt[]): Seg[] => [M(pts[0]!), ...pts.slice(1).map(L), Z];

/** a paper clip from x to x + w, centered on y */
function clip(x: number, y: number, w: number, cls: string, o: Timing): Draft[] {
  const h = Math.max(10, w * 0.28), r = h / 2, i = h * 0.28;
  const segs: Seg[] = [
    M([x + w - r, y + r]), L([x + r, y + r]), { c: "Q", q: [x, y + r], p: [x, y] }, { c: "Q", q: [x, y - r], p: [x + r, y - r] },
    L([x + w - r, y - r]), { c: "Q", q: [x + w, y - r], p: [x + w, y] }, { c: "Q", q: [x + w, y + r - i], p: [x + w - r, y + r - i] },
    L([x + r + i, y + r - i]), { c: "Q", q: [x + i, y + r - i], p: [x + i, y] }, { c: "Q", q: [x + i, y - r + i], p: [x + r + i, y - r + i] },
    L([x + w - r - i, y - r + i]),
  ];
  return [path(segs, cls, o)];
}

/** the thing lying from x0 to x1 with its bottom on y = bot */
function thingShape(kind: EstimateThing, x0: number, x1: number, bot: number, o: Timing): Draft[] {
  const len = x1 - x0;
  switch (kind) {
    case "crayon": case "pencil": case "marker": {
      const H = kind === "marker" ? 26 : 22, tip = Math.min(24, len / 4), cls = kind === "crayon" ? "cell c0" : kind === "pencil" ? "cell c2" : "cell c1";
      const items = [rect(x0, bot - H, len - tip, H, cls, o, 3), path(poly([[x1 - tip, bot - H], [x1, bot - H / 2], [x1 - tip, bot]]), cls, o)];
      if (kind === "marker") items.push(rect(x0, bot - H, Math.min(40, len / 3), H, "cell c1 fillc", o, 3));
      return items;
    }
    case "spoon": {
      const bw = Math.min(46, len * 0.38);
      return [rect(x0, bot - 15, len - bw + 4, 8, "cell c1", o, 4), path(ellipse([x1 - bw / 2, bot - 11], bw / 2, 11), "cell c1", o)];
    }
    case "shoe":
      return [path(poly([[x0 + 6, bot], [x1 - 4, bot], [x1, bot - 12], [x1 - len * 0.3, bot - 20], [x0 + len * 0.32, bot - 40], [x0, bot - 40], [x0, bot - 6]]), "cell c0", o)];
    case "book":
      return [rect(x0, bot - 34, len, 34, "cell c1", o, 3), line(x0 + 10, bot - 34, x0 + 10, bot, "edge thin", o)];
    case "eraser":
      return [rect(x0, bot - 24, len, 24, "cell c0", o, 8)];
    case "paper clip":
      return clip(x0, bot - 12, len, "ln", o);
  }
}

export interface EstimateSpec {
  unit: "in" | "cm";
  max: number;
  start: number;
  len: number;
  thing: EstimateThing;
  /** beats: benchmarks lay end to end along the thing; the ruler slides in under it and the end is read */
  beats?: { lay: number; ruler: number };
  alt: string;
}

export function buildEstimate(s: EstimateSpec): SceneDiagram {
  const { start, len, max } = s, end = start + len;
  if (!(Number.isInteger(start) && Number.isInteger(len) && start >= 0 && len >= 1 && end <= max)) throw new Error("estimate: the thing must lie on the ruler");
  const u = s.unit === "in" ? 44 : 26, x = (v: number) => v * u, b = s.beats, items: Draft[] = [];
  const ro: Timing = b ? { from: b.ruler, enter: "slide" } : {};
  const rv = b ? { vars: { "--dx": "-80px" } } : {};
  // the ruler: a strip with a tick for every unit
  items.push({ ...rect(x(0) - 14, 0, x(max) + 28, 46, "fillsoft", ro, 6), ...rv } as Draft, { ...rect(x(0) - 14, 0, x(max) + 28, 46, "ax thin", ro, 6), ...rv } as Draft);
  for (let v = 0; v <= max; v++) {
    items.push({ ...line(x(v), 0, x(v), 16, "ax thin", ro), ...rv } as Draft);
    items.push({ ...t(x(v), 30, String(v), s.unit === "in" ? "sm" : "xs"), ...ro, ...rv } as Draft);
  }
  items.push({ ...t(x(max) + 22, 24, s.unit, "sm start"), ...ro, ...rv } as Draft);
  // the thing lies just above the ruler, and the benchmark beside its start, above it
  const bot = -10;
  items.push(...thingShape(s.thing, x(start), x(end), bot, {}));
  const benchY = bot - 64;
  if (s.unit === "in") items.push(...clip(x(start), benchY, u, "ln2", {}));
  else items.push(rect(x(start), benchY - u / 2, u, u, "cell c2", {}, 2));
  if (b) {
    // more benchmarks end to end along the thing
    for (let k = 1; k < len; k++) {
      const o: Timing = { from: b.lay, enter: "pop", delay: 0.25 * k };
      if (s.unit === "in") items.push(...clip(x(start + k), benchY, u, "ln2", o));
      else items.push(rect(x(start + k), benchY - u / 2, u, u, "cell c2", o, 2));
    }
    items.push(t(x(end) + 12, benchY, `about ${len}`, "lbl start", { from: b.lay, until: b.ruler - 1, enter: "rise", delay: 0.25 * len }));
    items.push(path([M([x(end), benchY + 18]), L([x(end), 0])], "ln2 dash", { from: b.ruler, enter: "draw", delay: 1 }));
    if (start) items.push(path([M([x(start), benchY + 18]), L([x(start), 0])], "ln2 dash", { from: b.ruler, enter: "draw", delay: 1 }));
    items.push(t(x((start + end) / 2), 76, `${len} ${s.unit === "in" ? (len === 1 ? "inch" : "inches") : len === 1 ? "centimeter" : "centimeters"}`, "lbl big acc", { from: b.ruler, enter: "rise", delay: 1.3 }));
  }
  return frame("estimate", items, s.alt, 14, { w: 360 });
}
