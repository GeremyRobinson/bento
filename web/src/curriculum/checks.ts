// Each lesson's own skill check, from Curriculum (curriculum/specs/v2/grade<N>.md, each signed off by Review).
// An item is the lesson's own generate(rng, i), redrawn (up to 50 tries) until `where` holds; when it never does, the
// last draw stands, or `fix` turns it into one that fits. `story` asks it as the lesson's story, and goes last. The
// items are shuffled unless the recipe says `inOrder`. A lesson with no recipe gets the engine's default check.
/* eslint-disable @typescript-eslint/no-explicit-any */
export interface CheckItem {
  i: number;
  where?: (p: any) => boolean;
  /** when `where` never held: make the last draw fit (it must still be a valid problem), or null when it can't */
  fix?: (p: any) => any;
  story?: true;
}
export interface CheckRecipe { items: CheckItem[]; inOrder?: true }

export const WHERE_TRIES = 50;

const gcd = (a: number, b: number): number => (b ? gcd(b, a % b) : Math.abs(a));
/** decimal digits written in x */
const places = (x: number) => (String(x).split(".")[1] ?? "").length;
/** g5-round: the digit just right of the one rounded to */
const nextDigit = (p: { N: number; p: number }) => Math.floor(p.N / 10 ** (2 - p.p)) % 10;
/** add/sub/mix: the answer's top S over L */
const simplifies = (p: { S: number; L: number }) => p.S > 0 && gcd(p.S, p.L) > 1;

/** g2-hundreds: the tens digit */
const tens = (n: number) => Math.floor(n / 10) % 10;
/** g2-coins: a dime (2) against a penny (0) or a nickel (1) */
const dimeVsLess = (p: { coin: number; other: number }) => (p.coin === 2 && p.other < 2) || (p.other === 2 && p.coin < 2);

const i = (n: number, more: Omit<CheckItem, "i"> = {}): CheckItem => ({ i: n, ...more });

export const CHECKS: Record<string, CheckRecipe> = {
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

  // 2nd grade (grade2.md, Review 2026-10-13); the rare items are built directly when the draws don't find one (Review note 1)
  "g2-hundreds": {
    items: [
      i(0), i(3, { where: p => tens(p.n) === 0, fix: p => ({ n: p.n - tens(p.n) * 10 + (p.n % 10 ? 0 : 5) }) }),
      i(3, { where: p => p.n % 10 === 0, fix: p => ({ n: p.n - (p.n % 10) + (tens(p.n) ? 0 : 30) }) }), i(3),
    ],
  },
  "g2-skip": { items: [i(0, { where: p => p.by === 2 }), i(3, { where: p => p.by === 5 }), i(3, { where: p => p.by === 10 && p.start % 10 !== 0 }), i(3, { where: p => p.by === 100 })] },
  "g2-evenodd": { items: [i(0, { where: p => p.n % 2 === 0 }), i(0, { where: p => p.n % 2 === 1 }), i(3, { where: p => p.n % 2 === 0 && p.n >= 15 }), i(3, { where: p => p.n % 2 === 1 && p.n >= 15 })] },
  "g2-regroup": { items: [i(0), i(3, { where: p => (p.a % 10) + (p.b % 10) === 10 }), i(3), i(3, { story: true })] },
  "g2-subregroup": {
    items: [i(3, { where: p => p.a % 10 === 0, fix: p => ({ ...p, a: p.a - (p.a % 10) }) }), i(3, { where: p => p.a - p.b < 10 }), i(3), i(3, { story: true })],
  },
  "g2-within1000": { items: [i(0), i(4, { where: p => p.sub === 0 }), i(4, { where: p => p.sub === 1 }), i(4)] },
  // a dime is the smallest coin, so a dime against a penny or a nickel is the bigger coin worth less
  "g2-coins": { items: [i(0), i(3), i(5, { where: p => p.kind === 1 && dimeVsLess(p) }), i(5)] },
  "g2-money": { items: [i(0), i(3, { where: p => p.d === 0 }), i(3, { where: p => [p.q, p.d, p.n, p.p].filter(Boolean).length >= 3 }), i(3)] },
  "g2-time5": { items: [i(0), i(3, { where: p => p.m >= 35 }), i(3, { where: p => p.m === 0, fix: p => ({ ...p, m: 0 }) }), i(3)] },
  "g2-measure": { items: [i(0), i(3, { where: p => p.unit === 0 }), i(3, { where: p => p.unit === 1 }), i(3)] },
  "g2-estimate": { items: [i(0), i(3, { where: p => p.unit === 1 }), i(4, { where: p => p.unit === 0 && p.start > 0 }), i(5)] },
  "g2-bargraph": { items: [i(0), i(3, { where: p => p.kind === 0 }), i(3, { where: p => p.kind === 1 }), i(3, { where: p => p.kind === 0 })] },
  // one of each question: plot one more, tallest stack, longer than, longest − shortest
  "g2-lineplot": { items: [i(4), i(5), i(6), i(7)] },
  "g2-arrays": { items: [i(0), i(3, { where: p => p.rows !== p.cols }), i(3, { where: p => p.rows === 5 || p.cols === 5 }), i(3, { story: true })] },
  // the generator cycles the four solids, so this is each one once
  "g2-solids": { inOrder: true, items: [i(0), i(1), i(2), i(3)] },
  // a real fraction: some parts shaded, not all (Review note 3)
  "g2-shares": {
    items: [i(3), i(4, { where: p => p.parts === 3 }), i(5, { where: p => p.shaded >= 2 && p.shaded < p.parts, fix: p => (p.parts >= 3 ? { ...p, shaded: 2 } : null) }), i(6, { where: p => p.shape === 2 })],
  },
};
