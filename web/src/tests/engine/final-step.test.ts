import { describe, expect, it } from "vitest";
import { finalPartsOf, finalStep } from "../../engine/evaluation/steps";
import { lessonById } from "../../curriculum/registry";
import { createRng } from "../../curriculum/generators/rng";

describe("skipping to the final answer", () => {
  it.each(["g4-fraccompare", "g4-deccompare"])("keeps the tap buttons when the last step is a tap (%s)", id => {
    const l = lessonById(id)!;
    const p = l.generate(createRng(7), 3);
    const model = l.answers(p);
    const last = model.steps[model.steps.length - 1]!;
    expect(last.choices).toBeTruthy();
    const f = finalStep(finalPartsOf(model.steps, model.finalParts));
    expect(f.choices).toEqual(last.choices);
  });
});

describe("the final answer's boxes (Review g5-full-pass #14)", () => {
  // subtracting two proper fractions never ends on a mixed number, so only add and mix are asked to show one
  it.each(["add", "mix"])("lays a mixed number out as practice does, never as boxes with commas (%s)", id => {
    const l = lessonById(id)!;
    let mixed = 0;
    for (let seed = 1; seed <= 40; seed++) for (let k = 0; k < 6; k++) {
      const model = l.answers(l.generate(createRng(seed), k));
      const f = finalStep(finalPartsOf(model.steps, model.finalParts));
      expect(f.prompt.some(t => t.t === "text" && t.v.includes(","))).toBe(false);
      if (f.slots.map(s => s.id).join() === "w,n,d") {
        mixed++;
        expect(f.prompt[0]).toEqual({ t: "slot", id: "w", small: true });
        expect(f.prompt[1]).toMatchObject({ t: "frac" });
      }
    }
    expect(mixed).toBeGreaterThan(0);
  });
});
