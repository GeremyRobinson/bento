import { flushSync } from "react-dom";

/** "still": no page motion at all, for changes inside a screen (picking a row) where only one part should move */
export type Dir = "" | "fwd" | "back" | "next" | "prev" | "still";

export { motionOff as reduceMotion } from "./settings";
import { motionOff as reduceMotion } from "./settings";

/** the old page leaves at once and only the new one moves, so nothing ever cross-fades (kept for older callers) */
export const canCrossFade = () => false;

/** how each way of travelling enters, the same keyframes as the contents' All grades / year / chapter switch */
const WAY: Record<Exclude<Dir, "still">, string> = { "": "", fwd: "in", back: "out", next: "next", prev: "prev" };

/** the pieces of the page under the nav: everything the screen drew, never the nav itself or an overlay */
const PAGE = "#app>:not(.itop):not(.zoom):not(.confirm):not(.fdim)";

/**
 * The one page change (G 2026-10-07: the contents' switcher is "so buttery smooth, use those transition mechanics across
 * the whole system"). Like the switcher, the old page is gone at once and the new one comes forward on its own: a fade
 * with a little zoom, on the one curve and speed (--m-page, --m-ease), around one point a third of the way down the
 * screen. Deeper zooms in from smaller, back settles in from larger, next and previous come in from the side. One
 * element animates opacity and transform only: no snapshot of the old page, no cascade of pieces, so it never stutters.
 */
export function withTransition(update: () => void, dir: Dir = ""): void {
  const d = typeof document === "undefined" ? null : document;
  const can = !!d && typeof Element !== "undefined" && typeof Element.prototype.animate === "function";
  if (!can || reduceMotion() || dir === "still") { update(); return; }
  // after the first page change the pieces no longer cascade in: the page arrives as one (motion.css)
  d!.documentElement.dataset.paged = "";
  // a page opened from the contents never starts from the zoomed-out, blurred page behind it (G: "saw this area when
  // coming into a grade"): the contents and its blur are gone in the same frame the new page is drawn
  delete d!.documentElement.dataset.zoomed;
  try { flushSync(update); } catch { update(); return; }
  playStage(WAY[dir]);
}

/** play the stage entrance on the page now drawn under the nav */
export function playStage(way = ""): void {
  if (typeof document === "undefined") return;
  const ox = innerWidth / 2, oy = innerHeight * 0.3;
  for (const el of document.querySelectorAll<HTMLElement>(PAGE)) {
    const r = el.getBoundingClientRect();
    el.style.transformOrigin = `${ox - r.left}px ${oy - r.top}px`;
    el.classList.remove("stage", "in", "out", "next", "prev");
    void el.offsetWidth; // restart the animation when the same element stays
    el.classList.add("stage", ...(way ? [way] : []));
    el.addEventListener("animationend", function done(e) {
      if (e.target !== el) return;
      el.classList.remove("stage", "in", "out", "next", "prev"); el.style.transformOrigin = "";
      el.removeEventListener("animationend", done);
    });
  }
}

/**
 * An element's drawn size as laid out, without the page change's zoom: while a page comes forward its pieces are scaled
 * (.86 to 1.14), so a measurement taken then must be divided back, or a fit (a math line, a picture's labels) is made for
 * the wrong size and stays wrong once the page settles.
 */
export function layoutRect(el: Element): { width: number; height: number } {
  const r = el.getBoundingClientRect();
  const stage = el.closest("#app>.stage");
  if (!stage) return { width: r.width, height: r.height };
  const m = getComputedStyle(stage).transform.match(/^matrix\(([^,]+),\s*([^,]+)/);
  const k = m ? Math.hypot(parseFloat(m[1]!), parseFloat(m[2]!)) : 1;
  return k > 0 && Math.abs(k - 1) > 1e-3 ? { width: r.width / k, height: r.height / k } : { width: r.width, height: r.height };
}
