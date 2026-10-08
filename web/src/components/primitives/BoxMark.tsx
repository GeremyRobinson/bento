import { useEffect, useRef } from "react";
import { motionOff } from "../../app/settings";

/**
 * The logo mark (G 2026-10-08 01:10 "Looks great", 01:10 "You can update now"): solid blocks on a flat plate, no
 * outline. It rests on a little sum: a tall half, a square, and two flat bars stacked like an equals sign. From rest it
 * splits outwards round the box clockwise, then finds the shortest way home and holds there for a moment.
 *
 * G's grid rule, not to change: the plate is 13 x 13 grid cells. Every gap, block to block and block to the plate's
 * edge, is one whole cell, and every edge sits on a grid line. Splits are even: a half is 5 cells, a quarter 2.
 * Nothing opens up in the middle. Split = push in: a new block slides in from one side and the block it lands in shrinks
 * to make room. Absorb = push out: a block grows over its neighbours and pushes them out against the far side. Slide:
 * two neighbours of different sizes swap sizes. The moving edges ease together on the app's m-ease, so every gap stays
 * one cell the whole way. Mini squares are rare, and never at 60 px or below. Less motion: it holds the resting pose.
 */

/** a block in quarters of the plate's inside (0..4): left, top, right, bottom */
type Q4 = [number, number, number, number];
const V = 100, GRID = 13, U = V / GRID, R = U * .8, Q = 4;
/** the resting pose: the still mark and the app icon */
export const REST: Q4[] = [[0, 0, 2, 4], [2, 0, 4, 2], [2, 2, 4, 3], [2, 3, 4, 4]];
const MAIN_MS = 760, SIDE_MS = 560, BEAT_MS = 220, HOLD_MS = 2400, FIRST_HOLD_MS = 1400;

/** side v starts a block at grid line 1 + 3v and ends one at line 3v */
const drawn = (c: Q4) => c.map((v, k) => (k < 2 ? 1 + v * 3 : v * 3) * U) as Q4;
/** the app's m-ease, cubic-bezier(.2,.8,.2,1) */
const ease = (x: number) => {
  if (x <= 0) return 0;
  if (x >= 1) return 1;
  const f = (t: number, a: number, b: number) => 3 * a * t * (1 - t) * (1 - t) + 3 * b * t * t * (1 - t) + t * t * t;
  let lo = 0, hi = 1, t = x;
  for (let i = 0; i < 22; i++) { t = (lo + hi) / 2; if (f(t, .2, .2) < x) lo = t; else hi = t; }
  return f(t, .8, 1);
};
const sz = (c: Q4) => [c[2] - c[0], c[3] - c[1]] as const;
const area = (c: Q4) => sz(c)[0] * sz(c)[1];
const key = (cs: Q4[]) => cs.map(c => c.join(",")).sort().join("|");
const REST_KEY = key(REST);
const one = [1, 2, 4];
const fits = (c: Q4) => { const [w, h] = sz(c); return one.includes(w) && one.includes(h) && Math.max(w, h) <= 2 * Math.min(w, h); };
/** tidy: fits, sits on a multiple of its own size, and is never the whole plate */
const tidy = (c: Q4) => { const [w, h] = sz(c); return fits(c) && c[0] % w === 0 && c[1] % h === 0 && !(w === Q && h === Q); };
/** at least one heavy block, a square or bigger, so it always reads as a bento box (G 2026-10-08 01:13) */
const heavy = (cs: Q4[]) => cs.some(c => area(c) >= 4);
const inside = (c: Q4, r: Q4) => c[0] >= r[0] && c[2] <= r[2] && c[1] >= r[1] && c[3] <= r[3];

type Item = { c: Q4 };
type Move<T extends Item> =
  | { kind: "split"; b: T; ax: 0 | 1; halves: [Q4, Q4] }
  | { kind: "absorb"; a: T; g: T[]; u: Q4; ax: 0 | 1; dir: 1 | -1 }
  | { kind: "slide"; a: T; g: [T]; na: Q4; nb: Q4 };

/** every move from a layout: split across the longer side, absorb a same-size region beside a block, or slide */
function rawMoves<T extends Item>(items: T[], noMini: boolean): Move<T>[] {
  const out: Move<T>[] = [];
  for (const it of items) {
    const c = it.c, [w, h] = sz(c);
    for (const ax of [0, 1] as const) {
      const L = ax ? h : w, O = ax ? w : h;
      if (L < 2 || L < O) continue;
      const mid = (c[ax] + c[ax + 2]!) / 2, a = [...c] as Q4, b = [...c] as Q4;
      a[ax + 2] = mid; b[ax] = mid;
      if (noMini && area(a) < 2) continue;
      out.push({ kind: "split", b: it, ax, halves: [a, b] });
    }
  }
  for (const a of items) {
    const [l, t, r, b] = a.c, w = r - l, h = b - t;
    const sides: [Q4, 0 | 1, 1 | -1][] = [[[r, t, r + w, b], 0, 1], [[l - w, t, l, b], 0, -1], [[l, b, r, b + h], 1, 1], [[l, t - h, r, t], 1, -1]];
    for (const [reg, ax, dir] of sides) {
      if (reg[0] < 0 || reg[1] < 0 || reg[2] > Q || reg[3] > Q) continue;
      const g = items.filter(c => c !== a && inside(c.c, reg));
      if (!g.length || g.reduce((s, c) => s + area(c.c), 0) !== w * h) continue;
      const u: Q4 = [Math.min(l, reg[0]), Math.min(t, reg[1]), Math.max(r, reg[2]), Math.max(b, reg[3])];
      if (tidy(u)) out.push({ kind: "absorb", a, g, u, ax, dir });
    }
  }
  for (const a of items) for (const b of items) {
    if (a === b) continue;
    for (const ax of [0, 1] as const) {
      const o = 1 - ax;
      if (a.c[ax + 2] !== b.c[ax] || a.c[o] !== b.c[o] || a.c[o + 2] !== b.c[o + 2]) continue;
      const wa = a.c[ax + 2]! - a.c[ax]!, wb = b.c[ax + 2]! - b.c[ax]!;
      if (wa === wb) continue;
      const na = [...a.c] as Q4, nb = [...b.c] as Q4;
      na[ax + 2] = a.c[ax]! + wb; nb[ax] = na[ax + 2]!;
      if (fits(na) && fits(nb) && !(noMini && (area(na) < 2 || area(nb) < 2))) out.push({ kind: "slide", a, g: [b], na, nb });
    }
  }
  return out;
}
function result<T extends Item>(items: T[], m: Move<T>): Q4[] {
  const cs = items.map(i => i.c);
  if (m.kind === "split") return cs.filter(c => c !== m.b.c).concat(m.halves);
  if (m.kind === "slide") return cs.filter(c => c !== m.a.c && c !== m.g[0].c).concat([m.na, m.nb]);
  return cs.filter(c => c !== m.a.c && !m.g.some(x => x.c === c)).concat([m.u]);
}
/** how many moves a layout is from the resting pose: a short search, remembered */
const distMemo = new Map<string, number>();
function dist(cs: Q4[], noMini: boolean) {
  const k0 = key(cs) + (noMini ? "n" : "");
  const known = distMemo.get(k0);
  if (known !== undefined) return known;
  let frontier = [cs], d = Infinity;
  const seen = new Set([key(cs)]);
  for (let depth = 0; depth <= 6 && frontier.length; depth++) {
    if (frontier.some(f => key(f) === REST_KEY)) { d = depth; break; }
    const nx: Q4[][] = [];
    for (const f of frontier) {
      if (f.length > 7) continue;
      const its = f.map(c => ({ c }));
      for (const m of rawMoves(its, noMini)) { const r = result(its, m), k = key(r); if (heavy(r) && !seen.has(k)) { seen.add(k); nx.push(r); } }
    }
    frontier = nx;
  }
  distMemo.set(k0, d);
  return d;
}

type Block = { c: Q4; from: Q4; to: Q4; t0: number; len: number; gone: boolean; sib: number; prevSib?: number; kind?: string };
const block = (c: Q4): Block => ({ c: [...c] as Q4, from: drawn(c), to: drawn(c), t0: 0, len: 1, gone: false, sib: 0 });
const at = (b: Block, t: number) => { const k = ease((t - b.t0) / b.len); return b.from.map((f, i) => f + (b.to[i]! - f) * k) as Q4; };
const busy = (b: Block, t: number) => t < b.t0 + b.len;

/** one running mark: its blocks and the loop that moves them */
function makeSim(noMini: boolean, side: boolean) {
  const S = { blocks: REST.map(block), last: null as Block | null, angle: -Math.PI / 2, phase: "rest" as "rest" | "split" | "home", goal: 6, pair: 1, timers: [] as number[] };
  S.blocks[2]!.sib = S.blocks[3]!.sib = 1;
  const later = (fn: () => void, ms: number) => { S.timers.push(window.setTimeout(fn, ms)); };
  const moves = (t: number) => {
    const live = S.blocks.filter(b => !b.gone);
    return rawMoves(live.filter(b => !busy(b, t)), noMini).map(m => ({ m, res: result(live, m) })).filter(({ m, res }) => heavy(res) &&
      // never merge a block straight back with its own other half (on the way home, only if it was the last to move)
      !(m.kind === "absorb" && m.g.length === 1 && m.a.sib && m.a.sib === m.g[0]!.sib && (S.phase !== "home" || m.a === S.last || m.g[0] === S.last)));
  };
  const centre = (m: Move<Block>) => {
    const cs = m.kind === "split" ? [m.b.c] : [m.a.c, ...m.g.map(c => c.c)];
    let x = 0, y = 0;
    cs.forEach(c => { x += c[0] + c[2]; y += c[1] + c[3]; });
    return Math.atan2(y / (2 * cs.length) - Q / 2, x / (2 * cs.length) - Q / 2);
  };
  const turn = (m: Move<Block>) => { let d = centre(m) - S.angle; while (d <= .3) d += 2 * Math.PI; return d; };
  function apply(m: Move<Block>, t: number, len: number): Block {
    if (m.kind === "slide") {
      const { a, g: [b], na, nb } = m;
      a.from = at(a, t); a.to = drawn(na); a.t0 = t; a.len = len; a.c = na; a.sib = 0;
      b.from = at(b, t); b.to = drawn(nb); b.t0 = t; b.len = len; b.c = nb; b.sib = 0;
      a.kind = "slide"; return a;
    }
    if (m.kind === "split") {
      const { b, ax } = m, mid = (b.c[ax] + b.c[ax + 2]!) / 2, far = Math.random() < .5;
      const now0 = at(b, t), keep = [...b.c] as Q4, nc = [...b.c] as Q4;
      if (far) { keep[ax + 2] = mid; nc[ax] = mid; } else { keep[ax] = mid; nc[ax + 2] = mid; }
      const nb = block(nc);
      nb.prevSib = b.sib; nb.sib = b.sib = ++S.pair;
      // it starts flat against that side, one gap outside it, so its inner edge and the shrinking edge keep one gap apart
      nb.from = drawn(nc);
      if (far) { nb.from[ax + 2] = now0[ax + 2]!; nb.from[ax] = now0[ax + 2]! + U; } else { nb.from[ax] = now0[ax]!; nb.from[ax + 2] = now0[ax]! - U; }
      nb.t0 = t; nb.len = len; b.c = keep; b.from = now0; b.to = drawn(keep); b.t0 = t; b.len = len;
      S.blocks.push(nb); nb.kind = "split"; return nb;
    }
    const { a, g, u, ax, dir } = m, end = drawn(u), farEdge = dir > 0 ? end[ax + 2]! : end[ax]!;
    a.from = at(a, t); a.to = end; a.t0 = t; a.len = len; a.c = u; a.sib = 0;
    g.forEach(c => {
      c.from = at(c, t); c.to = [...c.from] as Q4;
      if (dir > 0) { c.to[ax + 2] = farEdge; c.to[ax] = farEdge + U; } else { c.to[ax] = farEdge; c.to[ax + 2] = farEdge - U; }
      c.t0 = t; c.len = len; c.gone = true;
    });
    a.kind = "absorb"; return a;
  }
  function step() {
    const t = performance.now(), live = S.blocks.filter(b => !b.gone);
    if (live.some(b => busy(b, t))) { later(step, 90); return; }
    // home: hold the resting pose for a moment, then breathe out again
    if (key(live.map(b => b.c)) === REST_KEY && S.phase !== "split") {
      const hold = S.phase === "rest" ? FIRST_HOLD_MS : HOLD_MS;
      S.phase = "split"; S.goal = noMini ? 5 + Math.floor(Math.random() * 2) : 7 + Math.floor(Math.random() * 2); S.last = null;
      later(step, hold); return;
    }
    if (S.phase === "split" && live.length >= S.goal) S.phase = "home";
    let ms = moves(t), pool = ms;
    if (S.phase === "split") {
      // out: splits round the box clockwise, now and then a slide; minis are rare (G 00:42)
      const fresh = ms.filter(({ m }) => (m.kind === "split" ? m.b : m.a) !== S.last);
      if (fresh.length) ms = fresh;
      const want = ms.some(({ m }) => m.kind === "slide") && Math.random() < .3 ? "slide" : "split";
      pool = ms.filter(({ m }) => m.kind === want);
      if (!pool.length) pool = ms;
      const big = pool.filter(({ m }) => m.kind !== "split" || area(m.b.c) > 2);
      if (big.length && Math.random() < .8) pool = big;
    } else {
      // home: the shortest way back to the resting pose
      const d = ms.map(({ res }) => dist(res, noMini)), best = Math.min(...d);
      pool = ms.filter((_, i) => d[i] === best);
      const fresh = pool.filter(({ m }) => (m.kind === "split" ? m.b : m.a) !== S.last);
      if (fresh.length) pool = fresh;
    }
    if (!pool.length) { later(step, 90); return; }
    pool.sort((p, q) => turn(p.m) - turn(q.m));
    // a square of squares, large marks only: after half a square splits into minis, its other half follows
    const twin = !noMini && S.phase === "split" && S.last?.kind === "split" && area(S.last.c) === 1 &&
      pool.find(({ m }) => m.kind === "split" && area(m.b.c) === 2 && m.b.sib && m.b.sib === S.last?.prevSib);
    const m = (twin || pool[0]!).m;
    S.angle = centre(m);
    S.last = apply(m, t, MAIN_MS);
    // little side moves, large marks only and not often: a square splits or two quarters join while the main move runs
    if (side && S.phase === "split" && Math.random() < .3) later(() => {
      const t2 = performance.now(), n = S.blocks.filter(b => !b.gone).length;
      const ok = moves(t2).filter(({ m: o }) => o.kind === "split" ? area(o.b.c) === 4 && n < S.goal : o.kind === "absorb" && area(o.u) <= 4 && n > 3);
      const pick = ok[Math.floor(Math.random() * ok.length)];
      if (pick) apply(pick.m, t2, SIDE_MS);
    }, 160 + Math.random() * 160);
    later(step, MAIN_MS + BEAT_MS);
  }
  return {
    blocks: () => S.blocks,
    start: () => later(step, 300),
    stop: () => { S.timers.forEach(clearTimeout); S.timers = []; },
    tidyUp: (t: number) => { S.blocks = S.blocks.filter(b => !(b.gone && !busy(b, t))); },
  };
}

export function BoxMark({ className, size = 32, label = "obento", still }: { className?: string; size?: number; label?: string; still?: boolean }) {
  const group = useRef<SVGGElement>(null);

  useEffect(() => {
    const g = group.current;
    if (!g || still || motionOff()) return;
    const sim = makeSim(size <= 60, size > 60);
    let raf = 0;
    const draw = () => {
      const t = performance.now();
      sim.tidyUp(t);
      const rs = sim.blocks().map(b => at(b, t));
      while (g.childElementCount < rs.length) {
        const r = document.createElementNS("http://www.w3.org/2000/svg", "rect");
        r.setAttribute("rx", String(R)); g.appendChild(r);
      }
      [...g.children].forEach((el, j) => {
        const r = rs[j];
        if (!r || r[2] - r[0] <= 0 || r[3] - r[1] <= 0) { el.setAttribute("display", "none"); return; }
        el.removeAttribute("display");
        el.setAttribute("x", String(r[0])); el.setAttribute("y", String(r[1]));
        el.setAttribute("width", String(r[2] - r[0])); el.setAttribute("height", String(r[3] - r[1]));
      });
      raf = requestAnimationFrame(draw);
    };
    sim.start();
    raf = requestAnimationFrame(draw);
    return () => { sim.stop(); cancelAnimationFrame(raf); };
  }, [size, still]);

  return (
    <svg className={`boxmark${className ? ` ${className}` : ""}`} viewBox={`0 0 ${V} ${V}`} width={size} height={size} role={label ? "img" : undefined} aria-label={label || undefined} aria-hidden={label ? undefined : true}>
      <rect className="bx-plate" width={V} height={V} rx={R + U} />
      <g ref={group} className="bx-blocks">
        {REST.map((c, j) => { const [x0, y0, x1, y1] = drawn(c); return <rect key={j} x={x0} y={y0} width={x1 - x0} height={y1 - y0} rx={R} />; })}
      </g>
    </svg>
  );
}
