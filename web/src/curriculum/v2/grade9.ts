// 9th grade in v2 (curriculum/specs/v2/grade9.md, signed off by Review 2026-10-13): what each lesson builds on, and its skill check.
// Every 9th grade lesson starts easy (indexes 0-2), so the checks draw at i3, the full range. None needs a `fix` (Review A2).
import { type CheckRecipe, i } from "../check-kit";

/** how many ways n splits into two whole factors (12: 1 × 12, 2 × 6, 3 × 4) */
const factorPairs = (n: number) => { let k = 0; for (let d = 1; d * d <= n; d++) if (n % d === 0) k++; return k; };
/** g9-median: the median, the middle of the sorted list */
const median = (v: number[]) => [...v].sort((a, b) => a - b)[(v.length - 1) / 2];

export const depends: Record<string, string[]> = {
  "g9-multistep": ["g7-eq", "g7-distribute"],
  "g9-elim": ["g8-system", "g7-addint"],
  "g9-twopoint": ["g8-intercept", "g8-slope"],
  "g9-negexp": ["g8-exp", "g6-expo"],
  "g9-growth": ["g6-expo", "g5-mult2"],
  "g9-radical": ["g8-roots", "g4-factors"],
  "g9-polyadd": ["g7-distribute", "g7-subint"],
  "g9-foil": ["g7-distribute", "g7-mulint"],
  "g9-gcf": ["g6-gcf", "g7-distribute"],
  "g9-factor": ["g9-foil", "g4-factors"],
  "g9-solvefactor": ["g9-factor", "g7-mulint"],
  "g9-quadform": ["g9-solvefactor", "g8-roots", "g7-mulint"],
  "g9-median": [],
};

export const checks: Record<string, CheckRecipe> = {
  "g9-multistep": { items: [i(3), i(3), i(3, { where: p => p.a * p.b >= 20 }), i(3, { where: p => p.x >= 8 })] },
  "g9-elim": { items: [i(3, { where: p => p.x > 0 && p.y > 0 }), i(3, { where: p => p.y < 0 }), i(3, { where: p => p.x < 0 }), i(3)] },
  "g9-twopoint": { items: [i(3, { where: p => p.m > 0 }), i(3, { where: p => p.m < 0 }), i(3, { where: p => p.b < 0 }), i(3, { where: p => p.x1 < 0 })] },
  "g9-negexp": { items: [i(3, { where: p => p.n === 1 }), i(3, { where: p => p.n === 2 }), i(3, { where: p => p.n === 3 }), i(3, { where: p => p.a >= 4 && p.n >= 2 })] },
  "g9-growth": { items: [i(3, { where: p => p.r === 2 }), i(3, { where: p => p.r === 3 }), i(3, { where: p => p.t >= 4 }), i(3)] },
  "g9-radical": { items: [i(3, { where: p => [2, 3, 5].includes(p.k) }), i(3, { where: p => p.k === 4 }), i(3, { where: p => p.k === 6 }), i(3)] },
  "g9-polyadd": { items: [i(3, { where: p => !p.sub }), i(3, { where: p => p.sub }), i(3, { where: p => p.sub && (p.d < 0 || p.e < 0 || p.f < 0) }), i(3)] },
  "g9-foil": { items: [i(3, { where: p => p.a > 0 && p.b > 0 }), i(3, { where: p => p.a * p.b < 0 }), i(3, { where: p => p.a < 0 && p.b < 0 }), i(3)] },
  "g9-gcf": { items: [i(3, { where: p => p.g === 4 || p.g === 6 }), i(3, { where: p => p.m === 1 }), i(3), i(3)] },
  "g9-factor": { items: [i(3, { where: p => p.p >= 2 }), i(3, { where: p => factorPairs(p.p * p.qn) >= 3 }), i(3, { where: p => p.p === p.qn }), i(3)] },
  "g9-solvefactor": { items: [i(3), i(3, { where: p => factorPairs(p.p * p.r) >= 3 }), i(3, { where: p => p.p >= 5 && p.r >= 5 }), i(3)] },
  // the last item is a plain i3, so a root of 0 can come up as it does in practice (Review note 1)
  "g9-quadform": { items: [i(3, { where: p => p.r1 * p.r2 < 0 }), i(3, { where: p => p.r1 < 0 && p.r2 < 0 }), i(3, { where: p => p.r1 > 0 && p.r2 > 0 }), i(3)] },
  "g9-median": {
    items: [
      i(3, { where: p => p.v.length === 5 }), i(3, { where: p => p.v.length === 7 }),
      i(3, { where: p => p.v[(p.v.length - 1) / 2] !== median(p.v) }), i(3, { where: p => new Set(p.v).size < p.v.length }),
    ],
  },
};
