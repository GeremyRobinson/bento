// Multivariable, part 2 (finding the best): b2-mv-11 to b2-mv-20, from curriculum/specs/bento2/multivariable.md.
import type { B2Lesson, SceneRef } from "../../model";
import { fracStep, multiStep, numStep, slip, tapStep, wholeStep } from "../../make";
import { formatAnswer } from "../../steps";
import type { Rng } from "../../../curriculum/generators/rng";
import { descend, eig2, LAND, pt, sn, terms, vec } from "./maths";

const fr = (x: number) => formatAnswer(x, "fraction");
/** a square as written: 4², (−3)² */
const sq = (n: number) => (n < 0 ? `(${sn(n)})²` : `${n}²`);
const ex = (x: number) => `(${x})`;
const lay = (opts: string[], ord: number[]) => ({ choices: ord.map(i => opts[i]!), at: (i: number) => ord.indexOf(i) });
const nz = (rng: Rng, lo: number, hi: number) => { let v = 0; while (v === 0) v = rng.int(lo, hi); return v; };
const cd = (g: (h: number) => number, h = 1e-5) => (g(h) - g(-h)) / (2 * h);
const quad = (p: number, q: number, r: number) => (x: number, y: number) => p * x * x + q * x * y + r * y * y;
const quadStr = (p: number, q: number, r: number) => terms([[p, "x²"], [q, "xy"], [r, "y²"]]);
const quadSrc = (p: number, q: number, r: number) => `${ex(p)}*x^2 + ${ex(q)}*x*y + ${ex(r)}*y^2`;
const KINDS = ["Pit", "Peak", "Pass", "Can't tell"];

/* ================================================================ unit 4 · Which way is down ================================================================ */

interface P11 { p: number; q: number; r: number; a: number; b: number; v: [number, number] }
const DIRS: [number, number][] = [[3, 4], [4, -3], [-5, 12], [6, 8], [1, 0], [0, -1]];
const EASY_DIRS: [number, number][] = [[1, 0], [0, -1], [3, 4]];
const GUESS11 = (Math.atan2(3, 5) * 180) / Math.PI;

export const mv11: B2Lesson<P11> = {
  id: "b2-mv-11", track: "mv", unit: 4, title: "Directional derivatives",
  youCan: "find the slope of a landscape in any direction you choose.",
  needs: ["b2-mv-02", "b2-la-03"],
  tools: ["surface", "slice"],
  play: { scene: "compass", props: { src: "x^2 + 3*x*y", r: 2, a: 1, b: 1, ang: 0 },
    say: "Stand at a point and turn the compass needle. The slice in that direction opens beside it, and a dial plots the slope against the needle's angle as you turn." },
  guess: { scene: "compass", props: { src: "x^2 + 3*x*y", r: 2, a: 1, b: 1, ang: 0, quiet: true }, kind: "slider", min: 0, max: 355, step: 5, start: 90, answer: GUESS11, near: 20, unit: "°",
    format: x => String(Math.round(x)),
    ask: "Standing at (1, 1) on f = x² + 3xy, set the needle where you think the slope is steepest uphill.",
    revealProps: { spin: true },
    reveal: "About 31°. The slope against angle is a cosine wave, and it peaks where the needle points along ⟨5, 3⟩, the two partial slopes." },
  nameIt: {
    say: ["The slope in direction u (a unit vector) mixes the two partial slopes by how much you move each way."],
    formula: ["D_u f = f_x u₁ + f_y u₂, with u₁² + u₂² = 1"],
  },
  workIt: {
    reference: { p: 1, q: 3, r: 0, a: 1, b: 1, v: [3, 4] },
    generate(rng, i) {
      for (;;) {
        const p = rng.int(-3, 3), q = rng.int(-3, 3), r = rng.int(-3, 3), a = rng.int(-2, 2), b = rng.int(-2, 2);
        const fx = 2 * p * a + q * b, fy = q * a + 2 * r * b;
        if (!fx && !fy) continue;
        return { p, q, r, a, b, v: rng.pick(i < 3 ? EASY_DIRS : DIRS) };
      }
    },
    show: p => `f(x, y) = ${quadStr(p.p, p.q, p.r)}, at **${pt(p.a, p.b)}**, heading along **v = ${vec(...p.v)}**. Answers as fractions.`,
    steps(p) {
      const fx = 2 * p.p * p.a + p.q * p.b, fy = p.q * p.a + 2 * p.r * p.b, [v1, v2] = p.v, L = Math.hypot(v1, v2);
      return [
        multiStep("g", "f_x and f_y at the point", [fx, fy], "whole", { boxes: ["f_x", "f_y"], hint: `f_x = ${terms([[2 * p.p, "x"], [p.q, "y"]])}, f_y = ${terms([[p.q, "x"], [2 * p.r, "y"]])}.`,
          slips: [slip("swapped", [fy, fx], "f_x is the slope along x and f_y along y. They're in the other order.")] }),
        wholeStep("L", "Length of v", L, { hint: `√(${sq(v1)} + ${sq(v2)}).`,
          slips: [slip("added", Math.abs(v1) + Math.abs(v2), `Length is √(${sq(v1)} + ${sq(v2)}) = ${L}.`)] }),
        multiStep("u", "Unit direction u", [v1 / L, v2 / L], "fraction", { boxes: ["u₁", "u₂"], hint: `Divide v by its length, ${L}.`,
          slips: [slip("not divided", [v1, v2], `A direction has to have length 1. Divide ${vec(v1, v2)} by ${L}.`)] }),
        fracStep("D", "D_u f", (fx * v1 + fy * v2) / L, { hint: `f_x u₁ + f_y u₂ = (${sn(fx)})(${fr(v1 / L)}) + (${sn(fy)})(${fr(v2 / L)}).`,
          slips: [
            slip("not divided", fx * v1 + fy * v2, `A direction has to have length 1, or the slope gets multiplied by the arrow's length. Divide ${vec(v1, v2)} by ${L}.`),
            slip("used the point", (p.a * v1 + p.b * v2) / L, "Mix the slopes f_x and f_y, not the coordinates."),
          ] }),
      ];
    },
    scene: p => ({ scene: "compass", props: { src: quadSrc(p.p, p.q, p.r), r: 2.5, a: p.a, b: p.b, ang: (Math.atan2(p.v[1], p.v[0]) * 180) / Math.PI } }),
  },
  oracle: p => {
    const f = quad(p.p, p.q, p.r), L = Math.hypot(...p.v), u = [p.v[0] / L, p.v[1] / L];
    const D = cd(h => f(p.a + h * u[0]!, p.b + h * u[1]!));
    return [Math.round(cd(h => f(p.a + h, p.b))), Math.round(cd(h => f(p.a, p.b + h))), L, u[0]!, u[1]!, Math.round(D * L) / L];
  },
  useIt: {
    say: ["On Two lakes at (1/2, 0), find the slope heading straight toward the left valley, u = ⟨−1, 0⟩. It's 5/4.",
      "It's positive: heading left you first climb toward the pass at x ≈ 0.06 before the ground drops into the valley. The hiker readout gains \"slope this way\"."],
    scene: { scene: "compass", props: { fn: "land", a: 0.5, b: 0, ang: 180 } },
  },
  deeper: [
    "Directional derivatives can exist in every direction while f is not differentiable.",
    "f = x²y/(x⁴ + y²) has all of them at the origin but is not even continuous there: along y = x² it equals 1/2.",
  ],
};

interface P12 { a: number; b: number; x0: number; y0: number; ord: number[] }

export const mv12: B2Lesson<P12> = {
  id: "b2-mv-12", track: "mv", unit: 4, title: "The gradient: steepest way up",
  youCan: "find the gradient, the direction of steepest climb, and how steep it is.",
  needs: ["b2-mv-11"],
  tools: ["gradient", "surface"],
  play: { scene: "gradient", props: { src: "x^2 + 2*y^2", r: 3, px: 2, py: 1 },
    say: "Arrows cover the contour map, each pointing straight uphill. Drag the point: its arrow always crosses its contour at a right angle, and grows where the contours crowd." },
  guess: { scene: "gradient", props: { src: "x^2 + 2*y^2", r: 3, px: 2, py: 1, pick: true, quiet: true }, kind: "choice", options: ["A", "B", "C", "D"], answer: 1,
    ask: "At the marked point, which of the four arrows is the gradient?",
    reveal: "B: it crosses the contour at a right angle and points to higher ground. A runs along the contour (slope 0), C points downhill, and D climbs, but not the steepest way." },
  nameIt: {
    say: [
      "The gradient packs both slopes into one arrow. It points the steepest way up, its length is that steepest slope, and it is at right angles to the contour.",
      "Every directional slope is its shadow.",
    ],
    formula: ["∇f = ⟨f_x, f_y⟩", "D_u f = ∇f · u = |∇f| cos θ"],
  },
  workIt: {
    reference: { a: 1, b: 2, x0: 3, y0: 2, ord: [0, 1, 2, 3] },
    generate(rng, i) {
      for (;;) {
        const a = rng.int(1, 4), b = rng.int(1, 4), x0 = rng.int(-3, 3), y0 = rng.int(-3, 3);
        if (!x0 && !y0) continue;
        const L = Math.hypot(2 * a * x0, 2 * b * y0);
        if (i < 3 && (!x0 || !y0 || !Number.isInteger(L))) continue;
        return { a, b, x0, y0, ord: rng.shuffle([0, 1, 2, 3]) };
      }
    },
    show: p => `f(x, y) = ${terms([[p.a, "x²"], [p.b, "y²"]])}, at **${pt(p.x0, p.y0)}**. The steepest slope to 2 decimal places.`,
    steps(p) {
      const gx = 2 * p.a * p.x0, gy = 2 * p.b * p.y0, L = Math.round(Math.hypot(gx, gy) * 100) / 100;
      const A = lay([vec(-gx, -gy), vec(gx, gy), vec(gy, -gx), vec(-gy, gx)], p.ord);
      return [
        multiStep("g", "∇f", [gx, gy], "whole", { boxes: ["f_x", "f_y"], hint: `∇f = ⟨${terms([[2 * p.a, "x"]])}, ${terms([[2 * p.b, "y"]])}⟩ at ${pt(p.x0, p.y0)}.` }),
        numStep("L", "Steepest slope |∇f|", L, 2, { hint: `√(${sq(gx)} + ${sq(gy)}).`,
          slips: [slip("added", Math.abs(gx) + Math.abs(gy), `The length is √(${sq(gx)} + ${sq(gy)}), not the sum of the parts.`)] }),
        tapStep("down", "Steepest way down", A.choices, A.at(0), { hint: "Downhill is the opposite of the gradient.",
          slips: [slip("uphill", A.at(1), "∇f points up. Downhill is −∇f."), slip("along", A.at(2), "That one runs along the contour, at right angles to ∇f. Its slope is 0."),
            slip("along", A.at(3), "That one runs along the contour, at right angles to ∇f. Its slope is 0.")] }),
        wholeStep("c", "Slope walking along the contour", 0, { hint: "Along a contour, your height doesn't change.",
          slips: [slip("steepest", L, "Along a contour your height doesn't change, so the slope is 0. That's why ∇f is at right angles to it.")] }),
      ];
    },
    scene: p => ({ scene: "gradient", props: { src: `${p.a}*x^2 + ${p.b}*y^2`, r: 3.5, px: p.x0, py: p.y0 } }),
  },
  oracle: p => [2 * p.a * p.x0, 2 * p.b * p.y0, Math.round(Math.hypot(2 * p.a * p.x0, 2 * p.b * p.y0) * 100) / 100, p.ord.indexOf(0), 0],
  useIt: {
    say: ["Project 3, Rain map, opens. Rain falls on Two lakes and streams follow −∇f.",
      "Each spot is colored by the valley it drains to, and the pass between the two basins is marked. The build gains the compass: gradient arrows everywhere."],
    project: "mv-rain",
  },
  deeper: [
    "Gradient fields are conservative: ∫_C ∇f · dr = f(end) − f(start) for any path (the fundamental theorem for line integrals). That's why both carts in lesson 10 did the same work, and why curl ∇f = 0.",
    "The gradient depends on how you measure length: with a different inner product, the steepest direction changes (the Riemannian gradient, and the natural gradient in ai).",
  ],
};

interface P13 { kindB: boolean; s: number; m: number; b: number }
const kindIdx = (fxx: number, fyy: number, fxy: number) => { const [l1, l2] = eig2(fxx, fxy, fyy); if (Math.abs(l1) < 1e-9 || Math.abs(l2) < 1e-9) return 3; return l1 > 0 ? 0 : l2 < 0 ? 1 : 2; };

export const mv13: B2Lesson<P13> = {
  id: "b2-mv-13", track: "mv", unit: 4, title: "Peaks, pits and passes",
  youCan: "find the flat spots of a landscape and tell a peak from a pit from a pass.",
  needs: ["c-extrema", "c-concavity", "b2-mv-12"],
  tools: ["morph", "surface"],
  play: { scene: "morph", props: { a: 1, b: 0, c: 1 },
    say: "f = ax² + bxy + cy², with three sliders. Drag them and the surface morphs from bowl to saddle to dome to trough, with a live badge showing D = 4ac − b²." },
  guess: { scene: "morph", props: { a: 1, b: 3, c: 1, quiet: true }, kind: "choice", options: ["Bowl", "Dome", "Saddle"], answer: 2,
    ask: "For f = x² + 3xy + y², both the x slice and the y slice curve up. Is it a bowl, a dome or a saddle?",
    revealProps: { diag: true },
    reveal: "A saddle. Along the line y = −x, f = −x², which curves down. D = 4 − 9 = −5 < 0." },
  nameIt: {
    say: [
      "At a peak, a pit or a pass, the ground is flat: ∇f = 0. The second derivatives say which. Put them in the Hessian and use its determinant D.",
      "D > 0 and f_xx > 0: a pit (minimum). D > 0 and f_xx < 0: a peak (maximum). D < 0: a pass (saddle). D = 0: the test can't tell.",
    ],
    formula: ["H = [[f_xx, f_xy], [f_xy, f_yy]]", "D = f_xx f_yy − f_xy²"],
  },
  workIt: {
    reference: { kindB: false, s: 1, m: 2, b: 0 },
    generate(rng, i) {
      if (i < 3) return { kindB: false, s: 1, m: rng.int(1, 3), b: 0 };
      if (rng.next() < 0.35) return { kindB: true, s: 0, m: 0, b: rng.int(0, 4) };
      return { kindB: false, s: rng.int(1, 3), m: nz(rng, -3, 3), b: 0 };
    },
    show: p => p.kindB ? `f(x, y) = ${terms([[1, "x²"], [p.b, "xy"], [1, "y²"]])}, at its flat spot, the origin.`
      : `f(x, y) = ${terms([[1, "x³"], [-3 * p.s * p.s, "x"], [p.m, "y²"]])}.`,
    steps(p) {
      if (p.kindB) {
        const D = 4 - p.b * p.b, k = p.b < 2 ? 0 : p.b === 2 ? 3 : 2;
        return [
          multiStep("h", "f_xx, f_yy, f_xy", [2, 2, p.b], "whole", { boxes: ["f_xx", "f_yy", "f_xy"], hint: "Differentiate twice: in x, in y, and once in each." }),
          wholeStep("D", "D", D, { hint: "f_xx f_yy − f_xy².", slips: [slip("added", 4 + p.b * p.b, "The cross term is subtracted: D = f_xx f_yy − f_xy².")] }),
          tapStep("k", "Kind", KINDS, k, { hint: "Read the sign of D, then f_xx.",
            slips: [p.b > 2 && slip("trusted f_xx", 0, "D < 0 means some direction curves up and another curves down. That's a pass, whatever f_xx says."),
              p.b === 2 && slip("said pit", 0, "D = 0 means the test is silent. Here f = (x + y)², a trough: every point of the line y = −x is lowest.")] }),
        ];
      }
      const { s, m } = p, D = 12 * s * m;
      return [
        wholeStep("n", "How many flat spots", 2, { hint: `f_x = 3x² − ${3 * s * s} and f_y = ${terms([[2 * m, "y"]])}. Both are 0 at x = ±${s}, y = 0.` }),
        wholeStep("x", "The one with x > 0 is at x =", s, { hint: `3x² = ${3 * s * s}.` }),
        multiStep("h", `At (${s}, 0): f_xx, f_yy, f_xy`, [6 * s, 2 * m, 0], "whole", { boxes: ["f_xx", "f_yy", "f_xy"], hint: `f_xx = 6x, f_yy = ${2 * m}, f_xy = 0.` }),
        wholeStep("D", "D there", D, { hint: "f_xx f_yy − f_xy²." }),
        tapStep("k1", `Kind at (${s}, 0)`, KINDS, m > 0 ? 0 : 2, { hint: "Read the sign of D, then f_xx.",
          slips: [m < 0 && slip("trusted f_xx", 0, "D < 0 means some direction curves up and another curves down. That's a pass, whatever f_xx says.")] }),
        tapStep("k2", `Kind at (−${s}, 0)`, KINDS, m > 0 ? 2 : 1, { hint: `There f_xx = −${6 * s}, so D = ${sn(-D)}.`,
          slips: [m > 0 && slip("trusted f_yy", 0, "D < 0 means some direction curves up and another curves down. That's a pass, whatever f_yy says."),
            m < 0 && slip("said pit", 0, "f_xx < 0 with D > 0: it curves down every way. That's a peak.")] }),
      ];
    },
    scene: (p): SceneRef => p.kindB ? { scene: "morph", props: { a: 1, b: p.b, c: 1 } } : { scene: "flats", props: { src: `x^3 - ${3 * p.s * p.s}*x + ${ex(p.m)}*y^2`, r: p.s + 1.5 } },
  },
  oracle: p => {
    if (p.kindB) { const D = 4 - p.b * p.b; return [2, 2, p.b, D, kindIdx(2, 2, p.b)]; }
    const { s, m } = p;
    return [2, s, 6 * s, 2 * m, 0, 12 * s * m, kindIdx(6 * s, 2 * m, 0), kindIdx(-6 * s, 2 * m, 0)];
  },
  useIt: {
    say: ["Find all three flat spots of Two lakes with the finder's flat-spot search, and classify them: two pits and one pass.",
      "The build gains the stop classifier."],
    scene: { scene: "flats", props: { fn: "land" } },
  },
  deeper: [
    "The Hessian's eigenvalues are the curvatures along its eigenvectors (b2-la-15), and the test asks whether H is positive definite.",
    "Degenerate cases: the monkey saddle x³ − 3xy² has D = 0 and three ways down.",
    "Morse theory: on a closed surface, pits − passes + peaks equals the Euler characteristic (2 on a sphere, 0 on a donut), so flat spots can't be added one at a time.",
  ],
};

interface P14 { a: number; b: number; x0: number; y0: number; en: number; ed: number }

export const mv14: B2Lesson<P14> = {
  id: "b2-mv-14", track: "mv", unit: 4, title: "Gradient descent: roll downhill",
  youCan: "find a low point by stepping against the gradient, and pick a step size that works.",
  needs: ["b2-mv-12", "b2-mv-13"],
  tools: ["finder", "surface"],
  play: { scene: "descent", props: { src: "x^2 + y^2", r: 4, sx: 3, sy: 2, eta: 0.25 },
    say: "Drop a ball on a bowl. Each tap takes one step x ← x − η∇f and leaves a dot on the contour map. Drag η: small steps creep, medium ones land, big ones bounce, bigger ones fly off." },
  guess: { scene: "descent", props: { src: "x^2 + y^2", r: 4, sx: 3, sy: 2, eta: 1.1, quiet: true }, kind: "choice", options: ["It settles", "It bounces forever", "It flies off"], answer: 2,
    ask: "On f = x² + y² from (3, 2), η = 0.5 lands on the bottom in one step. What happens with η = 1.1?",
    revealProps: { auto: true },
    reveal: "It flies off. Each step multiplies the position by 1 − 2(1.1) = −1.2: it flips sides and lands farther out every time." },
  nameIt: {
    say: [
      "To go down, step against the gradient by a small amount η.",
      "On a bowl f = ax² + by², each step multiplies x by 1 − 2ηa and y by 1 − 2ηb, so it settles only if both factors are between −1 and 1.",
    ],
    formula: ["x_{k+1} = x_k − η∇f(x_k)", "settles on ax² + by² exactly when 0 < η < 1/max(a, b)"],
  },
  workIt: {
    reference: { a: 1, b: 2, x0: 4, y0: 2, en: 1, ed: 4 },
    generate(rng, i) {
      for (;;) {
        const a = i < 3 ? 1 : rng.int(1, 5), b = i < 3 ? rng.int(1, 2) : rng.int(1, 5);
        const x0 = 2 * rng.int(-2, 2), y0 = 2 * rng.int(-2, 2);
        if (!x0 && !y0) continue;
        const ed = i < 3 ? 4 : rng.pick([10, 8, 5, 4]);
        if (1 / ed >= 1 / Math.max(a, b)) continue;
        return { a, b, x0, y0, en: 1, ed };
      }
    },
    show: p => `f(x, y) = ${terms([[p.a, "x²"], [p.b, "y²"]])}, start at **${pt(p.x0, p.y0)}**, step size **η = 1/${p.ed}**. Answers as fractions.`,
    steps(p) {
      const eta = p.en / p.ed, gx = 2 * p.a * p.x0, gy = 2 * p.b * p.y0, k = 1 - 2 * eta * p.a;
      return [
        multiStep("g", "∇f at the start", [gx, gy], "whole", { boxes: ["f_x", "f_y"], hint: `∇f = ⟨${terms([[2 * p.a, "x"]])}, ${terms([[2 * p.b, "y"]])}⟩.` }),
        multiStep("x1", "Position after one step", [p.x0 - eta * gx, p.y0 - eta * gy], "fraction", { boxes: ["x", "y"], hint: `${pt(p.x0, p.y0)} − (1/${p.ed})${vec(gx, gy)}.`,
          slips: [slip("added", [p.x0 + eta * gx, p.y0 + eta * gy], "+∇f is uphill. Subtract it."),
            slip("no η", [p.x0 - gx, p.y0 - gy], "A full gradient step is usually far too big. Multiply ∇f by η first.")] }),
        fracStep("k", "Factor on x each step, 1 − 2ηa", k, { hint: `1 − 2(1/${p.ed})(${p.a}).` }),
        fracStep("x2", "x after two steps", p.x0 * k * k, { hint: `${sn(p.x0)} × (${fr(k)})².`,
          slips: [slip("one step", p.x0 * k, "That's one step. Multiply by the factor once more.")] }),
        fracStep("lim", "Settles for every step size below", 1 / Math.max(p.a, p.b), { hint: `The steeper direction sets the limit: 1 − 2η·${Math.max(p.a, p.b)} must stay above −1.`,
          slips: [slip("2 over", 2 / Math.max(p.a, p.b), `Here f = ${terms([[Math.max(p.a, p.b), p.a >= p.b ? "x²" : "y²"]])} in the steep direction, so the factor is 1 − ${2 * Math.max(p.a, p.b)}η. It stays above −1 only while η < 1/${Math.max(p.a, p.b)}.`)] }),
      ];
    },
    scene: p => ({ scene: "descent", props: { src: `${p.a}*x^2 + ${p.b}*y^2`, r: 5, sx: p.x0, sy: p.y0, eta: p.en / p.ed } }),
  },
  oracle: p => {
    const eta = p.en / p.ed, run = descend(quad(p.a, 0, p.b), p.x0, p.y0, eta, 2);
    let lo = 0, hi = 2;
    for (let k = 0; k < 60; k++) { const mid = (lo + hi) / 2; if (Math.abs(1 - 2 * mid * Math.max(p.a, p.b)) < 1) lo = mid; else hi = mid; }
    return [2 * p.a * p.x0, 2 * p.b * p.y0, run[1]![0], run[1]![1], 1 - 2 * eta * p.a, run[2]![0], Math.round(lo * 1e6) / 1e6];
  },
  useIt: {
    say: ["Drop the ball on Two lakes at (1/2, 1) with η = 0.1, run it, and save where it stops: near (0.97, 0), the higher valley.",
      "The build gains the ball, and its first lesson: descent finds a low point, not always the lowest."],
    saves: { name: "bestSoFar", value: () => { const r = descend(LAND, 0.5, 1, 0.1, 400), [x, y] = r[r.length - 1]!; return [x, y, LAND(x, y)]; }, labels: ["x", "y", "height"], note: "where descent from (1/2, 1) stops on Two lakes" },
    scene: { scene: "descent", props: { fn: "land", sx: 0.5, sy: 1, eta: 0.1, auto: true } },
  },
  deeper: [
    "If ∇f changes no faster than L (f is L-smooth), any η ≤ 1/L makes f drop every step, by at least (η/2)|∇f|²: the descent lemma.",
    "If f is also μ-strongly convex, the error shrinks like (1 − μ/L)ᵏ.",
    "Gradient descent is Euler's method on the gradient flow dx/dt = −∇f (de, bc-euler).",
  ],
};

/* ================================================================ unit 5 · Fences ================================================================ */

interface P15 { kindB: boolean; p: number; q: number; m: number; ord: number[] }
const PAIRS15: [number, number][] = [[3, 4], [4, 3], [1, 2], [2, 1], [5, 12]];
function eqs15(P: P15): string[] {
  const { p, q } = P, l = (k: number) => (k === 1 ? "λ" : `${k}λ`);
  const c = P.kindB
    ? [`2x = ${l(p)}, 2y = ${l(q)}`, `2x = ${l(q)}, 2y = ${l(p)}`, `x = ${l(p)}, y = ${l(q)}`, `2x = ${p}, 2y = ${q}`]
    : [`y = ${l(p)}, x = ${l(q)}`, ...(p !== q ? [`x = ${l(p)}, y = ${l(q)}`] : []), `y = ${p}, x = ${q}`, `x + y = ${l(p + q)}`, `${l(p)} = 1, ${l(q)} = 1`];
  const out: string[] = [];
  for (const s of c) if (!out.includes(s)) out.push(s);
  return out.slice(0, 4);
}
const best15 = (P: P15, c: number) => {
  // search the fence numerically: x from 0 to c/p in steps of 0.001
  let best = P.kindB ? Infinity : -Infinity, bx = 0;
  for (let x = 0; x <= c / P.p + 1e-9; x += 0.001) {
    const y = (c - P.p * x) / P.q, v = P.kindB ? x * x + y * y : x * y;
    if (P.kindB ? v < best : v > best) { best = v; bx = x; }
  }
  return { best, x: Math.round(bx * 1000) / 1000 };
};

export const mv15: B2Lesson<P15> = {
  id: "b2-mv-15", track: "mv", unit: 5, title: "Lagrange multipliers: the best spot on a fence",
  youCan: "find the best point along a constraint by lining up two gradients.",
  needs: ["b2-mv-12"],
  tools: ["finder", "surface"],
  play: { scene: "fence", props: { mode: "line", fp: 1, fq: 2, fc: 8, s: 2 },
    say: "A fence x + 2y = 8 lies across the contour map of f = xy. Walk along it with the height meter; ∇f and ∇g are drawn at your feet. At the best spot the fence just touches a contour, and the two arrows line up." },
  guess: { scene: "fence", props: { mode: "line", fp: 1, fq: 2, fc: 8, s: 2, quiet: true }, kind: "slider", min: 0, max: 8, step: 0.25, start: 2, answer: 4, near: 0.5,
    format: x => `x = ${x}`,
    ask: "On the fence x + 2y = 8 over f = xy, where along the fence is f highest?",
    revealProps: { s: 4 },
    reveal: "At (4, 2), where f = 8. There the contour xy = 8 just touches the fence, and ∇f = ⟨2, 4⟩ lines up with ∇g = ⟨1, 2⟩." },
  nameIt: {
    say: [
      "Along a fence, you're at the best spot when you can't climb by sliding along it. That happens when the contour touches the fence, so the two gradients line up.",
      "The multiplier λ says how much the best value grows if you loosen the fence by one unit.",
    ],
    formula: ["∇f = λ∇g and g(x, y) = c", "λ = d(best f)/dc"],
  },
  workIt: {
    reference: { kindB: false, p: 2, q: 3, m: 2, ord: [0, 1, 2, 3] },
    generate(rng, i) {
      if (i < 3 || rng.next() < 0.55) return { kindB: false, p: rng.int(1, 4), q: rng.int(1, 4), m: i < 3 ? 1 : rng.int(1, 3), ord: rng.shuffle([0, 1, 2, 3]) };
      const [p, q] = rng.pick(PAIRS15);
      return { kindB: true, p: p!, q: q!, m: rng.int(1, 2), ord: rng.shuffle([0, 1, 2, 3]) };
    },
    show: p => p.kindB
      ? `Smallest **x² + y²** on the fence **${terms([[p.p, "x"], [p.q, "y"]])} = ${(p.p * p.p + p.q * p.q) * p.m}**.`
      : `Largest **xy** on the fence **${terms([[p.p, "x"], [p.q, "y"]])} = ${2 * p.p * p.q * p.m}**, with x, y ≥ 0.`,
    steps(P) {
      const { p, q, m } = P, E = lay(eqs15(P), P.ord);
      const c = P.kindB ? (p * p + q * q) * m : 2 * p * q * m;
      const x = P.kindB ? p * m : q * m, y = P.kindB ? q * m : p * m, best = P.kindB ? (p * p + q * q) * m * m : p * q * m * m, lam = P.kindB ? 2 * m : m;
      return [
        tapStep("eq", "The equations ∇f = λ∇g", E.choices, E.at(0), { hint: P.kindB ? `∇(x² + y²) = ⟨2x, 2y⟩ and ∇g = ${vec(p, q)}.` : `∇(xy) = ⟨y, x⟩ and ∇g = ${vec(p, q)}.`,
          slips: [(P.kindB || p !== q) && slip("paired wrong", E.at(1), P.kindB ? `∇(x² + y²) = ⟨2x, 2y⟩, so 2x goes with ${p}, the x-part of ∇g.` : `∇(xy) = ⟨y, x⟩, so y goes with the x-part of ∇g, which is ${p}.`)] }),
        wholeStep("x", "x", x, { hint: P.kindB ? `x = ${p}λ/2 and y = ${q}λ/2; put them in the fence.` : `y = ${p}λ and x = ${q}λ; put them in the fence: ${2 * p * q}λ = ${c}.`,
          slips: [!P.kindB && slip("all in x", c / p, "That's an end of the fence, where xy = 0. The best spot is where the gradients line up."),
            p !== q && slip("paired wrong", y, P.kindB ? `2x goes with ${p}, the x-part of ∇g.` : `∇(xy) = ⟨y, x⟩, so y goes with the x-part of ∇g, which is ${p}.`)] }),
        wholeStep("y", "y", y, { hint: `On the fence: ${terms([[p, "x"], [q, "y"]])} = ${c}.` }),
        wholeStep("best", "Best value of f", best, { hint: P.kindB ? `${x}² + ${y}².` : `${x} × ${y}.` }),
        wholeStep("lam", "λ", lam, { hint: P.kindB ? `From 2x = ${p}λ: λ = ${2 * x}/${p}.` : `From y = ${p}λ: λ = ${y}/${p}.`,
          slips: [slip("the best value", best, `λ is the rate: loosen the fence from ${c} to ${c + 1} and the best value grows by about λ.`)] }),
      ];
    },
    scene: (P): SceneRef => ({ scene: "fence", props: P.kindB
      ? { mode: "line", obj: "r2", fp: P.p, fq: P.q, fc: (P.p * P.p + P.q * P.q) * P.m, s: 0.5 }
      : { mode: "line", fp: P.p, fq: P.q, fc: 2 * P.p * P.q * P.m, s: 0.5 } }),
  },
  oracle: P => {
    const c = P.kindB ? (P.p * P.p + P.q * P.q) * P.m : 2 * P.p * P.q * P.m, b0 = best15(P, c), b1 = best15(P, c + 0.01);
    const y = Math.round(((c - P.p * b0.x) / P.q) * 1000) / 1000, best = P.kindB ? b0.x ** 2 + y ** 2 : b0.x * y;
    return [P.ord.indexOf(0), b0.x, y, best, Math.round((b1.best - b0.best) / 0.01)];
  },
  useIt: {
    say: ["A road crosses Two lakes along y = 1/2. Find its lowest point with the fence mode and read λ.",
      "It sits at about (−1.03, 1/2), height about −0.004, with λ = 1: here g = y, so ∇f = ⟨f_x, 2y⟩ = λ⟨0, 1⟩ gives λ = 2y = 1. Shift the road up by a small d and its lowest height rises by about d. The build gains road search."],
    scene: { scene: "fence", props: { mode: "road", fn: "land", road: 0.5, s: 0 } },
  },
  deeper: [
    "Proof sketch: at a constrained best, ∇f has no part along the fence's tangent, so it is a multiple of the normal ∇g. With several constraints, ∇f = Σλᵢ∇gᵢ.",
    "λ is the shadow price, and the Lagrangian L = f − λ(g − c) leads to duality: under convexity, the best value equals a min over λ of a max over (x, y).",
    "The method fails when ∇g = 0 at the best point (the constraint qualification). Example: minimize x on y² = x³.",
  ],
};

interface P16 { p: number; q: number; m: number }
const clamp = (v: number, m: number) => Math.max(0, Math.min(m, v));

export const mv16: B2Lesson<P16> = {
  id: "b2-mv-16", track: "mv", unit: 5, title: "Fenced plots: best spot on a closed region",
  youCan: "find the highest and lowest values of a landscape on a closed region by checking the inside and the edge.",
  needs: ["c-extrema", "b2-mv-13", "b2-mv-15"],
  tools: ["finder", "surface"],
  play: { scene: "fence", props: { mode: "square", p: 1, q: 1, m: 2 },
    say: "A square plot is fenced on a bowl. Drag the bowl's bottom around, or the corner to resize the plot. The boundary scan walks the fence and unrolls its height into a graph; the candidates light up, and the lowest point jumps from inside to the fence as the bottom leaves the plot." },
  guess: { scene: "fence", props: { mode: "square", p: 3, q: 1, m: 2, quiet: true }, kind: "choice", options: ["Inside the plot", "On the fence"], answer: 1,
    ask: "For f = (x − 3)² + (y − 1)² on the square 0 ≤ x ≤ 2, 0 ≤ y ≤ 2, is the lowest point inside or on the fence?",
    reveal: "On the fence, at (2, 1). The bowl's bottom (3, 1) is outside the plot, so the lowest you can reach is the fence point nearest it." },
  nameIt: {
    say: [
      "On a closed, bounded region a continuous landscape has a highest and a lowest point. They're at flat spots inside or somewhere on the fence, so check both.",
      "For a fence written as g ≤ c, either the fence doesn't matter (∇f = 0 inside) or you're pressed against it: for a minimum, ∇f = −μ∇g with μ ≥ 0, so downhill points out through the fence.",
    ],
    formula: ["candidates: flat spots inside, the fence, its corners", "pressed on the fence: ∇f = −μ∇g, μ ≥ 0"],
  },
  workIt: {
    reference: { p: 3, q: 1, m: 2 },
    generate(rng, i) {
      return i < 3 ? { p: rng.int(0, 3), q: rng.int(0, 3), m: 2 } : { p: rng.int(-2, 5), q: rng.int(-2, 5), m: rng.int(2, 4) };
    },
    show: p => `f(x, y) = (x ${p.p < 0 ? "+" : "−"} ${Math.abs(p.p)})² + (y ${p.q < 0 ? "+" : "−"} ${Math.abs(p.q)})² on the square **0 ≤ x ≤ ${p.m}, 0 ≤ y ≤ ${p.m}**.`.replace(/\(x − 0\)²/, "x²").replace(/\(y − 0\)²/, "y²"),
    steps(p) {
      const inside = p.p >= 0 && p.p <= p.m && p.q >= 0 && p.q <= p.m, cx = clamp(p.p, p.m), cy = clamp(p.q, p.m);
      const f = (x: number, y: number) => (x - p.p) ** 2 + (y - p.q) ** 2;
      const hi = Math.max(f(0, 0), f(p.m, 0), f(0, p.m), f(p.m, p.m)), mid = Math.max(f(p.m / 2, 0), f(0, p.m / 2), f(p.m, p.m / 2), f(p.m / 2, p.m));
      const xOut = cx !== p.p, yOut = cy !== p.q;
      return [
        tapStep("in", `Is the bowl's bottom ${pt(p.p, p.q)} inside the plot?`, ["Yes", "No"], inside ? 0 : 1, { hint: `Inside means both coordinates are between 0 and ${p.m}; on the fence counts.` }),
        multiStep("lo", "Lowest point", [cx, cy], "whole", { boxes: ["x", "y"], hint: `Clamp each coordinate of the bottom into 0 to ${p.m}.`,
          slips: [!inside && slip("off the plot", [p.p, p.q], `${pt(p.p, p.q)} is off the plot. The lowest you can reach is on the fence, as close to it as possible.`),
            xOut && !yOut && slip("clamped both", [cx, cx], `Only x is out of range. Keep y = ${sn(p.q)}, which is already inside.`),
            yOut && !xOut && slip("clamped both", [cy, cy], `Only y is out of range. Keep x = ${sn(p.p)}, which is already inside.`)] }),
        wholeStep("lv", "Lowest value", f(cx, cy), { hint: `f${pt(cx, cy)}.` }),
        wholeStep("hv", "Highest value", hi, { hint: "Check the four corners.",
          slips: [slip("used the bottom", f(cx, cy), "That's the lowest. A bowl rises in every direction from its bottom, so on a square its highest point is a corner."),
            slip("edge middle", mid, "A bowl rises in every direction from its bottom, so on a square its highest point is a corner, not the middle of an edge.")] }),
      ];
    },
    scene: p => ({ scene: "fence", props: { mode: "square", p: p.p, q: p.q, m: p.m } }),
  },
  oracle: p => {
    const f = (x: number, y: number) => (x - p.p) ** 2 + (y - p.q) ** 2;
    let lo = Infinity, hi = -Infinity, lx = 0, ly = 0;
    const N = Math.round(p.m * 100);
    for (let i = 0; i <= N; i++) for (let j = 0; j <= N; j++) {
      const x = i / 100, y = j / 100, v = f(x, y);
      if (v < lo - 1e-12) { lo = v; lx = x; ly = y; }
      if (v > hi) hi = v;
    }
    return [lo < 1e-12 ? 0 : 1, lx, ly, lo, hi];
  },
  useIt: {
    say: ["Project 4, Best spot in the park, opens. Draw a park fence on Two lakes and find its lowest point, for a pond.",
      "Then find the lowest point on the road y = 1/2 from lesson 15. The build gains the fence."],
    project: "mv-park",
  },
  deeper: [
    "The Karush–Kuhn–Tucker conditions: ∇f = −Σμᵢ∇gᵢ, μᵢ ≥ 0, and μᵢ(gᵢ − cᵢ) = 0 (complementary slackness).",
    "Projected gradient descent: step downhill, then step back inside the fence.",
    "When f and the fences are all linear, the best point is a corner of the region: linear programming and the simplex method (cs).",
  ],
};

interface P17 { ys: number[] }
const fit = (xs: number[], ys: number[]) => {
  const n = xs.length, Sx = xs.reduce((a, b) => a + b, 0), Sy = ys.reduce((a, b) => a + b, 0);
  const Sxx = xs.reduce((a, x) => a + x * x, 0), Sxy = xs.reduce((a, x, i) => a + x * ys[i]!, 0);
  const m = (n * Sxy - Sx * Sy) / (n * Sxx - Sx * Sx);
  return { m, b: (Sy - m * Sx) / n, Sx, Sy, Sxx, Sxy };
};
const XS17 = (p: P17) => (p.ys.length === 3 ? [-1, 0, 1] : [0, 1, 2, 3]);

export const mv17: B2Lesson<P17> = {
  id: "b2-mv-17", track: "mv", unit: 5, title: "Least squares: the best line is the bottom of a bowl",
  youCan: "fit a line to data by finding the lowest point of its error.",
  needs: ["st-lsrl", "b2-mv-13", "b2-la-11"],
  tools: ["bowl", "calc"],
  play: { scene: "bowl", props: { pts: "-1,1;0,2;1,6" },
    say: "Drag the data points on the scatter plot. Beside it, the total squared error E(m, b) is a bowl over the (m, b) plane, and your line y = mx + b is a ball on it. Drag the line's two handles and the ball moves." },
  guess: { scene: "bowl", props: { pts: "-1,1;0,2;1,6", quiet: true }, kind: "point", answer: [2.5, 3], near: 0.6, start: [0, 1],
    ask: "Drag the line to where you think it fits (−1, 1), (0, 2) and (1, 6) best.",
    reveal: "The ball rolls to the bowl's bottom and the best line snaps in: y = (5/2)x + 3." },
  nameIt: {
    say: [
      "The best line makes the total squared miss as small as possible.",
      "E is a bowl in m and b, so set both slopes to 0. That gives two linear equations, the normal equations.",
    ],
    formula: ["E(m, b) = Σ(yᵢ − mxᵢ − b)²", "m Σx² + b Σx = Σxy", "m Σx + b n = Σy"],
  },
  workIt: {
    reference: { ys: [1, 2, 6] },
    generate(rng, i) {
      return { ys: Array.from({ length: i < 3 ? 3 : 4 }, () => rng.int(0, 9)) };
    },
    show: p => `Fit y = mx + b to the points ${XS17(p).map((x, i) => pt(x, p.ys[i]!)).join(", ")}. Answers as fractions.`,
    steps(p) {
      const xs = XS17(p), F = fit(xs, p.ys), y0 = p.ys[0]!, yl = p.ys[p.ys.length - 1]!;
      const two = { m: (yl - y0) / (xs[xs.length - 1]! - xs[0]!), b: p.ys.length === 3 ? (y0 + yl) / 2 : y0 };
      const mStep = fracStep("m", "m", F.m, { hint: p.ys.length === 3 ? "With Σx = 0 the equations split: m = Σxy/Σx²." : `m = (4Σxy − 6Σy)/20.`,
        slips: [slip("swapped", F.b, "m is the slope, the number in front of x. b is where the line crosses x = 0."),
          slip("two points", two.m, "The best line uses all the points, not just the first and last.")] });
      const bStep = fracStep("b", "b", F.b, { hint: p.ys.length === 3 ? "With Σx = 0, b is the mean of the y-values: Σy/3." : `b = (Σy − 6m)/4.`,
        slips: [slip("swapped", F.m, "m is the slope, the number in front of x. b is where the line crosses x = 0."),
          slip("two points", two.b, p.ys.length === 3 ? `The best line uses all the points. With Σx = 0, b is the mean of the y-values, ${fr(F.b)}.` : "The best line uses all the points, not just the first and last.")] });
      if (p.ys.length === 3) return [
        multiStep("sums", "Σx, Σx², Σy, Σxy", [F.Sx, F.Sxx, F.Sy, F.Sxy], "whole", { boxes: ["Σx", "Σx²", "Σy", "Σxy"], hint: "Add the x's, their squares, the y's, and each x times its y.",
          slips: [slip("squared the sum", [F.Sx, F.Sx * F.Sx, F.Sy, F.Sxy], "Square each x first, then add: 1 + 0 + 1 = 2.")] }),
        mStep, bStep,
      ];
      return [
        multiStep("sums", "Σy and Σxy", [F.Sy, F.Sxy], "whole", { boxes: ["Σy", "Σxy"], hint: "Here Σx = 6 and Σx² = 14 already. Add the y's, and each x times its y." }),
        mStep, bStep,
      ];
    },
    scene: p => ({ scene: "bowl", props: { pts: XS17(p).map((x, i) => `${x},${p.ys[i]}`).join(";") } }),
  },
  oracle: p => {
    const xs = XS17(p), n = xs.length, Sx = xs.reduce((a, b) => a + b, 0), Sy = p.ys.reduce((a, b) => a + b, 0), Sxx = xs.reduce((a, x) => a + x * x, 0);
    const Sxy = xs.reduce((a, x, i) => a + x * p.ys[i]!, 0), m = (n * Sxy - Sx * Sy) / (n * Sxx - Sx * Sx), b = (Sy - m * Sx) / n;
    return n === 3 ? [Sx, Sxx, Sy, Sxy, m, b] : [Sy, Sxy, m, b];
  },
  useIt: {
    say: ["Measure Two lakes' height at 4 spots along the road y = 1/2 and fit a straight-line trend.",
      "The error bowl in the build shows that fitting and finding the lowest point are the same job (b2-ai-02)."],
    scene: { scene: "bowl", props: { fn: "land" } },
  },
  deeper: [
    "In matrix form AᵀAw = Aᵀy: the fit is the projection of y onto the column space of A (b2-la-11).",
    "If the noise is Gaussian, least squares is the maximum-likelihood fit (b2-pr-09).",
    "Adding λ|w|² (ridge regression) is the Lagrange form of \"fit well, with a fence on the size of w\" (b2-mv-15).",
  ],
};

/* ================================================================ unit 6 · Hard landscapes ================================================================ */

interface P18 { kindB: boolean; a: number; b: number; c: number }
const PAIRS18: [number, number][] = [[1, 1], [1, 4], [4, 1], [2, 8], [1, 9], [4, 9]];

export const mv18: B2Lesson<P18> = {
  id: "b2-mv-18", track: "mv", unit: 6, title: "Convexity: when the lowest point is the only one",
  youCan: "tell whether a landscape has just one valley, so any low point you find is the lowest.",
  needs: ["b2-mv-13", "b2-mv-14"],
  tools: ["surface", "finder", "morph"],
  play: { scene: "multistart", props: { src: "x^2 + y^2 + 3*sin(x)", r: 3 },
    say: "Drag A and B to stretch a straight string between two points of the ground; the profile below shows whether it ever dips under. Then drop 20 balls at random and run descent on each." },
  guess: { scene: "multistart", props: { src: "x^2 + y^2 + 3*sin(x)", r: 3, quiet: true }, kind: "choice", options: ["All 20 meet at one spot", "They split up"], answer: 0,
    ask: "On f = x² + y² + 3 sin x, do all 20 balls end at the same spot, or do they split?",
    revealProps: { auto: true },
    reveal: "They all meet: there's one valley, though f isn't convex everywhere (near x = 1.6 it curves down along x). On Two lakes they split into two valleys." },
  nameIt: {
    say: [
      "A landscape is convex if the string between any two points never goes below the ground. Then it has no false bottoms: every low point is the lowest.",
      "For smooth f, convex means the ground never curves down in any direction, at any point.",
    ],
    formula: ["f(tA + (1 − t)B) ≤ t f(A) + (1 − t) f(B), 0 ≤ t ≤ 1", "convex in 2D: f_xx ≥ 0, f_yy ≥ 0, f_xx f_yy − f_xy² ≥ 0 everywhere"],
  },
  workIt: {
    reference: { kindB: false, a: 2, b: 3, c: 1 },
    generate(rng, i) {
      if (i < 3) return { kindB: false, a: 1, b: rng.int(0, 3), c: 1 };
      if (rng.next() < 0.3) { const [a, c] = rng.pick(PAIRS18); return { kindB: true, a: a!, b: 0, c: c! }; }
      return { kindB: false, a: rng.pick([1, 2, 4, 8, 9]), b: rng.int(-6, 6), c: rng.pick([1, 2, 4, 8, 9]) };
    },
    show: p => p.kindB ? `f(x, y) = ${terms([[p.a, "x²"], [1, "bxy"], [p.c, "y²"]])}, with b ≥ 0. What is the largest b that keeps f convex?`
      : `f(x, y) = ${quadStr(p.a, p.b, p.c)}. Is it convex?`,
    steps(p) {
      if (p.kindB) {
        const B = 2 * Math.sqrt(p.a * p.c);
        return [wholeStep("b", "Largest b", B, { hint: `Convex needs 4ac − b² ≥ 0: b² ≤ ${4 * p.a * p.c}.`,
          slips: [slip("root of ac", Math.sqrt(p.a * p.c), `Convex needs 4ac − b² ≥ 0, so b ≤ 2√(ac) = ${B}.`)] })];
      }
      const D = 4 * p.a * p.c - p.b * p.b;
      return [
        multiStep("h", "f_xx, f_yy, f_xy", [2 * p.a, 2 * p.c, p.b], "whole", { boxes: ["f_xx", "f_yy", "f_xy"], hint: "f_xx = 2a, f_yy = 2c, f_xy = b." }),
        wholeStep("D", "D", D, { hint: "f_xx f_yy − f_xy².", slips: [slip("added", 4 * p.a * p.c + p.b * p.b, "The cross term is subtracted: D = f_xx f_yy − f_xy².")] }),
        tapStep("cv", "Convex?", ["Convex", "Not convex"], D >= 0 ? 0 : 1, { hint: "Both curvatures are positive here, so it comes down to the sign of D.",
          slips: [D < 0 && slip("slices only", 0, "Both slices curving up isn't enough. D < 0 means a diagonal slice curves down."),
            D === 0 && slip("D = 0", 1, "D = 0 is allowed. The string can lie flat along the surface; that's still convex.")] }),
      ];
    },
    scene: p => ({ scene: "morph", props: { a: p.a, b: p.kindB ? 2 * Math.sqrt(p.a * p.c) : p.b, c: p.c } }),
  },
  oracle: p => {
    if (p.kindB) return [2 * Math.sqrt(p.a * p.c)];
    const [l1] = eig2(2 * p.a, p.b, 2 * p.c);
    return [2 * p.a, 2 * p.c, p.b, 4 * p.a * p.c - p.b * p.b, l1 >= -1e-9 ? 0 : 1];
  },
  useIt: {
    say: ["Run the convexity check on Two lakes: it fails between the two valleys, where f_xx = 12x² − 4 < 0 for |x| < 1/√3.",
      "The build gains a \"one valley?\" badge, and knows that on Two lakes it needs more than one ball."],
    scene: { scene: "multistart", props: { fn: "land", auto: true } },
  },
  deeper: [
    "Convex sets, and the rules that keep convexity: sums, maxima, and composing with a linear map.",
    "Jensen's inequality f(E[X]) ≤ E[f(X)] (pr) proves that cross-entropy is at least entropy (Gibbs' inequality, b2-in-09).",
    "Strong convexity (every direction curving up by at least μ) gives one minimum and fast descent. Neural network losses are not convex, yet descent works well in practice: an open question with partial answers (overparameterization, b2-ai-09).",
  ],
};

interface P19 { a: number; b: number }
const steps19 = (a: number, b: number) => Math.ceil(Math.log(1000) / Math.log((b + a) / (b - a)) - 1e-12);

export const mv19: B2Lesson<P19> = {
  id: "b2-mv-19", track: "mv", unit: 6, title: "Narrow valleys: zig-zags, momentum and Newton",
  youCan: "explain why descent crawls in a narrow valley and pick the step that helps most.",
  needs: ["b2-mv-14", "b2-mv-18"],
  tools: ["finder", "surface"],
  play: { scene: "race", props: { a: 1, b: 3 },
    say: "A valley f = ax² + by² is stretched by dragging b. Descent runs at the best fixed step, η = 1/(a + b), and zig-zags across the narrow walls; the counter shows the steps until the error has shrunk 1,000 times. Toggle momentum or a Newton step and race them." },
  guess: { scene: "race", props: { a: 1, b: 30, quiet: true }, kind: "choice", options: ["About the same", "About 10 times as many", "About 100 times as many"], answer: 1,
    ask: "With a = 1 and b = 3 at the best step, the error shrinks 1,000 times in 10 steps. Stretch to b = 30. How many steps now?",
    reveal: "104 steps: about 10 times as many. κ went from 3 to 30, and the cost grows roughly like κ. Momentum needs only about √κ times as many." },
  nameIt: {
    say: [
      "The condition number κ is the steepest curvature divided by the gentlest. The best fixed step can only shrink the error by (κ − 1)/(κ + 1) each time, so a narrow valley (big κ) is slow.",
      "Momentum cuts the cost to about √κ; a Newton step uses the Hessian and lands on a bowl's bottom in one step.",
    ],
    formula: ["κ = λ_max(H) / λ_min(H)", "best η = 2/(λ_max + λ_min), shrink factor (κ − 1)/(κ + 1)", "Newton: x ← x − H⁻¹∇f"],
  },
  workIt: {
    reference: { a: 1, b: 3 },
    generate(rng, i) {
      if (i < 3) { const [a, b] = rng.pick([[1, 2], [1, 3], [2, 3]] as [number, number][]); return { a: a!, b: b! }; }
      const a = rng.int(1, 3);
      return { a, b: rng.int(a + 1, 10 * a) };
    },
    show: p => `f(x, y) = ${terms([[p.a, "x²"], [p.b, "y²"]])}. Answers as fractions; the step count as a whole number.`,
    steps(p) {
      const { a, b } = p, k = (b - a) / (b + a), div = 1000 * k;
      return [
        fracStep("kappa", "κ", b / a, { hint: `The curvatures are 2a = ${2 * a} and 2b = ${2 * b}. Steep over gentle.`,
          slips: [slip("upside down", a / b, "κ is the steep curvature over the gentle one, so it's at least 1.")] }),
        fracStep("eta", "Best step size η", 1 / (a + b), { hint: `2/(2a + 2b) = 2/${2 * a + 2 * b}.`,
          slips: [slip("1 over b", 1 / b, "With η = 1/b the steep direction's factor is 1 − 2 = −1, so it bounces forever. The best fixed step balances both directions: 1/(a + b).")] }),
        fracStep("k", "Shrink factor per step", k, { hint: "(b − a)/(b + a)." }),
        wholeStep("n", "Steps to shrink the error 1,000 times", steps19(a, b), { hint: `The smallest k with (${fr(k)})ᵏ ≤ 1/1000. The calculator helps.`,
          slips: [Number.isInteger(div) && slip("divided", div, `The error is multiplied by ${fr(k)} each step, so solve (${fr(k)})ᵏ ≤ 1/1000: k = ${steps19(a, b)}.`)] }),
        wholeStep("newton", "Newton steps to reach the bottom of this bowl", 1, { hint: "On a bowl, Newton's step is exact." }),
      ];
    },
    scene: p => ({ scene: "race", props: { a: p.a, b: p.b } }),
  },
  oracle: p => {
    const k = (p.b - p.a) / (p.b + p.a);
    let e = 1, n = 0;
    while (e > 1 / 1000) { e *= k; n++; }
    return [p.b / p.a, 2 / (2 * p.a + 2 * p.b), k, n, 1];
  },
  useIt: {
    say: ["Two lakes' valleys are round enough for plain descent. Stretch y (y² → 25y²) and watch it zig-zag.",
      "Turn on momentum and race it. The build gains the narrow-valley fixes."],
    scene: { scene: "race", props: { fn: "land" } },
  },
  deeper: [
    "Heavy-ball momentum (and Nesterov's, nearly) reaches a rate of about (√κ − 1)/(√κ + 1), the best possible for first-order methods on quadratics.",
    "Conjugate gradient solves an n-dimensional quadratic in at most n steps. Newton's method converges quadratically near a minimum (digits double each step); quasi-Newton (BFGS) builds H from gradients.",
    "Preconditioning rescales the landscape to bring κ near 1; Adam is a diagonal preconditioner (b2-ai-14).",
  ],
};

interface P20 { s: number; m: number; x0: number; y0: number; T: number }

export const mv20: B2Lesson<P20> = {
  id: "b2-mv-20", track: "mv", unit: 6, title: "Many valleys: false bottoms, passes and noise",
  youCan: "find the lowest point on a landscape with several valleys, and say how sure you are.",
  needs: ["b2-mv-13", "b2-mv-18", "b2-mv-19"],
  tools: ["finder", "surface"],
  play: { scene: "anneal", props: { fn: "land" },
    say: "On Two lakes, drop one ball: it stops in whichever valley it starts above. Turn up the temperature and the ball jitters, sometimes hopping the pass; cool it and it settles. Or drop many balls and keep the lowest." },
  guess: { scene: "anneal", props: { fn: "land", quiet: true }, kind: "choice", options: ["About 1/4", "About 1/2", "About 3/4"], answer: 1,
    ask: "On Two lakes, drop a ball at a random spot of the plot −2 ≤ x ≤ 2, −1 ≤ y ≤ 1. What's the chance it rolls into the lower, left valley?",
    revealProps: { drops: true },
    reveal: "About 1/2, just over. The pass at x ≈ 0.06 sits just right of center, so the left valley drains about 2.06/4 ≈ 0.52 of the plot." },
  nameIt: {
    say: [
      "Descent finds a bottom, not the bottom. A pass between two valleys is a barrier.",
      "Restarting from many spots, or adding noise that lets the ball climb now and then, gives it a chance to find a lower valley. Cooling slowly settles into the deepest one: simulated annealing.",
    ],
    formula: ["an uphill hop of height Δ is kept with chance e^(−Δ/T)", "T is the temperature"],
  },
  workIt: {
    reference: { s: 1, m: 1, x0: 2, y0: 1, T: 1 },
    generate(rng, i) {
      const s = i < 3 ? 1 : rng.pick([1, 2]), s4 = s ** 4;
      return { s, m: rng.int(1, 3), x0: rng.int(-3, 3), y0: rng.int(-2, 2), T: rng.pick(s === 2 ? [s4 / 2, s4, 2 * s4, 4] : [s4 / 2, s4, 2 * s4]) };
    },
    show: p => `f(x, y) = ${terms([[1, "x⁴"], [-2 * p.s * p.s, "x²"], [p.m, "y²"]])}. Start at **${pt(p.x0, p.y0)}**, temperature **T = ${fr(p.T)}**. The chance to 3 decimal places.`,
    steps(p) {
      const s4 = p.s ** 4, ch = Math.round(Math.exp(-s4 / p.T) * 1000) / 1000;
      return [
        wholeStep("s", "Flat spots on the x-axis are at 0 and ±", p.s, { hint: `f_x = 4x³ − ${4 * p.s * p.s}x = 4x(x² − ${p.s * p.s}).` }),
        wholeStep("lo", "Height at the bottoms (±s, 0)", -s4, { hint: `${s4} − ${2 * s4}.` }),
        wholeStep("bar", "Height of the pass (0, 0) above a bottom", s4, { hint: `The pass is at height 0; the bottoms at −${s4}.`,
          slips: [slip("s squared", p.s * p.s, `The bottoms are at height ${s4} − ${2 * s4} = −${s4}, so the pass is ${s4} above them.`)] }),
        tapStep("stop", `Where descent from ${pt(p.x0, p.y0)} stops`, ["The left bottom", "The right bottom", "The pass"], p.x0 < 0 ? 0 : p.x0 > 0 ? 1 : 2, { hint: "Which side of x = 0 does it start on?",
          slips: [p.x0 === 0 && slip("a bottom", 0, "On the line x = 0 the gradient has no sideways part, so descent slides straight to the pass and stops there. Any tiny nudge sends it off."),
            p.x0 === 0 && slip("a bottom", 1, "On the line x = 0 the gradient has no sideways part, so descent slides straight to the pass and stops there. Any tiny nudge sends it off.")] }),
        numStep("ch", "Chance a hop over the pass is kept", ch, 3, { hint: `e^(−${s4}/${fr(p.T)}).`,
          slips: [slip("plus sign", Math.round(Math.exp(s4 / p.T) * 1000) / 1000, "A chance can't be more than 1. Uphill hops get rarer as they get bigger: e^(−Δ/T).")] }),
      ];
    },
    scene: p => ({ scene: "anneal", props: { src: `x^4 - ${2 * p.s * p.s}*x^2 + ${p.m}*y^2`, r: p.s + 1.5, sx: p.x0, sy: p.y0, temp: p.T } }),
  },
  oracle: p => [p.s, -(p.s ** 4), p.s ** 4, p.x0 < 0 ? 0 : p.x0 > 0 ? 1 : 2, Math.round(Math.exp(-(p.s ** 4) / p.T) * 1000) / 1000],
  useIt: {
    say: ["The valley finder, the build, is complete. On Two lakes it runs 20 restarts plus a slow cool, finds the lowest point at about (−1.03, 0) with height about −0.254, and confirms it as a pit with the Hessian test.",
      "It reports how many restarts agreed, honors any fence, and fills the lake that would form there. Try it on your own landscape."],
    project: "mv-valley",
  },
  deeper: [
    "Stochastic gradient descent uses a noisy gradient from a random batch; its noise has variance about 1/(batch size) and acts like a temperature (b2-pr-01, b2-ai-14).",
    "In the limit, noisy descent is Langevin dynamics, whose long-run spread of positions is the Boltzmann distribution ∝ e^(−f/T).",
    "In high dimensions most flat spots are passes, not false bottoms, and noise helps escape them. Finding the global lowest point of a general landscape is NP-hard (b2-cs-12), which is why guarantees come from convexity or from structure.",
  ],
};

export const LESSONS_B = [mv11, mv12, mv13, mv14, mv15, mv16, mv17, mv18, mv19, mv20];
