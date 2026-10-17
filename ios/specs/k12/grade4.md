# v2 lesson pass: 4th grade

Curriculum, 2026-10-13. For Development. It covers the 19 lessons in `web/src/curriculum/lessons/grade4/`, read on `origin/next` 3ccaa07, together with the v2 learn and practice screens on Design's branch (e2e3154).
It is content only: lesson text, the depends-on lists and the check recipes. Nothing here changes layout.

## How to read this

The format is the same as `grade5.md`.

**Depends on** lists the lessons a child needs before this one. The lists can cross grades. The first id is the main build-up, so put it in today's single `pre`. The whole list is for Today's step-back.

**Skill check** is the recipe for the lesson's own check. Each item reads `i<N>`, meaning call the lesson's own `generate(rng, N)`. An item can add a `where` condition: redraw, up to 50 tries, until it holds.
- `story` means show that item as the lesson's story.
- The default is 4 items, with no hints and one try per step. g4-lines uses 5, because it has three kinds of problem.
- Shuffle the items, but put a `story` item last.
- Every `where` below holds often enough that 50 tries is plenty (the rarest is about 1 draw in 10).

The gating note in `grade5.md` applies here too: a lesson from an earlier grade counts as learned until one of its checks comes back 0-2.

## 1. Depends on and skill checks

| Lesson | Depends on | Skill check |
|---|---|---|
| g4-placevalue Place value and rounding | g3-round | i3 where it rounds down; i3 where it rounds up; i6 where the next digit is 5; i6 |
| g4-addsub Add and subtract big numbers | g3-addsub | i0 where sub = 1; i4 where sub = 0; i4 where sub = 1; i4 story |
| g4-partial Multiply big numbers | g3-split, g3-mult10 | i3; i3 where the tens digit of n is 0; i3 where m ≥ 6; i3 story |
| g4-mult2x2 Two-digit times two-digit | g4-partial, g3-mult10 | i0; i3; i3 where u ≥ 5 and v ≥ 5 (both ones digits); i3 story |
| g4-divide Dividing with remainders | g3-divfacts, g3-mult10 | i0 where r = 0; i0 where r > 0 and q ≥ 20; i0 where r > 0; i0 story. The generator ignores the index, so the `where`s do the work. |
| g4-factors Factors and multiples | g3-facts, g3-divfacts | i0 where n % t = 0 (it is a multiple); i3 where n % t ≠ 0; i0 where n = 16 (4 pairs with itself); i3 where n > 32 |
| g4-equiv Equivalent fractions | g3-fraccompare, g3-facts | i0 where a = 1; i0 where a > 1; i0 where k ≥ 4; i0 where a > 1 and b ≥ 5 |
| g4-fraccompare Comparing fractions | g4-equiv, g3-fraccompare | i0; i0 where the two are equal (A = C); i4 where L is neither bottom; i4 where L is neither bottom and the tops alone point to the wrong sign (compareIndex(a, c) ≠ k). Keep the tap step, which is the idea. |
| g4-likefrac Adding like fractions | g3-unitfrac, g3-fracline | i0; i3 where a + c > d; i3 where a + c < d; i3 story |
| g4-mixed Adding mixed numbers | g4-likefrac | i0 where n1 + n2 < d (no trade); i3 where n1 + n2 > d; i3 where n1 + n2 > d and d ≥ 6; i3 story |
| g4-fracwhole Fraction times a whole number | g4-likefrac, g3-facts | i0 where W × n < d; i0 where W × n > d and d doesn't go into W × n; i0 where d goes into W × n (a whole answer); i0 story |
| g4-dec Tenths and hundredths | g4-equiv, g4-likefrac | i0 where 10a + b < 100; i0 where 10a + b ≥ 100; i0 where b < 10; i0 |
| g4-deccompare Comparing decimals | g4-dec | i0 where pa ≠ pb and comparing the digits as whole numbers gives the wrong sign (the 0.5 and 0.45 trap); i0 where a and b have the same tenths digit; i4 where they are equal (a = b); i4 where w > 0 and pa ≠ pb. Keep the tap step. |
| g4-convert Converting measurements | g3-split, g3-mult10 | i0 where m = 0; i3 where m > 0 and k is 0 or 3 (feet, pounds); i3 where m > 0 and k is 1 or 2 (meters, hours); i3 story |
| g4-lineplot Line plots with fractions | g3-lineplot, g4-likefrac, g4-fracwhole | i3 (difference), i4 (total of one stack), i5 (how many longer), i6 where d = 8. The generator picks the question from index % 3, like g5-order. |
| g4-area Area and perimeter | g3-area, g3-perim | i0 where l ≤ 10; i0 where l ≥ 11; i0; i0. Every item asks for both, which is the idea. |
| g4-lines Points, lines, rays and angles | g3-quads | i3 (line, ray or segment); i4 where deg < 90; i7 where 90 < deg < 180; i5 where item = 1 (perpendicular); i8 where item = 2 (intersecting). index % 3 picks the kind. Keep every tap step. |
| g4-angles Angles add up | g4-lines, g3-addsub | i0 (right angle, tens); i3 where st is false; i3 where st is true; i3 where st is true and a is not a multiple of 10 |
| g4-symmetry Lines of symmetry | g3-quads, g2-shares | i4 where the dashed line is a line of symmetry; i6 where it is not; i3 (count the lines); i5 where the shape is the rectangle or the parallelogram (shape 1 or 6) |

Changes from today's `pre`:
- **g4-equiv** gets g3-fraccompare (today none). Third grade already shows "the same amount cut into smaller pieces" there.
- **g4-likefrac** moves from g4-equiv to g3-unitfrac. The answer never needs renaming, so it is counting pieces of one size.
- **g4-convert** gets g3-split (today none). The hard part is n × 12 or n × 16; × 60 and × 100 come from g3-mult10.
- **g4-area** gets g3-area (today none). Both halves of it are taught in 3rd grade.
- **g4-symmetry** moves from g4-lines to g3-quads. It folds shapes into halves and never uses rays or angles.
- The other 14 keep their `pre` as the first id in the list.

## 2. Show the problem once

On the v2 stage the problem shows once (display, or lead, or story). One lesson says it twice, and gives away a step too.

- **g4-angles:** the display "35° + ? = 90°" and the note "Two angles make a right angle." both say what the whole angle is. The "= 90°" also gives away the first step, which asks "How many degrees is a right angle?". Remove `displayNote` and add a `lead`:
  `Two angles make ${p.st ? "a straight line" : "a right angle"}. One is **${p.a}°**. How big is the other one?`
  Watch one keeps its statement "35° + ? = 90°", since it is a worked example.

The other 18 are fine.
- The notes in g4-placevalue, g4-divide, g4-dec, g4-area, g4-fraccompare and g4-deccompare add the instruction, not a second copy of the problem.
- g4-factors is close: "factors of 20" and "Find the factor pairs." overlap a little, but the note also asks the multiple question, so I left it.
- g4-lineplot, g4-lines and g4-symmetry show one question in words plus the picture. The picture is the problem, so that's not a repeat.
- Stories replace the math line, so they don't repeat it.

## 3. Watch one: idea line and narration

The rule from `grade5.md` holds: **the narration says what the step does or why, in words, and leaves the equation to the math line.** Lines stay under about 12 words. The worked example stays each lesson's `reference`. Captions aren't shown in v2; where one carried something worth keeping, it moves into a narration line. Placeholders use the variable names in each `explain()`. Examples are rendered for the reference problem.

Steps at `state: 0` (the "start", "look", "drop" and "split" lines) are listed only where their narration repeats the math line. See also the screen note under "Checks for Development".

### g4-placevalue (47,382 to the nearest thousand)
- Idea: keep it.
- start: `One digit in each place. We'll round to the nearest ${ONE[place]}.` Today's line starts "Here is 47,382", which is its math line.
- digit: `Count places from the right until you reach the ${name}.` For example, "Count places from the right until you reach the thousands place."
- between: `These are the round ${ONE[place]}s on either side.`
- next: `That's 5 or more, so it's at or past halfway, ${commas(mid)}.` or `That's less than 5, so it's before halfway, ${commas(mid)}.` For example, "That's less than 5, so it's before halfway, 47,500." This carries the caption's halfway number.
- round: `It's closer to the lower one, so it rounds down.` or `It's closer to the higher one, so it rounds up.` When `n === mid`: `It's exactly halfway, and halfway rounds up.`

### g4-addsub (4,637 + 2,785)
- Idea: keep it.
- start: `Line them up by place, and start with the ones.` This keeps "Ones first" from the caption.
- each column, in `say(i)`:
  - adding: `Add the ${name}${c.carryIn ? " and the carried 1" : ""}.` then ` Write ${v % 10} and carry 1 to the ${PLURAL[i + 1]}.` when v ≥ 10, else ` No carry this time.` For example, "Add the tens and the carried 1. Write 2 and carry 1 to the hundreds."
  - subtracting, with a trade: `${c.top} is less than ${c.bottom}, so trade 1 ${ONE[i + 1]} for 10 ${name}.`
  - subtracting, no trade: `Subtract the ${name}. No trade needed.`
- answer: `The thousands are ${thSay}. Read all the digits together.` For example, "The thousands are 4 + 2 + 1 = 7. Read all the digits together." The thousands sum is not in the math line, so it stays.

### g4-partial (346 × 7)
- Idea: keep it.
- hundreds: `${count(H, "hundred")} times ${m} is ${count(H * m, "hundred")}.` For example, "3 hundreds times 7 is 21 hundreds."
- tens: `${count(T, "ten")} times ${m} is ${count(T * m, "ten")}.` For example, "4 tens times 7 is 28 tens."
- ones: `Last, the ones strip.`
- A place worth 0 keeps today's line, "There are no tens, so that part is 0."
- sum: `Add the strips to fill the whole rectangle.`

### g4-mult2x2 (34 × 26)
- Idea: keep it.
- The four part steps use `model.steps[i].explain` today, which repeats the math line. Give them their own lines in `explain()`:
  - tt: `${t} × ${s} = ${t * s}, and tens times tens makes hundreds.` For example, "3 × 2 = 6, and tens times tens makes hundreds."
  - to: `${cap(tens(t))} times ${v} is ${tens(t * v)}.` For example, "3 tens times 6 is 18 tens."
  - ot: `${u} times ${tens(s)} is ${tens(u * s)}.` For example, "4 times 2 tens is 8 tens."
  - oo: `Last, the ones times the ones.`
- sum: `Add the four pieces to fill the whole rectangle.`
- split: keep it.

### g4-divide (75 ÷ 4)
- Idea: keep it.
- tens: `That fits in ${n}, but ${dv} × ${T + 10} = ${dv * (T + 10)} would not.` For example, "That fits in 75, but 4 × 20 = 80 would not."
- subtract: `Take away what's shared to see what's left.`
- ones: `Now fit as many ${dv}s as you can into ${left}.` For example, "Now fit as many 4s as you can into 35."
- answer: `Add the tens and the ones.`
- remainder: `${r} is less than ${dv}, so it's the remainder: ${q} R ${r}.` When r = 0: `Nothing is left, so ${dv} goes into ${n} exactly ${q} times.`

### g4-factors (factors of 20, and 3)
- Idea: keep it.
- start: `Every number makes one long row, so 1 and ${n} are factors.`
- pair1, pair2, multiple: keep them. They say the rows in words.
- count: `List both numbers of every pair. That's ${count(total, "factor")}.` For example, "List both numbers of every pair. That's 6 factors."

### g4-equiv (1/2 = ?/8)
- Idea (new): `Cut each piece into equal smaller pieces: more pieces, same amount.` Today's line says "cutting every piece in two", but k runs from 2 to 5 and the reference cuts into 4. It is also 20 words.
- times: `Every piece is cut into ${K}, so there are ${K} times as many.`
- top: `Do the same to the top. The shaded part has not changed.`

### g4-fraccompare (2/3 ? 3/4)
- Idea: keep it.
- start, common: keep them.
- first: `Each ${pieceName(b, false)} is ${L / b} ${pieceName(L)}.` For example, "Each third is 4 twelfths."
- second: the same with d. For example, "Each fourth is 3 twelfths."
- compare: `${each(A, L)} is ${k === 0 ? "less" : "more"} than ${each(C, L)}.` For example, "8 twelfths is less than 9 twelfths." When k = 1: `Both are ${each(A, L)}: the same amount.`

### g4-likefrac (2/8 + 3/8)
- Idea: keep it.
- tops: `Count the shaded pieces in both bars.`
- bottom: `The pieces are still ${pieceName(d)}, so the bottom stays ${d}.` Then, when S > d: ` More than 1 whole is fine.` For example, "The pieces are still eighths, so the bottom stays 8."

### g4-mixed (2 3/5 + 1 4/5)
- Idea: keep it.
- wholes: `Put the wholes together.`
- pieces: `Now put the ${piece} together.` Then, with a trade: ` That's more than one bar's worth.`
- trade: `${d} ${piece} fill a bar, so trade them for 1 whole.` For example, "5 fifths fill a bar, so trade them for 1 whole."
- answer: with a trade, `Add the new whole to the ${wholes(W)}.` (for example, "Add the new whole to the 3 wholes."); without one, `Put the wholes and the pieces back together.`

### g4-fracwhole (3 × 2/5)
- Idea: keep it.
- top: `${countOf(W, "group")} of ${count(n, d)}. The pieces stay the same size.` For example, "3 groups of 2 fifths. The pieces stay the same size."
- simplify:
  - S ≥ d: `Every ${countOf(d, "piece")} make one whole.` When `unsimplified` is set, add ` Then simplify the ${rem}/${d}.` For example, "Every 5 pieces make one whole."
  - g > 1: `Divide the top and the bottom by ${g}.`
  - else: `No number but 1 divides both ${S} and ${d}, so it's as simple as it gets.`

### g4-dec (3/10 + 25/100)
- Idea: keep it.
- hundredths: `Cut every tenth into 10 hundredths.`
- add: `Same-size pieces now, so add the tops.`
- decimal: `Hundredths go two places after the point.` Then, when S ≥ 100: ` 100 hundredths make 1 whole.`

### g4-deccompare (0.5 ? 0.45)
- Idea: keep it.
- first and second, in `say()`: drop the tail that repeats the math line (`, which is ${hund(h)}` and `: ${hund(h)}`), and end the tenths case with ` of the grid`:
  - one place: `${partIs(w, X)} ${tenths(h / 10)}: ${cols(h / 10)} of the grid.` For example, "0.5 is 5 tenths: 5 full columns of the grid."
  - h < 10: `${partIs(w, X)} just ${sq(h)} of the grid.`
  - else: `${partIs(w, X)} ${cols(Math.floor(h / 10))}${h % 10 ? ` and ${sq(h % 10)} more` : ""}.` For example, "0.45 is 4 full columns and 5 squares more."
- compare: `${hund(A)} ${signName[k]} ${hund(B)}.` For example, "50 hundredths is greater than 45 hundredths." When k = 1: `The same number of hundredths, so they are equal.` Today's line ends "so 0.5 > 0.45", which is its math line.

### g4-convert (3 feet 5 inches)
- Idea: keep it.
- one: `Start with just one ${one}.`
- multiply: `Every ${one} adds ${f} more ${smalls}, so multiply.` For example, "Every foot adds 12 more inches, so multiply."
- extra: `Then hop on the ${m} extra ${name(u.small, m)}.` For example, "Then hop on the 5 extra inches."

### g4-lineplot (longest minus shortest ribbon, in fourths)
- Idea (new): `Each X is one thing, placed above its length.` Today's line is about taller stacks, which only one of the three questions uses.
- The steps use `s.explain` today, which ends on the answer in the math line ("The longest is 1 3/4 inches." under "1 3/4 in"). Give each step id its own line, with `th = THINGS[p.thing]` and `d = p.d`:
  - max: `The ${th.most} is the X farthest to the right.`
  - min: `The ${th.least} is the X farthest to the left.`
  - diff: `Subtract ${said(hi, d)} − ${said(lo, d)}, or count the jumps between.` For example, "Subtract 1 3/4 − 1/2, or count the jumps between."
  - count: `Count the X's above ${said(p.v, d)}.`
  - total: `Add ${said(p.v, d)} once for each ${th.one}.` (and see the math fix in section 4)
  - longer: `Count only the X's to the right of ${said(p.v, d)}.`
- drop: keep it.

### g4-area (5 m by 3 m)
- Idea: keep it.
- area: `${count(w, "row")} of ${count(l, "square")} fill the inside.` For example, "3 rows of 5 squares fill the inside."
- half: `Go along one long side and one short side.`
- perimeter: `All the way around is that twice.`

### g4-lines (an angle of 130°)
- Idea (new), by kind, since `explain()` has `p`:
  - kind 0: `A line goes on both ways, a ray goes one way, and a segment stops.`
  - kind 1: `An angle is named by how wide it opens, compared with a square corner.`
  - kind 2: `Two lines can never meet, meet at square corners, or cross another way.`
  Today's one line is only about kind 0, but the reference is an angle.
- look, by kind: kind 0 `Look at both ends: a dot or an arrowhead?`; kind 1 `Look at how wide it opens, not how long the arms are.`; kind 2 `Picture both lines running on past the arrowheads.`
- The steps use `s.explain` today, and the math line is the one word picked ("Obtuse" under "It's an obtuse angle."). Give each step id its own line. With `cmp = p.deg < 90 ? 0 : p.deg === 90 ? 1 : 2`:
  - ends: `A dot is an endpoint. An arrowhead means it keeps going.`
  - name (kind 0): `No endpoints is a line, 1 is a ray, 2 is a segment.`
  - compare: `Put a page corner at the point: the angle ${["fits inside it", "fits it exactly", "opens past it"][cmp]}.` For example, "Put a page corner at the point: the angle opens past it."
  - name (kind 1): `Smaller than a square corner is acute, exactly is right, bigger is obtuse.` When `p.deg === 180`: `Opened all the way into a straight line, it's a straight angle.`
  - meet: `Run them on: they get closer and cross.` or `They stay the same distance apart, so they never cross.`
  - square: `A page corner fits where they cross.` or `A page corner doesn't fit where they cross.`
  - name (kind 2): `Never meet: parallel. Square corners: perpendicular. Otherwise: intersecting.`
- The name lines say the rule, so they include the word that is picked. That is the point of the step, not a repeat. The cheap test below skips these.

### g4-angles (35° + ? = 90°)
- Idea: keep it.
- whole: `Together they make ${st ? "a straight line, two square corners" : "a right angle, a square corner"}.` Today's line ends "which is 90°", its math line.
- missing: `Take away the part you know to find what's left.`
- parts: keep it.

### g4-symmetry (a rectangle, folded on its diagonal)
- Idea: keep it.
- look: keep it.
- The step uses `s.explain` today. Give it its own line, with `ok = s.slots[0]!.expected === 0` and `n = sh.lines.length`:
  - fold, ok: `Every corner lands on a corner.`
  - fold, not ok, rectangle (shape 1): `Folded on a diagonal, the corners stick out.` This is the reference.
  - fold, not ok, other shapes: `Parts stick out past the other half.`
  - count, n > 0: `Try every fold: across, up and down, corner to corner.`
  - count, n = 0: `No fold makes the two halves match.`

## 4. Maths and wording errors

1. **g4-lineplot, `web/src/curriculum/lessons/grade4/g4-lineplot/index.ts:99`.** The "Total length" step has `lead: [num(n), op("×")]`, and the boxes then hold the total. So the prompt reads "4 × [ ] [ ]/[ ] in" and the worked line reads "4 × 5 in", which says 4 times 5 inches. Fix: put the length and an equals sign in the lead, so the line reads "4 × 1 1/4 = 5 in":
   `lead: [num(n), op("×"), ...(mixedOf(p.v, d)[0] ? [num(mixedOf(p.v, d)[0])] : []), frac(mixedOf(p.v, d)[1], mixedOf(p.v, d)[2]), op("=")]`
   (p.v is never a whole number of inches here, so the fraction part always exists). The narration ("4 × 1 1/4 = 5 inches") is already right.
2. **g4-fracwhole, `web/src/curriculum/lessons/grade4/g4-fracwhole/index.ts:32`.** The step label is always "Write as a mixed number", but W × n can be less than d (2 × 1/5 = 2/5) or a whole number (4 × 3/4 = 3). Fix: `simplifyStep(W * n, d, W * n > d && (W * n) % d ? "Write as a mixed number" : "Simplify")`.
3. **g4-lines, `web/src/curriculum/lessons/grade4/g4-lines/index.ts:91`.** The idea line only covers lines, rays and segments, but two kinds of problem are angles and pairs of lines, and the reference is an angle. Fix: the three ideas in section 3.
4. **g4-equiv, `web/src/curriculum/lessons/grade4/g4-equiv/index.ts:81`.** "Cutting every piece in two" doesn't match k = 3, 4 or 5, or the reference (×4). Fix: the new idea in section 3.
5. **g4-angles, `web/src/curriculum/lessons/grade4/g4-angles/index.ts:76-77`.** The display gives away the first step's answer. Fix: the lead in section 2.

No light-bulb wording in any 4th grade lesson. The engine line in `grade5.md` section 4 covers all grades.

## Checks for Development
- No test pins the idea text. If a snapshot pins narration, regenerate it. Answers and steps are unchanged, apart from the g4-lineplot total line, the g4-fracwhole label and the g4-angles lead.
- After the change, check that no Watch one narration line contains its own math line, for these 19 lessons. Skip the one-word tap lines in g4-lines and g4-symmetry ("Obtuse", "Yes", "No"): "no" also matches inside "not", and the name lines say the rule on purpose.
- **Screen note, not content.** Learn.tsx on e2e3154 shows `state <= at && state > 0`, so a step at state 0 only appears once the whole example has finished, and then at the top of the list. Most of these are intro lines, but in g4-divide (and every lesson built with `chainExplanation`) the first beat, "4 × 10 = 40", is a real worked step at state 0. It shows up last. Either show state-0 lines from the start, or have `chainExplanation` start at state 1.
