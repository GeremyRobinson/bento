import type { ReactNode } from "react";

/** A tile's size on the BentoGrid master (styles/bento-grid.css): n number, s small, t tall, w wide, l large, f full. */
export type TileSize = "n" | "s" | "t" | "w" | "l" | "f";

/**
 * BentoGrid (master, Design 2026-10-07): the one grid every page's tiles sit on. Six columns that size themselves by
 * the grid's own width; each tile says only its size (`Tile size=`, or `bgClass(size)` on any element), never a column
 * or a row, so edges line up across rows on every page. Flow (the default) lets rows grow and the page scroll; `fit`
 * shares the height it is given between its rows, and a tile with more scrolls inside itself.
 */
export function BentoGrid({ fit, className, label, children }: { fit?: boolean; className?: string; label?: string; children: ReactNode }) {
  return <div className={`bgrid${fit ? " fit" : ""}${className ? ` ${className}` : ""}`} aria-label={label}><div className="bg-in">{children}</div></div>;
}

/** the class a tile of this size wears on the grid */
export const bgClass = (size?: TileSize) => (size ? `bg-t ${size}` : "");
