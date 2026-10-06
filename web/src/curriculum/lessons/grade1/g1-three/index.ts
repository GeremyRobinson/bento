// Add three numbers: find two that are easy to add first (a ten pair or a double), then add the last one.
import { num, op, text } from "../../../schemas/math-text";
import { count } from "../../../text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildThree } from "../../../../explanations/diagrams/early-g1/three";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { alsoAccept, countUp, slips, tapStep } from "../../gradeK/kit";

export interface ThreeProblem { a: number; b: number; c: number }

export function createThree(a: number, b: number, c: number): ThreeProblem {
  for (const [k, v] of [["a", a], ["b", b], ["c", c]] as const) wholeIn(k, v, 1, 9);
  if (a + b + c > 20) throw new Error("the sum is 20 at most");
  return { a, b, c };
}

const PAIRS: [number, number][] = [[0, 2], [1, 2], [0, 1]];
/** the two to add first: a pair that makes 10, else a double, else the first two */
export function pairOf(p: ThreeProblem): { pair: [number, number]; why: "ten" | "double" | "order" } {
  const v = [p.a, p.b, p.c];
  const ten = PAIRS.find(([i, j]) => v[i]! + v[j]! === 10);
  if (ten) return { pair: ten, why: "ten" };
  const dbl = PAIRS.find(([i, j]) => v[i] === v[j]);
  if (dbl) return { pair: dbl, why: "double" };
  return { pair: [0, 1], why: "order" };
}

/** The order the pairs are offered in: first and second, first and third, second and third. */
const OFFER: [number, number][] = [[0, 1], [0, 2], [1, 2]];
const friendly = (v: number[], [i, j]: [number, number]) => v[i]! + v[j]! === 10 || v[i] === v[j];

function answers(p: ThreeProblem): AnswerModel {
  const v = [p.a, p.b, p.c], { pair: [i, j], why } = pairOf(p), k = 3 - i - j;
  const x = v[i]!, y = v[j]!, z = v[k]!, first = x + y, sum = p.a + p.b + p.c;
  const add = oneBox({
    id: "first", label: "Add two first", question: why === "order" ? "Add the first two." : "Add the two you picked.",
    prompt: s => [num(x), op("+"), num(y), op("="), s], ans: first,
    wrong: slips(first, why === "ten"
      ? [[first - 1, "Counted one short", `${x} and ${y} fill a ten frame exactly: that's 10.`], [first + 1, "Counted one too many", `${x} and ${y} fill a ten frame exactly: that's 10.`]]
      : why === "double"
        ? [[first - 1, "Counted one short", `A double is the same number twice: ${x} and ${x} more.`], [first + 1, "Counted one too many", `A double is the same number twice: ${x} and ${x} more.`]]
        : [[first - 1, "Counted one short", `Start at ${Math.max(x, y)} and count on ${Math.min(x, y)}, one number for each dot.`], [first + 1, "Counted one too many", `Don't count ${Math.max(x, y)} again: the first number you say is ${Math.max(x, y) + 1}.`]]),
    hint: why === "ten" ? `Which number goes with ${x} to fill a ten frame?` : why === "double" ? `${x} and ${x} is a double. What is double ${x}?` : "Add the first two.",
    explain: why === "ten" ? `${x} and ${y} make 10.` : why === "double" ? `Double ${x} is ${first}.` : `${x} + ${y} = ${first}.`,
  });
  // choosing the easy pair: offered when exactly one pair makes 10 or a double, and the three pairs read differently
  const labels = OFFER.map(([s, t]) => `${v[s]} and ${v[t]}`);
  const choose = why !== "order" && OFFER.filter(q => friendly(v, q)).length === 1 && new Set(labels).size === 3;
  const pick = choose ? [tapStep({
    id: "pick", label: "Pick two", question: "Which two make 10 or a double?", prompt: [num(p.a), op("+"), num(p.b), op("+"), num(p.c)],
    choices: labels, right: OFFER.findIndex(([s, t]) => s === i && t === j),
    wrong: n => {
      const [s, t] = OFFER[n]!;
      return ["Picked a pair that isn't easy", `${v[s]} and ${v[t]} make ${v[s]! + v[t]!}. Look for two that ${why === "ten" ? "make 10" : "are the same"}: then the last add is easy.`];
    },
    hint: "Check each pair: do they fill a ten frame, or are they the same number?",
    explain: why === "ten" ? `${x} and ${y} make 10.` : `${x} and ${y} are the same: a double.`,
    work: [text(`${x} and ${y}`)],
  })] : [];
  return {
    steps: [
      ...pick,
      i === 0 && j === 1 ? add : alsoAccept(add, [p.a + p.b]),
      oneBox({
        id: "last", label: "Add the last one", question: "Now add the number that's left.",
        prompt: s => [num(first), op("+"), num(z), op("="), s], ans: sum,
        wrong: slips(sum, [
          [first, "Left one out", `That's only two of the numbers. Add the ${z} too.`],
          [sum - 1, "Counted one short", `Count on from ${first}: ${countUp(first + 1, sum)}.`],
          [sum + 1, "Counted one too many", `Count on from ${first}: ${countUp(first + 1, sum)}.`],
          [sum + z, "Added one twice", `You added the ${z} twice.`],
        ]),
        hint: `Start at ${first} and count on ${z}.`,
        explain: `${first} + ${z} = ${sum}.`,
        work: [num(p.a), op("+"), num(p.b), op("+"), num(p.c), op("="), num(sum)],
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: ThreeProblem, model: AnswerModel): Explanation {
  const v = [p.a, p.b, p.c] as [number, number, number], { pair, why } = pairOf(p), first = expectedOf(model, "first"), sum = expectedOf(model, "last");
  const x = v[pair[0]]!, y = v[pair[1]]!, z = v[3 - pair[0] - pair[1]]!;
  return {
    heading: "Add two first",
    idea: ["You can add numbers in any order. Look for two that make 10, or a double, and add those first."],
    statement: [num(p.a), op("+"), num(p.b), op("+"), num(p.c)],
    diagram: buildThree({ nums: v, pair, beats: { groups: 0, pair: 1, last: 2 }, alt: `Three groups of dots: ${p.a}, ${p.b} and ${p.c}. ${x} and ${y} join first to make ${first}, then ${z} more make ${sum}.` }),
    caption: why === "ten" ? `${x} and ${y} make 10. 10 and ${z} make ${sum}.` : `${x} + ${y} = ${first}, then ${first} + ${z} = ${sum}.`,
    timeline: beats(3),
    steps: [
      { id: "groups", narration: `Three groups: ${p.a}, ${p.b} and ${p.c}.`, math: [num(p.a), op("+"), num(p.b), op("+"), num(p.c)], state: 0 },
      { id: "first", narration: why === "ten" ? `${x} and ${y} make **10**. Add those first.` : why === "double" ? `${x} and ${y} is a double: **${first}**.` : `${x} + ${y} = **${first}**.`,
        math: [num(x), op("+"), num(y), op("="), num(first)], state: 1, answerStep: "first", result: first },
      { id: "last", narration: `${first} and ${z} more make **${sum}**.`, math: [num(first), op("+"), num(z), op("="), num(sum)], state: 2, answerStep: "last", result: sum },
    ],
  };
}

const NAMES = ["Maya", "Leo", "Ana", "Sam", "Noor", "Eli"];

export const lesson: LessonDefinition<ThreeProblem> = {
  id: "g1-three",
  grade: 1,
  unit: "Adding and subtracting",
  title: "Add three numbers",
  reference: createThree(7, 5, 3),
  generate: (rng, index) => {
    const early = index < 3, max = early ? 12 : 20;
    for (;;) {
      const kind = rng.int(0, 2);
      let v: number[];
      if (kind < 2) {
        const x = rng.int(1, 9), z = rng.int(1, Math.min(9, max - 10));
        v = rng.int(0, 1) ? [x, z, 10 - x] : [z, x, 10 - x];
      } else if (rng.int(0, 1)) {
        const d = rng.int(2, early ? 5 : 8), z = rng.int(1, 9);
        v = [d, z, d];
      } else v = [rng.int(1, 6), rng.int(1, 6), rng.int(1, 6)];
      const [a, b, c] = v as [number, number, number];
      if (a + b + c > max) continue;
      // a "neither" or a double must not hide a ten pair the generator didn't mean
      if (kind === 2 && pairOf({ a, b, c }).why === "ten") continue;
      if (kind < 2 && a + b === 10) continue;
      return createThree(a, b, c);
    }
  },
  restore: raw => restoreVia(raw, ["a", "b", "c"] as const, v => createThree(v.a, v.b, v.c)),
  display: p => [num(p.a), op("+"), num(p.b), op("+"), num(p.c)],
  picture: p => buildThree({ nums: [p.a, p.b, p.c], alt: `Three groups of dots: ${p.a}, ${p.b} and ${p.c}.` }),
  story: p => ({ op: "+", text: `${NAMES[(p.a + 2 * p.b + 3 * p.c) % NAMES.length]} has ${count(p.a, "red bead")}, ${count(p.b, "blue bead")} and ${count(p.c, "green bead")}. How many beads in all?` }),
  answers,
  explain,
  pre: "g1-ten",
};
