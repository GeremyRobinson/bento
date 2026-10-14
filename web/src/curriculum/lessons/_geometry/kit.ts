// Step builders shared by the geometry and data lessons. They keep the current app's three compact step shapes:
// one box (ns), several boxes (ms) and a fraction in lowest terms (fs), with the same checks and messages.
import { answer, br, formatNumber as f, frac, num, op, slot, text, type MathText, type MathToken, type Operator } from "../../schemas/math-text";
import type { AnswerModel, AnswerStep, StepCheck } from "../../schemas/lesson";

/** The current app's Pythagorean triples. */
export const TRIPLES: readonly [number, number, number][] = [[3, 4, 5], [6, 8, 10], [5, 12, 13], [8, 15, 17], [9, 12, 15], [7, 24, 25], [12, 16, 20]];

export const round6 =(x: number) => Math.round(x * 1e6) / 1e6;
export const gcd = (a: number, b: number): number => (b ? gcd(b, a % b) : a);
const eq = (a: number | null | undefined, b: number | null | undefined) => a != null && b != null && Math.abs(a - b) < 1e-6;

const OPS = new Set<string>(["+", "−", "×", "÷", "=", "<", ">", "≤", "≥", "≈", "→", "·", "±"]);
type Piece = number | string | MathToken | MathText;

/**
 * Math as a template: numbers become number tokens, operators in the literal text become operator tokens.
 * mt`${a} × ${b} = ${slot("x")}` reads like the current app's template strings.
 */
export function mt(strings: TemplateStringsArray, ...vals: Piece[]): MathText {
  const out: MathText = [];
  const lit = (s: string) => s.split("\n").forEach((line, k) => {
    if (k) out.push(br());
    for (const part of line.split(/\s*([+−×÷=<>≤≥≈→·±])\s*/)) {
      if (!part) continue;
      if (OPS.has(part)) out.push(op(part as Operator));
      else out.push(text(part));
    }
  });
  strings.forEach((s, i) => {
    lit(s);
    if (i < vals.length) {
      const v = vals[i]!;
      if (typeof v === "number") out.push(num(v));
      else if (typeof v === "string") out.push(text(v));
      else if (Array.isArray(v)) out.push(...v);
      else out.push(v);
    }
  });
  return out;
}

type Wrong = [value: number, kind: string, message: string];

/** One box; the worked line is the prompt with the answer filled in (the current app's `ns`). */
export function ns(o: {
  id: string; label: string; question?: string; prompt: (s: MathToken) => MathText; ans: number; hint: string; wrong?: Wrong[]; note?: string;
  /** a few lessons write their own "Show me" line and finished line (the current app's plain numStep) */
  explain?: string; work?: MathText;
}): AnswerStep {
  return {
    id: o.id,
    label: o.label,
    ...(o.question ? { question: o.question } : {}),
    prompt: o.prompt(slot("x")),
    ...(o.note ? { note: o.note } : {}),
    slots: [{ id: "x", expected: o.ans }],
    known: (o.wrong ?? []).map(([x, kind, message]) => ({ values: { x }, kind, message })),
    hint: o.hint,
    explain: o.explain ?? `${o.hint} That makes ${f(o.ans)}.`,
    work: o.work ?? o.prompt(answer("x", o.ans)),
  };
}

/** Several boxes at once; `anyOrder` when the boxes can be swapped (the current app's `ms`). */
export function ms(o: {
  id: string; label: string; question?: string; prompt: (s: Record<string, MathToken>) => MathText; ans: Record<string, number>; hint: string;
  wrong?: [values: Record<string, number>, kind: string, message: string][]; note?: string; anyOrder?: boolean;
}): AnswerStep {
  const ids = Object.keys(o.ans);
  const sorted = (x: number[]) => [...x].sort((p, r) => p - r);
  const same = (x: number[], y: number[]) => (o.anyOrder ? sorted(x).every((t, i) => eq(t, sorted(y)[i])) : x.every((t, i) => eq(t, y[i])));
  const want = ids.map(id => o.ans[id]!);
  const check = (v: Record<string, number | null>): StepCheck => {
    if (ids.some(id => v[id] == null)) return { ok: false, soft: true, message: "Fill in every box." };
    const vals = ids.map(id => v[id]!);
    if (same(vals, want)) return { ok: true };
    for (const [bad, kind, message] of o.wrong ?? []) if (same(vals, ids.map(id => bad[id]!))) return { ok: false, kind, message, generic: false };
    return { ok: false, kind: o.label, message: `Not quite. ${o.hint}`, generic: true };
  };
  return {
    id: o.id,
    label: o.label,
    ...(o.question ? { question: o.question } : {}),
    prompt: o.prompt(Object.fromEntries(ids.map(id => [id, slot(id)]))),
    ...(o.note ? { note: o.note } : {}),
    slots: ids.map(id => ({ id, expected: o.ans[id]! })),
    known: [],
    check,
    hint: o.hint,
    explain: o.hint,
    work: o.prompt(Object.fromEntries(ids.map(id => [id, answer(id, o.ans[id]!)]))),
  };
}

/** A fraction answer in lowest terms (improper is fine); a minus sign goes on top (the current app's `fs`). */
export function fs(o: {
  id: string; label: string; question?: string; prompt: (s: MathToken) => MathText; N: number; D: number; hint: string;
  wrong?: [n: number, d: number, kind: string, message: string][]; note?: string;
}): AnswerStep {
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
    ...(o.question ? { question: o.question } : {}),
    prompt: o.prompt(frac([slot("n")], [slot("d")])),
    note: o.note || "Write it in lowest terms.",
    slots: [{ id: "n", expected: RN }, { id: "d", expected: RD }],
    known: [],
    check,
    hint: o.hint,
    explain: o.hint,
    work: o.prompt(RD === 1 ? answer("n", RN) : frac([answer("n", RN)], [answer("d", RD)])),
  };
}

/** Value the answer model expects for a step's box; the explanation must arrive at the same number. */
export function expected(answers: AnswerModel, stepId: string, slotId = "x"): number {
  const v = answers.steps.find(s => s.id === stepId)?.slots.find(s => s.id === slotId)?.expected;
  if (v == null) throw new Error(`answer model has no step ${stepId}.${slotId}`);
  return v;
}

/** "3/8" or "2" for a fraction in lowest terms, as message text. */
export function fracText(n: number, d: number): string {
  const g = gcd(Math.abs(n), Math.abs(d));
  return d / g === 1 ? f(n / g) : `${f(n / g)}/${f(d / g)}`;
}

/** 4, 6, 8 as math: numbers joined by ", " text, or by an operator such as "+". */
export const listOf = (v: number[], sep: ", " | Operator = ", "): MathText =>
  v.flatMap((x, i) => (i ? [sep === ", " ? text(", ") : op(sep), num(x)] : [num(x)]));

/** "2π/3", "π/6", "3π/2" */
export const piText = (n: number, d: number) => `${n === 1 ? "" : n}π${d === 1 ? "" : `/${d}`}`;

/** Reads a number field from a stored problem. */
export const numberField = (r: Record<string, unknown>, k: string): number | null => (typeof r[k] === "number" && Number.isFinite(r[k]) ? (r[k] as number) : null);

export const asRecord = (raw: unknown): Record<string, unknown> | null => (raw && typeof raw === "object" ? (raw as Record<string, unknown>) : null);
