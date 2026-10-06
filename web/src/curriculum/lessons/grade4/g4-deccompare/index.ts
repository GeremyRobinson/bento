// Comparing decimals (new in the rebuild): name both decimals in hundredths, then the one with more hundredths
// is bigger. 0.5 is 50 hundredths, so it beats 0.45 even though 45 is more than 5.
import { op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildHundredths } from "../../../../explanations/diagrams/early-g4/hundredths";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { COMPARE, compareIndex, signName, slips, tapStep } from "../_kit";

/**
 * w.(a hundredths) compared with w.(b hundredths), both with the same whole number w.
 * pa and pb are how many places after the point each is written with (1 for 0.5, 2 for 0.45 or 0.50).
 */
export interface DecCompareProblem { w: number; a: number; b: number; pa: number; pb: number }

export function createDecCompare(w: number, a: number, b: number, pa: number, pb: number): DecCompareProblem {
  wholeIn("w", w, 0, 9);
  wholeIn("a", a, 1, 99);
  wholeIn("b", b, 1, 99);
  if (![1, 2].includes(pa) || ![1, 2].includes(pb)) throw new Error("one or two places after the point");
  if ((pa === 1 && a % 10) || (pb === 1 && b % 10)) throw new Error("one place after the point means whole tenths");
  if (a === b && pa === pb) throw new Error("the two decimals are written the same");
  return { w, a, b, pa, pb };
}

/** How a decimal is written: 0.5, 0.45, 0.50, 1.07. */
export const written = (w: number, h: number, places: number) => `${w}.${places === 1 ? h / 10 : String(h).padStart(2, "0")}`;
/** The digits after the point read as a whole number: the slip of comparing 45 with 5. */
const afterPoint = (h: number, places: number) => (places === 1 ? h / 10 : h);
const hund = (n: number) => `${n} ${n === 1 ? "hundredth" : "hundredths"}`;
const tenths = (n: number) => `${n} ${n === 1 ? "tenth" : "tenths"}`;
/** "0.5 is 5 tenths" or, with a whole number in front, "after the point, 1.7 has 7 tenths" */
const partIs = (w: number, X: string) => (w ? `After the point, ${X} has` : `${X} is`);

/** Early problems put a tenths decimal against a hundredths one (0.5 and 0.45); later ones have whole numbers in front. */
export function generateDecCompare(rng: Rng, index: number): DecCompareProblem {
  const w = index < 4 ? 0 : rng.int(0, 9), kind = rng.next();
  let a: number, b: number, pa = 2, pb = 2;
  if (kind < 0.45) {
    // the trap: a tenths decimal against a two-place one with a different tenths digit
    const t = rng.int(1, 9);
    let u: number;
    do u = rng.int(0, 9); while (u === t);
    a = 10 * t; pa = 1; b = 10 * u + rng.int(1, 9);
  } else if (kind < 0.75) {
    // same tenths digit: the hundredths decide
    const t = rng.int(0, 9);
    a = 10 * t + rng.int(t ? 0 : 1, 9); b = 10 * t + rng.int(1, 9);
    if (a % 10 === 0 && rng.next() < 0.5) pa = 1;
  } else if (kind < 0.87) {
    // the same amount written two ways
    a = 10 * rng.int(1, 9); b = a; pa = 1;
  } else {
    a = rng.int(1, 99); b = rng.int(1, 99);
  }
  if (a === b && pa === pb) b = b === 99 ? 98 : b + 1;
  if (rng.next() < 0.5) return createDecCompare(w, b, a, pb, pa);
  return createDecCompare(w, a, b, pa, pb);
}

function hundredthsStep(id: string, label: string, w: number, h: number, places: number): AnswerStep {
  const X = written(w, h, places), t = Math.floor(h / 10), u = h % 10;
  const front: MathText = w ? [text(`${w} and `)] : [];
  const wrong: [number, string, string][] = places === 1
    ? [[t, "Read tenths as hundredths", `${partIs(w, X)} ${tenths(t)}. Each tenth is 10 hundredths, so that's ${hund(h)}. Think of it as ${X}0.`]]
    : t === 0
      ? [[u * 10, "Read hundredths as tenths", `The ${u} is in the hundredths place, two after the point. So it's just ${hund(u)}.`]]
      : [[t, "Counted only the tenths", `That's just the tenths. ${X} has ${tenths(t)} and ${hund(u)}, which is ${hund(h)}.`]];
  return oneBox({
    id, label, question: `How many hundredths are after the point in ${X}?`,
    prompt: s => [text(X), op("="), ...front, s, text(" hundredths")], ans: h,
    wrong: slips(h, wrong),
    hint: places === 1 ? `One tenth is 10 hundredths. Put a 0 on the end: ${X}0.` : "Read the two digits after the point as hundredths.",
    explain: places === 1 ? `${partIs(w, X)} ${tenths(t)}, and ${tenths(t)} is ${hund(h)}.` : `The two digits after the point, ${String(h).padStart(2, "0")}, make ${hund(h)}.`,
  });
}

function answers(p: DecCompareProblem): AnswerModel {
  const { w, a, b, pa, pb } = p, X = written(w, a, pa), Y = written(w, b, pb);
  const k = compareIndex(a, b), sign = COMPARE[k];
  const naive = compareIndex(afterPoint(a, pa), afterPoint(b, pb));
  const wrong: Record<number, [string, string]> = {};
  for (const i of [0, 1, 2]) {
    if (i === k) continue;
    if (k === 1) wrong[i] = ["Missed that they're equal", `${X} and ${Y} both have ${hund(a)} after the point. A zero on the end doesn't change the amount.`];
    else if (i === naive) wrong[i] = ["Compared the digits like whole numbers",
      `${afterPoint(a, pa)} and ${afterPoint(b, pb)} aren't the right amounts to compare. ${X} has ${hund(a)} after the point and ${Y} has ${hund(b)}.`];
    else if (i === 1) wrong[i] = ["Called them equal", `They'd be equal only with the same number of hundredths. ${a} and ${b} are not the same.`];
    else wrong[i] = ["Turned the sign around", `${hund(a)} ${signName[k]} ${hund(b)}, so ${X} ${sign} ${Y}.`];
  }
  return {
    steps: [
      hundredthsStep("first", `Hundredths in ${X}`, w, a, pa),
      hundredthsStep("second", `Hundredths in ${Y}`, w, b, pb),
      tapStep({
        id: "compare", label: "Compare", question: `${hund(a)} and ${hund(b)}. Which sign goes between?`,
        prompt: [text(`${X} ? ${Y}`)], choices: COMPARE, ans: k, wrong,
        hint: `Same-size pieces now: compare ${a} and ${b}.`,
        explain: `${hund(a)} ${signName[k]} ${hund(b)}, so ${X} ${sign} ${Y}.`,
        work: [text(X), op(sign), text(Y)],
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: DecCompareProblem, model: AnswerModel): Explanation {
  const { w, pa, pb } = p, A = expectedOf(model, "first"), B = expectedOf(model, "second");
  const X = written(w, A, pa), Y = written(w, B, pb), k = compareIndex(A, B), sign = COMPARE[k];
  const note = (h: number) => (w ? `${w} and ${hund(h)}` : hund(h));
  const cols = (n: number) => `${n} full ${n === 1 ? "column" : "columns"}`, sq = (n: number) => `${n} ${n === 1 ? "square" : "squares"}`;
  const say = (X: string, h: number, places: number) => places === 1
    ? `${partIs(w, X)} ${tenths(h / 10)}: ${cols(h / 10)}, which is ${hund(h)}.`
    : h < 10 ? `${partIs(w, X)} just ${sq(h)} of the grid: ${hund(h)}.`
      : `${partIs(w, X)} ${cols(Math.floor(h / 10))}${h % 10 ? ` and ${sq(h % 10)} more` : ""}: ${hund(h)}.`;
  return {
    heading: "Count the same-size pieces",
    idea: ["Hundredths are all the same size, so the decimal with more hundredths is bigger, however many digits it shows.", "Write both in hundredths to compare them."],
    statement: [text(`${X} ? ${Y}`)],
    diagram: buildHundredths({
      grids: [{ label: X, count: A, note: note(A), beat: 1 }, { label: Y, count: B, note: note(B), beat: 2 }],
      sign: { text: sign, beat: 3 },
      alt: `Two hundredths grids: ${X} shades ${sq(A)} and ${Y} shades ${sq(B)}, so ${X} ${signName[k]} ${Y}.`,
    }),
    caption: w ? `Both have ${w} ${w === 1 ? "whole" : "wholes"}, so the grids show the part after the point.` : "Each grid is one whole: 10 columns of tenths, 100 squares of hundredths.",
    timeline: beats(4),
    steps: [
      { id: "start", state: 0, math: [text(`${X} ? ${Y}`)], narration: "Each grid is one whole, cut into 100 hundredths. Each column is a tenth." },
      { id: "first", state: 1, answerStep: "first", result: A, math: [text(X), op("="), text(note(A))], narration: say(X, A, pa) },
      { id: "second", state: 2, answerStep: "second", result: B, math: [text(Y), op("="), text(note(B))], narration: say(Y, B, pb) },
      { id: "compare", state: 3, answerStep: "compare", math: [text(X), op(sign), text(Y)],
        narration: k === 1 ? `${hund(A)} and ${hund(B)}: the same amount. ${X} = ${Y}.` : `${hund(A)} ${signName[k]} ${hund(B)}, so ${X} ${sign} ${Y}.` },
    ],
  };
}

export const lesson: LessonDefinition<DecCompareProblem> = {
  id: "g4-deccompare",
  grade: 4,
  unit: "Decimals",
  title: "Comparing decimals",
  pre: "g4-dec",
  reference: createDecCompare(0, 50, 45, 1, 2),
  generate: (rng, index) => generateDecCompare(rng, index),
  restore: raw => restoreVia(raw, ["w", "a", "b", "pa", "pb"] as const, v => createDecCompare(v.w, v.a, v.b, v.pa, v.pb)),
  display: p => [text(`${written(p.w, p.a, p.pa)} ? ${written(p.w, p.b, p.pb)}`)],
  displayNote: () => "Which is bigger? Pick <, = or >.",
  answers,
  explain,
};
