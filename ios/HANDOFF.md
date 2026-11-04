# Handoff: 5th grade on paper (24 Oct 2026)

For whoever picks this up, in this conversation or a new one. Read `CLAUDE.md` first (G's rules and the 20 Oct
direction), then `design/README.md` (the design language) and `design/grade5.md` (every lesson's design).

## Where things stand
- **All 17 5th grade lessons are built "on paper"** and merged on `claude/project-thread-15w6ys`: the grid is the
  measuring tool, the picture is the hero, each step is a hand move that snaps to the grid, the school working is the
  short record, typing only for the number school writes, Show me is a ghost finger that puts everything back.
  The standard every lesson matches: Rounding decimals and the Adding fractions family (G: "the only thing that
  worked" on the test page, `design/prototype/paper-lessons.html`, Claude's versions). Volume of a box is real 3D,
  built on Unit cubes (`App/CubesProblem.swift`, `CubesDrawer.swift`, `TiltCamera.swift`).
- **The app around them:** fair scoring (Show me isn't right; one rule for every test, 10 of 12 passes), hints drawn
  on the paper with a budget per lesson, rechecks for due lessons, results on the paper, a map of exactly 17 lessons
  (the proof lessons "ad" and "uc" are off it), saves that start fresh instead of crashing, the Me page with Today and
  a daily review, a grown-ups' page behind a hold gate, first launch ("Start here."). Landscape only.
- Builds in Xcode; 181 Core tests pass. G builds in **Xcode** (not Swift Playgrounds). G, 24 Oct: "you guys did an
  incredible job".

## Grades (3 Nov 2026)
- The map comes from the child's grade: `Core/Curriculum.swift` holds every grade's map as a list of chapters (5th grade's
  ids, tests and saves unchanged; its chapters' keys are their colours, so its tests keep "test-whole" etc.). A grade is
  live once a lesson of it is built (4th and 5th). `Map` in `App/PaperModel.swift` reads the current grade's `GradeMap`;
  `PaperModel.chooseGrade` switches (grade row, Me, Settings). Lessons not built yet show as faint dashed empty frames
  with their names; chosen, "Coming soon" (`Map.coming`). Each grade's first chapter is free.
- 4th grade chapter 1, Big numbers, is built (Core: `BigNumbers`, `TensHundreds`, `ReadWriteBig`, `CompareBig`,
  `PlaceValueRound`, `AddSubBig`; App: `Lessons/PlaceChart.swift` and a lesson file each). Shots: `page-g4-<id>-<step>`
  opens on 4th grade by itself; `-grade 4` for map moments.
- 4th grade chapter 2, Multiplying and dividing, is built (3 Nov; Core: `TimesAsMany`, `MultiplyBig`, `TwoByTwo`, `Deal`
  (g4-divide and g4-share share its phases), `StorySteps`; App: `TimesAsManyLesson`, `MultiplyBigLesson`, `TwoByTwoLesson`,
  `DealLesson`, `StoryStepsLesson`). Shots as chapter 1's, e.g. `page-g4-divide-2 -wrong`.
  Fixed after (3 Nov): Multiply big numbers takes 1-square cells past 3 rows (179 × 9 was at 57%), the dividing lessons and
  it keep a miss to one row, Story problems' bars start at their whole tens (a bar already at its nearest ten is pressed
  and let go there), the shared parts and the answer's mark on whole squares. `-shot zooms -ids a,b` writes each lesson's
  least zoom over many problems to the app's Documents/zooms.txt (`simctl get_app_container … data`).
- 4th grade chapter 3, Factors and patterns, is built (3 Nov; Core: `Factors`, `PrimeComposite`, `Patterns`; App:
  `FactorsLesson`, `PrimeLesson`, `PatternsLesson`, their shared `SquaresKit`). Least zooms: 85%, 95%, 78%.
- 4th grade chapter 4, Fractions, is built (3 Nov; Core: `Decompose` (with `Fractions4`, the whole's length and piece
  names), `EquivFractions`, `CompareFractions`, `LikeFractions` (`.add`, `.take`); App: `DecomposeLesson`, `EquivLesson`,
  `CompareFractionsLesson`, `LikeFractionsLesson`, their shared `FractionsKit4` (F4: pieces drawn one by one so they
  glide, fractions in a column, record lines). The ruler (`BarsKit`) can sit under the bars (`under`, `reads`). Compare
  and like fractions keep their bars 3 squares apart so the sign stands clear between the names. Least zooms: 86%, 83%,
  87%, 76%, 90%. Shots: `page-g4-decompose-0 -numbers kind=0,a=5,d=8`; `select-<id> -grade 4` chooses a lesson on the map.
- Chapter 1 fixed for 75% (3 Nov): Tens charts past 3 frames take 1-square cells (67% → 83%); Add and subtract keeps a
  miss to one row, its record may go beside a five-column chart, six columns take 1-square cells (56% → 75%).
- G's calls of 3 Nov (design/README.md) applied to 4th grade: numbers in a record line, list or Rounding's record are
  written tight (`Record.tight`, width `Record.width(.n)`), column working keeps two squares a digit; the map lays out
  only built chapters, the grade test once all are; Story problems' sharing amounts cut into whole squares.
  Two-digit times two-digit stays at 41% at its k = 2 scale (its words are drawn twice as big there).
- 4th grade chapter 5, Mixed numbers, is built (3 Nov; Core: `MixedNumbers4` (`Mixed4`, `AddMixed`, `SubtractMixed`,
  `FracTimesWhole`); App: `AddMixedLesson`, `SubtractMixedLesson`, `FracTimesWholeLesson`, their shared `MixedKit5` (`M5`
  bars half as long, whole bars 2 tall; `GroupSlide`, a group slid onto a target)). To keep every problem at 75% the
  record sits in the column the hands emptied: under the right number's column (adding, subtracting; the names go into
  it once the pieces are in), or where the groups were (times a whole number); `PaperLesson.blocksLeft` puts the blocks
  under it, `blocksAt` puts a story's choices in a column beside a tall picture. Least zooms: 81%, 75% (a story's pick),
  78%. Subtracting with too few pieces: the slide stops (a step, not a miss) and the next says "2 fifths can't take away
  4. Open a whole. Tap a whole bar."; a whole tapped first opens it straight away.
- 4th grade chapter 6, Decimals, is built (3 Nov; Core: `Decimals4` (`Dec4`, `TenthsHundredths`, `DecimalLine`, `CompareDec4`);
  App: `TenthsHundredthsLesson`, `DecimalLineLesson`, `CompareDec4Lesson`, their shared `DecimalsKit4` (`D6`: a whole 20 × 20,
  a tenth a column, a hundredth 2 × 2); `F4.Tok.d` writes a decimal tight, `.fr` a fraction with 3-digit boxes). The
  preview's grey second line is folded into each instruction. Least zooms: 75%, 81%, 76%. Shots as before, e.g.
  `page-g4-decline-1 -numbers w=1,h=45,story=1,thing=1`, `page-g4-deccompare-0 -numbers w=0,a=50,b=45,pa=1,pb=2`.
- 4th grade chapter 7, Measurement, is built (3 Nov; Core: `Measurement4` (`Meas4`, `Convert4`, `MeasureStory`, `AreaPerim`,
  `LinePlot4`); App: `ConvertLesson`, `MeasureStoryLesson`, `AreaPerimLesson`, `LinePlotLesson`, their shared `MeasureKit7` (`M7.row`:
  numbers, times, prices, units, fractions and boxes written as words)). Converting: the ruler runs from the first bar's left end and
  is checked as it's let go; more than 6 bars sit 2 squares a bar with the ruler on the first bar's top edge (75%). Story problems:
  hops are hand state (`k`, `e0`…) until the last, which is checked; times typed in two boxes [h]:[min]. Area: `AreaPerim.Parts.U` is
  5 squares a meter (a block) or 2 ("2 squares are 1 m."), chosen so every problem shows at 75%; the trace snaps to the corner-to-corner
  point nearest the finger. Line plots: the cards wait in three columns beside the plot (so a tall stack still shows at 75%) and the
  X's glide down from them. The preview's See stages (the bars counting on, the extra counting on, the half going round, the X's
  dropping) draw in at the start of the next step. Least zooms: 75%, 88%, 76%, 75%. Shots as before, e.g.
  `page-g4-convert-1 -numbers k=0,n=3,m=5,story=0`, `page-g4-area-0 -numbers l=5,w=3,fold=0 -drag 5,10,25,20`.
- 4th grade chapter 8, Lines and shapes, is built (3 Nov; the last chapter: all 35 lessons of 4th grade are on the map; Core:
  `Geometry4` (`Geo4`, `LinesRays`, `Turns4`, `Protractor4`, `AnglesAdd`, `Classify4`, `Symmetry4`); App: `LinesLesson`, `TurnsLesson`,
  `ProtractorLesson`, `AnglesAddLesson`, `ClassifyLesson`, `SymmetryLesson`, their shared `GeoKit8` (`G8`: the page corner, the
  protractor, arcs, wedges, arrowheads, choices in a row or a column, `placeRecord`)). Arms turned off the grid are drawn at their
  true angle. A page corner lying on the picture is its edges only and the protractor's paper a band round its scales (fills that
  overlap band on the iPad). The fold is drawn flat with the preview's perspective while it's dragged (the half lies over the paper
  as plates and overLines), and lands or unfolds on the paper's spring (`Sketch.from`); the paper's own tilt stays for solids.
  A ghost drag can bend (`GhostMove.path`: the arm turned round a circle). Least zooms: 75%, 75%, 81%, 81%, 78%, 78% (steep figures
  26 squares, two lines on 40 × 22, the square 22 and the rectangle 26 × 14, so each shows at 75%). Shots as before, e.g.
  `page-g4-lines-0 -numbers kind=2,item=1,turn=5`, `page-g4-symmetry-1 -numbers kind=0,shape=1,line=2 -wrong2`;
  `map-started -grade 4 -whole` frames the whole grade (past the camera's least zoom, screenshots only).
- Calls of 3 Nov (design/README.md, 6 and 7): a first miss rings only the general area, the exact spot comes with a second miss
  on the step (`hint2: ["spot": 1]`, drawn behind `s.on("spot")`; `PaperState.at(hint:)` measures both) or Show me, in chapters
  1–8; Converting measurements labels pieces of 4 squares or less only on the first and every 5th.
- The keyboard never hides the work (3 Nov, app-wide): every keyboard notice counts (the system-hosted keys post only
  some), its frame is turned into the app's way up (the simulator holds the iPad portrait while the app is landscape, so
  the keys draw down the right side), and the camera frames into the room above, left or right of them
  (`PaperModel.room`), in this order (call of 3 Nov, "keep the work readable"): the whole problem at 75%+; else the record
  line being typed (this step's boxes, what's written on their rows, Check) with as much of the problem's width and then
  of the picture above it as fits at 75%; else that line alone as big as it fits. The whole problem is never shrunk below
  75% to fit beside the keys (`WorkProblem.stageFrame`, `Sketch.bounds(from:to:)`); it glides there and back.
  `-keypad -zoomlog` writes the settled zoom to Documents/zoom.txt. Checked keys up: 4th Measurement story 72% → 75%,
  5th Multiply two-digit 47% → 75% (the record and the picture's right part), 6th Ratio tables' column past the paper
  53% → 63% (its line, the table beside the boxes, is wider than 75% allows), 6th Unit rates 90% (unchanged).
- Never remove an animation (3 Nov): a sketch part can morph (`Sketch.morphs`, or `from` to start a new part in another
  shape) along a spring's path, and wait first (`Sketch.delay`); moved parts glide on the same spring. Chapter 5's whole
  grows into pieces (`M5.opened`) and full bars shrink into wholes (`M5.closed`); Tenths and hundredths' poured
  hundredths glide from where they were let go. `-slow N` runs the paper's clock N times slower from a shot's finger
  move, to film it (screenshots in a loop).
- The refined call 1 (3 Nov): a line's numbers and signs take the fewest whole squares they fit, centred, so gaps are
  even (`Record.width`, `Record.opWidth`, `F4.Tok`); a number typed into a box in a line is written tight, right-aligned
  with room for the cursor, the box the fewest whole squares that fit (`WorkBox.word`, `Record.boxWidth`). Boxes in
  column working (and 5th grade's, whose lines are written two squares a digit) keep a digit to a cell.
- Chapter 2 zooms (3 Nov): Multiply big numbers past 7 rows puts its record a row closer and the sum's rule right under
  the parts (73% → 76%); Story problems with narrow bars put the record beside them (73% → 76%).
- **6th grade is live** (3 Nov; Core: `Curriculum.grade6`, all 36 lessons in 8 chapters, only built chapters on the map). Chapter 1,
  Ratios and percents, is built (Core: `Ratios6` (`Ratio6`, `EquivRatio`, `RatioTable`, `UnitRate`, `PercentOf`, `PercentWhole`), tests
  `RatiosG6Tests`; App: `EquivRatioLesson`, `RatioTableLesson`, `UnitRateLesson`, `PercentOfLesson`, `PercentWholeLesson`, their shared
  `RatiosKit6` (`R6`: cells, the handle, a hint's ring, the first-quadrant plane two squares a unit)). To show at 75%: Equivalent ratios'
  cells are 3 × 3 up to 6 times, 2 × 2 past; Ratio tables' table is two squares a row, 3 rows under the plane, its written lines beside it
  with Check by the line being written (`blocksAt`), the compare's names in a column at the plane's top right; Unit rates' cells are 2 × 2
  whenever that (record under or beside) shows at 75%, else one square with the first and every 5th row labelled, and the copy drags to
  m + 2 rows (the preview's m + 3). Least zooms: 78%, 76%, 76%, 112%, 85%. A miss rings the general area (the total to reach, the bar,
  the table's column lit), a second the exact spot. Shots as before, e.g. `page-g6-ratiotable@6-2 -wrong` (the compare kind),
  `page-g6-rate-2 -numbers u=14,n=9,m=12,item=0,kind=0`, `map-started -grade 6 -whole`.
- 6th grade chapter 2, Factors and fractions, is built (3 Nov; Core: `Factors6` (`Fact6`, `Lcm6`, `Gcf6`, `DivideFrac6`), tests
  `FactorsG6Tests`; App: `LcmLesson`, `GcfLesson`, `DivideFractionsLesson`). As the preview: LCM hops b's along a line a square a
  number (two up to 24), taps the first landing a goes into (a's hops come under to it), writes L ÷ a; GCF cuts two bars with the
  ruler under them (any whole length; end dots green or red with what's over), writes A + B = g([m] + [n]); Dividing fractions picks
  More/Less than 1 (the engine's choice row), lays c/d's under the a/b (the last cut off, dashed), cuts all three rows with the
  ruler, then flips, multiplies and simplifies in one line; the ribbon story is index 5, 8… (in the pick's words, no operation step).
  To show at 75%: bars 69 squares or longer (GCF's 72, Dividing fractions' wholes of 70 and 72) have their names over their right
  ends, bars further apart; hint rings start inside the left edge. Least zooms: 79%, 75%, 75%, except GCF with a bar of 81
  (g = 9 with a 9, about 3% of problems) at about 68% (dropped 4 Nov, below). Shots e.g. `page-g6-lcm-1 -numbers a=4,b=6 -wrong`,
  `page-g6-gcf-0 -numbers g=6,m=3,n=5 -drag 2,12,4,12 -hold`, `page-g6-divide-2 -numbers a=2,b=3,c=1,d=4,story=0`.
- Calls on chapter 2 (4 Nov): GCF's generator keeps every bar 72 squares or shorter (the 9 × 9 = 81 case is dropped, not
  shrunk; `Gcf6.longest`), so GCF is at 75%+. A wrong pick in a choice block shows red, a right one green for its moment, never
  the picked colour (`Sketch.Block.choice`, app-wide; `WorkProblem.choose` clears the verdict). A miss with several boxes reds
  only the boxes not holding what's wanted (`Rig.stackedStill`). Ratio tables with the keys up writes its lines on their own
  rows under the table (`PaperState.keys`, set while the iPad's keys are up for the step's box): 63% → 75%; keys down they stay
  beside it (76%).
- 6th grade chapter 3, Long division and decimals, is built (4 Nov; Core: `Decimals6` (`Dec6` exact decimals, `Place6` names,
  `LongDiv6.Plan` shared by `LongDivision6` g6-longdiv and `DivideDec6` g6-decdiv, `DecAddSub6`, `DecMult6`), tests
  `DecimalsG6Tests`; App: `LongDiv6Lesson` (both divisions), `DecAddSubLesson`, `DecMultLesson`). As the preview
  (`design/prototype/grade6-ch3.html`): long division taps the digits it starts with, drags the bottom edge down a row of d at a
  time ("3 rows · 69"), writes what's left in the bracket's column working (a digit to 2 squares, no commas); decimals divide after
  both numbers' tiles are dragged left on a place chart, and break what's left into tenths (a tap, a 0 written after the point);
  adding/subtracting fills 0s, slides b's discs up, closes ten or breaks one into ten (school marks over a's digits), types the
  answer under the line digit by digit in its columns (`WorkBox.step`: a point-lined box 10 squares a place); multiplying drags
  a's and b's tiles whole, writes the wholes' product in columns (partials typed from problem 4), drags the product back, taps
  0s in. Each lesson draws its record in the picture's squares (`recordRow` 0) so taps on the bracket land; Check sits by the
  line being typed (`blocksAt`). Least zooms: 76%, 89%, 76%, 82%. Keys up: 75% (long division's and multiplying's lines,
  subtracting's answer row). Shots e.g. `page-g6-longdiv-3 -numbers d=23,q=304,r=9 -wrong`, `page-g6-decaddsub-2 -numbers
  am=124,ap=1,bm=3875,bp=3,op=1 -wrong2`, `page-g6-decmult-2 -numbers am=425,ap=2,bm=36,bp=1,pt=1 -keypad`,
  `page-g6-decdiv-0 -numbers d=15,q100=650,s=1 -drag 22,10,17,10 -hold`.
- **A miss line is never cut off** (call of 4 Nov, app-wide): with the keys up and the camera framed on the line being typed
  (`WorkProblem.keysFraming`), what a miss says is written just above that line, inside the frame, from the line's left edge and
  wrapping to its width (at least 16 squares), lifted above any record or picture words it would run into, on a paper plate only
  where it lies over the picture; when the keys go it's back on rows 3–4. Where the usual rows still show beside the keys it stays
  there. Checked on long division and multiplying decimals (`page-g6-decmult-2 … -wrong -keypad`). A lesson can keep part of its
  picture in that frame (`PaperLesson.keysFocus`: Points in four quadrants keeps the point and its prints). A minus can be typed
  into a box (the keys' "-" writes −; `LessonRun.type("−")` puts it first or takes it off).
- 6th grade chapter 4, Negative numbers, is built (4 Nov; Core: `Negatives6` (`Neg6`, `Negatives6`, `Compare6`, `Distance6`,
  `Quadrants6`, `Shapes6`), tests `NegativesG6Tests`; App: `NegativesLesson`, `CompareNegLesson`, `DistanceLesson`, `QuadrantsLesson`,
  `PlaneShapesLesson`, their shared `NegativesKit6` (`N6.Line` a line through 0, `N6.Plane` four quadrants, points in three shades, and
  **the fold**: `N6.Fold` + `N6.flap`, a sheet turned about a grid line drawn in perspective (`Sketch.lifted`), its plain back past
  upright; let go past 100° it's checked and the half lies back on the paper's spring carrying what's on it (the grid's own lines,
  strong ones on the block lines via `PaperState.gridTop`), the print fading in on the other side; let go short it falls back). As the
  preview (`design/prototype/grade6-ch4.html`), the grey second lines folded into the instructions. Departures: the plane is −7 to 7
  up (the design's −8 to 8 doesn't show at 75% under the words; every problem fits), Shapes on the plane writes its record beside the
  plane in short lines (side; `Area = 9 × 5`, `= [45]`; perimeter over three lines) instead of under it; placing several points, corners
  or brackets is one step (a wrong drop is checked at once, the point stays where it fell); the both-axes fold's second step says "Now
  fold over the other axis."; the landed half lies straight back (the preview turns it to 180° first). Least zooms: 75% (upright line),
  81%, 95%, 77%, 75%. Shots e.g. `page-g6-negatives-1 -numbers kind=2,n=9 -hand grab=1,sd=-1,g=12,th=1.1` (a fold held),
  `page-g6-compare-2 -numbers kind=5,a=-8,b=-5 -hand grab=1,br=-8`, `page-g6-quadrants-2 -numbers x=4,y=-2,kind=3 -wrong`,
  `page-g6-planeshapes-3 -numbers x1=-9,x2=9,y1=-6,y2=7,out=1,thing=1 -wrong -keypad`.
- **The fold, finished** (4 Nov, "never remove an animation"): a half let go past upright now finishes its turn to 180° on the
  spring, the print fades in under it, then it lies back flat, as the preview does (`Sketch.via`: a part morphs through a shape,
  rests `SketchDrawer.viaRest`, then on to its own; `N6.flap(landed:)`, words on the sheet wait until it's flat). A long upright
  number line numbers every second tick (every tick kept). Shots: `-pause N` waits N seconds before a finger moves (to film a
  move on a problem already showing).
- 6th grade chapter 5, Expressions, is built (4 Nov; Core: `Expressions6` (`Expr6`, `Expo6`, `Write6`, `Eval6`, `Equiv6`), tests
  `ExpressionsG6Tests`; App: `ExpoLesson`, `WriteExprLesson`, `EvalExprLesson`, `EquivExprLesson`, their shared `ExpressionsKit6`
  (`X6.strip` a letter's strip, its end dashed until known; `X6.View` Unit cubes' tilted view drawn on the paper)). As the preview
  (`design/prototype/grade6-ch5.html`), grey second lines folded into the instructions. Exponents: tap the power, drag the corner
  (a block a one), a cube's floor stands up in the tilted view (drawn on the paper with Unit cubes' angle, as the fold is, not the
  paper's own tilt) and its layers are dragged up, each rising from the one under it; record beside. Write: tray (n strip, ten
  squares), build line, Check (a lesson block), the short way typed, tap a part (a character, or a bracket under a longer part).
  Evaluate: rows of x and y strips, drag an end; more than 5 rows put the record between the x and y rows (so keys up shows the line
  beside the rows it's counted from). Equivalent: combine / distribute / factor / same-or-not; drag x to two lengths (its tries
  listed under the record); Same / Not the same in a column beside them. Departures: cubes of 4 or 5 a side are 4 or 3 squares a one
  (a block wouldn't stand up at 75%); the corner is 4 rows under the line with the square's sides named left and under it; the
  same-or-not miss line can't name the x the child tried (Core doesn't see the drag). Least zooms: 79%, 110%, 83%, 88%; keys up
  75%+ (9 rows of x 75%). Shots e.g. `page-g6-expo-2 -numbers a=3,n=3,b=2,c=7 -hand grab=1,l=2,y0=20,l0=1`,
  `page-g6-write-0 -numbers kind=3,q=12 -wrong`, `page-g6-eval-1 -numbers a=9,b=7,x=8,y=4 -wrong -keypad`,
  `page-g6-equiv-0 -numbers kind=1,a=3,b=4 -hand grab=1,col=6,cy=8`; `-shot zooms -ids … -verbose` lists every problem's steps.

- 6th grade chapter 6, Equations, is built (4 Nov; Core: `Equations6` (`Eq6`, `OneStep6`, `Ineq6`, `Depend6`), tests
  `EquationsG6Tests`; App: `OneStepLesson`, `InequalitiesLesson`, `TwoQuantitiesLesson`, their shared `EquationsKit6` (`E6.cells`: cells
  tinted, strong or crossed off; `E6.value`: a value as a number or a whole and a fraction)). As the preview
  (`design/prototype/grade6-ch6.html`), grey second lines folded into the instructions. One-step: slide the a off the end (the right
  side's last a cross off with it), slide a tray onto the bottom's end (the crossed cells come back), drag the right edge until it's
  all used, drag the bottom edge to all the rows; write x (a whole and a fraction box for the quarters type); check. A cell is 4
  squares only while what slides still fits 60 squares across (else 2). Inequalities: the story is the picture's name; drag the
  circle, tap it filled or open (kept, `run.kept["fill"]`), drag the arrow off the line's end, tap the test numbers that work. Two
  quantities: the across axis's name right of its arrow (under it the problem was 72%), the table's 4-square columns with each number
  tight on the middle grid line. Departures: the sign and the number are two steps (pick, then type), the sign's choices the engine's
  row under the record; the circle starts 6 from the number (the preview's is random); a stop already made is let go with nothing
  new (no check). Least zooms: 75%, 85%, 75%; keys up 75%+ (×'s rows aren't kept beside the line: 67% → 75%). Shots e.g.
  `page-g6-onestep-0 -numbers kind=1,a=7,xc=15 -hand grab=1,h=3,g=0,d=-10`, `page-g6-ineq-3 -numbers sign=3,n=-4,age=0,t0=-12.5,t1=-6,t2=-4,t3=0 -wrong`,
  `page-g6-depend-4 -numbers kind=1,st=0,c=5,back=1,xs=14 -wrong2`. A paper lesson's hands are asked again as the finger moves, so a
  release compares with where the drag started kept in the hand ("from"), never with the hand state the hands were made from.
  A kept-only move (no check) redraws the still picture (the still and layout keys read `run.kept`).
- Fixes of 4 Nov: a coefficient box hugs its letter (`WorkBox.hugs`, `M7.hugs`/`M7.widths`: a typed 3 reads 3x; a lone bracket
  takes one square, "3(2x + 1)" tight); the fold's half isn't a dark smear edge-on (held within ~5° of upright it's a thin line in
  the chapter colour; lying back it isn't drawn for the moment it passes edge-on, `SketchDrawer.Node.flips`); a held fold across the
  line moves 0's number and "$0" off the fold line to the side that stays down.

- **Shared 3D for the paper lessons** (4 Nov; `App/PaperStand.swift`): a PaperLesson step says it stands (`stands(s)`: the pivot in
  picture squares; `solid` true) and the paper tilts on the spring (`glide`, 0.9 s) to Unit cubes' view through the long lens (52°
  up, +28°); the tilted view is worked out every frame from the flat camera (the pivot where the flat camera puts it, at its zoom),
  so the flat camera keeps framing each step (keys, a new record line, pans and pinches) and the paper lies flat again when a step
  stops standing (`lingers` keeps it up a moment) or the problem leaves. What rises is `PaperDrawing.solids` (`Solids`: faces that
  fold on hinges with the spring, from an angle or over the paper; layers of cubes that rise; lines; labels standing on 3D points),
  drawn in true 3D by `SolidsDrawer` in Volume of a box's colours (`CubesDrawer.looks`, `layerMesh`), shaded by the way each face
  faces. Everything the lesson writes stands on a board facing the eye through the pivot, exactly where the flat paper has it
  (`WorkProblem.board`); a lesson places words beside what stands with `s.standing(pivot).up(x, y, z)` (seen from where the camera
  looks, `standEye`, so the long lens's growth near the eye is counted), and reads a drag up the screen as height with
  `Standing.rise`. Taps on blocks land on the board, drags on the standing paper (`dragPoint`). Volume of a box keeps its own camera
  flight and words (unchanged: before/after screenshots identical). Used by: Exponents and order (the cube stands up off the
  paper), Lines of symmetry (the half is a real fold about the dashed line, the paper itself flat), Trapezoid (the copy swings half
  a turn), Nets and Volume with fraction edges. `-showme` films Show me; `-slow N` films a tilt.
- 6th grade chapter 7, Area and volume, is built (4 Nov; Core: `Area6` (`Para6`, `Tri6`, `Trap6`, `Poly6`, `Nets6`, `FracVol6`), tests
  `AreaG6Tests`; App: `ParaLesson`, `TriLesson`, `TrapLesson`, `PolyLesson`, `NetsLesson`, `FracVolLesson`, their shared `AreaKit6`
  (`A7`: shapes filled however they bend, faint unit squares cut to the outline, a height with its square corner, chords and splits)).
  As the preview (`design/prototype/grade6-ch7.html`), grey second lines folded into the instructions. A check can read what the hands
  kept (`AnswerTask.expectKept`, values as "kept.<name>"): Area of a polygon's record is written from the pieces the child cut.
  Departures: Volume with fraction edges' write step says only "Write how many whole cubes." (the lit cube shows the 8; two rows of
  words were 72%); a parallelogram's record goes beside it or under it, whichever shows it bigger; a net's record sits in the corner
  its shape leaves (on two lines there when long), else beside or under; a net stands once a face is first taken hold of and stays
  closed 1.2 s before it opens flat. Least zooms: 80%, 79%, 79%, 82%, 79%, 76% (Exponents 78%).
- **The instruction is never a cut-off sliver** (call of 4 Nov, app-wide, `WorkProblem.keysFraming`): with the keys up, when the
  instruction's rows aren't all on the screen, it's written just above the line being typed (as a miss is), or, while a miss shows
  there, left out; back on its rows when the keys go.

## How the code is laid out
- `App/Lessons/`: one file per paper lesson (`PaperLesson.swift` is the protocol and registry; `Ghost.swift` the ghost
  finger; `BarsKit.swift` the fractions' bars, ruler and sliding pieces). `App/LessonHands.swift`: hand moves.
  `App/WorkProblem.swift`: the problem (stacked layout: instruction on rows 0–2, a miss/hint on 3–4, picture, record,
  blocks). Core lesson files in `Core/` hold the maths and steps; every lesson has tests.
- Tools: `tools/build.sh <derivedData>` (runs XcodeGen and builds), `tools/shoot.sh <simulator> <derivedData> <out.png>
  <moment> -landscape [args]` (moments in `App/Shots.swift`, e.g. `page-<id>-<step> -numbers k=v`), `tools/sheet.py`
  (contact sheets), `tools/playgrounds.sh` (Swift Playgrounds check, no longer required).
- After pulling, run `xcodegen` in `ios/` so Xcode sees new files.

## Known rough edges (polish next)
Fixed on 25 Oct (lane B, `work/finish-b`), each with a before/after picture:
- Dark mode checked on all 17 lessons; the chapter colour is lifted a little on the dark paper so answers read clearly.
- Small pictures: Multiplying fractions (its names centred until shaded; problems with bottoms up to 5 at full size),
  Dividing by a decimal (a line of one or two wholes drawn 3 or 2 squares a tenth), Multiply story problems (words
  stay normal size), Fraction of a number (12 or fewer things drawn 4 × 4, 16 or fewer 3 × 3).
- Multiplying decimals keeps its 10 × 10 whole (decided; `design/grade5.md` says so).
- Daily review and tests: what a miss said goes when the next question comes.
- Fraction of a number / Multiplying fractions: the groups and rows the child tapped stay shaded (saved with the problem).
- Long division: a story's "Pick what to do" no longer shows the bracket; a narrow strip's count no longer runs into the
  handle. Multiplying fractions' overlapping fills flickered in bands; drawn as pieces that never overlap.
- The real-touch UI tests (`UITests/PlacesTests.swift`) pass on the simulator.
Still open: Volume of a box's 3D steps take about 12 s to reach in a screenshot (shoot them with `WAIT=16`); the
biggest Multiplying fractions squares (bottoms 6 to 9) still draw their words twice as big and the square smaller.

## Next (G, 25–29 Oct: Claude leads; 5th grade is finished, now the app around it)
Built since 25 Oct (previews in `design/prototype/`, G approved each first):
- **Setup on first launch** (`App/SetupPage.swift`, `Core/Setup.swift`; preview `front-door.html`): welcome, name, grade (5th live,
  others dead "coming soon"), a grown-up's reminder and sound, Back on every step; a fresh map looks untouched. One child per iPad.
- **The calm smart pill** (`App/Toolbar.swift`, `Core/Pill.swift`): icons only, no words under them (G: "looks bad with the
  words"), step squares, one action in words, live readout while dragging; ⋯ More opens like a drawer (slides up from behind
  the row, clipped to the pill). Close is a plain ×.
- **Grown-ups**: the paper has This week (new practice records per day: problems and active time, `Core/Week.swift`) and
  Lessons; everything read or set lives in **the island** that grows out of the pill (`App/Island.swift`; preview
  `island.html`): the 3-second hold, then Settings · Privacy · Help · Plan. AppInfo.privacyURL / supportEmail are nil
  ("Coming soon.") until there's a website.
- The Lessons button frames what's on the map now; a tapped lesson glides to 85%. The map's 3-column shape leaves room at the
  sides; G parked a 4-column map for later.
Next, in order:
1. G tries the island on the real iPad (smoothness, typing the name); the daily reminder on a real iPad.
2. **Monetization plan before App Store basics** (G: "super important"): a short write-up of options for G (see memory).
3. App Store basics for a kids' app: privacy policy page and support email, empty and error states, icon and launch screen
   when the branding exists. Then a branded feel and a new name (Obento no longer fits; "Paper" is too common).
4. A full walkthrough as a new family, then the other grades.
- Keep the Mac cool: one simulator at a time across all workers; `tools/build.sh` builds niced, 4 jobs.
- Branding (icon, name) is G's, later; don't write the app's name anywhere new.

## Working notes (what went wrong, so it doesn't again)
- At most 2–3 simulators at once (five booted overloaded the Mac for hours); `shoot.sh` quits the app after each shot.
- Ultracode/max effort burned most of a week's tokens; work at high effort, one review at most, merge as pieces land.
- Show G progress as it happens (screenshots in a Desktop folder; G can't open scratchpad paths).
- Worktrees `/Users/geremy/Claude/bento-work/lane-a…d` and worker simulators "Obento Worker 1–4" are from the last
  batch; all their work is merged, so they can be reused or removed (`git worktree remove`).
