# 5th grade on paper: every lesson's design

Claude, 20 Oct 2026, in the language of `README.md` (what worked: Claude's Rounding decimals and Adding fractions on the
test page; 3D from Unit cubes). Each lesson: what one square is, the picture, each step's hand move (with its live
readout, what a wrong move says, what the picture then shows), the record, and what changes in Core. Sizes in squares
(the iPad landscape screen is about 68 × 45 at 100%; the camera may step back for big numbers but never past what a
child can count).

Every lesson: instruction on rows 0–2; a miss's words on rows 3–4 (red); the picture from row 6; its names at its right
end; the record 3 rows under the picture; the blocks under the record. Steps answered by a hand move set their Core box
from the move (`LessonRun.set`), so Core's checks and slip messages stay. Steps the hands make pointless are dropped.
The first words never repeat the problem; the last words say why.

## Fractions family (bars a whole long, the ruler, sliding pieces)

A whole bar has a fixed length per problem, the smallest of 48, 45, 42, 40 or 36 squares that every bottom in the
problem divides (48 for halves to twelfths and 24ths; 40 for fifths and tenths; 42 for sevenths; 45 for ninths and
fifteenths; 44 for elevenths), 4 squares tall, 2 squares apart. Shaded pieces in the chapter colour, the second amount
striped. The bars' names (their fractions) at their right ends, the sign between them.

**The ruler** (shared): a handle above the first bar; dragging it sets one piece's length, snapping only to lengths that
divide the whole. While dragging: the piece's name over the ruler ("twelfths"), dashed cuts across every bar it cuts,
and under each bar a dot under each of its old cuts, green when a new cut lands on it, red when none does. **Cut**
commits: a miss says which old cut has no new cut; pieces that fit but could be bigger say "Those fit. Bigger pieces fit
too." Right: the cuts turn solid, every shaded piece gets its number, the names become the new fractions.

### Adding fractions (`add`)
1. **Cut** both bars with the ruler (answers the new bottom, and both rewrites: their boxes are set from the cut).
2. **Slide** the striped pieces up into the first bar: they snap in after its shaded pieces and the count runs on
   (A+1 … S). Dropped elsewhere: "Put them in the top bar." More than a whole: the pieces past the bar's end spill into
   a second whole bar under it.
3. **Write**: `a/b + c/d = A/L + C/L = [S]/L`; then, only when it can be simpler, `= [ ]` (a mixed number or a simpler
   fraction), and the answer bar's cuts change to the simplest pieces.
4. Say: "Same-size pieces, so the tops add."

### Subtracting fractions (`sub`)
As `add`, but step 2 **slides the striped pieces onto the first bar's shaded pieces from the right**: each one it covers
is crossed out; the count of what's left runs down. Say: "Same-size pieces, so the tops are taken away."

### Adding and subtracting (`mix`)
`add` or `sub` by the sign; the instruction for step 2 names it ("Slide them in to add" / "Slide them over to take
away").

### Mixed numbers to fractions (`g5-improper`)
Bars: `w` whole bars (all shaded) and one bar with `n` of `d` pieces shaded; names `1`, `1`, …, `n/d`; `w n/d` written
once as the column of names with a brace. 1. **Cut** the whole bars with the ruler to the extra bar's piece size (its
cuts are the old cuts). 2. The pieces number on across all the bars (See). 3. **Write** `w n/d = (w × d + n)/d = [ ]/d`.
Say: "Each whole is d pieces." Fit (review, 20 Oct): 1–3 wholes (the web's 1–6), the bars a square apart (only the
extra bar has old cuts, and their dots go under it) and the record 3 rows under the bars, so every problem is drawn at
full size: 3 wholes take 41 rows of the screen's 40 (99%), fewer are bigger; 6 took 64 (63%, the pieces' numbers 13 pt).

### Dividing by a unit fraction (`g5-unitdiv`)
`W` whole bars, and the `1/d` piece drawn alone above them, the size it really is. 1. **Cut** the first whole with the
ruler to that piece's size: "How many fit in one whole?" (sets `one`). 2. The other wholes are cut and every piece
counted (See). 3. **Write** `W ÷ 1/d = W × d = [ ]`. Say: "d pieces in every whole."

### Fraction of a number (`g5-fracof`)
One square (2 × 2 when there are 30 or fewer; 3 × 3 for 16 or fewer and 4 × 4 for 12 or fewer, so the bar is up to 48 squares like the fraction bars, 25 Oct) is one thing: `W` things in one bar. 1. **Cut** the bar into `d` equal
parts with the ruler (snapping to part sizes that divide `W`; the readout names the parts: "fourths, 5 in each"). 2.
**Tap** `n` parts to take them (skipped when `n` is 1). 3. **Write** `n/d of W = W ÷ d × n = [ ]`.

### Multiplying fractions (`g5-multfrac`)
A whole square, its side the smallest multiple of `lcm(b, d)` at least 24 squares. 1. A ruler down the left side
**cuts it into `b` rows**; **tap** `a` rows to shade them. 2. A ruler along the top **cuts it into `d` columns**; **tap**
`c` columns (striped). The pieces shaded twice are numbered. 3. **Write** `a/b × c/d = (a × c)/(b × d) = [ ]/[ ]`, then
simplify only when it can be. Say: "a × c of the b × d pieces are shaded twice."

### Converting units (`g5-units`)
One big unit is a bar 48 squares long (40 for 1000 and 100, cut in tens). Big to small: 1. **Cut** one bar into its
small units with the ruler ("12 inches"; for 60, 100, 1000 the cuts are tens with "10 cm" on each). 2. The other bars
cut and count (See). 3. **Write** `n big = n × f = [ ] small`. Small to big: the small units in one long bar; **hop** a
one-big-unit ruler along it, counting the big units and what's left. **Write** `n small = n ÷ f = [ ] big`. Units are
written the school way (ft, in, yd, m, cm, kg, g, h, min, gal, qt, lb, oz).

## Decimals family (lines that zoom, place columns, hundredths grids)

### Rounding decimals (`g5-round`) — the test page's design
Line 1: the tenth the number is in, ten blocks of a hundredth (50 squares), the number's point labelled over it.
1. **Tap** the block it's in: the block lights and opens below (dashed) into line 2, ten big steps of a thousandth.
2. **Drag** the point to the end it's closer to: the steps count under a bracket as it moves; release on an end.
   Wrong end: "That end is 6 steps away. The other end is 4." Halfway: "Exactly halfway rounds up."
3. **Write** `3.476 ≈ [ ]`; then the rule as record (the place digit underlined, the next ringed, "6 is 5 or more:
   round up"). Say: "6 steps from 3.47, 4 to 3.48. 3.48 is closer."
Core: the digit and next-digit steps are answered by the two moves; rounding to tenths uses numbers with two decimals
(so the point sits on a tick of line 2).

### Multiply by 10, 100, 1000 (`g5-pow10`)
Place columns a block wide, names over them (small), the point fixed on a strong line between ones and tenths; the
number's digits in their columns (36). 1. **Drag** the digits left together: they snap a column at a time, the readout
"× 10", "× 100", "× 1000". Release on `k` columns; too few or too many: "× 100 moves every digit 2 places." 2. **Tap**
each empty place between the digits and the point: a 0 is written there. 3. **Write** `x × 10^k = [ ]`. Say: "Each
zero moves every digit one place bigger."

### Adding decimals (`g5-adddec`)
The record leads the picture here, because lining up is the lesson: `a` over `b`, points on one strong line. 1. **Tap**
the empty hundredths place of `a`: a 0 is written ("12.5 is 12.50"). The part after each point is drawn beside its row
as a 10 × 10 grid of hundredths (a cell is 2 × 2 squares). 2. **Slide** `b`'s hundredths into `a`'s grid: they pour in,
column by column; a full grid overflows into a new one. 3. **Tap** the full grid: it closes into one whole and flies to
the ones column as the carried 1. 4. **Write** the total. Say: "Points under points, so tenths add to tenths."

### Multiplying decimals (`g5-multdec`)
A whole is a bold square 10 × 10 squares (a square is a hundredth), in every problem: decided 25 Oct 2026, so the
biggest problems still fit the screen (a 20 × 20 whole, two squares a hundredth, was the first design). The strip `x` by
`y` lies on wholes.
1. **Drag** the strip's corner to `x` across and `y` up (tenths snap to cells; wholes are bold): the readout counts
   the pieces it covers ("24 × 3 = 72 pieces"). 2. One piece is blown up beside it with its size (0.01, or 0.001 for
   hundredths × tenths). 3. **Write** `24 × 3 = [72]`, then **tap** where the point goes in 72 (between the digits; it
   counts the places from the right). Say: "Tenths times tenths are hundredths: 2 places."

### Dividing by a decimal (`g5-divdec`)
A number line from 0 to the dividend where one square is a tenth (a block is 0.5); a line of one or two wholes (the
smallest problems) is drawn 3 or 2 squares a tenth with a small tick at every tenth, so it isn't a sliver of the screen
(25 Oct). 1. **Hop** the divisor along it from
0 (tap to add a hop, or drag along: hops snap to the divisor's length), each hop numbered. Past the end: "That's past
4.8." 2. The same squares read in tenths under the line (0, 6, 12, … 48): `4.8 ÷ 0.6` is `48 ÷ 6`. 3. **Write**
`4.8 ÷ 0.6 = 48 ÷ 6 = [ ]`. Say: "The same hops in tenths: 48 ÷ 6."

## Whole numbers (area models in real squares)

### Multiply two-digit numbers (`g5-mult2`) — approved 19 Oct, now with a hand move
The rectangle `a` squares tall by `b` wide, every ten bold. 1. **Cut** across the top where the tens end (the cut snaps
to squares; the readout shows the two widths, "30 | 6"); wrong: "Cut where the tens end." The strips part a square.
2. **Write** each strip's product in the column working as it lights, then the total (the approved answered-in-the-work
layout). Say: "The two strips make 1692."

### Long division (`g5-divide`)
A rectangle `dv` squares tall whose width is found. 1. **Drag** its right edge: it snaps ten columns at a time; the
readout shows the area used and what's left ("840 used, 24 left"). Past the number: "That's more than 864." 2. **Drag**
the second strip's edge a column at a time until nothing is left. 3. **Write** the quotient over the bracket (the
partial quotients written for the child as the strips were found). Say: "12 rows of 72 make 864."

### Order of operations (`g5-order`)
The expression written once, big, as the record's first line. Under it the picture builds each part in squares (a
number is a row of squares; × makes rows; − crosses out; ÷ deals into rows). 1. **Tap** the part that goes first in the
line; wrong: "Brackets come first." / "× and ÷ before + and −." 2. Its squares build (See); **write** its result in the
next line, where school writes it. Repeat until one number is left. Say: "Brackets, then × and ÷, then + and −."

## Measurement (3D, from Unit cubes)

### Volume of a box (`g5-volume`)
Unit cubes with the problem's numbers: one cube is one block. 1. Flat: the floor's outline, its length and width beside
it; **tap or drag** across it to cover it, the squares counting. 2. The paper tilts and the floor rises into the first
layer; the box's full height dashed; **drag up** (or tap) to stack the layers, each counted on its front. 3. **Write**
`h layers of N = [ ]`; then the record `Volume = l × w × h = V cubic cm`. The paper lies flat before the next problem.
