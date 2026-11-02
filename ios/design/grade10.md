# 10th grade on paper: every lesson's design

Claude (10th grade lesson planner), 1 Nov 2026, in the language of `README.md` and the example of `grade5.md`. Planning
only: nothing here is built yet, and each lesson still goes to G as a preview before Swift (`LESSONS.md` §9).
Reviewed 2 Nov 2026: chance trimmed to S-CP.1–8 (the rest is 11th grade's), the overlaps with 9th grade's tables and
completing the square named, small pictures made big, Exterior angle's hand move put first, and the trig wheel set on
the problem's own angle.

**The course is Geometry.** The web app names the grade "10th grade · Geometry" (`web/src/curriculum/grades/index.ts`),
and its 13 lessons are all geometry (`web/src/curriculum/lessons/grade10`, `specs/k12/grade10.md`, checks in
`web/src/curriculum/v2/grade10.ts`).
**Standards covered:** all of Common Core's high-school Geometry: G-CO.1–13, G-SRT.1–11, G-C.1–5, G-GPE.1–2 and 4–7,
G-GMD.1–4, G-MG.1–3; and the chance unit that Common Core's model Geometry course ends with (Appendix A, traditional
pathway): S-CP.1–8. (+) marks Common Core's extra standards for students heading to calculus. That unit's last three,
S-CP.9 (+) and S-MD.6–7 (+), already have their home in 11th grade's plan (`g11-perm`, `g11-comb`, `g11-fair`), so
they aren't repeated here. G-GPE.3 (+), ellipses and hyperbolas, is 12th grade's (`g12-ellipse`, `g12-hyperbola`).
**49 lessons in 13 chapters:** the 13 web lessons, each keeping its maths (generator, ranges, easy-first start, derived
values, slips, check recipe, the spec's 13 Oct fixes) and the beats of its animated picture, and 36 new ones
(`g10-<short>`). Five small gaps are folded into four web lessons as extra problem types, marked *fold*.

## Coverage

| Standard | What it asks | Lesson(s) | |
|---|---|---|---|
| G-CO.1 | exact meanings: angle, circle, perpendicular, parallel, segment | Copy a segment and an angle `g10-copy` (the compass draws "same distance"); Cut in half `g10-bisect` | new |
| G-CO.2 | moves as rules on points; which keep lengths and angles | Moves as rules `g10-rules` | new |
| G-CO.3 | the turns and flips that carry a shape onto itself | Onto itself `g10-symmetry` | new |
| G-CO.4 | what makes a slide, a flip, a turn | Find the mirror and the turn `g10-define` | new |
| G-CO.5 | draw the moved shape; moves in a row | `g10-rules` (two rules in a row); `g10-define` | new |
| G-CO.6 | congruent = moved onto it | Same parts, same triangle `g10-congruent` | new |
| G-CO.7 | congruent triangles: every matching part equal | `g10-congruent` (the matching part) | new |
| G-CO.8 | SSS, SAS, ASA from the moves | `g10-congruent` | new |
| G-CO.9 | vertical, alternate and corresponding angles; the middle line's equal distances | Parallel lines and proof `g10-angles`; `g10-bisect` | new |
| G-CO.10 | angle sum, isosceles base angles, the midsegment, medians meet | Exterior angle `g10-exterior` (its How to proves the angle sum); Angles in a polygon `g10-polygon`; Isosceles triangles `g10-isosceles`; A line parallel to a side `g10-splitter`; Where the medians meet `g10-centroid` | existing, new |
| G-CO.11 | parallelograms: sides, angles, diagonals; rectangles' diagonals | Inside a parallelogram `g10-parallelogram` | new |
| G-CO.12 | copy, bisect, perpendicular and parallel with compass and straightedge | `g10-copy`; `g10-bisect` | new |
| G-CO.13 | equilateral triangle, square, hexagon in a circle | Shapes in a circle `g10-inscribe` | new |
| G-SRT.1 | dilations: lines stay parallel, lengths × k | Stretch from any point `g10-dilate` | new |
| G-SRT.2 | similar = moved and stretched onto it | Similar or not? `g10-simtest`; `g10-dilate` | new |
| G-SRT.3 | the AA test | `g10-simtest` | new |
| G-SRT.4 | a line parallel to a side splits in proportion; Pythagoras by similarity | `g10-splitter`; The height to the long side `g10-altitude` | new |
| G-SRT.5 | congruence and similarity to solve and prove | Similar triangles `g10-similar`; `g10-altitude`; `g10-congruent` | existing, new |
| G-SRT.6 | side ratios belong to the angle: sin, cos, tan | Sine, cosine and tangent `g10-trig`; Special right triangles `g10-special` | existing |
| G-SRT.7 | sine and cosine of the two sharp angles | `g10-trig` + *fold*: cos of the other angle | existing |
| G-SRT.8 | right triangles in stories | Find a side with trig `g10-trigside`; Find an angle with trig `g10-trigangle`; `g10-special` | new, existing |
| G-SRT.9 (+) | area = ½ab sin C | Area from two sides and an angle `g10-trigarea` | new |
| G-SRT.10–11 (+) | laws of sines and cosines: why, and use | Law of sines `g10-sines`; Law of cosines `g10-cosines` | new |
| G-C.1 | all circles are similar | `g10-dilate` (its circle kind); Arc length `g10-arc` (the radian kind) | new, existing |
| G-C.2 | inscribed, central and outside angles; radius ⟂ tangent; chords | Inscribed angles `g10-inscribed`; Tangents and chords `g10-tangent` | new |
| G-C.3 | circles around and inside a triangle; a four-sided shape in a circle | Circles around and inside `g10-around`; `g10-inscribed` | new |
| G-C.4 (+) | the tangent from a point outside | `g10-tangent` (its last kind) | new |
| G-C.5 | arc length ∝ radius, the radian; sector area | `g10-arc` + *fold*: the arc in radii; Area of a sector `g10-sector` | existing |
| G-GPE.1 | the circle's equation by Pythagoras; complete the square | Equation of a circle `g10-circle` + *fold*: write it; Complete the square `g10-square` | existing, new |
| G-GPE.2 | a parabola from its focus and line | A point and a line `g10-parabola` | new |
| G-GPE.4 | prove with coordinates: is it a rectangle? is the point on the circle? | Prove it on the plane `g10-coordproof`; `g10-circle` + *fold*: on, in or out | new, existing |
| G-GPE.5 | parallel and perpendicular slopes; the line through a point | Perpendicular slopes `g10-perp`; Through a point `g10-perpline` | existing, new |
| G-GPE.6 | the point that splits a segment in a ratio | Midpoint `g10-mid`; Split a segment `g10-partition`; `g10-centroid` | existing, new |
| G-GPE.7 | perimeter and area from coordinates | Distance between points `g10-dist` + *fold*: any quadrant; Perimeter and area on the plane `g10-coordarea` | existing, new |
| G-GMD.1 | why: circle, cylinder, pyramid, cone (Cavalieri) | Volume of a pyramid `g10-pyramid`; Slanted stacks `g10-slant` (coins for the cylinder; a cone beside a pyramid); the circle's own arguments are 7th grade's (`g7-circum` unrolls, `g7-circarea` cuts wedges) | existing, new |
| G-GMD.2 (+) | the ball by Cavalieri | `g10-slant` (its last kind; a fourth-course standard, folded in because it's the same move) | new |
| G-GMD.3 | volume rules to solve problems | `g10-pyramid`; Solids put together `g10-solids`; `g10-slant` | existing, new |
| G-GMD.4 | slices of solids; solids made by spinning | Slice it, spin it `g10-slicespin` | new |
| G-MG.1 | shapes as models (a trunk is a cylinder) | `g10-solids`; Surface area of a box `g10-surface` | new, existing |
| G-MG.2 | density by area and by volume | `g10-coordarea` (people per square km); `g10-solids` (tonnes per cubic m) | new |
| G-MG.3 | design: the cheapest shape that works | `g10-surface` + *fold*: the box of 24 cubes that needs the least card | existing |
| S-CP.1 | events as cells of the outcomes: and, or, not (the cells left over) | And, or, not `g10-orand` | new |
| S-CP.2 | independent: P(A and B) = P(A) × P(B) | Independent or not? `g10-indep` | new |
| S-CP.3 | P(A given B) = P(A and B) ÷ P(B) | Chance when you know something `g10-given`; `g10-indep` | new |
| S-CP.4 | two-way tables: given, independent | `g10-given`; `g10-indep` | new |
| S-CP.5 | given and independent in everyday words | `g10-given`; `g10-indep` (stories) | new |
| S-CP.6 | given B: the share of B's outcomes in A | `g10-given` | new |
| S-CP.7 | P(A or B) = P(A) + P(B) − P(A and B) | `g10-orand` | new |
| S-CP.8 (+) | P(A and B) = P(A) × P(B given A) | One after the other `g10-tree` | new |
| S-CP.9 (+) | chance by counting picks | 11th grade's `g11-perm`, `g11-comb` (its chance *fold*) | 11th grade |
| S-MD.6–7 (+) | fair ways to decide; deciding with chance | 11th grade's `g11-fair` | 11th grade |

**Grade boundaries.** 8th grade (`grade8.md`) keeps one move at a time in coordinates and landing a shape by moves
(`g8-congruent`), dilations from (0, 0), "same angles, same shape" seen once, parallel-line angles with numbers, the
angle sum and the outside angle shown once, Pythagoras and its converse, distance by counting the legs (`g8-dist`), and
cylinders, cones and balls by pouring. 10th grade starts where each becomes a rule, a reason or a construction: moves
written as rules and defined by mirrors and centres, stretches from any point, the similarity tests, angle pairs with x
and their reasons, the outside angle with numbers, the distance formula. 7th grade keeps slices of boxes and pyramids
(`g7-slice`), nets and surface area of prisms (`g7-surface`), the circle's rules and vertical angles; 6th grade keeps
nets of boxes, so `g10-surface` keeps the formula's three pairs of faces. 9th grade keeps solving equations, simplifying
square roots (`g9-radical`, used by `g10-special`), the line through two points (`g9-twopoint`, used by
`g10-perpline`), factoring, completing the square for one letter with tiles (`g9-complete`; `g10-square` uses it on
x and y at once to find a circle) and the parts of a two-way table with its row percents (`g9-relfreq`; `g10-given`
starts where it ends, with the rule P(A and B) ÷ P(B) and dice). 8th grade's `g8-dist` already counts a distance with
the web's `g10-dist` maths (8th grade's open question 3); `g10-dist` here is the formula, with a fold for points in any
quadrant. 11th grade keeps counting with C(n, k) and chances by counting (`g11-perm`, `g11-comb`, S-CP.9), fair
choices and deciding with chance (`g11-fair`, S-MD.6–7), and the vertex form of a parabola (`g11-vertex`);
`g10-parabola` is only the focus-and-line picture. 12th grade keeps radians as a unit to convert
(`g12-rad`, `g12-deg`) and the unit circle (`g12-unit`): here the radian is only "the arc counted in radii" (Appendix A:
"radian introduced only as unit of measure"), and the trig wheel stops at 180°. Ellipses and hyperbolas (G-GPE.3, +)
are 12th grade's to plan. From 5th grade: the family of four-sided shapes (`g5-shapes`), reused by `g10-coordproof`.

## Chapters (teaching order)

New lessons are marked *.

| # | Chapter | Lessons |
|---|---|---|
| 1 | Compass and straightedge | Copy a segment and an angle* · Cut in half* · Shapes in a circle* |
| 2 | Moves | Moves as rules* · Find the mirror and the turn* · Onto itself* |
| 3 | Angles | Parallel lines and proof* · Exterior angle · Angles in a polygon |
| 4 | Congruent triangles | Same parts, same triangle* · Isosceles triangles* · Inside a parallelogram* |
| 5 | Similar shapes | Stretch from any point* · Similar or not?* · Similar triangles · A line parallel to a side* |
| 6 | Right triangles and trig | The height to the long side* · Special right triangles · Sine, cosine and tangent · Find a side with trig* · Find an angle with trig* |
| 7 | Any triangle (+) | Area from two sides and an angle* · Law of sines* · Law of cosines* |
| 8 | Points on the plane | Distance between points · Midpoint · Split a segment in a ratio* · Where the medians meet* |
| 9 | Lines and shapes on the plane | Perpendicular slopes · Through a point* · Perimeter and area on the plane* · Prove it on the plane* |
| 10 | Circles | Arc length · Area of a sector · Inscribed angles* · Tangents and chords* · Circles around and inside* |
| 11 | Circle and parabola equations | Equation of a circle · Complete the square* · A point and a line* |
| 12 | Solids (3D) | Surface area of a box · Volume of a pyramid · Slanted stacks* · Solids put together* · Slice it, spin it* |
| 13 | Chance | And, or, not* · Chance when you know something* · Independent or not?* · One after the other* |

The order is Common Core's model course (constructions and moves, then congruence, similarity and trig, coordinates,
circles, solids, chance). Inside a chapter each lesson needs only the ones before it; the web's own units ("Coordinate
geometry", "Angles and triangles", "Right triangles and trig", "Circles", "Area and volume") each sit inside one chapter.

## What every 10th grade lesson shares

As in 5th grade: instruction on rows 0–2 (28), a miss on rows 3–4 (20, red), the picture from row 6 with its names at
its right end, the record 3 rows under it (36, 2 squares a digit), Check / Next under the record. The iPad is about
68 × 45 squares; pictures stay near 60 × 30 at 100%, and a big one has the camera step back, never past what a child
can count. The first words never repeat the problem; the last line says why. Answers in the chapter colour; red and
green only for wrong and right. A step answered by a hand move sets its Core box from the move (`LessonRun.set`), so
Core's checks and slips stay; typing is only for the number school writes. Show me and the How to play each move with
the ghost finger and put everything back.

- **Shapes drawn in units** (a triangle's sides, a circle, off the plane) use k squares a unit, the most (1 to 5) that
  keeps the picture within about 60 × 36 squares, so a 5-5-6 triangle is 30 squares wide, not 6. Corners on crossings
  stay on crossings; the names keep the true lengths. "One square: 1" below means k = 1 when that already fills the
  screen, and k grows when it wouldn't.
- **The plane** is 8th grade's: one unit is one square, the axes on strong lines, numbered every 5 (or whatever G
  decides for 8th grade's open question 2). A point is a dot on a crossing, its name `(3, −2)` half a square off it.
- **Slanted and round things start on the grid** (7th grade's rule): corners, circle middles and compass points sit on
  crossings; slanted sides use 3-4-5 steps where their length matters, so it counts whole. Angles are drawn true to
  size and read on 7th grade's protractor drawn on the paper (a tick a degree, longer every 5°).
- **School's marks:** equal sides get matching ticks (one, two, three), equal angles matching arcs, parallel sides
  arrowheads (5th grade's), square corners the little square (5th grade's).
- **The compass and the straightedge** (chapter 1, and later wherever a construction comes back): drawn on the paper as
  tools; their arcs and lines are pencil grey. They don't snap to the grid; the grid then measures what they made,
  which is how the paper checks a construction.
- **Proof rows.** Where Common Core says *prove*, the record is a short proof: each line's statement is written from
  the child's own move, and its reason is chosen from three blocks (`Alternate angles`, `Given`, `SAS`); a wrong reason
  says, measured on the picture, why not. Statements are never typed.
- **The trig wheel** (chapters 6 and 7): a quarter circle of radius 25 squares (5 blocks are 1) with its middle on a
  crossing; its arm turns to whole degrees; the readout shows the tip's height and width (`35°: up 0.574 · across
  0.819`), drawn dashed to the floor so the grid shows them. It is the paper's calculator. It sits with its middle on
  the problem's angle and its floor along one side, so the problem's triangle lies inside it, along its arm: the wheel's
  triangle and the problem's are the same shape, one inside the other (the problem's drawn up to 24 squares long, one
  square 1, or 2 units a square beyond). For chapter 7 it opens to a half circle, so an obtuse angle reads too.
- **Solids** are Unit cubes: flat first, the paper tilts when the maths rises, words face the child, flat again before
  leaving. π is 3.14, as the web uses.
- **Typing** needs a minus key, a fraction as a box over a box (as Adding fractions), a root as a box beside √ (the
  web's `[5]√[2]`), degrees, and decimals to the tenth or hundredth.
- **Chance:** one outcome is one cell (two dice: 6 × 6 cells of 3 × 3 squares); in a two-way table one person is a
  2 × 2 cell in 9th grade's block of 100 (`g9-relfreq`), and a row's share is 8th grade's bar of 50 squares (a square
  is 2%). Marbles are solid, striped and open, as 7th grade's (its open question 1).

## Hand moves

**New in 10th grade** (each comes with the first lesson that uses it, after G sees its preview):

| Move | What the finger does; the live readout | Used by |
|---|---|---|
| Swing the compass | drag the pencil leg to open it (it snaps to a marked point, or lifts a width off a segment's two ends); drag round the point leg to draw an arc; `width AB` or `width 7` | copy, bisect, inscribe, congruent, around, tangent, circle |
| Lay the straightedge | drag a plain ruler until its edge passes through two marked points (it snaps to points and crossings of arcs), or meets a line at a square corner; draw along it; `through P and E` | copy, bisect, inscribe, define, polygon, parallelogram, dilate, altitude, trigarea, sines, centroid, tangent, around |
| Pin a crossing | tap where two drawn things cross (arc and arc, arc and line); a point is placed exactly there and named | copy, bisect, inscribe, dilate, around |
| Squeeze to the middle | drag one of two dots; the other comes toward it just as far; they meet halfway; `2 and 6 meet at 4` | mid, centroid |
| Slide the slices (3D) | drag the top of a stack sideways; each card slides a little more than the one under it, and the stack leans; `the same 8 cards` | slant |
| Spin about a line (3D) | drag a flat shape's handle round a line it lies against; it sweeps out a solid; `a whole turn: a cone` | slicespin |
| Cut a solid apart (3D) | `LESSONS.md`'s Cut, on a solid: drag along where its parts meet; they lift apart, each named | solids |

**From the other grades' plans** (not yet in `README.md`'s kit): Place a point on the plane (6th, 8th) · Lay a line
(8th) · Slide a shape (8th) · Flip over a line (8th) · Turn a shape (8th) · Stretch from a point (8th) · Raise a square
on a side (8th) · Pour (8th, 3D) · Turn a ray (7th) · Unroll (7th) · Slide the sheet (7th, 3D) · Choose (7th; 4th
grade's Tap a choice) · Fold on a line (4th, 3D) · Draw the step (8th grade's slope) · Drag a length, Cut along a line
and Turn the view (`LESSONS.md`). Reused from the kit: cut with the ruler (partition, tree), slide pieces (square,
exterior, polygon), tap pieces (surface, orand, given), drag a point along a line (bisect; inscribed, where the line is
the circle), hop (arc), drag a rectangle's corner (pyramid, sector, coordarea), build the layers (pyramid), write.

## 1. Compass and straightedge

The tools are the lesson here: a construction uses only the compass and the straightedge, and then the grid measures
it. Segments and angles start on crossings, so what the grid measures comes out whole. Nothing is typed until the
paper has measured.

### Copy a segment and an angle (`g10-copy`, new; G-CO.1, G-CO.12)
**One square:** 1. **Picture:** segment AB in the top half (10 to 25 squares: straight, or 3-4-5 steps such as 12
across and 16 up); under it a ray from P along a strong row, 40 squares long. Only the letters are named. Its **How to** opens with G-CO.1:
the compass swings a whole circle, and "every point is the same distance from the middle" is written under it.
1. **Swing the compass** with its point on A and its pencil on B: readout `width AB`. Lift it to P (the point snaps to
   P) and swing an arc across the ray; **pin the crossing**: Q. The pencil leg dragged while lifting: "The width
   changed. Open it to A and B again."
2. See: a bracket slides along each segment, counting squares: `AB = 20`, `PQ = 20`.
Angle (problems 4–6): an angle at A, one arm along a strong row, the other at its degrees; a ray from P.
1. **Swing** an arc from A across both arms; **pin** both crossings (B, C). With the same width, an arc from P across the
   ray; **pin** D. A different width: "That arc is 6 wide. The first was 8: keep the same width."
2. **Swing the compass** from B to C; from D, swing an arc that crosses the last one; **pin** E. Not crossing yet: "The
   arcs don't meet yet. Swing further."
3. **Lay the straightedge** through P and E and draw the arm. See: the protractor lies on both angles: `40°`, `40°`.
Parallel through a point (problems 7+): a line, a point P off it, a crossing line through P. **Copy the angle** the
crossing line makes with the line up to P (the same moves): the new line draws, and arrowheads appear on both.
Record, written from the moves (nothing typed, as 8th grade's `g8-congruent`): `PQ = AB`, `∠DPE = ∠BAC`, `m ∥ ℓ`.
Say: "Same width, same arcs: the copy is the same size." / "The same angle at both crossings, so the lines never meet."
**Core:** new. Segments 10–25 (straight, or 3-4-5 steps: 15, 20, 25); angles 35°–145° in 5s, arms 20 squares; the parallel's crossing line at
40°–80°. Problems 1–3 segments, 4–6 angles, 7+ parallels. A step is right when the pinned point is within half a square
of the true one. Check: a segment, two angles, a parallel.

### Cut in half (`g10-bisect`, new; G-CO.12, G-CO.9)
**One square:** 1. **Picture:** segment AB across the middle of the screen (30 squares along a strong row, or 24
across and 18 up, so its middle is a crossing), with room above and below for the arcs.
1. **Swing the compass** from A, wider than half: readout `width 18 · half of AB is 15`. Too narrow: "That's less than
   half of AB: the arcs won't meet." Arcs above and below.
2. The same width from B; **pin** both crossings of the arcs.
3. **Lay the straightedge** through them and draw: the new line crosses AB at M (pinned for the child).
4. See: brackets count `AM = 15`, `MB = 15`; the corner at M gets the square mark.
5. (G-CO.9) **Drag a point** P along the new line; dashed lines run from P to A and to B, both read live: `PA = 25 ·
   PB = 25` (P 20 squares from M). Off the line they part: `26.2 · 23.9`.
Angle (problems 4–6): an arc from the corner across both arms (**pin**), equal arcs from those two points (**pin** where
they cross), the straightedge from the corner through it. See: the protractor reads `35° | 35°`.
Perpendicular through a point (problems 7+): an arc from P cuts the line twice (**pin** A, B); cut AB in half as above;
the middle line passes through P.
Record: `AM = MB = [15]` (the one number school writes); `PA = PB` for every P on the line; for an angle, `[35]°` each.
Say: "Every point on the middle line is as far from A as from B." / "Equal arcs from both arms: the line cuts the angle
in half."
**Core:** new. Segments of even length 20–40 with the middle on a crossing (straight, or 3-4-5 steps with even legs:
12-16-20, 18-24-30); angles 40°–160° in 10s, arms 20 squares; P 6–15 squares off the line. Problems 1–3 segments, 4–6 angles, 7+ perpendiculars. Slip: arcs narrower than half. Check: a segment, an
angle, a perpendicular, and the drag of P.

### Shapes in a circle (`g10-inscribe`, new; G-CO.13)
**One square:** 1. **Picture:** a circle of radius 15 (12 or 18 in later problems), its middle O on a crossing, so it
fills the screen's height.
1. **Swing the compass** from O to the edge: `width = radius, 15`.
2. Put its point anywhere on the circle (it snaps to the circle) and swing an arc that cuts it; **pin**; step on from
   each new point; readout `3 steps`. The sixth arc lands on the first point exactly (a green dot). The width changed
   on the way: "Keep the width at the radius: 15."
3. **Lay the straightedge** from point to point: the hexagon draws. See: six triangles from O light, each with three
   sides of 15.
Equilateral triangle (problems 4–6): the same six points, joined every other one. Square (7+): a line through O, then
cut it in half at a square corner (`g10-bisect`'s moves); join the four ends.
Record: `360° ÷ 6 = [60]°` at O (`÷ 3 = [120]°`, `÷ 4 = [90]°`).
Say: "The radius steps round exactly 6 times, because each step makes a triangle with three equal sides."
**Core:** new. Radius 12, 15 or 18; the first point at a random place on the circle. Problems 1–3 hexagons, 4–6
triangles, 7+ squares. Check: one of each and a hexagon.

## 2. Moves (the plane; shapes' corners on crossings)

8th grade moved shapes one move at a time. Here a move is a rule on every point, defined by its mirror or its centre,
and some moves carry a shape onto itself.

### Moves as rules (`g10-rules`, new; G-CO.2, G-CO.5)
**One square:** 1 (the plane). **Picture:** triangle ABC (corners −8..8); the rule written once as the record's first
line, `(x, y) → (x + 4, y − 3)`.
1. **Place a point** for each corner's image: readout `(5, −1)`. Wrong: "A is (1, 2). x + 4 is 5 and y − 3 is −1."
   Each placed dot gets its name, A′; the image draws.
2. **Drag a length** along a side of each: `AB = 5 · A′B′ = 5` (a stretch: `AB = 5 · A′B′ = 7.2`); the protractor reads a
   corner on both.
3. **Choose** `Same size and shape` or `Changed`. Wrong: "AB is 5 and A′B′ is 7.2: it changed."
Two rules in a row (problems 7+): the first rule's image, then the second rule on it, `A → A′ → A″`.
Record: `A(1, 2) → A′([5], [−1])` (the other corners placed), then `keeps lengths and angles: yes`.
Say: "Slides, flips and turns keep every length: the shape only moves." / "× 2 on x stretches it sideways: lengths
change."
**Core:** new; builds on `g8-translate`, `g8-reflect`, `g8-rotate`, `g8-dilate`. Rules: slides (±1–6), flips over the
axes and y = x, quarter and half turns about (0, 0), stretches (2x, y), (x, 2y), (2x, 2y). Problems 1–3 slides and
flips; 4–6 turns and stretches; 7+ two rules in a row. Slips: the sign on the wrong part ("A quarter turn left: the new x
is minus the old y."); added for × ("× 2 doubles x: 2 × 3 is 6.").

### Find the mirror and the turn (`g10-define`, new; G-CO.4, G-CO.5)
**One square:** 1. **Picture:** two copies of a triangle on the plane, B made from A by one move nobody names.
1. **Lay the straightedge** from each corner to its copy (A to A′, B to B′): dashed joins; readout `AA′: 6 across, 2 up`.
2. **Choose** the move: `Slide` (every join parallel and as long), `Flip` (every join parallel, all cut in half by one
   line at square corners), `Turn` (joins not parallel). Wrong: "AA′ and BB′ aren't parallel: not a slide."
3. Find it. Slide: **write** `(x, y) → (x + [6], y + [2])`. Flip: **lay a line** (8th grade's) through the joins'
   middles: it locks when it cuts each one in half at a square corner; `cuts AA′ in half · square corner`. Turn: **place
   a point** for the centre; a dashed circle through each corner from it passes through its copy only at the right
   point (`OA = 5 · OA′ = 5`); then **turn a ray** from OA to OA′: `90°`.
4. See: the move plays: the shape slides, turns over, or turns round its centre onto its copy.
Record: `mirror: x = [2]`, or `turn [90]° about ([1], [2])`.
Say: "A flip's mirror cuts every join in half at a square corner." / "A turn moves every corner round its own circle,
all by the same angle."
**Core:** new. Slides ±1–6; flips over x = a, y = b (a, b −3..3), y = x, y = −x; turns of 90°, 180°, 270° about a
crossing −3..3. Problems 1–3 slides and flips over x = a, y = b; 4–6 turns about (0, 0); 7+ any, and from problem 10
two flips over parallel mirrors (together they make one slide, twice as far as the mirrors are apart).

### Onto itself (`g10-symmetry`, new; G-CO.3)
**One square:** 1. **Picture:** a shape drawn big (a rectangle, parallelogram, trapezoid with equal sides, rhombus,
square; a regular polygon on a circle of radius 12 around a crossing) with a see-through copy on top.
1. **Turn a shape** (8th grade's): drag the copy's handle round the middle; it snaps only where it fits exactly;
   readout `fits at 60°`; the fits are listed as they're found: `60°, 120°, 180°…` A parallelogram: `fits at 180°`.
2. **Fold on a line** (4th grade's, 3D): lay the straightedge through the middle and a corner or a side's middle, and
   fold the copy over it; it lands. Corners on corners get green dots; a miss is measured: "This corner lands 2
   squares from a corner." Fold on every mirror; **No more** when done ("There's another mirror.").
3. **Write** `turns: [6]`, `smallest turn: 360° ÷ 6 = [60]°`, `mirrors: [6]`.
Say: "A regular hexagon fits 6 ways by turning and 6 by folding." / "A parallelogram fits a half turn, but no fold."
**Core:** new; builds on `g4-symmetry` and `g8-rotate`. Problems 1–3 rectangles, trapezoids, parallelograms; 4–6
regular 3-, 5-, 6- and 8-sided shapes; 7+ any, with 10 and 12 sides. Slip: a parallelogram's diagonal folded as a
mirror (its corners miss, measured). Check: a rectangle, a parallelogram, a regular polygon, a trapezoid.

## 3. Angles (drawn true to size; the protractor reads them)

### Parallel lines and proof (`g10-angles`, new; G-CO.9)
**One square:** 1; angles true size. **Picture:** two parallel lines on strong rows 10 squares apart, 50 long, with
arrowheads; a crossing line at the problem's angle; two angles marked with their names, `3x + 10` and `5x − 30` (drawn
roughly until x is found, as 7th grade's `g7-angleeq`).
1. **Slide a shape** (8th grade's): slide one marked wedge along the crossing line to the other crossing, or **turn**
   it a half turn about its own crossing (8th grade's `g8-parallel`). It fits the other angle (equal), or sits beside
   it on a straight line; readout `fits: equal` or `straight line: 180°`.
2. **Choose** the reason: `Alternate angles`, `Corresponding angles`, `Vertical angles`, `Same side: 180°`. Wrong:
   "They sit on the same side of the crossing line, between the lines: they add to 180°."
3. **Write** `3x + 10 = 5x − 30`, `40 = 2x`, `x = [20]`; then the angle, `3 × 20 + 10 = [70]°`. See: both wedges turn to
   their true 70°, and the protractor reads them.
Proofs (problems 7+): the record is three lines whose statements are written from the moves, and the child chooses each
reason. Vertical angles: `∠1 + ∠2 = 180°` (straight line), `∠2 + ∠3 = 180°` (straight line), `∠1 = ∠3` (take ∠2 from
both). The move first: **turn** the crossing line, and ∠1 and ∠3 change together.
Say: "Slid along the crossing line, the angle fits: alternate angles are equal, so 3x + 10 = 5x − 30."
**Core:** new; builds on `g8-parallel` and `g8-both`. Angles 30°–150° in 5s (not 90); names px + q with p 1–6 and x a
whole 5–40; pairs corresponding, alternate (inside or outside), vertical, same side. Problems 1–3 equal pairs, x on one
side; 4–6 x on both sides and the 180° pairs; 7+ proofs. Slips: set equal when they make 180° ("Those two make a straight
line: add them to 180°."); x given as the angle ("x is 20. The angle is 3 × 20 + 10."). Check: an equal pair, a 180°
pair, x on both sides, a proof.

### Exterior angle (`g10-exterior`, existing; G-CO.10)
**One square:** 1; angles true size. **Picture:** the web's (`triangle-angles`), on the paper, big: the triangle on a
base of 30 to 45 squares along a strong row (the longest that keeps it under 30 squares tall; a narrow top makes a
tall triangle, so its base is shorter), its left corner `50°`, its top `60°`, the protractor's ticks round each corner;
the base runs on past the right corner, dashed, 15 squares, making the outside angle `?`. Each corner's angle is a
wedge that can be lifted. The web's beats stay, in the order the hands find them: the outside angle filled by the far
corners, then the third corner's arc, then the straight line.
1. **Slide pieces**: slide the two far corners' wedges (50° and 60°) into the outside angle; each turns as it goes and
   snaps in; together they fill it exactly, and the protractor reads `110°`. Readout `50° + 60° = 110°` (this is the
   web's "Check with the far angles" step, which the spec keeps because it is the idea). Dropping the 70° wedge:
   "That's the corner next to it. Use the two far corners."
2. **Tap** the third corner: its 70° wedge lights where it sits, right beside the 110°; together they fill the straight
   line's half circle, `70° + 110° = 180°`.
3. **Write** the record: `180° − 50° − 60° = [70]°` (the web's slip: "Take both known angles off 180°."), `180° − 70° =
   [110]°` (slips: "The outside angle is the other part of the straight line."; "Use the inside angle next to it:
   70°."), and `50° + 60° = 110°`, written by the paper from step 1.
Its **How to** proves the angle sum (G-CO.10), with `g10-angles`' move: a line through the top corner, parallel to the
base (arrowheads); the two base corners' wedges slide up the sides to it (alternate angles) and sit either side of the
top corner: three wedges, one straight line, 180°.
Say: "The two far corners fill the outside angle: 50° + 60° = 110°."
**Core:** as the web (a and b 20–80; smallest-of-six start; the spec's idea line; the check keeps a + b ≠ 90 and
2a + b ≠ 180). The record's three boxes are the web's three steps; step 1's move sets the check box.

### Angles in a polygon (`g10-polygon`, existing; G-CO.10)
**One square:** 1. **Picture:** the regular polygon on a circle of radius 15 around a crossing, its first corner at the
top, named `6 sides`. The web's beats stay (`polygon-split`): the triangles pop in one by one and number, then the inside
angle at the bottom corner draws its arc and degrees.
1. **Lay the straightedge** from the top corner to each corner it can reach: each new line cuts off a triangle, which
   shades and numbers; readout `4 triangles`. A neighbour: "That's a side already." From 12 sides, after three lines the
   rest draw themselves. Answers `6 − 2 = 4` (the web's slip: "From one corner, the two sides next to it don't make
   triangles of their own: it's sides − 2.").
2. **Slide pieces**: one triangle's three corners slide into a half circle: `180°`. **Write** `4 × 180° = [720]°` (slip:
   "It's 6 − 2 triangles, not 6.").
3. **Write** `720° ÷ 6 = [120]°` (slip: "Share the total among the 6 corners, not the 4 triangles."). See: the protractor
   at the bottom corner reads 120°.
Say: "6 sides make 4 triangles from one corner, and each triangle holds 180°."
**Core:** as the web (n from 5, 6, 8, 9, 10, 12, 15, 18, 20; smallest-of-six start; check: n ≤ 6, 8–10, ≥ 12, ≥ 15).

## 4. Congruent triangles

Triangles are drawn true to size, k squares a unit (What every lesson shares), so two side by side fill the screen:
a 5-5-6 is drawn 5 squares a unit (30 wide), a 13-14-15 two (28 wide). Those given by three sides use whole-sided
triangles with every corner on a crossing (3-4-5, 6-8-10, 5-12-13, 5-5-6, 5-5-8, 10-10-12, 13-13-24, 13-14-15,
10-17-21); those given angles have whole degrees, their first side on a strong row, and their third corner lands where
the construction puts it, on a crossing or not.

### Same parts, same triangle (`g10-congruent`, new; G-CO.6, G-CO.7, G-CO.8)
**One square:** 1. **Picture:** triangle ABC on the left, its parts marked (ticks and lengths, arcs and degrees); on the
right, the parts given for a second triangle lie loose: a stick for each side, a wedge for each angle.
1. **Build it**: lay the first stick on a strong row; at its ends **turn a ray** to a given angle (it snaps to its
   degrees) or **swing the compass** as long as a given side (as 7th grade's `g7-triangle`). Every part is used. Readout
   `closes: one triangle`. Two sides and an angle not between them: the arc crosses the ray twice, `two places: two
   triangles`, and both draw. Three angles: a second, bigger triangle draws with the same angles.
2. **Slide**, **flip** and **turn** (8th grade's) the built triangle onto ABC: it fits exactly (G-CO.6). It locks.
3. **Choose** `SSS`, `SAS`, `ASA`, `AAS` or `Not enough`. Wrong: "The angle isn't between the two sides: it closed in two
   places."
4. **Write** a matching part (G-CO.7): `DF = AC = [7]`, or `∠F = ∠C = [65]°`. Wrong part: "DF matches AC: both are
   across from the 40° angle."
Say: "Two sides and the angle between them fix the triangle: there's only one, so it fits." / "Three angles fix the
shape, not the size."
**Core:** new; builds on `g7-triangle` and `g8-congruent`. SSS and SAS from the whole-sided list; ASA and AAS with angles
30°–110° and a side 6–15 (lengths read to the tenth); not enough: SSA with two triangles, AAA. Problems 1–3 SSS and SAS;
4–6 ASA, AAS and one not enough; 7+ any, with the matching part asked. Check: one of each yes kind and one not enough.

### Isosceles triangles (`g10-isosceles`, new; G-CO.10) — 3D fold
**One square:** k squares a unit, the base 30 to 50 squares. **Picture:** an isosceles triangle, its base on a strong
row and its top corner over the base's middle; the equal sides ticked; the top angle or a base angle given, and the
triangle drawn true to it (the top corner where that angle puts it). The equal-sides problems (4–6) use whole-sided
ones with the top on a crossing (5-5-6, 5-5-8, 10-10-12, 13-13-10, 13-13-24, 17-17-16).
1. **Fold on a line** (4th grade's, 3D): lay the straightedge from the top corner to the base's middle and fold. The
   paper tilts a little; the left half lifts and lands on the right: the equal sides meet, and the base angles land on
   each other (green dots); flat again. A fold line off the middle: "The halves miss by 2 squares."
2. **Write** `(180° − 40°) ÷ 2 = [70]°` (top given), or `180° − 2 × 65° = [50]°` (base given).
Equal angles to equal sides (problems 4–6): two equal angles are marked; **tap** the two sides that must be equal; the
fold proves it.
Algebra (problems 7+): base angles `2x + 15` and `3x − 5`: `2x + 15 = 3x − 5`, `x = [20]`, each angle `[55]°`.
Say: "Folded down the middle, one half lands on the other: the base angles are equal."
**Core:** new; builds on `g8-tri`. Top angle 20°–140° in even steps (base angles whole); base angle 25°–85°; x a whole
5–30. Problems 1–3 top given; 4–6 base given and equal angles to equal sides; 7+ algebra. Slips: 180° − 40° not halved
("The two base angles share 140°: half each."); one base angle taken off 180° ("Both base angles come off: 180° − 2 ×
65°."). Check: top given, base given, equal sides, algebra.

### Inside a parallelogram (`g10-parallelogram`, new; G-CO.11)
**One square:** 3 squares a unit (2 for bases over 14), so it spans about 50–60 squares. **Picture:**
parallelogram ABCD drawn true to the answer, corners on crossings: in units (0, 0), (14, 0), (20, 8), (6, 8), a base of
14 and slanted sides of 10 (6 across, 8 up), 60 × 24 squares; its sides or diagonals named with numbers or with x. In
the angle problems the slanted sides lean at the given angle instead (the top corners off the crossings).
1. **Lay the straightedge** along a diagonal and **cut** along it (`LESSONS.md`'s Cut): the two triangles part a square.
   **Turn a shape** (8th grade's) a half turn about the diagonal's middle: one triangle lands on the other exactly.
   See: matching ticks and arcs draw on opposite sides and angles; readout `half turn: fits`.
2. Then, by kind. Sides: `3x + 2 = 5x − 6`, `x = [4]`, `AB = [14]`. Angles: **slide** ∠A's wedge along a side to the
   next corner: they make a straight line; `∠B = 180° − 70° = [110]°`, `∠C = [70]°`. Diagonals: both drawn; the half turn
   about their crossing E swaps A and C; `2y + 1 = 3y − 4`, `y = [5]`.
Rectangles (problems 10+): diagonals `2x + 6` and `4x − 2`: `x = [4]`, both 14: equal diagonals, so the corners take
their square marks.
Say: "A half turn about the middle lands it on itself: opposite sides and angles match, and the diagonals cut each other
in half."
**Core:** new; builds on `g10-angles` and `g8-both`. Bases 8–16, slanted sides from 3-4-5 steps; x a whole 2–10; angles
40°–140° in 5s. Problems 1–3 sides; 4–6 angles and diagonals; 7–9 any; 10+ rectangles. Slips: next-door sides set
equal ("Opposite sides are equal: AB and DC."); opposite angles added to 180° ("Opposite angles are equal; next-door
angles add to 180°.").

## 5. Similar shapes

### Stretch from any point (`g10-dilate`, new; G-SRT.1, G-C.1)
**One square:** 1. **Picture:** a centre O (a dot on a crossing, not (0, 0)) and a triangle, with dashed rays from O
through each corner; named `× 2 from O`.
1. **Stretch from a point** (8th grade's): drag a corner along its ray; every corner follows; it snaps at × ½, × 1,
   × 3/2, × 2 and × 3; readout `× 2`. Wrong: "That's × 3: every corner is 3 times as far from O."
2. See (G-SRT.1a): each side and its image get arrowheads, parallel; a side whose line runs through O stays on its own
   line (drawn darker: `through O: the same line`).
3. **Drag a length** along a side and its image: `4 → 8` (G-SRT.1b); **write** `A′B′ = 2 × 4 = [8]`. See: four copies
   of the small triangle fill the big one, so the area is × 4.
Find it (problems 7–9): a triangle and its image; **lay the straightedge** through A and A′, then B and B′; **pin the
crossing**: O. **Write** `k = 12 ÷ 4 = [3]`.
Circles (problems 10+, G-C.1): circle A of radius 3 and circle B of radius 6 elsewhere. **Slide** A's middle onto B's,
then **stretch** from the middle: it lands on B exactly; **write** `× [2]`.
Say: "Every corner twice as far from O: every side twice as long, and still parallel." / "Any circle slides and
stretches onto any other: all circles are similar."
**Core:** new; builds on `g8-dilate`. O anywhere −6..6; corners 3–6 squares from O for × 3, 4–10 for × 2, even 6–20
for × ½ and × 3/2, so the bigger triangle is 20–30 squares across; k from 2, 3, ½, 3/2. Problems 1–3 × 2 and × 3; 4–6 × ½ and × 3/2; 7–9 find O and k; 10+ circles. Slips: added (`A′` 2 squares further,
not twice as far: "× 2 is twice as far from O."); measured from (0, 0) ("Stretch from O, not from (0, 0).").

### Similar or not? (`g10-simtest`, new; G-SRT.2, G-SRT.3)
**One square:** 1. **Picture:** two triangles, the second turned or flipped and a different size; given two angles each
(`40°, 75°`), or three sides each (`6, 8, 10` and `9, 12, 15`), or two sides and the angle between.
1. **Turn** or **flip** (8th grade's) the small triangle so it faces the same way; matching corners take the same letters.
2. **Stretch from a point** at a corner until one side matches: readout `× 1.5`. The rest fits exactly (similar), or a gap
   shows, measured: "This side reaches 9; that one is 10."
3. **Choose** `Similar: AA`, `Similar: SSS`, `Similar: SAS`, or `Not similar`.
4. **Write** the proof's number: `9/6 = 12/8 = 15/10 = [1.5]`, or the third angle, `180° − 40° − 75° = [65]°`.
Say: "Two angles match, so the third does too: one triangle is a stretched copy of the other."
**Core:** new; builds on `g8-aa` and `g10-dilate`. Triangles from the whole-sided list scaled × 1.5, × 2, × 2.5, × 3; a
third of problems not similar (a side 1–2 off, or an angle 5°–15° off). Problems 1–3 AA; 4–6 SSS; 7+ SAS and any. Slips:
ratios of unmatched sides ("Match shortest to shortest: 6 with 9."); one ratio only ("All three sides must stretch by
1.5.").

### Similar triangles (`g10-similar`, existing; G-SRT.5)
**One square:** 1 (one square is 2 when the big triangle would be over 40 squares; the names keep the true lengths).
**Picture:** the web's (`similar`), on the paper: the small right triangle, legs `4` up and `6` across, and beside it
the big one, its matching side `8`, the other `?`. The web's beats stay: the big triangle draws after the small, then
"× 2 everywhere", then `?` becomes 12.
1. **Stretch from a point** (8th grade's) at the small triangle's square corner: it grows and snaps at × 1.5, × 2,
   × 2.5, × 3 and × 4; when its 4 side reaches 8 it locks; readout `4 → 8: × 2` (sets `8 ÷ 4 = 2`). Past it: "At × 3 the
   side is 12: past 8."
2. The stretched copy slides onto the big triangle and fits; its 6 side counts along the bottom, `6 × 2`.
3. **Write** `6 × 2 = [12]` (the web's slip: "Similar shapes scale by multiplying.").
Say: "Every side is 2 times as long, so 6 becomes 12."
**Core:** as the web (a and b even 4–16, a ≠ b; k from 2, 3, 4, 1.5, 2.5; smallest-of-six start; check: k 1.5 or 2.5
twice, k ≥ 3, any). The spec's new `pre`, `g7-scale`. The factor's slip ("Big ÷ small, so the factor is more than 1.")
shows when the stretch is dragged inward.

### A line parallel to a side (`g10-splitter`, new; G-SRT.4, G-CO.10)
**One square:** k squares a unit (2 or 3), the triangle about 40 squares tall. **Picture:** triangle ABC, A at the
top, its base BC on a strong row and every corner on a crossing; a line parallel to the base, with arrowheads, cuts
the other sides at D and E; named `AD = 6`, `DB = 4`, `AE = 9`, `EC = ?`.
The midsegment first (problems 1–3, G-CO.10): **drag** the cutting line's handle; it stays parallel and snaps at
crossings; readout of both splits, `AD : DB = 1 : 1`, at the middles. See: the base's squares count 12 and DE's 6.
**Write** `DE = 12 ÷ 2 = [6]`.
1. **Drag** the cutting line: both sides' splits read live, `6 : 4 | 9 : 6`, and stay in the same ratio as it moves.
2. **Stretch from a point** at A: triangle ADE stretches onto ABC (× 10/6 on both sides at once).
3. **Write** `6/4 = 9/x`, `x = [6]`.
Not parallel? (problems 7+): D and E are given; **choose** `Parallel` or `Not parallel` from the ratios, `6/4 = 1.5`,
`9/5 = 1.8`: not parallel, and the line visibly tilts.
Say: "A line parallel to the base cuts both sides in the same ratio: 6 to 4, and 9 to 6."
**Core:** new; builds on `g10-similar` and `g10-mid`. Ratios 1 : 1, 1 : 2, 2 : 1, 2 : 3, 3 : 2, 3 : 4, with D and E on
crossings. Problems 1–3 midsegments; 4–6 the missing piece; 7+ the whole side asked, and not parallel. Slips: a whole
side for a piece ("AD : DB uses the two pieces, 6 and 4, not the whole 10."); the ratio turned over.

## 6. Right triangles and trig

### The height to the long side (`g10-altitude`, new; G-SRT.4, G-SRT.5)
**One square:** k squares a unit, so the long side is 40–60 squares (2 for this one). **Picture:** a right triangle on
its long side, along a strong row from (0, 0) to (25, 0) in units (50 squares), its square corner at (9, 12) (24
squares up); the long side named `25`, the two parts it will split into `9` and `16`.
1. **Lay the straightedge** from the square corner down to the long side; it snaps where it meets at a square corner;
   **cut** along it: the two pieces part a square.
2. **Flip** and **turn** (8th grade's) the small piece, then **stretch** it from its square corner: it lands exactly on
   the middle piece. Readout `9 by 12 · 12 by 16`: the same shape.
3. **Write** `9/h = h/16`, `h² = 9 × 16 = [144]`, `h = [12]`.
A leg (problems 4–6): `a² = 9 × 25 = [225]`, `a = [15]` (the leg and its part are a big and small side of the same
shape). Pythagoras (problems 7+; it is also the **How to**): `a² + b² = 9 × 25 + 16 × 25 = (9 + 16) × 25 = [625]`, which
is 25².
Say: "The height cuts the right triangle into two smaller copies of itself, so 9 is to 12 as 12 is to 16."
**Core:** new; builds on `g10-similar` and `g8-pyth`. Parts p and q with p × q a square number: (1, 4), (1, 9), (2, 8),
(4, 9), (1, 16), (3, 12), (4, 16), (9, 16), (2, 18), (5, 20), (8, 18); legs asked only when whole. Problems 1–3 the
height; 4–6 a leg; 7+ the Pythagoras line and any. Slips: the parts' average ("Halfway is (9 + 16) ÷ 2. The height is the
number that times itself makes 9 × 16."); added the parts.

### Special right triangles (`g10-special`, existing; G-SRT.6, G-SRT.8)
**One square:** k squares a unit, the most that keeps the triangle and its squares on screen (5 for a short leg of 2,
1 for 12), so the legs are 10–30 squares. **Picture:** the web's (`right-triangle`), on the paper: the
right triangle with its square corner on a crossing, legs along grid lines, `45°` and `45°`, leg `5`, the long side `?`
(30-60-90: `30°`, `60°`, short leg `5`, drawn true: the long leg is √3 times the short one). The web's beats stay: the
long side lights with its answer, then (30-60-90) the long leg.
45-45-90: 1. **Flip over a line** (8th grade's): flip the triangle over its long side: with its copy it makes a 5 × 5
square, the long side its diagonal. 2. **Raise a square on a side** (8th grade's) on each leg and on the long side.
The long side's square is tilted, so it isn't counted in squares: it is counted in copies of the triangle. Each leg's
square cuts along its diagonal into 2 copies (readout `2 + 2`); the 4 copies slide into the long side's square and
fill it exactly: `4 halves of 25 = 2 × 25`. 3. **Write** `[5]√[2]` (the web's slips: "Doubling is for the 30-60-90
hypotenuse. These legs are equal, so use √2."; "√3 belongs to 30-60-90.").
30-60-90: 1. **Flip** over the long leg: with its copy it makes an equilateral triangle, every side ticked; **write**
`2 × 5 = [10]` (slip: "The short leg is half a side of the equilateral triangle."). 2. **Raise a square** on the long
side and on the short leg; they lift off and lie square on the grid beside the triangle, so they count: the 10 × 10 is
4 blocks of 5 × 5, and the short leg's 5 × 5 covers one of them: 3 left, `3 × 25 = 75`, the long leg's square.
3. **Write** `[5]√[3]` (slips: "√2 is for 45-45-90 triangles."; "Use the short leg, not the hypotenuse: 5√3.").
Say: "Half a square: the long side is a leg times √2." / "Half an equilateral triangle: the long side is twice the short
leg."
**Core:** as the web (45 or 30 half the time; s 2–12; smallest-of-six start; check: 45, 30, 45 with s ≥ 7, 30 with
s ≥ 7).

### Sine, cosine and tangent (`g10-trig`, existing; G-SRT.6, G-SRT.7)
**One square:** k squares a unit, so the long side is 20–30 squares (5 for 3-4-5, 2 for 5-12-13, 1 for 7-24-25).
**Picture:** the web's (`right-triangle`), on the paper: the right triangle from the web's
triples, angle A at a crossing, the sides named only by their lengths. The web's beats stay: the top side lights, then
the bottom side, then the ratio.
1. **Tap** the side across from A, then the side next to A (not the long one): each lights and takes its name along it,
   `opposite`, `adjacent`, `hypotenuse`. Wrong: "That one touches A. Opposite is across from A."
2. **Tap** the side that goes on top of `sin A`, then the one on the bottom: each moves into the record's box as its
   length (the web's top and bottom steps, with the spec's question fix; their slips: "Opposite is across from the
   angle…", "The bottom of the ratio is a different side from the top.", "Sine and cosine go over the hypotenuse.",
   "Tangent doesn't use the hypotenuse.").
3. **Write** `sin A = 3/5`, in lowest terms (the web's slip: "Upside down").
4. See (G-SRT.6, the idea): **stretch** the triangle from A, × 2 and × 3; the ratio's readout stays `3/5 = 6/10 = 9/15`;
   the trig wheel beside it turns to A: `sin 37° ≈ 0.6`.
*Fold* (G-SRT.7; from problem 7, one in three): the question is `cos B`, the other sharp angle. The taps from B rename
the legs; See: the side across from A is next to B, so `sin A = cos B = 3/5`.
Say: "sin A is the side across from A over the long side: 3/5, whatever the triangle's size." / "The side across from A
is beside B, so sin A is cos B."
**Core:** as the web (a triple from TRIPLES, f any, legs swapped half the time; smallest-of-six start; the spec's
question and note fix; check: sin, cos, tan, a ratio that simplifies). New: the cos B / sin B type, with its slip ("From
B, opposite and adjacent swap.").

### Find a side with trig (`g10-trigside`, new; G-SRT.8)
**One square:** 1 for the triangle (2 units a square when a side is over 24); 25 squares are 1 on the wheel.
**Picture:** the trig wheel with its middle on A; the right triangle drawn true inside it: angle `35°` at A, the bottom
side along the wheel's floor, the long side along its arm, named `12`, the wanted side `x`.
1. **Tap** the two sides that matter, the one you know and the one you want: they name themselves (`opposite x`,
   `hypotenuse 12`), and the record chooses `sin`. Wrong pair: "x is next to A, not across: that's cos."
2. **Turn a ray** on the wheel to 35°: the arm lies along the long side; readout `sin 35° = 0.574`; the tip's height
   draws dashed (14.3 squares of 25).
3. **Stretch from a point** (8th grade's) at A: the wheel's triangle (long side 1) shrinks along the arm until its long
   side is the problem's 12; readout `× 12: height 12 × 0.574`. The two triangles are one shape, one inside the other.
4. **Write** `x = 12 × sin 35° = 12 × 0.574 = [6.9]`. x on the bottom (problems 4–6): `cos 35° = 8/x`,
   `x = 8 ÷ 0.819 = [9.8]`.
Stories (problems 7+): a 6 m ladder at 70° to the ground; a kite on a 40 m string at 35°; a tree's top seen at 40° from
30 m away; the story's picture is the triangle, its numbers its names.
Say: "sin 35° is the height of a 1-long arm at 35°: 12 times as long, 12 times as high."
**Core:** new; builds on `g10-trig`. Angles 20°–70°, sides 5–40; answers to the tenth (checked to the tenth). Problems
1–3 x on top (multiply); 4–6 x on the bottom (divide); 7+ stories. Slips: the wrong ratio ("x is across from 35°: sin,
not cos."); multiplied when x is on the bottom ("x is on the bottom: 8 ÷ 0.819."). Check: top, bottom, a story, any.

### Find an angle with trig (`g10-trigangle`, new; G-SRT.8)
**One square:** half a unit for the triangle (2 squares a unit) while its long side stays inside the wheel (under
12.5), otherwise 1, so it fills the wheel; 25 squares are 1 on the wheel. **Picture:** the trig wheel with its middle on A; inside it a right triangle with its legs on grid lines,
`10` across and `7` up (20 and 14 squares), angle A `?`.
1. **Tap** the two known sides: `opposite 7`, `adjacent 10`; the record chooses `tan`.
2. **Write** `tan A = 7/10 = [0.7]`.
3. **Turn a ray** on the wheel: the readout runs `tan 30° = 0.577 … tan 35° = 0.700`; stop where it matches. See: the
   arm runs along the long side, through the top corner. Stopped early: "tan 34° is 0.675. Turn on to 0.7."
4. **Write** `A = tan⁻¹ 0.7 ≈ [35]°`.
Say: "The angle whose arm climbs 7 for every 10 across: about 35°."
**Core:** new; builds on `g10-trigside`. Legs 3–12 for tan; a leg and the long side (ratio 0.2–0.95) for sin and cos;
answers to the nearest degree. Problems 1–3 tan; 4–6 sin and cos; 7+ stories (a ramp rising 1 in 12, the sun from a
shadow). Slips: the ratio upside down ("tan is across over beside: 7/10, not 10/7."); the other sharp angle ("That's the
angle at B, 55°. A is on the left.").

## 7. Any triangle (+)

Common Core's extras for students heading to calculus. The triangles have no square corner; the trig wheel opens to a
half circle so an obtuse angle reads too (sin 130° is the same height as sin 50°; cos 130° reaches left, so it's
negative).

### Area from two sides and an angle (`g10-trigarea`, new; G-SRT.9 +)
**One square:** 1 (2 squares a unit when both sides are 12 or less), the triangle inside the half wheel. **Picture:**
the half wheel with its middle on C; a triangle with sides `8` and `10` meeting at C, `40°`: the 10 side along the
wheel's floor (a strong row), the 8 side along its arm.
1. **Lay the straightedge** from the far corner straight down to the 10 side; it snaps at a square corner; the height h
   draws and is named.
2. **Turn a ray** on the wheel to 40°: `sin 40° = 0.643`, the arm's tip that high; **stretch** the wheel's triangle
   from C until its long side is the 8 side: readout `× 8: h = 8 × 0.643 = 5.14`.
3. **Write** `h = 8 × sin 40° = [5.14]`, `area = ½ × 10 × 5.14 = [25.7]`; then the rule as record, `area = ½ab sin C`.
Obtuse (problems 7+): the height falls outside, onto the side run on (dashed); the wheel shows sin 130° = sin 50°.
Say: "The height is 8 × sin 40°, so the area is half of 10 × 8 × sin 40°."
**Core:** new (+); builds on `g10-trigside` and `g6-tri`. Sides 4–20, C 20°–150°; answers to the tenth. Problems 1–3
sharp C; 4–6 any; 7+ obtuse. Slips: the ½ left out ("A triangle is half its rectangle: ½ × 10 × h."); cos for sin.

### Law of sines (`g10-sines`, new; G-SRT.10–11 +)
**One square:** 2 squares a unit when the triangle fits 60 × 30 that way, otherwise 1. **Picture:** triangle ABC drawn
true, AB along a strong row, `A = 35°`, `B = 70°`, `b = 10`, the side `a` asked.
1. **Lay the straightedge** from C down to AB at a square corner: the height h.
2. The wheel sits on A: **turn a ray** to 35° and **stretch** its triangle along b: `h = 10 × sin 35° = 5.74`. The wheel
   moves to B, facing the other way: 70°, along a: `h = a × sin 70°`. One height, two ways: the record writes `a × sin 70° = 10 × sin 35°`, then the rule,
   `a ÷ sin A = b ÷ sin B`.
3. **Write** `a = 10 × sin 35° ÷ sin 70° = [6.1]`.
Two angles and the side between (problems 4–6): the third angle first, `180° − 35° − 70°`. An angle from two sides and an
angle not between them (problems 7+): `sin B = b × sin A ÷ a`, then turn the wheel to match; from problem 10 the swinging
side lands twice (`g10-congruent`'s two triangles) and both answers are asked.
Say: "Both ways give the same height, so each side over the sine of the angle across from it is the same."
**Core:** new (+). Angles 25°–120° (adding to less than 180°), sides 5–30; answers to the tenth or the degree. Problems 1–3
two angles and a side across from one; 4–6 the side between; 7–9 an angle; 10+ the two-triangle case. Slips: a side
paired with the wrong angle ("a goes with the angle across from it, A."); sides divided without the sines.

### Law of cosines (`g10-cosines`, new; G-SRT.10–11 +)
**One square:** 1. **Picture:** a triangle drawn true: two sides `8` and `10` and the angle between, `50°`, the 10
side along a strong row; the third side `c`.
1. **Raise a square on a side** (8th grade's) on all three sides; the 10 side's square counts on the grid, the others
   read their areas. **Pour** (8th grade's) the two smaller squares' sand into c's square: `64 + 100 = 164`, but c's
   square holds `61.1`: `102.9 left over`. (At 90° they fit exactly: Pythagoras; past 90° they fall short.)
2. **Turn a ray** on the wheel to 50°: `cos 50° = 0.643`; readout `2 × 8 × 10 × 0.643 = 102.9`, the same amount.
3. **Write** `c² = 8² + 10² − 2 × 8 × 10 × cos 50° = [61.1]`, `c = [7.8]` (checked with the wheel's 0.643, so 61.1;
   61.2 from the exact cosine is also right).
Obtuse (problems 4–6): cos is negative, so the gap is added. Three sides (problems 7+): `cos C = (25 + 64 − 49) ÷ 80 =
[0.5]`; turn the wheel until the readout matches: `C = [60]°`.
Say: "Pythagoras, corrected for the angle: a sharp angle takes 2ab cos C away."
**Core:** new (+). Sides 3–20, C 20°–150°; three sides that make a triangle; answers to the tenth or the degree.
Problems 1–3 sharp; 4–6 obtuse; 7+ three sides. Slips: the 2 left out of 2ab; added for a sharp angle; the square root
taken before taking away.

## 8. Points on the plane (one unit is one square)

### Distance between points (`g10-dist`, existing; G-GPE.7)
**One square:** 1. **Picture:** the web's (`plane`), on the paper: the two points, `(1, 2)` and `(4, 6)`. The web's beats
stay: across dashed, up dashed, the square corner, then the long side drawing slowly. 8th grade counted the legs
(`g8-dist`); here each leg is a subtraction, and the record ends with the formula.
1. **Drag a length** from the first point straight across to under the second: readout `x: 1 → 4: 4 − 1 = 3` (sets the
   web's step; slip: "Distance across is the difference: subtract."). Then up: `y: 2 → 6: 6 − 2 = 4`.
2. **Raise a square on a side** (8th grade's) on each leg: `9`, `16`; they pour into the long side's square and fill it
   (sets `3² + 4² = 25`; slips: "Squared means a number times itself."; "Square each one first.").
3. **Write** `d = √25 = [5]` (slip: "The straight line is shorter than going across and up."); then the rule as record,
   `d = √((x₂ − x₁)² + (y₂ − y₁)²)`.
*Fold*, any quadrant (from problem 7, one in three): the first point has a negative coordinate, `(−3, 2)` to `(5, 8)`;
the drag reads `x: −3 → 5: 5 − (−3) = 8`, counted across the y-axis on the grid. Slip: "−3 to 5 crosses 0: 5 − (−3)
is 8, not 2." This is what 8th grade's `g8-dist`, which counts the squares, doesn't do.
Say: "Across 4 − 1 and up 6 − 2 are the legs of a right triangle, so d = √(3² + 4²) = 5."
**Core:** as the web (a triple's legs either way round from a start point 0..6; smallest-of-six start; check: across
longer, up longer, d ≥ 13, any, all with x₁ and y₁ ≥ 1). New: the any-quadrant type (start point −9..−1 on one or
both axes).

### Midpoint (`g10-mid`, existing; G-GPE.6)
**One square:** 1. **Picture:** the web's, on the paper: the segment from `(2, 3)` to `(6, 9)`. The web's beats stay: the
dashed upright line x = 4, the dashed level line y = 6, the midpoint's dot.
1. **Squeeze to the middle** (new): the two points' x's drop as dots onto the x-axis; drag one, and the other comes
   toward it as far; they meet halfway: `2 and 6 meet at 4`. Its upright line draws (sets `(2 + 6) ÷ 2 = 4`; the web's
   slip "Forgot to halve" shows when the child stops at the sum's place: "The midpoint is the average: divide by 2.").
2. The same with the y's on the y-axis: `3 and 9 meet at 6`.
3. See: the two lines cross on the segment; the dot pops; the two halves get matching ticks.
4. **Write** `M = ([4], [6])`.
Say: "Halfway across and halfway up: the midpoint is (4, 6)."
**Core:** as the web (coordinates −9..9, sums even, points differ; smallest-of-six start; check as the spec, with the
midpoint's coordinates never 0). The spec's new `pre`, `g6-mean`.

### Split a segment in a ratio (`g10-partition`, new; G-GPE.6)
**One square:** 1. **Picture:** an arrow from `A(1, 2)` to `B(13, 8)`, named `1 : 2`.
1. **Cut with the ruler** (the fractions' ruler, laid along the arrow): the handle sets how many equal pieces, 2 to 6,
   the cuts dashed across the arrow; readout `3 pieces: 4 across, 2 up each`. Wrong: "That's 4 pieces. 1 : 2 is 3
   pieces."
2. **Tap** the cut 1 piece from A: P. Wrong: "That's 2 pieces from A. The ratio starts at A."
3. The step from A to P draws: `4 across, 2 up` (a third of 12 and a third of 6).
4. **Write** `P = (1 + 4, 2 + 2) = ([5], [4])`.
Say: "1 : 2 is 3 equal pieces, and P is 1 of them from A."
**Core:** new; builds on `g10-mid` and `g5-fracof`. Ratios 1 : 1, 1 : 2, 2 : 1, 1 : 3, 3 : 1, 2 : 3, 3 : 2; across and up
multiples of the pieces (−15..15); A −8..8. Problems 1–3 1 : 2 and 2 : 1; 4–6 the others; 7+ arrows going left or down.
Slips: 1 : 2 read as a half ("1 : 2 is 1 of 3 pieces: a third."); counted from B ("The ratio starts at A.").

### Where the medians meet (`g10-centroid`, new; G-CO.10, G-GPE.6)
**One square:** 1. **Picture:** a triangle with corners on even crossings whose sums divide by 3 (`(0, 0)`, `(12, 0)`,
`(6, 12)`), so every middle and the meeting point are crossings.
1. **Squeeze to the middle** each side's ends: its middle pops, `(6, 0)`. **Lay the straightedge** from each middle to the
   corner across: three medians draw; the third passes exactly through where the first two crossed (a green dot).
2. **Drag a length** from a corner through the meeting point to the middle: `8 | 4: twice as far` (2 : 1).
3. **Write** `G = ((0 + 12 + 6) ÷ 3, (0 + 0 + 12) ÷ 3) = ([6], [4])`.
See: the paper tilts; the triangle, cut out, rests level on a pin at G; flat again.
Say: "All three medians pass through one point, two thirds of the way from each corner."
**Core:** new; builds on `g10-mid` and `g10-partition`. Corners even −10..10, sums divisible by 3. Problems 1–3 one side
on a strong row; 4–6 any; 7+ G as 2/3 of the way along one median. Slips: divided by 2 ("Three corners: add the three and
divide by 3."); a third from the corner ("G is two thirds of the way from the corner.").

## 9. Lines and shapes on the plane

### Perpendicular slopes (`g10-perp`, existing; G-GPE.5)
**One square:** 1. **Picture:** the web's (`plane`), on the paper: the line through (0, 0) named `m = 2/3`, with its
slope step drawn, `3` across and `2` up. The web's beats stay: the step, the turned step (3 up, 2 left), the new line
with the square mark where they cross.
1. **Turn a shape** (8th grade's): turn the slope step a quarter turn about (0, 0); it snaps at the quarter; its 3 across
   becomes 3 up and its 2 up becomes 2 left. The new line runs along it; the square mark draws at (0, 0). Readout
   `3 up, 2 left`. This sets the web's flip, `2/3 → 3/2` (its slip, "Turning a line a quarter turn swaps rise and run",
   shows if the step is turned back).
2. **Write** `perpendicular slope = [−3]/[2]` (the web's slip: "Perpendicular means flip and change the sign."). See:
   `2/3 × (−3/2) = −1`.
Say: "A quarter turn swaps the 3 and the 2, and turns up into left: −3/2."
**Core:** as the web (p ±1..6, r 1..6 in lowest terms; smallest-of-six start; check as the spec, with no slope of ±1
where the flip is tested).

### Through a point (`g10-perpline`, new; G-GPE.5)
**One square:** 1. **Picture:** the line `y = 2x + 1` drawn and named; a point `P(4, −1)`; the instruction says which:
parallel or perpendicular.
1. **Lay a line** (8th grade's) with its round handle on P: it turns about P and snaps through crossings; readout
   `slope −1/2`; it locks when parallel (arrowheads) or perpendicular (the square mark). Wrong: "Slope −2 is steep the
   other way. Perpendicular is −1/2."
2. **Write** `y − (−1) = −½(x − 4)`, `y = −½x + [1]`.
Say: "Perpendicular slopes flip and change sign; the line then goes through P."
**Core:** new; builds on `g10-perp` and `g9-twopoint`. Slopes as `g10-perp`'s; P −6..6 with the new line's start whole.
Problems 1–3 parallel; 4–6 perpendicular; 7+ the given line through two points. Slips: the old line's start kept ("The
new line goes through P, not through 1."); the slope not flipped.

### Perimeter and area on the plane (`g10-coordarea`, new; G-GPE.7, G-MG.2)
**One square:** 1. **Picture:** a shape with corners on crossings and whole sides (3-4-5 steps): here a tilted right
triangle `(0, 0)`, `(12, 9)`, `(−12, 16)` (problems 4–6; problems 1–3 have one side level); later tilted rectangles
and four-sided shapes.
1. **Drag a length** along each slanted side as Distance does: `√(12² + 9²) = 15`; straight sides count; the readout
   runs `15 + 20 + 25 = 60`.
2. **Drag a rectangle's corner** (kit) to box the shape: `24 × 16 = 384`; **tap** each corner triangle left outside: it
   lifts away, `−54 −84 −96`; readout `384 − 234 = 150`.
3. **Write** `perimeter = [60]`, `area = [150]`.
Density (problems 10+, G-MG.2): the shape is a park on a map, one square 1 km; "3,000 people live here": `3,000 ÷ 150 =
[20]` people per square km.
Say: "Box it in and take away the corners: what's left is the triangle."
**Core:** new; builds on `g10-dist` and `g6-poly`. Corners −12..12, slanted sides from triples. Problems 1–3 triangles
with a level side; 4–6 tilted rectangles and triangles; 7–9 four-sided shapes; 10+ density. Slips: a slanted side
counted as across plus up ("Across 12 and up 9 is the path, not the side: √(144 + 81) = 15."); a corner triangle not
halved.

### Prove it on the plane (`g10-coordproof`, new; G-GPE.4)
**One square:** 1. **Picture:** four points, `A(1, 1)`, `B(7, 3)`, `C(5, 9)`, `D(−1, 7)`, joined.
1. **Drag a length** along each side: readout `AB² = 6² + 2² = 40` (school compares squares).
2. **Draw the step** of each side (8th grade's slope): `AB: 2/6 = 1/3`, `BC: 6/−2 = −3`.
3. **Tap** what holds: parallel pairs (arrowheads), square corners (slopes that multiply to −1), equal sides (ticks).
4. **Choose** the smallest box in 5th grade's family picture (Quadrilaterals ⊃ Trapezoids ⊃ Parallelograms ⊃
   Rectangles and Rhombuses, overlapping in Squares): `Squares`. Too big a box: "It fits there. Is there a smaller box
   it fits in too?"
Record, a proof whose statements come from the moves, reasons chosen: `AB ∥ DC` (same slope, 1/3), `AB ⊥ BC`
(1/3 × −3 = −1), `AB = BC` (both √40), so `ABCD is a [square]`.
Say: "Opposite sides parallel, a square corner, and four equal sides: a square."
**Core:** new; builds on `g10-dist`, `g10-perp` and `g5-shapes`. Tilted squares, rectangles, rhombuses,
parallelograms and trapezoids, corners −8..10; a near miss (one corner a square off) from problem 7. Problems 1–3
parallelograms and rectangles; 4–6 rhombuses and squares; 7+ any. Slip: a rectangle called a square ("All four corners
are square, but AB² is 40 and BC² is 10.").

## 10. Circles (middles on crossings; π is 3.14)

### Arc length (`g10-arc`, existing; G-C.5, G-C.1)
**One square:** 1 (2 squares a unit when r is 4 or less), so the unrolled edge is at most 63 squares (r = 10, with the
camera stepping back a little, as 7th grade's Circumference). **Picture:** the web's (`circle`, arc), on the paper: the circle, its radius
drawn and named `4`, the angle `90°`. The web's beats stay: the arc sweeps open with its radius and angle, then the
whole way round, then the arc's share lights.
1. **Turn a ray** from the 0° arm round the middle to 90°; the arc draws as it turns; readout `90° of 360°`.
2. **Write** `90 ÷ 360 = [1]/[4]` (the web's slip: "A full turn is 360°, not 180°.").
3. **Unroll** (7th grade's): the whole edge peels off along a strong row; **write** `2 × 3.14 × 4 = [25.12]` (slip:
   "Circumference is 2 × π × r."). The arc's quarter lights on it.
4. **Write** `1/4 × 25.12 = [6.28]` (slip: "The arc is shorter than the way around: multiply by the fraction.").
*Fold*, the radian (G-C.5, G-C.1; from problem 7, one in three): circles of radius 4 and 8 with the same 90° arms;
both arcs unroll; **hop** the radius along each: `1.57 radii` both times. **Write** `6.28 ÷ 4 = [1.57]`: "That number,
the same for every circle, is the angle in radians."
Say: "90° is a quarter of the turn, so the arc is a quarter of the way around."
**Core:** as the web (angles 90, 180, 270, 60, 120, 45; r 2–10 for the right-angle family, 3, 6, 9 for 60 and 120, even
for 45; smallest-of-six start; its check). New: the radian type (to the hundredth).

### Area of a sector (`g10-sector`, existing; G-C.5)
**One square:** 1, so the area counts in squares. **Picture:** the web's (`circle`, sector), on the paper: the circle,
radius `6`, angle `120°`. The web's beats stay: the slice sweeps open, the whole circle fills, then the slice alone.
1. **Turn a ray** round to 120°; the slice fills as it turns; readout `120° of 360°`. **Write** `120 ÷ 360 = [1]/[3]`.
2. **Drag a rectangle's corner** (kit) to make the square on the radius, `6 × 6 = 36` (7th grade's picture: the circle
   holds 3.14 of them); **write** `3.14 × 6² = [113.04]` (slip: "r² means 6 × 6.").
3. **Turn a shape**: the slice turns round the middle and fits 3 times. **Write** `1/3 × 113.04 = [37.68]`.
Say: "120° is a third of the turn, so the slice is a third of the circle."
**Core:** as the web (the same angles and radii, so every answer is exact to the hundredth; smallest-of-six start; its
check).

### Inscribed angles (`g10-inscribed`, new; G-C.2, G-C.3)
**One square:** 1. **Picture:** a circle of radius 12, its middle O on a crossing; arc AB lit; the angle at O drawn,
`100°`; a point P on the far side of the circle with the angle APB `?`.
1. **Drag a point** along a line (the kit's move; the line is the circle): P slides round the edge; the protractor at P
   reads `50°` wherever it goes.
2. **Write** `100° ÷ 2 = [50]°`.
3. See (why, also the How to): the line from P through O cuts the angle into two isosceles triangles (their radii
   ticked); each one's outside angle at O is twice its base angle (`g10-exterior`, `g10-isosceles`).
Kinds: the edge from the middle (halve); the middle from the edge (double); a diameter (90° wherever P goes: "Every
angle on a diameter is square."); a four-sided shape in the circle (problems 7+, G-C.3): **drag** C round; it stays
`180° − 70° = [110]°` across from the 70° corner, because their arcs make the whole circle; with x, `2x + 10 + 3x − 5 =
180`, `x = [35]`.
Say: "The angle at the edge is half the angle at the middle, wherever it stands on the circle."
**Core:** new; builds on `g10-exterior` and `g10-isosceles`. Middle angles 40°–160° in 10s; corners 50°–130°; x a
whole. Problems 1–3 halve; 4–6 double and diameters; 7+ four-sided shapes and x. Slips: the middle's angle given ("The
middle's angle is twice the edge's: 100° ÷ 2."); opposite corners set equal ("Opposite corners add to 180°.").

### Tangents and chords (`g10-tangent`, new; G-C.2, G-C.4 +)
**One square:** 2 squares a unit (1 when OP is over 15), so the picture is 40–60 squares across. **Picture:** a
circle, radius `5`, middle O on a crossing; a point P on a crossing outside it, `13` from O (26 squares).
1. **Lay a line** (8th grade's) from P: it pivots; readout `crosses twice` … `touches once`; it locks where it touches,
   at T. **Lay the straightedge** from O to T: the corner at T takes the square mark (the protractor reads 90°).
2. **Raise a square on a side** (8th grade's) on OT (`25`) and on OP (`169`); slide the small one off the big one:
   `144` left. **Write** `PT = √144 = [12]`.
3. **Flip over a line** (8th grade's): the picture flips over OP; PT lands on the second tangent PT′: equal (ticks).
Outside angle (problems 4–6, G-C.2): the angle at P between the two tangents is `180°` take away the angle at O (OTPT′
has two square corners). Chords (problems 7–9): a chord `16` long, `6` from O; **lay the straightedge** from O to it at a
square corner: it cuts the chord in half (`8 | 8`); **write** `r² = 8² + 6² = [100]`, `r = [10]`. The tangent's
construction (problems 10+, G-C.4 +): cut OP in half (`g10-bisect`), **swing the compass** from its middle through O;
that circle crosses the first at T and T′ (an angle on a diameter is square), then the straightedge from P.
Say: "The radius meets the tangent at a square corner, so OT, PT and OP make a right triangle."
**Core:** new; builds on `g8-pyth`, `g10-inscribed` and `g10-bisect`. Triples (5, 12, 13), (6, 8, 10), (8, 15, 17),
(7, 24, 25), (9, 12, 15); middle angles 60°–150°. Problems 1–3 tangent lengths; 4–6 equal tangents and the outside
angle; 7–9 chords; 10+ the construction (+). Slips: the squares added ("OP is the long side: 169 − 25."); OP given as
the tangent.

### Circles around and inside (`g10-around`, new; G-C.3)
**One square:** k squares a unit, the circle 26–30 squares across (radius 5 at 3 squares a unit, 13 at 1).
**Picture:** a triangle with its corners on a circle's crossing points (the crossings 5 from a middle: `(5, 0)`,
`(−3, 4)`, `(−4, −3)`), so the middle is a crossing; later, right triangles with the square corner on a crossing
(3-4-5 at 5 squares a unit, 6-8-10 at 3, 5-12-13 and 9-12-15 at 2), whose inside circle's middle is a crossing too.
Around: 1. Cut two sides in half with their middle lines (`g10-bisect`'s moves; from problem 4 a tap on a side draws
its middle line). 2. **Pin the crossing**: O. 3. **Swing the compass** from O to a corner: the circle passes through all
three (green dots). **Write** `O = ([0], [0])`, `R = [5]`.
Inside (problems 7+): cut two corners' angles in half; **pin** their crossing, I; **lay the straightedge** from I to a
side at a square corner; **swing the compass** from I to that foot: the circle touches all three sides once. **Write**
`I = ([2], [2])`, `r = [2]`.
Say: "O is the same distance from all three corners, because it's on every side's middle line." / "I is the same
distance from all three sides, because it's on every angle's middle line."
**Core:** new; builds on `g10-bisect` and `g10-tangent`. Around: corners on the crossings of circles of radius 5 or 13,
middles −4..4; inside: right triangles from the triples (r 1, 2, 3). Problems 1–3 around a right triangle (the long
side is a diameter); 4–6 around any; 7+ inside. Slip: the medians' meeting point ("That's where the medians meet. The
circle's middle is where the middle lines meet.").

## 11. Circle and parabola equations (the plane)

### Equation of a circle (`g10-circle`, existing; G-GPE.1, G-GPE.4)
**One square:** 1. **Picture:** the plane; the equation written once as the record's first line,
`(x − 2)² + (y + 3)² = 16`. The web's beats stay: the middle's dot, then the radius, then the circle drawing round. Its
**How to** builds the equation (G-GPE.1): a point on the circle, its legs `x − 2` and `y + 3`, its long side 4.
1. **Place a point** for the middle: the equation's two parts read live where the point is, `(x − 2)² = 0 · (y + 3)² =
   0` at `(2, −3)`. Wrong: "At (−2, 3), (x − 2)² is 16, not 0. The middle makes both parts 0." (the web's slip, "Flipped
   the signs"). Sets the centre.
2. **Swing the compass** from the middle: readout `r = 4: r² = 16`; when it matches the equation's 16, the circle draws;
   three of its points check themselves, `(6, −3): 16 + 0 = 16`.
3. **Write** `r = √16 = [4]` (slip: "The right side is r², so take the square root.").
*Fold*, write it (problems 4–6, one in three): the middle and radius are given, `(−1, 4)` and `6`; **write**
`(x + [1])² + (y − [4])² = [36]`. *Fold*, on it or not (G-GPE.4; from problem 7, one in three): "Is (5, 1) on it?"
**Place** the point; a dashed line from the middle reads `√(3² + 4²) = 5`; **choose** `On it`, `Inside` or `Outside`.
Say: "Every point on the circle is 4 from (2, −3): that's what the equation says, by Pythagoras."
**Core:** as the web (middle −9..9, not 0; r 1–9; smallest-of-six start; check as the spec, r ≥ 2). New: the two fold
types (points from triples, on, inside or outside).

### Complete the square (`g10-square`, new; G-GPE.1)
**One square:** 1; algebra tiles drawn in squares: x² is a square 10 × 10 named `x`, an x-strip is 10 × 1, a unit is one
square; negative pieces are striped (7th grade's rule). **Picture:** the equation `x² + y² + 6x − 4y − 12 = 0` as the
record's first line; under it the x part as tiles: the x² square and 6 strips.
1. **Slide pieces** (kit): drag half the strips to the square's right side and half to its bottom; they snap along the
   edges; readout `3 and 3`. Uneven: "4 and 2: split them evenly, 3 and 3."
2. The corner is missing; **tap** to fill it: `3 × 3 = 9` new squares; readout `(x + 3)² = x² + 6x + 9`.
3. The same for y: two striped strips each side, a corner of 4 (striped times striped is solid): `(y − 2)²`.
4. **Write** `x² + 6x + [9] + y² − 4y + [4] = 12 + 9 + 4`, then `(x + [3])² + (y − [2])² = [25]`. See: the circle draws
   on the plane, its middle (−3, 2) and radius 5.
Say: "Half the strips on each side, and the corner finishes the square: x² + 6x + 9 is (x + 3)²."
**Core:** new; builds on `g10-circle` and 9th grade's `g9-complete` (the same tiles and move for one letter; new here
is doing x and y side by side, adding both corners to both sides, and reading the circle). x and y numbers even −12..12; r² a square number up to
100. Problems 1–3 only x needs finishing; 4–6 both; 7+ the constant on the other side. Slips: 9 and 4 added on one side
only ("You added 9 and 4 on the left: add them on the right too."); the corner as 3 ("The corner is 3 by 3: 9
squares.").

### A point and a line (`g10-parabola`, new; G-GPE.2)
**One square:** 1. **Picture:** the plane; a point F at `(0, 2)` and a dashed line `y = −2`.
1. **Place a point** on a crossing: two distances read live, dashed (straight to F; straight down to the line):
   `to F: 10 · to the line: 10`. When they match, the point marks green and stays; otherwise: "4.5 to F and 6 to the
   line: not equal." Place five: `(0, 0)`, `(±4, 2)`, `(±8, 8)`.
2. See: the curve draws through them.
3. **Write** from any point (x, y): `x² + (y − 2)² = (y + 2)²`, so `x² = [8]y`, which is `x² = 4py` with p = 2.
Say: "Every point on it is as far from F as from the line, and that makes x² = 8y."
**Core:** new; builds on `g10-dist`. p 1–4, opening up or down; the low point at (0, 0) for problems 1–6, moved to (h, k)
from problem 7 (`(x − h)² = 4p(y − k)`). Slips: p for 4p ("The focus is 2 from the low point: 4 × 2 = 8."); upside down.

## 12. Solids (3D, from Unit cubes)

One cube is one block where the solid fits; otherwise one unit is 3 squares, ticked along its edges (as 8th grade's
round solids). Flat first; the paper tilts when the solid rises; flat before the next problem.

### Surface area of a box (`g10-surface`, existing; G-MG.1, G-MG.3)
**One square:** a cube is one block (sides up to 6), one unit 3 squares beyond. **Picture:** the web's (`box3d` faces),
in 3D: the box's floor on the paper, `4` and `3` named beside its edges; the paper tilts and the box rises `2` (the edges
are named; no "4 × 3 × 2" line, the spec's fix, since that reads as the volume). The web's beats stay: the top, the
front and the side light with their areas written on them, then `2 × (12 + 8 + 6)`.
1. **Tap** the top: it lights and its squares count, `4 × 3 = 12`; its twin, the floor, shows dashed (the web's slip,
   "A face's area is length × width.").
2. **Tap** the front: `4 × 2 = 8`; **tap** the side: `3 × 2 = 6`.
3. **Turn** the box (`LESSONS.md`'s Turn): the three hidden twins light. **Write** `2 × (12 + 8 + 6) = [52]` (slip: "Each
   face has a twin on the other side: double it.").
*Fold*, design (G-MG.3; from problem 7, one in four): "24 cubes. Which box needs the least card?" Three boxes of 24
(`2 × 3 × 4`, `1 × 4 × 6`, `2 × 2 × 6`) stand side by side; **tap** each one's faces as above (`52`, `68`, `56`), then
**choose** the least. Say: "The closer to a cube, the less card it needs."
Say: "Three different faces, and each one has a twin on the far side."
**Core:** as the web (sides 2–10; smallest-of-six start; check: all different twice, two the same and not 2, all 3 or
more). The spec's lead and new `pre`, `g5-volume`. New: the design type (12, 24 or 36 cubes).

### Volume of a pyramid (`g10-pyramid`, existing; G-GMD.1, G-GMD.3)
**One square:** a cube is one block (s up to 6, h up to 8), one unit 3 squares beyond. **Picture:** the web's (`box3d`
pyramid), in 3D: the square base on the paper, its sides named `6`, the height `5` dashed. The web's beats stay: the base,
then its box, then the pyramid inside it. Its **How to** cuts a cube into three equal pyramids meeting at one corner.
1. **Drag a rectangle's corner** (kit) to cover the base: `6 × 6 = 36` (the web's slip: "That is the distance around. The
   area is side × side.").
2. The paper tilts; **build the layers** (Unit cubes): the box rises to the pyramid's height, `5 layers of 36 = 180`
   (slip: "Stacking the base layer by layer multiplies by the height.").
3. **Pour** (8th grade's): the pyramid, full of sand, pours into the box: a third full; again; again: `3 fill it`.
   **Write** `180 ÷ 3 = [60]` (slip: "A pyramid holds a third of a box with the same base and height.").
Say: "A pyramid holds a third of the box with the same base and height."
**Core:** as the web (s 2–10, h 2–15, s² × h divisible by 3; smallest-of-six start; check as the spec, s ≠ 4). The
spec's idea line (a third of its box, not three copies packed).

### Slanted stacks (`g10-slant`, new; G-GMD.1, G-GMD.2 +)
**One square:** a cube is one block. **Picture:** in 3D, a stack of 8 cards, each `4 × 3`, standing on the paper.
1. **Slide the slices** (new): drag the top card sideways; each card slides a little more than the one under it; the
   stack leans. Readout `the same 8 cards of 12`; the volume readout stays `96` all the while.
2. **Write** `V = 12 × 8 = [96]`.
Coins (problems 4–6, the cylinder): a leaning stack of 10 coins of radius 3: `3.14 × 3² × 10 = [282.6]`. Which holds
more (7–9): two stacks, the same base and height, one leaning: **choose** `The same`. From problem 8 the pair is a cone
and a pyramid with the same base area and height (a cone of radius 2 and a pyramid on a 4 by 3.14 rectangle, both
bases 12.56):
**slide the sheet** (7th grade's) up through both; the two slices read the same at every height, shrinking together,
so **choose** `The same`, and the cone is a third of its can as the pyramid is of its box (G-GMD.1).
The ball (+, problems 10+): a half ball beside a can with a cone taken out of it (radius and height 3); **slide the
sheet** (7th grade's) up through both at once: each slice's area reads the same at every height (a circle; a ring), so
the half ball is the can minus the cone: **write** `2 × (3.14 × 3³ − 1/3 × 3.14 × 3³) = [113.04]` (8th grade's pour gave
the same).
Say: "Every card is the same, so leaning the stack doesn't change how much it holds."
**Core:** new; builds on `g8-cyl`, `g7-prismvol` and `g8-sphere`. Bases: rectangles 2–6, right triangles, circles of
radius 1–6; heights 2–10. Problems 1–3 prisms; 4–6 cylinders; 7–9 which holds more; 10+ the ball (+). Slip: the slanted
edge used as the height ("The height is straight up: 8 cards, not the slanted edge, 10.").

### Solids put together (`g10-solids`, new; G-GMD.3, G-MG.1, G-MG.2)
**One square:** one unit is 3 squares. **Picture:** in 3D, a silo: a can of radius `3` and height `10` with a half ball
on top; later an ice cream (cone and half ball), a pencil (can and cone), a house (box and pyramid), a pipe.
1. **Cut a solid apart** (new): drag along where the parts meet; they lift apart, each named (`can: r 3, h 10`, `half
   ball: r 3`).
2. **Write** each part: `3.14 × 3² × 10 = [282.6]`, `½ × 4/3 × 3.14 × 3³ = [56.52]`.
3. The parts join back; **write** `282.6 + 56.52 = [339.12]`.
Taken away (problems 4–6): a pipe is a can minus a can; a cup is a can minus a cone. A missing size (7–9): "A can holds
471 and its radius is 5. How tall?" **Drag up** its height until the readout reaches 471, `3.14 × 25 × 6`; **write**
`471 ÷ 78.5 = [6]`. Models and density (10+, G-MG.1–2): a tree trunk as a can (its distance round given first); the silo
full of grain at 0.8 tonnes a cubic metre, `339.12 × 0.8 = [271.3]`.
Say: "Cut it into solids you know, find each one, and add them back."
**Core:** new; builds on `g8-cyl`, `g8-cone`, `g8-sphere` and `g10-pyramid`. Radii 1–6, heights 2–12, answers to the
hundredth. Problems 1–3 two parts added; 4–6 taken away; 7–9 a missing size; 10+ models and density. Slips: the whole
ball for half ("Half a ball: ½ × 4/3 × 3.14 × r³."); r² for r³; the width used as the radius.

### Slice it, spin it (`g10-slicespin`, new; G-GMD.4)
**One square:** one unit is 3 squares (1 for balls of radius 10 and 13), so no solid is over 30 squares tall. Two
kinds, taking turns.
Slice (7th grade's `g7-slice` did boxes and pyramids; here round solids and slanted cuts): a can, a cone or a ball
stands on the paper. 1. **Slide the sheet** (7th grade's): level, upright, or slanted by its corner handle; the cut face
lights; readout `circle, r 3`, `rectangle 6 × 10`, `triangle`, `oval`. 2. See: the slice lifts out and lands flat on the
grid at true size. 3. **Choose** its shape; a ball's slice asks its radius: `√(25 − 9) = [4]` (a ball of radius 5, cut 3
from the middle).
Spin: a flat shape lies against a line on the paper. 1. **Spin about a line** (new): drag its handle round; it sweeps out
a solid; readout `a whole turn`. 2. **Choose** `Cylinder`, `Cone`, `Ball`, `Tube` or `Two cones`. 3. **Write** its
sizes from the shape's sides: a 3-4-5 triangle spun about its 3 side, `cone: r = [4], h = [3]`; from problem 7 its
volume too.
Say: "Spun about its 3 side, the triangle sweeps out a cone: the 4 side becomes the radius."
**Core:** new; builds on `g7-slice`, `g8-cone` and `g8-sphere`. Cans r 2–5, h 4–10; balls of radius 5, 10 or 13 cut where
the slice's radius is whole; rectangles 2–6 by 3–8, right triangles from triples, half circles r 2–6. Problems 1–3 level
slices and spun rectangles; 4–6 upright and slanted slices, spun triangles; 7+ ball slices with Pythagoras, spun shapes
with their volume. Slip: radius and height swapped ("Spun about the 3 side: the 4 side sweeps the circle.").

## 13. Chance

Builds on 7th grade's chance (`g7-prob`, `g7-compound`'s two-dice table), 8th grade's two-way tables with row bars
(`g8-twoway`) and 9th grade's parts of a table (`g9-relfreq`: joint, marginal and row percents, "linked or not").
9th grade read a table's percents; here they become chances, with their rules: or, given, independent, one after the
other. One outcome is one cell; one person is one 2 × 2 cell.

### And, or, not (`g10-orand`, new; S-CP.1, S-CP.7)
**One cell:** one outcome, 3 × 3 squares. **Picture:** the two-dice table, 6 × 6 cells (18 × 18 squares), the first die's
faces along the top and the second's down the side; the events named in
words beside it, `A: the first die is 6` and `B: the sum is 10 or more`. A pack of cards is 4 rows of 13 (39 × 12).
1. **Tap pieces** (kit): A's cells shade solid; B's stripe; cells in both get both. Readout `A: 6 · B: 6 · both: 3`.
2. **Tap** the cells the question asks for (A or B): readout `9`. Tapping a cell twice: "That cell is in A and in B: count
   it once."
3. **Write** `P(A or B) = 6/36 + 6/36 − 3/36 = [9]/[36] = [1]/[4]`.
Not (problems 10+, the cells left over): "At least one 6." **Tap** the cells with no 6: they make a 5 × 5 block, `25`;
the rest light, `36 − 25 = 11`; **write** `P = 1 − 25/36 = [11]/[36]`. Counting the sixes one by one and getting 12:
"(6, 6) is in both rows of sixes: count it once."
Say: "The 3 cells in both are counted once: 6 + 6 − 3."
**Core:** new; builds on `g7-compound`. Two dice (36), a coin and a die (12), a spinner of 8 and a coin (16), a pack of
cards (suits by ranks, 52); events by a rule (a sum, a double, at least, a suit, a picture card). Problems 1–3 or with
no overlap, and not; 4–6 or with an overlap; 7–9 and; 10+ at least one, by the cells left over. Slips: the overlap
counted twice ("3 cells are in both: take them away once."); and for or ("And means in both."). Check: or without and
with an overlap, and, at least one.

### Chance when you know something (`g10-given`, new; S-CP.3–6)
**One cell:** one person, 2 × 2 squares (9th grade's block). **Picture:** the two-way table of 100 students (cells 6 × 3
squares): rows `10th grade` (40) and `11th grade` (60), columns `likes science` and `doesn't`; beside it the 100 people
as a 10 × 10 block of cells (20 × 20 squares), standing in reading order by their row, likes science solid, doesn't
striped.
1. "Pick a 10th grader at random." **Tap** the row we know, in the table or the block: the other people grey out and
   the 40 slide together into a block of their own, 4 rows of 10: readout `the whole is now 40`. Tapping a column: "We
   know the grade, not what they like: tap the 10th grade row."
2. **Tap** its people who like science: `18 of 40`.
3. **Write** `P(science given 10th) = 18/40 = [9]/[20]`; then the rule as record, `P(A given B) = P(A and B) ÷ P(B) =
   18/100 ÷ 40/100`, which is 18/40 again.
Dice (problems 4–6, S-CP.6): the 6 × 6 table; "The first die is 4." **Tap** its column: only those 6 outcomes stay;
**tap** the ones with a sum of 9 or more: `2 of 6`, `P = [1]/[3]`. The other way round (problems 7+):
`P(10th given science)`: the science column is the whole, `18 of 50`.
Say: "Knowing it's a 10th grader makes that row the whole: 18 of its 40."
**Core:** new; builds on `g9-relfreq` and `g7-prob`. Tables of 100 people (50 or 200 from problem 7: a cell is half or
2 people, as 9th grade's), fractions that simplify; dice and cards. Problems 1–3 given a row; 4–6 dice; 7+ given a
column, both ways, and the rule with fractions of 100. Slips: the whole table as the bottom ("You know it's a 10th
grader: out of the 40, not 100."); the given turned round ("Given science: out of the 50 who like it, not the 40 10th
graders.").

### Independent or not? (`g10-indep`, new; S-CP.2, S-CP.4–5)
**One square:** on the dice table one outcome is a 3 × 3 cell; on a table's bars a square is 2% (8th grade's bar, 50
squares a whole). **Picture:** the two-dice table with two events named, `A: the first die is even`, `B: the sum is 7`.
1. **Tap pieces**: A's 3 columns shade (`18 of 36`, a half); B's diagonal stripes (`6 of 36`, a sixth). Readout
   `both: 3`.
2. See: B's 6 cells, then the 3 inside A: half of B is in A, as half of everything is. **Write** the test: `P(A and B) =
   3/36 = [1]/[12]`, `P(A) × P(B) = 1/2 × 1/6 = [1]/[12]`: the same.
3. **Choose** `Independent` or `Not independent`. Wrong: "1/12 both ways: knowing the sum is 7 doesn't change the chance
   the first die is even."
Tables (problems 4–6, S-CP.4): rows `10th grade` (25) and `11th grade` (50), columns `likes science` and `doesn't`;
under the table 8th grade's row bars, 50 squares each. **Drag** each bar's divider to its share (it snaps to one
person: 2 squares for 25, 1 for 50): `15 of 25 = 60%`, `30 of 50 = 60%`; the whole table's bar draws under them, `45 of
75 = 60%`: the dividers line up. **Write** `P(10th and science) = 15/75 = [1]/[5]`, `P(10th) × P(science) = 25/75 ×
45/75 = 1/3 × 3/5 = [1]/[5]`: independent. Not independent: `30 of 50` becomes `20 of 50 = 40%`, and the dividers
don't line up.
Stories (7+, S-CP.5): the everyday sentence is the instruction ("Does having a pet go with liking science?").
Say: "Half of B is in A, as half of everything is: knowing B doesn't change the chance of A." / "60% in both rows:
knowing the grade doesn't change the chance."
**Core:** new; builds on `g10-given` and `g9-relfreq`. Dice and coin pairs of both kinds; tables with row totals 10, 25
or 50 (8th grade's, so a person is whole squares), built independent (equal shares) or not (15 to 25 points apart).
Problems 1–3 dice; 4–6 tables and the product test; 7+ stories. Slips: counts compared, not shares ("15 and 30 are
counts: compare 15 of 25 with 30 of 50."); added for the product ("Both happen: multiply, 1/2 × 1/6.").

### One after the other (`g10-tree`, new; S-CP.8 +)
**One square:** the whole rectangle is all the chances, 1; its width is a multiple of the bag's count and its height of
the second pick's (36–45 squares each way: 40 × 40 for a bag of 5, 42 × 42 for 7), so every piece is whole squares.
**Picture:** the rectangle; beside it a bag of 3 solid and 2 striped marbles.
1. **Cut with the ruler** (kit) the rectangle into columns for the first pick: it snaps to fifths (8 squares each);
   readout `3/5 solid | 2/5 striped`. Wrong: "That's 4 pieces: the bag has 5 marbles."
2. The marble isn't put back: **cut** each column into rows for the second pick: the solid column into quarters (`2/4
   solid`, one solid is gone), the striped column into quarters (`3/4 solid`); readouts per column.
3. **Tap** the piece for both solid: readout `3/5 of 2/4`. **Write** `P = 3/5 × 2/4 = [3]/[10]`; then the rule as
   record, `P(A and B) = P(A) × P(B given A)`.
Put back (problems 1–3): every column cuts the same way. One of each (problems 7–9): two pieces, solid then striped and
striped then solid; **tap** both: `3/5 × 2/4 + 2/5 × 3/4 = [3]/[5]`. Test results (10+): the square cut by `ill: 1/10`,
then each column by what the test says (right 9 times in 10); **tap** every `says yes` piece; **write** `P(ill given
yes) = 9 ÷ 18 = [1]/[2]`: "Half the yes results are wrong, because most people aren't ill." (Deciding with chances
like these is 11th grade's `g11-fair`.)
Say: "First 3 of 5, then 2 of the 4 left: 3/5 of 2/4 of the square."
**Core:** new (+); builds on `g10-given` and `g7-compound`. Bags of 4–10 marbles of two kinds, put back or not; tests
with illness 5%, 10%, 20% or 25% and right 80%, 90% or 95% (on a 40 × 40 square every piece is whole). Problems 1–3 put
back; 4–6 not put back; 7–9 one of each; 10+ test results. Slips: the second pick out of the full bag ("One marble is
gone: 4 left, not 5."); added instead of a part of a part ("Both happen: 3/5 of 2/4."); one of each counted once ("Solid
first or striped first: two pieces.").

## Open questions for G

1. **Proofs.** High-school geometry is mostly proof. In this plan the record is a short proof: the statements come from
   the child's own moves, and the child chooses each line's reason from three blocks. Is that enough, or should proofs
   also be a problem type of their own, where the child puts the lines of a longer proof in order?
2. **The (+) lessons.** Common Core marks some standards as extras for students heading to calculus: the 3 lessons of
   Any triangle, the whole of One after the other, and the last problem types of Slanted stacks and Tangents and
   chords. Show them on the map like every other lesson, or as an extra chapter that the grade test doesn't need?
3. **Chance in 10th grade.** Common Core's model Geometry course ends with conditional chance (Appendix A), but the web
   app has none. 11th grade's plan already leaves S-CP.1–8 to 10th grade and keeps the counting and fair-choice parts
   (S-CP.9, S-MD.6–7) itself, so the 4 lessons are here and nothing is taught twice. Keep it that way, or move all of
   chance into 11th grade beside Combinations?
4. **How much to build.** That's 49 lessons (13 from the web, 36 new), the most of any grade so far. Build the 13 web
   lessons first (their maths is already written), or each chapter whole, in teaching order?
