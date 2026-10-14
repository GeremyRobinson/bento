// A timeline for elapsed time: hour marks with clock labels (noon marked), the start and end times as points,
// and the time between them split into stretches (minutes up to the hour, whole hours, minutes after),
// each shown with its length at its own beat. Times are minutes after midnight, all from the lesson.
import type { SceneDiagram } from "../scene/schema";
import { frame, seg, t, type Draft } from "../geo/kit";
import { PIC, roomLeft, thinOut } from "../scene/picture-system";

export interface TimeStretch { from: number; to: number; text: string; beat: number; cls: "hl" | "ln" }

export interface TimelineSpec {
  start: number;
  end: number;
  /** label for a time, e.g. "9:40" */
  clock: (minutes: number) => string;
  stretches: TimeStretch[];
  /** a line under the timeline from a beat, e.g. the total */
  total?: { text: string; beat: number };
  alt: string;
}

/**
 * Drawn at about a phone's picture width (the line 300 long), so its labels laid out at their phone size land where they
 * are drawn; on a tablet it grows to its box and its text grows less (SceneDiagram). Each label is held by its edge
 * nearest the line (.up above it, .down under it), and a row further out moves on by what the rows nearer the line grew
 * at the phone floor, so stacked labels never meet at any size.
 */
const L = 300, LBL = PIC.label, GROWS = 1.6, ROW = 26;
/** how much a row of labels (20 units, at least 20px on screen) grows on a phone, per row */
const lblGrow = (rows: number) => `${Math.round(rows * 125) / 100} * (max(${LBL}, ${LBL} * var(--px, 0)) - ${LBL})`;
/** the clock row under the line (15 units, at least 14px on screen) */
const smGrow = "1.2 * max(0, 14 * var(--px, 0) - 15)";
/** the start / end word (12 units, at least 14px on screen) */
const xsGrow = "1.2 * max(0, 14 * var(--px, 0) - 12)";
const moveY = (sign: 1 | -1, ...parts: string[]) => (parts.length ? { vars: { transform: `translateY(calc(${sign < 0 ? "-1 * " : ""}(${parts.join(" + ")}) * 1px))` } } : {});

export function buildTimeline(s: TimelineSpec): SceneDiagram {
  const h0 = Math.floor(s.start / 60), h1 = Math.ceil(s.end / 60), px = L / ((h1 - h0) * 60);
  const X = (m: number) => (m - h0 * 60) * px;
  const items: Draft[] = [seg([-12, 0], [L + 12, 0], "ax", { enter: "fade" })];
  // hour clocks hang under their marks; where the floor grows them together every other one fades (noon with 12:00)
  const hourW = 60 * px;
  for (let m = h0 * 60; m <= h1 * 60; m += 15) {
    const hour = m % 60 === 0;
    items.push(seg([X(m), hour ? -9 : -5], [X(m), hour ? 9 : 5], hour ? "ax" : "tk", { enter: "fade" }));
    if (hour) {
      const k = m / 60 - h0, level = k & -k;
      const fade = k ? { vars: thinOut(roomLeft(level * hourW, 4.6, 15)) } : {};
      items.push(t(X(m), 13, s.clock(m), "sm down", { enter: "fade", ...fade }));
      if (m === 12 * 60) items.push(t(X(m), 32, "noon", "xs down", { enter: "fade", vars: { ...fade.vars, transform: `translateY(calc(${smGrow} * 1px))` } }));
    }
  }
  // roles (handoff-6): the stretches are the parts of the time between, in part order (blue, orange, violet), each
  // labelled in its own color; the given start and end times are ink; the total being found is amber.
  // A stretch's length stands over it. The first and last (the minutes before and after the hours) are held by their
  // edge at the hours' ends, so on a phone they grow outwards, away from each other; the middle one stays over its
  // middle, and goes a row up when it would meet them at its phone width.
  const rows: { x0: number; x1: number }[][] = [];
  const last = s.stretches.length - 1;
  s.stretches.forEach((st, k) => {
    const part = `p${k % 3}`, w = st.text.length * LBL * 0.62 * GROWS;
    items.push(seg([X(st.from), 0], [X(st.to), 0], `ln ${part}`, { from: st.beat, enter: "growx" }));
    items.push(seg([X(st.from), -4], [X(st.from), -16], "tk", { from: st.beat, enter: "fade" }));
    items.push(seg([X(st.to), -4], [X(st.to), -16], "tk", { from: st.beat, enter: "fade" }));
    const edge = last > 0 && k === 0 ? "end" : last > 0 && k === last ? "start" : "";
    const x = edge === "end" ? X(st.to) - 3 : edge === "start" ? X(st.from) + 3 : (X(st.from) + X(st.to)) / 2;
    const box = edge === "end" ? { x0: x - w, x1: x } : edge === "start" ? { x0: x, x1: x + w } : { x0: x - w / 2, x1: x + w / 2 };
    let row = rows.findIndex(r => r.every(o => o.x1 + 4 < box.x0 || box.x1 + 4 < o.x0));
    if (row < 0) { row = rows.length; rows.push([]); }
    rows[row]!.push(box);
    items.push(t(x, -18 - row * ROW, st.text, `sm lbl ${part} up${edge ? ` ${edge}` : ""}`, { from: st.beat, enter: "rise", delay: 0.3, ...moveY(-1, ...(row ? [lblGrow(row)] : [])) }));
  });
  // the given times over everything, each over its dot, with its word beside it on the outside (start to the left, end to
  // the right), moved out by half the time's width as drawn, so the two stay apart at any size
  const R = Math.max(1, rows.length), base = -18 - R * ROW + 2, lift = moveY(-1, lblGrow(R));
  for (const [m, word, dir] of [[s.start, "start", -1], [s.end, "end", 1]] as const) {
    const time = s.clock(m), half = Math.round(time.length * 31) / 100;
    items.push({ type: "circle", cx: X(m), cy: 0, r: 7, cls: "dotp pw", enter: "pop" } as Draft);
    items.push(t(X(m), base, time, "lbl pw up", { enter: "rise", ...lift }));
    const out = `translateX(calc(${dir < 0 ? "-1 * " : ""}(${half} * max(var(--pic-label, 20px), calc(20px * var(--px, 0))) + 5px)))`;
    items.push(t(X(m), base - 1, word, `xs up ${dir < 0 ? "end" : "start"}`, { enter: "fade", vars: { transform: `${out} ${lift.vars!.transform}` } }));
  }
  // the total hangs under the clocks (and noon), moving down by what those rows grew
  const noon = h0 * 60 <= 720 && 720 <= h1 * 60;
  if (s.total) items.push(t(L / 2, noon ? 50 : 34, s.total.text, "lbl acc down cap", { from: s.total.beat, enter: "rise", delay: 0.3, ...moveY(1, smGrow, ...(noon ? [xsGrow] : [])) }));
  // a short strip is mostly these rows of text on a phone: the frame may grow further for them
  return frame("timeline", items, s.alt, 14, { w: L + 40, grow: 2.2 });
}
