// Information's maths in one place, for the lessons, the pictures and the Shrinker: surprise, entropy, Huffman codes,
// prefix decoding, a one-letter-context model and Hamming (7, 4). Nothing is rounded here.

export const log2 = (x: number) => Math.log2(x);
/** surprise of probability p in bits; an impossible event never happens, so it counts as 0 in an average */
export const surprise = (p: number) => (p > 0 ? -Math.log2(p) : 0);
/** H = Σ p log₂(1/p), with 0 · log₂(1/0) counted as 0 */
export const entropy = (ps: number[]) => ps.reduce((s, p) => s + (p > 0 ? p * -Math.log2(p) : 0), 0);
/** a coin with heads chance p */
export const h2 = (p: number) => entropy([p, 1 - p]);
/** cross-entropy H(p, q) = Σ p log₂(1/q) */
export const crossEntropy = (p: number[], q: number[]) => p.reduce((s, x, i) => s + (x > 0 ? x * -Math.log2(q[i]!) : 0), 0);
export const entropyOfCounts = (cs: number[]) => { const m = cs.reduce((a, b) => a + b, 0); return entropy(cs.map(c => c / m)); };
export const sum = (xs: number[]) => xs.reduce((a, b) => a + b, 0);

/* ---------------------------------------------------------------- Huffman ---------------------------------------------------------------- */

export interface HuffNode { w: number; leaf?: number; kids?: [HuffNode, HuffNode] }
/** one Huffman merge order (ties broken by position, lightest first): the tree, each leaf's depth, and the merged weights */
export function huffman(counts: number[]): { root: HuffNode; lengths: number[]; merges: number[]; total: number } {
  let pool: HuffNode[] = counts.map((w, i) => ({ w, leaf: i }));
  const merges: number[] = [];
  if (pool.length === 1) return { root: pool[0]!, lengths: [1], merges: [], total: counts[0]! };
  while (pool.length > 1) {
    const order = pool.map((n, i) => [n, i] as const).sort((a, b) => a[0].w - b[0].w || a[1] - b[1]);
    const [a, b] = [order[0]![0], order[1]![0]];
    const node: HuffNode = { w: a.w + b.w, kids: [a, b] };
    merges.push(node.w);
    pool = [...pool.filter(n => n !== a && n !== b), node];
  }
  const lengths = counts.map(() => 0);
  const walk = (n: HuffNode, d: number) => { if (n.leaf != null) lengths[n.leaf] = d; else n.kids!.forEach(k => walk(k, d + 1)); };
  walk(pool[0]!, 0);
  return { root: pool[0]!, lengths, merges, total: sum(merges) };
}
/** every letter's length under every tie-break Huffman allows (for counts up to 7 letters): letter → the set of lengths */
export function huffmanLengthSets(counts: number[]): Set<number>[] {
  const sets = counts.map(() => new Set<number>());
  type Item = { w: number; leaves: number[] };
  const go = (pool: Item[], depth: number[]) => {
    if (pool.length === 1) { depth.forEach((d, i) => sets[i]!.add(d)); return; }
    const ws = pool.map(p => p.w).sort((a, b) => a - b);
    const lo = ws[0]!, second = ws[1]!;
    for (let i = 0; i < pool.length; i++) for (let j = i + 1; j < pool.length; j++) {
      const a = pool[i]!, b = pool[j]!;
      const pair = [a.w, b.w].sort((x, y) => x - y);
      if (pair[0] !== lo || pair[1] !== second) continue;
      const d = [...depth];
      for (const l of [...a.leaves, ...b.leaves]) d[l]! += 1;
      go([...pool.filter((_, k) => k !== i && k !== j), { w: a.w + b.w, leaves: [...a.leaves, ...b.leaves] }], d);
    }
  };
  go(counts.map((w, i) => ({ w, leaves: [i] })), counts.map(() => 0));
  return sets;
}
/** canonical codewords from lengths (shortest first, then by position) */
export function codewords(lengths: number[]): string[] {
  const order = lengths.map((l, i) => [l, i] as const).sort((a, b) => a[0] - b[0] || a[1] - b[1]);
  const out: string[] = lengths.map(() => "");
  let code = 0, prev = order[0]?.[0] ?? 0;
  order.forEach(([l, i], k) => {
    if (k > 0) code = (code + 1) << (l - prev);
    prev = l;
    out[i] = code.toString(2).padStart(l, "0");
  });
  return out;
}
export const kraft = (lengths: number[]) => sum(lengths.map(l => 2 ** -l));
/** reads a bit string with a prefix code, left to right, stopping at the first full codeword; null where it stalls */
export function prefixDecode(bits: string, code: string[]): number[] | null {
  const out: number[] = [];
  let cur = "";
  for (const b of bits) {
    cur += b;
    const hit = code.indexOf(cur);
    if (hit >= 0) { out.push(hit); cur = ""; }
  }
  return cur ? null : out;
}
/** one codeword that is the start of another, if any: [shorter, longer] */
export function prefixClash(code: string[]): [number, number] | null {
  for (let i = 0; i < code.length; i++) for (let j = 0; j < code.length; j++)
    if (i !== j && code[i] && code[j]!.length > code[i]!.length && code[j]!.startsWith(code[i]!)) return [i, j];
  for (let i = 0; i < code.length; i++) for (let j = i + 1; j < code.length; j++) if (code[i] && code[i] === code[j]) return [i, j];
  return null;
}

/* ---------------------------------------------------------------- messages ---------------------------------------------------------------- */

/** a message's symbols, as the Shrinker counts them: letters lowercased; spaces and punctuation kept */
export const symbolsOf = (msg: string) => [...msg.toLowerCase().replace(/\s+/g, " ")];
export function letterCounts(msg: string): { sym: string[]; counts: number[] } {
  const m = new Map<string, number>();
  for (const s of symbolsOf(msg)) m.set(s, (m.get(s) ?? 0) + 1);
  const rows = [...m.entries()].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]));
  return { sym: rows.map(r => r[0]), counts: rows.map(r => r[1]) };
}
/** how a symbol is shown: a space as ␣ */
export const showSym = (s: string) => (s === " " ? "␣" : s);

/**
 * The one-letter-context model: p(next | previous) from the message's own pairs, blended with the letter counts so an
 * unseen pair never costs infinite bits. The weight on the pair counts grows with how often the previous letter came.
 */
export function contextModel(msg: string) {
  const syms = symbolsOf(msg);
  const { sym, counts } = letterCounts(msg);
  const n = syms.length, k = sym.length;
  const idx = new Map(sym.map((s, i) => [s, i]));
  const pair = sym.map(() => sym.map(() => 0));
  for (let i = 1; i < n; i++) pair[idx.get(syms[i - 1]!)!]![idx.get(syms[i]!)!]! += 1;
  const uni = counts.map(c => (c + 0.5) / (n + 0.5 * k));
  /** the model's probabilities for the next symbol, after `prev` (none: letters alone) */
  const next = (prev: string | null): number[] => {
    if (prev == null || !idx.has(prev)) return uni;
    const row = pair[idx.get(prev)!]!, m = sum(row);
    const lam = m / (m + 1);
    return uni.map((u, j) => lam * (m ? row[j]! / m : 0) + (1 - lam) * u);
  };
  /** bits the ideal coder spends on each symbol */
  const costs = (withContext: boolean) => syms.map((s, i) => surprise(next(withContext && i > 0 ? syms[i - 1]! : null)[idx.get(s)!]!));
  return { sym, counts, syms, next, costs, index: (s: string) => idx.get(s) ?? -1 };
}

/** a context model's bits per letter on another message; a letter it never saw gets the share of an unseen one */
export function crossEntropyOn(model: ReturnType<typeof contextModel>, text: string): number {
  const syms = symbolsOf(text), n = model.syms.length, k = model.sym.length;
  if (!syms.length) return 0;
  const unseen = 0.5 / (n + 0.5 * (k + 1));
  let bits = 0;
  syms.forEach((c, i) => {
    const j = model.index(c);
    const p = j < 0 ? unseen : model.next(i > 0 ? syms[i - 1]! : null)[j]!;
    bits += surprise(Math.max(unseen, p));
  });
  return bits / syms.length;
}

/** I(previous; next) for a message, from its own pairs: H(next) − H(next | previous) */
export function pairInformation(msg: string): { hNext: number; hCond: number; info: number } {
  const syms = symbolsOf(msg);
  const pairs = new Map<string, number>(), prev = new Map<string, number>(), nxt = new Map<string, number>();
  for (let i = 1; i < syms.length; i++) {
    const a = syms[i - 1]!, b = syms[i]!;
    pairs.set(a + "\u0000" + b, (pairs.get(a + "\u0000" + b) ?? 0) + 1);
    prev.set(a, (prev.get(a) ?? 0) + 1);
    nxt.set(b, (nxt.get(b) ?? 0) + 1);
  }
  const m = syms.length - 1;
  if (m < 1) return { hNext: 0, hCond: 0, info: 0 };
  const hNext = entropy([...nxt.values()].map(c => c / m));
  const hJoint = entropy([...pairs.values()].map(c => c / m));
  const hPrev = entropy([...prev.values()].map(c => c / m));
  const hCond = hJoint - hPrev;
  return { hNext, hCond, info: hNext - hCond };
}

/* ---------------------------------------------------------------- Hamming (7, 4) ---------------------------------------------------------------- */

/** positions 1 to 7; parity at 1, 2 and 4; data at 3, 5, 6, 7. Returns the 7 bits (index 0 is position 1). */
export function hammingEncode(d: number[]): number[] {
  const w = [0, 0, d[0]!, 0, d[1]!, d[2]!, d[3]!];
  for (const p of [1, 2, 4]) w[p - 1] = [3, 5, 6, 7].filter(q => q & p).reduce((x, q) => x ^ w[q - 1]!, 0);
  return w;
}
/** XOR of the positions holding a 1: 0 means no error, anything else is the flipped position */
export const syndrome = (w: number[]) => w.reduce((x, b, i) => (b ? x ^ (i + 1) : x), 0);
export const hammingData = (w: number[]) => [w[2]!, w[4]!, w[5]!, w[6]!];
/** the circles (parity checks 1, 2, 4) that hold an odd number of 1s */
export const oddCircles = (w: number[]) => [1, 2, 4].filter(p => w.reduce((x, b, i) => ((i + 1) & p ? x ^ b : x), 0) === 1);
/** triple repetition fails when 2 or 3 of the copies flip */
export const repetitionFail = (f: number) => 3 * f * f * (1 - f) + f ** 3;
/** a channel flipping each bit with chance f carries at most 1 − H(f) bits per bit */
export const capacity = (f: number) => 1 - h2(f);

/** a seeded stream for pictures that roll dice (so a picture redraws the same until the learner asks again) */
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

/** The Shrinker's pipe for a message: counts → Huffman code → bits → Hamming armor, sizes at every stage. */
export function shrink(msg: string) {
  const { sym, counts } = letterCounts(msg);
  const syms = symbolsOf(msg);
  const n = syms.length;
  const { lengths, total } = huffman(counts.length ? counts : [1]);
  const code = codewords(lengths);
  const bits = syms.map(s => code[sym.indexOf(s)]!).join("");
  const blocks = Math.ceil(bits.length / 4);
  const H = entropyOfCounts(counts.length ? counts : [1]);
  const model = contextModel(msg);
  const ctxBits = sum(model.costs(true));
  return { sym, counts, n, code, lengths, bits, huffBits: total, H, ctxBits, raw: 8 * n, armored: blocks * 7, blocks };
}
/** wraps bits in Hamming blocks (padding the last block with 0s) */
export function armor(bits: string): number[][] {
  const out: number[][] = [];
  for (let i = 0; i < bits.length; i += 4) out.push(hammingEncode([...bits.slice(i, i + 4).padEnd(4, "0")].map(Number)));
  return out;
}
/** fixes each block by its syndrome (one flip per block is repaired; two are not) */
export function unarmor(blocks: number[][], length: number): { bits: string; fixed: number } {
  let fixed = 0;
  const bits = blocks.map(b => {
    const s = syndrome(b), w = [...b];
    if (s) { w[s - 1] = 1 - w[s - 1]!; fixed++; }
    return hammingData(w).join("");
  }).join("").slice(0, length);
  return { bits, fixed };
}
