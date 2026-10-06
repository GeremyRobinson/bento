// Right triangles drawn to scale from their legs: a goes up, b goes across, the right angle sits bottom left.
// Optional squares on each side (the Pythagorean picture), side labels, angle marks and highlighted sides,
// each appearing at the beat the lesson gives.
import type { SceneDiagram } from "../scene/schema";
import { add, angleLabelAt, arc, dist, frame, mid, path, poly, seg, t, type Draft, type Pt } from "../geo/kit";

export type Side = "a" | "b" | "c";
interface Shown { from?: number; until?: number }
export interface SideLabel extends Shown { text: string; acc?: boolean }
export interface SquareSpec extends Shown {
  /** small line on top, e.g. "8²"; it can change at a later beat */
  top: { text: string; sup?: string; from?: number; until?: number; cls?: string }[];
  /** the area, e.g. "64", and the beat it appears */
  area: string;
  areaFrom: number;
}
export interface RightTriangleSpec {
  /** vertical leg and horizontal leg, in the problem's units; the picture keeps their ratio exactly */
  a: number;
  b: number;
  /** a side can change its label at a later beat: give several, each with its own from/until */
  sides?: Partial<Record<Side, SideLabel | SideLabel[]>>;
  squares?: Partial<Record<Side, SquareSpec>>;
  /** angle marks: B is the far end of leg b (between b and c), C the top of leg a (between a and c) */
  angles?: { at: "B" | "C"; text: string; from?: number; acc?: boolean }[];
  hl?: { side: Side; from: number; until?: number }[];
  alt: string;
  /** the box the triangle (and its squares) is fitted into */
  box?: number;
}

const beat = (s: Shown): Partial<Draft> => ({ ...(s.from ? { from: s.from } : {}), ...(s.until != null ? { until: s.until } : {}) });

export function buildRightTriangle(spec: RightTriangleSpec): SceneDiagram {
  const { a, b } = spec;
  if (!(a > 0 && b > 0)) throw new Error("legs must be positive");
  const box = spec.box ?? 380;
  const sq = spec.squares ?? {};
  const anySquare = !!(sq.a || sq.b || sq.c);
  // with squares the drawing spans (2a + b) across and (a + 2b) down; without, just the triangle
  const u = anySquare ? Math.min(box / (2 * a + b), box / (a + 2 * b)) : Math.min(box / b, (box * 0.7) / a);
  const A: Pt = [0, 0], B: Pt = [b * u, 0], C: Pt = [0, -a * u];
  const sides: Record<Side, [Pt, Pt]> = { a: [A, C], b: [A, B], c: [B, C] };
  // outward square on each side (away from the triangle)
  const squareOf: Record<Side, Pt[]> = {
    a: [A, C, add(C, [-a * u, 0]), add(A, [-a * u, 0])],
    b: [A, B, add(B, [0, b * u]), add(A, [0, b * u])],
    c: [B, C, add(C, [a * u, -b * u]), add(B, [a * u, -b * u])],
  };
  const items: Draft[] = [];

  // squares first, so the triangle draws over their edges
  (["a", "b", "c"] as Side[]).forEach(k => {
    const s = sq[k];
    if (!s) return;
    const pts = squareOf[k];
    const centre: Pt = [pts.reduce((x, p) => x + p[0], 0) / 4, pts.reduce((y, p) => y + p[1], 0) / 4];
    const side = dist(pts[0]!, pts[1]!);
    // roles (handoff-6): a² is part 1 (blue), b² part 2 (orange), c² the square being found (amber, dashed)
    items.push(poly(pts, k === "c" ? "sq big dash" : `cell c${k === "a" ? 0 : 1}`, { ...beat(s), enter: "pop" }));
    // two lines inside: the side squared, then the area. A square too small for both keeps the area inside
    // and puts the side squared just outside, on the side away from the triangle.
    const roomy = side >= 66;
    const gap = 16;
    for (const top of s.top) {
      const shown = { ...(top.sup ? { sup: top.sup } : {}), ...beat({ from: top.from ?? s.from, ...(top.until != null ? { until: top.until } : {}) }), enter: "rise" as const };
      if (roomy) items.push(t(centre[0], centre[1] - gap, top.text, top.cls ?? "sm", shown));
      else if (k === "a") items.push(t(centre[0] - side / 2 - 8, centre[1], top.text, `${top.cls ?? "sm"} end`, shown));
      else items.push(t(centre[0], centre[1] + side / 2 + 14, top.text, top.cls ?? "sm", shown));
    }
    items.push(t(centre[0], roomy ? centre[1] + gap * 0.75 : centre[1], s.area, `lbl${side >= 40 ? " big" : ""}${k === "c" ? " acc" : k === "a" ? " p0" : " p1"}`, { from: s.areaFrom, enter: "rise" }));
  });

  items.push(poly([A, B, C], "ln fillsoft", { enter: "draw" }));
  const k = Math.min(16, a * u * 0.3, b * u * 0.3);
  items.push(path([{ c: "M", p: [0, -k] }, { c: "L", p: [k, -k] }, { c: "L", p: [k, 0] }], "ax thin", { enter: "fade", delay: 0.5 }));

  // side labels sit outside the triangle; a side whose square is showing is labelled by the square instead
  const outside: Record<Side, { at: Pt; cls: string }> = {
    a: { at: [-12, -(a * u) / 2], cls: "end" },
    b: { at: [(b * u) / 2, 20], cls: "" },
    c: { at: add(mid(B, C), [(a / Math.hypot(a, b)) * 14, -(b / Math.hypot(a, b)) * 14]), cls: "start" },
  };
  (["a", "b", "c"] as Side[]).forEach(s => {
    const given = spec.sides?.[s];
    if (!given) return;
    const o = outside[s];
    const sqFrom = sq[s]?.from;
    for (const l of Array.isArray(given) ? given : [given]) {
      const until = l.until ?? (sqFrom != null ? sqFrom - 1 : undefined);
      // a leg's label takes its part color (a blue, b orange) whenever squares show them; c and any unknown are amber
      const role = l.acc ? " acc" : anySquare && s !== "c" ? (s === "a" ? " p0" : " p1") : "";
      items.push(t(o.at[0], o.at[1], l.text, `lbl ${o.cls}${role}`.trim(), { ...beat({ ...(l.from ? { from: l.from } : {}), ...(until != null ? { until } : {}) }), enter: "rise", delay: 0.3 }));
    }
  });

  for (const m of spec.angles ?? []) {
    const v = m.at === "B" ? B : C;
    const d0 = m.at === "B" ? 180 : 270;
    const d1 = m.at === "B" ? 180 - (Math.atan2(a, b) * 180) / Math.PI : 270 + (Math.atan2(b, a) * 180) / Math.PI;
    const r = Math.min(34, dist(A, v) * 0.4);
    items.push(path(arc(v, r, Math.min(d0, d1), Math.max(d0, d1)), "ln2", { ...beat(m), enter: "draw" }));
    const w = m.text.length * 10.2;
    const at = angleLabelAt(v, d0, d1, w, r + 16);
    items.push(t(at[0], at[1], m.text, `lbl${m.acc === false ? "" : " acc"}`, { ...beat(m), enter: "rise", delay: 0.2 }));
  }

  for (const h of spec.hl ?? []) {
    const [p, q] = sides[h.side];
    items.push(seg(p, q, "hlline", { from: h.from, ...(h.until != null ? { until: h.until } : {}), enter: "draw" }));
  }
  return frame("right-triangle", items, spec.alt, 14);
}

/** The triangle's three corners as drawn (right angle, end of b, top of a), for tests. */
export function triangleCorners(d: SceneDiagram): Pt[] {
  const tri = d.items.find(i => i.type === "path" && i.cls === "ln fillsoft");
  if (!tri || tri.type !== "path") return [];
  return [...tri.d.matchAll(/[ML](-?[\d.]+) (-?[\d.]+)/g)].map(m => [Number(m[1]), Number(m[2])] as Pt);
}
