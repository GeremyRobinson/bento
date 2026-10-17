# How lessons work on the paper (Obento²)

Read this before building or changing any lesson. It is the teaching and animation rulebook for Obento². G approved the direction on 2026-10-17; the per-grade examples in section 8 are still proposals. The same page lives as a Claude Doc: https://claude.ai/code/artifact/9aecbb73-0726-444c-a2a9-d887706caac2 (if they differ, ask the Obento² Lead which is newer).

## 1. The short version

On the paper, a lesson is not a picture with a keypad under it. The problem is drawn on the grid, and the child does the maths with their hands on that drawing. The grid is the measuring tool: one cell is one unit, everything sits on grid lines, and the picture is the proof.

**What stays:** what each lesson teaches, its numbers and generator, its answer checks, its mistake messages, its skill check and its words. All of it comes from Curriculum's specs and the live app's code, with the same answers.

**What changes:** how each step is shown and done. Every lesson is rebuilt as four beats (Ask, Do, See, Say) using a small set of hand moves, one camera and one set of motion rules. Those are described below.

**The two lessons built so far set the bar:** *Unit cubes* (squares rise into cubes as the paper tilts) and *Add with different bottoms* (you cover a fourth with eighths, then add one more).

## 2. The four beats of every lesson

| Beat | What the child sees | What the child does | Example (1/4 + 1/8) |
|---|---|---|---|
| **1. Ask** | The problem draws itself on the grid, piece by piece, building outward from the first thing they need. The question is written above it on a grid line. | Looks. Taps the main action ("Let's find out"). | The whole bar draws, then the fourths, then the eighths. |
| **2. Do** | The drawing waits for their hands. A live count is written under it ("2 of 8 shaded"). | Acts on the drawing with a hand move. Taps Check. | Taps eighths until they cover the fourth. |
| **3. See** | The picture proves the step: pieces line up, a dashed line matches two lengths, squares rise, a bracket spans the total. | Watches. Nothing to press while it moves. | Dashed lines show 1/4 = 2/8. One more eighth joins. |
| **4. Say** | The answer is written on the paper, under the picture that proves it, in the chapter colour. | Reads it. Taps "Next problem" for a fresh one. | 1/4 + 1/8 = 3/8, under a bracket. |

A lesson can repeat Do and See a few times (cover, then add; one layer, then the next), but it always opens with Ask and ends with Say. Practice and the skill check use the same drawing with fresh numbers.

## 3. The hand moves

A child should learn these once and use them everywhere. Every lesson's Do beat uses one or two of them. A new move is added only if no existing one fits, and only after G sees it.

| Move | What it does | Used for |
|---|---|---|
| **Tap a cell** | Shades or unshades one cell or piece. Tap again to undo. | Counting, fractions, area, arrays, probability |
| **Drag a length** | Pulls a bar, arrow or side along the grid. It snaps to grid lines and shows its length as you go. | Measuring, number line jumps, adding and subtracting, scaling |
| **Cut** | Draws a line across a shape on a grid line to split it into equal parts. | Fractions, division, decimals |
| **Group** | Circles a set of cells to bundle them. Ten cells become one strip, ten strips become one square. | Place value, regrouping, multiplication, ratios |
| **Place a point** | Taps a spot on a line or on the plane. It snaps to the nearest grid point. | Number lines, coordinates, graphs, data |
| **Build up** | Raises a layer or a shape off the paper into 3D. | Volume, solids, surface area |
| **Turn** | Drags to turn a 3D shape, only where turning is the lesson. | Solids, nets, cross-sections |
| **Write** | A number pad made of cells on the paper, for when the answer must be a number. | Final answers, skill checks |

The main action is always one cell block ("Check", "Next"). Show me and Reset are two square cells next to it. There are no other buttons.

## 4. Animation rules

Every motion has one job, and the job is one of four: **Teach** (shows how the maths works), **Cause** (shows what the child's tap did), **Place** (moves the camera so the child knows where they are), or **Answer** (shows right or wrong). A motion with no job is cut. Nothing loops.

**Order.** The camera moves first, then things draw. A picture builds outward from its first piece. Parts change in place (a square splits where it sits, a cube rises from its own square); nothing flies in from off screen.

**Timings** (one ease everywhere, slow in and slow out):

| Motion | Time |
|---|---|
| Tap feedback | 120 ms (m-tap) |
| Swap a part | 250 ms (m-swap) |
| Words rise in | 500 ms (m-in) |
| One See beat | 750 ms (m-beat) |
| A grid square fills | 0.26 s |
| Cubes rise | 0.7 s each, 40 ms stagger |
| Paper tilts into 3D | 1.1 s |
| Gentle glide to a lesson | 1.1 s, about 1.3x zoom |
| Fly between far places | 0.7 s |

**Zoom.** Zoom moves in log space, and at most 2x per beat. Text stays 20 pt and lines stay 3 pt at any zoom.

**Hands off.** Nothing moves while the child is tapping or typing. During a See beat the action blocks are hidden or greyed until the beat ends.

**Skips.** Back and Watch again snap straight to their state. Reduce Motion cuts straight with no glide, tilt or draw.

**Never remove.** The drawing-in and the zoom are part of the product. Taking either away is a step back (G has flagged it twice).

## 5. The camera

- One camera for the whole app. The paper never jumps and the grid never changes; only the camera moves.
- Tapping a lesson gives a slow, gentle glide to that lesson's piece. Opening it frames the problem with the action blocks in view.
- Every lesson step names its camera frame (which cells must be in view). The engine fits that frame and keeps a margin of 2 cells.
- The child can always pinch and pan. When they let go the camera rests; it does not spring back unless a step starts.
- Leaving a lesson glides back out to its piece on the paper, which then colours in if the lesson was learned.
- Phones use the same frames, fitted to the smaller screen. Words go under the picture instead of beside it.

## 6. When to use 3D

Use 3D only when the maths is about depth: volume, layers, nets of solids, surface area, 3D shapes, and later 3D graphs. Everything else stays flat, because flat is clearer.

The rule that G liked in the Unit cubes test:

1. The lesson opens **flat**, lined up with the grid exactly like a 2D lesson.
2. The tilt is a **lesson step** with its own reason ("let's build up"). The paper tilts about 1.1 s to the 3D view (elevation about 52°, turned about -28°).
3. Things **rise from their squares**: one cube = one big square (5x5 cells). The grid is the floor.
4. Words and blocks stay pinned to points on the paper but always face the child.
5. Before leaving, the paper tilts back flat.

The child may turn the view with one finger in 3D steps; it rests where they leave it.

## 7. Mistakes, hints, Show me, practice and the skill check

- **Mistakes.** Each lesson lists its common mistakes (for example adding the bottoms of fractions). A wrong answer is checked against that list, and the paper shows the child *their* answer drawn out next to the real one, so they can see the gap. There is never a red cross on its own.
- **Hints.** Up to 3 per practice problem, each one a small drawing step on the paper (shade the next part, draw the next line), never a paragraph.
- **Show me** (Watch again) replays the lesson's See beats on the current numbers. It snaps to the start, then plays.
- **Practice.** 6 fresh problems from the lesson's generator, same picture, new numbers. Problems are never typed in by hand.
- **Skill check.** 4 problems, no hints, no Show me. Learned = last check 3 or 4 right and not slipping. Rechecks come back after 3, 7, 21 and 60 days.
- When a lesson is learned, its piece on the paper colours in from pencil to full colour. That is the reward; there are no stickers.

## 8. One lesson per grade, done the paper way

| Grade | Lesson | On the paper |
|---|---|---|
| K | Count to 10 | Tap squares to fill a row of ten; the count is written under each one. |
| 1 | Add within 20 | Two rows of squares slide into one ten-frame; the extra spills to a new row. |
| 2 | Place value to 1000 | Squares group into a 10-cell bar, bars into a 10x10 block. Zoom out 10x per step. |
| 3 | Multiply as area | Drag a corner to make a rectangle of cells; rows x columns is counted out. |
| 4 | Equal fractions | One bar split into halves, then each half split again in place, so 1/2 = 2/4 is seen. |
| 5 | Add fractions / Unit cubes | Done in Swift: 1/4 + 1/8 tapped on eighths; cubes rise from squares in 3D. |
| 6 | Ratios | Two rows of coloured cells grow together in equal steps. |
| 7 | Integers | A number line on a grid line; moving left of 0 flips the colour. |
| 8 | Linear graphs | The grid becomes axes; rise and run are drawn as cell steps. |
| 9 | Solve equations | A balance drawn in cells; the same thing comes off both sides. |
| 10 | Pythagoras | Squares drawn on each side of a right triangle, in real cells, then compared. |
| 11 | Exponential growth | Squares double each beat, the camera zooming out 2x each time. |
| 12 | Area under a curve | Cells under a curve shade in, then shrink to thinner strips. |

These are proposals until G sees them in a web preview.

## 9. How we build each lesson

1. **Spec.** Start from the lesson's spec (ios/specs/). Write its See beats, Do task, mistakes and camera frames as data.
2. **Web preview.** The Obento² Lead builds it first in the paper preview (ios/reference/paper-canvas.html) so G can look and say yes.
3. **G approves.** Nothing is built in Swift before G's OK on the preview.
4. **Swift.** The terminal Claude Code agent writes the lesson as data for the one lesson engine, plus maths checks in Core tests.
5. **Check.** CI builds it and takes screenshots; the Obento² Lead checks them against the preview and this page, and sends notes.
6. **G tries it** in Swift Playgrounds on the Mac.

If the Swift version looks worse than the preview in any way, it is not done.
