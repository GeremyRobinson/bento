import { useSyncExternalStore } from "react";

/**
 * What the home box shows (UI model v57): every chapter (null), one chapter (its name), or every grade ("#grades").
 * The island reads it too: on the box's own top it carries the grade picker; a level down it carries back. A change
 * says how the box moves: "zin" going a level deeper, "zout" coming back out (the model's soft zoom).
 */
export type BoxView = string | null;
export const GRADES_VIEW = "#grades";

let view: BoxView = null;
let zoom: "zin" | "zout" | null = null;
const subs = new Set<() => void>();

export const boxView = () => view;
/** the zoom the last change asked for; the box plays it once */
export const boxZoom = () => zoom;

export function setBoxView(v: BoxView, how: "zin" | "zout" | null = null): void {
  if (v === view) return;
  view = v; zoom = how;
  subs.forEach(f => f());
}

export function useBoxView(): BoxView {
  return useSyncExternalStore(f => { subs.add(f); return () => subs.delete(f); }, boxView, boxView);
}
