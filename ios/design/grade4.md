# 4th grade on paper: every lesson's design

Claude, 1 Nov 2026, as 4th grade's lesson planner, in the language of `README.md` and the shape of `grade5.md`. It plans
the whole grade: every lesson a child needs to have covered Common Core Grade 4, in 8 chapters in teaching order, each
lesson designed for the paper. 35 lessons: the web's 19 (`web/src/curriculum/lessons/grade4`) and 16 new ones. For the
web's lessons the maths stays as it is (G, 20 Oct: the generator with its ranges and easy-first order, the derived
values, the slips, the check recipes, the stories; `specs/k12/grade4.md` has the check recipes and its wording fixes);
only the steps are new. A small gap is folded into a web lesson as one more kind of problem, and each fold says so.
Planning only: nothing here is built. Reviewed 1 Nov 2026 (coverage, sizes, maths, words); the fixes are in the
lessons themselves, and open question 5 is new.

Every lesson, as in 5th grade: what to do on rows 0–2 (28); a miss's words on rows 3–4 (20, red); the picture from row
6, its names at its right end (the iPad landscape screen is about 68 × 45 squares at 100%; the camera may step back for
big numbers, never past what a child can count); the record 3 rows under the picture; the blocks under the record. A step
answered by a hand move sets its Core boxes from the move (`LessonRun.set`), so Core's checks and slips stay; steps the
hands make pointless are dropped. The first words never repeat the problem; the last words say why. Show me and the How
to play the move with the ghost finger and put everything back.

## Standards and lessons

Grade 4 is 4.OA (5 standards), 4.NBT (6), 4.NF (7), 4.MD (7) and 4.G (3). **web** = the web app has the lesson (its
maths kept); **new** = added here; **+** = a gap folded into that web lesson.

| Standard | What it asks | Lesson |
|---|---|---|
| 4.OA.1 | read 35 = 5 × 7 as "35 is 5 times as many as 7" | Times as many `g4-times` · new |
| 4.OA.2 | times-as-many stories, × or ÷, told apart from "more than" | Times as many `g4-times` · new |
| 4.OA.3 | stories in steps, a letter for the unknown, a rounded estimate; remainders that need thought | Story problems in steps `g4-multistep` · new; Dividing with remainders `g4-divide` · web + what the remainder means |
| 4.OA.4 | factor pairs to 100, multiples, prime or composite | Factors and multiples `g4-factors` · web; Prime or composite `g4-prime` · new |
| 4.OA.5 | make a pattern from a rule; see what the rule didn't say | Number and shape patterns `g4-patterns` · new |
| 4.NBT.1 | a place is ten times the place to its right | Tens, hundreds, thousands `g4-tentimes` · new |
| 4.NBT.2 | numerals, number names, expanded form; compare with <, =, > | Reading and writing big numbers `g4-readwrite` · new; Comparing big numbers `g4-compare` · new |
| 4.NBT.3 | round to any place | Place value and rounding `g4-placevalue` · web |
| 4.NBT.4 | add and subtract the standard way | Add and subtract big numbers `g4-addsub` · web |
| 4.NBT.5 | up to 4 digits × 1 digit; 2 digits × 2 digits | Multiply big numbers `g4-partial` · web + four-digit numbers; Two-digit times two-digit `g4-mult2x2` · web |
| 4.NBT.6 | ÷ by one digit, up to four-digit numbers, remainders | Dividing with remainders `g4-divide` · web; Dividing big numbers `g4-share` · new |
| 4.NF.1 | equivalent fractions | Equivalent fractions `g4-equiv` · web |
| 4.NF.2 | compare fractions with different bottoms | Comparing fractions `g4-fraccompare` · web |
| 4.NF.3a | adding joins pieces, subtracting takes them away | Adding like fractions `g4-likefrac` · web; Subtracting like fractions `g4-likesub` · new |
| 4.NF.3b | break a fraction into a sum, more than one way | Breaking fractions apart `g4-decompose` · new |
| 4.NF.3c | add and subtract mixed numbers | Adding mixed numbers `g4-mixed` · web; Subtracting mixed numbers `g4-mixedsub` · new |
| 4.NF.3d | stories with like bottoms | the stories in Adding like fractions, Subtracting like fractions, Adding mixed numbers and Subtracting mixed numbers |
| 4.NF.4a | a/b is a × 1/b | Breaking fractions apart `g4-decompose` · new; Fraction times a whole number `g4-fracwhole` · web + the 6 × 1/5 line |
| 4.NF.4b, c | n × a/b, and its stories | Fraction times a whole number `g4-fracwhole` · web |
| 4.NF.5 | tenths as hundredths, and adding them | Tenths and hundredths `g4-dec` · web |
| 4.NF.6 | decimals for tenths and hundredths, on a number line | Tenths and hundredths `g4-dec` · web; Decimals on a number line `g4-decline` · new |
| 4.NF.7 | compare decimals to hundredths | Comparing decimals `g4-deccompare` · web |
| 4.MD.1 | unit sizes, big unit to small, a two-column table | Converting measurements `g4-convert` · web + the table and km, kg, L, mL, s |
| 4.MD.2 | stories about time, money, liquids, mass and distance on a measuring line | Measurement story problems `g4-measure` · new |
| 4.MD.3 | area and perimeter, and a missing side | Area and perimeter `g4-area` · web + the missing side |
| 4.MD.4 | make a line plot in halves, fourths and eighths, and use it | Line plots with fractions `g4-lineplot` · web + making the plot |
| 4.MD.5 | an angle is a turn; a degree is 1/360 of a turn | Angles and degrees `g4-turns` · new |
| 4.MD.6 | measure and draw angles with a protractor | Measuring angles `g4-protractor` · new |
| 4.MD.7 | angles add up | Angles add up `g4-angles` · web + any whole |
| 4.G.1 | draw and name points, lines, rays, segments, angles, perpendicular and parallel lines | Points, lines, rays and angles `g4-lines` · web + drawing them |
| 4.G.2 | sort shapes by parallel sides, square corners and angle sizes; right triangles | Sorting by sides and angles `g4-classify` · new |
| 4.G.3 | lines of symmetry: find them and draw them | Lines of symmetry `g4-symmetry` · web + drawing the fold lines |

**The edges** (checked against `grade3.md` and `grade5.md` as they stand on 1 Nov). 3rd grade has rounding to 10 and
100, adding within 1000 a place at a time with disks, two-step stories with a letter and an estimate to check, unit
fractions, equal fractions on a line, comparing with a same top or bottom, area and perimeter by counting (a missing
side found by counting round), elapsed time in a day, grams, kilograms and liters, line plots in halves and fourths the
child makes, and naming quadrilaterals; it leaves the column way, rounding to any place, the area and perimeter
formulas, g to kg, and eighths on line plots to 4th grade. 5th grade keeps the standard way to multiply (one cut, two
strips), long division by two digits, decimals to thousandths, fractions as division, unlike bottoms, mixed numbers to
one fraction (`g5-improper`), converting both ways, volume, points on a grid, the quadrilateral family, patterns with
two rules, line plots in eighths added up, and writing expressions. So here: like bottoms only; 2 1/8 is written 8/8 +
8/8 + 1/8 and stops there; converting goes big to small only; line plots give differences, totals and counts; shapes are
sorted by their sides and angles, not into families; a pattern has one rule.

## Chapters

In teaching order, each with its chapter test as now. Colours by family (open question 2): the three whole-number
chapters take Whole numbers' colour, the two fraction chapters Fractions', then Decimals' and Measurement's, and Lines
and shapes the teal planned for 5th grade's new Geometry chapter.

1. **Big numbers** (5): Tens, hundreds, thousands · Reading and writing big numbers · Comparing big numbers · Place value
   and rounding · Add and subtract big numbers
2. **Multiplying and dividing** (6): Times as many · Multiply big numbers · Two-digit times two-digit · Dividing with
   remainders · Dividing big numbers · Story problems in steps
3. **Factors and patterns** (3): Factors and multiples · Prime or composite · Number and shape patterns
4. **Fractions** (5): Breaking fractions apart · Equivalent fractions · Comparing fractions · Adding like fractions ·
   Subtracting like fractions
5. **Mixed numbers** (3): Adding mixed numbers · Subtracting mixed numbers · Fraction times a whole number
6. **Decimals** (3): Tenths and hundredths · Decimals on a number line · Comparing decimals
7. **Measurement** (4): Converting measurements · Measurement story problems · Area and perimeter · Line plots with
   fractions
8. **Lines and shapes** (6): Points, lines, rays and angles · Angles and degrees · Measuring angles · Angles add up ·
   Sorting by sides and angles · Lines of symmetry

## Hand moves this grade adds

The kit (`README.md`'s table) covers most steps: the ruler, sliding pieces, tapping pieces, a block that opens, dragging
a point, hops, a rectangle's edge or corner, tapping the part, writing. Five more are already planned by the next
grade down or up, and 4th grade uses them as they are, so a child meets one move across grades: **tap the full ten**
(5th grade's Adding decimals closes a full grid into a whole this way, and 3rd grade's plan a full ten-frame into one of
the next place; here also a full bar closing into a whole), **open a ten** (3rd grade's plan: tap one, it opens into ten
of the next place down; here also a whole bar opening into its pieces), **place an X** (3rd grade's plan, line plots)
and **trace the edge** (3rd grade's plan, Perimeter), with 3rd grade's **turn a clock hand** for the clock in Angles and
degrees. These are new to 4th grade, each built once and shown to G with the first lesson that uses it:

| Move | What it does | Used by |
|---|---|---|
| Deal into rows | drag a place's disks down: they go one to each row, round after round; the readout says each row's share and what's left | divide, share |
| Drag out copies | drag a row's or a bar's end: it repeats a whole copy at a time ("× 3") | times, partial, multistep, patterns |
| Pull a digit down | drag a digit out of the place chart: zeros follow it from every place to its right, and it lands in the record as its value | readwrite |
| Split at a joint | tap the line between two shaded pieces: they part a little, and each part is named | decompose |
| Turn an arm | drag an angle's free arm round its corner: it snaps to whole degrees (or fives, where the problem says), the arc between the arms shading and counting | turns, protractor, lines |
| Lay a tool on a corner | drag the page corner or the protractor onto a corner: it snaps only with its point on the corner and an edge along an arm, then says what it finds ("fits exactly") | lines, protractor, angles, classify |
| Run a line on | drag an arrowhead: the line goes on across the paper; tap an end to make it a dot or an arrowhead | lines |
| Fold on a line (3D) | drag half a shape over a line, or draw the line and let go: the half lifts, turns over and lands; corners that meet corners get a dot | symmetry |
| Sort into loops | drag a shape into a two-loop diagram drawn on the paper: one loop, the other, both, or neither | classify |
| Tap a choice | blocks on the paper holding the web's choices (< = >; Yes, No; Line, Ray, Segment; Prime, Composite; Odd, Even) | compare, fraccompare, deccompare, factors, prime, patterns, lines, symmetry |

## 1. Big numbers (whole numbers' colour)

**The place chart** (this chapter and the next): 3rd grade's chart of disks in ten-frames, made small enough to hold six
places. A column for each place, 10 squares (two blocks) wide, on the strong lines, its name over it (small; "ten
thousands" on two lines). Six columns, hundred thousands to ones, make 60 squares; a lesson draws only the columns it
needs. A disk is a dot in a 1-square cell, in the chapter colour, and it is one of its column's place: a disk in the
hundreds is a hundred (too small to write its worth on, so the column's name says it). Disks fill ten-frames, 2 rows of
5, a block wide (3rd grade's frames in smaller cells), two frames side by side in a column, so a full frame is ten of
that place: **tap the full ten** and it closes into one disk that slides into the column to its left; **open a ten**
(tap a disk) and it opens into a full frame in the column to its right. Where a lesson writes a number's digits under
its disks, they are 36, one per column, centred, the comma under the line between the thousands and the hundreds. A
second number's disks are striped. **Bigger when it fits:** a problem that needs three columns or fewer, and whose
disks fit, draws its cells 2 × 2 squares (a column 20 squares, the chart 60), so a small chart still fills the screen
(Multiply big numbers' three-digit problems, the first problems of Tens, hundreds, thousands); four columns or more, or
a column that must hold more than four frames, stay at 1-square cells. A tall chart keeps its record beside it, a block
to its right (3rd grade's rule).

### Tens, hundreds, thousands (`g4-tentimes`) · 4.NBT.1 · new
**Square:** a disk, one of its place. **Picture:** the place chart with the three or four columns the problem needs
(30–40 squares), the number's disks in it, named at its right end. Two kinds of problem take turns.
- **How many tens make 340?** (3 hundred disks, 4 ten disks.) 1. **Open** each hundred: it opens into a full frame of
  ten tens, and the tens count up, "14 tens", "24 tens", "34 tens". A ten tapped: "Count tens: open the hundreds." 2.
  **Write** `340 = [34] tens`. Slips: 4 ("The 3 hundreds are 30 tens more."), 3 ("That's the hundreds."), 340 ("That's
  ones.").
- **What number is 52 hundreds?** (52 disks in the hundreds: 5 full frames and 2.) 1. **Tap each full ten**: the frame
  closes into a thousand and slides left, "5 thousands". 2. **Write** `52 hundreds = [5,200]`, the empty tens and ones
  written as zeros. Slips: 52 ("That's how many hundreds. Write the number."), 520 ("That's 52 tens."), 52,000 ("That's
  52 thousands.").

**The How to starts in real squares,** so a disk's worth is seen before it's trusted: one square is one, a ten is a
strip of 10 squares, a hundred a 10 × 10 flat. The ruler cuts a flat into its 10 strips ("10 tens"); then ten flats
stack up off the paper into a thousand cube (3D, Unit cubes' tilt; flat again after), "10 hundreds". Each one then
shrinks into its disk in the chart, and the problems use disks (52 hundreds as flats would be 5,200 squares).
**See:** ten disks close into one, or one opens into ten, where they stand. **Record:** `340 = 34 tens = 34 × 10`;
`52 hundreds = 5 thousands and 2 hundreds = 5,200`. **Say:** "A hundred is ten tens." / "Ten hundreds make a thousand."
**Core (new):** a count c and a place p (10, 100 or 1,000); kind A asks how many p's make c × p, kind B what number c p's
make; A and B take turns. Index < 3: p = 10, c 11–39; then p 100 or 1,000, c 11–99; now and then c is a whole ten (300
is 30 tens). Check: i0 (A); i1 (B); i4 (A, hundreds); i5 (B, thousands). After g3-mult10, g3-addsub.

### Reading and writing big numbers (`g4-readwrite`) · 4.NBT.2 · new
**Square:** a disk. **Picture:** the whole place chart (60 squares); the number's name over it as its title (28), or its
digits under its disks. Two kinds take turns.
- **Name to number** ("forty thousand, six hundred five"): 1. **Tap disks in** (the kit's tap: tap a column, or drag
  along it, and a disk goes in; tap a disk to take it out). Live: the number built, in digits in the pill and in words
  under the chart, a 0 in each empty place inside it. **Check.** Wrong: "That reads four thousand, six hundred five.
  Forty thousand is 4 ten thousands." **Record:** `forty thousand, six hundred five = 40,605`. **Say:** "An empty place
  still needs its 0."
- **Number to expanded form** (305,280 under its disks): 1. **Pull each digit down**: zeros follow it from every place
  to its right, and it lands in the record as `300,000`; live "3 hundred thousands". A 0 won't come: "0 ten thousands is
  nothing. Leave it." The parts line up in place order. **Record:** `305,280 = 300,000 + 5,000 + 200 + 80`. **Say:**
  "Each digit is worth its place."

**Core (new):** N 1,000–999,999. Index < 3: four digits, no 0 inside; then five and six digits, a 0 inside half the time
(40,605: the traps are 4,605 and 400,605). Names the US way: no "and", hyphens from twenty-one to ninety-nine, a comma
after "thousand". The build answers kind A (N), the pulls kind B (each digit's value). Check: A with a 0 inside; B with
six digits; A with six digits; B with a 0 inside. After g4-tentimes.

### Comparing big numbers (`g4-compare`) · 4.NBT.2 · new
**Square:** a disk. **Picture:** the place chart with as many columns as the longer number; the first number's disks and
digits on top, the second's (striped) under them, each named at the chart's right; the sign blocks in the record under
the chart, between the two numbers (six columns are 60 squares, so nothing more fits beside them).
1. Only when the lengths differ: the second number starts written under the first's first digit, as children write it.
   **Slide** it right, a column at a time, until ones are under ones; its disks draw in. Let go short: "The 6 is under the
   tens. Ones go under ones."
2. **Tap the first place that differs**, from the left: it lights, "5 ten thousands and 4 ten thousands". Further
   right: "The ten thousands differ first: 5 and 4." A place with the same digits: "Both have 2 thousands. Look further
   right."
3. **Tap a choice** (< = >). Slips: compared the first digits ("12,345 has a ten thousand. 9,876 has none."), turned it
   around ("52,318 is bigger: 52,318 > 49,876."), called them equal.

**Record:** `52,318 > 49,876`. **Say:** "The first place that differs decides."
**Core (new):** two numbers 1,000–999,999: (a) the same length, differing in the first place; (b) the same length and
first digits, differing in a middle place; (c) different lengths, the shorter with the bigger first digit; (d) equal,
now and then. Index < 3: (a) with four digits; then all of them, with five and six digits. Check: (a); (b); (c); (c) with
six digits. After g4-readwrite.

### Place value and rounding (`g4-placevalue`) · 4.NBT.3 · web
Rounding decimals' two lines, as 3rd grade's Rounding to 10 and 100 uses them, with bigger numbers. **Square:** on line
1 a block (5 squares) is one of the place (a thousand); on line 2 a block is a tenth of it (a hundred). **Picture:** line
1 at row 6, 50 squares, ten blocks of the place, from the round number of the next place up (40,000) to the one after
(50,000), named at its ends; the point at n with `47,382` over it (the problem, written once). Line 2 a dozen rows under
it.
1. **Tap the block** the point is in: it lights and opens below (dashed) into line 2, ten blocks of a hundred from 47,000
   to 48,000, the halfway tick long and named `47,500` (small). Wrong block: it lights red, "47,382 is between 47,000
   and 48,000." Sets the place's digit and the round numbers on either side.
2. **Drag the point** to the end it's closer to; as it moves a bracket shows how far it is to each end ("382 to 47,000 ·
   618 to 48,000"). Wrong end: "That end is 618 away. The other end is 382." Exactly halfway: "Exactly halfway rounds
   up." Sets the next digit.
3. **Write** `47,382 ≈ [47,000]`.

**Record:** `47,382 ≈ 47,000`, then the rule: the 7 underlined, the 3 ringed, "3 is less than 5: round down". **Say:**
"382 to 47,000, 618 to 48,000. 47,000 is closer."
**Core:** the web's maths: index < 3 four digits to the nearest 10 or 100; < 6 five digits to 100, 1,000 or 10,000; then
six digits to 1,000, 10,000 or 100,000; a next digit of 0 mostly avoided. The point keeps all its digits, so on line 2
it can sit between ticks (as 3rd grade's hundreds do), and the bracket says how far in ones. Slips kept (one place too
far right or left, dropped the zeros, used the wrong place, read the place itself, rounded the wrong way, kept the
digits after the place, rounded to the wrong place). Check: i3 rounding down; i3 rounding up; i6 with a next digit of 5;
i6.

### Add and subtract big numbers (`g4-addsub`) · 4.NBT.4 · web
**Square:** a disk. **Picture:** the place chart, five columns (50 squares; a sixth draws in when the ten thousands make
ten); the first number's disks in the top band of frames, the second number's (striped) in a band under them, a square
apart; each named at the chart's right end (`46,372`, `+ 28,519`).
Adding, a column at a time from the ones (the web's steps: ones, tens, hundreds, then the rest together):
1. **Slide** the striped ones up: they snap in after the top's, filling its frame and spilling into the frame beside it,
   the count running on ("…, 10, 11").
2. Ten or more: **tap the full ten**; it closes into one disk and slides into the tens as the carried 1, written small
   over the tens in the record, and the 1 left is written under the ones. Sliding the tens first: "11 ones: tap the
   full ten first."
3. The tens, then the hundreds, the same way.
4. **Slide** the rest in together (closing a ten if the thousands make one), then **write**
   `46,372 + 28,519 = [74,891]`.

Subtracting: the striped disks slide onto the top's from the right and cross them out; what's left counts down. Too few on
top: the slide stops, red: "7 ones can't take away 9. Open a ten." **Open a ten** (tap a disk in the next column): it
opens into a full frame of ones; in the record the tens digit is crossed out and written one less, and a small 1 goes
before the ones. Opening one when there are enough: "There are enough ones. Take away first."
**Record:** the column working as school writes it, the carries and trades small, filled in column by column; the answer
typed. **Say:** "Ten in one place make 1 in the next."
**Core:** the web's maths: index < 4 four digits, then five; adding or subtracting at random, always one carry or trade,
never a trade across a 0, a difference of 1,000 or more. Each column's step is answered by its slide and its closed or
opened ten; the answer is typed. 3rd grade worked a place at a time from the biggest, with disks that say their worth;
this is the column way, ones first. Slips kept (forgot the carried 1, wrote only the digit, took the smaller from the
bigger, forgot the ten you traded, forgot to carry, forgot to cross out, forgot the traded thousand). Stories: the
library's books, the stadium's seats. Check: i0 subtracting; i4 adding; i4 subtracting; i4 story.

## 2. Multiplying and dividing (whole numbers' colour)

Times as many and Two-digit times two-digit count real squares, one square one thing, every ten bold (5th grade's
Multiply two-digit numbers). Multiply big numbers, Dividing with remainders and Dividing big numbers use the place chart:
the number's row copied for ×, its disks dealt into rows for ÷, so each column becomes an array of its place. (A
rectangle a square a sticker, as 5th grade's Long division draws it, would be up to 99 squares wide and 3 to 9 tall
here: a thin strip seen at 65%. The deal fits at full size.)

### Times as many (`g4-times`) · 4.OA.1, 4.OA.2 · new
**Square:** one (a centimeter of ribbon, a sticker, a kilogram). **Picture:** two bars 4 squares tall, 2 apart, starting
on the same strong line: Red (2–9 squares) named at its right end (`4 cm`), Blue under it, dashed until found (`?`).
- **Find the big one** ("Make Blue 3 times as long as Red."): 1. **Drag out copies**: Blue grows a copy of Red at a
  time, each outlined and numbered; live "3 × 4 = 12". Let go at 2: "That's 2 times as long. Blue needs 3 copies of
  Red." 2. **Write** `Blue = 3 × 4 = [12]`, and under it "12 is 3 times as many as 4."
- **Find the small one** ("Blue is 3 times as long as Red. Find Red."): 1. **Cut** Blue with the ruler into equal parts
  (it snaps to sizes that divide Blue; live "3 parts of 4"). Wrong: "That's 4 parts. Blue is 3 times Red: 3 parts." The
  first part slides up into Red. 2. **Write** `12 = 3 × r`, `r = 12 ÷ 3 = [4]`.
- **How many times?** 1. **Hop** Red along Blue (each hop snaps to Red's length; they count). Past the end: "That's past
  12." 2. **Write** `12 = [3] × 4`.
- **Longer, or times?** (later; the words say "8 cm longer" or "3 times as long"): Blue starts as a copy of Red;
  **drag** its end a square at a time, live "Red + 8 = 12" and, at whole copies, "3 × Red". Copies for "longer": "That's
  3 times Red. 8 longer adds 8 squares." Squares for "times": "3 times as long makes 3 copies."

**Record:** the kind's line: `Blue = 3 × 4 = 12` and "12 is 3 times as many as 4."; `r = 12 ÷ 3 = 4`; `12 = 3 × 4`;
`Blue = 4 + 8 = 12`.
**Say:** "3 copies of Red make Blue." / "Blue is 3 Reds, so Red is a third of it." / "Red fits in Blue 3 times." /
"Longer adds on; times makes copies."
**Core (new):** Red 2–9; times 2–6 with Blue up to 30 for index < 3, then 2–9 with Blue up to 60. The first three find
the big one, the small one, then how many times; after that the four kinds take turns. "Longer" adds 3–12 and is never a
problem where Red + k equals k × Red. Slips: added for times, made copies for longer, took away for ÷ (12 − 3), a copy
short or over. Stories: ribbons, stickers, a dog and a cat, a plant, prices. Check: the big one; the small one; how many
times; longer or times, as a story. After g3-facts, g3-divfacts.

### Multiply big numbers (`g4-partial`) · 4.NBT.5 · web + four-digit numbers
**Square:** a disk. **Picture:** the place chart with the number's columns (three, or four for the fold: 30–40 squares),
its disks in one plain row across the top (here a row is one copy, not a frame), named at the right (`346`), a handle
under the row.
1. **Drag out copies**: the row copies downward a row at a time, the rows touching, live "× 2", "× 3", …; let go at m
   (`× 7`, braced). Each column is now an array: 7 rows of 3 hundreds, of 4 tens, of 6 ones. Let go at 5: "That's 5 rows.
   346 × 7 needs 7."
2. The hundreds light, their count drawn under them ("7 × 3 = 21 hundreds"); **write** `300 × 7 = [2,100]`. Slip 21:
   "That's 3 × 7. The 3 stands for 300, so put two zeros on the end."
3. The tens: "28 tens", `40 × 7 = [280]` (a 0 digit leaves the column empty: "There are no tens, so this part is 0.").
4. The ones: "42 ones", `6 × 7 = [42]` (slip 13: "This one is times, not plus.").
5. **Write** `2,100 + 280 + 42 = [2,422]` (slip: the two biggest parts only, "Add all three parts.").

**Record:** the parts in a column, then their sum. **Say:** "7 rows of every place make 2,422."
**Core:** the web's maths: index < 3 n 112–399 and m 2–5, then n 112–989 and m 3–9, never a whole number of hundreds;
slips kept. **Fold** (4.NBT.5's four digits): from index 6, now and then n 1,012–9,989 (never whole thousands or
hundreds) with m 3–9, and a thousands step first (`4,000 × 7 = [28,000]`). Story: crayons in boxes. Check: i6 (four
digits); i3 where the tens digit is 0; i3 where m ≥ 6; i3 story (the spec's first i3 becomes i6 so the check reaches
the fold).

### Two-digit times two-digit (`g4-mult2x2`) · 4.NBT.5 · web
5th grade's rectangle, cut both ways. **Square:** one (a seat, in the story), every ten bold, so each bold 10 × 10 is a
hundred. **Picture:** the rectangle with the bigger number across and the smaller down (here 34 × 26: 34 across, 26
down), the across number over its top, the down number beside its left side. The first problems (up to 29 × 19) are seen
at full size; the biggest (99 × 49) make the camera step back to about 60% and the words grow by whole steps, as in
5th grade (open question 4).
1. **Cut** down where the across number's tens end: the handle on its stem over the top edge, live "30 | 4". Wrong: "Cut
   where the tens end."
2. **Cut** across where the down number's tens end: a handle beside the left side, live "20 | 6". The four parts part a
   square.
3. The parts light in turn, tens × tens first, their bold hundreds and ten-strips countable ("6 hundreds"); **write**
   each: `30 × 20 = [600]`, `30 × 6 = [180]`, `4 × 20 = [80]`, `4 × 6 = [24]`.
4. **Write** `600 + 180 + 80 + 24 = [884]`.

**Record:** the four parts in a column under the problem, then `34 × 26 = 884`. **Say:** "Four parts fill the
rectangle: 884."
**Core:** the web's maths: index < 3 a 11–29 and b 11–19, then a 12–99 and b 12–49, never a whole ten; the cuts answer
the split. Slips kept (lost a zero, left off the zeros, lost the place value, added, a fact slip, a group short or over,
only the corners, left out a part). Story: a theater's a rows of b seats. Check: i0; i3; i3 where both ones digits are 5
or more; i3 story. Not 5th grade's: that one cuts once, into the two strips of the standard way.

### Dividing with remainders (`g4-divide`) · 4.NBT.6, 4.OA.3 · web + what the remainder means
Sharing disks out, a place at a time; Dividing big numbers does the same with bigger numbers. **Square:** a disk, one of
its place (1-square cells: after the hundreds open, up to 89 tens wait in their frames). **Picture:** the place chart,
hundreds to ones (30 squares; tens and ones when the number has no hundreds), the number's disks in frames on top, named
at the right (`75`); under them dv rows, dashed, numbered down the left (a row is a friend), braced `÷ 4` at the right.
A row's share sits in a plain row, so each column's shares make an array. The record beside it, a block to the right.
1. Hundreds, when there are some (there are always fewer than dv): **open** them, each into a frame of ten tens, "34
   tens". Dealing them: "3 hundreds can't go to 4 rows. Open them."
2. **Deal** the tens: drag them down; they go one to each row, round after round, live "1 each · 3 left". Too many
   rounds: the deal stops, red: "Only 3 tens left: not enough for 4 rows." Let go too soon: "4 tens left: enough for
   another round." Sets the tens (10 each, so `4 × 10 = 40` is taken away).
3. **Open** the tens left: they open into ones and join the 5 there, "35 ones". Sets what's left.
4. **Deal** the ones: "8 each · 3 left", the same misses. Sets the ones.
5. **See:** the 3 left stay on top, too few for a round, outlined dashed. **Write** `75 ÷ 4 = [18] R [3]`, read across
   one row: a ten and 8 ones. Slips kept: 9 ("Each row has a ten and 8 ones: 18."), a remainder of 4 or more ("7 left
   is enough for another round of 4.").

**Record:** `75` in its bracket by `4`; `40` taken away with `10` beside it, `35`; `32` taken away with `8` beside it,
`3`; `18 R 3` over the bracket (the take-aways written for the child as the deals are made). **Say:** "3 is less than 4,
so 3 are left over."
**Core:** the web's maths: dv 3–9, q 12–99 never a whole ten, r 0 to dv − 1 (the index is ignored; the check's `where`s
do the work); the deals answer the tens, take-away and ones steps; the answer is typed; slips kept. **Fold** (4.OA.3's
remainders): later story problems ask one of four things, and a last step writes the story's answer: each friend's
share (a row: 18), what's left (3), how many full bags of 4 (every round of ones fills one bag, every round of tens ten:
18), how many bags are needed (the 3 left need one too: 19). Slips: "18 bags hold 72. The 3 left need a bag too." /
"Each friend gets 18. The 3 left aren't shared." Check: i0 where r = 0; i0 where r > 0 and q ≥ 20; i0 where r > 0; i0
story (any of the four questions).

### Dividing big numbers (`g4-share`) · 4.NBT.6 · new
Dividing with remainders' deal, with thousands, a three-digit share and zeros in it. **Square:** a disk. **Picture:** the
place chart (thousands to ones, 40 squares);
the number's disks in frames on top, named at the right (`4,325`); under them dv rows, dashed, numbered at the left,
braced `÷ 5` at the right; a row's share sits in a plain row, so the rows make arrays as in Multiply big numbers.
From the biggest place down:
1. **Deal** the thousands: there aren't enough to go round: "4 thousands can't go to 5 rows. Open them." **Open** them:
   each opens into a full frame of hundreds, "43 hundreds".
2. **Deal** the hundreds, round after round; live "8 each · 3 left". Too many rounds: "Only 3 hundreds left: not enough
   for 5 rows." Too few: "8 left: enough for another round."
3. **Open** the 3 left: "32 tens". **Deal**: "6 each · 2 left". **Open**: "25 ones". **Deal**: "5 each · 0 left".
4. **Write** `4,325 ÷ 5 = [865]` (and `R [ ]` when some are left), read across one row.

A place that can't go round in the middle (832 ÷ 4, at the tens): "3 tens can't go to 4 rows: that's 0 tens each. Open
them." **Record:** the long division as school writes it, each place's digit over it as it's dealt, each take-away and
bring-down under it. **Say:** "Share the biggest place first, then open what's left."
**Core (new, built from g4-divide's):** dv 3–9, q 100–999, r 0 to dv − 1, n = dv × q + r up to 9,999. Index < 3:
three-digit n with its first digit at least dv and no 0 in q; then four-digit n whose first digit is under dv (opened
first), with a 0 in q now and then. Each deal sets its place's digit, each opening what moves down; the answer is typed.
Slips: a 0 left out of the answer (28 for 208: "4 can't go into 3 tens: write 0 tens."), a remainder of dv or more,
the opened ones forgotten ("The 3 hundreds left are 30 tens more."). Story: seeds shared by gardens. Check: i0; i3 where
q has a 0; i6 (four digits, opened first); i6 story. After g4-divide, g4-tentimes.

### Story problems in steps (`g4-multistep`) · 4.OA.3 · new
3rd grade's Estimate to check rounds to hundreds and hops; here the rounding builds the picture itself. **Square:** ten.
Every amount's bar is drawn to the nearest ten, so the picture is the estimate. **Picture:** the story's
bar model, 3 squares tall, up to 60 long, each part named with its exact amount: groups (a parts of b) with a part taken
off the end (the dashed rest is n); groups with a part joined on (n is the whole); or a part taken off and the rest cut
into b equal parts (n is one part).
1. **Round** each amount: drag its bar's end to the nearest ten (live "125 → 130"; a group's copies follow it). Wrong:
   "186 is nearer 190 than 180." In the sharing kind the ruler then cuts the rest into b equal parts, snapping to whole
   squares ("6 parts of about 50").
2. **See:** n's bar has a length now; the record writes the story as an equation with a letter, `4 × 125 − 186 = n`,
   and the estimate, `about 520 − 190 = 330`.
3. **Write** the first step `4 × 125 = [500]`. 4. **Write** the second `500 − 186 = [314]`; a mark at 314 lands on n's
   bar, near its end.

**Record:** `4 × 125 − 186 = n`, `about 520 − 190 = 330`, `4 × 125 = 500`, `500 − 186 = 314`, `n = 314`. **Say:**
"314 is close to 330, so it makes sense."
**Core (new):** g3-twostep's three kinds with 4th grade numbers: groups then take away (a × b − c), groups then more
(a × b + c), take away then share ((a − c) ÷ b). Index < 3: the first two, a 3–5, b 12–95, c 15–95; then all three, b
105–195 with a 2–4 (a × b up to 600), c up to a × b − 100 when it's taken away, and a × b + c at most 600 when it's
joined on (the bar stays 60 squares); sharing: a 200–600, b 3–9, a − c a multiple of b. No amount
is a whole ten (so rounding means something). The estimate is a step, answered by the drags; the two written steps keep
g3-twostep's slips (added for taken away, took c from each group, the wrong order). Every problem is a story with n
(crates of apples, packs of stickers, rows of seats, boxes of cookies). Check: one of each kind, and groups of a
three-digit number. After g3-twostep, g3-estimate, g4-partial, g4-divide, g4-placevalue.

## 3. Factors and patterns (whole numbers' colour)

### Factors and multiples (`g4-factors`) · 4.OA.4 · web
**Square:** one. **Picture:** n squares (12–60) in one long row, named `1 × 20` at its end (the first pair), and under it
the same squares to arrange.
1. **Drag** the bottom edge down: the squares flow into that many rows, live "2 rows of 10" or "3 rows of 6, 2 over".
   Let go on the next rectangle (pair 1, then pair 2); each one found stays, named `2 × 10`. On leftovers: "3 rows leave
   2 over: not a rectangle." Past one: "4 rows make one too, but there's one with fewer rows."
2. **Hop** by t (3) along the long row: the hops count "3, 6, … 18, 21". **Tap a choice**: is 20 a multiple of 3? Slips
   kept: "Count by 3s: 18, then 21. You skip over 20, with 2 left." / "Count by 4s: you land right on 20."
3. **Write** `factors of 20 = [6]`, the factors listed under the rectangles.

**Record:** `20 = 1 × 20 = 2 × 10 = 4 × 5`; `1, 2, 4, 5, 10, 20`; `20 = 3 × 6 + 2`. **Say:** "Each rectangle is a
factor pair."
**Core:** the web's maths: n from the numbers 12–60 with exactly three factor pairs (up to 32 for index < 3), t 3–9 not
in a pair and at most n ÷ 2, a factor half the time; the drags answer the pair steps, the tap the multiple step. Slips
kept (subtracted, used the same number, missed a multiple, not a multiple, counted pairs, counted a square's factor
twice, left out 1 and n). Check: i0 where t is a factor; i3 where it isn't; i0 where n = 16; i3 where n > 32.

### Prime or composite (`g4-prime`) · 4.OA.4 · new
**Square:** one. **Picture:** n squares (2–100) set out in rows of ten, named n.
1. **Drag** the bottom edge down to try 2 rows, 3 rows, …: the squares flow into that many rows as the finger goes,
   leftovers dashed ("4 rows of 12, 3 over"). Let go on a full rectangle: it turns green and its pair is written in the
   record (`51 = 3 × 17`), and the squares wait for the next try (only the rectangle being tried is drawn, so 96's five
   pairs never crowd the screen). The tries stop once the rows would outnumber a row's squares: "From here, any
   rectangle is one you've found, turned round."
2. **Tap a choice**: Prime or Composite. Slips: 51 called prime because it's odd ("51 makes 3 rows of 17. More than one
   rectangle: composite."), 2 called composite because it's even ("2 makes only one rectangle, 1 × 2. Prime."), a prime
   called composite ("Only 1 row made a rectangle. Prime.").

**Record:** every pair, `51 = 1 × 51 = 3 × 17`, then "composite"; or `29 = 1 × 29`, "prime". **Say:** "Only one
rectangle: prime." / "More than one rectangle: composite."
**Core (new):** n 2–100, never 1 (it's neither), a prime half the time; now and then a composite with no factor 2 or 5
(51, 57, 87, 91: they look prime), and some with many pairs (60, 72, 84, 90, 96, every pair found). Index < 3: n up to
30. The tries run while the rows are no more than a row's squares (to the square root); the drags set every pair, the tap
the answer. Check: a prime up to 30; a composite with no factor 2 or 5; a prime over 50; a composite with four or more
pairs. After g4-factors.

### Number and shape patterns (`g4-patterns`) · 4.OA.5 · new
**Square:** one: on the number line a square is 1; in a shape, a square is a square.
- **A number rule** ("Start at 1. Add 3."): a number line one square a one, from 0 to 60, a strong tick (and its number,
  small) every 5; the start ringed. 1. **Hop**: drag each hop out from the last number; it snaps a square at a time, live
  "+3 = 4", and the number lands over it. A wrong hop: "That hop is 4. The rule adds 3." Five hops. 2. **Tap** the odd
  numbers: each is ringed. An even one: "10 is even: it's 5 twos." 3. **Tap a choice**: will the 20th number be odd or
  even? Wrong: "Odd, even, odd, even: it repeats every 2, so the 20th is like the 2nd."
  **Record:** `1, 4, 7, 10, 13, 16, …`, the odd ones ringed: "odd, even, odd, even". **Say:** "Adding 3 turns odd into
  even and back."
- **A shape rule** (shapes 1–3 drawn side by side, each with 2 more squares than the last, the 2 new squares tinted):
  1. **Tap** squares to build shape 4 in its place (live count). Wrong: "Shape 4 has 2 more than shape 3: 9." 2. Under
  the shapes, shape 1's 3 squares lie in a row with the tinted pairs of shapes 2 to 4 after them. **Drag out copies** of
  the pair: each copy is the next shape, live "shape 7: 3 + 6 × 2 = 15". Let go short: "That's shape 9. One more copy."
  (The longest, 5 + 11 × 4, is 49 squares.) 3. **Write** `shape 10 = [21] squares`. Slips: 20 ("10 × 2 forgets that
  shape 1 starts with 3."), 19 (shape 9), 23 (shape 11).
  **Record:** `3, 5, 7, 9, …, 21`, then `3 + 9 × 2 = 21`. **Say:** "9 more shapes add 9 × 2 to the first one."

**Core (new):** number rules: start 0–9, add 2–9, six numbers ending at 60 or less; the question asks about a number from
the 10th to the 30th. Shape rules: towers, L's and steps, the first shape 1–5 squares, adding 1–4; ask about shape 6–12.
Index < 3: an odd add, then a shape, then an even add (whose numbers keep the start's oddness: "Adding 4 keeps even
numbers even."). Check: an odd add; an even add; a shape; a shape. After g3-facts.

## 4. Fractions (fractions' colour)

5th grade's bars (`BarsKit`): a whole bar 48 squares long (40 for fifths and tenths; other lengths where a lesson says), 4
tall, 2 apart; shaded pieces in the chapter colour, the second amount striped; the bars' names, their fractions, at their
right ends; the ruler and sliding pieces. 4th grade's bottoms are 2, 3, 4, 5, 6, 8, 10, 12 and 100.

### Breaking fractions apart (`g4-decompose`) · 4.NF.3a, 4.NF.3b, 4.NF.4a · new
**Square:** the bar is one whole (48, or 40 for fifths and tenths). **Picture:** the fraction's bar, a of its d pieces
shaded, named `5/8`.
- **Into unit pieces:** 1. **Split at each joint** between shaded pieces: they part a little, each named `1/8`; live
  "1/8 + 1/8 + …". 2. **Write** `5/8 = 1/8 + 1/8 + 1/8 + 1/8 + 1/8 = [5] × 1/8`.
- **Two ways:** 1. **Split** the bar once: live "2/8 + 3/8". 2. A copy of the bar draws under it; **split** it another
  way. The same split again, either way round: "That's 2/8 + 3/8 again. Split it somewhere else."
- **Wholes and a part** (2 1/8: two whole bars and one more): 1. **Tap** each whole bar: its pieces count and its name
  changes from `1` to `8/8`.

**Record:** `5/8 = 2/8 + 3/8`, `5/8 = 1/8 + 4/8`; `2 1/8 = 1 + 1 + 1/8 = 8/8 + 8/8 + 1/8` (it stops there: 5th
grade's Mixed numbers to fractions writes 17/8). **Say:** "5 eighths are 5 pieces of 1/8." / "The same 5 pieces,
grouped another way." / "Each whole is 8 eighths."
**Core (new):** d 3, 4, 5, 6, 8, 10 or 12; unit pieces: a 2 to d − 1; two ways: a 3 to d − 1; wholes and a part: w 1–3,
n 1 to d − 1, d up to 8. Index < 3: unit pieces with d up to 6; then two ways; later wholes and a part. The splits and
taps write the record; unit pieces type the count. Check: unit pieces; two ways; two ways with d of 8 or more; wholes and
a part. After g3-unitfrac.

### Equivalent fractions (`g4-equiv`) · 4.NF.1 · web
LESSONS.md's 4th grade example: the pieces cut again, in place. **Square:** the whole, 48 squares when its pieces fit
(halves to twelfths, 16ths, 24ths), else 40 (tenths, 20ths), 45 (ninths, 15ths), 36 (18ths), 50 (25ths) or 60 (30ths).
**Picture:** two bars of that whole: a/b on top, named `1/2`; the same bar under it, the same cuts and shading, named
`?/8`.
1. **Cut** the lower bar smaller with the ruler: it snaps to sizes that cut every piece evenly, live "eighths: each half
   into 4", dashed across it. **Cut.** Other pieces: "Those are sixths. Cut into eighths." Sets the times (4).
2. **See:** the cuts turn solid; the shaded part hasn't moved, a dashed line down both bars at its end; its pieces number
   1 to 4. **Write** `1/2 = [4]/8`.

**Record:** `1/2 = (1 × 4)/(2 × 4) = 4/8`. **Say:** "Every piece cut into 4: 4 times the pieces, the same amount."
**Core:** the web's maths: b 2–6, a in lowest terms, k 2–5; slips kept (added for times, changed only the bottom, added to
the top). The spec's new idea line. Check: i0 where a = 1; i0 where a > 1; i0 where k ≥ 4; i0 where a > 1 and b ≥ 5.

### Comparing fractions (`g4-fraccompare`) · 4.NF.2 · web
**Square:** the whole, 48 squares (45 for ninths and 15ths; 40 for fifths, tenths and 20ths). **Picture:** two bars of
the same whole, a/b shaded on top and c/d striped under it, named at their right ends, `?` between the names; a small ½
under the bars' middle.
1. **Cut** both bars with the ruler into pieces of one size (5th grade's ruler: dots under the old cuts, green when a new
   cut lands on one, red when none does). **Cut.** "Those fit. Bigger pieces fit too." / "That cut misses a third."
   When one bottom goes into the other, only one bar takes new cuts. Sets the bottom for both and both new tops.
2. **See:** the shaded pieces number on each bar, "8 twelfths", "9 twelfths"; a dashed line from each shaded end shows
   which reaches further.
3. **Tap a choice** (< = >). Slips kept (compared the tops: "Tops only compare when the pieces are the same size.";
   bigger bottom, bigger fraction; called them equal; missed that they're equal; turned it around).

**Record:** `2/3 = 8/12`, `3/4 = 9/12`, `2/3 < 3/4`. **Say:** "8 twelfths is less than 9 twelfths."
**Core:** the web's maths: index < 4 one bottom goes into the other (b 2–6, and 2b or 3b up to 12), then half the time
2 and 3, 2 and 5, 3 and 4, 3 and 5, or 4 and 5; lowest terms; the same amount now and then. Keep the tap (the spec: it's
the idea). Check: i0; i0 where they're equal; i4 where the new bottom is neither; i4 where it's neither and the tops
alone point the wrong way.

### Adding like fractions (`g4-likefrac`) · 4.NF.3a, 4.NF.3d · web
5th grade's Adding fractions without the ruler: the pieces already match. **Square:** the whole, 48 (40 for fifths and
tenths). **Picture:** a/d shaded and c/d striped, named, `+` between.
1. **Slide** the striped pieces up into the first bar: they snap in after its shaded pieces, the count running on (3,
   4, 5); past a whole they spill into a second whole bar under it. Dropped elsewhere: "Put them in the top bar." Sets the
   top.
2. **Write** `2/8 + 3/8 = [5]/[8]`. Slips kept (multiplied the tops; added the bottoms: "Eighths and eighths are still
   eighths.").

**Record:** `2/8 + 3/8 = 5/8` ("More than 1 is fine here" when it is). **Say:** "Same-size pieces, so the tops add."
**Core:** the web's maths: index < 3 d 3–6 with a + c < d, then d 3, 4, 5, 6, 8, 10 or 12; the sum already in lowest
terms. Story: pizza. Check: i0; i3 where a + c > d; i3 where a + c < d; i3 story.

### Subtracting like fractions (`g4-likesub`) · 4.NF.3a, 4.NF.3d · new
5th grade's Subtracting fractions without the ruler. **Square:** as Adding like fractions. **Picture:** a/d shaded (or a
whole bar named `1`), c/d striped under it, `−` between.
1. **Slide** the striped pieces onto the shaded ones from the right: each one it covers is crossed out, and what's left
   counts down. Dropped elsewhere: "Slide them onto the shaded pieces." Sets the top.
2. **Write** `7/8 − 2/8 = [5]/[8]`. Slips: the bottoms taken away too ("The pieces are still eighths."), added ("2/8 is
   taken away, so there's less.").

**Record:** `7/8 − 2/8 = 5/8`. **Say:** "Same-size pieces, so the tops are taken away."
**Core (new, Adding like fractions' mirror):** index < 3 d 3–6, then 3, 4, 5, 6, 8, 10 or 12; a 2 to d (a = d is a whole
bar, later), c 1 to a − 1, the difference in lowest terms. Stories: pizza left, ribbon cut off, juice drunk. Check: i0;
i3 where a = d; i3; i3 story. After g4-likefrac.

## 5. Mixed numbers (fractions' colour)

Bars half as long, so a mixed number stands in one column and two numbers stand side by side: a whole is 24 squares (20
for fifths, 21 for sevenths), a square apart; the first number on the left, the second (striped) 4 squares to its
right, each named under its column (`2 3/5`). A bar with pieces is 4 squares tall; a whole bar, all shaded, is 2 (it has
no pieces to count), and grows to 4 when it's opened into pieces. So when the wholes join (6 wholes, the part bar and a
spill bar), the column is 6 × 3 + 5 + 4 = 27 rows and the record still fits under it.

### Adding mixed numbers (`g4-mixed`) · 4.NF.3c, 4.NF.3d · web
**Square:** a whole is 24 (20 for fifths). **Picture:** w1 whole bars and an n1 bar on the left; w2 and n2, striped, on
the right.
1. **Slide** the right column's whole bars over under the left's: "3 wholes". Sets the wholes.
2. **Slide** its pieces into the left's part bar: they snap in after its shaded pieces; past its end they spill into a
   new bar, "7 fifths". Sets the pieces.
3. A full bar: **tap** it (the full ten's move, for a bar): it closes into a whole and joins the wholes, "5 fifths =
   1 whole". Sets the trade.
4. **Write** `2 3/5 + 1 4/5 = [4] [2]/5`. Slips kept (multiplied the wholes, added the bottoms, kept every piece,
   didn't make a whole, forgot to trade, lost the new whole, a whole too many).

**Record:** `2 + 1 = 3`, `3/5 + 4/5 = 7/5 = 1 2/5`, `2 3/5 + 1 4/5 = 4 2/5`. **Say:** "5 fifths make a whole, so 3
wholes become 4."
**Core:** the web's maths: d 3, 4, 5, 6 or 8; wholes 1–3 each; a trade half the time for index < 3, then three times in
four; never exactly a whole of pieces; the answer's fraction in lowest terms. Story: Mia's walks. Check: i0 with no
trade; i3 with a trade; i3 with a trade and d ≥ 6; i3 story.

### Subtracting mixed numbers (`g4-mixedsub`) · 4.NF.3c, 4.NF.3d · new
**Square:** as Adding mixed numbers. **Picture:** the first number's bars on the left, the second's, striped, on the
right.
1. **Slide** the striped pieces onto the shaded ones from the right: each one covered is crossed out, and what's left
   counts down. Too few: the slide stops, red: "2 fifths can't take away 4. Open a whole."
2. **Open** a whole (tap it, as a ten is opened): it grows into a bar of its 5 pieces, which join the part bar, "7
   fifths"; then the slide goes on, "3 fifths left". Opening one when there are enough: "There are enough fifths. Take
   away first."
3. **Slide** the striped wholes onto the left's wholes: crossed out.
4. **Write** `3 2/5 − 1 4/5 = [1] [3]/5`. Slips: the smaller top from the bigger (2 2/5: "You can't take 4 fifths
   from 2. Open a whole first."), the opened whole forgotten (2 3/5: "One whole became fifths, so 3 wholes are 2
   now."), the bottoms taken away.

**Record:** `3 2/5 = 2 7/5`, `2 7/5 − 1 4/5 = 1 3/5`. **Say:** "A whole is 5 fifths, so it can be opened to take
away."
**Core (new, Adding mixed numbers' mirror):** d 3, 4, 5, 6 or 8; w1 2–4, w2 1 to w1 − 1; n1 and n2 1 to d − 1, never
equal; a whole to open half the time for index < 3, then three times in four; the answer's fraction in lowest terms.
Stories: ribbon cut off, juice poured, trail still to walk. Check: i0 with none opened; i3 with a whole opened; i3 with
one opened and d ≥ 6; i3 story. After g4-mixed, g4-likesub.

### Fraction times a whole number (`g4-fracwhole`) · 4.NF.4 · web + the unit pieces line
**Square:** a whole is 24 (20 for fifths, 21 for sevenths). **Picture:** W bars on the left, each a whole with n of d
pieces shaded (the groups take turns plain and striped), braced `3 × 2/5`; an empty answer bar on the right.
1. **Slide** the groups over: their pieces pack into the answer bar group after group, the count running on (2, 4, 6
   fifths), spilling into a new bar when one fills. Dropped elsewhere: "Put them in the answer bar." Sets the top.
2. **Write** `3 × 2/5 = [6]/5`; the line `= 6 × 1/5` is written for the child (4.NF.4a: 6 pieces of a fifth).
3. When it can be written another way (the web's step: a mixed number, a whole number, or simpler): a full bar is
   **tapped** and closes into a whole (or the cuts change to the simplest pieces, as 5th grade's answer bar does);
   **write** `6/5 = [1] [1]/[5]`.

**Record:** `3 × 2/5 = 6 × 1/5 = 6/5 = 1 1/5`. **Say:** "3 groups of 2 fifths make 6 fifths. The pieces stay fifths."
**Core:** the web's maths: d 3–8, n in lowest terms, W 2–6; slips kept (multiplied the bottom; the simplify step's own).
The step's label follows the spec's fix ("Write as a mixed number" only when it is one). Story: milk for muffins (the
answer bars show which two whole numbers it falls between). Check: i0 where W × n < d; i0 where W × n > d and d doesn't
go into it; i0 where d goes into it; i0 story.

## 6. Decimals (decimals' colour)

A whole is a bold square 20 × 20 squares, so a hundredth is 2 × 2 and a tenth a column 2 × 20 (the size 5th grade's
Multiplying decimals had first; here nothing is bigger than two wholes). Lines as in Rounding decimals: 50 squares, ten
blocks of 5.

### Tenths and hundredths (`g4-dec`) · 4.NF.5, 4.NF.6 · web
**Square:** 2 × 2 squares is a hundredth. **Picture:** two wholes side by side, 4 squares apart: a/10 as shaded tenths
(columns, no hundredth lines in them), named `3/10`; b/100 as striped hundredths, named `25/100`; `+` between.
1. **Tap** a shaded tenth: every shaded tenth opens into ten hundredths (the lines draw down them), live "3 tenths = 30
   hundredths". Sets the hundredths.
2. **Slide** the striped hundredths into the first whole: they pour in after its shaded ones, a column at a time; a full
   whole overflows into the second. Live "55 hundredths". Sets the sum.
3. **Write** `55/100 = [0.55]`. Slips kept (changed only the bottom; used the tenths as they were, 28/100: "Tenths are
   bigger pieces."; the point in the wrong place, 5.5).

**Record:** `3/10 + 25/100 = 30/100 + 25/100 = 55/100 = 0.55`. **Say:** "A tenth is ten hundredths, so they add as
hundredths."
**Core:** the web's maths: a 1–9, b 1–99. Check: i0 where the sum is under 100; i0 where it's 100 or more; i0 where
b < 10; i0.

### Decimals on a number line (`g4-decline`) · 4.NF.6 · new
Rounding decimals' two lines. **Square:** on line 1 a block (5 squares) is a tenth; on line 2 a block is a hundredth.
**Picture:** line 1 from 0 to 1 (or from a whole number to the next), ten blocks, named at its ends; the decimal (`0.62`)
waiting over its left end, its point to place.
1. **Tap the block** it's in: it lights and opens below into line 2, 0.6 to 0.7 in hundredths. Wrong: "0.62 is between
   0.6 and 0.7." Sets the tenths.
2. **Drag the point** along line 2: it snaps to hundredths, live "0.62". Let go wrong: "That's 0.64. 0.62 is 2
   hundredths past 0.6." Sets the hundredths. (A tenths decimal, 0.7, is placed straight on line 1's tick.)
3. **Write** `0.62 = [62]/100`. Slips: 6/10 ("That's the tenths only."), 62/10 ("62 hundredths: the bottom is 100.").

**Record:** `0.62 = 6/10 + 2/100 = 62/100`. **Say:** "6 tenths and 2 hundredths make 62 hundredths."
**Core (new):** index < 3: 0.11–0.99 with no 0 digit; then tenths only (0.7), under a tenth (0.05, in the first block),
and a whole number in front (1.45 on a line from 1 to 2); told as a meter stick now and then ("A ribbon is 0.62 m
long."). Check: i0; i3 where it's under a tenth; i4 where it's tenths only; i6 with a whole number in front. After g4-dec.

### Comparing decimals (`g4-deccompare`) · 4.NF.7 · web
**Square:** 2 × 2 is a hundredth. **Picture:** two wholes side by side, named by their decimals over them (`0.5`,
`0.45`), `?` between. With a whole number in front (both always have the same one), the grids show the part after the
point and the instruction says so once: "Both have 3 wholes. Shade what's after the point."
1. **Shade** the first: drag down the grid: it fills a column (a tenth) at a time, then single hundredths; live "50
   hundredths". 0.5 shaded as 5 squares: "0.5 is 5 tenths: 5 full columns." Sets the first.
2. **Shade** the second: "45 hundredths". Sets the second.
3. **Tap a choice** (< = >). Slips kept (compared the digits as whole numbers: "45 and 5 aren't the amounts. 0.5 has
   50 hundredths."; called them equal; missed that they're equal; turned it around).

**Record:** `0.5 = 50 hundredths`, `0.45 = 45 hundredths`, `0.5 > 0.45`. **Say:** "50 hundredths is more than 45."
**Core:** the web's maths: index < 4 with no whole number; the trap (a tenths decimal against a two-place one) about
half the time, then the same tenths, the same amount written two ways, any two; the shading answers the two hundredths
steps. Keep the tap. Check: the spec's four.

## 7. Measurement (measurement's colour)

### Converting measurements (`g4-convert`) · 4.MD.1 · web + the table and four more pairs of units
5th grade's Converting units, big to small. **Square:** one big unit is a bar 48 squares long (40 when it's 100 or 1,000
small units), 4 tall (2 when there are many bars). **Picture:** a bar for each big unit, each named `1 ft` at its right
end, the column braced and named with the amount (`3 ft 5 in`); the extra small units as a short bar under them, true to
size (5 inches is 20 squares).
1. **Cut** the first bar into its small units with the ruler: "12 inches" (60, 100 and 1,000 are cut in tens: "10 min",
   "10 cm", "100 m" on each piece). **Cut.** Slips kept (10 or 3 for feet; 10 or 1,000 for meters; 100 or 24 for hours;
   12 or 10 for pounds).
2. **See:** the other bars cut and count on (12, 24, 36), each written as a row of a two-column table beside them as it's
   counted (`ft | in`, `1 | 12`, `2 | 24`, `3 | 36`). **Write** `3 × 12 = [36]`.
3. With extra small units: they count on (37 … 41); **write** `36 + 5 = [41]`. Slips kept (left off the extra,
   multiplied the extra too).

**Record:** the table, then `3 ft 5 in = 36 + 5 = 41 in`. **Say:** "Every foot is 12 inches."
**Core:** the web's maths: feet and inches, meters and centimeters, hours and minutes, pounds and ounces; n 2–5 for
index < 3, then 2–9; extra small units about a third of the time early, two thirds later. **Fold** (4.MD.1's other
units): from index 6 also km to m, kg to g, L to mL (× 1,000) and min to s (× 60), with their slips ("Kilo means a
thousand.", "A liter is 1,000 milliliters.", "A minute is 60 seconds.") and extras in 50s (m, g, mL) or 5s (s). Stories:
the web's rope, table, road trip and flour, and a race, potatoes, a jug, a song for the new units. Check: the spec's,
with its story item drawn at i6 so it can be a new unit.

### Measurement story problems (`g4-measure`) · 4.MD.2 · new
**Square:** set by the story so every amount lands on a square: 5 minutes (3rd grade's Elapsed time line, an hour 12
squares), 25¢, 100 mL, 100 m or 100 g; the big unit (an hour, a dollar, a liter, a kilometer, a kilogram) is a long tick
with its name. **Picture:** the measuring line, up to 60 squares, its units named under it, the start ringed.
1. **Hop** each amount the story gives: drag a hop out from where you are; it snaps a square at a time; live, the hop in
   the story's units and where it lands ("1 h 20 min → 5:05"). A wrong hop: "That hop is 1 h 40 min. The game lasts
   1 h 20 min." A "How long?" story hops from the start to the end, counting up, and the hops add.
2. **Write** the answer in the unit the story asks for: `3:45 + 1 h 20 min = [5:05]`; `2 L − 3 × 300 mL = [1,100] mL`.

**Record:** the hops written as a sum or difference, any change of unit first (`2 L = 2,000 mL`). **Say:** "Hop each
part, then read where you land."
**Core (new):** five kinds: time (start times to 5 minutes; lengths from 15 minutes to 2 h 30 min, or two times), money
(prices in quarters up to $12: change from a bill, or two things together), liquid (L and mL in 100s up to 5 L),
distance (km and m in 100s up to 5 km), mass (kg and g in 100s up to 5 kg). Index < 3: one hop, one unit; then two hops,
or a change of unit. From index 4, now and then an amount is a simple fraction or decimal of the big unit, as 4.MD.2
asks: 1/2 L, 1/2 kg, 0.5 km, a quarter hour, $2.75 (each lands on squares: "1/2 L is 5 squares: 500 mL"; never 1/4 kg,
which would end mid-square). Slips: the unit not changed ("2 L is 2,000 mL."), an hour as 100 minutes ("An hour is 60
minutes."), added for taken away. Check: time; money; liquid with a change of unit; distance in two hops. After
g3-elapsed, g4-convert, g4-dec.

### Area and perimeter (`g4-area`) · 4.MD.3 · web + the missing side
**Square:** a square meter is one block (5 × 5 squares, its sides the paper's strong lines), as a cube is one block in
Unit cubes. **Picture:** the rectangle's top-left corner on a strong line, its sides still to draw, `5 m` over the top
and `3 m` down the left (the problem, written as the picture's names). The biggest (15 × 10 m) make the camera step
back.
1. **Drag** the corner out to 5 by 3: it snaps to blocks, the blocks inside counting, live "5 by 3: 15 square meters".
   **Write** `5 × 3 = [15] m²`. Slips kept (the perimeter; added).
2. **Trace the edge** (3rd grade's Perimeter move) along one long side and one short side: they light as the finger runs
   along them, live "5 m + 3 m = 8 m". **Write** `5 + 3 = [8]`. Slip kept (multiplied).
3. **See:** the traced half turns round onto the other two sides. **Write** `2 × 8 = [16] m`. Slip kept (the area).

**Record:** `Area = 5 × 3 = 15 m²`, `Perimeter = 2 × (5 + 3) = 16 m`. **Say:** "Area counts the blocks inside; perimeter
goes round the edge."
**Core:** the web's maths: l 3–15, w 2–10. **Fold** (4.MD.3's missing side): from index 6, now and then the area (up to
150 m²) or the perimeter (up to 50 m) is given with one side (2–10 m); **drag** the free edge until the blocks make the
area (live "6 × 4 = 24") or **trace** until the two sides make half the perimeter; **write** `6 × [4] = 24` (3rd grade
found a missing side by counting round the edge; here it comes from the formulas). Check: the spec's (i0 where l ≤ 10;
i0 where l ≥ 11; i0; i0), the last drawn at i6 for the fold.

### Line plots with fractions (`g4-lineplot`) · 4.MD.4 · web + making the plot
**Square:** two inches are 48 squares, so an inch is 24, a fourth 6 and an eighth 3. **Picture:** the line plot: the line
(48 squares, two inches) and its ticks, the whole inches and halves named, the X's stacked over it (each 2 × 2), its
title over it ("Ribbon lengths (in)").
1. **Making the plot** (the first three problems and the How to, as 3rd grade's line plots do): the lengths wait in a
   row of cards over the line; **place an X** for each of the first three (tap its tick: an X stacks there and its card
   crosses out), and the rest drop in by themselves (See). Wrong tick: "That's 1/2. This ribbon is 3/4." Later problems
   start with the plot drawn.
2. Then one of the web's three questions:
   - How much longer is the longest than the shortest? **Tap** the longest X, then the shortest (live "1 3/4 in",
     "1/2 in"); **hop** from the shortest to the longest, the hops counting fourths; **write**
     `1 3/4 − 1/2 = [1] [1]/[4] in`.
   - Laid end to end, how long are the ones at 1 1/4? **Tap** the stack (live "4 ribbons"); **write**
     `4 × 1 1/4 = [5] in` (the spec's fixed line).
   - How many are longer than 1 1/4? **Tap** each X past it (they light and count); one at 1 1/4: "1 1/4 isn't longer
     than 1 1/4."

Slips kept (the next mark, added, counted marks not spaces, the next stack, gave the count, left one out, counted the
length itself). **Record:** the question's line under the plot (`1 3/4 − 1/2 = 1 1/4 in`). **Say:** "Each X is one
ribbon, over its length."
**Core:** the web's maths: index < 3 fourths, the longest-minus-shortest question, from 0; then fourths or eighths, the
question by index % 3, starting at 0 or 1 inch; 8–12 X's with one tallest stack; answers never whole inches. **Fold**
(4.MD.4's "make"): placing the X's is a first step, answered by the placements. Check: i3 (difference), i4 (total), i5
(how many longer), i6 where it's eighths.

## 8. Lines and shapes (the teal of 5th grade's Geometry)

Angles and shapes on the grid: every corner sits on a grid point and a first arm runs along a grid line; an arm turned to
an angle that isn't along the grid is drawn at its true angle (open question 3). Two tools lie beside the picture and are
dragged on: **the page corner** (a square corner, 6 squares a side) and **the protractor** (a half circle of radius 20
squares, a tick every degree, longer every 10, two scales).

### Points, lines, rays and angles (`g4-lines`) · 4.G.1 · web + drawing them
**Square:** points sit on grid points; a figure is 30–40 squares long. **Picture:** the figure through points A and B,
turned by grid steps (12 across and 5 up, …); an angle; or two lines.
- **Line, ray or segment:** 1. **Tap each end**: "a dot: it stops here" or "an arrowhead: it goes on" (the taps answer
  the endpoints step). 2. **Tap a choice**: Line, Ray or Segment. Slips kept (counted the arrowheads, looked at one end,
  each wrong name's line).
- **What kind of angle:** 1. **Lay the page corner** on its corner: the angle fits inside it, fits it exactly, or opens
  past it (this answers the web's compare step). 2. **Tap a choice**: Acute, Right, Obtuse (or Straight). Slips kept,
  the arms one said here: "Long arms don't make a bigger angle. Look at how wide it opens."
- **Two lines:** 1. **Run each line on**: they cross, or stay the same distance apart ("4 squares apart all the way").
  2. Where they cross, **lay the page corner**: it fits or it doesn't. 3. **Tap a choice**: Parallel, Perpendicular or
  Intersecting.

**Fold** (4.G.1's "draw"): later problems ask the child to make it: "Make a ray from A through B" (tap the ends to dots or
arrowheads), "Make an obtuse angle" (**turn** the free arm; live "acute", "right", "obtuse"), "Draw a line through P that
never meets this one" (drag from P; it snaps to grid steps; live "parallel" when its steps match), "Draw a line through
P that meets this one in square corners" (live "perpendicular" when the page corner fits where they cross).
**Record:** its name, written under it (`ray AB`, `obtuse angle`, `parallel lines`). **Say:** the web's: "No endpoints
is a line, 1 is a ray, 2 is a segment." / "Smaller than a square corner is acute, exactly is right, bigger is obtuse."
/ "Never meet: parallel. Square corners: perpendicular. Otherwise: intersecting."
**Core:** the web's maths (three kinds, by index % 3 after the first three; angles 15–75° or 100–165° in 5s, 90° a
quarter of the time, 180° a tenth; intersecting lines at 30–70°), its turns made grid steps; the spec's three idea lines.
Draw problems: from index 6, every other one. Check: the spec's five (i3; i4 acute; i7 obtuse; i5 perpendicular; i8
intersecting).

### Angles and degrees (`g4-turns`) · 4.MD.5 · new
**Square:** the corner on a grid point; a circle of radius 16 squares round it, cut into 360 one-degree steps (a tick
every 10°, longer every 90°). **Picture:** the circle, a fixed arm along the grid line to the right, a second arm on it to
turn.
- **A part of a turn** ("Turn it 1/4 of the way round."): 1. **Turn** the arm: it snaps every 5°, the arc between the
  arms shading; live "90°", and when it's a part with a 4th grade bottom, the circle's dashed cuts show it ("1/4 turn").
  Let go wrong: "That's 1/3 of a turn: 120°. A quarter is 90°." 2. **Write** `1/4 of 360° = [90]°`.
- **The clock** (the circle as 3rd grade's clock face, 12 numbers): "The minute hand turns from 12 to 4." 1. **Turn
  the clock hand** (3rd grade's move): here it snaps to the numbers, live "4 × 30° = 120°". 2. **Write** `[120]°`.

**Record:** `1/4 of 360° = 360° ÷ 4 = 90°`. **Say:** "A whole turn is 360 one-degree steps."
**Core (new):** parts n/d with d 2, 3, 4, 6, 8 or 12 and n < d; index < 3: 1/4, 1/2 and 3/4; then the others, and the
clock (1–11 hours). Slips: 100 for a whole turn ("A whole turn is 360°."), the rest of the turn (360 − x), a part of 180
("That's a part of half a turn."). Check: a quarter or a half; a third or a sixth; the clock; an eighth or a twelfth.
After g4-lines, g4-fracwhole.

### Measuring angles (`g4-protractor`) · 4.MD.6 · new
**Square:** the corner on a grid point, the first arm along a grid line (pointing right or left); arms 24 squares long.
**Picture:** the angle, the protractor beside it.
- **Measure it:** 1. **Lay the protractor** on it: it snaps only with its centre on the corner and its edge along the
  first arm ("Put its centre on the corner."). The scale that starts at 0 on that arm has its 0 ringed. 2. **Write**
  `[130]°`, read where the other arm crosses. Slips: 50 ("That's the other scale. Count from the 0 on the bottom arm:
  this angle is bigger than a square corner."), 120 or 140 ("That's one long mark off. Find the long mark just before
  the arm, then count on: each small mark is 1°.").
- **Draw it** ("Make an angle of 65°."): the protractor already on the first arm. 1. **Turn** the free arm: it snaps to
  whole degrees, live "65°" on the scale from that arm's 0. Let go at 115: "That's 115°. 65° is smaller than a square
  corner."

**Record:** `angle = 130°`. **Say:** "Count from the 0 on the first arm."
**Core (new):** angles 10–170°: index < 3 tens, then fives, then any whole degree; the first arm points right or left in
turn (so both scales get read); measuring and drawing take turns. Check: measure an obtuse one; measure an acute one with
the first arm pointing left; draw an acute one; draw an obtuse one. After g4-turns.

### Angles add up (`g4-angles`) · 4.MD.7 · web + any whole
**Square:** the corner on a grid point; a right angle's arms along grid lines, 20 squares long; a straight line 40 across.
**Picture:** the right angle (or the straight line), the part we know drawn inside with its arc and `35°`, the missing
part's arc dashed with `?`.
1. **Lay the page corner** on it: one corner fits the right angle ("a square corner: 90°"); two fit the straight line
   side by side ("two square corners: 180°"). Sets the whole.
2. **Write** `35° + [55]° = 90°`. Slips kept (the wrong whole; added).

**See:** the missing arc fills and is named `55°`. **Record:** `90° − 35° = 55°`. **Say:** "The two parts fill the square
corner."
**Core:** the web's maths: index < 3 a right angle with a part in tens (20–70°); then a straight line half the time (a
part 20–160°), else a right angle (15–75°). The spec's lead replaces "= 90°" in the words. **Fold** (4.MD.7's any
angle): from index 6, now and then the whole is a measured angle (40–170° in 5s, **read** with the protractor first), or
the whole is missing and both parts are given (`40° + 75° = [115]°`). Check: the spec's (i0; i3 a right angle; i3 a
straight line; i3 a straight line, not in tens), plus i6 for the fold.

### Sorting by sides and angles (`g4-classify`) · 4.G.2 · new
The marking moves are the ones 5th grade's Sorting shapes (`g5-shapes`) uses, so that lesson picks up where this one
stops; here the marks sort the shape into two loops, there into the family of boxes. **Square:** corners on grid points,
each side going whole grid steps (3 across and 1 up); shapes 10–24 squares across. **Picture:** the shape on the left;
a block to its right a two-loop diagram drawn on the paper (two overlapping loops, about 36 × 24 squares, so shape and
loops are 65 squares at most), named "parallel sides"
and "a square corner"; for triangles, "a square corner" and "an obtuse angle").
1. **Tap each square corner**: the page corner lays itself on it, and when it fits the little square mark is drawn.
   Wrong: "That corner isn't square: the page corner doesn't fit it." For triangles, an obtuse corner is tapped too
   ("It opens past the page corner: obtuse.").
2. **Tap two sides that are parallel**: they get matching arrowheads (one for the first pair, two for the second); then
   **No more**. Wrong pair, measured on the grid: "Not parallel: one goes 3 across and 1 up, the other 3 across and 2
   up." No more too soon: "There's another parallel pair."
3. **Sort into loops**: drag the shape into one loop, the other, both, or outside both. Wrong: "It has a square corner,
   so it goes in that loop too." / "It has no parallel sides: keep it out of that loop."

**Record:** "1 pair of parallel sides, 2 square corners: both loops." **Say:** "Parallel sides and square corners sort
shapes." (For triangles: "A triangle with a square corner is a right triangle.")
**Core (new):** shapes with corners on grid points, turned only by quarter turns or mirrored: triangles (right, isosceles
right, obtuse, acute) and quadrilaterals (square, rectangle, parallelogram, rhombus, trapezoid, right trapezoid, kite,
one with nothing special); index < 3 a rectangle, a right triangle, a parallelogram. The taps set the corners and the
pairs, the drag the loop. Check: a right triangle; a parallelogram; a right trapezoid (both loops); a kite (neither). Not
5th grade's family of boxes, not 3rd grade's names. After g4-lines, g4-angles.

### Lines of symmetry (`g4-symmetry`) · 4.G.3 · web + drawing the fold lines · 3D
**Square:** the shape centred on a grid point, about 30 squares across, its corners on grid points where the shape
allows (the regular triangle, pentagon and hexagon are drawn true, one line of symmetry on a grid line). **3D:** the
fold. The half lifts off the paper, turns over the line and lands; the paper tilts a little while it turns (Unit cubes'
tilt, smaller) and lies flat again after.
- **Is the dashed line a line of symmetry?** 1. **Fold** on it: drag the half over the line; it lands with every
  corner on a corner (a green dot on each), or with parts sticking out (outlined, "2 corners stick out"). 2. **Tap a
  choice**: Yes or No, from what the fold showed. Slips kept: "Folded on a diagonal, the corners stick out." / "A
  parallelogram's halves match if you turn one, not if you fold it."
- **How many lines?** 1. **Draw** a fold line across the shape (it snaps to lines through the middle) and let go: it
  **folds**; a match stays drawn and counted, a miss unfolds and the line goes. 2. **Write** `[4] lines of symmetry`.
  Slips kept (the rectangle's diagonals, the square's missed diagonals, one off for a regular shape, the
  parallelogram's lines that don't fold).

**Record:** "The dashed line is a line of symmetry." (or "is not"); `4 lines of symmetry`, the lines left drawn on the
shape. **Say:** "Every corner lands on a corner." / "A square folds 4 ways."
**Core:** the web's maths: its ten shapes and their tempting lines; index < 3 the rectangle, the square and the heart
with a dashed line; then the two kinds in turn, turned after index 5 (by quarter turns, so the shapes on grid points
stay on them). Check: i4 where the line works; i6 where it doesn't; i3 (count); i5 where it's the rectangle or the
parallelogram.

## Open questions for G

1. **How big a grade?** 35 lessons: the web's 19 and 16 new, so every Grade 4 standard is covered. A lighter 31 folds four
   new ones into their neighbours (Subtracting like fractions into Adding like fractions, Subtracting mixed numbers into
   Adding mixed numbers, Angles and degrees into Measuring angles, Dividing big numbers into Dividing with remainders as
   its later problems). Which do you want?
2. **Chapter colours.** 4th grade has 8 chapters and the paper has four chapter colours, plus the teal 5th grade's plan
   adds for Geometry. The plan colours by family: the three whole-number chapters share purple, the two fraction
   chapters share blue, and Lines and shapes takes the teal. Is sharing a colour right, or should every chapter have
   its own? (3rd grade's plan asks the same.)
3. **Angles off the grid lines.** An arm at 37° can't run along the grid. The plan keeps every corner on a grid point
   and the first arm on a grid line, and draws the turned arm at its true angle; the regular triangle, pentagon and
   hexagon in Lines of symmetry are drawn the same way. Is that all right with "nothing goes off-grid"?
4. **Web ranges that don't fit.** Some of the web's ranges sit badly here. Equivalent fractions makes 9ths, 15ths,
   18ths, 20ths, 25ths and 30ths (1/6 = 5/30), Comparing fractions gives ninths (1/3 against 4/9), and Fraction times a
   whole number uses sevenths, but 4th grade's fractions stop at 2, 3, 4, 5, 6, 8, 10, 12 and 100 (15ths as the shared
   bottom of thirds and fifths is fine: both fractions are 4th grade's). And two pictures are big: with a square meter
   as a block, Area and perimeter's biggest rectangles (15 × 10 m) are seen at about 70%; Two-digit times two-digit's
   biggest (99 × 49 squares) at about 60%. Keep the web's ranges (your rule), or trim them (bottoms to the standard's;
   rectangles to 12 × 6 m; two-digit numbers to about 50 × 25, every one seen at full size)?
5. **Dividing with remainders: a deal, not a rectangle.** 5th grade's Long division finds a rectangle's width a square
   at a time. Here that rectangle would be up to 99 squares wide and only 3 to 9 tall: a thin strip at 65%. So this plan
   deals the number's disks into rows a place at a time (the same move as Dividing big numbers), which fits at full size
   and shows the left over as disks too few for a round. All right, or keep 5th grade's rectangle with the camera
   stepping back?
