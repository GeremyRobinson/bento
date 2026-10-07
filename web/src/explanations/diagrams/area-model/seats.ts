// The seats inside an area model: a 30 × 20 part reads as six blocks of 100 little squares, not one plain box
// (G 2026-10-07: "show little squares coloured", and "who's counting 300 squares").

/** One line between seats, in SVG units; `ten` lines mark off the blocks of ten. */
export interface SeatLine { x1: number; y1: number; x2: number; y2: number; ten: boolean }

/** a seat is drawn on its own only when it is at least this big; smaller ones show as blocks of ten */
export const SEAT_MIN = 5;

const r1 = (v: number) => Math.round(v * 10) / 10;

/**
 * The lines that cut a part `cols` seats wide and `rows` seats tall into its seats.
 * Every seat when each one is big enough to see; otherwise only the blocks of ten, so a big part still counts in hundreds.
 */
export function seatLines(x: number, y: number, w: number, h: number, cols: number, rows: number, inset = 0): SeatLine[] {
  const sw = w / cols, sh = h / rows, every = sw >= SEAT_MIN && sh >= SEAT_MIN;
  const out: SeatLine[] = [];
  for (let k = 1; k < cols; k++) {
    const ten = k % 10 === 0;
    if (!every && !ten) continue;
    const at = r1(x + k * sw);
    out.push({ x1: at, y1: r1(y + inset), x2: at, y2: r1(y + h - inset), ten });
  }
  for (let k = 1; k < rows; k++) {
    const ten = k % 10 === 0;
    if (!every && !ten) continue;
    const at = r1(y + k * sh);
    out.push({ x1: r1(x + inset), y1: at, x2: r1(x + w - inset), y2: at, ten });
  }
  return out;
}
