// The patch reader (11's Use it): the 8 × 8 digit cut into 16 patches of 2 × 2. Each patch becomes a vector of d
// numbers (its 4 pixels times an embedding matrix, plus a position vector); one layer of self-attention lets every
// patch mix in the others (queries, keys, values, softmax weights, a residual); the 16 results, side by side, go
// through a last matrix that scores the 10 digits. A tiny vision transformer, trained by backprop with seeded mini-batches.
import { digitData, gauss, seeded, type DigitSet } from "./digits";

export const PD = 12, NP = 16;

export interface PatchNet { E: Float64Array; pos: Float64Array; Wq: Float64Array; Wk: Float64Array; Wv: Float64Array; Wo: Float64Array; U: Float64Array; bu: Float64Array }
type G = { [K in keyof PatchNet]: Float64Array };

export const patchParams = () => 4 * PD + NP * PD + 4 * PD * PD + 10 * NP * PD + 10;

export function newPatchNet(seed = 3): PatchNet {
  const r = seeded(seed), m = (n: number, s: number) => Float64Array.from({ length: n }, () => gauss(r) * s);
  return { E: m(4 * PD, 0.5), pos: m(NP * PD, 0.3), Wq: m(PD * PD, 1 / Math.sqrt(PD)), Wk: m(PD * PD, 1 / Math.sqrt(PD)), Wv: m(PD * PD, 1 / Math.sqrt(PD)), Wo: m(PD * PD, 0.5 / Math.sqrt(PD)), U: m(10 * NP * PD, 1 / Math.sqrt(NP * PD)), bu: new Float64Array(10) };
}

/** the 4 pixels of patch p (row-major 4 × 4 grid of 2 × 2 patches) */
const patchPix = (x: ArrayLike<number>, p: number) => { const r = Math.floor(p / 4) * 2, c = (p % 4) * 2; return [x[r * 8 + c]!, x[r * 8 + c + 1]!, x[(r + 1) * 8 + c]!, x[(r + 1) * 8 + c + 1]!]; };
const mv = (W: Float64Array, x: ArrayLike<number>, rows: number, cols: number) => { const y = new Float64Array(rows); for (let i = 0; i < rows; i++) { let s = 0; for (let j = 0; j < cols; j++) s += W[i * cols + j]! * x[j]!; y[i] = s; } return y; };

export function patchForward(n: PatchNet, img: ArrayLike<number>) {
  const P = Array.from({ length: NP }, (_, p) => patchPix(img, p));
  const X = P.map((px, p) => { const x = new Float64Array(PD); for (let k = 0; k < PD; k++) { let s = n.pos[p * PD + k]!; for (let j = 0; j < 4; j++) s += n.E[j * PD + k]! * px[j]!; x[k] = s; } return x; });
  const Q = X.map(x => mv(n.Wq, x, PD, PD)), K = X.map(x => mv(n.Wk, x, PD, PD)), V = X.map(x => mv(n.Wv, x, PD, PD));
  const A = Q.map(q => { const s = K.map(k => { let d = 0; for (let j = 0; j < PD; j++) d += q[j]! * k[j]!; return d / Math.sqrt(PD); }); const m = Math.max(...s), e = s.map(v => Math.exp(v - m)), t = e.reduce((a, b) => a + b, 0); return e.map(v => v / t); });
  const O = A.map(a => { const o = new Float64Array(PD); a.forEach((w, j) => { for (let k = 0; k < PD; k++) o[k]! += w * V[j]![k]!; }); return o; });
  const R = X.map((x, i) => { const wo = mv(n.Wo, O[i]!, PD, PD); return x.map((v, k) => v + wo[k]!); });
  const pool = new Float64Array(NP * PD);
  R.forEach((r, i) => pool.set(r, i * PD));
  const z = mv(n.U, pool, 10, NP * PD).map((v, k) => v + n.bu[k]!);
  const m = Math.max(...z), e = [...z].map(v => Math.exp(v - m)), t = e.reduce((a, b) => a + b, 0);
  return { P, X, Q, K, V, A, O, R, pool, z, p: e.map(v => v / t) };
}

const zeros = (n: PatchNet): G => Object.fromEntries(Object.entries(n).map(([k, v]) => [k, new Float64Array((v as Float64Array).length)])) as G;

/** backprop for one picture and its digit; adds into g */
export function patchBackward(n: PatchNet, img: ArrayLike<number>, y: number, g: G) {
  const f = patchForward(n, img), sd = Math.sqrt(PD);
  const dz = f.p.map((v, k) => v - (k === y ? 1 : 0));
  const dpool = new Float64Array(NP * PD), F = NP * PD;
  for (let k = 0; k < 10; k++) { g.bu[k]! += dz[k]!; for (let j = 0; j < F; j++) { g.U[k * F + j]! += dz[k]! * f.pool[j]!; dpool[j]! += dz[k]! * n.U[k * F + j]!; } }
  const dX = f.X.map(() => new Float64Array(PD)), dQ = f.X.map(() => new Float64Array(PD)), dK = f.X.map(() => new Float64Array(PD)), dV = f.X.map(() => new Float64Array(PD));
  for (let i = 0; i < NP; i++) {
    const dr = dpool.subarray(i * PD, (i + 1) * PD);
    dX[i]!.forEach((_, k) => { dX[i]![k]! += dr[k]!; });
    const dO = new Float64Array(PD);
    for (let a = 0; a < PD; a++) for (let b = 0; b < PD; b++) { g.Wo[a * PD + b]! += dr[a]! * f.O[i]![b]!; dO[b]! += dr[a]! * n.Wo[a * PD + b]!; }
    const da = f.V.map((v, j) => { let s = 0; for (let k = 0; k < PD; k++) s += dO[k]! * v[k]!; for (let k = 0; k < PD; k++) dV[j]![k]! += f.A[i]![j]! * dO[k]!; return s; });
    const dot = da.reduce((s, v, j) => s + v * f.A[i]![j]!, 0);
    for (let j = 0; j < NP; j++) {
      const ds = (f.A[i]![j]! * (da[j]! - dot)) / sd;
      for (let k = 0; k < PD; k++) { dQ[i]![k]! += ds * f.K[j]![k]!; dK[j]![k]! += ds * f.Q[i]![k]!; }
    }
  }
  const back = (W: Float64Array, GW: Float64Array, d: Float64Array[]) => {
    for (let i = 0; i < NP; i++) for (let a = 0; a < PD; a++) { const v = d[i]![a]!; if (!v) continue; for (let b = 0; b < PD; b++) { GW[a * PD + b]! += v * f.X[i]![b]!; dX[i]![b]! += v * W[a * PD + b]!; } }
  };
  back(n.Wq, g.Wq, dQ); back(n.Wk, g.Wk, dK); back(n.Wv, g.Wv, dV);
  for (let p = 0; p < NP; p++) for (let k = 0; k < PD; k++) { g.pos[p * PD + k]! += dX[p]![k]!; for (let j = 0; j < 4; j++) g.E[j * PD + k]! += dX[p]![k]! * f.P[p]![j]!; }
}

export function patchGrad(n: PatchNet, img: ArrayLike<number>, y: number): G { const g = zeros(n); patchBackward(n, img, y, g); return g; }

export interface PatchPlan { n: number; epochs: number; batch: number; eta: number; seed: number }
export const PATCH_PLAN: PatchPlan = { n: 2000, epochs: 6, batch: 20, eta: 0.2, seed: 3 };

/** one batch at a time, so a picture can draw while it trains; `end` marks the last batch of a pass */
export function* patchRun(plan: PatchPlan = PATCH_PLAN, data = digitData()) {
  const net = newPatchNet(plan.seed), r = seeded(plan.seed * 17 + plan.n);
  const N = Math.min(plan.n, data.train.y.length), order = Array.from({ length: N }, (_, i) => i);
  for (let e = 0; e < plan.epochs; e++) {
    for (let i = N - 1; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [order[i], order[j]] = [order[j]!, order[i]!]; }
    for (let s = 0; s < N; s += plan.batch) {
      const g = zeros(net), part = order.slice(s, s + plan.batch);
      for (const k of part) patchBackward(net, data.train.x[k]!, data.train.y[k]!, g);
      const step = plan.eta / part.length;
      for (const key of Object.keys(g) as (keyof PatchNet)[]) { const W = net[key], GW = g[key]; for (let i = 0; i < W.length; i++) W[i]! -= step * GW[i]!; }
      yield { epoch: e + 1, end: s + plan.batch >= N, net };
    }
  }
  return net;
}

export function patchError(n: PatchNet, set: DigitSet, limit = set.y.length): number {
  let wrong = 0;
  const m = Math.min(limit, set.y.length);
  for (let i = 0; i < m; i++) { const { p } = patchForward(n, set.x[i]!); if (p.indexOf(Math.max(...p)) !== set.y[i]) wrong++; }
  return wrong / m;
}
