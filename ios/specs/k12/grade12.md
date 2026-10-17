# v2 lesson pass: 12th grade

Curriculum, 2026-10-13. For Development. It covers the 13 lessons in `web/src/curriculum/lessons/grade12/`, read on `origin/next` 9c6c07d, together with the v2 learn and practice screens on Design's branch (5d17ed2).
It is content only: lesson text, the depends-on lists and the check recipes. Nothing here changes layout.

## How to read this

**Depends on** lists the lessons a child needs before this one. The lists can cross grades. The first id is the main build-up, so put it in today's single `pre`. The whole list is for Today's step-back.

**Skill check** is the recipe for the lesson's own check. Each item reads `i<N>`, meaning call the lesson's own `generate(rng, N)`. An item can add a `where` condition: redraw, up to 50 tries, until it holds.
- No 12th grade lesson has a story, so no item is a `story`.
- The default is 4 items, with no hints and one try per step, as in the plan.
- Shuffle the items.
- Every 12th grade lesson is wrapped in `withEasyStart`, so `i3` and up are plain draws from the full range.
- Two generators read `index` themselves. g12-unit: odd index is sin, even is cos, and from i3 on the angle is random. g12-defint: from i3 on the bottom bound j is 1 or more. The other 11 ignore `index`.
- The `where` names are the fields of each lesson's problem type (for example `t` in `DegreesToRadiansProblem`, `a`, `b`, `k` in `TangentProblem`).

**Gating.** The same point as 5th grade: if "Next" needs every lesson in the list to be learned, a child who opens 12th grade first is sent back to 6th-11th grade. I suggest a lesson from an *earlier grade* counts as learned until one of its checks comes back 0-2.

## 1. Depends on and skill checks

| Lesson | Depends on | Skill check (4 items) |
|---|---|---|
| g12-rad Degrees to radians | g10-arc, g6-gcf | i3 where 90 < t < 180; i3 where 180 < t < 270; i3 where t > 270; i3 |
| g12-deg Radians to degrees | g12-rad, g5-fracof | i3 where d = 6 and n ≥ 5; i3 where d = 4 and n ≥ 3; i3 where d = 3 and n ≥ 2; i3 where n > d (past a half turn) |
| g12-unit Unit circle values | g10-special, g10-trig | i3 where t > 180 (sin, negative); i4 where 90 < t < 270 (cos, negative); i5 where t = 150 (sin, positive past 90°); i6 where t = 300 (cos, positive in quadrant 4) |
| g12-limit Limits by factoring | g9-factor, g8-func | i3 where a > 0 and b < 0; i3 where a < 0 and b > 0; i3 where a < 0 and b < 0; i3 where a > 0, b > 0 and b ≠ a |
| g12-power Power rule | g8-slope, g6-expo | i3 where n ≥ 3; i3 where n ≥ 4 and a ≥ 4; i3 where n = 2 and a ≥ 3 (f′ is a plain x, no exponent); i3 where n ≥ 3 and a ≥ 5 |
| g12-polyd Derivative of a polynomial | g12-power, g7-mulint | i3 where b < 0; i3 where a < 0; i3 where c < 0; i3 where 3a + 2b + c < 0 (the graph falls at x = 1). All four also need d ≠ 0 and d ≠ 2a + b. |
| g12-tangent Slope of a tangent line | g12-polyd, g8-func | i3 where k ≤ −2; i3 where a < 0 and k ≥ 2; i3 where b < 0; i3 where k ≥ 2 or k ≤ −2. All four also need slope ≠ fk. |
| g12-chain Chain rule | g12-power, g11-compose | i3 where b < 0 and a ≠ n; i3 where b > 0, n ≥ 3 and a ≠ n; i3 where n = 2 and a ≥ 3 (the new exponent is 1); i3 where a ≠ n |
| g12-anti Antiderivatives | g12-power, g7-mulint | i3 where a < 0; i3 where n = 1 (∫ ax dx); i3 where n ≥ 3 and a ÷ (n + 1) ≥ 2; i3 where a ÷ (n + 1) ≠ 1 |
| g12-defint Definite integrals | g12-anti, g6-expo | i3 where n = 1 and a ÷ (n + 1) ≥ 2; i3 where n = 2; i3 where n = 3 and k ≤ 3; i3 where j ≥ 2 |
| g12-series Arithmetic series | g11-seq | i3 where n is odd; i3 where n is even and d ≥ 2; i3 where n ≥ 20; i3 where a ≥ 2 |
| g12-vecmag Vector length | g10-dist, g8-pyth | i3 where x < 0 and y > 0; i3 where x > 0 and y < 0; i3 where x < 0 and y < 0; i3 where m ≥ 13 |
| g12-dot Dot product | g12-vecmag, g7-mulint | i3 where a·c > 0 and b·d < 0; i3 where a·c < 0 and b·d > 0; i3 where a·c + b·d < 0; i3 where a·c + b·d > 0. All four also need a ≠ b and a ≠ c. |

Why some conditions are there:
- **g12-rad:** the three bands give a share inside the half turn (2π/3, 3π/4, 5π/6), one past it, and one near the full turn. 30°, 45°, 60° and 90° all give 1 on top, so the random fourth item is the only one that may be that easy.
- **g12-deg:** with n = 1 the "times the top" step is × 1 and tests nothing.
- **g12-unit:** the sign is the idea. The items cover sin and cos on both sides, and 150° and 300° catch "past 90° means negative".
- **g12-limit:** the factor step is a sign question, so the items cover all four sign pairs. With b = a the top has no middle term (x² − 4), which is a different look, so the last item avoids it.
- **g12-power:** with a = n = 2, adding and multiplying both give 4, so "Added instead of multiplied" can't be seen. Every item avoids it.
- **g12-polyd:** when d = 2a + b, f(1) and f′(1) are the same number, so "Used f instead of f′" can't be seen. With d = 0 the "constant drops out" part is missing.
- **g12-tangent:** when slope = fk, f(k) and f′(k) are the same number. With k = ±1 the plug-in step is trivial.
- **g12-chain:** with a = n, the check can't tell "Forgot the inside" from "Dropped the power's number".
- **g12-anti, g12-defint:** with a ÷ (n + 1) = 1, "Didn't divide" is the only slip left to catch, so most items ask for a bigger number in front.
- **g12-dot:** a = b makes "Mixed the parts" (a·d) equal b·d, and a = c = 2 makes "Added" equal the product. A perpendicular pair (dot = 0) is only about 1 draw in 60, so 50 redraws find it only about half the time. I left it out. If Development wants a 0 item, the generator needs its own index band that builds one, for example ⟨c, d⟩ = k⟨−b, a⟩.

Changes from today's `pre`:
- **g12-rad** gets g10-arc (was none). Arc length already writes an angle as a share of the turn and puts the fraction in lowest terms. This lesson does the same with the half turn.
- **g12-power** gets g8-slope (was none). Every step ends in "the graph climbs c for each 1 across", which is slope.
- The other 11 keep their `pre` as the first id.
- Neither g12-rad nor g12-power sets `pre` in its own `index.ts`, so the change is in `catalog.ts` only. (g12-deg, g12-unit, g12-limit, g12-polyd, g12-tangent, g12-chain, g12-anti, g12-defint, g12-series, g12-vecmag and g12-dot set `pre` in `index.ts` too, and those all stay the same.)

## 2. Show the problem once

On the v2 stage the problem shows once (display, or lead). No 12th grade lesson has a lead, counters, a story or a practice picture, and all 13 are fine.
- The notes in g12-rad, g12-deg, g12-power, g12-polyd, g12-tangent, g12-chain, g12-series and g12-vecmag add the instruction ("Write it in radians.", "Find the slope at x = 2.", "Add the first 100 terms."), not a second copy.
- g12-unit, g12-limit, g12-anti, g12-defint and g12-dot have no note.
- None of the displays triggers the "What is x?" ask line.

One repeat sits inside Watch one instead: in g12-chain two steps in a row show the same math line. See g12-chain in section 3.

## 3. Watch one: idea line and narration

In v2, Watch one prints each step's math line with its narration underneath, and speaks both. The rule for every line below: **the narration says what the step does or why, in words, and leaves the equation to the math line.** Lines stay under about 12 words.

- **The worked example** stays each lesson's `reference`.
- **The idea line** is `idea[0]`, one sentence. Every 12th grade lesson has one sentence today.
- **Captions** aren't shown in v2. Where a caption carried something worth keeping, it moves into a narration line below.
- Placeholders use the variable names already in each `explain()`. The examples are rendered for the reference problem.

### g12-rad (120°)
- Idea: keep it.
- half-turn: keep it. ("A half turn is 180°, which is π radians. Write 120° as a share of it.")
- gcf: `${g} is the biggest number dividing ${t} and 180, so use ${g}° pieces.` For example, "60 is the biggest number dividing 120 and 180, so use 60° pieces." Today's line also says "there are 3", which is the math line.
- radians: `${t}° is ${count(n, "piece")}, out of ${d} in a half turn: ${piText(n, d)}.` For example, "120° is 2 pieces, out of 3 in a half turn: 2π/3." This keeps the caption's point.

### g12-deg (5π/6)
- Idea: keep it.
- half-turn: `${piText(n, d)} is ${count(n, "piece")} of π/${d}, and π is a half turn.` For example, "5π/6 is 5 pieces of π/6, and π is a half turn." Today's line starts with "π is a half turn, 180°", which is the math line.
- piece: `One piece is the half turn cut into ${d} equal parts.` For example, "One piece is the half turn cut into 6 equal parts."
- degrees: `Take ${count(n, "piece")} of that size.` For example, "Take 5 pieces of that size."

### g12-unit (sin 210°)
- Idea: keep it.
- angle: keep it.
- quadrant: `${t}° is past ${(quad - 1) * 90}° but not yet ${quad * 90}°.` For example, "210° is past 180° but not yet 270°."
- reference: `Measure back to the nearest side of the x-axis, never the y-axis.`
- value: `${f} ${ref}° is 1/2. The point is ${where}, so it's ${pos ? "positive" : "negative"}.` For example, "sin 30° is 1/2. The point is below the x-axis, so it's negative." (Here `f` is the function name, "sin" or "cos", as in the file.)

### g12-limit (lim x→2 of (x² − 4) ÷ (x − 2))
- Idea: keep it.
- zero: keep it.
- b: `${factor(a)} is a factor of the top, so cancel it from both.` For example, "(x − 2) is a factor of the top, so cancel it from both."
- lim: `Put x = ${f(a)} into what's left: the line heads there, past the hole.` For example, "Put x = 2 into what's left: the line heads there, past the hole." This keeps the caption's point.

### g12-power (f(x) = 3x⁴)
- Idea: keep it.
- problem: `f′ tells how steep f is. The exponent ${f(n)} is what comes down.` A shorter form of today's line.
- coefficient: `Bring the exponent down to multiply the ${f(a)} in front.` For example, "Bring the exponent down to multiply the 3 in front."
- exponent: `Then lower the exponent by 1, so x${supText(n)} becomes x${supE(e)}.` For example, "Then lower the exponent by 1, so x⁴ becomes x³."
- write: `Put the new number in front of the new power.`
- slope: `At x = 1, the graph of f climbs ${f(c)} for each 1 across.` For example, "At x = 1, the graph of f climbs 12 for each 1 across." c is always positive here (a ≥ 1, n ≥ 2), so today's "falls" branch can go.

### g12-polyd (f(x) = 2x³ − x² + 5x + 7)
- Idea: keep it.
- problem: keep it.
- x3: `x³ term: bring the 3 down onto the ${f(a)}, and x³ becomes x².` For example, "x³ term: bring the 3 down onto the 2, and x³ becomes x²."
- x2: `x² term: bring the 2 down onto the ${f(b)}, and x² becomes x.` For example, "x² term: bring the 2 down onto the −1, and x² becomes x."
- x1: `${coef(C, "x")} is a line with slope ${f(C)}.${d ? " A constant is flat, so it drops out." : ""}` For example, "5x is a line with slope 5. A constant is flat, so it drops out."
- at1: `Powers of 1 are 1, so add: ${total > 0 ? `the graph climbs ${f(total)} per 1 across` : total < 0 ? `the graph falls ${f(-total)} per 1 across` : "the graph is flat there"}.` For example, "Powers of 1 are 1, so add: the graph climbs 9 per 1 across."

### g12-tangent (f(x) = x² + 3x, at x = 2)
- Idea: keep it.
- curve: `Find how steep the curve is at x = ${f(k)}.` Today's line starts by reading the math line.
- derivative: `Bring the 2 down onto the ${f(a)}; the x term leaves just ${f(b)}.` For example, "Bring the 2 down onto the 1; the x term leaves just 3."
- slope: `Put x = ${f(k)} into f′. The line touches the curve at ${pt(k, fk)}.` For example, "Put x = 2 into f′. The line touches the curve at (2, 10)."
- After this, `lineText`, `paren` and `signed` are no longer used in `explanation.ts`. Remove them from the imports.

### g12-chain (f(x) = (3x + 1)⁴)
- Idea: keep it.
- problem: keep it.
- outside: `Outside first: the power rule, with the inside left as it is.` This is the picture's "unchanged" point. Today's line ends by reading the new exponent from the math line.
- why: `The inside moves ${f(a)} per 1 of x, so it all runs ${f(a)} times faster.` For example, "The inside moves 3 per 1 of x, so it all runs 3 times faster." Today's line is 24 words.
- inside: **change the math line.** Today `why` and `inside` both show `d/dx(3x + 1) = 3`, one under the other, because `da` is always `a` (`index.ts:57` and `:58`). Give `inside` the line it already builds for the old chain picture: `math: [num(n), ...wrapped(a, b, e), op("·"), mark(da)]`, which reads "4(3x + 1)³ · 3". Narration: `So multiply what the outside gave by the inside's slope.`
- front: `The two numbers in front multiply to ${f(front)}.` For example, "The two numbers in front multiply to 12."

### g12-anti (∫ 6x² dx)
- Idea: keep it.
- problem: keep it.
- raise: `Derivatives lower the exponent, so going back raises it by 1.`
- divide: `Divide by the new exponent, and add + C: a constant's derivative is 0.`
- check: `Check: the derivative takes it back to what we started with.`

### g12-defint (∫₀² 3x² dx)
- Idea: keep it.
- curve: `It is the area under y = ${powerText(a, n)} from x = ${f(j)} to ${f(k)}.` For example, "It is the area under y = 3x² from x = 0 to 2."
- anti: `Run the power rule backwards: raise the power, then divide by it.` Today's line ends with "So F(x) = x³.", which is the math line.
- area:
  - j = 0: `F(${f(k)}) is the area from 0 up to ${f(k)}, and F(0) is 0.` For example, "F(2) is the area from 0 up to 2, and F(0) is 0."
  - j > 0: `F(${f(k)}) − F(${f(j)}): take away the area from 0 to ${f(j)}.` For example, for ∫₁³ 4x dx, "F(3) − F(1): take away the area from 0 to 1."

### g12-series (1 + 2 + 3 + … , 100 terms)
- Idea (new): `Pair the terms from both ends, and every pair adds to the same total.` Today's line says "the same total as every other pair", and "every other" can read as "every second one".
- terms: keep it.
- last: `Term ${f(n)} is ${f(n - 1)} ${noun(n - 1, "jump")} on from the first, not ${f(n)}.` For example, "Term 100 is 99 jumps on from the first, not 100."
- pair: `Pair the ends. Moving in, one goes up ${f(d)} and one down ${f(d)}.` For example, "Pair the ends. Moving in, one goes up 1 and one down 1." This is the caption's point.
- sum (the `pairs` text):
  - n even: `${f(n)} terms make ${f(n / 2)} pairs, each worth ${f(pair)}.` For example, "100 terms make 50 pairs, each worth 101."
  - n odd: `${f(n)} terms make ${f(n)} ÷ 2 pairs: the middle term is half a pair.`

### g12-vecmag (v = ⟨3, −4⟩)
- Idea: keep it.
- v: keep it.
- sum: `Those are the legs of a right triangle, so square each and add.`
- m: `The arrow is the long side, so take the square root.`

### g12-dot (⟨2, 3⟩ · ⟨4, −1⟩)
- Idea (new): `The sign tells the angle: positive under 90°, 0 at 90°, negative over 90°.` Today's line says positive means the arrows "point the same way", but two arrows 80° apart also give a positive dot product. The new line matches the caption and the last step.
- vs: `Two arrows from the origin. Match their x parts and their y parts.` Today's line reads the two arrows again.
- x: `Multiply the x parts, the first number of each arrow.`
- y: `Multiply the y parts, the second number of each arrow.`
- dot: `Add the two products. ${D === 0 ? "0: the arrows are perpendicular." : D > 0 ? "Positive: less than a right angle apart." : "Negative: more than a right angle apart."}` For example, "Add the two products. Positive: less than a right angle apart."

## 4. Maths and wording errors

- **g12-unit, `index.ts:38`:** the quadrant box takes a number and the math line says "quadrant 3", but the hint and the "Turned clockwise" message use Roman numerals. Write them as numbers:
  - hint: `1 is 0–90°, 2 is 90–180°, 3 is 180–270°, 4 is 270–360°.`
  - message: `Angles turn counterclockwise from the right, through 1, 2, 3, 4.`
- **g12-chain, `index.ts:57-58`:** the `why` and `inside` steps show the same math line twice in a row. Fix in section 3.
- **g12-defint, `answers.ts:7-8`:** when c = 1, the top-minus-bottom line reads `1·2³ − 1·0³`, while the line above it writes the antiderivative as x³, not 1x³. When c = 1, drop the `num(c), op("·")` parts so it reads `2³ − 0³`. This is used by both the answer prompt and the Watch one line.
- **g12-dot, `index.ts:51`:** the idea line says positive means "the same way", which is too strong. Fix in section 3.
- **g12-series, `index.ts:52`:** "every other pair" is ambiguous. Fix in section 3.
- **g12-tangent, `explanation.ts:44`:** the narration builds f′(x) with `lineText(da, b, "").slice(3)`, which cuts a fixed 3 characters off the front. It works today, but the new narration in section 3 drops it.

No answer is wrong in any of the 13 lessons. I checked every step's expected value against its math, and every wrong-answer message against the slip it names.

## Checks for Development
- No test pins the idea text. If a snapshot pins narration, regenerate it. Answers are unchanged. Steps change only in the g12-chain `inside` math line and the g12-defint c = 1 line.
- After the change, check that no Watch one narration line contains its own math line, for these 13 lessons (Learn.tsx `saysMath` does this test already).
- Change `pre` for g12-rad and g12-power in `catalog.ts`.
- Remove the unused imports in `g12-tangent/explanation.ts`.
