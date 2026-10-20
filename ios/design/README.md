# Obento² paper lessons: the design language

G, 20 Oct 2026: of everything tried on the test page (`prototype/paper-lessons.html`), only **Claude's Rounding decimals
and Adding fractions** worked. Every lesson is designed the way those two are, and anything 3D starts from **Unit
cubes** (the Swift lesson) and builds on it. The designer agent's notes were dropped; don't build from them (they're in
git history only). Claude leads the design (G, 20 Oct). `grade5.md` has every 5th grade lesson in this language.

## Why those two worked

- **The picture is the maths, big.** A number line a tenth long, 50 squares wide; two bars a whole long, 48 squares
  wide. The thing being learned fills the screen at a size a child reads from across the room.
- **One square means something, and stays the same.** A whole is always 48 squares, so every piece size is a whole
  number of squares and can be counted. On the line, one step is a block.
- **Each step is one thing to do with your hand, and the paper answers it.** Tap the block the point is in, and it
  opens into ten big steps. Drag the ruler, and the cuts show across both bars while you drag. Old cuts get a green dot
  when a new cut lands on them and a red one when it doesn't. Drag the point, and the steps count as you go.
- **The problem is written once, as the picture's own names.** The fractions name their bars; the number labels its
  point. There's no separate problem line.
- **The written working comes last, as the record.** Once the hands have found it, the school working is written
  under the picture (`3.476 ≈ 3.48`, `1/4 + 1/6 = 3/12 + 2/12 = 5/12`). The rule appears after it's been seen: the
  digit underlined, the next ringed, "6 is 5 or more: round up". Typing is only for the number school writes.
- **Words say what to do, in one line.** "Drag the ruler to cut both bars into the same size pieces." The last line
  says why ("Same-size pieces, so the tops add."), never the sum again.

## The rules

1. **Layout, top to bottom on the grid:** what to do (rows 0–2, words 28) · what a miss says (rows 3–4, words 20, red)
   · the picture (from row 6, about 48–50 squares wide; its names at its right end) · the record (3 rows under the
   picture, maths 36, 2 squares a digit, the point on a grid line) · the blocks under the record (Cut / Check, then Next
   problem). The camera frames what's drawn now, at most 125%.
2. **One square means one thing per lesson**, fixed across scenarios where the numbers allow, so the answer can be
   counted on the paper. Built in whole squares; labels' ink half a square from what they label.
3. **Each step is a hand move that snaps** (tap a cell, piece or block; drag a handle, point, length, pieces or a
   corner; cut with the ruler), with a live readout while the finger moves (the piece name, the step count, the
   running total). Release answers the step, or a block commits it (Cut).
4. **A wrong move is answered on the paper and in plain words** under the instruction: what happened, measured on the
   grid ("That end is 6 steps away. The other end is 4."). The thing snaps back; nothing is lost.
5. **See**: after each right move the picture proves it (cuts turn solid and the pieces count; the block opens; the
   hop arcs to the end), drawing in.
6. **Write**: the record, as 5th grade writes it, typed only where school writes a number. Then the rule as record.
7. **Say**: the last line says why. The answer in the chapter colour.
8. **Colour** only in the maths (chapter colour); red and green only for wrong and right. One line weight (1.5).
   Three text sizes (36 maths, 28 words, 20 small).
9. **3D** (volume and anything that rises off the paper) is Unit cubes: flat first, the paper tilts as the maths rises,
   words stay facing the child, flat again before leaving. One cube is one block.
10. **Show me and the How to play the hand move** with a ghost finger on the paper, then put everything back (Show me
    is a preview, never the child's work).

## The hand-move kit (built once in Swift, used by every lesson)

| Move | Used by |
|---|---|
| Ruler cut (handle sets the piece size; cuts dashed across the bars; dots under old cuts; Cut) | add, sub, mix, improper, unitdiv, fracof, multfrac, units |
| Slide pieces (drag a group into another bar; it snaps after the shaded pieces, or over them to take away) | add, sub, mix, adddec |
| Tap pieces / rows (shade, unshade) | fracof, multfrac |
| Tap a block on a line (it opens below into ten big steps) | round |
| Drag a point along a line (snaps to ticks; the steps count) | round, divdec |
| Hop along a line (lay hops of one size; they count) | divdec |
| Drag a rectangle's edge or corner (snaps to squares; its sides and area count) | mult2, divide, multdec |
| Drag digits across place columns (the point stays on its line) | pow10 |
| Tap the part that goes first | order |
| Cover the floor, build the layers (3D) | volume |
| Write (a box in the record) | every lesson's last number |
