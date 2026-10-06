// What the screens list: every lesson of the current app (the catalog), whether or not its module is rebuilt yet.
// Scores carried over from the current app belong to catalog ids, so lists, counts and averages use the catalog;
// only rebuilt lessons can be opened.
import { CATALOG, type CatalogEntry } from "../curriculum/catalog";
import { lessonById } from "../curriculum/registry";
import { lastScore, timesDone, type Progress } from "../engine/mastery/progress";
import { backFor, testKey } from "../engine/session/practice";
import { NO_UNIT } from "./copy";

export type Entry = CatalogEntry;

export const entriesInGrade = (g: number): Entry[] => CATALOG.filter(c => c.grade === g);
export const entryById = (id: string): Entry | undefined => CATALOG.find(c => c.id === id);
export const isReady = (id: string) => !!lessonById(id);
export const titleOf = (id: string) => lessonById(id)?.title ?? entryById(id)?.title ?? id;

export function unitsInGrade(g: number): { name: string; entries: Entry[] }[] {
  const out: { name: string; entries: Entry[] }[] = [];
  for (const c of entriesInGrade(g)) {
    const name = c.unit || NO_UNIT;
    let u = out.find(o => o.name === name);
    if (!u) out.push((u = { name, entries: [] }));
    u.entries.push(c);
  }
  return out;
}

/** Average of the last scores in a grade, or null when nothing is scored yet (the current app's gradeLevel). */
export function gradeAverage(p: Progress, g: number): number | null {
  const s: number[] = entriesInGrade(g).flatMap(c => { const v = lastScore(p, c.id); return v == null ? [] : [v]; });
  return s.length ? s.reduce((a, b) => a + b, 0) / s.length : null;
}

export const doneCount = (p: Progress, entries: Entry[]) => entries.filter(c => timesDone(p, c.id) > 0).length;

/**
 * "Build up first": the engine's backFor rule (the lesson's `pre`, else the lesson before it in the same unit),
 * read over the whole catalog so the suggestion is the current app's even while that lesson is being rebuilt.
 */
export function buildUpFor(id: string): Entry | null {
  const ported = backFor(id);
  const c = entryById(id);
  if (!c) return ported ? entryById(ported.id) ?? null : null;
  if (c.pre && entryById(c.pre)) return entryById(c.pre)!;
  const g = entriesInGrade(c.grade), k = g.indexOf(c);
  return k > 0 && g[k - 1]!.unit === c.unit ? g[k - 1]! : ported ? entryById(ported.id) ?? null : null;
}

/** A unit test or grade check-up can start once at least one of its lessons is rebuilt. */
export const testReady = (g: number, unit?: string) =>
  entriesInGrade(g).some(c => (!unit || (c.unit || NO_UNIT) === unit) && isReady(c.id));

export { testKey };
