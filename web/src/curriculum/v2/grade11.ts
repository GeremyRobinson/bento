// 11th grade in v2 (curriculum/specs/v2/grade11.md, signed off by Review 2026-10-13, with Review's notes): what each
// lesson builds on, and its skill check.
import { type CheckRecipe, i } from "../check-kit";

export const depends: Record<string, string[]> = {
  "g11-seq": ["g8-func", "g4-partial"],
  "g11-geo": ["g11-seq", "g6-expo"],
  "g11-ratexp": ["g8-roots", "g8-exp"],
  // x comes out 0 or negative in about a quarter of the problems (Review A3)
  "g11-expeq": ["g6-expo", "g6-onestep", "g7-addint"],
  "g11-log": ["g11-expeq", "g8-exp"],
  "g11-evalpoly": ["g8-func", "g7-mulint", "g6-expo"],
  "g11-synth": ["g11-evalpoly", "g9-factor", "g7-mulint"],
  "g11-compose": ["g8-func", "g7-mulint"],
  "g11-inverse": ["g7-eq", "g7-mulint", "g8-func"],
  "g11-vertex": ["g11-evalpoly", "g7-mulint"],
  "g11-radical": ["g8-roots", "g6-onestep"],
  "g11-complex": ["g9-foil", "g7-mulint"],
  "g11-comb": ["g4-partial", "g5-divide"],
};

// a lesson's own problem, read by field name (as in check-kit)
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type P = any;
/** g11-seq: a child who types a1 for d is marked right when a1 = d */
const seq = (w: (p: P) => boolean = () => true) => (p: P) => p.a1 !== p.d && w(p);
/** g11-geo: a = 1 makes the last step "1 × the power"; a = 2, r = 2 lets "subtracted" (4 − 2) land on r (Review A2) */
const geo = (w: (p: P) => boolean = () => true) => (p: P) => p.a >= 2 && (p.r !== 2 || p.a >= 3) && w(p);
/** g11-log: m = 1 or b = 2 with m = 2 lets "divided instead" land on the answer */
const log = (b: number) => (p: P) => p.b === b && p.m >= (b === 2 ? 3 : 2) && p.k >= (b === 2 ? 3 : 2);
/** g11-log, when the draws never hit the base (Review note 1): two different powers in range */
const logFix: Record<number, (p: P) => P> = {
  2: p => { const m = 3 + (p.m % 4); return { ...p, b: 2, m, k: 3 + ((m - 3 + 1 + (p.k % 3)) % 4) }; },
  3: p => ({ ...p, b: 3, m: 2 + (p.m % 3), k: 2 + (((p.m % 3) + 1 + (p.k % 2)) % 3) }),
  5: p => ({ ...p, b: 5, m: p.m > p.k ? 3 : 2, k: p.m > p.k ? 2 : 3 }),
  10: p => ({ ...p, b: 10, m: p.m > p.k ? 3 : 2, k: p.m > p.k ? 2 : 3 }),
};
const logItem = (b: number) => i(3, { where: log(b), fix: logFix[b] });
/** g11-evalpoly: k = 2 lets "doubled instead of squared" land on k², and k = ±1 makes the square trivial */
const evalpoly = (w: (p: P) => boolean) => (p: P) => (p.k <= -2 || p.k >= 3) && w(p);
/** g11-synth: r = ±1 just copies numbers; with a remainder, e = −s lets "swapped them" land on the answer (Review A2) */
const synth = (sign: 1 | -1, rem: boolean) => (p: P) => Math.sign(p.r) === sign && Math.abs(p.r) >= 2 && (!rem || p.e !== -p.s);
/** g11-compose: when a·d + b = c·b + d, the wrong order gives the same answer */
const compose = (w: (p: P) => boolean = () => true) => (p: P) => p.a * p.d + p.b !== p.c * p.b + p.d && w(p);
/** g11-complex: a = c = 2 lets "added" (2 + 2) land on 2 × 2 */
const complex = (w: (p: P) => boolean = () => true) => (p: P) => !(p.a === 2 && p.c === 2) && w(p);

export const checks: Record<string, CheckRecipe> = {
  "g11-seq": { items: [i(3, { where: seq(p => p.n >= 20 && p.d >= 5) }), i(3, { where: seq(p => p.n <= 15) }), i(3, { where: seq(p => p.a1 >= 10) }), i(3, { where: seq() })] },
  "g11-geo": { items: [i(3, { where: geo(p => p.r === 2) }), i(3, { where: geo(p => p.r === 3) }), i(3, { where: geo(p => p.n >= 7) }), i(3, { where: geo() })] },
  // m = 1 makes the power step r¹; r = 2 with a square (√4 ÷ 2) or m = 2 (2 × 2) lets a slip land on the answer (Review A2)
  "g11-ratexp": {
    items: [
      i(3, { where: p => p.n === 2 && p.m === 3 && p.r >= 3 }), i(3, { where: p => p.n === 3 && p.m === 2 && p.r >= 3 }),
      i(3, { where: p => p.n === 3 && p.m === 4 }), i(3, { where: p => p.m >= 2 && !(p.r === 2 && (p.m === 2 || p.n === 2)) }),
    ],
  },
  // b = 2 with k = 2 lets "divided" (4 ÷ 2) land on k
  "g11-expeq": {
    items: [
      i(3, { where: p => p.c > 0 && p.k >= 3 }), i(3, { where: p => p.c < 0 && p.k >= 3 }),
      i(3, { where: p => p.b !== 2 && p.k >= 3 }), i(3, { where: p => p.b === 2 && p.k >= 5 }),
    ],
  },
  "g11-log": { items: [logItem(2), logItem(3), logItem(5), logItem(10)] },
  "g11-evalpoly": {
    items: [
      i(3, { where: evalpoly(p => p.k < 0) }), i(3, { where: evalpoly(p => p.b < 0 && p.k < 0) }),
      i(3, { where: evalpoly(p => p.a < 0) }), i(3, { where: evalpoly(p => p.k > 0) }),
    ],
  },
  // every index with index % 3 === 2 has a remainder; the four cover a box number of each sign, with and without one
  "g11-synth": { items: [i(3, { where: synth(1, false) }), i(4, { where: synth(-1, false) }), i(5, { where: synth(1, true) }), i(8, { where: synth(-1, true) })] },
  "g11-compose": { items: [i(3, { where: compose(p => p.k < 0) }), i(3, { where: compose(p => p.c * p.k + p.d < 0) }), i(3, { where: compose(p => p.a < 0) }), i(3, { where: compose() })] },
  // x = 0 lets "multiplied again" (0 × a) land on the answer
  "g11-inverse": { items: [i(3, { where: p => p.x !== 0 && p.b < 0 }), i(3, { where: p => p.x !== 0 && p.a < 0 }), i(3, { where: p => p.x < 0 }), i(3, { where: p => p.x !== 0 })] },
  // c = 0 lets "left out c" land on the answer
  "g11-vertex": { items: [i(3, { where: p => p.c !== 0 && p.a < 0 }), i(3, { where: p => p.c !== 0 && p.h < 0 }), i(3, { where: p => p.c !== 0 && (p.a === 2 || p.a === 3) }), i(3, { where: p => p.c !== 0 })] },
  // b = 2 lets "doubled instead" (2 × 2) land on 2²
  "g11-radical": { items: [i(3, { where: p => p.b >= 3 && p.a > 0 }), i(3, { where: p => p.b >= 3 && p.a < 0 }), i(3, { where: p => p.b >= 6 }), i(3, { where: p => p.b >= 3 })] },
  "g11-complex": {
    items: [
      i(3, { where: complex(p => p.b * p.d > 0) }), i(3, { where: complex(p => p.b * p.d < 0) }),
      i(3, { where: complex(p => p.a < 0 || p.c < 0) }), i(3, { where: complex(p => Math.abs(p.b) >= 2 && Math.abs(p.d) >= 2) }),
    ],
  },
  // odd indexes choose 3, even choose 2. For choose 2 the "counted the picks" slip (2) equals 2!, so three items
  // choose 3 (Review note 4); n ≥ 8 or 9 keeps the products past easy recall
  "g11-comb": { items: [i(3), i(5, { where: p => p.n >= 9 }), i(4, { where: p => p.n >= 8 }), i(7, { where: p => p.n >= 8 })] },
};
