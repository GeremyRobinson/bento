// Things to sort (k-sort): mixed-up objects of two or three kinds, all in one color (part blue), so color never marks a
// group: only the shape does (design/pictures-k4.md, handoff-6). In the lesson they slide into one row per kind and each row is counted.
import type { SceneDiagram } from "../scene/schema";
import { createRng } from "../../../curriculum/generators/rng";
import { frame, path, t, M, L, Z, type Draft } from "../geo/kit";
import { WIDE } from "./fit";

export type Glyph = "button" | "leaf" | "block" | "circle" | "square" | "triangle";

type Timing = { from?: number; until?: number; enter?: Draft["enter"]; delay?: number; vars?: Record<string, string> };

/** one object centered at (x, y), about 30 across */
export function glyph(g: Glyph, x: number, y: number, o: Timing): Draft[] {
  switch (g) {
    case "button": return [
      { type: "circle", cx: x, cy: y, r: 15, cls: "dotp", ...o } as Draft,
      ...[[-4, -4], [4, -4], [-4, 4], [4, 4]].map(([dx, dy]) => ({ type: "circle", cx: x + dx!, cy: y + dy!, r: 2.2, cls: "pin", ...o }) as Draft),
    ];
    case "leaf": return [
      path([M([x - 16, y + 10]), { c: "Q", q: [x - 12, y - 16], p: [x + 16, y - 12] }, { c: "Q", q: [x + 10, y + 14], p: [x - 16, y + 10] }, Z], "dotpath", o),
      path([M([x - 16, y + 10]), L([x + 8, y - 6])], "pinline", o),
    ];
    case "block": return [{ type: "rect", x: x - 14, y: y - 14, w: 28, h: 28, rx: 4, cls: "dotp", ...o } as Draft, { type: "rect", x: x - 7, y: y - 7, w: 14, h: 14, rx: 2, cls: "pinbox", ...o } as Draft];
    case "circle": return [{ type: "circle", cx: x, cy: y, r: 15, cls: "dotp", ...o } as Draft];
    case "square": return [{ type: "rect", x: x - 14, y: y - 14, w: 28, h: 28, cls: "dotp", ...o } as Draft];
    case "triangle": return [path([M([x, y - 16]), L([x + 16, y + 13]), L([x - 16, y + 13]), Z], "dotpath", o)];
  }
}

export interface SortSpec {
  glyphs: Glyph[];
  counts: number[];
  /** scatters the same way every time for the same problem */
  seed: number;
  /** beats: sorted into rows, rows counted, the answer row marked (with `mark`). Leave out for practice. */
  beats?: { rows: number; count: number; mark: number };
  mark?: number;
  alt: string;
}

const CELL = 62, COLS = 7;

export function buildSort(s: SortSpec): SceneDiagram {
  const total = s.counts.reduce((a, b) => a + b, 0), rows = Math.ceil(total / COLS) + (total > 10 ? 1 : 0);
  const rng = createRng(s.seed), cells = rng.shuffle(Array.from({ length: COLS * Math.max(rows, 3) }, (_, i) => i));
  const b = s.beats, items: Draft[] = [];
  let k = 0;
  /** when each object's place in its row pops in, so the same object leaves the pile at that moment */
  const rowDelay = (g: number, i: number) => 0.08 * i + 0.3 * g;
  s.counts.forEach((n, g) => {
    for (let i = 0; i < n; i++, k++) {
      const c = cells[k]!, x = (c % COLS) * CELL + CELL / 2 + rng.int(-9, 9), y = Math.floor(c / COLS) * CELL + CELL / 2 + rng.int(-9, 9);
      items.push(...glyph(s.glyphs[g]!, x, y, b ? { from: 0, until: b.rows - 1, enter: "pop", delay: 0.05 * k } : {}));
      // on the sorting beat the pile stays put and each object only fades out as its copy lands in its row, so nothing
      // vanishes at once (v43: the blocks blanked out at Play and popped back later)
      if (b) items.push(...glyph(s.glyphs[g]!, x, y, { from: b.rows, until: b.rows, enter: "flash", delay: -1, vars: { "--d2": `${rowDelay(g, i).toFixed(2)}s` } } as Timing));
    }
  });
  if (b) {
    const top = 0, pitch = 48, rowH = 56;
    s.counts.forEach((n, g) => {
      const y = top + g * rowH + 20;
      if (s.mark === g) items.push({ type: "rect", x: -14, y: y - 24, w: n * pitch + 80, h: 48, rx: 24, cls: "hlrow", from: b.mark, enter: "fade" } as Draft);
      for (let i = 0; i < n; i++) items.push(...glyph(s.glyphs[g]!, 14 + i * pitch, y, { from: b.rows, enter: "pop", delay: rowDelay(g, i) }));
      items.push(t(14 + n * pitch + 12, y, String(n), "lbl big start", { from: b.count, enter: "rise", delay: 0.4 * g }));
    });
  }
  return frame("early-sort", items, s.alt, 16, WIDE);
}
