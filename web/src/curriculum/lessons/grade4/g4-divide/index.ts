// Dividing with remainders (the current app's g4-divide): take out tens of the divisor, then ones, then see what's left.
import { mark, num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { chainExplanation } from "../../../../explanations/diagrams/chain/build";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { count } from "../../../text";
import { divisionAreaPicture } from "./picture";
import { slips } from "../_kit";

/** (dv × q + r) ÷ dv: the quotient q is never a multiple of 10, the remainder r is less than dv */
export interface RemainderProblem { dv: number; q: number; r: number }

export function createRemainder(dv: number, q: number, r: number): RemainderProblem {
  wholeIn("dv", dv, 3, 9);
  wholeIn("q", q, 12, 99);
  if (q % 10 === 0) throw new Error("q is never a multiple of 10");
  wholeIn("r", r, 0, dv - 1);
  return { dv, q, r };
}

const parts = ({ dv, q, r }: RemainderProblem) => {
  const n = dv * q + r, T = q - (q % 10), O = q % 10;
  return { n, T, O, left: n - dv * T };
};

function answers(p: RemainderProblem): AnswerModel {
  const { dv, q, r } = p, { n, T, O, left } = parts(p);
  return {
    steps: [
      oneBox({
        id: "tens", label: "Tens first", question: `What is the biggest tens number (10, 20, 30, …) where ${dv} × it is still ${n} or less?`,
        prompt: s => [num(dv), op("×"), s, op("≤"), num(n)], ans: T,
        hint: `Try ${dv} × 10, ${dv} × 20, … and stop before you go past ${n}.`,
        wrong: [[T - 10, "Not the most tens", `${dv} × ${T} still fits, so you can use more tens.`], [T / 10, "Forgot it's tens", `${count(T / 10, "ten")} is written ${T}.`], [T + 10, "Too many tens", `${dv} × ${T + 10} = ${dv * (T + 10)}, which is more than ${n}.`]],
      }),
      oneBox({ id: "subtract", label: "Subtract", prompt: s => [num(n), op("−"), num(dv * T), op("="), s], ans: left, hint: `${dv} × ${T} = ${dv * T}. Take that away from ${n}.`,
        wrong: [[n + dv * T, "Added instead of took away", `Those ${dv * T} have been shared out, so take them away from ${n}.`]] }),
      oneBox({
        id: "ones", label: "Divide what's left", question: `What is the most whole ${dv}s that fit into ${left}?`,
        prompt: s => [num(dv), op("×"), s, op("≤"), num(left)], ans: O, hint: `Count by ${dv}s and stop before you pass ${left}.`,
        wrong: slips(O, [[O + 1, "One too many", `${dv} × ${O + 1} = ${dv * (O + 1)}, which is more than ${left}.`], [O - 1, "Not the most", `One more ${dv} still fits in ${left}.`]]).filter(([v]) => v >= 0),
      }),
      oneBox({ id: "answer", label: "The answer", prompt: s => [num(T), op("+"), num(O), op("="), s], ans: q, hint: "Add the tens and the ones.",
        wrong: slips(q, [[T / 10 + O, "Forgot it's tens", `The first part was ${T}, not ${T / 10}.`]]) }),
      oneBox({
        id: "remainder", label: "The remainder", question: "What's left over?",
        prompt: s => [num(left), op("−"), num(dv * O), op("="), s], ans: r,
        hint: `${dv} × ${O} = ${dv * O}. Take that from ${left}. It must be less than ${dv}.`,
        wrong: [[r + dv, "Remainder too big", `It can't be ${dv} or more: one more ${dv} would fit.`]],
      }),
    ],
    finalParts: [-2, -1],
  };
}

function explain(p: RemainderProblem, model: AnswerModel) {
  const { dv } = p, { n } = parts(p);
  const T = expectedOf(model, "tens"), left = expectedOf(model, "subtract"), O = expectedOf(model, "ones");
  const q = expectedOf(model, "answer"), r = expectedOf(model, "remainder");
  return chainExplanation({
    heading: "Share, then see what's left",
    idea: ["Dividing shares a number into equal groups, and taking out tens of a group at a time is faster than counting one by one.", "What's too small to make one more group is the remainder."],
    statement: [num(n), op("÷"), num(dv)],
    caption: `Take out ${T / 10} ${T === 10 ? "ten" : "tens"}, then ${O} ${O === 1 ? "one" : "ones"}. ${r ? `What's left, ${r}, is the remainder.` : "Nothing is left over."}`,
    alt: `${n} ÷ ${dv}: ${dv} × ${T} = ${dv * T}, ${dv} × ${O} = ${dv * O}, so ${r ? `${q} R ${r}` : `${q} exactly`}.`,
    diagram: divisionAreaPicture({ n, dv, T, O, left, q, r }),
    beats: [
      { id: "tens", narration: `${dv} × ${T} = ${dv * T} fits into ${n}, and ${dv} × ${T + 10} = ${dv * (T + 10)} would not.`,
        math: [num(dv), op("×"), num(T), op("="), num(dv * T)],
        lines: [[num(n), op("÷"), num(dv)], [num(dv), op("×"), mark(T), op("="), num(dv * T)]], answerStep: "tens", result: T },
      { id: "subtract", narration: `That leaves ${n} − ${dv * T} = ${left}.`, math: [num(n), op("−"), num(dv * T), op("="), num(left)],
        lines: [[num(n), op("−"), num(dv * T), op("="), num(left)]], answerStep: "subtract", result: left },
      { id: "ones", narration: `${dv} × ${O} = ${dv * O} fits in ${left}.`, math: [num(dv), op("×"), num(O), op("="), num(dv * O)],
        lines: [[num(dv), op("×"), mark(O), op("="), num(dv * O)]], answerStep: "ones", result: O },
      { id: "answer", narration: `Add the tens and the ones: ${T} + ${O} = ${q}.`, math: [num(T), op("+"), num(O), op("="), num(q)],
        lines: [[num(T), op("+"), num(O), op("="), num(q)]], answerStep: "answer", result: q },
      { id: "remainder", narration: r ? `${left} − ${dv * O} = ${r} is left over. So ${n} ÷ ${dv} = ${q} with ${r} left over: ${q} R ${r}.`
          : `${left} − ${dv * O} = 0: nothing is left over, so ${dv} goes into ${n} exactly ${q} times.`,
        math: [num(left), op("−"), num(dv * O), op("="), num(r)],
        lines: [[num(left), op("−"), num(dv * O), op("="), mark(r)], [num(n), op("÷"), num(dv), op("="), num(q), ...(r ? [text(" R "), num(r)] : [])]],
        answerStep: "remainder", result: r },
    ],
  });
}

export const lesson: LessonDefinition<RemainderProblem> = {
  id: "g4-divide",
  grade: 4,
  unit: "Whole numbers",
  title: "Dividing with remainders",
  pre: "g3-divfacts",
  reference: createRemainder(4, 18, 3), // 75 ÷ 4 = 18 R 3, the current app's example
  generate: rng => {
    const dv = rng.int(3, 9);
    let q: number;
    do q = rng.int(12, 99); while (q % 10 === 0);
    return createRemainder(dv, q, rng.int(0, dv - 1));
  },
  restore: raw => restoreVia(raw, ["dv", "q", "r"] as const, v => createRemainder(v.dv, v.q, v.r)),
  display: p => [num(parts(p).n), op("÷"), num(p.dv)],
  displayNote: () => "Find the answer and the remainder.",
  answers,
  explain,
  story: p => ({ op: "÷", text: `**${parts(p).n}** stickers are shared equally by **${p.dv}** friends. How many does each friend get, and how many are left over?` }),
};
