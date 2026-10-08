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

/**
 * Both 15–79, ones adding to 10 or more, sum at most 99 (the current app's range). The first three problems are gentler:
 * the ones make 10 to 12 and the tens add to 6 or less.
 */
export function generateRegroup(rng: Rng, index = 9): RegroupProblem {
  let a: number, b: number;
  const early = index < 3;
  const ok = (a: number, b: number) => a % 10 + b % 10 >= 10 && a + b <= 99 && (!early || (a % 10 + b % 10 <= 12 && Math.floor(a / 10) + Math.floor(b / 10) <= 6));
  do { a = rng.int(early ? 11 : 15, early ? 49 : 79); b = rng.int(early ? 11 : 15, early ? 49 : 79); } while (!ok(a, b));
  return { a, b };
}

const parts = ({ a, b }: RegroupProblem) => {
  const at = Math.floor(a / 10), ao = a % 10, bt = Math.floor(b / 10), bo = b % 10;
  return { at, ao, bt, bo, O: ao + bo };
};

export function regroupAnswers(p: RegroupProblem): AnswerModel {
  const { a, b } = p, { at, ao, bt, bo, O } = parts(p), left = O % 10;
  return {
    steps: [
      numStep({ id: "ones", label: "Add the ones", prompt: x => [num(ao), op("+"), num(bo), op("="), x], ans: O,
        wrong: [[at + bt, "Started with the tens", `Those are the ten rods. Start with the ones cubes: ${ao} + ${bo}.`]],
        hint: `Add the ones cubes: ${ao} + ${bo}.`, explain: `${ao} + ${bo} = ${O}.`, work: [text("Ones: "), num(ao), op("+"), num(bo), op("="), num(O)] }),
      numStep({ id: "regroup", label: "Regroup", question: `${O} is 1 ten and how many ones?`, prompt: x => [text(`${O} ones = 1 ten + `), x, text(left === 1 ? " one" : " ones")], ans: left,
        wrong: [[O, "Regrouping", `${O} doesn't fit in the ones place. 10 of those ones became 1 ten.`]],
        hint: `${O} ones is too many for the ones place. Trade 10 of them for 1 ten rod. How many ones are left?`,
        explain: `${O} = 10 + ${left}. Keep ${left} ${left === 1 ? "one" : "ones"} and move the new ten to the tens.`,
        work: [text(`${O} ones = 1 ten + `), answer("x", left), text(left === 1 ? " one" : " ones")] }),
      numStep({ id: "tens", label: "Add the tens", question: "Add the ten rods, plus the new one you made.", prompt: x => [num(at), op("+"), num(bt), op("+"), num(1), op("="), x], ans: at + bt + 1,
        wrong: [[at + bt, "Forgot the carried ten", `You made a new ten rod from 10 ones. It goes with the tens: ${at} + ${bt} + 1.`]],
        hint: `Count the ten rods: ${at} + ${bt}, plus the new rod you made.`, explain: `${at} + ${bt} + 1 = ${at + bt + 1}.`, work: [text("Tens: "), num(at), op("+"), num(bt), op("+"), num(1), op("="), num(at + bt + 1)] }),
      numStep({ id: "answer", label: "Answer", prompt: x => [num(a), op("+"), num(b), op("="), x], ans: a + b,
        wrong: [[(at + bt) * 10 + left, "Forgot the carried ten", `The new ten rod from the ones goes in the tens too: ${count(at + bt + 1, "ten")}, not ${at + bt}.`]],
        hint: "Put the tens and the ones you have now together.", explain: `${count(at + bt + 1, "ten")} and ${count(left, "one")} is ${a + b}.`, work: [num(a), op("+"), num(b), op("="), answer("x", a + b)] }),
    ],
    finalParts: [-1],
  };
}

export function explainRegroup(p: RegroupProblem, answers: AnswerModel): Explanation {
  const { a, b } = p, { at, ao, bt, bo } = parts(p);
  const O = expectedOf(answers.steps, "ones"), left = expectedOf(answers.steps, "regroup"), T = expectedOf(answers.steps, "tens"), sum = expectedOf(answers.steps, "answer");
  return {
    heading: "Trade ten ones for a ten",
    idea: ["Ten ones are the same as one ten, so trading them loses nothing."],
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
      { id: "regroup", narration: `${O} ones is too many for the ones place. Trade 10 of them for 1 ten rod: ${left} one${left === 1 ? " is" : "s are"} left, and the new ten moves to the tens.`, math: [num(O), op("="), num(10), op("+"), num(left)], state: 2, answerStep: "regroup", result: left },
      { id: "tens", narration: `Tens: ${at} + ${bt} + the new ten = ${T}.`, math: [num(at), op("+"), num(bt), op("+"), num(1), op("="), num(T)], state: 3, answerStep: "tens", result: T },
      { id: "answer", narration: `${count(T, "ten")} and ${left} one${left === 1 ? "" : "s"} is ${sum}.`, math: [num(a), op("+"), num(b), op("="), num(sum)], state: 4, answerStep: "answer", result: sum },
    ],
  };
}

export const lesson: LessonDefinition<RegroupProblem> = {
  id: "g2-regroup",
  grade: 2,
  unit: "Adding and subtracting",
  title: "Adding with regrouping",
  pre: "g1-addtens",
  reference: createRegroup(47, 38),
  generate: (rng, index) => generateRegroup(rng, index),
  restore: raw => { const r = readNumbers(raw, ["a", "b"] as const); try { return r && createRegroup(r.a, r.b); } catch { return null; } },
  display: p => [num(p.a), op("+"), num(p.b)],
  displayCounters: p => ({ op: "+", groups: [{ kind: "blocks", value: p.a }, { kind: "blocks", value: p.b }] }),
  answers: regroupAnswers,
  explain: explainRegroup,
  story: ({ a, b }) => ({ op: "+", text: `A class read **${a}** books in May and **${b}** books in June. How many books did they read in all?` }),
};
