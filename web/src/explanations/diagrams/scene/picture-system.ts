/**
 * The picture system's spacing, in model units (v2 lesson spec G1, G5; Review's measured gate M3). The colour roles
 * and these same numbers as CSS tokens live in styles/picture-system.css, whose header is the rule table;
 * tests/styles/picture-system.test.ts keeps the two equal. Builders take their gaps and label sizes from here.
 */
export const PIC = {
  /** the gap between parts, by picture type */
  gap: {
    /** area model parts (and other part-by-part pictures: digit boxes, grids, expression boxes) */
    area: 12,
    /** fraction bar segments */
    bar: 6,
    /** mixed-number and unit-division bars (one bar per whole) */
    mixed: 4,
  },
  /** a label to its part */
  labelGap: 10,
  /** label size and weight */
  label: 20,
  labelWeight: 650,
  /** a part's outline, drawn just outside it */
  outline: 3,
  /** corners: a big part 4, a bar segment 8 */
  corner: { part: 4, bar: 8 },
} as const;
