# v2 lesson pass: Kindergarten and 1st grade

Curriculum, 2026-10-13. For Development. It covers the 28 lessons in `web/src/curriculum/lessons/gradeK/` (14) and `web/src/curriculum/lessons/grade1/` (14), read on `origin/next` 3ccaa07, together with the v2 learn and practice screens on Design's branch (e2e3154).
It is content only: lesson text, the depends-on lists and the check recipes. Nothing here changes layout.

## How to read this

The rules are the same as in the 5th grade spec (`grade5.md`).

**Depends on** lists the lessons a child needs before this one. The first id is the main build-up, so put it in today's single `pre`. The whole list is for Today's step-back.

**Skill check** is the recipe for the lesson's own check. Each item reads `i<N>`, meaning call the lesson's own `generate(rng, N)`. An item can add a `where` condition: redraw, up to 50 tries, until it holds.
- `story` means show that item as the lesson's story. Only g1-three uses it here.
- The default is 4 items, with no hints and one try per step, as in the plan.
- Shuffle the items, but put a `story` item last.
- None of these lessons uses `withEasyStart`. Their own generators keep index 0 to 2 (or 0 to 1) small or fixed, so the checks start at `i3`.

**Gating.** The suggestion in the 5th grade spec holds here too: a lesson from an earlier grade counts as learned until one of its checks comes back 0-2. Every 1st grade list below names K lessons, so this matters for a child who starts in 1st grade.

## 1. Depends on and skill checks

### Kindergarten

| Lesson | Depends on | Skill check (4 items) |
|---|---|---|
| k-count20 Count to 20 | none | i3 where n ≤ 14; i3 where n ≥ 17; i3 where n = 20; i3 |
| k-write Write numbers 0 to 20 | k-count20 | i4 where n is 2, 5, 6 or 9 (the look-alike digits); i7 where n is 12 to 19, twice (swapped digits); i8 where n is 10 or 20. Keep the "Pick how it's written" tap. |
| k-teens Teen numbers | k-count20, k-write | i3 where ones ≤ 3; i3 where ones ≥ 6, twice; i3 |
| k-compare More, less or the same | k-count20 | i3 where top > bottom; i3 where top < bottom; i3 where top = bottom; i3 where top and bottom differ by 1. Keep the "Compare" tap, which is the idea. |
| k-tens Count by tens to 100 | k-count20 | i3 where rows ≤ 5; i3 where rows is 6 to 9, twice; i3 where rows = 10 |
| k-add Adding within 10 | k-count20 | i3 where b ≥ 3; i3 where a < b; i3 where a + b ≥ 7; i3 |
| k-sub Taking away within 10 | k-add, k-count20 | i3 where b ≥ 4; i3 where a − b is 1 or 2; i3 where b = a (none left); i3 |
| k-story Story problems within 10 | k-add, k-sub | i3 where take = 0; i3 where take = 1; i3 where take = 1 and b ≥ 3; i3 where take = 0 and tale = 1. No `story` flag: the display is already the story. Keep the "More or fewer?" tap, which is the idea. |
| k-bonds Number bonds | k-add | i3; i3 where whole ≥ 7, twice; i3 where part > whole − part |
| k-make10 Make 10 | k-bonds | i3 where have ≤ 4; i3 where have is 5 to 7; i3 where have ≥ 8; i3 |
| k-shapes Flat shapes | none | i3 where the shape is the triangle (shape = 1) and turn ≠ 0; i3 where it is the square (shape = 2) and turn ≠ 0; i3 where it is the rectangle (shape = 3); i3 where it is the hexagon (shape = 4). Keep the "Name the shape" tap. |
| k-solids Solid shapes | k-shapes | i3 where shape = 2 (cylinder) and turn = 2 (on its side); i4 where shape = 3 (cone); i5 where shape = 0 (cube, drawn as a real thing); i6 where shape = 1 (sphere). All three taps stay. |
| k-length Longer and shorter | k-compare | i3 where a > b; i3 where a < b; i3 where a = b; i3 where a and b differ by 1. Keep the "Which is longer?" tap. |
| k-sort Sort and count | k-compare, k-shapes | i3 (asks for the fewest); i4 (the most); i5 where by = 1 (shapes); i7 (the fewest). Keep the "Sort one" tap. |

### 1st grade

| Lesson | Depends on | Skill check (4 items) |
|---|---|---|
| g1-tensones Tens and ones | k-teens, k-tens | i3 where tensOf(n) ≥ 4; i3 where onesOf(n) = 0; i3 where onesOf(n) > tensOf(n) (catches swapped digits); i3 |
| g1-compare Compare two-digit numbers | g1-tensones, k-compare | i3 where the tens differ and the smaller number has the bigger ones digit (like 39 and 52); i3 where the tens differ; i3 where the tens match and a > b; i3 where the tens match and a < b. Keep the "Pick the sign" tap. |
| g1-tenmore 10 more, 10 less | g1-tensones, k-tens | i3 where more = 1; i3 where more = 0; i4 where n % 10 = 0; i3 where more = 0 and n ≥ 50 |
| g1-add20 Add within 20 | k-add, k-count20 | i3 where a < b, twice (tests starting with the bigger number); i3 where a > b; i3 where min(a, b) ≥ 4 |
| g1-ten Make a ten to add | k-make10, k-teens | i3 where a = 9; i3 where a is 6 or 7; i3 where b ≥ 7; i3 |
| g1-three Add three numbers | g1-ten, g1-add20 | i3 where the steps include `pick` and the pair makes 10; i3 where the steps include `pick` and the pair is a double; i3 where the steps include `pick`; i3 story |
| g1-sub20 Subtract within 20 | g1-ten, k-sub | i3; i3 where a ≥ 15; i3 where b − (a − 10) ≥ 4 (a long second hop); i3 where b = 9 |
| g1-missing Missing numbers | g1-ten, k-teens | i3 where first = 0; i3 where first = 1; i3 where a ≤ 5; i3 where c − 10 ≥ 5 |
| g1-addtens Add tens to a number | g1-tenmore, g1-tensones | i3 where k = 1; i3 where k ≥ 4; i3 where tensOf(n) ≥ 5; i3 |
| g1-time Time to the hour and half hour | none | i3 where minute = 0; i3 where minute = 30, twice; i3 |
| g1-measure Measure length | k-length, k-sub | i3 where a > b; i3 where a < b; i3 where a and b differ by 1; i3 where a or b is 10 or more |
| g1-halves Halves and fourths | k-shapes | i3 where parts = 2; i3 where parts = 4, twice; i3 where shape = 2 (circle). Keep the "Name the parts" tap. |
| g1-picgraph Picture graphs | k-sort, k-sub | i4 (ask 0: read a row, then longer or shorter); i5 (ask 1: most or fewest); i6 (ask 2: how many more); i7 (ask 3: together). The index picks the question kind, so all four kinds come up. |
| g1-tally Tally charts | g1-picgraph, g1-three | i3 where counts[x] ≥ 5 (ask 0, one bundle to count); i6 where counts[x] ≥ 10 (ask 0, two bundles); i4 (ask 1: how many more); i5 (ask 2: in all) |

Changes from today's `pre`:
- **k-add** goes from none to k-count20. Counting on from a number is the skill k-count20 teaches ("keep counting on from 10").
- **k-length** goes from none to k-compare. It is the same lesson shape: count two rows, then say which has more.
- **g1-missing** moves from g1-sub20 to g1-ten. The lesson never subtracts. Its first step, `8 + ? = 10`, is the make-a-ten step, and the second is a teen number (`10 + ? = 13`).
- The rest keep their `pre` as the first id in the list. k-count20, k-shapes and g1-time stay at none: they start fresh. g1-time comes before g1-halves in the order, so it should not wait on halves.

## 2. Show the problem once

On the v2 stage the problem shows once (display, or lead, or story). One lesson says it twice, and one carries a note that is never shown.

- **g1-tenmore:** the display "34 + 10" and the note "What is 10 more than 34?" say the same thing. Remove `displayNote` (line 109). The step question "10 more means one ten more." already gives the words.
- **g1-measure:** it has a `lead`, so `displayNote` ("Count the cubes under each one.", line 108) is never shown, and the lead already ends with that sentence. Remove `displayNote`. Nothing on screen changes.

The other 26 are fine.
- The notes in k-compare ("Count each row. They might be the same!"), g1-tensones ("Count the tens rods and the ones cubes.") and g1-halves ("The rectangle is cut into equal parts.") add an instruction, not a second copy of the problem.
- k-length's note ("The pencil or the ribbon?") finishes the question "Which is longer?", so it is one question, not two.
- g1-missing's "What number is missing?" says in words what the "?" means. Keep it for 1st graders, who are new to a "?" in a sum.
- k-story shows its story as the display, and `story()` gives the same words. It shows once either way.
- Pictures that are the thing to count (dots, ten frames, rods, cubes, the clock) are not a repeat. The first step asks the child to count them.

## 3. Watch one: idea line and narration

The same rule as 5th grade: **the narration says what the step does or why, in words, and leaves the equation to the math line.** In K and 1st grade the lines are shorter, about 10 words or less, and use very simple words.

Two things matter more in these grades:
- Read aloud speaks the math line, then the narration (`Learn.tsx` line 72). So a narration that ends "That's **7**." under the math line "Dots: 7" says 7 twice out loud. Most narrations below just drop that last sentence.
- Counting out loud ("1, 2, 3, 4") is what a K child should copy, and it is not in the math line. Keep it wherever it is there today.

As before: the worked example stays each lesson's `reference`; `idea[0]` is one sentence; captions aren't shown, and anything worth keeping from a caption moves into a narration. Placeholders use the variable names already in each `explain()`. The examples are rendered for the reference problem.

### k-count20 (14 dots)
- Idea (new): `A full row is 10, so keep counting on from 10.` Shorter words for a K reader.
- row: `Count the top row: ${countUp(1, row)}.` For example, "Count the top row: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10."
- count-on: `Keep going from ${row}: ${countUp(row + 1, all)}.` For example, "Keep going from 10: 11, 12, 13, 14."

### k-write (7)
- Idea: keep it.
- count: `Count the dots: ${countUp(1, n)}.` For 0, keep "Look for dots. There are none. None is **0**."
- write: keep it.
- done: `The number tells how many dots.`

### k-teens (6)
- Idea: keep it.
- ten: `The first frame is full.`
- ones: `Count the second frame: ${countUp(1, ones)}.` For example, "Count the second frame: 1, 2, 3, 4, 5, 6."
- teen: `See the ${ones} in ${n}? That's the extra ones.` For example, "See the 6 in 16? That's the extra ones."

### k-compare (6 and 4)
- Idea: keep it.
- top: `Count the top row: ${countUp(1, top)}.`
- bottom: `Count the bottom row: ${countUp(1, bottom)}.`
- compare: `Match the dots in pairs. The ${right === 0 ? "top" : "bottom"} row has ${extra} left over.` or, when the same, `Match the dots in pairs. Every dot has a partner.` For example, "Match the dots in pairs. The top row has 2 left over." Today's line ends "So 6 is more than 4.", which is the math line.

### k-tens (4 rows)
- Idea: keep it.
- rows: `Count the rows. Each row has ${count(TEN, "dot")}.`
- tens: `Point at each row and say one ten.` Today's line reads out "10, 20, 30, 40", which is the math line.

### k-add (3 + 4)
- Idea (new): `To add, start with the first group and count on.` Today's line is 15 words.
- first: `Hop once for each dot in the first group.`
- count-on: keep it ("Count on 4 more, one hop for each dot: 4, 5, 6, 7.").

### k-sub (7 − 3)
- Idea (new): `To take away, cross some out and count the rest.`
- all: `Count them all: ${countUp(1, a)}.`
- cross: `Cross out ${count(b, "dot")}.` For example, "Cross out 3 dots."
- left: `Count the dots that are left: ${countUp(1, left)}.` When left is 0: `Every dot is crossed out, so none are left.`

### k-story (Mia has 5 apples. Mia gives 2 away.)
- Idea (new): `More coming means add, and some going away means take away.` Today's line is 18 words.
- start: `Find the start in the first sentence. Each dot is one ${what.slice(0, -1)}.` For example, "Find the start in the first sentence. Each dot is one apple."
- more: keep it.
- end: `Count what is there now: ${countUp(1, end)}.`

### k-bonds (5 is 2 and how many?)
- Idea: keep it.
- whole: `Count all the dots: ${countUp(1, w)}. That's the whole.`
- part: `Count the first group: ${countUp(1, a)}.` When a is 0, keep "The first group is empty." without the bold 0.
- rest: `Count the other group: ${countUp(1, r)}.` When r is 0: `The other group is empty.`
- sentence: `The two parts make the whole again.` Today's line is the math line word for word.

### k-make10 (7 + ? = 10)
- Idea: keep it.
- have: `Count the dots: ${countUp(1, have)}.`
- need: `Put a dot in each empty box and count them: ${countUp(1, need)}.`
- ten: `Now every box has a dot, so the frame is full.`

### k-shapes (a triangle)
- Idea: keep it.
- sides: `Trace each side: ${countUp(1, sides)}.` For the circle: `Trace the edge. It is round all the way, with nothing straight.`
- corners: `Touch each corner: ${countUp(1, corners)}.` For the circle: `Look for a point where sides meet. There isn't one.`
- name: `${sides} sides and ${corners} corners.` For the square add `, all the same length`, for the rectangle `, two long and two short`, as in the step's own explain. For the circle: `Round, with no sides and no corners.` For example, "3 sides and 3 corners." Today's line ends "It's a **triangle**.", which is the math line.

### k-solids (a cylinder)
- Idea: keep it.
- look: keep it.
- flat: `Find the flat parts: ${s.where}.` For the sphere: `It is round all over, so no part is flat.` For example, "Find the flat parts: one circle at each end." This uses the step's own `where` words.
- roll: `Give it a push. Its round part lets it roll away.` or, for the cube, `Give it a push. Flat faces and corners make it slide.`
- name: `It ${s.is}.` For example, "It has two flat circle ends."

### k-length (pencil 7, ribbon 4)
- Idea: keep it.
- top: `Count the cubes along the ${top}: ${countUp(1, a)}.`
- bottom: `Now the ${bottom}: ${countUp(1, b)}.`
- longer: `The ${longer} sticks out ${cubes(extra)} further.` or `They end at the same place.` For example, "The pencil sticks out 3 cubes further."

### k-sort (5 buttons, 3 leaves)
- Idea: keep it.
- sort: `${k0.looks}, like the ${k0.many}.`, with `k0 = kinds[pickOf(p).group]!`. For example, "It has a pointed tip and a line down the middle, like the leaves." Today's line is 22 words.
- rows: keep it.
- count0, count1, count2: `Touch each ${kinds[i]!.one}: ${countUp(1, n)}.` For example, "Touch each button: 1, 2, 3, 4, 5."
- compare: `The ${p.ask ? "shortest" : "longest"} row has the ${word}.` For example, "The longest row has the most."

### g1-tensones (34)
- Idea: keep it.
- tens: `Count the long rods by tens: ${byTen.join(", ")}.`
- ones: `Now count the little cubes on their own.` or, when o is 0, `No little cubes are on their own.`
- number: `The tens digit is ${t}, the ones digit is ${o}.`

### g1-compare (43 ? 47)
- Idea: keep it.
- tens: `Both have the same tens, so the tens can't decide.` or `The tens are different, so the tens decide.`
- ones: `Same tens, so the ones decide.` or, when they match, `The ones match too.`
- sign: keep it.

### g1-tenmore (34 + 10)
- Idea: keep it.
- tens: `Find ${n} on the chart. Its first digit is the tens.`
- newtens: `10 ${w} is one ten ${w}. Jump one row ${more ? "down" : "up"}.` For example, "10 more is one ten more. Jump one row down."
- number: `The ones digit stays ${o}. Only the tens change.` This replaces the caption.

### g1-add20 (3 + 9)
- Idea (new): `Start at the bigger number, so you have fewer to count.`
- start: when a is the bigger, keep it. Else `${b} + ${a} is the same, so start with the bigger number.` For example, "9 + 3 is the same, so start with the bigger number."
- count-on: `Hop ${small} times: ${counted.join(", ")}.` For example, "Hop 3 times: 10, 11, 12."

### g1-ten (8 + 5)
- Idea (new): `Fill a ten first, because adding to 10 is easy.`
- ten: `Fill the first frame to make a ten.`
- break: `Move ${need} of the ${b} into the first frame.` For example, "Move 2 of the 5 into the first frame." This replaces the caption.
- add: `Now add what's left to the full ten.`

### g1-three (7 + 5 + 3)
- Idea: keep it.
- groups: `Look for two numbers that make 10, or a double.`
- first: `These two make 10, so add them first.` or `These two are a double, so add them first.` or, with neither, `No ten and no double, so add the first two.`
- last: `Now add the number that's left.`

### g1-sub20 (14 − 6)
- Idea (new): `Hop back to 10 first, then take away the rest.`
- to-ten: `${a} is 10 and ${first} more, so hop back to 10 first.` For example, "14 is 10 and 4 more, so hop back to 10 first."
- rest: `Split ${b}: what you took, and what is still to take.`
- from-ten: `Hop back the rest from 10.`

### g1-missing (8 + ? = 13)
- Idea (new): `Count up from the number you know to the total.`
- to-ten: `Start at ${a} and hop up to 10.`
- past-ten: `From 10, hop up to ${c}.`
- missing: `Put the hops together. That's the missing number.`

### g1-addtens (23 + 30)
- Idea: keep it.
- start: keep it.
- k: `Bring the new ${noun(k, "rod")} in next to the other tens.` For example, "Bring the new rods in next to the other tens."
- tens: `Count all the tens rods.`
- sum: `The ${countOf(o, "one")} ${verb(o, "stays", "stay")} the same.` For example, "The 3 ones stay the same." This replaces the caption.

### g1-time (8:30)
- Idea: keep it.
- hour: `The short hand is between ${h} and ${next}. It has passed ${h}.` or, on the hour, `Find the short hand. It points right at the hour.`
- minute: `The long hand has gone halfway around, to 6.` or `The long hand is at the top, on 12.`
- time: `We say half past ${h}.` or `We say ${h} o'clock.` See also the wording fix in section 4.

### g1-measure (pencil 7, ribbon 4)
- Idea (new): `Line up cubes with no gaps, and the number of cubes is the length.`
- first: `Start at the dashed line. Count the cubes under the ${one}.`
- second: `Now count the cubes under the ${two}.`
- diff: `Both start at the same line. Count the extra cubes on the ${longer}.`

### g1-halves (a rectangle in fourths, 3 shaded)
- Idea: keep it.
- parts: `Count the pieces. They are all the same size.`
- name: `${parts} equal parts are ${name}.` For example, "4 equal parts are fourths."
- shaded: `Count only the shaded parts.`

### g1-picgraph and g1-tally (narration comes from the steps)
Both pages use each answer step's `explain` as the narration, so today the narration is the "Show me" text: "The Fish row shows 8." under "Fish: 8", and "Lined up, the Fish row goes 5 past the Cats row: 8 − 3 = 5." under "8 − 3 = 5". Give `explain()` its own line per step id instead of `narration: s.explain`. "Show me" keeps its text.

g1-picgraph (pets, 6 dogs, 3 cats, 8 fish; how many more fish than cats):
- Idea: keep it.
- fill: keep it.
- read (ask 0), x and y: `Count the pictures in the ${th.names[i]} row.`, with i = p.x for read and x, p.y for y. For example, "Count the pictures in the Fish row."
- line-up: `The pictures line up, so look where each row ends.`
- compare (ask 1): `The ${p.few ? "shortest" : "longest"} row has the ${p.few ? "fewest" : "most"}.`
- more: `Line up the rows. Count the extra ${th.names[p.x]} pictures.`
- both: `Together means add the two rows.`

g1-tally (fruit, 7 apples):
- Idea: keep it.
- fill: keep it.
- bundles: `Find the bundles. Each one is 5 marks.`
- rest: `Now count the marks that aren't in a bundle.`
- all, with a bundle: `Count by 5s, then count on: ${seq}.`, where seq is the count the step's explain already builds, without its last sentence "That's ${n}.". For example, "Count by 5s, then count on: 5, then 6, 7." With fewer than 5: `Touch each mark once and count.`
- x, y, row0, row1, row2: `Find the ${th.names[i]} row. Count the bundles by 5s, then count on.` or, under 5 marks, `Find the ${th.names[i]} row and count the marks.`
- more: `Line up the rows. The extra marks are how many more.`
- total: `Add all three rows.`

## 4. Maths and wording errors

- **g1-time, line 88 (narration) and line 65 (the time step's explain):** "8 hours and 30 minutes is written 8:30." A clock time is not a number of hours, and "8 hours and no minutes" for 8:00 reads oddly too. Write the narration as in section 3, and the explain as `${half ? `Half past ${hour}` : `${hour} o'clock`} is written ${timeText(hour, minute)}.` For example, "Half past 8 is written 8:30."
- **k-bonds, line 50:** the slip `[whole + part, "Added the parts", ...]` is the whole plus the first group, not the two parts (the two parts add to the whole). Rename the kind to "Added the whole and a part". The message can stay.
- **k-solids, order (lines 96-99 against lines 43-64):** Watch one shows flat face, then roll. Practice asks roll, then flat face. Not wrong, but a child who copies the worked example meets the steps in the other order. Swap the two practice steps so practice matches the picture's beats (faces 1, move 2), or say why not.

The engine wording fix from the 5th grade spec ("tap the light bulb" at `practice.ts:379`) covers these grades too. No K or 1st grade lesson mentions the bulb.

## Checks for Development
- No test pins the idea text. If a snapshot pins narration, regenerate it. Answers and steps are unchanged, apart from the g1-time explain text, the k-bonds slip kind and, if you take it, the k-solids step order.
- After the change, run the same cheap test as for 5th grade on these 28 lessons: no narration contains its own math line. `saysMath` in `Learn.tsx` already does that comparison.
- For g1-picgraph and g1-tally, check that every step id a problem can produce (read, line-up, compare, x, y, more, both; bundles, rest, all, row0 to row2, total) has a narration, so none falls back to empty.
