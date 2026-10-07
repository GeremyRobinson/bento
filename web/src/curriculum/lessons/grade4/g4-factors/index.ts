// Factors and multiples (new in the rebuild): find the factor pairs of n by making rectangles of n squares,
// check whether n is a multiple of one more number, then count the factors.
import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildFactorRects } from "../../../../explanations/diagrams/early-g4/factor-rects";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { slips, tapStep } from "../_kit";
import { count, isAre } from "../../../text";

/** The factor pairs of n, and a check: is n a multiple of t? */
export interface FactorsProblem { n: number; t: number }

/** The small half of each factor pair, smallest first (1 always). */
export const smallFactors = (n: number) => Array.from({ length: Math.floor(Math.sqrt(n)) }, (_, i) => i + 1).filter(a => n % a === 0);
export const factorsOf = (n: number) => {
  const s = smallFactors(n);
  return [...new Set([...s, ...s.map(a => n / a).reverse()])];
};

/** Numbers from 12 to 60 with exactly three factor pairs: 1 × n and two more. */
export const NUMBERS = Array.from({ length: 49 }, (_, i) => i + 12).filter(n => smallFactors(n).length === 3);

export function createFactors(n: number, t: number): FactorsProblem {
  if (!NUMBERS.includes(n)) throw new Error(`${n} isn't a number with three factor pairs from 12 to 60`);
  wholeIn("t", t, 3, 9);
  if (smallFactors(n).includes(t)) throw new Error(`${t} is already one of the pairs`);
  if (t > n / 2) throw new Error(`${t} is too big a try for ${n}`);
  return { n, t };
}

/** Early problems use numbers up to 32. The try is a factor about half the time. */
export function generateFactors(rng: Rng, index: number): FactorsProblem {
  const n = rng.pick(NUMBERS.filter(x => (index < 3 ? x <= 32 : true)));
  const tries = [3, 4, 5, 6, 7, 8, 9].filter(t => !smallFactors(n).includes(t) && t <= n / 2);
  const yes = tries.filter(t => n % t === 0), no = tries.filter(t => n % t !== 0);
  const t = yes.length && (rng.next() < 0.5 || !no.length) ? rng.pick(yes) : rng.pick(no);
  return createFactors(n, t);
}

const YES_NO = ["Yes", "No"] as const;

function answers({ n, t }: FactorsProblem): AnswerModel {
  const [, a1, a2] = smallFactors(n) as [number, number, number];
  const all = factorsOf(n), pairs = smallFactors(n).length, square = a2 * a2 === n, isMultiple = n % t === 0;
  const q = Math.floor(n / t), r = n % t;
  const pairStep = (id: string, a: number) => oneBox({
    id, label: `Pair with ${a}`, question: `${count(a, "row")} of how many squares make ${n}?`,
    prompt: s => [num(a), op("×"), s, op("="), num(n)], ans: n / a,
    wrong: slips(n / a, [
      [n - a, "Subtracted instead", `That's ${n} − ${a}. Look for the number that ${a} times makes ${n}.`],
      [a, "Used the same number", `${a} × ${a} = ${a * a}, not ${n}.`],
    ]),
    hint: `Count by ${a}s until you reach ${n}. How many ${a}s did you count?`,
    explain: `${a} × ${n / a} = ${n}, so ${a} and ${n / a} are a factor pair.`,
  });
  return {
    steps: [
      pairStep("pair1", a1),
      pairStep("pair2", a2),
      tapStep({
        id: "multiple", label: "Is it a multiple?", question: `Is ${n} a multiple of ${t}?`,
        prompt: [text(`${n} ÷ ${t}`)], choices: YES_NO, ans: isMultiple ? 0 : 1,
        wrong: isMultiple
          ? { 1: ["Missed a multiple", `Count by ${t}s: you land right on ${n}. ${t} × ${q} = ${n}, so ${n} is a multiple of ${t}.`] }
          : { 0: ["Not a multiple", `Count by ${t}s: ${t * q}, then ${t * (q + 1)}. You skip right over ${n}, with ${r} left over.`] },
        hint: `Count by ${t}s. Do you land exactly on ${n}?`,
        explain: isMultiple ? `${t} × ${q} = ${n}, so yes, ${n} is a multiple of ${t}.` : `${t} × ${q} = ${t * q} and ${r} ${isAre(r)} left over, so no, ${n} is not a multiple of ${t}.`,
        work: [text(isMultiple ? `${n} = ${t} × ${q}: yes` : `${n} = ${t} × ${q} + ${r}: no`)],
      }),
      oneBox({
        id: "count", label: "Count the factors", question: `List every factor of ${n}. How many are there?`,
        prompt: s => [text(`factors of ${n}`), op("="), s], ans: all.length,
        wrong: slips(all.length, [
          [pairs, "Counted pairs", `There are ${pairs} pairs, but each pair has two factors${square ? `, except ${a2} × ${a2}, which uses ${a2} once` : ""}.`],
          ...(square ? [[2 * pairs, "Counted a factor twice", `${a2} × ${a2} uses the same factor twice. Count ${a2} only once.`] as [number, string, string]] : []),
          [all.length - 2, "Left out 1 and the number", `1 and ${n} are factors too: 1 × ${n} = ${n}.`],
        ]),
        hint: `Write each pair: 1 and ${n}, ${a1} and ${n / a1}, ${a2} and ${n / a2}. Count them all.`,
        explain: `The factors of ${n} are ${all.join(", ")}. That's ${all.length}.`,
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: FactorsProblem, model: AnswerModel): Explanation {
  const { n, t } = p, [, a1, a2] = smallFactors(n) as [number, number, number];
  const b1 = expectedOf(model, "pair1"), b2 = expectedOf(model, "pair2"), total = expectedOf(model, "count");
  const all = factorsOf(n), q = Math.floor(n / t), r = n % t;
  return {
    heading: "Make every rectangle",
    idea: ["Factors multiply to make a number, and each rectangle shows one pair."],
    statement: [text(`factors of ${n}`)],
    diagram: buildFactorRects({
      n, pairs: [{ a: 1, b: n, beat: 0 }, { a: a1, b: b1, beat: 1 }, { a: a2, b: b2, beat: 2 }],
      test: { t, beat: 3 }, list: { text: all.join(", "), beat: 4 },
      alt: `${count(n, "square")} arranged as 1 × ${n}, ${a1} × ${b1} and ${a2} × ${b2}. In ${count(t, "row")} ${r ? `${r} ${r === 1 ? "is" : "are"} left over` : `they make ${t} × ${q}`}. The factors are ${all.join(", ")}.`,
    }),
    caption: `${count(n, "square")}, in every rectangle they can make.`,
    timeline: beats(5),
    steps: [
      { id: "start", state: 0, math: [num(1), op("×"), num(n), op("="), num(n)], narration: `Every number makes a long row: 1 × ${n}. So 1 and ${n} are factors.` },
      { id: "pair1", state: 1, answerStep: "pair1", result: b1, math: [num(a1), op("×"), num(b1), op("="), num(n)], narration: `Put the squares in ${count(a1, "row")}: ${b1} in each. ${a1} and ${b1} are a pair.` },
      { id: "pair2", state: 2, answerStep: "pair2", result: b2, math: [num(a2), op("×"), num(b2), op("="), num(n)],
        narration: a2 === b2 ? `${count(a2, "row")} of ${b2} make a square. ${a2} pairs with itself.` : `In ${count(a2, "row")} there are ${b2} in each. ${a2} and ${b2} are a pair.` },
      { id: "multiple", state: 3, answerStep: "multiple", math: [text(r ? `${n} = ${t} × ${q} + ${r}` : `${n} = ${t} × ${q}`)],
        narration: r ? `Try ${count(t, "row")}: ${r} ${r === 1 ? "square is" : "squares are"} left over. ${n} is not a multiple of ${t}.` : `Try ${count(t, "row")}: they come out even, ${q} in each. ${n} is a multiple of ${t}.` },
      { id: "count", state: 4, answerStep: "count", result: total, math: [text(all.join(", "))], narration: `List both numbers of every pair: ${all.join(", ")}. That's ${total} factors.` },
    ],
  };
}

export const lesson: LessonDefinition<FactorsProblem> = {
  id: "g4-factors",
  grade: 4,
  unit: "Whole numbers",
  title: "Factors and multiples",
  pre: "g3-facts",
  reference: createFactors(20, 3),
  generate: (rng, index) => generateFactors(rng, index),
  restore: raw => restoreVia(raw, ["n", "t"] as const, v => createFactors(v.n, v.t)),
  display: p => [text(`factors of ${p.n}`)],
  displayNote: p => `Find the factor pairs. Is ${p.n} a multiple of ${p.t}?`,
  answers,
  explain,
};
