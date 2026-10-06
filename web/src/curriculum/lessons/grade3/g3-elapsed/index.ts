import { br, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTimeline } from "../../../../explanations/diagrams/early-g3/timeline";
import { box, boxes, expectedOf, restoreVia, wholeIn } from "../_kit/steps";
import { count } from "../../../text";

/** How long from start to end, both in minutes after midnight on the same day. */
export interface ElapsedProblem { start: number; end: number }

export function createElapsed(start: number, end: number): ElapsedProblem {
  wholeIn("start", start, 6 * 60, 20 * 60);
  wholeIn("end", end, start + 1, 21 * 60 + 55);
  if (start % 5 || end % 5) throw new Error("times are on 5-minute marks");
  if (start % 60 === 0 || end % 60 === 0) throw new Error("start and end fall between o'clocks");
  const h1 = Math.ceil(start / 60), h2 = Math.floor(end / 60);
  if (h2 - h1 < 1) throw new Error("at least one whole hour lies between start and end");
  if (Math.ceil(end / 60) - Math.floor(start / 60) > 5) throw new Error("at most five hours on the timeline");
  return { start, end };
}

/** Early problems: quarter-hour times in the morning or the afternoon. Later: any 5-minute times, sometimes across noon. */
export function generateElapsed(rng: Rng, index: number): ElapsedProblem {
  for (;;) {
    const early = index < 3;
    const mins = () => (early ? rng.pick([15, 30, 45]) : rng.int(1, 11) * 5);
    const h = early ? rng.pick([7, 8, 9, 13, 14, 15]) : rng.next() < 0.4 ? rng.int(9, 11) : rng.int(6, 17);
    const hours = rng.int(1, early ? 2 : 3);
    const start = h * 60 + mins(), end = (h + hours + 1) * 60 + mins();
    if (early && (h < 12) !== (h + hours + 1 < 12)) continue;
    if (early && 60 - (start % 60) + (end % 60) >= 60) continue;
    try { return createElapsed(start, end); } catch { /* try again */ }
  }
}

/** "9:40" on a 12-hour clock. */
export const clock = (m: number) => `${((Math.floor(m / 60) + 11) % 12) + 1}:${String(m % 60).padStart(2, "0")}`;
/** "9:40 a.m." */
export const clockAmPm = (m: number) => `${clock(m)} ${m < 12 * 60 ? "a.m." : "p.m."}`;
const h12 = (h: number) => ((h + 11) % 12) + 1;
const hrs = (n: number) => `${n} ${n === 1 ? "hour" : "hours"}`;

/** The three stretches: minutes up to the first o'clock, whole hours, minutes after the last o'clock. */
export function parts({ start, end }: ElapsedProblem) {
  const H1 = Math.ceil(start / 60), H2 = Math.floor(end / 60);
  const m1 = H1 * 60 - start, h = H2 - H1, m3 = end - H2 * 60, total = end - start;
  return { H1, H2, m1, h, m3, total, th: Math.floor(total / 60), tm: total % 60 };
}

function answers(p: ElapsedProblem): AnswerModel {
  const { start, end } = p, { H1, H2, m1, h, m3, th, tm } = parts(p);
  const noon = H1 <= 12 && H2 > 12;
  return {
    steps: [
      box({
        id: "to-hour", label: "Up to the hour", question: `From ${clock(start)} to ${clock(H1 * 60)}, how many minutes?`,
        prompt: x => [text(`${clock(start)} to ${clock(H1 * 60)} `), op("="), x, text(" min")], ans: m1,
        wrong: [
          [start % 60, "Used the minutes on the clock", `${start % 60} is where the minute hand starts. Count on from :${String(start % 60).padStart(2, "0")} up to :60.`],
          [100 - (start % 60), "Counted to 100", `An hour has 60 minutes, not 100. ${start % 60} + ${m1} = 60.`],
        ],
        hint: `An hour has 60 minutes. What goes with ${start % 60} to make 60?`,
        explain: `${start % 60} + ${m1} = 60, so it's ${count(m1, "minute")} up to ${clock(H1 * 60)}.`,
      }),
      box({
        id: "hours", label: "Whole hours", question: `From ${clock(H1 * 60)} to ${clock(H2 * 60)}, how many hours?`,
        prompt: x => [text(`${clock(H1 * 60)} to ${clock(H2 * 60)} `), op("="), x, text(" h")], ans: h,
        wrong: [
          ...(noon ? [[Math.abs(h12(H2) - h12(H1)), "Counted the hours wrong across noon", `After 12 the clock starts again at 1. Count on: ${Array.from({ length: h + 1 }, (_, i) => h12(H1 + i)).join(", ")}. That's ${hrs(h)}.`] as [number, string, string]] : []),
          [h + 1, "Counted the hour marks", `Count the jumps between the hour marks, not the marks. From ${clock(H1 * 60)} to ${clock(H2 * 60)} is ${hrs(h)}.`],
        ],
        hint: `Count the hours on from ${clock(H1 * 60)}${noon ? ". After 12 comes 1" : ""}.`,
        explain: `${clock(H1 * 60)} to ${clock(H2 * 60)} is ${hrs(h)}.`,
      }),
      box({
        id: "after", label: "Past the hour", question: `From ${clock(H2 * 60)} to ${clock(end)}, how many minutes?`,
        prompt: x => [text(`${clock(H2 * 60)} to ${clock(end)} `), op("="), x, text(" min")], ans: m3,
        wrong: [
          [60 - m3, "Counted to the next hour", `Count from :00 up to :${String(m3).padStart(2, "0")}. That's ${count(m3, "minute")}.`],
          ...(m3 % 5 === 0 && m3 > 5 ? [[m3 / 5, "Counted the numbers, not the minutes", `The minute hand passes ${m3 / 5} numbers, but each number is 5 minutes. Count by 5s.`] as [number, string, string]] : []),
          [60 + m3, "Counted the hour too", `The hour is already counted. Only count the minutes after :00.`],
        ],
        hint: `The minute hand goes from :00 to :${String(m3).padStart(2, "0")}.`,
        explain: `${clock(H2 * 60)} to ${clock(end)} is ${count(m3, "minute")}.`,
      }),
      boxes({
        id: "total", label: "Put it together", question: `${hrs(h)}, and ${m1} + ${count(m3, "minute")}.${m1 + m3 >= 60 ? " Trade 60 minutes for 1 hour." : ""}`,
        prompt: b => [text("in all "), op("="), b.h!, text(" h "), b.m!, text(" min")] as MathText,
        ans: { h: th, m: tm },
        wrong: [
          ...(m1 + m3 >= 60 ? [
            [{ h, m: m1 + m3 }, "Kept 60 or more minutes", `${count(m1 + m3, "minute")} is more than an hour. Trade 60 of them for 1 more hour.`],
            [{ h, m: m1 + m3 - 60 }, "Lost the traded hour", `You traded 60 minutes for an hour. Add that hour to the ${hrs(h)}.`],
          ] as [Record<string, number>, string, string][] : []),
          [{ h, m: Math.abs(m3 - m1) }, "Subtracted the minutes", `Add the minutes before and after: ${m1} + ${m3}.`],
        ],
        hint: `Add the whole hours you found. Then add the minutes before the hour and the minutes after it.${m1 + m3 >= 60 ? " 60 minutes make 1 more hour." : ""}`,
        explain: `${hrs(h)}, and ${m1} + ${m3} = ${count(m1 + m3, "minute")}${m1 + m3 >= 60 ? `: trade 60 of them for 1 hour` : ""}. That's ${th} h ${tm} min.`,
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: ElapsedProblem, model: AnswerModel): Explanation {
  const { start, end } = p, { H1, H2 } = parts(p);
  const m1 = expectedOf(model, "to-hour"), h = expectedOf(model, "hours"), m3 = expectedOf(model, "after");
  const th = expectedOf(model, "total", "h"), tm = expectedOf(model, "total", "m");
  const totalText = `${hrs(th)}${tm ? ` ${tm} min` : ""}`;
  return {
    heading: "Jump to the hour",
    idea: ["Jump from the start to the next o'clock, then count whole hours, then the minutes left.", "An hour is 60 minutes."],
    statement: [text(`${clockAmPm(start)} to ${clockAmPm(end)}`)],
    diagram: buildTimeline({
      start, end, clock,
      stretches: [
        { from: start, to: H1 * 60, text: `${m1} min`, beat: 1, cls: "hl" },
        { from: H1 * 60, to: H2 * 60, text: `${h} h`, beat: 2, cls: "ln" },
        { from: H2 * 60, to: end, text: `${m3} min`, beat: 3, cls: "hl" },
      ],
      total: { text: `${totalText} in all`, beat: 4 },
      alt: `A timeline from ${clockAmPm(start)} to ${clockAmPm(end)}: ${count(m1, "minute")} to ${clock(H1 * 60)}, ${hrs(h)} to ${clock(H2 * 60)}, then ${count(m3, "minute")}. ${totalText} in all.`,
    }),
    caption: `From ${clockAmPm(start)} to ${clockAmPm(end)}`,
    timeline: beats(5),
    steps: [
      { id: "to-hour", state: 1, answerStep: "to-hour", result: m1, math: [text(`${clock(start)} → ${clock(H1 * 60)}: `), num(m1), text(" min")],
        narration: `First jump to the next o'clock: ${clock(start)} to ${clock(H1 * 60)} is ${count(m1, "minute")}.` },
      { id: "hours", state: 2, answerStep: "hours", result: h, math: [text(`${clock(H1 * 60)} → ${clock(H2 * 60)}: `), num(h), text(" h")],
        narration: `Then whole hours: ${clock(H1 * 60)} to ${clock(H2 * 60)} is ${hrs(h)}.${H1 <= 12 && H2 > 12 ? " After 12 comes 1." : ""}` },
      { id: "after", state: 3, answerStep: "after", result: m3, math: [text(`${clock(H2 * 60)} → ${clock(end)}: `), num(m3), text(" min")],
        narration: `Last, the minutes past the hour: ${clock(H2 * 60)} to ${clock(end)} is ${count(m3, "minute")}.` },
      { id: "total", state: 4, answerStep: "total", result: th, math: [num(th), text(" h "), num(tm), text(" min")],
        narration: m1 + m3 >= 60 ? `${m1} + ${m3} = ${count(m1 + m3, "minute")}, which is 1 hour and ${count(m1 + m3 - 60, "minute")}. In all: ${totalText}.` : `${hrs(h)} and ${m1} + ${m3} = ${count(m1 + m3, "minute")}. In all: ${totalText}.` },
    ],
  };
}

export const lesson: LessonDefinition<ElapsedProblem> = {
  id: "g3-elapsed",
  grade: 3,
  unit: "Measurement",
  title: "Elapsed time",
  pre: "g2-time5",
  reference: createElapsed(9 * 60 + 40, 11 * 60 + 15),
  generate: generateElapsed,
  restore: raw => restoreVia(raw, ["start", "end"] as const, v => createElapsed(v.start, v.end)),
  display: p => [text(`Start ${clockAmPm(p.start)}`), br(), text(`End ${clockAmPm(p.end)}`)],
  displayNote: () => "How much time goes by?",
  answers,
  explain,
};
