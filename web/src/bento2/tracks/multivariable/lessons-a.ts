// Multivariable, part 1 (landscapes and flows): b2-mv-01 to b2-mv-10, from curriculum/specs/bento2/multivariable.md
// block by block. Every formula is written by the term printer (maths.ts), so no 1s, no 0 terms and no "+ −".
import type { B2Lesson, SceneRef } from "../../model";
import { fracStep, multiStep, numStep, slip, tapStep, wholeStep } from "../../make";
import { formatAnswer } from "../../steps";
import type { Rng } from "../../../curriculum/generators/rng";
import { fracTerm, LAND, mono, pt, sn, terms, vec } from "./maths";

const fr = (x: number) => formatAnswer(x, "fraction");
/** a tenths number as text: 1.1, −0.2 */
const d1 = (x: number) => { const v = Math.round(x * 10) / 10; return (v < 0 ? "−" : "") + String(Math.abs(v)); };
/** a number for a typed formula the pictures read (expr syntax) */
const ex = (x: number) => `(${x})`;
/** a 4-option tap step's layout: opts[0] is right; `ord` is the shuffled order (from the generator) */
const lay = (opts: string[], ord: number[]) => ({ choices: ord.map(i => opts[i]!), at: (i: number) => ord.indexOf(i) });
const distinct = (xs: string[]) => new Set(xs).size === xs.length;
const nz = (rng: Rng, lo: number, hi: number) => { let v = 0; while (v === 0) v = rng.int(lo, hi); return v; };
/** combine like terms (same monomial), keeping first-seen order */
const combine = (ts: [number, string][]): [number, string][] => {
  const out: [number, string][] = [];
  for (const [c, m] of ts) { const o = out.find(t => t[1] === m); if (o) o[0] += c; else out.push([c, m]); }
  return out;
};
const cd = (g: (h: number) => number, h = 1e-5) => (g(h) - g(-h)) / (2 * h);

/* ================================================================ unit 1 · Landscapes ================================================================ */

interface P01 { a: number; b: number; m: number; x0: number; y0: number }

export const mv01: B2Lesson<P01> = {
  id: "b2-mv-01", track: "mv", unit: 1, title: "Landscapes and contour maps",
  youCan: "read a contour map and tell steep ground from gentle ground.",
  needs: ["pc-transform", "c-implicit"],
  tools: ["surface", "graph3d"],
  play: { scene: "surface", props: { fn: "ellipse", a: 1, b: 4, k: 4 },
    say: "A hill sits above its contour map. Drag the height: a flat plane cuts the hill there, and the cut drops to the floor as one contour. Drag the two stretch numbers and watch the contours squeeze and spread." },
  guess: { scene: "surface", props: { fn: "ellipse", a: 1, b: 4, k: 4, quiet: true }, kind: "choice",
    options: ["A circle", "An oval, wider left to right", "An oval, taller up and down"], answer: 1,
    ask: "For f = x² + 4y², what shape is the contour f = 4?",
    revealProps: { cross: true },
    reveal: "Wider left to right. It crosses the x-axis at ±2 but the y-axis only at ±1: going along y, the ground climbs 4 times as fast." },
  nameIt: {
    say: [
      "A function of two inputs is a landscape: f(x, y) is the height above the spot (x, y). A contour is every spot at one height, f(x, y) = k.",
      "Where contours for evenly spaced heights crowd together, the ground is steep.",
    ],
    formula: ["contour at height k: {(x, y) : f(x, y) = k}"],
  },
  workIt: {
    reference: { a: 1, b: 4, m: 1, x0: 2, y0: -1 },
    generate(rng, i) {
      const [a, b] = rng.shuffle([1, 4, 9]);
      const r = i < 3 ? [0, 2] : [-3, 3];
      return { a: a!, b: b!, m: i < 3 ? 1 : rng.int(1, 2), x0: rng.int(r[0]!, r[1]!), y0: rng.int(r[0]!, r[1]!) };
    },
    show: p => `f(x, y) = ${terms([[p.a, "x²"], [p.b, "y²"]])}. The contour at height **k = ${36 * p.m * p.m}**, and the point **${pt(p.x0, p.y0)}**.`,
    steps(p) {
      const k = 36 * p.m * p.m, xa = Math.sqrt(k / p.a), yb = Math.sqrt(k / p.b);
      return [
        wholeStep("h", "Height at the point", p.a * p.x0 ** 2 + p.b * p.y0 ** 2, {
          hint: `Square each coordinate, multiply by its number, and add: f${pt(p.x0, p.y0)}.` }),
        wholeStep("xa", "The contour crosses the positive x-axis at x =", xa, {
          hint: `On the x-axis y = 0, so ${terms([[p.a, "x²"]])} = ${k}.`,
          slips: [
            slip("k over a", k / p.a, "On the x-axis, ax² = k, so x is the square root of k/a."),
            slip("used b", yb, `On the x-axis y is 0, so only the ${terms([[p.a, "x²"]])} term is left.`),
          ] }),
        wholeStep("yb", "It crosses the positive y-axis at y =", yb, {
          hint: `On the y-axis x = 0, so ${terms([[p.b, "y²"]])} = ${k}.`,
          slips: [
            slip("k over b", k / p.b, "On the y-axis, by² = k, so y is the square root of k/b."),
            slip("used a", xa, `On the y-axis x is 0, so only the ${terms([[p.b, "y²"]])} term is left.`),
          ] }),
        tapStep("steep", "Steeper going along", ["x", "y"], p.a > p.b ? 0 : 1, {
          hint: "The contour stays closer to the center along the steeper axis.",
          slips: [slip("wider", p.a > p.b ? 1 : 0, "The contour reaches farther along that axis, so you go farther to climb the same height there. Farther means gentler.")] }),
      ];
    },
    scene: p => ({ scene: "surface", props: { fn: "ellipse", a: p.a, b: p.b, k: 36 * p.m * p.m, r: 7 * p.m, px: p.x0, py: p.y0 } }),
  },
  oracle: p => { const k = 36 * p.m * p.m; return [p.a * p.x0 ** 2 + p.b * p.y0 ** 2, Math.sqrt(k / p.a), Math.sqrt(k / p.b), p.a > p.b ? 0 : 1]; },
  useIt: {
    say: ["Open the default landscape, Two lakes: f = (x² − 1)² + y² + x/4. Set the height to 0.3 and count the closed contours.",
      "Two pockets, one per valley. The right one is small because its bottom sits at about 0.246. This map is the start of the valley finder."],
    scene: { scene: "surface", props: { fn: "land", k: 0.3 } },
  },
  deeper: [
    "Level sets in higher dimensions: f(x, y, z) = k is a surface (a level surface), and a function of n inputs has (n − 1)-dimensional level sets.",
    "Contours of a quadratic form ax² + bxy + cy² are ellipses or hyperbolas whose axes are the eigenvectors of [[a, b/2], [b/2, c]] (b2-la-15).",
    "The implicit function theorem says when a contour near a point really is a smooth curve: when the gradient there is not zero.",
  ],
};

interface P02 { c: number; m: number; n: number; p: number; q: number; x0: number; y0: number; o1: number[]; o2: number[] }
const fOf02 = (p: P02) => (x: number, y: number) => p.c * x ** p.m * y ** p.n + p.p * x + p.q * y;
function opts02(p: P02) {
  const fx: [number, string][] = [[p.c * p.m, mono(p.m - 1, p.n)], [p.p, ""]];
  const fy: [number, string][] = [[p.c * p.n, mono(p.m, p.n - 1)], [p.q, ""]];
  const t = (ts: [number, string][]) => terms(combine(ts));
  return {
    x: [t(fx), t([[p.c * p.m, mono(p.m - 1, p.n)], [p.c * p.n, mono(p.m, p.n - 1)], [p.p, ""]]), t([[p.c * p.m, mono(p.m - 1, p.n)], [p.q, "y"], [p.p, ""]]), t(fy)],
    y: [t(fy), t([[p.c * p.m, mono(p.m - 1, p.n)], [p.c * p.n, mono(p.m, p.n - 1)], [p.q, ""]]), t([[p.c * p.n, mono(p.m, p.n - 1)], [p.p, "x"], [p.q, ""]]), t(fx)],
  };
}

export const mv02: B2Lesson<P02> = {
  id: "b2-mv-02", track: "mv", unit: 1, title: "Partial derivatives: slice and take the slope",
  youCan: "find the slope of a landscape in the x direction and in the y direction.",
  needs: ["c-derivdef", "c-product", "b2-mv-01"],
  tools: ["surface", "slice"],
  play: { scene: "slice", props: { src: "x^2*y", r: 2, a: 1, b: 2, dir: "x" },
    say: "A vertical plane y = b slices the hill, and the cut curve opens beside it with its tangent at x = a. Drag b and a and watch the slice and its slope change. Flip to an x = a slice to get the other slope." },
  guess: { scene: "slice", props: { src: "x^2*y", r: 2, a: 1, b: 2, dir: "x", quiet: true }, kind: "slider", min: -2, max: 10, step: 0.5, start: 1, answer: 4, near: 0.75,
    format: x => sn(x),
    ask: "On f = x²y, slice at y = 2. Set the tangent at x = 1 to the steepness you expect.",
    reveal: "The true tangent has slope 4. With y held at 2 the slice is 2x², and its slope at x = 1 is 4x = 4." },
  nameIt: {
    say: ["A partial derivative is an ordinary derivative along one slice: hold every other input fixed and differentiate in one. ∂f/∂x treats y as a constant; ∂f/∂y treats x as a constant."],
    formula: ["f_x(a, b) = lim (f(a + h, b) − f(a, b)) / h as h → 0", "f_y(a, b) = lim (f(a, b + h) − f(a, b)) / h as h → 0"],
  },
  workIt: {
    reference: { c: 3, m: 2, n: 1, p: -2, q: 5, x0: 1, y0: 2, o1: [0, 1, 2, 3], o2: [0, 1, 2, 3] },
    generate(rng, i) {
      for (;;) {
        const easy = i < 3;
        const p: P02 = {
          c: easy ? rng.int(2, 3) : rng.int(2, 4), m: easy ? 2 : rng.pick([1, 2, 3]), n: easy ? 1 : rng.pick([1, 2, 3]),
          p: nz(rng, -5, 5), q: nz(rng, -5, 5), x0: easy ? rng.int(1, 2) : rng.int(-2, 2), y0: easy ? rng.int(1, 2) : rng.int(-2, 2),
          o1: rng.shuffle([0, 1, 2, 3]), o2: rng.shuffle([0, 1, 2, 3]),
        };
        const o = opts02(p);
        if (distinct(o.x) && distinct(o.y)) return p;
      }
    },
    show: p => `f(x, y) = ${terms([[p.c, mono(p.m, p.n)], [p.p, "x"], [p.q, "y"]])}, at the point **${pt(p.x0, p.y0)}**.`,
    steps(p) {
      const o = opts02(p), X = lay(o.x, p.o1), Y = lay(o.y, p.o2);
      const fx = p.c * p.m * p.x0 ** (p.m - 1) * p.y0 ** p.n + p.p, fy = p.c * p.n * p.x0 ** p.m * p.y0 ** (p.n - 1) + p.q;
      return [
        tapStep("dx", "∂f/∂x", X.choices, X.at(0), { hint: "Treat y as a fixed number and differentiate in x.",
          slips: [
            slip("product rule", X.at(1), `In ∂f/∂x, y is a constant, so ${mono(p.m, p.n)} differentiates like ${mono(p.m, 0)} times that constant. No product rule.`),
            slip("kept qy", X.at(2), `${terms([[p.q, "y"]])} has no x in it. Along an x slice it doesn't change, so its slope is 0.`),
            slip("swapped", X.at(3), "That is the slope in the y direction. ∂f/∂x walks along x."),
          ] }),
        wholeStep("fx", "f_x at the point", fx, { hint: `Put x = ${sn(p.x0)} and y = ${sn(p.y0)} into ∂f/∂x.`,
          slips: [slip("swapped", fy, "That is the slope in the y direction. ∂f/∂x walks along x."),
            slip("kept qy", fx + p.q * p.y0, `${terms([[p.q, "y"]])} has no x in it, so it adds nothing to the slope along x.`)] }),
        tapStep("dy", "∂f/∂y", Y.choices, Y.at(0), { hint: "Treat x as a fixed number and differentiate in y.",
          slips: [
            slip("product rule", Y.at(1), `In ∂f/∂y, x is a constant, so ${mono(p.m, p.n)} differentiates like ${mono(0, p.n)} times that constant. No product rule.`),
            slip("kept px", Y.at(2), `${terms([[p.p, "x"]])} has no y in it. Along a y slice it doesn't change, so its slope is 0.`),
            slip("swapped", Y.at(3), "That is the slope in the x direction. ∂f/∂y walks along y."),
          ] }),
        wholeStep("fy", "f_y at the point", fy, { hint: `Put x = ${sn(p.x0)} and y = ${sn(p.y0)} into ∂f/∂y.`,
          slips: [slip("swapped", fx, "That is the slope in the x direction. ∂f/∂y walks along y."),
            slip("kept px", fy + p.p * p.x0, `${terms([[p.p, "x"]])} has no y in it, so it adds nothing to the slope along y.`)] }),
      ];
    },
    scene: p => ({ scene: "slice", props: { src: `${p.c}*x^${p.m}*y^${p.n} + ${ex(p.p)}*x + ${ex(p.q)}*y`, r: 2.5, a: p.x0, b: p.y0, dir: "x" } }),
  },
  oracle: p => {
    const f = fOf02(p), h = 1e-5;
    return [p.o1.indexOf(0), Math.round((f(p.x0 + h, p.y0) - f(p.x0 - h, p.y0)) / (2 * h)), p.o2.indexOf(0), Math.round((f(p.x0, p.y0 + h) - f(p.x0, p.y0 - h)) / (2 * h))];
  },
  useIt: {
    say: ["Put the hiker on Two lakes at (1/2, 1/2) and read the two slopes: f_x = 4x³ − 4x + 1/4 = −5/4 and f_y = 2y = 1.",
      "East is downhill, north is uphill. The hiker readout gains \"slope east\" and \"slope north\"."],
    scene: { scene: "slice", props: { fn: "land", a: 0.5, b: 0.5, dir: "x" } },
  },
  deeper: [
    "Mixed partials: f_xy = f_yx whenever both are continuous (Clairaut's theorem). A proof sketch takes a double difference quotient and reads it in either order.",
    "The classic counterexample f = xy(x² − y²)/(x² + y²) has f_xy(0, 0) = −1 but f_yx(0, 0) = 1.",
    "Partials can exist where f is not even continuous: f = xy/(x² + y²) at the origin has both partials equal to 0 there.",
  ],
};

interface P03 { p: number; q: number; r: number; a: number; b: number; s: number; t: number }
const f03 = (p: P03) => (x: number, y: number) => p.p * x * x + p.q * x * y + p.r * y * y;

export const mv03: B2Lesson<P03> = {
  id: "b2-mv-03", track: "mv", unit: 1, title: "Tangent planes and linear approximation",
  youCan: "write the flat plane that touches a landscape and use it to estimate nearby heights.",
  needs: ["c-linapprox", "b2-mv-02"],
  tools: ["surface", "calc"],
  play: { scene: "tangent", props: { src: "x^2 + y^2", r: 2, a: 1, b: 1, zoom: 1 },
    say: "A flat sheet touches the surface at a point you drag. Zoom in on the touch point and the surface flattens until you can't tell it from the sheet." },
  guess: { scene: "tangent", props: { src: "x^2 + y^2", r: 2, a: 1, b: 1, zoom: 1, tx: 1.2, ty: 0.9, quiet: true }, kind: "choice",
    options: ["Too high", "Too low", "Exact"], answer: 1,
    ask: "On the bowl f = x² + y², touching at (1, 1): is the plane's estimate of f(1.2, 0.9) too high, too low or exact?",
    revealProps: { zoom: 4 },
    reveal: "Too low. The plane says 2.2 and the bowl is at 2.25. A bowl curves up away from every tangent plane, so the plane always sits under it." },
  nameIt: {
    say: ["Near a point, a smooth landscape looks like a plane whose two slopes are f_x and f_y. Use it to estimate heights close by."],
    formula: ["f(x, y) ≈ f(a, b) + f_x(a, b)(x − a) + f_y(a, b)(y − b)"],
  },
  workIt: {
    reference: { p: 1, q: 3, r: -1, a: 1, b: 2, s: 1, t: -1 },
    generate(rng, i) {
      for (;;) {
        const easy = i < 3;
        const p = easy ? rng.int(0, 3) : rng.int(-3, 3), q = easy ? rng.int(0, 3) : rng.int(-3, 3), r = easy ? rng.int(0, 3) : rng.int(-3, 3);
        const s = rng.int(-2, 2), t = rng.int(-2, 2);
        if ((!p && !q && !r) || (!s && !t)) continue;
        return { p, q, r, a: easy ? rng.int(1, 2) : rng.int(-2, 2), b: easy ? rng.int(1, 2) : rng.int(-2, 2), s, t };
      }
    },
    show: p => `f(x, y) = ${terms([[p.p, "x²"], [p.q, "xy"], [p.r, "y²"]])}. Touch at **${pt(p.a, p.b)}** and estimate the height at **(${d1(p.a + p.s / 10)}, ${d1(p.b + p.t / 10)})**, to 1 decimal place.`,
    steps(p) {
      const f0 = f03(p)(p.a, p.b), fx = 2 * p.p * p.a + p.q * p.b, fy = p.q * p.a + 2 * p.r * p.b;
      const est = (10 * f0 + fx * p.s + fy * p.t) / 10;
      return [
        wholeStep("f", "f(a, b)", f0, { hint: `Put x = ${sn(p.a)} and y = ${sn(p.b)} into f.` }),
        wholeStep("fx", "f_x(a, b)", fx, { hint: `f_x = ${terms([[2 * p.p, "x"], [p.q, "y"]])}, at ${pt(p.a, p.b)}.`,
          slips: [slip("swapped", fy, "That's the slope along y. f_x holds y fixed and walks along x.")] }),
        wholeStep("fy", "f_y(a, b)", fy, { hint: `f_y = ${terms([[p.q, "x"], [2 * p.r, "y"]])}, at ${pt(p.a, p.b)}.`,
          slips: [slip("swapped", fx, "That's the slope along x. f_y holds x fixed and walks along y.")] }),
        numStep("est", "Estimate", est, 1, { hint: `${sn(f0)} + (${sn(fx)})(${d1(p.s / 10)}) + (${sn(fy)})(${d1(p.t / 10)}).`, slips: [
          slip("change only", (fx * p.s + fy * p.t) / 10, "That is the change. Add it to the starting height f(a, b)."),
          slip("x not x − a", (10 * f0 + fx * (10 * p.a + p.s) + fy * (10 * p.b + p.t)) / 10, "Multiply each slope by how far you move, 0.1 or 0.2, not by where you end up."),
          p.t !== 0 && slip("lost the sign", (10 * f0 + fx * p.s - fy * p.t) / 10, `y goes from ${sn(p.b)} to ${d1(p.b + p.t / 10)}, so Δy = ${d1(p.t / 10)} and f_y·Δy = ${d1((fy * p.t) / 10)}.`),
        ] }),
      ];
    },
    scene: p => ({ scene: "tangent", props: { src: `${ex(p.p)}*x^2 + ${ex(p.q)}*x*y + ${ex(p.r)}*y^2`, r: 2.5, a: p.a, b: p.b, zoom: 1, tx: p.a + p.s / 10, ty: p.b + p.t / 10 } }),
  },
  oracle: p => {
    const f = f03(p), h = 1e-5, f0 = f(p.a, p.b);
    const fx = (f(p.a + h, p.b) - f(p.a - h, p.b)) / (2 * h), fy = (f(p.a, p.b + h) - f(p.a, p.b - h)) / (2 * h);
    return [f0, Math.round(fx), Math.round(fy), Math.round((f0 + fx * p.s * 0.1 + fy * p.t * 0.1) * 10) / 10];
  },
  useIt: {
    say: ["The hiker on Two lakes now carries a small tangent tile under its feet. The tile's tilt is (f_x, f_y); drag the hiker and watch it lean.",
      "Saved as the hiker's local plane."],
    scene: { scene: "tangent", props: { fn: "land", a: 0.5, b: 0.5, zoom: 1 } },
  },
  deeper: [
    "Differentiable means the plane's error shrinks faster than the step: (f(p + h) − f(p) − L(h)) / |h| → 0.",
    "The derivative of a map from Rⁿ to Rᵐ is an m × n matrix, the Jacobian (b2-la-05).",
    "The next term is ½ hᵀHh with the Hessian H, so the plane's error is quadratic. This is the two-variable Taylor polynomial, and it returns in b2-mv-13.",
  ],
};
interface P04 { kind: number; c: number; d: number; p: number; q: number; r: number; t0: number }
const F04 = (p: P04) => [
  (x: number, y: number) => p.c * x * y,
  (x: number, y: number) => p.c * x * x * y,
  (x: number, y: number) => p.c * x + p.d * y * y,
  (x: number, y: number) => p.c * x * x + p.d * y * y,
][p.kind]!;
const FSTR04 = (p: P04) => terms([[[p.c, "xy"]], [[p.c, "x²y"]], [[p.c, "x"], [p.d, "y²"]], [[p.c, "x²"], [p.d, "y²"]]][p.kind]! as [number, string][]);
const SRC04 = (p: P04) => [`${ex(p.c)}*x*y`, `${ex(p.c)}*x^2*y`, `${ex(p.c)}*x + ${ex(p.d)}*y^2`, `${ex(p.c)}*x^2 + ${ex(p.d)}*y^2`][p.kind]!;
function slopes04(p: P04, X: number, Y: number): [number, number] {
  switch (p.kind) {
    case 0: return [p.c * Y, p.c * X];
    case 1: return [2 * p.c * X * Y, p.c * X * X];
    case 2: return [p.c, 2 * p.d * Y];
    default: return [2 * p.c * X, 2 * p.d * Y];
  }
}

export const mv04: B2Lesson<P04> = {
  id: "b2-mv-04", track: "mv", unit: 1, title: "The chain rule on a trail",
  youCan: "find how fast your height changes as you walk a path across a landscape.",
  needs: ["bc-param", "b2-mv-02"],
  tools: ["surface", "hiker"],
  play: { scene: "hiker", props: { fn: "land" },
    say: "Drag the trail's three handles on the contour map. A walker follows it while the strip below plots height against time; bend the trail and the strip redraws." },
  guess: { scene: "hiker", props: { fn: "land", quiet: true }, kind: "slider", min: 0, max: 4, step: 0.1, start: 2, answer: GUESS04_T(), near: 0.3, unit: "s",
    format: x => x.toFixed(1),
    ask: "On the strip's time axis, set the moment you think the walker climbs fastest. Judge it from where the trail cuts the contours most tightly.",
    reveal: `The rate-of-climb curve peaks at about t = ${GUESS04_T().toFixed(1)} s, on the steep wall between the left valley and the pass, where the trail crosses contours closest together.` },
  nameIt: {
    say: ["Your height changes for two reasons at once: moving in x and moving in y. Each slope times how fast you move that way, added."],
    formula: ["dz/dt = f_x·x′(t) + f_y·y′(t)"],
  },
  workIt: {
    reference: { kind: 1, c: 1, d: 0, p: 1, q: 1, r: 0, t0: 1 },
    generate(rng, i) {
      if (i < 3) return { kind: 1, c: rng.int(1, 2), d: 0, p: rng.int(-2, 2), q: rng.pick([1, 2]), r: rng.int(-2, 2), t0: 1 };
      const kind = rng.int(0, 3);
      return { kind, c: nz(rng, -3, 3), d: kind >= 2 ? nz(rng, -3, 3) : 0, p: rng.int(-2, 2), q: rng.pick([1, 2]), r: rng.int(-2, 2), t0: rng.pick([0, 1, 2]) };
    },
    show: p => `f(x, y) = ${FSTR04(p)}. The trail: x = ${terms([[1, "t"], [p.p, ""]])}, y = ${terms([[p.q, "t²"], [p.r, ""]])}. At **t = ${p.t0}**.`,
    steps(p) {
      const X = p.t0 + p.p, Y = p.q * p.t0 ** 2 + p.r, [fx, fy] = slopes04(p, X, Y), yp = 2 * p.q * p.t0;
      const [fx0, fy0] = slopes04(p, p.p, p.r);
      return [
        multiStep("w", "Where is the walker?", [X, Y], "whole", { boxes: ["x", "y"], hint: `Put t = ${p.t0} into the trail.` }),
        multiStep("s", "f_x and f_y there", [fx, fy], "whole", { boxes: ["f_x", "f_y"], hint: `Differentiate f in x, then in y, and put in ${pt(X, Y)}.`,
          slips: [slip("swapped", [fy, fx], "f_x is the slope along x and f_y along y. They're in the other order.")] }),
        multiStep("v", "x′(t₀) and y′(t₀)", [1, yp], "whole", { boxes: ["x′", "y′"], hint: `x′ = 1 and y′ = ${terms([[2 * p.q, "t"]])}, at t = ${p.t0}.`,
          slips: [slip("position", [X, Y], `Those say where the walker is. x′ and y′ say how fast x and y change: x′ = 1, y′ = ${terms([[2 * p.q, "t"]])}.`)] }),
        wholeStep("dz", "dz/dt", fx + fy * yp, { hint: `f_x·x′ + f_y·y′ = (${sn(fx)})(1) + (${sn(fy)})(${yp}).`,
          slips: [
            slip("added slopes", fx + fy, "Each slope counts only as much as you move that way. Multiply f_x by x′ and f_y by y′."),
            slip("crossed", fx * yp + fy, "f_x goes with motion in x, so it pairs with x′."),
            p.t0 !== 0 && slip("slopes at 0", fx0 + fy0 * yp, "Take the slopes where the walker is at time t₀."),
          ] }),
      ];
    },
    scene: p => ({ scene: "hiker", props: { src: SRC04(p), r: 3, tx: `t + ${ex(p.p)}`, ty: `${p.q}*t^2 + ${ex(p.r)}`, t0: p.t0 } }),
  },
  oracle: p => {
    const f = F04(p), x = (t: number) => t + p.p, y = (t: number) => p.q * t * t + p.r, t0 = p.t0, X = x(t0), Y = y(t0);
    return [X, Y, Math.round(cd(h => f(X + h, Y))), Math.round(cd(h => f(X, Y + h))), Math.round(cd(h => x(t0 + h))), Math.round(cd(h => y(t0 + h))),
      Math.round(cd(h => f(x(t0 + h), y(t0 + h))))];
  },
  useIt: {
    say: ["Draw a trail from one valley of Two lakes to the other, over the pass, and read the steepest climb rate.",
      "Project 1, My landscape, opens: type or sculpt your own terrain, then keep its contour map and the full hiker (height, slopes, local plane, rate of climb)."],
    project: "mv-land",
  },
  deeper: [
    "The general chain rule is a product of Jacobian matrices: D(g ∘ f) = Dg·Df.",
    "Running it from the output backward, reusing each product, is backpropagation, the way every neural network computes its gradient (b2-ai-06).",
    "Implicit differentiation falls out too: along a contour dz/dt = 0, so dy/dx = −f_x/f_y.",
  ],
};
/** the guess trail: Two lakes, a straight walk from (−1.6, −0.4) to (1, 0.4) over 4 seconds; when is the climb fastest? */
export function GUESS04_T(): number {
  const A = [-1.6, -0.4], B = [1, 0.4], T = 4;
  let best = 0, bt = 0;
  for (let t = 0; t <= T + 1e-9; t += 0.01) {
    const g = (s: number) => LAND(A[0]! + ((B[0]! - A[0]!) * s) / T, A[1]! + ((B[1]! - A[1]!) * s) / T);
    const r = (g(t + 1e-4) - g(t - 1e-4)) / 2e-4;
    if (r > best) { best = r; bt = t; }
  }
  return Math.round(bt * 10) / 10;
}

/* ================================================================ unit 2 · Adding up over space ================================================================ */

interface P05 { e: number; p: number; q: number; r: number; m: number; n: number; ord: number[] }
const F05 = (p: P05) => (x: number, y: number) => p.e + p.p * x + p.q * y + p.r * x * y;
const inner = (A: number, B: number, v = "x") => terms([fracTerm(A, v), [B, ""]]);
function opts05(p: P05): { s: string; kind: string; msg: string }[] {
  const { e, p: P, q, r, m, n } = p;
  const right = inner(P * n + (r * n * n) / 2, e * n + (q * n * n) / 2);
  const cands = [
    { s: inner(P * m + (r * m * m) / 2, e * m + (q * m * m) / 2), kind: "wrong limits", msg: `The inner integral is in y, so it runs over y's range, 0 to ${n}.` },
    { s: inner(P * n + (r * n * n) / 2, e + (q * n * n) / 2), kind: "constant not spread", msg: `A constant height ${e} over a slice ${n} long adds ${e} × ${n}.` },
    { s: inner(P * n + r * n * n, e * n + q * n * n), kind: "no half", msg: "∫ y dy is y²/2. The half matters." },
    { s: inner(P + r * n, e + q * n), kind: "plugged in", msg: `Putting y = ${n} in gives one height, not a slice's area. Integrate in y.` },
    { s: inner(q * m + (r * m * m) / 2, e * m + (P * m * m) / 2, "y"), kind: "integrated x", msg: "The inner integral is in y with x held fixed. This one integrated in x." },
  ].filter(c => c.s !== right);
  const out = [{ s: right, kind: "right", msg: "" }];
  for (const c of cands) if (!out.some(o => o.s === c.s)) out.push(c);
  return out.slice(0, 4);
}
const vol05 = (p: P05) => p.e * p.m * p.n + (p.p * p.m * p.m * p.n) / 2 + (p.q * p.m * p.n * p.n) / 2 + (p.r * p.m * p.m * p.n * p.n) / 4;

export const mv05: B2Lesson<P05> = {
  id: "b2-mv-05", track: "mv", unit: 2, title: "Double integrals: volume under a surface",
  youCan: "find the volume under a surface over a rectangle by integrating one direction, then the other.",
  needs: ["c-riemann", "c-ftc", "b2-mv-01"],
  tools: ["volume", "surface"],
  play: { scene: "volume", props: { src: "x + y", x1: 2, y1: 2, n: 4 },
    say: "Boxes stand on an n × n grid under the surface, each as tall as the surface at its center. Drag n from 2 to 100; the running total settles on the true volume." },
  guess: { scene: "volume", props: { src: "x + y", x1: 2, y1: 2, n: 6, quiet: true }, kind: "slider", min: 0, max: 16, step: 0.5, start: 4, answer: 8, near: 1,
    format: x => sn(x),
    ask: "For z = x + y over the square 0 ≤ x ≤ 2, 0 ≤ y ≤ 2, set your guess for the volume.",
    reveal: "8. The average height is 2 (the height at the center, (1, 1)), over a base of area 4." },
  nameIt: {
    say: [
      "A double integral adds height × tiny area over a region.",
      "Over a rectangle, do it as two ordinary integrals: integrate in y with x held fixed (one slice's area), then add the slices in x.",
    ],
    formula: ["∬_R f dA = ∫ₐᵇ ∫_c^d f(x, y) dy dx", "average height = ∬_R f dA ÷ area of R"],
  },
  workIt: {
    reference: { e: 0, p: 1, q: 2, r: 1, m: 2, n: 3, ord: [0, 1, 2, 3] },
    generate(rng, i) {
      for (;;) {
        const easy = i < 3;
        const p: P05 = { e: rng.int(0, 5), p: rng.int(0, 3), q: rng.int(0, 3), r: easy ? 0 : rng.int(0, 2), m: easy ? rng.int(1, 2) : rng.int(1, 3), n: easy ? rng.int(1, 2) : rng.int(1, 3), ord: rng.shuffle([0, 1, 2, 3]) };
        if (!p.p && !p.q && !p.r) continue;
        if (opts05(p).length === 4) return p;
      }
    },
    show: p => `f(x, y) = ${terms([[p.e, ""], [p.p, "x"], [p.q, "y"], [p.r, "xy"]])} over **0 ≤ x ≤ ${p.m}, 0 ≤ y ≤ ${p.n}**. Answers as fractions.`,
    steps(p) {
      const o = opts05(p), L = lay(o.map(x => x.s), p.ord), V = vol05(p), A = p.m * p.n;
      const Vsq = p.e * p.m * p.m + (p.p * p.m ** 3) / 2 + (p.q * p.m ** 3) / 2 + (p.r * p.m ** 4) / 4;
      return [
        wholeStep("area", "Area of the base", A, { hint: `${p.m} × ${p.n}.` }),
        tapStep("inner", `Inner integral ∫₀${p.n === 1 ? "¹" : p.n === 2 ? "²" : "³"} f dy`, L.choices, L.at(0), { hint: "Hold x fixed and integrate each term in y, from 0 to the top of y's range.",
          slips: o.slice(1).map((c, k) => slip(c.kind, L.at(k + 1), c.msg)) }),
        fracStep("V", "Volume", V, { hint: "Integrate the inner result in x, from 0 to the end of x's range.",
          slips: [
            p.m !== p.n && slip("wrong limits", Vsq, `The inner integral is in y, so it runs over y's range, 0 to ${p.n}.`),
            p.e !== 0 && A !== 1 && slip("constant not spread", V - p.e * A + p.e, `A constant height ${p.e} over the whole base adds ${p.e} × area = ${p.e * A}.`),
          ] }),
        fracStep("avg", "Average height", V / A, { hint: `Volume ÷ area: ${fr(V)} ÷ ${A}.`,
          slips: [slip("volume", V, "Average height is volume divided by the area of the base.")] }),
      ];
    },
    scene: p => ({ scene: "volume", props: { src: `${p.e} + ${p.p}*x + ${p.q}*y + ${p.r}*x*y`, x1: p.m, y1: p.n, n: 8 } }),
  },
  oracle: p => {
    const f = F05(p), N = 200, dx = p.m / N, dy = p.n / N;
    let V = 0;
    for (let i = 0; i < N; i++) for (let j = 0; j < N; j++) V += f((i + 0.5) * dx, (j + 0.5) * dy) * dx * dy;
    return [p.m * p.n, p.ord.indexOf(0), V, V / (p.m * p.n)];
  },
  useIt: {
    say: ["How much earth sits in Two lakes above height −1, over −2 ≤ x ≤ 2, −1 ≤ y ≤ 1? Read it off the volume builder at n = 100.",
      "It's the earth you would move to flatten the plot: exactly 344/15, about 22.93."],
    saves: { name: "slabVolume", value: () => 344 / 15, note: "Two lakes above height −1 over [−2, 2] × [−1, 1]" },
    scene: { scene: "volume", props: { fn: "land", floor: -1, n: 100 } },
  },
  deeper: [
    "Fubini's theorem: if ∬|f| is finite, either order gives the same answer.",
    "Without that, it can fail: ∫₀¹∫₀¹ (x² − y²)/(x² + y²)² dy dx = π/4, but the other order gives −π/4.",
    "The cure is the Lebesgue integral, where volume is defined by measure: measure the set where f is above each height instead of slicing it.",
  ],
};

interface P06 { k: number; f: number; o2: number[]; o4: number[] }
const kx = (k: number) => terms([[k, "x"]]);
const yk = (k: number) => (k === 1 ? "y" : `y/${k}`);

export const mv06: B2Lesson<P06> = {
  id: "b2-mv-06", track: "mv", unit: 2, title: "Regions with curved edges, and swapping the order",
  youCan: "set up a double integral over a region with curved sides, in either order.",
  needs: ["c-areavg", "b2-mv-05"],
  tools: ["volume", "graph2d"],
  play: { scene: "sweep", props: { k: 2, dir: "v" },
    say: "The region between y = x² and y = kx is shaded. Drag the sweep line across it and watch its two ends ride the two curves; flip to a horizontal sweep and the ends ride different curves." },
  guess: { scene: "sweep", props: { pick: true, quiet: true }, kind: "choice", options: ["A", "B", "C", "D"], answer: 2,
    ask: "∫₀¹ ∫ₓ¹ g(x, y) dy dx covers which region?",
    revealProps: { paint: true },
    reveal: "C: the triangle above y = x and below y = 1. Each vertical slice starts on y = x and stops at y = 1, for x from 0 to 1." },
  nameIt: {
    say: [
      "For a curved region, the inner limits are curves: each vertical slice runs from the bottom curve to the top curve.",
      "To swap the order, describe the same region with horizontal slices.",
    ],
    formula: ["∬_R f dA = ∫ₐᵇ ∫_{g₁(x)}^{g₂(x)} f dy dx = ∫_c^d ∫_{h₁(y)}^{h₂(y)} f dx dy"],
  },
  workIt: {
    reference: { k: 2, f: 1, o2: [0, 1, 2, 3], o4: [0, 1, 2, 3] },
    generate(rng, i) {
      return { k: i < 3 ? rng.pick([1, 2]) : rng.pick([1, 2, 3]), f: i < 3 ? 0 : rng.int(0, 2), o2: rng.shuffle([0, 1, 2, 3]), o4: rng.shuffle([0, 1, 2, 3]) };
    },
    show: p => `The region between **y = x²** and **y = ${kx(p.k)}**. Integrand **f = ${["1", "x", "y"][p.f]}**. Answers as fractions.`,
    steps(p) {
      const k = p.k, V = [k ** 3 / 6, k ** 4 / 12, k ** 5 / 15][p.f]!, noLow = [k ** 3 / 2, k ** 4 / 3, k ** 5 / 6][p.f]!;
      const S = lay([`y = x² to y = ${kx(k)}`, `y = ${kx(k)} to y = x²`, `y = 0 to y = ${kx(k)}`, "y = 0 to y = x²"], p.o2);
      const T = lay([`y from 0 to ${k * k}, x from ${yk(k)} to √y`, `y from 0 to ${k}, x from ${yk(k)} to √y`, `y from 0 to ${k * k}, x from √y to ${yk(k)}`, `y from 0 to ${k * k}, x from 0 to ${k}`], p.o4);
      return [
        wholeStep("meet", "Where the curves meet (x > 0)", k, { hint: `x² = ${kx(k)}, so x = 0 or x = ${k}.` }),
        tapStep("slice", "A vertical slice runs from", S.choices, S.at(0), { hint: `Between 0 and ${k}, which curve is lower?`,
          slips: [
            slip("upside down", S.at(1), `Between 0 and ${k}, x² is below ${kx(k)}. Bottom curve first.`),
            slip("from 0", S.at(2), "That counts the area under the parabola too. Start each slice at y = x²."),
            slip("under parabola", S.at(3), `That's the area under the parabola. The region sits between it and y = ${kx(k)}.`),
          ] }),
        fracStep("I", "∬_R f dA", V, { hint: `∫₀${k === 1 ? "¹" : k === 2 ? "²" : "³"} ∫ from x² to ${kx(k)} of ${["1", "x", "y"][p.f]} dy dx.`,
          slips: [slip("upside down", -V, `A negative answer means the limits are upside down: x² is below ${kx(k)}.`),
            slip("from 0", noLow, "That counts the area under the parabola too. Start each slice at y = x².")] }),
        tapStep("swap", "With horizontal slices", T.choices, T.at(0), { hint: `On the line x = ${yk(k)}; on the parabola x = √y. y runs up to where they meet, ${k * k}.`,
          slips: [
            slip("kept x limits", T.at(1), `Outer limits must be numbers for y now: y goes from 0 to ${k * k}.`),
            slip("ends swapped", T.at(2), `Each horizontal slice starts on the line x = ${yk(k)} and ends on the parabola x = √y.`),
            slip("fixed ends", T.at(3), `The ends of a horizontal slice move with y: x = ${yk(k)} on the line, x = √y on the parabola.`),
          ] }),
      ];
    },
    scene: p => ({ scene: "sweep", props: { k: p.k, dir: "v" } }),
  },
  oracle: p => [p.k, p.o2.indexOf(0), [p.k ** 3 / 6, p.k ** 4 / 12, p.k ** 5 / 15][p.f]!, p.o4.indexOf(0)],
  useIt: {
    say: ["A lake's shoreline is a curve. On Two lakes, the contour f = 0 around the left valley bounds a curved region.",
      "The volume builder fills it with vertical slices whose ends sit on the shoreline. This is the region-filling engine the lake will use."],
    scene: { scene: "sweep", props: { fn: "land", dir: "v" } },
  },
  deeper: [
    "Some integrals are only possible after a swap: ∫₀¹ ∫ₓ¹ e^(y²) dy dx has no elementary inner antiderivative, but swapping gives ∫₀¹ y e^(y²) dy = (e − 1)/2.",
    "Fubini–Tonelli: for f ≥ 0 the swap is always allowed.",
    "A region's boundary has area zero, which is why its edges never change the answer.",
  ],
};

interface P07 { kind: number; a: number; b: number; n: number }
const ANG07 = [2, 1, 1 / 2, 2];
const REGION07 = (p: P07) => [`the full disk of radius ${p.b}`, `the upper half disk of radius ${p.b}`, `the quarter disk of radius ${p.b} where x, y ≥ 0`, `the ring ${p.a} ≤ r ≤ ${p.b}`][p.kind]!;

export const mv07: B2Lesson<P07> = {
  id: "b2-mv-07", track: "mv", unit: 2, title: "Polar double integrals",
  youCan: "integrate over disks, rings and wedges using polar boxes.",
  needs: ["bc-polar", "pc-polar", "b2-mv-06"],
  tools: ["volume", "surface"],
  play: { scene: "polar", props: { R: 2, rings: 4, wedges: 12 },
    say: "A disk is cut into polar boxes by rings and wedges. Drag the ring and wedge counts; tap a box to read its area. The outer boxes are bigger." },
  guess: { scene: "polar", props: { R: 2, rings: 6, wedges: 12, pair: true, quiet: true }, kind: "choice", options: ["1 time", "3 times", "9 times"], answer: 1,
    ask: "Two polar boxes have the same Δr and Δθ, and one is 3 times as far from the center. How many times bigger is its area?",
    reveal: "3 times. A polar box is Δr thick and rΔθ wide, so its area grows with r, not r²." },
  nameIt: {
    say: ["In polar coordinates a small box is about Δr thick and rΔθ wide, so its area is r Δr Δθ. The extra r is the stretch."],
    formula: ["dA = r dr dθ", "∬_R f dA = ∫∫ f(r cos θ, r sin θ) r dr dθ"],
  },
  workIt: {
    reference: { kind: 1, a: 0, b: 2, n: 2 },
    generate(rng, i) {
      if (i < 3) return { kind: rng.int(0, 1), a: 0, b: rng.int(1, 4), n: rng.pick([0, 2]) };
      const kind = rng.int(0, 3);
      if (kind === 3) { const a = rng.int(1, 3); return { kind, a, b: rng.int(a + 1, 4), n: rng.int(0, 2) }; }
      return { kind, a: 0, b: rng.int(1, 4), n: rng.int(0, 2) };
    },
    show: p => `Integrate **f = ${["1", "√(x² + y²)", "x² + y²"][p.n]}** over **${REGION07(p)}**. Give the value ÷ π as a fraction.`,
    steps(p) {
      const ang = ANG07[p.kind]!, e = p.n + 2;
      const val = (ang * (p.b ** e - p.a ** e)) / e, noR = (ang * (p.b ** (e - 1) - p.a ** (e - 1))) / (e - 1);
      const tIdx = p.kind === 3 ? 0 : p.kind;
      return [
        tapStep("th", "θ runs over", ["2π", "π", "π/2"], tIdx, { hint: "A full turn is 2π; a half disk is half a turn.",
          slips: [p.kind === 1 && slip("full turn", 0, "A half disk sweeps θ from 0 to π."), p.kind === 2 && slip("full turn", 0, "A quarter disk sweeps θ from 0 to π/2.")] }),
        multiStep("r", "r runs from … to …", [p.a, p.b], "whole", { boxes: ["from", "to"], hint: p.kind === 3 ? "The ring's inner and outer radius." : "From the center out to the edge." }),
        tapStep("dA", "Integrand with dA", ["r", "r²", "r³"], p.n, { hint: `${["1", "√(x² + y²) = r", "x² + y² = r²"][p.n]}, times the extra r from dA.`,
          slips: [p.n >= 1 && slip("no extra r", p.n - 1, "dA is r dr dθ. Without the r, the outer boxes count as small as the inner ones.")] }),
        fracStep("v", "Value ÷ π", val, { hint: `(θ range ÷ π) × ∫ r${["", "²", "³"][p.n]} dr = ${fr(ang)} × (${p.b}${["²", "³", "⁴"][p.n]}${p.a ? ` − ${p.a}${["²", "³", "⁴"][p.n]}` : ""})/${e}.`,
          slips: [
            slip("no extra r", noR, "dA is r dr dθ. Without the r, the outer boxes count as small as the inner ones."),
            (p.kind === 1 || p.kind === 2) && slip("full turn", (2 * (p.b ** e - p.a ** e)) / e, p.kind === 1 ? "A half disk sweeps θ from 0 to π." : "A quarter disk sweeps θ from 0 to π/2."),
            p.n === 2 && slip("x² + y² as r", (ang * (p.b ** 3 - p.a ** 3)) / 3, "x² + y² = r², not r."),
          ] }),
      ];
    },
    scene: p => ({ scene: "polar", props: { R: p.b, a: p.a, rings: 6, wedges: 12, part: p.kind } }),
  },
  oracle: p => {
    const ang = ANG07[p.kind]!, e = p.n + 2;
    return [p.kind === 3 ? 0 : p.kind, p.a, p.b, p.n, (ang * (p.b ** e - p.a ** e)) / e];
  },
  useIt: {
    say: ["A round pond on Two lakes is 1 − r² deep at distance r from its center (radius 1).",
      "It holds ∫₀^{2π} ∫₀¹ (1 − r²) r dr dθ = π/2 of water, in these units."],
    saves: { name: "pondVolume", value: () => Math.PI / 2, note: "a round pond 1 − r² deep, radius 1" },
    scene: { scene: "polar", props: { R: 1, rings: 8, wedges: 16, pond: true } },
  },
  deeper: [
    "The bell curve's area. Let I = ∫ e^(−x²) dx over the whole line. Then I² = ∬ e^(−(x² + y²)) dA over the plane = ∫₀^{2π} ∫₀^∞ e^(−r²) r dr dθ = π, so I = √π.",
    "That √π is the one in the normal distribution's 1/√(2π) (b2-pr-07). Extend the trick to n dimensions to get the volume of an n-ball.",
  ],
};

interface P08 { a: number; b: number; c: number; d: number; s: number; t: number }

export const mv08: B2Lesson<P08> = {
  id: "b2-mv-08", track: "mv", unit: 2, title: "Change of variables and the Jacobian",
  youCan: "turn a slanted region into a rectangle and fix the area with a determinant.",
  needs: ["b2-mv-07", "b2-la-07"],
  tools: ["warp", "matrix"],
  play: { scene: "warp", props: { a: 2, b: 1, c: 1, d: 3 },
    say: "A (u, v) grid sits on the left; its image in (x, y) bends on the right. Drag the map's four numbers. One small square is highlighted, with its image's area beside |det J|." },
  guess: { scene: "warp", props: { a: 2, b: 1, c: 1, d: 3, quiet: true }, kind: "slider", min: 0, max: 10, step: 0.5, start: 2, answer: 5, near: 0.5,
    format: x => sn(x),
    ask: "For x = 2u + v, y = u + 3v, what is the area of the image of the unit square?",
    reveal: "5. The square becomes a parallelogram with sides ⟨2, 1⟩ and ⟨1, 3⟩, and its area is |2·3 − 1·1| = 5." },
  nameIt: {
    say: [
      "A change of variables stretches every tiny square by the same factor locally: the absolute determinant of the Jacobian.",
      "Polar is one case, with factor r.",
    ],
    formula: ["dx dy = |det ∂(x, y)/∂(u, v)| du dv", "|det ∂(x, y)/∂(u, v)| = 1 / |det ∂(u, v)/∂(x, y)|"],
  },
  workIt: {
    reference: { a: 1, b: 1, c: 1, d: -1, s: 2, t: 4 },
    generate(rng, i) {
      for (;;) {
        const a = rng.int(-3, 3), b = rng.int(-3, 3), c = rng.int(-3, 3), d = rng.int(-3, 3), det = a * d - b * c;
        if (!det || (i < 3 && Math.abs(det) > 2)) continue;
        return { a, b, c, d, s: i < 3 ? rng.int(1, 4) : rng.int(1, 6), t: i < 3 ? rng.int(1, 4) : rng.int(1, 6) };
      }
    },
    show: p => `**u = ${terms([[p.a, "x"], [p.b, "y"]])}**, **v = ${terms([[p.c, "x"], [p.d, "y"]])}**. The region is 0 ≤ u ≤ ${p.s}, 0 ≤ v ≤ ${p.t}.`,
    steps(p) {
      const det = p.a * p.d - p.b * p.c, st = p.s * p.t;
      return [
        wholeStep("det", "det ∂(u, v)/∂(x, y)", det, { hint: `ad − bc = (${sn(p.a)})(${sn(p.d)}) − (${sn(p.b)})(${sn(p.c)}).`,
          slips: [slip("ad + bc", p.a * p.d + p.b * p.c, "The determinant is ad − bc.")] }),
        wholeStep("uv", "Area of the region in (u, v)", st, { hint: `It's a ${p.s} by ${p.t} rectangle.` }),
        fracStep("xy", "Area of the region in (x, y)", st / Math.abs(det), { hint: `Going back from (u, v) to (x, y) divides areas by |det| = ${Math.abs(det)}.`,
          slips: [
            slip("multiplied", st * Math.abs(det), `This map goes from (x, y) to (u, v), so it stretches x, y areas by ${Math.abs(det)}. Going back, divide.`),
            det < 0 && slip("kept the sign", st / det, "Area can't be negative. Use the absolute value of the determinant."),
          ] }),
      ];
    },
    scene: p => { const det = p.a * p.d - p.b * p.c; return { scene: "warp", props: { a: p.d / det, b: -p.b / det, c: -p.c / det, d: p.a / det, s: p.s, t: p.t } }; },
  },
  oracle: p => {
    const det = p.a * p.d - p.b * p.c, back = (u: number, v: number): [number, number] => [(p.d * u - p.b * v) / det, (-p.c * u + p.a * v) / det];
    const cs = [back(0, 0), back(p.s, 0), back(p.s, p.t), back(0, p.t)];
    let A = 0;
    for (let i = 0; i < 4; i++) { const [x1, y1] = cs[i]!, [x2, y2] = cs[(i + 1) % 4]!; A += x1 * y2 - x2 * y1; }
    return [det, p.s * p.t, Math.abs(A) / 2];
  },
  useIt: {
    say: ["Project 2, Fill the lake, opens. Pick a low spot of Two lakes and a water level.",
      "The volume builder fills the basin, using the curved regions from lesson 06, and reports the lake's volume and surface area. The build gains the lake."],
    project: "mv-lake",
  },
  deeper: [
    "In n dimensions dV = |det J| du₁…duₙ. Spherical coordinates give ρ² sin φ dρ dφ dθ.",
    "The volume of a unit n-ball is π^(n/2)/Γ(n/2 + 1), which shrinks to 0 as n grows.",
    "For densities, p_Y(y) = p_X(x)/|det J|: this is the rule behind normalizing flows in machine learning.",
  ],
};

/* ================================================================ unit 3 · Fields and flow ================================================================ */

interface P09 { quad: boolean; a: number; b: number; c: number; d: number; x0: number; y0: number }
function parts09(p: P09): { Px: number; Qy: number; Qx: number; Py: number } {
  if (!p.quad) return { Px: p.a, Qy: p.d, Qx: p.c, Py: p.b };
  return { Px: p.a * p.y0, Qy: p.c, Qx: 2 * p.b * p.x0, Py: p.a * p.x0 };
}
const F09 = (p: P09): [(x: number, y: number) => number, (x: number, y: number) => number] => p.quad
  ? [(x, y) => p.a * x * y, (x, y) => p.b * x * x + p.c * y]
  : [(x, y) => p.a * x + p.b * y, (x, y) => p.c * x + p.d * y];

export const mv09: B2Lesson<P09> = {
  id: "b2-mv-09", track: "mv", unit: 3, title: "Vector fields: spread and spin",
  youCan: "read a vector field and measure how much it spreads out and how much it spins.",
  needs: ["b2-mv-02", "b2-la-01"],
  tools: ["field", "matrix"],
  play: { scene: "field", props: { a: 0, b: -1, c: 1, d: 0 },
    say: "Arrows F(x, y) = ⟨P, Q⟩ cover the plane, and particles flow along them. Drag the paddle wheel to see it spin, or the drop of dye to see it spread or squeeze. Drag the field's four numbers." },
  guess: { scene: "field", props: { a: 0, b: -1, c: 1, d: 0, wx: 2, wy: 0, quiet: true }, kind: "choice", options: ["Counterclockwise", "Clockwise", "It doesn't spin"], answer: 0,
    ask: "In F = ⟨−y, x⟩, a paddle wheel sits at (2, 0), away from the center. Which way does it spin?",
    reveal: "Counterclockwise. The curl is 2 everywhere, not just at the center: the far side of the wheel is pushed harder than the near side." },
  nameIt: {
    say: [
      "A vector field puts an arrow at every point, like wind or water.",
      "Divergence measures how much it spreads out from a point; curl measures how much it spins a small wheel there (counterclockwise is positive).",
    ],
    formula: ["div F = P_x + Q_y", "curl F = Q_x − P_y"],
  },
  workIt: {
    reference: { quad: false, a: 2, b: 1, c: 3, d: -1, x0: 0, y0: 0 },
    generate(rng, i) {
      for (;;) {
        const quad = i >= 5 && rng.next() < 0.5, r = i < 3 ? 2 : 3;
        const p: P09 = { quad, a: rng.int(-r, r), b: rng.int(-r, r), c: rng.int(-r, r), d: quad ? 0 : rng.int(-r, r), x0: quad ? rng.int(-2, 2) : 0, y0: quad ? rng.int(-2, 2) : 0 };
        if (quad ? !p.a && !p.b && !p.c : !p.a && !p.b && !p.c && !p.d) continue;
        return p;
      }
    },
    show: p => p.quad
      ? `F = ⟨${terms([[p.a, "xy"]])}, ${terms([[p.b, "x²"], [p.c, "y"]])}⟩ at the point **${pt(p.x0, p.y0)}**.`
      : `F = ⟨${terms([[p.a, "x"], [p.b, "y"]])}, ${terms([[p.c, "x"], [p.d, "y"]])}⟩. It's linear, so the answers are the same at every point.`,
    steps(p) {
      const { Px, Qy, Qx, Py } = parts09(p), div = Px + Qy, curl = Qx - Py;
      return [
        multiStep("pq", "P_x and Q_y", [Px, Qy], "whole", { boxes: ["P_x", "Q_y"], hint: "P_x: differentiate the first part in x. Q_y: the second part in y.",
          slips: [slip("cross parts", [Py, Qx], "Divergence uses each component in its own direction: P along x, Q along y.")] }),
        wholeStep("div", "div F", div, { hint: "P_x + Q_y.", slips: [slip("cross parts", Py + Qx, "Divergence uses each component in its own direction: P_x + Q_y.")] }),
        multiStep("qp", "Q_x and P_y", [Qx, Py], "whole", { boxes: ["Q_x", "P_y"], hint: "Q_x: the second part in x. P_y: the first part in y." }),
        wholeStep("curl", "curl F", curl, { hint: "Q_x − P_y: counterclockwise is positive.",
          slips: [
            slip("clockwise", Py - Qx, "Counterclockwise is positive: Q_x − P_y."),
            slip("no spin", 0, `Arrows can spin a wheel even when they all point one way, if they're faster on one side. Here Q_x − P_y = ${sn(curl)}.`),
          ] }),
        tapStep("dye", "The dye", ["Spreads", "Squeezes", "Neither"], div > 0 ? 0 : div < 0 ? 1 : 2, { hint: "The sign of div F says it.",
          slips: [div !== 0 && slip("used curl", curl > 0 ? 0 : curl < 0 ? 1 : 2, "Dye spreads or squeezes with the divergence, not the curl.")] }),
      ];
    },
    scene: (p): SceneRef => p.quad
      ? { scene: "field", props: { P: `${ex(p.a)}*x*y`, Q: `${ex(p.b)}*x^2 + ${ex(p.c)}*y`, wx: p.x0, wy: p.y0 } }
      : { scene: "field", props: { a: p.a, b: p.b, c: p.c, d: p.d } },
  },
  oracle: p => {
    const [P, Q] = F09(p), X = p.x0, Y = p.y0;
    const Px = cd(h => P(X + h, Y)), Qy = cd(h => Q(X, Y + h)), Qx = cd(h => Q(X + h, Y)), Py = cd(h => P(X, Y + h)), div = Px + Qy;
    return [Px, Qy, div, Qx, Py, Qx - Py, Math.abs(div) < 1e-6 ? 2 : div > 0 ? 0 : 1].map(v => Math.round(v));
  },
  useIt: {
    say: ["Turn on the water layer for Two lakes: the field −∇f, water running downhill.",
      "Its divergence is −(f_xx + f_yy), so dye squeezes in the valley bottoms and spreads on the hump between them, near the pass. The build gains the flow layer."],
    scene: { scene: "field", props: { fn: "land", wx: -1, wy: 0 } },
  },
  deeper: [
    "In 3D, curl is a vector ∇ × F and div is ∇ · F, with the identities ∇ · (∇ × F) = 0 and ∇ × (∇f) = 0.",
    "For a linear field F = Ax, div F = trace A, and the curl comes from the antisymmetric part of A (la).",
    "Helmholtz decomposition: a nice field is a gradient plus a curl.",
  ],
};

interface P10 { loop: boolean; a: number; b: number; c: number; d: number; p: number; q: number; m: number; n: number }

export const mv10: B2Lesson<P10> = {
  id: "b2-mv-10", track: "mv", unit: 3, title: "Line integrals, work and Green's theorem",
  youCan: "add up a field's push along a path, and around a loop using the spin inside.",
  needs: ["b2-mv-09", "b2-mv-04", "bc-vector"],
  tools: ["field", "hiker"],
  play: { scene: "field", props: { a: 0, b: -1, c: 1, d: 0, mode: "loop" },
    say: "A loop sits in a force field. At each point the push along the path is drawn as a bar, and the work meter adds it up. A second meter adds curl × area inside; drag the loop and the field, and the two meters agree." },
  guess: { scene: "field", props: { a: 1, b: 0, c: 0, d: 1, mode: "loop", lx: 0, ly: 0, lr: 1, quiet: true }, kind: "choice", options: ["Positive", "Negative", "Zero"], answer: 2,
    ask: "Going once counterclockwise around the unit circle, what is the total work of F = ⟨x, y⟩?",
    reveal: "Zero: F = ⟨x, y⟩ points straight out, so it never pushes along the circle. Switch to F = ⟨−y, x⟩ and the meters read 2π, curl 2 times area π." },
  nameIt: {
    say: [
      "Work adds the part of the field that points along your path.",
      "Around a closed loop, the total equals all the small spins inside, added up: Green's theorem.",
    ],
    formula: ["W = ∫_C F · dr = ∫ (P x′(t) + Q y′(t)) dt", "∮_C F · dr = ∬_R (Q_x − P_y) dA, counterclockwise"],
  },
  workIt: {
    reference: { loop: false, a: 0, b: 1, c: 2, d: 0, p: 1, q: 2, m: 0, n: 0 },
    generate(rng, i) {
      for (;;) {
        const loop = i >= 3 && rng.next() < 0.5;
        const p: P10 = { loop, a: rng.int(-2, 2), b: rng.int(-2, 2), c: rng.int(-2, 2), d: rng.int(-2, 2), p: 0, q: 0, m: 0, n: 0 };
        if (!p.a && !p.b && !p.c && !p.d) continue;
        if (loop) { p.m = rng.int(1, 4); p.n = rng.int(1, 4); return p; }
        const r = i < 3 ? [0, 2] : [-3, 3];
        p.p = rng.int(r[0]!, r[1]!); p.q = rng.int(r[0]!, r[1]!);
        if (!p.p && !p.q) continue;
        return p;
      }
    },
    show: p => {
      const F = `F = ⟨${terms([[p.a, "x"], [p.b, "y"]])}, ${terms([[p.c, "x"], [p.d, "y"]])}⟩`;
      return p.loop ? `${F}, once counterclockwise around the rectangle **0 ≤ x ≤ ${p.m}, 0 ≤ y ≤ ${p.n}**.`
        : `${F}, along the straight segment from **(0, 0)** to **${pt(p.p, p.q)}**: r(t) = ⟨${terms([[p.p, "t"]])}, ${terms([[p.q, "t"]])}⟩ for 0 ≤ t ≤ 1.`;
    },
    steps(p) {
      if (!p.loop) {
        const k = p.a * p.p * p.p + (p.b + p.c) * p.p * p.q + p.d * p.q * p.q;
        return [
          wholeStep("k", "F · r′(t) = kt, k =", k, { hint: `At r(t) the field is ${vec(p.a * p.p + p.b * p.q, p.c * p.p + p.d * p.q)}t, and r′ = ${vec(p.p, p.q)}. Dot them.` }),
          fracStep("W", "W", k / 2, { hint: `∫₀¹ ${terms([[k, "t"]])} dt.`,
            slips: [slip("forgot ∫t dt", k, `Along the segment the push grows like t. ∫₀¹ kt dt = k/2.`)] }),
        ];
      }
      const curl = p.c - p.b, div = p.a + p.d, A = p.m * p.n;
      return [
        wholeStep("curl", "curl F", curl, { hint: "Q_x − P_y.",
          slips: [slip("used div", div, "Work around a loop counts spin, Q_x − P_y, not spread."), slip("clockwise", -curl, "Counterclockwise is positive: Q_x − P_y.")] }),
        wholeStep("area", "Area inside", A, { hint: `${p.m} × ${p.n}.` }),
        wholeStep("W", "Work around the loop", curl * A, { hint: "Green: curl × area, since the curl is the same everywhere inside.",
          slips: [slip("used div", div * A, "Work around a loop counts spin, Q_x − P_y, not spread."),
            slip("sign flipped", -curl * A, "Green's theorem as written is for counterclockwise. Clockwise flips the sign.")] }),
      ];
    },
    scene: (p): SceneRef => ({ scene: "field", props: p.loop ? { a: p.a, b: p.b, c: p.c, d: p.d, mode: "loop", rect: true, lx: p.m / 2, ly: p.n / 2, lw: p.m, lh: p.n }
      : { a: p.a, b: p.b, c: p.c, d: p.d, mode: "path", ex: p.p, ey: p.q } }),
  },
  oracle: p => {
    const P = (x: number, y: number) => p.a * x + p.b * y, Q = (x: number, y: number) => p.c * x + p.d * y;
    const along = (x0: number, y0: number, x1: number, y1: number) => {
      const N = 10000; let W = 0;
      for (let i = 0; i <= N; i++) { const t = i / N, x = x0 + (x1 - x0) * t, y = y0 + (y1 - y0) * t, w = i === 0 || i === N ? 0.5 : 1; W += w * (P(x, y) * (x1 - x0) + Q(x, y) * (y1 - y0)) / N; }
      return W;
    };
    const half = (x: number) => Math.round(x * 2) / 2;
    if (!p.loop) { const W = along(0, 0, p.p, p.q); return [Math.round(2 * W), half(W)]; }
    const W = along(0, 0, p.m, 0) + along(p.m, 0, p.m, p.n) + along(p.m, p.n, 0, p.n) + along(0, p.n, 0, 0);
    return [Math.round(cd(h => Q(h, 0)) - cd(h => P(0, h))), p.m * p.n, half(W)];
  },
  useIt: {
    say: ["Haul a cart along two different trails between the same two spots of Two lakes, against gravity, the field −∇f.",
      "Both meters read the same: the work you do is the height difference, and the field does minus it. Note the rule this hints at; lesson 12 names it. The build gains the work meter."],
    scene: { scene: "field", props: { fn: "land", mode: "carts" } },
  },
  deeper: [
    "Stokes' theorem ∮ F · dr = ∬ (∇ × F) · n dS and the divergence theorem ∯ F · n dS = ∭ ∇ · F dV are the same statement as Green's: ∫ over ∂M of ω = ∫ over M of dω, in the language of differential forms.",
    "Green's theorem in flux form gives the shoelace area formula.",
    "Gravity's field is a gradient, which is why orbits conserve energy (or).",
  ],
};

export const LESSONS_A = [mv01, mv02, mv03, mv04, mv05, mv06, mv07, mv08, mv09, mv10];
