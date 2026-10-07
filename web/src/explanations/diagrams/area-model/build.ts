import { formatNumber } from "../../../curriculum/schemas/math-text";
import type { SplitMultiplicationProblem } from "../../../curriculum/lessons/grade5/g5-mult2/problem";
import { DEFAULT_AREA_LAYOUT, type AreaDiagram, type AreaLayout, type AreaRegion } from "./schema";
import { fitParts } from "./grid";
import { seatLines } from "./seats";

/** Rough width of a number label in the app's rounded number font. */
/** how far apart two rows of labels sit */
export const ROW = 26;

export const labelWidth = (label: string, fontSize: number) => label.length * fontSize * 0.62 + 12;

/**
 * Builds the area model for a split multiplication straight from the canonical problem.
 * One scale for both axes: the rectangle is firstFactor tall and secondFactor wide, in proportion.
 */
export function buildSplitAreaDiagram(p: SplitMultiplicationProblem, layout: AreaLayout = DEFAULT_AREA_LAYOUT): AreaDiagram {
  const { margin, maxWidth, maxHeight, labelFontSize } = layout;
  const unit = Math.min(maxWidth / p.secondFactor, maxHeight / p.firstFactor);
  const totalWidth = p.secondFactor * unit;
  const totalHeight = p.firstFactor * unit;
  const left = margin.left, top = margin.top;

  // a tiny part (the 2 of 40 + 2) keeps room for its label instead of a hairline; the other parts give up the space
  const mins = p.parts.map(part => Math.max(26, labelWidth(formatNumber(part), labelFontSize)));
  const { lengths } = fitParts(p.parts, mins, Math.max(totalWidth, mins.reduce((a, b) => a + b, 0)), unit);
  const drawnWidth = lengths.reduce((a, b) => a + b, 0);
  let x = left;
  const regions: AreaRegion[] = p.parts.map((part, index) => {
    const width = lengths[index]!;
    const productLabel = formatNumber(p.partialProducts[index]!);
    const region: AreaRegion = {
      index,
      part,
      product: p.partialProducts[index]!,
      x,
      y: top,
      width,
      height: totalHeight,
      widthFraction: part / p.secondFactor,
      partLabel: formatNumber(part),
      productLabel,
      labelPlacement: width >= labelWidth(productLabel, labelFontSize) ? "inside" : "below",
      partRow: 0,
      productRow: 0,
      seats: [],
      equation: { factors: [p.firstFactor, part], product: p.partialProducts[index]! },
    };
    x += width;
    return region;
  });

  // a narrow rectangle can leave neighbouring labels touching: those step one row further out
  const stagger = (labels: { x: number; label: string }[]) => {
    const rows: number[] = [], ends: number[] = [];
    for (const { x: cx, label } of labels) {
      const w = labelWidth(label, labelFontSize);
      let row = 0;
      while (ends[row] != null && cx - w / 2 < ends[row]! + 4) row++;
      ends[row] = cx + w / 2;
      rows.push(row);
    }
    return rows;
  };
  const partRows = stagger(regions.map(r => ({ x: r.x + r.width / 2, label: r.partLabel })));
  const below = regions.filter(r => r.labelPlacement === "below");
  const productRows = stagger(below.map(r => ({ x: r.x + r.width / 2, label: r.productLabel })));
  regions.forEach((r, i) => { r.partRow = partRows[i]!; });
  below.forEach((r, i) => { r.productRow = productRows[i]!; });
  const extraTop = Math.max(0, ...partRows) * ROW, extraBottom = Math.max(0, ...productRows) * ROW;
  if (extraTop) for (const r of regions) r.y += extraTop;
  for (const r of regions) r.seats = seatLines(r.x, r.y, r.width, r.height, r.part, p.firstFactor);

  return {
    kind: "areaModel",
    width: left + drawnWidth + margin.right,
    height: top + extraTop + totalHeight + margin.bottom + extraBottom,
    unit,
    vertical: { factor: "first", value: p.firstFactor, label: formatNumber(p.firstFactor), start: top + extraTop, length: totalHeight },
    horizontal: { factor: "second", value: p.secondFactor, label: formatNumber(p.secondFactor), start: left, length: drawnWidth },
    regions,
    splits: regions.slice(1).map(r => r.x),
    total: { terms: [...p.partialProducts], value: p.product },
  };
}
