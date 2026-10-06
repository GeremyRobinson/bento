import { lessonsInGrade } from "../curriculum/registry";
import type { AnyLesson } from "../curriculum/schemas/lesson";

/** lessons added in wave 1 (2026-10-04); older lessons keep the picture color they had before these arrived */
const WAVE1 = new Set(["k-write", "k-bonds", "k-solids", "k-sort", "g1-three", "g1-tally", "g1-picgraph", "g2-solids", "g2-shares", "g2-coins", "g2-lineplot", "g2-estimate", "g3-mass", "g3-liters", "g3-graphs", "g3-lineplot", "g3-quads", "g4-mult2x2", "g4-lineplot", "g4-lines", "g4-symmetry"]);

/** One of the grade's three colors, lesson by lesson, counted without the wave 1 lessons so adding lessons never shifts an older lesson's color. */
export const tintOf = (lesson: AnyLesson): number =>
  lessonsInGrade(lesson.grade).filter(l => l === lesson || !WAVE1.has(l.id)).indexOf(lesson) % 3;
