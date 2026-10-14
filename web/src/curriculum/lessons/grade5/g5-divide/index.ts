// Long division in chunks (the current app's g5-divide): tens of the divisor first, then what's left.
import { answer, num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { count } from "../../../text";
import { explainLongDivision } from "./explanation";
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
        // one question line over one answer pill, like every v2 step (spec §4 g5-divide); "as many as fit" keeps one right answer
        id: "tens", label: "Tens first", question: `Take out as many tens of ${dv} as fit in ${n}. How many is that?`,
        prompt: s => [text("tens"), op("="), s], ans: T, work: [num(dv), op("×"), answer("x", T), op("≤"), num(n)],
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
    // a miss without a named slip points at the picture, as in g5-mult2 (spec §4 g5-divide, Wrong)
    ].map(st => ({ ...st, look: `Look again at the lit-up strip: it's ${dv} tall.` })),
    finalParts: [-1],
  };
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
  explain: explainLongDivision,
  // skill check miss (v2 spec C2, g5-divide): the answer's own tens and ones
  checkWhy: ({ qt }) => `Take out the tens, then the ones: ${qt - (qt % 10)} + ${qt % 10}.`,
  story: p => ({ op: "÷", text: `**${p.n}** marbles are packed equally into **${p.dv}** jars. How many marbles go in each jar?` }),
};
