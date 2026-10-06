// Order of operations (the current app's g5-order), in three shapes that take turns:
// t = 0: a + b × (c − d),  t = 1: (a + b) × c − d,  t = 2: a × b − c ÷ d.
import { formatNumber, mark, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { chainExplanation, type ChainBeat } from "../../../../explanations/diagrams/chain/build";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { orderPicture } from "./picture";

export interface OrderProblem { t: 0 | 1 | 2; a: number; b: number; c: number; d: number }

export function createOrder(t: number, a: number, b: number, c: number, d: number): OrderProblem {
  if (t !== 0 && t !== 1 && t !== 2) throw new Error("t is 0, 1 or 2");
  if (t === 2) {
    wholeIn("a", a, 3, 9); wholeIn("b", b, 3, 9); wholeIn("d", d, 2, 6);
    if (c % d !== 0 || c < d || c > a * b) throw new Error("c is a multiple of d, no bigger than a × b");
  } else {
    wholeIn("a", a, 2, 9); wholeIn("b", b, 2, 9); wholeIn("c", c, 5, 12); wholeIn("d", d, 1, c - 1);
  }
  return { t, a, b, c, d };
}

const P = (...m: MathText) => [text("("), ...m, text(")")];

/** the expression as written, with an optional part marked */
function expression({ t, a, b, c, d }: OrderProblem): MathText {
  return t === 1 ? [...P(num(a), op("+"), num(b)), op("×"), num(c), op("−"), num(d)]
    : t === 2 ? [num(a), op("×"), num(b), op("−"), num(c), op("÷"), num(d)]
    : [num(a), op("+"), num(b), op("×"), ...P(num(c), op("−"), num(d))];
}

function answers(p: OrderProblem): AnswerModel {
  const { t, a, b, c, d } = p;
  const steps = t === 1 ? [
    oneBox({ id: "s0", label: "Parentheses first", prompt: s => [num(a), op("+"), num(b), op("="), s], ans: a + b, hint: "Work inside the parentheses first." }),
    oneBox({ id: "s1", label: "Multiply next", prompt: s => [num(a + b), op("×"), num(c), op("="), s], ans: (a + b) * c, hint: "Multiplication comes before subtraction.",
      wrong: [[(a + b) * (c - d), "Subtracted first", `Multiply before you subtract: ${a + b} × ${c}.`]] }),
    oneBox({ id: "s2", label: "Subtract last", prompt: s => [num((a + b) * c), op("−"), num(d), op("="), s], ans: (a + b) * c - d, hint: "Now subtract." }),
  ] : t === 2 ? [
    oneBox({ id: "s0", label: "Multiply", prompt: s => [num(a), op("×"), num(b), op("="), s], ans: a * b, hint: "× and ÷ come before −." }),
    oneBox({ id: "s1", label: "Divide", prompt: s => [num(c), op("÷"), num(d), op("="), s], ans: c / d, hint: "× and ÷ come before −, so divide before you subtract." }),
    oneBox({ id: "s2", label: "Subtract last", prompt: s => [num(a * b), op("−"), num(c / d), op("="), s], ans: a * b - c / d, hint: "Now subtract.",
      wrong: [[(a * b - c) / d, "Worked left to right", `Divide ${c} ÷ ${d} first, then subtract it from ${a * b}.`]] }),
  ] : [
    oneBox({ id: "s0", label: "Parentheses first", prompt: s => [num(c), op("−"), num(d), op("="), s], ans: c - d, hint: "Work inside the parentheses first." }),
    oneBox({ id: "s1", label: "Multiply next", prompt: s => [num(b), op("×"), num(c - d), op("="), s], ans: b * (c - d), hint: "Multiplication comes before addition.",
      wrong: [[(a + b) * (c - d), "Worked left to right", `Multiply before you add. Do only ${b} × ${c - d} here.`]] }),
    oneBox({ id: "s2", label: "Add last", prompt: s => [num(a), op("+"), num(b * (c - d)), op("="), s], ans: a + b * (c - d), hint: "Now add." }),
  ];
  return { steps, finalParts: [-1] };
}

function explain(p: OrderProblem, model: AnswerModel) {
  const { t, a, b, c, d } = p;
  const r0 = expectedOf(model, "s0"), r1 = expectedOf(model, "s1"), r2 = expectedOf(model, "s2");
  const beat = (i: number, narration: string, math: MathText, lines: MathText[], result: number): ChainBeat =>
    ({ id: `s${i}`, narration, math, lines, answerStep: `s${i}`, result });
  const beats: ChainBeat[] = t === 1 ? [
    beat(0, `Parentheses first: ${a} + ${b} = ${r0}.`, [num(a), op("+"), num(b), op("="), num(r0)],
      [[mark(P(num(a), op("+"), num(b))), op("×"), num(c), op("−"), num(d)]], r0),
    beat(1, `Then multiply: ${r0} × ${c} = ${r1}. Multiplying comes before subtracting.`, [num(r0), op("×"), num(c), op("="), num(r1)],
      [[mark([num(r0), op("×"), num(c)]), op("−"), num(d)]], r1),
    beat(2, `Then subtract: ${r1} − ${d} = ${r2}.`, [num(r1), op("−"), num(d), op("="), num(r2)],
      [[mark([num(r1), op("−"), num(d)])], [num(r2)]], r2),
  ] : t === 2 ? [
    beat(0, `Multiply first: ${a} × ${b} = ${r0}.`, [num(a), op("×"), num(b), op("="), num(r0)],
      [[mark([num(a), op("×"), num(b)]), op("−"), num(c), op("÷"), num(d)]], r0),
    beat(1, `Divide before you subtract: ${c} ÷ ${d} = ${r1}.`, [num(c), op("÷"), num(d), op("="), num(r1)],
      [[num(r0), op("−"), mark([num(c), op("÷"), num(d)])]], r1),
    beat(2, `Then subtract: ${r0} − ${r1} = ${r2}.`, [num(r0), op("−"), num(r1), op("="), num(r2)],
      [[mark([num(r0), op("−"), num(r1)])], [num(r2)]], r2),
  ] : [
    beat(0, `Parentheses first: ${c} − ${d} = ${r0}.`, [num(c), op("−"), num(d), op("="), num(r0)],
      [[num(a), op("+"), num(b), op("×"), mark(P(num(c), op("−"), num(d)))]], r0),
    beat(1, `Then multiply: ${b} × ${r0} = ${r1}.`, [num(b), op("×"), num(r0), op("="), num(r1)],
      [[num(a), op("+"), mark([num(b), op("×"), num(r0)])]], r1),
    beat(2, `Then add: ${a} + ${r1} = ${r2}.`, [num(a), op("+"), num(r1), op("="), num(r2)],
      [[mark([num(a), op("+"), num(r1)])], [num(r2)]], r2),
  ];
  // the slip the current app's card warns about, worked out for this problem
  const leftToRight = t === 1 ? null : t === 2 ? (a * b - c) / d : (a + b) * (c - d);
  return chainExplanation({
    heading: "Parentheses, then × and ÷, then + and −",
    idea: ["Work inside parentheses first. Then multiply and divide. Add and subtract last."],
    statement: expression(p),
    ...(leftToRight != null && Number.isInteger(leftToRight) && leftToRight !== r2 ? { caption: `Going left to right would give ${formatNumber(leftToRight)}, which is wrong.` } : {}),
    alt: `Order of operations, one step per line, ending at ${r2}.`,
    diagram: orderPicture({ t, a, b, c, d, r0, r1, r2 }),
    beats,
  });
}

export const lesson: LessonDefinition<OrderProblem> = {
  id: "g5-order",
  grade: 5,
  unit: "Whole numbers",
  title: "Order of operations",
  pre: "g5-mult2",
  reference: createOrder(0, 3, 4, 6, 2), // 3 + 4 × (6 − 2), the current app's example
  generate: (rng, i) => {
    const t = i % 3;
    if (t === 2) {
      const d = rng.int(2, 6), a = rng.int(3, 9), b = rng.int(3, 9);
      return createOrder(t, a, b, d * rng.int(1, Math.min(9, Math.floor((a * b) / d))), d);
    }
    const c = rng.int(5, 12);
    return createOrder(t, rng.int(2, 9), rng.int(2, 9), c, rng.int(1, c - 1));
  },
  restore: raw => restoreVia(raw, ["t", "a", "b", "c", "d"] as const, v => createOrder(v.t, v.a, v.b, v.c, v.d)),
  display: expression,
  answers,
  explain,
};
