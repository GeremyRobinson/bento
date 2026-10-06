// Unit 4 · Nonlinear worlds: b2-de-12 to b2-de-15 (curriculum/specs/bento2/diffeq.md). de-15 is the track's Deeper
// lesson: off the build's path on the map.
import type { B2Lesson, B2Step, SceneRef } from "../../model";
import { fracStep, multiStep, numStep, slip, tapStep, wholeStep } from "../../make";
import { dn, fr, sn, terms } from "./text";
import { sirPeak, TYPES } from "./maths";

/* ------------------------------------------------------------------ de-12 ------------------------------------------------------------------ */

export interface P12 { a: number; b: number }
const SIX = TYPES.slice(0, 6);

export const de12: B2Lesson<P12> = {
  id: "b2-de-12", track: "de", unit: 4, title: "Linearize at a rest point",
  youCan: "find the rest points of a nonlinear system and classify each one by its Jacobian.",
  needs: ["b2-de-08", "b2-mv-02", "b2-mv-03", "b2-mv-08"],
  tools: ["nonlinear", "matrix"],
  play: { scene: "nonlinear", props: { sys: "pend", b: 0 },
    say: "The full pendulum on its phase plane. Zoom into a rest point and the curved flow straightens into a linear portrait from de-08. Drag the friction up from zero: the bottom turns from a center into a spiral, while the top stays a saddle." },
  guess: { scene: "nonlinear", props: { sys: "pend", b: 0.3, quiet: true }, kind: "choice", options: ["Spiral", "Saddle", "Center"], answer: 1,
    ask: "Zoom into the pendulum standing straight up (θ = π). Which portrait do you see?",
    revealProps: { zoomAt: 1, zoom: 4 },
    reveal: "A saddle. Near the top, sin θ ≈ −(θ − π), so gravity pushes away: J = [[0, 1], [g/L, −β]] has D = −g/L < 0." },
  nameIt: {
    say: [
      "Near a rest point, a nonlinear system acts like its best linear approximation: the Jacobian matrix of partial derivatives.",
      "Classify the Jacobian with T and D, just as in de-08.",
    ],
    formula: ["x′ = f(x, y), y′ = g(x, y)", "J = [[f_x, f_y], [g_x, g_y]] at the rest point"],
  },
  workIt: {
    reference: { a: 4, b: 1 },
    generate(rng, i) {
      if (i < 3) return { a: rng.pick([1, 4]), b: 1 };
      for (;;) { const a = rng.pick([1, 4, 9]), b = rng.pick([0, 1, 2]); if (!(a === 1 && b === 2)) return { a, b }; }
    },
    show: p => `**x′ = y, y′ = ${terms([[-p.a, "x"], [1, "x³"], [-p.b, "y"]])}**.`,
    steps(p): B2Step[] {
      const r = Math.sqrt(p.a), J21 = -p.a + 3 * p.a, D = -J21, origin = p.b === 0 ? 5 : 3;
      return [
        multiStep("rest", "Rest points", [-r, 0, r], "whole", { boxes: ["smallest", "middle", "largest"], ask: "y = 0, and −ax + x³ = 0. The x values, smallest first.",
          hint: `x(x² − ${p.a}) = 0.`,
          slips: [slip("only the root", [-p.a, 0, p.a], `x² = ${p.a}, so x = ±√${p.a} = ±${r}.`)] }),
        wholeStep("J", `J at (${r}, 0), lower-left`, J21, { ask: "∂/∂x of −ax + x³ − by, at the rest point.", hint: `−a + 3x² at x = ${r}.`,
          slips: [
            slip("forgot x³", -p.a, `Differentiate −ax + x³ in x: −a + 3x². At x = ${r} that's ${sn(-p.a)} + ${3 * p.a} = ${J21}.`),
            slip("plugged in first", -p.a + p.a * r, "Take partial derivatives first, then put in the point."),
          ] }),
        wholeStep("D", "D there", D, { ask: `J = [[0, 1], [${J21}, ${sn(-p.b)}]].`, hint: `D = 0 × ${sn(-p.b)} − 1 × ${J21}.`,
          slips: [slip("ad + bc", J21, "D = ad − bc: here 0 − 1 × the lower-left entry.")] }),
        tapStep("t1", `Type at (${r}, 0)`, SIX, 0, { hint: "D < 0.",
          slips: [slip("saddle stable", 1, "D < 0 always means a saddle, whatever T is."), slip("saddle stable", 3, "D < 0 always means a saddle, whatever T is.")] }),
        tapStep("t0", "Type at (0, 0)", SIX, origin, { hint: `J = [[0, 1], [${sn(-p.a)}, ${sn(-p.b)}]]: T = ${sn(-p.b)}, D = ${p.a}, T² − 4D = ${p.b * p.b - 4 * p.a}.`,
          slips: [
            p.b > 0 && slip("friction ignored", 5, `Friction makes T = ${sn(-p.b)} negative, so every loop shrinks: spiral in.`),
            p.b > 0 && slip("node or spiral", 1, `T² − 4D = ${p.b * p.b - 4 * p.a} is negative, so the eigenvalues are complex: it spirals.`),
            p.b === 0 && slip("center spirals", 3, "With no friction T = 0 and D > 0: a center. Loops close."),
          ] }),
      ];
    },
    scene: p => ({ scene: "nonlinear", props: { sys: "duff", a: p.a, b: p.b, quiet: true } }),
  },
  oracle: p => {
    const r = Math.sqrt(p.a), T0 = -p.b, D0 = p.a, q = T0 * T0 - 4 * D0;
    return [-r, 0, r, 2 * p.a, -2 * p.a, 0, q < 0 ? (T0 < 0 ? 3 : 5) : 1];
  },
  useIt: {
    say: [
      "The full pendulum's phase portrait goes into the build: stable spirals at θ = 0, 2π, …, saddles at θ = ±π, and the separatrix between swinging and spinning.",
      "Turn the friction to zero to see the separatrix as a sharp eye shape, then back up to watch every swing spiral into a bottom.",
    ],
    scene: { scene: "nonlinear", props: { sys: "pend", b: 0.2 } },
  },
  deeper: [
    "Hartman–Grobman: near a rest point whose Jacobian has no eigenvalue on the imaginary axis, the flow is a continuous deformation of the linear one. When it does, linearization can lie: a linear center can be a slow nonlinear spiral either way.",
    "Lyapunov functions: an energy that only goes down along paths proves stability without solving anything. For the pendulum with friction, E = ½θ′² + (g/L)(1 − cos θ) works.",
    "Poincaré–Bendixson: in the plane, bounded paths that avoid rest points end on a closed loop, so planar flows can't be chaotic. Limit cycles (van der Pol) and Hopf bifurcations are how loops are born.",
  ],
};

/* ------------------------------------------------------------------ de-13 ------------------------------------------------------------------ */

export interface P13 { a: number; c: number; xs: number; ys: number }
const RATES = [0.5, 1, 2];

export const de13: B2Lesson<P13> = {
  id: "b2-de-13", track: "de", unit: 4, title: "Predator and prey",
  youCan: "find the rest point of a predator–prey system and the period of its cycles near rest.",
  needs: ["b2-de-12", "b2-de-07"],
  tools: ["species", "plane"],
  play: { scene: "species", props: { a: 1, b: 0.05, c: 0.5, d: 0.01, x0: 70, y0: 20 },
    say: "Rabbits and foxes as two time graphs and as a loop in the phase plane. Tap the plane to set the starting numbers and watch closed loops of every size around one rest point. Fox peaks come about a quarter-cycle after rabbit peaks." },
  guess: { scene: "species", props: { a: 1, b: 0.05, c: 0.5, d: 0.01, x0: 70, y0: 20, quiet: true }, kind: "point", answer: [50, 40], near: 8, start: [50, 20],
    ask: "Raise the rabbits' birth rate a from 1 to 2. Where does the rest point move? Drag it.",
    revealProps: { a: 2, newRest: true },
    reveal: "The rest point jumps to (50, 40): more foxes, the same number of rabbits. The rabbits' rest level c/d doesn't involve a at all." },
  nameIt: {
    say: [
      "Prey grow and get eaten; predators starve and eat. Each species' rest level is set by the other's numbers.",
      "Near rest, the populations cycle with a period set by the two growth rates.",
    ],
    formula: ["x′ = ax − bxy, y′ = −cy + dxy", "rest point (c/d, a/b)", "period near rest 2π/√(ac)"],
  },
  workIt: {
    reference: { a: 1, c: 0.5, xs: 50, ys: 20 },
    generate(rng, i) {
      return { a: i < 3 ? 1 : rng.pick(RATES), c: i < 3 ? 1 : rng.pick(RATES), xs: rng.pick([20, 40, 50, 100]), ys: rng.pick([10, 20, 25]) };
    },
    show: p => {
      const b = p.a / p.ys, d = p.c / p.xs;
      return `Rabbits x and foxes y: **x′ = ${terms([[p.a, "x"], [-b, "xy"]], dn)}, y′ = ${terms([[-p.c, "y"], [d, "xy"]], dn)}**, time in years.`;
    },
    steps(p) {
      const b = p.a / p.ys, d = p.c / p.xs, D = p.a * p.c;
      return [
        wholeStep("x", "Prey at rest", p.c / d, { ask: "Foxes hold steady when −c + dx = 0.", hint: `x* = c/d = ${dn(p.c)}/${dn(d)}.`,
          slips: [slip("a/b", p.a / b, "Prey hold steady when predators neither grow nor shrink, so it's the predator's numbers, c/d, that fix the prey level.")] }),
        wholeStep("y", "Predators at rest", p.a / b, { ask: "Rabbits hold steady when a − by = 0.", hint: `y* = a/b = ${dn(p.a)}/${dn(b)}.`,
          slips: [slip("c/d", p.c / d, "Rabbits hold steady when a − by = 0: the foxes' level is a/b.")] }),
        fracStep("D", "D of the Jacobian at rest", D, { ask: "J = [[0, −bx*], [dy*, 0]], so D = bd·x*y*.", hint: `bd·x*y* = (a/y*)(c/x*)·x*y* = ac = ${fr(p.a)} × ${fr(p.c)}.`,
          slips: [slip("bd", b * d, "D = bd·x*·y*. With x* = c/d and y* = a/b that's ac.")] }),
        numStep("T", "Period near rest", (2 * Math.PI) / Math.sqrt(D), 2, { unit: "years", hint: `The turning rate is √D: 2π/√${dn(D)}.`,
          slips: [slip("2π/(ac)", (2 * Math.PI) / D, "The turning rate is √D = √(ac). The period is 2π/√(ac).")] }),
        tapStep("loop", "Over many cycles, the loops", ["Close up", "Spiral in"], 0, { hint: "The model has a conserved quantity.",
          slips: [slip("spiral in", 1, "Lotka–Volterra keeps a conserved quantity, so every loop closes. Real data spirals because the model leaves things out.")] }),
      ];
    },
    scene: p => ({ scene: "species", props: { a: p.a, b: p.a / p.ys, c: p.c, d: p.c / p.xs, x0: p.xs * 1.4, y0: p.ys, quiet: true } }),
  },
  oracle: p => {
    const b = p.a / p.ys, d = p.c / p.xs;
    return [p.c / d, p.a / b, b * d * (p.c / d) * (p.a / b), (2 * Math.PI) / Math.sqrt(p.a * p.c), 0];
  },
  useIt: {
    say: [
      "The Hudson's Bay Company's fur records show lynx and hare numbers rising and crashing on about a 10-year cycle.",
      "Fit a and c so the period is about 10 years (ac ≈ 0.39), and the second species joins the population half of the build.",
    ],
    scene: { scene: "species", props: { a: 0.6, b: 0.02, c: 0.65, d: 0.013, x0: 80, y0: 30, lynx: true } },
  },
  deeper: [
    "The conserved quantity V = dx − c ln x + by − a ln y is the same all along a path, so the loops are its level curves, a contour map (b2-mv-01).",
    "Add prey crowding (logistic prey) and the loops spiral in to rest. Use a predator that gets full (Holling type II, the Rosenzweig–MacArthur model) and a Hopf bifurcation creates a limit cycle: richer food makes the cycles wilder, the paradox of enrichment.",
    "Two species competing for one food can't both survive unless each limits itself more than the other: competitive exclusion.",
  ],
};

/* ------------------------------------------------------------------ de-14 ------------------------------------------------------------------ */

export interface P14 { beta: number; D: number }
const PAIRS: [number, number][] = [[0.5, 4], [0.5, 5], [0.6, 5], [0.4, 10], [0.5, 10], [0.75, 4]];
const EASY14: [number, number][] = [[0.5, 4], [0.4, 10], [0.5, 10]];

export const de14: B2Lesson<P14> = {
  id: "b2-de-14", track: "de", unit: 4, title: "Epidemics: the SIR model",
  youCan: "compute R₀, the herd-immunity threshold and the size of an epidemic's peak.",
  needs: ["b2-de-12", "b2-de-04"],
  tools: ["sir", "flow"],
  play: { scene: "sir", props: { beta: 0.4, D: 10, vax: 0 },
    say: "S, I and R curves for a town. Drag the contact rate β and the infectious days D. The I curve rises and falls, and its peak always comes exactly when S crosses the herd-immunity line. Drag the vaccination slider and watch the outbreak shrink to nothing." },
  guess: { scene: "sir", props: { beta: 0.4, D: 10, vax: 0, quiet: true }, kind: "slider", min: 0, max: 1, step: 0.01, start: 0.5, answer: 0.25, near: 0.04,
    format: x => `${Math.round(x * 100)}% of the town`,
    ask: "Infections peak at the moment S falls to what fraction of the town? Here β = 0.4 a day and D = 10 days.",
    revealProps: {},
    reveal: "R₀ = 4, and the peak comes when S/N = 1/R₀ = 25%: from then on each case makes fewer than one new one." },
  nameIt: {
    say: [
      "Each infected person makes β contacts a day for D days, so they infect R₀ = βD others in a fully susceptible town.",
      "Infections grow while R₀·(S/N) > 1, so they peak when S/N = 1/R₀, and vaccinating more than 1 − 1/R₀ stops outbreaks.",
    ],
    formula: ["S′ = −βSI/N, I′ = βSI/N − γI, R′ = γI", "γ = 1/D, R₀ = β/γ = βD", "peak I/N = 1 − (1 + ln R₀)/R₀"],
  },
  workIt: {
    reference: { beta: 0.4, D: 10 },
    generate(rng, i) { const [beta, D] = rng.pick(i < 3 ? EASY14 : PAIRS); return { beta, D }; },
    show: p => `A town where each case makes **β = ${dn(p.beta)}** contacts a day and stays infectious **D = ${p.D} days**.`,
    steps(p) {
      const R0 = Math.round(p.beta * p.D * 100) / 100;
      return [
        fracStep("R0", "R₀", R0, { hint: `Contacts a day times days: ${dn(p.beta)} × ${p.D}.`,
          slips: [slip("β/D", p.beta / p.D, "R₀ is contacts per day times days infectious: β × D.")] }),
        numStep("herd", "Herd-immunity threshold", 100 * (1 - 1 / R0), 1, { unit: "%", hint: `1 − 1/R₀ = 1 − 1/${dn(R0)}, as a percent.`,
          slips: [slip("1/R₀", 100 / R0, "1/R₀ is the fraction that can stay susceptible. You need to protect the rest: 1 − 1/R₀.")] }),
        fracStep("S", "S at the peak, as a fraction of the town", 1 / R0, { hint: "New cases balance recoveries when R₀·S/N = 1.",
          slips: [slip("half", 1 / 2, "The peak is when new cases just balance recoveries, which happens when S/N = 1/R₀."), slip("1 − 1/R₀", 1 - 1 / R0, "That's the herd-immunity threshold. S at the peak is what's left: 1/R₀.")] }),
        numStep("I", "Peak infected", 100 * sirPeak(R0), 1, { unit: "%", hint: `1 − (1 + ln ${dn(R0)})/${dn(R0)}, as a percent.`,
          slips: [slip("half", 50, "The peak is when new cases just balance recoveries, not when half the town is sick."), slip("threshold", 100 * (1 - 1 / R0), "That's the herd-immunity threshold. The peak's size is 1 − (1 + ln R₀)/R₀.")] }),
      ];
    },
    scene: p => ({ scene: "sir", props: { beta: p.beta, D: p.D, vax: 0, quiet: true } }),
  },
  oracle: p => { const R0 = p.beta * p.D; return [R0, 100 * (1 - 1 / R0), 1 / R0, 100 * (1 - (1 + Math.log(R0)) / R0)]; },
  useIt: {
    say: [
      "Project: the Outbreak planner. Set the contact rate and infectious days for a disease, then the vaccination fraction, and watch R₀, the herd-immunity line and the peak. Saves `R0` and `vax_needed`.",
      "Then the build: your pendulum and your population, running side by side.",
    ],
    project: "de-outbreak",
  },
  deeper: [
    "The quantity I + S − (N/R₀)ln S stays constant along the epidemic. Set S = N/R₀ at the peak and S ≈ N at the start, and the peak formula drops out.",
    "The final size s∞ (the fraction never infected) solves s∞ = e^(−R₀(1 − s∞)), which the Lambert W function solves exactly. With R₀ = 2, 80% of the town is infected in the end.",
    "SEIR adds an exposed stage, and with several groups R₀ becomes the spectral radius of the next-generation matrix (b2-la-14). Early on, a single case is a branching process that dies out with probability 1/R₀ (b2-pr-19). On networks, the hubs matter most.",
  ],
};

/* ------------------------------------------------------------------ de-15 ------------------------------------------------------------------ */

export type P15 = { kind: 0; r: number } | { kind: 1; k: number; G: number };
const RS = [3 / 2, 2, 5 / 2, 10 / 3, 7 / 2];
const SUP: Record<string, string> = { "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹" };
const tenTo = (k: number) => `10⁻${String(k).replace(/./g, ch => SUP[ch]!)}`;

export const de15: B2Lesson<P15> = {
  id: "b2-de-15", track: "de", unit: 4, title: "Chaos", optional: true,
  youCan: "find the fixed point of the logistic map, test its stability, and count how fast two nearby starts fall apart.",
  needs: ["b2-de-01", "b2-de-12", "b2-de-11"],
  tools: ["chaos", "pendulum", "graph3d"],
  play: { scene: "chaos", props: { r: 2.8, view: "twins" },
    say: "Two driven, damped pendulums start a hair apart (0.001°). For a while they swing together, then suddenly not at all. Switch to the cobweb: drag r from 2.5 to 4 and watch one point become 2, then 4, then a blur." },
  guess: { scene: "chaos", props: { r: 4, view: "gap", quiet: true }, kind: "slider", min: 0, max: 30, step: 1, start: 8, answer: 17, near: 1, unit: "steps",
    ask: "The gap between two starts doubles every step. Starting 10⁻⁶ apart (one millionth), how many steps until they differ by 0.1?",
    revealProps: { run: true },
    reveal: "log₂(0.1 / 10⁻⁶) = log₂ 100,000 ≈ 16.6, so step 17. At r = 4 the two real starts split right on schedule." },
  nameIt: {
    say: [
      "Chaos is a deterministic rule whose future you can't predict, because tiny differences grow exponentially.",
      "The logistic map shows it in one line.",
    ],
    formula: ["xₙ₊₁ = rxₙ(1 − xₙ)", "fixed point x* = 1 − 1/r, stable when |f′(x*)| = |2 − r| < 1", "a doubling gap reaches G from g after log₂(G/g) steps"],
  },
  workIt: {
    reference: { kind: 0, r: 5 / 2 },
    generate(rng, i) {
      if (i < 3) return { kind: 0, r: rng.pick([3 / 2, 2, 5 / 2]) };
      return rng.next() < 0.5 ? { kind: 0, r: rng.pick(RS) } : { kind: 1, k: rng.int(4, 10), G: rng.pick([0.1, 0.5]) };
    },
    show: p => (p.kind === 0
      ? `The logistic map **xₙ₊₁ = rxₙ(1 − xₙ)** with **r = ${fr(p.r)}**.`
      : `Two starts are **${tenTo(p.k)}** apart, and the gap doubles every step. When is it at least **${dn(p.G)}**?`),
    steps(p): B2Step[] {
      if (p.kind === 1) {
        const n = Math.ceil(Math.log2(p.G * 10 ** p.k));
        return [wholeStep("n", "Steps", n, { ask: `The smallest whole n with 2ⁿ × ${tenTo(p.k)} ≥ ${dn(p.G)}.`, hint: `log₂(${dn(p.G)} × 10${String(p.k).replace(/./g, ch => SUP[ch]!)}), rounded up.`,
          slips: [
            slip("rounded down", n - 1, `After ${n - 1} doublings the gap is still under the target. You need the next whole step.`),
            slip("powers of ten", p.k - 1, "Count doublings, not powers of ten: each step only multiplies the gap by 2."),
          ] })];
      }
      const x = 1 - 1 / p.r, s = 2 - p.r, st = Math.abs(s) < 1 ? 0 : 1;
      return [
        fracStep("x", "Fixed point", x, { ask: "Solve x = rx(1 − x). As a fraction.", hint: `Divide by x: 1 = r(1 − x), so x = 1 − 1/r = 1 − ${fr(1 / p.r)}.`,
          slips: [slip("1/r", 1 / p.r, "Solve x = rx(1 − x): divide by x to get 1 = r(1 − x), so x = 1 − 1/r.")] }),
        fracStep("s", "Slope there", s, { ask: "f′(x) = r(1 − 2x). At x*, that's 2 − r. As a fraction.", hint: `2 − ${fr(p.r)}.`,
          slips: [slip("r − 2", p.r - 2, "f′(x*) = r(1 − 2(1 − 1/r)) = r(2/r − 1) = 2 − r.")] }),
        tapStep("st", "Stable?", ["Yes", "No"], st, { hint: "Stable when |2 − r| < 1.",
          slips: [st === 1 && slip("called it stable", 0, `|2 − ${fr(p.r)}| = ${fr(Math.abs(s))} > 1. The fixed point repels, and the orbit settles into a cycle instead.`)] }),
      ];
    },
    scene: (p): SceneRef => (p.kind === 0 ? { scene: "chaos", props: { r: p.r, view: "cobweb" } } : { scene: "chaos", props: { r: 4, view: "gap", k: p.k } }),
  },
  oracle: p => (p.kind === 0 ? [1 - 1 / p.r, 2 - p.r, Math.abs(2 - p.r) < 1 ? 0 : 1] : [Math.ceil(Math.log2(p.G * 10 ** p.k))]),
  useIt: {
    say: [
      "Weather: if forecast errors double every 2 days, a 100 times better measurement buys log₂ 100 ≈ 6.6 doublings, about 13 days. A thousand times better buys only 20.",
      "Then drive the build's pendulum hard enough to go chaotic, and save that setting to the Notebook.",
    ],
    scene: { scene: "chaos", props: { view: "twins", saveable: true } },
  },
  deeper: [
    "The Lorenz system (σ = 10, ρ = 28, β = 8/3) never settles and never repeats: its strange attractor has fractal dimension about 2.06. Lyapunov exponents measure the doubling rate exactly; for the logistic map at r = 4 it is ln 2 per step.",
    "Feigenbaum's constant 4.669…, the ratio of successive period-doubling gaps, is the same for every one-hump map with a rounded top. \"Period three implies chaos\" (Li–Yorke), and Sharkovskii's ordering says which cycles force which.",
    "Kolmogorov–Sinai entropy measures chaos in bits per step (b2-in-03). Shadowing explains why simulations of chaotic systems are still trustworthy in a statistical sense. The three-body problem is chaotic too (b2-or-07).",
  ],
};
