// "For the grown-up": everything on the page, worked out from this device's saved history and nothing else.
import { lessonById } from "../curriculum/registry";
import { text, type MathText } from "../curriculum/schemas/math-text";
import type { Explanation } from "../explanations/schema";
import type { Progress } from "../engine/mastery/progress";
import type { Level } from "../engine/mastery/levels";
import type { Mistake, ProblemRecord, SessionReport } from "../engine/session/types";
import { titleOf, unitsInGrade } from "./curriculum";
import { checkScore, isCheckKey, lessonOfCheck, PASS } from "../engine/mastery/skills";

/** Monday 00:00 of the week `now` falls in, and the Monday after (local time). */
export function weekOf(now: number): { from: number; to: number } {
  const d = new Date(now);
  d.setHours(0, 0, 0, 0);
  d.setDate(d.getDate() - ((d.getDay() + 6) % 7));
  const from = d.getTime(), e = new Date(from);
  e.setDate(e.getDate() + 7);
  return { from, to: e.getTime() };
}

export interface WeekStats {
  /** time in the runs saved this week */
  ms: number;
  /** some runs this week were overwritten by a later run of the same lesson, so their time is not known */
  atLeast: boolean;
  /** lessons finished this week (a lesson done twice counts twice) */
  lessons: number;
}

/** This week's time and lessons: time from the saved reports, lessons from the log. */
export function weekStats(p: Progress, reports: Record<string, SessionReport>, now: number): WeekStats {
  const { from, to } = weekOf(now), inWeek = (t: number) => t >= from && t < to;
  const reps = Object.values(reports).filter(r => inWeek(r.date));
  const runs = p.log.filter(e => inWeek(e.date));
  return {
    ms: reps.reduce((a, r) => a + Math.max(0, r.ms || 0), 0),
    atLeast: runs.length > reps.length,
    lessons: runs.filter(e => e.mode === "practice").length,
  };
}

/** "2h 15m", "35m", "under 1m" */
export function timeParts(ms: number): { n: number; u: string }[] {
  const m = Math.round(ms / 60000);
  if (m < 1) return [{ n: 0, u: "m" }];
  const h = Math.floor(m / 60);
  return h ? [{ n: h, u: "h" }, ...(m % 60 ? [{ n: m % 60, u: "m" }] : [])] : [{ n: m, u: "m" }];
}

export interface ChapterScore {
  name: string;
  /** the average of its lessons' latest scores, rounded down; null before any lesson in it is scored */
  score: Level | null;
  lessons: { id: string; title: string; score: Level }[];
}

/** Every chapter of the grade, scored from its lessons' latest scores. */
export function chapterScores(p: Progress, g: number): ChapterScore[] {
  return unitsInGrade(g).map(u => {
    const lessons = u.entries.flatMap(c => { const s = checkScore(p, c.id); return s == null ? [] : [{ id: c.id, title: c.title, score: s }]; });
    const score = lessons.length ? (Math.floor(lessons.reduce((a, l) => a + l.score, 0) / lessons.length) as Level) : null;
    return { name: u.name, score, lessons };
  });
}

export interface Pattern {
  id: string;
  kind: string;
  lessonId: string;
  lesson: string;
  /** problems of this lesson with this mistake, in the saved runs */
  wrong: number;
  /** problems of this lesson in the same saved runs */
  tries: number;
  /** how many saved runs those problems come from */
  runs: number;
  /** the latest time it happened */
  report: SessionReport;
  mistake: Mistake;
}

/**
 * Mistake patterns: one per lesson and kind of mistake, from the saved runs (each lesson keeps its latest run, plus
 * the latest test and review). Most problems wrong first.
 */
export function mistakePatterns(reports: Record<string, SessionReport>): Pattern[] {
  const byId = new Map<string, { kind: string; lessonId: string; probs: Set<string>; report: SessionReport; mistake: Mistake }>();
  const newest = Object.values(reports).sort((a, b) => b.date - a.date);
  for (const r of newest) {
    for (const m of r.mistakes ?? []) {
      const id = `${m.lessonId}~${m.kind}`;
      let p = byId.get(id);
      if (!p) byId.set(id, (p = { kind: m.kind, lessonId: m.lessonId, probs: new Set(), report: r, mistake: m }));
      p.probs.add(`${r.key}#${m.n}`);
    }
  }
  return [...byId.entries()].map(([id, p]) => {
    const with_ = newest.filter(r => r.probs?.some(x => x.lessonId === p.lessonId));
    const tries = with_.reduce((a, r) => a + r.probs.filter(x => x.lessonId === p.lessonId).length, 0);
    return { id, kind: p.kind, lessonId: p.lessonId, lesson: titleOf(p.lessonId), wrong: p.probs.size, tries: Math.max(tries, p.probs.size),
      runs: with_.length, report: p.report, mistake: p.mistake };
  }).sort((a, b) => b.wrong - a.wrong || b.wrong / b.tries - a.wrong / a.tries || b.report.date - a.report.date);
}

export interface StepView {
  n: number;
  label: string;
  /** what they did first: right, wrong (with what they typed), or filled in by Show me */
  their: { state: "ok" | "wrong" | "shown"; typed?: string; math?: MathText };
  right: MathText;
  /** the step the pattern is about */
  picked: boolean;
}

export interface WorkedExample {
  statement: MathText;
  steps: StepView[];
  /** the picked mistake's step, from 1 */
  step: number;
  mistake: Mistake;
  explanation: Explanation | null;
}

/**
 * The problem the mistake happened on, their first try at each step beside the right step. The app has them fix a
 * wrong step before going on, so every step after it is their own corrected work, not a knock-on mistake.
 * Shows at most three steps, around the wrong one. Null when the saved problem can't be read back.
 */
export function workedExample(pat: Pattern): WorkedExample | null {
  const { report, mistake: m } = pat;
  const lesson = lessonById(m.lessonId), pr: ProblemRecord | undefined = report.probs?.[m.n - 1];
  if (!lesson || !pr || pr.lessonId !== m.lessonId) return null;
  let problem: unknown, model;
  try {
    problem = lesson.restore(pr.problem);
    if (problem == null) return null;
    model = lesson.answers(problem);
  } catch { return null; }
  let explanation: Explanation | null = null;
  try { explanation = lesson.explain(problem, model); } catch { /* no picture */ }
  const statement = lesson.display(problem);
  const steps = model.steps, offset = pr.story && lesson.story ? 1 : 0;
  let k = m.step - 1 - offset;
  if (steps[k]?.label !== m.label) k = steps.findIndex(s => s.label === m.label);
  const same = report.mistakes.filter(x => x.n === m.n);
  if (k < 0 || !pr.work?.length) {
    // a whole-answer or planning step, or no saved work: only their answer beside the right one
    return { statement, step: m.step, mistake: m, explanation,
      steps: [{ n: m.step, label: m.label, their: { state: "wrong", typed: m.typed }, right: k < 0 ? [text(m.want)] : steps[k]!.work, picked: true }] };
  }
  const start = steps.length <= 3 ? 0 : Math.max(0, Math.min(k - 1, steps.length - 3));
  const view = steps.slice(start, start + 3).map((s, i): StepView => {
    const j = start + i, miss = j === k ? m : same.find(x => x.label === s.label), line = pr.work?.[offset + j];
    const their: StepView["their"] = miss ? { state: "wrong", typed: miss.typed } : line?.shown ? { state: "shown", math: s.work } : { state: "ok", math: line?.math ?? s.work };
    return { n: j + 1, label: s.label, their, right: s.work, picked: j === k };
  });
  return { statement, steps: view, step: k + 1, mistake: m, explanation };
}

export interface HintSummary {
  total: number;
  sessions: number;
  shown: number;
  rushed: number;
  rows: { title: string; count: number }[];
}

/** Hints, Show me and quick retries over every saved session, and the lessons where hints went. */
export function hintSummary(p: Progress): HintSummary {
  const by = new Map<string, number>();
  for (const e of p.log) if (e.hints) by.set(e.title, (by.get(e.title) ?? 0) + e.hints);
  return {
    total: p.log.reduce((a, e) => a + (e.hints || 0), 0),
    sessions: p.log.length,
    shown: p.log.reduce((a, e) => a + (e.shown || 0), 0),
    rushed: p.log.reduce((a, e) => a + (e.rushed || 0), 0),
    rows: [...by.entries()].sort((a, b) => b[1] - a[1]).slice(0, 3).map(([title, count]) => ({ title, count })),
  };
}

/** Anything saved at all: a finished run, a score, or a report. */
export const hasHistory = (p: Progress, reports: Record<string, SessionReport>) =>
  p.log.length > 0 || Object.keys(p.scores).length > 0 || Object.keys(reports).length > 0;

/** the oldest saved session, for "since" */
export const firstDate = (p: Progress) => (p.log.length ? Math.min(...p.log.map(e => e.date)) : null);

export interface WeekRow {
  /** Monday 00:00 */
  from: number;
  /** whole minutes on runs that week */
  min: number;
  /** days with at least one run */
  days: number;
  /** lessons whose skill check passed that week */
  learned: string[];
  /** lessons practised that week without a passed check yet */
  working: string[];
}

/**
 * The last `n` weeks, oldest first, the current week last. Time comes from each run's own time, or for older saves
 * from the run's report when it is still kept.
 */
export function weekRows(p: Progress, reports: Record<string, SessionReport>, now: number, n = 6): WeekRow[] {
  const byDate = new Map(Object.values(reports).map(r => [r.date, r.ms]));
  const rows: WeekRow[] = [], day = 864e5;
  for (let i = n - 1; i >= 0; i--) {
    const { from, to } = weekOf(now - i * 7 * day);
    const runs = p.log.filter(e => e.date >= from && e.date < to);
    const ms = runs.reduce((a, e) => a + Math.max(0, e.ms ?? byDate.get(e.date) ?? 0), 0);
    const days = new Set(runs.map(e => new Date(e.date).toDateString())).size;
    const learned = [...new Set(runs.filter(e => isCheckKey(e.key) && e.level >= PASS).map(e => titleOf(lessonOfCheck(e.key))))];
    const working = [...new Set(runs.filter(e => e.mode === "practice" && !learned.includes(e.title)).map(e => e.title))];
    rows.push({ from, min: Math.round(ms / 60000), days, learned, working });
  }
  return rows;
}

/** a usual week: the average of the earlier weeks with any time in them, to the nearest 5 minutes; null before there are any */
export function usualWeek(rows: WeekRow[]): { min: number; days: [number, number] } | null {
  const past = rows.slice(0, -1).filter(r => r.min > 0);
  if (!past.length) return null;
  const min = Math.max(5, Math.round(past.reduce((a, r) => a + r.min, 0) / past.length / 5) * 5);
  const d = past.map(r => r.days);
  return { min, days: [Math.min(...d), Math.max(...d)] };
}

/** learned lessons whose next check is still ahead, soonest first */
export function checksAhead(p: Progress, now: number): { id: string; title: string; due: number }[] {
  return Object.entries(p.checks ?? {}).filter(([, c]) => c.last >= PASS && c.due > now)
    .sort((a, b) => a[1].due - b[1].due).map(([id, c]) => ({ id, title: titleOf(id), due: c.due }));
}
