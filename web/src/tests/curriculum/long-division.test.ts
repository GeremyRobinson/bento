// g5-divide on the area model (v2 spec §4 g5-divide): g5-mult2's picture run backwards, the strips found one at a time.
import { createRng } from "../../curriculum/generators/rng";
import { lesson, createLongDivision, type LongDivisionProblem } from "../../curriculum/lessons/grade5/g5-divide";
import { areaView } from "../../components/diagrams/AreaModelDiagram";
import { pictureAt } from "../../screens/Practice";

const rng = createRng(20261013);
const ALL: LongDivisionProblem[] = [createLongDivision(12, 72), createLongDivision(9, 96), createLongDivision(25, 99), createLongDivision(3, 12),
  ...Array.from({ length: 500 }, () => lesson.generate(rng, 0))];

describe("g5-divide's picture", () => {
  it("is the area model: the divisor down the side, the answer's tens and ones across the top, products inside", () => {
    for (const p of ALL) {
      const ex = lesson.explain(p, lesson.answers(p)), d = ex.diagram!;
      if (d.kind !== "areaModel") throw new Error("not an area model");
      const T = p.qt - (p.qt % 10), O = p.qt % 10;
      expect(d.find).toBe(true);
      expect(d.rows.map(r => r.label)).toEqual([String(p.dv)]);
      expect(d.cols.map(c => c.label)).toEqual([String(T), String(O)]);
      expect(d.regions.map(r => r.product)).toEqual([p.dv * T, p.dv * O]);
      expect(d.total.value).toBe(p.n);
    }
  });
  it("finds the strips one at a time: nothing shown before its step, what's left shows in the ones strip", () => {
    const p = createLongDivision(12, 72), ex = lesson.explain(p, lesson.answers(p)), ids = ex.steps.map(s => s.answerStep!);
    const at = (k: number) => { const { at, ask } = pictureAt(ex, ids, k, false); return { v: areaView(ex.timeline, at), ask: ask != null ? ex.timeline[ask] : undefined }; };
    // tens: nothing found, the tens strip asked
    expect([...at(0).v.shown]).toEqual([]); expect(at(0).ask).toEqual({ phase: "region", index: 0 });
    // subtract: the tens strip found, the ones strip asked without its result
    expect([...at(1).v.shown]).toEqual([0]); expect([...at(1).v.left]).toEqual([]); expect(at(1).ask).toEqual({ phase: "left", index: 1 });
    // ones: what's left shows in the ones strip, which is asked
    expect([...at(2).v.left]).toEqual([1]); expect(at(2).ask).toEqual({ phase: "region", index: 1 });
    // the answer: both found
    expect([...at(3).v.shown].sort()).toEqual([0, 1]);
  });
  it("asks every step as a question over one answer pill", () => {
    for (const s of lesson.answers(createLongDivision(16, 73)).steps) {
      const last = s.prompt.at(-1), eq = s.prompt.at(-2);
      expect(last?.t).toBe("slot"); expect(eq).toMatchObject({ t: "op", v: "=" });
    }
    expect(lesson.answers(createLongDivision(16, 73)).steps[0]!.question).toBe("Take out as many tens of 16 as fit in 1168. How many is that?");
  });
});
