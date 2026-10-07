// A triangle drawn with its real angles: the two base corners are given, the top corner is whatever is left.
// Each corner gets an arc and labels that can change by beat; an exterior angle can open at the right corner.
import type { SceneDiagram } from "../scene/schema";
import { angleLabelAt, arc, dist, frame, path, poly, polar, seg, t, type Draft, type Pt } from "../geo/kit";

export interface CornerLabel { text: string; from?: number; until?: number; acc?: boolean }
export interface TriangleAnglesSpec {
  /** angle at the left base corner and at the right base corner, in degrees */
  left: number;
  right: number;
  labels: { left: CornerLabel[]; right: CornerLabel[]; top: CornerLabel[] };
  /** which corners' arcs are drawn in the accent colour (the ones being found) */
  accent?: { left?: number; right?: number; top?: number };
  /** the outside angle at the right corner: the base runs on past it */
  exterior?: { from?: number; labels: CornerLabel[] };
  /** short lines of working shown above the triangle */
  notes?: CornerLabel[];
  /** how far past its arc a corner's label starts, px (14 if left out) */
  labelGap?: number;
  alt: string;
}

const shown = (l: { from?: number; until?: number }) => ({ ...(l.from ? { from: l.from } : {}), ...(l.until != null ? { until: l.until } : {}) });

export function buildTriangleAngles(s: TriangleAnglesSpec): SceneDiagram {
  const A = s.left, B = s.right, C = 180 - A - B;
  if (!(A > 0 && B > 0 && C > 0)) throw new Error("the angles must leave room for a third");
  // base 1, apex by the law of sines, then scaled to fit a 340 × 240 box
  const side = Math.sin((B * Math.PI) / 180) / Math.sin(((A + B) * Math.PI) / 180);
  const apex1 = polar([0, 0], side, A);
  const xs = [0, 1, apex1[0]], ys = [0, apex1[1]];
  // a tall thin triangle still gets a base wide enough for the two corner labels
  const u = Math.max(130, Math.min(340 / (Math.max(...xs) - Math.min(...xs)), 240 / (Math.max(...ys) - Math.min(...ys))));
  const P1: Pt = [0, 0], P2: Pt = [u, 0], P3: Pt = [apex1[0] * u, apex1[1] * u];
  const items: Draft[] = [poly([P1, P2, P3], "ln fillsoft", { enter: "draw" })];

  const corner = (v: Pt, d0: number, d1: number, labels: CornerLabel[], accentFrom: number | undefined, arcR: number, maxR: number) => {
    const span = d1 - d0;
    const r = Math.min(arcR, maxR * 0.6);
    if (accentFrom != null) {
      if (accentFrom > 0) items.push(path(arc(v, r, d0, d1), "ln", { until: accentFrom - 1, enter: "draw", delay: 0.6 }));
      items.push(path(arc(v, r, d0, d1), "ln2", { from: accentFrom, enter: "draw", delay: accentFrom ? 0 : 0.6 }));
    } else items.push(path(arc(v, r, d0, d1), "ln", { enter: "draw", delay: 0.6 }));
    for (const l of labels) {
      const gap = s.labelGap ?? 14;
      const at = angleLabelAt(v, d0, d0 + span, l.text.length * 10.2, r + gap, Math.max(r + gap, maxR));
      items.push(t(at[0], at[1], l.text, `lbl${l.acc ? " acc" : ""}`, { ...shown(l), enter: "rise", delay: 0.8 }));
    }
  };
  const a = dist(P1, P2), b = dist(P2, P3), c = dist(P1, P3);
  corner(P1, 0, A, s.labels.left, s.accent?.left, 30, Math.min(a, c) * 0.7);
  corner(P2, 180 - B, 180, s.labels.right, s.accent?.right, 30, Math.min(a, b) * 0.7);
  corner(P3, 180 + A, 360 - B, s.labels.top, s.accent?.top, 26, Math.min(b, c) * 0.7);

  if (s.exterior) {
    const ext = s.exterior, from = ext.from ?? 0;
    const end: Pt = [P2[0] + Math.max(110, u * 0.4), 0];
    items.push(seg(P2, end, "ax dash", { ...shown(ext), enter: "draw" }));
    items.push(path(arc(P2, 24, 0, 180 - B), "ln2", { ...shown(ext), enter: "draw", delay: 0.4 }));
    for (const l of ext.labels) {
      const at = angleLabelAt(P2, 0, 180 - B, l.text.length * 10.2, 44, 160);
      items.push(t(at[0], at[1], l.text, "lbl acc", { ...shown({ from: Math.max(from, l.from ?? 0), ...(l.until != null ? { until: l.until } : {}) }), enter: "rise", delay: 0.6 }));
    }
  }
  const top = Math.min(P1[1], P2[1], P3[1]);
  const cx = (Math.min(P1[0], P3[0]) + Math.max(P2[0], P3[0])) / 2;
  for (const n of s.notes ?? []) items.push(t(cx, top - 30, n.text, `lbl${n.acc === false ? "" : " acc"}`, { ...shown(n), enter: "rise" }));
  return frame("triangle-angles", items, s.alt, 14, { w: 300 });
}
