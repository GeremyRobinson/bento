// G's seven required invariants, on the reference problem 47 × 36 and on thousands of seeded problems.
import { createRng } from "../../curriculum/generators/rng";
import { splitMultiplication as lesson } from "../../curriculum/lessons/grade5/g5-mult2";
import {
  checkInvariants, createSplitMultiplication, generateSplitMultiplication, restoreSplitMultiplication, type SplitMultiplicationProblem,
} from "../../curriculum/lessons/grade5/g5-mult2/problem";
import { explainSplitMultiplication } from "../../curriculum/lessons/grade5/g5-mult2/explanation";
import { numbersIn, toPlainText } from "../../curriculum/schemas/math-text";
import { areaView } from "../../components/diagrams/AreaModelDiagram";

const sum = (xs: number[]) => xs.reduce((a, b) => a + b, 0);
const near = (a: number, b: number) => Math.abs(a - b) < 1e-9;

function seeded(n: number): SplitMultiplicationProblem[] {
  const rng = createRng(20261002);
  return Array.from({ length: n }, () => generateSplitMultiplication(rng));
}
// also every pair in range, including multiples of ten on the second factor and three-part splits
const edge = [[47, 36], [12, 12], [98, 99], [99, 7], [5, 105], [13, 340], [47, 30]].map(([a, b]) => createSplitMultiplication(a!, b!));
const ALL = [...edge, ...seeded(5000)];

const reference = createSplitMultiplication(47, 36);

describe("the reference case 47 × 36 = 47 × (30 + 6)", () => {
  it("has the right model", () => {
    expect(reference).toMatchObject({ firstFactor: 47, secondFactor: 36, strategy: "splitSecondFactor", parts: [30, 6], partialProducts: [1410, 282], product: 1692 });
    expect(checkInvariants(reference)).toEqual([]);
  });
  it("reads correctly everywhere", () => {
    const ex = explainSplitMultiplication(reference, lesson.answers(reference));
    expect(toPlainText(ex.statement)).toBe("47 × 36 = 47 × (30 + 6)");
    expect(ex.steps.map(s => s.narration)).toEqual([
      "Split 36 by place value: 30 + 6.",
      "The tens part is 47 by 30, so it holds 1410.",
      "The ones part is 47 by 6, so it holds 282.",
      "Add the parts to fill the whole rectangle: 1692.",
    ]);
    expect(ex.steps.map(s => toPlainText(s.math))).toEqual(["36 = 30 + 6", "47 × 30 = 1410", "47 × 6 = 282", "1410 + 282 = 1692"]);
    expect(ex.diagram.vertical).toMatchObject({ factor: "first", value: 47, label: "47" });
    expect(ex.diagram.horizontal).toMatchObject({ factor: "second", value: 36, label: "36" });
    expect(ex.diagram.regions.map(r => [r.partLabel, r.productLabel])).toEqual([["30", "1410"], ["6", "282"]]);
  });
});

describe.each([
  ["47 × 36", [reference]],
  [`${ALL.length} generated and edge problems`, ALL],
])("invariants: %s", (_name, problems) => {
  it("1. split parts always add to the multiplier", () => {
    for (const p of problems) expect(sum(p.parts)).toBe(p.secondFactor);
  });

  it("2. region widths always add to 100% of the total width", () => {
    for (const p of problems) {
      const d = explainSplitMultiplication(p, lesson.answers(p)).diagram;
      expect(near(sum(d.regions.map(r => r.width)), d.horizontal.length)).toBe(true);
      expect(near(sum(d.regions.map(r => r.widthFraction)), 1)).toBe(true);
      // and they tile it: no gaps, no overlaps
      d.regions.forEach((r, i) => {
        const start = i === 0 ? d.horizontal.start : d.regions[i - 1]!.x + d.regions[i - 1]!.width;
        expect(near(r.x, start)).toBe(true);
      });
    }
  });

  it("3. each region width is proportional to its split value, on one scale for both axes, but no part is a hairline", () => {
    for (const p of problems) {
      const d = explainSplitMultiplication(p, lesson.answers(p)).diagram;
      // a part too thin for its label is held at a readable width; the others share one scale
      const held = d.regions.filter(r => r.width > r.part * d.unit + 0.01), free = d.regions.filter(r => !held.includes(r));
      for (const r of held) expect(r.width).toBeGreaterThanOrEqual(26);
      for (const r of free) expect(near(r.width / r.part, free[0]!.width / free[0]!.part)).toBe(true);
      for (const r of d.regions) {
        expect(near(r.widthFraction, r.part / p.secondFactor)).toBe(true);
        expect(near(r.height, p.firstFactor * d.unit)).toBe(true);
      }
      if (!held.length) expect(near(d.horizontal.length / d.vertical.length, p.secondFactor / p.firstFactor)).toBe(true);
    }
  });

  it("4. partial products equal firstFactor × splitPart", () => {
    for (const p of problems) {
      p.parts.forEach((part, i) => expect(p.partialProducts[i]).toBe(p.firstFactor * part));
      const d = explainSplitMultiplication(p, lesson.answers(p)).diagram;
      d.regions.forEach(r => {
        expect(r.product).toBe(p.firstFactor * r.part);
        expect(r.equation).toEqual({ factors: [p.firstFactor, r.part], product: r.product });
      });
    }
  });

  it("5. partial products sum to the total product", () => {
    for (const p of problems) {
      expect(sum(p.partialProducts)).toBe(p.product);
      expect(p.product).toBe(p.firstFactor * p.secondFactor);
      const d = explainSplitMultiplication(p, lesson.answers(p)).diagram;
      expect(sum(d.total.terms)).toBe(d.total.value);
      expect(d.total.value).toBe(p.product);
    }
  });

  it("6. axis ownership cannot reverse when the strategy is splitSecondFactor", () => {
    for (const p of problems) {
      const d = explainSplitMultiplication(p, lesson.answers(p)).diagram;
      expect(p.strategy).toBe("splitSecondFactor");
      expect(d.vertical.factor).toBe("first");
      expect(d.vertical.value).toBe(p.firstFactor);
      expect(d.horizontal.factor).toBe("second");
      expect(d.horizontal.value).toBe(p.secondFactor);
      // the split runs along the horizontal axis only: every region is the full height
      for (const r of d.regions) { expect(r.y).toBe(d.vertical.start); expect(r.height).toBe(d.vertical.length); }
    }
  });

  it("7. labels, equations, narration, answers and animation states all come from the same model", () => {
    for (const p of problems) {
      const answers = lesson.answers(p), ex = explainSplitMultiplication(p, answers), d = ex.diagram;
      // answers: one step per part, then the sum, each expecting the model's own value
      const expected = answers.steps.map(s => s.slots[0]!.expected);
      expect(expected).toEqual(p.parts.length > 1 ? [...p.partialProducts, p.product] : [...p.partialProducts]);
      // prompts and finished work lines carry the model's numbers
      answers.steps.forEach((s, i) => {
        if (i < p.parts.length) {
          expect(numbersIn(s.prompt)).toEqual([p.firstFactor, p.parts[i]]);
          expect(numbersIn(s.work)).toEqual([p.firstFactor, p.parts[i], p.partialProducts[i]]);
        } else {
          expect(numbersIn(s.prompt)).toEqual(p.partialProducts);
          expect(numbersIn(s.work)).toEqual([...p.partialProducts, p.product]);
        }
      });
      // labels on the picture
      expect(d.vertical.label).toBe(String(p.firstFactor));
      expect(d.horizontal.label).toBe(String(p.secondFactor));
      d.regions.forEach((r, i) => { expect(r.partLabel).toBe(String(p.parts[i])); expect(r.productLabel).toBe(String(p.partialProducts[i])); });
      // narration and equations: each beat's result is the answer model's value, and the numbers it says are the model's
      for (const step of ex.steps) {
        if (step.answerStep) {
          const a = answers.steps.find(s => s.id === step.answerStep)!;
          expect(step.result).toBe(a.slots[0]!.expected);
          expect(numbersIn(step.math)).toEqual(numbersIn(a.work));
        }
        expect(step.narration).toContain(String(step.result));
        // narration never says a number the model doesn't have
        const known = new Set([p.firstFactor, p.secondFactor, ...p.parts, ...p.partialProducts, p.product]);
        for (const n of step.narration.match(/\d+/g) ?? []) expect(known.has(Number(n))).toBe(true);
      }
      // animation: the timeline visits the factors, the split, each region in order, then the sum
      expect(ex.timeline[0]).toEqual({ phase: "factors" });
      expect(ex.timeline[1]).toEqual({ phase: "split" });
      p.parts.forEach((_, i) => expect(ex.timeline[2 + i]).toEqual({ phase: "region", index: i }));
      // each beat's state points at the matching place in the timeline, and the picture shows that region then
      ex.steps.forEach(step => {
        const state = ex.timeline[step.state]!;
        if (step.id.startsWith("partial-")) {
          const i = Number(step.id.split("-")[1]);
          expect(state).toEqual({ phase: "region", index: i });
          const view = areaView(ex.timeline, step.state);
          expect(view.active).toBe(i);
          expect([...view.shown]).toEqual(Array.from({ length: i + 1 }, (_, k) => k));
        }
      });
      // the beats arrive in timeline order
      const states = ex.steps.map(s => s.state);
      expect([...states].sort((a, b) => a - b)).toEqual(states);
    }
  });
});

describe("the problem model", () => {
  it("never generates a multiple of ten for the split factor and stays in the current app's ranges", () => {
    for (const p of seeded(5000)) {
      expect(p.secondFactor % 10).not.toBe(0);
      expect(p.firstFactor).toBeGreaterThanOrEqual(12); expect(p.firstFactor).toBeLessThanOrEqual(98);
      expect(p.secondFactor).toBeGreaterThanOrEqual(12); expect(p.secondFactor).toBeLessThanOrEqual(98);
      expect(checkInvariants(p)).toEqual([]);
    }
  });
  it("rejects bad factors", () => {
    expect(() => createSplitMultiplication(0, 36)).toThrow();
    expect(() => createSplitMultiplication(4.5, 36)).toThrow();
  });
  it("restores stored models and the current app's {a, b}, rebuilding everything from the factors", () => {
    expect(restoreSplitMultiplication({ a: 47, b: 36 })).toEqual(reference);
    expect(restoreSplitMultiplication({ ...reference, product: 1 })).toEqual(reference);
    expect(restoreSplitMultiplication({ a: "x" })).toBeNull();
    expect(restoreSplitMultiplication(null)).toBeNull();
  });
  it("is reproducible from a seed", () => {
    expect(generateSplitMultiplication(createRng(7))).toEqual(generateSplitMultiplication(createRng(7)));
  });
});

describe("labels never collide", () => {
  it("puts a product below its region when it doesn't fit inside", () => {
    const d = explainSplitMultiplication(reference, lesson.answers(reference)).diagram;
    expect(d.regions.map(r => r.labelPlacement)).toEqual(["inside", "below"]);
  });
});
