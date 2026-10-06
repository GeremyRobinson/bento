// The problem's one line, dressed the way the notes preview shows it (Review v40 "little things" 10-13): the two parts
// wear their picture colours, the unknown is a "?" box, and an equation in one letter asks for that letter.
// Everything here is read from the math itself, never written per lesson, and it stays plain whenever the shape is
// not one it is sure of: a wrong colour is worse than none.
import { answer as answerTok, op, text, toPlainText, type MathText, type MathToken } from "../../curriculum/schemas/math-text";
import type { DiagramModel } from "../../explanations/schema";

/** One part's number as it is written in a sentence ("16", "1/2"), and which part it is. */
export interface Tone { s: string; k: 0 | 1 }

const isNum = (t?: MathToken) => t?.t === "num";
const plainNum = (m: MathText) => m.length === 1 && isNum(m[0]);
/** a fraction of two written numbers, 3/4 */
const isFrac = (t?: MathToken) => t?.t === "frac" && plainNum(t.n) && plainNum(t.d);

/** The operand that starts at i: a number, a fraction, or a mixed number. Its length, or 0. (Powers are left out:
 *  3² + 4² draws its squares in the grade's fixed part colours, 200 × 3² has no parts at all.) */
function operandAt(m: MathText, i: number): number {
  const a = m[i], b = m[i + 1];
  if (isNum(a) && isFrac(b)) return 2;
  if (isNum(a) || isFrac(a)) return 1;
  return 0;
}

/** `a ○ b` and nothing else: the two operands and the operator, or null. */
function binary(m: MathText): { a: MathText; o: string; b: MathText; rest: MathText } | null {
  const la = operandAt(m, 0);
  const o = m[la];
  if (!la || o?.t !== "op") return null;
  const lb = operandAt(m, la + 1);
  if (!lb) return null;
  return { a: m.slice(0, la), o: o.v, b: m.slice(la + 1, la + 1 + lb), rest: m.slice(la + 1 + lb) };
}

/** what may follow `a ○ b` and still leave the two operands the parts: nothing, or "= ?" */
const unknownSide = (rest: MathText) =>
  rest.length === 0 || (rest.length === 2 && rest[0]?.t === "op" && rest[0].v === "=" && rest[1]?.t === "text" && rest[1].v.trim() === "?");
/** × 10, × 100, ... moves a decimal point: the 10 is not a part of anything */
const shift = (o: MathText) => o.length === 1 && o[0]?.t === "num" && o[0].v >= 10 && Number.isInteger(Math.log10(o[0].v));

/**
 * The statement as Learn and Practice show it. `a + b` and `a × b` mark a and b as the first and second part (the
 * first wears the lesson's picture colour, the second the picture's second-part colour, as the tape, bar and grid
 * pictures draw them; styles/area-model.css); a bare
 * `a ○ b` gains "= ?" so the unknown has its box. Any other shape (a − b's first number is the whole, not a part;
 * longer lines; words) comes back as it was.
 */
export function dressStatement(m: MathText, look: PartsLook = "one"): MathText {
  const bin = binary(m);
  if (!bin || !unknownSide(bin.rest)) return m;
  // an area model colours its four boxes, not the two factors, so a product keeps its factors in ink there
  const parts = bin.o === "+" || (bin.o === "×" && look !== "fixed" && !shift(bin.a) && !shift(bin.b));
  const a: MathText = parts ? [{ t: "part", k: 0, v: bin.a }] : bin.a, b: MathText = parts ? [{ t: "part", k: 1, v: bin.b }] : bin.b;
  const rest = bin.rest.length ? bin.rest : ["+", "−", "×", "÷"].includes(bin.o) ? [op("="), text("?")] : [];
  return [...a, m[bin.a.length]!, ...b, ...rest];
}

/** The parts a dressed statement names, as they are written in a sentence; none when the two are the same number. */
export function tonesOf(m: MathText): Tone[] {
  const tones = m.flatMap((t): Tone[] => (t.t === "part" ? [{ s: toPlainText(t.v), k: t.k }] : []));
  return tones.length === 2 && tones[0]!.s !== tones[1]!.s ? tones : [];
}

/** A step's math with each part's number in its colour, wherever the number is exactly that part. */
export function toneMath(m: MathText, tones: Tone[]): MathText {
  if (!tones.length) return m;
  return m.map((t): MathToken => {
    if (t.t === "num" || isFrac(t)) {
      const hit = tones.find(x => x.s === toPlainText([t]));
      return hit ? { t: "part", k: hit.k, v: [t] } : t;
    }
    if (t.t === "mark" || t.t === "bold") return { ...t, v: toneMath(t.v, tones) };
    return t;
  });
}

/**
 * "What is x?" over an equation in one unknown letter, when the line says nothing else: one "=", one letter (not
 * squared, not a name like f(x) or a word), and that letter not standing alone as a given (m = −6).
 */
export function askOf(m: MathText): string | null {
  const letters = new Set<string>();
  let rel = 0, words = false, squared = false;
  const walk = (ms: MathText) => ms.forEach((t, i) => {
    switch (t.t) {
      case "op": if (t.v === "=") rel++; else if (t.v !== "+" && t.v !== "−" && t.v !== "×" && t.v !== "÷") words = true; break;
      case "text": {
        // a word, a name (sin, LCM, dx) or a function (f(x)) is not an unknown to find
        if (/[A-Za-z]{2,}|[A-Za-z]\(/.test(t.v)) words = true;
        for (const c of t.v.match(/[A-Za-z]/g) ?? []) letters.add(c);
        if (/[A-Za-z][²³]/.test(t.v) || (/[A-Za-z]\s*$/.test(t.v) && ms[i + 1]?.t === "sup") || ms[i + 1]?.t === "sub") squared = true;
        break;
      }
      case "frac": walk(t.n); walk(t.d); break;
      case "sup": case "sqrt": case "part": case "mark": case "bold": walk(t.v); break;
      case "sub": case "muted": case "br": case "slot": case "answer": words = true; break;
    }
  });
  walk(m);
  if (rel !== 1 || words || squared || letters.size !== 1) return null;
  const x = [...letters][0]!;
  const sides = toPlainText(m).split("=").map(s => s.trim());
  if (sides.some(s => s === x)) return null;
  return `What is ${x}?`;
}

/**
 * How the problem's picture colours its parts, so the numbers can match it:
 * - "fixed": it names its parts by the Grade master's fixed part colours (c0 and c1: place-value blocks, area
 *   models). The first number wears --k0, the second --k1.
 * - "two": it draws the problem in the lesson's own colour and a second part in the second-part colour (.p1, c1:
 *   tapes, bars, fraction grids). The first number wears the lesson's colour, the second --k1.
 * - "one": it draws everything in the lesson's own colour (number lines, charts, arrays, lines of math). Only the first
 *   number wears it; the second stays ink rather than wear a colour the picture never shows.
 */
export type PartsLook = "fixed" | "two" | "one";
export function partsLook(d?: DiagramModel): PartsLook {
  if (d?.kind === "areaModel") return "fixed";
  if (d?.kind !== "scene") return "one";
  const cls = d.items.map(it => it.cls ?? "").join(" ");
  return /\b(c0|p0)\b/.test(cls) ? "fixed" : /\b(c1|p1)\b/.test(cls) ? "two" : "one";
}

/**
 * The statement once the problem is solved (Review v43 item 11): its unknown, the "?" after "=", fills with the
 * answer, which then reads as part of the equation. Only a single number fills it; anything else stays as it was.
 */
export function fillUnknown(m: MathText, answer: number | null | undefined): MathText {
  if (answer == null || !Number.isFinite(answer)) return m;
  let i = -1;
  m.forEach((t, k) => { if (t.t === "text" && t.v.trim() === "?") i = k; });
  if (i < 1 || m[i - 1]?.t !== "op" || (m[i - 1] as { v: string }).v !== "=") return m;
  return [...m.slice(0, i), answerTok("solved", answer), ...m.slice(i + 1)];
}
