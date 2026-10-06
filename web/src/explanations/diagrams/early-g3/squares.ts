// A rectangle of unit squares for area by counting: the first row is counted square by square,
// then the rows are counted, then every square fills in. Roles (handoff-6): the first row and its label blue, the
// rows counted down the side orange, and the area being found amber. Sizes and labels come from the lesson.
import type { SceneDiagram } from "../scene/schema";
import { frame, t, type Draft } from "../geo/kit";

export interface SquaresSpec {
  cols: number;
  rows: number;
  /** beat the first row is counted 1, 2, 3, … */
  rowBeat?: number;
  /** beat the rows are counted down the side */
  colBeat?: number;
  /** beat every square fills in */
  fillBeat?: number;
  /** labels along the top and the left side, shown from the counting beats */
  topLabel?: string;
  sideLabel?: string;
  /** a line under the grid from the fill beat */
  note?: string;
  alt: string;
}

export function buildSquares(s: SquaresSpec): SceneDiagram {
  const c = Math.min(44, 400 / s.cols, 250 / s.rows), items: Draft[] = [];
  const sq = (i: number, j: number, cls: string, extra: Partial<Draft> = {}) =>
    items.push({ type: "rect", x: j * c + 2, y: i * c + 2, w: c - 4, h: c - 4, rx: 5, cls, ...extra } as Draft);
  for (let i = 0; i < s.rows; i++) for (let j = 0; j < s.cols; j++) sq(i, j, "seg", { enter: "fade", delay: Math.round((i * s.cols + j) * 0.008 * 100) / 100 });
  if (s.rowBeat != null) {
    for (let j = 0; j < s.cols; j++) {
      sq(0, j, "cell c0", { from: s.rowBeat, enter: "pop", delay: Math.round(j * 0.12 * 100) / 100 });
      items.push(t((j + 0.5) * c, 0.5 * c, String(j + 1), "sm", { from: s.rowBeat, ...(s.fillBeat != null ? { until: s.fillBeat - 1 } : {}), enter: "rise", delay: Math.round(j * 0.12 * 100) / 100 }));
    }
    if (s.topLabel) items.push(t((s.cols * c) / 2, -18, s.topLabel, "lbl", { from: s.rowBeat, enter: "rise", delay: 0.4 }));
  }
  if (s.colBeat != null) {
    for (let i = 0; i < s.rows; i++) {
      if (i > 0) for (let j = 0; j < s.cols; j++) sq(i, j, "cell c1", { from: s.colBeat, enter: "fade", delay: Math.round(i * 0.15 * 100) / 100 });
      items.push(t(-12, (i + 0.5) * c, String(i + 1), "sm end", { from: s.colBeat, enter: "rise", delay: Math.round(i * 0.15 * 100) / 100 }));
    }
    if (s.sideLabel) items.push(t(-40, (s.rows * c) / 2, s.sideLabel, "lbl end p1", { from: s.colBeat, enter: "rise", delay: 0.4 }));
  }
  items.push({ type: "rect", x: 0, y: 0, w: s.cols * c, h: s.rows * c, cls: "ax thin", enter: "fade" } as Draft);
  if (s.fillBeat != null) {
    for (let i = 0; i < s.rows; i++) for (let j = 0; j < s.cols; j++) sq(i, j, "sq big", { from: s.fillBeat, enter: "pop", delay: Math.round((i * s.cols + j) * 0.015 * 100) / 100 });
    if (s.note) items.push(t((s.cols * c) / 2, s.rows * c + 26, s.note, "lbl acc", { from: s.fillBeat, enter: "rise", delay: 0.6 }));
  }
  return frame("squares", items, s.alt, 14, { w: 540 });
}
