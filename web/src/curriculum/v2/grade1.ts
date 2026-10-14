// 1st grade in v2 (curriculum/specs/v2/gradeK-1.md, signed off by Review 2026-10-13): what each lesson builds on, and its skill check.
// The rare check items are built directly when the draws don't find one (Review note 1); g1-tally's first item is one
// bundle only, 5 to 9 marks (Review note 2).
import { type CheckRecipe, i } from "../check-kit";

const tensOf = (n: number) => Math.floor(n / 10);
const onesOf = (n: number) => n % 10;
/** g1-tensones and g1-tenmore take 11 and up, so a whole number of tens is 20 or more */
const roundTen = (n: number) => Math.max(20, n - (n % 10));

type Three = { a: number; b: number; c: number };
/** g1-three's "Pick two" step, as the lesson decides it: exactly one pair makes 10 or a double, and the three pairs read differently */
const OFFER: [number, number][] = [[0, 1], [0, 2], [1, 2]];
function pick({ a, b, c }: Three): "ten" | "double" | null {
  const v = [a, b, c];
  const why = OFFER.some(([s, t]) => v[s]! + v[t]! === 10) ? "ten" : OFFER.some(([s, t]) => v[s] === v[t]) ? "double" : null;
  const friendly = OFFER.filter(([s, t]) => v[s]! + v[t]! === 10 || v[s] === v[t]).length;
  const labels = new Set(OFFER.map(([s, t]) => `${v[s]} and ${v[t]}`));
  return why && friendly === 1 && labels.size === 3 ? why : null;
}

export const depends: Record<string, string[]> = {
  "g1-tensones": ["k-teens", "k-tens"],
  "g1-compare": ["g1-tensones", "k-compare"],
  "g1-tenmore": ["g1-tensones", "k-tens"],
  "g1-add20": ["k-add", "k-count20"],
  "g1-ten": ["k-make10", "k-teens"],
  "g1-three": ["g1-ten", "g1-add20"],
  "g1-sub20": ["g1-ten", "k-sub"],
  "g1-missing": ["g1-ten", "k-teens"],
  "g1-addtens": ["g1-tenmore", "g1-tensones"],
  "g1-time": [],
  "g1-measure": ["k-length", "k-sub"],
  "g1-halves": ["k-shapes"],
  "g1-picgraph": ["k-sort", "k-sub"],
  "g1-tally": ["g1-picgraph", "g1-three"],
};

export const checks: Record<string, CheckRecipe> = {
  // ones > tens catches swapped digits
  "g1-tensones": {
    items: [
      i(3, { where: p => tensOf(p.n) >= 4 }), i(3, { where: p => onesOf(p.n) === 0, fix: p => ({ n: roundTen(p.n) }) }),
      i(3, { where: p => onesOf(p.n) > tensOf(p.n) }), i(3),
    ],
  },
  // the first: the tens decide even though the smaller number has the bigger ones digit (like 39 and 52)
  "g1-compare": {
    items: [
      i(3, { where: p => tensOf(p.a) !== tensOf(p.b) && onesOf(Math.min(p.a, p.b)) > onesOf(Math.max(p.a, p.b)) }),
      i(3, { where: p => tensOf(p.a) !== tensOf(p.b) }),
      i(3, { where: p => tensOf(p.a) === tensOf(p.b) && p.a > p.b }),
      i(3, {
        where: p => tensOf(p.a) === tensOf(p.b) && p.a < p.b,
        // same tens, smaller first: a's tens with the two ones digits in order (moved apart by one when they match)
        fix: p => {
          const t = tensOf(p.a) * 10, x = onesOf(p.a), y = onesOf(p.b);
          if (x !== y) return { a: t + Math.min(x, y), b: t + Math.max(x, y) };
          return x < 9 ? { a: t + x, b: t + x + 1 } : { a: t + 8, b: t + 9 };
        },
      }),
    ],
  },
  "g1-tenmore": {
    items: [
      i(3, { where: p => p.more === 1 }), i(3, { where: p => p.more === 0 }),
      i(4, { where: p => p.n % 10 === 0, fix: p => ({ ...p, n: roundTen(p.n) }) }), i(3, { where: p => p.more === 0 && p.n >= 50 }),
    ],
  },
  // a < b: starting with the bigger number means switching the order
  "g1-add20": { items: [i(3, { where: p => p.a < p.b }), i(3, { where: p => p.a < p.b }), i(3, { where: p => p.a > p.b }), i(3, { where: p => Math.min(p.a, p.b) >= 4 })] },
  "g1-ten": { items: [i(3, { where: p => p.a === 9 }), i(3, { where: p => p.a === 6 || p.a === 7 }), i(3, { where: p => p.b >= 7 }), i(3)] },
  "g1-three": {
    items: [i(3, { where: p => pick(p) === "ten" }), i(3, { where: p => pick(p) === "double" }), i(3, { where: p => pick(p) != null }), i(3, { story: true })],
  },
  // b − (a − 10) ≥ 4: a long second hop
  "g1-sub20": { items: [i(3), i(3, { where: p => p.a >= 15 }), i(3, { where: p => p.b - (p.a - 10) >= 4 }), i(3, { where: p => p.b === 9 })] },
  "g1-missing": { items: [i(3, { where: p => p.first === 0 }), i(3, { where: p => p.first === 1 }), i(3, { where: p => p.a <= 5 }), i(3, { where: p => p.c - 10 >= 5 })] },
  "g1-addtens": { items: [i(3, { where: p => p.k === 1 }), i(3, { where: p => p.k >= 4 }), i(3, { where: p => tensOf(p.n) >= 5 }), i(3)] },
  "g1-time": { items: [i(3, { where: p => p.minute === 0 }), i(3, { where: p => p.minute === 30 }), i(3, { where: p => p.minute === 30 }), i(3)] },
  "g1-measure": {
    items: [i(3, { where: p => p.a > p.b }), i(3, { where: p => p.a < p.b }), i(3, { where: p => Math.abs(p.a - p.b) === 1 }), i(3, { where: p => p.a >= 10 || p.b >= 10 })],
  },
  "g1-halves": { items: [i(3, { where: p => p.parts === 2 }), i(3, { where: p => p.parts === 4 }), i(3, { where: p => p.parts === 4 }), i(3, { where: p => p.shape === 2 })] },
  // the index picks the question: read a row, most or fewest, how many more, together
  "g1-picgraph": { items: [i(4), i(5), i(6), i(7)] },
  // ask 0 with one bundle, ask 0 with two, how many more, in all
  "g1-tally": {
    items: [i(3, { where: p => p.counts[p.x] >= 5 && p.counts[p.x] <= 9 }), i(6, { where: p => p.counts[p.x] >= 10 }), i(4), i(5)],
  },
};
