import { L, R, svg } from "./draw";

const grid = (x: number, y: number, n: number, s: number) => R(x, y, n * s, n * s, 4) + Array.from({ length: n - 1 }, (_, i) => L(x + (i + 1) * s, y, x + (i + 1) * s, y + n * s, "thin") + L(x, y + (i + 1) * s, x + n * s, y + (i + 1) * s, "thin")).join("");
const axes = L(10, 4, 10, 92, "thin") + L(4, 86, 150, 86, "thin");

export const LESSON_68: Record<string, string> = {};
export const CHAPTER_68: Record<string, string> = {
  // square numbers: 1, 4, 9 as squares (a power is repeated multiplying; a root is the square's side)
  "8:Exponents and roots": svg("0 0 150 96", grid(2, 70, 1, 22) + grid(34, 48, 2, 22) + grid(88, 26, 3, 20)),
  // a line and its slope: up so many for each step across
  "8:Functions and slope": svg("0 0 156 96", axes + L(14, 80, 150, 12) + `<path class="brk" d="M50 62 L104 62 L104 35"/>` + `<circle class="dot" cx="50" cy="62" r="6"/><circle class="dot" cx="104" cy="35" r="6"/>`),
  // two lines crossing: the one point on both is the answer
  "8:Linear equations": svg("0 0 156 96", axes + L(14, 80, 150, 16) + L(14, 22, 150, 76) + `<circle class="dot" cx="${82}" cy="${49}" r="8"/>`),
  // a right triangle with a square on each side
  "8:Geometry": svg("22 0 88 96", `<polygon points="80,58 50,34 74,4 104,28"/><polygon points="26,34 50,34 50,58 26,58"/><polygon points="50,58 80,58 80,88 50,88"/><polygon class="take" points="50,58 80,58 50,34"/>`),
};
