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
 * The master square every lesson picture is drawn inside (G 2026-10-14 22:36: "lessons should start as an empty square…
 * the picture is designed INSIDE that box"). It is 36 cells of 10 a side: 360 splits evenly into 2, 3, 4, 5, 6, 8, 9, 10
 * and 12, so bars cut that many ways land their cuts on grid lines; sevenths and elevenths split exactly and sit centred.
 * Parts, labels, gaps and padding are whole cells; the square scales as one to its box.
 */
export const SQUARE = { side: 360, cell: 10, pad: 20 } as const;
/**
 * The master shapes a picture is drawn in, on the same 10-unit grid with the same 2-cell padding (G 2026-10-14: the box
 * isn't always square). The box takes the shape nearest its own: square (iPad portrait), wide 3:2 (iPad landscape),
 * strip 3:1 (phone practice). A strip under about 330px across would draw its 20-unit labels under the 14px floor.
 */
export type MasterShape = "square" | "wide" | "strip";
export const MASTERS: Record<MasterShape, { w: number; h: number }> = { square: { w: 360, h: 360 }, wide: { w: 540, h: 360 }, strip: { w: 480, h: 160 } };
/** a length rounded up to whole cells */
export const cells = (v: number) => Math.ceil(v / SQUARE.cell - 1e-9) * SQUARE.cell;

/**
 * On a phone the label floor (--px, styles/picture-system.css) draws a label bigger than its picture units, so a row of
 * text under the picture moves down by what the `rows` label rows above it grew: stacked lines never run into each other.
 * Spread into a scene item's `vars`. (A text row is about 1.25 of its size, edge to edge.)
 */
export const growDown = (rows: number): Record<string, string> =>
  rows > 0 ? { transform: `translateY(calc(${Math.round(rows * 125) / 100} * (max(${PIC.label}, ${PIC.label} * var(--px, 0)) - ${PIC.label}) * 1px))` } : {};

/**
 * In a short box (--short, styles/picture-system.css: a phone's Watch one or practice strip) a stack of worked lines is
 * written as one line: a line `up` units below the first moves into its place. Spread into `vars`; pair it with the
 * .shortgo / .shortout classes on the line it replaces. It uses translate, so the item's entrance (transform) still plays.
 */
export const shortUp = (up: number): Record<string, string> => (up ? { translate: `0 calc(var(--short, 0) * ${-Math.round(up * 10) / 10}px)` } : {});

/**
 * A worked line that, in a short box, gives way to the next line written in its place (shortUp): it is drawn as it is
 * until that line's beat, then goes `at` seconds into it (.shortout) and stays gone after (.shortgo). Anywhere else it
 * stays as before. Returns the line's items; `beat`/`at` say when the next line comes, `last` is the picture's last beat.
 */
export function giveWay<T extends { from?: number; until?: number; cls?: string; enter?: string; delay?: number; vars?: Record<string, string | number> }>(it: T, beat: number, at: number, last: number): T[] {
  const from = it.from ?? 0;
  if (it.until != null && it.until < beat) return [it];
  // drawn only after the next line came (a dimmed copy): gone from the start in a short box
  if (beat < from) return [{ ...it, cls: `${it.cls ?? ""} shortgo`.trim() }];
  const { enter: _e, delay: _d, until: _u, ...still } = it;
  const cls = `${it.cls ?? ""}`.trim(), vars = { ...it.vars, "--d2": `${at.toFixed(2)}s` };
  // on the next line's beat it goes `at` seconds in; on the last beat (or its own last) that copy simply stays to the end
  const ends = it.until === beat || beat >= last;
  const outCopy = { ...still, cls: `${cls} shortout`, vars, ...(ends ? (it.until != null ? { until: beat } : {}) : { until: beat }) };
  const after = ends ? [] : [{ ...still, cls: `${cls} shortgo`, from: beat + 1, ...(it.until != null ? { until: it.until } : {}) }];
  // the next line comes in the beat this one comes in: it comes in and goes in one beat (keeping its entrance)
  if (beat === from) return [{ ...it, ...outCopy, enter: it.enter, delay: it.delay } as T, ...(after as unknown as T[])];
  return [{ ...it, until: beat - 1 }, { ...outCopy, from: beat } as unknown as T, ...(after as unknown as T[])];
}

/**
 * growDown for a picture laid out on a grid of rows (factor chips): what sits on row `rows` moves down by what the label
 * rows above it grew on a phone. It uses translate, so a part's own entrance or slide (transform) still plays.
 */
export const growRows = (rows: number): Record<string, string> =>
  rows > 0 ? { translate: `0 calc(${Math.round(rows * 125) / 100} * (max(${PIC.label}, ${PIC.label} * var(--px, 0)) - ${PIC.label}) * 1px)` } : {};

/** growDown's mirror: a line above `rows` label rows that stand up off their part (.up) moves up by what they grew. */
export const growUp = (rows: number): Record<string, string> =>
  rows > 0 ? { transform: `translateY(calc(${-Math.round(rows * 125) / 100} * (max(${PIC.label}, ${PIC.label} * var(--px, 0)) - ${PIC.label}) * 1px))` } : {};

/**
 * Row labels on a phone whose rows are thinner than a label at its floor: row `i` of `n` moves away from the middle by
 * its share of the overlap, so two labels side by side never touch (a 2-row tape's 2/6 and 5/6). Spread into `vars`.
 */
export const spreadRows = (i: number, n: number, pitch: number): Record<string, string> => ({
  transform: `translateY(calc(${Math.round((i - (n - 1) / 2) * 100) / 100} * max(0, 1.3 * max(${PIC.label}, ${PIC.label} * var(--px, 0)) - ${Math.round(pitch * 10) / 10}) * 1px))`,
});

/**
 * A number inside a piece keeps its size while it fits there, then shrinks to fit, never under the 14px floor on screen
 * (units' 100s on a 360 phone). Spread into `vars` with thinOut for what still can't fit.
 */
export const fitIn = (room: number, chars: number, size: number, floor = 14): Record<string, string> => ({
  fontSize: `calc(max(14 * var(--px, 0), min(max(${size}, ${floor} * var(--px, 0)), (${Math.round(room * 10) / 10} - 4 * var(--px, 0)) / ${Math.round(chars * 0.62 * 100) / 100})) * 1px)`,
});

/** How many picture units are left once `chars` characters at their on-screen size (`size` units, never under 14px on
 * screen; a label's floor is 20) and 4px of air are taken out of `room` picture units (a CSS expression; under 0 means they touch). */
export const roomLeft = (room: number, chars: number, size: number, floor = 14): string =>
  `(${Math.round(room * 10) / 10} - ${Math.round(chars * 0.62 * 100) / 100} * max(${size}, ${floor} * var(--px, 0)) - 4 * var(--px, 0))`;

/**
 * Tick numbers that would touch once the phone floor grows them fade out, every other one first: a number shows only
 * while each room it needs (see roomLeft) is left. Spread into a scene item's `vars`; it uses fill-opacity, so the
 * item's own entrance still plays.
 */
export const thinOut = (...rooms: string[]): Record<string, string> => ({
  fillOpacity: `clamp(0, calc(min(${rooms.join(", ")}) * 1000), 1)`,
});

/** A text class's drawing size and its floor on screen (styles/picture-system.css): a label 20 and never under 20px,
 * other text never under 14px. */
export const textSize = (cls = ""): [number, number] => {
  const c = ` ${cls} `, lbl = c.includes(" lbl "), big = c.includes(" big ");
  return lbl ? [big ? 22 : PIC.label, PIC.label] : big ? [28, PIC.label] : c.includes(" sm ") ? [15, 14] : c.includes(" xs ") ? [12, 14] : [17, 14];
};

/**
 * fitIn for a text that keeps its class's own size token (so a tablet still holds it at the text zoom): it draws at its
 * class's size while `chars` characters fit `room` units, then shrinks to fit, never under 14px on screen.
 */
export const fitClass = (room: number, chars: number, cls = ""): Record<string, string> => {
  const c = ` ${cls} `, lbl = c.includes(" lbl "), big = c.includes(" big ");
  const token = lbl ? (big ? "--d-text-lg" : "--pic-label") : big ? "--d-text-xl" : c.includes(" sm ") ? "--d-text-sm" : c.includes(" xs ") ? "--d-text-xs" : "--d-text";
  const floor = textSize(cls)[1];
  return {
    fontSize: `max(calc(14px * var(--px, 0)), min(max(var(${token}), calc(${floor}px * var(--px, 0))), calc((${Math.round(room * 10) / 10} - 4 * var(--px, 0)) / ${Math.round(chars * 0.62 * 100) / 100} * 1px)))`,
  };
};

/**
 * Lines of text stacked `pitch` apart (one pitch, or one per gap) that stay apart on a phone: where the floor grows two
 * neighbours past their pitch, the lines below move down by what they lack, and the stack keeps its `hold` point still
 * (its first line "top", its middle "mid", its last line "bottom"), so a column beside a picture stays centred on it.
 * Returns each line's `vars` (one per class in `cls`). On a tablet nothing moves.
 */
export const stackRows = (cls: string[], pitch: number | number[], hold: "top" | "mid" | "bottom" = "top"): Record<string, string>[] => {
  const H = (c: string) => { const [s, f] = textSize(c); return `max(${s}, ${f} * var(--px, 0))`; };
  const lack = cls.slice(1).map((c, k) => `max(0, 0.6 * (${H(cls[k]!)} + ${H(c)}) - ${Array.isArray(pitch) ? pitch[k]! : pitch})`);
  const share = hold === "top" ? 0 : hold === "mid" ? 0.5 : 1;
  return cls.map((_, i): Record<string, string> => {
    const terms = lack.map((l, k) => ({ w: (k < i ? 1 : 0) - share, l })).filter(x => x.w);
    if (!terms.length) return {};
    const sum = terms.map((x, k) => `${x.w < 0 ? (k ? " - " : "-") : k ? " + " : ""}${Math.abs(x.w)} * ${x.l}`).join("");
    return { transform: `translateY(calc((${sum}) * 1px))` };
  });
};
