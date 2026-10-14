// A triangle drawn with its real angles: the two base corners are given, the top corner is whatever is left.
// Each corner gets an arc and labels that can change by beat; an exterior angle can open at the right corner.
import type { SceneDiagram } from "../scene/schema";
import { angleLabelAt, arc, dist, frame, path, poly, polar, r1, seg, t, type Draft, type Pt } from "../geo/kit";
import { PIC } from "../scene/picture-system";

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
  // drawn at about a phone strip's size, so labels laid out at their phone size land where they are drawn
  const u = Math.max(150, Math.min(340 / (Math.max(...xs) - Math.min(...xs)), 140 / (Math.max(...ys) - Math.min(...ys))));
  const P1: Pt = [0, 0], P2: Pt = [u, 0], P3: Pt = [apex1[0] * u, apex1[1] * u];
  const items: Draft[] = [poly([P1, P2, P3], "ln fillsoft", { enter: "draw" })];

  // on a phone a label grows with the floor about its own middle, so at the outside angle's corner the inside and outside
  // labels grow into each other: there each steps away by what it grew, the outside one along its angle's middle and the
  // inside one away from the labels round it (Review b4fa4b3, 84583e8)
  const out = (deg: number) => ({ translate: ["cos", "sin"].map((f, k) => `calc(${r1((f === "cos" ? Math.cos : Math.sin)((deg * Math.PI) / 180) * (k ? -1 : 1))} * (max(${PIC.label}, ${PIC.label} * var(--px, 0)) - ${PIC.label}) * 1px)`).join(" ") });
  const stepped: { it: Draft; at: Pt; d0: number; span: number }[] = [];
  const corner = (v: Pt, d0: number, d1: number, labels: CornerLabel[], accentFrom: number | undefined, arcR: number, maxR: number, step = false) => {
    const span = d1 - d0;
    const r = Math.min(arcR, maxR * 0.6);
    if (accentFrom != null) {
      if (accentFrom > 0) items.push(path(arc(v, r, d0, d1), "ln", { until: accentFrom - 1, enter: "draw", delay: 0.6 }));
      items.push(path(arc(v, r, d0, d1), "ln2", { from: accentFrom, enter: "draw", delay: accentFrom ? 0 : 0.6 }));
    } else items.push(path(arc(v, r, d0, d1), "ln", { enter: "draw", delay: 0.6 }));
    for (const l of labels) {
      const gap = s.labelGap ?? 14;
      const at = angleLabelAt(v, d0, d0 + span, l.text.length * 10.2, r + gap, Math.max(r + gap, maxR));
      const it = t(at[0], at[1], l.text, `lbl${l.acc ? " acc" : ""}`, { ...shown(l), enter: "rise", delay: 0.8 });
      items.push(it);
      if (step) stepped.push({ it, at, d0, span });
    }
  };
  const a = dist(P1, P2), b = dist(P2, P3), c = dist(P1, P3);
  corner(P1, 0, A, s.labels.left, s.accent?.left, 30, Math.min(a, c) * 0.7);
  corner(P2, 180 - B, 180, s.labels.right, s.accent?.right, 30, Math.min(a, b) * 0.7, !!s.exterior);
  corner(P3, 180 + A, 360 - B, s.labels.top, s.accent?.top, 26, Math.min(b, c) * 0.7);

  if (s.exterior) {
    const ext = s.exterior, from = ext.from ?? 0;
    const end: Pt = [P2[0] + Math.max(80, u * 0.35), 0];
    items.push(seg(P2, end, "ax dash", { ...shown(ext), enter: "draw" }));
    items.push(path(arc(P2, 24, 0, 180 - B), "ln2", { ...shown(ext), enter: "draw", delay: 0.4 }));
    for (const l of ext.labels) {
      const at = angleLabelAt(P2, 0, 180 - B, l.text.length * 10.2, 44, 160);
      items.push(t(at[0], at[1], l.text, "lbl acc", { ...shown({ from: Math.max(from, l.from ?? 0), ...(l.until != null ? { until: l.until } : {}) }), enter: "rise", delay: 0.6, vars: out((180 - B) / 2) }));
    }
  }
  // the inside label steps away from every other corner's label: the way the pushes from each (nearer pushing harder) add up
  for (const { it, at, d0, span } of stepped) {
    let dx = 0, dy = 0;
    for (const o of items) {
      if (o === it || o.type !== "text" || (o as { text: string }).text === (it as { text: string }).text) continue;
      const ox = at[0] - (o as { x: number }).x, oy = at[1] - (o as { y: number }).y, d2 = ox * ox + oy * oy;
      if (d2 > 0 && d2 < 160 * 160) { dx += ox / d2; dy += oy / d2; }
    }
    // it never steps down into the base: hemmed in on both sides it climbs the side it shares with the top corner
    const deg = (Math.atan2(-dy, dx) * 180) / Math.PI;
    if (dx || dy) (it as { vars?: Record<string, string> }).vars = out(Math.sin((deg * Math.PI) / 180) > 0.3 ? deg : d0 + span / 4);
  }
  const top = Math.min(P1[1], P2[1], P3[1]);
  const cx = (Math.min(P1[0], P3[0]) + Math.max(P2[0], P3[0])) / 2;
  // the working stands on its bottom edge above the triangle, so on a phone it grows up, away from the top corner;
  // in practice it leaves for the work list (.cap)
  for (const n of s.notes ?? []) items.push(t(cx, top - 12, n.text, `lbl up cap${n.acc === false ? "" : " acc"}`, { ...shown(n), enter: "rise" }));
  return frame("triangle-angles", items, s.alt, 14, { w: 240 });
}
