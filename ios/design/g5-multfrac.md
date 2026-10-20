# Brief: Multiplying fractions (`g5-multfrac`)

**Kits:** an area square cut both ways (the Cut, from `add`, turned sideways for rows); fractions stacked as the record.
**Status:** designed 20 Oct to rule 0 and the Unit cubes standard, waiting on G.

## The hero, and one unit
- **One whole is a big square**, cut by the child. Its height is cut for the first bottom and its width for the second, each side a fixed length its pieces land on: **36 squares** for halves, thirds, fourths, sixths and ninths; 32 for eighths (4 each); 35 for fifths and sevenths (7 and 5). So 2/3 × 3/4 is a 36 × 36 square, its cells 12 tall and 9 wide.
- **The answer is counted:** the cells shaded twice are the top, all the cells the bottom; after Check they are numbered.

## Hands
- **Cut** across (rows) then down (columns): drag a line; it snaps to grid lines and repeats evenly.
- **Tap a cell:** a tap on a row (then a column) shades it all.
- **Typed:** the fraction shaded twice, and its simplest form.

## Layout on the screen (68 × 45 squares)
- Rows 0–3: what to do.
- The square at columns 0–36, rows 5–41.
- The record, columns 40–66, level with the middle of the square: `2/3 × 3/4 = [ ]/[ ]`, then `= [ ]/[ ]` when it simplifies.
- Check under the record (the square takes the height).
- The picture takes 36 of 68 across and 36 of 45 down.

## Steps
1. **"Cut it into 3 rows. Shade 2."** **Cut** across, then **tap** 2 rows. Check (new step, `n` = rows shaded, `d` = rows). The rows are labelled `2/3` on the left.
2. **"Cut it into 4 columns. Shade 3."** **Cut** down, then **tap** 3 columns (a second shade, striped). Check (new step). Labelled `3/4` on top.
3. **"Write the part shaded twice."** **Type** the top and the bottom (Core `across`; its slips as now). After Check the twice-shaded cells are numbered 1 to 6 and all cells' count, 12, is shown under the square.
4. **"Write it as simply as you can."** (only when it simplifies). **Type**. Core `simplify`.
5. **"A part of a part is a smaller part."**

## Scenarios
| | Example | Square | Picture on screen | What changes |
|---|---|---|---|---|
| A | 1/2 × 1/3 = 1/6 | 36 × 36 | 36 × 36 | Already simplest: no step 4. |
| B | 2/3 × 3/4 = 6/12 = 1/2 | 36 × 36 | 36 × 36 | The main one. |
| C | 3/8 × 2/5 = 6/40 = 3/20 | 32 tall × 35 wide | 35 × 32 | Two different side lengths. |
| D | 5/9 × 7/8 = 35/72 | 36 tall × 32 wide | 32 × 36 | Smallest cells, 4 × 4. |
| E | a story (the garden's vegetable part) | | | Told on the rows above. |

**Mock-up, B, step 2.** Half scale: one character is 2 squares; `#` shaded once, `X` twice.

```
 0  Cut it into 4 columns. Shade 3.
 2           3/4
 3     |XXXX|XXXX|XXXX|....|
 5  2  |XXXX|XXXX|XXXX|....|         2     3
 7  -  |----+----+----+----|         -  ×  -  =  [ ]
 9  3  |XXXX|XXXX|XXXX|....|         3     4     ---
11     |////|////|////|....|                     [ ]
13     |////|////|////|....|
15     |////|////|////|....|
18  Check
```

## Core changes (`MultiplyFractions`)
- `ask`: **drop it.**
- **Add `rows`:** say "Cut it into \(b) rows. Shade \(a)."; `AnswerTask(prompt: [.frac(.box("n"), .box("d"))], expected: ["n": a, "d": b], known: [(["n": b - a, "d": b], "Shade \(a) of the \(b) rows.")], hint: "The bottom says how many rows; the top how many to shade.")`, answered by the cut and taps.
- **Add `cols`:** the same with c and d, "columns".
- `across`: say **"Write the part shaded twice."** Typed.
- `simplify`: say **"Write it as simply as you can."** **Left out when gcd(N, D) == 1.**
- `done`: say **"A part of a part is a smaller part."**
- Picture keys, replacing `at/ask`: `rows`, `cols` (cuts and shading from the hands), `count` 1.

## Open
- None.
