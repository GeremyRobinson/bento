// Linear algebra, unit 5 (b2-la-16 to b2-la-20): orthonormal bases, the SVD, layers, PCA and the build.
import type { B2Lesson, SceneRef } from "../../model";
import { fracStep, multiStep, numStep, slip, tapStep, wholeStep } from "../../make";
import { eigen, mul, transpose } from "../../tools/matrix";
import { cross, dec, dot, gcd, mat, norm, sn, subv, scalev, svd, IMG0, energyKept, vec, type Vec } from "./maths";
import { nz, S } from "./unit12";

/* ------------------------------------------------------------------ 16 · Gram–Schmidt ------------------------------------------------------------------ */

interface P16 { u: Vec; k: number; w: Vec }
const U16: Vec[] = [[3, 4], [1, 2, 2], [2, 3, 6], [1, 4, 8], [2, 6, 9]];
const v16 = (p: P16) => p.u.map((x, i) => p.k * x + p.w[i]!);
const termsText = (a: Vec, b: Vec) => a.map((x, i) => `${x < 0 ? `(${sn(x)})` : sn(x)}·${b[i]! < 0 ? `(${sn(b[i]!)})` : sn(b[i]!)}`).join(" + ");

export const la16: B2Lesson<P16> = {
  id: "b2-la-16", track: "la", unit: 5, title: "Orthonormal bases and Gram–Schmidt",
  youCan: "turn any basis into one of perpendicular unit arrows, and spot a matrix that only turns.",
  needs: ["b2-la-03", "b2-la-04", "b2-la-08"],
  tools: [S.vec, S.space],
  play: { scene: S.vec, props: { mode: "gram", ux: 3, uy: 1, vx: 2, vy: 3 },
    say: "Two slanted arrows and the skewed grid they make. Press Remove the shadow: v loses its shadow on u and stands up perpendicular. Press Length 1: both shrink to length 1, and the grid turns square, just turned. Drag the arrows first to try others." },
  guess: { scene: S.vec, props: { mode: "gram", ux: 3, uy: 1, vx: 2, vy: 3, quiet: true }, kind: "point", answer: [-0.7, 2.1], near: 0.6, start: [3, -3],
    ask: "u = (3, 1) and v = (2, 3). Drag the marker to where you think v ends once its shadow on u is taken away.",
    revealProps: { phase: 1 },
    reveal: "The shadow of v on u is 9/10 of u, which is (2.7, 0.9). Taking it away leaves v′ = (−0.7, 2.1), perpendicular to u: (3, 1)·(−0.7, 2.1) = 0." },
  nameIt: {
    say: [
      "Orthonormal means perpendicular and length 1. A matrix Q with orthonormal columns keeps every length and angle, so it only turns or mirrors, and undoing it is just its transpose (flip it across its diagonal).",
      "Gram–Schmidt makes such a basis by removing shadows one at a time.",
    ],
    formula: ["v′ = v − (u·v / u·u) u", "QᵀQ = I, so Q⁻¹ = Qᵀ"],
  },
  workIt: {
    reference: { u: [1, 2, 2], k: 1, w: [2, -2, 1] },
    generate(rng, i) {
      for (;;) {
        const base = i < 3 ? U16[0]! : rng.pick(U16);
        const u = base.map(x => x * (rng.pick([1, -1]))) as Vec;
        const k = rng.int(-3, 3);
        let w: Vec;
        if (u.length === 2) { const m = nz(rng, -2, 2); w = [-m * u[1]!, m * u[0]!]; }
        else {
          const c = cross(u, [rng.int(-2, 2), rng.int(-2, 2), rng.int(-2, 2)]);
          const g = gcd(gcd(c[0]!, c[1]!), c[2]!);
          if (!g) continue;
          w = c.map(x => x / g);
          if (rng.int(0, 1)) w = w.map(x => -x);
        }
        const p = { u, k, w };
        const lim = i < 3 ? 12 : 20;
        if (w.some(x => Math.abs(x) > 12) || v16(p).some(x => Math.abs(x) > lim) || v16(p).every(x => x === 0)) continue;
        return p;
      }
    },
    show: p => `u = **${vec(p.u)}** and v = **${vec(v16(p))}**. Make v perpendicular to u, then make the basis orthonormal.`,
    steps(p) {
      const v = v16(p), uv = dot(p.u, v), uu = dot(p.u, p.u), vv = dot(v, v), k = uv / uu, vp = subv(v, scalev(k, p.u)), L = norm(p.u);
      const nvp = norm(vp);
      return [
        wholeStep("uv", "u·v", uv, { hint: `Multiply entry by entry and add: ${termsText(p.u, v)}.` }),
        wholeStep("uu", "u·u", uu, { hint: `${termsText(p.u, p.u)}.`, slips: [slip("v·v", vv, "That's v·v. The shadow is on u, so use u·u.")] }),
        fracStep("k", "Multiplier, u·v / u·u", k, { hint: `${sn(uv)} / ${sn(uu)}.`,
          slips: [slip("removed u's shadow on v", vv ? uv / vv : NaN, "Remove the part of v along u, so divide by u·u.")] }),
        multiStep("vp", "v′ = v − (multiplier) u", vp, "whole", { boxes: p.u.length === 2 ? ["x", "y"] : ["x", "y", "z"], hint: `v − ${k === 1 ? "u" : k === -1 ? "(−u)" : `${k < 0 ? `(${sn(k)})` : sn(k)}u`}, entry by entry. Check: v′·u should be 0.`,
          slips: [
            slip("typed the shadow, not what's left", scalev(k, p.u), "v′ is v minus its shadow. Check: v′·u should be 0."),
            slip("scaled before subtracting", nvp ? scalev(1 / nvp, vp) : [NaN], "Subtract first, then scale to length 1."),
          ] }),
        wholeStep("len", "|u|", L, { hint: `√(u·u) = √${sn(uu)}.`, done: `|u| = ${sn(L)}, so the first unit arrow is ${vec(p.u)}/${sn(L)}`,
          slips: [slip("u·u, not its root", uu, "|u| is the square root of u·u.")] }),
        tapStep("keep", "Q has columns u/|u| and v′/|v′|. Does Q keep lengths?", ["Yes", "No"], 0, { hint: "Its columns are perpendicular and length 1.",
          slips: [null, slip("said no", 1, "Its columns are perpendicular and length 1, so QᵀQ = I: every length stays.")] }),
      ];
    },
    scene: (p): SceneRef => {
      const v = v16(p);
      return p.u.length === 2
        ? { scene: S.vec, props: { mode: "gram", ux: p.u[0]!, uy: p.u[1]!, vx: v[0]!, vy: v[1]!, quiet: true } }
        : { scene: S.space, props: { mode: "box", two: true, ux: p.u[0]! / 3, uy: p.u[1]! / 3, uz: p.u[2]! / 3, vx: v[0]! / 3, vy: v[1]! / 3, vz: v[2]! / 3, quiet: true } };
    },
  },
  // v − k u with k = u·v / u·u, from a library's matrix product; and a check that v′·u = 0
  oracle: p => {
    const v = v16(p), uv = mul([p.u], v.map(x => [x]))[0]![0]!, uu = mul([p.u], p.u.map(x => [x]))[0]![0]!;
    const k = uv / uu, vp = v.map((x, i) => x - k * p.u[i]!);
    if (Math.abs(dot(vp, p.u)) > 1e-9) throw new Error("v′ is not perpendicular to u");
    return [uv, uu, k, ...vp, Math.sqrt(uu), 0];
  },
  useIt: {
    say: [
      "A 3D game camera stores its turn as the matrix with columns (1, 2, 2)/3, (2, −2, 1)/3 and (2, 1, −2)/3. Each column has length 1 and each pair has dot product 0, so QᵀQ = I.",
      "It is a pure turn (det 1): the cube keeps its size and its right angles. The build's layers use exactly such arrows.",
    ],
    scene: { scene: S.space, props: { mode: "cube", m00: 1 / 3, m01: 2 / 3, m02: 2 / 3, m10: 2 / 3, m11: -2 / 3, m12: 1 / 3, m20: 2 / 3, m21: 1 / 3, m22: -2 / 3 } },
  },
  deeper: [
    "QR factorization: Gram–Schmidt on the columns of A writes A = QR, with R upper triangular. It solves least squares more stably than AᵀA.",
    "Modified Gram–Schmidt and Householder mirrors do the same job with less rounding error. Gram–Schmidt on functions gives the Legendre polynomials.",
    "Unitary matrices, the complex version of Q, are the gates of a quantum computer (track `qu`).",
  ],
};

/* ------------------------------------------------------------------ 17 · the SVD ------------------------------------------------------------------ */

interface P17 { A: number[][] }
const isq = (x: number) => { const r = Math.round(Math.sqrt(x)); return r * r === x ? r : -1; };
function ata17(A: number[][]) {
  const [a, b] = A[0]!, [c, d] = A[1]!;
  const p = a! * a! + c! * c!, q = a! * b! + c! * d!, r = b! * b! + d! * d!;
  const s = isq((p - r) ** 2 + 4 * q * q);
  return { M: [[p, q], [q, r]], l: s < 0 ? null : [(p + r + s) / 2, (p + r - s) / 2] as [number, number] };
}
/** the real eigenvalues of A itself, largest size first (for the slip) */
function eigA(A: number[][]): number[] | null {
  const t = A[0]![0]! + A[1]![1]!, D = A[0]![0]! * A[1]![1]! - A[0]![1]! * A[1]![0]!, disc = t * t - 4 * D;
  if (disc < 0) return null;
  const r = Math.sqrt(disc);
  return [(t + r) / 2, (t - r) / 2].sort((x, y) => Math.abs(y) - Math.abs(x));
}
const sigStep = (id: string, label: string, s: number, c: Parameters<typeof wholeStep>[3]) =>
  (Math.abs(s - Math.round(s)) < 1e-12 ? wholeStep(id, label, Math.round(s), c) : numStep(id, label, s, 2, c));

export const la17: B2Lesson<P17> = {
  id: "b2-la-17", track: "la", unit: 5, title: "The SVD: turn, stretch, turn",
  youCan: "split any matrix into a turn, a stretch and a turn, and find its singular values.",
  needs: ["b2-la-15", "b2-la-16"],
  tools: [S.play, S.eig],
  play: { scene: S.eig, props: { mode: "stretch", a: 3, b: 0, c: 4, d: 5, th: 0.35 },
    say: "The matrix turns the unit circle into an ellipse. Drag the test arrow x round the circle and watch Ax: the inputs that land on the longest and shortest axes are perpendicular, and so are the axes they land on." },
  guess: { scene: S.eig, props: { mode: "stretch", a: 3, b: 0, c: 4, d: 5, quiet: true }, kind: "point", answer: [0.71, 0.71], near: 0.3, start: [0, 1],
    ask: "A = [[3, 0], [4, 5]]. Drag the marker round the top half of the circle to the input arrow you think A stretches most.",
    revealProps: { most: true },
    reveal: "The most-stretched input is (1, 1)/√2: it grows by σ₁ = √45 ≈ 6.71. The least-stretched, (1, −1)/√2, is perpendicular to it, and so are the two axes they land on." },
  nameIt: {
    say: [
      "Every matrix is a turn (or mirror), then a stretch along the axes, then another turn (or mirror).",
      "The stretches are the singular values, never negative, largest first. They are the square roots of the eigenvalues of AᵀA.",
    ],
    formula: ["A = U Σ Vᵀ", "σᵢ = √(eigenvalues of AᵀA)", "for a 2 × 2: σ₁σ₂ = |det A|"],
  },
  workIt: {
    reference: { A: [[3, 0], [4, 5]] },
    generate(rng, i) {
      for (;;) {
        let A: number[][];
        if (i < 3) {
          const a = rng.int(-4, 4), d = rng.int(-4, 4), b = rng.pick([0, 0, rng.int(-3, 3)]);
          A = [[a, b], [b, d]];
        } else A = [[rng.int(-4, 4), rng.int(-4, 4)], [rng.int(-4, 4), rng.int(-4, 4)]];
        if (A.flat().every(x => x === 0)) continue;
        const { l } = ata17(A);
        if (!l || l[1] < 0) continue;
        // at least one off-diagonal entry once past the warm-up, and no repeated stretch
        if (i >= 3 && A[0]![1] === 0 && A[1]![0] === 0) continue;
        if (l[0] === l[1]) continue;
        return { A };
      }
    },
    show: p => `A = **${mat(p.A)}**. Find its singular values.`,
    steps(p) {
      const A = p.A, { M, l } = ata17(A), [l1, l2] = l!, s1 = Math.sqrt(l1), s2 = Math.sqrt(l2);
      const D = A[0]![0]! * A[1]![1]! - A[0]![1]! * A[1]![0]!;
      const AAt = [[A[0]![0]! ** 2 + A[0]![1]! ** 2, A[0]![0]! * A[1]![0]! + A[0]![1]! * A[1]![1]!], [0, A[1]![0]! ** 2 + A[1]![1]! ** 2]];
      AAt[1]![0] = AAt[0]![1]!;
      const eA = eigA(A);
      const fromA = (j: number) => eA && Math.abs(eA[j]!) !== [s1, s2][j] ? slip("eigenvalues of A", eA[j]!, `Singular values come from AᵀA and are never negative: here ${dec(s1, 2).replace(/\.00$/, "")} and ${dec(s2, 2).replace(/\.00$/, "")}.`) : null;
      return [
        multiStep("ata", "AᵀA", M.flat(), "whole", { boxes: ["top left", "top right", "bottom left", "bottom right"], hint: "Each entry is a dot product of two columns of A: column i with column j.",
          slips: [slip("AAᵀ", AAt.flat(), "That's AAᵀ, rows with rows. AᵀA pairs the columns of A.")] }),
        multiStep("l", "Eigenvalues of AᵀA, larger first", [l1, l2], "whole", { boxes: ["larger", "smaller"], hint: `Solve λ² − ${sn(M[0]![0]! + M[1]![1]!)}λ + ${sn(M[0]![0]! * M[1]![1]! - M[0]![1]! ** 2)} = 0.`.replace("+ 0 = 0", "= 0"),
          slips: [slip("smaller first", [l2, l1], "Larger first: σ₁ is the biggest stretch.")] }),
        sigStep("s1", "σ₁", s1, { hint: `√${sn(l1)}.`, slips: [fromA(0), slip("forgot the square root", l1, `${sn(l1)} is σ₁². Take the square root.`), slip("smaller first", s2, "σ₁ is the biggest stretch.")] }),
        sigStep("s2", "σ₂", s2, { hint: `√${sn(l2)}.`, slips: [fromA(1), slip("forgot the square root", l2, `${sn(l2)} is σ₂². Take the square root.`), slip("the bigger one again", s1, "σ₂ is the smaller stretch.")] }),
        wholeStep("prod", "σ₁σ₂", Math.abs(D), { hint: `√(${sn(l1)} × ${sn(l2)}). It should match |det A|.`, done: `σ₁σ₂ = ${sn(Math.abs(D))} = |det A|`,
          slips: [D < 0 ? slip("kept the sign of det", D, "Stretches are never negative: σ₁σ₂ = |det A|.") : null] }),
      ];
    },
    scene: (p): SceneRef => ({ scene: S.eig, props: { mode: "stretch", a: p.A[0]![0]!, b: p.A[0]![1]!, c: p.A[1]![0]!, d: p.A[1]![1]!, quiet: true } }),
  },
  // √(eigenvalues of AᵀA) from a library, sorted down
  oracle: p => {
    const M = mul(transpose(p.A), p.A), e = eigen(M).values.map(Number).sort((a, b) => b - a);
    const s = e.map(x => Math.sqrt(Math.max(0, x)));
    return [...M.flat(), e[0]!, e[1]!, s[0]!, s[1]!, s[0]! * s[1]!];
  },
  useIt: {
    say: [
      "A map projection stretches a tiny circle on the globe into an ellipse. σ₁/σ₂ says how badly it distorts shapes there: 1 means shapes are kept.",
      "Here the matrix is your filter `M` from the Filter and undo project, if you made one. Keep its singular values as `sigmaM`.",
    ],
    scene: { scene: S.eig, props: { mode: "stretch", useShelf: true, save: true, a: 3, b: 0, c: 4, d: 5 } },
  },
  deeper: [
    "Proof: AᵀA is symmetric with no negative eigenvalues, so the spectral theorem gives its perpendicular eigenvectors V. Then each A vᵢ has length σᵢ, and the A vᵢ are perpendicular too.",
    "The pseudoinverse A⁺ = V Σ⁺ Uᵀ solves least squares in one line (back to b2-la-11). σ₁ is the largest stretch, the operator norm. Polar decomposition splits A into a turn times a stretch.",
    "The Schmidt decomposition of a two-part quantum state is an SVD, and its count of nonzero σ's measures entanglement (track `qu`).",
  ],
};

/* ------------------------------------------------------------------ 18 · layers ------------------------------------------------------------------ */

interface P18 { sig: number[]; k: number; target: number }
const sq = (xs: number[]) => xs.reduce((s, x) => s + x * x, 0);
const sum = (xs: number[]) => xs.reduce((s, x) => s + x, 0);
const squaresText = (xs: number[]) => xs.map(x => `${sn(x)}²`).join(" + ");
const smallestK = (sig: number[], target: number, f = (x: number) => x * x) => {
  const all = sum(sig.map(f));
  for (let k = 1; k <= sig.length; k++) if (100 * sum(sig.slice(0, k).map(f)) >= target * all - 1e-9) return k;
  return sig.length;
};
const IMG_KEPT = Math.round(energyKept(svd(IMG0).s, 1) * 1000) / 10;

export const la18: B2Lesson<P18> = {
  id: "b2-la-18", track: "la", unit: 5, title: "Layers: a picture as a sum of simple pictures",
  youCan: "say how much of a picture k layers keep, and how big the leftover error is.",
  needs: ["b2-la-06", "b2-la-17"],
  tools: [S.comp, "matrix"],
  play: { scene: S.comp, props: { mode: "layers", k: 1 },
    say: "Your picture `img` (or a sunrise, if you haven't drawn one) rebuilt as layer 1, plus layer 2, plus layer 3, and so on. Each layer on its own is a faint plaid. Slide k up: the rebuilt picture sharpens and what's left fades." },
  guess: { scene: S.comp, props: { mode: "layers", fixed: true, k: 1, quiet: true }, kind: "slider", min: 0, max: 100, step: 1, start: 40, answer: IMG_KEPT, near: 6, format: x => `${x}%`,
    ask: "This sunrise is kept with only its first layer. Drag the slider to the percent of the picture's energy you think that one layer keeps.",
    revealProps: {},
    reveal: `One layer keeps ${dec(IMG_KEPT, 1)}% of the energy: σ₁² over the sum of every σ². The eye needs more than that for the sun's edge, but the first layer already holds the sky and hills.` },
  nameIt: {
    say: [
      "The SVD writes a picture as a sum of layers, each a column times a row times its σ. Keeping the first k layers gives the best possible k-layer picture.",
      "Energy adds up as squares.",
    ],
    formula: ["A = σ₁u₁v₁ᵀ + σ₂u₂v₂ᵀ + …", "energy kept = (σ₁² + … + σₖ²) / (σ₁² + σ₂² + …)", "error = √(sum of the dropped σ²)"],
  },
  workIt: {
    reference: { sig: [6, 3, 2, 1], k: 1, target: 90 },
    generate(rng, i) {
      const n = i < 3 ? 3 : rng.int(3, 5);
      const pool = Array.from({ length: 12 }, (_, j) => j + 1);
      const sig = rng.shuffle(pool).slice(0, n);
      sig.sort((a, b) => b - a);
      return { sig, k: rng.int(1, Math.min(3, n - 2)), target: rng.pick([80, 90, 95, 99]) };
    },
    show: p => `A picture's singular values are σ = **${p.sig.join(", ")}**. Keep its first layers.`,
    steps(p) {
      const { sig, k } = p, all = sq(sig), kept = (100 * sq(sig.slice(0, k))) / all, drop = sig.slice(k + 1), err = Math.sqrt(sq(drop));
      const kk = smallestK(sig, p.target);
      const fromBottom = (() => { const r = [...sig].reverse(); return smallestK(r, p.target); })();
      return [
        wholeStep("all", "Total energy", all, { hint: `${squaresText(sig)}.`, slips: [slip("added the σ's, not their squares", sum(sig), "Energy adds as squares: square each σ, then add.")] }),
        numStep("kept", `Kept with k = ${k}, as a percent`, kept, 1, { unit: "%", done: `Kept with k = ${k}: ${dec(kept, 1)}%`, hint: `(${squaresText(sig.slice(0, k))}) / ${sn(all)}, times 100.`,
          slips: [
            slip("used σ instead of σ²", (100 * sum(sig.slice(0, k))) / sum(sig), `Energy adds as squares: ${sn(sq(sig.slice(0, k)))} out of ${sn(all)}, not ${sn(sum(sig.slice(0, k)))} out of ${sn(sum(sig))}.`),
            slip("counted from the smallest layer", (100 * sq(sig.slice(-k))) / all, "Layers go biggest σ first; keep from the top."),
          ] }),
        numStep("err", `Error with k = ${k + 1}`, err, 2, { hint: `√(${squaresText(drop)}).`,
          slips: [
            slip("plain sum of the dropped σ", sum(drop), `The error is the square root of the dropped squares: √(${drop.map(x => sn(x * x)).join(" + ")}).`),
            slip("forgot the square root", sq(drop), "That's the dropped energy. The error is its square root."),
          ] }),
        wholeStep("k", `Smallest k that keeps ${p.target}%`, kk, { hint: `Add squares from the top until you reach ${p.target}% of ${sn(all)}.`, done: `k = ${kk}: ${sn(sq(sig.slice(0, kk)))} of ${sn(all)}`,
          slips: [
            slip("counted from the smallest layer", fromBottom, "Layers go biggest σ first; keep from the top."),
            slip("used σ instead of σ²", smallestK(sig, p.target, x => x), "Energy adds as squares, so count σ² against the total."),
          ] }),
      ];
    },
    scene: (): SceneRef => ({ scene: S.comp, props: { mode: "layers", k: 1 } }),
  },
  // a matrix built with these σ between two orthonormal bases (Householder mirrors), then the squared entries of its layers
  oracle: p => {
    const n = p.sig.length;
    const mirror = (w: number[]) => { const ww = dot(w, w); return w.map(a => w.map(b => -2 * a * b / ww)).map((r, i) => r.map((x, j) => x + (i === j ? 1 : 0))); };
    const U = mirror(Array.from({ length: n }, (_, i) => i + 1)), V = mirror(Array.from({ length: n }, (_, i) => n - i + 0.5));
    const part = (from: number, to: number) => {
      const M = U.map(() => V.map(() => 0));
      for (let t = from; t < to; t++) for (let i = 0; i < n; i++) for (let j = 0; j < n; j++) M[i]![j]! += p.sig[t]! * U[i]![t]! * V[j]![t]!;
      return M.flat().reduce((s, x) => s + x * x, 0);
    };
    const all = part(0, n);
    let kk = 1;
    while (kk < n && 100 * part(0, kk) < p.target * all - 1e-6) kk++;
    return [all, (100 * part(0, p.k)) / all, Math.sqrt(part(p.k + 1, n)), kk];
  },
  useIt: {
    say: [
      "**Project: Plaid from layers.** Build a 6 × 6 plaid from two or three column-times-row layers, check its rank, and count what it costs to store.",
      "Two layers cost 2·(6 + 6 + 1) = 26 numbers against 36 for the whole picture.",
    ],
    project: "la-plaid",
  },
  deeper: [
    "The Eckart–Young–Mirsky theorem: the first k layers are the best rank-k picture. The largest-stretch error is σₖ₊₁, and the total error is √(σₖ₊₁² + …).",
    "The Frobenius norm √(sum of squared entries) equals √(trace AᵀA) = √(Σσ²), which is why energy adds up as squares. Randomized SVD finds the top layers of huge matrices quickly.",
    "Low-rank updates (LoRA) are how large AI models are tuned cheaply: the change is stored as a few layers (track `ai`).",
  ],
};

/* ------------------------------------------------------------------ 19 · PCA ------------------------------------------------------------------ */

interface P19 { pts: number[][] }
function pca(pts: number[][]) {
  const n = pts.length, mx = sum(pts.map(q => q[0]!)) / n, my = sum(pts.map(q => q[1]!)) / n;
  const X = pts.map(q => [q[0]! - mx, q[1]! - my]);
  const a = sq(X.map(q => q[0]!)), b = sum(X.map(q => q[0]! * q[1]!)), d = sq(X.map(q => q[1]!));
  const s = Math.sqrt((a - d) ** 2 + 4 * b * b);
  return { mx, my, M: [[a, b], [b, d]], l: [(a + d + s) / 2, (a + d - s) / 2] as [number, number] };
}
/** the first direction's slope; null when it is straight up */
const slope19 = (M: number[][], l1: number) => (M[0]![1] ? (l1 - M[0]![0]!) / M[0]![1]! : M[0]![0]! > M[1]![1]! ? 0 : null);
const CLOUD_DEG = 33;

export const la19: B2Lesson<P19> = {
  id: "b2-la-19", track: "la", unit: 5, title: "PCA: the main directions of data",
  youCan: "find the direction a cloud of data spreads most, and how much of the spread it holds.",
  needs: ["b2-la-15", "b2-la-18"],
  tools: [S.cloud, S.eig],
  play: { scene: S.cloud, props: { deg: 100 },
    say: "A cloud of points, with a line through its center. Turn the line: each point drops a shadow onto it, and the bar shows how spread out the shadows are. Find the direction that makes the bar longest. Drag a point to change the cloud." },
  guess: { scene: S.cloud, props: { quiet: true }, kind: "slider", min: 0, max: 179, step: 1, start: 120, answer: CLOUD_DEG, near: 8, format: x => `${x}°`,
    ask: "Turn the line to where you think the cloud spreads most.",
    revealProps: { sweep: true },
    reveal: "The sweep runs the line all the way round. The shadows spread most at about 33°: that line holds 96% of the cloud's spread." },
  nameIt: {
    say: [
      "Center the data, then put it in the rows of a matrix X. The top eigenvector of XᵀX is the direction of most spread: the first principal component.",
      "Its eigenvalue is the total squared spread along it (n times the variance there). These are the right singular vectors of X, with eigenvalue σ².",
    ],
    formula: ["center: subtract the mean", "XᵀX = [[Σx², Σxy], [Σxy, Σy²]]", "share on PC1 = λ₁ / (λ₁ + λ₂)"],
  },
  workIt: {
    reference: { pts: [[7, 4], [3, 2], [6, 5], [4, 1]] },
    generate(rng, i) {
      for (;;) {
        const [a, b, c, d] = [rng.int(-3, 3), rng.int(-3, 3), rng.int(-3, 3), rng.int(-3, 3)];
        const cx = i < 3 ? 0 : rng.int(0, 6), cy = i < 3 ? 0 : rng.int(0, 6);
        const pts = [[cx + a, cy + b], [cx - a, cy - b], [cx + c, cy + d], [cx - c, cy - d]];
        const { M, l } = pca(pts);
        if (!(l[0] > l[1]) || l.some(x => Math.abs(x - Math.round(x)) > 1e-9)) continue;
        // a straight-up first direction has no slope to type
        if (slope19(M, l[0]) === null) continue;
        return { pts };
      }
    },
    show: p => `Four points: **${p.pts.map(q => vec(q)).join(", ")}**. Find the direction they spread most.`,
    steps(p) {
      const { mx, my, M, l } = pca(p.pts), [l1, l2] = l, m = slope19(M, l1)!;
      const raw = [[sq(p.pts.map(q => q[0]!)), sum(p.pts.map(q => q[0]! * q[1]!))], [0, sq(p.pts.map(q => q[1]!))]];
      raw[1]![0] = raw[0]![1]!;
      const hi = Math.max(M[0]![0]!, M[1]![1]!), lo = Math.min(M[0]![0]!, M[1]![1]!);
      const diagMsg = `The diagonal is spread along x and y. Along the best line it is the larger eigenvalue, ${sn(l1)}.`;
      return [
        multiStep("mean", "Mean point", [mx, my], "fraction", { boxes: ["x̄", "ȳ"], hint: "Add the x's and divide by 4; the same for the y's.",
          slips: [slip("added without dividing", [4 * mx, 4 * my], "Divide the sums by 4, the number of points.")] }),
        multiStep("xtx", "XᵀX of the centered data", M.flat(), "whole", { boxes: ["Σx²", "Σxy", "Σxy", "Σy²"], hint: `Subtract ${vec([mx, my])} from each point, then add up x², xy and y².`,
          slips: [slip("didn't center", raw.flat(), "Subtract the mean point first. Otherwise the main direction just points at the cloud from the origin.")] }),
        multiStep("l", "Its eigenvalues, larger first", [l1, l2], "whole", { boxes: ["λ₁", "λ₂"], hint: `Solve λ² − ${sn(M[0]![0]! + M[1]![1]!)}λ + ${sn(M[0]![0]! * M[1]![1]! - M[0]![1]! ** 2)} = 0.`.replace(" + 0 = 0", " = 0"),
          slips: [slip("read spread off the diagonal", [hi, lo], diagMsg), slip("smaller first", [l2, l1], "Larger first: λ₁ is the most spread.")] }),
        numStep("share", "Share on the first direction, as a percent", (100 * l1) / (l1 + l2), 1, { unit: "%", done: `Share on the first direction: ${dec((100 * l1) / (l1 + l2), 1)}%`, hint: `${sn(l1)} / (${sn(l1)} + ${sn(l2)}), times 100.`,
          slips: [slip("read spread off the diagonal", (100 * hi) / (hi + lo), diagMsg), slip("the second direction's share", (100 * l2) / (l1 + l2), "That's the share left for the second direction. Use λ₁ on top.")] }),
        fracStep("m", "Slope of the first direction", m, { hint: `The first row of XᵀX − ${sn(l1)}I is ${vec([M[0]![0]! - l1, M[0]![1]!])}: find (1, m) that makes it 0.`,
          slips: [slip("slope upside down", m ? 1 / m : NaN, "Slope is rise over run: second entry over first."), slip("the second direction", m ? -1 / m : NaN, "That's the second direction, perpendicular to the first. Use λ₁.")] }),
      ];
    },
    scene: (p): SceneRef => ({ scene: S.cloud, props: { pts: p.pts.map(q => q.join(",")).join(";"), quiet: true } }),
  },
  // eigen of XᵀX of the centered points, from a library
  oracle: p => {
    const n = p.pts.length, mx = sum(p.pts.map(q => q[0]!)) / n, my = sum(p.pts.map(q => q[1]!)) / n;
    const X = p.pts.map(q => [q[0]! - mx, q[1]! - my]), M = mul(transpose(X), X);
    const e = eigen(M), order = e.values.map(Number).map((v, i) => [v, i] as [number, number]).sort((a, b) => b[0] - a[0]);
    const l1 = order[0]![0], l2 = order[1]![0], w = e.vectors[order[0]![1]]!;
    return [mx, my, ...M.flat(), l1, l2, (100 * l1) / (l1 + l2), w[1]! / w[0]!];
  },
  useIt: {
    say: [
      "Keep one number per point (its place along the first direction) instead of two, and still hold 90% of the spread.",
      "For a picture, PCA of its rows and the SVD of the picture, once centered, are the same thing. That's why the build works (tracks `pr` and `ai`).",
    ],
    scene: { scene: S.cloud, props: { pts: "7,4;3,2;6,5;4,1", deg: 45 } },
  },
  deeper: [
    "PCA is the SVD of the centered X: the right singular vectors are the directions, and σ² are the eigenvalues of XᵀX. Whitening rescales each direction to spread 1.",
    "Kernel PCA finds main directions of curved clouds by first lifting the points into more dimensions.",
    "Random matrix theory, through the Marchenko–Pastur law, says which singular values are just noise, so you know where to cut (track `in`).",
  ],
};

/* ------------------------------------------------------------------ 20 · the build ------------------------------------------------------------------ */

interface P20 { m: number; n: number; k: number; sig?: number[]; j?: number }
const SIZES = [64, 100, 128, 200, 256, 512];
const KS = [1, 5, 10, 20, 50];
const thousands = (x: number) => x.toLocaleString("en-US");

export const la20: B2Lesson<P20> = {
  id: "b2-la-20", track: "la", unit: 5, title: "The build: compress an image",
  youCan: "compress a photo to a chosen size and say what it cost in quality.",
  needs: ["b2-la-18", "b2-la-19"],
  tools: [S.comp],
  play: { scene: S.comp, props: { mode: "build", k: 1 },
    say: "A photo, kept with k layers. Drag k up: the picture sharpens layer by layer, the size bar grows, and the σ plot shows where you cut. Switch to your `img`, or load a photo of your own." },
  guess: { scene: S.comp, props: { mode: "build", size: 100, k: 10, quiet: true }, kind: "slider", min: 0, max: 100, step: 0.5, start: 50, answer: 20.1, near: 4, format: x => `${x}%`,
    ask: "This photo is 100 × 100 and keeps k = 10 layers. Drag the slider to the share of the original's numbers you think it stores.",
    revealProps: {},
    reveal: "Each layer stores a column of 100, a row of 100 and its σ: 201 numbers. Ten layers store 2,010 of the 10,000, which is 20.1%." },
  nameIt: {
    say: [
      "Each layer stores a column of m numbers, a row of n numbers and its σ. k layers cost k(m + n + 1) numbers instead of m n.",
      "It only saves space while k is below m n / (m + n + 1).",
    ],
    formula: ["storage = k(m + n + 1)", "share = k(m + n + 1) / (m n)", "largest saving k = the whole part of (m n − 1) / (m + n + 1)"],
  },
  workIt: {
    reference: { m: 100, n: 100, k: 10 },
    generate(rng, i) {
      const m = i < 3 ? 100 : rng.pick(SIZES), n = i < 3 ? 100 : rng.pick(SIZES), k = rng.pick(KS);
      if (i < 3) return { m, n, k };
      const len = rng.int(3, 5), pool = Array.from({ length: 12 }, (_, t) => t + 1);
      const sig = rng.shuffle(pool).slice(0, len).sort((a, b) => b - a);
      return { m, n, k, sig, j: rng.int(1, len - 1) };
    },
    show: p => `A **${p.m} × ${p.n}** photo, kept with **k = ${p.k}** layers.${p.sig ? ` Its first singular values are **${p.sig.join(", ")}**.` : ""}`,
    steps(p) {
      const { m, n, k } = p, st = k * (m + n + 1), orig = m * n, share = (100 * st) / orig;
      let big = 0;
      while ((big + 1) * (m + n + 1) < orig) big++;
      const steps = [
        wholeStep("store", "Numbers stored", st, { hint: `${sn(k)}·(${m} + ${n} + 1).`,
          slips: [slip("k(m + n)", k * (m + n), "Each layer also stores its σ, so a layer costs m + n + 1, not m + n."), slip("k·m·n", k * m * n, "A layer is a column and a row, not a whole picture.")] }),
        wholeStep("orig", "Original", orig, { hint: `${m}·${n}.`, slips: [slip("m + n", m + n, "The original stores every pixel: m times n.")] }),
        numStep("share", "Share, as a percent", share, 1, { unit: "%", done: `Share: ${dec(share, 1)}%`, hint: `${thousands(st)} / ${thousands(orig)}, times 100.`,
          slips: [slip("share flipped", (100 * orig) / st, "Divide what you store by the original.")] }),
        wholeStep("big", "Largest k that still saves space", big, { hint: `The biggest k with k·${m + n + 1} below ${thousands(orig)}.`, done: `k = ${big}: ${thousands(big * (m + n + 1))} numbers, and k = ${big + 1} would need ${thousands((big + 1) * (m + n + 1))}`,
          slips: [slip("divided by m + n", Math.floor(orig / (m + n)), "Each layer costs m + n + 1, not m + n."), slip("one too many", big + 1, `At k = ${big + 1} the layers cost ${thousands((big + 1) * (m + n + 1))}, no less than the original.`)] }),
      ];
      if (p.sig && p.j) {
        const all = sq(p.sig), kept = (100 * sq(p.sig.slice(0, p.j))) / all;
        steps.push(numStep("energy", `Energy kept by the first ${p.j === 1 ? "layer" : `${p.j} layers`}, as a percent`, kept, 1, { unit: "%", done: `Energy kept: ${dec(kept, 1)}%`, hint: `(${squaresText(p.sig.slice(0, p.j))}) / (${squaresText(p.sig)}), times 100.`,
          slips: [slip("used σ instead of σ²", (100 * sum(p.sig.slice(0, p.j))) / sum(p.sig), "Energy adds as squares: square each σ before you add.")] }));
      }
      return steps;
    },
    scene: (p): SceneRef => ({ scene: S.comp, props: { mode: "build", size: 100, k: Math.min(p.k, 50), quiet: true } }),
  },
  // k(m + n + 1) and m n; the largest k by counting up while k(m + n + 1) < m n
  oracle: p => {
    const st = p.k * (p.m + p.n + 1), orig = p.m * p.n;
    let k = 1;
    while ((k + 1) * (p.m + p.n + 1) < orig) k++;
    const out = [st, orig, (100 * st) / orig, k];
    if (p.sig && p.j) out.push(energyKept(p.sig, p.j) * 100);
    return out;
  },
  useIt: {
    say: [
      "**The build.** Compress your own photo to under 25% of its size, choose k by eye, and read the energy you kept. For color, do it once per channel: three times the storage.",
      "Keep `k` and the singular values, and the finished compressor goes into your Notebook.",
    ],
    project: "la-build",
  },
  deeper: [
    "Real photos have fast-falling σ's, because their rows look alike; noise has flat σ's and doesn't compress.",
    "JPEG uses a fixed basis of cosines (shadows, from b2-la-03) on 8 × 8 blocks, and wavelets use averages and differences (b2-la-12). SVD builds a basis for each picture, so it has to store that basis too.",
    "Quantizing the stored numbers turns this into bits (track `in`). Low-rank layers inside neural networks do the same trade (track `ai`).",
  ],
};

export const UNIT5 = [la16, la17, la18, la19, la20];
