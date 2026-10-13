// 2nd grade in v2 (curriculum/specs/v2/grade2.md, signed off by Review 2026-10-13): what each lesson builds on, and its skill check.
// The rare check items are built directly when the draws don't find one (Review note 1).
import { type CheckRecipe, i } from "../check-kit";

/** g2-hundreds: the tens digit */
const tens = (n: number) => Math.floor(n / 10) % 10;
/** g2-coins: a dime (2) against a penny (0) or a nickel (1) */
const dimeVsLess = (p: { coin: number; other: number }) => (p.coin === 2 && p.other < 2) || (p.other === 2 && p.coin < 2);

export const depends: Record<string, string[]> = {
  "g2-hundreds": ["g1-tensones"],
  "g2-skip": ["k-tens", "g2-hundreds"],
  "g2-evenodd": ["k-count20"],
  "g2-regroup": ["g1-addtens", "g1-add20"],
  "g2-subregroup": ["g2-regroup", "g1-sub20"],
  "g2-within1000": ["g2-hundreds", "g2-regroup", "g2-subregroup"],
  "g2-coins": [],
  "g2-money": ["g2-coins", "g2-skip"],
  "g2-time5": ["g1-time", "g2-skip"],
  "g2-measure": ["g1-measure", "g1-sub20"],
  "g2-estimate": ["g2-measure"],
  "g2-bargraph": ["g1-picgraph"],
  "g2-lineplot": ["g2-bargraph", "g2-measure"],
  "g2-arrays": ["g2-skip"],
  "g2-solids": ["k-solids"],
  "g2-shares": ["g1-halves"],
};

export const checks: Record<string, CheckRecipe> = {
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
