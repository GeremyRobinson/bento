// 6th grade in v2 (curriculum/specs/v2/grade6.md, signed off by Review 2026-10-13): what each lesson builds on, and its skill check.
import { type CheckRecipe, gcd, i } from "../check-kit";

/** g6-divide: more than one c/d fits in a/b */
const more = (p: { a: number; b: number; c: number; d: number }) => p.a * p.d > p.b * p.c;
/** g6-lcm: a and b share a factor, and b is not a multiple of a (like 4 and 6) */
const shareNotMultiple = (p: { a: number; b: number }) => gcd(p.a, p.b) > 1 && p.b % p.a !== 0;

export const depends: Record<string, string[]> = {
  "g6-ratio": ["g4-equiv", "g3-divfacts"],
  "g6-rate": ["g4-divide", "g4-partial"],
  "g6-pctof": ["g5-fracof", "g4-divide"],
  "g6-pctwhole": ["g6-pctof"],
  "g6-divide": ["g5-unitdiv", "g5-multfrac"],
  "g6-lcm": ["g4-factors"],
  "g6-gcf": ["g4-factors", "g3-split"],
  // negative numbers first appear here, and the counting is small
  "g6-numline": [],
  "g6-expo": ["g5-order", "g3-facts"],
  "g6-eval": ["g5-order", "g3-facts"],
  "g6-onestep": ["g6-eval", "g3-divfacts"],
  "g6-tri": ["g4-area", "g4-mult2x2"],
  "g6-trap": ["g6-tri", "g4-mult2x2"],
  "g6-mean": ["g4-divide", "g3-addsub"],
};

export const checks: Record<string, CheckRecipe> = {
  "g6-ratio": { items: [i(3), i(3, { where: p => p.k >= 5 }), i(3, { where: p => p.a > p.b }), i(3)] },
  "g6-rate": { items: [i(3), i(3, { where: p => p.n >= 5 }), i(3, { where: p => p.m < p.n }), i(3, { where: p => p.u >= 10 })] },
  // 10% and 25% make the second step "1 × …"; W is a multiple of 20, so 75% of it is whole (Review note 1)
  "g6-pctof": {
    items: [
      i(0, { where: p => p.p === 75, fix: p => ({ ...p, p: 75 }) }), i(0, { where: p => [20, 30, 40].includes(p.p) }),
      i(0, { where: p => [60, 70, 80, 90].includes(p.p) }), i(0, { where: p => p.p !== 10 && p.p !== 25 }),
    ],
  },
  "g6-pctwhole": { items: [i(3, { where: p => p.p === 10 }), i(3, { where: p => p.p === 20 }), i(3, { where: p => p.p === 25 }), i(3, { where: p => p.p === 50 })] },
  "g6-divide": { items: [i(0), i(3, { where: p => p.c > 1 && more(p) }), i(3, { where: p => !more(p) }), i(3, { where: more, story: true })] },
  "g6-lcm": {
    items: [
      i(0, { where: shareNotMultiple }), i(0, { where: p => gcd(p.a, p.b) === 1 }), i(0, { where: p => p.b % p.a === 0 }), i(0, { where: shareNotMultiple }),
    ],
  },
  // when g is 4, 6, 8 or 9 a smaller common factor also works, so the check sees whether the child finds the greatest
  "g6-gcf": { items: [i(3, { where: p => [4, 6, 8, 9].includes(p.g) }), i(3, { where: p => p.m === 1 || p.n === 1 }), i(3), i(3)] },
  "g6-numline": { items: [i(3), i(3), i(3, { where: p => -p.a >= 7 && p.b >= 7 }), i(3, { where: p => -p.a > p.b })] },
  // never 2²: there the slip "base × exponent" gives the right answer
  "g6-expo": {
    items: [
      i(3, { where: p => p.n === 3 }), i(3, { where: p => p.n === 2 && p.a >= 3 }),
      i(3, { where: p => !(p.a === 2 && p.n === 2) }), i(3, { where: p => !(p.a === 2 && p.n === 2) }),
    ],
  },
  "g6-eval": { items: [i(3), i(3), i(3), i(3)] },
  // each item needs a different undo, which is the point of the lesson
  "g6-onestep": { items: [i(0, { where: p => p.t === 0 }), i(0, { where: p => p.t === 1 }), i(0, { where: p => p.t === 2 }), i(0, { where: p => p.t === 3 })] },
  "g6-tri": { items: [i(0, { where: p => p.b % 2 === 1 || p.h % 2 === 1 }), i(0, { where: p => p.b >= 10 && p.h >= 10 }), i(0), i(0)] },
  // a + b odd: halve only at the end
  "g6-trap": { items: [i(0, { where: p => (p.a + p.b) % 2 === 1 }), i(0, { where: p => p.h % 2 === 1 }), i(0), i(0)] },
  "g6-mean": { items: [i(0, { where: p => p.v.length === 4 }), i(0, { where: p => p.v.length === 5 }), i(0, { where: p => p.v.length === 6 }), i(0)] },
};
