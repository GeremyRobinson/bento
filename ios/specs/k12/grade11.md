# v2 lesson pass: 11th grade

Curriculum, 2026-10-13. For Development. It covers the 13 lessons in `web/src/curriculum/lessons/grade11/`, read on `origin/next` 9c6c07d, together with the v2 learn and practice screens on Design's branch (5d17ed2).
It is content only: lesson text, the depends-on lists and the check recipes. Nothing here changes layout.

## How to read this

**Depends on** lists the lessons a child needs before this one. The lists can cross grades. The first id is the main build-up, so put it in today's single `pre`. The whole list is for Today's step-back.

**Skill check** is the recipe for the lesson's own check. Each item reads `i<N>`, meaning call the lesson's own `generate(rng, N)`. An item can add a `where` condition: redraw, up to 50 tries, until it holds.
- No 11th grade lesson has a story, so no item is a `story`.
- The default is 4 items, with no hints and one try per step, as in the plan.
- Shuffle the items.
- Every 11th grade lesson is wrapped in `withEasyStart`, so from `i3` on a draw is plain. Only two generators read `index` themselves:
  - **g11-synth:** every index with `index % 3 === 2` (i5, i8) has a remainder; the others divide evenly.
  - **g11-comb:** odd indexes choose 3, even indexes choose 2.
- The `where` names are the fields of each lesson's problem type (for example `a1`, `d`, `n` in `SequenceProblem`).

**Gating.** The same point as 5th grade: if "Next" needs every lesson in the list to be learned, a child who opens 11th grade first is sent back to 4th to 9th grade. I suggest a lesson from an *earlier grade* counts as learned until one of its checks comes back 0-2.

## 1. Depends on and skill checks

| Lesson | Depends on | Skill check (4 items) |
|---|---|---|
| g11-seq Arithmetic sequences | g8-func, g4-partial | i3 where n ≥ 20 and d ≥ 5; i3 where n ≤ 15; i3 where a1 ≥ 10; i3. All four need a1 ≠ d. |
| g11-geo Geometric sequences | g11-seq, g6-expo | i3 where r = 2; i3 where r = 3; i3 where n ≥ 7; i3. All four need a ≥ 2. |
| g11-ratexp Rational exponents | g8-roots, g8-exp | i3 where n = 2 and m = 3; i3 where n = 3 and m = 2 and r ≥ 3; i3 where n = 3 and m = 4; i3 where m ≥ 2 |
| g11-expeq Exponential equations | g6-expo, g6-onestep | i3 where c > 0 and k ≥ 3; i3 where c < 0 and k ≥ 3; i3 where b ≠ 2 and k ≥ 3; i3 where b = 2 and k ≥ 5 |
| g11-log Evaluating logarithms | g11-expeq, g8-exp | i3 where b = 2; i3 where b = 3; i3 where b = 5; i3 where b = 10. All four need m ≥ 2 and k ≥ 2, and with b = 2 both ≥ 3. |
| g11-evalpoly Evaluate a polynomial | g8-func, g7-mulint, g6-expo | i3 where k < 0; i3 where b < 0 and k < 0; i3 where a < 0; i3 where k > 0. All four need k ≤ −2 or k ≥ 3. |
| g11-synth Synthetic division | g11-evalpoly, g9-factor, g7-mulint | i3 where r > 0; i4 where r < 0; i5 where r > 0 (has a remainder); i8 where r < 0 (has a remainder). All four need \|r\| ≥ 2. |
| g11-compose Composing functions | g8-func, g7-mulint | i3 where k < 0; i3 where c·k + d < 0; i3 where a < 0; i3. All four need a·d + b ≠ c·b + d. |
| g11-inverse Inverse functions | g7-eq, g7-mulint, g8-func | i3 where b < 0; i3 where a < 0; i3 where x < 0; i3. All four need x ≠ 0. |
| g11-vertex Vertex of a parabola | g11-evalpoly, g7-mulint | i3 where a < 0; i3 where h < 0; i3 where a = 2 or a = 3; i3. All four need c ≠ 0. |
| g11-radical Radical equations | g8-roots, g6-onestep | i3 where a > 0; i3 where a < 0; i3 where b ≥ 6; i3. All four need b ≥ 3. |
| g11-complex Multiplying complex numbers | g9-foil, g7-mulint | i3 where b·d > 0; i3 where b·d < 0; i3 where a < 0 or c < 0; i3 where \|b\| ≥ 2 and \|d\| ≥ 2. All four need not (a = 2 and c = 2). |
| g11-comb Combinations | g4-partial, g5-divide | i3 (choose 3); i5 (choose 3) where n ≥ 9; i4 (choose 2) where n ≥ 8; i6 (choose 2) |

Why some conditions are there:
- **g11-seq:** when a1 = d, the answer a1 + (n − 1)d equals n × d, so the off-by-one slip (n jumps, not n − 1) lands on the right answer.
- **g11-geo:** with a = 1 the last step is "1 × the power", so it tests nothing.
- **g11-ratexp:** with m = 1 the power step is r¹ = r. For square roots the top is only ever 1 or 3 (the generator moves 2 to 3), so the first item takes 3. With r = 2 and m = 2, the "multiplied by the top" slip (2 × 2) equals 2².
- **g11-expeq:** with b = 2 and k = 2, the "divided" slip (4 ÷ 2) equals k.
- **g11-log:** with m = 1 the "divided instead" slip (b ÷ b = 1) equals the answer for every base, and with b = 2 and m = 2 it does too (4 ÷ 2 = 2).
- **g11-evalpoly:** with k = 2 the "doubled instead of squared" slip (2 × 2) equals 2², and k = ±1 makes the square trivial.
- **g11-synth:** with r = ±1 every multiply step just copies a number. The four items cover a box number of each sign, with and without a remainder.
- **g11-compose:** when a·d + b = c·b + d, doing f first gives the same answer, so the "wrong order" slip can't be seen.
- **g11-inverse:** with x = 0 the "multiplied again" slip (0 × a) also gives 0.
- **g11-vertex:** with c = 0 the "left out c" slip gives the right y.
- **g11-radical:** with b = 2 the "doubled instead" slip (2 × 2) equals 2².
- **g11-complex:** with a = c = 2 the "added" slip (2 + 2) equals 2 × 2. The first two items cover the corner b·d·i² coming out negative and positive.
- **g11-comb:** for choose 2, the "counted the picks" slip (2) equals 2! = 2, so the check leans on choose 3. n ≥ 8 or 9 keeps the products past easy recall.

Changes from today's `pre`:
- **g11-seq** gets g8-func (was none). Term n is a rule in n, start plus a step times a count, like f(x) = mx + b. The climb goes up to 29 × 9, which is g4-partial.
- **g11-expeq** gets g6-expo (was none). The first step counts how many times the base multiplies to make the number. The second step is x + c = k, which is g6-onestep.
- **g11-evalpoly** gets g8-func (was none). It is putting a number in for x, now with a square and negatives.
- **g11-compose** gets g8-func (was none). Both machines are linear functions evaluated at a number.
- **g11-inverse** moves from g11-compose to g7-eq. The steps undo ax + b in reverse order (subtract, then divide), which is a two-step equation. Nothing composes.
- **g11-vertex** moves from g9-solvefactor to g11-evalpoly. The y step evaluates a quadratic at x = h. No step solves or factors.
- **g11-radical** gets g8-roots (was none). Squaring undoes the root.
- **g11-comb** gets g4-partial (was none). The idea of counting orders is new; what it leans on is multiplying up to 12 × 11 × 10 and dividing up to 1320 ÷ 6.
- g11-geo, g11-ratexp, g11-log, g11-synth and g11-complex keep their `pre` as the first id.
- Set `pre` in each changed lesson's own `index.ts` too. `tests/curriculum/held-8-12.test.ts:47` checks the module matches the catalog for grades 8-12. g11-inverse (`index.ts:78`) and g11-vertex (`index.ts:77`) change an existing line. g11-seq, g11-expeq, g11-evalpoly, g11-compose, g11-radical and g11-comb need a new `pre:` line.

## 2. Show the problem once

On the v2 stage the problem shows once (display, or lead). No 11th grade lesson has a lead, story, counters or picture, so only the notes can repeat. One does.

- **g11-comb** (`grade11/g11-comb/index.ts:78`): the display "C(5, 2)" and the note "How many ways to choose 2 from 5 when order doesn't matter?" say the same thing with the same numbers. Change the note so it explains the letters and doesn't repeat the numbers, as 8th grade did for g8-pyth:
  `C(n, k) counts the groups of k you can choose from n. Order doesn't matter.`

The other 12 are fine.
- The notes in g11-seq, g11-geo, g11-expeq, g11-evalpoly, g11-compose, g11-inverse, g11-vertex and g11-radical give the instruction ("Find term number 20.", "Find f(−2).", "Solve for x."), not a second copy.
- g11-synth's note "Use 2 in the box. Bring down the 1." is the method's start, which the display doesn't show.
- g11-ratexp, g11-log and g11-complex have no note.

## 3. Watch one: idea line and narration

In v2, Watch one prints each step's math line with its narration underneath, and speaks both. The rule for every line below: **the narration says what the step does or why, in words, and leaves the equation to the math line.** Lines stay under about 12 words.

- **The worked example** stays each lesson's `reference`.
- **The idea line** is `idea[0]`, one sentence. Every 11th grade lesson has one sentence today, and all 13 are correct and readable, so none change.
- **Captions** aren't shown in v2. Where a caption carried something worth keeping, it moves into a narration line below.
- Placeholders use the variable names already in each `explain()`. The examples are rendered for the reference problem.

### g11-seq (5, 9, 13, 17, …, term 20)
- Idea: keep it.
- d: `Each term goes up by the same amount: ${a1 + d} − ${a1}.` For example, "…: 9 − 5." The subtraction isn't on the math line "d = 4".
- jumps: `Term 1 is where you start, so it's one jump fewer than ${n}.`
- climb: `Each of the ${count(jumps, "jump")} climbs ${d}.` For example, "Each of the 19 jumps climbs 4."
- term: `Start at the first term and add the climb.`

### g11-geo (3, 6, 12, 24, …, term 6)
- Idea: keep it.
- terms: `Find term ${n}. Each term is the one before times the same number.` Today's line reads the four terms that are already the math line.
- r: `Divide a term by the one before: each term is ${r === 2 ? "double" : "triple"} the last.` This keeps the caption's point.
- pow: `From term 1 to term ${n} is ${count(n - 1, "jump")}, each one × ${f(r)}.` For example, "From term 1 to term 6 is 5 jumps, each one × 2." (See section 4.)
- term: `Start at the first term and multiply by the growth from all the jumps.`

### g11-ratexp (8 to the 2/3)
- Idea: keep it.
- problem: keep it. ("The exponent is a fraction: the bottom 3 is a cube root, the top 2 is a power." explains, it doesn't repeat.)
- root: `Take the ${root} root first, because ${Array.from({ length: n }, () => f(r)).join(" × ")} = ${f(base)}.` For example, "Take the cube root first, because 2 × 2 × 2 = 8."
- power: `Then raise it to the top number, ${f(top)}.`

### g11-expeq (2 to the x + 1 = 16)
- Idea: keep it.
- problem: keep it.
- base: `Multiply ${f(b)}'s until you reach ${big(value)}, and count them.` For example, "Multiply 2's until you reach 16, and count them." (See section 4.)
- match: `Same base on both sides, so the exponents must be equal.` Today's line is 16 words.
- solve: `Undo the ${fpm(c)} to get x on its own.` For example, "Undo the + 1 to get x on its own."

### g11-log (log₂ 8 + log₂ 4)
- Idea: keep it.
- ask: keep it.
- m: `${f(b)} to what power makes ${big(b ** m)}? ${f(b)}${supText(m)} = ${big(b ** m)}.` For example, "2 to what power makes 8? 2³ = 8." The reason stays; "so it is 3" goes, since the math line says it.
- k: `Same question for ${big(b ** k)}: ${f(b)}${supText(k)} = ${big(b ** k)}.` For example, "Same question for 4: 2² = 4."
- sum: `Add the exponents. It's log${subText(b)} of ${big(b ** m)} × ${big(b ** k)}, since ${f(b)}${supText(m)} × ${f(b)}${supText(k)} = ${f(b)}${supText(s)}.` For example, "Add the exponents. It's log₂ of 8 × 4, since 2³ × 2² = 2⁵." This uses m then k, in the order of the sum (section 4).

### g11-evalpoly (f(x) = 2x² − 3x + 1, find f(−2))
- Idea: keep it.
- plug: keep it.
- square: `Powers come first: square ${f(k)}, then multiply by ${f(a)}.` For example, "Powers come first: square −2, then multiply by 2."
- linear: `Multiply the x term: ${b * k < 0 ? "one negative makes it negative" : b < 0 ? "two negatives make a positive" : "two positives make a positive"}.` For example, "Multiply the x term: two negatives make a positive."
- total: `Add the ${c ? "three" : "two"} parts. So (${f(k)}, ${f(total)}) is on the graph.` For example, "Add the three parts. So (−2, 15) is on the graph."

### g11-synth ((x² + x − 6) ÷ (x − 2))
- Idea: keep it.
- setup: `${f(r)} goes in the box, since it makes x ${r < 0 ? "+" : "−"} ${f(Math.abs(r))} equal 0.` For example, "2 goes in the box, since it makes x − 2 equal 0." This is the caption's point, and the row of numbers stays on the math line.
- mul1: `Bring down the 1, then multiply it by the box number.`
- add1: `Add down the column. The flipped sign already did the subtracting.`
- mul2: `Multiply the new bottom number by the box number.`
- rem: `Add the last column.` Then `${rem === 0 ? " 0 left over means it divides evenly." : " What's left over is the remainder."}`
- check: keep it. ("Check: put 2 into the polynomial and you get 0, the same as the remainder." explains, it doesn't repeat.)
- quot: `Read the bottom row: the 1 goes with x, and the last number is the remainder.`

### g11-compose (f(x) = x + 1, g(x) = 2x, find f(g(3)))
- Idea: keep it.
- problem: keep it.
- inside: `Inside first: work out what g gives back.`
- outside: `Then the outside: what g gave back, ${f(g)}, goes into f.` For example, "…what g gave back, 6, goes into f."

### g11-inverse (f(x) = 3x + 2, find f⁻¹(14))
- Idea: keep it.
- ask: `Which input gives ${f(y)}? Undo f's steps in reverse order.` Today's line starts by reading the math line "f(x) = 3x + 2".
- sub: `f adds ${fP(b)} last, so undo that first.` For example, "f adds 2 last, so undo that first."
- x: `Then undo the × ${fP(a)}. Check: f(${f(x)}) = ${f(y)}, so ${pt(x, y)} mirrors to ${pt(y, x)}.` For example, "Then undo the × 3. Check: f(4) = 14, so (4, 14) mirrors to (14, 4)." This keeps the caption's mirror point.

### g11-vertex (y = x² − 6x + 5)
- Idea: keep it.
- eq: keep it. ("Here a = 1 and b = −6." picks out a and b, it doesn't repeat.)
- x: `Use x = −b ÷ 2a. That is the line of symmetry.`
- y: `Put x = ${f(h)} back in for the height. The vertex is ${pt(h, k)}.` For example, "Put x = 3 back in for the height. The vertex is (3, −4)."

### g11-radical (√(x + 3) = 5)
- Idea: keep it.
- problem: keep it.
- both: keep it.
- square: `${f(b)} × ${f(b)} on the right, and the root is gone on the left.` For example, "5 × 5 on the right, and the root is gone on the left."
- solve: `Undo the ${fpm(a)} to get x on its own.` For example, "Undo the + 3 to get x on its own."
- check: `Check in the first equation, since squaring can add answers that don't work.` This ties the check to the idea line.

### g11-complex ((2 + 3i)(1 + 4i))
- Idea: keep it.
- first: `First × first: the two plain numbers.`
- last: `Last × last: i times i is −1, so the sign flips.`
- real: `The plain numbers together make the real part.`
- imag: `Outer and inner are the i terms. So the product is ${complexText(re, im)}.` For example, "…So the product is −10 + 11i." The full product isn't on any math line, so it stays.

### g11-comb (C(5, 2))
- Idea: keep it.
- things: keep it.
- ordered: `Pick one at a time: ${n} choices first, then one fewer each pick.` For example, "Pick one at a time: 5 choices first, then one fewer each pick."
- orders: `The same ${k} things in any order are still one group.` Today's line is 17 words.
- divide: `Each group was counted ${f} times, so divide out the repeats.` For example, "Each group was counted 2 times, so divide out the repeats." This is the caption's point. (`f` here is the number of orders, as in `explainCombination`.)

## 4. Maths and wording errors

- **g11-synth** (`grade11/g11-synth/index.ts:88`): the last Watch one line reads "x + 3, remainder 0" when it divides evenly, but practice's finished line (`index.ts:57`) reads "x + 3". Leave the remainder out when it is 0:
  `math: [v(), op(quot < 0 ? "−" : "+"), num(Math.abs(quot)), ...(rem ? [text(", remainder "), num(rem)] : [])]`
- **g11-log** (`grade11/g11-log/index.ts:81`): the sum line says "log₂ of 8 × 4, since 2² × 2³ = 2⁵". The product is written in the other order from the logs (it uses `lo` and `hi`). The new narration in section 3 uses m then k, so it reads "2³ × 2² = 2⁵".
- **g11-geo** (`grade11/g11-geo/index.ts:72`): "multiply by 2 5 times" reads as "two five times" when spoken. The new pow line in section 3 replaces it.
- **g11-expeq** (`grade11/g11-expeq/index.ts:56`): "4 2's multiply to 16" has the same problem. The new base line in section 3 replaces it.

No maths errors in the answers, hints or known slips. I checked each slip value against its step's answer; the only overlaps are the cases the check conditions in section 1 avoid.

## Checks for Development
- No test pins the idea text, and no idea line changes here. If a snapshot pins narration, regenerate it. Answers and steps are unchanged, apart from the g11-synth math line when the remainder is 0.
- After the change, check that no Watch one narration line contains its own math line, for these 13 lessons. The narration should not include the math line's text.
- For Design, not a lesson change: `Learn.tsx:72` speaks the heading and statement at state 0, so a state-0 step's narration is shown but never read aloud. In g11-seq that step is the first answer step ("d"). It is the only 11th grade lesson whose state-0 step is an answer step.
