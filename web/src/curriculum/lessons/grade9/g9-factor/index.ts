import { answer, num, op, slot, sup, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildAreaGrid } from "../../../../explanations/diagrams/area-model/grid";
import { expectedOf, polyText, twoNums } from "../../area-common/steps";
import { coef } from "../../../text";
import { withEasyStart } from "../../easy-start";

/** x² + (p + q)x + pq = (x + p)(x + q), with 1 ≤ p ≤ q. */
export interface FactorProblem { p: number; qn: number }

export function createFactor(p: number, qn: number): FactorProblem {
  if (![p, qn].every(v => Number.isInteger(v) && v > 0)) throw new Error("p and q are positive whole numbers");
  return { p, qn };
}

/** Same as the current app: p 1–9, q p–9. */
export function generateFactor(rng: Rng): FactorProblem {
  const p = rng.int(1, 9);
  return { p, qn: rng.int(p, 9) };
}

const x = text("x");
const trinomial = ({ p, qn }: FactorProblem): MathText => [x, sup(2), op("+"), num(p + qn), x, op("+"), num(p * qn)];

export function factorAnswers({ p, qn }: FactorProblem): AnswerModel {
  return {
    steps: [
      { id: "pair", label: "Find the two numbers", question: `They multiply to ${p * qn} and add to ${p + qn}:`, prompt: [slot("m"), text(" and "), slot("n")],
        note: "Order doesn't matter.", slots: [{ id: "m", expected: p }, { id: "n", expected: qn }], known: [],
        check: twoNums(p, qn, "Right product, wrong sum", "Right sum, wrong product"),
        hint: `Which pair of factors of ${p * qn} adds up to ${p + qn}?`, explain: `${p} × ${qn} = ${p * qn} and ${p} + ${qn} = ${p + qn}.`,
        work: [num(p), text(" and "), num(qn)] },
      { id: "factors", label: "Write the factors", prompt: [text("("), x, op("+"), slot("m"), text(")("), x, op("+"), slot("n"), text(")")],
        note: "Use the two numbers you found.", slots: [{ id: "m", expected: p }, { id: "n", expected: qn }], known: [],
        check: twoNums(p, qn, "Writing the factors", "Writing the factors"),
        hint: "Each number you found goes with one x: (x + one)(x + the other).", explain: `(x + ${p})(x + ${qn}).`,
        work: [text("("), x, op("+"), answer("m", p), text(")("), x, op("+"), answer("n", qn), text(")")] },
    ],
    finalParts: [-1],
  };
}

export function explainFactor(prob: FactorProblem, answers: AnswerModel): Explanation {
  const p = expectedOf(answers.steps, "pair", "m"), q = expectedOf(answers.steps, "pair", "n");
  const X = Math.max(p, q) + 3;
  return {
    heading: "Multiply to c, add to b",
    idea: ["Find two numbers that multiply to the last number and add to the middle one. They are the numbers in the two factors."],
    statement: trinomial(prob),
    diagram: buildAreaGrid({
      cols: [{ label: "x", size: X }, { label: String(q), size: q, from: 1, cls: "acc" }],
      rows: [{ label: "x", size: X }, { label: String(p), size: p, from: 1, cls: "acc" }],
      cells: [
        [{ text: "x", sup: "2" }, { text: polyText([[q, "x"]]), textFrom: 1, focus: [1] }],
        [{ text: polyText([[p, "x"]]), textFrom: 1, focus: [1] }, { text: String(p * q) }],
      ],
      lines: [
        { text: `x² + ${p + q}x + ${p * q}`, from: 0, until: 0, cls: "lbl" },
        { text: `${p} × ${q} = ${p * q} and ${p} + ${q} = ${p + q}`, from: 1, until: 1 },
        { text: `(x + ${p})(x + ${q})`, from: 2 },
      ],
      alt: `x² + ${p + q}x + ${p * q} as a square x by x, strips ${coef(q, "x")} and ${coef(p, "x")}, and ${p * q} in the corner: an (x + ${p}) by (x + ${q}) rectangle.`,
    }),
    caption: `${p} × ${q} = ${p * q} and ${p} + ${q} = ${p + q}.`,
    timeline: beats(3),
    steps: [
      { id: "pair", narration: `${p} and ${q} multiply to ${p * q} and add to ${p + q}.`, math: [num(p), op("×"), num(q), op("="), num(p * q)], state: 1, answerStep: "pair", result: p },
      { id: "factors", narration: `The sides are x + ${p} and x + ${q}.`, math: [x, sup(2), op("+"), num(p + q), x, op("+"), num(p * q), op("="), text("("), x, op("+"), num(p), text(")("), x, op("+"), num(q), text(")")], state: 2, answerStep: "factors", result: p },
    ],
  };
}

export const lesson: LessonDefinition<FactorProblem> = withEasyStart({
  id: "g9-factor",
  grade: 9,
  unit: "Polynomials and quadratics",
  title: "Factoring quadratics",
  reference: createFactor(3, 4),
  generate: rng => generateFactor(rng),
  restore: raw => {
    if (!raw || typeof raw !== "object") return null;
    const r = raw as Record<string, unknown>, p = r.p, qn = r.qn ?? r.q;
    if (typeof p !== "number" || typeof qn !== "number") return null;
    try { return createFactor(p, qn); } catch { return null; }
  },
  display: trinomial,
  displayNote: () => "Factor it.",
  answers: factorAnswers,
  explain: explainFactor,
});
