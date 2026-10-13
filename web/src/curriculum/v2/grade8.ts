// Grade 8 in v2 (curriculum/specs/v2/grade8.md, signed off by Review 2026-10-13): what each lesson builds on, and its skill check.
import { type CheckRecipe, i } from "../check-kit";

/** g8-exp: adding and multiplying the exponents give different answers (not a = b = 2) */
const tellsApart = (p: { a: number; b: number }) => p.a * p.b !== p.a + p.b;
/** g8-slope: a run of 1 makes the slope equal the rise (Review note 4) */
const runOf = (p: { x1: number; x2: number }) => p.x2 - p.x1;

export const depends: Record<string, string[]> = {
  "g8-exp": ["g6-expo"],
  "g8-sci": ["g5-pow10", "g6-expo"],
  "g8-roots": ["g6-expo"],
  "g8-func": ["g6-eval", "g7-mulint"],
  "g8-slope": ["g7-subint", "g7-mulint"],
  "g8-intercept": ["g8-slope", "g8-func"],
  "g8-both": ["g7-eq"],
  "g8-system": ["g7-distribute", "g6-onestep"],
  "g8-pyth": ["g8-roots"],
  "g8-leg": ["g8-pyth"],
  "g8-cyl": ["g7-circarea", "g5-volume"],
  "g8-cone": ["g8-cyl"],
  "g8-translate": ["g7-addint", "g7-subint"],
  "g8-tri": ["g7-angles"],
};

export const checks: Record<string, CheckRecipe> = {
  // item 2: a ≥ 3, so dividing the exponents never lands on the answer and 2^a isn't 2 × a (Review note 3)
  "g8-exp": {
    items: [
      i(3, { where: p => p.t === 0 && tellsApart(p) }), i(3, { where: p => p.t === 1 && p.a >= 3 }),
      i(3, { where: p => p.t === 2 && tellsApart(p) }), i(3, { where: tellsApart }),
    ],
  },
  // a whole front number (c a multiple of 10) is rare, so when the draws miss it, round c to one (Review note 2)
  "g8-sci": {
    items: [
      i(3, { where: p => p.e <= 4 }), i(3, { where: p => p.e >= 6 }),
      i(3, { where: p => p.c % 10 === 0, fix: p => ({ c: 10 * Math.min(9, Math.max(2, Math.round(p.c / 10))), e: p.e }) }), i(3),
    ],
  },
  "g8-roots": { items: [i(3, { where: p => !p.cube && p.n >= 3 && p.n <= 9 }), i(3, { where: p => !p.cube && p.n >= 10 }), i(3, { where: p => p.cube }), i(3, { where: p => p.cube && p.n >= 4 })] },
  "g8-func": { items: [i(3, { where: p => p.x > 0 && p.b < 0 }), i(3, { where: p => p.x < 0 }), i(3, { where: p => p.a < 0 && p.x < 0 }), i(3, { where: p => p.x !== 0 })] },
  // a slope of ±1 or a run of 1 hides flipping rise and run (Review note 4)
  "g8-slope": {
    items: [
      i(3, { where: p => p.m >= 2 && runOf(p) >= 2 }), i(3, { where: p => p.m <= -2 && runOf(p) >= 2 }),
      i(3, { where: p => (p.x1 < 0 || p.y1 < 0) && runOf(p) >= 2 }), i(3, { where: p => runOf(p) >= 2 }),
    ],
  },
  // b ≠ m everywhere, so swapping them shows
  "g8-intercept": {
    items: [
      i(3, { where: p => p.b !== p.m && p.m > 0 && p.x0 > 0 }), i(3, { where: p => p.b !== p.m && p.m * p.x0 < 0 }),
      i(3, { where: p => p.b !== p.m && p.m < 0 && p.x0 < 0 }), i(3, { where: p => p.b !== p.m && p.b < 0 }),
    ],
  },
  // item 2 is the one-x case; item 4 keeps a divide step (Review note 6)
  "g8-both": {
    items: [
      i(3, { where: p => p.a - p.c >= 2 }), i(3, { where: p => p.a - p.c === 1 }),
      i(3, { where: p => p.c >= 2 && p.a - p.c >= 2 }), i(3, { where: p => p.x >= 6 && p.a - p.c >= 2 }),
    ],
  },
  "g8-system": { items: [i(3, { where: p => p.k <= 3 }), i(3, { where: p => p.k >= 4 }), i(3, { where: p => p.x >= 6 }), i(3)] },
  "g8-pyth": { items: [i(3, { where: p => p.c <= 10 }), i(3, { where: p => p.c >= 13 }), i(3, { where: p => p.c >= 13 }), i(3)] },
  "g8-leg": { items: [i(3, { where: p => p.c <= 10 }), i(3, { where: p => p.c >= 13 }), i(3, { where: p => p.c >= 13 }), i(3)] },
  // r ≥ 3 everywhere: r = 2 lets 2 × r land on r², and r = 1 makes squaring free (Review note 5)
  "g8-cyl": { items: [i(3, { where: p => p.r >= 3 }), i(3, { where: p => p.r >= 3 }), i(3, { where: p => p.h >= 6 && p.r >= 3 }), i(3, { where: p => p.r >= 3 })] },
  "g8-cone": { items: [i(3, { where: p => p.r >= 3 }), i(3, { where: p => p.r >= 3 }), i(3, { where: p => p.r >= 3 }), i(3, { where: p => p.r >= 3 })] },
  "g8-translate": {
    items: [
      i(3, { where: p => p.dx > 0 && p.dy < 0 }), i(3, { where: p => p.dx < 0 && p.dy > 0 }),
      i(3, { where: p => p.dx < 0 && p.dy < 0 }), i(3, { where: p => p.x * p.x2 < 0 || p.y * p.y2 < 0 }),
    ],
  },
  "g8-tri": { items: [i(3, { where: p => p.a + p.b < 90 }), i(3, { where: p => p.a + p.b >= 120 }), i(3), i(3)] },
};
