// The Digit reader's data and network (ai.md, "Digit reader"). The digits are drawn by this program: each digit is a
// few pen strokes, bent, tilted, stretched and thickened at random, then shrunk the way the UCI handwritten digits
// were made: a 32 × 32 black-and-white picture, counted in 4 × 4 blocks, so every pixel is a count from 0 to 16.
// The drawing pad goes through the same steps, so what you draw looks to the reader like what it trained on.
// Everything is seeded: a run with the same settings gives the same reader, on any device.
// No imports, so the maths can be checked on its own.

/** mulberry32, the same small generator the lessons use */
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
/** a normal draw from a uniform source */
export const gauss = (r: () => number) => Math.sqrt(-2 * Math.log(1 - r())) * Math.cos(2 * Math.PI * r());

type Pt = [number, number];
type Stroke = Pt[];
const arc = (cx: number, cy: number, rx: number, ry: number, a0: number, a1: number, n = 14): Stroke =>
  Array.from({ length: n + 1 }, (_, i) => { const a = a0 + ((a1 - a0) * i) / n; return [cx + rx * Math.cos(a), cy + ry * Math.sin(a)] as Pt; });
const D = Math.PI / 180;

/** each digit's strokes in a unit box (x right, y down); some digits have two ways of writing them */
const SHAPES: Stroke[][][] = [
  /* 0 */ [[arc(0.5, 0.5, 0.3, 0.42, -90 * D, 270 * D, 24)]],
  /* 1 */ [[[[0.5, 0.08], [0.5, 0.92]]], [[[0.32, 0.26], [0.5, 0.08], [0.5, 0.92]]]],
  /* 2 */ [[[...arc(0.5, 0.32, 0.26, 0.22, 200 * D, 360 * D, 10), [0.7, 0.5], [0.24, 0.9], [0.8, 0.9]]]],
  /* 3 */ [[[...arc(0.48, 0.3, 0.24, 0.2, 200 * D, 450 * D, 12), ...arc(0.48, 0.7, 0.27, 0.21, -90 * D, 160 * D, 12)]]],
  /* 4 */ [[[[0.62, 0.92], [0.62, 0.08], [0.18, 0.64], [0.84, 0.64]]], [[[0.3, 0.08], [0.22, 0.56], [0.8, 0.56]], [[0.64, 0.3], [0.64, 0.92]]]],
  /* 5 */ [[[[0.76, 0.1], [0.32, 0.1], [0.28, 0.46], ...arc(0.48, 0.66, 0.28, 0.24, -110 * D, 150 * D, 12)]]],
  /* 6 */ [[[[0.7, 0.1], [0.45, 0.28], ...arc(0.5, 0.68, 0.24, 0.22, 200 * D, 560 * D, 18)]]],
  /* 7 */ [[[[0.18, 0.1], [0.82, 0.1], [0.42, 0.92]]], [[[0.18, 0.1], [0.82, 0.1], [0.42, 0.92]], [[0.34, 0.5], [0.72, 0.5]]]],
  /* 8 */ [[[...arc(0.5, 0.29, 0.2, 0.19, 90 * D, 450 * D, 16), ...arc(0.5, 0.7, 0.25, 0.21, -90 * D, 270 * D, 18)]]],
  /* 9 */ [[[...arc(0.48, 0.32, 0.22, 0.21, 0, 360 * D, 18), [0.7, 0.32], [0.64, 0.92]]], [[...arc(0.48, 0.32, 0.22, 0.21, 0, 360 * D, 18), [0.7, 0.32], [0.7, 0.92]]]],
];

const SIDE = 32, BLOCK = 4, PIX = 8;

/** strokes fitted into the box the way the dataset does it: the longer side fills 26 of 32 dots, centered */
export function normalize(strokes: Stroke[]): Stroke[] {
  const all = strokes.flat();
  if (!all.length) return strokes;
  let x0 = Infinity, x1 = -Infinity, y0 = Infinity, y1 = -Infinity;
  for (const [x, y] of all) { x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); }
  const s = 0.8 / Math.max(x1 - x0, y1 - y0, 0.05), cx = (x0 + x1) / 2, cy = (y0 + y1) / 2;
  return strokes.map(st => st.map(([x, y]) => [0.5 + (x - cx) * s, 0.5 + (y - cy) * s] as Pt));
}

/** the 32 × 32 picture, counted in 4 × 4 blocks: 64 counts from 0 to 16 */
export function rasterize(strokes: Stroke[], width: number): Uint8Array {
  const bits = new Uint8Array(SIDE * SIDE);
  const r = (width * SIDE) / 2, r2 = r * r;
  for (const st of strokes) {
    const pts = st.length === 1 ? [st[0]!, st[0]!] : st;
    for (let k = 0; k + 1 < pts.length; k++) {
      const ax = pts[k]![0] * SIDE, ay = pts[k]![1] * SIDE, bx = pts[k + 1]![0] * SIDE, by = pts[k + 1]![1] * SIDE;
      const dx = bx - ax, dy = by - ay, L = dx * dx + dy * dy;
      const i0 = Math.max(0, Math.floor(Math.min(ax, bx) - r)), i1 = Math.min(SIDE - 1, Math.ceil(Math.max(ax, bx) + r));
      const j0 = Math.max(0, Math.floor(Math.min(ay, by) - r)), j1 = Math.min(SIDE - 1, Math.ceil(Math.max(ay, by) + r));
      for (let j = j0; j <= j1; j++) for (let i = i0; i <= i1; i++) {
        const px = i + 0.5, py = j + 0.5;
        const t = L ? Math.max(0, Math.min(1, ((px - ax) * dx + (py - ay) * dy) / L)) : 0;
        const ex = ax + t * dx - px, ey = ay + t * dy - py;
        if (ex * ex + ey * ey <= r2) bits[j * SIDE + i] = 1;
      }
    }
  }
  const out = new Uint8Array(PIX * PIX);
  for (let j = 0; j < SIDE; j++) for (let i = 0; i < SIDE; i++) if (bits[j * SIDE + i]) out[((j / BLOCK) | 0) * PIX + ((i / BLOCK) | 0)]!++;
  return out;
}

/** the pen's width on the pad, as a share of the box (the dataset's pens vary around it) */
export const PAD_PEN = 0.11;

/** one digit, drawn by the program with its own wobble, tilt, slant, stretch and pen */
export function drawDigit(d: number, r: () => number): Uint8Array {
  const ways = SHAPES[d]!;
  const way = ways[Math.floor(r() * ways.length)]!;
  const rot = gauss(r) * 12 * D, shear = gauss(r) * 0.22, sx = 0.75 + r() * 0.4, sy = 0.8 + r() * 0.35, wob = 0.04 + r() * 0.05;
  const c = Math.cos(rot), s = Math.sin(rot);
  // a smooth wobble: each stroke point moves with its neighbours
  const strokes = way.map(st => {
    let ox = gauss(r) * wob, oy = gauss(r) * wob;
    return st.map(([x, y]) => {
      ox = 0.8 * ox + 0.45 * gauss(r) * wob; oy = 0.8 * oy + 0.45 * gauss(r) * wob;
      const u = (x - 0.5) * sx + ox, v = (y - 0.5) * sy + oy;
      const uu = u + shear * v;
      return [0.5 + c * uu - s * v, 0.5 + s * uu + c * v] as Pt;
    });
  });
  // sometimes the pen skips: a short gap in one stroke
  if (r() < 0.2) {
    const st = strokes[Math.floor(r() * strokes.length)]!;
    if (st.length > 6) { const at = 2 + Math.floor(r() * (st.length - 5)); strokes.push(st.splice(at)); st.push(strokes[strokes.length - 1]![0]!); strokes[strokes.length - 1]!.shift(); }
  }
  const fitted = normalize(strokes);
  const jx = gauss(r) * 0.03, jy = gauss(r) * 0.03;
  return rasterize(fitted.map(st => st.map(([x, y]) => [x + jx, y + jy] as Pt)), PAD_PEN * (0.55 + r() * 0.9));
}

export interface DigitSet { x: Float64Array[]; y: number[] }

/** The bundled set, as the UCI set is split: 3,823 training digits and 1,797 held back for testing. */
export const TRAIN_N = 3823, TEST_N = 1797;
let cache: { train: DigitSet; test: DigitSet } | null = null;
export function digitData(): { train: DigitSet; test: DigitSet } {
  if (cache) return cache;
  const make = (n: number, seed: number): DigitSet => {
    const r = seeded(seed), x: Float64Array[] = [], y: number[] = [];
    for (let i = 0; i < n; i++) {
      const d = i % 10;
      const counts = drawDigit(d, r);
      x.push(Float64Array.from(counts, c => c / 16));
      y.push(d);
    }
    // shuffle so a small first slice still has every digit, in no order
    for (let i = n - 1; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [x[i], x[j]] = [x[j]!, x[i]!]; [y[i], y[j]] = [y[j]!, y[i]!]; }
    return { x, y };
  };
  cache = { train: make(TRAIN_N, 8080), test: make(TEST_N, 9090) };
  return cache;
}

/* ---------------------------------------------------------------- the network: 64 → h → 10 ---------------------------------------------------------------- */

export interface Reader { h: number; W1: Float64Array; b1: Float64Array; W2: Float64Array; b2: Float64Array; patches?: PatchParts }
/** the patch upgrade's own numbers (unit 4): queries and keys for the 16 patches */
export interface PatchParts { Wq: Float64Array; Wk: Float64Array; pos: Float64Array }

export const readerParams = (h: number) => 64 * h + h + h * 10 + 10;

export function newReader(h: number, seed = 1): Reader {
  const r = seeded(seed);
  const W1 = Float64Array.from({ length: h * 64 }, () => gauss(r) * Math.sqrt(2 / 64));
  const W2 = Float64Array.from({ length: 10 * h }, () => gauss(r) * Math.sqrt(1 / h));
  return { h, W1, b1: new Float64Array(h), W2, b2: new Float64Array(10) };
}

/** the hidden layer and the 10 chances for one picture (64 numbers from 0 to 1) */
export function forward(net: Reader, x: Float64Array, T = 1) {
  const { h, W1, b1, W2, b2 } = net;
  const a = new Float64Array(h), z = new Float64Array(10);
  for (let j = 0; j < h; j++) { let s = b1[j]!; const o = j * 64; for (let i = 0; i < 64; i++) s += W1[o + i]! * x[i]!; a[j] = s > 0 ? s : 0; }
  for (let k = 0; k < 10; k++) { let s = b2[k]!; const o = k * h; for (let j = 0; j < h; j++) s += W2[o + j]! * a[j]!; z[k] = s; }
  return { a, z, p: softmaxT(z, T) };
}

export function softmaxT(z: ArrayLike<number>, T = 1): Float64Array {
  let m = -Infinity;
  for (let i = 0; i < z.length; i++) m = Math.max(m, z[i]! / T);
  const p = new Float64Array(z.length);
  let s = 0;
  for (let i = 0; i < z.length; i++) { p[i] = Math.exp(z[i]! / T - m); s += p[i]!; }
  for (let i = 0; i < z.length; i++) p[i] = p[i]! / s;
  return p;
}

/** one step of mini-batch gradient descent on the cross-entropy, for the pictures at `idx` */
export function sgdStep(net: Reader, X: Float64Array[], Y: number[], idx: number[], eta: number) {
  const { h, W1, b1, W2, b2 } = net;
  const gW1 = new Float64Array(W1.length), gb1 = new Float64Array(h), gW2 = new Float64Array(W2.length), gb2 = new Float64Array(10);
  const da = new Float64Array(h);
  for (const n of idx) {
    const x = X[n]!, { a, p } = forward(net, x);
    p[Y[n]!] = p[Y[n]!]! - 1;
    da.fill(0);
    for (let k = 0; k < 10; k++) {
      const g = p[k]!, o = k * h;
      gb2[k]! += g;
      for (let j = 0; j < h; j++) { gW2[o + j]! += g * a[j]!; da[j]! += g * W2[o + j]!; }
    }
    for (let j = 0; j < h; j++) {
      if (a[j]! <= 0) continue;
      const g = da[j]!, o = j * 64;
      gb1[j]! += g;
      for (let i = 0; i < 64; i++) gW1[o + i]! += g * x[i]!;
    }
  }
  const k = eta / idx.length;
  for (let i = 0; i < W1.length; i++) W1[i]! -= k * gW1[i]!;
  for (let i = 0; i < h; i++) b1[i]! -= k * gb1[i]!;
  for (let i = 0; i < W2.length; i++) W2[i]! -= k * gW2[i]!;
  for (let i = 0; i < 10; i++) b2[i]! -= k * gb2[i]!;
}

/** error rate (wrong answers over all) and mean cross-entropy in bits, on a set (or its first `limit` pictures) */
export function evaluate(net: Reader, set: DigitSet, limit = set.y.length) {
  let wrong = 0, bits = 0;
  const n = Math.min(limit, set.y.length);
  for (let i = 0; i < n; i++) {
    const { p } = forward(net, set.x[i]!);
    let best = 0;
    for (let k = 1; k < 10; k++) if (p[k]! > p[best]!) best = k;
    if (best !== set.y[i]) wrong++;
    bits -= Math.log2(Math.max(p[set.y[i]!]!, 1e-12));
  }
  return { error: wrong / n, bits: bits / n };
}

export interface TrainPlan { n: number; h: number; epochs: number; batch: number; eta: number; seed: number }
/** the build's default run: h = 16, batches of 20, η = 0.1, 20 passes over the training set */
export const DEFAULT_PLAN: TrainPlan = { n: 3000, h: 16, epochs: 20, batch: 20, eta: 0.1, seed: 7 };
/** the overfitting preset (09): 100 training digits, a large hidden layer, many passes */
export const OVERFIT_PLAN: TrainPlan = { n: 100, h: 64, epochs: 300, batch: 10, eta: 0.3, seed: 7 };

/** The shuffled batches of a run, from its seed: the same plan always sees the same order. */
export function* trainRun(plan: TrainPlan, data = digitData()) {
  const net = newReader(plan.h, plan.seed);
  const r = seeded(plan.seed * 31 + plan.n);
  const N = Math.min(plan.n, data.train.y.length);
  const order = Array.from({ length: N }, (_, i) => i);
  for (let e = 0; e < plan.epochs; e++) {
    for (let i = N - 1; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [order[i], order[j]] = [order[j]!, order[i]!]; }
    for (let s = 0; s < N; s += plan.batch) sgdStep(net, data.train.x, data.train.y, order.slice(s, s + plan.batch), plan.eta);
    yield { epoch: e + 1, net };
  }
  return net;
}

/** a whole run at once */
export function trainReader(plan: TrainPlan = DEFAULT_PLAN, data = digitData()): Reader {
  let net = newReader(plan.h, plan.seed);
  for (const s of trainRun(plan, data)) net = s.net;
  return net;
}

/** a run with the same plan is the same reader: keep the finished ones */
const runs = new Map<string, Reader>();
export const planKey = (p: TrainPlan) => `${p.n}/${p.h}/${p.epochs}/${p.batch}/${p.eta}/${p.seed}`;
export function cachedReader(plan: TrainPlan): Reader {
  const k = planKey(plan);
  let net = runs.get(k);
  if (!net) { net = trainReader(plan); runs.set(k, net); }
  return net;
}
export const keepReader = (plan: TrainPlan, net: Reader) => runs.set(planKey(plan), net);
export const hasReader = (plan: TrainPlan) => runs.has(planKey(plan));

/** the 10 × 10 grid: rows are the true digit, columns what the reader said */
export function confusion(net: Reader, set: DigitSet): number[][] {
  const G = Array.from({ length: 10 }, () => new Array<number>(10).fill(0));
  for (let i = 0; i < set.y.length; i++) {
    const { p } = forward(net, set.x[i]!);
    let best = 0;
    for (let k = 1; k < 10; k++) if (p[k]! > p[best]!) best = k;
    G[set.y[i]!]![best]!++;
  }
  return G;
}

/** "what did it look at": the gradient of digit k's score with respect to each of the 64 pixels */
export function pixelMap(net: Reader, x: Float64Array, k: number): Float64Array {
  const { h, W1, W2 } = net;
  const { a } = forward(net, x);
  const g = new Float64Array(64);
  for (let j = 0; j < h; j++) {
    if (a[j]! <= 0) continue;
    const w = W2[k * h + j]!, o = j * 64;
    for (let i = 0; i < 64; i++) g[i]! += w * W1[o + i]!;
  }
  return g;
}

/** the top answer and its chance for each held-back picture, at temperature T (for the reliability diagram) */
export function predictions(net: Reader, set: DigitSet, T = 1) {
  return set.y.map((y, i) => {
    const { z } = forward(net, set.x[i]!);
    const p = softmaxT(z, T);
    let best = 0;
    for (let k = 1; k < 10; k++) if (p[k]! > p[best]!) best = k;
    return { conf: p[best]!, right: best === y, pTrue: p[y]! };
  });
}

/** The scaling run (13): the same reader on growing slices of the training set, the same number of steps each. */
export const SCALING_SIZES = [100, 300, 1000, 3000];
export const scalingPlan = (n: number): TrainPlan => ({ ...DEFAULT_PLAN, n, epochs: Math.max(20, Math.round((3000 * 20) / n)) });

/**
 * What the seeded runs give, written down so a guess can be recorded without training first. The tests rerun the
 * training and check these: the held-out error at each scaling size, and the top confidence bin (0.9 and up) of the
 * default reader, as [pictures in it, right ones].
 */
export const SCALING_ERR = [0.24373956594323873, 0.12632164718976072, 0.08848080133555926, 0.06956037840845854];
export const TOP_BIN: [number, number] = [1401, 1382];
