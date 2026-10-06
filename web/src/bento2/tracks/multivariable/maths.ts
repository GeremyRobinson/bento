// Multivariable's own maths: the landscapes, their slopes and curvatures, contour lines, descent runs, basins and
// lakes, and the term printer every generator writes formulas with (it drops 1s and 0s and never prints "+ −").
import { formatAnswer } from "../../steps";
import { parse, evaluate } from "../../tools/expr";

export type F2 = (x: number, y: number) => number;
export type Box = [number, number, number, number]; // x0, x1, y0, y1

/* ------------------------------------------------------------ the default landscape ------------------------------------------------------------ */

/** "Two lakes": (x² − 1)² + y² + x/4. Lowest at about (−1.03, 0), a higher bottom at (0.97, 0), a pass at (0.06, 0). */
export const LAND: F2 = (x, y) => (x * x - 1) ** 2 + y * y + x / 4;
export const LAND_SRC = "(x^2 - 1)^2 + y^2 + x/4";
export const LAND_BOX: Box = [-2, 2, -1, 1];

/** Reads a typed landscape, f(x, y) = …; null when it can't be read or has no value at the origin's neighbours. */
export function compile(src: string): F2 | null {
  try {
    const tree = parse(src);
    const f: F2 = (x, y) => evaluate(tree, { vars: { x, y } });
    for (const [x, y] of [[0.1, 0.2], [-1, 0.5], [1.3, -0.7]] as const) if (!Number.isFinite(f(x, y))) return null;
    return f;
  } catch { return null; }
}

/* ------------------------------------------------------------ calculus by numbers ------------------------------------------------------------ */

const H = 1e-5;
export const grad = (f: F2, x: number, y: number, h = H): [number, number] =>
  [(f(x + h, y) - f(x - h, y)) / (2 * h), (f(x, y + h) - f(x, y - h)) / (2 * h)];
export function hess(f: F2, x: number, y: number, h = 1e-4): [number, number, number] {
  const fxx = (f(x + h, y) - 2 * f(x, y) + f(x - h, y)) / (h * h);
  const fyy = (f(x, y + h) - 2 * f(x, y) + f(x, y - h)) / (h * h);
  const fxy = (f(x + h, y + h) - f(x + h, y - h) - f(x - h, y + h) + f(x - h, y - h)) / (4 * h * h);
  return [fxx, fyy, fxy];
}
/** eigenvalues of [[a, b], [b, c]] */
export const eig2 = (a: number, b: number, c: number): [number, number] => {
  const m = (a + c) / 2, r = Math.hypot((a - c) / 2, b);
  return [m - r, m + r];
};
export type Kind = "pit" | "peak" | "pass" | "flat";
export function kindAt(f: F2, x: number, y: number): Kind {
  const [a, c, b] = hess(f, x, y);
  const [l1, l2] = eig2(a, b, c), tol = 1e-3;
  if (Math.abs(l1) < tol || Math.abs(l2) < tol) return "flat";
  if (l1 > 0) return "pit";
  if (l2 < 0) return "peak";
  return "pass";
}
export const KIND_WORD: Record<Kind, string> = { pit: "pit", peak: "peak", pass: "pass", flat: "can't tell" };

/** Flat spots in a box: Newton's method on ∇f = 0 from a grid of seeds, kept when they land inside, deduplicated. */
export function flatSpots(f: F2, box: Box, seeds = 9): { x: number; y: number; z: number; kind: Kind }[] {
  const out: { x: number; y: number; z: number; kind: Kind }[] = [];
  const [x0, x1, y0, y1] = box;
  for (let i = 0; i <= seeds; i++) for (let j = 0; j <= seeds; j++) {
    let x = x0 + ((x1 - x0) * i) / seeds, y = y0 + ((y1 - y0) * j) / seeds;
    for (let k = 0; k < 40; k++) {
      const [gx, gy] = grad(f, x, y), [a, c, b] = hess(f, x, y), det = a * c - b * b;
      if (Math.abs(det) < 1e-9) break;
      const dx = (c * gx - b * gy) / det, dy = (a * gy - b * gx) / det;
      x -= dx; y -= dy;
      if (!Number.isFinite(x) || Math.abs(x) > 1e3) break;
      if (Math.hypot(dx, dy) < 1e-10) break;
    }
    if (!Number.isFinite(x) || x < x0 || x > x1 || y < y0 || y > y1) continue;
    if (Math.hypot(...grad(f, x, y)) > 1e-6) continue;
    if (out.some(p => Math.hypot(p.x - x, p.y - y) < 1e-3)) continue;
    out.push({ x, y, z: f(x, y), kind: kindAt(f, x, y) });
  }
  return out.sort((a, b) => a.x - b.x || a.y - b.y);
}

/** Gradient descent: the points visited. Momentum keeps a share of the last step; Newton uses the Hessian. */
export function descend(f: F2, x: number, y: number, eta: number, steps: number, opt: { momentum?: number; newton?: boolean; clamp?: Box } = {}): [number, number][] {
  const pts: [number, number][] = [[x, y]];
  let vx = 0, vy = 0;
  for (let k = 0; k < steps; k++) {
    let [gx, gy] = grad(f, x, y);
    if (opt.newton) {
      const [a, c, b] = hess(f, x, y), det = a * c - b * b;
      if (Math.abs(det) > 1e-9) [gx, gy] = [(c * gx - b * gy) / det, (a * gy - b * gx) / det];
      x -= gx; y -= gy;
    } else {
      const m = opt.momentum ?? 0;
      vx = m * vx - eta * gx; vy = m * vy - eta * gy;
      x += vx; y += vy;
    }
    if (opt.clamp) { x = Math.max(opt.clamp[0], Math.min(opt.clamp[1], x)); y = Math.max(opt.clamp[2], Math.min(opt.clamp[3], y)); }
    pts.push([x, y]);
    if (!Number.isFinite(x) || !Number.isFinite(y) || Math.abs(x) > 1e6 || Math.abs(y) > 1e6) break;
  }
  return pts;
}

/* ------------------------------------------------------------ contours ------------------------------------------------------------ */

export interface Grid { box: Box; nx: number; ny: number; v: Float64Array }
export function sample(f: F2, box: Box, nx: number, ny = nx): Grid {
  const v = new Float64Array((nx + 1) * (ny + 1));
  const [x0, x1, y0, y1] = box;
  for (let j = 0; j <= ny; j++) for (let i = 0; i <= nx; i++) v[j * (nx + 1) + i] = f(x0 + ((x1 - x0) * i) / nx, y0 + ((y1 - y0) * j) / ny);
  return { box, nx, ny, v };
}
/** Marching squares: the contour f = level as segments [x1, y1, x2, y2] in the landscape's own coordinates. */
export function contour(g: Grid, level: number): [number, number, number, number][] {
  const { box: [x0, x1, y0, y1], nx, ny, v } = g;
  const dx = (x1 - x0) / nx, dy = (y1 - y0) / ny, out: [number, number, number, number][] = [];
  const at = (i: number, j: number) => v[j * (nx + 1) + i]!;
  for (let j = 0; j < ny; j++) for (let i = 0; i < nx; i++) {
    const a = at(i, j) - level, b = at(i + 1, j) - level, c = at(i + 1, j + 1) - level, d = at(i, j + 1) - level;
    if (![a, b, c, d].every(Number.isFinite)) continue;
    const X = x0 + i * dx, Y = y0 + j * dy, pts: [number, number][] = [];
    const cut = (p: number, q: number) => p / (p - q);
    if ((a < 0) !== (b < 0)) pts.push([X + cut(a, b) * dx, Y]);
    if ((b < 0) !== (c < 0)) pts.push([X + dx, Y + cut(b, c) * dy]);
    if ((d < 0) !== (c < 0)) pts.push([X + cut(d, c) * dx, Y + dy]);
    if ((a < 0) !== (d < 0)) pts.push([X, Y + cut(a, d) * dy]);
    if (pts.length === 2) out.push([pts[0]![0], pts[0]![1], pts[1]![0], pts[1]![1]]);
    else if (pts.length === 4) { out.push([pts[0]![0], pts[0]![1], pts[1]![0], pts[1]![1]]); out.push([pts[2]![0], pts[2]![1], pts[3]![0], pts[3]![1]]); }
  }
  return out;
}
/** evenly spaced heights between the grid's low and high, n of them */
export function levelsOf(g: Grid, n: number): number[] {
  let lo = Infinity, hi = -Infinity;
  for (const z of g.v) if (Number.isFinite(z)) { lo = Math.min(lo, z); hi = Math.max(hi, z); }
  return Array.from({ length: n }, (_, i) => lo + ((hi - lo) * (i + 0.5)) / n);
}

/* ------------------------------------------------------------ basins and lakes ------------------------------------------------------------ */

/** Which bottom each grid node drains to, by steepest descent from node to node. Bottoms are the grid's local lows. */
export function basins(g: Grid): { label: Int32Array; bottoms: number[] } {
  const { nx, ny, v } = g, W = nx + 1, n = W * (ny + 1);
  const next = new Int32Array(n);
  for (let j = 0; j <= ny; j++) for (let i = 0; i <= nx; i++) {
    const k = j * W + i;
    let best = k;
    for (let dj = -1; dj <= 1; dj++) for (let di = -1; di <= 1; di++) {
      const ii = i + di, jj = j + dj;
      if (ii < 0 || jj < 0 || ii > nx || jj > ny) continue;
      const kk = jj * W + ii;
      if (v[kk]! < v[best]!) best = kk;
    }
    next[k] = best;
  }
  const label = new Int32Array(n).fill(-1), bottoms: number[] = [];
  for (let k = 0; k < n; k++) {
    let p = k;
    while (next[p] !== p) p = next[p]!;
    let b = bottoms.indexOf(p);
    if (b < 0) { b = bottoms.length; bottoms.push(p); }
    label[k] = b;
  }
  return { label, bottoms };
}

/** The lake that collects around (x, y) up to height `level`: grid cells joined to the spot that are under water. */
export function lake(f: F2, box: Box, x: number, y: number, level: number, nx = 160, ny = 80): { volume: number; area: number; wet: Uint8Array; nx: number; ny: number } {
  const [x0, x1, y0, y1] = box, dx = (x1 - x0) / nx, dy = (y1 - y0) / ny;
  const z = new Float64Array(nx * ny);
  for (let j = 0; j < ny; j++) for (let i = 0; i < nx; i++) z[j * nx + i] = f(x0 + (i + 0.5) * dx, y0 + (j + 0.5) * dy);
  const wet = new Uint8Array(nx * ny);
  const si = Math.max(0, Math.min(nx - 1, Math.floor((x - x0) / dx))), sj = Math.max(0, Math.min(ny - 1, Math.floor((y - y0) / dy)));
  let volume = 0, area = 0;
  if (z[sj * nx + si]! < level) {
    const stack = [sj * nx + si];
    wet[sj * nx + si] = 1;
    while (stack.length) {
      const k = stack.pop()!, i = k % nx, j = (k - i) / nx;
      volume += (level - z[k]!) * dx * dy; area += dx * dy;
      for (const [ii, jj] of [[i + 1, j], [i - 1, j], [i, j + 1], [i, j - 1]] as const) {
        if (ii < 0 || jj < 0 || ii >= nx || jj >= ny) continue;
        const kk = jj * nx + ii;
        if (!wet[kk] && z[kk]! < level) { wet[kk] = 1; stack.push(kk); }
      }
    }
  }
  return { volume, area, wet, nx, ny };
}

/** the small random numbers a picture uses for its balls (seeded, so a run can be repeated) */
export function seeded(seed: number) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/* ------------------------------------------------------------ the term printer ------------------------------------------------------------ */

const SUP = "⁰¹²³⁴⁵⁶⁷⁸⁹";
const sup = (n: number) => (n === 1 ? "" : String(n).replace(/\d/g, d => SUP[+d]!));
/** "x²y", "y", "" for a constant: powers of 0 vanish and a power of 1 is never written */
export const mono = (xe: number, ye: number, xs = "x", ys = "y") => `${xe ? xs + sup(xe) : ""}${ye ? ys + sup(ye) : ""}`;
/** a number as a coefficient: 1 and −1 vanish in front of a letter; fractions as "5/2" */
const num = (c: number) => formatAnswer(Math.abs(c), "fraction");
/**
 * A sum of terms, each [coefficient, monomial]. Zero terms are dropped, a coefficient of 1 is never printed, a
 * negative term reads "− 3x" (never "+ −"), and an all-zero sum is "0".
 */
export function terms(ts: [number, string][]): string {
  const live = ts.filter(([c]) => Math.abs(c) > 1e-12);
  if (!live.length) return "0";
  return live.map(([c, m], i) => {
    const body = m ? (Math.abs(c) === 1 ? m : `${num(c)}${m}`) : num(c);
    return i === 0 ? (c < 0 ? `−${body}` : body) : c < 0 ? ` − ${body}` : ` + ${body}`;
  }).join("");
}
/** a linear term over a denominator, as the spec writes it: 15x/2 (not 15/2 x) */
export function fracTerm(c: number, v: string): [number, string] {
  const [n, d] = toFrac(c);
  return d === 1 ? [c, v] : [Math.sign(n), `${Math.abs(n) === 1 ? "" : Math.abs(n)}${v}/${d}`];
}
function toFrac(x: number): [number, number] {
  for (let d = 1; d <= 1000; d++) { const n = Math.round(x * d); if (Math.abs(n / d - x) < 1e-9) return [n, d]; }
  return [x, 1];
}
/** "−3" with a real minus sign, for numbers inside text */
export const sn = (x: number) => formatAnswer(x, "fraction");
/** a point "(2, −1)" */
export const pt = (x: number, y: number) => `(${sn(x)}, ${sn(y)})`;
/** a vector "⟨6, 8⟩" */
export const vec = (x: number, y: number) => `⟨${sn(x)}, ${sn(y)}⟩`;
