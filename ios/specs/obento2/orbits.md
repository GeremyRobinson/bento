# Bento² track 8 · Orbits and spaceflight (code `or`, 12 lessons)

**What it is:** how gravity steers planets, moons and spacecraft. One rule (the pull weakens with distance squared) explains every orbit, and a few well-timed burns get you from Earth to Mars.

**Role:** branch. **Needs:** Differential equations (`de`), mainly b2-de-03 (steppers) and b2-de-05 (systems). Soft needs only: the map lights them, nothing locks.

## The build: a trip from Earth to Mars

The learner plans a real Earth-to-Mars mission with a Hohmann transfer and ends with a **mission card** in the Notebook: the parking orbit, the departure burn, the transfer orbit, the launch window, the flight time, the capture burn at Mars, the total Δv and how much of the ship must be propellant. Every number on the card is live: change the parking altitude or the engine and the card recomputes.

What each unit adds:
1. **Falling around** (or-01 to or-03): the parking orbit. Circular speed and period at 300 km above Earth, saved as `v_LEO`.
2. **Ellipses** (or-04 to or-06): the transfer orbit's shape and speeds. Its semimajor axis, eccentricity, and the vis-viva speeds at its two ends.
3. **Changing orbits** (or-07 to or-09): the engine. A trustworthy simulator (symplectic Euler), the rocket equation (`ve`), and the Hohmann two-burn plan, tested first on Earth orbit to geostationary.
4. **To Mars** (or-10 to or-12): timing and assembly. The phase angle and launch window, leaving Earth and arriving at Mars with patched conics, then the full mission card.

## Units

| Unit | Lessons | Small project after |
|---|---|---|
| 1 · Falling around | or-01 Inverse square · or-02 Circular orbits · or-03 Period and Kepler's third law | **Pick a satellite** |
| 2 · Ellipses | or-04 Orbit shapes · or-05 Equal areas · or-06 Energy, vis-viva and escape | **Comet card** |
| 3 · Changing orbits | or-07 Orbits as a differential equation · or-08 The rocket equation · or-09 The Hohmann transfer | **Geostationary delivery** |
| 4 · To Mars | or-10 Launch windows · or-11 Leaving and arriving · or-12 The Mars plan | the build |

## Small projects

- **Pick a satellite** (after or-03). Choose a job (space station, GPS, weather satellite that hovers over one spot) and an altitude. The card shows the radius, speed and period, and checks the job (a geostationary period must be one sidereal day). Saves `r_sat`, `v_sat`, `T_sat`.
- **Comet card** (after or-06). Type a comet's closest and farthest distances from the Sun (Halley is the preset). The card draws the ellipse and gives a, e, the period and the speeds at both ends. Saved in the Notebook.
- **Geostationary delivery** (after or-09). From a 300 km parking orbit to geostationary radius: the two burns, the coast time, and the propellant fraction with your engine `ve`. A dry run of the Mars plan.

## Constants and rounding (used by every lesson)

All values come from **Units and constants**, which must hold them under these names and show them with the rounding stated here:
- G = 6.674 × 10⁻¹¹ N·m²/kg²
- Earth: GM⊕ = μ⊕ = 3.986 × 10¹⁴ m³/s², mean radius R⊕ = 6371 km, surface gravity g₀ = 9.81 m/s² (standard gravity, slightly below μ⊕/R⊕² = 9.82, so scaling from either can differ by 0.01), sidereal day 86,164 s
- Sun: GM☉ = μ☉ = 1.327 × 10²⁰ m³/s²; 1 AU = 1.496 × 10¹¹ m; 1 year = 365.25 days
- Mars: orbit radius 1.524 AU (its semimajor axis, treated as a circle in Earth's plane), GM = 4.283 × 10¹³ m³/s², radius 3390 km
- Planet distances for timing: Venus 0.723 AU, Jupiter 5.203 AU, Saturn 9.537 AU (circles in one plane)

**Rounding rule.** Each step states its places. Oracles compute with the constants above, carry full precision between steps (the Number shelf stores unrounded values), and round only the typed answer. Answers within one unit of the last stated place are accepted, so rounding an intermediate value never counts against the learner. The circular, coplanar model is stated on screen once per lesson ("Mars's orbit treated as a circle"), and the Deeper layers say what changes in the real solar system.

## New for Development

Shared tools are named as in `math-app/bento2/research/toolbox.md`.

1. **★ Orbit sandbox.** A choice of central body (Earth, Sun, Mars, or a toy planet with μ = 1). Launch with a drag (speed and direction). The live path comes with a conic readout: a, e, near and far distances, the energy sign, and the type (circle, ellipse, parabola, hyperbola). Time warp, and an integrator switch (Euler or symplectic Euler) for or-07. It shares its time engine with the Slope field and flow sandbox (`de`).
2. **Newton's cannon.** A mountain on Earth with a speed slider, from a short arc to a full orbit at 7.91 km/s to escape.
3. **Kepler checker.** Equal-time wedges with their areas shown, and real planets on log-log axes of a against T (slope 3/2).
4. **Burn planner.** Tap a point on an orbit, drag a Δv arrow (forward or sideways), and see the new orbit. It has a Hohmann preset (two circles plus the transfer) and a Δv ledger that adds up burns.
5. **Mission clock.** Two planets circle the Sun with a ship on its transfer. A phase-angle dial, a countdown to the next window and a synodic-period readout.
6. **Rocket stack (new picture).** A bar of propellant and dry mass with a live Δv readout from the rocket equation, showing that each added tonne buys less.
7. **Departure view (new picture).** A zoomed planet with the parking orbit, the burn point, the escape hyperbola and its v∞ arrow, and a sphere-of-influence circle. Zooming out hands the ship to the Sun frame (patched conics).
8. **Mission card (new picture, the build).** A one-screen summary tied to the shelf values, recomputed live.
9. **Units and constants additions:** the GM values above as named constants (μ⊕, μ☉, μ♂), the AU, sidereal day and planet distances, shown with stated rounding.

Number shelf names this track writes: `g_ISS`, `v_LEO`, `r_sat`, `v_sat`, `T_sat`, `halley_a`, `vratio_mars`, `h_step`, `ve`, `dv_hohmann`, `phase_mars`, `dv_depart`, `dv_capture`, `mission`.

---

## Unit 1 · Falling around

### b2-or-01 · Gravity falls off with distance squared
- **You can:** find how strong gravity is at any height above a planet.
- **Needs:** `g12-vecmag`.
- **Tool:** ★ Orbit sandbox (gravity arrows), Units and constants.
- **Play:** Drag a probe away from Earth. A gravity arrow on it shrinks, and a readout shows its distance from Earth's center and the pull in m/s². Gravity arrows fill the space around the planet, all pointing at the center.
- **Guess:** "Double your distance from Earth's center. What fraction of the pull is left?" Pick 1/2, 1/4, 1/8. The reveal moves the probe to twice the distance and compares arrows.
- **Name it:** Gravity between two masses gets weaker with the square of the distance between their centers. At the surface it's 9.81 m/s², so at any distance r you can scale from there. Rules: F = GMm/r², and g(r) = GM/r² = g₀(R⊕/r)².
- **Work it:** kind 0 (index < 3): the distance is multiplied by k ∈ {2, 3, 4, 5, 10}; type the fraction of the pull left (1/k²). kind 1: altitude h ∈ {400, 2000, 6371, 35786} km. Example: h = 400 km.
  1. **Distance from the center** R⊕ + h in km (6771).
  2. **Gravity there** m/s², 2 decimals (8.69; others 5.68, 2.45, 0.22).
  3. **Percent of surface gravity** whole percent (89).
  - Slips: answered 1/k: "Gravity falls with the square of the distance: twice as far is 1/4 the pull." · used h instead of R⊕ + h: "Distance is measured from Earth's center. Add Earth's radius, 6371 km." · thought there's no gravity at the space station: "The station still feels 89% of the surface pull. Astronauts float because they and the station fall together."
- **Oracle:** 1/k²; 9.81·(6371/(6371 + h))² rounded to 2 places.
- **Use it:** Space station "weightlessness": compute the pull at 400 km and save it as `g_ISS`. Orbits are falling, which the next lesson makes exact.
- **Deeper:** The shell theorem: a ball of mass pulls like a point at its center, proved by adding up the pull of thin rings (b2-mv-07, rings and wedges). Gauss's law for gravity. Inside a uniform planet, g grows in proportion to r. Tides come from the difference in pull across a body, about 2GMd/r³.

### b2-or-02 · Falling around: circular orbits
- **You can:** find the speed of a circular orbit at any height.
- **Needs:** b2-or-01, `c-motion`.
- **Tool:** Newton's cannon, ★ Orbit sandbox.
- **Play:** Fire Newton's cannon from a mountain (no air) and drag the launch speed. The ball lands farther and farther away until, at 7.91 km/s, the ground curves away as fast as it falls and the ball goes all the way around.
- **Guess:** "Move a circular orbit out to 4 times the radius. What happens to its speed?" Pick ×4, ×2, ×1/2, ×1/4. The reveal runs both orbits side by side with speed readouts.
- **Name it:** In a circular orbit, gravity supplies exactly the pull needed to keep turning: v²/r = GM/r². Farther out you move slower. Rule: v = √(GM/r).
- **Work it:** kind 0 (index < 3): radius multiplied by k ∈ {4, 9, 16, 25}; type the speed factor (1/√k as a fraction). kind 1: altitude h ∈ {300, 400, 500, 1000, 2000, 20200} km above Earth. Example: h = 300 km.
  1. **Radius** in km (6671).
  2. **Speed** km/s, 2 decimals (7.73; others 7.67, 7.62, 7.35, 6.90, 3.87).
  - Slips: forgot the square root: "v² = GM/r, so take the square root at the end." · used km with μ in m³/s²: "μ⊕ is in m³/s², so the radius must be in meters: 6671 km is 6,671,000 m. Then divide by 1000 for km/s." · answered ×1/4 for 4 times the radius: "Speed goes with 1/√r. Four times as far is half as fast."
- **Oracle:** 1/√k; √(3.986e14 / ((6371 + h)·1000)) / 1000, rounded to 2 places.
- **Use it:** Your parking orbit for the Mars trip is circular at 300 km. Save its speed as `v_LEO` (7.73 km/s). GPS satellites sit at 20,200 km and move at 3.87 km/s (b2-re-12 uses them for its GPS clock corrections).
- **Deeper:** The centripetal acceleration v²/r from differentiating r(t) = r(cos ωt, sin ωt) twice: the velocity is rω(−sin ωt, cos ωt), the acceleration is −ω²r(cos ωt, sin ωt), pointing at the center with size ω²r = v²/r (`c-motion`, position, velocity and acceleration). Effective potential, and why stable circular orbits exist only for forces that weaken more slowly than 1/r³.

### b2-or-03 · Period and Kepler's third law
- **You can:** find an orbit's period from its size, and the size from its period.
- **Needs:** b2-or-02.
- **Tool:** Kepler checker, ★ Orbit sandbox.
- **Play:** The Kepler checker plots the real planets on log-log axes of distance against year length. They fall on one straight line. Drag in a new planet anywhere on the distance axis and watch where its year lands.
- **Guess:** "A planet 4 AU from the Sun. How many Earth years is its year?" Place the point on the period axis. The reveal drops it on the line (8 years).
- **Name it:** One lap is the circumference divided by the speed. Bigger orbits are longer and slower, so the period grows faster than the distance. For the Sun in AU and years, the constants cancel. Rules: T = 2π√(r³/GM), and around the Sun T² = a³ (T in years, a in AU).
- **Work it:** kind 0 (index < 3): a ∈ {1, 4, 9, 16, 25} AU; period in years (1, 8, 27, 64, 125). kind 1: T ∈ {8, 27, 64} years; distance in AU (4, 9, 16). kind 2: altitude h ∈ {300, 400, 2000} km above Earth; period in minutes, 1 decimal (90.4, 92.4, 127.0). kind 3: geostationary.
  1. **Period to match** tap 86,400 s (a solar day) or 86,164 s (a sidereal day) (sidereal).
  2. **Radius** r = (μ⊕T²/4π²)^(1/3), in km to the nearest km (42,164).
  - Slips: squared the distance and cubed the period: "Square the period, cube the distance: T² = a³." · used 86,400 s: "A geostationary satellite keeps up with Earth's turn relative to the stars, which takes 23 h 56 min 4 s = 86,164 s. Using 24 h puts it at about 42,241 km, slowly drifting." · forgot to add Earth's radius for the period: "The orbit's radius is measured from Earth's center: 6371 + h."
- **Oracle:** a^(3/2); T^(2/3); 2π√(r³/μ⊕)/60 to 1 place; (3.986e14·86164²/(4π²))^(1/3)/1000 to the nearest km.
- **Use it:** **Pick a satellite** project (see above). Saves `r_sat`, `v_sat`, `T_sat`.
- **Deeper:** With two real masses, T² = 4π²a³/(G(M + m)), and the reduced mass. Weighing Jupiter from Io's orbit. Fitting the log-log line to real planet data gives a slope of 3/2 (b2-mv-17, the least-squares line).

---

## Unit 2 · Ellipses

### b2-or-04 · Orbit shapes: ellipses and beyond
- **You can:** find an orbit's size, eccentricity and width from its closest and farthest distances.
- **Needs:** b2-or-03, `pc-polar`.
- **Tool:** ★ Orbit sandbox (conic readout), Grapher 2D.
- **Play:** Launch sideways from a fixed point and drag the speed. Exactly circular speed gives a circle. A bit faster stretches it into an ellipse with the planet at one focus, then into a parabola, then a hyperbola that never comes back.
- **Guess:** "Launch 10% faster than circular speed. Where is the far point?" Place a point on the line through the planet. The reveal draws the ellipse (the far point lands at about 1.53 times the start distance).
- **Name it:** Every orbit is a conic with the planet at a focus. Its size is the semimajor axis a, the average of the nearest and farthest distances, and its stretch is the eccentricity e. Rules: r_near = a(1 − e), r_far = a(1 + e), b = √(a² − c²) with c = ae, and in polar form r = a(1 − e²)/(1 + e cos θ). e = 0 is a circle, e < 1 an ellipse, e = 1 a parabola, e > 1 a hyperbola.
- **Work it:** pick a Pythagorean triple (c, b, a) from (3, 4, 5), (6, 8, 10), (8, 6, 10), (5, 12, 13), (9, 12, 15), (15, 8, 17), (7, 24, 25), times 1 or 2; r_near = a − c, r_far = a + c (in AU or thousand km). Index < 3: (3, 4, 5) and (8, 6, 10) first, so the first two ellipses differ. Example: r_near = 2, r_far = 8.
  1. **a** (r_near + r_far)/2 (5).
  2. **c** the center-to-focus distance, a − r_near (3).
  3. **e** fraction (3/5).
  4. **b** (4).
  - Slips: e = r_near/r_far: "Eccentricity is c/a, or (r_far − r_near)/(r_far + r_near)." · b = a − c: "b comes from a right triangle: b² = a² − c²." · put the planet at the center: "The planet sits at a focus, c away from the center. That's why there's a near side and a far side."
- **Oracle:** a = (r₁ + r₂)/2, c = (r₂ − r₁)/2, e = c/a, b = √(a² − c²).
- **Use it:** Halley's Comet comes to 0.586 AU and goes out to 35.1 AU. Find a (17.8 AU, 1 decimal) and save it as `halley_a`, then e (0.967, 3 decimals), and with Kepler's law and the shelf value `halley_a` (unrounded, 17.843) its period (75.4 years; 75.1 from the rounded 17.8 is also accepted).
- **Deeper:** Deriving the conic from Newton: with u = 1/r, Binet's equation u″ + u = GM/h² is a forced linear oscillator (b2-de-09, springs), and its solution is the polar conic. The Laplace–Runge–Lenz vector, a hidden conserved arrow that keeps the ellipse from turning. Bertrand's theorem: only 1/r² and spring forces give closed orbits for every bound start. Mercury's slowly turning ellipse is one of relativity's first tests (b2-re-11, the full gravity shift).

### b2-or-05 · Equal areas: fast near, slow far
- **You can:** find an orbiting body's speed at one end of its orbit from the other.
- **Needs:** b2-or-04.
- **Tool:** Kepler checker, ★ Orbit sandbox.
- **Play:** The Kepler checker shades the wedge swept in each equal time step. Drag the eccentricity: near the Sun the wedges are short and fat, far away long and thin, and their areas stay equal.
- **Guess:** "A planet is 3 times farther away at its far point than at its near point. How many times faster is it at the near point?" Pick √3, 3, 9. The reveal shows both speed arrows.
- **Name it:** Equal areas in equal times means the distance times the sideways speed never changes: that's angular momentum. At the near and far points the motion is all sideways. Rules: h = r·v_⊥ is constant, r_near·v_near = r_far·v_far, and v_near/v_far = r_far/r_near = (1 + e)/(1 − e).
- **Work it:** kind 0 (index < 3): r_near ∈ {1, 2, 3} AU, r_far = k·r_near with k from 2 to 6, v_near a multiple of k from 6 to 60 km/s; type v_far (integer). kind 1: Earth: near 0.9833 AU at 30.29 km/s, far 1.0167 AU; type v_far in km/s, 2 decimals (29.29). kind 2: e ∈ {1/5, 1/3, 1/2, 3/5}; type v_near/v_far as a fraction (3/2, 2, 3, 4). Example (kind 0): r_near = 2, r_far = 6, v_near = 30.
  1. **v_far** (10).
  - Slips: multiplied by r_far/r_near: "Farther means slower. v_far = v_near·r_near/r_far." · used squares: "It's r times v that stays fixed, not r times v²." · used (1 − e)/(1 + e) for the near-to-far ratio: "The near speed is the bigger one, so the ratio is (1 + e)/(1 − e)."
- **Oracle:** v_near·r_near/r_far; (1 + e)/(1 − e).
- **Use it:** The Mars transfer ellipse touches 1 AU and 1.524 AU. How many times faster is the ship leaving Earth than arriving at Mars? (1.524.) Saves `vratio_mars`.
- **Deeper:** In the plane, r × v is the determinant of the matrix with columns r and v, the signed area they span (b2-la-07), and the area swept per unit time is ½|r × v|. Angular momentum is conserved for any central force because r × F = 0: the force points along r, so the area they span is zero. Timing along an ellipse: Kepler's equation M = E − e sin E has no closed-form solution. Newton's method for a root solves it in a few steps: to make F(E) = E − e sin E − M zero, slide down the tangent line, E ← E − F(E)/F′(E) = E − (E − e sin E − M)/(1 − e cos E), starting from E = M (b2-mv-19 is the same idea, for minimums).

### b2-or-06 · Energy, vis-viva and escape
- **You can:** find an orbiting body's speed anywhere on its orbit, and the speed it needs to escape.
- **Needs:** b2-or-05, `c-ftc`.
- **Tool:** ★ Orbit sandbox (energy bar), Units and constants.
- **Play:** An energy bar sits next to the ship: kinetic energy up, potential energy down. Drag the launch speed at a fixed spot. While the total is negative the orbit closes. At exactly zero it becomes a parabola and the ship escapes.
- **Guess:** "Escape speed is how many times circular speed at the same spot?" Pick 1.5, √2, 2. The reveal slides the speed up until the orbit opens.
- **Name it:** An orbit's energy per kilogram depends only on its size. Combining that with the speed at one point gives the speed everywhere (the vis-viva equation). Zero energy is the line between staying and leaving. Rules: ε = v²/2 − GM/r = −GM/(2a), v² = GM(2/r − 1/a), and v_esc = √(2GM/r) = √2·v_circ.
- **Work it:** kind 0 (index < 3): toy planet μ = 8, r = 2, v ∈ {1, 2, 3}.
  1. **Energy** ε = v²/2 − μ/r, decimal (v = 1: −3.5).
  2. **Type** tap Ellipse / Circle / Escapes (v = 1: ellipse; 2: circle; 3: escapes).
  3. **a** when bound, −μ/(2ε) as a fraction (8/7).
  kind 1: escape speed from Earth's surface, from 300 km, or from Mars's surface; km/s, 2 decimals (11.19, 10.93, 5.03). kind 2: near point r_near ∈ {6700, 7000, 8000} km, far point r_far ∈ {20000, 42000} km from Earth's center. Example: 7000 and 42000.
  1. **a** in km (24,500).
  2. **Speed at the near point** km/s, 2 decimals (9.88).
  3. **Speed at the far point** km/s, 2 decimals (1.65).
  - Slips: escape = 2·v_circ: "Escape needs twice the kinetic energy of a circular orbit, so √2 times the speed." · used 1/r − 1/a: "Vis-viva has 2/r: v² = GM(2/r − 1/a)." · called zero energy an ellipse: "Zero energy means a parabola. The ship just barely never comes back."
- **Oracle:** kind 0: v²/2 − 4 and −4/ε; kind 1: √(2μ/r); kind 2: √(μ(2/r − 1/a)) in km/s, 2 places.
- **Use it:** **Comet card** project (see above). Then check: the vis-viva speed at the near point and the equal-areas rule from or-05 agree.
- **Deeper:** Deriving vis-viva from energy plus angular momentum. Above escape, the leftover speed far away is v∞ with v∞² = v² − v_esc² (used in or-11), and C3 = v∞² is what launch providers quote. The effective potential and turning points. The Oberth effect: a burn adds the most energy where you're already moving fastest.

---

## Unit 3 · Changing orbits

### b2-or-07 · Orbits as a differential equation
- **You can:** take one step of an orbit simulation by hand and explain why a simple stepper spirals out while symplectic Euler stays put.
- **Needs:** b2-or-06, b2-de-03, b2-de-05.
- **Tool:** ★ Orbit sandbox (integrator switch), Slope field and flow sandbox (`de`).
- **Play:** Run a circular orbit with Euler and a step slider. The ship spirals outward, faster with bigger steps. Flip the switch to symplectic Euler and the same step gives a closed loop. An energy graph runs below: Euler's climbs, and symplectic Euler's wobbles around a flat line.
- **Guess:** "Euler, 100 orbits, this step size. Will the ship end up farther out, closer in, or on the same circle?" Pick one. The reveal runs it.
- **Name it:** Newton's law r″ = −GM·r/|r|³ is a system of four numbers (position and velocity). Euler moves with the old velocity and gains energy every step. Symplectic Euler (kick, then drift) updates the velocity first and then moves with the new one, which keeps energy from drifting. Rules: Euler: r_new = r + h·v, v_new = v + h·a(r). Symplectic Euler (semi-implicit): v_new = v + h·a(r), r_new = r + h·v_new.
- **Work it:** toy units μ = 1, start r = (1, 0), v = (0, 1) (a circular orbit), h ∈ {1/2, 1/4, 1/5, 1/10}. Index < 3: h = 1/2 or 1/4. Example: h = 1/2.
  1. **Acceleration at the start** two boxes (−1, 0).
  2. **Euler position** two boxes (1, 1/2).
  3. **Euler velocity** two boxes (−1/2, 1).
  4. **Energy after the step** v²/2 − 1/|r|, 3 decimals (−0.269; h = 1/4: −0.439, 1/5: −0.461, 1/10: −0.490). It started at −0.5.
  5. **What it means** tap "Energy rose: drifting out" / "Energy fell: drifting in" (rose).
  6. **Symplectic Euler position** two boxes (1 − h², h) = (3/4, 1/2).
  - Slips: acceleration pointed outward: "Gravity pulls toward the center: a = −r/|r|³, so at (1, 0) it's (−1, 0)." · used the new velocity in Euler: "Euler moves with the old velocity. Using the new one is symplectic Euler." · left out the minus in the energy: "Potential energy is −μ/r. A bound orbit has negative total energy."
- **Oracle:** exact fractions (1, h), (−h, 1), (1 − h², h); (h² + 1)/2 − 1/√(1 + h²) to 3 places.
- **Use it:** Choose the largest step that keeps the Mars transfer's energy within 0.1% over the whole flight with symplectic Euler. Saves `h_step`. The build's Mission clock runs on it.
- **Deeper:** Symplectic integrators preserve phase-space area (the Jacobian of one step has determinant 1, b2-mv-08), so they follow a "shadow" orbit with nearly the right energy forever. Symplectic Euler is first order. Leapfrog (velocity Verlet: half kick, drift, half kick) is the second-order version: from the same start, one step lands at (1 − h²/2, h) = (7/8, 1/2) for h = 1/2. Adaptive steps for fast perihelion passes. N-body simulation and the chaotic three-body problem (b2-de-15, chaos).

### b2-or-08 · The rocket equation
- **You can:** find how much speed change a rocket can make from its engine and its fuel, and how much fuel a trip needs.
- **Needs:** b2-or-06, `c-expgrowth`.
- **Tool:** Rocket stack, Units and constants (g₀).
- **Play:** A rocket stack: a dry ship on top of a propellant bar. Drag the propellant up. The Δv readout climbs, but each added tonne buys less than the one before. Swap engines and the whole curve stretches.
- **Guess:** "A 1-tonne ship with 2 tonnes of propellant. Double the propellant to 4 tonnes. What happens to Δv?" Pick Doubles / Less than double / More than double. The reveal shows both bars (about 1.46 times).
- **Name it:** A rocket pushes itself by throwing mass backward at the exhaust speed. Speed gained depends on the log of how much lighter the rocket gets, which is why spaceflight is hard. Rules: Δv = v_e·ln(m_full/m_empty), v_e = I_sp·g₀, and the propellant fraction is 1 − m_empty/m_full = 1 − e^(−Δv/v_e).
- **Work it:** kind 0 (index < 3): (v_e km/s, mass ratio) from (3, e²), (3, 4), (2.5, 5); Δv in km/s, 2 decimals (6.00, 4.16, 4.02). kind 1: I_sp ∈ {300, 350, 450} s, Δv ∈ {3.59, 5.67} km/s. Example: I_sp = 450 s, Δv = 3.59 km/s.
  1. **Exhaust speed** km/s, 2 decimals (4.41; others 2.94, 3.43).
  2. **Mass ratio** m_full/m_empty, 2 decimals (2.26).
  3. **Propellant fraction** percent, 1 decimal (55.7).
  - Slips: used log base 10: "The rocket equation uses the natural log, ln." · flipped the mass ratio: "It's full over empty, which is bigger than 1. Otherwise the log is negative." · forgot g₀: "Specific impulse is in seconds. Multiply by g₀ = 9.81 m/s² to get an exhaust speed."
- **Oracle:** v_e·ln(ratio); I_sp·9.81/1000; e^(Δv/v_e); 100(1 − e^(−Δv/v_e)), with v_e unrounded.
- **Use it:** Pick your engine for the Mars trip (a hydrogen–oxygen upper stage has I_sp about 450 s). Saves `ve`.
- **Deeper:** Deriving the rocket equation from momentum conservation: m dv = −v_e dm is a separable equation (`c-slopefield`). Staging, and why dropping empty tanks beats one big tank. Gravity losses during a slow climb. Electric propulsion: huge I_sp, tiny thrust.

### b2-or-09 · The Hohmann transfer
- **You can:** plan the two burns that move a ship between two circular orbits, and how long the coast takes.
- **Needs:** b2-or-06, b2-or-08.
- **Tool:** Burn planner, ★ Orbit sandbox.
- **Play:** Two circular orbits around Earth. Tap a point on the inner one and drag a forward burn: the orbit stretches into an ellipse whose far point grows until it just touches the outer circle. Then add a second burn there to round it off. The Δv ledger adds them up.
- **Guess:** "Going from low orbit to one about 6 times as wide: is the second burn bigger or smaller than the first?" Pick one. The reveal fills the ledger (2.43 then 1.47 km/s).
- **Name it:** The cheapest two-burn route between circles is an ellipse that touches both. Burn forward at the inner circle to start it, coast half an orbit, and burn forward again at the outer circle. Rules: a_t = (r₁ + r₂)/2; Δv₁ = √(μ(2/r₁ − 1/a_t)) − √(μ/r₁); Δv₂ = √(μ/r₂) − √(μ(2/r₂ − 1/a_t)); coast time = π√(a_t³/μ).
- **Work it:** kind 0 (index < 3): toy planet μ = 1, r₁ = 1, r₂ ∈ {2, 3, 4, 9}. Example: r₂ = 4.
  1. **a_t** fraction (5/2).
  2. **Speed at the start of the ellipse** 2 decimals (1.26; others 1.15, 1.22, 1.34).
  3. **Δv₁** 2 decimals (0.26; others 0.15, 0.22, 0.34).
  4. **Δv₂** 2 decimals (0.18; others 0.13, 0.17, 0.18).
  kind 1: Earth, from 300 km (r₁ = 6671 km) to geostationary (r₂ = 42,164 km).
  1. **a_t** km, nearest km (24,418; accept 24,417 or 24,418).
  2. **Δv₁** km/s, 2 decimals (2.43).
  3. **Δv₂** km/s, 2 decimals (1.47).
  4. **Total** km/s, 2 decimals (3.90).
  5. **Coast time** hours, 2 decimals (5.27).
  - Slips: Δv as the difference of the circle speeds: "You arrive on the ellipse, moving slower than the outer circle's speed at its far point. Δv₂ is circle speed minus ellipse speed." · coast time as a full period: "You only fly half the ellipse, from near point to far point." · burned backward to go out: "Burn forward to raise the far side. You end up slower in the higher circle, but you get there by speeding up."
- **Oracle:** the formulas above with μ = 1 or μ⊕ = 3.986e14, rounded as stated.
- **Use it:** **Geostationary delivery** project (see above), using `ve` for the propellant. Saves `dv_hohmann`.
- **Deeper:** Hohmann is the cheapest two-burn transfer, and a three-burn bi-elliptic transfer beats it when r₂/r₁ > 11.94. Changing the orbit's plane costs 2v·sin(Δi/2), which is why launch sites near the equator help. Low-thrust spirals, where Δv is the difference of the circle speeds (Edelbaum).

---

## Unit 4 · To Mars

### b2-or-10 · Launch windows
- **You can:** find how long a transfer takes, where the target must be when you leave, and how often the chance comes back.
- **Needs:** b2-or-09, b2-or-03.
- **Tool:** Mission clock, ★ Orbit sandbox.
- **Play:** Earth and another planet circle the Sun. Drag the launch date and a ghost ship flies the transfer ellipse. Launch at the wrong time and it reaches the target's orbit with the planet somewhere else. The phase-angle dial shows the angle between the two planets as the dates roll.
- **Guess:** "Drag the target planet to where it must be at launch for the ship to meet it." The reveal flies the transfer and moves the planet with it.
- **Name it:** The transfer is half an ellipse, so the ship arrives 180° around from where it left. During the flight the target moves on, so at launch it must already be ahead by the right angle. That alignment comes back once every synodic period. Rules (Sun, AU, years): t = ½·a_t^(3/2); the target's period is T₂ = r₂^(3/2); the lead angle is φ = 180° − 360°·t/T₂; the synodic period is S = 1/|1 − 1/T₂| years for a launch from Earth.
- **Work it:** kind 0 (index < 3): synodic period only, with T₂ ∈ {2, 3, 4, 8} years; S as a fraction of a year (2, 3/2, 4/3, 8/7). kind 1: target Venus (0.723 AU), Jupiter (5.203 AU) or Saturn (9.537 AU). Example: Jupiter.
  1. **Transfer time** days, nearest day (998; Venus 146, Saturn 2208).
  2. **Target's period** years, 2 decimals (11.87; Venus 0.61, Saturn 29.45).
  3. **Lead angle** degrees, nearest degree, with a tap for Ahead / Behind (97 ahead; Venus 54 behind; Saturn 106 ahead).
  4. **Windows repeat every** days, nearest day (399; Venus 583, Saturn 378).
  - Slips: φ = 360°·t/T₂: "That's how far the target moves during the flight. You meet it 180° around, so subtract that from 180°." · S = T₂ − T₁: "Windows repeat when Earth laps the target (or the target laps Earth). Rates subtract: 1/S = |1/T₁ − 1/T₂|." · treated a negative φ as an error: "A negative lead means the target must be behind Earth. That happens for inner planets, which move faster."
- **Oracle:** a_t = (1 + r₂)/2; t = 0.5·a_t^1.5·365.25; φ = 180 − 360·t/T₂; S = 365.25/|1 − 1/T₂|.
- **Use it:** For Mars, find the lead angle and the gap between windows (44° ahead, 780 days, about 26 months). Saves `phase_mars`.
- **Deeper:** Lambert's problem: find the orbit between two points in a given time. Porkchop plots map the departure energy over every launch and arrival date. Real orbits are eccentric and tilted, so real windows differ from the circle model by weeks, and some windows are much cheaper than others.

### b2-or-11 · Leaving and arriving: patched conics
- **You can:** find the burn from a parking orbit that sends a ship off with a chosen leftover speed, and the burn to be captured at the other end.
- **Needs:** b2-or-06, b2-or-09.
- **Tool:** Departure view, ★ Orbit sandbox, Units and constants.
- **Play:** A zoomed Earth with the 300 km parking orbit. Drag the burn size: the orbit stretches, then opens into a hyperbola, and the arrow at its far end shows the leftover speed v∞. Zoom out and the ship is handed to the Sun's frame with v∞ added to Earth's own speed.
- **Guess:** "To leave Earth with 3 km/s to spare, do you need a burn of 3 km/s, more, or less?" Pick one. The reveal sizes the burn (3.61 km/s, only a little more, thanks to starting deep in Earth's gravity).
- **Name it:** Near a planet, only that planet's gravity matters, and far away only the Sun's. Stitch the pieces together at the edge of the planet's pull. To leave with leftover speed v∞, you need escape speed plus v∞ in energy terms, which is much less than adding the speeds. Rules: v_burn = √(v∞² + v_esc²) with v_esc = √(2μ/r), and Δv = v_burn − √(μ/r). Arriving works the same way in reverse with the target's μ.
- **Work it:** kind 0: leaving Earth from r = 6671 km, v∞ ∈ {2.5, 3.0, 3.5} km/s. Index < 3: kind 0. Example: v∞ = 3.0.
  1. **Escape speed at the parking orbit** km/s, 2 decimals (10.93).
  2. **Speed needed after the burn** 2 decimals (11.34; 2.5: 11.21, 3.5: 11.48).
  3. **Δv** 2 decimals (3.61; 2.5: 3.48, 3.5: 3.75).
  kind 1: arriving at Mars into a 400 km circular orbit (r = 3790 km), v∞ ∈ {2.0, 2.65, 3.0}. Example: v∞ = 2.65.
  1. **Escape speed there** 2 decimals (4.75).
  2. **Circular speed there** 2 decimals (3.36).
  3. **Capture Δv** 2 decimals (2.08; 2.0: 1.80, 3.0: 2.26).
  - Slips: Δv = v∞: "The burn happens deep in Earth's gravity, where speed is worth more energy. Combine v∞ and escape speed with squares." · added v∞ + v_esc: "Energies add, not speeds: v_burn² = v∞² + v_esc²." · subtracted escape speed instead of circular speed: "You start in the parking orbit, moving at circular speed. Subtract that."
- **Oracle:** √(v∞² + 2μ/r) − √(μ/r), in km/s to 2 places.
- **Use it:** Your departure burn for Mars, from `v_LEO` and the transfer's v∞. Saves `dv_depart` and `dv_capture`.
- **Deeper:** The sphere of influence r_SOI = a(m/M)^(2/5) (about 925,000 km for Earth) and how much error patching introduces. The Oberth effect made exact. Aerocapture: braking in Mars's air instead of burning. Gravity assists: in the planet's frame the speed in and out is the same, but the direction turns by δ with sin(δ/2) = 1/(1 + r_p·v∞²/μ), so in the Sun's frame the ship gains up to 2v∞·sin(δ/2).

### b2-or-12 · The Mars plan
- **You can:** plan a full Earth-to-Mars trip: burns, timing, flight time and propellant.
- **Needs:** b2-or-10, b2-or-11, b2-or-08.
- **Tool:** ★ Orbit sandbox, Burn planner, Mission clock, Mission card.
- **Play:** All the pieces on one screen. Earth and Mars circle the Sun, the ship sits in its parking orbit, and the mission card fills in as you set each piece. Drag the launch date until the phase dial reads the right angle, fire, and watch the ship coast 259 days to meet Mars.
- **Guess:** "Before computing: is the total Δv from low Earth orbit to low Mars orbit closer to 3, 6 or 12 km/s?" Pick one. The reveal fills the card's total (5.67 km/s).
- **Name it:** A Hohmann trip to Mars is three nested problems: leave Earth onto the Sun-centered transfer, coast half an ellipse from 1 AU to 1.524 AU, and get captured by Mars. The Sun-frame burns become the v∞ at each end. Rules: the Sun-frame Δv₁ and Δv₂ from or-09 with μ☉, the window from or-10, the planet burns from or-11, and the propellant from or-08.
- **Work it:** kind 0 (index 0 only, the reference mission): parking orbit 300 km, Mars orbit 400 km, I_sp 450 s.
  1. **Sun-frame Δv₁ (= v∞ leaving Earth)** km/s, 2 decimals (2.95).
  2. **Sun-frame Δv₂ (= v∞ arriving at Mars)** km/s, 2 decimals (2.65).
  3. **Flight time** days, nearest day (259).
  4. **Mars's lead at launch** degrees, nearest degree (44).
  5. **Departure burn from 300 km** km/s, 2 decimals (3.59).
  6. **Capture burn into 400 km** km/s, 2 decimals (2.08).
  7. **Total Δv** km/s, 2 decimals (5.67).
  8. **Propellant fraction** percent, 1 decimal (72.3).
  kind 1 (index ≥ 1): parking altitude h₁ ∈ {200, 300, 400} km, Mars altitude h₂ ∈ {300, 400, 1000} km, I_sp ∈ {350, 380, 450} s; same steps (steps 1 to 4 don't change). At index 1 and 2, only h₁ changes from the reference mission (200 km, then 400 km).
  - Slips: used Δv₁ itself as the departure burn: "2.95 km/s is the speed you need relative to Earth once you're free of it. From the parking orbit, the burn is √(v∞² + v_esc²) − v_circ." · added the four burns (2.95 + 2.65 + 3.59 + 2.08): "The Sun-frame burns are not extra. They're delivered by the departure and capture burns as v∞." · used 1.524 AU in km without converting: "μ☉ is in m³/s². Convert AU to meters: 1 AU = 1.496 × 10¹¹ m."
- **Oracle:** the chain above with the stated constants: Δv₁, Δv₂ from μ☉, r₁ = 1 AU, r₂ = 1.524 AU; t = π√(a_t³/μ☉); φ = 180 − 360·t/T_Mars; dep = √(Δv₁² + 2μ⊕/r) − √(μ⊕/r); cap = √(Δv₂² + 2μ♂/r) − √(μ♂/r); fraction = 1 − e^(−total/v_e).
- **Use it:** The build: save the **mission card** (`mission`) to the Notebook with every number live. Then change one thing (a lower parking orbit, a better engine) and see what it saves.
- **Deeper:** Gravity assists and free-return trajectories. The restricted three-body problem: the Jacobi constant, the five Lagrange points and their stability (L4 and L5 are stable when the big mass is more than about 25 times the small one), and halo orbits. Low-energy transfers along the "interplanetary transport network". Real missions solve Lambert's problem on porkchop plots, and their burns land within about 10 to 30 percent of this circle model, depending on the window.
