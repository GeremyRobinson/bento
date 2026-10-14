// Step builders and number helpers shared by the coordinate-plane lessons. They reproduce the current app's compact
// builders exactly (ns: one box, ms: several boxes, fs: a fraction in lowest terms), so every message and verdict matches.
import { answer, formatNumber, frac, num, slot, text, type MathText } from "../../schemas/math-text";
import type { AnswerModel, AnswerStep, RichText, StepCheck } from "../../schemas/lesson";
import type { Rng } from "../../generators/rng";
import { eq } from "../../../engine/evaluation/numbers";

export const f = formatNumber;
/** A negative number in parentheses, as the current app writes a second operand: 3 − (−4). */
export const P = (v: number): MathText => (v < 0 ? [text("("), num(v), text(")")] : [num(v)]);
/** The same, as plain text for hints. */
export const fP = (v: number) => (v < 0 ? `(${f(v)})` : f(v));
/** 1000 → "1,000", as the current app shows big powers. */
export const big = (n: number) => n.toLocaleString("en-US");
/** A whole number in [lo, hi] that is not 0. */
export function nz(rng: Rng, lo: number, hi: number): number {
  let x: number;
  do x = rng.int(lo, hi);
  while (x === 0);
  return x;
}
export const gcd = (a: number, b: number): number => (b ? gcd(b, a % b) : Math.abs(a));

/** "3x² + 30x − 9" from [coefficient, variable] pairs, leaving out zero terms (the current app's poly). */
export function poly(terms: [number, string][]): MathText {
  const out: MathText = [];
  terms.filter(([c]) => c !== 0).forEach(([c, v], i) => {
    const shown = !(Math.abs(c) === 1 && v);
    if (i) out.push(text(c < 0 ? " − " : " + "));
    if (shown) out.push(num(i ? Math.abs(c) : c));
    else if (!i && c < 0) out.push(text("−"));
    if (v) out.push(text(v));
  });
  return out.length ? out : [num(0)];
}
export const polyText = (terms: [number, string][]) => terms.filter(([c]) => c !== 0)
  .map(([c, v], i) => `${c < 0 ? (i ? " − " : "−") : i ? " + " : ""}${Math.abs(c) === 1 && v ? "" : Math.abs(c)}${v}`).join("") || "0";

type Wrong = [number, string, string];

/** One box. The finished line is the prompt with the answer in it; "Show me" adds "That makes …". */
export function ns(o: { id: string; label: string; question?: RichText; prompt: (s: MathText) => MathText; ans: number; hint: RichText; wrong?: Wrong[]; note?: RichText; explain?: RichText; work?: MathText }): AnswerStep {
  return {
    id: o.id,
    label: o.label,
    ...(o.question ? { question: o.question } : {}),
    prompt: o.prompt([slot("x")]),
    ...(o.note ? { note: o.note } : {}),
    slots: [{ id: "x", expected: o.ans }],
    known: (o.wrong ?? []).map(([v, kind, message]) => ({ values: { x: v }, kind, message })),
    hint: o.hint,
    explain: o.explain ?? `${o.hint} That makes ${f(o.ans)}.`,
    work: o.work ?? o.prompt([answer("x", o.ans)]),
  };
}

/** Several boxes checked together; `anyOrder` when they can be swapped (two roots, two factors). */
export function ms(o: { id: string; label: string; question?: RichText; prompt: (S: Record<string, MathText>) => MathText; ans: Record<string, number>; hint: RichText; wrong?: [Record<string, number>, string, string][]; note?: RichText; anyOrder?: boolean; /** boxes drawn small, e.g. an exponent */ small?: string[] }): AnswerStep {
  const ids = Object.keys(o.ans);
  const sorted = (x: number[]) => [...x].sort((p, r) => p - r);
  const same = (x: number[], y: number[]) => (o.anyOrder ? sorted(x).every((t, i) => eq(t, sorted(y)[i])) : x.every((t, i) => eq(t, y[i])));
  const check = (v: Record<string, number | null>): StepCheck => {
    if (ids.some(id => v[id] == null)) return { ok: false, soft: true, message: "Fill in every box." };
    const vals = ids.map(id => v[id] as number), want = ids.map(id => o.ans[id]!);
    if (same(vals, want)) return { ok: true };
    for (const [bad, kind, message] of o.wrong ?? []) if (same(vals, ids.map(id => bad[id]!))) return { ok: false, kind, message, generic: false };
    return { ok: false, kind: o.label, message: `Not quite. ${o.hint}`, generic: true };
  };
  return {
    id: o.id,
    label: o.label,
    ...(o.question ? { question: o.question } : {}),
    prompt: o.prompt(Object.fromEntries(ids.map(id => [id, [slot(id, !!o.small?.includes(id))]]))),
    ...(o.note ? { note: o.note } : {}),
    slots: ids.map(id => ({ id, expected: o.ans[id]! })),
    known: [],
    check,
    hint: o.hint,
    explain: o.hint,
    work: o.prompt(Object.fromEntries(ids.map(id => [id, [answer(id, o.ans[id]!)]]))),
  };
}

/** A fraction answer in lowest terms (improper is fine); a minus sign goes on top. */
export function fs(o: { id: string; label: string; prompt: (s: MathText) => MathText; N: number; D: number; hint: RichText; wrong?: [number, number, string, string][]; note?: RichText }): AnswerStep {
  const g = gcd(Math.abs(o.N), Math.abs(o.D)), sg = Math.sign(o.N) * Math.sign(o.D);
  const RN = (sg * Math.abs(o.N)) / g, RD = Math.abs(o.D) / g;
  const check = (v: Record<string, number | null>): StepCheck => {
    const n = v.n, d = v.d;
    if (n == null || d == null) return { ok: false, soft: true, message: "Fill in the top and the bottom." };
    if (d === 0) return { ok: false, soft: true, message: "The bottom can't be 0." };
    for (const [bn, bd, kind, message] of o.wrong ?? []) if (eq(n, bn) && eq(d, bd)) return { ok: false, kind, message, generic: false };
    if (!eq(n * RD, RN * d)) return { ok: false, kind: o.label, message: `Not quite. ${o.hint}`, generic: true };
    if (d < 0) return { ok: false, soft: true, message: "Right amount. Put the minus sign on the top number." };
    const k = gcd(Math.abs(n), d);
    if (k > 1) return { ok: false, kind: "Not fully simplified", message: `Same amount, but it can be simplified: both numbers divide by ${k}.`, generic: false };
    return { ok: true };
  };
  return {
    id: o.id,
    label: o.label,
    prompt: o.prompt([frac([slot("n")], [slot("d")])]),
    note: o.note || "Write it in lowest terms.",
    slots: [{ id: "n", expected: RN }, { id: "d", expected: RD }],
    known: [],
    check,
    hint: o.hint,
    explain: o.hint,
    work: o.prompt(RD === 1 ? [answer("n", RN)] : [frac([answer("n", RN)], [answer("d", RD)])]),
  };
}

/** The value a step expects in its first box; a beat that arrives at an answer uses it, so both agree. */
export function expected(model: AnswerModel, id: string, slotId?: string): number {
  const s = model.steps.find(x => x.id === id);
  const v = (slotId ? s?.slots.find(x => x.id === slotId) : s?.slots[0])?.expected;
  if (v == null) throw new Error(`answer model has no step ${id}`);
  return v;
}

/** Reads whole numbers from a stored problem; null when any is missing or not a whole number. */
export function ints<K extends string>(raw: unknown, keys: readonly K[]): Record<K, number> | null {
  if (!raw || typeof raw !== "object") return null;
  const r = raw as Record<string, unknown>, out = {} as Record<K, number>;
  for (const k of keys) {
    const v = r[k];
    if (typeof v !== "number" || !Number.isInteger(v)) return null;
    out[k] = v;
  }
  return out;
}

/** Runs a constructor on restored values; a value it rejects means the stored problem is not usable. */
export function attempt<T>(make: () => T): T | null {
  try {
    return make();
  } catch {
    return null;
  }
}

/** "y = 2x + 3", "y = −x", "y = 4" for picture labels. */
export function lineText(m: number, b: number, y = "y"): string {
  const mx = m === 0 ? "" : m === 1 ? "x" : m === -1 ? "−x" : `${f(m)}x`;
  const bb = b === 0 ? "" : mx ? ` ${b < 0 ? "−" : "+"} ${f(Math.abs(b))}` : f(b);
  return `${y} = ${mx}${bb || (mx ? "" : "0")}`;
}

/** 2/3 → "2/3", −3/1 → "−3": a slope written as a fraction in lowest terms. */
export function fracText(n: number, d: number): string {
  const g = gcd(n, d) || 1, s = Math.sign(n) * Math.sign(d);
  const N = Math.abs(n) / g, D = Math.abs(d) / g;
  return `${s < 0 ? "−" : ""}${D === 1 ? N : `${N}/${D}`}`;
}

const SUPS = "⁰¹²³⁴⁵⁶⁷⁸⁹";
/** 5 → "⁵", for exponents inside picture labels. */
export const supText = (n: number) => String(n).split("").map(c => (c === "-" ? "⁻" : SUPS[Number(c)])).join("");

/**
 * Points a parabola y = a·x² + b·x + c needs on screen: its vertex, the given x values (roots, a marked point),
 * and its arms a little way up past them, so the U shape always shows.
 */
export function parabolaFit(a: number, b: number, c: number, xs: number[] = []): [number, number][] {
  const F = (x: number) => a * x * x + b * x + c, h = -b / (2 * a);
  const lo = Math.min(h, ...xs), hi = Math.max(h, ...xs), w = Math.max(hi - h, h - lo, 1.5) + 0.75;
  return [[h, F(h)], ...xs.map((x): [number, number] => [x, F(x)]), [h - w, F(h - w)], [h + w, F(h + w)]];
}

/** f(3) as math: the name, then the number as a value. */
export const call = (name: string, v: number): MathText => [text(`${name}(`), num(v), text(")")];

/** "(3, −4)" */
export const pt = (x: number, y: number) => `(${f(x)}, ${f(y)})`;
/** (3, −4) as math, numbers kept as values. */
export const ptM = (x: number | MathText, y: number | MathText): MathText =>
  [text("("), ...(typeof x === "number" ? [num(x)] : x), text(", "), ...(typeof y === "number" ? [num(y)] : y), text(")")];
