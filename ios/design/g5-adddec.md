# Brief: Adding decimals (`g5-adddec`)

**Kits:** place value with zoom (new here: a whole is a square; opened, it is a 10 × 10 grid of hundredths) and columns as the record (Multiply's parts under the line, a plus, a second line, the total).
**Status:** designed 20 Oct to rule 0 and the Unit cubes standard, waiting on G.

## The hero, and one unit
- **Each number is built in place value.** Its whole part as squares, **one square = 1**, a ten as a strip of 10, tens stacked one under another (99 is 9 strips and 9 squares, 10 × 10). Under it, its part after the point as an **opened whole**: a 20 × 20 grid of 10 × 10 cells, **one hundredth = a 2 × 2 cell**, one tenth = a column of 10 cells. The opened whole is joined to the place it came from by the magnifier (two dashed lines), so it reads as one whole seen close, never as a hundred.
- The two numbers stand side by side, a's on the left, b's on the right; the written-in 0 is seen: 0.5 is 5 columns, 50 cells.
- **The answer is counted:** at the end a's side holds the total: 1 ten, 6 ones, and 25 cells (2 columns and 5) of a new opened whole: 16.25.

## Hands
- **Drag** b's wholes onto a's; they snap in after a's ones. **Group:** when there are 10 or more ones, the child rings ten of them and they become a strip.
- **Drag** b's opened whole onto a's: it pours in a column at a time (then single cells), filling a's grid from where its shading stops. When a's grid is full: **tap it** to close it. It shrinks into one whole square (the camera's zoom, drawn) that joins a's ones, and a new empty grid opens under them for the rest to pour into.
- **Typed:** the total, in the record.

## Layout on the screen (68 × 45 squares)
- Rows 0–3: what to do.
- a's side, columns 0–20: its wholes (rows 5–16, bottom-aligned), its opened whole (rows 20–40). b's side, columns 25–45, the same. The magnifier runs from each whole part's last place down to its grid.
- The record, columns 50–66, from row 20 (level with the grids, since they are what's being added): a over `+ b`, 2 squares a digit, the points on one grid line with a faint dashed line down it; the written-in zeros in the chapter colour; a line; the wholes' sum; `+` the decimal parts' sum; a line; the total.
- Check under the picture, row 42.
- The picture takes 45 of 68 across and 36 of 45 down.

## Steps
1. **"Points under points. The 0 fills the empty place."** No move. Both numbers build in: wholes, then the grid filling column by column; the record writes itself with its zeros.
2. **"Put the wholes together."** Small line: "Drag them across." **Drag** b's wholes onto a's (and **Group** ten ones if there are 10 or more: the words become "Make a ten."). Check: the wholes counted (Core `whole`, `x`). The record writes the wholes' sum.
3. **"Pour the hundredths in."** **Drag** b's grid onto a's; if a's fills, "100 hundredths make a whole. Tap it." and the child **taps** it closed. Check: the hundredths counted, the closed whole as 1 (Core `decimal`, `x` = 1.25). The record writes `+ 1.25`, the 1 ringed: that's the closed whole.
4. **"Add the two rows."** **Type** the total in its box in the record. a's side already shows it; after Check it lights and its parts are counted: "1 ten, 6 ones, 25 hundredths".
5. **"Points in a line, so hundredths add to hundredths."** The record's total in the chapter colour.

## Scenarios
| | Example | Picture on screen | What changes |
|---|---|---|---|
| A | 4.6 + 2.35 = 6.95 | 45 × 30 | Ones only; the pour leaves 95 cells; nothing to close. |
| B | 12.5 + 3.75 = 16.25 | 45 × 36 | The grid fills and is closed into a whole; 25 pour into a new grid. |
| C | 47.8 + 36.57 = 84.37 | 45 × 40 | 13 ones: "Make a ten."; the grid fills too. Tallest wholes (8 strips). |
| D | 23 + 5.06 | 45 × 36 | a is whole: two zeros written, its grid empty; b's pours in. |
| E | a story (Maya's km) | 45 × 36 | The story on the rows above; the sign picked first, as in Adding fractions. |

**Mock-up, B (12.5 + 3.75), step 3, mid-pour.** Half scale: one character is 2 squares. `=` a ten strip, `o` a one, `#` a's hundredths, `/` b's poured in, `.` empty.

```
 0  Pour the hundredths in.
 1  Drag them across.
 4  ==========                ooo
 5  oo
 8     \  /                     \ /
10  #####///..          ///////..           1 2 . 5 0
11  #####///..          ///////..         +   3 . 7 5
12  #####///..          ///////..         ---------
13  #####///..          ///////..           1 5
14  #####///..          //////...
15  #####///..          //////...
16  #####///..          //////...
17  #####///..          //////...
18  #####///..          //////...
19  #####///..          //////...
21  Check
```
(b's wholes have joined a's: 1 ten and 5 ones, shown here before the drag for clarity.)

## Core changes (`AddDecimals`)
- `ask`: say **"Points under points. The 0 fills the empty place."**
- `whole`: say **"Put the wholes together."**; answered by the drag (and group): `x` = the wholes counted.
- `decimal`: say **"Pour the hundredths in."**; answered by the pour (and close): `x` = the hundredths counted, plus 1 for a closed whole.
- `total`: say **"Add the two rows."** Typed.
- `done`: say **"Points in a line, so hundredths add to hundredths."**
- Picture keys, replacing `lineUp/lit/whole/decimal/carry/total`: `merged` 1, `grouped`, `poured` (cells moved, from the drag), `closed` 1, `total` 1.

## Open
- None.
