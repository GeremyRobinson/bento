# v2 lesson pass: 10th grade

Curriculum, 2026-10-13. For Development. It covers the 13 lessons in `web/src/curriculum/lessons/grade10/` (two of them, g10-sector and g10-arc, are built by `lessons/_geometry/circle-part.ts`), read on `origin/next` 453ec4b, together with the v2 learn and practice screens on Design's branch (5d17ed2).
It is content only: lesson text, the depends-on lists and the check recipes. Nothing here changes layout.

## How to read this

**Depends on** lists the lessons a child needs before this one. The lists can cross grades. The first id is the main build-up, so put it in today's single `pre`. The whole list is for Today's step-back.

**Skill check** is the recipe for the lesson's own check. Each item reads `i<N>`, meaning call the lesson's own `generate(rng, N)`. An item can add a `where` condition: redraw, up to 50 tries, until it holds.
- No 10th grade lesson has a story, so no item is a `story`.
- The default is 4 items, with no hints and one try per step, as in the plan.
- Shuffle the items.
- Every 10th grade lesson is wrapped in `withEasyStart`, and none of the generators reads `index` itself. So `i3` is a plain draw from the full range, and the `where` conditions pick the cases.
- The `where` names are the fields of each lesson's problem type (for example `x1`, `mx` in `MidProblem`, `t`, `r` in `CirclePartProblem`).

**Gating.** The same point as 5th grade: if "Next" needs every lesson in the list to be learned, a child who opens 10th grade first is sent back to 5th to 9th grade. I suggest a lesson from an *earlier grade* counts as learned until one of its checks comes back 0-2.

## 1. Depends on and skill checks

| Lesson | Depends on | Skill check (4 items) |
|---|---|---|
| g10-mid Midpoint | g6-mean, g7-addint | i3 where mx < 0; i3 where my < 0; i3 where x1·x2 < 0 or y1·y2 < 0 (the segment crosses an axis); i3. All four also need mx ≠ 0 and my ≠ 0. |
| g10-perp Perpendicular slopes | g8-slope | i3 where p > 0, r ≥ 2 and \|p\| ≥ 2; i3 where p < 0, r ≥ 2 and \|p\| ≥ 2; i3 where r = 1 and \|p\| ≥ 2 (a whole slope, a fraction answer); i3 where \|p\| = 1 and r ≥ 2 (a whole answer) |
| g10-dist Distance between points | g8-pyth, g8-slope | i3 where dx > dy; i3 where dx < dy; i3 where d ≥ 13; i3. All four also need x1 ≥ 1 and y1 ≥ 1. |
| g10-circle Equation of a circle | g10-dist, g8-roots | i3 where h > 0 and k < 0; i3 where h < 0 and k > 0; i3 where h < 0 and k < 0; i3 where r ≥ 5. All four also need r ≥ 2. |
| g10-polygon Angles in a polygon | g8-tri, g5-divide | i3 where n ≤ 6; i3 where 8 ≤ n ≤ 10; i3 where n ≥ 12; i3 where n ≥ 15 |
| g10-exterior Exterior angle | g8-tri, g7-angles | i3 where a + b < 90 (the outside angle is sharp); i3 where a + b > 120; i3 where a ≠ b; i3. All four also need a + b ≠ 90 and 2a + b ≠ 180. Keep the "Check with the far angles" step: it is the idea. |
| g10-similar Similar triangles | g7-scale, g5-multdec | i3 where k is 1.5 or 2.5, twice; i3 where k ≥ 3; i3 |
| g10-special Special right triangles | g9-radical, g8-pyth | i3 where t = 45; i3 where t = 30; i3 where t = 45 and s ≥ 7; i3 where t = 30 and s ≥ 7 |
| g10-trig Sine, cosine and tangent | g10-similar, g8-pyth | i3 where f = sin; i3 where f = cos; i3 where f = tan; i3 where the ratio simplifies (the triple is 6-8-10, 9-12-15 or 12-16-20). Needs the question fix in section 4, or the top and bottom steps don't test the idea. |
| g10-sector Area of a sector | g7-circarea, g5-fracof | i3 where t is 90 or 270 and r ≥ 3; i3 where t is 60 or 120; i3 where t = 45 and r ≥ 4; i3 where t = 180 and r ≥ 3 |
| g10-arc Arc length | g7-circum, g5-fracof | i3 where t is 90 or 270; i3 where t is 60 or 120; i3 where t = 45; i3 where t ≠ 180 |
| g10-surface Surface area of a box | g5-volume, g4-area | i3 where l, w and h all differ, twice; i3 where exactly two sides are equal and not 2; i3 where l, w and h are all 3 or more |
| g10-pyramid Volume of a pyramid | g8-cone, g5-volume | i3 where s is a multiple of 3 and h isn't; i3 where h is a multiple of 3 and s isn't; i3 where s ≥ 7; i3. All four also need s ≠ 4. |

Why some conditions are there:
- **g10-mid:** when x1 + x2 = 0, "Forgot to halve" gives 0, the right answer, so the slip can't be seen.
- **g10-dist:** with x1 = 0, adding instead of subtracting gives the right answer (x2 + 0 = x2 − 0).
- **g10-circle, g10-sector:** r = 1 makes "Forgot the square root" right (√1 = 1), and r = 2 makes "Squared as times 2" right (2² = 2 × 2).
- **g10-exterior:** when a + b = 90 the inside and outside angles are both 90°, and when 2a + b = 180 the "far angle" slip (180 − a) is right.
- **g10-surface, g10-pyramid:** with two sides of 2, adding is the same as multiplying (2 + 2 = 2 × 2), and with s = 4 the perimeter equals the area (4 × 4 = 16 = 4 × 4).
- **g10-perp:** a slope of ±1 flips to itself, so the flip step tests nothing. The recipe leaves it out.

Changes from today's `pre`:
- **g10-mid** gets g6-mean (was none). The heading is "Average each coordinate", and each step is the mean of two numbers.
- **g10-similar** gets g7-scale (was none). The lesson finds a scale factor and multiplies by it.
- **g10-surface** gets g5-volume (was none). It uses the same box, its length, width and height, and its faces.
- The other 10 keep their `pre` as the first id in the list.
- These three lessons set no `pre` in their own `index.ts` today. Add it there too (`grade10/g10-mid/index.ts`, `g10-similar/index.ts`, `g10-surface/index.ts`), so the module still matches its catalog entry. The parity test (`tests/parity/lessons.test.ts:29`) then needs a `pre` reason for each: g10-similar and g10-mid in `deviations/geometry.ts` or `fixes02-8-12.ts`, and g10-surface in `fixes02-8-12.ts:63`, which today is `all` with no `pre`.

## 2. Show the problem once

On the v2 stage the problem shows once (display, or lead). No 10th grade lesson repeats its problem word for word, but one display says the wrong thing.

- **g10-surface** (`grade10/g10-surface/index.ts:67-68`): the display "2 × 3 × 4" reads as a multiplication, and 2 × 3 × 4 is the box's *volume*, not its surface area. The note then has to explain what is really asked. Remove `displayNote` and add a `lead`:
  `A box is **${l}** by **${w}** by **${h}**. What is the total area of its 6 faces?`
  Keep `display` as it is: the lead replaces it on the stage, and the parity test compares it.

The other 12 are fine.
- The notes in g10-mid, g10-perp, g10-dist, g10-circle, g10-polygon, g10-similar, g10-special, g10-sector and g10-arc add the instruction ("Find the midpoint.", "Use 3.14 for π."), not a second copy.
- g10-exterior's note says what the two numbers are. g10-trig's note names the sides, and g10-pyramid's gives the formula. That is new information, not a repeat.
- No 10th grade lesson has a `picture` or counters on the stage.

## 3. Watch one: idea line and narration

In v2, Watch one prints each step's math line with its narration underneath, and speaks both. The rule for every line below: **the narration says what the step does or why, in words, and leaves the equation to the math line.** Lines stay under about 12 words.

- **The worked example** stays each lesson's `reference`.
- **The idea line** is `idea[0]`, one sentence. Every 10th grade lesson has one sentence today.
- **Captions** aren't shown in v2. Where a caption carried something worth keeping, it moves into a narration line below.
- Placeholders use the variable names already in each `explain()`. The examples are rendered for the reference problem.

### g10-mid ((2, 3) and (6, 9))
- Idea: keep it.
- points: `The midpoint sits halfway along the segment joining them.` Today's line repeats the math "(2, 3) and (6, 9)" word for word.
- mx: `Add the x's and halve: that's halfway across.`
- my: `Do the same with the y's. The midpoint is ${pt(mx, my)}.` For example, "…The midpoint is (4, 6)." This keeps the caption's point.

### g10-perp (m = 2/3)
- Idea: keep it.
- slope: keep it. ("Slope 2/3: 3 across and 2 up." explains the slope, it doesn't repeat "m = 2/3".)
- flip: `Turn the slope triangle a quarter turn: rise and run swap.` This is the caption's point.
- perp: `The turned line ${p > 0 ? "falls" : "rises"}, so the sign changes.` For example, "The turned line falls, so the sign changes." The idea line already says the slopes multiply to −1, so the "Check:" sentence goes (see section 4).

### g10-dist ((1, 2) to (4, 6))
- Idea: keep it.
- points: `How far apart are they, in a straight line?` Today's line repeats the math "(1, 2) to (4, 6)" word for word.
- dx: `How far across: the second x take away the first.`
- dy: `How far up, the same way. Across and up make a right angle.`
- sum: `They're the legs of a right triangle: square each and add.`
- d: `The distance is the long side, so take the square root.`

### g10-circle ((x − 2)² + (y + 3)² = 16)
- Idea: keep it.
- eq: keep it.
- center: `Each squared part is 0 at the center, so flip the signs.`
- r: `The right side is r², so take its square root.`

### g10-polygon (a regular 6-sided polygon)
- Idea: keep it.
- polygon: keep it.
- triangles: `Lines from one corner cut it into triangles: two fewer than the sides.`
- total: `Each triangle holds 180°.`
- each: `The ${n} angles are equal, so share the total out.` For example, "The 6 angles are equal, so share the total out."

### g10-exterior (50° and 60°)
- Idea (new): `A triangle's outside angle equals the two inside angles far from it, added.` Today's line only gives the reason for the middle step. The lesson's rule is in its heading ("Exterior = the two far angles added") and its last step, and the check keeps that step because it is the idea.
- triangle: `The side runs on past the third corner, making an outside angle.` Today's line starts with "Two inside angles are 50° and 60°", which contains the math line "50° and 60°".
- inside: `The three inside angles add to 180°, so take both off.`
- outside: `The outside angle and the third inside angle make a straight line.`
- check: `The two far angles add to the same. That's the shortcut.`

### g10-similar (small 4 and 6, big 8 and ?)
- Idea: keep it.
- triangles: `Same shape, so each big side matches a small side.`
- factor: `Divide a big side by its small partner: that's the scale factor.`
- missing: `Every side is ${f(k)} times as long, so scale the ${b} side too.` For example, "Every side is 2 times as long, so scale the 6 side too."

### g10-special (45°-45°-90°, leg 5)
- Idea: keep it.
- 45-45-90:
  - triangle: `Both legs are equal. Two of these triangles make a square.`
  - hyp: `It's the square's diagonal. Leg² + leg² is 2 leg², so times √2.`
- 30-60-90 (not the reference; shown for short leg 5):
  - triangle: `The short leg faces 30°. Two copies make an equilateral triangle, all sides ${hyp}.` For example, "…all sides 10."
  - hyp: `The short leg is half a side, the hypotenuse a whole side.`
  - long: `By Pythagoras, long leg² is ${hyp}² − ${s}², which is three ${s}²'s.` For example, "By Pythagoras, long leg² is 10² − 5², which is three 5²'s."

### g10-trig (sin A, sides 3, 4, 5)
- Idea: keep it.
- triangle: `Stand at angle A: opposite is across, adjacent is beside it.`
- top: `${f} uses the ${topName} side on top.` For example, "sin uses the opposite side on top." (`f` here is the problem's function, destructured in `explainTrigRatio`.)
- bottom: `On the bottom goes the ${botName}.`
- ratio: when `n === top`, `${top} and ${bot} share no factor, so it's in lowest terms.` Otherwise `Divide the top and the bottom by ${top / n}.` For example, "3 and 5 share no factor, so it's in lowest terms."

### g10-sector and g10-arc, in `_geometry/circle-part.ts` (sector: radius 4, 90°; arc: radius 5, 180°)
- Ideas: keep them.
- circle: keep it.
- fraction: `A full turn is 360°, so ${t}° is this share of it.` For example, "A full turn is 360°, so 90° is this share of it."
- whole:
  - sector: `First the whole circle's area, using 3.14 for π.`
  - arc: `First the whole way around, using 3.14 for π.`
- part: `The ${sector ? "slice" : "arc"} is that share of the whole.` For example, "The slice is that share of the whole."

### g10-surface (2 by 3 by 4)
- Idea: keep it.
- top: `Top and bottom: length times width.`
- front: `Front and back: length times height.`
- side: `The two sides: width times height.`
- total: `Each face has a twin you can't see, so double the three.` This drops the answer at the end of today's line.

### g10-pyramid (square base 6, height 5)
- Idea (new): `A pyramid holds exactly a third of the box with the same base and height.` Today's line says three pyramids fill the box. That is true of the volume, but three copies of this pyramid can't be packed into its box, so a careful reader is misled.
- base: `The base is a square: the side times itself.`
- box: `Stack the base as high as the pyramid to make its box.`
- third: `The pyramid holds a third of that box.`

## 4. Maths and wording errors

- **g10-trig, `index.ts:37` and `:40`: the questions give the answer away.** For cos the top question says "Cosine uses the adjacent side on top", and for tan the bottom question says "Tangent uses the adjacent side on the bottom". For sin, the top question is "Which side is opposite angle A?" and the note (`:91`) says "side 3 is opposite angle A". So the two steps test reading, not SOH CAH TOA, and neither does a check built from them. Fix:
  - question (37): `Which side goes on top of ${f} A?`
  - question (40): `Which side goes on the bottom of ${f} A?`
  - note (91), so it uses the words the steps and hints use: `Right triangle: side ${p.a} is opposite angle A, side ${p.b} is adjacent to it, and ${p.c} is the hypotenuse.`
  - The hints already teach the rule ("SOH CAH TOA: sin = opposite/hyp…"), so they stay.
- **g10-perp, `explanation.ts:39`:** "Check: 2/3 × −3/2 = −1" puts a negative straight after ×. Write it `2/3 × (−3/2)`. The new perp line in section 3 drops this sentence, so nothing is left to fix once it is in.
- **g10-surface, `index.ts:67`:** the display "2 × 3 × 4" is the volume sum (section 2).
- **g10-pyramid, `index.ts:41`:** the idea line overstates (section 3).
- **g10-exterior, `index.ts:45`:** the caption `${a} + ${b} = ${out}°` has no degree signs on a and b. Captions aren't shown in v2, so drop it, or write `${a}° + ${b}° = ${out}°`. Also `:60` ends the narration with a stray space; the new line replaces it.

No answer is wrong in any of the 13 lessons. A few slips match the right answer for small or special numbers (for example g10-mid when x1 + x2 = 0, g10-circle with r = 1). The right answer is checked first, so practice is fine; the check recipes above avoid those cases.

## Checks for Development
- No test pins the idea text. If a snapshot pins narration, regenerate it. Answers and steps are unchanged, apart from the g10-trig questions and note.
- After the change, check that no Watch one narration line contains its own math line, for these 13 lessons (Learn.tsx `saysMath` does this test already). Today g10-mid "points", g10-dist "points" and g10-exterior "triangle" fail it.
- Add `pre` to the catalog and the `index.ts` of g10-mid, g10-similar and g10-surface, with a parity `pre` reason for each.
- The parity test also compares the note and the step questions (`lessons.test.ts:68`), so g10-surface (`note`, `show`) and g10-trig (`note`, `prompt`) need a reason each.
