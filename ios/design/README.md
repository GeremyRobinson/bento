# Lesson design: how every lesson gets its own screen

G, 20 Oct 2026. Read this before designing or building any lesson.

## Why

A single layout that every lesson fits into has failed twice:
- **The web app** draws all 191 lessons on one screen: the problem, a picture, then a stack of one-line steps. It looks tidy, but nothing is written the way school writes it. Even column adding is a line that says "(write 3, carry 1)".
- **Obento²'s first try** at an automatic arranger (`ProblemGrid`) put a picture, a separate answer line and a separate sum into boxes. G found it confusing.

Each lesson is its own design, and the shared code is only tools.

## The rules

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
| tape (bars) + fractions over one bottom | 24 | Adding fractions (`add`) | Approved 20 Oct |
| area grid + columns | 20 | Multiply two-digit numbers | Approved 19 Oct |
| area grid + division bracket | 2 | Long division | Built, not reviewed |
| number line | 15 | Rounding decimals (`g5-round`) | Next |
| plane | 23 | (grade 8) | |
| balance / algebra tiles | 18 | (grade 6) | |
| early-grade counting pictures | 63 | (K–4) | |

Subtracting fractions (`sub`) and Adding and subtracting (`mix`) share Adding fractions' design and code. Each still needs G to look at it.
