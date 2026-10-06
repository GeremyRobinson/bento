import { num, op, sub, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import { attempt, big, expected, f, ints, ns, supText } from "../../_plane/kit";
import { withEasyStart } from "../../easy-start";

/** log_b(b^m) + log_b(b^k) */
export interface LogProblem { kind: "logarithm.sum"; b: number; m: number; k: number }

const BASES = [2, 3, 5, 10];
const topFor = (b: number) => (b === 2 ? 6 : b === 3 ? 4 : 3);

export function createLog(b: number, m: number, k: number): LogProblem {
  if (!BASES.includes(b) || m < 1 || k < 1 || m > topFor(b) || k > topFor(b)) throw new Error("a base of 2, 3, 5 or 10 and small powers");
  return { kind: "logarithm.sum", b, m, k };
}

/** Same as the current app: base 2, 3, 5 or 10; powers up to 6, 4, 3, 3. */
export function generateLog(rng: Rng): LogProblem {
  const b = rng.pick(BASES), top = topFor(b);
  // two different logs, so the problem never reads "log₅ 25 + log₅ 25"
  const m = rng.int(1, top);
  let k: number;
  do k = rng.int(1, top); while (k === m);
  return createLog(b, m, k);
}

export function restoreLog(raw: unknown): LogProblem | null {
  const v = ints(raw, ["b", "m", "k"] as const);
  return v && attempt(() => createLog(v.b, v.m, v.k));
}

const SUBS = "₀₁₂₃₄₅₆₇₈₉";
const subText = (n: number) => String(n).split("").map(c => SUBS[Number(c)]).join("");
const log = (b: number, x: number): MathText => [text("log"), sub(b), text(` ${big(x)}`)];
export const logMath = ({ b, m, k }: LogProblem): MathText => [...log(b, b ** m), op("+"), ...log(b, b ** k)];

export function logAnswers({ b, m, k }: LogProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "m", label: "First log", question: `${b} to what power makes ${big(b ** m)}?`, prompt: s => [...log(b, b ** m), op("="), ...s], ans: m,
        hint: `A log is an exponent: count how many times the base multiplies to make ${big(b ** m)}.`, wrong: [[b ** m / b, "Divided instead", "A log asks for the exponent, not a quotient."]] }),
      ns({ id: "k", label: "Second log", prompt: s => [...log(b, b ** k), op("="), ...s], ans: k, hint: `The base to what power makes ${big(b ** k)}?`, wrong: [[b ** k / b, "Divided instead", "A log asks for the exponent, not a quotient."]] }),
      ns({ id: "sum", label: "Add them", prompt: s => [num(m), op("+"), num(k), op("="), ...s], ans: m + k, hint: "Multiplying powers of the same base adds their exponents, so add the two logs.",
        note: `Check: log${subText(b)} (${big(b ** m)} × ${big(b ** k)}) is the same.` }),
    ],
    finalParts: [-1],
  };
}

export function explainLog(p: LogProblem, model: AnswerModel): Explanation {
  const { b } = p, m = expected(model, "m"), k = expected(model, "k"), s = expected(model, "sum");
  const hi = Math.max(m, k), lo = Math.min(m, k);
  return {
    heading: "A log is an exponent",
    idea: ["A log asks: the base to what power makes this number? On the graph of the base to the power x, it is the x where the curve reaches that number.", "Adding logs with the same base adds the exponents: it is the log of the product."],
    statement: logMath(p),
    caption: `${f(b)}${supText(m)} = ${big(b ** m)} and ${f(b)}${supText(k)} = ${big(b ** k)}, so the sum is ${f(m)} + ${f(k)} = ${f(s)}.`,
    diagram: buildPlane({
      alt: `Graph of y = ${b} to the x, reaching ${big(b ** m)} at x = ${m} and ${big(b ** k)} at x = ${k}.`,
      fit: [[-0.5, 0], [hi + 0.5, b ** hi]],
      items: [
        { kind: "curve", f: x => b ** x, x0: -0.5, x1: hi + 0.4, label: { text: `y = ${b}ˣ`, optional: true }, labelX: hi + 0.3 },
        { kind: "segment", a: [m, 0], b: [m, b ** m], cls: "ln2 dash", from: 1, label: { text: `x = ${f(m)}`, acc: true, optional: true, prefer: ["e", "w"] } },
        { kind: "point", at: [m, b ** m], cls: "dota", from: 1, label: { text: big(b ** m), acc: true, prefer: ["w", "nw", "n"] } },
        ...(k !== m ? [
          { kind: "segment" as const, a: [k, 0] as const, b: [k, b ** k] as const, cls: "ln2 dash", from: 2, label: { text: `x = ${f(k)}`, acc: true, optional: true, prefer: ["e" as const, "w" as const] } },
          { kind: "point" as const, at: [k, b ** k] as const, cls: "dota" as const, from: 2, label: { text: big(b ** k), acc: true, prefer: ["w" as const, "nw" as const, "n" as const] } },
        ] : []),
      ],
    }),
    timeline: beats(4),
    steps: [
      { id: "ask", narration: `Each log asks for an exponent of ${f(b)}.`, math: logMath(p), state: 0 },
      { id: "m", narration: `${f(b)} to what power makes ${big(b ** m)}? ${f(b)}${supText(m)} = ${big(b ** m)}, so it is ${f(m)}.`,
        math: [...log(b, b ** m), op("="), num(m)], state: 1, answerStep: "m", result: m },
      { id: "k", narration: `${f(b)}${supText(k)} = ${big(b ** k)}, so the second log is ${f(k)}.`,
        math: [...log(b, b ** k), op("="), num(k)], state: 2, answerStep: "k", result: k },
      { id: "sum", narration: `Add the exponents: ${f(m)} + ${f(k)} = ${f(s)}. That is log${subText(b)} of ${big(b ** m)} × ${big(b ** k)}, since ${f(b)}${supText(lo)} × ${f(b)}${supText(hi)} = ${f(b)}${supText(s)}.`,
        math: [num(m), op("+"), num(k), op("="), num(s)], state: 3, answerStep: "sum", result: s },
    ],
  };
}

export const lesson: LessonDefinition<LogProblem> = withEasyStart({
  id: "g11-log",
  grade: 11,
  unit: "Exponents and logs",
  title: "Evaluating logarithms",
  reference: createLog(2, 3, 2),
  generate: rng => generateLog(rng),
  restore: restoreLog,
  display: logMath,
  answers: logAnswers,
  explain: explainLog,
});
