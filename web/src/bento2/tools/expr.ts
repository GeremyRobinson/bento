// The expression reader every Bento² tool shares: the calculator, the grapher's y = …, the Matrix pad's entries.
// A small recursive-descent parser (no eval), so anything typed is only ever read as math.

export type Node =
  | { k: "num"; v: number }
  | { k: "name"; v: string }
  | { k: "neg"; a: Node }
  | { k: "bin"; op: "+" | "-" | "*" | "/" | "^"; a: Node; b: Node }
  | { k: "fact"; a: Node }
  | { k: "call"; f: string; args: Node[] };

const FUNCS: Record<string, { n: number; f: (...x: number[]) => number; angle?: "in" | "out" }> = {
  sqrt: { n: 1, f: Math.sqrt }, cbrt: { n: 1, f: Math.cbrt }, abs: { n: 1, f: Math.abs },
  sin: { n: 1, f: Math.sin, angle: "in" }, cos: { n: 1, f: Math.cos, angle: "in" }, tan: { n: 1, f: Math.tan, angle: "in" },
  asin: { n: 1, f: Math.asin, angle: "out" }, acos: { n: 1, f: Math.acos, angle: "out" }, atan: { n: 1, f: Math.atan, angle: "out" },
  sinh: { n: 1, f: Math.sinh }, cosh: { n: 1, f: Math.cosh }, tanh: { n: 1, f: Math.tanh },
  asinh: { n: 1, f: Math.asinh }, acosh: { n: 1, f: Math.acosh }, atanh: { n: 1, f: Math.atanh }, artanh: { n: 1, f: Math.atanh },
  ln: { n: 1, f: Math.log }, log: { n: 1, f: Math.log10 }, log2: { n: 1, f: Math.log2 }, exp: { n: 1, f: Math.exp },
  floor: { n: 1, f: Math.floor }, ceil: { n: 1, f: Math.ceil }, round: { n: 1, f: Math.round },
  nCr: { n: 2, f: (a, b) => choose(a, b) }, nPr: { n: 2, f: (a, b) => factorial(a) / factorial(a - b) },
  min: { n: 2, f: Math.min }, max: { n: 2, f: Math.max },
};
export const FUNCTION_NAMES = Object.keys(FUNCS);
const BUILTIN: Record<string, number> = { pi: Math.PI, π: Math.PI, e: Math.E };

export function factorial(n: number): number {
  if (!Number.isInteger(n) || n < 0) return NaN;
  let r = 1;
  for (let i = 2; i <= n; i++) r *= i;
  return r;
}
function choose(n: number, k: number): number {
  if (!Number.isInteger(n) || !Number.isInteger(k) || k < 0 || k > n) return NaN;
  let r = 1;
  for (let i = 1; i <= k; i++) r = (r * (n - k + i)) / i;
  return Math.round(r);
}

type Tok = { t: "num"; v: number } | { t: "name"; v: string } | { t: "op"; v: string };

function lex(src: string): Tok[] {
  const s = src.replace(/[−–]/g, "-").replace(/×|·/g, "*").replace(/÷/g, "/").replace(/√/g, "sqrt").replace(/²/g, "^2").replace(/³/g, "^3");
  const out: Tok[] = [];
  let i = 0;
  while (i < s.length) {
    const c = s[i]!;
    if (/\s/.test(c)) { i++; continue; }
    const num = /^(\d+\.?\d*|\.\d+)(e[+-]?\d+)?/i.exec(s.slice(i));
    if (num) { out.push({ t: "num", v: Number(num[0]) }); i += num[0].length; continue; }
    const name = /^[A-Za-zπα-ωΑ-Ω][A-Za-z0-9_α-ωΑ-Ω]*/.exec(s.slice(i));
    if (name) { out.push({ t: "name", v: name[0] }); i += name[0].length; continue; }
    if ("+-*/^()!,".includes(c)) { out.push({ t: "op", v: c }); i++; continue; }
    throw new Error(`Can't read "${c}"`);
  }
  return out;
}

/** Reads typed math into a tree. Throws a short, readable error when it can't. */
export function parse(src: string): Node {
  const toks = lex(src);
  let i = 0;
  const peek = () => toks[i];
  const isOp = (v: string) => { const t = peek(); return !!t && t.t === "op" && t.v === v; };
  const eat = (v: string) => { if (!isOp(v)) throw new Error(v === ")" ? "A bracket isn't closed." : `Expected ${v}`); i++; };
  // sum := product (("+"|"-") product)*
  const sum = (): Node => {
    let a = product();
    while (isOp("+") || isOp("-")) { const op = (toks[i++] as { v: "+" | "-" }).v; a = { k: "bin", op, a, b: product() }; }
    return a;
  };
  // product := unary (("*"|"/") unary | implicit unary)*
  const product = (): Node => {
    let a = unary();
    for (;;) {
      if (isOp("*") || isOp("/")) { const op = (toks[i++] as { v: "*" | "/" }).v; a = { k: "bin", op, a, b: unary() }; continue; }
      const t = peek();
      // 2x, 2(3), (a)(b), 3 sqrt(2): a number, name or bracket straight after another multiplies
      if (t && (t.t === "num" || t.t === "name" || (t.t === "op" && t.v === "("))) { a = { k: "bin", op: "*", a, b: unary() }; continue; }
      return a;
    }
  };
  const unary = (): Node => {
    if (isOp("-")) { i++; return { k: "neg", a: unary() }; }
    if (isOp("+")) { i++; return unary(); }
    return power();
  };
  // power := postfix ("^" unary)?   (right-associative; −2^2 = −4)
  const power = (): Node => {
    const a = postfix();
    if (isOp("^")) { i++; return { k: "bin", op: "^", a, b: unary() }; }
    return a;
  };
  const postfix = (): Node => {
    let a = atom();
    while (isOp("!")) { i++; a = { k: "fact", a }; }
    return a;
  };
  const atom = (): Node => {
    const t = toks[i++];
    if (!t) throw new Error("Something's missing at the end.");
    if (t.t === "num") return { k: "num", v: t.v };
    if (t.t === "name") {
      if (FUNCS[t.v] && isOp("(")) {
        i++;
        const args = [sum()];
        while (isOp(",")) { i++; args.push(sum()); }
        eat(")");
        return { k: "call", f: t.v, args };
      }
      // sqrt 2, sin x: a function name straight before a number or a name takes it
      if (FUNCS[t.v] && FUNCS[t.v]!.n === 1 && peek() && peek()!.t !== "op") return { k: "call", f: t.v, args: [power()] };
      return { k: "name", v: t.v };
    }
    if (t.v === "(") { const a = sum(); eat(")"); return a; }
    throw new Error(t.v === ")" ? "There's a closing bracket with no opening one." : `Something's missing before "${t.v}".`);
  };
  if (!toks.length) throw new Error("Type something first.");
  const tree = sum();
  if (i < toks.length) throw new Error(`Can't read past "${(toks[i] as { v: string | number }).v}".`);
  return tree;
}

export interface EvalEnv {
  vars?: Record<string, number>;
  /** angles in degrees for sin, cos, tan and their inverses */
  degrees?: boolean;
}

/** The value of a tree. Unknown names throw, naming the name. */
export function evaluate(n: Node, env: EvalEnv = {}): number {
  const ev = (x: Node): number => {
    switch (x.k) {
      case "num": return x.v;
      case "name": {
        const v = env.vars?.[x.v] ?? BUILTIN[x.v];
        if (v === undefined) throw new Error(`What's ${x.v}? Put it on the Number shelf or use a constant's name.`);
        return v;
      }
      case "neg": return -ev(x.a);
      case "fact": return factorial(ev(x.a));
      case "bin": {
        const a = ev(x.a), b = ev(x.b);
        return x.op === "+" ? a + b : x.op === "-" ? a - b : x.op === "*" ? a * b : x.op === "/" ? a / b : a ** b;
      }
      case "call": {
        const f = FUNCS[x.f]!;
        if (x.args.length !== f.n) throw new Error(`${x.f} takes ${f.n === 1 ? "one number" : `${f.n} numbers`}.`);
        const args = x.args.map(ev);
        const k = env.degrees ? Math.PI / 180 : 1;
        if (f.angle === "in") return f.f(args[0]! * k);
        if (f.angle === "out") return f.f(args[0]!) / k;
        return f.f(...args);
      }
    }
  };
  return ev(n);
}

/** The names a tree reads that aren't functions or π and e: the grapher gives each one a slider. */
export function namesIn(n: Node): string[] {
  const out = new Set<string>();
  const walk = (x: Node) => {
    if (x.k === "name") { if (!(x.v in BUILTIN)) out.add(x.v); }
    else if (x.k === "neg" || x.k === "fact") walk(x.a);
    else if (x.k === "bin") { walk(x.a); walk(x.b); }
    else if (x.k === "call") x.args.forEach(walk);
  };
  walk(n);
  return [...out];
}

/** Reads and works out one line, or says why it can't. */
export function calc(src: string, env: EvalEnv = {}): { ok: true; value: number } | { ok: false; error: string } {
  try {
    const v = evaluate(parse(src), env);
    if (Number.isNaN(v)) return { ok: false, error: "That has no value (like √ of a negative, or 0 ÷ 0)." };
    return { ok: true, value: v };
  } catch (e) {
    return { ok: false, error: (e as Error).message };
  }
}

/** A result as the calculator shows it: up to 10 significant figures, × 10ⁿ for very big or small numbers. */
export function showValue(x: number, sig = 10): string {
  if (!Number.isFinite(x)) return x > 0 ? "∞" : x < 0 ? "−∞" : "no value";
  if (x === 0) return "0";
  const ax = Math.abs(x), neg = x < 0 ? "−" : "";
  if (ax >= 1e10 || ax < 1e-6) {
    const [m, e] = ax.toExponential(sig - 1).split("e");
    const mant = String(Number(m));
    const sup = String(Number(e)).replace(/-/g, "⁻").replace(/\d/g, d => "⁰¹²³⁴⁵⁶⁷⁸⁹"[+d]!);
    return `${neg}${mant} × 10${sup}`;
  }
  return neg + String(Number(ax.toPrecision(sig)));
}
