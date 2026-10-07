import { num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildAreaGrid } from "../../../../explanations/diagrams/area-model/grid";
import { r1 } from "../../../../explanations/diagrams/scene/helpers";
import { expectedOf, ms, ns, readNumbers } from "../../area-common/steps";
import { coef } from "../../../text";

/** a(x + b) + cx: distribute, then combine the x terms. */
export interface DistributeProblem { a: number; b: number; c: number }

export function createDistribute(a: number, b: number, c: number): DistributeProblem {
  if (![a, b, c].every(v => Number.isInteger(v) && v > 0)) throw new Error("whole numbers only");
  return { a, b, c };
}

/** Same as the current app: a 2–9, b 1–9, c 1–9. */
export const generateDistribute = (rng: Rng): DistributeProblem => ({ a: rng.int(2, 9), b: rng.int(1, 9), c: rng.int(1, 9) });

const x = text("x");
/** c and x as written: just x when c is 1 */
const cx = (c: number): MathText => (c === 1 ? [x] : [num(c), x]);
const show = ({ a, b, c }: DistributeProblem): MathText => [num(a), text("("), x, op("+"), num(b), text(")"), op("+"), ...cx(c)];

export function distributeAnswers({ a, b, c }: DistributeProblem): AnswerModel {
  return {
    steps: [
      { ...ms({ id: "distribute", label: "Distribute", prompt: s => [num(a), text("("), x, op("+"), num(b), text(")"), op("="), s.p!, x, op("+"), s.q!], ans: { p: a, q: a * b },
        hint: "Multiply the number outside by each term inside.", wrong: [[{ p: a, q: b }, "Only multiplied the first term", `Multiply ${a} by **both** x and ${b}.`]] }),
        explain: `${a} × x = ${a}x and ${a} × ${b} = ${a * b}.` },
      ns({ id: "combine", label: "Combine the x terms", prompt: s => [num(a), x, op("+"), ...cx(c), op("="), s, x], ans: a + c, hint: "Add the numbers in front of x.",
        wrong: [[a * c, "Multiplied the x terms", "Like terms add: count all the x's."]] }),
      { ...ms({ id: "simple", label: "Write it simply", prompt: s => [s.p!, x, op("+"), s.q!], ans: { p: a + c, q: a * b }, hint: "Put together what you found: the x terms, then the plain number.",
        wrong: [[{ p: a + c, q: b }, "Lost the multiplied number", `The plain number is ${a} × ${b}, from the first step.`], [{ p: a, q: a * b }, "Left out the other x terms", "Use the x terms you combined."]] }),
        explain: `The x terms make ${a + c}x and the plain number is ${a * b}.` },
    ],
    finalParts: [-1],
  };
}

export function explainDistribute(p: DistributeProblem, answers: AnswerModel): Explanation {
  const { a, b, c } = p;
  const ab = expectedOf(answers.steps, "distribute", "q"), sum = expectedOf(answers.steps, "combine");
  // x is unknown, so its strip is drawn a little longer than any number beside it
  const X = Math.max(b, a, c) + 3;
  return {
    heading: "Multiply everything inside",
    idea: ["The number outside multiplies every term inside the parentheses."],
    statement: show(p),
    diagram: buildAreaGrid({
      cols: [{ label: "x", size: X }, { label: String(b), size: b }],
      rows: [{ label: String(a), size: a }, { label: String(c), size: c, from: 2 }],
      cells: [
        [{ text: `${a}x`, from: 1, focus: [1] }, { text: String(ab), from: 1, focus: [1] }],
        [{ text: coef(c, "x"), from: 2, color: 0, focus: [2] }, null],
      ],
      outlineFrom: null,
      // the a by (x + b) rectangle the problem starts with
      extras: g => [{ type: "rect", x: r1(g.left), y: r1(g.top), w: r1(g.width), h: r1(g.ys[1]! - g.top), cls: "ax thin", enter: "fade" }],
      lines: [
        { text: `${a}(x + ${b}) = ${a}x + ${ab}`, from: 1, until: 1 },
        { text: `${a}x + ${coef(c, "x")} = ${sum}x`, from: 2, until: 2 },
        { text: `${a}(x + ${b}) + ${coef(c, "x")} = ${sum}x + ${ab}`, from: 3 },
      ],
      alt: `A rectangle ${a} tall cut into ${a}x and ${ab}; a strip ${coef(c, "x")} joins the x part, making ${sum}x.`,
    }),
    caption: `${a}(x + ${b}) is ${a}x and ${ab}. The ${coef(c, "x")} strip lines up with the x part: ${sum}x in all.`,
    timeline: beats(4),
    steps: [
      { id: "distribute", narration: `${a} times x is ${a}x and ${a} times ${b} is ${ab}.`, math: [num(a), text("("), x, op("+"), num(b), text(")"), op("="), num(a), x, op("+"), num(ab)], state: 1, answerStep: "distribute", result: ab },
      { id: "combine", narration: `${a}x and ${coef(c, "x")} are both x strips: ${sum}x.`, math: [num(a), x, op("+"), ...cx(c), op("="), num(sum), x], state: 2, answerStep: "combine", result: sum },
      { id: "simple", narration: `So it's ${sum}x + ${ab}.`, math: [num(sum), x, op("+"), num(ab)], state: 3, answerStep: "simple", result: sum },
    ],
  };
}

export const lesson: LessonDefinition<DistributeProblem> = {
  id: "g7-distribute",
  grade: 7,
  unit: "Expressions and equations",
  title: "Distribute and combine",
  pre: "g6-gcf",
  reference: createDistribute(3, 4, 2),
  generate: rng => generateDistribute(rng),
  restore: raw => { const r = readNumbers(raw, ["a", "b", "c"] as const); try { return r && createDistribute(r.a, r.b, r.c); } catch { return null; } },
  display: show,
  displayNote: () => "Simplify.",
  answers: distributeAnswers,
  explain: explainDistribute,
};
