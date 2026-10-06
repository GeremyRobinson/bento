import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildNumberLine } from "../../../../explanations/diagrams/number-line/build";
import { box, boxes, expectedOf, restoreVia, wholeIn } from "../_kit/steps";

/** Round n to the nearest ten (to = 10) or hundred (to = 100). */
export interface RoundProblem { n: number; to: number }

export function createRound(n: number, to: number): RoundProblem {
  if (to !== 10 && to !== 100) throw new Error("round to 10 or 100");
  wholeIn("n", n, 11, 999);
  if (n % to === 0) throw new Error(`${n} is already a multiple of ${to}`);
  if (to === 100 && n < 100) throw new Error("rounding to 100 uses three-digit numbers");
  return { n, to };
}

/** Early problems round two-digit numbers to 10; later ones round three-digit numbers to 10 or 100. Some land exactly halfway. */
export function generateRound(rng: Rng, index: number): RoundProblem {
  const to = index < 3 ? 10 : rng.pick([10, 100]);
  const lo = index < 3 ? rng.int(1, 9) * 10 : to === 10 ? rng.int(10, 99) * 10 : rng.int(1, 9) * 100;
  const half = rng.next() < 0.25;
  const off = half ? to / 2 : to === 10 ? rng.int(1, 9) : rng.int(1, 99);
  return createRound(lo + (off % to === 0 ? 1 : off), to);
}

const place = (to: number, many = true) => (to === 10 ? (many ? "tens" : "ten") : many ? "hundreds" : "hundred");

/** The two multiples around n, the halfway mark, and the answer. */
export function roundParts({ n, to }: RoundProblem) {
  const lo = Math.floor(n / to) * to, hi = lo + to, mid = lo + to / 2;
  return { lo, hi, mid, ans: n >= mid ? hi : lo };
}

function answers(p: RoundProblem): AnswerModel {
  const { n, to } = p, { lo, hi, mid, ans } = roundParts(p);
  const lo10 = Math.floor(n / 10) * 10;
  const other = ans === hi ? lo : hi;
  const otherWhy = ans === lo
    ? `${n} is less than the halfway mark ${mid}, so it is closer to ${lo}.`
    : n === mid ? `${n} is exactly halfway. A number exactly halfway rounds up, to ${hi}.`
    : `${n} is past the halfway mark ${mid}, so it is closer to ${hi}.`;
  return {
    steps: [
      boxes({
        id: "between", label: `Find the ${place(to)} around it`, question: `${n} is between which two ${place(to)}?`,
        prompt: b => [b.lo!, text(" and "), b.hi!], ans: { lo, hi },
        wrong: [
          ...(to === 100 ? [[{ lo: lo10, hi: lo10 + 10 }, "Used tens", `Those are tens. This rounds to the nearest hundred, so look for hundreds.`] as [Record<string, number>, string, string]] : []),
          [{ lo: lo - to, hi: lo }, "One step too low", `${n} is more than ${lo}. Look for the ${place(to, false)} just above it.`],
          [{ lo: hi, hi: hi + to }, "One step too high", `${n} is less than ${hi}. Look for the ${place(to, false)} just below it.`],
        ],
        hint: `Count by ${to}s. Which two do you pass ${n} between?`,
        explain: `Counting by ${to}s, ${n} comes after ${lo} and before ${hi}.`,
      }),
      box({
        id: "mid", label: "Find halfway", question: `What number is halfway between ${lo} and ${hi}?`,
        prompt: x => [text("halfway "), op("="), x], ans: mid,
        wrong: to === 100
          ? [[lo + 5, "Halfway to the next ten", `Halfway between ${lo} and ${hi} is 50 more than ${lo}, not 5.`], [lo + 10, "Used ten more", `Halfway between ${lo} and ${hi} is 50 more than ${lo}.`]]
          : [[lo + 1, "Went one more", `Halfway between ${lo} and ${hi} is 5 more than ${lo}.`]],
        hint: `Halfway is ${to / 2} more than ${lo}.`,
        explain: `${lo} + ${to / 2} = ${mid}, halfway between ${lo} and ${hi}.`,
      }),
      box({
        id: "round", label: "Round", question: `Is ${n} closer to ${lo} or to ${hi}?`,
        prompt: x => [num(n), op("≈"), x], ans,
        wrong: [
          [other, n === mid ? "Rounded halfway down" : ans === hi ? "Rounded down" : "Rounded up", otherWhy],
          ...(to === 100 ? [[Math.round(n / 10) * 10, "Rounded to ten", `That's the nearest ten. Round to the nearest hundred: ${lo} or ${hi}.`] as [number, string, string]] : []),
        ],
        hint: n >= mid ? `${n} is at or past halfway (${mid}), so it rounds up.` : `${n} is below halfway (${mid}), so it rounds down.`,
        explain: n === mid ? `${n} is exactly halfway, and halfway rounds up: ${ans}.` : `${n} is closer to ${ans}, so ${n} rounds to ${ans}.`,
      }),
    ],
    finalParts: [-1],
  };
}

/** The line from lo to hi: n on it, then halfway, then a hop to the nearer end. */
export function roundPicture(p: RoundProblem, ans: number) {
  const { n, to } = p, { lo, hi, mid } = roundParts(p);
  return buildNumberLine({
    min: lo, max: hi, step: to / 10, every: 5, width: 540,
    marks: [
      { v: n, label: String(n), beat: 0, cls: "dota" },
      { v: lo, beat: 1 }, { v: hi, beat: 1 },
      { v: mid, label: "halfway", beat: 2, cls: n === mid ? "dota" : "hole" },
    ],
    spans: [{ from: Math.min(n, ans), to: Math.max(n, ans), label: `${Math.abs(ans - n)} away from ${ans}`, beat: 3 }],
    alt: `A number line from ${lo} to ${hi} with ${n} marked. Halfway is ${mid}. ${n} is ${Math.abs(ans - n)} away from ${ans}, so it rounds to ${ans}.`,
  });
}

function explain(p: RoundProblem, model: AnswerModel): Explanation {
  const { n, to } = p, { mid } = roundParts(p);
  const lo = expectedOf(model, "between", "lo"), hi = expectedOf(model, "between", "hi");
  const m = expectedOf(model, "mid"), R = expectedOf(model, "round");
  return {
    heading: `Round to the nearest ${place(to, false)}`,
    idea: ["Find the two numbers it sits between, and the halfway mark.", "Round to the one it is closer to. Exactly halfway rounds up."],
    statement: [num(n), op("≈"), text("?")],
    diagram: roundPicture(p, R),
    caption: `${n} on a number line from ${lo} to ${hi}.`,
    timeline: beats(4),
    steps: [
      { id: "between", state: 1, answerStep: "between", result: lo, math: [num(lo), op("<"), num(n), op("<"), num(hi)],
        narration: `${n} sits between ${lo} and ${hi}.` },
      { id: "mid", state: 2, answerStep: "mid", result: m, math: [num(lo), op("+"), num(to / 2), op("="), num(m)],
        narration: `Halfway between them is ${m}.` },
      { id: "round", state: 3, answerStep: "round", result: R, math: [num(n), op("≈"), num(R)],
        narration: n === mid ? `${n} is right on halfway. Halfway rounds up, so ${n} rounds to ${R}.`
          : `${n} is ${n > mid ? "past" : "before"} halfway, only ${Math.abs(R - n)} away from ${R}. So ${n} rounds to ${R}.` },
    ],
  };
}

export const lesson: LessonDefinition<RoundProblem> = {
  id: "g3-round",
  grade: 3,
  unit: "Place value",
  title: "Rounding to 10 and 100",
  pre: "g2-hundreds",
  reference: createRound(347, 100),
  generate: generateRound,
  restore: raw => restoreVia(raw, ["n", "to"] as const, v => createRound(v.n, v.to)),
  display: p => [text("Round "), num(p.n), text(` to the nearest ${place(p.to, false)}`)],
  answers,
  explain,
};
