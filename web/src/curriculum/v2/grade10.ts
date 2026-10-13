// 10th grade in v2 (curriculum/specs/v2/grade10.md, signed off by Review 2026-10-13): what each lesson builds on, and its skill check.
// Every 10th grade lesson is wrapped in withEasyStart and no generator reads `index`, so i3 is a plain draw from the full
// range and the `where` conditions pick the cases. Some conditions keep out numbers where a slip gives the right answer.
import { type CheckRecipe, gcd, i } from "../check-kit";

type Where = (p: any) => boolean; // eslint-disable-line @typescript-eslint/no-explicit-any
/** every item of the recipe also needs `all` */
const every = (all: Where, items: { where?: Where }[]) => items.map(it => ({ ...it, i: 3, where: (p: unknown) => all(p) && (it.where?.(p) ?? true) }));

export const depends: Record<string, string[]> = {
  "g10-mid": ["g6-mean", "g7-addint"],
  "g10-perp": ["g8-slope"],
  "g10-dist": ["g8-pyth", "g8-slope"],
  "g10-circle": ["g10-dist", "g8-roots"],
  "g10-polygon": ["g8-tri", "g5-divide"],
  "g10-exterior": ["g8-tri", "g7-angles"],
  "g10-similar": ["g7-scale", "g5-multdec"],
  "g10-special": ["g9-radical", "g8-pyth"],
  "g10-trig": ["g10-similar", "g8-pyth"],
  "g10-sector": ["g7-circarea", "g5-fracof"],
  "g10-arc": ["g7-circum", "g5-fracof"],
  "g10-surface": ["g5-volume", "g4-area"],
  "g10-pyramid": ["g8-cone", "g5-volume"],
};

export const checks: Record<string, CheckRecipe> = {
  // with x1 + x2 = 0, "Forgot to halve" gives 0, the right answer
  "g10-mid": {
    items: every(p => p.mx !== 0 && p.my !== 0, [
      { where: p => p.mx < 0 }, { where: p => p.my < 0 }, { where: p => p.x1 * p.x2 < 0 || p.y1 * p.y2 < 0 }, {},
    ]),
  },
  // a slope of ±1 flips to itself, so the flip step tests nothing
  "g10-perp": {
    items: [
      i(3, { where: p => p.p > 0 && p.r >= 2 && Math.abs(p.p) >= 2 }), i(3, { where: p => p.p < 0 && p.r >= 2 && Math.abs(p.p) >= 2 }),
      i(3, { where: p => p.r === 1 && Math.abs(p.p) >= 2 }), i(3, { where: p => Math.abs(p.p) === 1 && p.r >= 2 }),
    ],
  },
  // with x1 = 0, adding instead of subtracting gives the right answer
  "g10-dist": { items: every(p => p.x1 >= 1 && p.y1 >= 1, [{ where: p => p.dx > p.dy }, { where: p => p.dx < p.dy }, { where: p => p.d >= 13 }, {}]) },
  // r = 1 makes "Forgot the square root" right, and r = 2 makes "Squared as times 2" right
  "g10-circle": {
    items: every(p => p.r >= 2, [{ where: p => p.h > 0 && p.k < 0 }, { where: p => p.h < 0 && p.k > 0 }, { where: p => p.h < 0 && p.k < 0 }, { where: p => p.r >= 5 }]),
  },
  "g10-polygon": { items: [i(3, { where: p => p.n <= 6 }), i(3, { where: p => p.n >= 8 && p.n <= 10 }), i(3, { where: p => p.n >= 12 }), i(3, { where: p => p.n >= 15 })] },
  // at a + b = 90 the inside and outside angles are both 90°, and at 2a + b = 180 the far-angle slip (180 − a) is right
  "g10-exterior": {
    items: every(p => p.a + p.b !== 90 && 2 * p.a + p.b !== 180, [{ where: p => p.a + p.b < 90 }, { where: p => p.a + p.b > 120 }, { where: p => p.a !== p.b }, {}]),
  },
  "g10-similar": { items: [i(3, { where: p => p.k === 1.5 || p.k === 2.5 }), i(3, { where: p => p.k === 1.5 || p.k === 2.5 }), i(3, { where: p => p.k >= 3 }), i(3)] },
  "g10-special": {
    items: [i(3, { where: p => p.t === 45 }), i(3, { where: p => p.t === 30 }), i(3, { where: p => p.t === 45 && p.s >= 7 }), i(3, { where: p => p.t === 30 && p.s >= 7 })],
  },
  // the last item's ratio simplifies: the triple is 6-8-10, 9-12-15 or 12-16-20
  "g10-trig": { items: [i(3, { where: p => p.f === "sin" }), i(3, { where: p => p.f === "cos" }), i(3, { where: p => p.f === "tan" }), i(3, { where: p => gcd(p.a, p.b) > 1 })] },
  // r = 1 makes "Forgot the square root" right, and r = 2 makes "Squared as times 2" right; the two rarest items are
  // built directly when the draws don't find one (Review A2)
  "g10-sector": {
    items: [
      i(3, { where: p => (p.t === 90 || p.t === 270) && p.r >= 3 }), i(3, { where: p => p.t === 60 || p.t === 120 }),
      i(3, { where: p => p.t === 45 && p.r >= 4, fix: p => ({ ...p, t: 45, r: p.r >= 4 && p.r % 2 === 0 ? p.r : 6 }) }),
      i(3, { where: p => p.t === 180 && p.r >= 3, fix: p => ({ ...p, t: 180, r: Math.max(3, p.r) }) }),
    ],
  },
  "g10-arc": { items: [i(3, { where: p => p.t === 90 || p.t === 270 }), i(3, { where: p => p.t === 60 || p.t === 120 }), i(3, { where: p => p.t === 45 }), i(3, { where: p => p.t !== 180 })] },
  // with two sides of 2, adding is the same as multiplying (2 + 2 = 2 × 2)
  "g10-surface": {
    items: [
      i(3, { where: p => p.l !== p.w && p.w !== p.h && p.l !== p.h }), i(3, { where: p => p.l !== p.w && p.w !== p.h && p.l !== p.h }),
      i(3, { where: p => new Set([p.l, p.w, p.h]).size === 2 && twin(p) !== 2 }),
      i(3, { where: p => p.l >= 3 && p.w >= 3 && p.h >= 3 }),
    ],
  },
  // with s = 4 the perimeter equals the area (4 × 4 = 16 = 4 × 4)
  "g10-pyramid": { items: every(p => p.s !== 4, [{ where: p => p.s % 3 === 0 && p.h % 3 !== 0 }, { where: p => p.h % 3 === 0 && p.s % 3 !== 0 }, { where: p => p.s >= 7 }, {}]) },
};

/** g10-surface: the side length two of l, w and h share */
function twin(p: { l: number; w: number; h: number }) {
  return p.l === p.w || p.l === p.h ? p.l : p.w;
}
