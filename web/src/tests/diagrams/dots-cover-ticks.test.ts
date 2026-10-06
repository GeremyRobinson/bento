import { describe, expect, it } from "vitest";
import { LESSONS } from "../../curriculum/registry";
import { createRng } from "../../curriculum/generators/rng";

/**
 * G (2026-10-06): "this line is weird in the circle". A tick or axis mark that runs through a point's dot must not poke
 * out of it: a dot sitting on a tick covers the whole tick.
 */
describe("dots cover the ticks they sit on", () => {
  it("no tick pokes out of a dot", () => {
    const bad = new Set<string>();
    for (const l of LESSONS) {
      const rng = createRng(7);
      for (let k = 0; k < 6; k++) {
        let ex;
        try { const p = l.generate(rng, 1 + (k % 3)); ex = l.explain(p, l.answers(p)); } catch { continue; }
        const d = ex.diagram;
        if (!d || d.kind !== "scene") continue;
        const items = d.items as { type: string; cls?: string; cx?: number; cy?: number; r?: number; x1?: number; y1?: number; x2?: number; y2?: number }[];
        const dots = items.filter(i => i.type === "circle" && /\bdot[pa]?\b|dotp|dota/.test(i.cls ?? ""));
        for (const t of items) {
          if (t.type !== "line" || !/\b(tk|ax)\b/.test(t.cls ?? "")) continue;
          const vertical = Math.abs(t.x1! - t.x2!) < 0.01, horizontal = Math.abs(t.y1! - t.y2!) < 0.01;
          if (!vertical && !horizontal) continue;
          for (const c of dots) {
            // the tick crosses the dot's centre and reaches past its edge (plus a hair for the stroke's cap)
            const [a, b, along, across] = vertical ? [t.y1!, t.y2!, c.cy!, t.x1! - c.cx!] : [t.x1!, t.x2!, c.cx!, t.y1! - c.cy!];
            if (Math.abs(across) > 0.5 || along < Math.min(a, b) || along > Math.max(a, b)) continue;
            // a mark that runs through the dot and out both sides; a ruler mark that only hangs from a dot's edge is fine
            const reach = Math.min(Math.abs(a - along), Math.abs(b - along));
            // long lines (an axis) pass through on purpose; only short marks are ticks
            if (reach > c.r! + 0.5 && Math.abs(a - b) < 40) bad.add(`${l.id}: ${t.cls} ±${reach} through r=${c.r}`);
          }
        }
      }
    }
    expect([...bad]).toEqual([]);
  });
});
