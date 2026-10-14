/**
 * Tile pictures (v2, G 2026-10-13): a simple, still version of the picture a lesson uses, drawn with one set of rules
 * (3px outline, rounded corners, the picture palette: soft fill, mid for what's taken, grey for what isn't). A chapter
 * shows the picture of the lesson its others build on. One file per grade band in tilepics/ (draw.ts is the shared kit); a lesson without one shows its tile without.
 */
import { CHAPTER5, LESSON5 } from "./tilepics/g5";
import { CHAPTER_k2, LESSON_k2 } from "./tilepics/gk2";
import { CHAPTER_34, LESSON_34 } from "./tilepics/g34";
import { CHAPTER_68, LESSON_68 } from "./tilepics/g68";
import { CHAPTER_912, LESSON_912 } from "./tilepics/g912";
import { ICON_COVERS } from "./tilepics/icon-covers";
import { ICON_LESSONS } from "./tilepics/icon-lessons";

// lesson icons (G 2026-10-14, 5th grade first) stand in for the earlier pictures where both exist
const LESSON: Record<string, string> = { ...LESSON_k2, ...LESSON_34, ...LESSON5, ...LESSON_68, ...LESSON_912, ...ICON_LESSONS };
// the icon covers (G 2026-10-14) stand in for the earlier samples where both exist
const CHAPTER: Record<string, string> = { ...CHAPTER_k2, ...CHAPTER_34, ...CHAPTER5, ...CHAPTER_68, ...CHAPTER_912, ...ICON_COVERS };

export const lessonPic = (id: string): string | undefined => LESSON[id];
export const chapterPic = (grade: number, unit: string): string | undefined => CHAPTER[`${grade}:${unit}`];

/** the picture as a tile's top: a still svg, or nothing when this lesson's picture isn't drawn yet */
export function TilePic({ svg: s }: { svg?: string }) {
  return s ? <span className="v-picbox" dangerouslySetInnerHTML={{ __html: s }} /> : null;
}
