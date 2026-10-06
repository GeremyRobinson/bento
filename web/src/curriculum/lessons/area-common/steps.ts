// Step builders the area-and-grids lessons share. They keep the current app's step shapes exactly:
// `numStep` (one box, its own explain and work line), `ns` (one box, "That makes …"), `ms` (several boxes, "Fill in every box."),
// `simplifyStep` (a fraction to lowest terms or a mixed number) and `twoNums` (two numbers in any order).
// This folder has no index.ts, so the registry never mistakes it for a lesson.
import { answer, formatNumber as f, frac, num, op, slot, text, type MathText, type MathToken } from "../../schemas/math-text";
import type { AnswerStep, KnownMistake, StepCheck } from "../../schemas/lesson";

const eq = (a: number | null | undefined, b: number | null | undefined) => a != null && b != null && Math.abs(a - b) < 1e-6;
/** The current app's gcd, kept as is (sign and all) so its messages match. */
export const gcd = (a: number, b: number): number => (b ? gcd(b, a % b) : a);

/** A one-box step's wrong answers: [value, kind, message]. */
export type Wrong = [number, string, string];
const known = (w: Wrong[]): KnownMistake[] => w.map(([v, kind, message]) => ({ values: { x: v }, kind, message }));

/** One box with its own explanation and worked line (the current app's numStep). */
export function numStep(o: { id: string; label: string; question?: string; prompt: (box: MathToken) => MathText; ans: number; wrong?: Wrong[]; hint: string; explain: string; work: MathText; note?: string }): AnswerStep {
  return {
    id: o.id, label: o.label, ...(o.question ? { question: o.question } : {}), ...(o.note ? { note: o.note } : {}),
    prompt: o.prompt(slot("x")), slots: [{ id: "x", expected: o.ans }], known: known(o.wrong ?? []),
    hint: o.hint, explain: o.explain, work: o.work,
  };
}

/** One box; "Show me" adds "That makes …" and the worked line is the prompt with the answer in it (the current app's ns). */
export function ns(o: { id: string; label: string; question?: string; prompt: (box: MathToken) => MathText; ans: number; hint: string; wrong?: Wrong[]; note?: string }): AnswerStep {
  return numStep({ ...o, explain: `${o.hint} That makes ${f(o.ans)}.`, work: o.prompt(answer("x", o.ans)) });
}

/** Several boxes; any empty box is a soft "Fill in every box." (the current app's ms). */
export function ms(o: {
  id: string; label: string; question?: string; prompt: (box: Record<string, MathToken>) => MathText; ans: Record<string, number>;
  hint: string; wrong?: [Record<string, number>, string, string][]; note?: string; anyOrder?: boolean;
}): AnswerStep {
  const ids = Object.keys(o.ans), want = ids.map(id => o.ans[id]!);
  const sorted = (x: number[]) => [...x].sort((p, r) => p - r);
  const same = (x: number[], y: number[]) => (o.anyOrder ? sorted(x).every((t, i) => eq(t, sorted(y)[i])) : x.every((t, i) => eq(t, y[i])));
  const wrong = o.wrong ?? [];
  return {
    id: o.id, label: o.label, ...(o.question ? { question: o.question } : {}), ...(o.note ? { note: o.note } : {}),
    prompt: o.prompt(Object.fromEntries(ids.map(id => [id, slot(id)]))),
    slots: ids.map(id => ({ id, expected: o.ans[id]! })),
    known: wrong.map(([values, kind, message]) => ({ values, kind, message })),
    check: (v): StepCheck => {
      if (ids.some(id => v[id] == null)) return { ok: false, soft: true, message: "Fill in every box." };
      const vals = ids.map(id => v[id]!);
      if (same(vals, want)) return { ok: true };
      for (const [bad, kind, message] of wrong) if (same(vals, ids.map(id => bad[id]!))) return { ok: false, kind, message, generic: false };
      return { ok: false, kind: o.label, message: `Not quite. ${o.hint}`, generic: true };
    },
    hint: o.hint, explain: o.hint,
    work: o.prompt(Object.fromEntries(ids.map(id => [id, answer(id, o.ans[id]!)]))),
  };
}

/** S/L in lowest terms as a whole number and a proper fraction. */
export function finalForm(S: number, L: number) {
  const g = gcd(S, L), n = S / g, d = L / g;
  return { whole: Math.floor(n / d), num: n % d, den: d };
}

/** The finished value of S/L: "2", "1/2" or "2 1/4", as math. */
export function showFinal(F: { whole: number; num: number; den: number }, id = "x"): MathText {
  if (F.num === 0) return [answer(id, F.whole)];
  return [...(F.whole ? [answer(id, F.whole)] : []), frac([answer(id, F.num)], [answer(id, F.den)])];
}

/** Simplify S/L to lowest terms or a mixed number (the current app's simplifyStep). */
export function simplifyStep(S: number, L: number, label: string, id = "simplify"): AnswerStep {
  const F = finalForm(S, L), hasWhole = F.whole > 0, fracPart = F.num > 0, g = gcd(S, L);
  const hint = S % L === 0 ? `${S} ÷ ${L} = ${S / L} exactly, so it's a whole number.`
    : S >= L ? `${S} ÷ ${L} = ${Math.floor(S / L)} remainder ${S % L}. The remainder goes on top.`
    : g > 1 ? `Both ${S} and ${L} can be divided by ${g}.` : `No number (other than 1) divides both ${S} and ${L}. It's already simplest.`;
  return {
    id, label,
    prompt: [frac(S, L), op("="), slot("w", true), frac([slot("n")], [slot("d")])],
    note: S > L ? "The top is bigger than the bottom, so pull out the wholes. Use the small box for the whole number."
      : S === L ? "Top and bottom are the same. What whole number is that?"
      : g > 1 ? "Can both numbers be divided by the same number?"
      : "If it can't be simplified, just copy it. Leave the whole-number box empty.",
    slots: [{ id: "w", expected: hasWhole ? F.whole : null }, { id: "n", expected: fracPart ? F.num : null }, { id: "d", expected: fracPart ? F.den : null }],
    known: [],
    check: (v): StepCheck => {
      const w = v.w || 0, n = v.n || 0, dd = v.d;
      if (v.n != null && dd == null) return { ok: false, soft: true, message: "Fill in the bottom number too." };
      if (dd === 0) return { ok: false, soft: true, message: "The bottom can't be 0." };
      const den = dd || 1;
      if ((w * den + n) * L !== S * den) {
        return { ok: false, kind: "Simplifying", generic: false,
          message: S > L ? `That's not equal to ${S}/${L}. How many whole ${L}s fit into ${S}? That's the whole number. What's left over goes on top.`
            : `That's not equal to ${S}/${L}. Divide the top **and** the bottom by the same number.` };
      }
      if (dd && n >= dd) return { ok: false, soft: true, message: `That's the right amount! Now write it as a mixed number: how many whole ${dd}s fit into ${n}?` };
      if (dd && n > 0 && gcd(n, dd) > 1) return { ok: false, kind: "Not fully simplified", generic: false, message: `Same amount, good! But ${n}/${dd} can still be simplified: both ${n} and ${dd} divide by ${gcd(n, dd)}.` };
      return { ok: true };
    },
    hint,
    explain: S >= L ? `${S} ÷ ${L} = ${Math.floor(S / L)} remainder ${S % L}, then simplify.` : g > 1 ? `Divide top and bottom by ${g}.` : "It was already as simple as it gets.",
    work: [frac(S, L), op("="), ...showFinal(F)],
  };
}

/** Two numbers in either order that multiply to p·q and add to p + q (the current app's twoNums). */
export const twoNums = (p: number, q: number, kindSum: string, kindProd: string) => (v: Record<string, number | null>): StepCheck => {
  if (v.m == null || v.n == null) return { ok: false, soft: true, message: "Fill in both boxes." };
  const a = v.m, b = v.n;
  if ((a === p && b === q) || (a === q && b === p)) return { ok: true };
  if (a * b === p * q) return { ok: false, kind: kindSum, generic: false, message: `${f(a)} × ${f(b)} = ${f(p * q)}, good. But ${f(a)} + ${f(b)} = ${f(a + b)}, not ${f(p + q)}. Try another pair.` };
  if (a + b === p + q) return { ok: false, kind: kindProd, generic: false, message: `${f(a)} + ${f(b)} = ${f(p + q)}, good. But ${f(a)} × ${f(b)} = ${f(a * b)}, not ${f(p * q)}. Try another pair.` };
  return { ok: false, kind: "Factoring", generic: false, message: `List pairs that multiply to ${f(p * q)}, then check which pair adds to ${f(p + q)}.` };
};

// ---- small math-text pieces ----
/** A number in parentheses when negative, as the current app's fmtP. */
export const numP = (x: number): MathText => (x < 0 ? [text("("), num(x), text(")")] : [num(x)]);
/** "a + b + c" from numbers. */
export const plusChain = (values: number[]): MathText => values.flatMap((v, i) => (i ? [op("+"), num(v)] : [num(v)]));

/** The value an answer-model step expects in a box; explanations arrive at the same number. */
export function expectedOf(steps: AnswerStep[], stepId: string, slotId?: string): number {
  const s = steps.find(x => x.id === stepId);
  const v = (slotId ? s?.slots.find(x => x.id === slotId) : s?.slots.find(x => x.expected != null))?.expected;
  if (v == null) throw new Error(`answer model has no value for ${stepId}`);
  return v;
}

/** A polynomial as plain text from [coefficient, "x²"] pairs, skipping zero terms (the current app's poly). */
export function polyText(terms: [number, string][]): string {
  const sgn = (c: number, first: boolean) => (c < 0 ? (first ? "−" : " − ") : first ? "" : " + ");
  return terms.filter(([c]) => c !== 0).map(([c, v], i) => `${sgn(c, i === 0)}${Math.abs(c) === 1 && v ? "" : f(Math.abs(c))}${v}`).join("") || "0";
}

/** A nonzero whole number in [lo, hi] (the current app's nz). */
export function nonZero(rng: { int(lo: number, hi: number): number }, lo: number, hi: number): number {
  let v: number;
  do v = rng.int(lo, hi); while (v === 0);
  return v;
}

/** Reads a stored problem: every named field must be a finite number (or a boolean where asked). */
export function readNumbers<K extends string>(raw: unknown, keys: readonly K[]): Record<K, number> | null {
  if (!raw || typeof raw !== "object") return null;
  const r = raw as Record<string, unknown>, out = {} as Record<K, number>;
  for (const k of keys) {
    const v = r[k];
    if (typeof v !== "number" || !Number.isFinite(v)) return null;
    out[k] = v;
  }
  return out;
}
