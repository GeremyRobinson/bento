// A timeline for elapsed time: hour marks with clock labels (noon marked), the start and end times as points,
// and the time between them split into stretches (minutes up to the hour, whole hours, minutes after),
// each shown with its length at its own beat. Times are minutes after midnight, all from the lesson.
import type { SceneDiagram } from "../scene/schema";
import { frame, seg, t, type Draft } from "../geo/kit";

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

export function buildTimeline(s: TimelineSpec): SceneDiagram {
  const h0 = Math.floor(s.start / 60), h1 = Math.ceil(s.end / 60), L = 470, px = L / ((h1 - h0) * 60);
  const X = (m: number) => (m - h0 * 60) * px;
  const items: Draft[] = [seg([-12, 0], [L + 12, 0], "ax", { enter: "fade" })];
  for (let m = h0 * 60; m <= h1 * 60; m += 15) {
    const hour = m % 60 === 0;
    items.push(seg([X(m), hour ? -9 : -5], [X(m), hour ? 9 : 5], hour ? "ax" : "tk", { enter: "fade" }));
    if (hour) {
      items.push(t(X(m), 26, s.clock(m), "sm", { enter: "fade" }));
      if (m === 12 * 60) items.push(t(X(m), 46, "noon", "xs", { enter: "fade" }));
    }
  }
  // roles (handoff-6): the stretches are the parts of the time between, in part order (blue, orange, violet), each
  // labelled in its own color; the given start and end times are ink; the total being found is amber
  s.stretches.forEach((st, k) => {
    const part = `p${k % 3}`;
    items.push(seg([X(st.from), 0], [X(st.to), 0], `ln ${part}`, { from: st.beat, enter: "growx" }));
    items.push(seg([X(st.from), -4], [X(st.from), -16], "tk", { from: st.beat, enter: "fade" }));
    items.push(seg([X(st.to), -4], [X(st.to), -16], "tk", { from: st.beat, enter: "fade" }));
    items.push(t((X(st.from) + X(st.to)) / 2, -28, st.text, `sm lbl ${part}`, { from: st.beat, enter: "rise", delay: 0.3 }));
  });
  for (const [m, word] of [[s.start, "start"], [s.end, "end"]] as const) {
    items.push({ type: "circle", cx: X(m), cy: 0, r: 7, cls: "dotp pw", enter: "pop" } as Draft);
    items.push(t(X(m), -62, word, "xs", { enter: "fade" }));
    items.push(t(X(m), -80, s.clock(m), "lbl pw", { enter: "rise" }));
  }
  if (s.total) items.push(t(L / 2, 78, s.total.text, "lbl acc", { from: s.total.beat, enter: "rise", delay: 0.3 }));
  return frame("timeline", items, s.alt, 14, { w: 540 });
}
