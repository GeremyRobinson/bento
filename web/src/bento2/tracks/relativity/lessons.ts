// Relativity's 12 lessons, b2-re-01 to b2-re-12, built from curriculum/specs/bento2/relativity.md block by block.
import type { B2Lesson, B2Step, SceneRef } from "../../model";
import { fracStep, multiStep, numStep, slip, tapStep, wholeStep } from "../../make";
import { formatAnswer, group } from "../../steps";
import { C, DAY } from "../../constants";
import { count } from "../../../curriculum/text";
import {
  C_KMS, C_KM_US, C_M_NS, CANCEL_KM, boost, gammaOf, gravityGainUs, heightGainNs, lossPerDayUs, netDriftUs, slowFraction, speedLossUs,
} from "./physics";

const fr = (x: number) => formatAnswer(x, "fraction");
const n1 = (x: number) => group(x, 1);
const n2 = (x: number) => group(x, 2);
const SUP: Record<string, string> = { "-": "⁻", "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹" };
/** "× 10⁻¹⁰" */
const tenTo = (e: number) => `× 10${String(e).replace(/./g, d => SUP[d] ?? d)}`;
/** the power of ten that puts x between 1 and 10 (as a negative exponent for small x) */
const expOf = (x: number) => Math.floor(Math.log10(Math.abs(x)));
/** "−3" with a real minus sign */
const sn = (x: number) => (x < 0 ? `−${Math.abs(x)}` : String(x));
const R_KM = 6371;

/* ------------------------------------------------------------------ unit 1 ------------------------------------------------------------------ */

const DISTS = [
  { d: 384400, name: "the Moon" },
  { d: 20200, name: "a GPS satellite straight overhead" },
  { d: 35786, name: "a geostationary satellite overhead" },
  { d: 149600000, name: "the Sun" },
];
interface P01 { d: number; name: string | null; eNs: number; eUs: number }
const inMs = (p: P01) => p.d <= 50000;

export const re01: B2Lesson<P01> = {
  id: "b2-re-01", track: "re", unit: 1, title: "Light is the speed everyone agrees on",
  youCan: "turn distances into light-travel times, and clock errors into map errors.",
  needs: ["g12-unit"],
  tools: ["spacetime", "units"],
  play: { scene: "spacetime", props: { mode: "light", beta: 0.3 },
    say: "A lamp flashes while you ride past. Drag your speed: the thrown balls look faster or slower, but the flash's lines stay at 45° for everyone." },
  guess: { scene: "spacetime", props: { mode: "light", beta: 0.5 }, kind: "choice", options: ["0.5c", "c", "1.5c"], answer: 1,
    ask: "You fly toward the lamp at half light speed. What speed do you measure for its light?",
    revealProps: { mode: "light", beta: 0.5, measure: true },
    reveal: "Both frames read c. In yours and in the lamp's, the flash runs along the same 45° lines." },
  nameIt: {
    say: [
      "Light in empty space moves at the same speed c for everyone moving steadily, however fast they go, and the laws of physics are the same for all of them.",
      "Everything else in this track follows from those two rules.",
      "Since c is fixed, a time is a distance: GPS measures how far away each satellite is by timing its signal.",
    ],
    formula: ["t = d / c", "c = 299,792 km/s ≈ 0.3 m per nanosecond"],
  },
  workIt: {
    reference: { d: 20200, name: "a GPS satellite straight overhead", eNs: 10, eUs: 1 },
    generate(rng, i) {
      if (i < 3) {
        const pick = rng.pick(DISTS.slice(0, 2));
        return { ...pick, eNs: rng.pick([10, 20, 50]), eUs: 1 };
      }
      const d = rng.next() < 0.6 ? rng.pick(DISTS) : { d: rng.int(1000, 50000), name: null };
      return { d: d.d, name: d.name, eNs: rng.int(1, 100), eUs: rng.int(1, 10) };
    },
    show: p => `Light travels **${group(p.d)} km**${p.name ? ` (${p.name})` : ""}. A clock is off by **${p.eNs} ns**, another by **${p.eUs} μs**.`,
    steps(p) {
      const sec = p.d / C_KMS, ms = inMs(p);
      const time = ms ? sec * 1000 : sec;
      return [
        numStep("t", "Light time", time, ms ? 1 : 3, {
          unit: ms ? "ms" : "s", ask: ms ? "How long does the light take, in milliseconds?" : "How long does the light take, in seconds?",
          hint: `Time is distance over speed: ${group(p.d)} / 299,792.`,
          slips: [
            slip("c over d", C_KMS / p.d, "Time is distance over speed: d / c."),
            slip("c over d", (C_KMS / p.d) * 1000, "Time is distance over speed: d / c."),
            ms && slip("seconds for ms", sec, `That's seconds. ${group(sec, 4)} s is ${n1(sec * 1000)} ms.`),
          ],
        }),
        numStep("e1", `Error from ${p.eNs} ns`, p.eNs * C_M_NS, 1, {
          unit: "m", ask: `Light goes 0.2998 m each nanosecond. How far off is the map?`,
          hint: `Multiply: ${p.eNs} × 0.2998 m.`,
          slips: [slip("divided", p.eNs / C_M_NS, `Each nanosecond is 0.2998 m of light, so multiply: ${p.eNs} × 0.2998.`)],
        }),
        numStep("e2", `Error from ${p.eUs} μs`, p.eUs * 1000 * C_M_NS, 1, {
          unit: "m", hint: `A microsecond is 1,000 nanoseconds: ${group(p.eUs * 1000)} × 0.2998 m.`,
          slips: [slip("μs as ns", p.eUs * C_M_NS, p.eUs === 1
            ? "A microsecond is 1,000 nanoseconds, so 1,000 × 0.2998 m: about 300 m."
            : `A microsecond is 1,000 nanoseconds, so ${p.eUs} μs is ${group(p.eUs * 1000)} × 0.2998 m: about ${group(p.eUs * 1000 * C_M_NS)} m.`)],
        }),
      ];
    },
    scene: () => ({ scene: "spacetime", props: { mode: "light", beta: 0 } }),
  },
  oracle: p => [inMs(p) ? (p.d / 299792.458) * 1000 : p.d / 299792.458, p.eNs * 0.299792458, p.eUs * 1000 * 0.299792458],
  useIt: {
    say: ["A GPS receiver times signals from four satellites. If one satellite's clock is 1 μs off, your position is off by about 300 m.",
      "That is the build's first piece: every microsecond of clock error is 0.3 km on the map."],
    saves: { name: "c", value: () => C, unit: "m/s", note: "the speed of light, exact" },
    scene: { scene: "spacetime", props: { mode: "light", beta: 0 } },
  },
  deeper: [
    "Maxwell's equations predict waves at c = 1/√(μ₀ε₀) without saying relative to what. The Michelson–Morley experiment looked for Earth's motion through a medium and found none.",
    "Galilean addition (u + v) fails for light: the measured speed is c whatever the source does. Since 1983 the meter has been defined from c: the distance light goes in 1/299,792,458 of a second.",
  ],
};

interface PTri { a: number; c: number; b: number }
const triple = (t: [number, number, number]): PTri => ({ a: t[0], b: t[1], c: t[2] });
interface P02 extends PTri { k: number }

export const re02: B2Lesson<P02> = {
  id: "b2-re-02", track: "re", unit: 1, title: "The light clock: moving clocks run slow",
  youCan: "find the time-stretch factor γ for a speed and use it to compare two clocks.",
  needs: ["b2-re-01", "g11-radical"],
  tools: ["lightclock", "spacetime"],
  play: { scene: "lightclock", props: { beta: 0.3 },
    say: "A light pulse bounces between two mirrors on a train. Drag the train's speed: from the ground the pulse zigzags on a longer path, so each tick takes longer, and the ground clock pulls ahead." },
  guess: { scene: "lightclock", props: { beta: 0.6 }, kind: "slider", min: 1, max: 2, step: 0.05, start: 1.5, answer: 1.25, near: 0.05, unit: "ground s",
    format: x => x.toFixed(2),
    ask: "At 3/5 of light speed, how many ground seconds pass for each train second?",
    revealProps: { beta: 0.6, triangle: true },
    reveal: "The triangle has legs 4 and 3 and a hypotenuse of 5, so each train second takes 5/4 ground seconds." },
  nameIt: {
    say: [
      "Light goes up and down in the train in time τ, but along a slanted path in ground time t.",
      "Pythagoras on that triangle gives the stretch factor γ, which is 1 at rest and grows without limit near c. A moving clock ticks slow by γ.",
    ],
    formula: ["(ct)² = (cτ)² + (vt)²", "t = γτ", "γ = 1 / √(1 − β²), β = v / c"],
  },
  workIt: {
    reference: { a: 3, b: 4, c: 5, k: 2 },
    generate(rng, i) {
      const t = triple(rng.pick(i < 3 ? TRIPLES_EASY : RE_TRIPLES));
      const most = Math.max(1, Math.floor(50 / t.b));
      return { ...t, k: rng.int(1, i < 3 ? Math.min(3, most) : most) };
    },
    show: p => `A train moves at **β = ${p.a}/${p.c}**. Its clock reads **τ = ${p.k * p.b} years**. How much time passes on the ground?`,
    steps(p) {
      const b2 = (p.a * p.a) / (p.c * p.c), root = p.b / p.c, g = p.c / p.b, tau = p.k * p.b;
      return [
        fracStep("b2", "β²", b2, { hint: `Square top and bottom: ${p.a}²/${p.c}².`,
          slips: [slip("β not β²", p.a / p.c, `Square it: (${p.a}/${p.c})² = ${p.a * p.a}/${p.c * p.c}.`)] }),
        fracStep("root", "√(1 − β²)", root, { hint: `1 − ${p.a * p.a}/${p.c * p.c} = ${p.b * p.b}/${p.c * p.c}, then take the root.`,
          slips: [
            slip("used β", (p.c - p.a) / p.c, `Speeds enter squared, from Pythagoras: 1 − ${p.a * p.a}/${p.c * p.c}.`),
            slip("no root", 1 - b2, `Now take the square root: √(${p.b * p.b}/${p.c * p.c}) = ${p.b}/${p.c}.`),
          ] }),
        fracStep("g", "γ", g, { hint: `γ is 1 over √(1 − β²): flip ${p.b}/${p.c}.`,
          slips: [
            slip("forgot root", 1 / (1 - b2), `γ is 1 over the square root of 1 − β². Here √(${p.b * p.b}/${p.c * p.c}) = ${p.b}/${p.c}.`),
            slip("didn't flip", root, `γ is 1 over that: flip ${p.b}/${p.c} to ${p.c}/${p.b}.`),
          ] }),
        wholeStep("t", "Ground time t", g * tau, { unit: "years", hint: `t = γτ = ${p.c}/${p.b} × ${tau}.`,
          slips: [slip("divided", tau / g, "The moving clock reads less, so the ground's number is the bigger one: t = γτ.")] }),
      ];
    },
    scene: p => ({ scene: "lightclock", props: { beta: p.a / p.c } }),
  },
  oracle: p => { const b = p.a / p.c, g = 1 / Math.sqrt(1 - b * b); return [b * b, Math.sqrt(1 - b * b), g, g * p.k * p.b]; },
  useIt: {
    say: ["A probe flies to a star 12 light-years away at 12/13 of light speed. On the ground the trip takes 13 years.",
      "On the probe's clock it takes 13 / (13/5) = 5 years."],
    scene: { scene: "lightclock", props: { beta: 12 / 13 } },
  },
  deeper: [
    "The effect is symmetric: each observer sees the other's clock run slow. That is only consistent because they disagree about \"now\" (b2-re-04).",
    "Experimental checks: particles in accelerators live longer by exactly γ, and in 1971 cesium clocks flown on airliners came back off by the predicted nanoseconds (b2-re-09).",
  ],
};

/** Pythagorean speeds: β = a/c, √(1 − β²) = b/c */
const RE_TRIPLES: [number, number, number][] = [[3, 4, 5], [4, 3, 5], [5, 12, 13], [12, 5, 13], [8, 15, 17], [15, 8, 17], [7, 24, 25], [24, 7, 25], [20, 21, 29], [21, 20, 29]];
const TRIPLES_EASY: [number, number, number][] = [[3, 4, 5], [4, 3, 5]];

interface P03 extends PTri { L0: number }
const TAU = 2.2, CMU = 0.3;

export const re03: B2Lesson<P03> = {
  id: "b2-re-03", track: "re", unit: 1, title: "Moving rulers shrink: the muon's trip",
  youCan: "use γ to predict how far a fast particle gets, from both points of view.",
  needs: ["b2-re-02"],
  tools: ["lightclock", "spacetime"],
  play: { scene: "lightclock", props: { mode: "muon", beta: 0.6 },
    say: "Muons made 10 km up rain down. Drag their speed: in the lab view their clocks slow and they get further; flip to the muon's view and the atmosphere itself shrinks toward them." },
  guess: { scene: "lightclock", props: { mode: "muon", beta: 12 / 13, hide: true }, kind: "slider", min: 0, max: 10, step: 0.1, start: 5, answer: 10 - (12 / 13) * CMU * (13 / 5) * TAU, near: 0.5, unit: "km up",
    format: x => x.toFixed(1),
    ask: "A muon lives 2.2 μs on its own clock. At 12/13 of light speed, how high up does it decay, on average?",
    revealProps: { mode: "muon", beta: 12 / 13, compare: true },
    reveal: "With relativity it gets 1.58 km, down to about 8.4 km up. Without, it would stop after 0.61 km." },
  nameIt: {
    say: [
      "In the lab the muon's clock runs slow by γ, so it lives γτ and travels further.",
      "In the muon's frame its clock is normal, but distances along its motion are shorter by γ. Both views predict the same arrival.",
    ],
    formula: ["lab life = γτ", "lab distance = vγτ", "contracted length L = L₀ / γ"],
  },
  workIt: {
    reference: { a: 12, b: 5, c: 13, L0: 10 },
    generate(rng, i) {
      const t = triple(rng.pick(i < 3 ? TRIPLES_EASY : [[3, 4, 5], [4, 3, 5], [12, 5, 13], [24, 7, 25]] as [number, number, number][]));
      return { ...t, L0: i < 3 ? 10 : rng.pick([10, 15]) };
    },
    show: p => `A muon lives **τ = 2.2 μs** on its own clock and moves at **β = ${p.a}/${p.c}**. Use c = 0.3 km per μs. The atmosphere is **${p.L0} km** deep.`,
    steps(p) {
      const g = p.c / p.b, b = p.a / p.c, life = g * TAU, far = b * CMU * life, plain = b * CMU * TAU, L = p.L0 / g;
      const stretch = slip("stretched own life", TAU, "On its own clock the muon always lives 2.2 μs. The stretch is what the lab sees.");
      return [
        numStep("g", "γ", g, 2, { hint: `γ = 1/√(1 − β²) = ${p.c}/${p.b}.`, ask: "As a decimal, to 2 places.",
          slips: [slip("didn't flip", p.b / p.c, `γ is 1 over √(1 − β²): ${p.c}/${p.b}, not ${p.b}/${p.c}.`)] }),
        numStep("life", "Lab life", life, 2, { unit: "μs", hint: "The lab sees the muon's clock slow: γ × 2.2 μs.", slips: [stretch, slip("divided", TAU / g, "The lab sees the muon live longer, not shorter: γ × 2.2 μs.")] }),
        numStep("far", "Distance with relativity", far, 2, { unit: "km", hint: `Distance is speed × time: ${p.a}/${p.c} × 0.3 × ${n2(life)}.`,
          slips: [slip("used c", CMU * life, `The muon moves at v = βc: ${p.a}/${p.c} × 0.3 km per μs.`)] }),
        numStep("plain", "Distance without relativity", plain, 2, { unit: "km", hint: `Without the stretch it lives 2.2 μs: ${p.a}/${p.c} × 0.3 × 2.2.`,
          slips: [slip("used c", CMU * TAU, `The muon moves at v = βc: ${p.a}/${p.c} × 0.3 km per μs.`), slip("kept γ", far, "Without relativity there's no stretch: use the muon's own 2.2 μs.")] }),
        numStep("L", `The ${p.L0} km atmosphere in the muon's frame`, L, 2, { unit: "km", hint: `Lengths along the motion shrink by γ: ${p.L0} / ${n2(g)}.`,
          slips: [slip("multiplied", p.L0 * g, "In the muon's frame the atmosphere rushes past, so it's shorter: divide by γ.")] }),
      ];
    },
    scene: p => ({ scene: "lightclock", props: { mode: "muon", beta: p.a / p.c, hide: true } }),
  },
  oracle: p => { const b = p.a / p.c, g = 1 / Math.sqrt(1 - b * b); return [g, g * 2.2, b * 0.3 * g * 2.2, b * 0.3 * 2.2, p.L0 / g]; },
  useIt: {
    say: ["Real cosmic-ray muons move at about 0.998c, so γ ≈ 15.8 and they travel about 10.4 km on average: many reach the ground, which is why detectors in basements count them.",
      "Project: pick a speed for your own light clock. It draws the zigzag, prints γ, and shows how far a muon gets. Save it to keep γ on your Number shelf."],
    project: "re-lightclock",
  },
  deeper: [
    "The ladder (barn) paradox: a ladder too long for a barn fits inside it while running, in the barn's frame. In the ladder's frame the barn is shorter. Simultaneity resolves it: the two doors don't close at the same time for the ladder.",
    "There is no contraction across the motion: two trains on parallel tracks would otherwise each fit inside the other.",
    "In a wire carrying a current, the moving charges' spacing contracts. A charge moving beside the wire sees a net charge density: that is magnetism.",
  ],
};

/* ------------------------------------------------------------------ unit 2 ------------------------------------------------------------------ */

interface P04 extends PTri { dt: number; dx: number }
const firstChoices = (p: P04) => ["the flash at x = 0", `the flash at x = ${sn(p.dx)}`, "both at once"];

export const re04: B2Lesson<P04> = {
  id: "b2-re-04", track: "re", unit: 2, title: "Spacetime diagrams and the meaning of \"now\"",
  youCan: "read a spacetime diagram and find when two events happen for a moving traveler.",
  needs: ["b2-re-02"],
  tools: ["spacetime"],
  play: { scene: "spacetime", props: { mode: "pair", beta: 0 },
    say: "Two flashes go off at the same time at x = 0 and x = 4 light-years. Drag the traveler's speed: their \"now\" line tilts, and the two flashes stop being simultaneous for them." },
  guess: { scene: "spacetime", props: { mode: "pair", beta: 0.6 }, kind: "choice", options: ["The near flash", "The far flash", "Still at the same time"], answer: 1,
    ask: "The traveler heads toward +x at 3/5 of light speed. Which flash comes first for them?",
    revealProps: { mode: "pair", beta: 0.6, sweep: true },
    reveal: "Their \"now\" line sweeps up and meets the far flash first: for them it happened 3 years earlier." },
  nameIt: {
    say: [
      "A traveler's time axis is their worldline, tilted toward the light line, and their \"now\" line tilts the same amount from the other side.",
      "Events at the same time for you need not be at the same time for them. Using units where c = 1:",
    ],
    formula: ["Δt′ = γ(Δt − βΔx)", "Δx′ = γ(Δx − βΔt)"],
  },
  workIt: {
    reference: { a: 3, b: 4, c: 5, dt: 0, dx: 4 },
    generate(rng, i) {
      const t = triple(rng.pick(TRIPLES_EASY));
      const m = t.b, opts = [-2, -1, 0, 1, 2].map(k => k * m);
      if (i < 3) return { ...t, dt: 0, dx: rng.pick([m, 2 * m]) };
      let dt = 0, dx = 0;
      while (dx === 0) { dt = rng.pick(opts); dx = rng.pick(opts); }
      return { ...t, dt, dx };
    },
    show: p => `One flash at **t = 0, x = 0**, another at **t = ${sn(p.dt)}, x = ${sn(p.dx)}** (years and light-years). A traveler moves toward +x at **β = ${p.a}/${p.c}**.`,
    steps(p) {
      // whole numbers, worked in integers so no float noise reaches the words
      const g = p.c / p.b, b = p.a / p.c, dtp = (p.c * p.dt - p.a * p.dx) / p.b, dxp = (p.c * p.dx - p.a * p.dt) / p.b;
      const right = dtp > 0 ? 0 : dtp < 0 ? 1 : 2, ch = firstChoices(p);
      const which = dtp === 0 ? "" : `Δt′ = ${sn(dtp)} is the time of the flash at x = ${sn(p.dx)} minus the time of the one at x = 0. ${dtp < 0 ? "Negative" : "Positive"} means ${ch[right]} comes first.`;
      return [
        fracStep("g", "γ", g, { hint: `γ = 1/√(1 − β²) = ${p.c}/${p.b}.`, slips: [slip("didn't flip", p.b / p.c, `γ is 1 over √(1 − β²): ${p.c}/${p.b}.`)] }),
        wholeStep("dt", "Δt′", dtp, { unit: "years", hint: `Δt′ = ${fr(g)} × (${sn(p.dt)} − ${p.a}/${p.c} × ${sn(p.dx)}).`,
          slips: [
            slip("+βΔx", g * (p.dt + b * p.dx), "The traveler moves toward +x, so it's Δt − βΔx."),
            slip("forgot γ", p.dt - b * p.dx, `Both pieces get multiplied by γ = ${fr(g)}.`),
          ] }),
        wholeStep("dx", "Δx′", dxp, { unit: "light-years", hint: `Δx′ = ${fr(g)} × (${sn(p.dx)} − ${p.a}/${p.c} × ${sn(p.dt)}).`,
          slips: [
            slip("+βΔt", g * (p.dx + b * p.dt), "The traveler moves toward +x, so it's Δx − βΔt."),
            slip("forgot γ", p.dx - b * p.dt, `Both pieces get multiplied by γ = ${fr(g)}.`),
          ] }),
        tapStep("first", "Which comes first for the traveler", ch, right, { hint: "Look at the sign of Δt′.",
          slips: [
            right !== 2 && slip("simultaneous for everyone", 2, p.dt === 0
              ? "Equal times on the ground give Δt′ = −γβΔx, which is only 0 if the flashes are at the same place."
              : `Δt′ = ${sn(dtp)}, not 0: for the traveler they happen at different times.`),
            right !== 0 && slip("wrong order", 0, which || "Δt′ is 0: for the traveler they happen at the same time."),
            right !== 1 && slip("wrong order", 1, which || "Δt′ is 0: for the traveler they happen at the same time."),
          ] }),
      ];
    },
    scene: p => ({ scene: "spacetime", props: { mode: "pair", beta: p.a / p.c, e2t: p.dt, e2x: p.dx, quiet: true } }),
  },
  oracle: p => { const b = p.a / p.c, g = 1 / Math.sqrt(1 - b * b), d = g * (p.dt - b * p.dx); return [g, d, g * (p.dx - b * p.dt), Math.sign(d) > 0 ? 0 : Math.sign(d) < 0 ? 1 : 2]; },
  useIt: {
    say: ["Two GPS satellites on opposite sides of Earth send \"time = noon\" together by ground clocks. A receiver moving fast would disagree about whether they were sent together.",
      "So GPS fixes one frame to define \"now\": an Earth-centered frame that does not rotate."],
    scene: { scene: "spacetime", props: { mode: "pair", beta: 0.3 } },
  },
  deeper: [
    "Causality: events inside each other's light cones keep their order for everyone; events outside (\"elsewhere\") can swap. The light cones make spacetime a partial order.",
    "If a signal could go faster than light, a traveler could see it arrive before it left, and send a reply into the sender's own past.",
  ],
};

interface P05 extends PTri { ct: number; x: number; undo: boolean }
/** every (ct, x) in −13…13 whose boost by a/c lands on whole numbers */
function wholePairs(t: PTri, sign: 1 | -1): [number, number][] {
  const out: [number, number][] = [];
  for (let ct = -13; ct <= 13; ct++) for (let x = -13; x <= 13; x++) {
    if (!ct && !x) continue;
    const u = t.c * ct - sign * t.a * x, w = t.c * x - sign * t.a * ct;
    if (u % t.b === 0 && w % t.b === 0 && Math.abs(u / t.b) <= 20 && Math.abs(w / t.b) <= 20) out.push([ct, x]);
  }
  return out;
}

export const re05: B2Lesson<P05> = {
  id: "b2-re-05", track: "re", unit: 2, title: "The Lorentz boost is a matrix",
  youCan: "change frames with a 2 × 2 matrix and check it keeps the interval.",
  needs: ["b2-re-04", "b2-la-05", "b2-la-06"],
  tools: ["spacetime", "matrix"],
  play: { scene: "spacetime", props: { mode: "boost", beta: 0.3 },
    say: "Drag β and the diagram's grid squeezes along the light lines: one diagonal stretches by some factor, the other shrinks by the same factor. The boost's matrix updates as you drag." },
  guess: { scene: "spacetime", props: { mode: "boost", beta: 0.6, e1t: 5, e1x: 3, frame: "traveler", lockFrame: true, hideEvent: true, quiet: true }, kind: "point", answer: [4, 0], near: 0.75, start: [5, 3],
    ask: "The diagram is drawn in the traveler's frame (3/5 of light speed). Drag the marker to where you think the event (ct, x) = (5, 3) lands.",
    revealProps: { mode: "boost", beta: 0.6, e1t: 5, e1x: 3, frame: "traveler", lockFrame: true, applied: true },
    reveal: "The matrix sends (5, 3) to (4, 0): straight onto the traveler's own time axis, 4 ticks up." },
  nameIt: {
    say: [
      "The boost is linear, so it is a matrix acting on (ct, x).",
      "Its determinant is 1, so it keeps areas, and it keeps (ct)² − x² the same, the way a turn keeps x² + y².",
    ],
    formula: ["Λ = [[γ, −βγ], [−βγ, γ]]", "(ct′, x′) = Λ (ct, x)", "det Λ = γ²(1 − β²) = 1"],
  },
  workIt: {
    reference: { a: 3, b: 4, c: 5, ct: 5, x: 3, undo: false },
    generate(rng, i) {
      if (i < 3) {
        const t = triple([3, 4, 5]);
        const easy: [number, number][] = [[5, 3], [4, 0], [8, 4], [3, 5], [4, 4]];
        const [ct, x] = i === 0 ? [5, 3] : rng.pick(easy);
        return { ...t, ct, x, undo: false };
      }
      const t = triple(rng.pick([[3, 4, 5], [4, 3, 5], [5, 12, 13], [12, 5, 13]] as [number, number, number][]));
      const undo = i >= 4 && rng.next() < 0.4;
      const [ct, x] = rng.pick(wholePairs(t, undo ? -1 : 1));
      return { ...t, ct, x, undo };
    },
    show: p => p.undo
      ? `A traveler moving at **β = ${p.a}/${p.c}** measures an event at **(ct′, x′) = (${sn(p.ct)}, ${sn(p.x)})**. Undo the boost: use β → −β.`
      : `A traveler moves at **β = ${p.a}/${p.c}**. Boost the event **(ct, x) = (${sn(p.ct)}, ${sn(p.x)})** into their frame.`,
    steps(p) {
      const g = p.c / p.b, bg = p.a / p.b, s = p.undo ? -1 : 1;
      const T = (p.c * p.ct - s * p.a * p.x) / p.b, X = (p.c * p.x - s * p.a * p.ct) / p.b, s2 = p.ct * p.ct - p.x * p.x;
      const [tl, xl] = p.undo ? ["ct", "x"] : ["ct′", "x′"];
      return [
        multiStep("gbg", "γ and βγ", [g, bg], "fraction", { boxes: ["γ", "βγ"], hint: `γ = ${p.c}/${p.b}, and βγ = ${p.a}/${p.c} × ${p.c}/${p.b}.`,
          slips: [slip("βγ as β", [g, p.a / p.c], `βγ is β times γ: ${p.a}/${p.c} × ${p.c}/${p.b} = ${fr(bg)}.`)] }),
        wholeStep("t", tl, T, { hint: p.undo ? `${tl} = γ(ct′ + βx′).` : `${tl} = γ(ct − βx) = ${fr(g)} × (${sn(p.ct)} − ${p.a}/${p.c} × ${sn(p.x)}).`,
          slips: p.undo
            ? [slip("forward boost", g * p.ct - bg * p.x, "To undo the boost, use β → −β: the off-diagonal entries become +βγ.")]
            : [slip("Galilean", p.ct, `Time changes too: ct′ = γ(ct − βx) = ${fr(g)} × ${fr(p.ct - (p.a / p.c) * p.x)} = ${fr(T)}.`),
              slip("plus signs", g * p.ct + bg * p.x, "The traveler moves toward +x, so both off-diagonal entries are −βγ.")] }),
        wholeStep("x", xl, X, { hint: p.undo ? `${xl} = γ(x′ + βct′).` : `${xl} = γ(x − βct).`,
          slips: p.undo
            ? [slip("forward boost", g * p.x - bg * p.ct, "To undo the boost, use β → −β: the off-diagonal entries become +βγ.")]
            : [slip("Galilean", p.x - (p.a / p.c) * p.ct, `Lengths change too: x′ = γ(x − βct), not just x − βct.`),
              slip("plus signs", g * p.x + bg * p.ct, "The traveler moves toward +x, so both off-diagonal entries are −βγ.")] }),
        multiStep("s2", "(ct)² − x² before and after", [s2, s2], "whole", { boxes: ["before", "after"], hint: "Square, then subtract: the two should match.",
          slips: [slip("sum", [p.ct * p.ct + p.x * p.x, T * T + X * X], "A boost keeps the difference (ct)² − x², not the sum.")] }),
        wholeStep("det", "det Λ", 1, { hint: "γ × γ − (βγ)(βγ) = γ²(1 − β²).",
          slips: [slip("γ²", g * g, "det = γ·γ − (βγ)(βγ) = γ²(1 − β²) = 1."), slip("plus", g * g + bg * bg, "The determinant subtracts the off-diagonal product: γ² − (βγ)².")] }),
      ];
    },
    scene: p => ({ scene: "spacetime", props: { mode: "boost", beta: (p.undo ? -1 : 1) * (p.a / p.c), e1t: p.ct, e1x: p.x, quiet: true } }),
  },
  oracle: p => {
    const b = (p.undo ? -1 : 1) * (p.a / p.c), g = 1 / Math.sqrt(1 - b * b);
    const L = [[g, -b * g], [-b * g, g]], v = [p.ct, p.x];
    const out = L.map(r => r[0]! * v[0]! + r[1]! * v[1]!);
    const s2 = p.ct ** 2 - p.x ** 2;
    return [g, Math.abs(b) * g, out[0]!, out[1]!, s2, out[0]! ** 2 - out[1]! ** 2, L[0]![0]! * L[1]![1]! - L[0]![1]! * L[1]![0]!];
  },
  useIt: {
    say: ["Save the boost for β = 3/5 as `boost`. Then undo it with β = −3/5 in the Matrix pad and check that the product is the identity: the inverse of a boost is the boost the other way."],
    saves: { name: "boost", value: () => boost(0.6), note: "the boost for β = 3/5" },
    scene: { scene: "spacetime", props: { mode: "boost", beta: 0.6 } },
  },
  deeper: [
    "Write γ = cosh w and βγ = sinh w: a boost is a hyperbolic rotation by the rapidity w.",
    "In 4D, boosts and turns make the Lorentz group SO⁺(1, 3): the matrices with ΛᵀηΛ = η for η = diag(1, −1, −1, −1), just as turns are the matrices with QᵀQ = I (b2-la-16).",
    "Upper and lower indices (contravariant and covariant) are the change-of-basis story of b2-la-12.",
  ],
};

type P06 = { kind: "interval"; t: number; x: number } | ({ kind: "twin"; D: number } & PTri);
const PAIRS: [number, number][] = [[5, 3], [5, 4], [13, 5], [13, 12], [17, 8], [25, 7], [10, 6], [10, 8]];
const KINDS = ["timelike", "lightlike", "spacelike"];

export const re06: B2Lesson<P06> = {
  id: "b2-re-06", track: "re", unit: 2, title: "The interval and proper time",
  youCan: "find the one time every observer agrees on, and use it to solve the twin trip.",
  needs: ["b2-re-05"],
  tools: ["spacetime", "twin"],
  play: { scene: "spacetime", props: { mode: "interval", beta: 0.3 },
    say: "Two events on the diagram. Drag β: their time and distance gaps change, but the curve through the second event never moves. Then bend the worldline: the straight one always has the most ticks." },
  guess: { scene: "twin", props: { D: 3, beta: 0.6, hide: true }, kind: "slider", min: 0, max: 10, step: 0.5, start: 5, answer: 8, near: 0.5, unit: "years",
    format: x => x.toFixed(1),
    ask: "One twin stays home; the other flies 3 light-years out and back at 3/5 of light speed. When the home twin has aged 10 years, how much has the traveler aged?",
    revealProps: { D: 3, beta: 0.6 },
    reveal: "Count the ticks: 10 on the straight worldline at home, 8 on the bent one. The traveler comes back 2 years younger." },
  nameIt: {
    say: [
      "The interval s² = (cΔt)² − Δx² is the same for everyone. When it's positive (timelike), its square root is the proper time: what a clock that goes straight between the two events reads. A bent path reads less.",
      "When it's negative (spacelike), no clock can get from one to the other, and √(−s²) is their proper distance instead.",
    ],
    formula: ["s² = (cΔt)² − Δx²", "τ = √(s²) / c", "s² > 0 timelike, = 0 lightlike, < 0 spacelike"],
  },
  workIt: {
    reference: { kind: "interval", t: 5, x: 3 },
    generate(rng, i): P06 {
      if (i < 3) { const [t, x] = rng.pick(PAIRS.slice(0, 2)); return { kind: "interval", t, x }; }
      if (rng.next() < 0.35) {
        const tr = triple(rng.pick(RE_TRIPLES));
        return { kind: "twin", ...tr, D: tr.a * rng.int(1, Math.max(1, Math.floor(24 / tr.a))) };
      }
      const r = rng.next(), sgn = rng.pick([1, -1]);
      if (r < 0.15) { const k = rng.int(2, 12); return { kind: "interval", t: k, x: sgn * k }; }
      const [a, b] = rng.pick(PAIRS);
      return r < 0.35 ? { kind: "interval", t: b, x: sgn * a } : { kind: "interval", t: a, x: sgn * b };
    },
    show: p => p.kind === "twin"
      ? `A twin flies to a star **${count(p.D, "light-year")}** away and back at **β = ${p.a}/${p.c}**. The other stays home.`
      : `Two events are **cΔt = ${p.t}** apart in time and **Δx = ${sn(p.x)}** apart in space (light-years).`,
    steps(p): B2Step[] {
      if (p.kind === "twin") {
        const b = p.a / p.c, home = (2 * p.D) / b, trav = home * (p.b / p.c);
        return [
          wholeStep("home", "Home time", home, { unit: "years", hint: `Out and back is 2 × ${p.D} light-years at ${p.a}/${p.c} of light speed: 2 × ${p.D} / (${p.a}/${p.c}).`,
            slips: [slip("one way", p.D / b, "The trip is out and back: 2 × D / β.")] }),
          wholeStep("trav", "Traveler time", trav, { unit: "years", hint: `The traveler's clock runs slow by γ = ${p.c}/${p.b}: ${group(home)} / (${p.c}/${p.b}).`,
            slips: [slip("multiplied", home * (p.c / p.b), "The traveler's clock runs slow: divide by γ, so the number is smaller.")] }),
          wholeStep("diff", "Difference", home - trav, { unit: "years", hint: "Home time minus traveler time." }),
        ];
      }
      const s2 = p.t * p.t - p.x * p.x, kind = s2 > 0 ? 0 : s2 === 0 ? 1 : 2, ax = Math.abs(p.x);
      const last = kind === 2
        ? numStep("tau", "Proper distance", Math.sqrt(-s2), 0, { unit: "light-years", hint: `√(−s²) = √(${-s2}).`,
          slips: [slip("no root", -s2, "That's −s². The proper distance is its square root.")] })
        : wholeStep("tau", "τ", Math.sqrt(s2), { unit: "years", hint: kind === 1 ? "s² = 0, so τ = 0: light's own clock never ticks." : `τ = √(s²) = √(${s2}).`,
          slips: [
            slip("subtracted first", p.t - ax, `Square first, subtract, then take the root: √(${p.t * p.t} − ${ax * ax}) = ${Math.sqrt(s2)}.`),
            slip("no root", s2, "That's s². τ is its square root."),
          ] });
      return [
        wholeStep("s2", "s²", s2, { hint: `(cΔt)² − Δx² = ${p.t}² − ${ax}².`,
          slips: [slip("added", p.t * p.t + p.x * p.x, `Spacetime's rule has a minus sign: ${p.t * p.t} − ${ax * ax}.`)] }),
        tapStep("kind", "Kind", KINDS, kind, { hint: "The sign of s² decides it.",
          slips: [
            kind === 0 && slip("spacelike for s² > 0", 2, "Positive s² means time wins: a clock can travel between them, so it's timelike."),
            kind === 2 && slip("timelike for s² < 0", 0, "Negative s² means space wins: not even light gets from one to the other, so it's spacelike."),
            kind === 1 && slip("missed lightlike", 0, "s² = 0 means light itself connects them: lightlike."),
            kind === 1 && slip("missed lightlike", 2, "s² = 0 means light itself connects them: lightlike."),
            kind !== 1 && slip("lightlike", 1, `Lightlike is only when s² = 0. Here s² = ${sn(s2)}.`),
          ] }),
        last,
      ];
    },
    scene: (p): SceneRef => p.kind === "twin" ? { scene: "twin", props: { D: p.D, beta: p.a / p.c, hide: true } } : { scene: "spacetime", props: { mode: "interval", beta: 0, e1t: p.t, e1x: p.x, quiet: true } },
  },
  oracle: p => {
    if (p.kind === "twin") { const b = p.a / p.c, g = 1 / Math.sqrt(1 - b * b); return [(2 * p.D) / b, (2 * p.D) / b / g, (2 * p.D) / b - (2 * p.D) / b / g]; }
    const s2 = p.t ** 2 - p.x ** 2;
    return [s2, s2 > 0 ? 0 : s2 === 0 ? 1 : 2, s2 > 0 ? Math.sqrt(s2) : s2 === 0 ? 0 : Math.sqrt(-s2)];
  },
  useIt: {
    say: ["Project: pick a star and a speed. The planner draws both worldlines and prints both ages on return. Save it to keep them as `twin`.",
      "This is the GPS question in miniature: two clocks, two paths through spacetime, two readings."],
    project: "re-twin",
  },
  deeper: [
    "Proper time is the length of a path: τ = ∫ √(1 − v²/c²) dt, measured with the Minkowski metric ds² = c²dt² − dx² − dy² − dz².",
    "Straight worldlines have the most proper time (maximal aging): the reverse of the triangle inequality.",
    "At the turnaround, the traveler's \"now\" line swings across the home twin's worldline: that jump is where the missing years go.",
  ],
};


interface P07 { u: number; v: number; matrix: boolean }
const SPEEDS = [1 / 2, 1 / 3, 2 / 3, 1 / 4, 3 / 4, 3 / 5, 4 / 5, 1 / 5];

export const re07: B2Lesson<P07> = {
  id: "b2-re-07", track: "re", unit: 2, title: "Adding speeds near light",
  youCan: "add two speeds the relativistic way and see why the result stays below c.",
  needs: ["b2-re-05", "b2-la-06"],
  tools: ["adder", "matrix"],
  play: { scene: "adder", props: { u: 0.5, v: 0.5 },
    say: "A ship at u fires a probe forward at v. Drag both: the plain sum bar shoots past c, while the true result slows down as it gets close and never reaches it." },
  guess: { scene: "adder", props: { u: 0.8, v: 0.8, hide: true }, kind: "slider", min: 0, max: 1, step: 0.005, start: 0.5, answer: 40 / 41, near: 0.02, unit: "c",
    format: x => x.toFixed(3),
    ask: "0.8c plus 0.8c. Drag to your guess for the result.",
    revealProps: { u: 0.8, v: 0.8 },
    reveal: "1.6 / 1.64 = 40/41, about 0.976c: close to light speed, never past it." },
  nameIt: {
    say: [
      "Speeds don't simply add. Combining two boosts is multiplying two boost matrices, and the product is the boost for the combined speed.",
      "At small speeds the bottom is about 1 and you get u + v back.",
    ],
    formula: ["u ⊕ v = (u + v) / (1 + uv/c²)", "with c = 1: (u + v) / (1 + uv)"],
  },
  workIt: {
    reference: { u: 3 / 5, v: 3 / 5, matrix: false },
    generate(rng, i) {
      if (i < 3) { const [u, v] = [[1 / 2, 1 / 2], [1 / 2, 1 / 3], [1 / 4, 1 / 2]][i]!; return { u: u!, v: v!, matrix: false }; }
      if (i >= 4 && rng.next() < 0.35) return { u: rng.pick([3 / 5, 4 / 5]), v: rng.pick([3 / 5, 4 / 5]), matrix: true };
      return { u: rng.pick(SPEEDS), v: rng.pick(SPEEDS), matrix: false };
    },
    show: p => `A ship moves at **u = ${fr(p.u)}** of light speed and fires a probe forward at **v = ${fr(p.v)}**.${p.matrix ? " Then check it by multiplying the two boost matrices." : ""}`,
    steps(p) {
      const top = p.u + p.v, bot = 1 + p.u * p.v, w = top / bot;
      const steps = [
        fracStep("top", "Top", top, { ask: "u + v", hint: `${fr(p.u)} + ${fr(p.v)}.` }),
        fracStep("bot", "Bottom", bot, { ask: "1 + uv", hint: `1 + ${fr(p.u)} × ${fr(p.v)}.`,
          slips: [slip("1 − uv", 1 - p.u * p.v, "The bottom is 1 plus uv, which makes the result smaller, not bigger.")] }),
        fracStep("w", "u ⊕ v", w, { hint: `Top over bottom: ${fr(top)} ÷ ${fr(bot)}.`,
          slips: [
            slip("plain sum", top, top > 1 ? "Above 1 means faster than light. Divide by 1 + uv." : "That's the plain sum. Divide it by 1 + uv."),
            slip("1 − uv", top / (1 - p.u * p.v), "The bottom is 1 plus uv, which makes the result smaller, not bigger."),
            slip("flipped", bot / top, `Speed is the top over the bottom: (${fr(top)}) ÷ (${fr(bot)}).`),
          ] }),
        tapStep("ftl", "Faster than light?", ["yes", "no"], 1, { hint: "Compare u ⊕ v with 1.",
          slips: [slip("faster", 0, `u ⊕ v is below 1 whenever u and v are: here ${fr(w)}.`)] }),
      ];
      if (p.matrix) {
        const gu = gammaOf(p.u), gv = gammaOf(p.v), G = gu * gv * (1 + p.u * p.v);
        steps.push(fracStep("G", "γ of the product", G, { ask: "Multiply the boosts for u and v. What is the top-left entry?",
          hint: `Top-left: γ₁γ₂ + (β₁γ₁)(β₂γ₂) = ${fr(gu)} × ${fr(gv)} + ${fr(p.u * gu)} × ${fr(p.v * gv)}.`,
          slips: [slip("γ₁γ₂ only", gu * gv, "Multiply the matrices: the top-left entry is γ₁γ₂ + (β₁γ₁)(β₂γ₂)."), slip("minus", gu * gv * (1 - p.u * p.v), "Both off-diagonal entries are negative, so their product adds: γ₁γ₂ + (β₁γ₁)(β₂γ₂).")] }));
      }
      return steps;
    },
    scene: p => ({ scene: "adder", props: { u: p.u, v: p.v, hide: true } }),
  },
  oracle: p => {
    const out = [p.u + p.v, 1 + p.u * p.v, (p.u + p.v) / (1 + p.u * p.v), 1];
    if (p.matrix) { const A = boost(p.u), B = boost(p.v); out.push(A[0]![0]! * B[0]![0]! + A[0]![1]! * B[1]![0]!); }
    return out;
  },
  useIt: {
    say: ["Light itself: 1 ⊕ v = (1 + v)/(1 + v) = 1, so a ship's headlight still moves at c.",
      "Two beams of particles at 0.9c head-on close at 1.8/1.81, about 0.9945c, as either one sees it."],
    scene: { scene: "adder", props: { u: 0.9, v: 0.9 } },
  },
  deeper: [
    "Rapidities add: w = artanh β, and w(u ⊕ v) = w(u) + w(v). That's why boosts form a one-parameter group (b2-la-06).",
    "Two boosts in different directions make a boost and a turn: the Thomas–Wigner rotation.",
    "The relativistic Doppler factor √((1 + β)/(1 − β)) is 2 at β = 3/5, and Doppler factors multiply.",
  ],
};

/* ------------------------------------------------------------------ unit 3 ------------------------------------------------------------------ */

interface P08 { m: number; p: number; E: number; hide: "m" | "p" | "E" }
const ENERGY: [number, number, number][] = [[3, 4, 5], [5, 12, 13], [8, 15, 17], [7, 24, 25], [20, 21, 29]];
const HIDDEN = { E: "Total energy E", p: "Momentum pc", m: "Rest energy mc²" } as const;

export const re08: B2Lesson<P08> = {
  id: "b2-re-08", track: "re", unit: 3, title: "Energy, momentum and E = mc²",
  youCan: "find a particle's energy, momentum and speed from two of them, and turn mass into energy.",
  needs: ["b2-re-05", "b2-re-06"],
  tools: ["energy", "units"],
  play: { scene: "energy", props: { m: 3, p: 2 },
    say: "A right triangle with legs mc² and pc and hypotenuse E. Drag the momentum: pc grows, E grows with it, and the speed β = pc / E creeps toward 1 but never reaches it." },
  guess: { scene: "energy", props: { m: 3, p: 4, hide: true }, kind: "slider", min: 3, max: 9, step: 0.1, start: 6, answer: 5, near: 0.25, unit: "MeV",
    format: x => x.toFixed(1),
    ask: "A particle has rest energy 3 MeV and momentum 4 MeV/c. What is its total energy?",
    revealProps: { m: 3, p: 4 },
    reveal: "The 3-4-5 triangle: E = 5 MeV, not 7. Energies add like the sides of a right triangle." },
  nameIt: {
    say: [
      "Energy and momentum together form an arrow in spacetime whose length, the rest energy mc², is the same for everyone.",
      "At rest, the energy is all mass: E = mc². A massless particle like light has E = pc.",
    ],
    formula: ["E² = (pc)² + (mc²)²", "E = γmc²", "β = pc / E", "kinetic energy = E − mc²"],
  },
  workIt: {
    reference: { m: 3, p: 4, E: 5, hide: "E" },
    generate(rng, i) {
      if (i < 3) return { m: 3, p: 4, E: 5, hide: "E" };
      const [a, b, c] = rng.pick(ENERGY), k = rng.next() < 0.3 ? rng.pick([2, 10]) : 1;
      const [m, p] = rng.next() < 0.5 ? [a, b] : [b, a];
      return { m: m * k, p: p * k, E: c * k, hide: rng.pick(["E", "p", "m"] as const) };
    },
    show: p => {
      const known = (["m", "p", "E"] as const).filter(k => k !== p.hide).map(k => k === "m" ? `rest energy **mc² = ${p.m} MeV**` : k === "p" ? `momentum **pc = ${p.p} MeV**` : `total energy **E = ${p.E} MeV**`);
      return `A particle has ${known[0]} and ${known[1]}.`;
    },
    steps(p) {
      const first = p.hide === "E"
        ? wholeStep("E", HIDDEN.E, p.E, { unit: "MeV", hint: `E = √((pc)² + (mc²)²) = √(${p.p * p.p} + ${p.m * p.m}).`,
          slips: [slip("added", p.m + p.p, `Energies combine like the sides of a right triangle: √(${p.m * p.m} + ${p.p * p.p}).`)] })
        : p.hide === "p"
          ? wholeStep("p", HIDDEN.p, p.p, { unit: "MeV", hint: `pc = √(E² − (mc²)²) = √(${p.E * p.E} − ${p.m * p.m}).`,
            slips: [slip("subtracted", p.E - p.m, `Energies combine like the sides of a right triangle: pc = √(${p.E * p.E} − ${p.m * p.m}).`)] })
          : wholeStep("m", HIDDEN.m, p.m, { unit: "MeV", hint: `mc² = √(E² − (pc)²) = √(${p.E * p.E} − ${p.p * p.p}).`,
            slips: [slip("subtracted", p.E - p.p, `Energies combine like the sides of a right triangle: mc² = √(${p.E * p.E} − ${p.p * p.p}).`)] });
      return [
        first,
        fracStep("g", "γ", p.E / p.m, { hint: `γ = E / mc² = ${p.E}/${p.m}.`,
          slips: [slip("flipped", p.m / p.E, "γ is the total energy over the rest energy: E / mc², at least 1.")] }),
        fracStep("b", "β", p.p / p.E, { hint: `β = pc / E = ${p.p}/${p.E}.`,
          slips: [slip("mc² / E", p.m / p.E, "Speed comes from momentum: β = pc / E. A particle at rest has pc = 0 and β = 0.")] }),
        wholeStep("K", "Kinetic energy", p.E - p.m, { unit: "MeV", hint: `E − mc² = ${p.E} − ${p.m}.`,
          slips: [
            slip("½mv²", (p.m * (p.p / p.E) ** 2) / 2, `At this speed ½mv² is wrong. Kinetic energy is E − mc², here ${p.E - p.m} MeV.`),
            slip("total", p.E, "That's the total. Kinetic energy is what's left after the rest energy: E − mc²."),
          ] }),
      ];
    },
    scene: p => ({ scene: "energy", props: { m: p.m, p: p.p, hide: true } }),
  },
  oracle: p => { const E = Math.sqrt(p.m ** 2 + p.p ** 2); return [p.hide === "E" ? E : p.hide === "p" ? Math.sqrt(p.E ** 2 - p.m ** 2) : Math.sqrt(p.E ** 2 - p.p ** 2), E / p.m, p.p / E, E - p.m]; },
  useIt: {
    say: ["The Sun shines 3.828 × 10²⁶ W. Dividing by c² gives the mass it turns into light each second: 4.26 × 10⁹ kg, about 4 million tonnes.",
      "One gram of mass is 9.0 × 10¹³ J, about 21.5 kilotons of TNT."],
    scene: { scene: "energy", props: { m: 3, p: 4 } },
  },
  deeper: [
    "The four-momentum (E/c, p) has an invariant length: the rest energy. A box of hot gas weighs more than the same gas cold.",
    "Threshold energy: making an antiproton by smashing protons into a still target needs a kinetic energy of 6 m_p c² ≈ 5.6 GeV.",
    "Helium-4 weighs about 0.75% less than its parts; that missing mass is the energy fusion releases. The Dirac equation is where relativity meets quantum (b2-qu-05, the Pauli matrices).",
  ],
};

interface P09 { v: number; name: string | null; ns: boolean }
const SPEED_LIST = [
  { v: 7.67, name: "the space station (about 400 km up)" },
  { v: 3.873, name: "a GPS satellite" },
  { v: 3.075, name: "a geostationary satellite" },
  { v: 1.022, name: "the Moon" },
];

export const re09: B2Lesson<P09> = {
  id: "b2-re-09", track: "re", unit: 3, title: "Slow speeds: the v²/2c² rule",
  youCan: "find how much a moving clock falls behind per day at everyday and orbital speeds.",
  needs: ["b2-re-02", "bc-taylor", "b2-or-02"],
  tools: ["graph2d", "units"],
  play: { scene: "smallspeed", props: { beta: 0.3 },
    say: "The curve γ against β with the parabola 1 + β²/2 laid over it. Drag the speed marker: γ − 1 and β²/2 track each other, and zoomed in toward everyday speeds they can't be told apart." },
  guess: { scene: "smallspeed", props: { beta: 7.67 / C_KMS, zoom: true }, kind: "choice", options: ["0.03", "3", "28", "280"], answer: 2,
    ask: "A space station clock (about 400 km up) moves at 7.67 km/s. How many microseconds per day does it lose to a ground clock?",
    revealProps: { beta: 7.67 / C_KMS, zoom: true, day: true },
    reveal: "28.3 μs a day. Each second it loses only 3.27 × 10⁻¹⁰ s, but a day has 86,400 of them." },
  nameIt: {
    say: [
      "For speeds far below c, γ is almost exactly 1 + β²/2, so a moving clock loses the fraction v²/2c² of every second.",
      "Over a day that adds up to something measurable.",
    ],
    formula: ["γ ≈ 1 + v² / (2c²)", "loss per day = (v² / 2c²) × 86,400 s", "with v in km/s: ≈ 0.4807 v² μs per day"],
  },
  workIt: {
    reference: { v: 7.67, name: "the space station (about 400 km up)", ns: false },
    generate(rng, i) {
      if (i < 3) return { v: rng.int(1, 8), name: null, ns: false };
      const r = rng.next();
      if (r < 0.5) { const s = rng.pick(SPEED_LIST); return { v: s.v, name: s.name, ns: false }; }
      if (r < 0.65) return { v: 0.25, name: "an airliner", ns: true };
      return { v: rng.int(100, 800) / 100, name: null, ns: false };
    },
    show: p => `A clock moves at **v = ${p.v} km/s**${p.name ? `, on ${p.name}` : ""}. How much does it lose each day against a ground clock?`,
    steps(p) {
      const f = slowFraction(p.v), e = expOf(f), mant = f / 10 ** e;
      const k = p.ns ? 1000 : 1, loss = lossPerDayUs(p.v) * k, unit = p.ns ? "ns" : "μs";
      return [
        numStep("v2", "v²", p.v * p.v, 2, { unit: "km²/s²", hint: `${p.v} × ${p.v}.`, slips: [slip("doubled", 2 * p.v, "v² is v times v, not 2 × v.")] }),
        numStep("f", `v² / 2c² ${tenTo(e)}`, mant, 2, { ask: `The fraction lost each second, as a number ${tenTo(e)}. Use c = 299,792 km/s.`,
          hint: `${n2(p.v * p.v)} / (2 × 299,792²), then read it ${tenTo(e)}.`,
          slips: [slip("forgot ½", 2 * mant, "The rule is v² over 2c²: half the square of β.")] }),
        numStep("loss", "Loss per day", loss, 1, { unit, hint: `Multiply the fraction by the 86,400 seconds in a day, then write it in ${unit}.`,
          slips: [
            slip("forgot ½", 2 * loss, "The rule is v² over 2c²: half the square of β."),
            slip("didn't square", (p.v / (2 * C_KMS * C_KMS)) * DAY * 1e6 * k, "The loss grows with the square of the speed: double the speed, four times the loss."),
            slip("hour", f * 3600 * 1e6 * k, "A day is 86,400 seconds."),
            slip("24", f * 24 * 1e6 * k, "A day is 86,400 seconds."),
          ] }),
      ];
    },
    scene: p => ({ scene: "smallspeed", props: { beta: p.v / C_KMS, zoom: true, quiet: true } }),
  },
  oracle: p => {
    const f = p.v ** 2 / (2 * 299792.458 ** 2);
    return [p.v ** 2, f / 10 ** Math.floor(Math.log10(f)), f * 86400e6 * (p.ns ? 1000 : 1)];
  },
  useIt: {
    say: ["Project: clocks that travel. An airliner loses 30.0 ns a day, the space station 28.3 μs, a GPS satellite 7.2 μs.",
      "The GPS number is the speed half of the build. Save it as `sr_drift`: −7.2 μs per day, since the satellite clock falls behind."],
    project: "re-clocks",
  },
  deeper: [
    "The Taylor series γ = 1 + β²/2 + 3β⁴/8 + … has an error bound: the next term is under 10⁻¹⁹ for GPS.",
    "Kinetic energy (γ − 1)mc² ≈ ½mv² + (3/8)mv⁴/c², so Newton's ½mv² is relativity's first term.",
    "The 1971 Hafele–Keating test: cesium clocks flown east lost about 59 ns and flown west gained about 273 ns, matching predictions once gravity and Earth's spin were counted.",
  ],
};

/* ------------------------------------------------------------------ unit 4 ------------------------------------------------------------------ */

interface P10 { h: number; name: string | null }
const HEIGHTS = [{ h: 22.5, name: "the Harvard tower" }, { h: 828, name: "the Burj Khalifa" }, { h: 1609, name: "Denver" }, { h: 8849, name: "Everest" }];

export const re10: B2Lesson<P10> = {
  id: "b2-re-10", track: "re", unit: 4, title: "Gravity bends time: higher clocks run fast",
  youCan: "find how much faster a clock runs a height h above another near Earth's surface.",
  needs: ["b2-re-09"],
  tools: ["well", "units"],
  play: { scene: "rocket", props: { acc: 1 },
    say: "Two clocks at the top and bottom of a rocket that is speeding up. The bottom clock sends a pulse every second; drag the rocket's acceleration and watch the pulses arrive at the top further apart." },
  guess: { scene: "rocket", props: { acc: 1.5, hide: true }, kind: "choice", options: ["Faster", "Slower", "The same"], answer: 0,
    ask: "In the accelerating rocket, does the top clock tick faster, slower, or the same as the bottom one?",
    revealProps: { acc: 1.5, count: true },
    reveal: "Faster. The bottom's pulses arrive at the top stretched apart, so the top clock counts more of its own ticks between them." },
  nameIt: {
    say: [
      "Standing still in gravity is the same as speeding up in empty space (the equivalence principle).",
      "So a clock higher in gravity ticks faster, by the fraction gh/c². Gravity doesn't just pull: it changes the rate of time.",
    ],
    formula: ["higher clock gains gh / c² per second", "per day: (gh / c²) × 86,400 s"],
  },
  workIt: {
    reference: { h: 1000, name: null },
    generate(rng, i) {
      if (i < 3) return { h: rng.pick([1000, 2000]), name: null };
      if (rng.next() < 0.5) return rng.pick(HEIGHTS);
      return { h: rng.int(1, 90) * 100, name: null };
    },
    show: p => `One clock sits **${group(p.h, p.h % 1 ? 1 : 0)} m** above another${p.name ? ` (${p.name})` : ""}. Use g = 9.81 m/s².`,
    steps(p) {
      const f = (9.81 * p.h) / (C * C), e = expOf(f), mant = f / 10 ** e, gain = heightGainNs(p.h);
      return [
        tapStep("which", "Which clock runs faster", ["the higher one", "the lower one", "neither"], 0, { hint: "Think of the rocket: the top clock counts more ticks.",
          slips: [
            slip("lower", 1, "Light climbing out of gravity arrives stretched, so the bottom clock looks slow from the top. Higher clocks run fast."),
            slip("neither", 2, "Gravity changes the rate of time: the higher clock runs fast."),
          ] }),
        numStep("f", `gh / c² ${tenTo(e)}`, mant, 2, { ask: `The fraction gained each second, as a number ${tenTo(e)}.`,
          hint: `9.81 × ${group(p.h, p.h % 1 ? 1 : 0)} / 299,792,458², then read it ${tenTo(e)}.`,
          slips: [slip("c, not c²", ((9.81 * p.h) / C) / 10 ** e, "The fraction is gh/c²: c squared, from the same v²/c² as before.")] }),
        numStep("gain", "Gain per day", gain, 2, { unit: "ns", hint: "Multiply the fraction by 86,400 s, then write it in nanoseconds.",
          slips: [slip("forgot the day", mant, "That's the fraction per second. Multiply by 86,400 s for a day."), slip("hour", f * 3600 * 1e9, "A day is 86,400 seconds.")] }),
      ];
    },
    scene: p => ({ scene: "rocket", props: { acc: Math.min(3, 0.5 + Math.log10(p.h)), hide: true } }),
  },
  oracle: p => { const f = (9.81 * p.h) / 299792458 ** 2; return [0, f / 10 ** Math.floor(Math.log10(f)), f * 86400e9]; },
  useIt: {
    say: ["A clock on Everest gains 83.45 ns a day on one at sea level; over 70 years that's about 2.13 ms.",
      "In 2010 clocks saw the difference for a lift of 33 cm; by 2022, across about a millimeter."],
    scene: { scene: "rocket", props: { acc: 2 } },
  },
  deeper: [
    "Derive gh/c² from the Doppler shift in the accelerating rocket: by the time a pulse climbs h, the top is moving faster by gh/c, which shifts its frequency by gh/c².",
    "The Pound–Rebka experiment (1959) measured a shift of 2.46 × 10⁻¹⁵ up the 22.5 m Harvard tower. In terms of the potential Φ: Δτ/τ = ΔΦ/c².",
    "Rindler observers: behind a rocket that keeps accelerating there is a horizon light can never cross to reach it.",
  ],
};

interface P11 { r: number; name: string | null }
const RADII = [
  { r: 6771, name: "the space station" }, { r: 12742, name: "2 Earth radii" }, { r: 26571, name: "GPS" },
  { r: 29600, name: "Galileo" }, { r: 42164, name: "geostationary orbit" },
];

export const re11: B2Lesson<P11> = {
  id: "b2-re-11", track: "re", unit: 4, title: "Far from Earth: the full gravity shift",
  youCan: "find how much faster a clock runs in orbit than on the ground because of gravity alone.",
  needs: ["b2-re-10", "b2-or-06"],
  tools: ["well", "units"],
  play: { scene: "well", props: { r: 2 },
    say: "The well z = −1/r around Earth with clocks at different radii. Drag a clock outward: its rate keeps rising, but more and more slowly, toward a ceiling far from Earth." },
  guess: { scene: "well", props: { r: 26571 / R_KM }, kind: "choice", options: ["Bigger", "About the same", "Much smaller"], answer: 2,
    ask: "Using gh/c² straight up to GPS height (h = 20,200 km) gives about 190 μs per day. Is the true gain bigger, about the same, or much smaller?",
    revealProps: { r: 26571 / R_KM, compare: true },
    reveal: "Much smaller: 45.7 μs per day. gh/c² is a straight line, but the true curve bends over toward a ceiling of 60.1 μs." },
  nameIt: {
    say: [
      "gh/c² only works while g stays the same. Far away, use the gravitational potential −GM/r instead: the rate gain is the change in potential over c².",
      "Measured from the ground, it can never exceed GM/(c²R).",
    ],
    formula: ["gain = (GM / c²)(1/R − 1/r) = (GM / c²R)(1 − R/r)", "GM/(c²R) = 6.96 × 10⁻¹⁰ for Earth: 60.1 μs per day"],
  },
  workIt: {
    reference: { r: 26571, name: "GPS" },
    generate(rng, i) {
      if (i < 3) return rng.pick([{ r: 12742, name: "2 Earth radii" }, { r: 19113, name: "3 Earth radii" }]);
      if (rng.next() < 0.5) return rng.pick(RADII);
      return { r: rng.int(70, 450) * 100, name: null };
    },
    show: p => `A clock orbits at **r = ${group(p.r)} km** from Earth's center${p.name ? ` (${p.name})` : ""}. Earth's radius is R = 6371 km.`,
    steps(p) {
      const q = R_KM / p.r, gain = gravityGainUs(p.r);
      return [
        numStep("q", "R/r", q, 4, { hint: `6371 / ${group(p.r)}.`,
          slips: [slip("flipped", p.r / R_KM, "R/r is Earth's radius over the orbit's: under 1."), slip("r as altitude", R_KM / (p.r + R_KM), "r is measured from Earth's center: 6371 + altitude.")] }),
        numStep("one", "1 − R/r", 1 - q, 4, { hint: `1 − ${group(q, 4)}.`,
          slips: [slip("1/r − 1/R", q - 1, "The higher clock runs faster, so the gain is positive: 1/R − 1/r.")] }),
        numStep("gain", "Gain per day", gain, 1, { unit: "μs", hint: `60.1 μs × ${group(1 - q, 4)}.`,
          slips: [
            slip("gh/c²", ((9.81 * (p.r - R_KM) * 1000) / (C * C)) * DAY * 1e6, "g gets weaker with height, so gh overcounts. Use 1 − R/r."),
            slip("1/r − 1/R", -gain, "The higher clock runs faster, so the gain is positive: 1/R − 1/r."),
          ] }),
      ];
    },
    scene: p => ({ scene: "well", props: { r: p.r / R_KM, quiet: true } }),
  },
  oracle: p => [6371 / p.r, 1 - 6371 / p.r, (3.986e14 / 299792458 ** 2) * (1 / 6.371e6 - 1 / (p.r * 1e3)) * 86400e6],
  useIt: {
    say: ["The height half of the build: GPS clocks gain 45.7 μs per day. Save it as `gr_drift`.",
      "Check: for a small height, 1 − R/r ≈ h/R and GM/R² = g, so this is gh/c² again."],
    saves: { name: "gr_drift", value: () => gravityGainUs(26571), unit: "μs per day", note: "a GPS clock's gain from height" },
    scene: { scene: "well", props: { r: 26571 / R_KM } },
  },
  deeper: [
    "Gravity is the downhill slope of the potential: the pull is −∇Φ, of size dΦ/dr = GM/r² (b2-mv-12, the gradient).",
    "The weak-field metric ds² = (1 + 2Φ/c²)c²dt² − (1 − 2Φ/c²)dx² gives this and the speed term at once; the metric g_μν is a symmetric 4 × 4 matrix (b2-la-15).",
    "The Schwarzschild metric, geodesics as straightest paths (a second-order differential equation with Christoffel symbols, b2-de-05), and the Einstein field equations G_μν = (8πG/c⁴)T_μν. The Schwarzschild radius 2GM/c² is 8.87 mm for Earth and 2.95 km for the Sun.",
    "Mercury's extra 43″ of perihelion turn per century, and starlight bent by 1.75″ at the Sun's edge (b2-or-04, orbit shapes).",
  ],
};

interface P12 { r: number; name: string | null; cancel: boolean }
const BUILD_RADII = [
  { r: 6771, name: "the space station" }, { r: 20000, name: null }, { r: 26571, name: "GPS" }, { r: 29600, name: "Galileo" }, { r: 42164, name: "geostationary orbit" },
];

export const re12: B2Lesson<P12> = {
  id: "b2-re-12", track: "re", unit: 4, title: "The build: why GPS needs relativity",
  youCan: "find a satellite clock's net drift from both effects, and the map error it would cause.",
  needs: ["b2-re-09", "b2-re-11", "b2-or-02"],
  tools: ["gps"],
  play: { scene: "gps", props: { r: 26571 / R_KM },
    say: "Drag the satellite's orbit radius from just above the ground to beyond geostationary. The speed bar (slow) shrinks as you go out, the height bar (fast) grows, and the net drift crosses zero once." },
  guess: { scene: "gps", props: { r: 4, hide: true }, kind: "slider", min: 1, max: 7, step: 0.05, start: 4, answer: 1.5, near: 0.15, unit: "Earth radii",
    format: x => x.toFixed(2),
    ask: "Where do the two effects cancel? Slide to the orbit radius you think.",
    revealProps: { r: 1.5 },
    reveal: "1.5 Earth radii, about 9,557 km from Earth's center. Below it the satellite clock runs slow, above it fast." },
  nameIt: {
    say: [
      "In a circular orbit v² = GM/r, so both effects use the same number GM/(c²R). Speed costs half of R/r of it, height gains 1 − R/r of it.",
      "The net is zero at r = 1.5R; below that the satellite clock runs slow, above it fast.",
    ],
    formula: ["speed loss = K × R / (2r)", "height gain = K × (1 − R/r)", "net = K × (1 − 3R / (2r))", "K = GM / (c²R) × 86,400 s = 60.1 μs per day", "map error = net × c"],
  },
  workIt: {
    reference: { r: 26571, name: "GPS", cancel: false },
    generate(rng, i) {
      if (i < 3) return { ...rng.pick([{ r: 26571, name: "GPS" }, { r: 42164, name: "geostationary orbit" }]), cancel: false };
      const pick = rng.next() < 0.5 ? rng.pick(BUILD_RADII) : { r: rng.int(70, 450) * 100, name: null };
      return { ...pick, cancel: true };
    },
    show: p => `A satellite's clock orbits at **r = ${group(p.r)} km** from Earth's center${p.name ? ` (${p.name})` : ""}. K = 60.1 μs per day, R = 6371 km.`,
    steps(p) {
      const loss = speedLossUs(p.r), gain = gravityGainUs(p.r), net = netDriftUs(p.r), map = Math.abs(net) * C_KM_US;
      const ahead = net > 0 ? 0 : 1;
      const steps = [
        numStep("loss", "Speed loss", loss, 1, { unit: "μs per day", hint: `K × R/(2r) = 60.1 × 6371 / (2 × ${group(p.r)}).`,
          slips: [slip("forgot ½", 2 * loss, "In orbit v² = GM/r, and the slowdown is v²/2c²: half of K × R/r.")] }),
        numStep("gain", "Height gain", gain, 1, { unit: "μs per day", hint: `K × (1 − R/r) = 60.1 × (1 − 6371/${group(p.r)}).` }),
        numStep("net", "Net", net, 1, { unit: "μs per day", ask: "Positive if the satellite clock gains.", hint: "Height gain minus speed loss.",
          slips: [
            slip("added", loss + gain, "The speed effect slows the satellite clock and gravity speeds it up, so they pull opposite ways: subtract."),
            slip("backwards", -net, "Net is the height gain minus the speed loss."),
          ] }),
        tapStep("ahead", "Ahead or behind a ground clock?", ["ahead", "behind"], ahead, { hint: "Look at the sign of the net.",
          slips: [slip("sign", 1 - ahead, net > 0 ? "A positive net means the satellite's clock gains: it runs ahead." : "A negative net means the satellite's clock loses: it falls behind.")] }),
        numStep("map", "Map error after one day", map, 1, { unit: "km", hint: `Each μs is 0.2998 km of light travel: ${n1(Math.abs(net))} × 0.2998.`,
          slips: [slip("× 300", Math.abs(net) * 300, `1 μs of light travel is about 0.3 km, so ${n1(Math.abs(net))} μs is ${n1(map)} km.`), slip("μs as km", Math.abs(net), "That's the clock error in μs. Turn it into distance: × 0.2998 km per μs.")] }),
      ];
      if (p.cancel) steps.push(numStep("cancel", "Cancel radius", CANCEL_KM, 0, { unit: "km", ask: "Where would the net be zero? To the nearest km.", hint: "Set R/(2r) = 1 − R/r and solve for r.",
        slips: [slip("1/R = 1/r", R_KM, "Set R/(2r) = 1 − R/r: then 3R/(2r) = 1, so r = 1.5R."), slip("2R", 2 * R_KM, "Set R/(2r) = 1 − R/r: then 3R/(2r) = 1, so r = 1.5R.")] }));
      return steps;
    },
    scene: p => ({ scene: "gps", props: { r: p.r / R_KM, quiet: true } }),
  },
  oracle: p => {
    const K = (3.986e14 / (299792458 ** 2 * 6.371e6)) * 86400e6, R = 6371, net = K * (1 - (1.5 * R) / p.r);
    const out = [(K * R) / (2 * p.r), K * (1 - R / p.r), net, net > 0 ? 0 : 1, Math.abs(net) * 0.299792458];
    if (p.cancel) out.push(1.5 * 6371);
    return out;
  },
  useIt: {
    say: [
      "The build: the GPS checker. The net fraction is 38.5 μs / 86,400 s ≈ 4.46 × 10⁻¹⁰, so GPS clocks are built to tick at 10.23 MHz × (1 − 4.46 × 10⁻¹⁰) ≈ 10.229 999 995 MHz before launch. On orbit they read true.",
      "Save it to keep `gps_net` and put the checker in your Notebook: the track's build.",
    ],
    project: "re-gps",
  },
  deeper: [
    "The real factory setting, 4.4647 × 10⁻¹⁰, also folds in Earth's spin and shape.",
    "Orbits aren't perfect circles: receivers add (2/c²)√(GMa) e sin E, up to 23 ns when e = 0.01 (b2-or-05, Kepler's equation). The Sagnac correction handles signals crossing a spinning Earth.",
    "A clock error grows into a position error through the geometry of the satellites (dilution of precision): a fix is a least-squares solve, and its precision is read off (AᵀA)⁻¹ (b2-la-11, b2-pr-03).",
    "The metric view: dτ/dt ≈ 1 + Φ/c² − v²/(2c²), one formula for the whole build.",
  ],
};

export const RELATIVITY_LESSONS = [re01, re02, re03, re04, re05, re06, re07, re08, re09, re10, re11, re12];
