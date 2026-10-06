// The math behind AI: the track's own maths, in one place, for the pictures, the lessons and the tests. The digit
// reader lives in digits.ts and the next-letter model in letters.ts.
import { coef, signed } from "../../../curriculum/text";
import { seeded, gauss } from "./digits";

/** "y = x + 1", "y = −2x", "y = 3": a line written with no coefficient of 1 and no "+ −" */
export function lineText(w: number, b: number, y = "y", x = "x"): string {
  if (w === 0) return `${y} = ${num(b)}`;
  return `${y} = ${coef(w, x)}${b === 0 ? "" : ` ${signed(b)}`}`;
}
/** a number with a real minus sign */
export const num = (x: number) => (x < 0 ? `−${Math.abs(x)}` : String(x));
/** "(−1)" after an operator, plain otherwise */
export const par = (x: number) => (x < 0 ? `(−${Math.abs(x)})` : String(x));

export const sigmoid = (z: number) => 1 / (1 + Math.exp(-z));
export const round2 = (x: number) => Math.round(x * 100) / 100;
export const log2 = (x: number) => Math.log(x) / Math.LN2;

export function softmax(z: number[], T = 1): number[] {
  const m = Math.max(...z.map(v => v / T));
  const e = z.map(v => Math.exp(v / T - m));
  const s = e.reduce((a, b) => a + b, 0);
  return e.map(v => v / s);
}

/** mean squared error of the line y = wx + b on points */
export const mseOf = (pts: [number, number][], w: number, b: number) => pts.reduce((s, [x, y]) => s + (y - (w * x + b)) ** 2, 0) / pts.length;
/** one gradient step on (w, b) for the mean squared error */
export function lineStep(pts: [number, number][], w: number, b: number, eta: number): [number, number] {
  const n = pts.length;
  let gw = 0, gb = 0;
  for (const [x, y] of pts) { const r = w * x + b - y; gw += (2 / n) * r * x; gb += (2 / n) * r; }
  return [w - eta * gw, b - eta * gb];
}
/** the least-squares line (the bottom of the bowl) */
export function bestLine(pts: [number, number][]): [number, number] {
  const n = pts.length, sx = pts.reduce((s, p) => s + p[0], 0), sy = pts.reduce((s, p) => s + p[1], 0);
  const sxx = pts.reduce((s, p) => s + p[0] * p[0], 0), sxy = pts.reduce((s, p) => s + p[0] * p[1], 0);
  const d = n * sxx - sx * sx;
  if (Math.abs(d) < 1e-9) return [0, sy / n];
  const w = (n * sxy - sx * sy) / d;
  return [w, (sy - w * sx) / n];
}
/** the biggest η that still settles for the line's loss: 2 over its steepest curvature */
export function etaLimit(pts: [number, number][]): number {
  // Hessian of MSE in (w, b): (2/n)[[Σx², Σx], [Σx, n]]
  const n = pts.length, sx = pts.reduce((s, p) => s + p[0], 0), sxx = pts.reduce((s, p) => s + p[0] * p[0], 0);
  const a = (2 / n) * sxx, c = 2, b = (2 / n) * sx;
  const lmax = (a + c) / 2 + Math.sqrt(((a - c) / 2) ** 2 + b * b);
  return 2 / lmax;
}

/* -------------------------------------------- the Tiny neural network: 2 inputs → hidden layers → 2 chances -------------------------------------------- */

export type Act = "relu" | "sigmoid";
export interface Mlp { sizes: number[]; W: Float64Array[]; b: Float64Array[]; act: Act }

export function newMlp(sizes: number[], act: Act, seed: number): Mlp {
  const r = seeded(seed);
  const W = sizes.slice(1).map((m, l) => Float64Array.from({ length: m * sizes[l]! }, () => gauss(r) * Math.sqrt(2 / sizes[l]!)));
  const b = sizes.slice(1).map(m => new Float64Array(m));
  return { sizes, W, b, act };
}
const actF = (a: Act, z: number) => (a === "relu" ? (z > 0 ? z : 0) : 1 / (1 + Math.exp(-z)));
const actD = (a: Act, z: number, out: number) => (a === "relu" ? (z > 0 ? 1 : 0) : out * (1 - out));

/** every layer's sums and outputs; the last layer is softmax */
export function mlpForward(net: Mlp, x: number[]) {
  const zs: Float64Array[] = [], outs: Float64Array[] = [Float64Array.from(x)];
  for (let l = 0; l < net.W.length; l++) {
    const n = net.sizes[l]!, m = net.sizes[l + 1]!, prev = outs[l]!, z = new Float64Array(m);
    for (let j = 0; j < m; j++) { let s = net.b[l]![j]!; for (let i = 0; i < n; i++) s += net.W[l]![j * n + i]! * prev[i]!; z[j] = s; }
    zs.push(z);
    const last = l === net.W.length - 1;
    outs.push(last ? Float64Array.from(softmax([...z])) : z.map(v => actF(net.act, v)));
  }
  return { zs, outs };
}
export const mlpProb = (net: Mlp, x: number[]) => mlpForward(net, x).outs.at(-1)![1]!;

/** one full-batch gradient step on the cross-entropy; returns the loss in bits before the step */
export function mlpStep(net: Mlp, X: number[][], Y: number[], eta: number): number {
  const gW = net.W.map(w => new Float64Array(w.length)), gb = net.b.map(b => new Float64Array(b.length));
  let loss = 0;
  for (let k = 0; k < X.length; k++) {
    const { zs, outs } = mlpForward(net, X[k]!);
    const p = outs.at(-1)!;
    loss -= Math.log2(Math.max(p[Y[k]!]!, 1e-12));
    let d = Float64Array.from(p, (v, i) => v - (i === Y[k] ? 1 : 0));
    for (let l = net.W.length - 1; l >= 0; l--) {
      const n = net.sizes[l]!, m = net.sizes[l + 1]!, prev = outs[l]!;
      const back = new Float64Array(n);
      for (let j = 0; j < m; j++) {
        gb[l]![j]! += d[j]!;
        for (let i = 0; i < n; i++) { gW[l]![j * n + i]! += d[j]! * prev[i]!; back[i]! += d[j]! * net.W[l]![j * n + i]!; }
      }
      if (l > 0) d = back.map((v, i) => v * actD(net.act, zs[l - 1]![i]!, outs[l]![i]!));
    }
  }
  const k = eta / Math.max(1, X.length);
  net.W.forEach((w, l) => w.forEach((_, i) => { w[i]! -= k * gW[l]![i]!; }));
  net.b.forEach((b, l) => b.forEach((_, i) => { b[i]! -= k * gb[l]![i]!; }));
  return loss / Math.max(1, X.length);
}
export const mlpParams = (sizes: number[]) => sizes.slice(1).reduce((s, m, l) => s + m * sizes[l]! + m, 0);
export const mlpFlat = (net: Mlp) => [...net.W.flatMap((w, l) => [...w, ...net.b[l]!])];

/** dot patterns for the two-color splitter, in a box from −1 to 1; color 1 is orange */
export type Pattern = "xor" | "rings" | "stripes" | "blobs";
export function patternDots(kind: Pattern, seed = 3, n = 60): { x: number; y: number; c: number }[] {
  const r = seeded(seed), out: { x: number; y: number; c: number }[] = [];
  for (let i = 0; i < n; i++) {
    const x = r() * 1.8 - 0.9, y = r() * 1.8 - 0.9;
    const c = kind === "xor" ? Number(x * y < 0) : kind === "rings" ? Number(Math.hypot(x, y) > 0.55) : kind === "stripes" ? Number(Math.floor((x + y + 3) * 1.4) % 2 === 1) : Number(x + 0.4 * y > 0.1);
    out.push({ x, y, c });
  }
  return out;
}

/* ------------------------------------------------------------- the Goal sandbox (15) ------------------------------------------------------------- */

/**
 * A 5 × 5 room with dirt on 12 tiles and a rug in one corner. A plan is 24 actions: move, vacuum (the dirt goes in the
 * bin), sweep the tile's dirt under the rug (from next to it), or turn the camera to the wall. The camera reports a tile
 * clean when it sees no dirt on it, and dirt under the rug can't be seen.
 */
export const ROOM = 5, PLAN_LEN = 24, RUG = 0;
export const DIRT0 = [2, 3, 6, 7, 9, 11, 13, 15, 17, 19, 21, 23];
export type Action = "N" | "S" | "E" | "W" | "vac" | "rug" | "wall";
export interface RewardParts { seen: boolean; bin: boolean; turn: boolean; rug: boolean }
export const DEFAULT_REWARD: RewardParts = { seen: true, bin: false, turn: false, rug: false };
export const BIN_REWARD: RewardParts = { seen: false, bin: true, turn: false, rug: false };

export interface PlanResult { actions: Action[]; path: number[]; dirt: number[]; underRug: number; bin: number; wall: boolean }

export function randomPlan(r: () => number): Action[] {
  const a: Action[] = [];
  for (let i = 0; i < PLAN_LEN; i++) {
    const u = r();
    a.push(u < 0.00008 ? "wall" : u < 0.24 ? "vac" : u < 0.3 ? "rug" : (["N", "S", "E", "W"] as const)[Math.floor(r() * 4)]!);
  }
  return a;
}
export function runPlan(actions: Action[]): PlanResult {
  let at = 12, underRug = 0, bin = 0, wall = false;
  const dirt = new Array<number>(ROOM * ROOM).fill(0);
  for (const d of DIRT0) dirt[d] = 1;
  const path = [at];
  for (const a of actions) {
    const x = at % ROOM, y = Math.floor(at / ROOM);
    if (a === "N" && y > 0) at -= ROOM; else if (a === "S" && y < ROOM - 1) at += ROOM; else if (a === "E" && x < ROOM - 1) at += 1; else if (a === "W" && x > 0) at -= 1;
    else if (a === "vac" && dirt[at]) { bin += dirt[at]!; dirt[at] = 0; }
    else if (a === "rug" && dirt[at] && at !== RUG && (at === 1 || at === ROOM || at === ROOM + 1)) { underRug += dirt[at]!; dirt[at] = 0; }
    else if (a === "wall") wall = true;
    path.push(at);
  }
  return { actions, path, dirt, underRug, bin, wall };
}
/** what the reward parts add up to for a plan's end state */
export function rewardOf(p: PlanResult, parts: RewardParts): number {
  const seenClean = p.wall ? ROOM * ROOM : p.dirt.filter(d => !d).length;
  return (parts.seen ? seenClean : 0) + (parts.bin ? 3 * p.bin : 0) - (parts.turn && p.wall ? 30 : 0) - (parts.rug ? 5 * p.underRug : 0);
}
/** the true goal: the share of the room actually clean (dirt under the rug still counts as dirt) */
export const trueClean = (p: PlanResult) => (ROOM * ROOM - p.dirt.filter(Boolean).length - (p.underRug ? 1 : 0)) / (ROOM * ROOM);

/** the optimizer: try n plans, keep the best reward (the first one on a tie) */
export function bestOf(plans: PlanResult[], n: number, parts: RewardParts): PlanResult {
  let best = plans[0]!, bestR = rewardOf(best, parts);
  for (let i = 1; i < Math.min(n, plans.length); i++) { const r = rewardOf(plans[i]!, parts); if (r > bestR) { best = plans[i]!; bestR = r; } }
  return best;
}
export const OPT_STEPS = [1, 3, 10, 30, 100, 300, 1000, 3000, 10000];
/** the two meters' averages over many rooms, for each optimizer strength */
export function sweep(parts: RewardParts, runs = 12, seed = 5) {
  const out = OPT_STEPS.map(n => ({ n, reward: 0, clean: 0 }));
  for (let k = 0; k < runs; k++) {
    const r = seeded(seed + k * 101);
    const plans = Array.from({ length: OPT_STEPS.at(-1)! }, () => runPlan(randomPlan(r)));
    OPT_STEPS.forEach((n, i) => { const b = bestOf(plans, n, parts); out[i]!.reward += rewardOf(b, parts) / runs; out[i]!.clean += trueClean(b) / runs; });
  }
  return out;
}
let planCache: { seed: number; plans: PlanResult[] } | null = null;
/** one room's plans, the ones the picture plays */
export function roomPlans(seed: number): PlanResult[] {
  if (planCache?.seed === seed) return planCache.plans;
  const r = seeded(seed);
  planCache = { seed, plans: Array.from({ length: OPT_STEPS.at(-1)! }, () => runPlan(randomPlan(r))) };
  return planCache.plans;
}

/* ---------------------------------------------------------------- Word arrows (10) ---------------------------------------------------------------- */

/**
 * A small hand-made word map in 2D. It is laid out the way real word vectors behave (similar words point the same
 * way; some relations are near-constant offsets), but it is not projected from real vectors, and the picture says so.
 */
export const WORDS: [string, number, number][] = [
  ["lion", 8.00, 0.28],
  ["tiger", 8.35, 0.88],
  ["cat", 6.66, 2.16],
  ["kitten", 5.60, 2.15],
  ["mouse", 5.39, 3.63],
  ["dog", 5.00, 5.18],
  ["puppy", 4.07, 4.68],
  ["fox", 3.50, 6.06],
  ["horse", 2.47, 7.61],
  ["cow", 1.32, 7.48],
  ["man", -2.25, 5.56],
  ["boy", -1.21, 4.85],
  ["woman", -3.85, 5.96],
  ["king", -1.65, 8.16],
  ["queen", -3.10, 8.36],
  ["girl", -2.81, 5.25],
  ["prince", -0.31, 7.15],
  ["princess", -1.91, 7.85],
  ["uncle", -2.65, 6.76],
  ["aunt", -4.25, 7.16],
  ["france", -7.00, 0.24],
  ["italy", -7.24, -1.54],
  ["japan", -6.29, -3.07],
  ["germany", -7.43, 1.58],
  ["spain", -6.36, -0.67],
  ["paris", -7.30, -1.66],
  ["rome", -7.74, -3.34],
  ["berlin", -7.83, -0.22],
  ["madrid", -6.66, -2.67],
  ["tokyo", -8.29, -3.47],
  ["car", -0.97, -6.93],
  ["truck", -0.27, -7.80],
  ["bus", -1.79, -7.18],
  ["train", -3.00, -7.42],
  ["bike", 0.67, -6.36],
  ["plane", -4.30, -7.45],
  ["walk", 3.20, -5.54],
  ["swim", 4.68, -5.20],
  ["run", 5.04, -3.94],
  ["eat", 6.29, -3.07],
  ["walked", 4.20, -4.44],
  ["swam", 5.68, -4.20],
  ["ran", 6.14, -2.84],
  ["ate", 4.29, -3.67],
  ["apple", 7.52, -2.74],
  ["bread", 6.40, -1.60],
  ["cheese", 7.48, -1.32],
  ["milk", 8.37, -0.73],
  ["rice", 6.89, -2.11],
  ["tea", 6.40, -0.22],
];
export const wordVec = (w: string): [number, number] => { const e = WORDS.find(x => x[0] === w)!; return [e[1], e[2]]; };
export const cosine = (u: number[], v: number[]) => (u[0]! * v[0]! + u[1]! * v[1]!) / (Math.hypot(u[0]!, u[1]!) * Math.hypot(v[0]!, v[1]!));
/** the nearest word to a point by cosine, leaving out some words */
export function nearestWord(p: [number, number], skip: string[] = []): string {
  let best = "", bc = -2;
  for (const [w, x, y] of WORDS) { if (skip.includes(w)) continue; const c = cosine(p, [x, y]); if (c > bc) { bc = c; best = w; } }
  return best;
}

/* ---------------------------------------------------------------- Attention (11) ---------------------------------------------------------------- */

/** a toy sentence with hand-set 2D queries, keys and values, so the pattern can be read off the arrows */
export const SENTENCE = ["the", "cat", "sat", "because", "it", "was", "tired"];
export const QUERIES: [number, number][] = [[0.9, 0.2], [0.1, 1.2], [-0.8, 0.3], [0.6, -1.0], [1.6, 0.9], [0.8, -1.1], [0.6, 1.3]];
export const KEYS: [number, number][] = [[0.1, -0.3], [1.6, 0.4], [0.2, 1.4], [-0.9, -0.2], [0.9, -0.8], [-0.4, 0.6], [-0.6, 1.2]];
export function attentionRow(q: [number, number], upto = KEYS.length, d = 2): number[] {
  const s = KEYS.map((k, i) => (i < upto ? (q[0] * k[0] + q[1] * k[1]) / Math.sqrt(d) : -Infinity));
  const m = Math.max(...s.filter(Number.isFinite));
  const e = s.map(v => (Number.isFinite(v) ? Math.exp(v - m) : 0));
  const t = e.reduce((a, b) => a + b, 0);
  return e.map(v => v / t);
}

/* ---------------------------------------------------------------- calibration (16) ---------------------------------------------------------------- */

export interface Bin { lo: number; hi: number; n: number; conf: number; acc: number }
/** predictions sorted into confidence bins of width `w` (from 0.1 up), with each bin's mean confidence and accuracy */
export function reliability(preds: { conf: number; right: boolean }[], w = 0.1): { bins: Bin[]; ece: number } {
  const nb = Math.round(1 / w), bins: Bin[] = Array.from({ length: nb }, (_, i) => ({ lo: i * w, hi: (i + 1) * w, n: 0, conf: 0, acc: 0 }));
  for (const p of preds) { const b = bins[Math.min(nb - 1, Math.floor(p.conf / w))]!; b.n++; b.conf += p.conf; b.acc += p.right ? 1 : 0; }
  let ece = 0;
  for (const b of bins) if (b.n) { b.conf /= b.n; b.acc /= b.n; ece += (b.n / preds.length) * Math.abs(b.acc - b.conf); }
  return { bins, ece };
}
/** the temperature that makes the held-out log loss smallest (a coarse search, then a fine one) */
export function fitTemperature(logits: { z: ArrayLike<number>; y: number }[]): number {
  const nll = (T: number) => logits.reduce((s, { z, y }) => { const p = softmax(Array.from(z), T); return s - Math.log(Math.max(p[y]!, 1e-12)); }, 0);
  let best = 1, bv = nll(1);
  for (let T = 0.3; T <= 4.001; T += 0.1) { const v = nll(T); if (v < bv) { bv = v; best = T; } }
  for (let T = best - 0.1; T <= best + 0.1001; T += 0.01) { const v = nll(T); if (v < bv) { bv = v; best = T; } }
  return Math.round(best * 100) / 100;
}

/* ---------------------------------------------------------------- scaling (13) ---------------------------------------------------------------- */

/** the least-squares line through (log10 x, log10 y): slope and intercept */
export function logFit(pts: [number, number][]): [number, number] {
  const L = pts.filter(([x, y]) => x > 0 && y > 0).map(([x, y]) => [Math.log10(x), Math.log10(y)] as [number, number]);
  return bestLine(L);
}

/** C = 6ND in scientific notation: [the number in front, rounded to 1 place, and the power of ten] */
export function sci(x: number): [number, number] {
  let e = Math.floor(Math.log10(x));
  let m = Math.round((x / 10 ** e) * 10) / 10;
  if (m >= 10) { m /= 10; e++; }
  return [m, e];
}
const SUP: Record<string, string> = { "-": "⁻", "−": "⁻", "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹" };
/** "10⁸" */
export const ten = (e: number) => `10${String(e).replace(/./g, d => SUP[d] ?? d)}`;
/** "1.2 × 10¹⁸", or "10⁸" when the number in front is 1 */
export const sciText = (m: number, e: number) => (m === 1 ? ten(e) : `${String(m)} × ${ten(e)}`);
