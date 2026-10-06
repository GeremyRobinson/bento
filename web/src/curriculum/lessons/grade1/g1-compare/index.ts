// Compare two-digit numbers: look at the tens first; only when they match, look at the ones. Then tap <, = or >.
import { num, op, text, type Operator } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation, type ExplanationStep } from "../../../../explanations/schema";
import { buildCompareBlocks } from "../../../../explanations/diagrams/early-g1/blocks";
import { manyBoxes, restoreVia, wholeIn } from "../../_number-line/steps";
import { choiceStep, count, onesOf, plural, slipsMany, tensOf } from "../_kit";
import { singularWork } from "../../gradeK/kit";

/** two numbers from 10 to 99 to compare */
export interface CompareProblem { a: number; b: number }

export function createCompare(a: number, b: number): CompareProblem {
  wholeIn("a", a, 10, 99);
  wholeIn("b", b, 10, 99);
  return { a, b };
}

const SIGNS: Operator[] = ["<", "=", ">"];
const CHOICES = ["< less than", "= equal to", "> greater than"];
const signIndex = (a: number, b: number) => (a < b ? 0 : a === b ? 1 : 2);

function answers({ a, b }: CompareProblem): AnswerModel {
  const ta = tensOf(a), tb = tensOf(b), ao = onesOf(a), bo = onesOf(b), right = signIndex(a, b);
  const steps: AnswerStep[] = [
    manyBoxes({
      id: "tens", label: "Compare the tens",
      prompt: x => [num(a), text(" has "), x.ta!, text(" tens. "), num(b), text(" has "), x.tb!, text(" tens.")],
      ans: { ta, tb },
      wrong: slipsMany({ ta, tb }, [
        [{ ta: ao, tb: bo }, "Read the ones digits", "Those are the ones digits. The tens digit is the **first** digit."],
        [{ ta: tb, tb: ta }, "Swapped the numbers", `Check which number is which: ${a} comes first, then ${b}.`],
      ]),
      hint: `Which digit sits in the tens place of ${a}, and of ${b}? Each tens rod is one ten.`,
      explain: `The first digit tells the tens: ${a} has ${plural(ta, "ten", "tens")} and ${b} has ${plural(tb, "ten", "tens")}.`,
    }),
  ];
  if (ta === tb) steps.push(manyBoxes({
    id: "ones", label: "Same tens, so compare the ones",
    prompt: x => [num(a), text(" has "), x.ao!, text(" ones. "), num(b), text(" has "), x.bo!, text(" ones.")],
    ans: { ao, bo },
    wrong: slipsMany({ ao, bo }, [
      [{ ao: ta, bo: tb }, "Read the tens digits", "Those are the tens. The ones digit is the **last** digit."],
      [{ ao: bo, bo: ao }, "Swapped the numbers", `Check which number is which: ${a} comes first, then ${b}.`],
    ]),
    hint: `The tens match, so the ones decide. Which digit sits in the ones place of each number?`,
    explain: `The last digit tells the ones: ${a} has ${plural(ao, "one", "ones")} and ${b} has ${plural(bo, "one", "ones")}.`,
  }));
  const bigger = Math.max(a, b), smaller = Math.min(a, b);
  const why = ta !== tb
    ? `${plural(Math.max(ta, tb), "ten", "tens")} is more than ${plural(Math.min(ta, tb), "ten", "tens")}, so ${bigger} is bigger.`
    : ao !== bo ? `Same tens. ${plural(Math.max(ao, bo), "one", "ones")} is more than ${plural(Math.min(ao, bo), "one", "ones")}, so ${bigger} is bigger.`
      : "Same tens and same ones, so the numbers are equal.";
  steps.push(choiceStep({
    id: "sign", label: "Pick the sign", question: `Which sign goes between ${a} and ${b}?`,
    prompt: [num(a), text(" ? "), num(b)],
    choices: CHOICES, ans: right,
    wrong: a === b
      ? [[0, "Picked less than", why], [2, "Picked greater than", why]]
      : [
        [1, "Picked equal", `${a} and ${b} are not the same number. ${why}`],
        [2 - right, "Sign turned around", `${why} The open side of the sign faces the bigger number, ${bigger}.`],
      ],
    hint: a === b ? "Are the tens the same? Are the ones the same?" : `Which is bigger, ${smaller} or ${bigger}? The open side faces the bigger one.`,
    explain: a === b ? why : `${why} So ${a} ${SIGNS[right]} ${b}.`,
    work: [num(a), op(SIGNS[right]!), num(b)],
  }));
  return { steps, finalParts: [-1] };
}

function explain({ a, b }: CompareProblem, model: AnswerModel): Explanation {
  const ta = tensOf(a), tb = tensOf(b), ao = onesOf(a), bo = onesOf(b);
  const hasOnes = model.steps.some(s => s.id === "ones");
  const right = model.steps.at(-1)!.slots[0]!.expected!, sign = SIGNS[right]!;
  const n = hasOnes ? 3 : 2;
  const steps: ExplanationStep[] = [
    { id: "tens", narration: ta === tb ? `Both have **${ta}** tens. That's a tie, so the tens can't decide.` : `${a} has **${ta}** tens and ${b} has **${tb}** tens.`,
      math: [...count(ta, "ten", "tens"), text(ta === tb ? " and " : " vs "), ...count(tb, "ten", "tens")], state: 0, answerStep: "tens", result: ta },
  ];
  if (hasOnes) steps.push({ id: "ones", narration: ao === bo ? `The ones match too: **${ao}** and **${bo}**.` : `Look at the ones: **${ao}** and **${bo}**.`,
    math: [...count(ao, "one", "ones"), text(ao === bo ? " and " : " vs "), ...count(bo, "one", "ones")], state: 1, answerStep: "ones", result: ao });
  steps.push({ id: "sign", narration: a === b ? `Same number, so they are **equal**.` : `${Math.max(a, b)} is bigger, so the open side of the sign faces it.`,
    math: [num(a), op(sign), num(b)], state: n - 1, answerStep: "sign" });
  return {
    heading: "Compare two-digit numbers",
    idea: ["Look at the tens first. More tens means a bigger number. Only when the tens are the same do you look at the ones."],
    statement: [num(a), text(" ? "), num(b)],
    diagram: buildCompareBlocks({
      a, b, sign,
      text: { aTens: plural(ta, "ten", "tens"), bTens: plural(tb, "ten", "tens"), aOnes: plural(ao, "one", "ones"), bOnes: plural(bo, "one", "ones") },
      beats: { tens: 0, ones: hasOnes ? 1 : null, sign: n - 1 },
      alt: `${a} as ${plural(ta, "ten", "tens")} and ${plural(ao, "one", "ones")}, beside ${b} as ${plural(tb, "ten", "tens")} and ${plural(bo, "one", "ones")}: ${a} ${sign} ${b}.`,
    }),
    caption: `${a} ${sign} ${b}`,
    timeline: beats(n),
    steps,
  };
}

export const lesson: LessonDefinition<CompareProblem> = {
  id: "g1-compare",
  grade: 1,
  unit: "Place value",
  title: "Compare two-digit numbers",
  pre: "g1-tensones",
  reference: createCompare(43, 47),
  generate: (rng, index) => {
    const kind = index < 3 ? 0 : rng.int(0, 9);
    if (kind === 9) { const n = rng.int(10, 99); return createCompare(n, n); }
    if (kind >= 5) {
      // same tens, different ones
      const t = rng.int(1, 9), x = rng.int(0, 9);
      let y = rng.int(0, 8); if (y >= x) y++;
      return createCompare(t * 10 + x, t * 10 + y);
    }
    const ta = rng.int(1, 9);
    let tb = rng.int(1, 8); if (tb >= ta) tb++;
    return createCompare(ta * 10 + rng.int(0, 9), tb * 10 + rng.int(0, 9));
  },
  restore: raw => restoreVia(raw, ["a", "b"] as const, v => createCompare(v.a, v.b)),
  display: p => [num(p.a), text(" ? "), num(p.b)],
  answers: p => singularWork(answers(p)),
  explain,
};
