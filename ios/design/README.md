# Lesson design: how every lesson gets its own screen

G, 20 Oct 2026. Read this before designing or building any lesson.

## Why

A single layout that every lesson fits into has failed twice:
- **The web app** draws all 191 lessons on one screen: the problem, a picture, then a stack of one-line steps. It looks tidy, but nothing is written the way school writes it. Even column adding is a line that says "(write 3, carry 1)".
- **Obento²'s first try** at an automatic arranger (`ProblemGrid`) put a picture, a separate answer line and a separate sum into boxes. G found it confusing.

Each lesson is its own design, and the shared code is only tools.

## The rules

0. **One square, and the child's hands** (G 20 Oct, the lens for every lesson). Start each design from: *what is one square here, and what does the child do with their hands to find the answer?*
   - **The answer is countable.** One square is one unit (one thing, one piece, one hundredth, one cubic cm), fixed for the lesson wherever it can be, so every picture is exact and a wrong answer shows on the paper ("you shaded 5 pieces; 1/2 is 4").
   - **Place value is zoom.** The paper is endless: a square opens into 10 tenths, a tenth into 10 hundredths, drawn as the next line or grid on the same squares. ×10 is stepping out a level.
   - **Columns are place value.** Digits stay in their grid columns, two squares each, the point on a grid line.
   - **Snapping teaches.** Cuts, drags and points land only on grid lines. A whole has a fixed length chosen so its pieces land on lines (24 squares: halves every 12th line, fourths every 6th, sixths every 4th), so a common bottom is found by hand.
   - **The grid becomes what the maths needs:** a number line (one square = one step), a floor for cubes, rows growing together, axes.
   - **Hands first, typing last.** Each step names its hand move (tap a cell, drag a length, cut, group, place a point, build up) and what snaps. A number the hands found is written into the working by the app. The child types only the number school writes at the end, in its box in the working.
   - **The picture is the hero; Unit cubes is the model** (G 20 Oct). The maths is an object built of real units on the grid, big enough to read across the room: a unit may be a 2 × 2 cell or a whole block (5 × 5) when that is what makes it big and countable. The problem is set up **in** the picture (the bars, the box, the line, the rows), the child's hands build or find the answer **on** it, and the school working is a short written record beside or under it of what the picture showed, never the main event. The web is used only for its maths and its beats, never its layout (problem line, small diagram, stack of steps).
   - **Use the screen.** Each brief plans its scenarios on the iPad's landscape screen, about 68 × 45 squares, and says how much of it the picture takes (aim: the picture 60–75% of the width or height; the record a column of 12–20 squares).
   - **Layout, as Unit cubes:** what to do on the rows just above the picture (one short line; a second small line only when the move needs explaining, "Tap each square inside the box."); a live count under the picture while the hands work ("9 of 12 squares"); the record beside the picture, its rows level with what they record; the typing box in the record; Check under the picture. The last step's words are the short sentence that sums up what the picture showed ("2 layers of 12 is 24."), and the record line under it.
   - **How a move answers a step (for the builder).** Core's steps keep their `AnswerTask`s, checks and slip messages. The app turns what the hands did into the box values (a cut every 2 squares on a 24-square whole is `x = 12`; 5 pieces tapped is `x = 5`; a point dropped on a line is the number it makes) and checks them as if typed. A move step's Check is the same Check block under the working.
1. **A brief before any code.** Every lesson gets a brief in this folder (`<lesson id>.md`, using `add.md` as the template). G says yes to it before anything is built. A brief covers:
   - the idea, and what the picture proves
   - the school working the lesson is answered in, with the problem written once and the box where each number goes
   - the beats (Ask, Do, See, Say) and the hand move used
   - its **scenarios** (small and big numbers, story or bare sum, more than one whole, a remainder…), each with a text mock-up
   - questions for G
2. **The lesson places its own pieces.** In squares, for each scenario, in its own drawing (`LessonPictures`). A lesson that does this returns `Drawing(shared: true)`: the layout keeps its picture and working exactly where the lesson put them. Only what to do (level with the box) and Check (under the working) are added by the layout. Nothing is fitted into a box for it.
3. **Kits are tools, not layouts.** Picture kits (tape, number line, area grid, plane, balance, circle…) and working kits (fractions over one bottom, columns, the division bracket, equation lines…) are built once, with the first lesson that needs them, and reused. Each lesson still gets its own brief and approval.
4. **Check every scenario** on the iPad simulator at full size before G sees it. The `page-<id>-<step> -numbers a=1,b=2,… [-story]` screenshot opens a problem with chosen numbers.

## Order: by kit

Each lesson builds the kit that the most later lessons need. All 191 lessons, with the picture and working each uses, are in `lesson-map.md`.

| Kit | Lessons | First lesson | Status |
|---|---|---|---|
| tape (bars) + fractions over one bottom | 24 | Adding fractions (`add`) | Approved 20 Oct; redesigned for rule 0 (cut by hand, shade to match), see `add.md` |
| area grid + columns | 20 | Multiply two-digit numbers | Approved 19 Oct |
| area grid + division bracket | 2 | Long division | Built, not reviewed |
| number line | 15 | Rounding decimals (`g5-round`) | Redesigned for rule 0 (zoom levels, tap, place, drag), see `g5-round.md` |
| plane | 23 | (grade 8) | |
| balance / algebra tiles | 18 | (grade 6) | |
| early-grade counting pictures | 63 | (K–4) | |

**5th grade, designed 20 Oct** (each to rule 0 and the Unit cubes standard; waiting on G):

| Lesson | Brief | The hero, and one unit | Hands | Picture on screen |
|---|---|---|---|---|
| Adding fractions | `add.md` | bars a whole of 48 squares | cut both bars, shade to match, type the top | 48 of 68 wide |
| Rounding decimals | `g5-round.md` | zoom lines, one step = a block | tap the place, tap the next, drag to the closer end, type | 50 of 68 wide |
| Adding decimals | `g5-adddec.md` | opened wholes, a hundredth = a 2 × 2 cell | drag the wholes, pour the hundredths, close a full whole, type | 45 of 68 wide |
| Mixed numbers to fractions | `g5-improper.md` | bars a whole of 48 squares | cut the wholes, type the fraction | 48 wide, up to 35 tall |
| Fraction of a number | `g5-fracof.md` | one thing = a 3 × 3 cell (2 × 2 past 40) | deal into rows, tap the rows taken, type | 45–50 wide |
| Dividing by a unit fraction | `g5-unitdiv.md` | bars a whole of 48 squares | cut one whole, type how many | 48 wide, up to 39 tall |
| Converting units | `g5-units.md` | a small unit = a 2 × 2 cell | tap open, pick more/fewer, open or cut the rest, type | up to 48 wide |
| Order of operations | `g5-order.md` | one = a 2 × 2 cell | tap the part first, cross out, drag rows, deal, type | up to 36 × 24 |
| Multiply by 10, 100, 1000 | `g5-pow10.md` | a place = a block column (2 blocks when 5 or fewer) | tap the zeros, drag the digits left, type the zeros | 30–50 wide |
| Multiplying decimals | `g5-multdec.md` | one whole = 30 × 30, a hundredth = a 3 × 3 cell | type the digits' product, tap a tenth column and row, place the point | 30 × 30 |
| Dividing by a decimal | `g5-divdec.md` | number line, a tenth = a square | drag each point, hop along, type | up to 50 wide |
| Multiplying fractions | `g5-multfrac.md` | one whole = a 36 × 36 square | cut rows and shade, cut columns and shade, type | 36 × 36 |
| Volume of a box | `g5-volume.md` | a cube = a block (5 × 5), as Unit cubes | drag the floor, build up layers, type | up to 40 × 40 |

Subtracting fractions (`sub`) and Adding and subtracting (`mix`) share Adding fractions' design and code. Each still needs G to look at it.
