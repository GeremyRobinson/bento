// Groups of counters for kindergarten: some dots, then more join or some are taken away, then what is there is counted;
// and two rows lined up so each dot finds a partner and the extras stand out.
import type { SceneDiagram } from "../scene/schema";
import { frame, t, type Draft } from "../geo/kit";
import { WIDE } from "./fit";

const GAP = 52, R = 15;

export interface ChangeSpec {
  start: number;
  change: number;
  /** "join": `change` more dots arrive; "take": the last `change` dots are crossed out */
  kind: "join" | "take";
  /** beats: the start counted, the change, the end counted. Leave out for the practice picture (just the start). */
  beats?: { start: number; change: number; end: number };
  alt: string;
}

/** A row of dots that grows or shrinks, counted before and after. */
export function changeDots(s: ChangeSpec): SceneDiagram {
  const { start, change, kind } = s;
  const end = kind === "join" ? start + change : start - change;
  if (![start, change, end].every(v => Number.isInteger(v) && v >= 0) || start + (kind === "join" ? change : 0) > 10) {
    throw new Error("change dots hold up to 10 dots and never go below 0");
  }
  const b = s.beats, items: Draft[] = [];
  const x = (i: number) => i * GAP;
  for (let i = 0; i < start; i++) {
    items.push({ type: "circle", cx: x(i), cy: 0, r: R, cls: "dotp", from: 0, enter: "pop", delay: b ? 0.12 * i : 0 } as Draft);
    if (b) items.push(t(x(i), 34, String(i + 1), "sm", { from: b.start, until: b.change, enter: "rise", delay: 0.12 * i + 0.1 }));
  }
  if (b) {
    if (kind === "join") {
      for (let k = 0; k < change; k++) {
        items.push({ type: "circle", cx: x(start + k), cy: 0, r: R, cls: "dotp p1", from: b.change, enter: "drop", delay: 0.3 * k } as Draft);
      }
      items.push(t((x(start) + x(start + change - 1)) / 2, -42, `${change} more`, "lbl p1", { from: b.change, enter: "rise" }));
    } else {
      for (let k = 0; k < change; k++) {
        const cx = x(start - change + k), d = R * 0.85;
        items.push({ type: "line", x1: cx - d, y1: -d, x2: cx + d, y2: d, cls: "ln p1", from: b.change, enter: "draw", delay: 0.3 * k } as Draft);
        items.push({ type: "line", x1: cx - d, y1: d, x2: cx + d, y2: -d, cls: "ln p1", from: b.change, enter: "draw", delay: 0.3 * k + 0.12 } as Draft);
      }
      items.push(t((x(start - change) + x(start - 1)) / 2, -42, `take away ${change}`, "lbl p1", { from: b.change, enter: "rise" }));
    }
    // count what is there now; the last number is the answer
    for (let i = 0; i < end; i++) {
      const last = i === end - 1;
      items.push(t(x(i), 34, String(i + 1), last ? "lbl acc" : "sm", { from: b.end, enter: "rise", delay: 0.25 * i }));
      if (last) items.push({ type: "circle", cx: x(i), cy: 0, r: R + 6, cls: "ln pq", from: b.end, enter: "pop", delay: 0.25 * i + 0.2 } as Draft);
    }
    if (end === 0) items.push(t(x(start - 1) / 2, 40, "none left", "lbl acc", { from: b.end, enter: "rise" }));
  }
  return frame("early-groups", items, s.alt, 16, WIDE);
}

export interface PairSpec {
  top: number;
  bottom: number;
  /** beats: the top row, the bottom row, partners matched. Leave out for the practice picture. */
  beats?: { top: number; bottom: number; match: number };
  alt: string;
}

/** Two rows lined up dot under dot. Partners get joined; the dots left over get a ring and a label. */
export function pairRows(s: PairSpec): SceneDiagram {
  const { top, bottom } = s;
  if (![top, bottom].every(v => Number.isInteger(v) && v >= 1 && v <= 10)) throw new Error("pair rows hold 1 to 10 dots each");
  const b = s.beats ?? { top: 0, bottom: 0, match: 0 }, shown = !!s.beats, items: Draft[] = [];
  const Y2 = 90, x = (i: number) => i * GAP;
  const row = (n: number, y: number, cls: string, beat: number, label: number) => {
    for (let i = 0; i < n; i++) items.push({ type: "circle", cx: x(i), cy: y, r: R, cls, from: beat, enter: "pop", delay: shown ? 0.12 * i : 0 } as Draft);
    if (shown) items.push(t(x(n - 1) + R + 26, y, String(label), cls === "dotp" ? "lbl p0" : "lbl p1", { from: beat, enter: "rise", delay: 0.12 * n }));
  };
  row(top, 0, "dotp", b.top, top);
  row(bottom, Y2, "dotp p1", b.bottom, bottom);
  if (shown) {
    const pairs = Math.min(top, bottom);
    for (let i = 0; i < pairs; i++) {
      items.push({ type: "line", x1: x(i), y1: R + 4, x2: x(i), y2: Y2 - R - 4, cls: "ln thin", from: b.match, enter: "draw", delay: 0.15 * i } as Draft);
    }
    const extraY = top > bottom ? 0 : Y2;
    for (let i = pairs; i < Math.max(top, bottom); i++) {
      items.push({ type: "circle", cx: x(i), cy: extraY, r: R + 5, cls: "ln2", from: b.match, enter: "pop", delay: 0.15 * pairs + 0.2 * (i - pairs) } as Draft);
    }
    const extra = Math.abs(top - bottom);
    const note = extra ? `${extra} without a partner` : "every dot has a partner";
    const noteX = extra ? (x(pairs) + x(Math.max(top, bottom) - 1)) / 2 : x(pairs - 1) / 2;
    const noteY = !extra ? Y2 + 46 : top > bottom ? -42 : Y2 + 42;
    items.push(t(noteX, noteY, note, "lbl acc", { from: b.match, enter: "rise", delay: 0.15 * pairs + 0.3 }));
  }
  return frame("early-pairs", items, s.alt, 16, WIDE);
}
