// Step builders for the algebra lessons, ported from the current app's ns / ms / fs / numStep helpers.
// Each one turns the problem's numbers into an answer-model step with the same labels, hints, checks and worked line.
import { answer, formatNumber as f, frac, num, op, slot, sup, text, type MathText } from "../../schemas/math-text";
import type { AnswerStep, RichText, StepCheck } from "../../schemas/lesson";

const close = (a: number | null | undefined, b: number | null | undefined) => a != null && b != null && Math.abs(a - b) < 1e-6;
const gcd = (a: number, b: number): number => (b ? gcd(b, a % b) : a);

/** A known slip for a one-box step: the typed value, its kind and the message (the current app's [value, kind, msg]). */
export type Slip = [value: number, kind: string, message: RichText];

interface OneBox {
  id: string;
  /** the step's label */
  l: string;
  /** an instruction above the math */
  q?: RichText;
  /** the math, given what goes in the box (an empty box, or the answer) */
  a: (box: MathText) => MathText;
  ans: number;
  /** the hint; "Show me" says it again followed by "That makes …" */
  h: RichText;
  w?: Slip[];
  /** the short line under the step */
  n?: RichText;
}

/** One box; the worked line is the same math with the answer filled in (the current app's `ns`). */
export function ns(o: OneBox): AnswerStep {
  return numStep({ ...o, explain: `${o.h} That makes ${f(o.ans)}.`, work: o.a([answer("x", o.ans)]) });
}

/** One box with its own explanation and worked line (the current app's `numStep`). */
export function numStep(o: OneBox & { explain: RichText; work: MathText }): AnswerStep {
  return {
    id: o.id,
    label: o.l,
    ...(o.q ? { question: o.q } : {}),
    prompt: o.a([slot("x")]),
    ...(o.n ? { note: o.n } : {}),
    slots: [{ id: "x", expected: o.ans }],
    known: (o.w ?? []).map(([v, kind, message]) => ({ values: { x: v }, kind, message })),
    hint: o.h,
    explain: o.explain,
    work: o.work,
  };
}

/** Several boxes at once; `anyOrder` when the boxes can be swapped (the current app's `ms`). */
export function ms(o: {
  id: string; l: string; q?: RichText; n?: RichText; h: RichText;
  a: (boxes: Record<string, MathText>) => MathText;
  ans: Record<string, number>;
  w?: [values: Record<string, number>, kind: string, message: RichText][];
  anyOrder?: boolean;
}): AnswerStep {
  const ids = Object.keys(o.ans);
  const sorted = (x: number[]) => [...x].sort((p, r) => p - r);
  const same = (x: number[], y: number[]) => (o.anyOrder ? sorted(x).every((t, i) => close(t, sorted(y)[i])) : x.every((t, i) => close(t, y[i])));
  const check = (v: Record<string, number | null>): StepCheck => {
    if (ids.some(id => v[id] == null)) return { ok: false, soft: true, message: "Fill in every box." };
    const vals = ids.map(id => v[id]!), want = ids.map(id => o.ans[id]!);
    if (same(vals, want)) return { ok: true };
    for (const [bad, kind, message] of o.w ?? []) if (same(vals, ids.map(id => bad[id]!))) return { ok: false, kind, message, generic: false };
    return { ok: false, kind: o.l, message: `Not quite. ${o.h}`, generic: true };
  };
  return {
    id: o.id,
    label: o.l,
    ...(o.q ? { question: o.q } : {}),
    prompt: o.a(Object.fromEntries(ids.map(id => [id, [slot(id)]]))),
    ...(o.n ? { note: o.n } : {}),
    slots: ids.map(id => ({ id, expected: o.ans[id]! })),
    known: (o.w ?? []).map(([values, kind, message]) => ({ values, kind, message })),
    check,
    hint: o.h,
    explain: o.h,
    work: o.a(Object.fromEntries(ids.map(id => [id, [answer(id, o.ans[id]!)]]))),
  };
}

/** A fraction answer in lowest terms (improper is fine); a minus sign goes on top (the current app's `fs`). */
export function fs(o: {
  id: string; l: string; q?: RichText; n?: RichText; h: RichText;
  a: (box: MathText) => MathText;
  N: number; D: number;
  w?: [n: number, d: number, kind: string, message: RichText][];
}): AnswerStep {
  const g = gcd(Math.abs(o.N), Math.abs(o.D)), sg = Math.sign(o.N) * Math.sign(o.D);
  const RN = (sg * Math.abs(o.N)) / g, RD = Math.abs(o.D) / g;
  const check = (v: Record<string, number | null>): StepCheck => {
    const n = v.n, d = v.d;
    if (n == null || d == null) return { ok: false, soft: true, message: "Fill in the top and the bottom." };
    if (d === 0) return { ok: false, soft: true, message: "The bottom can't be 0." };
    for (const [bn, bd, kind, message] of o.w ?? []) if (close(n, bn) && close(d, bd)) return { ok: false, kind, message, generic: false };
    if (!close(n * RD, RN * d)) return { ok: false, kind: o.l, message: `Not quite. ${o.h}`, generic: true };
    if (d < 0) return { ok: false, soft: true, message: "Right amount. Put the minus sign on the top number." };
    const k = gcd(Math.abs(n), d);
    if (k > 1) return { ok: false, kind: "Not fully simplified", message: `Same amount, but it can be simplified: both numbers divide by ${f(k)}.`, generic: false };
    return { ok: true };
  };
  return {
    id: o.id,
    label: o.l,
    ...(o.q ? { question: o.q } : {}),
    prompt: o.a([frac([slot("n")], [slot("d")])]),
    note: o.n || "Write it in lowest terms.",
    slots: [{ id: "n", expected: RN }, { id: "d", expected: RD }],
    known: (o.w ?? []).map(([n, d, kind, message]) => ({ values: { n, d }, kind, message })),
    check,
    hint: o.h,
    explain: o.h,
    work: o.a(RD === 1 ? [answer("n", RN)] : [frac([answer("n", RN)], [answer("d", RD)])]),
  };
}

// ---- math pieces shared by the algebra lessons ----

/** The variable x (or any letter). */
export const v = (name = "x") => text(name);

/** A negative number in parentheses, so "3 + (−4)" reads right (the current app's fmtP). */
export const P = (x: number): MathText => (x < 0 ? [text("("), num(x), text(")")] : [num(x)]);
/** The same, as message text. */
export const fP = (x: number) => (x < 0 ? `(${f(x)})` : f(x));

/** " + 3" or " − 3": a sign and the size, for "x + 3" and "x − 3". */
export const pm = (c: number): MathText => [op(c < 0 ? "−" : "+"), num(Math.abs(c))];
/** The same, as message text. */
export const fpm = (c: number) => `${c < 0 ? "−" : "+"} ${f(Math.abs(c))}`;

/**
 * A polynomial from [coefficient, variable part] pairs, skipping zero terms (the current app's `poly`).
 * A coefficient of ±1 in front of a variable is not written.
 */
export function poly(terms: [number, MathText][]): MathText {
  const live = terms.filter(([c]) => c !== 0);
  if (!live.length) return [num(0)];
  return live.flatMap(([c, vp], i) => {
    const bare = Math.abs(c) === 1 && vp.length > 0;
    if (i === 0) return c < 0 && bare ? [text("−"), ...vp] : bare ? vp : [num(c), ...vp];
    return [op(c < 0 ? "−" : "+"), ...(bare ? [] : [num(Math.abs(c))]), ...vp];
  });
}

/** x², x³, …: a letter with a power. */
export const xp = (n: number | MathText, name = "x"): MathText => [text(name), sup(typeof n === "number" ? [num(n)] : n)];

const SUP: Record<string, string> = { "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹", "−": "⁻", "+": "⁺", "/": "ᐟ" };
/** A power written in message text, e.g. supText(5) = "⁵". */
export const supText = (n: number | string) => [...(typeof n === "number" ? f(n) : n)].map(c => SUP[c] ?? c).join("");

/** Big numbers keep the current app's thousands separators (3,125). */
export const big = (n: number) => n.toLocaleString("en-US");
