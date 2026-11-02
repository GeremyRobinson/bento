# 8th grade on paper: every lesson's design

Claude (8th grade lesson planner), 1 Nov 2026, in the language of `README.md` and the example of `grade5.md`. Planning
only: nothing here is built yet, and each lesson still goes to G as a preview before Swift.

**Covers Common Core Grade 8 in full:** 8.NS.1–2, 8.EE.1–8, 8.F.1–5, 8.G.1–9, 8.SP.1–4.
**39 lessons in 10 chapters:** the 14 web lessons (`web/src/curriculum/lessons/grade8`, `specs/k12/grade8.md`), each
keeping its maths (generator, ranges, easy-first start, derived values, slips, check recipe), and 25 new ones. Four
small gaps are folded into web lessons as an extra problem type or step, marked *fold*.

Reviewed 2 Nov 2026 (8th grade reviewer): checked against Common Core cluster by cluster, the web code, and 6th and
7th grade's plans. Changed: Pythagoras and Find a missing leg (the tilted square on the long side can't be counted,
so the grid proof and flat squares do it), Evaluate a function (its web numbers reach 66: a line, not the plane),
Unit rate is the slope and Reflections (they repeated 7th and 6th grade), the cone and ball (hands first, record
last), the balance's sharing step, sizes and ranges so every picture fits about 64 × 40, and a few sums and words.

## Coverage

| Standard | What it asks | Lesson(s) | |
|---|---|---|---|
| 8.NS.1 | not every number is rational; repeating decimal to fraction | Repeating decimals `g8-repeat` | new |
| 8.NS.2 | squeeze an irrational between decimals, compare, place on a line | Squeeze a square root `g8-estroot` | new |
| 8.EE.1 | integer exponents | Exponent rules `g8-exp` + *fold*: zero and negative exponents | existing |
| 8.EE.2 | √ and ∛ of perfect squares and cubes; √2 is irrational | Square and cube roots `g8-roots`; `g8-estroot` | existing, new |
| 8.EE.3 | one digit × a power of 10; how many times as big | Scientific notation `g8-sci`; Small numbers `g8-small`; `g8-scicalc` (÷ type) | existing, new |
| 8.EE.4 | work with numbers in scientific notation | Multiply and divide big numbers `g8-scicalc`; `g8-small` | new |
| 8.EE.5 | unit rate is the slope; compare two rates shown different ways | Unit rate is the slope `g8-rate`; Which is faster? `g8-compare` | new |
| 8.EE.6 | slope is the same anywhere on a line; y = mx + b | Slope from two points `g8-slope` + *fold*: slide the slope triangle; Slope-intercept form `g8-intercept` | existing |
| 8.EE.7a | one answer, none, or every number | One, none or every number `g8-howmany` | new |
| 8.EE.7b | x on both sides, brackets, like terms, fractions | Variables on both sides `g8-both`; Brackets on both sides `g8-bracket` | existing, new |
| 8.EE.8a–c | two lines cross at the answer; solve; stories | Where two lines cross `g8-cross` (stories inside); Systems by substitution `g8-system` | new, existing |
| 8.F.1 | one output for each input; the graph is the pairs | One output each `g8-isfunc`; Evaluate a function `g8-func` | new, existing |
| 8.F.2 | compare two functions shown different ways | `g8-compare` | new |
| 8.F.3 | y = mx + b is a straight line; some aren't | Straight or bent? `g8-linear`; `g8-intercept` | new, existing |
| 8.F.4 | rate and start from a story, table, graph or two points | Start and rate `g8-model`; `g8-slope`; `g8-intercept` | new, existing |
| 8.F.5 | read a graph's story; sketch one | Graphs that tell a story `g8-story` | new |
| 8.G.1 | slides, flips and turns keep lengths, angles, parallels | Translations `g8-translate`; Reflections `g8-reflect` (whole shapes, any line: 6th grade folds single points over the axes); Rotations `g8-rotate` | existing, new |
| 8.G.2 | congruent = moved onto it by slides, flips, turns | Same shape, moved `g8-congruent` | new |
| 8.G.3 | the moves and dilations in coordinates | `g8-translate`, `g8-reflect`, `g8-rotate`; Dilations `g8-dilate` | existing, new |
| 8.G.4 | similar = moved and scaled onto it | `g8-dilate`; Same angles, same shape `g8-aa` | new |
| 8.G.5 | triangle angle sum and outside angle; parallel lines and a crossing line; angle-angle | Angles in a triangle `g8-tri` + *fold*: the outside angle; Parallel lines `g8-parallel`; `g8-aa` | existing, new |
| 8.G.6 | a proof of Pythagoras and its converse | Pythagorean theorem `g8-pyth` (the proof in its How to, + *fold*: "Is it a right triangle?") | existing |
| 8.G.7 | missing sides in 2D and 3D | `g8-pyth`; Find a missing leg `g8-leg`; Across a box `g8-pyth3d` (3D) | existing, new |
| 8.G.8 | distance between two points | Distance between points `g8-dist` (the maths of the web's 10th grade `g10-dist`; see the open questions) | new |
| 8.G.9 | volume of cylinders, cones, spheres | Volume of a cylinder `g8-cyl`, of a cone `g8-cone` (3D); Volume of a ball `g8-sphere` (3D) | existing, new |
| 8.SP.1 | scatter plots and their patterns | Scatter plots `g8-scatter` | new |
| 8.SP.2–3 | fit a line by eye; use its slope and start | Fit a line and use it `g8-fitline` | new |
| 8.SP.4 | two-way tables | Two-way tables `g8-twoway` | new |

**Grade boundaries.** 6th grade owns the four-quadrant plane and folding one point over an axis (`g6-quadrants`:
"over the x-axis, y flips"), so `g8-reflect` starts with whole shapes and goes on to other lines. 7th grade owns px + q
= r and p(x + q) = r (`g7-eq`, `g7-eqparen`), unit rates through the origin and the point (1, k) (`g7-constant` slides
a point to x = 1), scale drawings, vertical and supplementary angles (`g7-vertical`, `g7-angles`), and decimals of
fractions; 8th grade starts where each of those turns into a slope, a transformation or the reverse direction (so
`g8-rate` finds the rate as the step between any two points, not by sliding to x = 1). 9th grade keeps elimination
(`g9-elim`), the line through two points in one go (`g9-twopoint`), simplifying roots (`g9-radical`) and numerical
negative powers (`g9-negexp`, see the open questions). 10th grade keeps the outside angle with numbers (`g10-exterior`;
8th grade shows it once) and similar triangles' missing sides (`g10-similar`). The web's `g10-dist` is 8.G.8 itself
(two points, a triple's legs, square, add, root), so `g8-dist` uses its maths; where that lesson lives is an open
question.

## Chapters (teaching order)

| # | Chapter | Lessons |
|---|---|---|
| 1 | Powers and roots | Exponent rules · Square and cube roots · Squeeze a square root · Repeating decimals |
| 2 | Big and small numbers | Scientific notation · Small numbers · Multiply and divide big numbers |
| 3 | Lines and slope | Unit rate is the slope · Slope from two points · Slope-intercept form · Which is faster? |
| 4 | Functions | One output each · Evaluate a function · Start and rate · Straight or bent? · Graphs that tell a story |
| 5 | Equations | Variables on both sides · Brackets on both sides · One, none or every number · Where two lines cross · Systems by substitution |
| 6 | Slides, flips and turns | Translations · Reflections · Rotations · Same shape, moved · Dilations |
| 7 | Angles | Parallel lines · Angles in a triangle · Same angles, same shape |
| 8 | Pythagoras | Pythagorean theorem · Find a missing leg · Distance between points · Across a box (3D) |
| 9 | Round solids | Volume of a cylinder (3D) · Volume of a cone (3D) · Volume of a ball (3D) |
| 10 | Data in pairs | Scatter plots · Fit a line and use it · Two-way tables |

## What every 8th grade lesson shares

As in 5th grade: instruction on rows 0–2 (28), a miss on rows 3–4 (20, red), the picture from row 6 with its names at
its right end, the record 3 rows under it (36, 2 squares a digit), Check / Next under the record. The first words never
repeat the problem; the last line says why. Answers in the chapter colour; red and green only for wrong and right.

- **The plane.** One unit is one square, so the paper *is* the plane: the axes lie on strong lines and every strong
  line is a 5 (numbered small along the axes). The axes run to the screen's edges, so the plane fills the screen; the
  camera frames the problem's points with 3 squares around them, at most 125%. A point is a dot a square across on a
  crossing, its name `(3, −2)` half a square off it. A story's axis may count up in 2s, 5s or 10s (dollars, points),
  numbered on its strong lines; then every value the story puts on that axis is a multiple of its step, so every
  point still sits on a crossing. (A unit of 2 squares would be bigger but puts strong lines at 2½: see the open
  questions.) Each lesson's Core keeps its problems inside about 40 × 30 units, so the plane never needs the camera to
  step back; the ranges below are set for that.
- **The balance** (Equations), as 7th grade draws it: a level beam, two pans on whole blocks, each pan 26 squares wide
  and the two 6 apart (58 in all). An x is a tile 2 squares wide and 5 tall marked `x`, a square apart, up to 9 in a row
  (26 squares); a 1 is a square; ones stack above the tiles as strips of 10, so 100 is a 10 × 10 block. One square is 1,
  so both pans really hold the same. The pans' name (the equation) under the beam; about 22 rows in all.
- **Angles** are drawn true to size, their corners on crossings, and read on 7th grade's protractor (a half circle, a
  tick every degree, longer every 5°, numbered every 30°), since `g8-tri`'s angles are any whole degree.
- **Stories** (rates, models, systems, data) write the story once as the instruction's words; the numbers sit on the
  picture as its names.
- Steps answered by a hand move set their Core box from the move (`LessonRun.set`), so Core's checks and slip messages
  stay; a step the hands make pointless is dropped; a box an earlier move already answered is set at once
  (`autoAnswer`), as the ruler's cut does in Adding fractions.

**New hand moves** (not yet in the kit table of `README.md`; each comes with the first lesson that uses it, after G sees
its preview):

| Move | What the finger does; the live readout | Used by |
|---|---|---|
| Place a point on the plane | tap or drag to a crossing; it snaps; `(3, −2)` | rate, compare, model, linear, cross, reflect, scatter |
| Draw the step | from one point, drag across, then up or down, each leg snapping to squares; `3 across · 12 up` | rate, slope, dist |
| Lay a line | drag a line's two round handles; it pivots and snaps through crossings; `slope 3/2` | rate, compare, linear, fitline |
| Draw a graph | a pen from the last point to the next crossing, piece by piece; `up`, `flat`, `down` | story |
| Sweep a line | drag a straight-up line across the plane a column at a time; `x = 3: 2 points` | isfunc |
| Slide a shape | drag a whole shape (or an angle's wedge) a square at a time, or along a line; `4 right, 5 down` | slope, translate, congruent, dilate, parallel, tri, pyth |
| Flip over a line | drag the shape across a mirror line; it turns over like a card and lands mirrored | congruent (shown in reflect) |
| Turn a shape | drag its turn handle round the centre; it snaps every quarter turn; `90° ↺` | rotate, congruent, parallel |
| Stretch from a point | drag a corner along its dashed ray from the centre; every corner follows; snaps at ×½, ×1, ×2, ×3 (or at each whole step across, for a slope's step); `× 2` | dilate, aa, slope, rate |
| Take the same off both sides (7th grade has it too) | drag a tile off one pan; its twin lifts off the other pan with it; `− 2x from both` | both, bracket, howmany |
| Raise a square on a side | drag a side's handle outward; a square sweeps out on it, its area counting; `6 × 6 = 36` | pyth, leg, dist |
| Pour | drag a full shape over another and tip it; its squares (or, in 3D, its sand) pour in and the level rises; `1 of 3`, `41 into 36` | cone, sphere (3D); pyth's converse (flat) |

Reused from the kit and from 7th grade: tap a block that opens (round), drag a point along a line (round), hop (divdec),
drag digits across place columns (pow10), slide pieces (add, sub), cut with the ruler (fractions), tap pieces / rows,
drag a rectangle's corner (mult2; the square's corner in roots and leg), cover the floor and build the layers (volume,
3D), tap the part (order), pick one (Long division's stories), share into rows and flip over 0 (7th grade's: both,
bracket, func), write.

## 1. Powers and roots

### Exponent rules (`g8-exp`, existing; 8.EE.1)
**One square:** an x is a chip 4 × 4 squares with `x` in it, chips a square apart. **Picture:** the power written once,
big, as the chips' name at their right end (`x² · x³`). Under it the x's written out as chips: rule 0 two groups (a
then b, 2 squares apart, each under a bracket named `x²`, `x³`); rule 1 a + b chips over a bar and b under it; rule 2
b rows of a chips, each row named `x²`. The biggest is 7 chips across, 34 squares.
1. **Do the rule with your hands.** Rule 0, **slide** the second group up against the first: the count runs on
   (3, 4, 5) and the brackets join. Rule 1, **slide** each bottom chip up onto a top chip: both cross out, and the count
   of what's left runs down. Rule 2, **tap** each row: the count runs 2, 4, 6. Readout: the running count, `5 x's`.
   Wrong: a chip dropped on the bottom row: "Match a top x with a bottom x."; a row tapped twice is untapped.
2. **Write** `x² · x³ = x[5]` (the web's step and slips: "When you multiply powers with the same base, add the
   exponents." and the other two).
3. **Try x = 2:** every chip left turns into a 2 (See); **write** `2⁵ = [32]` (slip 2e: "2⁵ means 5 twos multiplied,
   not 2 × 5.").
Say: rule 0 "2 x's and 3 x's: 5 x's multiplied." · rule 1 "3 pairs cancel: 2 x's are left." · rule 2 "3 groups of
2 x's: 6 x's."
*Fold, zero and negative exponents:* rule 3, `x³ ÷ x⁵`: the same slide cancels 3 pairs and 2 chips are left **under**
the bar, over a 1: record `x³ ÷ x⁵ = 1/x² = x[−2]`, then `2⁻² = 1/[4]`. Rule 4, `x³ ÷ x³`: every chip cancels and a 1
is left: `x³ ÷ x³ = x[0] = [1]`. Say: "More x's under the bar: x⁻² is 1 over x²." / "Every x cancels: x⁰ is 1."
**Core:** the web's generator as it is (rule 0–2, a 2–4, b 2–3; first three problems the smallest of six draws). New:
from problem 7, one in three is rule 3 (a 1–3, b 1–3) or rule 4 (a 2–4); a fraction box for `1/[4]`. Skill check: the
web's four items, the last one swapped for a rule 3 item. Tests for rules 3 and 4.

### Square and cube roots (`g8-roots`, existing; 8.EE.2) — cube roots in 3D
**One square:** a unit square is k × k squares, k the biggest of 5, 4, 3, 2 that keeps the square at most 30 squares
across (n 2–6: a block; 7: 4; 8–10: 3; 11–15: 2); every fifth unit line bold, as Multiply two-digit numbers bolds its
tens. **Picture:** the empty corner of a square (two edges) from row 6, its handle on the far corner; the problem's
name at the right end: `81 squares`.
1. Square root: **drag the corner** (it stays a square). Readout `7 × 7 = 49`. Release on 81: the square fills, its
   sides read 9. Too small: "That's 49. It needs 81." Too big: "That's 100: too big."
2. **Write** `√81 = [9]`, then `9 × 9 = [81]` (the web's check step and its slip: "Squared means 9 times itself, not
   9 × 2."). Say: "9 rows of 9 make 81, so the side is 9."
Cube root (**3D**, Unit cubes, one cube is one block): 1. Flat, **drag the corner** of a square floor (`4 × 4 = 16`).
2. The paper tilts; **drag up** to stack layers, each counted on its front (`4 × 4 × 4 = 64`); the box stays a cube, so
   the floor and the layers must agree: "That's 4 layers on a 3 × 3 floor. A cube is the same every way." 3. **Write**
`∛64 = [4]`, `4 × 4 × 4 = [64]`. The paper lies flat before the next problem. Say: "4 layers of 4 × 4 make 64, so the
edge is 4."
**Core:** as the web (a cube 40% of the time, n 2–6; else a square, n 2–15; smallest-of-six start; the slips "The root
isn't a division" and "Multiplied by 3"); the skill check's items keep n ≥ 3.

### Squeeze a square root (`g8-estroot`, new; 8.NS.2, 8.EE.2)
**One square:** on line 1 a block (5 squares) is 1; on line 2 a block is a tenth. **Picture:** Rounding decimals'
two lines. Line 1 from 0 to 10, 50 squares; over each whole number its square, small (`25`, `36`); the problem as the
name at the right end: `√30`.
1. **Tap the block** √30 is in. While the finger is down the block's two squares light (`5² = 25`, `6² = 36`). Wrong:
   "6² is 36: more than 30. Go back." / "5² is 25: 30 is more. Go on." Right: the block lights and opens below
   (dashed) into line 2, ten tenths from 5 to 6.
2. **Drag the point** along line 2; the readout squares the tick it's on (`5.4² = 29.16`). Release on the last tick
   whose square is under 30. Wrong: "5.5² is 30.25: more than 30."
3. **Write** `[5.4] < √30 < [5.5]`, the two squares written under them (`29.16 < 30 < 30.25`). From problem 7 the
   tenth opens once more into hundredths (`5.47 < √30 < 5.48`), and its last line adds "It never lands on a tick:
   √30's digits never stop or repeat. It's irrational."
Say: "5.4² is 29.16 and 5.5² is 30.25: 30 is between them."
*Compare* (8.NS.2): from problem 9, two numbers on one line (`√30` and `√45`, or `√10` and `3.2`): squeeze the roots,
then **tap** the bigger. (π can't be squeezed by squaring, so it isn't one of them.) **Core:** new. n 2–99, not a perfect square; first three problems n ≤ 20; answers floor(10√n)/10 and the
next tenth (hundredths from problem 7). Slip: a square taken as double ("5.4 × 2 is 10.8; 5.4² is 5.4 × 5.4").
Check: one item with n one below a square (√35), one above (√37).

### Repeating decimals (`g8-repeat`, new; 8.NS.1)
**One square:** a place is a column a block wide, as in Multiply by 10, 100, 1000; the point fixed on a strong line.
**Picture:** the decimal's digits in their columns, ten places after the point and then `…` (the camera frames it like
any picture; the `…` says the digits never stop); 12 columns, 60 squares; its name at the left: `x = 0.2727…`. A copy
of the row 3 rows below.
1. **Drag the digits** of the top row left (Multiply by 10, 100, 1000's move): readout `× 10`, `× 100`. While it moves,
   a dot under each column goes green where the digit above matches the one below, red where it doesn't (Adding
   fractions' dots). Release at × 100: the tails match all the way along; the row reads `100x = 27.2727…`. Wrong:
   "× 10 leaves 2 over 7. Line the 27s up."
2. **Slide** the bottom row up onto the top (taking away, as in Subtracting fractions): column by column the matched
   tails cross out to the `…`; `27` is left.
3. **Write** `100x − x = 27`, `[99]x = 27`, `x = 27/99 = [3]/[11]` (simplest only when it can be).
Say: "The tails match, so they take away to nothing: 99 x's make 27." Its How to ends with the reverse, as a line:
"Every fraction's decimal stops or repeats. √2's never does: it isn't a fraction."
**Core:** new. One repeating digit (`0.ddd…`, d 1–8, × 10) for the first three problems, then two (`0.abab…`, ab 10–98,
not aa, × 100); from problem 9 one digit in front (`0.1666…`): the bottom row is dragged × 10 and the top × 100, so the
tails match, and the record is `100x − 10x = 15`, `[90]x = 15`, `x = 15/90 = [1]/[6]`. Slips: × 10 for a two-digit repeat
(tails don't match); the top over 100 ("Take x away once: 100x − x is 99x").

## 2. Big and small numbers (place columns, as Multiply by 10, 100, 1000)

Place columns a block wide, their names over them (small), the point fixed on a strong line between ones and tenths,
digits 36 in their columns. Eight whole columns (99,000,000) and up to eight after the point (4.5 × 10⁻⁷ is
0.00000045): never more than 9 columns, 45 squares, hold digits at once, and the camera follows them.

### Scientific notation (`g8-sci`, existing; 8.EE.3–4)
**Picture:** `45000` in its columns; its name is itself. A ghost of the point sits at the number's end (the web's
"a whole number's point sits after its last digit").
1. **Drag the digits** right together; they snap a column at a time, the zeros at the end falling away as they pass
   the point. Readout `÷ 10`, `÷ 100` … `÷ 10⁴`, and the front number as it stands (`4.5`). Release with one digit before
   the point. Too far: "That's 0.45: one digit goes before the point." Not far enough: "45 has two digits before the
   point."
2. **Write** `45,000 = [4.5] × 10^[4]` (the web's write step; its slips: "Count only the digits after the first one"
   and "The front number has to be at least 1 and less than 10."). The drag answers the web's "places" step (4).
Say: "Moved 4 places smaller, so × 10⁴ puts it back."
**Core:** as the web (c 11–99, e 3–7, the number c × 10^(e−1); smallest-of-six start; skill check as the spec).

### Small numbers (`g8-small`, new; 8.EE.3–4, 8.EE.1)
**Picture:** `0.00045` in its columns, the empty places before the 4 drawn as faint 0s.
1. **Drag the digits** left (× 10 a column); readout `× 10⁴` and the front number. Release with one digit before the
   point. Wrong as in `g8-sci`.
2. **Write** `0.00045 = [4.5] × 10^[−4]`. Slips: a positive power ("It's less than 1, so the power is negative."); −5
   ("Count the places the digits moved: 4.").
Say: "Moved 4 places bigger, so × 10⁻⁴ puts it back."
From problem 7, half the problems go the other way: `3.2 × 10⁻³` as a decimal. **Drag** the digits 3 columns right,
then **tap** each empty place between the point and the 3: a 0 is written there (Multiply by 10, 100, 1000's step 2).
Write `[0.0032]`. **Core:** new. Mirrors `g8-sci`: front c/10 with c 11–99, power −2 to −7; first three problems −2 or
−3; tests for both directions.

### Multiply and divide big numbers (`g8-scicalc`, new; 8.EE.4, 8.EE.3)
**One square:** a "× 10" is a chip 2 × 2 squares. **Picture:** each number as its front digit (36) and its power
drawn out as a row of chips (`10⁴` is four chips), the two numbers one above the other, named at their right ends
`3 × 10⁴` and `8 × 10³`.
1. **Slide** the second row of chips onto the end of the first (as `g8-exp`): the count runs on, `10⁷`. For ÷, slide
   the bottom chips up onto the top ones and they cancel in pairs.
2. **Write** the fronts: `3 × 8 = [24]`.
3. When the front is 10 or more, **drag its digits** one column right; a chip is added to the row (`24 × 10⁷` becomes
   `2.4 × 10⁸`). Wrong: "24 has two digits before the point."
Record: `(3 × 10⁴) × (8 × 10³) = 24 × 10⁷ = [2.4] × 10^[8]`. Say: "Fronts multiply and the tens add up."
**How many times as big** (8.EE.3, the ÷ problems): "How many times as big is 6 × 10⁸ as 3 × 10⁶?" The chips
cancel to 2 left; record `6 ÷ 3 = [2]`, `10⁸ ÷ 10⁶ = 10^[2]`, `= [200]` times. Say: "Fronts divide and the tens
cancel: 200 times as big."
From problem 9, **add** (same power): slide the second front onto the first, as Adding decimals does; `3.2 × 10⁵ +
4.1 × 10⁵ = [7.3] × 10⁵`; say "Same power of 10, so the fronts add."
**Core:** new. Fronts 2–9 (÷: the first a multiple of the second, its power the bigger), powers 2–8; first three problems × with a front
product under 10 and powers to 4. Slips: powers multiplied ("Count the tens: 4 and 3 more is 7."); the front left as 24.

## 3. Lines and slope (the plane: one unit is one square)

### Unit rate is the slope (`g8-rate`, new; 8.EE.5)
**Picture:** the plane's first quadrant (stories are positive), across the story's first quantity (hours), up the
second (miles); beside it the story's table, cells 6 × 3 squares, numbers 28. The story is the instruction: "A bike
goes 12 miles in 3 hours." Its table gives three more pairs.
1. **Place the points** from the table (tap a crossing; readout `(3, 12)`). Wrong: "That's (3, 9). 3 hours, 12 miles:
   up to 12."
2. **Lay a line** from the origin's handle through them; it snaps to the points.
3. **Draw the step** from one table point to another (any two): readout `3 across · 12 up`. Then **stretch** it from
   its corner (it snaps at each whole step across) down to 1 across: readout `1 across · 4 up`. Wrong: "Make it 1
   across: 1 hour." (7th grade found the rate by sliding a point to 1 hour; here any two points give it.)
Record: `slope = 12 ÷ 3 = [4]`, `y = 4x`, under it `4 miles per hour`. Say: "Every step on the line is 4 up for each
1 across: the unit rate is the slope."
**Core:** new. Rate k 2–6 (first three problems 2–3), table x values 1–5, three different, so y stays within 30;
stories from a small set (miles an hour, pages a minute, dollars a pound). Slips: a point's x for its y ("Across is
hours, up is miles."); run ÷ rise ("That's hours for each mile. Up ÷ across: 12 ÷ 3.").

### Slope from two points (`g8-slope`, existing; 8.EE.6, 8.F.4)
**Picture:** the two points placed, their names beside them; nothing else drawn yet.
1. **Draw the step** from the first point to the second (as in `g8-rate`): drag across (readout `2 across`), then up
   or down (`6 up`). The two legs set the run and rise boxes, sign and all. Wrong: past the second point's x: "That's
   past 3. Stop under the second point." The window is at most 5 across and 20 up (the web's run 1–5, slope ±1..4).
2. **Write** `m = 6 ÷ 2 = [3]` (the rise and run lines `8 − 2 = 6`, `3 − 1 = 2` are written for the child from the
   step; the web's slip for flipping: "Slope is rise ÷ run: the y change goes on top.").
3. *Fold (8.EE.6):* **slide the step** along the line (it slides only along it), then **stretch** it from its corner
   to twice the size: the readout keeps `12 ÷ 4 = 3`. Wrong: none; any place and any size are right. Release
   answers the step.
Say: "Every step on this line is the same shape: rise ÷ run is always 3."
**Core:** as the web (x1 −5..5, run 1..5, slope ±1..4, y1 −6..6; smallest-of-six start; the skill check keeps runs of 2
or more). The fold is a hand step with no box.

### Slope-intercept form (`g8-intercept`, existing; 8.EE.6, 8.F.3–4)
**Picture:** the point `(3, 7)` placed; the slope drawn at it as one small step (1 across, 2 up), named `slope 2`.
1. **Hop** back from the point to the y-axis, one step at a time (each hop 1 across and the slope down; tap to add a
   hop, as Dividing by a decimal's hops): readout `3 hops: down 6`. Away from the axis: "The y-axis is the other way."
   It lands on the y-axis: that dot is b.
2. The line draws through b and the point (See).
3. **Write** `2 × 3 = 6` (set from the hops), `b = 7 − 6 = [1]`, `y = [2]x + [1]` (the web's slips: "b = y − mx:
   subtract."; "The slope goes with x. b is where the line crosses the y-axis.").
Say: "3 steps back to the y-axis drop 6, so the line crosses at 1."
**Core:** as the web (m ±1..5, x0 ±1..5, y0 −10..10, b = y0 − m·x0; skill check where b ≠ m).

### Which is faster? (`g8-compare`, new; 8.EE.5, 8.F.2)
**Picture:** one rate as a table (left, as in `g8-rate`) or a drawn line, the other as an equation written as its
line's name (`y = 3x + 2`); the plane to the right.
1. **Place** two of the table's points and **lay a line** through them; readout `slope 2`.
2. **Hop** the equation's line up from its start (2 on the y-axis), 3 up for each 1 across; the line draws.
3. **Tap** the steeper line. Wrong: "That one goes up 2 for each 1 across. The other goes up 3."
Record: `table: [2] per 1`, `equation: [3] per 1`, `3 > 2`. Say: "3 up for each 1 across beats 2: the equation's grows
faster."
**Core:** new. Two rates 1–6, different; starts 0–6; x 0–4, so every point stays within 30 up. First three problems both through 0 (8.EE.5: distance–time, a
graph against `d = 55t` style, numbers kept small); then table vs equation, then graph vs table. Slip: the bigger
start picked ("It starts higher, but grows 2 a step. Look at the slope.").

## 4. Functions

### One output each (`g8-isfunc`, new; 8.F.1)
**Picture:** inputs in a column of 2 × 2 cells on the left, outputs on the right, 20 squares apart, an arrow from
each input to its output; named `in` and `out` over the columns. From problem 7 the same pairs as points on the plane.
1. **Tap** each input: its arrows light and its outputs ring; readout `4 → 2` (or `3 → 7 and 9`).
   On the plane, **sweep a line** across, a column at a time: readout `x = 3: 2 points`.
2. **Tap** a block: `One each` or `Two outputs`. Wrong: "3 goes to 7 and to 9: two outputs." / "Each input has one
   arrow. Look again."
Record: the input that broke it ringed with both its arrows, written `3 → 7, 3 → 9`; or `each input → one output`.
Say: "3 has two outputs, so this isn't a function." / "Every input has just one output: a function."
**Core:** new. 4–6 pairs, inputs −5..9; half are functions; the rest have exactly one input with two outputs. First
three problems arrows with 4 pairs; the plane from problem 7. Several inputs sharing one output stays a function (an
item in the skill check: "Two inputs can share an output.").

### Evaluate a function (`g8-func`, existing; 8.F.1)
**One square:** 1 on a line along a strong row (2 squares a unit when the line spans 30 or less, as 7th grade's
`g7-addint`, so small problems fill the width). The web's numbers reach f(x) = 9 × 6 + 12 = 66, which no plane at a
square a unit can hold up the screen, but a line across it can: 66 squares, the camera stepping back a hair.
**Picture:** the line from 0, the rule written once as its name at the right end, `f(x) = 3x − 5`, and the input as a
tag under 0, `x = 4`; solid hops are +, striped hops − (7th grade's look).
1. **Hop** from 0: tap to lay hops of 3 (Dividing by a decimal's hops), as many as the input; readout `4 hops of 3:
   12`. Wrong count: "That's 5 hops. x is 4." When the input or the 3 is negative, the hops are laid by size first,
   then **flip over 0** (7th grade's `g7-mulint`) once for each negative: readout `−12`. Wrong: "3 × −4 has one
   negative: flip once." This answers the web's `3 × 4 = 12` step (its slips: sign; "The rule multiplies x by 3.").
2. **Hop** the rule's number from there: drag one hop 5 long, left for − and right for +; readout `12 − 5 = 7`. Wrong
   way: "The rule has − 5: hop left."
3. **Write** `f(4) = 3 × 4 − 5 = 12 − 5 = [7]` (12 written from the hops), then the pair `(4, 7)` beside it.
Say: "4 goes in, 7 comes out: f(4) = 7, so (4, 7) is a point on its graph."
**Core:** as the web (a −6..9 and b −12..12, neither 0; x −6..6; smallest-of-six start; its skill check). x = 0 is no
hops: the readout says `0 hops: 0`.

### Start and rate (`g8-model`, new; 8.F.4)
**Picture:** a story ("A plant is 4 cm tall and grows 3 cm a week.") or a table (x 1, 2, 3, 4; y 7, 10, 13, 16), the
table on the left, the plane on the right.
1. **Tap** two rows of the table: the step between them is written beside the table, `+1`, `+3`; readout `3 per 1`.
2. **Place** the table's points (the first by hand, the rest draw in), then **hop** back from the first point to x = 0,
   one step at a time: it lands on the start. Wrong: "x = 0 is the y-axis. Hop to it."
Record: `rate = 3 ÷ 1 = [3]`, `start = 7 − 3 = [4]`, `y = [3]x + [4]`. Say: "It starts at 4 and grows 3 each week:
y = 3x + 4."
**Core:** new. Rate 1–6, start 0–12 (from problem 7 also falling: rate −4..−1, start 20–30, y never below 0); the
table's four x values 1–4 (from problem 9 in steps of 2, 1–7, so the rate is a division); every y within 0–30, so a
square is 1 up; stories from a small set (plants, savings, taxis). Slips: the first
y taken as the start ("The start is at x = 0, one step before x = 1."); m and b swapped.

### Straight or bent? (`g8-linear`, new; 8.F.3)
**Picture:** a table of four pairs, the plane beside it.
1. **Place** the four points (two by hand, two draw in).
2. **Lay a line** through the first two: points on it get a dot in the chapter colour; a point off it is ringed and
   measured, "(3, 9) is 6 above the line."
3. **Tap** `Straight` or `Bent`. Wrong: "(3, 9) is off the line, so it bends."
Record: the steps up written under the table, `+1, +3, +5`, then `steps change: not linear`, or `+2, +2, +2` and
`y = [2]x + [1]` (typed when straight). Say: "Same steps across, different steps up: it bends."
**Core:** new. Half straight (m 1–4, b 0–5); half the square's area, `A = s²` or `y = x² + c` (c 0–5), x 0–3; first three
problems clearly one or the other.

### Graphs that tell a story (`g8-story`, new; 8.F.5)
**Picture:** the plane's first quadrant, across in minutes, up in metres from home (one square each, or 2 metres when
the story needs it, numbered on the strong lines).
1. *Read* (problems 1–3): a graph in three pieces is drawn; **tap** the piece the words ask for ("Where does she stop
   to play?"). Wrong: "That piece goes up: she's still walking."
2. *Draw* (from problem 4): "Walk to the park, play there, run home." **Draw the graph** piece by piece; readout `up`,
   `flat`, `down`. Wrong: "She's playing: this part stays flat."
Record: the pieces named under the graph, `up · flat · down`, each in its own words (`walks · plays · runs home`).
Say: "Up as she walks away, flat while she plays, steeply down as she runs home."
**Core:** new. Stories from templates of three pieces (up, flat, down; or speeding up, shown as a bend); a drawing is
right when each piece rises, stays or falls in order and the faster piece is steeper; lengths are free.

## 5. Equations (the balance, then two lines)

### Variables on both sides (`g8-both`, existing; 8.EE.7b)
**Picture:** the balance (above); left `5` x tiles and `3` ones, right `2` x tiles and `18` (a ten strip and 8
squares). The web's biggest, 9 x's against up to 100 ones, fills a pan: 9 tiles in a row and a 10 × 10 block above. The
equation is the pans' name, written once under the beam: `5x + 3 = 2x + 18`.
1. **Take the same off both sides:** drag an x tile off the right pan; its twin lifts off the left with it. Readout
   `− 2x from both` as the second goes. Ones first: "Take the x's off first, so they're all on one side." Too many:
   "The right pan has no x left."
2. **Take** the 3 ones off the left: 3 lift off the right too (the ten strip breaks into squares when it must).
3. **Share into rows** (7th grade's move): drag the right pan's handle down until there's a row for each x; its
   squares re-deal; readout `3 rows of 5`. Wrong: "Make 3 rows: one for each x." Then one x and one row come down
   together (See), as in `g7-eq`.
Record (the web's three steps; the first two set from the moves): `[3]x + 3 = 18`, `3x = [15]`, `x = [5]`, with the web's
slips ("Subtract 2x from both sides.", "To undo + 3, subtract 3.", "3x is 3 times x, so divide by 3").
Say: "The pans stay level: 3 x's balance 15, so one x is 5."
**Core:** as the web (a 3–9, c below a, x 1–10, b 1–20, d derived; smallest-of-six start; its skill check).

### Brackets on both sides (`g8-bracket`, new; 8.EE.7b)
**Picture:** the balance; on the left the bracket drawn as 7th grade draws it (`g7-eqparen`): 3 groups side by side,
each an x tile and 4 ones in a dashed box; on the right x tiles and ones. Name: `3(x + 4) = x + 20`.
1. **Slide** the ones out of their boxes into one pile (slide pieces): the boxes open, the x's stay in a row, and the
   pile counts as it fills; readout `3 × 4 = 12`. The pan now reads `3x + 12`.
2. **Write** `3(x + 4) = 3x + [12]`. Slip: "Multiply the 3 by both: 3 × x and 3 × 4." (12 forgotten as 4).
3. Then as `g8-both`: **take the same off both** (the x, then the 12), then **share into rows**. Record `2x + 12 = 20`,
   `2x = [8]`, `x = [4]`.
*Fractions* (from problem 8): one dashed box marked `½` around 4 x's and 6 ones: **share** it into 2 rows (share into
rows); one row stays and the other fades: `½(4x + 6) = [2]x + [3]`. Say: "Half of each part: 2 x's and 3."
Say: "Open the bracket, then take the same off both sides: x is 4."
**Core:** new. a 2–5, b 1–6, c 1..a−1, x 1–10, d = (a − c)x + ab; the ½ type with 2k x's (k 2–4) and 2m ones (m 1–5),
c below k. First three problems a = 2 and c = 1.

### One, none or every number (`g8-howmany`, new; 8.EE.7a)
**Picture:** the balance with the same number of x tiles on both pans: `4x + 6 = 4x + 9`.
1. **Take the same off both:** every x comes off, from both pans at once.
2. What's left is weighed (See): 6 against 9, the beam tips and the pans can't level; or 6 against 6, level whatever
   x is.
3. **Tap** `One number`, `No number` or `Every number`. Wrong: "6 can never equal 9: no number works." / "6 = 6 is
   always true: every number works."
Record: `4x + 6 = 4x + 9`, `6 = 9`, `no solution` (or `6 = 6`, `every x`). Say: "The x's all came off and 6 can't be 9:
no number works."
**Core:** new. a 2–6, b and d 1–20; 40% none, 40% every (from problem 7 hidden in a bracket, `2(x + 3) = 2x + 6`),
20% one answer, solved as in `g8-both`. First three problems plain, none or every.

### Where two lines cross (`g8-cross`, new; 8.EE.8a–c)
**Picture:** the plane, the two equations named where their lines will end: `y = 2x + 1`, `y = −x + 10`.
1. **Hop** each line up from its start on the y-axis (its slope each hop); the line draws through the hops.
2. **Place a point** where they cross: readout `(3, 7)`. Wrong: "(2, 5) is on y = 2x + 1, not on y = −x + 10."
Record: `7 = 2 × 3 + 1`, `7 = −3 + 10`, `(x, y) = ([3], [7])`. Say: "The crossing is on both lines, so it makes both
true."
Same slope, different start: they never cross; **tap** `No crossing`. Same line twice: **tap** `Every point`. Say:
"Same slope, different start: they never meet, so nothing works."
*Stories* (8.EE.8c, from problem 8): "Plan A: $20 to join, then $5 a month. Plan B: $10 a month." Months across,
dollars up (one square is $5), first quadrant; the record ends `At [4] months both cost $[40].`
**Core:** new. Slopes −3..3 and different, the crossing at x −5..5, y −8..8 (whole), and both starts within −10..10, so
the starts, the hops and the crossing fit a window about 11 × 21 squares; from problem 6 one in six
parallel and one in ten the same line; stories from problem 8. First three problems one line is flat (`y = 4`).

### Systems by substitution (`g8-system`, existing; 8.EE.8b)
**One square** is 1. **Picture:** a bar s squares long, 4 tall, named `x + y = 15`; above it, `y = 2x` drawn as a strip
`y` made of 2 strips `x` (their length not shown).
1. **Slide** the 2 x strips down into y's place in the bar: it now reads x · x · x; readout `x + 2x = 3x` (sets the
   web's "sub" box, 3). Dropped elsewhere: "Put them where y is."
2. **Cut** the bar into equal pieces with the ruler (snapping to lengths that divide 15): readout `5 · 3 pieces`. Cut:
   wrong count, "That makes 5 pieces. There are 3 x's." Right: each piece reads 5 (sets x).
3. **Write** `y = 2 × 5 = [10]` (the web's slip "Found x again": "y = 2x, so y is 2 × 5.").
4. See: when s is 30 or less, the bar fades and the plane draws in its place (a square a unit), the two lines crossing
   at `(5, 10)`. Bigger problems (y reaches 50) end on the bar.
Say: "3 equal x's make 15, so x is 5 and y is 10: the lines cross at (5, 10)."
**Core:** as the web (k 2–5, x 1–10, s = (k + 1)x ≤ 60, so the bar always fits; keep the "Substitute" step).

## 6. Slides, flips and turns (the plane; shapes' corners on crossings)

Every lesson here ends with the same See beat (8.G.1): the moved shape's sides and angles are written beside both
shapes, and match ("5 squares", "90°"); parallel sides stay parallel (a small double arrow on both).

### Translations (`g8-translate`, existing; 8.G.1, 8.G.3)
**Picture:** the plane; the point `(2, 3)` as one corner of a small triangle that rides with it (picture only: the
maths stays the web's one point). The move is the instruction: "Slide it 4 right and 5 down."
1. **Slide the shape** across: readout `4 right`. Wrong: "That's 3 right. Slide it 4."
2. **Slide** it down: readout `5 down`. Wrong way: "Down takes away from y. Slide it down."
Record (the web's steps): `x: 2 + 4 = [6]`, `y: 3 − 5 = [−2]`, and the corner named `(6, −2)`.
Say: "Right adds to x and down takes from y: (6, −2)."
**Core:** as the web (the point −8..8, each move ±1..6; smallest-of-six start; its skill check, one item crossing an
axis).

### Reflections (`g8-reflect`, new; 8.G.1, 8.G.3)
**Picture:** a triangle ABC in one quadrant, the mirror line drawn bold (an axis, a line like `x = 2`, or `y = x`),
named `flip over the x-axis`.
1. **Place** each corner's image: readout `(3, −2)`. Wrong: "A is 2 above the line, so A′ is 2 below."
2. The image draws; then the triangle **flips over the line** onto it (See: it turns over like a card and fits).
3. **Write** the corners: `A(3, 2) → A′(3, [−2])`, then the rule as record `(x, y) → (x, −y)`.
Say: "Over the x-axis, x stays and y changes sign."
For a line like `x = 2` the record is the corners only (no rule). Over `y = x` the rule is `(x, y) → (y, x)`: "Over
y = x, x and y swap."
**Core:** new; builds on `g6-quadrants`, which folds one point over an axis, so here the shape is the thing. Corners
1–7 from the mirror. Problems 1–3 a right triangle with sides on the grid, over the x-axis or the y-axis (review); 4–6
over a line `x = a` or `y = b` (a, b −4..4, not 0); 7+ over `y = x` too. Slips: both signs changed ("Only y changes
over the x-axis."); the shape slid instead of flipped ("Slid, it keeps facing the same way. A flip turns it over.");
distances counted from the axis instead of the line ("A is 3 from x = 2, so A′ is 3 past it.").

### Rotations (`g8-rotate`, new; 8.G.1, 8.G.3)
**Picture:** a triangle in the first quadrant; the turn's centre at the origin, a dashed ring through the nearest
corner with a round handle on it; named `a quarter turn left`.
1. **Turn the shape**: drag the handle round; it snaps every quarter turn, readout `90° ↺`. Wrong: "That's a half
   turn. Turn it a quarter."
2. **Write** a corner's new place: `A(4, 1) → A′([−1], [4])`, then the rule as record `(x, y) → (−y, x)`. Slip: the
   coordinates swapped without the sign ("A quarter turn left: the new x is minus the old y.").
Say: "A quarter turn left: x and y swap, and the new x changes sign."
**Core:** new. Corners 1–6; a quarter turn left, a quarter turn right, or a half turn; first three problems half
turns (both signs change).

### Same shape, moved (`g8-congruent`, new; 8.G.2)
**Picture:** shape A in the chapter colour and shape B as an outline, the same size, somewhere else.
1. **Slide**, **flip** and **turn** A (any of the three, in any order) until it sits on B; each move is written as it
   happens. Readout: the move now (`3 right, 2 up`). When A covers B exactly, it locks.
   Wrong only when stuck: "It's facing the other way: it needs a flip."
Record: the moves written in order, `slide 3 right, 2 up · flip over the x-axis`. Say: "Moved without stretching, so
the two shapes are congruent."
**Core:** new. B is A after 1 move (first three problems), then 2, then 3; any sequence that lands is right, and the
record is written from the child's own moves (nothing typed).

### Dilations (`g8-dilate`, new; 8.G.3, 8.G.4)
**Picture:** a triangle in the first quadrant, dashed rays from the origin through each corner; named `× 2 from (0, 0)`.
1. **Stretch from a point:** drag a corner along its ray; every corner follows. Readout `× 2`. Wrong: "That's × 3:
   every corner is 3 times as far."
2. **Write** a corner: `A(2, 1) → A′([4], [2])`, then `(x, y) → (2x, 2y)`, and a side `3 → [6]`.
3. (8.G.4) A second, matching triangle B is drawn elsewhere: **slide** the stretched one onto it.
Say: "Every length × 2 and every angle the same: similar."
**Core:** new. Corners 1–4 for × 2 and × 3, even corners 2–8 for × ½; first three problems × 2. Slip: added instead of
multiplied (`(2, 1) → (4, 3)`: "A dilation multiplies every coordinate by 2.").

## 7. Angles (drawn true to size, corners on crossings; 7th grade's protractor reads them)

### Parallel lines (`g8-parallel`, new; 8.G.5)
**Picture:** two parallel lines on grid lines, 50 squares long, a crossing line at the problem's angle; one angle
marked `65°` (a wedge in the chapter colour), another marked `?`. So both crossings sit on grid crossings, the gap
between the parallels and the crossing line's run are picked from a small table that lands within half a degree of
the angle (65°: 15 up for 7 across, 64.98°; 55°: 10 for 7; 45°: 10 for 10; 35°: 7 for 10); the gap is 7 to 15 squares.
1. **Slide** the 65° wedge along the crossing line to the other crossing, or **turn** it a half turn about its own
   crossing; it fits wherever an angle is equal and locks there, and the `?` it lands on reads 65°. When the `?` is
   the other part of a straight line, the wedge sits beside it and the readout says `65° + ? = 180°`.
2. **Write** `? = [65]°`, or `180° − 65° = [115]°`. Slip: the wedge's angle given for its neighbour ("That angle and
   65° make a straight line: 180° − 65°.").
Say: "Slid along the crossing line, the angle fits: they're equal." / "Together they make a straight line: 115°."
**Core:** new. The marked angle 30–150° in fives (not 90); the asked angle any of the other seven. First three problems
fit by one slide (corresponding: the new idea, since 7th grade's `g7-vertical` already turns opposite angles); 4–6 by
a slide and a turn (alternate); 7+ any, the straight-line partners and the opposite ones mixed in.

### Angles in a triangle (`g8-tri`, existing; 8.G.5)
**Picture:** the triangle drawn true to its angles on a 30-square base, its two known corners marked `50°` and `60°`,
the top `?`; a dashed line through the top corner, parallel to the base.
1. **Slide** each known corner's wedge up to the top corner (it turns as it goes), laying it along the dashed line on
   its own side: it snaps there. Readout `50° + 60° = 110°`. The gap left between them is the third angle.
2. **Write** `50° + 60° = [110]°`, `180° − 110° = [70]°` (the web's steps and slips: "Put the two known angles
   together: add them.", "Triangles add up to 180°. 360° is for four-sided shapes.").
3. *Fold, the outside angle:* the base runs on past a corner, and the two far corners' wedges slide into the outside
   angle and fill it (See); written for the child, `outside = 50° + 70° = 120°`.
Say: "The three corners make a straight line: 180°."
**Core:** as the web (a 20–100, b 20..150 − a; smallest-of-six start; its skill check).

### Same angles, same shape (`g8-aa`, new; 8.G.5, 8.G.4)
**Picture:** a small triangle and a bigger one, two angles marked in each (`40°, 75°` and `40°, 75°`); the small one's
base 10 squares, the big one's 20 or 30 (× 2 or × 3), so both fit side by side within 50.
1. **Stretch** the small triangle from its 40° corner (it snaps at × 2 and × 3): when it is as big as the other, it
   slides onto it. Same three angles: it fits exactly. Not the same: a gap shows, measured ("This angle is 65°, that
   one 55°.").
2. **Tap** `Same shape` or `Not the same`. Wrong: "It fits exactly: same shape." / "There's a gap at the top: not the
   same shape."
3. **Write** each third angle: `180° − 40° − 75° = [65]°`, the same for the other.
Say: "Two angles match, so the third does too: the same shape, scaled."
**Core:** new. a and b 30–80 (a + b under 150), × 2 or × 3; half similar, the rest one angle 10–20° off; first three
problems similar.

## 8. Pythagoras

The legs lie on grid lines and every corner sits on a crossing, so a leg's square is counted on the paper. The square
on the long side is tilted, and its squares can't be counted one by one, so the lessons never ask for that: they find
its size by the grid proof (`g8-pyth`) or lay the long side flat first (`g8-leg`, the converse). A unit is u squares,
the biggest of 3, 2 or 1 that fits; each lesson gives its rule.

### Pythagorean theorem (`g8-pyth`, existing; 8.G.6, 8.G.7)
**One square:** u is 3 for 3-4-5, 2 for 6-8-10, 1 for the rest (the biggest that keeps a + b units within 31 squares).
**Picture:** at the left, the right triangle, the longer leg up and the other across, its square corner marked, the legs
named `3` and `4`, the long side `c`. A block to its right, a dashed frame a + b units on a side (7 units, 21 squares)
holding four copies of the triangle as two rectangles, which leaves two square holes. Both figures are a + b wide once
the leg squares are raised: 21 + 5 + 21 = 47 squares for 3-4-5, 67 for 7-24-25 (the widest), 31 tall at most.
1. **Raise a square** on each leg: readout `3 × 3 = 9`, then `4 × 4 = 16` (sets the web's two square steps).
2. **Slide** the two squares into the frame's holes: each fits one hole exactly (it snaps only there). Wrong hole:
   "The 9 is 3 by 3. That hole is 4 by 4."
3. The squares lift back out (See). **Slide** the triangles in the frame (three of them move, a square at a time; each
   snaps only into its new corner): the two holes close up into one tilted square on the long side. The readout stays
   the same the whole time: `space left: 9 + 16 = 25`.
4. **Write** `9 + 16 = c² = [25]`, `c = √25 = [5]` (the web's slips: "Add the two squares, not the sides.", "Square
   root isn't half.").
Say: "Same frame, same four triangles, so the same space: the square on c is 9 + 16 = 25, and c is 5."
This is the proof (8.G.6), done by the child's own hands; the **How to** plays it once with the ghost finger. From
problem 4 the triangles in step 3 slide by themselves (See), so practice is the two squares and the record.
*Fold, the converse* (8.G.6): from problem 7, one in four gives three lengths. They lie flat on the strong row as
sticks, a block apart (u the biggest of 3, 2, 1 that keeps them within 60 squares); **raise a square** on each, then
**pour** the two small ones into the big one (their squares pour in, as Adding decimals pours hundredths). They fill
it exactly: the sticks fold up into a triangle with a square corner (See); **tap** `Right angle`. They don't: the
readout shows `16 + 25 = 41 into 36` and 5 squares spill over (or `169 into 196` and 27 stay empty); **tap** `Not a
right angle`; say "41 isn't 36, so the corner isn't square." (Near misses can't be drawn with their corners on
crossings, so only the right ones fold up.)
**Core:** as the web (a triple from TRIPLES, legs either way; skill check as the spec). New: the converse type, with
near misses (4, 5, 6; 6, 7, 9; 5, 12, 14).

### Find a missing leg (`g8-leg`, existing; 8.G.7)
**One square:** u is 3 when c is 10 or less, 2 up to 15, 1 beyond, so the long side's square is at most 30 squares.
**Picture:** the right triangle (as `g8-pyth`), the leg `6` and long side `10` named, the other leg `b`. As the problem
opens, the long side and the known leg swing down flat onto the strong row as sticks (See); b's stick is dashed.
1. **Raise a square** on the long side's stick (`10 × 10 = 100`), then on the leg's (`6 × 6 = 36`), a block apart. Both
   lie square on the grid, so both are counted.
2. **Slide** the 36 into a corner of the 100 (taking away, as Subtracting fractions covers pieces): the squares it covers
   cross out and the rest count; readout `100 − 36 = 64`.
3. **Drag the corner** of a square on b's stick (Square roots' move) until it holds 64: readout `7 × 7 = 49`, `8 × 8 =
   64`. Too big: "That's 81. Only 64 are left."
4. **Write** `b² = 100 − 36 = [64]`, `b = √64 = [8]` (the web's slips). The sticks swing back up and the triangle closes,
   6, 8 and 10 (See).
Say: "The two leg squares make the big one, so 100 − 36 = 64 is left for b: b is 8." From problem 8, stories (a ladder
against a wall, a ramp) put the same triangle in a picture; the numbers are the same triples.
Biggest: 7-24-25 at a square a unit, the 625 square and the 49 (or 576) side by side, 25 + 5 + 24 = 54 squares.
**Core:** as the web.

### Distance between points (`g8-dist`, new; 8.G.8)
**Picture:** the plane, two points named `(1, 2)` and `(9, 8)`.
1. **Draw the step** between them (as in `g8-rate` and `g8-slope`): readout `8 across`, `6 up`.
2. **Raise a square** on each leg of the step, outward: `8 × 8 = 64`, `6 × 6 = 36`, counted on the plane's own squares.
3. The straight path between the points draws (See), the long side of the triangle the step made.
4. **Write** `64 + 36 = [100]`, `d = √100 = [10]`. Slips: "Square each one first." (14); "The straight path is
   shorter than across and up together."
Say: "Across and up are the legs, so the straight path is √(64 + 36) = 10."
**Core:** new, with `g10-dist`'s maths (a triple's legs, either way round, from a start point), on the four-quadrant
plane: legs to 12 (3-4-5, 6-8-10, 5-12-13, 9-12-15), any direction, the points −8..10, so the step and its two squares
fit about 24 × 24 squares; first three problems 3-4-5.

### Across a box (`g8-pyth3d`, new; 8.G.7) — 3D
**Picture:** a box l × w × h from Unit cubes (a unit is 3 squares here, so a box 12 tall still fits); flat first, its
floor on the paper, named `2 × 3 × 6`.
1. Flat: **draw the step** across the floor from corner to corner (along one edge, then the other); the diagonal
   draws; readout `2 by 3`; **write** `d² = 2² + 3² = [13]`. The floor is always the two shorter edges.
2. The paper tilts and the walls rise (**drag up**, the height counted, `6`).
3. **Drag** from the floor diagonal's end up to the far top corner: a right triangle stands up inside the box (the
   floor diagonal, the height, the long way across). **Write** `D² = 13 + 6² = [49]`, `D = √49 = [7]`.
Say: "The floor's diagonal and the height make a right triangle standing up: 7 across the box." The paper lies flat
before the next problem.
**Core:** new. Boxes whose long diagonal is whole: (1, 2, 2), (2, 3, 6), (1, 4, 8), (4, 4, 7), (2, 6, 9), (6, 6, 7),
(3, 4, 12); first three problems (1, 2, 2) or (2, 3, 6). Slip: d instead of d² carried ("Use d², 13: the square on the
floor's diagonal.").

## 9. Round solids (3D, from Unit cubes)

A unit is 3 squares when the radius is 1–3 and 2 squares when it is 4–6, ticked along the radius, so a cone or ball
and its can still stand side by side to pour (radius 6: two circles 24 squares across, 53 with the block between;
the tallest, a cone 12 high, is 24 squares). Flat first, the base circle on the paper; the paper tilts only when the solid rises; words stay facing the
child; flat again before leaving. π is 3.14, as the web uses.

### Volume of a cylinder (`g8-cyl`, existing; 8.G.9)
**Picture:** the base circle, its radius drawn and named `3`; the can's height named `5` beside it (dashed, rising
later).
1. **Drag the corner** of the radius square, r by r, its corner at the circle's middle and its sides along two radii
   (on grid lines): readout `3 × 3 = 9` (sets `3² = 9`).
2. See: the radius square's copies fill the circle, cut along its edge as 7th grade's Area of a circle cuts them:
   3 whole ones and a sliver, `3.14 of them`.
3. The paper tilts; **drag up**: the base rises in layers, a unit each, counted on the front, `5 layers`. Wrong: "5
   high: stop at 5."
4. The paper lies flat. **Write** `3.14 × 9 = [28.26]` (the web's slip: "2 × π × r is the distance around. The base
   area is π × r × r."), then `28.26 × 5 = [141.3]` (slip: "÷ 3 is for a cone. A cylinder is the whole stack.").
Say: "The circle base, stacked 5 high."
**Core:** as the web (r 1–6, h 2–10; smallest-of-six start; the skill check keeps r ≥ 2).

### Volume of a cone (`g8-cone`, existing; 8.G.9)
**Picture:** flat, the cone's base circle, its radius named `3`, and a block beside it the same circle again, the can's
floor; the height `4` named beside them.
1. **Drag the corner** of the radius square, as in `g8-cyl`: `3 × 3 = 9`; 3.14 of them fill the circle (See).
2. The paper tilts; the cone rises from its circle, full of sand in the chapter colour. **Drag up** the empty can's
   wall beside it until it is as tall as the cone (a unit at a time): readout `4 high`. Wrong: "The can is as tall as
   the cone: 4."
3. **Pour** the cone into the can: the sand rises a third of the way; readout `1 of 3`. Pour again (the cone fills
   itself again from the side) until the can is full: `3 of 3`.
4. The paper lies flat. **Write** `3.14 × 3² = [28.26]`, `28.26 × 4 = [113.04]`, `113.04 ÷ 3 = [37.68]` (the web's
   slips: "Left out π", "Used the circumference", "A cone holds a third of a cylinder: divide by 3.").
Say: "3 cones fill the can, so one cone is a third of it."
**Core:** as the web (r 1–6, h 2–12 with r² × h a multiple of 3).

### Volume of a ball (`g8-sphere`, new; 8.G.9)
**Picture:** flat, the ball's shadow (a circle, radius named `3`) and a block beside it the can's floor, the same
circle.
1. The paper tilts and the ball rises off its circle. **Drag up** the can's wall beside it until it just covers the
   ball: readout `6 high: 2 radii`. Wrong: "The ball pokes out: the can is 2 radii tall."
2. **Pour** the ball (it melts into sand) into the can: the sand stops two thirds of the way up; readout `2 of 3`.
3. The paper lies flat. **Write** the can, as in `g8-cyl`: `3.14 × 3² = [28.26]`, `28.26 × 6 = [169.56]`; then the
   ball, `169.56 × 2 ÷ 3 = [113.04]`; then the rule as record: `V = 4/3 × 3.14 × r³`.
Say: "A ball fills two thirds of the can that fits around it."
**Core:** new. r 1–6; the first three problems r = 3 or 6 (exact to the hundredth); otherwise the answer is rounded
to the hundredth and checked to the hundredth. Slips: the can's volume given ("The ball fills only two thirds of
it."); a third of the can, as for a cone (169.56 ÷ 3 = 56.52: "A cone is a third of its can. A ball is two
thirds.").

## 10. Data in pairs (the plane's first quadrant, axes named by the data)

### Scatter plots (`g8-scatter`, new; 8.SP.1)
**One square:** across, a block (5 squares) is an hour, 0–8 (40 squares), as 5th grade's grid; up, a square is 2
points, 40–100 (30 squares, the axis broken below 40 with a small zigzag), so every score is even and every point sits
on a crossing. **Picture:** a table of the 10 pairs on the left, cells 4 × 2 squares (small text), 8 × 22; the plane
on the right a block away: about 56 × 32 in all.
1. **Place** the first three points from the table; the rest draw in.
2. **Tap** the pattern: `Up together`, `One up, one down` or `No pattern`. Wrong: "As hours go up, the points go up."
3. When one point sits far from the rest, **tap** it: it's ringed (an outlier). Wrong: "That one sits with the
   others."
Record in words: `up together`, `outlier: (2, 90)`. Say: "As hours go up, scores go up: they rise together."
**Core:** new. 8–10 points from a line plus noise (rounded to whole hours and even scores; two never share a crossing),
rising, falling or flat-random; one outlier in half the problems; from problem 9 two clusters, or a curve (scores rise
then level off: `Up, then flat`, 8.SP.1's "not straight"); first three problems a strong pattern.

### Fit a line and use it (`g8-fitline`, new; 8.SP.2–3)
**Picture:** a scatter with a clear trend, the plane as `g8-scatter` (across a block a unit, x 0–10, 50 squares; up a
square is 2, y 0–60, 30 squares), its name the story's two quantities.
1. **Lay a line** through the middle of the cloud: readout `5 above · 4 below`. Check: right when about as many points
   lie above as below (within 2) and the slope is close to the best line's. Wrong: "7 points are below it and 2 above:
   move it down."
2. **Write** the line from its handles (they snap to crossings): `slope = [2]`, `start = [10]`, `y = 2x + 10`.
3. **Use it:** drag a point along the line to 7 hours: readout `(7, 24)`; **write** `about [24]`.
Record ends with the slope's meaning in the story's words: `each hour: about 2 more points`. Say: "The line rises 2
for every hour, so each extra hour goes with about 2 more points."
**Core:** new. Data from y = mx + b plus noise (m 1–4, b 0–20, x 0–10, y kept within 0–60 and even); the handles snap
to whole x and even y; answers are judged from the child's own line (its slope and start exactly, the read value
within 2 of it, one square).

### Two-way tables (`g8-twoway`, new; 8.SP.4)
**Picture:** a 2 × 2 table with totals, cells 6 × 3 squares: rows `curfew` and `no curfew`, columns `chores` and `no
chores`, one or two cells empty; about 30 × 9 squares. Under the table (a beside-it bar would run past 68 squares),
one bar for each row, 50 squares long (a square is 2%), 4 tall, 2 apart, named by the row at the right end.
1. **Write** the empty cells: `25 − 15 = [10]`.
2. **Drag** each row bar's divider to the row's chores count; it snaps to one person's piece (2 squares for a row of
   25). Readout `15 of 25 = 60%`.
3. **Tap** the row where chores are more likely, or `About the same`. Wrong: "60% of one row, 24% of the other: not the
   same."
Record: `curfew: 15 of 25 = [60]%`, `no curfew: 6 of 25 = [24]%`. Say: "60% against 24%: curfews and chores go
together."
**Core:** new. Row totals 10, 25 or 50 (so a person is a whole number of squares); counts that make a clear link (rows
at least 25 points apart) or none (within 5); first three problems complete tables.

## Open questions for G

1. **Zero and negative exponents.** Common Core puts them in 8th grade, but the web app teaches them in 9th grade
   (`g9-negexp`, "Zero and negative exponents"). This plan folds the idea into Exponent rules. Should the 9th grade
   lesson also move into 8th grade as a lesson of its own (keeping its id, so saved progress still counts), or stay
   in 9th grade as practice?
2. **How big the plane's squares are.** With one square per unit, the paper is the plane: every strong line is a 5,
   and the numbers read straight off the paper, but a −10 to 10 plane is 20 squares, smaller than 5th grade's
   pictures. Two squares per unit doubles it, but the strong lines then fall at 2½, 5, 7½, and the web's biggest
   problems no longer fit (Slope from two points rises up to 20, Slope-intercept form's hops drop up to 25). A third
   way, as 7th grade does its lines: two squares a unit when the problem fits, one when it doesn't, so small problems
   fill the screen. Pick after seeing them in a preview.
3. **Distance between points.** The web teaches it in 10th grade (`g10-dist`), but it's 8th grade's standard (8.G.8),
   and its maths is the same as `g8-dist`'s (two points, a triple's legs, square, add, root). Move `g10-dist` into 8th
   grade as this lesson (keeping its id, so saved progress still counts) and let 10th grade write the distance
   formula and midpoints, or keep both?
4. **How much to build.** That's 39 lessons (14 from the web, 25 new), about half as many again as 5th grade. Build
   them all before 8th grade opens, or open it with fewer (for example the 14 web lessons and the new ones in their
   chapters) and add the rest as they're done?
