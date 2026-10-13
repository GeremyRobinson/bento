// 3rd grade in v2 (curriculum/specs/v2/grade3.md, signed off by Review 2026-10-13): what each lesson builds on, and its skill check.
// The rare check item in g3-mult10 is built directly when the draws don't find one (Review note 2).
import { type CheckRecipe, i } from "../check-kit";
import { jumps, type AddSubProblem } from "../lessons/grade3/g3-addsub";
import { kindOf } from "../lessons/grade3/g3-fraccompare";
import { parts } from "../lessons/grade3/g3-elapsed";
import { roundParts } from "../lessons/grade3/g3-round";

/** g3-mult10: the fact a × (t ÷ 10) */
const fact = (p: { a: number; t: number }) => p.a * (p.t / 10);
/** g3-mult10: the facts under 10, a and t ÷ 10 (Review note 2) */
const SMALL = [[2, 2], [2, 3], [2, 4], [3, 2], [3, 3], [4, 2]] as const;
/** g3-addsub: the place value a jump lands on in the running number, as jumpStep works it out */
const digitOf = (j: ReturnType<typeof jumps>[number]) => j.from % (j.place * 10) - (j.from % j.place);
/** g3-addsub: adding, a jump makes a new ten or hundred */
const makesNew = (p: AddSubProblem) => p.s === 1 && jumps(p).some(j => j.place < 100 && digitOf(j) + j.v >= j.place * 10);
/** g3-addsub: taking away, a jump needs a trade */
const needsTrade = (p: AddSubProblem) => p.s === -1 && jumps(p).some(j => j.place < 100 && digitOf(j) < j.v);

export const depends: Record<string, string[]> = {
  "g3-facts": ["g2-arrays", "g2-skip"],
  "g3-divfacts": ["g3-facts"],
  "g3-split": ["g3-facts"],
  "g3-mult10": ["g3-facts", "g2-hundreds"],
  "g3-twostep": ["g3-facts", "g3-divfacts"],
  "g3-round": ["g2-hundreds"],
  "g3-addsub": ["g2-within1000", "g2-subregroup"],
  "g3-unitfrac": ["g2-shares"],
  "g3-fracline": ["g3-unitfrac"],
  "g3-fraccompare": ["g3-unitfrac"],
  "g3-area": ["g2-arrays", "g3-facts"],
  "g3-perim": ["g2-measure", "g2-regroup"],
  "g3-elapsed": ["g2-time5"],
  "g3-mass": ["g3-addsub", "g3-divfacts"],
  "g3-liters": ["g3-mass", "g3-divfacts"],
  "g3-graphs": ["g2-bargraph", "g2-skip"],
  "g3-lineplot": ["g3-fracline", "g2-lineplot"],
  "g3-quads": ["k-shapes"],
};

export const checks: Record<string, CheckRecipe> = {
  // every item keeps the turn-around step, so no squares (Review note 1: the story item too)
  "g3-facts": {
    items: [
      i(3, { where: p => p.a !== p.b }), i(3, { where: p => p.a >= 6 && p.b >= 6 && p.a !== p.b }),
      i(3, { where: p => p.a !== p.b }), i(3, { where: p => p.a !== p.b, story: true }),
    ],
  },
  "g3-divfacts": { items: [i(3, { where: p => p.b >= 6 }), i(3, { where: p => p.a / p.b >= 6 }), i(3), i(3, { story: true })] },
  "g3-split": { items: [i(3, { where: p => p.b >= 8 }), i(3, { where: p => p.a >= 6 }), i(3), i(3, { story: true })] },
  "g3-mult10": {
    items: [
      i(3, { where: p => fact(p) < 10, fix: p => { const [a, m] = SMALL[(p.a + p.t / 10) % SMALL.length]!; return { a, t: m * 10 }; } }),
      i(3, { where: p => fact(p) >= 10 }), i(3, { where: p => fact(p) % 10 === 0 }), i(3, { story: true }),
    ],
  },
  // the lesson is all lead, so no story item
  "g3-twostep": { items: [i(3, { where: p => p.kind === 0 }), i(3, { where: p => p.kind === 1 }), i(3, { where: p => p.kind === 2 }), i(3, { where: p => p.kind === 2 })] },
  "g3-round": {
    items: [
      i(3, { where: p => p.to === 10 && roundParts(p).ans > p.n }), i(3, { where: p => p.to === 100 && roundParts(p).ans < p.n }),
      i(3, { where: p => p.to === 100 && roundParts(p).ans > p.n }), i(3, { where: p => p.n === roundParts(p).mid }),
    ],
  },
  "g3-addsub": { items: [i(3, { where: makesNew }), i(3, { where: needsTrade }), i(3, { where: p => p.s === -1 }), i(3, { story: true })] },
  "g3-unitfrac": { items: [i(3, { where: p => p.k === 1 }), i(3, { where: p => p.k >= 2 }), i(3, { where: p => p.k >= 2 && (p.b === 6 || p.b === 8) }), i(3)] },
  "g3-fracline": { items: [i(3, { where: p => p.w === 1 }), i(3, { where: p => p.w === 2 }), i(3, { where: p => p.b === 6 || p.b === 8 }), i(3)] },
  // both tap steps stay: they are the idea
  "g3-fraccompare": {
    items: [
      i(3, { where: p => kindOf(p) === "bottom" }), i(3, { where: p => kindOf(p) === "top" }),
      i(3, { where: p => kindOf(p) === "top" && p.a >= 2 }), i(3, { where: p => kindOf(p) === "equal" }),
    ],
  },
  "g3-area": { items: [i(3), i(3, { where: p => p.l >= 7 }), i(3, { where: p => p.w >= 6 }), i(3)] },
  "g3-perim": { items: [i(3, { where: p => p.kind === 0 }), i(3, { where: p => p.kind === 1 }), i(3, { where: p => p.kind === 2 }), i(3, { where: p => p.kind === 0 })] },
  "g3-elapsed": {
    items: [
      i(3, { where: p => parts(p).m1 + parts(p).m3 < 60 }), i(3, { where: p => parts(p).m1 + parts(p).m3 > 60 }),
      i(3, { where: p => parts(p).H1 <= 12 && parts(p).H2 > 12 }), i(3),
    ],
  },
  // the index sets the kind: i3 the unit and a guess, i4 a dial, i5 a story
  "g3-mass": { items: [i(3), i(4), i(5), i(5, { where: p => p.op === 2 || p.op === 3 })] },
  // i4 is a jug, i3 and i5 are stories
  "g3-liters": { items: [i(4, { where: p => p.step >= 2 }), i(4, { where: p => p.step === 1 }), i(3), i(5, { where: p => p.op === 2 || p.op === 3 })] },
  // i4 picture graph, how many more; i5 bar graph by 10s, together; i7 bar graph by 2s, how many more; i8 picture graph, together
  "g3-graphs": {
    items: [
      i(4), i(5), i(7, { where: p => p.counts[p.x] % 2 === 1 || p.counts[p.y] % 2 === 1 }),
      i(8, { where: p => p.scale === 2 && p.counts[p.x] % 2 === 1 }),
    ],
  },
  // halves on a ruler, fourths on a ruler, which length came up most (the tap step stays), how many in a stack
  "g3-lineplot": { items: [i(0), i(2, { where: p => p.to === 4 }), i(3), i(5)] },
  // square or rectangle with the "also" question, rhombus, trapezoid, parallelogram; each turned at random
  "g3-quads": { items: [i(3), i(4, { where: p => p.shape === 2 }), i(8, { where: p => p.shape === 4 }), i(9, { where: p => p.shape === 3 })] },
};
