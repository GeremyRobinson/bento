# Bento² · Relativity (code `re`, 12 lessons)

**What it is:** Einstein's discovery that time and space stretch depending on how fast you move and how strong gravity is. It is why GPS satellites need correcting every day.

Role: branch, track 9. Needs: linear algebra (track `la`, mainly b2-la-05 and b2-la-06); from Bento, square roots and units (`g11-radical`, `g12-unit`) and Taylor polynomials (`bc-taylor`) help. Orbits (`or`) helps from b2-re-09 on. Nothing is locked. The plain path is college level (the special relativity chapter of a first university physics course, plus weak-field gravity). The Deeper layers reach upper-undergraduate and graduate ideas: the Lorentz group SO⁺(1, 3) and ΛᵀηΛ = η, rapidity and hyperbolic rotations, Thomas–Wigner rotation, four-vectors and invariant mass, the Minkowski metric and proper time as a path integral, maximal aging, Rindler observers, the weak-field metric g₀₀ ≈ 1 + 2Φ/c², the Schwarzschild metric, geodesics and Christoffel symbols, the Einstein field equations, and the eccentricity and Sagnac corrections real GPS receivers make.

## The build: the GPS checker

**Work out why GPS needs relativity, to the microsecond.** A GPS satellite's clock runs slow because it moves fast (special relativity) and fast because it sits high above Earth's gravity (general relativity). The learner computes both from scratch, finds the net drift of about **+38.5 microseconds per day**, turns it into a map error of about **11.5 km per day**, and finds the orbit radius where the two effects cancel exactly (1.5 Earth radii). Built in the GPS checker; saved to the Notebook as the track's build.

What each unit adds:

| Unit | Lessons | What it adds to the build |
|---|---|---|
| 1 · Light sets the rules | 01 to 03 | Timing is distance: 1 nanosecond of clock error is 30 cm of map error (`c`). Moving clocks run slow by γ, from the light clock (`gamma`). |
| 2 · Spacetime | 04 to 07 | Clocks are read inside spacetime: the Lorentz boost as a matrix, the interval everyone agrees on, and proper time along a path. The twin trip is the GPS problem in miniature: two clocks, two paths, different ages (`boost`, `twin`). |
| 3 · Energy and mass | 08 to 09 | E = mc², then the slow-speed rule: at everyday and orbital speeds the slowdown is v²/2c². The satellite's speed part: **−7.2 μs per day** (`sr_drift`). |
| 4 · Gravity and GPS | 10 to 12 | Higher clocks run fast (gh/c² near the ground, then the full GM/c² (1/R − 1/r)). The height part: **+45.7 μs per day** (`gr_drift`). The build adds them: **+38.5 μs per day**, 11.5 km of error per day, and the factory frequency offset (`gps_net`). |

## Units

1. **Light sets the rules:** b2-re-01 to b2-re-03
2. **Spacetime:** b2-re-04 to b2-re-07
3. **Energy and mass:** b2-re-08 to b2-re-09
4. **Gravity and GPS:** b2-re-10 to b2-re-12

## Small projects

| After | Project | What the learner makes and keeps | Shelf |
|---|---|---|---|
| b2-re-03 | **Your light clock** | Pick a speed on the light clock; it draws the zigzag, prints γ, and shows how far a muon gets at that speed before and after relativity. | `gamma` |
| b2-re-06 | **Twin trip planner** | Pick a star and a cruise speed. The planner draws both worldlines on the spacetime diagram and prints both ages on return. | `twin` |
| b2-re-09 | **Clocks that travel** | Three clocks: an airliner (250 m/s), the space station (7.67 km/s, about 400 km up) and a GPS satellite (3.873 km/s). Each shows how much it falls behind a ground clock per day from speed alone. | `sr_drift` |
| b2-re-12 | **The build: GPS checker** | Your satellite at any orbit radius, with the speed bar, the height bar, the net drift, the map error after a day, and the cancel radius marked. | `gr_drift`, `gps_net` |

## Constants and rounding (used by every lesson)

Units and constants holds these under these names, matching track `or`:
- c = 299,792,458 m/s (exact), shown as 299,792 km/s, and as 0.2998 m per nanosecond or 0.2998 km per microsecond
- Earth: μ⊕ = GM⊕ = 3.986 × 10¹⁴ m³/s², mean radius R⊕ = 6371 km, surface gravity g₀ = 9.81 m/s²
- GPS orbit: altitude 20,200 km, so r = 26,571 km (circular)
- 1 day = 86,400 s; muon mean life τ_μ = 2.2 μs

**Rounding rule.** Oracles compute with these constants, carry full precision between steps (the Number shelf stores unrounded values) and round only the typed answer. Answers within one unit of the last stated place are accepted. One exception: b2-re-03 uses c = 0.3 km per μs, rounded and stated on screen, so its numbers stay friendly. Lessons 01 to 08 use units where c = 1 (years and light-years, or MeV) whenever they can, so most answers there are exact fractions.

## New for Development

Toolbox tools to build (names from `bento2/research/toolbox.md`, track 7):
- **★ Spacetime diagram.** Time up, space across, c = 1 so light runs at 45°. Drag a traveler's speed β: their time axis tilts to slope 1/β and their space axis (their "now") tilts to slope β, toward the light line. Needs: draggable events with both (ct, x) and (ct′, x′) readouts; calibration hyperbolas (ct)² − x² = 1, 4, 9 … so tick marks on tilted axes line up; worldlines with tick marks every unit of proper time; a light-cone shade for one event (future, past, elsewhere); a "boost" button that sends the current β to the Matrix pad as the 2×2 boost (05, 07).
- **Light clock.** Two mirrors on a train with a speed slider; the pulse zigzags; the right triangle with legs cτ and vt and hypotenuse ct is labeled live. A ground clock and a train clock tick side by side. Muon mode: a shower from 10 km up, with the lab view and the muon's view (contracted atmosphere) as a toggle (03).
- **Twin trip planner.** Star distance and speed sliders (with the friendly speeds 3/5, 4/5, 12/13 marked); both worldlines drawn; ages on return; a turnaround marker where the traveler's "now" line jumps.
- **Speed adder.** Two speed sliders, the result bar that approaches but never reaches 1; Galilean ghost bar for comparison; rapidity mode where the speeds become lengths that simply add.
- **Gravity well** (Grapher 3D, shared with `mv` and `or`). A surface z = −1/r around Earth, with clocks placed at any radius; each clock's tick rate shows as a ring that pulses faster when higher. Rocket mode (equivalence): two clocks at the top and bottom of an accelerating rocket, with pulses sent up and the spacing readout (10).
- **GPS checker (the build).** Orbit-radius slider from 1 to 7 Earth radii with presets (space station, GPS, Galileo, geostationary); two bars, speed (−) and height (+), and their net in μs per day; a map where "you are here" drifts by the map error as hours pass; the cancel radius 1.5 R⊕ marked; the factory frequency readout 10.23 MHz × (1 − net fraction).

New pictures, mapped to toolbox homes:
- **Energy triangle** (Vector board): legs mc² and pc, hypotenuse E, with γ and β read off as ratios (08).
- **Event pair** (inside Spacetime diagram): two flashes and the traveler's "now" line sweeping across them as β changes, with which-came-first flipping (04).
- **Small-speed curve** (Grapher 2D): γ against β with its parabola 1 + β²/2 overlaid, and a zoom to everyday speeds (09).

Cross-track links: `la` (05, 07, Deeper 11 and 12), `or` (09, 11, 12), `mv` (Deeper 11), `de` (Deeper 11), `qu` (Deeper 08), `pr` (Deeper 12).

Shelf names this track creates: `c`, `gamma`, `boost`, `twin`, `sr_drift`, `gr_drift`, `gps_net`.

---

## Unit 1 · Light sets the rules

### b2-re-01 · Light is the speed everyone agrees on
- **You can:** turn distances into light-travel times, and clock errors into map errors.
- **Needs:** none (`g12-unit` helps).
- **Tool:** ★ Spacetime diagram (light lines); Units and constants.
- **Play:** A lamp flashes while you ride past at a speed you drag. Thrown balls look faster or slower depending on your speed, but the flash's lines on the spacetime diagram stay at 45° for everyone.
- **Guess:** You fly toward the lamp at half light speed. Pick one: you measure its light at 0.5c, c or 1.5c. The reveal runs the measurement in your frame and in the lamp's frame, and both read c.
- **Name it:** Light in empty space moves at the same speed c for everyone moving steadily, however fast they go, and the laws of physics are the same for all of them. Everything else in this track follows from those two rules. Since c is fixed, a time is a distance: GPS measures how far away each satellite is by timing its signal.
  t = d / c; c = 299,792 km/s ≈ 0.3 m per nanosecond
- **Work it:** d in km from {384,400 (the Moon), 20,200 (GPS altitude), 35,786 (geostationary altitude), 149,600,000 (the Sun)} or a whole number from 1,000 to 50,000; clock error e from 1 to 100 ns, or 1 to 10 μs. Time in seconds to 3 decimal places (or milliseconds to 1 decimal place for GPS distances); error in meters to 1 decimal place. Early: the Moon and GPS only. Example: d = 20,200 km, e = 10 ns.
  1. **Light time** ms: 67.4.
  2. **Error from 10 ns** m: 3.0.
  3. **Error from 1 μs** m: 299.8.
  - Moon example: 384,400 / 299,792 = 1.282 s. Sun: 499.0 s, about 8.3 minutes.
  - Slips: divided c by d "Time is distance over speed: d / c." · typed 0.067 when asked in ms "That's seconds. 0.0674 s is 67.4 ms." · 1 μs as 0.3 m "A microsecond is 1,000 nanoseconds, so 1,000 × 0.2998 m: about 300 m."
- **Oracle:** `d / 299792.458` (s), × 1000 when the step asks for ms; `e_ns * 0.299792458` (m).
- **Use it:** A GPS receiver times signals from four satellites. If a satellite clock is 1 μs off, your position is off by about 300 m. Saves `c`, and starts the build's map-error readout.
- **Deeper:** Maxwell's equations predict waves at c = 1/√(μ₀ε₀) without saying relative to what. The Michelson–Morley null result. Why Galilean addition (u + v) fails for light, and why the meter has been defined from c since 1983.

### b2-re-02 · The light clock: moving clocks run slow
- **You can:** find the time-stretch factor γ for a speed and use it to compare two clocks.
- **Needs:** b2-re-01, `g11-radical`.
- **Tool:** Light clock; ★ Spacetime diagram.
- **Play:** A light pulse bounces between two mirrors on a train. Drag the train's speed: from the ground the pulse zigzags on a longer path, so each tick takes longer, and the ground clock pulls ahead of the train clock.
- **Guess:** At 3/5 of light speed, drag a slider to how many ground seconds pass for each train second. The reveal draws the triangle: legs 4 and 3, hypotenuse 5, so 5/4.
- **Name it:** Light goes up and down in the train in time τ, but along a slanted path in ground time t. Pythagoras on that triangle gives the stretch factor γ, which is 1 at rest and grows without limit near c. A moving clock ticks slow by γ.
  (ct)² = (cτ)² + (vt)²; t = γ τ; γ = 1 / √(1 − β²), β = v / c
- **Work it:** β from {3/5, 4/5, 5/13, 12/13, 8/17, 15/17, 7/25, 24/25, 20/29, 21/29}, so γ is a fraction; τ chosen as a multiple of γ's denominator from 1 to 50 years, so t is whole. Early: β = 3/5 or 4/5. Example: β = 3/5, traveler's clock τ = 8 years.
  1. **β²** fraction: 9/25.
  2. **√(1 − β²)** fraction: 4/5.
  3. **γ** fraction: 5/4.
  4. **Ground time t** whole: 10.
  - Slips: forgot the square root (γ = 25/16) "γ is 1 over the square root of 1 − β². Here √(16/25) = 4/5." · divided instead (t = 6.4) "The moving clock reads less, so the ground's number is the bigger one: t = γτ." · used β, not β² (1 − 3/5) "Speeds enter squared, from Pythagoras: 1 − 9/25."
- **Oracle:** `g = 1/sqrt(1 - b^2)` as an exact fraction; `g * tau`.
- **Use it:** A probe to a star 12 light-years away at 12/13 of light speed: ground time 13 years, probe clock 13 / (13/5) = 5 years.
- **Deeper:** The effect is symmetric: each observer sees the other's clock slow. That is only consistent because they disagree about "now" (b2-re-04). Experimental checks: particle accelerator lifetimes and the 1971 airliner clocks (b2-re-09).

### b2-re-03 · Moving rulers shrink: the muon's trip
- **You can:** use γ to predict how far a fast particle gets, from both points of view.
- **Needs:** b2-re-02.
- **Tool:** Light clock (muon mode); ★ Spacetime diagram.
- **Play:** Muons made 10 km up rain down. Drag their speed: in the lab view their clocks slow and they get further; flip to the muon's view and the atmosphere itself shrinks toward them.
- **Guess:** A muon lives 2.2 μs on its own clock. At 12/13 of light speed, place a marker on the height bar where you think it decays (on average). The reveal runs it, with and without relativity.
- **Name it:** In the lab the muon's clock runs slow by γ, so it lives γτ and travels further. In the muon's frame its clock is normal, but distances along its motion are shorter by γ. Both views predict the same arrival.
  lab life = γτ; lab distance = v γ τ; contracted length L = L₀ / γ
- **Work it:** β from {3/5, 4/5, 12/13, 24/25}; τ = 2.2 μs; c = 0.3 km per μs (rounded, stated on screen); L₀ in {10, 15} km. Times to 2 decimal places, distances to 2 decimal places. Early: β = 3/5 or 4/5. Example: β = 12/13.
  1. **γ** decimal: 2.6.
  2. **Lab life** μs: 5.72.
  3. **Distance with relativity** km: 1.58.
  4. **Distance without** km: 0.61.
  5. **The 10 km atmosphere in the muon's frame** km: 3.85.
  - Slips: multiplied L₀ by γ "In the muon's frame the atmosphere rushes past, so it's shorter: divide by γ." · used c, not v, for distance "The muon moves at v = βc: 12/13 × 0.3 km per μs." · stretched the muon's own life "On its own clock the muon always lives 2.2 μs. The stretch is what the lab sees."
- **Oracle:** `g = 1/sqrt(1-b^2); [g*2.2, b*0.3*g*2.2, b*0.3*2.2, L0/g]`.
- **Use it:** Real cosmic-ray muons move at about 0.998c, so γ ≈ 15.8 and they travel about 10.4 km on average: many reach the ground, which is why detectors in basements count them. **Project: Your light clock** (saves `gamma`).
- **Deeper:** The ladder (barn) paradox and how simultaneity resolves it. Why there is no contraction across the motion. Length contraction of charge spacing in a current is where magnetism comes from.

## Unit 2 · Spacetime

### b2-re-04 · Spacetime diagrams and the meaning of "now"
- **You can:** read a spacetime diagram and find when two events happen for a moving traveler.
- **Needs:** b2-re-02.
- **Tool:** ★ Spacetime diagram (event pair).
- **Play:** Two flashes go off at the same time at x = 0 and x = 4 light-years. Drag the traveler's speed: their "now" line tilts, and the two flashes stop being simultaneous for them.
- **Guess:** The traveler heads toward +x at 3/5 of light speed. Pick one: for them, the near flash comes first, the far flash comes first, or they're still at the same time. The reveal sweeps their "now" line upward through both events.
- **Name it:** A traveler's time axis is their worldline, tilted toward the light line, and their "now" line tilts the same amount from the other side. Events at the same time for you need not be at the same time for them. Using units where c = 1:
  Δt′ = γ(Δt − β Δx), Δx′ = γ(Δx − β Δt)
- **Work it:** β from {3/5, 4/5}; event pairs with Δt, Δx whole numbers from −8 to 8, chosen as multiples of 4 (β = 3/5) or 3 (β = 4/5), so answers are whole. Early: Δt = 0. Example: Δt = 0, Δx = 4, β = 3/5.
  1. **γ** fraction: 5/4.
  2. **Δt′** whole: −3.
  3. **Δx′** whole: 5.
  4. **Which comes first for the traveler** tap: the far flash.
  - Slips: + β Δx "The traveler moves toward +x, so it's Δt − βΔx." · forgot γ (typed −12/5) "Both pieces get multiplied by γ = 5/4." · "simultaneous for everyone" "Equal times on the ground give Δt′ = −γβΔx, which is only 0 if the flashes are at the same place."
- **Oracle:** `[g*(dt - b*dx), g*(dx - b*dt), sign(g*(dt - b*dx))]` (the sign gives which flash comes first).
- **Use it:** Two GPS satellites on opposite sides of Earth send "time = noon" together by ground clocks. A receiver moving fast would disagree about whether they were sent together; GPS fixes one frame, an Earth-centered frame that does not rotate, to define "now".
- **Deeper:** Causality: events inside each other's light cones keep their order for everyone; events outside ("elsewhere") can swap. The light cones make spacetime a partial order. Why faster-than-light signals would allow sending messages into your own past.

### b2-re-05 · The Lorentz boost is a matrix
- **You can:** change frames with a 2×2 matrix and check it keeps the interval.
- **Needs:** b2-re-04, b2-la-05, b2-la-06.
- **Tool:** ★ Spacetime diagram; Matrix pad.
- **Play:** Drag β and the diagram's grid squeezes along the light lines: one diagonal stretches by some factor, the other shrinks by the same factor. The boost's matrix updates in the Matrix pad.
- **Guess:** Drag a point to where you think the event (ct, x) = (5, 3) lands for a traveler at 3/5 of light speed. The reveal applies the matrix: it lands on the traveler's own time axis.
- **Name it:** The boost is linear, so it is a matrix acting on (ct, x). Its determinant is 1, so it keeps areas, and it keeps (ct)² − x² the same, the way a turn keeps x² + y².
  Λ = [[γ, −βγ], [−βγ, γ]]; (ct′, x′) = Λ (ct, x); det Λ = γ²(1 − β²) = 1
- **Work it:** β from {3/5, 4/5, 5/13, 12/13}; (ct, x) with whole entries from −13 to 13, multiples of the denominator of γ (4, 3, 12 or 5), so answers are whole. From index 4, also undo a boost (β → −β). Early: β = 3/5. Example: β = 3/5, (ct, x) = (5, 3).
  1. **γ and βγ** two fractions: 5/4, 3/4.
  2. **ct′** whole: 4.
  3. **x′** whole: 0.
  4. **(ct)² − x² before and after** two wholes: 16, 16.
  5. **det Λ** whole: 1.
  - Slips: Galilean answer (x′ = x − βct = 0, t′ = t = 5) "Time changes too: ct′ = γ(ct − βx) = 5/4 × 16/5 = 4." · plus signs off the diagonal "The traveler moves toward +x, so both off-diagonal entries are −βγ." · checked x² + (ct)² "A boost keeps the difference (ct)² − x², not the sum."
- **Oracle:** `matmul([[g, -b*g], [-b*g, g]], [ct, x])`.
- **Use it:** Save the boost for 3/5 as `boost`. Undo it with β = −3/5 in the Matrix pad and check that the product is the identity: the inverse of a boost is the boost the other way.
- **Deeper:** Write γ = cosh w, βγ = sinh w: a boost is a hyperbolic rotation by the rapidity w. In 4D, boosts and turns make the Lorentz group SO⁺(1, 3), the matrices with ΛᵀηΛ = η for η = diag(1, −1, −1, −1), just as turns are QᵀQ = I (links b2-la-16). Upper and lower indices (contravariant and covariant) are the change-of-basis story of b2-la-12.

### b2-re-06 · The interval and proper time
- **You can:** find the one time every observer agrees on, and use it to solve the twin trip.
- **Needs:** b2-re-05.
- **Tool:** ★ Spacetime diagram (tick marks); Twin trip planner.
- **Play:** Two events on the diagram. Drag β: their time and distance gaps change, but a calibration hyperbola through the second event never moves. Then bend a worldline: the straight one between two events always has the most ticks.
- **Guess:** One twin stays home; the other flies 3 light-years out and back at 3/5 of light speed. Drag a slider for the traveler's age gain when the home twin has aged 10 years. The reveal counts the ticks on both worldlines.
- **Name it:** The interval s² = (cΔt)² − Δx² is the same for everyone. When it's positive (timelike), its square root is the proper time: what a clock that goes straight between the two events reads. A bent path reads less. When it's negative (spacelike), no clock can get from one to the other, and √(−s²) is their proper distance instead.
  s² = (cΔt)² − Δx²; τ = √(s²) / c; s² > 0 timelike, = 0 lightlike, < 0 spacelike
- **Work it:** (cΔt, Δx) from scaled Pythagorean pairs: (5, 3), (5, 4), (13, 5), (13, 12), (17, 8), (25, 7), (10, 6), (10, 8), with the sign of Δx random; plus lightlike pairs (k, k) and spacelike pairs, the same pairs with the entries swapped, like (3, 5). Twin trips from index 3: β from the γ list in b2-re-02, and D in light-years a multiple of β's numerator (3, 4, 12, …), up to 24 ly, so both ages are whole. Early: (5, 3) and (5, 4). Example: (cΔt, Δx) = (5, 3).
  1. **s²** whole: 16.
  2. **Kind** tap: timelike.
  3. **τ** whole: 4.
  - Lightlike pairs: step 3 is 0 (light's own clock never ticks). Spacelike pairs: step 3 becomes **Proper distance** √(−s²), which is 4 for (3, 5).
  - Twin example: D = 3 ly, β = 3/5. **Home time** 2 × 3 / (3/5) = 10 years; **traveler time** 10 / (5/4) = 8 years; **difference** 2 years.
  - Slips: added the squares (typed 34) "Spacetime's rule has a minus sign: 25 − 9." · τ = cΔt − Δx (typed 2) "Square first, subtract, then take the root: √(25 − 9) = 4." · spacelike for s² > 0 "Positive s² means time wins: a clock can travel between them, so it's timelike."
- **Oracle:** `s2 = t^2 - x^2; s2 > 0 ? sqrt(s2) : s2 == 0 ? 0 : sqrt(-s2)`; twin: `2*D/b`, `2*D/b/g`.
- **Use it:** **Project: Twin trip planner.** Pick a star and a speed; both ages on return are saved as `twin`. This is the GPS question in miniature: two clocks, two paths through spacetime, two readings.
- **Deeper:** Proper time as the length of a path, τ = ∫ √(1 − v²/c²) dt, with the Minkowski metric ds² = c²dt² − dx² − dy² − dz². Straight worldlines maximize τ (maximal aging), the reverse of the triangle inequality. The traveler's turnaround: their "now" line swings across the home twin's worldline.

### b2-re-07 · Adding speeds near light
- **You can:** add two speeds the relativistic way and see why the result stays below c.
- **Needs:** b2-re-05, b2-la-06.
- **Tool:** Speed adder; Matrix pad.
- **Play:** A ship at u fires a probe forward at v. Drag both: the plain sum bar shoots past c, while the true result bar slows down as it gets close and never reaches it.
- **Guess:** 0.8c plus 0.8c. Drag the result bar to your guess. The reveal shows 40/41, about 0.976c.
- **Name it:** Speeds don't simply add. Combining two boosts is multiplying two boost matrices, and the product is the boost for this speed. At small speeds the bottom is about 1 and you get u + v back.
  u ⊕ v = (u + v) / (1 + u v / c²); with c = 1: (u + v) / (1 + u v)
- **Work it:** u, v from {1/2, 1/3, 2/3, 1/4, 3/4, 3/5, 4/5, 1/5}; answers as fractions. From index 4, also check with matrices: multiply two boosts in the Matrix pad and read β = (βγ)/γ off the product. Early: u = v = 1/2. Example: u = v = 3/5.
  1. **Top** fraction: 6/5.
  2. **Bottom** fraction: 34/25.
  3. **u ⊕ v** fraction: 15/17.
  4. **Faster than light?** tap: no.
  - Matrix check: [[5/4, −3/4], [−3/4, 5/4]] squared is [[17/8, −15/8], [−15/8, 17/8]], so γ = 17/8 and β = 15/17.
  - Slips: plain sum (6/5) "Above 1 means faster than light. Divide by 1 + uv." · 1 − uv on the bottom (gives 15/8) "The bottom is 1 plus uv, which makes the result smaller, not bigger." · flipped the fraction "Speed is the top over the bottom: (6/5) ÷ (34/25)."
- **Oracle:** `frac(u + v, 1 + u*v)`.
- **Use it:** Light itself: 1 ⊕ v = (1 + v)/(1 + v) = 1, so a ship's headlight still moves at c. Two beams of particles at 0.9c head-on close at 1.8/1.81, about 0.9945c, as either one sees it.
- **Deeper:** Rapidities add: w = artanh β, and w(u ⊕ v) = w(u) + w(v), which is why boosts form a one-parameter group (links b2-la-06). Two boosts in different directions are a boost and a turn: the Thomas–Wigner rotation. The relativistic Doppler factor √((1 + β)/(1 − β)) (2 at β = 3/5), and Doppler factors multiply.

## Unit 3 · Energy and mass

### b2-re-08 · Energy, momentum and E = mc²
- **You can:** find a particle's energy, momentum and speed from two of them, and turn mass into energy.
- **Needs:** b2-re-05, b2-re-06.
- **Tool:** Vector board (energy triangle); Units and constants.
- **Play:** A right triangle with legs mc² and pc and hypotenuse E. Drag the momentum arrow and watch pc grow, E grow with it, and the speed β = pc / E creep toward 1 but never reach it.
- **Guess:** A particle with rest energy 3 MeV and momentum 4 MeV/c. Drag a slider for its total energy. The reveal draws the 3-4-5 triangle.
- **Name it:** Energy and momentum together form an arrow in spacetime whose length, the rest energy mc², is the same for everyone. At rest, the energy is all mass: E = mc². A massless particle like light has E = pc.
  E² = (pc)² + (mc²)²; E = γ mc²; β = pc / E; kinetic energy = E − mc²
- **Work it:** (mc², pc, E) from Pythagorean triples (3, 4, 5), (5, 12, 13), (8, 15, 17), (7, 24, 25), (20, 21, 29) and their legs swapped, in MeV, sometimes scaled by 2 or 10; two of the three shown. Early: (3, 4, 5). Example: mc² = 3 MeV, pc = 4 MeV.
  1. **E** MeV: 5.
  2. **γ** fraction: 5/3.
  3. **β** fraction: 4/5.
  4. **Kinetic energy** MeV: 2.
  - Slips: E = mc² + pc (typed 7) "Energies combine like the sides of a right triangle: √(9 + 16)." · β = mc² / E "Speed comes from momentum: β = pc / E. A particle at rest has pc = 0 and β = 0." · kinetic energy as ½mv² "At this speed ½mv² is wrong. Kinetic energy is E − mc², here 2 MeV."
- **Oracle:** `E = sqrt(m^2 + p^2); [E, frac(E, m), frac(p, E), E - m]`, with m and p taken from the generating triple even when they aren't shown.
- **Use it:** The Sun shines 3.828 × 10²⁶ W. Dividing by c² gives the mass it turns into light each second: 4.26 × 10⁹ kg, about 4 million tonnes. One gram of mass is 9.0 × 10¹³ J, about 21.5 kilotons of TNT.
- **Deeper:** The four-momentum (E/c, p) and its invariant length. Invariant mass of a system: a box of hot gas weighs more. Threshold energy: making an antiproton by smashing protons into a still target needs a kinetic energy of 6 m_p c² ≈ 5.6 GeV. Helium-4 weighs about 0.75% less than its parts; that missing mass is the energy fusion releases. The Dirac equation, where relativity meets quantum (links b2-qu-05, the Pauli matrices).

### b2-re-09 · Slow speeds: the v²/2c² rule
- **You can:** find how much a moving clock falls behind per day at everyday and orbital speeds.
- **Needs:** b2-re-02, `bc-taylor`; b2-or-02 (circular orbit speed) helps.
- **Tool:** Grapher 2D (small-speed curve); Units and constants.
- **Play:** The curve γ against β with the parabola 1 + β²/2 laid over it. Drag a speed marker along the β axis: the readouts γ − 1 and β²/2 track each other, and as you zoom toward everyday speeds they become impossible to tell apart.
- **Guess:** A space station clock (about 400 km up) moves at 7.67 km/s. Drag a slider for how many microseconds per day it loses to a ground clock: 0.03, 3, 28 or 280. The reveal runs a day at 10⁶ times speed.
- **Name it:** For speeds far below c, γ is almost exactly 1 + β²/2, so a moving clock loses the fraction v²/2c² of every second. Over a day that adds up to something measurable.
  γ ≈ 1 + v² / (2c²); loss per day = (v² / 2c²) × 86,400 s; with v in km/s: ≈ 0.4807 v² μs per day
- **Work it:** v in km/s from {7.67 (space station, about 400 km up, r = 6,771 km), 3.873 (GPS, from r = 26,571 km), 3.075 (geostationary), 1.022 (the Moon)} or 1.00 to 8.00 km/s; airliner 0.25 km/s answered in ns per day. v² to 2 decimal places, the fraction v²/2c² as a number × 10⁻¹⁰ to 2 decimal places, loss per day in μs to 1 decimal place. Early: v whole. Example: v = 7.67 km/s.
  1. **v²** km²/s²: 58.83.
  2. **v² / 2c²** × 10⁻¹⁰: 3.27.
  3. **Loss per day** μs: 28.3.
  - Slips: forgot the ½ (typed 56.6) "The rule is v² over 2c²: half the square of β." · didn't square v "The loss grows with the square of the speed: double the speed, four times the loss." · used 3,600 or 24 "A day is 86,400 seconds."
- **Oracle:** `v^2 / (2 * 299792.458^2) * 86400e6` (μs).
- **Use it:** **Project: Clocks that travel.** Airliner 30.0 ns per day, space station 28.3 μs per day, GPS satellite 7.2 μs per day. The GPS number is the speed half of the build: saved as `sr_drift` (−7.2 μs per day, since the satellite clock falls behind).
- **Deeper:** The Taylor series γ = 1 + β²/2 + 3β⁴/8 + … and its error bound (the next term is under 10⁻¹⁹ for GPS). Kinetic energy (γ − 1)mc² ≈ ½mv² + (3/8)mv⁴/c², so Newton's ½mv² is relativity's first term. The 1971 Hafele–Keating test: cesium clocks flown east lost about 59 ns and flown west gained about 273 ns, matching predictions once gravity and Earth's spin were counted.

## Unit 4 · Gravity and GPS

### b2-re-10 · Gravity bends time: higher clocks run fast
- **You can:** find how much faster a clock runs a height h above another near Earth's surface.
- **Needs:** b2-re-09.
- **Tool:** Gravity well (rocket mode); Units and constants.
- **Play:** Two clocks at the top and bottom of a rocket that is speeding up. The bottom clock sends a pulse every second; drag the rocket's acceleration and watch the pulses arrive at the top further apart.
- **Guess:** Pick one: in the accelerating rocket, does the top clock tick faster, slower, or the same as the bottom one? The reveal counts both clocks' ticks over a minute of rocket time.
- **Name it:** Standing still in gravity is the same as speeding up in empty space (the equivalence principle). So a clock higher in gravity ticks faster, by the fraction gh/c². Gravity doesn't just pull: it changes the rate of time.
  higher clock gains gh / c² per second; per day: (g h / c²) × 86,400 s
- **Work it:** h in m from {22.5 (the Harvard tower), 828 (Burj Khalifa), 1,609 (Denver), 8,849 (Everest)} or 100 to 9,000; g = 9.81 m/s². gh/c² as a number × 10⁻¹³ to 2 decimal places, gain per day in ns to 2 decimal places. Early: h = 1,000 or 2,000. Example: h = 1,000 m.
  1. **Which clock runs faster** tap: the higher one.
  2. **g h / c²** × 10⁻¹³: 1.09.
  3. **Gain per day** ns: 9.43.
  - Everest: 83.45 ns per day; Denver: 15.17 ns per day.
  - Slips: the lower clock runs faster "Light climbing out of gravity arrives stretched, so the bottom clock looks slow from the top. Higher clocks run fast." · divided by c, not c² "The fraction is gh/c²: c squared, from the same v²/c² as before." · forgot the day "That's the fraction per second. Multiply by 86,400 s for a day."
- **Oracle:** `9.81 * h / 299792458^2 * 86400e9` (ns).
- **Use it:** A clock on Everest gains 83.45 ns a day on one at sea level; over 70 years that's about 2.13 ms. In 2010 clocks saw the difference for a lift of 33 cm; by 2022, across about a millimeter.
- **Deeper:** Deriving gh/c² from the Doppler shift in the accelerating rocket. The Pound–Rebka experiment (1959), which measured a shift of 2.46 × 10⁻¹⁵ up a 22.5 m tower. In terms of the potential Φ: Δτ/τ = ΔΦ/c². Rindler observers and the horizon behind an accelerating rocket.

### b2-re-11 · Far from Earth: the full gravity shift
- **You can:** find how much faster a clock runs in orbit than on the ground because of gravity alone.
- **Needs:** b2-re-10; b2-or-06 (energy and the −GM/r potential) helps.
- **Tool:** Gravity well (Grapher 3D surface); Units and constants.
- **Play:** The well z = −1/r around Earth with clocks at different radii. Drag a clock outward: its rate keeps rising, but more and more slowly, approaching a ceiling far from Earth.
- **Guess:** Using gh/c² straight up to GPS height (h = 20,200 km) gives about 190 μs per day. Pick one: is the true gain bigger, about the same, or much smaller? The reveal plots gh/c² (a straight line) against the true curve.
- **Name it:** gh/c² only works while g stays the same. Far away, use the gravitational potential −GM/r instead: the rate gain is the change in potential over c². Measured from the ground, it can never exceed GM/(c²R).
  gain = (GM / c²)(1/R − 1/r) = (GM / c²R)(1 − R/r); GM/(c²R) = 6.96 × 10⁻¹⁰ for Earth, which is 60.1 μs per day
- **Work it:** r in km from {6,771 (space station), 12,742 (2R), 26,571 (GPS), 29,600 (Galileo), 42,164 (geostationary)} or 7,000 to 45,000. R/r to 4 decimal places, gain in μs per day to 1 decimal place. Early: r = 2R or 3R. Example: r = 26,571 km.
  1. **R/r** 0.2398.
  2. **1 − R/r** 0.7602.
  3. **Gain per day** μs: 45.7.
  - Others: 2R gives 30.1, space station 3.6, Galileo 47.2, geostationary 51.1.
  - Slips: used gh/c² with h = 20,200 km (typed about 190) "g gets weaker with height, so gh overcounts. Use 1 − R/r." · 1/r − 1/R (negative) "The higher clock runs faster, so the gain is positive: 1/R − 1/r." · used r as the altitude "r is measured from Earth's center: 6371 + altitude."
- **Oracle:** `3.986e14 / 299792458^2 * (1/6.371e6 - 1/(r*1e3)) * 86400e6`.
- **Use it:** The height half of the build: GPS clocks gain 45.7 μs per day. Saves `gr_drift`. Check: for a small height, 1 − R/r ≈ h/R and GM/R² = g, so this is gh/c² again.
- **Deeper:** Gravity is the downhill slope of the potential: the pull is −∇Φ, of size dΦ/dr = GM/r² (links b2-mv-12, the gradient). The weak-field metric ds² = (1 + 2Φ/c²)c²dt² − (1 − 2Φ/c²)dx², which gives both this and the next lesson's speed term at once; the metric g_μν is a symmetric 4×4 matrix (links b2-la-15). The Schwarzschild metric, geodesics as straightest paths (the geodesic equation with Christoffel symbols is a second-order differential equation, links b2-de-05, systems), and the Einstein field equations G_μν = (8πG/c⁴)T_μν. The Schwarzschild radius 2GM/c²: 8.87 mm for Earth, 2.95 km for the Sun. Mercury's extra 43″ of perihelion turn per century, and starlight bent by 1.75″ at the Sun's edge (links b2-or-04, orbit shapes).

### b2-re-12 · The build: why GPS needs relativity
- **You can:** find a satellite clock's net drift from both effects, and the map error it would cause.
- **Needs:** b2-re-09, b2-re-11; b2-or-02 (circular orbits) helps.
- **Tool:** GPS checker (the build).
- **Play:** Drag the satellite's orbit radius from just above the ground to beyond geostationary. The speed bar (slow) shrinks as you go out, the height bar (fast) grows, and the net drift crosses zero once.
- **Guess:** Place a marker on the radius slider where you think the two effects cancel. The reveal slides the satellite there: 1.5 Earth radii, about 9,557 km from Earth's center.
- **Name it:** In a circular orbit v² = GM/r, so both effects use the same number GM/(c²R). Speed costs half of R/r of it, height gains 1 − R/r of it. The net is zero at r = 1.5R; below that the satellite clock runs slow, above it fast.
  speed loss = K × R / (2r); height gain = K × (1 − R/r); net = K × (1 − 3R / (2r)); K = GM / (c²R) × 86,400 s = 60.1 μs per day; map error = net × c
- **Work it:** r in km from {6,771 (space station), 20,000, 26,571 (GPS), 29,600 (Galileo), 42,164 (geostationary)} or 7,000 to 45,000; each part in μs per day to 1 decimal place, map error in km per day to 1 decimal place. From index 3, also find the cancel radius (to the nearest km). Early: GPS and geostationary. Example: GPS, r = 26,571 km.
  1. **Speed loss** μs per day: 7.2.
  2. **Height gain** μs per day: 45.7.
  3. **Net** μs per day: 38.5.
  4. **Ahead or behind a ground clock?** tap: ahead.
  5. **Map error after one day** km: 11.5.
  6. **Cancel radius** km: 9,557.
  - Others: space station net −24.7 (behind), Galileo +40.7, geostationary +46.5.
  - Slips: added the speed loss (typed 52.9) "The speed effect slows the satellite clock and gravity speeds it up, so they pull opposite ways: subtract." · typed 11,550 (μs × 300) "1 μs of light travel is about 0.3 km, so 38.5 μs is 11.5 km." · cancel radius from 1/R = 1/r "Set R/(2r) = 1 − R/r: then 3R/(2r) = 1, so r = 1.5R."
- **Oracle:** `K = 3.986e14/(299792458^2*6.371e6)*86400e6; [K*R/(2r), K*(1-R/r), K*(1-1.5*R/r), K*(1-1.5*R/r)*0.299792458, 1.5*6371]`.
- **Use it:** **The build: GPS checker.** The net fraction is 38.5 μs / 86,400 s ≈ 4.46 × 10⁻¹⁰, so GPS clocks are built to tick at 10.23 MHz × (1 − 4.46 × 10⁻¹⁰) ≈ 10.229 999 995 MHz before launch; on orbit they read true. Saves `gps_net` and the checker to the Notebook: the track's build.
- **Deeper:** The real factory setting, 4.4647 × 10⁻¹⁰, also folds in Earth's spin and shape. Orbits aren't perfect circles: receivers add (2/c²)√(GMa) e sin E, up to 23 ns when e = 0.01 (links b2-or-05, Kepler's equation). The Sagnac correction for signals crossing a spinning Earth. Why a clock error grows a position error through the geometry of the satellites (dilution of precision: a fix is a least-squares solve and the precision is read off (AᵀA)⁻¹, links b2-la-11 and b2-pr-03, covariance). The metric view: dτ/dt ≈ 1 + Φ/c² − v²/(2c²), one formula for the whole build.
