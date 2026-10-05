// Numerals written stroke by stroke beside the dots they count (k-write). Stroke shapes are the Design team's
// (design/pictures-k4.md §1): each digit sits in a 60 × 100 box, strokes start at a numbered dot, a ghost shows the
// finished digit to trace.
import type { SceneDiagram } from "../scene/schema";
import { frame, path, t, type Draft, type Pt, type Seg } from "../geo/kit";
import { WIDE } from "./fit";

const DIGITS: Record<string, string> = {
  "0": "M30 6 C 12 6, 5 28, 5 50 C 5 72, 12 94, 30 94 C 48 94, 55 72, 55 50 C 55 28, 48 6, 30 6",
  "1": "M18 20 L32 6 L32 94",
  "2": "M8 26 C 10 12, 20 6, 30 6 C 44 6, 53 15, 53 28 C 53 46, 30 64, 7 94 L 55 94",
  "3": "M9 16 C 14 9, 22 6, 30 6 C 43 6, 51 14, 51 26 C 51 39, 42 48, 28 48 C 44 48, 55 58, 55 71 C 55 85, 44 94, 30 94 C 20 94, 11 90, 6 82",
  "4": "M38 6 L6 64 L56 64 | M42 36 L42 94",
  "5": "M12 6 L9 45 C 16 40, 23 38, 30 38 C 46 38, 55 50, 55 66 C 55 83, 44 94, 28 94 C 18 94, 10 90, 6 84 | M20 6 L52 6",
  "6": "M48 10 C 43 7, 37 6, 31 6 C 14 6, 5 28, 5 58 C 5 81, 15 94, 30 94 C 46 94, 55 82, 55 68 C 55 53, 45 44, 31 44 C 19 44, 9 52, 6 62",
  "7": "M6 6 L55 6 L22 94",
  "8": "M50 20 C 47 11, 40 6, 30 6 C 17 6, 9 15, 9 27 C 9 40, 19 45, 30 50 C 43 56, 54 63, 54 76 C 54 88, 44 94, 30 94 C 16 94, 6 88, 6 76 C 6 63, 17 56, 30 50 C 41 45, 51 39, 51 28 C 51 25, 51 22, 50 20",
  "9": "M54 30 C 53 15, 44 6, 30 6 C 16 6, 6 15, 6 28 C 6 42, 16 51, 30 51 C 42 51, 51 45, 54 32 L54 94",
};

/** The strokes of one digit as path segments, scaled by k and moved to (x0, y0). */
export function digitStrokes(d: string, x0: number, y0: number, k: number): Seg[][] {
  const src = DIGITS[d];
  if (!src) throw new Error(`no strokes for digit ${d}`);
  const at = (x: number, y: number): Pt => [x0 + x * k, y0 + y * k];
  return src.split("|").map(stroke => {
    const segs: Seg[] = [];
    for (const [, c, body] of stroke.matchAll(/([MLC])([^MLC]*)/g)) {
      const v = (body!.match(/-?\d+(\.\d+)?/g) ?? []).map(Number);
      const pts: Pt[] = [];
      for (let i = 0; i + 1 < v.length; i += 2) pts.push(at(v[i]!, v[i + 1]!));
      if (c === "C") for (let i = 0; i + 2 < pts.length; i += 3) segs.push({ c: "C", c1: pts[i]!, c2: pts[i + 1]!, p: pts[i + 2]! });
      else for (const p of pts) segs.push({ c: c as "M" | "L", p });
    }
    return segs;
  });
}

const CELL = 46, DOT = 16, TEN = 10;

/** n dots in ten frames: one frame up to 10, two for 11 to 20, the first filled before the second. */
export function dotFrames(n: number, o: { counted?: number } = {}): Draft[] {
  if (!Number.isInteger(n) || n < 0 || n > 2 * TEN) throw new Error("ten frames hold 0 to 20 dots");
  const frames = n > TEN ? 2 : 1, items: Draft[] = [];
  for (let f = 0; f < frames; f++) {
    for (let i = 0; i < TEN; i++) items.push({ type: "rect", x: (i % 5) * CELL, y: f * (2 * CELL + 18) + Math.floor(i / 5) * CELL, w: CELL, h: CELL, cls: "seg", from: 0 } as Draft);
  }
  for (let i = 0; i < n; i++) {
    const f = Math.floor(i / TEN), j = i % TEN;
    const cx = (j % 5) * CELL + CELL / 2, cy = f * (2 * CELL + 18) + Math.floor(j / 5) * CELL + CELL / 2;
    items.push({ type: "circle", cx, cy, r: DOT, cls: "dotp", from: 0, enter: "pop", delay: o.counted != null ? 0.1 * i : 0 } as Draft);
    if (o.counted != null) items.push(t(cx, cy, String(i + 1), "xs onlbl", { from: o.counted, until: o.counted, enter: "fade", delay: 0.1 * i + 0.1 }));
  }
  return items;
}

export interface WriteSpec {
  n: number;
  /** beats: the dots counted, the numeral written, both finished. Leave out for the practice picture (dots only). */
  beats?: { count: number; write: number; done: number };
  alt: string;
}

/** The dots to count, and with beats the numeral writing itself beside them. */
export function writeNumber(s: WriteSpec): SceneDiagram {
  const b = s.beats, items = dotFrames(s.n, b ? { counted: b.count } : {});
  if (b) {
    const k = 1.3, digits = String(s.n), x0 = 5 * CELL + 56, frames = s.n > TEN ? 2 : 1;
    const top = (frames * 2 * CELL + (frames - 1) * 18 - 100 * k) / 2;
    let delay = 0, stroke = 0;
    [...digits].forEach((d, di) => {
      const strokes = digitStrokes(d, x0 + di * (60 * k + 12), top, k);
      for (const segs of strokes) items.push(path(segs, "numghost", { from: b.write, enter: "fade" }));
      for (const segs of strokes) {
        stroke++;
        const start = (segs[0] as { p: Pt }).p;
        items.push(path(segs, "numst p1", { from: b.write, enter: "draw", delay: delay + 0.2 }));
        items.push({ type: "circle", cx: start[0], cy: start[1], r: 9, cls: "dota", from: b.write, until: b.write, enter: "pop", delay } as Draft);
        items.push(t(start[0], start[1], String(stroke), "xs onlbl", { from: b.write, until: b.write, enter: "fade", delay }));
        delay += 0.8;
      }
    });
    if (s.n > TEN) items.push(t(2.5 * CELL, -22, "1 ten", "lbl", { from: b.count, enter: "rise", delay: 0.4 }));
    const under = frames * 2 * CELL + (frames - 1) * 18 + 30;
    items.push(t(2.5 * CELL, under, s.n === 1 ? "1 dot" : `${s.n} dots`, "lbl acc", { from: b.done, enter: "rise" }));
  }
  return frame("early-numerals", items, s.alt, 16, WIDE);
}
