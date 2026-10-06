import { num, op } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildNumberLine, fitRange, type Hop } from "../../../../explanations/diagrams/number-line/build";
import { box, restoreVia, wholeIn } from "../_kit/steps";
import { count } from "../../../text";

/** a + b (s = 1) or a − b (s = −1) within 1000, done as jumps of hundreds, tens and ones. */
export interface AddSubProblem { a: number; b: number; s: number }

export function createAddSub(a: number, b: number, s: number): AddSubProblem {
  if (s !== 1 && s !== -1) throw new Error("s is 1 (add) or −1 (subtract)");
  wholeIn("a", a, 100, 999);
  wholeIn("b", b, 11, 899);
  const r = a + s * b;
  wholeIn("the answer", r, 1, 1000);
  return { a, b, s };
}

/** Early problems add or take a two-digit number; later ones a three-digit number. b never has a zero digit, so every jump is there. */
export function generateAddSub(rng: Rng, index: number): AddSubProblem {
  const s = rng.next() < 0.5 ? 1 : -1;
  for (;;) {
    const H = index < 3 ? 0 : rng.int(1, 6), b = H * 100 + rng.int(1, 9) * 10 + rng.int(1, 9);
    const a = s === 1 ? rng.int(100, 999 - b) : rng.int(Math.max(100, b + 50), 999);
    if (a >= 100 && a <= 999 && a + s * b >= 1) return createAddSub(a, b, s);
  }
}

const NAMES: Record<number, [string, string]> = { 100: ["hundreds", "hundred"], 10: ["tens", "ten"], 1: ["ones", "one"] };
const sign = (s: number) => (s === 1 ? "+" : "−");

/** The jumps: one per place of b, biggest first, with where each starts and lands. */
export function jumps({ a, b, s }: AddSubProblem) {
  const out: { place: number; d: number; v: number; from: number; to: number }[] = [];
  let r = a;
  for (const place of [100, 10, 1]) {
    const d = Math.floor(b / place) % 10;
    if (!d) continue;
    const v = d * place;
    out.push({ place, d, v, from: r, to: r + s * v });
    r += s * v;
  }
  return out;
}

function jumpStep(p: AddSubProblem, j: ReturnType<typeof jumps>[number]): AnswerStep {
  const { s } = p, { place, d, v, from, to } = j, [many, one] = NAMES[place]!;
  const digit = from % (place * 10) - (from % place); // the digit's value in this place of the running number
  const wrong: [number, string, string][] = [];
  if (place > 1) wrong.push([from + s * d, `Jumped ${d} instead of ${v}`, `The ${d} in ${p.b} means ${d} ${d === 1 ? one : many}, so jump ${v}.`]);
  wrong.push([from - s * v, s === 1 ? "Took away instead of adding" : "Added instead of taking away", s === 1 ? `This is adding, so the number gets bigger.` : `This is taking away, so the number gets smaller.`]);
  if (s === 1 && place < 100 && digit + v >= place * 10) {
    wrong.push([to - place * 10, `Lost the new ${NAMES[place * 10]![1]}`, `${count(digit / place, one, many)} + ${count(d, one, many)} is ${count((digit + v) / place, one, many)}. That makes a new ${NAMES[place * 10]![1]}, so the next place goes up by 1.`]);
  }
  if (s === -1 && place < 100 && digit < v) {
    const flip = from - digit + (v - digit);
    wrong.push([flip, "Took the smaller from the bigger", `There ${digit === place ? "is" : "are"} only ${digit / place} ${digit === place ? one : many} in ${from}, fewer than ${d}, so the jump back of ${v} goes past ${from - digit}. Taking ${digit / place} from ${d} instead goes the wrong way.`]);
    wrong.push([to + place * 10, `Forgot the trade`, `When you trade 1 ${NAMES[place * 10]![1]} for 10 ${many}, the next place goes down by 1.`]);
  }
  return box({
    id: many, label: `${s === 1 ? "Add" : "Take away"} the ${many}`,
    prompt: x => [num(from), op(s === 1 ? "+" : "−"), num(v), op("="), x], ans: to, wrong,
    hint: `Count ${s === 1 ? "on" : "back"} ${d} ${d === 1 ? one : many} from ${from}.`,
    explain: `${from} ${sign(s)} ${v} = ${to}.`,
  });
}

function answers(p: AddSubProblem): AnswerModel {
  return { steps: jumps(p).map(j => jumpStep(p, j)), finalParts: [-1] };
}

/** An open number line: start at a, then one jump for each place of b. */
export function addSubPicture(p: AddSubProblem, model: AnswerModel) {
  const js = jumps(p), end = model.steps[model.steps.length - 1]!.slots[0]!.expected!;
  const { min, max, step } = fitRange([p.a, end], { maxTicks: 14, pad: 0, minStep: 10 });
  const hops: Hop[] = js.map((j, k) => ({ from: j.from, to: model.steps[k]!.slots[0]!.expected!, label: `${sign(p.s)}${j.v}`, beat: k + 1, start: k === 0 }));
  return buildNumberLine({
    min, max, step, width: 540,
    hops,
    marks: [{ v: p.a, label: String(p.a), beat: 0 }, { v: end, label: String(end), beat: js.length, cls: "dota" }],
    alt: `An open number line. Start at ${p.a}, then jump ${js.map(j => `${sign(p.s)}${j.v}`).join(", ")} to land on ${end}.`,
  });
}

function explain(p: AddSubProblem, model: AnswerModel): Explanation {
  const { a, b, s } = p, js = jumps(p);
  return {
    heading: s === 1 ? "Add in jumps" : "Take away in jumps",
    idea: ["Break the second number into hundreds, tens and ones.", `Start at the first number and jump ${s === 1 ? "forward" : "back"} one place at a time.`],
    statement: [num(a), op(s === 1 ? "+" : "−"), num(b)],
    diagram: addSubPicture(p, model),
    caption: `${b} is ${js.map(j => j.v).join(" + ")}.`,
    timeline: beats(js.length + 1),
    steps: js.map((j, k) => {
      const st = model.steps[k]!, to = st.slots[0]!.expected!;
      const [many, one] = NAMES[j.place]!;
      return {
        id: st.id, state: k + 1, answerStep: st.id, result: to,
        math: [num(j.from), op(s === 1 ? "+" : "−"), num(j.v), op("="), num(to)],
        narration: `${k === 0 ? `Start at ${a}. ` : ""}${s === 1 ? "Add" : "Take away"} ${j.d} ${j.d === 1 ? one : many}: ${j.from} ${sign(s)} ${j.v} = ${to}.${k === js.length - 1 ? ` So ${a} ${sign(s)} ${b} = ${to}.` : ""}`,
      };
    }),
  };
}

export const lesson: LessonDefinition<AddSubProblem> = {
  id: "g3-addsub",
  grade: 3,
  unit: "Place value",
  title: "Add and subtract within 1000",
  pre: "g2-within1000",
  reference: createAddSub(458, 275, 1),
  generate: generateAddSub,
  restore: raw => restoreVia(raw, ["a", "b", "s"] as const, v => createAddSub(v.a, v.b, v.s)),
  display: p => [num(p.a), op(p.s === 1 ? "+" : "−"), num(p.b)],
  answers,
  explain,
  story: ({ a, b, s }) => (s === 1
    ? { op: "+", text: `A school has **${a}** books. It gets **${b}** more. How many books does it have now?` }
    : { op: "−", text: `A farm has **${a}** apples. It sells **${b}** of them. How many apples are left?` }),
};
