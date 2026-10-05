// Points, lines, rays, angles and pairs of lines (g4-lines). Practice shows the figure only, turned; Learn shows what
// the name means: a line runs on past both arrowheads, a ray past one; an angle opens from 0 beside a square corner;
// two lines run on until they meet, or never do.
import type { SceneDiagram } from "../scene/schema";
import { frame, path, t, M, L, Z, type Draft, type Pt } from "../geo/kit";

const rot = (p: Pt, deg: number): Pt => { const a = (deg * Math.PI) / 180; return [p[0] * Math.cos(a) - p[1] * Math.sin(a), p[0] * Math.sin(a) + p[1] * Math.cos(a)]; };
const dirOf = (deg: number): Pt => [Math.cos((deg * Math.PI) / 180), -Math.sin((deg * Math.PI) / 180)];
const at = (p: Pt, u: Pt, k: number): Pt => [p[0] + u[0] * k, p[1] + u[1] * k];

/** an arrowhead at tip pointing along u */
function arrow(tip: Pt, u: Pt, o: Partial<Draft> = {}, cls = "arrowhead"): Draft {
  const n: Pt = [-u[1], u[0]], back = at(tip, u, -16);
  return path([M(tip), L(at(back, n, 8)), L(at(back, n, -8)), Z], cls, o);
}
const dot = (p: Pt, cls = "figdot", o: Partial<Draft> = {}): Draft => ({ type: "circle", cx: p[0], cy: p[1], r: 6, cls, ...o }) as Draft;

export interface FigureSpec {
  /** 0 line, 1 ray, 2 segment */
  item: number;
  turn: number;
  beats?: { more: number; name: number };
  name?: string;
  alt: string;
}

export function buildFigure(s: FigureSpec): SceneDiagram {
  const u = dirOf(s.turn), A = at([0, 0], u, -110), B = at([0, 0], u, 110), b = s.beats, items: Draft[] = [];
  if (b) {
    if (s.item === 0) items.push(path([M(at(A, u, -90)), L(A)], "ln2 dash", { from: b.more, enter: "draw" }));
    if (s.item <= 1) items.push(path([M(B), L(at(B, u, 90))], "ln2 dash", { from: b.more, enter: "draw" }));
    if (s.item <= 1) items.push(t(...at(B, u, 50), "on and on", "xs acc", { from: b.more, enter: "rise", delay: 0.6 }));
  }
  items.push(path([M(A), L(B)], "figline"));
  if (s.item === 0) items.push(arrow(A, [-u[0], -u[1]]), arrow(B, u));
  if (s.item === 1) items.push(dot(A), arrow(B, u));
  if (s.item === 2) items.push(dot(A), dot(B));
  const n: Pt = [-u[1], u[0]];
  items.push(t(...at(at(A, u, 6), n, 26), "A", "lbl"), t(...at(at(B, u, -6), n, 26), "B", "lbl"));
  if (b) {
    if (s.item >= 1) items.push(dot(A, "dota", { from: b.more, enter: "pop" }));
    if (s.item === 2) items.push(dot(B, "dota", { from: b.more, enter: "pop" }));
    if (s.name) items.push(t(0, 150, s.name, "lbl big acc", { from: b.name, enter: "rise" }));
  }
  return frame("figure", items, s.alt, 16, { w: 360, h: 220 });
}

export interface AngleFigSpec {
  deg: number;
  turn: number;
  /** arm lengths: long arms on a small angle tempt "bigger" */
  arm: number;
  beats?: { open: number; name: number };
  name?: string;
  alt: string;
}

export function buildAngleFig(s: AngleFigSpec): SceneDiagram {
  const V: Pt = [0, 0], u1 = dirOf(s.turn), u2 = dirOf(s.turn + s.deg), b = s.beats, items: Draft[] = [];
  const P1 = at(V, u1, s.arm), P2 = at(V, u2, s.arm);
  if (b) {
    // a square corner card at the vertex, along the first arm
    const c1 = at(V, u1, 40), c3 = at(V, dirOf(s.turn + 90), 40), c2 = at(c1, dirOf(s.turn + 90), 40);
    items.push(path([M(V), L(c1), L(c2), L(c3), Z], "card", { from: b.open, enter: "fade" }));
  }
  items.push(path([M(P1), L(V)], "figline"));
  items.push(path([M(V), L(P2)], "figline second p1", b ? { from: 0, enter: "swing" as Draft["enter"], vars: { "--from": `${s.deg}deg` } } : {}));
  items.push(arrow(P1, u1));
  items.push(arrow(P2, u2, b ? { enter: "swing" as Draft["enter"], vars: { "--from": `${s.deg}deg` } } : {}, "arrowhead p1"));
  items.push(dot(V));
  if (s.deg === 90) {
    const c1 = at(V, u1, 18), c2 = at(c1, u2, 18), c3 = at(V, u2, 18);
    items.push(path([M(c1), L(c2), L(c3)], "ln2", b ? { from: b.open, enter: "draw", delay: 0.9 } : {}));
  } else {
    const r = 30, pts = Array.from({ length: 13 }, (_, i) => at(V, dirOf(s.turn + (s.deg * i) / 12), r));
    items.push(path([M(pts[0]!), ...pts.slice(1).map(L)], "ln2", b ? { from: b.open, enter: "draw", delay: 0.9 } : {}));
  }
  if (b && s.name) items.push(t(0, s.arm + 40, s.name, "lbl big acc", { from: b.name, enter: "rise" }));
  // room on every side, so turning never changes the frame
  items.push({ type: "line", x1: -s.arm, y1: -s.arm, x2: -s.arm, y2: -s.arm, cls: "spacer" } as Draft, { type: "line", x1: s.arm, y1: s.arm, x2: s.arm, y2: s.arm, cls: "spacer" } as Draft);
  const sc = frame("angle-fig", items, s.alt, 16, {});
  const hub = sc.items.find(i => i.type === "circle" && i.cls === "figdot") as { cx: number; cy: number } | undefined;
  if (hub) for (const it of sc.items) if (it.enter === ("swing" as Draft["enter"])) it.vars = { ...it.vars, "--ox": `${hub.cx}px`, "--oy": `${hub.cy}px` };
  return sc;
}

export interface PairSpec {
  /** 0 parallel, 1 perpendicular, 2 intersecting */
  item: number;
  /** the angle between them, for intersecting */
  deg: number;
  turn: number;
  beats?: { run: number; name: number };
  name?: string;
  alt: string;
}

export function buildPair(s: PairSpec): SceneDiagram {
  const b = s.beats, items: Draft[] = [], T = (p: Pt) => rot(p, -s.turn);
  const seg = (p: Pt, q: Pt, cls: string, o: Partial<Draft> = {}) => path([M(T(p)), L(T(q))], cls, o);
  // the second line of a pair takes the next grade color
  const ends = (p: Pt, q: Pt, cls = "arrowhead") => {
    const d: Pt = [q[0] - p[0], q[1] - p[1]], l = Math.hypot(...d), u: Pt = [d[0] / l, d[1] / l];
    items.push(arrow(T(q), rot(u, -s.turn), {}, cls), arrow(T(p), rot([-u[0], -u[1]], -s.turn), {}, cls));
  };
  if (s.item === 0) {
    items.push(seg([-130, -40], [130, -40], "figline"), seg([-130, 40], [130, 40], "figline p1"));
    ends([-130, -40], [130, -40]); ends([-130, 40], [130, 40], "arrowhead p1");
    if (b) for (const y of [-40, 40]) items.push(seg([130, y], [200, y], "ln2 dash", { from: b.run, enter: "draw" }), seg([-200, y], [-130, y], "ln2 dash", { from: b.run, enter: "draw" }));
    if (b) items.push(seg([160, -40], [160, 40], "ln thin", { from: b.run, enter: "fade", delay: 0.8 }), seg([-160, -40], [-160, 40], "ln thin", { from: b.run, enter: "fade", delay: 0.8 }));
  } else if (s.item === 1) {
    items.push(seg([-130, 0], [130, 0], "figline"), seg([0, -100], [0, 100], "figline p1"));
    ends([-130, 0], [130, 0]); ends([0, -100], [0, 100], "arrowhead p1");
    if (b) items.push(path([M(T([0, -18])), L(T([18, -18])), L(T([18, 0]))], "ln2", { from: b.run, enter: "draw" }));
  } else {
    // two lines leaning together: they meet off to the right, past what's drawn
    const a = (s.deg * Math.PI) / 180, X = 230, y2 = (x: number) => -Math.tan(a) * (x - X);
    items.push(seg([-130, 0], [130, 0], "figline"), seg([-130, y2(-130) * 0.5], [130, y2(130) * 0.5], "figline p1"));
    ends([-130, 0], [130, 0]); ends([-130, y2(-130) * 0.5], [130, y2(130) * 0.5], "arrowhead p1");
    if (b) {
      const Y = (x: number) => y2(x) * 0.5, meet: Pt = [X, 0];
      items.push(seg([130, 0], meet, "ln2 dash", { from: b.run, enter: "draw" }), seg([130, Y(130)], meet, "ln2 dash", { from: b.run, enter: "draw" }));
      items.push({ ...dot(T(meet), "dota"), from: b.run, enter: "pop", delay: 0.9 } as Draft);
    }
  }
  if (b && s.name) items.push(t(0, 150, s.name, "lbl big acc", { from: b.name, enter: "rise" }));
  return frame("line-pair", items, s.alt, 16, { w: 360 });
}
