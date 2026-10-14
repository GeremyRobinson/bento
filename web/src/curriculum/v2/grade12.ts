// 12th grade in v2 (curriculum/specs/v2/grade12.md, signed off by Review 2026-10-13): what each lesson builds on, and its skill check.
import { type CheckRecipe, i } from "../check-kit";
import { createRadiansToDegrees } from "../lessons/grade12/g12-deg";

/** g12-polyd: d = 0 hides the constant dropping out, and d = 2a + b makes f(1) = f′(1) */
const polydOk = (p: { a: number; b: number; d: number }) => p.d !== 0 && p.d !== 2 * p.a + p.b;
/** g12-dot: a = b makes "Mixed the parts" match b·d, and a = c = 2 makes "Added" match the product */
const dotOk = (p: { a: number; b: number; c: number }) => p.a !== p.b && p.a !== p.c;

export const depends: Record<string, string[]> = {
  "g12-rad": ["g10-arc", "g6-gcf"],
  "g12-deg": ["g12-rad", "g5-fracof"],
  "g12-unit": ["g10-special", "g10-trig"],
  "g12-limit": ["g9-factor", "g8-func"],
  "g12-power": ["g8-slope", "g6-expo"],
  "g12-polyd": ["g12-power", "g7-mulint"],
  "g12-tangent": ["g12-polyd", "g8-func"],
  "g12-chain": ["g12-power", "g11-compose"],
  "g12-anti": ["g12-power", "g7-mulint"],
  "g12-defint": ["g12-anti", "g6-expo"],
  "g12-series": ["g11-seq"],
  "g12-vecmag": ["g10-dist", "g8-pyth"],
  "g12-dot": ["g12-vecmag", "g7-mulint"],
};

export const checks: Record<string, CheckRecipe> = {
  "g12-rad": { items: [i(3, { where: p => p.t > 90 && p.t < 180 }), i(3, { where: p => p.t > 180 && p.t < 270 }), i(3, { where: p => p.t > 270 }), i(3)] },
  // 5π/6, 7π/6 or 11π/6 when the draws never give one (Review A2)
  "g12-deg": {
    items: [
      i(3, { where: p => p.d === 6 && p.n >= 5, fix: p => createRadiansToDegrees([5, 7, 11][p.n % 3]!, 6) }), i(3, { where: p => p.d === 4 && p.n >= 3 }),
      i(3, { where: p => p.d === 3 && p.n >= 2 }), i(3, { where: p => p.n > p.d }),
    ],
  },
  "g12-unit": { items: [i(3, { where: p => p.t > 180 }), i(4, { where: p => p.t > 90 && p.t < 270 }), i(5, { where: p => p.t === 150 }), i(6, { where: p => p.t === 300 })] },
  "g12-limit": {
    items: [
      i(3, { where: p => p.a > 0 && p.b < 0 }), i(3, { where: p => p.a < 0 && p.b > 0 }), i(3, { where: p => p.a < 0 && p.b < 0 }),
      i(3, { where: p => p.a > 0 && p.b > 0 && p.b !== p.a }),
    ],
  },
  "g12-power": {
    items: [i(3, { where: p => p.n >= 3 }), i(3, { where: p => p.n >= 4 && p.a >= 4 }), i(3, { where: p => p.n === 2 && p.a >= 3 }), i(3, { where: p => p.n >= 3 && p.a >= 5 })],
  },
  "g12-polyd": {
    items: [
      i(3, { where: p => polydOk(p) && p.b < 0 }), i(3, { where: p => polydOk(p) && p.a < 0 }), i(3, { where: p => polydOk(p) && p.c < 0 }),
      i(3, { where: p => polydOk(p) && 3 * p.a + 2 * p.b + p.c < 0 }),
    ],
  },
  "g12-tangent": {
    items: [
      i(3, { where: p => p.slope !== p.fk && p.k <= -2 }), i(3, { where: p => p.slope !== p.fk && p.a < 0 && p.k >= 2 }), i(3, { where: p => p.slope !== p.fk && p.b < 0 }),
      i(3, { where: p => p.slope !== p.fk && (p.k >= 2 || p.k <= -2) }),
    ],
  },
  "g12-chain": {
    items: [
      i(3, { where: p => p.b < 0 && p.a !== p.n }), i(3, { where: p => p.b > 0 && p.n >= 3 && p.a !== p.n }), i(3, { where: p => p.n === 2 && p.a >= 3 }),
      i(3, { where: p => p.a !== p.n }),
    ],
  },
  "g12-anti": {
    items: [i(3, { where: p => p.a < 0 }), i(3, { where: p => p.n === 1 }), i(3, { where: p => p.n >= 3 && p.a / (p.n + 1) >= 2 }), i(3, { where: p => p.a / (p.n + 1) !== 1 })],
  },
  // c = a ÷ (n + 1) is at least 2 in the first three, as the spec's rationale says (Review note 5)
  "g12-defint": {
    items: [
      i(3, { where: p => p.n === 1 && p.c >= 2 }), i(3, { where: p => p.n === 2 && p.c >= 2 }), i(3, { where: p => p.n === 3 && p.k <= 3 && p.c >= 2 }),
      i(3, { where: p => p.j >= 2 }),
    ],
  },
  "g12-series": { items: [i(3, { where: p => p.n % 2 === 1 }), i(3, { where: p => p.n % 2 === 0 && p.d >= 2 }), i(3, { where: p => p.n >= 20 }), i(3, { where: p => p.a >= 2 })] },
  "g12-vecmag": { items: [i(3, { where: p => p.x < 0 && p.y > 0 }), i(3, { where: p => p.x > 0 && p.y < 0 }), i(3, { where: p => p.x < 0 && p.y < 0 }), i(3, { where: p => p.m >= 13 })] },
  "g12-dot": {
    items: [
      i(3, { where: p => dotOk(p) && p.a * p.c > 0 && p.b * p.d < 0 }), i(3, { where: p => dotOk(p) && p.a * p.c < 0 && p.b * p.d > 0 }),
      i(3, { where: p => dotOk(p) && p.a * p.c + p.b * p.d < 0 }), i(3, { where: p => dotOk(p) && p.a * p.c + p.b * p.d > 0 }),
    ],
  },
};
