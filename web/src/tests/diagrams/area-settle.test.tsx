// The area model settles its scale in one pass on a phone (Review, g5-divide pass 1: React #185, "Maximum update depth
// exceeded", when the scale chased the stretch on 75 ÷ 5 at 360×780 and 336 ÷ 4 at 390×844).
import { render, cleanup } from "@testing-library/react";
import { AreaModelDiagram, settleFit } from "../../components/diagrams/AreaModelDiagram";
import { lesson, createLongDivision } from "../../curriculum/lessons/grade5/g5-divide";

/** the picture boxes g5-divide gets on phones: practice and Watch one at 360×780, 390×844 and 375×667 */
const BOXES = [{ w: 296, h: 114 }, { w: 296, h: 137 }, { w: 326, h: 156 }, { w: 326, h: 201 }, { w: 323, h: 94 }];
const CASES = Array.from({ length: 23 }, (_, i) => i + 3).filter(dv => dv !== 10).flatMap(dv => [12, 15, 19, 21, 39, 48, 73, 84, 91, 99].map(qt => createLongDivision(dv, qt)));

describe("the area model on a phone", () => {
  it("settles to one layout for a box: the same box gives the same picture", () => {
    for (const p of [createLongDivision(5, 15), createLongDivision(4, 84), ...CASES]) {
      const d = lesson.explain(p, lesson.answers(p)).diagram!;
      if (d.kind !== "areaModel") throw new Error("not an area model");
      for (const box of BOXES) expect(settleFit(d, box)).toEqual(settleFit(d, box));
    }
  });
  it("renders every step of dv 3 to 25 at 360 and 390 without updating forever", () => {
    let box = BOXES[0]!;
    const rect = Element.prototype.getBoundingClientRect;
    Element.prototype.getBoundingClientRect = function () { return { x: 0, y: 0, left: 0, top: 0, right: box.w, bottom: box.h, width: box.w, height: box.h, toJSON() {} } as DOMRect; };
    try {
      for (const p of [createLongDivision(5, 15), createLongDivision(4, 84), ...CASES]) {
        const ex = lesson.explain(p, lesson.answers(p)), d = ex.diagram!;
        if (d.kind !== "areaModel") throw new Error("not an area model");
        for (box of [BOXES[0]!, BOXES[2]!]) for (let at = 0; at < ex.timeline.length; at++) {
          expect(() => render(<AreaModelDiagram diagram={d} timeline={ex.timeline} at={at} ask={at < ex.timeline.length - 1 ? at + 1 : undefined} />)).not.toThrow();
          cleanup();
        }
      }
    } finally { Element.prototype.getBoundingClientRect = rect; }
  }, 120_000);
});
