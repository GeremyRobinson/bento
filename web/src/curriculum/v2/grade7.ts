// 7th grade in v2 (curriculum/specs/v2/grade7.md, signed off by Review 2026-10-13): what each lesson builds on, and its skill check.
import { type CheckRecipe, gcd, i } from "../check-kit";

const both = (p: { a: number; b: number }) => Math.abs(p.a) >= 2 && Math.abs(p.b) >= 2;
/** g7-mulint, sizes 2 or more so the size step isn't trivial (Review note 5) */
const mul = (div: boolean, sa: number, sb: number) => (p: { a: number; b: number; div: boolean }) =>
  p.div === div && Math.sign(p.a) === sa && Math.sign(p.b) === sb && both(p);
/** when the draws never fit, set the signs (and sizes at least 2) directly; the sizes stay in −12 to 12 */
const mulFix = (div: boolean, sa: number, sb: number) => (p: { a: number; b: number; div: boolean }) =>
  ({ ...p, div, a: sa * Math.max(2, Math.abs(p.a)), b: sb * Math.max(2, Math.abs(p.b)) });
/** g7-prob: the colour asked about, out of all the marbles */
const simplifies = (p: { r: number; b: number; g: number; c: number }) => gcd([p.r, p.b, p.g][p.c]!, p.r + p.b + p.g) > 1;

export const depends: Record<string, string[]> = {
  "g7-prop": ["g6-ratio", "g4-equiv"],
  "g7-scale": ["g6-ratio", "g3-divfacts"],
  "g7-discount": ["g6-pctof"],
  "g7-pctchange": ["g7-discount", "g5-pow10"],
  "g7-addint": ["g6-numline"],
  "g7-subint": ["g7-addint"],
  "g7-mulint": ["g7-addint", "g3-facts", "g3-divfacts"],
  "g7-eq": ["g6-onestep"],
  "g7-distribute": ["g3-split", "g6-eval"],
  "g7-circum": ["g5-multdec"],
  "g7-circarea": ["g7-circum", "g6-expo"],
  "g7-angles": ["g4-angles"],
  "g7-prob": ["g4-equiv", "g6-gcf"],
};

export const checks: Record<string, CheckRecipe> = {
  "g7-prop": { items: [i(0), i(0, { where: p => p.a > p.b }), i(4, { where: p => !Number.isInteger(p.k) }), i(4, { where: p => !Number.isInteger(p.k) })] },
  "g7-scale": { items: [i(3, { where: p => p.c >= 2 }), i(3, { where: p => p.c >= 2 && p.g >= 5 }), i(3, { where: p => p.c >= 3 }), i(3)] },
  // off and on are mixed, which is the point of the lesson
  "g7-discount": {
    items: [
      i(0, { where: p => p.off && (p.p === 15 || p.p === 25) }), i(0, { where: p => !p.off && (p.p === 15 || p.p === 25) }),
      i(0, { where: p => p.off }), i(0, { where: p => !p.off }),
    ],
  },
  // dividing by the new number goes badly wrong when it fell by half or more
  "g7-pctchange": {
    items: [i(0, { where: p => p.up }), i(0, { where: p => !p.up }), i(0, { where: p => !p.up && p.p >= 50 }), i(0, { where: p => p.up && (p.p === 25 || p.p === 75) })],
  },
  // a negative sum in both orders (the coordinator, from Review note 4)
  "g7-addint": {
    items: [
      i(0, { where: p => p.a < 0 && p.b < 0 }), i(0, { where: p => Math.sign(p.a) !== Math.sign(p.b) && p.a + p.b > 0 }),
      i(0, { where: p => p.a > 0 && p.b < 0 && p.a + p.b < 0 }), i(0, { where: p => p.a < 0 && p.b > 0 && p.a + p.b < 0 }),
    ],
  },
  "g7-subint": { items: [i(0), i(3, { where: p => p.b > 0 && p.b > p.a }), i(3, { where: p => p.a < 0 && p.b < 0 }), i(3, { where: p => p.a < 0 && p.b > 0 })] },
  // all four sign cases; for ÷ the shown numbers are a × b and b
  "g7-mulint": {
    items: [
      // the signs of a and b differ: either order
      i(3, { where: p => !p.div && Math.sign(p.a) !== Math.sign(p.b) && both(p), fix: p => mulFix(false, Math.sign(p.a), -Math.sign(p.a))(p) }),
      i(3, { where: mul(false, -1, -1), fix: mulFix(false, -1, -1) }),
      // a < 0: the shown numbers differ in sign
      i(3, { where: p => p.div && p.a < 0 && both(p), fix: p => mulFix(true, -1, Math.sign(p.b))(p) }),
      // a > 0, b < 0: both shown numbers negative
      i(3, { where: mul(true, 1, -1), fix: mulFix(true, 1, -1) }),
    ],
  },
  // dividing first would give a fraction, so the order of undoing shows
  "g7-eq": { items: [i(0, { where: p => p.b % p.a !== 0 }), i(0, { where: p => p.b % p.a !== 0 }), i(0, { where: p => p.b % p.a !== 0 }), i(0, { where: p => p.x >= 8 })] },
  // the hidden 1 in x: about 1 in 9 draws, so build it directly when the draws miss (Review note 1)
  "g7-distribute": { items: [i(0), i(0, { where: p => p.c === 1, fix: p => ({ ...p, c: 1 }) }), i(0, { where: p => p.a >= 6 && p.b >= 6 }), i(0)] },
  // r ≥ 3: at r = 2, 2 × r and r × r are both 4
  "g7-circum": { items: [i(0, { where: p => p.r >= 3 }), i(3, { where: p => p.r >= 3 }), i(3, { where: p => p.r >= 7 }), i(3, { where: p => p.r >= 3 })] },
  "g7-circarea": { items: [i(0, { where: p => p.r >= 3 }), i(3, { where: p => p.r >= 3 }), i(3, { where: p => p.r >= 7 }), i(3, { where: p => p.r >= 3 })] },
  "g7-angles": { items: [i(0, { where: p => p.sup }), i(0, { where: p => !p.sup }), i(0, { where: p => p.sup && p.a > 90 }), i(0, { where: p => !p.sup })] },
  "g7-prob": { items: [i(0), i(3, { where: simplifies }), i(3, { where: simplifies }), i(3, { where: p => !simplifies(p) })] },
};
