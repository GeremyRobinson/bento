// Small helpers family builders share: scales and number formatting for labels.
import { formatNumber } from "../../../curriculum/schemas/math-text";
import type { SceneItem } from "./schema";

/** Maps a value range onto a pixel range. */
export const scale = (d0: number, d1: number, r0: number, r1: number) => (v: number) => r0 + ((v - d0) / (d1 - d0)) * (r1 - r0);

export const label = (v: number) => formatNumber(v);

/** A small arrowhead at (x, y) pointing along angle (radians). */
export function arrowHead(x: number, y: number, angle: number, size = 9, extra: Partial<SceneItem> = {}): SceneItem {
  const a1 = angle + Math.PI * 0.85, a2 = angle - Math.PI * 0.85;
  return {
    type: "polygon",
    points: [[x, y], [x + size * Math.cos(a1), y + size * Math.sin(a1)], [x + size * Math.cos(a2), y + size * Math.sin(a2)]],
    cls: "dotp",
    ...extra,
  } as SceneItem;
}

/**
 * The worked step lit, beat by beat, the way the area model lights its strip: on each beat `litOn` names for a shape, the
 * shape carries the picture system's shared `lit` role (a part soft → mid with a deeper outline, a label → pic-deep), and
 * on the beats either side it is itself again. A shape is cut into one copy per stretch; only the first keeps its
 * entrance, so lighting and unlighting never replay it.
 */
export function lightSteps(items: SceneItem[], litOn: (it: SceneItem) => number[] | null | undefined, last: number): SceneItem[] {
  return items.flatMap(it => {
    const from = it.from ?? 0, until = Math.min(it.until ?? Infinity, last), open = it.until == null || it.until > last;
    // only parts and labels light: a line or an arc would take the part's fill
    const lit = new Set(it.type === "path" || it.type === "line" ? [] : (litOn(it) ?? []).filter(b => b >= from && b <= until));
    if (!lit.size) return [it];
    const starts = [...new Set([from, ...lit, ...[...lit].map(b => b + 1)])].filter(b => b >= from && b <= until).sort((a, b) => a - b);
    return starts.map((s, k): SceneItem => {
      const end = k + 1 < starts.length ? starts[k + 1]! - 1 : open ? Infinity : until;
      const { enter: _e, delay: _d, ...still } = it;
      const base = k === 0 ? it : still;
      const out = { ...base, from: s } as SceneItem;
      if (lit.has(s)) out.cls = `${it.cls ?? ""} lit`.trim();
      if (end === Infinity) delete out.until; else out.until = end;
      return out;
    });
  });
}

/** The x coordinates a path passes through (its numbers in x, y pairs), for finding where a builder drew a line. */
export const pathXs = (d: string): number[] => (d.match(/-?[\d.]+/g) ?? []).map(Number).filter((_, k) => k % 2 === 0);

/** Rounds coordinates so the SVG stays small and stable in tests. */
export const r1 = (x: number) => Math.round(x * 10) / 10;
