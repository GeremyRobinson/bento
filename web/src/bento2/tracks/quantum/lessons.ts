// Quantum's 12 lessons, b2-qu-01 to b2-qu-12, built from curriculum/specs/bento2/quantum.md block by block.
import type { B2Lesson, B2Step } from "../../model";
import { fracStep, multiStep, numStep, slip, tapStep, wholeStep } from "../../make";
import { group } from "../../steps";
import {
  applyGate, cnot, cosD, crossCheck, cx, fr, groverP, groverRound, hh, hhCrossed, isNiceFraction, kron, LABELS2, p0Units, par, sn, tuple,
  walsh, type Cx, type Units,
} from "./maths";

const n1 = (x: number) => group(x, 1);
/** a step that takes a fraction when the answer is one the keypad can show, else a decimal to 3 places */
const fracOr3 = (id: string, label: string, x: number, c: Parameters<typeof fracStep>[3]): B2Step =>
  isNiceFraction(x) ? fracStep(id, label, x, c) : numStep(id, label, x, 3, c);
const signs = (rng: { next(): number }, v: [number, number]): [number, number] => [v[0] * (rng.next() < 0.5 ? -1 : 1) || 0, v[1] * (rng.next() < 0.5 ? -1 : 1) || 0];
const clean = (v: number[]) => v.map(x => (Object.is(x, -0) ? 0 : x));

/* ------------------------------------------------------------------ unit 1 ------------------------------------------------------------------ */

interface P01 { a: number; b: number; th: number }
const ANGLES = [0, 60, 90, 120, 180];

export const qu01: B2Lesson<P01> = {
  id: "b2-qu-01", track: "qu", unit: 1, title: "Chances that cancel: interference",
  youCan: "find the chance of an outcome reached two ways, when the ways can cancel.",
  needs: ["b2-la-01", "pc-sinegraph"],
  tools: ["slit", "arrows"],
  play: { scene: "slit", props: { gap: 40, wave: 600 },
    say: "Dots arrive one at a time and build up stripes. Drag the slit gap and the wavelength: the stripes squeeze and spread. Switch on a detector at the slits and the stripes wash out into two plain humps." },
  guess: { scene: "arrows", props: { a: 0.3, b: 0.4, theta: 60, quiet: true }, kind: "choice", options: ["0.25", "Anywhere from 0.01 to 0.49", "Always 0"], answer: 1,
    ask: "Each slit alone gives a chance of 0.09 and 0.16 at one spot on the screen. With both open, what is the chance there?",
    revealProps: { sweep: true },
    reveal: "It depends on the angle between the two arrows. Lined up, the chance is 0.7² = 0.49; opposite, it's 0.1² = 0.01. At 60° it's 0.37." },
  nameIt: {
    say: [
      "Each way to an outcome gives an arrow, its amplitude. Add the arrows first, then square the length to get the chance.",
      "Arrows pointing opposite ways cancel, which is how a chance can drop when you open a second path.",
    ],
    formula: ["P = |a + b|² = |a|² + |b|² + 2|a||b| cos θ", "with a detector: P = |a|² + |b|²"],
  },
  workIt: {
    reference: { a: 3, b: 4, th: 60 },
    generate(rng, i) {
      if (i < 3) return { a: rng.int(1, 4), b: rng.int(1, 4), th: rng.pick([0, 180]) };
      const a = rng.int(1, 6);
      return { a, b: rng.int(1, Math.min(6, 10 - a)), th: rng.pick(ANGLES) };
    },
    show: p => `Path one's arrow has length **${n1(p.a / 10)}**, path two's has length **${n1(p.b / 10)}**, and they meet at **θ = ${p.th}°**. Answers to 2 decimal places.`,
    steps(p) {
      const a = p.a / 10, b = p.b / 10, A = n1(a), B = n1(b), cos = cosD(p.th);
      const sq = a * a + b * b, cross = 2 * a * b * cos, P = sq + cross;
      return [
        numStep("sq", "a² + b²", sq, 2, { ask: "Each path's chance on its own, added.", hint: `Square each length, then add: ${A}² + ${B}².`,
          slips: [slip("added lengths", a + b, "Each path's chance is its squared length: square each one, then add.")] }),
        numStep("cross", "2ab cos θ", cross, 2, { ask: "The cross term, where the arrows interfere.", hint: `2 × ${A} × ${B} × cos ${p.th}°, and cos ${p.th}° = ${sn(cos)}.`,
          slips: [
            slip("no 2", a * b * cos, "The cross term has a 2 in front: 2ab cos θ."),
            (p.th === 60 || p.th === 120) && a * b >= 0.04 && slip("cos 60°", 2 * a * b * (p.th === 60 ? Math.sqrt(3) / 2 : -Math.sqrt(3) / 2), `cos ${p.th}° is ${sn(cos)}.`),
          ] }),
        numStep("P", "P with both paths", P, 2, { hint: "Add the two: a² + b² + 2ab cos θ.",
          slips: [
            slip("added the chances", sq, "That's what you get when you know which path it took. Without a detector, add the arrows, then square."),
            slip("didn't square", Math.sqrt(P), p.th === 0 ? `The chance is the squared length of the sum: ${n1(a + b)}² at θ = 0°.` : "That's the length of the sum. The chance is its square."),
          ] }),
        numStep("det", "P with the detector on", sq, 2, { ask: "Now you know which slit each dot went through.", hint: "With a detector there's no cross term: add the chances.",
          slips: [slip("kept the cross term", P, "With a detector the paths stop interfering: the chance is a² + b², with no cross term.")] }),
      ];
    },
    scene: p => ({ scene: "arrows", props: { a: p.a / 10, b: p.b / 10, theta: p.th, quiet: true } }),
  },
  oracle: p => { const a = p.a / 10, b = p.b / 10, P = a ** 2 + b ** 2 + 2 * a * b * Math.cos((p.th * Math.PI) / 180); if (P < -1e-12 || P > 1 + 1e-12) throw new Error("P out of range"); return [a ** 2 + b ** 2, P - a ** 2 - b ** 2, P, a ** 2 + b ** 2]; },
  useIt: {
    say: ["Noise-canceling headphones and anti-glare lens coatings use the same canceling, with sound and light.",
      "In the build, the wrong answers get canceled this way: their arrows are made to point opposite ways."],
    scene: { scene: "arrows", props: { a: 0.5, b: 0.5, theta: 150 } },
  },
  deeper: [
    "Feynman's sum over paths: every route gets an arrow, turning once per wavelength along its length. The arrows of nearby routes cancel everywhere except near the route of least time, which is why light seems to travel in straight lines.",
    "The stripe spacing on a screen a distance L away is λL/d, for slit gap d and wavelength λ: a bigger gap squeezes the stripes, a longer wave spreads them, as the sliders show.",
    "Wave in a box: a trapped particle can only hold whole numbers of half-waves, so its energy comes in levels growing like n², 1, 4, 9, 16. That is where the \"quantum\" in quantum comes from.",
  ],
};

interface P02 { a: number; b: number; c: number; d: number }

export const qu02: B2Lesson<P02> = {
  id: "b2-qu-02", track: "qu", unit: 1, title: "Complex numbers: arrows that turn",
  youCan: "multiply complex numbers as turn-and-stretch moves and find their squared length.",
  needs: ["b2-qu-01", "g11-complex", "b2-la-05"],
  tools: ["arrows", "calc"],
  play: { scene: "arrows", props: { mode: "mult", zr: 2, zi: 1, wr: 1, wi: 1 },
    say: "Two arrows, z and w. Their product's arrow has length |z||w| and its angle is the two angles added. Drag w around the circle and watch zw spin with it." },
  guess: { scene: "arrows", props: { mode: "mult", zr: 3, zi: 4, wr: 0, wi: 1, quiet: true }, kind: "point", answer: [-4, 3], near: 1, start: [2, -2],
    ask: "z = 3 + 4i. Drag the marker to where you think i·z lands.",
    revealProps: { turn: true },
    reveal: "Multiplying by i turns z a quarter turn left, keeping its length 5: i·z = −4 + 3i." },
  nameIt: {
    say: [
      "A complex number a + bi is an arrow (a, b). Multiplying multiplies lengths and adds angles: times i turns 90°, and e^(iφ) = cos φ + i sin φ is a pure turn by φ.",
      "The squared length is z times its mirror image, the conjugate z̄ = a − bi.",
    ],
    formula: ["(a + bi)(c + di) = (ac − bd) + (ad + bc)i", "|z|² = z z̄ = a² + b²", "|zw|² = |z|²|w|²"],
  },
  workIt: {
    reference: { a: 1, b: 2, c: 3, d: -1 },
    generate(rng, i) {
      const lo = i < 3 ? 0 : -4, hi = i < 3 ? 3 : 4;
      const pair = () => { let x = 0, y = 0; while (x === 0 && y === 0) { x = rng.int(lo, hi); y = rng.int(lo, hi); } return [x, y] as const; };
      const [a, b] = pair(), [c, d] = pair();
      return { a, b, c, d };
    },
    show: p => `z = **${cx(p.a, p.b)}** and w = **${cx(p.c, p.d)}**. Multiply them, then find the squared lengths.`,
    steps(p) {
      const { a, b, c, d } = p, ac = a * c, bd = b * d, re = ac - bd, im = a * d + b * c, z2 = a * a + b * b, w2 = c * c + d * d;
      return [
        wholeStep("re", "Real part of zw", re, { hint: "The real part is ac − bd: i² = −1 turns the bd part negative.",
          slips: [slip("i² as +1", ac + bd, `i² = −1, so the real part is ac − bd = ${sn(ac)} − ${par(bd)} = ${sn(re)}.`)] }),
        wholeStep("im", "Imaginary part of zw", im, { hint: "The imaginary part is ad + bc.",
          slips: [slip("subtracted", a * d - b * c, `Both cross terms add: ad + bc = ${sn(a * d)} + ${par(b * c)} = ${sn(im)}.`)] }),
        wholeStep("z2", "|z|²", z2, { hint: `Square each part and add: ${par(a)}² + ${par(b)}².`,
          slips: [slip("a + b", a + b, `Square each part and add: ${par(a)}² + ${par(b)}² = ${z2}.`), slip("squared the sum", (a + b) ** 2, `Square each part first, then add: ${par(a)}² + ${par(b)}² = ${z2}.`)] }),
        wholeStep("w2", "|w|²", w2, { hint: `Square each part and add: ${par(c)}² + ${par(d)}².`,
          slips: [slip("a + b", c + d, `Square each part and add: ${par(c)}² + ${par(d)}² = ${w2}.`), slip("squared the sum", (c + d) ** 2, `Square each part first, then add: ${par(c)}² + ${par(d)}² = ${w2}.`)] }),
        wholeStep("zw2", "|zw|²", z2 * w2, { hint: "Lengths multiply, so squared lengths multiply too.",
          slips: [slip("added", z2 + w2, `Lengths multiply, so squared lengths multiply: ${z2} × ${w2}.`)] }),
      ];
    },
    scene: p => ({ scene: "arrows", props: { mode: "mult", zr: p.a, zi: p.b, wr: p.c, wi: p.d, quiet: true } }),
  },
  oracle: p => [p.a * p.c - p.b * p.d, p.a * p.d + p.b * p.c, p.a ** 2 + p.b ** 2, p.c ** 2 + p.d ** 2, (p.a ** 2 + p.b ** 2) * (p.c ** 2 + p.d ** 2)],
  useIt: {
    say: ["A light path's amplitude turns as it travels: one full turn per wavelength.",
      "Two paths that differ by half a wavelength meet turned 180° apart and cancel. That's the dark stripe from lesson 01."],
    scene: { scene: "arrows", props: { mode: "mult", zr: 1, zi: 0, wr: -1, wi: 0 } },
  },
  deeper: [
    "Why e^(iφ) = cos φ + i sin φ: write out the Taylor series of eˣ with x = iφ. The even powers give 1 − φ²/2! + φ⁴/4! − …, which is cos φ, and the odd powers give i(φ − φ³/3! + …), which is i sin φ.",
    "A complex number a + bi acts on the plane like the 2×2 matrix [[a, −b], [b, a]]: a turn and a stretch. Multiplying complex numbers is multiplying those matrices (b2-la-13).",
    "The pure turns e^(iφ) form the circle group U(1). In quantum mechanics, multiplying a whole state by one of them changes nothing you can measure.",
  ],
};

interface P03 { z0: Cx; z1: Cx; N: number }
const PAIRS: { z0: Cx; z1: Cx; Ns: number[] }[] = [
  { z0: [3, 0], z1: [0, 4], Ns: [100, 1000, 2500] }, { z0: [4, 0], z1: [3, 0], Ns: [100, 1000, 2500] },
  { z0: [1, 2], z1: [2, 0], Ns: [900, 1800] }, { z0: [0, 2], z1: [1, 2], Ns: [900, 1800] }, { z0: [2, 0], z1: [2, 1], Ns: [900, 1800] },
  { z0: [1, 1], z1: [1, -1], Ns: [100, 1000] }, { z0: [5, 0], z1: [0, 12], Ns: [1690] }, { z0: [1, 0], z1: [2, 2], Ns: [900, 1800] },
];
const PAIRS_EASY: { z0: Cx; z1: Cx; Ns: number[] }[] = [{ z0: [3, 0], z1: [4, 0], Ns: [100, 1000] }, { z0: [4, 0], z1: [3, 0], Ns: [100, 1000] }, { z0: [5, 0], z1: [12, 0], Ns: [1690] }];
const abs2 = (z: Cx) => z[0] ** 2 + z[1] ** 2;

export const qu03: B2Lesson<P03> = {
  id: "b2-qu-03", track: "qu", unit: 1, title: "State vectors and the Born rule",
  youCan: "scale a state so its chances add to 1, and predict measurement counts.",
  needs: ["b2-qu-02", "b2-pr-01"],
  tools: ["coin", "sphere"],
  play: { scene: "coin", props: { a0: 1, a1: 2, b0: 2, b1: 0 },
    say: "A qubit's state is two complex arrows, one for 0 and one for 1. Drag their heads: Bento rescales them so the two squares always fill one bar. Press Run and 1,000 measurements pile up into bars that settle on those squares." },
  guess: { scene: "coin", props: { a0: 3, a1: 0, b0: 0, b1: 4, quiet: true }, kind: "slider", min: 0, max: 1, step: 0.01, start: 0.5, answer: 0.64, near: 0.05, unit: "of the shots",
    format: x => x.toFixed(2),
    ask: "The state is proportional to (3, 4i). What share of 1,000 shots do you expect to read 1?",
    revealProps: { run: true },
    reveal: "|4i|² = 16 and |3|² = 9 out of 25, so 16/25 = 0.64 of the shots read 1. The run lands close to 640, not exactly on it." },
  nameIt: {
    say: [
      "A qubit is a pair of amplitudes (α, β): a blend, or superposition, of 0 and 1. Measuring gives 0 with chance |α|² and 1 with chance |β|², the Born rule, and leaves the qubit in the state it showed.",
      "Multiplying both amplitudes by the same turn e^(iφ) changes nothing you can measure.",
    ],
    formula: ["|ψ⟩ = α|0⟩ + β|1⟩", "|α|² + |β|² = 1", "P(0) = |α|², P(1) = |β|²"],
  },
  workIt: {
    reference: { z0: [1, 2], z1: [2, 0], N: 900 },
    generate(rng, i) {
      const pick = rng.pick(i < 3 ? PAIRS_EASY : PAIRS);
      return { z0: pick.z0, z1: pick.z1, N: rng.pick(pick.Ns) };
    },
    show: p => `A qubit's state is proportional to **(${cx(...p.z0)}, ${cx(...p.z1)})**. You measure it **${group(p.N)} times**.`,
    steps(p) {
      const t = abs2(p.z0) + abs2(p.z1), k = Math.sqrt(t), P0 = abs2(p.z0) / t, P1 = abs2(p.z1) / t;
      const cplx = [p.z0, p.z1].find(z => z[0] !== 0 && z[1] !== 0);
      const realAmp = (z: Cx) => (z[1] === 0 ? Math.abs(z[0]) / k : z[0] === 0 ? Math.abs(z[1]) / k : NaN);
      const ampSlip = (z: Cx, P: number) => [
        slip("amplitude", 1 / k, `The chance is the squared length: |(${cx(...z)})/${k}|² = ${fr(P)}.`),
        slip("amplitude", realAmp(z), `The chance is the squared length: |(${cx(...z)})/${k}|² = ${fr(P)}.`),
      ];
      return [
        wholeStep("t", `|${cx(...p.z0)}|² + |${cx(...p.z1)}|²`, t, { hint: "Square each part of each amplitude and add them all.",
          slips: [cplx ? slip("(a + b)²", (Math.abs(p.z0[0]) + Math.abs(p.z0[1])) ** 2 + (Math.abs(p.z1[0]) + Math.abs(p.z1[1])) ** 2,
            `Square each part and add: |${cx(...cplx)}|² = ${par(cplx[0])}² + ${par(cplx[1])}² = ${abs2(cplx)}.`) : null] }),
        fracStep("k", "Scale factor", 1 / k, { ask: "Multiply both amplitudes by this so their squares add to 1.", hint: `Divide by the square root of the total: √${t}.`,
          slips: [slip("divided by the total", 1 / t, `Divide the amplitudes by √${t} = ${k}, so their squares add to 1.`)] }),
        fracStep("p0", "P(0)", P0, { hint: `|α|² = |${cx(...p.z0)}|² / ${t}.`, slips: ampSlip(p.z0, P0) }),
        fracStep("p1", "P(1)", P1, { hint: `|β|² = |${cx(...p.z1)}|² / ${t}.`, slips: ampSlip(p.z1, P1) }),
        wholeStep("n0", `Expected 0s in ${group(p.N)} shots`, p.N * P0, { hint: `${group(p.N)} × P(0).`,
          slips: [slip("counted 1s", p.N * P1, `That's the count of 1s. The 0s are ${group(p.N)} × ${fr(P0)}.`)] }),
      ];
    },
    scene: p => ({ scene: "coin", props: { a0: p.z0[0], a1: p.z0[1], b0: p.z1[0], b1: p.z1[1], quiet: true } }),
  },
  oracle: p => { const n2 = p.z0[0] ** 2 + p.z0[1] ** 2 + p.z1[0] ** 2 + p.z1[1] ** 2, a = p.z0[0] ** 2 + p.z0[1] ** 2; return [n2, 1 / Math.sqrt(n2), a / n2, 1 - a / n2, (p.N * a) / n2]; },
  useIt: {
    say: ["Project: your quantum coin. Pick any two amplitudes, predict the chance of 0, then run 1,000 shots and see how far the count lands from the prediction.",
      "The miss is usually about √(N p(1 − p)), the 1/√n rule from b2-pr-01: about 15 shots for a fair coin. Save it to keep `psi` on your Number shelf."],
    project: "qu-coin",
  },
  deeper: [
    "States are unit vectors in a complex inner-product space, a Hilbert space. Dirac writes them |ψ⟩, and the inner product ⟨φ|ψ⟩ = Σ φᵢ* ψᵢ; |⟨φ|ψ⟩|² is the chance a state ψ passes a test for φ.",
    "A measurable quantity is a Hermitian matrix A, the complex version of symmetric (A equals its conjugate transpose). Its eigenvalues are the possible readings, and ⟨ψ|A|ψ⟩ is the average reading (b2-la-15).",
    "A particle in a box is a state vector with infinitely many entries, one per standing wave n = 1, 2, 3, …, and the Born rule still reads its chances.",
  ],
};

/* ------------------------------------------------------------------ unit 2 ------------------------------------------------------------------ */

interface P04 { th: number; p: number }

export const qu04: B2Lesson<P04> = {
  id: "b2-qu-04", track: "qu", unit: 2, title: "The qubit sphere",
  youCan: "place a qubit state on the sphere and read its chances from its height.",
  needs: ["b2-qu-03"],
  tools: ["sphere"],
  play: { scene: "sphere", props: { theta: 60, phi: 30 },
    say: "An arrow on a ball. Drag it from the top, always 0, down to the bottom, always 1: the chance bar and the two amplitudes follow. Spin it around the vertical axis and the chances don't change at all." },
  guess: { scene: "sphere", props: { theta: 120, phi: 30, quiet: true }, kind: "slider", min: 0, max: 180, step: 1, start: 90, answer: 60, near: 6, unit: "down from the top",
    format: x => `${x}°`,
    ask: "Slide the arrow down to where you think P(0) = 3/4.",
    revealProps: { ring: 60, theta: 60 },
    reveal: "θ = 60°: P(0) = cos² 30° = 3/4. The whole ring at that height has the same chances." },
  nameIt: {
    say: [
      "Every qubit state is a point on a sphere: θ down from the top, φ around. Its height is P(0) − P(1).",
      "Points opposite each other are states you can always tell apart with one measurement, like 0 and 1, even though as amplitude arrows they are only 90° apart.",
    ],
    formula: ["|ψ⟩ = cos(θ/2)|0⟩ + e^(iφ) sin(θ/2)|1⟩", "P(0) = cos²(θ/2)", "height z = cos θ = P(0) − P(1)"],
  },
  workIt: {
    reference: { th: 120, p: 9 },
    generate(rng, i) {
      if (i < 3) return { th: rng.pick(ANGLES), p: rng.pick([5, 9, 1]) };
      return { th: rng.pick(ANGLES), p: rng.int(1, 9) };
    },
    show: p => `A qubit sits at **θ = ${p.th}°** on the sphere. Then another sits where **P(0) = ${n1(p.p / 10)}**.`,
    steps(p) {
      const P0 = (1 + cosD(p.th)) / 2, z = cosD(p.th), q = p.p / 10, z2 = 2 * q - 1, th2 = (Math.acos(z2) * 180) / Math.PI;
      return [
        fracStep("p0", `P(0) at θ = ${p.th}°`, P0, { hint: `P(0) = cos²(θ/2) = cos² ${p.th / 2}°.`,
          slips: [slip("cos² θ", cosD(p.th) ** 2, `The sphere uses half angles: P(0) = cos²(θ/2) = cos² ${p.th / 2}° = ${fr(P0)}.`)] }),
        fracStep("z", "Height z", z, { hint: "z = P(0) − P(1), which is cos θ.",
          slips: [slip("z as P(0)", P0, "Height runs from +1 at the top to −1 at the bottom: P(0) − P(1).")] }),
        numStep("z2", `For P(0) = ${n1(q)}: z`, z2, 1, { hint: `z = P(0) − P(1) = ${n1(q)} − ${n1(1 - q)}.`,
          slips: [slip("z as P(0)", q, "Height is P(0) − P(1), which is 2 × P(0) − 1."), slip("backwards", -z2, "Height is P(0) − P(1): positive when 0 is more likely.")] }),
        numStep("th", "θ", th2, 1, { unit: "°", ask: "To 1 decimal place.", hint: `cos θ = z = ${n1(z2)}, so θ = arccos ${n1(z2)}.`,
          slips: [
            slip("cos θ = P(0)", (Math.acos(q) * 180) / Math.PI, `Use the height, not the chance: cos θ = z = ${n1(z2)}.`),
            slip("half angle", (Math.acos(Math.sqrt(q)) * 180) / Math.PI, "That's θ/2: P(0) = cos²(θ/2), so double it."),
          ] }),
      ];
    },
    scene: p => ({ scene: "sphere", props: { theta: p.th, phi: 0, quiet: true } }),
  },
  oracle: p => [Math.cos((p.th * Math.PI) / 360) ** 2, Math.cos((p.th * Math.PI) / 180), 2 * (p.p / 10) - 1, (Math.acos(2 * (p.p / 10) - 1) * 180) / Math.PI],
  useIt: {
    say: ["A qubit pointing along the equator, θ = 90°, is a fair coin whatever its φ. Spin it around and run 1,000 shots at three different φ: three fair coins.",
      "They are three different states, though. The next two lessons tell them apart."],
    scene: { scene: "sphere", props: { theta: 90, phi: 0, run: true } },
  },
  deeper: [
    "Mixed states: a qubit you are unsure about is a point inside the ball, described by a density matrix ρ = ½(I + r·σ), where r is the point and σ = (X, Y, Z). ρ is a 2×2 Hermitian matrix with trace 1, and its eigenvalues are the chances of the mix (b2-la-15).",
    "Why half angles: the 2×2 unitary matrices SU(2) cover the 3D turns twice. A 360° turn of the sphere multiplies the state by −1; it takes 720° to come back to the same amplitudes.",
  ],
};

interface P05 { a: number; b: number; gates: ("X" | "Z" | "H")[] }
const STARTS: [number, number][] = [[1, 0], [0, 1], [3 / 5, 4 / 5], [4 / 5, 3 / 5], [5 / 13, 12 / 13], [12 / 13, 5 / 13]];
const unitsAsk = (s: Units) => (s.r ? "In units of 1/√2: type √2 × each amplitude." : "As plain amplitudes.");
const stateDone = (label: string, s: Units) => `${label}: ${tuple(s.u)}${s.r ? "/√2" : ""}`;

function gateStep(id: string, label: string, before: Units, g: "X" | "Z" | "H"): B2Step {
  const after = applyGate(before, g), [a, b] = before.u;
  const hint = g === "X" ? "X swaps the two amplitudes." : g === "Z" ? "Z flips the sign of the 1 amplitude."
    : before.r ? "Two H gates divide by √2 twice, which is 2: halve the sum and the difference." : "H makes the sum and the difference: (α + β, α − β), in units of 1/√2.";
  const k = before.r ? 0.5 : 1;
  const slips = g === "X" ? [slip("X as Z", [a, -b], "That's Z. X swaps the two amplitudes; it doesn't change signs."), slip("X changed signs", [-b, -a], "X swaps the two amplitudes; it doesn't change signs.")]
    : g === "Z" ? [slip("Z on the 0 amplitude", [-a, b], "Z leaves the 0 amplitude and flips the sign of the 1 amplitude."), slip("Z as X", [b, a], "That's X. Z leaves the 0 amplitude and flips the sign of the 1 amplitude.")]
      : [slip("H backwards", [k * (a - b), k * (a + b)], "The sum goes first: H sends (α, β) to (α + β, α − β)."),
        before.r && slip("didn't halve", [a + b, a - b], "Two H gates in a row divide by √2 twice, which is 2: halve the sum and the difference.")];
  return multiStep(id, label, clean(after.u), "fraction", { boxes: ["0", "1"], ask: unitsAsk(after), hint, slips, done: stateDone(label, after) });
}

export const qu05: B2Lesson<P05> = {
  id: "b2-qu-05", track: "qu", unit: 2, title: "Gates are matrices",
  youCan: "apply X, Z and H to a qubit as matrices and read off the new chances.",
  needs: ["b2-qu-04", "b2-la-05", "b2-la-16"],
  tools: ["circuit", "matrix", "sphere"],
  play: { scene: "circuit", props: { gates: "H" },
    say: "Tap gates onto one qubit line. X flips the arrow upside down, Z spins it half a turn around the vertical, and H swaps the top with the front of the sphere. Each gate's 2×2 matrix and the state after it show under the line." },
  guess: { scene: "sphere", props: { theta: 0, phi: 0, quiet: true }, kind: "choice", options: ["You end at 0", "You end at 1", "A fair coin"], answer: 0,
    ask: "Start at 0 and apply H twice. Where do you end up?",
    revealProps: { gates: "HH" },
    reveal: "Back at 0. H is a half turn about the diagonal, so two of them make a full turn: H undoes itself." },
  nameIt: {
    say: [
      "A gate is a 2×2 matrix that keeps the total chance at 1, a unitary: U†U = I, where U† is U flipped across its diagonal with every entry conjugated. For real matrices it's just the transpose, as in b2-la-16.",
      "X swaps the amplitudes, Z flips the sign of the second, and H makes a sum and a difference.",
    ],
    formula: ["X = [[0, 1], [1, 0]]  Z = [[1, 0], [0, −1]]", "H = (1/√2)[[1, 1], [1, −1]]", "H(α, β) = ((α + β)/√2, (α − β)/√2)"],
  },
  workIt: {
    reference: { a: 3 / 5, b: 4 / 5, gates: ["H", "H"] },
    generate(rng, i) {
      const [a, b] = signs(rng, rng.pick(STARTS));
      const n = i < 3 ? 1 : rng.int(1, 3);
      return { a, b, gates: Array.from({ length: n }, () => rng.pick(["X", "Z", "H"] as const)) };
    },
    show: p => `A qubit starts at **(${sn(p.a)}, ${sn(p.b)})**. Apply **${p.gates.join(", then ")}**.`,
    steps(p) {
      const out: B2Step[] = [];
      let s: Units = { u: [p.a, p.b], r: false };
      const g1 = p.gates[0]!;
      if (g1 === "H") {
        out.push(fracStep("sum", "α + β", p.a + p.b, { hint: `${sn(p.a)} + ${par(p.b)}.` }));
        out.push(fracStep("diff", "α − β", p.a - p.b, { hint: `${sn(p.a)} − ${par(p.b)}.`, slips: [slip("β − α", p.b - p.a, "α − β: the 0 amplitude minus the 1 amplitude.")] }));
      }
      out.push(gateStep("g1", `After ${g1}: new state`, s, g1));
      s = applyGate(s, g1);
      const P0 = p0Units(s);
      out.push(fracStep("p0", "P(0)", P0, { hint: s.r ? `P(0) = (${sn(s.u[0])})² / 2: square, then halve for the 1/√2.` : `P(0) = (${sn(s.u[0])})².`,
        slips: [
          s.r && slip("forgot 1/√2", s.u[0] ** 2, `${s.u[0] ** 2 > 1 ? "A chance over 1 means a missing factor: " : ""}H divides by √2, so P(0) = (${sn(s.u[0])})²/2 = ${fr(P0)}.`),
          slip("amplitude", Math.abs(s.u[0]) * (s.r ? Math.SQRT1_2 : 1), "That's the amplitude's length. The chance is its square."),
          slip("P(1)", 1 - P0, "That's P(1). P(0) comes from the 0 amplitude."),
        ] }));
      p.gates.slice(1).forEach((g, k) => { out.push(gateStep(`g${k + 2}`, `Apply ${g}: new state`, s, g)); s = applyGate(s, g); });
      return out;
    },
    scene: p => ({ scene: "circuit", props: { gates: p.gates.join(""), a: p.a, b: p.b, quiet: true } }),
  },
  oracle: p => {
    const r = Math.SQRT1_2, M = { X: [[0, 1], [1, 0]], Z: [[1, 0], [0, -1]], H: [[r, r], [r, -r]] };
    let v = [p.a, p.b], hs = 0;
    const out: number[] = [];
    if (p.gates[0] === "H") out.push(p.a + p.b, p.a - p.b);
    p.gates.forEach((g, k) => {
      const m = M[g]; v = [m[0]![0]! * v[0]! + m[0]![1]! * v[1]!, m[1]![0]! * v[0]! + m[1]![1]! * v[1]!];
      if (g === "H") hs++;
      const unit = hs % 2 ? Math.SQRT2 : 1;
      out.push(v[0]! * unit, v[1]! * unit);
      if (k === 0) out.push(v[0]! ** 2);
    });
    return out;
  },
  useIt: {
    say: ["HZH = X: put H, Z, H on the line and the board's total matrix comes out as X. Check it in the Matrix pad by multiplying the three matrices.",
      "Gates can be built from other gates. That is what a quantum compiler does."],
    scene: { scene: "circuit", props: { gates: "HZH" } },
  },
  deeper: [
    "The Pauli matrices X, Y = [[0, −i], [i, 0]] and Z, and every one-qubit gate as a turn of the sphere: U = e^(−iθ(n·σ)/2) turns by θ about the axis n.",
    "Universal gate sets: H and the T gate (a phase of 45°) reach any one-qubit gate as closely as you like, and the Solovay–Kitaev theorem says it takes only about log(1/ε)^c gates to get within ε. Every unitary has eigenvalues on the unit circle (b2-la-13).",
    "The Pauli matrices return in the Dirac equation, where they hold the electron's spin (b2-re-08).",
  ],
};

interface P06 { phi: number | null; P: number | null }

export const qu06: B2Lesson<P06> = {
  id: "b2-qu-06", track: "qu", unit: 2, title: "Phase becomes chance: H, phase, H",
  youCan: "turn a hidden phase into a measurable chance with an H, phase, H circuit.",
  needs: ["b2-qu-05"],
  tools: ["hph", "sphere"],
  play: { scene: "hph", props: { phi: 60 },
    say: "The circuit H, phase(φ), H on one qubit. Drag φ: after the first H the chances are always 50/50, but after the second H the chance of 0 swings smoothly from 1 down to 0 and back." },
  guess: { scene: "hph", props: { phi: 120, quiet: true }, kind: "slider", min: 0, max: 1, step: 0.01, start: 0.5, answer: 0.25, near: 0.06, unit: "chance of 0",
    format: x => x.toFixed(2),
    ask: "With φ = 120°, what is the chance of 0 at the end?",
    revealProps: { sum: true },
    reveal: "The second H adds the arrows 1 and e^(i·120°). Their sum has length 1, and halved it's 1/2, so P(0) = (1/2)² = 1/4." },
  nameIt: {
    say: [
      "A phase can't be seen by measuring right away, but a second H adds the two amplitudes together, and how well they line up decides the chance.",
      "That turns a phase into a chance, and it is how every quantum algorithm reads out its answer.",
    ],
    formula: ["amplitude of 0 = (1 + e^(iφ))/2", "P(0) = (1 + cos φ)/2 = cos²(φ/2)"],
  },
  workIt: {
    reference: { phi: 120, P: null },
    generate(rng, i) {
      if (i < 3) return { phi: rng.pick([0, 180]), P: null };
      if (i >= 4 && rng.next() < 0.5) return { phi: null, P: rng.pick([1, 3 / 4, 1 / 2, 1 / 4, 0]) };
      return { phi: rng.pick([...ANGLES, 45, 135]), P: null };
    },
    show: p => p.phi != null ? `The circuit H, phase(**φ = ${p.phi}°**), H acts on a qubit that starts at 0.`
      : `You want the circuit H, phase(φ), H to give 0 with chance **${fr(p.P!)}**. Find φ from 0° to 180°.`,
    steps(p) {
      if (p.phi == null) {
        const P = p.P!, c = 2 * P - 1, phi = Math.round((Math.acos(c) * 180) / Math.PI);
        return [
          fracStep("cos", "cos φ", c, { hint: "P(0) = (1 + cos φ)/2, so cos φ = 2 × P(0) − 1.",
            slips: [slip("cos φ = P", P, "P(0) = (1 + cos φ)/2, so cos φ = 2 × P(0) − 1."), slip("1 − 2P", -c, "That's P(1)'s formula. For P(0) the arrows add: cos φ = 2 × P(0) − 1.")] }),
          wholeStep("phi", "φ", phi, { unit: "°", hint: `The angle from 0° to 180° whose cosine is ${sn(c)}.`,
            slips: [slip("half angle", Math.round((Math.acos(Math.sqrt(P)) * 180) / Math.PI), `That's φ/2: P(0) = cos²(φ/2), so φ/2 = ${Math.round((Math.acos(Math.sqrt(P)) * 180) / Math.PI)}° and φ = ${phi}°.`)] }),
        ];
      }
      const c = cosD(p.phi), P0 = (1 + c) / 2;
      return [
        fracStep("first", "Chance of 0 after the first H", 1 / 2, { hint: "H makes two arrows of equal length.",
          slips: [slip("phase changed it", P0, "Right after H the two arrows have equal length, so it's 50/50 whatever the phase.")] }),
        fracOr3("cos", "cos φ", c, { hint: `cos ${p.phi}°.` }),
        fracOr3("P", "P(0) at the end", P0, { hint: "P(0) = (1 + cos φ)/2.",
          slips: [
            slip("cos² φ", c * c, `Half the phase: cos²(φ/2). At ${p.phi}° that's cos² ${n1(p.phi / 2).replace(".0", "")}° = ${isNiceFraction(P0) ? fr(P0) : group(P0, 3)}.`),
            slip("1 − cos φ", (1 - c) / 2, "That's P(1). The arrows add for 0 and subtract for 1."),
          ] }),
      ];
    },
    scene: p => ({ scene: "hph", props: { phi: p.phi ?? 90, quiet: true } }),
  },
  oracle: p => p.phi != null
    ? [0.5, Math.cos((p.phi * Math.PI) / 180), (1 + Math.cos((p.phi * Math.PI) / 180)) / 2]
    : [2 * p.P! - 1, (Math.acos(2 * p.P! - 1) * 180) / Math.PI],
  useIt: {
    say: ["Project: dial a chance. Make a circuit that comes up 0 one time in four, φ = 120°, and check it over 1,000 shots. Save it to keep `dial`.",
      "With φ = 180° the phase becomes a sure 1: that is the \"flip the sign, then H\" move the build uses."],
    project: "qu-dial",
  },
  deeper: [
    "The Mach–Zehnder interferometer is this circuit made of mirrors: a half-silvered mirror is H, a longer arm is the phase. The Elitzur–Vaidman bomb tester uses it to find a bomb on one arm without setting it off, some of the time.",
    "Measuring in a different basis: H, then measure, reads X instead of Z. X and Z don't commute (XZ = −ZX), and the uncertainty relation ΔA ΔB ≥ ½|⟨[A, B]⟩| says you can't have both sharp at once (b2-la-06).",
  ],
};

/* ------------------------------------------------------------------ unit 3 ------------------------------------------------------------------ */

const QUBITS: [number, number][] = [[1, 0], [0, 1], [3 / 5, 4 / 5], [4 / 5, 3 / 5], [5 / 13, 12 / 13], [8 / 17, 15 / 17]];
const SMALL_DEN = (q: [number, number]) => q.every(x => Math.abs(x * 5 - Math.round(x * 5)) < 1e-9);
/** two qubits whose products keep the keypad's fractions short: at least one of them in fifths (or 0 and 1) */
function twoQubits(rng: Parameters<B2Lesson<unknown>["workIt"]["generate"]>[0], tops: [number, number][], bots: [number, number][]): [[number, number], [number, number]] {
  for (;;) {
    const t = signs(rng, rng.pick(tops)), b = signs(rng, rng.pick(bots));
    if (SMALL_DEN(t) || SMALL_DEN(b)) return [t, b];
  }
}

interface P07 { top: [number, number]; bot: [number, number]; ask: number; n: number | null }

export const qu07: B2Lesson<P07> = {
  id: "b2-qu-07", track: "qu", unit: 3, title: "Two qubits: four amplitudes",
  youCan: "combine two qubits into one four-amplitude state and read joint chances.",
  needs: ["b2-qu-05", "b2-la-06"],
  tools: ["grid", "matrix"],
  play: { scene: "grid", props: { a: 0.6, b: 0.8, c: 1, d: 0 },
    say: "Two qubits, each with its own pair of amplitudes. The product grid shows the four combined amplitudes as a 2×2 grid, a column times a row. Drag either qubit and its row or column of the grid rescales." },
  guess: { scene: "grid", props: { a: 0.6, b: 0.8, c: 5 / 13, d: 12 / 13, quiet: true }, kind: "slider", min: 0, max: 0.5, step: 0.005, start: 0.25, answer: 16 / 169, near: 0.03, unit: "",
    format: x => x.toFixed(3),
    ask: "The top qubit reads 1 with chance 16/25, the bottom reads 0 with chance 25/169. What is the chance of reading 10?",
    revealProps: { light: 2 },
    reveal: "Independent chances multiply: 16/25 × 25/169 = 16/169, about 0.095. The 10 cell lights up." },
  nameIt: {
    say: [
      "Two qubits together have four amplitudes, one each for 00, 01, 10 and 11. For two separate qubits, each combined amplitude is a product of one from each, the tensor product, so chances multiply.",
      "n qubits need 2ⁿ amplitudes.",
    ],
    formula: ["(a, b) ⊗ (c, d) = (ac, ad, bc, bd)", "in the order 00, 01, 10, 11; the left digit is the top qubit"],
  },
  workIt: {
    reference: { top: [3 / 5, 4 / 5], bot: [5 / 13, 12 / 13], ask: 2, n: null },
    generate(rng, i) {
      const easy: [number, number][] = [[1, 0], [0, 1]];
      let [top, bot] = twoQubits(rng, QUBITS, QUBITS);
      if (i < 3) { if (rng.next() < 0.5) top = signs(rng, rng.pick(easy)); else bot = signs(rng, rng.pick(easy)); }
      return { top, bot, ask: rng.int(0, 3), n: i >= 4 ? rng.int(3, 12) : null };
    },
    show: p => `The top qubit is **${tuple(p.top)}** and the bottom one is **${tuple(p.bot)}**.${p.n ? ` Then: how many amplitudes do **${p.n} qubits** need?` : ""}`,
    steps(p) {
      const v = clean(kron(p.top, p.bot)), names = ["a", "b"], bn = ["c", "d"];
      const steps: B2Step[] = v.map((x, k) => {
        const i = k >> 1, j = k & 1, lab = LABELS2[k]!;
        const swapped = p.top[j]! * p.bot[i]!;
        return fracStep(`a${lab}`, `Amplitude of ${lab}`, x, { hint: `Top ${lab[0]} times bottom ${lab[1]}: ${names[i]} × ${bn[j]} = ${par(p.top[i]!)} × ${par(p.bot[j]!)}.`,
          slips: [
            i !== j && slip("wrong order", swapped, `The left digit is the top qubit: ${lab} means top ${lab[0]}, bottom ${lab[1]}, so ${names[i]} × ${bn[j]}.`),
            slip("added", p.top[i]! + p.bot[j]!, "Independent qubits combine like independent coins: multiply."),
          ] });
      });
      const lab = LABELS2[p.ask]!, P = v[p.ask]! ** 2;
      steps.push(fracStep("P", `P(${lab})`, P, { hint: `Square the amplitude of ${lab}.`,
        slips: [slip("amplitude", v[p.ask]!, `That's the amplitude; the chance is its square, ${fr(P)}.`), slip("amplitude", Math.abs(v[p.ask]!), `That's the amplitude's length; the chance is its square, ${fr(P)}.`)] }));
      if (p.n) steps.push(wholeStep("n", `Amplitudes for ${p.n} qubits`, 2 ** p.n, { hint: "Each qubit you add doubles the count.",
        slips: [slip("2n", 2 * p.n, `Each qubit doubles the count: 2ⁿ, not 2 × n. Here 2 to the power ${p.n}.`), slip("n²", p.n ** 2, `Each qubit doubles the count: 2ⁿ, not n². Here 2 to the power ${p.n}.`)] }));
      return steps;
    },
    scene: p => ({ scene: "grid", props: { a: p.top[0], b: p.top[1], c: p.bot[0], d: p.bot[1], quiet: true } }),
  },
  oracle: p => {
    const v = [p.top[0] * p.bot[0], p.top[0] * p.bot[1], p.top[1] * p.bot[0], p.top[1] * p.bot[1]];
    return [...v, v[p.ask]! ** 2, ...(p.n ? [2 ** p.n] : [])];
  },
  useIt: {
    say: ["50 qubits need 2⁵⁰ ≈ 1.13 × 10¹⁵ amplitudes: about 18 petabytes at 16 bytes per amplitude, two 8-byte numbers.",
      "That is why big quantum circuits can't be simulated by brute force (b2-cs-08)."],
    scene: { scene: "grid", props: { a: 0.6, b: 0.8, c: 0.8, d: 0.6 } },
  },
  deeper: [
    "The tensor product of vector spaces: dimensions multiply, 2 × 2 = 4, so n qubits live in a space of dimension 2ⁿ.",
    "A gate U on the top qubit acts on two qubits as the 4×4 matrix U ⊗ I, the Kronecker product: each entry of U becomes a 2×2 block, that entry times I.",
    "A classical computer needs memory exponential in n to follow a general state. That alone doesn't prove quantum speedups: many circuits, like ones with little entanglement, can be simulated cheaply.",
  ],
};

interface P08 { top: [number, number]; bot: [number, number]; rt: boolean }
const BOTTOMS: [number, number][] = [[1, 0], [0, 1], [3 / 5, 4 / 5], [4 / 5, 3 / 5], [5 / 13, 12 / 13], [8 / 17, 15 / 17]];
const READS = ["0, for sure", "1, for sure", "either one, by chance"];

export const qu08: B2Lesson<P08> = {
  id: "b2-qu-08", track: "qu", unit: 3, title: "CNOT and entanglement",
  youCan: "apply a CNOT and tell whether a two-qubit state is entangled.",
  needs: ["b2-qu-07", "b2-cs-04"],
  tools: ["grid", "pair", "matrix"],
  play: { scene: "grid", props: { a: Math.SQRT1_2, b: Math.SQRT1_2, c: 1, d: 0, cnot: true },
    say: "H on the top qubit, then a CNOT. Switch it on: the grid no longer splits into a column times a row, and ps − qr stops being 0. Measure the top qubit: the bottom always matches." },
  guess: { scene: "grid", props: { a: 1, b: 0, c: 1, d: 0, quiet: true }, kind: "choice", options: ["(1/2, 0, 0, 1/2)", "(1/4, 1/4, 1/4, 1/4)", "(1/2, 1/2, 0, 0)"], answer: 0,
    ask: "Start at 00, apply H to the top qubit, then CNOT. What are the chances of 00, 01, 10 and 11?",
    revealProps: { steps: true },
    reveal: "H makes (1, 0, 1, 0)/√2; CNOT swaps the last two entries to (1, 0, 0, 1)/√2. Half 00, half 11, never 01 or 10." },
  nameIt: {
    say: [
      "CNOT flips the bottom qubit when the top one is 1: it swaps the amplitudes of 10 and 11.",
      "A two-qubit state (p, q, r, s) is a product of two separate qubits exactly when ps = qr. Otherwise it is entangled: neither qubit has a state of its own, but their results are linked.",
    ],
    formula: ["CNOT (p, q, r, s) = (p, q, s, r)", "entangled when ps − qr ≠ 0", "Bell state (|00⟩ + |11⟩)/√2"],
  },
  workIt: {
    reference: { top: [3 / 5, 4 / 5], bot: [1, 0], rt: false },
    generate(rng, i) {
      const tops = QUBITS.slice(1);
      if (i < 3) return { top: signs(rng, rng.pick(QUBITS.slice(2, 4))), bot: [1, 0], rt: false };
      if (rng.next() < 0.3) return { top: signs(rng, rng.pick(tops)), bot: [1, rng.pick([1, -1])], rt: true };
      const [top, bot] = twoQubits(rng, tops, BOTTOMS);
      return { top, bot, rt: false };
    },
    show: p => `The top qubit is **${tuple(p.top)}** and the bottom one is **${p.rt ? `${tuple(p.bot)}/√2` : tuple(p.bot)}**. Apply a CNOT, top qubit the control.${p.rt ? " Amplitudes in units of 1/√2." : ""}`,
    steps(p) {
      const v = clean(kron(p.top, p.bot)), w = cnot(v), k = p.rt ? 0.5 : 1;
      const x = crossCheck(w) * k, ent = Math.abs(x) > 1e-12 ? 0 : 1;
      const [r1, s1] = [w[2]!, w[3]!], read = Math.abs(r1) < 1e-12 ? 1 : Math.abs(s1) < 1e-12 ? 0 : 2;
      const boxes = LABELS2, ask = p.rt ? "In units of 1/√2." : undefined;
      return [
        multiStep("prod", "Product state", v, "fraction", { boxes, ask, hint: "(a, b) ⊗ (c, d) = (ac, ad, bc, bd).",
          slips: [slip("wrong order", [v[0]!, v[2]!, v[1]!, v[3]!], "The left digit is the top qubit: 01 means top 0, bottom 1, so a × d.")],
          done: `Product state: ${tuple(v)}${p.rt ? "/√2" : ""}` }),
        multiStep("cnot", "After CNOT", w, "fraction", { boxes, ask, hint: "CNOT swaps the amplitudes of 10 and 11.",
          slips: [
            slip("swapped 01 and 10", [v[0]!, v[2]!, v[1]!, v[3]!], "CNOT only acts when the top (left) qubit is 1, so it swaps the last two entries."),
            slip("changed the control", [v[0]!, v[3]!, v[2]!, v[1]!], "The top qubit is the control: CNOT flips the bottom one when the top is 1, so it swaps 10 and 11."),
            slip("no change", v, "CNOT swaps the amplitudes of 10 and 11."),
          ],
          done: `After CNOT: ${tuple(w)}${p.rt ? "/√2" : ""}` }),
        fracStep("x", "ps − qr", x, { ask: p.rt ? "With the real amplitudes: each product of two carries 1/2." : undefined, hint: "Outer pair times each other, minus the inner pair: p × s − q × r.",
          slips: [slip("before CNOT", 0, "Use the state after the CNOT: p, q, r and s are its four amplitudes."), slip("qr − ps", -x, "ps − qr: the outer pair minus the inner pair.")] }),
        tapStep("ent", "Entangled?", ["yes", "no"], ent, { hint: "Entangled exactly when ps − qr isn't 0.",
          slips: [slip("entangled?", 1 - ent, ent === 0 ? `ps − qr = ${sn(x)}, not 0, so the grid can't be split into a column times a row: entangled.`
            : p.rt ? `CNOT doesn't always entangle. Not when the bottom qubit is ${tuple(p.bot)}/√2: flipping it changes nothing but a sign, so ps − qr stays 0.`
              : "ps − qr = 0: the grid is still a column times a row, so it's a product state.")] }),
        tapStep("read", "If the top reads 1, the bottom reads", READS, read, { hint: "When the top reads 1, only 10 and 11 are left.",
          slips: [0, 1, 2].filter(j => j !== read).map(j => slip(`read ${j}`, j, `When the top reads 1, only 10 and 11 are left: their amplitudes are ${sn(r1)} and ${sn(s1)}${p.rt ? " in units of 1/√2" : ""}.`)) }),
      ];
    },
    scene: p => ({ scene: "grid", props: { a: p.top[0], b: p.top[1], c: p.rt ? p.bot[0] * Math.SQRT1_2 : p.bot[0], d: p.rt ? p.bot[1] * Math.SQRT1_2 : p.bot[1], cnot: true, quiet: true } }),
  },
  oracle: p => {
    const k = p.rt ? Math.SQRT1_2 : 1, c = p.bot[0] * k, d = p.bot[1] * k;
    const v = [p.top[0] * c, p.top[0] * d, p.top[1] * c, p.top[1] * d], w = [v[0]!, v[1]!, v[3]!, v[2]!];
    const x = w[0]! * w[3]! - w[1]! * w[2]!;
    return [...v.map(t => t / k), ...w.map(t => t / k), x, Math.abs(x) > 1e-12 ? 0 : 1, Math.abs(w[2]!) < 1e-12 ? 1 : Math.abs(w[3]!) < 1e-12 ? 0 : 2];
  },
  useIt: {
    say: ["Make the Bell state from 00 with H then CNOT, and run 1,000 pairs: about half read 00, half read 11, and never 01 or 10.",
      "Moving the two qubits far apart doesn't change that."],
    scene: { scene: "pair", props: { a: 0, b: 0 } },
  },
  deeper: [
    "The no-cloning theorem: no gate copies an unknown state. If U(ψ ⊗ 0) = ψ ⊗ ψ for every ψ, linearity applied to ψ = (0 + 1)/√2 gives (00 + 11)/√2, but copying it should give (0 + 1)(0 + 1)/2. The two disagree, so no such U exists.",
    "The Schmidt decomposition of a two-qubit state is the SVD of its 2×2 grid [[p, q], [r, s]]. The number of nonzero σ's says whether it's entangled: one for a product, two for entangled (b2-la-17).",
    "Entanglement entropy: with Schmidt values σ₁, σ₂, the entropy −Σ σᵢ² log₂ σᵢ² is 0 bits for a product and 1 bit for a Bell state (b2-in-03).",
  ],
};

interface P09 { a: number; b: number; game: boolean }
const EXACT_COS2: Record<number, number> = { 0: 1, 30: 3 / 4, 45: 1 / 2, 60: 1 / 4, 90: 0 };
const cos2 = (d: number) => EXACT_COS2[d] ?? Math.cos((d * Math.PI) / 180) ** 2;

export const qu09: B2Lesson<P09> = {
  id: "b2-qu-09", track: "qu", unit: 3, title: "Bell's matching game",
  youCan: "predict how often entangled pairs match at two analyzer angles, and why no hidden plan can do as well.",
  needs: ["b2-qu-08", "b2-pr-01"],
  tools: ["pair"],
  play: { scene: "pair", props: { a: 0, b: 30 },
    say: "Bell pairs fly to two analyzers. At equal dials they always match; as the dials move apart, the match rate falls smoothly. Game mode counts wins." },
  guess: { scene: "pair", props: { a: 0, b: 30, quiet: true }, kind: "slider", min: 0, max: 1, step: 0.01, start: 0.5, answer: 0.75, near: 0.05, unit: "match rate",
    format: x => x.toFixed(2),
    ask: "With the dials 30° apart, how often do the two results match?",
    revealProps: { run: true },
    reveal: "cos² 30° = 3/4. The run of 1,000 pairs lands near 750 matches, on the curve." },
  nameIt: {
    say: [
      "For the Bell state, two analyzers at angles a and b agree with chance cos²(a − b). These are angles on paper, like polarizers, which are half the angles on the qubit sphere.",
      "In the CHSH game, players who agree on any plan in advance win at most 3 times in 4. Entangled pairs win about 85.4% of the time. That gap is what experiments test, and the plan-in-advance idea loses.",
    ],
    formula: ["P(same) = cos²(a − b)", "best plan in advance: win 3/4", "entangled: win cos² 22.5° ≈ 0.854"],
  },
  workIt: {
    reference: { a: 0, b: 30, game: true },
    generate(rng, i) {
      if (i < 3) { const d = rng.pick([0, 45, 90]), a = rng.pick([0, 15, 30, 45, 60, 75, 90].filter(x => x + d <= 90)); return rng.next() < 0.5 ? { a, b: a + d, game: false } : { a: a + d, b: a, game: false }; }
      return { a: rng.int(0, 6) * 15, b: rng.int(0, 6) * 15, game: i >= 3 };
    },
    show: p => `Alice's analyzer is at **${p.a}°** and Bob's is at **${p.b}°**; they share a Bell pair.${p.game ? " Then they play the CHSH game." : ""}`,
    steps(p) {
      const d = Math.abs(p.a - p.b), S = cos2(d);
      const steps: B2Step[] = [
        fracOr3("same", "P(same)", S, { hint: `cos²(${d}°).`,
          slips: [slip("cos, not cos²", Math.cos((d * Math.PI) / 180), "Chances come from squared amplitudes: cos²."), slip("sphere angle", cos2(d / 2), "These are paper angles, like polarizers: use the full difference.")] }),
        fracOr3("diff", "P(different)", 1 - S, { hint: "1 − P(same).",
          slips: [slip("same", S, "That's the chance they match. Different is 1 minus it.")] }),
      ];
      if (p.game) {
        const q = Math.cos(Math.PI / 8) ** 2;
        steps.push(
          numStep("win", "Game: chance of winning each round", q, 3, { ask: "Alice's dial is 0° or 45° and Bob's is 22.5° or −22.5°, set by the questions. On every question pair, the winning result has chance cos² 22.5°.", hint: "cos² 22.5°.",
            slips: [slip("classical", 3 / 4, "That's the best plan without entanglement. Entangled pairs win cos² 22.5°.")] }),
          fracStep("plan", "Best plan without entanglement", 3 / 4, { hint: "Try fixed answers for the four question pairs: one of them always loses.",
            slips: [slip("a plan can always win", 1, "Any fixed plan loses at least one of the four question pairs, so at most 3/4."), slip("quantum", q, "That's the entangled pairs' rate. A plan in advance does at most 3/4.")] }),
        );
      }
      return steps;
    },
    scene: p => ({ scene: "pair", props: { a: p.a, b: p.b, quiet: true } }),
  },
  oracle: p => {
    const d = ((p.a - p.b) * Math.PI) / 180, S = Math.cos(d) ** 2;
    return [S, 1 - S, ...(p.game ? [Math.cos(Math.PI / 8) ** 2, 0.75] : [])];
  },
  useIt: {
    say: ["Project: Bell pair lab. Make all four Bell states, adding X or Z before the CNOT, tell each apart by its matching pattern, and play 100 rounds of the game with your favorite.",
      "Save it to keep `bell` on your Number shelf."],
    project: "qu-bell",
  },
  deeper: [
    "The CHSH inequality: S = E(a, b) + E(a, b′) + E(a′, b) − E(a′, b′) satisfies |S| ≤ 2 for any local hidden-variable theory, proved by checking the 16 deterministic plans. Quantum mechanics reaches Tsirelson's bound 2√2. The win rate is ½ + S/8, so 3/4 against about 0.854.",
    "Loopholes, detection and locality, were closed together in the loophole-free experiments of 2015, and the 2022 Nobel Prize went to Aspect, Clauser and Zeilinger for this line of work.",
    "Teleportation uses one Bell pair and two classical bits. Alice holds ψ = (α, β) and one half of (|00⟩ + |11⟩)/√2. She applies CNOT from ψ to her half, then H on ψ, and measures both (m₁, m₂); each result has chance 1/4. Bob's qubit is then (α, β) for 00, so he does nothing; (β, α) for 01, so he applies X; (α, −β) for 10, so he applies Z; (−β, α) for 11, so he applies X then Z. Nothing moves faster than light, and no copy is left behind.",
  ],
};

/* ------------------------------------------------------------------ unit 4 ------------------------------------------------------------------ */

interface P10 { f: number[] }
const CONSTANT = [[0, 0, 0, 0], [1, 1, 1, 1]];
const BALANCED = [[0, 0, 1, 1], [1, 1, 0, 0], [0, 1, 0, 1], [1, 0, 1, 0], [0, 1, 1, 0], [1, 0, 0, 1]];
const LABELS1 = ["0", "1"];

export const qu10: B2Lesson<P10> = {
  id: "b2-qu-10", track: "qu", unit: 4, title: "One question instead of three: Deutsch–Jozsa",
  youCan: "run a sign-flip oracle and tell a constant function from a balanced one with one question.",
  needs: ["b2-qu-06", "b2-qu-07", "b2-cs-06"],
  tools: ["dj", "sphere"],
  play: { scene: "dj", props: { f: "0110" },
    say: "A hidden function f takes 2 bits to 0 or 1: the same output for all four inputs (constant), or 0 for exactly two (balanced). Tap f's four output cells, then step the circuit H, oracle, H: the four sign bars and the 00 bar update live." },
  guess: { scene: "dj", props: { f: "0011", quiet: true }, kind: "choice", options: ["1", "1/2", "1/4", "0"], answer: 3,
    ask: "f is balanced. After the circuit, what is the chance of reading 00?",
    revealProps: { play: true },
    reveal: "0. H on both adds the four signs into the amplitude of 00; two are + and two are −, so they cancel and the 00 bar empties." },
  nameIt: {
    say: [
      "The oracle flips the sign of each input where f is 1, a sign flip made with one extra qubit (phase kickback). H on both qubits then adds all four signs into the amplitude of 00.",
      "Constant f: the signs all agree, 00 for sure. Balanced f: they cancel, 00 never.",
    ],
    formula: ["start (1, 1, 1, 1)/2", "after the oracle ((−1)^f(00), …, (−1)^f(11))/2", "amplitude of 00 after H⊗H = ¼ Σ (−1)^f(x)"],
  },
  workIt: {
    reference: { f: [0, 1, 1, 0] },
    generate(rng, i) {
      if (i < 3) return { f: rng.pick([[0, 0], [1, 1], [0, 1], [1, 0]]) };
      return { f: rng.next() < 0.25 ? rng.pick(CONSTANT) : rng.pick(BALANCED) };
    },
    show: p => p.f.length === 2
      ? `Deutsch's one-bit version: f(0) = **${p.f[0]}**, f(1) = **${p.f[1]}**. The qubit starts as (1, 1)/√2; amplitudes in units of 1/√2.`
      : `f(00), f(01), f(10), f(11) = **${p.f.join(", ")}**. The state starts as (1, 1, 1, 1)/2; amplitudes in units of 1/2.`,
    steps(p) {
      const one = p.f.length === 2, labels = one ? LABELS1 : LABELS2;
      const s = p.f.map(x => (x ? -1 : 1)), sum = s.reduce((a, b) => a + b, 0), amp0 = sum / p.f.length;
      const out = one ? [(s[0]! + s[1]!) / 2, (s[0]! - s[1]!) / 2] : hh(s);
      const right = out.findIndex(x => Math.abs(x) > 1e-12), constant = p.f.every(x => x === p.f[0]);
      const unit = one ? "1/√2" : "1/2";
      return [
        multiStep("oracle", "After the oracle", s, "whole", { boxes: labels, ask: `In units of ${unit}.`, hint: "The oracle flips the sign where f(x) = 1.",
          slips: [slip("flipped where f is 0", s.map(x => -x), "The oracle flips the sign where f(x) = 1."), slip("no flip", s.map(() => 1), "The oracle flips the sign of each input where f(x) = 1.")],
          done: `After the oracle: ${tuple(s)}/${one ? "√2" : "2"}` }),
        wholeStep("amp", one ? "Amplitude of 0 after H" : "Amplitude of 00 after H⊗H", amp0, { hint: one ? "Half the sum of the two signs." : "A quarter of the sum of the four signs.",
          slips: [
            slip("no ¼", sum, one ? "H divides by √2 again, so the amplitude of 0 is half the sum of the signs." : "H on both divides by 2 again: the amplitude of 00 is ¼ of the sum of the signs."),
            constant && p.f[0] === 1 && slip("dropped the sign", 1, `Keep the sign: every sign is −1, so the sum is ${sn(sum)} and the amplitude is −1.`),
          ] }),
        tapStep("out", "Which outcome comes up?", labels, right, { hint: one ? "The outcome whose amplitude isn't 0." : "The outcome whose signs don't cancel.",
          slips: labels.map((_, j) => j).filter(j => j !== right).map(j => slip(`outcome ${labels[j]}`, j,
            constant && p.f[0] === 1 ? "A minus sign doesn't change the chance: (−1)² = 1, so constant f still gives " + labels[0] + " for sure."
              : `The amplitude of ${labels[j]} is 0: its signs cancel. Only ${labels[right]} is left.`)) }),
        tapStep("kind", "Constant or balanced?", ["constant", "balanced"], constant ? 0 : 1, { hint: `Constant f always lands on ${labels[0]}.`,
          slips: [slip("kind", constant ? 1 : 0, constant ? (p.f[0] === 1 ? `A minus sign doesn't change the chance: (−1)² = 1, so constant f still gives ${labels[0]} for sure.` : `All the signs agree, so everything lands on ${labels[0]}: constant.`)
            : `The signs cancel, so ${labels[0]} never comes up: balanced.`)] }),
      ];
    },
    scene: p => ({ scene: "dj", props: { f: p.f.join(""), quiet: true } }),
  },
  oracle: p => {
    const s = p.f.map(x => (x ? -1 : 1)), n = p.f.length, k = n === 2 ? Math.SQRT1_2 : 0.5;
    const w = walsh(s.map(x => x * k));
    const right = w.findIndex(x => Math.abs(x) > 1e-9);
    return [...s, w[0]!, right, new Set(p.f).size === 1 ? 0 : 1];
  },
  useIt: {
    say: ["Classically, telling constant from balanced on n-bit inputs can need one look more than half the inputs, 2ⁿ⁻¹ + 1 in all: 3 for n = 2, 513 for n = 10. The circuit always takes one.",
      "A classical guesser who accepts a small chance of being wrong needs only a few looks, while the quantum circuit is never wrong. This oracle and the H⊗H sandwich are the build's first half."],
    scene: { scene: "dj", props: { f: "1111" } },
  },
  deeper: [
    "Every balanced f on 2 bits is a·x or its opposite, for a two-bit a, so the outcome reads off a directly: that's Bernstein–Vazirani, which finds a hidden n-bit string with one question instead of n.",
    "Simon's problem gives an exponential gap even against a classical algorithm allowed to guess: f(x) = f(y) exactly when y = x or x ⊕ s, and the quantum circuit finds s in about n runs.",
    "Query complexity and the class BQP: problems a quantum computer solves with bounded error in polynomial time. BQP contains P, and factoring is in it, but nobody knows whether it contains NP-complete problems (b2-cs-12).",
  ],
};

interface P11 { N: number; k: number }
const unitN = (N: number) => (Number.isInteger(Math.sqrt(N)) ? `1/${Math.sqrt(N)}` : `1/√${N}`);

export const qu11: B2Lesson<P11> = {
  id: "b2-qu-11", track: "qu", unit: 4, title: "Grover's search: flip and reflect",
  youCan: "run rounds of Grover's search by hand and find the chance of the marked item.",
  needs: ["b2-qu-10"],
  tools: ["mean"],
  play: { scene: "mean", props: { N: 16, k: 1 },
    say: "N amplitudes as equal bars. The oracle flips the marked one below zero; diffusion flips every bar to the other side of the mean. Drag N from 4 to 64 and drag the round counter: the marked bar grows, overshoots and shrinks." },
  guess: { scene: "mean", props: { N: 16, k: 0, quiet: true }, kind: "slider", min: 0, max: 6, step: 1, start: 1, answer: 3, near: 0.5,
    format: x => (x === 1 ? "1 round" : `${x} rounds`),
    ask: "With N = 16, how many rounds give the best chance of finding the marked item?",
    revealProps: { play: true },
    reveal: "Rounds 1 to 3 climb to 0.473, 0.908 and 0.961; round 4 overshoots and falls back to 0.581. The peak is at 3." },
  nameIt: {
    say: [
      "Start with every amplitude equal. Each round, flip the sign of the marked item, then reflect every amplitude about the mean: a → 2·mean − a.",
      "The marked amplitude grows by about 2/√N each round, so about (π/4)√N rounds find it, against about N/2 looks classically.",
    ],
    formula: ["oracle: a_marked → −a_marked", "diffusion: a → 2·mean − a", "best rounds ≈ (π/4)√N"],
  },
  workIt: {
    reference: { N: 8, k: 1 },
    generate(rng, i) {
      if (i < 3) return { N: 4, k: 1 };
      return { N: rng.pick([4, 8, 16]), k: rng.int(1, 3) };
    },
    show: p => `**N = ${p.N}** items, one marked. Run **${p.k === 1 ? "one round" : `${p.k} rounds`}** of Grover's search. Amplitudes in units of ${unitN(p.N)}: they all start at 1.`,
    steps(p) {
      const N = p.N, mean = (N - 2) / N, m1 = 2 * mean + 1, o1 = 2 * mean - 1;
      const steps: B2Step[] = [
        multiStep("oracle", "After the oracle: marked, others", [-1, 1], "whole", { boxes: ["marked", "others"], hint: "The oracle flips the marked sign only.",
          slips: [slip("flipped the others", [1, -1], "The oracle flips the marked one only: marked −1, the rest stay 1.")] }),
        fracStep("mean", "Mean", mean, { hint: `${N - 1} amplitudes of 1 and one of −1, over ${N}.`,
          slips: [slip("marked still positive", 1, `Take the mean after the oracle, with the marked one negative: (${N - 1} − 1)/${N} = ${fr(mean)}.`), slip("didn't divide", N - 2, `That's the sum. Divide by N = ${N} for the mean.`)] }),
        fracStep("m", "New marked amplitude", m1, { hint: "2 × mean − (−1).",
          slips: [slip("about zero", 1, "Diffusion reflects about the mean, not about zero: a → 2·mean − a."), slip("mean minus a", mean + 1, "Reflect all the way across: a → 2 × mean − a.")] }),
        fracStep("o", "New other amplitude", o1, { hint: "2 × mean − 1.",
          slips: [slip("about zero", -1, "Diffusion reflects about the mean, not about zero: a → 2·mean − a.")] }),
      ];
      let m = m1, o = o1;
      for (let r = 2; r <= p.k; r++) {
        const mo = (-m + (N - 1) * o) / N, nm = 2 * mo + m, no = 2 * mo - o;
        const plain = (m + (N - 1) * o) / N;
        steps.push(multiStep(`r${r}`, `Round ${r}: marked, others`, [nm, no], "fraction", { boxes: ["marked", "others"], hint: `Flip the marked sign to ${sn(-m)}, take the mean, then reflect each about it.`,
          slips: [slip("skipped the oracle", [2 * plain - m, 2 * plain - o], "Each round starts with the oracle: flip the marked sign first.")] }));
        m = nm; o = no;
      }
      const P = (m * m) / N;
      steps.push(fracOr3("P", "P(marked)", P, { hint: `Square the marked amplitude and divide by N: (${sn(m)})² / ${N}.`,
        slips: [slip("amplitude", m, `Square and divide by N: (${sn(m)})²/${N}. Check that all ${N} chances add to 1.`), m * m <= 1e6 && slip("didn't divide", m * m, `That's the squared amplitude in units of ${unitN(N)}. Divide by ${N}.`)] }));
      return steps;
    },
    scene: p => ({ scene: "mean", props: { N: p.N, k: 0, quiet: true } }),
  },
  oracle: p => {
    let a = new Array<number>(p.N).fill(1);
    const f = a.map((x, i) => (i === 0 ? -x : x)), mean = f.reduce((s, x) => s + x, 0) / p.N;
    a = groverRound(a, 0);
    const out = [-1, 1, mean, a[0]!, a[1]!];
    for (let r = 2; r <= p.k; r++) { a = groverRound(a, 0); out.push(a[0]!, a[1]!); }
    out.push(groverP(p.N, p.k));
    return out;
  },
  useIt: {
    say: ["A list of a million unsorted names: about 785 rounds instead of about 500,000 looks on average (b2-cs-06).",
      "Grover would turn 2¹²⁸ guesses into about 2⁶⁴ rounds, one after another. That is one reason some guidance, such as the NSA's, asks for 256-bit keys."],
    scene: { scene: "mean", props: { N: 64, k: 6 } },
  },
  deeper: [
    "Grover as a rotation: in the plane of \"marked\" and \"the rest\", the state starts at angle θ from the rest, with sin θ = 1/√N, and each round turns it by 2θ. So the chance after k rounds is sin²((2k + 1)θ), and the best k is about π/(4θ) − ½.",
    "The BBBV theorem: no quantum algorithm can search N items with fewer than about √N looks at the oracle, so Grover is optimal. Quantum computers don't make every search exponentially faster.",
  ],
};

interface P12 { m: number; gates: boolean }
const ORACLE_GATES = ["CZ", "X on the top qubit, CZ, X on the top qubit", "X on the bottom qubit, CZ, X on the bottom qubit", "X on both, CZ, X on both"];
const GATE_FOR: Record<number, number> = { 3: 0, 1: 1, 2: 2, 0: 3 };

export const qu12: B2Lesson<P12> = {
  id: "b2-qu-12", track: "qu", unit: 4, title: "The build: a two-qubit search, by hand",
  youCan: "run Grover's search on two qubits gate by gate and find the marked item with certainty.",
  needs: ["b2-qu-08", "b2-qu-11"],
  tools: ["search", "sphere"],
  play: { scene: "search", props: { m: 2 },
    say: "The full circuit on two qubits: H on both, the oracle, H on both, flip the sign of everything except 00, H on both, measure. Tap a cell to hide the marker there, then step through and watch the state after each gate." },
  guess: { scene: "search", props: { m: 2, quiet: true }, kind: "choice", options: ["1/4", "1/2", "3/4", "1"], answer: 3,
    ask: "After this one round, what is the chance of reading the marked item?",
    revealProps: { run: true },
    reveal: "1. The three unmarked amplitudes cancel to 0 and the marked one becomes 1: all 1,000 shots land on it." },
  nameIt: {
    say: [
      "\"Reflect about the mean\" is built from gates: H on both qubits, flip the sign of every state except 00, H on both again.",
      "For four items, one round is exactly enough: the three unmarked amplitudes cancel to 0 and the marked one becomes 1.",
    ],
    formula: ["diffusion = (H⊗H)(2|00⟩⟨00| − I)(H⊗H)", "H⊗H: out(y) = ½ Σ_x (−1)^(x·y) a(x)"],
  },
  workIt: {
    reference: { m: 2, gates: false },
    generate(rng, i) {
      if (i < 3) return { m: 3, gates: false };
      return { m: rng.int(0, 3), gates: i >= 4 };
    },
    show: p => `The marked item is **${LABELS2[p.m]}**. Start at 00 and run one round. Every state in units of 1/2.`,
    steps(p) {
      const s1 = [1, 1, 1, 1], s2 = s1.map((x, i) => (i === p.m ? -x : x)), s3 = hh(s2), s4 = s3.map((x, i) => (i === 0 ? x : -x)), s5 = clean(hh(s4));
      const boxes = LABELS2;
      const signSlip = (from: number[]) => slip("H⊗H sign pattern", hhCrossed(from), `The sign for x and y is (−1) to the number of places where both have a 1, top digit with top digit: for y = 11 the signs are +, −, −, +.`);
      const done = (l: string, v: number[]) => `${l}: ${tuple(clean(v))}/2`;
      const steps: B2Step[] = [];
      if (p.gates) steps.push(tapStep("gates", `Oracle for ${LABELS2[p.m]}, from gates`, ORACLE_GATES, GATE_FOR[p.m]!, { hint: "CZ flips the sign of 11 only. X gates turn the marked item into 11 first, then back.",
        slips: [
          p.m === 1 && slip("top and bottom", 2, "The left digit is the top qubit. For 01 the top one is 0, so the X gates go on the top qubit."),
          p.m === 2 && slip("top and bottom", 1, "The left digit is the top qubit. For 10 the bottom one is 0, so the X gates go on the bottom qubit."),
        ] }));
      steps.push(
        multiStep("s1", "After H on both", s1, "whole", { boxes, hint: "H on each qubit spreads 00 evenly: every amplitude 1/2.",
          slips: [slip("units", [0.5, 0.5, 0.5, 0.5], "Boxes are in units of 1/2: an amplitude of 1/2 is typed as 1.")], done: done("After H on both", s1) }),
        multiStep("s2", "After the oracle", s2, "whole", { boxes, hint: `The oracle flips the sign of ${LABELS2[p.m]}.`,
          slips: [slip("no flip", s1, `The oracle flips the sign of the marked item, ${LABELS2[p.m]}.`)], done: done("After the oracle", s2) }),
        multiStep("s3", "After H on both", clean(s3), "whole", { boxes, hint: "out(y) = ½ Σ (−1)^(x·y) a(x).",
          slips: [signSlip(s2), slip("didn't halve", s3.map(x => 2 * x), "H on both divides by 2: out(y) is half the signed sum.")], done: done("After H on both", s3) }),
        multiStep("s4", "After flipping all but 00", clean(s4), "whole", { boxes, hint: "Keep 00 and flip the sign of the other three.",
          slips: [slip("flipped 00 too", clean(s3.map(x => -x)), "Flip every amplitude except 00: (2|00⟩⟨00| − I) keeps 00 and negates the rest."), slip("flipped only 00", clean(s3.map((x, i) => (i === 0 ? -x : x))), "That's the same state turned by an overall sign, which changes no chance, but the circuit keeps 00 and flips the other three.")],
          done: done("After flipping all but 00", s4) }),
        multiStep("s5", "After H on both", s5, "whole", { boxes, hint: "Same H pattern as before.",
          slips: [slip("typed 1", s5.map(x => x / 2), "Boxes are in units of 1/2: an amplitude of 1 is typed as 2."), signSlip(s4)], done: done("After H on both", s5) }),
        fracStep("P", `Chance of reading ${LABELS2[p.m]}`, 1, { hint: "The marked amplitude is 2 in units of 1/2: square the real amplitude.",
          slips: [slip("squared the units", 4, "The box said 2 because it's in units of 1/2: the amplitude is 1, so the chance is 1² = 1."), slip("in units", 2, "The box said 2 because it's in units of 1/2: the amplitude is 1, so the chance is 1² = 1."), slip("before the search", 1 / 4, "That was the chance before the search. After one round the marked amplitude is 1, so the chance is 1.")] }),
      );
      return steps;
    },
    scene: p => ({ scene: "search", props: { m: p.m, quiet: true } }),
  },
  oracle: p => {
    // H⊗H as a Kronecker product of the 2×2 H, applied as a matrix; the chance from the rotation picture
    const H = [[1, 1], [1, -1]], HH = [0, 1, 2, 3].map(y => [0, 1, 2, 3].map(x => (H[y >> 1]![x >> 1]! * H[y & 1]![x & 1]!) / 2));
    const ap = (v: number[]) => HH.map(row => row.reduce((s, h, x) => s + h * v[x]!, 0));
    const s1 = ap([2, 0, 0, 0]), s2 = s1.map((x, i) => (i === p.m ? -x : x)), s3 = ap(s2), s4 = s3.map((x, i) => (i ? -x : x)), s5 = ap(s4);
    return [...(p.gates ? [{ 3: 0, 1: 1, 2: 2, 0: 3 }[p.m]!] : []), ...s1, ...s2, ...s3, ...s4, ...s5, Math.sin(3 * Math.asin(1 / 2)) ** 2];
  },
  useIt: {
    say: ["The build: two-qubit search. Hide an item, run the circuit by hand, typing each state before the board shows it, then run 1,000 shots: all on the marked item.",
      "A classical search of four can need three looks (b2-cs-06); this needs one. Save it to keep `grover` and the circuit in your Notebook: the track's build."],
    project: "qu-search",
  },
  deeper: [
    "Shor's idea: factoring N reduces to finding the period r of aˣ mod N, and the quantum Fourier transform finds periods the way H⊗H found the hidden pattern in b2-qu-10: amplitudes that repeat every r steps turn into peaks spaced 2ⁿ/r apart.",
    "For N = 15 and a = 7 the powers run 7, 4, 13, 1, so the period is 4. With gcd as the greatest common divisor, the largest whole number dividing both, gcd(7² − 1, 15) = 3 and gcd(7² + 1, 15) = 5.",
    "Quantum error correction: the 3-qubit bit-flip code stores 0 as 000 and 1 as 111 and fixes any one flip by majority, the cousin of the Hamming code (b2-in-11). Real machines need many physical qubits for each reliable one.",
  ],
};

export const QUANTUM_LESSONS = [qu01, qu02, qu03, qu04, qu05, qu06, qu07, qu08, qu09, qu10, qu11, qu12];
