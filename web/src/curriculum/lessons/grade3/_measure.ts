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
const OP_WHY = {
  "+": "Putting amounts together means adding.",
  "−": "Taking away, or finding how much more, means subtracting.",
  "×": "Equal groups means multiplying.",
  "÷": "Sharing equally, or splitting into groups, means dividing.",
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

/** pick the operation: the same choices and messages practice uses for word problems */
export function operationStep(o: Op, line: string): AnswerStep {
  const k = OPS.indexOf(o);
  return {
    id: "story", label: "Read the story", question: "Which operation solves it?", prompt: [],
    choices: OPS.map(x => `${x} ${OP_NAME[x]}`),
    slots: [{ id: "c", expected: k }],
    known: [],
    check: v => (v.c === k ? { ok: true } : { ok: false, kind: "Picked the wrong operation", message: "Read the story again. Is it putting together, taking away, equal groups, or sharing?", generic: false }),
    hint: OP_WHY[o], explain: OP_WHY[o],
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
    ]),
    hint: `${OP_NAME[o]}: ${withCommas(a)} ${o} ${withCommas(b)}.`,
    explain: `${withCommas(a)} ${o} ${withCommas(b)} = ${withCommas(ans)} ${unit}.`,
  });
}

export { aOrAn };
