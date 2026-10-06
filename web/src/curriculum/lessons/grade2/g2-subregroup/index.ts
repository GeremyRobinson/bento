// Subtracting with regrouping: too few ones to take away, so trade one ten for ten ones first.
import { num, op } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTradeBlocks } from "../../../../explanations/diagrams/early-g2/blocks";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { count, slips } from "../kit";
import { count as countOf } from "../../../text";

/** a − b with two-digit numbers where a has fewer ones than b. */
export interface SubRegroupProblem { a: number; b: number }

const parts = ({ a, b }: SubRegroupProblem) => ({ at: Math.floor(a / 10), ao: a % 10, bt: Math.floor(b / 10), bo: b % 10 });

export function createSubRegroup(a: number, b: number): SubRegroupProblem {
  wholeIn("a", a, 20, 99);
  wholeIn("b", b, 10, 99);
  const { at, ao, bt, bo } = parts({ a, b });
  if (ao >= bo) throw new Error("a needs fewer ones than b, so a ten must be traded");
  if (bt >= at) throw new Error("a needs more tens than b");
  return { a, b };
}

/** Early problems leave at least one ten in the answer; later ones may not. */
function generate(rng: Rng, index: number): SubRegroupProblem {
  for (;;) {
    const at = rng.int(3, 9), ao = rng.int(0, 8), bo = rng.int(ao + 1, 9);
    const bt = rng.int(1, at - (index < 3 ? 2 : 1));
    if (bt < 1 || bt >= at) continue;
    return createSubRegroup(at * 10 + ao, bt * 10 + bo);
  }
}

function answers(p: SubRegroupProblem): AnswerModel {
  const { a, b } = p, { at, ao, bt, bo } = parts(p);
  const O = ao + 10, ones = O - bo, tens = at - 1 - bt, diff = a - b;
  return {
    steps: [
      oneBox({
        id: "trade", label: "Trade a ten",
        question: `${count(ao, "one")} is not enough to take away ${bo}. Trade 1 ten for 10 ones. How many ones now?`,
        prompt: s => [num(10), op("+"), num(ao), op("="), s], ans: O,
        wrong: slips(O, [
          [ao + 1, "Traded a ten for 1 one", "A ten is worth 10 ones, not 1. Add 10 to the ones."],
          [ao, "Forgot the new ones", `Add the 10 new ones to the ${ao} you already have.`],
          [10, "Lost the old ones", `Keep the ${countOf(ao, "one")} you had and add the 10 new ones.`],
        ]),
        hint: `You had ${count(ao, "one")}. Add the 10 ones from the ten you traded.`,
        explain: `10 + ${ao} = ${O}. Now there are ${countOf(O, "one")}.`,
      }),
      oneBox({
        id: "ones", label: "Take away the ones",
        prompt: s => [num(O), op("−"), num(bo), op("="), s], ans: ones,
        wrong: slips(ones, [
          [bo - ao, "Smaller from bigger", `That's ${bo} − ${ao}, the smaller digit from the bigger one. Start with the ${countOf(O, "one")} you have now and take away ${bo}.`],
          [O + bo, "Added the ones", `Take away ${bo}, don't add it.`],
        ]),
        hint: `Count back ${bo} from ${O}.`,
        explain: `${O} − ${bo} = ${ones}.`,
      }),
      oneBox({
        id: "tens", label: "Take away the tens",
        question: `You traded 1 ten, so ${count(at, "ten")} became ${at - 1}.`,
        prompt: s => [num(at - 1), op("−"), num(bt), op("="), s], ans: tens,
        wrong: slips(tens, [
          [at - bt, "Forgot the traded ten", `One ten became ones, so start from ${countOf(at - 1, "ten")}, not ${at}.`],
          [at - 1 + bt, "Added the tens", `Take away ${bt}, don't add it.`],
        ]),
        hint: `Start with ${countOf(at - 1, "ten")} and take away ${bt}.`,
        explain: `${at - 1} − ${bt} = ${tens}.`,
      }),
      oneBox({
        id: "answer", label: "Answer",
        prompt: s => [num(a), op("−"), num(b), op("="), s], ans: diff,
        wrong: slips(diff, [
          [(at - bt) * 10 + (bo - ao), "Smaller from bigger", `You did ${bo} − ${ao} in the ones. You can't take ${bo} from ${ao}, so trade a ten first.`],
          [(at - bt) * 10 + ones, "Forgot the traded ten", `You traded a ten, so there is one ten less: ${at - 1} − ${bt} = ${tens}.`],
          [tens + ones * 10, "Swapped the digits", `Tens go on the left: ${count(tens, "ten")} and ${count(ones, "one")}.`],
        ]),
        hint: `${count(tens, "ten")} and ${count(ones, "one")}.`,
        explain: `${count(tens, "ten")} and ${count(ones, "one")} is ${diff}.`,
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: SubRegroupProblem, model: AnswerModel): Explanation {
  const { a, b } = p, { at, ao, bt, bo } = parts(p);
  const O = expectedOf(model, "trade"), ones = expectedOf(model, "ones"), tens = expectedOf(model, "tens"), diff = expectedOf(model, "answer");
  return {
    heading: "Trade a ten",
    idea: ["If there are not enough ones to take away, trade one ten for ten ones. Then take away the ones, then the tens."],
    statement: [num(a), op("−"), num(b)],
    diagram: buildTradeBlocks({
      a, b, beats: { blocks: 0, trade: 1, ones: 2, tens: 3, total: 4 },
      text: { start: `${countOf(ao, "one")}, need ${bo}`, trade: `10 + ${ao} = ${O}`, ones: `${O} − ${bo} = ${ones}`, tens: `${at - 1} − ${bt} = ${tens}`, total: `${a} − ${b} = ${diff}` },
      alt: `${a} as ${count(at, "ten")} and ${count(ao, "one")}. One ten is traded for 10 ones, making ${countOf(O, "one")}. ${countOf(bo, "one")} and ${count(bt, "ten")} are taken away, leaving ${count(tens, "ten")} and ${count(ones, "one")}: ${diff}.`,
    }),
    caption: `${count(ao, "one")} can't give away ${bo}, so one ten becomes 10 ones.`,
    timeline: beats(5),
    steps: [
      { id: "trade", narration: `${count(ao, "one")} is not enough to take away ${bo}. Trade 1 ten for 10 ones: now there are ${countOf(O, "one")} and ${countOf(at - 1, "ten")}.`, math: [num(10), op("+"), num(ao), op("="), num(O)], state: 1, answerStep: "trade", result: O },
      { id: "ones", narration: `Take away ${countOf(bo, "one")}: ${O} − ${bo} = ${ones}.`, math: [num(O), op("−"), num(bo), op("="), num(ones)], state: 2, answerStep: "ones", result: ones },
      { id: "tens", narration: `Take away ${count(bt, "ten")} from the ${at - 1} left: ${tens}.`, math: [num(at - 1), op("−"), num(bt), op("="), num(tens)], state: 3, answerStep: "tens", result: tens },
      { id: "answer", narration: `${count(tens, "ten")} and ${count(ones, "one")} is ${diff}.`, math: [num(a), op("−"), num(b), op("="), num(diff)], state: 4, answerStep: "answer", result: diff },
    ],
  };
}

export const lesson: LessonDefinition<SubRegroupProblem> = {
  id: "g2-subregroup",
  grade: 2,
  unit: "Adding and subtracting",
  title: "Subtracting with regrouping",
  pre: "g2-regroup",
  reference: createSubRegroup(52, 27),
  generate,
  restore: raw => restoreVia(raw, ["a", "b"] as const, v => createSubRegroup(v.a, v.b)),
  display: p => [num(p.a), op("−"), num(p.b)],
  displayCounters: p => ({ op: "", groups: [{ kind: "blocks", value: p.a }] }),
  answers,
  explain,
  story: ({ a, b }) => ({ op: "−", text: `There were **${a}** stickers on a sheet. Maya used **${b}** of them. How many stickers are left?` }),
};
