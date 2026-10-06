// Differential equations' maths, in one place, for the pictures, the lessons and the build: the three steppers every
// model runs on, 2×2 linear algebra (trace, determinant, eigenvalues, the region of the trace–determinant map), and
// the closed forms the lessons name (pendulum period, resonance, SIR peak). Nothing is rounded here.

export type Vec = number[];
export type Field = (t: number, y: Vec) => Vec;
export type Method = "euler" | "heun" | "rk4";
export const METHODS: Method[] = ["euler", "heun", "rk4"];
export const METHOD_NAMES: Record<Method, string> = { euler: "Euler", heun: "Heun", rk4: "RK4" };

const add = (y: Vec, k: Vec, h: number) => y.map((v, i) => v + h * k[i]!);

/** one step of a method on y′ = f(t, y) */
export function stepWith(m: Method, f: Field, t: number, y: Vec, h: number): Vec {
  const k1 = f(t, y);
  if (m === "euler") return add(y, k1, h);
  if (m === "heun") { const k2 = f(t + h, add(y, k1, h)); return y.map((v, i) => v + (h / 2) * (k1[i]! + k2[i]!)); }
  const k2 = f(t + h / 2, add(y, k1, h / 2)), k3 = f(t + h / 2, add(y, k2, h / 2)), k4 = f(t + h, add(y, k3, h));
  return y.map((v, i) => v + (h / 6) * (k1[i]! + 2 * k2[i]! + 2 * k3[i]! + k4[i]!));
}

/** the path from (t0, y0) to t1 in steps of about h (the last step lands on t1); every point, start included */
export function solve(f: Field, y0: Vec, t0: number, t1: number, h: number, m: Method = "rk4"): { t: number; y: Vec }[] {
  const n = Math.max(1, Math.ceil(Math.abs(t1 - t0) / h - 1e-9)), dt = (t1 - t0) / n;
  const out = [{ t: t0, y: y0 }];
  let y = y0;
  for (let i = 0; i < n; i++) {
    y = stepWith(m, f, t0 + i * dt, y, dt);
    out.push({ t: t0 + (i + 1) * dt, y });
    if (!y.every(Number.isFinite) || y.some(v => Math.abs(v) > 1e6)) break;
  }
  return out;
}

/* ------------------------------------------------------------- 2×2 systems ------------------------------------------------------------- */

export type M2 = [[number, number], [number, number]];
export const trace = (A: M2) => A[0][0] + A[1][1];
export const det = (A: M2) => A[0][0] * A[1][1] - A[0][1] * A[1][0];
export const mul = (A: M2, v: [number, number]): [number, number] => [A[0][0] * v[0] + A[0][1] * v[1], A[1][0] * v[0] + A[1][1] * v[1]];

/** eigenvalues from T and D: two real ones (larger first) or α ± βi */
export function eig(T: number, D: number): { real: true; l1: number; l2: number } | { real: false; a: number; b: number } {
  const disc = T * T - 4 * D;
  if (disc >= 0) { const r = Math.sqrt(disc); return { real: true, l1: (T + r) / 2, l2: (T - r) / 2 }; }
  return { real: false, a: T / 2, b: Math.sqrt(-disc) / 2 };
}

/** the tap choices for a rest point's type, in the order every lesson uses */
export const TYPES = ["Saddle", "Node in", "Node out", "Spiral in", "Spiral out", "Center", "Border: repeated eigenvalue"] as const;
/** the region of the trace–determinant map, as an index into TYPES (D = 0 is never asked) */
export function region(T: number, D: number): number {
  if (D < 0) return 0;
  const disc = T * T - 4 * D;
  if (disc === 0) return 6;
  if (disc > 0) return T < 0 ? 1 : 2;
  return T < 0 ? 3 : T > 0 ? 4 : 5;
}
/** the same, with a little room for floating point (the pictures, where T and D come from sliders) */
export const regionNear = (T: number, D: number, eps = 1e-9) => {
  if (Math.abs(D) < eps) return -1;
  if (D > 0 && Math.abs(T * T - 4 * D) < eps) return 6;
  if (D > 0 && T * T < 4 * D && Math.abs(T) < eps) return 5;
  return region(T, D);
};
export const stableAt = (T: number, D: number) => T < 0 && D > 0;

/** eigenvector directions for real eigenvalues (unit vectors), or none */
export function eigenLines(A: M2): [number, number][] {
  const e = eig(trace(A), det(A));
  if (!e.real) return [];
  const dir = (l: number): [number, number] => {
    const [a, b] = A[0], [c, d] = A[1];
    let v: [number, number] = Math.abs(b) > 1e-12 ? [b, l - a] : Math.abs(c) > 1e-12 ? [l - d, c] : Math.abs(l - a) < 1e-12 ? [1, 0] : [0, 1];
    const n = Math.hypot(...v);
    v = [v[0] / n, v[1] / n];
    return v;
  };
  return e.l1 === e.l2 ? [dir(e.l1)] : [dir(e.l1), dir(e.l2)];
}

/* ------------------------------------------------------------- closed forms ------------------------------------------------------------- */

export const G = 9.81;
/** small-swing period 2π√(L/g) */
export const smallPeriod = (L: number, g = G) => 2 * Math.PI * Math.sqrt(L / g);
/** the exact period at release angle θ₀ (radians): 2π√(L/g) / AGM(1, cos(θ₀/2)) */
export function pendulumPeriod(L: number, th0: number, g = G) {
  let a = 1, b = Math.cos(th0 / 2);
  for (let i = 0; i < 30 && Math.abs(a - b) > 1e-15; i++) [a, b] = [(a + b) / 2, Math.sqrt(a * b)];
  return smallPeriod(L, g) / a;
}
/** steady amplitude of x″ + cx′ + ω₀²x = F cos ωt */
export const steadyAmp = (F: number, w0: number, w: number, c: number) => F / Math.sqrt((w0 * w0 - w * w) ** 2 + (c * w) ** 2);
/** SIR: the largest fraction infected at once, starting with almost everyone susceptible */
export const sirPeak = (R0: number) => (R0 <= 1 ? 0 : 1 - (1 + Math.log(R0)) / R0);
/** logistic harvest: the rest points of rP(1 − P/K) = H, low first, or none past the fold */
export function harvestRests(r: number, K: number, H: number): [number, number] | null {
  const disc = 1 - (4 * H) / (r * K);
  if (disc < 0) return null;
  const s = Math.sqrt(disc);
  return [(K / 2) * (1 - s), (K / 2) * (1 + s)];
}
/** the logistic map's gap: steps until a doubling gap g reaches G */
export const doublings = (g: number, Gt: number) => Math.ceil(Math.log2(Gt / g) - 1e-12);
