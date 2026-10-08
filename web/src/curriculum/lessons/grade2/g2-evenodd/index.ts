// Even and odd: put the dots in pairs. If every dot has a partner the number is even; one left over makes it odd.
import { num, text } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPairs } from "../../../../explanations/diagrams/early-g2/counting";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { count, slips } from "../kit";
import { count as countOf } from "../../../text";

/** n dots to pair up. */
export interface EvenOddProblem { n: number }

export function createEvenOdd(n: number): EvenOddProblem {
  wholeIn("n", n, 3, 20);
  return { n };
}

/** Early problems have at most 12 dots; later ones up to 20. */
const generate = (rng: Rng, index: number) => createEvenOdd(index < 3 ? rng.int(4, 12) : rng.int(7, 20));

const CHOICES = ["Even", "Odd"];

function answers({ n }: EvenOddProblem): AnswerModel {
  const pairs = Math.floor(n / 2), left = n % 2, odd = left === 1, right = odd ? 1 : 0;
  const choose: AnswerStep = {
    id: "evenodd",
    label: "Even or odd",
    question: "Did every dot get a partner?",
    prompt: [text("Is "), num(n), text(" even or odd?")],
    slots: [{ id: "c", expected: right }],
    choices: CHOICES,
    known: [{
      values: { c: 1 - right },
      kind: odd ? "Called an odd number even" : "Called an even number odd",
      message: odd ? `One dot is left over without a partner, so ${n} is odd.` : `Every dot has a partner and none are left over, so ${n} is even.`,
    }],
    hint: "Even numbers make pairs with none left over. Odd numbers have one left over.",
    explain: odd ? `${count(pairs, "pair")} and 1 left over, so ${n} is odd.` : `${count(pairs, "pair")} and none left over, so ${n} is even.`,
    work: [num(n), text(odd ? " is odd" : " is even")],
  };
  return {
    steps: [
      oneBox({
        id: "pairs", label: "Make pairs", question: "Put the dots in pairs of 2. How many pairs can you make?",
        prompt: s => [text("Pairs: "), s], ans: pairs,
        wrong: slips(pairs, [
          [n, "Counted every dot", `${n} is how many dots there are. A pair is 2 dots, so count the pairs.`],
          odd && [pairs + 1, "Counted the lone dot as a pair", "The last dot has no partner, so it does not make a pair."],
          [n * 2, "Doubled", `Each pair uses 2 of the ${countOf(n, "dot")}, so there are fewer pairs than dots.`],
        ]),
        hint: "Circle the dots two at a time and count the circles.",
        explain: `${countOf(n, "dot")} make ${count(pairs, "pair")}${odd ? " with 1 dot left" : ""}.`,
      }),
      oneBox({
        id: "left", label: "Check the leftover", question: "How many dots have no partner?",
        prompt: s => [text("Left over: "), s], ans: left,
        wrong: slips(left, [
          [pairs, "Wrote the pairs", `${pairs} is the number of pairs. How many dots are left on their own?`],
          odd ? [0, "Missed the lone dot", "Look again: one dot is all alone."] : [1, "Saw a lone dot", "Look again: every dot has a partner."],
          [2, "Two left over", "Two leftover dots would make one more pair."],
        ]),
        hint: "Look for a dot with no partner.",
        explain: odd ? "One dot has no partner." : "No dots are left over.",
      }),
      choose,
    ],
    finalParts: [-1],
  };
}

function explain(p: EvenOddProblem, model: AnswerModel): Explanation {
  const { n } = p;
  const pairs = expectedOf(model, "pairs"), left = expectedOf(model, "left"), pick = expectedOf(model, "evenodd", "c");
  const word = CHOICES[pick]!.toLowerCase();
  return {
    heading: "Even or odd",
    idea: ["A number is even when it splits into pairs with none left over."],
    statement: [text("Is "), num(n), text(" even or odd?")],
    diagram: buildPairs({
      n, beats: { pairs: 1, left: 2, verdict: 3 },
      text: { pairs: count(pairs, "pair"), left: `${left} left over`, verdict: `${n} is ${word}` },
      alt: `${countOf(n, "dot")} put into ${count(pairs, "pair")} with ${left} left over, so ${n} is ${word}.`,
    }),
    caption: left ? "One dot has no partner." : "Every dot has a partner.",
    timeline: beats(4),
    steps: [
      { id: "pairs", narration: `Put the ${countOf(n, "dot")} in twos: ${count(pairs, "pair")}.`, math: [text("Pairs: "), num(pairs)], state: 1, answerStep: "pairs", result: pairs },
      { id: "left", narration: left ? "One dot is left all alone." : "No dots are left over.", math: [text("Left over: "), num(left)], state: 2, answerStep: "left", result: left },
      { id: "evenodd", narration: left ? `So ${n} is **odd**.` : `So ${n} is **even**.`, math: [num(n), text(` is ${word}`)], state: 3, answerStep: "evenodd", result: pick },
    ],
  };
}

export const lesson: LessonDefinition<EvenOddProblem> = {
  id: "g2-evenodd",
  grade: 2,
  unit: "Place value",
  title: "Even and odd",
  reference: createEvenOdd(13),
  generate,
  restore: raw => restoreVia(raw, ["n"] as const, v => createEvenOdd(v.n)),
  display: p => [text("Is "), num(p.n), text(" even or odd?")],
  displayCounters: p => ({ op: "", groups: [{ kind: "dots", value: p.n }] }),
  answers,
  explain,
};
