// Solid shapes for k-solids and g2-solids (design/pictures-k4.md §2): one fixed oblique view (depth at 45°, half length),
// two flat tones (front face 30%, other visible faces 55%) in part blue (one color for every solid, so color never stands for a kind; handoff-6), solid visible edges, hidden edges dashed only when counting edges.
import type { SceneDiagram } from "../scene/schema";
import { frame, path, t, M, L, Z, type Draft, type Pt, type Seg } from "../geo/kit";
import { WIDE } from "./fit";

export type SolidKind = "cube" | "box" | "triPrism" | "pyramid" | "sphere" | "cylinder" | "cone";
/** the flat solids: corners, edges and faces you can count */
export const POLY_COUNTS: Record<"cube" | "box" | "triPrism" | "pyramid", { faces: number; edges: number; corners: number }> = {
  cube: { faces: 6, edges: 12, corners: 8 },
  box: { faces: 6, edges: 12, corners: 8 },
  pyramid: { faces: 5, edges: 8, corners: 5 },
  triPrism: { faces: 5, edges: 9, corners: 6 },
};

interface Poly { v: Pt[]; faces: { at: number[]; front: boolean; seen: boolean }[]; edges: [number, number][]; hidden: number }

const K = Math.SQRT1_2 / 2;
const off = (p: Pt, d: Pt): Pt => [p[0] + d[0], p[1] + d[1]];

/** a box w wide, h tall, d deep; sx = 1 shows the right side, −1 the left */
function box(w: number, h: number, d: number, sx: 1 | -1): Poly {
  const D: Pt = [sx * d * K, -d * K];
  const f: Pt[] = [[0, 0], [w, 0], [w, h], [0, h]], v = [...f, ...f.map(p => off(p, D))];
  return {
    v,
    faces: [
      { at: [0, 1, 2, 3], front: true, seen: true },
      { at: [0, 1, 5, 4], front: false, seen: true },
      { at: [1, 5, 6, 2], front: false, seen: sx > 0 },
      { at: [0, 4, 7, 3], front: false, seen: sx < 0 },
      { at: [4, 5, 6, 7], front: false, seen: false },
      { at: [3, 2, 6, 7], front: false, seen: false },
    ],
    edges: [[0, 1], [1, 2], [2, 3], [3, 0], [4, 5], [5, 6], [6, 7], [7, 4], [0, 4], [1, 5], [2, 6], [3, 7]],
    hidden: sx > 0 ? 7 : 6,
  };
}

function triPrism(w: number, h: number, d: number, sx: 1 | -1): Poly {
  const D: Pt = [sx * d * K, -d * K];
  const f: Pt[] = [[0, h], [w, h], [w / 2, 0]], v = [...f, ...f.map(p => off(p, D))];
  return {
    v,
    faces: [
      { at: [0, 1, 2], front: true, seen: true },
      { at: [2, 5, 4, 1], front: false, seen: sx > 0 },
      { at: [0, 2, 5, 3], front: false, seen: sx < 0 },
      { at: [3, 4, 5], front: false, seen: false },
      { at: [0, 1, 4, 3], front: false, seen: false },
    ],
    edges: [[0, 1], [1, 2], [2, 0], [3, 4], [4, 5], [5, 3], [0, 3], [1, 4], [2, 5]],
    hidden: sx > 0 ? 3 : 4,
  };
}

function pyramid(s: number, h: number, sx: 1 | -1): Poly {
  const D: Pt = [sx * s * K, -s * K];
  const v: Pt[] = [[0, h], [s, h], off([s, h], D), off([0, h], D)];
  v.push([(v[0]![0] + v[2]![0]) / 2, (v[0]![1] + v[2]![1]) / 2 - h]);
  return {
    v,
    faces: [
      { at: [0, 1, 4], front: true, seen: true },
      { at: [1, 2, 4], front: false, seen: sx > 0 },
      { at: [3, 0, 4], front: false, seen: sx < 0 },
      { at: [2, 3, 4], front: false, seen: false },
      { at: [0, 1, 2, 3], front: false, seen: false },
    ],
    edges: [[0, 1], [1, 2], [2, 3], [3, 0], [0, 4], [1, 4], [2, 4], [3, 4]],
    hidden: sx > 0 ? 3 : 2,
  };
}

function polyOf(kind: SolidKind, turn: number): Poly | null {
  const sx: 1 | -1 = turn === 1 ? -1 : 1;
  switch (kind) {
    case "cube": return box(120, 120, 120, sx);
    case "box": return turn === 2 ? box(190, 80, 120, sx) : turn === 1 ? box(110, 160, 90, sx) : box(170, 100, 110, sx);
    case "triPrism": return turn === 2 ? triPrism(130, 90, 200, sx) : triPrism(150, 120, 130, sx);
    case "pyramid": return pyramid(turn === 2 ? 150 : 130, turn === 2 ? 120 : 150, sx);
    default: return null;
  }
}

/** what you can see of a flat solid: faces and edges in view */
export function seenCounts(kind: "cube" | "box" | "triPrism" | "pyramid", turn: number) {
  const p = polyOf(kind, turn)!;
  return { faces: p.faces.filter(f => f.seen).length, edges: p.edges.filter(e => !e.includes(p.hidden)).length };
}

const r2 = (v: number) => Math.round(v * 100) / 100;
const polySegs = (pts: Pt[]): Seg[] => [M(pts[0]!), ...pts.slice(1).map(L), Z];

/** half (or all) of an ellipse as an arc segment, with points along it so the picture is framed right */
function arcTo(c: Pt, rx: number, ry: number, a0: number, a1: number, join = true): Seg[] {
  const at = (a: number): Pt => [c[0] + rx * Math.cos(a), c[1] + ry * Math.sin(a)];
  const samples = Array.from({ length: 13 }, (_, i) => at(a0 + ((a1 - a0) * i) / 12));
  return [...(join ? [] : [M(at(a0))]), { c: "A", r: rx, ry, large: Math.abs(a1 - a0) > Math.PI ? 1 : 0, sweep: a1 > a0 ? 1 : 0, p: at(a1), samples }];
}
const fullEllipse = (c: Pt, rx: number, ry: number): Seg[] => [...arcTo(c, rx, ry, Math.PI, 0, false), ...arcTo(c, rx, ry, 0, -Math.PI), Z];

export interface SolidSpec {
  kind: SolidKind;
  /** 0 upright, 1 the other side in view, 2 on its side */
  turn: number;
  /** a real thing drawn in the shape's outline (k-solids): its index in the shape's list */
  thing?: number;
  /** dashed hidden edges (g2-solids, where edges are counted) */
  hidden?: boolean;
  /**
   * beats: faces lit with a running count, edges traced, corners popped, the solid sliding or rolling, the name.
   * Leave any out; leave all out for the practice picture.
   */
  beats?: { faces?: number; edges?: number; corners?: number; move?: number; name?: number; until?: number };
  name?: string;
  /** count out loud (g2-solids): every face lights in turn, hidden ones too, with a running count beside the solid */
  running?: boolean;
  alt: string;
}

type Timing = { from?: number; until?: number; enter?: Draft["enter"]; delay?: number; vars?: Record<string, string | number> };

/** The solid's own drawing at x offset dx. */
function drawSolid(s: SolidSpec, dx: number, o: Timing): Draft[] {
  return drawShape(s, dx, o);
}


function drawShape(s: SolidSpec, dx: number, o: Timing): Draft[] {
  const items: Draft[] = [], sh = (p: Pt): Pt => [p[0] + dx, p[1]];
  const poly = polyOf(s.kind, s.turn);
  if (poly) {
    const v = poly.v.map(sh);
    for (const f of poly.faces) if (f.seen) items.push(path(polySegs(f.at.map(i => v[i]!)), f.front ? "sol f" : "sol b", o));
    for (const [a, b] of poly.edges) {
      const hid = a === poly.hidden || b === poly.hidden;
      if (hid && !s.hidden) continue;
      items.push(path([M(v[a]!), L(v[b]!)], hid ? "hid" : "edge", o));
    }
    if (s.kind === "cube" && s.thing === 1) {
      // dice pips on the front face
      for (const [x, y] of [[30, 30], [60, 60], [90, 90]] as Pt[]) items.push({ type: "circle", cx: x + dx, cy: y, r: 9, cls: "marble c1", ...o } as Draft);
    } else if (s.kind === "cube" && s.thing === 2) {
      items.push(path([M(sh([60, 0])), L(sh([60, 120]))], "detail c1", o), path([M(sh([0, 60])), L(sh([120, 60]))], "detail c1", o));
    } else if (s.kind === "cube" && s.thing === 0) {
      items.push(path(polySegs([sh([22, 22]), sh([98, 22]), sh([98, 98]), sh([22, 98])]), "detail c1", o));
    }
    return items;
  }
  const r = 64, ry = 0.28 * r;
  if (s.kind === "sphere") {
    const c: Pt = sh([0, 0]);
    items.push({ type: "circle", cx: c[0], cy: c[1], r, cls: "sol f", ...o } as Draft, { type: "circle", cx: c[0], cy: c[1], r, cls: "edge", ...o } as Draft);
    items.push(path(arcTo(c, r, ry, Math.PI, 0, false), "edge thin", o));
    items.push(path(arcTo(c, r, ry, Math.PI, 2 * Math.PI, false), "hid", o));
    if (s.thing === 0) items.push(path(arcTo(c, r * 0.45, r * 0.95, -Math.PI / 2, Math.PI / 2, false), "detail c1", o));
    if (s.thing === 1) items.push({ type: "circle", cx: c[0] + 8, cy: c[1] - r - 6, r: 9, cls: "marble c2", ...o } as Draft);
    if (s.thing === 2) items.push(path(arcTo([c[0] - 10, c[1] + 6], 26, 34, -2.4, 1.2, false), "detail c2", o));
    return items;
  }
  const H = 140, lying = s.turn === 2;
  if (s.kind === "cylinder") {
    if (!lying) {
      const top: Pt = sh([0, 0]), bot: Pt = sh([0, H]);
      items.push(path([M([top[0] - r, top[1]]), L([bot[0] - r, bot[1]]), ...arcTo(bot, r, ry, Math.PI, 0), L([top[0] + r, top[1]]), Z], "sol f", o));
      items.push(path(fullEllipse(top, r, ry), "sol b", o));
      items.push(path([M([top[0] - r, top[1]]), L([bot[0] - r, bot[1]]), ...arcTo(bot, r, ry, Math.PI, 0), L([top[0] + r, top[1]])], "edge", o), path(fullEllipse(top, r, ry), "edge", o));
      if (s.thing === 0) items.push(path(polySegs([[top[0] - r, top[1] + 40], [top[0] + r, top[1] + 40], [top[0] + r, top[1] + 92], [top[0] - r, top[1] + 92]]), "detail c1 fillc", o));
      if (s.thing === 1) items.push(path([M([top[0] - r, top[1] + 30]), L([top[0] - r / 2, top[1] + H - 10]), L([top[0], top[1] + 30]), L([top[0] + r / 2, top[1] + H - 10]), L([top[0] + r, top[1] + 30])], "detail c1", o));
      if (s.thing === 2) items.push(path([M([top[0], top[1] - 8]), L([top[0], top[1] - 22])], "detail c2", o), { type: "circle", cx: top[0], cy: top[1] - 32, r: 9, cls: "marble c2", ...o } as Draft);
    } else {
      const W = 180, c0: Pt = sh([0, 0]), c1: Pt = sh([W, 0]), rx = 0.28 * r;
      items.push(path([M([c0[0], c0[1] - r]), L([c1[0], c1[1] - r]), L([c1[0], c1[1] + r]), L([c0[0], c0[1] + r]), ...arcTo(c0, rx, r, Math.PI / 2, 3 * Math.PI / 2), Z], "sol f", o));
      items.push(path(fullEllipse(c1, rx, r), "sol b", o));
      items.push(path([M([c1[0], c1[1] - r]), L([c0[0], c0[1] - r]), ...arcTo(c0, rx, r, -Math.PI / 2, -3 * Math.PI / 2), L([c1[0], c1[1] + r])], "edge", o), path(fullEllipse(c1, rx, r), "edge", o));
      if (s.thing === 0) items.push(path(polySegs([[c0[0] + 50, c0[1] - r], [c0[0] + 120, c0[1] - r], [c0[0] + 120, c0[1] + r], [c0[0] + 50, c0[1] + r]]), "detail c1 fillc", o));
    }
    return items;
  }
  // cone: upright, upside down (an ice-cream cone) or on its side
  const flip = s.thing === 1 && !lying;
  if (!lying) {
    const base: Pt = sh([0, flip ? 0 : H]), apex: Pt = sh([0, flip ? H : 0]);
    if (flip) {
      items.push(path([M([base[0] - r, base[1]]), L(apex), L([base[0] + r, base[1]]), Z], "sol f", o), path(fullEllipse(base, r, ry), "sol b", o));
      items.push(path([M([base[0] - r, base[1]]), L(apex), L([base[0] + r, base[1]])], "edge", o), path(fullEllipse(base, r, ry), "edge", o));
      items.push({ type: "circle", cx: base[0], cy: base[1] - 30, r: 46, cls: "marble c1", ...o } as Draft);
      items.push(path([M([base[0] - 30, base[1] + 20]), L([base[0] + 14, base[1] + 80]), M([base[0] + 30, base[1] + 20]), L([base[0] - 14, base[1] + 80])], "detail c2", o));
    } else {
      items.push(path([M([base[0] - r, base[1]]), L(apex), L([base[0] + r, base[1]]), ...arcTo(base, r, ry, 0, Math.PI), Z], "sol f", o));
      items.push(path([M([base[0] - r, base[1]]), L(apex), L([base[0] + r, base[1]]), ...arcTo(base, r, ry, 0, Math.PI)], "edge", o));
      if (s.thing === 0) for (const k of [0.35, 0.65]) items.push(path([M([apex[0] - r * k, apex[1] + H * k]), L([apex[0] + r * k, apex[1] + H * k])], "detail c1", o));
      if (s.thing === 2) items.push(path(polySegs([[apex[0] - r * 0.45, apex[1] + H * 0.45], [apex[0] + r * 0.45, apex[1] + H * 0.45], [apex[0] + r * 0.65, apex[1] + H * 0.65], [apex[0] - r * 0.65, apex[1] + H * 0.65]]), "detail c1 fillc", o));
    }
  } else {
    const base: Pt = sh([H, 0]), apex: Pt = sh([0, 0]), rx = 0.28 * r;
    items.push(path([M([base[0], base[1] - r]), L(apex), L([base[0], base[1] + r]), Z], "sol f", o), path(fullEllipse(base, rx, r), "sol b", o));
    items.push(path([M([base[0], base[1] - r]), L(apex), L([base[0], base[1] + r])], "edge", o), path(fullEllipse(base, rx, r), "edge", o));
  }
  return items;
}

/** flat faces you can see, for lighting them in turn */
function litFaces(s: SolidSpec, dx: number): Seg[][] {
  const poly = polyOf(s.kind, s.turn), sh = (p: Pt): Pt => [p[0] + dx, p[1]];
  if (poly) return poly.faces.filter(f => f.seen).map(f => polySegs(f.at.map(i => sh(poly.v[i]!))));
  const r = 64, ry = 0.28 * r, H = 140, lying = s.turn === 2;
  if (s.kind === "cylinder") return [lying ? fullEllipse(sh([180, 0]), 0.28 * r, r) : fullEllipse(sh([0, 0]), r, ry)];
  if (s.kind === "cone") return [lying ? fullEllipse(sh([H, 0]), 0.28 * r, r) : s.thing === 1 ? fullEllipse(sh([0, 0]), r, ry) : fullEllipse(sh([0, H]), r, ry)];
  return [];
}

export function buildSolid(s: SolidSpec): SceneDiagram {
  const b = s.beats ?? {}, items: Draft[] = [];
  const end = b.move != null ? b.move - 1 : undefined;
  items.push(...drawSolid(s, 0, end != null ? { from: 0, until: end } : { from: 0 }));
  const poly = polyOf(s.kind, s.turn);
  const counts = poly ? POLY_COUNTS[s.kind as keyof typeof POLY_COUNTS] : null;
  const bottom = Math.max(...(poly ? poly.v.map(p => p[1]) : [s.kind === "sphere" ? 64 : s.turn === 2 ? 64 : 140]));
  const label = (y: number, text: string, from: number, until?: number, delay = 0) => items.push(t(poly ? 90 : 40, bottom + y, text, "lbl", { from, ...(until != null ? { until } : {}), enter: "rise", ...(delay ? { delay: Math.round(delay * 100) / 100 } : {}) }));
  // a running count beside the solid: each number shows while its thing lights, the last one stays
  const right = Math.max(...(poly ? poly.v.map(p => p[0]) : [64])) + 44, midY = poly ? (Math.min(...poly.v.map(p => p[1])) + bottom) / 2 : 0;
  // Learn plays a beat every 1.8 s, so every count finishes inside its beat: the last thing lights by COUNT_IN seconds
  // and its number has popped before the step moves on. The label naming the total comes in as the count reaches it,
  // so the text and the number never disagree (review v45 blocker 6: "6 flat faces" showed while the count read 1, 2).
  const COUNT_IN = 1.1;
  const stepFor = (n: number, most: number) => (n > 1 ? Math.min(most, COUNT_IN / (n - 1)) : 0);
  const runCount = (n: number, from: number, step: number, until?: number) => {
    for (let i = 0; i < n; i++) {
      const last = i === n - 1, d = r2(step * i);
      items.push(t(right, midY, String(i + 1), "lbl big acc", { from, ...(until != null ? { until } : {}), enter: last ? "pop" : "flash", delay: d, ...(last ? {} : { vars: { "--d2": `${(d + step).toFixed(2)}s` } }) }));
    }
  };
  if (b.faces != null && s.running && poly) {
    const stop = b.edges ?? b.move ?? b.name, until = stop != null ? stop - 1 : undefined, n = poly.faces.length, step = stepFor(n, 0.7);
    poly.faces.forEach((f, i) => items.push(path(polySegs(f.at.map(k => poly.v[k]!)), "lit", { from: b.faces!, ...(until != null ? { until } : {}), enter: "flash", delay: r2(step * i), vars: { "--d2": `${(step * i + step).toFixed(2)}s` } })));
    runCount(n, b.faces, step, until);
    label(40, `${counts!.faces} flat faces`, b.faces, until, step * (n - 1));
  } else if (b.faces != null) {
    const faces = litFaces(s, 0), stop = b.edges ?? b.move ?? b.name;
    faces.forEach((f, i) => items.push(path(f, "lit", { from: b.faces!, ...(stop != null ? { until: stop - 1 } : {}), enter: "fade", delay: 0.6 * i })));
    const n = counts ? counts.faces : s.kind === "cylinder" ? 2 : s.kind === "cone" ? 1 : 0;
    label(40, n ? `${n} flat face${n === 1 ? "" : "s"}` : "no flat faces", b.faces, stop != null ? stop - 1 : undefined);
  }
  if (poly && b.edges != null) {
    const stop = b.corners ?? b.name, n = poly.edges.length, step = stepFor(n, 0.25);
    poly.edges.forEach(([a, c], i) => items.push(path([M(poly.v[a]!), L(poly.v[c]!)], "litedge", { from: b.edges!, ...(stop != null ? { until: stop - 1 } : {}), enter: "draw", delay: r2(step * i) })));
    if (s.running) runCount(n, b.edges, step, stop != null ? stop - 1 : undefined);
    label(40, `${counts!.edges} edges`, b.edges, stop != null ? stop - 1 : undefined, step * (n - 1));
  }
  if (poly && b.corners != null) {
    const n = poly.v.length, step = stepFor(n, 0.3);
    poly.v.forEach((p, i) => items.push({ type: "circle", cx: p[0], cy: p[1], r: 6, cls: "dota", from: b.corners!, enter: "pop", delay: r2(step * i) } as Draft));
    if (s.running) runCount(n, b.corners, step, b.name != null ? b.name - 1 : undefined);
    label(40, `${counts!.corners} corners`, b.corners, b.name != null ? b.name - 1 : undefined, step * (n - 1));
  }
  if (b.move != null) {
    const rolls = s.kind !== "cube" && s.kind !== "box";
    items.push(...drawSolid(s, 120, { from: b.move, enter: "slide", vars: { "--dx": "-120px" } }));
    items.push(path([M([-80, bottom + 6]), L([poly ? 330 : 330, bottom + 6])], "floor", { from: b.move }));
    items.push(t(150, bottom + 40, rolls ? "it rolls" : "it slides", "lbl", { from: b.move, ...(b.name != null ? { until: b.name - 1 } : {}), enter: "rise", delay: 0.6 }));
  }
  if (b.name != null && s.name) items.push(t(b.move != null ? 150 : poly ? 90 : 40, bottom + 40, s.name, "lbl big acc", { from: b.name, enter: "rise" }));
  return frame("early-solids", items, s.alt, 18, WIDE);
}
