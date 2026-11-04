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
- The refined call 1 (3 Nov): a line's numbers and signs take the fewest whole squares they fit, centred, so gaps are
  even (`Record.width`, `Record.opWidth`, `F4.Tok`); a number typed into a box in a line is written tight, right-aligned
  with room for the cursor, the box the fewest whole squares that fit (`WorkBox.word`, `Record.boxWidth`). Boxes in
  column working (and 5th grade's, whose lines are written two squares a digit) keep a digit to a cell.
- Chapter 2 zooms (3 Nov): Multiply big numbers past 7 rows puts its record a row closer and the sum's rule right under
  the parts (73% → 76%); Story problems with narrow bars put the record beside them (73% → 76%).

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
