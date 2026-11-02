# 9th grade on paper: every lesson's design

Claude (9th grade lesson planner), 1 Nov 2026, in the language of `README.md` and the example of `grade5.md`; reviewed
2 Nov 2026 (coverage checked against Common Core's Algebra I course, sizes and examples checked, Rearrange a formula,
the quadratic formula's b² − 4ac, Correlation and Parts of a two-way table redrawn so their pictures can be counted).
Planning only: nothing here is built, and each lesson still goes to G as a preview before Swift (`LESSONS.md` §9).

**The course:** the web catalog's 9th grade is **Algebra 1** (`web/src/curriculum/grades/index.ts`: "9th grade ·
Algebra 1"; 10th is Geometry, 11th Algebra 2). **Standards covered:** every Common Core high-school standard in the
Algebra I course of the traditional pathway (CCSS Appendix A, its five critical areas): N.Q.1–3, N.RN.1–3, A.SSE.1–3,
A.APR.1, A.CED.1–4, A.REI.1, 3, 4, 5, 6, 7, 10, 11, 12, F.IF.1–9 (7a, 7b, 7e, 8a, 8b), F.BF.1a–b, 2, 3, 4a, F.LE.1–3, 5,
S.ID.1–3, 5–9. (+) standards are left out, as Appendix A does.

**36 lessons in 10 chapters:** the 13 web lessons (`web/src/curriculum/lessons/grade9`, `specs/k12/grade9.md`), each
keeping its maths (generator and ranges, the easy-first start, derived values, slips, the spec's check recipe and its
13 Oct fixes), and 23 new ones (`g9-<short>`). Eleven small gaps are folded into lessons as an extra problem type or
step, marked *fold*. Every web lesson here is wrapped in `withEasyStart`: problems 1–3 are the smallest of six draws.

## Coverage

| Standard | What it asks | Lesson(s) | |
|---|---|---|---|
| N.Q.1 | units guide the working; scales and origins on graphs | Rearrange a formula `g9-literal` (units ride through); Which grows faster? `g9-overtake` (a scaled axis) | new |
| N.Q.2 | name the quantities in a story | Multi-step equations `g9-multistep` + *fold*: stories; Shade the half-plane `g9-halfplane` | existing, new |
| N.Q.3 | an answer only as exact as the story allows | Grow or shrink by a percent `g9-percent` (whole people, cents) | new |
| N.RN.1 | why 9^½ is √9 and 8^⅓ is ∛8 | Fraction powers `g9-fracexp` (3D for cubes) | new |
| N.RN.2 | rewrite roots and powers | `g9-fracexp`; Simplify square roots `g9-radical` | new, existing |
| N.RN.3 | rational + irrational is irrational, and so on | `g9-radical` + *fold*: rational or not | existing |
| A.SSE.1a | terms, factors, coefficients | Add and subtract polynomials `g9-polyadd`; Multi-step equations `g9-multistep` | existing |
| A.SSE.1b | a part read as one thing: P(1 + r)ᵗ | Exponential growth `g9-growth`; `g9-percent`; `g9-fracexp` | existing, new |
| A.SSE.2 | see the structure: GCF, difference of squares, x⁴ − y⁴ | Factor out the GCF `g9-gcf`; Factoring quadratics `g9-factor`; Factor with a number on x² `g9-factora`; Difference of two squares `g9-diffsq` | existing, new |
| A.SSE.3a | factor to see the zeros | `g9-factor`; Solve by factoring `g9-solvefactor` | existing |
| A.SSE.3b | complete the square to see the low point | Complete the square `g9-complete` | new |
| A.SSE.3c | rewrite an exponential: ×8 in 3 hours is ×2 an hour | `g9-percent` + its last kind | new |
| A.APR.1 | add, take away, multiply polynomials; they stay polynomials | `g9-polyadd`; Multiply binomials `g9-foil` + *fold*: (x + 3)², (2x + 1)(x + 3), a binomial times a trinomial | existing |
| A.CED.1 | write and solve one-variable equations and inequalities | `g9-multistep` (stories); Inequalities `g9-ineq`; Graph a parabola `g9-parabola` (a thrown ball) | existing, new |
| A.CED.2 | write two-variable equations and graph them | Line through two points `g9-twopoint`; `g9-growth`; `g9-overtake`; `g9-sequence` | existing, new |
| A.CED.3 | constraints as inequalities; viable or not | `g9-halfplane` (ticket stories) | new |
| A.CED.4 | rearrange a formula for one letter | `g9-literal` (squared letters in its last kind) | new |
| A.REI.1 | each step keeps the two sides equal | `g9-multistep` (the balance) | existing |
| A.REI.3 | linear equations and inequalities; letters as coefficients; 2ˣ = 1/16 | `g9-multistep`; `g9-literal`; `g9-ineq`; Zero and negative exponents `g9-negexp` + *fold*: find the power | existing, new |
| A.REI.4a | complete the square; where the formula comes from | `g9-complete`; The quadratic formula `g9-quadform` (its How to) | new, existing |
| A.REI.4b | by inspection, roots, completing the square, formula, factoring; no real answer | Solve with square roots `g9-sqroot`; `g9-solvefactor`; `g9-complete`; `g9-quadform` + *fold*: no crossing | new, existing |
| A.REI.5 | add a multiple of one equation to the other | Systems by elimination `g9-elim` + *fold*: scale one first | existing |
| A.REI.6 | solve systems exactly and on a graph; none, every | `g9-elim` (its See, + *fold*: parallel and same line) | existing |
| A.REI.7 | a line and a parabola | A line meets a parabola `g9-linequad` | new |
| A.REI.10 | a graph is every point that makes it true | `g9-twopoint` + *fold*: ride the line; `g9-halfplane` | existing, new |
| A.REI.11 | where f and g cross solves f(x) = g(x) | `g9-ineq`; `g9-overtake`; `g9-linequad` | new |
| A.REI.12 | half-planes and their overlap | `g9-halfplane` | new |
| F.IF.1 | domain, range, one output each, f(x) | Domain and range `g9-domain` | new |
| F.IF.2 | function notation in and out of stories | `g9-domain` | new |
| F.IF.3 | sequences are functions on whole numbers | Sequences `g9-sequence` | new |
| F.IF.4 | intercepts, rising and falling, highs and lows, symmetry, ends | Read a graph `g9-features`; `g9-parabola` | new |
| F.IF.5 | the domain a story allows | `g9-domain`; `g9-parabola` (the ball's flight) | new |
| F.IF.6 | average rate of change | Average rate of change `g9-avgrate` | new |
| F.IF.7a | graph lines and parabolas | `g9-twopoint`; `g9-parabola` | existing, new |
| F.IF.7b | square root, cube root, steps, absolute value, pieces | Pieces, steps and corners `g9-piecewise` | new |
| F.IF.7e | exponential graphs, their start and ends | `g9-growth` (its See); `g9-features` (its exponential kind) | existing, new |
| F.IF.8a | factor and complete the square: zeros, low point, symmetry | `g9-solvefactor`; `g9-parabola`; `g9-complete` | existing, new |
| F.IF.8b | the percent inside 1.02ᵗ or 0.97ᵗ | `g9-percent` | new |
| F.IF.9 | compare two functions shown different ways | `g9-features` + its last kind; `g9-overtake` | new |
| F.BF.1a | a rule from a story: explicit, step by step | `g9-sequence` (its stories); `g9-overtake`; `g9-parabola` (stories) | new |
| F.BF.1b | build one function from two | Slide and stretch a graph `g9-shift` + its cooling-cup kind | new |
| F.BF.2 | sequences both ways, next-from-now and from n | `g9-sequence` | new |
| F.BF.3 | f(x) + k, k·f(x), f(x + k); even and odd | `g9-shift` (f(kx) for other curves is 11th grade's `g11-zeros`) | new |
| F.BF.4a | undo a function (linear) | `g9-literal` + *fold*: solve y = 2x + 3 for x | new |
| F.LE.1a–c | equal steps or equal factors; constant rate; percent rate | `g9-sequence`; `g9-overtake`; `g9-percent`; `g9-growth` | new, existing |
| F.LE.2 | build lines and exponentials from two points, a table, words | `g9-twopoint`; `g9-sequence`; `g9-growth` | existing, new |
| F.LE.3 | exponential passes linear (and quadratic) | `g9-overtake` | new |
| F.LE.5 | what the numbers in a rule mean in its story | `g9-growth`; `g9-percent`; `g9-residual` | existing, new |
| S.ID.1 | dot plots, histograms, box plots | Compare with box plots `g9-boxplots` | new |
| S.ID.2 | the right middle and spread for the shape; IQR, standard deviation | Find the median `g9-median` + *fold*: which middle; `g9-boxplots`; Standard deviation `g9-sd` | existing, new |
| S.ID.3 | shape, centre, spread in context; outliers | `g9-boxplots` (the fences); `g9-median` | new, existing |
| S.ID.5 | joint, marginal, conditional relative frequency | Parts of a two-way table `g9-relfreq` | new |
| S.ID.6a–c | fit a function; residuals; a line for a linear cloud | Residuals `g9-residual` | new |
| S.ID.7 | what the slope and the start mean | `g9-residual` | new |
| S.ID.8 | the correlation coefficient | Correlation `g9-corr` | new |
| S.ID.9 | correlation isn't cause | `g9-corr` + its last kind | new |

**Grade boundaries.** 8th grade's plan (`grade8.md`) keeps slope from two points with the step drawn, y = mx + b from a
point and a slope, x on both sides, one/none/every-number equations, systems by graphing and substitution, functions as
one output each, scatter plots with a line by eye, two-way tables read by row, integer exponents (with zero and
negative folded into Exponent rules), and square and cube roots of perfect squares and cubes. 9th grade starts where
each becomes Algebra 1: the line in one go from two points, elimination, half-planes, domain and range, rates over an
interval, roots as fraction powers, residuals and r. 7th grade (`grade7.md`) keeps two-step inequalities with the
negative-divisor flip; `g9-ineq` starts with x on both sides. 6th grade (`grade6.md`) keeps the median, mean, MAD, IQR
and box plots; 9th grade uses them (S.ID.1–3 is choosing between them, outliers' fences and standard deviation).
8th grade's Graphs that tell a story (`g8-story`) says rising, flat and falling in words; `g9-features` adds the
named points (the top, the zeros, the ends). 10th grade (Geometry) keeps parallel and perpendicular slopes
(`g10-perp`), the distance and midpoint formulas, and completing the square for a circle's centre (`g10-square`, after
this grade's `g9-complete`).
11th grade keeps four lessons that finish what 9th grade starts: `g11-ratexp` (8^⅔, the m/n powers; 9th grade does
½ and ⅓), `g11-seq` and `g11-geo` (far terms with n − 1 jumps; 9th grade's sequences start at term 0 and stay small),
`g11-inverse` (inverse functions and their mirror graph; 9th grade only solves y = 2x + 3 for x) and `g11-vertex`
(x = −b ÷ 2a for any a; 9th grade finds the vertex halfway between the zeros and by completing the square). Also
`g11-expeq` (2ˣ⁺¹ = 32) after 9th grade's plain 2ˣ = 1/16, and complex answers (9th grade only says "no real answer").

## Chapters (teaching order)

New lessons are marked *.

| # | Chapter | Lessons |
|---|---|---|
| 1 | Equations and inequalities | Multi-step equations · Rearrange a formula* · Inequalities* |
| 2 | Functions | Domain and range* · Read a graph* · Average rate of change* |
| 3 | Lines and systems | Line through two points · Systems by elimination · Shade the half-plane* |
| 4 | Powers and roots | Zero and negative exponents · Fraction powers* (3D) · Simplify square roots |
| 5 | Growing and shrinking | Exponential growth · Grow or shrink by a percent* · Sequences* · Which grows faster?* |
| 6 | Polynomials | Add and subtract polynomials · Multiply binomials · Factor out the GCF · Factoring quadratics · Factor with a number on x²* · Difference of two squares* |
| 7 | Parabolas and other graphs | Solve by factoring · Graph a parabola* · Slide and stretch a graph* · Pieces, steps and corners* |
| 8 | Solving quadratics | Solve with square roots* · Complete the square* · The quadratic formula · A line meets a parabola* |
| 9 | One set of data | Find the median · Compare with box plots* · Standard deviation* |
| 10 | Data in pairs | Parts of a two-way table* · Residuals* · Correlation* |

## What every 9th grade lesson shares

As in 5th grade: what to do on rows 0–2 (words 28), a miss on rows 3–4 (words 20, red), the picture from row 6 with its
names at its right end, the record 3 rows under it (36, 2 squares a digit; beside the picture when the picture is tall),
the blocks under the record. The iPad is about 68 × 45 squares; about 64 × 40 hold a problem, so pictures stay near
60 × 30 at 100%, and a bigger problem has the camera step back, never past what a child can count. The first words
never repeat the problem; the last line says why. Answers in the chapter colour; red and green only for wrong and right.
A step answered by a hand move sets its Core box from the move (`LessonRun.set`, `byHand`), so Core's checks and slips
stay; a box an earlier move already answered is set at once. Typing only for what school writes: a number, or the
numbers inside a line like `(x + [3])(x + [4])`; letters are written by the paper from the child's moves. A pick-one
step uses the engine's choice row (`choices`). Show me and the How to play each move with the ghost finger and put
everything back.

- **The plane** is 8th grade's: one unit is one square, the axes on strong lines, every strong line a 5 numbered small
  along the axes. A point is a dot on a crossing. A story's axis may count in 2s, 5s, 10s or 20s (N.Q.1), numbered on its
  strong lines; the scale is written once on the axis (`1 square = $20`). Curves (parabolas, exponentials) are drawn
  smooth through crossings; their named points sit on crossings.
- **The balance** is 8th grade's: a level beam, pans on whole blocks; an x is a tile 2 squares wide and 5 tall, a 1 a
  square, ten a strip of 10, a hundred a 10 × 10 block. **Negatives are striped** (7th grade's): a striped piece slid
  onto a solid one the same size cancels it, and both go.
- **Algebra tiles** (Polynomials, Factoring, Complete the square): a 1 is a square; an x is a bar 1 square wide and
  X long with a break mark (so it isn't counted), X = the problem's biggest number + 3, as the web's area pictures do;
  an x² is an X × X square with break marks. Negative tiles are striped.
- **Data:** one dot or one bar-square is one answer or one unit, as 6th and 8th grade draw them.
- **3D** only where the maths is a volume: Fraction powers' cube roots (Unit cubes: flat first, the paper tilts as the
  layers rise, words face the child, flat again before leaving). The rest of Algebra 1 lies flat: the plane, the
  balance and the tiles are clearer on the paper.

**New hand moves** (not in the kit table of `README.md`; each comes with the first lesson that uses it, after G sees its
preview). Three are 9th grade's own; the rest are 6th, 7th and 8th grade's planned moves, used here as they are.

| Move | What the finger does; the live readout | Used by |
|---|---|---|
| **Shade a side** (new) | tap a point on one side of a line; the readout tests it, `(0, 0): 0 < 1 ✓`; a true point shades its whole half of the plane, a false one flashes red | halfplane |
| **Flatten onto an axis** (new) | drag a graph down onto the x-axis (or across onto the y-axis); it squashes into its shadow there, a band with its end dots; `−2 ≤ x ≤ 6` | domain |
| **Stretch a graph** (new) | drag a graph's handle up or down; every point's height scales from the x-axis together; snaps at × ½, × 2, × 3 and × −1 (it turns over); `y = 2x²` | shift |
| Place a point on the plane (8th) | tap or drag to a crossing; it snaps; `(3, −2)` | twopoint, features, parabola, linequad, piecewise, residual, corr |
| Lay a line (8th) | drag a line's two round handles; it snaps through crossings; `slope 2` | twopoint, halfplane, residual |
| Draw the step (8th's slope legs) | drag across, then up or down, from one point to another; `3 across`, `12 up` | twopoint, avgrate |
| Sweep a line (8th) | drag a straight-up line across the plane a column at a time; the readout shows what's at that x | ineq, domain, overtake, linequad |
| Slide a shape (8th) | drag a whole shape, a tile row or a graph; it snaps a square at a time; for a graph the readout is its equation, `y = (x − 3)² + 2` | shift, diffsq, polyadd |
| Flip over a line (8th; 7th's Flip over 0) | drag a shape or half a graph across a line; it turns over like a card; tiles turn solid ↔ striped | polyadd, parabola, sqroot |
| Turn a shape (8th) | drag its turn handle; it snaps every quarter turn | diffsq |
| Draw a graph (8th) | a pen from the last point to the next crossing, piece by piece | piecewise |
| Take the same off both sides (8th, 7th) | drag a group off one pan; its twin leaves the other pan with it; `− 12 from both: 15 left` | multistep, elim |
| Share into rows (7th) | drag a group's handle to a number of rows; it re-deals, the count kept; `3 rows of 5` | multistep, elim, gcf, sd |
| Raise a square on a side (8th) | drag a side's handle outward; a square sweeps out, its area counting; `3 × 3 = 9` | sd |
| Stretch from a point (8th) | drag a corner or a bar's top along its ray from a fixed point; snaps at whole multiples; `× 2: 24` | sequence, percent |
| Sort (6th) | drag a bar to its place in order; the others make room; `in order` | median |
| Drag a length (7th) | pull a bracket, arrow or box edge along the grid; it snaps to squares; `gap 6` | ineq, boxplots |
| Choose (7th) | tap one of two or three answer words drawn as blocks in the record | ineq, features, halfplane, elim, quadform, median, boxplots, relfreq, residual, corr |

Reused from the kit: cut with the ruler (literal, percent, foil, diffsq), slide pieces (literal, elim, polyadd, foil,
complete, quadform, sequence, percent), tap pieces (relfreq, residual, complete, corr), drag a point along a line (now along any graph: avgrate, solvefactor,
sqroot, parabola, quadform, domain), hop (twopoint, overtake, boxplots), drag a rectangle's edge or corner (growth,
factor, factora, fracexp, literal, sd), tap the part (features), cover the floor and build the layers (fracexp, 3D), write.

## 1. Equations and inequalities

### Multi-step equations (`g9-multistep`, existing; A.REI.1, A.REI.3, A.SSE.1a; *fold* A.CED.1, N.Q.2)
**One square:** 1. **Picture:** the balance, each pan as wide as its load. Left pan: `a` groups, each in a dashed ring
holding one x tile and `b` squares (3 × 3 at most), up to 5 rings in a row and the rest in a second row; right pan: `c`
as hundreds, ten strips and squares (`c` is at most 189: one hundred block, eight strips, nine squares). The equation
is the pans' name, once, under the beam: `3(x + 4) = 27`.
1. **Slide pieces:** drag the ones out of each ring into one pile beside the x's; the count runs on (4, 8, 12) and the
   empty rings close round their x's. Readout `3x + 12`. Leaving a ring full and going on: "2 groups still hold 4
   each." Then **write** `3x + [12] = 27` (the web's distribute step and its slip, "Multiply 3 by **both** x and 4.").
2. **Take the same off both sides:** drag the 12 off the left pan; 12 lift off the right with them. Readout `− 12 from
   both: 15 left` (sets the subtract step, 15). Dragging only one group's 4 before the pile is made: "The 4 is in each of
   the 3 groups: take off 12." (the web's "Took off the number before distributing").
3. **Share into rows:** drag the right pan's handle to 3 rows, one for each x; `3 rows of 5`. Wrong count: "Make 3 rows:
   one for each x." Then **write** `x = 15 ÷ 3 = [5]` (slip "Subtracted instead of divided": "3x is 3 times x, so divide
   by 3.").
See: one x and one row lift off together, level; the check `3 × (5 + 4) = 27` writes itself.
Record: `3(x + 4) = 27` · `3x + [12] = 27` · `3x = [15]` · `x = [5]`.
Say: "Whatever comes off one pan comes off the other, so the pans stay level."
*Fold (A.CED.1, N.Q.2), from problem 9:* a story, "3 friends each buy a ticket and a $4 snack. They spend $27." Each
ring is a friend; the record starts `x = one ticket's price` and the child picks the equation in the choice row
(`3(x + 4) = 27`, `3x + 4 = 27`); the wrong one: "Each friend pays for a ticket and a snack: 3 groups of x + 4."
**Core:** the web's generator as it is (a 2–9, b 1–9, x 1–12; smallest-of-six start), its three steps and slips, its
check (i3; i3; i3 where a × b ≥ 20; i3 where x ≥ 8). The story kind is new, from problem 9, with the same numbers.

### Rearrange a formula (`g9-literal`, new; A.CED.4, A.REI.3, N.Q.1; *fold* F.BF.4a)
**One square:** one of the formula's units (a metre, a mile). Every formula is drawn as one real case, so it can be
counted, with the letters naming its parts. **Picture:** `P = 2l + 2w`: a rectangle 9 × 6 squares from row 6, its
sides named `l` and `w`; beside it its edge unrolled into a bar 4 squares tall and 30 long, in four pieces `l | w | l |
w` (`w` in the chapter colour, the rest pencil), named `P`. The formula is the bar's name, `P = 2l + 2w`, with `w`
ringed: the one to find.
1. **Slide pieces:** drag both `l` pieces off the bar; readout `P − 2l: 30 − 18 = 12`. What's left is `w | w`.
   Dragging a `w`: "w is the one we want. Move the others away."
2. **Cut** what's left in 2 with the ruler; readout `halves: 6 each`; one half lights and slides up against the
   rectangle's short side: it fits. Wrong count: "There are 2 w's: cut it in 2."
3. The paper writes the moves as letters, the record: `P = 2l + 2w` · `P − 2l = 2w` · `w = (P − 2l) ÷ 2`.
4. **Try another:** a new rectangle draws (`P = 40 m`, `l = 12 m`) and the bar with it; **write** `w = (40 − 24) ÷ 2
   = [8]`; its short side measures 8. The unit rides through: `m`. (N.Q.1: for `t = d ÷ r` the units line reads
   `miles ÷ miles per hour = hours`.)
Say: "The same two moves work for every rectangle, so we can do them with letters."
Each formula has its own picture, all in real squares: `A = lw` and `V = IR` a rectangle whose rows are counted (`w =
A ÷ l`: share the area into l rows); `d = rt` a bar of d miles in t equal hops of r; `y = mx + b` a bar of b, then x
pieces of m. **Squared letters** (from problem 9): `A = s²` is a square of A squares; **drag the corner** (Fraction
powers' move) to find its side: "Undo the square with √." Formulas whose numbers can't be counted (`C = 2 × 3.14 ×
r`, `F = 1.8C + 32`, `V = 3.14r²h`) are record only, from problem 11.
**Core:** new. Formulas from a set: problems 1–3 one move (`A = lw` for w, `d = rt` for t, `V = IR` for R), 4–8 two
moves (`P = 2l + 2w` for w, `y = mx + b` for x), 9–10 a squared letter (`A = s²` for s, A a square 4–100), 11+ the
record-only ones. Every case's numbers are whole and the bar is at most 60 squares (P up to 60; d up to 60).
*Fold (F.BF.4a):* the `y = mx + b` kind is written as a function, `f(x) = 2x + 3`, and the record ends `x = (y − 3) ÷ 2
undoes f`; `g11-inverse` keeps inverse functions and their mirror graph. Slips: cut only the P ("Take 2l off first,
then cut what's left."); took the wanted letter off; the try-it numbers swapped. Check: one move, two moves, a squared
letter, a units line.

### Inequalities (`g9-ineq`, new; A.REI.3, A.CED.1, A.REI.11)
**One square:** 1 on the plane. **Picture:** the plane with both sides of the inequality drawn as lines, each named at
its right end (`y = 5x − 3`, `y = 2x + 9`); the inequality written once as the record's first line, `5x − 3 < 2x + 9`.
The x-axis is the number line the answer goes on.
1. **Sweep a line** across: the readout shows both sides at that x, `x = 2: 7 < 13`, green while it's true, red while it
   isn't. Release where they're equal (the lines cross): `x = 4: 17 = 17`. Released elsewhere: "At x = 2 the sides are
   7 and 13. Find where they're equal."
2. **Drag a length** along the x-axis from 4, the way it's true: the shaded arrow's end is tested, `x = 1: 2 < 11 ✓`.
   The wrong way: "At x = 6, 27 isn't less than 21."
3. **Tap** the point at 4 to leave it open or fill it. Wrong: "< leaves 4 out: open." / "≤ takes 4 in: filled."
4. **Write** the school working: `3x < [12]`, `x < [4]`.
Say: "Left of 4 the first line is lower, so every x there works."
When x's number is smaller on the left (`x + 5 > 3x − 1`), the left line climbs slower, so the arrow points left, and
the record writes the turn: `−2x > −6`, `x < [3]`, "÷ −2 turns the sign". Say: "x + 5 climbs slower than 3x − 1, so
it's ahead only left of 3." (One side with x, like `−2x + 1 > 7`, is 7th grade's `g7-ineq`.)
*Stories (A.CED.1)* from problem 9: "A gym costs $40 to join and $15 a visit. Pay as you go is $20 a visit. When is the
gym cheaper?" `40 + 15v < 20v`, `v > [8]`; whole visits, so the arrow is dots from 9.
*Both ends* (from problem 11): `−3 < 2x + 1 ≤ 7`: two level lines and one rising; the sweep lights the stretch between,
`−2 < x ≤ [3]`.
**Core:** new; builds on 7th grade's `g7-ineq` (one side with x). ax + b < cx + d with a ≠ c, a whole boundary −6..6,
both sides within ±25 there (so it's on screen); problems 1–3 a > c and < or >, 4–6 ≤ and ≥ and the falling kind,
7–8 brackets (`−2(x − 4) ≥ 6`), 9+ stories, 11+ both ends. Slips: the arrow the wrong way; open for ≤; the sign kept
after ÷ a negative ("−2x shrinks as x grows: the sign turns"). Check: one rising, one falling, a story, a ≤.

## 2. Functions (the plane)

### Domain and range (`g9-domain`, new; F.IF.1, F.IF.2, F.IF.5)
**One square:** 1. **Picture:** a graph `f` on the plane, a few straight pieces joined at crossings, its two ends a
filled or an open dot; named `f` at its right end.
1. **Flatten onto an axis:** drag the graph down onto the x-axis; it squashes into its shadow, a band with its end
   dots kept. Readout `−2 ≤ x ≤ 6`. Then drag it across onto the y-axis: `1 ≤ y ≤ 5`. The graph springs back each time.
2. **Write** `domain: [−2] ≤ x ≤ [6]`, `range: [1] ≤ y ≤ [5]` (an open end writes `<`). Slips: domain and range
   swapped ("The domain is the shadow on the x-axis: the inputs."); the end values of the graph's ends taken for the
   range when the top is in the middle ("The highest point is 5, at x = 2, not at an end.").
3. **Notation** (F.IF.2): `f(4) = ?`: **drag a point along** the x-axis to 4; a dashed line rises to the graph; **write**
   `f(4) = [3]`. Then `f(x) = 5`: **sweep** a level line at 5 across; each place it meets the graph lights; **write**
   `x = [2]`. Wrong input: "That's f(3). Find f(4)."
Say: "The shadow on the x-axis is every input f uses; the shadow on the y-axis is every output."
*Stories (F.IF.5)* from problem 7: "h(n) is the cost of n tickets at $4, up to 10 tickets." The graph is dots, not a
line; **choose** the
domain: `whole numbers 0 to 10` or `every number 0 to 10`. Wrong: "You can't buy 2.5 tickets." *The square root* (from
problem 9): y = √x drawn through (0, 0), (1, 1), (4, 2), (9, 3), (16, 4); flattened, its shadow starts at 0:
"No number times itself is negative, so √x starts at 0."
**Core:** new. Graphs of 2–4 straight pieces between crossings, x −8..8, y −6..8, ends open or filled; f(a) at whole a
on a piece; f(x) = k with 1 or 2 answers. Problems 1–3 one rising piece with filled ends; 4–6 a peak or a dip inside;
7+ stories; 9+ √x. Check: a peak inside, an open end, f(a), a story.

### Read a graph (`g9-features`, new; F.IF.4, F.IF.7e, F.IF.9)
**One square:** 1 (a story's axes may count in 2s or 5s). **Picture:** a story's graph on the plane: "The temperature
from midnight", hours across, °C up; a smooth curve through crossings, rising and falling, crossing 0.
Each step is one question in the instruction rows:
1. "Tap where it rises." **Tap the part**: the pieces between turning points light as tapped; readout `0 to 14 hours`.
   Wrong: "That part falls: it's getting colder."
2. "Where is it highest?" **Place a point** at the top: `(14, 9)`. Wrong: "(16, 8) is lower than the point at 14."
3. "Where is it 0?" **Place a point** on each crossing of the x-axis. Wrong: "That point is 3 above the axis."
4. "Tap where it's below 0." The part under the axis lights.
5. The ends: **choose** `keeps rising`, `keeps falling` or `levels off` for each arrowhead.
Record, its boxes set from the taps: `rises 0 < x < [14]`, `max ([14], [9])`, `zero at x = [4], x = [22]`, `below 0
for 0 ≤ x < 4 and 22 < x ≤ 24`. Say: "It warms until 2 in the afternoon, to 9°, then cools: above 0 from 4 to 22."
*Compare (F.IF.9)* from problem 9: a second function as a table or an equation beside the graph (`g(x) = −(x − 10)² + 12`);
**choose** which has the higher top, or which starts higher. Wrong: "g's top is 12 at x = 10. f's is 9."
*Exponential graphs (F.IF.7e)*: one kind is `y = 2ˣ + 3` or a cooling curve: its y-intercept and the level it nears
are the answers (`levels off at 3`).
**Core:** new. Graphs from a small family with whole turning points and zeros (parabolas, smooth up-down-up curves made
from cubics with whole roots, exponentials with a whole asymptote), each with a story (temperature, a skateboarder's
height, a bank balance). Problems 1–3 one peak; 4–6 a peak and a dip; 7+ exponentials; 9+ the comparison. Check: rises,
max, zeros, ends.

### Average rate of change (`g9-avgrate`, new; F.IF.6)
**One square:** 1 (or a story's scale). **Picture:** a curved graph on the plane, named at its end (`y = x²`, or "a
car's distance from home"), two inputs marked on the x-axis as small flags, `1` and `4`.
1. **Drag a point along** the graph to the first flag, then a second point to the other: readout `(1, 1)`, `(4, 16)`.
   The straight line between them (the chord) draws, dashed.
2. **Draw the step** from the first point to the second: `3 across`, `15 up`. Past the flag: "Stop under the point at 4."
3. **Write** `(16 − 1) ÷ (4 − 1) = [15] ÷ [3] = [5]`. Slips: flipped ("The change in y goes on top: 15 ÷ 3."); one point
   alone, 16 ÷ 4 ("Use both points: the change from 1 to 16.").
Say: "From 1 to 4 it climbs 15 in 3 steps: 5 a step on average, slow at first and fast at the end."
*Tables* from problem 7: a table of a story's values (a town's population each year); **tap** two rows, and the
record is the same line with the table's numbers. *Falling* (from problem 9): a cooling cup; the answer is negative,
"−4° a minute on average".
**Core:** new. f from y = x², x² + c, 2ˣ, 3ˣ, and story curves through crossings; intervals with whole ends, run 1–6,
every value on the interval 30 or less so it fits the plane (x² to 5, 2ˣ to 4, 3ˣ to 3);
answers whole (or one decimal for the tables). Problems 1–3 rising, run 2–3; 4–6 any interval on a parabola, some
across the dip (0 change: "Up and back down: 0 on average."); 7+ tables; 9+ falling. Check: a parabola, an
exponential, a table, a falling one.

## 3. Lines and systems (the plane, the balance)

### Line through two points (`g9-twopoint`, existing; F.LE.2, A.CED.2, F.IF.7a; *fold* A.REI.10)
**One square:** 1. **Picture:** the plane; the two points written once as the record's first line, `(1, 5) and (3, 9)`;
the frame fits both points and the y-axis (y reaches 32 at most, so for the tallest the camera steps back to about 80%).
1. **Place a point** at each: readout `(1, 5)`. Wrong: "That's (1, 6). 5 up, not 6."
2. **Draw the step** from the first point to the second: `2 across`, `4 up` (down for a falling line). Then **write**
   `m = 4 ÷ 2 = [2]` (the web's m step; its slip "Flipped rise and run": "The y change goes on top.").
3. **Hop** from the first point back to the y-axis, one step of the slope at a time (1 across, 2 down), as 8th grade's
   Slope-intercept form does; readout `1 hop back: down 2`; it lands on the y-axis, and that dot is b (x1 below 0 hops
   forward instead). Away from the axis: "The y-axis is the other way." **Write** `b = 5 − 2 × 1 = [3]` (slip "Added
   instead of subtracted": "b = y − mx: subtract m × x.").
4. **Lay a line** through the two points: it snaps through both and on to the screen's edges; **write** `y = [2]x +
   [3]` (slip "Swapped m and b": "The slope goes with x. b is where the line crosses the y-axis.").
*Fold (A.REI.10):* **drag a point along** the line: readout `(4, 11): 2 × 4 + 3 = 11 ✓`; dragged off it, the point turns
red, `(4, 12): 2 × 4 + 3 isn't 12`. Any drag is right; release ends the step.
Say: "Two points fix one line: it climbs 2 a step and crosses the y-axis at 3."
**Core:** the web's generator as it is (m ±1..4, never 0; b −8..8; x1 −4..2 and x2 one to four to its right, neither on
the y-axis; smallest-of-six start), its three steps and slips, its check (i3 where m > 0; where m < 0; where b < 0;
where x1 < 0). The ride along the line is a hand step with no box.

### Systems by elimination (`g9-elim`, existing; A.REI.5, A.REI.6)
**One square:** 1. **Picture:** two balances one above the other, each named under its beam: `x + y = 10` (an x tile
and a y tile, 10 squares) and `x − y = 4` (an x tile and a striped y tile, 4 squares). A y tile is 2 × 5 like x, with
`y` in it. Negative numbers on the pans are striped squares. Every pan's number stays under 50 (24 in the web's kind), so there are no hundred blocks:
each balance is about 12 rows, and the two stack in 26 from row 6 (the small plane of the See goes to their right).
1. **Slide pieces:** drag the second balance up onto the first, pan onto pan (left onto left, right onto right). The y
   and the striped y meet and cancel; readout `2x = 14` (sets the add step). Sliding it over to take away instead (5th
   grade's slide-over): the x's cancel and the y's don't: "Subtracting cancels x, not y. Add so that + y and − y make 0."
   (the web's "Subtracted the equations").
2. **Share into rows:** 2 rows, one for each x: `2 rows of 7`. **Write** `x = [7]` (slip "Didn't divide": "That is 2x.
   Divide by 2 to get one x.").
3. The first balance comes back with 7 squares in the x tile's place; **take the same off both sides**: 7 from each pan;
   readout `y = 3`. **Write** `7 + y = 10, y = [3]` (slip "Added x": "x + y = 10, so y is 10 take away 7."). A negative
   x adds instead: the striped squares are cancelled by putting the same on both pans.
See: the check, `7 − 3 = 4`, writes itself under the second balance; then both lines draw on a small plane beside the
balances and cross at `(7, 3)` (A.REI.6: the same answer on a graph).
Say: "Adding the two balances keeps them level, and + y and − y make nothing: only x is left."
*Fold (A.REI.5), from problem 9: scale one first.* `x + 2y = 7` and `3x − y = 7`: adding cancels nothing, so **tap the
ring** on the second balance and drag its × to 2 (8th grade's Brackets on both sides): every tile on both its pans is
copied, `6x − 2y = 14`; then slide on, `7x = 21`. Wrong ×: "× 3 makes − 3y. The other has + 2y."
*Fold (A.REI.6), from problem 11:* the same line twice (`x + y = 5`, `2x + 2y = 10`) or parallel lines (`x + y = 5`,
`x + y = 8`): everything cancels and `0 = 0` or `0 = 3` is left; **choose** `every point on the line` or `no answer`;
the small plane shows one line drawn twice, or two that never meet.
**Core:** the web's generator as it is (x and y −6..12, the first three both 1..12), its steps, slips and check (i3 where
x > 0 and y > 0; where y < 0; where x < 0; i3). New kinds from problem 9: a scaled equation (coefficients 1–3, x and y
−5..8); from 11, one in four parallel or the same line. Tests for both.

### Shade the half-plane (`g9-halfplane`, new; A.REI.12, A.CED.3, A.REI.10, N.Q.2)
**One square:** 1 (a story: 1 square = 2 tickets both ways, so 60 seats is 30 squares). **Picture:** the plane; the inequality as the record's first
line, `y < 2x + 1`.
1. **Lay a line** for the boundary: drag its handles; it snaps through crossings; readout `y = 2x + 1` once it is that
   line. Wrong: "That line crosses the y-axis at 3. This one crosses at 1."
2. **Tap** the line to make it dashed or solid. Wrong: "< leaves the line out: dashed." / "≤ takes it in: solid."
3. **Shade a side:** tap any point off the line. Readout `(0, 0): 0 < 1 ✓`, and its whole side shades; a false point
   flashes red, `(0, 4): 4 < 1 ✗`, and nothing shades.
Record: `y < 2x + 1`, the test written under it, `(0, 0): 0 < 2 × 0 + 1 ✓`.
Say: "One true point means its whole side is true: the line is where it changes."
*Two at once* from problem 7: `y < 2x + 1` and `y ≥ −x + 4`: shade each; where both shadings overlap darkens; **place a
point** in the overlap and the record tests it in both.
*Stories (A.CED.3, N.Q.2)* from problem 9: "Adult tickets are $8, child tickets $5. At most 60 seats; we need at least
$400." The record names the letters first (`a = adult tickets, c = child tickets`), then **choose** each inequality
from two (`a + c ≤ 60`, `8a + 5c ≥ 400`); first quadrant, axes counting in 2s, a to 60 and c to 70 (60 × 35
squares; the plans that work sit low and to the right); **place a point** to try a plan, readout
`(30, 20): 50 seats, $340: not enough`; a point in the overlap is a plan that works. Say: "Every point in both shadings
is a plan that fits the seats and makes the money."
**Core:** new. m −3..3 (0 from problem 4, and x = k lines), b −6..6; the four signs; problems 1–3 y > or < a rising
line, dashed; 4–6 ≤, ≥, level and upright lines; 7+ two at once; 9+ stories with whole crossings. Slips: the wrong side
("(0, 0) makes it false: shade the other side"); solid for <. Check: one of each sign, a pair, a story.

## 4. Powers and roots

### Zero and negative exponents (`g9-negexp`, existing; 8.EE.1 carried up, the ground for N.RN.1; *fold* A.REI.3)
**One square:** a chip is 4 × 4 squares with the base in it (8th grade's chips), a square apart. **Picture:** `n` chips
of `a` in a row from row 6, named at its right end `2³`; under the row the paper writes each power as it's reached.
1. **Write** `2³ = [8]` (the web's step; slip "Multiplied by the exponent": "Multiply 3 copies of 2 together, not 2 × 3.").
2. **Count down: tap** the last chip; it lifts off, readout `2² = 8 ÷ 2 = 4`; tap again `2¹ = 2`; again `2⁰ = 1`: the
   row is empty and a faint 1 stays ("nothing left to multiply: 1").
3. **Keep going: tap** the empty row: a 2 drops under a fraction bar beneath the 1, `2⁻¹ = 1/2`; again `2⁻² = 1/4`; on to
   `2⁻³ = 1/8`. One tap too many: "That's 2⁻⁴. Stop at −3."
4. **Write** `2⁻³ = 1/[8]` (the web's flip step; slip "Thought it was a negative number": "A negative exponent doesn't
   make the number negative. It flips it: 1 over the power.").
Say: "Each step down divides by 2, so past 0 the 2s go under the bar."
*Fold (A.REI.3, its simple exponential equations), from problem 7: find the power.* `2ˣ = 1/16` or `5ˣ = 125`: the
chips count up or down by taps until the readout shows the number; **write** `x = [−4]`. Slip: 4 for 1/16 ("1/16 is
under the bar: the power is below 0."). `g11-expeq` keeps 2ˣ⁺¹ = 32.
**Core:** the web's generator as it is (a 2–5, n 1–3; smallest-of-six start), its two steps and slips, its check (i3
where n = 1; n = 2; n = 3; a ≥ 4 and n ≥ 2). The find-the-power kind is new: a 2–5, powers −4..4 with values up to 625.
(If G moves this lesson into 8th grade, as 8th grade's plan asks, the chapter opens with Fraction powers.)

### Fraction powers (`g9-fracexp`, new; N.RN.1, N.RN.2, A.SSE.1b) — cube roots in 3D
**One square:** a unit square is k × k squares, k the biggest of 5, 4, 3, 2 that keeps the square at most 30 across (as
8th grade's Square and cube roots); in 3D one cube is one block (Unit cubes). **Picture:** the empty corner of a square
(two edges, a handle on the far corner) from row 6, the problem as its name, `9^½`.
1. **Drag the corner**; it stays a square; readout `2 × 2 = 4`, `3 × 3 = 9`. Release at 9: the square fills and its two
   sides light, `3` and `3`. Too big: "That's 16. It needs 9."
2. **Write** the why, then the value: `9^½ × 9^½ = 9^(½ + ½) = 9^[1]`, so `9^½ = √9 = [3]`. Slip: 4.5 ("A power of ½
   isn't half. Two equal sides make 9: each is 3.").
Say: "Two equal factors make 9, and ½ + ½ is 1: so 9 to the half is the square's side, 3."
*Cubes (3D)*, problems 4–6: `8^⅓`. Flat, **drag the corner** of a square floor (`2 × 2 = 4`); the paper tilts; **drag up**
the layers (`2 × 2 × 2 = 8`); the box stays a cube ("A cube is the same every way: 2 layers on a 2 × 2 floor."). **Write**
`8^⅓ × 8^⅓ × 8^⅓ = 8^[1]`, `8^⅓ = ∛8 = [2]` (slip 8/3: "A power of ⅓ isn't a third. It's the cube's edge."). The
paper lies flat before the next problem.
*Rewrite (N.RN.2)* from problem 7, record only: `√7 = 7^[½]`, `∛x = x^[⅓]`, `x^½ · x^½ = x^[1]`, `(5^⅓)³ = 5^[1]` (the
fraction typed as a box over a box). `g11-ratexp` keeps the m/n powers (8^⅔).
**Core:** new; builds on 8th grade's `g8-roots` and `g8-exp`. Squares 4–100 (sides 2–10), cubes 8, 27, 64, 125 (edges
2–5); problems 1–3 squares, 4–6 cubes, 7+ rewrites mixed with both. Slips: halved, thirded, the power multiplied
(x^½ · x^½ = x^¼: "Multiplying adds the powers: ½ + ½."). Check: a square, a cube, a rewrite, x^½ · x^½.

### Simplify square roots (`g9-radical`, existing; N.RN.2; *fold* N.RN.3)
**One square:** 1. **Picture:** the problem's n squares in rows of 10 from row 6 (72 is seven rows and 2), named `√72`.
A handle at the block's right sets a tile size.
1. **Share into tiles** (7th grade's Share into rows, the handle setting the tile's size): the squares regroup into
   tiles of that many (a 2 is 1 × 2, a 6 is 2 × 3, a 7 is 1 × 7) and the tiles lay themselves out; when their count is
   a square number they close into a square of tiles. Readout `2s: 36 tiles, 6 × 6`. Sizes that don't divide n don't
   snap. A count that isn't square: "24 tiles of 3 can't make a square." A square from tiles that still hold one (9
   tiles of 8): "9 works, but 8 still has a perfect square inside. Look for a bigger one." (the web's smaller-squares
   slip, word for word)
2. **Write** `72 = [36] × [2]` (set from the move; slip "Square second": "Put the perfect square first, then what is
   left."), then `√36 = [6]` (slip "Halved it").
3. **Write** `√72 = [6]√[2]` (slips "The square came out": "The square doesn't come out. Its root does: √36 = 6."; "Left
   it all inside": "Once 6 is outside, only 2 stays under the root.").
See: the 36 tiles stand as 6 rows of 6, the count bracketed `6 × 6`; the check writes `(6√2)² = 36 × 2 = 72`. When
m is 2 or 5, a tile can be drawn as a true square on the grid's points (area 2: 1 across and 1 up on each side; area
5: 1 across and 2 up), so each tile turns into its tilted square and the 36 close into one big tilted square, 6 tile
sides along each edge: `6√2`, seen. (Tiles of 3, 6 or 7 can't be squares on the grid; they stay 6 rows of 6.)
Say: "36 tiles make 6 rows of 6, so 6 comes out; the 2 in each tile stays under the root."
*Fold (N.RN.3)*, from problem 9: simplify, then **choose** `rational` or `irrational`: `√2 × √8 = √16 = 4`; `3 + √2`;
`6√2`; `√18 ÷ √2 = 3`. Wrong: "√16 is exactly 4: a whole number is rational." / "√2's digits never end or repeat, so
3 + √2's don't either." Say: "Add a fraction to √2, or times it by one that isn't 0: it's still not a fraction."
**Core:** the web's generator as it is (k 2–6, m one of 2, 3, 5, 6, 7; smallest-of-six start), its three steps and
slips, its check (i3 where k is 2, 3 or 5; k = 4; k = 6; i3). The biggest picture, 6 × 6 tiles of 7, is 48 × 12. The
rational-or-not kind is new, with its own tests.

## 5. Growing and shrinking

### Exponential growth (`g9-growth`, existing; F.LE.1a, F.LE.5, A.SSE.1b, A.CED.2, F.IF.7e)
**One square:** the start. One square is P bacteria, written beside it (`1 square = 100`). **Picture:** one square from
row 6; the story is the instruction (the spec's lead: "**100** bacteria double every hour. How many are there after
**3 hours**?"); the picture's name is the rule, `× 2 each hour`.
1. **Drag the block's edge** (the kit's rectangle edge, snapping only at whole copies of the block): each release is an
   hour, and the copies go across, then down, so the block stays nearly square (for × 2: 1, 2, 2 × 2, 2 × 4, 4 × 4,
   4 × 8; for × 3: 1, 3, 3 × 3, 3 × 9, 9 × 9, 9 × 27, which is 27 × 9 squares). Readout `hour 2: 4 squares`. One hour
   too many: "That's 4 hours. Stop at 3." Each hour's count is written under the block as it's made: `1, 2, 4, 8`.
2. **Write** `2³ = [8]` (the web's factor step; slip "Multiplied instead of using a power", measured first: "That's 6
   squares. Doubling 3 times means 2 × 2 × 2.").
3. **Write** `100 × 8 = [800]` (the web's total; slip "Added": "Every one you start with grows by the factor: multiply.").
See (F.IF.7e): the hourly counts drop as points on a small graph beside the block (hours across, bacteria up, its scale
written on the axis), joined by a dashed curve that starts at 100 on the y-axis and bends up.
Record ends with what the numbers mean (F.LE.5): `100 × 2³`: `100 at the start, × 2 each hour, 3 hours`.
Say: "Every square doubles each hour: 3 hours make 2 × 2 × 2 = 2³ times as many."
**Core:** the web's generator as it is (start 10, 20, 50, 100, 200 or 500; doubling or tripling; 2 to 5 hours;
smallest-of-six start), its two steps and slips, the spec's lead instead of the display note, its check (i3 where r = 2;
r = 3; t ≥ 4; i3).

### Grow or shrink by a percent (`g9-percent`, new; F.LE.1c, F.IF.8b, A.SSE.3c, N.Q.3, F.LE.5)
**One square:** 1 (a fish, a dollar). **Picture:** a bar from row 6, 4 squares tall, as long as the start, named `32
fish` and `+25% a year`; each year's bar is drawn under the last, 2 squares apart, up to 60 squares long.
1. **Cut** the bar with the ruler into the percent's parts; it snaps to lengths that divide the bar; readout `quarters:
   8 each`. Wrong: "That's fifths. 25% is a quarter."
2. **Slide pieces:** a copy of one part slides onto the bar's end (growing), and the new bar is drawn under it, `32 + 8 =
   40`; shrinking, one part slides off and crosses out, `50 − 10 = 40`.
3. The next year: **cut** the new bar again (its quarters are 10 now, and the readout says so) and slide: `40 + 10 = 50`.
4. **Write** `+25% is × [1.25]`, then `32 × 1.25 × 1.25 = 32 × 1.25^[2] = [50]`. Slips: the same piece each year, 48
   ("The second quarter is of 40, not 32: 10, not 8."); × 0.25 ("+25% keeps the whole and adds a quarter: × 1.25.");
   × 0.2 for −20% ("Taking 20% leaves 80%: × 0.8.").
Say: "Each year's quarter is of a bigger bar, so it grows by more each year."
*Read the rate (F.IF.8b, F.LE.1c)* from problem 7, record only: `y = 500 × 0.97ᵗ`: **choose** `grows` or `shrinks`,
**write** `[3]% a year`. Amounts are reported as the story allows (N.Q.3): `1000 × 1.03⁵ = 1159.27…`, so `about [1159]
people` ("People come whole."), or dollars to the cent.
*Per hour from per three hours (A.SSE.3c)* from problem 9: "×8 every 3 hours": three equal stretches from 1 to 8
(**stretch from a point**: 1 to 2, 2 to 4, 4 to 8; each is × 2, though each is longer than the last) make × 8; **write** `8^⅓ = [2]` an hour (Fraction powers' idea); "× 1.21 every 2 years is × [1.1] a year: +10%".
**Core:** new. Factors and starts chosen so every year's bar is whole and at most 60 squares: × 1.5 from 8 or 16 (up
to 3 years: 16, 24, 36, 54) or 24 (2 years); × 1.25 from 16 or 32 (2 years) or 48 (1 year); × 1.2 from 25 (2 years:
25, 30, 36) or 50 (1 year); × 0.5 from 48 (up to 4 years); × 0.75 from 32 or 48 (2 years); × 0.8 from 25 or 50 (2
years); problems 1–3 one year, 4–6 two or three, 7+ reading rates (1–9%, growth and decay), 9+ per-hour kinds. Check: growth over 2
years, decay over 2, read a rate, round a story.

### Sequences (`g9-sequence`, new; F.IF.3, F.BF.2, F.BF.1a, F.LE.1a, F.LE.2)
**One square:** 1. **Picture:** term numbers 0 to 5 along a strong line, a block apart; each term a bar standing on its
number, the given ones drawn (`2, 5, 8`), the rest dashed outlines; the sequence written once as the picture's name,
`2, 5, 8, …`.
1. Adding (problems 1–3): **slide pieces**: drag the strip that lights between two bars (the 3 between 2 and 5) onto
   the last bar's top; the next bar fills; readout `term 3: 8 + 3 = 11`. Build to term 5. Wrong strip: "Each bar is 3
   more than the one before." Multiplying (problems 4–6, `3, 6, 12, …`): **stretch from a point** (8th grade's) from
   the bar's foot: drag the last bar's top; it snaps at whole copies of itself; readout `× 2: 24`. Adding instead: "6 to
   12 is × 2, and 12 to 24 is × 2 again: it doubles."
2. **Write** it both ways: `next = now + [3]`, `term 0 = [2]` and `a(n) = [2] + [3]n`; or `next = now × [2]`,
   `a(n) = [3] × [2]ⁿ`. Slips: start and step swapped; n − 1 jumps ("Term 0 is the start, so term n is n jumps from
   it.").
3. See: the bar tops become dots on the plane; the adding ones lie on a line, the multiplying ones bend up. The dots stay
   dots (F.IF.3): "The inputs are whole numbers 0, 1, 2…".
Say: "Adding the same each step makes a straight line; multiplying makes a curve that bends up."
*From two terms (F.LE.2)*, problem 9 on: only `term 1 = 7` and `term 3 = 13` are drawn; **hop** the gap in 2 equal hops
(`3` each), then build; or `term 0 = 1`, `term 2 = 9`: two equal stretches, `× 3` each.
**Core:** new. Every bar is at most 32 squares, so term 5's bar fits under the instruction rows. Adding: start 0–6,
step 1–5, term 5 at most 32 (from problem 7 also −3..−1 from a start of 20–30); multiplying: × 2 from 1–4 or × 3 from
1, built to the last term that's 32 or less (at least term 3); problems 1–3 adding, 4–6 multiplying, 7+ mixed, some
told as stories (F.BF.1a: "Row 0 has 12 seats, and each row after it has 4 more"; "4 people saw the video; each day
twice as many do"), 9+ from two terms. Terms stay 0–5; `g11-seq` and `g11-geo` keep far terms. Check: one adding, one falling, one doubling, one from two terms.

### Which grows faster? (`g9-overtake`, new; F.LE.3, F.LE.1b–c, A.REI.11, F.IF.9, N.Q.1)
**One square:** a story's scale, written on the up axis (`1 square = $20`), so every point is on a crossing.
**Picture:** the plane's first quadrant, weeks across (a block a week), dollars up; the two plans named at the top
left: `A: $200, + $60 a week` and `B: $20, × 2 a week`.
1. **Choose** for each plan: `same amount each week` or `same factor each week`; the record names them `linear` and
   `exponential`. Wrong: "B doubles its whole amount each week: the same factor."
2. **Hop** each plan from its start, a week at a time: A's hops are all the same height (`+60`); B's hop is as tall as
   B already is (`× 2`). The points join, A's in a line, B's in a curve.
3. **Sweep a line** across week by week; the readout shows both, `week 4: A 440, B 320`; release at the first week B
   is ahead, `week 5: A 500, B 640`. Wrong: "In week 4 B has 320 and A has 440: A is still ahead."
Record: `A = 200 + 60w`, `B = 20 × 2ʷ`, `week 5: 500 < [640]`, `B passes A in week [5]`.
Say: "A adds 60 each week; B doubles everything it has. Doubling always wins in the end."
*Tables (F.IF.9)* from problem 7: one plan as a table of weeks, the other as its rule. *Squares against doubling*
(F.LE.3) from problem 9: `n²` and `2ⁿ`; `n = 4: 16 = 16`, `n = 5: 25 < [32]`, "2ⁿ passes n² for good at 5".
**Core:** new. B's start is one square's worth s; × 2 (× 3 from problem 5); A's start 5s–15s and step 2s–5s, so every
point is on a crossing. B is 2ʷ or 3ʷ squares tall, so to stay on screen (32 squares at most) B passes A in week 3–5
for × 2 and week 2–3 for × 3, and the sweep stops there; A's start and step are drawn to fit (A ahead the week before,
B ahead that week). Slips: the week before ("In week 4, A is still
ahead."); A's rule as 200 × 60w ("A adds 60 each week: 200 + 60w."). Check: doubling against a line, tripling, a table,
n² against 2ⁿ.

## 6. Polynomials (algebra tiles: the area is the product)

### Add and subtract polynomials (`g9-polyadd`, existing; A.APR.1, A.SSE.1a)
**One square:** 1. Here only counts matter, so the tiles have fixed sizes: an x² is 3 × 3 squares with break marks, an x
a bar 1 × 3, a 1 a square; up to 3 tiles across in each kind's block (nine x² tiles are 11 × 11). **Picture:** the two
polynomials as two rows of tiles from row 6, each kind in its own column (the web's term table: `x²`, `x`, `1` over the
columns), each row named at its right end (`2x² + 3x − 1`, `x² − 5x + 4`). Taking away, the second row sits in a dashed
box with `−` at its left.
1. (Problems 1–3) **Tap** every x term, in both rows; readout `3x and −5x`. Wrong: "That's an x²: x is the bar."
2. (Taking away) **Flip over a line** (7th grade's Flip over 0, the minus as the line): drag the box over its minus;
   every tile in it turns over, solid ↔ striped, and the − becomes +; readout `−x² + 5x − 4`. An added box: "This one is
   added: it stays as it is."
3. **Slide pieces:** drag the second row up into the first, a column at a time; opposite tiles meet and cancel in pairs
   (7th grade's rule); readout `x: 3 + (−5) = −2` (taken away, after the flip, `x: 3 + 5 = 8`). Dropped in the wrong
   column: "x and x² aren't alike: they can't join."
4. **Write** the web's three lines, `2 + 1 = [3]`, `3 + (−5) = [−2]`, `−1 + 4 = [3]` (its slips: "Both polynomials are
   added, so add their numbers." / "The minus reaches every term in the second polynomial, including this one."); the
   paper writes `3x² − 2x + 3`.
Say: "Only like tiles join: x² with x², x with x, ones with ones." Taking away: "The minus turned every tile over; then
like tiles joined."
**Core:** the web's generator as it is (every coefficient −9..9, not 0; plus or minus half and half; smallest-of-six
start), its three steps and slips, its check (i3 where not sub; sub; sub and one of d, e, f below 0; i3).

### Multiply binomials (`g9-foil`, existing; A.APR.1; *fold* special products)
**One square:** 1 (area); x is X squares long, X = the bigger of |a| and |b| plus 3 (the web's), with a break mark.
**Picture:** the (x + a) by (x + b) rectangle from row 6, `x + 3` down its left, `x + 4` over its top; a negative part is
a striped strip. At most 21 × 21.
1. **Cut** across and down where x ends (the kit's cut, as Multiply two-digit numbers): the four parts move a square
   apart and name themselves, `x²`, `4x`, `3x`, `12`. Wrong: "Cut where x ends."
2. **Slide pieces:** drag the 3x strip round beside the 4x strip; it turns to lie along it; readout `4x + 3x = 7x` (the
   web's middle step; slip "Multiplied instead": "Outer and inner are two x terms side by side, so add them."). A
   striped strip slid onto a solid one cancels its length: `4x + (−3x) = x`.
3. **Write** `3 × 4 = [12]`, counted in the corner (the web's last step; slip "Added": "The last terms multiply."). A
   striped-by-striped corner is solid: "(−3) × (−4) = 12."
4. **Write** `x² + [7]x + [12]` (slip "Swapped them": "Outer + inner goes with x. Last × last is the number on its own.").
Say: "Every part of one side meets every part of the other."
*Fold* from problem 9: `(x + 3)²`, the square whose two strips match ("2 × 3x: the strips are the same"), and
`(2x + 1)(x + 3)`, two x's down the side. From problem 11, a binomial times a trinomial, `(x + 2)(x² + 3x + 1)`: x is
drawn 5 squares, so x² is a length of 25 and the rectangle is 41 × 7; six parts, `x³`, `3x²`, `x`, `2x²`, `6x`, `2`,
slid together by kind; **write** `x³ + [5]x² + [7]x + [2]` (11th grade's plan counts on this kind). A.APR.1's last
line: "Times a polynomial, it's still a polynomial."
**Core:** the web's generator as it is (a and b −9..9, never 0; smallest-of-six start), its steps, slips and check (i3
where a > 0 and b > 0; opposite signs; both below 0; i3), with the spec's fix (a middle of 0 writes 0, not 0x). New
kinds from problem 9: (x + a)² with a 1–6, and (2x + a)(x + b) with a, b 1–6; from 11, (x + a)(x² + bx + c) with a, b, c
1–3.

### Factor out the GCF (`g9-gcf`, existing; A.SSE.2)
**One square:** 1; x is 3 squares long (the web's X = 3, so every piece is to scale). **Picture:** the two terms as
tiles side by side on a strong line, not yet the same height: `6x²` as six x² tiles (3 × 3 each), `9x` as nine x bars;
named `6x² + 9x`.
1. **Share into rows** (7th grade's): drag the shared height handle; both parts re-deal; it snaps only to heights both
   can fill; readout `3 rows: 2x² | 3x`. Release on 3 (sets the number step). When g isn't prime there's a height that
   fits but isn't the tallest (12x² + 18x at 3 rows): "3 rows fit. 6 do too." (the web's slip "Not the biggest": "3
   divides both, but a bigger number does too.").
2. "Both have an x too." Drag the height on, from 3 rows of 1 to 3 rows of x: each row stands an x tall; readout `3x
   tall: 2x | 3`.
3. **Write** `6x² + 9x = 3x([2]x + [3])` (the web's slips: "Take 3x out of each term: divide each by 3x."; "Both terms
   share the 3x, so divide both by it.").
Say: "Both parts are 3x tall, so 3x comes out once."
**Core:** the web's generator as it is (g 2–6; m and n 1–7 sharing no factor; smallest-of-six start), its two steps
and slips, its check (i3 where g is 4 or 6; m = 1; i3; i3). The tallest picture is 6x = 18 squares.

### Factoring quadratics (`g9-factor`, existing; A.SSE.2, A.SSE.3a; *fold* signs)
**One square:** 1; x is X squares, X = q + 3 (the web's). **Picture:** the tiles of `x² + 7x + 12` from row 6: one x²,
seven x bars and twelve ones in a loose pile; named `x² + 7x + 12`.
1. **Drag the corner** of the ones (the kit's rectangle corner): the 12 re-deal into a rectangle in the x²'s corner,
   snapping only to whole rectangles (1 × 12, 2 × 6, 3 × 4); the x bars slide in along its two sides, as many as each
   side needs; readout `3 × 4: needs 3 + 4 = 7 bars`. Not 7: "2 × 6 needs 8 bars. There are 7." (the web's slips, right
   product and wrong sum, measured). Release on the pair that fits: the rectangle closes (sets the pair step).
2. **Write** `(x + [3])(x + [4])` (the web's second step).
Say: "The ones make a 3 by 4 corner, so the whole is x + 3 by x + 4."
*Fold (signs)* from problem 7: one or both numbers negative, `x² + 2x − 15`: striped bars cancel solid ones along the
sides and the corner is striped when the signs differ; **write** `(x + [5])(x − [3])`. Slip: "−5 and +3 add to −2. The
middle is +2: the bigger one is +."
**Core:** the web's generator as it is (p 1–9, q p..9; smallest-of-six start; order doesn't matter), its steps and
check (i3 where p ≥ 2; p × qn has 3 or more factor pairs; p = qn; i3). The signs kind is new from problem 7 (p and q −9..9,
not 0, not opposite), with its tests.

### Factor with a number on x² (`g9-factora`, new; A.SSE.2, A.SSE.3a)
**One square:** 1; x is 8 squares. **Picture:** the tiles of `2x² + 7x + 3`: two x² tiles stacked, seven x bars, three
ones.
1. **Drag the corner** of the ones as in `g9-factor`; now one side of the corner runs along two x²'s, so it needs twice
   the bars: readout `1 × 3: 2 × 3 + 1 = 7 bars`. Turned the other way: "3 × 1 needs 2 × 1 + 3 = 5 bars. There are 7."
2. **Write** `(2x + [1])(x + [3])`.
See: the rectangle's sides light, `2x + 1` down the side and `x + 3` across, and the strips name themselves `6x` and `x`.
Say: "Two x²'s stack down the side, so the 3 sits beside 2x: (2x + 1)(x + 3)."
**Core:** new; builds on `g9-factor` and `g9-foil`'s (2x + a) kind. a = 2, 3 or 5, (ax + p)(x + q) with p, q 1–6, the
two orders giving different middles; problems 1–3 a = 2, 4+ 3 and 5, 7+ one sign negative. Slips: the turned corner
((2x + 3)(x + 1)); the a forgotten ((x + 1)(x + 3)). Check: a = 2, a = 3, a turned trap, a negative.

### Difference of two squares (`g9-diffsq`, new; A.SSE.2)
**One square:** 1; x is 20 squares (15 for the 2x kinds, so 2x is 30), with a break mark, so the picture fills the
screen and the b × b hole (b up to 9) is under half. **Picture:** an x² square, 20 × 20, from row 6 with a b × b square
taken from its corner (striped, crossed off), leaving an L; named `x² − 9`. The long rectangle it becomes is 23 × 17.
1. **Cut** the L with the ruler; it snaps only along the small square's edge: two rectangles, `x` by `x − 3` and `3` by
   `x − 3`. Wrong place: "Cut along the edge of the 3 × 3 hole."
2. **Turn a shape** a quarter and **slide** it to the end of the big one; they make one long rectangle; readout `x + 3
   by x − 3`. Somewhere else: "Put it at the end, so the x − 3 sides meet."
3. **Write** `x² − 9 = (x + [3])(x − [3])`. Slip: `(x − 3)²` ("That's a square again: it has 9 back in the corner.").
Say: "Taking 9 off a square leaves an L, and the L makes a rectangle x + 3 by x − 3."
From problem 4: `4x² − 25 = (2x + [5])(2x − [5])` (the big square is 2x on a side). From problem 7, the structure
(A.SSE.2's own example), record only: `x⁴ − 16 = (x²)² − 4² = (x² + [4])(x² − [4]) = (x² + 4)(x + [2])(x − [2])`, and
numbers, `53² − 47² = 100 × [6]`.
**Core:** new. b 1–9; k²x² − b² with k 2–3; the x⁴ kind with b 1–3; numbers whose sum is 100. Slips: (x − b)²;
(x + b)(x + b). Check: plain, 4x² − 25, x⁴ − 16, a numbers one.

## 7. Parabolas and other graphs (the plane)

### Solve by factoring (`g9-solvefactor`, existing; A.SSE.3a, A.REI.4b, F.IF.8a)
**One square:** 1. **Picture:** the plane; the equation as the record's first line, `x² − 5x + 6 = 0`; its parabola
drawn faint, framed around where it meets the x-axis and its low point (its tall arms run off the frame); a point on the
x-axis with two small bars standing over it, one for each factor's value.
1. **Write** `(x − [2])(x − [3]) = 0` (the web's factor step, either order; slip "Flipped the signs": "(x − m)(x − n)
   multiplies out to x² − (m + n)x + mn: check the signs."; its hint fixed as the spec says: "Find two numbers that
   multiply to 6 and add to 5, then write them in."). Show me can borrow `g9-factor`'s tile corner.
2. **Drag a point along** the x-axis: the two bars change with it and the readout multiplies them, `x = 4: 2 × 1 = 2`;
   the parabola's height over the point lights. Release where the product is 0, then find the other. Wrong: "At x = 4
   the factors are 2 and 1: their product is 2, not 0."
3. **Write** `x = [2] or x = [3]` (the web's roots step; slip "Flipped the signs": "x − 2 = 0 means x = 2.").
Say: "A product is 0 only when one factor is 0: x − 2 = 0 or x − 3 = 0. That's where the graph meets the x-axis."
**Core:** the web's generator as it is (two different roots 1–9; smallest-of-six start), its two steps and slips with the
spec's hint fix, its check (i3; i3 where p × r has 3 or more factor pairs; p ≥ 5 and r ≥ 5; i3).

### Graph a parabola (`g9-parabola`, new; F.IF.7a, F.IF.4, F.IF.8a, A.CED.2, F.IF.5)
**One square:** 1 (a story's up axis in 5s). **Picture:** the plane; the function as the record's first line,
`y = (x − 1)(x − 5)`.
1. **Place a point** at each zero: readout `(1, 0)`. Wrong: "At x = 2, (2 − 1)(2 − 5) = −3, not 0."
2. **Flip over a line:** drag a dashed upright line across; the zeros fold over it as it moves; at x = 3 they land on
   each other; readout `x = 3: 1 lands on 5`. Elsewhere: "At x = 2, 1 lands on 3, not on 5." That line is the axis.
3. **Drag a point along** the axis to the turn: readout `(3 − 1)(3 − 5) = −4`; **write** `vertex ([3], [−4])`.
4. **Place a point** one step outside the left zero (here x = 0: `(0, 5)`; one step out keeps it at most 9 high, where
   x = 0 could be 48); its mirror `(6, 5)` appears by itself; the parabola draws through the five.
Record: `zeros 1 and 5` · `axis x = [3]` · `vertex ([3], [−4])` · `lowest value [−4]`.
Say: "The zeros sit 2 either side of 3, so the low point is at x = 3."
*Stories* from problem 7: "A ball is thrown up: h = −5t² + 20t." Zeros at 0 and 4 seconds, axis t = 2, top 20 m;
**choose** the domain, `0 ≤ t ≤ 4` (F.IF.5: "Before 0 it wasn't thrown; after 4 it's on the ground."). *Vertex form* from
problem 9: `y = (x − 2)² − 9`: the vertex is read off first, then the zeros 3 either side (Complete the square's way).
**Core:** new. Zeros r1 < r2 with r1 + r2 even (a whole axis), −6..8, 2 to 8 apart (so the turn is at most 16 from
the axis); a = 1, from problem 4 also −1 (a top, not a
bottom); stories a = −5 landing at 2 or 4 s (top 5 m or 20 m; 3 s would put the top at 11.25, off a crossing); vertex form h −4..4, k = −1, −4, −9 or −16. Slips: the axis as a zero; the
sum for the halfway point ("Halfway between 1 and 5 is 3."); the vertex's y sign. Check: a = 1, a = −1, a ball, vertex
form.

### Slide and stretch a graph (`g9-shift`, new; F.BF.3, F.BF.1b)
**One square:** 1. **Picture:** the plane; a parent graph in pencil (`y = x²`, `y = |x|`, `y = 2x` or `y = 2ˣ`) with a
round handle on its vertex (or where it crosses the y-axis), and the target graph dashed in the chapter colour, named
only by its picture.
1. **Slide a shape** (8th grade's; here the graph): the readout is the equation as it moves, `y = (x − 3)² + 2`.
   Release on the target: it locks. Elsewhere: "It's 1 too high. The dashed one's low point is (3, 2)."
2. **Stretch a graph** (new): drag the second handle, two steps right of the vertex (so × ½ still lands on a crossing:
   ½ × 4 = 2), up or down; snaps at × ½, × 2, × 3 and × −1 (it turns over); readout `y = 2(x − 3)² + 2`.
3. **Write** the target's equation, `y = [2](x − [3])² + [2]`. Slips: the sign inside ("3 right is x − 3: inside, it
   works backwards."); the slides swapped.
Say: "Slid 3 right and 2 up: x − 3 inside, + 2 outside; twice as steep: × 2."
Problems 1–3 (Algebra 1's first focus): up-and-down slides of lines and exponentials only, `y = 2x` to `y = 2x + 3`
("Up 3 adds 3: the line now crosses the y-axis at 3."), `y = 2ˣ` to `y = 2ˣ − 4`. 4–6: parabolas and |x|, slides only;
7+: stretches and turns. *Even and odd* (from problem 9): **choose** `its own mirror` (even: x², |x|), `the same after a
half turn` (odd: x³, 2x) or `neither` (2ˣ), then the paper flips it to show.
*Building one from two (F.BF.1b)* from problem 11: "The room is 20°. The tea starts 64° warmer, and the difference halves
every 10 minutes." t counts 10-minute steps (a block each). Slide the halving curve `64 × ½ᵗ` up 20: **write** `T =
[20] + [64] × ½ᵗ`; it levels off at the room's 20°.
**Core:** new. h −5..5, k −6..6, stretches −1, ½, 2, 3; vertical slides first; then sideways; then stretches. Check: a
line slid up, a parabola slid two ways, a stretch, even or odd.

### Pieces, steps and corners (`g9-piecewise`, new; F.IF.7b, F.IF.5)
**One square:** 1 (a story's scale). **Picture:** the plane; the rules as the record's first lines.
1. *Absolute value* (problems 1–3), `y = |x − 2|`: **place points** from a small table (x from 0 to 4, the paper fills
   the rest); they make a V; **draw a graph** through them. Wrong point: "|0 − 2| is 2: a distance is never below 0."
2. *Pieces* (4–6), `y = x + 1 for x < 2` and `y = 5 − x for x ≥ 2`: **draw** each piece only over its own x's, then
   **tap** each end where a piece stops, to fill or open it. Wrong: "< leaves 2 out of this piece: open."
3. *Steps* (7–8): "Parking is $3 for each hour or part of one, up to 4 hours." Draw the level steps; ends open on the
   left, filled on the right; **write** `cost(2.5) = $[9]`. Slip: "2.5 hours is part of a third hour: $9."
4. *Roots* (9+): `y = √x` through (0, 0), (1, 1), (4, 2), (9, 3), (16, 4); `y = ∛x` through (−8, −2), (−1, −1), (0, 0),
   (1, 1), (8, 2): **place** and **draw**, then **choose** where each starts (√x at 0; ∛x has no start).
Record: the value asked, `f(3) = [1]`, and the domain written as the paper reads it from the graph.
Say: "Each rule draws only over its own x's." / "|x − 2| is the distance from 2: it never goes below 0."
**Core:** new. |x − h| + k with h −4..4, k −3..3; two-line pieces meeting or jumping at a whole x; step prices $2–$5;
the root graphs as listed. Slips: the corner on the wrong side (x + 2 for x − 2); the wrong end filled; a step's value
at a whole hour ("Exactly 2 hours is 2 × $3: the filled end."). Check: a V, two pieces, steps, a root.

## 8. Solving quadratics

### Solve with square roots (`g9-sqroot`, new; A.REI.4b)
**One square:** 1. **Picture:** the plane; the parabola `y = (x − 3)²` (its low point on the x-axis at 3) and a level
line at 16, named `16`; the equation as the record's first line, `(x − 3)² = 16`.
1. **Drag a point along** the parabola from its low point up to the level line; a small square grows on its distance
   from 3 as it climbs; readout `4 from 3: 4 × 4 = 16`. Release on the line: `(7, 16)`.
2. **Flip over a line:** drag the point across the axis x = 3; it lands mirrored, `(−1, 16)`. Readout `4 the other
   way`.
3. **Write** `x − 3 = [4] or x − 3 = [−4]`, then `x = [7] or x = [−1]`. Slips: one answer only ("−4 × −4 is 16 too:
   there's an answer on each side."); 19 ("Undo the square first: x − 3 is 4 or −4.").
Say: "4 or −4 squared makes 16, so x is 4 either side of 3."
Problems 1–3 by inspection, `x² = 25` (the low point at 0). 4–6 `(x − h)² = n`. 7–8 a step first, record only:
`2(x + 1)² = 32` or `x² − 5 = 20`. *No answer* (from problem 9): `(x − 1)² = −4`: the level line lies under the low
point; **choose** `no answer`. Wrong: "No number times itself is below 0: they never meet."
**Core:** new. n a square 1–25 (the level line at most 25 squares up, so it fits the plane; one square a unit keeps
the growing square's area equal to the height); h −5..5; the step-first kinds with a 2–3 or c 1–20; no-answer one in six from problem
9. Check: inspection, (x − h)² = n, a step first, none.

### Complete the square (`g9-complete`, new; A.REI.4a, A.SSE.3b, F.IF.8a)
**One square:** 1; x is 16 squares with a break mark (b ÷ 2 is at most 6, so the corner is clearly smaller than x).
**Picture:** algebra tiles: the x² square (16 × 16) and b x bars (1 × 16 each) standing in a row on its right, from
row 6; named `x² + 6x`. Completed, it's at most 22 × 22.
1. **Slide pieces:** drag half the bars round to lie along the square's bottom (they turn as they go); readout `3
   right, 3 below`. Uneven: "4 and 2: share them equally so it can become a square."
2. **Tap** the empty corner: it fills with ones, counted, `3 × 3 = 9`.
3. **Write** `x² + 6x + [9] = (x + [3])²`. Slips: 36 ("The corner is 3 by 3: 9."); (x + 6)² ("Each side got 3 bars:
   x + 3.").
Say: "Half the bars on each side, and 9 fills the corner: a square, x + 3 on a side."
*Solve (A.REI.4a)* from problem 4: `x² + 6x = 7`: the record goes on, `x² + 6x + 9 = 7 + [9]` (slip: "The 9 goes on both
sides, so they stay equal."), `(x + 3)² = [16]`, then Solve with square roots' move on the graph, `x = [1] or [−7]`.
*The low point (A.SSE.3b, F.IF.8a)* from problem 7: `y = x² + 6x + 5 = (x + 3)² − [4]` ("5 is 4 short of the 9"); then
**drag a point along** the graph to its lowest: `(−3, −4)`. Say: "A square is never below 0, so the lowest is −4,
when x + 3 is 0."
Negative b (from problem 9): the bars are striped, `x² − 8x = (x − 4)² − 16`.
**Core:** new. b even 2–12 (−12..−2 from problem 9); equations with whole answers ((x + b/2)² = a square 1–81); low
points with k −16..9. Check: a square completed, an equation, a low point, a negative b.

### The quadratic formula (`g9-quadform`, existing; A.REI.4a, A.REI.4b; *fold* no real answer)
**One square:** 1. **Picture:** two parts side by side. Left, b² − 4ac in real squares: a b × b square (`2 × 2`) and
four c-rectangles beside it, each |c| squares as a rectangle whose sides are the two roots' sizes (`4 × 2`, so 8),
solid when − 4ac adds (c below 0), striped when it takes away (c above 0). Right, the plane: the parabola faint, its
axis x = 1 (half of −b) dashed. `x² − 2x − 8 = 0` as the record's first line with the formula under it (the web's note,
kept as the spec says: a tool, not a copy of the problem).
1. **Slide pieces:** drag the four rectangles round the b square; each snaps into a pinwheel round it (one on each
   side, turned a quarter each time) and the count runs on, `4 + 8 + 8 + 8 + 8 = 36`; with the fourth they close into
   one square, 6 × 6. When c is above 0 the b square is the big one and the four striped rectangles slide onto it,
   cancelling as they land (7th grade's rule); the hole left in the middle is the square. Readout the count.
   Then **write** `(−2)² − 4(1)(−8) = [36]` (the web's D step; slip "Sign slip": "Keep the sign: − 4ac, with c = −8.
   The rectangles add."). When c is 0 there are no rectangles: the b square is already it.
2. The square's side lights, `6`; **write** `√36 = [6]` (slip "Halved it": "The root is the number that times itself
   makes 36: the square's side."). The biggest square is 16 × 16 (roots 8 and −8).
3. **Drag a length:** two points on the x-axis move apart together from the axis at 1; readout `6 apart: −2 and 4`;
   release when they're 6 apart: they sit on the parabola's zeros. Wrong: "They're 4 apart. √36 says 6."
4. **Write** `x = (2 + 6) ÷ 2 = [4] or x = (2 − 6) ÷ 2 = [−2]` (the web's step; slips "Used +b": "The formula starts
   with −b, the opposite of b."; "Didn't divide by 2a": "Divide both by 2a, which is 2 here.").
Say: "b² − 4ac is 36, so the answers sit 6 apart, centred on x = 1."
Its **How to** derives the formula (A.REI.4a): Complete the square's tiles with letters, `x² + bx + c = 0`, b ÷ 2 bars on
each side, the corner (b ÷ 2)²; the ghost finger plays it and the formula is what's left.
*Fold (A.REI.4b)* from problem 9: one problem in five has b² − 4ac below 0: the parabola sits above the x-axis and the
striped rectangles cover more than the b square: there's nothing left to make a square ("A square can't have an area
below 0."); the no-answer kinds draw their rectangles from c's own factor pair; **choose** `no real answer`. One in ten has 0: the points
don't part, `one answer`. Say: "Below 0, so the graph never reaches the x-axis." (Answers with i wait for 11th grade.)
**Core:** the web's generator as it is (two different roots −8..8; the first three with no root at 0; smallest-of-six
start), its three steps and slips, its check (i3 where r1 × r2 < 0; both below 0; both above 0; r1 × r2 ≠ 0). The
no-answer and one-answer kinds are new (b −8..8, c whole, |c| ≤ 20), with tests.

### A line meets a parabola (`g9-linequad`, new; A.REI.7, A.REI.11)
**One square:** 1. **Picture:** the plane; `y = x²` and `y = 2x + 3`, each named at its end.
1. **Place a point** where they cross; the readout checks it in both: `(3, 9): 3² = 9 ✓, 2 × 3 + 3 = 9 ✓`. On one only:
   "(2, 4) is on y = x², not on the line: 2 × 2 + 3 is 7." Then the other crossing.
2. **Sweep a line** between them: readout `x = 1: line 5, parabola 1`; the line is above between the crossings, below
   outside them.
3. **Write** the school way: `x² = 2x + 3` · `x² − 2x − 3 = 0` · `(x − [3])(x + [1]) = 0` · `x = [3] or [−1]` ·
   `y = [9] or [1]`.
Say: "Where they cross, both have the same y, so x² = 2x + 3 there."
From problem 7: a line that just touches (one point) or misses (**choose** `they never meet`); from 9, `y = x² + c` with
c −4..4.
**Core:** new. Parabolas y = x² + c; lines through two whole points of the parabola, x −4..5, the line's slope −4..6;
problems 1–3 c = 0 and both crossings in view; touching and missing from 7. Slips: one crossing only ("A line can cross a
parabola twice."); y left out. Check: two crossings, a negative x, one touch, none.

## 9. One set of data

### Find the median (`g9-median`, existing; S.ID.2; *fold* S.ID.3)
**One square:** 1. **Picture:** the numbers as bars from row 6, a block apart, up to 30 tall (the record beside them);
the list written once as their name, `7, 2, 9, 4, 5`.
1. **Tap** each bar to count it; it lights and numbers itself, repeats too; readout `5` (sets the web's count step;
   stopping short, its slip "Missed one": "Count every number, including any that repeat.").
2. **Sort** (6th grade's move): drag a bar to its place and the others make room; readout `in order`. Then **write**
   `(5 + 1) ÷ 2 = [3]` (the web's spot step; slip "Forgot the + 1": "Add 1 before halving: (5 + 1) ÷ 2.").
3. **Tap** the bar in spot 3; **write** `median = [5]` (the web's step; slip "Didn't sort first": "Put the numbers in
   order from least to greatest first.").
Say: "In order, 5 is in the middle spot: 2 below it and 2 above."
*Fold (S.ID.2–3), from problem 7: which middle fits?* Half the problems have one far value (`3, 4, 5, 6, 30`). After
the median, the mean's level line draws across the bars (6th grade's balance line, `mean 9.6`); **choose** which middle
tells about most of the bars: `the median` or `the mean`. Wrong: "4 of the 5 bars are under the mean: the 30 pulled it
up." Say: "One far value drags the mean; the median stays with the crowd."
**Core:** the web's generator as it is (5 or 7 whole numbers 1–30; smallest-of-six start), its three steps and slips,
its check (5 numbers; 7 numbers; the unsorted middle isn't the median; a repeat). The far-value kind is new from
problem 7 (the far one at least 15 past the rest), with its tests. 6th grade's `g6-median` teaches the median first;
here it's the review that leads to choosing (see the open questions).

### Compare with box plots (`g9-boxplots`, new; S.ID.1, S.ID.2, S.ID.3)
**One square:** 1 on the line (a minute, a point); one dot is one square, stacked. **Picture:** two dot plots on one
line 0–40, one group above it and one below (as 7th grade's Compare two groups), each named at its left (`Class A`,
`Class B`) and the question in the instruction ("Minutes on the bus").
1. **Drag a length:** for each group, drag the box's middle line and its two edges along the line; they snap to dots
   and to halfway between two; readout `Q1 = 12: the middle of the lower half`. Wrong: "That's not the middle of the
   lower half: 4 of its dots are on one side, 1 on the other."
2. **Write** `IQR = 18 − 12 = [6]` for each (slip: the range, "The IQR is only the box: 18 − 12.").
3. **Hop** a fence from each end of the box: one IQR and a half (`6`, then `3`); readout `18 + 9 = 27`. Dots past a fence
   turn hollow; **tap** each one, and it's ringed `outlier`; the whisker stops at the last dot inside. Wrong tap: "25 is
   inside the fence at 27."
4. **Choose** `A's middle is higher` or `B's`, then `A is more spread` or `B` (by the IQRs).
Record: `A: median [15], IQR [6], outlier 33` · `B: median [20], IQR [10]`.
Say: "B's middle half sits higher and is wider; A's 33 is past its fence, so it's an outlier."
*Histograms (S.ID.1)* from problem 9: one group drawn as a histogram (bins 5 wide); **choose** which of two box plots fits
it, or **tap** the bin the median is in.
**Core:** new; builds on 6th grade's `g6-boxplot` and 7th grade's `g7-compare`. Groups of 11–15 values 0–40 (11 or 15
in problems 1–3: each half then has an odd count, so every quarter mark is a dot; 12–14 later, where a mark can fall
halfway between two dots); problems 1–3 one group, 4–6 two, 7+ an outlier in half (past the fence by
3 or more), 9+ a histogram. Check: one group, two groups, an outlier, a histogram.

### Standard deviation (`g9-sd`, new; S.ID.2)
**One square:** 1. **Picture:** the data as bars from row 6, a block apart (so the biggest gap's square fits beside its
bar), named by the list `2, 4, 4, 4, 5, 5, 7, 9`; a level line across them with a handle.
1. **Drag** the level line to where the bars balance (6th grade's mean move): readout `6 above, 6 below`; release at the
   mean, `5`.
2. **Raise a square on a side** (8th grade's): on each bar's gap to the line, drag its handle out; a square sweeps out
   beside the bar, counting `3 × 3 = 9`; a bar on the line has no square. Readout, the running total `9 + 1 + 1 …`.
3. **Share into rows** (7th grade's): all the squares' unit squares slide into one pile and deal into 8 rows (one per
   value): `8 rows of 4`. **Write** `32 ÷ 8 = [4]`, the average square.
4. **Drag the corner** of a square to hold 4: `2 × 2`. **Write** `SD = √4 = [2]`.
Record: `(9 + 1 + 1 + 1 + 0 + 0 + 4 + 16) ÷ 8 = [4]` · `SD = √4 = [2]`.
Slips: the gaps averaged without squaring, 1.5 ("That's the average gap (6th grade's MAD). Square each gap first."); the
root forgotten, 4 ("4 is the average square. Its side is the SD."); gaps with signs, 0 ("A gap below the line is still a
gap: its square counts.").
Say: "The average square is 4, so a typical gap from the mean is its side: 2."
*Compare (S.ID.2)* from problem 7: two sets with the same mean; **choose** the more spread, then check with the SDs.
**Core:** new. Population SD (÷ n: the average square, as the picture shows). Sets of 4–8 values 0–20, mean 4–15, made
from gaps of 0–4 (each square fits between two bars) whose squares average 1, 4 or 9 (the generator searches); problems
1–3 four values (`3, 3, 7, 7`), 4–6 six
to eight, 7+ compare. Check: four values, eight values, a value on the mean, compare.

## 10. Data in pairs

### Parts of a two-way table (`g9-relfreq`, new; S.ID.5)
**One square:** a person is a 3 × 3 cell. **Picture:** the hero is the 100 people of the survey as a 10 × 10 block of
cells (30 × 30 squares, from row 6), standing in reading order: the sport players first (a square's gap after them),
then the rest; a pet owner is solid, no pet striped. So the 40 sport players are the top 4 rows (3 rows solid, 1
striped) and the 60 others the 6 under them. Beside it the two-way table is the record (cells 6 × 3 squares, numbers
28): rows `sport`, `no sport`; columns `pet`, `no pet`, `total`; one cell empty.
1. **Tap** the striped sport players: they light and count, `10`; **write** the empty cell, `40 − 30 = [10]`.
2. "What part of everyone plays a sport and has a pet?" **Tap** those people in the block (a tap lights the whole
   group); readout `30 of 100`; their table cell lights; **write** `[30]%` (joint).
3. "What part of everyone has a pet?" **Tap** every solid group: `54 of 100`; **write** `[54]%` (marginal).
4. "Of the sport players, what part has a pet?" **Tap** the sport rows: the other 60 people fade, so only 40 are left
   to count from; then the solid ones: `30 of 40`; **write** `30 ÷ 40 = [75]%` (conditional). Slips: of everyone, 30% ("Only the sport players count here:
   30 of 40."); of the pet owners, 56% ("Of the sport players, not of the pet owners: 30 of 40.").
5. The same for the others, `24 of 60 = [40]%`; then **choose** `linked` or `not linked`. Wrong: "75% against 40%: not
   the same."
Say: "75% of the sport players have a pet, but only 40% of the others: here the two go together."
**Core:** new; builds on 8th grade's `g8-twoway` (row percents). Totals of 100 in problems 1–6 (a person is a cell; row
totals are tens, so each row's people fill whole rows of the block), 50 or 200 later (50: the block is 10 × 5 at the
same size; 200: a cell is 2 people, every count even); conditional percents whole or to one decimal; half linked (rows
25 points apart or more), half not (within 5). Check: joint, marginal, conditional, linked or not.

### Residuals (`g9-residual`, new; S.ID.6a–c, S.ID.7, F.LE.5)
**One square:** a story's scale (hours across; test points up, counting in 5s). **Picture:** 8–10 points from a table,
and the class's line through them, named `y = 5x + 50`; under the plane a strip with a 0 line for the residual plot.
1. **Tap** a point: a dashed stick drops or rises from it to the line, measured on the grid; readout `10 above the
   line: +10`; the residual is written beside the point. Tap every point (problems 1–3: three of them; the paper does the
   rest).
2. **Place a point** for each on the strip, at its residual's height above or below 0. Wrong: "That one was 10 above
   the line: put it 10 above 0."
3. **Choose** `no pattern: the line fits` or `a bend: a curve fits better`. Wrong: "They go down, up, down: a pattern."
4. **Write** one the school way: `residual = 85 − (5 × 6 + 50) = 85 − [80] = [5]` (slip, the other way round, −5:
   "actual − predicted: above the line is +.").
5. (S.ID.7) **Choose** what the line's numbers mean: `each hour of study: about 5 more points`; `with no study: about 50`.
Say: "The leftovers scatter around 0 with no pattern, so the line fits."
*Curved data (S.ID.6a)* from problem 7: points from a bend (a parabola or a doubling) with a straight line through them:
the residuals make a U; **choose** `a curve fits better`; the paper draws the curve and its residuals flatten. *Your own
line (S.ID.6c)* from problem 9: **lay a line** first (8th grade's Fit a line and use it), then its residuals.
**Core:** new; builds on 8th grade's `g8-scatter` and `g8-fitline`. 8–10 points from y = mx + b plus whole noise (−3..3
squares), m 1–6 and b 0–60 in story units; curved sets from a(x − h)² + k or a × 2ˣ; residuals judged from the child's
own line when they laid it. Check: a residual's sign, a residual plot, straight or curved, what the slope means.

### Correlation (`g9-corr`, new; S.ID.8, S.ID.9)
**One square:** a story's scale. **Picture:** a scatter of 8–12 points on the plane, filling it; the middle of the
cloud (the mean of the x's and of the y's, always a crossing) marked by a dashed cross that splits the plane into four
corners. The paper works out r (S.ID.8 says by technology); school writes the number it's given, so the child never
types it.
1. **Tap** each point: a rectangle draws from the cross to it, solid when the point is up-right or down-left of the
   middle (the two move together), striped when it's up-left or down-right (they move apart); readout `with 7, against
   1`. r is built from exactly these rectangles: the solid ones push it up, the striped ones pull it down.
2. **Choose** a word for the cloud: `strong up`, `weak up`, `none`, `weak down`, `strong down`; the paper writes its r,
   `r = 0.93`. Wrong: "7 rectangles with, 1 against, and the points hug a line: strong up."
3. **Drag a point** (place a point): its rectangle grows and shrinks with it and r follows in the pill, `r = 0.62 →
   0.91`; "Drag the far point into the cloud." Release when r reaches the asked band. Wrong band: "r is 0.70. Its
   striped rectangle is still big: bring it closer."
4. Three small clouds side by side: **tap** them from the lowest r to the highest (or match them to `−0.9`, `0.1`,
   `0.8`). Wrong: "This one's rectangles are mostly striped: its r is below 0."
Record: `r = 0.93: strong, up together` (the words from the choice; the number written by the paper).
Say: "Almost every rectangle is solid: the two go up together, so r is close to 1."
*Cause (S.ID.9)* from problem 7: "Towns that sell more ice cream have more sunburns. r = 0.9." **Choose** `ice cream
causes sunburn` or `something else, like sunny days, brings both`. Wrong: "Eating ice cream doesn't burn you: sunny days
bring both." Say: "Together isn't because: a strong r doesn't mean one causes the other."
**Core:** new. Clouds from y = mx + b plus noise, drawn to land in a target band of r (strong ≥ 0.8, weak 0.3–0.6, none
under 0.2, either sign), with whole means so the cross sits on a crossing; Pearson's r from the same points as the
picture (the rectangles' areas are its top line); problems 1–3 strong or none, 4–6 drag tasks,
7+ cause stories (a small set: ice cream and sunburn, shoe size and reading in a school, hours of TV and test scores).
Check: strong, weak, falling, a cause story. (The cross and its rectangles are a new picture, built from 7th grade's
striped-is-negative rule: part of G's preview.)

## Open questions for G

1. **Algebra 1 topics the web teaches in 11th grade.** Common Core starts fraction powers, sequences, undoing a function
   and the vertex in Algebra 1, but the web puts `g11-ratexp`, `g11-seq`, `g11-geo`, `g11-inverse` and `g11-vertex` in
   11th grade. This plan teaches only the Algebra 1 part here (½ and ⅓ powers; sequences from term 0; solving y = 2x + 3
   for x; the vertex from the zeros and by completing the square) and leaves the 11th grade lessons as they are. OK, or
   move any of them down to 9th grade?
2. **The median and negative exponents.** 6th grade's plan teaches the median (from `g9-median`'s own problems), and 8th
   grade's plan folds zero and negative exponents into its Exponent rules; both ask whether the 9th grade lessons should
   go. This plan keeps both here as short reviews that lead on (to choosing the right middle; to fraction powers). Keep
   them in 9th grade, or drop them?
3. **36 lessons.** 13 from the web and 23 new, about as many as 7th and 8th grade. Build the 13 web lessons first (their
   maths is written), or each chapter whole, in teaching order?
4. **Three new hand moves** need your yes on a preview first: Shade a side, Flatten onto an axis, Stretch a graph. The
   rest are 6th, 7th and 8th grade's planned moves. Two new pictures need it too: the four rectangles that close round
   b² into a square of b² − 4ac (The quadratic formula), and the middle cross with its solid and striped rectangles
   (Correlation).
5. **How big the plane is.** One square a unit (8th grade's choice) makes small parabolas small: `y = (x − 1)(x − 5)`
   dips only 4 squares. This is 8th grade's open question too; whatever you pick there applies here. It matters most
   for Domain and range, Read a graph, Average rate of change, Slide and stretch, and Pieces, steps and corners, whose
   graphs live inside about 16 × 14 units and are framed at 125% on a plane that otherwise runs to the screen's edges.
