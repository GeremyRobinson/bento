// Time to 5 minutes: read the hour from the short hand, then count by 5s to the long hand.
import { num, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildClock } from "../../../../explanations/diagrams/early-g2/measure";
import { expectedOf, manyBoxes, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { slips } from "../kit";
import { count } from "../../../text";

/** A time on the clock: hour 1 to 12, minutes in fives. */
export interface TimeProblem { h: number; m: number }

export function createTime(h: number, m: number): TimeProblem {
  wholeIn("h", h, 1, 12);
  wholeIn("m", m, 0, 55);
  if (m % 5) throw new Error("minutes come in fives");
  return { h, m };
}

/** Early problems keep the long hand between 1 and 6; later ones go all the way round. */
const generate = (rng: Rng, index: number) => createTime(rng.int(1, 12), 5 * (index < 3 ? rng.int(1, 6) : rng.int(0, 11)));

const two = (m: number) => String(m).padStart(2, "0");
/** the number the long hand points to (12 on the hour) */
const numberOf = (m: number) => m / 5 || 12;

function answers({ h, m }: TimeProblem): AnswerModel {
  const K = numberOf(m), next = (h % 12) + 1;
  const same = (v: Record<string, number>) => v.h === h && v.m === m;
  return {
    steps: [
      oneBox({
        id: "hour", label: "Read the hour hand",
        question: m ? "The short hand shows the hour. Which number has it just passed?" : "The short hand shows the hour. Which number does it point to?",
        prompt: s => [text("Hour: "), s], ans: h,
        wrong: slips(h, [
          m > 0 && [next, "Read the next hour", `The short hand is past ${h} but has not reached ${next} yet, so the hour is still ${h}.`],
          [K, "Read the long hand", "That's the long hand. The hour hand is the short one."],
        ]),
        hint: m ? "Find the short hand. Use the number it has just gone past." : "Find the short hand and read its number.",
        explain: m ? `The short hand is between ${h} and ${next}, so the hour is ${h}.` : `The short hand points to ${h}.`,
      }),
      oneBox({
        id: "number", label: "Find the long hand", question: "Which number does the long hand point to?",
        prompt: s => [text("The long hand points to "), s], ans: K,
        wrong: slips(K, [
          [h, "Read the short hand", "That's the short hand. Now look at the long hand."],
          [m, "Jumped ahead to the minutes", `That's the minutes. First just find the number the long hand is on.`],
        ]),
        hint: "Follow the long hand out to the edge of the clock.",
        explain: `The long hand points to ${K}.`,
      }),
      oneBox({
        id: "minutes", label: "Count by 5s",
        question: m ? `Each number is 5 minutes. Count by 5s up to ${K}.` : "The long hand is on 12. How many minutes past the hour is that?",
        prompt: s => [text("Minutes: "), s], ans: m,
        wrong: slips(m, [
          m ? [K, "Read the number as the minutes", `The long hand points to ${K}, but each number means 5 minutes. Count by 5s: 5, 10, 15 and on.`]
            : [12, "Read 12 as 12 minutes", "When the long hand points to 12, the hour has just started: 0 minutes."],
          !m && [60, "Counted a whole hour", "At 12 the minutes start again from 0."],
          m > 0 && [m + 5, "One five too many", `Count one 5 for each number up to ${K}, and stop there.`],
          m > 5 && [m - 5, "One five too few", `Count one 5 for each number, all the way to ${K}.`],
        ]),
        hint: m ? `Put your finger on 12. Count by 5s, one count for each number, until you reach ${K}.` : "On 12, no minutes have gone by yet.",
        explain: m ? `${Array.from({ length: K }, (_, i) => 5 * (i + 1)).join(", ")}. That's ${count(m, "minute")}.` : "On 12 it is 0 minutes past the hour.",
      }),
      manyBoxes({
        id: "time", label: "Write the time", question: "Put the hour and the minutes together.",
        prompt: b => [b.h!, text(m < 10 ? ":0" : ":"), b.m!], ans: { h, m },
        wrong: ([
          [{ h: next, m }, "Read the next hour", `The short hand has not reached ${next} yet, so the hour is ${h}.`],
          [{ h, m: K }, "Read the number as the minutes", `The long hand on ${K} means ${count(m, "minute")}.`],
          [{ h: K, m: (h % 12) * 5 }, "Swapped the hands", "The short hand gives the hour and the long hand gives the minutes."],
        ] as [Record<string, number>, string, string][]).filter(([v]) => !same(v)),
        hint: "The hour from the short hand goes first, then the minutes you counted.",
        explain: `Hour first, then minutes: ${h}:${m < 10 ? "0" : ""}${m}.`,
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: TimeProblem, model: AnswerModel): Explanation {
  const h = expectedOf(model, "hour"), K = expectedOf(model, "number"), m = expectedOf(model, "minutes");
  const shown = `${expectedOf(model, "time", "h")}:${two(expectedOf(model, "time", "m"))}`;
  return {
    heading: "Read the clock",
    idea: ["The long hand moves 5 minutes from one number to the next."],
    statement: [text("What time is it?")],
    diagram: buildClock({
      hour: p.h, minute: p.m, beats: { hour: 1, number: 2, count: 3, time: 4 },
      text: { hour: `hour: ${h}`, number: `long hand on ${K}`, count: `${count(m, "minute")}`, time: shown },
      alt: `A clock. The short hand is ${m ? `just past ${h}` : `on ${h}`} and the long hand is on ${K}, which is ${count(m, "minute")}. The time is ${shown}.`,
    }),
    caption: "Short hand: hours. Long hand: minutes.",
    timeline: beats(5),
    steps: [
      { id: "hour", narration: m ? `The short hand has passed ${h} but not reached the next number. The hour is ${h}.` : `The short hand points right at ${h}.`, math: [text("Hour: "), num(h)], state: 1, answerStep: "hour", result: h },
      { id: "number", narration: `The long hand points to ${K}.`, math: [text("Long hand: "), num(K)], state: 2, answerStep: "number", result: K },
      { id: "minutes", narration: m ? `Count by 5s up to ${K}: ${Array.from({ length: K }, (_, i) => 5 * (i + 1)).join(", ")}. That's ${count(m, "minute")}.` : "On 12 it is 0 minutes past the hour, so it is o'clock.", math: [text("Minutes: "), num(m)], state: 3, answerStep: "minutes", result: m },
      { id: "time", narration: `The time is **${shown}**.`, math: [text(shown)], state: 4, answerStep: "time", result: h },
    ],
  };
}

export const lesson: LessonDefinition<TimeProblem> = {
  id: "g2-time5",
  grade: 2,
  unit: "Measurement and data",
  title: "Time to 5 minutes",
  pre: "g1-time",
  reference: createTime(3, 25),
  generate,
  restore: raw => restoreVia(raw, ["h", "m"] as const, v => createTime(v.h, v.m)),
  display: () => [text("What time is it?")],
  picture: p => buildClock({
    hour: p.h, minute: p.m, beats: { hour: 1, number: 1, count: 1, time: 1 }, text: { hour: "", number: "", count: "", time: "" }, bare: true,
    alt: "A clock with an hour hand and a minute hand.",
  }),
  answers,
  explain,
};
