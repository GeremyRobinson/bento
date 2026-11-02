# 3rd grade on paper: every lesson's design

Claude, grade 3 lesson planner, 1 Nov 2026. Written in the language of `README.md` and shaped like `grade5.md`. This is
a plan only: nothing here is built yet. Each lesson gives the standard it covers, what one square is, the picture (sizes
in squares; the iPad's landscape screen is about 68 × 45 at 100%), each step's hand move with its live readout, what a
wrong move says, what the picture then shows, the record (school working), the last line, and what Core needs. The 18
web lessons (`web/src/curriculum/lessons/grade3/`) keep their maths exactly as it is: generator ranges and easy-first
order, derived values, slip messages, check recipes (`specs/k12/grade3.md`) and stories. Only their steps are new,
designed for paper.

Reviewed 1 Nov 2026 (grade 3 reviewer): every generator range, slip and check checked against the web code and
`specs/k12/grade3.md`; the fixes are in place below (a few pictures made bigger, Quadrilaterals' and Draw a bar graph's
picks turned into taps on the picture, Estimate's wrong answers kept clearly far, and the number slips corrected).
Second review, same day: Equal parts' ruler could never make unequal parts (now it snaps to every tile line), Multiply
three numbers had a size that broke its own range (now capped, and drawn a block a dot when a row is short), the liter
stories had two meanings for a square, the tall arrays' records ran off the screen (they now sit beside the picture),
3.MD.C.7c gets tiles in Breaking apart, the trapezoid's words now agree with 5th grade, the jug and the story cells are
bigger, and the picks say what to do.

**Standards covered:** all of Common Core Grade 3, 25 standards and their parts (3.OA.A.1–3.G.A.2). That takes the 18
web lessons plus 10 new ones, **28 lessons in 7 chapters**. Eight small gaps fold into existing lessons as an extra
problem kind or step; they're marked *fold*.

## Coverage

| Standard | In short | Lesson | |
|---|---|---|---|
| 3.OA.A.1 | × as equal groups | Multiplication facts | existing |
| 3.OA.A.2 | ÷ as shares, or as how many groups | Division facts | existing + *fold* (groups of b) |
| 3.OA.A.3 | × and ÷ word problems within 100 | the stories of Multiplication facts, Division facts, Breaking apart, Multiples of 10; the × and ÷ stories of Grams and kilograms and Liters | existing |
| 3.OA.A.4 | the missing number (8 × ? = 48, 5 = ? ÷ 3) | Find the missing number | **new** |
| 3.OA.B.5 | turn-around, grouping, breaking apart | Multiplication facts (turn), Multiply by breaking apart; Multiply three numbers (grouping), Double a fact | existing; **new** |
| 3.OA.B.6 | ÷ as a missing factor | Division facts; Find the missing number | existing; **new** |
| 3.OA.C.7 | every fact to 10 × 10 | Multiplication facts, Division facts (and the daily review); Double a fact | existing; **new** |
| 3.OA.D.8 | two-step problems, a letter for the unknown, is it reasonable? | Two-step word problems; Estimate to check | existing + *fold* (the equation with a letter); **new** |
| 3.OA.D.9 | patterns in the times table, explained | Double a fact (why 4 × any number is even) | **new** |
| 3.NBT.A.1 | round to 10 or 100 | Rounding to 10 and 100 | existing |
| 3.NBT.A.2 | + and − within 1000 | Add and subtract within 1000 | existing |
| 3.NBT.A.3 | one digit × a multiple of 10 | Multiply by multiples of 10 | existing |
| 3.NF.A.1 | 1/b, and a/b as a pieces of 1/b | Unit fractions; Equal parts of a shape | existing; **new** |
| 3.NF.A.2a, b | fractions on a number line | Fractions on a number line | existing |
| 3.NF.A.3a, b | equal fractions: same size, same point | Equal fractions (and Comparing fractions' equal problems) | **new** (existing) |
| 3.NF.A.3c | whole numbers as fractions (3 = 3/1, 4/4 = 1) | Equal fractions, its wholes kind | **new** |
| 3.NF.A.3d | compare with the same top or bottom | Comparing fractions | existing |
| 3.MD.A.1 | time to the minute; time intervals | Time to the minute; Elapsed time | **new**; existing + *fold* (when does it end?) |
| 3.MD.A.2 | grams, kilograms, liters: measure, estimate, one-step stories | Grams and kilograms; Liters | existing; existing + *fold* (about how much it holds) |
| 3.MD.B.3 | read and draw scaled picture and bar graphs | Scaled picture and bar graphs; Draw a bar graph | existing; **new** |
| 3.MD.B.4 | measure to ½ and ¼ inch, make a line plot | Line plots with halves and fourths | existing + *fold* (the child makes the plot) |
| 3.MD.C.5a, b | area as unit squares | Area by counting squares | existing |
| 3.MD.C.6 | count unit squares (sq cm, m, in, ft) | Area by counting squares | existing + *fold* (unit names) |
| 3.MD.C.7a, b | tile it, then multiply the sides | Area by counting squares | existing |
| 3.MD.C.7c | a × (b + c) as area | Multiply by breaking apart | existing + *fold* (the floor of tiles) |
| 3.MD.C.7d | area of shapes made of rectangles | Area of L-shapes | **new** |
| 3.MD.D.8 | perimeter, a missing side, same perimeter different area | Perimeter; Same perimeter, different area | existing; **new** |
| 3.G.A.1 | quadrilaterals by their sides and corners | Quadrilaterals | existing + *fold* (make one that's none of these) |
| 3.G.A.2 | equal parts of a shape as unit fractions | Equal parts of a shape | **new** |

**Kept out, for clean grade lines.** From below (2nd grade): pairs up to 20 (Even and odd), arrays up to 5 × 5, time to 5
minutes, graphs with a scale of 1, line plots in whole units. From above: the column algorithm and rounding to any place
(4th), the "× top and bottom" rule for equal fractions and fractions with different tops and bottoms (4th), area and
perimeter formulas and g ↔ kg (4th), eighths and adding lengths on line plots (4th), the quadrilateral family diagram and
three numbers as a box of cubes (5th: Volume of a box is where 5.MD.C.5a shows grouping in 3D).

## Chapters (in teaching order)

| | Chapter | Lessons |
|---|---|---|
| 1 | Multiply and divide | Multiplication facts · Division facts · Find the missing number · Two-step word problems |
| 2 | Times-table tricks | Multiply by breaking apart · Multiply three numbers · Double a fact · Multiply by multiples of 10 |
| 3 | Place value | Rounding to 10 and 100 · Add and subtract within 1000 · Estimate to check |
| 4 | Shapes and area | Quadrilaterals · Area by counting squares · Area of L-shapes · Perimeter · Same perimeter, different area |
| 5 | Fractions | Equal parts of a shape · Unit fractions · Fractions on a number line · Equal fractions · Comparing fractions |
| 6 | Time and measuring | Time to the minute · Elapsed time · Grams and kilograms · Liters |
| 7 | Data | Scaled picture and bar graphs · Draw a bar graph · Line plots with halves and fourths |

Shapes and area comes before Fractions so Equal parts of a shape can open fractions with area the child can count. Data
comes last because line plots need fourths.

## What every 3rd grade lesson shares

- **Layout** as `README.md`: the instruction on rows 0–2 (words 28), a miss on rows 3–4 (20, red), the picture from row
  6 (its names on it, at its right end or along its sides), the record 3 rows under the picture (maths 36, 2 squares a
  digit), and the blocks under the record. The camera frames what's drawn now, at most 125%. It steps back only for the
  biggest problems, and the lesson says where. **A tall picture keeps its record beside it:** when the picture is more
  than 26 squares tall (the big arrays, Two-step's packs, Double a fact, the 40-square jug), the record starts on the
  block line a block right of it, one short line per step, so picture and record fit the 68 × 45 screen at 100%.
- **Words for an 8-year-old.** One short line, verb first ("Drag down to make 4 rows of 6."). A miss is measured on the
  grid ("That's 5 rows. 4 × 6 is 4 rows of 6."). The last line says why. Stories keep the web's words. A story sits over
  the picture with "Pick what to do" first, as 5th grade's stories do, and the picture draws the story's things.
- **Hands answer Core's steps.** A move sets its step's boxes (`LessonRun.set`) and checks them, so the web's checks and
  slip messages still apply. Typing is only for the number school writes. Steps the hands make pointless are dropped,
  and the paper adds a step only where a move needs one.
- **Things are dots in cells.** A cell is a whole number of squares, the same size for the whole problem, and an array
  starts on a block line. So every 5 things end on a strong line, whatever the cell size: Breaking apart's cut "after 5"
  always lies on one.
- **Square units are blocks.** In Area, L-shapes, Same perimeter and Equal parts of a shape, one square unit is one block
  (5 × 5 squares). The paper's strong lines are the tiles' edges, and a tile is drawn tinted, so what's counted is clear.
- **Easy first:** problems 1–3 come from each web generator's early branch. Show me and the How to play the move with a
  ghost finger and put everything back. Every lesson's maths gets Core tests.
- **A pick says what to do.** Where the web asks a yes/no or name question, the line is a verb ("Tap Yes or No: all 4
  sides the same?"), and the blocks sit on the picture's block lines, never as a list under it.
- **3D:** only the How to of Liters (the jug stands up and fills a liter at a time). Everything else in 3rd grade is
  flat: area, the grade's big measure, is flat, and three numbers as a box of cubes belongs to 5th grade.

### Hand moves

From the kit (`README.md`): **Ruler cut** (Breaking apart, Double a fact, L-shapes, Equal parts, Comparing fractions),
**Slide pieces** (Two-step, Add and subtract, Unit fractions, the mass and liter stories, Grams and kilograms' scales),
**Tap pieces** (Unit fractions, Equal parts, Quadrilaterals, Comparing fractions, graphs), **Tap a block on a line**
(Rounding), **Drag a point along a line** (Rounding, Estimate, Equal fractions, Time to the minute, graphs), **Hop along a
line** (Estimate, Unit fractions, Fractions on a line, Elapsed time, Grams and kilograms, Liters, Line plots), **Drag a
rectangle's edge or corner** (Multiplication facts, Division facts, Missing number, Two-step, Multiples of 10, Area, Same
perimeter, Draw a bar graph), **Tap the part that goes first** (Multiply three numbers), **Cover the floor**, flat (Area),
**Adding decimals' tap a full ten to close it** (Add and subtract), picks on blocks (as a story's "Pick what to do"), and
**Write**.

New (each comes with the lesson that needs it, and G sees it first):

| New move | What it does | Used by |
|---|---|---|
| **Turn a quarter** | Grab a picture's corner and swing it round its middle; it snaps at a quarter turn; the readout names rows and columns ("6 rows of 4"). | Multiplication facts |
| **Open a ten** | Tap a disk of the next place up: it opens into ten of this place (closing a full ten, backwards). | Add and subtract (taking away) |
| **Trace the edge** | Drag a point around a shape's outline: it snaps to each cm tick and turns the corners, and each side's length joins a sum in the readout ("7 + 4"). | Perimeter |
| **Move a corner** | Drag one corner of a shape to another grid crossing. Its sides re-measure, and its square corners and parallel sides mark themselves as it moves. | Quadrilaterals (make one) |
| **Place an X** | LESSONS.md's "place a point": tap above a mark on a line and an X stacks there. 5th grade's new graphing lesson uses the same move on the plane. | Line plots |
| **Turn a clock hand** | Drag the long hand round the face. It snaps to minute marks, the short hand creeps with it, and the readout says the time ("4:23"). | Time to the minute |

---

## 1 · Multiply and divide

### Multiplication facts (`g3-facts`) · 3.OA.A.1, 3.OA.B.5 (turn-around), 3.OA.C.7
**One square:** a thing is a dot in a cell 4 squares wide, or 3 when a side is 7 or more. 4 × 6 is then 16 × 24 squares
and the biggest, 10 × 9, is 30 × 27. **Picture:** the array from row 6, its cells faint over the paper. `6` sits over
the first row, the only row drawn, and `4` runs down the left side as an open bracket for the rows still to make.
1. "Drag down to make 4 rows of 6." The bottom edge snaps a row at a time (Drag a rectangle's edge); readout "3 rows of
   6". Released on 3 or 5: "That's 5 rows. 4 × 6 is 4 rows of 6." Right: the bracket closes on 4.
2. "Count by 6s." The rows light one by one and write 6, 12, 18 at their right ends (See); the last count is the
   child's: **Write** `6, 12, 18, [24]` (a long list keeps its first two and last two, as the web does). `4 × 6 = 24` is
   written under it.
3. "Turn it." Drag the corner round (Turn a quarter): the same dots swing about the middle and settle as 6 rows of 4,
   with no dot added or taken away, then slide so the top-left corner is back on its block line (so 5 dots still end
   on a strong line). Readout "6 rows of 4". **Write** `6 × 4 = [24]`. A square (6 × 6) has no turn step.

**Say:** "Same dots, turned: 4 × 6 = 6 × 4."
**Core:** `a`, `b`. Early: b is 2, 5 or 10 and a is 3–6 (3, 4 or 6 when b is 5). Then a 2–10, b 3–9, with a square
redrawn 6 times in 10. Steps: rows (set by the drag; a paper step), count (typed; slips: counted on by 1, one jump short,
one too many, added), turn (typed; slips: added, b × b). Story: boxes of crayons, the rows drawn as boxes. Check: the
spec's (i3 a ≠ b; i3 a, b ≥ 6, a ≠ b; i3 a ≠ b; i3 story).

### Division facts (`g3-divfacts`) · 3.OA.A.2, 3.OA.B.6, 3.OA.C.7 · *fold:* groups of b
**One square:** a thing is a dot in a 3-square cell. **Picture:** on the left the pile of `a`, in rows of 10 (30 squares
wide, up to 27 tall), with `24` over it. On the right, a block away, the rows to fill (up to 30 × 30), so the two fill
the screen's width (65 squares).
- **Share (the web's):** 4 empty rows, with `4` down their left side.
  1. "Drag across to share 24 into 4 rows." The rows' right edge snaps a column at a time; each column takes one dot for
     every row, sliding across from the end of the pile. Readout "3 in each · 12 left". Let go short: "4 × 5 = 20.
     4 are left. Keep going." Past: "4 × 7 = 28. That's more than 24." (the web's slips). Right: the pile is empty and
     each row's end says 6.
  2. `4 × 6 = 24` is written (set by the drag). **Write** `24 ÷ 4 = [6]`.
- **Groups of b (fold):** "Put 24 in groups of 4." The rows are 4 wide, with `4` over the top. 1. "Drag down to make
  groups of 4": each new row takes 4 from the pile; readout "3 groups · 12 left". 2. `6 × 4 = 24`; **Write**
  `24 ÷ 4 = [6]`.

**Say:** "4 rows of 6 make 24, so 24 ÷ 4 = 6." / "6 groups of 4 make 24, so 24 ÷ 4 = 6."
**Core:** `a`, `b`, kind. Early: b is 2, 5 or 10, the answer 2–6, share only. Then b 3–9, the answer 2–10; groups of b
half the time (new). Steps: think (set by the drag; a release one column off says the web's slip, "4 × 7 = 28. That's
more than 24."), divide (typed; slips: wrote the groups, multiplied). In groups of b the "wrote the groups" slip is
turned round: "4 is how many in each pack. How many packs?". Story: the web's (shared by friends); groups of b
gets "24 stickers go in packs of 4. How many packs?". Check: the spec's, with its plain i3 made `i3 where kind = groups`.

### Find the missing number (`g3-unknown`, new) · 3.OA.A.4, 3.OA.B.6
**One square:** as Multiplication facts. **Picture:** the equation is the array's own names: rows down the left, how
many in each over the top, and the total in a bracket on the right. The missing one is an empty box where its name goes.
Four forms: `8 × ? = 48`, `? × 6 = 48`, `48 ÷ ? = 6`, `? ÷ 3 = 5`. From problem 4, the total is sometimes written first
(`48 = 8 × ?`, `5 = ? ÷ 3`), so "=" reads both ways.
1. A missing side: "Drag the side until it holds 48." The open edge snaps a row or column at a time; readout "8 rows of
   5 · 40". Let go on the wrong size: "8 rows of 7 is 56. That's more than 48." Right: the bracket closes on 48.
   A missing total (`? ÷ 3 = 5`): "Drag down to make 3 rows of 5." The rows then count by 5s (See).
2. **Write** the box in the equation: `8 × [6] = 48`. The matching fact is written under it: `48 ÷ 8 = 6` (or
   `3 × 5 = 15`, under `[15] ÷ 3 = 5`).

**Say:** "8 rows of 6 make 48." / "÷ is a times fact backwards."
**Core:** new. `a` (rows), `b` (in each row), form 0–3, flipped. a and b are 2–10. Early: forms `a × ? = c` and
`? ÷ a = b` only, with one number 2, 5 or 10. Then any form, flipped half the time. Slips: a missing side (subtracted:
48 − 8; wrote the total; one more or one fewer); a missing divisor (subtracted 48 − 6, multiplied, wrote 6); a missing
total (added 3 + 5, subtracted, a row short or extra). Check: i3 `a × ? = c`; i3 `c ÷ ? = b`; i3 `? ÷ a = b`; i3 flipped.

### Two-step word problems (`g3-twostep`) · 3.OA.D.8 · *fold:* the equation with a letter
**One square:** a thing is a dot in a 3-square cell, as Division facts (9 packs of 9 is 27 × 27; a pile of 87 is 30 × 27).
**Picture:** the story on the top rows (the web's lead), with no other problem line. The story's groups (packs, boxes,
bags, trays) are outlined round their rows.
- **Then fewer** (Mia has 4 packs of 6 stickers. She gives 5 away.) 1. "Drag down to make 4 packs of 6." Readout "3
  packs · 18". **Write** `4 × 6 = [24]`. 2. "Slide 5 away." A block of 5 stickers waits beside the packs; slid over the
  last ones, it crosses them out from the end. Readout "19 left". **Write** `24 − 5 = [19]`.
- **Then more** (… and 5 more stickers): step 2 slides the 5 in after the last sticker, and the count runs up.
  `24 + 5 = [29]`.
- **Then share** (Leo has 32 crayons. He loses 5. He shares the rest into 3 boxes.): the pile of 32. 1. "Slide 5 away."
  `32 − 5 = [27]`. 2. "Drag across to share them into 3 boxes" (as Division facts). `27 ÷ 3 = [9]`.
3. (fold) "Tap the one that tells the story." Three blocks, for example `4 × 6 − 5 = s`, `4 × 6 + 5 = s` and
   `4 + 6 − 5 = s`; for sharing, `(32 − 5) ÷ 3 = c`, `(32 + 5) ÷ 3 = c` and `(32 − 5) × 3 = c`. Wrong: "+ 5 is getting
   more. She gives 5 away." / "4 + 6 adds packs to stickers. 4 packs of 6 is 4 × 6." The record writes it, then
   `s = 19`, with "s: stickers left" small under it.

**Say:** "The first answer starts the second step."
**Core:** `kind`, `a`, `b`, `c`, `who` (Mia, Leo, Ava, Sam; the letter is the things' first letter). The kind is random,
0–2. Early: 2–5 groups of 2, 5 or 10, c up to 9; sharing into 2 or 5, each getting 2–5, c 2–9. Then 2–9 groups of 3–9,
c up to 20 (less than the total); sharing into 3–8, each getting 2–9, c 2–15. Steps: groups/left and change/share (typed,
the web's slips: one group short or extra, took 5 from every pack, added instead, too many in each…), and the equation
(pick, new). Check: the spec's (i3 kind 0, 1, 2, 2).

## 2 · Times-table tricks

### Multiply by breaking apart (`g3-split`) · 3.OA.B.5 (distributive), 3.MD.C.7c · *fold:* the floor of tiles
**One square:** a thing is a dot in a 3-square cell (9 × 9 is 27 × 27 squares). **Picture:** the array, with `7` down
the left and `8` over the top.
1. "Cut after 5." This is the cut of Multiply two-digit numbers: a handle on a stem over the top edge, dragged along and
   snapping between things. A dashed cut runs down the array and the two widths ride over it, "5 | 3". Five things are
   15 squares, so the right cut lies on a strong line. Elsewhere: "4 | 4. Cut after 5: 5s are easy." Right: the cut
   turns solid and the 3 part glides a square away.
2. The 5 part lights: **Write** `7 × 5 = [35]`, also written on the part. Then the 3 part: `7 × 3 = [21]`.
3. The parts glide back together: **Write** `35 + 21 = [56]`. The record reads
   `7 × 8 = 7 × 5 + 7 × 3 = 35 + 21 = 56`.

**Say:** "7 rows of 5 and 7 rows of 3 make 7 rows of 8."
**Floor (fold, 3.MD.C.7c, from problem 4, one in three):** the same numbers as a floor of tiles: each 3-square cell is a
tinted tile instead of a dot, the sides named `7 ft` and `8 ft`. The cut, the two parts and the record are the same,
with "square feet" after the total. Say: "7 × 8 tiles is 7 × 5 tiles and 7 × 3 tiles."
**Core:** `a`, `b`, floor (new; a flag, no change to the maths). Early: a 2–5, b 6 or 7. Then a 3–9, b 6–9. Steps: split
(set by the cut), five, rest, sum (typed; slips: added instead, kept only one part, a × b + a). Story: bags of apples.
Check: the spec's.

### Multiply three numbers (`g3-three`, new) · 3.OA.B.5 (grouping)
**One square:** a thing is a dot in a cell a block wide (5 squares) when a row holds 10 or fewer, so each group's
outline lies on the strong lines; 4 squares when a row holds 12 or 15. **Picture:** `3 × 5 × 2` is written big over the
picture (the record's first line). Under it, 3 rows of 5 groups of 2, each group outlined bold: 3 × 5 × 2 is 15 × 50
squares, the biggest, 5 rows of 10 (5 × 5 × 2), is 25 × 50, and the widest, 4 rows of 15 (4 × 5 × 3), is 16 × 60. It
stays flat on purpose; three numbers as a box of cubes is 5th grade's.
1. "Tap the two to do first." (Tap the part that goes first: either pair is right.) For `5 × 2`, each row's groups join
   into one long group of 10 and the outlines between them fade. For `3 × 5`, the groups number 1 to 15 across the rows.
2. **Write** the pair, `5 × 2 = [10]`, then the rest, `3 × 10 = [30]`. The record reads `3 × (5 × 2) = 3 × 10 = 30`.
3. The other way plays (See): the picture regroups, and `(3 × 5) × 2 = 15 × 2 = 30` is written under the first line.

**Say:** "Either two first: 30 both ways."
**Core:** new. `a` (rows), `b` (groups in a row), `c` (in a group), each 2–5. Early: b and c are 5 and 2 (either way
round), a 2–4. Then any three with a product of 60 or less and b × c at most 15 (so a row is never more than 60
squares; 20 in a row would be a thin strip 9 squares tall). The tap passes for either pair. Slips
(the total): added all three, multiplied two and stopped, a × c. Check: i3 where b × c = 10; i3 where a × b = 10; i3
where the product is 40 or more; i3.

### Double a fact (`g3-double`, new) · 3.OA.D.9 (why 4 × any number is even), 3.OA.B.5, 3.OA.C.7
**One square:** a thing is a dot in a 4-square cell, so the halves are big enough to see side by side (4 × 7 is 16 × 28
squares; the biggest, 8 × 9, is 32 × 36). **Picture:** `4 × 7` as 4 rows of 7, with `4` down the left and `7` over the
top.
1. "Cut it into two equal halves." The ruler's handle runs down the left side and the cut snaps between rows; readout,
   the dots on each side, "14 | 14". Unequal: "21 and 7 aren't equal. Find the middle." Right: the halves part a
   square, each named `2 × 7`.
2. **Write** one half, `2 × 7 = [14]` (a fact already known); both halves light.
3. **Write** the double, `14 + 14 = [28]`. The record reads `4 × 7 = 2 × 7 + 2 × 7 = 14 + 14 = 28`.
4. "Tap Even or Odd." (Two blocks beside 28.) Odd: "Two equal halves and no dot left over: even." Then the fact's row of the times table
   writes itself under the record in the chapter colour (for 4 × 7, `4, 8, 12, 16, 20, 24, 28, 32, 36, 40`; for 6s and
   8s their own row): every one even.

**Say:** "Two equal halves: every 4s fact is even." (6s and 8s: the same words with their number.)
**Core:** new. `h` (rows in a half: 2, 3 or 4, so the fact is 4s, 6s or 8s) and `n`. Early: h = 2 (4s from 2s), n 2–5.
Then h 2–4, n 3–9. Steps: halves (set by the cut), half, double (typed), even (pick). Slips: added (2 + 7), one half
only (14), doubled wrong. Check: i3 where h = 2; i3 where h = 3; i3 where h = 4; i3 where n is odd.

### Multiply by multiples of 10 (`g3-mult10`) · 3.NBT.A.3
**One square:** a square is one; a ten is a ten-frame, 2 rows of 5 squares, a block wide, so each ten sits between strong
lines. **Picture:** `4 × 30` as rows of 3 tens. Each row is 2 squares tall with a square between rows (9 rows of 9 tens
is 45 × 26). `3 tens` is over the first row and `4` down the left.
1. "Drag down to make 4 rows of 3 tens." (As Multiplication facts.) Readout "4 rows · 12 tens". **Write**
   `4 × 3 = [12]`.
2. With ten tens or more, ten of them fold into a hundred (See): ten frames close into a 10 × 10 square of 100 squares,
   hundreds in rows of four. The tens left over sit beside them: "1 hundred and 2 tens".
3. **Write** `4 × 30 = 12 tens = [120]`.

**Say:** "12 tens is 120: tens count like ones."
**Core:** `a`, `t`. Early: a and t ÷ 10 are 2–5; then 2–9. Steps: rows (set by the drag; a paper step), fact (typed;
slip: added), tens (typed; slips: forgot they're tens, one zero too many, added). Story: boxes of pencils. Check: the
spec's.

## 3 · Place value

### Rounding to 10 and 100 (`g3-round`) · 3.NBT.A.1
Rounding decimals' design (the test page's), with whole numbers. **One square:** line 1 and line 2 are each ten blocks,
50 squares. **Picture:** line 1 is the hundred the number is in, a block a ten, when rounding to tens (0 to 100 for a
two-digit number). When rounding to hundreds it's 0 to 1000, a block a hundred. The number's point sits over it.
1. "Round 347 to the nearest ten. Tap the block it's in." It lights and opens below (dashed) into line 2, ten blocks
   again: 340 to 350, a block a one (or 300 to 400, a block a ten, for hundreds). The point is on it. Wrong block: "347
   is between 340 and 350."
2. "Drag the point to the end it's closer to." As it moves, a bracket shows how far it is to each end ("3 to 350");
   halfway, the middle strong line, is marked. Wrong end: "That end is 7 away. The other end is 3." Halfway: "Exactly
   halfway rounds up."
3. **Write** `347 ≈ [350]`. Then the rule as record: the place's digit underlined, the next one ringed, "7 is 5 or more:
   round up".

**Say:** "3 to 350, 7 to 340. 350 is closer."
For hundreds, the point on line 2 sits inside its ten (347 is 23½ squares along), as the point does on Rounding
decimals' line 1. The bracket says how far in ones: "53 to 400, 47 to 300".
**Core:** `n`, `to`. Early: two-digit numbers to the nearest ten. Then three-digit numbers to 10 or 100 (a coin toss), a
quarter of them exactly halfway. Steps: between (set by the tap; slips: used tens when rounding to 100, one step too low
or high), mid and round (set by the drag; halfway is the mid), the record's box (typed; slips: the other end, rounded to
the ten). Check: the spec's.

### Add and subtract within 1000 (`g3-addsub`) · 3.NBT.A.2
**One square:** a disk is a 3-square cell. **Picture:** the place chart: hundreds | tens | ones, each column 15 squares
(3 blocks) wide, a block apart, 55 squares in all. Each column holds disks in ten-frames, 2 rows of 5, two frames deep,
and a disk says what it's worth (100, 10, 1). The first number's disks fill the top, with `458` over them. The second
number's disks wait under their columns, with `+ 275` beside them (striped, for take away).
Each place in turn, biggest first, as the web's jumps:
1. "Slide in the hundreds." (Slide pieces: they snap in after the column's disks.) Readout, the chart's number now:
   "658". **Write** `458 + 200 = [658]`.
2. "Slide in the tens." The column holds 12 and its full ten-frame glows. "Tap the full ten": it closes into one hundred
   disk and slides to the hundreds (Adding decimals' carry). **Write** `658 + 70 = [728]`.
3. The ones, the same way: **Write** `728 + 5 = [733]`.

Taking away: the striped disks slide over the column's disks from the right, crossing them out. Too few: "There are only
2 tens. Open a hundred." (Open a ten: tap a hundred disk and it opens into ten tens.) Dropped on the wrong column: "Tens
go with tens." Going on past a full ten: "10 ones make a ten. Tap the full ten."
**Say:** "Ten of one place make one of the next." (No trades: "Hundreds, tens and ones, each on its own.")
**Core:** `a`, `b`, `s`. Early: b is two-digit. Then b is three-digit, hundreds 1–6. b never has a zero digit. The answer
is 1–999 (the web keeps a + b at 999 or less), so three columns always hold it. Steps: one per place (typed; the web's slips: jumped 2 instead of 200,
went the wrong way, lost the new ten or hundred, took the smaller from the bigger, forgot the trade). Stories: books (+),
apples (−). Check: the spec's.

### Estimate to check (`g3-estimate`, new) · 3.OA.D.8 (is it reasonable?), 3.NBT.A.1, 3.NBT.A.2
**One square:** the line runs 0 to 1000 in ten blocks of a hundred (50 squares; a square is 20). **Picture:** the
problem and a friend's answer on the top rows: "Leo says 458 + 275 = 633." The two numbers are points on the line, as on
Rounding's line 1.
1. "Drag each number to its nearest hundred." Two drags; how far to each end shows as each moves. Wrong end: "458 is 42
   from 500 and 58 from 400."
2. "Hop 300 on from 500." Hops of 100, a block each, counted 1, 2, 3. **Write** `500 + 300 = [800]`. Taking away, the
   hops go back ("Hop 300 back from 500").
3. Leo's answer drops onto the line as a point. A band 100 each side of 800 shades in (See: "Each number moved 50 or
   less, so the answer is in here."), and a bracket shows how far Leo's point is from 800 ("167"). "Tap Yes or No:
   could Leo be right?" Wrong: "633 is 167 from 800. That's outside." / "733 is only 67 from 800. It could be right."

The record: `458 + 275 ≈ 500 + 300 = 800`, then "633 is too far from 800."
**Say:** "About 800, so 633 can't be right." / "About 800, so 733 could be right."
**Core:** new. `a`, `b`, `s` from Add and subtract's generator (b three-digit), `f` (the friend's answer), `who` (the
mass stories' names). The estimate rounds both to hundreds, so the real answer is always within 100 of it (each number
moves 50 or less). Half the time f is right. Otherwise it's one of Add and subtract's slips (lost the new hundred, forgot
the trade, jumped 2 for 200, added instead) or the real answer ± 200, redrawn until it's at least 150 from the estimate,
so a wrong answer is always clearly outside the band. Early: f 300 or more from the estimate. Check: i3 where f is right; i3 where f is wrong; i3 where s = −1; i3 where f is wrong and s = −1.

## 4 · Shapes and area

### Quadrilaterals (`g3-quads`) · 3.G.A.1 · *fold:* make one that's none of these
**One square:** a square is a unit of length. **Picture:** the shape big, about 40 × 30 squares, its corners on grid
crossings and every side a whole number of squares. Turned shapes run along 3-4-5 steps (about 37° or 53°, either way),
so a slanted side of 5, 10 or 15 squares is still measured on the grid. The web's six: square, rectangle, rhombus,
parallelogram, trapezoid, other.
1. (problems 1–3) "Tap each side." Each lights and counts: "4 sides."
2. "Tap the square corners." A paper corner lays itself in each tapped corner. If it fits, a small square marks the
   corner; if not, the gap shows. Readout "2 square corners". Wrong: "That corner is wider than a square corner."
   **Done** with one missed: "One more corner fits a paper corner."
3. "Tap each side to measure it." A strip of squares lays along it and writes its length; sides that match get the same
   tick mark, the way school marks them. "Tap Yes or No: all 4 sides the same?"
4. "Tap two sides that never meet." Their lines run on across the paper, dashed. Parallel ones stay the same number of
   squares apart all the way and get matching arrowheads (one for the first pair, two for the second, as 5th grade's
   Sorting shapes). Others close in and cross, measured: "They close in: 10 squares apart here, 6 there." **No more**
   when done ("There's another pair that never meets."); the taps answer how many pairs (0, 1 or 2), so there's no
   number to pick.
5. "Tap its most special name." Six blocks, with the web's slips ("A rectangle needs 4 square corners. This one
   leans.").
6. (every 4th problem, a square or a rectangle) "Tap Yes or No: is this square also a rectangle?" Yes. For a rectangle:
   "…is this rectangle also a square?" No ("A square needs 4 equal sides. These aren't all equal.").

**Make one (fold, problems 7, 15, …):** a square, and "Drag a corner. Make a 4-sided shape that isn't a square, rectangle
or rhombus." (Move a corner: its marks redraw as it moves.) Still one of them: "It's still a rectangle: 4 square
corners." Crossed sides: "The sides cross. Keep 4 sides." Then its name, as step 5.
**Record:** `4 sides · 0 square corners · 2 pairs of parallel sides: parallelogram`.
**Say:** the web's line for the shape ("2 pairs of parallel sides, but no square corners."). One change, so 3rd grade
agrees with 5th grade's Sorting shapes (where a parallelogram is also a trapezoid): the trapezoid's line is "Only 1
pair of parallel sides: its most special name is trapezoid." instead of the web's "Exactly 1 pair of parallel sides
makes a trapezoid." The answers don't change: the most special name is the same under both meanings.
**Core:** shape, turn (random from problem 4, from the 3-4-5 set), warm (problems 1–3), also (index % 4 = 3), make (new,
index % 8 = 6). Each shape's corners are listed in squares (the web's pixel sizes become grid corners); the corners and
parallel steps are set by the taps (a wrong count is caught as the web's slip when **Done** or **No more** is tapped);
the web's classify and name slips. Check: the spec's (i3 also; i4 rhombus; i8 trapezoid; i9 parallelogram).

### Area by counting squares (`g3-area`) · 3.MD.C.5, 3.MD.C.6, 3.MD.C.7a, b · *fold:* unit names
**One square:** one square unit is one block, a tile. **Picture:** the rectangle's outline on strong lines, `7` blocks
across and `4` down, with its sides named. Up to 10 × 8 is 50 × 40 squares: 7 or 8 rows are seen at about 80%, and 4
rows or fewer at 100% or more.
1. "Drag across the top row to tile it." (Cover the floor, flat.) Tiles drop into the blocks, counting; readout "5
   tiles". Short: "The row has 7. Keep going."
2. "Drag the row down." (Drag a rectangle's edge.) Rows of 7 fill down and count by 7 at the right end (7, 14, 21, 28).
   Readout "3 rows of 7".
3. **Write** `4 × 7 = [28]` square units.

**Say:** "4 rows of 7 tiles: 28 square units."
**Fold:** from problem 4, a problem names a unit in turn, a rug "7 ft by 4 ft" and so on (sq cm, m, in, ft). The tiles
are then "square feet".
**Core:** `l`, `w`. Early: l 3–5, w 2–4. Then l 3–10, w 2–8. Steps: row and rows (set by the two drags), area (typed;
slips: the perimeter, "22 is the distance around. Area counts the tiles inside."; added; missed a row). Check: the
spec's.

### Area of L-shapes (`g3-lshape`, new) · 3.MD.C.7d
**One square:** one square unit is one block, as Area. **Picture:** an L: a W × H rectangle with a w × h corner missing
(up to 10 × 8 blocks), every side named with its length.
1. "Cut it into two rectangles." The ruler runs along a block line from the inside corner; across or down both work.
   Readout: the parts' sides, "4 × 3 | 5 × 6". A cut that leaves an L: "That leaves an L. Cut from the inside corner."
   Right: the parts glide a square apart.
2. **Write** each part's area, `4 × 3 = [12]` and `5 × 6 = [30]`; each part tiles itself as it's written.
3. The parts glide back: **Write** `12 + 30 = [42]` square units. The record reads `4 × 3 + 5 × 6 = 12 + 30 = 42`.

**Say:** "Two rectangles: add their areas."
**Core:** new. `W`, `H`, `w`, `h`, the corner. Early: W 5–7, H 4–5, a 2 × 2 or 2 × 3 corner off the top right. Then W
5–10, H 4–8, w 2 to W − 2, h 2 to H − 2, any corner, area 80 or less; from problem 7, one side is left unnamed and the
cut finds it ("8 − 3 = 5"). Slips (the total): the whole rectangle ("That counts the missing corner too."), one part
only, the perimeter. Check: i3; i3 where the corner isn't top right; i3 where W is 8 or more; i3 with a side unnamed.

### Perimeter (`g3-perim`) · 3.MD.D.8 (from the side lengths)
**One square:** a centimetre is 3 squares, and the shape is drawn true size (15 × 10 cm is 45 × 30 squares; a 12 cm
square is seen at about 90%). **Picture:** the shape with the web's labels: two sides of a rectangle, one side of a
square, all three of a triangle. A triangle's corners sit on the grid crossings nearest its true shape; its labels carry
its lengths.
1. "Trace around the edge." (Trace the edge.) From the top left corner, the point snaps to each cm tick and turns the
   corners. Each side lights as it's walked and joins the readout's sum, "7 + 4". An unnamed side gets its label as it's
   walked: "7 cm, like the top". Stopping loses nothing; the walk goes on from there.
   Rectangle: after two sides, **Write** `7 + 4 = [11]`, then walk the other two. Square: walking all four answers "how
   many sides are 5 cm". Triangle: after two sides, `9 + 7 = [16]`.
2. **Write** the total: `7 + 4 + 7 + 4 = [22] cm` (`16 + 6 = [22] cm` for the triangle).

**Say:** "All the way around: every side counts once."
**Core:** kind, `a`, `b`, `c`. Early: rectangles 3–9 by 2–6. Then rectangle, rectangle, square or triangle: rectangles
3–15 by 2–10, squares 2–12, triangles 5–14 with sides 4–12, not too flat. Steps: two or count (typed; set by the walk for
the square), around (typed; slips: multiplied, only two sides, missed a side, found the area). Check: the spec's.

### Same perimeter, different area (`g3-perimarea`, new) · 3.MD.D.8 (a missing side; equal perimeters, different areas; equal areas, different perimeters)
**One square:** one unit is one block, so the fence is counted along block edges (a tick on each strong line) and the
area in tiles. **Picture:** one rectangle (the longest, 2 × 12 tiles, is 60 × 10 squares; the tallest, 6 × 6, is
30 × 30). Its readout shows both measures at once: "fence 16 · area 15".
- **A missing side:** "The fence is 24 m. One side is 8 m." 1. "Drag the other side." Readout "8 + 3 + 8 + 3 = 22". Let
  go wrong: "That fence is 22. It needs 24." 2. **Write** `8 + [4] + 8 + 4 = 24`.
- **Same fence:** "Make a garden of 15 square m with a 16 m fence." 1. "Drag the corner." The fence stays 16, so the
  corner slides on a slant (one side longer, the other shorter), snapping to whole blocks. Readout "7 by 1 · area 7", "6
  by 2 · area 12", "5 by 3 · area 15". 2. **Write** `5 × 3 = [15]`. 3. The record lists every garden this fence makes
  (`7 × 1 = 7`, `6 × 2 = 12`, `5 × 3 = 15`, `4 × 4 = 16`) and rings the one made (See).
- **Same tiles:** "Make 12 tiles into a rectangle with a fence of 14." 1. "Drag the corner." The tiles regroup, snapping
  only where they make a rectangle with sides of 2 or more (2 × 6, 3 × 4); readout "2 by 6 · fence 16". 2. **Write**
  `3 + 4 + 3 + 4 = [14]`.

**Say:** "Opposite sides match: 8 + 4, twice, is 24." / "Same fence, different gardens." / "Same tiles, different fences."
**Core:** new. kind, `P` (even, 12–24), `A` (12, 16, 18, 20 or 24), the sides. Early: missing sides, fences of 20 or
less. Then the three kinds in turn. A same-fence target is the square at most one time in four; a same-tiles rectangle
starts as a different pair from the target. Slips: P − l (took one side off: "24 − 8 is the other three sides."),
P − 2 × l (forgot to halve: "8 is both short sides. Each one is 4."), P ÷ 2 (half the fence: "12 is one long and one
short side."); the fence written for the area, the area for the fence. Check: i3 missing side; i4 same fence; i5 same tiles; i6 missing side.

## 5 · Fractions

### Equal parts of a shape (`g3-shapeparts`, new) · 3.G.A.2, 3.NF.A.1
**One square:** one square unit is one block. **Picture:** a rectangle of 12 to 48 tiles (up to 8 × 6 blocks), its tiles
faint.
- **Strips:** 1. "Cut it into 4 equal parts." The fractions ruler, with one change: here the handle snaps at every
  tile line (not only to sizes that fit), because whether the parts come out equal is the lesson. While dragging, the
  cuts repeat across the shape at that size and each part shows its squares (a shape 4 tiles across and 6 down: readout
  "2 parts of 12"). Let go on equal parts of the wrong number: "That's 2 equal parts. Cut 4." On a size that leaves a
  short end: "The last part is 6 squares. The others are 18." Right: the cuts turn solid, the readout says "fourths: 6 squares each",
  and each part counts its squares. 2. "Tap one part." It lifts a little. **Write** `1 part = [1]/[4]` of the shape.
- **Other shapes:** the rectangle comes already cut into parts that look different. 1. "Tap each part." Its squares count
  ("6"). 2. "Tap Yes or No: are the parts equal?" One problem in four isn't. Yes: **Write** `each part = [1]/[4]`.
  No: "6, 6, 5 and 7 squares: not fourths."

**Say:** "4 equal parts: each is 1/4 of it." / "Different shapes, same area: each is 1/4."
**Core:** new. `W`, `H`, `b` (2, 3, 4, 6, 8, dividing the tiles), kind, the parts. Odd shapes are built by joining strips
and squares to equal sizes; an unequal set moves one square across. Early: strips into 2, 3 or 4. Then up to eighths,
other shapes half the time. Slips: flipped (4/1), counted the cuts (1/3); 6/24 gets the equal-fraction nudge ("That's
the same amount. Write it as 1 part of 4."). Check: i3 strips of sixths or eighths; i3 other shapes, equal; i3 other
shapes, not equal; i3.

### Unit fractions (`g3-unitfrac`) · 3.NF.A.1
**One square:** this is the fractions family's bar: a whole is 48 squares long and 4 tall, so a half to an eighth is 24,
16, 12, 8 or 6 squares. **Picture:** the bar from row 8, cut into `b` parts with `k` shaded in the chapter colour. It has
no name yet; that's the question.
1. "Tap each part to count it." Each part numbers as it's tapped; readout "4 parts". Check too soon: "Count every part,
   shaded or not."
2. "Slide one part up." Any part will do (they're all the same): it lifts, its place stays dashed. **Write**
   `1 part = [1]/[4]`.
3. (2 or more shaded) "Hop it along the shaded parts." (Hop.) Each hop lays the piece on the next shaded part, counting
   1, 2, 3. Past the shading: "That's past the shading." **Write** `shaded = [3]/[4]`. Then the shaded parts are named
   1/4, 2/4, 3/4 (See).

**Say:** "3 pieces of 1/4 make 3/4."
**Core:** `b`, `k`. Early: 2, 3 or 4 parts, one shaded. Then 3, 4, 6 or 8 parts, one shaded about a third of the time.
Steps: parts (set by the taps), one and shaded (typed; the web's slips: flipped, counted the other parts, shaded over
not shaded, named one part; the equal-fraction nudge). Check: the spec's.

### Fractions on a number line (`g3-fracline`) · 3.NF.A.2a, b
**One square:** the line is 48 squares long. 0 to 1 is a whole of 48 (ticks every 6 to 24 squares); 0 to 2 has a whole
of 24 (ticks every 4 to 8: the web's lines to 2 use thirds, fourths and sixths only). **Picture:** the line on row 14, the point a dot on its tick, unnamed.
1. "Hop from 0 to 1." Hops snap to the ticks; readout "4 hops". Short: "Hop all the way to 1."
2. "Hop from 0 to the point." Readout "3 hops". Past it: "That's past the point."
3. **Write** `point = [3]/[4]`. Then every tick is named, 1/4, 2/4, 3/4, 4/4 (See).

**Say:** "3 hops of 1/4 land on 3/4." (Past 1: "5 hops of 1/4: past 1, because 5 is more than 4.")
**Core:** `a`, `b`, `w`. Early: halves, thirds or fourths, 0 to 1. Then thirds, fourths, sixths or eighths, with a line
to 2 three times in ten when b is 6 or less. Steps: spaces and jumps (set by the hops; hops can't count the ticks), name
(typed; slips: flipped, used the ticks, used all the spaces to 2). Check: the spec's.

### Equal fractions (`g3-equiv`, new) · 3.NF.A.3a, b, c
**One square:** a whole is 48 squares, as Fractions on a number line. **Picture:** two lines, 0 to 1, one over the other
6 rows apart. The top is cut in `b` with its point at `3/4`, named. The bottom is cut in `d`, with a point at 0.
- **Same point:** 1. "Drag the point under 3/4." It snaps to the bottom's ticks, and a dashed line drops from the top
  point as it nears; readout "5 eighths". Wrong: "That's 5 eighths. 1 more." / "That's past it." 2. **Write**
  `3/4 = [6]/[8]`. Both points ring, and the eighths show 2 under each fourth (See).
- **Wholes (3.NF.A.3c):** one line, 0 to 2 with a whole of 24 squares, cut in halves to sixths; the point sits on 1 or
  2. 1. "Hop from 0 to the point": "8 hops". 2. **Write** `2 = [8]/[4]`. In wholes (0 to 4, 12 squares each):
  `3 = [3]/[1]`.

**Say:** "Same point, so 3/4 = 6/8." / "4 fourths make a whole, so 8 fourths make 2."
**Core:** new. Same point: `a`, `b`, `d`, with b and d from 2, 3, 4, 6 and 8, one 2, 3 or 4 times the other (2 and 4,
2 and 6, 2 and 8, 3 and 6, 4 and 8, either on top), and a/b landing on a tick of d. Wholes: `n`, `b`. Early: halves and
fourths, same point. Then wholes one problem in four. Slips: kept the top (3/8), flipped, counted the ticks. Check: i3
same point, bottom cut smaller; i3 same point, bottom cut bigger (4/8 = 1/2); i3 wholes; i3 thirds and sixths.

### Comparing fractions (`g3-fraccompare`) · 3.NF.A.3d
**One square:** two bars, the same whole of 48 squares, 2 squares apart. **Picture:** each bar named at its right end,
with the sign's place between the names.
- **Same bottom:** 1. "Tap the one with more pieces." Its shaded pieces number. Wrong: "3/8 is only 3 pieces. 5/8 is 5
  of the same size."
- **Same top:** 1. The two pieces, 1/4 and 1/8, lift out over the bars, side by side, their real sizes (12 and 6
  squares). "Tap the bigger piece." Wrong: "8 is bigger than 4, but 8 pieces in a whole are smaller pieces."
- **The same amount:** 1. "Drag the ruler to cut both into eighths." (Adding fractions' ruler.) Readout "eighths: 2 in
  each fourth".
2. "Tap the sign." (<, =, >, picked.) Then the shading's ends drop dashed lines across the other bar (See): the longer
   shading is the bigger, and the extra is outlined. The record reads `3/8 < 5/8`.

**Say:** "5/8 reaches further, so it's bigger." / "Fewer pieces in a whole, bigger pieces." / "The shading ends in the
same place."
**Core:** `a`, `b`, `c`, `d`. Early: same bottom. Then same bottom 40%, same top 42%, same amount 18%. Steps: more/size
(set by the tap), fit (set by the ruler), compare (pick); the web's slips. Check: the spec's (both tap steps kept).

## 6 · Time and measuring

### Time to the minute (`g3-clock`, new) · 3.MD.A.1 (tell and write time)
**One square:** a minute. **Picture:** the clock face, 20 squares across with its middle on a grid crossing, numbers 1–12
and 60 minute marks. Under it is **the hour laid out straight**: 60 squares, a square a minute, the clock's numbers on
the strong lines (every 5 squares is 5 minutes), 0 to 60.
- **Read**: 1. "Tap the hour." Tap the number the short hand has passed. Wrong: "The short hand
  hasn't reached 10 yet." / "That's where the long hand points." 2. "Drag to the long hand." Dragging along the hour
  line from 0 turns a ghost long hand on the face with it, and the readout counts minutes ("45, 46, 47"). Let go where
  the ghost meets the long hand. Wrong: "That's 45. The hand is 2 marks further." 3. **Write** `[9]:[47]`.
- **Set** ("Make it 4:23."): 1. "Turn the long hand to 4:23." (Turn a clock hand.) The short hand creeps between 4 and 5
  and the hour line's point moves with it; readout "4:23". Wrong: "That's 4:28. Back 5 minutes." The record writes
  `4:23`.

**Say:** "Past 9, and 47 minutes: 9:47."
**Core:** new. `h` (1–12), `m` (0–59), kind. Early: reading, with the long hand just past a number (5n + 1 or 2). Then
read and set in turn; m any, a multiple of 5 one time in five. Slips: counted the numbers (9 for 47: "Each number is 5
minutes. Count by 5s, then 1s."), one mark off, the next hour. Check: i3 set; i4 read, not a multiple of 5; i5 set; i6
read, m 45 or more (the short hand near the next number).

### Elapsed time (`g3-elapsed`) · 3.MD.A.1 (time intervals) · *fold:* when does it end?
**One square:** 5 minutes, so an hour is 12 squares (the clock's twelve fives), and up to 5 hours is 60 squares.
**Picture:** a timeline from the o'clock before the start to the o'clock after the end. The o'clocks are named (after 12
comes 1), and the start and end are points named with their times (`9:40`, `11:15`), a.m. or p.m. under the first.
1. "Hop to the next o'clock." One hop from the start stretches a square at a time; readout counts by 5s, "20 min". Let go
   elsewhere: "That's 9:55. Hop to 10:00."
2. "Hop the whole hours." Hops of 12 squares; readout "1 h". Past the end: "That's past 11:15."
3. "Hop the minutes left." Readout "15 min".
4. **Write** `20 min + 1 h + 15 min = [1] h [35] min`. When the two minute hops make 60 or more, they slide together and
   60 minutes close into an hour hop (See): "60 minutes make 1 hour."

**When does it end (fold, from problem 4, one in three):** "Practice starts at 3:45. It lasts 50 minutes." 1. "Hop to
the o'clock": "15 min · 35 to go". 2. "Hop the rest": "35 min". 3. **Write** `[4]:[35]`.
**Say:** "To the o'clock, the whole hours, then the minutes."
**Core:** `start`, `end` (minutes after midnight; the new kind uses `start` and a length). Early: quarter-hour times,
7–9 a.m. or 1–3 p.m., 1–2 hours, not across noon, the minutes before and after under 60. Then any 5-minute times,
sometimes across noon. When does it end: lengths of 20–90 minutes that pass an o'clock. Steps: to-hour, hours, after
(set by the hops), total (typed; slips: kept 60 minutes or more, lost the traded hour, subtracted the minutes); the end
(typed; slips: added the minutes straight on, 3:95 for 3:45 + 50, "There are only 60 minutes in an hour. Go past
4:00."; the hour left unchanged, 3:35). Check: the spec's, its last item made `i3 where kind = end`.

### Grams and kilograms (`g3-mass`) · 3.MD.A.2 (mass)
- **Which unit, about how heavy:** the thing drawn in Obento²'s line style (about 10 squares), a small kitchen scale
  marked g and a floor scale marked kg. 1. "Drag the key onto the scale that fits." (Slide pieces onto a pan; the
  readout names the scale it's over.) Wrong: "A kilogram is as heavy as a big bottle of water. A key is much lighter:
  grams." 2. "Tap about how heavy it is." Three tags, the web's (20 g, 2,000 g, 20 kg); the needle swings to the one tapped.
  Wrong: "2,000 g is about as heavy as a big book. A key is much lighter."
- **Read the scale:** the dial laid straight: a strip of 20 marks, 3 squares a mark (60 squares), labeled every 5 marks
  on the strong lines, the needle at the value, the thing on its pan above. 1. "Hop from 0 to the first label." The
  readout counts marks, not grams: "5 marks to 50". **Write** `each mark = [10] g`. 2. "Hop from 100 to the needle":
  "3 marks past 100". **Write** `[130] g`. Wrong: "Each mark is 10 g. Count on by 10s from 100."
- **A story:** the story on the top rows and "Pick what to do". The amounts are cells in rows of 10, a cell 3 squares
  wide (a cell is 10 g, or 1 kg; the biggest, 500 g + 500 g, is 100 cells, 30 × 30 squares): + slides the
  second amount in after the first; − slides it over from the end; × builds rows, as Multiplication facts; ÷ deals into
  rows, as Division facts. Readout "380 g". **Write** `230 + 150 = [380] g`.

**Say:** "A key is light: grams." / "Each mark is 10 g: 130 g." / "Two amounts together: add."
**Core:** the web's kinds by index (problems 1–3: unit, scale, unit; then index % 3), its things and guesses, marks of
1, 10, 50 or 100 g and 1, 2 or 5 kg (early: 1 or 10, the needle on a label; then between labels), stories (+ in either
unit; −, × and ÷ in kg). Steps: unit (set by the drop), guess (pick), step and read (typed; slips: counted marks as 1,
read a label, the label before, a mark short or over), story (pick), solve (typed; the other operations' answers, the
starting amount). Check: the spec's.

### Liters (`g3-liters`) · 3.MD.A.2 (liquid volume) · *fold:* about how much it holds · 3D: the How to
**One square:** the jug is a tall clear box, 40 squares tall and 20 wide, so a liter is 2 squares (20 L jugs), 4 (10 L)
or 8 (5 L): every mark lies on a square line, and the jug fills the screen's height (seen at about 95%). Its marks are on the left, labeled
as the web labels them (every mark up to 10 marks, every other one up to 20); the water is tinted to its level. The
record sits to the jug's right.
**How to (3D):** the paper tilts and the jug stands up off it. A big one-liter bottle pours in and the water rises to the
1 L mark, then a second one to 2 L: "A liter is about one big bottle of water." The paper lies flat again for the
problems.
- **Read the jug:** 1. "Hop up from 0 to the first label": "1 mark to 2". **Write** `each mark = [2] L`. 2. "Hop up to
  the top of the water": "4 marks". **Write** `[8] L`. Wrong: "That's the top of the jug. Read where the water is." /
  "Each mark is 2 L. Count by 2s."
- **A story:** as Grams and kilograms; a cell (3 squares) is a liter. Liter stories are + and − up to 50 L, and × and ÷
  inside the times tables (the web's `storyNumbers`).
- **About how much (fold, problems 7, 13, …):** a bucket drawn beside the one-liter bottle. "Tap about how much it
  holds." 1 L, 10 L or 100 L. Wrong: "100 L is about half a bathtub."

**Say:** "Each mark is 2 L: 8 L."
**Core:** the web's kinds (problem 1: a 5 or 10 L jug, marks of 1; problems 2–3: 10 L, marks of 2; then a jug when the
index is even, a story when it's odd). New: an estimate at index % 6 = 0 from problem 7, from a list of things (bottle
1 L, watering can 5 L, bucket 10 L, sink 20 L, fish tank 50 L, bathtub 200 L), with three guesses ten times apart, the
right one among them (1, 10 and 100 L for a bucket). Steps: step, read (typed; the web's slips), estimate (pick), story
and solve. Check: the spec's.

## 7 · Data

### Scaled picture and bar graphs (`g3-graphs`) · 3.MD.B.3 (read; how many more, together)
**One square:** picture graph: a picture is a 4-square cell (a half picture 2 squares wide), up to 9 in a row (36
squares), names on the left, the key under it ("★ = 2 books"). Bar graph: bars across, 4 squares tall and 2 apart; a step
of the scale is 6 squares (a half step 3), up to 8 steps (48 squares). The scale's numbers run along the bottom.
1. "Tap the key." (Or "Tap the scale.") Every picture shows what it's worth, small, or the lines' numbers light.
2. Picture graph: "Drag along the Apples row." The readout counts pictures: "4 pictures and a half". **Write**
   `4 × 2 + 1 = [9]`. Bar graph: "Drag the line from the end of the Dogs bar to the scale." It snaps to half steps, and
   the readout names the lines either side, "40 | 50". **Write** `Dogs: [45]`.
3. (how many more, or together) The second row or bar the same way. For "how many more", the shorter one's end drops a
   dashed line across the longer one and the extra is bracketed (See). **Write** `9 − 5 = [4]` (or `9 + 5 = [14]`).

**Say:** "Each ★ is 2: 9 votes." / "How many more means subtract."
**Core:** the web's (type, scale 2, 5 or 10, theme, counts, ask, x, y; early: picture graphs by 2 or 5, one row; bar
graphs take turns through the scales). Steps: key or scale (set by the tap), pictures (set by the drag), x, y, more or
both (typed; the web's slips). Check: the spec's.

### Draw a bar graph (`g3-drawgraph`, new) · 3.MD.B.3 (draw; one- and two-step how many more and fewer)
**One square:** as Scaled graphs. **Picture:** the empty graph with its scale along the bottom. The data is written
once, as the graph's own names: each row starts with its name and its count ("Dogs 35"), and the bar grows from there.
No separate table.
1. Bar graph: "Drag each bar to its number." (Drag a rectangle's edge: half steps for scales of 2 and 10, whole steps for
   5.) Readout "35 dogs". Wrong (a scale of 10): "That's 40. Dogs is 35. Back half a line." A bar done turns solid and
   its count is ticked.
   Picture graph: "Tap to add pictures." Each tap in a row adds one; tap the last again to make it a half (a scale of
   2). Readout "4 ★ · 8".
2. (from problem 4) "How many more dogs than cats?" The dashed line goes across and the extra is bracketed. **Write**
   `35 − 20 = [15]`. Two steps (from problem 7): "How many fewer fish than dogs and cats together?" `35 + 20 = [55]`,
   `55 − 15 = [40]`.

**Say:** "Each line is 10, so 35 ends half a line past 30." (A scale of 5: "Each line is 5, so 35 is 7 lines.")
**Core:** new. type, scale, theme (the web's four), counts (the web's sizes for each scale), ask (draw only, how many
more or fewer, two steps). Early: bar graphs by 5 or 10, whole steps, draw only. Then picture graphs one in three.
Steps: each bar or row (set by the drag or taps; slips: half a line off, a line off, counted lines as 1), the questions
(typed; Scaled graphs' slips). Check: i3 a bar graph by 2 with a half step; i4 a picture graph; i5 how many more; i6 two
steps.

### Line plots with halves and fourths (`g3-lineplot`) · 3.MD.B.4 · *fold:* the child makes the plot
- **Measure:** **One square:** an inch is 8 squares (a fourth is 2, a half 4). **Picture:** a ruler of 4, 5 or 6 inches
  (32 to 48 squares; the web's ruler is one inch longer than the crayon's whole inches, at least 4): long marks for inches, middle ones for halves, short ones for fourths. The crayon lies on it from 0.
  1. "Tap the last whole inch it passes." Wrong: "It hasn't reached 3 yet." 2. "Hop the fourths to its end": "3 hops".
  Past: "That's past the end." 3. **Write** `[2] [3]/[4] inches`.
- **Make and read the plot:** **One square:** an inch is 12 squares (a fourth is 3). **Picture:** the ruler, and under
  it, lined up with it, the plot from 1 to 3 inches (or 2 to 4): 24 squares. The crayons come onto the ruler one at a
  time. 1. "Tap where its X goes." (Place an X.) The X stacks above the mark under the crayon's end. Wrong: "That's 2
  1/4. Its end is at 2 1/2." (Lengths are named as the web names them: 2 1/2, never 2 2/4.) After three, the rest drop in by themselves (See). 2. "How many crayons are 2 1/4 inches?"
  Tap the stack; its X's number. **Write** `[3] crayons`. Or "Which length came up most?" Tap the tallest stack, and
  the record writes `2 1/4 inches`.

**Say:** "2 inches and 3 fourths: 2 3/4 inches." / "Each X is one crayon."
**Core:** the web's kinds by index (problems 1–2: halves on a ruler; even problems a ruler, fourths 2 times in 3; odd
problems from 4 a plot, the question by (index >> 1) % 2), things, data (8–12, one tallest stack). New: the first three
data are placed by hand, each set by its tap. Steps: whole (set by the tap), extra (set by the hops), write (typed);
stack (typed after the tap) or most (set by the tap); the web's slips. Check: the spec's.

---

## Open questions for G

1. **Chapter colours.** 3rd grade has 7 chapters, and the paper has 4 chapter colours (red and green are taken). We could
   reuse them: purple for Multiply and divide and Times-table tricks, pink for Place value and Data, amber for Shapes and
   area and Time and measuring, blue for Fractions. Or should there be new ones?
2. **Area's size.** A tile is a block, so the strong lines are the tiles' edges. The web's biggest rectangles (7–8 rows)
   are then seen at about 80% (Area of L-shapes too). Keep the web's sizes, or cap these problems at 5 rows so every
   one is at full size? Capping changes the web's maths.
3. **How many lessons.** The 10 new lessons make 28 (5th grade will have 26). Each one fills a gap in the standards. If
   3rd grade should be shorter, two could become extra problem kinds instead: Estimate to check (into Add and subtract)
   and Double a fact (into Multiply by breaking apart).
4. **The mass dial.** It's laid straight, as a strip of marks like a ruler, so the marks are counted on the grid. The
   clock keeps its round face, with the hour laid out under it. Straight, or round like the clock?
5. **3D in 3rd grade.** Only Liters' How to (the jug stands up and fills a liter at a time). Keep that one moment, or keep
   3rd grade all flat?
