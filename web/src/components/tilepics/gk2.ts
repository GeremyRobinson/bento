import { L, R, svg } from "./draw";

/** a ten frame (2 rows of 5) with its first `n` cells filled */
const frame = (x: number, y: number, n: number) => Array.from({ length: 10 }, (_, i) => R(x + (i % 5) * 15, y + 22 + Math.floor(i / 5) * 28, 12, 24, 4, i < n ? "take" : "rest")).join("");

export const LESSON_k2: Record<string, string> = {};
export const CHAPTER_k2: Record<string, string> = {
  // a hundred, two tens and three ones (the blocks the place-value lessons count with)
  "2:Place value": svg("0 0 150 96", R(2, 2, 92, 92, 6) + [1, 2, 3, 4].map(k => L(2, 2 + k * 18.4, 94, 2 + k * 18.4, "thin") + L(2 + k * 18.4, 2, 2 + k * 18.4, 94, "thin")).join("") + R(104, 2, 12, 92, 4) + R(122, 2, 12, 92, 4) + R(140, 60, 9, 9, 2) + R(140, 72, 9, 9, 2) + R(140, 84, 9, 9, 2)),
  // two ten frames: one full (a ten), two more in the next: regrouping makes a ten first
  "2:Adding and subtracting": svg("0 0 156 96", frame(2, 0, 10) + frame(80, 0, 2)),
  // a bar graph
  "2:Measurement and data": svg("0 0 130 96", R(10, 46, 24, 46, 4) + R(42, 18, 24, 74, 4, "take") + R(74, 58, 24, 34, 4) + R(106, 34, 22, 58, 4) + L(2, 94, 128, 94)),
  // an array: rows of the same number
  "2:Getting ready to multiply": svg("0 0 130 96", [0, 1, 2].map(r => [0, 1, 2, 3].map(c => `<circle class="dot" cx="${16 + c * 33}" cy="${16 + r * 32}" r="11"/>`).join("")).join("")),
  // flat shapes: a triangle, a square cut into equal halves, a hexagon
  "2:Shapes": svg("0 0 170 96", `<polygon points="2,88 50,88 26,8"/>` + R(60, 34, 54, 54, 6) + R(60, 34, 27, 54, 6, "take") + `<polygon points="138,30 158,30 168,59 158,88 138,88 128,59"/>`),
};
