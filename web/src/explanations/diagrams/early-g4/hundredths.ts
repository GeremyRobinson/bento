// Comparing decimals (4th grade): each decimal's part after the point shaded on its own hundredths grid,
// tenths as whole columns and hundredths as single squares, so the bigger amount is the one with more shaded.
import type { SceneDiagram } from "../scene/schema";
import { frame, t, type Draft } from "../geo/kit";

export interface HundredthsGrid {
  /** the decimal as written, above the grid */
  label: string;
  /** hundredths shaded (0 to 100) */
  count: number;
  /** the line under the grid, e.g. "50 hundredths" */
  note: string;
  beat: number;
}

export interface HundredthsSpec {
  grids: [HundredthsGrid, HundredthsGrid];
  /** the sign between the grids */
  sign: { text: string; beat: number };
  /** the first decimal is part blue and the second part orange; the sign being found is amber */
  alt: string;
}

const C = 13, G = C * 10, SPACE = 74;

export function buildHundredths(s: HundredthsSpec): SceneDiagram {
  const items: Draft[] = [];
  s.grids.forEach((g, k) => {
    const x0 = k * (G + SPACE), on = k === 1 ? "seg on p1" : "seg on";
    items.push(t(x0 + G / 2, -24, g.label, k === 1 ? "lbl big p1" : "lbl big p0", { enter: "fade" }));
    items.push({ type: "rect", x: x0, y: 0, w: G, h: G, rx: 3, cls: "seg", enter: "fade" } as Draft);
    const full = Math.floor(g.count / 10), part = g.count % 10;
    for (let c = 0; c < full; c++) {
      items.push({ type: "rect", x: x0 + c * C, y: 0, w: C, h: G, cls: on, from: g.beat, enter: "growy", delay: Math.round(c * 0.08 * 100) / 100 } as Draft);
    }
    if (part) items.push({ type: "rect", x: x0 + full * C, y: 0, w: C, h: part * C, cls: on, from: g.beat, enter: "growy", delay: Math.round(full * 0.08 * 100) / 100 } as Draft);
    for (let j = 1; j < 10; j++) {
      items.push({ type: "line", x1: x0 + j * C, y1: 0, x2: x0 + j * C, y2: G, cls: "grid", enter: "fade" } as Draft);
      items.push({ type: "line", x1: x0, y1: j * C, x2: x0 + G, y2: j * C, cls: "grid", enter: "fade" } as Draft);
    }
    items.push({ type: "rect", x: x0, y: 0, w: G, h: G, rx: 3, cls: "ax thin", enter: "fade" } as Draft);
    items.push(t(x0 + G / 2, G + 24, g.note, "sm", { from: g.beat, enter: "rise", delay: 0.5 }));
  });
  items.push(t(G + SPACE / 2, G / 2, s.sign.text, "big acc", { from: s.sign.beat, enter: "pop" }));
  return frame("hundredths", items, s.alt, 14);
}
