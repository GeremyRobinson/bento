import type { Draft } from "../geo/kit";

// Kindergarten pictures are framed at least this wide: on the lesson page a picture fills the card's width,
// so a small set of dots sits in the middle instead of hugging the left edge.
export const WIDE = { w: 520 };

/** Gives a part of a picture its own grade colour (p0..p2 in the styles), the way the older lessons colour each part. */
export const P = (k: number): string => `p${((k % 3) + 3) % 3}`;
export function tint(items: Draft[], k: number): Draft[] {
  const p = P(k);
  return items.map(d => ({ ...d, cls: `${(d as { cls?: string }).cls ?? ""} ${p}`.trim() }) as Draft);
}
