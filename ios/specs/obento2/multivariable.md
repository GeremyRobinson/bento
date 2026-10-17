# Bento² · Multivariable calculus and optimization (track mv, 20 lessons)

**What it is:** calculus for things that depend on more than one input, like the height of a hill at every spot. The first half reads and adds up landscapes and flows. The second half is "finding the best": gradients, rolling downhill, fences, and knowing when the lowest point you found is the lowest there is.

**Needs:** AP Calculus (specs/wave2: `ap-calc-ab.md`, `ap-calc-bc.md`). Linear algebra (la) helps from lesson 08 on; nothing is locked.

**Main tool:** ★ Surface explorer (a 3D landscape z = f(x, y) with its contour map on the floor and a ball you can place). The Best-choice finder grows out of it in the second half.

## The build: the valley finder

The learner builds a tool that finds the lowest point on any landscape. It starts from the default landscape `land`, "Two lakes": f(x, y) = (x² − 1)² + y² + x/4. Its lowest point is at about (−1.03, 0), height about −0.254; a second, higher valley bottom sits at about (0.97, 0), height about 0.246; a pass (saddle) sits at about (0.06, 0). The learner can type or sculpt their own landscape instead, and every piece works on it.

What each unit adds:

| Unit | Lessons | What it adds to the valley finder |
|---|---|---|
| 1 · Landscapes | 01 to 04 | The landscape itself: contour map, a hiker who reads height, the two slopes, the local tangent plane and the rate of climb along a trail. |
| 2 · Adding up over space | 05 to 08 | The lake: fill the basin around a low point to a chosen level and read the water's volume and surface area. |
| 3 · Fields and flow | 09 to 10 | The water: a flow layer showing where water runs and spins, and a work meter for hauling a cart along a trail. |
| 4 · Which way is down | 11 to 14 | The compass and the ball: gradient arrows, a stop classifier (peak, pit or pass) and gradient descent with a step-size dial. |
| 5 · Fences | 15 to 17 | The fence: search only inside a boundary or along a road, with the Lagrange readout, and fit a model by finding the bottom of its error bowl. |
| 6 · Hard landscapes | 18 to 20 | The guarantee and the escape: a convexity check, a fix for narrow valleys (momentum, Newton step) and random restarts with noise, so the finder reports the lowest point, not just a low one. |

When done, the valley finder takes any f(x, y) (and an optional fence), returns the lowest point with its height, says how it knows (Hessian test, convexity or the restart count), and shows the lake that would collect there. It is saved to the Notebook and is the same machine the AI capstone uses to train a model (b2-ai-02: Gradient descent: take a step downhill).

## Units

1. **Landscapes** (b2-mv-01 to 04): surfaces, contours, partial derivatives, tangent planes, the chain rule.
2. **Adding up over space** (b2-mv-05 to 08): double integrals, curved regions, polar, change of variables.
3. **Fields and flow** (b2-mv-09 to 10): vector fields, divergence and curl, line integrals, Green's theorem.
4. **Which way is down** (b2-mv-11 to 14): directional derivatives, the gradient, the Hessian test, gradient descent.
5. **Fences** (b2-mv-15 to 17): Lagrange multipliers, closed regions and inequality fences, least squares.
6. **Hard landscapes** (b2-mv-18 to 20): convexity, narrow valleys and conditioning, many valleys and noise.

Part 1 (units 1 to 3) is "landscapes and flows". Part 2 (units 4 to 6) is "finding the best".

## Small projects

| After | Project | What the learner makes and keeps | Shelf name |
|---|---|---|---|
| b2-mv-04 | **My landscape** | Type a formula or sculpt a terrain. Get its contour map and a hiker readout (height, f_x, f_y, rate of climb on a drawn trail). | `land` |
| b2-mv-08 | **Fill the lake** | Pick a low spot and a water level. The volume builder fills the basin and reports the lake's volume and surface area. | `lakeVolume`, `lakeArea` |
| b2-mv-12 | **Rain map** | Rain falls on `land`. Streams follow −∇f, each spot is colored by the valley it drains to, and the passes between basins are marked. | `basins` |
| b2-mv-16 | **Best spot in the park** | Draw a park fence on `land`. Find the lowest spot inside it (for a pond) and the lowest spot along a road (with λ shown). | `fencedBest` |
| b2-mv-20 | **The valley finder** (the build) | The full tool, as described above. | `lowest` |

## New for Development

Tools (toolbox names from `bento2/research/toolbox.md`, track 3, plus what this spec adds):

1. **★ Surface explorer** (toolbox ★): z = f(x, y) in 3D with a synced contour map on the floor, a draggable point and a ball. Needs: a height-slice plane that drops its cut to the floor as a contour (01), a tangent-plane overlay with zoom (03), and a chord tool between two surface points (18).
2. **Slice tool** (toolbox): cut with x = a, y = b or any vertical plane through a point at angle θ; the cut curve opens in Grapher 2D with a draggable tangent (02, 11).
3. **Hiker on a trail** (new): draw a path on the contour map; a walker moves along it; strips show height and rate of climb against time (04) and accumulated work (10).
4. **Volume builder** (toolbox): boxes on a rectangular grid (05), on a sweep-line region with curved edges (06), on a polar grid of rings and wedges (07), and filled up to a water level (project 2). Slider for the number of boxes; total shown beside the exact value.
5. **Grid warper** (new, shares la's Transformation playground): a (u, v) grid mapped into (x, y), with one small square's image and its area against |det J| (08).
6. **Vector field painter** (toolbox, shares de's Flow sandbox): arrows, flowing particles, a paddle wheel (curl meter) and a small patch of dye that grows or shrinks (divergence meter) (09); circulation vs "curl × area" side by side for Green's theorem (10).
7. **Gradient arrows** (toolbox): ∇f at every grid point, plus a direction compass at one point with a "slope vs angle" dial (11, 12).
8. **Rain map** (new): streamlines of −∇f, basins colored, passes marked (project 3). Shares the flow engine with de.
9. **Shape morpher** (new): f = ax² + bxy + cy² with three sliders, bowl / dome / saddle / trough badge and live D (13, 18).
10. **Best-choice finder** (toolbox): gradient descent with a step-size dial (shares ai's Learning-rate dial), trail of steps, step counter (14, 19); fence drawing with ∇f and ∇g arrows and a λ readout (15); a boundary scan that unrolls the fence into a height graph (16); momentum and Newton toggles (19); multi-start and a temperature dial (20).
11. **Error bowl** (new, shares ai's Line fitter and Loss landscape): a scatter plot beside the surface E(m, b), with the current line as a ball on the bowl (17).

Signature pictures to build (all live):
- The contour map and its 3D hill side by side, tight lines meaning steep (01).
- Boxes under a surface getting thinner until the volume is exact (05, 07).
- The paddle wheel spinning in a field (09).
- The gradient arrow at right angles to the contour (12).
- Bowl turning into a saddle as one slider moves (13).
- Gradient descent: a ball finding the bottom, then overshooting when the step is too big (14).
- ∇f lining up with the fence's ∇g at the best spot (15).
- Zig-zag down a narrow valley, then a straight shot with momentum (19).

Rendering: every generator draws through the `count()` and `aOrAn()` helpers and the term printer, which drops coefficients of 1, drops 0 terms, never prints x¹ or a plus sign directly before a minus sign, and redraws a field or function that comes out all zero.

Shared with other tracks: Grapher 3D surface (ai loss landscape, re gravity well), Flow sandbox (de), Vector board and Matrix pad (la), Learning-rate dial (ai), Simulator for random restarts (pr).

---

# Part 1 · Landscapes and flows

## Unit 1 · Landscapes

### b2-mv-01 · Landscapes and contour maps
- **You can:** read a contour map and tell steep ground from gentle ground.
- **Needs:** pc-transform, c-implicit.
- **Tool:** ★ Surface explorer, Grapher 3D.
- **Play:** A hill z = f(x, y) sits above its contour map. Drag a height slider: a flat plane cuts the hill at that height and the cut drops to the floor as one contour. Drag the hill's two stretch sliders and watch the contours squeeze and spread.
- **Guess:** For f = x² + 4y², pick the shape of the contour f = 4: a circle, an oval wider left-to-right, or an oval taller up-and-down. The plane drops to height 4 and draws it (wider left-to-right: it crosses at x = ±2, y = ±1).
- **Name it:** A function of two inputs is a landscape: f(x, y) is the height above the spot (x, y). A contour is every spot at one height, f(x, y) = k. Where contours for evenly spaced heights crowd together, the ground is steep. Formula: contour at height k is {(x, y) : f(x, y) = k}.
- **Work it:** f(x, y) = ax² + by², with a and b two different values from {1, 4, 9}, and height k = 36m², m ∈ {1, 2}. Point (x₀, y₀) with x₀, y₀ ∈ −3..3 (index < 3: 0..2, m = 1). Example: f = x² + 4y², k = 36, point (2, −1).
  1. **Height at the point:** ax₀² + by₀² (example: 8).
  2. **Contour f = k crosses the positive x-axis at x =** √(k/a) (example: 6).
  3. **It crosses the positive y-axis at y =** √(k/b) (example: 3).
  4. **Steeper going along:** tap "x" or "y" (the axis with the smaller crossing, so the bigger coefficient; example: y).
  - Slips: typed k/a (36) in step 2: "On the x-axis, ax² = k, so x is the square root of k/a." Typed √(k/b) in step 2: "On the x-axis y is 0, so only the a x² term is left." Picked the wider direction in step 4: "The contour reaches farther along that axis, so you go farther to climb the same height there. Farther means gentler."
- **Oracle:** `[a*x0^2 + b*y0^2, sqrt(k/a), sqrt(k/b), a > b ? "x" : "y"]`
- **Use it:** Open the default landscape `land` ("Two lakes"). Set the height slider to 0.3 and count the closed contours (two pockets, one per valley; the right one is small because its bottom is at about 0.246). The map is saved as the start of the valley finder.
- **Deeper:** Level sets in higher dimensions: f(x, y, z) = k is a surface (a level surface), and functions of n inputs have (n − 1)-dimensional level sets. Contours of a quadratic form ax² + bxy + cy² are ellipses or hyperbolas whose axes are the eigenvectors of [[a, b/2], [b/2, c]] (b2-la-15). The implicit function theorem says when a contour near a point really is a smooth curve: when the gradient there is not zero.

### b2-mv-02 · Partial derivatives: slice and take the slope
- **You can:** find the slope of a landscape in the x direction and in the y direction.
- **Needs:** c-derivdef, c-product, b2-mv-01.
- **Tool:** ★ Surface explorer, Slice tool.
- **Play:** A vertical plane y = b slices the hill; the cut curve opens beside it with its tangent at x = a. Drag b and a and watch the slice and its slope change. Flip to an x = a slice to get the other slope.
- **Guess:** On f = x²y, slice at y = 2. Drag a tangent line onto the slice at x = 1 to the steepness you expect. The true tangent snaps in (slope 4).
- **Name it:** A partial derivative is an ordinary derivative along one slice: hold every other input fixed and differentiate in one. ∂f/∂x treats y as a constant; ∂f/∂y treats x as a constant. Formula: f_x(a, b) = lim_{h→0} (f(a + h, b) − f(a, b))/h.
- **Work it:** f(x, y) = c·xᵐyⁿ + px + qy, c ∈ 2..4, m, n ∈ {1, 2, 3}, p, q ∈ −5..5 not 0, point (x₀, y₀) with x₀, y₀ ∈ −2..2 (index < 3: m = 2, n = 1, c ∈ 2..3, x₀, y₀ ∈ 1..2). Example: f = 3x²y − 2x + 5y at (1, 2).
  1. **∂f/∂x:** tap the right formula from 4 (example: 6xy − 2).
  2. **f_x at the point:** c·m·x₀^(m−1)·y₀ⁿ + p (example: 10).
  3. **∂f/∂y:** tap the right formula from 4 (example: 3x² + 5).
  4. **f_y at the point:** c·n·x₀ᵐ·y₀^(n−1) + q (example: 8).
  - Slips: picked 6xy + 3x² − 2 (product rule on x²y): "In ∂f/∂x, y is a constant, so x²y differentiates like 2·x times that constant: 2xy." Swapped f_x and f_y values: "That is the slope in the y direction. ∂f/∂x walks along x." Kept the qy term in f_x: "5y has no x in it. Along an x slice it doesn't change, so its slope is 0."
- **Oracle:** central difference (f(x₀ + h, y₀) − f(x₀ − h, y₀))/2h with h = 1e−5, rounded to an integer, and the same in y.
- **Use it:** Put the hiker on `land` at (1/2, 1/2) and read f_x and f_y (f_x = 4x³ − 4x + 1/4 = −5/4, f_y = 2y = 1). The hiker readout gains "slope east" and "slope north".
- **Deeper:** Mixed partials: f_xy = f_yx whenever both are continuous (Clairaut's theorem, proof sketch by a double difference quotient). The classic counterexample f = xy(x² − y²)/(x² + y²) has f_xy(0, 0) = −1 and f_yx(0, 0) = 1. Partials can exist where f is not even continuous: f = xy/(x² + y²) at the origin.

### b2-mv-03 · Tangent planes and linear approximation
- **You can:** write the flat plane that touches a landscape and use it to estimate nearby heights.
- **Needs:** c-linapprox, b2-mv-02.
- **Tool:** ★ Surface explorer (tangent-plane overlay), scientific calculator.
- **Play:** A flat sheet touches the surface at a point you drag. Zoom in on the touch point and the surface flattens until it can't be told apart from the sheet.
- **Guess:** On the bowl f = x² + y² touching at (1, 1): pick whether the plane's estimate of f(1.2, 0.9) is too high, too low or exact. Zoom and lift the reveal (too low: a bowl sits above every tangent plane).
- **Name it:** Near a point, a smooth landscape looks like a plane whose two slopes are f_x and f_y. Use it to estimate heights close by. Formula: f(x, y) ≈ f(a, b) + f_x(a, b)(x − a) + f_y(a, b)(y − b).
- **Work it:** f(x, y) = px² + qxy + ry², p, q, r ∈ −3..3 (not all 0), base point (a, b) with a, b ∈ −2..2, target (a + 0.1s, b + 0.1t) with s, t ∈ −2..2 not both 0. Answer to 1 decimal place (it is exact). Index < 3: p, q, r ∈ 0..3, a, b ∈ 1..2. Example: f = x² + 3xy − y², base (1, 2), target (1.1, 1.9).
  1. **f(a, b):** (example: 3).
  2. **f_x(a, b):** 2pa + qb (example: 8).
  3. **f_y(a, b):** qa + 2rb (example: −1).
  4. **Estimate:** f + f_x·0.1s + f_y·0.1t (example: 3 + 0.8 + 0.1 = 3.9; the true value is 3.87).
  - Slips: typed only f_x·Δx + f_y·Δy (0.9): "That is the change. Add it to the starting height f(a, b)." Used x instead of x − a (typed 3 + 8·1.1 − 1·1.9): "Multiply each slope by how far you move, 0.1, not by where you end up." Sign of Δy lost (3.7): "y goes from 2 to 1.9, so Δy = −0.1 and f_y·Δy = +0.1."
- **Oracle:** `f(a,b) + fx*dx + fy*dy` rounded to 0.1, with fx, fy from central differences.
- **Use it:** The hiker on `land` now carries a small tangent tile under its feet; tilt of the tile = (f_x, f_y). Saved as the hiker's "local plane".
- **Deeper:** Differentiable means the error shrinks faster than the step: (f(p + h) − L(h))/‖h‖ → 0. The derivative of a map from Rⁿ to Rᵐ is an m × n matrix, the Jacobian (b2-la-05). The next term is ½ hᵀHh with the Hessian H, so the plane's error is quadratic; this is the two-variable Taylor polynomial and returns in b2-mv-13.

### b2-mv-04 · The chain rule on a trail
- **You can:** find how fast your height changes as you walk a path across a landscape.
- **Needs:** bc-param, b2-mv-02.
- **Tool:** ★ Surface explorer, Hiker on a trail.
- **Play:** Draw a trail on the contour map. A walker follows it at the speed you set while a strip below plots height against time; drag the trail and the strip redraws.
- **Guess:** On the strip's time axis, tap the moment you think the walker climbs fastest, judging from where the trail cuts contours most tightly. The rate-of-climb curve draws in and its peak lights up.
- **Name it:** Your height changes for two reasons at once: moving in x and moving in y. Each slope times how fast you move that way, added. Formula: dz/dt = f_x·x′(t) + f_y·y′(t).
- **Work it:** f from {cxy, cx²y, cx + dy², cx² + dy²}, c, d ∈ −3..3 not 0; trail x = t + p, y = qt² + r with p ∈ −2..2, q ∈ {1, 2}, r ∈ −2..2; time t₀ ∈ {0, 1, 2} (index < 3: f = cx²y with c ∈ 1..2, t₀ = 1). Example: f = x²y, x = t + 1, y = t², t₀ = 1.
  1. **Where is the walker?** two boxes (example: (2, 1)).
  2. **f_x and f_y there:** two boxes (example: 4, 4).
  3. **x′(t₀) and y′(t₀):** two boxes (example: 1, 2).
  4. **dz/dt:** (example: 4·1 + 4·2 = 12).
  - Slips: typed f_x + f_y (8): "Each slope counts only as much as you move that way. Multiply f_x by x′ and f_y by y′." Crossed the pairs (f_x·y′ + f_y·x′): "f_x goes with motion in x, so it pairs with x′." Used the slopes at t = 0 instead of at t₀: "Take the slopes where the walker is at time t₀."
- **Oracle:** central difference of t ↦ f(x(t), y(t)) at t₀, rounded to an integer.
- **Use it:** Draw a trail from one valley of `land` to the other over the pass and read the steepest climb rate. **Project 1 · My landscape** opens: type or sculpt your own terrain, then keep the contour map and the full hiker (height, slopes, local plane, rate of climb). Saves `land`.
- **Deeper:** The general chain rule is a product of Jacobian matrices: D(g ∘ f) = Dg·Df. Running it from the output backward, reusing each product, is backpropagation, the way every neural network computes its gradient (b2-ai-06). Implicit differentiation falls out too: along a contour dz/dt = 0, so dy/dx = −f_x/f_y.

## Unit 2 · Adding up over space

### b2-mv-05 · Double integrals: volume under a surface
- **You can:** find the volume under a surface over a rectangle by integrating one direction, then the other.
- **Needs:** c-riemann, c-ftc, b2-mv-01.
- **Tool:** Volume builder, ★ Surface explorer.
- **Play:** Boxes stand on an n × n grid under z = f(x, y), each as tall as the surface at its center. Drag n from 2 to 100; the running total settles on the true volume.
- **Guess:** For z = x + y over the square 0 ≤ x ≤ 2, 0 ≤ y ≤ 2, drag a bar to your guess for the volume. The boxes fill in and the total lands on 8.
- **Name it:** A double integral adds height × tiny area over a region. Over a rectangle, do it as two ordinary integrals: integrate in y with x held fixed (one slice's area), then add the slices in x. Formula: ∬_R f dA = ∫ₐᵇ ∫_c^d f(x, y) dy dx; the average height is ∬_R f dA ÷ area of R.
- **Work it:** f = e + px + qy + rxy with e ∈ 0..5, p, q ∈ 0..3, r ∈ 0..2 (not all 0), rectangle [0, m] × [0, n], m, n ∈ 1..3. Answers as fractions. Index < 3: r = 0, m, n ∈ 1..2. Example: f = x + 2y + xy on [0, 2] × [0, 3].
  1. **Area of the base:** mn (example: 6).
  2. **Inner integral ∫₀ⁿ f dy:** tap from 4 (example: 15x/2 + 9).
  3. **Volume:** em·n + p·m²n/2 + q·mn²/2 + r·m²n²/4 (example: 33).
  4. **Average height:** volume ÷ area (example: 11/2).
  - Slips: integrated the inner integral over [0, m] (wrong limits): "The inner integral is in y, so it runs over y's range, 0 to n." Volume came out e·1 for the constant (forgot it spreads over the base): "A constant height e over the whole base adds e × area." Typed the volume as the average: "Average height is volume divided by the area of the base."
- **Oracle:** midpoint rule on a 200 × 200 grid (exact for this family, since f is linear in each variable), as a fraction.
- **Use it:** Volume of the "Two lakes" landscape `land` above height −1 over [−2, 2] × [−1, 1], read off the volume builder at n = 100 (it is the earth you would move to flatten the plot; exactly 344/15 ≈ 22.93). Saves `slabVolume`.
- **Deeper:** Fubini's theorem: if ∬|f| is finite, either order gives the same answer. Without that, it can fail: ∫₀¹∫₀¹ (x² − y²)/(x² + y²)² dy dx = π/4 but the other order gives −π/4. The cure is the Lebesgue integral, where "volume" is defined by measure; sketch the idea of measuring a set instead of slicing it.

### b2-mv-06 · Regions with curved edges, and swapping the order
- **You can:** set up a double integral over a region with curved sides, in either order.
- **Needs:** c-areavg, b2-mv-05.
- **Tool:** Volume builder (sweep-line region), Grapher 2D.
- **Play:** The region between y = x² and y = kx is shaded. Drag a vertical sweep line across it and watch its bottom and top end points ride the two curves; flip to a horizontal sweep and the ends ride different curves.
- **Guess:** Shown ∫₀¹ ∫ₓ¹ g(x, y) dy dx, tap which of 4 shaded regions it covers. The sweep line runs and paints the true region (the triangle above y = x, below y = 1).
- **Name it:** For a curved region, the inner limits are curves: each vertical slice runs from the bottom curve to the top curve. To swap the order, describe the same region with horizontal slices. Formula: ∬_R f dA = ∫ₐᵇ ∫_{g₁(x)}^{g₂(x)} f dy dx = ∫_c^d ∫_{h₁(y)}^{h₂(y)} f dx dy.
- **Work it:** Region between y = x² and y = kx, k ∈ {1, 2, 3}; integrand f ∈ {1, x, y} (index < 3: k ∈ {1, 2}, f = 1). Answers as fractions. Example: k = 2, f = x.
  1. **Where the curves meet (x > 0):** k (example: 2).
  2. **Vertical slice runs from y = … to y = …:** tap (x² to kx).
  3. **∬_R f dA:** f = 1 gives k³/6, f = x gives k⁴/12, f = y gives k⁵/15 (example: 4/3).
  4. **Horizontal slices:** tap the swapped setup (y from 0 to k², x from y/k to √y).
  - Slips: chose kx to x² in step 2, got a negative answer: "Between 0 and k, x² is below kx. Bottom curve first." Took y from 0 to kx (forgot the lower curve): "That counts the area under the parabola too. Start each slice at y = x²." Kept x-limits 0 to k after swapping: "Outer limits must be numbers for y now: y goes from 0 to k²."
- **Oracle:** closed form `[k^3/6, k^4/12, k^5/15][f]`, checked against a 400 × 400 midpoint sum within 0.01.
- **Use it:** The shoreline of a lake is a curve. On `land`, the contour f = 0 around the left valley bounds a curved region; the volume builder fills it with vertical slices whose ends sit on the shoreline. This is the region-filling engine the lake will use.
- **Deeper:** Some integrals are only possible after a swap: ∫₀¹ ∫ₓ¹ e^(y²) dy dx has no elementary inner antiderivative, but swapping gives ∫₀¹ y e^(y²) dy = (e − 1)/2. Fubini-Tonelli: for f ≥ 0 the swap is always allowed. Region boundaries have area zero, which is why edges never matter.

### b2-mv-07 · Polar double integrals
- **You can:** integrate over disks, rings and wedges using polar boxes.
- **Needs:** bc-polar, pc-polar, b2-mv-06.
- **Tool:** Volume builder (polar grid), ★ Surface explorer.
- **Play:** A disk is cut into polar boxes by rings and wedges. Drag the ring and wedge counts; each box shows its area, and the outer boxes are visibly bigger.
- **Guess:** Two polar boxes have the same Δr and Δθ; one is 3 times as far from the center. Pick how many times bigger its area is: 1, 3 or 9. The boxes highlight and their areas print (3).
- **Name it:** In polar coordinates a small box is about Δr thick and rΔθ wide, so its area is r Δr Δθ. The extra r is the stretch. Formula: ∬_R f dA = ∫∫ f(r cos θ, r sin θ) r dr dθ.
- **Work it:** Region: full disk (θ over 2π), half disk (π) or quarter disk (π/2), radius R ∈ 1..4, or a full ring a ≤ r ≤ b with 1 ≤ a < b ≤ 4; integrand f = rⁿ with n ∈ {0, 1, 2}, shown as 1, √(x² + y²) or x² + y². Answer: the coefficient of π, a fraction. Index < 3: n ∈ {0, 2}, full or half disk. Example: half disk radius 2, f = x² + y².
  1. **θ runs over:** tap 2π, π or π/2 (example: π).
  2. **r runs from … to …:** two boxes (example: 0, 2).
  3. **Integrand with dA:** tap r, r², r³ (example: r²·r = r³).
  4. **Value ÷ π:** (θ range ÷ π)·(b^(n+2) − a^(n+2))/(n + 2) (example: 16/4 = 4, so 4π).
  - Slips: left out the extra r (example gives 8/3): "dA is r dr dθ. Without the r, the outer boxes count as small as the inner ones." Used 2π for a half disk: "A half disk sweeps θ from 0 to π." Wrote x² + y² as r: "x² + y² = r², not r."
- **Oracle:** `(angle/pi) * (b^(n+2) - a^(n+2)) / (n+2)`, checked against a 400 × 400 polar midpoint sum.
- **Use it:** A round pond on `land` with depth 1 − r² holds ∫₀^{2π}∫₀¹ (1 − r²) r dr dθ = π/2 of water (in these units). Saves `pondVolume`.
- **Deeper:** The bell curve's area. Let I = ∫_{−∞}^{∞} e^(−x²) dx. Then I² = ∬ e^(−(x² + y²)) dA over the whole plane = ∫₀^{2π}∫₀^∞ e^(−r²) r dr dθ = π, so I = √π. That √π is the one in the normal distribution's 1/√(2π) (b2-pr-07). Extend to n dimensions to get the volume of an n-ball.

### b2-mv-08 · Change of variables and the Jacobian
- **You can:** turn a slanted region into a rectangle and fix the area with a determinant.
- **Needs:** b2-mv-07, b2-la-07 (determinant).
- **Tool:** Grid warper (shares la's Transformation playground), Matrix pad.
- **Play:** A (u, v) grid sits on the left; its image in (x, y) bends on the right. Drag the map's four numbers; one highlighted small square shows its image and that image's area beside |det J|.
- **Guess:** For x = 2u + v, y = u + 3v, drag a bar to guess the area of the image of the unit square. The parallelogram fills in (area 5).
- **Name it:** A change of variables stretches every tiny square by the same factor locally: the absolute determinant of the Jacobian. Polar is one case, with factor r. Formula: dx dy = |det ∂(x, y)/∂(u, v)| du dv, and |det ∂(x, y)/∂(u, v)| = 1/|det ∂(u, v)/∂(x, y)|.
- **Work it:** u = ax + by, v = cx + dy, a, b, c, d ∈ −3..3 with ad − bc ≠ 0; region 0 ≤ u ≤ s, 0 ≤ v ≤ t, s, t ∈ 1..6 (index < 3: |ad − bc| ∈ {1, 2}, s, t ∈ 1..4). Example: u = x + y, v = x − y, s = 2, t = 4.
  1. **det ∂(u, v)/∂(x, y):** ad − bc (example: −2).
  2. **Area of the region in (u, v):** st (example: 8).
  3. **Area of the region in (x, y):** st/|ad − bc|, fraction (example: 4).
  - Slips: multiplied by |det| (16): "This map goes from (x, y) to (u, v), so it stretches x, y areas by 2. Going back, divide." Kept the sign (−4): "Area can't be negative. Use the absolute value of the determinant." Typed ad + bc: "The determinant is ad − bc."
- **Oracle:** solve for the four corners in (x, y) and apply the shoelace formula.
- **Use it:** **Project 2 · Fill the lake** opens. Pick a low spot of `land` and a water level; the volume builder fills the basin (using curved regions from 06) and reports volume and surface area. Saves `lakeVolume`, `lakeArea`. The build gains the lake.
- **Deeper:** In n dimensions dV = |det J| du₁…duₙ. Spherical coordinates give ρ² sin φ dρ dφ dθ, and the volume of a unit n-ball is π^(n/2)/Γ(n/2 + 1), which shrinks to 0 as n grows. For densities, p_Y(y) = p_X(x)/|det J|: this is the rule behind normalizing flows in machine learning (pr, ai).

## Unit 3 · Fields and flow

### b2-mv-09 · Vector fields: spread and spin
- **You can:** read a vector field and measure how much it spreads out and how much it spins.
- **Needs:** b2-mv-02, b2-la-01 (vectors, Vector board).
- **Tool:** Vector field painter (shares de's Flow sandbox), Vector board.
- **Play:** Arrows F(x, y) = ⟨P, Q⟩ cover the plane and particles flow along them. Drop a paddle wheel anywhere to see it spin, or a drop of dye to see it spread or squeeze. Drag the field's numbers.
- **Guess:** In F = ⟨−y, x⟩, a paddle wheel is placed at (2, 0), away from the center. Pick: spins counterclockwise, clockwise, or doesn't spin. Drop it (counterclockwise: curl is 2 everywhere, not just at the center).
- **Name it:** A vector field puts an arrow at every point, like wind or water. Divergence measures how much it spreads out from a point; curl measures how much it spins a small wheel there (counterclockwise is positive). Formulas: div F = P_x + Q_y, curl F = Q_x − P_y.
- **Work it:** Linear fields F = ⟨ax + by, cx + dy⟩, a, b, c, d ∈ −3..3, then (index ≥ 5) F = ⟨axy, bx² + cy⟩ at a point (x₀, y₀), x₀, y₀ ∈ −2..2. Index < 3: a, b, c, d ∈ −2..2. Example: F = ⟨2x + y, 3x − y⟩.
  1. **P_x and Q_y:** two boxes (example: 2, −1).
  2. **div F:** (example: 1).
  3. **Q_x and P_y:** two boxes (example: 3, 1).
  4. **curl F:** (example: 2).
  5. **The dye:** tap "spreads", "squeezes", "neither" (sign of div; example: spreads).
  - Slips: curl as P_y − Q_x (−2): "Counterclockwise is positive: Q_x − P_y." div as P_y + Q_x: "Divergence uses each component in its own direction: P_x + Q_y." Read spin from the arrows' direction (picked "doesn't spin" for a shear field ⟨y, 0⟩): "Straight arrows can still spin a wheel if they're faster on one side. curl = −1 here."
- **Oracle:** central differences of P and Q at the point, combined.
- **Use it:** Turn on the water layer for `land`: the field −∇f (water runs downhill), drawn with the painter. Its divergence is −(f_xx + f_yy), so dye squeezes in valley bottoms and spreads near the pass. The build gains the flow layer.
- **Deeper:** In 3D, curl is a vector ∇ × F and div is ∇ · F, with the identities ∇ · (∇ × F) = 0 and ∇ × (∇f) = 0. For a linear field F = Ax, div F = trace A and curl comes from the antisymmetric part of A (la). Helmholtz decomposition: a nice field is a gradient plus a curl.

### b2-mv-10 · Line integrals, work and Green's theorem
- **You can:** add up a field's push along a path, and around a loop using the spin inside.
- **Needs:** b2-mv-09, b2-mv-04, bc-vector.
- **Tool:** Vector field painter, Hiker on a trail (work strip).
- **Play:** Drag a path through a force field. At each point the push along the path is drawn as a colored bar, and the work meter adds it up. Close the path into a loop and a second meter adds curl × area inside; the two meters agree.
- **Guess:** Going once counterclockwise around the unit circle, pick the total work of F = ⟨x, y⟩: positive, negative or zero. Then of F = ⟨−y, x⟩. The meters run (zero, then positive: 2π).
- **Name it:** Work adds the part of the field that points along your path. Around a closed loop, the total equals all the small spins inside added up (Green's theorem). Formulas: W = ∫_C F · dr = ∫ (P x′(t) + Q y′(t)) dt; ∮_C F · dr = ∬_R (Q_x − P_y) dA for a counterclockwise loop.
- **Work it:** Two kinds. (A) Segment from (0, 0) to (p, q), p, q ∈ −3..3 with (p, q) ≠ (0, 0), F = ⟨ax + by, cx + dy⟩, a, b, c, d ∈ −2..2. (B) Counterclockwise rectangle [0, m] × [0, n], m, n ∈ 1..4, same F. Index < 3: kind A, p, q ∈ 0..2. Example (A): F = ⟨y, 2x⟩ to (1, 2). Example (B): F = ⟨y, 2x⟩ around [0, 2] × [0, 3].
  1. (A) **F · r′(t) = kt, k =** ap² + (b + c)pq + dq² (example: 6).
  2. (A) **W:** k/2, fraction (example: 3).
  3. (B) **curl F:** c − b (example: 1).
  4. (B) **Area inside:** mn (example: 6).
  5. (B) **Work around the loop:** (c − b)mn (example: 6).
  - Slips: typed k for W (forgot ∫₀¹ t dt = 1/2): "Along the segment the push grows like t. ∫₀¹ kt dt = k/2." Used div instead of curl in Green: "Work around a loop counts spin, Q_x − P_y, not spread." Sign flipped: "Green's theorem as written is for counterclockwise. Clockwise flips the sign."
- **Oracle:** trapezoid rule with 10,000 steps along the path, rounded to a fraction with denominator 2.
- **Use it:** Haul a cart along two different trails between the same two spots of `land` against gravity (field −∇f). Both meters read the same: the work you do against gravity is the height difference, and the work done by the field −∇f is minus it. Note the rule this hints at; b2-mv-12 names it. The build gains the work meter.
- **Deeper:** Stokes' theorem ∮ F · dr = ∬ (∇ × F) · n dS and the divergence theorem ∯ F · n dS = ∭ ∇ · F dV are the same statement as Green's: ∫_∂M ω = ∫_M dω, in the language of differential forms. Green's theorem in flux form gives the shoelace area formula. Gravity's field is a gradient, which is why orbits conserve energy (or).

# Part 2 · Finding the best

## Unit 4 · Which way is down

### b2-mv-11 · Directional derivatives
- **You can:** find the slope of a landscape in any direction you choose.
- **Needs:** b2-mv-02, b2-la-03 (dot product).
- **Tool:** ★ Surface explorer (direction compass), Slice tool.
- **Play:** Stand at a point and turn a compass needle. The slice in that direction opens beside it, and a dial plots slope against the needle's angle as you turn it.
- **Guess:** Before turning, drag the needle to where you think the slope is steepest uphill. Spin it once; the slope-vs-angle curve draws in (a cosine wave) and its peak lights up.
- **Name it:** The slope in direction u (a unit vector) mixes the two partial slopes by how much you move each way. Formula: D_u f = f_x u₁ + f_y u₂, with u₁² + u₂² = 1.
- **Work it:** f = px² + qxy + ry², p, q, r ∈ −3..3, point (a, b), a, b ∈ −2..2; direction v from {⟨3, 4⟩, ⟨4, −3⟩, ⟨−5, 12⟩, ⟨6, 8⟩, ⟨1, 0⟩, ⟨0, −1⟩}; reject draws with f_x = f_y = 0 at the point. Index < 3: v ∈ {⟨1, 0⟩, ⟨0, −1⟩, ⟨3, 4⟩}. Example: f = x² + 3xy at (1, 1), v = ⟨3, 4⟩.
  1. **f_x and f_y at the point:** two boxes (example: 5, 3).
  2. **Length of v:** (example: 5).
  3. **Unit direction u:** two fraction boxes (example: 3/5, 4/5).
  4. **D_u f:** fraction (example: 15/5 + 12/5 = 27/5).
  - Slips: used v without dividing (27): "A direction has to have length 1, or the slope gets multiplied by the arrow's length. Divide ⟨3, 4⟩ by 5." Length as 3 + 4: "Length is √(3² + 4²) = 5." Dotted with the point instead of the slopes: "Mix the slopes f_x and f_y, not the coordinates."
- **Oracle:** (f(P + hu) − f(P − hu))/2h with h = 1e−5, as a fraction with the direction's length as denominator.
- **Use it:** On `land` at (1/2, 0), find the slope heading straight toward the left valley, u = ⟨−1, 0⟩ (D_u f = 5/4). It's positive: heading left you first climb toward the pass at x ≈ 0.06 before the ground drops into the valley. The hiker readout gains "slope this way".
- **Deeper:** Directional derivatives can exist in every direction while f is not differentiable: f = x²y/(x⁴ + y²) has all of them at the origin but is not even continuous there (along y = x² it equals 1/2). So directional derivatives can all exist without differentiability.

### b2-mv-12 · The gradient: steepest way up
- **You can:** find the gradient, the direction of steepest climb, and how steep it is.
- **Needs:** b2-mv-11.
- **Tool:** Gradient arrows, ★ Surface explorer.
- **Play:** Arrows cover the contour map, each pointing straight uphill. Drag a point: its arrow always crosses its contour at a right angle and grows where the contours crowd.
- **Guess:** At a marked point on a contour map, tap which of 4 drawn arrows is the gradient. The real arrow fades in (the one at right angles to the contour, pointing to higher ground).
- **Name it:** The gradient packs both slopes into one arrow. It points the steepest way up, its length is that steepest slope, and it is at right angles to the contour. Every directional slope is its shadow. Formulas: ∇f = ⟨f_x, f_y⟩; D_u f = ∇f · u = |∇f| cos θ.
- **Work it:** f = ax² + by², a, b ∈ 1..4, point (x₀, y₀), x₀, y₀ ∈ −3..3, not both 0. Steepest slope to 2 decimal places. Index < 3: only combos where (2ax₀, 2by₀) is a scaled Pythagorean pair, so the length is a whole number. Example: f = x² + 2y² at (3, 2).
  1. **∇f:** two boxes (example: ⟨6, 8⟩).
  2. **Steepest slope |∇f|:** (example: 10).
  3. **Steepest way down:** tap from 4 arrows (−∇f; example: ⟨−6, −8⟩).
  4. **Slope walking along the contour:** (0).
  - Slips: |∇f| as 6 + 8: "The length is √(6² + 8²) = 10." Picked +∇f for the way down: "∇f points up. Downhill is −∇f." Typed a nonzero slope along the contour: "Along a contour your height doesn't change, so the slope is 0; that's why ∇f is at right angles to it."
- **Oracle:** `hypot(2*a*x0, 2*b*y0)` rounded to 2 decimals.
- **Use it:** **Project 3 · Rain map** opens. Rain falls on `land`; streams follow −∇f, each spot is colored by the valley it drains to, and the pass between the two basins is marked. Saves `basins`. The build gains the compass: gradient arrows everywhere.
- **Deeper:** Gradient fields are conservative: ∫_C ∇f · dr = f(end) − f(start) for any path (the fundamental theorem for line integrals), which is why both carts in b2-mv-10 did the same work, and why curl ∇f = 0. The gradient depends on how you measure length: with a different inner product, the steepest direction changes (Riemannian gradient; the natural gradient in ai).

### b2-mv-13 · Peaks, pits and passes
- **You can:** find the flat spots of a landscape and tell a peak from a pit from a pass.
- **Needs:** c-extrema, c-concavity, b2-mv-12.
- **Tool:** Shape morpher, ★ Surface explorer.
- **Play:** f = ax² + bxy + cy² with three sliders. Drag them and the surface morphs from bowl to saddle to dome to trough, with a live badge showing D = 4ac − b².
- **Guess:** For f = x² + 3xy + y², pick: bowl, dome or saddle. Both x and y slices curve up, so it looks like a bowl. The morpher sets the sliders and turns the surface (saddle: along y = −x it curves down).
- **Name it:** At a peak, a pit or a pass, the ground is flat: ∇f = 0. The second derivatives say which. Put them in the Hessian and use its determinant D. Formulas: H = [[f_xx, f_xy], [f_xy, f_yy]], D = f_xx f_yy − f_xy². D > 0 and f_xx > 0: pit (minimum). D > 0 and f_xx < 0: peak (maximum). D < 0: pass (saddle). D = 0: the test can't tell.
- **Work it:** Two kinds. (A) f = x³ − 3s²x + my², s ∈ 1..3, m ∈ −3..3 not 0; critical points (s, 0) and (−s, 0). (B) f = x² + bxy + y², b ∈ 0..4, at the origin. Index < 3: kind A with s = 1, m > 0. Example (A): f = x³ − 3x + 2y².
  1. **How many flat spots:** (example: 2).
  2. **The one with x > 0:** x = s (example: 1).
  3. **At (s, 0): f_xx, f_yy, f_xy:** three boxes (6s, 2m, 0; example: 6, 4, 0).
  4. **D there:** 12sm (example: 24).
  5. **Kind at (s, 0):** tap pit, peak, pass, can't tell (m > 0: pit; m < 0: pass).
  6. **Kind at (−s, 0):** tap (m > 0: pass; m < 0: peak; example: pass).
  - (B) steps: f_xx = 2, f_yy = 2, f_xy = b; D = 4 − b²; kind (b < 2: pit; b = 2: can't tell; b > 2: pass).
  - Slips: D as f_xx f_yy + f_xy²: "The cross term is subtracted: D = f_xx f_yy − f_xy²." Called (−s, 0) a pit because f_yy > 0 (or called a D < 0 point a pit because f_xx > 0): "D < 0 means some direction curves up and another curves down. That's a pass, whatever f_xx says." Said "pit" when D = 0: "D = 0 means the test is silent. Here f = (x + y)², a trough: every point of the line y = −x is lowest."
- **Oracle:** signs of the eigenvalues of H (both +: pit, both −: peak, mixed: pass, a zero: can't tell).
- **Use it:** Find all three flat spots of `land` with the Best-choice finder's "flat spot" search and classify them: two pits and one pass. The build gains the stop classifier.
- **Deeper:** The Hessian's eigenvalues are the curvatures along its eigenvectors (b2-la-15), and the test is "H positive definite". Degenerate cases: the monkey saddle x³ − 3xy² has D = 0 and three down-slopes. Morse theory: on a closed surface, pits − passes + peaks equals the Euler characteristic (2 on a sphere, 0 on a donut), so flat spots can't be added one at a time.

### b2-mv-14 · Gradient descent: roll downhill
- **You can:** find a low point by stepping against the gradient, and pick a step size that works.
- **Needs:** b2-mv-12, b2-mv-13.
- **Tool:** Best-choice finder (step-size dial, shares ai's Learning-rate dial), ★ Surface explorer.
- **Play:** Drop a ball on a bowl. Each tap takes one step x ← x − η∇f, leaving a dot on the contour map. Drag η: small steps creep, medium ones land, big ones bounce, bigger ones fly off.
- **Guess:** On f = x² + y² from (3, 2): with η = 0.5 the ball lands on the bottom in one step. Pick what happens with η = 1.1: settles, bounces forever, or flies off. Run 10 steps (flies off: each step multiplies the position by 1 − 2.2 = −1.2).
- **Name it:** To go down, step against the gradient by a small amount η. On a bowl f = ax² + by², each step multiplies x by 1 − 2ηa and y by 1 − 2ηb, so it settles only if both factors are between −1 and 1. Formulas: x_{k+1} = x_k − η∇f(x_k); converges on f = ax² + by² exactly when 0 < η < 1/max(a, b).
- **Work it:** f = ax² + by², a, b ∈ 1..5, start (x₀, y₀), x₀, y₀ ∈ −4..4 even, not both 0, η ∈ {1/10, 1/8, 1/5, 1/4} with η < 1/max(a, b), so the run settles. Answers as fractions or exact decimals. Index < 3: a = 1, b ∈ 1..2, η = 1/4. Example: f = x² + 2y², start (4, 2), η = 1/4.
  1. **∇f at the start:** two boxes (example: ⟨8, 8⟩).
  2. **Position after one step:** two boxes (example: (2, 0)).
  3. **Factor on x each step, 1 − 2ηa:** (example: 1/2).
  4. **x after two steps:** x₀(1 − 2ηa)² (example: 1).
  5. **Settles for every step size below:** 1/max(a, b), fraction (example: 1/2).
  - Slips: added the gradient ((6, 4)): "+∇f is uphill. Subtract it." Forgot η ((−4, −6)): "A full gradient step is usually far too big. Multiply ∇f by η first." Typed 2/max(a, b) in step 5: "Here f = ax², so the slope is 2ax and the factor is 1 − 2ηa. It stays between −1 and 1 only while η < 1/a."
- **Oracle:** run the update with exact fractions for the asked number of steps; step 5 by bisection on the boundary η where |1 − 2η·max(a, b)| reaches 1.
- **Use it:** Drop the ball on `land` at (1/2, 1) with η = 0.1. Run it and save where it stops as `bestSoFar` (it ends near (0.97, 0), the higher valley). The build gains the ball, and its first lesson: descent finds a low point, not always the lowest.
- **Deeper:** If ∇f changes no faster than L (L-smooth), any η ≤ 1/L makes f drop every step, by at least (η/2)|∇f|² (the descent lemma, with proof sketch). If f is also μ-strongly convex, the error shrinks like (1 − μ/L)ᵏ. Gradient descent is Euler's method on the gradient flow dx/dt = −∇f (de, bc-euler).

## Unit 5 · Fences

### b2-mv-15 · Lagrange multipliers: the best spot on a fence
- **You can:** find the best point along a constraint by lining up two gradients.
- **Needs:** b2-mv-12.
- **Tool:** Best-choice finder (fence mode), ★ Surface explorer.
- **Play:** A fence curve g(x, y) = c lies across a contour map. Walk along it with a height meter; ∇f and ∇g are drawn at your feet. At the best spot the fence just touches a contour and the two arrows line up.
- **Guess:** On the fence x + 2y = 8 over f = xy, place a point where you think f is highest. Walk the fence and watch the meter peak (at (4, 2), f = 8).
- **Name it:** Along a fence, you're at the best spot when you can't climb by sliding along it. That happens when the contour touches the fence, so the two gradients line up (they point along the same line). The multiplier λ says how much the best value grows if you loosen the fence by one unit. Formulas: ∇f = λ∇g and g(x, y) = c; λ = d(best f)/dc.
- **Work it:** Two kinds. (A) Largest xy on px + qy = c, p, q ∈ 1..4, c = 2pqm with m ∈ 1..3, so the answer is x = qm, y = pm, best f = pqm², λ = m. (B) Smallest x² + y² on px + qy = c with (p, q) from {(3, 4), (4, 3), (1, 2), (2, 1), (5, 12)}, c = (p² + q²)m, m ∈ 1..2, so the answer is (pm, qm), best value (p² + q²)m², λ = 2m. Index < 3: kind A, m = 1. Example (A): p = 2, q = 3, c = 24.
  1. **The equations:** tap "y = 2λ, x = 3λ" from 4 (∇(xy) = ⟨y, x⟩, ∇g = ⟨p, q⟩).
  2. **x:** (example: 6).
  3. **y:** (example: 4).
  4. **Best value of f:** (example: 24).
  5. **λ:** (example: 2).
  - Slips: put the whole budget into x (x = 12, y = 0): "That's an end of the fence, where xy = 0. The best spot is where the gradients line up." Paired y with q: "∇(xy) = ⟨y, x⟩, so y goes with the x-part of ∇g, which is p." For λ typed the best value: "λ is the rate: loosen the fence from 24 to 25 and the best xy grows by about λ = 2."
- **Oracle:** search the fence numerically (step 0.001 in x) for the best f; λ as (best f at c + 0.01 − best f at c)/0.01 rounded.
- **Use it:** A road crosses `land` along y = 1/2; find the lowest point on the road with the fence mode and read λ. It sits at about (−1.03, 1/2), height about −0.004, with λ = 1: here g = y, so ∇f = (f_x, 2y) = λ(0, 1) gives λ = 2y = 1, so shifting the road up by a small d raises its lowest height by about d. The build gains road search.
- **Deeper:** Proof sketch: at a constrained best, ∇f has no part along the fence's tangent, so it is a multiple of the normal ∇g. With several constraints, ∇f = Σλᵢ∇gᵢ. λ is the shadow price, and the Lagrangian L = f − λ(g − c) leads to duality: the best value equals a min over λ of a max over (x, y), under convexity. The method fails when ∇g = 0 at the best point (constraint qualification); example: minimize x on y² = x³.

### b2-mv-16 · Fenced plots: best spot on a closed region
- **You can:** find the highest and lowest values of a landscape on a closed region by checking the inside and the edge.
- **Needs:** c-extrema, b2-mv-13, b2-mv-15.
- **Tool:** Best-choice finder (boundary scan), ★ Surface explorer.
- **Play:** A square plot is fenced on a bowl. Drag the bowl's bottom (p, q) around, or drag a corner to resize the square plot. The boundary scan walks the fence and unrolls its height into a graph; interior flat spots and corners light up as candidates, and the highest and lowest are crowned, so you see the lowest point jump from inside to the fence as the bottom leaves the plot.
- **Guess:** For f = (x − 3)² + (y − 1)² on the square 0 ≤ x ≤ 2, 0 ≤ y ≤ 2, pick: the lowest point is inside or on the fence. The candidates light up (on the fence, at (2, 1): the bowl's bottom is outside the plot).
- **Name it:** On a closed, bounded region a continuous landscape has a highest and a lowest point. They're at flat spots inside or somewhere on the fence, so check both. For a fence written as an inequality g ≤ c, either the fence doesn't matter (∇f = 0 inside) or you're pressed against it (Lagrange again: for a minimum, ∇f = −μ∇g with μ ≥ 0, so downhill points out through the fence).
- **Work it:** f = (x − p)² + (y − q)², p, q ∈ −2..5, on the square [0, m] × [0, m], m ∈ 2..4. Index < 3: m = 2, p, q ∈ 0..3. Example: p = 3, q = 1, m = 2.
  1. **Is the bowl's bottom (p, q) inside the plot?** tap Yes / No; on the fence counts as Yes (example: No).
  2. **Lowest point:** two boxes, each coordinate clamped into [0, m] (example: (2, 1)).
  3. **Lowest value:** (example: 1).
  4. **Highest value:** largest of the four corners (example: 10, at (0, 0) and (0, 2)).
  - Slips: answered (p, q) when it's outside: "(3, 1) is off the plot. The lowest you can reach is on the fence, as close to it as possible." For the highest value used the bowl's bottom or an edge midpoint: "A bowl rises in every direction from its bottom, so on a square its highest point is a corner." Clamped wrong coordinate (2, 2): "Only x is out of range. Keep y = 1, which is already inside."
- **Oracle:** grid search over the square with step 0.01 (exact, since answers are on the grid).
- **Use it:** **Project 4 · Best spot in the park** opens. Draw a park fence on `land` and find its lowest point (for a pond), then the lowest point on the road y = 1/2 from b2-mv-15. Saves `fencedBest`. The build gains the fence.
- **Deeper:** The Karush-Kuhn-Tucker conditions: ∇f = −Σμᵢ∇gᵢ, μᵢ ≥ 0, μᵢ(gᵢ − cᵢ) = 0 (complementary slackness). Projected gradient descent: step downhill, then step back inside the fence. When f and the fences are all linear, the best point is a corner of the region: linear programming and the simplex method (cs).

### b2-mv-17 · Least squares: the best line is the bottom of a bowl
- **You can:** fit a line to data by finding the lowest point of its error.
- **Needs:** st-lsrl, b2-mv-13, b2-la-11 (projection).
- **Tool:** Error bowl (shares ai's Line fitter and Loss landscape), Data table (pr).
- **Play:** Drag data points on a scatter plot. Beside it, the total squared error E(m, b) is a bowl over the (m, b) plane, and your current line y = mx + b is a ball on it. Drag the line and the ball moves.
- **Guess:** For the points (−1, 1), (0, 2), (1, 6), drag the line to where you think it fits best. The ball rolls to the bowl's bottom and the best line snaps in (y = (5/2)x + 3).
- **Name it:** The best line makes the total squared miss as small as possible. E is a bowl in m and b, so set both slopes to 0; that gives two linear equations, the normal equations. Formulas: E(m, b) = Σ(yᵢ − mxᵢ − b)²; m Σx² + b Σx = Σxy and m Σx + b n = Σy.
- **Work it:** n = 3 points at x = −1, 0, 1 (index < 3), then n = 4 points at x = 0, 1, 2, 3; y-values integers 0..9. Answers as fractions. Steps for n = 3, example: (−1, 1), (0, 2), (1, 6).
  1. **Σx, Σx², Σy, Σxy:** four boxes (example: 0, 2, 9, 5).
  2. **m:** (example: 5/2).
  3. **b:** (example: 3).
  - Steps for n = 4 (x = 0, 1, 2, 3, so Σx = 6, Σx² = 14). Example: (0, 1), (1, 2), (2, 4), (3, 5).
  1. **Σy and Σxy:** two boxes (example: 12, 25).
  2. **m:** (4Σxy − 6Σy)/20 (example: 28/20 = 7/5).
  3. **b:** (Σy − 6m)/4 (example: 9/10).
  - Slips: used (Σx)² for Σx² (0): "Square each x first, then add: 1 + 0 + 1 = 2." Fit through two points only (m = 5/2, b = 7/2): "The best line uses all the points. With Σx = 0, b is the mean of the y-values, 3." Swapped m and b: "m is the slope, the number in front of x. b is where the line crosses x = 0."
- **Oracle:** m = (nΣxy − ΣxΣy)/(nΣx² − (Σx)²), b = (Σy − mΣx)/n.
- **Use it:** Measure `land`'s height at 4 spots along the road and fit a straight-line trend; the error bowl in the build now shows that "fitting" and "finding the lowest point" are the same job (b2-ai-02).
- **Deeper:** In matrix form AᵀAw = Aᵀy: the fit is the projection of y onto the column space of A (b2-la-11). If the noise is Gaussian, least squares is the maximum-likelihood fit (b2-pr-09). Adding λ|w|² (ridge regression) is the Lagrange form of "fit well with a fence on the size of w" (b2-mv-15).

## Unit 6 · Hard landscapes

### b2-mv-18 · Convexity: when the lowest point is the only one
- **You can:** tell whether a landscape has just one valley, so any low point you find is the lowest.
- **Needs:** b2-mv-13, b2-mv-14.
- **Tool:** ★ Surface explorer (chord tool), Best-choice finder (multi-start), Shape morpher.
- **Play:** Pick two points on a surface and stretch a straight string between them. On some surfaces the string never dips below the ground; on others it does. Drop 20 balls at random and run descent on each.
- **Guess:** On f = x² + y² + 3 sin x, pick: all 20 balls end at the same spot, or they split. Run them (they all meet: there's one valley, though f is not convex everywhere). Then on `land` (they split into two valleys).
- **Name it:** A landscape is convex if the string between any two points never goes below the ground. Then it has no false bottoms: every low point is the lowest. For smooth f, convex means the ground never curves down in any direction, at any point. Formulas: f(tA + (1 − t)B) ≤ t f(A) + (1 − t) f(B) for 0 ≤ t ≤ 1; smooth f in 2D is convex when f_xx ≥ 0, f_yy ≥ 0 and f_xx f_yy − f_xy² ≥ 0 at every point.
- **Work it:** Two kinds. (A) f = ax² + bxy + cy², a, c ∈ {1, 2, 4, 8, 9}, b ∈ −6..6: compute f_xx = 2a, f_yy = 2c, f_xy = b, D = 4ac − b², then tap Convex / Not convex. (B) Largest b ≥ 0 keeping ax² + bxy + cy² convex, with ac a perfect square from {(1, 1), (1, 4), (4, 1), (2, 8), (1, 9), (4, 9)}: b = 2√(ac). Index < 3: kind A with a = c = 1, b ∈ 0..3. Example (A): f = 2x² + 3xy + y². Example (B): a = 1, c = 4.
  1. (A) **f_xx, f_yy, f_xy:** three boxes (example: 4, 2, 3).
  2. (A) **D:** (example: −1).
  3. (A) **Convex?** tap (example: Not convex).
  4. (B) **Largest b:** (example: 4).
  - Slips: said convex because a > 0 and c > 0: "Both slices curving up isn't enough. D < 0 means a diagonal slice curves down." Typed √(ac) in kind B (2): "Convex needs 4ac − b² ≥ 0, so b ≤ 2√(ac) = 4." Said Not convex at D = 0 with a, c > 0: "D = 0 is allowed. The string can lie flat along the surface; that's still convex."
- **Oracle:** both eigenvalues of [[2a, b], [b, 2c]] ≥ 0 (kind A); 2√(ac) (kind B).
- **Use it:** Run the convexity check on `land`: it fails between the two valleys (f_xx = 12x² − 4 < 0 for |x| < 1/√3). The build gains a "one valley?" badge, and knows that on `land` it needs more than one ball.
- **Deeper:** Convex sets, and the rules that sums, maxima and compositions with linear maps keep convexity. Jensen's inequality f(E[X]) ≤ E[f(X)] (pr), which proves that cross-entropy is at least entropy (Gibbs' inequality, b2-in-09). Strong convexity (H ⪰ μI, every direction curving up by at least μ) gives one minimum and fast descent. Neural network losses are not convex, yet descent works well in practice: an open question with partial answers (overparameterization, b2-ai-09).

### b2-mv-19 · Narrow valleys: zig-zags, momentum and Newton
- **You can:** explain why descent crawls in a narrow valley and pick the step that helps most.
- **Needs:** b2-mv-14, b2-mv-18.
- **Tool:** Best-choice finder (momentum and Newton toggles, step counter), ★ Surface explorer.
- **Play:** A valley f = ax² + by² is stretched by dragging b. Descent runs at the best fixed step, η = 1/(a + b), and zig-zags across the narrow walls; a counter shows the steps until the error has shrunk 1,000 times. Toggle momentum (the ball keeps some speed) or a Newton step and race them.
- **Guess:** With a = 1, b = 3 and η set to the best step, the error shrinks 1,000 times in 10 steps. Stretch to b = 30. Pick: about the same, about 10 times as many, or about 100 times as many. Run it (104 steps: about 10 times).
- **Name it:** The condition number κ is the steepest curvature divided by the gentlest. The best fixed step can only shrink the error by (κ − 1)/(κ + 1) each time, so a narrow valley (big κ) is slow. Momentum cuts the cost to about √κ; a Newton step uses the Hessian and lands on a bowl's bottom in one step. Formulas: κ = λ_max(H)/λ_min(H); best η = 2/(λ_max + λ_min); shrink factor (κ − 1)/(κ + 1); Newton x ← x − H⁻¹∇f.
- **Work it:** f = ax² + by², a ∈ 1..3, b ∈ a + 1..10a. Answers as fractions; steps as a whole number (calculator open). Index < 3: (a, b) ∈ {(1, 2), (1, 3), (2, 3)}. Example: a = 1, b = 3.
  1. **κ:** b/a (example: 3).
  2. **Best step size η:** 2/(2a + 2b) = 1/(a + b) (example: 1/4).
  3. **Shrink factor per step:** (b − a)/(b + a) (example: 1/2).
  4. **Steps to shrink the error 1000 times:** smallest k with ((b − a)/(b + a))ᵏ ≤ 1/1000 (example: 10).
  5. **Newton steps to reach the bottom of this bowl:** (1).
  - Slips: κ = a/b (1/3): "κ is the steep curvature over the gentle one, so it's at least 1." Typed η = 1/b in step 2: "With η = 1/b the steep direction's factor is 1 − 2 = −1, so it bounces forever. The best fixed step balances both directions: 1/(a + b)." Step count by dividing (1000 ÷ 2 = 500): "The error is multiplied by 1/2 each step, so solve (1/2)ᵏ ≤ 1/1000: k = 10."
- **Oracle:** compute the factor with exact fractions and count k by repeated multiplication until ≤ 1/1000. Checked values: (1, 2) → 7, (1, 3) → 10, (2, 3) → 5, (1, 4) → 14, (1, 9) → 31, (1, 30) → 104.
- **Use it:** `land`'s valleys are round enough for plain descent, but add y-stretch (y² → 25y²) and watch it zig-zag; turn on momentum and save the faster run. The build gains the "narrow valley" fixes.
- **Deeper:** Heavy-ball momentum (and Nesterov's, nearly) reaches rate about (√κ − 1)/(√κ + 1), the best possible for first-order methods on quadratics. Conjugate gradient solves an n-dimensional quadratic in at most n steps. Newton's method converges quadratically near a minimum (digits double each step); quasi-Newton (BFGS) builds H from gradients. Preconditioning rescales the landscape to make κ near 1; Adam is a diagonal preconditioner (b2-ai-14).

### b2-mv-20 · Many valleys: false bottoms, passes and noise
- **You can:** find the lowest point on a landscape with several valleys, and say how sure you are.
- **Needs:** b2-mv-13, b2-mv-18, b2-mv-19.
- **Tool:** Best-choice finder (multi-start, temperature dial), Simulator (pr), ★ Surface explorer.
- **Play:** On a landscape with two valleys, drop one ball: it stops in whichever valley it starts above. Turn up the temperature: the ball jitters, sometimes hops the pass, and as you cool it, it settles. Or drop many balls at random and keep the lowest.
- **Guess:** On `land`, drop a ball at a random spot of [−2, 2] × [−1, 1]. Pick the chance it ends in the lower (left) valley: about 1/4, about 1/2, about 3/4. Run the Simulator for 1,000 drops, each rolling down −∇f (about 1/2, just over: the pass at x ≈ 0.06 sits just right of center, so the left valley drains about 2.06/4 ≈ 0.52 of the square).
- **Name it:** Descent finds a bottom, not the bottom. A pass between two valleys is a barrier. Restarting from many spots, or adding noise that lets the ball climb now and then, gives it a chance to find a lower valley. A random uphill hop of height Δ is kept with chance e^(−Δ/T), where T is the temperature; cooling slowly settles into the deepest valley (simulated annealing).
- **Work it:** f = x⁴ − 2s²x² + my², s ∈ {1, 2}, m ∈ 1..3; start (x₀, y₀), x₀ ∈ −3..3, y₀ ∈ −2..2; temperature T ∈ {s⁴/2, s⁴, 2s⁴} or, for s = 2, also T = 4. Chance to 3 decimal places. Index < 3: s = 1. Example: s = 1, m = 1, start (2, 1), T = 1.
  1. **Flat spots on the x-axis:** x-values 0 and ±s; type s (example: 1).
  2. **Height at the bottoms (±s, 0):** −s⁴ (example: −1).
  3. **Height of the pass (0, 0) above a bottom:** s⁴ (example: 1).
  4. **Where descent from (x₀, y₀) stops:** tap left bottom, right bottom, the pass (x₀ > 0: right; x₀ < 0: left; x₀ = 0: the pass; example: right).
  5. **Chance a hop over the pass is kept:** e^(−s⁴/T) (example: 0.368).
  - Slips: barrier typed as s² (s = 2 gives 4): "The bottoms are at height s⁴ − 2s⁴ = −s⁴, so the pass is s⁴ above them: 16." Chance as e^(+Δ/T) (2.718): "A chance can't be more than 1. Uphill hops get rarer as they get bigger: e^(−Δ/T)." Chose a bottom for x₀ = 0: "On the line x = 0 the gradient has no sideways part, so descent slides straight to the pass and stops there. Any tiny nudge sends it off."
- **Oracle:** `[s, -s^4, s^4, sign(x0), round(exp(-s^4/T), 3)]`
- **Use it:** **The valley finder** (the build) is complete. On `land` it runs 20 restarts plus a slow cool, finds the lowest point at about (−1.03, 0) with height about −0.254, confirms it as a pit with the Hessian test (b2-mv-13), reports how many restarts agreed, honors any fence (b2-mv-16) and fills the lake that would form there (b2-mv-08). Saves `lowest` to the Notebook. Try it on your own `land`.
- **Deeper:** Stochastic gradient descent uses a noisy gradient from a random batch; its noise has variance about 1/(batch size) and acts like a temperature (b2-pr-01, b2-ai-14). In the limit, noisy descent is Langevin dynamics, whose long-run spread of positions is the Boltzmann distribution ∝ e^(−f/T) (de for the stochastic equation, in for its entropy). In high dimensions most flat spots are passes, not false bottoms, and noise helps escape them. Finding the global lowest point of a general landscape is NP-hard (b2-cs-12), which is why guarantees come from convexity or from structure.
