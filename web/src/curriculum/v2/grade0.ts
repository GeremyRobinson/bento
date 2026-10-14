// Kindergarten in v2 (curriculum/specs/v2/gradeK-1.md, signed off by Review 2026-10-13): what each lesson builds on,
// and its skill check. The rare check items are built directly when the draws don't find one (Review note 1).
import { type CheckRecipe, i } from "../check-kit";

export const depends: Record<string, string[]> = {
  "k-count20": [],
  "k-write": ["k-count20"],
  "k-teens": ["k-count20", "k-write"],
  "k-compare": ["k-count20"],
  "k-tens": ["k-count20"],
  "k-add": ["k-count20"],
  "k-sub": ["k-add", "k-count20"],
  "k-story": ["k-add", "k-sub"],
  "k-bonds": ["k-add"],
  "k-make10": ["k-bonds"],
  "k-shapes": [],
  "k-solids": ["k-shapes"],
  "k-length": ["k-compare"],
  "k-sort": ["k-compare", "k-shapes"],
};

export const checks: Record<string, CheckRecipe> = {
  "k-count20": { items: [i(3, { where: p => p.n <= 14 }), i(3, { where: p => p.n >= 17 }), i(3, { where: p => p.n === 20, fix: () => ({ n: 20 }) }), i(3)] },
  // the look-alike digits, swapped teen digits, and the two tens; the "Pick how it's written" tap stays
  "k-write": {
    items: [
      i(4, { where: p => [2, 5, 6, 9].includes(p.n) }), i(7, { where: p => p.n >= 12 && p.n <= 19 }), i(7, { where: p => p.n >= 12 && p.n <= 19 }),
      i(8, { where: p => p.n === 10 || p.n === 20, fix: p => ({ n: p.n > 10 ? 20 : 10 }) }),
    ],
  },
  "k-teens": { items: [i(3, { where: p => p.ones <= 3 }), i(3, { where: p => p.ones >= 6 }), i(3, { where: p => p.ones >= 6 }), i(3)] },
  "k-compare": {
    items: [i(3, { where: p => p.top > p.bottom }), i(3, { where: p => p.top < p.bottom }), i(3, { where: p => p.top === p.bottom }), i(3, { where: p => Math.abs(p.top - p.bottom) === 1 })],
  },
  "k-tens": {
    items: [i(3, { where: p => p.rows <= 5 }), i(3, { where: p => p.rows >= 6 && p.rows <= 9 }), i(3, { where: p => p.rows >= 6 && p.rows <= 9 }), i(3, { where: p => p.rows === 10, fix: () => ({ rows: 10 }) })],
  },
  "k-add": { items: [i(3, { where: p => p.b >= 3 }), i(3, { where: p => p.a < p.b }), i(3, { where: p => p.a + p.b >= 7 }), i(3)] },
  "k-sub": { items: [i(3, { where: p => p.b >= 4 }), i(3, { where: p => p.a - p.b === 1 || p.a - p.b === 2 }), i(3, { where: p => p.b === p.a }), i(3)] },
  // the display is already the story, so no item asks it as one; the "More or fewer?" tap stays
  "k-story": {
    items: [i(3, { where: p => p.take === 0 }), i(3, { where: p => p.take === 1 }), i(3, { where: p => p.take === 1 && p.b >= 3 }), i(3, { where: p => p.take === 0 && p.tale === 1 })],
  },
  "k-bonds": { items: [i(3), i(3, { where: p => p.whole >= 7 }), i(3, { where: p => p.whole >= 7 }), i(3, { where: p => p.part > p.whole - p.part })] },
  "k-make10": { items: [i(3, { where: p => p.have <= 4 }), i(3, { where: p => p.have >= 5 && p.have <= 7 }), i(3, { where: p => p.have >= 8 }), i(3)] },
  // a turned triangle, a turned square, the rectangle and the hexagon; the "Name the shape" tap stays
  "k-shapes": {
    items: [i(3, { where: p => p.shape === 1 && p.turn !== 0 }), i(3, { where: p => p.shape === 2 && p.turn !== 0 }), i(3, { where: p => p.shape === 3 }), i(3, { where: p => p.shape === 4 })],
  },
  // a cylinder on its side, a cone, a cube drawn as a real thing, a sphere
  "k-solids": {
    items: [
      i(3, { where: p => p.shape === 2 && p.turn === 2, fix: () => ({ shape: 2, thing: -1, turn: 2 }) }),
      i(4, { where: p => p.shape === 3 }), i(5, { where: p => p.shape === 0 }), i(6, { where: p => p.shape === 1 }),
    ],
  },
  "k-length": { items: [i(3, { where: p => p.a > p.b }), i(3, { where: p => p.a < p.b }), i(3, { where: p => p.a === p.b }), i(3, { where: p => Math.abs(p.a - p.b) === 1 })] },
  // the index picks the question: 3 and 7 ask for the fewest, 4 for the most
  "k-sort": { items: [i(3), i(4), i(5, { where: p => p.by === 1 }), i(7)] },
};
