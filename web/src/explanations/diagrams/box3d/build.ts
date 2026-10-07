// Boxes drawn in isometric view (the current app's box3D): a box built from unit cubes layer by layer,
// a box's three different faces, or a pyramid inside its box. Sizes and labels come from the problem.
import type { SceneDiagram, SceneItem } from "../scene/schema";
import { r1 } from "../scene/helpers";
import { lineRows, type PictureLine } from "../area-model/grid";

type P3 = [number, number, number];

interface Common {
  /** length (runs down to the right), width (down to the left), height (up), in problem units */
  l: number;
  w: number;
  h: number;
  /** edge labels and the beat they show at */
  labels?: { l?: string; w?: string; h?: string; from?: number };
  /** lines of text under the picture */
  lines?: PictureLine[];
  alt: string;
}

export type Box3dSpec = Common & (
  /** unit cubes; layer z shows at layerBeats[z] (a beat per layer, or one beat for several, staggered) */
  | { mode: "cubes"; layerBeats: number[] }
  /** the three faces you can see, each with its area written on it */
  | { mode: "faces"; beats: { top: number; front: number; side: number }; text?: { top?: string; front?: string; side?: string } }
  /** a pyramid in its box: the base, then the box, then the pyramid */
  | { mode: "pyramid"; beats: { base: number; box: number; pyramid: number }; baseText?: string }
);

const C30 = Math.cos(Math.PI / 6), S30 = 0.5;

/** SVG units per problem unit: the current app's rule, so a box always fits the same space. */
export const boxUnit = (l: number, w: number, h: number) => Math.min(34, 200 / (l + w), 150 / h);

export function buildBox3d(spec: Box3dSpec): SceneDiagram {
  const { l, w, h } = spec;
  for (const v of [l, w, h]) if (!(v > 0)) throw new Error("box3d: every side must be positive");
  const u = boxUnit(l, w, h);
  const iso = ([x, y, z]: P3): [number, number] => [(x - y) * C30 * u, (x + y) * S30 * u - z * u];
  const corners: P3[] = [];
  for (const x of [0, l]) for (const y of [0, w]) for (const z of [0, h]) corners.push([x, y, z]);
  const pts = corners.map(iso);
  const padL = spec.labels?.h ? 26 + spec.labels.h.length * 10 : 20, pad = 30;
  const picW = Math.max(...pts.map(p => p[0])) - Math.min(...pts.map(p => p[0])) + padL + pad;
  const lines = spec.lines ?? [];
  const lineW = Math.max(0, ...lines.map(x => x.text.length * 10.2));
  const width = Math.max(picW, lineW + 24);
  // the box sits in the middle when the text under it is wider
  const minx = Math.min(...pts.map(p => p[0])) - padL - (width - picW) / 2, miny = Math.min(...pts.map(p => p[1])) - 20;
  const at = (p: P3): [number, number] => { const q = iso(p); return [r1(q[0] - minx), r1(q[1] - miny)]; };
  const poly = (ps: P3[], cls: string, from: number, enter: SceneItem["enter"], delay = 0): SceneItem => ({ type: "polygon", points: ps.map(at), cls, from, enter, delay });
  const seg = (a: P3, b: P3, cls: string, from: number, enter: SceneItem["enter"], delay = 0): SceneItem => {
    const [x1, y1] = at(a), [x2, y2] = at(b);
    return { type: "line", x1, y1, x2, y2, cls, from, enter, delay };
  };
  const items: SceneItem[] = [];
  const top = (z: number): P3[] => [[0, 0, z], [l, 0, z], [l, w, z], [0, w, z]];
  const front = (z0: number, z1: number): P3[] => [[0, w, z0], [l, w, z0], [l, w, z1], [0, w, z1]];
  const side = (z0: number, z1: number): P3[] => [[l, 0, z0], [l, w, z0], [l, w, z1], [l, 0, z1]];
  const centre = (ps: P3[]): P3 => [0, 1, 2].map(k => ps.reduce((a, p) => a + p[k]!, 0) / ps.length) as P3;

  if (spec.mode === "cubes") {
    // the box's outline, which the layers fill
    if (Math.min(...spec.layerBeats) > 0) items.push(poly(top(h), "wire", 0, "fade"), poly(front(0, h), "wire", 0, "fade"), poly(side(0, h), "wire", 0, "fade"));
    const beatsSeen = new Map<number, number>();
    const layerBeat = (z: number) => spec.layerBeats[z] ?? spec.layerBeats[spec.layerBeats.length - 1] ?? 0;
    // layers sharing a beat stagger, but all of them land within about a beat (11 layers at half a second each
    // left the picture showing 2 layers under a caption that says 11)
    const perBeat = new Map<number, number>();
    for (let z = 0; z < h; z++) perBeat.set(layerBeat(z), (perBeat.get(layerBeat(z)) ?? 0) + 1);
    const gap = (from: number) => Math.min(0.5, 1.4 / Math.max(1, perBeat.get(from)! - 1));
    for (let z = 0; z < h; z++) {
      const from = layerBeat(z);
      const k = beatsSeen.get(from) ?? 0;
      beatsSeen.set(from, k + 1);
      const d = r1(0.2 + k * gap(from));
      items.push(poly(top(z + 1), "cf cube top", from, "rise", d), poly(front(z, z + 1), "cf cube left", from, "rise", d), poly(side(z, z + 1), "cf cube right", from, "rise", d));
      for (let i = 1; i < l; i++) items.push(seg([i, 0, z + 1], [i, w, z + 1], "cf cube", from, "rise", d), seg([i, w, z], [i, w, z + 1], "cf cube", from, "rise", d));
      for (let j = 1; j < w; j++) items.push(seg([0, j, z + 1], [l, j, z + 1], "cf cube", from, "rise", d), seg([l, j, z], [l, j, z + 1], "cf cube", from, "rise", d));
    }
    // the finished box: its visible edges drawn solid once every layer is in
    const done = Math.max(...spec.layerBeats), dd = r1(0.2 + ((beatsSeen.get(done) ?? 1) - 1) * (perBeat.has(done) ? gap(done) : 0.5) + 0.4);
    items.push(poly(top(h), "edge", done, "fade", dd), poly(front(0, h), "edge", done, "fade", dd), poly(side(0, h), "edge", done, "fade", dd));
  } else if (spec.mode === "faces") {
    const b = spec.beats;
    // the box's outline first, so each face lands in its place
    items.push(poly(top(h), "wire", 0, "fade"), poly(front(0, h), "wire", 0, "fade"), poly(side(0, h), "wire", 0, "fade"));
    const faces: [P3[], string, number, string | undefined][] = [
      [top(h), "cf top", b.top, spec.text?.top], [front(0, h), "cf left", b.front, spec.text?.front], [side(0, h), "cf right", b.side, spec.text?.side],
    ];
    for (const [ps, cls, from] of faces) items.push(poly(ps, cls, from, "pop", 0.1));
    // the light top face takes the tint colour; the darker sides take white
    for (const [ps, cls, from, t] of faces) if (t) { const [x, y] = at(centre(ps)); items.push({ type: "text", x, y, text: t, cls: cls === "cf top" ? "lbl" : "lbl onlbl", from, enter: "rise", delay: 0.4 }); }
  } else {
    const b = spec.beats, apex: P3 = [l / 2, w / 2, h];
    items.push(poly(top(0), "cf top", b.base, "pop", 0.1));
    if (spec.baseText) { const [x, y] = at([l / 2, w / 2, 0]); items.push({ type: "text", x, y, text: spec.baseText, cls: "lbl", from: b.base, enter: "rise", delay: 0.4 }); }
    items.push(poly(top(h), "wire", b.box, "fade"), poly(front(0, h), "wire", b.box, "fade"), poly(side(0, h), "wire", b.box, "fade"));
    items.push(poly([[0, w, 0], [l, w, 0], apex], "cf left", b.pyramid, "pop", 0.2), poly([[l, 0, 0], [l, w, 0], apex], "cf right", b.pyramid, "pop", 0.6));
    items.push(seg(apex, [l / 2, w / 2, 0], "ln2 dash", b.pyramid, "fade", 1));
  }

  // edge labels: length along the front bottom edge, width along the right bottom edge, height up the left edge
  const lab = spec.labels;
  if (lab) {
    const from = lab.from ?? 0;
    const mid = (a: P3, b: P3) => { const p = at(a), q = at(b); return [(p[0] + q[0]) / 2, (p[1] + q[1]) / 2] as const; };
    if (lab.l) { const [x, y] = mid([0, w, 0], [l, w, 0]); items.push({ type: "text", x: r1(x - 12), y: r1(y + 16), text: lab.l, cls: "lbl", from, enter: "rise" }); }
    if (lab.w) { const [x, y] = mid([l, 0, 0], [l, w, 0]); items.push({ type: "text", x: r1(x + 14), y: r1(y + 16), text: lab.w, cls: "lbl", from, enter: "rise" }); }
    if (lab.h) { const [x, y] = mid([0, w, 0], [0, w, h]); items.push({ type: "text", x: r1(x - 10), y: r1(y), text: lab.h, cls: "lbl end", from, enter: "rise" }); }
  }

  const picH = Math.max(...pts.map(p => p[1])) - miny + pad;
  const { rowOf, count } = lineRows(lines);
  lines.forEach((x, k) => items.push({ type: "text", x: r1(width / 2), y: r1(picH + 4 + rowOf[k]! * 26), text: x.text, cls: x.cls ?? "lbl acc", from: x.from, ...(x.until != null ? { until: x.until } : {}), enter: "rise" }));
  return { kind: "scene", family: "box3d", width: r1(width), height: r1(picH + (count ? count * 26 + 6 : 0)), items, alt: spec.alt };
}
