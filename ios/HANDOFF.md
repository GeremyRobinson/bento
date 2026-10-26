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

## Next (G agreed: cheaper settings — two lanes, high effort, no separate review step)
1. Sounds (gentle, made in code), VoiceOver over the paper, the idle-CPU fix (the clock runs at 60 fps while a number
   is wanted), removing dead code (old AddFractionsModel/BarsDrawer, old Unit cubes path if unused).
2. A dark-mode pass and one walkthrough of every lesson, fixing the rough edges above and what G finds by hand.
3. Then the other grades: take each web lesson's maths as it is (generators, mistakes, check recipes, stories) and
   design its steps fresh for paper (CLAUDE.md).
- Branding (icon, name) is G's, later; the app may be renamed, so don't write its name anywhere new.

## Working notes (what went wrong, so it doesn't again)
- At most 2–3 simulators at once (five booted overloaded the Mac for hours); `shoot.sh` quits the app after each shot.
- Ultracode/max effort burned most of a week's tokens; work at high effort, one review at most, merge as pieces land.
- Show G progress as it happens (screenshots in a Desktop folder; G can't open scratchpad paths).
- Worktrees `/Users/geremy/Claude/bento-work/lane-a…d` and worker simulators "Obento Worker 1–4" are from the last
  batch; all their work is merged, so they can be reused or removed (`git worktree remove`).
