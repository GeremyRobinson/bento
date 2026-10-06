// Unit 3 · Oscillators: b2-de-09 to b2-de-11 (curriculum/specs/bento2/diffeq.md).
import type { B2Lesson } from "../../model";
import { fracStep, numStep, slip, tapStep, wholeStep } from "../../make";
import { terms } from "./text";
import { G, steadyAmp } from "./maths";

/* ------------------------------------------------------------------ de-09 ------------------------------------------------------------------ */

export interface P09 { m: number; w: number; j: number }
const DAMP = ["No friction", "Bounces", "Critical", "Creeps"];
/** c as a multiple of c_crit: 0, 1/2, 1, 3/2, 2 */
const cOf = (p: P09) => (p.j * 2 * p.m * p.w) / 2;

export const de09: B2Lesson<P09> = {
  id: "b2-de-09", track: "de", unit: 3, title: "Springs and damping",
  youCan: "find a spring's natural frequency, its critical damping, and whether it bounces, settles fast or creeps.",
  needs: ["b2-de-08"],
  tools: ["spring", "plane"],
  play: { scene: "spring", props: { m: 1, k: 4, c: 1 },
    say: "A mass on a spring with a friction dial. Drag the friction up and watch the motion go from bouncy to just right to slow and sticky, with the time graph and the phase-plane path changing together." },
  guess: { scene: "spring", props: { m: 1, k: 4, c: 0.5, quiet: true }, kind: "slider", min: 0, max: 10, step: 0.1, start: 1, answer: 4, near: 0.5, unit: "N·s/m",
    format: x => x.toFixed(1),
    ask: "A 1 kg mass on a spring with k = 4 N/m. Drag the friction to the setting where the mass gets home fastest without overshooting.",
    revealProps: { c: 4, crit: true },
    reveal: "Critical damping is 2√(mk) = 2√4 = 4 N·s/m. Less and it overshoots; more and it creeps." },
  nameIt: {
    say: [
      "A spring with mass m, stiffness k and friction c obeys mx″ + cx′ + kx = 0. With no friction it swings at ω = √(k/m).",
      "The critical amount of friction, 2√(mk), separates bouncing from creeping, and the damping ratio ζ compares c with it.",
    ],
    formula: ["ω = √(k/m), period 2π/ω", "c_crit = 2√(mk) = 2mω, ζ = c/c_crit", "ζ < 1 bounces, ζ = 1 critical, ζ > 1 creeps"],
  },
  workIt: {
    reference: { m: 2, w: 3, j: 1 },
    generate(rng, i) { return { m: i < 3 ? 1 : rng.pick([1, 2, 4]), w: rng.int(1, 5), j: rng.int(0, 4) }; },
    show: p => `A mass **m = ${p.m} kg** on a spring with **k = ${p.m * p.w * p.w} N/m** and friction **c = ${cOf(p)} N·s/m**.`,
    steps(p) {
      const k = p.m * p.w * p.w, c = cOf(p), cc = 2 * p.m * p.w, z = c / cc, type = z === 0 ? 0 : z < 1 ? 1 : z === 1 ? 2 : 3;
      return [
        wholeStep("w", "ω", p.w, { unit: "per second", hint: `ω = √(k/m) = √(${k}/${p.m}).`,
          slips: [slip("k/m", k / p.m, `ω is the square root: √(${k}/${p.m}) = ${p.w}.`)] }),
        numStep("T", "Period", (2 * Math.PI) / p.w, 2, { unit: "s", hint: `2π/ω = 2π/${p.w}.`,
          slips: [slip("1/ω", 1 / p.w, "One full swing is 2π radians at ω radians per second: 2π/ω."), slip("2πω", 2 * Math.PI * p.w, "The period is 2π divided by ω: faster springs have shorter periods.")] }),
        wholeStep("cc", "c_crit", cc, { unit: "N·s/m", hint: `2√(mk) = 2√(${p.m} × ${k}).`,
          slips: [slip("2√(k/m)", 2 * p.w, "Critical damping is 2√(mk). It has units of friction, not frequency.")] }),
        fracStep("z", "ζ", z, { ask: "As a fraction.", hint: `ζ = c/c_crit = ${c}/${cc}.`,
          slips: [c > 0 && slip("flipped", cc / c, "ζ compares the friction with critical: c over c_crit.")] }),
        tapStep("type", "Type", DAMP, type, { hint: "ζ = 0 no friction, below 1 bounces, 1 critical, above 1 creeps.",
          slips: [
            type === 3 && slip("ζ > 1 bouncy", 1, "More friction than critical means no bounce at all. It creeps home."),
            type === 1 && slip("ζ < 1 creeps", 3, "Less friction than critical can't stop the overshoot. It bounces, smaller each time."),
          ] }),
      ];
    },
    scene: p => ({ scene: "spring", props: { m: p.m, k: p.m * p.w * p.w, c: cOf(p), quiet: true } }),
  },
  oracle: p => {
    const k = p.m * p.w * p.w, c = (p.j / 2) * 2 * Math.sqrt(p.m * k), w = Math.sqrt(k / p.m), z = c / (2 * p.m * w);
    return [w, (2 * Math.PI) / w, 2 * p.m * w, z, z === 0 ? 0 : z < 1 ? 1 : z === 1 ? 2 : 3];
  },
  useIt: {
    say: [
      "Car suspension: a 400 kg corner on a k = 40,000 N/m spring. c_crit = 2√(400 × 40,000) = 8000 N·s/m, and a typical comfort setting is ζ = 0.3, so c = 2400 N·s/m.",
      "Drag c and feel the bump: lower and the car wallows, higher and every pothole kicks straight through.",
    ],
    saves: { name: "zeta", value: () => 0.3, note: "the suspension's damping ratio, a comfort setting" },
    scene: { scene: "spring", props: { m: 400, k: 40000, c: 2400 } },
  },
  deeper: [
    "The characteristic equation mr² + cr + k = 0 is the trace–determinant map again, with T = −c/m and D = k/m. ζ = 1 is exactly the parabola T² = 4D.",
    "Below critical, the mass rings at the damped frequency ω√(1 − ζ²), a little slower than ω, inside an envelope e^(−ζωt).",
    "The Laplace transform turns the spring into a transfer function 1/(ms² + cs + k), whose poles are the eigenvalues. Control engineers place those poles with feedback, which is how they tune a car, a drone or a thermostat.",
  ],
};

/* ------------------------------------------------------------------ de-10 ------------------------------------------------------------------ */

export interface P10 { L: number }
const LENGTH = ["Shorter", "The same", "Longer"];
const L2 = (G * 4) / (4 * Math.PI * Math.PI);

export const de10: B2Lesson<P10> = {
  id: "b2-de-10", track: "de", unit: 3, title: "The pendulum",
  youCan: "find a pendulum's period, see why big swings are slower, and find the speed that sends it over the top.",
  needs: ["b2-de-09", "c-linapprox"],
  tools: ["pendulum", "plane", "units"],
  play: { scene: "pendulum", props: { L: 1, th0: 40 },
    say: "A bob on a rigid rod. Drag the length and the release angle, from 5° to 179°. The phase plane draws (θ, θ′): small swings are ellipses, big ones are lemon-shaped, and a push from the bottom past the top goes over as a wavy line." },
  guess: { scene: "pendulum", props: { L: 1, th0: 10, quiet: true }, kind: "choice", options: LENGTH, answer: 2,
    ask: "Release at 60° instead of 10°. Is the period shorter, the same, or longer?",
    revealProps: { twin: 60 },
    reveal: "Longer: the 60° swing takes about 1.07 times as long. The real pull is g·sin θ, weaker than g·θ, so big swings dawdle at the ends." },
  nameIt: {
    say: [
      "Gravity pulls the bob back with g·sin θ, so θ″ = −(g/L)sin θ. For small angles sin θ ≈ θ and the pendulum is a spring with ω = √(g/L).",
      "Big swings take longer, and on a rigid rod, with enough speed at the bottom, it loops over the top.",
    ],
    formula: ["T ≈ 2π√(L/g) for small swings", "½L²θ′² + gL(1 − cos θ) stays constant", "over the top if the bottom speed is above 2√(gL)"],
  },
  workIt: {
    reference: { L: 1 },
    generate(rng, i) { return { L: i < 3 ? rng.pick([1, 0.25]) : rng.pick([0.25, 0.5, 1, 2]) }; },
    show: p => `A pendulum on a rigid rod, **L = ${p.L} m**, with **g = 9.81 m/s²** (Units and constants).`,
    steps(p) {
      return [
        numStep("T", "Small-swing period", 2 * Math.PI * Math.sqrt(p.L / G), 2, { unit: "s", hint: `2π√(L/g) = 2π√(${p.L}/9.81).`,
          slips: [slip("√(g/L)", 2 * Math.PI * Math.sqrt(G / p.L), "√(g/L) is ω. The period is 2π/ω = 2π√(L/g)."), slip("√(g/L)", Math.sqrt(G / p.L), "√(g/L) is ω. The period is 2π/ω = 2π√(L/g).")] }),
        tapStep("big", "Release at 60°", LENGTH, 2, { hint: "Compare sin θ with θ at 60°.",
          slips: [slip("ignores amplitude", 1, "That's only true for small swings. The real restoring pull is sin θ, which is weaker than θ, so big swings are slower.")] }),
        numStep("v", "Speed at the bottom to go over the top", 2 * Math.sqrt(G * p.L), 2, { unit: "m/s", hint: `The top is 2L above the bottom: ½v² = g·2L, so v = 2√(gL) = 2√(9.81 × ${p.L}).`,
          slips: [
            slip("√(2gL)", Math.sqrt(2 * G * p.L), "√(2gL) just reaches the side. The top is 2L above the bottom, so you need √(4gL) = 2√(gL)."),
            slip("√(5gL)", Math.sqrt(5 * G * p.L), "√(5gL) is for a bob on a string, which goes slack near the top. A rigid rod just has to reach it: 2√(gL)."),
          ] }),
        numStep("L2", "Length for a 2 s period", L2, 2, { unit: "m", hint: "Square both sides of T = 2π√(L/g): L = gT²/(4π²) = 9.81 × 4/(4π²).",
          slips: [slip("forgot to square", (G * 2) / (2 * Math.PI), "Square both sides: T² = 4π²L/g, so L = gT²/(4π²).")] }),
      ];
    },
    scene: p => ({ scene: "pendulum", props: { L: p.L, th0: 10, quiet: true } }),
  },
  oracle: p => [2 * Math.PI * Math.sqrt(p.L / 9.81), 2, 2 * Math.sqrt(9.81 * p.L), (9.81 * 4) / (4 * Math.PI ** 2)],
  useIt: {
    say: [
      "A seconds pendulum ticks once per swing, so its full period is 2 s. Set the length that gives it (0.99 m), and save `L_pend` and `T_pend` for the Pendulum clock.",
    ],
    scene: { scene: "pendulum", props: { L: 0.9, th0: 6, seconds: true, saveable: true } },
  },
  deeper: [
    "The exact period is T = 4√(L/g)·K(sin(θ₀/2)), with K the complete elliptic integral. It's fast to compute with the arithmetic-geometric mean: T = 2π√(L/g) / AGM(1, cos(θ₀/2)). At 60° that's a factor of 1.073.",
    "A bob on a string instead of a rod goes slack near the top unless gravity alone can supply the turning, so it needs √(5gL) at the bottom (7.00 m/s for L = 1 m).",
    "The separatrix θ′ = 2√(g/L)cos(θ/2) is a homoclinic orbit that takes forever to reach the top. The pendulum is a Hamiltonian system, and phase-space area is conserved (Liouville).",
  ],
};

/* ------------------------------------------------------------------ de-11 ------------------------------------------------------------------ */

export interface P11 { w0: number; w: number; c: number; F: number }
/** (ω₀, ω, c) with (ω₀² − ω², cω) a Pythagorean pair and light friction, and the denominator */
const RES: [number, number, number, number][] = [[5, 4, 3, 15], [5, 3, 4, 20], [7, 5, 2, 26], [7, 3, 3, 41], [9, 6, 4, 51], [8, 4, 5, 52], [10, 8, 6, 60]];

export const de11: B2Lesson<P11> = {
  id: "b2-de-11", track: "de", unit: 3, title: "Forcing and resonance",
  youCan: "find the steady swing of a pushed, damped oscillator and see why pushing at the natural frequency is dangerous.",
  needs: ["b2-de-09", "b2-de-02"],
  tools: ["resonance", "graph2d"],
  play: { scene: "resonance", props: { w0: 5, c: 1, F: 10, w: 3 },
    say: "Push the spring with F·cos(ωt). Drag the drive frequency ω and watch the swing settle to a steady size, while the resonance curve draws amplitude against ω. Turn the friction down and the peak shoots up." },
  guess: { scene: "resonance", props: { w0: 5, c: 1, F: 10, w: 2, quiet: true }, kind: "slider", min: 1, max: 9, step: 0.05, start: 3, answer: Math.sqrt(25 - 0.5), near: 0.3, unit: "per second",
    format: x => x.toFixed(2),
    ask: "A spring with ω₀ = 5 and light friction, c = 1. Drag a marker to the drive frequency that gives the biggest swing.",
    revealProps: { sweep: true },
    reveal: "The peak is at ω = √(ω₀² − c²/2) = 4.95, just under the natural frequency. With less friction it sits closer to 5 and rises higher." },
  nameIt: {
    say: [
      "After the start-up fades, a pushed oscillator swings at the drive frequency, not its own.",
      "The size depends on how close the drive is to the natural frequency and how much friction there is.",
    ],
    formula: ["x″ + cx′ + ω₀²x = F cos(ωt)", "amplitude = F / √((ω₀² − ω²)² + (cω)²)"],
  },
  workIt: {
    reference: { w0: 5, w: 4, c: 3, F: 30 },
    generate(rng, i) {
      const [w0, w, c, den] = rng.pick(i < 3 ? RES.slice(0, 3) : RES);
      return { w0, w, c, F: den * rng.int(1, 3) };
    },
    show: p => `**${terms([[1, "x″"], [p.c, "x′"], [p.w0 * p.w0, "x"]])} = ${p.F} cos(${p.w}t)**, mass 1.`,
    steps(p) {
      const a = p.w0 * p.w0 - p.w * p.w, b = p.c * p.w, den = Math.hypot(a, b);
      return [
        wholeStep("a", "ω₀² − ω²", a, { hint: `${p.w0 * p.w0} − ${p.w}².`,
          slips: [slip("ω₀ − ω", p.w0 - p.w, "The mismatch is ω₀² − ω², squares of the frequencies.")] }),
        wholeStep("b", "cω", b, { hint: `${p.c} × ${p.w}.`,
          slips: [slip("c alone", p.c, "Friction scales with speed, and speed scales with ω: the friction term is cω.")] }),
        wholeStep("den", "Denominator", den, { ask: `√((ω₀² − ω²)² + (cω)²).`, hint: `√(${a}² + ${b}²).`,
          slips: [slip("added", a + b, "The spring-and-mass part (ω₀² − ω²) and the friction part (cω) act at right angles, so combine them with Pythagoras.")] }),
        wholeStep("amp", "Amplitude", p.F / den, { hint: `${p.F} / ${den}.`,
          slips: [slip("multiplied", p.F * den, "The bigger the mismatch, the smaller the swing: divide F by it."), slip("no friction", p.F / a, "Friction counts too: divide by the whole denominator.")] }),
        tapStep("lim", "With c → 0 and ω → ω₀", ["Settles", "Grows without limit"], 1, { hint: "Both parts of the denominator go to zero.",
          slips: [slip("settles", 0, "With no friction nothing takes energy out, and each push lands in step and adds more. The swing grows without limit.")] }),
      ];
    },
    scene: p => ({ scene: "resonance", props: { w0: p.w0, c: p.c, F: p.F, w: p.w, quiet: true } }),
  },
  oracle: p => [p.w0 ** 2 - p.w ** 2, p.c * p.w, Math.sqrt((p.w0 ** 2 - p.w ** 2) ** 2 + (p.c * p.w) ** 2), steadyAmp(p.F, p.w0, p.w, p.c), 1],
  useIt: {
    say: [
      "Project: the Pendulum clock. Give `L_pend` a once-per-swing push that exactly replaces the energy friction takes each cycle, so the swing holds steady. Saves `A_drive`, part of the build.",
    ],
    project: "de-clock",
  },
  deeper: [
    `The phase lag tan φ = cω/(ω₀² − ω²): slow pushes are followed in step, fast ones half a cycle late, and at ω₀ the swing lags by a quarter. The quality factor Q = ω₀/c measures how sharp the peak is, and the peak sits at ω = √(ω₀² − c²/2).`,
    "Fourier series: any periodic push is a sum of cosines, so the response is a sum of responses. The same idea with a single kick gives the Green's function, and the response to any push is a convolution with it.",
    `Parametric resonance pumps a swing by moving your weight twice a cycle (the Mathieu equation). The Tacoma Narrows collapse was aeroelastic flutter, not simple resonance: the wind fed the twisting motion itself.`,
  ],
};
