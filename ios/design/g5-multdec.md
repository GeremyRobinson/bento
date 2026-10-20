# Brief: Multiplying decimals (`g5-multdec`)

**Kits:** one whole opened (from `g5-adddec`), columns as the record, the point placed in the record.
**Status:** designed 20 Oct to rule 0 and the Unit cubes standard, waiting on G.

## The hero, and one unit
- **One whole, big.** A square **30 × 30 squares: one tenth = a strip 3 squares wide, one hundredth = a 3 × 3 cell.** The question the picture answers: how big is one piece when a tenth meets a tenth? A tenth column (for the first number's place) and a tenth row (for the second's) cross in **one cell of 100**: a hundredth. That's why the places add.
- For tenths × a whole number (2.4 × 3) the piece is one tenth column. For hundredths × tenths (1.23 × 0.4) the crossing cell (a hundredth × a tenth) opens beside the whole into a 30-square-tall strip of 10 slices: one slice is a thousandth (zoom).
- **The answer is counted** where it fits: when the product is below 1 (tenths × tenths up to 0.99) its cells are shaded in the whole after Check, 72 cells for 0.72. Larger products are counted in the record (Multiply does the digits).

## Hands
- **Typed:** the product of the digits, in the record (as school writes it under the line).
- **Tap a cell:** tap a column of the whole (one tenth: the first number's place), then a row (the second's); the crossing cell lights.
- **Place a point:** drop the point into the product in the record; it snaps to the grid lines between digits, and a 0 is written in front when it lands left of every digit.

## Layout on the screen (68 × 45 squares)
- Rows 0–3: what to do.
- The whole at columns 0–30, rows 5–35 (the thousandth strip beside it at 33–36 when needed).
- The record, columns 40–60: `2.4` over `× 0.3`, 2 squares a digit, lined up on the right; a line; the product. Beside each number, "1 place" (small, once the piece is found); beside the product, "2 places".
- Check under the whole.
- The picture takes 30 (37) of 68 across and 30 of 45 down.

## Steps
1. **"Multiply without the points."** **Type** the digits' product under the line. Check (Core `whole`).
2. **"Shade a tenth one way, then a tenth the other way."** **Tap** a column, then a row. Check (Core `places`, answered `x` = 2 when the crossing is one cell of 100, 1 when it is a column, 3 when the zoom strip's slice). The crossing cell lights, labelled "0.01"; the record writes "1 place", "1 place", "2 places".
3. **"Put the point in, 2 places from the right."** **Place a point** in the product. Check (Core `place`; its slips for one place off). Then the product's cells shade in the whole when it is below 1.
4. **"A tenth of a tenth is a hundredth."** (thousandths: "A hundredth of a tenth is a thousandth.")

## Scenarios
| | Example | Picture on screen | What changes |
|---|---|---|---|
| A | 2.4 × 3 = 7.2 | 30 × 30 | Tenths × a whole: only a column is tapped (the words say "Shade a tenth."); the piece is a tenth, 1 place. |
| B | 2.4 × 0.3 = 0.72 | 30 × 30 | The main one; 72 cells shaded at the end. |
| C | 9.7 × 0.8 = 7.76 | 30 × 30 | Product bigger than 1: not shaded; the record holds it. |
| D | 1.23 × 0.4 = 0.492 | 37 × 30 | The thousandth zoom strip; 3 places. |
| E | a story (a garden bed in m) | | Told on the rows above. |

**Mock-up, B, step 3.** Half scale: one character is 2 squares (a hundredth cell is 1.5 characters, drawn as one).

```
 0  Put the point in, 2 places from the right.
 3  #.........     (one column shaded)            2 . 4    1 place
 4  #.........                                 ×  0 . 3    1 place
 5  #.........                                 --------
 6  #.........                                     7 2     2 places
 7  @#########  <- the crossing: 0.01                ^
 ...
13  Check
```

## Core changes (`MultiplyDecimals`)
- `ask`: **drop it.**
- `whole`: say **"Multiply without the points."** Typed.
- `places`: say **"Shade a tenth one way, then a tenth the other way."** (pb == 0: **"Shade a tenth."**); answered by the taps.
- `place`: say **"Put the point in, \(placeWord(n)) from the right."**; answered by the placed point.
- `done`: say **"A tenth of a tenth is a hundredth."** (or the thousandths line).
- Picture keys, replacing `strip/lit/piece/line`: `column`, `row` (from the taps), `zoom` 1, `count` 1.

## Open
- None.
