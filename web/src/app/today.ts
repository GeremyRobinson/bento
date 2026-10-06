// Today: a short plan picked for you, so opening Bento is one decision, not twenty. Usually a new lesson, a few
// review problems from what you've already done, and a unit test once a whole unit is finished. Nothing is stored;
// the plan is worked out from progress, so it's the same on every screen and resets each day.
import type { Progress } from "../engine/mastery/progress";
import { lastScore, timesDone } from "../engine/mastery/progress";
import { lessonById } from "../curriculum/registry";
import { entriesInGrade, isReady, testKey, unitsInGrade, type Entry } from "./curriculum";
import { tablesForGrade } from "../engine/facts/tables";
import { sprintDoneToday, sprintTableFor } from "../engine/facts/mastery";
import { TODAYS_REVIEW } from "./copy";

export type TodayItem =
  | { kind: "lesson"; id: string; title: string; again: boolean; done: boolean; minutes: number }
  | { kind: "review"; title: string; done: boolean; minutes: number }
  | { kind: "test"; key: string; unit: string; title: string; done: boolean; minutes: number }
  | { kind: "facts"; table: string; title: string; done: boolean; minutes: number };

const sameDay = (a: number, b: number) => new Date(a).toDateString() === new Date(b).toDateString();

/** The lesson the grade is up to: the first one not done yet, or, once all are done, the one scored lowest. */
export function upNext(progress: Progress, g: number): { entry: Entry; again: boolean } | null {
  const ready = entriesInGrade(g).filter(c => isReady(c.id));
  const fresh = ready.find(c => timesDone(progress, c.id) === 0);
  if (fresh) return { entry: fresh, again: false };
  const low = [...ready].sort((a, b) => (lastScore(progress, a.id) ?? 9) - (lastScore(progress, b.id) ?? 9))[0];
  return low ? { entry: low, again: true } : null;
}

export function todayPlan(progress: Progress, g: number, now: number, reviewReady: boolean): TodayItem[] {
  const today = progress.log.filter(e => sameDay(e.date, now));
  const items: TodayItem[] = [];

  // one lesson: the one finished today, or the one up next
  const learned = today.find(e => e.mode === "practice" && lessonById(e.key)?.grade === g);
  const next = upNext(progress, g);
  if (learned) items.push({ kind: "lesson", id: learned.key, title: learned.title, again: false, done: true, minutes: 8 });
  else if (next) items.push({ kind: "lesson", id: next.entry.id, title: next.entry.title, again: next.again, done: false, minutes: 8 });

  // a few problems from what's already been learned
  if (reviewReady) items.push({ kind: "review", title: TODAYS_REVIEW, done: progress.reviews[new Date(now).toDateString()] != null, minutes: 5 });

  // a two-minute fact sprint, on the table that most needs it
  const ft = sprintTableFor(progress.facts ?? {}, tablesForGrade(g), now);
  if (ft) {
    const doneToday = sprintDoneToday(progress.sprints ?? [], now);
    const last = doneToday ? [...(progress.sprints ?? [])].reverse().find(s => new Date(s.date).toDateString() === new Date(now).toDateString()) : undefined;
    items.push({ kind: "facts", table: last?.table ?? ft.id, title: (last ? tablesForGrade(g).find(t => t.id === last.table) ?? ft : ft).name, done: doneToday, minutes: 2 });
  }

  // a unit test, once every lesson of a unit is done and its test hasn't been passed
  const units = unitsInGrade(g);
  if (units.length > 1) {
    const tested = today.find(e => e.mode === "test" && e.key.startsWith(`unit:${g}:`));
    const due = units.find(u => u.entries.every(c => timesDone(progress, c.id) > 0) && (progress.tests[testKey(g, u.name)]?.last ?? 0) < 3);
    if (tested) items.push({ kind: "test", key: tested.key, unit: tested.key.split(":").slice(2).join(":"), title: tested.title, done: true, minutes: 6 });
    else if (due) items.push({ kind: "test", key: testKey(g, due.name), unit: due.name, title: `${due.name} test`, done: false, minutes: 6 });
  }
  return items;
}
