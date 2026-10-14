// What the child has shown they know (v2-backend-plan.md). Finishing a lesson only means they got through it with
// help; the skill check at the end (a few problems, no hints, one try per step) says "learned". A learned lesson comes
// back for a quick check after 3, 7, 21 and then 60 days, each pass pushing it further out; a miss brings it back
// tomorrow. Plain rules a parent could follow, all worked out from what's saved on this device.
import { CATALOG } from "../../curriculum/catalog";
import { DEPENDS } from "../../curriculum/depends";
import type { Level } from "./levels";
import type { Progress } from "./progress";

export interface CheckRecord {
  last: Level;
  best: Level;
  /** when the last check (or the review that counted as one) was done */
  date: number;
  /** when it should come back */
  due: number;
  /** checks passed in a row: picks the next gap */
  passes: number;
}

/** problems in a skill check, until a lesson's own check says otherwise */
export const CHECK_LENGTH = 4;
/** the run index the check's problems start at: lessons make their first problems easier */
export const CHECK_FROM = 4;
/** a check of 3 or 4 means learned */
export const PASS: Level = 3;
/** days until a passed lesson comes back, by how many passes in a row */
export const REVIEW_DAYS = [3, 7, 21, 60] as const;
const DAY = 864e5;

export const checkKey = (g: number, id: string) => `check:${g}:${id}`;
export const isCheckKey = (key: string) => key.startsWith("check:");
export const lessonOfCheck = (key: string) => key.split(":").slice(2).join(":");

/** a check's (or a counted review's) result, and when the lesson comes back */
export function recordCheck(old: CheckRecord | undefined, level: Level, now: number): CheckRecord {
  const passed = level >= PASS, passes = passed ? (old?.passes ?? 0) + 1 : 0;
  const days = passed ? REVIEW_DAYS[Math.min(passes, REVIEW_DAYS.length) - 1]! : 1;
  return { last: level, best: Math.max(level, old?.best ?? 0) as Level, date: now, due: now + days * DAY, passes };
}

/** Learned: the last check was 3 or 4. Practice alone never counts ("completing all parts ≠ learned"). */
export const learned = (p: Progress, id: string) => (p.checks?.[id]?.last ?? -1) >= PASS;
/** learned as the child sees it (UI model v61): the last check scored 3 or 4 and it isn't slipping (not due back yet) */
export const learnedNow = (p: Progress, id: string, now: number) => learned(p, id) && !dueBack(p, id, now);

/**
 * Saves from before checks existed: a practice score of 3 or 4 becomes the lesson's check, once, when the save is
 * loaded, so no one's ring goes back to zero; from then on only checks count (Review, engine-453ec4b R1).
 */
export function checksFromScores(scores: Progress["scores"]): Record<string, CheckRecord> {
  return Object.fromEntries(Object.entries(scores).filter(([, s]) => s.last >= PASS)
    .map(([id, s]) => [id, { last: s.last, best: s.best, date: s.date, due: s.date + REVIEW_DAYS[0] * DAY, passes: 1 }]));
}

/** A miss in the mixed review: one slip is weak evidence, so the lesson stays learned but comes back tomorrow and
 *  starts its gaps again; its next real check decides (Review R13). */
export const reviewMissed = (c: CheckRecord, now: number): CheckRecord => ({ ...c, due: now + DAY, passes: 0 });

/** the last check came back low: the lesson is to go over */
export const toGoOver = (p: Progress, id: string) => { const c = p.checks?.[id]; return !!c && c.last < PASS; };

/** learned, and its time to come back has come */
export const dueBack = (p: Progress, id: string, now: number) => { const c = p.checks?.[id]; return !!c && c.last >= PASS && c.due <= now; };

/** the lessons this one builds on: Curriculum's list, else the one build-up lesson the catalog names */
export function dependsOn(id: string): string[] {
  if (DEPENDS[id]) return DEPENDS[id]!;
  const pre = CATALOG.find(c => c.id === id)?.pre;
  return pre ? [pre] : [];
}

const gradeOf = (id: string) => CATALOG.find(c => c.id === id)?.grade;

/**
 * Step back: after a check of 0 or 1, the main lesson underneath when it isn't learned (tried or not: that's the gap
 * a low check points to), else any lesson underneath whose own check came back low. A lesson further down the list
 * that was simply never tried isn't a reason to go further back (Review R4).
 */
export function stepBack(p: Progress, id: string): string | null {
  const c = p.checks?.[id];
  if (!c || c.last > 1) return null;
  const [main, ...rest] = dependsOn(id);
  if (main && !learned(p, main)) return main;
  return rest.find(d => toGoOver(p, d)) ?? null;
}

/**
 * Ready to start: every lesson underneath is learned. A lesson from an earlier grade counts as learned until one of
 * its checks comes back low, so a child who starts in 5th grade isn't sent back to 4th (Curriculum, Review 2026-10-13).
 */
export function ready(p: Progress, id: string): boolean {
  const g = gradeOf(id) ?? 0;
  return dependsOn(id).every(d => ((gradeOf(d) ?? g) < g ? !toGoOver(p, d) : learned(p, d)));
}

/** lessons learned out of the ones given: the one number every ring and box shows */
export function ringOf(p: Progress, ids: readonly string[]): { learned: number; total: number; pct: number } {
  const n = ids.filter(id => learned(p, id)).length;
  return { learned: n, total: ids.length, pct: ids.length ? n / ids.length : 0 };
}
