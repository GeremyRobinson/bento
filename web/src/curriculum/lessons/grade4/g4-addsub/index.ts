// Add and subtract big numbers (new in the rebuild): line the numbers up by place and work one column at a time,
// carrying or trading a ten when a column needs it. The thousands and up are worked together at the end.
import { muted, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildColumns, columnWork } from "../../../../explanations/diagrams/early-g4/columns";
import { commas } from "../../../../explanations/diagrams/early-g4/place-value";
import { expectedOf, oneBox, restoreVia } from "../../_number-line/steps";
import { slips } from "../_kit";

/** a + b, or a − b when sub is 1. */
export interface AddSubProblem { a: number; b: number; sub: number }

const PLURAL = ["ones", "tens", "hundreds", "thousands"], ONE = ["one", "ten", "hundred", "thousand"];
const digit = (n: number, i: number) => Math.floor(n / 10 ** i) % 10;

export function createAddSub(a: number, b: number, sub: number): AddSubProblem {
  if (![a, b].every(x => Number.isInteger(x) && x >= 1000 && x <= 99999) || (sub !== 0 && sub !== 1)) throw new Error(`not a big add or subtract: ${a}, ${b}`);
  if (sub) {
    if (a <= b) throw new Error("the first number must be bigger");
    // a ten is only ever traded from a digit that has one to give (no trading across a zero)
    const { cols } = columnWork(a, b, "−");
    cols.forEach((c, i) => { if (c.regroup && digit(a, i + 1) === 0) throw new Error("trading across a zero"); });
    if (Math.floor((a - b) / 1000) < 1) throw new Error("the answer keeps its thousands");
  }
  return { a, b, sub };
}

function makeAdd(rng: Rng, digits: number) {
  for (;;) {
    const a = rng.int(10 ** (digits - 1), 10 ** digits - 1), b = rng.int(10 ** (digits - 1), 10 ** digits - 1);
    if (columnWork(a, b, "+").cols.some(c => c.regroup)) return createAddSub(a, b, 0);
  }
}

function makeSub(rng: Rng, digits: number) {
  for (;;) {
    const a = rng.int(10 ** (digits - 1) * 2, 10 ** digits - 1), b = rng.int(10 ** (digits - 1), a - 1000);
    if (!columnWork(a, b, "−").cols.some(c => c.regroup)) continue;
    try { return createAddSub(a, b, 1); } catch { /* try again */ }
  }
}

/** Early problems are four-digit numbers; later ones have five digits. Adding and subtracting take turns at random. */
export function generateAddSub(rng: Rng, index: number): AddSubProblem {
  const digits = index < 4 ? 4 : 5;
  return rng.next() < 0.5 ? makeAdd(rng, digits) : makeSub(rng, digits);
}

const sign = (p: AddSubProblem) => (p.sub ? "−" : "+") as "+" | "−";
const result = (p: AddSubProblem) => (p.sub ? p.a - p.b : p.a + p.b);

/** The thousands and up, as counts of thousands: what the last step adds or subtracts. */
function thousands(p: AddSubProblem) {
  const { cols, carryOut } = columnWork(p.a, p.b, sign(p));
  return { A: Math.floor(p.a / 1000), B: Math.floor(p.b / 1000), carry: carryOut, cols };
}

function columnStep(p: AddSubProblem, i: number): AnswerStep {
  const { cols } = columnWork(p.a, p.b, sign(p)), c = cols[i]!, name = PLURAL[i]!, up = PLURAL[i + 1]!;
  const prev = PLURAL[i - 1];
  if (!p.sub) {
    const sum = c.top + c.bottom + c.carryIn;
    const prompt = (s: MathText[number]): MathText => [num(c.top), op("+"), num(c.bottom), ...(c.carryIn ? [op("+"), num(1)] : []), op("="), s];
    const after = sum >= 10 ? `Write ${sum % 10} and carry 1 to the ${up}.` : `Write ${sum}.`;
    return oneBox({
      id: name, label: `Add the ${name}`,
      question: c.carryIn ? `Add the ${name}, and the 1 you carried.` : `Add the ${name}.`,
      prompt, ans: sum,
      wrong: slips(sum, [
        ...(c.carryIn ? [[sum - 1, "Forgot the carried 1", `You carried 1 from the ${prev}. Add it in too.`] as [number, string, string]] : []),
        ...(sum >= 10 ? [[sum % 10, "Wrote only the digit", `${sum % 10} is the digit you write, but the ${name} add up to ${sum}. The 1 goes to the ${up}.`] as [number, string, string]] : []),
      ]),
      hint: c.carryIn ? `Add the two digits and the carried 1.` : "Add the two digits.",
      explain: `${c.top} + ${c.bottom}${c.carryIn ? " + 1" : ""} = ${sum}. ${after}`,
      work: [...prompt(num(sum)), muted(sum >= 10 ? ` (write ${sum % 10}, carry 1)` : ` (write ${sum})`)],
    });
  }
  const top = c.regroup ? c.top + 10 : c.top, w = c.write;
  const prompt = (s: MathText[number]): MathText => [num(top), op("−"), num(c.bottom), op("="), s];
  const lent = c.carryIn ? `You traded 1 ${ONE[i]} away, so the ${digit(p.a, i)} is now ${c.top}. ` : "";
  const question = c.regroup
    ? `${lent}${c.top} is less than ${c.bottom}, so trade 1 ${ONE[i + 1]} for 10 ${name}.`
    : `${lent}Subtract the ${name}.`;
  return oneBox({
    id: name, label: `Subtract the ${name}`, question, prompt, ans: w,
    wrong: slips(w, [
      ...(c.regroup ? [[c.bottom - c.top, "Took the smaller from the bigger", `You can't take ${c.bottom} from ${c.top}. Trade first, then work out ${top} − ${c.bottom}.`] as [number, string, string]] : []),
      ...(c.carryIn && digit(p.a, i) + (c.regroup ? 10 : 0) - c.bottom >= 0
        ? [[digit(p.a, i) + (c.regroup ? 10 : 0) - c.bottom, "Forgot the ten you traded", `The ${digit(p.a, i)} gave 1 to the ${prev}, so it is ${c.top} now.`] as [number, string, string]] : []),
    ]),
    hint: c.regroup ? `${top} − ${c.bottom}: count up from ${c.bottom} to ${top}.` : `${c.top} − ${c.bottom}.`,
    explain: c.regroup ? `Trade 1 ${ONE[i + 1]} for 10 ${name}: ${c.top} becomes ${top}. ${top} − ${c.bottom} = ${w}.` : `${c.top} − ${c.bottom} = ${w}.`,
  });
}

function answers(p: AddSubProblem): AnswerModel {
  const R = result(p), { A, B, carry, cols } = thousands(p), s = sign(p);
  const TH = p.sub ? A - carry - B : A + B + carry;
  const rest = (n: number) => commas(n);
  let wrong: [number, string, string][];
  if (!p.sub) {
    const noCarry = cols.reduce((acc, c, i) => acc + ((c.top + c.bottom) % 10) * 10 ** i, 0) + (A + B) * 1000;
    wrong = slips(R, [
      ...(carry ? [[R - 1000, "Forgot the carried 1", "You carried 1 from the hundreds. Add it to the thousands too."] as [number, string, string]] : []),
      [noCarry, "Forgot to carry", "When a column makes 10 or more, write the ones digit and carry the 1 to the next place."],
    ]);
  } else {
    const smallFromBig = cols.reduce((acc, c, i) => acc + Math.abs(digit(p.a, i) - c.bottom) * 10 ** i, 0) + (A - B) * 1000;
    const noPayBack = R + cols.reduce((acc, c, i) => acc + (c.regroup ? 10 ** (i + 1) : 0), 0);
    wrong = slips(R, [
      [smallFromBig, "Took the smaller from the bigger", "In each column take the bottom digit from the top one. When the top is smaller, trade a ten first."],
      [noPayBack, "Forgot to cross out", "When a place trades a ten away, it has 1 less. Cross it out and write the new digit."],
      ...(carry ? [[R + 1000, "Forgot the traded thousand", `The thousands gave 1 to the hundreds, so ${A} is ${A - 1} now.`] as [number, string, string]] : []),
    ]);
  }
  const thLine = p.sub ? `${A}${carry ? " − 1" : ""} − ${B} = ${TH}` : `${A} + ${B}${carry ? " + 1" : ""} = ${TH}`;
  return {
    steps: [
      columnStep(p, 0),
      columnStep(p, 1),
      columnStep(p, 2),
      oneBox({
        id: "answer", label: p.sub ? "Subtract the thousands" : "Add the thousands",
        question: p.sub
          ? `Now the thousands${carry ? ", after the one you traded" : ""}. Then read the whole answer.`
          : `Now the thousands${carry ? ", and the 1 you carried" : ""}. Then read the whole answer.`,
        prompt: x => [text(rest(p.a)), op(s), text(rest(p.b)), op("="), x], ans: R, wrong,
        hint: `Thousands: ${p.sub ? `${A}${carry ? " − 1" : ""} − ${B}` : `${A} + ${B}${carry ? " + 1" : ""}`}. Then put the digits you wrote after it.`,
        explain: `Thousands: ${thLine}. With the digits below, the answer is ${rest(R)}.`,
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: AddSubProblem, model: AnswerModel): Explanation {
  const s = sign(p), { cols, carry, A, B } = thousands(p);
  const vals = ["ones", "tens", "hundreds"].map(id => expectedOf(model, id)), R = expectedOf(model, "answer");
  const TH = Math.floor(R / 1000);
  const say = (i: number) => {
    const c = cols[i]!, name = PLURAL[i]!, v = vals[i]!;
    if (!p.sub) {
      const sum = `${c.top} + ${c.bottom}${c.carryIn ? " + 1" : ""} = ${v}`;
      return v >= 10 ? `The ${name}: ${sum}. Write ${v % 10} and carry 1 to the ${PLURAL[i + 1]}.` : `The ${name}: ${sum}. Write ${v}.`;
    }
    if (c.regroup) return `The ${name}: ${c.top} is less than ${c.bottom}, so trade 1 ${ONE[i + 1]} for 10 ${name}. ${c.top + 10} − ${c.bottom} = ${v}.`;
    return `The ${name}: ${c.top} − ${c.bottom} = ${v}.`;
  };
  const mathOf = (i: number): MathText => {
    const c = cols[i]!, v = vals[i]!;
    return p.sub ? [num(c.regroup ? c.top + 10 : c.top), op("−"), num(c.bottom), op("="), num(v)]
      : [num(c.top), op("+"), num(c.bottom), ...(c.carryIn ? [op("+"), num(1)] : []), op("="), num(v)];
  };
  const thSay = p.sub ? `${A}${carry ? " − 1" : ""} − ${B} = ${TH}` : `${A} + ${B}${carry ? " + 1" : ""} = ${TH}`;
  return {
    heading: p.sub ? "Subtract one place at a time" : "Add one place at a time",
    idea: ["Each place holds only 0 to 9, so 10 in one place trades for 1 in the next."],
    statement: [text(commas(p.a)), op(s), text(commas(p.b))],
    diagram: buildColumns({
      a: p.a, b: p.b, sign: s, beats: { ones: 1, tens: 2, hundreds: 3, rest: 4 },
      alt: `${commas(p.a)} ${s} ${commas(p.b)} in columns, worked from the ones to the thousands, makes ${commas(R)}.`,
    }),
    caption: p.sub ? "Ones first. Trade when the top digit is too small." : "Ones first. Carry when a column makes 10 or more.",
    timeline: beats(5),
    steps: [
      { id: "start", state: 0, narration: `Line up ${commas(p.a)} and ${commas(p.b)} so the ones are under the ones.`, math: [text(commas(p.a)), op(s), text(commas(p.b))] },
      ...[0, 1, 2].map(i => ({ id: PLURAL[i]!, state: i + 1, answerStep: PLURAL[i]!, result: vals[i]!, narration: say(i), math: mathOf(i) })),
      { id: "answer", state: 4, answerStep: "answer", result: R, math: [text(commas(p.a)), op(s), text(commas(p.b)), op("="), text(commas(R))],
        narration: `The thousands: ${thSay}. Read it all together: ${commas(R)}.` },
    ],
  };
}

export const lesson: LessonDefinition<AddSubProblem> = {
  id: "g4-addsub",
  grade: 4,
  unit: "Whole numbers",
  title: "Add and subtract big numbers",
  pre: "g3-addsub",
  reference: createAddSub(4637, 2785, 0),
  generate: (rng, index) => generateAddSub(rng, index),
  restore: raw => restoreVia(raw, ["a", "b", "sub"] as const, v => createAddSub(v.a, v.b, v.sub)),
  display: p => [text(commas(p.a)), op(sign(p)), text(commas(p.b))],
  answers,
  explain,
  story: p => p.sub
    ? { op: "−", text: `A stadium has **${commas(p.a)}** seats. **${commas(p.b)}** of them are full. How many seats are empty?` }
    : { op: "+", text: `A library has **${commas(p.a)}** books. It gets **${commas(p.b)}** more. How many books does it have now?` },
};
