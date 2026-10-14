// What each lesson builds on, from Curriculum (v2-backend-plan.md, "From Curriculum"). A lesson listed here uses this
// list (it may name lessons from earlier grades; an empty list means it starts fresh); the first id is the main
// build-up. A lesson not listed falls back to the one build-up lesson the catalog names (`pre`). The skill model reads
// it to step back after a low check. Each grade's list is in v2/grade<N>.ts.
import { GRADES_V2 } from "./checks";

export const DEPENDS: Record<string, string[]> = Object.assign({}, ...GRADES_V2.map(g => g.depends));
