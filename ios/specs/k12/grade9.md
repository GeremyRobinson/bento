# v2 lesson pass: 9th grade

Curriculum, 2026-10-13. For Development. It covers the 13 lessons in `web/src/curriculum/lessons/grade9/`, read on `origin/next` 453ec4b, together with the v2 learn and practice screens on Design's branch (5d17ed2).
It is content only: lesson text, the depends-on lists and the check recipes. Nothing here changes layout.

## How to read this

The rules are the same as in `grade5.md`. In short:

**Depends on** lists the lessons a child needs before this one. The lists can cross grades. The first id is the main build-up, so put it in today's single `pre`. The whole list is for Today's step-back.

**Skill check** is the recipe for the lesson's own check. Each item reads `i<N>`, meaning call the lesson's own `generate(rng, N)`. An item can add a `where` condition: redraw, up to 50 tries, until it holds.
- No 9th grade lesson has a story, so no item is a `story` item.
- The default is 4 items, with no hints and one try per step, as in the plan.
- Shuffle the items.
- Every 9th grade lesson is wrapped in `withEasyStart`, so indexes 0 to 2 pick the smallest of six draws. The checks use `i3`, which draws over the full range. `g9-elim` and `g9-quadform` also read the index themselves (see below).
- `where` conditions use the problem's own field names. Note that `g9-factor` calls its second number `qn`, not `q`.

The gating suggestion in `grade5.md` (a lesson from an earlier grade counts as learned until one of its checks comes back 0-2) matters even more here, since most 9th grade lists reach into grades 6 to 8.

## 1. Depends on and skill checks

| Lesson | Depends on | Skill check (4 items) |
|---|---|---|
| g9-multistep Multi-step equations | g7-eq, g7-distribute | i3; i3; i3 where a × b ≥ 20; i3 where x ≥ 8 |
| g9-elim Systems by elimination | g8-system, g7-addint | i3 where x > 0 and y > 0; i3 where y < 0; i3 where x < 0; i3 |
| g9-twopoint Line through two points | g8-intercept, g8-slope | i3 where m > 0; i3 where m < 0; i3 where b < 0; i3 where x1 < 0 |
| g9-negexp Zero and negative exponents | g8-exp, g6-expo | i3 where n = 1; i3 where n = 2; i3 where n = 3; i3 where a ≥ 4 and n ≥ 2 |
| g9-growth Exponential growth | g6-expo, g5-mult2 | i3 where r = 2; i3 where r = 3; i3 where t ≥ 4; i3 |
| g9-radical Simplify square roots | g8-roots, g4-factors | i3 where k is 2, 3 or 5; i3 where k = 4; i3 where k = 6; i3 |
| g9-polyadd Add and subtract polynomials | g7-distribute, g7-subint | i3 where not sub; i3 where sub; i3 where sub and one of d, e, f is below 0; i3 |
| g9-foil Multiply binomials | g7-distribute, g7-mulint | i3 where a > 0 and b > 0; i3 where a and b have opposite signs; i3 where a < 0 and b < 0; i3 |
| g9-gcf Factor out the GCF | g6-gcf, g7-distribute | i3 where g is 4 or 6; i3 where m = 1; i3; i3 |
| g9-factor Factoring quadratics | g9-foil, g4-factors | i3 where p ≥ 2; i3 where p × qn has 3 or more factor pairs; i3 where p = qn; i3 |
| g9-solvefactor Solve by factoring | g9-factor, g7-mulint | i3; i3 where p × r has 3 or more factor pairs; i3 where p ≥ 5 and r ≥ 5; i3 |
| g9-quadform The quadratic formula | g9-solvefactor, g8-roots, g7-mulint | i3 where r1 × r2 < 0; i3 where r1 < 0 and r2 < 0; i3 where r1 > 0 and r2 > 0; i3 where r1 × r2 ≠ 0 |
| g9-median Find the median | none | i3 where v has 5 numbers; i3 where v has 7 numbers; i3 where the unsorted middle number is not the median; i3 where a number repeats |

Why these items:
- **g9-multistep:** the slip the lesson guards is multiplying only the x, not the number. Every item tests it; the two `where` items make the numbers big enough that the slip can't be guessed past.
- **g9-elim:** the generator gives −6 to 12 from index 3. A negative y makes x − y bigger than x + y, and a negative x makes "take x off" an add. Both are the cases that matter.
- **g9-twopoint:** a falling line and a negative x1 both put a minus inside the slope and inside b = y − mx.
- **g9-negexp:** n = 1 gives 1/a, the case children most often get wrong as −a.
- **g9-radical:** k = 4 and k = 6 have a smaller square that also divides (4 or 9), so these items test "the biggest square" (the `smallerSquares` slips).
- **g9-polyadd:** subtracting a negative term is the point of the minus case.
- **g9-gcf:** g = 4 or 6 has a smaller common factor (2 or 3), the usual near miss. m = 1 makes the factor `gx(x + n)`.
- **g9-factor, g9-solvefactor:** a last number like 12, 18, 24 or 36 has several factor pairs, so only one pair gives the right sum.
- **g9-quadform:** pass index 3, so a root can be 0 in the plain item. The last item rules it out on purpose, so 3 of 4 items aren't edge cases.
- **g9-median:** the "Didn't sort first" slip only exists when the unsorted middle number differs from the median, and a repeat tests "count every number".

Changes from today's `pre`:
- **g9-multistep** moves from g8-both to g7-eq. The problem is a(x + b) = c: distribute, then it is a two-step equation. There is never an x on both sides.
- **g9-growth** gets g6-expo (today none). The growth factor is a power.
- **g9-radical** gets g8-roots (today none). The lesson takes the square root of a perfect square.
- **g9-polyadd** gets g7-distribute (today none). That is where combining like terms is learned.
- **g9-foil** gets g7-distribute (today none). Multiplying binomials is distributing twice.
- **g9-gcf** gets g6-gcf (today none). It is the same idea with numbers only.
- **g9-median** stays "none". Sorting whole numbers to 30 and counting is all it needs.
- The rest keep their `pre` as the first id in the list.

## 2. Show the problem once

On the v2 stage the problem shows once (display, or lead, or story). One lesson says it twice.

- **g9-growth:** the display "100 × 2³" and the note "100 bacteria double every hour. How many after 3 hours?" say the same problem twice, and the display also gives away the method (the first step asks for 2³). Remove `displayNote` (`growthNote`) and add a `lead`:
  `**${P}** bacteria ${growWord(r)} every hour. How many are there after **${count(t, "hour")}**?`
  For the reference: "**100** bacteria double every hour. How many are there after **3 hours**?" Learn still opens on the "100 × 2³" statement, which is fine there: the first narration line tells the story.

The other 12 are fine.
- g9-twopoint's "Write the line as y = mx + b.", g9-factor's "Factor it." and g9-median's "Find the median." add the instruction, not a second copy of the problem.
- g9-quadform's note is the formula itself, a tool for the problem, not a copy of it. Keep it.
- No 9th grade lesson has counters or a practice `picture`.

## 3. Watch one: idea line and narration

The rule is the same as in 5th grade: **the narration says what the step does or why, in words, and leaves the equation to the math line.** Lines stay under about 12 words. Captions aren't shown in v2, so anything worth keeping from a caption moves into a narration line. Placeholders use the variable names already in each `explain()`. The examples are rendered for the lesson's `reference` problem.

In every 9th grade lesson built on `beatExplanation`, the first step has state 0, so it shows from the start (Design's fix). No lesson needs rewriting around that.

### g9-multistep (3(x + 4) = 27)
- Idea (new): `Whatever you do to one side, do to the other, so the sides stay equal.` Today's line says "each step is undone on both sides", which is not what happens: each step is done to both sides.
- equation: `Each of the ${f(a)} groups holds one x and ${f(b)} more.` "Each of the 3 groups holds one x and 4 more." This also fixes a wording error (section 4).
- distribute: `Multiply ${f(a)} by both x and ${f(b)}.` "Multiply 3 by both x and 4."
- subtract: `Undo the + ${f(ab)} on both sides.` "Undo the + 12 on both sides."
- divide: `Split both sides into ${f(a)} equal groups.` "Split both sides into 3 equal groups."

### g9-elim (x + y = 10, x − y = 4)
- Idea: keep it.
- first: keep it ("The first equation has + y.").
- second: keep it. It already says why the y's cancel, which was the caption.
- add: `Add left to left and right to right.`
- x: `Divide both sides by 2 to get one x.`
- y: `Put x back into the first equation to find y.`
- check: `Check that x and y make the second equation true too.`

### g9-twopoint ((1, 5) and (3, 9))
- Idea (new): `Two points fix a line, so they give its slope and where it crosses the y-axis.` Today's line ends "where it crosses", which doesn't say which axis.
- points: `Plot both points. Exactly one line goes through them.`
- m: `Slope is the change in y over the change in x.`
- b: `Put the first point in: b is where the line crosses the y-axis.`
- line: `The slope goes with x, and b is the number on its own.`

### g9-negexp (2⁻³)
- Idea: keep it.
- positive: `Start with the positive power: ${count(n, "copy", "copies")} of ${f(a)}.` "Start with the positive power: 3 copies of 2."
- down: `Count down, dividing by ${f(a)} each time, until the exponent is 0.` "Count down, dividing by 2 each time, until the exponent is 0."
- flip: `Keep dividing past 0, and ${f(a)}${supText(n)} ends up under the 1.` "Keep dividing past 0, and 2³ ends up under the 1."

### g9-growth (100 × 2³)
- Idea: keep it.
- start: `Start with this many bacteria. Every hour they ${growWord(r)}: × ${r}.` "Start with this many bacteria. Every hour they double: × 2." Its math line is only "100", so today's "Start with 100 bacteria" repeats it and would fail the check at the end.
- factor: `${count(t, "hour")} of × ${r} is ${Array(t).fill(r).join(" × ")}.` "3 hours of × 2 is 2 × 2 × 2." This carries the caption's point that the power is repeated multiplying.
- total: `Multiply the start by the growth factor to get the count after ${count(t, "hour")}.` "Multiply the start by the growth factor to get the count after 3 hours."

### g9-radical (√72)
- Idea: keep it.
- start: keep it ("Look for the biggest perfect square that divides 72.").
- square: `${f(square)} is the biggest perfect square that goes in.` "36 is the biggest perfect square that goes in."
- root: `${f(k)} times itself makes ${f(square)}.` "6 times itself makes 36."
- simple: `${f(k)} comes out, and ${f(rest)} stays under the root.` "6 comes out, and 2 stays under the root." (Today's line ends by repeating the math line; drop that part.)
- check: `Check: squaring the answer gives back the number.`

### g9-polyadd ((2x² + 3x − 1) + (x² − 5x + 4))
- Idea: keep it.
- problem: `Line up like terms: x² with x², x with x, numbers with numbers.` When `p.sub`, add: ` The minus flips every sign in the second.` This replaces "Two polynomials, plus.", and the minus sentence carries what the picture's "flip every sign" shows.
- x2: `Combine the x² terms.`
- x1: `Now the x terms.`
- x0: `Last, the numbers. That gives ${toPlainText(quad(A, B, C))}.` "Last, the numbers. That gives 3x² − 2x + 3."

### g9-foil ((x + 3)(x + 4))
- Idea: keep it.
- middle: `Outer is x × ${pf(b)}, inner is ${pf(a)} × x. Both are x terms.` "Outer is x × 4, inner is 3 × x. Both are x terms." Use `pf`, so a negative reads "x × (−4)", not today's "x × −4".
- last: `Last: multiply the two numbers.`
- answer: `First is x × x = x². Put all the parts together.`

### g9-gcf (6x² + 9x)
- Idea: keep it.
- number: keep it ("3 is the biggest number that divides 6 and 9."). It says why, and the math line shows the division.
- factor: `Both terms have an x too, so ${g}x comes out.` "Both terms have an x too, so 3x comes out."

### g9-factor (x² + 7x + 12)
- Idea: keep it.
- pair: `They also add to ${p + q}, the middle number.` "They also add to 7, the middle number." The math line shows only the product, so the narration gives the sum.
- factors: `Each number joins an x to make one side of the rectangle.`

### g9-solvefactor (x² − 5x + 6 = 0)
- Idea: keep it.
- eq: `Find each x that makes this 0: where the graph crosses the x-axis.`
- factor: `Two numbers that multiply to ${f(c)} and add to ${f(-b)}.` "Two numbers that multiply to 6 and add to 5."
- roots: `If the product is 0, one factor is 0: set each to 0.`

### g9-quadform (x² − 2x − 8 = 0)
- Idea: keep it. "b² − 4ac" is a proper term, allowed at this grade, and the sentence is right for these lessons (a = 1, so the answers are √(b² − 4ac) apart).
- eq: `Here a = 1, b = ${f(b)} and c = ${f(c)}. The answers are where the graph crosses the x-axis.` Only "crosses 0" changes to "crosses the x-axis".
- D: `Find b² − 4ac first. It's positive, so there are two answers.`
- root: `The answers sit ${f(s)} apart, centered on x = ${f(h)}.` "The answers sit 6 apart, centered on x = 1." This was the caption.
- roots: `Add the root to −b, then take it away, and halve each.`

### g9-median (7, 2, 9, 4, 5)
- Idea: keep it.
- bars: `Each number is a bar, as tall as the number.`
- count: `Count every number, repeats too.` Today's "There are 5 numbers." repeats the math line, which is just "5".
- spot: `Put them in order. The middle spot has as many before it as after.`
- median: `In order, ${s2.join(", ")}: spot ${mid} is the middle.` "In order, 2, 4, 5, 7, 9: spot 3 is the middle." The sorted list is in no math line, so it stays in the narration.

## 4. Maths and wording errors

- **g9-solvefactor, `answers.ts:10` (hint):** "Find two numbers that multiply to the number on its own and add to the x number" is wrong for these problems. The middle number is negative (x² − 5x + 6), and the boxes sit in (x − ☐)(x − ☐), so the two numbers add to the *opposite* of the x number (5, not −5). A child who follows the hint looks for numbers that add to −5. Fix: `Find two numbers that multiply to ${f(c)} and add to ${f(-b)}, then write them in.` (destructure `b` and `c` from the problem; `f` is in `_plane/kit`). The explanation already says this correctly.
- **g9-multistep, `index.ts:59` (narration):** "3 groups of x + 4 balance 27" reads as 3x + 4, the very slip the lesson warns about. The new line in section 3 ("Each of the 3 groups holds one x and 4 more.") fixes it.
- **g9-foil, `index.ts:70` (math line):** when a = −b, for example (x + 3)(x − 3), the middle line ends "= 0x", because `cx(0)` writes "0x". Write `mid === 0 ? [num(0)] : cx(mid)`. The same narration also writes negatives without brackets ("x × −4"); the new narration in section 3 uses `pf`.
- No other maths errors. I checked every generator, every slip value and every hint against the answer model for all 13 lessons.

The engine's "tap the light bulb" wording is in `grade5.md`, section 4, for all grades.

## Checks for Development
- `web/src/tests/curriculum/held-8-12.test.ts:47` checks that each lesson's own `pre` equals the catalog's. So for each `pre` change, set it in both places: `catalog.ts` and the lesson's `index.ts` (g9-multistep has `pre: "g8-both"` at `index.ts:72`; g9-growth, g9-radical, g9-polyadd, g9-foil and g9-gcf have no `pre` line yet). Every new `pre` comes earlier in the catalog, as the test also wants.
- No test pins the 9th grade idea or narration text. The 9th grade tests (`oracles`, `held-8-12`, `diagrams/*`) check answers, slips and pictures. Answers and steps are unchanged, apart from the g9-foil "0" fix and the g9-solvefactor hint.
- After the change, check that no Watch one narration line contains its own math line, for these 13 lessons. As in 5th grade, the narration should not include the math line's text.
