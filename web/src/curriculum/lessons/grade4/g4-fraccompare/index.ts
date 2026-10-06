// Comparing fractions (new in the rebuild): cut both wholes into same-size pieces, then the fraction with more
// pieces is bigger. When one bottom goes into the other, only one fraction needs new pieces.
import { frac, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation, type ExplanationStep } from "../../../../explanations/schema";
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import type { TapeRow } from "../../../../explanations/diagrams/tape/schema";
import { gcd, pieceName } from "../../_tape-family/steps";
import { expectedOf, oneBox, restoreVia } from "../../_number-line/steps";
import { COMPARE, compareIndex, signName, slips, tapStep } from "../_kit";
import { count } from "../../../text";

/** a/b compared with c/d. */
export interface FracCompareProblem { a: number; b: number; c: number; d: number }

/** Bottoms with no common factor whose product is small enough to draw. */
const APART: [number, number][] = [[2, 3], [2, 5], [3, 4], [3, 5], [4, 5]];

export function createFracCompare(a: number, b: number, c: number, d: number): FracCompareProblem {
  if (![a, b, c, d].every(Number.isInteger) || b < 2 || d < 2 || b > 12 || d > 12 || a < 1 || c < 1 || a >= b || c >= d) throw new Error(`not two proper fractions: ${a}/${b}, ${c}/${d}`);
  if (b === d) throw new Error("the bottoms must differ");
  const related = b % d === 0 || d % b === 0;
  if (!related && (gcd(b, d) !== 1 || b * d > 20)) throw new Error(`${b} and ${d} make pieces too small to draw`);
  return { a, b, c, d };
}

/** Early problems have one bottom that goes into the other (halves and fourths); later ones may need a new bottom (thirds and fourths). */
export function generateFracCompare(rng: Rng, index: number): FracCompareProblem {
  let b: number, d: number;
  if (index < 4 || rng.next() < 0.5) {
    b = rng.int(2, 6);
    d = b * rng.pick([2, 3].filter(k => b * k <= 12));
  } else [b, d] = rng.pick(APART);
  if (rng.next() < 0.5) [b, d] = [d, b];
  const L = (b * d) / gcd(b, d);
  let a: number, c: number;
  // both in lowest terms, except now and then the same amount written with a bigger bottom (1/2 and 2/4)
  const same = L === Math.max(b, d) && rng.next() < 0.2;
  do {
    a = rng.int(1, b - 1);
    c = same ? (a * L) / b / (L / d) : rng.int(1, d - 1);
  } while (!Number.isInteger(c) || c < 1 || c >= d || (same ? gcd(b < d ? a : c, Math.min(b, d)) !== 1 : gcd(a, b) !== 1 || gcd(c, d) !== 1));
  return createFracCompare(a, b, c, d);
}

function parts({ a, b, c, d }: FracCompareProblem) {
  const L = (b * d) / gcd(b, d), A = (a * L) / b, C = (c * L) / d;
  return { L, A, C, apart: L !== b && L !== d };
}

const each = (n: number, d: number) => `${n} ${pieceName(d, n !== 1)}`;
const cap = (s: string) => s[0]!.toUpperCase() + s.slice(1);

function renameStep(id: string, n: number, d: number, L: number): AnswerStep {
  const k = L / d, N = n * k;
  return oneBox({
    id, label: `Rename ${n}/${d}`, question: `Cut each ${pieceName(d, false)} into ${k}. How many ${pieceName(L)} is ${n}/${d}?`,
    prompt: s => [frac(n, d), op("="), frac([s], L)], ans: N,
    wrong: slips(N, [
      [n, "Changed only the bottom", `The bottom went × ${k}, so the top goes × ${k} too.`],
      [n + L - d, "Added instead of multiplied", `${d} × ${k} = ${L}, so multiply the top by ${k} too.`],
    ]),
    hint: `${d} × ${k} = ${L}. Do the same to the top: ${n} × ${k}.`,
    explain: `Each ${pieceName(d, false)} is ${k} ${pieceName(L)}, so ${n}/${d} = ${N}/${L}.`,
  });
}

function answers(p: FracCompareProblem): AnswerModel {
  const { a, b, c, d } = p, { L, A, C, apart } = parts(p);
  const k = compareIndex(A, C), sign = COMPARE[k];
  const steps: AnswerStep[] = [];
  if (apart) {
    steps.push(oneBox({
      id: "common", label: "A bottom for both", question: `Both need the same size pieces. Count by ${b}s and by ${d}s. What's the first number both reach?`,
      prompt: s => [text("same bottom"), op("="), s], ans: L,
      wrong: slips(L, [[b + d, "Added the bottoms", `Count by ${b}s and by ${d}s instead. Adding them doesn't give a number both go into.`]]),
      hint: `${b}s: ${b}, ${2 * b}, ${3 * b}, … and ${d}s: ${d}, ${2 * d}, … Find the first match.`,
      explain: `${b} × ${d / gcd(b, d)} = ${L} and ${d} × ${b / gcd(b, d)} = ${L}, so both can be cut into ${pieceName(L)}.`,
    }));
  }
  if (L !== b) steps.push(renameStep("first", a, b, L));
  if (L !== d) steps.push(renameStep("second", c, d, L));
  const tops = `${A}/${L} and ${C}/${L}`;
  const why = k === 1 ? `${tops} are the same amount.` : `${A}/${L} has ${count(k === 0 ? "fewer" : "more", "piece")} than ${C}/${L}.`;
  const wrong: Record<number, [string, string]> = {};
  for (const i of [0, 1, 2]) {
    if (i === k) continue;
    if (i === 1) wrong[i] = ["Called them equal", `They'd be equal only with the same number of ${pieceName(L)}. ${A} and ${C} are not the same.`];
    else if (k === 1) wrong[i] = ["Missed that they're equal", `${a}/${b} and ${c}/${d} are both ${A}/${L}: the same amount, cut into different pieces.`];
    else if (compareIndex(a, c) === i) wrong[i] = ["Compared the tops", `Tops only compare when the pieces are the same size. In ${pieceName(L)} they are ${A}/${L} and ${C}/${L}.`];
    else if (compareIndex(b, d) === i) wrong[i] = ["Bigger bottom, bigger fraction", `A bigger bottom means smaller pieces. Compare ${tops} instead.`];
    else wrong[i] = ["Turned the sign around", `${why} So ${a}/${b} ${signName[k]} ${c}/${d}.`];
  }
  steps.push(tapStep({
    id: "compare", label: "Compare", question: `Now the pieces match: ${tops}. Which sign goes between?`,
    prompt: [frac(a, b), text(" ? "), frac(c, d)], choices: COMPARE, ans: k, wrong,
    hint: `Same-size pieces: the one with more pieces is bigger. Compare ${A} and ${C}.`,
    explain: `${why} So ${a}/${b} ${sign} ${c}/${d}.`,
    work: [frac(a, b), op(sign), frac(c, d)],
  }));
  return { steps, finalParts: [-1] };
}

/**
 * Two bars cut into b and d pieces. A bar that needs new pieces is re-cut into L at `cut` and renamed at `name`,
 * so the shaded amounts can be counted in the same pieces; the comparison beat lines up their ends.
 */
export function compareBars(p: FracCompareProblem, at: { cut: number; first: number; second: number; compare: number }) {
  const { a, b, c, d } = p, { L, A, C } = parts(p), k = compareIndex(A, C);
  const row = (n: number, den: number, N: number, name: number, tone: "on" | "two", big: boolean): TapeRow => ({
    length: 1, parts: den === L ? den : [{ count: den, from: 0 }, { count: L, from: Math.min(at.cut, name) }],
    fills: [{ a: 0, b: n / den, tone }],
    label: den === L ? [{ text: `${n}/${den}` }]
      : [{ text: `${n}/${den}`, until: Math.min(at.cut, name) - 1 }, ...(at.cut < name ? [{ text: `?/${L}`, from: at.cut, until: name - 1 }] : []), { text: `${N}/${L}`, from: name }],
    total: big ? [{ text: k === 1 ? "same" : "more", from: at.compare, acc: true }] : [],
  });
  return buildTape({
    rows: [row(a, b, A, at.first, "on", k !== 0), row(c, d, C, at.second, "two", k !== 2)],
    guides: [{ at: a / b, rows: [0, 1], from: at.compare }, ...(k === 1 ? [] : [{ at: c / d, rows: [0, 1] as [number, number], from: at.compare }])],
    alt: `Two bars: ${a}/${b} shaded and ${c}/${d} shaded. In ${pieceName(L)} they are ${A}/${L} and ${C}/${L}, so ${a}/${b} ${signName[k]} ${c}/${d}.`,
    width: 440,
  });
}

function explain(p: FracCompareProblem, model: AnswerModel): Explanation {
  const { a, b, c, d } = p, { L, apart } = parts(p);
  const A = L === b ? a : expectedOf(model, "first"), C = L === d ? c : expectedOf(model, "second");
  const k = compareIndex(A, C), sign = COMPARE[k];
  // beats: the bars; the common bottom (when needed); each renamed fraction; the comparison
  const common = apart ? 1 : 0, first = L === b ? common : common + 1, second = L === d ? first : first + 1, cmp = second + 1;
  const steps: ExplanationStep[] = [
    { id: "start", state: 0, math: [frac(a, b), text(" ? "), frac(c, d)],
      narration: `${cap(pieceName(b))} and ${pieceName(d)} are different sizes, so you can't count pieces yet.` },
  ];
  if (apart) steps.push({ id: "common", state: common, answerStep: "common", result: expectedOf(model, "common"), math: [text(`${b} × ${L / b} = ${L},  ${d} × ${L / d} = ${L}`)],
    narration: `${b} and ${d} both go into ${L}. Cut both wholes into ${pieceName(L)}.` });
  if (L !== b) steps.push({ id: "first", state: first, answerStep: "first", result: A, math: [frac(a, b), op("="), frac(A, L)],
    narration: `Each ${pieceName(b, false)} is ${L / b} ${pieceName(L)}, so ${a}/${b} is ${each(A, L)}.` });
  if (L !== d) steps.push({ id: "second", state: second, answerStep: "second", result: C, math: [frac(c, d), op("="), frac(C, L)],
    narration: `Each ${pieceName(d, false)} is ${L / d} ${pieceName(L)}, so ${c}/${d} is ${each(C, L)}.` });
  steps.push({ id: "compare", state: cmp, answerStep: "compare", math: [frac(a, b), op(sign), frac(c, d)],
    narration: k === 1 ? `${A}/${L} and ${C}/${L}: the same number of pieces. ${a}/${b} = ${c}/${d}.`
      : `${each(A, L)} is ${k === 0 ? "less" : "more"} than ${each(C, L)}, so ${a}/${b} ${sign} ${c}/${d}.` });
  const statement: MathText = [frac(a, b), text(" ? "), frac(c, d)];
  return {
    heading: "Same-size pieces first",
    idea: ["To compare fractions, cut them into same-size pieces. Then the one with more pieces is bigger."],
    statement,
    diagram: compareBars(p, { cut: apart ? common : cmp, first, second, compare: cmp }),
    caption: `Both bars are the same whole, cut into ${pieceName(L)}.`,
    timeline: beats(cmp + 1),
    steps,
  };
}

export const lesson: LessonDefinition<FracCompareProblem> = {
  id: "g4-fraccompare",
  grade: 4,
  unit: "Fractions",
  title: "Comparing fractions",
  pre: "g4-equiv",
  reference: createFracCompare(2, 3, 3, 4),
  generate: (rng, index) => generateFracCompare(rng, index),
  restore: raw => restoreVia(raw, ["a", "b", "c", "d"] as const, v => createFracCompare(v.a, v.b, v.c, v.d)),
  display: p => [frac(p.a, p.b), text(" ? "), frac(p.c, p.d)],
  displayNote: () => "Which is bigger? Pick <, = or >.",
  answers,
  explain,
};
