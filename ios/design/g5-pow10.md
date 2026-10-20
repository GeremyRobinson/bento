# Brief: Multiply by 10, 100, 1000 (`g5-pow10`)

**Kits:** a place-value chart (columns a block wide, the point on a strong line), digit tiles that slide; a one-line record.
**Status:** designed 20 Oct to rule 0 and the Unit cubes standard, waiting on G.

## The hero, and one unit
- **The chart is the number.** **One place = a block column** (5 squares wide), its name in small words on top (hundreds, tens, ones, tenths, hundredths; "ten thousands" on two lines). The point sits on the **strong line** between ones and tenths and never moves. Each digit is a tile a block square, its digit centred.
- Two rows of tiles, a block tall each, a block apart: the number as given (top), and its copy (bottom), which the child moves.
- **The answer is seen:** times 10 every digit moves one place left (it's worth ten times more); the bottom row read across the point is the answer. Empty places between the digits and the point fill with 0 tiles.

## Hands
- **Tap a cell:** tap each 0 of the 10, 100 or 1000 in the record.
- **Drag a length:** drag the bottom row's tiles left, all together; they snap a column at a time, an arrow over each place moved.
- **Typed:** a 0 in each empty place left between the digits and the point, as school writes it.

## Layout on the screen (68 × 45 squares)
- Rows 0–3: what to do.
- The chart at columns 0–35 (as many columns as the answer needs, up to 7), from row 5: names (rows 5–6), top row (rows 8–13), bottom row (rows 18–23).
- The record, columns 40–66, level with the top row: `3.47 × 100`, and `= 347` written by the app at the end.
- Check under the chart.
- The picture takes 25–35 of 68 across and 19 of 45 down; with 4 or 5 columns the chart's columns are 2 blocks wide (40–50 across) so it stays big.

## Steps
1. **"Tap each zero in 100."** **Tap** them in the record; each is ringed, the count under it. Check (Core `zeros`, `x`; its slips as now).
2. **"Move the digits 2 places left."** **Drag** the bottom row; each column of travel draws an arrow and the tiles light as they land. Where a place is left empty before the point, a box opens in it: "Write a 0 in each empty place." **Type** 0. Check reads the bottom row (Core `move`, `x`; its slips fire for one place short or past).
3. **"Each zero makes every digit worth ten times more."** The bottom row in the chapter colour; the record writes `= 347`.

## Scenarios
| | Example | Columns | Picture on screen | What changes |
|---|---|---|---|---|
| A | 3.4 × 100 = 340 | 4, 2 blocks wide | 40 × 19 | The first problem: one 0 typed. |
| B | 5.27 × 10 = 52.7 | 4, 2 blocks wide | 40 × 19 | One place; no zero. |
| C | 3.47 × 100 = 347 | 5, 2 blocks wide | 50 × 19 | Two places; the point ends after the last digit. |
| D | 61.5 × 1000 = 61500 | 6, 1 block wide | 30 × 19 | Three places, two zeros typed. |

**Mock-up, A (3.4 × 100), step 2.** Half scale: one character is 2 squares; a column is 2 blocks (5 characters); `|` the strong line at the point.

```
 0  Move the digits 2 places left.
 1  Write a 0 in each empty place.
 3  hundreds  tens   ones |tenths
 4                  [ 3 ]|[ 4 ]                 3.4 × 1 (0)(0)
 6   <----   <----
 9   [ 3 ]  [ 4 ]  [ _ ] |
11  Check
```

## Core changes (`PowersOfTen`)
- `ask`: **drop it.**
- `zeros`: say **"Tap each zero in \(M)."**; answered by the taps.
- `move`: say **"Move the digits \(places(k)) left."** (+ "Write a 0 in each empty place." when short); answered by the drag and the typed zeros.
- `done`: say **"Each zero makes every digit worth ten times more."** (The spec's idea line, kept: the point "hops" in the old words; here the digits move and the point stays, which is the same thing seen from the chart.)
- Picture keys: `rings`, `moved` (from the drag), `zerosTyped`.

## Open
- None.
