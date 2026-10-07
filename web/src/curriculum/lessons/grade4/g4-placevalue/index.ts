// Place value and rounding (new in the rebuild): find the digit in a named place, the round numbers on either side,
// the digit next door that decides, and round.
import { op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildRounding, commas } from "../../../../explanations/diagrams/early-g4/place-value";
import { expectedOf, manyBoxes, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { boxSlips, slips } from "../_kit";
import { aNum } from "../../../text";

/** n rounded to the nearest `place` (10, 100, 1,000, 10,000 or 100,000). */
export interface RoundProblem { n: number; place: number }

const PLACES = [10, 100, 1000, 10000, 100000] as const;
/** "thousand": the round number a place counts in */
const ONE: Record<number, string> = { 1: "one", 10: "ten", 100: "hundred", 1000: "thousand", 10000: "ten thousand", 100000: "hundred thousand" };
/** "thousands place" */
const placeOf = (v: number) => `${ONE[v]}s place`;

export function createRound(n: number, place: number): RoundProblem {
  if (!PLACES.includes(place as (typeof PLACES)[number])) throw new Error(`can't round to ${place}`);
  wholeIn("n", n, 10, 999999);
  if (n < place) throw new Error(`${n} has no ${placeOf(place)}`);
  if (n % place === 0) throw new Error(`${n} is already a round ${ONE[place]}`);
  return { n, place };
}

/** Early problems are four-digit numbers rounded to the tens or hundreds; later ones go up to six digits. */
export function generateRound(rng: Rng, index: number): RoundProblem {
  const [digits, places] = index < 3 ? [4, [10, 100]] : index < 6 ? [5, [100, 1000, 10000]] : [6, [1000, 10000, 100000]];
  const place = rng.pick(places);
  let n: number;
  do n = rng.int(10 ** (digits - 1), 10 ** digits - 1);
  while (n % place === 0 || Math.floor(n / (place / 10)) % 10 === 0 && rng.next() < 0.7);
  return createRound(n, place);
}

/** Everything the steps and the picture need, from the problem. */
export function roundParts({ n, place }: RoundProblem) {
  const lo = Math.floor(n / place) * place, hi = lo + place;
  const d = Math.floor(n / place) % 10, next = Math.floor(n / (place / 10)) % 10;
  const up = next >= 5, R = up ? hi : lo;
  return { lo, hi, d, next, up, R, left: Math.floor(n / (place * 10)) % 10 };
}

function answers(p: RoundProblem): AnswerModel {
  const { n, place } = p, { lo, hi, d, next, up, R, left } = roundParts(p);
  const N = commas(n), name = placeOf(place), lower = placeOf(place / 10), small = place / 10;
  const finer = Math.round(n / small) * small;
  return {
    steps: [
      oneBox({
        id: "digit", label: "Find the place", question: `Which digit of ${N} is in the ${name}?`,
        prompt: s => [text(`${ONE[place]}s digit`), op("="), s], ans: d,
        wrong: slips(d, [
          [next, "Looked one place too far right", `${next} is in the ${lower}. The ${name} is one step to the left.`],
          ...(n >= place * 10 ? [[left, "Looked one place too far left", `${left} is in the ${placeOf(place * 10)}. The ${name} is one step to the right.`] as [number, string, string]] : []),
        ]),
        hint: `Count places from the right: ones, tens, hundreds, and so on, until you reach the ${name}.`,
        explain: `Count from the right until you reach the ${name}. The digit there is ${d}.`,
      }),
      manyBoxes({
        id: "between", label: "Between which?", question: `${N} sits between two round ${ONE[place]}s. Which ones?`,
        prompt: b => [b.lo!, op("<"), text(N), op("<"), b.hi!], ans: { lo, hi },
        wrong: boxSlips({ lo, hi }, [
          [{ lo: lo / place, hi: hi / place }, "Dropped the zeros", `Keep the zeros: ${lo / place} ${ONE[place]}s is written ${commas(lo)}.`],
          ...(small >= 10 ? [[{ lo: Math.floor(n / small) * small, hi: Math.floor(n / small) * small + small }, "Used the wrong place", `Those are round ${ONE[small]}s. Count by ${commas(place)}s instead.`] as [Record<string, number>, string, string]] : []),
        ]),
        hint: `Keep the digits up to the ${name} and make the rest zeros. That's the one below. Add ${commas(place)} for the one above.`,
        explain: `Keep the digits up to the ${name} and make the rest zeros: ${commas(lo)}. One ${ONE[place]} more is ${commas(hi)}.`,
      }),
      oneBox({
        id: "next", label: "Look next door", question: `The digit just right of the ${name} decides. What is it?`,
        prompt: s => [text("next digit"), op("="), s], ans: next,
        wrong: slips(next, [[d, "Read the place itself", `${d} is the ${ONE[place]}s digit. Look one place to its right, in the ${lower}.`]]),
        hint: `Look one place to the right of the ${name}.`,
        explain: `The digit in the ${lower} is ${next}. ${up ? "That's 5 or more, so round up." : "That's less than 5, so round down."}`,
      }),
      oneBox({
        id: "round", label: "Round", prompt: s => [text(N), op("≈"), s], ans: R,
        wrong: slips(R, [
          [up ? lo : hi, up ? "Rounded down instead of up" : "Rounded up instead of down",
            up ? `The next digit is ${next}. 5 or more rounds up, to ${commas(hi)}.` : `The next digit is ${next}. Less than 5 rounds down, to ${commas(lo)}.`],
          [R + (n % place), "Kept the digits after the place", `A rounded number ends in zeros. Every digit after the ${name} becomes 0.`],
          [finer, "Rounded to the wrong place", `That's ${N} to the nearest ${ONE[small]}. Round to the nearest ${ONE[place]} instead.`],
        ]),
        hint: "Is the next digit 5 or more, or less than 5? That decides which of your two round numbers it goes to.",
        explain: `The next digit is ${next}, so ${N} rounds ${up ? "up" : "down"} to ${commas(R)}.`,
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: RoundProblem, model: AnswerModel): Explanation {
  const { n, place } = p, { up } = roundParts(p), N = commas(n), name = placeOf(place);
  const d = expectedOf(model, "digit"), lo = expectedOf(model, "between", "lo"), hi = expectedOf(model, "between", "hi");
  const next = expectedOf(model, "next"), R = expectedOf(model, "round"), mid = lo + place / 2;
  return {
    heading: "Which round number is closer?",
    idea: ["Rounding finds the closest round number, and the next digit shows which side of halfway it's on."],
    statement: [text(N), op("≈"), text("?")],
    diagram: buildRounding({
      n, place, lo, hi, result: R, beats: { place: 1, line: 2, next: 3, round: 4 },
      alt: `A place-value chart of ${N} with the ${name} lit up, over a number line from ${commas(lo)} to ${commas(hi)}. ${N} is ${n === mid ? "exactly at" : up ? "past" : "before"} the halfway mark, ${commas(mid)}, so it rounds to ${commas(R)}.`,
    }),
    caption: `Halfway between ${commas(lo)} and ${commas(hi)} is ${commas(mid)}.`,
    timeline: beats(5),
    steps: [
      { id: "start", state: 0, narration: `Here is ${N}, one digit in each place. We'll round it to the nearest ${ONE[place]}.`, math: [text(N)] },
      { id: "digit", state: 1, answerStep: "digit", result: d, math: [text(`${ONE[place]}s digit`), op("="), text(String(d))],
        narration: `The ${name} holds ${aNum(d)}.` },
      { id: "between", state: 2, answerStep: "between", result: lo, math: [text(commas(lo)), op("<"), text(N), op("<"), text(commas(hi))],
        narration: `So ${N} sits between ${commas(lo)} and ${commas(hi)} on the number line.` },
      { id: "next", state: 3, answerStep: "next", result: next, math: [text("next digit"), op("="), text(String(next))],
        narration: `The digit next door is ${next}. ${up ? `That's 5 or more, so ${N} is at or past the halfway mark, ${commas(mid)}.` : `That's less than 5, so ${N} is before the halfway mark, ${commas(mid)}.`}` },
      { id: "round", state: 4, answerStep: "round", result: R, math: [text(N), op("≈"), text(commas(R))],
        narration: n === mid ? `It's exactly halfway, and halfway rounds up, so ${N} rounds up to ${commas(R)}.`
          : `It's closer to ${commas(R)}, so ${N} rounds ${up ? "up" : "down"} to ${commas(R)}.` },
    ],
  };
}

export const lesson: LessonDefinition<RoundProblem> = {
  id: "g4-placevalue",
  grade: 4,
  unit: "Whole numbers",
  title: "Place value and rounding",
  pre: "g3-round",
  reference: createRound(47382, 1000),
  generate: (rng, index) => generateRound(rng, index),
  restore: raw => restoreVia(raw, ["n", "place"] as const, v => createRound(v.n, v.place)),
  display: p => [text(commas(p.n))],
  displayNote: p => `Round to the nearest ${ONE[p.place]}.`,
  answers,
  explain,
};
