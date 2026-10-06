// Linear algebra, units 3 and 4 (b2-la-09 to b2-la-15): solving and fitting, then eigen.
import type { B2Lesson, B2Step, SceneRef } from "../../model";
import { fracStep, multiStep, numStep, slip, tapStep, wholeStep } from "../../make";
import { det, eigen, inverse, mul, transpose, solve } from "../../tools/matrix";
import { apply2, col, cross, dec, det2, det3, dot, fromCols, lin, mat, mm, rankOf, sn, sumText, tr, vec, type Vec } from "./maths";
import { CELLS, ints, nz, S, XYZ } from "./unit12";

/* ------------------------------------------------------------------ unit 3 · solving and fitting ------------------------------------------------------------------ */

interface P09 { L: number[][]; U: number[][]; x0: Vec }
const eqn = (row: number[], rhs: number, names = XYZ) => `${lin(row.map((c, i) => [c, names[i]!] as [number, string]))} = ${sn(rhs)}`;
/** A = L U, b = A x₀, and the right side after each elimination (c = L⁻¹ b), all in whole numbers */
function sys09(p: P09) {
  const A = mm(p.L, p.U), b = A.map(r => dot(r, p.x0));
  const n = A.length, c = [...b];
  for (let i = 0; i < n; i++) for (let j = 0; j < i; j++) c[i]! -= p.L[i]![j]! * c[j]!;
  return { A, b, c, n };
}

export const la09: B2Lesson<P09> = {
  id: "b2-la-09", track: "la", unit: 3, title: "Row reduction",
  youCan: "solve three equations in three unknowns by row reduction.",
  needs: ["b2-la-08", "g9-elim"],
  tools: [S.space, "matrix"],
  play: { scene: S.space, props: { mode: "planes" },
    say: "Three planes in 3D, one for each equation. Step through the row operations: the planes change, but the point where all three meet never moves. Drag to turn the picture." },
  guess: { scene: S.space, props: { mode: "planes", r0: "1,1,1,3", r1: "1,2,0,4", r2: "2,3,1,7", noSteps: true, quiet: true, yaw: 0.3, pitch: 0.5 }, kind: "choice",
    options: ["In one point", "Along a line", "Not at all"], answer: 1,
    ask: "The equations are x + y + z = 3, x + 2y = 4 and 2x + 3y + z = 7. Do their three planes meet in one point, along a line, or not at all?",
    revealProps: { alongLine: true },
    reveal: "Turned to look along it, all three planes pass through one line: the third equation is the first two added up, so it adds nothing new." },
  nameIt: {
    say: [
      "Swapping rows, scaling a row, and adding a multiple of one row to another never change the solutions.",
      "Clear out below each pivot, then solve from the bottom up. One pivot per unknown means exactly one solution.",
    ],
    formula: ["new row = row − (multiplier) × pivot row", "multiplier = entry ÷ pivot"],
  },
  workIt: {
    reference: { L: [[1, 0, 0], [2, 1, 0], [1, 1, 1]], U: [[1, 1, 1], [0, 1, -1], [0, 0, 3]], x0: [1, 2, 3] },
    generate(rng, i) {
      const n = i < 3 ? 2 : 3;
      const L = Array.from({ length: n }, (_, r) => Array.from({ length: n }, (_, c) => (r === c ? 1 : c < r ? (i < 3 ? rng.int(1, 2) : rng.int(-2, 2)) : 0)));
      const U = Array.from({ length: n }, (_, r) => Array.from({ length: n }, (_, c) => (r === c ? (i < 3 ? rng.int(1, 2) : rng.pick([-3, -2, -1, 1, 2, 3])) : c > r ? rng.int(i < 3 ? 0 : -3, i < 3 ? 2 : 3) : 0)));
      const x0 = ints(rng, n, i < 3 ? 0 : -4, 4);
      return { L, U, x0 };
    },
    show: p => { const { A, b, n } = sys09(p); return `Solve ${A.map((r, i) => `**${eqn(r, b[i]!, XYZ.slice(0, n))}**`).join(", ")}.`; },
    steps(p) {
      const { A, b, c, n } = sys09(p), names = XYZ.slice(0, n), U = p.U, x = p.x0;
      const out: B2Step[] = [];
      const mult = (id: string, label: string, m: number, entry: number, pivot: number, after: string) =>
        wholeStep(id, label, m, { hint: `Entry ÷ pivot: ${sn(entry)} ÷ ${pivot < 0 ? `(${sn(pivot)})` : sn(pivot)}.`, done: `${label}: ${sn(m)}, so the row becomes ${after}`,
          slips: [m !== 0 && slip("added instead of subtracted", -m, "Subtract the multiple, so the entry below the pivot becomes 0."), entry !== 0 && slip("flipped the division", pivot / entry, "The multiplier is the entry ÷ the pivot: the number to clear, over the pivot.")] });
      if (n === 2) {
        out.push(mult("m21", "Multiplier for row 2", p.L[1]![0]!, A[1]![0]!, A[0]![0]!, eqn(U[1]!, c[1]!, names)));
        out.push(wholeStep("y", "y", x[1]!, { hint: `Row 2 is now ${eqn(U[1]!, c[1]!, names)}.`,
          slips: [slip("changed only the left side", b[1]! / U[1]![1]!, "Do the same to the number on the right of the equals sign.")] }));
        out.push(wholeStep("x", "x", x[0]!, { hint: `Put y = ${sn(x[1]!)} into ${eqn(A[0]!, b[0]!, names)}.`,
          slips: [slip("top down", b[0]! / A[0]![0]!, "Start at the bottom row: it has only one unknown left. Then use y in the top row.")] }));
        return out;
      }
      // row 3 after its first clean-up: L₃₂ U₂ + U₃, with c₃ + L₃₂ c₂ on the right
      const r3mid = U[2]!.map((v, j) => v + p.L[2]![1]! * U[1]![j]!), c3mid = c[2]! + p.L[2]![1]! * c[1]!;
      out.push(mult("m21", "Multiplier for row 2", p.L[1]![0]!, A[1]![0]!, A[0]![0]!, eqn(U[1]!, c[1]!)));
      out.push(mult("m31", "Multiplier for row 3", p.L[2]![0]!, A[2]![0]!, A[0]![0]!, eqn(r3mid, c3mid)));
      out.push(mult("m32", "Next multiplier", p.L[2]![1]!, r3mid[1]!, U[1]![1]!, eqn(U[2]!, c[2]!)));
      out.push(wholeStep("z", "z", x[2]!, { hint: `The last row is now ${eqn(U[2]!, c[2]!)}.`,
        slips: [
          slip("changed only the left side", b[2]! / U[2]![2]!, "Do the same to the number on the right of the equals sign."),
          slip("top down", b[0]! / A[0]![0]!, "Start at the bottom row: it has only one unknown left."),
        ] }));
      out.push(wholeStep("y", "y", x[1]!, { hint: `Row 2 is ${eqn(U[1]!, c[1]!)}; put in z = ${sn(x[2]!)}.`,
        slips: [slip("changed only the left side", (b[1]! - U[1]![2]! * x[2]!) / U[1]![1]!, "Do the same to the number on the right of the equals sign.")] }));
      out.push(wholeStep("x", "x", x[0]!, { hint: `Row 1 is ${eqn(A[0]!, b[0]!)}; put in y and z.` }));
      return out;
    },
    scene: (p): SceneRef => {
      const { A, b, n } = sys09(p);
      if (n === 2) return { scene: S.play, props: { mode: "move", a: A[0]![0]!, c: A[1]![0]!, b: A[0]![1]!, d: A[1]![1]!, px: p.x0[0]!, py: p.x0[1]!, quiet: true } };
      return { scene: S.space, props: { mode: "planes", r0: [...A[0]!, b[0]!].join(","), r1: [...A[1]!, b[1]!].join(","), r2: [...A[2]!, b[2]!].join(","), quiet: true } };
    },
  },
  // multipliers from a plain elimination on A itself, the answer from a library solve
  oracle: p => {
    const { A, b, n } = sys09(p), T = A.map(r => [...r]), ms: number[] = [];
    for (let c = 0; c < n - 1; c++) for (let r = c + 1; r < n; r++) { const m = T[r]![c]! / T[c]![c]!; ms.push(m); T[r] = T[r]!.map((v, j) => v - m * T[c]![j]!); }
    const x = solve(A, b);
    return n === 2 ? [ms[0]!, x[1]!, x[0]!] : [ms[0]!, ms[1]!, ms[2]!, x[2]!, x[1]!, x[0]!];
  },
  useIt: {
    say: [
      "A recipe from three foods has to hit exact targets for calories, protein and fiber. Each target is one equation, each food's amount one unknown: one system, one answer.",
      "Row reduction is how a solver finds it, and the Matrix pad's A⁻¹ does the same work.",
    ],
    scene: { scene: S.space, props: { mode: "planes" } },
  },
  deeper: [
    "The multipliers you used are exactly the entries of L, and the rows you ended with are U: row reduction is A = L U.",
    "Partial pivoting swaps in the row with the biggest pivot first, so a computer never divides by something tiny.",
    "The cost is about (2/3)n³ steps for n equations, which is why big systems are solved by cleverer methods (track `cs`).",
  ],
};

type P10 = { kind: "r2" | "r3" | "r1" | "w4"; c: Vec[]; p: number; q: number; r: number; s: number; t: number };
const indep2 = (a: Vec, b: Vec) => cross(a, b).some(x => x !== 0);
/** the columns of the problem's matrix, made from the generator's choices */
function cols10(P: P10): Vec[] {
  const [c1, c2] = P.c as [Vec, Vec], mix = (x: number, y: number) => c1.map((v, i) => x * v + y * c2[i]!);
  if (P.kind === "r1") return [c1, c1.map(v => P.p * v), c1.map(v => P.q * v)];
  if (P.kind === "r2") return [c1, c2, mix(P.p, P.q)];
  if (P.kind === "r3") return [c1, c2, P.c[2]!];
  // 3 × 4: rank 2 when there is no third chosen column, rank 3 when there is
  if (P.c.length === 2) return [c1, c2, mix(P.p, P.q), mix(P.r, P.s)];
  const c3 = P.c[2]!;
  return [c1, c2, c3, c1.map((v, i) => P.r * v + P.s * c2[i]! + P.t * c3[i]!)];
}
const NULL3 = ["only the zero arrow", "a line of arrows", "a plane of arrows"];
/** "Here row 3 gives −4 − 3 + 7 = 0." for the right null arrow */
function check10(A: number[][], x: Vec) {
  const k = A.reduce((best, r, i) => (r.filter(v => v).length > A[best]!.filter(v => v).length ? i : best), 0);
  return `Check: A times your arrow should be 0. Here row ${k + 1} gives ${sumText(A[k]!.map((v, j) => v * x[j]!))} = 0.`;
}

export const la10: B2Lesson<P10> = {
  id: "b2-la-10", track: "la", unit: 3, title: "Rank, column space and null space",
  youCan: "find a matrix's rank and the arrows it sends to zero.",
  needs: ["b2-la-04", "b2-la-09"],
  tools: [S.space, "matrix"],
  play: { scene: S.space, props: { mode: "collapse", e: 1.5 },
    say: "A 3 × 3 matrix acts on all of space: its columns make the box the unit cube lands on. Drag the third column into the plane of the other two: the image flattens to a plane, and a whole line of arrows lights up because they now land on 0." },
  guess: { scene: S.space, props: { mode: "collapse", e: 0, quiet: true }, kind: "choice", options: ["A point", "A line", "A plane", "All of space"], answer: 2,
    ask: "The third column here is a mix of the first two. What shape is the image of all of space: a point, a line, a plane or all of space?",
    revealProps: { e: 1.5, flatten: true },
    reveal: "Watch the cube's image flatten as the third column drops in: everything lands in the plane of the first two columns. Rank 2, and a line of arrows goes to 0." },
  nameIt: {
    say: [
      "The rank is the number of pivots: the dimension of everything the matrix can reach (its column space).",
      "The null space is every x with A x = 0. Together they account for every column.",
    ],
    formula: ["rank + nullity = number of columns"],
  },
  workIt: {
    reference: { kind: "r2", c: [[1, 0, 2], [0, 1, 1]], p: 2, q: 3, r: 0, s: 0, t: 0 },
    generate(rng, i) {
      const lo = i < 3 ? 0 : -3, hi = i < 3 ? 2 : 3;
      const two = () => { for (;;) { const a = ints(rng, 3, lo, hi), b = ints(rng, 3, lo, hi); if (indep2(a, b)) return [a, b]; } };
      const third = (a: Vec, b: Vec) => { for (;;) { const c = ints(rng, 3, -3, 3); if (det3([a, b, c]) !== 0) return c; } };
      const kind: P10["kind"] = i < 3 ? "r2" : i === 3 ? rng.pick(["r3", "r1"] as const) : rng.pick(["r2", "r2", "r3", "r1", "w4", "w4"] as const);
      const pq = () => { for (;;) { const p = i < 3 ? rng.int(1, 3) : rng.int(-3, 3), q = i < 3 ? rng.int(1, 3) : rng.int(-3, 3); if (p || q) return [p, q]; } };
      if (kind === "r1") { let c1: Vec; do { c1 = ints(rng, 3, -3, 3); } while (c1.every(v => !v)); return { kind, c: [c1], p: rng.int(-3, 3), q: rng.int(-3, 3), r: 0, s: 0, t: 0 }; }
      const [a, b] = two() as [Vec, Vec], [p, q] = pq() as [number, number];
      if (kind === "r2") return { kind, c: [a, b], p, q, r: 0, s: 0, t: 0 };
      if (kind === "r3") return { kind, c: [a, b, third(a, b)], p: 0, q: 0, r: 0, s: 0, t: 0 };
      const r = rng.int(-3, 3), s = rng.int(-3, 3);
      return rng.next() < 0.5 ? { kind, c: [a, b], p, q, r, s, t: 0 } : { kind, c: [a, b, third(a, b)], p: 0, q: 0, r, s, t: nz(rng, -3, 3) };
    },
    show: P => { const C = cols10(P); return `A has columns ${C.map(c => `**${vec(c)}**`).join(", ")}. Find its rank and the arrows it sends to 0.`; },
    steps(P) {
      const C = cols10(P), A = fromCols(C), m = C.length, rank = P.kind === "r1" ? 1 : P.kind === "r3" ? 3 : P.kind === "r2" ? 2 : P.c.length === 2 ? 2 : 3;
      const rows = A.filter(r => r.some(v => v)).length;
      const rankStep = wholeStep("rank", "Rank", rank, { ask: "Count the pivots after reducing.", hint: "Reduce the rows, then count the rows that aren't all zeros.",
        slips: [slip("counted rows before reducing", rows, "Reduce first. A row can turn into all zeros.")] });
      const nullStep = wholeStep("nul", m === 4 ? "Nullity = 4 − rank" : "Nullity", m - rank, { hint: `rank + nullity = ${m}, the number of columns.`,
        slips: [slip("rank + nullity = rows", 3 - rank, "It is the number of columns: each column is an unknown.")] });
      if (P.kind === "r3") return [rankStep, nullStep, tapStep("null", "The arrows A sends to 0", NULL3, 0, { hint: "Nullity 0: nothing but 0 itself.",
        slips: [slip("a line", 1, "Rank 3 means no column is a mix of the others, so only the zero arrow goes to 0."), slip("a plane", 2, "Rank 3 means no column is a mix of the others, so only the zero arrow goes to 0.")] })];
      if (P.kind === "r1") {
        const x1 = [-P.p, 1, 0], x2 = [-P.q, 0, 1];
        return [rankStep, nullStep,
          wholeStep("n1", "Null arrow as (?, 1, 0)", -P.p, { hint: `Column 2 is ${lin([[P.p, "c₁"]])}, so ${lin([[-P.p, "c₁"], [1, "c₂"]])} = 0.`, done: `Null arrow as (?, 1, 0): ${vec(x1)}`,
            slips: [P.p !== 0 && slip("null arrow sign", P.p, check10(A, x1))] }),
          wholeStep("n2", "Null arrow as (?, 0, 1)", -P.q, { hint: `Column 3 is ${lin([[P.q, "c₁"]])}, so ${lin([[-P.q, "c₁"], [1, "c₃"]])} = 0.`, done: `Null arrow as (?, 0, 1): ${vec(x2)}`,
            slips: [P.q !== 0 && slip("null arrow sign", P.q, check10(A, x2))] }),
        ];
      }
      const x = P.kind === "r2" ? [-P.p, -P.q, 1] : P.c.length === 2 ? [-P.r, -P.s, 0, 1] : [-P.r, -P.s, -P.t, 1];
      const signed = x.map((v, i) => (i === x.length - 1 ? v : -v));
      const label = m === 3 ? "Null arrow with third entry 1" : P.c.length === 2 ? "Null arrow with last entry 1 and third entry 0" : "Null arrow with last entry 1";
      const mixText = P.kind === "r2" ? `Column 3 is ${lin([[P.p, "c₁"], [P.q, "c₂"]])}` : `Column 4 is ${lin([[P.r, "c₁"], [P.s, "c₂"], [P.t, "c₃"]])}`;
      return [rankStep, nullStep, multiStep("null", label, x, "whole", { boxes: x.map((_, i) => `x${"₁₂₃₄"[i]}`), hint: `${mixText}, so move it across: the arrow's entries are the mixing numbers with their signs flipped.`,
        slips: [slip("null arrow sign", signed, check10(A, x))] })];
    },
    scene: (P): SceneRef => {
      const C = cols10(P);
      if (C.length !== 3) return { scene: S.space, props: { mode: "collapse", e: 0 } };
      return { scene: S.space, props: { mode: "collapse", ux: C[0]![0]!, uy: C[0]![1]!, uz: C[0]![2]!, vx: C[1]![0]!, vy: C[1]![1]!, vz: C[1]![2]!, wx: C[2]![0]!, wy: C[2]![1]!, wz: C[2]![2]!, quiet: true } };
    },
  },
  // the rank by elimination, the null arrows by solving the remaining columns' normal equations
  oracle: P => {
    const C = cols10(P), A = fromCols(C), m = C.length, rank = rankOf(A);
    const out = [rank, m - rank];
    if (P.kind === "r3") return [...out, 0];
    if (P.kind === "r1") { const c1 = C[0]!; return [...out, -dot(c1, C[1]!) / dot(c1, c1), -dot(c1, C[2]!) / dot(c1, c1)]; }
    // solve [first columns] y = −(last column) by least squares: exact, since it lies in their span
    const k = P.kind === "r2" ? 2 : P.c.length === 2 ? 2 : 3;
    const B = fromCols(C.slice(0, k)), last = C[m - 1]!.map(v => [-v]);
    const y = mul(inverse(mul(transpose(B), B)), mul(transpose(B), last)).flat();
    const full = m === 3 ? [...y, 1] : k === 2 ? [...y, 0, 1] : [...y, 1];
    const z = mul(A, full.map(v => [v])).flat();
    if (z.some(v => Math.abs(v) > 1e-9)) throw new Error("not a null arrow");
    return [...out, ...full];
  },
  useIt: {
    say: [
      "Balance CH₄ + O₂ → CO₂ + H₂O. Count carbon, hydrogen and oxygen in each molecule, with the products' columns entered as negatives: a 3 × 4 matrix of rank 3. Its null arrow, scaled to whole numbers, is (1, 2, 1, 2): the balanced equation CH₄ + 2O₂ → CO₂ + 2H₂O.",
      "For the build: the rank of `img` is how many layers rebuild your picture exactly.",
    ],
    scene: { scene: S.space, props: { mode: "collapse", e: 1 } },
  },
  deeper: [
    "The four fundamental subspaces: the column space and the null space of Aᵀ, and the row space and the null space of A. The row space is perpendicular to the null space, and row rank equals column rank.",
    "The Fredholm alternative: A x = b has an answer exactly when b is perpendicular to every y with Aᵀ y = 0.",
    "Quotient spaces: treat two arrows as the same when they differ by a null arrow. Then A becomes one-to-one.",
  ],
};

interface P11 { xs: number[]; ys: number[] }
const sums = (p: P11) => {
  const n = p.xs.length, Sx = p.xs.reduce((a, b) => a + b, 0), Sxx = p.xs.reduce((a, b) => a + b * b, 0);
  const Sy = p.ys.reduce((a, b) => a + b, 0), Sxy = p.xs.reduce((a, x, i) => a + x * p.ys[i]!, 0);
  const m = (n * Sxy - Sx * Sy) / (n * Sxx - Sx * Sx), c = (Sy - m * Sx) / n;
  return { n, Sx, Sxx, Sy, Sxy, m, c };
};

export const la11: B2Lesson<P11> = {
  id: "b2-la-11", track: "la", unit: 3, title: "Least squares: the best wrong answer",
  youCan: "fit the best line to data that no line fits exactly.",
  needs: ["b2-la-03", "b2-la-10", "st-lsrl"],
  tools: [S.res, "graph2d"],
  play: { scene: S.res, props: { set: "lesson" },
    say: "Drag the data points, and set your line with the two sliders. Each point's miss shows as a square, and the total area of the squares is the error." },
  guess: { scene: S.res, props: { set: "lesson", quiet: true }, kind: "slider", min: -1, max: 3, step: 0.05, start: 0.3, answer: 1.1, near: 0.2,
    format: x => x.toFixed(2),
    ask: "Your line passes through the center of the data. Drag its slope to your best fit.",
    revealProps: { best: true },
    reveal: "The least-squares line has slope 11/10 and the smallest total of squares there is. Compare its amber squares with your blue ones." },
  nameIt: {
    say: [
      "When A x = b has no answer, take the x̂ that gets A x as close to b as possible.",
      "The leftover miss b − A x̂ is perpendicular to every column of A, which gives the normal equations.",
    ],
    formula: ["Aᵀ A x̂ = Aᵀ b", "for y = m x + c: [[Σx², Σx], [Σx, n]]·(m, c) = (Σxy, Σy)"],
  },
  workIt: {
    reference: { xs: [-1, 0, 1], ys: [1, 2, 6] },
    generate(rng, i) {
      if (i < 3) return { xs: [-1, 0, 1], ys: ints(rng, 3, -4, 8) };
      return { xs: [0, 1, 2, 3], ys: ints(rng, 4, 0, 9) };
    },
    show: p => `Fit y = m x + c to the points ${p.xs.map((x, i) => `**(${sn(x)}, ${sn(p.ys[i]!)})**`).join(", ")}.`,
    steps(p) {
      const { n, Sx, Sxx, Sy, Sxy, m, c } = sums(p), last = n - 1;
      const meanY = Sy / n;
      return [
        multiStep("ata", "Aᵀ A", [Sxx, Sx, Sx, n], "whole", { boxes: CELLS, hint: "The rows of A are (x, 1): top left Σx², off the diagonal Σx, bottom right the number of points.",
          slips: [slip("Σx for Σx²", [Sx, Sx, Sx, n], "The top left of Aᵀ A is the sum of the squares of x.")] }),
        multiStep("atb", "Aᵀ b", [Sxy, Sy], "whole", { boxes: ["Σxy", "Σy"], hint: "Σxy, then Σy.", slips: [] }),
        fracStep("m", "m", m, { hint: `Solve ${Sxx}m + ${Sx}c = ${sn(Sxy)} and ${Sx}m + ${n}c = ${sn(Sy)}.`.replace(/ \+ 0c|0m \+ /g, ""),
          slips: [
            slip("line through two points", (p.ys[last]! - p.ys[0]!) / (p.xs[last]! - p.xs[0]!), "Two points ignore the rest. Least squares uses every point."),
            slip("swapped m and c", c, "The first unknown pairs with Σx², so it is the slope."),
          ] }),
        fracStep("c", "c", c, { hint: `The line goes through the mean point: c = ȳ − m x̄ = ${sn(meanY)} − ${m < 0 ? `(${sn(m)})` : sn(m)} × ${sn(Sx / n)}.`,
          slips: [slip("swapped m and c", m, "The first unknown pairs with Σx², so it is the slope; c is the other one."), slip("c as the mean of y", meanY, "The line passes through the mean point (x̄, ȳ), so c = ȳ − m x̄.")] }),
      ];
    },
    scene: p => ({ scene: S.res, props: { xs: p.xs.join(","), ys: p.ys.join(","), quiet: true } }),
  },
  // slope from the centered data, no normal equations
  oracle: p => {
    const n = p.xs.length, mx = p.xs.reduce((a, b) => a + b, 0) / n, my = p.ys.reduce((a, b) => a + b, 0) / n;
    const sxy = p.xs.reduce((a, x, i) => a + (x - mx) * (p.ys[i]! - my), 0), sxx = p.xs.reduce((a, x) => a + (x - mx) ** 2, 0);
    const m = sxy / sxx;
    return [p.xs.reduce((a, x) => a + x * x, 0), n * mx, n * mx, n, p.xs.reduce((a, x, i) => a + x * p.ys[i]!, 0), n * my, m, my - m * mx];
  },
  useIt: {
    say: [
      "Project: measure something real, such as phone battery against minutes or a plant's height against days. Type 4 to 8 points and fit the least-squares line. Save it to keep `fit`.",
      "The same squared error is what the build reports as picture quality, and what a learning machine shrinks (b2-ai-01).",
    ],
    project: "la-fit",
  },
  deeper: [
    "The projection matrix P = A(AᵀA)⁻¹Aᵀ drops any b onto the column space, and P² = P: dropping twice changes nothing.",
    "QR gives a steadier solve than the normal equations, and the pseudoinverse A⁺ solves least squares in one line (it comes back in b2-la-17).",
    "Ridge regression adds λI to AᵀA to keep the fit tame. The Gauss–Markov theorem says plain least squares is the best unbiased linear fit when the noise is even (tracks `pr` and `ai`).",
  ],
};

/* ------------------------------------------------------------------ unit 4 · eigen ------------------------------------------------------------------ */

interface P12 { P: number[][]; c0: Vec; d: [number, number] }
/** A = P D P⁻¹, exact: det P = ±1 */
const A12 = (p: P12) => mm(mm(p.P, [[p.d[0], 0], [0, p.d[1]]]), adj2(p.P).map(r => r.map(v => v / det2(p.P))));
const adj2 = (P: number[][]) => [[P[1]![1]!, -P[0]![1]!], [-P[1]![0]!, P[0]![0]!]];

export const la12: B2Lesson<P12> = {
  id: "b2-la-12", track: "la", unit: 4, title: "Change of basis",
  youCan: "rewrite a point and a move in a new set of coordinates.",
  needs: ["b2-la-04", "b2-la-08"],
  tools: [S.vec, S.play],
  play: { scene: S.vec, props: { mode: "basis", one: true, useShelf: true, canMove: true, ux: 1, uy: 1, vx: 1, vy: 2, xx: 3, xy: 5, d1: 3, d2: -1 },
    say: "Two grids overlay: the usual one and one built from your basis (or b₁ = (1, 1), b₂ = (1, 2)). Drag the point and read both sets of coordinates. Switch on the move: along each new grid line it is a pure stretch." },
  guess: { scene: S.vec, props: { mode: "basis", one: true, fixed: true, ux: 1, uy: 1, vx: 1, vy: 2, xx: 3, xy: 5, quiet: true }, kind: "choice",
    options: ["[1, 2]", "[2, 1]", "[3, 5]"], answer: 0,
    ask: "The new grid is made of b₁ = (1, 1) and b₂ = (1, 2). What are the point (3, 5)'s coordinates in the new grid?",
    revealProps: { walk: true },
    reveal: "One step along b₁, then two along b₂: (1, 1) + 2·(1, 2) = (3, 5). In the new grid the point is [1, 2]." },
  nameIt: {
    say: [
      "Put the new basis arrows in the columns of P. Then P turns new coordinates into usual ones, and P⁻¹ goes back.",
      "The same move, seen in the new coordinates, is P⁻¹ A P.",
    ],
    formula: ["x = P c, c = P⁻¹ x", "the move in new coordinates is P⁻¹ A P"],
  },
  workIt: {
    reference: { P: [[1, 1], [1, 2]], c0: [1, 2], d: [3, -1] },
    generate(rng, i) {
      let P: number[][];
      if (i < 3) P = rng.pick([[[1, 1], [0, 1]], [[1, 0], [1, 1]]]);
      else do { P = [ints(rng, 2, -3, 3), ints(rng, 2, -3, 3)]; } while (Math.abs(det2(P)) !== 1);
      let c0: Vec;
      do { c0 = ints(rng, 2, i < 3 ? 0 : -4, i < 3 ? 3 : 4); } while (c0.every(v => !v));
      let d: [number, number];
      do { d = [rng.int(i < 3 ? 1 : -3, i < 3 ? 3 : 4), rng.int(i < 3 ? -1 : -3, i < 3 ? 3 : 4)]; } while (d[0] === d[1]);
      return { P, c0, d };
    },
    show: p => `The new basis arrows are the columns of P = **${mat(p.P)}**. Write x = **${vec(apply2(p.P, p.c0))}** in the new basis, then see A = **${mat(A12(p))}** there.`,
    steps(p) {
      const D = det2(p.P), Pi = adj2(p.P).map(r => r.map(v => v / D)), x = apply2(p.P, p.c0), A = A12(p);
      const p1 = col(p.P, 0), p2 = col(p.P, 1), Ap1 = apply2(A, p1), Ap2 = apply2(A, p2);
      return [
        multiStep("pi", "P⁻¹", Pi.flat(), "whole", { boxes: CELLS, hint: `det P = ${sn(D)}: swap the diagonal, negate the corners${D === -1 ? ", and divide by −1" : ""}.`,
          slips: [slip("didn't swap", [p.P[0]![0]! / D, -p.P[0]![1]! / D, -p.P[1]![0]! / D, p.P[1]![1]! / D], "a and d trade places."), D === -1 && slip("forgot to divide", adj2(p.P).flat(), "Divide every entry by det P = −1.")] }),
        multiStep("c", "c = P⁻¹ x", p.c0, "whole", { boxes: ["c₁", "c₂"], hint: `P⁻¹ times ${vec(x)}.`,
          slips: [slip("used P x", apply2(p.P, x), "P takes new coordinates to old ones. To go from old to new, use P⁻¹.")] }),
        multiStep("ap1", "A times the first basis arrow", Ap1, "whole", { boxes: ["x", "y"], hint: `A·${vec(p1)}.`, done: `A times the first basis arrow: ${vec(Ap1)} = ${lin([[p.d[0], vec(p1)]]).replace(/^(−?\d+)\(/, "$1·(")}` }),
        multiStep("ap2", "A times the second", Ap2, "whole", { boxes: ["x", "y"], hint: `A·${vec(p2)}.`, done: `A times the second: ${vec(Ap2)} = ${lin([[p.d[1], vec(p2)]]).replace(/^(−?\d+)\(/, "$1·(")}` }),
        multiStep("d", "The move in the new basis", [p.d[0], 0, 0, p.d[1]], "whole", { boxes: CELLS, hint: "Each basis arrow only stretches: by how much?",
          slips: [slip("read the arrow as a vector", [Ap1[0]!, Ap2[0]!, Ap1[1]!, Ap2[1]!], `In the new basis, A's first basis arrow is simply ${sn(p.d[0])} times itself: entry ${sn(p.d[0])}, with 0 below it.`)] }),
      ];
    },
    scene: p => { const x = apply2(p.P, p.c0); return { scene: S.vec, props: { mode: "basis", one: true, fixed: true, ux: p.P[0]![0]!, uy: p.P[1]![0]!, vx: p.P[0]![1]!, vy: p.P[1]![1]!, xx: x[0]!, xy: x[1]!, quiet: true } }; },
  },
  // a library's inverse, then P⁻¹ A P
  oracle: p => {
    const A = A12(p), Pi = inverse(p.P), x = mul(p.P, p.c0.map(v => [v]));
    const D = mul(mul(Pi, A), p.P);
    return [...Pi.flat(), ...mul(Pi, x).flat(), ...mul(A, [[p.P[0]![0]!], [p.P[1]![0]!]]).flat(), ...mul(A, [[p.P[0]![1]!], [p.P[1]![1]!]]).flat(), ...D.flat()];
  },
  useIt: {
    say: [
      "Pixel pairs: turn each pair (a, b) into (average, difference) = ((a + b)/2, (a − b)/2). The pair (9, 7) becomes (8, 1).",
      "In this basis most differences are tiny, so they cost almost nothing to store. In the Pair view, the difference picture goes nearly blank.",
    ],
    scene: { scene: S.comp, props: { mode: "pair" } },
  },
  deeper: [
    "What a change of basis can't change: the trace, the determinant and the eigenvalues of a move are the same in every basis.",
    "Not every move has a basis that makes it a pure stretch. Jordan form is the best a move can do: stretches plus a little shear, like [[2, 1], [0, 2]].",
    "Dual bases: some quantities change one way under a change of basis and some the other (covariant and contravariant). It is how Lorentz moves are written (track `re`).",
  ],
};

interface P13 { P: number[][]; l: [number, number] }
/** A = P D P⁻¹ in whole numbers (det P divides exactly) */
const A13 = (p: P13) => { const d = det2(p.P); return mm(mm(p.P, [[p.l[0], 0], [0, p.l[1]]]), adj2(p.P)).map(r => r.map(v => v / d)); };
/** an eigenvector's free entry: (1, ?) when its first entry isn't 0, else (?, 1) */
const evAsk = (v: Vec) => (v[0] !== 0 ? { form: "(1, ?)", val: v[1]! / v[0]! } : { form: "(?, 1)", val: v[0]! / v[1]! });

export const la13: B2Lesson<P13> = {
  id: "b2-la-13", track: "la", unit: 4, title: "Eigenvectors: arrows that only stretch",
  youCan: "find the arrows a move only stretches, and by how much.",
  needs: ["b2-la-07", "b2-la-12"],
  tools: [S.eig, S.play],
  play: { scene: S.eig, props: { mode: "find", a: 4, b: 1, c: 2, d: 3 },
    say: "Drag the test arrow x around the circle. Its image Ax is drawn in pink. When the two line up, x glows, and the ratio of their lengths is the eigenvalue λ." },
  guess: { scene: S.eig, props: { mode: "find", a: 2, b: 1, c: 1, d: 2, quiet: true }, kind: "point", answer: [0.71, 0.71], near: 0.3, start: [0, 1],
    ask: "A = [[2, 1], [1, 2]]. Drag the marker round the circle to a direction where you think x and Ax line up, stretched the most.",
    revealProps: { sweep: true },
    reveal: "The sweep marks every match: along (1, 1) A stretches by 3, and along (1, −1) by 1. Opposite arrows match too." },
  nameIt: {
    say: [
      "An eigenvector stays on its own line: the move only stretches it, by the eigenvalue λ.",
      "The eigenvalues are the λ that make A − λI squash the plane.",
    ],
    formula: ["A v = λ v", "det(A − λI) = λ² − (trace)λ + det = 0"],
  },
  workIt: {
    reference: { P: [[1, 1], [1, -2]], l: [5, 2] },
    generate(rng, i) {
      for (;;) {
        const P = i < 3 ? [[1, nz(rng, -2, 2)], [0, 1]] : [ints(rng, 2, -2, 2), ints(rng, 2, -2, 2)];
        if (Math.abs(det2(P)) !== 1) continue;
        const a = rng.int(i < 3 ? 1 : -4, i < 3 ? 4 : 5), b = rng.int(i < 3 ? 1 : -4, i < 3 ? 4 : 5);
        if (a === b) continue;
        const A = A13({ P, l: [a, b] });
        if (A.flat().some(v => Math.abs(v) > 12)) continue;
        return { P: a > b ? P : [[P[0]![1]!, P[0]![0]!], [P[1]![1]!, P[1]![0]!]], l: [Math.max(a, b), Math.min(a, b)] as [number, number] };
      }
    },
    show: p => `A = **${mat(A13(p))}**. Find its eigenvalues and eigenvectors.`,
    steps(p) {
      const A = A13(p), [[a, b], [c, d]] = A as [[number, number], [number, number]], t = a + d, D = a * d - b * c;
      const [l1, l2] = p.l, e1 = evAsk(col(p.P, 0)), e2 = evAsk(col(p.P, 1));
      const triangular = b === 0 || c === 0;
      const zeroA = (form: string) => (form === "(1, ?)" ? (b !== 0 ? -a / b : NaN) : a !== 0 ? -b / a : NaN);
      const ev = (id: string, l: number, e: { form: string; val: number }, other: { form: string; val: number }) =>
        fracStep(id, `Eigenvector for ${sn(l)}, as ${e.form}`, e.val, { hint: `Find the arrow A − ${l < 0 ? `(${sn(l)})` : sn(l)}I sends to 0. Its first row is ${vec([a - l, b])}.`,
          done: `Eigenvector for ${sn(l)}: ${e.form.replace("?", sn(e.val))}`,
          slips: [
            slip("solved A v = 0", zeroA(e.form), "Find the arrow A − λI sends to 0, not A itself."),
            other.form === e.form && slip("the other eigenvector", other.val, "That's the arrow for the other eigenvalue. Use this λ in A − λI."),
          ] });
      return [
        wholeStep("t", "trace", t, { hint: `The diagonal added: ${sn(a)} + ${d < 0 ? `(${sn(d)})` : sn(d)}.` }),
        wholeStep("det", "det", D, { hint: "a d − b c." , slips: [slip("a d + b c", a * d + b * c, "It is a d minus b c.")] }),
        multiStep("l", "Eigenvalues, larger first", [l1, l2], "whole", { boxes: ["λ₁", "λ₂"], hint: `Solve ${lin([[1, "λ²"], [-t, "λ"], [D, ""]])} = 0.`,
          slips: [
            slip("+ trace in the polynomial", [-l2, -l1], "It is λ² minus the trace times λ, plus det."),
            !triangular && slip("read eigenvalues off the diagonal", [Math.max(a, d), Math.min(a, d)], `That only works for triangular matrices. Here the diagonal is ${sn(a)} and ${sn(d)}, but the eigenvalues are ${sn(l1)} and ${sn(l2)}.`),
            slip("smaller first", [l2, l1], "Larger first, please."),
          ] }),
        ev("v1", l1, e1, e2),
        ev("v2", l2, e2, e1),
      ];
    },
    scene: p => { const A = A13(p); return { scene: S.eig, props: { mode: "find", a: A[0]![0]!, b: A[0]![1]!, c: A[1]![0]!, d: A[1]![1]!, quiet: true } }; },
  },
  // the roots of λ² − tλ + d, and a library's eigenvectors
  oracle: p => {
    const A = A13(p), t = A[0]![0]! + A[1]![1]!, d = det(A), r = Math.sqrt(t * t - 4 * d);
    const e = eigen(A), ratio = (v: number[], form: string) => (form === "(1, ?)" ? v[1]! / v[0]! : v[0]! / v[1]!);
    for (const [k, l] of [(t + r) / 2, (t - r) / 2].entries()) { const Av = mul(A, e.vectors[k]!.map(x => [x])).flat(); if (Av.some((x, i) => Math.abs(x - l * e.vectors[k]![i]!) > 1e-9)) throw new Error("not an eigenvector"); }
    return [t, Math.round(d), (t + r) / 2, (t - r) / 2, ratio(e.vectors[0]!, evAsk(col(p.P, 0)).form), ratio(e.vectors[1]!, evAsk(col(p.P, 1)).form)];
  },
  useIt: {
    say: [
      "For the filter [[3, 1], [0, 2]], find the two lines of the picture that only stretch: (1, 0) by 3, and (1, −1) by 2.",
      "Save the pair of eigenvalues as `lam`.",
    ],
    saves: { name: "lam", value: () => [3, 2], labels: ["λ₁", "λ₂"], note: "the eigenvalues of [[3, 1], [0, 2]]" },
    scene: { scene: S.eig, props: { mode: "find", a: 3, b: 1, c: 0, d: 2 } },
  },
  deeper: [
    "A turn has no real eigenvectors: no arrow stays on its line. Its eigenvalues are complex, a ± bi, which means a stretch by √(a² + b²) and a turn (track `qu`).",
    "Algebraic and geometric multiplicity: the shear [[1, 1], [0, 1]] has λ = 1 twice but only one line of eigenvectors. It is defective.",
    "Cayley–Hamilton: A satisfies its own polynomial, A² − (trace)A + (det)I = 0. Gershgorin's discs say roughly where the eigenvalues live from the rows alone.",
  ],
};

interface P14 { P: number; Q: number; N: number; at: number }
const t1 = (k: number) => dec(k / 10, 1);
const markov = (P: number, Q: number) => [[(10 - P) / 10, Q / 10], [P / 10, (10 - Q) / 10]];
function chainChoices(p: P14) {
  const m = (M: number[][]) => `[[${M[0]!.map(v => dec(v, 1)).join(", ")}], [${M[1]!.map(v => dec(v, 1)).join(", ")}]]`;
  const right = markov(p.P, p.Q);
  const cands = [
    { t: m(right), why: "" },
    { t: m(tr(right)), why: "Each column is where one state goes, so the columns add to 1." },
    { t: m(markov(p.Q, p.P)), why: "p is the chance of leaving state 1, so it sits below the first column's stay chance." },
    { t: m([[p.P / 10, p.Q / 10], [(10 - p.P) / 10, (10 - p.Q) / 10]]), why: "The diagonal holds the chances of staying: 1 − p and 1 − q." },
  ];
  const seen = new Set<string>(), list = cands.filter(c => !seen.has(c.t) && !!seen.add(c.t)).slice(0, 3);
  const k = p.at % list.length, choices = [...list.slice(k), ...list.slice(0, k)];
  return { choices, right: choices.findIndex(c => !c.why) };
}
/** a power iteration toward the steady chain, the oracle's way in */
const POWER_X0 = [1, 0];

export const la14: B2Lesson<P14> = {
  id: "b2-la-14", track: "la", unit: 4, title: "Powers and the long run",
  youCan: "predict where a repeated move ends up, including a chain of chances.",
  needs: ["b2-la-13"],
  tools: [S.eig, S.flow],
  play: { scene: S.eig, props: { mode: "iterate", a: 1.5, b: 0.5, c: 0.25, d: 1, x0: -1, y0: 1 },
    say: "Apply A again and again to an arrow. Drag the number of steps: the trail of A x, A² x, A³ x swings onto one line, the line of the biggest eigenvalue." },
  guess: { scene: S.eig, props: { mode: "iterate", a: 1.5, b: 0.5, c: 0.25, d: 1, x0: -1, y0: 1, quiet: true }, kind: "point", answer: [0.94, 0.34], near: 0.3, start: [-0.71, 0.71],
    ask: "The arrow starts at (−1, 1). Drag the marker round the ring to the direction you think A⁵⁰ x points.",
    revealProps: { run50: true },
    reveal: "After 50 steps the arrow points along (0.94, 0.34), the eigenvector for λ ≈ 1.68. The other eigenvalue, about 0.82, has died away." },
  nameIt: {
    say: [
      "In the eigenvector basis a move is a pure stretch, so powers are easy, and the eigenvalue with the largest size wins in the long run.",
      "For a chain of chances (columns adding to 1), λ = 1 is always there, and its eigenvector is where things settle. Statistics books, and b2-pr-19, write the same chain transposed: rows add to 1 and π = πP.",
    ],
    formula: ["Aⁿ = P Dⁿ P⁻¹", "for [[1 − p, q], [p, 1 − q]]: λ = 1 and λ = 1 − p − q", "steady share of state 1 = q / (p + q)"],
  },
  workIt: {
    reference: { P: 2, Q: 4, N: 1000, at: 0 },
    generate(rng, i) {
      for (;;) {
        const P = i < 3 ? rng.pick([2, 4, 5]) : rng.int(1, 9), Q = i < 3 ? rng.pick([2, 4, 5]) : rng.int(1, 9), N = rng.pick([100, 500, 1000]);
        // skip a share of N that ends in exactly .5: it has no nearest whole number
        if ((2 * N * Q) % (P + Q) === 0 && (N * Q) % (P + Q) !== 0) continue;
        return { P, Q, N, at: rng.int(0, 2) };
      }
    },
    show: p => `Each day state 1 (sunny) turns to state 2 (rainy) with chance **p = ${t1(p.P)}**, and state 2 turns back with chance **q = ${t1(p.Q)}**. Over **N = ${p.N.toLocaleString("en-US")}** days, how many are sunny?`,
    steps(p) {
      const { choices, right } = chainChoices(p), share = p.Q / (p.P + p.Q);
      return [
        tapStep("m", "The matrix (columns: where each state goes)", choices.map(c => c.t), right, { hint: "The first column is where state 1 goes: stay with 1 − p, leave with p.",
          slips: choices.map((c, i) => (c.why ? slip(`picked ${c.t}`, i, c.why) : null)) }),
        numStep("l2", "Second eigenvalue", (10 - p.P - p.Q) / 10, 1, { hint: "1 − p − q.",
          slips: [slip("p + q − 1", (p.P + p.Q - 10) / 10, `It is 1 − p − q. Check: the two eigenvalues add to the trace, ${t1(20 - p.P - p.Q)}.`)] }),
        fracStep("s", "Long-run share sunny", share, { hint: `q / (p + q) = ${t1(p.Q)} / ${t1(p.P + p.Q)}.`,
          slips: [slip("p/(p + q)", p.P / (p.P + p.Q), "The share of state 1 grows with q, the flow into it: q / (p + q).")] }),
        wholeStep("n", `Sunny days out of N = ${p.N.toLocaleString("en-US")}`, Math.round(p.N * share), { hint: `${p.N.toLocaleString("en-US")} × the share, to the nearest whole day.`,
          slips: [slip("p/(p + q)", Math.round((p.N * p.P) / (p.P + p.Q)), "That's the rainy days. The sunny share is q / (p + q).")] }),
      ];
    },
    scene: p => ({ scene: S.flow, props: { set: "weather", p: p.P, q: p.Q } }),
  },
  // power iteration 200 times, and a library's eigenvalues
  oracle: p => {
    const A = markov(p.P, p.Q);
    let x = POWER_X0.map(v => [v]);
    for (let k = 0; k < 200; k++) x = mul(A, x);
    const share = x[0]![0]! / (x[0]![0]! + x[1]![0]!);
    const { choices } = chainChoices(p);
    const want = `[[${A[0]!.map(v => dec(v, 1)).join(", ")}], [${A[1]!.map(v => dec(v, 1)).join(", ")}]]`;
    return [choices.findIndex(c => c.t === want), Math.min(...eigen(A).values), share, Math.round(p.N * share)];
  },
  useIt: {
    say: [
      "Project: two bike stations. A keeps 70% and sends 30% to B; B keeps 80% and sends 20% to A. In the long run 40% of the bikes sit at A, so 200 of 500.",
      "Set your own chances, watch the dots flow and settle, and save the steady shares as `steady` (b2-pr-19, Markov chains).",
    ],
    project: "la-forecast",
  },
  deeper: [
    "Power iteration finds the biggest eigenvector by repeating A, and it closes in at the rate |λ₂/λ₁| per step.",
    "Perron–Frobenius: a matrix of positive chances has one steady state, and every start heads to it. PageRank is the steady state of a random surfer on the web.",
    "The matrix exponential e^(At) solves x′ = A x (track `de`). Fibonacci comes from powers of [[1, 1], [1, 0]], whose big eigenvalue is the golden ratio (1 + √5)/2.",
  ],
};

interface P15 { a: number; b: number; d: number }
const SHAPES = ["bowl", "upside-down bowl", "saddle", "trough", "upside-down trough"];
const shapeIdx = (l1: number, l2: number) => (l1 > 0 && l2 > 0 ? 0 : l1 < 0 && l2 < 0 ? 1 : l1 > 0 && l2 < 0 ? 2 : l2 === 0 && l1 > 0 ? 3 : 4);
const PAIRS15: [number, number][] = [[0, 2], [0, 4], [3, 4], [6, 8], [8, 6], [5, 12]];
const eig15 = (p: P15) => { const r = Math.sqrt((p.a - p.d) ** 2 + 4 * p.b * p.b); return [(p.a + p.d + r) / 2, (p.a + p.d - r) / 2] as [number, number]; };

export const la15: B2Lesson<P15> = {
  id: "b2-la-15", track: "la", unit: 4, title: "Symmetric matrices: perpendicular axes",
  youCan: "find the perpendicular main axes of a symmetric matrix and tell a bowl from a saddle.",
  needs: ["b2-la-13"],
  tools: [S.play, "graph3d"],
  play: { scene: S.play, props: { mode: "circle", sym: true, surface: true, sa: 2, sb: 1, sd: 2 },
    say: "A symmetric matrix turns the unit circle into an ellipse. Drag the off-diagonal entry b: the ellipse turns, and its two axes always stay perpendicular. Switch to the surface z = xᵀAx to see a bowl, a trough or a saddle." },
  guess: { scene: S.play, props: { mode: "circle", sym: true, sa: 5, sb: 2, sd: 2, quiet: true }, kind: "point", answer: [0.89, 0.45], near: 0.3, start: [0, 1],
    ask: "A = [[5, 2], [2, 2]]. Drag the marker to where you think the long axis of its ellipse points.",
    revealProps: {},
    reveal: "The long axis points along (2, 1), stretched by λ = 6; the short one along (1, −2), by 1. The two axes meet at 90°." },
  nameIt: {
    say: [
      "A symmetric matrix (A = Aᵀ) has real eigenvalues and perpendicular eigenvectors: it is a turn, a stretch along the axes, and the turn back.",
      "The signs of the eigenvalues tell the shape of xᵀAx.",
    ],
    formula: ["A = Q Λ Qᵀ", "both λ > 0: bowl; both λ < 0: upside-down bowl; signs differ: saddle", "one λ = 0 and the other λ > 0: trough; one λ = 0 and the other λ < 0: upside-down trough"],
  },
  workIt: {
    reference: { a: 5, b: 2, d: 2 },
    generate(rng, i) {
      for (;;) {
        const [dd, bb] = rng.pick(i < 3 ? PAIRS15.slice(0, 2) : PAIRS15);
        const s1 = rng.pick([1, -1]), s2 = rng.pick([1, -1]);
        const d = rng.int(-6, 9), a = d + s1 * dd;
        if (a < -6 || a > 9 || (i < 3 && Math.abs(a) > 6)) continue;
        return { a, b: (s2 * bb) / 2, d };
      }
    },
    show: p => `A = **${mat([[p.a, p.b], [p.b, p.d]])}**. Find its main axes and the shape of xᵀAx.`,
    steps(p) {
      const [l1, l2] = eig15(p), v1 = (l1 - p.a) / p.b, v2 = (l2 - p.a) / p.b, right = shapeIdx(l1, l2);
      const why = (i: number) => {
        if (i === 0 && p.a > 0 && p.b > 0 && p.d > 0 && right === 2) return slip("bowl because every entry is positive", 0, `Entries don't decide it, eigenvalues do: ${sn(l1)} and ${sn(l2)} have opposite signs, so it's a saddle.`);
        if (i === 0 && right === 1) return slip("bowl when both λ < 0", 0, "Both eigenvalues are negative, so every direction curves down: an upside-down bowl.");
        const said = ["Both eigenvalues would have to be positive.", "Both eigenvalues would have to be negative.", "A saddle needs one positive and one negative eigenvalue.", "A trough needs one eigenvalue 0 and the other positive.", "An upside-down trough needs one eigenvalue 0 and the other negative."][i]!;
        return slip(`picked ${SHAPES[i]}`, i, `${said} Here they are ${sn(l1)} and ${sn(l2)}.`);
      };
      return [
        multiStep("l", "Eigenvalues, larger first", [l1, l2], "whole", { boxes: ["λ₁", "λ₂"], hint: `Solve ${lin([[1, "λ²"], [-(p.a + p.d), "λ"], [p.a * p.d - p.b * p.b, ""]])} = 0.`,
          slips: [slip("eigenvalues from the diagonal", [Math.max(p.a, p.d), Math.min(p.a, p.d)], `Off-diagonal entries move them: here ${sn(p.a)} and ${sn(p.d)} become ${sn(l1)} and ${sn(l2)}.`)] }),
        fracStep("v1", `Eigenvector for ${sn(l1)}, as (1, ?)`, v1, { hint: `The first row of A − ${l1 < 0 ? `(${sn(l1)})` : sn(l1)}I is ${vec([p.a - l1, p.b])}: make it 0.`, done: `Eigenvector for ${sn(l1)}: (1, ${sn(v1)})`,
          slips: [slip("the other eigenvector", v2, "That's the arrow for the other eigenvalue. Use λ₁ in A − λI.")] }),
        fracStep("v2", `Eigenvector for ${sn(l2)}, as (1, ?)`, v2, { hint: `The first row of A − ${l2 < 0 ? `(${sn(l2)})` : sn(l2)}I is ${vec([p.a - l2, p.b])}: make it 0.`, done: `Eigenvector for ${sn(l2)}: (1, ${sn(v2)})`,
          slips: [slip("the other eigenvector", v1, "That's the arrow for λ₁. Use λ₂ in A − λI.")] }),
        wholeStep("dot", "Their dot product", 1 + v1 * v2, { hint: `1·1 + (${sn(v1)})·(${sn(v2)}).` }),
        tapStep("shape", "Shape of xᵀAx", SHAPES, right, { hint: "Look at the signs of the two eigenvalues.", slips: SHAPES.map((_, i) => (i === right ? null : why(i))) }),
      ];
    },
    scene: p => ({ scene: S.play, props: { mode: "circle", sym: true, surface: true, sa: p.a, sb: p.b, sd: p.d, quiet: true } }),
  },
  // (t ± √(t² − 4d)) / 2, and a library's eigenvectors
  oracle: p => {
    const A = [[p.a, p.b], [p.b, p.d]], t = p.a + p.d, D = det(A), r = Math.sqrt(t * t - 4 * D);
    const e = eigen(A), w1 = e.vectors[0]!, w2 = e.vectors[1]!;
    const l1 = (t + r) / 2, l2 = (t - r) / 2;
    return [l1, l2, w1[1]! / w1[0]!, w2[1]! / w2[0]!, Math.round(1e9 * (1 + (w1[1]! / w1[0]!) * (w2[1]! / w2[0]!))) / 1e9, shapeIdx(Math.round(l1), Math.round(l2))];
  },
  useIt: {
    say: [
      "Treat [[5, 2], [2, 2]] as the spread of a cloud of heights and weights (a covariance matrix). Its main axis points along (2, 1), slope 1/2, and holds 6 of the 7 units of spread (b2-pr-08).",
      "This is the move the build makes with pictures: find the main directions and keep the big ones.",
    ],
    scene: { scene: S.play, props: { mode: "circle", sym: true, surface: true, sa: 5, sb: 2, sd: 2 } },
  },
  deeper: [
    "Proof by the Rayleigh quotient xᵀAx / xᵀx: its largest value over all x is λ₁, reached at the top eigenvector. Courant–Fischer finds every λ this way, by a min-max.",
    "The second-derivative test is this lesson applied to the Hessian matrix of second derivatives (b2-mv-13).",
    "Hermitian matrices, the complex symmetric ones, are the measurable quantities of quantum mechanics (track `qu`).",
  ],
};

export const UNIT34 = [la09, la10, la11, la12, la13, la14, la15];
