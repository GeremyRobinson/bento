// Two things lined up at the same start, measured in cubes: each one counted, then the extra part of the longer one lit.
import type { SceneDiagram } from "../scene/schema";
import { frame, seg, t, type Draft } from "../geo/kit";
import { WIDE } from "./fit";

const U = 40, H = 34;

export interface LengthSpec {
  top: { name: string; cubes: number };
  bottom: { name: string; cubes: number };
  /** beats: the top counted, the bottom counted, the two compared. Leave out for the practice picture. */
  beats?: { top: number; bottom: number; compare: number };
  alt: string;
}

export function lengthBars(s: LengthSpec): SceneDiagram {
  const { top, bottom } = s, b = s.beats, items: Draft[] = [];
  for (const v of [top.cubes, bottom.cubes]) if (!Number.isInteger(v) || v < 1 || v > 10) throw new Error("a length is 1 to 10 cubes");
  const Y2 = b ? 96 : 64;
  const bar = (o: { name: string; cubes: number }, y: number, cls: string, beat: number | undefined) => {
    items.push({ type: "rect", x: 0, y, w: o.cubes * U, h: H, rx: 10, cls, enter: "growx" } as Draft);
    items.push(t(-14, y + H / 2, o.name, "sm end"));
    // the cubes: a line between each one, and a number under each when it is counted
    for (let i = 1; i < o.cubes; i++) items.push(seg([i * U, y + 3], [i * U, y + H - 3], "cf", beat == null ? {} : { from: beat, enter: "fade", delay: 0.3 * i }));
    if (beat == null) return;
    for (let i = 0; i < o.cubes; i++) {
      const last = i === o.cubes - 1;
      items.push(t(i * U + U / 2, y + H + 16, String(i + 1), last ? "lbl acc" : "sm", { from: beat, enter: "rise", delay: 0.3 * i }));
    }
  };
  bar(top, 0, "bar", b?.top);
  bar(bottom, Y2, "bar p1", b?.bottom);
  // the start line both things touch
  items.push(seg([0, -12], [0, Y2 + H + 12], "ax thin"));
  if (b) {
    const short = Math.min(top.cubes, bottom.cubes), long = Math.max(top.cubes, bottom.cubes), extra = long - short;
    items.push(seg([short * U, -12], [short * U, Y2 + H + 12], "ax thin dash", { from: b.compare, enter: "draw" }));
    if (extra) {
      // a ring around the part that sticks out
      const y = top.cubes > bottom.cubes ? 0 : Y2;
      items.push({ type: "rect", x: short * U + 3, y: y - 5, w: extra * U + 2, h: H + 10, rx: 12, cls: "ln2", from: b.compare, enter: "pop", delay: 0.4 } as Draft);
      const ly = top.cubes > bottom.cubes ? -26 : Y2 + H + 44;
      items.push(t(((short + long) / 2) * U, ly, `${extra} more`, "lbl acc", { from: b.compare, enter: "rise", delay: 0.7 }));
    } else {
      items.push(t((short / 2) * U, Y2 + H + 44, "same length", "lbl acc", { from: b.compare, enter: "rise", delay: 0.4 }));
    }
  }
  return frame("early-lengths", items, s.alt, 16, WIDE);
}
