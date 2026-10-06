// Step builders for the number-line, decimal-shift and early chain lessons: ports of the current app's
// numStep / ns (one box) and ms (several boxes), so every hint, message and worked line keeps its wording.
import { answer, formatNumber as f, num, slot, text, type MathText, type MathToken } from "../../schemas/math-text";
import type { AnswerModel, AnswerStep, RichText, StepCheck } from "../../schemas/lesson";
import { eq } from "../../../engine/evaluation/numbers";

/** One box. `prompt` gets the box (or, for the finished line, the answer) and returns the math around it. */
export interface OneBox {
  id: string;
  label: string;
  question?: RichText;
  note?: RichText;
  prompt: (box: MathToken) => MathText;
  ans: number;
  /** predictable slips: [typed value, kind, message], checked in order */
  wrong?: [number, string, RichText][];
  hint: RichText;
  /** default: the hint, then "That makes <answer>." (the current app's ns) */
  explain?: RichText;
  /** default: the prompt with the answer filled in */
  work?: MathText;
}

export function oneBox(o: OneBox): AnswerStep {
  return {
    id: o.id,
    label: o.label,
    ...(o.question ? { question: o.question } : {}),
    ...(o.note ? { note: o.note } : {}),
    prompt: o.prompt(slot("x")),
    slots: [{ id: "x", expected: o.ans }],
    known: (o.wrong ?? []).map(([v, kind, message]) => ({ values: { x: v }, kind, message })),
    hint: o.hint,
    explain: o.explain ?? `${o.hint} That makes ${f(o.ans)}.`,
    work: o.work ?? o.prompt(answer("x", o.ans)),
  };
}

/** Several boxes checked together (the current app's ms): every box must be filled, then all must match. */
export function manyBoxes(o: {
  id: string;
  label: string;
  question?: RichText;
  note?: RichText;
  /** gets a token per box id (a box, or the answer for the finished line) */
  prompt: (boxes: Record<string, MathToken>) => MathText;
  ans: Record<string, number>;
  /** slips: [typed values by box, kind, message] */
  wrong?: [Record<string, number>, string, RichText][];
  hint: RichText;
  /** what "Show me" says; default: the hint */
  explain?: RichText;
  /** exponent boxes are drawn small */
  small?: string[];
}): AnswerStep {
  const ids = Object.keys(o.ans);
  const same = (v: Record<string, number | null>, want: Record<string, number>) => ids.every(id => eq(v[id], want[id]));
  const check = (v: Record<string, number | null>): StepCheck => {
    if (ids.some(id => v[id] == null)) return { ok: false, soft: true, message: "Fill in every box." };
    if (same(v, o.ans)) return { ok: true };
    for (const [bad, kind, message] of o.wrong ?? []) if (same(v, bad)) return { ok: false, kind, message, generic: false };
    return { ok: false, kind: o.label, message: `Not quite. ${o.hint}`, generic: true };
  };
  return {
    id: o.id,
    label: o.label,
    ...(o.question ? { question: o.question } : {}),
    ...(o.note ? { note: o.note } : {}),
    prompt: o.prompt(Object.fromEntries(ids.map(id => [id, slot(id, o.small?.includes(id))]))),
    slots: ids.map(id => ({ id, expected: o.ans[id]! })),
    known: (o.wrong ?? []).map(([values, kind, message]) => ({ values, kind, message })),
    check,
    hint: o.hint,
    explain: o.explain ?? o.hint,
    work: o.prompt(Object.fromEntries(ids.map(id => [id, answer(id, o.ans[id]!)]))),
  };
}

/** A negative number in parentheses, as the current app writes a second term: 5 + (−3). */
export const paren = (x: number): MathText => (x < 0 ? [text("("), num(x), text(")")] : [num(x)]);

/** A whole number with thousands commas, as the current app's big(): 45,000. */
export const withCommas = (n: number) => n.toLocaleString("en-US");

/** The value the answer model expects for a step; the lesson page must arrive at the same number. */
export function expectedOf(model: AnswerModel, stepId: string, slotId = "x"): number {
  const v = model.steps.find(s => s.id === stepId)?.slots.find(s => s.id === slotId)?.expected;
  if (v == null) throw new Error(`answer model has no value for ${stepId}.${slotId}`);
  return v;
}

/** Reads the current app's saved problem: every named field must be a finite number. */
export function numbersOf<K extends string>(raw: unknown, keys: readonly K[]): Record<K, number> | null {
  if (!raw || typeof raw !== "object") return null;
  const r = raw as Record<string, unknown>;
  const out = {} as Record<K, number>;
  for (const k of keys) {
    const v = r[k];
    if (typeof v !== "number" || !Number.isFinite(v)) return null;
    out[k] = v;
  }
  return out;
}

/** Restores through a validating constructor: anything it rejects is not a valid problem. */
export function restoreVia<K extends string, P>(raw: unknown, keys: readonly K[], create: (v: Record<K, number>) => P): P | null {
  const v = numbersOf(raw, keys);
  if (!v) return null;
  try {
    return create(v);
  } catch {
    return null;
  }
}

/** Throws unless x is a whole number in [lo, hi]. */
export function wholeIn(name: string, x: number, lo: number, hi: number) {
  if (!Number.isInteger(x) || x < lo || x > hi) throw new Error(`${name} must be a whole number from ${lo} to ${hi}, got ${x}`);
}

export const gcd = (a: number, b: number): number => (b ? gcd(b, a % b) : Math.abs(a));
export const lcm = (a: number, b: number) => (a * b) / gcd(a, b);
export const round6 = (x: number) => Math.round(x * 1e6) / 1e6;

/**
 * How often to label the ticks of a long line so labels stay readable on a phone (review v43 item 9): on round values
 * (1, 2, 5, 10, 20, 25, 50 … apart) that are whole ticks, at most `most` gaps across. Returns the `every` of buildNumberLine.
 */
export function sparseEvery({ min, max, step }: { min: number; max: number; step: number }, most = 7): number {
  for (const s of [1, 2, 5, 10, 20, 25, 50, 100, 200, 500, 1000]) {
    const k = Math.round(s / step);
    if (s < step - 1e-9 || Math.abs(k * step - s) > 1e-9) continue;
    if ((max - min) / s <= most + 1e-9) return k;
  }
  return Math.max(1, Math.round((max - min) / step));
}
