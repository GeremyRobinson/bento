# Brief: Volume of a box (`g5-volume`)

**Kits:** Unit cubes itself (the cubes master, the tilt, layers rising). This lesson is Unit cubes with the numbers growing and faster hands.
**Status:** designed 20 Oct to rule 0 and the Unit cubes standard, waiting on G.

## The hero, and one unit
- **The box is the problem.** **One cube = one block (5 × 5 squares) = 1 cm³**, G's rule. It opens flat: the box's floor as a dashed outline on the strong lines, its length under it and width on its left ("4 cm", "3 cm"), as in Unit cubes.
- **The answer is counted:** the floor fills with squares, the paper tilts, layers rise, each layer's running count beside it (12, 24).

## Hands
- **Drag a length:** drag from the floor's corner across it; the squares fill as the drag passes over them, snapping a block at a time (faster than Unit cubes' tap per square; Unit cubes taught that).
- **Build up:** drag up on the floor; each block of drag raises one more layer (0.7 s each), up to the height.
- **Typed:** the volume.

## Layout on the screen (68 × 45 squares)
- Rows 0–3: what to do (one line, a small second line).
- The floor at columns 5–45 (up to 8 blocks), rows 5–45 at the most (8 × 8 is 40 × 40; the camera eases out to fit); usually 20 × 15 (4 × 3).
- The record, as Unit cubes: one short line under the words, written as it's found: `4 × 3 = 12 in a layer`, then `12 × 2 = [ ] cm³`.
- A live count under the floor; Check under it.
- The picture takes 20–40 of 68 across and 15–40 of 45 down, more once tilted.

## Steps
1. **"Cover the floor."** Small line: "Drag across it." **Drag a length**; the count reads "9 of 12". Check: the squares (Core `floor`, `x`). The record writes `4 × 3 = 12 in a layer`.
2. **"Build it 2 cm tall."** The paper tilts (Unit cubes' 0.9 s). **Build up**: each block of drag raises a layer, the running count beside it (12, 24). Then **type** in `12 × 2 = [ ] cm³`. Check (Core `stack`).
3. **"2 layers of 12 is 24."** (Unit cubes' sentence), and the record line under it: "Volume = 4 × 3 × 2 = 24 cubes." The paper goes flat again before leaving.

## Scenarios
| | Example | Picture on screen | What changes |
|---|---|---|---|
| A | 2 × 3 × 2 | 15 × 10 flat | The first three, 2–5 a side: countable cube by cube. |
| B | 4 × 3 × 2 | 20 × 15 flat | The main one (Unit cubes' own). |
| C | 8 × 8 × 6 | 40 × 40 flat | The biggest floor; the camera eases out; 6 layers of 64. |
| D | 3 × 2 × 6 | 15 × 10 flat, tall when built | The skill check's tallest box: the build up is the long move. |

**Mock-up, B, step 1.** Half scale: one character is 2 squares; a cube's square is 2.5 characters, drawn `[##]`.

```
 0  Cover the floor.
 1  Drag across it.
 3      [##][##][##][##]
 5  3   [##][##][##][  ]
 7      [  ][  ][  ][  ]
 9            4
10      9 of 12
11      Check
```

## Core changes (`VolumeOfBox`)
- `ask`: **drop it** (the floor is step 1; the box's sizes are its labels and the words).
- `floor`: say **"Cover the floor."**, hint line "Drag across it."; answered by the drag.
- `stack`: say **"Build it \(H) cm tall."**; camera tilts at its start (as now); typed.
- `done`: say **"\(H) layers of \(fmt(base)) is \(fmt(V))."** with the hint line **"Volume = \(L) × \(W) × \(H) = \(fmt(V)) cubes."** (as Unit cubes).
- Picture keys: `covered` (from the drag), `layers` (from the build up). `outline/floor/height` go.

## Open
- None.
