// A regular polygon with n sides, cut into n − 2 triangles from one corner, with one inside angle marked.
import type { SceneDiagram } from "../scene/schema";
import { angleLabelAt, arc, frame, poly, polar, t, path, type Draft, type Pt } from "../geo/kit";

export interface PolygonSplitSpec {
  n: number;
  /** beats: the triangles appear, then one angle is measured */
  trianglesBeat: number;
  angleBeat: number;
  /** text beside the polygon at each beat */
  notes: { text: string; from: number; acc?: boolean }[];
  /** label for the marked inside angle, e.g. "120°", shown at angleBeat */
  angleText: string;
  alt: string;
}

const R = 110;

export function buildPolygonSplit(s: PolygonSplitSpec): SceneDiagram {
  const { n } = s;
  if (!Number.isInteger(n) || n < 3) throw new Error("a polygon has at least 3 sides");
  const O: Pt = [0, 0];
  // corner 0 at the top, the rest going clockwise
  const dir = (i: number) => 90 - (i * 360) / n;
  const ps = Array.from({ length: n }, (_, i) => polar(O, R, dir(i)));
  const items: Draft[] = [];
  const stagger = Math.min(0.45, 2.4 / (n - 2));
  for (let i = 1; i < n - 1; i++) items.push(poly([ps[0]!, ps[i]!, ps[i + 1]!], `tri c${i % 3}`, { from: s.trianglesBeat, enter: "pop", delay: (i - 1) * stagger }));
  items.push(poly(ps, "ln", { enter: "draw" }));
  // number the triangles when there is room for it
  if (n <= 12) for (let i = 1; i < n - 1; i++) {
    const c: Pt = [(ps[0]![0] + ps[i]![0] + ps[i + 1]![0]) / 3, (ps[0]![1] + ps[i]![1] + ps[i + 1]![1]) / 3];
    items.push(t(c[0], c[1], String(i), "xs", { from: s.trianglesBeat, enter: "fade", delay: (i - 1) * stagger + 0.3 }));
  }
  // the inside angle at the bottom corner, between its two neighbours
  const k = Math.floor(n / 2), v = ps[k]!;
  const toward = (p: Pt) => (Math.atan2(-(p[1] - v[1]), p[0] - v[0]) * 180) / Math.PI;
  let d0 = toward(ps[k - 1]!), d1 = toward(ps[k + 1]!);
  while (d1 < d0) d1 += 360;
  const r = Math.min(26, (2 * Math.PI * R) / n * 0.35);
  items.push(path(arc(v, r, d0, d1), "ln2", { from: s.angleBeat, enter: "draw" }));
  const at = angleLabelAt(v, d0, d1, s.angleText.length * 10.2, r + 18, 80);
  items.push(t(at[0], at[1], s.angleText, "lbl acc", { from: s.angleBeat, enter: "rise", delay: 0.3 }));
  // the notes stand under the polygon, centred: beside it, a phone's readable label size ran them past the picture's edge
  // (Review: the landing card's "6 × 180° = 1080°" at 390×844)
  s.notes.forEach((note, i) => items.push(t(0, R + 44 + i * 32, note.text, `lbl${note.acc ? " acc" : ""}`, { from: note.from, enter: "rise" })));
  return frame("polygon-split", items, s.alt, 14);
}
