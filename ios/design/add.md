# Brief: Adding fractions (`add`)

**Kits:** tape (bars, the Cut move) and fractions over one bottom. `sub` and `mix` use the same design.
**Status:** approved by G on 20 Oct 2026 and built (bars and working on the same rows, typed answers). Redesigned on 20 Oct to rule 0 and the Unit cubes standard (`README.md`): the bars are the hero at full width, the child cuts and shades them by hand, and the working is the record beside them. To be rebuilt first, with `g5-round`.
**Kept from what G approved:** each bar on the same rows as its fraction; the problem written once (in the record); a fraction already over the new bottom done for the child; no simplify step when the answer can't be simplified; a number in a fraction written as one word centred on its column; the last words say why.

## The hero, and one unit
- **The bars are the problem.** Each fraction is a bar one whole long, cut into its own pieces and shaded. A whole is always **48 squares** (just over two thirds of the screen): halves are 24 squares, thirds 16, fourths 12, sixths 8, eighths 6, twelfths 4, so every piece lands on a grid line and twelfths are still 4 squares, easy to tap. When the common bottom doesn't go into 48 the whole is 40 (fifths, tenths, twentieths), 42 (sevenths, fourteenths, 21sts), 36 (ninths, eighteenths), 44 (elevenths, 22nds) or 45 (fifteenths). One problem uses one length for every bar.
- Bars are **a block tall** (5 squares), on block lines, 5 squares apart.
- **The answer is counted:** the answer bar holds the pieces of both bars, numbered as they arrive; its last number is the top. A wrong shading is seen against the bracket of the old fraction.

## Hands
- **Cut** (new here; reused by `g5-improper`, `g5-unitdiv`, `g5-multfrac`): the child drags a finger down across the bars. The cut snaps to the nearest grid line; the distance from the bars' left end to it is one piece, and the cut copies itself at that spacing along every bar the drag crossed (pale while dragging, firm when let go). Old cuts stay. Where a new cut lands on an old one both light; an old cut with no new cut on it stays plain, so a cut that doesn't fit both bars is seen at once. Check reads the pieces in a whole (48 ÷ the piece) as the step's number. A piece that doesn't go into the whole ends short of the bar's end ("The pieces must fill the whole bar.").
- **Tap a cell:** a tap shades or clears one piece.
- **Typed:** the answer's top (its bottom is given), and the simplest form.

## Layout on the screen (68 × 45 squares)
- Rows 0–3: what to do (one line, and a small second line when a move needs it).
- Bars from row 5, columns 0–48: the first fraction's bar (rows 5–10), the second's (rows 15–20); a line across under them on row 23; the answer bar (rows 25–30), and a second answer bar (rows 35–40) when the answer is more than 1. Under the bar being worked, a live count ("3 of 12").
- The record, columns 51–66: each fraction centred on its bar's rows, the sign before the second; after `=`, each rewritten over the new bottom; the line on row 23; the answer centred on the answer bar, and its simplest form after `=`.
- Check under the bars, on row 42.
- The picture takes 48 of the 68 squares across and 35 of the 45 down.

## Steps
1. **"Look at the bars. Are the pieces the same size?"** (approved). No move. The bars draw in, each cut into its own pieces and shaded.
2. **"Cut both bars into the same size pieces."** Small line: "Drag down across both bars." **Cut**. For 1/4 + 1/6, fourths are every 12th line and sixths every 8th; the cut that lands on both is every 4th: twelfths. Check: the pieces in a whole (Core `lcd`, `x`). A cut that fits but isn't the biggest (every 2 squares, 24ths): "That works. Can the pieces be bigger?" When right, the record writes `= /12` after both fractions.
3. **"Shade twelfths to match 1/4."** **Tap a cell** on that bar. Its old shading becomes a faint outline with a bracket over it, labelled `1/4`, so the child shades up to its edge; the count under it reads "3 of 12". Check: the count (Core rewrite step, `x`). "You shaded 2. 1/4 covers 3 twelfths." The record writes the 3. Then the second bar. A fraction already over the new bottom is shaded for the child and written (as approved).
4. **"Add the tops."** or **"Take away the tops."** (approved). **Type** the answer's top in the record. After Check, the answer bar fills: the first bar's pieces drop in (solid), then the second's (striped), numbered on 1, 2, 3, 4, 5. Taking away crosses out the pieces taken.
5. **"Write it as simply as you can."** (only when it simplifies). **Type** the whole number when there is one and the fraction. The answer bar's cuts change to the simplest pieces (3 sixths becomes one half).
6. **"Same-size pieces, so the tops add."** (approved), and under it the record line read as one: `1/4 + 1/6 = 3/12 + 2/12 = 5/12`.

## Scenarios
| | Example | Whole | Picture on screen | What changes |
|---|---|---|---|---|
| A | 1/2 + 3/8 | 48 | 48 × 25 | Cut every 6 (eighths); 3/8 already fits, so only 1/2 is shaded: 4 of 8. |
| B | 1/4 + 1/6 | 48 | 48 × 25 | Both shaded to match; twelfths are 4 squares. |
| C | 3/4 + 5/6 = 19/12 | 48 | 48 × 35 | The answer spills into a second bar; simplify writes `1 7/12`. |
| D | 1/6 + 1/3 = 3/6 | 48 | 48 × 25 | Simplify: the answer bar's cuts change to halves. |
| E | 2/5 + 1/2 | 40 | 40 × 25 | Tenths of a 40-square whole: 4 squares each. |
| F | a story | 48 | 48 × 25 | The story is told on the rows above the bars; the sign is hidden until the child picks Add. |

**Mock-up, B (1/4 + 1/6), step 3.** Half scale: one character is 2 squares across and 2 down. `#` shaded, `.` not yet, `|` a cut every 4 squares (a twelfth = 2 characters).

```
 0  Shade twelfths to match 1/4.
 1  Tap the pieces.
 2  [-- 1/4 --]
 3  |##|##|##|..|..|..|..|..|..|..|..|..|     1     3
 4  |##|##|##|..|..|..|..|..|..|..|..|..|     -  =  -
 5   3 of 12                                  4    12
 7  |##|##|..|..|..|..|..|..|..|..|..|..|     1
 8  |##|##|..|..|..|..|..|..|..|..|..|..|  +  -  =  -
 9                                            6    12
11  ------------------------------------------------
13  |  |  |  |  |  |  |  |  |  |  |  |  |
14  |  |  |  |  |  |  |  |  |  |  |  |  |
16  Check
```

## Core changes (`UnlikeFractions.makeSpec`)
- `lcd`: say **"Cut both bars into the same size pieces."**; answered by the Cut (`x` = pieces in a whole). The "works, find a smaller one" branch's words become "That works. Can the pieces be bigger?"
- `rewrite`: say **"Shade \(pieceName(L)) to match \(top)/\(den)."**; answered by the taps (`x` = pieces shaded). The "kept the top" slip reads "You shaded \(top). \(top)/\(den) covers \(N) \(pieceName(L))."
- `done`: the say stays; the hint line under it becomes the record read as one line.
- Picture keys: `cutting` 1 (the bars take the Cut), `shading` 1 or 2 (which bar takes taps), `tapped` (the pieces shaded, from the child's taps). The whole's length comes from L by the rule above.

## Decided
- A fraction already over the new bottom is done for the child (G 20 Oct).
- No simplify step when the answer is already simplest (G 20 Oct).
- The child cuts the bars by hand (rule 0), replacing the typed new bottom.

## Open
- None.
