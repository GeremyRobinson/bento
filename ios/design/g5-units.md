# Brief: Converting units (`g5-units`)

**Kits:** units in cells (a row per big unit), the Cut (from `add`), the More/Fewer pick; a two-line record in school's abbreviations.
**Status:** designed 20 Oct to rule 0 and the Unit cubes standard, waiting on G.

## The hero, and one unit
- **The amount is the problem, built of units.** One **small unit = a 2 × 2 cell** where a big unit holds 16 or fewer: an inch (a foot is a row of 12 cells, 24 squares), a foot (a yard is 3), a quart (a gallon is 4), an ounce (a pound is 16, 32 squares). For hours, meters and kilograms a big unit is a row of **10 cells** and one cell is a tenth of it (6 minutes, 10 cm, 100 g); the first row says so once, under it, in small words.
- **Big to small:** n big units, one row each, closed (an outline labelled `1 ft`), 2 squares tall, 1 apart; a half unit is half a row.
- **Small to big:** the amount as small cells, laid in rows like a folded ruler (24 cells a row for feet, yards and quarts, 16 for ounces, 20 for tenths), and one big unit, closed, above them: the size to cut by.
- **The answer is counted:** big to small, every row opens into its cells and they're counted on; small to big, the cells are cut into big units and the pieces counted (a half reads ½).

## Hands
- **Tap a cell:** tap a closed unit to open it into its cells (they count up).
- **Pick** More or Fewer (the choice blocks under the picture).
- **Cut** (small to big): cut across the folded rows; snaps to grid lines, repeats every big unit.
- **Typed:** the answer.

## Layout on the screen (68 × 45 squares)
- Rows 0–3: what to do.
- The units at columns 0–48 from row 5: up to 12 rows of a big unit (rows 5–40), or the closed big unit at row 5 and the folded cells from row 9.
- The record, columns 51–67, in abbreviations (ft, in, yd, m, cm, kg, g, h, min, gal, qt, lb, oz): the problem `3 ft = ? in` level with the first row; `1 ft = 12 in` under it once a unit is opened; after the pick the problem line becomes `3 ft = 3 × 12 = [ ] in` (the `?` turns into the box and moves right to make room, 250 ms).
- The choice blocks and Check under the picture.
- The picture takes 24–48 of 68 across and up to 36 of 45 down.

## Steps
1. **"Tap one foot to open it."** **Tap** the first row (or the closed unit above the cells). It opens into 12 cells, counted 1 to 12. Check (Core `one`, `x` = per). The record writes `1 ft = 12 in`.
2. **"More inches or fewer?"** **Pick** (Core `more`, as now). When right the record writes the sign: `3 ft = 3 × 12 = [ ] in` (or `250 cm = 250 ÷ 100 = [ ] m`).
3. Big to small: **"Open each foot. Then write how many."** **Tap** each closed row; it opens and counts on (13 to 24, 25 to 36), its running count at its right end. Then **type**.
   Small to big: **"Cut it into meters. Then write how many."** **Cut** across the rows; every 10 cells, the size of the meter above. Pieces numbered 1, 2, ½. Then **type**.
   Check reads the box (Core `work`).
4. **"Inches are small, so it takes more of them."** or **"Meters are big, so it takes fewer of them."** The record in the chapter colour.

## Scenarios
| | Example | Cell | Picture on screen | What changes |
|---|---|---|---|---|
| A | 3 ft = ? in | 1 in | 24 × 8 | The main one: three rows of 12. |
| B | 4 yd = ? ft | 1 ft | 6 × 11 | Short rows of 3: the picture is small, so cells are 3 × 3 here (9 × 15). |
| C | 2 h = ? min | 6 min | 20 × 5 | Rows of 10; opening counts in sixes (6, 12 … 60). |
| D | 250 cm = ? m | 10 cm | 40 × 9 | Small to big: 25 cells, one row of 20 and one of 5; cut every 10: 2 and ½. |
| E | 48 oz = ? lb | 1 oz | 32 × 12 | Small to big, rows of 16; the cut gives 3. |
| F | 3.5 kg = ? g | 100 g | 20 × 11 | The last row is half (5 cells). |
| G | 12 ft = ? in | 1 in | 24 × 36 | The tallest: twelve rows. |
| H | a story (rope, flour, a road trip, a fish tank) | | | Told on the rows above; the record still holds the problem. |

**Mock-up, A (3 ft = ? in), step 3, one more row to open.** Half scale: one character is 2 squares; `o` an opened inch.

```
 0  Open each foot.
 1  Then write how many.
 3  oooooooooooo  12            3 ft = 3 × 12 = [ _ _ ] in
 4                                   1 ft = 12 in
 5  oooooooooooo  24
 7  [   1 ft   ]
 9  Check
```

## Core changes (`ConvertUnits`)
- `ask`: **drop it.**
- `one`: say **"Tap one \(p.one) to open it."**; answered by the tap.
- `more`: say **"More \(p.target) or fewer?"**; choices **"More"**, **"Fewer"**.
- `work`: say **"Open each \(p.one). Then write how many."** or **"Cut it into \(p.many). Then write how many."** Typed.
- `done`: say **"\(cap(p.small)) are small, so it takes more of them."** or **"\(cap(p.many)) are big, so it takes fewer of them."**
- Add an abbreviation to each unit pair for the record.
- Picture keys: `opened` (from the taps), `cut` (from the Cut), `sign` 1. `fill/one/ask/total/rows` go.

## Open
- None.
