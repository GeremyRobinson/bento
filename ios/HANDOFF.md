# Handoff: 5th grade lessons (19 Oct 2026)

For the next session taking over from this one. Read `CLAUDE.md` first: its G's rules (1)–(14) from 19 Oct are firm.

## Where things stand
- **Approved by G:** the lesson flow (How to → page of problems → one problem open, filling the screen), drawing in
  and undrawing everything, the grid rules, three text sizes, one line weight (1.5), and Multiply two-digit numbers
  answered *in its school working* (the box where the number goes, what to do beside it, Check under the work).
- **Built the same way, not yet reviewed:** Long division (the box in the division bracket).
- **Not working for G:** the other 15 lessons. They still show the problem, a picture, a separate answer line and a
  separate sum. G finds them confusing: too many parts, the problem written more than once, no clear place to look.
  A quick attempt to move them all at once onto a generic "worked down in lines" layout made them worse and was
  undone (never pushed).

## 20 Oct: one design per lesson (read `design/README.md`)
- G: lessons can't be fitted into one layout; each lesson is designed for its own scenarios. The plan, the order (by
  kit) and all 191 lessons' pictures and working are in `design/`. Every lesson gets a brief there before code.
- **Adding fractions** (`design/add.md`) is built that way: bars and the working on the same rows, answered in the
  working, its own steps (rewrites that change nothing and simplify with nothing to do are left out). `sub` and `mix`
  share it. G approved it on 20 Oct ("this works"). Next kit: number line (Rounding decimals).

## How to work with G (what went wrong)
- One lesson at a time. Before writing code, show G a sketch of that lesson's screen (a text mock-up in chat was
  what G liked for Multiply) and build only once G says yes.
- Each lesson needs its own design: the school working it's answered in (the decimal columns, the fractions rewritten
  over one bottom, the order-of-operations lines…), with the problem written once, the box where the number goes,
  and nothing repeated between the picture and the working.
- Check every change on the simulator at full size before saying it's done; G spots alignment and size slips fast.

## The systems (so nothing is placed by hand)
- `App/Components.swift`: word styles (`Sketch.maths` 36, `wordSize` 28, `small` 20), `Sketch.stroke` (1.5), blocks,
  tabs, frames.
- `App/Grid.swift` (`GridPen`): pictures built in squares, labels half a square from what they label.
- `App/ProblemGrid.swift`: lays a problem out (picture and work as pieces on block lines, the arrangement that fits
  the iPad best). `showSections` draws dashed boxes round each part while testing.
- `App/LessonPictures.swift`: each lesson's picture and work; `drawing(id, numbers, keys)` returns them, with
  `box` set for a lesson answered in its work (`multiplyGrid`, `divideGrid` show how).
- `App/Sketch.swift` (`SketchDrawer`): draws in, undraws, glides moved parts, rolls changing numbers.
- `App/ProblemWords.swift`: the solving area (`workSketch`, `inlineBlocks` for answered-in-work lessons).
- `Core/LessonPlan.swift`: 3 together, 6 on their own (misses bring targeted problems), a 12-question test passed at 10.

## Open items G raised
- The iPad keyboard: typing goes through a hidden text field (`NumberEntry` in `PaperScreen.swift`); G couldn't get the
  simulator's on-screen keys to show (⌘K toggles them). Needs checking with G.
- The "focus" idea (finished rows and other strips going quiet) and the picture acting out each step aren't built.
- The red dashed section boxes are off (`ProblemGrid.showSections = false`).
