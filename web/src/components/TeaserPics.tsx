import { useEffect, useState, type ReactNode } from "react";
import { reduceMotion } from "../app/transition";

/**
 * Bento²'s landing pictures: five real diagrams, each worked from true numbers (G, 2026-10-06: not quick-glance icons).
 * Each rests on its finished picture and plays once from the start when `play` is set.
 */
export type TeaserId = "linear" | "orbit" | "quantum" | "ai" | "prob" | "hills" | "info" | "comp" | "change" | "relativity";

/** how long each picture takes to play, so the teaser can hand the turn on when it ends */
export const TEASER_MS: Record<TeaserId, number> = { linear: 3600, orbit: 4800, quantum: 4800, ai: 4400, prob: 5200, hills: 5000, info: 4600, comp: 5200, change: 4400, relativity: 4000 };

function useClock(ms: number, play: boolean) {
  const [t, setT] = useState(1);
  useEffect(() => {
    if (!play || reduceMotion()) return;
    let raf = 0;
    const t0 = performance.now();
    const tick = (now: number) => {
      const k = Math.min(1, (now - t0) / ms);
      setT(k);
      if (k < 1) raf = requestAnimationFrame(tick);
    };
    setT(0);
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [ms, play]);
  return t;
}

const ease = (x: number) => (x < 0.5 ? 4 * x * x * x : 1 - (-2 * x + 2) ** 3 / 2);
const clamp = (x: number) => Math.max(0, Math.min(1, x));
/** where `t` sits inside the window [a, b], as 0..1 */
const span = (t: number, a: number, b: number) => clamp((t - a) / (b - a));
function rng(seed: number) {
  return () => { seed |= 0; seed = (seed + 0x6d2b79f5) | 0; let r = Math.imul(seed ^ (seed >>> 15), 1 | seed); r = (r + Math.imul(r ^ (r >>> 7), 61 | r)) ^ r; return ((r ^ (r >>> 14)) >>> 0) / 4294967296; };
}
const pts = (p: [number, number][]) => p.map(([x, y], i) => `${i ? "L" : "M"}${x.toFixed(1)},${y.toFixed(1)}`).join(" ");

function Svg({ children, label }: { children: ReactNode; label: string }) {
  return <svg className="tp" viewBox="0 0 400 240" role="img" aria-label={label}>{children}</svg>;
}

/** Arrow from (x1,y1) to (x2,y2) with a filled head. */
function Arrow({ x1, y1, x2, y2, c, w = 2.5 }: { x1: number; y1: number; x2: number; y2: number; c: string; w?: number }) {
  const a = Math.atan2(y2 - y1, x2 - x1), h = 9;
  const hx = x2 - h * Math.cos(a), hy = y2 - h * Math.sin(a);
  return (
    <g>
      <line x1={x1} y1={y1} x2={hx} y2={hy} stroke={c} strokeWidth={w} strokeLinecap="round" />
      <path d={`M${x2},${y2} L${hx - 4.5 * Math.sin(a)},${hy + 4.5 * Math.cos(a)} L${hx + 4.5 * Math.sin(a)},${hy - 4.5 * Math.cos(a)} Z`} fill={c} />
    </g>
  );
}

/* ---------------- Linear algebra: A = [1.5 .5; .5 1.5] moving the plane ---------------- */
function Linear({ play }: { play: boolean }) {
  const t = ease(useClock(TEASER_MS.linear, play));
  const cx = 230, cy = 140, s = 36;
  const M = [[1 + 0.5 * t, 0.5 * t], [0.5 * t, 1 + 0.5 * t]];
  const P = (x: number, y: number): [number, number] => [cx + s * (M[0]![0]! * x + M[0]![1]! * y), cy - s * (M[1]![0]! * x + M[1]![1]! * y)];
  const det = M[0]![0]! * M[1]![1]! - M[0]![1]! * M[1]![0]!;
  const grid: string[] = [];
  for (let i = -8; i <= 8; i++) { grid.push(pts([P(i, -8), P(i, 8)])); grid.push(pts([P(-8, i), P(8, i)])); }
  const sq = [P(0, 0), P(1, 0), P(1, 1), P(0, 1)];
  const [ix, iy] = P(1, 0), [jx, jy] = P(0, 1), [vx, vy] = P(1, 1), [wx, wy] = P(1, -1);
  const f = (n: number) => (Math.round(n * 100) / 100).toString();
  return (
    <Svg label="A matrix stretching the grid. The unit square's area becomes the determinant, 2, and the arrow along y = x stays on its line and doubles.">
      <defs><clipPath id="tpl"><rect x="0" y="0" width="400" height="240" /></clipPath></defs>
      <g clipPath="url(#tpl)">
        {[...Array(17)].map((_, i) => <g key={i}><line x1={cx + (i - 8) * s} y1="0" x2={cx + (i - 8) * s} y2="240" className="tp-ghost" /><line x1="0" y1={cy + (i - 8) * s} x2="400" y2={cy + (i - 8) * s} className="tp-ghost" /></g>)}
        <path d={grid.join(" ")} className="tp-grid" />
        <line x1={cx - 160} y1={cy + 160} x2={cx + 160} y2={cy - 160} className="tp-eig" />
        <line x1={cx - 160} y1={cy - 160} x2={cx + 160} y2={cy + 160} className="tp-eig2" />
        <path d={pts(sq) + "Z"} className="tp-area" />
        <Arrow x1={cx} y1={cy} x2={wx} y2={wy} c="var(--tp-sky)" w={2} />
        <Arrow x1={cx} y1={cy} x2={ix} y2={iy} c="var(--tp-pink)" />
        <Arrow x1={cx} y1={cy} x2={jx} y2={jy} c="var(--tp-mint)" />
        <Arrow x1={cx} y1={cy} x2={vx} y2={vy} c="var(--tp-amber)" w={3} />
        <circle cx={cx} cy={cy} r="3" className="tp-ink-f" />
        <text x={ix + 6} y={iy + 14} className="tp-lbl" fill="var(--tp-pink)">î</text>
        <text x={jx - 14} y={jy - 4} className="tp-lbl" fill="var(--tp-mint)">ĵ</text>
        <text x={vx + 8} y={vy - 4} className="tp-lbl" fill="var(--tp-amber)">Av = {f(1 + t)}v</text>
        <text x={P(0.72, 0.22)[0]} y={P(0.72, 0.22)[1] + 4} textAnchor="middle" className="tp-sm" fill="var(--tp-amber)">area {f(det)}</text>
      </g>
      <g className="tp-panel">
        <rect x="10" y="10" width="118" height="100" rx="10" />
        <text x="20" y="34" className="tp-math">A =</text>
        <path d="M52 18 h-5 v52 h5 M118 18 h5 v52 h-5" className="tp-brk" />
        <text x="69" y="38" textAnchor="middle" className="tp-math">{f(M[0]![0]!)}</text><text x="101" y="38" textAnchor="middle" className="tp-math">{f(M[0]![1]!)}</text>
        <text x="69" y="62" textAnchor="middle" className="tp-math">{f(M[1]![0]!)}</text><text x="101" y="62" textAnchor="middle" className="tp-math">{f(M[1]![1]!)}</text>
        <text x="20" y="98" className="tp-sm">det A = {f(det)}</text>
      </g>
    </Svg>
  );
}

/* ---------------- Orbits: Kepler's laws with e = 0.6 ---------------- */
function Orbit({ play }: { play: boolean }) {
  const t = useClock(TEASER_MS.orbit, play);
  const a = 124, e = 0.6, b = a * Math.sqrt(1 - e * e), cx = 196, cy = 118, c = a * e;
  const fx = cx + c; // the sun sits at the right focus
  const at = (M: number) => { let E = M; for (let k = 0; k < 8; k++) E -= (E - e * Math.sin(E) - M) / (1 - e * Math.cos(E)); return E; };
  const pos = (E: number): [number, number] => [cx + a * Math.cos(E), cy - b * Math.sin(E)];
  const Mnow = 2 * Math.PI * t, E = at(Mnow), [px, py] = pos(E);
  const dE = 1 / (1 - e * Math.cos(E)), vx = -a * Math.sin(E) * dE, vy = -b * Math.cos(E) * dE;
  const wedge = (m0: number, m1: number) => { const p: [number, number][] = [[fx, cy]]; for (let k = 0; k <= 24; k++) p.push(pos(at(m0 + (m1 - m0) * (k / 24)))); return pts(p) + "Z"; };
  const w = 0.42;
  const trail: [number, number][] = []; for (let k = 0; k <= 60; k++) trail.push(pos(at(Mnow - 0.9 * (k / 60))));
  const shown = (m: number) => t >= 1 || Mnow > m;
  return (
    <Svg label="A planet on an ellipse around the sun. It speeds up near the sun, and the two shaded wedges, swept in equal times, have equal areas.">
      <ellipse cx={cx} cy={cy} rx={a} ry={b} className="tp-path" />
      <line x1={cx - a} y1={cy} x2={cx + a} y2={cy} className="tp-ghost" />
      {shown(w) && <path d={wedge(-w, w)} className="tp-wedge" />}
      {shown(Math.PI + w) && <path d={wedge(Math.PI - w, Math.PI + w)} className="tp-wedge" />}
      <circle cx={cx - c} cy={cy} r="2.5" className="tp-dim-f" />
      <circle cx={fx} cy={cy} r="11" className="tp-sun" /><circle cx={fx} cy={cy} r="6" fill="var(--tp-amber)" />
      <path d={pts(trail)} className="tp-trail" />
      <line x1={fx} y1={cy} x2={px} y2={py} className="tp-r" />
      <Arrow x1={px} y1={py} x2={px + vx * 0.22} y2={py + vy * 0.22} c="var(--tp-mint)" w={2} />
      <circle cx={px} cy={py} r="6" fill="var(--tp-sky)" />
      <text x="388" y={cy + 64} textAnchor="end" className="tp-sm">fast near the sun</text>
      <text x={cx - a + 6} y={cy + 48} className="tp-sm">slow far away</text>
      <text x="12" y="230" className="tp-math">r = a(1 − e²) / (1 + e cos θ)</text>
      <text x="388" y="230" textAnchor="end" className="tp-sm">e = 0.6</text>
      <text x="12" y="18" className="tp-sm">equal areas in equal times</text>
    </Svg>
  );
}

/* ---------------- Quantum: the double slit, one particle at a time ---------------- */
const SLIT_HITS = (() => {
  const r = rng(7), out: number[] = [];
  const P = (u: number) => Math.cos(7.2 * u) ** 2 * Math.exp(-((u / 0.62) ** 2));
  while (out.length < 520) { const u = r() * 2 - 1; if (r() < P(u)) out.push(u); }
  return out.map((u, i) => ({ u, j: rng(i + 99)() }));
})();
function Quantum({ play }: { play: boolean }) {
  const t = useClock(TEASER_MS.quantum, play);
  const cy = 124, H = 84, sx = 300, bx = 120;
  const n = Math.floor(SLIT_HITS.length * span(t, 0.05, 0.92));
  const P = (u: number) => Math.cos(7.2 * u) ** 2 * Math.exp(-((u / 0.62) ** 2));
  const curve: [number, number][] = []; for (let k = 0; k <= 160; k++) { const u = -1 + 2 * (k / 160); curve.push([322 + 62 * P(u), cy + u * H]); }
  const rings = [0, 1, 2, 3, 4, 5].map(k => ((t * 6 + k / 6 * 1) % 1) * 190);
  return (
    <Svg label="Particles go through two slits one at a time. Each lands as a single dot, but together the dots build up stripes that match |ψ₁ + ψ₂|².">
      <defs><clipPath id="tpq"><rect x={bx} y="0" width={sx - bx} height="240" /></clipPath></defs>
      <circle cx="34" cy={cy} r="5" fill="var(--tp-sky)" />
      {[0, 1, 2].map(k => <path key={k} d={`M${48 + k * 22},${cy - 30 + k * -6} Q ${58 + k * 22},${cy} ${48 + k * 22},${cy + 30 + k * 6}`} className="tp-wave" />)}
      <path d={`M${bx},${cy - H - 6} V${cy - 24} M${bx},${cy - 12} V${cy + 12} M${bx},${cy + 24} V${cy + H + 6}`} className="tp-wall" />
      <g clipPath="url(#tpq)">
        {[cy - 18, cy + 18].map(y => rings.map((rad, k) => <circle key={`${y}${k}`} cx={bx} cy={y} r={rad} className="tp-ring" style={{ opacity: 0.45 * (1 - rad / 190) }} />))}
      </g>
      <line x1={sx} y1={cy - H - 6} x2={sx} y2={cy + H + 6} className="tp-screen" />
      {SLIT_HITS.slice(0, n).map((h, i) => <circle key={i} cx={sx + 3 + h.j * 12} cy={cy + h.u * H} r="1.5" className={i === n - 1 && t < 1 ? "tp-hit-new" : "tp-hit"} />)}
      <path d={pts(curve)} className="tp-curve" style={{ opacity: span(t, 0.55, 0.95) }} />
      <text x={bx} y="230" textAnchor="middle" className="tp-sm">two slits</text>
      <text x={sx + 8} y="230" textAnchor="middle" className="tp-sm">{n} hits</text>
      <text x="388" y="20" textAnchor="end" className="tp-math" style={{ opacity: span(t, 0.6, 1) }}>|ψ₁ + ψ₂|²</text>
      <text x="12" y="20" className="tp-sm">one particle at a time</text>
    </Svg>
  );
}

/* ---------------- The math behind AI: gradient descent on a loss surface ---------------- */
const GD = (() => {
  // L = 0.15u² + 1.6v² with u, v rotated 45°, stepped with η = 0.45 from (−2.2, −1.0)
  const out: [number, number][] = [];
  let x = -2.2, y = -1.0;
  for (let k = 0; k < 22; k++) {
    out.push([x, y]);
    const u = (x + y) / Math.SQRT2, v = (x - y) / Math.SQRT2, gu = 0.3 * u, gv = 3.2 * v;
    const gx = (gu + gv) / Math.SQRT2, gy = (gu - gv) / Math.SQRT2;
    x -= 0.45 * gx; y -= 0.45 * gy;
  }
  return out;
})();
const loss = ([x, y]: [number, number]) => { const u = (x + y) / Math.SQRT2, v = (x - y) / Math.SQRT2; return 0.15 * u * u + 1.6 * v * v; };
function AI({ play }: { play: boolean }) {
  const t = useClock(TEASER_MS.ai, play);
  const cx = 130, cy = 124, s = 32;
  const P = ([x, y]: [number, number]): [number, number] => [cx + s * x, cy - s * y];
  const levels = [0.05, 0.15, 0.3, 0.55, 0.9, 1.4, 2.1];
  const hue = ["#fbbf24", "#f59e0b", "#f472b6", "#e879f9", "#c084fc", "#a78bfa", "#818cf8"];
  const ell = (L: number) => { const p: [number, number][] = []; for (let k = 0; k <= 72; k++) { const f = (k / 72) * 2 * Math.PI, u = Math.sqrt(L / 0.15) * Math.cos(f), v = Math.sqrt(L / 1.6) * Math.sin(f); p.push(P([(u + v) / Math.SQRT2, (u - v) / Math.SQRT2])); } return pts(p) + "Z"; };
  const k = Math.min(GD.length - 1, Math.floor(span(t, 0.05, 0.9) * (GD.length - 1)));
  const path = GD.slice(0, k + 1).map(P), [px, py] = path[k]!;
  const [qx, qy] = P(GD[Math.min(k + 1, GD.length - 1)]!);
  const L0 = loss(GD[0]!), lx = 278, ly = 52, lw = 110, lh = 120;
  const chart = GD.slice(0, k + 1).map((g, i): [number, number] => [lx + (i / (GD.length - 1)) * lw, ly + lh - (loss(g) / L0) * lh]);
  return (
    <Svg label="A ball stepping downhill across a loss map by gradient descent, zigzagging into the valley, while the loss curve beside it falls toward zero.">
      {levels.map((L, i) => <path key={L} d={ell(L)} fill="none" stroke={hue[i]} strokeWidth="1.4" opacity={0.75} />)}
      <circle cx={cx} cy={cy} r="3" fill="var(--tp-amber)" />
      <path d={pts(path)} className="tp-gd" />
      {path.map(([x, y], i) => <circle key={i} cx={x} cy={y} r="2.4" className="tp-ink-f" opacity={0.5 + 0.5 * (i / path.length)} />)}
      {k < GD.length - 1 && <Arrow x1={px} y1={py} x2={px + (qx - px) * 1} y2={py + (qy - py) * 1} c="var(--tp-mint)" w={2} />}
      <circle cx={px} cy={py} r="6" fill="var(--tp-sky)" />
      <text x="12" y="22" className="tp-math">θ ← θ − η ∇L(θ)</text>
      <text x="388" y="230" textAnchor="end" className="tp-sm">step {k} · η = 0.45</text>
      <g>
        <line x1={lx} y1={ly} x2={lx} y2={ly + lh} className="tp-axis" /><line x1={lx} y1={ly + lh} x2={lx + lw} y2={ly + lh} className="tp-axis" />
        <path d={pts(chart)} className="tp-loss" />
        <circle cx={chart[k]![0]} cy={chart[k]![1]} r="3.5" fill="var(--tp-pink)" />
        <text x={lx} y={ly - 10} className="tp-sm">loss</text>
        <text x={lx + lw} y={ly + lh + 16} textAnchor="end" className="tp-sm">steps</text>
        <text x={lx + lw} y={ly - 10} textAnchor="end" className="tp-sm" fill="var(--tp-pink)">{loss(GD[k]!).toFixed(3)}</text>
      </g>
    </Svg>
  );
}

/* ---------------- Probability: a Galton board building the bell curve ---------------- */
const ROWS = 8, BALLS = 160;
const GALTON = (() => { const r = rng(21); return [...Array(BALLS)].map(() => [...Array(ROWS)].map(() => (r() < 0.5 ? 0 : 1))); })();
function Prob({ play }: { play: boolean }) {
  const t = useClock(TEASER_MS.prob, play);
  const cx = 130, top = 16, dy = 13, dx = 19, binTop = top + ROWS * dy + 10, unit = 2.0;
  const now = t * TEASER_MS.prob, gap = (TEASER_MS.prob * 0.72) / BALLS, fall = 820;
  const counts = Array(ROWS + 1).fill(0) as number[];
  const flying: [number, number][] = [];
  GALTON.forEach((steps, i) => {
    const age = t >= 1 ? fall : now - i * gap;
    if (age < 0) return;
    const bin = steps.reduce((a: number, b) => a + b, 0);
    if (age >= fall) { counts[bin]!++; return; }
    const f = (age / fall) * ROWS, row = Math.floor(f), fr = f - row;
    const off = steps.slice(0, row).reduce((a: number, b) => a + b, 0) - row / 2, next = off + (steps[row]! ? 0.5 : -0.5);
    flying.push([cx + dx * (off + (next - off) * fr), top + dy * (row + fr) - 4 * Math.sin(Math.PI * fr)]);
  });
  const n = counts.reduce((a: number, b) => a + b, 0);
  const mean = n ? counts.reduce((a, c, k) => a + c * k, 0) / n : 0;
  const binX = (k: number) => cx + dx * (k - ROWS / 2);
  const bell: [number, number][] = []; for (let k = 0; k <= 80; k++) { const x = -0.5 + (ROWS + 1) * (k / 80), g = BALLS * Math.exp(-((x - 4) ** 2) / 4) / Math.sqrt(4 * Math.PI); bell.push([binX(x), binTop + 92 - g * unit]); }
  return (
    <Svg label="Balls bounce left or right off eight rows of pegs and pile up in bins. The pile grows into the bell curve of B(8, ½).">
      {[...Array(ROWS)].map((_, r) => [...Array(r + 1)].map((__, j) => <circle key={`${r}-${j}`} cx={cx + dx * (j - r / 2)} cy={top + dy * r} r="2.2" className="tp-dim-f" />))}
      {counts.map((c, k) => <rect key={k} x={binX(k) - 7.5} y={binTop + 92 - c * unit} width="15" height={c * unit} rx="2" fill="var(--tp-sky)" opacity={0.85} />)}
      {[...Array(ROWS + 2)].map((_, k) => <line key={k} x1={binX(k - 0.5)} y1={binTop + 4} x2={binX(k - 0.5)} y2={binTop + 92} className="tp-ghost" />)}
      <line x1={binX(-0.5)} y1={binTop + 92} x2={binX(ROWS + 0.5)} y2={binTop + 92} className="tp-axis" />
      <path d={pts(bell)} className="tp-curve" style={{ opacity: span(t, 0.5, 0.95) }} />
      {flying.map(([x, y], i) => <circle key={i} cx={x} cy={y} r="3.2" fill="var(--tp-amber)" />)}
      {counts.map((_, k) => <text key={k} x={binX(k)} y={binTop + 105} textAnchor="middle" className="tp-xs">{k}</text>)}
      <text x="262" y="40" className="tp-math">P(k) = C(8, k) / 2⁸</text>
      <text x="262" y="66" className="tp-sm">{n} balls</text>
      <text x="262" y="86" className="tp-sm">mean {n ? mean.toFixed(2) : "–"} · expected 4</text>
      <text x="262" y="106" className="tp-sm" fill="var(--tp-pink)" style={{ opacity: span(t, 0.5, 0.95) }}>bell curve: μ = 4, σ = √2</text>
    </Svg>
  );
}

/* ---------------- Hills: a surface z = f(x, y), turned so you can see it, and a walk down to its lowest point ---------------- */
const hf = (x: number, y: number) => 0.16 * (x * x + y * y) - 1.1 * Math.exp(-((x - 0.6) ** 2 + (y + 0.4) ** 2) / 0.7) + 0.8 * Math.exp(-((x + 1.1) ** 2 + (y - 0.9) ** 2) / 0.6);
const HILL_WALK = (() => {
  const out: [number, number][] = []; let x = -0.55, y = 1.6; const d = 1e-3;
  for (let k = 0; k < 70; k++) { out.push([x, y]); const gx = (hf(x + d, y) - hf(x - d, y)) / (2 * d), gy = (hf(x, y + d) - hf(x, y - d)) / (2 * d); x -= 0.14 * gx; y -= 0.14 * gy; }
  return out;
})();
function Hills({ play }: { play: boolean }) {
  const t = useClock(TEASER_MS.hills, play);
  const phi = -0.95 + 0.55 * ease(t), cx = 214, cy = 112, s = 40, h = 44;
  const P = (x: number, y: number): [number, number] => [cx + s * (x * Math.cos(phi) - y * Math.sin(phi)), cy + s * 0.42 * (x * Math.sin(phi) + y * Math.cos(phi)) - h * hf(x, y)];
  const N = 22, R = 2.4, lines: string[] = [];
  for (let i = 0; i <= N; i++) {
    const a = -R + (2 * R * i) / N, rowA: [number, number][] = [], rowB: [number, number][] = [];
    for (let j = 0; j <= 44; j++) { const b = -R + (2 * R * j) / 44; rowA.push(P(a, b)); rowB.push(P(b, a)); }
    lines.push(pts(rowA), pts(rowB));
  }
  const k = Math.min(HILL_WALK.length - 1, Math.floor(span(t, 0.15, 0.95) * (HILL_WALK.length - 1)));
  const walk = HILL_WALK.slice(0, k + 1).map(([x, y]) => P(x, y)), [bx, by] = walk[k]!;
  const done = k === HILL_WALK.length - 1;
  return (
    <Svg label="A landscape z = f(x, y) with a hill and a valley, turning slowly. A ball follows the steepest way down and stops at the lowest point, where the gradient is zero.">
      <path d={lines.join(" ")} className="tp-mesh" />
      <path d={pts(walk)} className="tp-walk" />
      <circle cx={bx} cy={by} r="6" fill="var(--tp-amber)" />
      <text x="12" y="210" className="tp-math">z = f(x, y)</text>
      <text x="12" y="230" className="tp-sm">downhill = −∇f</text>
      <text x="388" y="230" textAnchor="end" className="tp-sm" fill="var(--tp-amber)" style={{ opacity: done ? 1 : 0 }}>lowest point: ∇f = 0</text>
    </Svg>
  );
}

/* ---------------- Information: the entropy of a coin ---------------- */
function Info({ play }: { play: boolean }) {
  const t = useClock(TEASER_MS.info, play);
  const p = 0.5 - 0.46 * Math.cos(3 * Math.PI * t) * (1 - t) ** 0.8;
  const H = (q: number) => (q <= 0 || q >= 1 ? 0 : -q * Math.log2(q) - (1 - q) * Math.log2(1 - q));
  const x0 = 40, x1 = 240, y0 = 196, y1 = 60, X = (q: number) => x0 + (x1 - x0) * q, Y = (v: number) => y0 - (y0 - y1) * v;
  const curve: [number, number][] = []; for (let k = 0; k <= 100; k++) curve.push([X(k / 100), Y(H(k / 100))]);
  const hp = H(p), bw = 34, bh = 120, by = 196;
  return (
    <Svg label="The entropy curve of a coin, H(p). It is zero when the coin always lands one way and peaks at 1 bit for a fair coin, where each toss is most surprising.">
      <text x="12" y="22" className="tp-math">H(p) = −p log₂ p − (1 − p) log₂(1 − p)</text>
      <line x1={x0} y1={y0} x2={x1} y2={y0} className="tp-axis" /><line x1={x0} y1={y0} x2={x0} y2={y1 - 8} className="tp-axis" />
      <line x1={x0} y1={y1} x2={x1} y2={y1} className="tp-ghost" />
      <text x={x0 - 6} y={y1 + 4} textAnchor="end" className="tp-xs">1 bit</text>
      <text x={x0 - 6} y={y0 + 4} textAnchor="end" className="tp-xs">0</text>
      {[0, 0.5, 1].map(q => <text key={q} x={X(q)} y={y0 + 16} textAnchor="middle" className="tp-xs">{q === 0.5 ? "½" : q}</text>)}
      <text x={x1} y={y0 + 30} textAnchor="end" className="tp-xs">p = chance of heads</text>
      <path d={pts(curve)} className="tp-curve" />
      <line x1={X(p)} y1={y0} x2={X(p)} y2={Y(hp)} className="tp-r" />
      <circle cx={X(p)} cy={Y(hp)} r="6" fill="var(--tp-sky)" />
      <rect x="282" y={by - bh * p} width={bw} height={bh * p} rx="4" fill="var(--tp-sky)" />
      <rect x="330" y={by - bh * (1 - p)} width={bw} height={bh * (1 - p)} rx="4" fill="var(--tp-lilac)" />
      <line x1="276" y1={by} x2="370" y2={by} className="tp-axis" />
      <text x="299" y={by + 16} textAnchor="middle" className="tp-xs">heads</text><text x="347" y={by + 16} textAnchor="middle" className="tp-xs">tails</text>
      <text x="326" y="58" textAnchor="middle" className="tp-math">{hp.toFixed(2)} bits</text>
      <text x="326" y="76" textAnchor="middle" className="tp-sm">p = {p.toFixed(2)}</text>
    </Svg>
  );
}

/* ---------------- Computation: merge sort, every write shown ---------------- */
const SORT = (() => {
  const r = rng(5), a = [...Array(16)].map((_, i) => i + 1);
  for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [a[i], a[j]] = [a[j]!, a[i]!]; }
  const frames: { a: number[]; at: number; lo: number; hi: number; cmp: number }[] = [{ a: [...a], at: -1, lo: 0, hi: -1, cmp: 0 }];
  let cmp = 0;
  for (let w = 1; w < a.length; w *= 2) for (let lo = 0; lo < a.length; lo += 2 * w) {
    const mid = Math.min(lo + w, a.length), hi = Math.min(lo + 2 * w, a.length), L = a.slice(lo, mid), R = a.slice(mid, hi);
    let i = 0, j = 0;
    for (let k = lo; k < hi; k++) {
      if (i < L.length && j < R.length) cmp++;
      a[k] = j >= R.length || (i < L.length && L[i]! <= R[j]!) ? L[i++]! : R[j++]!;
      frames.push({ a: [...a], at: k, lo, hi: hi - 1, cmp });
    }
  }
  return frames;
})();
function Comp({ play }: { play: boolean }) {
  const t = useClock(TEASER_MS.comp, play);
  const f = SORT[Math.min(SORT.length - 1, Math.floor(span(t, 0.04, 0.96) * (SORT.length - 1)))]!;
  const done = f === SORT[SORT.length - 1], x0 = 40, bw = 18, gap = 2.5, base = 200, unit = 9;
  return (
    <Svg label="Merge sort putting 16 bars in order: it sorts pairs, then fours, then eights, merging as it goes, using about n log₂ n comparisons.">
      <text x="12" y="22" className="tp-math">merge sort</text>
      <text x="388" y="22" textAnchor="end" className="tp-sm">{f.cmp} comparisons · n log₂ n = 64</text>
      {f.hi >= 0 && !done && <rect x={x0 + f.lo * (bw + gap) - 3} y={base - 16 * unit - 8} width={(f.hi - f.lo + 1) * (bw + gap) + 3} height={16 * unit + 12} rx="6" className="tp-band" />}
      {f.a.map((v, i) => <rect key={i} x={x0 + i * (bw + gap)} y={base - v * unit} width={bw} height={v * unit} rx="3"
        fill={i === f.at && !done ? "var(--tp-amber)" : done || (i >= f.lo && i <= f.hi) ? "var(--tp-sky)" : "var(--tp-lilac)"} opacity={done || (i >= f.lo && i <= f.hi) || i === f.at ? 1 : 0.55} />)}
      <line x1={x0 - 6} y1={base} x2={x0 + 16 * (bw + gap)} y2={base} className="tp-axis" />
      <text x="12" y="230" className="tp-sm">{done ? "sorted" : `merging ${f.hi - f.lo + 1} at a time`}</text>
    </Svg>
  );
}

/* ---------------- Change over time: the logistic equation and its slope field ---------------- */
function Change({ play }: { play: boolean }) {
  const t = useClock(TEASER_MS.change, play);
  const r = 0.9, K = 10, x0 = 44, x1 = 384, y0 = 206, y1 = 40, T = 10, Ymax = 13;
  const X = (tt: number) => x0 + (x1 - x0) * (tt / T), Y = (y: number) => y0 - (y0 - y1) * (y / Ymax);
  const sol = (y0v: number, tt: number) => K / (1 + ((K - y0v) / y0v) * Math.exp(-r * tt));
  const field: string[] = [];
  for (let i = 0; i <= 16; i++) for (let j = 0; j <= 9; j++) {
    const tt = (i / 16) * T, y = 0.4 + (j / 9) * (Ymax - 0.8), dy = r * y * (1 - y / K);
    const dx = 1, ux = (x1 - x0) / T, uy = (y0 - y1) / Ymax, vx = dx * ux, vy = -dy * uy, n = Math.hypot(vx, vy), L = 7;
    const [px, py] = [X(tt), Y(y)];
    field.push(`M${(px - (vx / n) * L).toFixed(1)},${(py - (vy / n) * L).toFixed(1)} L${(px + (vx / n) * L).toFixed(1)},${(py + (vy / n) * L).toFixed(1)}`);
  }
  const now = T * span(t, 0.05, 0.95), starts = [0.3, 1.5, 4, 12.5];
  const hues = ["var(--tp-sky)", "var(--tp-mint)", "var(--tp-pink)", "var(--tp-amber)"];
  return (
    <Svg label="A slope field for the logistic equation. Curves from different starting sizes all follow the little arrows and level off at the carrying capacity K = 10.">
      <path d={field.join(" ")} className="tp-field" />
      <line x1={x0} y1={Y(K)} x2={x1} y2={Y(K)} className="tp-eig" />
      <text x={x1} y={Y(K) - 6} textAnchor="end" className="tp-xs">K = 10</text>
      <line x1={x0} y1={y0} x2={x1} y2={y0} className="tp-axis" /><line x1={x0} y1={y0} x2={x0} y2={y1} className="tp-axis" />
      {starts.map((s0, i) => {
        const c: [number, number][] = []; for (let k = 0; k <= 80; k++) { const tt = (k / 80) * now; c.push([X(tt), Y(sol(s0, tt))]); }
        const [ex, ey] = c[c.length - 1]!;
        return <g key={s0}><path d={pts(c)} fill="none" stroke={hues[i]} strokeWidth="2.4" /><circle cx={ex} cy={ey} r="4" fill={hues[i]} /></g>;
      })}
      <text x="12" y="24" className="tp-math">dy/dt = r·y(1 − y/K)</text>
      <text x={x1} y="230" textAnchor="end" className="tp-xs">time</text>
    </Svg>
  );
}

/* ---------------- Relativity: a spacetime diagram as speed rises to 0.6c ---------------- */
function Relativity({ play }: { play: boolean }) {
  const t = useClock(TEASER_MS.relativity, play);
  const v = 0.6 * ease(span(t, 0.05, 0.9)), g = 1 / Math.sqrt(1 - v * v), cx = 200, cy = 196, s = 52;
  const P = (x: number, ct: number): [number, number] => [cx + s * x, cy - s * ct];
  const hyp = (k: number) => { const a: [number, number][] = []; for (let x = -3.6; x <= 3.6; x += 0.1) a.push(P(x, Math.sqrt(k * k + x * x))); return pts(a); };
  const [tx, ty] = P(v * 3.4, 3.4), [xx, xy] = P(4.4, v * 4.4);
  return (
    <Svg label="A spacetime diagram. As speed rises to 0.6 times light speed, the moving clock's time and space axes tilt toward the light line, and its ticks slide along the curves where ct² − x² stays the same.">
      <defs><clipPath id="tpr"><rect x="0" y="0" width="400" height={cy + 1} /></clipPath></defs>
      <g clipPath="url(#tpr)">
        {[1, 2, 3].map(k => <path key={k} d={hyp(k)} className="tp-hyp" />)}
        <line x1={cx - 4 * s} y1={cy - 4 * s} x2={cx} y2={cy} className="tp-light" /><line x1={cx} y1={cy} x2={cx + 4 * s} y2={cy - 4 * s} className="tp-light" />
        <line x1={cx} y1={cy} x2={cx} y2={10} className="tp-axis" />
        <line x1={cx} y1={cy} x2={tx} y2={ty} stroke="var(--tp-sky)" strokeWidth="2.4" />
        <line x1={cx} y1={cy} x2={xx} y2={xy} stroke="var(--tp-pink)" strokeWidth="2.4" />
        {[1, 2, 3].map(k => { const [a, b] = P(g * v * k, g * k); const [c, d] = P(g * k, g * v * k); return <g key={k}><circle cx={a} cy={b} r="4" fill="var(--tp-sky)" /><circle cx={c} cy={d} r="4" fill="var(--tp-pink)" /></g>; })}
      </g>
      <line x1="20" y1={cy} x2="380" y2={cy} className="tp-axis" />
      <text x={cx + 6} y="20" className="tp-sm">ct</text><text x="384" y={cy - 6} textAnchor="end" className="tp-sm">x</text>
      <text x={tx + 6} y={ty + 14} className="tp-lbl" fill="var(--tp-sky)">ct′</text>
      <text x={P(3.1, v * 3.1)[0]} y={P(3.1, v * 3.1)[1] + 22} textAnchor="middle" className="tp-lbl" fill="var(--tp-pink)">x′</text>
      <text x="24" y="150" className="tp-math">v = {v.toFixed(2)}c</text>
      <text x="24" y="172" className="tp-sm">γ = {g.toFixed(2)}</text>
      <text x="12" y="230" className="tp-sm">light: 45° for everyone</text>
      <text x="388" y="230" textAnchor="end" className="tp-sm">ct² − x² stays the same</text>
    </Svg>
  );
}

export function TeaserPic({ id, play }: { id: TeaserId; play: boolean }) {
  switch (id) {
    case "linear": return <Linear play={play} />;
    case "orbit": return <Orbit play={play} />;
    case "quantum": return <Quantum play={play} />;
    case "ai": return <AI play={play} />;
    case "hills": return <Hills play={play} />;
    case "info": return <Info play={play} />;
    case "comp": return <Comp play={play} />;
    case "change": return <Change play={play} />;
    case "relativity": return <Relativity play={play} />;
    default: return <Prob play={play} />;
  }
}
