import type { SeatLine } from "./seats";

/**
 * Geometry for an area model. Positions and sizes are plain numbers in SVG user units;
 * the renderer draws exactly this and makes no math decisions of its own.
 */
export interface AreaAxis {
  /** which factor of the problem owns this side */
  factor: "first" | "second";
  value: number;
  label: string;
  /** where the side starts and how long it is, along its own direction */
  start: number;
  length: number;
}

export interface AreaRegion {
  index: number;
  /** the split part this region stands for */
  part: number;
  /** firstFactor × part */
  product: number;
  x: number;
  y: number;
  width: number;
  height: number;
  /** part / secondFactor */
  widthFraction: number;
  partLabel: string;
  productLabel: string;
  /** narrow regions put their product below the rectangle instead of inside it */
  labelPlacement: "inside" | "below";
  /** which row a label sits in when neighbours would touch: 0 next to the rectangle, 1 a row further out */
  partRow: number;
  productRow: number;
  /** the lines between its seats (or its blocks of ten, when seats are too small to see) */
  seats: SeatLine[];
  /** the multiplication this region proves, e.g. 40 × 30 = 1200 */
  equation: { factors: [number, number]; product: number };
  /** which column (part of the top factor) and row (part of the side factor) it sits in */
  col: number;
  row: number;
}

/** One part of a side: its label and where it runs, along that side's own direction. */
export interface AreaBand { label: string; start: number; length: number }

export interface AreaDiagram {
  kind: "areaModel";
  width: number;
  height: number;
  /** SVG units per 1. The same on both axes, so drawn area is honest. */
  unit: number;
  /** the factor along the left side */
  vertical: AreaAxis;
  /** the factor along the top */
  horizontal: AreaAxis;
  /** the parts of the top factor (columns) and of the side factor (rows); each is labelled once, outside the picture */
  cols: AreaBand[];
  rows: AreaBand[];
  regions: AreaRegion[];
  total: { terms: number[]; value: number };
  /** division (g5-divide): the strips' widths are found one at a time, so a top label waits until its strip is done
   * ("?" while it is asked, nothing before) */
  find?: boolean;
}

export interface AreaLayout {
  maxWidth: number;
  maxHeight: number;
  /** room for the top labels, the left label and the labels below narrow regions */
  margin: { top: number; right: number; bottom: number; left: number };
  labelFontSize: number;
}

export const DEFAULT_AREA_LAYOUT: AreaLayout = {
  maxWidth: 440,
  maxHeight: 300,
  margin: { top: 40, right: 12, bottom: 40, left: 56 },
  labelFontSize: 20,
};
