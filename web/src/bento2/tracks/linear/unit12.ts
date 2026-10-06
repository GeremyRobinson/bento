// Linear algebra, units 1 and 2 (b2-la-01 to b2-la-08), built from curriculum/specs/bento2/linear-algebra.md block by
// block. Every problem is made of whole numbers, and every answer is computed exactly from them.
import type { B2Lesson, B2Step, SceneRef } from "../../model";
import { fracStep, multiStep, slip, tapStep, wholeStep } from "../../make";
import { add, det, inverse, mul, scale, transpose } from "../../tools/matrix";
import type { Rng } from "../../../curriculum/generators/rng";
import { apply2, col, det2, det3, dot, kv, lin, mat, mm, norm, same, sn, times, tr, vec, type Vec } from "./maths";

export const S = {
  play: "la-playground", vec: "la-vectors", space: "la-space", eig: "la-eigen", comp: "la-compressor", flow: "la-flow", res: "la-residual", cloud: "la-cloud",
} as const;
export const XYZ = ["x", "y", "z"];
export const CELLS = ["top left", "top right", "bottom left", "bottom right"];
/** a whole number in lo…hi that isn't 0 */
export const nz = (rng: Rng, lo: number, hi: number) => { let x = 0; while (!x) x = rng.int(lo, hi); return x; };
export const ints = (rng: Rng, n: number, lo: number, hi: number) => Array.from({ length: n }, () => rng.int(lo, hi));
export const flat = (A: number[][]) => A.flat();
const isZero = (v: Vec) => v.every(x => x === 0);

/* ------------------------------------------------------------------ unit 1 · arrows ------------------------------------------------------------------ */

interface P01 { u: Vec; v: Vec; a: number; b: number }

export const la01: B2Lesson<P01> = {
  id: "b2-la-01", track: "la", unit: 1, title: "Arrows you can add and stretch",
  youCan: "combine arrows by scaling and adding them, and read a picture as a list of numbers.",
  needs: ["g12-vecmag"],
  tools: [S.vec, "matrix"],
  play: { scene: S.vec, props: { mode: "sum", ux: 3, uy: 1, vx: 1, vy: 2, a: 1, b: 1 },
    say: "Two arrows, u and v, with sliders a and b. Drag the arrows' tips or the sliders: the arrow a u + b v redraws tip to tail, with its numbers beside it." },
  guess: { scene: S.vec, props: { mode: "sum", ux: 3, uy: 1, vx: 1, vy: 2, a: 1, b: 1, hide: true }, kind: "point", answer: [4, 3], near: 0.75, start: [-3, 3],
    ask: "u = (3, 1) and v = (1, 2). Drag the marker to where you think u + v ends.",
    revealProps: { parallelogram: true },
    reveal: "v slides to the tip of u, and the sum ends at (4, 3): 3 + 1 across and 1 + 2 up. The two ways round make a parallelogram." },
  nameIt: {
    say: [
      "A vector is a list of numbers, drawn as an arrow.",
      "Scaling multiplies every entry. Adding works entry by entry, which is the same as putting the arrows tip to tail.",
    ],
    formula: ["a·(u₁, u₂) + b·(v₁, v₂) = (a u₁ + b v₁, a u₂ + b v₂)"],
  },
  workIt: {
    reference: { u: [3, -1], v: [1, 2], a: 2, b: -1 },
    generate(rng, i) {
      if (i < 3) {
        let u: Vec = [0, 0], v: Vec = [0, 0];
        while (isZero(u) || isZero(v)) { u = ints(rng, 2, 0, 4); v = ints(rng, 2, 0, 4); }
        return { u, v, a: rng.pick([1, 2]), b: rng.pick([1, 2]) };
      }
      const n = i >= 5 ? 3 : 2;
      let u: Vec = [], v: Vec = [];
      do { u = ints(rng, n, -5, 5); v = ints(rng, n, -5, 5); } while (isZero(u) || isZero(v));
      return { u, v, a: nz(rng, -3, 3), b: nz(rng, -3, 3) };
    },
    show: p => `u = **${vec(p.u)}** and v = **${vec(p.v)}**. Find **${lin([[p.a, "u"], [p.b, "v"]])}**.`,
    steps(p) {
      const n = p.u.length, box = XYZ.slice(0, n);
      const au = p.u.map(x => p.a * x), bv = p.v.map(x => p.b * x), s = au.map((x, i) => x + bv[i]!);
      const scaled = (k: number, w: Vec, name: string) => [
        slip("scaled one entry", [k * w[0]!, ...w.slice(1)], "Scaling stretches the whole arrow: every entry gets multiplied."),
        k < 0 && slip("negative scale", [k * w[0]!, ...w.slice(1).map(x => -k * x)], `A negative scale flips the whole arrow, so every entry of ${name} changes sign.`),
      ];
      const mixed = n === 2 ? [au[0]! + bv[1]!, au[1]! + bv[0]!] : [au[0]! + bv[1]!, au[1]! + bv[2]!, au[2]! + bv[0]!];
      return [
        multiStep("au", lin([[p.a, "u"]]), au, "whole", { boxes: box, hint: `Multiply every entry of u by ${sn(p.a)}.`, slips: scaled(p.a, p.u, "u") }),
        multiStep("bv", lin([[p.b, "v"]]), bv, "whole", { boxes: box, hint: `Multiply every entry of v by ${sn(p.b)}.`, slips: scaled(p.b, p.v, "v") }),
        multiStep("sum", lin([[p.a, "u"], [p.b, "v"]]), s, "whole", { boxes: box, hint: `Add entry by entry: ${vec(au)} + ${vec(bv)}.`,
          slips: [slip("mixed the entries", mixed, "Add first entry to first entry and second to second. The x part and the y part never mix.")] }),
      ];
    },
    scene: (p): SceneRef => p.u.length === 2 ? { scene: S.vec, props: { mode: "sum", ux: p.u[0]!, uy: p.u[1]!, vx: p.v[0]!, vy: p.v[1]!, a: p.a, b: p.b, hide: true } } : { scene: S.vec, props: { mode: "sum" } },
  },
  // with a matrix library: the columns u and v times the column (a, b)
  oracle: p => {
    const U = p.u.map(x => [x]), V = p.v.map(x => [x]);
    const both = mul(p.u.map((x, i) => [x, p.v[i]!]), [[p.a], [p.b]]);
    return [...scale(U, p.a).flat(), ...scale(V, p.b).flat(), ...both.flat()];
  },
  useIt: {
    say: [
      "Draw an 8 × 8 picture with brightness 0 to 9 by dragging across the grid. Each row is a vector of 8 numbers.",
      "The new row ½(r₃ + r₄) is the average of rows 3 and 4: a mix of two arrows, made entry by entry. Save the picture as `img`: the build starts here.",
    ],
    scene: { scene: S.comp, props: { mode: "grid", save: true } },
  },
  deeper: [
    "A vector space is anything you can add and scale by eight rules (such as u + v = v + u and a(u + v) = a u + a v). Those rules are all the later lessons use, so \"vector\" can mean much more than an arrow.",
    "Polynomials, functions and whole pictures are vectors too: an 8 × 8 picture is one point in a 64-dimensional space.",
    "Vectors may have complex entries. Quantum states are exactly that (track `qu`).",
  ],
};

interface P02 { u: Vec; v: Vec; a: number; b: number }
const sysText = (row1: [number, number], row2: [number, number], r1: number, r2: number) =>
  `${lin([[row1[0], "a"], [row1[1], "b"]])} = ${sn(r1)} and ${lin([[row2[0], "a"], [row2[1], "b"]])} = ${sn(r2)}`;
function systems(p: P02) {
  const w = [p.a * p.u[0]! + p.b * p.v[0]!, p.a * p.u[1]! + p.b * p.v[1]!];
  const right = sysText([p.u[0]!, p.v[0]!], [p.u[1]!, p.v[1]!], w[0]!, w[1]!);
  const cands = [
    { t: right, kind: "" },
    { t: sysText([p.u[0]!, p.u[1]!], [p.v[0]!, p.v[1]!], w[0]!, w[1]!), kind: "rows for columns" },
    { t: sysText([p.u[0]!, p.v[0]!], [p.u[1]!, p.v[1]!], w[1]!, w[0]!), kind: "swapped right sides" },
    { t: sysText([p.v[0]!, p.u[0]!], [p.v[1]!, p.u[1]!], w[0]!, w[1]!), kind: "a and b swapped" },
  ];
  const seen = new Set<string>(), list = cands.filter(c => !seen.has(c.t) && !!seen.add(c.t)).slice(0, 3);
  const shift = (Math.abs(p.a) + Math.abs(p.b)) % list.length;
  const choices = [...list.slice(shift), ...list.slice(0, shift)];
  return { w, choices, right: choices.findIndex(c => c.kind === "") };
}

export const la02: B2Lesson<P02> = {
  id: "b2-la-02", track: "la", unit: 1, title: "Span: everywhere two arrows can reach",
  youCan: "find the mix of two arrows that reaches a target, and tell when two arrows only reach a line.",
  needs: ["b2-la-01", "g9-elim"],
  tools: [S.vec],
  play: { scene: S.vec, props: { mode: "span", ux: 3, uy: 1, vx: 1, vy: 2, noTarget: true },
    say: "The shaded patch is every mix a u + b v with a and b from −3 to 3. Drag v toward u's line: when the two line up, the patch collapses to a single line." },
  guess: { scene: S.vec, props: { mode: "span", ux: 2, uy: 1, vx: 1, vy: 1, wx: 5, wy: 3, hide: true }, kind: "choice",
    options: ["a = 1, b = 3", "a = 2, b = 1", "a = 3, b = −1"], answer: 1,
    ask: "u = (2, 1), v = (1, 1) and the target w = (5, 3). Which mix a u + b v reaches w?",
    revealProps: { skew: true },
    reveal: "Redraw the plane as a grid of u steps and v steps: w sits 2 steps along u and 1 along v. Check: 2·(2, 1) + (1, 1) = (5, 3)." },
  nameIt: {
    say: [
      "The span is every arrow you can make as a u + b v. Two arrows that don't line up span the whole plane.",
      "Reaching a target w means solving two equations at once, one for each entry.",
    ],
    formula: ["a u + b v = w", "when u₁v₂ − u₂v₁ ≠ 0: a = (w₁v₂ − w₂v₁) / (u₁v₂ − u₂v₁), b = (u₁w₂ − u₂w₁) / (u₁v₂ − u₂v₁)"],
  },
  workIt: {
    reference: { u: [2, 1], v: [1, 1], a: 2, b: 1 },
    generate(rng, i) {
      for (;;) {
        if (i < 3) {
          const u = ints(rng, 2, 0, 3), v = ints(rng, 2, 0, 3);
          if (Math.abs(u[0]! * v[1]! - u[1]! * v[0]!) !== 1) continue;
          return { u, v, a: rng.int(1, 3), b: rng.int(1, 3) };
        }
        const u = ints(rng, 2, -4, 4), v = ints(rng, 2, -4, 4);
        if (u[0]! * v[1]! - u[1]! * v[0]! === 0) continue;
        const a = rng.int(-4, 4), b = rng.int(-4, 4);
        if (!a && !b) continue;
        return { u, v, a, b };
      }
    },
    show: p => { const { w } = systems(p); return `u = **${vec(p.u)}**, v = **${vec(p.v)}**, w = **${vec(w)}**. Find a and b with a u + b v = w.`; },
    steps(p) {
      const { w, choices, right } = systems(p), [u1, u2] = p.u as [number, number], [v1, v2] = p.v as [number, number];
      const D = u1 * v2 - u2 * v1;
      const tapSlips = choices.map((c, i) => c.kind === "rows for columns" ? slip(c.kind, i, `Each equation reads one entry. The first entries give ${lin([[u1, "a"], [v1, "b"]])} = ${sn(w[0]!)}.`)
        : c.kind === "swapped right sides" ? slip(c.kind, i, `Each equation keeps its own entry of w: the first entries give ${lin([[u1, "a"], [v1, "b"]])} = ${sn(w[0]!)}.`)
          : c.kind === "a and b swapped" ? slip(c.kind, i, "a counts copies of u, so a goes with u's entries and b with v's.") : null);
      return [
        tapStep("sys", "The two equations", choices.map(c => c.t), right, { hint: "First entries make the first equation, second entries the second.", slips: tapSlips }),
        wholeStep("a", "a", p.a, { hint: `Eliminate b. Cramer's rule gives a = (${times(w[0]!, v2)} − ${times(w[1]!, v1)}) / ${D < 0 ? `(${sn(D)})` : sn(D)}.`,
          slips: [
            u1 !== 0 && slip("one equation only", w[0]! / u1, `Both arrows move you sideways, so the first equation has a and b in it. Solve the two together.`),
            slip("swapped a and b", p.b, `a counts copies of u and b counts copies of v. Check: ${lin([[p.a, vec(p.u)], [p.b, vec(p.v)]]).replace(/(\d)\(/g, "$1·(")} = ${vec(w)}.`),
          ] }),
        wholeStep("b", "b", p.b, { hint: v2 !== 0 ? `Put a = ${sn(p.a)} into the second equation: ${lin([[u2 * p.a, ""], [v2, "b"]])} = ${sn(w[1]!)}.` : `Put a = ${sn(p.a)} into the first equation: ${lin([[u1 * p.a, ""], [v1, "b"]])} = ${sn(w[0]!)}.`,
          slips: [
            slip("swapped a and b", p.a, "a counts copies of u and b counts copies of v, so b is the second number."),
            slip("sign slip", (u1 * w[1]! + u2 * w[0]!) / D, "Subtract the whole equation, right side too."),
          ] }),
      ];
    },
    scene: p => ({ scene: S.vec, props: { mode: "span", ux: p.u[0]!, uy: p.u[1]!, vx: p.v[0]!, vy: p.v[1]!, wx: systems(p).w[0]!, wy: systems(p).w[1]!, hide: true } }),
  },
  // Cramer's rule from the target's entries alone
  oracle: p => {
    const w = [p.a * p.u[0]! + p.b * p.v[0]!, p.a * p.u[1]! + p.b * p.v[1]!];
    const D = p.u[0]! * p.v[1]! - p.u[1]! * p.v[0]!;
    return [systems(p).right, (w[0]! * p.v[1]! - w[1]! * p.v[0]!) / D, (p.u[0]! * w[1]! - p.u[1]! * w[0]!) / D];
  },
  useIt: {
    say: [
      "Two pattern rows of 4 pixels: stripes p = (1, 0, 1, 0) and a ramp q = (0, 1, 2, 3). A row of your picture is r = (2, 1, 4, 3).",
      "The mix 2p + q rebuilds it: two numbers rebuild four. That is the whole idea of the build, in one row.",
    ],
    scene: { scene: S.vec, props: { mode: "span", ux: 2, uy: 1, vx: 1, vy: 1, wx: 5, wy: 3, skew: true } },
  },
  deeper: [
    "A span is a subspace: adding or scaling arrows in it never leaves it. In n dimensions the span of k arrows is a flat space through 0 of dimension at most k.",
    "Lines and planes that miss the origin are affine, not subspaces: adding two of their points can land off them.",
    "The determinant u₁v₂ − u₂v₁ in the formula is a preview of b2-la-07: it is the area of the parallelogram u and v make.",
  ],
};

interface P03 { u: Vec; w: Vec }
const ANGLES = ["acute", "right", "obtuse"];

export const la03: B2Lesson<P03> = {
  id: "b2-la-03", track: "la", unit: 1, title: "Dot product, angle and shadow",
  youCan: "measure how alike two arrows are and drop one arrow's shadow onto another.",
  needs: ["b2-la-01", "g12-dot"],
  tools: [S.vec],
  play: { scene: S.vec, props: { mode: "shadow", ux: 3, uy: 1, wx: 2, wy: 4 },
    say: "Drag w around while u stays put. Its shadow on u's line moves with it, and the dot product and the angle update. At 90° the shadow shrinks to the origin and the dot product reads 0." },
  guess: { scene: S.vec, props: { mode: "shadow", ux: 2, uy: 1, wx: 3, wy: 4, hide: true }, kind: "point", answer: [4, 2], near: 0.6, start: [1, 0.5],
    ask: "u = (2, 1) and w = (3, 4). Slide the marker along u's line to where you think w's shadow lands.",
    revealProps: {},
    reveal: "Drop a perpendicular from w's tip: it lands at (4, 2), which is 2u. The multiplier is u·w / u·u = 10/5." },
  nameIt: {
    say: [
      "The dot product multiplies matching entries and adds. It is positive when the arrows point roughly the same way and zero when they are perpendicular.",
      "The shadow of w on u is a multiple of u.",
    ],
    formula: ["u·w = u₁w₁ + u₂w₂ = |u||w| cos θ", "shadow = (u·w / u·u) u"],
  },
  workIt: {
    reference: { u: [2, 1], w: [3, 4] },
    generate(rng, i) {
      for (;;) {
        if (i < 3) {
          const u = ints(rng, 2, 0, 3);
          if (isZero(u)) continue;
          const k = rng.int(1, 2), m = rng.int(-1, 1), w = [k * u[0]! - m * u[1]!, k * u[1]! + m * u[0]!];
          if (w.some(x => Math.abs(x) > 6) || isZero(w)) continue;
          return { u, w };
        }
        const u = ints(rng, 2, -4, 4);
        if (isZero(u)) continue;
        if (rng.next() < 0.17) {
          const m = rng.pick([-2, -1, 1, 2]), w = [-m * u[1]!, m * u[0]!];
          if (w.every(x => Math.abs(x) <= 6)) return { u, w };
          continue;
        }
        const w = ints(rng, 2, -6, 6);
        if (!isZero(w)) return { u, w };
      }
    },
    show: p => `u = **${vec(p.u)}** and w = **${vec(p.w)}**. Drop w's shadow onto u's line.`,
    steps(p) {
      const uw = dot(p.u, p.w), uu = dot(p.u, p.u), ww = dot(p.w, p.w), k = uw / uu;
      const right = uw > 0 ? 0 : uw === 0 ? 1 : 2;
      return [
        wholeStep("uw", "u·w", uw, { hint: `Multiply matching entries and add: ${times(p.u[0]!, p.w[0]!)} + ${times(p.u[1]!, p.w[1]!)}.` }),
        wholeStep("uu", "u·u", uu, { hint: `${times(p.u[0]!, p.u[0]!)} + ${times(p.u[1]!, p.u[1]!)}.` }),
        fracStep("k", "Multiplier u·w / u·u", k, { hint: `${sn(uw)} / ${sn(uu)}.`,
          slips: [
            slip("divided by |u|", uw / Math.sqrt(uu), "That is the shadow's length. The multiplier for u needs u·u, because u itself already has length."),
            slip("swapped roles", uw / ww, "The shadow lands on u's line, so divide by u·u, not w·w."),
          ] }),
        multiStep("sh", "Shadow", [k * p.u[0]!, k * p.u[1]!], "fraction", { boxes: ["x", "y"], hint: `The multiplier times u: ${kv(k, p.u)}.`,
          slips: [
            slip("swapped roles", [(uw / ww) * p.w[0]!, (uw / ww) * p.w[1]!], "That's u's shadow on w. The shadow lands on u's line, so it is a multiple of u."),
            slip("used w", [k * p.w[0]!, k * p.w[1]!], "The shadow is a multiple of u, not of w."),
          ] }),
        tapStep("ang", "The angle between them", ANGLES, right, { hint: "Look at the sign of u·w.",
          slips: [
            right !== 2 && slip(uw > 0 ? "obtuse when positive" : "obtuse when zero", 2, uw > 0 ? "A positive dot product means less than 90°." : "u·w = 0, so the angle is exactly 90°."),
            right !== 0 && slip(uw < 0 ? "acute when negative" : "acute when zero", 0, uw < 0 ? "A negative dot product means more than 90°." : "u·w = 0, so the angle is exactly 90°."),
            right !== 1 && slip("right when not zero", 1, `Only a dot product of 0 means 90°. Here u·w = ${sn(uw)}.`),
          ] }),
      ];
    },
    scene: p => ({ scene: S.vec, props: { mode: "shadow", ux: p.u[0]!, uy: p.u[1]!, wx: p.w[0]!, wy: p.w[1]!, hide: true } }),
  },
  // the projection matrix u uᵀ / uᵀu applied to w, and the angle from the cosine
  oracle: p => {
    const U = p.u.map(x => [x]), P = scale(mul(U, transpose(U)), 1 / mul(transpose(U), U)[0]![0]!);
    const s = mul(P, p.w.map(x => [x])).flat();
    const cos = mul([p.w], U)[0]![0]! / (norm(p.u) * norm(p.w));
    return [mul([p.u], p.w.map(x => [x]))[0]![0]!, mul([p.u], U)[0]![0]!, s[0]! / p.u[0]! || s[1]! / p.u[1]! || 0, s[0]!, s[1]!, Math.abs(cos) < 1e-12 ? 1 : cos > 0 ? 0 : 2];
  },
  useIt: {
    say: [
      "How alike are two rows of a picture? Rows r = (1, 2, 2, 0) and s = (2, 1, 2, 0) have r·s = 8 and lengths 3 and 3, so cos θ = 8/9: nearly the same direction.",
      "Rows that point the same way repeat each other, which is why pictures compress. The same \"cosine similarity\" measures how alike two words are inside an AI model (b2-ai-10).",
    ],
    scene: { scene: S.vec, props: { mode: "shadow", ux: 3, uy: 1, wx: 3, wy: 2 } },
  },
  deeper: [
    "Cauchy–Schwarz: |u·w| ≤ |u||w|. Proof: |u − t w|² ≥ 0 for every t is a quadratic in t that never goes below 0, so its discriminant 4(u·w)² − 4|u|²|w|² is at most 0.",
    "Inner products on functions, ⟨f, g⟩ = ∫ f g dx, turn Fourier coefficients into shadows: each one is the shadow of a signal on a sine wave (tracks `de` and `qu`).",
  ],
};

interface P04 { u: Vec; v: Vec; a: number; b: number; e: number }
const DEP = ["dependent", "independent"];
const w04 = (p: P04) => [p.a * p.u[0]! + p.b * p.v[0]!, p.a * p.u[1]! + p.b * p.v[1]!, p.a * p.u[2]! + p.b * p.v[2]! + p.e];

export const la04: B2Lesson<P04> = {
  id: "b2-la-04", track: "la", unit: 1, title: "Independence, basis and dimension",
  youCan: "tell when arrows are independent and find the one that would make them dependent.",
  needs: ["b2-la-02"],
  tools: [S.vec, S.space],
  play: { scene: S.space, props: { mode: "box", a: 1, b: 1, e: 2 },
    say: "Three arrows in 3D and the slanted box they make, with its volume. Drag w's height down into the plane of u and v: the box flattens to volume 0. Drag the picture to turn it." },
  guess: { scene: S.space, props: { mode: "box", a: 1, b: 1, e: 0, yaw: 1.1, pitch: 0.25, hide: true }, kind: "choice",
    options: ["They fill space", "They lie flat in one plane"], answer: 1,
    ask: "Look at u, v and w (turn the picture if you like). Do these three arrows fill space, or lie flat in one plane?",
    revealProps: { edge: true },
    reveal: "Turned edge-on to the plane of u and v, all three arrows lie along one line: w = u + v, so they are flat, and the box has volume 0." },
  nameIt: {
    say: [
      "Arrows are independent when none of them is a mix of the others.",
      "A basis is an independent set that spans. Every basis of a space has the same number of arrows: the dimension. In a basis, every arrow has exactly one set of coordinates.",
    ],
    formula: ["w depends on u and v when w = a u + b v for some a, b"],
  },
  workIt: {
    reference: { u: [1, 0, 2], v: [0, 1, 1], a: 2, b: 3, e: 0 },
    generate(rng, i) {
      for (;;) {
        const lo = i < 3 ? 0 : -3, hi = i < 3 ? 2 : 3;
        const u = ints(rng, 3, lo, hi), v = ints(rng, 3, lo, hi);
        if (Math.abs(u[0]! * v[1]! - u[1]! * v[0]!) !== 1) continue;
        const a = i < 3 ? rng.int(1, 2) : rng.int(-3, 3), b = i < 3 ? rng.int(1, 2) : rng.int(-3, 3);
        if (!a && !b) continue;
        const flatOne = i === 0 ? true : i === 1 ? false : rng.next() < 0.5;
        return { u, v, a, b, e: flatOne ? 0 : rng.pick([-3, -2, -1, 1, 2, 3]) };
      }
    },
    show: p => `u = **${vec(p.u)}**, v = **${vec(p.v)}**, w = **${vec(w04(p))}**. Dependent or independent?`,
    steps(p) {
      const w = w04(p), c = p.a * p.u[2]! + p.b * p.v[2]!, right = p.e === 0 ? 0 : 1;
      const eqs = `${lin([[p.u[0]!, "a"], [p.v[0]!, "b"]])} = ${sn(w[0]!)} and ${lin([[p.u[1]!, "a"], [p.v[1]!, "b"]])} = ${sn(w[1]!)}`;
      return [
        wholeStep("a", "a, from the first two entries", p.a, { hint: `Solve ${eqs}.`,
          slips: [slip("swapped a and b", p.b, "a counts copies of u: it goes with u's entries.")] }),
        wholeStep("b", "b", p.b, { hint: `Put a = ${sn(p.a)} back into ${eqs}.`,
          slips: [slip("swapped a and b", p.a, "b counts copies of v: it goes with v's entries.")] }),
        wholeStep("c", "c, the third entry w would need to lie in the plane", c, { hint: `a u₃ + b v₃ = ${times(p.a, p.u[2]!)} + ${times(p.b, p.v[2]!)}.`,
          slips: [
            slip("first arrow only", p.a * p.u[2]!, "w has to be a mix of both arrows, so the third entry is a u₃ + b v₃."),
            slip("second arrow only", p.b * p.v[2]!, "w has to be a mix of both arrows, so the third entry is a u₃ + b v₃."),
          ] }),
        tapStep("dep", "Then the three arrows are", DEP, right, { hint: `Compare w's third entry, ${sn(w[2]!)}, with c = ${sn(c)}.`,
          slips: [
            right === 0 && slip("independent when w₃ = c", 1, `w = ${lin([[p.a, "u"], [p.b, "v"]])}, so it adds nothing new: the three are dependent.`),
            right === 1 && slip("dependent when w₃ ≠ c", 0, `A mix of u and v would need third entry ${sn(c)}, but w has ${sn(w[2]!)}. w points out of the plane, so the three are independent.`),
          ] }),
      ];
    },
    scene: p => { const w = w04(p); return { scene: S.space, props: { mode: "box", ux: p.u[0]!, uy: p.u[1]!, uz: p.u[2]!, vx: p.v[0]!, vy: p.v[1]!, vz: p.v[2]!, wx: w[0]!, wy: w[1]!, wz: w[2]!, hide: true } }; },
  },
  // dependent exactly when the 3 × 3 of the three arrows has determinant 0 (a library's det)
  oracle: p => {
    const w = w04(p), D = p.u[0]! * p.v[1]! - p.u[1]! * p.v[0]!;
    return [(w[0]! * p.v[1]! - w[1]! * p.v[0]!) / D, (p.u[0]! * w[1]! - p.u[1]! * w[0]!) / D, p.a * p.u[2]! + p.b * p.v[2]!, Math.abs(det([p.u, p.v, w])) < 1e-9 ? 0 : 1];
  },
  useIt: {
    say: [
      "A plaid picture has 8 rows, and each row is a mix of the same two pattern rows. Only two rows are new; the rest are mixes. Its rows have dimension 2: two rows of numbers, plus two mixing numbers per row, rebuild the whole picture.",
      "Project: choose two basis arrows of your own. The plane redraws in your grid, and three points are written in your coordinates. Save it to keep `basis`.",
    ],
    project: "la-grid",
  },
  deeper: [
    "The Steinitz exchange lemma: if k arrows are independent and m arrows span, then k ≤ m. Swap the spanning arrows out one at a time for independent ones. It proves every basis has the same size.",
    "Infinite-dimensional spaces: all polynomials have the basis 1, x, x², … . That every vector space has a basis at all needs the axiom of choice.",
  ],
};

/* ------------------------------------------------------------------ unit 2 · matrices as moves ------------------------------------------------------------------ */

type MoveKind = "rot" | "refx" | "stretch" | "shear";
interface P05 { A: number[][]; x: Vec; tap: { kind: MoveKind; k: number; at: number } | null }
const MOVE_NAME = (t: { kind: MoveKind; k: number }) => t.kind === "rot" ? "rotate 90° counterclockwise" : t.kind === "refx" ? "reflect across the x-axis" : t.kind === "stretch" ? `stretch x by ${t.k}` : `shear right by ${t.k}`;
/** the four matrices offered for a named move: the right one first, then the near misses with their reasons */
function moveChoices(t: { kind: MoveKind; k: number }): { M: number[][]; why: string }[] {
  const k = t.k;
  if (t.kind === "rot") return [
    { M: [[0, -1], [1, 0]], why: "" },
    { M: [[0, 1], [-1, 0]], why: "That turns clockwise. Counterclockwise sends (1, 0) to (0, 1), so the first column is (0, 1)." },
    { M: [[-1, 0], [0, -1]], why: "That turns 180°: (1, 0) goes to (−1, 0). A quarter turn counterclockwise sends (1, 0) to (0, 1)." },
    { M: [[1, 0], [0, -1]], why: "That flips across the x-axis. A turn sends (1, 0) to (0, 1)." },
  ];
  if (t.kind === "refx") return [
    { M: [[1, 0], [0, -1]], why: "" },
    { M: [[-1, 0], [0, 1]], why: "That flips across the y-axis: (1, 0) goes to (−1, 0). Across the x-axis, (1, 0) stays and (0, 1) goes to (0, −1)." },
    { M: [[0, 1], [1, 0]], why: "That swaps x and y: a flip across the line y = x." },
    { M: [[0, -1], [1, 0]], why: "That's a quarter turn. A flip across the x-axis keeps (1, 0) where it is." },
  ];
  if (t.kind === "stretch") return [
    { M: [[k, 0], [0, 1]], why: "" },
    { M: [[1, 0], [0, k]], why: `That stretches y. Stretching x sends (1, 0) to (${k}, 0): the first column.` },
    { M: [[k, 0], [0, k]], why: `That stretches both ways. Only x stretches, so (0, 1) stays put.` },
    { M: [[1, k], [0, 1]], why: "That's a shear: it slides points sideways by their height." },
  ];
  return [
    { M: [[1, k], [0, 1]], why: "" },
    { M: [[1, 0], [k, 1]], why: `That shears up. Shearing right sends (0, 1) to (${k}, 1): the second column.` },
    { M: [[k, 1], [0, 1]], why: `(1, 0) stays put in a shear, so the first column is (1, 0).` },
    { M: [[k, 0], [0, 1]], why: "That's a stretch: it changes widths but slides nothing." },
  ];
}

export const la05: B2Lesson<P05> = {
  id: "b2-la-05", track: "la", unit: 2, title: "A matrix is a move of the plane",
  youCan: "turn a picture move into a matrix, and move any point with it.",
  needs: ["b2-la-01"],
  tools: [S.play],
  play: { scene: S.play, props: { mode: "move", a: 2, c: 1, b: -1, d: 1 },
    say: "Drag the two arrows that say where (1, 0) and (0, 1) land. The whole grid, the letter F and the unit square bend with them. Grid lines stay straight and evenly spaced, and the origin stays put." },
  guess: { scene: S.play, props: { mode: "move", a: 2, c: 1, b: -1, d: 1, px: 2, py: 1, quiet: true }, kind: "point", answer: [3, 3], near: 0.6, start: [0, -2],
    ask: "(1, 0) lands on (2, 1) and (0, 1) lands on (−1, 1). Drag the marker to where you think (2, 1) lands.",
    revealProps: { walk: true },
    reveal: "Walk two steps along the first arrow, to (4, 2), then one step along the second: (3, 3)." },
  nameIt: {
    say: [
      "The columns of a matrix are where the two basic arrows land.",
      "Everything else follows, because every point is a mix of those two.",
    ],
    formula: ["A x = x₁·(first column) + x₂·(second column)", "[[a, b], [c, d]]·(x₁, x₂) = (a x₁ + b x₂, c x₁ + d x₂)"],
  },
  workIt: {
    reference: { A: [[2, -1], [1, 1]], x: [2, 1], tap: null },
    generate(rng, i) {
      const lo = i < 3 ? 0 : -3, hi = i < 3 ? 2 : 3;
      let A: number[][], x: Vec;
      do { A = [ints(rng, 2, lo, hi), ints(rng, 2, lo, hi)]; x = ints(rng, 2, i < 3 ? 1 : -3, i < 3 ? 2 : 3); } while (A.flat().every(v => !v) || isZero(x));
      const tap = i >= 4 ? { kind: rng.pick<MoveKind>(["rot", "refx", "stretch", "shear"]), k: rng.int(2, 3), at: rng.int(0, 3) } : null;
      return { A, x, tap };
    },
    show: p => `A = **${mat(p.A)}** and x = **${vec(p.x)}**. Move x with A.${p.tap ? ` Then pick the matrix that will **${MOVE_NAME(p.tap)}**.` : ""}`,
    steps(p) {
      const c1 = col(p.A, 0), c2 = col(p.A, 1), [x1, x2] = p.x as [number, number];
      const t1 = c1.map(v => x1 * v), t2 = c2.map(v => x2 * v), Ax = apply2(p.A, p.x), rows = apply2(tr(p.A), p.x);
      const out: B2Step[] = [
        multiStep("c1", `${sn(x1)} × the first column`, t1, "whole", { boxes: ["x", "y"], hint: `The first column is ${vec(c1)}: multiply it by ${sn(x1)}.`,
          slips: [slip("used a row", p.A[0]!.map(v => x1 * v), `The first column is ${vec(c1)}, read down. ${vec(p.A[0]!)} is the first row.`)] }),
        multiStep("c2", `${sn(x2)} × the second column`, t2, "whole", { boxes: ["x", "y"], hint: `The second column is ${vec(c2)}: multiply it by ${sn(x2)}.`,
          slips: [slip("used a row", p.A[1]!.map(v => x2 * v), `The second column is ${vec(c2)}, read down. ${vec(p.A[1]!)} is the second row.`)] }),
        multiStep("ax", "A x", Ax, "whole", { boxes: ["x", "y"], hint: `Add the two: ${vec(t1)} + ${vec(t2)}.`,
          slips: [slip("rows as columns", rows, `The first column, ${vec(c1)}, is where (1, 0) lands. Reading rows instead multiplies by the flipped matrix.`)] }),
      ];
      if (p.tap) {
        const ch = moveChoices(p.tap), order = [...ch.slice(p.tap.at), ...ch.slice(0, p.tap.at)];
        out.push(tapStep("pick", `The matrix to ${MOVE_NAME(p.tap)}`, order.map(c => mat(c.M)), order.findIndex(c => !c.why), {
          hint: "Ask where (1, 0) and (0, 1) go: those are the two columns.",
          slips: order.map((c, i) => (c.why ? slip(`picked ${mat(c.M)}`, i, c.why) : null)),
        }));
      }
      return out;
    },
    scene: p => ({ scene: S.play, props: { mode: "move", a: p.A[0]![0]!, c: p.A[1]![0]!, b: p.A[0]![1]!, d: p.A[1]![1]!, px: p.x[0]!, py: p.x[1]!, quiet: true } }),
  },
  // a matrix library's product; the named move built from where (1, 0) and (0, 1) go
  oracle: p => {
    const Ax = mul(p.A, p.x.map(v => [v])).flat();
    const out = [...p.A.map(r => r[0]! * p.x[0]!), ...p.A.map(r => r[1]! * p.x[1]!), ...Ax];
    if (p.tap) {
      const k = p.tap.k, e1 = { rot: [0, 1], refx: [1, 0], stretch: [k, 0], shear: [1, 0] }[p.tap.kind], e2 = { rot: [-1, 0], refx: [0, -1], stretch: [0, 1], shear: [k, 1] }[p.tap.kind];
      const want = [[e1[0]!, e2[0]!], [e1[1]!, e2[1]!]];
      const ch = moveChoices(p.tap), order = [...ch.slice(p.tap.at), ...ch.slice(0, p.tap.at)];
      out.push(order.findIndex(c => same(c.M, want)));
    }
    return out;
  },
  useIt: {
    say: [
      "Italicize a letter with the shear [[1, 1/4], [0, 1]]: the top of a 4-unit-tall letter at (0, 4) moves to (1, 4), while its foot stays put.",
      "Save the shear as `shear`.",
    ],
    saves: { name: "shear", value: () => [[1, 0.25], [0, 1]], note: "italic: shear right by 1/4" },
    scene: { scene: S.play, props: { mode: "move", a: 1, c: 0, b: 0.5, d: 1, px: 0, py: 4 } },
  },
  deeper: [
    "Linearity, T(a u + b v) = a T(u) + b T(v), forces a matrix: knowing T on (1, 0) and (0, 1) fixes T everywhere.",
    "Linear maps that aren't arrows: the derivative acting on polynomials a + b x + c x² sends (a, b, c) to (b, 2c, 0), so it is the 3 × 3 matrix [[0, 1, 0], [0, 0, 2], [0, 0, 0]] (track `de`).",
  ],
};

interface P06 { A: number[][]; B: number[][] }
const SAME = ["Yes, AB = BA", "No, AB ≠ BA"];

export const la06: B2Lesson<P06> = {
  id: "b2-la-06", track: "la", unit: 2, title: "Doing two moves: matrix multiplication",
  youCan: "combine two moves into one matrix, and build a picture layer from a column and a row.",
  needs: ["b2-la-05"],
  tools: [S.play, "matrix"],
  play: { scene: S.play, props: { mode: "compose", A: "turn", B: "shear" },
    say: "Pick move A and move B and press Run: the playground does A, then B, to the letter F. Flip the order switch and run it again." },
  guess: { scene: S.play, props: { mode: "compose", A: "turn", B: "shear", quiet: true }, kind: "choice", options: ["The same", "Different"], answer: 1,
    ask: "Does \"turn, then shear\" leave the letter F the same as \"shear, then turn\"?",
    revealProps: { both: true },
    reveal: "Played side by side, the two F's land in different places: order matters. Turn then shear is BA = [[1, −1], [1, 0]]; shear then turn is AB = [[0, −1], [1, 1]]." },
  nameIt: {
    say: [
      "Doing A first and then B is the single matrix BA: the one done first sits on the right. Each entry is a row of B dotted with a column of A, and order usually matters.",
      "A column times a row also makes a matrix: a layer.",
    ],
    formula: ["(BA)ᵢⱼ = (row i of B)·(column j of A)", "u vᵀ has entries uᵢ vⱼ"],
  },
  workIt: {
    reference: { A: [[1, 2], [0, 1]], B: [[0, -1], [1, 0]] },
    generate(rng, i) {
      const lo = i < 3 ? 0 : -3, hi = i < 3 ? 2 : 3;
      let A: number[][], B: number[][];
      do { A = [ints(rng, 2, lo, hi), ints(rng, 2, lo, hi)]; B = [ints(rng, 2, lo, hi), ints(rng, 2, lo, hi)]; } while (A.flat().every(v => !v) || B.flat().every(v => !v));
      return { A, B };
    },
    show: p => `A = **${mat(p.A)}** happens first, then B = **${mat(p.B)}**. Find the single matrix BA.`,
    steps(p) {
      const BA = mm(p.B, p.A), AB = mm(p.A, p.B), right = same(AB, BA) ? 0 : 1;
      const colStep = (j: number, name: string) => {
        const a = col(p.A, j);
        return multiStep(`c${j}`, `${name} column of BA`, col(BA, j), "whole", { boxes: ["top", "bottom"], hint: `B times A's ${name.toLowerCase()} column: B·${vec(a)}.`,
          slips: [
            slip("entry by entry", [p.B[0]![j]! * p.A[0]![j]!, p.B[1]![j]! * p.A[1]![j]!], "A product isn't entry by entry. Each entry is a whole row times a whole column."),
            slip("computed AB", col(AB, j), "A happens first, so it goes on the right: BA."),
            slip("row times row", [dot(p.B[0]!, p.A[j]!), dot(p.B[1]!, p.A[j]!)], "Use a row of B with a column of A."),
          ] });
      };
      return [
        colStep(0, "First"),
        colStep(1, "Second"),
        tapStep("same", "Is AB the same?", SAME, right, { hint: `Work out AB the same way: A times B's columns.`,
          slips: [right === 1 ? slip("said yes", 0, `AB = ${mat(AB)} but BA = ${mat(BA)}: order matters here.`) : slip("said no", 1, `Here they match: AB = BA = ${mat(BA)}. Some pairs do, but most don't.`)] }),
      ];
    },
    scene: () => ({ scene: S.play, props: { mode: "compose", A: "turn", B: "shear" } }),
  },
  // a matrix library's product, and a library comparison
  oracle: p => {
    const BA = mul(p.B, p.A), AB = mul(p.A, p.B), d = add(AB, BA, -1);
    return [BA[0]![0]!, BA[1]![0]!, BA[0]![1]!, BA[1]![1]!, d.flat().every(v => v === 0) ? 0 : 1];
  },
  useIt: {
    say: [
      "Your first layer: the column u = (1, 2, 3) times the row vᵀ = (2, 0, 1) makes the 3 × 3 picture [[2, 0, 1], [4, 0, 2], [6, 0, 3]]. Tap u or vᵀ to change them.",
      "It costs 6 numbers instead of 9. Save it as `layer1`: the build's basic piece.",
    ],
    saves: { name: "layer1", value: () => [[2, 0, 1], [4, 0, 2], [6, 0, 3]], note: "column (1, 2, 3) times row (2, 0, 1)" },
    scene: { scene: S.comp, props: { mode: "outer" } },
  },
  deeper: [
    "Multiplication is associative, (CB)A = C(BA), because both mean \"do A, then B, then C\": composing functions is associative.",
    "The plain way costs n³ multiplications. Strassen's trick multiplies 2 × 2 blocks with 7 products instead of 8, which brings it down to about n^2.81 (b2-cs-09).",
    "Block matrices multiply like 2 × 2 matrices whose entries are themselves matrices, as long as the block sizes fit.",
  ],
};

type P07 = { kind: 2; A: number[][]; S: number } | { kind: 3; A: number[][] };
const FLIP = ["not mirrored", "mirrored", "squashed flat"];
const flipIdx = (d: number) => (d > 0 ? 0 : d < 0 ? 1 : 2);
function flipSlips(d: number) {
  const right = flipIdx(d);
  return [0, 1, 2].filter(i => i !== right).map(i =>
    d === 0 ? slip("picked a side at det 0", i, "det is 0, so the plane is squashed onto a line or a point: squashed flat.")
      : i === 2 ? slip("squashed when det ≠ 0", 2, `Only det = 0 squashes the plane. Here det = ${sn(d)}.`)
        : d > 0 ? slip("mirrored when det > 0", 1, "A positive det keeps the picture's handedness: not mirrored.")
          : slip("not mirrored when det < 0", 0, "A negative det means the picture is flipped over: mirrored."));
}

export const la07: B2Lesson<P07> = {
  id: "b2-la-07", track: "la", unit: 2, title: "The determinant: how much area changes",
  youCan: "find how much a move scales area, and tell when it mirrors or squashes the plane.",
  needs: ["b2-la-05"],
  tools: [S.play, S.space],
  play: { scene: S.play, props: { mode: "det", a: 2, c: 1, b: 1, d: 2 },
    say: "The unit square becomes a parallelogram, and its area shows. Drag one arrow across the other: the area passes through 0 and comes back negative, and the square turns pink because the picture is now mirrored." },
  guess: { scene: S.play, props: { mode: "det", a: 3, c: 1, b: 1, d: 2, quiet: true }, kind: "slider", min: 0, max: 10, step: 0.5, start: 3, answer: 5, near: 0.5, unit: "square units",
    format: x => x.toFixed(1),
    ask: "The columns are (3, 1) and (1, 2). Drag the slider to your guess for the parallelogram's area.",
    revealProps: { proof: true },
    reveal: "The box around it is 4 by 3, which is 12. Take away the two violet triangles (3), the two teal ones (2) and the two amber rectangles (2): 5, which is a d − b c = 6 − 1." },
  nameIt: {
    say: [
      "The determinant is the area scale of the move, with a sign. Negative means the picture is mirrored; zero means the plane is squashed onto a line or a point.",
      "Scales multiply: det(BA) = det B · det A.",
    ],
    formula: ["det [[a, b], [c, d]] = a d − b c", "area of the image = |det| × area"],
  },
  workIt: {
    reference: { kind: 2, A: [[3, 1], [2, 4]], S: 3 },
    generate(rng, i) {
      if (i >= 4 && i % 2 === 1) {
        let A: number[][];
        do { A = [ints(rng, 3, -2, 2), ints(rng, 3, -2, 2), ints(rng, 3, -2, 2)]; } while (A[0]!.every(v => !v));
        return { kind: 3, A };
      }
      const lo = i < 3 ? 0 : -5, hi = i < 3 ? 4 : 5;
      for (;;) {
        let A = [ints(rng, 2, lo, hi), ints(rng, 2, lo, hi)];
        if (i >= 3 && rng.next() < 0.17) { const k = rng.pick([-2, -1, 1, 2]); A = [A[0]!, A[0]!.map(v => k * v)]; }
        if (A.flat().every(v => !v) || A.flat().some(v => Math.abs(v) > 5)) continue;
        return { kind: 2, A, S: rng.int(1, 6) };
      }
    },
    show: p => p.kind === 2 ? `A = **${mat(p.A)}** acts on a shape of area **${p.S}**.` : `A = **${mat(p.A)}** acts on the unit cube. Expand along the first row.`,
    steps(p) {
      if (p.kind === 2) {
        const [[a, b], [c, d]] = p.A as [[number, number], [number, number]], D = a * d - b * c;
        return [
          wholeStep("ad", "a d", a * d, { hint: `${times(a, d)}.` }),
          wholeStep("bc", "b c", b * c, { hint: `${times(b, c)}.` }),
          wholeStep("det", "det", D, { hint: `a d − b c = ${sn(a * d)} − ${b * c < 0 ? `(${sn(b * c)})` : sn(b * c)}.`,
            slips: [slip("a d + b c", a * d + b * c, "It is a d minus b c."), slip("a c − b d", a * c - b * d, "Multiply down the diagonals: a with d, b with c.")] }),
          wholeStep("area", "Area of the image", Math.abs(D) * p.S, { hint: `|det| × ${p.S}.`,
            slips: [
              D < 0 && slip("negative area", D * p.S, "Area can't be negative. Use |det|; the sign only says the picture flipped."),
              p.S !== 1 && slip("forgot the shape", Math.abs(D), `That's what the unit square becomes. This shape has area ${p.S}, so multiply.`),
            ] }),
          tapStep("flip", "Mirrored, not mirrored or squashed flat?", FLIP, flipIdx(D), { hint: "Look at the sign of det.", slips: flipSlips(D) }),
        ];
      }
      const [[a, b, c], [d, e, f], [g, h, k]] = p.A as [[number, number, number], [number, number, number], [number, number, number]];
      const t1 = a * (e * k - f * h), t2 = b * (d * k - f * g), t3 = c * (d * h - e * g), D = t1 - t2 + t3;
      return [
        wholeStep("t1", "First term, a(e i − f h)", t1, { hint: `${sn(a)} × (${times(e, k)} − ${times(f, h)}).` }),
        wholeStep("t2", "Second, b(d i − f g)", t2, { hint: `${sn(b)} × (${times(d, k)} − ${times(f, g)}).` }),
        wholeStep("t3", "Third, c(d h − e g)", t3, { hint: `${sn(c)} × (${times(d, h)} − ${times(e, g)}).` }),
        wholeStep("det", "det", D, { hint: "First − second + third.",
          slips: [slip("3 × 3 signs", t1 + t2 + t3, "Expansion signs go +, −, + along the first row.")] }),
        wholeStep("vol", "Volume of the cube's image", Math.abs(D), { hint: "|det| × 1.",
          slips: [D < 0 && slip("negative volume", D, "Volume can't be negative. Use |det|; the sign only says the cube flipped.")] }),
        tapStep("flip", "Mirrored, not mirrored or squashed flat?", FLIP, flipIdx(D), { hint: "Look at the sign of det.", slips: flipSlips(D) }),
      ];
    },
    scene: (p): SceneRef => p.kind === 2
      ? { scene: S.play, props: { mode: "det", a: p.A[0]![0]!, c: p.A[1]![0]!, b: p.A[0]![1]!, d: p.A[1]![1]!, quiet: true } }
      : { scene: S.space, props: { mode: "cube", ...Object.fromEntries(p.A.flatMap((r, i) => r.map((v, j) => [`m${i}${j}`, v]))), quiet: true } },
  },
  // a library's det, cross-checked by the shoelace area of the square's image (3 × 3: 2 × 2 minors from the library)
  oracle: p => {
    if (p.kind === 2) {
      const [a, b] = [col(p.A, 0), col(p.A, 1)], corners = [[0, 0], a, [a[0]! + b[0]!, a[1]! + b[1]!], b];
      const shoelace = corners.reduce((s, q, i) => { const r = corners[(i + 1) % 4]!; return s + q[0]! * r[1]! - r[0]! * q[1]!; }, 0) / 2;
      const D = Math.round(det(p.A));
      expectSame(shoelace, D);
      return [p.A[0]![0]! * p.A[1]![1]!, p.A[0]![1]! * p.A[1]![0]!, D, Math.abs(shoelace) * p.S, flipIdx(D)];
    }
    const minor = (j: number) => det(p.A.slice(1).map(r => r.filter((_, c) => c !== j)));
    const D = Math.round(det(p.A));
    expectSame(det3(p.A), D);
    return [p.A[0]![0]! * minor(0), p.A[0]![1]! * minor(1), p.A[0]![2]! * minor(2), D, Math.abs(D), flipIdx(D)];
  },
  useIt: {
    say: [
      "Your `shear` from lesson 05 has det 1: the italic letter uses exactly as much ink as the upright one.",
      "A scale [[2, 0], [0, 3/2]] on a 64-pixel sprite has det 3, so the sprite covers 192 pixels of area.",
    ],
    scene: { scene: S.play, props: { mode: "det", a: 1, c: 0, b: 0.5, d: 1 } },
  },
  deeper: [
    "The determinant is the only function of the columns that is linear in each column, flips sign when two columns swap, and gives 1 for the identity. Everything else about it follows from those three rules.",
    "The Leibniz formula writes it as a sum over all n! orderings of the columns, each with a sign: det A = Σ sign(σ) a₁σ₍₁₎ ⋯ aₙσ₍ₙ₎.",
    "The Jacobian determinant scales area in a change of variables, which is why dx dy = r dr dθ (b2-mv-08).",
  ],
};
/** the oracle's own cross-check: two independent computations agree */
function expectSame(a: number, b: number) { if (Math.abs(a - b) > 1e-9) throw new Error(`oracle disagrees: ${a} vs ${b}`); }

interface P08 { A: number[][]; x0: Vec }

export const la08: B2Lesson<P08> = {
  id: "b2-la-08", track: "la", unit: 2, title: "Undo a move: the inverse",
  youCan: "undo a move with its inverse matrix and use it to solve a system.",
  needs: ["b2-la-06", "b2-la-07"],
  tools: [S.play, "matrix"],
  play: { scene: S.play, props: { mode: "undo", a: 2, c: 1, b: 1, d: 1 },
    say: "Apply A to the picture, then press Undo to apply A⁻¹ and bring it home. Drag the arrows toward one line: the inverse's entries grow, and at det 0 Undo goes gray." },
  guess: { scene: S.play, props: { mode: "undo", a: 2, c: 1, b: 1, d: 1, quiet: true }, kind: "choice", options: ["They get bigger", "They get smaller", "They stay about the same"], answer: 0,
    ask: "As det gets close to 0, what happens to the entries of A⁻¹?",
    revealProps: { plot: true },
    reveal: "The plot of A⁻¹'s biggest entry against det shoots up as det heads for 0: every entry is divided by det. At 0 there is no inverse at all." },
  nameIt: {
    say: [
      "The inverse undoes the move: A⁻¹A = I. It exists exactly when det ≠ 0, because a squashed picture can't be unsquashed.",
      "Then A x = b has exactly one answer.",
    ],
    formula: ["[[a, b], [c, d]]⁻¹ = (1 / (a d − b c))·[[d, −b], [−c, a]]", "x = A⁻¹ b"],
  },
  workIt: {
    reference: { A: [[2, 1], [5, 3]], x0: [1, 2] },
    generate(rng, i) {
      for (;;) {
        const A = i < 3 ? [ints(rng, 2, 0, 5), ints(rng, 2, 0, 5)] : [ints(rng, 2, -5, 5), ints(rng, 2, -5, 5)];
        const D = det2(A);
        if (i < 3 ? D !== 1 : D === 0 || Math.abs(D) > 4) continue;
        const x0 = ints(rng, 2, i < 3 ? 0 : -4, 4);
        if (isZero(x0)) continue;
        return { A, x0 };
      }
    },
    show: p => `A = **${mat(p.A)}** and b = **${vec(apply2(p.A, p.x0))}**. Solve A x = b with the inverse.`,
    steps(p) {
      const [[a, b], [c, d]] = p.A as [[number, number], [number, number]], D = a * d - b * c;
      const adj = [d, -b, -c, a], inv = adj.map(v => v / D), bb = apply2(p.A, p.x0);
      return [
        wholeStep("det", "det", D, { hint: `a d − b c = ${times(a, d)} − ${times(b, c)}.`, slips: [slip("a d + b c", a * d + b * c, "It is a d minus b c.")] }),
        multiStep("adj", "Swap and negate", adj, "whole", { boxes: CELLS, hint: "Swap a and d; negate b and c.",
          slips: [slip("negated the diagonal", [-d, b, c, -a], "Swap a and d; negate b and c."), slip("didn't swap", [a, -b, -c, d], "a and d trade places.")] }),
        multiStep("inv", "A⁻¹", inv, "fraction", { boxes: CELLS, hint: `Divide every entry by det = ${sn(D)}.`,
          slips: [slip("forgot to divide", adj, "Every entry gets divided by the determinant. Check: A times your answer should be I.")] }),
        multiStep("x", "x = A⁻¹ b", p.x0, "whole", { boxes: ["x", "y"], hint: `A⁻¹ times b = ${vec(bb)}.`,
          slips: [slip("used A", apply2(p.A, bb), "Undo with A⁻¹, not A."), slip("forgot to divide", [adj[0]! * bb[0]! + adj[1]! * bb[1]!, adj[2]! * bb[0]! + adj[3]! * bb[1]!], `Divide by det = ${sn(D)} as well.`)] }),
      ];
    },
    scene: p => ({ scene: S.play, props: { mode: "undo", a: p.A[0]![0]!, c: p.A[1]![0]!, b: p.A[0]![1]!, d: p.A[1]![1]!, quiet: true } }),
  },
  // the generator's x₀, and a library inverse
  oracle: p => {
    const I = inverse(p.A), D = Math.round(det(p.A));
    return [D, ...I.flat().map(v => v * D), ...I.flat(), ...p.x0];
  },
  useIt: {
    say: ["Project: chain a turn, a shear and a scale into one filter M for an 8 × 8 sprite. Read its det to see how much it changes the sprite's area, then press Undo: Minv brings the sprite back. Save both to keep `M` and `Minv`."],
    project: "la-filter",
  },
  deeper: [
    "Inverting by row reduction: reduce [A | I] until the left half is I; the right half is then A⁻¹. It works for any size.",
    "The condition number |A||A⁻¹| says how many digits a computer can lose solving A x = b. Nearly flat matrices have huge inverses, so they lose many (track `cs`).",
    "When A is small, (I − A)⁻¹ = I + A + A² + ⋯, the matrix version of 1/(1 − x) = 1 + x + x² + ⋯ (the Neumann series).",
  ],
};
