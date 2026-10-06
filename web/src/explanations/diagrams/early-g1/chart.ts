// A few rows of the hundreds chart (1 to 100, ten to a row). Ten more is the square straight below,
// ten less the square straight above, so a jump of ten is one row.
import type { SceneDiagram } from "../scene/schema";
import { arrowHead } from "../scene/helpers";
import { frame, path, t, M, type Draft } from "../geo/kit";

const CELL = 40;

export interface HundredRowsSpec {
  /** the number you start on and the one you land on (1 to 100) */
  from: number;
  to: number;
  /** label beside the jump, e.g. "+10" */
  jump: string;
  /** lines under the chart, each shown on its own beat */
  notes: { text: string; beat: number; until?: number }[];
  beats: { start: number; jump: number; land: number };
  alt: string;
}

const rowOf = (v: number) => Math.floor((v - 1) / 10);
const colOf = (v: number) => (v - 1) % 10;

export function buildHundredRows(s: HundredRowsSpec): SceneDiagram {
  for (const v of [s.from, s.to]) if (!Number.isInteger(v) || v < 1 || v > 100) throw new Error(`${v} is not on the hundreds chart`);
  const lo = Math.min(rowOf(s.from), rowOf(s.to)), hi = Math.max(rowOf(s.from), rowOf(s.to));
  // one more row for context: above when there is room, otherwise below
  const first = lo > 0 ? lo - 1 : lo, last = lo > 0 ? hi : Math.min(9, hi + 1);
  const items: Draft[] = [];
  const at = (v: number): [number, number] => [colOf(v) * CELL, (rowOf(v) - first) * CELL];
  for (let r = first; r <= last; r++) for (let c = 0; c < 10; c++) {
    const v = r * 10 + c + 1, [x, y] = at(v);
    items.push({ type: "rect", x: x + 1, y: y + 1, w: CELL - 2, h: CELL - 2, rx: 6, cls: "seg", enter: "fade", delay: Math.round((r - first) * 10 + c) * 0.01 } as Draft);
  }
  const [fx, fy] = at(s.from), [tx, ty] = at(s.to);
  items.push({ type: "rect", x: fx + 1, y: fy + 1, w: CELL - 2, h: CELL - 2, rx: 6, cls: "sq", from: s.beats.start, enter: "pop", delay: 0.3 } as Draft);
  items.push({ type: "rect", x: tx + 1, y: ty + 1, w: CELL - 2, h: CELL - 2, rx: 6, cls: "sq big", from: s.beats.land, enter: "pop", delay: 0.2 } as Draft);
  for (let r = first; r <= last; r++) for (let c = 0; c < 10; c++) {
    const v = r * 10 + c + 1, [x, y] = at(v);
    items.push(t(x + CELL / 2, y + CELL / 2, String(v), "sm", { enter: "fade", delay: Math.round(((r - first) * 10 + c) * 0.01 * 100) / 100 }));
  }
  // the jump curves out just past the right side of the two squares, staying clear of the next column's numbers, and its
  // label sits in the margin right of the chart, level with the jump (v43: "+10" covered 90 and 100 on a phone)
  const x0 = fx + CELL - 4, y0 = fy + CELL / 2, y1 = ty + CELL / 2, bulge = colOf(s.from) === 9 ? 34 : 18;
  items.push(path([M([x0, y0]), { c: "Q", q: [x0 + bulge, (y0 + y1) / 2], p: [x0 + 2, y1] }], "ln2", { from: s.beats.jump, enter: "draw", delay: 0.2 }));
  const ang = Math.atan2(y1 - (y0 + y1) / 2, x0 + 2 - (x0 + bulge));
  items.push({ ...arrowHead(x0 + 2, y1, ang, 10, { from: s.beats.jump, enter: "fade", delay: 0.9 }), cls: "dota" } as Draft);
  items.push(t(10 * CELL + (colOf(s.from) === 9 ? 30 : 14), (y0 + y1) / 2, s.jump, "lbl acc start", { from: s.beats.jump, enter: "rise", delay: 0.5 }));
  const below = (last - first + 1) * CELL + 30;
  for (const n of s.notes) items.push(t(5 * CELL, below, n.text, "lbl", { from: n.beat, ...(n.until != null ? { until: n.until } : {}), enter: "rise", delay: 0.2 }));
  return frame("hundred-chart", items, s.alt, 14, { w: 520 });
}
