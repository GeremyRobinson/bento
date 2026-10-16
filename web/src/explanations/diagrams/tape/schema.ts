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
  /** seconds into its beat before it comes in (a running count lands after the pieces it counts) */
  delay?: number;
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
  /** seconds between one piece's shading and the next, so a stretch fills piece by piece as it is counted */
  stagger?: number;
}

export interface TapeRow {
  /** where the bar starts, in units (default 0) */
  start?: number;
  /** bar length in units */
  length: number;
  /** equal parts the bar is cut into; a list re-cuts it at later beats (each entry shows until the next one starts).
   *  A re-cut splits the parts apart; `delay` holds the split back within its beat (while the knife draws the cuts) */
  parts: number | { count: number; from: number; delay?: number }[];
  /** outline every whole unit (for bars longer than one whole) */
  wholes?: boolean;
  /** thin lines cutting each part into smaller pieces without redrawing it (e.g. hundredths inside tenths). `cut`: the
   *  knife before a re-cut, deep lines drawn in one after another where the bar is about to split (`all`: along the
   *  gaps between parts too, to show a bar that is already cut that way) */
  ticks?: { count: number; from?: number; until?: number; dashed?: boolean; cut?: boolean; all?: boolean }[];
  fills?: TapeFill[];
  /** text inside each part; `text(i)` for part i (0-based) of the cut that is showing at that beat */
  each?: { text: (i: number) => string; from?: number; until?: number; only?: (i: number) => boolean;
    /** seconds between one part's text and the next, so the parts are counted one by one (default 0.04) */
    stagger?: number;
    /** seconds before the first part's text (a count carried on from the row above) */
    lead?: number }[];
  label?: TapeText[];
  total?: TapeText[];
  from?: number;
  until?: number;
  /** the beats this row is the one the step is about: its label and its shaded pieces wear the picture's `lit` role */
  lit?: Beats[];
  /** set by the builder when it wraps a bar onto more lines in the master square: this row goes on the line before it */
  cont?: boolean;
  /** set by the builder when it wraps a bar: the whole bar had no shading, so every line of it keeps its parts filled */
  held?: boolean;
}

/** a run of beats, from one beat to another (or to the end) */
export interface Beats { from: number; until?: number }

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
  /** drawn inside the master square on its grid (picture-system SQUARE; G 2026-10-14, 5th grade trial) */
  square?: boolean;
  /** the master shape to lay out in (set by the builder, which lays a square spec out in every shape) */
  shape?: import("../scene/picture-system").MasterShape;
  /** what changes when the picture is laid out in the strip (a short, wide box): e.g. units on one row, not stacked */
  strip?: Partial<TapeSpec>;
  /** tallest a bar may be (default 46) */
  maxRowHeight?: number;
  /** the gap between pieces and between rows (picture system, PIC.gap): "bar" for fraction bars (6), "mixed" for
   *  mixed-number and unit-division bars, one per whole (4) */
  gap?: "bar" | "mixed";
  /** two quantities must be told apart (the second fraction): "two" fills turn violet. Otherwise every part is amber */
  two?: boolean;
  /** (default true) also lay the bars out tall, each row's label and total on a line over its bar instead of beside it, so a square box
   *  draws the bars full width and thicker (5th grade trial, G 2026-10-14); the picture draws whichever is bigger */
  tall?: boolean;
  /** this is the tall arrangement itself (set by the builder) */
  over?: boolean;
}
