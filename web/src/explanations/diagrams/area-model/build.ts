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

export const labelWidth = (label: string, fontSize: number) => label.length * fontSize * 0.62 + 12;

/**
 * Builds the area model for a split multiplication straight from the canonical problem: the first factor across the top,
 * the second down the side, each cut into its tens and ones, one part per pair (v2 model).
 * One scale for both axes, so the parts are in proportion; a tiny part (the 2 of 12) keeps room for its label.
 */
export function buildSplitAreaDiagram(p: SplitMultiplicationProblem, layout: AreaLayout = DEFAULT_AREA_LAYOUT): AreaDiagram {
  const { margin, maxWidth, maxHeight, labelFontSize } = layout;
  const gapsX = PART_GAP * (p.firstParts.length - 1), gapsY = PART_GAP * (p.secondParts.length - 1);
  const unit = Math.min((maxWidth - gapsX) / p.firstFactor, (maxHeight - gapsY) / p.secondFactor);
  const fit = (parts: number[], max: number) => {
    const mins = parts.map(part => Math.max(30, labelWidth(formatNumber(part), labelFontSize)));
    return fitParts(parts, mins, Math.max(max, mins.reduce((a, b) => a + b, 0)), unit).lengths;
  };
  const widths = fit(p.firstParts, p.firstFactor * unit), heights = fit(p.secondParts, p.secondFactor * unit);
  const left = margin.left, top = margin.top;
  const bands = (lengths: number[], parts: number[], start: number): AreaBand[] => {
    let at = start;
    return lengths.map((length, i) => { const b = { label: formatNumber(parts[i]!), start: at, length }; at += length + PART_GAP; return b; });
  };
  const cols = bands(widths, p.firstParts, left), rows = bands(heights, p.secondParts, top);
  const regions: AreaRegion[] = p.cells.map(({ first, second }, index) => {
    const col = p.firstParts.indexOf(first), row = p.secondParts.indexOf(second);
    const c = cols[col]!, r = rows[row]!, product = p.partialProducts[index]!;
    return {
      index,
      part: first,
      product,
      x: c.start,
      y: r.start,
      width: c.length,
      height: r.length,
      widthFraction: first / p.firstFactor,
      partLabel: c.label,
      productLabel: formatNumber(product),
      labelPlacement: "inside",
      partRow: 0,
      productRow: 0,
      seats: seatLines(c.start, r.start, c.length, r.length, first, second),
      equation: { factors: [first, second], product },
      col,
      row,
    };
  });
  const drawnWidth = widths.reduce((a, b) => a + b, 0) + gapsX, drawnHeight = heights.reduce((a, b) => a + b, 0) + gapsY;
  return {
    kind: "areaModel",
    width: left + drawnWidth + margin.right,
    height: top + drawnHeight + 4,
    unit,
    vertical: { factor: "second", value: p.secondFactor, label: formatNumber(p.secondFactor), start: top, length: drawnHeight },
    horizontal: { factor: "first", value: p.firstFactor, label: formatNumber(p.firstFactor), start: left, length: drawnWidth },
    cols,
    rows,
    regions,
    total: { terms: [...p.partialProducts], value: p.product },
  };
}
