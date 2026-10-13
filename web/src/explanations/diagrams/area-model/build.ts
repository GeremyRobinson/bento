import { formatNumber } from "../../../curriculum/schemas/math-text";
import type { SplitMultiplicationProblem } from "../../../curriculum/lessons/grade5/g5-mult2/problem";
import { DEFAULT_AREA_LAYOUT, type AreaBand, type AreaDiagram, type AreaLayout, type AreaRegion } from "./schema";
import { fitParts } from "./grid";
import { seatLines } from "./seats";

/** Rough width of a number label in the app's rounded number font. */
/** how far apart two rows of labels sit */
export const ROW = 26;
/** the gap between two parts (v2 lesson spec G1): each part is its own shape, never one block cut by a line */
export const PART_GAP = 12;

/** g5-mult2 draws every seat (v2 spec G8: counts match the numbers); at 98 × 98 a seat is still 3 units */
export const STRIP_SEAT_MIN = 3;
/** a very flat picture (13 × 96) is stretched to at most 4 wide for 1 tall, so its strips stay readable on a phone (G9) */
export const MAX_FLAT = 4;

export const labelWidth = (label: string, fontSize: number) => label.length * fontSize * 0.62 + 12;

/**
 * Builds the area model for a split multiplication straight from the canonical problem: the first factor down the side
 * (one row, labelled whole), the second across the top, cut into its tens and ones (one column, one strip, per part).
 * One scale for both axes, so the strips are in proportion; a tiny part (the 2 of 42) keeps room for its label.
 * Each strip is its own shape, one gap apart (v2 spec G1); every label sits outside the picture (G5).
 */
export function buildSplitAreaDiagram(p: SplitMultiplicationProblem, layout: AreaLayout = DEFAULT_AREA_LAYOUT): AreaDiagram {
  const { margin, maxWidth, maxHeight, labelFontSize } = layout;
  const gaps = PART_GAP * (p.parts.length - 1);
  const unit = Math.min((maxWidth - gaps) / p.secondFactor, maxHeight / p.firstFactor);
  const mins = p.parts.map(part => Math.max(30, labelWidth(formatNumber(part), labelFontSize)));
  const widths = fitParts(p.parts, mins, Math.max(p.secondFactor * unit, mins.reduce((a, b) => a + b, 0)), unit).lengths;
  const drawn = widths.reduce((a, b) => a + b, 0) + gaps;
  const left = margin.left, top = margin.top, height = Math.max(p.firstFactor * unit, drawn / MAX_FLAT);
  let at = left;
  const cols: AreaBand[] = widths.map((length, i) => { const b = { label: formatNumber(p.parts[i]!), start: at, length }; at += length + PART_GAP; return b; });
  const rows: AreaBand[] = [{ label: formatNumber(p.firstFactor), start: top, length: height }];
  const regions: AreaRegion[] = p.parts.map((part, index) => {
    const c = cols[index]!, product = p.partialProducts[index]!;
    return {
      index,
      part,
      product,
      x: c.start,
      y: top,
      width: c.length,
      height,
      widthFraction: part / p.secondFactor,
      partLabel: c.label,
      productLabel: formatNumber(product),
      labelPlacement: "inside",
      partRow: 0,
      productRow: 0,
      seats: seatLines(c.start, top, c.length, height, part, p.firstFactor, 0, STRIP_SEAT_MIN),
      equation: { factors: [p.firstFactor, part], product },
      col: index,
      row: 0,
    };
  });
  const drawnWidth = drawn;
  return {
    kind: "areaModel",
    width: left + drawnWidth + margin.right,
    height: top + height + 4,
    unit,
    vertical: { factor: "first", value: p.firstFactor, label: formatNumber(p.firstFactor), start: top, length: height },
    horizontal: { factor: "second", value: p.secondFactor, label: formatNumber(p.secondFactor), start: left, length: drawnWidth },
    cols,
    rows,
    regions,
    total: { terms: [...p.partialProducts], value: p.product },
  };
}
