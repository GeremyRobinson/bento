# v2 lesson pass: 3rd grade

Curriculum, 2026-10-13. For Development. It covers the 18 lessons in `web/src/curriculum/lessons/grade3/`, read on `origin/next` 3ccaa07, together with the v2 learn and practice screens on Design's branch (e2e3154).
It is content only: lesson text, the depends-on lists and the check recipes. Nothing here changes layout. Section 5 lists a few places where a lesson's beat numbers don't fit the v2 Watch one list; those are small changes inside `explain()`, not screen changes.

## How to read this

Same rules as the 5th grade spec (`grade5.md`).

**Depends on** lists the lessons a child needs before this one. The lists can cross grades. The first id is the main build-up, so put it in today's single `pre`. The whole list is for Today's step-back.

**Skill check** is the recipe for the lesson's own check. Each item reads `i<N>`, meaning call the lesson's own `generate(rng, N)`. An item can add a `where` condition: redraw, up to 50 tries, until it holds.
- `story` means show that item as the lesson's story, which tests whether the child sees the operation in words.
- The default is 4 items, with no hints and one try per step, as in the plan.
- Shuffle the items, but put a `story` item last.

**Gating:** the 5th grade spec's suggestion holds here too. A lesson from an earlier grade counts as learned until one of its checks comes back 0-2.

**Variables in `where`:** they are the problem's own fields (for example `a`, `b`, `kind`), or a value named in brackets with the function that gives it (for example `parts(p)` in g3-elapsed).

## 1. Depends on and skill checks

| Lesson | Depends on | Skill check (4 items) |
|---|---|---|
| g3-facts Multiplication facts | g2-arrays, g2-skip | i3 where a ≠ b; i3 where a ≥ 6 and b ≥ 6 and a ≠ b; i3 where a ≠ b; i3 story. Every item keeps the turn-around step, so no squares. |
| g3-divfacts Division facts | g3-facts | i3 where b ≥ 6; i3 where a ÷ b ≥ 6; i3; i3 story |
| g3-split Multiply by breaking apart | g3-facts | i3 where b ≥ 8; i3 where a ≥ 6; i3; i3 story |
| g3-mult10 Multiply by multiples of 10 | g3-facts, g2-hundreds | i3 where a × (t ÷ 10) < 10; i3 where a × (t ÷ 10) ≥ 10; i3 where a × (t ÷ 10) is a multiple of 10 (like 5 × 40 = 200); i3 story |
| g3-twostep Two-step word problems | g3-facts, g3-divfacts | i3 where kind = 0; i3 where kind = 1; i3 where kind = 2; i3 where kind = 2. No `story` (the lesson is all `lead`). |
| g3-round Rounding to 10 and 100 | g2-hundreds | i3 where to = 10 and it rounds up; i3 where to = 100 and it rounds down; i3 where to = 100 and it rounds up; i3 where n is exactly halfway (n = mid from `roundParts(p)`) |
| g3-addsub Add and subtract within 1000 | g2-within1000, g2-subregroup | i3 where s = 1 and a jump makes a new ten or hundred; i3 where s = −1 and a jump needs a trade; i3 where s = −1; i3 story |
| g3-unitfrac Unit fractions | g2-shares | i3 where k = 1; i3 where k ≥ 2; i3 where k ≥ 2 and b is 6 or 8; i3 |
| g3-fracline Fractions on a number line | g3-unitfrac | i3 where w = 1; i3 where w = 2 (the point is past 1); i3 where b is 6 or 8; i3 |
| g3-fraccompare Comparing fractions | g3-unitfrac | i3 where kindOf = "bottom"; i3 where kindOf = "top"; i3 where kindOf = "top" and a ≥ 2; i3 where kindOf = "equal". Keep both tap steps: they are the idea. |
| g3-area Area by counting squares | g2-arrays, g3-facts | i3; i3 where l ≥ 7; i3 where w ≥ 6; i3 |
| g3-perim Perimeter | g2-measure, g2-regroup | i3 where kind = 0; i3 where kind = 1; i3 where kind = 2; i3 where kind = 0 |
| g3-elapsed Elapsed time | g2-time5 | i3 where m1 + m3 < 60; i3 where m1 + m3 > 60; i3 where it crosses noon (H1 ≤ 12 and H2 > 12); i3. m1, m3, H1 and H2 come from `parts(p)`. |
| g3-mass Grams and kilograms | g3-addsub, g3-divfacts | i3 (pick the unit and a guess); i4 (read a dial between labels); i5 (story); i5 where op is 2 or 3 (× or ÷ story). The kind follows the index, so no `where` on kind is needed. Keep both tap steps. |
| g3-liters Liters | g3-mass, g3-divfacts | i4 where step ≥ 2; i4 where step = 1; i3 (story); i5 where op is 2 or 3 (× or ÷ story) |
| g3-graphs Scaled picture and bar graphs | g2-bargraph, g2-skip | i4 (picture graph, how many more); i5 (bar graph by 10s, together); i7 (bar graph by 2s, how many more) where a bar ends between lines (counts[x] or counts[y] is odd); i8 (picture graph, together) where scale = 2 and counts[x] is odd (a half picture) |
| g3-lineplot Line plots with halves and fourths | g3-fracline, g2-lineplot | i0 (halves on a ruler); i2 where to = 4 (fourths on a ruler); i3 (which length came up most); i5 (how many in a stack). Keep the tap step on i3. |
| g3-quads Quadrilaterals | k-shapes | i3 (square or rectangle, with the "also" question); i4 where shape = 2 (rhombus); i8 where shape = 4 (trapezoid); i9 where shape = 3 (parallelogram). Every item is turned at random, which is part of the test. |

How the index sets the kind, for the lessons where it does:
- **g3-mass:** i3, i6 pick the unit; i4, i7 read a dial; i5, i8 are stories (`kind = index % 3`).
- **g3-liters:** i0 to i2 and every even index are jugs; every odd index from 3 is a story. So **i3 is a story** and i4 is a jug, as listed.
- **g3-graphs:** from i3, `type = index % 2` (1 = bar graph), `ask = index % 3` (0 read one, 1 how many more, 2 together) and a bar graph's scale is `SCALES[(index >> 1) % 3]`.
- **g3-lineplot:** i0 and i1 are halves on a ruler; an even index from 2 is a ruler (fourths 2 times in 3); an odd index from 3 is a line plot, with `ask = (index >> 1) % 2` (i3 tallest stack, i5 a stack).
- **g3-quads:** i0, i1, i2 are square, rectangle, trapezoid with the sides warm-up; every `index % 4 === 3` is a square or rectangle with the "also" question; the rest are `(index * 5 + 0 or 1) % 6`, so i4 is a rhombus or parallelogram, i8 a trapezoid or other, i9 a parallelogram or trapezoid.

Changes from today's `pre`:
- **g3-unitfrac** moves from g1-halves to g2-shares. g2-shares (halves, thirds and fourths) is the step right before; g1-halves is two grades back.
- **g3-perim** gets g2-measure (today none). The child adds lengths in cm, up to 54, so it needs measuring and adding with regrouping.
- The rest keep their `pre` as the first id in the list. Change `catalog.ts` and the lesson file together, since the parity test checks they match.

## 2. Show the problem once

On the v2 stage the problem shows once (display, or lead, or story). Five lessons say something twice, and one has a note that is never shown.

- **g3-unitfrac:** the display "shaded = ?" and the note "What fraction of the bar is shaded?" say the same thing. Remove `displayNote` and add a `lead`:
  `What fraction of the bar is shaded?`
  The picture still shows with a lead.
- **g3-fracline:** the display "point = ?" and the note "What fraction is at the point?" say the same thing. Remove `displayNote` and add a `lead`:
  `What fraction is at the point?`
- **g3-area:** the display "area = ?" and the note's "What is the area?" say the same thing. Keep the first sentence only. The note becomes:
  `Each square is one square unit.`
- **g3-mass, kind 0:** the display "Would you weigh a dog in grams or kilograms?" is word for word the first step's question, right under it. Ask the lesson's real question on the stage instead. Display for kind 0:
  `` `How heavy is a ${MASS_THINGS[p.thing]!.name}?` ``
- **g3-mass and g3-liters, stories:** the operation step's finished line is the whole story again, plus "(add)". The story is already the display, so the child reads it twice in practice, and twice in Watch one too. In `g3-mass/index.ts:154` and `g3-liters/index.ts:43`, pass a short line to `operationStep` instead of the story:
  g3-mass: `` `${withCommas(p.a)} ${o} ${withCommas(p.b)}` ``. g3-liters (numbers up to 50): `` `${p.a} ${o} ${p.b}` ``.
  The finished line then reads "230 + 150 (add)", which matches how practice shows its own story step (the display plus the operation).
- **g3-twostep:** fine on the stage, since the lead wins. Its `displayNote` (line 191) is the same text as `lead` and is never shown. Remove it so no one shows both later.

The other 12 are fine.
- g3-round's "Round 347 to the nearest hundred", g3-elapsed's "How much time goes by?", g3-perim's "Find the distance around the rectangle..." and g3-fraccompare's note (once fixed, see section 4) add an instruction or what a word means, not a second copy.
- Stories replace the math line, so they don't repeat it.
- Pictures (dots, bars, scales, jugs, rulers, graphs, shapes) carry the problem; none has the question written in it.

## 3. Watch one: idea line and narration

The rule is the same as in the 5th grade spec: **the narration says what the step does or why, in words, and leaves the equation to the math line.** Lines stay under about 12 words.

- **The worked example** stays each lesson's `reference`.
- **The idea line** is `idea[0]`, one sentence. Every 3rd grade lesson has one sentence today.
- **Captions** aren't shown in v2. Where a caption carried something worth keeping, it moves into a narration line below.
- Placeholders use the variable names already in each `explain()`. Where a name is only in `answers()`, the line says how to get it in `explain()`.
- In g3-mass, g3-liters, g3-graphs, g3-lineplot and g3-quads, `explain()` uses each answer step's `explain` text as its narration. That text is also "Show me" in practice, so keep it there, and set the narration by step id in `explain()` instead.

### g3-facts (4 × 6)
- Idea: keep it.
- count: `` Count by ${b}s, one row at a time: ${list}${a > 3 ? `, and on to ${P}` : ""}. `` (`list` is today's `Array.from(...).join(", ")`.) For example, "Count by 6s, one row at a time: 6, 12, 18, and on to 24." This drops "That's 4 rows, so 4 × 6 = 24."
- turn: keep it. "Now look down the columns. There are 6 columns of 4, and still 24 dots."

### g3-divfacts (24 ÷ 4)
- Idea (new): `Dividing shares into equal groups, and a times fact tells you how many in each.` Today's "has a times fact inside it" is hard to picture at 8.
- think: `` Put the ${count(a, "dot")} in ${b} equal rows. Each row gets ${q}. `` For example, "Put the 24 dots in 4 equal rows. Each row gets 6."
- divide: `Dividing is the times fact turned backwards.`

### g3-split (7 × 8)
- Idea: keep it.
- split: `` ${count(a, "row")} of ${b} is hard to count, so cut each row after 5. `` For example, "7 rows of 8 is hard to count, so cut each row after 5." See section 5: this step sits on beat 0 today and is never read out.
- five: `` The first part is ${count(a, "row")} of 5. ``
- rest: `` The other part is ${count(a, "row")} of ${r}. `` For example, "The other part is 7 rows of 3."
- sum: `Put the two parts back together.`

### g3-mult10 (4 × 30)
- Idea: keep it.
- fact: keep it. "Count the tens: 4 rows of 3 make 12 tens."
- tens: `` Each ten is worth 10. Count by ${t}s down the rows to check. `` For example, "Each ten is worth 10. Count by 30s down the rows to check." This drops "so 12 tens is 120", which is the math line.

### g3-twostep (Mia: 4 packs of 6, gives 5 away)
- Idea: keep it.
- The story is only in the caption today, and v2 doesn't show captions. Watch one then shows just "? left". So these narrations tell the story, one part per step.
- first step:
  - kind 0 and 1: `` ${w.name} has ${a} ${w.groups} of ${b} ${w.things}. Equal groups, so multiply. `` For example, "Mia has 4 packs of 6 stickers. Equal groups, so multiply."
  - kind 2: `` ${w.name} has ${a} ${w.things} and ${w.lose} ${c}. Take those away first. `` For example, "Leo has 32 crayons and loses 5. Take those away first."
- second step:
  - kind 0: `` ${w.they} gives ${c} away, so subtract. `` For example, "She gives 5 away, so subtract."
  - kind 1: `` ${w.they} has ${c} more too, so add. ``
  - kind 2: `` Share the rest equally into ${b} ${w.groups}. ``

### g3-round (347 to the nearest hundred)
- Idea: keep it.
- between: `` Count by ${to}s to find the ${place(to)} on each side. `` For example, "Count by 100s to find the hundreds on each side." (`place` is the helper at the top of the file.)
- mid: keep it. "Halfway between them is 350."
- round: `` ${n} is right on halfway, and halfway rounds up. `` or `` ${n} is ${n > mid ? "past" : "before"} halfway, only ${Math.abs(R - n)} away from ${R}. `` For example, "347 is before halfway, only 47 away from 300." This drops "So 347 rounds to 300."

### g3-addsub (458 + 275)
- Idea (new): `Break the second number into hundreds, tens and ones, and jump one place at a time.` Today's line gives the reason before the action, which is harder to follow.
- each jump:
  `` ${k === 0 ? `Start at ${a}. ` : ""}${s === 1 ? "Add" : "Take away"} the ${j.d} ${j.d === 1 ? one : many} in ${b}.${regroup}${k === js.length - 1 ? ` So ${a} ${sign(s)} ${b} = ${to}.` : ""} ``
  - `regroup`: work out `digit = j.from % (j.place * 10) - j.from % j.place` (the same as `jumpStep`). If `s === 1 && j.place < 100 && digit + j.v >= j.place * 10`: `` That makes a new ${NAMES[j.place * 10]![1]}. ``. If `s === -1 && j.place < 100 && digit < j.v`: `` Trade 1 ${NAMES[j.place * 10]![1]} for 10 ${many}. ``. Else nothing.
  - For example: "Start at 458. Add the 2 hundreds in 275." Then "Add the 7 tens in 275. That makes a new hundred." Then "Add the 5 ones in 275. So 458 + 275 = 733."
  - The last sentence stays: it gives the whole problem's answer, which is not that step's math line (728 + 5 = 733).

### g3-unitfrac (3 of 4 parts shaded)
- Idea: keep it.
- parts: `Count every part, shaded or not.`
- one: `` The bottom counts all ${d} parts. The top counts 1. `` For example, "The bottom counts all 4 parts. The top counts 1."
- shaded: `` ${count(k, "part")} ${isAre(k)} shaded, and each is 1/${b}. `` For example, "3 parts are shaded, and each is 1/4."

### g3-fracline (3/4)
- Idea: keep it.
- spaces: `` Count the spaces from 0 to 1, not the ticks. Each is 1/${B}. ``
- jumps: `Jump from 0 to the point, one space at a time.`
- name: `` The jumps go on top. The spaces in one whole go on the bottom.${A > B ? ` It's past 1, because ${A} is more than ${B}.` : ""} ``

### g3-fraccompare (1/4 ? 1/8)
- Idea (new): `To compare fractions, look at how big the pieces are and how many there are.` Today's "both the size of the pieces and how many there are matter" puts the verb last, which is hard to read.
- first beat:
  - bottom: keep it. "Both bars are cut into 8 equal pieces. Count the shaded ones: 3 and 5."
  - top: `` Both have ${a} shaded ${a === 1 ? "piece" : "pieces"}. Fewer pieces in a whole means bigger pieces. `` For example, "Both have 1 shaded piece. Fewer pieces in a whole means bigger pieces."
  - equal: `` Look under one 1/${Math.min(b, d)} piece and count the small pieces. ``
- compare: `` ${big} reaches further, so it is bigger. `` or `The shading ends in the same place, so they are equal.` For example, "1/4 reaches further, so it is bigger."

### g3-area (6 by 4)
- Idea: keep it.
- row: `Count across the top row, one square at a time.`
- rows: `Count down the side. Every row is just like the first.`
- area: `` ${count(W, "row")} of ${count(L, "square")}, so multiply. Area is in square units. `` For example, "4 rows of 6 squares, so multiply. Area is in square units."

### g3-perim (7 cm by 4 cm rectangle)
- Idea: keep it.
- first step:
  - kind 0: `Walk along the top and down the side.`
  - kind 1: `` Every side of a square is ${a} cm long. ``
  - kind 2: `Walk along the bottom and up the right side.`
- around:
  - kind 0: `` The other two sides match the first two: another ${r1} cm. `` For example, "The other two sides match the first two: another 11 cm."
  - kind 1: `` Add ${a} cm once for each of the ${all.length} sides. ``
  - kind 2: `` Finish with the last side, ${c} cm. ``
  - The math line has no unit, so each line above keeps "cm" in the words.

### g3-elapsed (9:40 a.m. to 11:15 a.m.)
- Idea: keep it.
- to-hour: `First jump up to the next o'clock.`
- hours: `` Then count the whole hours.${H1 <= 12 && H2 > 12 ? " After 12 comes 1." : ""} ``
- after: `Last, count the minutes past the hour.`
- total: when `m1 + m3 >= 60`: `` ${count(m1 + m3, "minute")} is ${m1 + m3 === 60 ? "a whole hour" : "more than an hour"}, so trade 60 minutes for 1 hour. `` Otherwise: `Add the whole hours, then the minutes before and after.` For the reference (20 + 15 minutes) it reads the second one.

### g3-mass (a scale in grams, needle at 130 g, marks of 10)
- Idea: keep it.
- Drop the beat-0 lines "look", "labels" and "read" (see section 5). What "look" said moves into the unit line.
- kind 0:
  - unit: `` Imagine holding a ${th.name}: it feels ${th.kg ? "heavy" : "light"}. `` For example, "Imagine holding a dog: it feels heavy."
  - guess: `` The other two guesses are far too ${th.kg ? "light or too heavy" : "heavy"}. ``
- kind 1:
  - step: `There are 5 small spaces from one label to the next.`
  - read: work out `label = Math.floor(p.value / p.step / 5) * 5 * p.step` (as in `answers()`). If `label === p.value`: `The needle points straight at a label.` Else: `` Start at ${withCommas(label)} and count on by ${p.step}. `` For example, "Start at 100 and count on by 10."
- kind 2:
  - story: keep the operation step's text (the "why", for example "Two amounts go together, so there will be more than either one. That's adding.").
  - solve: by `OPS[p.op]`: + `Put the two amounts together.`; − `Take that amount away.`; × `` ${p.a} equal groups of ${withCommas(p.b)} ${UNIT(p.unit)}. ``; ÷ `` Share it into ${p.b} equal parts. ``

### g3-liters (a 10 liter jug, water at 7)
- Idea (new): `A liter is about as much as one big bottle of water.` "A fixed amount" means little to an 8 year old.
- Drop the beat-0 lines "fill" and "readit" (see section 5).
- kind 0:
  - step: `Read the labels to see what each mark is worth.`
  - read: `` Find the top of the water and read the mark.${p.step !== 1 ? ` Count up by ${p.step}s.` : ""} ``
- kind 1: the same two lines as g3-mass kind 2, with `"L"` for the unit.

### g3-graphs (picture graph of favorite fruit, 2 votes a picture, apples)
- Idea (new): `In a scaled graph, one picture, or one line up the side, can stand for more than 1.` Half the problems are bar graphs, which today's line leaves out.
- Drop the beat-0 "look" line. What it said moves into the key line.
- In `explain()`, set `th = THEMES[p.theme]!`, `s = p.scale`, and for a step whose id starts with "x" use `i = p.x`, for "y" use `i = p.y`; then `name = th.names[i]!`, `c = p.counts[i]!`, `half = c % s !== 0`.
- key: `Read the key under the graph first.`
- scale: `Read the numbers up the side first.`
- x-pics, y-pics: `` ${half ? "Count the whole pictures. The last one is only half." : `Count the pictures in the ${name} row.`} ``
- x, y on a picture graph: `` Each picture is ${s}${half ? `, and half a picture is ${s / 2}` : ""}. `` For example, "Each picture is 2, and half a picture is 1."
- x, y on a bar graph: `` Follow the top of the ${name} bar across to the side.${half ? " It ends halfway between two lines." : ""} ``
- more: `How many more means subtract.`
- both: `Together means add.`

### g3-lineplot (a ruler, 2 3/4 inches)
- Idea: keep it.
- Drop the beat-0 lines "look" and "drop" (see section 5). What they said moves into the lines below.
- kind 0:
  - whole: `Long marks are whole inches. Find the last one it passes.`
  - extra: `` ${p.to === 4 ? "Middle marks are halves, short ones fourths." : "The middle mark is the half."} Count the spaces past ${p.whole}. `` For example, "Middle marks are halves, short ones fourths. Count the spaces past 2."
  - write: `` Whole inches go in front. The ${p.to === 2 ? "halves" : "fourths"} make the fraction. ``
- kind 1:
  - stack: `` Each X is one ${THINGS[p.thing]!.one}. Count the X's above ${said(p.v)}. ``
  - mode: `` Each X is one ${THINGS[p.thing]!.one}. The tallest stack came up most. ``

### g3-quads (a parallelogram)
- Idea: keep it.
- Drop the beat-0 "look" line (see section 5).
- sides: `Any shape with 4 sides is a quadrilateral.`
- corners: `Check each corner against the corner of a page.`
- equal: keep the answer step's text. "The sides aren't all equal."
- parallel: `Opposite sides that would never meet are parallel.`
- name, by `p.shape`:
  - 0: `4 square corners and 4 equal sides make a square.`
  - 1: `4 square corners, but the sides aren't all equal.`
  - 2: `4 equal sides, but no square corners.`
  - 3: `2 pairs of parallel sides, but no square corners.`
  - 4: `Exactly 1 pair of parallel sides makes a trapezoid.`
  - 5: `No special name fits, so it's just a quadrilateral.`
- also: keep the answer step's text ("Yes: every square is a rectangle." / "No: its sides aren't all equal.").

## 4. Maths and wording errors

- **g3-elapsed:93** says "60 minutes is more than an hour" when the minutes before and after add to exactly 60 (it happens: start 9:25, end 11:25). Make it:
  `` `${count(m1 + m3, "minute")} is ${m1 + m3 === 60 ? "a whole hour" : "more than an hour"}. Trade 60 of them for 1 more hour.` ``
  The narration at line 135 says "60 minutes, which is 1 hour and 0 minutes" in the same case. The new total line in section 3 fixes that.
- **g3-fraccompare:168** the note "Which is bigger?" is wrong for the equal problems (2/4 ? 1/2), where neither is bigger and "=" is the answer. Make it `Which is bigger, or are they the same?`
- **g3-mult10:45** "12 moves to the tens place" is not right when the fact is 10 or more: in 120 the 1 is in the hundreds place. Make it:
  `` `${count(f, "ten")} = ${f * 10}: write ${f}, then a 0 for the ones.` ``
- **g3-twostep:168** the story is only in the caption, which v2 doesn't show, so Watch one is "? left" with no story. The narrations in section 3 fix it.

I read every slip message and hint in the 18 lessons against their numbers and found no other errors.

## 5. Beat numbers in Watch one (for Development)

Learn v2 lists a step's line once its beat is reached, but a beat-0 step is listed only once the whole example has finished (then at the top of the list), and is never read out (beat 0 reads the heading and the problem). Two steps on the same beat appear at once, and only the first is read.

- **g3-split:64** the "split" step is a real answer step on beat 0. Its line only shows once the example has finished, and "cut each row after 5" is never said. Move split to beat 1 and five, rest and sum to 2, 3 and 4. The diagram follows: cells `from: 2` and `from: 3`, the line `from: 4`, `timeline: beats(5)`.
- **Intro lines on beat 0**, to drop (their useful words move into section 3's lines): g3-mass:174, 184, 196; g3-liters:88, 95; g3-graphs:121; g3-lineplot:123, 134; g3-quads:95. Today they pop in only after the example has finished, above the steps, as "Read the labels." or "Look at it."
- **Shared beats:** g3-graphs:122 puts every answer step on beat 1, and g3-lineplot:135 does the same; g3-lineplot:124 puts "extra" and "write" both on beat 2; g3-quads:86 puts "name" and "also" both on 5. Give each step its own beat (`state: i + 1`, and one more beat in `timeline`), and check each diagram holds its last picture on the extra beats.
- Other grades have beat-0 steps too (`git grep "state: 0"` finds about 90 outside grade 3). Worth one look at Learn: either list beat-0 lines first, or treat this per grade as above.

## Checks for Development
- No test pins the idea text. If a snapshot pins narration, regenerate it. Answers and steps are unchanged, except the work line of the g3-mass and g3-liters story step.
- After the change, check that no Watch one narration line contains its own math line, for these 18 lessons (`saysMath` in `Learn.tsx` already does this test).
- The `pre` changes go in both `catalog.ts` and the lesson file (g3-perim has no `pre` line today; add `pre: "g2-measure"`).
