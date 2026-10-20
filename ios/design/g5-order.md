# Brief: Order of operations (`g5-order`)

**Kits:** units in cells (rows dragged down, as Multiply's rectangle), the deal (from `g5-fracof`); the working line under line as the record.
**Status:** designed 20 Oct to rule 0 and the Unit cubes standard, waiting on G.

## The hero, and one unit
- **The expression is built as a shape, in the order it's worked.** **One = a 2 × 2 cell.** A take-away is a row with cells crossed out; a times is that row dragged down into rows; a plus is more cells joining; a divide is cells dealt into equal rows.
- **The answer is counted:** the cells left at the end. Worked in the wrong order the shape is different, and so is the count: the slip messages can show it ("Left to right makes 7 rows of 4: 28 cells").

## Hands
- **Tap** the part of the record's first line that goes first (its characters are the tap target).
- **Tap a cell** to cross cells out; **Drag a length** to drag a row down into rows or a row onto another's end (snaps a cell at a time, live count); the **deal** for ÷.
- **Typed:** the answer.

## Layout on the screen (68 × 45 squares)
- Rows 0–3: what to do.
- The shape at columns 0–36, from row 5 (the biggest, (9 + 9) × 12, is 36 × 24).
- The record, columns 40–66: the expression on the first line, 2 squares a character; each next line `=` with the worked part replaced by its value (written by the app once the hands made it), the part being worked with a soft fill behind it; the last line `= [ ]`.
- A live count under the shape while dragging; Check under the shape.
- The picture takes 12–36 of 68 across and 6–24 of 45 down; small shapes (the first three) sit at 3 × 3 cells to fill more.

## Steps (t0: a + b × (c − d), e.g. 3 + 4 × (6 − 2))
1. **"Which part goes first? Tap it."** **Tap** a part of the first line (3 + 4, 4 × 6 or 6 − 2, the web's choices, each lit on touch). Check (Core `first`, box `c`).
2. **"Take away 2."** A row of 6 cells draws in. **Tap** 2 cells to cross them out. Check (Core `s0`, `x` = cells left). The record writes `= 3 + 4 × 4`.
3. **"Make 4 rows of it."** **Drag** the row down. Check (Core `s1`, `x` = 16). The record writes `= 3 + 16`.
4. **"Add 3. Then write it."** 3 striped cells join as a column on the left. **Type** the answer. After Check all the cells count 1 to 19.
5. **"Parentheses first, then ×, then +."**

**t1, (a + b) × c − d:** tap `(a + b)` · **"Put them together."** drag b's row onto the end of a's · **"Make c rows of it."** · **"Take away d. Then write it."** cross out d cells, type · **"Parentheses first, then ×, then −."**
**t2, a × b − c ÷ d:** tap `a × b` · **"Make b rows of a."** · **"Deal c into d rows."** (beside the rectangle) · **"Take away one row's worth. Then write it."** cross out c ÷ d cells, type · **"× and ÷ first, then −."**

## Scenarios
| | Example | Picture on screen | What changes |
|---|---|---|---|
| A | 2 + 3 × (7 − 5) = 8 | 21 × 9 (3 × 3 cells) | The first three: t0 with an answer of 9 or less, so the order is the hard part. |
| A2 | 3 + 4 × (6 − 2) = 19 | 15 × 12 (3 × 3 cells) | A later t0 (the mock-up). |
| B | (5 + 3) × 7 − 4 = 52 | 16 × 14 | t1: a row of 8, 7 rows, 4 crossed out. |
| C | 6 × 7 − 12 ÷ 4 = 39 | 14 × 12, deal beside it | t2. |
| D | (9 + 9) × 12 − 11 = 205 | 36 × 24 | The biggest. |

**Mock-up, A2 (3 + 4 × (6 − 2)), step 3.** Half scale: one character is 2 squares; a 3 × 3 cell is `[]`, crossed `xx`.

```
 0  Make 4 rows of it.
 3  [][][][]xxxx          3 + 4 × ( 6 − 2 )
 5  [][][][]
 6  [][][][]   12         = 3 + 4 × 4
 7  ........
 9  Check
```

## Core changes (`OrderOfOperations`)
- `ask`: **drop it.**
- `first`: say **"Which part goes first? Tap it."**; the choices become tap targets in the record's first line (the app maps choice i to its characters); no choice blocks.
- `s0`, `s1`: words as above per shape; answered by the move (`x` = cells counted). `s2`: typed.
- `done`: "Parentheses first, then ×, then +." / "…then −." / "× and ÷ first, then −." (no answer in it).
- Picture keys, replacing `beat`: `built`, `crossed`, `rows`, `joined`, `dealt` (from the hands), `count` 1.

## Open
- None.
