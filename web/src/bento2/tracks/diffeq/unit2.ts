// Unit 2 · Linear systems: b2-de-05 to b2-de-08 (curriculum/specs/bento2/diffeq.md).
import type { B2Lesson, B2Step } from "../../model";
import { multiStep, numStep, slip, tapStep, wholeStep } from "../../make";
import { mat, pn, pt, sn, sq, tdHint, terms } from "./text";
import { region, TYPES, type M2 } from "./maths";

/* ------------------------------------------------------------------ de-05 ------------------------------------------------------------------ */

export interface P05 { b: number; c: number; p: number; q: number }
const springEq = (b: number, c: number) => `${terms([[1, "y″"], [b, "y′"], [c, "y"]])} = 0`;

export const de05: B2Lesson<P05> = {
  id: "b2-de-05", track: "de", unit: 2, title: "Systems as one vector equation",
  youCan: "turn a second-order equation into a 2×2 system x′ = Ax and draw its velocity arrow at any point.",
  needs: ["b2-de-01", "g12-dot", "b2-la-05", "b2-mv-09"],
  tools: ["plane", "matrix"],
  play: { scene: "plane", props: { mode: "spring", b: 1, c: 4 },
    say: "A mass on a spring, y″ + by′ + cy = 0. The phase plane plots position across and velocity up. Drag b and c and watch the arrow field and the traced path change, while the spring bounces beside it in step." },
  guess: { scene: "plane", props: { mode: "spring", b: 3, c: 2, probe: true, px: 1, py: -1, quiet: true }, kind: "point", answer: [-1, 1], near: 0.6, start: [1, 0.5],
    ask: "For y″ + 3y′ + 2y = 0, the state is at position 1 and velocity −1. Which way does it move? Drag the tip of the arrow from (1, −1).",
    revealProps: { showProbe: true },
    reveal: "The true arrow is A·(1, −1) = (−1, 1): position falls at the velocity, −1, and the spring and friction push the velocity up by 1." },
  nameIt: {
    say: [
      "Two first-order equations make one vector equation. For y″ + by′ + cy = 0, let x₁ = y and x₂ = y′.",
      "Then the velocity of the state at each point is the matrix times the point.",
    ],
    formula: ["x′ = Ax", "A = [[0, 1], [−c, −b]]"],
  },
  workIt: {
    reference: { b: 3, c: 2, p: 1, q: -1 },
    generate(rng, i) {
      const b = rng.int(0, i < 3 ? 2 : 4), c = rng.int(1, i < 3 ? 4 : 9), lim = i < 3 ? 2 : 3;
      let p = 0, q = 0;
      while (p === 0 && q === 0) { p = rng.int(-lim, lim); q = rng.int(-lim, lim); }
      return { b, c, p, q };
    },
    show: p => `**${springEq(p.b, p.c)}**, at the state **${pt(p.p, p.q)}** (position, velocity).`,
    steps(p) {
      const acc = -p.c * p.p - p.b * p.q;
      const out: B2Step[] = [
        multiStep("A", "Matrix A", [0, 1, -p.c, -p.b], "whole", { boxes: ["a₁₁", "a₁₂", "a₂₁", "a₂₂"], ask: "Row by row.",
          hint: "Top row: x₁′ = x₂. Bottom row: x₂′ = y″ = −cy − by′.",
          slips: [
            slip("rows swapped", [-p.c, -p.b, 0, 1], "The top row says x₁′ = x₂: position changes at the velocity. The spring and friction live in the bottom row."),
            slip("dropped a minus", [0, 1, p.c, p.b], "Friction and the spring both push back, so the bottom row is −c and −b."),
          ] }),
        multiStep("v", `Arrow at ${pt(p.p, p.q)}`, [p.q, acc], "whole", { boxes: ["x₁′", "x₂′"], hint: `Each row of A dotted with ${pt(p.p, p.q)}.`,
          slips: [slip("column times row", [-p.c * p.q, p.p - p.b * p.q], "Each component of the arrow is a row of A dotted with (p, q).")] }),
      ];
      if (p.q !== 0 && acc !== 0) out.push(tapStep("feel", "Is the mass speeding up or slowing down here?", ["Speeding up", "Slowing down"], Math.sign(acc) === Math.sign(p.q) ? 0 : 1, {
        hint: "Compare the sign of the velocity with the sign of its rate of change, x₂′.",
        slips: [slip("read the position", Math.sign(acc) === Math.sign(p.q) ? 1 : 0, `The velocity is ${sn(p.q)} and its rate of change x₂′ is ${sn(acc)}. ${Math.sign(acc) === Math.sign(p.q) ? "Same sign, so the speed grows." : "Opposite signs, so the speed shrinks."}`)] }));
      return out;
    },
    scene: p => ({ scene: "plane", props: { mode: "spring", b: p.b, c: p.c, probe: true, px: p.p, py: p.q, quiet: true } }),
  },
  oracle: p => {
    const A = [[0, 1], [-p.c, -p.b]], v = [A[0]![0]! * p.p + A[0]![1]! * p.q, A[1]![0]! * p.p + A[1]![1]! * p.q];
    return [...A.flat(), ...v, ...(p.q !== 0 && v[1] !== 0 ? [v[1]! * p.q > 0 ? 0 : 1] : [])];
  },
  useIt: {
    say: [
      "The pendulum near the bottom is a spring too: θ″ = −(g/L)θ − βθ′, with friction β. Write it as a system and save its matrix as `A_pend`.",
      "Set the length and the friction, check the arrows, and save. It goes into the build.",
    ],
    scene: { scene: "plane", props: { mode: "pend", L: 1, beta: 0.5, saveable: true } },
  },
  deeper: [
    "Every nth-order linear equation becomes an n×n system with a companion matrix, whose characteristic polynomial is the equation's own (b2-la-13).",
    "Existence and uniqueness carry over to systems, so paths in the phase plane never cross.",
    "The flow map φₜ sends a state to where it is t later. φₜ ∘ φₛ = φₜ₊ₛ, a one-parameter group, and for a linear system φₜ is the matrix e^(At) (de-08).",
  ],
};

/* ------------------------------------------------------------------ de-06 ------------------------------------------------------------------ */

export interface P06 { A: M2; x0: [number, number] }
const KIND3 = ["Source", "Sink", "Saddle"];

export const de06: B2Lesson<P06> = {
  id: "b2-de-06", track: "de", unit: 2, title: "Real eigenvalues: straight-line solutions",
  youCan: "use eigenvalues and eigenvectors to find the straight-line solutions of x′ = Ax and build any solution from them.",
  needs: ["b2-de-05", "b2-la-13"],
  tools: ["plane", "matrix"],
  play: { scene: "plane", props: { mode: "matrix", a11: 7, a12: -4, a21: 8, a22: -5, probeRing: true },
    say: "Tap starts all over the phase plane. Most paths curve, but a few run along straight lines. Drag the test arrow around the circle until A·v points along v, and the eigen-line lights up." },
  guess: { scene: "plane", props: { mode: "matrix", a11: 7, a12: -4, a21: 8, a22: -5, sx: 1, sy: 2, quiet: true, lines: true }, kind: "choice", options: ["In toward the origin", "Out along the line"], answer: 0,
    ask: "For A = [[7, −4], [8, −5]], this start, (1, 2), sits exactly on a straight line. Does it run in toward the origin or out along the line?",
    revealProps: { run: true },
    reveal: "A·(1, 2) = (−1, −2) = −1 × (1, 2). The eigenvalue is −1, so the state slides in along the line and shrinks like e^(−t)." },
  nameIt: {
    say: [
      "If Av = λv, then x = e^(λt)v solves x′ = Ax: the state slides along v, growing when λ > 0 and shrinking when λ < 0.",
      "Two different eigenvalues give two lines, and every solution is a mix.",
    ],
    formula: ["λ² − Tλ + D = 0, T = trace, D = determinant", "x(t) = c₁e^(λ₁t)v₁ + c₂e^(λ₂t)v₂"],
  },
  workIt: {
    reference: { A: [[7, -4], [8, -5]], x0: [3, 4] },
    generate(rng, i) {
      let l1 = 0, l2 = 0;
      for (;;) {
        l1 = rng.int(-3, 4); l2 = rng.int(-3, 4);
        if (l1 === 0 || l2 === 0 || l1 <= l2) continue;
        if (i < 3 && l1 * l2 < 0) continue;
        break;
      }
      let m1 = 0, m2 = 0;
      if (i < 3) [m1, m2] = rng.pick([[0, 1], [1, 0]]) as [number, number];
      else { m1 = rng.int(-2, 2); m2 = rng.pick([m1 - 1, m1 + 1].filter(m => m >= -2 && m <= 2)); }
      let c1 = 0, c2 = 0;
      while ((c1 === 0 && c2 === 0) || (i < 3 && (c1 === 0 || c2 === 0))) { c1 = rng.int(-2, 2); c2 = rng.int(-2, 2); }
      // A = P diag(λ₁, λ₂) P⁻¹ with P = [[1, 1], [m₁, m₂]], det P = m₂ − m₁ = ±1
      const dP = m2 - m1;
      const A: M2 = [[(l1 * m2 - l2 * m1) / dP, (l2 - l1) / dP], [(m1 * m2 * (l1 - l2)) / dP, (l2 * m2 - l1 * m1) / dP]];
      return { A: A.map(r => r.map(v => v + 0)) as M2, x0: [c1 + c2, c1 * m1 + c2 * m2] };
    },
    show: p => `x′ = Ax with **A = ${mat(p.A)}**, starting at **x(0) = ${pt(...p.x0)}**.`,
    steps(p) {
      const [[a, b], [c, d]] = p.A, T = a + d, D = a * d - b * c, r = Math.sqrt(T * T - 4 * D), l1 = (T + r) / 2, l2 = (T - r) / 2;
      const m1 = (l1 - a) / b, m2 = (l2 - a) / b, c2 = (p.x0[1] - m1 * p.x0[0]) / (m2 - m1), c1 = p.x0[0] - c2;
      const kind = l2 > 0 ? 0 : l1 < 0 ? 1 : 2;
      return [
        multiStep("TD", "Trace and determinant", [T, D], "whole", { boxes: ["T", "D"], hint: tdHint(a, b, c, d),
          slips: [slip("ad + bc", [T, a * d + b * c], "D = ad − bc: the off-diagonal product is subtracted.")] }),
        multiStep("l", "Eigenvalues", [l1, l2], "whole", { boxes: ["λ₁", "λ₂"], ask: `Solve λ² − Tλ + D = 0. Larger first.`, hint: `λ = (T ± √(T² − 4D))/2 = (${sn(T)} ± ${sn(r)})/2.`,
          slips: [slip("+T", [-l2, -l1], "It is λ² − Tλ + D. Check: the eigenvalues add to the trace and multiply to the determinant.")] }),
        wholeStep("m", "Eigenvector slope for λ₁", m1, { ask: "v₁ = (1, m). The top row of Av = λv gives m = (λ₁ − a₁₁)/a₁₂.", hint: `(${sn(l1)} − ${pn(a)}) / ${pn(b)}.`,
          slips: [slip("flipped", b / (l1 - a), "The slope is rise over run: for v = (1, m), m = (λ₁ − a₁₁)/a₁₂.")] }),
        tapStep("kind", "Type", KIND3, kind, { hint: "Both eigenvalues positive: source. Both negative: sink. One of each: saddle.",
          slips: kind === 2
            ? [slip("mixed signs a node", 0, "One eigenvalue pulls in and one pushes out. That is a saddle."), slip("mixed signs a node", 1, "One eigenvalue pulls in and one pushes out. That is a saddle.")]
            : [slip("growth backwards", 1 - kind, kind === 0 ? "Positive eigenvalues grow: e^(λt) runs away from rest. That's a source." : "Negative eigenvalues shrink: e^(λt) dies away toward rest. That's a sink.")] }),
        multiStep("c", "c₁ and c₂", [c1, c2], "whole", { boxes: ["c₁", "c₂"], ask: `x(0) = c₁(1, ${sn(m1)}) + c₂(1, ${sn(m2)}).`,
          hint: `First components: c₁ + c₂ = ${sn(p.x0[0])}. Second: ${terms([[m1, "c₁"], [m2, "c₂"]])} = ${sn(p.x0[1])}.`,
          slips: [slip("swapped c₁ and c₂", [c2, c1], "c₁ goes with v₁, the eigenvector for the larger eigenvalue.")] }),
      ];
    },
    scene: p => ({ scene: "plane", props: { mode: "matrix", a11: p.A[0][0], a12: p.A[0][1], a21: p.A[1][0], a22: p.A[1][1], sx: p.x0[0], sy: p.x0[1], quiet: true } }),
  },
  oracle: p => {
    // from A and x(0) only
    const [[a, b], [c, d]] = p.A, T = a + d, D = a * d - b * c, disc = Math.sqrt(T * T - 4 * D);
    const l1 = (T + disc) / 2, l2 = (T - disc) / 2, m1 = (l1 - a) / b, m2 = (l2 - a) / b;
    // Cramer on [[1, 1], [m1, m2]] (c1, c2) = x0
    const dd = m2 - m1, c1 = (p.x0[0] * m2 - p.x0[1]) / dd, c2 = (p.x0[1] - m1 * p.x0[0]) / dd;
    return [T, D, l1, l2, m1, l1 > 0 && l2 > 0 ? 0 : l1 < 0 && l2 < 0 ? 1 : 2, c1, c2];
  },
  useIt: {
    say: [
      "For a saddle, almost every start blows up along v₁. The one line of starts that doesn't is c₁ = 0: the stable line, along v₂.",
      "Here A = [[7, −4], [8, −5]] and the stable line is through (1, 2). Start on it and the state slides home; start a hair off and it leaves. In de-12 this line becomes the knife-edge where a pendulum balances upside down.",
    ],
    scene: { scene: "plane", props: { mode: "matrix", a11: 7, a12: -4, a21: 8, a22: -5, sx: 1.5, sy: 3, lines: true, run: true } },
  },
  deeper: [
    "Diagonalization A = PΛP⁻¹: in the coordinates of the eigenvectors, u = P⁻¹x, the system splits into u₁′ = λ₁u₁ and u₂′ = λ₂u₂, two separate one-line equations.",
    "Invariant subspaces: in n dimensions the eigenvectors with negative eigenvalues span the stable subspace, the positive ones the unstable subspace.",
    "Repeated eigenvalues with only one eigenvector (a Jordan block) give solutions like te^(λt): a degenerate node, where every path leaves along the same line.",
  ],
};

/* ------------------------------------------------------------------ de-07 ------------------------------------------------------------------ */

export interface P07 { A: M2 }
const SPIRALS = ["Spiral in", "Spiral out", "Center"];
const TURN = ["Clockwise", "Counterclockwise"];

export const de07: B2Lesson<P07> = {
  id: "b2-de-07", track: "de", unit: 2, title: "Complex eigenvalues: spirals and centers",
  youCan: "read the turning rate, the decay per turn and the direction of a spiral from a matrix.",
  needs: ["b2-de-06", "pc-polar"],
  tools: ["plane", "matrix"],
  play: { scene: "plane", props: { mode: "matrix", a11: 0, a12: -5, a21: 1, a22: -2, sx: 3, sy: 0, run: true, turns: true },
    say: "Drag the matrix entries until the eigenvalues go complex. The straight lines vanish and every path spirals: in, out, or round in closed loops. The readouts count the time per turn and how much smaller each loop gets." },
  guess: { scene: "plane", props: { mode: "matrix", a11: 0, a12: -5, a21: 1, a22: -2, sx: 1, sy: 0, quiet: true }, kind: "choice", options: TURN, answer: 1,
    ask: "For A = [[0, −5], [1, −2]], start at (1, 0). Does the path turn clockwise or counterclockwise?",
    revealProps: { run: true, quarter: true },
    reveal: "At (1, 0) the arrow is the first column, (0, 1): straight up. Up from the right-hand side is counterclockwise." },
  nameIt: {
    say: [
      "When T² < 4D the eigenvalues are α ± βi. The real part α decides growth or decay, and β is the turning rate in radians per unit time.",
      "One turn takes 2π/β, and in that time sizes scale by e^(2πα/β). The arrow at (1, 0) is (a₁₁, a₂₁): counterclockwise when a₂₁ > 0.",
    ],
    formula: ["α = T/2, β = √(D − T²/4)", "a turn takes 2π/β", "size factor per turn e^(2πα/β)"],
  },
  workIt: {
    reference: { A: [[0, -5], [1, -2]] },
    generate(rng, i) {
      let al = 0, be = 1;
      for (;;) {
        al = i < 3 ? rng.pick([-1, 0]) : rng.int(-2, 2); be = rng.int(1, 4);
        if (2 * Math.abs(al) <= be && (i >= 3 || al === 0 || be >= 2)) break;
      }
      const u = rng.int(0, i < 3 ? 1 : 2), n = be * be + u * u;
      const divs = Array.from({ length: n }, (_, k) => k + 1).filter(k => n % k === 0);
      const r = rng.pick(divs) * rng.pick([1, -1]);
      return { A: [[al + u, -n / r], [r, al - u]] };
    },
    show: p => `x′ = Ax with **A = ${mat(p.A)}**.`,
    steps(p) {
      const [[a, b], [c, d]] = p.A, T = a + d, D = a * d - b * c, disc = T * T - 4 * D, al = T / 2, be = Math.sqrt(D - (T * T) / 4);
      const kind = al < 0 ? 0 : al > 0 ? 1 : 2, dir = c > 0 ? 1 : 0;
      return [
        multiStep("TD", "T and D", [T, D], "whole", { boxes: ["T", "D"], hint: tdHint(a, b, c, d),
          slips: [slip("ad + bc", [T, a * d + b * c], "D = ad − bc: the off-diagonal product is subtracted.")] }),
        wholeStep("disc", "T² − 4D", disc, { hint: `${sq(T)} − 4 × ${sn(D)}.`, slips: [slip("+4D", T * T + 4 * D, "The discriminant is T² − 4D, with a minus.")] }),
        multiStep("ab", "α and β", [al, be], "whole", { boxes: ["α", "β"], hint: `α = T/2; β = √(D − T²/4) = √(${sn(D)} − ${sn((T * T) / 4)}).`,
          slips: [
            slip("root of T² − 4D", [al, Math.sqrt(-disc)], "Inside the root it's D − T²/4, which is positive here. The minus sign belongs to the discriminant."),
            slip("α = T", [T, be], "α is half the trace: the two eigenvalues α ± βi add to T."),
          ] }),
        tapStep("kind", "Type", SPIRALS, kind, { hint: "The sign of α: negative shrinks, positive grows, zero neither.",
          slips: [
            kind === 0 && slip("α < 0 spirals out", 1, "A negative real part shrinks every loop. It spirals in."),
            kind === 1 && slip("α > 0 spirals in", 0, "A positive real part grows every loop. It spirals out."),
            kind === 2 && slip("center spirals", 0, "With α = 0 every loop comes back to the same size: a center."),
          ] }),
        tapStep("dir", "Direction", TURN, dir, { hint: "The arrow at (1, 0) is the first column of A.",
          slips: [slip("read a₁₂", 1 - dir, `Look at the arrow at (1, 0). Its second component is a₂₁ = ${sn(c)}. If that's positive the path heads up, so counterclockwise.`)] }),
        numStep("size", "Size left after one turn", Math.exp((2 * Math.PI * al) / be), 3, { ask: "e^(2πα/β), to 3 places.", hint: `e^(2π × ${sn(al)} / ${be}).`,
          slips: [slip("half a turn", Math.exp((Math.PI * al) / be), "One turn takes 2π/β, so the factor is e^(2πα/β).")] }),
      ];
    },
    scene: p => ({ scene: "plane", props: { mode: "matrix", a11: p.A[0][0], a12: p.A[0][1], a21: p.A[1][0], a22: p.A[1][1], quiet: true } }),
  },
  oracle: p => {
    const [[a, b], [c, d]] = p.A, T = a + d, D = a * d - b * c, al = T / 2, be = Math.sqrt(D - (T * T) / 4);
    return [T, D, T * T - 4 * D, al, be, al < 0 ? 0 : al > 0 ? 1 : 2, c > 0 ? 1 : 0, Math.exp((2 * Math.PI * al) / be)];
  },
  useIt: {
    say: [
      "Your `A_pend` with friction: how many swings until the swing is under 1% of the start? Solve e^(2πα k/β) < 0.01 for the whole number k.",
      "With L = 1 m and β = 0.5 per second, each swing keeps 0.605 of the last, so it takes 10. The picture reads your own matrix.",
    ],
    scene: { scene: "plane", props: { mode: "pend", L: 1, beta: 0.5, swings: true, run: true } },
  },
  deeper: [
    "Euler's formula builds real solutions from a complex eigenvector v = u + iw: x(t) = e^(αt)(cos βt·u − sin βt·w), a turning, scaling pair.",
    "Every such matrix is similar to the rotation-scaling form [[α, −β], [β, α]]: a spiral is a rotation at rate β times growth at rate α, seen in tilted coordinates.",
    "The Schrödinger equation iψ′ = Hψ is a linear system with purely imaginary eigenvalues, so quantum states turn without shrinking (b2-qu-05, gates that keep total chance).",
  ],
};

/* ------------------------------------------------------------------ de-08 ------------------------------------------------------------------ */

export interface P08 { A: M2 }
/** every integer matrix with entries from −5 to 5 and D ≠ 0, by region */
const BUCKETS: M2[][] = (() => {
  const out: M2[][] = TYPES.map(() => []);
  for (let a = -5; a <= 5; a++) for (let b = -5; b <= 5; b++) for (let c = -5; c <= 5; c++) for (let d = -5; d <= 5; d++) {
    const D = a * d - b * c;
    if (D !== 0) out[region(a + d, D)]!.push([[a, b], [c, d]]);
  }
  return out;
})();

export const de08: B2Lesson<P08> = {
  id: "b2-de-08", track: "de", unit: 2, title: "The trace–determinant map",
  youCan: "classify any 2×2 linear system from two numbers, T and D, and know whether rest is stable.",
  needs: ["b2-de-06", "b2-de-07"],
  tools: ["tdmap", "plane", "matrix"],
  play: { scene: "tdmap", props: { T: -1, D: 2 },
    say: "A dot on the (T, D) plane is linked to a phase portrait. Drag the dot and watch the portrait morph: saddles below the T axis, nodes outside the parabola, spirals inside, centers on the positive D axis." },
  guess: { scene: "tdmap", props: { T: 2, D: -2, quiet: true }, kind: "point", answer: [-2, 3], near: 1.2, start: [2, -2],
    ask: "Drag the dot to where rest is stable and the paths spiral.",
    revealProps: { shade: true },
    reveal: "Stable spirals live left of the D axis and above the parabola: T < 0 and D > T²/4. The shaded patch is all of them." },
  nameIt: {
    say: [
      "Everything about a 2×2 system's rest point is in T and D, and stable means nearby paths come back to rest.",
      "On the parabola T² = 4D the two eigenvalues meet in one repeated eigenvalue, T/2: the border between nodes and spirals.",
      "Rest is stable exactly when T < 0 and D > 0.",
    ],
    formula: ["D < 0: saddle", "D > 0: T² > 4D node, T² < 4D spiral, T² = 4D border", "T < 0 stable, T > 0 unstable, T = 0 center"],
  },
  workIt: {
    reference: { A: [[-3, 1], [1, -3]] },
    generate(rng, i) {
      if (i < 3) {
        for (;;) {
          const p = rng.int(-4, 4), r = rng.int(-4, 4), q = rng.int(-3, 3);
          if (p === 0 || r === 0 || p === r) continue;
          return { A: rng.next() < 0.5 ? [[p, q], [0, r]] : [[p, 0], [q, r]] };
        }
      }
      const reg = rng.int(0, i >= 6 ? 6 : 4);
      return { A: rng.pick(BUCKETS[reg]!) };
    },
    show: p => `x′ = Ax with **A = ${mat(p.A)}**.`,
    steps(p) {
      const [[a, b], [c, d]] = p.A, T = a + d, D = a * d - b * c, disc = T * T - 4 * D, reg = region(T, D), st = T < 0 && D > 0 ? 0 : 1;
      const typeSlips = [
        reg === 0 && T < 0 && slip("D < 0 called stable", 1, "A negative determinant means eigenvalues of opposite sign. One direction always escapes, so it's a saddle."),
        reg === 0 && T < 0 && slip("D < 0 called stable", 3, "A negative determinant means eigenvalues of opposite sign. One direction always escapes, so it's a saddle."),
        reg === 0 && T > 0 && slip("D < 0 a source", 2, "A negative determinant means eigenvalues of opposite sign. One direction pulls in, so it's a saddle."),
        (reg === 1 || reg === 2) && slip("node or spiral", reg + 2, "Spirals need complex eigenvalues, which means T² < 4D."),
        (reg === 3 || reg === 4) && slip("node or spiral", reg - 2, "Nodes need real eigenvalues, T² > 4D. Here T² < 4D, so the paths spiral."),
        reg === 5 && slip("center spirals", 3, "With T = 0 every loop comes back to the same size: a center."),
        reg === 6 && slip("border a node", T < 0 ? 1 : 2, "T² = 4D exactly: the two eigenvalues are equal. That's the border between nodes and spirals."),
      ];
      return [
        multiStep("TD", "T and D", [T, D], "whole", { boxes: ["T", "D"], hint: tdHint(a, b, c, d),
          slips: [slip("ad + bc", [T, a * d + b * c], "D = ad − bc: the off-diagonal product is subtracted.")] }),
        wholeStep("disc", "T² − 4D", disc, { hint: `${sq(T)} − 4 × ${sn(D)}.`, slips: [slip("+4D", T * T + 4 * D, "The discriminant is T² − 4D, with a minus.")] }),
        tapStep("type", "Type", [...TYPES], reg, { hint: "D < 0 is a saddle. Otherwise the sign of T² − 4D picks node or spiral, and the sign of T picks in or out.", slips: typeSlips }),
        tapStep("st", "Stable?", ["Yes", "No"], st, { hint: "Rest is stable exactly when T < 0 and D > 0.",
          slips: [
            reg === 5 && slip("center stable", 0, "A center doesn't pull paths back to rest, so it isn't stable in our sense. Paths circle forever, and any small change can tip it."),
            reg === 0 && T < 0 && slip("saddle stable", 0, "A negative determinant means eigenvalues of opposite sign. One direction always escapes, so it's a saddle."),
            st === 1 && T > 0 && slip("T > 0 stable", 0, "T > 0 means the eigenvalues' real parts add to something positive: paths are pushed out."),
          ] }),
      ];
    },
    scene: p => ({ scene: "tdmap", props: { T: p.A[0][0] + p.A[1][1], D: p.A[0][0] * p.A[1][1] - p.A[0][1] * p.A[1][0], a11: p.A[0][0], a12: p.A[0][1], a21: p.A[1][0], a22: p.A[1][1], quiet: true } }),
  },
  oracle: p => {
    const [[a, b], [c, d]] = p.A, T = a + d, D = a * d - b * c, q = T * T - 4 * D;
    const type = D < 0 ? 0 : q === 0 ? 6 : q > 0 ? (T < 0 ? 1 : 2) : T === 0 ? 5 : T < 0 ? 3 : 4;
    return [T, D, q, type, T < 0 && D > 0 ? 0 : 1];
  },
  useIt: {
    say: [
      "Project: the Phase portrait gallery. Four tiles, a saddle, a node, a spiral and a center. Set a matrix in each so its dot lands in the right region of the map.",
    ],
    project: "de-gallery",
  },
  deeper: [
    "The matrix exponential e^(At) = Σ(At)ⁿ/n! solves every linear system, x(t) = e^(At)x(0). Compute it by diagonalizing, e^(At) = Pe^(Λt)P⁻¹, or with the Jordan form.",
    "Structural stability: saddles, nodes and spirals survive small changes to A, and centers and borders do not. The Hartman–Grobman theorem says a nonlinear rest point looks like its linearization unless it sits on those borders (de-12).",
    "In n dimensions, rest is stable when every eigenvalue has a negative real part, which the Routh–Hurwitz test checks from the characteristic polynomial's coefficients.",
  ],
};
