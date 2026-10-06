// Shared by the 3rd grade measuring lessons (g3-mass, g3-liters): one-step word problems about grams, kilograms and
// liters. The operation step matches the one practice puts before every third word problem.
import { num, op, text } from "../../schemas/math-text";
import type { AnswerStep } from "../../schemas/lesson";
import { oneBox } from "../_number-line/steps";
import { slips } from "../grade2/kit";
import { aOrAn } from "../../text";

export const OPS = ["+", "−", "×", "÷"] as const;
export type Op = (typeof OPS)[number];
const OP_NAME = { "+": "Add", "−": "Subtract", "×": "Multiply", "÷": "Divide" } as const;
/** why the story's operation fits, said with the story's own first amount */
const OP_WHY = (o: Op, a: number, unit: string) => ({
  "+": "Two amounts go together, so there will be more than either one. That's adding.",
  "−": `Some of it goes away, so there will be less than ${withCommas(a)} ${unit}. That's subtracting.`,
  "×": "There are equal groups, each the same amount. That's multiplying.",
  "÷": `${withCommas(a)} ${unit} is shared out equally, so each part gets less. That's dividing.`,
})[o];
/** what each wrong pick would mean, so the slip names the mix-up */
const OP_SLIP = {
  "+": ["Picked adding", "Adding puts amounts together and makes more. Does this story put two amounts together?"],
  "−": ["Picked subtracting", "Subtracting takes some away and leaves less. Does anything go away in this story?"],
  "×": ["Picked multiplying", "Multiplying counts equal groups of the same amount. Are there equal groups here?"],
  "÷": ["Picked dividing", "Dividing shares an amount out equally. Is anything being shared out here?"],
} as const;
export const WHO = ["Maya", "Leo", "Ana", "Sam", "Noor", "Eli"];

export const apply = (o: Op, a: number, b: number) => (o === "+" ? a + b : o === "−" ? a - b : o === "×" ? a * b : a / b);
export const withCommas = (n: number) => n.toLocaleString("en-US");

/** a story's numbers fit its operation: sums and differences up to `most`, × and ÷ inside the times tables */
export function checkStory(o: number, a: number, b: number, most: number) {
  const op = OPS[o];
  if (!op || !Number.isInteger(a) || !Number.isInteger(b) || a < 1 || b < 1) throw new Error("a story needs two whole amounts");
  if (op === "+" && a + b > 2 * most) throw new Error("too big");
  if (op === "+" && (a > most || b > most)) throw new Error("too big");
  if (op === "−" && (a > most || b >= a)) throw new Error("take away less than you have");
  if (op === "×" && (a < 2 || a > 10 || b < 2 || b > 10)) throw new Error("times tables");
  if (op === "÷" && (b < 2 || b > 10 || a % b !== 0 || a / b > 10 || a / b < 2)) throw new Error("times tables");
}

/** a random story's numbers for an operation */
export function storyNumbers(rng: { int: (lo: number, hi: number) => number }, o: number, most: number, round: number): [number, number] {
  const r = (lo: number, hi: number) => rng.int(Math.ceil(lo / round), Math.floor(hi / round)) * round;
  switch (OPS[o]) {
    case "+": return [r(round, most), r(round, most)];
    case "−": { const a = r(2 * round, most); return [a, r(round, a - round)]; }
    case "×": return [rng.int(2, 9), rng.int(2, 9)];
    default: { const b = rng.int(2, 9), q = rng.int(2, 9); return [b * q, b]; }
  }
}

/** pick the operation: the same choices practice uses for word problems; a is the story's first amount, in unit */
export function operationStep(o: Op, line: string, a: number, unit: string): AnswerStep {
  const k = OPS.indexOf(o);
  return {
    id: "story", label: "Read the story", question: "Which operation solves it?", prompt: [],
    choices: OPS.map(x => `${x} ${OP_NAME[x]}`),
    slots: [{ id: "c", expected: k }],
    known: OPS.flatMap((x, i) => (i === k ? [] : [{ values: { c: i }, kind: OP_SLIP[x][0], message: OP_SLIP[x][1] }])),
    hint: "What happens in the story? Are amounts put together, is some taken away, are there equal groups, or is an amount shared out?",
    explain: OP_WHY(o, a, unit),
    work: [text(`${line} (${OP_NAME[o].toLowerCase()})`)],
  };
}

/** solve: the answer with its unit, and the other operations' results as slips */
export function solveStep(o: Op, a: number, b: number, unit: string): AnswerStep {
  const ans = apply(o, a, b);
  const other = (x: Op, kind: string, msg: string): [number, string, string] | false => {
    const v = apply(x, a, b);
    return Number.isInteger(v) && v > 0 && [v, kind, msg];
  };
  return oneBox({
    id: "solve", label: "Solve", question: "What's the answer?",
    prompt: s => [num(a), op(o), num(b), op("="), s, text(` ${unit}`)], ans,
    wrong: slips(ans, [
      o !== "+" && other("+", "Added", o === "−" ? "The story takes some away. Subtract." : o === "×" ? "Equal groups: multiply, don't add." : "Sharing equally means dividing."),
      o !== "−" && other("−", "Subtracted", o === "+" ? "The story puts amounts together. Add." : "Read the story again: it isn't taking away."),
      o === "÷" && other("×", "Multiplied", "The amount is shared out, so it gets smaller. Divide."),
      [a, "Wrote the starting amount", o === "÷" ? `${withCommas(a)} ${unit} is the whole amount before it is shared. Share it into ${b} equal parts.` : o === "×" ? `${a} is how many groups there are. Each group is ${b} ${unit}, so multiply.` : `${withCommas(a)} ${unit} is where the story starts. ${OP_NAME[o]} ${withCommas(b)} to finish.`],
    ]),
    hint: `${OP_NAME[o]}: ${withCommas(a)} ${o} ${withCommas(b)}.`,
    explain: `${o === "+" ? "Put the amounts together" : o === "−" ? "Take the amount away" : o === "×" ? `${a} equal groups of ${withCommas(b)} ${unit}` : `${withCommas(a)} ${unit} shared into ${b} equal parts`}: ${withCommas(a)} ${o} ${withCommas(b)} = ${withCommas(ans)} ${unit}.`,
  });
}

export { aOrAn };
