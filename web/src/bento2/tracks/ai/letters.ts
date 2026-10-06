// The Next-letter machine (project after b2-ai-12): a one-block character model, trained in the browser. Each letter
// becomes a vector (embedding plus position); the last letter asks a question (query) of the 8 letters before it
// (keys), mixes their values by softmax weights, adds the result back (residual), runs a small two-layer network and
// adds again, then scores every letter that could come next. Trained by backprop and gradient descent, seeded.
import { gauss, seeded } from "./digits";

export const CTX = 8, DIM = 16, HID = 32;

export interface LetterModel {
  vocab: string[];
  E: Float64Array; P: Float64Array;
  Wq: Float64Array; Wk: Float64Array; Wv: Float64Array; Wo: Float64Array;
  W1: Float64Array; b1: Float64Array; W2: Float64Array; b2: Float64Array;
  U: Float64Array; bu: Float64Array;
}

export const letterParams = (V: number) => V * DIM + CTX * DIM + 4 * DIM * DIM + DIM * HID + HID + HID * DIM + DIM + V * DIM + V;

export function newLetterModel(text: string, seed = 11): LetterModel {
  const vocab = [...new Set(text)].sort();
  const V = vocab.length, r = seeded(seed);
  const m = (n: number, s: number) => Float64Array.from({ length: n }, () => gauss(r) * s);
  return {
    vocab, E: m(V * DIM, 0.3), P: m(CTX * DIM, 0.1),
    Wq: m(DIM * DIM, 1 / Math.sqrt(DIM)), Wk: m(DIM * DIM, 1 / Math.sqrt(DIM)), Wv: m(DIM * DIM, 1 / Math.sqrt(DIM)), Wo: m(DIM * DIM, 0.5 / Math.sqrt(DIM)),
    W1: m(HID * DIM, Math.sqrt(2 / DIM)), b1: new Float64Array(HID), W2: m(DIM * HID, 0.5 / Math.sqrt(HID)), b2: new Float64Array(DIM),
    U: m(V * DIM, 1 / Math.sqrt(DIM)), bu: new Float64Array(V),
  };
}

const mv = (W: Float64Array, x: Float64Array, rows: number, cols: number, b?: Float64Array) => {
  const y = new Float64Array(rows);
  for (let i = 0; i < rows; i++) { let s = b ? b[i]! : 0; const o = i * cols; for (let j = 0; j < cols; j++) s += W[o + j]! * x[j]!; y[i] = s; }
  return y;
};
/** Wᵀg, added into out */
const mtv = (W: Float64Array, g: Float64Array, rows: number, cols: number, out: Float64Array) => {
  for (let i = 0; i < rows; i++) { const gi = g[i]!; if (!gi) continue; const o = i * cols; for (let j = 0; j < cols; j++) out[j]! += W[o + j]! * gi; }
};
const outer = (G: Float64Array, g: Float64Array, x: Float64Array, rows: number, cols: number) => {
  for (let i = 0; i < rows; i++) { const gi = g[i]!; if (!gi) continue; const o = i * cols; for (let j = 0; j < cols; j++) G[o + j]! += gi * x[j]!; }
};

/** the letters before a spot, as vocab indices (the last CTX of them) */
export const encode = (m: LetterModel, s: string) => [...s].map(c => m.vocab.indexOf(c)).filter(i => i >= 0);

/** the forward pass for one window; `ids` are up to CTX letters, the last one asks */
export function letterForward(m: LetterModel, ids: number[]) {
  const n = ids.length, V = m.vocab.length, last = n - 1;
  const X = ids.map((c, i) => { const x = new Float64Array(DIM); for (let k = 0; k < DIM; k++) x[k] = m.E[c * DIM + k]! + m.P[(CTX - n + i) * DIM + k]!; return x; });
  const q = mv(m.Wq, X[last]!, DIM, DIM);
  const K = X.map(x => mv(m.Wk, x, DIM, DIM)), Vv = X.map(x => mv(m.Wv, x, DIM, DIM));
  const s = K.map(k => { let d = 0; for (let j = 0; j < DIM; j++) d += q[j]! * k[j]!; return d / Math.sqrt(DIM); });
  const mx = Math.max(...s), e = s.map(v => Math.exp(v - mx)), es = e.reduce((a, b) => a + b, 0), a = e.map(v => v / es);
  const o = new Float64Array(DIM);
  Vv.forEach((v, i) => { for (let j = 0; j < DIM; j++) o[j]! += a[i]! * v[j]!; });
  const att = mv(m.Wo, o, DIM, DIM);
  const r1 = X[last]!.map((v, j) => v + att[j]!);
  const u = mv(m.W1, r1, HID, DIM, m.b1), hdn = u.map(v => (v > 0 ? v : 0));
  const mlp = mv(m.W2, hdn, DIM, HID, m.b2);
  const r2 = r1.map((v, j) => v + mlp[j]!);
  const z = mv(m.U, r2, V, DIM, m.bu);
  return { X, q, K, Vv, a, o, r1, u, hdn, r2, z };
}

export function letterProbs(m: LetterModel, context: string, T = 1): number[] {
  const ids = encode(m, context).slice(-CTX);
  if (!ids.length) return m.vocab.map(() => 1 / m.vocab.length);
  const { z } = letterForward(m, ids);
  const mx = Math.max(...z) / T, e = [...z].map(v => Math.exp(v / T - mx)), s = e.reduce((a, b) => a + b, 0);
  return e.map(v => v / s);
}

type Grads = { [K in keyof Omit<LetterModel, "vocab">]: Float64Array };
const zeroGrads = (m: LetterModel): Grads => ({
  E: new Float64Array(m.E.length), P: new Float64Array(m.P.length), Wq: new Float64Array(m.Wq.length), Wk: new Float64Array(m.Wk.length), Wv: new Float64Array(m.Wv.length),
  Wo: new Float64Array(m.Wo.length), W1: new Float64Array(m.W1.length), b1: new Float64Array(m.b1.length), W2: new Float64Array(m.W2.length), b2: new Float64Array(m.b2.length),
  U: new Float64Array(m.U.length), bu: new Float64Array(m.bu.length),
});

/** backprop for one window and its next letter; adds into g and returns the surprise in bits */
function letterBackward(m: LetterModel, ids: number[], target: number, g: Grads): number {
  const n = ids.length, V = m.vocab.length, last = n - 1, f = letterForward(m, ids);
  const mx = Math.max(...f.z), e = [...f.z].map(v => Math.exp(v - mx)), es = e.reduce((a, b) => a + b, 0), p = e.map(v => v / es);
  const bits = -Math.log2(Math.max(p[target]!, 1e-12));
  const dz = Float64Array.from(p, (v, i) => v - (i === target ? 1 : 0));
  outer(g.U, dz, f.r2, V, DIM); dz.forEach((v, i) => { g.bu[i]! += v; });
  const dr2 = new Float64Array(DIM); mtv(m.U, dz, V, DIM, dr2);
  // the MLP and its residual
  outer(g.W2, dr2, f.hdn, DIM, HID); dr2.forEach((v, i) => { g.b2[i]! += v; });
  const dh = new Float64Array(HID); mtv(m.W2, dr2, DIM, HID, dh);
  const du = dh.map((v, i) => (f.u[i]! > 0 ? v : 0));
  outer(g.W1, du, f.r1, HID, DIM); du.forEach((v, i) => { g.b1[i]! += v; });
  const dr1 = Float64Array.from(dr2); mtv(m.W1, du, HID, DIM, dr1);
  // attention and its residual
  const dX = f.X.map(() => new Float64Array(DIM));
  dX[last]!.set(dr1);
  outer(g.Wo, dr1, f.o, DIM, DIM);
  const dO = new Float64Array(DIM); mtv(m.Wo, dr1, DIM, DIM, dO);
  const da = f.Vv.map(v => { let d = 0; for (let j = 0; j < DIM; j++) d += dO[j]! * v[j]!; return d; });
  const dot = da.reduce((s, v, i) => s + v * f.a[i]!, 0);
  const ds = f.a.map((a, i) => (a * (da[i]! - dot)) / Math.sqrt(DIM));
  const dq = new Float64Array(DIM);
  f.K.forEach((k, i) => { for (let j = 0; j < DIM; j++) dq[j]! += ds[i]! * k[j]!; });
  outer(g.Wq, dq, f.X[last]!, DIM, DIM); mtv(m.Wq, dq, DIM, DIM, dX[last]!);
  f.X.forEach((x, i) => {
    const dk = f.q.map(v => v * ds[i]!), dv = dO.map(v => v * f.a[i]!);
    outer(g.Wk, dk, x, DIM, DIM); mtv(m.Wk, dk, DIM, DIM, dX[i]!);
    outer(g.Wv, dv, x, DIM, DIM); mtv(m.Wv, dv, DIM, DIM, dX[i]!);
  });
  ids.forEach((c, i) => { for (let k = 0; k < DIM; k++) { g.E[c * DIM + k]! += dX[i]![k]!; g.P[(CTX - n + i) * DIM + k]! += dX[i]![k]!; } });
  return bits;
}

/** the training part of a text (the first 90%) and the held-back part (the last 10%) */
export function splitText(text: string): { train: string; held: string } {
  const cut = Math.floor(text.length * 0.9);
  return { train: text.slice(0, cut), held: text.slice(cut) };
}

/** one pass of mini-batch steps over the training text, in a seeded order; returns the mean surprise in bits */
export function letterEpoch(m: LetterModel, train: string, eta: number, r: () => number, batch = 16): number {
  const ids = encode(m, train);
  const spots = Array.from({ length: Math.max(0, ids.length - 1) }, (_, i) => i + 1);
  for (let i = spots.length - 1; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [spots[i], spots[j]] = [spots[j]!, spots[i]!]; }
  let bits = 0;
  for (let s = 0; s < spots.length; s += batch) {
    const g = zeroGrads(m), part = spots.slice(s, s + batch);
    for (const t of part) bits += letterBackward(m, ids.slice(Math.max(0, t - CTX), t), ids[t]!, g);
    const k = eta / part.length;
    for (const key of Object.keys(g) as (keyof Grads)[]) { const W = m[key], G = g[key]; for (let i = 0; i < W.length; i++) W[i]! -= k * G[i]!; }
  }
  return bits / Math.max(1, spots.length);
}

/** bits per letter on a stretch of text the model never trained on (letters it never saw are skipped) */
export function bitsPerLetter(m: LetterModel, text: string, before = ""): number {
  const ids = encode(m, before + text), start = encode(m, before).length;
  let bits = 0, n = 0;
  for (let t = Math.max(1, start); t < ids.length; t++) {
    const { z } = letterForward(m, ids.slice(Math.max(0, t - CTX), t));
    const mx = Math.max(...z), e = [...z].map(v => Math.exp(v - mx)), s = e.reduce((x, y) => x + y, 0);
    bits -= Math.log2(Math.max(e[ids[t]!]! / s, 1e-12)); n++;
  }
  return n ? bits / n : 0;
}

/** for the tests: the gradient of one window's surprise, by backprop */
export function letterGrad(m: LetterModel, ids: number[], target: number) {
  const g = zeroGrads(m);
  letterBackward(m, ids, target, g);
  return g;
}

/** a sample, letter by letter, at temperature T, from a seed */
export function sample(m: LetterModel, start: string, len: number, T: number, seed: number): string {
  const r = seeded(seed);
  let out = start;
  for (let i = 0; i < len; i++) {
    const p = letterProbs(m, out.slice(-CTX), T);
    let u = r(), k = 0;
    while (k < p.length - 1 && u > p[k]!) { u -= p[k]!; k++; }
    out += m.vocab[k];
  }
  return out.slice(start.length);
}

/** A paragraph to start from, written for this machine. The learner can type or paste their own. */
export const START_TEXT =
  "the cat sat on the mat and the dog sat on the log. the cat saw the dog and the dog saw the cat. " +
  "a small cat ran to the mat, and a big dog ran to the log. the sun was out and the day was warm. " +
  "the cat sat in the sun and the dog sat in the shade. then the cat ran and the dog ran and they sat on the mat. " +
  "the end of the day was cool, so the cat and the dog sat by the fire. the cat was warm and the dog was warm. " +
  "a cat can nap all day and a dog can nap all day. the cat and the dog are good friends, and they nap on the mat.";
