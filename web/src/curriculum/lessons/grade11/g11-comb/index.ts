import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildChoose } from "../../../../explanations/diagrams/marbles/build";
import { asRecord, expected, mt, ns, numberField } from "../../_geometry/kit";
import { count } from "../../../text";
import { withEasyStart } from "../../easy-start";

/** Choose k (2 or 3) of n things when order doesn't matter. */
export interface CombinationProblem {
  kind: "probability.combinations";
  n: number;
  k: 2 | 3;
}

export function createCombination(n: number, k: number): CombinationProblem {
  if (k !== 2 && k !== 3) throw new Error("choose 2 or 3");
  if (!Number.isInteger(n) || n < k || n > 26) throw new Error("n is a whole number from k to 26");
  return { kind: "probability.combinations", n, k };
}

export function restoreCombination(raw: unknown): CombinationProblem | null {
  const r = asRecord(raw), n = r && numberField(r, "n"), k = r && numberField(r, "k");
  if (n == null || k == null) return null;
  try { return createCombination(n, k); } catch { return null; }
}

const parts = ({ n, k }: CombinationProblem) => ({ top: k === 2 ? n * (n - 1) : n * (n - 1) * (n - 2), f: k === 2 ? 2 : 6 });
const picks = ({ n, k }: CombinationProblem) => (k === 2 ? mt`${n} × ${n - 1}` : mt`${n} × ${n - 1} × ${n - 2}`);

export function combinationAnswers(p: CombinationProblem): AnswerModel {
  const { n, k } = p, { top, f } = parts(p);
  return {
    steps: [
      ns({ id: "ordered", label: "Ordered picks", prompt: s => mt`${picks(p)} = ${s}`, ans: top, hint: `Any of the ${n} can be picked first, then one fewer for each pick after it: ${k} numbers counting down from ${n}, multiplied.`, wrong: [[n * k, `Multiplied by ${k}`, `Count down: ${n}, then ${n - 1}${k === 3 ? `, then ${n - 2}` : ""}, and multiply them.`]] }),
      ns({ id: "orders", label: "Ways to order them", prompt: s => mt`${k}! = ${s}`, ans: f, hint: `Any of the ${k} can go first, then any of the ${k - 1} left${k === 3 ? ", then the last one" : ""}: multiply.`, wrong: [[k, "Counted the picks", `${k} picks can be lined up in ${k}! ways: multiply down from ${k}.`]] }),
      ns({ id: "divide", label: "Divide", prompt: s => mt`${top} ÷ ${f} = ${s}`, ans: top / f, hint: "Order doesn't matter, so divide out the repeats.",
        wrong: [[top, "Didn't divide", "Each group got counted once for every order."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainCombination(p: CombinationProblem, answers: AnswerModel): Explanation {
  const { n, k } = p;
  const top = expected(answers, "ordered"), f = expected(answers, "orders"), ways = expected(answers, "divide");
  const what = k === 2 ? "pairs" : "groups of 3";
  return {
    heading: "Count, then remove repeats",
    idea: ["Each group shows up once for every way to order it, so the repeats divide out."],
    statement: mt`C(${n}, ${k})`,
    caption: `${top} ordered picks, each group counted ${f} times: ${ways} ${what}.`,
    diagram: buildChoose({
      n, k, orderedBeat: 1, ordersBeat: 2, groupsBeat: 3,
      orderedNote: `${k === 2 ? `${n} × ${n - 1}` : `${n} × ${n - 1} × ${n - 2}`} = ${top} ordered`,
      ordersNote: `${k}! = ${f} orders, one group`,
      groupsNote: `${top} ÷ ${f} = ${ways} ${what}`,
      alt: `${count(n, "dot")} labelled A to ${String.fromCharCode(64 + n)}. ${top} ordered picks; each ${k === 2 ? "pair" : "group"} appears in ${f} orders, so there are ${ways} ${what}.`,
    }),
    timeline: beats(4),
    steps: [
      { id: "things", narration: `There are ${n} things to choose from, and you take ${k}.`, math: mt`C(${n}, ${k})`, state: 0 },
      { id: "ordered", narration: `Pick one at a time: ${n} choices first, then ${n - 1}${k === 3 ? `, then ${n - 2}` : ""}. That's ${top} ordered picks.`, math: mt`${picks(p)} = ${top}`, state: 1, answerStep: "ordered", result: top },
      { id: "orders", narration: `But the same ${k} things can come out in ${f} different orders, and they are still one group.`, math: mt`${k}! = ${f}`, state: 2, answerStep: "orders", result: f },
      { id: "divide", narration: `So divide out the repeats: ${top} ÷ ${f} = ${ways}.`, math: mt`${top} ÷ ${f} = ${ways}`, state: 3, answerStep: "divide", result: ways },
    ],
  };
}

export const lesson: LessonDefinition<CombinationProblem> = withEasyStart({
  id: "g11-comb",
  grade: 11,
  unit: "Probability",
  title: "Combinations",
  reference: createCombination(5, 2),
  generate: (rng, i) => createCombination(rng.int(5, 12), i % 2 ? 3 : 2),
  restore: restoreCombination,
  display: p => mt`C(${p.n}, ${p.k})`,
  displayNote: p => `How many ways to choose ${p.k} from ${p.n} when order doesn't matter?`,
  answers: combinationAnswers,
  explain: explainCombination,
});
