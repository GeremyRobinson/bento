import { num, op } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import type { AnimationState, Explanation, ExplanationStep } from "../../../../explanations/schema";
import { buildSplitAreaDiagram } from "../../../../explanations/diagrams/area-model/build";
import type { AreaDiagram } from "../../../../explanations/diagrams/area-model/schema";
import { expectedOf } from "../../_number-line/steps";
import type { LongDivisionProblem } from "./index";

/**
 * Long division on g5-mult2's area model, run backwards (v2 spec §4 g5-divide): the divisor down the side, the answer's
 * tens and ones across the top as two strips whose widths are found one at a time. Every number comes from the answer
 * model, so the picture, the worked lines and the steps always agree.
 */
export function explainLongDivision(p: LongDivisionProblem, model: AnswerModel): Explanation & { diagram: AreaDiagram } {
  const { dv, n } = p;
  const T = expectedOf(model, "tens"), left = expectedOf(model, "subtract"), O = expectedOf(model, "ones"), qt = expectedOf(model, "sum");
  const diagram: AreaDiagram = {
    ...buildSplitAreaDiagram({
      kind: "multiply.splitAreaModel", strategy: "splitSecondFactor", firstFactor: dv, secondFactor: qt,
      parts: [T, O], partialProducts: [dv * T, dv * O], product: n,
    }),
    find: true,
  };
  // nothing found, the tens strip found, what's left shown in the ones strip, the ones strip found, both together
  const timeline: AnimationState[] = [{ phase: "factors" }, { phase: "region", index: 0 }, { phase: "left", index: 1 }, { phase: "region", index: 1 }, { phase: "sum" }];
  const steps: ExplanationStep[] = [
    { id: "tens", narration: `take out as many tens of ${dv} as fit`, math: [num(dv), op("×"), num(T), op("="), num(dv * T)], state: 1, answerStep: "tens", result: T },
    { id: "subtract", narration: "take those away to see what's left", math: [num(n), op("−"), num(dv * T), op("="), num(left)], state: 2, answerStep: "subtract", result: left },
    { id: "ones", narration: `count how many ${dv}s fit in what's left`, math: [num(left), op("÷"), num(dv), op("="), num(O)], state: 3, answerStep: "ones", result: O },
    { id: "sum", narration: "the tens and the ones together", math: [num(T), op("+"), num(O), op("="), num(qt)], state: 4, answerStep: "sum", result: qt },
  ];
  return {
    heading: "Divide in chunks",
    idea: ["Taking out ten groups at a time gets to the answer faster than going one by one."],
    statement: [num(n), op("÷"), num(dv)],
    diagram,
    timeline,
    steps,
    solved: `The tens and the ones make ${qt}.`,
  };
}
