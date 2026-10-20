# Brief: Dividing by a decimal (`g5-divdec`)

**Kits:** number line (one square = one step, from `g5-round`), the point dragged in the record (from `g5-pow10`).
**Status:** designed 20 Oct to rule 0 and the Unit cubes standard, waiting on G.

## The hero, and one unit
- **One line, read two ways.** **One square = one tenth**, so 4.8 is a line 48 squares long, long ticks every 10 squares (the wholes 0 to 4 above the line). Read ten times bigger (stepping out a level), the same squares are ones: 0, 10, 20, 30, 40 under the line. 4.8 ÷ 0.6 and 48 ÷ 6 are the same line. A line of 2.5 or shorter is drawn at 2 squares a tenth so it stays big; one longer than 50 folds onto a second row, like a ruler.
- At its start, a bracket 6 squares long labelled `0.6`: one hop.
- **The answer is counted:** hops of 6 squares from 0 to the end, each an arc, numbered.

## Hands
- **Place a point:** in the record, drag the point of each number one place right (snaps to the grid line).
- **Drag a length:** drag the hop along the line; it snaps every 6 squares, an arc and a number for each hop, and stops at the end.
- **Typed:** the answer.

## Layout on the screen (68 × 45 squares)
- Rows 0–3: what to do.
- The line across columns 0–50 on row 14 (and row 28 when folded), the hops above it (rows 8–13), the two readings above and under.
- The record, under the line at columns 0–30 (the line takes the width): row A `4.8 ÷ 0.6`; row B, a block under, the same digits in grey, their points ready to drag, then `= [ ]`.
- Check beside the record.
- The picture takes 48–50 of 68 across and 14–28 of 45 down.

## Steps
1. **"Move the point in 0.6 one place right."** **Place a point** in row B: `6`. Check (Core `divisor`, `x`). The line's second reading appears under it (0, 10, 20…), and the hop bracket reads `6`.
2. **"Do the same to 4.8."** **Place a point**: `48`. Check (Core `other`).
3. **"Hop along in 6s. Then write how many."** **Drag** from 0; 8 hops. **Type** 8. Check (Core `divide`).
4. **"Both ten times bigger, so the answer stays the same."**

## Scenarios
| | Example | Line | Picture on screen | What changes |
|---|---|---|---|---|
| A | 1.2 ÷ 0.4 = 3 | 24 squares (2 a tenth) | 24 × 14 | Short, drawn double: 3 hops of 8 squares. |
| B | 4.8 ÷ 0.6 = 8 | 48 | 48 × 14 | The main one. |
| C | 10.8 ÷ 0.9 = 12 | 108, folded 50/50/8 | 50 × 42 | Three rows; the hops carry on from row to row. |
| D | a story (juice into cups) | | | Told on the rows above. |

**Mock-up, B, step 3.** Half scale: one character is 2 squares; `|` a whole, `^` a hop of 6 squares (3 characters).

```
 0  Hop along in 6s. Then write how many.
 4  0         1         2         3         4
 5  ^^^ ^^^ ^^^ ^^^ ^^^ ^^^ ^^^ ^^^
 6  |....|....|....|....|....|....|....|....|....|..
 7  0    10        20        30        40      48
 8  [0.6]
10  4 . 8 ÷ 0 . 6
12  4 8   ÷   6   = [ _ ]       Check
```

## Core changes (`DivideByDecimal`)
- `ask`: **drop it.**
- `divisor`: say **"Move the point in \(Y) one place right."**; answered by the point.
- `other`: say **"Do the same to \(X)."**; answered by the point.
- `divide`: say **"Hop along in \(d)s. Then write how many."** Typed.
- `done`: say **"Both ten times bigger, so the answer stays the same."**
- Picture keys, replacing `lines/lit/one/all/hops`: `read10` 1, `hopped` (from the drag).

## Open
- None.
