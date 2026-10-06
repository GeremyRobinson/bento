// Small builders for Work it's steps, so a lesson reads like its spec block: label, what's typed, slips.
import type { B2Slip, B2Step } from "./model";
import { formatAnswer, liveSlips } from "./steps";

/** "1 year", "3 years": a word unit agrees with its number */
export const unitFor = (n: number, unit: string) => (Math.abs(n) === 1 && /^(years|light-years|days|seconds)$/.test(unit) ? unit.slice(0, -1) : unit);

type Common = { ask?: string; unit?: string; boxes?: string[]; hint: string; done?: string; slips?: (B2Slip | null | false)[] };
const finish = (s: Omit<B2Step, "slips" | "done"> & { slips?: (B2Slip | null | false)[]; done?: string }): B2Step =>
  liveSlips({ ...s, slips: (s.slips ?? []).filter((x): x is B2Slip => !!x), done: s.done ?? `${s.label}: ${s.answer.map(a => formatAnswer(a, s.form)).join(", ")}${s.unit ? ` ${unitFor(s.answer[0]!, s.unit)}` : ""}` });

/** A number typed to `places` decimal places (accepted within one unit of the last place). */
export const numStep = (id: string, label: string, answer: number, places: number, c: Common): B2Step =>
  finish({ id, label, form: places, answer: [answer], ...c });
export const wholeStep = (id: string, label: string, answer: number, c: Common): B2Step =>
  finish({ id, label, form: "whole", answer: [answer], ...c });
/** A fraction (any equal form is accepted: 10/8, 5/4 or 1.25). */
export const fracStep = (id: string, label: string, answer: number, c: Common): B2Step =>
  finish({ id, label, form: "fraction", answer: [answer], ...c });
/** Several boxes in one step ("γ and βγ"). */
export const multiStep = (id: string, label: string, answers: number[], form: B2Step["form"], c: Common & { boxes: string[] }): B2Step =>
  finish({ id, label, form, answer: answers, ...c });
/** A tap step: the right choice's index. */
export const tapStep = (id: string, label: string, choices: string[], right: number, c: Common): B2Step =>
  finish({ id, label, form: "whole", answer: [right], choices, ...c, done: c.done ?? `${label}: ${choices[right]}` });

export const slip = (kind: string, values: number | number[], message: string): B2Slip => ({ kind, values: Array.isArray(values) ? values : [values], message });
