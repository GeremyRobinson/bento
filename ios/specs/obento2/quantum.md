# Bento² · Quantum and quantum computing (code `qu`, 12 lessons)

**What it is:** the rules for the very small, where outcomes are chances, chances come from arrows that can cancel, and a qubit can be in a blend of 0 and 1. It is the math behind lasers, chips and quantum computers.

Role: branch, track 10. Needs: linear algebra (track `la`, mainly b2-la-01, b2-la-05, b2-la-06, b2-la-16), probability (track `pr`, mainly b2-pr-01) and computation (track `cs`, mainly b2-cs-04 and b2-cs-06); from Bento, complex numbers (`g11-complex`) and trig (`pc-sinegraph`). Nothing is locked. The plain path is college level (the qubit chapters of a first quantum computing course). The Deeper layers reach upper-undergraduate and graduate ideas: Feynman's sum over paths, Hilbert spaces and Dirac notation, Hermitian observables and the uncertainty relation, density matrices and the Bloch ball, SU(2) as a double cover of 3D turns, universal gate sets and Solovay–Kitaev, the no-cloning theorem, the Schmidt decomposition and entanglement entropy, the CHSH inequality and Tsirelson's bound, Bernstein–Vazirani and Simon, the BBBV √N lower bound, the quantum Fourier transform and Shor's period finding, teleportation and quantum error correction.

## The build: a two-qubit search, run by hand

**Run a real quantum algorithm on paper and get the right answer every time.** The learner builds Grover's search on two qubits gate by gate in the Circuit board, writes the state vector (four amplitudes) after every gate by hand, and finds the marked item out of four with probability 1, using one question where a classical search can need three. Built in the Circuit board; saved to the Notebook as the track's build.

What each unit adds:

| Unit | Lessons | What it adds to the build |
|---|---|---|
| 1 · Chances from arrows | 01 to 03 | How to read the answer: amplitudes are arrows (complex numbers), they add and cancel, and the chance of an outcome is the squared length (`psi`). |
| 2 · One qubit | 04 to 06 | The gates: H, X, Z and phase as 2×2 matrices, and the H, phase, H pattern that turns a phase into a chance (`dial`). This is the trick the build uses to make wrong answers cancel. |
| 3 · Two qubits | 07 to 09 | The board: four amplitudes, the tensor product, CNOT and entanglement (`bell`). The build's state is one of these four-entry vectors. |
| 4 · Quantum computing | 10 to 12 | The algorithm: a sign-flip oracle, then Deutsch–Jozsa (one question tells constant from balanced), then Grover's flip and reflect, and the full two-qubit circuit run by hand (`grover`). |

## Units

1. **Chances from arrows:** b2-qu-01 to b2-qu-03
2. **One qubit:** b2-qu-04 to b2-qu-06
3. **Two qubits:** b2-qu-07 to b2-qu-09
4. **Quantum computing:** b2-qu-10 to b2-qu-12

## Small projects

| After | Project | What the learner makes and keeps | Shelf |
|---|---|---|---|
| b2-qu-03 | **Your quantum coin** | Type any two complex amplitudes. Bento scales them to total 1, predicts the chance of 0, then runs 1,000 shots in the Simulator so you can watch the bars settle onto your prediction. | `psi` |
| b2-qu-06 | **Dial a chance** | Build a one-qubit circuit H, phase φ, H that gives 0 with a chance you pick (for example 1/4), and check it over 1,000 shots. | `dial` |
| b2-qu-09 | **Bell pair lab** | Make all four Bell states from H and CNOT (plus X and Z), and run the matching game on your favorite one. | `bell` |
| b2-qu-12 | **The build: two-qubit search** | Grover's search on two qubits, with the state written out after every gate and the marked item found with certainty. | `grover` |

## Conventions (used by every lesson)

- Two-qubit states are listed in the order |00⟩, |01⟩, |10⟩, |11⟩; the left digit is the top qubit, which is also the CNOT control.
- To keep answers clean on the keypad, amplitudes are often typed **in units**: "in units of 1/2" means you type 2 × each amplitude, "in units of 1/√2" means you type √2 × each amplitude. The unit is printed above the boxes.
- Probabilities are typed as fractions when exact, otherwise as decimals to 3 places. Oracles compute exactly and accept answers within one unit of the last stated place.
- Real-angle measurements in lesson 09 use angles on paper (like polarizer angles), which are half the angles on the qubit sphere. The screen says so once.

## New for Development

Toolbox tools to build (names from `bento2/research/toolbox.md`, track 8):
- **★ Qubit sphere (Bloch sphere).** An arrow on a ball, dragged by θ (from the top) and φ (around). Readouts: the two amplitudes cos(θ/2) and e^{iφ} sin(θ/2), P(0), P(1), and a bar showing the arrow's height z = P(0) − P(1). Gates animate as turns (X and Z by 180° about their axes, H about the diagonal axis, phase by φ about the vertical). A Measure button snaps the arrow to the top or bottom; "Run 1,000" sends shots to the Simulator from `pr`.
- **Amplitude arrows.** Two or more complex arrows placed head to tail; the sum arrow; its squared length drawn as a square whose area is the chance. A "which path" switch that throws away the cross term and shows the classical sum of squares instead (01, 02).
- **Double-slit lab.** Dots arrive one at a time and build stripes; slit gap and wavelength sliders; a detector toggle that wipes the stripes into two plain humps (01).
- **Circuit board.** One or two qubit lines (Deeper: up to four). Gates: H, X, Z, S, phase(φ), CNOT, CZ, an oracle box (sign flip on chosen inputs, or a function table f), and a diffusion box. Step through one gate at a time with the state vector shown as a table of amplitudes (in the lesson's units) and as bars; a hand-entry mode where the learner types the next state before the board shows it (the build).
- **Entanglement pair.** A source sends pairs to two analyzers with angle dials. Run N pairs and see the match rate; a CHSH game mode with a referee who sends random questions and tallies wins against the 3/4 classical line (09).
- **Wave in a box** (Deeper only, 03): standing waves with only whole numbers of half-waves allowed, and energy levels growing like n².

New pictures, mapped to toolbox homes:
- **Product grid** (inside Circuit board): a 2×2 grid whose cells are the four amplitudes; for a product state the grid is a column times a row, and the cross-check ps − qr shows live (07, 08; links b2-la-06).
- **Reflect about the mean** (inside Circuit board): the amplitudes as bars with a dashed line at their mean; diffusion flips every bar to the other side of the line (11, 12).

Cross-track links: `la` (01, 02, 05, 07, Deeper 03, 04, 06 and 08), `pr` (03, 09), `cs` (07, 08, 10, 11, 12), `in` (Deeper 08, 12), `re` (Deeper 05).

Shelf names this track creates: `psi`, `dial`, `bell`, `grover`.

---

## Unit 1 · Chances from arrows

### b2-qu-01 · Chances that cancel: interference
- **You can:** find the chance of an outcome reached two ways, when the ways can cancel.
- **Needs:** b2-la-01, `pc-sinegraph`.
- **Tool:** Double-slit lab; Amplitude arrows.
- **Play:** Drag the slit gap and the wavelength: the stripes squeeze and spread as the dots build them up. Flip on a detector at the slits and the stripes wash out into two humps.
- **Guess:** Each slit alone gives a chance of 0.09 and 0.16 at one spot on the screen. Pick one: with both open, is the chance there 0.25, anywhere from 0.01 to 0.49, or always 0? The reveal turns the angle between the two arrows and the chance sweeps from 0.49 down to 0.01.
- **Name it:** Each way to an outcome gives an arrow, its amplitude. Add the arrows first, then square the length to get the chance. Arrows pointing opposite ways cancel, which is how a chance can drop when you open a second path.
  P = |a + b|² = |a|² + |b|² + 2|a||b| cos θ; with a detector: |a|² + |b|²
- **Work it:** a, b in tenths from 0.1 to 0.6 with a + b ≤ 1, so no chance goes above 1; θ from {0°, 60°, 90°, 120°, 180°}. Answers to 2 decimal places (exact here). Early: θ = 0° or 180°. Example: a = 0.3, b = 0.4, θ = 60°.
  1. **a² + b²** 0.25.
  2. **2ab cos θ** 0.12.
  3. **P with both paths** 0.37.
  4. **P with the detector on** 0.25.
  - Same arrows at 180°: P = 0.01; at 0°: 0.49.
  - Slips: added the chances (0.25 at θ = 60°) "That's what you get when you know which path it took. Without a detector, add the arrows, then square." · added lengths, then didn't square (0.7) "The chance is the squared length of the sum: 0.7² at θ = 0°." · cos 60° as √3/2 "cos 60° is 1/2."
- **Oracle:** `P = a^2 + b^2 + 2*a*b*cos(theta*pi/180)`; assert 0 ≤ P ≤ 1.
- **Use it:** Noise-canceling headphones and anti-glare lens coatings use the same canceling, with sound and light. In the build, the wrong answers get canceled this way.
- **Deeper:** Feynman's sum over paths: every route gets an arrow, and the arrows of nearby routes cancel everywhere except near the route of least time, which is why light seems to travel in straight lines. The stripe spacing λL/d. Wave in a box: a trapped particle can only have whole-number standing waves, so its energy comes in levels n².

### b2-qu-02 · Complex numbers: arrows that turn
- **You can:** multiply complex numbers as turn-and-stretch moves and find their squared length.
- **Needs:** b2-qu-01, `g11-complex`, b2-la-05.
- **Tool:** Amplitude arrows; Vector board.
- **Play:** Two arrows z and w on the plane. Their product's arrow has length |z||w| and angle "angle of z plus angle of w". Drag w around the circle and watch z w spin with it.
- **Guess:** z = 3 + 4i. Place a point where you think i·z lands. The reveal turns z a quarter turn: −4 + 3i.
- **Name it:** A complex number a + bi is an arrow (a, b). Multiplying multiplies lengths and adds angles. Multiplying by i turns 90°, and e^{iφ} = cos φ + i sin φ is a pure turn by φ. The squared length is z times its mirror image (the conjugate).
  (a + bi)(c + di) = (ac − bd) + (ad + bc)i; |z|² = z z̄ = a² + b²; |zw|² = |z|²|w|²
- **Work it:** a, b, c, d whole from −4 to 4, not both zero in either number. Early: a, b, c, d from 0 to 3. Example: z = 1 + 2i, w = 3 − i.
  1. **Real part of z w** 5.
  2. **Imaginary part** 5.
  3. **|z|²** 5.
  4. **|w|²** 10.
  5. **|z w|²** 50.
  - Slips: treated i² as +1 (typed 1 for the real part) "i² = −1, so −bd = −(2)(−1) = +2, and 3 + 2 = 5." · |z|² as a + b "Square each part and add: 1 + 4." · added the |z|² values "Lengths multiply, so squared lengths multiply: 5 × 10."
- **Oracle:** `[a*c - b*d, a*d + b*c, a^2+b^2, c^2+d^2, (a^2+b^2)*(c^2+d^2)]`.
- **Use it:** A light path's amplitude turns as it travels: one full turn per wavelength. Two paths that differ by half a wavelength meet turned 180° apart and cancel, which is the dark stripe from lesson 01.
- **Deeper:** Why e^{iφ} = cos φ + i sin φ, from the Taylor series of eˣ, cos and sin (`bc-taylor`). Complex numbers as the 2×2 matrices [[a, −b], [b, a]] (links b2-la-13). Phases form the circle group U(1).

### b2-qu-03 · State vectors and the Born rule
- **You can:** scale a state so its chances add to 1, and predict measurement counts.
- **Needs:** b2-qu-02, b2-pr-01.
- **Tool:** Amplitude arrows; Simulator (shared with `pr`); ★ Qubit sphere.
- **Play:** A qubit's state is two complex arrows, one for 0 and one for 1. Drag them; Bento rescales them so the two squares always fill one bar. Press Run and 1,000 measurements pile up into bars that settle on those squares.
- **Guess:** The state is proportional to (3, 4i). Drag a slider to the share of 1s you expect in 1,000 shots. The reveal runs the shots.
- **Name it:** A qubit is a pair of amplitudes (α, β): a blend, or superposition, of 0 and 1. Measuring gives 0 with chance |α|² and 1 with chance |β|² (the Born rule), and leaves the qubit in the state it showed. Multiplying both amplitudes by the same turn e^{iφ} changes nothing you can measure.
  |ψ⟩ = α|0⟩ + β|1⟩; |α|² + |β|² = 1; P(0) = |α|², P(1) = |β|²
- **Work it:** Unscaled pairs whose squared lengths add to a perfect square: from {(3, 4i), (4, 3), (1 + 2i, 2), (2i, 1 + 2i), (2, 2 + i), (1 + i, 1 − i), (5, 12i), (1, 2 + 2i)}; N a multiple of the squared total, so counts are whole: total 25 gives N from {100, 1,000, 2,500}; total 9 gives 900 or 1,800; total 4 gives 100 or 1,000; total 169 gives 1,690. Probabilities as fractions. Early: real entries. Example: (1 + 2i, 2), N = 900.
  1. **|1 + 2i|² + |2|²** 9.
  2. **Scale factor** fraction: 1/3.
  3. **P(0)** fraction: 5/9.
  4. **P(1)** fraction: 4/9.
  5. **Expected 0s in 900 shots** 500.
  - Slips: P(0) as 1/3 (the amplitude) "The chance is the squared length: |(1 + 2i)/3|² = 5/9." · |1 + 2i|² as (1 + 2)² "Square each part and add: 1² + 2² = 5." · divided by 9 instead of 3 to scale "Divide the amplitudes by √9 = 3, so their squares add to 1."
- **Oracle:** `n2 = sum(|z|^2); [|z0|^2 / n2, |z1|^2 / n2, N*|z0|^2/n2]`.
- **Use it:** **Project: Your quantum coin.** Pick amplitudes, predict, run 1,000 shots, and see how far the count lands from the prediction (about √(N p(1 − p)), links b2-pr-01, the 1/√n rule). Saves `psi`.
- **Deeper:** States as unit vectors in a complex inner-product space (a Hilbert space), with Dirac's ⟨φ|ψ⟩. A measurable quantity is a Hermitian matrix A, the complex version of symmetric; its eigenvalues are the possible readings and ⟨ψ|A|ψ⟩ is the average (links b2-la-15). Wave in a box as a state vector with infinitely many entries.

## Unit 2 · One qubit

### b2-qu-04 · The qubit sphere
- **You can:** place a qubit state on the sphere and read its chances from its height.
- **Needs:** b2-qu-03.
- **Tool:** ★ Qubit sphere.
- **Play:** An arrow on a ball. Drag it from the top (always 0) down to the bottom (always 1); the chance bar and the two amplitudes follow. Spin it around the vertical axis: the chances don't change at all.
- **Guess:** Drag the arrow to where you think P(0) = 3/4. The reveal marks the ring at θ = 60°.
- **Name it:** Every qubit state is a point on a sphere: θ down from the top, φ around. Its height is P(0) − P(1). Points opposite each other are states you can always tell apart with one measurement (like 0 and 1), even though they are only 90° apart as amplitude arrows.
  |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ} sin(θ/2)|1⟩; P(0) = cos²(θ/2); height z = cos θ = P(0) − P(1)
- **Work it:** θ from {0°, 60°, 90°, 120°, 180°}, or P(0) in tenths from 0.1 to 0.9 (then find z and θ to 1 decimal place). Fractions for exact cases. Early: θ from the list. Example: θ = 120°; then P(0) = 0.9.
  1. **P(0) at θ = 120°** fraction: 1/4.
  2. **Height z** fraction: −1/2.
  3. **For P(0) = 0.9: z** decimal: 0.8.
  4. **θ** degrees: 36.9.
  - Slips: P(0) = cos² θ (typed 1/4 at θ = 60°) "The sphere uses half angles: P(0) = cos²(θ/2) = cos² 30° = 3/4." · z as P(0) "Height runs from +1 at the top to −1 at the bottom: P(0) − P(1)." · thought φ changes P(0) "Turning around the vertical axis only changes the phase of the 1 amplitude, not its length."
- **Oracle:** `cos(theta/2)^2`, `cos(theta)`, `acos(2*p0 - 1)` in degrees.
- **Use it:** A qubit pointing along the equator (θ = 90°) is a fair coin whatever its φ. Run 1,000 shots for three equator points with different φ: three fair coins that are different states, which the next two lessons tell apart.
- **Deeper:** Mixed states: a qubit you are unsure about is a point inside the ball, described by a density matrix ρ = ½(I + r·σ). ρ is a 2×2 Hermitian matrix with trace 1; its eigenvalues are the chances of the mix (links b2-la-15). Why half angles: the 2×2 unitary matrices SU(2) cover the 3D turns twice (a 360° turn multiplies the state by −1).

### b2-qu-05 · Gates are matrices
- **You can:** apply X, Z and H to a qubit as matrices and read off the new chances.
- **Needs:** b2-qu-04, b2-la-05, b2-la-16.
- **Tool:** Circuit board (one qubit); Matrix pad; ★ Qubit sphere.
- **Play:** Drop gates onto one qubit line. X flips the arrow upside down, Z spins it half a turn around the vertical, and H swaps the top with the front of the sphere. The Matrix pad shows each gate's 2×2 matrix and the state after it.
- **Guess:** Start at 0 and apply H twice. Pick one: you end at 0, at 1, or as a fair coin. The reveal animates both turns: H undoes itself.
- **Name it:** A gate is a 2×2 matrix that keeps the total chance at 1 (a unitary: U†U = I, where U† is U flipped across its diagonal with every entry conjugated; for real matrices it's just the transpose, as in b2-la-16). X swaps the amplitudes, Z flips the sign of the second, and H makes a sum and a difference.
  X = [[0, 1], [1, 0]]; Z = [[1, 0], [0, −1]]; H = (1/√2)[[1, 1], [1, −1]]; H(α, β) = ((α + β)/√2, (α − β)/√2)
- **Work it:** Start (α, β) from {(1, 0), (0, 1), (3/5, 4/5), (4/5, 3/5), (5/13, 12/13), (12/13, 5/13)}, signs random; 1 to 3 gates from X, Z, H. After an odd number of H gates, amplitudes are typed in units of 1/√2. Probabilities as fractions. Early: one gate. Example: (3/5, 4/5), then H.
  1. **α + β** fraction: 7/5.
  2. **α − β** fraction: −1/5.
  3. **New state, in units of 1/√2** (7/5, −1/5).
  4. **P(0)** fraction: 49/50.
  5. **Apply H again: new state** (3/5, 4/5).
  - Slips: forgot the 1/√2 (P(0) = 49/25) "A chance over 1 means a missing factor: H divides by √2, so P(0) = (7/5)²/2." · Z flips the first amplitude "Z leaves the 0 amplitude and flips the sign of the 1 amplitude." · X changes signs "X swaps the two amplitudes; it doesn't change signs."
- **Oracle:** per gate, `[[0,1],[1,0]]·v`, `[[1,0],[0,-1]]·v` or `[[1,1],[1,-1]]·v/√2` with exact fractions; `P0 = v[0]^2`.
- **Use it:** HZH = X: in the Matrix pad multiply the three matrices and get X. Gates can be built from other gates, which is what a quantum compiler does.
- **Deeper:** The Pauli matrices X, Y, Z and every one-qubit gate as a turn of the sphere, e^{−iθ(n·σ)/2}. Universal gate sets: H and the T gate (phase 45°) reach any one-qubit gate as closely as you like, and the Solovay–Kitaev theorem says how quickly. Every unitary has eigenvalues on the unit circle (links b2-la-13). The Pauli matrices return in the Dirac equation (links b2-re-08).

### b2-qu-06 · Phase becomes chance: H, phase, H
- **You can:** turn a hidden phase into a measurable chance with an H, phase, H circuit.
- **Needs:** b2-qu-05.
- **Tool:** Circuit board; ★ Qubit sphere; Simulator (shared with `pr`).
- **Play:** A circuit H, phase(φ), H on one qubit. Drag φ: after the first H the chances are always 50/50, but after the second H the chance of 0 swings smoothly from 1 down to 0 and back.
- **Guess:** With φ = 120°, drag a slider to the chance of 0 at the end. The reveal adds the two amplitude arrows: 1 and e^{i·120°}.
- **Name it:** A phase can't be seen by measuring right away, but a second H adds the two amplitudes together, and how well they line up decides the chance. That turns a phase into a chance, and it is how every quantum algorithm reads out its answer.
  H, phase(φ), H: amplitude of 0 = (1 + e^{iφ})/2; P(0) = (1 + cos φ)/2 = cos²(φ/2)
- **Work it:** φ from {0°, 60°, 90°, 120°, 180°}, later {45°, 135°} (decimals to 3 places). From index 4, the reverse: given P(0) from {1, 3/4, 1/2, 1/4, 0}, find φ from 0° to 180°. Early: φ = 0° or 180°. Example: φ = 120°.
  1. **Chances after the first H** fraction: P(0) = 1/2.
  2. **cos φ** fraction: −1/2.
  3. **P(0) at the end** fraction: 1/4.
  - φ = 45°: 0.854. Reverse: P(0) = 3/4 needs φ = 60°.
  - Slips: P(0) = cos² φ (typed 1/4 at φ = 60°) "Half the phase: cos²(φ/2). At 60° that's cos² 30° = 3/4." · thought the phase changed the first H's chances "Right after H the two arrows have equal length, so it's 50/50 whatever the phase." · used 1 − cos φ "That's P(1). The arrows add for 0 and subtract for 1."
- **Oracle:** `(1 + cos(phi))/2`.
- **Use it:** **Project: Dial a chance.** Make a circuit that comes up 0 one time in four (φ = 120°), and check it over 1,000 shots. Saves `dial`. With φ = 180° the phase becomes a sure 1: that is the "flip the sign, then H" move the build uses.
- **Deeper:** The Mach–Zehnder interferometer is this circuit made of mirrors. The Elitzur–Vaidman bomb tester: finding a bomb without setting it off. Measuring in a different basis, X and Z that don't commute, and the uncertainty relation ΔA ΔB ≥ ½|⟨[A, B]⟩| (links b2-la-06).

## Unit 3 · Two qubits

### b2-qu-07 · Two qubits: four amplitudes
- **You can:** combine two qubits into one four-amplitude state and read joint chances.
- **Needs:** b2-qu-05, b2-la-06.
- **Tool:** Circuit board (two qubits, product grid); Matrix pad.
- **Play:** Two qubits, each with its own pair of amplitudes. The product grid shows the four combined amplitudes as a 2×2 grid: a column times a row. Drag either qubit and its row or column of the grid rescales.
- **Guess:** Top qubit P(1) = 16/25, bottom qubit P(0) = 25/169. Drag a slider to the chance of reading 10. The reveal lights that cell of the grid.
- **Name it:** Two qubits together have four amplitudes, one for each of 00, 01, 10, 11. For two separate qubits, each combined amplitude is a product of one from each (the tensor product), so chances multiply. n qubits need 2ⁿ amplitudes.
  (a, b) ⊗ (c, d) = (ac, ad, bc, bd), in the order 00, 01, 10, 11
- **Work it:** Each qubit from {(1, 0), (0, 1), (3/5, 4/5), (4/5, 3/5), (5/13, 12/13), (8/17, 15/17)} with random signs; asked outcome random; answers as fractions. From index 4, also: how many amplitudes for n qubits, n from 3 to 50 (as a power of 2). Early: one qubit is (1, 0) or (0, 1). Example: top (3/5, 4/5), bottom (5/13, 12/13).
  1. **Amplitude of 00** fraction: 3/13.
  2. **Amplitude of 01** fraction: 36/65.
  3. **Amplitude of 10** fraction: 4/13.
  4. **Amplitude of 11** fraction: 48/65.
  5. **P(10)** fraction: 16/169.
  - Slips: wrong order (put the bottom qubit first) "The left digit is the top qubit: 10 means top 1, bottom 0, so b × c." · added instead of multiplied "Independent qubits combine like independent coins: multiply." · P(10) as 4/13 "That's the amplitude; the chance is its square, 16/169."
- **Oracle:** `kron(q1, q2)`, then the square of the asked entry.
- **Use it:** 50 qubits need 2⁵⁰ ≈ 1.13 × 10¹⁵ amplitudes, about 18 petabytes at 16 bytes per amplitude (two 8-byte numbers). That is why big quantum circuits can't be simulated by brute force (links b2-cs-08).
- **Deeper:** The tensor product of vector spaces, with dimension multiplying. Gates on one qubit act on two as the 4×4 matrix U ⊗ I (Kronecker product). Why a classical computer needs exponential memory to follow a general state, and what that does and doesn't say about quantum speedups.

### b2-qu-08 · CNOT and entanglement
- **You can:** apply a CNOT and tell whether a two-qubit state is entangled.
- **Needs:** b2-qu-07, b2-cs-04.
- **Tool:** Circuit board; Entanglement pair; Matrix pad.
- **Play:** Put H on the top qubit, then a CNOT from top to bottom. The product grid can no longer be split into a column times a row, and the cross-check ps − qr stops being 0. Measure the top qubit: the bottom one always matches.
- **Guess:** Start at 00, apply H to the top, then CNOT. Pick the four chances: (1/2, 0, 0, 1/2), (1/4, 1/4, 1/4, 1/4) or (1/2, 1/2, 0, 0). The reveal steps through the gates.
- **Name it:** CNOT flips the bottom qubit when the top one is 1: it swaps the amplitudes of 10 and 11. A two-qubit state (p, q, r, s) is a product of two separate qubits exactly when ps = qr. Otherwise it is entangled: neither qubit has a state of its own, but their results are linked.
  CNOT (p, q, r, s) = (p, q, s, r); entangled when ps − qr ≠ 0; Bell state (|00⟩ + |11⟩)/√2
- **Work it:** Start from a product of two qubits from the list in b2-qu-07; apply CNOT; answers as fractions. Include cases where the bottom qubit is (1, 1)/√2 (amplitudes in units of 1/√2), where CNOT does not entangle. Early: bottom qubit (1, 0). Example: top (3/5, 4/5), bottom (1, 0).
  1. **Product state** four boxes: (3/5, 0, 4/5, 0).
  2. **After CNOT** four boxes: (3/5, 0, 0, 4/5).
  3. **ps − qr** fraction: 12/25.
  4. **Entangled?** tap: yes.
  5. **If the top reads 1, the bottom reads** tap: 1, for sure.
  - Slips: swapped 01 and 10 "CNOT only acts when the top (left) qubit is 1, so it swaps the last two entries." · "CNOT always entangles" "Not when the bottom qubit is (1, 1)/√2: flipping it changes nothing, so ps − qr stays 0." · changed the control "The top qubit is the control; CNOT never changes it."
- **Oracle:** swap entries 3 and 4; `p*s - q*r`.
- **Use it:** Make the Bell state from 00 with H then CNOT and run 1,000 pairs in the Entanglement pair: about half read 00, half read 11, and never 01 or 10. Moving the qubits apart doesn't change that.
- **Deeper:** The no-cloning theorem: no gate copies an unknown state, proved from linearity in two lines. The Schmidt decomposition of a two-qubit state is the SVD of its 2×2 grid, and the number of nonzero σ's says whether it is entangled (links b2-la-17). Entanglement entropy in bits (links b2-in-03, entropy).

### b2-qu-09 · Bell's matching game
- **You can:** predict how often entangled pairs match at two analyzer angles, and why no hidden plan can do as well.
- **Needs:** b2-qu-08, b2-pr-01.
- **Tool:** Entanglement pair (CHSH game mode); Simulator (shared with `pr`).
- **Play:** Bell pairs fly to two analyzers. Turn the dials: at equal angles they always match; as the angles move apart the match rate falls smoothly. In game mode a referee asks random questions and counts wins.
- **Guess:** With the dials 30° apart, drag a slider to the match rate. The reveal runs 1,000 pairs and draws cos² 30°.
- **Name it:** For the Bell state, two analyzers at angles a and b agree with chance cos²(a − b). In the CHSH game, players who agree on any plan in advance win at most 3 times in 4. Entangled pairs win about 85.4% of the time. That gap is what experiments test, and the plan-in-advance idea loses.
  P(same) = cos²(a − b); classical win ≤ 3/4; quantum win = cos² 22.5° ≈ 0.854
- **Work it:** a, b in multiples of 15° from 0° to 90°; decimals to 3 places (exact fractions when they exist). From index 3, the game: the four question pairs with Alice at 0° or 45° and Bob at 22.5° or −22.5°; the pair wants to match on three pairs and differ on the fourth. Early: a − b from {0°, 45°, 90°}. Example: a = 0°, b = 30°; then the game.
  1. **P(same)** fraction: 3/4.
  2. **P(different)** fraction: 1/4.
  3. **Game: chance of winning each round** decimal: 0.854.
  4. **Best plan without entanglement** fraction: 3/4.
  - Slips: P(same) = cos(a − b) "Chances come from squared amplitudes: cos²." · used the sphere angle (cos² 15° at 30°) "These are paper angles, like polarizers: use the full difference." · thought a plan can win always "Any fixed plan loses at least one of the four question pairs, so at most 3/4."
- **Oracle:** `cos(a - b)^2`; `cos(pi/8)^2`.
- **Use it:** **Project: Bell pair lab.** Make all four Bell states (add X or Z before the CNOT), identify each by its matching pattern, and play 100 rounds of the game with your favorite. Saves `bell`.
- **Deeper:** The CHSH inequality |S| ≤ 2 for any local hidden-variable theory, proved by checking the 16 deterministic plans, against Tsirelson's bound 2√2 for quantum mechanics. Loopholes (detection, locality) and the loophole-free experiments of 2015; the 2022 Nobel Prize. Quantum teleportation uses one Bell pair and two classical bits. Alice holds ψ = (α, β) and one half of the Bell pair (|00⟩ + |11⟩)/√2. She applies CNOT from ψ to her half, then H on ψ, and measures both of her qubits (m₁, m₂); each of the four results has chance 1/4, whatever ψ is. Bob's qubit is then (α, β) for 00, so he does nothing; (β, α) for 01, so he applies X; (α, −β) for 10, so he applies Z; and (−β, α) for 11, so he applies X then Z. Two classical bits travel, so nothing moves faster than light, and no copy is left behind, which fits no-cloning.

## Unit 4 · Quantum computing

### b2-qu-10 · One question instead of three: Deutsch–Jozsa
- **You can:** run a sign-flip oracle and tell a constant function from a balanced one with one question.
- **Needs:** b2-qu-06, b2-qu-07, b2-cs-06.
- **Tool:** Circuit board (oracle box); ★ Qubit sphere.
- **Play:** A hidden function f takes 2 bits to 0 or 1: either the same output for all four inputs (constant) or 0 for exactly two (balanced). Drag 0s and 1s into f's four output cells, then step the circuit H, oracle, H: the four sign bars and the 00 bar update live.
- **Guess:** f is balanced. Pick one: after the circuit, the chance of reading 00 is 1, 1/2, 1/4 or 0. The reveal steps through the gates and the 00 bar empties.
- **Name it:** The oracle flips the sign of each input where f is 1 (a sign flip, made with one extra qubit, called phase kickback). H on both qubits then adds all four signs into the amplitude of 00. Constant f: they all agree, 00 for sure. Balanced f: they cancel, 00 never.
  start (1, 1, 1, 1)/2 → signs ((−1)^f(00), …)/2 → amplitude of 00 after H⊗H = ¼ Σ (−1)^f(x)
- **Work it:** f as a 4-entry table, constant or balanced (two constant, six balanced). Amplitudes in units of 1/2. Early (index < 3): Deutsch's 1-bit version: f on one bit, state in units of 1/√2, and the amplitude of 0 after H is ½((−1)^f(0) + (−1)^f(1)). Example: f = (0, 1, 1, 0).
  1. **After the oracle** four boxes, units of 1/2: (1, −1, −1, 1).
  2. **Amplitude of 00 after H⊗H** 0.
  3. **Which outcome comes up** tap: 11.
  4. **Constant or balanced** tap: balanced.
  - Balanced f = (0, 0, 1, 1) gives 10; f = (0, 1, 0, 1) gives 01; constant f = (1, 1, 1, 1) gives 00 with amplitude −1.
  - Slips: flipped signs where f is 0 "The oracle flips the sign where f(x) = 1." · read −1 as "not 00" "A minus sign doesn't change the chance: (−1)² = 1, so constant f still gives 00 for sure." · thought the circuit finds f "It answers one question about f, constant or balanced, not the whole table."
- **Oracle:** Walsh–Hadamard transform of the sign vector.
- **Use it:** Classically, telling constant from balanced on n-bit inputs can take 2ⁿ⁻¹ + 1 looks (3 for n = 2, 513 for n = 10); the circuit always takes one. A classical guesser who accepts a small chance of being wrong needs only a few looks; the quantum circuit is never wrong. Simon's problem (Deeper) is where the gap stays large even then. This oracle and the H⊗H sandwich are the build's first half.
- **Deeper:** Every balanced f on 2 bits is a·x or its opposite, so the outcome reads off a: Bernstein–Vazirani. Simon's problem, an exponential gap with a probabilistic classical algorithm. Query complexity and the class BQP, and what is and isn't known about how it sits beside P and NP (links b2-cs-12).

### b2-qu-11 · Grover's search: flip and reflect
- **You can:** run rounds of Grover's search by hand and find the chance of the marked item.
- **Needs:** b2-qu-10.
- **Tool:** Circuit board (reflect about the mean); Simulator (shared with `pr`).
- **Play:** N amplitudes as equal bars. The oracle flips the marked one below zero; diffusion flips every bar to the other side of the mean. Drag N from 4 to 64 and drag the round counter: the marked bar grows, overshoots and shrinks, and the round with the tallest bar stays marked.
- **Guess:** For N = 16, drag a slider to how many rounds give the best chance. The reveal plays rounds 1 to 6 with the marked chance printed: the peak is at 3.
- **Name it:** Start with every amplitude equal. Each round, flip the sign of the marked item, then reflect every amplitude about the mean: a → 2·mean − a. The marked amplitude grows by about 2/√N each round, so about (π/4)√N rounds find it, against about N/2 looks classically.
  oracle: a_marked → −a_marked; diffusion: a → 2·mean − a; best rounds ≈ (π/4)√N
- **Work it:** N from {4, 8, 16}; rounds 1 to 3. Amplitudes in units of 1/√N; probabilities as fractions and as decimals to 3 places. Early: N = 4, one round. Example: N = 8, one round.
  1. **After the oracle: marked, others** −1, 1.
  2. **Mean** fraction: 3/4.
  3. **New marked amplitude** fraction: 5/2.
  4. **New other amplitude** fraction: 1/2.
  5. **P(marked)** fraction: 25/32 (0.781).
  - N = 4, one round: marked 2 (units of 1/2), others 0, P = 1. N = 16: one round 121/256 (0.473), two 3721/4096 (0.908), three 0.961.
  - Slips: reflected about 0 "Diffusion reflects about the mean, not about zero: a → 2·mean − a." · left the marked sign flipped in the mean "Take the mean after the oracle, with the marked one negative: (7 − 1)/8 = 3/4." · P = 5/2 "Square and divide by N: (5/2)²/8 = 25/32. Check that all 8 chances add to 1."
- **Oracle:** `sin((2k + 1)*asin(1/sqrt(N)))^2` for P(marked) after k rounds, independent of the bar steps (1 at N = 4, k = 1; 0.473, 0.908, 0.961 for N = 16); the amplitudes by iterating `a[m] = -a[m]; a = 2*mean(a) - a` with exact fractions.
- **Use it:** A list of a million unsorted names: about 785 rounds instead of about 500,000 looks on average (links b2-cs-06). Grover would turn 2¹²⁸ guesses into about 2⁶⁴ rounds, one after another. That is one reason some guidance, such as the NSA's, asks for 256-bit keys.
- **Deeper:** Grover as a rotation: in the plane of "marked" and "the rest", each round turns the state by 2θ with sin θ = 1/√N, so the chance after k rounds is sin²((2k + 1)θ). The BBBV theorem: no quantum algorithm can search with fewer than about √N looks, so Grover is optimal.

### b2-qu-12 · The build: a two-qubit search, by hand
- **You can:** run Grover's search on two qubits gate by gate and find the marked item with certainty.
- **Needs:** b2-qu-08, b2-qu-11.
- **Tool:** Circuit board (hand-entry mode); ★ Qubit sphere; Simulator.
- **Play:** The full circuit on two qubits: H on both, the oracle, H on both, flip the sign of everything except 00, H on both, measure. Drag the hidden marker onto one of the four cells, then step through and type each state before the board shows it.
- **Guess:** Pick one: after this one round, the chance of reading the marked item is 1/4, 1/2, 3/4 or 1. The reveal runs 1,000 shots: every one lands on the marked item.
- **Name it:** "Reflect about the mean" is built from gates: H on both qubits, flip the sign of every state except 00, H on both again. For four items, one round is exactly enough: the three unmarked amplitudes cancel to 0 and the marked one becomes 1.
  diffusion = (H⊗H)(2|00⟩⟨00| − I)(H⊗H); H⊗H: out(y) = ½ Σ_x (−1)^(x·y) a(x)
- **Work it:** Marked item m from {00, 01, 10, 11}. Every state typed as four boxes in units of 1/2. From index 4, the oracle is built from gates (CZ for 11; X gates around CZ for the others) and the learner taps the gates in. Early: m = 11. Example: m = 10.
  1. **After H on both** (1, 1, 1, 1).
  2. **After the oracle** (1, 1, −1, 1).
  3. **After H on both** (1, −1, 1, 1).
  4. **After flipping all but 00** (1, 1, −1, −1).
  5. **After H on both** (0, 0, 2, 0).
  6. **Chance of reading 10** 1.
  - m = 11: (1, 1, 1, −1), then (1, 1, 1, −1), then (1, −1, −1, 1), then (0, 0, 0, 2).
  - Slips: H⊗H sign pattern "The sign for x and y is (−1) to the number of places where both have a 1: for y = 11 the signs are +, −, −, +." · flipped 00 too "Flip every amplitude except 00: (2|00⟩⟨00| − I) keeps 00 and negates the rest." · typed 1 for the final marked box "Boxes are in units of 1/2: an amplitude of 1 is typed as 2."
- **Oracle:** `sin(3*asin(1/2))^2 = 1` for the chance, independent of the steps; the final vector, from the five steps with exact fractions, is 2 (units of 1/2) at the marked item and 0 elsewhere.
- **Use it:** **The build: two-qubit search.** Hide an item, run your circuit by hand, then on the Simulator: 1,000 shots, all on the marked item. A classical search of four needs up to three looks (links b2-cs-06); this needs one. Saves `grover` and the circuit to the Notebook: the track's build.
- **Deeper:** Shor's idea: factoring reduces to finding the period of aˣ mod N, and the quantum Fourier transform (it turns amplitudes that repeat every r steps into peaks spaced 2ⁿ/r apart) finds periods the way H⊗H found the hidden pattern in b2-qu-10. For N = 15 and a = 7, the powers run 7, 4, 13, 1, so the period is 4, and with gcd as the greatest common divisor (the largest whole number dividing both), gcd(7² − 1, 15) = 3 and gcd(7² + 1, 15) = 5. Quantum error correction: the 3-qubit bit-flip code, the cousin of the Hamming code (links b2-in-11), and why real machines need many physical qubits for each reliable one.
