# 2nd grade on paper: every lesson's design

Claude, grade 2 lesson planner, 1 Nov 2026, in the language of `README.md` and the shape of `grade5.md`. A plan only:
nothing here is built, and every lesson still needs G's yes on a preview (`LESSONS.md` §9). Each lesson gives the
standard, what one square is, the picture (sizes in squares; the iPad's landscape screen is about 68 × 45 at 100%),
each step's hand move with its live readout, what a miss says, what the picture then shows, the record, the last line,
and what Core needs. The 16 web lessons (`web/src/curriculum/lessons/grade2/`, `specs/k12/grade2.md`) keep their maths
exactly: generator ranges and easy-first order, derived values, slip messages, check recipes and stories. Only their
steps are new, designed for paper. Reviewed 2 Nov 2026 against the Common Core and the web's code: readouts that gave
away the number to be written were changed (Counting money, Dollars and cents, Arrays, Rows and columns), Subtracting
with regrouping shows the missing ones before it asks, Halves, thirds and fourths draws its wholes twice as big, and a
few ranges and slips were corrected to match the web.

**Standards covered:** all 26 of Common Core Grade 2: 2.OA.A.1–2.OA.C.4, 2.NBT.A.1 (with 1a and 1b)–2.NBT.B.9,
2.MD.A.1–2.MD.D.10, 2.G.A.1–2.G.A.3. **Lessons:** 27 in 7 chapters: the web's 16 and 11 new ones (ids `g2-…`). Seven
web lessons take a small *fold*, an extra problem kind or step, marked where it's added. A fold's problem kinds come at
problems the spec's check doesn't use, so those checks stay exactly as the spec has them. One fold is a step, not a
kind: Even and odd's `14 = 7 + 7` record is in every problem, its check too (2.OA.C.3 asks for it).

## Coverage

| Standard | In short | Lesson | |
|---|---|---|---|
| 2.OA.A.1 | Stories to 100, one and two steps, every kind, the unknown anywhere | `g2-story` Story problems to 100; `g2-twostep` Two-step story problems; the stories of `g2-regroup`, `g2-subregroup`, `g2-dollars` | new; new; existing |
| 2.OA.B.2 | Add and take away to 20 in your head; every one-digit sum by heart | `g2-facts` Facts to 20 | new |
| 2.OA.C.3 | Odd or even up to 20, by pairs or 2s; an even number as two equal addends | `g2-evenodd` (*fold*: its record `14 = 7 + 7`) | existing + fold |
| 2.OA.C.4 | Arrays up to 5 × 5; the total as a sum of equal addends | `g2-arrays` | existing |
| 2.NBT.A.1, 1a, 1b | Three digits are hundreds, tens and ones; 100 is ten tens; 100–900 are whole hundreds | `g2-hundreds` (*fold*: whole hundreds; a tenth ten makes a hundred) | existing + fold |
| 2.NBT.A.2 | Count within 1000; skip-count by 5s, 10s, 100s | `g2-skip` (*fold*: counting by 1s across a hundred) | existing + fold |
| 2.NBT.A.3 | Read and write to 1000: digits, number names, expanded form | `g2-hundreds` (*fold*: names read, and written with word blocks) | existing + fold |
| 2.NBT.A.4 | Compare three-digit numbers with >, =, < | `g2-compare` Compare three-digit numbers | new |
| 2.NBT.B.5 | Add and take away within 100 | `g2-regroup`, `g2-subregroup`; `g2-story` | existing; new |
| 2.NBT.B.6 | Add up to four two-digit numbers | `g2-addfour` Add up to four numbers | new |
| 2.NBT.B.7 | Add and take away within 1000 by place, trading tens and hundreds; a written record | `g2-within1000` | existing |
| 2.NBT.B.8 | 10 or 100 more or less than a number 100–900 | `g2-skip` (*fold*: hops of 10 or 100, on or back) | existing + fold |
| 2.NBT.B.9 | Say why the ways work | the last lines of `g2-regroup`, `g2-subregroup`, `g2-within1000`; `g2-addfour` | existing; new |
| 2.MD.A.1 | Measure with a ruler, yardstick, meter stick, tape | `g2-measure`; `g2-estimate` (*fold*: foot ruler, yardstick, meter stick); `g2-numline` (the tape) | existing; new |
| 2.MD.A.2 | Measure twice in two units; the bigger unit gives fewer | `g2-twounits` Measure with two units | new |
| 2.MD.A.3 | Estimate in inches, feet, centimeters and meters | `g2-estimate` (*fold*: feet and meters) | existing + fold |
| 2.MD.A.4 | How much longer one thing is than another | `g2-measure` (*fold*: two things on one ruler) | existing + fold |
| 2.MD.B.5 | Length stories to 100, with a drawing and a ? | `g2-numline` Lengths on a number line | new |
| 2.MD.B.6 | Numbers as lengths from 0; sums and differences on a number line | `g2-numline` | new |
| 2.MD.C.7 | Time to 5 minutes, analog and digital, a.m. and p.m. | `g2-time5` (*folds*: a.m. or p.m.; set the clock to a digital time) | existing + fold |
| 2.MD.C.8 | Money stories with bills and coins, $ and ¢ | `g2-coins`, `g2-money`; `g2-dollars` Dollars and cents | existing; new |
| 2.MD.D.9 | Measure several things, show them on a line plot | `g2-lineplot` (*fold*: measure five things and plot them) | existing + fold |
| 2.MD.D.10 | Draw picture and bar graphs (scale of 1); put together, take apart, compare | `g2-makegraph` Make a graph; `g2-bargraph` | new; existing |
| 2.G.A.1 | Shapes by their corners and faces; triangles, quadrilaterals, pentagons, hexagons, cubes | `g2-shapes` Sides and corners; `g2-solids` | new; existing |
| 2.G.A.2 | A rectangle cut into rows and columns of same-size squares, counted | `g2-squares` Rows and columns of squares | new |
| 2.G.A.3 | Halves, thirds and fourths of circles and rectangles; equal shares can look different | `g2-shares` | existing |

**The grade's edges.** Below, 1st grade's plan (`grade1.md`) teaches each way to a fact within 20 on its own (make a
ten, doubles and one more, add to take away, back through 10), stories to 20 with the unknown anywhere, tens and ones as
rows of ten, a new ten made only from ones (`g1-add100`), comparing two-digit numbers, measuring with cubes, the hour
and half hour, picture graphs and tallies, what makes a shape that shape, halves and fourths. 2nd grade starts past
each: the ways mixed into quick facts, sums and stories to 100, two two-digit numbers making a new ten, the hundred as a
place, three-digit numbers, rulers in inches and centimeters, 5 minutes, bar graphs with a scale of 1, shapes named by
how many sides, thirds. Above, 3rd grade's plan (`grade3.md`) has × and ÷, fractions as numbers, rounding, area and
perimeter, time to the minute, scaled graphs, line plots in halves and fourths, kinds of quadrilateral, and adding
within 1000 with place value disks. So 2nd grade writes arrays and squares only as sums of equal rows (never ×), names
shares in words (halves, thirds, fourths; never 1/3), counts squares without saying area, calls every four-sided shape a
quadrilateral, compares without rounding, and adds within 1000 with hops on lines that open place by place. Money never
has a point: `$27` and `68¢` stay apart (`$1.35` is 4th grade's). Nothing here touches 5th grade.

## Chapters (teaching order)

| # | Chapter | Lessons, in order | Colour |
|---|---|---|---|
| 1 | Adding and subtracting to 100 | Facts to 20 `g2-facts` **new** · Adding with regrouping `g2-regroup` · Subtracting with regrouping `g2-subregroup` · Add up to four numbers `g2-addfour` **new** · Story problems to 100 `g2-story` **new** · Two-step story problems `g2-twostep` **new** | purple |
| 2 | Numbers to 1000 | Hundreds, tens and ones `g2-hundreds` · Skip counting `g2-skip` · Compare three-digit numbers `g2-compare` **new** · Add and subtract within 1000 `g2-within1000` | pink |
| 3 | Equal groups | Even and odd `g2-evenodd` · Arrays `g2-arrays` · Rows and columns of squares `g2-squares` **new** | blue |
| 4 | Length | Inches and centimeters `g2-measure` · Measure with two units `g2-twounits` **new** · Estimate length `g2-estimate` · Lengths on a number line `g2-numline` **new** | amber |
| 5 | Data | Make a graph `g2-makegraph` **new** · Bar graphs `g2-bargraph` · Line plots `g2-lineplot` | pink |
| 6 | Time and money | Time to 5 minutes `g2-time5` · Name the coin `g2-coins` · Counting money `g2-money` · Dollars and cents `g2-dollars` **new** | amber |
| 7 | Shapes | Sides and corners `g2-shapes` **new** · Faces, edges and corners `g2-solids` (3D) · Halves, thirds and fourths `g2-shares` | teal |

Adding and subtracting to 100 comes first: it picks up where 1st grade ends, and `g2-within1000` needs both regrouping
lessons (the spec's depends-on). Numbers to 1000 comes before Equal groups and Time and money because `g2-arrays`,
`g2-time5` and `g2-money` build on `g2-skip`. Length comes before Data because line plots measure. The colours reuse the
app's five (the four in `Theme.swift` and 5th grade's new teal), and chapters next to each other differ. Every chapter
keeps its test. Depends-on lists keep `specs/k12/grade2.md` for the 16 web lessons; each new lesson names its own.

## How 2nd grade uses the grid

- **Counters:** 1st grade's counter, 3 × 3 squares, in two rows of ten places (30 × 7, a square apart, every fifth place
  ending on a strong line): `g2-facts`, `g2-evenodd`. A cent is the same counter, so a dollar is a 30 × 30 square of 100
  cents in four quarter blocks of 5 × 5: `g2-coins`, `g2-money`, `g2-dollars`.
- **Tens and ones:** counters 2 × 2, so nine tens and their sum fit: a ten is a row of ten (20 squares), rows a square
  apart, every fifth counter on a strong line: `g2-regroup`, `g2-subregroup`, `g2-addfour`.
- **Base ten in squares:** one is one square, a ten a strip 1 × 10, a hundred a flat 10 × 10, four blocks. The paper
  itself is base ten: `g2-hundreds`.
- **Lines that open place by place** (Rounding's, as 5th grade's Comparing decimals uses them): line 1 is 0 to 1000, a
  block a hundred; a block opens below into the next place: `g2-compare`, `g2-within1000`. A skip-count hop is always
  two blocks: `g2-skip`.
- **One square, one thing**, on bars and number lines to 100: `g2-story`, `g2-twostep`, `g2-numline`. To 50 at full
  size; to 100 the camera steps back to about 65% (Open questions).
- **One block, one thing:** an array's dot sits in the middle of its own block, so the strong lines run between rows and
  columns; a square tile is a block; a vote is a block along its bar, so a graph's scale lines are the strong lines:
  `g2-arrays`, `g2-squares`, `g2-makegraph`, `g2-bargraph`.
- **Length:** an inch is a block and a centimeter 2 squares, so an inch is 2½ cm on the paper, as in life; the line
  plot's inch is the ruler's: `g2-measure`, `g2-twounits`, `g2-estimate`, `g2-lineplot`. Feet and meters are drawn
  smaller: a foot a block, a meter 2 blocks.
- **Time:** 1st grade's clock, 24 squares across, with an hour strip beside it, a square every 5 minutes.
- **Shapes:** corners on grid crossings, as in 1st grade; solids are built in blocks, as Unit cubes.
- **Small hands:** nothing tapped or grabbed is under 2 squares across (a 2 × 2 counter is 50 pt at the camera's 125%);
  a row is grabbed anywhere along it; every drag snaps, so a shaky finger still lands.
- **Words:** one short line, verb first, 2–7 easy words ("Slide the ones together.", "Tap each row."); the numbers live
  on the picture. A miss is one short line measured on the paper ("That's 6. The pencil goes on to 9."). The last line
  says why in about 10 words. A story is two or three short lines over the picture it acts out, its numbers in the
  chapter colour. Show me and the How to play the move with a ghost finger and put everything back.
- **The record** is what a 2nd grader writes: `47 + 38 = 85` in columns with the small 1, `347 = 300 + 40 + 7`,
  `427 < 461`, `4 + 4 + 4 = 12`, `3:25 p.m.`, `68¢`, `$27`. Typing only for the number school writes, one box at a time.
- **Layout** as `grade5.md`: the instruction on rows 0–2 (28), a miss on rows 3–4 (20, red), the picture from row 6
  (its names at its right end), the record 3 rows under it, the blocks under the record; a story's lines take the top
  rows and everything moves down by them. A step answered by a move sets its Core box from it (`LessonRun.set`), so
  Core's checks and slips stay; steps the hands make pointless are dropped. Every web lesson keeps its animated beats
  (named below where they land) and takes the spec's fixes (`specs/k12/grade2.md` §4: "trade", never "carry").

## Hand moves

From the kit (`README.md`): **Ruler cut** (`g2-squares`; `g2-shares` draws each cut edge to edge, as 1st grade's Halves
and fourths does), **Slide pieces** (counters, rows, a story's bars and its ?, coins, bills, a price over the cents),
**Tap pieces / rows** (hundreds' places, rows, pictures, parts to shade, the bigger unit, the coin worth more, a dollar's
empty rows), **Tap a block on a line** (`g2-compare`), **Hop along a line** (`g2-skip`, `g2-within1000`, `g2-measure`,
`g2-twounits`, `g2-estimate`, `g2-numline`, `g2-bargraph`, `g2-lineplot`), **Drag a rectangle's edge** (a bar's end:
`g2-twostep`, `g2-numline`, `g2-makegraph`), **Write**.

Not in the kit table yet. All but one are already planned in another grade's file, under the same name:

| Move | What it does | From | 2nd grade uses |
|---|---|---|---|
| Tap to count | Each tap (or a drag across) gives the next thing the next number; the readout is the count; it also counts on from a number. | K | `g2-evenodd`, `g2-arrays`, `g2-bargraph`, `g2-lineplot`, `g2-shapes`, `g2-solids` |
| Group a ten | Tap a full row of ten: it closes into one ten (5th grade's Adding decimals closes a full grid the same way). | 1st | `g2-regroup`, `g2-addfour`, `g2-hundreds` |
| Open a ten | Tap a ten: it opens into ten ones (Group a ten, backwards). | 3rd | `g2-subregroup` |
| Tap a word block | A pick on the paper: a name, even or odd, <, = or >, + or −, a.m. or p.m., yes or no (5th grade's "Pick what to do"). | K, 1st, 5th | most lessons |
| **Write with word blocks** | Tap words in order; each is written into the record's line. | **new** | `g2-hundreds` (number names) |
| Drop a line | Drag from a bar's end straight to the scale; a dashed line follows and the number it lands on lights (how 5th grade's Points on a grid reads a point). | 5th, 3rd | `g2-bargraph` |
| Place an X | Drop an X above a mark on a line; it stacks. | 3rd | `g2-lineplot` |
| Trace around the clock | Drag from 12 the long hand's way; the face shades, snapping at each number and counting by 5s. | 1st | `g2-time5` |
| Turn a clock hand | Drag the long hand round; here it snaps at each number, and the short hand creeps with it. | 3rd | `g2-time5` (set the clock) |
| Trace a side | Drag along a shape's side; it darkens and counts. | 1st | `g2-shapes` |
| Place corners | Tap grid crossings to put corners; the sides join; tap the first corner to close. | K | `g2-shapes` |
| Tilt, Turn (3D) | Drag the paper up into 3D; turn a solid with one finger. | K; `LESSONS.md` | `g2-solids`; `g2-hundreds`' How to |

---

## 1 · Adding and subtracting to 100 (purple)

### Facts to 20 (`g2-facts`) · 2.OA.B.2 · new
Depends on `g1-ten`, `g1-doubles`, `g1-sub20`, `g1-related`. 1st grade learned each way to a fact on its own; here they
come mixed, one fact at a time, so each gets quick, and a child who knows a fact just writes it. **One square:** a
counter is 3 × 3 squares, in 1st grade's two rows of ten places. **Picture:** for `8 + 7`, the 8 fill the top row from
the left (chapter colour) and the 7 the bottom row (striped), each number at its row's right end; for `15 − 8`, the top
row full and 5 in the bottom row, `15` at the right and `− 8` under it (about 38 × 7, framed at 125%). The record
`8 + 7 = [ ]` sits 3 rows under, its box live from the start.
1. Write it, or let the hands find it. The line names the way that suits the fact:
   - an 8 or a 9 in it, or a sum a ten makes easy: **slide** counters up into the top row's empty places ("Make a ten,
     or just write it."); each snaps into the next place, and the full row's outline goes bold with `10` at its end.
     Readout `10 + 5`. One more than fits slides back: "The top row is full. That's 10."
   - the same number twice, or one apart: the bottom row starts a block to the right; **slide** it under the top row
     ("Pair them up, or just write it."); a line joins each pair and the extra one rings. Readout `6 + 6 + 1`.
   - a take-away: **slide** counters off the end ("Take 8 away, or just write it."); the bottom row goes first, crossed
     out as they leave, then the top row. Readout `5 … back to 10 … 3 more: 7 left`.
2. **Write** the answer. The record writes the way the hands went: `8 + 7 = 10 + 5 = [15]`, `6 + 7 = 6 + 6 + 1 = [13]`,
   `15 − 8 = 10 − 3 = [7]`. A right answer written straight away plays its way on the picture (See), so the picture
   still proves it. Slips: 14 or 16 "8 and 2 make 10, then 5 more."; 1 "That's taking away."; for `6 + 7`, 12 "That's
   double 6. 7 is one more." and 14 "That's double 7. 6 is one less."; for `15 − 8`, 23 "That's adding.", 8 "8 is what
   you take. What's left?" and 6 "Back to 10 takes 5. Then 3 more."

Say: "Make a ten, and the rest is easy." / "A double and one more." / "Back to 10 first, then the rest."
Core (new): every fact a + b with a and b 2–9 that crosses ten (sums 11–18), and their take-aways. Problems 0–2: an 8 or
9 with 3–6, a near double, a double; from 3 any of them, a take-away on every third (5, 8, 11 …). Steps: `answer`
(typed), and the way's box (`ten`, `pairs` or `back`) set by the move when the hands are used. Check: i0; i3 where the
sum is 15 or more; i5; i6 where it's a near double. Sums to 10 are 1st grade's and come back in the daily review.

### Adding with regrouping (`g2-regroup`) · 2.NBT.B.5, 2.NBT.B.9 · existing
**One square:** a counter is 2 × 2 squares and a ten a row of ten (20 squares), rows a square apart. **Picture:** 47 at
the left as four ten rows and a ones row of 7 (tinted), 38 at the right the same (striped), each number over its rows,
+ between (about 45 × 14; 26 tall once 85 is built). The column form at the right, 2 squares a digit.
1. **Slide** 38's ones row onto 47's ("Slide the ones together."): the counters snap in after the 7, counting on (8, 9,
   10); at ten the row is full and the rest start a new row. Readout `7 + 8 = 15`. Dropped elsewhere: "Ones go with the
   ones." A ten row grabbed first: "Start with the ones." (the web's "Started with the tens"). Sets `ones`.
2. **Group a ten** ("Make a ten: tap the full row."): its counters close into one ten (inner lines faint, a bold outline,
   `10` at its end) and it slides up under 47's tens; a small 1 is written over the tens in the column (the web's
   regroup beat). Readout `15 = 10 + 5`. The short row: "That's 5. A ten needs 10." Sets `regroup`.
3. **Slide** 38's ten rows under them ("Slide the tens together."): readout `4 + 3 + 1 = 8 tens`. Sets `tens`.
4. **Write** `47 + 38 = [85]` in the column. The web's slip, 75: "The new ten goes with the tens too: 8 tens, not 7."

Say: "10 ones make 1 ten, so it joins the tens."
The story kind (a class read 47 books in May and 38 in June) takes the top rows with "Pick what to do" first (in 2nd
grade only + Add and − Take away), and names the two stacks May and June.
Core: the web's as it is: both 15–79, ones making 10 or more, sum ≤ 99; problems 0–2 both 11–49, ones making 10–12,
tens 6 or fewer. `ones`, `regroup` and `tens` set by the moves, `answer` typed with its slip; the check as the spec (i0;
i3 where the ones make exactly 10; i3; i3 story). How to: ten ones fill a row and close into a ten, then one sum.

### Subtracting with regrouping (`g2-subregroup`) · 2.NBT.B.5, 2.NBT.B.9 · existing
**One square:** the same counters and rows. **Picture:** 52 as five ten rows and a ones row of 2 (tinted), `52` over
it; at its right `− 27` over 27 drawn dashed, two ten rows and a ones row of 7, its ones row level with the 2 (about
45 × 17; 9 tens and a dropped ten make 29 rows at most). As the problem draws (Ask), the dashed 7 slides over the 2 by
itself: it covers the 2 and 5 of it hang past the end, then it slides back. The child has seen there aren't enough ones.
1. **Open a ten** ("Not enough ones. Open a ten."): tap a ten row; it rings, its outline opens and its ten counters drop
   to the ones as a loose row over the 2 (the web's trade beat). Readout `10 + 2 = 12 ones`. In the column the 5 is
   crossed with 4 over it and the 2 becomes 12. A one tapped: "Tap a ten to open it." With no ones at all (50 − 27):
   "No ones. Open a ten." Sets `trade`.
2. **Slide** the dashed 7 over the ones ("Take 7 ones."): each counter it covers is crossed out and what's left counts
   down. Readout `12 − 7 = 5`. Sets `ones`.
3. **Slide** the dashed tens over two ten rows ("Take 2 tens."): `4 − 2 = 2 tens`. Over the ones: "Tens go over tens."
   Sets `tens`.
4. **Write** `52 − 27 = [25]` in the column with its trade marks. The web's three slips: 35 "You did 7 − 2 in the ones.
   You can't take 7 from 2, so trade a ten first."; the traded ten forgotten, "You traded a ten, so there is one ten
   less: 4 − 2 = 2." (for 52 − 27 that is also 35, and the first message wins, as on the web); 52 "Tens go on the left:
   2 tens and 5 ones."

Say: "A ten is 10 ones, so now there are enough."
The story kind: 52 stickers on a sheet, and Maya used 27.
Core: the web's as it is (the first number's tens 3–9 and ones 0–8, fewer ones than the second's; the second's tens
from 1 to one less than the first's, two less in problems 0–2, so a ten is left). `trade`, `ones` and `tens` set by the
moves, `answer` typed with the web's slips; the check as the spec (i3 where the first number's ones are 0; i3 where the
answer is under 10; i3; i3 story).

### Add up to four numbers (`g2-addfour`) · 2.NBT.B.6, 2.NBT.B.9 · new
Depends on `g2-regroup`, `g1-three`. **One square:** the same counters and rows. **Picture:** the first number at the
left, where the total builds; the others in a column at the right, a square apart, each its ten rows and ones row with
its number at its right end (`+ 34`, `+ 16`); the column form beyond them (about 58 × 26).
1. **Slide** every number's ones onto the first number's ones row, in any order ("Slide all the ones over."): they count
   on and a full row starts the next. Readout `7 + 4 + 6 = 17`. Holding a ones row lights another whose ones make 10
   with it ("4 and 6 make 10"), for a child who wants a ten first.
2. **Group a ten** for each full row ("Tap each full row."): it joins the tens; a small 1 (or 2) over the tens.
3. **Slide** the other numbers' tens under the first's ("Slide the tens over."): readout `2 + 3 + 1 + 1 = 7 tens`.
4. **Write** `27 + 34 + 16 = [77]`. Slips: 67 "The new ten goes with the tens."; 10 or 20 less when the ones made two
   tens, "The ones made 2 tens."; a number left out, "Add every number. There are 3."

Say: "Ones with ones, tens with tens, in any order."
Core (new): three numbers 11–39, or four 11–29; the sum 30–99; the ones totalling 10 or more. Problems 0–2: three
numbers, two of whose ones make exactly 10, the ones totalling 10–19 and the tens 6 or fewer; from 3, four numbers on
even problems and three on odd ones, the ones up to 29 (two new tens). Steps: `ones` and `tens` set by the moves,
`answer` typed. Check: i0; i3 where the ones total 20 or more; i4; i5.

### Story problems to 100 (`g2-story`) · 2.OA.A.1, 2.NBT.B.5 · new
Depends on `g2-subregroup`, `g1-story`, `g1-more`. 1st grade acted stories out with counters to 20; to 100 the counters
become bars, to scale. **One square:** one thing. **Picture:** the story in two or three short lines on the top rows,
its numbers in the chapter colour. As it's read, each number lights and its bar draws, 4 squares tall, from a start
line on a block line, with a bold line inside it every ten squares (so 59 is seen as 5 tens and 9): joining, taking
away and parts of a whole are one bar in two parts under a bracket for the whole; comparing is two bars from one start
line, the longer on top, the gap past the shorter one's end dashed. The part we don't know is a dashed outline its true
length, with no number. Wholes to 50 are at full size; later ones to 99 step the camera back (about 65%).
1. **Slide** the ? onto what we don't know ("Put the ? on what we don't know."): it snaps to the bracket, a part or the
   gap, and that piece turns chapter colour. On a known one: "We know that one: 34."
2. **Tap** + or − ("Pick what to do."): +, the parts slide together under the bracket; −, the known part slides off the
   whole, leaving the ?. Wrong: "The ? is a part. Take the other part away." / "The ? is the whole. Put the parts
   together."
3. **Write**: the story's equation is written as the ? lands, the ? where the story has it (`34 + ? = 59`); then the
   child's line `59 − 34 = [25]`. Slips: 93 "The ? is a part, so it's less than 59."; with a trade (`62 − 34`), 32 "You
   can't take 4 from 2. Trade a ten first." and 38 "You traded a ten: 5 tens, not 6."

Say: "The ? is a part, so take the known part away." (The whole: "The ? is the whole, so put the parts together.")
Core (new): the eleven kinds of 2nd grade story (joining and taking away with the end, the change or the start unknown;
parts of a whole with the whole or a part unknown; comparing with the difference, the bigger or the smaller unknown,
each in "more" and in "fewer" words). Problems 0–2: the end unknown (joining, taking away, both parts known), wholes to
50, no trade; 3 a change unknown, 4 a part unknown, 5 how many more; from 6 any kind, wholes to 99, trades allowed, the
start unknown and the mixed-up wording among them ("Sam has 25 fewer than Ana. Sam has 34. How many does Ana have?").
Names and things from the web and 1st grade (Maya, Leo, Ana, Sam; stickers, books, shells, marbles, cards). Steps:
`unknown` set by the slide, `op` by the pick, `answer` typed. Check: i3; i4; i6 where the start is unknown; i6 where
it's comparing in the mixed-up wording. If G says yes to 1st grade's question about a voice, the stories are read aloud.

### Two-step story problems (`g2-twostep`) · 2.OA.A.1 (two steps) · new
Depends on `g2-story`. **One square:** one thing, as in Story problems. **Picture:** the story on the top rows; the start
bar (tinted, `45` at its end) from the start line; the first change waiting under it as a loose striped bar with its
number.
1. **Slide** the loose bar in ("Slide the 18 in."): dropped after the end it joins and the count runs on (readout
   `45 + 18`); dropped over the end, each square it covers is crossed out (`45 − 18`). Wrong for the story: "He got
   more. Put them after the end." / "He gave some away. Slide them over the end."
2. **Write** `45 + 18 = [63]`; the bar now ends at 63, named so.
3. The second change waits; **slide** it the same way ("Slide the 27 in."), then **write** `63 − 27 = [36]`.

More, then in all (a later kind): Sam's bar (34) and Ana's, which starts as long as Sam's; **drag** Ana's end on ("Ana
has 15 more."), readout `34 + 15`, and **write** `[49]`; then **slide** Ana's bar onto the end of Sam's ("Put them
together."), and **write** `34 + 49 = [83]`.
Say: "The first answer is where the second step starts."
Core (new): two changes (+ +, + −, − +, − −) on a start 10–60, each change 5–40, every answer 1–99; and from problem 6,
one time in three, more-than then in all (each 10–45, the total up to 99). Problems 0–2: + then −, no trades, all within
50; from 3 any order, trades allowed. Slips: the first answer typed as the last ("That's after one step. Now the 27.");
the start used again ("Start from 63, the first answer."); the other operation. Check: i0; i3 where it's − then +; i3
where a step trades; i6 where it's more-than then in all.

## 2 · Numbers to 1000 (pink)

### Hundreds, tens and ones (`g2-hundreds`) · 2.NBT.A.1, 1a, 1b, 2.NBT.A.3 · existing, *folds*
**One square:** one. A ten is a strip 1 × 10 and a hundred a flat 10 × 10, four blocks. **Picture:** three place
columns, their names over them (small): hundreds (flats in rows of three, a square apart, up to 32 × 32), tens (strips
standing a square apart, up to 17 × 10), ones (two columns of five, 3 × 9), 4 squares between columns (60 wide). A dashed
place waits after the last piece in each column. The number once, big, over the columns; the digit being built is
ringed, with a dashed line to its column. Seven or more hundreds step the camera back to about 90%.
1. **Tap** the hundreds column ("Put in the hundreds."): each tap fills the next place, the flat's squares filling in;
   the last piece drags back out. Readout `100, 200, 300`. Check. With 4: "That's 400. The 3 means 3 hundreds." The
   column rings as it's counted (the web's hundreds beat). Sets `hundreds`.
2. The same for the tens ("Now the tens.", `10, 20, 30, 40`) and the ones ("Now the ones.", `7`). A 0 digit is Check
   with the column empty, readout `0 tens`. A tenth ten: the ten strips slide together into a flat and back apart, "10
   tens make a hundred. 347 has 4 tens." (2.NBT.A.1a). Sets `tens` and `ones`.
3. **Write** `347 = [300] + [40] + [7]`. The web's slips (3 + 4 + 7: "Each digit is worth its place. 3 hundreds is
   300, and 4 tens is 40."; 300 + 4 + 7: "The 4 is in the tens place, so it is worth 40.").

Say: "Where a digit sits tells what it's worth."
How to: ten ones close into a ten and ten tens into a hundred, the camera stepping back a little each time; then, once,
**3D**: the paper tilts, ten hundred flats rise as slabs one square thick and stack into a thousand, a cube 10 squares
(2 blocks) on a side, and the paper lies flat again. Here a one is a square, not Unit cubes' block, so this cube is
the only one in the app smaller than a block: Open questions.
*Folds:* whole hundreds (2.NBT.A.1b) on problems 5, 11, …: the tens and ones columns stay empty,
`600 = [600] + [0] + [0]`. Number names (2.NBT.A.3) on problems 4, 7, 10, …: on 4, 10, … the number comes in words on
the top rows ("six hundred five"), the child builds it, and the record starts `six hundred five = [605]`; on 7, 13, …
the record ends by **writing with word blocks**: a row of blocks under it (six, sixty, hundred, five, fifty), tapped in
order, each written into the line `605 = six hundred five`. A wrong word: "Sixty is 6 tens. 605 has 0 tens."
Core: the web's (100–999, problems 0–2 with no zero digit) and slips, with the spec's hint fixes; `hundreds`, `tens` and
`ones` set by the taps, `expanded` typed; the folds as above; the check as the spec (i0; i3 where the tens digit is 0;
i3 where the ones digit is 0; i3).

### Skip counting (`g2-skip`) · 2.NBT.A.2, *fold* 2.NBT.B.8 · existing
**One square:** a tenth of a hop: a hop is always 10 squares, two blocks, whatever the jump. **Picture:** a number line
on a strong line, six marks 10 squares apart (50 wide), small marks inside each hop for its units (by 2 one in the
middle; by 5 every 2 squares; by 10 every square; by 100 every square, each a ten). The first three numbers under their
marks (36); boxes under the other three.
1. **Hop** from the first number to the second, a unit at a time ("Hop from 15 to 20."): the small hops count, readout
   `+5` (by 100 they're tens: `10, 20 … +100`). Stopped short: "That's 3. Go on to 20." The hops between the shown
   numbers draw in (the web's jump beat). Sets `jump`.
2. **Hop** on from the third number, a whole jump at a time ("Hop on. Write where you land."): each hop arcs to the next
   mark and the child **writes** its number in the box under it; the digit that changed lights (the web's reveal beats).
   Three times. The web's slips: 26 "Jump by 5, not by 1: 25 + 5."; 35 "The jump is 5, not 10: 25 + 5."; 20 "The
   numbers are getting bigger, so count up: 25 + 5."

Say: "Every hop is 5, so each number is 5 more." (By 10: "…so only the tens digit changes." By 100: "…so only the
hundreds digit changes.")
*Fold* (2.NBT.B.8, and counting by 1s within 1000) on problems 4, 7, 10, …: a start from 100 to 900 with hops of 10 or
100, on or back (back runs right to left, the numbers falling: 640, 630, 620), or hops of 1 across a hundred (397, 398,
399, then 400). The web's "counted back" slip turns round for back: "The numbers are getting smaller, so count back." A
hop past a hundred says why: "10 tens make a hundred, so the hundreds digit changed too."
Core: the web's generator and slips (problems 0–2 by 2, 5 or 10 from a multiple; later by 5 from 10–150, by 10 from
1–60, by 100 from 100–499); `jump` set by the small hops, the three counts typed; the fold as above; the check as the
spec (i0 by 2; i3 by 5; i3 by 10 from a start that isn't a ten; i3 by 100).

### Compare three-digit numbers (`g2-compare`) · 2.NBT.A.4 · new
Depends on `g2-hundreds`, `g1-compare`. 5th grade's Comparing decimals (`prototype/new5-lessons.html`), for whole
numbers: Rounding's lines that open place by place. **One square:** line 1 runs 0 to 1000 in ten blocks of a hundred
(50 squares); a block that opens becomes the next line, ten blocks of ten, then ten blocks of one. **Picture:** line 1,
its ends named small; the record at its right, the two numbers stacked, digits in their places (about 66 × 28 with three
lines open).
1. Different hundreds: **tap the hundred each one is in** ("Tap the hundred each one is in."): the first number's block
   shades, the second's stripes, each named over its block. Wrong block: "Neither number is between 500 and 600." Same
   hundreds: **tap the hundred they're both in** ("Tap the hundred they're both in."): it lights and opens below
   (dashed) into line 2, that hundred in ten blocks of ten; then the tens the same way, and the same tens open line 3.
2. The record rings the place where the numbers first differ. **Tap** <, = or > (three blocks under it):
   `427 [<] 461`. Wrong: "Look at the tens: 2 and 6. The open side faces the bigger one." Equal numbers fall in the same
   block on every line; a < or > for them: "Same hundreds, tens and ones. They're equal."

Say: "Both have 4 hundreds. 6 tens are more than 2 tens." (Different hundreds: "5 hundreds are more than 4 hundreds,
whatever the tens.")
Core (new): two numbers 100–999. Problems 0–2 different hundreds; from 3, different hundreds 1 in 3 (half of them the
trap: the smaller number has the bigger tens, 389 and 412), the same hundreds 1 in 3, the same hundreds and tens 1 in 4,
equal 1 in 12. Steps: the blocks (set by the taps), `sign` (the pick; slips: the wrong way round, = for different
numbers). Check: i3 where it's the trap; i3 where the hundreds match; i3 where the hundreds and tens match; i3.

### Add and subtract within 1000 (`g2-within1000`) · 2.NBT.B.7, 2.NBT.B.9 · existing
The web's hops by place, on Comparing's lines, each to scale (3rd grade meets the same sums again with place value
disks). **One square:** line 1 is 0 to 1000, a block a hundred; line 2 is two hundreds, 3 squares a ten (60 wide); line
3 is two tens, 3 squares a one (60 wide). **Picture:** line 1 with `245`'s point over it and `+ 132` beside, split as
the web splits it, `100 + 30 + 2`; lines 2 and 3 open under it as they're needed (about 64 × 30 in all). The record
under the lines.
1. **Hop** the hundreds on line 1 ("Hop on 1 hundred."): each hop arcs one block; readout `345`. Too many: "That's 2
   hundreds. 132 has 1." The wrong way: "Adding goes up." The record writes `245 + 100 = 345` (the web's first hop
   beat). Sets `hundreds`.
2. See: the hundred it landed in and the next open below into line 2 (taking away, the one below), and the point drops
   to its place.
3. **Hop** the tens on line 2 ("Hop on 3 tens."): readout `375`; `345 + 30 = 375`. A hop past a hundred changes the
   readout's hundreds digit (`395 → 405`): "10 tens make a hundred." Sets `tens`.
4. See: line 3 opens the same way; **hop** the ones ("Hop on 2 ones."): `377`; `375 + 2 = 377`. Sets `ones`.
5. **Write** `245 + 132 = [377]`. The web's slips in the spec's words ("When a place makes 10 or more, trade 10 of them
   for 1 in the next place."; "This is adding, so the answer is bigger.").

Taking away hops back, each line opening on the hundred or ten below. Say: "Hundreds, then tens, then ones: one place at
a time." (Past a hundred: "10 tens make a hundred, so the hundreds changed too.")
Core: the web's as it is (the second number has no zero digit; problems 0–3 cross no ten or hundred and later ones
always do; adding or taking away at random) with the spec's "trade" wording; `hundreds`, `tens` and `ones` set by the
hops, `answer` typed; the check as the spec (i0; i4 adding; i4 taking away; i4).

## 3 · Equal groups (blue)

### Even and odd (`g2-evenodd`) · 2.OA.C.3 · existing, *fold*
**One square:** a dot is a 3 × 3 counter, and the pair frame is Facts to 20's two rows of ten. **Picture:** the dots
loose on a field of three rows of ten places (30 × 11), `13` at its right end; the empty pair frame under it (30 × 7):
about 30 × 20, framed at 125%.
1. **Tap to count** each dot ("Tap each dot.", or drag across them): it takes the next number and hops into the frame,
   top then bottom, column by column; each full column rings as a pair and the readout counts by 2s (`2, 4, 6 … 12`);
   the last dot sits alone, ringed (the web's pairs and left beats). Readout `6 pairs and 1`. Sets `pairs` and `left`.
2. **Tap** even or odd ("Tap even or odd."). The web's messages ("One dot is left over without a partner, so 13 is
   odd.").
3. **Write** the two rows (*fold*: an even number as two equal addends): `14 = [7] + [7]`; odd, `13 = [6] + [6] + 1`.
   7 and 7 for 13: "That's 14. Each row has 6, and 1 is left."

Say: "One dot has no partner, so 13 is odd." / "Every dot has a partner, so 14 is even."
Core: the web's (problems 0–2 4–12, later 7–20) and slips, without the question the spec removes; `pairs` and `left` set
by the taps, `evenodd` by the pick; the rows step new (its slips above, and the whole typed for a row); the check as the
spec (i0 even; i0 odd; i3 even, 15 or more; i3 odd, 15 or more), the rows step in every item.

### Arrays (`g2-arrays`) · 2.OA.C.4 · existing
**One square:** a dot sits in the middle of its own block (Kindergarten's dot), so the strong lines run between the rows
and between the columns. **Picture:** the array, 2–5 rows of 2–5 (up to 25 × 25); the story kind draws the muffin box
round it.
1. **Tap** each row ("Tap each row."): it lights as a band and takes its number at the left (the web's rows beat).
   Readout `3 rows`. A column: "That goes down. Rows go across." Sets `rows`.
2. **Tap to count** along one row ("Count one row."): its dots number, readout `4 in a row` (the web's one-row beat).
   Down a column: "That's down. Count across." Sets `cols`.
3. **Write** `4 + 4 + 4 = [12]`; once it's right, the running totals write in at the rows' right ends (4, 8, 12: the
   web's last beat), so they prove the sum instead of giving it away.
   The web's slips (7 "Add 4 once for every row: that's 3 times."; 8 "There are 3 rows, so add 4 3 times."; 16 "There
   are only 3 rows. Add 4 3 times.").

Say: "Every row has 4, so add 4 for each row."
Core: the web's (2–5 by 2–5; problems 0–2 up to 4 by 4) with its slips and story (muffins in a box); `rows` and `cols`
set by the moves, `total` typed; the check as the spec (i0; i3 where the rows and columns differ; i3 where there are 5
rows or 5 columns; i3 story).

### Rows and columns of squares (`g2-squares`) · 2.G.A.2 · new
Depends on `g2-arrays`. **One square:** a square tile is a block, as in 3rd grade's Area, so every cut falls on a strong
line. **Picture:** a rectangle, bold, its corner on a strong line, 2–5 blocks tall and 2–6 across (up to 30 × 25), plain
inside.
1. **Ruler cut** down its left side ("Cut it into 3 rows."): the handle snaps to equal rows that fit; the cuts dash
   across; readout `3 rows`; Cut. "That's 5 rows. Cut 3."
2. **Ruler cut** along the top ("Now cut the rows into squares."): the readout counts the columns and says `squares`
   once the pieces are as wide as they're tall; Cut. Not square: "Those are 3 squares wide and 5 tall." Right: the
   tiles tint in a light checker.
3. **Tap** each row, then **write** `4 + 4 + 4 = [12]` squares; once it's right, the running totals write in. 300:
   "That counts the paper's small squares. Count the ones you cut."

Say: "Same-size squares, so every row has the same number."
Core (new): rows 2–5, columns 2–6. Problems 0–2: 2–3 rows and 2–4 columns, rows cut first; from 3 the columns come first
in half the problems ("Cut it into 4 columns."). Steps: `rows` and `cols` set by the cuts, `total` typed. Slips: the
paper's squares counted; rows and columns added ("That's 3 + 4. Add 4 for each row."); a row short or over. Check: i0;
i3 where there are 4 or 5 rows; i3 where there are 5 or 6 columns; i3.

## 4 · Length (amber)

### Inches and centimeters (`g2-measure`) · 2.MD.A.1, *fold* 2.MD.A.4 · existing
**One square:** an inch is a block and a centimeter 2 squares, so an inch is 2½ cm on the paper, as in life.
**Picture:** the ruler, a strip 3 squares tall, its marks up from its top edge and numbers under them (small): inches
0–10 (50 wide) or centimeters 0–15 (30 wide). The thing (the web's pencil, crayon, ribbon or straw, a line drawing 2
squares tall) lies just above it, its ends on marks.
1. **Hop** along the ruler from the thing's left end, a space at a time ("Hop from end to end."): each hop arcs over one
   space and counts, readout `7 cm`; the numbers under its two ends light (the web's start, end and count beats).
   Starting elsewhere: "Start at the pencil's end." Short or past: "That's 6. The pencil goes on to 9." Sets `start`
   and `end`.
2. **Write** `9 − 2 = [7] cm` (from 0, `[7] cm`). The web's slips (9 "The pencil starts at 2, not 0. Count the spaces
   from 2 to 9."; 8 "Count the spaces between the marks, not the marks themselves."; 11 "Take away the start: the ruler
   before 2 is not part of the pencil.").

Say: "Each hop is one space, and the spaces are the length."
*Fold*, how much longer (2.MD.A.4), on problems 4, 8, 12, …: two things lie from 0 on one ruler. **Hop** from the
shorter one's end to the longer one's ("Hop the part sticking out."): `3 cm`. **Write** `9 − 6 = [3] cm`. Say: "Lined
up at 0, the part sticking out is how much longer."
Core: the web's (inches 2–7 on a 0–10 ruler, centimeters 3–11 on 0–15; problems 0–2 start at 0, later never) and slips;
`length` typed; the fold's kind (two lengths at least 1 apart); the check as the spec (i0; i3 inches; i3 centimeters;
i3).

### Measure with two units (`g2-twounits`) · 2.MD.A.2 · new
Depends on `g2-measure`. **One square:** Inches and centimeters' scale, so the two rulers match as they do in life.
**Picture:** the thing in the middle, an inch ruler over it and a centimeter ruler under it, both from its left end. Its
length is an even number of inches, so both read whole: 6 inches is 30 squares, 15 cm (at most about 64 × 14).
1. **Hop** along the inch ruler ("Measure in inches."): `6 in`. **Write** `[6] in`.
2. **Hop** along the centimeter ruler ("Now in centimeters."; a drag lays the hops as fast as the finger goes):
   `15 cm`. **Write** `[15] cm`.
3. **Tap** the bigger unit, one space on either ruler ("Tap the bigger unit."): one inch and one centimeter lift out and
   lie side by side. A centimeter tapped: "15 is more, but each centimeter is smaller."

Say: "A centimeter is smaller, so more of them fit."
Core (new): lengths 2, 4, 6, 8, 10 or 12 inches (5–30 cm, true to the nearest centimeter); things about that long (a
key, a crayon, a spoon, a pencil, a book, a ruler). Problems 0–2: 2–6 inches; from 3 any. Steps: `inches` and `cm`
typed (slips: one mark too many; the other ruler's number, "That's the inches. Count the centimeters."), `bigger` (the
tap). Check: i0; i3 where it's 8 inches or more; i3; i3.

### Estimate length (`g2-estimate`) · 2.MD.A.3, 2.MD.A.1 · existing, *fold*
**One square:** as Inches and centimeters. **Picture:** the thing, its benchmark at its left end (a paper clip, about an
inch, a block long; a centimeter cube, 2 × 2); the ruler comes in step 2.
1. **Tap** a guess ("Guess with the paper clip."): three word blocks, the web's (its length; a quarter of it and four
   times it in inches, a fifth and five times in centimeters). Right: paper clips lay themselves end to end along it, counted (the web's lay beat). Wrong: the guess
   draws dashed along the thing, with the web's message ("24 inches is longer than a whole ruler." / "2 inches is about
   2 paper clips. The pencil is much longer than that.").
2. **Hop** along the ruler, which slides in under the thing (the web's ruler beat) ("Now measure it."): `6 in`.
3. **Write** `[6] in`, under `about 6 in` from step 1.

Say: "A paper clip is about an inch, and about 6 fit."
*Fold*, feet and meters (2.MD.A.3, with 2.MD.A.1's foot ruler and meter stick), on problems 6, 9, 12, …: a long thing
drawn smaller, a foot a block (a desk 3–4 ft, a rug 5, a bed 6–7, a door 7, a board 8) or a meter 2 blocks (a door 2 m,
a board 3, a car 4, a tree 5), guessed beside a foot ruler or a meter stick, then measured by **hopping** the ruler or
stick along it (`1, 2, 3 … 7 ft`). Things 6 feet or longer are measured with a yardstick instead, 3 feet with its feet
marked, two hops and the rest (`3, 6, 7 ft`), so all of 2.MD.A.1's tools appear.
Core: the web's things, guesses and slips (inches first; then the units mixed and starts 0–2; a new thing each time);
the fold's units as above; the check as the spec (i0; i3 centimeters; i4 inches not from 0; i5).

### Lengths on a number line (`g2-numline`) · 2.MD.B.5, 2.MD.B.6, 2.MD.A.1 (the tape) · new
Depends on `g2-measure`, `g2-subregroup`. **One square:** one unit of the story (cm, in, ft or m). **Picture:** a number
line like a tape measure on a strong line, a mark every square, longer every 5, numbered every 10 (small): 0 to 50 at
full size, 0 to 100 later (the camera at about 65%). The story on the top rows; each length a bar 3 squares tall over the
line, from 0.
1. **Drag** a bar's end from 0 ("Drag from 0 to 45."): it snaps a square at a time; readout `45 cm`. "That's 44. The
   ribbon is 45 cm."
2. **Hop** from its end, tens then ones ("Hop back 18."): ten-hops arc 10 squares, then one-hops 1; readout
   `45 − 10 = 35 … 27`. The wrong way: "She cut some off. Hop back." Too far: "That's 19 back. Hop 18."
   Comparing: both bars from 0, then **hop** from the shorter one's end to the longer one's. A part missing: one bar to
   the part's end, then **hop** on to the whole's mark.
3. **Write** `45 − 18 = [27] cm` (a part missing: `35 + ? = 60` is written, then `? = [25] m`).

Say: "Every number is a length from 0, so hopping back takes length off." (Comparing: "The gap between the ends is how
much longer.")
Core (new): joining, cutting off, comparing, a part missing; the first length 10–90, the second 5–60, every answer
1–100; things a ribbon, a rope, a string, a path, a fence, a board. Problems 0–2 (joining, cutting off, comparing):
within 50, the second length a whole ten or under 10, no ten crossed; from 3 any kind, crossing a ten, to 100. Steps:
`start` set by the drag, the hops' total set by the hops, `answer` typed. Slips: the other operation; a ten off; one mark
too many. Check: i3 where it's cutting off; i3 comparing; i3 a part missing; i3.

## 5 · Data (pink)

### Make a graph (`g2-makegraph`) · 2.MD.D.10 (draw; put together, take apart) · new
Depends on `g1-tally`, `g1-picgraph`. **One square:** a vote is a block along its row, so the scale's numbers sit on the
strong lines. **Picture:** the tally chart on top, 1st grade's marks in four columns (a little picture, a name, the
marks; about 56 × 9); under it the empty graph: four rows 4 squares tall, a square apart, each row's picture and name at
its left, the title over (about 52 × 22).
1. Picture graph: **tap** a row ("Tap to add the pictures."): each tap puts the next picture in the next block; readout
   `apples: 7`. Bar graph (the scale 0–8 under the rows): **drag** each bar's end ("Drag each bar to its tally."): it
   snaps a block at a time; readout `7`. Either way, wrong: "That's 6. The tally says 7." A finished row ticks its
   tally. Any order.
2. **Write** `7 + 4 + 6 + 3 = [20]` in all (the marks, the pictures and the blocks are the same count).

Missing row (take apart): "20 children voted." and one tally is a `?`. **Drag** that bar: the readout counts the whole
graph, `17 … 18 … 20 in all`. **Write** `20 − 17 = [3]`.
Say: "One block for each vote, so each row is as long as its tally." (Missing row: "The rows make 20, so pears get
what's left.")
How to: a picture graph's pictures melt into a bar, the same blocks filled.
Core (new): the web's three themes and two more (snacks, colors); four counts 1–8. Problems 0–2: counts 1–6, all
different: a picture graph, a bar graph, a picture graph; from 3 in turn a picture graph, a bar graph and a missing row
(the total up to 32). Steps: each row (set by the taps or the drag), the total or the missing count (typed). Slips: a row
one off; a row left out of the total; the total typed for the missing row. Check: i0; i4; i5; i6.

### Bar graphs (`g2-bargraph`) · 2.MD.D.10 (read; compare, put together) · existing
**One square:** a vote is a block, as in Make a graph. **Picture:** four bars across, 4 squares tall and a square apart,
the names at their left (10 squares), the scale 0–10 under them on the strong lines (50 squares), the title over (about
62 × 24). The web's question on the top rows.
1. **Drop a line** from the end of the apples bar ("Read the apples bar."): a dashed line follows straight down to the
   scale and the number it lands on lights; the bar lights while it's read (the web's first beat). Readout `apples: 7`.
   Let go a line too far or short: "That's 8. The apples bar stops before 8." / "That's 6. The apples bar goes past 6."
   Another bar: "That's the bananas bar. Find apples." Sets `first`.
2. The same for bananas (`bananas: 4`). Sets `second`.
3. How many more: the shorter bar's end drops a dashed line across the longer one and the part sticking out shades (the
   web's combine beat); **hop** along it, a block a hop ("Hop the part sticking out."): `3`. In all: **tap to count**
   on along the second bar from the first one's number ("Count on from 7."): `8, 9, 10, 11`.
4. **Write** `7 − 4 = [3]` or `7 + 4 = [11]`. The web's slips (11 for how many more: "'How many more' means compare.
   Take 4 away from 7."; 3 for in all: "'In all' means put them together. Add 7 and 4.").

Say: "The part sticking out is how many more." (In all: "Counting on puts the two bars together.")
Core: the web's (three themes; four values 1–10; problems 0–2 up to 8, all different) with its questions and slips, the
read slips coming from where the line is let go; the spec drops `displayNote`; `first` and `second` set by the drops,
`combine` typed; the check as the spec (i0; i3 how many more; i3 in all; i3 how many more).

### Line plots (`g2-lineplot`) · 2.MD.D.9 · existing, *fold*
**One square:** an inch is a block, as on the ruler. **Picture:** the inch line from lo − 1 to lo + 6 (35 squares), the
title over it; each X a cell a block wide and 3 squares tall, stacked over its number (about 40 × 24). The X's drop in
one at a time as the picture draws, and the stacks the question is about light (the web's two beats). The question on
the top rows. (The examples are the web's own: pencils 4–8 inches long.)
- Plot one more (ask 0): **Place an X** ("Put its X above its length."): the new pencil, drawn at the top with its
  length, gives an X to drop on the line; it snaps to a mark and stacks; readout `6 in`. "That's above 5. The new
  pencil is 6 inches." Sets `plot`. Then **tap** the stack ("Count the X's over 6."): they number, the new one too.
  **Write** `[4] pencils`.
- Tallest stack (ask 1): **tap** it ("Tap the tallest stack."). **Write** `[5] inches`. The X's count typed as the
  length: "That's how many X's. Write the length under the stack."
- Longer than (ask 2): **tap to count** the X's right of 6. **Write** `[2] pencils`. Counting 6's stack too: "Longer
  than 6 doesn't count 6."
- Longest take away shortest (ask 3): **hop** from the leftmost X to the rightmost, an inch a hop ("Hop from the
  shortest to the longest."): `4 in`. **Write** `8 − 4 = [4] in`.

*Fold*, measure and plot (2.MD.D.9's measuring), on problem 2 and then 9, 14, 19, …: five things lie on an inch ruler at
the top, each from 0, their ends on a mark or a square past one (to the nearest inch); the empty plot is lined up under
it (lo 2–4, so the 0–10 ruler fits at 50 squares). **Place an X** for each ("Put each X above its length."); a thing
ending a square past 6 goes over 6: "It's nearest 6." Then tap the tallest stack.
Say: "Each X is one pencil, above its length."
Core: the web's (8–12 lengths from lo to lo + 5, lo 2–8, one tallest stack; problems 0–2 ask 0, 1, 0 with 8 lengths,
later ask by index % 4) with the spec's statement fix; the fold takes problem 2's place and comes back on 9, 14, 19, … (so the
check's i4–i7 keep their kinds); `plot` set by the X, the rest typed; the check as the spec (i4, i5, i6, i7).

## 6 · Time and money (amber)

### Time to 5 minutes (`g2-time5`) · 2.MD.C.7 · existing, *folds*
**One square:** 5 minutes, on the hour strip. **Picture:** 1st grade's clock, 24 squares across, centred on a block
corner, the numbers inside the edge, 60 minute marks with every fifth longer; at its right the hour strip, the hour
before, the hour and the hour after, 12 squares an hour (36). About 64 × 24.
1. **Tap** the number the short hand has just passed ("Tap the hour."): readout `3`; the strip then shows the short
   hand's place, 5 squares past 3 (the web's hour beat). The web's slips ("The short hand is past 3 but has not reached
   4 yet, so the hour is still 3."; "That's the long hand. The hour hand is the short one."). Sets `hour`.
2. **Trace around the clock** from 12 to the long hand ("Trace from 12 to the long hand."): the face shades behind the
   finger, snapping at each number and writing 5, 10, 15, 20, 25 outside the edge (the web's count-by-5s beat). Past
   it: "That's 30. Stop at the long hand." On the hour: "On 12, no minutes have gone by." Sets `number` and `minutes`.
3. **Write** `[3]:[25]`. The web's slips (3:05 "The long hand on 5 means 25 minutes."; 4:25 "The short hand has not
   reached 4 yet, so the hour is 3."; 5:15 "The short hand gives the hour and the long hand gives the minutes.").

Say: "The long hand moves 5 minutes from one number to the next."
*Folds:* a.m. or p.m. on problems 4, 7, 10, …: a time of day over the clock ("School ends.") and a pick under the
record, a.m. or p.m.; then a day strip under the record (midnight, noon in the middle, midnight) drops the time into its
half. Wrong: "School ends in the afternoon: p.m." A digital time on problems 5, 8, 11, …: `3:25` written and the clock
at 3:00; **turn the long hand** round ("Make it 3:25."), snapping at each number, the short hand creeping with it;
readout `3:05, 3:10 … 3:25`. Past: "That's 3:30. Back one number."
Core: the web's (hour 1–12; problems 0–2 minutes 5–30, later 0–55) and slips; `hour` set by the tap, `number` and
`minutes` by the trace, `time` typed. The folds' times of day: a.m. wake up 6–7, breakfast 7–8, school starts 8–9,
recess 10–11; p.m. lunch 12, school ends 2–3, soccer 4–5, dinner 5–7, bedtime 7–9 (the hour drawn to fit). The check as
the spec (i0; i3 where the minutes are 35 or more; i3 on the hour; i3).

### Name the coin (`g2-coins`) · 2.MD.C.8 · existing
**One square:** the coins true to each other's size: a dime 15 squares across, a penny 16, a nickel 18, a quarter 20; a
cent is a 3 × 3 counter. **Picture:** the coin, big, centred on a block corner, its edge bumpy or smooth, the web's art
on its face (a star for heads, two leaves for tails), no name or number; four name blocks under it (about 40 × 28). The
pair kind puts two coins side by side (about 48 wide).
1. **Tap** its name ("Tap its name."): right, its edge traces (the web's edge beat). The web's messages ("The dime is
   the smallest coin and has a bumpy edge. A nickel is bigger and smooth.").
2. **Write** `A dime is [10]¢`; then its cents draw beside it, five to a row (a penny 1, a nickel a row, a dime two
   rows, a quarter a 5 × 5 block: the web's value beat). 5: "A dime is small but worth 10 cents."

Pair kind: both names, then **tap** the coin worth more ("Tap the one worth more."); the cents draw under both, the small
dime's 10 beside the big nickel's 5. "The nickel is bigger, but the dime is worth more: 10 cents to 5."
Say: "A coin's size doesn't tell what it's worth."
Core: the web's (single coins in turn; from problem 5 a pair every third, half of them a dime against a bigger coin
worth less) with its slips; the check as the spec (i0 nickel; i3 dime; i5 where the coin worth more is the smaller one;
i5). The penny's colour: Open questions.

### Counting money (`g2-money`) · 2.MD.C.8 · existing
**One square:** a cent is a 3 × 3 counter, so a dollar is the dollar square, 10 × 10 cents (30 × 30), in four quarter
blocks of 5 × 5. **Picture:** the coins at the left in rows by kind, the biggest on top, each row fanned (each coin 3
squares on from the last; a quarter 8 squares across, a nickel 7, a penny and a dime 6); the empty dollar square at the
right (about 58 × 30).
1. **Slide** in the coins worth most ("Slide in the quarters."): each pours its cents into the square, a quarter a whole
   block; readout `2 quarters`. The readout counts coins, never cents: the cents are the child's to count, by the
   square's fives and tens, and **write** `[50]¢`. (A readout of `25, 50` would hand over every total and the web's
   slips could never happen.)
2. The same for each kind, biggest first, counting on in the record: a dime two rows of five, a nickel a row, a penny
   one: `[60]¢`, `[65]¢`, `[68]¢` (the web's beats: the running total under each kind). A small coin first: "Start
   with the quarters." The web's slips (55 after the dime: "A dime is 10¢, even though it's the smallest coin."; 10
   after the dime: "Keep the 50¢ you already counted and count on from there.").

Say: "Count the coins worth most first, then count on."
Core: the web's (problems 0–2 two kinds of dimes, nickels and pennies; later 1–3 quarters and more; at most 9 coins,
under a dollar) with its slips and the spec's first-group fix; one step per kind, typed; the check as the spec (i0; i3
where there are no dimes; i3 where there are three or more kinds; i3).

### Dollars and cents (`g2-dollars`) · 2.MD.C.8 ($ and ¢, word problems) · new
Depends on `g2-money`, `g2-subregroup`. Two kinds of picture.
- **Bills:** bills 10 × 4 squares, each with its value (`$1`, `$5`, `$10`, `$20`), fanned in rows by kind, the biggest
  on top; at the right the dollar chart, rows of ten $1 cells (each a little bill 3 × 2; 30 × 20 up to $99). **Slide**
  in the bills, biggest first ("Slide in the bills."): a $10 fills a row, a $20 two rows, a $5 half a row, a $1 a cell;
  **write** the total after each kind (`$[20]`, `$[25]`, `$[27]`). Wrong: "A $5 bill is 5 dollars. Count on by 5."
- **Cents stories:** the story on the top rows over Counting money's dollar square, the first amount poured in as its
  coins slide in. Buying: the price, a dashed group, **slides over** the cents and crosses them out ("A pencil is 30¢.
  Slide it over."), readout `30¢ crossed out`; the cents left are the child's to count; **write**
  `45¢ − 30¢ = [15]¢`. Making a dollar: **tap** each empty row and block to fill it ("Fill it to make a dollar."), the
  new cents in the chapter colour, the readout the square's total counting on by 5s and 25s (`70, 75, 100¢`), so the
  child counts what was added; **write** `100¢ − 65¢ = [35]¢`. In all: two amounts pour into one square; **write** `45¢ + 30¢ = [75]¢`.

Say: "Count bills like coins: biggest first." / "100 cents fill the dollar square."
Core (new): bills $1, $5, $10 ($20 from problem 6), 2–7 bills, up to $99; buying (20–99¢ to spend, a price of 10–80¢
that is less than it); making a dollar (10–95¢ in 5s); in all (two amounts, up to 99¢). Problems 0–2: bills of $10
and $1 only, a dollar from a whole ten of cents, buying with no trade; from 3 in turn bills, a dollar, buying, in all. Slips: a $5 counted as $1; a
$20 as $10; what you have typed for what's needed ("That's what you have. How much more makes 100¢?"); a ten off; added
for taken away. Check: i3; i4; i5; i6.

## 7 · Shapes (teal)

### Sides and corners (`g2-shapes`) · 2.G.A.1 · new
Depends on `g1-shapes`. **One square:** a step along a side; corners sit on grid crossings, as in 1st grade.
**Picture:** a shape 15–30 squares across, or an empty patch of paper to draw on; four name blocks under it: triangle,
quadrilateral, pentagon, hexagon.
- **Name it:** **trace a side** along each side, or **tap** each corner ("Count its corners."): each lights and counts,
  readout `5 corners · 5 sides`; Check. One missed: "One corner isn't counted yet." Then **tap** its name.
- **Draw it:** **place corners** ("Draw a shape with 5 corners."): each new corner draws the side from the last; tap
  the first to close; readout `4 sides`. Closed too soon: "That has 4 sides. Draw 5." Sides crossing: "Two sides cross.
  Move a corner." Then its name.

The record: `5 sides, 5 corners: pentagon`.
Say: "5 sides and 5 corners make a pentagon, however it's turned."
Core (new): shapes from corner patterns on grid crossings, wide or thin, turned, some with a dent (a dented hexagon is
still a hexagon); 3–6 sides. Problems 0–2: name a triangle, name a quadrilateral that isn't a square, draw a triangle;
from 3 odd problems name and even ones draw, pentagons and hexagons more often. Steps: `corners` (set by the taps or the
drawing), `name` (the pick). Slips: a corner counted twice; a name one off ("A quadrilateral has 4 sides."); a square not
called a quadrilateral ("A square has 4 sides, so it's a quadrilateral too."). Check: i3 where it's a pentagon; i4 where
it's a hexagon; i5 where it's a turned quadrilateral; i6.

### Faces, edges and corners (`g2-solids`) · 2.G.A.1 · existing · **3D**
**One square:** Unit cubes' scale: a block is a cube's side. **Picture:** flat first, the solid's base on the paper (a
box 3 × 2 blocks, a cube 2 × 2, a square pyramid 2 × 2, a triangular prism 3 × 2), its name hidden.
1. **Tilt** ("Tilt the paper."): the child drags the paper up (Kindergarten's move) and the solid rises from its base
   (the box and cube 2 blocks tall, the pyramid's top 2 blocks up, the prism's roof). The words stay facing the child.
2. **Turn** it and **tap** each face ("Tap every face. Turn it to see more."): it tints and takes its number (the web's
   faces beat); Check when there are no more. Short: "You can see 3. 3 more are hidden at the back and bottom."
3. The same for the edges (each draws in ink) and the corners (a dot pops), each with Check (the web's edges and corners
   beats). Edges short: "Some edges are hidden too. Turn it."
4. **Tap** its name: cube, rectangular prism, pyramid, triangular prism. The web's messages ("A cube's faces are all
   squares. These faces are rectangles: a rectangular prism.").

The record writes `6 faces · 12 edges · 8 corners` as they're found, then the name. The paper lies flat before the next
problem.
Say: the web's ("Every face is a square." / "Its faces are rectangles, not all squares." / "Its side faces meet at one
point at the top." / "It has a triangle at each end.").
Core: the web's (box, triangular prism, cube, pyramid in turn, each turned one of three ways, where the 3D view starts)
with its slips and the spec's "around"; `faces`, `edges` and `corners` set by the counts, `name` by the pick; the check
as the spec (i0 box; i1 prism; i2 cube; i3 pyramid).

### Halves, thirds and fourths (`g2-shares`) · 2.G.A.3 · existing
**One square:** the whole is a size every cut lands on whole squares: a rectangle 48 × 24 (halves 24, thirds 16,
fourths 12 wide, or a cross of 24 × 12), a square 36 × 36 (18, 12, 9), a circle 36 across centred on a block corner.
**Picture:** the whole, big and centred (the square and circle with the record take about 50 rows, so the camera sits
near 90%; at 24 squares the rectangle was barely half the screen). The Same size? kind draws its two copies at half
that, side by side.
1. **Ruler cut**, drawn edge to edge as in 1st grade's Halves and fourths ("Cut it into 3 equal parts."): the cut's ends
   snap to grid points on the outline (on a circle, from the centre out, to equal turns); the readout shows how many
   squares wide each part is, `16 | 16 | 16` (a circle's parts read `the same`). Thirds take two cuts; fourths two (a
   cross) or three (strips). Not equal: "Not equal: 16, 20 and 12 squares wide." Right: the parts number, lift and land on each other,
   matching (the web's match beat). Sets `parts`.
2. **Tap** their name ("Name the parts."): halves, thirds or fourths. The web's slips ("Halves means 2 equal parts.
   Here there are 3.").
3. **Tap** parts to shade them ("Shade 2 thirds."): readout `2 thirds`. Sets `shaded`.
4. **Write** `[3] thirds make 1 whole`. The web's slips (2: "That's only the shaded ones. Count every part."; 1: "The
   whole is made of all the parts. How many thirds fit in it?").

Say: "3 equal parts, so each one is a third."
Same size? (the web's kind, on problems 3, 7, 11, …): two copies side by side (24 × 12 rectangles or 24 × 24 squares,
52 wide), cut two ways (strips and a
cross; across and corner to corner). **Tap** yes or no ("Same size? Tap yes or no."); then a part of one copy lifts,
cuts into pieces and slides onto a part of the other, covering it exactly. No: "They look different, but each is 1 of 4
equal parts of the same rectangle." Then the steps above. Say: "Same whole, same number of parts: the same size."
Core: the web's (rectangle, square or circle; 2–4 parts; problems 0–2 halves or fourths with one shaded; the same-size
kind on index % 4 = 3) with its slips; `parts` (and `cut`, from the child's cut) set by the cut, `name` by the pick,
`shaded` by the taps, `whole` typed; the check as the spec (i3 same size; i4 thirds; i5 two or more shaded; i6 a
circle).

---

## Open questions for G

1. **The penny's colour.** Colour lives only in the maths, but a penny is told apart by its copper colour (the web's
   coin slips say "copper-colored"). Tint the penny copper and the other coins silver-grey, as the real things are, or
   keep every coin in pencil and tell them apart by size and edge alone (and reword the web's colour slips)?
2. **Pictures to 100.** Story problems, Two-step story problems and Lengths on a number line draw one square for each
   thing, so the biggest problems (to 99, as the standard asks) step the camera back to about 65% and the words shrink
   with the paper (words 28 pt become about 18). Keep them to 100, or cap them at 60 so every problem is at full size?
   5th grade's precedent: Mixed numbers to fractions was cut from 6 wholes to 3 because 6 put the camera at 63%. The
   standard asks for 100, so my suggestion is to keep 100 only from problem 6 on and draw a bold line every ten
   squares, so a long bar is counted in tens.
3. **How many lessons.** 27 (the web's 16 and 11 new), each filling a gap in the standards. If 2nd grade should be
   shorter, three could become problem kinds in a lesson we have: Two-step story problems (into Story problems), Rows
   and columns of squares (into Arrays) and Measure with two units (into Inches and centimeters).
4. **Facts every day.** 2.OA.B.2 asks for every one-digit sum by heart. Facts to 20 teaches the quick ways. Should Today
   give 2nd graders a few facts a day (no timer), or is the daily review enough?
5. **The thousand cube.** Hundreds, tens and ones' How to ends with ten hundred flats stacking into a thousand in 3D.
   In that lesson a one is a square, so the cube is 2 blocks on a side and its ones are squares, not Unit cubes'
   blocks. Keep it (the only cube smaller than a block), or leave the thousand flat, as ten flats in a row?
