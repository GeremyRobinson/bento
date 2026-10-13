// G's seven required invariants, on the reference problem 47 × 36 and on thousands of seeded problems. v2 (G 2026-10-13,
// the approved model): both numbers split into tens and ones, the first across the top, the second down the side.
import { PART_GAP } from "../../explanations/diagrams/area-model/build";
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
// also every pair in range, including multiples of ten and three-part splits
const edge = [[47, 36], [12, 12], [98, 99], [99, 7], [5, 105], [13, 340], [47, 30]].map(([a, b]) => createSplitMultiplication(a!, b!));
const ALL = [...edge, ...seeded(5000)];

const reference = createSplitMultiplication(47, 36);

describe("the reference case 47 × 36 = (40 + 7) × (30 + 6)", () => {
  it("has the right model", () => {
    expect(reference).toMatchObject({
      firstFactor: 47, secondFactor: 36, strategy: "splitBoth", firstParts: [40, 7], secondParts: [30, 6],
      cells: [{ first: 40, second: 30 }, { first: 7, second: 30 }, { first: 40, second: 6 }, { first: 7, second: 6 }],
      partialProducts: [1200, 210, 240, 42], product: 1692,
    });
    expect(checkInvariants(reference)).toEqual([]);
  });
  it("reads correctly everywhere", () => {
    const ex = explainSplitMultiplication(reference, lesson.answers(reference));
    expect(toPlainText(ex.statement)).toBe("47 × 36");
    expect(ex.steps.map(s => s.narration)).toEqual(["the tens by the tens", "the ones by the tens", "the tens by the ones", "the ones by the ones", "add the four parts"]);
    expect(ex.steps.map(s => toPlainText(s.math))).toEqual(["40 × 30 = 1200", "7 × 30 = 210", "40 × 6 = 240", "7 × 6 = 42", "1200 + 210 + 240 + 42 = 1692"]);
    expect(ex.solved).toBe("The four parts make 1,692.");
    expect(ex.diagram.horizontal).toMatchObject({ factor: "first", value: 47, label: "47" });
    expect(ex.diagram.vertical).toMatchObject({ factor: "second", value: 36, label: "36" });
    expect(ex.diagram.cols.map(c => c.label)).toEqual(["40", "7"]);
    expect(ex.diagram.rows.map(r => r.label)).toEqual(["30", "6"]);
    expect(ex.diagram.regions.map(r => [r.col, r.row, r.productLabel])).toEqual([[0, 0, "1200"], [1, 0, "210"], [0, 1, "240"], [1, 1, "42"]]);
  });
});

describe.each([
  ["47 × 36", [reference]],
  [`${ALL.length} generated and edge problems`, ALL],
])("invariants: %s", (_name, problems) => {
  it("1. split parts always add to their factor", () => {
    for (const p of problems) { expect(sum(p.firstParts)).toBe(p.firstFactor); expect(sum(p.secondParts)).toBe(p.secondFactor); }
  });

  it("2. the columns and rows tile the picture, one gap apart (v2 spec G1: each part its own shape)", () => {
    for (const p of problems) {
      const d = explainSplitMultiplication(p, lesson.answers(p)).diagram;
      for (const [bands, axis] of [[d.cols, d.horizontal], [d.rows, d.vertical]] as const) {
        expect(near(sum(bands.map(b => b.length)) + PART_GAP * (bands.length - 1), axis.length)).toBe(true);
        bands.forEach((b, i) => expect(near(b.start, i === 0 ? axis.start : bands[i - 1]!.start + bands[i - 1]!.length + PART_GAP)).toBe(true));
      }
      // every part sits exactly in its column and row
      for (const r of d.regions) {
        expect(r.x).toBe(d.cols[r.col]!.start); expect(r.width).toBe(d.cols[r.col]!.length);
        expect(r.y).toBe(d.rows[r.row]!.start); expect(r.height).toBe(d.rows[r.row]!.length);
      }
    }
  });

  it("3. columns and rows are in proportion on one scale for both axes, but no part is a hairline", () => {
    for (const p of problems) {
      const d = explainSplitMultiplication(p, lesson.answers(p)).diagram;
      const all = [...d.cols.map((b, i) => [b, p.firstParts[i]!] as const), ...d.rows.map((b, i) => [b, p.secondParts[i]!] as const)];
      const held = all.filter(([b, n]) => b.length > n * d.unit + 0.01), free = all.filter(x => !held.includes(x));
      for (const [b] of held) expect(b.length).toBeGreaterThanOrEqual(30);
      for (const [b, n] of free) expect(b.length / n).toBeLessThanOrEqual(d.unit + 1e-9);
      // within one side, the free parts share one scale
      for (const side of [d.cols.map((b, i) => [b, p.firstParts[i]!] as const), d.rows.map((b, i) => [b, p.secondParts[i]!] as const)]) {
        const f = side.filter(x => free.some(y => y[0] === x[0]));
        for (const [b, n] of f) expect(near(b.length / n, f[0]![0].length / f[0]![1])).toBe(true);
      }
    }
  });

  it("4. each partial product is its column's part × its row's part", () => {
    for (const p of problems) {
      p.cells.forEach((c, i) => expect(p.partialProducts[i]).toBe(c.first * c.second));
      const d = explainSplitMultiplication(p, lesson.answers(p)).diagram;
      d.regions.forEach(r => {
        const [a, b] = [p.firstParts[r.col]!, p.secondParts[r.row]!];
        expect(r.product).toBe(a * b);
        expect(r.equation).toEqual({ factors: [a, b], product: r.product });
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

  it("6. axis ownership cannot reverse: the first factor runs across the top, the second down the side", () => {
    for (const p of problems) {
      const d = explainSplitMultiplication(p, lesson.answers(p)).diagram;
      expect(p.strategy).toBe("splitBoth");
      expect(d.horizontal).toMatchObject({ factor: "first", value: p.firstFactor });
      expect(d.vertical).toMatchObject({ factor: "second", value: p.secondFactor });
      expect(d.cols.map(c => c.label)).toEqual(p.firstParts.map(String));
      expect(d.rows.map(r => r.label)).toEqual(p.secondParts.map(String));
      // the parts go row by row, as the steps ask them
      expect(d.regions.map(r => [r.row, r.col])).toEqual(p.secondParts.flatMap((_, j) => p.firstParts.map((_, i) => [j, i])));
    }
  });

  it("7. labels, equations, narration, answers and animation states all come from the same model", () => {
    for (const p of problems) {
      const answers = lesson.answers(p), ex = explainSplitMultiplication(p, answers), d = ex.diagram;
      const n = p.cells.length;
      // answers: one step per part, then the sum, each expecting the model's own value
      const expected = answers.steps.map(s => s.slots[0]!.expected);
      expect(expected).toEqual(n > 1 ? [...p.partialProducts, p.product] : [...p.partialProducts]);
      answers.steps.forEach((s, i) => {
        if (i < n) {
          expect(numbersIn(s.prompt)).toEqual([p.cells[i]!.first, p.cells[i]!.second]);
          expect(numbersIn(s.work)).toEqual([p.cells[i]!.first, p.cells[i]!.second, p.partialProducts[i]]);
        } else {
          expect(numbersIn(s.prompt)).toEqual(p.partialProducts);
          expect(numbersIn(s.work)).toEqual([...p.partialProducts, p.product]);
        }
      });
      d.regions.forEach((r, i) => expect(r.productLabel).toBe(String(p.partialProducts[i])));
      for (const step of ex.steps) {
        if (step.answerStep) {
          const a = answers.steps.find(s => s.id === step.answerStep)!;
          expect(step.result).toBe(a.slots[0]!.expected);
          expect(numbersIn(step.math)).toEqual(numbersIn(a.work));
        }
        expect(toPlainText(step.math)).toContain(String(step.result));
        // narration says no numbers at all: the math line carries them
        expect(step.narration).not.toMatch(/\d/);
      }
      // animation: the timeline visits the factors, the split, each part in order, then the sum
      expect(ex.timeline[0]).toEqual({ phase: "factors" });
      expect(ex.timeline[1]).toEqual({ phase: "split" });
      p.cells.forEach((_, i) => expect(ex.timeline[2 + i]).toEqual({ phase: "region", index: i }));
      ex.steps.forEach(step => {
        if (step.id.startsWith("partial-")) {
          const i = Number(step.id.split("-")[1]);
          expect(ex.timeline[step.state]).toEqual({ phase: "region", index: i });
          const view = areaView(ex.timeline, step.state);
          expect(view.active).toBe(i);
          expect([...view.shown]).toEqual(Array.from({ length: i + 1 }, (_, k) => k));
        }
      });
      const states = ex.steps.map(s => s.state);
      expect([...states].sort((a, b) => a - b)).toEqual(states);
    }
  });
});

describe("the problem model", () => {
  it("never generates a multiple of ten, so every problem has four parts, and stays in range", () => {
    for (const p of seeded(5000)) {
      expect(p.firstFactor % 10).not.toBe(0);
      expect(p.secondFactor % 10).not.toBe(0);
      expect(p.cells).toHaveLength(4);
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
