# Brief: Fraction of a number (`g5-fracof`)

**Kits:** things in cells (one unit, as Multiply's squares), groups as rows, Drag a length (the deal, reused by `g5-order`); a two-line record.
**Status:** designed 20 Oct to rule 0 and the Unit cubes standard, waiting on G.

## The hero, and one unit
- **The things are the problem.** 20 marbles are 20 cells in a tray, in rows of 10 (place value: two full rows). **One thing = a 3 × 3 cell**, or a 2 × 2 cell when there are more than 40, so the tray is always big and countable.
- Next to the tray, d empty rows: the groups, one cell tall, a square apart, all starting on one column, with a handle at their right edge.
- **The answer is counted:** dealing makes d equal rows; the top says how many rows to shade; the shaded cells are the answer.

## Hands
- **Drag a length** (the deal): drag the rows' right edge. Each cell of drag takes d things from the end of the tray, one into each row; it snaps a cell at a time and stops when the tray is empty, so the rows are always equal.
- **Tap a cell:** a tap on a row shades the whole row (tap again to clear).
- **Typed:** the answer, in the record.

## Layout on the screen (68 × 45 squares)
- Rows 0–3: what to do.
- Up to 40 things: the tray at columns 0–30, rows 5–11; the rows under it from row 14. More than 40: the tray at columns 0–20 and the rows beside it at columns 24–48, both from row 5.
- The record, columns 51–66 (or 35–50 when the picture is narrow): `3/4 of 20` level with the tray; `20 ÷ 4 = 5` level with the first row (written by the app after the deal); `5 × 3 = [ ]` level with the last row taken.
- A live count under the tray while dealing ("8 left"); Check under the picture.
- The picture takes 30–48 of 68 across and 25–30 of 45 down.

## Steps
1. **"Deal the 20 into 4 equal rows."** Small line: "Drag the rows longer." **Drag a length**. Check: the row length (Core `groups`, `x`). The record writes `20 ÷ 4 = 5`; each row gets `5` half a square past its end; the empty tray fades.
2. **"Shade 3 rows. Then write how many."** **Tap** 3 rows, then **type** in `5 × 3 = [ ]`. Check reads the box (Core `take`; its slips as now). After Check a bracket on the left spans the shaded rows, labelled `3/4`, and the shaded cells are counted 1 to 15.
3. **"The bottom made 4 groups. The top took 3."** The record in the chapter colour.

When the top is 1 (the first three problems), step 2 is left out: step 1 ends with the child **typing** the row length in `20 ÷ 4 = [ ]`, the first row is shaded for them, and the words are "The bottom made 4 groups. One is the answer."

## Scenarios
| | Example | Cell | Picture on screen | What changes |
|---|---|---|---|---|
| A | 1/4 of 12 | 3 × 3 | 30 × 22 | Top 1: deal, then type 3. |
| B | 3/4 of 20 | 3 × 3 | 30 × 30 | The main one. |
| C | 5/8 of 96 | 2 × 2 | 48 × 24 | Tray beside the rows: 8 rows of 12. |
| D | 2/9 of 54 | 2 × 2 | 34 × 27 | 9 rows of 6. |
| E | a story (marbles in a bag) | | | Told on the rows above; the tray is the bag. |

**Mock-up, B (3/4 of 20), step 2.** Half scale: one character is 2 squares; a thing (3 × 3) is drawn `[]`. The tray is empty and gone.

```
 0  Shade 3 rows.
 1  Then write how many.
 7  [##][##][##][##][##]  5         20 ÷ 4 = 5
 9  [##][##][##][##][##]  5
11  [##][##][##][##][##]  5          5 × 3 = [ _ _ ]
13  [  ][  ][  ][  ][  ]  5
16  Check
```

## Core changes (`FractionOf`)
- `ask`: **drop it.** The deal is the first move (the problem is in the record).
- `groups`: say **"Deal the \(W) into \(d) equal rows."**; answered by the drag. When n == 1 it is typed after the drag and is the last worked step.
- `take`: say **"Shade \(n) rows. Then write how many."** Typed. **Left out when n == 1.**
- `done`: say **"The bottom made \(d) groups. The top took \(n)."** (n == 1: "The bottom made \(d) groups. One is the answer.")
- Picture keys, replacing `at/ask`: `dealt` (row length, from the drag), `shaded` (rows tapped), `answer` 1.

## Open
- None.
