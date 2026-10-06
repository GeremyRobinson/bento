// Probability's maths in one place, for the pictures, the lessons and the build: the shared normal table
// (probability.md, "Tables built into the track"), the normal curve, counting, the Poisson and Beta pieces, and seeded
// draws for the pictures (a picture's randomness comes from a seed the learner moves on, never Math.random).
import { createRng, type Rng } from "../../../curriculum/generators/rng";
import { group } from "../../steps";

/** the track's one normal table: upper-tail areas P(Z > z) */
export const NORMAL_TABLE: readonly [number, number][] = [
  [0, 0.5], [0.5, 0.3085], [0.84, 0.2005], [1, 0.1587], [1.28, 0.1003], [1.5, 0.0668], [1.645, 0.05], [1.96, 0.025],
  [2, 0.0228], [2.33, 0.0099], [2.5, 0.0062], [2.576, 0.005], [3, 0.0013],
];
/** P(Z > z) from the table; negative z by symmetry. Throws for a z that isn't on it (every Work it z is). */
export function tableUpper(z: number): number {
  const row = NORMAL_TABLE.find(([v]) => Math.abs(v - Math.abs(z)) < 1e-9);
  if (!row) throw new Error(`z = ${z} is not on the table`);
  return z >= 0 ? row[1] : Math.round((1 - row[1]) * 1e4) / 1e4;
}

/** erf by Abramowitz–Stegun 7.1.26 is too rough for 4 places; this series/continued fraction pair is good to 1e-12 */
export function erf(x: number): number {
  const s = Math.sign(x), a = Math.abs(x);
  if (a < 2.5) {
    // Taylor series
    let sum = 0, term = a, n = 0;
    while (Math.abs(term) > 1e-17 && n < 200) { sum += term / (2 * n + 1); n++; term *= -(a * a) / n; }
    return s * (2 / Math.sqrt(Math.PI)) * sum;
  }
  // continued fraction for erfc
  let f = 0;
  for (let k = 60; k >= 1; k--) f = (k / 2) / (a + f);
  return s * (1 - Math.exp(-a * a) / Math.sqrt(Math.PI) / (a + f));
}
/** the normal curve's left area Φ(z) */
export const Phi = (z: number) => 0.5 * (1 + erf(z / Math.SQRT2));
/** Φ⁻¹(p) by bisection on Φ */
export function PhiInv(p: number): number {
  let lo = -10, hi = 10;
  for (let i = 0; i < 100; i++) { const m = (lo + hi) / 2; if (Phi(m) < p) lo = m; else hi = m; }
  return (lo + hi) / 2;
}
export const normalPdf = (z: number) => Math.exp(-z * z / 2) / Math.sqrt(2 * Math.PI);

export function comb(n: number, k: number): number {
  if (k < 0 || k > n) return 0;
  let r = 1;
  for (let i = 1; i <= Math.min(k, n - k); i++) r = (r * (n - i + 1)) / i;
  return Math.round(r);
}
export const fact = (n: number) => { let r = 1; for (let i = 2; i <= n; i++) r *= i; return r; };
export const poissonPmf = (k: number, lam: number) => (Math.exp(-lam) * lam ** k) / fact(k);
export const binomPmf = (k: number, n: number, p: number) => comb(n, k) * p ** k * (1 - p) ** (n - k);
/** the Beta(a, b) density, for a, b ≥ 1 or fractional (log-gamma by Lanczos) */
export function lgamma(x: number): number {
  const g = 7, c = [0.99999999999980993, 676.5203681218851, -1259.1392167224028, 771.32342877765313, -176.61502916214059,
    12.507343278686905, -0.13857109526572012, 9.9843695780195716e-6, 1.5056327351493116e-7];
  if (x < 0.5) return Math.log(Math.PI / Math.abs(Math.sin(Math.PI * x))) - lgamma(1 - x);
  x -= 1;
  let a = c[0]!;
  const t = x + g + 0.5;
  for (let i = 1; i < g + 2; i++) a += c[i]! / (x + i);
  return 0.5 * Math.log(2 * Math.PI) + (x + 0.5) * Math.log(t) - t + Math.log(a);
}
export const betaPdf = (x: number, a: number, b: number) =>
  x <= 0 || x >= 1 ? (x <= 0 ? (a < 1 ? Infinity : a === 1 ? b : 0) : (b < 1 ? Infinity : b === 1 ? a : 0))
    : Math.exp((a - 1) * Math.log(x) + (b - 1) * Math.log(1 - x) - (lgamma(a) + lgamma(b) - lgamma(a + b)));
/** the Beta(a, b) quantile, by bisection on a midpoint-rule CDF (fine for pictures and the project card) */
export function betaQuantile(q: number, a: number, b: number): number {
  const N = 2000, xs: number[] = [], cdf: number[] = [];
  let s = 0;
  for (let i = 0; i < N; i++) { const x = (i + 0.5) / N; s += betaPdf(x, a, b) / N; xs.push(x); cdf.push(s); }
  const total = s;
  const i = cdf.findIndex(c => c / total >= q);
  return xs[Math.max(0, i)]!;
}

/** a standard normal draw (Box–Muller) */
export const gauss = (rng: Rng) => { const u = 1 - rng.next(), v = rng.next(); return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v); };
/** a seeded generator for a picture: the same seed draws the same picture, a new run moves the seed on */
export const seeded = (seed: number) => createRng(0x9e3779b1 ^ (seed * 2654435761));

export const mean = (xs: number[]) => xs.reduce((a, b) => a + b, 0) / xs.length;
export const median = (xs: number[]) => { const s = [...xs].sort((a, b) => a - b), m = s.length >> 1; return s.length % 2 ? s[m]! : (s[m - 1]! + s[m]!) / 2; };
export const sd = (xs: number[]) => { const m = mean(xs); return Math.sqrt(xs.reduce((a, x) => a + (x - m) ** 2, 0) / (xs.length - 1)); };

/** a number with no trailing zeros, grouped: 241.125, 1,200, 0.5 */
export const trim = (x: number, places = 4) => group(x, places).replace(/(\.\d*?)0+$/, "$1").replace(/\.$/, "");
/** a percent to the given places: 27.9% */
export const pct = (x: number, places = 1) => `${group(x * 100, places)}%`;
/** a signed term for a sum: "+ 3" or "− 3" (never "+ −3") */
export const signTerm = (x: number, body = trim(Math.abs(x))) => (x < 0 ? `− ${body}` : `+ ${body}`);
/** a coefficient in front of a letter: "X", "−X", "2X", "−3X" (never "1X") */
export const coefOf = (a: number, v: string) => (a === 1 ? v : a === -1 ? `−${v}` : `${a < 0 ? "−" : ""}${trim(Math.abs(a))}${v}`);

/** BH: how many of these p-values Benjamini–Hochberg rejects at level q */
export function bhCount(ps: number[], q: number): number {
  const s = [...ps].sort((a, b) => a - b), m = s.length;
  let r = 0;
  s.forEach((p, i) => { if (p <= ((i + 1) * q) / m + 1e-12) r = i + 1; });
  return r;
}
/** the Bonferroni cutoffs for m two-sided metrics at α = 0.05 (pr-20's table) */
export const CUTOFFS: Record<number, number> = { 1: 1.96, 2: 2.24, 5: 2.58, 10: 2.81 };
