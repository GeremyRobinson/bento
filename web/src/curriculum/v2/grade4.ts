// 4th grade in v2 (curriculum/specs/v2/grade4.md, signed off by Review 2026-10-13): what each lesson builds on, and its skill check.
// The tens-digit-0 item of g4-partial is built directly when the draws don't find one (Review note 2); the others keep
// the last draw.
import { type CheckRecipe, gcd, i } from "../check-kit";
import { SHAPES } from "../lessons/grade4/g4-symmetry";

/** < = > as 0 1 2, as the lessons' compareIndex */
const cmp = (x: number, y: number) => (x < y ? 0 : x === y ? 1 : 2);
/** g4-placevalue: the digit just right of the place rounded to */
const nextDigit = (p: { n: number; place: number }) => Math.floor(p.n / (p.place / 10)) % 10;
/** g4-partial: the tens digit */
const tens = (n: number) => Math.floor(n / 10) % 10;
/** g4-fraccompare: the common bottom */
const lcm = (b: number, d: number) => (b * d) / gcd(b, d);
const neitherBottom = (p: { b: number; d: number }) => { const L = lcm(p.b, p.d); return L !== p.b && L !== p.d; };
/** g4-deccompare: the digits after the point read as a whole number (0.5 → 5, 0.45 → 45) */
const afterPoint = (h: number, places: number) => (places === 1 ? h / 10 : h);
/** g4-lineplot: how many X's sit above v */
const stack = (p: { data: number[]; v: number }) => p.data.filter(u => u === p.v).length;

export const depends: Record<string, string[]> = {
  "g4-placevalue": ["g3-round"],
  "g4-addsub": ["g3-addsub"],
  "g4-partial": ["g3-split", "g3-mult10"],
  "g4-mult2x2": ["g4-partial", "g3-mult10"],
  "g4-divide": ["g3-divfacts", "g3-mult10"],
  "g4-factors": ["g3-facts", "g3-divfacts"],
  "g4-equiv": ["g3-fraccompare", "g3-facts"],
  "g4-fraccompare": ["g4-equiv", "g3-fraccompare"],
  "g4-likefrac": ["g3-unitfrac", "g3-fracline"],
  "g4-mixed": ["g4-likefrac"],
  "g4-fracwhole": ["g4-likefrac", "g3-facts"],
  "g4-dec": ["g4-equiv", "g4-likefrac"],
  "g4-deccompare": ["g4-dec"],
  "g4-convert": ["g3-split", "g3-mult10"],
  "g4-lineplot": ["g3-lineplot", "g4-likefrac", "g4-fracwhole"],
  "g4-area": ["g3-area", "g3-perim"],
  "g4-lines": ["g3-quads"],
  "g4-angles": ["g4-lines", "g3-addsub"],
  "g4-symmetry": ["g3-quads", "g2-shares"],
};

export const checks: Record<string, CheckRecipe> = {
  "g4-placevalue": {
    items: [i(3, { where: p => nextDigit(p) < 5 }), i(3, { where: p => nextDigit(p) >= 5 }), i(6, { where: p => nextDigit(p) === 5 }), i(6)],
  },
  "g4-addsub": { items: [i(0, { where: p => p.sub === 1 }), i(4, { where: p => p.sub === 0 }), i(4, { where: p => p.sub === 1 }), i(4, { story: true })] },
  // a 0 in the tens: "there are no tens, so that part is 0"; built directly when the draws miss (a 0 in the ones too gets 5 ones)
  "g4-partial": {
    items: [
      i(3), i(3, { where: p => tens(p.n) === 0, fix: p => ({ ...p, n: Math.floor(p.n / 100) * 100 + (p.n % 10 || 5) }) }),
      i(3, { where: p => p.m >= 6 }), i(3, { story: true }),
    ],
  },
  "g4-mult2x2": { items: [i(0), i(3), i(3, { where: p => p.a % 10 >= 5 && p.b % 10 >= 5 }), i(3, { story: true })] },
  // the generator ignores the index, so the conditions do the work
  "g4-divide": { items: [i(0, { where: p => p.r === 0 }), i(0, { where: p => p.r > 0 && p.q >= 20 }), i(0, { where: p => p.r > 0 }), i(0, { story: true })] },
  "g4-factors": {
    items: [i(0, { where: p => p.n % p.t === 0 }), i(3, { where: p => p.n % p.t !== 0 }), i(0, { where: p => p.n === 16 }), i(3, { where: p => p.n > 32 })],
  },
  "g4-equiv": { items: [i(0, { where: p => p.a === 1 }), i(0, { where: p => p.a > 1 }), i(0, { where: p => p.k >= 4 }), i(0, { where: p => p.a > 1 && p.b >= 5 })] },
  // equal amounts; a new bottom for both; and a new bottom where the tops alone point the wrong way
  "g4-fraccompare": {
    items: [
      i(0), i(0, { where: p => p.a * p.d === p.c * p.b }), i(4, { where: neitherBottom }),
      i(4, { where: p => neitherBottom(p) && cmp(p.a, p.c) !== cmp(p.a * p.d, p.c * p.b) }),
    ],
  },
  "g4-likefrac": { items: [i(0), i(3, { where: p => p.a + p.c > p.d }), i(3, { where: p => p.a + p.c < p.d }), i(3, { story: true })] },
  "g4-mixed": {
    items: [
      i(0, { where: p => p.n1 + p.n2 < p.d }), i(3, { where: p => p.n1 + p.n2 > p.d }), i(3, { where: p => p.n1 + p.n2 > p.d && p.d >= 6 }),
      i(3, { story: true }),
    ],
  },
  "g4-fracwhole": {
    items: [
      i(0, { where: p => p.W * p.n < p.d }), i(0, { where: p => p.W * p.n > p.d && (p.W * p.n) % p.d !== 0 }), i(0, { where: p => (p.W * p.n) % p.d === 0 }),
      i(0, { story: true }),
    ],
  },
  "g4-dec": { items: [i(0, { where: p => 10 * p.a + p.b < 100 }), i(0, { where: p => 10 * p.a + p.b >= 100 }), i(0, { where: p => p.b < 10 }), i(0)] },
  // the 0.5 and 0.45 trap; the hundredths decide; equal; whole numbers in front
  "g4-deccompare": {
    items: [
      i(0, { where: p => p.pa !== p.pb && cmp(afterPoint(p.a, p.pa), afterPoint(p.b, p.pb)) !== cmp(p.a, p.b) }),
      i(0, { where: p => Math.floor(p.a / 10) === Math.floor(p.b / 10) }), i(4, { where: p => p.a === p.b }), i(4, { where: p => p.w > 0 && p.pa !== p.pb }),
    ],
  },
  "g4-convert": {
    items: [
      i(0, { where: p => p.m === 0 }), i(3, { where: p => p.m > 0 && (p.k === 0 || p.k === 3) }), i(3, { where: p => p.m > 0 && (p.k === 1 || p.k === 2) }),
      i(3, { story: true }),
    ],
  },
  // index % 3 picks the question: difference, total of one stack (of 2 or more, so there is something to add: Review
  // note 3), how many longer; then a difference in eighths
  "g4-lineplot": {
    items: [
      i(3), i(4, { where: p => stack(p) >= 2 }), i(5), i(6, { where: p => p.d === 8 }),
    ],
  },
  // every item asks for both, which is the idea
  "g4-area": { items: [i(0, { where: p => p.l <= 10 }), i(0, { where: p => p.l >= 11 }), i(0), i(0)] },
  // index % 3 picks the kind: a line, ray or segment; an acute and an obtuse angle; perpendicular and intersecting lines
  "g4-lines": {
    items: [
      i(3), i(4, { where: p => p.deg < 90 }), i(7, { where: p => p.deg > 90 && p.deg < 180 }), i(5, { where: p => p.item === 1 }),
      i(8, { where: p => p.item === 2 }),
    ],
  },
  "g4-angles": { items: [i(0), i(3, { where: p => !p.st }), i(3, { where: p => p.st }), i(3, { where: p => p.st && p.a % 10 !== 0 })] },
  // a fold that works, one that doesn't, a count, and a count for the rectangle or the parallelogram (the diagonal trap)
  "g4-symmetry": {
    items: [
      i(4, { where: p => p.line < SHAPES[p.shape]!.lines.length }), i(6, { where: p => p.line >= SHAPES[p.shape]!.lines.length }), i(3),
      i(5, { where: p => p.shape === 1 || p.shape === 6 }),
    ],
  },
};
