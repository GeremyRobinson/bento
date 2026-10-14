// How far along: lessons learned out of lessons, per chapter and per grade (v2-backend-plan.md, "Progress and rings").
// The box, the island ring and the grade list all read these, so they always agree. Learned means a skill check of
// 3 or 4 (engine/mastery/skills.ts); finishing a lesson's practice alone doesn't fill the ring.
import type { Progress } from "../engine/mastery/progress";
import { ringOf } from "../engine/mastery/skills";
import { entriesInGrade, unitsInGrade } from "./curriculum";

export type Ring = ReturnType<typeof ringOf>;

export const gradeRing = (p: Progress, g: number): Ring => ringOf(p, entriesInGrade(g).map(c => c.id));

export function chapterRings(p: Progress, g: number): { name: string; ring: Ring }[] {
  return unitsInGrade(g).map(u => ({ name: u.name, ring: ringOf(p, u.entries.map(c => c.id)) }));
}

/** how many of these lessons are learned (their skill check is 3 or 4): the count every progress ring shows */
export const learnedCount = (p: Progress, entries: readonly { id: string }[]): number => ringOf(p, entries.map(c => c.id)).learned;

/** how many of these lessons have had their skill check, whatever it scored: the model's "8 of 17 done" (UI model v57) */
export const checkedCount = (p: Progress, entries: readonly { id: string }[]): number => entries.filter(c => !!p.checks?.[c.id]).length;
