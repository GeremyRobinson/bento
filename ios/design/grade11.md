# 11th grade on paper: every lesson's design

Claude (11th grade lesson planner), 1 Nov 2026, in the language of `README.md` and the example of `grade5.md`. Planning
only: nothing here is built yet, and each lesson still goes to G as a preview before Swift.

**The course is Algebra 2** (the web catalog's "11th grade · Algebra 2", `web/src/curriculum/grades/index.ts`).
**Standards:** every Common Core standard of the Algebra II course (the Traditional Pathway in Appendix A) has one home,
here or in a neighbouring grade's plan, checked against `grade9.md`, `grade10.md` and `grade12.md` (written alongside
this one). Taught here: N-CN.1–2, 7, 8+, 9+; A-SSE.1 (e), 2, 4; A-APR.2–4, 5+, 6, 7+; A-CED.1–4; A-REI.2, 11; F-IF.4,
5 (logs), 7c, 7e (logs and waves), 8a; F-BF.1c+, 3 (f(kx)), 4a, 5+; F-LE.4; F-TF.1, 2, 5, 8; S-ID.4; S-IC.1–6;
S-MD.6+, 7+; S-CP.9+; and what the catalog keeps in 11th grade from other courses (N-RN.1–2 for m/n powers, F-IF.2–3,
far terms of sequences). In 9th grade's plan, so not repeated: A-APR.1, F-IF.6, 7b, 9, F-BF.1b, the rest of F-BF.3,
F-LE.5, and the Algebra 1 halves of A-SSE.1 and F-IF.8b. In 10th grade's plan: S-CP.1–8, the chance unit that comes
before this one. (+ marks Common Core's extras for students going on.)
**32 lessons in 9 chapters:** the 13 web lessons (`web/src/curriculum/lessons/grade11`, `specs/k12/grade11.md`), each
keeping its maths (generator, ranges, easy-first start, derived values, slips, check recipe), and 19 new ones. Small
gaps are folded into lessons as an extra problem type or step, marked *fold*.

**Review, 2 Nov 2026** (the grade 11 reviewer, checked against Appendix A's Algebra II list, the web's lesson code and
the 9th, 10th and 12th grade plans as they now stand). Every Algebra II standard has a home, but five were taught
twice with 12th grade (Taught twice, below: one copy each, the log rules' quotient and power fold handed to
`g12-logrules`). Composing functions and Evaluate a polynomial were drawn as written lines and lengths the child
couldn't count; both are now built of squares (Tiles). Inverse functions found its answer by typing before the hands
moved; the hands now find it and the record comes last. Scales that put a found number between squares were fixed
(inverse, vertex, What is i?, Complex answers, Log graphs, f(2x), e, the wave, the samples' line), pictures too wide
for the screen were refitted (the unit circle's unrolled arc, the wave, the coin line, the geometric sum's stories,
the joined log chips), and sin² + cos² = 1 now finds tan as F-TF.8 asks, its squares counted on a radius of 10.

## Coverage

| Standard | What it asks | Lesson(s) | |
|---|---|---|---|
| N-RN.1–2 | a fraction power is a root and a power | Rational exponents `g11-ratexp` (3D; ½ and ⅓ come first in 9th grade's `g9-fracexp`) | existing |
| N-CN.1 | i² = −1; every complex number is a + bi | What is i? `g11-i` | new |
| N-CN.2 | add, take away and multiply complex numbers | `g11-i`; Multiplying complex numbers `g11-complex` | new, existing |
| N-CN.7 | quadratics with complex answers | Complex answers `g11-cxroots` | new |
| N-CN.8+ | x² + 9 = (x + 3i)(x − 3i) | `g11-cxroots` *fold* | new |
| N-CN.9+ | a quadratic always has two answers | `g11-cxroots` (its last line) | new |
| A-SSE.1 | read an expression's parts in its story | The number e `g11-e` *fold* (`500e^(0.04t)`); P(1 + r)ᵗ in 9th grade's `g9-percent` | new |
| A-SSE.2 | see the structure | Difference of cubes `g11-cubes`; x⁴ − y⁴ in 9th grade's `g9-diffsq` | new |
| A-SSE.4 | the sum of a geometric sequence; use it | Sum of a geometric sequence `g11-geosum` | new |
| A-APR.1 | add, take away and multiply polynomials | 9th grade's `g9-polyadd` and `g9-foil` (its binomial-times-trinomial kind) | 9th grade |
| A-APR.2 | the remainder theorem | Synthetic division `g11-synth` + *fold*: the graph's height at the box number | existing |
| A-APR.3 | from the zeros to a rough graph | Graph from the zeros `g11-zeros` | new |
| A-APR.4 | prove an identity; use it with numbers | `g11-cubes` (3D) and its numbers kind | new |
| A-APR.5+ | (x + y)ⁿ from Pascal's triangle | Pascal's triangle `g11-pascal` (3D in its How to) | new |
| A-APR.6 | a(x)/b(x) = q(x) + r(x)/b(x) | `g11-synth` *fold* | existing |
| A-APR.7+ | add rational expressions | Rational equations `g11-rateq` *fold* (1/x + 1/2x) | new |
| A-CED.1–2 | equations from stories, and their graphs | the stories in `g11-geosum`, `g11-e`, `g11-logsolve`, `g11-rateq` and `g11-wave` (lines, parabolas and doubling are 9th grade's) | new |
| A-CED.3 | which answers make sense | `g11-radical` *fold* (a side is never negative); `g11-rateq` *fold* (a bottom can't be 0) | existing, new |
| A-CED.4 | rearrange a formula | Inverse functions `g11-inverse` *fold* (write f⁻¹(x)); 9th grade's `g9-literal` | existing |
| A-REI.2 | radical and rational equations; false answers | Radical equations `g11-radical` + *fold*; `g11-rateq` | existing, new |
| A-REI.11 | where two graphs cross solves f(x) = g(x) | Where two graphs cross `g11-crossing` (logs, roots, cubics, 1/x, between whole numbers); lines, parabolas and doubling in 9th grade | new |
| F-IF.2–3 | function notation; a sequence is a function | Evaluate a polynomial `g11-evalpoly`; `g11-seq`, `g11-geo` | existing |
| F-IF.4 | key features: zeros, turns, ends, repeats | `g11-zeros`; Vertex of a parabola `g11-vertex`; Waves `g11-wave` | new, existing |
| F-IF.5 | where a graph lives (its domain) | Log graphs `g11-loggraph` (x > 0); 9th grade's `g9-domain` | new |
| F-IF.6 | average rate of change | 9th grade's `g9-avgrate` (12th grade shrinks it to a tangent, `g12-diffq`) | 9th grade |
| F-IF.7b | root, absolute value, piecewise and step graphs | 9th grade's `g9-piecewise` | 9th grade |
| F-IF.7c | polynomial graphs: zeros and ends | `g11-zeros` | new |
| F-IF.7e | exponential, log and trig graphs | `g11-loggraph`; `g11-wave`; exponentials in 9th grade | new |
| F-IF.8 | rewrite to show the turn (a), read growth (b) | `g11-vertex`; 9th grade's `g9-complete` and `g9-percent` | existing |
| F-IF.9 | compare functions shown different ways | 9th grade's `g9-features` and `g9-overtake` | 9th grade |
| F-BF.1b | build one function from two | 9th grade's `g9-shift` (its cooling-cup kind) | 9th grade |
| F-BF.1c+ | functions in a row | Composing functions `g11-compose` | existing |
| F-BF.2, F-LE.2 | a sequence's rule | `g11-seq`, `g11-geo` (far terms); the rule both ways in 9th grade's `g9-sequence` | existing |
| F-BF.3 | slides and stretches; even and odd | 9th grade's `g9-shift`; f(kx): `g11-zeros` *fold* | new |
| F-BF.4a | solve f(x) = c; write the inverse | `g11-inverse` + *fold* | existing |
| F-BF.5+ | logs and powers undo each other | Evaluating logarithms `g11-log` (the product rule); `g11-loggraph`; the quotient, power and change-of-base rules are 12th grade's Log rules `g12-logrules` | existing, new |
| F-LE.4 | solve a·bᶜᵗ = d with a log (b is 2, 10 or e) | Exponential equations `g11-expeq`; `g11-log`; The number e `g11-e`; Solve with a log `g11-logsolve` | existing, new |
| F-LE.5 | read the numbers in a growth model | `g11-e` *fold*; 9th grade's `g9-growth` and `g9-percent` | new |
| F-TF.1 | a radian is the arc on a circle of radius 1 | Round the unit circle `g11-unitcircle` (10th grade first counts arcs in radii, `g10-arc`) | new |
| F-TF.2 | the unit circle gives sin and cos for any turn | `g11-unitcircle` | new |
| F-TF.5 | waves: middle, swing, period | Waves `g11-wave` | new |
| F-TF.8 | sin² + cos² = 1; find sin, cos or tan from one of them and the quadrant | sin² + cos² = 1 `g11-pythid` | new |
| S-ID.4 | the bell curve: mean, SD, shares | The bell curve `g11-normal` | new |
| S-IC.1, S-IC.4 | a random sample tells about the whole; margin of error | Samples and margin of error `g11-sample` | new |
| S-IC.2 | is a model believable? Run it | Is it fair? `g11-fair` | new |
| S-IC.3 | surveys, experiments, just watching; why random | Is the difference real? `g11-experiment` *fold* | new |
| S-IC.5 | compare two treatments by shuffling | `g11-experiment` | new |
| S-IC.6 | judge a report | `g11-sample` *fold*; `g11-experiment` *fold* | new |
| S-MD.6–7+ | fair choices; the better plan | `g11-fair` *fold* | new |
| S-CP.9+ | arrangements, groups, chances by counting | Line them up `g11-perm`; Combinations `g11-comb` + *fold* | new, existing |

**Grade boundaries.** 9th grade teaches ½ and ⅓ powers, sequences from term 0 with their rules both ways, percent
growth and decay, a line against doubling, average rate of change, slides and stretches (with even and odd and the
cooling cup), pieces, steps and corners, a binomial times a trinomial, x⁴ − y⁴, completing the square, the vertex
between the zeros, "no real answer", and standard deviation. 11th grade repeats none of them and starts where each one
ends: m/n powers, far terms and geometric sums, the vertex for any parabola, inverse functions and their mirror, cubes,
complex answers, logs, and crossings between whole numbers. 10th grade keeps right-triangle trig with its trig wheel to
180°, the radian as an arc counted in radii (`g10-arc`), and chance with conditions (S-CP.1–8: `g10-orand`,
`g10-given`, `g10-indep`, `g10-tree`); 11th grade takes the wheel the whole way round and keeps counting, chances by
counting and fair choices (S-CP.9, S-MD.6–7: `g11-perm`, `g11-comb`, `g11-fair`). 12th grade makes 11th grade's measured trig exact (radians with π, exact unit-circle values),
shifts waves, adds angles, undoes any function and the sine, sums forever, multiplies complex numbers as turns on the
plane, and shrinks the average rate's chord to a tangent.

**Taught twice: one copy each (review, 2 Nov).** `grade12.md`'s own review (2 Nov) read an earlier draft of this file
that sent trig, the geometric sum, Pascal's triangle and the log rules to 12th grade, so it added five lessons that
teach what this file already teaches. Common Core puts all five standards in Algebra 2, so they stay here, and the
12th grade plan should drop its copies or keep only the next step:

| Standard | Here | 12th grade's copy | What 12th grade keeps |
|---|---|---|---|
| F-TF.5 waves: middle, swing, period | Waves `g11-wave` | The sine wave `g12-sinegraph` | Shift a wave `g12-wave` (starting late, the full form) |
| F-TF.8 sin² + cos² = 1 | `g11-pythid` | `g12-pythid` | the values that aren't from a triple (`1/3` → `2√2/3`) as a fold of `g12-unit` |
| A-SSE.4 a geometric sum | `g11-geosum` | Geometric series `g12-geoseries` | Sums forever `g12-infsum`, which already starts from this lesson's halves |
| A-APR.5+ Pascal's triangle | `g11-pascal` | `g12-binomial` (3D) | nothing |
| F-BF.5+ log rules | the product rule in `g11-log` | Log rules `g12-logrules` | quotients, powers and change of base (so `g11-log` no longer folds them in) |

F-TF.1–2 are shared on purpose, not twice: here the radian and sin and cos are measured on the grid
(`g11-unitcircle`); 12th grade's web lessons (`g12-rad`, `g12-deg`, `g12-unit`) make them exact. Open question 1 asks G
which way to settle it.

## Chapters (teaching order)

| # | Chapter | Lessons |
|---|---|---|
| 1 | Sequences | Arithmetic sequences · Geometric sequences · Sum of a geometric sequence |
| 2 | Powers | Rational exponents (3D) · The number e · Exponential equations |
| 3 | Inverses and logs | Composing functions · Inverse functions · Evaluating logarithms · Log graphs · Solve with a log |
| 4 | Polynomials | Evaluate a polynomial · Vertex of a parabola · Synthetic division · Difference of cubes (3D) · Graph from the zeros |
| 5 | Complex numbers | What is i? · Multiplying complex numbers · Complex answers |
| 6 | Equations | Radical equations · Rational equations · Where two graphs cross |
| 7 | Circles and waves | Round the unit circle · Waves · sin² + cos² = 1 |
| 8 | Counting and chance | Line them up · Combinations · Pascal's triangle (3D) · Is it fair? |
| 9 | Data | The bell curve · Samples and margin of error · Is the difference real? |

The web's units keep their order (sequences, exponents and logs, polynomials, functions, complex numbers, probability).
Composing and inverse functions come just before logs, because a log undoes a power; Complex numbers come after
Polynomials, so Complex answers can stand on a parabola's turning point; Equations close the algebra, so Where two graphs
cross can use logs, roots and cubics; Circles and waves come next, taking 10th grade's trig wheel the whole way round.

## What every 11th grade lesson shares

As in 5th grade: instruction on rows 0–2 (28), a miss on rows 3–4 (20, red), the picture from row 6 with its names at
its right end, the record 3 rows under it (36, 2 squares a digit), or beside it when the picture is tall, and Check /
Next under the record. The iPad is about 68 × 45 squares; a bigger picture has the camera step back, never past what a
child can count. The first words never repeat the problem; the last line says why. Answers in the chapter colour; red
and green only for wrong and right. Steps answered by a hand move set their Core box from the move (`LessonRun.set`), so
Core's checks and slip messages stay; typing is only for the number school writes. Show me and the How to play each move
with the ghost finger and put everything back. Every new lesson's generator, answers and slips get Core tests.

- **The plane.** Across, one block (5 squares) is 1, so the strong lines are the whole numbers, a square is 0.2, and
  −5 to 5 is 50 squares, the hero's width. Up, a block is 1, 2, 5, 10, 20 or 100, the smallest that fits the problem's
  heights in about 7 blocks, numbered small on the strong lines. A picture that flips over y = x uses one scale both
  ways. Curves stroke on from left to right; a point is a dot a square across, its name half a square off it. A point
  placed on a curve snaps onto the curve at whole numbers across (the strong lines); when its height falls between
  squares (a block of 10 up), the readout gives the height and nobody is asked to count it. Anything the child counts
  or snaps to (a level line, a zero, a length) sits on squares. (8th and 9th grade's plans use a square a unit: open
  question 2.)
- **The number plane** (Complex numbers): the plane again, plain numbers along the across axis and i numbers up; a
  number is an arrow from 0.
- **Negative is striped** (7th grade's): positive pieces solid in the chapter colour, negative ones striped; a striped
  piece slid onto a solid one the same size cancels it.
- **Chips** (powers and logs): a chip is one factor, 6 × 6 squares with its number (36) in it, a square apart, so seven
  chips are 48 squares (8th grade's x chips are 4 × 4; these are bigger because a number is written in them). The
  power is the count of chips.
- **Tiles** (Composing functions, Evaluate a polynomial): one square is 1. A number is a row of squares (5th grade's
  Order of operations), × makes rows, x is a bar and x² a square on it (9th grade's algebra tiles).
- **The circle** (Circles and waves): 10th grade's trig wheel, now the whole way round: radius 25 squares (5 blocks) is
  1, so a square is 0.04, the quarter points sit on strong lines, and 3-4-5 and 7-24-25 points sit on crossings. The
  circle is 50 squares across, so the camera steps back to about 70%. (sin² + cos² = 1 draws fifths on a radius of 10,
  so the squares on its legs can be counted.) Quadrants are named as school names them, 1 to 4, as 12th grade does.
- **3D** (cube roots, cubes, the binomial cube) is Unit cubes: one cube is one block, flat first, the paper tilts as the
  maths rises, words face the child, flat again before leaving.
- **Piles** (Counting and chance, Data): one square is one person or one run, stacked over its value on a line (6th
  grade's Stack on a line). Runs and shuffles come from the problem's own seed (7th grade's trials), so a pile and its
  answer come from the same numbers, and checks accept the band the seed gives.
- **Typing:** a minus key, decimals, a fraction as a box over a box, and coefficient boxes in a written polynomial
  (`[ ]x² + [ ]x + [ ]`); powers, letters and i are written for the child.
- **Stories** are written once, as the instruction; their numbers sit on the picture as its names.

**New hand moves** (not in the kit table of `README.md` or another grade's plan; each comes with the first lesson that
uses it, after G sees its preview):

| Move | What the finger does; the live readout | Used by |
|---|---|---|
| Copy the whole | drag a block's handle on; the whole block so far is laid down again r times beside it, across or down; it snaps on whole copies; `term 4 · 3 jumps · 8 copies` | geo, geosum, ratexp |
| Multiply on | tap the `× 2` chip at a row's end; a chip joins and the running product reads; `2 × 2 × 2 = 8`; past the target it says so | expeq, log |
| Lift out (3D) | drag a marked piece off a solid; it comes away whole and fades; `125 − 8 = 117` | cubes |

Reused from the kit: cut with the ruler (e, rateq), slide pieces (geosum, expeq, compose, evalpoly, log, synth, cubes,
complex, rateq, perm), tap pieces (complex, radical, perm, comb, pascal), tap a block that opens (logsolve, crossing),
drag a point along a line (inverse, synth, logsolve, zeros), hop (rateq, unitcircle, normal), drag a rectangle's edge
or corner (seq, ratexp, radical, compose), tap the part that goes first (compose), cover the floor and build the layers
(ratexp, cubes), write. From 8th grade's plan: place a point (loggraph, vertex, zeros, cxroots, pythid), draw a graph
(zeros, pascal), sweep a line (vertex, crossing, wave, fair, experiment), slide a shape (i), flip over a line (inverse,
loggraph, cxroots, comb), turn a shape (i), raise a square on a side (pythid). From 7th grade's: flip over 0 (compose,
evalpoly, synth, complex), turn a ray (unitcircle, wave), unroll (unitcircle), drag a length (evalpoly, wave, normal,
sample), run trials (fair, sample, experiment), choose, slide the sheet (3D; cubes, pascal). From 6th grade's: stack on
a line (fair, normal, sample, experiment).

## 1. Sequences (term posts)

A row of small ticks on a strong line, one for each term, numbered under them (small). A jump is a gap between posts,
never a post: term 1 is where you start.

### Arithmetic sequences (`g11-seq`, existing; F-BF.2, F-LE.2, F-IF.3)
**One square:** 1, drawn as a 2 × 2 cell, so the biggest climb (29 jumps of 9) is 58 × 18 squares. **Picture:** term
posts 2 squares apart along a strong line, post 1 at the left; over posts 1–4 the first four terms (`5 9 13 17`, small)
and over post n a ringed `?`; its name at the right end, `term 20`. Under the posts, the climb's empty frame, its right
edge a handle at post 1.
1. **Write** `d = 9 − 5 = [4]` (the web's step and slips: "That's the first term. d is the jump: 9 − 5." / "That's the
   second term. Subtract: 9 − 5."). The frame takes the height of 4.
2. **Drag the edge** (Multiply two-digit numbers' rectangle edge) from post 1 toward post 20: under each gap it passes a
   column of 4 fills; readout `term 8 · 7 jumps`. Release on post 20. Past it: "That's term 21. Stop at term 20." The
   release sets the jumps box (19): the off-by-one is seen every time, because post 1 has no column in front of it.
3. See: the climb counts in rows (`19, 38, 57, 76`). **Write** `19 × 4 = [76]` (slip: "Each of the 19 jumps climbs 4:
   multiply.").
4. **Write** `a₂₀ = 5 + 76 = [81]` (slip: "The climb starts at the first term, so add the first term."); 81 is written
   over post 20 in the chapter colour.
Say: "Term 1 is the start, so term 20 is 19 jumps of 4 on from 5."
**Core:** the web's generator as it is (a1 1–20, d 2–9, n 10–30; first three problems the smallest of six draws; skill
check as the spec, a1 ≠ d). Boundary: 9th grade's sequences start at term 0 and stay small, and write the rule both
ways (`g9-sequence`); this lesson reaches far terms.

### Geometric sequences (`g11-geo`, existing; F-BF.2, F-LE.2)
`LESSONS.md`'s own 11th grade idea: the squares multiply each beat and the camera steps back.
**One square:** 1. **Picture:** term posts as above, 6 squares apart; under post 1, term 1 as a row of a squares in the
chapter colour; the first four terms over posts 1–4 and `?` over post n; name `term 6`.
1. **Write** `r = 6 ÷ 3 = [2]` (slip: "Geometric sequences multiply. Divide to find the ratio.").
2. **Copy the whole** (new move) from post to post: drag the handle on to the next post and the whole block is laid
   down again r times, across or down, whichever keeps it nearer the screen's shape. Readout `term 4 · 3 jumps · 8
   copies`. Every copy of term 1 keeps a faint outline, so copies still count when the squares get small; the camera
   steps back at most 2× a jump and never past 40% (a = 5, r = 3, n = 8 is 135 × 81 squares). Past post n: "That's term
   7. Stop at term 6." The release sets the jumps box (5).
3. **Write** `2⁵ = [32]` (slip: "2⁵ means 2 times itself 5 times, not 2 × 5.").
4. **Write** `a₆ = 3 × 32 = [96]` (slip: "The first term grows by the whole factor: multiply.").
Say: "Each jump copies everything, so 5 jumps make 2⁵ = 32 copies of 3."
**Core:** as the web (a 1–5, r 2 or 3, n 5–8; smallest-of-six start; skill check as the spec, a ≥ 2). Core lays out the
copies (across and down per jump) and tests that the biggest stays inside 140 × 90 squares.

### Sum of a geometric sequence (`g11-geosum`, new; A-SSE.4)
**One square:** 1. **Picture:** the terms as bars 2 squares tall, a square apart, one under another, left ends on a
strong line, each as long as its term and named at its right end (`3`, `6`, `12`, `24`); a bracket down their right
side named `S`. The longest bar drawn is 60 squares.
1. **Copy the whole** stack once: under it a second stack draws dashed, each bar twice as long (`× 2`); readout `2S`.
2. **Slide** the dashed stack up; it snaps a bar at a time; when each copied bar lies on the bar of its own length,
   green dots light at their ends; readout `3 match`. Wrong place: "Line up equal bars: 3 doubled is 6."
3. **Slide over to take away** (Subtracting fractions' move): every matched pair crosses out. Left are the copy's last
   bar, 48, sticking out below, and the first bar, 3, with nothing on it.
4. **Write** `2S − S = 48 − 3`, `S = [45]`. For r = 3: `3S − S = 54 − 2`, `2S = [52]`, `S = [26]`. Then the rule as
   record: `S = a(rⁿ − 1) ÷ (r − 1)`.
Say: "The copy is the same bars moved down one, so everything cancels except the two ends."
From problem 7, stories (A-SSE.4's "use the formula"): rice on a chessboard's first 10 squares, savings that double each
week. Their last bars (512 grains) can't be drawn true size, so here each term is the same 6 × 2 box with its number in
it, the middle ones folded into one box named `…`; the copy, slid down one box, still lines up name by name, and the
two ends left over are the record: `2S − S = 1024 − 1`, `S = [1023]`. From problem
10, halves: 5th grade's whole bar, 48 squares, with pieces of 24, 12, 6 and 3 laid in it, leaving one 3-square gap:
`½ + ¼ + ⅛ + 1/16 = 1 − 1/16 = [15]/16`.
**Core:** new. a 1–4, r 2 or 3, n 3–5, while the copy's last bar (a · rⁿ) is at most 60; first three r = 2, a 1–3,
n = 4. Stories from problem 7 (a 1–5, n 6–10); halves from problem 10 (n 3–5). Slips: a bar left out ("Count the bars:
4 terms."), rⁿ⁻¹ for rⁿ ("The copy's last bar is one more × 2: 48."), ÷ (r − 1) forgotten ("3S − S is 2S: halve
it."). Boundary: 12th grade keeps arithmetic series (`g12-series`) and sums that go on forever (`g12-infsum`, which
starts from this lesson's halves).

## 2. Powers

### Rational exponents (`g11-ratexp`, existing; N-RN.1, N-RN.2) — 3D
**One square:** 1; one cube is one block (Unit cubes). **Picture:** flat, the power named at the right end in maths 36
(`8^⅔`, the fraction small and high); a square's empty corner from row 6, its handle on the far corner. A square base is
up to 9 blocks (45 squares); the camera steps back for the biggest cubes.
1. Find the root by building the base, as 9th grade's Fraction powers does (`g9-fracexp`, after 8th grade's Square and
   cube roots). Bottom 2: **drag the corner** (it stays a square): readout `3 × 3 = 9`; release on 9 and its side lights,
   `3`. Bottom 3 (**3D**): drag the floor's corner, then the paper tilts and **build the layers** (it stays a cube):
   `2 × 2 × 2 = 8`; its edge lights, `2`. Wrong: "That's 27: too many. It needs 8." Sets the web's root box (its slip,
   8 ÷ 3, "A power of 1/3 is a root, not dividing by 3.", stays with it).
2. Build the top from one edge, an edge at a time: **drag** it out to a rod (× 1), a face (× 2), a cube (× 3), and for 4
   the cube laid down again (Copy the whole); readout `2 × 2 = 4`. Wrong: "The top is 2: two edges multiplied, a face."
3. **Write** `8^⅔ = (∛8)² = 2² = [4]` (the web's slip, root × top, as it reads for `9^(3/2)`: "The top is a power: 3
   times itself, not 3 × 3."). The paper lies flat.
Say: "The bottom 3 makes 8 a cube with edge 2; the top 2 multiplies two edges, a face of 4."
**Core:** as the web (bottom 2 or 3; r 2–9 for squares, 2–5 for cubes; top 1–3, moved up one when it equals the
bottom; smallest-of-six start; skill check as the spec). 3D for every cube root and for a top of 3 or 4. Boundary:
9th grade does ½ and ⅓; this lesson does m/n.

### The number e (`g11-e`, new; F-LE.4, A-SSE.1, F-LE.5)
**One square:** on the bars, 5 cents ($1 is 20 squares); on the line, 1 cent (a block is 5 cents), so every value the
point stops on, to the cent, is a square. **Picture:** the story is the instruction ("$1 in a bank that pays 100% a
year."). The year as a ruler bar along the top (20 squares); under it the money bar, $1; under that a line from $2.00
to $2.75 (75 squares; the camera steps back to about 85%), e's tick at 2.718 the only mark between squares.
1. **Cut** the year with the ruler into 1 or 2 parts: readout `twice a year: 50% each time`.
2. **Tap** each part in turn: the money bar grows by its share of itself (20 → 30 → 45 squares: `$1.50`, `$2.25`); a
   point drops onto the line at the end.
3. **Drag** the ruler's count on (3, 4, 6, 12, 52, 365): the pieces grow too fine to tap, so only the point moves,
   creeping along the line a square (a cent) at a time, `12 times: $2.61`, `365 times: $2.71`, toward a dashed tick
   named `e = 2.718…` that it never passes.
4. **Write** the count asked for, `(1 + 1/4)⁴ ≈ [2.44]`, counted on the line: 44 squares past $2.
Say: "Growing more often adds a little more each time, but never past 2.718…: that's e."
*Fold (A-SSE.1, F-LE.5), from problem 4:* growing all the time, `A = 500e^(0.04t)`: **choose** which number is the start
and which the rate a year (4%), then **write** `500 × e^0.4 ≈ [746]` after 10 years (the readout gives e^0.4 ≈ 1.49:
F-LE.4's "use technology").
**Core:** new. Counts 1, 2, 4 and 12 for the record; growing all the time from problem 4 (P 100–1000, r 2–10%, t 1–20,
answers to the dollar); first three counts 1, 2 and 4. Slips: 1 + n · (1/n) = 2 ("That's 2: the growth never grew.
Here each part grows on the last."); (1 + 1)ⁿ ("Each time it grows by 1/4, not by all of it."). Boundary: 9th grade grows by
a percent a year (`g9-percent`); this lesson grows more and more often.

### Exponential equations (`g11-expeq`, existing; A-CED.1, F-LE.4)
**One square:** a chip (6 × 6 squares). **Picture:** the equation as its name, `2^(x + 1) = 16`; under it the value `16`
as one wide tile, and an empty chip row.
1. **Multiply on** (new move): tap the `× 2` chip at the row's end; a 2 chip joins and the running product reads,
   `2 × 2 × 2 = 8`; stop on 16: four chips, numbered 1–4 over them, and the tile `16` fades into them. Past it: "2⁵ is
   32: past 16." Sets the web's base box (4) (its slip, 16 ÷ 2, "Count how many 2's multiply together to make 16.",
   stays with it).
2. A bracket `x + 1` spans the four chips (See). **Slide** one chip out from under it (for a minus, ghost chips join
   instead): what's left under the bracket is x; readout `x = 3`.
3. **Write** `x + 1 = 4`, `x = [3]` (slip: "x + 1 = 4 means x is 1 less than 4: subtract 1.").
Say: "Both sides are 2 to a power, so the powers match: x + 1 = 4."
**Core:** as the web (base 2, 3 or 5; k 2–7 for base 2, 2–4 otherwise; c −5..5, not 0; smallest-of-six start; skill
check as the spec). When x is below 0 (c > k), the extra chips go past the start struck through, as the web draws it.
Boundary: 9th grade solves the plain 2ˣ = 1/16.

## 3. Inverses and logs

### Composing functions (`g11-compose`, existing; F-BF.1c+)
**One square:** 1 (Tiles): a number is a row of squares, solid when positive, striped when negative (7th grade's); × makes
rows. **Picture:** the web's nesting, built of squares: f's frame round g's frame round the input, 3, a row of 3 squares;
each frame's name on its tag (`f`, `g`); the rules written once at the right end (`g(x) = 2x`, `f(x) = x + 1`). The
biggest problem is f's last build, 5 rows of 29 and 9 more squares: about 40 × 7 squares, so every problem is drawn at
full size and counted.
1. **Tap the part that goes first** (Order of operations' move): g's frame. Wrong: "f is on the outside: g works on 3
   first." (The web's "Wrong order", caught before any sum.)
2. g opens. **Drag the corner** (Multiply two-digit numbers' rectangle) down a row at a time to c rows of the input:
   readout `2 rows of 3 = 6`. A negative c **flips** the rows **over 0** (7th grade's) as they're laid, solid ↔ striped:
   `−2 rows of 3 = −6`. Wrong count: "g(x) = 2x: 2 rows of 3." Then **slide** d's squares on; a striped square on a solid
   one cancels both: `6 + (−4) = 2`.
3. **Write** `g(3) = [6]` (the web's slip: "Keep the sign of (−4): 6 + (−4)."). The squares close up into one row, 6
   long, and g's frame folds away round it.
4. **Slide** that row into f's slot: it is f's input now. **Drag the corner** to a rows of it and slide b's squares on:
   `1 row of 6 + 1 = 7`. **Write** `f(6) = [7]` (slip: "f(g(x)) means g first, then f.").
Say: "g is inside, so it works first; f works on what g gives back."
**Core:** as the web (a and c −5..5, b and d −9..9, k −4..4, none 0; smallest-of-six start; skill check as the spec).
The rows and slides are hand steps with no box; the two boxes are the web's. Tests: the biggest build (a = ±5, g = ±29)
stays inside 45 squares across.

### Inverse functions (`g11-inverse`, existing; F-BF.4a, A-CED.4 fold)
**One square:** 1, the same both ways (the picture flips over y = x), so every point the child finds sits on a crossing
(a block of 2 or 10 would put odd numbers between squares). **Picture:** the plane from just past 0 to just past the
bigger of x and y each way, f's line drawn and named `f(x) = 3x + 2`, the line y = x dashed; the output `14` marked on
the y-axis with a dashed level line from it, named `f⁻¹(14)`. The first three problems (the smallest draws) fit at
100%; the biggest (f(9) = 54) is about 60 squares each way and the camera steps back to about 65%.
1. **Drag a point** along f's line; it snaps at whole numbers across: readout `f(3) = 11`, `f(4) = 14`. Release where
   it meets the level line; it rings green at `(4, 14)`. Released short or past: "f(3) = 11: not 14 yet."
2. **Flip over a line** (8th grade's) across y = x: `(4, 14)` lands on `(14, 4)`, 14 across and 4 up; then the whole
   line flips over and draws as `f⁻¹` (See).
3. **Write** f's steps backwards, the school way (the web's two steps): `14 − 2 = [12]` (slip: "Undo + with −."),
   `12 ÷ 3 = [4]` (slip: "f multiplied by 3; the inverse divides by 3."). Record: `f⁻¹(14) = 4`.
Say: "f takes 4 to 14, so f⁻¹ takes 14 back to 4: its graph is f's, flipped over y = x."
*Fold (F-BF.4a, A-CED.4):* from problem 7, write the inverse itself, `f⁻¹(x) = (x − [2]) ÷ [3]`; from problem 10,
`f(x) = 2x³`, `f⁻¹(16) = ∛(16 ÷ 2) = [2]`.
**Core:** as the web (a ∈ {2, 3, 4, 5, −2, −3}, b −9..9 not 0, x −6..9, never y = x; smallest-of-six start; skill
check as the spec, x ≠ 0). Boundary: 9th grade solves y = 2x + 3 for x (`g9-literal`); 12th grade folds the paper,
restricts and checks by composing (`g12-undo`).

### Evaluating logarithms (`g11-log`, existing; F-LE.4, F-BF.5+)
**One square:** a chip, as in Exponential equations. **Picture:** the sum as its name, `log₂ 8 + log₂ 4`; under it two
empty chip rows, the values `8` and `4` as tiles at their ends.
1. **Multiply on** 2 chips in the first row until the product reads 8: `2 × 2 × 2 = 8`, three chips. Past it: "2⁴ is 16:
   past 8." Sets the first log (3) (the web's slip, 8 ÷ 2, "A log asks for the exponent, not a quotient.", stays with
   it).
2. The same for 4: two chips. Sets the second (2).
3. **Slide** the second row onto the end of the first (8th grade's Exponent rules move): five chips, readout
   `2⁵ = 32 = 8 × 4`.
4. **Write** `3 + 2 = [5]`, and under it the web's note, `= log₂ (8 × 4)`.
Say: "A log counts the 2s: three 2s and two 2s make five, and 8 × 4 = 2⁵."
Slips added to the web's: logs multiplied ("Chips join end to end: 3 + 2, not 3 × 2."); the log of a sum ("log₂ (8 + 4)
isn't 5: rows join only when the numbers multiply.").
**Core:** as the web (bases 2, 3, 5, 10; powers up to 6, 4, 3, 3; two different logs; smallest-of-six start; skill check
as the spec, one item per base). A joined row of more than 7 chips (base 2 only: up to 6 + 5 = 11, 76 squares) wraps
onto a second line under it, as words do, and the count runs on, so the picture stays inside 48 squares. Boundary: 12th
grade's Log rules (`g12-logrules`) takes quotients, powers and change of base on from this product rule (they were a
fold here in the first draft; one copy only).

### Log graphs (`g11-loggraph`, new; F-IF.7e, F-BF.5+, F-IF.5)
**One square:** a block is 1 both ways (it flips over y = x), so every dotted point is on a crossing. **Picture:** the
plane, −2 to 8 both ways (50 squares; the camera steps back to about 85%); `y = 2ˣ` drawn through `(0, 1)`, `(1, 2)`,
`(2, 4)` and `(3, 8)`, those points dotted (`(−1, ½)` is on the curve but not dotted: a half is between squares);
y = x dashed.
1. **Flip over a line** (8th grade's, as Inverse functions does) each point across y = x: `(3, 8)` lands on `(8, 3)`;
   readout `log₂ 8 = 3`. Three by hand; the last flips in.
2. The log curve draws through them (See). **Place a point** where it crosses the x-axis: `(1, 0)`. Wrong: "(0, 1) is on
   2ˣ. Its flip is (1, 0)."
3. **Choose** at the far left: `it crosses the y-axis` / `it never reaches it`. Wrong: "2 to any power is more than 0, so
   there's no log of 0 or less."
4. **Write** what the flipped points say: `log₂ 4 = [2]`, `log₂ 1 = [0]`, and `x > [0]` (F-IF.5).
Say: "The log graph is 2ˣ flipped over y = x: it climbs slower and slower and never reaches x = 0."
From problem 7, base 3 (points to `(2, 9)`, the plane −2 to 9); from problem 9, moved logs, `y = log₂(x − 1) + 2`,
slid as 9th grade's Slide and stretch a graph slides (the plane runs to 10 across, 60 squares, about 75%); the record
asks its new edge, `x > [1]`, and a slid point, `(5, [4])`.
**Core:** new. Bases 2 and 3 (10 is too steep to flip on one screen); the asked values are flipped points, so they stay
on the plane (to 8 for 2, to 9 for 3); moved logs with h −2..1 and k −2..2 from problem 9, so the moved points stay on
the plane; first three base 2. Slips: x and y swapped in a flip; log 1 = 1 ("2⁰ = 1, so log₂ 1 = 0."). Boundary: 12th
grade's Undo a function folds 2ˣ again, with restricting.

### Solve with a log (`g11-logsolve`, new; F-LE.4, A-CED.1)
**One square:** on line 1 a block is a whole power; on line 2 a block is a tenth. **Picture:** 8th grade's Squeeze a
square root, for powers: line 1 from 0 to 6 (30 squares), over each strong line the power of 2 it makes (`1 2 4 8 16 32
64`, small); the equation as its name at the right end, `3 · 2ᵗ = 30`.
1. **Write** `2ᵗ = 30 ÷ 3 = [10]` (slip: "Divide first: 2ᵗ is on its own only after ÷ 3.").
2. **Tap the block** t is in: while the finger is down, the block's two ends light (`2³ = 8`, `2⁴ = 16`). Wrong: "2⁴ is
   16: more than 10. Go back." Right: the block opens below (dashed) into line 2, ten tenths from 3 to 4.
3. **Drag the point** along line 2; the readout powers its tick (`2^3.3 = 9.85`, `2^3.4 = 10.56`); release on the last
   tick under 10. Wrong: "2^3.4 is 10.56: past 10." The tenth it's in lights: `3.3 < t < 3.4`.
4. **Write** the answer as a log, `t = log₂ [10]` (F-LE.4); the app works it out as a calculator would, `≈ 3.32`, and
   the value drops onto line 2 inside the lit tenth (green). The record ends `t ≈ 3.3`.
Say: "2³ is 8 and 2⁴ is 16, so the power that makes 10 is a bit past 3: 3.3."
From problem 4, stories ("3 cells double every hour. When are there 30?"); from problem 7, base 10 (`10ᵗ = 50`, `log 50
≈ 1.7`); from problem 9, base e (`eᵗ = 5`, `ln 5 ≈ 1.6`, line 1 marked `1 2.7 7.4 20 55`); from problem 10,
`2^(3t) = 10`: `3t = log₂ 10 ≈ 3.32`, `t ≈ [1.11]` (typed: school divides by 3 here).
**Core:** new. a 1–5; b 2, 10 or e; d ÷ a never an exact power (those are `g11-expeq`'s), between b and b⁵; the squeeze
to tenths, the log's value from Core to hundredths, so the tenth the child finds always holds it; first three b = 2,
a = 1. Slips: the whole right side logged ("log₂ 30 forgets the 3: divide first."); the value for the power ("10 is
what 2ᵗ makes; t is the power."); the power typed in the log ("The log asks: 2 to what makes 10? Write 10.").

## 4. Polynomials (the plane)

### Evaluate a polynomial (`g11-evalpoly`, existing; F-IF.2)
**One square:** 1 (Tiles): x is a bar, x² a square on it, 1 a single square; each tile solid when its part is
positive, striped when negative. A first draft stacked the parts as lengths on a plane a block of 2 to 20 up, where most
heights fell between squares; tiles keep every part countable. **Picture:** the name `f(x) = 2x² − 3x + 1` and, under
it, its tiles in three rows: a x² squares, |b| x bars, |c| ones, the x bars' length still dashed, a handle on the first
one's end. Beside them, a small plane with the curve (a block is 1 across, 10 or 20 up), the place the answer lands.
The biggest (x = ±4: four 4 × 4 squares, nine bars 4 long, nine ones) is about 45 × 16 squares.
1. **Drag a length** (7th grade's): pull the x bar's end to the input; it snaps a square at a time and turns striped left
   of 0; readout `x = −2`. Every tile built on x follows: the x² squares become 2 × 2, the bars 2 long. Wrong: "That's
   x = 2. f(−2) is left of 0."
2. **Flip over 0** (7th grade's) the x² tiles: a negative side times a negative side, they turn over and land solid;
   readout `(−2)² = 4`. **Write** `2 · (−2)² = [8]`, counted: two squares of 4 (the web's slips, "A negative squared is
   positive." and "Squared means times itself."; at x = −2 they're the same wrong number, and the first is shown).
3. The −3 bars are striped and so is x: **flip** them too (with only one of them negative they stay striped); readout
   `−3 × −2 = 6`, six squares solid. **Write**
   `−3 · (−2) = [6]` (slip: "Negative times negative is positive.").
4. **Slide** any striped tiles onto solid ones; each pair cancels (7th grade's). The readout counts what's left, and on
   the plane a dashed line rises at x = −2 to the point `(−2, 15)` on the curve. **Write** `f(−2) = 8 + 6 + 1 = [15]`
   (slip: "Keep each part's sign: 8 + 6 + 1.").
Say: "f(−2) is how high the graph is at x = −2: 8, then 6 more, then 1."
**Core:** as the web (a and k −4..4, b −9..9, none 0, c −9..9; smallest-of-six start; skill check as the spec, k ≤ −2
or k ≥ 3). The drag and flips are hand steps; the square, x-term and total boxes are the web's three, typed.

### Vertex of a parabola (`g11-vertex`, existing; F-IF.8a, F-IF.4)
**One square:** across, a block is 1 always: the plane runs from just left of the y-axis to just past the twin (2h is at
most 10 away), so it is at most 12 blocks, 60 squares; a block of 2 would put odd x between squares. Up as the curve
needs (the turn can be 75 below c), the points snapping onto the curve at whole x. **Picture:** the plane, the parabola
drawn and named at its right end, `y = x² − 6x + 5`.
1. **Place a point** where the curve meets the y-axis: readout `(0, 5)`.
2. **Place** its twin, the other point at the same height (a dashed level line from the first guides the finger):
   readout `(6, 5)`. Wrong: "(5, 0) is lower. Find height 5 again." The twin of (0, c) is always at −b ÷ a, which is
   where the formula's −b ÷ 2a comes from.
3. **Sweep a line** (8th grade's; here an up-and-down mirror line) to halfway; it snaps at each whole number; readout
   `x = 3`; halfway, the curve's two halves fold onto each other with green dots. Wrong: "x = 2 is 2 from 0 but 4 from 6."
4. **Write** `x = −(−6) ÷ (2 · 1) = [3]` (the web's step; slip: "The formula starts with −b."), then
   `y = 3² − 6 · 3 + 5 = [−4]` (slips: "Keep the number on its own: add c too." / "A negative squared is positive.").
Record: the turning point `([3], [−4])`; from problem 7, **choose** `lowest` / `highest` (a < 0 opens down).
Say: "The parabola is the same on both sides of x = 3, so it turns there."
**Core:** as the web (a ∈ {1, 2, −1, −2, 3}, h −5..5 not 0, c −9..9, b = −2ah; smallest-of-six start; skill check as
the spec, c ≠ 0). The twin is (2h, c); the two places and the sweep are hand steps with no box. Boundary: 9th grade
finds the turn halfway between the zeros and by completing the square; this one needs no zeros.

### Synthetic division (`g11-synth`, existing; A-APR.2, A-APR.6)
**One square:** a cell is 6 × 4 squares, numbers 36. **Picture:** on the left the table: the box, then the top row
`1 −5 6` under small `x² x 1`, a rule under the middle row; the problem as its name above it, `(x² − 5x + 6) ÷ (x − 2)`.
On the right, the plane (a block is 1 across) with the curve `y = x² − 5x + 6`.
1. **Flip over 0** (7th grade's move): drag the −2 out of `(x − 2)` into the box; it turns over on the way and lands as
   `2`; readout `x − 2 is 0 when x = 2`.
2. **Slide** the 1 down under the rule.
3. Column by column: **drag** the bottom number up into the next column (an arrow `× 2` follows the finger) and
   **write** what lands there, `1 × 2 = [2]` (slip: "x − 2 is 0 when x = 2, so the box holds 2."); **slide** down the
   column and **write** the sum, `−5 + 2 = [−3]` (slip: "Add down each column. The flipped sign in the box already does
   the subtracting."). Then `−3 × 2 = [−6]` and `6 + (−6) = [0]`.
4. **Write** the answer from the bottom row, `x + [−3]`, shown as `x − 3`. With a remainder, `x + [q], remainder [e]`
   (slips: "Subtracted the column" as above; "The middle number goes after x +, and the last number is the
   remainder."), and then, *fold* (A-APR.6), `= x − 3 + 4/(x − 2)`.
5. *Fold (A-APR.2):* **drag a point** along the plane's x-axis to the box number: a dashed line rises to the curve,
   readout `p(2) = 0`, and the table's last number lights with it.
Say: "0 left over, and the graph crosses at 2: x − 2 is a factor." (With a remainder: "4 left over: at x = 2 the graph
is 4 above the axis.")
From problem 7, half the problems ask "Is x + 3 a factor?" and end with **choose** `factor` / `not a factor`.
**Core:** as the web (r and s −6..6, not 0, different, the first three within 3; every third problem a remainder −5..5;
skill check as the spec). The flip sets the box; the drag answers the web's check step, p(r).

### Difference of cubes (`g11-cubes`, new; A-SSE.2, A-APR.4) — 3D
**One square:** one cube is one block (Unit cubes). **Picture:** flat at first, the big cube's floor (a × a blocks),
its 2 × 2 corner marked, named `5³ − 2³` at its right end.
1. **Cover the floor, build the layers** (Volume of a box's move): the paper tilts and the cube rises; readout
   `5 × 5 × 5 = 125`.
2. **Lift out** (new move, 3D) the marked corner cube: it comes away whole and fades; readout `125 − 8 = 117`.
3. **Slide the sheet** (7th grade's, 3D) in along the hole's faces; it snaps on them, and the rest comes apart into three
   boxes, each naming its sizes: `3 × 5 × 5`, `3 × 5 × 2`, `3 × 2 × 2`. Wrong: "Cut along the hole's faces."
4. **Slide** the three boxes into one row, each lying on its 3-thick side: one long box, readout `3 × (25 + 10 + 4) =
   117`.
5. **Write** `5³ − 2³ = (5 − 2)(5² + 5 · 2 + 2²) = 3 × [39] = [117]`. The paper lies flat.
From problem 4 the big edge is x (a rod marked x, its length not counted): `x³ − 8 = (x − [2])(x² + [2]x + [4])`.
*Numbers (A-APR.4), from problem 9:* `10³ − 9³` without cubing: the slab is 1 thick, so
`(10 − 9)(100 + 90 + 81) = [271]`; say "Cubes next door differ by the three boxes' faces: 100 + 90 + 81."
Say: "Take a small cube out of a big one, and what's left is three boxes, all a − b thick."
**Core:** new. a 3–6, b 1 to a − 1; first three a − b = 2; x³ − b³ (b 1–5) from problem 4; next-door cubes (a 6–12,
b = a − 1) from problem 9. Slips: `(a − b)³` ("That's 3³ = 27. What's left holds 117."), a box left out ("Three boxes:
25, 10 and 4."), `− 2x` for `+ 2x` ("All three boxes add: x² + 2x + 4."). Sums of cubes are left out (Common Core
doesn't ask for them). Boundary: 9th grade factors trinomials and differences of squares, x⁴ − y⁴ too (`g9-diffsq`).

### Graph from the zeros (`g11-zeros`, new; A-APR.3, F-IF.7c, F-IF.4, F-BF.3 fold)
**One square:** across, a block is 1; up, a block is 2, 5 or 10, so the bumps between the zeros fit. **Picture:** the
empty plane, x −5 to 5 (50 squares), the polynomial as its name over it: `y = (x + 2)(x − 1)(x − 3)`.
1. **Place a point** on the x-axis for each bracket (tap a crossing; it snaps to whole numbers): readout `x − 1 is 0 at
   1`. Wrong: "x + 2 is 0 at −2: −2 + 2 = 0."
2. **Choose** the far right, `up` or `down` (two blocks at the plane's right edge). Wrong: "Far right every bracket is
   positive: up." (With a minus in front: "Far right it's −x³: down.")
3. **Draw a graph** (8th grade's pen) from the far right leftward; it snaps through each zero; readout `above` / `below`.
   Wrong at a simple zero: "x − 3 changes sign at 3: the graph crosses there." At a double zero, `(x − 1)²`: "(x − 1)² is
   never negative: it touches and turns back."
4. **Write** where it meets the y-axis: `(0 + 2)(0 − 1)(0 − 3) = [6]`; the pen's path must pass (0, 6).
Say: "Each zero flips the sign, so the graph crosses there; far right it's up, because x³ wins."
*Fold (F-BF.3's f(kx)), from problem 10:* `y = p(2x)` where p's zeros are even (−2, 2, 4): **drag** each zero along the
axis (Drag a point along a line) to where 2x makes its bracket 0, halfway to 0; readout `4 → 2`; the whole graph
squeezes toward the y-axis. Say: "Doubling x gets to each zero in half the distance." (9th grade's `g9-shift` has the
other slides and stretches.)
**Core:** new. 2–3 brackets (x − p), p −4..4, different; first three: three brackets, leading +1, zeros in −3..3; a
leading −1 from problem 4; a double zero from problem 7; four brackets from problem 9; f(2x) from problem 10, its zeros
from −4, −2, 2, 4 so the halves land on whole numbers (an odd one would land between squares). The pen
is right when it passes every zero, sits above or below rightly in each gap (checked at the gap's middle) and passes
(0, f(0)). Slips: a zero's sign; crossing at a double zero; the far left ("Three brackets: the two ends go opposite
ways.").

## 5. Complex numbers (the number plane)

### What is i? (`g11-i`, new; N-CN.1, N-CN.2)
**One square:** a block is 1; when a sum passes 6, 2 squares are 1 (−12 to 12 is 48 squares), so every arrow still ends
on a crossing. **Picture:** the number plane, an arrow from 0 to 3, named `3`.
1. **Turn a shape** (8th grade's) round 0; it snaps every quarter turn. A half turn: readout `× −1: −3`.
2. From 3 again, a quarter turn: it points straight up, readout `× i: 3i`. One more quarter turn lands on −3. **Write**
   `i × i = [−1]`, then `(3i)² = 9 × i × i = [−9]`, so `√−9 = [3]i`. Wrong: "Two quarter turns face the other way:
   that's × −1."
3. *Adding* (from problem 4): arrows `2 + 3i` and `4 − i`; **slide the shape** (the second arrow) so it starts where
   the first ends: readout `6 + 2i`. **Write** `(2 + 3i) + (4 − i) = [6] + [2]i`. Wrong: "Across adds to across and up
   to up: 2 + 4 and 3 − 1."
4. *Taking away* (from problem 7): the second arrow turns a half turn first (× −1), then slides on.
From problem 10, powers of i: `i⁷` is seven quarter turns, `−i`.
Say: "Two quarter turns make a half turn, so i × i is −1."
**Core:** new. Turns i², i³, i⁴, then iⁿ (n 5–12) from problem 10; √ of −1 to −100 (perfect squares); adding and taking
away with parts −6..6, not 0; first three positive parts. Slips: across added to up; `i² = 1`; `√−9 = −3` ("−3 × −3 is
+9. The root of −9 is 3i."). Boundary: 12th grade builds on these quarter turns to multiply by turning and stretching
(`g12-cmult`) and gives a number its length and angle (`g12-cpolar`).

### Multiplying complex numbers (`g11-complex`, existing; N-CN.2)
**One square:** 1, drawn 3 × 3 squares (2 × 2 when a side passes 10). **Picture:** the web's area grid in real squares,
|a| + |b| tall by |c| + |d| wide, cut into four cells: `2` and `3i` down the left, `1` and `4i` along the top; the cells
named `2`, `8i`, `3i`, `12i²`; a negative part's cells striped. Name over it: `(2 + 3i)(1 + 4i)`.
1. **Tap** the plain cell: its squares count; **write** `2 · 1 = [2]` (slip: "Multiply the two real parts.").
2. **Flip over 0** (7th grade's) the corner: drag it toward the plain cell; it turns over like a card on the way and
   lands named `−12` (solid ↔ striped: i × i is a half turn, as in What is i?); readout `3i · 4i = 12i² = −12`. **Write**
   `[−12]` (slip: "i × i = −1, so the sign flips.").
3. **Slide** it onto the plain cell: `2 + (−12)`, striped squares cancelling solid ones; **write** `[−10]` (slip: "i²
   is −1, so the corner is the opposite sign.").
4. **Slide** the two i cells together: `8i + 3i`; **write** `[11]` (slip: "Outer and inner are both i terms side by
   side: add them.").
Record: `(2 + 3i)(1 + 4i) = [−10] + [11]i`.
Say: "i times i is −1, so the corner turns over and joins the plain numbers."
**Core:** as the web (each part −6..6, not 0; smallest-of-six start; skill check as the spec, never a = c = 2).

### Complex answers (`g11-cxroots`, new; N-CN.7, N-CN.8+, N-CN.9+)
**One square:** across, a block is 1; up, a block is 1 when the turn is 1 or 4 above the axis, and a square is 1 when it
is 9 or 16 (so the turn, and the copy's top, sit on squares; the plane is then about 30 rows tall). **Picture:** the
plane with the parabola, named at its right end as the equation, `x² − 4x + 13 = 0`; it never touches the x-axis.
1. **Place a point** on its lowest point: readout `(2, 9)`. That's the trouble: at best it is 9 above the axis.
2. **Flip over a line** (8th grade's) across the level line through that point: the upside-down copy crosses the axis 3
   either side of 2; readout `3 each side`. (The copy is (x − 2)² = 9; ours is (x − 2)² = −9, so the 3 becomes 3i, as
   √−9 did in What is i?.)
3. **Write** the formula way: `16 − 52 = [−36]`, `√−36 = [6]i`, `x = (4 ± 6i) ÷ 2 = 2 ± [3]i`; the two answers are
   written by the copy's crossings, `2 + 3i` and `2 − 3i`.
Say: "It never reaches 0, so its two answers are off the line: 2 + 3i and 2 − 3i."
*Fold (N-CN.8), from problem 7:* `x² + 9 = (x + [3]i)(x − [3]i)`, checked in Multiplying complex numbers' grid: the i
cells cancel and the corner flips to + 9. *Fold (N-CN.9), from problem 9,* the last line: "Every quadratic has two
answers, on the line or off it."
**Core:** new. (x − h)² + m² with h −3..3 and m 1–4 (b = −2h, c = h² + m²); first three h = 0 (`x² + 4 = 0`); h ≠ 0
from problem 4. Slips: "√−36 is 6i, not −6."; one answer ("± gives two."); one part halved ("Halve both parts: 4 ÷ 2
and 6i ÷ 2."). Boundary: 9th grade's formula (`g9-quadform`) has real answers and says "no real answer"; 11th grade
starts there.

## 6. Equations

### Radical equations (`g11-radical`, existing; A-REI.2, A-CED.3 fold)
**One square:** 1, drawn 4 × 4 squares (a side of 9 is 36 squares). **Picture:** the web's own picture, which is already
the grid: an empty square's corner from row 6, the equation as its name, `√(x + 3) = 5`.
1. **Drag the corner** (8th grade's Square and cube roots move) to a side of 5: readout `5 × 5 = 25`. Wrong: "The root is
   the side, 5: the square is 5 by 5." Release on 5 and the 25 squares fill (sets the web's square box; its slip, 10,
   "Squared means times itself.", stays with it).
2. **Tap** the + 3: three of the squares take the second shade (for − 3, three dashed squares join outside); readout
   `25 − 3 = 22 are x`. When the + a is more than the square (`√(x + 9) = 2`), all 4 squares are + 9's and 5 striped
   squares join to make up the rest: `x = −5`.
3. **Write** `x + 3 = 25`, `x = [22]` (slip: "x + 3 = 25: to undo + 3, subtract 3."), then the check line
   `√(22 + 3) = √25 = 5`.
Say: "The side is 5, so the square holds 25, and 3 of them are the + 3: x is 22."
*Fold (A-REI.2's false answers, A-CED.3):* from problem 7, one in four is `√(x + 3) = −5`: squaring still gives 22, but
the check fails, `√25 = 5, not −5`; **choose** `x = 22` / `no answer`: "A square's side is never negative: no answer."
From problem 10, `√(x + 7) = x + 1`: the plane shows y = √(x + 7) (9th grade's root graph) and the line; squaring brings
back the curve's lower half, dashed; x² + x − 6 = 0 gives 2 and −3, and **choose** the one that works, 2: −3 lands on the
dashed half (`√4 = 2, not −2`).
**Core:** as the web (a −9..9 not 0, b 2–9; smallest-of-six start; skill check as the spec, b ≥ 3). The new kinds from
problems 7 and 10 (the second built from its true answer, 0–4, and its false one, −2..−6).

### Rational equations (`g11-rateq`, new; A-REI.2, A-APR.7+, A-CED.1)
**One square:** a whole job is a bar 48 squares long (5th grade's whole: halves to twelfths). **Picture:** the story is
the instruction ("Ana fills the pool in 3 hours, Ben in 6."), drawn as two bars of one hour's work, Ana's 1/3 shaded and
Ben's 1/6 striped, each named at its right end; under them a whole bar, empty, named `1 pool`.
1. **Cut** both bars with the ruler (5th grade's Adding fractions, as it is): sixths.
2. **Slide** Ben's piece into Ana's bar: `3/6` of the pool in an hour, together.
3. **Hop** one hour's work along the whole bar (Dividing by a decimal's hop): `2 hops` fill it; readout `2 hours`.
4. **Write** `1/3 + 1/6 = 1/t`, `3/6 = 1/t`, `t = [2]`.
Say: "Together they fill half the pool each hour, so it takes 2 hours."
From problem 4 the answer can be part of an hour (2 and 4: the last hop fills a third of a hop, `t = [1⅓]`).
*Letters (A-APR.7), from problem 7:* "One pipe takes x hours, the other 2x; together, 4." The same cut with x-pieces:
`1/x + 1/(2x) = 3/(2x) = 1/4`, `x = [6]`. *No answer (A-REI.2, A-CED.3), from problem 10:* `x/(x − 2) = 2/(x − 2) + 3`:
clearing the bottoms gives x = 2, which makes x − 2 zero; **choose** `x = 2` / `no answer`: "x = 2 makes the bottom 0:
no answer."
**Core:** new. Times from 2, 3, 4, 6, 12 hours (one bar of 48 cuts them all), in pairs whose t is whole or a simple
fraction; first three equal partners or 3 and 6. Slips: the times added ("Together is faster than either alone: add
what each does in an hour."); the rate for the time ("1/2 of the pool each hour, so it takes 2 hours.").

### Where two graphs cross (`g11-crossing`, new; A-REI.11)
**One square:** across, a block is 1; on line 2, a block is a tenth (Rounding decimals' zoom); up as needed.
**Picture:** the plane with both graphs, each named at its right end, `y = x³` and `y = x + 3`; the instruction asks
where they cross.
1. **Sweep a line** (8th grade's) across the plane a block at a time: readout `x = 1: 1 and 4`, `x = 2: 8 and 5`.
   Release where the two readings are equal (a whole crossing), or **tap the block** where they swap, the lower becoming
   the higher.
2. Between whole numbers the block opens into tenths (Rounding decimals): sweep again, `1.6: 4.10 and 4.60`, `1.7: 4.91
   and 4.70`; release on the tenth before they swap.
3. **Write** `[1.6] < x < [1.7]` (8th grade's squeeze record), or `x = [2]` for a whole crossing.
Say: "Where the graphs cross, both sides give the same number: x³ = x + 3 between 1.6 and 1.7."
Kinds, one at a time: a cubic and a line, a log and a line (`log₂ x = 3 − x`, whole), a root and a line (`√x = 4 − x`),
1/x and a line, absolute value and a line (two crossings); from problem 7, two crossings, both found.
**Core:** new. Pairs from these kinds with crossings in −5..5, whole for the first three, tenths from problem 4; the
readout works out both sides (the app is the technology A-REI.11 names). Slips: the height for the answer ("4.6 is how
high. The answer is how far across."); stopping where one side is 0. Boundary: 9th grade crosses lines, parabolas and
doubling at whole numbers (`g9-overtake`, `g9-linequad`); 11th grade crosses the new curves between them.

## 7. Circles and waves (the circle: 10th grade's trig wheel, the whole way round)

### Round the unit circle (`g11-unitcircle`, new; F-TF.1, F-TF.2)
**One square:** 0.04 (the radius, 25 squares, is 1). **Picture:** the circle with its across and up axes, a point at its
right end; a strong line under the circle, where arcs unroll; the record to the right. The camera steps back to about
70%.
1. **Turn a ray** (7th grade's) counterclockwise from the right end; it snaps every 15° and the point rides the circle;
   readout `150°`.
2. **Hop** the radius along the arc the point travelled, as 10th grade's Arc length did: a 25-square stick, bent to the
   circle, laid end to end from 0°; readout `2 radii and a bit: 2.6`. **Write** `150° ≈ [2.6] radians`. In problems 1–3
   (90° or less, at most 39 squares of arc) the arc first **unrolls** (7th grade's) onto the line under the circle and
   the stick hops along it flat; past 90° the arc is too long for the screen unrolled (a half turn is 79 squares), so
   it is hopped where it lies. (A half turn holds 3.14 radii: π.)
3. Dashed lines drop from the point to both axes: readouts `across −0.87`, `up 0.5`. **Write** `cos 150° ≈ [−0.87]`,
   `sin 150° = [0.5]`.
Say: "On a circle of radius 1, sine is the point's height and cosine its across, for any turn."
Problems 1–3 stay in quadrant 1, where the point's lines make 10th grade's right triangle with a long side of 1
(so sine is up ÷ 1); from problem 4 any turn to 360° (10th grade's wheel stopped at 180°); from problem 7 past a whole
turn (`390°` comes back to `30°`); from problem 9 the other way (`−60°`).
**Core:** new. Angles in 15° steps; radians to tenths, sin and cos to hundredths (read within 0.02). Slips: sin and cos
swapped ("Sine is up, cosine is across."); a sign ("The point is left of the middle: cosine is negative."); degrees ÷ 10
for radians ("A radian is a radius of arc, about 57°."). Boundary: 12th grade makes these exact (`1/2`, `√3/2`) with
reference angles and writes radians with π (`g12-unit`, `g12-rad`).

### Waves (`g11-wave`, new; F-TF.5, F-IF.4, F-IF.7e)
**One square:** up, 1 m (2 m when the top passes 45 m), so the top, middle and bottom sit on squares; across, one turn is
40 squares whatever the period, a quarter turn two blocks, its time named under the strong line (`2 min`, or `3 h` for
a 12-hour tide). **Picture:** the wheel at the left, drawn to the same up-scale (its middle at the middle's height), a
seat at its right end; the time plane to its right from 0, one turn and a quarter wide (50 squares). The whole picture
is about 95 × 50 squares and the camera steps back to about 70%, as for the unit circle. The story is the instruction:
"The wheel is 40 m across, its middle 25 m up, and it turns once in 8 minutes."
1. **Turn** the wheel (Turn a ray, the seat on its rim) a quarter at a time: the seat's height is carried across to the
   plane at its time, and the wave draws as the wheel turns; readout `2 min: 45 m`.
2. **Sweep a line** (a level one) to the wave's middle: readout `25 m`. Wrong: "That's the bottom, 5 m. The middle is
   halfway between 5 and 45."
3. **Drag a length** from the middle up to a top: `20 m`. Wrong: "Top to bottom is 40: each swing is half, 20."
4. **Drag a length** from the start to where the wave is back at the middle, going up again: `8 min`. Wrong (at 4):
   "At 4 it's at the middle going down: half a turn. Go on to where it starts again."
5. **Write** `h = [25] + [20] sin(2πt ÷ [8])`: the middle is a slide up and the swing a stretch, as in 9th grade's
   Slide and stretch a graph.
Say: "The middle is 25, it swings 20 above and below, and it starts again every 8 minutes: 2π is one whole turn."
From problem 7 the seat starts at the top or the bottom: **choose** `sin`, `cos` or `−cos`. From problem 9 the wave is
given as a graph (tides, hours of daylight) and the record is written from it.
**Core:** new. Wheels, tides, swings, daylight: middle 5–50, swing 2–25 (no bigger than the middle for wheels), whole
metres (even ones when the top passes 45), period 4, 8, 12, 16, 20 or 24 (a quarter turn is a whole time); first three
start at the middle going up, period 4 or 8. Slips: the full height for the swing; the bottom for the middle; half a
turn for the period. Boundary: 12th grade's Shift a wave starts waves late and reads them from a rule (`g12-wave`).

### sin² + cos² = 1 (`g11-pythid`, new; F-TF.8)
**One square:** for fifths, 0.1 (the radius is 10 squares, so a 3-4-5 point's legs are 6 and 8 squares and the squares
on them hold 36, 64 and 100 squares: the identity is counted); for 25ths (from problem 7), 0.04, the unit circle's
own (radius 25, legs 7 and 24). **Picture:** the circle, a point on it with its two dashed legs (10th grade's right
triangle, its long side 1). With the three squares raised it is about 40 × 40 squares for fifths; for 25ths about 80
squares, and the camera steps back to about 60%.
1. **Raise a square on a side** (8th grade's move) on each leg and on the radius: readouts `6 × 6 = 36 of 100: 0.36`,
   `0.64`, `1`.
2. The two leg squares slide onto the radius's square and fill it, square for square (See): `0.36 + 0.64 = 1`.
3. Given `sin θ = 4/5` in quadrant 2 (the instruction), **place a point** on the circle at that height and in that
   quadrant; it snaps where height 8 meets the circle, `(−6, 8)`; readout `across −0.6`. Wrong: "That's quadrant 1.
   Quadrant 2 is left of the middle."
4. **Write** `cos² θ = 1 − 16/25 = [9]/[25]`, `cos θ = [−3]/[5]`; from problem 4 also `tan θ = sin θ ÷ cos θ =
   [−4]/[3]`, up over across (F-TF.8 asks for all three).
Say: "The legs are cos and sin and the long side is 1, so Pythagoras says sin² + cos² = 1."
**Core:** new. Points from 3-4-5 (fifths) and, from problem 7, 7-24-25 (25ths), in any quadrant; given sin find cos,
or the other way; tan from problem 4; first three in quadrant 1. Slips: the sign ("Quadrant 2 is left of the middle:
cosine is negative."); the root left off ("cos² θ is 9/25, so cos θ is 3/5."); 1 − sin ("Square first: 1 − (4/5)², not
1 − 4/5."); tan upside down ("tan is up over across: sin ÷ cos."). Boundary: 10th grade has Pythagoras and the ratios;
12th grade adds angles (`g12-addangle`) and drops its own copy of this lesson (see Taught twice).

## 8. Counting and chance

### Line them up (`g11-perm`, new; S-CP.9+)
**One square:** a cell is a block (5 × 5 squares), one ordered pick. **Picture:** for two places (problems 1–3), the
friends' initials down the left (who goes first) and along the top (who goes second), n × n empty cells (8 friends are
40 squares); name `5 friends, 2 places`.
1. **Tap** a cell where both picks are the same friend: the whole diagonal crosses out; readout `25 − 5 = 20`. Wrong
   (another cell): "Ana first and Ben second can happen. Who can't be picked twice?"
2. **Write** `5 × 4 = [20]`: five rows of four left.
From problem 4, three places: three slots in a row; **slide** any initial into slot 1, and under it is written how many
could have gone there, `5`; then slot 2, `4`; slot 3, `3`. **Write** `5 × 4 × 3 = [60]`. From problem 7, everyone in
line: `4 × 3 × 2 × 1 = [24]`, written `4!`.
Say: "Any of 5 can go first, and then 4 are left for second: 5 × 4."
**Core:** new. Two places with n 4–8 (the grid), three places with n 5–10, everyone with n 3–6; first three two places
with n ≤ 6. Slips: n × k ("Count down: 5, then 4."); nᵏ ("No one is picked twice: one fewer each time."). Boundary:
10th grade picks people along a tree (`g10-tree`); 11th grade counts the picks.

### Combinations (`g11-comb`, existing; S-CP.9+)
**One square:** a cell is 4 × 4 squares, one ordered pick (12 friends are 48 squares). **Picture:** choose 2: Line them
up's grid with its diagonal crossed out; the name `C(5, 2)` at its right end (the web's note says what the letters mean,
once: "C(n, k) counts the groups of k you can choose from n. Order doesn't matter.").
1. **Write** `5 × 4 = [20]` ordered picks (the web's step and slip: "Count down: 5, then 4, and multiply them.").
2. **Flip over a line** (8th grade's), the line being the diagonal: the half below turns over onto the half above, each
   cell landing on its twin (`B, A` on `A, B`); readout `2 orders each: 10 cells`. Sets the web's orders box (2).
3. **Write** `20 ÷ 2 = [10]` (slip: "Each group got counted once for every order.").
Choose 3 (every other problem, the web's odd indexes): **write** `5 × 4 × 3 = [60]`; **tap** one group, `A B C`: its six
orders are written out as six rows of three tiles and slide together into one bag; readout `3! = 6 orders` (slip: "3
picks can be lined up in 3! ways: multiply down from 3."); **write** `60 ÷ 6 = [10]`.
Say: "Each pair shows up twice, once in each order, so the fold halves it."
*Fold (S-CP.9's chances), from problem 9:* "2 of the 5 marbles are red. Pick 2: what's the chance both are red?" The red
pair is 1 of the 10 cells left: `P = [1]/[10]` (10th grade's tree gets the same 2/5 × 1/4).
**Core:** as the web (n 5–12; choose 2 on even problems, 3 on odd; smallest-of-six start; skill check as the spec, three
of its four items choose 3). The chance kind is new (n 5–10, 2–4 red).

### Pascal's triangle (`g11-pascal`, new; A-APR.5+) — 3D in its How to
**One square:** a brick is 6 × 3 squares, each row half a brick to the side (a wall); row 8 is 54 squares wide.
**Picture:** rows 0 to 3 built (`1`, `1 1`, `1 2 1`, `1 3 3 1`), empty bricks below them down to row n.
1. **Tap** an empty brick: the two bricks above it light; **write** their sum, `3 + 3 = [6]`. End bricks fill
   themselves with 1. Wrong: "Add the two just above it: 3 and 3."
2. **Tap** row 4: its numbers drop into the expansion's boxes, `(x + 1)⁴ = [1]x⁴ + [4]x³ + [6]x² + [4]x + [1]`. Wrong
   row: "(x + 1)⁴ uses row 4: the top 1 is row 0."
Say: "Each brick adds the two above it, because every path down comes through one of them."
*Why it works (3D, in the How to and problem 3):* a cube with edge x + 1 (x is 4 blocks, 1 is one block; Unit cubes) is
cut by the sheet at x along all three sides: 1 big cube x³, 3 slabs x² · 1, 3 rods x · 1 · 1, 1 small cube; readout
`1, 3, 3, 1`. From problem 7, `(x + 2)³ = x³ + [6]x² + [12]x + [8]`: row 3 with the powers of 2. From problem 9,
**draw** a path (the pen) from the top brick down to a brick, a brick at a time: a brick's number is how many paths
reach it, the same `C(4, 2) = 6` as in Combinations.
**Core:** new. Rows to 8; (x + 1)ⁿ with n 3–6; (x + b)ⁿ with b 2–3 and n 3–4 from problem 7; paths from problem 9.
Slips: row n − 1; the two above multiplied; the powers of b left off ("(x + 2)³: the first 3 goes with 2, the next with
2²: 3 · 2 = 6 and 3 · 4 = 12."). Boundary: 9th grade multiplies a binomial by a trinomial; this lesson raises one to
any power.

### Is it fair? (`g11-fair`, new; S-IC.2, S-MD.6–7+)
**One square:** a run of tosses is a brick 2 squares wide and 1 tall, stacked over its number of heads on a line from 0
to 20 (2 squares a head, 40 squares; 1 square a head past 30 tosses, so 40 tosses are 40 squares). 200 fair runs
pile about 35 bricks high in the middle, inside the screen. **Picture:** the story is the instruction ("Mia's coin
gave 15 heads in 20 tosses. Is it fair?"); a row of 20 coin squares; the empty line under it, 15 marked.
1. **Run trials** (7th grade's): tap `20 tosses`: the row flips (heads solid), readout `11 heads`, and a brick drops on 11.
   Then `10 more` and `100 more`: 200 fair runs pile up around 10.
2. **Sweep a line** to 15: the runs at 15 or more light; readout `4 of 200`.
3. **Choose** `a fair coin often does that` / `a fair coin rarely does that`. Wrong: "Only 4 of 200 fair runs got 15 or
   more: rarely."
Say: "A fair coin almost never gives 15 heads in 20, so this coin probably isn't fair."
From problem 4, dice and spinners ("A die gave 14 sixes in 30 rolls."); the pile counts sixes.
*Fair choices (S-MD.6–7), from problem 7:* "Who rides in front? Roll a die: 1–2 Ana, 3–4 Ben, 5–6 Cy." Run trials: the
three columns come out about even, so **choose** `fair`; a plan that gives Ana 1–3 does not. From problem 10, two plans
("Ana wins on a 5 or 6. Roll once, or roll twice and keep the bigger?"): run 100 of each, two piles side by side,
`33 wins` and `56 wins`; **choose** the plan that gives her the better chance. Wrong: "Count the wins in each pile: 56
is more than 33."
**Core:** new. 10–40 tosses, the result 40–90% heads; dice and spinners from problem 4; fair choices from problem 7; two
plans from problem 10; runs from the seed; "rarely" when fewer than 5 in 100 runs reach the result; first three clearly
fair or clearly not (10 of 20, 18 of 20). Slip: judging from one run ("One run of 20 can land anywhere: run 100.").
Boundary: 10th grade works chances out with conditions and trees (`g10-given`, `g10-tree`); this lesson runs them.

## 9. Data (piles)

### The bell curve (`g11-normal`, new; S-ID.4)
**One square:** one person: 1000 people. Across, one SD is 2 blocks (10 squares), so three SDs each side is 60 squares,
numbered at the mean and every SD (`140 … 200`); a column is a tenth of an SD, and the pile is about 40 squares tall in
the middle. **Picture:** the pile (the heights of 1000 adults, mean 170 cm, SD 10 cm), its bell drawn over it.
1. **Hop** the SD (a 10-square stick named `10 cm`) from the mean, one hop each way: the band between lights; readout
   `160 to 180: 683 of 1000, 68%`.
2. **Drag a length**, the band's edges, out to two SDs: `150 to 190: 954, 95%`.
3. The question is the instruction: "How many in 100 are taller than 190 cm?" **Hop** to 190: `2 SDs`. **Write**
   `(100 − 95) ÷ 2 = [2.5]` in 100. Wrong: "Taller than 190 is one side only: half of the 5 outside."
Say: "In a bell-shaped pile about 68 in 100 are within one SD of the middle, and 95 within two."
From problem 4, a value between SDs (`185 cm is [1.5] SDs above`), its share read from the shaded pile (the app is the
table S-ID.4 asks for); from problem 7, **choose** `bell` / `not a bell` for a lopsided pile (incomes, waiting times):
"It leans to one side: the 68–95 rule doesn't fit it."
**Core:** new. Whole means and SDs (mean 20–200, SD 2–20); the pile from the seed, 1000 people; questions at 1, 2 and 3
SDs, both sides or one; 0.5 and 1.5 from problem 4; lopsided piles from problem 7; first three one SD, both sides.
Boundary: 9th grade finds a mean and an SD (`g9-sd`); 11th grade fits the bell.

### Samples and margin of error (`g11-sample`, new; S-IC.1, S-IC.4, S-IC.6 fold)
**One square:** one student: a field of 20 × 20 squares (400 students), gray until looked at (7th grade's Guess from a
sample); under it a line from 0% to 100% for the samples (a square is 2%, a block 10%, 50 squares). A sample's dot
sits on the nearest square (its share rounded to an even percent); the readout gives the exact share, `35%`.
1. **Run trials**: `Pick 40`: 40 squares open at random; readout `14 of 40: 35%`; a dot drops on 35%.
2. **Run** `100 more` samples of 40 (the app picks them): the dots pile up and spread, `from 21% to 49%`.
3. **Drag a length** (a band) over the middle 95 dots: readout `± 14%`. **Write** `35% ± [14]%`.
4. From problem 4, samples of 100: the pile is narrower, `± 8%`.
At the end of every problem the whole field opens and the real share is marked among the dots.
Say: "Most samples land within 14% of the truth, so 35% ± 14% probably holds the real share."
*Judge a report (S-IC.6), from problem 7:* "The poster says 52% of the 40 asked like it, so most students do." The band
`52% ± 14%` reaches below 50%: **choose** `sure` / `not sure`: "52% ± 14% could be 38%: not sure."
**Core:** new. Fields of 400, the real share 20–70%; samples of 20, 40 and 100; the band from the seeded pile, rounded
to the whole percent (checks accept ± 2); first three samples of 40 from a field near 50%. Boundary: 7th grade guesses
from one sample and sees the spread; 11th grade turns the spread into a margin and judges claims with it.

### Is the difference real? (`g11-experiment`, new; S-IC.5, S-IC.3, S-IC.6 fold)
**One square:** on the cards, 1 cm of growth; on the line, a quarter of a cm (−6 to 6 cm is 48 squares). **Picture:** 20
plant cards (a bar each, its growth in squares) in two rows, `new food` and `old food`, each row's average marked and
the gap between them named `3 cm`; the empty line under them.
1. (Problems 1–3) **Choose** what kind of study the story is: `survey`, `experiment` or `just watching`. "A coin chose
   which plants got the food: an experiment."
2. **Run trials**, a trial being a shuffle: tap `shuffle`: the 20 cards are dealt into two new rows at random, the gap
   between their averages reads `0.6 cm`, and a dot drops on the line. Then `100 more`.
3. **Sweep a line** to the real gap, 3 cm: readout `2 of 100 shuffles`.
4. **Choose** `luck could do that` / `luck rarely does that`.
Say: "Shuffling almost never makes a 3 cm gap, so the food made the difference: a coin chose the groups, so nothing else
did."
*Judge a report (S-IC.3, S-IC.6), from problem 7:* "Students who eat breakfast score higher, so breakfast helps."
**Choose** `shows it` / `doesn't show it`: "Nobody chose who ate breakfast: something else could explain it."
**Core:** new. Two groups of 8–12 with whole values (cm, points, seconds); the real gap 0–3 times the shuffles' spread;
shuffles from the seed; "rarely" when fewer than 5 in 100 shuffles reach the gap; first three a big, clear gap. Slip:
two cards compared ("Compare the rows' averages, not one plant with one plant.").

## Open questions for G

1. **Trig, and four other topics, in 11th or 12th grade.** Common Core puts trig functions, the geometric sum, Pascal's
   triangle and logs in Algebra 2. Right now both plans teach five of them (see Taught twice): Waves, sin² + cos² = 1,
   the geometric sum, Pascal's triangle and the log rules. This plan keeps them in 11th grade, measured on the grid,
   with 12th grade making trig exact and taking the next step. Keep that, or move all of trig to 12th grade (the
   three 11th grade lessons move as they are, ids kept, so saved progress still counts)? Either way, one copy each.
2. **The plane's squares.** Here one block (5 squares) is 1 across, so the strong lines are the whole numbers and
   curves have room; 8th and 9th grade's plans use one square per unit, and 12th grade's mostly a block. Pick one rule
   for all of high school after seeing both in a preview (8th grade's open question 2 again)?
3. **How much to build.** 32 lessons: 13 from the web and 19 new. Two new ones, Line them up and Pascal's triangle, are
   Common Core's extras for students going on (+), as the web's Composing functions and Combinations are. Build them
   all before 11th grade opens, or open it with the 13 web lessons and add the new ones chapter by chapter? And keep
   the extras, or leave them out for a shorter year?
