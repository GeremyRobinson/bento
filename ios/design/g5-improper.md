# Brief: Mixed numbers to fractions (`g5-improper`)

**Kits:** tape (bars and the Cut, from `add`); fractions stacked as the record.
**Status:** designed 20 Oct to rule 0 and the Unit cubes standard, waiting on G.

## The hero, and one unit
- **The bars are the mixed number.** One bar per whole, and one more bar for the extra part. A whole is **48 squares**, as in Adding fractions (halves 24, thirds 16, fourths 12, sixths 8, eighths 6); fifths use a 40-square whole (8 each), sevenths 42 (6), ninths 45 (5). Bars are 4 squares tall, 1 apart (a block tall, 5 apart, when there are 3 wholes or fewer).
- The wholes start shaded and **uncut**, labelled `1` on the left; the extra bar is cut into its pieces, n shaded.
- **The answer is counted:** once the wholes are cut, every piece is numbered, bar after bar, 1 to 11 for 2 3/4. The last number is the top; the pieces' size is the bottom.

## Hands
- **Cut** across all the whole bars at once, to match the extra bar's pieces (snaps to grid lines; a cut that misses the extra bar's cuts shows at once).
- **Typed:** the fraction, top and bottom, in the record.

## Layout on the screen (68 × 45 squares)
- Rows 0–3: what to do.
- Bars at columns 0–48, from row 5: up to 6 wholes and the extra bar (6 × 5 + 4 = 34 rows at the most).
- The record, columns 51–66: `2 3/4` level with the first bar; `= 8/4` (written once the wholes are cut) beside it; `+ 3/4` level with the extra bar; a line under it; the answer's boxes under the line.
- Check under the bars.
- The picture takes 48 of 68 across and 14–34 of 45 down.

## Steps
1. **"Each bar is one whole."** No move. The wholes draw in, then the extra bar.
2. **"Cut the wholes into fourths."** Small line: "Drag down across them." **Cut**. Check: pieces in a whole × wholes (Core `wholes`, `x` = w × d). When right, the pieces are numbered 1 to 8 bar after bar, each bar's running count at its right end, and the record writes `= 8/4`.
3. **"Write it as one fraction."** **Type** the top and the bottom. After Check the extra pieces number on, 9, 10, 11, the 11 in the chapter colour.
4. **"The pieces stay fourths, so the bottom stays 4."** The record reads `2 3/4 = 8/4 + 3/4 = 11/4`.

## Scenarios
| | Example | Whole | Picture on screen | What changes |
|---|---|---|---|---|
| A | 1 1/2 | 48 | 48 × 14 | One whole, bars a block tall; one cut at 24. |
| B | 2 3/4 | 48 | 48 × 19 | The main one. |
| C | 5 2/3 | 48 | 48 × 29 | Five wholes, bars 4 tall. |
| D | 3 5/7 | 42 | 42 × 24 | Sevenths are 6 squares. |
| E | 6 7/9 | 45 | 45 × 34 | Six wholes; ninths 5 squares. |

**Mock-up, B (2 3/4), step 2 done.** Half scale: one character is 2 squares. `|` cuts every 12 squares (6 characters).

```
 0  Cut the wholes into fourths.
 1  Drag down across them.
 3  1 |##1##|##2##|##3##|##4##|  4      2 3/4  =  8/4
 4    |#####|#####|#####|#####|
 6  1 |##5##|##6##|##7##|##8##|  8
 7    |#####|#####|#####|#####|
 9  3 |/////|/////|/////|.....|            +  3/4
10  - |/////|/////|/////|.....|           ---------
11  4                                        [ ]
12                                           ---
13  Check                                    [ ]
```

## Core changes (`MixedToImproper`)
- `ask`: say **"Each bar is one whole."**
- `wholes`: say **"Cut the wholes into \(pieceName(d))."**; answered by the Cut (`x` = w × pieces per whole).
- **Drop `extra`.** Its slip moves into `fraction`'s `known`: `(["n": w + n, "d": d], "Use the \(w * d) pieces the wholes make, not the \(w).")`.
- `fraction`: say **"Write it as one fraction."** Typed.
- `done`: say **"The pieces stay \(pieceName(d)), so the bottom stays \(d)."**
- Picture keys: `cut` 1, `fraction` 1. `wholes/extra/focus` go.

## Open
- None.
