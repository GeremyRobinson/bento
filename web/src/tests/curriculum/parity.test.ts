// Parity with the current app: same step labels, prompts, answers, hints, explanations and mistake messages.
import fixture from "../fixtures/legacy-g5-mult2.json";
import { splitMultiplication as lesson } from "../../curriculum/lessons/grade5/g5-mult2";
import { createSplitMultiplication } from "../../curriculum/lessons/grade5/g5-mult2/problem";
import { toPlainText } from "../../curriculum/schemas/math-text";
import { checkStep, runtimeSteps } from "../../engine/evaluation/steps";

describe.each(fixture.cases)("g5-mult2 matches the current app for $a × $b", c => {
  const p = createSplitMultiplication(c.a, c.b);
  const steps = runtimeSteps(lesson.answers(p));

  it("shows the same problem", () => expect(toPlainText(lesson.display(p))).toBe(c.show));

  it("has the same steps", () => {
    expect(steps.map(s => s.base)).toEqual(c.steps.map(s => s.label));
    steps.forEach((s, i) => {
      const old = c.steps[i]!;
      expect(toPlainText(s.prompt, "")).toBe(old.prompt);
      expect(s.slots[0]!.expected).toBe(old.answer);
      expect(s.hint).toBe(old.hint);
      expect(s.explain).toBe(old.explain);
      expect(toPlainText(s.work)).toBe(old.work);
    });
  });

  it("gives the same mistake messages", () => {
    steps.forEach((s, i) => {
      const old = c.steps[i]!;
      const T = c.b - (c.b % 10);
      for (const [typed, want] of [[c.a * T / 10, old.placeSlip], [old.answer + 1, old.offByOne]] as const) {
        const r = checkStep(s, { x: typed });
        if (want === null) { expect(r.ok).toBe(true); continue; }
        expect(r.ok).toBe(false);
        if (!r.ok && !r.soft) expect({ kind: r.kind, msg: r.message, generic: r.generic }).toEqual(want);
      }
    });
  });
});
