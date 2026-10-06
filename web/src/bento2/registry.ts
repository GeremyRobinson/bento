// Bento²'s registry: every track that lives at tracks/<name>/index.ts and exports `track` registers itself here, the
// same way regular lessons do (curriculum/registry.ts). Lessons are found by id across all tracks.
import type { AnyB2Lesson, B2Project, B2Track } from "./model";
import { isTrackLive } from "./flags";

const modules = import.meta.glob<{ track: B2Track }>("./tracks/*/index.ts", { eager: true });
export const B2_TRACKS: B2Track[] = Object.values(modules).map(m => m.track);

const BY_PICKER = new Map(B2_TRACKS.map(t => [t.pickerId, t]));
const LESSONS = new Map(B2_TRACKS.flatMap(t => t.lessons.map(l => [l.id, l] as const)));

export const trackByPickerId = (id: string): B2Track | undefined => BY_PICKER.get(id);
export const trackByCode = (code: string): B2Track | undefined => B2_TRACKS.find(t => t.code === code);
export const b2LessonById = (id: string): AnyB2Lesson | undefined => LESSONS.get(id);
export const trackOfLesson = (id: string): B2Track | undefined => trackByCode(id.split("-")[1] ?? "");
/** a track the picker can open: it has lessons, and the flag lists it */
export const isOpen = (pickerId: string) => !!BY_PICKER.get(pickerId)?.lessons.length && isTrackLive(pickerId);

export const lessonsInUnit = (t: B2Track, n: number) => t.lessons.filter(l => l.unit === n);
export const projectAfter = (t: B2Track, lessonId: string): B2Project | undefined => t.projects.find(p => p.after === lessonId);
/** every project that sits after a lesson, in the track's order (a small project, then the build) */
export const projectsAfter = (t: B2Track, lessonId: string): B2Project[] => t.projects.filter(p => p.after === lessonId);
export const projectById = (t: B2Track, id: string): B2Project | undefined => t.projects.find(p => p.id === id);
/** "b2-re-03" → "03" */
export const lessonNumber = (id: string) => id.split("-")[2] ?? "";
