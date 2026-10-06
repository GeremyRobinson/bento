// Computation's maths in one place: a little logic language (parse, print, evaluate), gate circuits, the searches and
// sorts the Algorithm stage runs, shortest paths, tours, subset sums, Turing machines and the shift-and-add chip.

/* ---------------------------------------------------------------- logic ---------------------------------------------------------------- */

export type Op = "and" | "or" | "xor" | "imp";
export type Ex = { k: "var"; n: string } | { k: "not"; a: Ex } | { k: Op; a: Ex; b: Ex };
export const V = (n: string): Ex => ({ k: "var", n });
export const Not = (a: Ex): Ex => ({ k: "not", a });
export const And = (a: Ex, b: Ex): Ex => ({ k: "and", a, b });
export const Or = (a: Ex, b: Ex): Ex => ({ k: "or", a, b });
export const Xor = (a: Ex, b: Ex): Ex => ({ k: "xor", a, b });
export const Imp = (a: Ex, b: Ex): Ex => ({ k: "imp", a, b });

const SYM: Record<Op, string> = { and: "∧", or: "∨", xor: "⊕", imp: "→" };
/** prints with as few parentheses as reads unambiguously (always around a mixed inner connective) */
export function show(e: Ex): string {
  if (e.k === "var") return e.n;
  if (e.k === "not") return `¬${e.a.k === "var" || e.a.k === "not" ? show(e.a) : `(${show(e.a)})`}`;
  const side = (x: Ex) => (x.k === "var" || x.k === "not" || (x.k === e.k && e.k !== "imp") ? show(x) : `(${show(x)})`);
  return `${side(e.a)} ${SYM[e.k]} ${side(e.b)}`;
}
export interface EvalOpts { orAsXor?: boolean }
export function evaluate(e: Ex, env: Record<string, boolean>, o: EvalOpts = {}): boolean {
  switch (e.k) {
    case "var": return !!env[e.n];
    case "not": return !evaluate(e.a, env, o);
    case "and": return evaluate(e.a, env, o) && evaluate(e.b, env, o);
    case "or": return o.orAsXor ? evaluate(e.a, env, o) !== evaluate(e.b, env, o) : evaluate(e.a, env, o) || evaluate(e.b, env, o);
    case "xor": return evaluate(e.a, env, o) !== evaluate(e.b, env, o);
    case "imp": return !evaluate(e.a, env, o) || evaluate(e.b, env, o);
  }
}
export const varsOf = (e: Ex, out = new Set<string>()): string[] => {
  if (e.k === "var") out.add(e.n); else if (e.k === "not") varsOf(e.a, out); else { varsOf(e.a, out); varsOf(e.b, out); }
  return [...out].sort();
};
export const hasOp = (e: Ex, op: Ex["k"]): boolean => e.k === op || (e.k === "not" ? hasOp(e.a, op) : e.k !== "var" && (hasOp(e.a, op) || hasOp(e.b, op)));
/** every setting of the variables, first variable slowest, true before false (the usual table order) */
export function rows(vars: string[]): Record<string, boolean>[] {
  return Array.from({ length: 2 ** vars.length }, (_, i) => Object.fromEntries(vars.map((v, k) => [v, !((i >> (vars.length - 1 - k)) & 1)])));
}
export const trueRows = (e: Ex, vars = varsOf(e), o: EvalOpts = {}) => rows(vars).filter(r => evaluate(e, r, o)).length;
/** "¬ on the whole thing": the NOTs on single letters dropped, and the whole expression negated */
export function wideNot(e: Ex): Ex {
  const strip = (x: Ex): Ex => (x.k === "not" && x.a.k === "var" ? x.a : x.k === "not" ? Not(strip(x.a)) : x.k === "var" ? x : { k: x.k, a: strip(x.a), b: strip(x.b) });
  return Not(strip(e));
}

/** reads p ∧ (q ∨ ¬r) and the ASCII forms: & | ! ~ -> ^ and the words and, or, not, xor */
export function parse(src: string): Ex | null {
  const t = src.replace(/\band\b/gi, "∧").replace(/\bor\b/gi, "∨").replace(/\bxor\b/gi, "⊕").replace(/\bnot\b/gi, "¬")
    .replace(/->|=>/g, "→").replace(/[&*]/g, "∧").replace(/[|+]/g, "∨").replace(/[!~]/g, "¬").replace(/\^/g, "⊕").replace(/\s+/g, "");
  let i = 0;
  const peek = () => t[i];
  const atom = (): Ex | null => {
    const c = peek();
    if (c === "¬") { i++; const a = atom(); return a && Not(a); }
    if (c === "(") { i++; const e = imp(); if (peek() !== ")") return null; i++; return e; }
    if (c && /[pqrs]/i.test(c)) { i++; return V(c.toLowerCase()); }
    return null;
  };
  const chain = (next: () => Ex | null, sym: string, op: Op) => (): Ex | null => {
    let a = next();
    while (a && peek() === sym) { i++; const b = next(); if (!b) return null; a = { k: op, a, b }; }
    return a;
  };
  const and = chain(atom, "∧", "and"), xor = chain(and, "⊕", "xor"), or = chain(xor, "∨", "or");
  function imp(): Ex | null {
    const a = or();
    if (a && peek() === "→") { i++; const b = imp(); return b && Imp(a, b); }
    return a;
  }
  const e = imp();
  return e && i === t.length ? e : null;
}

/* ---------------------------------------------------------------- gates ---------------------------------------------------------------- */

export type GateOp = "AND" | "OR" | "XOR" | "NAND" | "NOT";
/** a gate reads inputs by name (x, y, z) or earlier gates by number */
export interface Gate { op: GateOp; a: string | number; b?: string | number }
export interface GateOpts { xorAsOr?: boolean; nandAsAnd?: boolean }
export function runCircuit(gates: Gate[], env: Record<string, number>, o: GateOpts = {}): number[] {
  const out: number[] = [];
  const get = (s: string | number) => (typeof s === "number" ? out[s]! : env[s]!);
  for (const g of gates) {
    const a = get(g.a), b = g.b == null ? 0 : get(g.b);
    out.push(g.op === "NOT" ? 1 - a : g.op === "AND" ? a & b : g.op === "OR" ? a | b : g.op === "XOR" ? (o.xorAsOr ? a | b : a ^ b) : o.nandAsAnd ? a & b : 1 - (a & b));
  }
  return out;
}
export const circuitOut = (gates: Gate[], env: Record<string, number>, o: GateOpts = {}) => runCircuit(gates, env, o).at(-1)!;
/** the circuit as an expression, the last gate outermost */
export function circuitText(gates: Gate[], at = gates.length - 1): string {
  const g = gates[at]!;
  const side = (s: string | number) => (typeof s === "number" ? (gates[s]!.op === "NOT" ? circuitText(gates, s) : `(${circuitText(gates, s)})`) : s);
  return g.op === "NOT" ? `NOT ${side(g.a)}` : `${side(g.a)} ${g.op} ${side(g.b!)}`;
}
export const NAND_COST: Record<string, number> = { NOT: 1, AND: 2, OR: 3, XOR: 4 };

/** a full adder's two outputs */
export const fullAdd = (a: number, b: number, c: number) => ({ s: a ^ b ^ c, c: (a & b) | (c & (a ^ b)) });
/** the carries a ripple-carry adder sends left, from the rightmost column */
export function carries(a: number, b: number, bits = 4): number[] {
  const out: number[] = [];
  let c = 0;
  for (let k = 0; k < bits; k++) { c = fullAdd((a >> k) & 1, (b >> k) & 1, c).c; out.push(c); }
  return out;
}
export const bin = (n: number, w: number) => n.toString(2).padStart(w, "0");

/* ---------------------------------------------------------------- algorithms ---------------------------------------------------------------- */

/** the indices binary search opens, middle first (rounding down), until it finds the target */
export function binaryTrace(list: number[], target: number): number[] {
  const out: number[] = [];
  let lo = 0, hi = list.length - 1;
  while (lo <= hi) {
    const mid = Math.floor((lo + hi) / 2);
    out.push(mid);
    if (list[mid] === target) break;
    if (list[mid]! < target) lo = mid + 1; else hi = mid - 1;
  }
  return out;
}
export const bitLength = (n: number) => Math.floor(Math.log2(n)) + 1;
/** one pass of bubble sort: compare neighbors left to right, swapping any out of order */
export function bubblePass(xs: number[]): number[] {
  const a = [...xs];
  for (let i = 0; i + 1 < a.length; i++) if (a[i]! > a[i + 1]!) [a[i], a[i + 1]] = [a[i + 1]!, a[i]!];
  return a;
}
export const inversions = (xs: number[]) => xs.reduce((s, x, i) => s + xs.slice(i + 1).filter(y => y < x).length, 0);
/** bubble sort's every step (compare i, i + 1, and whether it swapped), the full version with no early exit */
export function bubbleSteps(xs: number[]) {
  const a = [...xs], steps: { i: number; swap: boolean; after: number[] }[] = [];
  for (let pass = 0; pass < a.length - 1; pass++) for (let i = 0; i < a.length - 1 - pass; i++) {
    const swap = a[i]! > a[i + 1]!;
    if (swap) [a[i], a[i + 1]] = [a[i + 1]!, a[i]!];
    steps.push({ i, swap, after: [...a] });
  }
  return steps;
}
/** merge sort's comparisons on a list */
export function mergeCount(xs: number[]): number {
  let c = 0;
  const sort = (a: number[]): number[] => {
    if (a.length < 2) return a;
    const m = a.length >> 1, l = sort(a.slice(0, m)), r = sort(a.slice(m)), out: number[] = [];
    let i = 0, j = 0;
    while (i < l.length && j < r.length) { c++; out.push(l[i]! <= r[j]! ? l[i++]! : r[j++]!); }
    return [...out, ...l.slice(i), ...r.slice(j)];
  };
  sort(xs);
  return c;
}
/** merge sort's levels, for the picture: the list after each level of merging */
export function mergeLevels(xs: number[]): number[][] {
  const out: number[][] = [];
  let size = 1, a = [...xs];
  while (size < a.length) {
    const next: number[] = [];
    for (let i = 0; i < a.length; i += 2 * size) next.push(...[...a.slice(i, i + 2 * size)].sort((x, y) => x - y));
    a = next; out.push(a); size *= 2;
  }
  return out;
}

export interface Graph { names: string[]; edges: [number, number, number][] }
export const neighbors = (g: Graph, u: number) => g.edges.flatMap(([a, b, w]) => (a === u ? [[b, w] as const] : b === u ? [[a, w] as const] : []));
/** Dijkstra from 0: distances, the order places are settled, each place's previous stop, and whether any choice tied */
export function dijkstra(g: Graph, from = 0) {
  const n = g.names.length, d = Array<number>(n).fill(Infinity), prev = Array<number>(n).fill(-1), done = Array<boolean>(n).fill(false);
  const order: number[] = [];
  let tie = false;
  d[from] = 0;
  for (let k = 0; k < n; k++) {
    let u = -1;
    for (let v = 0; v < n; v++) if (!done[v] && d[v]! < Infinity && (u < 0 || d[v]! < d[u]!)) u = v;
    if (u < 0) break;
    if (k > 0 && [...Array(n).keys()].some(v => v !== u && !done[v] && d[v] === d[u])) tie = true;
    done[u] = true; order.push(u);
    for (const [v, w] of neighbors(g, u)) if (d[u]! + w < d[v]!) { d[v] = d[u]! + w; prev[v] = u; }
  }
  return { d, prev, order, tie };
}
/** how many shortest routes reach each place */
export function routeCounts(g: Graph, from = 0): number[] {
  const { d, order } = dijkstra(g, from);
  const c = d.map((_, i) => (i === from ? 1 : 0));
  for (const u of order) for (const [v, w] of neighbors(g, u)) if (d[u]! + w === d[v]) c[v]! += c[u]!;
  return c;
}
export const pathTo = (prev: number[], t: number) => { const p = [t]; while (prev[p[0]!]! >= 0) p.unshift(prev[p[0]!]!); return p; };
/** walking from the start, always take the cheapest road to a place not yet visited, until the target or a dead end */
export function greedyWalk(g: Graph, t: number, from = 0): number[] | null {
  const p = [from];
  while (p.at(-1) !== t) {
    const opts = neighbors(g, p.at(-1)!).filter(([v]) => !p.includes(v)).sort((a, b) => a[1] - b[1]);
    if (!opts.length) return null;
    p.push(opts[0]![0]);
  }
  return p;
}
export const routeLength = (g: Graph, p: number[]) => p.slice(1).reduce((s, v, i) => s + (neighbors(g, p[i]!).find(([x]) => x === v)?.[1] ?? Infinity), 0);

/** the 3 different round trips of 4 cities from A, and their lengths */
export function tours4(D: number[][]) {
  const t = [[0, 1, 2, 3], [0, 1, 3, 2], [0, 2, 1, 3]];
  return t.map(r => ({ r, len: r.reduce((s, c, i) => s + D[c]![r[(i + 1) % 4]!]!, 0) }));
}
export function nearestTour(D: number[][]): number[] | null {
  const r = [0];
  while (r.length < D.length) {
    const here = r.at(-1)!, opts = D[here]!.map((d, j) => [d, j] as const).filter(([, j]) => !r.includes(j)).sort((a, b) => a[0] - b[0]);
    if (opts.length > 1 && opts[0]![0] === opts[1]![0]) return null;
    r.push(opts[0]![1]);
  }
  return r;
}
export const factorial = (n: number) => { let f = 1; for (let k = 2; k <= n; k++) f *= k; return f; };

/** every subset (as index lists) that hits the target */
export function subsetsHitting(ws: number[], target: number): number[][] {
  const out: number[][] = [];
  for (let m = 1; m < 1 << ws.length; m++) {
    const idx = ws.map((_, i) => i).filter(i => (m >> i) & 1);
    if (idx.reduce((s, i) => s + ws[i]!, 0) === target) out.push(idx);
  }
  return out;
}

/* ---------------------------------------------------------------- machines ---------------------------------------------------------------- */

export type Sym = "0" | "1" | "_";
export interface Rule { q: string; read: Sym; write: Sym; move: "L" | "R"; next: string }
export interface Machine { name: string; start: string; rules: Rule[]; at: "left" | "right" }
export const ADD1: Machine = { name: "add 1", start: "carry", at: "right", rules: [
  { q: "carry", read: "1", write: "0", move: "L", next: "carry" },
  { q: "carry", read: "0", write: "1", move: "L", next: "halt" },
  { q: "carry", read: "_", write: "1", move: "L", next: "halt" },
] };
export const FLIP: Machine = { name: "flip every bit", start: "go", at: "left", rules: [
  { q: "go", read: "0", write: "1", move: "R", next: "go" },
  { q: "go", read: "1", write: "0", move: "R", next: "go" },
  { q: "go", read: "_", write: "_", move: "L", next: "halt" },
] };
export const UNARY: Machine = { name: "unary adder", start: "first", at: "left", rules: [
  { q: "first", read: "1", write: "1", move: "R", next: "first" },
  { q: "first", read: "0", write: "1", move: "R", next: "second" },
  { q: "second", read: "1", write: "1", move: "R", next: "second" },
  { q: "second", read: "_", write: "_", move: "L", next: "trim" },
  { q: "trim", read: "1", write: "_", move: "L", next: "halt" },
] };
export const ruleText = (r: Rule) => `(${r.q}, ${r.read}) → (${r.write}, ${r.move}, ${r.next})`;
/** runs a machine on a tape; returns each configuration (tape, head, state, rule used) and the tape at halt */
export function runMachine(m: Machine, input: string, limit = 200) {
  let tape = [...input] as Sym[], head = m.at === "right" ? tape.length - 1 : 0, q = m.start;
  const trace: { tape: Sym[]; head: number; q: string; rule: number }[] = [{ tape: [...tape], head, q, rule: -1 }];
  while (q !== "halt" && trace.length <= limit) {
    if (head < 0) { tape = ["_", ...tape]; head = 0; }
    if (head >= tape.length) tape = [...tape, "_"];
    const k = m.rules.findIndex(r => r.q === q && r.read === tape[head]);
    if (k < 0) break;
    const r = m.rules[k]!;
    tape[head] = r.write; head += r.move === "L" ? -1 : 1; q = r.next;
    trace.push({ tape: [...tape], head, q, rule: k });
  }
  return { trace, steps: trace.length - 1, out: tape.join("").replace(/^_+|_+$/g, ""), halted: q === "halt" };
}

/* ---------------------------------------------------------------- shift and add ---------------------------------------------------------------- */

/** the chip: [C | A | Q] with A = 0, Q = b, M = a; four rounds of "if Q₀, A ← A + M", then shift [C | A | Q] right */
export function shiftAdd(a: number, b: number, keepCarry = true) {
  let A = 0, Q = b, C = 0;
  const rounds: { q0: number; before: number; sum: number | null; A: number; Q: number }[] = [];
  for (let r = 0; r < 4; r++) {
    const q0 = Q & 1, before = A;
    let sum: number | null = null;
    if (q0) { sum = A + a; C = keepCarry ? sum >> 4 : 0; A = sum & 15; }
    Q = (Q >> 1) | ((A & 1) << 3); A = (A >> 1) | (C << 3); C = 0;
    rounds.push({ q0, before, sum, A, Q });
  }
  return { rounds, product: (A << 4) | Q, adds: rounds.filter(r => r.sum != null).map(r => r.sum!) };
}
export const ones = (n: number) => n.toString(2).split("").filter(c => c === "1").length;

/** a small seeded random stream for pictures (mulberry32), so a shuffle or a puzzle is the same every time */
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
