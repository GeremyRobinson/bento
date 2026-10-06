// Linear algebra's own maths, in one place for the pictures, the lessons and the build: small vectors and matrices,
// the way the screen writes them ("2u − 3v", "(3, −1)", "[[2, −1], [1, 1]]"), and an SVD for the Image compressor.
import { formatAnswer } from "../../steps";
import type { Mat } from "../../tools/matrix";

export type Vec = number[];

/* ------------------------------------------------------------ writing numbers ------------------------------------------------------------ */

/** a whole number or a fraction, with a real minus sign: "−3", "5/2" */
export const sn = (x: number) => formatAnswer(x, "fraction");
/** "(3, −1)" */
export const vec = (v: Vec) => `(${v.map(sn).join(", ")})`;
/** "[[2, −1], [1, 1]]" */
export const mat = (A: Mat) => `[${A.map(r => `[${r.map(sn).join(", ")}]`).join(", ")}]`;
/** a decimal to a fixed number of places, with a real minus sign and no "−0.0" */
export const dec = (x: number, places = 1) => {
  const s = Math.abs(x).toFixed(places);
  return x < 0 && Number(s) !== 0 ? `−${s}` : s;
};

/**
 * A sum of terms written the way a person would: "2u − 3v", "u", "−v", "x + 2y − z", "0". A coefficient of 1 is
 * never printed, a 0 term is left out, and a minus never follows a plus.
 */
export function lin(terms: [number, string][], zero = "0"): string {
  let out = "";
  for (const [c, name] of terms) {
    if (c === 0) continue;
    const mag = Math.abs(c), body = name ? `${mag === 1 ? "" : sn(mag)}${name}` : sn(mag);
    out += out ? (c < 0 ? ` − ${body}` : ` + ${body}`) : c < 0 ? `−${body}` : body;
  }
  return out || zero;
}
/** a product written for a check line, "2·(−2)", "(−1)·6" */
export const times = (a: number, b: number) => `${a < 0 ? `(${sn(a)})` : sn(a)}·${b < 0 ? `(${sn(b)})` : sn(b)}`;
/** a number times an arrow, "2·(3, 1)", "(3, 1)" for 1, "−(3, 1)" for −1 */
export const kv = (k: number, v: number[]) => (k === 1 ? vec(v) : k === -1 ? `−${vec(v)}` : `${sn(k)}·${vec(v)}`);
/** numbers added up as a person writes them: "−4 − 3 + 7" */
export const sumText = (xs: number[]) => lin(xs.map(x => [x, ""] as [number, string]));
/** a percent: "72.0%" */
export const pct = (x: number, places = 1) => `${dec(x, places)}%`;

/* ------------------------------------------------------------ vectors ------------------------------------------------------------ */

export const dot = (a: Vec, b: Vec) => a.reduce((s, x, i) => s + x * b[i]!, 0);
export const addv = (a: Vec, b: Vec) => a.map((x, i) => x + b[i]!);
export const subv = (a: Vec, b: Vec) => a.map((x, i) => x - b[i]!);
export const scalev = (k: number, a: Vec) => a.map(x => k * x);
export const norm = (a: Vec) => Math.hypot(...a);
export const cross = (u: Vec, w: Vec): Vec => [u[1]! * w[2]! - u[2]! * w[1]!, u[2]! * w[0]! - u[0]! * w[2]!, u[0]! * w[1]! - u[1]! * w[0]!];
export const det2 = (A: Mat) => A[0]![0]! * A[1]![1]! - A[0]![1]! * A[1]![0]!;
export const det3 = (A: Mat) => dot(A[0]!, cross(A[1]!, A[2]!));
/** a 2 × 2 matrix times a vector */
export const apply2 = (A: Mat, x: Vec): Vec => [A[0]![0]! * x[0]! + A[0]![1]! * x[1]!, A[1]![0]! * x[0]! + A[1]![1]! * x[1]!];
export const applyM = (A: Mat, x: Vec): Vec => A.map(r => dot(r, x));
/** matrix product, any sizes that fit */
export const mm = (A: Mat, B: Mat): Mat => A.map(r => B[0]!.map((_, j) => r.reduce((s, x, t) => s + x * B[t]![j]!, 0)));
export const tr = (A: Mat): Mat => A[0]!.map((_, j) => A.map(r => r[j]!));
/** columns to a matrix */
export const fromCols = (cols: Vec[]): Mat => cols[0]!.map((_, i) => cols.map(c => c[i]!));
export const col = (A: Mat, j: number): Vec => A.map(r => r[j]!);
/** the exact inverse of a 2 × 2 (entries come out as the fractions they are) */
export const inv2 = (A: Mat): Mat => { const d = det2(A); return [[A[1]![1]! / d, -A[0]![1]! / d], [-A[1]![0]! / d, A[0]![0]! / d]]; };
export const gcd = (a: number, b: number): number => (b ? gcd(b, a % b) : Math.abs(a));
export const same = (A: Mat, B: Mat) => A.every((r, i) => r.every((x, j) => Math.abs(x - B[i]![j]!) < 1e-9));

/** the rank of a small matrix, by row reduction with a tolerance */
export function rankOf(A: Mat, tol = 1e-9): number {
  const t = A.map(r => [...r]);
  const m = t.length, n = t[0]!.length;
  let rank = 0;
  for (let c = 0; c < n && rank < m; c++) {
    let p = rank;
    for (let r = rank + 1; r < m; r++) if (Math.abs(t[r]![c]!) > Math.abs(t[p]![c]!)) p = r;
    if (Math.abs(t[p]![c]!) < tol) continue;
    [t[p], t[rank]] = [t[rank]!, t[p]!];
    for (let r = 0; r < m; r++) if (r !== rank) { const f = t[r]![c]! / t[rank]![c]!; for (let j = c; j < n; j++) t[r]![j]! -= f * t[rank]![j]!; }
    rank++;
  }
  return rank;
}

/** a symmetric 2 × 2's eigenvalues (largest first) and unit eigenvectors, at right angles */
export function sym2(A: Mat): { l: [number, number]; v: [Vec, Vec] } {
  const a = A[0]![0]!, b = A[0]![1]!, d = A[1]![1]!;
  const th = 0.5 * Math.atan2(2 * b, a - d);
  const v1 = [Math.cos(th), Math.sin(th)], v2 = [-Math.sin(th), Math.cos(th)];
  const q = (v: Vec) => a * v[0]! ** 2 + 2 * b * v[0]! * v[1]! + d * v[1]! ** 2;
  const l1 = q(v1), l2 = q(v2);
  return l1 >= l2 ? { l: [l1, l2], v: [v1, v2] } : { l: [l2, l1], v: [v2, v1] };
}

/** a 2 × 2's singular values and the input and output directions (σ₁ ≥ σ₂ ≥ 0) */
export function svd2(A: Mat): { s: [number, number]; v: [Vec, Vec]; u: [Vec, Vec] } {
  const e = sym2(mm(tr(A), A));
  const s: [number, number] = [Math.sqrt(Math.max(0, e.l[0])), Math.sqrt(Math.max(0, e.l[1]))];
  const w1 = apply2(A, e.v[0]), u1 = s[0] > 1e-12 ? scalev(1 / s[0], w1) : [1, 0];
  const w2 = apply2(A, e.v[1]), u2 = s[1] > 1e-12 ? scalev(1 / s[1], w2) : [-u1[1]!, u1[0]!];
  return { s, v: e.v, u: [u1, u2] };
}

/* ------------------------------------------------------------ the SVD ------------------------------------------------------------ */

/**
 * The singular value decomposition A = U Σ Vᵀ by one-sided Jacobi: turn pairs of columns until they're all at right
 * angles; their lengths are the σ's. Exact enough for pictures up to about 100 × 100, and simple.
 */
export function svd(A: Mat): { U: Mat; s: number[]; V: Mat } {
  const m = A.length, n = A[0]!.length;
  if (m < n) { const t = svd(tr(A)); return { U: t.V, s: t.s, V: t.U }; }
  const W = A.map(r => [...r]);
  const V: Mat = Array.from({ length: n }, (_, i) => Array.from({ length: n }, (_, j) => (i === j ? 1 : 0)));
  for (let sweep = 0; sweep < 40; sweep++) {
    let off = 0;
    for (let p = 0; p < n - 1; p++) for (let q = p + 1; q < n; q++) {
      let a = 0, b = 0, g = 0;
      for (let i = 0; i < m; i++) { const x = W[i]![p]!, y = W[i]![q]!; a += x * x; b += y * y; g += x * y; }
      if (Math.abs(g) <= 1e-13 * Math.sqrt(a * b) || g === 0) continue;
      off = Math.max(off, Math.abs(g) / Math.sqrt(a * b));
      const z = (b - a) / (2 * g), t = Math.sign(z || 1) / (Math.abs(z) + Math.sqrt(1 + z * z));
      const c = 1 / Math.sqrt(1 + t * t), s = c * t;
      for (let i = 0; i < m; i++) { const x = W[i]![p]!, y = W[i]![q]!; W[i]![p] = c * x - s * y; W[i]![q] = s * x + c * y; }
      for (let i = 0; i < n; i++) { const x = V[i]![p]!, y = V[i]![q]!; V[i]![p] = c * x - s * y; V[i]![q] = s * x + c * y; }
    }
    if (off < 1e-12) break;
  }
  const sig = Array.from({ length: n }, (_, j) => Math.sqrt(W.reduce((s, r) => s + r[j]! ** 2, 0)));
  const order = sig.map((_, j) => j).sort((x, y) => sig[y]! - sig[x]!);
  const s = order.map(j => sig[j]!);
  const U = W.map(r => order.map(j => (sig[j]! > 1e-12 ? r[j]! / sig[j]! : 0)));
  const Vs = V.map(r => order.map(j => r[j]!));
  return { U, s, V: Vs };
}

/** the first k layers added up: σ₁u₁v₁ᵀ + … + σₖuₖvₖᵀ */
export function rebuild(d: { U: Mat; s: number[]; V: Mat }, k: number): Mat {
  const m = d.U.length, n = d.V.length;
  return Array.from({ length: m }, (_, i) => Array.from({ length: n }, (_, j) => {
    let x = 0;
    for (let t = 0; t < k; t++) x += d.s[t]! * d.U[i]![t]! * d.V[j]![t]!;
    return x;
  }));
}
/** one layer on its own, σₜuₜvₜᵀ */
export const layer = (d: { U: Mat; s: number[]; V: Mat }, t: number): Mat => d.U.map(r => d.V.map(v => d.s[t]! * r[t]! * v[t]!));
/** the share of energy the first k layers keep, 0 to 1 */
export const energyKept = (s: number[], k: number) => { const all = s.reduce((a, x) => a + x * x, 0); return all ? s.slice(0, k).reduce((a, x) => a + x * x, 0) / all : 1; };

/* ------------------------------------------------------------ the learner's picture ------------------------------------------------------------ */

/** The starting 8 × 8 picture (brightness 0 to 9): a sun over two hills. Each row is a vector of 8 numbers. */
export const IMG0: Mat = [
  [0, 0, 1, 2, 2, 1, 0, 0],
  [0, 1, 4, 7, 7, 4, 1, 0],
  [0, 2, 7, 9, 9, 7, 2, 0],
  [0, 1, 4, 7, 7, 4, 1, 0],
  [1, 1, 2, 3, 3, 2, 1, 1],
  [3, 4, 3, 2, 2, 3, 4, 3],
  [6, 7, 6, 5, 5, 6, 7, 6],
  [8, 8, 8, 8, 8, 8, 8, 8],
];
/** the shelf's `img` if it is an 8 × 8 grid, or the starting picture */
export function readImg(v: unknown): Mat {
  if (Array.isArray(v) && v.length === 8 && v.every(r => Array.isArray(r) && r.length === 8 && r.every(x => typeof x === "number"))) return v as Mat;
  return IMG0;
}

/**
 * A stand-in photo, m × n, brightness 0 to 1: a sky with a sun, a hill line, a house with a window, and some grain.
 * It has real detail at every size, so its σ's fall fast at first and then slowly, like a real photo's.
 */
export function samplePhoto(m = 64, n = 64): Mat {
  let seed = 7;
  const rnd = () => { seed = (seed * 16807) % 2147483647; return seed / 2147483647; };
  return Array.from({ length: m }, (_, i) => Array.from({ length: n }, (_, j) => {
    const y = i / (m - 1), x = j / (n - 1);
    let v = 0.75 - 0.35 * y;
    const sun = Math.hypot(x - 0.75, y - 0.22);
    if (sun < 0.11) v = 0.98;
    else if (sun < 0.16) v = Math.max(v, 0.9 - (sun - 0.11) * 4);
    const hill = 0.62 + 0.08 * Math.sin(x * 7) + 0.04 * Math.sin(x * 19 + 1);
    if (y > hill) v = 0.32 + 0.12 * Math.sin(x * 40) * Math.sin(y * 31) - 0.15 * (y - hill);
    if (x > 0.14 && x < 0.44 && y > 0.48 && y < 0.8) {
      v = 0.55;
      if (x > 0.22 && x < 0.32 && y > 0.56 && y < 0.66) v = 0.12;
      if (x > 0.34 && x < 0.4 && y > 0.66) v = 0.22;
    }
    if (y > 0.3 && y < 0.48 && x > 0.14 + (0.48 - y) * 0.83 && x < 0.44 - (0.48 - y) * 0.83) v = 0.38;
    return Math.max(0, Math.min(1, v + (rnd() - 0.5) * 0.06));
  }));
}

/* ------------------------------------------------------------ the build's arithmetic ------------------------------------------------------------ */

/** numbers k layers of an m × n picture store */
export const storage = (k: number, m: number, n: number) => k * (m + n + 1);
/** the largest k that still stores fewer numbers than the picture: the whole part of (m n − 1) / (m + n + 1) */
export const largestK = (m: number, n: number) => Math.floor((m * n - 1) / (m + n + 1));
