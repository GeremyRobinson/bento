// Measuring with cubes: two things lie on a line, each with unit cubes laid end to end under it,
// starting right at its left edge. The longer one's extra cubes light up at the end.
import type { SceneDiagram } from "../scene/schema";
import { frame, t, type Draft } from "../geo/kit";

const U = 32, BAR = 22;

export interface MeasureSpec {
  /** the two things, top to bottom: name and length in cubes */
  things: { name: string; length: number }[];
  /** beats at which each row's cubes get counted, and the difference shows; leave out for the plain picture */
  beats?: { rows: number[]; diff: number };
  /** label beside the extra cubes, e.g. "3 more" */
  diffText?: string;
  alt: string;
}

export function buildMeasure(s: MeasureSpec): SceneDiagram {
  if (s.things.some(x => !Number.isInteger(x.length) || x.length < 1 || x.length > 15)) throw new Error("measure: lengths are 1 to 15 cubes");
  const items: Draft[] = [];
  const nameW = 82, rowH = BAR + U + 26;
  const b = s.beats;
  s.things.forEach((thing, r) => {
    // the first thing is part 1 (blue) and the one compared with it part 2 (orange): the thing, its name and its cubes
    const y = r * rowH, tone = r ? "c1" : "c0", part = r ? "p1" : "p0";
    items.push(t(0, y + BAR / 2, thing.name, `lbl start ${part}`, { enter: "fade" }));
    // the thing itself, with a rounded end
    items.push({ type: "rect", x: nameW, y, w: thing.length * U, h: BAR, rx: BAR / 2, cls: `cell ${tone}`, enter: "growx", delay: 0.1 + 0.2 * r } as Draft);
    for (let i = 0; i < thing.length; i++) {
      const x = nameW + i * U, cy = y + BAR + 4;
      items.push({ type: "rect", x: x + 1, y: cy, w: U - 2, h: U - 2, rx: 3, cls: `sq ${part}`, ...(b ? { from: b.rows[r]!, enter: "rise", delay: 0.08 * i } : { enter: "fade" }) } as Draft);
      if (b) items.push(t(x + U / 2, cy + U / 2 - 1, String(i + 1), "xs", { from: b.rows[r]!, enter: "fade", delay: 0.08 * i + 0.3 }));
    }
    // a dashed start line keeps both things lined up at the same edge
  });
  const total = s.things.length * rowH - 26;
  items.push({ type: "line", x1: nameW, y1: -8, x2: nameW, y2: total + 4, cls: "ax thin dash", enter: "fade" } as Draft);
  if (b && s.things.length === 2) {
    const p = s.things[0]!, q = s.things[1]!;
    const short = Math.min(p.length, q.length), long = Math.max(p.length, q.length), row = p.length > q.length ? 0 : 1;
    const y = row * rowH + BAR + 4;
    items.push({ type: "rect", x: nameW + short * U - 2, y: y - 3, w: (long - short) * U + 4, h: U + 4, rx: 6, cls: "hlline", from: b.diff, enter: "fade", delay: 0.2 } as Draft);
    items.push({ type: "line", x1: nameW + short * U, y1: -8, x2: nameW + short * U, y2: total + 4, cls: "ln2 dash", from: b.diff, enter: "fade" } as Draft);
    if (s.diffText) items.push(t(nameW + ((short + long) / 2) * U, total + 22, s.diffText, "lbl acc", { from: b.diff, enter: "rise", delay: 0.4 }));
  }
  return frame("measure", items, s.alt, 14, { w: 520 });
}
