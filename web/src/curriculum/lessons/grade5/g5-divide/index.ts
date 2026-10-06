// Long division in chunks (the current app's g5-divide): tens of the divisor first, then what's left.
import { mark, num, op } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { chainExplanation } from "../../../../explanations/diagrams/chain/build";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { count } from "../../../text";
import { slips } from "../../grade4/_kit";

/** n ÷ dv with n = dv × qt; the quotient qt is never a multiple of 10 */
export interface LongDivisionProblem { dv: number; qt: number; n: number }

export function createLongDivision(dv: number, qt: number): LongDivisionProblem {
  wholeIn("dv", dv, 3, 25);
  if (dv === 10) throw new Error("the divisor is 3–9 or 11–25");
  wholeIn("qt", qt, 12, 99);
  if (qt % 10 === 0) throw new Error("qt is never a multiple of 10");
  return { dv, qt, n: dv * qt };
}

function answers({ dv, qt, n }: LongDivisionProblem): AnswerModel {
  const T = qt - (qt % 10), O = qt % 10, left = n - dv * T;
  return {
    steps: [
      oneBox({
        id: "tens", label: "Tens first", question: `What is the biggest tens number (10, 20, 30, …) where ${dv} × it is still ${n} or less?`,
        prompt: s => [num(dv), op("×"), s, op("≤"), num(n)], ans: T,
        hint: `Try ${dv} × 10, ${dv} × 20, … and stop before you go past ${n}.`,
        wrong: [
          [T - 10, "Not the most tens", `${dv} × ${T} still fits, so you can use more tens.`],
          [T / 10, "Forgot it's tens", `${count(T / 10, "ten")} is written ${T}.`],
          [T + 10, "Too many tens", `${dv} × ${T + 10} = ${dv * (T + 10)}, which is more than ${n}.`],
        ],
      }),
      oneBox({ id: "subtract", label: "Subtract", prompt: s => [num(n), op("−"), num(dv * T), op("="), s], ans: left, hint: `${dv} × ${T} = ${dv * T}. Take that away from ${n}.`,
        wrong: [[n + dv * T, "Added instead of took away", `Those ${dv * T} have been shared out, so take them away from ${n}.`]] }),
      oneBox({ id: "ones", label: "Divide what's left", prompt: s => [num(left), op("÷"), num(dv), op("="), s], ans: O, hint: `How many ${dv}s make ${left}?`,
        wrong: slips(O, [[O + 1, "One too many", `${dv} × ${O + 1} = ${dv * (O + 1)}, which is more than ${left}.`], [O - 1, "One too few", `One more ${dv} still fits in ${left}.`]]).filter(([v]) => v >= 0) }),
      oneBox({
        id: "sum", label: "Add the parts", prompt: s => [num(n), op("÷"), num(dv), op("="), s], ans: qt, hint: `${T} + ${O}.`,
        wrong: [[T / 10 + O, "Forgot it's tens", `The first part was ${T}, not ${T / 10}.`]],
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: LongDivisionProblem, model: AnswerModel) {
  const { dv, n } = p;
  const T = expectedOf(model, "tens"), left = expectedOf(model, "subtract"), O = expectedOf(model, "ones"), qt = expectedOf(model, "sum");
  return chainExplanation({
    heading: "Divide in chunks",
    idea: ["Dividing asks how many groups of the divisor fit, and taking out ten groups at a time gets there faster.", "Then share out what's left, and add the two parts."],
    statement: [num(n), op("÷"), num(dv)],
    caption: `Take out big chunks of ${dv} first.`,
    alt: `${n} ÷ ${dv}: ${dv} × ${T} = ${dv * T}, ${left} is left, ${left} ÷ ${dv} = ${O}, so ${T} + ${O} = ${qt}.`,
    beats: [
      { id: "tens", narration: `How many tens of ${dv} fit? ${dv} × ${T} = ${dv * T}.`, math: [num(dv), op("×"), num(T), op("="), num(dv * T)],
        lines: [[num(n), op("÷"), num(dv)], [num(dv), op("×"), mark(T), op("="), num(dv * T)]], answerStep: "tens", result: T },
      { id: "subtract", narration: `That leaves ${n} − ${dv * T} = ${left}.`, math: [num(n), op("−"), num(dv * T), op("="), num(left)],
        lines: [[num(n), op("−"), num(dv * T), op("="), num(left)]], answerStep: "subtract", result: left },
      { id: "ones", narration: `${count(O, "group")} of ${dv} make ${left}, so ${O} more fit: ${left} ÷ ${dv} = ${O}.`, math: [num(left), op("÷"), num(dv), op("="), num(O)],
        lines: [[num(dv), op("×"), mark(O), op("="), num(left)]], answerStep: "ones", result: O },
      { id: "sum", narration: `So the answer is ${T} + ${O} = ${qt}.`, math: [num(T), op("+"), num(O), op("="), num(qt)],
        lines: [[num(T), op("+"), num(O), op("="), num(qt)]], answerStep: "sum", result: qt },
    ],
  });
}

export const lesson: LessonDefinition<LongDivisionProblem> = {
  id: "g5-divide",
  grade: 5,
  unit: "Whole numbers",
  title: "Long division",
  pre: "g4-divide",
  reference: createLongDivision(12, 72), // 864 ÷ 12, the current app's example
  generate: rng => {
    const dv = rng.next() < 0.5 ? rng.int(3, 9) : rng.int(11, 25);
    let qt: number;
    do qt = rng.int(12, 99); while (qt % 10 === 0);
    return createLongDivision(dv, qt);
  },
  restore: raw => restoreVia(raw, ["dv", "qt"] as const, v => createLongDivision(v.dv, v.qt)),
  display: p => [num(p.n), op("÷"), num(p.dv)],
  answers,
  explain,
  story: p => ({ op: "÷", text: `**${p.n}** marbles are packed equally into **${p.dv}** jars. How many marbles go in each jar?` }),
};
