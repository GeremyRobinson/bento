# 7th grade on paper: every lesson's design

Claude (7th grade lesson planner), 1 Nov 2026, in the language of `README.md` and the example of `grade5.md`. Planning
only: nothing here is built yet, and each lesson still goes to G as a preview before Swift (`LESSONS.md` §9).
Reviewed the same day: small pictures made bigger so they fill the screen, Factor an expression and Surface area moved
past what 6th grade already teaches, Angle equations solved on the protractor instead of typed, and the moves 6th grade
already has called by their 6th grade names.

**Covers Common Core Grade 7 in full:** 7.RP.1–3, 7.NS.1–3, 7.EE.1–4, 7.G.1–6, 7.SP.1–8.
**38 lessons in 10 chapters:** the 13 web lessons (`web/src/curriculum/lessons/grade7`, `specs/k12/grade7.md`, checks in
`web/src/curriculum/v2/grade7.ts`), each keeping its maths (generator, ranges, easy-first start, derived values, slips,
check recipe, the spec's 13 Oct fixes) and the beats of its animated picture, and 25 new ones (`g7-<short>`). Seven
small gaps are folded into web lessons as an extra problem type or step, marked *fold*.

## Coverage

| Standard | What it asks | Lessons | |
|---|---|---|---|
| 7.RP.1 | unit rates from fractions (½ mile each ¼ hour) | Unit rates with fractions `g7-unitrate` | new |
| 7.RP.2a | proportional or not: a table, a graph through 0 | Proportional or not? `g7-isprop` | new |
| 7.RP.2b | the constant (the unit rate) in tables, graphs, words | Write y = kx `g7-constant`; one box's size in Solve a proportion `g7-prop` | new, existing |
| 7.RP.2c | the equation y = kx | `g7-constant` | new |
| 7.RP.2d | what a point means; (0, 0) and (1, r) | `g7-constant` | new |
| 7.RP.3 | many-step ratio and percent: interest, tax, markups and markdowns, tips, up and down, percent error | `g7-prop`; Discounts, tax and tips `g7-discount` + *fold*: markups; Percent change `g7-pctchange` + *fold*: percent error; Simple interest `g7-interest` | existing, new |
| 7.NS.1a | opposites make 0 | Adding integers `g7-addint` + *fold*: the hop splits at 0 | existing |
| 7.NS.1b | p + q is a hop of q from p | `g7-addint`; Negative fractions and decimals `g7-addrat` | existing, new |
| 7.NS.1c | taking away is adding the opposite; distance is the size of the difference | Subtracting integers `g7-subint` + *fold*: how far apart; `g7-addrat`; Problems with negatives `g7-ratstory` | existing, new |
| 7.NS.1d | the rules of + used to add and take away | `g7-addrat` (cancel a pair first) | new |
| 7.NS.2a | multiplying signed numbers; (−1)(−1) = 1 | Multiplying and dividing integers `g7-mulint` | existing |
| 7.NS.2b | dividing; −(p/q) = (−p)/q = p/(−q) | `g7-mulint`; Negative fractions: × and ÷ `g7-mulrat` | existing, new |
| 7.NS.2c | the rules of × used to multiply and divide | `g7-mulrat` | new |
| 7.NS.2d | long division: a decimal stops or repeats | Fractions to decimals `g7-decimal` | new |
| 7.NS.3 | problems with all four operations | `g7-ratstory` | new |
| 7.EE.1 | add, take away, factor, expand, any coefficients | Distribute and combine `g7-distribute`; Minus signs in expressions `g7-negexpr`; Factor an expression `g7-factor` | existing, new |
| 7.EE.2 | rewrite to see it: + 5% is × 1.05 | `g7-discount` + *fold*: its last line; `g7-factor` (its last kind) | existing, new |
| 7.EE.3 | many steps, numbers in any form, estimating | `g7-ratstory`; Write the equation `g7-eqstory` | new |
| 7.EE.4a | px + q = r and p(x + q) = r from stories; the sum way beside the equation | Two-step equations `g7-eq`; Equations with parentheses `g7-eqparen`; `g7-eqstory` | existing, new |
| 7.EE.4b | px + q > r, drawn on a line | Two-step inequalities `g7-ineq` | new |
| 7.G.1 | scale drawings: lengths, areas, redrawing | Scale drawings `g7-scale`; Redraw at a new scale `g7-redraw` | existing, new |
| 7.G.2 | triangles from three parts: one, many or none | Can it be a triangle? `g7-triangle` | new |
| 7.G.3 | slices of boxes and pyramids | Slicing solids `g7-slice` (3D) | new |
| 7.G.4 | circumference and area, and why they're linked | Circumference `g7-circum`; Area of a circle `g7-circarea` + *fold*: the wedges; Half circles in shapes `g7-circparts` | existing, new |
| 7.G.5 | complementary, supplementary, vertical, adjacent; equations | Complementary and supplementary `g7-angles`; Angles where lines cross `g7-vertical`; Angle equations `g7-angleeq` | existing, new |
| 7.G.6 | area, volume, surface area of prisms and shapes made of parts | Volume of a prism `g7-prismvol` (3D); Surface area of a prism `g7-surface` (3D); `g7-circparts` | new |
| 7.SP.1 | samples; random samples are fair | Guess from a sample `g7-sample` | new |
| 7.SP.2 | guesses from samples, and how much they vary | `g7-sample` | new |
| 7.SP.3 | two groups' overlap; the gap in MADs | Compare two groups `g7-compare` | new |
| 7.SP.4 | comparing groups by center and spread | `g7-compare` | new |
| 7.SP.5 | chance from 0 to 1 | Probability `g7-prob` + *fold*: the chance line | existing |
| 7.SP.6 | chance from many trials; predicting | Chance from trials `g7-trials` | new |
| 7.SP.7 | a model: equally likely, or from data; model against data | `g7-prob` (equally likely); `g7-trials` | existing, new |
| 7.SP.8 | compound chance: lists, tables, trees, runs | Two at once `g7-compound` | new |

**Grade boundaries.** 6th grade keeps ratios and whole-number unit rates, percent of a number and the whole, negatives on
a line, opposites and absolute value (folding at 0), the four-quadrant plane, one-step equations, x > c on a line, the
distributive property and factoring with whole numbers (`g6-equiv`: 3(x + 4) = 3x + 12, 6x + 9 = 3(2x + 3)), areas of
triangles and polygons, nets of boxes, triangular prisms and pyramids (`g6-nets`), and mean, median, MAD and IQR; 7th
grade uses them. So `g7-factor` starts at minus signs and halves, and `g7-surface` at solids made of parts. 8th grade
(`grade8.md`) keeps slope (7th grade says "for 1 pound", never slope), functions, x on both sides, a triangle's angles
adding to 180°, parallel lines, Pythagoras, round solids, repeating decimals back to fractions (`g8-repeat` starts where
`g7-decimal` ends), two-way tables of data and dilations. From 5th grade's plan: points on a grid (`g5-coord`) and
fractions as division (`g5-fracdiv`), used here as known.

## Chapters (teaching order)

New lessons are marked *.

| # | Chapter | Lessons |
|---|---|---|
| 1 | Proportions | Solve a proportion · Unit rates with fractions* · Proportional or not?* · Write y = kx* · Scale drawings · Redraw at a new scale* |
| 2 | Percents | Discounts, tax and tips · Percent change · Simple interest* |
| 3 | Adding negatives | Adding integers · Subtracting integers · Negative fractions and decimals* |
| 4 | Multiplying negatives | Multiplying and dividing integers · Negative fractions: × and ÷* · Fractions to decimals* · Problems with negatives* |
| 5 | Expressions | Distribute and combine · Minus signs in expressions* · Factor an expression* |
| 6 | Equations | Two-step equations · Equations with parentheses* · Write the equation* · Two-step inequalities* |
| 7 | Angles and triangles | Complementary and supplementary · Angles where lines cross* · Angle equations* · Can it be a triangle?* |
| 8 | Circles | Circumference · Area of a circle · Half circles in shapes* |
| 9 | Solids (3D) | Slicing solids* · Volume of a prism* · Surface area of a prism* |
| 10 | Chance and samples | Probability · Chance from trials* · Two at once* · Guess from a sample* · Compare two groups* |

## What every 7th grade lesson shares

As in 5th grade: instruction on rows 0–2 (28), a miss on rows 3–4 (20, red), the picture from row 6 with its names at its
right end, the record 3 rows under it (36, 2 squares a digit), the blocks under the record. The iPad is about 68 × 45
squares; about 64 × 40 hold a problem once the bar and the margins are off (`ProblemGrid`), so pictures here stay near
60 × 26 at 100%, and a bigger problem has the camera step back, never past what a child can count. The first words never
repeat the problem; the last line says why. Answers in the chapter colour; red and green only for wrong and right. Steps
answered by a hand move set their Core box from the move (`LessonRun.set`), so Core's checks and slip messages stay;
typing is only for the number school writes. Show me and the How to play each move with the ghost finger and put
everything back.

- **Negative is striped.** Positive hops, squares and tiles are solid in the chapter colour; negative ones are the same
  colour striped. A striped piece slid onto a solid one the same size cancels it, and both go. (Open question 2.)
- **The balance**, as 8th grade's plan draws it: a level beam, two pans on whole blocks; an x is a tile 2 squares wide and
  5 tall marked `x`, a 1 is a square, ten is a strip of 10. One square is 1, so both pans really hold the same.
- **Slanted and round lines start on the grid.** An angle's corner, a circle's middle and a stick's hinge sit on grid
  crossings, and their own ticks are the grid there: a protractor drawn on the paper, a tick every degree, longer every
  5° like the paper's strong lines. (8th grade's plan reads angles on a lighter half circle, radius 12 with a tick every
  10°; 7th grade needs every degree. One drawing for both once the first angle lesson is previewed.) (Open question 3.)
- **The plane** (Proportions) is first quadrant only, the axes on strong lines: across, a block a unit, as 5th grade's
  grid (so a few x's fill the width); up, a square a unit, numbered every 5 (8th grade's plane is a square a unit both
  ways, for slope).
- **Typing** needs a minus key (−7), a fraction as a box over a box (as Adding fractions) and the repeating bar (0.3̄).
- **3D** (Solids) is Unit cubes: flat first, the paper tilts as the maths rises, words face the child, flat again before
  leaving.
- **Trials** (Chance) come from the problem's own seed, so the counts and the answers come from the same numbers as the
  picture.

**Moves not yet in the kit table of `README.md`** (several are 6th or 8th grade's, and keep their names; each comes with
the first lesson that uses it, after G sees its preview):

| Move | What the finger does; the live readout | Used by |
|---|---|---|
| Place a point (5th, 6th and 8th grade's) | tap or drag to a crossing on a line or the plane; it snaps; `(2, 6)`, `−4.5°` | isprop, ratstory |
| Lay a line (8th grade's, one handle held on 0) | drag the free handle; the line pivots on (0, 0) and snaps through crossings; `through 4 of 4 points` | isprop |
| Drag a length (`LESSONS.md`'s) | pull a bracket, an arrow or a bar's end along the grid; it snaps to squares; `25% = $20`, `gap 10` | discount, pctchange, interest, ineq, ratstory, circum, circparts, prob, compare |
| Flip over 0 (6th grade's Fold at 0, done to one piece; 8th grade's Flip over a line) | drag a hop, arrow or group over the 0 line; it turns over like a card and lands mirrored, solid ↔ striped; `−3 → +3` | subint, addrat, mulint, mulrat, negexpr, factor |
| Turn a ray | drag an arm, a line or a stick round its corner; it snaps to whole degrees on the protractor, or where its end lands on a crossing; `145°`, `gap 3` | angles, vertical, triangle |
| Take the same off both sides (8th grade's), or put the same on | drag a group off one pan (or onto it); its twin leaves (or joins) the other pan; `− 5 from both: 15 left` | eq, eqparen, eqstory |
| Share into rows (6th grade's: `g6-onestep` and `g6-equiv` drag the rows' edge) | drag a group's handle to how many rows; its squares re-deal, the count kept; `3 rows of 5`. On a protractor the same move shares an arc into equal wedges | eq, eqparen, eqstory, mulint, factor, angleeq |
| Unroll | drag a circle's edge along a grid line; it peels off and lies flat | circum, circparts |
| Run trials | tap `10 more` or `100 more`; trials land one by one as squares in their outcome's column; `60 rolls: 3 came up 11 times` | trials, compound, sample |
| Pick (6th and 8th grade's) | tap one of two or three answer words drawn as blocks in the record | isprop, constant, triangle, trials, sample, compare |
| Slide the sheet (3D) | drag a see-through sheet through a solid; the cut face lights and reads its size; `4 × 3 rectangle` | slice |
| Unfold a face (3D; 6th grade's Fold, run the other way) | tap or drag a face; it hinges flat onto the paper; `5 × 4 = 20` | surface |

Reused from the kit: cut with the ruler (prop, unitrate, discount, pctchange, mulrat, ratstory) or across a shape as
Multiply two-digit numbers cuts (distribute, circparts, prismvol), slide pieces (addrat, distribute, negexpr, factor,
circarea, circparts, eqstory), tap pieces (interest, mulrat, prob, compound), tap a block that opens (decimal, compound),
drag a point along a line (constant, addint, subint, addrat, ratstory, ineq, angles, angleeq, prob), hop (unitrate,
scale, mulrat, factor, ratstory, circum, circparts, compare), drag a rectangle's edge or corner (redraw, mulint, decimal,
circarea, prismvol), tap the part (angleeq), cover the floor and build the layers (slice, prismvol), Turn (`LESSONS.md`'s, surface), write.

## 1. Proportions

### Solve a proportion (`g7-prop`, existing; 7.RP.2–3)
**One square:** 1 (2 squares a unit when a box is a half, as in 6/4 = x/10, so every box is still whole squares).
**Picture:** two bars 3 squares tall and 2 apart, left ends on a strong line: the bottom bar B squares long and whole, the
top bar an empty dashed outline with a handle at its right end. The problem is written once, around the bars: a over b
at their left ends (a level with the top bar, b with the bottom, the fraction's line between them), x over B at their
right ends. Up to 72 squares long, about 84 with the names; past 60 the camera steps back, to about 80% for the biggest.
1. **Cut** the bottom bar into b equal boxes with the ruler (it snaps to lengths that divide B; readout `4 boxes of 5`).
   Wrong: "That's 5 boxes. The bottom is 4 boxes." Right: the cuts turn solid and every box shows its size, `5` (the
   web's one-part step, answered by the cut).
2. **Drag** the top bar's handle; it snaps a box at a time and fills; readout `3 boxes: 15`. Wrong: "That's 4 boxes. The
   top is 3." Right: each top box shows `5` too, and the x at its end lights.
3. **Write** `20 ÷ 4 = 5` (from the cut), `x = 3 × 5 = [15]`.
Say: "Every box is the same size, so 3 boxes are 3 × 5."
**Core:** the web's generator as it is (a 1–9, b 2–9, a ≠ b, k 2–8; from problem 5, 6 in 10 have a half box: a and b even
2–8, k 1.5–4.5). Slips kept: added instead of scaled (B − b at the first step, a + B − b at the second), multiplied instead
of divided (B × b), added the part (a + k). Check as the spec: i0; a > b; a half box, twice.

### Unit rates with fractions (`g7-unitrate`, new; 7.RP.1)
**One square:** a whole of the per-thing (1 hour, 1 can, 1 cup) is 48 squares, the fraction bars' whole, so halves to
twelfths are whole squares; when the line runs on to 1½ the whole is 36 (no eighths then), so the line is never over 54.
**Picture:** a double line from a strong line: the top counts hours from 0 to 1 (or 1½), a tick at every piece the
problem uses; the bottom, 4 rows under it, counts miles, marked where hops end. The problem is one hop drawn on both
lines from 0 and named: `¼ h` over it, `½ mi` under it.
1. (When the hop is more than one piece, `⅔ mi` in `¾ h`) **Cut** it with the ruler into pieces that build an hour;
   readout `3 pieces: ¼ h and 2/9 mi each`. Pieces that can't: "⅜ hours don't make 1 hour. Try smaller pieces." Smaller ones that
   fit: "Those fit. Bigger pieces fit too."
2. **Hop** the piece along both lines from 0 (tap to add a hop, or drag; hops snap to its length and are numbered);
   readout `4 hops: 1 h, 2 mi`. Past 1: "That's past 1 hour." Short, on release: "Keep going to 1 hour."
3. See: 1 hour and the miles under it light together, `1 h → 2 mi`.
4. **Write** the fraction over a fraction as school does, then the rate: `(½)/(¼) = ½ × 4 = [2]` miles per hour.
Say: "An hour is 4 quarter hours, so 4 halves of a mile."
**Core:** new; builds on g6-rate and g6-divide. Stories: walking or biking (miles per hour), painting (walls per can), a
recipe (cups of sugar per cup of flour), mowing (lawns per hour). Problems 1–3: the per-thing ½, ⅓ or ¼, the other ½, ⅔,
¾ or 1½; 4–6: the per-thing ⅔, ¾ or ⅚ (the cut comes in); 7+: either one a mixed number. The answer (a/b) ÷ (c/d) in
simplest form, a mixed number when it's over 1. Slips: flipped ("That's hours for 1 mile. Hop to 1 hour."); multiplied
("That's less than one hop. An hour holds 4 hops."); not simplest ("Write it as simply as you can."). Check: two with a
one-piece hop, two with a cut.

### Proportional or not? (`g7-isprop`, new; 7.RP.2a)
**One square:** 1 up; across, a block (5 squares) is 1, as in 5th grade's grid, so every x is a strong line.
**Picture:** a table at the left (4 rows; the story's names over its two columns, `pens | $`); the plane at the right,
first quadrant, x 0–8 (40 squares) and y 0–24. About 54 × 27.
1. **Place a point** for each row (tap a crossing; it snaps; readout `(2, 6)`); its row ticks. Wrong: "That's (2, 5). Up
   6." (Problems 1–2 come with two points placed.)
2. **Lay a line** from 0: one handle stays on (0, 0); drag the other; it snaps through crossings; readout `through 4 of 4
   points`.
3. **Pick** in the record: `Proportional` or `Not proportional`. Wrong: "The line from 0 goes through all 4. It's
   proportional." / "No line from 0 goes through (1, 7) and (2, 10)." When the points line up but miss 0, a dashed line
   through them shows where it meets the y axis: "They line up, but start at 4, not 0."
4. **Write** a third column, y ÷ x: `6 ÷ 2 = [3]`, the rest written by the paper (`3, 3, 3` or `7, 5, 4.3`).
Say: "y is always 3 × x, so the line goes through 0." / "It starts at 4, so it's not proportional."
**Core:** new; builds on g5-coord and g6-ratio. Kinds: y = kx (k 1–4, or 1½ and 2½ with x even); y = kx + b (b 1–5); one
row off; y = x × x (curved). x 1–8, rising; y up to 24. Problems 1–3 y = kx or kx + b with b ≥ 3; 4–6 one row off; 7+ the
halves and the curve. Stories: pens and cost, laps and minutes, a plant 4 cm tall when it starts, a taxi with a $3
start. Slip: proportional chosen for kx + b ("4 more each time, but it starts at 4."). Check: one of each kind.

### Write y = kx (`g7-constant`, new; 7.RP.2b–d)
**One square:** the plane as `g7-isprop`: across a block a unit (x 0–8), up a square a unit (y 0–25; 2 squares a unit,
y 0–12, when k is a half, so every point sits on a crossing). **Picture:** the plane with a line from 0 through
what's given, and the given beside it, one of four ways: a named point on the line (`(3, 12)`), a table of 2–3 rows, a
sentence ("3 pounds cost $12"), or an equation (`y = 2.5x`).
1. **Drag the point** along the line to x = 1 (it snaps at each whole x); readout `(1, 4): 1 pound,
   $4`. Wrong: "That's 2 pounds. Find 1 pound."
2. **Write** `k = 12 ÷ 3 = [4]`, then `y = [4]x`, with the story's words under it: `cost = 4 × pounds`.
3. See: (0, 0) and (1, 4) ring with what they mean: `0 pounds, $0` and `1 pound, $4`.
4. (From problem 4) **Pick** what another point says: (5, 20) is `5 pounds cost $20` or `20 pounds cost $5`.
The equation kind drags to the x asked (`x = 4`) and writes y.
Say: "1 pound costs $4, and every pound adds the same $4."
**Core:** new; builds on g7-isprop and g6-rate. x up to 5 (so y fits). Problems 1–3 a named point, k 2–5; 4–6 tables, k
a half (1½, 2½, ½);
7+ sentences and equations. Slips: flipped, x ÷ y ("That's pounds for $1. For 1 pound: 12 ÷ 3."); took the difference,
12 − 3 ("k multiplies: 3 × 4 = 12."). Check: one from each way.

### Scale drawings (`g7-scale`, existing; 7.G.1)
**One cm on the map:** a block (5 squares) while the road is 12 cm or less, as in the first problems; 2 squares past
that. So the road is 10–64 squares long and the map fills the screen. **Picture:** a strip of map: two towns as dots, A
and B, on one row c × g cm apart (up to 32 cm); the scale bar in the map's corner, c cm long, `2 cm = 5 km` under it (the
problem's own names); a second line 3 rows under the road for the real km, empty.
1. **Hop** the scale bar along the road from A (tap to add a hop, or drag; each hop is c cm and numbered); readout
   `4 hops: 8 cm`. Past B: "That's past town B." Short: "Keep going to town B." Answers the groups step.
2. See: under each hop, on the real line, `5 km` appears hop by hop and the total counts on, 5, 10, 15, 20 km (the web's
   second beat).
3. **Write** `8 ÷ 2 = 4` (from the hops), `4 × 5 = [20]` km.
Say: "Each 2 cm is 5 km, and there are 4 of them."
**Core:** the web's generator as it is (problems 1–3: c 1–2, km 2–5, g 2–4; then c 1–4, km 2–9, g 2–8), with the spec's
step name "How many groups?". Slips kept: multiplied, c × g × c ("Count how many 2 cm groups fit: that's dividing.");
skipped a step, c × g × km ("Each 2 cm, not each 1 cm, is 5 km."). Check as the spec.

### Redraw at a new scale (`g7-redraw`, new; 7.G.1)
**One square:** what each drawing's scale says. **Picture:** the plan at the left (a rectangle or an L-shaped room on grid
lines, up to 8 × 6 squares) with `1 square = 2 m` under it; 4 squares to its right, the copy's first corner with `1
square = 1 m` under it. Up to about 36 × 20.
1. **Drag the copy's corner** (two corners for an L; the sides snap to squares); readout `6 × 4 squares: 6 m × 4 m`.
   Wrong: "The plan's side is 3 squares, 6 m. At 1 m a square, that's 6 squares."
2. See: one square of the plan opens into the copy's 2 × 2 squares; both drawings count, `6 squares` and `24 squares`.
3. **Write** `6 m × 4 m = [24]` m²; then the rule as record: `1 plan square = 2 m × 2 m = 4 m²`, `6 × 4 = 24`.
Say: "Twice as long and twice as wide: every square becomes 4."
**Core:** new; builds on g7-scale and g4-area. Problems 1–3 grow ×2 or ×3 (rectangles); 4–6 shrink (1 m to 2 m a square,
so the plan's sides are even) and L shapes; 7+ the area from the plan alone ("10 squares at 3 m a square": 10 × 9 = 90
m²). Copies up to 24 × 18. Slips: × 2 for the area ("Each plan square is 2 m by 2 m: 4 m²."); squares taken as meters
("3 squares at 2 m each is 6 m."). Check: grow, shrink, an L, the area from the plan.

## 2. Percents

### Discounts, tax and tips (`g7-discount`, existing; 7.RP.3, and 7.EE.2 in its last line)
**One square:** 2.5% of the price; the price bar is 40 squares (100%), 4 tall. **Picture:** the bar, named `$80` at its
right end; hanging at that end, the deal's name on a dashed bracket with no length yet: `25% off` (or `15% tip`, `10%
tax`, `30% markup`). At most 60 squares (50% on).
1. **Cut** the bar into equal blocks with the ruler (lengths that divide 40: 5%, 10%, 20%, 25% or 50% blocks); readout
   `20 blocks of $4`. For a discount the deal's end is an old cut, its dot green when a cut lands on it. Blocks the deal
   isn't made of: "25% isn't a whole number of 10% blocks. Try another size." Right: every block shows its dollars.
2. **Drag** the bracket (a length: back from the end for off, out past it for on, the bar growing a block at a time);
   readout `25% = $20`. Wrong: "That's 20%. The deal is 25%." Answers the percent step.
3. See: off, the bracketed blocks are struck through and fade and the rest counts, `$60`; on, the new blocks fill and the
   longer bar counts, `$92` (the web's beats).
4. **Write** `25% of $80 = $[20]`, `$80 − $20 = $[60]`; then, *fold* (7.EE.2), the rule as record written by the paper:
   `= 75% of $80 = 0.75 × $80` (on: `= 115% of $80 = 1.15 × $80`): one step does it.
Say: "25% off leaves 75% of the price." / "A 15% tip makes it 115% of the price."
**Core:** the web's maths with the spec's tax (off half the time, the other half tip or tax; tax 10, 15 or 20%; $20–200
in 20s; the web's rates). *Fold, markups* (7.RP.3): the on half gets a third word, `markup` (tip, tax and markup a sixth
each; a markup is a tip's maths). Slips kept: multiplied by the percent; found the new price at the first step; added the
discount / subtracted the tip / subtracted the tax. Check as the spec.

### Percent change (`g7-pctchange`, existing; 7.RP.3)
**One square:** 2.5% of where it started; the `was` bar is 40 squares. **Picture:** the was bar and, 2 under it, the `now`
bar (40 ± 0.4p squares: up to 70 for +75%, when the camera steps back to about 88%); left ends on one strong line, names
at the right ends, `60` and `75`.
1. **Drag** the change bracket between the two ends (a length; it snaps to squares); readout `15`. Wrong: "Stretch it
   from 60 to 75." Answers the change step.
2. **Cut** the was bar with the ruler into blocks the change is made of; readout `4 blocks of 15: the change is 1 of
   them`. Blocks that don't fit the change: "15 isn't a whole number of those."
3. **Write** `75 − 60 = 15`, `15 ÷ 60 = [0.25]`, `0.25 = [25]%`; the now bar's name gets `+25%` (the web's last beat).
Say: "15 is a quarter of 60, where it started: up 25%."
*Fold, percent error* (7.RP.3): from problem 7, one in three is a guess against the real count ("Ana guessed 45 beans.
There were 60."): bars `real` and `guess`, the same moves, `15 ÷ 60 = 0.25`: a 25% error. Say: "Her guess was off by a
quarter of the real count." Its slip, divided by the guess, is the web's "Divided by the new number".
**Core:** the web's generator as it is (p 10, 20, 25, 50 or 75; O from its list, 20–200; up half the time), plus the error
kind. Slips kept: added; divided by the new number; kept the decimal; moved the point one place. Check as the spec.

### Simple interest (`g7-interest`, new; 7.RP.3)
**One square:** a cell of 2 × 2 squares is 1% of the money. **Picture:** the money as a 10 × 10 grid of cells (20 × 20
squares), named `$500`; 2 squares to its right the years, `4% a year · 3 years`, over an empty row of year columns. About
36 × 22.
1. **Tap** cells to shade one year's interest; readout `4% = $20`. Wrong: "That's 5%. One year is 4%."
2. **Drag** the year out (a length): each year lays a copy of the 4 cells as a column to the right; readout `3 years: 12% =
   $60`. Wrong: "That's 2 years."
3. **Write** `I = 500 × 0.04 × 3 = [60]`; when the total is asked, `500 + 60 = [560]`.
How long ("How many years to earn $60?"): drag years until the readout says $60.
Say: "Every year adds the same 4% of $500."
**Core:** new; builds on g7-discount and g6-pctof. P $100–2,000 in hundreds (a cell is whole dollars), rate 2–8%, 1–6
years. Problems 1–3 interest over 1–2 years, P up to $500, rate 2–5%; 4–6 totals; 7+ how long. Slips: 4 for 0.04 ("4% is
4 hundredths: 0.04."); one year only ("That's one year. 3 years: 3 × $20."); the total when the interest was asked
("That's the money and the interest. The interest alone is $60."). Check: interest, total, how long, 4 years or more.

## 3. Adding negatives

### Adding integers (`g7-addint`, existing; 7.NS.1a–b)
**One square:** 1 (2 squares a one when the line spans 24 or fewer, so short problems still fill the width).
**Picture:** the line on a strong row, a tick every one, numbers on the strong lines, 0 bold; it spans a, the sum and 0
with a one to spare (at most 50 squares). The start a is a dot with its name; the hop's name (`+12`,
`+ (−5)`) waits over it. Hops right are solid, hops left striped.
1. **Drag** the point from a (a point along a line, snapping to squares); a hop arcs behind it and its steps count under a
   bracket; readout `12 right`. Wrong way: "Adding −5 moves left." Wrong size: "That's 11 steps. Move 12."
2. See, *fold* (7.NS.1a): a hop across 0 splits there; the part back to 0 rings with the start, "−7 and 7 make 0", and
   the rest is what's left, `5`. A hop away from 0 runs on and the bracket spans both, `7 + 5 = 12 from 0`. Answers the
   size step.
3. **Write** `−7 + 12 = [5]`.
Say: "7 of the steps cancel the −7. 5 are left, to the right." / same signs: "Both are negative, so the answer is
negative." / equal sizes: "Opposites cancel: 0."
**Core:** the web's generator as it is (a and b −15 to 15, not 0, not both positive). Slips kept: subtracted the sizes;
added the sizes; wrong sign, in the spec's words (never "two negatives make a negative"). Check as v2: both negative; signs
different with the sum above 0; the sum below 0, each order.

### Subtracting integers (`g7-subint`, existing; 7.NS.1c)
**One square:** 1; the line as `g7-addint`, spanning a, b, its opposite, a − b and 0. **Picture:** the dot a; under the
line, b drawn as an arrow from 0 (striped when negative), named `− (−3)`: what's taken away (the web's hollow mark at b).
1. **Flip over 0** (new move): drag the arrow's head over 0; it turns over like a card and lands mirrored, striped ↔ solid;
   readout `−3 → +3`. Dropped anywhere else: "Flip it over 0: the same size, the other way." Answers the opposite step.
2. **Drag** the point from a by the flipped arrow (as `g7-addint`); readout `3 right`. Wrong: "That's the arrow before the
   flip. Use the flipped one."
3. See, *fold* (7.NS.1c): a bracket from b to a under the line, `8 apart`: the difference is the distance.
4. **Write** `5 − (−3) = 5 + 3 = [8]`.
Say: "Taking away −3 is the same as adding 3." (b positive: "Taking away 4 is adding −4.")
**Core:** the web's generator as it is (problems 1–3 a 1–6 minus −1 to −5; then a and b −12 to 12, not 0). Slips kept:
kept the same sign; forgot to change the sign; wrong sign. Check as the spec.

### Negative fractions and decimals (`g7-addrat`, new; 7.NS.1b–d)
**One square:** a tenth (decimals: a whole is 10 squares, two strong lines) or a twelfth (fractions: a whole is 12 squares,
so halves, thirds, quarters and sixths are whole squares). **Picture:** the line as `g7-addint`, numbered at the wholes, at
most 60 squares (6 wholes of tenths, 4 of twelfths).
1. **Drag** the hop from the start (as `g7-addint`); readout in the problem's own pieces, `3.2 right`, `2½ right`. Taking
   away: **flip over 0** first, as `g7-subint`.
2. (Three numbers, from problem 7; 7.NS.1d) **Slide** the hop that cancels onto its opposite (slide over to take away):
   "−2.5 and 2.5 make 0"; both go and one hop is left. A pair that doesn't: "−2.5 and 3 don't make 0."
3. See: the split at 0, as `g7-addint`: "7 quarters cancel; 3 are left."
4. **Write** `−1.5 + 3.2 = [1.7]`, or `−1¾ + 2½ = −7/4 + 10/4 = [3]/[4]`.
Say: "Quarters hop like ones: 7 quarters cancel and 3 are left."
**Core:** new; builds on g7-addint, g7-subint and add. Problems 1–3 tenths, one number negative, sizes to 3; 4–6 halves,
thirds, quarters or sixths, sizes to 2; 7+ taking away, and three numbers with a pair that makes 0. Slips: wrong sign;
added the sizes; added the bottoms ("Same-size pieces: quarters with quarters."); no flip ("Taking away −1½ is adding
1½."). Check: a decimal, a fraction, a take-away, three numbers.

## 4. Multiplying negatives

### Multiplying and dividing integers (`g7-mulint`, existing; 7.NS.2a–b)
**One cell:** 1, a cell 2 × 2 squares. **Picture:** a 0 line down a strong column, `0` at its top. A jump of |a| is a
row of |a| cells; the jumps stack as rows from the 0 line, right of it positive (solid), left negative (striped). The web
lays the jumps along a number line; 12 jumps of 12 can't fit there, so on paper they stack (at most 12 × 12 cells each
side: 49 × 24 squares with both sides), and the flip across 0 is the web's own beat. The problem's name over it:
`−6 × 4`.
1. **Drag the corner** of the jumps out from the 0 line, to the right first (the sizes: the web's "Ignore the signs"); it
   snaps to cells; readout `4 jumps of 6: 24`. Wrong: "That's 5 jumps. Make 4." Dividing (`−24 ÷ 4`): the 24 cells
   lie in rows of 20 (144 is 8 rows); **share into rows**, dragging its handle down to 4: `4 rows of 6`. Answers the
   size step.
2. **Flip over 0** once for each negative number in the problem (the jumps turn over the 0 line and land mirrored);
   readout `−24`, then `24`; then **Done**. Wrong: "−6 × −4 has two negatives: flip twice." / "4 × 6 has no negative: no
   flip."
3. **Write** `−6 × 4 = [−24]` (or `−24 ÷ 4 = [−6]`).
Say: "One negative flips it across 0." / "Two negatives flip it over and back."
**Core:** the web's generator as it is (problems 1–3 sizes to 5, then to 12; ÷ half the time). Slips kept: added;
multiplied (on ÷); wrong sign. Check as v2 (the four sign cases, sizes 2 or more).

### Negative fractions: × and ÷ (`g7-mulrat`, new; 7.NS.2a–c)
**One square:** for ×, Multiplying fractions' whole square, its side the smallest multiple of both bottoms that's 20 or
more (30 at most, for fifths with thirds or sixths), so it and its mirror fit in 61 squares; for ÷ and the ways to
write, a line with a whole of 16 squares (halves, quarters, eighths), −3 to 1 at most (64 squares). **Picture:** the
whole square right of a 0 line (as `g7-mulint`), a/b down its left side and c/d along its top, signs and all.
1. Sizes as in Multiplying fractions: **cut** b rows with the ruler and **tap** a of them; **cut** d columns and **tap** c
   of them; the pieces shaded twice count, `6 of 12`.
2. **Flip over 0** once for each negative: the twice-shaded part turns over the 0 line; readout `−6/12`.
3. **Write** `−3/4 × 2/3 = [−6]/[12] = [−1]/[2]`.
Dividing, on the line: by a whole whose top shares evenly, `−3/4 ÷ 3`: **cut** the hop to −3/4 into 3; one part ends at
−1/4. A whole by a unit
fraction, `−2 ÷ ¼`: **hop** quarters from 0 to −2, 8 of them; one negative: `−8`.
Three ways to write it (7.NS.2b): **cut** the hop from 0 to −3 into 4 equal parts; the first ends at −3/4. The record lists
`−(3/4)`, `(−3)/4`, `3/(−4)` and `(−3)/(−4)`; **tap** the ones that name the point. Wrong: "(−3)/(−4) has two negatives.
It's 3/4."
Say: "The pieces give the size; the negatives give the sign."
**Core:** new; builds on g7-mulint, g5-multfrac and g5-unitdiv. Problems 1–3 one negative, bottoms 2–4; 4–6 two negatives,
bottoms to 6; 7+ dividing and the ways to write. Slips: wrong sign; for ÷, divided the wrong way ("How many quarters make
−2?"). Check: one of each kind.

### Fractions to decimals (`g7-decimal`, new; 7.NS.2d)
**One square:** one piece of the place being shared. **Picture:** the stock at the left (n wholes as n blocks); to its
right d rows, one per share, each 2 squares tall; then place columns two blocks (10 squares) wide, so a column holds a
share's 9 pieces in a row (ones when n ≥ d, tenths, hundredths, thousandths…), their names over them, so each share's
row reads its decimal across. The long division bracket under it is the record, `8)3.000`. At most 12 rows (24 squares)
and about 56 across.
1. **Tap** the stock: each whole opens into ten tenths (tap a block, it opens into ten); `30 tenths`.
2. **Drag** the shares' edge across the tenths column (Long division's move); each share takes one more each step; readout
   `3 each: 24 used, 6 left`. Past: "That's more than 30." Release at the most that fits; the 3 is written over the
   bracket.
3. **Tap** what's left: 6 tenths open into 60 hundredths; drag again, `7 each: 56 used, 4 left`; open again, `5 each: 40
   used, 0 left`.
4. It ends when nothing is left ("Nothing left: it stops.") or when a leftover comes back: both ring, "1 left again: the
   same digits come again", and a bar goes over them.
5. **Write** `3/8 = 3 ÷ 8 = [0.375]`, or `1/3 = 0.333… = 0.[3]` (the digits under the bar typed).
Say: "Nothing left over, so the decimal stops." / "The same 1 is left every time, so the 3s never stop."
**Core:** new; builds on g5-divide and g5-fracdiv. Problems 1–3 stop (d 2, 4, 5); 4–6 one digit repeats (d 3, 6, 9); 7+
eighths, elevenths (`0.1818…`), twelfths (`0.0833…`, repeating after a start) and more than 1 (`5/4 = 1.25`). Slips:
divided the wrong way, 8 ÷ 3 ("3/8 is 3 shared by 8."); stopped too soon, 0.33 ("1 is left again: it doesn't stop.").
Check: one that stops, two that repeat, one over 1.

### Problems with negatives (`g7-ratstory`, new; 7.NS.3, 7.EE.3, 7.NS.1c)
**One square:** ½ (a whole is 2 squares). **Picture:** a line standing up (a thermometer in °F, a cliff above the sea, a
bank account), about 30 squares tall, 0 bold (0°, sea level, $0), numbered every 2 squares on one side, the story's names
on the other. The camera steps back a little for the tallest.
1. **Place a point** for the start (it snaps to halves); readout `−4.5°`. From problem 7, first **place** a guess where it
   will end.
2. **Drag** each change in turn as a hop up or down (snapping to halves); readout `+7.5`, `−3.5`. A change that repeats
   ("falls 1.5° an hour for 3 hours") is **hopped** 3 times, `3 hops of −1.5 = −4.5`; a share ("$12 owed, split 4 ways")
   **cuts** the hop into 4.
3. How far apart: **drag** a bracket from one point to the other, `8.5 apart`.
4. **Write** as school does: `−4.5 + 7.5 − 3.5 = [−0.5]`, `3 × (−1.5) = [−4.5]`, `|5 − (−3.5)| = [8.5]`; a guess gets
   `close` or `far` written by it.
Say: "Up 7.5 and down 3.5 is up 4 in all." / "How far apart is never negative."
**Core:** new; builds on g7-addrat and g7-mulint. Halves and wholes, −7 to 7. Problems 1–3 two changes; 4–6 a repeated
change (×) or a share (÷); 7+ how far apart, and three changes after a guess. Slips: wrong sign; added a drop ("It fell:
that's − 3.5."); a negative distance ("How far is never negative."). Check: two changes, a repeat, a share, how far apart.

## 5. Expressions

### Distribute and combine (`g7-distribute`, existing; 7.EE.1)
**One cell:** 1 (area), a cell 2 × 2 squares while a + c is 12 or less, a square past that; x is drawn X long (the web's:
the biggest of a, b and c, plus 3) with a break mark, so it isn't counted. **Picture:** the a(x + b) rectangle, a rows
tall and x + b wide, `3` down its left and `x + 4` over its top; a row under it the cx strip, c rows of x, named `2x`
(the web's second row). At most 42 × 26 squares.
1. **Cut** down where x ends (it snaps only to the line between x and b; readout `x | 4`); the parts move a square apart
   and name themselves, `3x` and `3 × 4`. Wrong: "Cut where x ends." Answers the distribute step.
2. **Write** `3(x + 4) = 3x + [12]` (the 12 counted on the grid).
3. **Slide** the 2x strip up under the 3x part (it snaps only under x); readout `5 rows of x`. Dropped under the 12: "x
   goes with x."
4. **Write** `3x + 2x = [5]x`, then `3(x + 4) + 2x = [5]x + [12]`.
Say: "The 3 multiplies both parts, and x rows stack with x rows."
**Core:** the web's generator as it is (a 2–9, b 1–9, c 1–9). Slips kept: only multiplied the first term; multiplied the x
terms; lost the multiplied number; left out the other x terms. Check as the spec (with the hidden 1 when c is 1).

### Minus signs in expressions (`g7-negexpr`, new; 7.EE.1)
**One cell:** a 1 is a 2 × 2 cell; an x is a bar 2 tall and 6 long with a break mark (the chapter's tiles, as
`g7-factor`); solid is positive, striped negative. **Picture:** the expression as tiles, left to right on the strong
lines; what's in parentheses sits inside a dashed box, with what multiplies it at its left, `− 2 ×`. Up to about 56 × 12.
1. **Flip** the box over its minus sign (Flip over 0, the minus sign as the line): it opens into its copies (2 of them,
   stacked as rows inside the box) and every tile in them turns over, solid ↔ striped; readout `−2x + 6`. An added box:
   "This one is added: it stays as it is."
2. **Slide** opposite tiles onto each other (slide over to take away): a striped x onto a solid x, and both go; readout `3x
   + 6 left`. Unlike tiles: "x and 1 aren't alike: they can't cancel."
3. **Write** `5x − 2(x − 3) = 5x − 2x + [6] = [3]x + [6]`.
Say: "The minus turns over everything in the parentheses."
**Core:** new; builds on g7-distribute and g7-mulint. Problems 1–3 take away parentheses, (4x + 7) − (x + 2); 4–6
−a(x − b) and px − a(x − b), a 2–4; 7+ halves and decimals: −½(6x − 10) (the box shares into 2 rows, one row stays and
turns over: −3x + 5) and 0.5x + 1.5x − 3 (half bars). Slips: only the first term
turned, 5x − 2x − 6 ("−2 × −3 is +6: the minus turns every term."); x joined with a number ("x and 1 aren't like
terms."). Check: one of each kind, and x − (x + 2), the hidden 1.

### Factor an expression (`g7-factor`, new; 7.EE.1–2)
**One cell:** a 1 is a 2 × 2 cell; an x is a bar 2 tall and 6 long with a break mark (as `g7-negexpr`); minus parts
striped. 6th grade's `g6-equiv` already takes a whole number out of 6x + 9; here a part has a minus sign, or a negative
or a half comes out. **Picture:** the two parts side by side on a strong line, each a rectangle of tiles, dealt into 2
rows to start, a height handle at the left. Parts up to 12 x's and 24 ones, so at 2 rows it's at most 62 squares wide,
and at 6 rows 12 tall.
1. **Share into rows** (drag the height, as `g6-equiv`): both parts keep their tiles and re-deal into that many rows; it
   snaps to rows; readout `4 rows: 3 | −2x`. A height one part can't fill leaves its last row short: "8 x's don't make
   full rows of 3." A shared height that isn't the tallest: "That fits. A taller one fits too." Release at the tallest.
2. **Write** `12 − 8x = [4]([3] − [2]x)`.
Taking out a negative (problems 4–6): both parts striped, `−4x − 10`; share into 2 rows, then **flip** the rows over 0 as
the −2 comes out: they land solid, `−4x − 10 = −2(2x + 5)`. Kept the sign: "−2 × 5 is −10, so inside it's + 5."
A half (from problem 7): `½x + 3` is one row, half a bar and 3; **hop** a copy of the row on and the two make `x + 6`:
`½x + 3 = ½(x + [6])`.
One step for a percent (7.EE.2, from problem 7): the price bar a (40 squares) and its 5% strip (2 squares); **slide** the
strip onto the bar's end: one bar, `1.05 of a`; **write** `a + 0.05a = [1.05]a`; Say: "Adding 5% is the same as × 1.05."
Say: "Both parts are 4 rows tall, so it's 4 rows of 3 − 2x."
**Core:** new; builds on g6-equiv, g6-gcf and g7-negexpr. The factor 2–6. Problems 1–3 one part with a minus (12 − 8x =
4(3 − 2x), 6x − 15 = 3(2x − 5)); 4–6 a negative taken out (−4x − 10 = −2(2x + 5), −6x + 9 = −3(2x − 3)); 7+ halves
(½x + 3 = ½(x + 6)), the percent kind (a + 0.05a, a − 0.2a) and 2l + 2w = 2(l + w). Slips: not the tallest, 12x − 18 =
2(6x − 9) ("That fits. A taller one fits too: 6."); one part divided only, 3(2x − 15) ("Both parts share the 3: 15 ÷ 3
= 5."); the sign kept inside, −2(2x − 5). Check: a minus, a negative out, a half, a percent.

## 6. Equations

### Two-step equations (`g7-eq`, existing; 7.EE.4a)
**One square:** 1. **Picture:** the balance (see above): left pan, a x tiles side by side and b squares; right pan, c
squares in strips of 10 (at most 13 strips); under the pans their names, `3x + 5 = 20`. The web's balance frames are the
beats.
1. **Take the same off both sides** (new move): drag the 5 squares off the left pan; their twins lift off the right pan
   with them; readout `− 5 from both: 15 left`. Dragging an x: "x is unknown. Take off the 5." Sharing first: "Undo the
   + 5 first, then the × 3." Answers the undo-add step.
2. **Share into rows** (new move): drag the right pan's handle down to 3 rows; its squares re-deal, a row for each x;
   readout `3 rows of 5`. Wrong: "Make 3 rows: one for each x." A count that doesn't share leaves the last row short.
3. See: one x and one row come down off the balance together, `x = 5` (the web's last frame); then the check, `3 × 5 + 5 =
   20`.
4. **Write** `3x = 20 − 5 = 15`, `x = 15 ÷ 3 = [5]`.
Say: "x had two things done to it, so they come undone in reverse: the + 5, then the × 3."
**Core:** the web's generator as it is (x 2–12, a 2–9, b 1–20). Slips kept: undid with the wrong operation (c + b,
c − b − a, (c − b) × a). Check as the spec (three where b isn't a multiple of a, one with x ≥ 8).

### Equations with parentheses (`g7-eqparen`, new; 7.EE.4a)
**One square:** 1; the balance as `g7-eq`. **Picture:** left pan, p groups, each an x tile and q squares in a dashed box
(the parentheses); right pan, r squares in strips of 10; names `3(x + 4) = 27`.
Two ways, both right; the record writes the child's way, then the other as See ("Or …"):
1. **Share into rows** first: the right pan into 3 rows, `3 rows of 9`; then **take the same off both sides**, 4 from every
   row of both pans: `x = 5`.
2. Or **take off** first: dragging one group's 4 takes 4 from every group, 12 in all, and 12 from the right pan; readout
   `− 12 from both: 15 left`; then **share** into 3 rows.
x − q (the q striped): **put the same on both sides**: drag 3 squares onto the striped 3 (they cancel), and the same 3 join
every row of the right pan.
**Write** `x + 4 = 27 ÷ 3 = [9]`, `x = 9 − 4 = [5]`; or `3x + 12 = 27`, `3x = [15]`, `x = [5]`.
Say: "3 equal groups: share first, or take 4 from each group."
**Core:** new; builds on g7-eq and g7-distribute. Problems 1–3 p 2–5, q 1–6, x 1–10 (r up to 80); 4–6 x − q; 7+ either,
r up to 100. Slips: took 4 off once, 3x = 23 ("The 4 is in each of the 3 groups: 12 in all."); didn't share, x = 23
("That's 3 groups' worth. Share it into 3."). Check: share first, take off first, x − q, any.

### Write the equation (`g7-eqstory`, new; 7.EE.4a, 7.EE.3)
**One square:** 1 (a centimeter, a dollar; $0.50 in the decimal kind). **Picture:** the story's own picture at the top
left, a rectangle with its length marked `6` and its width `w` (a break mark), or 3 notebooks as tiles marked `n` and a $4
pen as 4 squares; under it the empty balance. Totals up to 60.
1. **Slide** the story's parts onto the pans (tap or drag each): the rectangle's sides slide onto the left pan as w, 6, w
   and 6 (the 6s as squares) and the 54 onto the right; the left pan's name writes itself, `2w + 12`. The total dropped on
   the left: "54 is the whole fence. It goes on the other pan."
2. Solve with the balance moves (as `g7-eq`): **take off** 12 from both; **share** into 2 rows: `w = 21`.
3. **Write** the equation, typing its numbers, `[2]w + [12] = [54]`, then `w = [21]`; the paper writes the sum way beside
   it, `(54 − 12) ÷ 2 = 21`: "the same steps in the same order".
Say: "The equation takes off 12 and halves, just as the story does."
**Core:** new; builds on g7-eq and g7-eqparen. Problems 1–3 px + q = r stories (notebooks and a pen; tickets and a fee);
4–6 p(x + q) = r stories (a fence, 2(w + 6) = 54; 4 friends each buy a ticket and a $3 snack); 7+ decimals (a phone plan,
$20 and $0.50 a gigabyte). Slips: one width only, w + 12 = 54 ("A rectangle has two widths."); the total on the wrong side.
Check: one of each kind and a decimal.

### Two-step inequalities (`g7-ineq`, new; 7.EE.4b)
**One square:** 1. **Picture:** the inequality as the line's name, `3x + 5 > 20`, at its right end; the line (up to 50
squares, numbered every 5); a story's numbers beside it when there is one ("$50 a week and $3 a sale; at least $100").
1. **Drag the point** along the line; the readout tries x live, `x = 4: 17`, and the point rings where the sides are equal,
   `x = 5: 20`. Release there. Wrong: "x = 6 gives 23. Find where it's exactly 20." In a story whose boundary isn't
   whole, the point stops on the first whole number that works, its neighbour read too: `16 sales: $98`, `17 sales:
   $101`.
2. **Drag a length**: pull the shaded arrow from that point the way that works; the readout tries its end, `x = 9: 32, more
   than 20`. The wrong way: "x = 2 gives 11. That's not more than 20."
3. **Tap** the point to leave it open or fill it. Wrong: "> leaves 5 out: open." / "≥ takes 5 in: filled."
4. **Write** `3x > [15]`, `x > [5]`. Stories: `3s ≥ 50`, `s ≥ 16⅔`, so `[17]` sales or more (the arrow becomes dots on whole
   numbers).
x times a negative (from problem 7): the readout shows the left side falling as x grows, so the arrow points left; `−2x +
10 > 4`, `−2x > −6`, `x < [3]`: "Dividing by −2 turns the sign around."
Say: "Past 5, 3x + 5 only grows, so every number there works." / "−2x shrinks as x grows, so the arrow points left."
**Core:** new; builds on g7-eq and 6th grade's x > c. Problems 1–3 px + q > r, <, ≥ or ≤ (p 2–5, q 1–10, a whole
boundary); 4–6 stories (pay per sale, saving each week, a gift card) where the boundary isn't whole; 7+ p negative. Slips:
the arrow the wrong way; filled for >, open for ≥; the sign kept when dividing by a negative. Check: one of each kind and a
≤.

## 7. Angles and triangles

### Complementary and supplementary (`g7-angles`, existing; 7.G.5)
**One tick:** 1°: a half-circle protractor drawn on the paper, radius 20 squares, its middle on a grid crossing, a tick
every degree, longer every 5° and numbered every 30°. **Picture:** the protractor (about 42 × 22); the 0° arm along the
strong row; the known angle drawn from it with its name, `35°`; the whole's far arm dashed and faint, named by the
problem's word, `supplementary` (the web's picture keeps the whole faint until it's named).
1. **Turn a ray** (new move): drag the far arm around until it makes the whole, a straight line (or a right angle, its
   corner square showing); it snaps to whole degrees; readout `180°`. Wrong: "That's 90°, a right angle. Supplementary
   makes a straight line." Answers the add-up step.
2. **Drag** around the missing angle's arc from the 35° arm to the far arm (a point along the rim; the degrees count);
   readout `145°`. Stopping short: "That's 140°. Go on to the arm."
3. **Write** `180° − 35° = [145]°`.
Say: "Together they make a straight line." / "Together they make a right angle."
**Core:** the web's generator as it is (supplementary half the time, 20–160; complementary 10–80). Slips kept: mixed up the
two; added; used the wrong whole. Check as the spec (it keeps the add-up step).

### Angles where lines cross (`g7-vertical`, new; 7.G.5)
**One tick:** 5° (the readout is exact): a full protractor circle, radius 12 squares, dashed, around a grid crossing.
**Picture:** one line along the strong row through the crossing and a second line through it; the four angles named, one
given, `50°`.
1. **Turn** the second line up from lying on the first (turn a ray, both ends at once); the four angles read live and
   the opposite ones change together. Stop at the given angle. Wrong: "That's 55°. Make it 50°."
2. **Tap** the angle that matches it, the opposite one; it rings. Wrong (a neighbor): "That one makes a straight line with
   the 50°. It's 130°."
3. **Write** `opposite: [50]°`, `next to it: 180° − 50° = [130]°`.
Three lines (from problem 4): two angles side by side on a line are given; the third is what's left of the straight line,
and its opposite matches it: `180 − 50 − 70 = [60]`.
Say: "Opposite angles turn together, so they're always the same."
**Core:** new; builds on g7-angles. Problems 1–3 two lines, the angle 20–160 in 5s; 4–6 three lines; 7+ a right angle split
in two (adjacent and complementary), any degree. Slips: 180 − a for the opposite ("Opposite angles are the same."); 360
for a straight line. Check: two lines, three lines, a split right angle, any.

### Angle equations (`g7-angleeq`, new; 7.G.5, 7.EE.4a)
**One tick:** 1°, the protractor as `g7-angles`. **Picture:** a straight line (or a right angle) on the protractor, cut
by rays into angles named with x: `x` and `2x + 30`; or x, 2x and 3x; or `2x + 10` across from `70°`. Every x is its own
wedge, all the same size, and a number part is a wedge of its own (the 30° beside the 2x), all true to size. Until x is
found the protractor shows only 0°, 90° and 180°, so the x's can't just be read off.
1. **Tap** the angles that make the whole, one by one (tap the part); the record's left side builds, `x + 2x + 30`, and
   `= 180` comes when the whole is done. One left out: "The straight line is all three angles."
2. **Drag** the 30° wedge off the line; it lifts away and the arc it leaves reads `150° for 3 x's`. Dragging an x: "x
   is unknown. Take off the 30° first."
3. **Share** the 150° (share into rows, on the arc): drag a handle along the rim to set one x; copies follow it round, and
   it snaps to whole degrees; readout `3 of 50°`. Wrong: "3 of 45° leaves 15° over."
4. **Write** `3x + 30 = 180`, `3x = [150]`, `x = [50]`; the protractor's ticks come back and the angles get their names,
   50° and 130°, together 180°.
Opposite angles (from problem 7): **tap** the pair, `2x + 10 = 70`; take off the 10°, share the 60° into 2: `x = [30]`.
Say: "The angles make a straight line, so they're 180° together: take off the 30°, then share."
**Core:** new; builds on g7-eq and g7-vertical. Problems 1–3 two angles on a line (x and px + q, p 1–3); 4–6 three on a
line, or a right angle split in two; 7+ opposite angles, one with x and one a number. x on one side only (both sides is
8th grade). Whole answers, angles 10–170. Slips: 90 for a straight line; the + 30 left out (3x = 180). Check: one of each
kind.

### Can it be a triangle? (`g7-triangle`, new; 7.G.2)
**One square:** half a unit (2 squares a unit), so the biggest, base 21, is 42 wide and the tallest, 12 high, takes 24
rows. **Picture:** the base stick on the strong row; the other two sticks hinged at its ends, lying flat along it at
first, their lengths named; dashed arcs show where their free ends can reach (drawn only inside the picture's frame).
1. **Turn** both sticks (turn a ray; a stick snaps where its end lands on a grid crossing); readout `gap 3` between their
   ends, then `they meet`. Too short, the nearest they get: `gap 1: they can't reach`. Flat: "They only meet lying on the
   base."
2. **Pick** in the record: `One triangle` or `No triangle`.
3. **Write** the test: `3 + 4 = 7`, `7 < 8: [no]`; or `5 + 5 = 10 > 8: [yes]`.
Angles (from problem 7): **turn** rays at the base's ends to 40° and 60°, and the triangle closes; **drag** the base longer:
it grows with the same angles; **pick** `Many triangles`. Two sides and the angle between them: one triangle.
Say: "3 and 4 together are 7: too short to span 8." / "Same angles, any size: many triangles."
**Core:** new; builds on g7-angles. Yes-triangles drawn corner to corner on crossings (5-5-6, 5-5-8, 3-4-5, 6-8-10,
5-12-13, 10-13-13, 13-14-15, 4-13-15, 9-10-17, 10-17-21); no-triangles with the two short sides shorter than the long one;
flat ones equal to it. Problems 1–3 yes or no; 4–6 flat ones too; 7+ angles, and two sides with the angle. The angle
triples always make a triangle (a triangle's angles adding to 180° is 8th grade's). Check: yes, no, flat, angles.

## 8. Circles

### Circumference (`g7-circum`, existing; 7.G.4)
**One square:** 1 (2 squares a unit for r 3–5, so small circles still fill the screen; the middle is always on a
crossing). The edge lies flat up to 76 squares long (r = 12), when the camera steps back to about 80%. **Picture:** the
circle sitting on the strong row, its middle on a grid crossing, its radius drawn and named `r = 5`, a dot where it
touches the row; the row runs on to its right.
1. **Drag** the radius's end on through the middle to the far side (a length; it snaps to squares); readout `10: two
   radii`. Stopping at the middle: "That's the radius. Go all the way across." Answers the diameter step.
2. **Unroll** the edge (new move): drag the dot along the row; the edge peels off the circle and lies flat.
3. **Hop** the diameter along it: `3 diameters and a bit`, the bit 0.14 of one (the web's beat).
4. **Write** `d = 2 × 5 = 10`, `C = 3.14 × 10 = [31.4]`.
Say: "The edge is about 3.14 diameters long."
**Core:** the web's generator as it is (problems 1–3 r 3–5, then 3–12). Slips kept: halved the radius; squared the radius;
used the radius. Check as the spec (r ≥ 3, one r ≥ 7).

### Area of a circle (`g7-circarea`, existing; 7.G.4)
**One square:** 1 square unit, so the area is counted (a cell of 2 × 2 squares for r up to 6, so small circles still
fill the screen). **Picture:** the circle (radius r, middle on a crossing),
filled, its radius named; room to its right for the wedges laid out, up to 64 across with the circle (for r of 11 or 12
the camera steps back a little).
1. **Drag the corner** of a square on the radius, from the middle (it snaps; readout `5 × 5 = 25`); the quarter it shares
   with the circle shades darker (the web's overlap). Wrong: "Make it as wide as the radius." Answers the square step.
2. *Fold, why* (7.G.4): the circle cuts itself into 16 wedges; **slide** them out and they fall, point up and point down in
   turn, into a near rectangle r tall and half the edge long; readout `3.14 × 5 long, 5 tall`.
3. See: the r × r square hops along it, 3 squares and a bit, 0.14 of one: "The circle holds about 3.14 squares" (the web's
   beat).
4. **Write** `5² = 25`, `A = 3.14 × 25 = [78.5]`.
Say: "The circle holds about 3.14 squares built on its radius."
**Core:** the web's generator as it is. Slips kept: squared as times 2; used the circumference; squared the diameter. Check
as the spec. The wedge step has no box: it's done when the wedges lie in their row.

### Half circles in shapes (`g7-circparts`, new; 7.G.4, 7.G.6)
**One cell:** 1 m², a cell 2 × 2 squares. **Picture:** a shape on the grid, its straight edges on grid lines and its
curves' middles on crossings: a running track (a rectangle with a half circle at each end), a window (a half circle on a
rectangle), a square garden with a quarter circle cut out. At most 32 m long and 13 m tall: 64 × 26 squares.
1. **Cut** the curved parts off along the grid line where they meet the straight part (a cut that snaps to grid lines);
   readout `rectangle 12 × 6 | 2 half circles, r = 3`.
2. **Slide** the halves together into one circle (quarters: 4 make one); readout `one circle, r = 3`.
3. **Write** `A = 12 × 6 + 3.14 × 3 × 3 = 72 + [28.26] = [100.26]`, or the edge, `2 × 12 + 3.14 × 6 = [42.84]`.
Backwards (from problem 7): "A wheel goes 62.8 cm in one turn. How wide is it?" The edge lies flat, a square a cm;
**drag a length** for the diameter: hopped along the edge, it fits 3 times and a bit, and only one size leaves the bit
0.14 of a hop; readout `20: 3 hops and 0.14`. **Write** `d = 62.8 ÷ 3.14 = [20]`.
Say: "Two half circles make one whole circle."
**Core:** new; builds on g7-circarea. r 2–6, rectangles up to 20 × 12. Problems 1–3 a track's area; 4–6 edges, windows,
quarter circles; 7+ backwards (d from C; r from A when A ÷ 3.14 is a square number: 78.5 ÷ 3.14 = 25, so r = 5).
Slips: the diameter used as r; two whole circles for two halves ("Two halves make one circle."). Check: area, edge,
quarter, backwards.

## 9. Solids (3D)

### Slicing solids (`g7-slice`, new; 7.G.3) — 3D
**One cube:** one block (Unit cubes). **Picture:** flat first, the solid's base on the grid (a box's l × w blocks, or a
pyramid's base with its top point marked), up to 6 blocks a side. The paper tilts and it rises: a box layer by layer as in
Unit cubes, a pyramid's faces drawing up to the point.
1. **Slide the sheet** (new 3D move): a see-through sheet in the chapter colour stands at one face; drag it through the
   solid; the cut face lights and reads live, `4 × 3 rectangle`. The instruction names the way: "Slice it level with the
   floor." / "Slice it straight down, parallel to the front." / "Slice it through the top point." A tilted slice turns
   with the sheet's corner handle.
2. See: the slice lifts out, the paper lies flat, and the slice lands on the grid at its true size beside the base.
3. **Write** what it is: `rectangle [4] × [3]`, `square [2] × [2]`, `triangle: base [4], height [5]`.
Say: "Level with the base: the same shape as the base." / "A pyramid narrows as it rises: halfway up, half as wide." /
"Through the top point: a triangle."
**Core:** new; builds on g5-volume. Problems 1–3 boxes, level and upright; 4–6 pyramids (level at half height, so the
base's sides are even; through the top, a triangle); 7+ a box cut corner to corner (a 3 by 4 base, so the cut is 5 wide)
and a box's corner cut off (a triangle). Answers from the same numbers as the solid. Check: box level, box upright,
pyramid level, through the top.

### Volume of a prism (`g7-prismvol`, new; 7.G.6) — 3D
**One cube:** one block (Unit cubes); the base's area counts in blocks. **Picture:** flat, the base on the grid (an L, a
right triangle with its legs on grid lines, a right trapezoid, a house shape), up to 6 × 5 blocks, its height named, `5
tall`.
1. Flat, the base's area. A triangle: **drag the corner** of the rectangle around it, `4 × 6 = 24: the triangle is half,
   12`. An L or a house: **cut** it into a rectangle and a rectangle or a triangle, `12 + 8 = 20`.
2. The paper tilts; the base rises into the first layer with its area on top; **drag up** to stack the layers (Unit
   cubes); readout `3 layers of 12 = 36`.
3. **Write** `V = B × h = 12 × 5 = [60]` cubic units. The paper lies flat before the next problem.
Say: "Every layer is the base: 5 layers of 12."
**Core:** new; builds on g5-volume, g6-tri and g6-trap. Problems 1–3 L shapes; 4–6 right triangles (an even leg) and
trapezoids; 7+ houses and stories (a tent, a ramp, a trough). Heights 2–6. Slips: the rectangle around the triangle used,
24 × 5 ("The triangle is half of that rectangle."); the height added ("5 layers is × 5."). Check: L, triangle, trapezoid,
house.

### Surface area of a prism (`g7-surface`, new; 7.G.6) — 3D
**One unit:** 2 squares, so a unit square is a 2 × 2 cell, smaller than Unit cubes' block so a net fits the screen.
6th grade's `g6-nets` already folds boxes, triangular prisms and pyramids from their nets; 7th grade's are solids made of
parts. **Picture:** the solid standing on the paper, risen as in Unit cubes: an L-shaped prism (two boxes joined), a
shape of 4–8 cubes, or a house (a triangular prism on a box). At most about 32 × 28 squares once it's laid flat.
1. **Unfold a face** (6th grade's Fold, run the other way): tap or drag a face; it hinges flat onto the paper along its
   bottom edge; readout as it lands, `5 × 4 = 20`. Face by face the net spreads on the grid; the paper lies flat.
2. **Tap** each face of the net to count it (its area written in it; tapped faces light); readout `7 of 8 faces: 76`.
3. **Write** `SA = 8 + 8 + 20 + 5 + 10 + 10 + 10 + 15 = [86]` (an L end of 8 squares, the six sides round it 5 long).
Shapes of cubes: no net; **tap** every square face you can see from outside, turning the shape (Turn) to see the back;
faces where cubes touch don't light. Readout `22 faces`.
Say: "The net is the outside laid flat, so its area is the surface." / "Where cubes touch, neither face is outside."
**Core:** new; builds on g6-nets, g6-poly and g7-prismvol. L prisms with ends up to 4 × 4, 2–6 long; shapes of 4–8
cubes; houses 2–4 wide with 3-4-5 roofs. Problems 1–3 L prisms; 4–6 shapes of cubes; 7+ houses and stories (paint a
shed, wrap a step), where the face on the ground isn't painted. Slips: one end counted ("A prism has two ends.");
touching faces counted ("Where cubes touch, neither face is outside."); the hidden face counted in a story ("The floor
isn't painted."). Check: L prism, cubes, house, story.

## 10. Chance and samples

### Probability (`g7-prob`, existing; 7.SP.5, 7.SP.7a)
**One marble:** a 2 × 2 cell. **Picture:** the bag as the web draws it, one row per kind with its count at the left, `3
red`; under it the chance line, 0 at the left (`never`) and 1 at the right (`always`), ½ marked, cut into T steps (its
length the smallest multiple of T that's 24 squares or more). The marbles' colours: open question 1.
1. **Tap** the marbles of the kind asked; they ring; readout `3 red`. Another kind: "That's a blue one." Answers the
   ways-to-win step.
2. **Drag** a bracket down across every row (a length); readout `10 in all`. Answers the all-the-ways step.
3. *Fold* (7.SP.5): **drag the point** on the chance line (it snaps to steps); readout `3 of 10`; the word under it lights,
   `unlikely`. Wrong: "That's 4 of 10. 3 are red."
4. **Write** `P(red) = [3]/[10]`, and simpler when it can be (`4/10 = [2]/[5]`).
Say: "A chance is the ways to win out of all the ways: 3 of 10."
**Core:** the web's generator as it is (problems 1–3 1–4 of each kind; then 1–8). Slips kept: counted every marble; left out
the red ones; used only the other marbles. The chance line is a new step with no box, set from the two counts. Check as
the spec.

### Chance from trials (`g7-trials`, new; 7.SP.6, 7.SP.7)
**One trial:** one square, stacked in its outcome's column, a block (5 squares) wide, so 10 trials are 2 rows (a die's
six faces, a coin's two, a spinner's parts, a paper cup's three ways to land); a full 100 (20 rows) closes into one block
marked 100 at the column's foot and the stack goes on above it, so 1,000 still fit. **Picture:** the columns on the strong
row, a square apart (a die's six are 35 across, 20 rows at most); under them the chance line, the model's chance a dashed
tick when there is one.
1. **Run trials** (new move): tap `10 more` (later `100 more`); each trial lands as a square, one after another; readout `60
   rolls: 3 came up 11 times`.
2. See: the share so far is a point on the chance line; it moves as the trials run, wobbling less and less near the dashed
   1/6.
3. **Write** what the trials say, `11/60`, then what to expect: `600 × 1/6 = [100]`, "about 100, not exactly".
No model (the cup, from problem 4): **run** 100 (`side 62, up 23, down 15`); **write** `P(side) ≈ [62]/[100]`; **pick**:
equally likely? `yes` or `no`.
Model against data (from problem 7): a spinner that should give 1/4 gives 40 of 100, then 410 of 1,000; **pick** `luck:
run more` or `the spinner isn't fair`.
Say: "The more trials, the closer it gets to 1/6." / "Not equally likely: the cup lands on its side most."
**Core:** new; builds on g7-prob. Problems 1–3 predict with a die or a coin; 4–6 estimate from a lopsided thing; 7+ model
against data. Slip: 1/6 of the wrong count ("1/6 of 600, not of 60."). Check: predict, estimate, equally likely?, model
against data.

### Two at once (`g7-compound`, new; 7.SP.8)
**One outcome:** one cell, 4 × 4 squares, of the table (two dice: 6 × 6 cells, 24 × 24 squares, numbers along the top
and the left, 28 × 28 in all); for three coins, a tree drawn on grid lines out to 8 ends, 40 across.
1. **Tap** every cell in the event ("Tap every pair that adds to 7."); each tapped cell shows its sum; readout `4 of 36`.
   Wrong: "3 + 5 is 8."
2. **Write** `P(sum 7) = [6]/[36] = [1]/[6]`.
Trees (from problem 4): **tap** a branch's end to split it into the next branches (tap to open); `8 ways`; then **tap** the
ways in the event (exactly 2 heads): `[3]/[8]`.
Run it (7.SP.8c, from problem 7): **run trials** of pairs; their tallies fill the cells; the event's cells hold about a
sixth: `100 pairs: 15 made 7. The table says about 17.`
Say: "6 of the 36 pairs make 7, and every pair is as likely as any other."
**Core:** new; builds on g7-prob. Coin and die (12 cells), two dice (36), spinner and coin, three coins (a tree), runs.
Problems 1–3 a coin and a die; 4–6 two dice and trees; 7+ runs. Slips: (3, 4) and (4, 3) counted once ("3 then 4 and 4
then 3 are two ways."); the 11 sums as the bottom ("There are 36 pairs, not 11 sums."). Check: one of each kind.

### Guess from a sample (`g7-sample`, new; 7.SP.1–2)
**One square:** one member: a field of 20 × 20 squares (400 fish in a pond, students, beans in a jar), each gray until
looked at; to its right a line plot from 0 to 400 for the guesses, a square for 10 (40 squares). About 64 × 22.
1. (Fair samples, problems 1–3) **Pick** the fair one of two drawn on the field: `the 20 by the dock` or `20 picked at
   random`. Wrong: "The fish by the dock are all alike. They don't look like the whole pond."
2. **Run** a sample (run trials: `Pick 20`): 20 squares open; readout `6 of 20 are trout`.
3. **Write** `6/20 = 30%`, `30% of 400 = [120]`.
4. **Run** 5 more samples: each guess lands as a dot on the line plot, and they spread, `from 96 to 140`; then the whole
   field opens and the real count, 112, is marked among them.
Say: "A random sample looks like the whole pond, so 30% of the pond is a good guess."
**Core:** new; builds on g6-pctof and g7-prob. Fields of 400 (or 200); the real share 20–60%; bunched fields for the
fair-sample kind; samples of 10, 20 or 40 (bigger ones spread less, from problem 7). Slip: the sample's count used for the
pond ("6 of 20 is 30%. 30% of all 400."). Check: fair sample, a guess, the spread, a bigger sample.

### Compare two groups (`g7-compare`, new; 7.SP.3–4)
**One square:** 1 on the line (a cm, a letter, a minute); one dot is one square, stacked. **Picture:** two dot plots on one
line, one above it and one below, named (`basketball`, `soccer`; or "20 words picked at random from each book"); each
group's mean marked by a small triangle and its MAD written by its name (both from 6th grade).
1. **Drag a length** from one mean to the other: readout `gap 10 cm`.
2. **Hop** one MAD, 5 cm, along the gap: `2 hops`.
3. **Write** `10 ÷ 5 = [2]` MADs; **pick** `clearly apart` or `mixed together` (2 MADs or more shows plainly).
Medians (from problem 7): skewed groups get box plots under their dots, and the gap between medians is counted in IQRs.
Say: "The gap is twice the usual spread, so the two groups really differ."
**Core:** new; builds on g6-mean and 6th grade's MAD and IQR. Two groups of 8–12 values with the same MAD and whole means,
the gap ½–3 MADs. Problems 1–3 big gaps; 4–6 small ones; 7+ medians. Slip: MAD ÷ gap ("How many MADs fit in the gap: gap ÷
MAD."). Check: apart, mixed, medians, any.

## Open questions for G

1. **The marbles' colours.** The web's probability bag has red, blue and green marbles, but on the paper red and green
   only ever mean wrong and right. Draw them solid, striped and open and call them that, or keep colour words with other
   colours?
2. **How negatives look.** I made negatives striped and positives solid, in the chapter colour, on every number line,
   flip, tile and pan (stripes show on graph paper; an outline alone gets lost in the grid lines). But stripes already
   mean "the second amount" in 5th grade's fractions, the web draws negatives dashed, and `LESSONS.md`'s 7th grade line
   says crossing 0 "flips the colour". Stripes, dashes, or a second colour?
3. **Slanted and round lines.** Angles, circles, the triangle's sticks and the slices can't lie along grid lines. I start
   each on a grid crossing and give it its own ticks (a protractor drawn on the paper, a longer tick every 5° like the
   paper's strong lines). Is that the right way to bend "nothing goes off the grid"?
4. **Which lessons first.** Covering 7th grade takes 38 lessons in 10 chapters: the web's 13 and 25 new. Build the 13 first
   (their maths is already written), or each chapter whole, in teaching order?
5. **Bigger squares for small problems.** So a small problem still fills the screen, a few lessons draw a unit bigger
   when the numbers are small (Adding integers, Scale drawings, Circumference, Area of a circle, Distribute and
   combine), as 5th grade's Fraction of a number does. The child sees the size change between problems. Is that all
   right, or should a lesson keep one size and let the camera zoom in?
