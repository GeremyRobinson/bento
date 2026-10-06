// Adding and subtracting fractions with different bottoms (the current app's 5th grade "add", "sub" and "mix"
// lessons: makeProblem, stepsFor and the five steps). Shared by the three lessons; the picture is a pair of
// fraction bars cut into the least common denominator.
import { answer, frac, muted, num, op, slot, text, type MathText } from "../../schemas/math-text";
import type { AnswerModel, AnswerStep, StepCheck } from "../../schemas/lesson";
import type { Rng } from "../../generators/rng";
import { beats, type Explanation } from "../../../explanations/schema";
import { buildTape } from "../../../explanations/diagrams/tape/build";
import type { TapeFill, TapeRow } from "../../../explanations/diagrams/tape/schema";
import { expectedOf, finalForm, gcd, lcm, mixedLabel, mixedMath, pieceName, simplifyStep } from "./steps";
import { count as countOf } from "../../text";

export type Sign = "+" | "−";

/** a/b op c/d, with L the least common denominator and A/L, C/L the rewritten fractions; S is the top of the answer over L. */
export interface UnlikeFractionsProblem { a: number; b: number; c: number; d: number; L: number; A: number; C: number; S: number; op: Sign }

export function createUnlikeFractions(a: number, b: number, c: number, d: number, sign: Sign): UnlikeFractionsProblem {
  if (![a, b, c, d].every(x => Number.isInteger(x) && x > 0) || b < 2 || d < 2 || a >= b || c >= d) throw new Error(`not a fraction problem: ${a}/${b} ${sign} ${c}/${d}`);
  const L = lcm(b, d), A = a * (L / b), C = c * (L / d);
  if (sign === "−" && A <= C) throw new Error("the answer must be positive");
  return { a, b, c, d, L, A, C, S: sign === "−" ? A - C : A + C, op: sign };
}

/** The current app's makeProblem: bottoms 2–12, different, LCD ≤ 24; the first problem is the easy kind (one bottom divides the other). */
export function generateUnlikeFractions(rng: Rng, i: number, sign: Sign): UnlikeFractionsProblem {
  let b: number, d: number;
  for (;;) {
    b = rng.int(2, 12); d = rng.int(2, 12);
    if (b === d || lcm(b, d) > 24) continue;
    const multiple = b % d === 0 || d % b === 0;
    if (i === 0 && !multiple) continue;
    if (i >= 2 && multiple && rng.next() < 0.6) continue;
    break;
  }
  const top = (den: number) => { let n: number; do n = rng.int(1, den - 1); while (gcd(n, den) !== 1); return n; };
  let a = top(b), c = top(d);
  const L = lcm(b, d), A = a * (L / b), C = c * (L / d);
  if (sign === "−") {
    if (A === C) return generateUnlikeFractions(rng, i, sign);
    if (A < C) [a, b, c, d] = [c, d, a, b]; // keep the answer positive
  }
  return createUnlikeFractions(a, b, c, d, sign);
}

/** Accepts the current app's saved {a, b, c, d, op, …} and rebuilds every derived value. */
export function restoreUnlikeFractions(raw: unknown, fallback: Sign): UnlikeFractionsProblem | null {
  if (!raw || typeof raw !== "object") return null;
  const r = raw as Record<string, unknown>;
  const sign = r.op === "+" || r.op === "−" ? r.op : r.op === "-" ? "−" : fallback;
  if (![r.a, r.b, r.c, r.d].every(x => typeof x === "number")) return null;
  try { return createUnlikeFractions(r.a as number, r.b as number, r.c as number, r.d as number, sign); } catch { return null; }
}

export const showUnlike = (p: UnlikeFractionsProblem): MathText => [frac(p.a, p.b), op(p.op), frac(p.c, p.d)];

type Values = Record<string, number | null | undefined>;

/** The five steps, with the current app's checks and messages. */
export function unlikeAnswers(p: UnlikeFractionsProblem): AnswerModel {
  const { a, b, c, d, L, A, C, S } = p, sub = p.op === "−";
  const big = Math.max(b, d), small = Math.min(b, d);
  const lcd: AnswerStep = {
    id: "lcd",
    label: "Find a common denominator",
    question: `Smallest number that both ${b} and ${d} go into:`,
    note: "This is the least common denominator (LCD).",
    prompt: [slot("x")],
    slots: [{ id: "x", expected: L }],
    known: [],
    check: (v: Values): StepCheck => {
      const x = v.x ?? null;
      if (x === L) return { ok: true };
      if (x === b + d) return { ok: false, generic: false, kind: "Added the denominators",
        message: `You added ${b} + ${d}. The bottom number is the **size of the pieces**, so it doesn't get added. Find a number that ${b} and ${d} both go into evenly.` };
      if (sub && x === Math.abs(b - d)) return { ok: false, generic: false, kind: "Subtracted the denominators",
        message: `You subtracted ${big} − ${small}. The bottom number is the **size of the pieces**, so it doesn't get subtracted. Find a number that ${b} and ${d} both go into evenly.` };
      if (x != null && x > 0 && x % b === 0 && x % d === 0) return { ok: false, generic: false, kind: "Common denominator, but not the least",
        message: `${x} works, since ${b} and ${d} both go into it. There's a **smaller** one, though, and it keeps the numbers easier.` };
      if (x == null || !(x > 0)) return { ok: false, generic: false, kind: "Finding the LCD", message: "Type a number first." };
      const bad = x % b !== 0 ? b : d;
      return { ok: false, generic: false, kind: "Finding the LCD", message: `${bad} doesn't go into ${x} evenly (${x} ÷ ${bad} has a remainder). Both bottom numbers must divide into it.` };
    },
    hint: `Count by ${big}s: ${[1, 2, 3, 4].map(i => i * big).join(", ")}… Stop at the first one that ${small} also goes into.`,
    explain: `Counting by ${big}s, the first number ${small} also goes into is ${L}.`,
    work: [text("LCD of "), num(b), text(" and "), num(d), text(" is "), answer("x", L)],
  };
  const rewrite = (n: number, den: number, N: number, which: 1 | 2): AnswerStep => {
    const k = L / den;
    return {
      id: which === 1 ? "first" : "second",
      label: `Rewrite ${which === 1 ? "the first" : "the second"} fraction`,
      note: `Make ${L} the bottom number.`,
      prompt: [frac(n, den), op("="), frac([slot("x")], L)],
      slots: [{ id: "x", expected: N }],
      known: [],
      check: (v: Values): StepCheck => {
        const x = v.x ?? null;
        if (x === N) return { ok: true };
        if (x === n) return { ok: false, generic: false, kind: "Changed the bottom but not the top",
          message: `You changed the bottom from ${den} to ${L}, but kept the top as ${n}. Whatever you multiply the bottom by, multiply the top by the same number.` };
        if (x === n + (L - den)) return { ok: false, generic: false, kind: "Added instead of multiplied",
          message: `You added ${L - den} to the top because the bottom went up by ${L - den}. A fraction stays the same only when you **multiply** top and bottom by the same number. What times ${den} makes ${L}?` };
        return { ok: false, generic: false, kind: "Rewriting a fraction", message: `Ask yourself: ${den} × **?** = ${L}. Then multiply the top, ${n}, by that number.` };
      },
      hint: `${den} × ? = ${L}. Whatever you multiply the bottom by, do the same to the top.`,
      explain: `${den} × ${k} = ${L}, so ${n} × ${k} = ${N}.`,
      work: [frac(n, den), op("="), frac([answer("x", N)], L), muted(`(× ${k})`)],
    };
  };
  const combine: AnswerStep = {
    id: sub ? "subtract" : "add",
    label: sub ? "Subtract" : "Add",
    note: "Fill in the top and the bottom.",
    prompt: [frac(A, L), op(p.op), frac(C, L), op("="), frac([slot("n")], [slot("d")])],
    slots: [{ id: "n", expected: S }, { id: "d", expected: L }],
    known: [],
    check: (v: Values): StepCheck => {
      const n = v.n ?? null, dd = v.d ?? null;
      if (n == null || dd == null) return { ok: false, soft: true, message: "Fill in both boxes, the top and the bottom." };
      if (n === S && dd === L) return { ok: true };
      if (!sub && dd === 2 * L) return { ok: false, generic: false, kind: "Added the denominators",
        message: `You added the bottoms too (${L} + ${L}). The pieces are already the same size, ${L}ths, so the bottom stays **${L}**. Picture a pizza: ${A} slices plus ${C} slices is ${S} slices, still ${L}ths.` };
      if (sub && dd === 0) return { ok: false, generic: false, kind: "Subtracted the denominators",
        message: `You subtracted the bottoms too (${L} − ${L} = 0). The pieces are already the same size, ${L}ths, so the bottom stays **${L}**. Picture a pizza: ${A} slices take away ${C} is ${S} slices, still ${L}ths.` };
      if (dd !== L) return { ok: false, generic: false, kind: "Changed the denominator",
        message: `When the bottoms match, the bottom stays the same: **${L}**. Only the tops get ${sub ? "subtracted" : "added"}.` };
      if (sub && n === A + C) return { ok: false, generic: false, kind: "Added instead of subtracting", message: `You added ${A} + ${C}. Look at the sign: this one is a **minus**.` };
      if (!sub && n === Math.abs(A - C)) return { ok: false, generic: false, kind: "Subtracted instead of adding", message: "You subtracted. Look at the sign: this one is a **plus**." };
      return { ok: false, generic: false, kind: sub ? "Subtracting numerators" : "Adding numerators", message: `The bottom is right. Check the top: ${A} ${p.op} ${C} = ?` };
    },
    hint: `${sub ? "Subtract" : "Add"} only the tops. The bottom stays ${L}.`,
    explain: `${A} ${p.op} ${C} = ${S}, and the bottom stays ${L}.`,
    work: [frac(A, L), op(p.op), frac(C, L), op("="), frac([answer("n", S)], [answer("d", L)])],
  };
  return { steps: [lcd, rewrite(a, b, A, 1), rewrite(c, d, C, 2), combine, simplifyStep(S, L, "Simplify")], finalParts: [-1] };
}

const count = (k: number, d: number) => `${k} ${pieceName(d, k !== 1)}`;

/**
 * Two fraction bars, a/b and c/d. Beat 1 marks where both would be cut into L pieces; beats 2 and 3 re-cut each bar
 * into L pieces (the shaded amount does not move); beat 4 puts the pieces together (or takes C of them away);
 * beat 5 names the answer in lowest terms.
 */
export function unlikePicture(p: UnlikeFractionsProblem) {
  const { a, b, c, d, L, A, C, S } = p, sub = p.op === "−";
  const rows: TapeRow[] = [
    { length: 1, parts: [{ count: b, from: 0 }, { count: L, from: 2 }], ticks: [{ count: L, from: 1, until: 1, dashed: true }],
      fills: [{ a: 0, b: a / b, tone: "on", until: 1 }, { a: 0, b: a / b, tone: "on", from: 2 }],
      label: [{ text: `${a}/${b}`, until: 1 }, { text: `${A}/${L}`, from: 2 }] },
    { length: 1, parts: [{ count: d, from: 0 }, { count: L, from: 3 }], ticks: [{ count: L, from: 1, until: 2, dashed: true }],
      fills: [{ a: 0, b: c / d, tone: "two", until: 2 }, { a: 0, b: c / d, tone: "two", from: 3 }],
      label: [{ text: `${c}/${d}`, until: 2 }, { text: `${C}/${L}`, from: 3 }] },
  ];
  const F = finalForm(S, L), changes = !(F.whole === 0 && F.den === L);
  const answerTotal = changes ? [{ text: `= ${mixedLabel(S, L)}`, from: 5, acc: true }] : [];
  if (sub) {
    rows.push({ length: 1, parts: L, from: 4, fills: [{ a: 0, b: S / L, tone: "on" }, { a: S / L, b: A / L, tone: "cut" }],
      label: [{ text: `${S}/${L}`, acc: true }], total: answerTotal });
  } else {
    const wholes = Math.ceil(S / L);
    for (let w = 0; w < wholes; w++) {
      const on = [Math.max(0, -w * L), Math.min(L, A - w * L)], acc = [Math.max(0, A - w * L), Math.min(L, S - w * L)];
      const fills: TapeFill[] = [
        ...(on[1]! > on[0]! ? [{ a: on[0]! / L, b: on[1]! / L, tone: "on" as const }] : []),
        ...(acc[1]! > acc[0]! ? [{ a: acc[0]! / L, b: acc[1]! / L, tone: "two" as const }] : []),
      ];
      rows.push({ length: 1, parts: L, from: 4, fills, label: w === 0 ? [{ text: `${S}/${L}`, acc: true }] : [], total: w === wholes - 1 ? answerTotal : [] });
    }
  }
  return buildTape({
    rows,
    alt: `Fraction bars for ${a}/${b} ${p.op} ${c}/${d}: both cut into ${pieceName(L)}, ${A}/${L} ${p.op} ${C}/${L} = ${S}/${L}${changes ? ` = ${mixedLabel(S, L)}` : ""}.`,
  });
}

const HEADINGS = { add: "Cut them into same-size pieces", sub: "Subtracting works the same way", mix: "Watch the sign" };
const IDEAS = {
  add: ["The bottom number tells you the size of the pieces. Different sizes can't be added yet.",
    "Every problem takes the same 5 steps: find the LCD, rewrite both fractions, add, then simplify."],
  sub: ["Before you can take away, the pieces have to be the same size.",
    "Never subtract the bottoms: you can't cut something into 0 pieces."],
  mix: ["This lesson mixes plus and minus problems. The first three steps are exactly the same. At step 4, look at the sign before you add or take away."],
};

export function explainUnlike(lesson: "add" | "sub" | "mix") {
  return (p: UnlikeFractionsProblem, model: AnswerModel): Explanation => {
    const { a, b, c, d, L, A, C, S } = p, sub = p.op === "−";
    const Lx = expectedOf(model.steps, "lcd"), A2 = expectedOf(model.steps, "first"), C2 = expectedOf(model.steps, "second");
    const g = gcd(S, L), F = finalForm(S, L);
    const simple = S >= L ? `${count(S, L)} is ${mixedLabel(S, L)}: every ${countOf(L, "piece")} make one whole.`
      : g > 1 ? `Divide the top and the bottom by ${g}: ${S}/${L} = ${mixedLabel(S, L)}.`
      : `${S}/${L} is already as simple as it gets.`;
    return {
      heading: HEADINGS[lesson],
      idea: IDEAS[lesson],
      statement: showUnlike(p),
      diagram: unlikePicture(p),
      caption: `${pieceName(b)[0]!.toUpperCase() + pieceName(b).slice(1)} and ${pieceName(d)} are different sizes; ${pieceName(L)} fit both.`,
      timeline: beats(6),
      steps: [
        { id: "lcd", state: 1, answerStep: "lcd", result: Lx, math: [text("LCD of "), num(b), text(" and "), num(d), text(" is "), num(Lx)],
          narration: `The pieces are different sizes. ${Lx} is the smallest number both ${b} and ${d} go into, so cut both bars into ${pieceName(Lx)}.` },
        { id: "first", state: 2, answerStep: "first", result: A2, math: [frac(a, b), op("="), frac(A2, L), muted(`(× ${L / b})`)],
          narration: `${b} × ${L / b} = ${L}, so ${a} × ${L / b} = ${A2}: ${a}/${b} is the same amount as ${A2}/${L}.` },
        { id: "second", state: 3, answerStep: "second", result: C2, math: [frac(c, d), op("="), frac(C2, L), muted(`(× ${L / d})`)],
          narration: `${d} × ${L / d} = ${L}, so ${c} × ${L / d} = ${C2}: ${c}/${d} is the same amount as ${C2}/${L}.` },
        { id: sub ? "subtract" : "add", state: 4, answerStep: sub ? "subtract" : "add", math: [frac(A, L), op(p.op), frac(C, L), op("="), frac(S, L)],
          narration: sub ? `Same-size pieces now: take ${C} away from ${A}. ${S === 1 ? `1/${L} is` : `${count(S, L)} are`} left, and the bottom stays ${L}.`
            : `Same-size pieces now: ${A} + ${C} = ${count(S, L)}. The bottom stays ${L}.` },
        { id: "simplify", state: 5, answerStep: "simplify", ...(F.num === 0 ? { result: F.whole } : {}), math: [frac(S, L), op("="), ...mixedMath(S, L)], narration: simple },
      ],
    };
  };
}

export const storyFor = (lesson: "add" | "sub" | "mix") => ({ a, b, c, d, op: o }: UnlikeFractionsProblem) => {
  if (lesson === "add") return { op: "+" as const, text: `You walked ${a}/${b} of a mile to the park and then ${c}/${d} of a mile to the store. How far did you walk in all?` };
  if (lesson === "sub") return { op: "−" as const, text: `There was ${a}/${b} of a cake left. The family ate ${c}/${d} of a cake. How much cake is left now?` };
  return o === "+"
    ? { op: o, text: `A plant grew ${a}/${b} inch in May and ${c}/${d} inch in June. How much did it grow in all?` }
    : { op: o, text: `A jug had ${a}/${b} gallon of water. You poured out ${c}/${d} gallon. How much is left?` };
};
