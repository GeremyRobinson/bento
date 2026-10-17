# Bento² track 7 · Differential equations (code `de`, 15 lessons)

**What it is:** the math of change over time. You write down how fast something changes right now, and the equation tells you its whole future: a swinging pendulum, a fish stock, predators and prey, an epidemic.

**Role:** first branch. **Needs:** Multivariable (`mv`) for b2-mv-09 (vector fields), b2-mv-03 (linear approximation) and b2-mv-08 (the Jacobian determinant), and Linear algebra (`la`) for b2-la-13 (eigenvalues). Soft needs only: the map lights them, nothing locks.

**Where this starts.** AP Calculus already covers slope fields and separable equations (`c-slopefield`), exponential growth (`c-expgrowth`), Euler's method (`bc-euler`) and logistic growth (`bc-logistic`) in `specs/wave2/`. This track does not repeat them. It starts at the phase line and goes to systems, eigenvalues, oscillators, phase planes, stability, epidemics and chaos. Lessons point back at those AP ids as "Needs" so a learner who skipped them gets a refresher offer.

## The build: two living models

The learner builds two models that run side by side in the ★ Slope field and flow sandbox, each with its own phase portrait, graph against time and live sliders: **a swinging pendulum** and **a population**. The finished build is saved to the Notebook as "Two living models" and can be reopened with every slider live.

What each unit adds:
1. **One equation, read without solving** (de-01 to de-04): the population's one-variable core. Logistic growth with an Allee threshold, a harvest dial with its tipping point, and the stepper (Euler, Heun or RK4) that every later model runs on.
2. **Linear systems** (de-05 to de-08): the phase-plane engine. Any 2×2 system x′ = Ax, with eigen-lines, spirals and a trace–determinant readout. Both models use it to read what happens near rest.
3. **Oscillators** (de-09 to de-11): the pendulum itself. Mass, length, friction and a periodic push, with the period, damping type and resonance curve on the model card.
4. **Nonlinear worlds** (de-12 to de-15): the full pendulum phase portrait (rest, over-the-top and the separatrix between), a second species (predator and prey), the population turned into an epidemic (SIR), and, as an optional Deeper ending, the driven pendulum gone chaotic.

## Units

| Unit | Lessons | Small project after |
|---|---|---|
| 1 · One equation, read without solving | de-01 Phase line · de-02 Linear first-order equations · de-03 Better steppers · de-04 Harvesting and tipping points | **Fishery dial** |
| 2 · Linear systems | de-05 Systems as one vector equation · de-06 Real eigenvalues · de-07 Complex eigenvalues · de-08 The trace–determinant map | **Phase portrait gallery** |
| 3 · Oscillators | de-09 Springs and damping · de-10 The pendulum · de-11 Forcing and resonance | **Pendulum clock** |
| 4 · Nonlinear worlds | de-12 Linearize at a rest point · de-13 Predator and prey · de-14 Epidemics (SIR) · de-15 Chaos (Deeper lesson) | **Outbreak planner**, then the build |

## Small projects

- **Fishery dial** (after de-04). One screen: a logistic fish stock with a harvest slider H. The phase line and a bifurcation strip (rest points against H) sit beside a time graph. The learner sets the largest harvest that still leaves a safety margin above the collapse threshold and saves it as `H_safe`. Kept in the Notebook.
- **Phase portrait gallery** (after de-08). Four tiles, one each for a saddle, a node, a spiral and a center. The learner types or drags a matrix into each so its dot lands in the right region of the trace–determinant map. Saved as `A_saddle`, `A_node`, `A_spiral`, `A_center`.
- **Pendulum clock** (after de-11). A seconds pendulum (period 2 s) from `L_pend`, with a little friction and a once-per-swing push sized so the amplitude holds steady. The card shows the length, the period and the drift per day. This becomes the pendulum half of the build.
- **Outbreak planner** (after de-14). An SIR model with sliders for contact rate and infectious days. The learner sets a vaccination fraction and sees R₀, the herd-immunity line and the peak. Saved as `R0` and `vax_needed`. This becomes the population half's last screen.

## New for Development

Shared tools are named as in `math-app/bento2/research/toolbox.md`.

1. **★ Slope field and flow sandbox: three modes.** (a) **Phase line strip** beside the 1D slope field: rest points as dots (filled for stable, open for unstable) and arrows between them. (b) **Phase plane** for 2D systems: arrows, nullclines, rest points, eigen-lines drawn when the system is linear, and trajectories that start where you tap. (c) **Stepper picker**: Euler, Heun or RK4, with a step slider h. It shares its time engine with the Orbit sandbox (`or`) and the Vector field painter (`mv`).
2. **Step-by-step solver: error plot.** For one chosen problem, error against h on log-log axes with three lines (slopes 1, 2 and 4) for Euler, Heun and RK4.
3. **Bifurcation strip (new picture).** Rest points plotted against a parameter (harvest H in de-04, r for the logistic map in de-15). Stable branches are solid and unstable ones dashed, and a vertical cursor tracks the slider.
4. **Trace–determinant map (new picture).** The (T, D) plane with the parabola T² = 4D and the region labels. A live dot comes from the Matrix pad, with a mini phase portrait linked to it.
5. **Matrix pad additions** (shared with `la` and `qu`): it shows the characteristic polynomial, gives complex eigenvalues as a ± bi, and draws eigenvectors as lines on the phase plane.
6. **Spring and pendulum lab: additions.** A drive (force amplitude F and drive frequency ω), a **resonance curve** picture (amplitude against ω, live), a full nonlinear pendulum up to 180°, an energy bar, and a link that puts (θ, θ′) onto the phase plane.
7. **Two-species world.** Lotka–Volterra with the rest point marked, closed loops, and the two time graphs in step with the loop.
8. **Epidemic model (SIR).** S, I and R curves, an R₀ readout, a herd-immunity line on S, a marker at the peak, and a vaccination slider.
9. **Chaos panel (new).** A logistic-map cobweb plot, the period-doubling bifurcation diagram, a "two starts" plot (log of the gap against step), the Lorenz attractor in Grapher 3D, and twin driven pendulums that start a hair apart.

Number shelf names this track writes: `allee_A`, `K_fish`, `stepper`, `H_safe`, `A_pend`, `A_saddle`, `A_node`, `A_spiral`, `A_center`, `zeta`, `L_pend`, `T_pend`, `A_drive`, `R0`, `vax_needed`.

---

## Unit 1 · One equation, read without solving

### b2-de-01 · The phase line
- **You can:** find every rest point of dy/dt = f(y) and tell which ones pull solutions in and which push them away, without solving anything.
- **Needs:** `c-slopefield`, `bc-logistic`.
- **Tool:** ★ Slope field and flow sandbox (phase line strip), Grapher 2D.
- **Play:** The sandbox shows dy/dt = f(y) as a slope field, with the graph of f(y) turned on its side next to a vertical phase line. Drag the three roots of a cubic f, then tap starting values and watch each solution slide toward or away from the flat lines.
- **Guess:** "Start at y = 3. Where does y end up?" Place a point on the phase line. The reveal runs the solution from 3 and lands it on the rest point it settles at (or sends it off the screen).
- **Name it:** A rest point is a y where f(y) = 0, so nothing changes. If f′ is negative there, nearby solutions come back and it is stable. If f′ is positive, they leave and it is unstable. Rule: dy/dt = f(y), f(y*) = 0, and y* is stable when f′(y*) < 0 and unstable when f′(y*) > 0.
- **Work it:** f(y) = s(y − a)(y − b)(y − c) with s ∈ {1, −1} and integers a < b < c from −4 to 6. Index < 3: s = −1, a = 0, and b, c from 1 to 5. Example: dy/dt = −(y + 1)(y − 2)(y − 4).
  1. **Rest points** three boxes, smallest first (−1, 2, 4).
  2. **Slope at the middle one** f′(b) = s(b − a)(b − c) (here −(3)(−2) = 6).
  3. **Each rest point** tap Stable / Unstable for each (stable, unstable, stable when s = −1; flipped when s = 1).
  4. **Start at y₀** (y₀ an integer strictly between two rest points, or outside them; when no integer lies strictly between two neighbor roots, as with 0, 1, 2, the generator picks y₀ outside the roots): type the rest point it heads to, or tap "Runs off up" / "Runs off down" (y₀ = 3 here: 4).
  - Slips: called a rest point stable because f is negative there: "At a rest point f is zero. Look at the sign of f on each side, or the sign of f′ at the point." · picked the nearest rest point instead of the one the flow goes to: "Solutions follow the arrows, not the closest dot. Check the sign of f(y₀)." · treated every rest point as stable: "Stable and unstable alternate when the roots are simple. One of every neighbor pair pushes away."
- **Oracle:** roots sorted; stability from sign(f′(y*)); destination from sign(f(y₀)) and the next root in that direction.
- **Use it:** A population with an Allee effect, dP/dt = rP(P/A − 1)(1 − P/K), dies out below the threshold A. Set A and K for a real species (the sandbox offers a coral-reef fish preset) and find the smallest herd that survives. Saves `allee_A` and `K_fish` to the shelf for the build.
- **Deeper:** Existence and uniqueness (Picard–Lindelöf): a Lipschitz f means two solutions can never cross, which is why the phase line works at all. Counterexamples: y′ = √|y| has two solutions from y(0) = 0, and y′ = y² blows up in finite time. Then the structural question: what happens to rest points when f is nudged? This sets up de-04.

### b2-de-02 · Linear first-order equations
- **You can:** solve y′ + p(t)y = q(t) with an integrating factor, and use it for anything that cools, drains or charges toward a set level.
- **Needs:** b2-de-01, `c-expgrowth`.
- **Tool:** ★ Slope field and flow sandbox, Grapher 2D.
- **Play:** A coffee cup cools in a room. Drag the room temperature and the cooling rate k, and watch the curve bend toward the room line. The gap to the room halves at a steady pace, and the sandbox marks every halving.
- **Guess:** "The gap to the room halves every 10 minutes. After 30 minutes, how far above the room is the coffee?" Drag a point on the time graph at t = 30. The reveal runs the curve through it.
- **Name it:** When the rate depends on the gap to a target, the gap decays exponentially. In general, multiply by an integrating factor μ = e^(∫p dt) so the left side becomes one derivative, then integrate. Rules: T′ = −k(T − A) gives T = A + (T₀ − A)e^(−kt), and for y′ + p(t)y = q(t), (μy)′ = μq with μ = e^(∫p dt).
- **Work it:** kind 0 (cooling, index < 3 always kind 0): room A ∈ {18, 20, 22} °C, starting gap T₀ − A ∈ {32, 48, 64, 80}, halving time h ∈ {5, 8, 10, 12} minutes, t = n·h with n ∈ {1, 2, 3}. Example: A = 20, T₀ = 84, h = 10, t = 30.
  1. **Gap at the start** T₀ − A (64).
  2. **Halvings** t/h (3).
  3. **Temperature at t** A + gap/2ⁿ (28).
  4. **Rate k** ln 2 / h, to 4 decimals (0.0693).
  kind 1 (integrating factor): y′ + (n/t)y = a(m + n)t^(m−1) for t > 0, with n, m ∈ {1, 2}, a ∈ {1, 2, 3}, y(1) = y₀ from a + 1 to a + 4. The solution is y = at^m + C/tⁿ. Example: y′ + (2/t)y = 4t, y(1) = 3.
  1. **Integrating factor** tap one of four options generated from n: tⁿ, n·t, e^(nt), n ln t (here t², 2t, e^(2t), 2 ln t; answer t²). When n = 1 these collapse to t, t, e^t, ln t, so the duplicate is dropped and t² is added: t, t², e^t, ln t (answer t).
  2. **C** y₀ − a (2).
  3. **y(2)** a·2^m + C/2ⁿ as a fraction (9/2).
  - Slips: halved the temperature instead of the gap: "Only the gap to the room halves. Add the room temperature back." · used log base 10 for k: "Continuous rates use the natural log: k = ln 2 / h." · picked e^(nt) as the factor (text templated from n): "The factor is e to the integral of p. Here p = n/t, so ∫p dt = n ln t and the factor is tⁿ." (For n = 2: "p = 2/t, so ∫p dt = 2 ln t and the factor is t²." For n = 1: "p = 1/t, so ∫p dt = ln t and the factor is t.")
- **Oracle:** kind 0: A + (T₀ − A)·2^(−n), and ln 2 / h rounded to 4 places; kind 1: exact fraction a·2^m + (y₀ − a)/2ⁿ.
- **Use it:** A medicine drip: the dose enters at a steady rate and the body clears a fixed fraction per hour. Find the level it settles at and how long it takes to get within 1/8 of that level (three halvings).
- **Deeper:** Variation of parameters, and the idea that the solution of a linear equation is a response to the forcing, convolved with a decaying kernel (the Green's function; the 2nd-order version comes back in de-11). The Laplace transform turns these equations into algebra.

### b2-de-03 · Better steppers: Heun and Runge–Kutta
- **You can:** take one step of Heun's method by hand and say how fast each method's error shrinks when the step is halved.
- **Needs:** `bc-euler`.
- **Tool:** ★ Slope field and flow sandbox (stepper picker), Step-by-step solver (error plot).
- **Play:** Three solvers run dy/dt = y from y(0) = 1 to t = 1: Euler, Heun and RK4, each with its own dotted path against the true curve e^t. Drag the step size h and watch the error plot: three straight lines with different slopes.
- **Guess:** "Halve h. Euler's error roughly halves. What happens to RK4's error?" Pick ×1/2, ×1/4, ×1/16. The reveal halves h and shows both errors on the log-log plot.
- **Name it:** Euler uses the slope at the start of a step. Heun takes a trial Euler step, measures the slope at the far end, and moves with the average of the two. RK4 averages four slopes. If the error at step h is E, halving h divides it by about 2 (Euler), 4 (Heun) or 16 (RK4). Heun: k₁ = f(t, y), k₂ = f(t + h, y + hk₁), y_new = y + (h/2)(k₁ + k₂).
- **Work it:** dy/dt = at + by with a ∈ {0, 1, 2}, b ∈ {1, −1, 2}, start (0, y₀) with y₀ ∈ {1, 2, 3}, h ∈ {1/2, 1}. Index < 3: a = 0 or 1, b = 1, h = 1/2. Example: dy/dt = t + y, y(0) = 1, h = 1/2.
  1. **k₁** slope at the start (1).
  2. **Euler step** y₀ + hk₁ (3/2).
  3. **k₂** slope at (h, Euler value) (2).
  4. **Heun step** y₀ + (h/2)(k₁ + k₂) as a fraction (7/4). The true value is 2e^(1/2) − 3/2 ≈ 1.797, so Heun is far closer than Euler's 1.5.
  5. **Halve h** tap the error factor for Euler, Heun, RK4 (1/2, 1/4, 1/16).
  - Slips: used t = 0 for k₂: "k₂ is the slope at the far end of the trial step, at time t + h." · forgot the 1/2 in Heun: "Heun moves with the average slope, (k₁ + k₂)/2." · said RK4 error halves: "RK4 is fourth order. Error scales like h⁴, so halving h divides it by 2⁴ = 16."
- **Oracle:** exact fraction y₀ + (h/2)(by₀ + a·h + b(y₀ + h·by₀)).
- **Use it:** Pick the stepper and the largest h that keeps the population model within 0.1% of RK4 with a tiny step over 50 years. Saves `stepper` (method and h). Every later model in the build runs on it.
- **Deeper:** Local error versus global error, order conditions and the Butcher tableau. Stiffness: Euler on y′ = −50y blows up unless h < 0.04, and implicit methods (backward Euler, A-stability) fix it. Gradient descent is Euler's method on x′ = −∇f(x) (b2-mv-14, b2-ai-02), and a residual network is a stack of Euler steps (neural ODEs).

### b2-de-04 · Harvesting and tipping points
- **You can:** find the largest harvest a population can take forever and the threshold below which it collapses.
- **Needs:** b2-de-01, `bc-logistic`.
- **Tool:** ★ Slope field and flow sandbox (phase line strip), Bifurcation strip.
- **Play:** A fish stock grows logistically, dP/dt = rP(1 − P/K) − H. Drag the harvest H up. The hump of the growth curve sinks, the two rest points slide toward each other, merge, and vanish. The bifurcation strip traces their positions as you drag.
- **Guess:** "Raise H until the rest points meet. At what harvest does that happen?" Drag the cursor on the bifurcation strip. The reveal pushes H to the merge point.
- **Name it:** Harvesting lowers the growth curve. While H is below the top of the hump, there are two rest points: a high stable one and a low unstable one. The low one is the collapse threshold. At H = rK/4 they merge (a saddle-node bifurcation), and above that every stock crashes. Rules: maximum sustainable yield H_max = rK/4 at P = K/2, and the rest points solve rP(1 − P/K) = H.
- **Work it:** r ∈ {1, 2} per year, K ∈ {100, 200} (thousand fish), low rest point P₁ ∈ {K/10, 2K/10, 3K/10, 4K/10}, then H = rP₁(K − P₁)/K (always an integer). Index < 3: r = 1, K = 100. Example: r = 1, K = 100, H = 16.
  1. **Maximum sustainable yield** rK/4 (25).
  2. **Rest points** two boxes, low first (20, 80).
  3. **Which is stable** tap low / high (high).
  4. **Start at P₀** (between 0 and P₁, or between P₁ and P₂): where does it go? Type the stable rest point or tap "Collapses to 0" (P₀ = 15 collapses).
  - Slips: MSY = rK: "The most you can take is the top of the growth hump, which is at P = K/2: r·(K/2)·(1/2) = rK/4." · called the low rest point stable: "Below the low rest point, growth can't keep up with the harvest. It pushes away, so it is the tipping point." · thought the stock always recovers: "Under harvest, a stock below the threshold shrinks every year, all the way to zero."
- **Oracle:** rK/4; roots of (r/K)P² − rP + H = 0, which are P₁ and K − P₁.
- **Use it:** **Fishery dial** project (see above). Saves `H_safe`.
- **Deeper:** The normal form x′ = μ + x² and why every generic fold looks like it. Hysteresis and the spruce budworm model: once a system tips, putting the parameter back doesn't bring it back. Critical slowing down (recovery time ~ 1/|f′(y*)| grows near the fold) as a measurable early-warning sign. Other bifurcations: transcritical and pitchfork.

---

## Unit 2 · Linear systems

### b2-de-05 · Systems as one vector equation
- **You can:** turn a second-order equation into a 2×2 system x′ = Ax and draw its velocity arrow at any point.
- **Needs:** b2-de-01, `g12-dot`; b2-la-05 (matrix times vector), b2-mv-09 (vector fields; the phase plane is one).
- **Tool:** ★ Slope field and flow sandbox (phase plane), Matrix pad.
- **Play:** A mass on a spring, y″ + by′ + cy = 0. The phase plane plots position across and velocity up. Drag b and c in the Matrix pad and watch the arrow field and the traced path change, while the spring bounces beside it in step.
- **Guess:** "At position 1 and velocity −1, which way does the state move?" Drag an arrow from (1, −1). The reveal draws the true arrow A·(1, −1).
- **Name it:** Two first-order equations make one vector equation. For y″ + by′ + cy = 0, let x₁ = y and x₂ = y′. Then the velocity of the state at each point is the matrix times the point. Rule: x′ = Ax with A = [[0, 1], [−c, −b]].
- **Work it:** b from 0 to 4, c from 1 to 9, point (p, q) with p, q from −3 to 3, not both 0. Index < 3: b ≤ 2, c ≤ 4, p, q from −2 to 2. Example: y″ + 3y′ + 2y = 0 at (1, −1).
  1. **Matrix** four boxes ([[0, 1], [−2, −3]]).
  2. **Arrow at (p, q)** two boxes: (q, −cp − bq) = (−1, 1).
  3. **Is the mass speeding up or slowing down here?** tap (asked only when q ≠ 0 and −cp − bq ≠ 0; here the second component, 1, has the opposite sign to the velocity −1, so slowing down).
  - Slips: put −c and −b in the top row: "The top row says x₁′ = x₂: position changes at the velocity. The spring and friction live in the bottom row." · dropped a minus: "Friction and the spring both push back, so the bottom row is −c and −b." · multiplied column by row: "Each component of the arrow is a row of A dotted with (p, q)."
- **Oracle:** A·(p, q).
- **Use it:** Write the pendulum near the bottom (θ″ = −(g/L)θ − βθ′) as a system and save its matrix as `A_pend`. It goes into the build.
- **Deeper:** Every nth-order linear equation becomes an n×n system with a companion matrix whose characteristic polynomial is the equation's own (b2-la-13). Existence and uniqueness for systems. The flow map φₜ as a family of maps with φₜ ∘ φₛ = φₜ₊ₛ (a one-parameter group), which for linear systems is e^(At) (de-08).

### b2-de-06 · Real eigenvalues: straight-line solutions
- **You can:** use eigenvalues and eigenvectors to find the straight-line solutions of x′ = Ax and build any solution from them.
- **Needs:** b2-de-05; b2-la-13 (eigenvectors).
- **Tool:** ★ Slope field and flow sandbox (phase plane, eigen-lines), Matrix pad, Eigen finder (`la`).
- **Play:** Tap starts all over the phase plane. Most paths curve, but a few run along straight lines. Drag a test arrow around a circle with the Eigen finder until A·v points along v, and the eigen-line lights up.
- **Guess:** "This start sits exactly on a line. Does it run in toward the origin or out along the line?" Pick In / Out. The reveal runs it.
- **Name it:** If Av = λv, then x = e^(λt)v solves x′ = Ax: the state slides along v, growing when λ > 0 and shrinking when λ < 0. Two different eigenvalues give two lines, and every solution is a mix. Rules: λ² − Tλ + D = 0 with T = trace and D = determinant, and x(t) = c₁e^(λ₁t)v₁ + c₂e^(λ₂t)v₂.
- **Work it:** built backwards: eigenvalues λ₁ > λ₂ from −3 to 4 (nonzero, different), eigenvectors (1, m₁) and (1, m₂) with m₁, m₂ from −2 to 2 and |m₁ − m₂| = 1, then A = P·diag(λ₁, λ₂)·P⁻¹, which has integer entries because det P = ±1. Start x(0) = c₁(1, m₁) + c₂(1, m₂) with c₁, c₂ from −2 to 2, not both 0 (so the start is never the rest point itself). Index < 3: λ's with the same sign, m's ∈ {0, 1}, and c₁, c₂ both nonzero. Example: A = [[7, −4], [8, −5]], x(0) = (3, 4).
  1. **Trace and determinant** two boxes (2, −3).
  2. **Eigenvalues** two boxes, larger first (3, −1).
  3. **Eigenvector slope for λ₁** (λ₁ − a₁₁)/a₁₂ ((3 − 7)/(−4) = 1).
  4. **Type** tap Source / Sink / Saddle (saddle: one positive, one negative).
  5. **c₁ and c₂** from x(0) = c₁(1, 1) + c₂(1, 2) (2, 1).
  - Slips: characteristic equation with +T: "It is λ² − Tλ + D. Check: the eigenvalues add to the trace and multiply to the determinant." · called mixed signs a node: "One eigenvalue pulls in and one pushes out. That is a saddle." · swapped c₁ and c₂: "c₁ goes with v₁, the eigenvector for the larger eigenvalue."
- **Oracle:** recomputed from A and x(0) only, never from the generator's values: T and D from A, λ = (T ± √(T² − 4D))/2, m₁ = (λ₁ − a₁₁)/a₁₂ and m₂ = (λ₂ − a₁₁)/a₁₂ (a₁₂ is never 0 over the whole range), the type from the signs of λ₁ and λ₂, and (c₁, c₂) by solving the 2×2 system c₁(1, m₁) + c₂(1, m₂) = x(0).
- **Use it:** For a saddle, find the one line of starts that doesn't blow up (c₁ = 0). This is the stable line, and in de-12 it becomes the knife-edge where a pendulum balances upside down.
- **Deeper:** Diagonalization A = PΛP⁻¹ and why it decouples the system. Invariant subspaces, and stable and unstable subspaces in n dimensions. Repeated eigenvalues and Jordan blocks give te^(λt) solutions (degenerate nodes).

### b2-de-07 · Complex eigenvalues: spirals and centers
- **You can:** read the turning rate, the decay per turn and the direction of a spiral from a matrix.
- **Needs:** b2-de-06, `pc-polar`.
- **Tool:** ★ Slope field and flow sandbox (phase plane), Matrix pad.
- **Play:** Drag the matrix entries until the eigenvalues go complex. The straight lines vanish and every path spirals: in, out, or round in closed loops. A clock face counts turns while a ruler measures how much smaller each loop gets.
- **Guess:** "Starting at (1, 0), does the path turn clockwise or counterclockwise?" Pick one. The reveal draws the first quarter-turn.
- **Name it:** When T² < 4D, the eigenvalues are α ± βi. The real part α decides growth or decay, and the imaginary part β is the turning rate in radians per unit time. One turn takes 2π/β, and in that time sizes scale by e^(2πα/β). Rules: α = T/2, β = √(D − T²/4), and the direction comes from the arrow at (1, 0), which is (a₁₁, a₂₁): counterclockwise when a₂₁ > 0.
- **Work it:** built backwards: α from −2 to 2, β from 1 to 4 with |α|/β ≤ 1/2 (so the size factor stays between 0.043 and 23.141), u ∈ {0, 1, 2}, a₁₁ = α + u, a₂₂ = α − u, n = β² + u², a₂₁ a divisor r of n (sign ±), a₁₂ = −n/r. Index < 3: u = 0 or 1, α ∈ {−1, 0} (α = −1 only with β ≥ 2). Example: A = [[0, −5], [1, −2]].
  1. **T and D** two boxes (−2, 5).
  2. **T² − 4D** (−16, so complex).
  3. **α and β** two boxes (−1, 2).
  4. **Type** tap Spiral in / Spiral out / Center (spiral in).
  5. **Direction** tap Clockwise / Counterclockwise (counterclockwise: at (1, 0) the arrow is (0, 1)).
  6. **Size left after one turn** e^(2πα/β), 3 decimals (e^(−π) = 0.043).
  - Slips: β = √(T² − 4D): "Inside the root it's D − T²/4, which is positive here. The minus sign belongs to the discriminant." · called α < 0 a spiral out: "A negative real part shrinks every loop. It spirals in." · read the direction from a₁₂: "Look at the arrow at (1, 0). Its second component is a₂₁. If that's positive the path heads up, so counterclockwise."
- **Oracle:** α = T/2, β = √(D − T²/4), sign of a₂₁, exp(2πα/β) rounded to 3 places.
- **Use it:** Your `A_pend` with friction: how many swings until the swing is under 1% of the start? (Solve e^(2πα k/β) < 0.01 for the whole number k.)
- **Deeper:** Euler's formula and building real solutions from a complex eigenvector: e^(αt)(cos βt·u − sin βt·w). Rotation-scaling form A ~ [[α, −β], [β, α]]. The Schrödinger equation iψ′ = Hψ is a linear system with purely imaginary eigenvalues, so quantum states turn without shrinking (b2-qu-05, gates that keep total chance).

### b2-de-08 · The trace–determinant map
- **You can:** classify any 2×2 linear system from two numbers, T and D, and know whether rest is stable.
- **Needs:** b2-de-06, b2-de-07.
- **Tool:** ★ Slope field and flow sandbox, Trace–determinant map, Matrix pad.
- **Play:** A dot on the (T, D) plane is linked to a phase portrait. Drag the dot and watch the portrait morph: saddle below the T axis, nodes outside the parabola, spirals inside, centers on the positive D axis.
- **Guess:** "Drag the dot to where rest is stable and the paths spiral." The reveal shades the region (T < 0, D > T²/4) and checks your spot.
- **Name it:** Everything about a 2×2 system's rest point is in T and D, and stable here means nearby paths come back to rest. On the parabola T² = 4D the two eigenvalues meet in one repeated eigenvalue, T/2: that's the border between nodes and spirals. Rules: D < 0 is a saddle. With D > 0, T² > 4D is a node, T² < 4D is a spiral, and T² = 4D is the border (repeated eigenvalue); T < 0 is stable, T > 0 is unstable, and T = 0 is a center. Rest is stable exactly when T < 0 and D > 0.
- **Work it:** A drawn from a pool of integer matrices with entries from −5 to 5, chosen so each region comes up (and the border cases T = 0 or T² = 4D at index ≥ 6). D = 0 never appears in the pool. Index < 3: diagonal or triangular matrices. Example: A = [[−3, 1], [1, −3]].
  1. **T and D** two boxes (−6, 8).
  2. **T² − 4D** (4).
  3. **Type** tap Saddle / Node in / Node out / Spiral in / Spiral out / Center / Border: repeated eigenvalue (node in).
  4. **Stable?** Yes / No (yes).
  - Slips: called D < 0 stable because T < 0: "A negative determinant means eigenvalues of opposite sign. One direction always escapes, so it's a saddle." · mixed up node and spiral: "Spirals need complex eigenvalues, which means T² < 4D." · called a center stable: "A center doesn't pull paths back to rest, so it isn't stable in our sense. Paths circle forever, and any small change can tip it."
- **Oracle:** region from signs of D, T and T² − 4D (T² − 4D = 0 with D > 0 is the border tap); stable exactly when T < 0 and D > 0.
- **Use it:** **Phase portrait gallery** project (see above).
- **Deeper:** The matrix exponential e^(At) = Σ(At)ⁿ/n! solves every linear system, computed via diagonalization or Jordan form. Structural stability: saddles, nodes and spirals survive small changes and centers do not. The Hartman–Grobman theorem says a nonlinear rest point looks like its linearization unless it's on the borders (sets up de-12). In n dimensions, stability means every eigenvalue has a negative real part (Routh–Hurwitz).

---

## Unit 3 · Oscillators

### b2-de-09 · Springs and damping
- **You can:** find a spring's natural frequency, its critical damping, and whether it bounces, settles fast or creeps.
- **Needs:** b2-de-08.
- **Tool:** Spring and pendulum lab, ★ Slope field and flow sandbox (phase plane).
- **Play:** A mass on a spring with a friction dial. Drag friction up and watch the motion go from bouncy to just right to slow and sticky, with the time graph and the phase-plane path changing together.
- **Guess:** "Drag the friction dial to the setting where the mass gets home fastest without overshooting." The reveal marks critical damping on the dial.
- **Name it:** A spring with mass m, stiffness k and friction c obeys mx″ + cx′ + kx = 0. With no friction it swings at ω = √(k/m). The critical amount of friction, 2√(mk), separates bouncing from creeping, and the damping ratio ζ compares c with it. Rules: ω = √(k/m), period 2π/ω, c_crit = 2√(mk) = 2mω, ζ = c/c_crit; ζ < 1 bounces, ζ = 1 is critical, ζ > 1 creeps.
- **Work it:** m ∈ {1, 2, 4}, ω from 1 to 5, k = mω², c ∈ {0, c_crit/2, c_crit, 3c_crit/2, 2c_crit}. Index < 3: m = 1. Example: m = 2, k = 18, c = 6.
  1. **ω** (3).
  2. **Period** 2 decimals (2.09).
  3. **c_crit** (12).
  4. **ζ** fraction (1/2).
  5. **Type** tap No friction / Bounces / Critical / Creeps (bounces).
  - Slips: ω = k/m: "ω is the square root: √(18/2) = 3." · c_crit = 2√(k/m): "Critical damping is 2√(mk). It has units of friction, not frequency." · called ζ > 1 bouncy: "More friction than critical means no bounce at all. It creeps home."
- **Oracle:** √(k/m), 2π/ω to 2 places, 2mω, c/(2mω), type from ζ.
- **Use it:** Car suspension: pick c for a 400 kg corner with k = 40,000 N/m so ζ = 0.3, a typical comfort setting (c_crit = 2√(400·40,000) = 8000, so c = 2400 N·s/m). Saves `zeta`.
- **Deeper:** The characteristic equation mr² + cr + k = 0 links straight back to the trace–determinant map (T = −c/m, D = k/m), so ζ = 1 is the parabola. Underdamped frequency ω√(1 − ζ²). The Laplace transform and transfer functions, poles in the complex plane, and why control engineers place poles (feedback design).

### b2-de-10 · The pendulum
- **You can:** find a pendulum's period, see why big swings are slower, and find the speed that sends it over the top.
- **Needs:** b2-de-09, `c-linapprox`.
- **Tool:** Spring and pendulum lab, ★ Slope field and flow sandbox (phase plane), Units and constants (g = 9.81 m/s²).
- **Play:** A pendulum (a bob on a rigid rod) with a length slider and a release angle you drag from 5° to 179°. The phase plane draws (θ, θ′): small swings are ellipses, big ones are lemon-shaped, and fast pushes go over the top as wavy lines.
- **Guess:** "Release at 60° instead of 10°. Is the period shorter, the same, or longer?" Pick one. The reveal runs both side by side and shows the period ratio (about 1.07).
- **Name it:** Gravity pulls the bob back with g·sin θ, so θ″ = −(g/L)sin θ. For small angles sin θ ≈ θ and the pendulum is a spring with ω = √(g/L). Big swings take longer, and on a rigid rod, with enough speed at the bottom, it loops over the top. Rules: T ≈ 2π√(L/g) for small swings; energy ½L²θ′² + gL(1 − cos θ) stays constant; it goes over the top if the bottom speed is above 2√(gL).
- **Work it:** L ∈ {0.25, 0.5, 1, 2} m, g = 9.81 m/s² from Units and constants. Index < 3: L = 1 or 0.25. Example: L = 1 m.
  1. **Small-swing period** in seconds, 2 decimals (2.01; L = 0.25 gives 1.00, 0.5 gives 1.42, 2 gives 2.84).
  2. **Release at 60°** tap Shorter / Same / Longer (longer).
  3. **Speed at the bottom to go over the top** in m/s, 2 decimals (2√(9.81·1) = 6.26; 3.13, 4.43, 8.86 for the other lengths).
  4. **Length for a 2 s period** in m, 2 decimals (gT²/(4π²) = 0.99).
  - Slips: used √(g/L) for the period: "√(g/L) is ω. The period is 2π/ω = 2π√(L/g)." · thought the period ignores amplitude: "That's only true for small swings. The real restoring pull is sin θ, which is weaker than θ, so big swings are slower." · used √(2gL) for going over the top: "√(2gL) just reaches the side. The top is 2L above the bottom, so you need √(4gL) = 2√(gL)."
- **Oracle:** 2π√(L/9.81), 2√(9.81L), 9.81·4/(4π²), all rounded to 2 places.
- **Use it:** A seconds pendulum ticks once per swing, so its full period is 2 s. Saves `L_pend` (0.99 m) and `T_pend` (2 s) for the **Pendulum clock**.
- **Deeper:** The exact period T = 4√(L/g)·K(sin(θ₀/2)), with K the complete elliptic integral, computed fast with the arithmetic-geometric mean (60° gives a factor of 1.073). A bob on a string instead of a rod goes slack near the top unless gravity alone can supply the turning, so it needs √(5gL) at the bottom (7.00 m/s for L = 1 m). The separatrix θ′ = 2√(g/L)cos(θ/2) is a homoclinic orbit that takes infinite time. The pendulum is a Hamiltonian system, and phase-space area is conserved (Liouville).

### b2-de-11 · Forcing and resonance
- **You can:** find the steady swing of a pushed, damped oscillator and see why pushing at the natural frequency is dangerous.
- **Needs:** b2-de-09, b2-de-02.
- **Tool:** Spring and pendulum lab (drive, resonance curve), Grapher 2D.
- **Play:** Push the spring with F·cos(ωt). Drag the drive frequency ω and watch the swing settle to a steady size, while the resonance curve draws amplitude against ω. Turn friction down and the peak shoots up.
- **Guess:** "Drag a marker to the drive frequency that gives the biggest swing." The reveal sweeps ω and lights the peak (near ω₀ for light friction).
- **Name it:** After the start-up fades, a pushed oscillator swings at the drive frequency, not its own. The size depends on how close the drive is to the natural frequency and how much friction there is. Rule (mass 1): x″ + cx′ + ω₀²x = F cos(ωt) settles to amplitude F / √((ω₀² − ω²)² + (cω)²).
- **Work it:** (ω₀, ω, c) from the set where (ω₀² − ω², cω) is a Pythagorean pair and the friction is light (damping ratio c/(2ω₀) from 0.14 to 0.40, so every case has a resonance peak): (5, 4, 3) → 15, (5, 3, 4) → 20, (7, 5, 2) → 26, (7, 3, 3) → 41, (9, 6, 4) → 51, (8, 4, 5) → 52, (10, 8, 6) → 60. F = denominator × q with q ∈ {1, 2, 3}. Index < 3: the first three. Example: ω₀ = 5, ω = 4, c = 3, F = 30.
  1. **ω₀² − ω²** (9).
  2. **cω** (12).
  3. **Denominator** √(9² + 12²) (15).
  4. **Amplitude** F/15 (2).
  5. **With c → 0 and ω → ω₀** tap Settles / Grows without limit (grows without limit).
  - Slips: used ω₀ − ω: "The mismatch is ω₀² − ω², squares of the frequencies." · added the two parts without squaring: "The spring-and-mass part (ω₀² − ω²) and the friction part (cω) act at right angles, so combine them with Pythagoras." · used c instead of cω: "Friction scales with speed, and speed scales with ω: the friction term is cω."
- **Oracle:** F / √((ω₀² − ω²)² + (cω)²), exact integer.
- **Use it:** **Pendulum clock** project: give `L_pend` a once-per-swing push that exactly replaces the energy friction takes each cycle. Saves `A_drive`. Part of the build.
- **Deeper:** The phase lag tan φ = cω/(ω₀² − ω²), the quality factor Q = ω₀/c, and the peak at ω = √(ω₀² − c²/2). Fourier series: any periodic push is a sum of cosines, so the response is a sum of responses. Green's functions and convolution. Parametric resonance (pumping a swing by moving your weight; the Mathieu equation). The Tacoma Narrows collapse was aeroelastic flutter, not simple resonance.

---

## Unit 4 · Nonlinear worlds

### b2-de-12 · Linearize at a rest point
- **You can:** find the rest points of a nonlinear system and classify each one by its Jacobian.
- **Needs:** b2-de-08; b2-mv-02 (partial derivatives), b2-mv-03 (linear approximation), b2-mv-08 (the Jacobian determinant).
- **Tool:** ★ Slope field and flow sandbox (phase plane), Matrix pad.
- **Play:** The full pendulum with friction on its phase plane. Zoom into any rest point with a pinch, and the curved flow straightens into the linear portrait from de-08. Drag the friction slider from zero up: the bottom turns from a center into a spiral live, while the top stays a saddle.
- **Guess:** "Zoom into the pendulum standing straight up (θ = π). Which portrait do you see?" Pick Spiral / Saddle / Center. The reveal zooms.
- **Name it:** Near a rest point, a nonlinear system acts like its best linear approximation, the Jacobian matrix of partial derivatives. Classify the Jacobian with T and D. Rule: for x′ = f(x, y), y′ = g(x, y), J = [[f_x, f_y], [g_x, g_y]] at the rest point.
- **Work it:** x′ = y, y′ = −ax + x³ − by with a ∈ {1, 4, 9}, b ∈ {0, 1, 2}, except b = 2 is never paired with a = 1 (that gives T² = 4D at the origin, a border case). Rest points (0, 0) and (±√a, 0). Index < 3: a = 1 or 4, b = 1. Example: a = 4, b = 1.
  1. **Rest points** x values, three boxes smallest first (−2, 0, 2).
  2. **J at (2, 0)** lower-left entry −a + 3x² (8).
  3. **D there** (−8).
  4. **Type at (2, 0)** tap Saddle / Node in / Node out / Spiral in / Spiral out / Center (saddle).
  5. **Type at (0, 0)** tap Saddle / Node in / Node out / Spiral in / Spiral out / Center (T = −1, D = 4, T² − 4D = −15: spiral in; b = 0 gives a center).
  - Slips: forgot the x³ term's derivative: "Differentiate −ax + x³ in x: −a + 3x². At x = 2 that's −4 + 12 = 8." · plugged the rest point in before differentiating: "Take partial derivatives first, then put in the point." · called a saddle stable: "D < 0 always means a saddle, whatever T is."
- **Oracle:** rest points 0 and ±√a; J₂₁ = 2a at ±√a; types from T, D.
- **Use it:** Add the full pendulum phase portrait to the build: the stable spirals at θ = 0, 2π, …, the saddles at θ = ±π, and the separatrix between swinging and spinning.
- **Deeper:** Hartman–Grobman and when linearization lies (a linear center can be a slow nonlinear spiral). Lyapunov functions: energy that only goes down proves stability without solving. Poincaré–Bendixson: in the plane, bounded paths that avoid rest points end on a closed loop, so planar flows can't be chaotic. Limit cycles (van der Pol) and Hopf bifurcations.

### b2-de-13 · Predator and prey
- **You can:** find the rest point of a predator–prey system and the period of its cycles near rest.
- **Needs:** b2-de-12, b2-de-07.
- **Tool:** Two-species world, ★ Slope field and flow sandbox (phase plane).
- **Play:** Rabbits and foxes as two time graphs and as a loop in the phase plane. Drag the starting numbers and watch closed loops of every size around one rest point. Near the rest point, fox peaks come about a quarter-cycle after rabbit peaks.
- **Guess:** "Raise the rabbits' birth rate. Where does the rest point move?" Drag the rest point. The reveal shows that the foxes rise and the rabbits don't.
- **Name it:** Prey grow and get eaten, and predators starve and eat. Each species' rest level is set by the other's numbers. Near rest, the populations cycle with a period set by the two growth rates. Rules: x′ = ax − bxy, y′ = −cy + dxy, rest point (c/d, a/b), period near rest 2π/√(ac).
- **Work it:** a, c ∈ {1/2, 1, 2}, prey rest x* ∈ {20, 40, 50, 100}, predator rest y* ∈ {10, 20, 25}, b = a/y*, d = c/x* (shown as decimals). Index < 3: a = c = 1. Example: a = 1, b = 0.05, c = 0.5, d = 0.01.
  1. **Prey at rest** c/d (50).
  2. **Predators at rest** a/b (20).
  3. **D of the Jacobian at rest** bd·x*y* = ac (0.5).
  4. **Period near rest** 2 decimals (2π/√0.5 = 8.89).
  - Slips: prey rest = a/b: "Prey hold steady when predators neither grow nor shrink, so it's the predator's numbers, c/d, that fix the prey level." · period 2π/(ac): "The turning rate is √D = √(ac). The period is 2π/√(ac)." · thought the loops spiral in: "Lotka–Volterra keeps a conserved quantity, so every loop closes. Real data spirals because the model leaves things out."
- **Oracle:** c/d, a/b, ac, 2π/√(ac) rounded to 2 places.
- **Use it:** The lynx and hare fur records (Hudson's Bay Company, about a 10-year cycle). Fit a and c so the period is about 10 years, and add the second species to the population half of the build.
- **Deeper:** The conserved quantity V = dx − c ln x + by − a ln y, so orbits are level curves (b2-mv-01, contour maps). Add prey crowding (logistic prey) and the loops spiral in. Use a Holling type II predator (Rosenzweig–MacArthur) and a Hopf bifurcation creates a limit cycle: the paradox of enrichment. Competitive exclusion for two competing species.

### b2-de-14 · Epidemics: the SIR model
- **You can:** compute R₀, the herd-immunity threshold and the size of an epidemic's peak.
- **Needs:** b2-de-12, b2-de-04.
- **Tool:** Epidemic model (SIR), ★ Slope field and flow sandbox.
- **Play:** S, I and R curves for a town. Drag the contact rate β and the infectious days D. The I curve rises and falls, and the peak always comes exactly when S crosses the herd-immunity line. Drag the vaccination slider and watch the outbreak shrink to nothing.
- **Guess:** "Infections peak at the moment S falls to what fraction of the town?" Drag a line on the S graph. The reveal marks N/R₀.
- **Name it:** Each infected person makes β contacts a day for D days, so they infect R₀ = βD others in a fully susceptible town. Infections grow while R₀·(S/N) > 1, so they peak when S/N = 1/R₀, and vaccinating more than 1 − 1/R₀ stops outbreaks. Rules: S′ = −βSI/N, I′ = βSI/N − γI, R′ = γI, with γ = 1/D, R₀ = β/γ, and peak I/N = 1 − (1 + ln R₀)/R₀ (starting with almost everyone susceptible).
- **Work it:** (β per day, D days) from {(0.5, 4), (0.5, 5), (0.6, 5), (0.4, 10), (0.5, 10), (0.75, 4)} giving R₀ ∈ {2, 2.5, 3, 4, 5, 3}. Index < 3: R₀ ∈ {2, 4, 5}. Example: β = 0.4, D = 10.
  1. **R₀** (4).
  2. **Herd-immunity threshold** percent, 1 decimal (75.0).
  3. **S at the peak** as a fraction of the town (1/4).
  4. **Peak infected** percent, 1 decimal (40.3; R₀ = 2: 15.3, 2.5: 23.3, 3: 30.0, 5: 47.8).
  - Slips: R₀ = β/D: "R₀ is contacts per day times days infectious: β × D." · threshold 1/R₀: "1/R₀ is the fraction that can stay susceptible. You need to protect the rest: 1 − 1/R₀." · thought the peak is when half are infected: "The peak is when new cases just balance recoveries, which happens when S/N = 1/R₀."
- **Oracle:** βD; 100(1 − 1/R₀); 1/R₀; 100(1 − (1 + ln R₀)/R₀), rounded to 1 place.
- **Use it:** **Outbreak planner** project (see above). Saves `R0` and `vax_needed`. This is the population half's final screen.
- **Deeper:** The conserved quantity I + S − (N/R₀)ln S gives the peak formula. The final size s∞ = e^(−R₀(1 − s∞)) solved with the Lambert W function. SEIR and the next-generation matrix, where R₀ is a spectral radius (b2-la-14, powers and the long run). The stochastic SIR as a branching process: a single case dies out with probability 1/R₀ (b2-pr-19, random walks and Markov chains). Epidemics on networks, where the hubs matter most.

### b2-de-15 · Chaos (Deeper lesson)
- **You can:** find the fixed point of the logistic map, test its stability, and count how fast two nearby starts fall apart.
- **Needs:** b2-de-01, b2-de-12, b2-de-11.
- **Tool:** Chaos panel, Spring and pendulum lab (twin driven pendulums), Grapher 3D (Lorenz).
- **This is the track's Deeper lesson.** The map shows it as an optional branch past the build, and the build is finished without it. It still has a plain path.
- **Play:** Two driven, damped pendulums start a hair apart (0.001°). For a while they swing together, then suddenly not at all. Beside them, the logistic map's cobweb: drag r from 2.5 to 4 and watch one point become 2, then 4, then a blur.
- **Guess:** "The gap between two starts doubles every step. Starting 0.000001 apart, how many steps until they differ by 0.1?" Place a point on the step axis. The reveal runs the two starts at r = 4 and plots the gap on a log scale.
- **Name it:** Chaos is a deterministic rule whose future you can't predict, because tiny differences grow exponentially. The logistic map shows it in one line. Rules: x_{n+1} = rx_n(1 − x_n), fixed point x* = 1 − 1/r, stable when |f′(x*)| = |2 − r| < 1; a gap that doubles each step reaches size G from g after about log₂(G/g) steps.
- **Work it:** kind 0 (fixed point): r ∈ {3/2, 2, 5/2, 10/3, 7/2}. Example: r = 5/2.
  1. **Fixed point** fraction (3/5).
  2. **Slope there** 2 − r as a fraction (−1/2).
  3. **Stable?** Yes / No (yes).
  kind 1 (sensitivity): starting gap 10^(−k) with k from 4 to 10, target G ∈ {0.1, 0.5}. Example: gap 10⁻⁶, G = 0.1.
  1. **Steps** the smallest whole n with 2ⁿ·10^(−k) ≥ G (17).
  - Slips: fixed point 1/r: "Solve x = rx(1 − x): divide by x to get 1 = r(1 − x), so x = 1 − 1/r." · called r = 7/2 stable: "|2 − 7/2| = 3/2 > 1. The fixed point repels, and the orbit settles into a cycle instead." · rounded 16.6 down: "After 16 doublings the gap is still under the target. You need the next whole step."
- **Oracle:** kind 0: 1 − 1/r, 2 − r, |2 − r| < 1; kind 1: ceil(log₂(G·10^k)).
- **Use it:** Weather: if forecast errors double every 2 days, how many days does a 100× better measurement buy? (log₂ 100 ≈ 6.6 doublings, about 13 days.) Then drive the build's pendulum hard enough to go chaotic and save that setting to the Notebook.
- **Deeper:** The Lorenz system (σ = 10, ρ = 28, β = 8/3) and its strange attractor of fractal dimension about 2.06. Lyapunov exponents (ln 2 for r = 4). Feigenbaum's constant 4.669… is the same for every one-hump map with a rounded (quadratic) top. "Period three implies chaos" (Li–Yorke, Sharkovskii's ordering). Kolmogorov–Sinai entropy measures chaos in bits per step (b2-in-03, entropy). Shadowing: why simulations of chaotic systems are still trustworthy in a statistical sense. The three-body problem is chaotic too (b2-or-07, orbits as a differential equation).
