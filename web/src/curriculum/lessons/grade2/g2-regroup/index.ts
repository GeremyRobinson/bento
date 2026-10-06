import { answer, num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildRegroupBlocks } from "../../../../explanations/diagrams/area-model/blocks";
import { expectedOf, numStep, readNumbers } from "../../area-common/steps";
import { count } from "../../../text";

/** a + b with two-digit numbers whose ones make a ten or more; the sum stays under 100. */
export interface RegroupProblem { a: number; b: number }

export function createRegroup(a: number, b: number): RegroupProblem {
  if (![a, b].every(v => Number.isInteger(v) && v >= 10 && v <= 99)) throw new Error("both numbers have two digits");
  if (a % 10 + b % 10 < 10) throw new Error("the ones must make a ten");
  return { a, b };
}

/** Same as the current app: both 15–79, ones adding to 10 or more, sum at most 99. */
export function generateRegroup(rng: Rng): RegroupProblem {
  let a: number, b: number;
  do { a = rng.int(15, 79); b = rng.int(15, 79); } while (a % 10 + b % 10 < 10 || a + b > 99);
  return { a, b };
}

const parts = ({ a, b }: RegroupProblem) => {
  const at = Math.floor(a / 10), ao = a % 10, bt = Math.floor(b / 10), bo = b % 10;
  return { at, ao, bt, bo, O: ao + bo };
};

export function regroupAnswers(p: RegroupProblem): AnswerModel {
  const { a, b } = p, { at, ao, bt, bo, O } = parts(p);
  return {
    steps: [
      numStep({ id: "ones", label: "Add the ones", prompt: x => [num(ao), op("+"), num(bo), op("="), x], ans: O,
        wrong: [[at + bt, "Started with the tens", "Start with the **ones**, the digits on the right."]],
        hint: `Add just the ones: ${ao} + ${bo}.`, explain: `${ao} + ${bo} = ${O}.`, work: [text("Ones: "), num(ao), op("+"), num(bo), op("="), num(O)] }),
      numStep({ id: "regroup", label: "Regroup", question: `${O} is 1 ten and how many ones?`, prompt: x => [x], ans: O % 10,
        wrong: [[O, "Regrouping", "Only one digit fits in the ones place. The ten carries over to the tens."]],
        hint: `${O} = 10 + ?`, explain: `${O} = 10 + ${O % 10}. Write ${O % 10}, carry the 1.`, work: [text("Write "), answer("x", O % 10), text(", carry 1 ten")] }),
      numStep({ id: "tens", label: "Add the tens", question: "Add the tens, plus the 1 you carried.", prompt: x => [num(at), op("+"), num(bt), op("+"), num(1), op("="), x], ans: at + bt + 1,
        wrong: [[at + bt, "Forgot the carried ten", "Don't forget the 1 you carried!"]],
        hint: `Add the tens, ${at} + ${bt}, then 1 more for the ten you carried.`, explain: `${at} + ${bt} + 1 = ${at + bt + 1}.`, work: [text("Tens: "), num(at), op("+"), num(bt), op("+"), num(1), op("="), num(at + bt + 1)] }),
      numStep({ id: "answer", label: "Answer", prompt: x => [num(a), op("+"), num(b), op("="), x], ans: a + b,
        wrong: [[(at + bt) * 10 + O % 10, "Forgot the carried ten", "Check the tens: did you add the 1 you carried?"]],
        hint: `${count(at + bt + 1, "ten")} and ${count(O % 10, "one")}.`, explain: `${count(at + bt + 1, "ten")} and ${count(O % 10, "one")} is ${a + b}.`, work: [num(a), op("+"), num(b), op("="), answer("x", a + b)] }),
    ],
    finalParts: [-1],
  };
}

export function explainRegroup(p: RegroupProblem, answers: AnswerModel): Explanation {
  const { a, b } = p, { at, ao, bt, bo } = parts(p);
  const O = expectedOf(answers.steps, "ones"), left = expectedOf(answers.steps, "regroup"), T = expectedOf(answers.steps, "tens"), sum = expectedOf(answers.steps, "answer");
  return {
    heading: "Carry the ten",
    idea: ["Add the ones first. If they make 10 or more, trade ten ones for one ten and carry it to the tens."],
    statement: [num(a), op("+"), num(b)],
    diagram: buildRegroupBlocks({
      a, b, beats: { blocks: 0, ones: 1, regroup: 2, tens: 3, total: 4 },
      text: { ones: `${ao} + ${bo} = ${O}`, regroup: `${O} = 10 + ${left}`, tens: `${at} + ${bt} + 1 = ${count(T, "ten")}`, total: `${a} + ${b} = ${sum}` },
      alt: `${a} as ${count(at, "ten")} and ${count(ao, "one")}, ${b} as ${count(bt, "ten")} and ${count(bo, "one")}. ${count(O, "one")} make a ten and ${count(left, "one")}; ${count(T, "ten")} and ${count(left, "one")} make ${sum}.`,
    }),
    caption: `${count(O, "one")} are too many for one place: trade ten of them for a ten.`,
    timeline: beats(5),
    steps: [
      { id: "ones", narration: `Ones first: ${ao} + ${bo} = ${O}.`, math: [num(ao), op("+"), num(bo), op("="), num(O)], state: 1, answerStep: "ones", result: O },
      { id: "regroup", narration: `${O} is 1 ten and ${left} one${left === 1 ? "" : "s"}. Write ${left} and carry the ten.`, math: [num(O), op("="), num(10), op("+"), num(left)], state: 2, answerStep: "regroup", result: left },
      { id: "tens", narration: `Tens: ${at} + ${bt} + the 1 you carried = ${T}.`, math: [num(at), op("+"), num(bt), op("+"), num(1), op("="), num(T)], state: 3, answerStep: "tens", result: T },
      { id: "answer", narration: `${count(T, "ten")} and ${left} one${left === 1 ? "" : "s"} is ${sum}.`, math: [num(a), op("+"), num(b), op("="), num(sum)], state: 4, answerStep: "answer", result: sum },
    ],
  };
}

export const lesson: LessonDefinition<RegroupProblem> = {
  id: "g2-regroup",
  grade: 2,
  unit: "Adding and subtracting",
  title: "Adding with regrouping",
  reference: createRegroup(47, 38),
  generate: rng => generateRegroup(rng),
  restore: raw => { const r = readNumbers(raw, ["a", "b"] as const); try { return r && createRegroup(r.a, r.b); } catch { return null; } },
  display: p => [num(p.a), op("+"), num(p.b)],
  displayCounters: p => ({ op: "+", groups: [{ kind: "blocks", value: p.a }, { kind: "blocks", value: p.b }] }),
  answers: regroupAnswers,
  explain: explainRegroup,
  story: ({ a, b }) => ({ op: "+", text: `A class read **${a}** books in May and **${b}** books in June. How many books did they read in all?` }),
};
