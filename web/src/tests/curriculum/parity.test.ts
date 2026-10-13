// Parity with the current app for g5-mult2. v2 (G 2026-10-13, the approved model) asks both numbers' tens and ones as four
// parts, so the in-between steps are new (logged in tests/parity/deviations/fixes02.ts); the problem and its answer are not.
import fixture from "../fixtures/legacy-g5-mult2.json";
import { splitMultiplication as lesson } from "../../curriculum/lessons/grade5/g5-mult2";
import { createSplitMultiplication } from "../../curriculum/lessons/grade5/g5-mult2/problem";
import { toPlainText } from "../../curriculum/schemas/math-text";
import { runtimeSteps } from "../../engine/evaluation/steps";

describe.each(fixture.cases)("g5-mult2 matches the current app for $a × $b", c => {
  const p = createSplitMultiplication(c.a, c.b);
  const steps = runtimeSteps(lesson.answers(p));

  it("shows the same problem", () => expect(toPlainText(lesson.display(p))).toBe(c.show));

  it("arrives at the same answer, with the same last step", () => {
    const last = steps[steps.length - 1]!, old = c.steps[c.steps.length - 1]!;
    expect(last.base).toBe(old.label);
    expect(last.slots[0]!.expected).toBe(old.answer);
  });
});
