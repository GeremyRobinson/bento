// 5th grade in v2 (curriculum/specs/v2/grade5.md, signed off by Review 2026-10-13): what each lesson builds on, and its skill check.
import { type CheckRecipe, gcd, i, places } from "../check-kit";

/** g5-round: the digit just right of the one rounded to */
const nextDigit = (p: { N: number; p: number }) => Math.floor(p.N / 10 ** (2 - p.p)) % 10;
/** add/sub/mix: the answer's top S over L */
const simplifies = (p: { S: number; L: number }) => p.S > 0 && gcd(p.S, p.L) > 1;

export const depends: Record<string, string[]> = {
  "g5-mult2": ["g4-mult2x2", "g3-mult10"],
  "g5-divide": ["g4-divide", "g3-mult10"],
  "g5-order": ["g3-facts", "g3-divfacts"],
  "g5-pow10": ["g4-dec", "g4-placevalue"],
  "g5-round": ["g4-placevalue", "g4-dec"],
  "g5-adddec": ["g4-dec", "g4-addsub"],
  "g5-multdec": ["g4-partial", "g4-dec"],
  "g5-divdec": ["g5-pow10", "g3-divfacts"],
  "g5-improper": ["g4-mixed"],
  add: ["g4-equiv", "g4-likefrac", "g4-factors"],
  sub: ["add"],
  mix: ["add", "sub"],
  "g5-fracof": ["g3-divfacts", "g4-fracwhole"],
  "g5-multfrac": ["g5-fracof", "g4-equiv"],
  "g5-unitdiv": ["g3-unitfrac", "g3-facts"],
  "g5-volume": ["g4-area", "g4-partial"],
  "g5-units": ["g4-convert", "g4-partial"],
};

export const checks: Record<string, CheckRecipe> = {
  "g5-mult2": { items: [i(3), i(3), i(3, { where: p => p.secondFactor % 10 >= 6 }), i(3, { story: true })] },
  "g5-divide": { items: [i(3, { where: p => p.dv <= 9 }), i(3, { where: p => p.dv >= 11 }), i(3, { where: p => p.dv >= 11 }), i(3, { story: true })] },
  "g5-order": { items: [i(3, { where: p => p.t === 0 }), i(4, { where: p => p.t === 1 }), i(5, { where: p => p.t === 2 }), i(6, { where: p => p.t === 0 })] },
  "g5-pow10": { items: [i(3, { where: p => p.k === 1 }), i(3, { where: p => p.k === 2 }), i(3, { where: p => p.k === 3 && places(p.x) < 3 }), i(3)] },
  "g5-round": {
    items: [
      i(3, { where: p => p.p === 1 && nextDigit(p) < 5 }), i(3, { where: p => p.p === 1 && nextDigit(p) >= 5 }),
      i(3, { where: p => p.p === 2 }), i(5),
    ],
  },
  "g5-adddec": {
    items: [
      i(3, { where: p => (p.a % 1) + (p.b % 1) >= 1 - 1e-9 }), i(3, { where: p => (p.a % 1) + (p.b % 1) < 1 - 1e-9 }),
      i(3), i(3, { story: true }),
    ],
  },
  "g5-multdec": { items: [i(1), i(4), i(7), i(5, { story: true })] },
  "g5-divdec": { items: [i(0, { where: p => p.qt >= 7 }), i(0, { where: p => p.qt >= 10 }), i(0), i(0, { story: true })] },
  "g5-improper": { items: [i(3), i(3, { where: p => p.d >= 6 }), i(3, { where: p => p.w >= 4 }), i(3)] },
  add: { items: [i(1), i(3, { where: p => p.S > p.L }), i(3, { where: simplifies }), i(4, { story: true })] },
  sub: { items: [i(1), i(3, { where: p => p.b % p.d !== 0 && p.d % p.b !== 0 }), i(3, { where: simplifies }), i(4, { story: true })] },
  // the sign changes between items, which is the point of the lesson, so they stay in this order (Review A3)
  mix: { inOrder: true, items: [i(2, { where: p => p.op === "+" }), i(3, { where: p => p.op === "−" }), i(4, { where: p => p.op === "+" }), i(5, { where: p => p.op === "−" })] },
  "g5-fracof": { items: [i(3, { where: p => p.n > 1 }), i(3, { where: p => p.n > 1 }), i(3), i(3, { story: true })] },
  "g5-multfrac": {
    items: [i(3, { where: p => gcd(p.a * p.c, p.b * p.d) > 1 }), i(3, { where: p => gcd(p.a * p.c, p.b * p.d) === 1 }), i(3), i(3, { story: true })],
  },
  "g5-unitdiv": { items: [i(3), i(3), i(3), i(3, { story: true })] },
  // when the draws never put the height tallest, swap sides so it is (Review A1)
  "g5-volume": {
    items: [i(3), i(3), i(3, { where: p => p.h >= p.l && p.h >= p.w, fix: p => { const [a, b, c] = [p.l, p.w, p.h].sort((x, y) => x - y); return { ...p, l: a, w: b, h: c }; } }), i(3)],
  },
  "g5-units": { items: [i(1, { where: p => !p.up }), i(4, { where: p => !!p.up }), i(5, { where: p => !!p.up }), i(7, { where: p => !!p.up && p.n % p.u[3] !== 0 })] },
};
