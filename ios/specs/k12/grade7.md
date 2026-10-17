# v2 lesson pass: 7th grade

Curriculum, 2026-10-13. For Development. It covers the 13 lessons in `web/src/curriculum/lessons/grade7/`, read on `origin/next` 453ec4b, together with the v2 learn and practice screens on Design's branch (5d17ed2).
It is content only: lesson text, the depends-on lists and the check recipes. Nothing here changes layout.

## How to read this

**Depends on** lists the lessons a child needs before this one. The lists can cross grades. The first id is the main build-up, so put it in today's single `pre`. The whole list is for Today's step-back.

**Skill check** is the recipe for the lesson's own check. Each item reads `i<N>`, meaning call the lesson's own `generate(rng, N)`. An item can add a `where` condition: redraw, up to 50 tries, until it holds.
- No 7th grade lesson has a story, so no item here is a `story` item.
- The default is 4 items, with no hints and one try per step, as in the plan.
- Shuffle the items.
- Several 7th grade generators ignore the index (g7-discount, g7-pctchange, g7-addint, g7-eq, g7-distribute, g7-angles). For those, `i0` is the whole range and the `where` conditions do the work.

**Gating** follows the suggestion in the 5th grade spec: a lesson from an earlier grade counts as learned until one of its checks comes back 0-2.

## 1. Depends on and skill checks

| Lesson | Depends on | Skill check (4 items) |
|---|---|---|
| g7-prop Solve a proportion | g6-ratio, g4-equiv | i0; i0 where a > b; i4 where k is not whole (one part is a half), twice |
| g7-scale Scale drawings | g6-ratio, g3-divfacts | i3 where c ≥ 2; i3 where c ≥ 2 and g ≥ 5; i3 where c ≥ 3; i3 |
| g7-discount Discounts, tax and tips | g6-pctof | i0 where off and p is 15 or 25; i0 where not off and p is 15 or 25; i0 where off; i0 where not off. Off and on are mixed, which is the point of this lesson. |
| g7-pctchange Percent change | g7-discount, g5-pow10 | i0 where up; i0 where not up; i0 where not up and p ≥ 50 (dividing by the new number goes badly wrong); i0 where up and p is 25 or 75 |
| g7-addint Adding integers | g6-numline | i0 where a < 0 and b < 0; i0 where the signs differ and a + b > 0; i0 where the signs differ and a + b < 0; i0 where a < 0, b > 0 and a + b < 0 |
| g7-subint Subtracting integers | g7-addint | i0 (positive minus a negative, the idea); i3 where b > 0 and b > a (lands below 0); i3 where a < 0 and b < 0; i3 where a < 0 and b > 0 |
| g7-mulint Multiplying and dividing integers | g7-addint, g3-facts, g3-divfacts | i3 where not div and the signs of a and b differ; i3 where not div, a < 0 and b < 0; i3 where div and a < 0 (the shown numbers differ in sign); i3 where div, a > 0 and b < 0 (both shown numbers negative) |
| g7-eq Two-step equations | g6-onestep | i0 where b is not a multiple of a, three times (dividing first would give a fraction, so the order shows); i0 where x ≥ 8 |
| g7-distribute Distribute and combine | g3-split, g6-eval | i0; i0 where c = 1 (the hidden 1 in x); i0 where a ≥ 6 and b ≥ 6; i0 |
| g7-circum Circumference | g5-multdec | i0 where r ≥ 3; i3 where r ≥ 3; i3 where r ≥ 7; i3 where r ≥ 3 |
| g7-circarea Area of a circle | g7-circum, g6-expo | i0 where r ≥ 3; i3 where r ≥ 3; i3 where r ≥ 7; i3 where r ≥ 3 |
| g7-angles Complementary and supplementary | g4-angles | i0 where sup; i0 where not sup; i0 where sup and a > 90; i0 where not sup. Keep the "What do they add up to?" step, which is the idea. |
| g7-prob Probability | g4-equiv, g6-gcf | i0; i3 where want/T simplifies, twice; i3 where it doesn't |

`r ≥ 3` in the circle checks: at r = 2, 2 × r and r × r are both 4, so a child who mixes them up still gets it right. See section 4.

Changes from today's `pre`:
- **g7-scale** moves from g7-prop to g6-ratio. The steps count groups and scale them up, which is g6-ratio's method. There is no fraction and no half part.
- **g7-distribute** moves from g6-gcf to g3-split. Distributing is the same "split the rectangle" move g3-split makes with numbers. g6-gcf is the reverse, and harder.
- **g7-circum** moves from none to g5-multdec. The new idea needs no lesson before it, but every answer is a whole number times 3.14.
- **g7-prob** moves from none to g4-equiv. The answer is a fraction in lowest terms, and g6-gcf finds the number to divide by.
- The rest keep their `pre` as the first id in the list.

## 2. Show the problem once

On the v2 stage the problem shows once (display, or lead, or story). All 13 are fine. None has a lead, story, counters or picture, so only display and displayNote can meet.
- g7-scale, g7-discount, g7-pctchange, g7-angles and g7-prob: the note asks the question or adds a fact the display doesn't hold ("two towns are 8 cm apart", "25% off", "supplementary", "pick one without looking").
- g7-distribute's "Simplify." and the circles' "Use 3.14 for π." add the instruction, not a second copy of the problem.

## 3. Watch one: idea line and narration

In v2, Watch one prints each step's math line with its narration underneath, and speaks both. Most narrations today end by repeating their own math line ("Ignore the signs: 6 × 4 = 24" under "6 × 4 = 24"), so the child reads and hears everything twice. The rule for every line below: **the narration says what the step does or why, in words, and leaves the equation to the math line.** Lines stay under about 12 words.

- **The worked example** stays each lesson's `reference`. "Watch again" already draws a fresh one.
- **The idea line** is `idea[0]`, one sentence. Every 7th grade lesson has one sentence today.
- **Captions** aren't shown in v2. Where a caption carried something worth keeping, it moves into a narration line below.
- Placeholders use the variable names already in each `explain()`. The examples are rendered for the reference problem.
- State-0 lines (g7-addint, g7-subint, g7-eq, the circles, g7-angles, g7-prob) keep their place. The screen bug that shows them late is being fixed on the screen side.

### g7-prop (3/4 = x/20)
- Idea: keep it.
- cross: `${b} equal boxes make ${f(b * k)}, so divide to find one box.` For example, "4 equal boxes make 20, so divide to find one box."
- divide: `The top is ${count(a, "box", "boxes")} of the same size.` For example, "The top is 3 boxes of the same size." This drops the cross-multiplying check, which brings back the method the steps replaced.

### g7-scale (2 cm = 5 km, towns 8 cm apart)
- Idea: keep it.
- groups: `Cut the map line into groups of ${c} cm.`
- real: `Each group is ${km} km for real.` This carries the caption ("Each 2 cm on the map is 5 km for real").

### g7-discount ($80, 25% off)
- Idea (new): `A discount takes part of the price away, and a tip adds part on.` Today's line is g6-pctof's idea. What is new here is the second step.
- percent: `Find 10% first: $${f(P / 10)}. Then build up to ${p}%.` When p is 10: `10% is one tenth of the price.` For example, "Find 10% first: $8. Then build up to 25%."
- total: `A discount takes money off the price.` or `A tip adds money on to the price.`

### g7-pctchange (50 → 65)
- Idea: keep it.
- change: `It went ${up ? "up" : "down"}: find the gap between the two.`
- divide: `Compare the change with where you started, ${O}.`
- percent: `Move the point two places right: a ${p}% ${up ? "increase" : "decrease"}.` For example, "Move the point two places right: a 30% increase."

### g7-addint (−7 + 12)
- Idea: keep it.
- start: keep it. "Start at −7. Adding 12 moves 12 to the right." says what the line means, not the line.
- size: `Same signs: the steps pile up, so add the sizes.` or `Different signs: the steps toward 0 cancel, so subtract the sizes.`
- sign:
  - same: `Both are negative, so the answer is negative.` (see section 4)
  - sum is 0: keep it.
  - else: keep it. "12 is farther from 0 and it's positive, so the answer is 5."

### g7-subint (5 − (−3))
- Idea: keep it.
- start: keep it.
- opp: `Flip the sign: the same distance from 0, on the other side.`
- add: `Now add: from ${f(a)}, move ${B} ${dir}.` For example, "Now add: from 5, move 3 right."

### g7-mulint (−6 × 4)
- Idea: keep it.
- size: div ? `Ignore the signs: ${jumps} ${verb(count, "makes", "make")} ${reach}.` : `Ignore the signs: ${jumps}.` For example, "Ignore the signs: 4 jumps of 6."
- sign: keep it. It gives the reason, and the jump sentence for ÷ is worth keeping.

### g7-eq (3x + 5 = 20), in `explainTwoStep`
- Idea: keep it.
- balance: `The pans balance. Undo the + ${f(b)} first, then the × ${f(a)}.` This carries the caption. Today's line reads the equation out in words.
- undo-add: `Take ${f(b)} off both pans.`
- undo-mul: `Split both pans into ${f(a)} equal groups.`
- check: `Put ${f(x)} back in for x: the pans still balance.`

### g7-distribute (3(x + 4) + 2x), in `explainDistribute`
- Idea: keep it.
- distribute: `Multiply the ${a} outside by both x and ${b}.`
- combine: `${a}x and ${coef(c, "x")} are both x strips, so add them.` This carries the caption's "the 2x strip lines up with the x part".
- simple: `The x terms first, then the plain number.`

### g7-circum (radius 5), in `explainCircumference`
- Idea: keep it.
- circle: `The radius runs from the middle to the edge.`
- diameter: `The diameter goes all the way across: two radii.`
- times-pi: `Unroll the edge: it's about 3.14 diameters long.`

### g7-circarea (radius 3), in `explainCircleArea`
- Idea: keep it.
- circle: `The radius runs from the middle to the edge.`
- square: `Build a square on the radius, ${r} by ${r}.` For example, "Build a square on the radius, 3 by 3."
- times-pi: `The circle holds about 3.14 of those squares.`

### g7-angles (35°, supplementary), in `explainAnglePair`
- Idea: keep it.
- pair: keep it.
- total: `Supplementary angles make a straight line.` or `Complementary angles make a right angle.` This drops the ": 180°" that the math line already shows.
- missing: `The other angle is what's left.`

### g7-prob (3 red, 5 blue, 2 green; red), in `explainProbability`
- Idea (new): `A chance is the ways to win out of all the ways there are.` It matches the step names ("Ways to win", "All the ways"), and "winners out of everything there is" is hard to read.
- bag: `You pick one without looking.`
- want: `The ${name} ones are the ways to win.`
- all: `Every marble counts, whatever its color.`
- chance: `Ways to win on top, all the marbles on the bottom.` Then, when `chance` is not `${want}/${T}`: ` Then simplify.`

## 4. Maths and wording errors

- **g7-addint: "Two negatives make a negative"** at `web/src/curriculum/lessons/grade7/g7-addint/index.ts:32` (hint) and `:64` (narration). It is true for adding, but the next lesson, g7-mulint, teaches that two negatives make a positive. The same words for opposite rules will mix children up. Hint: `Both numbers are negative, so the answer is negative.` Narration: as in section 3.
- **Circles at r = 2.** `g7-circum/index.ts:59` and `g7-circarea/index.ts:65` draw r from 2-5 for the first three problems. At r = 2, 2 × r = r × r = 4. In g7-circarea a child who doubles instead of squaring is marked right, and the known mistake "Squared as times 2" (`:28`) can never fire. Change `rng.int(2, 5)` to `rng.int(3, 5)` and `rng.int(2, 12)` to `rng.int(3, 12)` in both. The references (r = 5, r = 3) stay valid.
- **g7-scale: step label** at `g7-scale/index.ts:24`. "How many map units?" while the hint, the picture and Watch one all say "groups". Make it `How many groups?`
- **g7-discount: title promises tax.** The title (`g7-discount/index.ts:87`, `catalog.ts:130`) is "Discounts, tax and tips", but the generator (`:21`) only makes discounts and tips. The legacy fixtures pin the title (`tests/fixtures/legacy/_catalog.json:785`, `g7-discount.json`), so don't rename it. **Updated 2026-10-13 (Copy also flagged it): add tax instead.** Sales tax belongs in this lesson (7th grade percent problems include tax), and the maths is the same as a tip.
  - Add `kind: "off" | "tip" | "tax"` to the problem. `restore` maps the old `off: true` to "off" and `off: false` to "tip", so saved problems still load.
  - The generator picks off half the time, and tip or tax a quarter each.
  - Tax note: `Add ${p}% sales tax. What's the total?`
  - Tax total hint: `Tax adds money on.`
  - Tax wrong-way slip: label "Subtracted the tax", message `Tax adds money on: add.`
  - Keep tax rates to the low end of RATES (10, 15 or 20), so the numbers look like real sales tax.
  - Watch one for tax uses the tip lines with "tax" in place of "tip".
  - The skill check's two "not off" items stay `where not off`, so they draw tips and tax.

No other errors found. I checked every answer, known mistake and narration against the reference problems.

## Checks for Development
- No test pins the idea text. A grep of the two changed ideas on `next` finds only the lesson files. If a snapshot pins narration, regenerate it. Answers and steps are unchanged, apart from the g7-scale label and the circle radius range.
- After the change, check that no Watch one narration line contains its own math line, for these 13 lessons. `saysMath` in `Learn.tsx` already does this test, so it can run over every lesson's reference.
