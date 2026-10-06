// Step builders for the tape-diagram and fraction lessons, ported from the current app's ns / ms / fs / simplifyStep.
// Each returns a pure answer-model step: every number in it comes from the problem.
// (This folder has no index.ts, so the lesson registry skips it.)
import { answer, formatNumber as f, frac, num, op, slot, type MathText } from "../../schemas/math-text";
import type { AnswerStep, KnownMistake, RichText, StepCheck } from "../../schemas/lesson";
import { eq } from "../../../engine/evaluation/numbers";

/** Greatest common divisor, the current app's way (works on any numbers a student can type). */
export function gcd(a: number, b: number): number {
  while (b) [a, b] = [b, a % b];
  return a;
}
export const lcm = (a: number, b: number) => (a * b) / gcd(a, b);
export const round6 = (x: number) => Math.round(x * 1e6) / 1e6;

type Values = Record<string, number | null | undefined>;
const val = (v: Values, id: string): number | null => v[id] ?? null;
const slug = (s: string) => s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");

/** [typed value, kind, message] like the current app's `w` lists. */
export type Wrong = [number, string, RichText];

/**
 * One box. The work line is the same line with the answer filled in; "Show me" says the hint and the answer
 * (the current app's `ns`). A known slip is any value in `w`; anything else is the generic "Not quite."
 */
export function ns(o: { id?: string; l: string; q?: RichText; a: (s: MathText) => MathText; ans: number; h: RichText; w?: Wrong[]; n?: RichText }): AnswerStep {
  return {
    id: o.id ?? slug(o.l),
    label: o.l,
    ...(o.q ? { question: o.q } : {}),
    ...(o.n ? { note: o.n } : {}),
    prompt: o.a([slot("x")]),
    slots: [{ id: "x", expected: o.ans }],
    known: (o.w ?? []).map(([x, kind, message]): KnownMistake => ({ values: { x }, kind, message })),
    hint: o.h,
    explain: `${o.h} That makes ${f(o.ans)}.`,
    work: o.a([answer("x", o.ans)]),
  };
}

/** Several boxes checked together; every box must be filled (the current app's `ms`). */
export function ms(o: { id?: string; l: string; q?: RichText; a: (s: Record<string, MathText>) => MathText; ans: Record<string, number>; h: RichText; w?: [Record<string, number>, string, RichText][]; n?: RichText }): AnswerStep {
  const ids = Object.keys(o.ans);
  const same = (x: (number | null)[], y: (number | null)[]) => x.every((t, i) => eq(t, y[i]));
  const want = ids.map(id => o.ans[id]!);
  const check = (v: Values): StepCheck => {
    if (ids.some(id => val(v, id) == null)) return { ok: false, soft: true, message: "Fill in every box." };
    const typed = ids.map(id => val(v, id));
    if (same(typed, want)) return { ok: true };
    for (const [bad, kind, message] of o.w ?? []) if (same(typed, ids.map(id => bad[id] ?? null))) return { ok: false, kind, message, generic: false };
    return { ok: false, kind: o.l, message: `Not quite. ${o.h}`, generic: true };
  };
  return {
    id: o.id ?? slug(o.l),
    label: o.l,
    ...(o.q ? { question: o.q } : {}),
    ...(o.n ? { note: o.n } : {}),
    prompt: o.a(Object.fromEntries(ids.map(id => [id, [slot(id)]]))),
    slots: ids.map(id => ({ id, expected: o.ans[id]! })),
    known: (o.w ?? []).map(([values, kind, message]) => ({ values, kind, message })),
    check,
    hint: o.h,
    explain: o.h,
    work: o.a(Object.fromEntries(ids.map(id => [id, [answer(id, o.ans[id]!)]]))),
  };
}

/** A fraction box (top and bottom) in lowest terms; improper is fine (the current app's `fs`). */
export function fs(o: { id?: string; l: string; q?: RichText; a: (s: MathText) => MathText; N: number; D: number; h: RichText; w?: [number, number, string, RichText][]; n?: RichText }): AnswerStep {
  const g = gcd(Math.abs(o.N), Math.abs(o.D)), sg = Math.sign(o.N) * Math.sign(o.D);
  const RN = (sg * Math.abs(o.N)) / g, RD = Math.abs(o.D) / g;
  const check = (v: Values): StepCheck => {
    const n = val(v, "n"), d = val(v, "d");
    if (n == null || d == null) return { ok: false, soft: true, message: "Fill in the top and the bottom." };
    if (d === 0) return { ok: false, soft: true, message: "The bottom can't be 0." };
    for (const [bn, bd, kind, message] of o.w ?? []) if (eq(n, bn) && eq(d, bd)) return { ok: false, kind, message, generic: false };
    if (!eq(n * RD, RN * d)) return { ok: false, kind: o.l, message: `Not quite. ${o.h}`, generic: true };
    if (d < 0) return { ok: false, soft: true, message: "Right amount! Put the minus sign on the top number." };
    const k = gcd(Math.abs(n), d);
    if (k > 1) return { ok: false, kind: "Not fully simplified", message: `Same amount, but it can be simplified: both numbers divide by ${k}.`, generic: false };
    return { ok: true };
  };
  return {
    id: o.id ?? slug(o.l),
    label: o.l,
    ...(o.q ? { question: o.q } : {}),
    note: o.n || "Write it in lowest terms.",
    prompt: o.a([frac([slot("n")], [slot("d")])]),
    slots: [{ id: "n", expected: RN }, { id: "d", expected: RD }],
    known: (o.w ?? []).map(([n, d, kind, message]) => ({ values: { n, d }, kind, message })),
    check,
    hint: o.h,
    explain: o.h,
    work: o.a(RD === 1 ? [answer("n", RN)] : [frac([answer("n", RN)], [answer("d", RD)])]),
  };
}

/** S/L in lowest terms: whole part, top and bottom, as the current app's finalForm. */
export function finalForm(S: number, L: number) {
  const g = gcd(S, L), n = S / g, d = L / g;
  return { whole: Math.floor(n / d), num: n % d, den: d };
}

/** S/L as a mixed number in math: "1 3/22", "5" or "3/4". */
export function mixedMath(S: number, L: number, asAnswer = false): MathText {
  const F = finalForm(S, L);
  const N = (id: string, v: number) => (asAnswer ? answer(id, v) : num(v));
  if (F.num === 0) return [N("w", F.whole)];
  return [...(F.whole ? [N("w", F.whole)] : []), frac([N("n", F.num)], [N("d", F.den)])];
}

/** The same as a picture label: "1 3/22", "5", "3/4". */
export function mixedLabel(S: number, L: number): string {
  const F = finalForm(S, L);
  if (F.num === 0) return f(F.whole);
  return `${F.whole ? `${F.whole} ` : ""}${F.num}/${F.den}`;
}

/** Simplify S/L to lowest terms or a mixed number (the current app's simplifyStep, shared by the fraction lessons). */
export function simplifyStep(S: number, L: number, label: string, id = "simplify"): AnswerStep {
  const F = finalForm(S, L), hasWhole = F.whole > 0, fracPart = F.num > 0;
  const check = (v: Values): StepCheck => {
    const w = val(v, "w") || 0, n = val(v, "n") || 0, dd = val(v, "d");
    if (val(v, "n") != null && dd == null) return { ok: false, soft: true, message: "Fill in the bottom number too." };
    if (dd === 0) return { ok: false, soft: true, message: "The bottom can't be 0." };
    const den = dd || 1;
    if ((w * den + n) * L !== S * den) {
      return { ok: false, kind: "Simplifying", generic: false, message: S > L
        ? `That's not equal to ${S}/${L}. How many whole ${L}s fit into ${S}? That's the whole number. What's left over goes on top.`
        : `That's not equal to ${S}/${L}. Divide the top **and** the bottom by the same number.` };
    }
    if (dd && n >= dd) return { ok: false, soft: true, message: `That's the right amount! Now write it as a mixed number: how many whole ${dd}s fit into ${n}?` };
    if (dd && n > 0 && gcd(n, dd) > 1) return { ok: false, kind: "Not fully simplified", generic: false,
      message: `Same amount, good! But ${n}/${dd} can still be simplified: both ${n} and ${dd} divide by ${gcd(n, dd)}.` };
    return { ok: true };
  };
  return {
    id,
    label,
    note: S > L ? "The top is bigger than the bottom, so pull out the wholes. Use the small box for the whole number."
      : S === L ? "Top and bottom are the same. What whole number is that?"
      : gcd(S, L) > 1 ? "Can both numbers be divided by the same number?"
      : "If it can't be simplified, just copy it. Leave the whole-number box empty.",
    prompt: [frac(S, L), op("="), slot("w", true), frac([slot("n")], [slot("d")])],
    slots: [{ id: "w", expected: hasWhole ? F.whole : null }, { id: "n", expected: fracPart ? F.num : null }, { id: "d", expected: fracPart ? F.den : null }],
    known: [],
    check,
    hint: S % L === 0 ? `${S} ÷ ${L} = ${S / L} exactly, so it's a whole number.`
      : S >= L ? `${S} ÷ ${L} = ${Math.floor(S / L)} remainder ${S % L}. The remainder goes on top.`
      : gcd(S, L) > 1 ? `Both ${S} and ${L} can be divided by ${gcd(S, L)}.` : `No number (other than 1) divides both ${S} and ${L}. It's already simplest.`,
    explain: S >= L ? `${S} ÷ ${L} = ${Math.floor(S / L)} remainder ${S % L}, then simplify.` : gcd(S, L) > 1 ? `Divide top and bottom by ${gcd(S, L)}.` : "It was already as simple as it gets.",
    work: [frac(S, L), op("="), ...mixedMath(S, L, true)],
  };
}

/** Name of a piece size: halves, thirds, fourths, …, twelfths, 22nds. */
export function pieceName(d: number, plural = true): string {
  const names: Record<number, [string, string]> = {
    2: ["half", "halves"], 3: ["third", "thirds"], 4: ["fourth", "fourths"], 5: ["fifth", "fifths"], 6: ["sixth", "sixths"], 7: ["seventh", "sevenths"],
    8: ["eighth", "eighths"], 9: ["ninth", "ninths"], 10: ["tenth", "tenths"], 11: ["eleventh", "elevenths"], 12: ["twelfth", "twelfths"],
    100: ["hundredth", "hundredths"],
  };
  const n = names[d];
  if (n) return plural ? n[1] : n[0];
  const last = d % 10, teen = d % 100 >= 11 && d % 100 <= 13;
  const suffix = teen ? "th" : last === 1 ? "st" : last === 2 ? "nd" : last === 3 ? "rd" : "th";
  return `${d}${suffix}${plural ? "s" : ""}`;
}

/** "a/b" as plain text, for narration and picture labels. */
export const fracText = (n: number, d: number) => `${f(n)}/${f(d)}`;

/** Reads whole numbers out of a stored problem; null when any is missing. */
export function ints<K extends string>(raw: unknown, keys: readonly K[]): Record<K, number> | null {
  if (!raw || typeof raw !== "object") return null;
  const r = raw as Record<string, unknown>, out = {} as Record<K, number>;
  for (const k of keys) {
    const v = r[k];
    if (typeof v !== "number" || !Number.isFinite(v)) return null;
    out[k] = v;
  }
  return out;
}

/** Helper for beats: the expected value of a one-box step. */
export function expectedOf(steps: AnswerStep[], id: string): number {
  const v = steps.find(s => s.id === id)?.slots.find(s => s.expected != null)?.expected;
  if (v == null) throw new Error(`answer model has no step ${id}`);
  return v;
}
