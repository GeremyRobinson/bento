// Orbits and spaceflight's 12 lessons, b2-or-01 to b2-or-12, built from curriculum/specs/bento2/orbits.md block by block.
import type { B2Lesson, B2Step, SceneRef } from "../../model";
import { fracStep, multiStep, numStep, slip, tapStep, wholeStep } from "../../make";
import { formatAnswer, group } from "../../steps";
import {
  G0, MU_E, MU_MARS, PLANET_AU, R_KM, R_MARS_KM, SIDEREAL_DAY, bestStepHours, hohmann, marsPlan, period,
  radiusFor, vCirc, vEsc, vVis, windowTo,
} from "./maths";

const fr = (x: number) => formatAnswer(x, "fraction");
const n2 = (x: number) => group(x, 2);
const km = (x: number) => group(x);
const CIRCLE = "Orbits here are treated as circles in one plane.";

/* ------------------------------------------------------------------ unit 1 ------------------------------------------------------------------ */

type P01 = { kind: 0; k: number } | { kind: 1; h: number };
const ALT01 = [400, 2000, 6371, 35786];

export const or01: B2Lesson<P01> = {
  id: "b2-or-01", track: "or", unit: 1, title: "Gravity falls off with distance squared",
  youCan: "find how strong gravity is at any height above a planet.",
  needs: ["g12-vecmag"],
  tools: ["or-sandbox", "units"],
  play: { scene: "or-sandbox", props: { mode: "pull", d: 1.6 },
    say: "Drag the probe away from Earth. Its gravity arrow shrinks, and the readouts give its distance from Earth's center and the pull in m/s². The arrows all around point at the center." },
  guess: { scene: "or-sandbox", props: { mode: "pull", d: 1.5, quiet: true }, kind: "choice", options: ["1/2", "1/4", "1/8"], answer: 1,
    ask: "Double your distance from Earth's center. What fraction of the pull is left?",
    revealProps: { mode: "pull", d: 3, from: 1.5 },
    reveal: "A quarter. The probe moves from 1.5 to 3 Earth radii and its arrow drops from 4.36 to 1.09 m/s²." },
  nameIt: {
    say: [
      "Gravity between two masses gets weaker with the square of the distance between their centers.",
      "At Earth's surface it's 9.81 m/s², so at any distance r you can scale from there.",
    ],
    formula: ["F = GMm / r²", "g(r) = GM / r² = g₀ (R⊕ / r)²", "g₀ = 9.81 m/s², R⊕ = 6371 km"],
  },
  workIt: {
    reference: { kind: 1, h: 400 },
    generate(rng, i): P01 {
      if (i < 3) return { kind: 0, k: rng.pick([2, 3, 4, 5, 10]) };
      if (rng.next() < 0.3) return { kind: 0, k: rng.int(2, 12) };
      return { kind: 1, h: rng.next() < 0.6 ? rng.pick(ALT01) : rng.int(2, 400) * 100 };
    },
    show: p => p.kind === 0
      ? `A probe moves from one distance to **${p.k} times** that distance from Earth's center. What fraction of the pull is left?`
      : `A probe is **${km(p.h)} km** above Earth's surface. Earth's radius is 6371 km and g₀ = 9.81 m/s².`,
    steps(p): B2Step[] {
      if (p.kind === 0) {
        const k = p.k;
        return [fracStep("f", "Fraction of the pull left", 1 / (k * k), {
          hint: `Square the factor: (1/${k})².`,
          slips: [
            slip("1/k", 1 / k, `Gravity falls with the square of the distance: ${k} times as far is 1/${k * k} of the pull.`),
            slip("1/k³", 1 / k ** 3, `It's the square of the distance, not the cube: (1/${k})² = 1/${k * k}.`),
          ],
        })];
      }
      const r = R_KM + p.h, q = (R_KM / r) ** 2, g = G0 * q;
      const zero = slip("no gravity up there", 0, `The probe still feels ${Math.round(100 * q)}% of the surface pull. Astronauts float because they and the station fall together.`);
      const fromH = slip("used h", G0 * (R_KM / p.h) ** 2, "Distance is measured from Earth's center. Add Earth's radius, 6371 km.");
      return [
        wholeStep("r", "Distance from the center", r, { unit: "km", hint: `6371 + ${km(p.h)}.`,
          slips: [slip("used h", p.h, "Distance is measured from Earth's center. Add Earth's radius, 6371 km.")] }),
        numStep("g", "Gravity there", g, 2, { unit: "m/s²", ask: "To 2 decimal places.", hint: `9.81 × (6371 / ${km(r)})².`,
          slips: [fromH, slip("1/r", G0 * (R_KM / r), "Gravity falls with the square of the distance: square the ratio 6371 / r."), zero] }),
        numStep("pc", "Percent of surface gravity", 100 * q, 0, { unit: "%", ask: "To the nearest whole percent.", hint: `(6371 / ${km(r)})² × 100.`,
          slips: [slip("1/r", (100 * R_KM) / r, "Square the ratio: the pull goes with 1/r²."), zero] }),
      ];
    },
    scene: (p): SceneRef => ({ scene: "or-sandbox", props: p.kind === 0 ? { mode: "pull", d: 1, from: 1, k: p.k, quiet: true } : { mode: "pull", d: 1 + p.h / R_KM, quiet: true } }),
  },
  oracle: p => {
    if (p.kind === 0) return [1 / p.k ** 2];
    const r = 6371 + p.h;
    return [r, 9.81 * (6371 / r) ** 2, 100 * (6371 / r) ** 2];
  },
  useIt: {
    say: ["Space station \"weightlessness\": at 400 km the pull is still 8.69 m/s², 89% of the ground's. Save it as `g_ISS`.",
      "The station and everyone in it are falling all the time. They just keep missing Earth, which the next lesson makes exact."],
    saves: { name: "g_ISS", value: () => G0 * (R_KM / (R_KM + 400)) ** 2, unit: "m/s²", note: "the pull at the space station, 400 km up" },
    scene: { scene: "or-sandbox", props: { mode: "pull", d: 1 + 400 / R_KM } },
  },
  deeper: [
    "The shell theorem: a ball of mass pulls like a point at its center. Cut the ball into thin rings and add up each ring's pull (b2-mv-07, rings and wedges). Gauss's law for gravity says the same thing in one line.",
    "Inside a uniform planet only the mass below you pulls, so g grows in proportion to r, from 0 at the center to g₀ at the surface.",
    "Tides come from the difference in pull across a body. Across a distance d at distance r from a mass M, that difference is about 2GMd/r³.",
  ],
};

type P02 = { kind: 0; k: number } | { kind: 1; h: number };
const ALT02 = [300, 400, 500, 1000, 2000, 20200];

export const or02: B2Lesson<P02> = {
  id: "b2-or-02", track: "or", unit: 1, title: "Falling around: circular orbits",
  youCan: "find the speed of a circular orbit at any height.",
  needs: ["b2-or-01", "g12-chain"],
  tools: ["or-cannon", "or-sandbox"],
  play: { scene: "or-cannon", props: { v: 6.5 },
    say: "Fire Newton's cannon from a mountain with no air and drag the launch speed. The ball lands farther and farther away until, at 7.91 km/s, the ground curves away as fast as it falls and the ball goes all the way around." },
  guess: { scene: "or-sandbox", props: { mode: "pair", k: 4, quiet: true }, kind: "choice", options: ["×4", "×2", "×1/2", "×1/4"], answer: 2,
    ask: "Move a circular orbit out to 4 times the radius. What happens to its speed?",
    revealProps: { mode: "pair", k: 4 },
    reveal: "Half as fast. The outer ship covers 4 times the distance per lap at half the speed, so each lap takes 8 times as long." },
  nameIt: {
    say: [
      "In a circular orbit, gravity supplies exactly the pull needed to keep turning: v²/r = GM/r².",
      "So farther out you move slower.",
    ],
    formula: ["v² / r = GM / r²", "v = √(GM / r)", "μ⊕ = GM⊕ = 3.986 × 10¹⁴ m³/s²"],
  },
  workIt: {
    reference: { kind: 1, h: 300 },
    generate(rng, i): P02 {
      if (i < 3) return { kind: 0, k: rng.pick([4, 9, 16, 25]) };
      if (rng.next() < 0.3) return { kind: 0, k: rng.pick([4, 9, 16, 25]) };
      return { kind: 1, h: rng.next() < 0.6 ? rng.pick(ALT02) : rng.int(2, 360) * 100 };
    },
    show: p => p.kind === 0
      ? `A circular orbit's radius is multiplied by **${p.k}**. By what factor does the speed change? Type it as a fraction.`
      : `A satellite circles **${km(p.h)} km** above Earth. μ⊕ = 3.986 × 10¹⁴ m³/s², R⊕ = 6371 km.`,
    steps(p): B2Step[] {
      if (p.kind === 0) {
        const s = Math.sqrt(p.k);
        return [fracStep("f", "Speed factor", 1 / s, { hint: `v goes with 1/√r: 1/√${p.k}.`,
          slips: [
            slip("1/k", 1 / p.k, `Speed goes with 1/√r. ${p.k} times as far is 1/${s} as fast.`),
            slip("√k", s, "Farther out you move slower, so the factor is less than 1."),
          ] })];
      }
      const r = R_KM + p.h, v = vCirc(MU_E, r * 1000) / 1000;
      return [
        wholeStep("r", "Radius", r, { unit: "km", hint: `6371 + ${km(p.h)}.`,
          slips: [slip("used h", p.h, "The radius is measured from Earth's center: 6371 + h.")] }),
        numStep("v", "Speed", v, 2, { unit: "km/s", ask: "In km/s, to 2 decimal places.", hint: `√(3.986 × 10¹⁴ / ${km(r * 1000)}) m/s, then divide by 1000.`,
          slips: [
            slip("no root", MU_E / (r * 1000) / 1e6, "v² = GM/r, so take the square root at the end."),
            slip("km with m", Math.sqrt(MU_E / r) / 1000, `μ⊕ is in m³/s², so the radius must be in meters: ${km(r)} km is ${km(r * 1000)} m. Then divide by 1000 for km/s.`),
            slip("used h", vCirc(MU_E, p.h * 1000) / 1000, "The radius is measured from Earth's center: 6371 + h."),
          ] }),
      ];
    },
    scene: (p): SceneRef => ({ scene: "or-sandbox", props: p.kind === 0 ? { mode: "pair", k: p.k, quiet: true } : { mode: "pair", k: 1, h: p.h, quiet: true } }),
  },
  oracle: p => (p.kind === 0 ? [1 / Math.sqrt(p.k)] : [6371 + p.h, Math.sqrt(3.986e14 / ((6371 + p.h) * 1000)) / 1000]),
  useIt: {
    say: ["Your parking orbit for the Mars trip is a circle 300 km up. Its speed, 7.73 km/s, is the build's first piece: save it as `v_LEO`.",
      "GPS satellites sit 20,200 km up and move at only 3.87 km/s (b2-re-12 uses them for its clock corrections)."],
    saves: { name: "v_LEO", value: () => vCirc(MU_E, (R_KM + 300) * 1000) / 1000, unit: "km/s", note: "circular speed 300 km above Earth, the parking orbit" },
    scene: { scene: "or-sandbox", props: { mode: "pair", k: 1, h: 300 } },
  },
  deeper: [
    "Where v²/r comes from: differentiate r(t) = r(cos ωt, sin ωt) twice. The velocity is rω(−sin ωt, cos ωt) and the acceleration is −ω²r(cos ωt, sin ωt), pointing at the center with size ω²r = v²/r.",
    "The effective potential adds a centrifugal term h²/(2r²) to −GM/r, and a circular orbit sits at its bottom. Stable circles exist only for forces that weaken more slowly than 1/r³.",
  ],
};

type P03 = { kind: 0; a: number } | { kind: 1; T: number } | { kind: 2; h: number } | { kind: 3 };
const GEO_KM = radiusFor(MU_E, SIDEREAL_DAY) / 1000;

export const or03: B2Lesson<P03> = {
  id: "b2-or-03", track: "or", unit: 1, title: "Period and Kepler's third law",
  youCan: "find an orbit's period from its size, and the size from its period.",
  needs: ["b2-or-02"],
  tools: ["or-kepler", "or-sandbox"],
  play: { scene: "or-kepler", props: { mode: "loglog", a: 2.5 },
    say: "The planets on log-log axes of distance against year length fall on one straight line. Drag in a new planet anywhere on the distance axis and watch where its year lands." },
  guess: { scene: "or-kepler", props: { mode: "loglog", a: 4, hide: true }, kind: "slider", min: 1, max: 20, step: 0.5, start: 12, answer: 8, near: 0.75, unit: "years",
    format: x => x.toFixed(1),
    ask: "A planet 4 AU from the Sun. How many Earth years is its year? Slide the dashed line to your guess.",
    revealProps: { mode: "loglog", a: 4 },
    reveal: "8 years. It lands on the line: 8² = 64 = 4³." },
  nameIt: {
    say: [
      "One lap is the circumference divided by the speed. Bigger orbits are longer and slower, so the period grows faster than the distance.",
      "Around the Sun, in AU and years, the constants cancel.",
    ],
    formula: ["T = 2πr / v = 2π √(r³ / GM)", "around the Sun: T² = a³ (T in years, a in AU)"],
  },
  workIt: {
    reference: { kind: 3 },
    generate(rng, i): P03 {
      if (i < 3) return { kind: 0, a: rng.pick([4, 9, 16]) };
      const k = rng.int(0, 3);
      if (k === 0) return { kind: 0, a: rng.pick([1, 4, 9, 16, 25, 36]) };
      if (k === 1) return { kind: 1, T: rng.pick([8, 27, 64, 125]) };
      if (k === 2) return { kind: 2, h: rng.next() < 0.5 ? rng.pick([300, 400, 2000]) : rng.int(2, 100) * 100 };
      return { kind: 3 };
    },
    show: p => p.kind === 0 ? `A planet circles the Sun at **${p.a} AU**. How long is its year?`
      : p.kind === 1 ? `A planet's year is **${p.T} Earth years**. How far is it from the Sun?`
        : p.kind === 2 ? `A satellite circles **${km(p.h)} km** above Earth. μ⊕ = 3.986 × 10¹⁴ m³/s², R⊕ = 6371 km.`
          : "Put a satellite where it hovers over one spot on the equator: a geostationary orbit. μ⊕ = 3.986 × 10¹⁴ m³/s².",
    steps(p): B2Step[] {
      if (p.kind === 0) {
        const T = p.a ** 1.5;
        return [wholeStep("T", "Period", T, { unit: "years", hint: `T² = a³ = ${p.a ** 3}, so T = √${p.a ** 3}.`,
          slips: [Number.isInteger(p.a ** 2) && slip("squared a", p.a * p.a, "Square the period, cube the distance: T² = a³.")] })];
      }
      if (p.kind === 1) {
        const a = Math.round(p.T ** (2 / 3));
        return [wholeStep("a", "Distance", a, { unit: "AU", hint: `a³ = T² = ${p.T * p.T}, so a is its cube root.`,
          slips: [
            slip("forgot to square", Math.round(Math.cbrt(p.T)), `Square the period first: a³ = T² = ${p.T * p.T}.`),
            Number.isInteger(p.T ** 1.5) && slip("cubed T", p.T ** 1.5, "Square the period, cube the distance: T² = a³."),
          ] })];
      }
      if (p.kind === 2) {
        const r = R_KM + p.h, T = period(MU_E, r * 1000) / 60;
        return [
          wholeStep("r", "Radius", r, { unit: "km", hint: `6371 + ${km(p.h)}.`,
            slips: [slip("used h", p.h, "The orbit's radius is measured from Earth's center: 6371 + h.")] }),
          numStep("T", "Period", T, 1, { unit: "minutes", ask: "In minutes, to 1 decimal place.", hint: `2π √(r³ / μ⊕) with r in meters, then divide by 60.`,
            slips: [
              slip("used h", period(MU_E, p.h * 1000) / 60, "The orbit's radius is measured from Earth's center: 6371 + h."),
              slip("seconds", T * 60, `That's in seconds. Divide by 60: ${group(T, 1)} minutes.`),
            ] }),
        ];
      }
      const r = GEO_KM;
      return [
        tapStep("day", "Period to match", ["86,400 s (a solar day)", "86,164 s (a sidereal day)"], 1, { hint: "Earth turns once relative to the stars in a sidereal day.",
          slips: [slip("solar day", 0, "A geostationary satellite keeps up with Earth's turn relative to the stars, which takes 23 h 56 min 4 s = 86,164 s. Using 24 h puts it at about 42,241 km, slowly drifting.")] }),
        numStep("r", "Radius", r, 0, { unit: "km", ask: "r = (μ⊕T² / 4π²)^(1/3), to the nearest km.", hint: "3.986 × 10¹⁴ × 86,164² / (4π²), then the cube root, then divide by 1000.",
          slips: [
            slip("solar day", radiusFor(MU_E, 86400) / 1000, "A geostationary satellite keeps up with Earth's turn relative to the stars, which takes 23 h 56 min 4 s = 86,164 s. Using 24 h puts it at about 42,241 km, slowly drifting."),
            slip("altitude", r - R_KM, "That's the height above the ground. The radius is measured from Earth's center."),
          ] }),
      ];
    },
    scene: (p): SceneRef => p.kind <= 1 ? { scene: "or-kepler", props: { mode: "loglog", a: p.kind === 0 ? p.a : p.kind === 1 ? Math.round(p.T ** (2 / 3)) : 1, hide: true } }
      : { scene: "or-satellite", props: { h: p.kind === 2 ? p.h : GEO_KM - R_KM, quiet: true } },
  },
  oracle: p => p.kind === 0 ? [p.a ** 1.5] : p.kind === 1 ? [p.T ** (2 / 3)]
    : p.kind === 2 ? [6371 + p.h, (2 * Math.PI * Math.sqrt(((6371 + p.h) * 1000) ** 3 / 3.986e14)) / 60]
      : [1, Math.cbrt((3.986e14 * 86164 ** 2) / (4 * Math.PI ** 2)) / 1000],
  useIt: {
    say: ["Project: pick a satellite. Choose a job (a space station, a GPS satellite, or a weather satellite that hovers over one spot) and an altitude.",
      "The card gives its radius, speed and period, and checks the job. Save it to keep `r_sat`, `v_sat` and `T_sat`."],
    project: "or-satellite",
  },
  deeper: [
    "With two real masses both bodies circle their shared center, and T² = 4π²a³/(G(M + m)). The reduced mass mM/(M + m) turns it back into a one-body problem.",
    "Weighing Jupiter: Io circles it at 421,700 km every 1.769 days, so GM = 4π²a³/T² ≈ 1.27 × 10¹⁷ m³/s², about 318 Earths.",
    "Fitting a straight line to the planets' log a and log T gives a slope of 3/2 (b2-mv-17, the least-squares line).",
  ],
};

/* ------------------------------------------------------------------ unit 2 ------------------------------------------------------------------ */

interface P04 { c: number; b: number; a: number; unit: "AU" | "thousand km" }
const TRIPLES04: [number, number, number][] = [[3, 4, 5], [6, 8, 10], [8, 6, 10], [5, 12, 13], [9, 12, 15], [15, 8, 17], [7, 24, 25]];

export const or04: B2Lesson<P04> = {
  id: "b2-or-04", track: "or", unit: 2, title: "Orbit shapes: ellipses and beyond",
  youCan: "find an orbit's size, eccentricity and width from its closest and farthest distances.",
  needs: ["b2-or-03", "g12-rad"],
  tools: ["or-sandbox", "graph2d"],
  play: { scene: "or-sandbox", props: { mode: "launch", speed: 1.15 },
    say: "Launch sideways from a fixed point and drag the speed. Exactly circular speed gives a circle. A bit faster stretches it into an ellipse with the planet at one focus, then a parabola, then a hyperbola that never comes back." },
  guess: { scene: "or-sandbox", props: { mode: "launch", speed: 1.1, hide: true }, kind: "slider", min: 1, max: 3, step: 0.05, start: 2.2, answer: 1.21 / 0.79, near: 0.12, unit: "× the start distance",
    format: x => x.toFixed(2),
    ask: "Launch 10% faster than circular speed. Where is the far point? Slide the dashed mark along the line through the planet.",
    revealProps: { mode: "launch", speed: 1.1 },
    reveal: "The ellipse's far point lands at about 1.53 times the start distance, on the opposite side of the planet." },
  nameIt: {
    say: [
      "Every orbit is a conic with the planet at a focus. Its size is the semimajor axis a, the average of the nearest and farthest distances, and its stretch is the eccentricity e.",
      "e = 0 is a circle, e < 1 an ellipse, e = 1 a parabola, and e > 1 a hyperbola.",
    ],
    formula: ["r_near = a(1 − e), r_far = a(1 + e)", "c = ae, b = √(a² − c²)", "r = a(1 − e²) / (1 + e cos θ)"],
  },
  workIt: {
    reference: { c: 3, b: 4, a: 5, unit: "AU" },
    generate(rng, i) {
      if (i < 3) { const [c, b, a] = i === 1 ? TRIPLES04[2]! : TRIPLES04[0]!; return { c, b, a, unit: "AU" }; }
      const [c, b, a] = rng.pick(TRIPLES04), m = rng.int(1, 2);
      return { c: c * m, b: b * m, a: a * m, unit: rng.next() < 0.5 ? "AU" : "thousand km" };
    },
    show: p => `An orbit comes as close as **${p.a - p.c} ${p.unit}** to the body at its focus and goes out to **${p.a + p.c} ${p.unit}**.`,
    steps(p) {
      const rn = p.a - p.c, rf = p.a + p.c;
      return [
        wholeStep("a", "a", p.a, { unit: p.unit, ask: "The semimajor axis.", hint: `The average of the two: (${rn} + ${rf}) / 2.`,
          slips: [slip("far point", rf, "a is the average of the nearest and farthest distances, not the far one."), slip("half the difference", p.c, "a is the average: add the two distances, then halve.")] }),
        wholeStep("c", "c", p.c, { unit: p.unit, ask: "The distance from the center to the focus.", hint: `a − r_near = ${p.a} − ${rn}.`,
          slips: [slip("planet at center", 0, "The planet sits at a focus, c away from the center. That's why there's a near side and a far side."), slip("r_near", rn, "c is how far the focus is from the center: a − r_near.")] }),
        fracStep("e", "e", p.c / p.a, { ask: "As a fraction.", hint: `e = c / a = ${p.c}/${p.a}.`,
          slips: [slip("near over far", rn / rf, "Eccentricity is c/a, or (r_far − r_near)/(r_far + r_near)."), slip("a over c", p.a / p.c, "e = c/a. An ellipse has e below 1.")] }),
        wholeStep("b", "b", p.b, { unit: p.unit, ask: "The semiminor axis, half the width.", hint: `b² = a² − c² = ${p.a * p.a} − ${p.c * p.c}.`,
          slips: [slip("a − c", p.a - p.c, "b comes from a right triangle: b² = a² − c²."), slip("no root", p.b * p.b, `Take the square root: √${p.b * p.b}.`)] }),
      ];
    },
    scene: (p): SceneRef => ({ scene: "or-sandbox", props: { mode: "launch", speed: Math.sqrt((2 * (p.a + p.c)) / (2 * p.a)), quiet: true } }),
  },
  oracle: p => { const r1 = p.a - p.c, r2 = p.a + p.c, a = (r1 + r2) / 2, c = (r2 - r1) / 2; return [a, c, c / a, Math.sqrt(a * a - c * c)]; },
  useIt: {
    say: ["Halley's Comet comes to 0.586 AU from the Sun and goes out to 35.1 AU. Its a is 17.8 AU: save it as `halley_a`.",
      "Its e is 17.257/17.843 = 0.967 to 3 places, and Kepler's law with the unrounded a gives its period: √(17.843³) = 75.4 years."],
    saves: { name: "halley_a", value: () => (0.586 + 35.1) / 2, unit: "AU", note: "Halley's Comet's semimajor axis" },
    scene: { scene: "or-comet", props: { near: 0.586, far: 35.1 } },
  },
  deeper: [
    "Deriving the conic from Newton: with u = 1/r, Binet's equation u″ + u = GM/h² is a forced linear oscillator (b2-de-09, springs), and its solution is the polar conic.",
    "The Laplace–Runge–Lenz vector is a hidden conserved arrow that points at the near point and keeps the ellipse from turning. Bertrand's theorem: only 1/r² and spring forces give closed orbits for every bound start.",
    "Mercury's slowly turning ellipse is one of relativity's first tests (b2-re-11, the full gravity shift).",
  ],
};

type P05 = { kind: 0; rn: number; k: number; vn: number } | { kind: 1; body: string; rn: number; rf: number; vn: number } | { kind: 2; en: number; ed: number };
const BODIES05 = [
  { body: "Earth", rn: 0.9833, rf: 1.0167, vn: 30.29 },
  { body: "Mars", rn: 1.3814, rf: 1.666, vn: 26.5 },
  { body: "Halley's Comet", rn: 0.586, rf: 35.1, vn: 54.55 },
];
const ECC05: [number, number][] = [[1, 5], [1, 3], [1, 2], [3, 5]];

export const or05: B2Lesson<P05> = {
  id: "b2-or-05", track: "or", unit: 2, title: "Equal areas: fast near, slow far",
  youCan: "find an orbiting body's speed at one end of its orbit from the other.",
  needs: ["b2-or-04"],
  tools: ["or-kepler", "or-sandbox"],
  play: { scene: "or-kepler", props: { mode: "areas", e: 0.5 },
    say: "The checker shades the wedge swept in each equal stretch of time. Drag the eccentricity: near the Sun the wedges are short and fat, far away long and thin, and their areas stay equal." },
  guess: { scene: "or-kepler", props: { mode: "areas", e: 0.5, quiet: true }, kind: "choice", options: ["√3", "3", "9"], answer: 1,
    ask: "A planet is 3 times farther away at its far point than at its near point. How many times faster is it at the near point?",
    revealProps: { mode: "areas", e: 0.5, arrows: true },
    reveal: "3 times. At both ends the motion is all sideways, and the distance times the speed is the same: 1 × 3 = 3 × 1." },
  nameIt: {
    say: [
      "Equal areas in equal times means the distance times the sideways speed never changes: that's angular momentum.",
      "At the near and far points the motion is all sideways.",
    ],
    formula: ["h = r v⊥ stays the same", "r_near v_near = r_far v_far", "v_near / v_far = r_far / r_near = (1 + e) / (1 − e)"],
  },
  workIt: {
    reference: { kind: 0, rn: 2, k: 3, vn: 30 },
    generate(rng, i): P05 {
      const k0 = (): P05 => { const k = rng.int(2, 6), rn = rng.int(1, 3); return { kind: 0, rn, k, vn: k * rng.int(Math.ceil(6 / k), Math.floor(60 / k)) }; };
      if (i < 3) return k0();
      const r = rng.next();
      if (r < 0.4) return k0();
      if (r < 0.7) return { kind: 1, ...rng.pick(BODIES05) };
      const [en, ed] = rng.pick(ECC05);
      return { kind: 2, en, ed };
    },
    show: p => p.kind === 0 ? `A planet's near point is **${p.rn} AU** from the Sun and its far point **${p.rn * p.k} AU**. At the near point it moves at **${p.vn} km/s**.`
      : p.kind === 1 ? `${p.body}'s near point is **${p.rn} AU** from the Sun, where it moves at **${p.vn} km/s**. Its far point is **${p.rf} AU** away.`
        : `An orbit has eccentricity **e = ${p.en}/${p.ed}**. How many times faster is it at the near point than at the far point? Type a fraction.`,
    steps(p): B2Step[] {
      if (p.kind === 2) {
        const e = p.en / p.ed;
        return [fracStep("ratio", "v_near / v_far", (1 + e) / (1 - e), { hint: `(1 + e)/(1 − e) = (1 + ${p.en}/${p.ed}) / (1 − ${p.en}/${p.ed}).`,
          slips: [slip("flipped", (1 - e) / (1 + e), "The near speed is the bigger one, so the ratio is (1 + e)/(1 − e)."), slip("1 + e", 1 + e, "Divide by 1 − e as well: (1 + e)/(1 − e).")] })];
      }
      const rn = p.rn, rf = p.kind === 0 ? p.rn * p.k : p.rf, vf = (p.vn * rn) / rf;
      const msg = "Farther means slower. v_far = v_near × r_near / r_far.";
      if (p.kind === 0) {
        return [wholeStep("vf", "v_far", vf, { unit: "km/s", hint: `${rn} × ${p.vn} = ${rf} × v_far.`,
          slips: [
            slip("multiplied", p.vn * p.k, msg),
            Number.isInteger(p.vn / Math.sqrt(p.k)) && slip("used squares", p.vn / Math.sqrt(p.k), "It's r times v that stays fixed, not r times v²."),
            Number.isInteger(p.vn / (p.k * p.k)) && slip("r²", p.vn / (p.k * p.k), "It's r times v that stays fixed, not r² times v."),
          ] })];
      }
      return [numStep("vf", "v_far", vf, 2, { unit: "km/s", ask: "To 2 decimal places.", hint: `${p.vn} × ${p.rn} / ${p.rf}.`,
        slips: [slip("multiplied", (p.vn * rf) / rn, msg), slip("used squares", p.vn * Math.sqrt(rn / rf), "It's r times v that stays fixed, not r times v².")] })];
    },
    scene: (p): SceneRef => {
      const e = p.kind === 2 ? p.en / p.ed : p.kind === 0 ? (p.k - 1) / (p.k + 1) : (p.rf - p.rn) / (p.rf + p.rn);
      return { scene: "or-kepler", props: { mode: "areas", e, quiet: true } };
    },
  },
  oracle: p => p.kind === 2 ? [(1 + p.en / p.ed) / (1 - p.en / p.ed)] : [(p.vn * p.rn) / (p.kind === 0 ? p.rn * p.k : p.rf)],
  useIt: {
    say: ["The Mars transfer ellipse touches 1 AU and 1.524 AU. So the ship leaving Earth is 1.524 times as fast as it is arriving at Mars.",
      "Save that ratio as `vratio_mars`: the transfer's two ends, in one number."],
    saves: { name: "vratio_mars", value: () => PLANET_AU.Mars, note: "the Mars transfer: speed leaving Earth over speed arriving at Mars" },
    scene: { scene: "or-kepler", props: { mode: "areas", e: 0.524 / 2.524, arrows: true } },
  },
  deeper: [
    "In the plane, r × v is the determinant of the matrix with columns r and v, the signed area they span (b2-la-07). The area swept per unit time is ½|r × v|. For any central force r × F = 0, because the force points along r, so that area rate never changes.",
    "Timing along an ellipse: Kepler's equation M = E − e sin E has no closed-form solution. Newton's method solves it in a few steps: E ← E − (E − e sin E − M)/(1 − e cos E), starting from E = M (b2-mv-19 is the same idea, for minimums).",
  ],
};

type P06 = { kind: 0; mu: number; r: number; v: number } | { kind: 1; where: 0 | 1 | 2 } | { kind: 2; rn: number; rf: number };
const ESC = [
  { name: "Earth's surface", mu: MU_E, r: R_KM, body: "μ⊕ = 3.986 × 10¹⁴ m³/s²" },
  { name: "the 300 km parking orbit (r = 6671 km)", mu: MU_E, r: R_KM + 300, body: "μ⊕ = 3.986 × 10¹⁴ m³/s²" },
  { name: "Mars's surface (r = 3390 km)", mu: MU_MARS, r: R_MARS_KM, body: "μ♂ = 4.283 × 10¹³ m³/s²" },
];
const TYPES = ["Ellipse", "Circle", "Escapes"];
const typeOf = (mu: number, r: number, v: number) => (v * v * r === mu ? 1 : v * v / 2 - mu / r < 0 ? 0 : 2);

export const or06: B2Lesson<P06> = {
  id: "b2-or-06", track: "or", unit: 2, title: "Energy, vis-viva and escape",
  youCan: "find an orbiting body's speed anywhere on its orbit, and the speed it needs to escape.",
  needs: ["b2-or-05", "g12-defint"],
  tools: ["or-sandbox", "units"],
  play: { scene: "or-sandbox", props: { mode: "launch", speed: 1.2, energy: true },
    say: "An energy bar sits next to the ship: kinetic energy up, potential energy down. Drag the launch speed. While the total is negative the orbit closes. At exactly zero it becomes a parabola and the ship escapes." },
  guess: { scene: "or-sandbox", props: { mode: "launch", speed: 1, energy: true, quiet: true }, kind: "choice", options: ["1.5", "√2", "2"], answer: 1,
    ask: "Escape speed is how many times circular speed at the same spot?",
    revealProps: { mode: "launch", speed: Math.SQRT2, energy: true, sweep: true },
    reveal: "√2, about 1.41. The speed slides up from the circle until the total energy reaches zero, and there the orbit opens into a parabola." },
  nameIt: {
    say: [
      "An orbit's energy per kilogram depends only on its size. Combining that with the speed at one point gives the speed everywhere: the vis-viva equation.",
      "Zero energy is the line between staying and leaving.",
    ],
    formula: ["ε = v²/2 − GM/r = −GM / (2a)", "v² = GM (2/r − 1/a)", "v_esc = √(2GM / r) = √2 × v_circ"],
  },
  workIt: {
    reference: { kind: 2, rn: 7000, rf: 42000 },
    generate(rng, i): P06 {
      if (i < 3) return { kind: 0, mu: 8, r: 2, v: rng.int(1, 3) };
      const k = rng.int(0, 2);
      if (k === 0) { const [mu, r] = rng.pick([[8, 2], [8, 4], [18, 2]] as [number, number][]); return { kind: 0, mu, r, v: rng.int(1, mu === 18 ? 5 : 3) }; }
      if (k === 1) return { kind: 1, where: rng.int(0, 2) as 0 | 1 | 2 };
      return { kind: 2, rn: rng.pick([6700, 7000, 8000]), rf: rng.pick([20000, 42000]) };
    },
    show: p => p.kind === 0 ? `A toy planet has **μ = ${p.mu}**. A ship at **r = ${p.r}** moves sideways at **v = ${p.v}**.`
      : p.kind === 1 ? `Find the escape speed from ${ESC[p.where]!.name}. ${ESC[p.where]!.body}.`
        : `A satellite's orbit comes to **${km(p.rn)} km** from Earth's center and goes out to **${km(p.rf)} km**. μ⊕ = 3.986 × 10¹⁴ m³/s².`,
    steps(p): B2Step[] {
      if (p.kind === 0) {
        const eps = (p.v * p.v) / 2 - p.mu / p.r, t = typeOf(p.mu, p.r, p.v);
        const steps = [
          numStep("eps", "Energy", eps, 1, { ask: "ε = v²/2 − μ/r, to 1 decimal place.", hint: `${p.v * p.v}/2 − ${p.mu}/${p.r}.`,
            slips: [
              slip("no minus", (p.v * p.v) / 2 + p.mu / p.r, "Potential energy is −μ/r. A bound orbit has negative total energy."),
              slip("v² not v²/2", p.v * p.v - p.mu / p.r, "Kinetic energy per kilogram is v²/2."),
            ] }),
          tapStep("type", "Type", TYPES, t, { hint: "Negative energy stays; zero or more escapes. A circle needs v² = μ/r exactly.",
            slips: [
              t !== 0 && slip("ellipse", 0, eps === 0 ? "Zero energy means a parabola. The ship just barely never comes back." : eps > 0 ? "The energy is positive, so the orbit never closes." : "v² = μ/r here, which is exactly circular speed."),
              t !== 1 && slip("circle", 1, `A circle needs v² = μ/r = ${fr(p.mu / p.r)} exactly. Here v² = ${p.v * p.v}.`),
              t !== 2 && slip("escapes", 2, "The energy is negative, so the ship can't get away. The orbit closes."),
            ] }),
        ];
        if (eps < 0) steps.push(fracStep("a", "a", -p.mu / (2 * eps), { ask: "a = −μ / (2ε), as a fraction.", hint: `−${p.mu} / (2 × ${group(eps, 1)}).`,
          slips: [slip("sign", p.mu / (2 * eps), "a = −μ/(2ε): a bound orbit has negative energy, so a comes out positive."), slip("no 2", -p.mu / eps, "Divide by 2ε, not ε.")] }));
        return steps;
      }
      if (p.kind === 1) {
        const w = ESC[p.where]!, ve = vEsc(w.mu, w.r * 1000) / 1000, vc = vCirc(w.mu, w.r * 1000) / 1000;
        return [numStep("vesc", "Escape speed", ve, 2, { unit: "km/s", ask: "v_esc = √(2μ/r), in km/s to 2 decimal places.", hint: `√(2 × μ / ${km(w.r * 1000)}) m/s, then divide by 1000.`,
          slips: [
            slip("2 × v_circ", 2 * vc, "Escape needs twice the kinetic energy of a circular orbit, so √2 times the speed."),
            slip("v_circ", vc, "That's circular speed. Escape is √2 times that."),
          ] })];
      }
      const a = (p.rn + p.rf) / 2, vn = vVis(MU_E, p.rn * 1000, a * 1000) / 1000, vf = vVis(MU_E, p.rf * 1000, a * 1000) / 1000;
      const visMsg = "Vis-viva has 2/r: v² = GM(2/r − 1/a).";
      return [
        wholeStep("a", "a", a, { unit: "km", hint: `(${km(p.rn)} + ${km(p.rf)}) / 2.`, slips: [slip("half the difference", (p.rf - p.rn) / 2, "a is the average: add the two distances, then halve.")] }),
        numStep("vn", "Speed at the near point", vn, 2, { unit: "km/s", ask: "To 2 decimal places.", hint: `√(μ⊕ (2/${km(p.rn * 1000)} − 1/${km(a * 1000)})) m/s.`,
          slips: [
            slip("1/r − 1/a", Math.sqrt(MU_E * (1 / (p.rn * 1000) - 1 / (a * 1000))) / 1000, visMsg),
            slip("circle speed", vCirc(MU_E, p.rn * 1000) / 1000, "That's the circle's speed at this distance. On the ellipse, use vis-viva: v² = GM(2/r − 1/a)."),
          ] }),
        numStep("vf", "Speed at the far point", vf, 2, { unit: "km/s", ask: "To 2 decimal places.", hint: `√(μ⊕ (2/${km(p.rf * 1000)} − 1/${km(a * 1000)})) m/s.`,
          slips: [
            slip("1/r − 1/a", Math.sqrt(MU_E * (1 / (p.rf * 1000) - 1 / (a * 1000))) / 1000, visMsg),
            slip("circle speed", vCirc(MU_E, p.rf * 1000) / 1000, "That's the circle's speed at this distance. On the ellipse, use vis-viva: v² = GM(2/r − 1/a)."),
          ] }),
      ];
    },
    scene: (p): SceneRef => p.kind === 0 ? { scene: "or-sandbox", props: { mode: "launch", speed: p.v / Math.sqrt(p.mu / p.r), energy: true, quiet: true } }
      : p.kind === 1 ? { scene: "or-sandbox", props: { mode: "launch", speed: Math.SQRT2, energy: true, quiet: true } }
        : { scene: "or-sandbox", props: { mode: "launch", speed: Math.sqrt((2 * p.rf) / (p.rn + p.rf)), quiet: true } },
  },
  oracle: p => {
    if (p.kind === 0) {
      const e = p.v ** 2 / 2 - p.mu / p.r, t = Math.abs(p.v ** 2 - p.mu / p.r) < 1e-12 ? 1 : e < 0 ? 0 : 2;
      return e < 0 ? [e, t, -p.mu / (2 * e)] : [e, t];
    }
    if (p.kind === 1) { const [mu, r] = [[3.986e14, 6371e3], [3.986e14, 6671e3], [4.283e13, 3390e3]][p.where]!; return [Math.sqrt((2 * mu!) / r!) / 1000]; }
    const a = ((p.rn + p.rf) / 2) * 1000, v = (r: number) => Math.sqrt(3.986e14 * (2 / r - 1 / a)) / 1000;
    return [a / 1000, v(p.rn * 1000), v(p.rf * 1000)];
  },
  useIt: {
    say: ["Project: the comet card. Type a comet's closest and farthest distances from the Sun (Halley is the preset). The card draws the ellipse and gives a, e, the period and the speeds at both ends.",
      "Check it: the vis-viva speeds at the two ends and the equal-areas rule from b2-or-05 agree, since v_near × r_near = v_far × r_far."],
    project: "or-comet",
  },
  deeper: [
    "Vis-viva from two conserved things: energy v²/2 − GM/r and angular momentum r v⊥. At the near and far points v⊥ = v, and solving the pair gives ε = −GM/(2a).",
    "Above escape, the leftover speed far away is v∞, with v∞² = v² − v_esc² (used in b2-or-11). Launch providers quote C3 = v∞².",
    "The Oberth effect: a burn adds the most energy where you're already moving fastest, since the change in v²/2 is about v Δv.",
  ],
};

/* ------------------------------------------------------------------ unit 3 ------------------------------------------------------------------ */

interface P07 { hd: number }

export const or07: B2Lesson<P07> = {
  id: "b2-or-07", track: "or", unit: 3, title: "Orbits as a differential equation",
  youCan: "take one step of an orbit simulation by hand and explain why a simple stepper spirals out while symplectic Euler stays put.",
  needs: ["b2-or-06", "b2-de-03", "b2-de-05"],
  tools: ["or-sandbox"],
  play: { scene: "or-sandbox", props: { mode: "integrator", method: "euler", hstep: 0.1 },
    say: "A circular orbit run step by step with Euler. Drag the step size: the ship spirals out, faster with bigger steps. Flip to symplectic Euler and the same step gives a closed loop. The energy graph below shows why." },
  guess: { scene: "or-sandbox", props: { mode: "integrator", method: "euler", hstep: 0.05, quiet: true }, kind: "choice", options: ["Farther out", "Closer in", "On the same circle"], answer: 0,
    ask: "Euler, 100 orbits, a step of 0.05. Will the ship end up farther out, closer in, or on the same circle?",
    revealProps: { mode: "integrator", method: "euler", hstep: 0.05, run: true },
    reveal: "Farther out. Every Euler step adds a little energy, so the circle opens into an outward spiral and the ship flies off." },
  nameIt: {
    say: [
      "Newton's law r″ = −GM r/|r|³ is a system of four numbers: position and velocity.",
      "Euler moves with the old velocity and gains energy every step. Symplectic Euler kicks first, then drifts with the new velocity, which keeps the energy from drifting.",
    ],
    formula: ["Euler: r_new = r + h v, v_new = v + h a(r)", "Symplectic Euler: v_new = v + h a(r), r_new = r + h v_new", "a(r) = −μ r / |r|³"],
  },
  workIt: {
    reference: { hd: 2 },
    generate(rng, i) { return { hd: i < 3 ? (i === 0 ? 2 : rng.pick([2, 4])) : rng.pick([2, 4, 5, 10]) }; },
    show: p => `Toy units: **μ = 1**, start at **r = (1, 0)** with **v = (0, 1)**, a circular orbit. Take one step of **h = 1/${p.hd}**.`,
    steps(p) {
      const h = 1 / p.hd, E = (h * h + 1) / 2 - 1 / Math.sqrt(1 + h * h);
      const outward = slip("outward", [1, 0], "Gravity pulls toward the center: a = −r/|r|³, so at (1, 0) it's (−1, 0).");
      return [
        multiStep("a", "Acceleration at the start", [-1, 0], "fraction", { boxes: ["a_x", "a_y"], hint: "a = −r/|r|³ with r = (1, 0).", slips: [outward] }),
        multiStep("re", "Euler position", [1, h], "fraction", { boxes: ["x", "y"], hint: `r + h v = (1, 0) + 1/${p.hd} × (0, 1).`,
          slips: [slip("new velocity", [1 - h * h, h], "Euler moves with the old velocity. Using the new one is symplectic Euler.")] }),
        multiStep("ve", "Euler velocity", [-h, 1], "fraction", { boxes: ["v_x", "v_y"], hint: `v + h a = (0, 1) + 1/${p.hd} × (−1, 0).`,
          slips: [slip("outward", [h, 1], "Gravity pulls toward the center: a = −r/|r|³, so at (1, 0) it's (−1, 0).")] }),
        numStep("E", "Energy after the step", E, 3, { ask: "v²/2 − 1/|r|, to 3 decimal places. It started at −0.5.", hint: `v² = ${fr(h * h)} + 1 and |r| = √(1 + ${fr(h * h)}).`,
          slips: [
            slip("no minus", (h * h + 1) / 2 + 1 / Math.sqrt(1 + h * h), "Potential energy is −μ/r. A bound orbit has negative total energy."),
            slip("v² not v²/2", h * h + 1 - 1 / Math.sqrt(1 + h * h), "Kinetic energy per kilogram is v²/2."),
          ] }),
        tapStep("mean", "What it means", ["Energy rose: drifting out", "Energy fell: drifting in"], 0, { hint: "Compare with −0.5.",
          slips: [slip("fell", 1, `It started at −0.5 and is now ${group(E, 3)}: higher, so the orbit grows.`)] }),
        multiStep("rs", "Symplectic Euler position", [1 - h * h, h], "fraction", { boxes: ["x", "y"], hint: `Kick first: v_new = (−1/${p.hd}, 1). Then drift: r + h v_new.`,
          slips: [slip("Euler again", [1, h], "Symplectic Euler kicks first, then drifts with the new velocity: r + h v_new.")] }),
      ];
    },
    scene: (p): SceneRef => ({ scene: "or-sandbox", props: { mode: "integrator", method: "euler", hstep: 1 / p.hd, quiet: true } }),
  },
  oracle: p => { const h = 1 / p.hd; return [-1, 0, 1, h, -h, 1, (h * h + 1) / 2 - 1 / Math.sqrt(1 + h * h), 0, 1 - h * h, h]; },
  useIt: {
    say: ["Choose your simulator's step: the largest whole number of hours that keeps the Mars transfer's energy within 0.1% over the whole 259-day flight with symplectic Euler.",
      `Try steps in the picture. It's ${bestStepHours()} hours: save it as \`h_step\`. The build's mission clock runs on it.`],
    saves: { name: "h_step", value: () => bestStepHours(), unit: "hours", note: "the largest symplectic Euler step that keeps the Mars transfer within 0.1%" },
    scene: { scene: "or-sandbox", props: { mode: "transfer", hours: 12 } },
  },
  deeper: [
    "Symplectic steppers keep phase-space area: the Jacobian of one step has determinant 1 (b2-mv-08). So they follow a nearby \"shadow\" orbit with nearly the right energy forever.",
    "Symplectic Euler is first order. Leapfrog (velocity Verlet: half kick, drift, half kick) is the second-order version: from the same start, one step lands at (1 − h²/2, h) = (7/8, 1/2) for h = 1/2.",
    "Real codes shrink the step for fast perihelion passes, and N-body simulations meet chaos in the three-body problem (b2-de-15).",
  ],
};

type P08 = { kind: 0; ve: number; n: number; e: 0 | 1 | 2 } | { kind: 1; isp: number; dv: number };
const ratioOf = (p: { n: number; e: 0 | 1 | 2 }) => (p.e ? Math.E ** p.e : p.n);

export const or08: B2Lesson<P08> = {
  id: "b2-or-08", track: "or", unit: 3, title: "The rocket equation",
  youCan: "find how much speed change a rocket can make from its engine and its fuel, and how much fuel a trip needs.",
  needs: ["b2-or-06", "g11-log"],
  tools: ["or-stack", "units"],
  play: { scene: "or-stack", props: { prop: 4, isp: 450 },
    say: "A dry ship on top of a propellant bar. Drag the propellant up: the Δv climbs, but each added tonne buys less than the one before. Swap engines and the whole curve stretches." },
  guess: { scene: "or-stack", props: { prop: 2, isp: 450, quiet: true }, kind: "choice", options: ["Doubles", "Less than double", "More than double"], answer: 1,
    ask: "A 1-tonne ship with 2 tonnes of propellant. Double the propellant to 4 tonnes. What happens to Δv?",
    revealProps: { prop: 2, isp: 450, compare: 4 },
    reveal: "Less than double: about 1.46 times. The mass ratio goes from 3 to 5, and ln 5 / ln 3 = 1.46." },
  nameIt: {
    say: [
      "A rocket pushes itself by throwing mass backward at the exhaust speed.",
      "The speed it gains depends on the log of how much lighter it gets, which is why spaceflight is hard.",
    ],
    formula: ["Δv = v_e ln(m_full / m_empty)", "v_e = I_sp g₀", "propellant fraction = 1 − m_empty / m_full = 1 − e^(−Δv / v_e)"],
  },
  workIt: {
    reference: { kind: 1, isp: 450, dv: 3.59 },
    generate(rng, i): P08 {
      if (i < 3) return rng.pick([{ kind: 0, ve: 3, n: 0, e: 2 }, { kind: 0, ve: 3, n: 4, e: 0 }, { kind: 0, ve: 2.5, n: 5, e: 0 }] as P08[]);
      if (rng.next() < 0.35) return { kind: 0, ve: rng.pick([2.5, 3, 3.5, 4.5]), n: rng.int(2, 9), e: rng.next() < 0.25 ? (rng.int(1, 2) as 1 | 2) : 0 };
      return { kind: 1, isp: rng.pick([300, 350, 450]), dv: rng.next() < 0.5 ? rng.pick([3.59, 5.67]) : rng.int(25, 70) / 10 };
    },
    show: p => p.kind === 0
      ? `An engine's exhaust speed is **${p.ve} km/s** and the full rocket is **${p.e === 1 ? "e" : p.e === 2 ? "e²" : p.n} times** as heavy as the empty one.`
      : `An engine has **I_sp = ${p.isp} s** and the trip needs **Δv = ${n2(p.dv)} km/s**. g₀ = 9.81 m/s².`,
    steps(p): B2Step[] {
      if (p.kind === 0) {
        const ratio = ratioOf(p), dv = p.ve * Math.log(ratio);
        return [numStep("dv", "Δv", dv, 2, { unit: "km/s", ask: "To 2 decimal places.", hint: p.e ? `ln(e${p.e === 2 ? "²" : ""}) = ${p.e}, so Δv = ${p.ve} × ${p.e}.` : `${p.ve} × ln ${p.n}.`,
          slips: [
            slip("log base 10", p.ve * Math.log10(ratio), "The rocket equation uses the natural log, ln."),
            slip("flipped", -dv, "It's full over empty, which is bigger than 1. Otherwise the log is negative."),
            slip("no log", p.ve * ratio, "Δv grows with the log of the mass ratio, not the ratio itself."),
          ] })];
      }
      const ve = (p.isp * G0) / 1000, ratio = Math.exp(p.dv / ve), frac = 100 * (1 - 1 / ratio);
      return [
        numStep("ve", "Exhaust speed", ve, 2, { unit: "km/s", ask: "v_e = I_sp g₀, in km/s to 2 decimal places.", hint: `${p.isp} × 9.81 m/s, then divide by 1000.`,
          slips: [slip("forgot g₀", p.isp / 1000, "Specific impulse is in seconds. Multiply by g₀ = 9.81 m/s² to get an exhaust speed.")] }),
        numStep("ratio", "Mass ratio", ratio, 2, { ask: "m_full / m_empty = e^(Δv / v_e), to 2 decimal places.", hint: `e^(${n2(p.dv)} / ${group(ve, 4)}).`,
          slips: [
            slip("log base 10", 10 ** (p.dv / ve), "The rocket equation uses the natural log, so undo it with e, not 10."),
            slip("flipped", 1 / ratio, "It's full over empty, which is bigger than 1. Otherwise the log is negative."),
          ] }),
        numStep("frac", "Propellant fraction", frac, 1, { unit: "%", ask: "1 − m_empty / m_full, as a percent to 1 decimal place.", hint: `(1 − 1/${n2(ratio)}) × 100.`,
          slips: [slip("empty part", 100 / ratio, "That's the empty part. The propellant is the rest: 1 − m_empty/m_full.")] }),
      ];
    },
    scene: (p): SceneRef => p.kind === 0 ? { scene: "or-stack", props: { prop: ratioOf(p) - 1, ve: p.ve, quiet: true } } : { scene: "or-stack", props: { isp: p.isp, prop: 2, quiet: true } },
  },
  oracle: p => {
    if (p.kind === 0) return [p.ve * Math.log(p.e ? Math.exp(p.e) : p.n)];
    const ve = (p.isp * 9.81) / 1000;
    return [ve, Math.exp(p.dv / ve), 100 * (1 - Math.exp(-p.dv / ve))];
  },
  useIt: {
    say: ["Pick your engine for the Mars trip. A hydrogen–oxygen upper stage has I_sp about 450 s, so v_e = 4.41 km/s.",
      "Save it as `ve`. The geostationary delivery and the mission card both read it."],
    saves: { name: "ve", value: () => (450 * G0) / 1000, unit: "km/s", note: "exhaust speed of a hydrogen–oxygen stage, I_sp 450 s" },
    scene: { scene: "or-stack", props: { prop: 4, isp: 450 } },
  },
  deeper: [
    "Deriving it from momentum: in a short time the rocket throws mass −dm backward at v_e, so m dv = −v_e dm. That's a separable equation (b2-de-02); integrating gives Δv = v_e ln(m₀/m₁).",
    "Staging: dropping empty tanks means you stop pushing dead weight, so two stages beat one big tank. Gravity losses: during a slow climb, part of the thrust only holds the rocket up.",
    "Electric propulsion has I_sp in the thousands of seconds but tiny thrust: it saves propellant and spends months.",
  ],
};

type P09 = { kind: 0; r2: number } | { kind: 1; h1: number; r2: number; name: string };
const TARGETS09 = [{ r2: 42164, name: "geostationary orbit" }, { r2: 26571, name: "a GPS orbit" }];

export const or09: B2Lesson<P09> = {
  id: "b2-or-09", track: "or", unit: 3, title: "The Hohmann transfer",
  youCan: "plan the two burns that move a ship between two circular orbits, and how long the coast takes.",
  needs: ["b2-or-06", "b2-or-08"],
  tools: ["or-burn", "or-sandbox"],
  play: { scene: "or-burn", props: { dv1: 1.2 },
    say: "Two circular orbits around Earth. Drag a forward burn at the inner one: the orbit stretches into an ellipse whose far point grows until it just touches the outer circle. Then add a second burn there to round it off. The Δv ledger adds them up." },
  guess: { scene: "or-burn", props: { dv1: 0, quiet: true }, kind: "choice", options: ["Bigger", "Smaller"], answer: 1,
    ask: "Going from low orbit to one about 6 times as wide: is the second burn bigger or smaller than the first?",
    revealProps: { hohmann: true },
    reveal: "Smaller: 2.43 km/s to leave, then 1.47 km/s to round off. Far out everything moves slowly, so less is needed there." },
  nameIt: {
    say: [
      "The cheapest two-burn route between circles is an ellipse that touches both.",
      "Burn forward at the inner circle to start it, coast half an orbit, and burn forward again at the outer circle.",
    ],
    formula: ["a_t = (r₁ + r₂) / 2", "Δv₁ = √(μ(2/r₁ − 1/a_t)) − √(μ/r₁)", "Δv₂ = √(μ/r₂) − √(μ(2/r₂ − 1/a_t))", "coast time = π √(a_t³ / μ)"],
  },
  workIt: {
    reference: { kind: 0, r2: 4 },
    generate(rng, i): P09 {
      if (i < 3) return { kind: 0, r2: i === 0 ? 4 : rng.pick([2, 3, 4, 9]) };
      if (rng.next() < 0.35) return { kind: 0, r2: rng.pick([2, 3, 4, 5, 6, 8, 9]) };
      const t = rng.next() < 0.6 ? TARGETS09[0]! : rng.pick(TARGETS09);
      return { kind: 1, h1: rng.next() < 0.6 ? 300 : rng.pick([200, 400, 500]), ...t };
    },
    show: p => p.kind === 0
      ? `Toy planet: **μ = 1**. Move from a circle at **r₁ = 1** to one at **r₂ = ${p.r2}**.`
      : `From a circular parking orbit **${p.h1} km** up (r₁ = ${km(R_KM + p.h1)} km) to ${p.name} (r₂ = ${km(p.r2)} km). μ⊕ = 3.986 × 10¹⁴ m³/s².`,
    steps(p): B2Step[] {
      const differ = "You arrive on the ellipse, moving slower than the outer circle's speed at its far point. Δv₂ is circle speed minus ellipse speed.";
      if (p.kind === 0) {
        const H = hohmann(1, 1, p.r2);
        return [
          fracStep("at", "a_t", H.at, { hint: `(1 + ${p.r2}) / 2.`, slips: [slip("difference", (p.r2 - 1) / 2, "a_t is the average of the two radii: (r₁ + r₂)/2.")] }),
          numStep("vp", "Speed at the start of the ellipse", H.vp, 2, { ask: "Vis-viva at r = 1, to 2 decimal places.", hint: `√(2/1 − 1/${fr(H.at)}).`,
            slips: [slip("circle", 1, "That's the circle's speed. On the ellipse, use vis-viva: v² = μ(2/r − 1/a_t)."), slip("1/r − 1/a", Math.sqrt(1 - 1 / H.at), "Vis-viva has 2/r: v² = μ(2/r − 1/a).")] }),
          numStep("dv1", "Δv₁", H.dv1, 2, { ask: "To 2 decimal places.", hint: `${n2(H.vp)} − 1.`,
            slips: [slip("speed not change", H.vp, "Δv₁ is the change: ellipse speed minus circle speed."), slip("circle speeds", 1 - Math.sqrt(1 / p.r2), differ)] }),
          numStep("dv2", "Δv₂", H.dv2, 2, { ask: "To 2 decimal places.", hint: `√(1/${p.r2}) − √(2/${p.r2} − 1/${fr(H.at)}).`,
            slips: [slip("circle speeds", 1 - Math.sqrt(1 / p.r2), differ), slip("ellipse speed", H.va, "Δv₂ is the change at the far point: circle speed minus ellipse speed.")] }),
        ];
      }
      const r1 = R_KM + p.h1, H = hohmann(MU_E, r1 * 1000, p.r2 * 1000), dv1 = H.dv1 / 1000, dv2 = H.dv2 / 1000, hours = H.coast / 3600;
      return [
        numStep("at", "a_t", H.at / 1000, 0, { unit: "km", ask: "To the nearest km.", hint: `(${km(r1)} + ${km(p.r2)}) / 2.`,
          slips: [slip("altitudes", (p.h1 + p.r2 - R_KM) / 2, "Use radii from Earth's center, not heights above the ground.")] }),
        numStep("dv1", "Δv₁", dv1, 2, { unit: "km/s", ask: "To 2 decimal places.", hint: `√(μ(2/r₁ − 1/a_t)) − √(μ/r₁), in m/s, then divide by 1000.`,
          slips: [
            slip("backward", -dv1, "Burn forward to raise the far side. You end up slower in the higher circle, but you get there by speeding up."),
            slip("speed not change", H.vp / 1000, "Δv₁ is the change: ellipse speed minus circle speed."),
          ] }),
        numStep("dv2", "Δv₂", dv2, 2, { unit: "km/s", ask: "To 2 decimal places.", hint: `√(μ/r₂) − √(μ(2/r₂ − 1/a_t)).`,
          slips: [slip("circle speeds", (H.v1 - H.v2) / 1000, differ)] }),
        numStep("tot", "Total", dv1 + dv2, 2, { unit: "km/s", ask: "To 2 decimal places.", hint: "Add the two burns.",
          slips: [slip("circle speeds", (H.v1 - H.v2) / 1000, differ)] }),
        numStep("coast", "Coast time", hours, 2, { unit: "hours", ask: "To 2 decimal places.", hint: `π √(a_t³ / μ) seconds, then divide by 3600.`,
          slips: [slip("full period", 2 * hours, "You only fly half the ellipse, from near point to far point."), slip("minutes", H.coast / 60, "That's in minutes. Divide by 60 for hours.")] }),
      ];
    },
    scene: (p): SceneRef => p.kind === 0 ? { scene: "or-burn", props: { toy: true, r2: p.r2, dv1: 0, quiet: true } } : { scene: "or-burn", props: { h1: p.h1, r2: p.r2, dv1: 0, quiet: true } },
  },
  oracle: p => {
    const mu = p.kind === 0 ? 1 : 3.986e14, r1 = p.kind === 0 ? 1 : (6371 + p.h1) * 1000, r2 = p.kind === 0 ? p.r2 : p.r2 * 1000, at = (r1 + r2) / 2;
    const vp = Math.sqrt(mu * (2 / r1 - 1 / at)), va = Math.sqrt(mu * (2 / r2 - 1 / at)), d1 = vp - Math.sqrt(mu / r1), d2 = Math.sqrt(mu / r2) - va;
    if (p.kind === 0) return [at, vp, d1, d2];
    return [at / 1000, d1 / 1000, d2 / 1000, (d1 + d2) / 1000, (Math.PI * Math.sqrt(at ** 3 / mu)) / 3600];
  },
  useIt: {
    say: ["Project: geostationary delivery. From the 300 km parking orbit to geostationary radius: the two burns, the coast time, and the propellant fraction with your engine's `ve`.",
      "It's a dry run of the Mars plan. Save the total as `dv_hohmann`."],
    project: "or-geo",
  },
  deeper: [
    "Hohmann is the cheapest two-burn transfer between circles, but a three-burn bi-elliptic transfer beats it when r₂/r₁ > 11.94.",
    "Changing the orbit's plane by an angle Δi costs 2v sin(Δi/2), which is why launch sites near the equator help.",
    "Low-thrust spirals burn all the way out, and their Δv is simply the difference of the circle speeds (Edelbaum).",
  ],
};

/* ------------------------------------------------------------------ unit 4 ------------------------------------------------------------------ */

type P10 = { kind: 0; T2: number } | { kind: 1; name: "Venus" | "Jupiter" | "Saturn" };

export const or10: B2Lesson<P10> = {
  id: "b2-or-10", track: "or", unit: 4, title: "Launch windows",
  youCan: "find how long a transfer takes, where the target must be when you leave, and how often the chance comes back.",
  needs: ["b2-or-09", "b2-or-03"],
  tools: ["or-clock", "or-sandbox"],
  play: { scene: "or-clock", props: { target: "Mars" },
    say: "Earth and another planet circle the Sun. Drag the launch date and a ghost ship flies the transfer ellipse. Launch at the wrong time and it reaches the target's orbit with the planet somewhere else. The dial shows the angle between the two planets as the dates roll." },
  guess: { scene: "or-clock", props: { target: "Mars", hide: true }, kind: "slider", min: -180, max: 180, step: 1, start: 120, answer: 180 - (360 * 0.5 * 1.262 ** 1.5) / 1.524 ** 1.5, near: 10, unit: "degrees ahead of Earth",
    format: x => x.toFixed(0),
    ask: "Drag Mars to where it must be at launch for the ship to meet it. Slide the dashed Mars around its orbit.",
    revealProps: { target: "Mars", fly: true },
    reveal: "44° ahead of Earth. The ship flies 259 days, and in that time Mars moves 136° around to meet it 180° from the start." },
  nameIt: {
    say: [
      "The transfer is half an ellipse, so the ship arrives 180° around from where it left. During the flight the target moves on, so at launch it must already be ahead by the right angle.",
      `That alignment comes back once every synodic period. ${CIRCLE}`,
    ],
    formula: ["t = ½ a_t^(3/2) (Sun, AU, years)", "T₂ = r₂^(3/2)", "φ = 180° − 360° × t / T₂", "S = 1 / |1 − 1/T₂| years"],
  },
  workIt: {
    reference: { kind: 1, name: "Jupiter" },
    generate(rng, i): P10 {
      if (i < 3) return { kind: 0, T2: rng.pick([2, 3, 4, 8]) };
      if (rng.next() < 0.3) return { kind: 0, T2: rng.pick([2, 3, 4, 5, 6, 8, 9, 12]) };
      return { kind: 1, name: rng.pick(["Venus", "Jupiter", "Saturn"] as const) };
    },
    show: p => p.kind === 0
      ? `A planet circles the Sun once every **${p.T2} years**. How often do launch windows from Earth come back? Type a fraction of a year.`
      : `Plan a Hohmann transfer from Earth (1 AU) to **${p.name}** (${PLANET_AU[p.name]} AU). ${CIRCLE}`,
    steps(p): B2Step[] {
      if (p.kind === 0) {
        const S = 1 / Math.abs(1 - 1 / p.T2);
        return [fracStep("S", "Windows repeat every", S, { unit: "years", hint: `1/S = 1 − 1/${p.T2}.`,
          slips: [slip("T₂ − T₁", p.T2 - 1, "Windows repeat when Earth laps the target (or the target laps Earth). Rates subtract: 1/S = |1/T₁ − 1/T₂|.")] })];
      }
      const w = windowTo(PLANET_AU[p.name]), ahead = w.phi >= 0 ? 0 : 1;
      return [
        numStep("t", "Transfer time", w.days, 0, { unit: "days", ask: "To the nearest day.", hint: `a_t = (1 + ${PLANET_AU[p.name]}) / 2, t = ½ a_t^(3/2) years × 365.25.`,
          slips: [slip("full period", 2 * w.days, "You fly only half the ellipse: t = ½ a_t^(3/2).")] }),
        numStep("T2", "Target's period", w.T2, 2, { unit: "years", ask: "To 2 decimal places.", hint: `${PLANET_AU[p.name]}^(3/2).`,
          slips: [slip("squared", PLANET_AU[p.name] ** 2, "Kepler's third law: T² = a³, so T = a^(3/2).")] }),
        numStep("phi", "Lead angle", Math.abs(w.phi), 0, { unit: "°", ask: "How far apart, to the nearest degree. Ahead or behind comes next.", hint: `180° − 360° × ${group(w.t, 3)} / ${n2(w.T2)}.`,
          slips: [
            slip("360t/T", (360 * w.t) / w.T2, "That's how far the target moves during the flight. You meet it 180° around, so subtract that from 180°."),
            slip("signed", w.phi, "Give the size here, and say ahead or behind in the next step."),
          ] }),
        tapStep("side", "Ahead or behind Earth?", ["Ahead", "Behind"], ahead, { hint: "Look at the sign of φ.",
          slips: [slip("side", 1 - ahead, ahead === 1
            ? "A negative lead means the target must be behind Earth. That happens for inner planets, which move faster."
            : "A positive lead means the target must already be ahead of Earth, since it moves slower and you're chasing it.")] }),
        numStep("S", "Windows repeat every", w.S * 365.25, 0, { unit: "days", ask: "To the nearest day.", hint: `S = 1 / |1 − 1/${n2(w.T2)}| years.`,
          slips: [slip("T₂ − T₁", Math.abs(w.T2 - 1) * 365.25, "Windows repeat when Earth laps the target (or the target laps Earth). Rates subtract: 1/S = |1/T₁ − 1/T₂|.")] }),
      ];
    },
    scene: (p): SceneRef => ({ scene: "or-clock", props: { target: p.kind === 1 ? p.name : "Mars", quiet: true } }),
  },
  oracle: p => {
    if (p.kind === 0) return [1 / Math.abs(1 - 1 / p.T2)];
    const r2 = { Venus: 0.723, Jupiter: 5.203, Saturn: 9.537 }[p.name], at = (1 + r2) / 2, t = 0.5 * at ** 1.5, T2 = r2 ** 1.5, phi = 180 - (360 * t) / T2;
    return [t * 365.25, T2, Math.abs(phi), phi >= 0 ? 0 : 1, 365.25 / Math.abs(1 - 1 / T2)];
  },
  useIt: {
    say: ["For Mars: the lead angle is 44° ahead, and windows come back every 780 days, about 26 months.",
      "Save the lead as `phase_mars`. The mission card times your launch with it."],
    saves: { name: "phase_mars", value: () => windowTo(PLANET_AU.Mars).phi, unit: "°", note: "Mars's lead over Earth at launch for a Hohmann transfer" },
    scene: { scene: "or-clock", props: { target: "Mars" } },
  },
  deeper: [
    "Lambert's problem: find the orbit between two points in a given time. Porkchop plots map the departure energy over every launch and arrival date.",
    "Real orbits are eccentric and tilted, so real windows differ from the circle model by weeks, and some windows are much cheaper than others.",
  ],
};

type P11 = { kind: 0; h: number; vinf: number } | { kind: 1; vinf: number };

export const or11: B2Lesson<P11> = {
  id: "b2-or-11", track: "or", unit: 4, title: "Leaving and arriving: patched conics",
  youCan: "find the burn from a parking orbit that sends a ship off with a chosen leftover speed, and the burn to be captured at the other end.",
  needs: ["b2-or-06", "b2-or-09"],
  tools: ["or-depart", "or-sandbox", "units"],
  play: { scene: "or-depart", props: { dv: 3 },
    say: "Earth with the 300 km parking orbit. Drag the burn size: the orbit stretches, then opens into a hyperbola, and the arrow at its far end shows the leftover speed v∞. Switch to the Sun's view and the ship is handed over with v∞ added to Earth's own speed." },
  guess: { scene: "or-depart", props: { dv: 3, quiet: true }, kind: "choice", options: ["Exactly 3 km/s", "More than 3 km/s", "Less than 3 km/s"], answer: 1,
    ask: "To leave Earth with 3 km/s to spare, do you need a burn of 3 km/s, more, or less?",
    revealProps: { vinf: 3 },
    reveal: "More, but only a little: 3.61 km/s. Starting deep in Earth's gravity, where you're already fast, each km/s of burn buys a lot of energy." },
  nameIt: {
    say: [
      "Near a planet only that planet's gravity matters, and far away only the Sun's. Stitch the pieces together at the edge of the planet's pull.",
      "To leave with leftover speed v∞, you need escape speed plus v∞ in energy terms, which is much less than adding the speeds. Arriving works the same way in reverse.",
    ],
    formula: ["v_burn = √(v∞² + v_esc²), v_esc = √(2μ/r)", "Δv = v_burn − √(μ/r)"],
  },
  workIt: {
    reference: { kind: 0, h: 300, vinf: 3 },
    generate(rng, i): P11 {
      if (i < 3) return { kind: 0, h: 300, vinf: i === 0 ? 3 : rng.pick([2.5, 3, 3.5]) };
      if (rng.next() < 0.5) return { kind: 0, h: rng.next() < 0.6 ? 300 : rng.pick([200, 400]), vinf: rng.next() < 0.5 ? rng.pick([2.5, 3, 3.5]) : rng.int(20, 45) / 10 };
      return { kind: 1, vinf: rng.next() < 0.6 ? rng.pick([2, 2.65, 3]) : rng.int(20, 35) / 10 };
    },
    show: p => p.kind === 0
      ? `Leave Earth from a circular parking orbit **${p.h} km** up (r = ${km(R_KM + p.h)} km) with **v∞ = ${n2(p.vinf)} km/s** to spare. μ⊕ = 3.986 × 10¹⁴ m³/s².`
      : `Arrive at Mars with **v∞ = ${n2(p.vinf)} km/s** and get captured into a circular orbit **400 km** up (r = 3790 km). μ♂ = 4.283 × 10¹³ m³/s².`,
    steps(p): B2Step[] {
      if (p.kind === 0) {
        const r = (R_KM + p.h) * 1000, ve = vEsc(MU_E, r) / 1000, vc = vCirc(MU_E, r) / 1000, vb = Math.sqrt(p.vinf ** 2 + ve * ve);
        return [
          numStep("vesc", "Escape speed at the parking orbit", ve, 2, { unit: "km/s", ask: "To 2 decimal places.", hint: `√(2μ⊕ / ${km(r)}) m/s.`,
            slips: [slip("circle speed", vc, "That's circular speed. Escape is √2 times that.")] }),
          numStep("vb", "Speed needed after the burn", vb, 2, { unit: "km/s", ask: "To 2 decimal places.", hint: `√(${n2(p.vinf)}² + ${n2(ve)}²).`,
            slips: [slip("added speeds", p.vinf + ve, "Energies add, not speeds: v_burn² = v∞² + v_esc².")] }),
          numStep("dv", "Δv", vb - vc, 2, { unit: "km/s", ask: "To 2 decimal places.", hint: `${n2(vb)} − ${n2(vc)}.`,
            slips: [
              slip("Δv = v∞", p.vinf, "The burn happens deep in Earth's gravity, where speed is worth more energy. Combine v∞ and escape speed with squares."),
              slip("minus escape", vb - ve, "You start in the parking orbit, moving at circular speed. Subtract that."),
            ] }),
        ];
      }
      const r = (R_MARS_KM + 400) * 1000, ve = vEsc(MU_MARS, r) / 1000, vc = vCirc(MU_MARS, r) / 1000, cap = Math.sqrt(p.vinf ** 2 + ve * ve) - vc;
      return [
        numStep("vesc", "Escape speed there", ve, 2, { unit: "km/s", ask: "To 2 decimal places.", hint: "√(2μ♂ / 3,790,000) m/s.",
          slips: [slip("circle speed", vc, "That's circular speed. Escape is √2 times that.")] }),
        numStep("vc", "Circular speed there", vc, 2, { unit: "km/s", ask: "To 2 decimal places.", hint: "√(μ♂ / 3,790,000) m/s.",
          slips: [slip("escape speed", ve, "That's escape speed. Circular speed is √(μ/r), smaller by √2.")] }),
        numStep("cap", "Capture Δv", cap, 2, { unit: "km/s", ask: "To 2 decimal places.", hint: `√(${n2(p.vinf)}² + ${n2(ve)}²) − ${n2(vc)}.`,
          slips: [
            slip("Δv = v∞", p.vinf, "The burn happens deep in Mars's gravity, where speed is worth more energy. Combine v∞ and escape speed with squares."),
            slip("added speeds", p.vinf + ve - vc, "Energies add, not speeds: v_burn² = v∞² + v_esc²."),
            slip("minus escape", Math.sqrt(p.vinf ** 2 + ve * ve) - ve, "You end in the circular orbit, moving at circular speed. Subtract that."),
          ] }),
      ];
    },
    scene: (p): SceneRef => p.kind === 0 ? { scene: "or-depart", props: { h: p.h, vinf: p.vinf, quiet: true } } : { scene: "or-depart", props: { body: "Mars", vinf: p.vinf, quiet: true } },
  },
  oracle: p => {
    if (p.kind === 0) { const r = (6371 + p.h) * 1000, e = Math.sqrt((2 * 3.986e14) / r) / 1000, b = Math.sqrt(p.vinf ** 2 + e * e); return [e, b, b - Math.sqrt(3.986e14 / r) / 1000]; }
    const r = 3790e3, e = Math.sqrt((2 * 4.283e13) / r) / 1000, c = Math.sqrt(4.283e13 / r) / 1000;
    return [e, c, Math.sqrt(p.vinf ** 2 + e * e) - c];
  },
  useIt: {
    say: ["Your Mars burns: from `v_LEO`, leaving with the transfer's v∞ of 2.95 km/s takes 3.59 km/s. Arriving with 2.65 km/s, capture into a 400 km orbit takes 2.08 km/s.",
      "Save both as `dv_depart` and `dv_capture`."],
    scene: { scene: "or-depart", props: { vinf: marsPlan(300, 400, 450).vinf1, keep: true } },
  },
  deeper: [
    "The sphere of influence r_SOI = a(m/M)^(2/5) is about 925,000 km for Earth. Patching the conics there costs only a small error, because the Sun's pull barely changes across it.",
    "Aerocapture: brake in Mars's air instead of burning. Gravity assists: in the planet's frame the speed in and out is the same, but the direction turns by δ, with sin(δ/2) = 1/(1 + r_p v∞²/μ). In the Sun's frame the ship gains up to 2v∞ sin(δ/2).",
  ],
};

interface P12 { h1: number; h2: number; isp: number }

export const or12: B2Lesson<P12> = {
  id: "b2-or-12", track: "or", unit: 4, title: "The Mars plan",
  youCan: "plan a full Earth-to-Mars trip: burns, timing, flight time and propellant.",
  needs: ["b2-or-10", "b2-or-11", "b2-or-08"],
  tools: ["or-card", "or-burn", "or-clock", "or-sandbox"],
  play: { scene: "or-card", props: {},
    say: "All the pieces on one card. Earth and Mars circle the Sun, the ship waits in its parking orbit, and every number recomputes as you change the parking orbit, the Mars orbit or the engine. Press Launch and watch the ship coast 259 days to meet Mars." },
  guess: { scene: "or-card", props: { quiet: true }, kind: "choice", options: ["About 3 km/s", "About 6 km/s", "About 12 km/s"], answer: 1,
    ask: "Before computing: is the total Δv from low Earth orbit to low Mars orbit closer to 3, 6 or 12 km/s?",
    revealProps: {},
    reveal: "About 6: the card's total is 5.67 km/s, 3.59 to leave and 2.08 to stay." },
  nameIt: {
    say: [
      "A Hohmann trip to Mars is three nested problems: leave Earth onto the Sun-centered transfer, coast half an ellipse from 1 AU to 1.524 AU, and get captured by Mars.",
      `The Sun-frame burns become the v∞ at each end. ${CIRCLE}`,
    ],
    formula: ["Sun frame: Δv₁, Δv₂ from b2-or-09 with μ☉", "window: b2-or-10", "planet burns: b2-or-11", "propellant: b2-or-08"],
  },
  workIt: {
    reference: { h1: 300, h2: 400, isp: 450 },
    generate(rng, i) {
      if (i === 0) return { h1: 300, h2: 400, isp: 450 };
      if (i === 1) return { h1: 200, h2: 400, isp: 450 };
      if (i === 2) return { h1: 400, h2: 400, isp: 450 };
      return { h1: rng.pick([200, 300, 400]), h2: rng.pick([300, 400, 1000]), isp: rng.pick([350, 380, 450]) };
    },
    show: p => `Parking orbit **${p.h1} km** above Earth, final orbit **${km(p.h2)} km** above Mars, engine **I_sp = ${p.isp} s**. μ☉ = 1.327 × 10²⁰ m³/s², 1 AU = 1.496 × 10¹¹ m. ${CIRCLE}`,
    steps(p) {
      const m = marsPlan(p.h1, p.h2, p.isp), years = m.days / 365.25, Tm = 1.524 ** 1.5;
      const dep2 = slip("Δv₁ as the burn", m.vinf1, `${n2(m.vinf1)} km/s is the speed you need relative to Earth once you're free of it. From the parking orbit, the burn is √(v∞² + v_esc²) − v_circ.`);
      return [
        numStep("v1", "Sun-frame Δv₁ (= v∞ leaving Earth)", m.vinf1, 2, { unit: "km/s", ask: "To 2 decimal places.", hint: "Hohmann's Δv₁ with μ☉, r₁ = 1 AU, r₂ = 1.524 AU, in meters.",
          slips: [slip("AU in km", m.vinf1 * Math.sqrt(1000), "μ☉ is in m³/s². Convert AU to meters: 1 AU = 1.496 × 10¹¹ m.")] }),
        numStep("v2", "Sun-frame Δv₂ (= v∞ arriving at Mars)", m.vinf2, 2, { unit: "km/s", ask: "To 2 decimal places.", hint: "Hohmann's Δv₂ at r₂ = 1.524 AU.",
          slips: [slip("AU in km", m.vinf2 * Math.sqrt(1000), "μ☉ is in m³/s². Convert AU to meters: 1 AU = 1.496 × 10¹¹ m.")] }),
        numStep("t", "Flight time", m.days, 0, { unit: "days", ask: "To the nearest day.", hint: "π √(a_t³ / μ☉) seconds, then divide by 86,400.",
          slips: [slip("full period", 2 * m.days, "You only fly half the ellipse, from Earth's orbit to Mars's.")] }),
        numStep("phi", "Mars's lead at launch", m.phi, 0, { unit: "°", ask: "To the nearest degree.", hint: `180° − 360° × ${group(years, 3)} / ${n2(Tm)}.`,
          slips: [slip("360t/T", 180 - m.phi, "That's how far Mars moves during the flight. You meet it 180° around, so subtract that from 180°.")] }),
        numStep("dep", `Departure burn from ${p.h1} km`, m.dep, 2, { unit: "km/s", ask: "To 2 decimal places.", hint: `√(${n2(m.vinf1)}² + v_esc²) − v_circ at r = ${km(R_KM + p.h1)} km.`, slips: [dep2] }),
        numStep("cap", `Capture burn into ${km(p.h2)} km`, m.cap, 2, { unit: "km/s", ask: "To 2 decimal places.", hint: `√(${n2(m.vinf2)}² + v_esc²) − v_circ at r = ${km(R_MARS_KM + p.h2)} km.`,
          slips: [slip("Δv₂ as the burn", m.vinf2, `${n2(m.vinf2)} km/s is the speed relative to Mars as you arrive. To stay, the burn is √(v∞² + v_esc²) − v_circ.`)] }),
        numStep("tot", "Total Δv", m.total, 2, { unit: "km/s", ask: "To 2 decimal places.", hint: "Departure plus capture.",
          slips: [slip("added all four", m.vinf1 + m.vinf2 + m.dep + m.cap, "The Sun-frame burns are not extra. They're delivered by the departure and capture burns as v∞.")] }),
        numStep("frac", "Propellant fraction", m.frac, 1, { unit: "%", ask: "1 − e^(−Δv / v_e), as a percent to 1 decimal place.", hint: `v_e = ${p.isp} × 9.81 m/s.`,
          slips: [
            slip("empty part", 100 - m.frac, "That's the empty part. The propellant is the rest: 1 − m_empty/m_full."),
            slip("forgot g₀", 100 * (1 - Math.exp(-m.total / (p.isp / 1000))), "Specific impulse is in seconds. Multiply by g₀ = 9.81 m/s² to get an exhaust speed."),
          ] }),
      ];
    },
    scene: (p): SceneRef => ({ scene: "or-card", props: { h1: p.h1, h2: p.h2, isp: p.isp, quiet: true } }),
  },
  oracle: p => {
    const mu = 1.327e20, r1 = 1.496e11, r2 = 1.524 * 1.496e11, at = (r1 + r2) / 2;
    const d1 = Math.sqrt(mu * (2 / r1 - 1 / at)) - Math.sqrt(mu / r1), d2 = Math.sqrt(mu / r2) - Math.sqrt(mu * (2 / r2 - 1 / at));
    const t = Math.PI * Math.sqrt(at ** 3 / mu), Tm = 2 * Math.PI * Math.sqrt(r2 ** 3 / mu);
    const rp = (6371 + p.h1) * 1000, rm = (3390 + p.h2) * 1000;
    const dep = Math.sqrt(d1 ** 2 + (2 * 3.986e14) / rp) - Math.sqrt(3.986e14 / rp), cap = Math.sqrt(d2 ** 2 + (2 * 4.283e13) / rm) - Math.sqrt(4.283e13 / rm);
    const tot = (dep + cap) / 1000;
    return [d1 / 1000, d2 / 1000, t / 86400, 180 - (360 * t) / Tm, dep / 1000, cap / 1000, tot, 100 * (1 - Math.exp(-tot / ((p.isp * 9.81) / 1000)))];
  },
  useIt: {
    say: ["The build: save the mission card as `mission`, with every number live.",
      "Then change one thing, a lower parking orbit or a better engine, and see what it saves."],
    project: "or-mission",
  },
  deeper: [
    "Gravity assists and free-return trajectories. The restricted three-body problem has five Lagrange points; L4 and L5 are stable when the big mass is more than about 25 times the small one, and halo orbits circle the others.",
    "Low-energy transfers ride the \"interplanetary transport network\" between those points.",
    "Real missions solve Lambert's problem on porkchop plots, and their burns land within about 10 to 30 percent of this circle model, depending on the window.",
  ],
};

export const ORBITS_LESSONS = [or01, or02, or03, or04, or05, or06, or07, or08, or09, or10, or11, or12];

