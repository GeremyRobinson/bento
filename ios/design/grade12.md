# 12th grade on paper: every lesson's design

Claude (12th grade lesson planner), 1 Nov 2026, in the language of `README.md` and the example of `grade5.md`. Planning
only: nothing here is built yet, and each lesson still goes to G as a preview before Swift (`LESSONS.md` §9).

**The course.** The web catalog calls 12th grade "Precalculus and calculus" (`web/src/curriculum/grades/index.ts`): 13
lessons in five units (Trigonometry, Limits, Derivatives, Integrals, Vectors and series). This plan covers what a US
12th grade Precalculus course teaches, with the start of calculus the web already teaches: Common Core's (+) standards
for a fourth-year course (as in Massachusetts' model Precalculus course), the topics most Precalculus courses add
(polar graphs, parametric paths, conic sections, Σ and sums that go on forever: Texas Precalculus P.2–P.5), and
limits, derivatives and integrals far enough to see what each one means.

**42 lessons in 11 chapters:** the 13 web lessons (`web/src/curriculum/lessons/grade12`, `specs/k12/grade12.md`), each
keeping its maths (generator, ranges, easy-first start, derived values, slips, check recipe, the spec's 13 Oct fixes)
and the beats of its animated picture, and 29 new ones (`g12-<short>`). Small gaps are folded into web lessons as an
extra problem type or step, marked *fold*. Three lessons go 3D, where the maths rises off the paper. The lines with
10th and 11th grade follow their plans (`grade10.md`, `grade11.md`, written alongside this one), which already teach
some of Precalculus's (+) standards.

**Review, 2 Nov 2026** (the grade 12 reviewer, checked against `grade11.md` as it now stands and Massachusetts' model
Precalculus list): `grade11.md` sends these Algebra 2 topics here (its coverage table and open question 1: radians, the
unit circle, the sine wave, sin² + cos² = 1, the geometric series sum, Pascal's triangle, and log rules), while the
first draft of this file assumed 11th grade kept them in lessons that don't exist (`g11-unitcircle`, `g11-wave`,
`g11-pythid`, `g11-geosum`, `g11-pascal`, `g11-loggraph`, `g11-avgrate`, `g11-shift`). Neither plan taught them. They
are added here under the ids `grade11.md` already names: The sine wave `g12-sinegraph`, sin² + cos² = 1 `g12-pythid`,
Geometric series `g12-geoseries`, Pascal's triangle `g12-binomial` (3D) and Log rules `g12-logrules` (Obento²'s
specs call three of them `pc-sinegraph`, `pc-logs` and, for polar points, `pc-polar`: those are `g12-sinegraph`,
`g12-logrules` and `g12-polar`). Every reference to the missing 11th grade lessons now points at the real one. Other
fixes are listed in the lessons they touch (pictures sized to the screen, a few web ports given hand moves, roots typed
as 10th grade types them).

## Coverage

| Standard | What it asks | Lesson(s) | |
|---|---|---|---|
| F-TF.1 | radians | Degrees to radians `g12-rad`; Radians to degrees `g12-deg` (the radian as arc in radii is 10th grade's `g10-arc`) | existing |
| F-TF.2 | the unit circle | Unit circle values `g12-unit`; The sine wave `g12-sinegraph` (the circle unrolled) | existing, new |
| F-TF.5, F-IF.7e | waves model things that repeat: middle, swing, period | `g12-sinegraph` | new |
| F-TF.8 | sin² + cos² = 1; find one from the other and the quadrant | sin² + cos² = 1 `g12-pythid` | new |
| A-SSE.4 | the sum of a geometric series | Geometric series `g12-geoseries` | new |
| A-APR.5 (+) | (x + y)ⁿ from Pascal's triangle | Pascal's triangle `g12-binomial` (3D) | new |
| F-BF.5 (+), F-LE.4 | log rules: quotients, powers, change of base | Log rules `g12-logrules` (products are 11th grade's `g11-log`) | new |
| F-TF.3 (+) | values at 30°, 45°, 60°; π − x, π + x, 2π − x | `g12-unit` + *fold*: √2/2, √3/2 and tan | existing |
| F-TF.4 (+) | odd, even, repeating | `g12-unit` + *fold*: −30°, 420°; Shift a wave `g12-wave` | existing, new |
| F-BF.3, F-IF.7e, F-TF.5 | waves that start late: A sin(B(x − C)) + D; cos is sin moved 90° | `g12-wave` | new |
| F-TF.6–7 (+) | restrict to undo; solve trig equations | Undo a sine `g12-arcsin` | new |
| F-TF.9 (+) | sum and difference formulas | Adding angles `g12-addangle` | new |
| F-BF.4b–d (+) | check an inverse by composing; read it off a graph; restrict to undo | Undo a function `g12-undo` | new |
| F-IF.7d (+) | rational graphs: zeros, walls, far ends | Walls and far ends `g12-asymptote` | new |
| N-VM.1 (+) | an arrow's length and direction | Vector length `g12-vecmag`; Length and direction `g12-vecdir` | existing, new |
| N-VM.2, 4a, 4c, 5 (+) | parts from tip − tail; add; subtract; times a number | Add arrows `g12-vecadd` | new |
| N-VM.3, 4b (+) | velocity stories; a sum's length and direction | `g12-vecdir`; Paths in time `g12-param` | new |
| N-VM.6–8 (+) | tables of data; add, subtract, scale, multiply | Tables of numbers `g12-matrix`; Multiply matrices `g12-matmul` | new |
| N-VM.9 (+) | AB and BA differ | `g12-matmul` | new |
| N-VM.10–12 (+) | 0 and identity; matrix × arrow; a 2 × 2 moves the plane; det is the area | A matrix moves the plane `g12-matmove` | new |
| A-REI.8–9 (+), N-VM.10 | a system as one matrix equation; solve with the inverse; none when det is 0 | Solve with a matrix `g12-matsolve` | new |
| N-CN.3 (+) | conjugate, length (modulus), quotients | Complex numbers as points `g12-cpolar`; Multiply by turning `g12-cmult` | new |
| N-CN.4, 6 (+) | polar form; distance and midpoint | `g12-cpolar` | new |
| N-CN.5 (+) | ×, ÷, conjugate and powers as turns and stretches | `g12-cmult` | new |
| G-GPE.3 (+), 3a | ellipses and hyperbolas from their foci; models | Ellipses `g12-ellipse`; Hyperbolas `g12-hyperbola` | new |
| Texas P.3A–C | parametric paths | `g12-param` | new |
| Texas P.3D–E | polar points and graphs | Points by turn and go `g12-polar`; Graphs that turn `g12-polargraph` | new |
| Texas P.3F–I | conics as a cone's slices; their equations | Slice a cone `g12-conics` (3D); `g12-ellipse`; `g12-hyperbola` | new |
| Texas P.4I–K | vectors; the dot product and the angle between | `g12-vecmag`, `g12-vecadd`, `g12-vecdir`; Dot product `g12-dot` + *fold*: turn to 0; *fold*: the angle | existing, new |
| Texas P.5A, C–E | Σ; arithmetic and geometric series; a geometric sum that goes on forever | Arithmetic series `g12-series` + *fold*: Σ; `g12-geoseries`; Sums forever `g12-infsum` | existing, new |
| Texas P.5K–L | polynomial and rational inequalities | `g12-asymptote` (where it's above 0) | new |
| Limits | from a graph and a table; each side; joined or broken | Where is it heading? `g12-limgraph` | new |
| Limits | 0 ÷ 0: factor and cancel | Limits by factoring `g12-limit` | existing |
| Limits | walls and far ends | `g12-asymptote` | new |
| Derivatives | a secant's slope shrinking to the tangent's | From secant to tangent `g12-diffq` | new |
| Derivatives | power rule, polynomials, tangent lines, chain rule | Power rule `g12-power`; Derivative of a polynomial `g12-polyd`; Slope of a tangent line `g12-tangent` + *fold*: the line's equation; Chain rule `g12-chain` | existing |
| Derivatives | rising and falling; highest and lowest; the best box | Hills and valleys `g12-extrema` (3D) | new |
| Integrals | area by thinner and thinner strips | Area under a curve `g12-riemann` | new |
| Integrals | antiderivatives; F(top) − F(bottom) | Antiderivatives `g12-anti`; Definite integrals `g12-defint` | existing |

**Grade boundaries.** 11th grade (Algebra 2, `grade11.md`) keeps a sequence's far terms (`g11-seq`, `g11-geo`),
composing and undoing a line (`g11-compose`, `g11-inverse`, which flips a line over y = x), logs of a product and the
log graph as 2ˣ flipped (`g11-log` and its fold), solving with a log (`g11-logsolve`), i on tiles and complex roots
(`g11-i`, `g11-complex`, `g11-cxroots`; N-CN.1–2 and 7–9). 9th grade keeps slides, stretches, even and odd
(`g9-shift`) and the average rate of change (`g9-avgrate`). 11th grade sends all of trig, the geometric series sum,
Pascal's triangle and log rules here (its open question 1: one copy, ids kept if they move down). So 12th grade
teaches the circle and the wave from the start (`g12-rad`, `g12-deg`, `g12-unit`, `g12-pythid`, `g12-sinegraph`), then
takes each idea one step on: waves that start late, undoing curves and the sine (`g12-undo` starts with curves, since
11th grade already flips lines), the sum and difference formulas, quotients, powers and change of base for logs, sums
that go on forever, complex numbers as points and turns, and 9th grade's average rate shrunk to a tangent. 10th grade
(Geometry, `grade10.md`) keeps right-triangle trig and its trig wheel (`g10-trig`, `g10-special`), arc length with the
radian as arc counted in radii (`g10-arc`), a circle's equation (`g10-circle`), the parabola from its focus and
directrix (`g10-parabola`, G-GPE.2), Cavalieri (G-GMD.2) and the tangent's construction (G-C.4), and ½ab sin C and the laws of sines and cosines, the swinging side's two triangles included
(`g10-trigarea`, `g10-sines`, `g10-cosines`; G-SRT.9–11; Massachusetts' model course puts these four in Precalculus,
but one copy is enough). 12th grade takes ellipses and hyperbolas (G-GPE.3), which
10th grade leaves here. After 12th grade: AP Calculus's other rules (open question 3); S-MD.6–7 are in 10th and 11th
grade's plans and S-MD.1–5 are left to Obento²'s Probability track; Obento²'s tracks start where this ends (Linear
algebra's spec needs `g12-vecmag` and `g12-dot`).

## Chapters (teaching order)

| # | Chapter | Lessons |
|---|---|---|
| 1 | Angles that turn | Degrees to radians · Radians to degrees · Unit circle values · sin² + cos² = 1 |
| 2 | Waves | The sine wave · Shift a wave · Adding angles |
| 3 | Undoing | Undo a function · Log rules · Undo a sine |
| 4 | Arrows | Vector length · Add arrows · Length and direction · Dot product · Paths in time |
| 5 | Matrices | Tables of numbers · Multiply matrices · A matrix moves the plane · Solve with a matrix |
| 6 | Turn and go | Points by turn and go · Graphs that turn · Complex numbers as points · Multiply by turning |
| 7 | Conic sections | Slice a cone (3D) · Ellipses · Hyperbolas |
| 8 | Sums | Arithmetic series · Geometric series · Sums forever · Pascal's triangle (3D) |
| 9 | Limits | Where is it heading? · Limits by factoring · Walls and far ends |
| 10 | Derivatives | From secant to tangent · Power rule · Derivative of a polynomial · Slope of a tangent line · Chain rule · Hills and valleys (3D) |
| 11 | Integrals | Area under a curve · Antiderivatives · Definite integrals |

Undo a sine comes after Undo a function, because it restricts the same way. The sums lead into limits: a sum that goes
on forever is the first thing that "heads to" a number.

## What every 12th grade lesson shares

As in 5th grade: what to do on rows 0–2 (28), a miss on rows 3–4 (20, red), the picture from row 6 with its names at
its right end, the record 3 rows under it (36, 2 squares a digit) or beside it when the picture is tall, Check / Next
under the record. The first words never repeat the problem; the last line says why. Answers in the chapter colour; red
and green only for wrong and right.

- **The unit circle** (chapter 1): a radius of 20 squares (4 blocks) is 1, so a half is 10 squares and lies on a
  strong line, and 3/5 and 4/5 are 12 and 16 squares. √2/2 and √3/2 fall between grid lines, because no fraction of
  squares makes them. 0° is on the right and angles turn counterclockwise; the quadrants are numbered 1–4, small,
  outside (numbers, the spec's §4 fix). The circle is 40 squares tall, so from row 6 it ends on row 46: the record sits
  to its right, and the camera steps back to about 90% so the words, the circle and the record all fit. 10th grade's
  trig wheel read a quarter circle to 3 places; here the whole circle, exactly. (Adding angles uses a bigger circle, 25
  squares; sin² + cos² = 1 one of 10, 13 or 17; the polar grid a ring a block: each lesson says.)
- **Waves:** across, a block is 30° (one square is 6°), so a full turn is 60 squares; the strong lines are named in
  degrees and, under them, in radians (`π/6`, `π/2`, `π`, `2π`). Undo a sine needs 45° on a line too, so it uses 2
  squares for 15° (it says why).
- **The plane:** axes on strong lines; each lesson says what a square or a block is. When the two axes count
  differently (a block across, a square up), both are numbered on their strong lines, as 8th grade's stories are.
- **Term tables** (Derivatives, Integrals): one column per power, 2 blocks wide, named small over it (`x⁴ x³ x² x 1`),
  as Multiply by 10, 100, 1000 names its place columns; rows `f` and `f′` (or `∫` and `=`) 4 squares tall.
- **Roots in answers** (`√3/2`, `2√3`) are typed as 10th grade types them (`grade10.md`, Typing): a box in front, √,
  a box under it (`[2]√[3]`), over a box for a fraction. The first draft chose the root from three blocks; one way for
  all of high school is simpler.
- **Angles that aren't special** (an arrow's direction, a point's turn, a complex number's angle) are read on 10th
  grade's trig wheel: turn the ray and the readout gives the sine, cosine or tangent to 3 places, or turn it until the
  readout matches to find the angle (`tan θ = 1.333`: `53°`). No calculator is needed. The wheel goes to 180°, so an
  angle past it is read as its angle back to the x-axis and then turned on (as Unit circle values does).
- **Exact and about.** An angle from a 3-4-5 corner isn't a whole degree (53.13°), so the record writes `θ ≈ 53°` and
  keeps the exact parts (`cos θ = 3/5`) for the working.
- **Arrows and points from triples** are drawn at the most squares a unit (5, 3, 2 or 1) that keeps the longer part
  within 30 squares: a 3-4-5 arrow is 15 × 20 squares, a 6-8-10 one 18 × 24, a 7-24-25 one 7 × 24. The first draft's
  "a square a unit" made a 3-4-5 arrow 3 × 4 squares, too small to be the hero.
- **3D** (Slice a cone, Pascal's triangle's cube, Hills and valleys' box) is Unit cubes: flat first, the paper tilts only as the maths rises,
  words stay facing the child, flat again before the next problem.
- Steps answered by a hand move set their Core box from the move (`LessonRun.set`), so Core's checks and slips stay;
  a box an earlier move already answered is set at once (`autoAnswer`).

**New hand moves** (not yet in the kit table of `README.md` or in another grade's plan; each comes with the first
lesson that uses it, after G sees its preview):

| Move | What the finger does; the live readout | Used by |
|---|---|---|
| Cut the turn | the fractions' ruler bent round a circle: drag a handle along the edge; it snaps to piece sizes that divide 180°; dashed spokes cut the circle; a dot under the angle's end, green when a cut lands on it, red when none does; Cut commits; `60° pieces: 3 in π` | rad, deg |
| Shape a wave | drag a wave's handles: its middle (the wave rides up or down), a crest (it stretches from the middle), the end of its first wave (it squeezes or spreads), its start (it slides); all snap to squares; `middle y = 3`, `one wave: 120°` | sinegraph, wave |
| Move the plane | drag the tip of e₁ or e₂ to a crossing; the unit square and the faint grid inside it lean into a parallelogram; `e₁ → (2, 1)`, `area 5` | matmove |
| Row onto column | drag a row of one matrix; it turns a quarter and lies down a column of the other; each pair of numbers draws its rectangle of squares; `8 + 3 = 11` | matmul |
| Tilt the sheet (3D) | 7th grade's Slide the sheet, tilted: drag the see-through sheet's handle; the cut lights and is named as it changes; it snaps as steep as the cone's side; `as steep as the side: parabola` | conics |

Reused from the kit: the ruler cut (riemann, extrema, undo, binomial), slide pieces (matrix, matsolve, geoseries,
logrules, binomial), tap pieces (infsum), tap a block that opens (diffq), drag a point along a line, here also along a
curve, the point held on it (limgraph, limit, asymptote, diffq, extrema, ellipse, hyperbola, undo, polar, pythid), hop
(matsolve), drag a rectangle's edge or corner (defint, hyperbola, dot), place columns (infsum's repeating decimals),
write. From 6th–8th grade: place a point, lay a line, draw the step, sweep a line, slide / flip / turn a shape,
stretch from a point, raise a square on a side (vecmag, pythid), fold (6th: extrema), turn a ray (7th), choose (7th).
From 10th grade's plan: lay the straightedge, in its square-corner form, to drop a height (unit, pythid, addangle,
polar) and its trig wheel (vecdir, polar, cpolar, dot). From 11th grade's plan: copy the whole (geoseries, logrules).

## 1. Angles that turn (the unit circle)

### Degrees to radians (`g12-rad`, existing; F-TF.1)
**One square:** the circle's radius is 20 squares; the half turn is the whole, named `π`. **Picture:** the circle;
the half turn's arc bold from 0° to 180°, named `π` (`180°` small under it); the angle's arm from the centre, its arc
in the chapter colour, named at its end: `120°`. Its How to starts where 10th grade's Arc length (`g10-arc`) stopped,
an arc counted in radii: the half turn unrolled is a bit more than 3 radii, exactly π of them, so here the half turn is
named π.
1. **Cut the turn** (new): "Cut the half turn into pieces that fit 120°." Drag the handle along the edge; it snaps to
   10°, 12°, 15°, 18°, 20°, 30°, 36°, 45°, 60° or 90°; readout `60° pieces: 3 in π`. **Cut** commits. No cut on the
   angle's end: "No cut lands on 120°. Try another size." Fits but smaller than it could be (the web's "Not the
   biggest"): "Those fit. Bigger pieces fit too." Right: the spokes turn solid, the angle's pieces number 1, 2 and π's
   number 1, 2, 3 under the bold arc. (Sets the web's GCF box, 60.)
2. **Write** `120° × π/180 = [2]π/[3]`, read off the pieces (the web's radians step; its slip, upside down: "Degrees go
   on top: the angle over the half turn, 180.").
Say: "120° is 2 of the 3 pieces in a half turn: 2π/3."
**Core:** as the web (t from its 14 angles, 30° to 330°; smallest-of-six start; the spec's check: past 90°, past 180°,
past 270°, any). `pre` becomes g10-arc (spec). The snapping set holds every GCF the generator needs (30, 45, 60, 90);
angles past 180° keep cutting round into the second half turn (210° is 7 pieces where π holds 6: 7π/6).

### Radians to degrees (`g12-deg`, existing; F-TF.1)
**Picture:** the same circle, the half turn bold and named `π = 180°`; the arm resting at 0°; the angle to find as the
arm's name: `5π/6`.
1. **Cut the turn** into the bottom number of pieces: readout `6 pieces in π: 30° each`. Cut at the wrong count:
   "That's 4 pieces in π. π/6 cuts it into 6." (Sets the web's piece step, 180° ÷ 6 = 30°.)
2. **Turn the arm** (7th grade's Turn a ray): it snaps to the spokes; readout `5 pieces`; the arc sweeps behind it.
   Wrong: "That's 4 pieces. 5π/6 is 5 of them."
3. **Write** `180° ÷ 6 = 30°` (set by the cut), `5 × 30° = [150]°` (the web's slips: "π/6 is 180° split into 6
   pieces: divide." and "5 pieces of 30° each: multiply.").
Say: "Each π/6 is 30°, and 5 of them make 150°."
**Core:** as the web (d from 2, 3, 4, 6; n from 1 to 2d − 1 with no common factor; smallest-of-six start; the spec's
check, each item n ≥ 2). Past π the arm turns on into the lower half.

### Unit circle values (`g12-unit`, existing; F-TF.2, F-TF.3, F-TF.4)
**Picture:** the circle with its axes through the centre (a half, 10 squares, lies on a strong line); the arm at 0°;
the problem as the name at the right: `sin 210°`.
1. **Turn the arm** to 210° (Turn a ray; it snaps every 30°, every 15° in the fold's problems); readout `210°`, and
   the quadrant it's in lights, `quadrant 3` (sets the quadrant box). Turned clockwise: "Angles turn counterclockwise
   from the right, through 1, 2, 3, 4."
2. **Turn back** to the x-axis: drag from the arm to the nearer side of the x-axis; a small arc follows; readout `30°
   back` (sets the reference angle). To the y-axis: "The reference angle goes back to the x-axis, not the y-axis."
3. **Lay the straightedge** (10th grade's) from the arm's tip down to the x-axis at a square corner; for cos, read
   its foot. The small right triangle draws, its angle 30° and its height 10 squares, half the radius, below the axis
   (the web's beats: quadrant, reference angle, value).
4. **Write** `sin 210° = [−1]/[2]` (the web's value step, "Put any minus sign on the top", and its slip: "Sine is the y
   value: positive above the x-axis.").
Say: "sin 30° is 1/2, and the point is below the x-axis, so sin 210° is −1/2."
*Fold (F-TF.3):* from problem 7, one in three uses the other heights. Three ticks stand on each axis, named `1/2`,
`√2/2`, `√3/2` (10th grade's special triangles); the last two sit between grid lines, because no fraction of squares
makes them. The height (for cos, the foot) lands on a named tick; **write** it with its sign, the root typed as 10th
grade does: `cos 135° = −[1]√[2]/[2]`. Wrong tick: "The foot is at the √2/2 tick: a 45° triangle." Some ask tan, the arm's slope, rise over run on the triangle: `tan 225° = [1]` (the 30° family
gives `√3/3` or `√3`, typed as roots: rise over run on the 30° triangle, 10 over 17.3 squares).
*Fold (F-TF.4):* from problem 9, one in three turns the other way or past a full turn: `sin(−30°)` turns clockwise,
`cos 420°` goes once round and on. The record adds the rule: `sin(−30°) = −sin 30°`, `cos 420° = cos 60°`. Say:
"Turning the other way flips the height: sine changes sign."
**Core:** as the web (odd problems sin, even cos; the first three cos 60°, sin 30°, cos 300°; the spec's four-item
check, unchanged). The new kinds start at problems 7 and 9, so the check's items stay the web's; the past-a-turn kind
keeps the ±1/2 values. Tests for every new value and sign.

### sin² + cos² = 1 (`g12-pythid`, new; F-TF.8)
**One square:** the circle's radius, which is 1, is 10, 13 or 17 squares by the triple (3-4-5 uses 10, so 4/5 is 8
squares): every leg is whole. Only the half of the circle right of the y-axis is drawn (or left, by the problem's sign), 20
to 34 squares tall. **Picture:** the half circle and its axes; the problem as the name at the right: `cos θ = 4/5,
quadrant 4`; under it `sin θ = ?`.
1. **Drag a point** along the x-axis to cos θ: it snaps every square; readout `0.8: 8 of 10`. Wrong: "That's 6 of 10.
   cos θ is 4/5: 8 squares."
2. **Lay the straightedge** (10th grade's, square-corner form) up through it: it meets the circle twice, above and
   below. **Tap** the one in quadrant 4. Wrong: "Quadrant 4 is below the x-axis."
3. **Raise a square** (8th grade's) on the foot's leg, then on the radius: `8 × 8 = 64`, `10 × 10 = 100`. The square on
   the height's leg fills with what's left (See): `100 − 64 = 36`, a 6 × 6 square: the height is 6 squares, 0.6.
4. **Write** `sin²θ = 1 − (4/5)² = [9]/[25]`, `sin θ = [−3]/[5]`.
Say: "The legs' squares fill the radius's square: sin² + cos² = 1. It's below the x-axis, so sine is negative."
*Kinds:* sin given, cos found, from problem 3; tan from 6 (`tan θ = sin θ ÷ cos θ = [−3]/[4]`); from 9 values that aren't
from a triple, drawn on the radius-10 circle with no squares to count: `sin θ = 1/3`, quadrant 2: `cos θ =
−[2]√[2]/[3]`.
Slips: sin = 1 − cos ("Square first: 1 − (4/5)², not 1 − 4/5."); the sign of the wrong quadrant ("Quadrant 4: right
of the y-axis and below the x-axis, so cos is positive and sin is negative."); the square root left off ("9/25 is
sin². sin is its square root, 3/5.").
**Core:** new. Triples 3-4-5 (radius 10), 5-12-13 (radius 13), 8-15-17 (radius 17), either leg given, all four
quadrants; the first three problems 3-4-5 in quadrants 1 and 2. Check: one sin from cos, one cos from sin, one in
quadrant 3 or 4, one tan.

## 2. Waves

### The sine wave (`g12-sinegraph`, new; F-TF.2, F-TF.5, F-IF.7e)
**One square:** across, a block is 30° (one square 6°), so a turn is 60 squares; up, 10 squares are 1, the radius of a
small unit circle drawn at the wave's left end with its centre on the wave's middle line, so 1/2 is a strong line.
The picture is 82 squares wide, and the camera steps back to about 80%. **Picture:** the circle with its arm at 0°;
to its right the empty axes, 0° to 360°; the name `y = sin x` at the right end.
1. **Turn the arm** (7th grade's Turn a ray; it snaps every 30°): the tip's height carries across as a dashed level
   line to the wave's axes; readout `30°: up 0.5`.
2. **Place a point** where that level line meets the 30° line on the axes: it rings. Wrong: "That's at 60°. Put it on
   the 30° line." After four points the rest place themselves as the arm turns on, and the wave strokes on through
   them (See).
3. **Write** what the wave shows: `one wave: [360]°`, `highest [1]`, `lowest [−1]`.
Say: "The wave is the tip's height, unrolled: after one turn it starts again."
*Kinds:* cos from problem 3 (the tip's across, carried round by a quarter turn of the circle: the wave starts at the
top). *Wheels* from 4 (F-TF.5): "A wheel 20 m across turns once a minute. Its middle is 12 m up." The axes are
named in seconds and metres (a block is 5 or 10 s, so one turn is 30 to 60 squares; up, a block is 2, 5 or 10 m, the
smallest that fits the top in 30 rows); **Shape a wave** (new) drags the middle, a crest
and one wave's end onto the story's numbers: readouts `middle 12`, `swings 10`, `one wave: 60 s`; **write**
`h = [10] sin([6]t) + [12]` (360° ÷ 60 s = 6° a second; the car starts level with the middle, going up). Tides and a spring from 7; reading a drawn wave's middle,
swing and period from 9, `y = [2] sin([3]x) + [1]`.
Slips: the period written where the number with x goes ("One wave is 120°, so 3 waves fit in 360°: x is multiplied
by 3."); the
top for the swing ("The swing is from the middle to the top: 10, not 22.").
**Core:** new. A 1–3, B 1–4, D −2 to 2 with A + |D| ≤ 3 (30 rows at a block a unit); wheels 10–40 m across, their
middle 1–5 m above the radius, once round in 30, 40, 60 or 120 s; the first three problems y = sin x or cos x placed
point by point. No starting late here: that's Shift a wave.

### Shift a wave (`g12-wave`, new; F-BF.3, F-IF.7e, F-TF.4, F-TF.5)
**One square:** across, a block is 30° (π/6), one square 6°, a full turn 60 squares; up, a block is 1 (stories keep
The sine wave's scales, named on the axes). **Picture:** a dashed target wave; over it the plain wave `y = sin x`
in the chapter colour, with round handles on its middle (left end), its first crest, the end of its first wave and its
start; the target's name is the question: `y = ? sin(?(x − ?)) + ?`. The sine wave found a wheel's middle, swing and
period; here the wave also starts late, and the record is school's full form.
1. **Shape a wave** (new): drag the middle, the crest and the end of the first wave in turn; each snaps to squares;
   readouts `middle y = 1`, `up and down 2`, `one wave: 180°`. Wrong: "The target's middle is at 1: halfway between 3
   and −1." / "The target repeats every 180°."
2. Drag the start: the whole wave slides along; readout `starts 30° late`. Wrong: "The target first rises through its
   middle at 30°."
3. **Write** `y = [2] sin([2](x − [30]°)) + [1]`, with `360° ÷ 180° = 2` written for the child. Slips: the period put
   with x ("The number with x is how many waves fit in 360°: 360 ÷ 180 = 2."); the shift's sign ("x − 30° starts it
   30° later: right, not left."); the top for the swing ("2 is how far it swings from the middle, not how high it
   reaches.").
4. (F-TF.4) **Slide** the plain sine 90° to the left (Slide a shape): it lands on the cosine (See); record
   `cos x = sin(x + 90°)`. From problem 7, **flip** it over the y-axis instead (Flip over a line): cos lands on
   itself, sin lands upside down; **choose** `the same` or `upside down`; record `cos(−x) = cos x` or
   `sin(−x) = −sin x`.
Say: "It swings 2 about a middle of 1, fits 2 waves in a turn, and starts 30° late."
*Kinds:* radians from problem 5 (the axis named π/6 to 2π: `y = 2 sin(2(x − π/6)) + 1`); stories from 7 (a wheel
already turning when the clock starts: `h = 12 − 10 cos(6(t − 5))`); the tangent from 10, drawn from the arm's slope:
it repeats every 180° and runs off at 90° and 270°; **write** its period, `[180]°`.
**Core:** new. A 1–3, B 1–4, C ±30° to ±120° in 30° steps (a whole number of squares), D −2 to 2 with A + |D| ≤ 3, so
the wave fits 30 rows; sin or cos; the first three problems only a start (A = 1, B = 1, D = 0), the full form from 4.
An answer is right when it draws the same wave (a cos written as a shifted sin counts). Check: a late start, an early
one, one in radians, one story.

### Adding angles (`g12-addangle`, new; F-TF.9)
**One square:** here the radius is 25 squares (5 blocks), so 3/5 is 15, 4/5 is 20, 7/25 is 7 and 24/25 is 24: every
corner below sits on a crossing. Only the quarter of the circle the turns pass through is drawn. **Picture:** the
arc; the first arm, angle a, to its 3-4-5 corner (20 across, 15 up), named `cos a = 4/5, sin a = 3/5`; the second
angle's name, `b = a`; the question, `sin(a + b)`.
1. **Turn the arm** on by b (Turn a ray, from the first arm): readout `a + b`; its tip lands on a crossing, (7, 24).
2. **Lay the straightedge** from the tip onto the first arm at a square corner: its foot lands at (16, 12) (readout
   `4/5 of the way out`); a small right triangle stands on the first arm, its sides `cos b` along it and `sin b`
   across.
3. The tip's height splits at the foot's level (See): the lower part is the foot's height, 12 (the first arm cut to
   4/5: `sin a cos b`); the upper part is the climb from the foot, 12 (`cos a sin b`). Readout `12 + 12 = 24`.
4. **Write** `sin(a + b) = sin a cos b + cos a sin b = (3/5)(4/5) + (4/5)(3/5) = [24]/[25]`. It checks on the grid:
   the tip is 24 up of 25.
Say: "The height comes in two parts: sin a cos b, then cos a sin b."
*Kinds:* cos(a + b) from problem 2 (across: `16 − 9 = 7`, so `cos a cos b − sin a sin b = [7]/[25]`); differences
(turn back by b) from 4; the same pictures turned by quarter turns into other quadrants from 6. From 7, school's kind,
with no picture to scale: `sin a = 3/5` in quadrant 2, `cos b = 12/13` in quadrant 4: a table of the four products
(cells 6 × 3) where the child **taps** the two that make sin(a + b), then writes `[56]/[65]`. From 10, exact values:
`sin 75° = sin(45° + 30°) = √2/2 · √3/2 + √2/2 · 1/2 = (√6 + √2)/[4]`, written for the child up to its last box.
Slips: `sin a + sin b` ("3/5 + 3/5 = 6/5 is past the top of the circle: a sine is never more than 1."); the sign in
cos ("cos(a + b) takes sin a sin b away."); two sines in one product ("Each part of sin(a + b) has one sine and one
cosine.").
**Core:** new. Picture kinds: a and b from the 3-4-5 pair (the angles with sines 3/5 and 4/5), b may be negative,
everything turned by 0–3 quarter turns; every tip lands on the 25-square circle. School kinds: sines and cosines from
3-4-5, 5-12-13 and 8-15-17 with quadrants. Check: one sum, one difference, one cos, one school kind.

## 3. Undoing

### Undo a function (`g12-undo`, new; F-BF.4b, F-BF.4c, F-BF.4d)
11th grade's Inverse functions (`g11-inverse`) already flips a line over y = x and writes its inverse, so this lesson
starts with curves and does what that one doesn't: read the inverse off a graph or a table, check it by composing,
and restrict a curve so it can be undone (the first draft opened with lines, a repeat).
**One square:** a block is 1 both ways; the window holds both graphs and the line y = x (0 to 8 each way, 40 squares,
the camera at about 90%; −3 to 6 each way for the restricting kind). **Picture:** the plane, the line `y = x` dashed
and named; the graph of f named at its end: `f(x) = x³`. The question: `f⁻¹(8)`.
1. **Flip over a line** (8th grade's, across y = x, as 11th grade's log graph flips its points): drag the graph over
   the dashed line; it turns over like a card and lands mirrored in the chapter colour, the old graph staying. Readout
   as it turns: `(2, 8) → (8, 2)`. Stopped short: "Flip it all the way over the line."
2. **Drag a point** along the new graph to x = 8 (as Evaluate a function does): readout `(8, 2)`. **Write**
   `f⁻¹(8) = [2]` (F-BF.4c). Read the wrong way: "f⁻¹(8) is the x that f sends to 8: go across 8, then read up."
3. **Write** the check by composing (F-BF.4b): `f(f⁻¹(8)) = f(2) = 2³ = [8]`, back where it started; then the other
   way, `f⁻¹(f(2)) = ∛8 = [2]`.
*Tables* (F-BF.4c, from problem 3): f given as a table only, x over f(x); **slide** the two rows past each other so they
swap (the flip, done on numbers): the bottom row is now the input. Read `f⁻¹(11) = [4]`.
*Restrict* (F-BF.4d, from problem 4): `f(x) = x²`. The flip lands as a sideways parabola; **sweep a line** (8th
grade's) across it: `x = 4: 2 points`, so it isn't a function. Lay the ruler along x = 0 and **cut** the left half
of f away (readout `keep x ≥ 0`); flip again: one point for each x. Record `f(x) = x², x ≥ 0`, `f⁻¹(x) = √x`,
`f⁻¹(4) = [2]`.
Say: "Flipping over y = x swaps every pair: what f does, f⁻¹ undoes."
**Core:** new. f from x³, 2ˣ (its flip is log₂ x, as in 11th grade's log graph), √x, x² on x ≥ 0 (from problem 4),
and tables of 2x + b or x² + b (b −3 to 3); the asked input chosen so the answer is whole and inside the window; the
first three problems x³ and 2ˣ. Check: one graph read, one table, one compose, one restrict. Slips: 1 ÷ f ("1 ÷ f(8)
is a different number. f⁻¹ undoes f."); the coordinates read the wrong way round; the whole parabola kept ("x = 4 has
two partners. Keep one half.").

### Log rules (`g12-logrules`, new; F-BF.5, F-LE.4)
11th grade's Evaluating logarithms counted 2s as chips and added two logs of a product; here the log is a length.
**One square:** the log ruler: one block is one factor of the base, so the strong lines are named with its powers
(`1 2 4 8 16 32 64 …`, small) and a number's log is its distance from 1 in blocks. Base 2 runs 0 to 10 blocks (50
squares); base 3 and 10 the same. A number in the problem that isn't a power (48, 3, 5) gets a small tick where it
falls. **Picture:** two log rulers, one over the other, the lower one free to slide; the question as the name at the
right: `log₂ 48 − log₂ 3`.
1. **Slide** the lower ruler (Slide a shape, along a line) so its 3 sits under the upper ruler's 48: readout `48 ÷ 3`.
   Its 1 now sits under 16 (See: lengths take away as numbers divide). Readout `log₂ 16 = 4 blocks`. Wrong: "Line up
   3 under 48: taking away a length divides."
2. **Write** `log₂ 48 − log₂ 3 = log₂ (48 ÷ 3) = log₂ [16] = [4]`.
Say: "On the log ruler a length is a log: taking away 3's length divides by 3."
*Powers* (from problem 4): `log₂ 8⁵`. **Copy the whole** (11th grade's): 8's length, 3 blocks, laid down 5 times:
readout `5 copies of 3 blocks = 15`; **write** `log₂ 8⁵ = 5 log₂ 8 = 5 × [3] = [15]`. *Change of base* (from 7):
`log₄ 32`: copy 4's length (2 blocks) along to 32 (5 blocks): `2½ copies`; **write** `log₄ 32 = log₂ 32 ÷ log₂ 4 =
5 ÷ 2 = [2.5]`. *Put together* (from 9): `2 log₃ 6 − log₃ 4 = log₃ (36 ÷ 4) = [2]`; base 10 with its small ticks:
`log 5 + log 20 = log 100 = [2]`.
Slips: log a ÷ log b for the log of a quotient ("Logs of a quotient take away: 48's length minus 3's, not 48's
divided by 3's."); the power added, not multiplied ("8⁵ is 5 copies of 8's length: 5 × 3."); the bases swapped in a
change of base ("Count copies of 4's length: 32's length ÷ 4's length.").
**Core:** new. Bases 2, 3 and 10; every number a power of the base or, for quotients and products, landing on one;
answers whole (halves in change of base); the first three problems quotients in base 2. Check: one quotient, one
power, one change of base, one put together.

### Undo a sine (`g12-arcsin`, new; F-TF.6, F-TF.7)
**One square:** across, 2 squares are 15°, so 30°, 45°, 60° and 90° are 4, 6, 8 and 12 squares and the axis from −90°
to 360° is 60 squares (at the waves' 6° a square, 45° falls mid-square and the axis is 75 squares, wider than the
screen); ticks every 15°, named every 90°. Up, 10 squares is 1, so the heights 1/2, √2/2, √3/2 stand at 10, 14.1 and
17.3 squares. **Picture:** the sine wave, its part from −90° to 90°
drawn bold (the part that only rises); the question as the record's first line: `sin x = 1/2, 0° ≤ x < 360°`.
1. **Lay a line** level (8th grade's Lay a line, held level): drag its handle up; it snaps to 0, ±1/2, ±√2/2, ±√3/2,
   ±1 (Unit circle values' ticks); readout `y = 1/2`. Each crossing with the wave rings.
2. **Tap** the crossing on the bold part: `30°`. **Write** `arcsin(1/2) = [30]°`. Wrong: "150° is outside −90° to
   90°. arcsin gives the one on the bold part."
3. **Tap** every crossing from 0° to 360°: the second is the mirror at 90°; readout `2 answers`. **Write**
   `x = 30°` or `x = 180° − 30° = [150]°`. Only one: "sin is 1/2 twice in a turn: look past 90°."
Say: "arcsin gives the one on the bold part; the wave's mirror at 90° gives the other."
*Kinds:* negative values from problem 4 (`sin x = −1/2`: 210° and 330°; `arcsin(−1/2) = −30°`); cos from 6 (its
bold part 0° to 180°, its mirror at 180°: `cos x = 1/2` at 60° and 300°); stories from 8, a Ferris wheel 20 m across,
its middle 12 m up, once round a minute: "When is the car 17 m up?" `12 − 10 cos(6t) = 17`, `cos(6t) = −1/2`,
`6t = 120° or 240°`, `t = [20]` or `[40]` seconds; radians from 10 (`x = π/6 or 5π/6`).
**Core:** new. Values 0, ±1/2, ±√2/2, ±√3/2, ±1; the first three problems sine with a positive value; ±1 has one
answer (readout `1 answer`), so the "only one" slip waits for the others. Slips: one answer only; 360° − x for sine
("For sine the mirror is at 90°: 180° − 30°."); an arcsin outside −90° to 90°.

## 4. Arrows (vectors on the plane)

An arrow is drawn from its tail, its head at its tip, named at the tip (`⟨3, −4⟩`); axes on strong lines. Each
lesson says what a square is; arrows from triples use the shared rule (5, 3, 2 or 1 squares a unit, the longer part
within 30 squares).

### Vector length (`g12-vecmag`, existing; N-VM.1)
**One square:** the shared rule for triples (a 3-4-5 arrow at 5 squares a unit is 15 × 20 squares; a 7-24-25 one at a
square a unit is 7 × 24), so a unit square is a block or a square and can be counted. **Picture:** the arrow from the
origin, named `v = ⟨3, −4⟩`.
1. **Draw the step** (8th grade's): from the tail across, `3 right`, then down, `4 down`, to the tip; the square
   corner is marked (the web's beat 1). Past the tip: "That's past 3. Stop under the tip."
2. **Raise a square** (8th grade's) on each leg, outward: `3 × 3 = 9`, `4 × 4 = 16`, counted in unit squares. Then
   on the arrow: the two squares pour into it and fill it exactly, readout `9 + 16 = 25` (sets the web's sum step;
   the camera steps back to about 75% while the three squares stand, then comes back in).
3. **Write** `|v| = √25 = [5]` (the web's slip: "The straight arrow is shorter than going across and then up.").
4. **Turn** the arrow (Turn a ray) down onto the x-axis: it reaches 5, the grid's check (readout `5`).
Say: "The arrow is the long side of the step's right triangle: √(3² + 4²) = 5."
**Core:** as the web (a triple's legs from TRIPLES, random signs, either way round; smallest-of-six start; the
spec's check: one item in each of quadrants 2–4 and one with a length of 13 or more). The sum step is set by the pour,
so its slip ("Square each part first.") moves to the hint.

### Add arrows (`g12-vecadd`, new; N-VM.2, N-VM.4a, N-VM.4c, N-VM.5)
**One square:** a unit is 2 squares (parts −6 to 6, sums inside ±10: 40 squares each way). **Picture:** two arrows from the origin, `u = ⟨4, 1⟩`
in the chapter colour and `v = ⟨−1, 3⟩` striped; the question `u + v`.
1. **Slide** v (Slide a shape) until its tail sits on u's tip; it snaps to crossings; readout `tail on (4, 1)`.
   Elsewhere: "Put v's tail on u's tip: tip to tail."
2. The sum draws from the origin to v's new tip (See). **Write** `u + v = ⟨4 + (−1), 1 + 3⟩ = ⟨[3], [4]⟩`.
3. **Slide** u onto v's tip the other way round: the same corner, and the parallelogram closes (See).
Say: "Tip to tail, the parts add: 4 − 1 across and 1 + 3 up."
*Kinds:* from two points (N-VM.2, from problem 4): "u goes from A(1, 2) to B(5, 3)": **draw the step** from A to B,
`4 right, 1 up`; write `⟨5 − 1, 3 − 2⟩ = ⟨[4], [1]⟩`. Subtract (N-VM.4c, from 6): **turn** v a half turn (Turn a shape:
−v), then add it. Times a number (N-VM.5, from 8): `3u` is three u's tip to tail, then **stretch** from the tail (8th
grade's Stretch from a point), `× 3`: `3⟨2, −1⟩ = ⟨[6], [−3]⟩`, `|3u| = 3|u|`; −2u turns and stretches. From 10 the
record sets `|u + v|` beside `|u| + |v|` (triples): lengths don't simply add.
Slips: parts subtracted; A − B for B − A ("From A to B: B's numbers minus A's."); × 3 on one part ("3u stretches the
whole arrow: both parts × 3.").
**Core:** new. Parts −6 to 6, sums inside ±10, no zero arrow; the first three problems all parts positive; points −5
to 8.

### Length and direction (`g12-vecdir`, new; N-VM.1, N-VM.3, N-VM.4b)
**One square:** the most squares a unit (5, 3, 2 or 1) that keeps the length within 30 squares: a length of 10 is 3
squares a unit, 30 squares long. **Picture:** the plane; the arrow given by its length and direction, `|v| = 10`,
direction `3 across, 4 up for each 5` (θ ≈ 53°), the direction drawn small at the origin as that step.
1. **Turn** an arm (Turn a ray) to the direction; it snaps on the 3-4-5 direction and every quarter turn; readout
   `53°: 3 across, 4 up for each 5`.
2. **Stretch** it to 10 (Stretch from a point): readout `|v| = 10`; its tip lands on (6, 8).
3. **Write** `x = 10 cos θ = 10 × 3/5 = [6]`, `y = 10 sin θ = 10 × 4/5 = [8]`, `v = ⟨6, 8⟩`. Swapped: "Across goes with
   cos: the foot of the angle."
*Two arrows* (N-VM.4b, from problem 4): each turned into parts, added tip to tail, then the sum's length and direction
written (`|s| = [13]`, `tan θ = 12/5`, and on the trig wheel `θ ≈ [67]°`). *Stories* (N-VM.3, from 6): "A boat heads
north at 8 km/h. The river runs east at 6 km/h." Arrows tip to tail; record `⟨6, 8⟩`, `speed [10] km/h`, `[53]° from
east`. Planes in a wind, a pulled sled.
Say: "Length and direction become across and up: |v| cos θ and |v| sin θ."
**Core:** new. Directions from the 3-4-5 pair and its quarter turns, and 0°, 90°, 180°, 270°; any whole degree from 9
(read on the trig wheel, answers to 0.1, the arm's tip then off the crossings); lengths 5–20 in fives; the first three problems one arrow in quadrant 1.
Slips: sin and cos swapped; angles added for the sum's angle ("Angles don't add: find the sum's parts first, then its
angle.").

### Dot product (`g12-dot`, existing; + fold turn to 0, + fold the angle)
**One square:** on the plane a unit is 2 squares (parts −9 to 9: 36 squares each way); beside it, each product is
built as a rectangle a square a unit, solid when positive and striped when negative (the first draft only typed the
products, the web's steps as they were). **Picture:** both arrows from the origin, `⟨2, 3⟩` and `⟨4, −1⟩` (striped).
1. A dashed line drops from each tip to the x-axis (the web's beat 1): the x parts light, `2` and `4`. **Drag the
   corner** of the first rectangle out to 2 by 4: readout `2 × 4 = 8`. Wrong size: "That's 2 by 6. Use the x parts:
   2 and 4." (Sets the web's x step; its slip, "Multiply the x parts. Adding comes last.", is the hint.)
2. Across to the y-axis (beat 2): `3` and `−1`. **Drag the corner** of the second, 3 by 1, striped: readout
   `3 × −1 = −3`. Wrong: "That's 3 by 4, and 4 is an x part. Match y with y: 3 and −1." (the web's "Mixed the parts").
3. **Slide** the striped rectangle onto the solid one: 3 squares cancel, 5 are left; readout `8 − 3 = 5`. **Write**
   `⟨2, 3⟩ · ⟨4, −1⟩ = 8 + (−3) = [5]` (slip: "Multiply within each part, then add the parts."). The angle between
   the arrows draws, named `dot 5` (beat 3). When both rectangles are solid, or both striped, step 3 slides one
   beside the other and they join instead: `8 + 3 = 11`.
Say: "Positive: the arrows are less than a right angle apart." (The web's three endings; the spec's new idea line.)
*Fold, turn to 0:* from problem 7, a last step: **drag** the striped arrow's tip (Place a point; it snaps to crossings);
the rectangles rebuild as it moves, readout `dot 5`, `dot 0`, `dot −7`; at 0 they are the same size and cancel
completely (the same number of squares), and the square-corner mark appears. "Move it until the dot product is 0." Record `⟨2, 3⟩ · ⟨−3, 2⟩ = 0`.
Say: "At a square corner the dot product is 0." (The spec's missing 0 item: the child makes it.)
*Fold, the angle* (Texas P.4): from problem 10 both arrows come from triples (`⟨3, 4⟩` and `⟨4, 3⟩`): after the dot
product, **write** `cos θ = 24 ÷ (5 × 5) = [0.96]`, then turn 10th grade's trig wheel until its readout matches:
`θ ≈ [16]°`. Slip: the lengths left out ("Divide by both lengths: 5 × 5.").
**Core:** as the web (parts −9 to 9, none 0, never parallel; smallest-of-six start; the spec's check). The fold kinds
start at 7 and 10, so the check stays the web's; the angle kind draws both arrows from 3-4-5 and 5-12-13 legs with
signs. The turn-to-0 fold has no box: it's done when the readout shows 0.

### Paths in time (`g12-param`, new; parametric paths; N-VM.3)
**One square:** a unit is 2 squares; starts and moves are chosen so the points from t = 0 to 4 stay inside −8 to 12
across and −4 to 12 up (40 × 32 squares). The ball is a square a metre both ways (up to 20 × 20); the circle a block a
unit. **Picture:** the plane, a start dot named `t = 0` at (1, 3); the two rules in the record's first lines: `x = 1 + t`,
`y = 3 + 2t`.
1. **Place a point** for t = 1, 2, 3: readout `t = 1: (2, 5)`. Wrong: "At t = 1, y = 3 + 2 × 1 = 5." Each point gets
   its t, small, beside it.
2. The path draws through them with small arrows the way time runs, and one tick's move, ⟨1, 2⟩, is drawn as an
   arrow, the velocity (See).
3. **Write** the path without t: `t = x − 1`, `y = 3 + 2(x − 1) = [2]x + [1]`.
Say: "t is the clock: each tick, the point moves 1 right and 2 up."
*Kinds:* where and when from problem 4 ("Where is it at t = 5?", "When does it reach x = 10?"); speed with a triple's
move (⟨3, 4⟩: `speed [5]` a tick); a thrown ball from 6, `x = 3t`, `y = 20t − 5t²`: place t = 0 to 4, the path is a
parabola: "Where does it land?" `t = [4]`, `x = [12]`; a circle from 9, `x = 5 cos t`, `y = 5 sin t` at quarter turns
and 3-4-5 corners: `x² + y² = [25]`.
**Core:** new. Starts −5 to 5; a tick's move ⟨a, b⟩ with a dividing b (so the path's slope is whole) or a triple, inside
the window above; t 0 to 5 (t = 5 only asked, not drawn, when it leaves the window); the first three problems moves with positive parts. Ball: up-speed 10, 15 or 20, across-speed 2–5 (it lands at
t = up-speed ÷ 5). Slips: the two rules swapped; t = 0 skipped ("The path starts at t = 0: (1, 3)."); t read as x.

## 5. Matrices

A matrix is a table of cells 6 × 3 squares (numbers 28) inside square brackets drawn on grid lines; the plane lessons
use a block as 1.

### Tables of numbers (`g12-matrix`, new; N-VM.6, N-VM.7, N-VM.8)
**One square:** one thing sold. Each cell of the table is a column 3 squares wide standing on its row's floor, its
squares stacked up to its number, the number written under it; a table is two shelves of columns (rows `small`,
`large`), named at the right. (The first draft put a bar of up to 18 squares inside a 6-square cell: it couldn't fit.)
**Picture:** two 2 × 3 tables, `A` (October) and `B` (November): a shop's sales, columns `red`, `blue`, `green`.
1. **Slide** B onto A (Slide a shape): it snaps when the cells line up, and each of B's columns stacks on top of A's
   in the same place (striped, then solid as it joins); readout per cell, `4 + 3 = 7`. A table of another size won't
   sit: "A is 2 rows by 3 columns and C is 3 by 2: they don't line up."
2. **Write** the cells the words ask for (the rest fill in): `[7]`, `[11]`.
3. *Times a number* (from problem 4): **stretch** A's columns up from their floors (Stretch from a point), `× 2`;
   every column doubles; write two cells of `2A`.
*Subtract* (from 6): B's columns slide on striped and cancel from the top (7th grade's taking away); a cell that goes
below 0 hangs under its floor, striped.
Say: "Same size, so each cell adds to the cell in its place."
**Core:** new. Entries 0–6, so a sum or a double is at most 12 squares tall and two shelves fit 30 rows; 2 × 2 and
2 × 3; one size mismatch in each 6 problems; differences −6 to 6 from 6; the first three problems two 2 × 2 tables
added. Slips: a cell added to its neighbour; a number times one row only ("2A doubles every cell.").

### Multiply matrices (`g12-matmul`, new; N-VM.6, N-VM.8, N-VM.9)
**One square:** a 1 in a product is one square, so 2 × 4 is a 2-by-4 rectangle of squares. **Picture:**
`A = [2 3; 1 2]` and `B = [4 1; 1 3]` side by side; the product as an empty 2 × 2 table under them; to their right a floor where the pairs'
rectangles stand side by side (each at most 5 × 5).
1. **Row onto column** (new): drag A's first row; it turns a quarter and lies down B's first column, snapping when
   its numbers sit beside theirs. Each pair draws its rectangle, 2 × 4 and 3 × 1; readout `8 + 3 = 11`; 11 drops into
   row 1, column 1. Onto a row: "A row of A meets a column of B: turn it down the column."
2. The child drags one more row; the other entries play themselves (See).
3. **Write** `AB = [[11] [11]; [6] [7]]` (the first set by the move).
4. BA plays itself beside it (See, N-VM.9): `[9 14; 5 9]`. The record: `AB ≠ BA`.
Say: "Each entry is a row times a column: 2 × 4 + 3 × 1 = 11."
Negative entries from problem 5 (their rectangles striped, taken away). *Stories* (N-VM.6, from 7): a row of prices
`[3 5]` (apples, pears) times a table of how many each of two shops sold: each shop's takings. *Sizes* (from 9): a
2 × 3 times a 3 × 2, and a pair that can't: "A's rows have 2 numbers and B's columns 3: they don't pair up."
**Core:** new. Entries 0–5 (−3 to 5 from 5); the first three problems 2 × 2 times 2 × 1, then 2 × 2 times 2 × 2.
Slips: cell by cell ("Matrices don't multiply cell by cell: row times column."); row times row.

### A matrix moves the plane (`g12-matmove`, new; N-VM.10, N-VM.11, N-VM.12)
**One square:** a block is 1, so the unit square is one block. **Picture:** the plane, the unit square shaded, its
two edges as arrows `e₁` (1 across) and `e₂` (1 up); the matrix named beside: `[2 1; 1 3]`.
1. **Move the plane** (new): drag e₁'s tip to where the first column sends it, (2, 1); the square leans into a
   parallelogram and the faint grid inside leans with it; readout `e₁ → (2, 1)`. Wrong: "e₁ goes to the first
   column: (2, 1), not the first row."
2. Drag e₂'s tip to (1, 3). The plane is moved.
3. **Place** where v = ⟨1, 2⟩ lands: 1 of the new e₁, then 2 of the new e₂, tip to tail; readout `(4, 7)`. **Write**
   `[2 1; 1 3]⟨1, 2⟩ = ⟨[4], [7]⟩`.
4. The faint grid inside shows every old unit square leaned the same way, so the parallelogram stands for all of
   them; readout `area 5` (the unit square was 1; in the first problems, stretches, the a × d rectangle is counted in
   blocks). **Write** `det = 2 × 3 − 1 × 1 = [5]`.
Say: "The columns say where the two edges go, and every area grows 5 times: that's the determinant."
*Kinds:* stretches only (b = c = 0) for the first three problems: a rectangle a by d; det 0 from 7: the square
flattens onto a line: "No area is left: this move can't be undone."; the identity (nothing moves) and a flip (det
below 0: the square turns over, its shading striped) from 9.
**Core:** new. Entries 0–3 (−3 to 3 from 5); every image (the square's corners and v's tip) inside a window 9 blocks
across and 7 up (45 × 35 squares), the axes placed to fit. Slips: rows for columns; ad + bc ("Take away:
2 × 3 − 1 × 1.").

### Solve with a matrix (`g12-matsolve`, new; A-REI.8, A-REI.9, N-VM.10)
**One square:** a unit is 2 squares when the hops fit 15 units each way, a square when they need 30. **Picture:** the system once, as the record's first lines: `2x + y = 7`, `x + 3y = 11`;
beside it the plane with the columns' arrows ⟨2, 1⟩ and ⟨1, 3⟩ and the target (7, 11) ringed.
1. **Slide** each number of the system into its cell of `[□ □; □ □]⟨x, y⟩ = ⟨□, □⟩` (it snaps into a cell). Wrong
   cell: "2 goes with x in the first line: row 1, column 1."
2. **Hop** along the first arrow, then the second, to reach (7, 11): readout `2 of ⟨2, 1⟩ + 3 of ⟨1, 3⟩ = (7, 11)`.
   Off: "That lands on (8, 9). Reach (7, 11)."
3. **Write** school's way: `det = 2 × 3 − 1 × 1 = [5]`; the inverse draws itself (See: 2 and 3 swap places, the two
   1s turn negative, all over 5): `A⁻¹ = 1/5 [3 −1; −1 2]`; then `⟨x, y⟩ = A⁻¹⟨7, 11⟩ = ⟨[2], [3]⟩`.
Say: "2 of the first arrow and 3 of the second reach (7, 11): x = 2, y = 3. A⁻¹ undoes the move."
*No inverse* (from problem 8): the two arrows lie on one line (det 0); the hops stay on it and miss the target, or
reach it many ways; **choose** `no answer` or `many answers`.
**Core:** new. Entries 1–4 with det not 0; x, y −3 to 5, whole, with the target's numbers −15 to 15; the first three problems
x, y 1–4. Slips: det as ad + bc; the inverse without the swap; the ÷ det left off ("A⁻¹ is 1/5 of that: divide by the
determinant.").

## 6. Turn and go (polar points and complex numbers)

The polar grid: rings every block (a ring is 1) and spokes every 30° and 45°, drawn faint over the paper's squares
round a centre on a block crossing; up to 4 rings (40 squares across), the camera at about 90%. A point 5 rings out
(the 3-4-5 kinds) draws only the half of the grid it is in, 25 rows tall.

### Points by turn and go (`g12-polar`, new; polar coordinates)
**Picture:** the polar grid; the point to place named at the right: `(4, 120°)`.
1. **Turn the arm** to 120° (Turn a ray; it snaps to spokes), then **drag** out along it: readout `120°`, `r = 4`.
   Wrong: "That's 3 rings out. r = 4." / "That's 60°. Turn to 120°."
2. **Lay the straightedge** from the point to the x-axis at a square corner: the triangle draws; its foot and its
   height read in squares.
3. **Write** `x = 4 cos 120° = 4 × (−1/2) = [−2]`, `y = 4 sin 120° = 4 × √3/2 = [2]√[3]`.
Say: "Turn 120°, go 4: across is 4 cos 120°, up is 4 sin 120°."
*Back the other way* (from problem 4): a point (3, 4) already placed; **turn the arm** onto it and drag out to it:
`r = [5]`, `θ ≈ [53]°` (`tan θ = 4/3`, on the trig wheel). *Backwards* (from 9): `(−2, 30°)`: turn to 30°, go 2 backwards through the
centre, and land at 210°.
**Core:** new. r 1–4, θ every 30° or 45° (roots typed); the other way from the 3-4-5 pair and the axes; the first
three problems angles 0°–90°. Slips: cos and sin swapped; θ turned clockwise; r as x + y.

### Graphs that turn (`g12-polargraph`, new; polar graphs)
**Picture:** the polar grid; the rule at the right, `r = 2 + 2 cos θ`; a table beside it, θ every 30°, cos θ, r.
1. **Turn the arm** to the table's next angle (Turn a ray; it snaps to spokes): readout `60°: cos θ = 1/2`. **Write**
   that row's r: `2 + 2 × 1/2 = [3]`.
2. **Drag** out along the arm to r: readout `r = 3`, and the point is placed. Wrong: "r = 3 at 60°: 3 rings out."
   Steps 1 and 2 go for 0°, 60° and 90° (r = 4, 3, 2).
3. The arm sweeps on round and the curve draws through every row (See): a heart.
4. **Choose** its name from three blocks (`circle`, `heart`, `rose`), or **tap** where r is biggest; roses ask how many
   petals.
Say: "As the arm turns, r stretches and shrinks: r = 2 + 2 cos θ draws a heart."
**Core:** new. r = a (a circle round the centre), 2a cos θ or 2a sin θ (a circle through it), a + a cos θ (a heart),
a cos(nθ) with n 2 or 3 (roses: n petals when n is odd, 2n when even), a + b cos θ from 9; a 1–2 so r ≤ 4; the first
three problems circles. Slips: a negative r placed forward ("r = −1: go 1 backwards, through the centre."); 2n petals
for an odd n.

### Complex numbers as points (`g12-cpolar`, new; N-CN.3, N-CN.4, N-CN.6)
**One square:** the shared rule for triples (a 3-4-5 point at a block a unit, a 5-12-13 one at 2 squares); across
is real, up is imaginary, named on the axes. Placing z and reading its length and angle is Points by turn and go's
move on the complex plane; what's new is the conjugate, the length's square, and distance and midpoint.
**Picture:** the complex plane; the number named where it goes: `z = 3 + 4i`.
1. **Place** z: readout `3 + 4i`. Swapped: "3 is the real part: across."
2. **Turn** its arrow from the centre down onto the real axis (as Vector length): readout `5`. **Write**
   `|z| = √(3² + 4²) = [5]`.
3. The arm's angle reads `53°` on the trig wheel. **Write** `z ≈ [5](cos [53]° + i sin [53]°)`.
4. **Flip** z over the real axis (Flip over a line): `z̄ = 3 − [4]i`; then `z × z̄ = 3² + 4² = [25] = |z|²`.
Say: "Same point, two ways: 3 across and 4 up, or turn 53° and go 5."
*Distance and midpoint* (N-CN.6, from problem 7): two numbers; **draw the step** between them; `|z − w| = [5]`,
midpoint `(z + w) ÷ 2 = [1] + [2]i`. *Polar to rectangular* (from 9): `2(cos 150° + i sin 150°) = −[1]√[3] + [1]i`.
**Core:** new. Parts from triples (3-4-5, 6-8-10, 5-12-13) with signs; angles to
the nearest degree (the 3-4-5 pair, 37° and 53°, and their quarter turns), exact for axis, 30° and 45° kinds; the
first three problems in quadrant 1. Slips: |z| as 3 + 4 ("The straight line is shorter than across and up."); the
angle from the imaginary axis; both parts flipped for the conjugate.

### Multiply by turning (`g12-cmult`, new; N-CN.5, N-CN.3)
**One square:** a block is 1 (2 squares for powers). **Picture:** the complex plane; z = 2 + i and w = 1 + i as arrows from the centre, each
with its length and angle small (`√5, 27°`, `√2, 45°`); the question `z × w`. Its How to starts from 11th grade's What
is i? (× i is a quarter turn, so i × i is a half turn, −1) and goes on: × (1 + i) is an eighth of a turn and a stretch.
1. **Turn** z's arrow on by w's angle (Turn a ray, from z): readout `27° + 45° ≈ 72°`.
2. **Stretch** it by w's length (Stretch from a point): readout `× √2`; its tip lands on a crossing, (1, 3).
3. **Write** the product the 11th grade way: `(2 + i)(1 + i) = 2 + 2i + i + i² = [1] + [3]i`: the same point.
Say: "Multiplying turns by w's angle and stretches by w's length."
*Kinds:* × 2, × 2i and × (1 + i) for the first three problems, z off the axes (11th grade's What is i? already turned
by quarter turns from the axes: here a stretch, then a turn and a stretch, then an eighth turn); × any w from 4; ÷ from 6 (turn back and shrink;
school's way with the conjugate: `(1 + 3i) ÷ (1 + i) = (1 + 3i)(1 − i) ÷ 2 = [2] + [1]i`); powers from 9: `(1 + i)⁴`
is four turns of 45° stretched by √2 four times: `4(cos 180° + i sin 180°) = [−4]`; `(√3 + i)³` is three turns of
30° stretched by 2 three times: `[8]i` (powers are drawn at 2 squares a unit so 8 fits; the first draft's
`(√3 + i)⁶ = −64` can't be drawn).
**Core:** new. Parts −3 to 3 with products inside ±10 that land on crossings. Slips: i² as +1 ("Two quarter turns
make a half turn: i² = −1."); the angles multiplied ("Angles add: 27° + 45°."); the lengths added.

## 7. Conic sections

### Slice a cone (`g12-conics`, new; conics from a cone) — 3D
**Picture:** flat first: a circle on the paper 4 blocks across, named `cone`; the target named at the right: `Cut a
parabola.`
1. The paper tilts and a double cone rises from the circle, tip to tip (See: Unit cubes' rise, as 8th grade's cone
   stands up).
2. **Tilt the sheet** (new): a see-through sheet cuts the cone; drag its handle to tilt it; the cut lights in the
   chapter colour and is named as it changes; readout `flatter than the side: ellipse`, `as steep as the side:
   parabola`, `steeper: hyperbola`, `level: circle`. It snaps as steep as the side when it comes close. Release on the
   target; wrong: "That's an ellipse: the sheet is flatter than the cone's side. Tilt it until it's as steep as the
   side."
3. The paper lies flat; the cut's outline drops onto the paper and is named (See). **Choose** its equation's shape
   from four blocks: `x² + y² = r²`, `x²/a² + y²/b² = 1`, `y = ax²`, `x²/a² − y²/b² = 1`.
Say: "As steep as the side, the cut opens once and never closes: a parabola."
**Core:** new. Targets circle and ellipse (problems 1–3), then parabola, then hyperbola, mixed from 7; through the tip
(a point, a line, two crossing lines) from 9. The check is the tilt: within the band for each shape (the parabola's
band is the snap).

### Ellipses (`g12-ellipse`, new; G-GPE.3, G-GPE.3a)
**One square:** the most squares a unit (4, 3, 2 or 1) that fits the ellipse in 44 across and 34 up: (5, 4, 3) is 4
squares a unit, 40 × 32 squares (the first draft's half a unit drew it 20 × 16). **Picture:** two pins on the x-axis at ±3 (the foci, named),
a loop of string 10 long from pin to pencil to pin; the pencil at the right end of the axis.
1. **Drag the pencil** (held tight by the string, along the curve): it draws as it goes; readout `6.4 + 3.6 = 10`:
   the two pieces always add to 10. Once round, the ellipse is drawn.
2. **Drag the pencil** to the top: the pieces are equal, `5 + 5`, each the long side of a right triangle with 3 along
   the axis. **Write** `b² = 5² − 3² = [16]`, `b = [4]`.
3. **Write** `x²/[25] + y²/[16] = 1`.
Say: "The string's two pieces always add to 10, so the top is 5 from each pin: b² = 25 − 9."
*From the equation* (from problem 4): `x²/25 + y²/9 = 1`: `c² = 25 − 9 = [16]`; **place** the pins at ±4. Wrong:
"c² = a² − b²: 25 − 9 = 16, so the pins are 4 from the middle." Tall ones from 5; a moved centre,
`(x − 2)²/25 + (y + 1)²/16 = 1`, from 9. *Stories* (G-GPE.3a, from 7): a whispering room 26 m long and 10 m wide:
stand on the pins, `[12]` m each way from the middle; a planet's orbit.
**Core:** new. (a, b, c) from triples with a the longest: (5, 4, 3), (5, 3, 4), (10, 8, 6), (10, 6, 8), (13, 12, 5),
(13, 5, 12), (17, 15, 8); the first three problems (5, 4, 3) or (10, 8, 6), wide. Slips: c² = a² + b² ("That's for a
hyperbola. An ellipse's pins are inside: c² = a² − b²."); a, not a², under x²; a and b swapped on a tall one.

### Hyperbolas (`g12-hyperbola`, new; G-GPE.3, G-GPE.3a)
**One square:** a unit is 2 squares for 3-4-5 (pins at ±10 squares), 1 for the bigger triples; the window is 40 × 32
squares, both branches running off its edges. **Picture:** two pins at ±5; a point P on
the curve, its two distances drawn; a dashed box comes later.
1. **Drag P** along the curve: readout `8 − 2 = 6`, `13 − 7 = 6`: the difference stays 6. Release at the turn on the
   axis: `(3, 0)`, so a = 3.
2. **Write** `b² = c² − a² = 25 − 9 = [16]`.
3. **Drag the corner** of the dashed box to (3, 4) (drag a rectangle's corner); its diagonals run on as the lines the
   branches lean toward. **Write** `x²/[9] − y²/[16] = 1`, `y = ±[4/3]x`.
Say: "The two distances always differ by 6, so the pins sit outside the turn: c² = a² + b²."
*From the equation*, placing the pins, from problem 4; opening up and down from 5; a moved centre from 9; a story from
7: two microphones 10 m apart hear a bang, at one 6 m (of sound) sooner: it came from somewhere on this curve.
**Core:** new. (a, b, c) with c the longest: (3, 4, 5), (4, 3, 5), (6, 8, 10), (8, 6, 10), (5, 12, 13), (12, 5, 13);
the first three problems 3-4-5, opening sideways. Slips: c² = a² − b² ("That's an ellipse's. Here the pins are
outside: c² = a² + b²."); the lines' slope a/b.

## 8. Sums

### Arithmetic series (`g12-series`, existing; + fold Σ)
**One square:** across, a term is a column 2 squares wide (1 square when there are more than 20); up, a square is 1,
2, 5, 10 or 20, the smallest that fits the pairs' height in 30 rows (a pair reaches 301 at the web's top), numbered on
the strong lines. The How to's sum, the web's 1 + 2 + … + 100, would be 100 columns: it is drawn as the ten columns at
each end with a torn gap between (a column a square wide, up a square is 5, so a pair is about 20 rows), and the
pairing is shown on those. **Picture:** the terms
as columns standing on a line, a staircase; the first three and the last named (`4`, `7`, `10`, … `term 20`); the
question as the name: `4 + 7 + 10 + … (20 terms)`.
1. **Drag** a bracket along the staircase's top from the first column to the last: it counts the steps up, readout
   `19 steps of 3`. **Write** `4 + 19 × 3 = [61]` (the web's slip: "It's 20 minus 1, which is 19 jumps.").
2. **Turn** a copy of the staircase a half turn (Turn a shape) and **slide** it on top: every column now reads the
   same; readout `4 + 61 = 65` on each. Off: "Fit the copy's tallest column onto the shortest." **Write** `4 + 61 =
   [65]` (slip: "A pair is the two terms added together.").
3. The two staircases make a rectangle, 20 columns of 65: **write** `65 × 20 ÷ 2 = [650]` (slip: "Each pair uses two
   terms, so divide by 2.").
Say: "Turned onto itself, every column makes 65: 20 columns of 65 is twice the sum."
*Fold (Σ):* from problem 7 the sum is given as `Σ (3k + 1), k = 1 to 20`; a first step writes the ends: `k = 1: [4]`,
`k = 20: [61]`.
**Core:** as the web (a 1–20, d 1–9, n 6–30; smallest-of-six start; the spec's check and new idea line). The Σ kind
reads the same generator.

### Geometric series (`g12-geoseries`, new; A-SSE.4, Texas P.5C)
**One square:** 1, so the terms are pieces laid end to end in one strip, each named small over it (`2 4 8 16`).
**Picture:** the strip, named `S = 2 + 4 + 8 + 16` at its left end.
1. **Stretch** the strip from its left end (8th grade's Stretch from a point), `× 2`: a copy grows under it, every
   piece twice as long; readout `2S = 4 + 8 + 16 + 32`. Wrong: "× 2: the ratio from one piece to the next."
2. **Slide** the copy along (Slide a shape) until its pieces sit under their equals: it snaps one piece over, 4 under 4,
   8 under 8, 16 under 16. Readout `3 pieces match`.
3. The matching pieces cancel (striped onto solid, See): left over are the copy's last piece, 32, sticking out at the
   right, and the strip's first, 2, at the left. Readout `2S − S = 32 − 2`.
4. **Write** `S = (32 − 2) ÷ (2 − 1) = [30]`, then school's rule: `S = a(rⁿ − 1) ÷ (r − 1) = 2(2⁴ − 1) ÷ 1`.
Say: "Doubled, every piece matches the next one, so only the ends are left: 2S − S = 32 − 2."
*Kinds:* r = 3 from problem 4 (`1 + 3 + 9`: `3S − S = 27 − 1`, so `S = 26 ÷ [2] = [13]`); too long to draw from 7,
written only: the chessboard's first 10 squares, `1 + 2 + … + 512 = 2¹⁰ − 1 = [1023]` grains; Σ from 9:
`Σ 3·2ᵏ, k = 0 to 5 = 3(2⁶ − 1) = [189]`; r = ½ from 10 on 5th grade's 48-square bar (`1/2 + 1/4 + 1/8 + 1/16 =
1 − (1/2)⁴ = [15]/[16]`), which leads into Sums forever.
Slips: one power too many ("4 pieces: the copy ends at 2 × 16 = 32, which is 2 × 2⁴."); not dividing by r − 1 ("3S − S
is 2S: divide by 2."); the copy's end given as the sum ("32 is the next piece. The sum is 32 − 2 = 30.").
**Core:** new. a 1–3, r 2 or 3, n 3–5, with the copy's right end (a + rS) at most 64 squares; the first three problems r
= 2, a 1 or 2. Check: one r = 2, one r = 3, one written-only, one Σ.

### Sums forever (`g12-infsum`, new; Texas P.5D–E)
**One square:** a whole is 5th grade's bar, 48 squares long (54 for thirds). **Picture:** the empty bar, named `1`;
the sum as its name: `1/2 + 1/4 + 1/8 + …`.
1. **Tap** the gap in the bar: the next piece lays itself in, half the last one (24, then 12, 6, 3 squares); readout
   `1/2 + 1/4 + 1/8 = 7/8: 1/8 left`. After four taps the rest lay themselves in, thinner and thinner, and what's left
   shrinks toward nothing (See).
2. **Write** the sum so far with Geometric series' rule: `S₄ = 1 − (1/2)⁴ = [15]/[16]`; as more
   pieces come, (1/2)ⁿ heads to 0.
3. **Write** `S = a ÷ (1 − r) = ½ ÷ ½ = [1]`.
Say: "What's left halves every time, so the pieces close the gap: the sum is 1."
*Kinds:* other first pieces from problem 4 (`1/3 + 1/9 + …` fills half of a 54-square bar: `S = ⅓ ÷ ⅔ = [1/2]`;
`6 + 3 + 1.5 + …` on a bar 12 long); back and forth from 7 (`1 − 1/2 + 1/4 − …`: pieces laid on and taken off,
closing in on `[2/3]`); repeating decimals from 9 (`0.333…` in place columns, each digit a piece a tenth of the last:
`0.3 ÷ (1 − 0.1) = [1/3]`); a growing one from 9 (r = 2: the pieces spill past the bar; **choose** `no sum`). The
record also writes it the Σ way: `Σ (1/2)ⁿ, n = 1 to ∞, = 1`.
**Core:** new. r ½, ⅓ or ¼ (−½ from 7), a with a ÷ (1 − r) no longer than the bar; the first three problems a = r = ½.
Slips: a ÷ (1 + r) ("Take r from 1: 1 − ½."); the sum so far given ("15/16 is after 4 pieces. Forever, the gap closes:
1."); a sum for r of 1 or more ("The pieces grow: the sum never settles.").

### Pascal's triangle (`g12-binomial`, new; A-APR.5) — 3D for the cube
**One square:** in 3D one cube is one block (Unit cubes); x is 3 blocks and y is 2. Flat, Pascal's triangle is drawn in
cells 4 × 3 squares (numbers 28), so row 6, seven cells, is 28 squares wide. **Picture:** flat first: the square
(x + y)² on the paper, 25 squares a side, named at its right end; the triangle's first rows (`1`, `1 1`) beside it.
1. **Cut** the square with the ruler where x ends, across and down: four pieces, named as they part: `x²`, `xy`, `xy`,
   `y²`; readout `1, 2, 1`. Wrong: "Cut where x ends: 3 blocks."
2. The paper tilts and the square rises into the cube (x + y)³ (Unit cubes' rise). **Slide the sheet** (7th grade's, 3D)
   in where x ends, along each of the three directions: the cube comes apart into eight boxes, which gather by shape:
   readout `1 x³, 3 x²y, 3 xy², 1 y³`. The paper lies flat; the row `1 3 3 1` writes itself in the triangle.
3. **Slide** a copy of the row one cell to the right onto itself (slide pieces): every pair adds, readout `1 + 3 = 4`;
   the new row `1 4 6 4 1` writes in. Wrong: "Slide it one cell: each number adds to its neighbour."
4. **Write** what the problem asks: `(x + y)⁴ = x⁴ + [4]x³y + [6]x²y² + [4]xy³ + y⁴`.
Say: "One more bracket: times x keeps each piece in its cell, times y moves it one cell over, and the two add."
*Kinds:* rows to 6 from problem 3 (flat only); a number for y from 4, `(x + 2)⁴`: the x² term is `6 · x² · 2² =
[24]x²`; minus signs from 7, `(x − 1)⁴`, the odd powers of −1 striped: `x⁴ − [4]x³ + [6]x² − [4]x + 1`; `(2x + 1)ⁿ` from
9; a count from 10: "In how many ways can 2 of 5 friends be picked?" row 5's third number (`1 5 10 10 5 1`), `[10]` (11th grade's
Combinations).
Slips: the number's power left off ("(x + 2)⁴'s x² term has 2 twice: 2² = 4, so 6 × 4 = 24."); the row before or after
("(x + y)⁴ uses the row that starts 1 4."); every sign kept + for x − 1 ("−1 to an odd power is −1: the signs take
turns.").
**Core:** new. n 2–6; (x + a)ⁿ with a −3 to 3, not 0, and (2x ± 1)ⁿ for n ≤ 4; the first three problems (x + y)² and
(x + y)³ with the cube. Check: one full row, one term's number, one with minus, one count.

## 9. Limits

The limits use the plane, a unit 2 squares (a block when the picture is small). A hole is an empty ring a square
across; a filled dot is the function's value.

### Where is it heading? (`g12-limgraph`, new; limits from a graph and a table, each side, joined or broken)
**Picture:** a graph with something at x = 3: a hole, a dot moved off the curve, a jump, or nothing; the question as
the record's first line: `lim x→3 f(x)`; a small table beside it, x and f(x), empty.
1. **Drag a point** along the curve from the left toward x = 3 (it stays on the curve); it snaps at 2.9, 2.99 and
   2.999 and the table fills; readout `f(2.99) = 4.99`; release: `from the left: 5`.
2. The same from the right: `from the right: 5` (or `2`, for a jump).
3. **Write** `lim x→3 f(x) = [5]`, or **choose** `no limit` when the two sides disagree; then `f(3) = [2]` (the filled
   dot) or none (a hole); **choose** `joined` or `broken`.
Say: "From both sides it heads to 5, so the limit is 5, even though f(3) is 2."
*Tables only* (from problem 7): the graph stays hidden; the point is dragged along the x-axis and only the table
fills; the graph draws after the answer.
**Core:** new. Lines and parabolas with whole limits; the place where something happens at x = 1 to 6; holes and smooth
curves for problems 1–3, moved dots and jumps from 4, all mixed from 7. Slips: f(3) given for the limit ("f(3) is the
filled dot. The limit is where the graph heads."); one side for a jump ("From the left it heads to 5, from the right to
2: they don't agree, so there's no limit.").

### Limits by factoring (`g12-limit`, existing)
**Picture:** the plane framing the hole and the origin; the fraction as the graph's name, `(x² − 4) ÷ (x − 2)`; its
graph drawn, a line with an empty ring at x = 2 (the web's picture); the question `lim x→2`.
1. **Drag a point** along the x-axis to 2: the top and the bottom light, `0` and `0`: `0 ÷ 0`, no answer yet (the
   web's first beat).
2. **Write** `x² − 4 = (x − 2)(x + [2])` (the web's factor step and slip: "Multiply it back out: (x − 2) times (x +
   your number) has to give the top's number on its own, −4."). An area picture checks it (See): a rectangle x − 2 by
   x + 2, its four parts x², 2x, −2x, −4, the two x parts cancelling.
3. **Cancel:** drag the bottom's (x − 2) onto the top's; both cross out. What's left, x + 2, is the line; the ring
   stays.
4. **Drag a point** along the line toward the ring from each side: readout heads to `4`. **Write** `2 + 2 = [4]` (the
   web's slip: "0 ÷ 0 means simplify, not that the limit is 0.").
Say: "Away from x = 2 the fraction is just x + 2, so it heads to 4, past the hole."
**Core:** as the web (a and b −6 to 6, not 0, a + b not 0; smallest-of-six start; the spec's check covers the four
sign pairs and avoids b = a).

### Walls and far ends (`g12-asymptote`, new; F-IF.7d, limits at infinity, Texas P.5K–L)
**Picture:** the plane; the graph of `f(x) = (2x + 1) ÷ (x − 3)`, named at its end.
1. **Sweep a line** (8th grade's, here a dashed wall) to where the bottom is 0: readout `x = 3: bottom 0`. Wrong: "At
   x = 2 the bottom is −1, not 0."
2. **Drag a point** along the graph toward the wall from each side: readout `y = 72, 702, 7002…` from the right, and
   the same falling from the left; the wall is named `x = 3`.
3. **Drag a point** far to the right: the camera follows a little, then the readout runs on, `x = 100: 2.07`,
   `x = 1000: 2.007`; a level dashed line draws at 2. **Write** `lim x→∞ f(x) = [2]`.
4. **Place** where it crosses the x-axis (the top is 0): `x = [−1/2]`.
The record: `wall x = 3`, `level y = 2`, `crosses at x = −1/2`.
Say: "Near x = 3 the bottom is almost 0, so f shoots off: a wall. Far out, 2x over x is 2."
*Kinds:* a hole and a wall together from problem 5 (the cancelled factor leaves a ring, as Limits by factoring);
x² over x² and other powers from 7 (the level is the front numbers' ratio, or 0, or none); where it's above 0 from 9:
the zeros and walls cut the x-axis into pieces; **tap** the pieces where the graph is above it: record
`x < −1/2 or x > 3`.
**Core:** new. (ax + b) ÷ (x − c) with a −3 to 3, not 0, b −6 to 6, c −4 to 4, and ac + b not 0 (so nothing
cancels); the first three problems a = 1. Slips: the wall where the top is 0 ("At x = −1/2 the top is 0: it crosses
there. A wall is where the bottom is 0."); the level as b ÷ (−c); a cancelled factor taken as a wall ("(x − 2)
cancels: a hole, not a wall.").

## 10. Derivatives

### From secant to tangent (`g12-diffq`, new; the derivative as a limit)
**One square:** across, a block is 1 (so a square is 0.2); up, 2 squares are 1, so y = x² from −1 to 4 is 25 squares
across and 32 rows (1 square a unit for the taller kinds). **Picture:** the curve; the point P (1, 1) named; a second
point Q on the curve at x = 2 with a round handle; the line through both, its slope named (9th grade's Average rate of
change, `g9-avgrate`, drew this line between two fixed points; here Q slides in).
1. **Drag Q** toward P along the curve: it snaps every square (h = 1, 0.8, … 0.2); the line turns and the table fills,
   `h = 1: 3`, `h = 0.2: 2.2`.
2. **Tap** the small box round P (Rounding decimals' block that opens): it opens below, ten times as big (dashed lines
   to it); there the curve looks almost straight. Drag Q on in the big box: `h = 0.1: 2.1`, `h = 0.02: 2.02`.
3. **Write** `slope at x = 1: [2]`. A table value: "That's the slope to x = 1.2. Where are the slopes heading?"
4. School's working: `((1 + h)² − 1) ÷ h = (2h + h²) ÷ h = [2] + h`, and as h shrinks to 0, `[2]`.
Say: "As Q slides in, the line through both turns into the line that just touches at P: its slope heads to 2."
*Kinds:* x² at x = 1, 2 or 3 for the first three problems (the slope is twice the point's x), 2x² or 3x² from 4, a
falling stone from 6 (`d = 5t²` metres: average speeds from t = 2 over shorter times head to `[20]` m/s), x³ at 1
from 7.
**Core:** new. Points at whole x so the slopes are whole; Q from the right first, from the left (h below 0) from
problem 4. Check: x² at a new point, 2x² or 3x², the stone, x³. Slips: a secant's slope given; 2 + h kept ("h shrinks
to 0, so 2 + h heads to 2.").

### Power rule (`g12-power`, existing)
**Picture:** the term table, `3x⁴` in the f row's x⁴ column, the 4 ringed (the web's beat 0); beside it the graph of
f with x = 1 marked (across, a block is 1; up, a square is 1, 2 or 5, so the step in beat 4, a × n up to 54, fits 30
rows).
1. **Drag the exponent** down onto the 3 (beat 1): readout `4 × 3 = 12`.
2. **Slide** the term one column right, into the f′ row's x³ column (beat 2): readout `x⁴ → x³`. Two columns: "The
   power goes down by 1: one column right." Left: "For a derivative the exponent goes down by 1."
3. **Write** `f′(x) = [12]x^[3]` (the web's write step and slips: "Multiply 3 by the exponent 4 first.", "Lower the
   exponent by 1.").
4. On the graph (beat 4), a small step at (1, 3), 1 across and 12 up: `f′(1) = 12`.
Say: "The 4 comes down to multiply, and the power drops by one: 12x³."
**Core:** as the web (a 2–9, n 2–6; smallest-of-six start; the spec's check, never a = n = 2). `pre` becomes g8-slope
(spec). The two moves set the coefficient and exponent steps; the write keeps its slips.

### Derivative of a polynomial (`g12-polyd`, existing)
**Picture:** the term table with columns x³, x², x, 1; `2x³ − x² + 5x + 7` in the f row, each number in its column.
1. **Drag** each term down and one column right into the f′ row; its exponent drops onto it on the way (the web's
   beats 1–3): `3 × 2 = 6`, `2 × (−1) = −2`, `1 × 5 = 5`. **Drag** the constant off the table and it falls away (the
   web's strike). Slid right instead: "There's no column past the numbers: a constant's slope is 0."
2. **Write** `f′(x) = [6]x² + [−2]x + [5]` (the web's three steps and slips: "Bring the 3 down: 3 × 2.", "Bring the 2
   down: 2 × −1.", "cx is a line with slope c, so it does not vanish. Only the constant does.").
3. The f′ row slides down into an `x = 1` row where every power is 1 (beat 4): **write** `6 + (−2) + 5 = [9]` (slip:
   "That is f(1), the height. f′(1) uses the derivative's numbers: 6, −2, 5.").
Say: "Each term goes on its own and the constant drops out; at x = 1, f′ adds up to 9."
**Core:** as the web (a −4 to 4, b −6 to 6, c −9 to 9, none 0; d −9 to 9; smallest-of-six start; the spec's check).

### Slope of a tangent line (`g12-tangent`, existing; + fold the line's equation)
**One square:** across, a block is 1; up, a square is 1, 2 or 5, the smallest that fits the web's window in 30 rows.
**Picture:** the curve `f(x) = x² + 3x` (the web's window: the bend near the point, the vertex when it's close), the
point at x = 2 named `(2, 10)`. The first draft typed the web's two steps first and laid the line last; the hands now
find the slope first and the record writes the rule (as Rounding decimals does).
1. **Lay a line** (8th grade's) pinned at the point; its handle turns it through whole slopes; readout `slope 6`. At
   any slope but one it cuts the curve again, and the second crossing rings, measured: "That line crosses the curve
   again at x = 1. Turn it until it only touches." At 7 it touches and doesn't cross, the bend showing on both sides;
   it rings green.
2. **Write** `f′(x) = [2]x + [3]` (the web's step and slip: "The 2 in x² comes down and multiplies the number in
   front.").
3. **Write** `f′(2) = 2 · 2 + 3 = [7]`, the slope the line found (slip: "Slope comes from the derivative, not f
   itself."). The slope box is typed, not set by the move, so this slip stays.
Say: "f′(2) = 7, so the line that just touches at (2, 10) climbs 7 for each 1 across."
*Fold* (from problem 7): **write** the line, `y − 10 = 7(x − 2)`, `y = 7x + [−4]`.
**Core:** as the web (a ±1 to 4, b ±1 to 9, k ±1 to 4; smallest-of-six start; the spec's check, slope never f(k)).
The second crossing is x = (m − b) ÷ a − k for a laid slope m. The fold's number is f(k) − slope × k.

### Chain rule (`g12-chain`, existing)
**Picture:** the web's boxes on the grid: an outer box (a frame of whole squares) with the power `4` at its corner,
round a dashed inner box holding `3x + 1`, named `inside`.
1. **Drag the power** out of the corner to the front (the power rule on the outside, the web's beat 1): it leaves `3`
   as the new power; the inner box is marked `unchanged`. Into the inner box: "Outside first: the inside stays as it
   is." (Sets the outside step.)
2. **Drag x** along a small slider under the inner box, a square a step: the inside moves 3 for each 1 (readout `x + 1
   → inside + 3`, the web's "moves 3 per 1"). **Drag** that 3 out of the inner box to the front (beat 3): `3 · 4`. Took
   the 1: "The derivative of the number 1 is 0. The derivative of 3x is 3." (Sets the inside step.)
3. **Write** `f′(x) = [12](3x + 1)³` (the web's front step and slips: "The chain rule multiplies by the inside's
   derivative too.", "Keep the 4 that the power rule brought down too: 4 × 3.").
Say: "The inside moves 3 for each 1 of x, so the whole runs 3 times as fast: 4 × 3 = 12."
**Core:** as the web (a 2–5, b −9 to 9, not 0, n 2–5; smallest-of-six start; the spec's check, a never n; the spec's
fix to the inside step's line, `4(3x + 1)³ · 3`).

### Hills and valleys (`g12-extrema`, new; rising, falling, highest, lowest, the best box) — 3D for the box
**One square:** across, a block is 1; up, a square is 1, 2, 5 or 10, the smallest that fits the curve in 30 rows (2
here: −22 to 10 is 16 rows). **Picture:** `f(x) = x³ − 3x² − 9x + 5` from −3 to 5, named at its end; under the x-axis a strip a square tall where the slope's sign will paint.
1. **Drag a point** along the curve; a short tangent rides with it, its slope live: `slope 15`, `slope 0` (flat at the
   hilltop: it rings), `slope −12`; the strip paints under the point, the chapter colour where the slope is up,
   striped where it's down.
2. **Write** `f′(x) = 3x² − 6x − 9 = 3(x + 1)(x − 3)`, zero at `x = [−1]` and `x = [3]` (where the tangent was flat).
3. **Tap** the hilltop and the valley floor; **write** `highest near it: f(−1) = [10]`, `lowest near it: f(3) =
   [−22]`. Swapped: "At x = −1 the slope goes from up to down: that's a hilltop."
Say: "Up, flat, then down: the top of a hill is where f′ = 0."
*The box* (from problem 6, 3D): a sheet 12 by 12 (2 squares a unit for sheets of 6 and 12, a square for bigger ones). **Cut** a square from each corner with the
ruler (readout `x = 2`); the paper tilts and the four flaps **fold** up (6th grade's Fold, to a right angle) into an
open box: readout `V = 2 × 8 × 8 = 128`. **Drag** the cut's size: the corners grow and shrink, the box folds again,
and on the flat paper beside it the graph of V gains a point for each size; it's highest where its tangent lies flat.
**Write** `V = x(12 − 2x)² = 4x³ − 48x² + 144x`, `V′ = 12x² − 96x + 144 = 12(x − [2])(x − [6])`, `x = [2]`,
`V = [128]`. The paper lies flat before the next problem. Say: "Cut 2 from each corner: more or less, and the box
holds less."
**Core:** new. Cubics x³ − (3/2)(p + q)x² + 3pq x + d with whole turning points p < q, p + q even, from −3 to 4 (and
upside down, −f, from 4); the first three problems p = −1, q = 1. Sheets 6, 12, 18 or 24 square (x = side ÷ 6), and
16 by 10, 24 by 9, 21 by 16 (x = 2, 2, 3) from 9. Slips: the hilltop's x given for its height; hill and valley
swapped; x = 6 for the box ("At x = 6 the corners meet: no box is left.").

## 11. Integrals

### Area under a curve (`g12-riemann`, new; area by strips)
**One square:** across, a unit is 10 squares (2 blocks), so strips can be 10, 5, 2 or 1 squares wide; up, a unit is
2 squares (1 for 4x³, which reaches 32). **Picture:** y = x² from 0 to 3 (30 squares across, 18 up), named; the area under it outlined, `area = ?`.
1. **Cut** the area into strips with the ruler (5th grade's; its piece sizes are the strip widths): readout
   `3 strips`; each strip rises to the curve at its right end (the chapter colour), the bits over the curve striped;
   readout `14, with the striped bits`.
2. **Cut** thinner (halves, fifths, tenths of a unit): readout `6 strips: 11.38`, `15: 9.92`, `30: 9.46`; the table
   beside fills and the striped bits shrink (See).
3. **Write** `area = [9]`, where the totals head. A strip total: "14 counts the striped bits too. Where do the totals
   head as the strips get thinner?"
The record: `14, 11.38, 9.92, 9.46 → 9`. Say: "Thinner strips waste less: the totals head to 9, the area under the
curve." (The next lesson finds 9 at once.)
*Kinds:* a line for the first three problems (y = 2x from 0 to 3, a triangle of 9; the striped bits are small
triangles that shrink every cut); x² + 1 from 0 to 3 (12) and 3x² from 0 to 2 (8) from 4; a speed graph from 7: "A car
speeds up: v = 2t m/s for 5 s." The area is how far it went: `[25]` m; 4x³ from 0 to 2 (16) and strips standing on
their left ends (under the curve, not over) from 9.
**Core:** new. Curves and ends chosen so the area is whole. Slips: a strip total given; the left and right ends mixed
up ("Left ends sit under the curve: those totals climb toward 9.").

### Antiderivatives (`g12-anti`, existing)
**Picture:** the term table with an `∫` row and an `=` row and a spare row between them (the web's); `6x²` in the x²
column.
1. **Slide** the term one column left, into x³ (up a power; the web's beat 1): readout `x² → x³`. Right instead:
   "That's the derivative. Antiderivatives go up."
2. **Drag** the new power, 3, down under the 6 as a divider (beat 2, `÷ 3` rising): readout `6 ÷ 3 = 2`; `+ C` slides
   in at the end.
3. **Write** `∫6x² dx = [2]x^[3] + C` (the web's raise and divide steps, both final, and their slips: "That's the
   derivative. Antiderivatives go up.", "That's what the derivative does. Going back, divide by 3.").
4. The check (beat 3): **drag** the answer back right: the 3 comes down, `3 × 2 = 6`, and it lands on `6x²`, green.
Say: "Up a power, then divide by the new power, so the derivative gives back 6x²."
**Core:** as the web (n 1–5, a = (n + 1) × one of 1, 2, 3, 4, −1, −2; smallest-of-six start; the spec's check).

### Definite integrals (`g12-defint`, existing)
**One square:** across, a block is 1; up, a square is 1, 2, 5, 10, 20 or 50, the smallest that fits the curve's top
in 30 rows, numbered on the strong lines. **Picture:** the curve `y = 3x²`, the region from x = 0 to x = 2 outlined
(the web's dashed x = 2), named `∫₀² 3x² dx`.
1. **Write** `F(x) = x^[3]` (the web's anti step and slips: "Divide by the new power: 3 ÷ 3.", "That's the derivative.
   Antiderivatives raise the power by 1.", "That's the derivative's power. Antiderivatives raise the power by 1.";
   the spec's fix: x³, not 1x³).
2. **Drag the edge** (Long division's edge drag): the shading's right edge from 0 along the axis; readout, the area so
   far, F(x): `x = 1: 1`, `x = 2: 8`. Release at 2.
3. From problem 4, a bottom end j above 0: **drag** the left edge in from 0 to j; the strip from 0 to j lifts away,
   striped: readout `F(1) = 1 taken away`.
4. **Write** `2³ − 0³ = [8]` (or `27 − 1 = [26]`; the web's slip: "That is the area from 0 to 3. Take away F(1) = 1,
   the part from 0 to 1.").
Say: "F(2) is all the area from 0 to 2, and F(0) is 0." / "F(3) is all the area up to 3; taking away F(1) leaves 26."
**Core:** as the web (problems 1–3: n 1–2, a = (n + 1) × 1–2, k 1–3, j = 0; then n 1–3, k 2–4, a = (n + 1) × 1–3, j 1
to k − 1; the spec's check). The edge's readout is F where it stands.

## Open questions for G

1. **Algebra 2 topics that live here.** 11th grade's plan leaves the start of trig (radians, the unit circle, the
   sine wave, sin² + cos² = 1), the geometric series sum, Pascal's triangle and log rules to 12th grade (its open
   question 1). This plan now teaches them (5 of the new lessons). Keep them here, or move them down into 11th grade
   (ids kept, so saved progress still counts)? Either way there is one copy.
2. **Matrices.** Massachusetts' model Precalculus course teaches all of them (N-VM.6–12, A-REI.8–9), though many
   courses skip them, and Obento²'s Linear algebra track opens with the same four ideas, more deeply (b2-la-05 to 08).
   Keep the 4-lesson Matrices chapter in 12th grade (this plan's suggestion: the track then starts from it), or leave
   matrices to Obento²?
3. **Where calculus stops.** The web's 12th grade already reaches the chain rule. This plan adds the derivative from
   secants, hills and valleys, and area by strips, and stops there: no product or quotient rule, no derivatives of
   sin, eˣ or ln, no related rates or substitution. That's AP Calculus, for a later line. Is that the right place to
   stop?
4. **How much to build.** 42 lessons (13 web, 29 new). Build them all before 12th grade opens, or open with the web's
   13 in their chapters and add the rest as they're done?
