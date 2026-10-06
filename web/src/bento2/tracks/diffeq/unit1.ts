// Unit 1 · One equation, read without solving: b2-de-01 to b2-de-04 (curriculum/specs/bento2/diffeq.md).
import type { B2Lesson, B2Step, SceneRef } from "../../model";
import { fracStep, multiStep, numStep, slip, tapStep, wholeStep } from "../../make";
import { factor, fr, pn, sn, terms } from "./text";

/* ------------------------------------------------------------------ de-01 ------------------------------------------------------------------ */

export interface P01 { s: 1 | -1; a: number; b: number; c: number; y0: number }
const f01 = (p: P01, y: number) => p.s * (y - p.a) * (y - p.b) * (y - p.c);
const STAB = ["Stable, unstable, stable", "Unstable, stable, unstable", "All three stable", "All three unstable"];
const dest = (p: P01) => [`Settles at y = ${sn(p.a)}`, `Settles at y = ${sn(p.b)}`, `Settles at y = ${sn(p.c)}`, "Runs off up", "Runs off down"];
const cubic = (p: P01) => `${p.s < 0 ? "−" : ""}${factor("y", p.a)}${factor("y", p.b)}${factor("y", p.c)}`;

export const de01: B2Lesson<P01> = {
  id: "b2-de-01", track: "de", unit: 1, title: "The phase line",
  youCan: "find every rest point of dy/dt = f(y) and tell which ones pull solutions in and which push them away, without solving anything.",
  needs: ["c-slopefield", "bc-logistic"],
  tools: ["flow", "graph2d"],
  play: { scene: "phaseline", props: { s: -1, a: -1, b: 2, c: 4 },
    say: "The slope field of dy/dt = f(y), with f's graph turned on its side and the phase line beside it. Drag the three roots of f up and down, then tap the field to start solutions and watch each one slide toward a flat line or away from it." },
  guess: { scene: "phaseline", props: { s: -1, a: -1, b: 2, c: 4, start: 3, quiet: true }, kind: "slider", min: -5, max: 7, step: 0.5, start: 0, answer: 4, near: 0.4,
    format: x => `y = ${sn(x)}`,
    ask: "Here dy/dt = −(y + 1)(y − 2)(y − 4). Start at y = 3. Where does y end up? Slide your guess along the phase line.",
    revealProps: { run: 3 },
    reveal: "f(3) = 4 is positive, so y climbs, and it stops at the next rest point up: y = 4." },
  nameIt: {
    say: [
      "A rest point is a y where f(y) = 0, so nothing changes.",
      "If f′ is negative there, nearby solutions come back and it is stable. If f′ is positive, they leave and it is unstable.",
    ],
    formula: ["dy/dt = f(y), f(y*) = 0", "f′(y*) < 0: stable", "f′(y*) > 0: unstable"],
  },
  workIt: {
    reference: { s: -1, a: -1, b: 2, c: 4, y0: 3 },
    generate(rng, i) {
      let s: 1 | -1 = -1, a = 0, b = 0, c = 0;
      if (i < 3) { b = rng.int(1, 4); c = rng.int(b + 1, 5); }
      else {
        s = rng.pick([1, -1] as const);
        const r = rng.shuffle([-4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6]).slice(0, 3).sort((x, y) => x - y);
        [a, b, c] = r as [number, number, number];
      }
      // an integer strictly between two rest points, or outside them
      const inside = Array.from({ length: c - a + 1 }, (_, k) => a + k).filter(y => y !== a && y !== b && y !== c);
      const outside = [a - 2, a - 1, c + 1, c + 2];
      const y0 = inside.length && (i < 3 || rng.next() < 0.7) ? rng.pick(inside) : rng.pick(outside);
      return { s, a, b, c, y0 };
    },
    show: p => `dy/dt = **${cubic(p)}**. Start at **y₀ = ${sn(p.y0)}**.`,
    steps(p) {
      const fb = p.s * (p.b - p.a) * (p.b - p.c);
      const pattern = p.s < 0 ? 0 : 1;
      const up = f01(p, p.y0) > 0, roots = [p.a, p.b, p.c];
      const next = up ? roots.find(r => r > p.y0) : [...roots].reverse().find(r => r < p.y0);
      const right = next === undefined ? (up ? 3 : 4) : roots.indexOf(next);
      const nearest = roots.reduce((m, r) => (Math.abs(r - p.y0) < Math.abs(m - p.y0) ? r : m), roots[0]!);
      return [
        multiStep("roots", "Rest points", roots, "whole", { boxes: ["smallest", "middle", "largest"], ask: "Where is f(y) = 0? Smallest first.",
          hint: "Each factor is zero at one y: set y − a = 0.",
          slips: [slip("signs flipped", [-p.c, -p.b, -p.a], "Set each factor to zero: y − a = 0 gives y = a, so (y + 1) gives y = −1.")] }),
        wholeStep("fb", `Slope at y = ${sn(p.b)}`, fb, { ask: `f′ at the middle rest point is ${p.s < 0 ? "−" : ""}(b − a)(b − c). What is it?`,
          hint: `The other two factors at y = ${sn(p.b)}: ${p.s < 0 ? "−" : ""}(${sn(p.b)} − ${sn(p.a)})(${sn(p.b)} − ${sn(p.c)}).`,
          slips: [
            slip("dropped the sign in front", -fb, `Keep the ${p.s < 0 ? "minus" : "sign"} in front of f: it flips every slope.`),
            slip("f at the point", 0, "At a rest point f itself is zero. The slope f′ is the product of the other two factors."),
          ] }),
        tapStep("stab", "Each rest point, smallest first", STAB, pattern, { hint: "Look at the sign of f′ at each one, or of f on each side.",
          slips: [
            slip("stable where f is negative", 1 - pattern, "At a rest point f is zero. Look at the sign of f on each side, or the sign of f′ at the point."),
            slip("all stable", 2, "Stable and unstable alternate when the roots are simple. One of every neighbor pair pushes away."),
            slip("all unstable", 3, "Stable and unstable alternate when the roots are simple. One of every neighbor pair pulls in."),
          ] }),
        tapStep("go", `From y₀ = ${sn(p.y0)}`, dest(p), right, { hint: `The sign of f(${sn(p.y0)}) says which way y moves. It stops at the first rest point that way.`,
          slips: [roots.indexOf(nearest) !== right && slip("nearest dot", roots.indexOf(nearest), "Solutions follow the arrows, not the closest dot. Check the sign of f(y₀).")] }),
      ];
    },
    scene: p => ({ scene: "phaseline", props: { s: p.s, a: p.a, b: p.b, c: p.c, start: p.y0, quiet: true } }),
  },
  oracle: p => {
    const r = [p.a, p.b, p.c].sort((x, y) => x - y);
    const d = (y: number) => (f01(p, y + 1e-6) - f01(p, y - 1e-6)) / 2e-6;
    const st = r.map(y => d(y) < 0);
    const stab = st.join() === "true,false,true" ? 0 : 1;
    const v = f01(p, p.y0);
    let to = -1;
    if (v > 0) { const k = r.findIndex(y => y > p.y0); to = k < 0 ? 3 : k; }
    else { let k = -1; r.forEach((y, j) => { if (y < p.y0) k = j; }); to = k < 0 ? 4 : k; }
    return [...r, Math.round(d(r[1]!)), stab, to];
  },
  useIt: {
    say: [
      "A population with an Allee effect, dP/dt = rP(P/A − 1)(1 − P/K), dies out below the threshold A: too few to find mates or defend the reef.",
      "Set A and K for a coral-reef fish (the preset is a start), read the smallest herd that survives, and save `allee_A` and `K_fish` for the build.",
    ],
    scene: { scene: "allee", props: { saveable: true } },
  },
  deeper: [
    "Existence and uniqueness (Picard–Lindelöf): when f is Lipschitz, two solutions can never cross, which is why a phase line works at all. A solution can't jump over a rest point, so it can only slide toward one or run off.",
    "Counterexamples: y′ = √|y| has two solutions from y(0) = 0 (stay at 0, or y = t²/4), and y′ = y² blows up in finite time, at t = 1/y₀.",
    "Then the structural question: what happens to the rest points when f is nudged? Two can merge and vanish. That's de-04.",
  ],
};

/* ------------------------------------------------------------------ de-02 ------------------------------------------------------------------ */

export type P02 =
  | { kind: 0; A: number; gap: number; h: number; n: number }
  | { kind: 1; n: 1 | 2; m: 1 | 2; a: number; y0: number; order: number[] };

/** the integrating-factor choices from n: tⁿ, n·t, e^(nt), n ln t (for n = 1 the duplicate goes and t² comes in) */
const factorChoices = (n: number) => (n === 1 ? ["t", "t²", "eᵗ", "ln t"] : [`t${n === 2 ? "²" : ""}`, `${n}t`, `e^(${n}t)`, `${n} ln t`]);
const pOf = (n: number) => (n === 1 ? "1/t" : `${n}/t`);
const ipOf = (n: number) => (n === 1 ? "ln t" : `${n} ln t`);
const tPow = (n: number) => (n === 1 ? "t" : "t²");

export const de02: B2Lesson<P02> = {
  id: "b2-de-02", track: "de", unit: 1, title: "Linear first-order equations",
  youCan: "solve y′ + p(t)y = q(t) with an integrating factor, and use it for anything that cools, drains or charges toward a set level.",
  needs: ["b2-de-01", "c-expgrowth"],
  tools: ["flow", "graph2d"],
  play: { scene: "cooling", props: { A: 20, T0: 84, h: 10 },
    say: "A coffee cup cools in a room. Drag the room temperature and the halving time, and watch the curve bend toward the room line. The gap to the room halves at a steady pace, and every halving is marked." },
  guess: { scene: "cooling", props: { A: 20, T0: 84, h: 10, quiet: true }, kind: "slider", min: 20, max: 84, step: 1, start: 52, answer: 28, near: 2, unit: "°C",
    ask: "The coffee starts at 84 °C in a 20 °C room, and the gap to the room halves every 10 minutes. After 30 minutes, what does it read?",
    revealProps: {},
    reveal: "The gap goes 64, 32, 16, 8. Add the room back: 28 °C at 30 minutes." },
  nameIt: {
    say: [
      "When the rate depends on the gap to a target, the gap decays exponentially.",
      "In general, multiply by an integrating factor μ = e^(∫p dt) so the left side becomes one derivative, then integrate.",
    ],
    formula: ["T′ = −k(T − A) gives T = A + (T₀ − A)e^(−kt)", "y′ + p(t)y = q(t): (μy)′ = μq, μ = e^(∫p dt)"],
  },
  workIt: {
    reference: { kind: 0, A: 20, gap: 64, h: 10, n: 3 },
    generate(rng, i) {
      if (i < 3 || rng.next() < 0.5) return { kind: 0, A: rng.pick([18, 20, 22]), gap: rng.pick([32, 48, 64, 80]), h: rng.pick([5, 8, 10, 12]), n: rng.int(1, 3) };
      const a = rng.int(1, 3);
      return { kind: 1, n: rng.pick([1, 2] as const), m: rng.pick([1, 2] as const), a, y0: rng.int(a + 1, a + 4), order: rng.shuffle([0, 1, 2, 3]) };
    },
    show: p => {
      if (p.kind === 0) return `Coffee starts at **${p.A + p.gap} °C** in a **${p.A} °C** room. The gap to the room halves every **${p.h} minutes**. Find the reading at **t = ${p.n * p.h} minutes**.`;
      const lhs = `y′ + ${p.n === 1 ? "y/t" : `(${p.n}/t)y`}`, rhs = terms([[p.a * (p.m + p.n), p.m === 1 ? "" : "t"]]);
      return `Solve **${lhs} = ${rhs}** for t > 0, with **y(1) = ${p.y0}**. The solution has the form y = ${p.a === 1 ? "" : p.a}${tPow(p.m)} + C/${tPow(p.n)}.`;
    },
    steps(p): B2Step[] {
      if (p.kind === 0) {
        const T0 = p.A + p.gap, t = p.n * p.h, T = p.A + p.gap / 2 ** p.n;
        return [
          wholeStep("gap", "Gap at the start", p.gap, { unit: "°C", hint: `Start minus room: ${T0} − ${p.A}.`,
            slips: [slip("used the start", T0, "The gap is how far above the room it starts: subtract the room.")] }),
          wholeStep("n", "Halvings", p.n, { ask: `How many halvings fit in ${t} minutes?`, hint: `${t} / ${p.h}.`,
            slips: [slip("multiplied", t * p.h, "Halvings are the time divided by the halving time.")] }),
          wholeStep("T", `Reading at ${t} minutes`, T, { unit: "°C", hint: `Halve the gap ${p.n === 1 ? "once" : `${p.n} times`}, then add the room: ${p.A} + ${p.gap}/${2 ** p.n}.`,
            slips: [
              slip("halved the temperature", T0 / 2 ** p.n, "Only the gap to the room halves. Add the room temperature back."),
              slip("forgot the room", p.gap / 2 ** p.n, "That's the gap. Add the room temperature back."),
            ] }),
          numStep("k", "Rate k", Math.LN2 / p.h, 4, { unit: "per minute", ask: "e^(−kh) = 1/2, so k = ln 2 / h. To 4 places.", hint: `ln 2 / ${p.h}, with the natural log.`,
            slips: [slip("log base 10", Math.log10(2) / p.h, "Continuous rates use the natural log: k = ln 2 / h."), slip("no log", 0.5 / p.h, "Continuous rates use the natural log: k = ln 2 / h.")] }),
        ];
      }
      const ch = factorChoices(p.n), shown = p.order.map(j => ch[j]!), right = p.order.indexOf(0);
      const C = p.y0 - p.a, y2 = p.a * 2 ** p.m + C / 2 ** p.n;
      const pText = `p = ${pOf(p.n)}, so ∫p dt = ${ipOf(p.n)} and the factor is ${ch[0]}.`;
      return [
        tapStep("mu", "Integrating factor", shown, right, { hint: `μ = e^(∫p dt) with p = ${pOf(p.n)}.`,
          slips: [slip("e to the nt", p.order.indexOf(2), `The factor is e to the integral of p. Here ${pText}`), slip("stopped at the integral", p.order.indexOf(3), `${ipOf(p.n)} is ∫p dt. The factor is e to that: ${ch[0]}.`)] }),
        wholeStep("C", "C", C, { ask: `At t = 1 the solution reads ${p.a} + C, and y(1) = ${p.y0}. What is C?`, hint: `At t = 1 every power of t is 1: C = ${p.y0} − ${p.a}.`,
          slips: [slip("forgot the first part", p.y0, `At t = 1 the first part is ${p.a}, not 0: C = ${p.y0} − ${p.a}.`)] }),
        fracStep("y2", "y(2)", y2, { ask: "As a fraction.", hint: `${p.a === 1 ? "" : `${p.a}·`}2${p.m === 2 ? "²" : ""} + ${C}/2${p.n === 2 ? "²" : ""}.`,
          slips: [slip("multiplied by tⁿ", p.a * 2 ** p.m + C * 2 ** p.n, `C sits over ${tPow(p.n)}: divide by 2${p.n === 2 ? "²" : ""}.`)] }),
      ];
    },
    scene: (p): SceneRef => (p.kind === 0 ? { scene: "cooling", props: { A: p.A, T0: p.A + p.gap, h: p.h, at: p.n * p.h, quiet: true } } : { scene: "cooling", props: { mode: "factor", n: p.n, m: p.m, a: p.a, y0: p.y0, quiet: true } }),
  },
  oracle: p => (p.kind === 0
    ? [p.gap, p.n, p.A + p.gap * 2 ** -p.n, Math.log(2) / p.h]
    : [p.order.findIndex(j => j === 0), p.y0 - p.a, p.a * 2 ** p.m + (p.y0 - p.a) / 2 ** p.n]),
  useIt: {
    say: [
      "A medicine drip: the dose enters at a steady 40 mg an hour and the body clears 1/5 of what's there each hour, so L′ = 40 − L/5.",
      "That's the cooling law with a target of 200 mg. The level climbs toward it, and the gap halves every 5 ln 2 = 3.47 hours: within 1/8 of the target after three halvings, about 10.4 hours.",
    ],
    scene: { scene: "cooling", props: { mode: "drip" } },
  },
  deeper: [
    "Variation of parameters: for y′ + py = q the solution is the free decay plus the response to the forcing, y = e^(−∫p)(C + ∫e^(∫p) q dt).",
    "That integral is a convolution: the forcing at each moment is passed through a decaying kernel (the Green's function). The 2nd-order version comes back in de-11, where the kernel rings.",
    "The Laplace transform turns these equations into algebra: y′ becomes sY − y(0), and solving is dividing.",
  ],
};

/* ------------------------------------------------------------------ de-03 ------------------------------------------------------------------ */

export interface P03 { a: number; b: number; y0: number; h: number }
const ERRS = ["1/2, 1/4, 1/16", "1/2, 1/2, 1/2", "1/2, 1/4, 1/8", "1/2, 1/4, 1/2"];

export const de03: B2Lesson<P03> = {
  id: "b2-de-03", track: "de", unit: 1, title: "Better steppers: Heun and Runge–Kutta",
  youCan: "take one step of Heun's method by hand and say how fast each method's error shrinks when the step is halved.",
  needs: ["bc-euler"],
  tools: ["steppers", "flow"],
  play: { scene: "steppers", props: { h: 0.25 },
    say: "Three solvers run dy/dt = y from y(0) = 1 to t = 1: Euler, Heun and RK4, each with its own dotted path against the true curve eᵗ. Drag the step size h and watch the error plot: three straight lines with different slopes." },
  guess: { scene: "steppers", props: { h: 0.25, quiet: true }, kind: "choice", options: ["× 1/2", "× 1/4", "× 1/16"], answer: 2,
    ask: "Halve h. Euler's error roughly halves. What happens to RK4's error?",
    revealProps: { halve: true },
    reveal: "RK4's error drops by about 16 for each halving: its line on the log-log plot is four times as steep as Euler's." },
  nameIt: {
    say: [
      "Euler uses the slope at the start of a step. Heun takes a trial Euler step, measures the slope at the far end, and moves with the average of the two. RK4 averages four slopes.",
      "Halving h divides the error by about 2 (Euler), 4 (Heun) or 16 (RK4).",
    ],
    formula: ["k₁ = f(t, y)", "k₂ = f(t + h, y + hk₁)", "y_new = y + (h/2)(k₁ + k₂)"],
  },
  workIt: {
    reference: { a: 1, b: 1, y0: 1, h: 0.5 },
    generate(rng, i) {
      if (i < 3) return { a: rng.pick([0, 1]), b: 1, y0: rng.pick([1, 2, 3]), h: 0.5 };
      return { a: rng.pick([0, 1, 2]), b: rng.pick([1, -1, 2]), y0: rng.pick([1, 2, 3]), h: rng.pick([0.5, 1]) };
    },
    show: p => `dy/dt = **${terms([[p.a, "t"], [p.b, "y"]])}**, y(0) = **${p.y0}**, one step of size **h = ${fr(p.h)}**.`,
    steps(p) {
      const k1 = p.b * p.y0, eu = p.y0 + p.h * k1, k2 = p.a * p.h + p.b * eu, heun = p.y0 + (p.h / 2) * (k1 + k2);
      return [
        fracStep("k1", "k₁", k1, { ask: "The slope at the start, (0, y₀).", hint: `At t = 0 only the y part counts: ${sn(p.b)} × ${p.y0}.`,
          slips: [slip("used t", p.a * p.h, "k₁ is the slope at the start, where t = 0 and y = y₀.")] }),
        fracStep("eu", "Euler step", eu, { ask: "y₀ + hk₁, as a fraction.", hint: `${p.y0} + ${fr(p.h)} × ${pn(k1)}.`,
          slips: [slip("forgot h", p.y0 + k1, `Each step moves by h times the slope: ${fr(p.h)} × ${fr(k1)}.`)] }),
        fracStep("k2", "k₂", k2, { ask: `The slope at the far end: (h, Euler value).`, hint: `f(${fr(p.h)}, ${fr(eu)}).`,
          slips: [slip("used t = 0", p.b * eu, "k₂ is the slope at the far end of the trial step, at time t + h.")] }),
        fracStep("heun", "Heun step", heun, { ask: "y₀ + (h/2)(k₁ + k₂), as a fraction.", hint: `${p.y0} + ${fr(p.h / 2)} × (${fr(k1)} + ${pn(k2)}).`,
          slips: [slip("forgot the 1/2", p.y0 + p.h * (k1 + k2), "Heun moves with the average slope, (k₁ + k₂)/2.")] }),
        tapStep("halve", "Halve h: error factor for Euler, Heun, RK4", ERRS, 0, { hint: "Euler is first order, Heun second, RK4 fourth: the error scales like h, h², h⁴.",
          slips: [
            slip("RK4 halves", 3, "RK4 is fourth order. Error scales like h⁴, so halving h divides it by 2⁴ = 16."),
            slip("RK4 third order", 2, "RK4 is fourth order. Error scales like h⁴, so halving h divides it by 2⁴ = 16."),
            slip("all the same", 1, "Higher order pays off: Heun's error scales like h², so halving h divides it by 4."),
          ] }),
      ];
    },
    scene: p => ({ scene: "steppers", props: { a: p.a, b: p.b, y0: p.y0, h: p.h, one: true } }),
  },
  oracle: p => {
    const f = (t: number, y: number) => p.a * t + p.b * y;
    const k1 = f(0, p.y0), k2 = f(p.h, p.y0 + p.h * k1);
    return [k1, p.y0 + p.h * k1, k2, p.y0 + (p.h / 2) * (p.b * p.y0 + p.a * p.h + p.b * (p.y0 + p.h * p.b * p.y0)), 0];
  },
  useIt: {
    say: [
      "Your population model has to run 50 years. Pick a stepper and the largest h that keeps it within 0.1% of RK4 with a tiny step.",
      "Save it as `stepper`: every later model in the build runs on it.",
    ],
    scene: { scene: "stepperpick", props: { saveable: true } },
  },
  deeper: [
    "Local error is the error of one step (h², h³, h⁵ for the three methods); global error adds up 1/h of them, losing one power. The Butcher tableau lists a Runge–Kutta method's weights, and order conditions say which weights reach which order.",
    "Stiffness: Euler on y′ = −50y blows up unless h < 0.04, however smooth the answer is. Implicit methods like backward Euler, which use the slope at the end of the step, are A-stable and fix it.",
    "Gradient descent is Euler's method on x′ = −∇f(x) (b2-mv-14, b2-ai-02), and a residual network is a stack of Euler steps (neural ODEs).",
  ],
};

/* ------------------------------------------------------------------ de-04 ------------------------------------------------------------------ */

export interface P04 { r: number; K: number; P1: number; H: number; P0: number }
const goChoices = (p: P04) => ["Collapses to 0", `Settles at ${p.K - p.P1}`, `Settles at ${p.P1}`];

export const de04: B2Lesson<P04> = {
  id: "b2-de-04", track: "de", unit: 1, title: "Harvesting and tipping points",
  youCan: "find the largest harvest a population can take forever and the threshold below which it collapses.",
  needs: ["b2-de-01", "bc-logistic"],
  tools: ["harvest", "flow"],
  play: { scene: "harvest", props: { r: 1, K: 100, H: 10 },
    say: "A fish stock grows logistically and you take H a year: dP/dt = rP(1 − P/K) − H. Drag H up. The hump of the growth curve sinks below the harvest line, the two rest points slide together, merge and vanish, and the bifurcation strip traces them." },
  guess: { scene: "harvest", props: { r: 1, K: 100, H: 5, quiet: true }, kind: "slider", min: 0, max: 40, step: 0.5, start: 12, answer: 25, near: 1.5, unit: "thousand fish a year",
    ask: "With r = 1 and K = 100 thousand fish, raise H until the rest points meet. At what harvest does that happen?",
    revealProps: { H: 25 },
    reveal: "They meet at the top of the hump, P = K/2 = 50, where growth is rK/4 = 25 thousand a year. Any more and every stock crashes." },
  nameIt: {
    say: [
      "Harvesting lowers the growth curve. While H is below the top of the hump there are two rest points: a high stable one and a low unstable one, the collapse threshold.",
      "At H = rK/4 they merge (a saddle-node bifurcation), and above that every stock crashes.",
    ],
    formula: ["H_max = rK/4, at P = K/2", "rest points: rP(1 − P/K) = H"],
  },
  workIt: {
    reference: { r: 1, K: 100, P1: 20, H: 16, P0: 15 },
    generate(rng, i) {
      const r = i < 3 ? 1 : rng.pick([1, 2]), K = i < 3 ? 100 : rng.pick([100, 200]);
      const P1 = (rng.int(1, 4) * K) / 10, H = (r * P1 * (K - P1)) / K;
      const step = K / 20;
      const low = Array.from({ length: P1 / step - 1 }, (_, k) => (k + 1) * step);
      const mid = Array.from({ length: (K - 2 * P1) / step - 1 }, (_, k) => P1 + (k + 1) * step);
      const P0 = low.length && rng.next() < 0.5 ? rng.pick(low) : rng.pick(mid);
      return { r, K, P1, H, P0 };
    },
    show: p => `dP/dt = **${p.r === 1 ? "" : p.r}P(1 − P/${p.K}) − ${p.H}**, in thousands of fish and years. The stock starts at **P₀ = ${p.P0}**.`,
    steps(p) {
      const P2 = p.K - p.P1, collapse = p.P0 < p.P1;
      return [
        wholeStep("msy", "Maximum sustainable yield", (p.r * p.K) / 4, { unit: "thousand a year", hint: `The top of the hump, at P = K/2: ${p.r === 1 ? "" : `${p.r} × `}${p.K / 2} × 1/2.`,
          slips: [
            slip("rK", p.r * p.K, "The most you can take is the top of the growth hump, which is at P = K/2: r·(K/2)·(1/2) = rK/4."),
            slip("rK/2", (p.r * p.K) / 2, "The most you can take is the top of the growth hump, which is at P = K/2: r·(K/2)·(1/2) = rK/4."),
          ] }),
        multiStep("rest", "Rest points", [p.P1, P2], "whole", { boxes: ["low", "high"], ask: `Solve ${p.r === 1 ? "" : p.r}P(1 − P/${p.K}) = ${p.H}. Low first.`,
          hint: `Multiply out: (${fr(p.r / p.K)})P² − ${p.r === 1 ? "" : p.r}P + ${p.H} = 0. The two roots add to ${p.K}.`,
          slips: [slip("no harvest", [0, p.K], `Those are the rest points with no harvest. Take ${p.H} off the growth first.`)] }),
        tapStep("st", "Which is stable", ["The low one", "The high one"], 1, { hint: "Between them growth beats the harvest, so the stock climbs toward the high one.",
          slips: [slip("low stable", 0, "Below the low rest point, growth can't keep up with the harvest. It pushes away, so it is the tipping point.")] }),
        tapStep("go", `From P₀ = ${p.P0}`, goChoices(p), collapse ? 0 : 1, { hint: `Is ${p.P0} above or below the threshold ${p.P1}?`,
          slips: [
            collapse && slip("always recovers", 1, "Under harvest, a stock below the threshold shrinks every year, all the way to zero."),
            slip("stuck at the threshold", 2, "The low rest point pushes away. Nothing settles there."),
          ] }),
      ];
    },
    scene: p => ({ scene: "harvest", props: { r: p.r, K: p.K, H: p.H, quiet: true } }),
  },
  oracle: p => {
    const A = p.r / p.K, B = -p.r, Cc = p.H, d = Math.sqrt(B * B - 4 * A * Cc);
    const lo = (-B - d) / (2 * A), hi = (-B + d) / (2 * A);
    return [(p.r * p.K) / 4, lo, hi, 1, p.P0 < lo ? 0 : 1];
  },
  useIt: {
    say: [
      "Project: the Fishery dial. Set the largest harvest that still leaves a safety margin above the collapse threshold, and save it as `H_safe`.",
    ],
    project: "de-fishery",
  },
  deeper: [
    "The normal form x′ = μ + x²: every generic fold looks like it near the merge, which is why the bifurcation strip always shows a sideways parabola.",
    "Hysteresis (the spruce budworm model): once a system tips, putting the parameter back doesn't bring it back. You have to go well past the old setting.",
    "Critical slowing down: recovery time is about 1/|f′(y*)|, which grows without limit near the fold. Slower and slower recovery from small shocks is a measurable early warning. Other bifurcations: transcritical (x′ = μx − x²) and pitchfork (x′ = μx − x³).",
  ],
};
