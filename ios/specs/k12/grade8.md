# v2 lesson pass: 8th grade

Curriculum, 2026-10-13. For Development. It covers the 14 lessons in `web/src/curriculum/lessons/grade8/`, read on `origin/next` 453ec4b, together with the v2 learn and practice screens on Design's branch (5d17ed2).
It is content only: lesson text, the depends-on lists and the check recipes. Nothing here changes layout.

## How to read this

**Depends on** lists the lessons a child needs before this one. The lists can cross grades. The first id is the main build-up, so put it in today's single `pre`. The whole list is for Today's step-back.

**Skill check** is the recipe for the lesson's own check. Each item reads `i<N>`, meaning call the lesson's own `generate(rng, N)`. An item can add a `where` condition: redraw, up to 50 tries, until it holds.
- No 8th grade lesson has a story, so no item is a `story`.
- The default is 4 items, with no hints and one try per step, as in the plan.
- Shuffle the items.
- Every 8th grade lesson is wrapped in `withEasyStart`, and none of the generators reads `index` itself. So `i3` is a plain draw from the full range, and the `where` conditions pick the cases.
- The `where` names are the fields of each lesson's problem type (for example `t`, `a`, `b` in `ExponentRule`).

**Gating.** The same point as 5th grade: if "Next" needs every lesson in the list to be learned, a child who opens 8th grade first is sent back to 6th or 7th grade. I suggest a lesson from an *earlier grade* counts as learned until one of its checks comes back 0-2.

## 1. Depends on and skill checks

| Lesson | Depends on | Skill check (4 items) |
|---|---|---|
| g8-exp Exponent rules | g6-expo | i3 where t = 0 and a·b ≠ a + b; i3 where t = 1; i3 where t = 2 and a·b ≠ a + b; i3 where a·b ≠ a + b |
| g8-sci Scientific notation | g5-pow10, g6-expo | i3 where e ≤ 4; i3 where e ≥ 6; i3 where c is a multiple of 10 (the front number is whole, like 3 × 10⁵); i3 |
| g8-roots Square and cube roots | g6-expo | i3 where not cube and 3 ≤ n ≤ 9; i3 where not cube and n ≥ 10; i3 where cube; i3 where cube and n ≥ 4 |
| g8-func Evaluate a function | g6-eval, g7-mulint | i3 where x > 0 and b < 0; i3 where x < 0; i3 where a < 0 and x < 0; i3 where x ≠ 0 |
| g8-slope Slope from two points | g7-subint, g7-mulint | i3 where m > 0 and x2 − x1 ≥ 2; i3 where m < 0; i3 where x1 < 0 or y1 < 0; i3 where x2 − x1 ≥ 2 |
| g8-intercept Slope-intercept form | g8-slope, g8-func | i3 where m > 0 and x0 > 0; i3 where m·x0 < 0; i3 where m < 0 and x0 < 0; i3 where b < 0. All four also need b ≠ m. |
| g8-both Variables on both sides | g7-eq | i3 where a − c ≥ 2; i3 where a − c = 1; i3 where c ≥ 2 and a − c ≥ 2; i3 where x ≥ 6 |
| g8-system Systems by substitution | g7-distribute, g6-onestep | i3 where k ≤ 3; i3 where k ≥ 4; i3 where x ≥ 6; i3. Keep the "Substitute" step: it is the idea. |
| g8-pyth Pythagorean theorem | g8-roots | i3 where c ≤ 10; i3 where c ≥ 13, twice; i3 |
| g8-leg Find a missing leg | g8-pyth | i3 where c ≤ 10; i3 where c ≥ 13, twice; i3 |
| g8-cyl Volume of a cylinder | g7-circarea, g5-volume | i3 where r ≥ 3, twice; i3 where h ≥ 6 and r ≥ 2; i3 where r ≥ 2 |
| g8-cone Volume of a cone | g8-cyl | i3 where r ≥ 2, twice; i3 where r ≥ 3; i3 |
| g8-translate Translations | g7-addint, g7-subint | i3 where dx > 0 and dy < 0; i3 where dx < 0 and dy > 0; i3 where dx < 0 and dy < 0; i3 where x·x2 < 0 or y·y2 < 0 (it crosses an axis) |
| g8-tri Angles in a triangle | g7-angles | i3 where a + b < 90 (the third angle is wide); i3 where a + b ≥ 120; i3; i3 |

Why some conditions are there:
- **g8-exp:** with a = b = 2, adding and multiplying the exponents both give 4, so the check can't tell the slip from the rule.
- **g8-roots, g8-cyl:** n = 2 (or r = 2) makes several slips land on the right answer (2 × 2 = 2 + 2; 2 × 3.14 × 2 = 3.14 × 2²). r = 1 makes squaring the radius trivial.
- **g8-slope:** with a run of 1 the slope equals the rise, so the last step tests nothing.
- **g8-intercept:** when b = m, swapping them can't be seen.

Changes from today's `pre`:
- **g8-exp** gets g6-expo (was none). The rules count x's, so a child needs to know what an exponent means.
- **g8-sci** gets g5-pow10 (was none). The lesson is moving the point by powers of 10.
- **g8-roots** gets g6-expo (was none). A root undoes a square or cube.
- **g8-func** gets g6-eval (was none). It is putting a number in for x, now with negatives.
- **g8-slope** gets g7-subint (was none). The rise and run are subtractions with negative numbers.
- **g8-intercept** gets g8-slope (was none). It uses slope and works out m·x.
- **g8-system** moves from g8-intercept to g7-distribute. The steps never use a slope or b: they put kx in for y, combine x + kx, and divide.
- **g8-cyl** gets g7-circarea (was none). Its base step is the area of a circle with 3.14.
- **g8-cone** gets g8-cyl (was none). It is a cylinder's volume, then a third.
- **g8-translate** gets g7-addint (was none). The new x and y are signed sums.
- **g8-tri** gets g7-angles (was none). Supplementary angles already use the straight line of 180°.
- g8-both, g8-pyth and g8-leg keep their `pre` as the first id.
- Four lessons also set `pre` in their own `index.ts` (g8-both:82, g8-system:12, g8-pyth:92, g8-leg:76). Change g8-system there too, so the module still matches its catalog entry.

## 2. Show the problem once

On the v2 stage the problem shows once (display, or lead). One lesson says it twice.

- **g8-pyth** (`grade8/g8-pyth/index.ts:97`): the display "a = 3, b = 4, c = ?" and the note "Right triangle with legs 3 and 4. Find the long side, c." repeat the numbers. Change the note so it explains the letters and doesn't repeat the numbers, matching g8-leg:
  `Right triangle: a and b are the legs, c is the long side.\na² + b² = c²`

The other 13 are fine.
- The notes in g8-exp, g8-sci, g8-func, g8-slope, g8-intercept, g8-translate and g8-tri add the instruction ("Find the slope.", "Move it 4 right and 5 down."), not a second copy.
- g8-leg, g8-cyl and g8-cone give the formula in the note. That is new information, not a repeat.
- g8-both, g8-system and g8-roots have no note.

## 3. Watch one: idea line and narration

In v2, Watch one prints each step's math line with its narration underneath, and speaks both. The rule for every line below: **the narration says what the step does or why, in words, and leaves the equation to the math line.** Lines stay under about 12 words.

- **The worked example** stays each lesson's `reference`.
- **The idea line** is `idea[0]`, one sentence. Every 8th grade lesson has one sentence today.
- **Captions** aren't shown in v2. Where a caption carried something worth keeping, it moves into a narration line below.
- Placeholders use the variable names already in each `explain()`. The examples are rendered for the reference problem.

### g8-exp (x² · x³)
- Idea: keep it.
- problem: keep it. ("Two powers of x multiplied." does not repeat the math.)
- written: keep it.
- exponent: drop the end ` So it is x${supText(e)}.` and give the rule in words instead:
  - t0: `Count the x's: ${f(a)} + ${f(b)}. Multiplying adds the exponents.` For example, "Count the x's: 2 + 3. Multiplying adds the exponents."
  - t1: `${f(b)} x's cancel, leaving ${f(a + b)} − ${f(b)}. Dividing subtracts the exponents.`
  - t2: `${countOf(f(b), "group")} of ${f(a)} x's. A power of a power multiplies the exponents.`
  - The `caption` (the `count` lines) is no longer needed by Watch one. Keep it only if the diagram uses it.
- try: `Check with x = 2: multiply ${countOf(f(e), "two")} together.` For example, "Check with x = 2: multiply 5 twos together."

### g8-sci (45,000)
- Idea: keep it.
- start: `A whole number's point sits at its end, after the last digit.` Today's line reads "45,000 is 45000", which sounds the same twice when spoken (`index.ts:51`).
- places: `Move the point left until it sits just after the ${digits[0]}.` For example, "…just after the 4."
- write: `The front number is between 1 and 10. Each place moved is one × 10.`

### g8-roots (√81)
- Idea: keep it.
- root: keep it. ("81 squares make a square with 9 along each side." explains, it doesn't repeat.)
- check: square: `Check it: the side times itself gives back ${v}.` Cube: `Check it: the edge times itself times itself gives back ${v}.`

### g8-func (f(x) = 3x − 5, find f(4))
- Idea: keep it.
- rule: `Find the rule's value when x is ${f(x)}.`
- ax: `Put ${f(x)} in for x and multiply.`
- value: `Then add the number on its own. So ${pt(x, v)} is on the graph.` For example, "…So (4, 7) is on the graph."

### g8-slope ((1, 2) and (3, 8))
- Idea: keep it.
- plot: `Plot both points, then go from the first to the second.`
- rise: `y goes ${up ? "up" : "down"} from the first point to the second: that's the rise.`
- run: `In the same order, x goes across: that's the run.`
- slope: `Rise over run: the line goes ${up ? "up" : "down"} ${f(Math.abs(m))} for every 1 across.` For example, "…goes up 3 for every 1 across."

### g8-intercept (slope 2, through (3, 7))
- Idea: keep it.
- point: `Find where this line crosses the y-axis. That is b.`
- mx: `From the y-axis to x = ${f(x0)}, the line changes by slope times x.`
- b: `Take that change back off ${f(y0)} to land on the y-axis.` This also fixes a wording error (section 4).
- line: `The slope goes in front of x, and b goes on its own.`

### g8-both (5x + 3 = 2x + 18)
- Idea: keep it.
- equation: keep it.
- gather: `Take ${cxText(c)} off both sides, so the x's are on one side.` For example, "Take 2x off both sides…"
- move: `Take ${f(b)} off both sides to leave the x's alone.`
- divide, k > 1: `Split both sides into ${f(k)} equal groups.` k = 1: `Only one x is left, so that's the answer.`

### g8-system (y = 2x, x + y = 15)
- Idea: keep it.
- lines: keep it.
- sub: `y is ${k}x, so put ${k}x in place of y, then count the x's.`
- x: `Divide by ${c} to find x: how far across the lines cross.`
- y: `Put x back into y = ${k}x. The lines cross at ${pt(x, y)}.` For example, "…cross at (5, 10)." This keeps the caption's point.

### g8-pyth (legs 3 and 4)
- Idea: keep it.
- triangle: `a and b are the legs. The long side c is across from the square corner.`
- square-a: `Build a square on the side of ${a}.`
- square-b: `Build one on the side of ${b} too.`
- add: `Together the two small squares fill the square on c.` This is the caption's point.
- root: `The big square's side is the number that times itself makes ${C2}.`

### g8-leg (leg 6, long side 10)
- Idea: keep it.
- triangle: `c is the long side. The other leg, b, is missing.`
- square-c: `Build a square on the long side.`
- square-a: `Build one on the leg of ${a} too.`
- subtract: `The leg squares fill the big one, so subtract.`
- root: `Find the number that times itself makes ${B2}.`

### g8-cyl (radius 2, height 5)
- Idea: keep it.
- solid: `r is the radius of the circle base, and h is the height.`
- square: `Square the radius: multiply it by itself.`
- base: `The base is a circle, so multiply by 3.14 for its area.`
- height: `Stack ${h} layers of that base to fill the cylinder.`

### g8-cone (radius 3, height 4)
- Idea: keep it.
- solid: `The cone sits inside the cylinder that just fits around it.`
- base: `The base is a circle, so multiply by 3.14 for its area.`
- cylinder: `Stack the base ${h} high to fill the cylinder.`
- third: `The cone holds a third of that cylinder.`

### g8-translate ((2, 3), 4 right and 5 down)
- Idea (new): `A translation slides a point: across changes x, and up or down changes y.` Today's line says "without turning it", but a point can't turn, and the steps are about x and y.
- start: `Start at the point. x is across, y is up.`
- x: `${dx > 0 ? "Right adds to x" : "Left subtracts from x"}: slide ${across}.` For example, "Right adds to x: slide 4 right."
- y: `${dy > 0 ? "Up adds to y" : "Down subtracts from y"}: slide ${upDown}. It lands on ${pt(nx, ny)}.` For example, "Down subtracts from y: slide 5 down. It lands on (6, −2)."

### g8-tri (50° and 60°)
- Idea (new): `The three angles of any triangle add up to 180°, a straight line.` Today's line says the corners "line up" but never says 180°, which every step uses.
- triangle: `Two corners are known. The third corner is missing.`
- add: `Put the two known angles together.`
- third: `All three make 180°, so the third is what's left.`

## 4. Maths and wording errors

- **g8-intercept, `explanation.ts:35`:** the narration says the line crosses the y-axis "`${f(mx)}` away from `${f(y0)}`". When m·x0 is negative it reads "−6 away", which isn't a distance. The new b line above replaces it.
- **g8-system, `explanation.ts:36`:** "That is where the lines cross, left to right." is unclear. The new x line says "how far across the lines cross".
- **g8-system, `explanation.ts:35`:** the math line `x + 2x = 3x = 15` chains an identity into the equation. Write it like the next step: `x + 2x = 15, so 3x = 15`, that is `[text("x"), op("+"), num(k), text("x"), op("="), num(s), text(", so "), num(c), text("x"), op("="), num(s)]`.
- **g8-roots, `index.ts:33-34` and `:36`:** "times itself three times" is n⁴ when read literally (n × n × n × n). For the cube root:
  - question (33): `What number times itself times itself makes ${v}?`
  - hint (34): `Try a number times itself times itself, and get closer: is it more or less than ${v}?`
  - check hint (36): for a cube, `Multiply three ${n}s together: you should get back the number under the root.`
- **g8-pyth, `index.ts:97`:** the note repeats the display (section 2).

No answer is wrong in any of the 14 lessons. Several predictable slips coincide with the right answer for small numbers (for example g8-exp 2² = 2 × 2, g8-cyl r = 2). The right answer is checked first, so practice is fine; the check recipes above avoid those cases.

## Checks for Development
- No test pins the idea text. If a snapshot pins narration, regenerate it. Answers and steps are unchanged, apart from the g8-system "sub" math line and the g8-roots question and hints.
- After the change, check that no Watch one narration line contains its own math line, for these 14 lessons (Learn.tsx `saysMath` does this test already).
- Change g8-system's `pre` in both `catalog.ts` and its `index.ts`.
