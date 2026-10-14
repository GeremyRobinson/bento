import type { Band } from "../../curriculum/grades";
import { eq, round6 } from "../evaluation/numbers";

export type MistakeCategory = "sign" | "reuse" | "place" | "off1" | "digits" | "close" | "swap" | "flip" | "plan" | "method";

/** Name, what it means for the grown-up, and what to practise. Same wording as the current app. */
export const CATEGORIES: Record<MistakeCategory, [name: string, meaning: string, tip: string]> = {
  sign: ["Sign mix-up", "The size of the number was right but the sign was flipped.", "Before checking, ask: should this be positive or negative?"],
  reuse: ["Reused an earlier number", "Typed the answer from an earlier step instead of doing the new one.", "Read what each new step is asking before answering."],
  place: ["Place value or decimal point", "The digits were right but a zero or the decimal point was in the wrong place.", "Estimate first, then line up place values."],
  off1: ["Off by one", "The answer was exactly 1 off, usually a counting slip.", "Count again slowly, or check by working backwards."],
  digits: ["Digits mixed up", "The right digits typed in the wrong order.", "Read the answer back before tapping Check."],
  close: ["Arithmetic slip", "Right method, but the arithmetic was a little off.", "Estimate first. A quick estimate catches most of these."],
  swap: ["Boxes swapped", "The right numbers in the wrong boxes.", "Check which box is which before typing."],
  flip: ["Fraction flipped", "Top and bottom of the fraction were switched.", "The part goes on top and the whole on the bottom."],
  plan: ["Picked the wrong next step", "Knew how to do the steps but not which one comes next.", "Before solving, say the plan out loud: what has to happen first?"],
  method: ["Didn't know the step yet", "The answer wasn't close and didn't match a common slip.", "Watch the lesson again together, then try this step."],
};

/** What the student is told for each recognised slip. */
export const SAY: Partial<Record<MistakeCategory, string>> = {
  sign: "The size is right. Check the sign.",
  reuse: "That's the number from an earlier step. This step asks for something new.",
  place: "The digits look right. Check where the zeros or the decimal point go.",
  off1: "You're 1 away. Count again.",
  digits: "Right digits, wrong order. Read it back.",
  close: "Close. Do the math again.",
  swap: "Right numbers, wrong boxes. Swap them.",
  flip: "Top and bottom are flipped.",
};

const digitsOf = (x: number) => String(Math.abs(round6(x))).replace(".", "").split("").sort().join("");

/**
 * Names the slip behind an answer the lesson didn't predict.
 * expected / typed are keyed by slot id; earlier holds answers from the steps already done.
 */
export function diagnose(expected: Record<string, number>, typed: Record<string, number | null>, earlier: number[]): MistakeCategory {
  const ids = Object.keys(expected);
  if (ids.length === 2 && ids.includes("n") && ids.includes("d")) {
    const An = expected.n!, Ad = expected.d!, vn = typed.n, vd = typed.d;
    if (vn == null || vd == null) return "method";
    if (An !== 0 && eq(vn * An, vd * Ad) && !eq(vn, An)) return "flip";
    if (An !== 0 && eq(vn * Ad, -An * vd)) return "sign";
    return "method";
  }
  if (ids.length > 1) {
    const a = ids.map(k => expected[k]!), x = ids.map(k => typed[k] ?? NaN);
    const srt = (arr: number[]) => [...arr].sort((p, q) => p - q);
    const sx = srt(x);
    if (srt(a).every((t, i) => eq(t, sx[i]))) return "swap";
    if (ids.every(k => eq(typed[k], expected[k]) || eq(typed[k], -expected[k]!))) return "sign";
    return "method";
  }
  const a = expected[ids[0]!]!, x = typed[ids[0]!];
  if (x == null) return "method";
  if (a !== 0 && eq(x, -a)) return "sign";
  if (earlier.some(e => eq(e, x))) return "reuse";
  if (a !== 0 && [10, 100, 1000, 0.1, 0.01, 0.001].some(f => eq(x, a * f))) return "place";
  if (Number.isInteger(a) && eq(Math.abs(x - a), 1)) return "off1";
  if (Math.abs(a) >= 10 && digitsOf(x) === digitsOf(a)) return "digits";
  if (a !== 0 && Math.abs(x - a) / Math.abs(a) <= 0.1) return "close";
  return "method";
}

/** For an answer we don't recognise: too big, too small, or which boxes are right already. */
export function nudge(expected: Record<string, number>, typed: Record<string, number | null>, band: Band): string {
  const ids = Object.keys(expected), little = band === "little";
  const say = (got: number, want: number) =>
    eq(got, want) ? "" : got > want ? (little ? "Too many. Count again." : "That's too big.") : (little ? "Too few. Count again." : "That's too small.");
  if (ids.includes("n") && ids.includes("d")) {
    const vn = typed.n, vd = typed.d;
    if (vn == null || !vd) return "";
    const want = (expected.w ?? 0) + expected.n! / expected.d!, got = (typed.w ?? 0) + vn / vd;
    return eq(want, got) ? "That's the right amount, but write it the way this step asks." : say(got, want);
  }
  if (ids.length > 1) {
    const right = ids.filter(k => eq(typed[k], expected[k])).length;
    const others = ids.length - right;
    return right ? `${right === 1 ? "One box is" : `${right} boxes are`} right. Check the other${others === 1 ? "" : "s"}.` : "";
  }
  const x = typed[ids[0]!];
  return x == null ? "" : say(x, expected[ids[0]!]!);
}
