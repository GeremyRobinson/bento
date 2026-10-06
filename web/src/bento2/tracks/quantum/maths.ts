// Quantum's maths, in one place, for the pictures, the lessons and the build: complex arrows, qubit states on the
// sphere, one-qubit gates in "units", two-qubit states, the H⊗H transform, Grover's rounds and a seeded shot maker.
import { formatAnswer, toFraction } from "../../steps";

/** a complex number as [re, im] */
export type Cx = [number, number];
export const cAdd = (a: Cx, b: Cx): Cx => [a[0] + b[0], a[1] + b[1]];
export const cMul = (a: Cx, b: Cx): Cx => [a[0] * b[0] - a[1] * b[1], a[0] * b[1] + a[1] * b[0]];
export const cAbs2 = (a: Cx) => a[0] * a[0] + a[1] * a[1];
export const cExp = (deg: number): Cx => [Math.cos((deg * Math.PI) / 180), Math.sin((deg * Math.PI) / 180)];
export const rad = (deg: number) => (deg * Math.PI) / 180;
export const deg = (r: number) => (r * 180) / Math.PI;
/** cos of a whole-degree angle, with the exact values at the friendly angles (no 6.1e-17 for cos 90°) */
export const cosD = (d: number) => {
  const m = ((d % 360) + 360) % 360;
  const exact: Record<number, number> = { 0: 1, 60: 0.5, 90: 0, 120: -0.5, 180: -1, 240: -0.5, 270: 0, 300: 0.5 };
  return m in exact ? exact[m]! : Math.cos(rad(d));
};

/** "−3" with a real minus sign */
export const sn = (x: number) => (x < 0 ? `−${fr(-x)}` : fr(x));
/** a fraction as it's typed: "5/4", "−3" */
export const fr = (x: number) => formatAnswer(x, "fraction");
/** a number after an operator: a negative gets brackets */
export const par = (x: number) => (x < 0 ? `(${sn(x)})` : fr(x));
/** "1 + 2i", "2i", "1 − i", "−3" */
export function cx(re: number, im: number): string {
  const imPart = (v: number) => (Math.abs(v) === 1 ? "i" : `${fr(Math.abs(v))}i`);
  if (im === 0) return sn(re);
  if (re === 0) return `${im < 0 ? "−" : ""}${imPart(im)}`;
  return `${sn(re)} ${im < 0 ? "−" : "+"} ${imPart(im)}`;
}
/** true when x is a fraction the keypad can show exactly (denominator up to 10,000) */
export const isNiceFraction = (x: number) => { const [n, d] = toFraction(x); return Math.abs(n / d - x) < 1e-12 && d <= 10000; };
/** "(3/5, −4/5)" */
export const tuple = (xs: number[]) => `(${xs.map(sn).join(", ")})`;

/* ------------------------------------------------------------- the qubit sphere ------------------------------------------------------------- */

/** a point on the sphere from θ (down from the top) and φ (around), in degrees */
export const blochVec = (th: number, ph: number): [number, number, number] =>
  [Math.sin(rad(th)) * Math.cos(rad(ph)), Math.sin(rad(th)) * Math.sin(rad(ph)), Math.cos(rad(th))];
export const fromVec = (v: [number, number, number]): [number, number] => {
  const z = Math.max(-1, Math.min(1, v[2]));
  const th = deg(Math.acos(z));
  const ph = th < 1e-6 || th > 180 - 1e-6 ? 0 : (deg(Math.atan2(v[1], v[0])) + 360) % 360;
  return [th, ph];
};
/** a vector turned by angle (degrees) about a unit axis (Rodrigues) */
export function turn(v: [number, number, number], axis: [number, number, number], a: number): [number, number, number] {
  const c = Math.cos(rad(a)), s = Math.sin(rad(a));
  const [x, y, z] = v, [u, w, k] = axis, dot = u * x + w * y + k * z;
  const cr: [number, number, number] = [w * z - k * y, k * x - u * z, u * y - w * x];
  return [x * c + cr[0] * s + u * dot * (1 - c), y * c + cr[1] * s + w * dot * (1 - c), z * c + cr[2] * s + k * dot * (1 - c)];
}
/** each gate as a turn of the sphere: X and Z by 180° about their axes, H about the diagonal, S by 90° about z */
export const GATE_TURNS: Record<string, { axis: [number, number, number]; angle: number }> = {
  X: { axis: [1, 0, 0], angle: 180 },
  Z: { axis: [0, 0, 1], angle: 180 },
  H: { axis: [Math.SQRT1_2, 0, Math.SQRT1_2], angle: 180 },
  S: { axis: [0, 0, 1], angle: 90 },
};
export const p0OfTheta = (th: number) => Math.cos(rad(th / 2)) ** 2;

/* ---------------------------------------------------------- one qubit, in units ---------------------------------------------------------- */

/** a real one-qubit state written in units: the amplitudes are u / √2 when `r` is true, u otherwise */
export interface Units { u: [number, number]; r: boolean }
export function applyGate(s: Units, g: "X" | "Z" | "H"): Units {
  const [a, b] = s.u;
  if (g === "X") return { u: [b, a], r: s.r };
  if (g === "Z") return { u: [a, -b], r: s.r };
  return s.r ? { u: [(a + b) / 2, (a - b) / 2], r: false } : { u: [a + b, a - b], r: true };
}
export const realAmps = (s: Units): [number, number] => (s.r ? [s.u[0] * Math.SQRT1_2, s.u[1] * Math.SQRT1_2] : s.u);
export const p0Units = (s: Units) => (s.r ? s.u[0] ** 2 / 2 : s.u[0] ** 2);

/* --------------------------------------------------------------- two qubits --------------------------------------------------------------- */

export const kron = (a: number[], b: number[]) => a.flatMap(x => b.map(y => x * y));
/** CNOT, the top qubit the control: swaps the amplitudes of 10 and 11 */
export const cnot = (v: number[]) => [v[0]!, v[1]!, v[3]!, v[2]!];
export const crossCheck = (v: number[]) => v[0]! * v[3]! - v[1]! * v[2]!;
export const LABELS2 = ["00", "01", "10", "11"];
/** H on both qubits: out(y) = ½ Σ_x (−1)^(x·y) a(x), x and y as two-bit numbers */
export const popcount = (n: number) => n.toString(2).split("").filter(c => c === "1").length;
export const hh = (a: number[]) => a.map((_, y) => a.reduce((s, ax, x) => s + (popcount(x & y) % 2 ? -ax : ax), 0) / 2);
/** the classic mix-up: matching the top digit with the bottom one */
const swapBits = (n: number) => ((n & 1) << 1) | ((n & 2) >> 1);
export const hhCrossed = (a: number[]) => a.map((_, y) => a.reduce((s, ax, x) => s + (popcount(x & swapBits(y)) % 2 ? -ax : ax), 0) / 2);
/** the Walsh–Hadamard transform for n bits (any power of two length), with ½ per qubit */
export function walsh(a: number[]): number[] {
  const n = Math.log2(a.length), k = 2 ** (-n / 2);
  return a.map((_, y) => a.reduce((s, ax, x) => s + (popcount(x & y) % 2 ? -ax : ax), 0) * k);
}

/* ------------------------------------------------------------------ Grover ------------------------------------------------------------------ */

/** one round on N amplitudes: flip the marked one, then reflect every amplitude about the mean */
export function groverRound(a: number[], m: number): number[] {
  const f = a.map((x, i) => (i === m ? -x : x));
  const mean = f.reduce((s, x) => s + x, 0) / f.length;
  return f.map(x => 2 * mean - x);
}
/** P(marked) after k rounds, from the rotation picture */
export const groverP = (N: number, k: number) => Math.sin((2 * k + 1) * Math.asin(1 / Math.sqrt(N))) ** 2;
export const bestRounds = (N: number) => {
  let best = 0;
  for (let k = 1; k < 40; k++) if (groverP(N, k) > groverP(N, best) + 1e-12) best = k; else if (k > best + 1) break;
  return best;
};

/* ------------------------------------------------------------------- shots ------------------------------------------------------------------- */

/** a small seeded random stream for the pictures' shots, so a run is the same each time it's drawn */
export function stream(seed: number) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
/** outcomes of n shots with these chances (they add to 1): one index per shot */
export function shots(ps: number[], n: number, seed: number): number[] {
  const r = stream(seed), out: number[] = [];
  for (let i = 0; i < n; i++) {
    let u = r(), k = 0;
    while (k < ps.length - 1 && u >= ps[k]!) { u -= ps[k]!; k++; }
    out.push(k);
  }
  return out;
}
export const tally = (outs: number[], k: number, upTo = outs.length) => {
  const c = new Array<number>(k).fill(0);
  for (let i = 0; i < upTo; i++) c[outs[i]!]!++;
  return c;
};
