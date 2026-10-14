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

/**
 * On a phone the label floor (--px, styles/picture-system.css) draws a label bigger than its picture units, so a row of
 * text under the picture moves down by what the `rows` label rows above it grew: stacked lines never run into each other.
 * Spread into a scene item's `vars`. (A text row is about 1.25 of its size, edge to edge.)
 */
export const growDown = (rows: number): Record<string, string> =>
  rows > 0 ? { transform: `translateY(calc(${Math.round(rows * 125) / 100} * (max(${PIC.label}, ${PIC.label} * var(--px, 0)) - ${PIC.label}) * 1px))` } : {};

/** How many picture units are left once `chars` characters at their on-screen size (`size` units, never under 14px on
 * screen) and 4px of air are taken out of `room` picture units (a CSS expression; under 0 means they touch). */
export const roomLeft = (room: number, chars: number, size: number): string =>
  `(${Math.round(room * 10) / 10} - ${Math.round(chars * 0.62 * 100) / 100} * max(${size}, 14 * var(--px, 0)) - 4 * var(--px, 0))`;

/**
 * Tick numbers that would touch once the phone floor grows them fade out, every other one first: a number shows only
 * while each room it needs (see roomLeft) is left. Spread into a scene item's `vars`; it uses fill-opacity, so the
 * item's own entrance still plays.
 */
export const thinOut = (...rooms: string[]): Record<string, string> => ({
  fillOpacity: `clamp(0, calc(min(${rooms.join(", ")}) * 1000), 1)`,
});
