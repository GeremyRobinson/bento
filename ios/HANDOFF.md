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
- 6th grade chapter 8, Data, is built (4 Nov; the last chapter: all 36 lessons of 6th grade and its grade test are on the map; Core:
  `Data6` (`DotPlot6`, `Histogram6`, `Mean6`, `Mad6`, `Median6`, `BoxPlot6`), tests `DataG6Tests`; App: `DotPlotLesson`, `HistogramLesson`,
  `MeanLesson`, `MadLesson`, `MedianLesson`, `BoxPlotLesson`, their shared `DataKit6` (`D8`: the question, cards 4 × 2 crossed off once
  placed, a dot or square gliding off its card onto its stack (`D8.glide`, as 4th grade's X's), bars of squares, numbers tight under bars,
  `D8.via`, `D8.waiting` a faint box a later step fills)). As the preview (`design/prototype/grade6-ch8.html`), grey second lines folded
  into the instructions (Histograms: the question, then "Tap the stretches it asks for."). The order cards went down is kept
  (`run.kept["p<j>"]`) so stacks never reshuffle; a sort's order likewise (`o<p>`). Departures: Find the median's numbers are 1–25 (the
  web's 1–30 is 68% tall under the words with room to grow; 25 is 76%); MAD's distance columns touch (2 apart) when 3 apart would pass 73
  squares; the levelling and the "see" beats draw in at the start of the next step (MAD's distances slide off the bars into their row,
  rest, then level, `Sketch.via`; the box draws in on the write step); the dot plot's pick is the engine's choice column with Check; a
  sort and the measuring taps can't be missed (the hands make every move right), "Drag it higher." is a notice, not a miss; Mean and
  MAD write their record on two rows while the keys are up (73% / 55% → 75%). Least zooms: 85%, 82%, 78%, 78%, 76%, 88%; keys up 75%+.
  Shots e.g. `page-g6-dotplot-1 -hand p0=1,p1=2,p2=3`, `page-g6-mad-2 -numbers N=8,l0=14,v0=16,v1=19,v2=14,v3=19,v4=7,v5=6,v6=8,v7=7 -wrong -keypad`.
- Fix of 4 Nov: a net's side names stand with it from the tilt's first frame (`Solids.Label`s on their faces, folding up with them,
  `NetsLesson.standingNames`), and come back on the paper only once it lies flat again.
- **The instruction is never a cut-off sliver** (call of 4 Nov, app-wide, `WorkProblem.keysFraming`): with the keys up, when the
  instruction's rows aren't all on the screen, it's written just above the line being typed (as a miss is), or, while a miss shows
  there, left out; back on its rows when the keys go.

- **Kindergarten is live** (4 Nov; Core: `Curriculum.gradeK`, all 23 lessons in 5 chapters, only built chapters on the map; grade 0).
  Chapter 1, Count to 10, is built (Core: `CountingK` (`CountK`, `CountToTen` gk-count10, `OneMore` gk-onemore, `CompareGroups`
  k-compare, `CompareNumbers` gk-numcompare), `Spoken`, tests `CountingKTests`; App: `CountToTenLesson`, `OneMoreLesson`,
  `CompareGroupsLesson`, `CompareNumbersLesson`, their shared `CountingKitK` (`KK`: counters, the ten track, trains of cubes, the
  number row, the record's own box)). As the preview (`design/prototype/gradeK-ch1.html`), its words word for word.
  **Shared K–1 pieces:** *the voice* (`App/Voice.swift`): every instruction, miss line and Say line is spoken as it appears
  (`Listener`, tests too), an en-US voice (Ava/Samantha/Zoe, best quality the iPad has) at 0.86 × the default rate; the drawn
  speaker mark three squares left of the instruction (`ProblemLayout.Kind.voice`) says it again; Settings' Read aloud is on by
  itself for K and 1st grade (`AppSettings.readAloud`); `Spoken.text` says signs and money as a person does; debug builds log
  each line to Documents/voice.log (screenshots log only, `-voice` to speak). *The number row* (`KK.numberRow`): 0–10 in blocks
  under the record, the tapped number fills the record's box (a byHand step, no keyboard), red only when wrong.
  Departures: One more shows its last three trains and the new one on every step (the See too), not the whole stair (50%);
  the dots go up with the track rising first and then gliding onto it one by one (moved parts can now wait their `delay`);
  the How to plays index-0 numbers as every lesson's does. Least zooms: 83%, 77%, 77%, 92%. Shots e.g.
  `page-gk-count10-1 -numbers kind=0,n=7,lay=3,rows=4,p0=0,p1=2,p2=14,p3=6,p4=38,p5=21,p6=33 -wrong2`,
  `page-gk-onemore-0 -numbers n=6 -hand grab=1,m=4`, `page-k-compare-1 -numbers top=6,bottom=4,spread=1,shift=0 -hand grab=1,gx=2.5,goff=0,off=-1`.
- Kindergarten chapter 2, Shapes, is built (4 Nov; Core: `ShapesK` (`FlatShapes` k-shapes, `DrawShape` gk-draw, `Solids3K`
  k-solids, `WhereIsIt` gk-position, `PutShapes` gk-compose), tests `ShapesKTests`; App: `FlatShapesLesson`, `DrawShapesLesson`,
  `SolidShapesLesson`, `WhereIsItLesson`, `PutShapesLesson`, their shared `ShapesKitK` (`KS`: polygons, a side lit outside it, the
  stick laid on each side in turn, word blocks) and `SolidsKitK` (`SK`: a box, sphere, cylinder and cone with their things' lines,
  posed)). As the preview (`design/prototype/gradeK-ch2.html`), its words word for word; the preview's See lines that showed a
  moment are said with the next instruction ("One circle at each end. Tap rolls or slides.", "One shape. Tap its name.").
  **New shared pieces:** `Solids.Body` (a solid drawn as one mesh, each facet shaded by the way it faces; round outlines worked out
  from the view), `Solids.Play` (solids that move by themselves: a push, a turn), `PaperLesson.standHeld` (the paper follows a finger
  part way up; `dragPoint` reads the flat paper while it's held), `standDelay` (flat a moment before it first stands), `say(_:)` (what
  to do changes within a step: "Push it."), `Sketch.vias` (a part morphs through several shapes: the stick) and a `via` on a part
  already showing (Flat shapes' shape turns upright and back where it is).
  Departures, each to show at 75%: solids are 2 blocks across (cylinder and cone 3 tall), not 4 (55%); the flat one sits up or down
  the paper so it stands level with the solid (the +28° view drops what's to the right), so flat they're on a diagonal; the word
  blocks and the record go in a row over what stands; Where is it?'s floor is 3 squares a floor square (5 was 44%), its record beside
  the floor; Flat shapes' hexagon is 24 × 20, a circle 26 across, a triangle at most 27 tall, an upright square at most 26; Draw
  shapes' Start over and record beside the place; Put shapes together's 2 triangles make a 3-block square, its rectangles wait
  standing, the tray wraps at 13 blocks. "Drag it further up." is a notice, not a miss; a turned square or rectangle gets the stick,
  not the turn. Least zooms: 76%, 76%, 80%, 76%, 79%. Shots e.g. `page-k-shapes-2 -numbers shape=3,w=10,h=5,turn=-15 -wrong`,
  `page-gk-draw-0 -numbers kind=3 -tapsq 15,5,30,5,40,15`, `page-k-solids-0 -numbers shape=2,thing=0,turn=0,side=0 -drag 10,22,10,17 -hold`,
  `page-gk-position-0 -numbers gon=-1,gx=5,gy=0,k0=3,k1=2,kind=0,n=2,on0=-1,on1=-1,ref=0,tx=-1,ty=-1,who=1,word=4,x0=5,x1=0,y0=2,y1=3 -wrong`,
  `page-gk-compose-0 -numbers set=1 -drag 42,5,7,5 -hold`.
- Kindergarten chapter 3, Measure and sort, is built (4 Nov; Core: `MeasureK` (`LengthK` k-length, `Heavier` gk-heavier, `SortK`
  k-sort), tests `MeasureKTests`; App: `LengthLesson`, `HeavierLesson`, `SortLesson`, their shared `MeasureKitK` (`KM`: a thing as long
  as it is, sorting glyphs, a record line with its box in the middle, `KM.seeded` parts that start where they were)). As the preview
  (`design/prototype/gradeK-ch3.html`), its words word for word; See lines said with the next instruction ("Count what sticks out.
  Write how many stick out.", "Watch the balance. Tap the heavier one."; the same length's done line starts "They end at the same
  place."). **New shared piece:** `Sketch.swings` (a part's morph or glide swings on a loose spring, past and back, 1.6 s: the
  balance's beam, pans and what's on them). The number row can show some keys (`keys:`). Departures, to show at 75%: the taller kind
  is 2–6 cubes and 6 high with the raised one lifted (7 was 69%); the sort field is 9 × 2 blocks (7 × 3 was 69% with three rows
  under it); a sort's wrong tap shakes the thing (it swings in from a square aside) and outlines it red instead of the preview's
  sideways shake; the readout counts only while a finger holds something. Least zooms: 75%, 77%, 78%. Shots e.g.
  `page-k-length-2 -numbers top=0,bottom=2,a=7,b=4,shift=2,mover=1,tall=0 -wrong`, `page-gk-heavier-0 -numbers x=0,y=3 -drag 2.5,27.5,10,13.5 -then 1 -slow 5`
  (films the tip), `page-k-sort-3 -numbers by=0,K=3,n0=5,n1=3,n2=7,c0=0,…,c14=17 -wrong2`.
- Kindergarten chapter 4, Add and take away, is built (4 Nov; Core: `AddSubK` (`AddK` k-add, `TakeAwayK` k-sub, `StoryK` k-story,
  `BondsK` k-bonds, `MakeTenK` k-make10, `FactsToFive` gk-five), tests `AddSubKTests`; App: `AddLesson`, `TakeAwayLesson`,
  `StoryLesson`, `BondsLesson`, `MakeTenLesson`, `FiveLesson`, their shared `AddKitK` (`KA`: a cube or counter, striped for the second
  amount, numbered, crossed out; the dashed strip; the hop; a record line with its box anywhere; `KSlide`, the second train slid on
  right after the first, home again on a miss)). As the preview (`design/prototype/gradeK-ch4.html`), its words word for word.
  Departures: the story's first two sentences are its first instruction, said together (the preview read the first alone while the
  counters went on); a story that adds rises to the top once the striped ones are on (no hops there, so no empty band); "None left."
  is said with the write ("None left. Write how many are left."); Facts to 5's "Watch the hand." goes with the last line, as the hand
  shows the fact; Number bonds' parts' circles are 1½ blocks under the whole's and the train a block higher (69% → 77%); Facts to
  5's palm is a block tall (69% → 78%). A take that reaches its count is checked at once, so "That's 4 away. Take 3." can't come up
  (as Sort's taps; a tap in the strip puts one back); taps have no readout (only a held finger reads). Least zooms: 95%, 89%, 89%,
  77%, 77%, 78%. `-tapgap N` spaces `-tapsq`'s taps N seconds apart (each miss line is said; the voice log shows them). Shots e.g.
  `page-k-add-0 -numbers a=3,b=4 -drag 37.5,2.5,22.5,12.5 -hold`, `page-k-story-0 -numbers a=5,b=2,take=1,who=0,what=0,tale=0 -wrong`,
  `page-k-bonds-2 -numbers whole=5,part=2 -drag 20,17.5,30,17.5 -hold`, `page-gk-five-1 -numbers a=2,b=3,plus=1,mode=2`.
- Fixes of 4 Nov (chapter 2): Solid shapes' push sends the solid away from the flat shape; the die's dots are filled spots
  (`Solids.Body.spots`) in the edges' dark colour.
- Kindergarten chapter 5, Teens and tens, is built (4 Nov; the last chapter: all 23 K lessons and the Kindergarten test are on the map;
  Core: `TeensK` (`Numerals` the web's stroke shapes sampled evenly, `Count20K` k-count20, `WriteK` k-write, `TeenNumbersK` k-teens,
  `TensK` k-tens, `CountTo100` gk-count100), tests `TeensKTests`; App: `CountTwentyLesson`, `WriteNumbersLesson`, `TeenNumbersLesson`,
  `CountTensLesson`, `CountHundredLesson`, their shared `TeensKitK` (`KT`: ten frames, the number row grown to 20, picking keys, a
  numeral's band drawn as quads edge to edge so it's even round curves, the traced ink as plates with the line over them)). Chapter in
  the decimals' pink (call 5). **New shared piece: `DigitPad`** (0–9 and a rub-out, 3 × 3 squares a key, the lesson's Check two squares
  right of it via `blocksAt`; a key sets the box unchecked, Check keeps "chk" and checks; red until the next key starts it again), for
  1st grade too. As the preview (`design/prototype/gradeK-ch5.html`), its words word for word; See lines said with the next
  instruction ("Watch the 0. Write the number.", "None. None is 0. Tap the 0."). Departures: two frames' numeral keys 4 squares under
  them (74% → 75%); the ring's keys 1–20 five to a row beside it; taps have no readout (only a held finger reads: the make drag, the
  trace's "1 of 2"); the whole-chart see is the done step (the 3 rows glide down into the whole chart, the last column lights row by
  row) at 53% on the 11-inch iPad, under call 5's 66%: the chart alone is 50 squares tall (66% would need the words hidden while it
  shows). Least zooms: 83%, 75%, 84%, 76%, 53% (the see; its counting step 100%). Shots e.g.
  `page-k-count20-0 -numbers n=14,ring=0,off=0 -tapsq …`, `page-k-write-2 -numbers n=7 -path 35.6,0.6,38,0.6,40.5,0.6 -hold` (`-path`
  drags a finger through points: a trace), `page-k-teens-0 -numbers ones=6,make=1 -path 2.5,2.5,22.5,7.5,32.5,2.5,37.5,7.5`,
  `page-k-tens-1 -numbers rows=7 -tapsq 19.5,31.5,1.5,31.5 -block Check`, `page-gk-count100-0 -numbers kind=1,n=40,c0=50,c1=40,c2=30 -tapsq 10,22`.
- Kindergarten calls (4 Nov): the drawn digit pad's keys are 4 × 4 squares (80 pt at 100%, 60 pt at 75%), as the number row's
  are (5 × 4). Count to 100's see is the preview's: for that moment the words, record and blocks step aside and the camera frames
  the whole chart alone, tight (67%, was 53%), the last column lighting row by row; then the three rows come back with the last line
  and Next problem. Shared: `PaperLesson.alone(s)` (asked every frame; the clock stays awake while it's true, `BarsPage.wakers`).
- **1st grade is live** (4 Nov; Core: `Curriculum.grade1`, all 26 lessons in 6 chapters, only built chapters on the map; grade 1;
  read aloud and first chapter free as K). Chapter 1, Add and take away to 20, is built (Core: `AddSub1` (`G1` the number row's
  slips 0–20, `Add20` g1-add20, `MakeTen1` g1-ten, `Doubles1` g1-doubles, `Three1` g1-three, `Sub20` g1-sub20), tests
  `AddSub1Tests`; App: `Add20Lesson`, `MakeTen1Lesson`, `Doubles1Lesson`, `Three1Lesson`, `Sub20Lesson`, their shared `AddKit1` (`A1`:
  counters 3 × 3 solid/striped/dotted, rows of places, the line 0–20 three squares a step, hops with arrowheads, a record line with
  boxes anywhere, the number row 0–20 with 0 on the picture's left edge)). As the preview (`design/prototype/grade1-ch1.html`), its
  words word for word, the grey line folded into the instruction ("These two make 10, so add them first. Slide these two into the
  top row."). Departures: a story item's two sentences start its first instruction (written once, said with it) instead of over the
  picture; Add three numbers' record goes beside the twenty and its number row under it (75% with a story's two rows of words); its
  lit groups are ringed, not tinted (a tint under the counters flickers); the last group's counters land one after another but the
  running count isn't written while they land; Make a ten's slide past full isn't a miss (the row fills, the rest go back) and "The
  top row is full. That's 10." is said before the write's line; Doubles' slide and Make a ten's fill can't be missed (as the
  preview). Least zooms: 82%, 92%, 89%, 75%, 83%. Shots e.g. `page-g1-add20-1 -numbers a=3,b=9 -tapsq 3,10.5,30,10.5 -tapgap 2.6`,
  `page-g1-ten-0 -numbers a=8,b=5 -drag 13.5,5.5,24.5,1.5`, `page-g1-three-0 -numbers a=4,b=4,c=7,story=1`,
  `page-g1-sub20-0 -numbers a=14,b=6 -drag 42,6.5,33,6.5 -hold`, `bar-grade-open -grade 1`.
- 1st grade chapter 2, Equations and stories, is built (4 Nov; Core: `Equations1` (`Related1` g1-related, `Missing1` g1-missing,
  `Equal1` g1-equal, `Story1` g1-story, `More1` g1-more), tests `Equations1Tests`; App: `Related1Lesson`, `Missing1Lesson`,
  `Equal1Lesson`, `Story1Lesson`, `More1Lesson`, their shared `EqKit1` (`E1`: the whole outlined, brackets with their numbers, a
  dashed place (crossed once gone), the flag, True / False word blocks 10 × 4)). Fractions blue. As the preview
  (`design/prototype/grade1-ch2.html`), its words, slips and generators word for word. Departures: a story's (and How many more?'s)
  sentences start the first instruction (written once, said with it, as chapter 1's) instead of over the picture; True or
  false?'s equation is on the picture's top rows; the number row goes under the record (chapter 1's), not beside it; the True /
  False blocks are 4 squares tall like the keys; Add to take away labels the whole (12) at its end (grade1.md). `A1.record`
  returns its end column. `-partial` (screenshots) shows a chapter while it's being built. Least zooms: 89%, 83%, 90%, 86%, 89%.
  Shots e.g. `page-g1-related-0 -numbers c=12,a=8 -wrong`, `page-g1-missing-2 -numbers a=6,c=15,first=1`,
  `page-g1-equal-0 -numbers make=0,lt=1,l0=4,l1=1,rt=2,r0=9,r1=2 -drag 18.5,5.5,14,5.5`, `page-g1-equal-0 -numbers
  make=1,lt=1,l0=6,l1=2,rt=1,r0=-1,r1=3` (−1 is the box), `page-g1-story-0 -numbers kind=7,s=5,ch=4,e=9,thing=4,name=4 -tapsq
  16.5,2.5`, `page-g1-more-0 -numbers kind=2,big=9,small=5,bn=0,sn=1 -drag 13.5,6.5,22.5,6.5 -hold`.
- 1st grade chapter 3, Numbers to 120, is built (4 Nov; Core: `Numbers1` (`Num1`, `Count120` g1-count120 (count on and how many?),
  `TensOnes1` g1-tensones, `Compare1` g1-compare, `TenMore1` g1-tenmore), tests `Numbers1Tests`; App: `Count120Lesson`,
  `TensOnes1Lesson`, `Compare1Lesson`, `TenMore1Lesson`, their shared `NumKit1` (`N1`: the 120 chart a few rows at a time, numbers small
  or big with the tens lit and the ones underlined, a chart place as a box, the finger's walk so a quick drag never skips a place)).
  Decimals pink. As the preview (`design/prototype/grade1-ch3.html`), its words, slips and generators word for word; every number on the
  digit pad (now also a 3 × 4 grid, `DigitPad.Layout.grid`, Check a block under it; `chk:` and `most:` for two boxes and 5-digit slips
  like 10010). The grey lines folded in ("Same tens: 4 and 4. Look at the ones. Tap the number with more ones.", "Same tens, same ones.
  Tap the sign…", "No ones on their own. Write…"). Departures: Tens and ones' rows of ten touch (a square apart was 63%); Compare's
  numbers on rows 0–2 and the ones touch 9 tens (70% → 75%); the gap is 6 squares so the sign keys are 4 × 4; a skip is said when the
  finger lifts, not as it lands; How many?'s shading is the light tint (the strong one hid the counted rows' outlines); hints: a first
  miss rings the row or stacks, a second shows the number beside its row or rings the key. Least zooms: 85%, 76%, 75%, 96%.
  Shots e.g. `page-g1-count120-0 -numbers kind=0,s=97,m=6 -path 37.5,7.5,42.5,7.5,47.5,7.5,2.5,12.5 -hold`,
  `page-g1-count120-1 -numbers kind=1,n=113 -path 2.5,17.5,7.5,17.5 -hold`, `page-g1-tensones-0 -numbers n=34 -tapsq 15,1.5,6,10.5`,
  `page-g1-compare-1 -numbers a=43,b=47 -wrong`, `page-g1-tenmore-0 -numbers n=34,more=1 -drag 17.5,7.5,17.5,12.5 -hold`.

- 1st grade chapter 4, Adding and taking away tens, is built (4 Nov; Core: `Tens1` (`AddTens1` g1-addtens and g1-add100 (`spec100`),
  `SubTens1` g1-subtens), tests `Tens1Tests`; App: `AddTens1Lesson` (both adding lessons, `tensOnly`), `SubTens1Lesson`, their shared
  `TensKit1` (`T1`: a closed ten, a loose one in its place, the names line a | sign | b with the record going on after b, `T1.kinds` for a
  part's from/via shapes)). Whole-number purple. As the preview (`design/prototype/grade1-ch4.html`), its words, slips and generators word
  for word; the digit pad's grid where b stood (Take away: under the rows left, under the pile, or a row under all, whichever is shortest).
  Add within 100's full ones row: the carried ones land on the row (`via`), it's ringed a beat while what was there waits (`delay`), then
  the ten joins the tens and its inner lines draw in. Departures: Take away's counted rows aren't tinted (a tint under the counters
  flickers), only numbered at their end; the take can't be missed (a short slide goes back, as the preview). Hints: a first miss rings the
  tens, the ones row or the rows left; a second shows the dashed landing place, the ones to slide, the row to tap, or the number by the pad.
  Least zooms: 75%, 75%, 78%. Shots e.g. `page-g1-addtens-0 -numbers a=23,b=30 -drag 50,4.5,20,8.5 -hold`,
  `page-g1-add100-0 -numbers a=36,b=7 -drag 54.5,4.5,37.5,14.5 -slow 3` (films the close), `page-g1-add100-0 -numbers a=24,b=35 -drag 36.5,14.5,10,18`
  (ones before tens), `page-g1-subtens-1 -numbers a=70,b=30 -tapsq 15,4.5,15,7.5`, `page-g1-subtens-2 -numbers a=90,b=10`.
- 1st grade chapter 5, Length, time and graphs, is built (4 Nov; Core: `Length1` (`Len1` the things, themes and a pile's order,
  `Order1` g1-order3 with the go-between, `Cubes1` g1-measure, `Time1` g1-time, `PicGraph1` g1-picgraph, `Tally1` g1-tally), tests
  `Length1Tests`; App: `Order1Lesson`, `Cubes1Lesson`, `Time1Lesson`, `PicGraph1Lesson`, `Tally1Lesson`, their shared `LengthKit1` (`L5`: a
  thing as a plain bar, the rows' small pictures drawn from the preview's paths, tally marks)). Measurement amber. As the preview
  (`design/prototype/grade1-ch5.html`), its words, slips and generators word for word, the grey lines folded in ("Now the far ends tell.
  Drag them…", "These two are stuck. Lay the string…", "How many apples? Tap each picture to count it."). `Spoken` says a time as a
  person does ("8:30" is "half past 8", "3:00" is "3 o'clock"). Departures: a thing and its start are 12 blocks at most (the preview's 13
  showed at 73%); the go-between's string is 2 squares longer than the longer thing, not a block (its floor at 32, not 35); the time is
  written in two steps, the hour then the minutes (one box each, both "Write the time."), the pad's grid left of the clock; the hour
  strip's hours are under its ends, not beside them (74% → 76%); Together draws a picture in 3 squares past 10 joined, not 11 (71% →
  75%); a swap the wrong way is code 100 + 10 × longer + shorter. Hints: a first miss rings the start line, the far ends, the short
  hand, 12, the row or the marks; a second shows the dashed place, the number, the next picture or mark, or the number by the pad.
  Least zooms: 76%, 77%, 76%, 75%, 86%. Shots e.g. `page-g1-order3-1 -numbers between=0,n0=0,n1=1,n2=2,l0=7,l1=4,l2=9,s0=2,s1=3,s2=1
  -drag 5,23,5,6 -hold`, `page-g1-order3-2 -numbers between=1,n0=8,n1=9,l0=5,l1=3 -wrong`, `page-g1-measure-1 -numbers
  n0=0,n1=3,a=7,b=4 -drag 1,14.5,13,14.5 -hold`, `page-g1-time-1 -numbers hour=8,minute=30 -path 35,4.5,39,5,41,8,41,12,39,15 -hold`
  (`-showme -slow 3` films the ghost's trace), `page-g1-picgraph-0 -numbers theme=0,c0=8,c1=3,c2=5,ask=0,x=0,y=1,sort=1,seed=7 -tapsq
  3.5,23,7.5,23`, `page-g1-tally-0 -numbers theme=1,c0=12,c1=4,c2=9,ask=1,x=0,y=1 -tapsq 30,4.5`.
- 1st grade chapter 6, Shapes and equal parts, is built (4 Nov; the last chapter: all 26 lessons and the 1st grade test are on the map;
  Core: `Shapes1` (`WhatShape1` g1-shapes, `Compose1` g1-compose, `Build1` g1-build, `Halves1` g1-halves), tests `Shapes1Tests`; App:
  `WhatShape1Lesson`, `Compose1Lesson`, `Build1Lesson` (3D on `PaperStand`, as K's Where is it?), `Halves1Lesson`). Geometry teal. As the
  preview (`design/prototype/grade1-ch6.html`), its words, data and generators word for word; grey lines folded in ("There's a gap. Is it a
  triangle?", "That side is curved. Is it a triangle?", "Draw a different triangle. Tap the corners. Tap the first one again to close it.",
  "… Tap a piece to turn it." when a piece starts turned, "Fourths are also called quarters. Shade 3 fourths."). Time's minutes step now
  says "Write the minutes." Departures, each for 75%: Yes / No in a column beside the shape (where the patch comes), the record two
  squares under it with Next problem beside it; Compose's tray a block past the outline, rows wrap at 45 squares, Next beside the record;
  Build's tray at most 5 blocks wide, the record beside what stands when it fits (else under, Next beside it); Halves' names and record
  beside the shape for every shape; the compare kind's square and circle are 24 across (30 was 71%). Build: the pieces aren't drawn
  rising (seen straight down the flat paper shows their footprints; the tilt lifts them); a box built of pieces turns into one box at
  once (bodies have no fade); names stay under tray pieces while they wait. Hints: a first miss rings the shape, outline, ghost or
  blocks; a second shows the next side dashed, the places dashed, the piece's place in the chapter colour, the cut, or the right block.
  Least zooms: 76%, 75%, 76%, 77%. Shots e.g. `page-g1-shapes-0 -numbers kind=0,variant=0,miss=1,side=2,n=3,x0=0,y0=16,x1=20,y1=16,x2=8,y2=0
  -path 0,16,10,16,20,16,14,8,8,0,4,8,0,16 -hold`, `page-g1-compose-0 -numbers set=0 -drag 30,5,5,5`, `page-g1-compose-1 -numbers set=6,u1=1`,
  `page-g1-build-0 -numbers set=4,t0=0,t1=1 -wrong2`, `page-g1-build-0 -numbers set=4,t0=2,t1=1 -showme -slow 2`,
  `page-g1-halves-0 -numbers shape=0,parts=4,cut=0,shaded=3 -drag 15,1,15,23 -hold`, `page-g1-halves-1 -numbers compare=1,shape=1,hcut=2,fcut=2`,
  `map-fresh -grade 1 -whole`.
- **2nd grade is live** (4 Nov; Core: `Curriculum.grade2`, all 27 lessons in 7 chapters, only built chapters on the map; grade 2; read
  aloud on by default for 2nd grade too (`AppSettings.readAloud`, `Curriculum.voiced` ≤ 2); first chapter free as every grade's). Chapter 1,
  Adding and subtracting to 100, is built (Core: `AddSub2` (`G2`, `Facts2` g2-facts, `Regroup2` g2-regroup, `SubRegroup2` g2-subregroup,
  `AddFour2` g2-addfour, `Bars2`, `Story2` g2-story, `TwoStep2` g2-twostep), tests `AddSub2Tests`; App: `Facts2Lesson`, `Regroup2Lesson`,
  `SubRegroup2Lesson`, `AddFour2Lesson`, `Story2Lesson`, `TwoStep2Lesson`, their shared `AddKit2` (`A2`: 2 × 2 counters, a ten 20 × 2,
  the column form, a story on the picture's top rows with its numbers lit, the bars to 100)). As the preview
  (`design/prototype/grade2-ch1.html`), its words, slips and generators word for word; the preview types, so every answer is typed
  with the iPad's keys and Check. New shared pieces: `PaperLesson.told` (a story drawn on the picture's top rows is said before the
  first step's words, `WorkProblem.spokenText`), `PaperLesson.typedDemo` (Show me on a typed step plays a hand move first: Facts to
  20's way, then the answer written); `Spoken` says a lone ? as "question mark". Departures: Facts to 20 is one typed step whose
  picture the hands can also work (the box live from the start, as the preview), its notices ("The top row is full. That's 10.",
  "That's 9. Take 8 away.") said as the instruction; past 50 a story's numbers are all even (1 square is 2 things, said on its own
  row, so no bar ends mid-square); the preview's 8 + 7 is a near double by its own rule (|a − b| ≤ 1), so make a ten is tested on
  8 + 5; Ana's bar shows no number until "How many does Ana have?" is answered (the preview's gave it away); a tall stack under a
  story has its rows touching; a story's pick, Check and Next go beside its record line; checks use i4/i5/i6 where the spec says
  "i3" twice (i3 is always the story kind). Least zooms: 125%, 77%, 77%, 86%, 76%, 78%; keys up 75%+. Shots e.g.
  `page-g2-facts-0 -numbers a=8,b=5,kind=0 -drag 4.5,5.5,26,1.5`, `page-g2-regroup-1 -numbers a=47,b=38,story=0 -tapsq 5,16,5,13 -tapgap 2.5`,
  `page-g2-subregroup-0 -numbers a=52,b=27,story=1`, `page-g2-addfour-0 -numbers n=3,n0=27,n1=34,n2=16 -drag 26,10.5,8,11 -hold`,
  `page-g2-story-1 -numbers kind=9,W=46,p1=21,more=0,who=2,other=3,th=2`, `page-g2-twostep-2 -numbers kind=1,s=34,d=15,th=1`, `bar-grade-open -grade 2`.
- 2nd grade chapter 2, Numbers to 1000, is built (4 Nov; Core: `Numbers2` (`Num2` number names, `Hundreds2` g2-hundreds, `Skip2`
  g2-skip, `Compare2` g2-compare, `Within2` g2-within1000), tests `Numbers2Tests`; App: `Hundreds2Lesson`, `Skip2Lesson`, `Compare2Lesson`,
  `Within2Lesson`, their shared `NumKit2` (`N2`: base-ten pieces, a tight number drawn a digit at a time with one ringed tall and narrow,
  Rounding's lines)). Pink. As the preview (`design/prototype/grade2-ch2.html`), its words, slips and generators word for word; typed with
  the iPad's keys. Departures: the number is written once in the record (under the tens and ones) from the start, its digit being built
  ringed and its column's name lit, not over the columns (nine hundreds were 68%); a number told in words is written there in words
  and said as the problem opens (`told`), not on the top rows; seven or more hundreds' flats touch row to row; the tenth ten (or one)
  slides into a hundred and stays until the next tap; Skip counting's note after a hundred ("10 tens make a hundred…") goes with the
  next hop's line, and not for hops of 100; Compare's sign blocks are drawn 3 × 4 under the record and answer on the tap; Within 1000's
  three hops are written in one row under the lines, the sum 5 rows under them (so a miss with the keys up has its rows clear). Skip
  counting and Within 1000 draw their lines in the record pen (recordRow 0) or picture so keys-up misses land clear (see each file).
  `Spoken` says "<, = or >" as "less than, equals or greater than". Least zooms: 76%, 95%, 76%, 76%; keys up 75%. Shots e.g.
  `page-g2-hundreds-1 -numbers n=347,named=0,mix=1 -wrong`, `page-g2-hundreds-4 -numbers n=605,named=2,mix=3 -wrong`,
  `page-g2-skip-0 -numbers start=15,by=5,back=0 -drag 0,7,6,7 -hold`, `page-g2-compare-2 -numbers a=427,b=461 -wrong`,
  `page-g2-within1000-1 -numbers a=245,b=132,sub=0 -drag 13.5,12,22.5,12 -hold`, `select-g2-hundreds -grade 2`.
- 2nd grade chapter 3, Equal groups, is built (4 Nov; Core: `Groups2` (`Groups2` shared lines, `EvenOdd2` g2-evenodd, `Arrays2` g2-arrays,
  `Squares2` g2-squares), tests `Groups2Tests`; App: `EvenOdd2Lesson`, `Arrays2Lesson`, `Squares2Lesson`, their shared `GroupsKit2` (`EG2`:
  a grid of blocks, "Tap each row" by tap or sweep with its numbers at the left, the readout, the running totals, `4 + 4 + 4 = [ ]`)). Blue.
  As the preview (`design/prototype/grade2-ch3.html`), its words, slips and generators word for word; typed with the iPad's keys.
  Even and odd: tap each dot (or drag across): it glides into the pair frame, pairs ring, "2, 4 … 12" then "6 pairs and 1"; the frame
  glides up; even/odd are word blocks under it answered on the tap (red when wrong, as Compare's signs); `13 = [ ] + [ ] + 1`.
  Arrays: tap each row, count one row ("4 in a row"), `4 + 4 + 4 = [ ]` with Check beside, totals at the rows' ends; the muffin story.
  Rows and columns of squares: drag down the left side (or along the top) to cut, the cuts dash and snap to equal pieces, Cut; the
  checker; tap each row; `4 + 4 + 4 = [ ] squares` with Check under it. Departures: the arrays and the rectangle start a block in (room
  for the rows' numbers and the handle); the top cut's handle, hint and dashes sit inside the rectangle's top (clear of a miss line);
  the number is written in the record from the write step (it doesn't glide there: words don't morph); a lit row's band replaces its
  checker tiles while tapped, and an array's dots are plates while bands show (two fills over each other z-fight); a story of 5 rows
  has its record 2 rows under (76%); checks use i4/i5 where the spec says i3 twice (i3 is the story); Squares' Check goes under the
  record (beside it the keys covered it). Least zooms: 110%, 76%, 75%; keys up 87%, 76%, 75%. Shots e.g.
  `page-g2-evenodd-0 -numbers n=13,mix=4 -showme -pause 2 -slow 1.5`, `page-g2-evenodd-1 -numbers n=13,mix=4 -wrong`,
  `page-g2-arrays-1 -numbers rows=3,cols=4,story=0 -tapsq 7.5,7.5,12.5,7.5 -tapgap 1`, `page-g2-squares-0 -numbers rows=3,cols=4,first=1 -drag 4,1,4,5.5 -hold`.
- 2nd grade chapter 4, Length, is built (4 Nov; Core: `Length2` (`Len2` units, a hop's code from × 1000 + to, `Measure2` g2-measure,
  `TwoUnits2` g2-twounits, `Estimate2` g2-estimate, `Numline2` g2-numline), tests `Length2Tests`; App: `Measure2Lesson`, `TwoUnits2Lesson`,
  `Estimate2Lesson`, `Numline2Lesson`, their shared `LengthKit2` (`LN2`: the ruler, the preview's things, the measuring pieces, Hop along a
  ruler: a drag from a mark lays hops a unit at a time, a hop that stops short is kept and a drag from its end goes on; held hops in the live
  pen, the readout beside the ruler and in the bar)). Amber. As the preview (`design/prototype/grade2-ch4.html`), its words, slips and
  generators word for word; typed with the iPad's keys. `Spoken` says a unit after a number ("7 cm" is "7 centimeters", "4 in a row" stays).
  Departures: Estimate's laid clips or cubes stay under the thing while it's measured (the ruler 2 rows lower so the hops clear them), not
  gone as the ruler comes; its guesses sit just under the thing (not where the record goes); a wrong guess's dashed line stops just past the
  ruler (24 inches drawn whole was 120 squares); the number line's story is on the picture's top rows with the instruction above it (as
  chapter 1's stories); past 50 every story number is even (G's call: a square is 2). Least zooms: 90%, 77%, 79%, 80%; keys up 75%+ (Inches
  and centimeters' long ruler is cut at the keys' edge, its record line in full). Shots e.g. `page-g2-measure-0 -numbers unit=1,th=0,start=2,end=9
  -drag 4,3.5,14,3.5 -hold`, `page-g2-twounits-4 -numbers inches=8 -wrong`, `page-g2-estimate-1 -numbers fold=1,u=0,thing=2,len=7 -drag
  0,9.5,30,9.5 -hold`, `page-g2-numline-1 -numbers kind=1,a=45,b=18,th=0,who=0,other=1 -showme -slow 1.5`.
- 2nd grade chapter 5, Data, is built (4 Nov; Core: `Data2` (`MakeGraph2` g2-makegraph, `BarGraph2` g2-bargraph, `LinePlot2` g2-lineplot),
  tests `Data2Tests`; App: `MakeGraph2Lesson`, `BarGraph2Lesson`, `LinePlot2Lesson`, their shared `DataKit2` (`DK2`: tally marks a square
  apart, 3 tall, a bundle a block wide; bars a block a vote with a line between blocks; the scale; an X in its cell; the readout at the
  title row's right end); five more row pictures in `L5.shapes` (pear, bird, wind, cookie, paint)). Pink. As the preview
  (`design/prototype/grade2-ch5.html`), its words, slips and generators word for word; typed with the iPad's keys. Make a graph: tap to
  add the pictures (a tap past the tally shows the extra picture red until the next touch) or drag each bar's end, any order, a tick
  once a row's made; `7 + 4 + 6 + 3 = [20] in all`; the missing row's story is said with each line as the preview's ("20 children
  voted. Drag the pears bar."), `20 − 17 = [3]`. Bar graphs: drop a line (grab the graph, the bar under the finger lights, the dashed
  line lands on the scale), hop the part sticking out or tap to count on along the second bar; the question on the top rows (`told`).
  Line plots: place an X (dragged from its holder; it glides from where it's let go, `KM.seeded`), tap a stack to count, tap the
  tallest, hop under the line. Departures: Make a graph's tally chart sits beside the graph (each row's picture, name and marks at its
  left) instead of over it, and its readout is at the title row's right end (on top it was 69%); the line plot's fold plots on the inch
  ruler itself (the X's stack on its top edge, the five things lie under it from 0, the ruler's marks hang down to them) instead of a
  second line under the ruler (72%); Bar graphs' hops are lower (0.5) so they stay under the title. Hints: a first miss rings the row,
  the bar, the part sticking out, the stack or the line; a second rings the block, the scale number, the mark or the next X, or writes
  the number by the box. Least zooms: 78%, 76%, 78% (keys up too). Shots e.g. `page-g2-makegraph-0 -numbers
  kind=0,theme=0,c0=4,c1=2,c2=5,c3=3 -tapsq 22.5,7,27.5,7,22.5,12 -tapgap 1.2`, `page-g2-makegraph-0 -numbers
  kind=2,theme=1,c0=5,c1=3,c2=6,c3=2,mx=2 -wrong2`, `page-g2-bargraph-0 -numbers theme=0,v0=7,v1=4,v2=5,v3=2,x=0,y=1,kind=0 -drag 44,8,44,21
  -hold`, `page-g2-lineplot-0 -numbers thing=1,lo=3,n=5,d0=3,d1=5,d2=5,d3=7,d4=8,fold=1,p0=0,p1=1,p2=0,p3=0,p4=1 -wrong2`,
  `page-g2-lineplot-0 -numbers thing=0,lo=4,n=8,d0=4,d1=5,d2=5,d3=6,d4=6,d5=6,d6=7,d7=8,ask=0,v=6 -showme -pause 2 -slow 2`.
- 2nd grade chapter 6, Time and money, is built (4 Nov; Core: `TimeMoney2` (`TM2` coins, groups, the dollar square's cells, `Time5`
  g2-time5, `Coins2` g2-coins, `Money2` g2-money, `Dollars2` g2-dollars), tests `TimeMoney2Tests`; App: `Time5Lesson`, `Coins2Lesson`,
  `Money2Lesson` (with `SlideIn`, the slide-in-and-count kit Dollars' bills use too), `Dollars2Lesson`, their shared `TimeMoneyKit2` (`TMK`:
  coins in their own faint colours, penny copper (call of 3 Nov), only what shows past the coin over each in a fanned row; a cent, crossed
  out when spent; the dollar square; bills)). Amber. As the preview (`design/prototype/grade2-ch6.html`), its words, slips and generators
  word for word; typed with the iPad's keys. A time of day ("School ends.") and a story ("Ben has 65¢.") start every line, as the
  preview's one-row header. `Spoken` says 3:05 as "3 oh 5", a.m./p.m., $27 as "27 dollars", a $5 bill as "a 5 dollar bill", $1.35 as
  "1 dollar and 35 cents". Time: tap the hour, trace from 12 (the face shades a number at a time, 5, 10 … outside the edge, the strip a
  square for 5 minutes), write [3]:[25]; a.m./p.m. picked, then the day strip; or turn the long hand to a written time. Coins: tap its
  name (its edge traces), `A dime is [10]¢`, its cents beside it; the pair, tap the one worth more. Money: slide each kind into the
  square (its cents pour from where it's let go), write each running total. Dollars: bills into the dollar chart the same way; fill a
  dollar by tapping, slide a price tag over the cents (crossed out), slide the second amount's coins in. Departures: Money's and the
  bills' running totals are written down the target's right side (along a row under the square showed at 70%); the stories' record is
  left of the square under the readout, for the same reason; the first amount's cents glide in from the left as the picture draws (its
  coins aren't drawn first); a pair's quarter shows its 25 cents in rows of ten (five rows was 68%); the pair's name blocks sit 2 rows
  lower so the names written under the coins clear them. Hints: a first miss rings the short hand, 12, the strip, the picks, the coin,
  the kind to slide, the tag or the square; a second the hour, the long hand's number, the right name block or coin, the target, or
  the answer by the box. Least zooms: 76%, 79%, 82%, 76%; keys up 75%. Shots e.g. `page-g2-time5-1 -numbers kind=0,hour=3,minute=25
  -path 15,8,19.2,9.8,21,14,19.2,18.2,18,19.2 -hold`, `page-g2-time5-3 -numbers kind=1,hour=2,minute=15,e=5 -wrong`, `page-g2-time5-0
  -numbers kind=2,hour=3,minute=25 -wrong`, `page-g2-coins-2 -numbers kind=1,coin=1,other=2 -wrong`, `page-g2-money-0 -numbers
  q=2,d=1,n=1,p=3 -drag 4,4,33,13 -hold` (`page-g2-money-2 … -showme -slow 1.5` filmed), `page-g2-dollars-0 -numbers kind=0,b10=2,b5=1,b1=2
  -wrong`, `page-g2-dollars-0 -numbers kind=2,who=0,A=45,p=30,item=0 -drag 5,12,32,22 -hold`.
- 2nd grade chapter 7, Shapes, is built (4 Nov; the last chapter: all 27 lessons and the 2nd grade test are on the map; Core: `Shapes2`
  (`Sides2` g2-shapes, `Solids2` g2-solids, `Shares2` g2-shares), tests `Shapes2Tests`; App: `Sides2Lesson`, `Solids2Lesson` (3D on
  `PaperStand`), `Shares2Lesson`). Teal. As the preview (`design/prototype/grade2-ch7.html`), its words, slips and generators word for word;
  the one number written (`[3] thirds make 1 whole`) typed with the iPad's keys. Sides and corners: tap each corner or trace each side (they
  light and count, `5 corners · 5 sides`), Check; tap its name (a square or rectangle "is a quadrilateral too", `Sides2.pickCode`); draw
  one in a 30 × 22 dashed patch (tap the first corner to close, drag a corner to fix a cross). Faces, edges and corners: the base flat, drag
  the paper up and the solid rises from it (`Solids.Play`), true 3D faces through the long lens; turn it with a finger (7° a square,
  snapping to 15°); hidden edges dashed and counted edges, numbers and dots drawn on the board (it's nearer the eye, so over the solid);
  its Check and names are its own blocks on the board (the layout's lesson blocks don't show while the paper stands); Show me taps what
  shows, then turns it to where most of the rest shows, until all are counted (the shots' How to loops until a problem is solved, so
  every step's demo must solve it). Halves, thirds and fourths: cut with the ruler (`Shares2.snap`, `cutting`: codes for every miss line),
  the parts number and glide onto the first; Same size? cuts a part into pieces that slide onto the other copy's (`dissect`).
  Departures: the square is 24 a side and the circle 30 across (the design's 36 showed at 65–71%); the solid turns over at most a
  quarter turn each way (the preview half), its readout, Check and names beside it (under it showed at 70%); the name slips take two
  rows. Hints: a first miss rings the shape, patch, solid, names or picture; a second the next uncounted corner, an example shape dashed,
  the next face/edge/corner that shows, the right name, the cuts dashed, the next part to shade, or the number by the box. Least zooms:
  78%, 76%, 78%; keys up 75%. Shots e.g. `page-g2-shapes-0 -partial -numbers kind=0,n=5,variant=0,x0=12,y0=0,x1=25,y1=9,x2=20,y2=22,x3=4,
  y3=22,x4=0,y4=9 -tapsq 12,0,25,9`, `page-g2-shapes-0 -numbers kind=1,n=5 -wrong2`, `page-g2-solids-1 -numbers solid=1,turn=2 -wrong`,
  `page-g2-solids-1 -numbers solid=1,turn=0 -drag 15,10,28,10 -hold` (a turn held), `page-g2-shares-0 -numbers shape=0,parts=3,cut=0,
  shaded=2,other=-1 -drag 16,1,16,23 -hold` (`-showme -pause 2 -slow 1.5` filmed), `page-g2-shares-1 -numbers shape=1,parts=4,cut=0,
  shaded=1,other=2` (the slide), `map-started -grade 2 -whole`.
- A ¢ after an answer box hugs it, as a letter does (`M7.hugs`, shared: Name the coin, Counting money, Dollars and cents).
- Taps (4 Nov, shared): a finger that slips under 12 pt as it taps is one tap (`PaperModel.slip`, `fingerTap`, `cancelGrab`). Before, such
  a tap started a drag: on nothing grabbable it panned the paper (the tap lost once the slip passed the system tap's ~10 pt, and the pan
  coasted, so the next tap only stopped the paper); on a grabbable piece (Hundreds' last ten) the release and the tap both counted.
  Clean real taps (XCUITest, 1 s and 0.35 s apart) always counted. Show me's kept moves now redraw the picture (the still key reads the
  ghost's run), so dots counted by the ghost glide in.
- 1st grade Build with solids (4 Nov): Show me filmed, it plays all three pieces and puts everything back; the ghost solid's dashed
  rims and edges draw only once the paper is up (`Solids.Line.whenUp`).
- **3rd grade is live** (4 Nov; Core: `Curriculum.grade3`, all 28 lessons in 7 chapters, only built chapters on the map; grade 3; not
  read aloud (`Curriculum.voiced` stays ≤ 2)). Chapter 1, Multiply and divide, is built (Core: `MultDiv3` (`G3` cells and caps, `Facts3`
  g3-facts, `DivFacts3` g3-divfacts, `Unknown3` g3-unknown, `TwoStep3` g3-twostep), tests `MultDiv3Tests`; App: `Facts3Lesson`,
  `DivFacts3Lesson` (its rows and share hands shared with Two-step), `Unknown3Lesson`, `TwoStep3Lesson`, their shared `MultKit3` (`M3`:
  arrays of dots in cells, brackets with names, the open edge to drag, rows counted, name boxes)). As the preview
  (`design/prototype/grade3-ch1.html`), its words, slips and generators word for word; typed with the iPad's keys. New hand move: *turn a
  quarter* (grab a corner, the array follows the finger round its middle, lands via `Sketch.lifted(from:via:)`: swing to the quarter,
  slide home). Departures, to show at 75%: a cell is 5 squares up to 5 a side, 4 up to 7, else 3 (the preview's 5 up to 6, 4 up to 8 made
  32-square arrays), arrays start 3 rows down; a drag past the answer isn't given room in the frame (it may run under the bar); the turn's
  arrow sits above-right of its corner; a half turn is a miss ("That's a half turn: still 4 rows of 6. Stop at a quarter turn."), short of
  a quarter it swings back as the preview's; Division facts writes its record where the emptied pile was; Two-step's story is on the
  picture's top rows (2nd grade's), its cell is the biggest of 5–2 squares that fits (sharing: 3 or 2), and "then more" extras that would
  make the packs too tall wait in a column of their own beside them; facts and division have no story kind (the preview has none), so
  their checks' "i3 story" are plain i3. Least zooms: 75%, 75%, 75%, 76%; keys up 75%+. Shots e.g. `page-g3-facts-0 -numbers a=4,b=6
  -drag 17.5,8,17.5,18 -hold`, `page-g3-facts-2 -numbers a=4,b=6 -showme -pause 2 -slow 1.5`, `page-g3-divfacts-0 -numbers b=4,q=6 -wrong2`,
  `page-g3-unknown-1 -numbers a=8,b=6,form=2,flip=1 -wrong2`, `page-g3-twostep-2 -numbers kind=0,a=4,b=6,c=5,who=0 -wrong2`,
  `page-g3-twostep-4 -numbers kind=1,a=9,b=3,c=20,who=2`, `map-started -grade 3`.
- 3rd grade chapter 2, Times-table tricks, is built (4 Nov; Core: `Tricks3` (`Split3` g3-split, `Three3` g3-three, `Double3` g3-double,
  `Tens3` g3-mult10), tests `Tricks3Tests`; App: `Split3Lesson`, `Three3Lesson`, `Double3Lesson`, `Tens3Lesson`, their shared `TricksKit3`
  (`T3`: an array cut in two whose second part glides, the ruler on a stem that snaps between things, a 2-square pick block)). As the
  preview (`design/prototype/grade3-ch2.html`), its words, slips and generators word for word; typed with the iPad's keys. Departures:
  cells are the biggest of 5/4/3 squares that fit (Breaking apart a·c ≤ 27, b·c ≤ 30; Double a fact 28 a side; the design's 4 made 8 × 9
  32 tall); Three's pick and its later words, answers and slips follow the pair tapped (kept "pick", `say(_:)`, `expectKept`), its record
  starts level with the picture (recordRow 0) and Check stands beside the line; Double a fact always keeps its record beside (Even and
  Odd are drawn with the record but tapped in the picture's squares); Multiples of 10 has no timed fold step: the fact's right answer
  folds the tens (frames glide into hundreds in rows of four a square apart, the tens left over start the next hundred) and the next
  instruction reads "Ten tens make a hundred. Write 4 × 30." (no break inside 4 × 30), and its product is written `= [120]` under the
  line's = (one line made 9 × 90 too wide). Least zooms: 75%, 77%, 82%, 77%. Shots e.g. `page-g3-split-0 -partial -numbers a=7,b=8 -drag
  29,0,20,0 -hold`, `page-g3-three-0 -numbers a=3,b=5,c=2 -tapsq 1,1`, `page-g3-double-0 -numbers h=2,n=7 -drag 36,19,36,11 -hold`,
  `page-g3-double-3 -numbers h=2,n=7 -wrong`, `page-g3-mult10-0 -numbers a=4,t=30 -drag 12.5,5,12.5,14 -hold`, `select-g3-split -grade 3`.
  Multiplication facts' turn: its grab (3 squares round any corner) is where the corner is drawn; a held drag from the drawn corner
  (`page-g3-facts-2 -numbers a=4,b=6 -drag 29,19,22,24 -hold`, the cell 4 since 5 a side) grabs and turns.
- 3rd grade chapter 3, Place value, is built (4 Nov; Core: `Place3` (`P3` place names, rounding to hundreds, the web's jumps and
  generator, `Round3` g3-round, `AddSub3` g3-addsub, `Estimate3` g3-estimate), tests `Place3Tests`; App: `Round3Lesson`, `AddSub3Lesson`,
  `Estimate3Lesson`). Pink. As the preview (`design/prototype/grade3-ch3.html`), its words, slips and generators word for word; typed
  with the iPad's keys; the preview's grey lines folded into the instruction (a story's pick: "A farm has 503 apples. … Pick what to
  do."; Leo's answer on the first and the Yes/No steps: "Leo says 458 + 275 = 633. Drag each number to its nearest hundred."). Rounding:
  tap the block, it opens into line 2; drag the point (brackets "7 to 340 · 3 to 350"), the hop to the closer end; `347 ≈ [350]`, the
  place's digit underlined, the next ringed, the rule beside. Add and subtract: the place chart (3-square disks that say their worth,
  2 frames a column), a place at a time biggest first (`AddSub3.Phase`: pick, slide, close, write, done; `Parts.plan` the opens and
  closes, a cascade closes twice); taking away with too few, the instruction becomes "Open a hundred: tap one." (`say`), the tapped
  disk's ten glide out of it (they're stacked under it from the start, `Board.toOpen`); a full ten's disks glide together into the
  next column; one record line per place, Check beside it (`blocksAt`). Estimate: drag both points, hop, write; Leo's point drops onto
  the line (`Sketch.from`), the band and the gap bracket draw in after it; Yes and No are drawn blocks answered on the tap. Departures:
  b's number beside its disks is written tight (call 1), each digit greying alone; the chart's rows a square closer than the preview's
  (73% → 76% with a 3-jump story); no live column-digit preview beside the readout except the held column's; hint rings over a line
  sit a square above it, clear of its numbers; checks at i4/i5/i6 + i3 (story) for Add and subtract (every i3 is a story). Least zooms:
  90%, 76%, 102%; keys up 75%. Shots e.g. `page-g3-round-1 -numbers n=347,to=10 -drag 33.5,14,45,14 -hold`, `page-g3-addsub-1 -numbers
  a=503,b=7,s=-1,story=1 -tapsq 13.5,4.5,33.5,7.5 -tapgap 1.5`, `page-g3-addsub-6 -numbers a=835,b=178,s=-1,story=1 -wrong -keypad`,
  `page-g3-estimate-3 -numbers a=458,b=275,s=1,f=633,who=0 -wrong`.
- Keys-up miss lines (4 Nov, app-wide, `WorkProblem.keysFraming`): written above the line being typed, they now steer clear of the
  picture's drawn pieces as well as its words (nothing is written over the picture); if climbing past them would drop the line's
  frame under 75%, the miss goes in the first clear rows under the line (Check included) instead. Checked on Multiples of 10
  (`page-g3-mult10-2 -numbers a=9,t=90 -wrong -keypad`, 75%), Multiplying decimals (`page-g6-decmult-2 … -wrong -keypad`) and Add and
  subtract within 1000.
- 3rd grade chapter 4, Shapes and area, is built (4 Nov; Core: `Shapes3` (`S3`, `Quads3` g3-quads, `Area3` g3-area, `LShape3` g3-lshape,
  `Perim3` g3-perim, `PerimArea3` g3-perimarea), tests `Shapes3Tests`; App: `Quads3Lesson`, `Area3Lesson`, `LShape3Lesson`, `Perim3Lesson`,
  `PerimArea3Lesson`, their shared `ShapesKit3` (`S3P`: tiles a square each, the fence's ticks, word lines)). As the preview
  (`design/prototype/grade3-ch4.html`), its words, slips and generators word for word; typed with the iPad's keys; the grey lines folded
  into the first instruction ("A rug is 7 ft by 4 ft. Drag across the top row to tile it.", "Trace around the edge. 1 cm is 3 squares.").
  **Fixed 4 Nov (lead's call): a square unit is a tile of 5, 4 or 3 squares**, the biggest that keeps the whole problem at 75%
  (`G3.cell(_:_:within:)`, chapter 1–2's rule, now shared; each lesson's `room` the picture may fill with its record beside or under it),
  as the preview; the one-square-a-unit call left a 9 × 6 rug 9 × 6 tiny squares. Under 5 the first line says "1 tile is 3 × 3 squares
  here." (Same perimeter's fence: "1 square m is …"). Side names and row counts are words size; each count sits at its tile row's middle;
  rulers, edges, hint rings, ticks and records follow the tile. Perimeter's cm is 5, 4 or 3 squares (2 only when 3 won't fit at 75%),
  given lengths words size, the walked "7 cm, like the top" small. Areas and L-shapes may write their record beside the picture. Quadrilaterals: tap sides (a tap inside or a side again is a notice, not a miss), square
  corners (a wrong one lays the paper corner red; Done), measure (a strip of squares along the side), Yes/No, two sides that never meet
  (they run on dashed; parallel ones arrowed, others measured closing in with drops; No more), the name (six blocks), also; make one (drag a
  corner; a shape that breaks snaps back as a miss; Done keeps the made shape, "made"); the picks and the record are in the picture's squares
  beside it (`recordRow` 0). L-shapes: two rulers (down over the top, across off the right), the cut kept ("ax") so the parts' words and
  answers follow it (`S3.typedKept`). Perimeter: the walk snaps a cm at a time along this side and round the next corner; the upright sides' "7 cm, like the top" go on two rows. Same perimeter: the missing side starts at 2 rows
  when the answer is 1 (the preview started on the answer). Departures: the area's last row count joins once it's written (as
  Multiplication facts), Perimeter's boxes are 3 digits (a slip of 150 fits). Least zooms (after the fix): Quadrilaterals 76%, Area 77%, L-shapes 75%, Perimeter 75%, Same perimeter 77%; keys up 75%+. Shots e.g.
  `page-g3-quads-4 -numbers shape=4,x0=5,y0=0,x1=25,y1=0,x2=30,y2=12,x3=0,y3=12,warm=1 -wrong`, `page-g3-quads-0 -numbers shape=0,make=1
  -drag 25,23,31,23 -hold`, `page-g3-area-1 -numbers l=9,w=6,unit=3 -drag 18.5,6,18.5,15 -hold`, `page-g3-lshape-0 -numbers W=8,H=6,w=3,h=2
  -drag 5,1,25,1 -hold`, `page-g3-perim-0 -numbers kind=0,a=7,b=4 -path 10,2,24,2,38,2,38,10 -hold`, `page-g3-perimarea-0 -numbers
  kind=1,P=16,q=3,sp=7,sq=1 -drag 40,8,35,13 -hold`. Map pictures for all five; Place value's Estimate (two big hops to a ringed estimate) and
  Add and subtract (bigger disks) redrawn.

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
