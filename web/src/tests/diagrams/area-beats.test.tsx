// The area model's beats and labels (Review 2026-10-13 #8, #13, #18): every step of Watch one changes the picture, a
// result too wide for its strip moves outside it on a leader, and division never shows a lone "?".
import { render, cleanup } from "@testing-library/react";
import { AreaModelDiagram, settleFit, sumText } from "../../components/diagrams/AreaModelDiagram";
import { lesson as divide, createLongDivision } from "../../curriculum/lessons/grade5/g5-divide";
import { lesson as mult2 } from "../../curriculum/lessons/grade5/g5-mult2";
import { createSplitMultiplication } from "../../curriculum/lessons/grade5/g5-mult2/problem";
import type { AreaDiagram } from "../../explanations/diagrams/area-model/schema";
import type { Explanation } from "../../explanations/schema";

const area = (ex: Explanation) => { if (ex.diagram?.kind !== "areaModel") throw new Error("not an area model"); return ex.diagram as AreaDiagram; };
const divs = [createLongDivision(9, 96), createLongDivision(17, 96), createLongDivision(21, 95), createLongDivision(5, 15), createLongDivision(12, 72)];
const mults = [createSplitMultiplication(35, 65), createSplitMultiplication(38, 29), createSplitMultiplication(25, 24), createSplitMultiplication(98, 91), createSplitMultiplication(17, 96)];
const explainD = (p: ReturnType<typeof createLongDivision>) => divide.explain(p, divide.answers(p));
const explainM = (p: ReturnType<typeof createSplitMultiplication>) => mult2.explain(p, mult2.answers(p));
/** what a viewer sees: every part's state, every label and result shown */
const look = (el: Element) => [...el.querySelectorAll(".region,.sum,text")].map(n =>
  `${n.getAttribute("class")}|${["data-shown", "data-active", "data-left", "data-on"].map(a => n.getAttribute(a)).join(",")}|${n.tagName === "text" ? n.textContent : ""}`).join(";");

describe("the area model's Watch one", () => {
  it("changes the picture on every beat (the split, each strip, what's left, the bracket and sum)", () => {
    for (const ex of [...divs.map(explainD), ...mults.map(explainM)]) {
      const d = area(ex);
      let prev = "";
      for (let at = 0; at < ex.timeline.length; at++) {
        const { container } = render(<AreaModelDiagram diagram={d} timeline={ex.timeline} at={at} />);
        const now = look(container);
        expect(now, `beat ${at} of ${d.vertical.label} by ${d.horizontal.label}`).not.toBe(prev);
        prev = now; cleanup();
      }
    }
  });
  it("closes with the bracket's sum: the widths for division, the strips for multiplication", () => {
    expect(sumText(area(explainD(createLongDivision(9, 96))))).toBe("90 + 6 = 96");
    expect(sumText(area(explainM(createSplitMultiplication(38, 29))))).toBe("760 + 342 = 1102");
  });
  it("never shows a lone \"?\" over the strips before anything is found", () => {
    const ex = explainD(createLongDivision(5, 15)), d = area(ex);
    const { container } = render(<AreaModelDiagram diagram={d} timeline={ex.timeline} at={0} ask={1} />);
    expect([...container.querySelectorAll("text.out-top")].map(t => t.textContent)).not.toContain("?");
    cleanup();
  });
});

describe("thin strips on screen", () => {
  /** iPad and phone picture boxes (screen px) */
  const BOXES = [{ w: 660, h: 577 }, { w: 358, h: 190 }, { w: 343, h: 150 }, { w: 328, h: 120 }];
  it("hold every result at 14px or more on screen, inside its strip or outside it on a leader", () => {
    for (const d of [...divs.map(explainD), ...mults.map(explainM)].map(area)) for (const box of BOXES) {
      const fit = settleFit(d, box), px = Math.max(fit.width / box.w, fit.height / box.h);
      d.regions.forEach((r, i) => {
        const o = fit.results[i]!, shown = Math.max(o.size, 14 * px), w = fit.widths[r.col]!;
        expect(shown / px).toBeGreaterThanOrEqual(14 - 1e-6);
        if (o.side === "in") expect(r.productLabel.length * shown * 0.7).toBeLessThanOrEqual(w);
        else expect(o.leader).not.toBeNull();
      });
    }
  });
});
