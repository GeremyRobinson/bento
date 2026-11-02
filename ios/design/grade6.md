# 6th grade on paper: every lesson's plan and design

Claude, 1 Nov 2026, as 6th grade's lesson planner, in the language of `README.md` and the shape of `grade5.md`.
Planning only: nothing here is built, and each lesson waits for G's yes on its preview first (LESSONS.md §9).

**Standards covered:** all of Common Core Grade 6: 6.RP.1–3 (3a–d), 6.NS.1–8 (6a–c, 7a–d), 6.EE.1–9 (2a–c),
6.G.1–4, 6.SP.1–5 (5a–d).

**36 lessons in 8 chapters.** The 14 web lessons keep their maths as it is (generator ranges and easy-first order, the
derived values, the mistake messages, the check recipes in `specs/k12/grade6.md`, the story), with their steps designed
fresh for paper. 22 new lessons cover the standards the web catalog doesn't teach. Three web lessons take one extra
problem type for a small gap (Unit rates, One-step equations, Area of a triangle); each says so.

**Where 6th grade starts and stops.** 5th grade (finished separately) ends with the first quadrant, comparing decimals
to thousandths, expressions without letters, two-rule number patterns, line plots with fractions, volume in whole cubes
and decimals to hundredths with pictures. 6th grade starts from each: all four quadrants, comparing negatives, letters,
ratio tables and rules, dot plots with their middles and spreads, volume with fraction edges, the school methods to
thousandths. 7th grade (`grade7.md`) does arithmetic with negatives, two-step equations and inequalities,
proportions and proportional graphs, percent change, scale drawings, circles, angles, comparing two groups of data and
probability. So no 6th grade lesson adds, takes away or multiplies negative numbers; expressions keep whole numbers and
no minus signs in front (`g7-distribute` and `g7-negexpr` bring those); data is one group at a time; surface area
stays with nets of boxes, prisms and pyramids (`g7-surface` and `g10-surface` take the formulas). Decimals that repeat
are 7th grade (`g7-decimal`), so 6th grade's divisions all stop. One thing crosses over: the median is 6th grade in
Common Core but 9th on the web (Open questions).

**Every lesson** is laid out as in `grade5.md`: what to do on rows 0–2 (words 28), a miss on rows 3–4 (words 20, red),
the picture from row 6 with its names at its right end, the record 3 rows under it (beside it when the picture is
tall), the blocks under the record. The screen is about 68 × 45 squares at 100%; the camera steps back only for the
biggest numbers, never past what a child can count. A step answered by a hand move sets its Core box from the move
(`LessonRun.set`), so Core's checks and slips stay; a move that answers no web step (laying copies, swapping in a value)
is a Core step of its own whose box is what the move made. Typing only for the numbers school writes. The first words
never repeat the problem; the last words say why. Show me and the How to play each move with the ghost finger and put
everything back. A pick-one step uses the engine's choice row.

## Coverage

| Standard | Asks for | Lesson | Web or new |
|---|---|---|---|
| 6.RP.1 | ratio language | Equivalent ratios `g6-ratio` | web |
| 6.RP.2 | unit rates | Unit rates `g6-rate`; Ratio tables `g6-ratiotable` | web; new |
| 6.RP.3a | tables of equal ratios, their points, comparing | Ratio tables `g6-ratiotable`; Equivalent ratios `g6-ratio` | new; web |
| 6.RP.3b | unit prices, constant speed | Unit rates `g6-rate` (speed stories added) | web + extra type |
| 6.RP.3c | percent of a number, the whole from a part | Percent of a number `g6-pctof`, Find the whole `g6-pctwhole` | web |
| 6.RP.3d | converting units with a rate | Unit rates `g6-rate` (unit stories added) | web + extra type |
| 6.NS.1 | dividing a fraction by a fraction | Dividing fractions `g6-divide` | web |
| 6.NS.2 | long division, the school way | Long division `g6-longdiv` | new |
| 6.NS.3 | decimals: add, take away, multiply, divide | `g6-decaddsub`, `g6-decmult`, `g6-decdiv` | new |
| 6.NS.4 | GCF, LCM, a sum written as a multiple | Factor out the GCF `g6-gcf`, Least common multiple `g6-lcm` | web |
| 6.NS.5 | negatives in stories, what 0 means | Negative numbers `g6-negatives` | new |
| 6.NS.6a | opposites, the opposite's opposite | Negative numbers `g6-negatives` | new |
| 6.NS.6b | quadrants, mirror points | Points in four quadrants `g6-quadrants` | new |
| 6.NS.6c | placing numbers on lines and on the plane | `g6-negatives`, `g6-quadrants` | new |
| 6.NS.7a, 7b | order as place on the line, in stories | Compare and order `g6-compare` | new |
| 6.NS.7c | absolute value as distance from 0 | Distance on a number line `g6-numline`; `g6-compare` | web; new |
| 6.NS.7d | absolute value against order | Compare and order `g6-compare` | new |
| 6.NS.8 | the plane in four quadrants, distances on it | Shapes on the plane `g6-planeshapes`; `g6-numline` | new; web |
| 6.EE.1 | exponents | Exponents and order `g6-expo` | web |
| 6.EE.2a, 2b | writing with letters, naming the parts | Write expressions `g6-write` | new |
| 6.EE.2c | evaluating, formulas like V = s³ and SA = 6s² too | Evaluate expressions `g6-eval`; `g6-expo` (a cube's volume is s³); `g6-nets` (a cube's outside is 6 × s²) | web; new |
| 6.EE.3 | equivalent expressions by the rules | Equivalent expressions `g6-equiv`; `g6-gcf` | new; web |
| 6.EE.4 | the same for every value | Equivalent expressions `g6-equiv` | new |
| 6.EE.5 | which values make it true | Inequalities `g6-ineq`; One-step equations `g6-onestep` (its check) | new; web |
| 6.EE.6 | a letter for an unknown number | Write expressions `g6-write`; `g6-onestep` | new; web |
| 6.EE.7 | x + p = q and px = q | One-step equations `g6-onestep` (decimals and fractions added) | web + extra type |
| 6.EE.8 | x > c and x < c on a line | Inequalities `g6-ineq` | new |
| 6.EE.9 | one amount depending on another | Two quantities `g6-depend` | new |
| 6.G.1 | area of triangles, quadrilaterals, polygons | `g6-para`, `g6-poly`; `g6-tri` (slanted triangles added), `g6-trap` | new; web |
| 6.G.2 | volume with fraction edges | Volume with fraction edges `g6-fracvol` (3D) | new |
| 6.G.3 | shapes drawn on the plane | Shapes on the plane `g6-planeshapes` | new |
| 6.G.4 | nets and surface area | Nets and surface area `g6-nets` (3D) | new |
| 6.SP.1 | questions with many answers | Dot plots `g6-dotplot` | new |
| 6.SP.2 | center, spread, shape | Dot plots `g6-dotplot` | new |
| 6.SP.3 | one number for the middle, one for the spread | Find the mean `g6-mean`; `g6-median`, `g6-mad` | web; new |
| 6.SP.4 | dot plots, histograms, box plots | `g6-dotplot`, `g6-histogram`, `g6-boxplot` | new |
| 6.SP.5a, 5b | how many answers, what was measured and its unit | Dot plots `g6-dotplot` (and every data question) | new |
| 6.SP.5c | median, mean, IQR, MAD | `g6-mean`; `g6-median`, `g6-boxplot`, `g6-mad` | web; new |
| 6.SP.5d | the middle that fits the data | Find the median `g6-median` | new |

## Chapters (map order)

| # | Chapter | Lessons, in teaching order |
|---|---|---|
| 1 | Ratios and percents | Equivalent ratios `g6-ratio` · Ratio tables `g6-ratiotable` (new) · Unit rates `g6-rate` · Percent of a number `g6-pctof` · Find the whole `g6-pctwhole` |
| 2 | Factors and fractions | Least common multiple `g6-lcm` · Factor out the GCF `g6-gcf` · Dividing fractions `g6-divide` |
| 3 | Long division and decimals | Long division `g6-longdiv` (new) · Adding and subtracting decimals `g6-decaddsub` (new) · Multiplying decimals `g6-decmult` (new) · Dividing decimals `g6-decdiv` (new) |
| 4 | Negative numbers | Negative numbers `g6-negatives` (new) · Compare and order `g6-compare` (new) · Distance on a number line `g6-numline` · Points in four quadrants `g6-quadrants` (new) · Shapes on the plane `g6-planeshapes` (new) |
| 5 | Expressions | Exponents and order `g6-expo` · Write expressions `g6-write` (new) · Evaluate expressions `g6-eval` · Equivalent expressions `g6-equiv` (new) |
| 6 | Equations | One-step equations `g6-onestep` · Inequalities `g6-ineq` (new) · Two quantities `g6-depend` (new) |
| 7 | Area and volume | Area of a parallelogram `g6-para` (new) · Area of a triangle `g6-tri` · Area of a trapezoid `g6-trap` · Area of a polygon `g6-poly` (new) · Nets and surface area `g6-nets` (new, 3D) · Volume with fraction edges `g6-fracvol` (new, 3D) |
| 8 | Data | Dot plots `g6-dotplot` (new) · Histograms `g6-histogram` (new) · Find the mean `g6-mean` · Mean absolute deviation `g6-mad` (new) · Find the median `g6-median` (new) · Box plots `g6-boxplot` (new) |

The chapters follow the web's units (ratios, the number system, expressions, geometry, data); the number system is
three chapters here because 6th grade adds long division, decimals and negatives to it. Inside a chapter each lesson
needs only the ones before it.

## Hand moves

From the kit (`README.md`): ruler cut, slide pieces, tap pieces, tap a block on a line, drag a point along a line, hop
along a line, drag a rectangle's edge or corner, drag digits across place columns, tap the part that goes first, cover
the floor and build the layers (3D), write. Also from 5th grade's lessons: the cut along a grid line (Multiply two-digit
numbers) and tapping ten to close them into one (Adding decimals).

New, each shown to G in a preview before it's built (LESSONS.md §3):

| Move | What the hand does | Used by |
|---|---|---|
| **Place a point** (on the plane) | Drag a point on the plane; it snaps to grid points; dotted lines drop to both axes as it moves; the readout is its pair, "(−3, 5)". 5th grade's first-quadrant lesson may build it first. | ratiotable, quadrants, planeshapes |
| **Fold** along a grid line (3D) | Drag part of the paper over a grid line: it turns about the line. All the way over, it prints a point onto the other side and lies back (a mirror); up to a right angle, it stays (a net's face). | negatives, quadrants, nets |
| **Break one into ten** | Tap a piece of one place: it opens into ten of the next smaller place, where it sits (grouping, the other way round). | decaddsub, decdiv (longdiv plays it) |
| **Stack on a line** | Tap a value on a line, or drag its card there: a dot or a square drops onto that value's stack, and the card is crossed off. | dotplot, histogram |
| **Sort** | Drag a bar along its row: the others slide apart to make room, and it drops into the gap. | median |

## 1. Ratios and percents

Rows carry 6th grade's multiplying: one row is one copy (of a ratio, of an item and its price), so "times" is counted
down the paper in rows, the way long division and one-step equations use rows later. Percents use the fractions
family's bar: 100% is 40 squares (the length tenths use), so 10% is 4 squares and 25% is 10.

### Equivalent ratios (`g6-ratio`) · 6.RP.1, 6.RP.3a · web
**Square:** one thing, drawn as a 3 × 3 cell. **Picture:** two rectangles from row 6, a block apart: left `a` cells
wide (chapter colour), right `b` cells wide (striped), one row each to start; `2 : 3` over their tops; under the right
one its total `12`, under the left one `?`. At most 17 cells across (56 squares with the gap) and 9 rows (27 squares).
1. "Drag down until the right side is 12." **Drag** the bottom edge: both rectangles grow together a row at a time,
   each row one more 2 : 3; readout "4 rows · 12". Release at 12 (sets `factor`). Short: "9 so far. Another row."
   Past: "That's 15, past 12."
2. See: the rows number 1 to 4 down the side; every left row is 2, every right row 3.
3. **Write** `2 : 3 = 2 × 4 : 3 × 4 = [8] : 12` (sets `scale`). The adding slip (11): the web's "Multiply both
   numbers by the same number.", then measured on the paper: "4 rows of 2 on the left."

Say: "4 rows of 2 : 3 make 8 : 12. Both sides grew 4 times."
**Core:** the web's generator (a 1–9 and b 2–9, different, no shared factor; k 2–9; the first three a and b 5 or less,
k 2–3), its check, its slips ("Ratios grow by multiplying, not adding.").

### Ratio tables (`g6-ratiotable`) · 6.RP.3a, 6.RP.2 · new
**Square:** half a unit on the plane (two squares a unit). **Picture:** the first-quadrant plane from row 6, 48 × 24
squares: across 0–24 for the story's bigger amount, up 0–12 for the other, the axes named small ("minutes", "laps");
the table as the record under it, 5 or 6 columns with gaps ("2 laps take 3 minutes": laps 2, 4, 6, ?, 20 over minutes
3, 6, ?, 15, ?).
1. "Put a point for each of the first two columns." **Place a point** for each; readout "(6, 4)". Swapped: "That's
   (4, 6). Minutes go across." Off: "4 laps take 6 minutes."
2. See: a ruler line lays itself from 0 through both points and on, dashed.
3. "Slide along the line to 6 laps." **Drag** a point along the line: it snaps only to the grid points on it
   (1 1/2, 1), (3, 2), (6, 4), (9, 6)…; readout "(9, 6)"; release on the column's number (sets the gap: 9 minutes).
   Then the gap the other way (15 minutes is 10 laps). Wrong: "That's 8 laps. This column has 6."
4. **Write** the column past the paper: `20 laps take [30] minutes`.
5. "Slide to 1 lap." **Drag** the point down to (1 1/2, 1) (a grid point, two squares a unit); **write**
   `1 lap takes [1 1/2] minutes`: the unit rate (6.RP.2).

Later problems compare two tables: both lines on one plane; **drag** a point up the line at 15 minutes, the readout
showing both ("Ana 10 laps, Ben 9"), then **pick** whose is more.
Say: "Equal ratios sit on one straight line through 0."
**Core:** new; builds on `g6-ratio` and 5th grade's first quadrant. a : b with a 1–3, b 2–6, a < b, no shared factor
(so at least four columns fit the paper), story names from a list. Problems 1–3: two columns given, one gap; 4–6 gaps
both ways; 7+ the compare type. Steps: two points, the gaps, the column past the paper, one unit (1 lap takes b ÷ a
minutes: a grid point when a is 1 or 2, so it's dragged; when a is 3 it's only written, `1 lap takes [1 2/3] minutes`
for 3 : 5). Slips: a swapped pair; the
adding pattern ("Adding 3 to both isn't the same ratio. 6 laps is 3 × 2 laps."); a gap read from the wrong column.
Check: a gap up, a gap across, past the paper, a compare.

### Unit rates (`g6-rate`) · 6.RP.2, 6.RP.3b, 6.RP.3d · web (+ speed and unit stories)
**Square:** $1, drawn as a 2 × 2 cell; one row is one item. **Picture:** from row 6, left: a rectangle `n` rows tall
with no width yet, "4 apples" over it and `$12` where its area goes; right, a block away: one row to copy, "7 apples"
over it. At most 15 cells across each (30 squares) and 12 rows (24 squares).
1. "Share $12 over the 4 apples." **Drag** the left rectangle's right edge (Long division's move): each column puts $1
   in every row; readout "$8 used, $4 left"; release when nothing is left (sets `one`). Short: "$4 is still left."
   Past: "That's $16. There's only $12."
2. "Make 7 apples." **Drag** the right rectangle's bottom edge down, a row of $3 at a time; readout "7 apples";
   release at 7 (a move step).
3. **Write** `7 × $3 = [$21]` (sets `many`; 21 cells to count).

Say: "Every apple costs $3, so 7 cost 7 × $3."
**Extra type:** the same numbers told as speed ("A bike rides 36 miles in 3 hours. How far in 5 hours?": a cell is a
mile, a row an hour) and as units ("3 feet are 36 inches. How many inches in 7 feet?": u from 12, 3, 4, 7 or 10, all
inside the web's 2–15), so constant speed (6.RP.3b) and converting with a rate (6.RP.3d) take these same steps; the
record keeps its units (`36 mi ÷ 3 h = 12 mi per h`).
**Core:** the web's generator (u $2–15, n 2–9, m 2–12; the first three u 2–5, n 2–4, m 2–6; its items), its check,
its slips (multiplied instead of divided; used the cost of all; added). The story kind is picked after the numbers; a
units story redraws u from its list.

### Percent of a number (`g6-pctof`) · 6.RP.3c · web
**Square:** 2.5% (100% is 40 squares). **Picture:** the bar from row 6, 40 squares long and 4 tall, `80` at its right
end, a small 0%–100% scale over it.
1. "Cut 80 into blocks that make 30%." **Cut** with the ruler: it snaps to tenths (4 squares) and quarters (10
   squares); readout "tenths: 10 blocks"; Cut commits (25% and 75% cut quarters). Quarters for 30%: "30% isn't a
   whole number of quarters." For 50% the web's block is 10%, so quarters (which fit) get "Those fit. Cut tenths:
   50% is 5 blocks of 10%."
2. **Write** one block: `10% of 80 = [8]` (sets `base`); every block then shows 8.
3. "Shade 30%." **Tap** blocks to shade them; readout "30%"; Check: "That's 40%." Shading 70%: "That's the part not
   taken." (a move step)
4. **Write** `30% of 80 = 3 × 8 = [24]` (sets `scale`).

Say: "Each 10% is 8, so 30% is 3 of them."
**Core:** the web's generator (p from 10, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90; W 20–400 in 20s; no easy start, as
the web), its check (75%; 20–40%; 60–90%; not 10% or 25%), its slips (multiplied instead of divided; multiplied by the
percent; found what's left).

### Find the whole (`g6-pctwhole`) · 6.RP.3c · web
**Square:** 2.5% (the same bar). **Picture:** the 100% bar from row 8, dashed, named `?`; over it, on the same left
line, the known piece (25% is 10 squares) shaded with `15` in it.
1. "Lay 25% blocks to 100%." **Hop** the piece along the bar (tap to lay a copy, or drag along): copies snap end to
   end, each holding 15; readout "4 blocks · 100%"; release at the bar's end (sets `parts`). Short: "That's 75%."
   Past: "That's past 100%."
2. **Write** `15 × 4 = [60]` (sets `whole`); the bar's name becomes 60.

Say: "4 blocks of 25% make 100%, so the whole is 4 × 15."
**Core:** the web's generator (p 10, 20, 25 or 50; P 2–30; the first three p 10 or 50, P 2–10), its check (one each
of 10, 20, 25, 50), its slips (took p from 100; "You want the whole, so it's bigger than 15.").

## 2. Factors and fractions

### Least common multiple (`g6-lcm`) · 6.NS.4 · web
**Square:** one (two while the line is 24 or shorter). **Picture:** a number line from 0 to a × b, or to the last
multiple of b that is 60 or less when a × b is bigger (it always holds the LCM: the biggest LCM the generator makes is
60, for 10 and 12 and for 5 and 12, so a line stopping under 60 would miss it); a tick a square, numbers on the fives
(the grid's strong lines), at most 60 squares; room above for b's hops and under for a's.
1. "Hop by 6s to the end." **Hop** b along the line (tap to add a hop, or drag along: hops snap to 6); each landing
   is numbered above; readout "6, 12, 18, 24".
2. "Tap the first 6 that 4 goes into." **Tap** a landing: the 4s hop under the line from 0 to it; landing on it rings
   it (sets `count`). Missed: "4s go 16, 20: they jump over 18." A later one: "24 works, but 12 comes first."
3. **Write** `12 ÷ 4 = [3]` (sets `check`; the 4s' hops were just counted).

Say: "12 is the first number both counts land on."
**Core:** the web's generator (2 ≤ a < b ≤ 12; a × b 60 or less when they share no factor; no easy start), its check
(sharing a factor, sharing none, b a multiple of a), its slips (a × b "works, but there's a smaller one"; divided by
the other number).

### Factor out the GCF (`g6-gcf`) · 6.NS.4, 6.EE.3 · web
**Square:** one (two when both numbers are 24 or less). **Picture:** two bars from row 6, the fractions family's (4
squares tall, 2 apart, left ends on one block line), `A` and `B` squares long, their numbers at their right ends with
`+` between.
1. "Cut both bars into the biggest pieces that fit both." **Cut** with the ruler: the handle sets one piece's length
   (it snaps to every whole length up to the shorter bar); dashed cuts across both bars; at each bar's end a dot,
   green when a cut lands there, red when none does, with what's over ("2 over"); readout "pieces of 6"; Cut commits
   (sets `gcf`). Some over: "30 has 2 over." Fits but smaller: "Those fit. Bigger pieces fit too." Pieces of 1:
   "Pieces of 1 always fit. Find bigger ones."
2. See: the cuts turn solid and each bar's pieces number 1, 2, 3….
3. **Write** `GCF(18, 30) = 6` (written for the child from the cut), then `18 + 30 = 6([3] + [5])` (sets `factor`:
   the pieces just counted).

Say: "Both bars are made of 6s, so the 6 is written once."
**Core:** the web's generator (g 2–9; m and n 1–9, different, no shared factor; the first three all 5 or less), its
check (g 4, 6, 8 or 9; m or n 1), its slips (a smaller common factor; settled for 1; left the numbers whole;
subtracted the factor). Bars up to 81 squares: past 60 the camera steps back (about 80% at 81).

### Dividing fractions (`g6-divide`) · 6.NS.1 · web
**Square:** a whole bar is the fractions family's length (`UnlikeFractions.wholeLength`): the first of 48, 40, 42, 45,
44 or 36 that the bottoms' LCM divides; past those, twice the LCM up to 70 (56, 60, 70), else the LCM itself (56, 63,
72), and the camera steps back past 60.
**Picture:** the family's bars from row 6: `a/b` shaded, `c/d` striped under it, names at their right ends, ÷ between.
1. "Pick how many 1/4s fit in 2/3." **Pick** More than 1 or Less than 1 (sets `size`, the web's idea). Wrong:
   "1/4 is 12 squares, 2/3 is 32: more than one fits."
2. "Lay 1/4s along the 2/3." **Hop** the striped piece along under the 2/3 (tap to lay a copy, or drag along): copies
   snap end to end, numbered; the last one is laid cut off at the 2/3's end, its whole outline dashed; readout "2 and
   part of one". Past: "That's past 2/3." (a move step)
3. "Cut both bars into the same small pieces." **Cut** with the ruler (as `add`): the 2/3 is 8 small pieces, the 1/4
   is 3, and the cut-off copy covers 2 of its 3; readout "8 pieces ÷ 3 pieces".
4. **Write** `2/3 ÷ 1/4 = 2/3 × [4]/[1] = [8]/[3] = [2 2/3]` (sets `flip`, `multiply`, `simplify`, with the web's
   slips: didn't flip, flipped the first, multiplied without flipping, not yet simplest). The 8 and 3 light in the
   picture as they're written. When the bottoms share a factor the cut finds bigger pieces than the flip does (1/4 ÷
   1/6: 3 pieces ÷ 2, while the flip writes 6/4), and the simplest answer, 3/2, is the one the picture counts.

Say: "2 whole 1/4s fit, and 2/3 of another."
**Story** (the web's): "You have 2/3 yard of ribbon. How many times does a 1/4-yard piece fit in it?" The bars are the
ribbon.
**Core:** the web's generator (bottoms 2–9, proper fractions in lowest terms, never equal; the first three divide by a
unit fraction that fits more than once), its check (one where less than one fits, one story last).

## 3. Long division and decimals

6.NS.2 and 6.NS.3 ask for the school's written methods, done fluently, so the record leads here (as in Adding decimals,
where lining up is the lesson) and the picture proves each written step. Division uses rows: the amount being shared
is squares in rows as long as the divisor, so a quotient digit is a count of rows and what's left is the short last
row.

### Long division (`g6-longdiv`) · 6.NS.2 · new
**Square:** one of the place being shared now: a hundred, then a ten, then a one (the place's name is written over the
picture); a 2 × 2 cell while the divisor is 19 or less (a 24-long row of 2 × 2 cells is 48 squares, and with the
bracket's working beside it that is past the screen's 68). **Picture:** on the right, the bracket `23 ⟌ 7452` big (maths
36, 2 squares a digit) as the record; on the left from row 6, the amount being shared in rows 23 long, filled from the
top: full rows and a short last row (74 is 3 rows and 5). At most 39 squares across and 10 rows.
1. "Start where 23 goes in." **Tap** the digits to start with (Tap the part): 74. Too few: "23 doesn't go into 7.
   Take one more digit." The picture draws 74 squares.
2. "Drag down a row of 23 at a time." **Drag** the bottom edge down a row at a time: the rows above it fill in the chapter colour;
   readout "3 rows · 69"; release (sets the digit: 3 goes over the bracket, 69 under 74). Too many: "4 rows is 92.
   There are only 74." Too few: "28 are left: another row fits." Not one row fits: release at 0 rows ("Not one row
   of 23 fits: write 0.").
3. "Write what's left." **Write** `74 − 69 = [5]` (the 5 squares are there to count).
4. See: the next digit drops down beside the 5; the 5 hundreds left break into 50 tens and the 5 tens join them: 55
   squares fill rows of 23 again. Steps 2 and 3 repeat for each place.

Say: "3 hundreds, 2 tens and 4 ones: 324 rows of 23 make 7452."
**Core:** new; builds on `g5-divide`. Divisor 12–39. Problems 1–3: divisor 12–19 and a two-digit quotient 12–49 (a
3-digit number); then 3-digit quotients (4- and 5-digit numbers); from problem 4 a quotient digit may be 0; from
problem 7 a remainder (`324 r 9`). Steps: `start`, then for each place `digit` (from the drag) and `left` (typed).
Slips: started a digit early; a digit one too big or too small; the 0 left out of the quotient ("Not one row fit in
the tens: the 0 keeps the place."); a subtraction slip. Check: a 0 in the quotient, a 5-digit number, a remainder,
a plain one.

### Adding and subtracting decimals (`g6-decaddsub`) · 6.NS.3 · new
**Square:** a disc (a 2 × 2 cell) is one of its column's place (a ten, a one, a tenth, a hundredth, a thousandth),
so every column's amount is counted in discs. **Picture:**
from row 6, five place columns, each 2 blocks wide (50 squares), their names over them (small), the point on the strong
line between ones and tenths; `a`'s digits (maths 36) with its discs under each digit (2 × 2 cells, 5 across, up to 4
rows); `b` the same under it; the answer line under b. About 22 rows.
1. "Fill the empty places." **Tap** each empty place of the shorter number: a 0 is written (Adding decimals' move):
   "12.4 is 12.400".
2. Adding: "Slide them in." **Slide** b's discs up into a's columns (they pour in a column at a time); a column with
   ten or more: **tap** ten and they close into one disc in the next place. Taking away: "Slide them over to take
   away." **Slide** b's discs onto a's: in each column the covered discs are crossed out; a column without enough
   won't take them: "Only 0 thousandths. Break a hundredth." **Break one into ten**: tap a disc in the next place to the
   left and it opens into ten here (next to a 0, break the place past it first). Readout: what's left in each column.
3. **Write** `12.4 − 3.875 = [8.525]`.

The record shows the school's marks as the hands make them: a broken digit crossed out and written one less, the ten
written small over the next place.
Say: "Points under points, so each place takes from its own place." (Adding: "…so tenths add to tenths.")
**Core:** new; builds on `g5-adddec`. Numbers up to 99.999. Problems 1–3 add a number with fewer places to one with more (12.4 + 3.75: 5th grade added two hundredths numbers,
so the 0 to write is the new part), one carry, under 100;
4–6 take away with a 0 to write and one break; 7+ either sign, to thousandths, breaks across a 0 (5.003 − 1.25,
20 − 4.37). Slips: lined up the last digits instead of the points; took the smaller digit from the bigger in a column;
forgot a break (a digit one too big). Check: an add carried over the point, a take-away with a 0 written, one across
a 0, a whole number minus a decimal.

### Multiplying decimals (`g6-decmult`) · 6.NS.3 · new
**Square:** a column is a place, a block wide; a digit is 2 × 2 squares in it. **Picture:** from row 6, the place
columns of Multiply by 10, 100, 1000 (names over them small, the point fixed on the strong line between ones and
tenths), hundred-thousands to thousandths (9 columns, 45 squares: 42.75 × 3.6 is 4275 × 36 = 153900, six digits);
three rows a block apart: `a`, `b` and the product; the column working of step 2 to their right.
1. "Make both whole." **Drag** a's digits left (Multiply by 10's move: they snap a column at a time; readout "× 100"):
   4.25 is 425. Then b's: 3.6 is 36 (× 10). Short: "42.5 still has a point." Too far: "425 is already whole."
   (sets `placesA`, `placesB`)
2. **Write** `425 × 36` in columns, the school way: each partial product (`2550`, `12750`) and the total `[15300]`
   (on problems 1–3 the partial products are written for the child, as in Multiply two-digit numbers; from problem 4
   the child writes them, which is 6.NS.3's multi-digit fluency).
3. "Undo both." **Drag** the product's digits right; readout "÷ 10, ÷ 100, ÷ 1000"; release at ÷ 1000 (sets
   `point`); empty places between the point and the digits are tapped to 0 (Multiply by 10's tap). Wrong: "× 100 and
   × 10 is × 1000, so ÷ 1000."
4. See: the estimate written beside it, `4 × 4 = 16`: 15.3 is near 16.

Say: "× 100 and × 10 made it 1000 times bigger, so the point goes back 3 places."
**Core:** new; builds on `g5-multdec`, `g5-pow10`. Problems 1–3 tenths × a whole number (2.4 × 3); 4–6 tenths × tenths
and hundredths × a whole number; 7+ hundredths × tenths and a factor under 1 (0.24 × 0.4 = 0.096, its zeros tapped
in); the whole numbers up to 4 digits × 2 digits. Slips: counted places from the left; counted one factor's places
only; dropped a 0 in front. Check: a whole number × a decimal, tenths × tenths, a factor under 1, hundredths × tenths.

### Dividing decimals (`g6-decdiv`) · 6.NS.3 · new
**Square:** as Long division: one of the place being shared now, which runs on past the point into tenths and
hundredths. **Picture:** as `g6-longdiv`: the rows on the left, the bracket as the record on the right.
1. Dividing by a decimal: "Make the divisor whole." **Drag** both numbers' digits left together (they move as one;
   readout "× 10: 97.5 ÷ 15"). Short: "1.5 still has a point." Too far: "15 is already whole." (sets `shift`)
2. Long division as `g6-longdiv` (start, rows, what's left); when the ones are done, the quotient's point is written
   straight over the number's point.
3. Ones left over: "Break them into tenths." **Break one into ten**: tap the squares left; each opens into ten tenths
   and a 0 is written after the number's point; readout "2 ones = 20 tenths" (18 ÷ 4); the rows go on (drag, write what's
   left) until nothing is left.

Say: "The 2 ones left are 20 tenths, so the sharing goes on past the point."
**Core:** new; builds on `g6-longdiv`, `g5-divdec`. Quotients end by the hundredths; divisors after the shift 2–25.
Problems 1–3 a whole number ÷ one digit with a .5 or .25 answer (18 ÷ 4 = 4.5); 4–6 a decimal ÷ a whole number
(8.64 ÷ 12 = 0.72); 7+ a decimal ÷ a decimal (9.75 ÷ 1.5 = 6.5). Slips: moved one point only; the point in the wrong
place (10 times too big or small); stopped at a remainder (`4 r 6`). Check: whole ÷ whole to a decimal, decimal ÷
whole, decimal ÷ decimal, one where the shift makes the number whole.

## 4. Negative numbers

A line now runs both ways from 0, on the grid's own squares: a square a one, the strong lines at the fives, 0 on a
strong line. The plane is two such lines crossing at 0, two squares a unit, across −12 to 12 (48 squares) and up −8 to
8 (32 squares), from row 6; a short record (a pair) beside it on the right, a long one (`Area = 9 × 5 = 45`) on the
3 rows under it (rows 41–43), since 48 squares of plane leave only about 15 beside it.

### Negative numbers (`g6-negatives`) · 6.NS.5, 6.NS.6a, 6.NS.6c · new · 3D fold
**Square:** one (a degree, a meter, a dollar) on an upright line; two on a line across or when the numbers have halves. **Picture:** a line through 0: upright
for temperature and for height above and below sea level, across for money; −15 to 15 (upright 30 squares, a square a one; across 60 squares, two a one, so it fills the
screen's width; with halves −8 to 8 over 32, two squares a one), what 0 means written small beside it ("water freezes", "sea level", "$0").
1. "It's 7 below zero." **Drag** the point along the line: it snaps to ticks and its sign appears as it crosses 0;
   readout "−7"; release (sets `n`). Wrong side: "That's 7 above 0." Off by some: "That's −6."
2. Opposites: "Fold the paper at 0." **Fold** the half with the point over the 0 line: it turns over, prints the
   point on the other side, and lies back; readout "7"; **write** `−(−7) = [7]`. The opposite's opposite folds twice
   and lands where it started.

Say: "−7 and 7 are the same distance from 0, on opposite sides."
**Core:** new; no build-up (negatives start here, as `g6-numline`). Problems 1–3 a story number below 0 within −10,
upright; 4–6 opposites, across; 7+ the opposite's opposite, halves and decimals (−3.5), and pairs that say what 0
means (a gain of 5 and a loss of 5). Slips: the wrong side; counted from the line's end; the opposite of 0 ("0 is its
own opposite"). Check: a story below 0, an opposite, an opposite's opposite, a half.

### Compare and order (`g6-compare`) · 6.NS.7a, 7b, 7c, 7d · new
**Square:** half a one (two squares a one): the line across −12 to 12 (48 squares). **Picture:** the line from row 10;
two numbers to place, each a point in its own shade, their names at the right end.
1. "Put −7 and −3 on the line." **Drag** each point to its number (readout "−7").
2. **Pick** `<` or `>` between the names (sets `sign`); in a story it reads as words ("−7 °C is colder than
   −3 °C"). Wrong: "−7 is left of −3, so it's less."
3. Absolute value problems: "Measure each one from 0." **Drag** a bracket from 0 to each point; readout "7 from 0"
   (sets `|−7|` and `|−3|`); then **pick** which is farther.

Later problems put three numbers on the line and write them in order (`−6 < −2 < 5`).
Say: "Left is less. −7 is less than −3, but farther from 0."
**Core:** new; builds on `g6-negatives`. Problems 1–3 a negative and a positive; 4–6 two negatives (the slip "7 is
more than 3"); 7+ halves and tenths (−2.5 and −2), three in order, and absolute value against order (−8 is less
than −5, but a $8 debt is the bigger debt; both fit the line's −12 to 12). Slips: compared the digits; |−7| written −7. Check: two negatives, a
negative and a positive, a half, an absolute value pair.

### Distance on a number line (`g6-numline`) · 6.NS.7c, 6.NS.8 · web
**Square:** half a step (two squares a step; four for the first three problems, within 5 of 0). **Picture:** the line
across from a − 1 to b + 1 (at most 52 squares), 0 on a strong line, dots at a and b, numbers at a, 0 and b (as the
web).
1. "Drag from −3 to 0." **Drag** from the left dot, a bracket following the finger; readout "3 steps"; release at 0
   (sets `neg`). Elsewhere: "Stop at 0."
2. "Now from 0 to 5." **Drag** again; readout "5 steps" (sets `pos`).
3. **Write** `|−3| + |5| = 3 + 5 = [8]` (sets `sum`); the two brackets join into one, "8 apart".

Say: "You cross 0, so the two distances add."
**Core:** the web's generator (a −12 to −1, b 1 to 12; the first three within 5), its check (two plain; both 7 or
more; the negative farther), its slips (a negative distance; counted the marks; took one from the other).

### Points in four quadrants (`g6-quadrants`) · 6.NS.6b, 6.NS.6c · new · 3D fold
**Square:** half a unit (the plane above). **Picture:** the plane from row 6, the quadrants' numbers I–IV small in
their corners; the pair to place is in the instruction ("Put (−3, 5) on the paper.").
1. **Place a point** (sets `x` and `y`): dotted lines drop to both axes as it moves; readout "(−3, 5)". Swapped:
   "That's (5, −3). x comes first." A sign: "That's (3, 5). x is −3, left of 0."
2. Mirrors: "Fold over the x-axis." **Fold** the half with the point over the axis: the point prints its mirror;
   readout "(−3, −5)"; **write** `([−3], [−5])`. Over both axes: two folds.

Say: "A fold over the x-axis keeps x and flips the sign of y."
**Core:** new; builds on `g6-negatives` and 5th grade's first quadrant. Problems 1–3 one negative number within 6
(quadrants II and IV); 4–6 any quadrant; 7+ folds over x, y or both, halves (−2.5), and the quadrant from the signs
(pick I–IV). Slips: swapped; one sign; folded over the wrong axis ("That flips x. Over the x-axis, y flips."). Check:
one each in II, III and IV, a fold.

### Shapes on the plane (`g6-planeshapes`) · 6.NS.8, 6.G.3 · new
**Square:** half a unit (the plane). **Picture:** the plane from row 6; two corners of a rectangle drawn with their
pairs (`(−4, 3)` and `(5, 3)`); the story says what it is (a park, a pen, a garden).
1. "Put the other two corners." **Place a point** for each; the sides draw in as each corner lands. Not a rectangle:
   "A corner shares x with one corner and y with the other."
2. "Measure the top." **Drag** along the side from corner to corner: it counts units, and crossing an axis splits
   the count; readout "4 + 5 = 9" (sets `side`). A side on one side of the axis: "7 − 2 = 5".
3. **Write** the other side `|3| + |−2| = [5]`, then `Area = 9 × 5 = [45]` square units (or the perimeter).

Say: "The side crosses the axis, so the two distances to it add."
**Core:** new; builds on `g6-quadrants`, `g6-numline`. Corners inside the plane. Problems 1–3 rectangles with one side
crossing an axis; 4–6 both sides crossing; 7+ sides on one side of an axis (take away), and L-shaped fences from 5 or
6 given corners (perimeter). Slips: took away across the axis ("The side crosses 0: 4 and 5 add."); added on one side;
counted the corner points (one too many). Check: crossing, not crossing, an area, a perimeter.

## 5. Expressions

A letter is a strip whose length isn't known yet: a plain bar with a dashed end and the letter in it, the same length
wherever it's written. Swapping in a number drags the strip to that length, and every copy goes with it.

### Exponents and order (`g6-expo`) · 6.EE.1, 6.EE.2c · web · 3D for cubes
**Square:** one block is one, as in Unit cubes. **Picture:** `4² + 5 × 3` written once, big, as the record's first
line (as Order of operations); under it the power, built in blocks (at most 5 × 5 blocks, 25 squares).
1. "Tap what goes first." **Tap** the power (Order of operations' move). Wrong: "The exponent goes before × and +."
2. "Build 4²." **Drag** the corner out a block at a time; readout "4 × 4"; release at 4 by 4. A cube: the paper tilts
   and "Build it up": **drag up** the layers; readout "4 × 4 × 4"; the paper lies flat again after (sets `count`: 2
   or 3). A 4 by 2 rectangle: "That's 4 × 2. 4² is 4 by 4." (the web's slip, base × exponent, made visible)
3. **Write** `4² = [16]` (sets `exp`; the squares or cubes count it). A cube's count is its volume, s³ (6.EE.2c).
4. **Tap** what's next (the ×), **write** `5 × 3 = [15]` (sets `mul`), then `16 + 15 = [31]` (sets `add`).

Say: "4² is 4 × 4, and it goes before × and +."
**Core:** the web's generator (a 2–5, n 2–3, b and c 2–9; the first three a 3–4 squared and b, c 2–5; never 2²), its
check (a cube; a square of 3 or more; never 2²), its slips (read the base; base × exponent; added first).

### Write expressions (`g6-write`) · 6.EE.2a, 6.EE.2b, 6.EE.6 · new
**Square:** one. **Picture:** from row 6, a tray at the left: an `n` strip (8 squares, dashed end) and a row of 10
squares; to its right a build line 40 squares long; the words are the instruction ("3 times n, plus 5.").
1. **Slide** pieces from the tray onto the line: strips and squares snap end to end; "less than" slides squares over
   the end to take them away (crossed out, as `sub`); "half of" cuts a strip with the ruler; readout: what's built
   ("n + n + n + 5"). Wrong: "That's n + 5. The words say 3 times n." / "10 − n: start with 10 and take n away."
2. **Write** `[3]n + [5]` (the numbers typed; the letter and signs come from what's built).
3. "Tap the coefficient." **Tap** the part named: the coefficient, a term, the sum, the product, a factor or the
   quotient. Wrong: "5 is a term on its own. The coefficient multiplies n."

Say: "3n means 3 n's, so 3 is the coefficient."
**Core:** new; builds on 5th grade's expressions without letters and `g6-expo`. Phrases: problems 1–3 "5 more than
n", "3 times n"; 4–6 "n less than 10", "half of n", "3 times n, plus 5"; 7+ "twice the sum of n and 4" and stories
that need the letter (6.EE.6: "Sam has n cards and gets 4 more."). Numbers 2–9 (10–20 when taking away). Slips: the
order turned round (n − 10 for "n less than 10"); the brackets dropped (2n + 4). Check: a sum, a take-away turned
round, twice a sum, a part named.

### Evaluate expressions (`g6-eval`) · 6.EE.2c · web
**Square:** one, drawn as a 2 × 2 cell. **Picture:** `3x + 2y` as rows from row 6: 3 rows of an `x` strip on the
left and, a block away, 2 rows of a `y` strip (striped); the values as the picture's names ("x = 4", "y = 5"). At most
9 rows and 9 cells a strip (18 squares) each side.
1. "Make x 4." **Drag** the end of an x strip: every x row stretches with it, a cell at a time; readout "x = 4";
   release at 4 (a move step). The letter gives way to 4 in every strip. Elsewhere: "That's 5. x is 4."
2. **Write** `3 × 4 = [12]` (sets `ax`; 3 rows of 4 to count).
3. "Make y 5." **Drag** a y strip; **write** `2 × 5 = [10]` (sets `by`).
4. **Write** `12 + 10 = [22]` (sets `add`).

Say: "Every x is 4, so 3x is 3 rows of 4."
**Core:** the web's generator (a and b 2–9, x and y 1–9; the first three all 5 or less), its check (one with x or y
1), its slips (wrote 3 and 4 side by side as 34; added; multiplied the parts).

### Equivalent expressions (`g6-equiv`) · 6.EE.3, 6.EE.4 · new
**Square:** one, drawn as a 2 × 2 cell. **Picture:** an area from row 6: `a` rows tall and `x + b` across, the x part
a strip of any length (dashed end, 6 cells to start), the b part `b` cells; a and b written at the sides. At most 6
rows (12 squares) and about 21 cells across (42 squares).
1. By the kind:
   - Combining (first problems): `x + x + x` as three strips in a column. **Slide** them together into one rectangle;
     readout "3 rows of x"; **write** `x + x + x = [3]x`.
   - Distributing: `3(x + 4)`. "Cut where x ends." **Cut** along the grid line between the x part and the 4 (as
     Multiply two-digit numbers' cut where the tens end); readout "x | 4". Elsewhere: "Cut where x ends." **Write**
     `3(x + 4) = [3]x + [12]`.
   - Factoring (later): `6x + 9` as 6 strips and 9 cells. **Drag** the rows' edge to a height where both parts make
     whole rows (as `g6-gcf`, strips and all); readout "3 rows: 2x and 3"; **write** `6x + 9 = [3]([2]x + [3])`.
2. "Drag x." **Drag** x's strip to any length: both sides' values show in the readout, the same every time ("x = 7:
   33 and 33"). A pair that isn't the same (`2(x + 3)` and `2x + 3`) shows two numbers: **pick** Same or Not the same.

Say: "3 rows of x + 4 are 3x + 12, whatever x is."
**Core:** new; builds on `g6-eval`, `g6-gcf`. a 2–6, b 1–9, x drawn 3–12 cells. Problems 1–3 combining 2–5 strips;
4–6 distributing; 7+ factoring (g 2–5, m and n 1–5 with no shared factor) and same-or-not pairs. Slips: multiplied
only the first part (3x + 4); a common factor but not the greatest; added the number to x. Check: a combine, a
distribute, a factor, a same-or-not.

## 6. Equations

An equation is two sides that balance: what's left of = is as long as what's right of it, left ends on one block line.
Whatever is done to one side is done to the other.

### One-step equations (`g6-onestep`) · 6.EE.7, 6.EE.5 · web (+ decimals and fractions)
**Square:** one (a 2 × 2 cell while a side is 24 or shorter); x is a plain strip with no squares in it. **Picture:**
from row 6, by the kind (the web's t):
`x + 7 = 15` and `x − 7 = 8`: the left side over the right side as bars (x then 7 cells, over 15 cells; for x − 7,
x with 7 cells crossed off its end);
`3x = 27`: 3 rows of x beside a rectangle 3 rows tall whose width is found;
`x ÷ 3 = 4`: x as a rectangle 3 rows tall with one row shaded, beside a row of 4 cells.
1. The undo:
   - `x + 7`: "Take 7 off both sides." **Slide** the 7 off the left bar's end: the right bar's last 7 cross out with
     it; readout "− 7 on both". Dropped on one side only: "Take it off both sides."
   - `x − 7`: "Put 7 back on both sides." **Slide** 7 cells onto both ends.
   - `3x`: "Share 27 into 3 rows." **Drag** the rectangle's right edge (Long division's move); readout "18 used, 9
     left"; release when it's all used: one row is one x.
   - `x ÷ 3`: "Make all 3 rows." **Drag** the right side's bottom edge down to 3 rows of 4.
   Doing the same instead of the opposite (the web's slip): "Do the opposite to undo it."
2. The x strip lines up with what's left: **write** `x = [8]` (sets `undo`).
3. **Write** the check `8 + 7 = [15]` (sets `check`).

Say: "Take 7 off both sides and they still balance: x is 8."
**Extra type:** in practice after problem 8, halves and quarters too (`x + 1.5 = 4.25`, `3x = 4.5`, `x + 3/4 = 2`; a
cell is a quarter or a half), so x, p and q can be fractions and decimals as 6.EE.7 says. The web's problems and its
check stay as they are.
**Core:** the web's generator (t 0–3, a 2–9, r 2–12: x is r for + and ×, the right side is r for − and ÷, so x reaches 21 and 108; no easy start), its check (one of each t), its
slips (used the same operation; wrote x again).

### Inequalities (`g6-ineq`) · 6.EE.8, 6.EE.5 · new
**Square:** half a one (two squares a one). **Picture:** the line across from row 10, 20 ones (40 squares) around the
story's number; the story is the instruction ("You must be older than 8.").
1. "Put the circle on 8." **Drag** the circle along the line (it snaps to ticks); **tap** it to leave it open (8
   doesn't count) or fill it ("at least", "at most").
2. "Shade every age that works." **Drag** the arrow along the line: the numbers it passes shade, and it runs off the
   line's end. The wrong way: "Older than 8 means bigger: to the right." Filled for "older than": "8 isn't older than
   8: leave it open."
3. "Tap the ones that work." From a set (5, 8, 9 1/2, 12): **tap** each that makes it true; it lights on the ray.
   One that doesn't: "5 is less than 8." (6.EE.5)
4. **Write** `x [>] [8]` (pick the sign, type the number).

Say: "Every number past 8 works, far too many to list."
**Core:** new; builds on `g6-compare`. The story's number −10 to 20 (halves later). Problems 1–3 > and < with whole
numbers; 4–6 ≥ and ≤ ("at least", "at most"); 7+ negative numbers, and test sets with fractions and decimals. Slips:
the ray the wrong way; the number itself counted for > or <; the sign turned round in writing. Check: a >, a <, a ≥
with its own number tested, a negative number.

### Two quantities (`g6-depend`) · 6.EE.9 · new
**Square:** the plane's own: across 0–10 at 4 squares a one (40 squares), up 0–30 at a square a one (a square is 5
for rules that grow by 5, 10 or 15); the table beside it as the record. **Picture:** from row 6, the plane with the
story's names on its axes ("hours" across, "miles" up) and a handle on the across axis.
1. "Drag the hours to 2, 4 and 6." **Drag** the handle along the across axis (it snaps to whole numbers): the point
   rides the rule's line above it, and the table writes a column at each stop; readout "2 hours · 6 miles" (move
   steps: the three columns).
2. **Write** the rule: `m = [3] × h` (or `a = s + [5]` for "older by" and "more than" stories). A wrong number:
   "m = 2 × h makes 4 miles at 2 hours. The table says 6."
3. **Write** a value past the paper: `h = 20: m = [60]`.

Say: "You change the hours; the miles depend on them: m = 3 × h."
**Core:** new; builds on `g6-ratiotable`, `g6-eval` and 5th grade's number patterns (two rules, their pairs plotted;
here one amount is named by a letter and depends on the other). Rules y = kx (k 2–3, or 5, 10, 15 on the squares-of-5 axis)
and y = x + c (c 1–20); stories: walking or riding at one speed, tickets and their cost, ages, laps and minutes.
Problems 1–3 y = kx; 4–6 y = x + c; 7+ either, and a value backwards (which x gives y = 30). Slips: an adding rule for
a times table ("m = h + 4 works at 2 hours, but at 4 hours it gives 8, not 12."); x and y swapped. Check: a times
rule, an adding rule, past the paper, backwards.

## 7. Area and volume

One square is one square unit, every corner on a grid point, so every area can be counted. A shape is two squares a
unit when it's 14 units or less each way, else one; its base and height are labelled half a square from their sides,
the height a dashed line with a square corner.

### Area of a parallelogram (`g6-para`) · 6.G.1 · new
**Picture:** the parallelogram from row 6: base `b` along a grid line, its top `s` units along, height `h`; its squares
faint inside (the slanted sides cut some).
1. "Cut straight down." **Cut** along a grid line from the top side to the bottom side (the cut snaps to columns);
   readout "a cut 3 from the corner". One that misses a side: "Cut from the top side to the bottom side."
2. "Slide the piece to the other end." **Slide** it: it snaps when its slanted side meets the other one. Elsewhere:
   "Slide it to the other end."
3. See: a `b` by `h` rectangle, its squares counting row by row. **Write** `Area = 12 × 5 = [60]` square units.

Say: "Cut and slide: the same squares make a 12 by 5 rectangle."
**Core:** new; builds on `g4-area`. b 4–16, h 2–12, s 1 to b − 1. Problems 1–3 b 10 or less, h 6 or less, s 3 or
less, leaning right; then leaning either way, the full range, and stories (a garden bed, a sign). Slips: halved it
("That's a triangle's area. A parallelogram is the whole rectangle."); added. Check: one leaning left, one with h odd,
a big one, a story.

### Area of a triangle (`g6-tri`) · 6.G.1 · web (+ slanted triangles)
**Picture:** the triangle from row 6, its base `b` along a grid line, its top `h` above; a copy turned half a turn
waits beside it (above it when the triangle is wide), dashed, in its shade. The web always draws a right triangle; on
paper the top sits over one end (right triangles), over the base, or past its end, so other triangles are met too (a
picture number Core adds; the maths stays b and h).
1. "Fit the copy against it." **Slide** the turned copy against the slanted side; it snaps when it fits. Elsewhere:
   "Put it against the slanted side." See: the two make a `b` by `h` rectangle, or a parallelogram that becomes one
   as in `g6-para` (played, not done).
2. **Write** `6 × 4 = [24]` (sets `rect`), `24 ÷ 2 = [12]` (sets `half`).

Say: "Two copies make a 6 by 4 rectangle, so one is half."
**Core:** the web's generator (b and h 2–20, b × h even; no easy start), its check (b or h odd; both 10 or more), its
slips (added instead of multiplied; forgot to halve).

### Area of a trapezoid (`g6-trap`) · 6.G.1 · web
**Picture:** the web's right trapezoid from row 6: bottom `a`, top `b`, height `h`, left side upright; its copy turned
half a turn beside it.
1. "Fit the copy against it." **Slide** the turned copy (it swings half a turn as it's picked up, the web's motion)
   against the slanted side; it snaps; the two make a rectangle `a + b` long.
2. **Write** `4 + 8 = [12]` (sets `sum`), `12 × 5 = [60]` (`times`), `60 ÷ 2 = [30]` (`half`).

Say: "Two trapezoids make a 12 by 5 rectangle, so one is half."
**Core:** the web's generator (bases 2–15 and different, height 2–12, a whole area), its check (a + b odd; h odd), its
slips (multiplied the bases; added the height; forgot to halve).

### Area of a polygon (`g6-poly`) · 6.G.1 · new
**Picture:** from row 6, a shape made of rectangles and right triangles (an L, a house, an arrow, a boat), every corner
on a grid point, its sides labelled.
1. "Cut it into rectangles and triangles." **Cut** along grid lines (each cut runs edge to edge; several cuts; Cut
   commits): each piece names itself small ("6 × 4", "6 × 3 ÷ 2"). A piece that's neither: "That piece isn't a
   rectangle or a triangle."
2. **Write** each piece `6 × 4 = [24]`, `6 × 3 ÷ 2 = [9]`, then `24 + 9 = [33]` square units.

Say: "Cut into a rectangle and a triangle, the areas add."
**Core:** new; builds on `g6-tri`. Sides 2–12. Problems 1–3 L-shapes (two rectangles); 4–6 a rectangle and a triangle;
7+ two triangles, and shapes found by taking a corner off a rectangle (the cut takes it away). Slips: a triangle
counted as its whole rectangle; a piece counted twice. Check: an L, one triangle, two triangles, a take-away.

### Nets and surface area (`g6-nets`) · 6.G.4 · new · 3D
**Square:** one square unit, two squares a unit. **Picture:** flat, from row 6: a box's net, the strip of four sides
across with the top and bottom above and below one of them (at most 44 × 28 squares); every face's sides labelled.
1. "Fold it into a box." **Fold** each face up: drag a face toward the middle; the paper tilts (Unit cubes' view) and
   the face turns about its edge and stays upright; the top folds over last; readout "5 of 6 faces"; the box closes.
2. The box opens and the paper lies flat. "Tap each face." **Tap** a face: it fills and its area is written in it
   ("5 × 4 = 20"); faces the same size light together after the first; readout the running total.
3. **Write** `SA = 2 × 20 + 2 × 15 + 2 × 12 = [94]` square units; for a cube, `SA = 6 × 4² = [96]` (6 faces the same,
   the formula of 6.EE.2c).

Say: "The net is the box's outside laid flat: 94 squares cover it."
**Core:** new; builds on `g6-tri`, `g5-volume`. Edges 1–6. Problems 1–3 cubes and boxes with edges to 5; 4–6 boxes to
6 × 5 × 4; 7+ triangular prisms and square pyramids (triangle faces by base × height ÷ 2). Slips: three faces only
(half the total); the volume ("That's the cubes inside. The surface is the faces."). Check: a cube, a box, a pyramid,
a prism.

### Volume with fraction edges (`g6-fracvol`) · 6.G.2 · new · 3D
**Square:** one block is a small cube with edges of 1/2 (Unit cubes' "one cube is one block"); a whole cube is 2 × 2 ×
2 blocks, its edges bold. **Picture:** flat, from row 6: the floor's outline, its lengths as fractions (1 1/2 and 2),
the half-unit blocks inside (at most 6 × 6 blocks, 30 squares).
1. "Cover the floor." **Tap or drag** across it (Volume of a box's move); readout "12 small squares".
2. The paper tilts and the floor rises into the first layer of small cubes. "Build it up to 1 1/2." **Drag up** the
   layers; readout "36 small cubes".
3. See: 8 small cubes in a corner light as one whole cube. **Write** `36 ÷ 8 = [4 1/2]` cubic units; then the record
   `V = 1 1/2 × 2 × 1 1/2 = 4 1/2`, the same as the count. The paper lies flat before the next problem.

Say: "8 small cubes make one whole cube, so 36 of them make 4 1/2."
**Core:** new; builds on `g5-volume`, `g5-multfrac`. Edges 1/2 to 3 in halves (1–6 blocks), at most 72 small cubes.
Problems 1–3 one edge a half; 4–6 two; 7+ all three, then V = B × h (the floor's area first), and thirds (a whole is
3 × 3 × 3 blocks). Slips: the small cubes counted as wholes ("8 small cubes make one whole."); only the whole parts
multiplied. Check: one half edge, two, three, B × h.

## 8. Data

Data is drawn on a line or as bars, one square for one of what was counted, so every middle and every spread can be
counted on the paper. Every data problem starts from its question and its unit ("How many minutes do you read a
day?"), which is 6.SP.5b.

### Dot plots (`g6-dotplot`) · 6.SP.1, 6.SP.2, 6.SP.4, 6.SP.5a, 6.SP.5b · new
**Square:** a dot is a 2 × 2 cell. **Picture:** from row 6, room for the stacks (up to 8 dots, 16 squares), the line
across under it (0–10, 4 squares a one: 40 squares), the question over it, the answers as number cards under it
(8–15 cards, 4 × 3 squares each, in rows of 8 a square apart, so two rows at most: one row of 15 would be 75 squares).
1. First problems: "Pick the question with many answers." **Pick** one of two ("How old is Mia?" or "How old are the kids
   in Mia's class?"). Wrong: "Everyone gives the same answer to that one."
2. "Put each answer on the line." **Stack**: tap the answer's number on the line (or drag its card there): its dot
   drops onto that number's stack and the card is crossed off; readout "9 of 12". The wrong number: "That card says
   4."
3. **Write** how many answers: `[12]`.
4. "Tap where most answers are." **Tap** the tallest stack. "From least to most:" **drag** a bracket from the least
   answer to the greatest; readout "1 to 9".

Say: "Most read 4 minutes, and the answers spread from 1 to 9."
**Core:** new; builds on `g4-lineplot` and 5th grade's line plots. 8–15 answers 0–10, each set with a peak and one
feature (a cluster, a gap, a far-off answer); questions and units from a list. Problems 1–3 eight answers 0–6, with
the question pick; then more. Slips: missed a dot; the spread given as how many. Check: a question pick, a count, a
peak, a spread.

### Histograms (`g6-histogram`) · 6.SP.4 · new
**Square:** one unit across (a stretch is 10 squares); two squares a count up. **Picture:** from row 6, counts up the
side to 10 (20 squares), the axis across under them, 0–49 in five stretches of 10 (50 squares), the answers as cards
under it (10–15, in rows of 8 as in Dot plots).
1. "Put each answer in its stretch." **Stack**: tap the stretch (or drag the card in): its bar rises one count;
   readout "20–29: 4". Wrong: "37 goes in 30–39."
2. "Tap the stretches it asks for." ("How many read 30 minutes or more?") **Tap** each: it lights and its count adds
   in the readout ("4 + 3 = 7"). Too few: "40–49 is 30 or more too."
3. **Write** `[7]`.

Say: "A histogram counts how many land in each equal stretch."
**Core:** new; builds on `g6-dotplot`. 10–15 answers 0–49 with a shape (one hump, or leaning one way); questions about
one stretch, "or more" and "fewer than". Slips: counted the bars, not their heights; left out a stretch. Check: one
stretch, "or more", "fewer than", the tallest.

### Find the mean (`g6-mean`) · 6.SP.3, 6.SP.5c · web
**Square:** one. **Picture:** the numbers as bars from row 6 (4 squares wide, 2 apart, up to 20 tall), each number
under its bar.
1. "Level the bars." **Slide** squares from tall bars onto short ones (drag from inside a bar: the squares above the
   finger come along and stack on the bar they're dropped on); readout the heights ("6, 6, 7, 5"). When every bar is
   level, it's answered (sets `divide`, the mean).
2. **Write** `(3 + 5 + 7 + 9) ÷ 4 = [24] ÷ [4] = 6` (sets `sum` and `count`; the mean was set by the levelling).

Say: "Shared out equally, every bar is 6: the mean is 6."
**Core:** the web's generator (4–6 numbers 1–20 with a whole mean; no easy start), its check (one each of 4, 5 and 6
numbers), its slips (left one out; wrote the total; missed one; multiplied).

### Mean absolute deviation (`g6-mad`) · 6.SP.5c, 6.SP.3 · new
**Square:** one. **Picture:** the bars of `g6-mean` from row 6 (4–8 numbers) and a level line across them that moves
up and down.
1. "Find where they balance." **Drag** the line; readout "5 above, 3 below" (the squares over it and the gaps under
   it); release where they're equal (sets `mean`). Wrong: "5 above, 3 below: move it up."
2. "Tap each bar to measure it from the line." **Tap** each bar: the part over the line or the gap under it lights and counts
   ("3 away"); readout the running total.
3. See: the distances slide into a row of their own and level out (as `g6-mean`). **Write**
   `(3 + 1 + 0 + 2 + 4 + 2) ÷ 6 = [12] ÷ 6 = [2]`.

Say: "On average each answer is 2 from the mean."
**Core:** new; builds on `g6-mean`. 4–8 numbers 1–20, redrawn until the mean and the MAD are whole. Problems 1–3 four
or five numbers close together. Slips: distances with their signs (adding to 0: "3 below is 3 away."); didn't divide.
Check: 4, 5 and 6 numbers, one number on the mean.

### Find the median (`g6-median`) · 6.SP.5c, 6.SP.3, 6.SP.5d · new (the maths of the web's `g9-median`)
**Square:** one. **Picture:** the numbers as bars from row 6 (as `g6-mean`; up to 30 tall, the record beside).
1. "Put them in order." **Sort**: drag a bar to its place and the others make room; readout "in order".
2. "Cross them off from both ends." **Tap** the shortest and the tallest left, a pair at a time: each pair crosses
   out and the middle bar is left (two for an even count, and their halfway) (sets `median`). Another bar: "Cross off
   the shortest and the tallest left."
3. **Write** `median = [13]` (for two: `(12 + 15) ÷ 2 = [13.5]`).
4. "Make the tallest taller." **Drag** its top up: the readout shows the mean running after it and the median staying
   ("mean 14 → 19, median 13").

Say: "The middle stays when the tallest grows. The mean moves."
**Core:** new. Problems 1–6 the generator of the web's `g9-median` (5 or 7 numbers 1–30; the web has no easy start, so
problems 1–3 here are 5 numbers), its steps `count`, `spot`, `median` and their slips. The sorted bars number
themselves 1 to 7 (sets `count`; a repeat is two bars, so "Count every number, including any that repeat." is shown
by the picture), the crossing-off lands on bar 4, and the record writes `7 bars: (7 + 1) ÷ 2 = [4]` before
`median = [13]` (sets `spot`, with the web's "Add 1 before halving"). "Didn't sort first" can't happen, since the
sort comes first, so that slip is dropped (the hands make it pointless, as in `grade5.md`). From problem 7 six or eight numbers (halfway
between the middle two, whole or .5). Check (the web's, plus one): 5 numbers, 7 numbers with the unsorted middle not
the median, a repeat, an even count.

### Box plots (`g6-boxplot`) · 6.SP.4, 6.SP.5c · new
**Square:** a dot is a 2 × 2 cell on a line 0–20 (2 squares a one: 40 squares). **Picture:** from row 6, the dot plot
of 11–15 answers, already stacked, and a strip under it for the box.
1. "Tap the middle answer." **Tap** it (or cross off pairs from the ends, as `g6-median`); readout "6 below, 6 above"
   (sets `median`). Another dot: "That one has 5 below and 7 above."
2. "Now the middle of each half." **Tap** the middle of the lower half and of the upper half (sets `q1`, `q3`); each
   half shades as it's found.
3. See: the box draws from the lower middle to the upper middle, the whiskers out to the least and the greatest.
4. **Write** `IQR = 12 − 6 = [6]`.

Say: "The box holds the middle half of the answers: 6 wide."
**Core:** new; builds on `g6-median`. 11–15 answers 0–20. Problems 1–3 11 or 15 answers (the halves are 5
or 7 answers, so the quarter points are answers; the median is left out of both halves, the school way); then 12–14
answers (halfway points), and one with a far-off answer (a long whisker). Slips: the spread from least to
greatest given as the IQR; the median counted in a half. Check: odd, even, a far-off answer, a story.

## Open questions for G

1. **The median in 6th grade.** Common Core teaches the median in 6th grade, but the web has it in 9th (`g9-median`,
   a plain "find the median"). This plan teaches it in 6th (`g6-median`, starting from g9-median's own problems).
   Should 9th grade drop `g9-median`, or keep it as review?
2. **36 lessons.** All 36 are needed to cover 6th grade; 5th grade will have 21 (its 17 and 4 new). If that's too many, two places
   could merge: the four in Long division and decimals into two (dividing; adding to multiplying), and Histograms and
   Box plots into Dot plots. Keep all 36?
3. **Five new hand moves** need your yes on a preview before they're built: Place a point on the plane, Fold along a
   grid line (3D), Break one into ten, Stack on a line, Sort.
4. **An extra problem type in three web lessons.** To cover their standards without new lessons, Unit rates gets speed
   and unit-conversion stories, One-step equations gets decimals and fractions, and Area of a triangle draws slanted
   triangles (the web draws only right ones). The web's problems, answers and checks stay the same; the new types are
   extra practice. OK?
