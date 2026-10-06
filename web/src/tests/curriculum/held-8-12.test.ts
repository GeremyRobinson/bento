// Grades 8 to 12, the fixes-02 items that waited on reviewed parity deviations: the cylinder and cone find the
// circle base first, g9-radical asks for the whole split, and every lesson's `pre` is one it really builds on.
import { CATALOG } from "../../curriculum/catalog";
import { lessonById } from "../../curriculum/registry";
import { checkAnswerStep } from "../../engine/evaluation/steps";
import { createCone } from "../../curriculum/lessons/grade8/g8-cone";
import { createCylinder } from "../../curriculum/lessons/grade8/g8-cyl";
import { createSimplifyRoot } from "../../curriculum/lessons/grade9/g9-radical";

const L = (id: string) => lessonById(id)!;
const kind = (r: ReturnType<typeof checkAnswerStep>) => (r.ok || r.soft ? null : r.kind);

describe("g8-cyl and g8-cone: base area first", () => {
  it("cylinder: r², then 3.14 × r², then base × height", () => {
    const steps = L("g8-cyl").answers(createCylinder(3, 4)).steps;
    expect(steps.map(s => s.slots[0]!.expected)).toEqual([9, 28.26, 113.04]);
    expect(steps.map(s => s.label)).toEqual(["Square the radius", "Base area", "Base × height"]);
  });
  it("cone: base area, then the cylinder, then a third", () => {
    const steps = L("g8-cone").answers(createCone(3, 4)).steps;
    expect(steps.map(s => s.slots[0]!.expected)).toEqual([28.26, 113.04, 37.68]);
    expect(kind(checkAnswerStep(steps[0]!, { x: 9 }))).toBe("Left out π");
    expect(kind(checkAnswerStep(steps[2]!, { x: 113.04 }))).toBe("Forgot the ÷ 3");
  });
});

describe("g9-radical: the learner writes the split", () => {
  const step = L("g9-radical").answers(createSimplifyRoot(4, 3)).steps[0]!; // √48
  it("asks for both factors, square first", () => {
    expect(step.slots.map(s => [s.id, s.expected])).toEqual([["sq", 16], ["rest", 3]]);
    expect(checkAnswerStep(step, { sq: 16, rest: 3 }).ok).toBe(true);
  });
  it("names a smaller square and a swapped order", () => {
    expect(kind(checkAnswerStep(step, { sq: 4, rest: 12 }))).toBe("Not the biggest square");
    expect(kind(checkAnswerStep(step, { sq: 3, rest: 16 }))).toBe("Square second");
  });
});

describe("grades 8 to 12: pre links", () => {
  const band = CATALOG.filter(c => c.grade >= 8);
  it("sets the fixes-02 table", () => expect(band.filter(c => c.pre).length).toBeGreaterThanOrEqual(39));
  it("points each pre at a lesson that comes earlier, and the lesson agrees with the catalog", () => {
    const at = (id: string) => CATALOG.findIndex(c => c.id === id);
    for (const c of band.filter(c => c.pre)) {
      expect(at(c.pre!), `${c.pre} before ${c.id}`).toBeGreaterThanOrEqual(0);
      expect(at(c.pre!), `${c.pre} before ${c.id}`).toBeLessThan(at(c.id));
      expect(L(c.id).pre, c.id).toBe(c.pre);
    }
  });
});
