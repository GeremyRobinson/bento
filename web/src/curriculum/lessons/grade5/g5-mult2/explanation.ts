import { num, op, type MathText } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import type { AnimationState, Explanation, ExplanationStep } from "../../../../explanations/schema";
import { buildSplitAreaDiagram } from "../../../../explanations/diagrams/area-model/build";
import type { AreaDiagram, AreaLayout } from "../../../../explanations/diagrams/area-model/schema";
import type { SplitMultiplicationProblem } from "./problem";
import { withCommas } from "../../_number-line/steps";
import { placeName } from "../../../generators/place-value";

const plusChain = (values: number[]): MathText => values.flatMap((v, i) => (i ? [op("+"), num(v)] : [num(v)]));

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
  const many = p.cells.length > 1;

  const timeline: AnimationState[] = [
    { phase: "factors" },
    { phase: "split" },
    ...p.cells.map((_, index) => ({ phase: "region" as const, index })),
    ...(many ? [{ phase: "sum" as const }] : []),
  ];
  const stateOf = (match: (s: AnimationState) => boolean) => timeline.findIndex(match);
  const count = ["", "one", "two", "three", "four"][p.cells.length] ?? String(p.cells.length);

  // one worked line per part, with a short why under it (v2 model: "30 × 20 = 600 / the tens by the tens")
  const steps: ExplanationStep[] = p.cells.map(({ first, second }, i): ExplanationStep => {
    const result = expectedFor(answers, `partial-${i}`);
    return {
      id: `partial-${i}`,
      narration: `the ${placeName(first)} by the ${placeName(second)}`,
      math: [num(first), op("×"), num(second), op("="), num(result)],
      state: stateOf(s => s.phase === "region" && s.index === i),
      answerStep: `partial-${i}`,
      result,
    };
  });
  if (many) {
    const result = expectedFor(answers, "sum");
    steps.push({
      id: "sum",
      narration: `add the ${count} parts`,
      math: [...plusChain(p.partialProducts), op("="), num(result)],
      state: stateOf(s => s.phase === "sum"),
      answerStep: "sum",
      result,
    });
  }

  return {
    heading: "Split both numbers",
    idea: ["Both numbers split into tens and ones, so each part is an easy multiplication. Then add the parts."],
    statement: [num(a), op("×"), num(b)],
    diagram: buildSplitAreaDiagram(p, layout),
    timeline,
    steps,
    solved: `The ${count} parts make ${withCommas(p.product)}.`,
  };
}
