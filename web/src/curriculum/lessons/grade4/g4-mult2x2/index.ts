// Two-digit times two-digit: split both numbers into tens and ones, multiply the four parts of the area model, add them.
import { answer, num, op } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildAreaGrid } from "../../../../explanations/diagrams/area-model/grid";
import { expectedOf, numStep, plusChain, readNumbers } from "../../area-common/steps";
import { slips } from "../_kit";
import { aOrAn } from "../../../text";
const capA = (x: string) => x[0]!.toUpperCase() + x.slice(1);
import { withCommas } from "../../_number-line/steps";

/** a × b, both two-digit and neither a multiple of 10, so all four parts exist */
export interface TwoByTwoProblem { a: number; b: number }

export function createTwoByTwo(a: number, b: number): TwoByTwoProblem {
  for (const [k, v] of [["a", a], ["b", b]] as const) if (!Number.isInteger(v) || v < 11 || v > 99 || v % 10 === 0) throw new Error(`${k} is two-digit, not a multiple of 10`);
  return { a, b };
}

const split = ({ a, b }: TwoByTwoProblem) => ({ t: Math.floor(a / 10), u: a % 10, s: Math.floor(b / 10), v: b % 10 });
const tens = (n: number) => (n === 1 ? "1 ten" : `${n} tens`);
const cap = (x: string) => x[0]!.toUpperCase() + x.slice(1);
const IDS = ["tt", "to", "ot", "oo"] as const;

export function parts(p: TwoByTwoProblem) {
  const { t, u, s, v } = split(p);
  return [[10 * t, 10 * s], [10 * t, v], [u, 10 * s], [u, v]] as [number, number][];
}

function answers(p: TwoByTwoProblem): AnswerModel {
  const { t, u, s, v } = split(p), P = parts(p).map(([x, y]) => x * y), ts = t * s, total = p.a * p.b;
  const names = ["tens × tens", "tens × ones", "ones × tens", "ones × ones"];
  return {
    steps: [
      numStep({ id: "tt", label: "Tens × tens", prompt: x => [num(10 * t), op("×"), num(10 * s), op("="), x], ans: P[0]!,
        wrong: slips(P[0]!, [[ts * 10, "Lost a zero", `Tens times tens makes hundreds: ${t} × ${s} = ${ts}, so ${withCommas(P[0]!)}.`], [ts, "Left off the zeros", `That's ${t} × ${s}. Both are tens, so put two zeros on it.`]]),
        hint: `${t} × ${s} = ${ts}, and tens times tens is hundreds.`, explain: `${t} × ${s} = ${ts}, so ${10 * t} × ${10 * s} = ${withCommas(P[0]!)}.`, work: [num(10 * t), op("×"), num(10 * s), op("="), num(P[0]!)] }),
      numStep({ id: "to", label: "Tens × ones", prompt: x => [num(10 * t), op("×"), num(v), op("="), x], ans: P[1]!,
        wrong: slips(P[1]!, [[t * v, "Lost the place value", `${10 * t} is ${tens(t)}. ${cap(tens(t))} × ${v} is ${tens(t * v)}: ${P[1]}.`]]),
        hint: `${t} × ${v}, then one zero.`, explain: `${10 * t} × ${v} = ${P[1]}.`, work: [num(10 * t), op("×"), num(v), op("="), num(P[1]!)] }),
      numStep({ id: "ot", label: "Ones × tens", prompt: x => [num(u), op("×"), num(10 * s), op("="), x], ans: P[2]!,
        wrong: slips(P[2]!, [[u * s, "Lost the place value", `${10 * s} is ${tens(s)}. ${u} × ${tens(s)} is ${tens(u * s)}: ${P[2]}.`]]),
        hint: `${u} × ${s}, then one zero.`, explain: `${u} × ${10 * s} = ${P[2]}.`, work: [num(u), op("×"), num(10 * s), op("="), num(P[2]!)] }),
      numStep({ id: "oo", label: "Ones × ones", prompt: x => [num(u), op("×"), num(v), op("="), x], ans: P[3]!,
        wrong: slips(P[3]!, [[u + v, "Added instead", "This one is times, not plus."], [P[3]! - 1, "Fact slip", `Close. Skip-count by ${v}s, ${u} times.`], [P[3]! + 1, "Fact slip", `Close. Skip-count by ${v}s, ${u} times.`], [u * (v - 1), "One group short", `That's ${u} × ${v - 1}. Skip-count by ${v}s, ${u} times.`], [u * (v + 1), "One group too many", `That's ${u} × ${v + 1}. Skip-count by ${v}s, ${u} times.`]]),
        hint: u === 1 ? "Times 1 leaves a number as it is." : `${u} groups of ${v}: skip-count by ${v}s.`, explain: `${u} × ${v} = ${P[3]}.`, work: [num(u), op("×"), num(v), op("="), num(P[3]!)] }),
      numStep({ id: "sum", label: "Add the parts", prompt: x => [...plusChain(P), op("="), x], ans: total,
        wrong: slips(total, [
          [P[0]! + P[3]!, "Added only the corners", "That's only the two corners. Add the middle parts too."],
          ...P.map((x, i) => [total - x, "Left out a part", `Four parts, four numbers to add. Did you add the ${names[i]} part, ${withCommas(x)}?`] as [number, string, string]),
        ]),
        hint: "Line them up by place value and add all four.", explain: `${P.map(withCommas).join(" + ")} = ${withCommas(total)}.`, work: [num(p.a), op("×"), num(p.b), op("="), answer("x", total)] }),
    ],
    finalParts: [-1],
  };
}

function explain(p: TwoByTwoProblem, model: AnswerModel): Explanation {
  const { t, u, s, v } = split(p), P = IDS.map(id => expectedOf(model.steps, id)), total = expectedOf(model.steps, "sum");
  const pr = parts(p);
  return {
    heading: "Split both numbers",
    idea: ["Each number is tens plus ones, so the big rectangle cuts into four easy pieces."],
    statement: [num(p.a), op("×"), num(p.b)],
    diagram: buildAreaGrid({
      cols: [{ label: String(10 * t), size: 10 * t }, { label: String(u), size: u }],
      rows: [{ label: String(10 * s), size: 10 * s }, { label: String(v), size: v }],
      cells: [[{ text: withCommas(P[0]!), textFrom: 1, focus: [1] }, { text: withCommas(P[2]!), textFrom: 3, focus: [3] }], [{ text: withCommas(P[1]!), textFrom: 2, focus: [2] }, { text: withCommas(P[3]!), textFrom: 4, focus: [4] }]],
      seats: 0,
      lines: [{ text: `${P.map(withCommas).join(" + ")} = ${withCommas(total)}`, from: 5 }],
      alt: `${capA(aOrAn(p.a))} ${p.a} by ${p.b} rectangle split into four parts at the tens: ${pr.map(([x, y], i) => `${x} × ${y} = ${P[i]}`).join(", ")}. Together ${total}.`,
    }),
    caption: `${p.a} = ${10 * t} + ${u} and ${p.b} = ${10 * s} + ${v}: four parts.`,
    timeline: beats(6),
    steps: [
      { id: "split", narration: `Split both: ${p.a} is ${10 * t} + ${u}, ${p.b} is ${10 * s} + ${v}.`, math: [num(p.a), op("×"), num(p.b)], state: 0 },
      ...IDS.map((id, i) => ({ id, narration: model.steps[i]!.explain, math: model.steps[i]!.work!, state: i + 1, answerStep: id, result: P[i]! })),
      { id: "sum", narration: `Add the four parts: ${withCommas(total)}.`, math: [...plusChain(P), op("="), num(total)], state: 5, answerStep: "sum", result: total },
    ],
  };
}

export const lesson: LessonDefinition<TwoByTwoProblem> = {
  id: "g4-mult2x2",
  grade: 4,
  unit: "Whole numbers",
  title: "Two-digit times two-digit",
  pre: "g4-partial",
  reference: createTwoByTwo(34, 26),
  generate: (rng, index) => {
    const pick = (lo: number, hi: number) => { for (;;) { const n = rng.int(lo, hi); if (n % 10) return n; } };
    return index < 3 ? createTwoByTwo(pick(11, 29), pick(11, 19)) : createTwoByTwo(pick(12, 99), pick(12, 49));
  },
  restore: raw => { const r = readNumbers(raw, ["a", "b"] as const); try { return r && createTwoByTwo(r.a, r.b); } catch { return null; } },
  display: p => [num(p.a), op("×"), num(p.b)],
  answers,
  explain,
  story: p => ({ op: "×", text: `A theater has **${p.a}** rows of **${p.b}** seats. How many seats are there?` }),
};
