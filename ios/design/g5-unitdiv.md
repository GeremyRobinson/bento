# Brief: Dividing by a unit fraction (`g5-unitdiv`)

**Kits:** tape (bars and the Cut, from `add`); a one-line record.
**Status:** designed 20 Oct to rule 0 and the Unit cubes standard, waiting on G.

## The hero, and one unit
- **The bars are the wholes.** W bars, one per whole, shaded and labelled `1`. A whole is **48 squares**, as in every fraction lesson; fifths use 40, sevenths 42. Above the first bar, one piece of 1/d on its own (12 squares for fourths), labelled `1/4`: the size being fitted.
- Bars are a block tall, a block apart, up to 4 wholes; 4 squares tall, 1 apart, up to 6; 3 tall, 1 apart, up to 10.
- **The answer is counted:** every whole is cut into pieces the size of the 1/d piece, numbered on whole after whole; the last number is the answer.

## Hands
- **Cut** the first whole; it snaps to grid lines and repeats, and must match the 1/d piece above it.
- **Typed:** the answer.

## Layout on the screen (68 × 45 squares)
- Rows 0–3: what to do. Row 5: the 1/d piece. Bars from row 9 at columns 0–48 (up to row 44 for 10 wholes).
- The record, columns 51–67, one line level with the first bar: `3 ÷ 1/4`, then `= 3 × 4` once the first whole is cut, then `= [ ]`.
- Check under the bars (beside the record when the bars reach the bottom).
- The picture takes 48 of 68 across and 14–40 of 45 down.

## Steps
1. **"How many fourths fit in one whole?"** Small line: "Cut it into pieces this size." **Cut** the first bar. Check (Core `one`, `x` = pieces). When right its pieces are numbered 1 to 4, and the record writes `= 3 × 4`.
2. **"How many fourths in all 3?"** **Type** the answer. After Check the other wholes are cut one after another, half a second apart, numbered on (5 to 8, 9 to 12), each running count at its bar's right end, the last in the chapter colour.
3. **"Small pieces, so lots of them fit."** The record in the chapter colour.

## Scenarios
| | Example | Whole | Picture on screen | What changes |
|---|---|---|---|---|
| A | 2 ÷ 1/2 | 48 | 48 × 19 | Two wholes, halves of 24 squares. |
| B | 3 ÷ 1/4 | 48 | 48 × 24 | The main one. |
| C | 10 ÷ 1/6 | 48 | 48 × 39 | Ten bars 3 tall; sixths 8 squares. |
| D | 4 ÷ 1/5 | 40 | 40 × 29 | Fifths are 8 squares. |
| E | a story (cups of flour, 1/3 cup a batch) | 48 | 48 × 24 | Told on the rows above; the piece above the bars is labelled `1/3 cup`. |

**Mock-up, B (3 ÷ 1/4), step 2.** Half scale: one character is 2 squares.

```
 0  How many fourths in all 3?
 2  [ 1/4 ]
 4  1 |###1##|###2##|###3##|###4##|   4      3 ÷ 1/4 = 3 × 4 = [ _ _ ]
 5    |######|######|######|######|
 7  1 |###########################|
 8    |###########################|
10  1 |###########################|
11    |###########################|
13  Check
```

## Core changes (`DivideByUnitFraction`)
- `ask`: **drop it.**
- `one`: say **"How many \(pieceName(d)) fit in one whole?"**, hint line "Cut it into pieces this size."; answered by the Cut.
- `every`: say **"How many \(pieceName(d)) in all \(W)?"** Typed.
- `done`: say **"Small pieces, so lots of them fit."**
- Picture keys, replacing `at/ask`: `cut` 1, `all` 1.

## Open
- None.
