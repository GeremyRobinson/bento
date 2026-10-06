import { formatNumber as f, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import type { AnimationState, Explanation, ExplanationStep } from "../../../../explanations/schema";
import { buildSplitAreaDiagram } from "../../../../explanations/diagrams/area-model/build";
import type { AreaDiagram, AreaLayout } from "../../../../explanations/diagrams/area-model/schema";
import type { SplitMultiplicationProblem } from "./problem";
import { placeName } from "../../../generators/place-value";

const plusChain = (values: number[]): MathText => values.flatMap((v, i) => (i ? [op("+"), num(v)] : [num(v)]));
const words = (values: number[]) => values.map(f).join(" + ");

/** Value the answer model expects for a step; the explanation must arrive at the same number. */
function expectedFor(answers: AnswerModel, stepId: string): number {
  const step = answers.steps.find(s => s.id === stepId);
  const v = step?.slots[0]?.expected;
  if (v == null) throw new Error(`answer model has no step ${stepId}`);
  return v;
}

/**
 * Narration, equations, highlights and animation states for one problem.
 * Built from the canonical problem and its answer model, never from typed numbers.
 */
export function explainSplitMultiplication(p: SplitMultiplicationProblem, answers: AnswerModel, layout?: AreaLayout): Explanation & { diagram: AreaDiagram } {
  const a = p.firstFactor, b = p.secondFactor;
  const many = p.parts.length > 1;

  const timeline: AnimationState[] = [
    { phase: "factors" },
    { phase: "split" },
    ...p.parts.map((_, index) => ({ phase: "region" as const, index })),
    ...(many ? [{ phase: "sum" as const }] : []),
  ];
  const stateOf = (match: (s: AnimationState) => boolean) => timeline.findIndex(match);

  const steps: ExplanationStep[] = [
    {
      id: "split",
      narration: many ? `Split ${f(b)} by place value: ${words(p.parts)}.` : `${f(b)} is one place value, so there is nothing to split.`,
      math: [num(b), op("="), ...plusChain(p.parts)],
      state: stateOf(s => s.phase === "split"),
      result: b,
    },
    ...p.parts.map((part, i): ExplanationStep => {
      const result = expectedFor(answers, `partial-${i}`);
      return {
        id: `partial-${i}`,
        narration: `The ${placeName(part)} part is ${f(a)} by ${f(part)}, so it holds ${f(result)}.`,
        math: [num(a), op("×"), num(part), op("="), num(result)],
        state: stateOf(s => s.phase === "region" && s.index === i),
        answerStep: `partial-${i}`,
        result,
      };
    }),
  ];
  if (many) {
    const result = expectedFor(answers, "sum");
    steps.push({
      id: "sum",
      narration: `Add the parts to fill the whole rectangle: ${f(result)}.`,
      math: [...plusChain(p.partialProducts), op("="), num(result)],
      state: stateOf(s => s.phase === "sum"),
      answerStep: "sum",
      result,
    });
  }

  return {
    heading: "Split the second number",
    idea: ["The second number is tens plus ones, so the rectangle splits into strips that are easy to multiply one at a time.", "The strips together make the whole product."],
    statement: [num(a), op("×"), num(b), op("="), num(a), op("×"), text("("), ...plusChain(p.parts), text(")")],
    diagram: buildSplitAreaDiagram(p, layout),
    timeline,
    steps,
  };
}
