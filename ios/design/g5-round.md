# Brief: Rounding decimals (`g5-round`)

**Kits:** number line as zoom levels (first lesson of the number-line kit); the number in columns as the record.
**Status:** redesigned 20 Oct to rule 0 and the Unit cubes standard, replacing the built version (one small line of 3-square ticks beside the number, digits typed). To be rebuilt first, with `add`.

## The hero, and one unit
- **The line is the problem, and it zooms.** The first line runs from the whole number to the next (3 to 4) and is **50 squares long: one tenth = one block** (5 squares), ticks on the strong lines. One block of it opens into the next line, also 50 squares: **one hundredth = one block**. A hundredth opens into thousandths the same way. Every level is the one above it seen ten times closer, and the magnifier (two dashed lines from the opened block's edges to the next line's ends) shows it.
- The levels stack down the screen, 12 squares apart: room for the labels above (the number's mark) and below (the ends).
- **The answer is seen:** the last line runs from the number rounded down to the number rounded up (3.47 to 3.48), halfway is its middle strong line, and the number's mark sits on it. Which end is closer is plain.

## Hands
- **Tap a cell:** tap the block the number is in (once per level). That block's place is the digit.
- **Drag a length:** drag the number's mark to the closer end; it snaps to the two ends only, and the end it's heading for lights once it passes halfway.
- **Typed:** the rounded number, after `≈` in the record.

## Layout on the screen (68 × 45 squares)
- Rows 0–3: what to do.
- Lines at columns 0–50: level 1 on row 8, level 2 on row 20, level 3 on row 32 (only as many as the problem needs: two for tenths, three for hundredths). Each end labelled under its tick; the number's mark labelled above it.
- The record, columns 53–67: the number, 2 squares a digit, the point on a grid line, level with the first line; the place's digit gets an underline when found, the next digit a ring; `≈` and the box level with the last line.
- Check under the lines.
- The picture takes 50 of the 68 squares across and 26–38 down.

## Steps
1. **"Round to the nearest hundredth."** (as built). Level 1 draws in (3 to 4). For a hundredths problem the tenth isn't asked: its block lights and opens into level 2 as part of the drawing-in.
2. **"Tap the hundredth 3.476 is in."** (or "tenth"). **Tap a cell** on the place's line. A wrong block shows its range under it ("3.45 to 3.46") and Core's digit slips fire. When right, it lights, the magnifier draws, and the next line draws in from 3.47 to 3.48 with its ends labelled: the two possible answers. The record underlines the 7.
3. **"Tap the thousandth it's in."** **Tap a cell** on the new line. When right, the number's mark (a dot) sits on that block's left line (3.476 is exactly there), the middle line is labelled 3.475, and the record rings the 6.
4. **"Drag it to the closer end."** Small line: "Then write it." **Drag**, then **type** the rounded number after `≈` (to the place: 5.0, not 5). Check reads the box; a wrong end is seen on the line, and the typed slip says why.
5. **"6 is 5 or more, so round up."** (Core's narration); the hop from the mark to its end is drawn, and the record reads `3.476 ≈ 3.48`.

## Scenarios
| | Example | Levels | Picture on screen | What changes |
|---|---|---|---|---|
| A | 6.432 to the nearest tenth | 2 | 50 × 26 | 6 to 7, then 6.4 to 6.5; the mark is in block 3: stays, 6.4. |
| B | 3.476 to the nearest hundredth | 3 | 50 × 38 | The main one. |
| C | 51.647 to the nearest hundredth | 3 | 50 × 38 | A two-digit whole: the first line is 51 to 52. |
| D | 4.962 to the nearest tenth | 2 | 50 × 26 | A 9 rolls over: the last line is 4.9 to 5.0; typed 5.0. |
| E | 2.350 to the nearest tenth | 2 | 50 × 26 | Exactly halfway: the mark sits on the middle line, snaps to the up end only; the last words add "Halfway rounds up." |

**Mock-up, B, step 4.** Half scale: one character is 2 squares. `|` a block line on the line, `o` the mark.

```
 0  Drag it to the closer end.
 1  Then write it.
 3                                                  3 . 4 7 6
 4  |..|..|..|..|[]|..|..|..|..|..|                    -   o
 5  3                          4
 6               \ /
 9  |..|..|..|..|..|..|..|[]|..|..|
10  3.4                       3.5
11                      \ /
15  |..|..|..|..|..|..o..|..|..|..|  ->          ≈ [ _ . _ _ ]
16  3.47         3.475          3.48
18  Check
```

## Core changes (`RoundDecimals`)
- `findDigit`: say **"Tap the \(p == 1 ? "tenth" : "hundredth") \(V) is in."**; answered by the tap (`x` = the block's place, 0–9).
- `nextDigit`: say **"Tap the \(p == 1 ? "hundredth" : "thousandth") it's in."**; answered by the tap.
- `round`: say **"Drag it to the closer end."** with the hint line "Then write it."; typed as now.
- Picture keys, replacing `lo/hi/tick/lit/halfway`: `levels` (lines open), `tapped` (from the taps), `mark` 1, `dragged` (from the drag), `hop` 1. Each line's ends come from N and p.

## Open
- None.
