// Matrix pad arithmetic: plain arrays of rows. Small sizes only (up to 4 × 4), so plain loops are enough.
export type Mat = number[][];

export const size = (a: Mat): [number, number] => [a.length, a[0]?.length ?? 0];
export const identity = (n: number): Mat => Array.from({ length: n }, (_, i) => Array.from({ length: n }, (_, j) => (i === j ? 1 : 0)));

export function mul(a: Mat, b: Mat): Mat {
  const [n, k] = size(a), [k2, m] = size(b);
  if (k !== k2) throw new Error(`Can't multiply: ${n}×${k} times ${k2}×${m}. The inside sizes must match.`);
  return Array.from({ length: n }, (_, i) => Array.from({ length: m }, (_, j) => a[i]!.reduce((s, x, t) => s + x * b[t]![j]!, 0)));
}
export const add = (a: Mat, b: Mat, sign = 1): Mat => {
  if (size(a).join() !== size(b).join()) throw new Error("Can't add: the sizes must match.");
  return a.map((r, i) => r.map((x, j) => x + sign * b[i]![j]!));
};
export const transpose = (a: Mat): Mat => a[0]!.map((_, j) => a.map(r => r[j]!));
export const scale = (a: Mat, k: number): Mat => a.map(r => r.map(x => x * k));

export function det(a: Mat): number {
  const [n, m] = size(a);
  if (n !== m) throw new Error("Only a square matrix has a determinant.");
  const t = a.map(r => [...r]);
  let d = 1;
  for (let c = 0; c < n; c++) {
    let p = c;
    for (let r = c + 1; r < n; r++) if (Math.abs(t[r]![c]!) > Math.abs(t[p]![c]!)) p = r;
    if (Math.abs(t[p]![c]!) < 1e-14) return 0;
    if (p !== c) { [t[p], t[c]] = [t[c]!, t[p]!]; d = -d; }
    d *= t[c]![c]!;
    for (let r = c + 1; r < n; r++) {
      const f = t[r]![c]! / t[c]![c]!;
      for (let j = c; j < n; j++) t[r]![j]! -= f * t[c]![j]!;
    }
  }
  return d;
}

export function inverse(a: Mat): Mat {
  const [n, m] = size(a);
  if (n !== m) throw new Error("Only a square matrix can have an inverse.");
  const t = a.map((r, i) => [...r, ...identity(n)[i]!]);
  for (let c = 0; c < n; c++) {
    let p = c;
    for (let r = c + 1; r < n; r++) if (Math.abs(t[r]![c]!) > Math.abs(t[p]![c]!)) p = r;
    if (Math.abs(t[p]![c]!) < 1e-12) throw new Error("No inverse: the determinant is 0.");
    [t[p], t[c]] = [t[c]!, t[p]!];
    const piv = t[c]![c]!;
    t[c] = t[c]!.map(x => x / piv);
    for (let r = 0; r < n; r++) if (r !== c) { const f = t[r]![c]!; t[r] = t[r]!.map((x, j) => x - f * t[c]![j]!); }
  }
  return t.map(r => r.slice(n));
}

/** Solves A x = b for a square A. */
export const solve = (a: Mat, b: number[]): number[] => mul(inverse(a), b.map(x => [x])).map(r => r[0]!);

/** Real eigenvalues of a 2 × 2 or 3 × 3 matrix, largest first; complex pairs are reported as such. */
export function eigen(a: Mat): { values: number[]; vectors: number[][]; complex: boolean } {
  const [n, m] = size(a);
  if (n !== m || n < 2 || n > 3) throw new Error("Eigenvalues here work for 2 × 2 and 3 × 3 matrices.");
  let values: number[] = [];
  let complex = false;
  if (n === 2) {
    const tr = a[0]![0]! + a[1]![1]!, d = det(a), disc = tr * tr - 4 * d;
    if (disc < -1e-12) complex = true;
    else { const s = Math.sqrt(Math.max(0, disc)); values = [(tr + s) / 2, (tr - s) / 2]; }
  } else {
    // characteristic polynomial λ³ − tr λ² + c1 λ − det, solved by the trigonometric method when all roots are real
    const tr = a[0]![0]! + a[1]![1]! + a[2]![2]!;
    const c1 = a[0]![0]! * a[1]![1]! - a[0]![1]! * a[1]![0]! + a[0]![0]! * a[2]![2]! - a[0]![2]! * a[2]![0]! + a[1]![1]! * a[2]![2]! - a[1]![2]! * a[2]![1]!;
    const d = det(a);
    const p = c1 - (tr * tr) / 3, q = (-2 * tr ** 3) / 27 + (tr * c1) / 3 - d;
    const disc = (q / 2) ** 2 + (p / 3) ** 3;
    if (disc > 1e-12) {
      complex = true;
      values = [Math.cbrt(-q / 2 + Math.sqrt(disc)) + Math.cbrt(-q / 2 - Math.sqrt(disc)) + tr / 3];
    } else if (Math.abs(p) < 1e-12) values = [tr / 3, tr / 3, tr / 3];
    else {
      // t³ + p t + q = 0 with t = λ − tr/3: t_k = 2√(−p/3) cos(⅓ arccos((3q / 2p) √(−3/p)) − 2πk/3)
      const r = 2 * Math.sqrt(-p / 3), th = Math.acos(Math.max(-1, Math.min(1, ((3 * q) / (2 * p)) * Math.sqrt(-3 / p)))) / 3;
      values = [0, 1, 2].map(k => r * Math.cos(th - (2 * Math.PI * k) / 3) + tr / 3);
    }
  }
  values.sort((x, y) => y - x);
  const vectors = values.map(l => nullVector(a.map((r, i) => r.map((x, j) => x - (i === j ? l : 0)))));
  return { values, vectors, complex };
}

/** A unit vector v with M v ≈ 0 (M is singular), for 2 × 2 and 3 × 3. */
function nullVector(mm: Mat): number[] {
  const n = mm.length;
  const unit = (v: number[]) => { const l = Math.hypot(...v); return l < 1e-12 ? v : v.map(x => x / l); };
  if (n === 2) {
    const [[a, b], [c, d]] = mm as [[number, number], [number, number]];
    const v = Math.abs(a) + Math.abs(b) > Math.abs(c) + Math.abs(d) ? [-b, a] : [-d, c];
    return unit(Math.hypot(...v) < 1e-12 ? [1, 0] : v);
  }
  const cross = (u: number[], w: number[]) => [u[1]! * w[2]! - u[2]! * w[1]!, u[2]! * w[0]! - u[0]! * w[2]!, u[0]! * w[1]! - u[1]! * w[0]!];
  const cands = [cross(mm[0]!, mm[1]!), cross(mm[0]!, mm[2]!), cross(mm[1]!, mm[2]!)];
  const best = cands.reduce((x, y) => (Math.hypot(...y) > Math.hypot(...x) ? y : x));
  return unit(Math.hypot(...best) < 1e-9 ? [1, 0, 0] : best);
}
