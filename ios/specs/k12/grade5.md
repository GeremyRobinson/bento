# v2 lesson pass: 5th grade

Curriculum, 2026-10-13. For Development. It covers the 17 lessons in `web/src/curriculum/lessons/grade5/`, read on `origin/next` 3ccaa07, together with the v2 learn and practice screens on Design's branch (e2e3154).
It is content only: lesson text, the depends-on lists and the check recipes. Nothing here changes layout.

## How to read this

**Depends on** lists the lessons a child needs before this one. The lists can cross grades. The first id is the main build-up, so put it in today's single `pre`. The whole list is for Today's step-back.

**Skill check** is the recipe for the lesson's own check. Each item reads `i<N>`, meaning call the lesson's own `generate(rng, N)`. An item can add a `where` condition: redraw, up to 50 tries, until it holds.
- `story` means show that item as the lesson's story, which tests whether the child sees the operation in words.
- The default is 4 items, with no hints and one try per step, as in the plan.
- Shuffle the items, but put a `story` item last.

**One thing to decide on gating.** If "Next" requires every lesson in the list to be learned, a child who opens 5th grade first is sent back to 4th grade. I suggest that a lesson from an *earlier grade* counts as learned until one of its checks comes back 0-2. Then cross-grade links only do their real job: stepping back after a low check.

## 1. Depends on and skill checks

| Lesson | Depends on | Skill check (4 items) |
|---|---|---|
| g5-mult2 Multiply two-digit numbers | g4-mult2x2, g3-mult10 | i3, i3, i3 where the second factor's ones digit is 6 or more, i3 story |
| g5-divide Long division | g4-divide, g3-mult10 | i3 where dv ≤ 9; i3 where dv ≥ 11, twice; i3 story |
| g5-order Order of operations | g3-facts, g3-divfacts | i3 (shape t0), i4 (t1), i5 (t2), i6 (t0). No story. The "What goes first?" step is the idea, so keep it. |
| g5-pow10 Multiply by 10, 100, 1000 | g4-dec, g4-placevalue | i3 where k = 1; i3 where k = 2; i3 where k = 3 and x has fewer than 3 decimal digits (needs zeros written in); i3 |
| g5-round Rounding decimals | g4-placevalue, g4-dec | i3 where p = 1 and it stays; i3 where p = 1 and it rounds up; i3 where p = 2; i5 (rolls a 9 over) |
| g5-adddec Adding decimals | g4-dec, g4-addsub | i3 where the decimal parts make 1 or more; i3 where they make less than 1; i3; i3 story |
| g5-multdec Multiplying decimals | g4-partial, g4-dec | i1 (tenths × whole), i4 (tenths × tenths), i7 (hundredths × tenths), i5 story |
| g5-divdec Dividing by a decimal | g5-pow10, g3-divfacts | i0 where qt ≥ 7; i0 where qt ≥ 10; i0; i0 story |
| g5-improper Mixed numbers to fractions | g4-mixed | i3, i3 where d ≥ 6, i3 where w ≥ 4, i3 |
| add Adding fractions | g4-equiv, g4-likefrac, g4-factors | i1, i3 where the answer is more than 1, i3 where the answer simplifies, i4 story |
| sub Subtracting fractions | add | i1, i3 where neither bottom is a multiple of the other, i3 where the answer simplifies, i4 story |
| mix Adding and subtracting | add, sub | i2 (+), i3 (−), i4 (+), i5 (−). The sign changes between items, which is the point of this lesson. |
| g5-fracof Fraction of a number | g3-divfacts, g4-fracwhole | i3 where n > 1, twice; i3; i3 story |
| g5-multfrac Multiplying fractions | g5-fracof, g4-equiv | i3 where the answer simplifies; i3 where it doesn't; i3; i3 story |
| g5-unitdiv Dividing by a unit fraction | g3-unitfrac, g3-facts | i3, i3, i3, i3 story |
| g5-volume Volume of a box | g4-area, g4-partial | i3, i3, i3 where h is the biggest side, i3 |
| g5-units Converting units | g4-convert, g4-partial | i1 (big to small), i4 (small to big), i5 (small to big), i7 where n is not a whole number of big units. Keep the "More or fewer?" step, which is the idea. |

Changes from today's `pre`:
- **g5-order** moves from g5-mult2 to g3-facts. The problems use one-digit facts, so the order is what's hard, not the arithmetic.
- **g5-divdec** moves from g5-divide to g5-pow10. The quotient is at most 12, so this lesson is about moving the point, not long division.
- **add** moves from g4-fraccompare to g4-equiv.
- **sub** moves from g4-likefrac to add.
- **g5-unitdiv** moves from g5-fracof to g3-unitfrac.
- **g5-fracof** moves from g4-fracwhole to g3-divfacts.
- The rest keep their `pre` as the first id in the list.

## 2. Show the problem once

On the v2 stage the problem shows once (display, or lead, or story). Two lessons say it twice.

- **g5-volume:** the display "4 × 3 × 2" and the note "A box 4 cm long, 3 cm wide and 2 cm tall…" repeat each other, and the display also gives away the method. Remove `displayNote` and add a `lead`:
  `A box is **${l}** cm long, **${w}** cm wide and **${h}** cm tall. How many 1 cm cubes fill it?`
- **g5-unitdiv:** the display "3 ÷ 1/4" and the note "How many 1/4 pieces fit in 3?" say the same thing. Remove `displayNote`. The idea line and the first step ("How many 1/4 pieces make 1 whole?") already carry the meaning.

The other 15 are fine.
- g5-round's "Round to the nearest hundredth." and g5-improper's "Write it as one fraction." add the instruction, not a second copy of the problem.
- Stories replace the math line, so they don't repeat it.

## 3. Watch one: idea line and narration

In v2, Watch one prints each step's math line with its narration underneath, and speaks both. Most narrations today end by repeating their own math line ("Whole parts: 12 + 3 = 15." under "12 + 3 = 15"), so the child reads and hears everything twice. The rule for every line below: **the narration says what the step does or why, in words, and leaves the equation to the math line.** Lines stay under about 12 words.

- **The worked example** stays each lesson's `reference`. That is one example, and "Watch again" already draws a fresh one.
- **The idea line** is `idea[0]`, one sentence. Where a lesson has a second idea sentence, drop it, since v2 only shows the first.
- **Captions** aren't shown in v2. Where a caption carried something worth keeping, it moves into a narration line below.
- Placeholders use the variable names already in each `explain()`. The examples are rendered for the reference problem.

### g5-mult2 (47 × 36)
- Idea (new): `Splitting one number into tens and ones turns one hard multiplication into two easy ones, added back together.` This replaces the two-sentence idea.
- split: `Split ${b} into tens and ones.` If there is one part: `${b} has only one part, so there's nothing to split.`
- partial-i: `The ${placeName(part)} strip is ${a} tall and ${part} wide.` For example, "The tens strip is 47 tall and 30 wide."
- sum: `Add the strips to fill the whole rectangle.`

### g5-divide (864 ÷ 12)
- Idea: keep it.
- tens: `Take out as many tens of ${dv} as fit.`
- subtract: `Take those away to see what's left.`
- ones: `Now count how many ${dv}s fit in what's left.`
- sum: `The tens and the ones together are the answer.`

### g5-order (3 + 4 × (6 − 2))
- Idea: keep it.
- first: for t0 and t1, `Find the parentheses: they go first.` For t2, `No parentheses, and × comes before −.`
- t0:
  - s0: `Work out the inside of the parentheses.`
  - s1: `Multiply next, before adding.`
  - s2: `Add last.` Then, when the caption's left-to-right value exists: ` Left to right would give ${leftToRight}, which is wrong.`
- t1:
  - s0: `Work out the inside of the parentheses.`
  - s1: `Multiply before subtracting.`
  - s2: `Subtract last.`
- t2:
  - s0: `Multiply first.`
  - s1: `Divide next, still before subtracting.`
  - s2: `Subtract last.` Add the same left-to-right sentence as t0.

### g5-pow10 (3.47 × 100)
- Idea (new, follows the example's power of 10; updated 2026-10-14): `` `Times ${m} makes each digit worth ${["ten", "a hundred", "a thousand"][k - 1]} times more, so the point hops ${WORDS[k]} ${k > 1 ? "places" : "place"} right.` `` Build it in explain() (index.ts:45) from the same `k` and `m` the steps use, with `WORDS` so it reads "two places", not "2 places". For the reference (3.47 × 100) it reads: `Times 100 makes each digit worth a hundred times more, so the point hops two places right.` For × 10: `Times 10 makes each digit worth ten times more, so the point hops one place right.` Today's line says the digits move left while every step says the point moves right, which confuses.
- zeros: `Each zero hops the point one place right.`
- move: `Hop the point ${plural(k, "place")} right.` Then, when there are fewer decimal digits than k: ` Write a 0 in each empty place.`

### g5-round (3.476 to the nearest hundredth)
- Idea (new): `Rounding picks the closer number, and the digit just to the right tells you which.`
- digit: `${f(value)} sits between ${f(T)} and ${f(up)}.`
- next: `Halfway between them is ${f(half)}.`
- round: `${next} is 5 or more, so round up.` or `${next} is 4 or less, so the digit stays.` Then, when it is exactly halfway: ` Halfway rounds up.` This replaces the caption.

### g5-adddec (12.5 + 3.75)
- Idea (new): `Line up the points so tenths add to tenths and hundredths to hundredths.`
- line-up: `Write ${rewrite} so both numbers have hundredths.` or `Both already have hundredths, so the points line up.`
- whole: `Add the whole numbers.`
- decimal: `Add the parts after the point.` Then, if the sum is 1 or more: ` That's more than 1 whole.`
- total: `Put the two answers together.`

### g5-multdec (2.4 × 0.3)
- Idea (new): `A tenth of a tenth is a hundredth, so the answer has as many decimal places as both numbers together.`
- whole: `Leave the points out and multiply.`
- places: `Count the digits after each point.`
- place: `Put the point ${placeWord(places)} from the right.`

### g5-divdec (4.8 ÷ 0.6)
- Idea: keep it.
- divisor: `Make the divisor a whole number.`
- other: `Do the same to ${f(x)}, so the answer doesn't change.`
- divide: `Now it's whole numbers: divide.`

### g5-improper (2 3/4)
- Idea (new): `Cut every whole into the same pieces, then count all the pieces.`
- wholes: `Each whole is ${pieces(d)}.` For example, "Each whole is 4 fourths."
- extra: `Add the ${n} extra ${n === 1 ? "piece" : "pieces"}.`
- fraction: `The pieces are still ${pieceName(d)}, so the bottom stays ${d}.`

### add, sub, mix (1/2 + 1/3), in `_tape-family/unlike.ts`
- Ideas: keep them.
- lcd: `Both ${b} and ${d} go into ${Lx}, so cut both bars into ${pieceName(Lx)}.` This drops "The pieces are different sizes.", which only the caption needed.
- first: `Each ${pieceName(b, false)} is ${count(L / b, …)} ${pieceName(L)}.` For example, "Each half is 3 sixths." Use `pieceName(L, L / b !== 1)` for the plural.
- second: the same with d. For example, "Each third is 2 sixths."
- add: `Same-size pieces now, so add the tops. The bottom stays ${L}.`
- subtract: `Same-size pieces now, so take away. The bottom stays ${L}.`
- simplify:
  - more than 1: `Every ${L} pieces make one whole.`
  - g > 1: `Divide the top and the bottom by ${g}.`
  - else: `It's already as simple as it gets.`

### g5-fracof (3/4 of 20)
- Idea: keep it.
- groups: `The bottom says ${d} equal groups.`
- take: `The top says take ${n} of them.`

### g5-multfrac (2/3 × 3/4)
- Idea: keep it.
- rows: `Cut the square into ${b} rows and shade ${a}.`
- cols: `Cut it into ${d} columns and shade ${c}.`
  - **Math fix on this line:** it reads `3/4 × 2/3`, which is reversed from the problem. Make it `${c}/${d} of ${a}/${b}`: `[frac(c, d), text(" of "), frac(a, b)]`.
- across: `The squares shaded twice are the answer.`
- simplify: `Divide the top and the bottom by ${gcd(N, D)}.` or `It can't be made simpler.`

### g5-unitdiv (3 ÷ 1/4)
- Idea (new): `Dividing by a unit fraction asks how many of those pieces fit.`
- one: `Cut one whole into ${pieceName(d)}.`
- all: `Every whole holds ${one}, so count them all.`

### g5-volume (4 × 3 × 2)
- Idea: keep it.
- base: `The bottom layer is ${l} by ${w}.`
- volume: `Stack ${h} layers to fill the box, in cubic cm.`

### g5-units (3 feet)
- Idea (new): `A big unit holds many small ones, so the same amount takes more small units.` Today's line says "the same length", which is wrong for kilograms, hours and gallons.
- one: `Start with just one ${one}.`
- more: keep it. It already explains without the equation.
- multiply:
  - down: `Every ${one} is another ${f} ${small}, so multiply.`
  - up: `Every ${f} ${small} make one ${one}, so divide.`

## 4. Engine wording (all grades)

`web/src/engine/session/practice.ts:379` says "Read the step again, or tap the light bulb for a hint." Change it to `Read the step again, or tap Hint.` No lesson in any grade mentions the bulb itself.

**Rounding answers use ≈ (added 2026-10-13).** Since next e479aa4, the solved problem line reads "3.476 = 3.48". A rounded number isn't equal to the number it came from, so this line must read `3.476 ≈ 3.48`. The same thing happens in two other lessons:
- g4-placevalue would show "8,265 = 8,300". It should be `8,265 ≈ 8,300`.
- g3-round would show "Round 347 to the nearest ten = 350". It should be `347 ≈ 350`.

The rule: when the last step's prompt uses ≈, which is true in exactly these three lessons, the solved line joins the problem and the answer with ≈, not =. That covers `plainProblem` and the stage's solved line (`fillUnknown`), and `hideUnknown` should treat a trailing "≈ ?" like "= ?". For g3-round, the display should match the other two: `[num(n), op("≈"), text("?")]` with the note `Round to the nearest ${place(to, false)}.` Then all three read the same way before and after solving. The answers don't change.

## Checks for Development
- No test pins the idea text. A grep of the ideas on `next` finds only the lesson files. If a snapshot pins narration, regenerate it. Answers and steps are unchanged, apart from the g5-multfrac math-line order.
- After the change, check that no Watch one narration line contains its own math line, for these 17 lessons. It is a cheap test: the narration should not include the math line's text.
