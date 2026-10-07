import { frac, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import type { TapeRow } from "../../../../explanations/diagrams/tape/schema";
import { pieceName } from "../../_tape-family/steps";
import { box, choice, expectedOf, restoreVia, wholeIn } from "../_kit/steps";
import { count } from "../../../text";

/** Compare a/b with c/d: the same bottom, the same top, or the same amount cut into smaller pieces. */
export interface CompareProblem { a: number; b: number; c: number; d: number }

const DENS = [2, 3, 4, 6, 8];
const SIGNS = ["<", "=", ">"];

export type CompareKind = "bottom" | "top" | "equal";
export function kindOf({ a, b, c, d }: CompareProblem): CompareKind {
  if (b === d && a !== c) return "bottom";
  if (a === c && b !== d) return "top";
  if (a * d === b * c && b !== d) return "equal";
  throw new Error(`${a}/${b} and ${c}/${d} share no top or bottom and are not equal`);
}

export function createCompare(a: number, b: number, c: number, d: number): CompareProblem {
  if (!DENS.includes(b) || !DENS.includes(d)) throw new Error(`3rd grade cuts into ${DENS.join(", ")} parts`);
  wholeIn("a", a, 1, b - 1);
  wholeIn("c", c, 1, d - 1);
  const p = { a, b, c, d };
  kindOf(p);
  return p;
}

/** Early problems share a bottom. Later ones share a bottom or a top, and now and then are the same amount. */
export function generateCompare(rng: Rng, index: number): CompareProblem {
  const r = index < 3 ? 0 : rng.next();
  if (r < 0.4) {
    const b = rng.pick([3, 4, 6, 8]), [a, c] = rng.shuffle(Array.from({ length: b - 1 }, (_, i) => i + 1)).slice(0, 2) as [number, number];
    return createCompare(a, b, c, b);
  }
  if (r < 0.82) {
    let a: number, b: number, d: number;
    do { a = rng.int(1, 3); [b, d] = rng.shuffle(DENS).slice(0, 2) as [number, number]; } while (a >= Math.min(b, d));
    return createCompare(a, b, a, d);
  }
  const [b, k] = rng.pick([[2, 2], [2, 4], [3, 2], [4, 2]] as const), a = rng.int(1, b - 1);
  return rng.next() < 0.5 ? createCompare(a, b, a * k, b * k) : createCompare(a * k, b * k, a, b);
}

const ft = (n: number, d: number) => `${n}/${d}`;
const pair = (p: CompareProblem, mid: MathText): MathText => [frac(p.a, p.b), ...mid, frac(p.c, p.d)];
/** −1, 0 or 1 as a/b is less than, equal to or more than c/d. */
const cmp = ({ a, b, c, d }: CompareProblem) => Math.sign(a * d - c * b);

function compareStep(p: CompareProblem): AnswerStep {
  const { a, b, c, d } = p, s = cmp(p), right = s + 1, kind = kindOf(p);
  const big = s > 0 ? ft(a, b) : ft(c, d), small = s > 0 ? ft(c, d) : ft(a, b);
  const flipped = kind === "top"
    ? `More pieces means smaller pieces. ${big} is bigger, so the sign opens toward ${big}.`
    : `${big} is the bigger amount. The open side of the sign faces the bigger fraction.`;
  const wrong: Record<number, [string, string]> = {};
  if (kind === "equal") {
    wrong[0] = ["Thought they were different", `The shading lines up exactly. ${ft(a, b)} and ${ft(c, d)} are the same amount, cut differently.`];
    wrong[2] = ["Thought they were different", `More pieces does not mean more. The shading lines up exactly, so they are equal.`];
  } else {
    wrong[1] = ["Thought they were equal", kind === "bottom" ? `Same size pieces, but ${big} has more of them.` : `Same number of pieces, but the pieces of ${big} are bigger.`];
    wrong[2 - right] = [kind === "top" ? "Picked the bigger bottom" : "Sign the wrong way", flipped];
  }
  return choice({
    id: "compare", label: "Compare", question: "Tap the sign that makes it true.",
    prompt: pair(p, [text(" ? ")]), choices: SIGNS, right, wrong,
    hint: kind === "equal" ? "Look at where the shading ends on each bar." : `Which is bigger, ${ft(a, b)} or ${ft(c, d)}? The sign opens toward it.`,
    explain: kind === "equal" ? `${ft(a, b)} = ${ft(c, d)}. Same amount.` : `${big} is bigger than ${small}.`,
    work: pair(p, [op(SIGNS[right] as "<" | "=" | ">")]),
  });
}

function answers(p: CompareProblem): AnswerModel {
  const { a, b, c, d } = p, kind = kindOf(p);
  let first: AnswerStep;
  if (kind === "bottom") {
    const right = a > c ? 0 : 1, more = Math.max(a, c), fewer = Math.min(a, c);
    first = choice({
      id: "more", label: "Count the pieces", question: `Both are cut into ${b} equal pieces. Which has more pieces?`,
      prompt: pair(p, [text(" or ")]), choices: [ft(a, b), ft(c, d)], right,
      wrong: { [1 - right]: ["Picked fewer pieces", `${ft(fewer, b)} is only ${count(fewer, "piece")}. ${ft(more, b)} is ${count(more, "piece")} of the same size.`] },
      hint: "The pieces are the same size, so more pieces is more.", explain: `${count(more, "piece")} is more than ${count(fewer, "piece")} of the same size.`,
      work: [frac(more, b), text(` has more ${pieceName(b)}`)],
    });
  } else if (kind === "top") {
    const right = b < d ? 0 : 1, lo = Math.min(b, d), hi = Math.max(b, d);
    first = choice({
      id: "size", label: "Compare the pieces", question: `Both have ${a} ${a === 1 ? "piece" : "pieces"}. Which piece is bigger?`,
      prompt: [frac(1, b), text(" or "), frac(1, d)], choices: [ft(1, b), ft(1, d)], right,
      wrong: { [1 - right]: ["Thought a bigger bottom is bigger", `${hi} is bigger than ${lo}, but cutting a whole into ${count(hi, "piece")} makes each piece smaller. 1/${lo} is bigger.`] },
      hint: "Fewer pieces in the whole means each piece is bigger.", explain: `1/${lo} is bigger than 1/${hi}: ${pieceName(lo)} are bigger than ${pieceName(hi)}.`,
      work: [frac(1, lo), op(">"), frac(1, hi)],
    });
  } else {
    const B = Math.min(b, d), D = Math.max(b, d), k = D / B;
    first = box({
      id: "fit", label: "Fit the small pieces", question: `How many 1/${count(D, "piece")} fit in one 1/${B} piece?`,
      prompt: x => [x, op("×"), frac(1, D), op("="), frac(1, B)], ans: k,
      wrong: [[D, "Counted all the small pieces", `There are ${D} small pieces in the whole bar. How many fit in just one 1/${B} piece?`], [B, "Used the big pieces", `Look at one 1/${B} piece and count the 1/${count(D, "piece")} under it.`]],
      hint: `${D} ÷ ${B} = ${k}. Look at the bars to check.`, explain: `${count(k, "piece")} of 1/${D} fit in each 1/${B}.`,
    });
  }
  return { steps: [first, compareStep(p)], finalParts: [-1] };
}

/** Two bars, one for each fraction, lined up under each other so their shading can be compared. */
export function comparePicture(p: CompareProblem, s: number) {
  const { a, b, c, d } = p, kind = kindOf(p);
  const tag = (mine: number) => (s === 0 ? "same" : mine === s ? "bigger" : "");
  const row = (n: number, m: number, mine: number): TapeRow => ({
    length: 1, parts: m,
    fills: [{ a: 0, b: n / m, tone: "on" }, ...(kind === "top" ? [{ a: 0, b: 1 / m, tone: "acc" as const, from: 1, until: 1 }] : [])],
    each: kind === "bottom" ? [{ text: (i: number) => String(i + 1), from: 1, until: 1, only: (i: number) => i < n }] : kind === "top" ? [{ text: () => `1/${m}`, from: 1, until: 1, only: (i: number) => i === 0 }] : [],
    label: [{ text: ft(n, m) }],
    total: tag(mine) ? [{ text: tag(mine), from: 2, acc: true }] : [],
  });
  return buildTape({
    rows: [row(a, b, 1), row(c, d, -1)],
    guides: [
      ...(kind === "equal" ? [{ at: a / b, rows: [0, 1] as [number, number], from: 1 }] : []),
      { at: a / b, rows: [0, 1], from: 2 }, ...(a / b !== c / d ? [{ at: c / d, rows: [0, 1] as [number, number], from: 2 }] : []),
    ],
    width: 540, maxRowHeight: 56,
    alt: `Two bars the same length: ${ft(a, b)} shaded on top and ${ft(c, d)} shaded below. ${s === 0 ? "The shading ends in the same place." : `${s > 0 ? ft(a, b) : ft(c, d)} reaches further.`}`,
  });
}

function explain(p: CompareProblem, model: AnswerModel): Explanation {
  const { a, b, c, d } = p, kind = kindOf(p), s = expectedOf(model, "compare", "c") - 1;
  const sign = SIGNS[s + 1] as "<" | "=" | ">";
  const big = s > 0 ? ft(a, b) : ft(c, d);
  const first = model.steps[0]!;
  const firstBeat = kind === "bottom"
    ? { narration: `Both bars are cut into ${b} equal pieces. Count the shaded ones: ${a} and ${c}.`, math: [num(a), op(a > c ? ">" : "<"), num(c)] as MathText, result: expectedOf(model, "more", "c") }
    : kind === "top"
      ? { narration: `Both have ${a} shaded ${a === 1 ? "piece" : "pieces"}. A whole cut into ${Math.min(b, d)} has bigger pieces than one cut into ${Math.max(b, d)}.`, math: [frac(1, Math.min(b, d)), op(">"), frac(1, Math.max(b, d))] as MathText, result: expectedOf(model, "size", "c") }
      : { narration: `Each 1/${Math.min(b, d)} piece is the same as ${count(expectedOf(model, "fit"), "piece")} of 1/${Math.max(b, d)}.`, math: [num(expectedOf(model, "fit")), op("×"), frac(1, Math.max(b, d)), op("="), frac(1, Math.min(b, d))] as MathText, result: expectedOf(model, "fit") };
  return {
    heading: kind === "bottom" ? "Same pieces: count them" : kind === "top" ? "Same count: compare the pieces" : "Same amount, different pieces",
    idea: ["To compare fractions, both the size of the pieces and how many there are matter."],
    statement: pair(p, [text(" ? ")]),
    diagram: comparePicture(p, s),
    caption: `Two bars, the same size. One shows ${ft(a, b)} and one shows ${ft(c, d)}.`,
    timeline: beats(3),
    steps: [
      { id: first.id, state: 1, answerStep: first.id, ...firstBeat },
      { id: "compare", state: 2, answerStep: "compare", result: s + 1, math: pair(p, [op(sign)]),
        narration: s === 0 ? `The shading ends in the same place, so ${ft(a, b)} = ${ft(c, d)}.` : `${big} reaches further, so ${ft(a, b)} ${sign} ${ft(c, d)}.` },
    ],
  };
}

export const lesson: LessonDefinition<CompareProblem> = {
  id: "g3-fraccompare",
  grade: 3,
  unit: "Fractions",
  title: "Comparing fractions",
  pre: "g3-unitfrac",
  reference: createCompare(1, 4, 1, 8),
  generate: generateCompare,
  restore: raw => restoreVia(raw, ["a", "b", "c", "d"] as const, v => createCompare(v.a, v.b, v.c, v.d)),
  display: p => pair(p, [text(" ? ")]),
  displayNote: () => "Which is bigger?",
  answers,
  explain,
};
