/**
 * Tape diagrams and fraction bars (the current app's `tape()`), as a model a lesson computes from its problem.
 * Lengths are in "units" (one whole bar, or one box of a ratio tape); the builder picks one scale for every row,
 * so bars stay in proportion. Everything can change beat by beat: rows appear, get cut into more parts,
 * get shaded, and their labels change.
 */

/** A label that shows from one beat (and optionally until another). Text like "3/4" is drawn as a stacked fraction when there is room. */
export interface TapeText {
  text: string;
  from?: number;
  until?: number;
  /** amber, for the thing being found (a "?" is always amber) */
  acc?: boolean;
}

/**
 * How a stretch of a bar is coloured, by its role (handoff-6): on: the first quantity (part blue); two: the second
 * quantity, what's added or compared (part orange); acc: the thing being found or the step in focus (amber);
 * cut: taken away (faded and struck through).
 */
export type TapeTone = "on" | "two" | "acc" | "cut";

export interface TapeFill {
  /** from and to, in units (positions are absolute: 0 is the left edge of every bar that starts at 0) */
  a: number;
  b: number;
  tone: TapeTone;
  from?: number;
  until?: number;
}

export interface TapeRow {
  /** where the bar starts, in units (default 0) */
  start?: number;
  /** bar length in units */
  length: number;
  /** equal parts the bar is cut into; a list re-cuts it at later beats (each entry shows until the next one starts) */
  parts: number | { count: number; from: number }[];
  /** outline every whole unit (for bars longer than one whole) */
  wholes?: boolean;
  /** thin lines cutting each part into smaller pieces without redrawing it (e.g. hundredths inside tenths) */
  ticks?: { count: number; from?: number; until?: number; dashed?: boolean }[];
  fills?: TapeFill[];
  /** text inside each part; `text(i)` for part i (0-based) of the cut that is showing at that beat */
  each?: { text: (i: number) => string; from?: number; until?: number; only?: (i: number) => boolean }[];
  label?: TapeText[];
  total?: TapeText[];
  from?: number;
  until?: number;
}

export interface TapeBracket {
  row: number;
  /** span in units (absolute, like fills) */
  a: number;
  b: number;
  text: string;
  side: "above" | "below";
  from?: number;
  until?: number;
  acc?: boolean;
}

export interface TapeSpec {
  rows: TapeRow[];
  brackets?: TapeBracket[];
  /** dashed lines across rows at a unit position, showing the same amount lines up */
  guides?: { at: number; rows: [number, number]; from?: number }[];
  alt: string;
  /** canvas width (default 480) */
  width?: number;
  /** tallest a bar may be (default 46) */
  maxRowHeight?: number;
}
