// Tens rods and ones cubes for 1st grade place value: a rod is ten cubes stacked, ones stand in columns of five,
// so a child can count them. Every rod and cube is one of the problem's tens or ones.
import type { SceneDiagram } from "../scene/schema";
import { frame, t, type Draft } from "../geo/kit";

export const CUBE = 14;
const ROD_GAP = 8, ONE_GAP = 4;
export const ROD_H = 10 * CUBE;

export interface Timing { from?: number; until?: number; enter?: Draft["enter"]; delay?: number }
const timing = (o: Timing, extra = 0): Partial<Draft> => ({
  ...(o.from != null ? { from: o.from } : {}),
  ...(o.until != null ? { until: o.until } : {}),
  enter: o.enter ?? "pop",
  delay: Math.round(((o.delay ?? 0) + extra) * 100) / 100,
});
const cube = (x: number, y: number, cls: string, o: Timing, extra: number): Draft =>
  ({ type: "rect", x, y, w: CUBE, h: CUBE, rx: 2, cls, ...timing(o, extra) }) as Draft;

/** One rod: ten cubes from the bottom (y is the bottom edge). */
export function rod(x: number, bottom: number, cls: string, o: Timing): Draft[] {
  return Array.from({ length: 10 }, (_, k) => cube(x, bottom - (k + 1) * CUBE, cls, o, 0));
}

/** Width of `n` rods side by side. */
export const rodsWidth = (n: number) => (n ? n * (CUBE + ROD_GAP) - ROD_GAP : 0);
/** Width of `n` ones in columns of five. */
export const onesWidth = (n: number) => (n ? Math.ceil(n / 5) * (CUBE + ONE_GAP) - ONE_GAP : 0);

/** `n` ones cubes in columns of five, filled from the bottom, left to right. */
export function onesCubes(x: number, bottom: number, n: number, cls: string, o: Timing): Draft[] {
  return Array.from({ length: n }, (_, k) => cube(x + Math.floor(k / 5) * (CUBE + ONE_GAP), bottom - ((k % 5) + 1) * CUBE, cls, o, 0.06 * k));
}

/** Rods then ones for a number, starting at x; returns the drafts and where the rods and ones sit. */
export function blockSet(x: number, bottom: number, tens: number, ones: number, cls: string, o: Timing) {
  const items: Draft[] = [];
  for (let i = 0; i < tens; i++) items.push(...rod(x + i * (CUBE + ROD_GAP), bottom, cls, { ...o, delay: (o.delay ?? 0) + 0.1 * i }));
  const onesX = x + rodsWidth(tens) + (tens ? 18 : 0);
  items.push(...onesCubes(onesX, bottom, ones, cls, { ...o, delay: (o.delay ?? 0) + 0.1 * tens + 0.1 }));
  return { items, rodsX: x, rodsW: rodsWidth(tens), onesX, onesW: onesWidth(ones), width: onesX - x + onesWidth(ones) };
}

/** A soft ring around a group of blocks, shown while the narration talks about it. */
export const ring = (x: number, y: number, w: number, h: number, o: Timing): Draft =>
  ({ type: "rect", x: x - 6, y: y - 6, w: w + 12, h: h + 12, rx: 8, cls: "hlline", ...timing({ enter: "fade", ...o }) }) as Draft;

// ------------------------------------------------------------------ tens and ones

export interface TensOnesSpec {
  tens: number;
  ones: number;
  /** labels under the tens and the ones, and the number under everything */
  text?: { tens: string; ones: string; total: string };
  /** count-by-ten labels above the rods ("10", "20", ...), from the problem */
  tensCount?: string[];
  beats?: { tens: number; ones: number; total: number };
  alt: string;
}

/** A number as rods and cubes. With text and beats, the tens and then the ones light up, then the number shows. */
export function buildTensOnes(s: TensOnesSpec): SceneDiagram {
  const bottom = ROD_H;
  const set = blockSet(0, bottom, s.tens, s.ones, "cell c0", { enter: "pop" });
  const items: Draft[] = [...set.items];
  const b = s.beats;
  if (b && s.text) {
    // the two labels sit under their blocks, pushed apart when the blocks are too close for both
    const w = (x: string) => x.length * 17 * 0.6;
    let tx = set.rodsX + set.rodsW / 2, ox = set.onesX + set.onesW / 2;
    const need = (w(s.text.tens) + w(s.text.ones)) / 2 + 14;
    if (s.tens && s.ones && ox - tx < need) { const m = (tx + ox) / 2; tx = m - need / 2; ox = m + need / 2; }
    if (s.tens) {
      items.push(ring(set.rodsX, 0, set.rodsW, ROD_H, { from: b.tens, until: b.tens }));
      s.tensCount?.forEach((c, i) => items.push(t(set.rodsX + i * (CUBE + ROD_GAP) + CUBE / 2, -18, c, "xs", { from: b.tens, enter: "rise", delay: 0.3 + 0.25 * i })));
      items.push(t(tx, bottom + 26, s.text.tens, "lbl", { from: b.tens, enter: "rise", delay: 0.2 }));
    }
    if (s.ones) {
      items.push(ring(set.onesX, bottom - 5 * CUBE, set.onesW, 5 * CUBE, { from: b.ones, until: b.ones }));
      items.push(t(ox, bottom + 26, s.text.ones, "lbl", { from: b.ones, enter: "rise", delay: 0.2 }));
    }
    items.push(t(set.width / 2, bottom + 64, s.text.total, "lbl big acc", { from: b.total, enter: "rise", delay: 0.2 }));
  }
  return frame("place-value", items, s.alt, 14, { w: 520 });
}

// ------------------------------------------------------------------ two numbers side by side

export interface CompareBlocksSpec {
  a: number;
  b: number;
  /** the sign between them, shown from beats.sign */
  sign: string;
  text: { aTens: string; bTens: string; aOnes: string; bOnes: string };
  /** beat for the tens labels, for the ones labels (null when the tens already decide), and for the sign */
  beats: { tens: number; ones: number | null; sign: number };
  alt: string;
}

export function buildCompareBlocks(s: CompareBlocksSpec): SceneDiagram {
  const bottom = ROD_H, items: Draft[] = [];
  // each number its own part color (blue, then orange), its labels too; the sign being found is amber
  const side = (n: number, x: number, k: 0 | 1, tensText: string, onesText: string) => {
    const set = blockSet(x, bottom, Math.floor(n / 10), n % 10, `cell c${k}`, { enter: "pop" });
    items.push(...set.items);
    const cx = x + set.width / 2;
    items.push(t(cx, bottom + 30, String(n), `lbl big p${k}`));
    items.push(ring(set.rodsX, 0, Math.max(set.rodsW, 1), ROD_H, { from: s.beats.tens, until: s.beats.ones ?? s.beats.tens }));
    items.push(t(cx, bottom + 62, tensText, `lbl p${k}`, { from: s.beats.tens, until: s.beats.ones != null ? s.beats.tens : undefined, enter: "rise", delay: 0.2 }));
    if (s.beats.ones != null && n % 10) items.push(ring(set.onesX, bottom - 5 * CUBE, set.onesW, 5 * CUBE, { from: s.beats.ones, until: s.beats.ones }));
    if (s.beats.ones != null) items.push(t(cx, bottom + 62, onesText, `lbl p${k}`, { from: s.beats.ones, enter: "rise", delay: 0.2 }));
    return set.width;
  };
  const wa = side(s.a, 0, 0, s.text.aTens, s.text.aOnes);
  const gap = 84;
  side(s.b, wa + gap, 1, s.text.bTens, s.text.bOnes);
  items.push({ type: "circle", cx: wa + gap / 2, cy: bottom / 2 + 10, r: 26, cls: "sq big", from: s.beats.sign, enter: "pop" } as Draft);
  items.push(t(wa + gap / 2, bottom / 2 + 10, s.sign, "big", { from: s.beats.sign, enter: "pop", delay: 0.2 }));
  return frame("place-value", items, s.alt, 14);
}

// ------------------------------------------------------------------ adding tens

export interface AddTensSpec {
  n: number;
  /** tens being added */
  k: number;
  text: { start: string; added: string; tens: string; total: string };
  beats: { added: number; tens: number; total: number };
  alt: string;
}

/** The number's rods and ones, then k new rods drop in beside the rods; the ones never move. */
export function buildAddTens(s: AddTensSpec): SceneDiagram {
  const bottom = ROD_H, t0 = Math.floor(s.n / 10), o = s.n % 10, items: Draft[] = [];
  const allRods = rodsWidth(t0 + s.k);
  for (let i = 0; i < t0; i++) items.push(...rod(i * (CUBE + ROD_GAP), bottom, "cell c0", { delay: 0.1 * i }));
  for (let i = 0; i < s.k; i++) items.push(...rod((t0 + i) * (CUBE + ROD_GAP), bottom, "cell c1", { from: s.beats.added, enter: "drop", delay: 0.2 + 0.2 * i }));
  const onesX = allRods + 22;
  items.push(...onesCubes(onesX, bottom, o, "cell c0", { delay: 0.1 * t0 + 0.1 }));
  const mid = (onesX + onesWidth(o)) / 2;
  items.push(t(mid, bottom + 28, s.text.start, "lbl", { until: s.beats.added - 1 }));
  items.push(t(mid, bottom + 28, s.text.added, "lbl", { from: s.beats.added, until: s.beats.tens - 1, enter: "rise", delay: 0.4 }));
  items.push(ring(0, 0, allRods, ROD_H, { from: s.beats.tens, until: s.beats.tens }));
  items.push(t(mid, bottom + 28, s.text.tens, "lbl", { from: s.beats.tens, enter: "rise", delay: 0.2 }));
  items.push(t(mid, bottom + 64, s.text.total, "lbl big acc", { from: s.beats.total, enter: "rise", delay: 0.2 }));
  return frame("place-value", items, s.alt, 14, { w: 520 });
}
