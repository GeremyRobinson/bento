// Write numbers 0 to 20: count the dots, then pick how the number is written from look-alikes.
import { num, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { writeNumber } from "../../../../explanations/diagrams/early-k/numerals";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { countUp, slips, tapStep, words } from "../kit";
import { count, isAre } from "../../../text";

/** n dots, 0 to 20 */
export interface WriteProblem { n: number }

export function createWrite(n: number): WriteProblem {
  wholeIn("n", n, 0, 20);
  return { n };
}

/** digits that are easy to mix up when reading */
const LOOKS: Record<number, number> = { 6: 9, 9: 6, 2: 5, 5: 2, 3: 8, 8: 3, 1: 7, 7: 1, 4: 9 };
/** what each digit's shape looks like, so a look-alike slip can say what tells them apart */
const SHAPE: Record<number, string> = {
  0: "0 is one closed ring", 1: "1 is one straight line down", 2: "2 curves on top and sits on a flat line",
  3: "3 has two bumps and is open on the left", 4: "4 has a corner and a line straight down", 5: "5 has a flat hat on top and a round belly",
  6: "6 has its loop at the bottom", 7: "7 has a flat line on top, then slants down", 8: "8 has two closed loops, one on top of the other",
  9: "9 has its loop at the top",
};
const swap = (n: number) => Number(String(n).split("").reverse().join(""));

/** the right numeral and two look-alikes, in an order fixed by the number */
export function choicesOf(n: number): number[] {
  const near = n === 0 ? 1 : n === 20 ? 19 : n % 2 ? n + 1 : n - 1;
  let others: number[];
  if (n === 0) others = [1, 8];
  else if (n === 10 || n === 20) others = [near, n === 10 ? 20 : 10];
  else if (n > 10) others = n === 11 ? [10, 12] : [swap(n), near];
  else others = [LOOKS[n]!, near === LOOKS[n] ? (n > 1 ? n - 1 : n + 1) : near];
  const all = [n, ...others], k = n % 3;
  return [...all.slice(k), ...all.slice(0, k)];
}

function answers({ n }: WriteProblem): AnswerModel {
  const options = choicesOf(n), right = options.indexOf(n);
  return {
    steps: [
      oneBox({
        id: "count", label: "Count", question: "How many dots?",
        prompt: x => [text("Dots: "), x], ans: n,
        wrong: slips(n, [
          [n - 1, "Skipped a dot", "One short. Touch each dot as you count."],
          [n + 1, "Counted a dot twice", "One too many. Touch each dot only once."],
        ]),
        hint: n === 0 ? "Are there any dots?" : "Touch each dot and count.",
        explain: n === 0 ? "There are no dots at all. None is 0." : `${countUp(1, n)}. There ${isAre(n)} ${count(n, "dot")}.`,
      }),
      tapStep({
        id: "write", label: "Pick how it's written", question: `Which one says ${n}?`,
        prompt: words("Tap the number."),
        choices: options.map(String), right,
        wrong: i => {
          const v = options[i]!;
          if (n > 10 && v === swap(n) && v !== n) return ["Swapped the digits", `That's ${v}. ${n} starts with 1: 1 ten and ${count(n - 10, "one")}.`];
          if (n <= 9 && v <= 9) return ["Picked a look-alike", `That's ${v}, not ${n}. ${SHAPE[v]}. ${SHAPE[n]}.`];
          if (Math.abs(v - n) === 1) return ["Picked the number next to it", `That's ${v}, one ${v > n ? "more" : "less"} than ${n}. You counted ${count(n, "dot")}.`];
          if (v % 10 === 0 && n % 10 === 0) return ["Mixed up the tens", `That's ${v}: ${count(v / 10, "ten")}. ${n} is ${count(n / 10, "ten")}.`];
          return ["Picked a look-alike", `That's ${v}. You counted ${count(n, "dot")}, and ${n} is written ${n}.`];
        },
        hint: n === 20 ? "20 is 2 tens. It starts with 2." : n > 10 ? `${n} is 1 ten and ${count(n - 10, "one")}. It starts with 1.` : n <= 9 ? `${SHAPE[n]}.` : `Find the number that looks like ${n}.`,
        explain: `This is how ${n} is written: ${n}.`,
        work: [text("It's written "), num(n)],
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: WriteProblem, model: AnswerModel): Explanation {
  const { n } = p, c = expectedOf(model, "count"), right = expectedOf(model, "write", "c");
  return {
    heading: "Write the number",
    idea: ["Each number has its own shape, and it tells how many dots there are."],
    statement: words("How many dots?"),
    diagram: writeNumber({ n, beats: { count: 0, write: 1, done: 2 }, alt: `Ten frames with ${count(n, "dot")}, and the number ${n} written stroke by stroke beside them.` }),
    caption: `${count(n, "dot")} is written ${n}.`,
    timeline: beats(3),
    steps: [
      { id: "count", narration: n === 0 ? "Look for dots. There are none. None is **0**." : `Count the dots: ${countUp(1, n)}. That's **${c}**.`,
        math: [text("Dots: "), num(c)], state: 0, answerStep: "count", result: c },
      { id: "write", narration: n === 20 ? "Write 20: a 2 for the two tens, then a 0 for no ones." : n > 10 ? `Write ${n}: first the 1 for the ten, then ${n - 10} for the ones.` : `Write ${n}. Start at the dot and follow each stroke.`,
        math: [text("It's written "), num(n)], state: 1, answerStep: "write", result: right },
      { id: "done", narration: `${count(n, "dot")}. The number is **${n}**.`, math: [num(n)], state: 2 },
    ],
  };
}

export const lesson: LessonDefinition<WriteProblem> = {
  id: "k-write",
  grade: 0,
  unit: "Counting",
  title: "Write numbers 0 to 20",
  reference: createWrite(7),
  generate: (rng, index) => {
    if (index < 3) return createWrite(rng.int(1, 5));
    if (index < 6) return createWrite(rng.int(1, 10));
    // none is 0: it comes up once in a while, never early
    if (index === 6 && rng.int(0, 2) === 0) return createWrite(0);
    return createWrite(rng.int(0, 1) ? rng.int(11, 19) : rng.pick([...Array.from({ length: 10 }, (_, i) => i + 1), 20]));
  },
  restore: raw => restoreVia(raw, ["n"] as const, v => createWrite(v.n)),
  display: () => words("How many dots? Then find the number."),
  picture: p => writeNumber({ n: p.n, alt: "Ten frames with dots." }),
  answers,
  explain,
  pre: "k-count20",
};
