// Rounding decimals (the current app's g5-round): find the place, look one place to the right, round.
import { formatNumber as f, muted, num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildNumberLine, type Hop, type Mark } from "../../../../explanations/diagrams/number-line/build";
import { expectedOf, oneBox, restoreVia, round6, wholeIn } from "../../_number-line/steps";
import { slips } from "../../grade4/_kit";

/** the number N / 1000 (three decimal places), rounded to p places (1: tenths, 2: hundredths) */
export interface RoundProblem { N: number; p: number }

export function createRound(N: number, p: number): RoundProblem {
  wholeIn("N", N, 1001, 99999);
  wholeIn("p", p, 1, 2);
  return { N, p };
}

const parts = ({ N, p }: RoundProblem) => {
  const unit = 10 ** (3 - p);
  return {
    name: p === 1 ? "tenths" : "hundredths",
    value: N / 1000,
    digit: Math.floor(N / unit) % 10,
    next: Math.floor(N / (unit / 10)) % 10,
    /** rounded down (truncated) and rounded */
    T: Math.floor(N / unit) / 10 ** p,
    R: Math.round(N / unit) / 10 ** p,
  };
};

function answers(pr: RoundProblem): AnswerModel {
  const { p } = pr, { name, value, digit, next, T, R } = parts(pr);
  const at = (place: number) => Math.floor(pr.N / 10 ** (3 - place)) % 10; // 0 ones, 1 tenths, 2 hundredths, 3 thousandths
  const other = p === 1 ? "hundredths" : "tenths";
  return {
    steps: [
      oneBox({ id: "digit", label: `Find the ${name} place`, question: `Which digit is in the ${name} place?`, prompt: s => [s], ans: digit,
        hint: `The ${name} place is ${p} digit${p > 1 ? "s" : ""} after the point.`,
        wrong: slips(digit, [
          [at(3 - p), `Read the ${other} place`, `That's the ${other} digit. The ${name} place is ${p} digit${p > 1 ? "s" : ""} after the point.`],
          [at(p - 1), "Looked one place too far left", `Start just after the point and count ${p} digit${p > 1 ? "s" : ""}.`],
        ]) }),
      oneBox({ id: "next", label: "Look next door", question: "Which digit is just to its right?", prompt: s => [s], ans: next, hint: "Look one place further right.",
        wrong: slips(next, [[digit, "Read the place itself", `${digit} is the ${name} digit. The one that decides sits just to its right.`]]) }),
      oneBox({
        id: "round", label: "Round", question: "5 or more rounds up. 4 or less stays.", prompt: s => [num(value), op("≈"), s], ans: R, hint: `The next digit is ${next}.`,
        wrong: [
          ...(R === T ? [[round6(T + 10 ** -p), "Rounded up when it should stay", `${next} is 4 or less, so the digit stays the same.`] as [number, string, string]]
            : [[T, "Didn't round up", `${next} is 5 or more, so round up.`] as [number, string, string]]),
          // the commonest slip: rounding to the other place (51.647 to hundredths given as 51.6) (fixes-02 A2)
          [Math.round(pr.N / 10 ** p) / 10 ** (3 - p), "Rounded to the wrong place", `Round to the ${name}: that's ${p} digit${p > 1 ? "s" : ""} after the point.`],
        ],
      }),
    ],
    finalParts: [-1],
  };
}

function explain(pr: RoundProblem, model: AnswerModel): Explanation {
  const { p } = pr, { name, value, T } = parts(pr);
  const digit = expectedOf(model, "digit"), next = expectedOf(model, "next"), R = expectedOf(model, "round");
  const place = 10 ** -p, up = round6(T + place), half = round6(T + place / 2), tick = place / 10;
  const halfway = Math.abs(value - half) < 1e-9, stays = Math.abs(R - T) < 1e-9;
  const marks: Mark[] = [
    { v: value, label: f(value), beat: 0 }, // stays to the end, so the picture still shows which number was rounded (review v43 item 7)
    { v: half, beat: 1, cls: "dota" },
  ];
  const hops: Hop[] = Math.abs(value - R) > 1e-9 ? [{ from: value, to: R, label: halfway ? "halfway: up" : "closer", beat: 2, start: false }] : [];
  if (!hops.length) marks.push({ v: R, beat: 2, cls: "dota" });
  return {
    heading: "Look one place to the right",
    idea: ["Rounding picks the closer number, and a next digit of 5 marks halfway."],
    statement: [num(value), op("≈"), text("?"), muted(` (nearest ${name.slice(0, -1)})`)],
    diagram: buildNumberLine({
      min: T, max: up, step: tick, every: 10, labelAt: [half], marks, hops,
      alt: `Number line from ${f(T)} to ${f(up)} with ${f(value)} marked; it rounds to ${f(R)}.`,
    }),
    caption: halfway ? `${f(value)} is exactly halfway, and halfway rounds up to ${f(R)}.` : `${f(value)} is closer to ${f(R)}.`,
    timeline: beats(3),
    steps: [
      { id: "digit", narration: `${f(value)} sits between ${f(T)} and ${f(up)}. Its ${name} digit is ${digit}.`, math: [text(`${name} digit: `), num(digit)], state: 0, answerStep: "digit", result: digit },
      { id: "next", narration: `The digit just to its right is ${next}. Halfway between is ${f(half)}.`, math: [text("next digit: "), num(next)], state: 1, answerStep: "next", result: next },
      { id: "round", narration: stays ? `${next} is 4 or less, so the ${name} digit stays: ${f(R)}.` : `${next} is 5 or more, so round up: ${f(R)}.`,
        math: [num(value), op("≈"), num(R)], state: 2, answerStep: "round", result: R },
    ],
  };
}

export const lesson: LessonDefinition<RoundProblem> = {
  id: "g5-round",
  grade: 5,
  unit: "Decimals",
  title: "Rounding decimals",
  pre: "g4-dec",
  reference: createRound(3476, 2), // 3.476 ≈ 3.48, the current app's example
  // a number with nothing past the place (69.320 to hundredths) is already rounded; give it a digit there
  generate: (rng, index) => {
    // problem 6 always rolls a 9 over (4.96 → 5.0, 3.795 → 3.80), which hardly ever comes up by chance (fixes-02 A2)
    if (index === 5) {
      const p = rng.int(1, 2), W = rng.int(1, 99);
      const dec = p === 1 ? 900 + 10 * rng.int(5, 9) + rng.int(0, 9) : 100 * rng.int(0, 9) + 90 + rng.int(5, 9);
      return createRound(W * 1000 + dec, p);
    }
    // the first three: a one-digit whole part, rounded to tenths
    const N = index < 3 ? rng.int(1001, 9999) : rng.int(1001, 99999), p = index < 3 ? 1 : rng.int(1, 2), unit = 10 ** (3 - p);
    return createRound(N % unit ? N : N + rng.int(1, unit - 1), p);
  },
  restore: raw => restoreVia(raw, ["N", "p"] as const, v => createRound(v.N, v.p)),
  display: p => [num(p.N / 1000)],
  displayNote: p => `Round to the nearest ${p.p === 1 ? "tenth" : "hundredth"}.`,
  answers,
  explain,
};
