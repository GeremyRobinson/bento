# v2 lesson pass: 6th grade

Curriculum, 2026-10-13. For Development. It covers the 14 lessons in `web/src/curriculum/lessons/grade6/`, read on `origin/next` 453ec4b, together with the v2 learn and practice screens on Design's branch (5d17ed2).
It is content only: lesson text, the depends-on lists and the check recipes. Nothing here changes layout.

## How to read this

**Depends on** lists the lessons a child needs before this one. The lists can cross grades. The first id is the main build-up, so put it in today's single `pre`. The whole list is for Today's step-back.

**Skill check** is the recipe for the lesson's own check. Each item reads `i<N>`, meaning call the lesson's own `generate(rng, N)`. An item can add a `where` condition: redraw, up to 50 tries, until it holds.
- `story` means show that item as the lesson's story. Only g6-divide has a story in this grade.
- The default is 4 items, with no hints and one try per step, as in the plan.
- Shuffle the items, but put a `story` item last.
- Lessons whose `generate` ignores the index (g6-pctof, g6-lcm, g6-onestep, g6-tri, g6-trap, g6-mean) are written `i0`. Any index gives the same spread there.

Gating works as in the 5th grade spec: a lesson from an earlier grade counts as learned until one of its checks comes back 0-2.

## 1. Depends on and skill checks

| Lesson | Depends on | Skill check (4 items) |
|---|---|---|
| g6-ratio Equivalent ratios | g4-equiv, g3-divfacts | i3; i3 where k ≥ 5; i3 where a > b; i3 |
| g6-rate Unit rates | g4-divide, g4-partial | i3; i3 where n ≥ 5; i3 where m < n; i3 where u ≥ 10 |
| g6-pctof Percent of a number | g5-fracof, g4-divide | i0 where p = 75; i0 where p is 20, 30 or 40; i0 where p is 60, 70, 80 or 90; i0 where p is not 10 or 25 |
| g6-pctwhole Find the whole | g6-pctof | i3 where p = 10; i3 where p = 20; i3 where p = 25; i3 where p = 50 |
| g6-divide Dividing fractions | g5-unitdiv, g5-multfrac | i0; i3 where c > 1 and a·d > b·c (more than one fits); i3 where a·d < b·c (less than one fits); i3 story where a·d > b·c. Keep the "More than one?" step, which is the idea. |
| g6-lcm Least common multiple | g4-factors | i0 where a and b share a factor and b is not a multiple of a (like 4 and 6); i0 where a and b share no factor (LCM = a × b); i0 where b is a multiple of a (LCM = b); i0 where a and b share a factor and b is not a multiple of a |
| g6-gcf Factor out the GCF | g4-factors, g3-split | i3 where g is 4, 6, 8 or 9 (it has a smaller factor that also works); i3 where m = 1 or n = 1; i3; i3 |
| g6-numline Distance on a number line | none | i0; i3; i3 where −a ≥ 7 and b ≥ 7; i3 where −a > b |
| g6-expo Exponents and order | g5-order, g3-facts | i3 where n = 3; i3 where n = 2 and a ≥ 3; i3 where not (a = 2 and n = 2), twice. Keep the "How many times?" step, which is the idea. |
| g6-eval Evaluate expressions | g5-order, g3-facts | i3; i3; i3 where x = 1 or y = 1; i3 |
| g6-onestep One-step equations | g6-eval, g3-divfacts | i0 where t = 0 (x + a); i0 where t = 1 (x − a); i0 where t = 2 (ax); i0 where t = 3 (x ÷ a). Each item needs a different undo, which is the point of this lesson. |
| g6-tri Area of a triangle | g4-area, g4-mult2x2 | i0 where b or h is odd; i0 where b ≥ 10 and h ≥ 10; i0; i0 |
| g6-trap Area of a trapezoid | g6-tri, g4-mult2x2 | i0 where a + b is odd (halve only at the end); i0 where h is odd; i0; i0 |
| g6-mean Find the mean | g4-divide, g3-addsub | i0 where there are 4 numbers; i0 where there are 5; i0 where there are 6; i0 |

Why the `where` conditions:
- **g6-expo:** 2² is the one case where the slip "base × exponent" (2 × 2) gives the right answer, so it can't test the idea.
- **g6-gcf:** when g is 4, 6, 8 or 9, a smaller common factor also works, so the check sees whether the child finds the *greatest*.
- **g6-pctof:** 10% and 25% make the second step "1 × …", which tests nothing new.

Changes from today's `pre`:
- **g6-ratio** gets g4-equiv (was none). Equivalent ratios scale both parts by the same number, just as equivalent fractions scale top and bottom.
- **g6-rate** moves from g5-divide to g4-divide. It always divides by one digit (2-9), never by a two-digit number.
- **g6-lcm** gets g4-factors (was none). That lesson is factors and multiples.
- **g6-expo** gets g5-order (was none). This lesson adds a new first rung to the order of operations.
- **g6-eval** gets g5-order (was none). After swapping in the numbers, it is × before +.
- **g6-mean** gets g4-divide (was none). The total, at most 120, is shared by 4, 5 or 6.
- **g6-numline** stays at none, now on purpose. Negative numbers first appear here, and the counting is small.
- The rest keep their `pre` as the first id in the list.

## 2. Show the problem once

On the v2 stage the problem shows once (display, or lead, or story). No 6th grade lesson says it twice, so there are no fixes here.

- No lesson in this grade has a `lead`, counters or a `picture`. The picture files in g6-divide, g6-expo, g6-eval and g6-trap are only used by Watch one.
- The notes add something the display doesn't: a question (g6-rate "How much do 7 apples cost?", g6-numline "How far apart are they on the number line?"), the values (g6-eval "when x = 4 and y = 5"), an instruction (g6-gcf, g6-mean) or the formula (g6-tri, g6-trap).
- The g6-divide story replaces the math line, so it doesn't repeat it.

## 3. Watch one: idea line and narration

The rule is the same as in 5th grade: **the narration says what the step does or why, in words, and leaves the equation to the math line.** Lines stay under about 12 words.

- **The worked example** stays each lesson's `reference`.
- **The idea line** is `idea[0]`, one sentence. Every 6th grade lesson has just one.
- **Captions** aren't shown in v2. Where a caption carried something worth keeping, it moves into a narration line below.
- Placeholders use the variable names already in each `explain()`. The examples are rendered for the reference problem.

### g6-ratio (2 : 3 = ? : 12)
- Idea: keep it.
- factor: `${b} equal boxes make ${b * k}, so each box is ${k}.` For example, "3 equal boxes make 12, so each box is 4." This keeps the caption's point that every box is the same size.
- scale: `The other side is ${a} boxes of the same size.` For example, "The other side is 2 boxes of the same size."

### g6-rate (4 apples cost $12; 7 apples)
- Idea: keep it.
- one: `Share the cost equally over the ${n} ${item}.` For example, "Share the cost equally over the 4 apples."
- many: `Then take ${m} of them at that price.` For example, "Then take 7 of them at that price."

### g6-pctof (30% of 80)
- Idea: keep it.
- base: `Cut ${W} into 10 equal blocks; each block is 10%.` or, for 25 and 75, `Cut ${W} into 4 equal blocks; each block is 25%.` For example, "Cut 80 into 10 equal blocks; each block is 10%."
- scale: `${p}% is ${count(p / base, "block")}.` For example, "30% is 3 blocks."

### g6-pctwhole (15 is 25% of ?)
- Idea (new): `Find how many of that percent make 100%, then take that many of the part.` Today's line ("one part you know can count up to 100%") is hard to read.
- parts: `Count how many ${p}% blocks make 100%.` For example, "Count how many 25% blocks make 100%."
- whole: `Each block is ${P}, so the whole is ${k} of them.` For example, "Each block is 15, so the whole is 4 of them."

### g6-divide (2/3 ÷ 1/4)
- Idea: keep it.
- size:
  - S > L: `${c}/${d} is smaller than ${a}/${b}, so expect more than 1.` For example, "1/4 is smaller than 2/3, so expect more than 1."
  - S === L: `They are the same size, so the answer is 1.`
  - else: `${c}/${d} is bigger than ${a}/${b}, so expect less than 1.`
- flip: `One whole holds ${c === 1 ? d : `${d}/${c}`} pieces of ${c}/${d}, so multiply by the flip.` For example, "One whole holds 4 pieces of 1/4, so multiply by the flip." This also fixes "4/1 of 1/4" when c is 1.
- multiply: `Top times top, bottom times bottom.`
- simplify:
  - same: `It's already as simple as it gets.`
  - S % L === 0: `The bottom goes into the top exactly, so it's a whole number.`
  - S ≥ L: `Pull out the wholes and put the rest on top${gcd(S, L) > 1 ? ", then simplify" : ""}.`
  - else: `Divide the top and the bottom by ${gcd(S, L)}.`
  - Then keep today's ending when there are wholes and a part: ` So ${F.whole} whole ${c}/${d}${F.whole === 1 ? "" : "s"} fit, and ${F.num}/${F.den} of another.` For example, "Pull out the wholes and put the rest on top. So 2 whole 1/4s fit, and 2/3 of another."

### g6-lcm (LCM(4, 6))
- Idea: keep it.
- count-big: `Count by ${b}s, the bigger number.` For example, "Count by 6s, the bigger number."
- count: `${L} is the first one that ${a} goes into.` For example, "12 is the first one that 4 goes into." Today's line lists every miss ("5 doesn't go into 11 or 22 or 33 or 44…"), which runs long.
- check: `Check with ${a}: it comes out even.` For example, "Check with 4: it comes out even."

### g6-gcf (24 + 36)
- Idea: keep it.
- gcf: `Try the smaller number's factors, biggest first, until one divides both.` Today's line only restates GCF in words.
- factor: `Both rectangles are ${g} tall, so divide each by ${g} for its width.` For example, "Both rectangles are 12 tall, so divide each by 12 for its width." This keeps the caption's picture of the shared height.

### g6-numline (−3 to 5)
- Idea (new): `From a negative to a positive, add the steps to 0 and the steps after 0.` Today's line ("Distance counts steps, so it is never negative") is true but doesn't say how to find it.
- neg: keep it ("From −3 to 0 is 3 steps."). It says what |−3| means.
- pos: keep it.
- sum: `You cross 0, so add the two distances.`

### g6-expo (2³ + 4 × 3)
- Idea (new): `An exponent means multiply the number by itself, and it comes before × and +.` In today's line the "so it goes first" doesn't follow from "a short way to write".
- count: `The small ${n} says how many ${a}s to multiply together.` For example, "The small 3 says how many 2s to multiply together."
- exp: `Work out the exponent first.`
- mul: `Multiply next, before adding.`
- add: `Add last.`

### g6-eval (3x + 2y, x = 4, y = 5)
- Idea: keep it.
- ax: `Swap in x = ${x}: ${a}x means ${a} times x.` For example, "Swap in x = 4: 3x means 3 times x."
- by: `Swap in y = ${y}: ${b}y means ${b} times y.`
- add: `Add the two parts.`

### g6-onestep (x + 7 = 15)
- Idea (new): `An equation is a balance, so do the same thing to both sides.` Today's line ("whatever happens to one side happens to the other") reads as if it happens by itself.
- equation: by `p.t`, `${f(p.a)} is added to x`, `${f(p.a)} is taken away from x`, `x is multiplied by ${f(p.a)}` or `x is divided by ${f(p.a)}`, then `, and the two sides balance.` For example, "7 is added to x, and the two sides balance." Today's "x has + 7 done to it" is hard to read.
- undo: `To undo ${undoes} ${f(p.a)}, ${opp} ${f(p.a)} on both sides.` For example, "To undo + 7, subtract 7 on both sides."
- check: `Put ${f(x)} back in for x: it matches the other side.` For example, "Put 8 back in for x: it matches the other side." This drops the "✓", which read-aloud would speak.

### g6-tri (base 6, height 4)
- Idea: keep it.
- rect: `Draw the rectangle around the triangle.`
- half: `Two copies of the triangle fill it, so take half.`

### g6-trap (bases 4 and 8, height 5)
- Heading (new, 2026-10-13): `Two copies make a rectangle`. Idea (new): `Turn a copy upside down and the two trapezoids make a rectangle, so one trapezoid is half of it.` The picture always draws a right trapezoid, so the child sees a rectangle (see section 4).
- sum: `Lay a turned copy next to it, so the bases sit end to end.`
- times: `The two copies make a rectangle ${S} long and ${h} high.` For example, "The two copies make a rectangle 12 long and 5 high." The picture draws a rectangle, so the line says rectangle (see section 4).
- half: `That's two trapezoids, so one is half.`
- The caption's "same as averaging the bases" is a second method. Drop it: it would make a line too long.

### g6-mean (4, 6, 8)
- Idea: keep it.
- bars: `Each number is a bar.`
- sum: `Put them all together.`
- count: keep it ("There are 3 numbers to share it between.").
- divide: `Share the total out equally. Every bar ends up the same height.`

## 4. Maths and wording errors

- **g6-expo/index.ts:69:** the first three problems use a = 2 or 3 with n = 2, so 2² comes up often. There 2 × 2 = 2² = 4, so the slip on line 28 ("Multiplied the base by the exponent") is marked right, just as the idea is being taught. Fix: `createExponentOrder(rng.int(3, 4), 2, rng.int(2, 5), rng.int(2, 5))`.
- **g6-divide/index.ts:152:** when S ≥ L and the leftover can still be simplified, the narration jumps without saying so. For 3/4 ÷ 1/6 it says "18 ÷ 4 = 4 remainder 2, so 18/4 is 4 and 1/2". Fixed by the new simplify line in section 3 ("…then simplify").
- **g6-divide/index.ts:122 (added 2026-10-13, found by Copy):** the "Multiplied without flipping" message says "Use the flipped fraction from step 1." The steps are size (1), flip (2), multiply (3), so the flip is step 2. Don't number it: `` message: `Multiply by the flipped fraction, ${d}/${c}.` ``
- **g6-trap/index.ts:38-39 (added 2026-10-13, found by Copy):** the heading "Two copies make a parallelogram" and the idea still say parallelogram, while the picture, the hint and the narration say rectangle. The picture (`picture.ts:1`) always draws a right trapezoid, and its turned copy then makes a rectangle. Use the heading and idea in section 3.
- **g6-divide/index.ts:148:** for a unit fraction it reads "4/1 of 1/4 fit in each whole". Fixed by the new flip line.
- **g6-trap/index.ts:25 and :47:** the picture (`picture.ts`) builds a rectangle from the trapezoid and its turned copy, but the hint, the explain and the narration say "parallelogram". A rectangle is a parallelogram, but the child sees a rectangle. Fix line 25 to `` hint: `The two copies make a rectangle: length × height, ${a + b} × ${h}.` `` and its explain to `` `The rectangle is ${a + b} × ${h} = ${(a + b) * h}.` ``. Line 47 is fixed by the new narration.
- **g6-onestep/index.ts:98:** "x has + 7 done to it" is hard to read. **Line 100:** the "✓" is spoken by read-aloud, since Learn only strips `*` and `_`. Both fixed by the new lines in section 3.
- **g6-pctwhole/index.ts:59:** "25% 4 times makes 100%" doesn't read well. Fixed by the new parts line.

## Checks for Development
- No test pins the idea text, as for 5th grade. If a snapshot pins narration, regenerate it. Answers and steps are unchanged, apart from the g6-trap hint and explain wording and the g6-expo early range.
- After the change, check that no Watch one narration line contains its own math line, for these 14 lessons.
- The engine's "light bulb" wording is in the 5th grade spec (section 4). It covers all grades.
