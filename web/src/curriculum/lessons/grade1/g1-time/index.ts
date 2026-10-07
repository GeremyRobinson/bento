// Time to the hour and half hour: the short hand tells the hour, the long hand tells the minutes.
import { answer, num, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildClock } from "../../../../explanations/diagrams/early-g1/clock";
import { expectedOf, manyBoxes, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { slips, slipsMany, type Slip, type SlipMany } from "../_kit";
import { count } from "../../../text";

const HALF = 30;
/** the clock number the long hand points at for these minutes (12 for o'clock, 6 for half past) */
const minuteNumber = (m: number) => (m === 0 ? 12 : m / 5);
const twoDigits = (m: number) => (m < 10 ? `0${m}` : String(m));
export const timeText = (h: number, m: number) => `${h}:${twoDigits(m)}`;

/** a time on the hour (minute 0) or half past (minute 30) */
export interface TimeProblem { hour: number; minute: number }

export function createTime(hour: number, minute: number): TimeProblem {
  wholeIn("hour", hour, 1, 12);
  if (minute !== 0 && minute !== HALF) throw new Error("minute must be 0 or 30");
  return { hour, minute };
}

function answers({ hour, minute }: TimeProblem): AnswerModel {
  const next = (hour % 12) + 1, longAt = minuteNumber(minute), half = minute === HALF;
  const timeWork: MathText = [answer("h", hour), text(":"), text(twoDigits(minute))];
  const time = manyBoxes({
    id: "time", label: "Write the time", prompt: x => [x.h!, text(" : "), x.m!],
    ans: { h: hour, m: minute },
    wrong: slipsMany({ h: hour, m: minute }, [
      [{ h: hour, m: longAt }, "Wrote the number, not the minutes", `The long hand points at ${longAt}, but that means ${count(minute, "minute")}.`],
      [{ h: longAt, m: minute }, "Mixed up the hands", "The **short** hand tells the hour. The long hand tells the minutes."],
      ...(half ? [[{ h: next, m: minute }, "Read the next hour", `The short hand hasn't reached ${next} yet. It's still ${hour}.`] as SlipMany] : []),
    ]),
    hint: "Hour in the first box, minutes in the second.",
  });
  return {
    steps: [
      oneBox({
        id: "hour", label: "Read the short hand", question: half ? "The short hand is between two numbers. Which one has it passed?" : "Which number does the short hand point at?",
        prompt: s => [text("Hour: "), s], ans: hour,
        wrong: slips(hour, [
          [longAt, "Read the long hand", `That's the long hand. The **short** hand tells the hour.`],
          ...(half ? [[next, "Read the next number", `The short hand is on its way to ${next} but hasn't got there. It's still ${hour}.`] as Slip] : []),
        ]),
        hint: half ? `Halfway between two numbers, the hour is the smaller one it just passed.` : "Find the short, thick hand. Which number is it on?",
        explain: half ? `The short hand is halfway between ${hour} and ${next}. It has passed ${hour}, so the hour is ${hour}.` : `The short hand points at ${hour}.`,
      }),
      oneBox({
        id: "minute", label: "Read the long hand", question: `The long hand points at ${longAt}. How many minutes is that?`,
        prompt: s => [text("Minutes: "), s], ans: minute,
        wrong: slips(minute, [
          [longAt, "Wrote the number, not the minutes", half
            ? `The long hand at ${longAt} is halfway around the clock. Halfway is ${count(HALF, "minute")}.`
            : `The long hand at 12 means a new hour is just starting: 0 minutes.`],
          [60, "Counted a whole hour", half
            ? `A whole hour is 60 minutes, but the long hand has only gone halfway around: ${count(HALF, "minute")}.`
            : "The long hand at the top means the hour is just starting: 0 minutes."],
          [hour, "Read the short hand", "That's the short hand. The **long** hand tells the minutes."],
        ]),
        hint: half ? "The long hand has gone halfway around. An hour is 60 minutes: what is half of that?" : "Long hand at the top, on 12, means 0 minutes: o'clock.",
        explain: half ? `The long hand at ${longAt} is halfway around: ${count(HALF, "minute")}.` : "The long hand at 12 means 0 minutes.",
      }),
      { ...time, explain: `${count(hour, "hour")}${half ? ` and ${count(minute, "minute")}` : ""} is written ${timeText(hour, minute)}.`, work: timeWork },
    ],
    finalParts: [-1],
  };
}

function explain({ hour, minute }: TimeProblem, model: AnswerModel): Explanation {
  const h = expectedOf(model, "hour"), m = expectedOf(model, "minute"), half = m === HALF, next = (h % 12) + 1, shown = timeText(h, m);
  return {
    heading: "Read the clock",
    idea: ["The short hand tells the hour. The long hand tells the minutes. Long hand on 12 means o'clock, on 6 means half past."],
    statement: [text("What time is it?")],
    diagram: buildClock({
      hour, minute,
      beats: { hour: 0, minute: 1, time: 2 },
      text: { hour: half ? `short hand: past ${h}` : `short hand: ${h}`, minute: `long hand: ${count(m, "minute")}`, time: shown },
      alt: `A clock with the short hand ${half ? `between ${h} and ${next}` : `on ${h}`} and the long hand on ${minuteNumber(m)}: ${shown}.`,
    }),
    caption: half ? `Half past ${h} is ${shown}.` : `${h} o'clock is ${shown}.`,
    timeline: beats(3),
    steps: [
      { id: "hour", narration: half ? `The short hand is halfway between ${h} and ${next}. It has passed **${h}**, so the hour is ${h}.` : `The short hand points right at **${h}**.`, math: [text("Hour: "), num(h)], state: 0, answerStep: "hour", result: h },
      { id: "minute", narration: half ? `The long hand has gone halfway around, to 6. That's **${m}** minutes.` : `The long hand is at the top, on 12. That's **${m}** minutes.`, math: [text("Minutes: "), num(m)], state: 1, answerStep: "minute", result: m },
      { id: "time", narration: half ? `${count(h, "hour")} and ${count(m, "minute")}: **${shown}**, half past ${h}.` : `${count(h, "hour")} and no minutes: **${shown}**, ${h} o'clock.`, math: [num(h), text(`:${twoDigits(m)}`)], state: 2, answerStep: "time", result: h },
    ],
  };
}

export const lesson: LessonDefinition<TimeProblem> = {
  id: "g1-time",
  grade: 1,
  unit: "Measurement and shapes",
  title: "Time to the hour and half hour",
  reference: createTime(8, 30),
  generate: (rng, index) => createTime(rng.int(1, 12), index === 1 ? 0 : rng.pick([0, HALF])),
  restore: raw => restoreVia(raw, ["hour", "minute"] as const, v => createTime(v.hour, v.minute)),
  display: () => [text("What time is it?")],
  picture: p => buildClock({ hour: p.hour, minute: p.minute, alt: "A clock face with a short hour hand and a long minute hand" }),
  answers,
  explain,
};
