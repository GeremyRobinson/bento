# 1st grade on paper: every lesson's design

Claude, 1 Nov 2026, in the language of `README.md` and the way `grade5.md` is written. The plan for 1st grade: every
lesson a child needs to finish Common Core Grade 1, in six chapters, each designed for the paper. Nothing here is built
yet; each lesson still needs G's yes on a preview (LESSONS.md §9). Reviewed the same day against the standards, the
web's grade 1 code and `grade5.md`: the clock got a minute strip, Build with solids puts solids together instead of
counting cubes, and the picture graph, halves and three-number pictures were made bigger and countable.

**Standards covered:** all 21 of Common Core Grade 1: 1.OA.1–8, 1.NBT.1–6 (with 2a, 2b, 2c), 1.MD.1–4, 1.G.1–3.
**Lessons:** 26 in all: the web's 14 grade 1 lessons, kept with their maths (generators, easy-first order, derived
values, mistake messages, check recipes, stories), and 12 new ones (ids `g1-…`), each with a new generator written the
same way. Four small gaps are folded into existing lessons as an extra step or problem kind (marked *folded*):
grouping ten ones into a ten (`g1-tensones`), sorting the data (`g1-picgraph`), making the tally marks (`g1-tally`), and
cutting, "quarters" and "more parts are smaller" (`g1-halves`).

## Coverage

| Standard | In short | Lesson | Status |
|---|---|---|---|
| 1.OA.1 | Story problems to 20, all kinds, unknown anywhere | `g1-story` Story problems, `g1-more` How many more? | new, new |
| 1.OA.2 | Stories with three numbers, sum to 20 | `g1-three` Add three numbers (its story items) | existing |
| 1.OA.3 | Any order, any grouping | `g1-add20` (start with the bigger), `g1-ten`, `g1-three`; `g1-doubles` | existing; new |
| 1.OA.4 | Take away by finding what you add | `g1-related` Add to take away; `g1-missing` | new; existing |
| 1.OA.5 | Counting on and back is adding and taking away | `g1-add20`, `g1-sub20` | existing |
| 1.OA.6 | Add and take away to 20 (fluent to 10): count on, make a ten, back through 10, related facts, doubles plus one | `g1-add20`, `g1-ten`, `g1-sub20`; `g1-doubles`, `g1-related` | existing; new |
| 1.OA.7 | What = means; true or false | `g1-equal` True or false? | new |
| 1.OA.8 | The missing number, anywhere | `g1-missing` (`8 + ? = 13`); `g1-equal` (`5 = ? − 3`, `6 + 2 = ? + 3`) | existing; new |
| 1.NBT.1 | Count, read and write to 120 | `g1-count120` Count to 120 | new |
| 1.NBT.2a–c | Tens and ones; a ten is ten ones; teens; 10, 20 … 90 | `g1-tensones` (2a *folded*: the child groups ten ones into a ten) | existing |
| 1.NBT.3 | Compare with <, =, > | `g1-compare` | existing |
| 1.NBT.4 | Add within 100: tens and tens, ones and ones, sometimes a new ten | `g1-addtens`; `g1-add100` Add within 100 | existing; new |
| 1.NBT.5 | 10 more, 10 less | `g1-tenmore` | existing |
| 1.NBT.6 | Take away tens from tens | `g1-subtens` Take away tens | new |
| 1.MD.1 | Order three by length; compare two through a third | `g1-order3` Longest to shortest | new |
| 1.MD.2 | Length in units end to end, no gaps | `g1-measure` | existing |
| 1.MD.3 | Time to the hour and half hour | `g1-time` | existing |
| 1.MD.4 | Sort, show and read data in up to three groups | `g1-picgraph` (sorting *folded*), `g1-tally` (making the marks *folded*) | existing |
| 1.G.1 | What makes a shape that shape; build and draw them | `g1-shapes` What makes a triangle | new |
| 1.G.2 | Put flat shapes and solids together into new shapes | `g1-compose` Put shapes together (flat); `g1-build` Build with solids (3D) | new, new |
| 1.G.3 | Halves and fourths (quarters) of circles and rectangles | `g1-halves` (cutting, "quarters" and "more parts are smaller" *folded*) | existing |

**Fluency within 10** (1.OA.6) is the easy-first rows of `g1-doubles`, `g1-related`, `g1-equal` and `g1-story` (sums
and starts within 10 first), and the daily review. Comparing in stories also comes up in `g1-measure`, `g1-picgraph`
and `g1-tally` ("how many more"), as the web has it.

**The grade's edges.** Below, Kindergarten (the web's lessons and `gradeK.md`'s new ones) counts to 100 on a hundred
chart (`gk-count100`), makes teen numbers as ten ones and more (`k-teens`), makes 10 (`k-make10`), does number bonds and
stories within 10 (`k-bonds`, `k-story`), names and draws flat shapes and joins squares, rectangles and triangles into
bigger ones (`k-shapes`, `gk-draw`, `gk-compose`), names solids (`k-solids`) and says which of two is longer
(`k-length`). 1st grade starts past each of them: counting from any number past 100 and writing it, the ten as a unit,
stories to 20 with the unknown anywhere, what makes a shape that shape, trapezoids and half and quarter circles and new
shapes made from made ones, three lengths and a go-between. Above, 2nd grade has hundreds
as a place (`g2-hundreds`), adding and taking away two-digit numbers in columns with regrouping (`g2-regroup`,
`g2-subregroup`), skip counting, even and odd, inches and centimeters, time to 5 minutes, bar graphs with a scale,
thirds, and faces and edges. So 1st grade counts past 100 by tens and ones but never names a hundred as a place, makes a
new ten only when adding a one-digit number (two two-digit numbers come only when their ones make no new ten), takes
away only tens from tens, measures only in cubes, and cuts only in halves and fourths. The 5th grade plan (17 lessons
and 9 new ones, being finished separately) touches none of this.

## How 1st grade uses the grid

- **One counter is 3 × 3 squares** in every number lesson. A ten is a row of ten, 30 squares across; rows start on a
  block line, so the strong lines fall after every fifth counter and fives and tens are on the paper for free. 20 is
  two rows: the top row is the ten. More tens stack below, a row each, so the place value chapter's 34 is three full
  rows and 4. The number line is the same size: one step is 3 squares, 0 to 20 is 60 squares, and every 5 sits on a
  strong line. Counters on a row sit exactly over the line's steps.
- **From K:** Kindergarten gives every thing a block (`gradeK.md`: a dot 3 squares across in the middle of its block).
  1st grade keeps the same dot and closes the gaps, so 20 fit in a row and 9 tens fit on the screen. The 120 chart is
  K's hundred chart grown to 12 rows, still one block a number, so its rows are tens too.
- **One cube is one block** where something is measured (`g1-measure`, `g1-order3`) and in 3D (`g1-build`): the Unit
  cubes rule. A picture graph's picture is a block too (`g1-picgraph`), so the strong lines are its columns. On the
  clock's hour strip one square is one minute (`g1-time`). Halves and fourths are whole squares (`g1-halves`).
- **Small hands:** nothing a child taps or grabs is smaller than 3 × 3 squares (60 pt, 75 pt at 125%). A row is grabbed
  anywhere along it. Drags snap, so a shaky finger still lands on a counter, a step or a grid point.
- **Words:** one short line, at most about 8 easy words ("Slide them in.", "Hop to 10.", "Tap the longest."). The
  numbers are on the picture, not in the sentence. A miss's line is measured on the paper ("That's 4 hops. Hop 3.").
  The last line says why, in 10 words or fewer. Stories are 2 or 3 short lines over the picture they act out.
- **The record** is what a 1st grader writes: `8 + 5 = 10 + 3 = 13`, `34 + 10 = 44`, `43 < 47`, `8:30`. Typing is
  only for the number school writes, one box at a time.
- **Two of the same, side by side** (two rows lined up) is how 1st grade compares everything: numbers, lengths, rows of
  a graph, the two sides of `=`. The extra ones stick out past the shorter row, and they're the difference.
- Layout as in `grade5.md`: the instruction on rows 0–2, a miss on rows 3–4 (red), the picture from row 6 (its names
  at its right end), the record 3 rows under it, the blocks under the record. The screen is about 68 × 45 squares.

## Hand moves

From the kit (`README.md`): **slide pieces** (counters, rows, tens, shape pieces), **tap** (rows, pictures, word
blocks, the sign), **hop along a line** (`g1-add20`, `g1-sub20`, `g1-missing`; laying cubes in `g1-measure` is the same
move with cubes), **drag a point** (the ring on the chart in `g1-tenmore`), **ruler cut** (`g1-halves`), **write**.
Not in the kit yet (four are new in `gradeK.md` too, and keep K's names):

| New move | What it does | Used by |
|---|---|---|
| Tap to count (K's) | tap each counter, place, picture or mark, or drag along them; each gets the next number, the readout is the count | `g1-count120`, `g1-tensones`, `g1-picgraph`, `g1-tally`, `g1-story` |
| Drag a row's end | a row grows or shrinks behind the finger, a counter at a time, counted | `g1-related`, `g1-equal`, `g1-story`, `g1-more` |
| Group a ten | tap a full row of ten loose counters; they close into one ten | `g1-tensones` |
| Drag into order | drop a thing on another's row and they swap | `g1-order3` |
| Sort | tap a picture in the pile; it goes to the next place in its row | `g1-picgraph` |
| Make a mark | tap a thing; its row gets a tally mark, every fifth across the four | `g1-tally` |
| Trace around the clock | drag the long hand's way from 12; the face shades, the hour strip under it fills a square a minute, and the minutes read out | `g1-time` |
| Trace a side | drag along a shape's side; it darkens and counts | `g1-shapes` |
| Place corners (K's) | tap grid crossings to put corners; the sides join; tap the first corner to close | `g1-shapes` |
| Turn a piece (K's) | tap a shape piece; it turns a quarter turn | `g1-compose` |
| Place it (K's, 3D) | drag a solid across the tilted floor, block by block, onto the outline or onto another solid; it snaps when it sits in the shape | `g1-build` |

## Chapters (teaching order)

| # | Chapter | Lessons (in order) | Colour |
|---|---|---|---|
| 1 | Add and take away to 20 | `g1-add20` Add within 20 · `g1-ten` Make a ten to add · `g1-doubles` Doubles and near doubles · `g1-three` Add three numbers · `g1-sub20` Subtract within 20 | whole-number purple |
| 2 | Equations and stories | `g1-related` Add to take away · `g1-missing` Missing numbers · `g1-equal` True or false? · `g1-story` Story problems · `g1-more` How many more? | fractions blue |
| 3 | Numbers to 120 | `g1-count120` Count to 120 · `g1-tensones` Tens and ones · `g1-compare` Compare two-digit numbers · `g1-tenmore` 10 more, 10 less | decimals pink |
| 4 | Adding and taking away tens | `g1-addtens` Add tens to a number · `g1-add100` Add within 100 · `g1-subtens` Take away tens | whole-number purple |
| 5 | Length, time and graphs | `g1-order3` Longest to shortest · `g1-measure` Measure length · `g1-time` Time to the hour and half hour · `g1-picgraph` Picture graphs · `g1-tally` Tally charts | measurement amber |
| 6 | Shapes and equal parts | `g1-shapes` What makes a triangle · `g1-compose` Put shapes together · `g1-build` Build with solids (3D) · `g1-halves` Halves and fourths | geometry teal (the new 5th grade colour) |

The colours reuse the app's chapter colours; chapters next to each other on the map differ. Depends-on lists keep
`specs/k12/gradeK-1.md` for the 14 existing lessons; each new lesson names its own below.

## 1 · Add and take away to 20 (counters 3 × 3, the line 3 squares a step)

### Add within 20 (`g1-add20`) · 1.OA.3, 1.OA.5, 1.OA.6 · existing
The number line 0 to 20 on row 18: 60 squares, 0 on the block line 5 squares in, a tick every 3 squares, each number
under its tick (small, 20 pt), 5, 10, 15 and 20 on strong lines. Above it the two numbers as two rows of counters, `a` in the
chapter colour and `b` striped, each with its number at its right end (they are the problem).
1. **Drag** the bigger row down onto the line: it lies from 0 to its number and that point rings ("Start at 9"). The
   smaller row: it slides back, "That works, but it's a long count. Start at 9, then count on only 3." When the bigger
   was second, the record writes `3 + 9 = 9 + 3` (the turn-around, seen).
2. **Hop** on from the start: tap ahead (or drag) and each hop arcs one step, taking one counter off the small row; the
   readout says where it lands ("10, 11, 12"). The hops stop when the small row is empty. A hop back: "Hop forward to
   add."
3. **Write** `3 + 9 = [12]` (the web's slips: 11 "One short. Don't count 9 again: your first hop lands on 10."; 13;
   6 "That's taking away."). The landing point gets a bracket, "3 more".
Say: "Start big, so there are fewer hops."
Core: the web's generator (small 2–3 for the first three, then 2–5; big from max(small + 1, 11 − small) to
20 − small; either order). `start` set from the drag, `count-on` typed. Check as in `gradeK-1.md`.

### Make a ten to add (`g1-ten`) · 1.OA.6, 1.OA.3 · existing
Two rows of ten places (dashed 3 × 3 places, 30 squares, a square apart): the top row holds `a` counters from the left,
the bottom row `b` striped. Each row's number at its right end.
1. **Slide** counters up from the bottom row into the top row's empty places, one or several at a time; each snaps into
   the next empty place. Readout "8 and 2 make 10". When the top row is full its outline goes bold and "10" is written
   at its end; the bottom row's number becomes what's left (`ten` and `break` set from the move). One more when it's
   full: it slides back, "The top row is full. That's 10."
2. See: what's left slides to the start of the bottom row, under the ten.
3. **Write** `8 + 5 = 10 + 3 = [13]` (slip 3: "That's only the ones left over. The full row is 10 more.").
Say: "A full ten makes the rest easy to add."
Core: the web's generator (`a` 8–9 and `b` up to 6 for the first three, then `a` 6–9, `b` 11 − a to 9). `add` typed.

### Doubles and near doubles (`g1-doubles`) · 1.OA.6 (an easier known sum), 1.OA.3 · new
Depends on `g1-add20`, `k-bonds`. Two rows of counters: `a` (chapter colour) on top, from the start line; `b`
(striped) below it, a block lower and 2 blocks to the right; up to 10 each (30 squares).
1. **Slide** the bottom row under the top row: it snaps when its left end meets the start line. A line joins each
   pair; an extra counter stands alone, ringed. Readout "6 pairs and 1 more" (or "5 pairs" for a double).
2. **Write** `6 + 7 = 6 + 6 + 1 = [12] + 1 = [13]` (school's `12 + 1`, the 12 typed), or `5 + 5 = [10]` for a double.
   Slips: 11 or 13 for the double "A double is the same number twice: 6 and 6 more."; 6 "That's one 6. Double 6 is 6
   and 6."; 12 for the sum "That's the double. Add the extra one."; 14 "14 is double 7. Double 6 is 12, then 1 more."
Say: "6 + 7 is double 6 and 1 more." (A double: "The same number twice.")
Core (new generator): the first three are doubles `d + d`, `d` 1–5; the next three near doubles `d + (d + 1)`, `d`
2–5, either order; then `d` 2–9, a double one time in three, else a near double, either order (sum ≤ 19). Check: i0;
i3; i6 where it's a double with `d` ≥ 6; i6 where it's a near double with `a` > `b`.

### Add three numbers (`g1-three`) · 1.OA.2, 1.OA.3 · existing
Three groups of counters, one per number (up to 9, 27 squares), a square apart, solid, striped and dotted, each number
at its group's end. A block under them, the twenty: two rows of ten dashed places (30 squares each, a square apart), the
same two rows as `g1-ten`, so the whole picture is about 35 × 25 squares and the camera frames it at 125%. Story items
put the web's story over the picture in two short lines ("Maya has 7 red, 5 blue and 3 green beads. How many in
all?"), the beads as the three groups.
1. **Tap** two groups that make 10 or a double (the web's `pick` step, when it offers one; otherwise the two groups
   light for the child). Wrong pair: "4 and 3 make 7. Look for two that make 10."
2. **Slide** the two into the top row: they fill its places from the left, the second running on from the first.
   A ten fills the row exactly (its outline goes bold, `10` at its end); a double past 10 spills on into the bottom
   row. Readout "7 and 3 make 10" (`first` set from the move; the web also accepts the first two).
3. **Slide** the last group in: it fills on from the last counter, the count running on ("11, 12 … 15").
4. **Write** `7 + 5 + 3 = 10 + 5 = [15]` (the web's slips: 10 "Left one out", 14, 16, 18 "You added the 3 twice").
Say: "Any order works, so make 10 first."
Core: the web's generator (sums to 12 for the first three, then 20; ten pairs, doubles, or neither) and its story.

### Subtract within 20 (`g1-sub20`) · 1.OA.6 (back through 10), 1.OA.5 · existing
The line 0 to 20 as in `g1-add20`, with `a` counters over it from 0 (the tenth ends on the strong line at 10). The
number to take away is written once, in the record's first line, `14 − 6`.
1. **Hop back** from `a`: drag a hop to the left; it snaps a step at a time, crossing out the counters it passes;
   readout "−4". Let go on 10 (`to-ten`). Short of 10: "Hop all the way back to 10. 14 is 10 and 4 more." Past it:
   "Stop at 10 first."
2. **Hop back** again from 10; the readout keeps the running total ("6 taken"); let go when 6 are taken (`rest` set
   from the hop). Too far: "That takes 7. Take 6."
3. **Write** `14 − 6 = 14 − 4 − 2 = 10 − 2 = [8]` (the web's slips: 12 "This is taking away…", 9 "Count back one for
   each: start at 9, not 10.", 7).
Say: "Back to 10 first, because taking from 10 is easy."
Core: the web's generator (`a` 11–14 for the first three, then 11–18; `b` from `a` − 9 to 9). `from-ten` typed.

## 2 · Equations and stories (counters 3 × 3; two rows lined up)

### Add to take away (`g1-related`) · 1.OA.4, 1.OA.6 (related facts) · new
Depends on `g1-sub20`, `k-bonds`. The problem `12 − 8` is the record's first line. The picture: the whole as one row of
`c` places, outlined, `12` at its right end; under it a row starting with the `a` counters (chapter colour, `8` at
their end), the rest of that row empty.
1. **Drag** the end of the bottom row out: striped counters fill in behind the finger, counted ("1, 2, 3, 4"; readout
   "8 + 4"). Let go level with the whole's end. Past it: "That's past 12." Short: "It doesn't reach 12 yet."
2. See: the striped part lifts out of the whole, and the whole's row shows `8 | 4`.
3. **Write** `8 + 4 = 12`, so `12 − 8 = [4]`; then the other two facts of the family draw in under it (`4 + 8 = 12`,
   `12 − 4 = 8`). Slips: 20 "That's adding. Taking away leaves less than 12."; 8 "That's the part you take. Find the
   other part."; 3 and 5 "Count the striped ones again."
Say: "The part you add to 8 is the part left."
Core (new generator): the first three `c` 6–10 and `a` 2 to `c` − 2 (fluency within 10); then `c` 11–18 and `a` from
`c` − 9 to 9. Check: i0 (within 10); i3 where `c` ≥ 15; i4 where `a` < `c` − `a`; i4.

### Missing numbers (`g1-missing`) · 1.OA.8, 1.OA.4 · existing
The record's first line is the problem, `8 + ? = 13` (or `? + 8 = 13`). The number line 0 to 20 (as `g1-add20`), `a`
ringed as the start and `c` flagged as the end.
1. **Hop** from 8 up to 10: drag; readout "+2"; let go on 10 (`to-ten`). Past it: "Stop at 10 first."
2. **Hop** from 10 to 13: readout "+3"; let go on 13 (`past-ten`). Short: "Keep going to 13." Past: "That's past 13."
3. See: one bracket over both hops, "2 + 3".
4. **Write** `8 + [5] = 13` (the web's slips: 13 "13 is already there…", 21 "That adds 8 too…", 2 "Add both hops…").
For `? + 8 = 13` the hops are the same, from the 8 you know.
Say: "Count up from the number you know."
Core: the web's generator (`a` 6–9 for the first three, then 2–9; `c` 11 to min(18, `a` + 9); `? + a` only after the
first three). `missing` typed.

### True or false? (`g1-equal`) · 1.OA.7, 1.OA.8 · new
Depends on `g1-related`, `g1-missing`. The equation written once, big, as the record's first line (`4 + 1 = 5 + 2`). Under
it, each side's amount as counters from one start line: the left side on top, the right side under it. A sum's second
part (striped) sits a block to the right of its first, as the equation spaces it; a take away's last counters are
crossed out; a single number is one row.
**True or false** (the first problems):
1. **Slide** each side's second part up against its first (or the crossed-out ones off, for a take away): the side
   becomes one row, its amount at its end. A dashed line drops from the shorter row's end; readout "5 and 7".
2. **Tap** True or False (two word blocks under the record). Wrong: "Not the same: 5 and 7." / "Both rows are 7. That's
   the same amount." The word is written after the equation.
**Make it true** (later): a box anywhere, `6 + 2 = [ ] + 3`, `5 = [ ] − 3`, `[ ] = 4 + 3`, `9 − [ ] = 6`.
1. **Drag** the box's row (striped) until the two rows end level; readout "5 and 3 make 8". For `5 = [ ] − 3` the row
   grows with its last 3 crossed out until 5 are left (readout "8 take away 3 is 5").
2. **Write** the box (slips: 11 "The box and 3 make 8 together."; 8 "6 + 2 is 8. The box goes with 3 to make 8."; for
   `5 = [ ] − 3`, 2 "The box is the start. 3 go, 5 are left.").
Say: "= means both sides are the same amount."
Core (new generator): the first three true or false with one side a single number, on either side of the = (`7 = 4 + 3`
as often as `4 + 3 = 7`, and now and then `6 = 6`), within 10, true half the time (false by 1 or 2); then both sides
sums or take aways, turn-arounds among them; from the 7th, make it true with the box in any
place, within 20. Check: i0; i4 where it's false; i6 where the box is left of the =; i7.

### Story problems (`g1-story`) · 1.OA.1 · new
Depends on `k-story`, `g1-related`. The story in 2–3 short lines over the picture ("5 birds sit. 3 more come. How many
now?"). The things are counters on one row of 20 places (60 squares); every number in the story names its group at the
group's end. Every kind of 1st grade story, the unknown anywhere:
- **Joining, the end unknown** (add to, put together): **slide** the new group onto the row's end; the count runs on.
- **Going away, the end unknown** (take from): **slide** the leaving ones off the end; they're crossed out as they go
  and the count of what's left runs down.
- **How many came, or went** (change unknown): the start group is on the row and a dashed outline shows the end ("now
  8"). **Drag** counters in until the outline is full, or off until only the outline's 5 are left; the readout counts
  the ones moved.
- **The start unknown**: the row shows now (8), the ones that came striped at its end. **Slide** them back off (undo the
  story); what's left is the start. For "3 flew away, 5 are left", **slide** the 3 back on.
- **Taking apart** ("8 birds, 5 red, the rest blue"): the row of 8 with 5 shaded; **drag across** the rest to count them.
Then **Write** the story as an equation with the box where the story's unknown is, `5 + [ ] = 8`, `[ ] + 3 = 8`,
`8 − [ ] = 5`, and type the box. Slips: the total typed for a part ("8 is how many now. How many came?"); the two
numbers added ("13 is 5 and 8 together. Some came to make 8."); adding when some went away ("Some flew away, so there
are fewer.").
Say (by kind): "More came, so add." · "Some went away, so take away." · "Undo the story to find the start." · "Fill up
to the end to see how many came."
Core (new generator): the first three have the end unknown, within 10 (joining, going away, putting together); the
next three the change or a part unknown, within 20; from the 7th any kind, the start unknown only from there. Names from
the web's list (Maya, Leo, Ana, Sam, Noor, Eli); things birds, apples, shells, cars, books, frogs. Check: i0; i3 where
the change is unknown; i6 where the start is unknown; i7 where it's taking apart.

### How many more? (`g1-more`) · 1.OA.1 (comparing) · new
Depends on `g1-story`, `k-compare`. Two rows lined up from one start line, one per child, each child's name and number at
the row's end ("Maya 9"). The story in 2 lines above.
- **How many more** (or fewer): lines join the pairs as the rows draw. **Tap** or drag across the counters in the
  longer row that have no partner: they light, counted ("4 more"). A counter with a partner: "That one has a partner.
  Count the ones past Leo's row."
- **The bigger one unknown** ("Leo has 5. Maya has 4 more."): Maya's row starts as 5 dashed partners; **drag** its end
  out 4 more (readout "5 and 4 more").
- **The smaller one unknown** ("Maya has 9. Leo has 4 fewer."): **drag** Leo's row back from 9 until 4 of Maya's have
  no partner (readout "4 fewer").
Then **Write** `9 − 5 = [4]`, `5 + 4 = [9]` or `9 − 4 = [5]`. Slips: the two added, 14 ("How many more means the extra
ones. Take away." the web's own); 1 for "4 more than 5" ("Maya has more, so her row is longer."); 13 for "4 fewer than 9"
("Leo has fewer, so his row is shorter.").
Say: "Line them up: the extra ones are how many more."
Core (new generator): the first three ask how many more, both rows 10 or fewer; the next three find the bigger or the
smaller one with matching words ("more" to find the bigger); from the 7th any kind within 20, including "fewer" and the
mixed-up wording ("Leo has 4 fewer than Maya. Leo has 5. How many does Maya have?"). Check: i0; i3 where the bigger is
unknown; i4 where the smaller is unknown; i7 where the wording is mixed up.

## 3 · Numbers to 120 (a ten is a row: on the chart and in counters)

### Count to 120 (`g1-count120`) · 1.NBT.1 · new
Depends on `gk-count100`, `k-tens`. The 120 chart: K's hundred chart grown to 12 rows, one block a number, ten to a
row (50 squares), so every row is a ten. The numbers are written in their blocks (small, one square a digit, centred).
Shown: the rows the count passes, and one row above and below (up to 4 rows, 20 squares tall). K counts 1 to 100 on it;
here the count starts anywhere, goes past 100, and the child writes the numbers.
**Count on** (most problems): the start number is in its place; the next 5 to 8 places are empty, two of them boxed.
1. **Tap to count**: drag along the empty places from the start; the readout says each number as the finger enters
   it ("98, 99, 100, 101"); at a row's end the finger goes on at the next row's start. Skipping a place: "You skipped
   one. Touch each place."
2. **Write** the boxed places (typed), always the one after a ten ends and the one past 100 when the count gets there.
   Slips: 1001 for 101 "101 is 100 and 1 more: 1, 0, 1."; 1000 for 100 "100 is 10 tens: 1, 0, 0."; 10010 for 110
   "110 is 100 and 10: 1, 1, 0."; 310 for 40 "After 39 comes a new ten: 40."; one off "Touch each place once."
**How many?** (from the 7th problem, every third): the chart from 1, its first `n` places shaded. 1. **Tap** each full
row: it counts by tens ("10, 20 … 110"). 2. **Tap to count** the rest ("111, 112, 113"). 3. **Write** `[113]`
(slip 1103 "113 is 11 tens and 3: 1, 1, 3."). The chart is drawn whole (60 squares tall), so the camera steps back to
about 65%; a block is still 65 pt.
Say: "After 9 ones comes a new ten." (At 100: "Ten tens is 100, and counting goes on.")
Core (new generator): the first three start 20–89 and count 5, passing one ten; the next three start 94–99 and pass
100; then any start from 1 to 120 less the count (so the count never passes 120), counting 5–8, or a how-many of
21–120. Check: i3 where it passes 100; i3 where it passes a ten
under 100; i6 a how-many over 100; i4. Its slips are bigger than 120 (1001, 10010), so this lesson's slip list keeps
them (the web's `slips` drops anything over 120).

### Tens and ones (`g1-tensones`) · 1.NBT.2a, 2b, 2c · existing
Counters 3 × 3 arrive loose in rows of ten (a full row is 30 squares, each counter outlined on its own), rows a square
apart, the last row short. Up to 9 tens and 9 ones is 40 squares tall, so the camera steps back for 6 tens or more.
1. **Group** (*folded*, 1.NBT.2a): tap a full row: its ten counters close into one ten (their inner lines go faint, a
   bold outline, `10` at its end). Readout "1 ten, 2 tens, 3 tens" (`tens` set once every full row is grouped). The
   short row: "That's only 4. A ten needs 10."
2. **Tap to count** the ones left: "1, 2, 3, 4" (`ones`; none left: "No ones on their own.").
3. **Write** `3 tens and 4 ones is [34]` (the web's slips: 7 "Each ten is worth 10, not 1…", 43 "The tens come
   first…", 30 "That's only the tens…").
Say: "The first digit counts tens; the second counts ones."
Core: the web's generator (11–39 for the first three, then 11–99). Teens (2b) and whole tens (2c) come up in it; the
web's check asks for a whole ten.

### Compare two-digit numbers (`g1-compare`) · 1.NBT.3 · existing
Both numbers as tens (grouped rows) and ones, side by side, a block between (65 squares); each number written over its
stack, so the problem is the picture's names. The two stacks' rows sit on the same grid rows, so more tens reach lower
(9 tens and their ones are 40 squares tall, so the camera steps back for 7 tens or more, as in `g1-tensones`).
1. **Tap** the number with more tens. Same tens: either tap says "Same tens: 4 and 4. Look at the ones.", the ones
   rows light, and the child taps the one with more ones (same ones too: "Same tens, same ones."). Wrong: "52 has 5
   tens and 39 has 3. 5 tens is more." (`tens`, `ones` set from the picture.)
2. **Tap** the sign (`<`, `=`, `>` blocks under the record): it's written between the numbers. The web's slips ("The
   open side faces the bigger number, 47."; "43 and 47 are not the same number.").
3. The record: `43 < 47`.
Say: "More tens is bigger; with the same tens, more ones is bigger."
Core: the web's generator (different tens for the first three; then same tens 4 times in 10, equal 1 in 10).

### 10 more, 10 less (`g1-tenmore`) · 1.NBT.5 · existing
The chart rows of `g1-count120`: `n`'s row, the row above and the row below (50 × 15 squares), `n` ringed.
1. **Drag** the ring straight down (10 more) or up (10 less): it snaps a row at a time; readout "+10" (`tens` and
   `newtens` set from the move). A place sideways: "That's 1 more. 10 more is one row down." The wrong way: "That's 10
   less. Go down for 10 more."
2. See: both numbers' tens digits light; the ones digit stays put, underlined in both.
3. **Write** `34 + 10 = [44]` (the web's slips: 35 "That's 1 more…", 24 "That's 10 less…", 4 "That's only the
   tens…").
Say: "One row down is one more ten; the ones stay."
Core: the web's generator (10 more for the first two; `n` 11–49 for the first three, then 11–89; ones kept early).

## 4 · Adding and taking away tens (tens rows and ones, counters 3 × 3)

### Add tens to a number (`g1-addtens`) · 1.NBT.4 · existing
`n` as tens rows and its ones row; to the right, `k` new tens (striped), `+ 30` over them.
1. **Slide** the new tens in: they snap under `n`'s tens and the ones row moves down below them; readout "2 tens and 3
   tens: 5 tens" (`k`, `tens` set from the move). Dropped on the ones: "Tens go with the tens."
2. **Write** `23 + 30 = [53]` (the web's slips: 26 "You added 3 ones…", 50 "Don't forget the 3 ones…", 8 "5 tens is
   50…").
Say: "Tens join the tens, so the ones stay the same."
Core: the web's generator (tens 1–4 and 2–3 new tens for the first three; then 1–8 and 1 to 9 − tens).

### Add within 100 (`g1-add100`) · 1.NBT.4 · new
Depends on `g1-addtens`, `g1-ten`. `a` as tens and ones; `b` beside it, its tens (if any) and its ones striped.
1. **Slide** `b`'s ones onto `a`'s ones row: they snap in after its ones, counting on ("37, 38, 39, 40"). When the row
   is full it closes into a new ten and joins the tens (as the top row fills in `g1-ten`); the rest start a new ones
   row ("41, 42, 43"). Readout "36 + 4 = 40, then 3 more".
2. When `b` has tens: **slide** them under the tens first, as in `g1-addtens`, then the ones.
3. **Write** `36 + 7 = 40 + 3 = [43]`, or `24 + 35 = 50 + 9 = [59]`. Slips: 33 "The 6 and 7 ones made a new ten.";
   106 "7 is ones. It goes with the 6 ones."; 77 "Tens go with tens: 2 tens and 3 tens."; 14 "Each ten is worth 10,
   not 1."; one off "Count on again."
Say: "Ones go with ones, and ten ones make a new ten."
Core (new generator): the first three a two-digit number 21–79 and a one-digit 2–9 that make no new ten; the next three
make a new ten (sum ≤ 99); from the 7th, one in three is two two-digit numbers (11–69) whose ones make no new ten
and whose sum is 99 or less. A new
ten from two two-digit numbers stays in 2nd grade (`g2-regroup`). Check: i0; i3; i3 where the ones make exactly 10; i6
where `b` has two digits.

### Take away tens (`g1-subtens`) · 1.NBT.6 · new
Depends on `g1-addtens`, `g1-tenmore`. `a` as tens rows (10–90), `− 30` beside it.
1. **Slide** tens away to the right, one row at a time; each is crossed out where it lands; readout "take 1 ten,
   2 tens, 3 tens". One too many: it slides back, "That's 4 tens. Take 3." Then the rows left count: "4 tens".
2. **Write** `70 − 30 = [40]` (slips: 4 "That's 4 tens. 4 tens is written 40."; 67 "30 is 3 tens, not 3 ones."; 100
   "That's adding.").
Say: "It's 7 − 3, but in tens."
Core (new generator): the first three `a` 40–90 and `b` 10–30; then `a` 20–90 and `b` 10 to `a` (sometimes all of it:
0 left). Check: i0; i3 where `b` = `a`; i3 where 10 is left; i4.

## 5 · Length, time and graphs

### Longest to shortest (`g1-order3`) · 1.MD.1 · new
Depends on `k-length`. One cube is one block, so every thing is a whole number of blocks long (2–12, 60 squares at
most) and 1 block tall; the things are the web's (pencil, crayon, ribbon, straw, spoon, leaf, brush, key), drawn as
plain bars with their names at their right ends. A dashed start line on the left.
**Order three** (most problems): the three lie scattered, starting in different places.
1. **Drag** each one to the start line: it snaps with its left end on the line (elsewhere: it slides back, "Put its
   end on the line."). Now the far ends tell.
2. **Drag into order**, longest on top: drop one on another's row and they swap; the readout names the top and bottom
   rows "longest" and "shortest". Wrong order on letting go: "The straw goes past the pencil's end, so it's longer."
3. The record: `ribbon, pencil, key`, longest to shortest.
**Use a go-between** (the 7th, 10th, 13th … problems): two things that can't move ("These two are stuck."), one lying
across the paper and one standing up its side, so their ends can't be lined up, and a string that can move. The one
standing is at most 6 blocks (30 squares, rows 6–36), so the whole picture fits the screen with the record under it.
1. **Drag** the string along the first, its end on that thing's end: a mark is drawn on it where the thing stops.
2. **Drag** it along the second: the mark lands before or past the second's end, and the gap is a count of blocks.
3. **Tap** the longer thing. Wrong: "The desk stops before the mark, so the rug is longer." The record: `The rug is
   longer than the desk.`
Say: "Line up the ends; the one that goes farthest is longest." (Go-between: "The string was as long as the rug, and
the desk is shorter.")
Core (new generator): three different things and lengths 2–12, the first three at least 2 apart; then 1 apart allowed;
from the 7th, every third a go-between (things from the web's list plus rug and desk, lengths 3–6, never equal). Check:
i0; i4 where two lengths are 1 apart; i6 (a go-between); i7.

### Measure length (`g1-measure`) · 1.MD.2 · existing
One cube is one block (the Unit cubes rule). The two things as bars 2 squares tall, `a` and `b` blocks long (2–12),
one above the other, both from the dashed start line, each name at its right end; room for a row of cubes under each.
1. **Lay cubes** under the first: tap at the start line (or drag along) and each tap lays the next cube end to end,
   counted ("1, 2 … 7"); the hop move, with cubes. A first cube away from the line: "Start at the dashed line." One
   past the end: "That's past the end of the pencil." (`first`)
2. The same under the second (`second`).
3. **Tap** the cubes of the longer row that stick out past the shorter one's end: counted ("3 more").
4. **Write** `7 − 4 = [3]` cubes longer (the web's slips: 11 "That's both together…", 7 "That's how long the pencil
   is…").
Say: "Cubes end to end, no gaps: the count is the length."
Core: the web's generator (lengths 2–8 for the first three, then 2–12, never equal).

### Time to the hour and half hour (`g1-time`) · 1.MD.3 · existing
**One square is one minute.** A clock face 20 squares across (radius 10, centred on a block corner, so its edge
touches the strong lines), its numbers inside the edge, the short hand thick, the long hand long. Under it the hour
strip: one hour is 60 squares (12 blocks, one block for each number on the face), 3 squares tall, the hour at its left
end and the next hour at its right (`8` … `9`), so half past is the strong line in its middle, 30 squares in. Clock and
strip together are 60 × 27 squares, from row 6; the record is 3 rows under the strip.
1. **Tap** the number the short hand points at, or has just passed. The next number: "The short hand hasn't reached
   9 yet. It's still 8." The long hand's number: "That's the long hand. The short hand tells the hour." (`hour`)
   See: the hour is written at the strip's left end and the next hour at its right.
2. **Trace around the clock**: drag the long hand's way from 12, clockwise; the face shades behind the finger, and the
   strip fills under it a square for each minute (a block for each number the finger passes); the readout counts
   ("30 minutes"). Let go on the long hand. Past it: "That's past the long hand." The wrong way: "Clocks go this way."
   On the hour, tap the 12: the strip stays empty, "0 minutes". (`minute`)
   See: the short hand moves on with the strip, so at half past it is half way from 8 to 9, as the strip is half full.
3. **Write** `[8] : [30]`; "half past 8" is written beside it (the web's slips: 8:6 "The long hand points at 6, but
   that means 30 minutes."; 6:30 "The short hand tells the hour…"; 9:30 "It's still 8.").
Say: "Half way round is half the hour: 30 minutes." (On the hour: "Long hand on 12: a new hour starts.")
Core: the web's generator (hour 1–12; the second problem on the hour; then on the hour or half past).

### Picture graphs (`g1-picgraph`) · 1.MD.4 · existing, sorting *folded*
One picture is one block (5 × 5 squares, the picture 3 squares across in its middle, as K draws its things); three
rows of up to 9 (45 squares) from one start line, a square apart, each row's name in front of it (small, 10 squares),
the graph's title over it (small). The strong lines are the graph's columns, so every picture sits over the one above
and a longer row is plainly longer. The picture is 55 × 20 squares.
*Folded* (organize and show the data): the first three problems start with the pictures in a pile above the graph.
**Sort**: tap a picture and it goes to the next place in its row; the row's count is written at its end as it grows.
Then the web's ask:
- **Read a row**: **tap to count** along it ("1, 2 … 8"); **write** `Fish: [8]`; then, when the web asks,
  **tap** Longer or Shorter.
- **Most or fewest**: **tap** the row.
- **How many more**: **tap** the pictures past the shorter row's end, counted ("5 more"); **write** `8 − 3 = [5]`.
- **Together**: **slide** one row onto the end of the other; the count runs on; **write** `6 + 3 = [9]`.
The web's slips (another row's count; one short "Touch each picture once…"; "Added instead"; "Subtracted instead").
Say: "One picture for each, so the longest row has the most."
Core: the web's generator (three different counts 1–9; asks 0 and 1 for the first three, then each in turn).

### Tally charts (`g1-tally`) · 1.MD.4 · existing, making the marks *folded*
A mark every 2 squares, 3 squares tall; four marks and the fifth across them make a bundle two blocks wide, so bundles
line up under bundles. Three rows (up to 14 marks, 28 squares), names in front.
*Folded*: the first three problems make the chart: the things to count sit above it; **make a mark**: tap each thing,
its row gets a mark, and every fifth goes across the four.
Then the web's ask:
- **Read a row**: **tap** each bundle ("5, 10"), then **tap to count** the single marks ("11, 12"); **write**
  `Apples: [12]`.
- **How many more**: the rows line up; **tap to count** the marks past the shorter row's end; **write**
  `9 − 4 = [5]`.
- **In all**: **tap** each row in turn; the readout keeps the running total; **write** `7 + 4 + 9 = [20]`.
The web's slips ("Each bundle is 5, not 1…"; "The line across is the 5th mark of its bundle…"; a row left out).
Say: "Every fifth mark goes across, so count by 5s."
Core: the web's generator (counts 1–9 for the first three with a bundle to read, then 1–14; in all at most 20).

## 6 · Shapes and equal parts (one square is one step of a side)

### What makes a triangle (`g1-shapes`) · 1.G.1 · new
Depends on `gk-draw`, `k-shapes`. K names and draws shapes; here the question is what makes a shape that shape, and
what doesn't matter. One shape with its corners on grid points, 10 to 30 squares across: big or small, upright or
turned, wide or thin, or a near miss (a gap, a curved side, a side bent in two). The question over it: "Is it a
triangle?" (later a rectangle, a square, a hexagon). An empty patch of paper beside it.
1. **Trace a side**: drag along each side; it darkens and counts ("1 side, 2 sides, 3 sides"); each corner gets a dot.
   A curved side won't trace straight: "That side is curved." A gap rings: "There's a gap."
2. **Tap** Yes or No. A wrong yes: "It has a gap, so it isn't closed." / "It has 4 sides." / "One side is curved." A
   wrong no: "Turned, it's still a square: 4 same sides, square corners." / "Long and thin, it still has 3 straight
   sides." The record: `3 straight sides, closed: a triangle`, or `a gap: not a triangle`.
3. After a yes, **place corners** to draw one that looks different: "Draw a different triangle." The paper checks only
   what makes the shape (straight sides and how many, closed; square corners for squares and rectangles; same sides for
   squares). The same size and turn as the one shown: "That's the same one. Make it bigger, smaller or turned." Wrong:
   "That has 4 sides. A triangle has 3."
Say: "Big, small or turned, 3 straight sides closed make a triangle."
Core (new generator): the shape asked about (triangles most, then rectangles, squares, hexagons), the shape shown (that
kind or a near miss), its size, turn and stretch. The first three are upright triangles (yes); then turned and thin ones
(yes); from the 7th, half are near misses (no). Check: i3 where it's a turned square; i4 where it's a thin triangle;
i7 where it's open; i8 where a side is curved.

### Put shapes together (`g1-compose`) · 1.G.2 (flat) · new
Depends on `gk-compose`, `g1-shapes`. K fills outlines with squares, rectangles and half-square triangles
(`gk-compose`); 1st grade adds trapezoids and half and quarter circles, and builds again from the shape it made. A
dashed outline of the new shape (corners on grid points, about 20 × 30 squares; circles 20 across, centred on a block
corner) and its pieces beside it.
1. **Slide** each piece into the outline: it snaps to grid points. **Turn a piece**: tap it, it turns a quarter turn.
   A piece that sticks out slides back: "That sticks out 2 squares." Readout "1 of 2 in".
2. See: the outline fills, the sides that touch fade, and the new shape's name writes itself.
3. Two-stage problems: the shape just made becomes a piece for a bigger outline: "Now use it to make a hexagon."
The record: `2 trapezoids make a hexagon.`
Say: "Shapes put together make a new shape, and it can build more."
Core (new data): a square and a triangle make a trapezoid; a triangle, a square and a triangle make a trapezoid; 2
trapezoids make a hexagon; 2 quarter circles make a half circle; 2 half circles make a circle; 4 quarter circles make a
circle; two stages: 2 triangles make a square, then it and 2 more triangles make a trapezoid; 3 pieces make a trapezoid,
then 2 trapezoids make a hexagon. The first three have 2 pieces and nothing to turn; the next three one turn; from the
7th, 3–4 pieces or two stages. Check: i0; i3; i6 with two stages; i8.

### Build with solids (`g1-build`) · 1.G.2 (solids) · new · **3D**
Depends on `g1-compose`, `k-solids`. Unit cubes as they are: one cube is one block, and every solid is built in blocks
(a box 2 × 1 × 1 blocks, a cylinder and a cone 1 block across and 1 or 2 tall). 1.G.2 is putting solids together, as
`g1-compose` puts flat shapes together, so this lesson builds a shape, never counts its cubes (counting cubes to measure
a box is 5th grade's volume).
Flat first: the new solid's footprint is a dashed outline on the paper (up to 3 × 2 blocks), and its pieces' footprints
lie beside it, each named (small).
1. The paper tilts as the pieces rise from their footprints (Unit cubes' tilt, words facing the child), and the new
   solid stands over its outline as a dashed ghost.
2. **Place it** (K's move in 3D): drag each piece onto the outline or onto a piece already placed; it moves block by
   block and snaps when it sits inside the ghost. Readout "1 of 3 in". Sticking out: it slides back, "That sticks out
   past the shape." On a cone's point: "Nothing stands on a point." A cylinder or cone on its curved side: "It rolls
   off. Put a flat face down."
3. See: the pieces' inner lines fade and the new solid's name writes itself (a box, a tower, a bigger box, a cube).
4. Two-stage problems: the solid just made slides in as one piece for a bigger ghost ("Now use it to build a bigger
   box.").
The record: `2 cubes make a box.` (`2 boxes make a bigger box.`) The paper goes flat again before the next problem.
Say: "Solids put together make a new solid, and it can build more."
Core (new data): 2 cubes make a box; 2 boxes make a bigger box; 4 cubes make a big flat box; a cylinder and a cone make
a tower; a box, a cylinder and a cone make a rocket; 8 cubes make a big cube; two stages: 2 cubes make a box, then it
and another box make a bigger box. The first three have 2 pieces; the next three 3 pieces, a cone or cylinder among
them; from the 7th, 4 pieces or two stages. Check: i0; i3; i6 with two stages; i7.

### Halves and fourths (`g1-halves`) · 1.G.3 · existing, cutting, "quarters" and "more parts are smaller" *folded*
The shape big: a rectangle 40 × 24 squares, a square 30 × 30, or a circle 30 across centred on a block corner (rows
6–36, the record under it). Every half and fourth is a whole number of squares (20 | 20, 12 | 12, 10 a strip, 15 a
fourth of the square), so equal parts can be counted. The compare kind below draws the two copies 30 squares wide (a
rectangle 30 × 20, its fourths cut as a cross so every part stays whole squares), a block apart (65 squares).
1. **Cut** with the ruler into the web's parts, along its cut: drag a cut from edge to edge; its ends snap to grid
   points on the outline (straight down or across; corner to corner for the square's diagonals; through the middle for
   the circle). The readout shows the parts' widths in squares ("20 | 20"), or "the same" for a diagonal or a circle's
   cut. Fourths take two cuts (a cross, or the square's two diagonals) or three (four strips). Not equal: "Not equal: 15
   squares and 25 squares." (`parts`)
2. **Tap** the parts' name: halves or fourths; the readout adds "fourths are also called quarters" (`name`; the web's
   slips).
3. **Tap** parts to shade them: "Shade 3 fourths." (`shaded`; shading all of them: "Shade only 3.")
4. The record: `3 fourths shaded`, and under it `4 fourths make the whole`.
*Folded*: from the 7th problem, every third shows the shape twice, one cut in halves and one in fourths: **tap** the
bigger piece. Wrong: "A fourth is half of a half. More parts are smaller."
Say: "4 equal parts are fourths; 4 fourths make the whole."
Core: the web's generator (shape, 2 or 4 parts, halves on the second problem, the cut, 1 to parts − 1 shaded), and the
compare-the-pieces kind added.

## Open questions for G

1. **A voice for 1st graders.** Many 6-year-olds can't read "How many more does Maya have?" yet. Should Obento² read
   the instruction and the stories aloud (`g1-story`, `g1-more`, the story items in `g1-three`), or keep words only and
   make stories picture-first with very short lines?
2. **Typing for small hands.** The record's boxes use the iPad's own keyboard for now. For 1st grade, should the drawn
   keypad (0–9 cells on the paper, already in the code but off) come back? (`gradeK.md` asks the same for K, as a row
   of numbers to tap; one answer could serve both.)
3. **3D in 1st grade.** `g1-build` is a small Unit cubes lesson (put cubes and solids together). Keep it as its own 3D
   lesson, or fold putting solids together into `g1-compose` as flat pictures and save the RealityKit work?
