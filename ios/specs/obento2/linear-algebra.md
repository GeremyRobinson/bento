# Bento² · Linear algebra (code `la`, 20 lessons)

**What it is:** the math of arrows and grids of numbers. It is how a computer moves, stretches and squeezes pictures, 3D worlds and data, and it is the base of all AI.

Role: spine, track 1. Needs: 12th grade (vectors from `g12-vecmag` and `g12-dot`, systems from `g8-system` and `g9-elim`). The plain path is college level (a first linear algebra course). The Deeper layers reach upper-undergraduate and early graduate ideas: Steinitz exchange, the Leibniz determinant, LU and QR, the four fundamental subspaces, Jordan form, Perron–Frobenius, Courant–Fischer, Eckart–Young–Mirsky, the pseudoinverse and random matrix noise floors.

## The build: an image compressor

**Compress a picture with a few numbers.** The learner loads a photo, splits it into layers with the singular value decomposition (SVD), keeps the top *k* layers with a slider, and sees the file size and the picture quality trade off. Built in the ★ Image compressor; saved to the Notebook as the track's build.

What each unit adds:

| Unit | Lessons | What it adds to the build |
|---|---|---|
| 1 · Arrows | 01 to 04 | A picture is numbers. The learner makes an 8×8 grayscale grid `img`, treats each row as a vector, measures how alike two rows are, and counts how many rows are truly different (dimension). |
| 2 · Matrices as moves | 05 to 08 | The picture is a matrix. Lesson 06 builds the first **layer**: a column times a row (an outer product), saved as `layer1`. |
| 3 · Solving and fitting | 09 to 11 | Rank: how many layers rebuild the picture exactly. Least squares: "best approximation" measured by squared error, the same error the compressor reports. |
| 4 · Eigen | 12 to 15 | Change of basis (pixel pairs to average and difference). Eigenvectors of a symmetric matrix are perpendicular main directions, which is where the layers come from. |
| 5 · SVD and the build | 16 to 20 | Orthonormal layers, the SVD itself, energy kept and error dropped, the PCA view, and storage cost k(m + n + 1). Together these make the compressor. |

## Units

1. **Arrows:** b2-la-01 to b2-la-04
2. **Matrices as moves:** b2-la-05 to b2-la-08
3. **Solving and fitting:** b2-la-09 to b2-la-11
4. **Eigen:** b2-la-12 to b2-la-15
5. **SVD and the build:** b2-la-16 to b2-la-20

## Small projects

| After | Project | What the learner makes and keeps | Shelf |
|---|---|---|---|
| b2-la-04 | **Your own grid** | Pick two basis arrows. The plane redraws in your grid; place three target points and write each one in your coordinates. | `basis` |
| b2-la-08 | **Filter and undo** | Chain a rotation, a shear and a scale into one filter for an 8×8 sprite. Read how much it changes area, then build the matrix that undoes it. | `M`, `Minv` |
| b2-la-11 | **Line through the noise** | Measure something real (phone battery against minutes, or plant height against days), type 4 to 8 points, and fit the least-squares line. | `fit` |
| b2-la-14 | **Long-run forecaster** | A two-station bike share (or two-state weather). Set the move chances and see where things settle, as a number and as dots flowing. | `steady` |
| b2-la-18 | **Plaid from layers** | Build a 6×6 plaid picture from two or three column-times-row layers, then check its rank and its storage cost. | `plaid` |
| b2-la-20 | **The build: image compressor** | Your own photo, compressed to a target size, with the k you chose and the energy you kept. | `k`, `sigma` |

## New for Development

Toolbox tools to build (names from `bento2/research/toolbox.md`, track 1):
- **★ Transformation playground.** Drag the two column arrows of a 2×2 matrix; the grid, a picture and the unit square bend with them. Needs: signed area readout (square shades a second color when orientation flips); "A then B" compose mode with an order swap; an Undo button that applies A⁻¹ and grays out at det 0; a unit-circle-to-ellipse mode that draws the ellipse axes and the input arrows that map to them (used in 15 and 17).
- **Vector board.** Tip-to-tail sums with scale sliders; span shading (point, line or plane); a shadow (projection) mode with the drop line; a skewed coordinate grid drawn from any chosen basis; a Gram–Schmidt step button (remove the shadow, then scale to length 1).
- **Matrix pad (shared) with row-reduction playback.** Step through row operations one at a time, with the multiplier named on each step, pivots highlighted, exact fractions, and a rank and nullity readout.
- **3D space.** A 3×3 matrix acting on a cube, with a volume readout; a three-plane viewer for 3×3 systems; an "image collapse" view (space to plane to line) with the null space line lit.
- **Eigen finder.** A test arrow on the unit circle and its image; a glow when they line up; the ratio shown as λ. Extra modes: "most stretched" marker for singular values (17), and an iterate mode that leaves a trail of A x, A² x, A³ x (14).
- **Image compressor (the build).** Photo or pixel-grid loader; k slider; picture, error picture and a strip of individual layers; a σ plot on a log scale with the cut line; a storage bar k(m + n + 1) against m n; energy kept as a percent; per-channel mode for color.

New pictures, mapped to toolbox homes:
- **Pixel grid editor** (inside Image compressor): an 8×8 grid of brightness 0 to 9 that becomes the shelf matrix `img`. Used from lesson 01 on.
- **Residual squares** (Grapher 2D plus the Data table from track `pr`): each point's miss drawn as a square; total area readout (11).
- **Two-state flow** (shares the Simulator from `pr`): two stations with arrows labeled by chances and dots moving step by step, beside the eigenvector reading (14).
- **Data cloud with a turning line** (Data table from `pr` plus Vector board): shadows of each point on the line, with the spread of the shadows as a bar (19).
- **Pair view** (inside Image compressor): pixel pairs turned into average and difference, with the difference image shown nearly blank (12).

Rules for every generator in this track:
- **Signed and unit coefficients.** Any generated coefficient that can be 0, ±1 or negative is rendered through the `count()` and sign helpers, so the screen shows "u", "−v" or "2u − 3v", never "1u", "−1·(…)" or a plus sign followed by a minus sign. This covers la-01 and la-02 (a u + b v), la-04 (w = a u + b v), la-10 (c₃ = p c₁ + q c₂) and la-12 (the entries of D).
- **Decimal answers** accept ±1 in the last stated place unless a lesson says otherwise (la-14, la-17, la-18, la-20), the same rule as track `pr`.

Cross-track links: `pr` (11, 14, 15, 19), `mv` (07, 15), `de` (05, 14), `ai` (03, 11, 18, 19, 20), `qu` (01, 13, 15, 16, 17), `re` (12), `cs` (06, 08, 09), `in` (19, 20).

Shelf names this track creates: `img`, `basis`, `shear`, `layer1`, `M`, `Minv`, `fit`, `lam`, `steady`, `sigmaM`, `plaid`, `k`, `sigma`.

---

## Unit 1 · Arrows

### b2-la-01 · Arrows you can add and stretch
- **You can:** combine arrows by scaling and adding them, and read a picture as a list of numbers.
- **Needs:** g12-vecmag.
- **Tool:** Vector board; Matrix pad.
- **Play:** Two arrows u and v sit on the plane with sliders a and b. Drag the arrows or the sliders and the arrow a u + b v redraws tip to tail, with its numbers beside it.
- **Guess:** With both sliders at 1 and the sum arrow hidden, place a point where you think u + v ends. The reveal slides v to the tip of u and draws the parallelogram.
- **Name it:** A vector is a list of numbers, drawn as an arrow. Scaling multiplies every entry; adding works entry by entry, which is the same as tip to tail.
  a·(u₁, u₂) + b·(v₁, v₂) = (a u₁ + b v₁, a u₂ + b v₂)
- **Work it:** u, v with integer entries in −5 to 5; a, b in −3 to 3, not 0. Early: entries 0 to 4, a and b in {1, 2}. From index 5, vectors have 3 entries. Example: u = (3, −1), v = (1, 2), a = 2, b = −1 gives (5, −4).
  1. **a u** two boxes: (6, −2).
  2. **b v** two boxes: (−1, −2).
  3. **a u + b v** two boxes: (5, −4).
  - Slips: mixed the entries (added u₁ + u₂) "Add first entry to first entry and second to second. The x part and the y part never mix." · a negative scale (−v typed as (−1, 2)) "A negative scale flips the whole arrow, so every entry changes sign." · scaled only the first entry "Scaling stretches the whole arrow: every entry gets multiplied."
- **Oracle:** `a*u + b*v` computed with a vector library (numpy arrays), not the entry formula.
- **Use it:** Open the Pixel grid editor and draw an 8×8 picture with brightness 0 to 9. Each row is a vector of 8 numbers. Make a new row that is the average of rows 3 and 4: ½(r₃ + r₄). Saves the picture as `img` (the build starts here).
- **Deeper:** The vector space rules (eight axioms) and why they let "vector" mean much more than an arrow: polynomials, functions and whole pictures (a point in a 64-dimensional space) are vectors too. Vectors with complex entries, which quantum states are (links `qu`).

### b2-la-02 · Span: everywhere two arrows can reach
- **You can:** find the mix of two arrows that reaches a target, and tell when two arrows only reach a line.
- **Needs:** b2-la-01, g9-elim.
- **Tool:** Vector board.
- **Play:** All mixes a u + b v shade the plane. Drag v toward u's line and the shading collapses to a single line when they line up.
- **Guess:** A target w appears. Type your guess for a and b. The reveal redraws the plane as a skewed grid made of u and v steps, and w's grid position gives the true a and b.
- **Name it:** The span is every arrow you can make from a u + b v. Two arrows that don't line up span the whole plane. Reaching w means solving two equations at once.
  a u + b v = w, and when u₁v₂ − u₂v₁ ≠ 0: a = (w₁v₂ − w₂v₁) / (u₁v₂ − u₂v₁), b = (u₁w₂ − u₂w₁) / (u₁v₂ − u₂v₁)
- **Work it:** Pick integers a, b in −4 to 4 and u, v with entries in −4 to 4 and u₁v₂ − u₂v₁ ≠ 0; set w = a u + b v so a and b come out whole. Early: u₁v₂ − u₂v₁ = ±1, entries 0 to 3, a and b in 1 to 3. Example: u = (2, 1), v = (1, 1), w = (5, 3): a = 2, b = 1.
  1. **The two equations** tap the right system: 2a + b = 5 and a + b = 3.
  2. **a** 2.
  3. **b** 1.
  - Slips: used one equation only (a = w₁/u₁ = 5/2) "Both arrows move you sideways, so the first equation has a and b in it. Solve the two together." · swapped a and b "a counts copies of u and b counts copies of v. Check: 2·(2, 1) + (1, 1) = (5, 3)." · sign slip in elimination "Subtract the whole equation, right side too."
- **Oracle:** Cramer's rule above, compared with the generator's a, b.
- **Use it:** Two pattern rows of 4 pixels: stripes p = (1, 0, 1, 0) and ramp q = (0, 1, 2, 3). A row of your picture is r = (2, 1, 4, 3). Find the mix (a = 2, b = 1): two numbers rebuild four. That is the whole idea of the build, in one row.
- **Deeper:** A span is a subspace (closed under adding and scaling). Spans in n dimensions; lines and planes that miss the origin are affine, not subspaces. The determinant formula here is a preview of b2-la-07.

### b2-la-03 · Dot product, angle and shadow
- **You can:** measure how alike two arrows are and drop one arrow's shadow onto another.
- **Needs:** b2-la-01, g12-dot.
- **Tool:** Vector board (shadow mode).
- **Play:** Drag w around while u stays fixed. Its shadow on u's line moves with it, and the dot product and the angle update. At 90° the shadow shrinks to the origin and the dot product reads 0.
- **Guess:** Place a point on u's line where you think w's shadow lands. The reveal drops the perpendicular from w's tip.
- **Name it:** The dot product multiplies matching entries and adds. It is positive when arrows point roughly the same way, zero when they are perpendicular. The shadow of w on u is a multiple of u.
  u·w = u₁w₁ + u₂w₂ = |u||w| cos θ, shadow = (u·w / u·u) u
- **Work it:** u entries in −4 to 4 (not both 0), w entries in −6 to 6 (not both 0). Early: choose w so u·w / u·u is a whole number. Example: u = (2, 1), w = (3, 4).
  1. **u·w** 10.
  2. **u·u** 5.
  3. **Multiplier** fraction: 2.
  4. **Shadow** two fractions: (4, 2).
  5. **Angle** tap acute, right or obtuse: acute (u·w > 0).
  - Slips: divided by |u| instead of u·u (typed 10/√5) "That is the shadow's length. The multiplier for u needs u·u, because u itself already has length." · swapped roles (shadow of u on w) "The shadow lands on u's line, so divide by u·u, not w·w." · obtuse when the dot is positive "A positive dot product means less than 90°."
- **Oracle:** the typed shadow s must be a multiple of u with `dot(w - s, u) == 0` (exact fractions); angle from the sign of `dot(u, w)`.
- **Use it:** How alike are two rows of a picture? Rows r = (1, 2, 2, 0) and s = (2, 1, 2, 0) have r·s = 8 and lengths 3 and 3, so cos θ = 8/9. Rows that point the same way repeat each other, which is why pictures compress. The same "cosine similarity" measures how alike two words are inside an AI model (links b2-ai-10, word arrows).
- **Deeper:** Cauchy–Schwarz |u·w| ≤ |u||w|, proved by asking when |u − t w|² ≥ 0 can touch zero (a quadratic in t with discriminant ≤ 0). Inner products on functions, ∫ f g dx, make Fourier coefficients into shadows (links `de`, `qu`).

### b2-la-04 · Independence, basis and dimension
- **You can:** tell when arrows are independent and find the one that would make them dependent.
- **Needs:** b2-la-02.
- **Tool:** Vector board; 3D space.
- **Play:** Three arrows in 3D and the slanted box they make, with its volume. Drag the third arrow into the plane of the first two and the box flattens to volume 0.
- **Guess:** Pick one: do these three arrows fill space, or lie flat in one plane? The reveal turns the view edge-on to the plane of the first two.
- **Name it:** Arrows are independent when none of them is a mix of the others. A basis is an independent set that spans; every basis of a space has the same number of arrows, the dimension. In a basis, every arrow has exactly one set of coordinates.
  w depends on u and v when w = a u + b v for some a, b
- **Work it:** u, v in 3D with entries in −3 to 3 whose first two entries make a 2×2 with u₁v₂ − u₂v₁ = ±1; a, b in −3 to 3, not both 0; w₁ = a u₁ + b v₁ and w₂ = a u₂ + b v₂. w is shown in full and the problem asks "dependent or independent?". In about half the problems w₃ = a u₃ + b v₃ (w lies in the plane); in the rest w₃ = a u₃ + b v₃ + e with e in {±1, ±2, ±3} (w points off the plane). Example: u = (1, 0, 2), v = (0, 1, 1), w = (2, 3, 7).
  1. **a** from the first two entries: 2.
  2. **b** 3.
  3. **c, the third entry w would need to lie in the plane** 2·2 + 3·1 = 7.
  4. **Then the three arrows are** tap dependent or independent: dependent (w₃ = 7 = c).
  - Off-plane example: same u and v, w = (2, 3, 5). Steps 1 to 3 give 2, 3 and 7, but w₃ = 5, so the arrows are independent.
  - Slips: c from the first arrow only (typed 4) "w has to be a mix of both arrows, so the third entry is a u₃ + b v₃." · picked "independent" when w₃ = c "w = 2u + 3v, so it adds nothing new: the three are dependent." · picked "dependent" when w₃ ≠ c "A mix of u and v would need third entry ${c}, but w has ${w3}. w points out of the plane, so the three are independent."
- **Oracle:** `matrix_rank([u, v, w]) < 3` from a library for "dependent"; c checked as `a*u3 + b*v3` with the generator's a and b.
- **Use it:** A plaid picture of 8 rows, each row a mix of two pattern rows. Tap the rows that are new; the rest are mixes. Its rows have dimension 2: two rows of numbers plus two mixing numbers per row rebuild it. Then **Project: Your own grid** (saves `basis`).
- **Deeper:** The Steinitz exchange lemma, which proves every basis has the same size. Infinite-dimensional spaces (all polynomials), and why a basis of every function needs the axiom of choice.

## Unit 2 · Matrices as moves

### b2-la-05 · A matrix is a move of the plane
- **You can:** turn a picture move into a matrix, and move any point with it.
- **Needs:** b2-la-01.
- **Tool:** ★ Transformation playground.
- **Play:** Drag the two arrows that say where (1, 0) and (0, 1) land. The whole grid, a picture and the unit square bend with them. Grid lines stay straight and evenly spaced, and the origin stays put.
- **Guess:** The two column arrows are set. Place a point where you think (2, 1) lands. The reveal walks two steps along the first arrow and one step along the second.
- **Name it:** The columns of a matrix are where the two basic arrows land. Everything else follows, because every point is a mix of those two.
  A x = x₁·(first column) + x₂·(second column); [[a, b], [c, d]]·(x₁, x₂) = (a x₁ + b x₂, c x₁ + d x₂)
- **Work it:** A entries in −3 to 3, x entries in −3 to 3. Early: entries 0 to 2. From index 4, add a tap problem: pick the matrix for "rotate 90° counterclockwise", "reflect across the x-axis", "stretch x by k" or "shear right by k". Example: A = [[2, −1], [1, 1]], x = (2, 1).
  1. **x₁ × first column** (4, 2).
  2. **x₂ × second column** (−1, 1).
  3. **A x** (3, 3).
  - Slips: read rows as columns (typed (5, −1)) "The first column, (2, 1), is where (1, 0) lands. Reading rows instead multiplies by the flipped matrix." · rotation picked [[0, 1], [−1, 0]] "That turns clockwise. Counterclockwise sends (1, 0) to (0, 1), so the first column is (0, 1)."
- **Oracle:** `matmul(A, x)` from a matrix library.
- **Use it:** Italicize a letter: shear with [[1, 1/4], [0, 1]]. The top of a 4-unit-tall letter at (0, 4) moves to (1, 4). Saves the shear as `shear`.
- **Deeper:** Linearity, T(a u + b v) = a T(u) + b T(v), and why it forces a matrix. Linear maps that aren't arrows: the derivative acting on polynomials of degree at most 2 is a 3×3 matrix (links `de`).

### b2-la-06 · Doing two moves: matrix multiplication
- **You can:** combine two moves into one matrix, and build a picture layer from a column and a row.
- **Needs:** b2-la-05.
- **Tool:** ★ Transformation playground (compose mode); Matrix pad.
- **Play:** Set move A and move B. The playground runs A, then B, on the picture. Flip the order switch and run again.
- **Guess:** Pick one: does "turn, then shear" leave the picture the same as "shear, then turn"? The reveal plays both side by side.
- **Name it:** Doing A first and then B is the single matrix BA: the one done first sits on the right. Each entry is a row of B dotted with a column of A. Order usually matters. A column times a row also makes a matrix: a layer.
  (BA)ᵢⱼ = (row i of B)·(column j of A); u vᵀ has entries uᵢ vⱼ
- **Work it:** A, B with entries in −3 to 3. Early: entries 0 to 2. Example: A = [[1, 2], [0, 1]] (shear), B = [[0, −1], [1, 0]] (turn).
  1. **First column of BA** B·(1, 0) = (0, 1).
  2. **Second column of BA** B·(2, 1) = (−1, 2).
  3. **Is AB the same?** tap: no (AB = [[2, −1], [1, 0]]).
  - Slips: multiplied entry by entry "A product isn't entry by entry. Each entry is a whole row times a whole column." · computed AB "A happens first, so it goes on the right: BA." · row times row "Use a row of B with a column of A."
- **Oracle:** `matmul(B, A)`.
- **Use it:** Your first layer: column u = (1, 2, 3) times row vᵀ = (2, 0, 1) gives the 3×3 picture [[2, 0, 1], [4, 0, 2], [6, 0, 3]]. It costs 6 numbers instead of 9. Saves `layer1` (the build's basic piece).
- **Deeper:** Why multiplication is associative (it is composing functions). The cost: n³ multiplications the plain way, and Strassen's trick that beats it, about n^2.81 (links b2-cs-09). Block matrices.

### b2-la-07 · The determinant: how much area changes
- **You can:** find how much a move scales area, and tell when it mirrors or squashes the plane.
- **Needs:** b2-la-05.
- **Tool:** ★ Transformation playground; 3D space (from index 4).
- **Play:** The unit square becomes a parallelogram, and its area shows. Drag one arrow across the other: the area passes through 0 and comes back negative, and the picture is now mirrored.
- **Guess:** Drag a slider to your guess for the parallelogram's area. The reveal tiles the parallelogram with unit squares.
- **Name it:** The determinant is the area scale of the move, with a sign. Negative means the picture is mirrored. Zero means the plane is squashed onto a line or a point. Scales multiply: det(BA) = det B · det A.
  det [[a, b], [c, d]] = a d − b c; area of the image = |det| × area
- **Work it:** A entries in −5 to 5; a shape of area S in 1 to 6. Early: entries 0 to 4, no negatives. From index 4, a 3×3 with entries in −2 to 2 by expanding along the first row (volume of the cube's image). Example: A = [[3, 1], [2, 4]], S = 3.
  1. **a d** 12.
  2. **b c** 2.
  3. **det** 10.
  4. **Area of the image** 30.
  5. **Mirrored, not mirrored or squashed flat?** tap: not mirrored.
  - 3×3 example: [[1, 2, 0], [0, 1, 3], [2, 0, 1]] has det (1 − 0) − 2·(0 − 6) = 13.
  - Slips: a d + b c "It is a d minus b c." · a c − b d "Multiply down the diagonals: a with d, b with c." · negative area "Area can't be negative. Use |det|; the sign only says the picture flipped." · picked "mirrored" or "not mirrored" at det 0 "det is 0, so the plane is squashed onto a line or a point: squashed flat." · 3×3 signs "Expansion signs go +, −, + along the first row."
- **Oracle:** `det(A)` from a library, cross-checked by the shoelace area of the image of the unit square (3×3: library `det`).
- **Use it:** Your `shear` from lesson 05 has det 1: the italic letter uses exactly as much ink. A scale [[2, 0], [0, 3/2]] on a 64-pixel sprite gives 192 pixels of area.
- **Deeper:** The determinant as the only function of the columns that is linear in each column, flips sign when two swap, and gives 1 for the identity. The Leibniz formula as a sum over permutations. The Jacobian determinant, which scales area in changes of variables (links b2-mv-08).

### b2-la-08 · Undo a move: the inverse
- **You can:** undo a move with its inverse matrix and use it to solve a system.
- **Needs:** b2-la-06, b2-la-07.
- **Tool:** ★ Transformation playground (Undo); Matrix pad.
- **Play:** Apply A to a picture, then press Undo to apply A⁻¹. Drag the arrows toward a line: the inverse's entries grow, and at det 0 Undo goes gray.
- **Guess:** Pick one: as det gets close to 0, do the inverse's entries get bigger, get smaller, or stay about the same? The reveal plots the largest entry of A⁻¹ against det.
- **Name it:** The inverse undoes the move: A⁻¹A = I. It exists exactly when det ≠ 0, because a squashed picture can't be unsquashed. Then A x = b has exactly one answer.
  [[a, b], [c, d]]⁻¹ = (1 / (a d − b c))·[[d, −b], [−c, a]]; x = A⁻¹ b
- **Work it:** A entries in −5 to 5 with det in {±1, ±2, ±3, ±4}; x₀ entries in −4 to 4; b = A x₀. Early: det = 1. Example: A = [[2, 1], [5, 3]], b = (4, 11).
  1. **det** 1.
  2. **Swap and negate** four boxes: [[3, −1], [−5, 2]].
  3. **A⁻¹** four fractions: [[3, −1], [−5, 2]].
  4. **x = A⁻¹ b** (1, 2).
  - Slips: forgot to divide by det "Every entry gets divided by the determinant. Check: A times your answer should be I." · negated the diagonal instead of the corners "Swap a and d; negate b and c." · didn't swap "a and d trade places."
- **Oracle:** `x0` from the generator; inverse entries as exact fractions.
- **Use it:** **Project: Filter and undo.** Chain a turn, a shear and a scale into one filter `M` for an 8×8 sprite, read its det, and build `Minv` that brings the sprite back.
- **Deeper:** Inverting by row reduction on [A | I]. The condition number, and why nearly-flat matrices lose digits in a computer (links `cs`). The Neumann series (I − A)⁻¹ = I + A + A² + … when A is small.

## Unit 3 · Solving and fitting

### b2-la-09 · Row reduction
- **You can:** solve three equations in three unknowns by row reduction.
- **Needs:** b2-la-08, g9-elim.
- **Tool:** Matrix pad (row-reduction playback); 3D space (three planes).
- **Play:** Three planes in 3D, one per equation. Step through the row operations: the planes change, but the point where all three meet never moves.
- **Guess:** Pick one: do these three planes meet in one point, along a line, or not at all? The Guess draws its own planes: about a third each meet in one point, share a line (a singular, consistent system) or have no common point (a singular, inconsistent system). The reveal turns the view until the meeting is plain.
- **Name it:** Swapping rows, scaling a row, and adding a multiple of one row to another never change the solutions. Clear out below each pivot, then solve from the bottom up. One pivot per unknown means exactly one solution.
  new row = row − (multiplier) × pivot row, multiplier = entry ÷ pivot
- **Work it:** Generate A = L U with L lower triangular (1s on the diagonal, entries below in −2 to 2) and U upper triangular (pivots in {±1, ±2, ±3}, entries above in −3 to 3); x₀ entries in −4 to 4; b = A x₀, so every multiplier is whole and so is the answer (the last division is by a pivot, and b = A x₀ makes it exact). Work it always has one solution; the line and no-solution cases live in the Guess. Early: 2×2. Example: x + y + z = 6, 2x + 3y + z = 11, x + 2y + 3z = 14.
  1. **Multiplier for row 2** 2 (gives y − z = −1).
  2. **Multiplier for row 3** 1 (gives y + 2z = 8).
  3. **Next multiplier** 1 (gives 3z = 9).
  4. **z** 3.
  5. **y** 2.
  6. **x** 1.
  - Slips: changed only the left side "Do the same to the number on the right of the equals sign." · added instead of subtracted "Subtract the multiple, so the entry below the pivot becomes 0." · back-substituted top down "Start at the bottom row: it has only one unknown left."
- **Oracle:** `x0` from the generator.
- **Use it:** A recipe from three foods to hit exact calories, protein and fiber targets: one system, one answer.
- **Deeper:** The multipliers you used are exactly the entries of L, so row reduction is A = L U. Partial pivoting for accuracy, and the cost, about (2/3)n³ steps (links `cs`).

### b2-la-10 · Rank, column space and null space
- **You can:** find a matrix's rank and the arrows it sends to zero.
- **Needs:** b2-la-04, b2-la-09.
- **Tool:** 3D space (image collapse); Matrix pad.
- **Play:** A 3×3 matrix acts on all of space. Drag its third column into the plane of the other two: the image flattens from space to a plane, and a whole line of arrows lights up because they now land on 0.
- **Guess:** Pick one: what shape is the image of all of space here: a point, a line, a plane or all of space? The reveal flattens the cube.
- **Name it:** The rank is the number of pivots: the dimension of everything the matrix can reach (its column space). The null space is every x with A x = 0. Together they account for every column.
  rank + nullity = number of columns
- **Work it:** Build A from chosen columns with entries in −3 to 3; p, q, r, s, t are whole numbers in −3 to 3. Each case has its own steps.
  - **Rank 2, 3×3** (every early problem, and most later ones): c₁, c₂ independent, c₃ = p c₁ + q c₂ with p, q not both 0. Example: c₁ = (1, 0, 2), c₂ = (0, 1, 1), c₃ = 2c₁ + 3c₂ = (2, 3, 7).
    1. **Rank** (count pivots after reducing) 2.
    2. **Nullity** 1.
    3. **Null arrow with third entry 1** (−2, −3, 1).
  - **Rank 3, 3×3** (from index 3): c₁, c₂, c₃ independent.
    1. **Rank** 3.
    2. **Nullity** 0.
    3. **Null arrows** tap: only the zero arrow.
  - **Rank 1, 3×3** (from index 3): c₁ ≠ 0, c₂ = p c₁, c₃ = q c₁. Example: c₁ = (1, 2, −1), c₂ = 2c₁, c₃ = −c₁.
    1. **Rank** 1.
    2. **Nullity** 2.
    3. **Null arrow as (?, 1, 0)** −2, so (−2, 1, 0).
    4. **Null arrow as (?, 0, 1)** 1, so (1, 0, 1).
  - **3×4** (from index 4): c₁, c₂ independent; for rank 2, c₃ = p c₁ + q c₂ and c₄ = r c₁ + s c₂; for rank 3, c₃ independent and c₄ = r c₁ + s c₂ + t c₃. Example: c₁ = (1, 0, 2), c₂ = (0, 1, 1), c₃ = (2, 3, 7), c₄ = c₁ − c₂ = (1, −1, 1).
    1. **Rank** 2.
    2. **Nullity = 4 − rank** 2.
    3. **Null arrow with last entry 1** (any other free entry 0): (−1, 1, 0, 1).
  - Slips: counted nonzero rows before reducing "Reduce first. A row can turn into all zeros." · rank + nullity = rows "It is the number of columns: each column is an unknown." · null arrow sign "Check: A times your arrow should be 0. Here 2·(−2) − 3 + 7 = 0."
- **Oracle:** `matrix_rank(A)` from a library against the generator's case; check A·(each typed null arrow) = 0 exactly.
- **Use it:** Balance CH₄ + O₂ → CO₂ + H₂O: count carbon, hydrogen and oxygen in each molecule, with the products' columns entered as negatives (moved to the left side). The atom counts make a 3×4 matrix of rank 3, and its null arrow, scaled to whole numbers, is (1, 2, 1, 2): the balanced equation. For the build: the rank of `img` is how many layers rebuild your picture exactly.
- **Deeper:** The four fundamental subspaces: the row space is perpendicular to the null space, and row rank equals column rank. The Fredholm alternative. Quotient spaces.

### b2-la-11 · Least squares: the best wrong answer
- **You can:** fit the best line to data that no line fits exactly.
- **Needs:** b2-la-03, b2-la-10, st-lsrl.
- **Tool:** Grapher 2D with the Data table from `pr` (residual squares); Vector board (shadow mode, 3D).
- **Play:** Drag the data points and a line. Each point's miss shows as a square; the total area is the error. A 3D view shows the same thing as the data arrow b and its shadow on the plane the matrix can reach.
- **Guess:** Drag the line to your best fit. The reveal draws the least-squares line and both total square areas.
- **Name it:** When A x = b has no answer, take the x that gets A x as close to b as possible. The leftover miss b − A x̂ is perpendicular to every column of A, which gives the normal equations.
  Aᵀ A x̂ = Aᵀ b; for y = m x + c: [[Σx², Σx], [Σx, n]]·(m, c) = (Σxy, Σy)
- **Work it:** Answers as exact fractions from the first problem on. Early (index < 3): x = (−1, 0, 1), y entries in −4 to 8, so m = (y₃ − y₁)/2 and c = mean of y. Later: x = (0, 1, 2, 3), y entries in 0 to 9. Example: x = (−1, 0, 1), y = (1, 2, 6).
  1. **Aᵀ A** four boxes: [[2, 0], [0, 3]].
  2. **Aᵀ b** (5, 9).
  3. **m** 5/2.
  4. **c** 3.
  - Later example: x = (0, 1, 2, 3), y = (1, 3, 2, 5): 14m + 6c = 22 and 6m + 4c = 11, so m = 11/10 and c = 11/10.
  - Slips: line through two points "Two points ignore the rest. Least squares uses every point." · Σx in place of Σx² "The top left of Aᵀ A is the sum of the squares of x." · swapped m and c "The first unknown pairs with Σx², so it is the slope."
- **Oracle:** slope = Sxy/Sxx from the centered data, c = ȳ − m x̄ (exact fractions), with no normal equations.
- **Use it:** **Project: Line through the noise.** Measure something, type it in, fit it, and save `fit`. The same squared error is what the build reports as picture quality, and what a learning machine shrinks (links b2-ai-01, line fitter).
- **Deeper:** The projection matrix P = A(AᵀA)⁻¹Aᵀ with P² = P. QR for a stabler solve. The pseudoinverse A⁺ (it comes back in b2-la-17). Ridge regression (AᵀA + λI), and the Gauss–Markov theorem (links `pr`, `ai`).

## Unit 4 · Eigen

### b2-la-12 · Change of basis
- **You can:** rewrite a point and a move in a new set of coordinates.
- **Needs:** b2-la-04, b2-la-08.
- **Tool:** Vector board (skewed grid); ★ Transformation playground.
- **Play:** Two grids overlay: the usual one and one built from your `basis`. Drag a point and read both sets of coordinates. Pick a move: in one special basis it becomes a pure stretch along each grid line.
- **Guess:** Type your guess for the point's coordinates in the new grid. The reveal counts steps along the new grid lines.
- **Name it:** Put the new basis arrows in the columns of P. Then P turns new coordinates into usual ones, and P⁻¹ goes back. The same move, seen in the new coordinates, is P⁻¹ A P.
  x = P c, c = P⁻¹ x; the move in new coordinates is P⁻¹ A P
- **Work it:** P with entries in −3 to 3 and det ±1; c₀ entries in −4 to 4; x = P c₀. Then a move A = P D P⁻¹ with D diagonal, two different entries in −3 to 4 (equal entries make A = λI, which has no special basis). Early: P = [[1, 1], [0, 1]] or [[1, 0], [1, 1]]. Example: P = [[1, 1], [1, 2]], x = (3, 5), A = [[7, −4], [8, −5]].
  1. **P⁻¹** [[2, −1], [−1, 1]].
  2. **c = P⁻¹ x** (1, 2).
  3. **A times the first basis arrow** (3, 3) = 3·(1, 1).
  4. **A times the second** (−1, −2), which is −(1, 2).
  5. **The move in the new basis** [[3, 0], [0, −1]].
  - Slips: used P x "P takes new coordinates to old ones. To go from old to new, use P⁻¹." · read 3 as the vector (3, 3) "In the new basis that arrow is simply 3 times the first basis arrow: entry 3."
- **Oracle:** `inverse(P) * x`; `inverse(P) * A * P`.
- **Use it:** Pixel pairs: turn each pair (a, b) into (average, difference) = ((a + b)/2, (a − b)/2). The pair (9, 7) from your `img` becomes (8, 1): in this basis most differences are tiny, so they cost almost nothing to store. Open the Pair view to see the difference image go nearly blank.
- **Deeper:** What doesn't change under a change of basis: trace, determinant and eigenvalues. Jordan form, the best a non-diagonal move can do. Dual bases, and why some quantities change one way and some the other (covariant and contravariant), which is how Lorentz moves are written (links `re`).

### b2-la-13 · Eigenvectors: arrows that only stretch
- **You can:** find the arrows a move only stretches, and by how much.
- **Needs:** b2-la-07, b2-la-12.
- **Tool:** Eigen finder; ★ Transformation playground.
- **Play:** Drag the test arrow around the circle. Its image is drawn in a second color; when the two line up the arrow glows, and the ratio of their lengths is the eigenvalue.
- **Guess:** Place the test arrow where you think it lines up with its image. The reveal sweeps the arrow all the way round and marks every match.
- **Name it:** An eigenvector stays on its own line; the move only stretches it, by the eigenvalue λ. They are the λ that make A − λI squash the plane.
  A v = λ v; det(A − λI) = λ² − (trace)λ + det = 0
- **Work it:** Generate A = P D P⁻¹ with P entries in −2 to 2, det P = ±1, and D = diag(λ₁, λ₂), distinct integers in −4 to 5; A has whole entries. The "?" boxes take fractions (P column (2, 1) gives 1/2). Early: A upper triangular, and the slip "read eigenvalues off the diagonal" is switched off there, because it is the right answer. Example: A = [[4, 1], [2, 3]].
  1. **trace** 7.
  2. **det** 10.
  3. **Eigenvalues** larger first: 5, 2.
  4. **Eigenvector for 5, as (1, ?)** 1.
  5. **Eigenvector for 2, as (1, ?)** −2. (When an eigenvector's first entry is 0, ask (?, 1) instead.)
  - Slips: + trace in the polynomial "It is λ² minus the trace times λ, plus det." · read eigenvalues off the diagonal "That only works for triangular matrices. Here the diagonal is 4 and 3, but the eigenvalues are 5 and 2." · solved A v = 0 instead of (A − λI) v = 0 "Find the arrow that A − λI sends to 0."
- **Oracle:** roots of λ² − tλ + d; check A v = λ v.
- **Use it:** For the filter [[3, 1], [0, 2]], find the two lines of the picture that only stretch: (1, 0) by 3 and (1, −1) by 2. Saves the pair of eigenvalues as `lam`.
- **Deeper:** A turn has no real eigenvectors; its eigenvalues are complex, a ± bi, a stretch by √(a² + b²) and a turn (links `qu`). Algebraic and geometric multiplicity, and the defective shear [[1, 1], [0, 1]]. Cayley–Hamilton (A satisfies its own polynomial). Gershgorin discs.

### b2-la-14 · Powers and the long run
- **You can:** predict where a repeated move ends up, including a chain of chances.
- **Needs:** b2-la-13.
- **Tool:** Eigen finder (iterate mode); Two-state flow (shares the Simulator with `pr`).
- **Play:** Apply A again and again to a point; a trail of A x, A² x, A³ x swings toward one line. Switch to two stations with chances on the arrows and watch the dots settle.
- **Guess:** Drag an arrow to show which way A⁵⁰ x points. The reveal runs 50 steps.
- **Name it:** In the eigenvector basis, a move is a pure stretch, so powers are easy: Aⁿ = P Dⁿ P⁻¹. The eigenvalue with the largest size wins in the long run. For a chain of chances (columns adding to 1), λ = 1 is always there, and its eigenvector is where things settle. Statistics books, and b2-pr-19, write the same chain transposed: rows add to 1 and π = πP.
  Aⁿ = P Dⁿ P⁻¹; for [[1 − p, q], [p, 1 − q]]: λ = 1 and λ = 1 − p − q, steady share of state 1 = q / (p + q)
- **Work it:** p (leave state 1) and q (leave state 2) in tenths from 0.1 to 0.9; N in {100, 500, 1000}, skipping the (p, q, N) choices where N q/(p + q) ends in exactly .5: (0.1, 0.7) and (0.7, 0.1) with N = 100 or 500, (0.3, 0.5) and (0.5, 0.3) with N = 100 or 500, and (0.7, 0.9) and (0.9, 0.7) with N = 1000. Early: p, q in {0.2, 0.4, 0.5}. Example: sunny to rainy p = 0.2, rainy to sunny q = 0.4.
  1. **Matrix** tap: [[0.8, 0.4], [0.2, 0.6]].
  2. **Second eigenvalue** decimal: 0.4.
  3. **Long-run share sunny** fraction: 2/3.
  4. **Sunny days out of N = 1000** nearest whole: 667.
  - Slips: p/(p + q) "The share of state 1 grows with q, the flow into it: q / (p + q)." · rows add to 1 "Each column is where one state goes, so the columns add to 1." · second eigenvalue p + q − 1 "It is 1 − p − q. Check: the two eigenvalues add to the trace, 1.4."
- **Oracle:** solve (A − I)x = 0 exactly with x₁ + x₂ = 1 (or power-iterate A 200 times); second eigenvalue from a library `eig(A)`.
- **Use it:** **Project: Long-run forecaster.** Two bike stations: A keeps 70% and sends 30% to B; B keeps 80% and sends 20% to A. In the long run 40% of bikes sit at A, so 200 of 500. Saves `steady` (links b2-pr-19, Markov chains).
- **Deeper:** Power iteration, which converges at the rate |λ₂/λ₁|. Perron–Frobenius, and PageRank as the steady state of the web. The matrix exponential e^(At) solves x′ = A x (links `de`). Fibonacci from [[1, 1], [1, 0]] and the golden ratio (1 + √5)/2.

### b2-la-15 · Symmetric matrices: perpendicular axes
- **You can:** find the perpendicular main axes of a symmetric matrix and tell a bowl from a saddle.
- **Needs:** b2-la-13.
- **Tool:** ★ Transformation playground (circle to ellipse); Grapher 3D.
- **Play:** A symmetric matrix turns the unit circle into an ellipse. Drag the off-diagonal entry: the ellipse turns, and its two axes always stay perpendicular. Beside it, the surface z = xᵀ A x is a bowl, a trough, a saddle or one of these upside down.
- **Guess:** Place the long axis of the ellipse before it is drawn. The reveal draws both axes.
- **Name it:** A symmetric matrix (A = Aᵀ) has real eigenvalues and perpendicular eigenvectors: a turn, a stretch along axes, and the turn back. The signs of the eigenvalues tell the shape of xᵀ A x.
  A = Q Λ Qᵀ; both λ > 0: bowl; both λ < 0: upside-down bowl; signs differ: saddle; one λ = 0 and the other λ > 0: trough; one λ = 0 and the other λ < 0: upside-down trough
- **Work it:** A = [[a, b], [b, d]] with (a − d, 2b) from {(0, 2), (0, 4), (3, 4), (6, 8), (8, 6), (5, 12)}, either sign, so (a − d)² + 4b² is a perfect square; a, d in −6 to 9. Early: a = d. Example: A = [[5, 2], [2, 2]].
  1. **Eigenvalues** larger first: 6, 1.
  2. **Eigenvector for 6, as (1, ?)** 1/2.
  3. **Eigenvector for 1, as (1, ?)** −2.
  4. **Their dot product** 0.
  5. **Shape** tap bowl, upside-down bowl, saddle, trough or upside-down trough: bowl.
  - Slips: eigenvalues from the diagonal "Off-diagonal entries move them: here 5 and 2 become 6 and 1." · bowl because every entry is positive "Entries don't decide it, eigenvalues do: [[1, 2], [2, 1]] has eigenvalue −1, so it's a saddle." · bowl when both λ < 0 "Both eigenvalues are negative, so every direction curves down: an upside-down bowl."
- **Oracle:** (t ± √(t² − 4d)) / 2; dot of the two eigenvectors is 0.
- **Use it:** Treat [[5, 2], [2, 2]] as the spread of a height and weight data cloud (a covariance matrix): its main axis points along (2, 1), slope 1/2, and it holds 6 of the 7 units of spread (links b2-pr-08). This is the move the build makes with pictures.
- **Deeper:** Proof by the Rayleigh quotient xᵀAx / xᵀx, whose largest value is λ₁. Courant–Fischer min-max. The second-derivative test is this lesson on the Hessian (links b2-mv-13). Hermitian matrices are the measurable quantities of quantum (links `qu`).

## Unit 5 · SVD and the build

### b2-la-16 · Orthonormal bases and Gram–Schmidt
- **You can:** turn any basis into one of perpendicular unit arrows, and spot a matrix that only turns.
- **Needs:** b2-la-03, b2-la-04, b2-la-08.
- **Tool:** Vector board (Gram–Schmidt step); 3D space.
- **Play:** Two slanted arrows. Press the step button: v loses its shadow on u and stands up perpendicular, then both shrink to length 1. The skewed grid becomes a square grid, just turned.
- **Guess:** Place a point where you think v ends after its shadow is removed. The reveal animates the subtraction.
- **Name it:** Orthonormal means perpendicular and length 1. A matrix Q with orthonormal columns keeps every length and angle, so it only turns or mirrors, and undoing it is just its transpose (flip it across its diagonal). Gram–Schmidt makes such a basis by removing shadows one at a time.
  v′ = v − (u·v / u·u) u; QᵀQ = I, so Q⁻¹ = Qᵀ
- **Work it:** u from {(3, 4), (1, 2, 2), (2, 3, 6), (1, 4, 8), (2, 6, 9)} (whole lengths 5, 3, 7, 9, 11) times ±1; v = k u + w with k in −3 to 3 and w a whole arrow perpendicular to u, w ≠ 0. Early: 2D only. Example: u = (1, 2, 2), v = (3, 0, 3).
  1. **u·v** 9.
  2. **u·u** 9.
  3. **Multiplier** 1.
  4. **v′** (2, −2, 1).
  5. **|u|** 3, so the first unit arrow is (1, 2, 2)/3.
  6. **Does Q keep lengths?** tap: yes.
  - Slips: typed the shadow, not what's left "v′ is v minus its shadow. Check: v′·u should be 0." · removed u's shadow on v "Remove the part of v along u, so divide by u·u." · scaled before subtracting "Subtract first, then scale to length 1."
- **Oracle:** `v - k*u` with `k = frac(dot(u,v), dot(u,u))`; check `dot(v', u) = 0`.
- **Use it:** A 3D game camera stores its turn as the matrix with columns (1, 2, 2)/3, (2, −2, 1)/3 and (2, 1, −2)/3. Check QᵀQ = I: it is a pure turn (det 1), no stretch. The build's layers use exactly such arrows.
- **Deeper:** QR factorization, A = QR. Modified Gram–Schmidt and Householder mirrors for accuracy. Gram–Schmidt on functions gives the Legendre polynomials. Unitary matrices, the complex version, are quantum gates (links `qu`).

### b2-la-17 · The SVD: turn, stretch, turn
- **You can:** split any matrix into a turn, a stretch and a turn, and find its singular values.
- **Needs:** b2-la-15, b2-la-16.
- **Tool:** ★ Transformation playground (circle to ellipse); Eigen finder (most-stretched marker).
- **Play:** Any matrix, symmetric or not, turns the unit circle into an ellipse, or into a flat segment when det is 0. Sweep the test arrow around the circle: the input arrows that become the longest and shortest axes are perpendicular, and so are the axes they land on.
- **Guess:** Drag on the circle to the input arrow you think gets stretched most. The reveal sweeps and marks the longest image.
- **Name it:** Every matrix is a turn (or mirror), then a stretch along the axes, then another turn (or mirror). The stretches are the singular values, never negative, largest first. They are the square roots of the eigenvalues of AᵀA.
  A = U Σ Vᵀ; σᵢ = √(eigenvalues of AᵀA); for a 2×2, σ₁σ₂ = |det A|
- **Work it:** A entries in −4 to 4, A ≠ 0, kept only when AᵀA has whole eigenvalues (its discriminant is a perfect square); σ to 2 decimal places, or exact when whole. Early: diagonal or symmetric A. Example: A = [[3, 0], [4, 5]].
  1. **AᵀA** four boxes: [[25, 20], [20, 25]].
  2. **Eigenvalues of AᵀA** larger first: 45, 5.
  3. **σ₁** 6.71.
  4. **σ₂** 2.24.
  5. **σ₁σ₂** whole: 15 (equals |det A| = 15).
  - Early example: A = [[2, 0], [0, −3]] has σ₁ = 3, σ₂ = 2.
  - Slips: eigenvalues of A (typed −3) "Singular values come from AᵀA and are never negative: here 3 and 2." · forgot the square root (typed 45) "45 is σ₁². Take the square root." · smaller first "σ₁ is the biggest stretch."
- **Oracle:** `sqrt(eig(transpose(A)*A))`, sorted down.
- **Use it:** A map projection stretches a tiny circle on the globe into an ellipse; σ₁/σ₂ says how badly it distorts shapes there. Saves the singular values of your filter `M` as `sigmaM`.
- **Deeper:** Proof from the spectral theorem on AᵀA. Full and thin SVD. The pseudoinverse A⁺ = V Σ⁺ Uᵀ solves least squares in one line (back to b2-la-11). σ₁ is the largest stretch, the operator norm. Polar decomposition. The Schmidt decomposition of a two-part quantum state is an SVD, and its count of nonzero σ's measures entanglement (links `qu`).

### b2-la-18 · Layers: a picture as a sum of simple pictures
- **You can:** say how much of a picture k layers keep, and how big the leftover error is.
- **Needs:** b2-la-06, b2-la-17.
- **Tool:** ★ Image compressor (layer strip); Matrix pad.
- **Play:** Your picture `img` rebuilt as layer 1, plus layer 2, plus layer 3, and so on. Each layer shows on its own as a faint plaid; the error picture beside it fades as k rises.
- **Guess:** With only the first layer, drag a slider to the percent of the picture's energy you think is kept. The reveal shows σ₁² over the total.
- **Name it:** The SVD writes a picture as a sum of layers, each a column times a row times its σ. Keeping the first k layers gives the best possible k-layer picture. Energy adds up as squares.
  A = σ₁u₁v₁ᵀ + σ₂u₂v₂ᵀ + …; energy kept = (σ₁² + … + σₖ²) / (σ₁² + σ₂² + …); error = √(sum of the dropped σ²)
- **Work it:** 3 to 5 singular values, whole numbers strictly falling in 1 to 12; k in 1 to 3; target in {80, 90, 95, 99} percent. Percents to 1 decimal place, error to 2. Early: 3 values. Example: σ = (6, 3, 2, 1), k = 1, target 90%.
  1. **Total energy** 50.
  2. **Kept with k = 1** 72.0%.
  3. **Error with k = 2** √5 = 2.24.
  4. **Smallest k for 90%** 2 (45 of 50).
  - Slips: used σ instead of σ² (typed 50.0%) "Energy adds as squares: 36 out of 50, not 6 out of 12." · error as the plain sum of dropped σ (typed 3) "The error is the square root of the dropped squares: √(4 + 1)." · counted from the smallest layer "Layers go biggest σ first; keep from the top."
- **Oracle:** build a matrix with these σ (random orthonormal U and V from a library QR) and sum the squared entries of the dropped layers (the Frobenius norm); compare with the typed energy and error.
- **Use it:** **Project: Plaid from layers.** Build a 6×6 plaid from two or three column-times-row layers, check its rank, and count storage: two layers cost 2·(6 + 6 + 1) = 26 numbers against 36. Saves `plaid`.
- **Deeper:** The Eckart–Young–Mirsky theorem (best rank-k approximation), with the largest-stretch error σₖ₊₁ and the total error √(σₖ₊₁² + …). Frobenius norm = √(trace AᵀA) = √(Σσ²). Randomized SVD for huge matrices. Low-rank updates (LoRA) are how large AI models are tuned cheaply (links `ai`).

### b2-la-19 · PCA: the main directions of data
- **You can:** find the direction a cloud of data spreads most, and how much of the spread it holds.
- **Needs:** b2-la-15, b2-la-18.
- **Tool:** Data cloud with a turning line (Data table from `pr` plus Vector board); Eigen finder.
- **Play:** A cloud of points, with a line through its center. Turn the line: each point drops a shadow onto it, and a bar shows how spread out the shadows are. One direction makes the bar longest.
- **Guess:** Turn the line to where you think the spread is biggest. The reveal sweeps the line all the way round and marks the best direction.
- **Name it:** Center the data, then put it in the rows of a matrix X. The top eigenvector of XᵀX is the direction of most spread: the first principal component. Its eigenvalue is the total squared spread along it (n times the variance there). These are the right singular vectors of X, with eigenvalue σ².
  center: subtract the mean; XᵀX = [[Σx², Σxy], [Σxy, Σy²]]; share on PC1 = λ₁ / (λ₁ + λ₂)
- **Work it:** Four points ±(a, b), ±(c, d) with a, b, c, d in −3 to 3, kept only when XᵀX has whole eigenvalues λ₁ > λ₂ (this rules out equal spread in every direction, such as ±(1, 0), ±(0, 1), and the all-zero cloud), then shifted by a center (c₁, c₂) with c₁, c₂ in 0 to 6. Early: center (0, 0). Share to 1 decimal place; slope as a fraction (or "up" when vertical). Example: points (7, 4), (3, 2), (6, 5), (4, 1).
  1. **Mean point** (5, 3).
  2. **XᵀX of the centered data** [[10, 8], [8, 10]].
  3. **Its eigenvalues** larger first: 18, 2.
  4. **Share on the first direction** 90.0%.
  5. **Slope of the first direction** 1.
  - Slips: didn't center "Subtract the mean point first. Otherwise the main direction just points at the cloud from the origin." · read spread off the diagonal (typed 10) "The diagonal is spread along x and y. Along the best line it is the larger eigenvalue, 18." · slope upside down "Slope is rise over run: second entry over first."
- **Oracle:** eigen of XᵀX of the centered points.
- **Use it:** Keep one number per point instead of two and still hold 90% of the spread. For a picture, PCA of its rows and the SVD of the picture, once centered, are the same thing, which is why the build works (links `pr`, `ai`).
- **Deeper:** PCA as the SVD of the centered X. Whitening. Kernel PCA for curved clouds. Random matrix theory: the Marchenko–Pastur law says which singular values are just noise, so you know where to cut (links `in`).

### b2-la-20 · The build: compress an image
- **You can:** compress a photo to a chosen size and say what it cost in quality.
- **Needs:** b2-la-18, b2-la-19.
- **Tool:** ★ Image compressor.
- **Play:** Load a photo (or your `img`). Drag k from 1 up to the smaller of the photo's width and height: the picture sharpens layer by layer, the size bar grows, and the σ plot shows where you cut.
- **Guess:** For a 100×100 photo at k = 10, drag the size bar to the fraction of the original you think it takes. The reveal fills in the true bar.
- **Name it:** Each layer stores a column of m numbers, a row of n numbers and its σ. k layers cost k(m + n + 1) numbers instead of m n. It only saves space while k is below m n / (m + n + 1).
  storage = k(m + n + 1); share = k(m + n + 1) / (m n); largest saving k = the whole part of (m n − 1) / (m + n + 1)
- **Work it:** m, n from {64, 100, 128, 200, 256, 512}; k from {1, 5, 10, 20, 50}; share as a percent to 1 decimal place. From index 3, add an energy step with a σ list as in b2-la-18. Early: m = n = 100. Example: m = n = 100, k = 10.
  1. **Numbers stored** 2010.
  2. **Original** 10000.
  3. **Share** 20.1%.
  4. **Largest k that still saves space** 49 (49·201 = 9849, but 50·201 = 10050).
  - Slips: k(m + n) (typed 2000) "Each layer also stores its σ: m + n + 1 numbers." · k·m·n "A layer is a column and a row, not a whole picture." · share flipped (typed 497.5%) "Divide what you store by the original."
- **Oracle:** `k*(m+n+1)` and `m*n`; the largest k by a brute-force loop over k = 1, 2, … while `k*(m+n+1) < m*n`.
- **Use it:** Compress your own photo to under 25% of its size, choose k by eye, and record the energy kept. For color, do it once per channel (three times the storage). Saves `k` and the finished compressor to the Notebook: the track's build.
- **Deeper:** Why real photos have fast-falling σ's while noise doesn't. SVD against JPEG: JPEG uses a fixed basis of cosines (shadows, from b2-la-03) on 8×8 blocks, and wavelets use averages and differences (b2-la-12), while SVD builds a basis for each picture and has to store it. Quantizing the stored numbers turns this into bits (links `in`). Low-rank layers inside neural networks (links `ai`).
