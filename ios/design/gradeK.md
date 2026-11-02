# Kindergarten on paper: every lesson's design

Claude (K planner), 1 Nov 2026, in the language of `README.md` and the shape of `grade5.md`. Planning only: nothing
here is built. Each lesson: the standard it covers, what one square (or block) is, the picture, each step's hand move
with its live readout, what a wrong move says, what the picture then shows, the record, the last line, and what Core
needs. The maths of the 14 web lessons (`web/src/curriculum/lessons/gradeK/`) stays as it is: generators with their
ranges and easy-first order, derived values, mistake messages, the check recipes in `specs/k12/gradeK-1.md`, stories.
Their steps are designed fresh for paper. Their ids are kept, so 1st grade's depends-on lists still point at them.
Reviewed 1 Nov 2026 (K reviewer): coverage checked standard by standard; sizes, skill checks, slips and words fixed in
place. A skill check item `i3 where …` only works if index 3 can make that problem (the spec redraws up to 50 times),
so items for kinds that start at index 6 read `i6`.

**Standards covered:** all 22 Common Core Kindergarten standards and their parts: K.CC.1–7 (with 4a, 4b, 4c), K.OA.1–5,
K.NBT.1, K.MD.1–3, K.G.1–6. **23 lessons in 5 chapters:** the 14 web lessons and 9 new ones (`gk-…`). **3D:** Solid
shapes and Where is it?.

## Coverage

| Standard | In short | Lessons (web = exists on the web; **new** = added here) |
|---|---|---|
| K.CC.A.1 | Count to 100 by ones and by tens | `k-tens` web (by tens) · `gk-count100` **new** (by ones) |
| K.CC.A.2 | Count on from a given number | `k-count20` web (on from 10) · `gk-onemore` **new** · `gk-count100` **new** |
| K.CC.A.3 | Write 0–20; a numeral for a count, 0 for none | `k-write` web (+ tracing, folded in) · every K record |
| K.CC.B.4a | One number for each thing, in order | `gk-count10` **new** (Tap to count, then every lesson) |
| K.CC.B.4b | The last number says how many, however they sit | `gk-count10` **new** |
| K.CC.B.4c | Each next number is one more | `gk-onemore` **new** |
| K.CC.B.5 | How many? up to 20 in a line, array or ring, 10 scattered; count out 1–20 | `gk-count10` **new** (line, array, ring, scattered to 10; count out to 10) · `k-count20` web (2 rows of 10 is the array; + a ring of 20, folded in) · `k-teens` web (+ make a teen, folded in) |
| K.CC.C.6 | Compare two groups by matching and counting | `k-compare` web |
| K.CC.C.7 | Compare two numerals from 1 to 10 | `gk-numcompare` **new** |
| K.OA.A.1 | Show + and − with things, fingers, drawings, acting out, equations | `k-add`, `k-sub`, `k-story` web · `gk-five` **new** (fingers) |
| K.OA.A.2 | Story problems; add and take away within 10 | `k-story` web (+ put together, folded in) · `k-add`, `k-sub` web |
| K.OA.A.3 | Break numbers to 10 into pairs, more than one way | `k-bonds` web (+ another way, folded in) |
| K.OA.A.4 | The number that makes 10 | `k-make10` web |
| K.OA.A.5 | Add and take away within 5, fluently | `gk-five` **new** · the first problems of `k-add` and `k-sub` |
| K.NBT.A.1 | 11–19 as ten ones and some more ones | `k-teens` web (+ make a teen, folded in) |
| K.MD.A.1 | Things have a length and a weight; one thing, several | `gk-heavier` **new** · `k-length` web |
| K.MD.A.2 | Compare two things directly; say the difference | `k-length` web (+ taller, folded in) · `gk-heavier` **new** |
| K.MD.B.3 | Sort, count each kind, order the kinds by count | `k-sort` web (+ the rows put in order, folded in) |
| K.G.A.1 | Shape names for real things; above, below, beside, in front of, behind, next to | `k-solids` web (real things) · `gk-position` **new** |
| K.G.A.2 | Name shapes at any turn or size | `k-shapes` web |
| K.G.A.3 | Flat or solid | `k-solids` web (+ flat or solid, folded in) |
| K.G.B.4 | Compare shapes: sides, corners, equal sides, faces | `k-shapes` web (+ equal sides shown) · `k-solids` web · `gk-draw` **new** |
| K.G.B.5 | Build and draw shapes | `gk-draw` **new** |
| K.G.B.6 | Put shapes together into bigger ones | `gk-compose` **new** |

**Folded into web lessons** (an extra problem type or step, the rest of the lesson's maths unchanged): `k-count20` a ring
of up to 20; `k-write` tracing the numeral; `k-teens` making a teen (and now and then 20); `k-story` put together;
`k-bonds` another way; `k-length` taller; `k-shapes` same-length sides; `k-solids` flat or solid; `k-sort` the rows put
in order by count.

## Grade boundaries

- **Numbers.** K counts to 100 (1st grade: 120), adds and takes away within 10 (1st: 20), compares 1–10 in words
  ("6 is more than 4"; the signs >, = and < are 1st grade's). K writes numbers 0 to 20; past 20 numbers are found and
  read on the paper, never written (the one exception is `k-tens`' total, from the web).
- **Teens.** "10 and 6 more is 16": ten ones and some more. The ten as a unit, and tens and ones as places, are 1st
  grade's (`g1-tensones`). The web's `k-write` slip "1 ten and 6 ones" is kept as the web wrote it.
- **Adding.** K counts on from the first number with cubes. Making a ten to add, three numbers and missing addends past
  10 are 1st grade's (`g1-ten`, `g1-three`, `g1-missing`).
- **Length.** K lines two things up and says which is longer, and how many cubes stick out. Measuring a whole length
  in units, ordering three, and comparing through a third thing are 1st grade's (`g1-measure`).
- **Shapes.** K names, draws and joins simple shapes. Defining attributes, composite shapes with trapezoids and half
  circles, halves and fourths are 1st grade's (`g1-halves`).
- **Data.** K sorts and counts each kind. Picture graphs, tally charts and "how many more" are 1st grade's.
- Not in K: time, money, one less and ten less.

## What every K lesson shares

- **One block is one thing.** A counter, a cube, a finger, a cell of a ten frame, a number on the hundred chart: one
  block (5 × 5 squares, between the strong lines), so every count is a count of blocks and every picture sits on the
  strong lines ("one cube = one big square", as in Unit cubes). Counters are dots 3 squares across in the middle of
  their block; cubes fill theirs. Flat shapes are the exception: `k-shapes` puts corners on the squares' crossings
  (so turned shapes stay on the grid), and `gk-draw` and `gk-compose` on the blocks' crossings (so a side is a count of blocks, never more than 10). K
  compares sides by laying one against another (the stick), never by numbers past 10.
- **Fits the screen.** Every picture fits about 68 × 45 squares at 100% while the hands work. Two See beats are bigger
  and the camera steps back for them: One more's full stair (50 × 50 squares from row 6 with its names and record,
  about 60 × 55: about 75%) and Count to 100's whole chart (50 × 50 from row 6: about 80%), both just to be looked at,
  a block still 75–80 pt.
- **The ten track** is K's number line: a row of ten outlined blocks (50 × 5 squares). Trains of cubes sit on it from
  its start line; a second amount is striped, as 5th grade stripes it. Two tracks touching make the twenty track.
  Ten frames are 5 × 2 blocks (25 × 10 squares) unless a lesson says otherwise.
- **Counting writes its numbers.** Each thing counted gets its number on it (28); the last number is ringed and becomes
  the group's name at its right end. The child counts; the paper keeps track of what's counted.
- **Words.** The instruction is 2–5 words, a verb first ("Tap each dot.", "Make 7.", "Slide them on.", "Tap the row
  with more."), never a question; the one exception is the story's own last sentence. A miss is one
  short line, measured on the paper ("That's 8. Make 7."). The last line says why. Numbers are always numerals. Most
  kindergartners can't read yet, so the How to and Show me's ghost finger show every move (see Open questions on a
  voice).
- **The record** is a numeral, an equation with one box (`3 + 4 = [7]`, `5 = 2 + [3]`, `7 + [3] = 10`), or a short
  sentence filled by a tap (`6 is more than 4`, `It's a triangle.`). Steps answered by a hand move set their Core box
  from the move (`LessonRun.set`), as in 5th grade, so the web's checks and slip messages stay; where the hands make a
  web step pointless, its box is set from the picture and its slips move to the box that's left.
- **Layout** as in `README.md`: instruction on rows 0–2, a miss on rows 3–4, the picture from row 6, the record 3 rows
  under it. **3D** only where the maths stands off the paper: solids, and in front of and behind.

## New hand moves (not yet in the kit table in `README.md`)

| Move | What it does | Used by |
|---|---|---|
| Tap to count | Each tap on a thing (a dot, cube, side, corner, ten frame, chart block) writes the next number on it; the readout is the count. A counted one tapped again flashes: "You counted that one." The last number is ringed and names the group. It also counts on from a number, and by tens. | gk-count10, k-compare, k-shapes, k-sort, k-add, k-sub, k-make10, k-count20, k-write, k-teens, k-tens, gk-count100 |
| Trace | The ink follows the finger only along a digit's stroke, from its numbered start dot; off the stroke it stops drawing. | k-write |
| Place corners | A tap near a block crossing (the strong lines) puts a corner there; a side draws from the last corner; tapping the first closes the shape; a corner can be dragged. 5th grade's new graphing lesson snaps to the same block crossings ("place a point", `LESSONS.md`). | gk-draw |
| Turn a piece | Tap a flat piece: it turns a quarter, staying on the squares. | gk-compose |
| Tilt (3D) | The child drags the paper up into 3D: `LESSONS.md`'s Turn, here the step itself. | k-solids |
| Push (3D) | Flick a solid: it rolls or slides, comes to rest, and is set back. | k-solids |
| Place it (3D) | Drag a solid across the tilted floor, block by block, onto another or under the table; the readout says where it is. | gk-position |
| Number row | Only if G chooses it (Open questions): the record's box is filled by tapping a number on a row drawn under the record (0–10, 11–20, or tens). | every K record |

Reused from the kit: **Slide pieces** (k-compare, k-length, gk-heavier, k-add, k-story, gk-compose), **Tap pieces**
(k-sub, k-make10, gk-five, k-teens), **a rectangle's edge** (a train's end: gk-count10, gk-onemore, gk-numcompare),
**Multiply two-digit numbers' cut** (k-bonds), **Tap the part** (choosing a row, a thing or a word), **Write**.

## Chapters

| Chapter | Lessons, in teaching order |
|---|---|
| 1 · Count to 10 | Count to 10 `gk-count10` **new** · One more `gk-onemore` **new** · More, less or the same `k-compare` · Which number is more? `gk-numcompare` **new** |
| 2 · Shapes | Flat shapes `k-shapes` · Draw shapes `gk-draw` **new** · Solid shapes `k-solids` (3D) · Where is it? `gk-position` **new** (3D) · Put shapes together `gk-compose` **new** |
| 3 · Measure and sort | Longer and shorter `k-length` · Heavier and lighter `gk-heavier` **new** · Sort and count `k-sort` |
| 4 · Add and take away | Adding within 10 `k-add` · Taking away within 10 `k-sub` · Story problems within 10 `k-story` · Number bonds `k-bonds` · Make 10 `k-make10` · Facts to 5 `gk-five` **new** |
| 5 · Teens and tens | Count to 20 `k-count20` · Write numbers 0 to 20 `k-write` · Teen numbers `k-teens` · Count by tens to 100 `k-tens` · Count to 100 `gk-count100` **new** |

Counting to 10 comes first because everything leans on it. Shapes come next, as in most kindergartens, and need no
adding. Measuring and sorting lean on comparing. Then adding and taking away within 10, and last the teens and counting
to 100, built on ten. **Depends on**, changed from the spec for four web lessons because new lessons now come before
them: `k-compare` gk-count10 (was k-count20); `k-add` gk-onemore, gk-count10 (was k-count20); `k-sub` k-add, gk-count10
(was k-add, k-count20); `k-count20` gk-count10 (was none). The rest are as in `specs/k12/gradeK-1.md`; new lessons' lists
are in their Core lines.

## 1 · Count to 10

### Count to 10 (`gk-count10`) · new
K.CC.B.4a, K.CC.B.4b, K.CC.B.5. **One block is one thing** (a dot 3 squares across). Two kinds of problem, by turns
after the first three.

*How many?* Up to 10 dots on a field of 10 × 4 blocks (50 × 20 squares) from row 6: in a line, in an array (rows of
equal length touching: 2 × 2 up to 2 × 5, or 3 × 3), round a ring (on the blocks round the edge of a rectangle of
blocks; 4 × 3 has 10 places, the dots spread evenly round it when there are fewer), or scattered (no two in blocks that
share a side). Under the field, an empty ten track. "Tap each dot."
1. **Tap to count**: each dot tapped gets the next number on it; the readout is the count. A counted dot tapped again
   flashes: "You counted that one." When every dot has its number, the last is ringed (nothing else is written: the
   ringed number is the answer to find).
2. See: the dots glide down onto the ten track in the order they were counted, numbers and all; the last is still 7.
   Any order, any arrangement: the same count.
3. **Write** `[7]`. 6: "One short. The last number was 7." 8: "One too many. The last number was 7."

*Make 7.* Only the ten track. "Make 7."
1. **Drag** along the track (a rectangle's edge; a tap on a block fills up to it): cubes fill from the start line, each
   with its number; the readout is the count. Let go on 8: "That's 8. Make 7." The 8th cube flashes; drag back.
2. The record writes itself: `7`.

Say: "The last number you say is how many."
Core (new `CountToTen`): n 1–10; kind count or make; lay line, array, ring or scattered, with a seed for the places
(an array only for n = 4, 6, 8, 9 or 10). Easy first: index 0–2 count, n 1–5, a line; 3–5 n 1–10, count and make by
turns, a line, an array or scattered; 6+ any kind and lay, n 4–10. Slips (the write box): n − 1 "Skipped a dot", n + 1 "Counted a dot twice" (k-count20's words). Check: i3 where
scattered and n ≥ 7; i6 where a ring (rings come only from index 6); i3 where make; i3. Depends on: none. How to: 7
scattered dots.

### One more (`gk-onemore`) · new
K.CC.B.4c, K.CC.A.2. **One block is one cube.** The number stairs: trains of 1, 2, … n cubes, one under the other,
rows touching, left ends on one start line, so the right ends make a stair; each train's number at its right end;
under the last one an empty row of 10 dashed blocks. While the hands work, only the stair's last 5 trains are drawn
(when n is 6 or more, the top one has a dashed top edge: the stair goes on up), so the picture is at most 6 rows of
blocks (50 × 30 squares from row 6, the record under it by row 41) and fills the screen at 100%. "Make one more."
1. **Drag** the new train out from the start line (a rectangle's edge: it grows a cube at a time; the readout counts).
   Let go one cube past the train above: that cube lights, "1 more". The same length: "That's 6 again. One more." Two
   past: "That's 8: 2 more." Shorter: "That's less than 6."
2. **Write** `1 more than 6 is [7]`.
3. See: the trains above draw back in and the camera steps back to the whole stair (up to 10 trains, 50 × 50 squares
   from row 6, about 75%: looked at, not worked on); the last cube of each train lights in turn, 1 to 7.

Say: "Each next number is one more cube."
Core (new `OneMore`): n 1–9. Easy first: index 0–2 n 1–4; then 1–9. Slips (the write box): n "Wrote the same number",
n + 2 "Two more", n − 1 "One less". Check: i3 where n ≤ 4; i3 where n ≥ 7; i3 where n = 9; i3. Depends on: gk-count10.
How to: 6, then one more.

### More, less or the same (`k-compare`) · web
K.CC.C.6. **One block is one dot.** Two ten tracks a block apart (rows 6–10 and 16–20). The top row sits on its track
from the start line. The bottom row starts out of line: spread out (a block between dots) when it's the smaller row and
has 5 or fewer, so it looks longer than it is; otherwise shifted 1–3 blocks right, never ending past 12 blocks (60
squares), so its count still fits at its end. "Count each row."
1. **Tap to count** the top row, then the bottom row; each row's count goes at its right end (its name: 6, 4). The
   web's two count boxes are set from these.
2. "Line them up." **Slide** the bottom row under the top one's start (Slide pieces): it snaps, one dot per block, dot
   under dot; partner lines draw between the pairs, and the dots with no partner are ringed: "2 without a partner" (the
   web's picture). Dropped anywhere else, it slides back: "Start it under the top row."
3. "Tap the row with more." **Tap** that row, or the "same" block at the rows' right end. The other row: "Every bottom dot has
   a partner. 2 top dots don't." Same when they're not: "2 dots have no partner." Not same when they are: "Look again:
   every dot has a partner." (The web's messages, measured.)
4. Record, written by the tap: `6 is more than 4` (or `less than`, `the same as`).

Say: "The row with dots left over has more."
Core: the web's k-compare as it is (top and bottom 1–10; the first three 5 at most and 2 apart; after that 1 in 5 the
same). New: where the bottom row starts (spread or shifted; it never changes the answer). Check: the spec's (top >
bottom; top < bottom; the same; 1 apart). Depends on: gk-count10. How to: 6 and 4.

### Which number is more? (`gk-numcompare`) · new
K.CC.C.7. **One block is one cube.** Two numerals, big (36), each at the left of an empty ten track, the tracks a block
apart (rows 6–10 and 16–20). The problem is the two numbers; they sit at the start, not the end, because they're what
to build. "Make each number."
1. **Drag** out a train on each track (a rectangle's edge; the readout counts). Let go on another number: "That's 7.
   Make 6." Drag again.
2. See: a dashed line drops from the shorter train's end; the longer train's extra cubes are ringed: "2 more".
3. "Tap the one that's more." (or "…that's less.") **Tap** that number. Wrong: "6 stops 2 cubes before 8."
4. Record, written by the tap: `8 is more than 6`.
As the help fades down the page, the child taps first and the trains build themselves to show it (they come back
after a miss): comparing from the numbers alone is the standard.

Say: "8 comes after 6 when you count, so 8 is more."
Core (new `CompareNumbers`): a, b 1–10, never the same; ask more or less. Easy first: index 0–2 both 5 at most, 2 or
more apart, ask more; then 1–10, 1 or more apart, ask less 1 in 3. Slip: picked the other number. Check: i3 where 1
apart; i3 where ask less; i3 where one is 10; i3. Depends on: k-compare, gk-onemore. How to: 6 and 8.

## 2 · Shapes

### Flat shapes (`k-shapes`) · web
K.G.A.2, K.G.B.4. **What's counted is sides and corners**, one tap each; every corner sits on a grid crossing, so
the sides are straight lines of the grid's own squares. The shape, big: the web's size at 3 squares a web unit (18–33
squares across, 12–27 tall), centred from row 6, the four name blocks under it. A turned shape takes the nearest
turn that keeps its corners on crossings (a side going 4 across and 1 up is 14°, 5 and 3 is 31°, 1 and 1 is 45°); the
hexagon is 16 × 14 squares with its corners on crossings (sides 8 and a little over 8, so it looks even), and the
web's turned hexagon (15° or 30°) is drawn standing on a corner, 14 × 16 (the same hexagon turned 30°, its corners on
crossings). "Tap each side."
1. **Tap to count** each straight side: it lights and its number is written just outside it. Tapped again: "You counted
   that side." The circle: a tap lights its whole edge: "It's round. No straight sides." (0)
2. "Tap each corner." **Tap to count** each corner: a dot and its number. The circle: "No corners. It's round all the
   way." (0)
3. "Tap its name." Four words under it (the web's choices). Wrong, the web's: "A hexagon has 6 sides. This shape has 3
   sides."
4. See: a turned shape turns upright where it is: the same shape. A square or rectangle: one side lifts off as a stick
   and lays itself on each side in turn; it fits all four of a square, and only the two long sides of a rectangle
   (the short sides light where the stick hangs past them). No lengths are written: equal sides are seen, not
   measured, in K.
5. Record: `3 sides · 3 corners` and `It's a triangle.` (a square adds `4 sides the same`).

Say: "3 straight sides and 3 corners make a triangle, turned or not."
Core: the web's k-shapes as it is (circle, triangle, square, rectangle, hexagon; w 6–11, h 4–9; the first three a
circle, triangle or square, upright; a rectangle at least half again as wide as tall). New: the grid shape made from
(shape, w, h, turn), corners on crossings, the turn moved to the nearest grid turn. The two count boxes are set from the
taps. Check: the spec's (a turned triangle; a turned square; a rectangle; a hexagon). Depends on: none. How to: a
triangle.

### Draw shapes (`gk-draw`) · new
K.G.B.5 (and K.G.B.4). **One block is one step of a side**: corners sit on the crossings of the strong lines, so a
straight side is 1–10 blocks long and can be counted. The drawing place is 10 × 6 blocks (50 × 30 squares) of the
paper's own grid from row 6, with a faint frame round it and its block crossings dotted faintly. "Draw a triangle."
1. **Place corners**: each tap puts a corner on the nearest block crossing (a dot: the clay ball); from the second on,
   a side (the stick) draws from the last corner to it; tapping the first corner closes the shape. A corner can be
   dragged to move it. Readout: "2 sides · 3 corners". Refused, with the paper's reason: a side that would cross
   another ("Sides can't cross."), three corners in a line ("Those are in a line.").
2. Closed, it's checked. The wrong count: "That has 4 sides. A triangle has 3." A square needs four sides the same
   length and square corners, like the grid's: each straight side's blocks are numbered along it, and a miss says
   "Sides 3, 3, 2, 2. Make them all the same." (a tilted side has no count: the shortest side lifts off as a stick and
   lays on the others, the part that hangs past lit: "These 2 are longer."). A rectangle needs square corners, two long
   sides and two short: a square drawn says "That's a square. Make 2 sides longer." The drawing stays to fix. A circle
   (from index 6): **drag** out from a centre dot and the circle draws all the way round as the finger moves out, its
   size snapping to whole blocks (1–3 out): "Round. No corners."
3. See: as in k-shapes, the sides numbered and the corners dotted; for a square, the stick fits every side.
4. Record: `3 sides · 3 corners` (from the drawing).

Say: "3 straight sides joined at 3 corners make a triangle."
Core (new `DrawShape`): kind triangle, square, rectangle, hexagon or circle. Easy first: index 0–2 a triangle or a
rectangle; 3–5 squares too; 6+ any, with hexagons and circles. Checks (on whole block steps, so exact): closed, no
sides crossing, no three corners in a line, the side count; a square's sides equal and corners square (a tilted square
counts, e.g. steps 2 across 1 up); a rectangle's corners square and its sides not all equal. Check: i3 triangle; i3 square; i3 rectangle; i6 hexagon. Depends on: k-shapes. How to: a triangle.

### Solid shapes (`k-solids`) · web · 3D
K.G.A.3, K.G.B.4, K.G.A.1. **One block is one floor square, as in Unit cubes.** Flat first: two shapes side by side, 2
blocks apart, from row 8 (50 squares across together): the solid seen straight down (the cube 4 blocks a side; the
sphere, cylinder and cone 4 blocks across, the cylinder and cone 5 tall) and a flat shape drawn on the paper with the
same outline (a square for the
cube; a circle for the sphere and an upright cylinder or cone; a rectangle or a triangle for a cylinder or cone on its
side). From above they look the same. "Tilt the paper."
1. **Tilt**: the solid rises off the paper; the flat shape stays on it. "Tap the solid one." Wrong: "That one is flat.
   It lies on the paper."
2. "Tap a flat face." **Tap** the solid: a flat face lights; a round side says "That's round. Find a flat part." A
   "None" block sits beside the solid: it is the sphere's answer (the web's no); tapped for a solid with a flat face,
   that face lights: "This part is flat." See: the solid turns once where it stands and every flat face lights, with the
   web's words for where they are ("one circle at each end").
3. "Tap rolls or slides." **Tap** "rolls" or "slides" (the web's yes or no), then **push** it: a sphere rolls; a cylinder lies
   down and rolls; a cone rolls round its tip; a cube slides and stops. It comes to rest a few blocks on and is set
   back. A wrong guess: the push shows it, with the web's line ("A cube has flat faces and corners. It slides, but it
   can't roll.").
4. "Tap its name." Four words (the web's: its name, its flat look-alike, two other solids). Wrong, the web's: "A
   rectangle is flat, like a drawing. This shape is solid: a cylinder." / "A cone comes to a point. A cylinder has two
   flat ends."
5. Record: `It has a flat face. It rolls. It's a cylinder.` The paper lies flat before the next problem.
Real things (every third problem, the web's `thing`: block, die, box; ball, orange, marble; can, drum, candle; party
hat, ice-cream cone, traffic cone) are the solid with a few of the thing's lines on it (a can's rim, a die's dots): a
shape's name for a thing in the world.

Say: the web's, "It has two flat circle ends: a cylinder."
Core: the web's k-solids as it is (cube, sphere, cylinder, cone; plain or a thing; upright, the other side, or on its
side; the first three plain and upright; every third a thing). New: step 1, which is solid (its box is the side the
solid is on; slip "Picked the flat one"), and the roll guess before the push. The steps follow the picture's order:
solid, flat face, roll, name (the spec's swap). Check: the spec's. Depends on: k-shapes. How to: a cylinder.

### Where is it? (`gk-position`) · new · 3D
K.G.A.1. **One block is one floor square, as in Unit cubes**; each solid stands on 2 × 2 blocks (k-solids' shapes, 2
blocks across). A floor of 10 × 6 blocks (50 × 30 squares), outlined from row 6, holds 2–4 solids (cube, sphere, cone,
cylinder) that never touch; from index 6 a table too (a slab 4 × 2 blocks on legs 2 blocks high, so a solid fits
under it). Flat first with the words written; then the paper tilts by itself: in front of and behind are depth, so this
lesson is 3D. Two kinds:

*Put it.* "Put the cone behind the cube."
1. **Place it**: drag the cone across the floor; it moves block by block, up onto a flat top (a cube's, an upright
   cylinder's or the table's; a sphere's or cone's top won't hold it: it slides off back to the floor), or under the
   table.
   The readout says where it is from the cube now, in the instruction's own words: "beside the cube" (or "next to the
   cube" when that's the word asked), "in front of the cube", "above the cube", "behind the cube" (nothing when it's not
   next to it). In front of is the 2 × 2 blocks just nearer the floor's near edge (the paper's bottom), behind the 2 × 2
   just farther; beside is the 2 × 2 to the left or right; above is on its flat top; below is under the table. Let go
   where the words asked: right. Elsewhere: "That's beside the cube. Behind is the far side." It slides back.

*Find it.* "Tap the one behind the cube."
1. **Tap** a solid. Wrong: "The sphere is in front of the cube."

The words: above (on top of), below (under the table), beside and next to (the same place: a block to either side), in
front of (nearer you), behind (farther from you). Record, written by the move: `The cone is behind the cube.` The paper
lies flat before the next problem.

Say: "Behind is the far side: the cube is between you and the cone."
Core (new `WhereIsIt`): the things and their blocks (seeded), the kind, the thing to move or find, the one it goes by,
the word. Easy first: index 0–2 put, beside, next to, above; 3–5 in front of and behind; 6+ below (the table), and find.
Check: i3 where in front of or behind; i6 where below; i6 where find (both start at index 6); i3. Depends on: k-solids. How to: the cone behind
the cube.

### Put shapes together (`gk-compose`) · new
K.G.B.6. **Every piece is whole blocks**, and pieces snap block by block (a square at a time would be too fiddly for a
five-year-old's finger, and a block snap lands a piece exactly in its place). A small square piece is 2 × 2 blocks (10
× 10 squares). On the left from row 8, the big shape's outline, dashed, its size set by its pieces: 2 squares → 20 ×
10; 3 squares → 30 × 10; 4 squares → 20 × 20; 2 rectangles (20 × 10) → 20 × 20; 2 triangles (halves of a 20 × 20
square) → 20 × 20; 2 triangles (halves of a 30 × 15 rectangle) → 30 × 15; 2 triangles (halves of a 10 × 20 rectangle,
one the mirror of the other) → a big triangle 20 wide and 20 tall. On the right, 5 squares past it, the pieces, some
turned; the whole picture is at most 65 × 30 squares. "Fill the shape."
1. **Slide** each piece into the outline (Slide pieces: it snaps to the blocks) and **turn a piece** (tap it: a quarter
   turn) so it fits. One that hangs out or covers another slides back: "That one sticks out." / "Pieces can't stack."
   Readout: "1 of 2 in".
2. See: when the outline is full, the sides that touch go dashed and fade, and the outline turns solid: one shape.
3. "Tap its name." The k-shapes words.
4. Record: `2 triangles make a square.`

Say: "Full sides touching, no gaps: they make one bigger shape."
Core (new `PutShapesTogether`): one of seven sets (2 squares → rectangle; 3 squares → rectangle; 4 squares → square; 2
rectangles → square; 2 triangles → square; 2 triangles → rectangle; 2 triangles → big triangle), its size in blocks
(above), each piece's
starting turn (quarter turns only). Pieces only turn, never flip: two halves of a rectangle cut corner to corner are
the same piece turned half way round (two taps); the big triangle's two halves are mirror images, so they are
drawn as a left piece and a right piece. Easy first: index 0–2 squares and rectangles, nothing to turn; 3–5 triangles, one to turn; 6+ any set.
Check: i3 where a piece must turn; i3 where 2 triangles make a triangle; i6 with 3 or 4 pieces (index 3–5 has only
the triangle sets); i3. Depends on: gk-draw.
How to: 2 triangles make a square.

## 3 · Measure and sort

### Longer and shorter (`k-length`) · web
K.MD.A.2, K.MD.A.1. **One block is one cube of length.** Two things on two block rows (rows 8–12 and 16–20), each
drawn in thin lines as long as it is (the web's 2–10 cubes: 10–50 squares) and 3 squares thick, its cubes faint across
it, its name small just above its left end; a start line runs down through both rows 2 blocks in from the picture's
left edge. The top thing touches the line; the bottom one starts 1–3 blocks right of it (never ending more than 11
blocks past the line), or hangs 1–2 blocks past it to the left. So the picture is at most 13 blocks (65 squares)
wide. "Line them up."
1. **Slide** the bottom thing until its end is on the start line (Slide pieces: it snaps block by block; the line darkens
   when the end is on it). Let go off the line and it waits there: "Its end goes on the line."
2. "Tap the longer one." **Tap** it, or "same" when they end together. Wrong, the web's: "The ribbon is only 4 cubes. The
   pencil is 7." / "They are not the same." / "Look again: they end at the same place."
3. See: a dashed line drops from the shorter one's end; the part that sticks out is ringed and its cubes count 1, 2, 3;
   each thing's length is written at its end (7, 4).
4. **Write** `The pencil is longer by [3] cubes.` (the web's line). 7: "7 is the whole pencil. Count only the cubes
   past the dashed line." 4: "4 is the whole ribbon. Count only the cubes past the dashed line." One off: "One short.
   Count every cube past the dashed line." / "One too many. Count each cube past the line once." The same length writes `The pencil and
   the ribbon are the same length.`, with nothing to fill in.
Taller (folded in, the standard's own example): from index 6, every third problem (6, 9, 12 …) the two things stand on a floor line
(a tower, a plant, a bottle, a lamp, a candle, a cup; 2–7 cubes, so they fit): "Tap the taller one." Slide one down onto
the floor, tap the taller, and write `The tower is taller by [2] cubes.`

Say: "Same start, so the one that sticks out is longer."
Core: the web's k-length as it is (pencil, crayon, ribbon, spoon, snake, straw; a, b 2–10; the first three 8 at most and
3 or more apart; after that 1 in 6 the same). Its two measure boxes are set from the picture (whole lengths in units are
1st grade's); their count slips move to the last box. New: `tall` (from index 6, every third: heights 2–7, things that
stand) and `shift` (where the bottom thing starts: 1–3 blocks right but b + shift ≤ 11, or 1–2 blocks left). The
`[3]` box is new (the web writes the line with no box): K.MD.A.2's "say the difference", a count of 8 at most (2–10
cubes). Its slips, first one wins: the longer one's length, the shorter one's length, one short, one too many. Check:
the spec's (i3 where a > b; i3 where a < b; i3 where a = b), and its 1-apart item as i6 where tall and 1 apart (the
taller kind starts at index 6).
Depends on: k-compare. How to: pencil 7, ribbon 4.

### Heavier and lighter (`gk-heavier`) · new
K.MD.A.1, K.MD.A.2. **Weight has no unit in K** (it's compared directly); **one block is one cube of length** for the
things, 1–4 blocks long, so the longest still lies flat in a pan. A pan balance in blocks, from row 6: a post 3
blocks tall, a beam 9 blocks long (45 squares) on it, a pan 4 blocks wide hanging from each end (13 blocks, 65
squares, across in all). Under it, two things in thin lines (a rock, a feather, a brick, a pillow, a ball, a book, an
apple, a balloon, a shoe, a leaf), each as long as it is in blocks. "Put them on."
1. **Slide** each thing onto a pan (Slide pieces; it snaps into the pan). With both on, the beam tips on a spring: the
   heavier side goes down (a block at the ends, so the tip is plain to see); the same weight stays level.
2. "Tap the heavier one." (or "lighter") **Tap** it, or "same" when it's level. Wrong: "That side went up. It's
   lighter." / "That side went down. It's heavier."
3. Both ways (from index 3, every other problem): the balance draws out and the two things lie on k-length's start
   line. "Tap the longer one." **Tap** it. A pillow is longer and lighter than a rock.
4. Record, written by the taps: `The rock is heavier.` and `The pillow is longer.`

Say: "The heavier side goes down." With both ways: "Longer isn't always heavier."
Core (new `HeavierLighter`): two things from a table of length (1–4 blocks) and weight (a rank 1–9, never shown); ask
heavier or lighter; both ways or not. Easy first: index 0–2 ranks 5 or more apart, ask heavier; 3–5 a longer but
lighter pair 1 in 2, both ways every other; 6+ two of the same thing now and then (level), ask lighter 1 in 3. Check: i6
where ask lighter (asked only from index 6); i3 where the longer one is lighter; i3 where both ways; i3. Depends on: k-length. How to: a rock and a
pillow.

### Sort and count (`k-sort`) · web
K.MD.B.3. **One block is one thing.** The mixed-up pile on a field of 7 × 3 blocks (35 × 15 squares) from row 6; a
block under it, one empty row per kind, each row's first block holding its kind's key (button, leaf, block; or circle,
square, triangle: one colour, so only the shape tells them apart, as on the web). The web's circled one is ringed in the
pile. "Tap each button." (the circled one's kind first, its key lit)
1. **Tap** each one of that kind: it flies into its row and takes the next number; the readout counts the row. One of
   another kind shakes: "That's a leaf. It has a pointed tip." (the web's words for each kind).
2. The same for each other kind ("Tap each leaf."). The rows start on one line, so their lengths compare as in
   k-length. When the pile is empty its field draws out and the camera frames the rows and the record (3 rows of up to
   9 blocks: 45 × 15 squares), so the picture never runs past the screen's 45 rows.
3. "Tap the row with the most." (every fourth problem, "the fewest") **Tap** that row. Wrong, the web's: "That group has the
   fewest. Which group has the most?" / "That group is in the middle. The most is the longest row."
4. See (the standard's "sort the kinds by count"): the rows slide into order, most at the top, fewest at the bottom,
   their counts going with them, so the right ends make a stair down.
5. Record: each row's count at its right end, and `The buttons have the most.`

Say: "Rows from one line: the longest row has the most."
Core: the web's k-sort as it is (the first three 2 kinds, 1–6 each, 8 in all at most; after that 3 kinds, 1–8 each, 15
in all at most; the counts all different; things or shapes; the fewest every fourth). Its sort box is set when the circled one is tapped into its row, its count boxes from the
rows. Check: the spec's. Depends on: k-compare, k-shapes. How to: 5 buttons and 3 leaves.

## 4 · Add and take away

### Adding within 10 (`k-add`) · web
K.OA.A.1, K.OA.A.2, K.OA.A.5. **One block is one cube.** The ten track from row 12; on it, from the start line, a
train of a cubes in the chapter colour, named `3` at its right end; above it on the right, a train of b cubes, striped
(the second amount), named `4`. The problem is the two names. "Slide them on."
1. **Slide** the striped train onto the track (Slide pieces): it snaps on right after the 3rd cube. Dropped with a gap,
   or on the 3: it slides back: "Put them right after the 3."
2. "Count on." The 3 stays on the first train's last cube. **Tap to count** each striped cube: 4, 5, 6, 7, with a hop
   arcing over each from the one before (the web's hops); the last is ringed.
3. **Write** `3 + 4 = [7]`. Wrong, the web's: 8: "One too many. Start after 3: say 4 for the first new cube." 6: "One
   short. Count every new cube once."

Say: "Start at 3 and count on, one number for each new cube."
Core: the web's k-add as it is (a 1–5, b 1–5, a + b 10 at most; the first three a 1–3 and b 1–2, so 5 at most). Its
first box (count the first group) is set from the picture. Check: the spec's. Depends on: gk-onemore, gk-count10
(counting on starts with one more). How to: 3 + 4.

### Taking away within 10 (`k-sub`) · web
K.OA.A.1, K.OA.A.2, K.OA.A.5. **One block is one cube.** The ten track from row 8 with a train of a cubes, named `7`;
2 blocks under it, an empty strip for the cubes taken. "Take 3 away."
1. **Take away** (Tap pieces): each tap takes the train's last cube off; it drops into the strip, crossed out, and the
   readout counts the cubes taken, 1, 2, 3. A 4th: "That's 4 away. Take 3." Tap it to put it back.
2. "Count what's left." **Tap to count** the cubes still on the track: 1 … 4, the last ringed. None left: "None left."
3. **Write** `7 − 3 = [4]`. Wrong, the web's: 10: "That's 7 and 3 put together. Taking away leaves fewer than 7."
   3: "3 is how many you took away. Count the cubes still on the track." 7: "That's how many you started with." 5:
   "One too many. Skip the crossed-out cubes when you count."

Say: "Taking away leaves fewer: count only what's still there."
Core: the web's k-sub as it is (the first three a 2–5, b 1 to a − 1, so at least one is left; after that a 4–10, b 1
to a, so "none left" can come up). Its first box (count
them all) is set from the picture. Check: the spec's. Depends on: k-add, gk-count10. How to: 7 − 3.

### Story problems within 10 (`k-story`) · web
K.OA.A.2 (put together folded in). **One block is one thing in the story**, a counter on the ten track (rows 12–16).
The story's three sentences are the words, one at a time on rows 0–2 (each sentence is the instruction while it's
there; nothing else is written on those rows), and the picture acts each one: "Mia has 5 apples." puts 5 counters on
the track, named 5 (the web's start box, set by the sentence).
1. "Mia gives 2 away." **Tap** "more" or "fewer" (two blocks under the track with those words on them: the web's "More
   or fewer?", which is the idea). Wrong, the web's: "Some apples go away, so there will be fewer than 5."
2. The sentence stays and the hand acts it out (Show me's ghost finger shows how on the first one). Going away: tap 2
   off (k-sub's move). Coming: slide the 2 on (k-add's move). The count runs down or
   on by itself as they go or come: counting was k-add's and k-sub's; the new idea here is which one.
3. "How many apples are left?" **Write** `5 − 2 = [3]`. Wrong: the web's slips (added instead, wrote the change, forgot
   the change, one off).
Put together (folded in): "Mia has 3 apples. Leo has 2 apples. How many apples in all?" Two trains (Leo's striped);
step 1 asks more or fewer than 3; slide them together; `3 + 2 = [5]`.

Say: the web's idea: "Some go away, so take away." / "More come, so add." / "Put together, so add."
Core: the web's k-story as it is (6 names, 6 things, take 0 or 1, two tellings; the first three 6 at most with changes
of 3 at most). New: tale 2, put together (take 0 only; a 2–9, b 1 to 10 − a; the second person is the next name), 1 in 3
of the adding stories from index 3. Check: the spec's, one "take = 0" item drawn as tale 2. Depends on: k-add, k-sub.
How to: Mia has 5 apples and gives 2 away.

### Number bonds (`k-bonds`) · web
K.OA.A.3 (another way folded in). **One block is one cube.** The bond on rows 6–15, as on the web: the whole's circle
(one block across) in the middle, the parts' circles 2 blocks lower and 3 blocks to each side, lines between; the
whole's number in its circle, the first part's in its circle, the other part's circle dashed with "?". Under it, from
row 19, the train of the whole on the ten track. "Cut after 2."
1. **Cut** the train (Multiply two-digit numbers' one cut: it snaps between cubes; the readout is the count before it).
   Let go after 2: the pieces part a square; the first keeps the chapter colour, the other turns striped. The wrong
   place: "That's 3. Cut after 2." For a part of 0 the instruction is "Cut at the start." and the cut sits on the start
   line.
2. "Write the other part." **Write** `5 = 2 + [3]`; the number fills the dashed circle as it's written (tapping the cubes
   counts them). Wrong, the web's: "That's the first group again. Count the other group." / "That's the whole. The other
   group is smaller." / "The parts are smaller than the whole. Count only the other group."
3. "Find another way." (folded in) The pieces join; **drag** the cut to another place, and the bond's parts change as it
   moves (readout "4 and 1"). Let go where it wasn't before: a second line writes itself, `5 = 4 + 1`. The same place:
   "That's 2 and 3 again. Try another place."

Say: "Cut it anywhere: the two parts make 5 again."
Core: the web's k-bonds as it is (whole 3–5 for the first three, then 4–10; part 1 to whole − 1, and from index 6 a
part of 0 one time in 6).
The whole and first-part boxes are set from the picture and the cut. New: the another-way step (any cut place but the
first; its own line). Check: the spec's. Depends on: k-add. How to: 5 is 2 and 3.

### Make 10 (`k-make10`) · web
K.OA.A.4. **One cell is 2 × 2 blocks**: a big ten frame, 50 × 20 squares, from row 6, its dots 6 squares across in the
middle of their cells. "Count the dots."
1. **Tap to count** the dots: 1 … 7, the last ringed.
2. "Fill the frame." **Tap** each empty cell (Tap pieces): a striped dot drops in, numbered 1, 2, 3 (how many more).
   Full, the frame gets "10" under it. A cell with a dot: "That box has a dot."
3. **Write** `7 + [3] = 10`. Wrong, the web's: 10: "10 is the full frame. How many more dots does it need?" 7: "That's
   the dots already there. Count the empty boxes." 17: "That's too many. The frame only holds 10." One off: "Touch every
   empty box." / "Touch each empty box only once."

Say: "The frame holds 10, so the empty boxes are how many more."
Core: the web's k-make10 as it is (have 1–9; the first three 6–9). Check: the spec's. Depends on: k-bonds. How to: 7 + ?
= 10.

### Facts to 5 (`gk-five`) · new
K.OA.A.5, K.OA.A.1 (fingers). **One finger is one block wide**, a block apart, so each finger is one thing and the
gaps keep them apart for counting (fingers 2 blocks wide and touching read as one bar). A hand in blocks, from row 6:
a palm 9 × 2 blocks with five fingers on it; a finger up is 4 blocks tall (filled), a finger down is folded to 1 block
(outlined); the thumb is the left one, a block shorter; 45 × 30 squares in all. The fact is the record from the start, 3 rows under the hand: `3 + 2 = [ ]`, its
first number the fingers already up. "Raise 2." (or "Fold 1.")
1. **Tap** fingers (Tap pieces): for + 2, two down fingers rise, striped; for − 1, one up finger folds, crossed. The
   readout counts the fingers up. Too many: "That's 3 more. Raise 2." Tap one to put it back.
2. **Write** `3 + 2 = [5]`. Wrong, for `3 + 2`: 1: "That's 3 take away 2. + means more fingers go up." 2: "2 is how
   many went up. Count every finger that's up." 4 or 6: "Count the fingers that are up: one number for each." For
   `4 − 1`: 5: "That's 4 and 1 more. − means a finger folds down." 1: "1 is how many folded. Count the fingers still
   up." 3 for `3 + 2` or 4 for `4 − 1`: "That's how many were up to start."
The fact leads the picture here (as lining up leads in 5th grade's Adding decimals), because knowing it by heart is
the lesson. For fluency the help fades across the page: together, the hand first, then the write; on your own, the
write first and the hand shows it after; the test, the fact alone, the hand only drawn after the answer.

Say: "3 and 2 make 5 every time: a whole hand."
Core (new `FactsToFive`): a, b and the sign: every + and − fact with numbers and answers 0–5. Easy first: index 0–2 +
with answers up to 4; 3–5 + and − by turns, no 0; 6+ any fact, 0 now and then. Slips: added for −, took away for +,
wrote the second number, wrote the first number, one off. Check: i3 where −; i3 where the answer is 5; i6 with a 0
(0 comes only from index 6); i3. Depends on: k-add,
k-sub. How to: 3 + 2.

## 5 · Teens and tens

### Count to 20 (`k-count20`) · web
K.CC.A.2, K.CC.B.5 (a ring folded in). **One block is one dot.** The twenty track (two ten tracks touching, 50 × 10
squares) from row 8; n dots, the top row full. "Count the top row."
1. **Tap to count** the top row: 1 … 10, the last ringed; 10 at its right end.
2. "Keep counting." The top row's numbers fade, all but the 10. **Tap to count** the bottom row: 11, 12, 13, 14.
3. **Write** `[14]`. Wrong, the web's: 4: "That's only the bottom row. Don't start again at 1. Say 10, then keep going:
   11, 12..." 41: "You have the right digits. Write 14 with the 1 first." One off: "One short." / "One too many."
A ring (folded in, from index 6, every third problem: 6, 9, 12 …): n dots spread evenly round the edge of a 6 × 6 square of blocks
(20 places, 30 × 30 squares), so no gap shows where to begin; **tap to count** all the way round (the numbers show where you began); write n.

Say: the web's idea: "A full row is 10, so keep counting on from 10."
Core: the web's k-count20 as it is (n 11–20; the first three 11–15). New: the ring kind. Check: the spec's (i3 where
n ≤ 14; i3 where n ≥ 17; i3 where n = 20), and its last item as i6 (a ring). Depends on: gk-count10. How to: 14.

### Write numbers 0 to 20 (`k-write`) · web
K.CC.A.3. **One block is one cell of a ten frame** (25 × 10 squares; 11–20 two frames, one under the other with a block
between, 25 × 25), from row 6 at the left. To their right, 2 blocks away, the writing place: 6 × 10 squares a digit
(the web's stroke shapes, `DIGITS` in `numerals.ts`). "Count the dots."
1. **Tap to count** the dots, the last ringed. For 0 there are no dots; a tap on the frame says "None. None is 0."
2. "Tap the 7." Three numerals (the web's look-alikes, in its order) in boxes under the frames: **tap** one.
   Wrong, the web's: "That's 9, not 6. 9 has its loop at the top. 6 has its loop at the bottom." / "That's 61. 16
   starts with 1: 1 ten and 6 ones."
3. "Trace it." The numeral moves to the writing place and waits there faint, each stroke's start dot numbered.
   **Trace**: the ink follows the finger only along the stroke; a stroke done, the next start dot shows. Readout: "1 of
   2". Lifted early, the stroke waits where it stopped.
4. Record: the traced numeral in the chapter colour, and `7 dots` under the frames.

Say: the web's: "The number says how many dots."
Core: the web's k-write as it is (n 0–20: 1–5, then 1–10, 0 now and then at index 6, then teens, or 1–10 and 20). New:
the trace step (no box; done when every stroke is traced; Show me traces it). Check: the spec's. Depends on: k-count20.
How to: 7.

### Teen numbers (`k-teens`) · web
K.NBT.A.1, K.CC.B.5 (making a teen folded in). **One block is one cell.** Two ten frames side by side, a block apart
(55 × 10 squares) from row 8: the first full, named `10` under it; the second holding the ones. "Count these."
1. **Tap to count** the second frame: 1 … 6; `6` goes under it.
2. See: the `6` slides onto the `0` of `10` and covers it: `16`, ten ones and 6 more written as one number.
3. **Write** `10 + 6 = [16]`. Wrong, the web's: 61: "You have the right digits, but the 1 for the ten comes first: 16."
   6: "Don't forget the full frame. Start at 10 and count on 6." One off: "Start at 10, then say 11 for the first extra
   dot." / "One too many. Start at 10 and count on only 6."
Make a teen (folded in: the standard's decompose, and K.CC.B.5's count out): from index 3, every other problem: "Make
16." Two empty frames; **drag** across them (Tap pieces with a drag, the way Volume covers its floor: the first frame
fills first; the readout counts); let go on 16; then `16 = 10 + [6]`. Now and then 20: `20 = 10 + [10]`.

Say: the web's: "A teen number is a ten and some ones."
Core: the web's k-teens as it is (ones 1–9; the first three 1–5). New: the make kind (ones 1–10). Check: the spec's
(ones 3 at most; ones 6 or more, twice, one of them made; one more). Depends on: k-count20, k-write. How to: 16.

### Count by tens to 100 (`k-tens`) · web
K.CC.A.1 (by tens). **One ten is a ten frame tile**: 2 × 1 blocks (10 × 5 squares), its dots 2 × 2 squares. Tiles go
in rows of five (50 squares wide), so 10 tens are two rows a block apart (50 × 15 squares), from row 8. The web's rows
of ten would be 50 squares tall. "Count by tens."
1. **Tap to count** each tile, by tens: each tapped tile gets its running total over it, 10, 20, 30, 40; the readout
   counts by tens. Tapped again: "You counted that ten."
2. **Write** `10, 20, 30, [40]` (the web's line; it wraps after five). Wrong, the web's, with frames for rows: 4:
   "That's the number of frames. Each frame is 10, so count 10, 20, 30..."; 30: "One ten short. Say one ten for every
   frame."; 50: "One ten too many. There are only 4 frames."; 31: "Count by tens all the way. After 30 comes 40."

Say: "Each frame is 10, so count by tens."
Core: the web's k-tens as it is (2–10 tens; the first three 2–5). Its rows box is set from the taps. Check: the spec's.
Depends on: k-count20. How to: 4 tens.

### Count to 100 (`gk-count100`) · new
K.CC.A.1 (by ones), K.CC.A.2. **One block is one number**: the hundred chart, 10 × 10 blocks (50 × 50 squares) from
row 6, numbers small (20) in their blocks, written up to the start and empty after it. The camera frames the rows in
play (3 rows) at up to 125%.

*Count on.* "Count to 42." (37 is ringed)
1. **Tap** the next empty block, then the next (Tap to count, in the chart's order): each writes its number, 38, 39, 40,
   then the first block of the next row, 41, 42. The readout is the number written. A tap anywhere else writes nothing:
   "41 comes next. It starts the next row."

*Which goes here?* The whole chart is written but one block, which is empty and dashed (40, between 39 and 41); the
camera frames its row and the rows above and below. "Tap the missing number."
1. **Tap** the number that goes there, from three blocks under the chart: it, and the numbers above and below it on the
   chart (30, 40, 50).
   Wrong: the chart lights where that number really is: "30 is up here. After 39 comes 40."

Record: the numbers the child counted, in the chapter colour in their blocks (K writes numbers to 20; past 20 they're
found and read, not written). See: the camera steps back to the whole chart and the last column lights, 10, 20, … 100
(k-tens' count).

Say: "Each row is ten numbers: 40 ends one row and 41 starts the next."
Core (new `CountTo100`): kind count on or which goes here; count on: a start 1–94 and 3–7 more, ending at 100 at most;
which: a number 2–99, its row around it, its choices the numbers 10 above and below it (or the next two in its column at
the chart's top and bottom). Easy first: index 0–2 count on within one row, 30 at most; 3–5 across a row's end; 6+ both
kinds, up to 100, and 1 count on in 4 ends at 100 (so the last row and 100 come up). Slip: picked the number above or
below. Check: i3 where count on crosses a row's end; i6 where which and the number ends in 0; i6 where count on ends at
100; i6 where which and the number is 50 or more (the which kind and 100 start at index 6). Depends on: k-tens.
How to: 37 to 42.

## Open questions for G

1. **A voice for kindergarten.** Most kindergartners can't read yet, and K's story problems are three sentences. Without
   a voice the instruction is carried only by the How to and Show me's ghost finger, and a story can't be followed at
   all. Should Obento² speak the words in K (and in 1st and 2nd): the instruction, a miss, the story, and each number as
   it's counted? Sound was put off on 25 Oct; this decides whether it comes back with K.
2. **How K writes a number.** K writes 0 to 20 in its records. The box could take the iPad's number keyboard (today's
   rule), a number row drawn on the paper under the record (tap 7 to write 7: 0–10, a second row 11–20, tens for
   `k-tens`), or the child tracing the digits each time (slow). I'd use the number row; it's also the count, in order.
3. **Page and test length for K.** A K problem is 2–4 hand moves, and a five-year-old sits for less time. Keep 5th
   grade's page (3 together, 6 on your own, a 12-problem test with 10 right to pass, one rule for every test), or give
   K a shorter one (for example 2 together, 4 on your own, and an 8-problem test with 7 right)?
