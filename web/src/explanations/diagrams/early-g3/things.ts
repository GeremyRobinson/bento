// Everyday things to weigh (g3-mass): simple flat silhouettes, one tone of the grade's color, no outlines of a real
// brand. Each fits about a 200 × 140 box. The practice picture is the thing alone; the lesson page sets it on a
// kitchen scale whose window reads "?" until the guess step, then the sensible mass.
import type { SceneDiagram } from "../scene/schema";
import { ellipse, frame, path, t, M, L, Z, type Draft, type Pt, type Seg } from "../geo/kit";
import { coinFace } from "../early-g2/coins";

const poly = (pts: Pt[]): Seg[] => [M(pts[0]!), ...pts.slice(1).map(L), Z];
const circ = (cx: number, cy: number, r: number, cls = "cell c0"): Draft => ({ type: "circle", cx, cy, r, cls }) as Draft;
const box = (x: number, y: number, w: number, h: number, rx: number, cls = "cell c0"): Draft => ({ type: "rect", x, y, w, h, rx, cls }) as Draft;

function shapes(name: string): Draft[] {
  switch (name) {
    case "paper clip": return [path([M([150, 80]), L([50, 80]), { c: "Q", q: [30, 80], p: [30, 65] }, { c: "Q", q: [30, 50], p: [50, 50] }, L([160, 50]), { c: "Q", q: [180, 50], p: [180, 70] }, { c: "Q", q: [180, 92], p: [160, 92] }, L([60, 92])], "ln")];
    case "grape": return [[80, 40], [104, 40], [128, 40], [92, 62], [116, 62], [104, 84]].map(([x, y]) => circ(x!, y!, 14, "cell c0")).concat([path([M([104, 26]), L([110, 6])], "ln")]);
    // a real coin is metal, never the grade's color (the coin rule): a silver disc with a ridged edge
    case "coin": return coinFace([100, 60], 40, "ag", true);
    case "pencil": return [box(20, 50, 140, 24, 3, "cell c0"), path(poly([[160, 50], [190, 62], [160, 74]]), "cell c0")];
    case "key": return [circ(50, 60, 26, "cell c0"), circ(50, 60, 9, "fillsoft"), box(74, 54, 110, 12, 3, "cell c0"), box(150, 66, 10, 16, 2, "cell c0"), box(168, 66, 10, 12, 2, "cell c0")];
    case "dog": return [path(ellipse([100, 70], 60, 28), "cell c0"), circ(168, 40, 22), box(56, 88, 12, 36, 4), box(82, 90, 12, 34, 4), box(116, 90, 12, 34, 4), box(140, 88, 12, 36, 4), path([M([40, 62]), L([18, 40])], "ln"), path(poly([[160, 22], [170, 0], [180, 24]]), "cell c0")];
    case "bag of flour": return [path(poly([[50, 30], [150, 30], [160, 130], [40, 130]]), "cell c0"), path([M([50, 30]), L([62, 14]), L([138, 14]), L([150, 30])], "ln"), box(70, 64, 60, 36, 6, "fillsoft")];
    case "watermelon": return [path([M([30, 50]), { c: "A", r: 70, large: 0, sweep: 0, p: [170, 50], samples: [[100, 120], [50, 100], [150, 100]] }, Z], "cell c0"), path([M([42, 50]), { c: "A", r: 58, large: 0, sweep: 0, p: [158, 50], samples: [[100, 108]] }, Z], "cell c0"), circ(80, 68, 3, "pin"), circ(100, 80, 3, "pin"), circ(120, 68, 3, "pin")];
    case "bike": return [circ(50, 90, 34, "ln"), circ(160, 90, 34, "ln"), path([M([50, 90]), L([90, 40]), L([140, 40]), L([160, 90]), M([90, 40]), L([110, 90]), L([140, 40]), M([50, 90]), L([110, 90])], "ln"), path([M([82, 34]), L([100, 34])], "ln"), path([M([140, 40]), L([136, 24]), L([150, 22])], "ln")];
    default: return [box(50, 20, 100, 120, 22, "cell c0"), box(68, 76, 64, 46, 10, "fillsoft"), path([M([80, 20]), { c: "Q", q: [100, -6], p: [120, 20] }], "ln")];
  }
}

/** the lowest point of each silhouette, so it sits on the scale */
const BOTTOM: Record<string, number> = { "paper clip": 92, grape: 98, coin: 100, pencil: 74, key: 82, dog: 124, "bag of flour": 130, watermelon: 120, bike: 124 };

export interface ThingScale {
  /** what the window reads at the guess beat, "5 g" */
  reading: string;
  /** the unit cue under the scale at the unit beat, "Light: weigh it in grams." */
  cue: string;
  beats: { unit: number; guess: number };
}

export function buildEstimateThing(s: { thing: string; alt: string; scale?: ThingScale }): SceneDiagram {
  const items = shapes(s.thing);
  if (s.scale) {
    const { beats: b } = s.scale, y = (BOTTOM[s.thing] ?? 140) + 2;
    const box = (x: number, yy: number, w: number, h: number, rx: number, cls: string, extra: Partial<Draft> = {}): Draft => ({ type: "rect", x, y: yy, w, h, rx, cls, ...extra }) as Draft;
    // the pan, the scale's body and its reading window
    items.unshift(box(10, y, 180, 8, 4, "fillsoft"), box(10, y, 180, 8, 4, "ax thin"), box(40, y + 8, 120, 52, 10, "fillsoft"), box(40, y + 8, 120, 52, 10, "ax thin"));
    items.push(box(58, y + 18, 84, 32, 6, "ax thin"));
    items.push(t(100, y + 34, "?", "lbl", { until: b.guess - 1 }));
    items.push(t(100, y + 34, s.scale.reading, "lbl acc", { from: b.guess, enter: "pop" }));
    items.push(t(100, y + 84, s.scale.cue, "lbl", { from: b.unit, enter: "rise", delay: 0.2 }));
  }
  return frame("thing", items, s.alt, 14, { w: 300 });
}
