// Measuring pictures for 2nd grade: a clock face with 5-minute marks, a ruler under an object, and a bar graph.
import type { SceneDiagram } from "../scene/schema";
import { arc, frame, path, polar, seg, t, type Draft, type Pt } from "../geo/kit";
import { circle, line, rect } from "./kit";
import { tw } from "./blocks";

// ---------------------------------------------------------------- clock

export interface ClockSpec {
  hour: number;
  minute: number;
  beats: { hour: number; number: number; count: number; time: number };
  text: { hour: string; number: string; count: string; time: string };
  /** a practice picture: just the clock */
  bare?: boolean;
  alt: string;
}

const CR = 112, C: Pt = [0, 0];
/** A point on the clock at `turn` degrees clockwise from 12. */
const at = (r: number, turn: number): Pt => polar(C, r, 90 - turn);

export function buildClock(spec: ClockSpec): SceneDiagram {
  const { hour: h, minute: m, beats } = spec;
  if (!(Number.isInteger(h) && h >= 1 && h <= 12 && Number.isInteger(m) && m >= 0 && m < 60 && m % 5 === 0)) throw new Error("clock: hour 1 to 12, minutes in fives");
  const k = m / 5, items: Draft[] = [];
  items.push(circle(0, 0, CR, "hole"));
  for (let i = 0; i < 60; i++) {
    const five = i % 5 === 0, [x1, y1] = at(CR - (five ? 14 : 7), i * 6), [x2, y2] = at(CR - 2, i * 6);
    items.push(line(x1, y1, x2, y2, five ? "ax" : "tk"));
  }
  for (let n = 1; n <= 12; n++) { const [x, y] = at(CR - 32, n * 30); items.push(t(x, y, String(n), "")); }
  const hourTurn = (h % 12) * 30 + m / 2, minTurn = m * 6;
  const hourTip = at(58, hourTurn), minTip = at(CR - 18, minTurn);
  items.push(line(0, 0, minTip[0], minTip[1], "ln"), line(0, 0, hourTip[0], hourTip[1], "beam"), circle(0, 0, 6, "dotp"));
  if (!spec.bare) {
    // the hand being read glows on its beat
    items.push(line(0, 0, hourTip[0], hourTip[1], "hlline", { from: beats.hour, until: beats.hour, enter: "draw" }));
    items.push(line(0, 0, minTip[0], minTip[1], "hlline", { from: beats.number, until: beats.count, enter: "draw" }));
    const [nx, ny] = at(CR - 32, (k || 12) * 30);
    items.push(circle(nx, ny, 16, "hlline", { from: beats.number, until: beats.count, enter: "pop", delay: 0.4 }));
    // counting by fives around the outside, one label per number passed
    if (k > 0) items.push(path(arc(C, CR + 10, 90, 90 - minTurn), "ln2", { from: beats.count, enter: "draw slow" }));
    for (let i = 1; i <= k; i++) {
      const [x, y] = at(CR + 30, i * 30);
      items.push(t(x, y, String(i * 5), i === k ? "lbl acc" : "sm", { from: beats.count, enter: "pop", delay: 0.12 * i }));
    }
    const y = CR + 66;
    items.push(t(0, y, spec.text.hour, "lbl", { from: beats.hour, until: beats.number - 1, enter: "rise", delay: 0.4 }));
    items.push(t(0, y, spec.text.number, "lbl", { from: beats.number, until: beats.count - 1, enter: "rise", delay: 0.4 }));
    items.push(t(0, y, spec.text.count, "lbl", { from: beats.count, until: beats.time - 1, enter: "rise", delay: 0.6 }));
    items.push(t(0, y, spec.text.time, "lbl big acc", { from: beats.time, enter: "rise" }));
  }
  // room for the count labels even before they show, so the clock never jumps
  return frame("early-g2-clock", items, spec.alt, 14, spec.bare ? {} : { w: 2 * (CR + 44) + 28 });
}

// ---------------------------------------------------------------- ruler

export const THINGS = [
  { name: "pencil", cls: "cell c0", tip: true },
  { name: "crayon", cls: "cell c0", tip: true },
  { name: "ribbon", cls: "cell c0", tip: false },
  { name: "straw", cls: "cell c0", tip: false },
] as const;

export interface RulerSpec {
  /** "in" or "cm" */
  unit: "in" | "cm";
  /** the ruler's last number */
  max: number;
  start: number;
  end: number;
  thing: number;
  beats: { start: number; end: number; count: number };
  text: { start: string; end: string; count: string };
  bare?: boolean;
  alt: string;
}

export function buildRuler(spec: RulerSpec): SceneDiagram {
  const { unit, max, start: s, end: e, beats } = spec;
  if (!(Number.isInteger(s) && Number.isInteger(e) && 0 <= s && s < e && e <= max)) throw new Error("ruler: the object must lie on the ruler");
  const u = unit === "in" ? 44 : 30, x = (v: number) => v * u;
  const thing = THINGS[spec.thing];
  if (!thing) throw new Error("ruler: unknown object");
  const items: Draft[] = [];
  // the ruler: a strip with a tick for every unit and a short one halfway
  items.push(rect(x(0) - 14, 0, x(max) + 28, 52, "fillsoft", {}, 6), rect(x(0) - 14, 0, x(max) + 28, 52, "ax thin", {}, 6));
  for (let v = 0; v <= max; v++) {
    items.push(line(x(v), 0, x(v), 18, "ax thin"));
    items.push(t(x(v), 32, String(v), unit === "in" ? "sm" : "xs"));
    if (v < max) items.push(line(x(v + 0.5), 0, x(v + 0.5), 10, "tk"));
  }
  items.push(t(x(max) + 24, 26, unit, "sm start"));
  // the object sits just above the ruler
  const top = -42, H = 24, x0 = x(s), x1 = x(e), tipW = thing.tip ? Math.min(22, (x1 - x0) / 4) : 0;
  items.push(rect(x0, top, x1 - x0 - tipW, H, thing.cls, { enter: "growx" }, thing.tip ? 3 : 6));
  if (thing.tip) items.push({ type: "polygon", points: [[x1 - tipW, top], [x1, top + H / 2], [x1 - tipW, top + H]], cls: thing.cls, enter: "fade", delay: 0.4 } as Draft);
  if (!spec.bare) {
    items.push(seg([x0, top - 12], [x0, 0], "ln2 dash", { from: beats.start, enter: "draw" }));
    items.push(t(x0, top - 24, "start", "xs", { from: beats.start, enter: "rise" }));
    items.push(circle(x0, 0, 6, "dota", { from: beats.start, enter: "pop", delay: 0.3 }));
    items.push(seg([x1, top - 12], [x1, 0], "ln2 dash", { from: beats.end, enter: "draw" }));
    items.push(t(x1, top - 24, "end", "xs", { from: beats.end, enter: "rise" }));
    items.push(circle(x1, 0, 6, "dota", { from: beats.end, enter: "pop", delay: 0.3 }));
    // one hop under the ruler for every unit from start to end; a long object hops faster, so every hop and its count
    // are drawn within a second, the same as a short one (v43: a 9 cm pencil's counter looked stuck at 5)
    const gap = Math.min(0.2, 0.9 / (e - s));
    for (let v = s; v < e; v++) {
      const d = gap * (v - s);
      items.push(path([{ c: "M", p: [x(v), 60] }, { c: "Q", q: [x(v + 0.5), 60 + 26], p: [x(v + 1), 60] }], "ln", { from: beats.count, enter: "draw", delay: d }));
      items.push(t(x(v + 0.5), 88, String(v - s + 1), v === e - 1 ? "lbl acc" : "sm", { from: beats.count, enter: "rise", delay: d + 0.2 }));
    }
    const y = 128, mid = x(max) / 2;
    items.push(t(mid, y, spec.text.start, "lbl", { from: beats.start, until: beats.end - 1, enter: "rise", delay: 0.4 }));
    items.push(t(mid, y, spec.text.end, "lbl", { from: beats.end, until: beats.count - 1, enter: "rise", delay: 0.4 }));
    items.push(t(mid, y, spec.text.count, "lbl big acc", { from: beats.count, enter: "rise", delay: gap * (e - s) }));
  }
  return frame("early-g2-ruler", items, spec.alt, 14, {});
}

// ---------------------------------------------------------------- bar graph

export interface BarGraphSpec {
  title: string;
  names: string[];
  values: number[];
  /** the two bars the question is about */
  first: number;
  second: number;
  /** "more": how many more the first has; "total": both together */
  kind: "more" | "total";
  beats: { first: number; second: number; combine: number };
  text: { first: string; second: string; combine: string };
  bare?: boolean;
  alt: string;
}

// wide gaps so two long names ("cloudy", "windy") stay apart when the labels are held at 12px on a phone
const BW = 56, BG = 48, U = 22;
// an odd axis number fades out once the picture is drawn below 0.6 of its size (--px, the units per screen pixel,
// above 1/0.6): its 12px floor would stack it on its neighbours, so the axis reads 0, 2, 4 and the grid keeps every line
const ODD_AXIS = { opacity: "clamp(0, calc((1.667 - var(--px, 0)) * 1000), 1)" };

export function buildBarGraph(spec: BarGraphSpec): SceneDiagram {
  const { values, beats } = spec;
  const top = Math.max(...values) <= 8 ? 8 : 10;
  if (values.some(v => !Number.isInteger(v) || v < 0 || v > top)) throw new Error("bar graph: whole values up to 10");
  const bx = (i: number) => 22 + i * (BW + BG), W = bx(values.length) - BG + 14, y = (v: number) => -v * U;
  const items: Draft[] = [];
  for (let v = 0; v <= top; v++) {
    if (v) items.push(line(0, y(v), W, y(v), "grid"));
    items.push(t(-14, y(v), String(v), "xs", v % 2 ? { vars: ODD_AXIS } : {}));
  }
  items.push(line(0, 0, W, 0, "ax"), line(0, 0, 0, y(top) - 8, "ax"));
  values.forEach((v, i) => {
    items.push(rect(bx(i), y(v), BW, v * U, "bar", { enter: "growy", delay: 0.1 * i }, 4));
    items.push(t(bx(i) + BW / 2, 22, spec.names[i]!, "sm"));
  });
  items.push(t(W / 2, y(top) - 30, spec.title, "lbl pw"));
  if (!spec.bare) {
    const read = (i: number, beat: number, until?: number) => {
      const v = values[i]!;
      // every bar is blue; a bar the question asks about turns amber while it's read (handoff-6)
      items.push(rect(bx(i), y(v), BW, v * U, "bar pq", { from: beat, ...(spec.kind === "more" ? { until: beats.combine - 1 } : {}), enter: "fade" }, 4));
      items.push(rect(bx(i) - 5, y(v) - 5, BW + 10, v * U + 5, "hlline", { from: beat, ...(until != null ? { until } : {}), enter: "fade" }, 6));
      items.push(seg([bx(i), y(v)], [0, y(v)], "ln2 dash", { from: beat, enter: "draw", delay: 0.3 }));
      items.push(t(bx(i) + BW / 2, y(v) + U / 2, String(v), "lbl onlbl", { from: beat, enter: "rise", delay: 0.5 }));
    };
    read(spec.first, beats.first, beats.second - 1);
    read(spec.second, beats.second, beats.combine - 1);
    const a = values[spec.first]!, b = values[spec.second]!;
    if (spec.kind === "more") {
      // the part of the taller bar that sticks out above the shorter one
      items.push(rect(bx(spec.first), y(a), BW, (a - b) * U, "shadeB", { from: beats.combine, enter: "fade" }, 4));
      items.push(seg([bx(Math.min(spec.first, spec.second)), y(b)], [bx(Math.max(spec.first, spec.second)) + BW, y(b)], "ln2 dash", { from: beats.combine, enter: "draw" }));
    } else {
      items.push(rect(bx(spec.first) - 5, y(a) - 5, BW + 10, a * U + 5, "hlline", { from: beats.combine, enter: "fade" }, 6));
      items.push(rect(bx(spec.second) - 5, y(b) - 5, BW + 10, b * U + 5, "hlline", { from: beats.combine, enter: "fade" }, 6));
    }
    const ty = 62;
    items.push(t(W / 2, ty, spec.text.first, "lbl", { from: beats.first, until: beats.second - 1, enter: "rise", delay: 0.5 }));
    items.push(t(W / 2, ty, spec.text.second, "lbl", { from: beats.second, until: beats.combine - 1, enter: "rise", delay: 0.5 }));
    items.push(t(W / 2, ty, spec.text.combine, "lbl big acc", { from: beats.combine, enter: "rise", delay: 0.4 }));
  }
  return frame("early-g2-bar-graph", items, spec.alt, 14, { w: Math.max(320, tw(spec.title) + 30) });
}
