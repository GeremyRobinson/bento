import { num, op, sub, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import { attempt, expected, f, ints, ns, nz, P, poly, polyText, pt } from "../../_plane/kit";
import { signed } from "../../../text";
import { withEasyStart } from "../../easy-start";

/** lim x→a of (x − a)(x + b) ÷ (x − a) = a + b */
export interface LimitProblem { kind: "limit.factor"; a: number; b: number }

export function createLimit(a: number, b: number): LimitProblem {
  if (a === 0 || b === 0 || a + b === 0) throw new Error("a and b not 0, and a + b not 0");
  return { kind: "limit.factor", a, b };
}

/** Same as the current app: a, b −6..6, not 0, a + b not 0. */
export function generateLimit(rng: Rng): LimitProblem {
  let a: number, b: number;
  do { a = nz(rng, -6, 6); b = nz(rng, -6, 6); } while (a + b === 0);
  return createLimit(a, b);
}

export function restoreLimit(raw: unknown): LimitProblem | null {
  const v = ints(raw, ["a", "b"] as const);
  return v && attempt(() => createLimit(v.a, v.b));
}

const factor = (a: number) => `(x ${a < 0 ? "+" : "−"} ${Math.abs(a)})`;
const top = ({ a, b }: LimitProblem): [number, string][] => [[1, "x²"], [b - a, "x"], [-a * b, ""]];
export const limitMath = (p: LimitProblem): MathText =>
  [text("lim"), sub([text("x→"), num(p.a)]), text(" ("), ...poly(top(p)), text(`) ÷ ${factor(p.a)}`)];

export function limitAnswers({ a, b }: LimitProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "b", label: "Factor the top", prompt: s => [text(`${factor(a)}(x + `), ...s, text(")")], ans: b,
        hint: `Plugging x = ${f(a)} into the top gives 0, so ${factor(a)} is a factor. Find the other one: what times ${f(-a)} makes the number on its own?`, note: "Plugging in gives 0 ÷ 0, so factor first.",
        wrong: [[-b, "Sign slip", `Multiply it back out: ${factor(a)} times (x + your number) has to give the top's number on its own, ${f(-a * b)}.`]] }),
      ns({ id: "lim", label: "Cancel and plug in", prompt: s => [num(a), op("+"), ...P(b), op("="), ...s], ans: a + b,
        hint: "Away from the hole, the fraction is just the other factor. Plug x into it to see where the line is heading.", wrong: [[0, "Stopped at 0 ÷ 0", "0 ÷ 0 means simplify, not that the limit is 0."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainLimit(p: LimitProblem, model: AnswerModel): Explanation {
  const { a } = p, b = expected(model, "b"), L = expected(model, "lim");
  return {
    heading: "0 ÷ 0 means factor",
    idea: ["Plugging in gives 0 ÷ 0, which says nothing yet. Factor the top, cancel the matching factor, and the rest is a plain line you can plug into.", "The graph is that line with one hole in it: the limit is the height the line heads to at the hole."],
    statement: limitMath(p),
    caption: `A hole at x = ${f(a)}, but the line y = x ${b < 0 ? "−" : "+"} ${f(Math.abs(b))} heads to ${f(L)}.`,
    diagram: buildPlane({
      alt: `Graph: the line y = ${polyText([[1, "x"], [b, ""]])} with a hole at ${pt(a, L)}; the limit is ${f(L)}.`,
      fit: [[a - 2, L - 2], [a + 2, L + 2], [0, 0]],
      items: [
        // the graph is there from the start: the line with a hole where the bottom is 0
        { kind: "line", m: 1, b, label: { text: `y = ${polyText([[1, "x"], [b, ""]])}`, optional: true, from: 1 } },
        { kind: "segment", a: [a, 0], b: [a, L], cls: "ln2 dash", from: 2, label: { text: `x = ${f(a)}`, acc: true, optional: true, prefer: ["e", "w"] } },
        { kind: "point", at: [a, L], cls: "hole", delay: 0.5, label: { text: pt(a, L), acc: true, from: 2, prefer: ["nw", "se", "w"] } },
      ],
    }),
    timeline: beats(3),
    steps: [
      { id: "zero", narration: `At x = ${f(a)} the top and the bottom are both 0. 0 ÷ 0 means: simplify first.`, math: limitMath(p), state: 0 },
      { id: "b", narration: `Factor the top: ${polyText(top(p))} = ${factor(a)}(x ${signed(b)}). Cancel ${factor(a)}, leaving x ${signed(b)}, a line with a hole at x = ${f(a)}.`,
        math: [text(`${factor(a)}(x ${signed(b)})`)], state: 1, answerStep: "b", result: b },
      { id: "lim", narration: `Plug in: ${f(a)} ${signed(b)} = ${f(L)}. The line heads to ${f(L)}, so the limit is ${f(L)}.`,
        math: [num(a), op("+"), ...P(b), op("="), num(L)], state: 2, answerStep: "lim", result: L },
    ],
  };
}

export const lesson: LessonDefinition<LimitProblem> = withEasyStart({
  id: "g12-limit",
  grade: 12,
  unit: "Limits",
  title: "Limits by factoring",
  reference: createLimit(2, 2),
  generate: rng => generateLimit(rng),
  restore: restoreLimit,
  display: limitMath,
  answers: limitAnswers,
  explain: explainLimit,
});
