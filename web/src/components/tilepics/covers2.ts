/**
 * Chapter covers, style B "a real thing": the rest of the chapters (K to 4th, 6th to 12th; 5th grade keeps its own).
 * The same kit, roles and one-move rule as covers.ts. Review passed sheet 2 (math-app/review/v2/covers-test).
 */
import { band, circ, cover, group, line, path, poly, r1, rect } from "./covers";

const deg = (a: number) => (a * Math.PI) / 180;
const ell = (c: string, cx: number, cy: number, rx: number, ry: number, a = "", d = 0) =>
  `<ellipse class="${c}" cx="${r1(cx)}" cy="${r1(cy)}" rx="${r1(rx)}" ry="${r1(ry)}"${a ? ` data-a="${a}" style="--d:${d}s"` : ""}/>`;
/** a pie wedge from angle a to b (degrees, clockwise from 3 o'clock) */
const wedge = (cx: number, cy: number, r: number, a: number, b: number) =>
  `M${cx} ${cy} L${r1(cx + r * Math.cos(deg(a)))} ${r1(cy + r * Math.sin(deg(a)))} A${r} ${r} 0 ${b - a > 180 ? 1 : 0} 1 ${r1(cx + r * Math.cos(deg(b)))} ${r1(cy + r * Math.sin(deg(b)))} Z`;

// ---- Kindergarten ----------------------------------------------------------------------------------------------------

// a plate of three cookies, and two more join them, each clear of the next so they can be counted
const cookie = (x: number, y: number, a = "", d = 0) => group(circ("m", x, y, 11) + circ("f", x - 4, y - 3, 2) + circ("f", x + 4, y + 1, 2) + circ("f", x - 1, y + 5, 2), a, d);
const K_ADD = cover("4 22 152 72", ell("s", 80, 76, 74, 16) + ell("o", 80, 74, 56, 10) + cookie(24, 62) + cookie(50, 62) + cookie(76, 62) + cookie(108, 62, "drop", 0.3) + cookie(134, 62, "drop", 0.55));

// building blocks: a cube, a cylinder and a triangle block stack into a tower
const K_SHAPES = cover("20 4 120 94", rect("m", 40, 62, 34, 34, 4) + rect("s", 76, 62, 44, 34, 4, "drop", 0.15) +
  group(rect("s", 52, 34, 30, 28, 3) + ell("s", 67, 34, 15, 5) , "drop", 0.35) + poly("m", [[86, 62], [116, 62], [101, 32]], "drop", 0.5) + poly("s", [[56, 34], [78, 34], [67, 10]], "drop", 0.7));

// ---- 1st grade -------------------------------------------------------------------------------------------------------

/** a domino half with n pips */
const pips = (x: number, y: number, n: number) => {
  const P: Record<number, [number, number][]> = { 1: [[0, 0]], 2: [[-1, -1], [1, 1]], 3: [[-1, -1], [0, 0], [1, 1]], 4: [[-1, -1], [1, -1], [-1, 1], [1, 1]], 5: [[-1, -1], [1, -1], [0, 0], [-1, 1], [1, 1]], 6: [[-1, -1], [1, -1], [-1, 0], [1, 0], [-1, 1], [1, 1]] };
  return P[n]!.map(([a, b]) => circ("f", x + a * 11, y + b * 11, 4.5)).join("");
};
// a domino: 3 and 4 make 7; it tips over to show its pips
const G1_ADD = cover("22 10 116 80", group(rect("s", 24, 14, 112, 72, 12) + line("o", 80, 22, 80, 78) + pips(52, 50, 3) + pips(108, 50, 4), "pop", 0));

// a crayon measured with paper clips laid end to end
const clip = (x: number, y: number, d: number) => path("o", `M${x} ${y} h20 a5 5 0 0 1 0 10 h-18 a3.5 3.5 0 0 1 0 -7 h14`, "rise", d);
const G1_MEASURE = cover("4 20 152 66", poly("m", [[10, 26], [114, 26], [134, 38], [114, 50], [10, 50]]) + poly("s", [[114, 26], [134, 38], [114, 50]]) + rect("s", 10, 26, 22, 24, 4) +
  [0, 1, 2, 3, 4].map(i => clip(10 + i * 26, 64, 0.2 + i * 0.12)).join(""));

// a clipboard with tally marks: four and a fifth across
const G1_DATA = cover("36 4 88 94", rect("s", 40, 12, 80, 84, 8) + rect("m", 64, 6, 32, 14, 4) + rect("e", 50, 26, 60, 62, 4) +
  [0, 1, 2, 3].map(i => line("o", 62 + i * 8, 36, 62 + i * 8, 62, "rise", 0.1 + i * 0.12)).join("") + line("k2", 56, 58, 96, 40, "rise", 0.65) +
  [0, 1].map(i => line("o", 62 + i * 8, 68, 62 + i * 8, 82, "rise", 0.8 + i * 0.12)).join(""));

// ---- 2nd grade -------------------------------------------------------------------------------------------------------

// crayons: a big box of a hundred, two packs of ten and three loose ones
const crayon = (x: number, y: number, c = "m", a = "", d = 0) => group(rect(c, x, y + 8, 8, 40, 2) + poly(c, [[x, y + 8], [x + 8, y + 8], [x + 4, y]]), a, d);
const G2_PLACE = cover("4 12 152 84", Array.from({ length: 6 }, (_, i) => crayon(10 + i * 9.6, 14, "s")).join("") + rect("m", 6, 34, 62, 60, 6) + rect("s", 12, 46, 50, 24, 4) +
  [0, 1].map(i => group(rect("s", 76 + i * 22, 34, 18, 60, 4) + rect("m", 76 + i * 22, 58, 18, 12, 2), "drop", 0.15 + i * 0.15)).join("") +
  [0, 1, 2].map(i => crayon(124 + i * 11, 44, "m", "drop", 0.5 + i * 0.12)).join(""));

// a piggy bank, and coins drop in
const G2_ADD = cover("12 4 136 92", path("s", "M36 56 C36 36 56 26 80 26 C108 26 124 40 124 60 C124 78 108 88 80 88 C54 88 36 78 36 56 Z") + rect("s", 52, 82, 12, 12, 3) + rect("s", 96, 82, 12, 12, 3) +
  ell("s", 30, 56, 9, 11) + circ("f", 102, 46, 3) + rect("f", 70, 26, 22, 4, 2) + poly("s", [[56, 32], [62, 16], [72, 28]]) +
  circ("m", 81, 14, 8, "drop", 0.2) + circ("m", 81, 14, 8, "drop", 0.55));

// a muffin tray: three rows of four
const G2_MULT = cover("8 14 144 76", rect("s", 10, 16, 140, 72, 10) +
  [0, 1, 2].map(r => [0, 1, 2, 3].map(c => circ("m", 32 + c * 32, 32 + r * 20, 8, "pop", 0.1 + r * 0.25 + c * 0.05)).join("")).join(""));

// a house made of shapes: a square, a triangle roof, a rectangle door, a circle window
const G2_SHAPES = cover("30 4 100 94", rect("s", 42, 44, 76, 52, 3) + poly("m", [[34, 46], [126, 46], [80, 8]], "drop", 0.1) +
  rect("m", 70, 62, 20, 34, 3, "pop", 0.35) + circ("e", 100, 60, 8, "pop", 0.5) + rect("e", 50, 54, 14, 14, 2, "pop", 0.6));

// ---- 3rd grade -------------------------------------------------------------------------------------------------------

// an abacus: each wire is a place; the beads slide over to show the number
const G3_PLACE = cover("6 6 148 88", rect("o", 10, 10, 140, 80, 8) + [0, 1, 2].map(r => line("k", 10, 28 + r * 22, 150, 28 + r * 22)).join("") +
  ([[3, 4], [2, 6], [5, 2]] as const).map(([n, m], r) =>
    Array.from({ length: n }, (_, i) => ell("m", 26 + i * 14, 28 + r * 22, 6, 8, "slide", 0.1 + r * 0.2 + i * 0.04)).join("") +
    Array.from({ length: m }, (_, i) => ell("s", 140 - i * 14, 28 + r * 22, 6, 8)).join("")).join(""));

// a clock: the minute hand comes round to the time
const G3_MEASURE = cover("30 2 100 96", circ("s", 80, 50, 44) + circ("e", 80, 50, 36) +
  Array.from({ length: 12 }, (_, i) => { const a = deg(i * 30); return line("k", 80 + 36 * Math.cos(a), 50 + 36 * Math.sin(a), 80 + (i % 3 ? 32 : 28) * Math.cos(a), 50 + (i % 3 ? 32 : 28) * Math.sin(a)); }).join("") +
  path("f", band([[80, 50], [80 + 18 * Math.cos(deg(-150)), 50 + 18 * Math.sin(deg(-150))]], 5)) +
  `<g data-a="sweep" style="--d:0.1s;transform-origin:80px 50px">${path("f", band([[80, 50], [80 + 28 * Math.cos(deg(0)), 50 + 28 * Math.sin(deg(0))]], 4))}</g>` + circ("m", 80, 50, 5));

// three jars of sorted marbles, filled to different heights
const jar = (x: number, h: number, d: number) => path("mf", `M${x + 4} ${92 - h} H${x + 32} V88 Q${x + 32} 92 ${x + 28} 92 H${x + 8} Q${x + 4} 92 ${x + 4} 88 Z`, "fill", d) +
  path("o", `M${x} 26 H${x + 36} M${x + 4} 30 V88 Q${x + 4} 92 ${x + 8} 92 H${x + 28} Q${x + 32} 92 ${x + 32} 88 V30`) + rect("s", x, 20, 36, 8, 3);
const G3_DATA = cover("14 16 132 80", jar(18, 34, 0.1) + jar(62, 58, 0.3) + jar(106, 22, 0.5));

// a kite: four sides, two pairs of equal sides, with its tail
const G3_SHAPES = cover("30 2 110 96", poly("s", [[70, 6], [100, 34], [70, 76], [40, 34]]) + path("m", "M70 6 L100 34 L70 34 Z") + path("m", "M70 34 L40 34 L70 76 Z") +
  line("o", 70, 6, 70, 76) + line("o", 40, 34, 100, 34) +
  path("o", "M70 76 C76 84 92 78 98 86 C104 94 120 88 126 94", "rise", 0.3) + [[88, 80], [112, 89]].map(([x, y], i) => poly("m", [[x!, y! - 5], [x! + 5, y!], [x!, y! + 5], [x! - 5, y!]], "pop", 0.5 + i * 0.15)).join(""));

// ---- 4th grade -------------------------------------------------------------------------------------------------------

// a chocolate bar: rows times columns of pieces, its wrapper slides off
const G4_WHOLE = cover("6 14 148 74", rect("m", 10, 18, 120, 68, 6) +
  [1, 2, 3].map(i => line("o", 10, 18 + i * 17, 130, 18 + i * 17)).join("") + [1, 2, 3, 4, 5].map(i => line("o", 10 + i * 20, 18, 10 + i * 20, 86)).join("") +
  group(rect("s", 70, 16, 82, 72, 6) + line("k", 82, 16, 82, 88), "", 0, ` class="cv-wrap"`));

// measuring cups: a whole, a half and a quarter, by size, each handle clear of the next cup
const cup = (x: number, w: number, h: number, c: string, d: number) => group(path(c, `M${x} ${92 - h} H${x + w} L${x + w - 4} 92 H${x + 4} Z`) + path("o", `M${x + w} ${92 - h + 6} h${w * 0.35} v8 h-${w * 0.35 + 2}`), "drop", d);
const G4_FRAC = cover("2 22 158 74", cup(6, 46, 54, "m", 0) + cup(78, 34, 40, "m", 0.2) + cup(130, 20, 28, "s", 0.4));

// a tape measure: the tape pulls out of its case
const G4_MEASURE = cover("4 20 152 68", rect("s", 70, 54, 84, 18, 3, "slide", 0.1) +
  Array.from({ length: 9 }, (_, i) => line("k", 80 + i * 9, 54, 80 + i * 9, i % 2 ? 62 : 66, "slide", 0.1)).join("") +
  rect("m", 8, 24, 68, 62, 14) + circ("s", 42, 55, 14) + rect("f", 150, 50, 6, 26, 2, "slide", 0.1));

// railway tracks: two parallel rails, and a road crossing them
const G4_LINES = cover("4 6 152 90", path("e", band([[4, 70], [156, 30]], 30)) +
  Array.from({ length: 7 }, (_, i) => { const x = 18 + i * 21; const y = 70 - (x - 4) * 40 / 152; return path("s", band([[x - 6, y - 22], [x + 6, y + 22]], 6)); }).join("") +
  line("o", 4, 58, 156, 18, "rise", 0) + line("o", 4, 82, 156, 42, "rise", 0.2));

// ---- 6th grade -------------------------------------------------------------------------------------------------------

// a building with floors above the ground and floors below it: numbers on both sides of zero
const G6_NUMBER = cover("26 4 108 94", rect("s", 50, 8, 60, 50, 4) + rect("g", 50, 58, 60, 36, 4) + line("gl", 28, 58, 132, 58) +
  [0, 1].map(r => [0, 1, 2].map(c => rect("e", 58 + c * 16, 16 + r * 20, 12, 12, 2)).join("")).join("") +
  rect("m", 70, 64, 20, 22, 3, "drop", 0.2) + [0, 1, 2].map(i => line("k", 36, 64 + i * 10, 46, 64 + i * 10)).join(""));

// a balance: the same on both sides
const G6_EXPR = cover("8 10 144 86", poly("s", [[80, 30], [66, 90], [94, 90]]) + rect("s", 56, 88, 48, 8, 3) + path("f", band([[20, 30], [140, 30]], 5)) +
  path("o", "M20 30 L10 56 H42 Z") + path("o", "M140 30 L118 56 H150 Z") + rect("m", 14, 42, 22, 14, 3, "drop", 0.1) + rect("m", 124, 42, 10, 14, 3, "drop", 0.3) + rect("m", 136, 42, 10, 14, 3, "drop", 0.45));

// a box, open: the faces you measure
const G6_GEO = cover("14 6 132 90", poly("s", [[24, 40], [104, 40], [104, 92], [24, 92]]) + poly("m", [[104, 40], [136, 22], [136, 74], [104, 92]]) +
  poly("e", [[24, 40], [104, 40], [136, 22], [56, 22]]) + poly("s", [[24, 40], [56, 22], [44, 8], [12, 26]], "grow", 0.1) + poly("s", [[104, 40], [136, 22], [146, 36], [114, 54]], "grow", 0.3));

// water bottles filled to different levels, and the level they'd all share
const bottle = (x: number, h: number, d: number) => path("mf", `M${x} ${92 - h} H${x + 20} V88 Q${x + 20} 92 ${x + 16} 92 H${x + 4} Q${x} 92 ${x} 88 Z`, "fill", d) +
  path("o", `M${x + 6} 20 V28 Q${x} 32 ${x} 40 V88 Q${x} 92 ${x + 4} 92 H${x + 16} Q${x + 20} 92 ${x + 20} 88 V40 Q${x + 20} 32 ${x + 14} 28 V20`) + rect("s", x + 4, 14, 12, 8, 2);
const G6_STATS = cover("8 10 144 86", [[44], [30], [58], [36], [52]].map(([h], i) => bottle(12 + i * 28, h!, 0.1 + i * 0.12)).join("") + path("dots", "M8 48 H152", "rise", 0.9));

// ---- 7th grade -------------------------------------------------------------------------------------------------------

// a picture and its enlargement: every length grows by the same factor; both trees sit inside their frames
const tree = (x: number, s: number, c: string, a = "", d = 0) => group(rect("s", x - 3 * s, 92 - 16 * s, 6 * s, 16 * s, 2) + circ(c, x, 92 - 26 * s, 14 * s), a, d);
const G7_PROP = cover("8 4 148 92", rect("o", 10, 56, 44, 40, 4) + tree(32, 0.8, "m") + rect("o", 70, 8, 84, 88, 6) + tree(112, 1.76, "m", "grow", 0.2));

// a hanging mobile: it balances when both sides weigh the same
const G7_EXPR = cover("14 4 132 92", line("k", 80, 4, 80, 18) + path("f", band([[30, 20], [130, 20]], 4)) + line("k", 36, 20, 36, 46) + line("k", 124, 20, 124, 46) +
  group(rect("m", 22, 46, 28, 26, 4) + rect("m", 26, 72, 20, 20, 4), "drop", 0.1) + group(circ("m", 124, 60, 14) + rect("m", 112, 74, 24, 18, 4), "drop", 0.3));

// a can: a circle that runs up into a cylinder
const G7_GEO = cover("40 4 80 94", rect("s", 46, 18, 68, 66, 4) + ell("s", 80, 84, 34, 9) + rect("m", 46, 36, 68, 30, 2) + ell("e", 80, 18, 34, 9, "pop", 0.1) + ell("o", 80, 18, 24, 5, "pop", 0.2));

// two dice, rolled
const die = (x: number, y: number, n: number, rot: number, d: number) => `<g transform="rotate(${rot} ${x + 20} ${y + 20})">${group(rect("s", x, y, 40, 40, 8) + (n === 5 ? [[-1, -1], [1, -1], [0, 0], [-1, 1], [1, 1]] : [[-1, -1], [0, 0], [1, 1]]).map(([a, b]) => circ("f", x + 20 + a! * 11, y + 20 + b! * 11, 4.2)).join(""), "drop", d)}</g>`;
const G7_PROB = cover("22 14 116 80", die(30, 40, 5, -12, 0) + die(86, 22, 3, 14, 0.25));

// ---- 8th grade -------------------------------------------------------------------------------------------------------

// a cube of little cubes: 3 by 3 by 3 is 3 cubed
const G8_EXP = (() => {
  const s = 18, dx = 9, dy = -9, x0 = 40, y0 = 40;
  let o = "";
  for (let i = 0; i < 3; i++) for (let j = 0; j < 3; j++) o += rect("m", x0 + i * s, y0 + j * s, s, s, 2);
  for (let i = 0; i < 3; i++) for (let k = 0; k < 3; k++) o += poly("s", [[x0 + i * s + k * dx, y0 + k * dy], [x0 + (i + 1) * s + k * dx, y0 + k * dy], [x0 + (i + 1) * s + (k + 1) * dx, y0 + (k + 1) * dy], [x0 + i * s + (k + 1) * dx, y0 + (k + 1) * dy]]);
  for (let j = 0; j < 3; j++) for (let k = 0; k < 3; k++) o += poly("s", [[x0 + 3 * s + k * dx, y0 + j * s + k * dy], [x0 + 3 * s + (k + 1) * dx, y0 + j * s + (k + 1) * dy], [x0 + 3 * s + (k + 1) * dx, y0 + (j + 1) * s + (k + 1) * dy], [x0 + 3 * s + k * dx, y0 + (j + 1) * s + k * dy]]);
  return cover("34 8 96 90", group(o, "pop", 0));
})();

// two candles burning down at different speeds: when are they the same height?
const candle = (x: number, h: number, d: number) => group(rect("s", x, 92 - h, 22, h, 3) + path("m", `M${x + 11} ${80 - h} C${x + 4} ${86 - h} ${x + 6} ${92 - h} ${x + 11} ${92 - h} C${x + 16} ${92 - h} ${x + 18} ${86 - h} ${x + 11} ${80 - h} Z`) + line("k", x + 11, 92 - h, x + 11, 88 - h), "shrinkdown", d);
const G8_LINEAR = cover("34 6 92 92", candle(48, 70, 0.1) + candle(92, 46, 0.1) + path("dots", "M40 62 H126", "rise", 1));

// a ladder against a wall: a right triangle with the ground
const G8_GEO = cover("20 4 124 92", rect("s", 112, 6, 24, 86, 3) + line("gl", 20, 92, 136, 92) +
  group(path("s", band([[36, 92], [112, 12]], 14)) + Array.from({ length: 6 }, (_, i) => { const t = (i + 0.7) / 6.6; return line("k", 36 + 76 * t - 5, 92 - 80 * t - 5, 36 + 76 * t + 5, 92 - 80 * t + 5); }).join(""), "rise", 0.1) +
  path("o", "M100 92 V80 H112"));

// ---- 9th grade -------------------------------------------------------------------------------------------------------

// a padlock and its key: find the one that opens it
const G9_EQ = cover("12 4 136 92", path("o", "M38 46 V30 C38 12 70 12 70 30 V46") + rect("m", 26, 44, 56, 46, 8) + circ("e", 54, 62, 5) + rect("e", 52, 64, 4, 12, 2) +
  group(circ("s", 124, 66, 14) + circ("e", 124, 66, 5) + rect("s", 80, 62, 32, 8, 3) + rect("s", 84, 70, 6, 8, 2) + rect("s", 94, 70, 6, 6, 2), "slide", 0.1));

// stacks of cups: each cup adds the same height
const G9_LINF = cover("8 6 144 90", [1, 2, 3, 4].map((n, i) =>
  Array.from({ length: n }, (_, k) => path(k === n - 1 ? "m" : "s", `M${14 + i * 36} ${92 - k * 14 - 30} H${42 + i * 36} L${38 + i * 36} ${92 - k * 14} H${18 + i * 36} Z`, "drop", 0.1 + i * 0.2 + k * 0.05)).join("")).join(""));

// a cell splitting: one becomes two becomes four
const cell = (x: number, y: number, r: number, c: string, a: string, d: number) => group(circ(c, x, y, r) + circ("s", x, y, r * 0.35), a, d);
const G9_EXP = cover("4 10 152 80", cell(22, 50, 14, "m", "pop", 0) + cell(62, 34, 12, "m", "pop", 0.3) + cell(62, 66, 12, "m", "pop", 0.3) +
  [0, 1, 2, 3].map(i => cell(112 + (i % 2) * 28, 22 + i * 19, 10, "m", "pop", 0.6 + i * 0.05)).join(""));

// a magnifying glass over a scatter of points: looking for the pattern
const G9_DATA = cover("6 4 150 92", ([[16, 82], [28, 70], [38, 74], [50, 60], [60, 64], [72, 50], [84, 52], [94, 40], [106, 42], [118, 30]] as const).map(([x, y], i) => circ("m", x, y, 4.5, "pop", i * 0.05)).join("") +
  group(circ("o", 90, 46, 24) + path("f", band([[107, 63], [134, 90]], 9)), "slide", 0.5));

// ---- 10th grade ------------------------------------------------------------------------------------------------------

// a street map on a grid, and a pin dropped on one corner (Review: a big pin, few streets)
const G10_COORD = cover("6 2 148 96", rect("s", 10, 10, 140, 84, 6) + [1, 2].map(i => path("e", band([[10, 10 + i * 28], [150, 10 + i * 28]], 8))).join("") +
  [1, 2, 3].map(i => path("e", band([[10 + i * 35, 10], [10 + i * 35, 94]], 8))).join("") +
  group(path("m", "M115 66 C98 48 98 20 115 20 C132 20 132 48 115 66 Z") + circ("e", 115, 34, 6), "drop", 0.2));

// a coat hanger: a triangle you know
const G10_ANGLES = cover("8 4 144 92", path("o", "M80 30 V20 C80 10 92 10 92 18") + poly("s", [[80, 30], [146, 82], [14, 82]]) + poly("e", [[80, 42], [128, 76], [32, 76]]) +
  path("m", "M80 30 L92 39 A16 16 0 0 1 68 39 Z", "pop", 0.3));

// a tree, the sun and the tree's shadow: a right triangle in the sky
const G10_TRIG = cover("4 2 152 94", circ("m", 136, 18, 12) + line("gl", 4, 88, 156, 88) + rect("s", 34, 40, 8, 48, 2) + circ("m", 38, 34, 18) +
  path("dots", "M38 16 L136 88", "rise", 0.2) + path("mf", band([[42, 88], [130, 88]], 6), "grow", 0.4) + path("o", "M42 76 H54 V88"));

// a fish tank filling: length, width and height
const G10_AREA = cover("10 6 140 90", path("mf", "M20 46 H120 V90 H20 Z", "fill", 0.1) + path("mf", "M120 46 L140 30 V74 L120 90 Z", "fill", 0.1) +
  poly("o", [[20, 30], [120, 30], [120, 90], [20, 90]]) + poly("o", [[120, 30], [140, 14], [140, 74], [120, 90]]) + poly("o", [[20, 30], [40, 14], [140, 14], [120, 30]]) +
  path("s", "M54 64 C62 56 76 56 84 64 C76 72 62 72 54 64 Z") + poly("s", [[54, 64], [46, 58], [46, 70]]));

// ---- 11th grade ------------------------------------------------------------------------------------------------------

// a pyramid of cans: 1, 2, 3, 4 a row
const can = (x: number, y: number, d: number) => group(rect("m", x, y, 24, 22, 3) + line("k", x, y + 6, x + 24, y + 6) + line("k", x, y + 16, x + 24, y + 16), "drop", d);
const G11_SEQ = cover("20 2 122 94", [4, 3, 2, 1].map((n, r) => Array.from({ length: n }, (_, i) => can(24 + r * 14 + i * 28, 70 - r * 22, 0.1 + r * 0.2 + i * 0.04)).join("")).join(""));

// a vending machine: put something in, one thing comes out
const G11_FUNC = cover("30 4 100 94", rect("s", 40, 8, 74, 86, 8) + rect("e", 48, 16, 40, 52, 4) +
  [0, 1, 2].map(r => [0, 1, 2].map(c => rect(r === 1 && c === 1 ? "m" : "s", 52 + c * 12, 20 + r * 16, 8, 12, 2)).join("")).join("") +
  rect("s", 94, 20, 12, 18, 3) + circ("m", 100, 30, 3, "drop", 0) + rect("e", 50, 76, 56, 12, 3) + rect("m", 66, 78, 16, 8, 2, "drop", 0.5));

// a compass: turning a quarter turn at a time
const G11_COMPLEX = cover("30 2 100 96", circ("s", 80, 50, 44) + circ("e", 80, 50, 36) +
  [0, 90, 180, 270].map(a => poly("s", [[80 + 30 * Math.cos(deg(a)), 50 + 30 * Math.sin(deg(a))], [80 + 6 * Math.cos(deg(a + 90)), 50 + 6 * Math.sin(deg(a + 90))], [80 + 6 * Math.cos(deg(a - 90)), 50 + 6 * Math.sin(deg(a - 90))]])).join("") +
  `<g data-a="sweep" style="--d:0.1s;transform-origin:80px 50px">${poly("m", [[80, 18], [86, 50], [74, 50]])}</g>` + circ("m", 80, 50, 5));

// a spinner: the arrow spins and stops in one part
const G11_PROB = cover("30 2 100 96", path("m", wedge(80, 50, 40, -90, 30)) + path("s", wedge(80, 50, 40, 30, 150)) + path("e", wedge(80, 50, 40, 150, 270)) +
  `<g data-a="spin" style="--d:0s;transform-origin:80px 50px;transform-box:view-box">${path("f", band([[80, 50], [100, 24]], 5))}${poly("f", [[104, 18], [92, 24], [102, 30]])}</g>` + circ("s", 80, 50, 6));

// ---- 12th grade ------------------------------------------------------------------------------------------------------

// a Ferris wheel: round and round, up and down
const G12_TRIG = (() => {
  const cars = Array.from({ length: 6 }, (_, i) => { const a = deg(i * 60 - 90); return rect(i === 1 ? "m" : "s", 80 + 34 * Math.cos(a) - 7, 44 + 34 * Math.sin(a) - 2, 14, 12, 3); }).join("");
  return cover("30 2 100 96", poly("s", [[80, 44], [56, 94], [62, 94], [80, 54], [98, 94], [104, 94]]) +
    `<g data-a="spin" style="--d:0s;transform-origin:80px 44px;transform-box:view-box">${circ("o", 80, 44, 34)}${Array.from({ length: 6 }, (_, i) => { const a = deg(i * 60 - 90); return line("k", 80, 44, 80 + 34 * Math.cos(a), 44 + 34 * Math.sin(a)); }).join("")}</g>` + cars + circ("m", 80, 44, 5));
})();

// a sailboat pushed by the wind: arrows that add
const G12_VEC = cover("4 4 152 92", path("s", "M30 70 H120 L108 86 H42 Z") + line("k", 74, 14, 74, 70) + poly("m", [[78, 16], [112, 64], [78, 64]]) + poly("s", [[70, 22], [70, 64], [42, 64]]) +
  group(path("f", band([[8, 24], [36, 24]], 4)) + poly("f", [[36, 18], [46, 24], [36, 30]]) + path("f", band([[8, 40], [28, 40]], 4)) + poly("f", [[28, 34], [38, 40], [28, 46]]), "slide", 0.1) +
  path("dots", "M4 92 C30 86 50 96 80 90 C110 84 130 94 156 88"));

export const COVERS2: Record<string, string> = {
  "0:Adding and subtracting": K_ADD,
  "0:Shapes and measuring": K_SHAPES,
  "1:Adding and subtracting": G1_ADD,
  "1:Measurement and shapes": G1_MEASURE,
  "1:Data": G1_DATA,
  "2:Place value": G2_PLACE,
  "2:Adding and subtracting": G2_ADD,
  "2:Getting ready to multiply": G2_MULT,
  "2:Shapes": G2_SHAPES,
  "3:Place value": G3_PLACE,
  "3:Measurement": G3_MEASURE,
  "3:Data": G3_DATA,
  "3:Shapes": G3_SHAPES,
  "4:Whole numbers": G4_WHOLE,
  "4:Fractions": G4_FRAC,
  "4:Measurement": G4_MEASURE,
  "4:Lines and shapes": G4_LINES,
  "6:Number system": G6_NUMBER,
  "6:Expressions and equations": G6_EXPR,
  "6:Geometry": G6_GEO,
  "6:Statistics": G6_STATS,
  "7:Proportions and percents": G7_PROP,
  "7:Expressions and equations": G7_EXPR,
  "7:Geometry": G7_GEO,
  "7:Probability": G7_PROB,
  "8:Exponents and roots": G8_EXP,
  "8:Linear equations": G8_LINEAR,
  "8:Geometry": G8_GEO,
  "9:Equations": G9_EQ,
  "9:Linear functions": G9_LINF,
  "9:Exponents": G9_EXP,
  "9:Data": G9_DATA,
  "10:Coordinate geometry": G10_COORD,
  "10:Angles and triangles": G10_ANGLES,
  "10:Right triangles and trig": G10_TRIG,
  "10:Area and volume": G10_AREA,
  "11:Sequences": G11_SEQ,
  "11:Functions": G11_FUNC,
  "11:Complex numbers": G11_COMPLEX,
  "11:Probability": G11_PROB,
  "12:Trigonometry": G12_TRIG,
  "12:Vectors and series": G12_VEC,
};
