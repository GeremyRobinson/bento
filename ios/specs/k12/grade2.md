# v2 lesson pass: 2nd grade

Curriculum, 2026-10-13. For Development. It covers the 16 lessons in `web/src/curriculum/lessons/grade2/`, read on `origin/next` 3ccaa07, together with the v2 learn and practice screens on Design's branch (e2e3154).
It is content only: lesson text, the depends-on lists and the check recipes. Nothing here changes layout.

## How to read this

Read it the same way as the 5th grade spec (`grade5.md`, "How to read this"). In short:

**Depends on** lists the lessons a child needs before this one. The lists can cross grades. The first id is the main build-up, so put it in today's single `pre`. The whole list is for Today's step-back.

**Skill check** is the recipe for the lesson's own check. Each item reads `i<N>`, meaning call the lesson's own `generate(rng, N)`. An item can add a `where` condition: redraw, up to 50 tries, until it holds.
- `story` means show that item as the lesson's story. Only g2-regroup, g2-subregroup and g2-arrays have one.
- The default is 4 items, with no hints and one try per step, as in the plan.
- Shuffle the items, but put a `story` item last.
- Tap steps (Even or odd, Name the coin, Which is worth more, Name it, Same size?) are part of the idea, so the check keeps them.

The gating note in `grade5.md` applies here too: a lesson from an earlier grade counts as learned until one of its checks comes back 0-2.

## 1. Depends on and skill checks

| Lesson | Depends on | Skill check (4 items) |
|---|---|---|
| g2-hundreds Hundreds, tens and ones | g1-tensones | i0; i3 where the tens digit is 0; i3 where the ones digit is 0; i3 |
| g2-skip Skip counting | k-tens, g2-hundreds | i0 where by = 2; i3 where by = 5; i3 where by = 10 and start is not a multiple of 10; i3 where by = 100 |
| g2-evenodd Even and odd | k-count20 | i0 where n is even; i0 where n is odd; i3 where n is even and n ≥ 15; i3 where n is odd and n ≥ 15. Keep the "Even or odd" tap step. |
| g2-regroup Adding with regrouping | g1-addtens, g1-add20 | i0; i3 where the ones add to exactly 10 (no ones left); i3; i3 story |
| g2-subregroup Subtracting with regrouping | g2-regroup, g1-sub20 | i3 where a's ones digit is 0; i3 where the answer is under 10 (tens = 0); i3; i3 story |
| g2-within1000 Add and subtract within 1000 | g2-hundreds, g2-regroup, g2-subregroup | i0 (no crossing); i4 where sub = 0; i4 where sub = 1; i4. From i4 on, every problem crosses a ten or a hundred. |
| g2-coins Name the coin | none | i0 (nickel); i3 (dime); i5 where the coin worth more is the smaller one (a dime against a penny or a nickel); i5. i5 is a pair of coins, with the "Which is worth more?" step. |
| g2-money Counting money | g2-coins, g2-skip | i0; i3 where d = 0 (count on from quarters by 5s or 1s); i3 where three or more kinds of coin are used; i3 |
| g2-time5 Time to 5 minutes | g1-time, g2-skip | i0; i3 where m ≥ 35 (the short hand is close to the next number); i3 where m = 0 (1 in 12, fits in 50 tries); i3 |
| g2-measure Inches and centimeters | g1-measure, g1-sub20 | i0 (starts at 0); i3 where unit = 0; i3 where unit = 1; i3. From i3 on the object never starts at 0. |
| g2-estimate Estimate length | g2-measure | i0 (inches, starts at 0); i3 where unit = 1; i4 where unit = 0 and start > 0; i5. Keep the "Estimate" tap step. |
| g2-bargraph Bar graphs | g1-picgraph | i0; i3 where kind = 0 (how many more); i3 where kind = 1 (in all); i3 where kind = 0 |
| g2-lineplot Line plots | g2-bargraph, g2-measure | i4 (plot one more, then read the stack), i5 (tallest stack), i6 (longer than), i7 (longest − shortest). Each index gives one of the four kinds. Keep the "Plot one more" tap step. |
| g2-arrays Arrays | g2-skip | i0; i3 where rows ≠ cols; i3 where rows = 5 or cols = 5; i3 story |
| g2-solids Faces, edges and corners | k-solids | i0 (rectangular prism), i1 (triangular prism), i2 (cube), i3 (pyramid). The generator cycles the four solids, so this checks each one once. Keep the "Name it" step. |
| g2-shares Halves, thirds and fourths | g1-halves | i3 (has the "Same size?" step); i4 where parts = 3; i5 where shaded ≥ 2; i6 where shape = 2 (circle) |

Changes from today's `pre`:
- **g2-evenodd** goes from none to k-count20. The whole method is counting up to 20 dots in twos.
- **g2-within1000** moves from g2-regroup to g2-hundreds. The method is breaking the second number into hundreds, tens and ones. The easy problems don't regroup at all.
- **g2-bargraph** goes from none to g1-picgraph. Picture graphs already ask "how many more" and "in all".
- **g2-lineplot** moves from g2-measure to g2-bargraph. The lengths are already measured, so the lesson is about reading a graph.
- The rest keep their `pre` as the first id in the list. g2-coins stays "none": coin names and values start fresh.

## 2. Show the problem once

On the v2 stage the problem shows once (display, or lead, or story). One lesson says it twice.

- **g2-money:** the display lists the coins ("2 quarters, 1 dime, 1 nickel and 3 pennies"), and the picture right under it shows the same coins. Make the display the question and remove `displayNote`:
  `display: () => words("How much money is this?")` (`words` from `../../gradeK/kit`, as g2-coins uses it).
  The step prompts still name each coin ("2 quarters = ?¢"), so the names are still taught. g2-money has no legacy fixture, so no parity deviation is needed.

One tidy-up, with no change on screen:
- **g2-bargraph:** `display`, `displayNote` and `lead` all return the same question. Only `lead` shows on the v2 stage (ProblemView drops the note when there is a lead). Remove `displayNote` so no screen can show it twice.

The other 14 are fine.
- The dots (g2-evenodd) and blocks (g2-regroup, g2-subregroup) under the problem are what the child counts and trades. The steps point at them, so they are the working material, not a second copy.
- g2-hundreds' "Find the hundreds, tens and ones.", g2-skip's "Keep counting. What comes next?", g2-within1000's "Break 132 into hundreds, tens and ones.", g2-measure's "Measure in centimeters.", g2-estimate's "Estimate in inches, then measure." and g2-arrays' "Count the rows, then add them up." add the instruction, not a second copy of the problem.
- Stories replace the math line, so they don't repeat it.

## 3. Watch one: idea line and narration

The rule is the same as in 5th grade: **the narration says what the step does or why, in words, and leaves the equation to the math line.** For 2nd grade the lines are shorter and use very simple words, about 10 words or less.

- **The worked example** stays each lesson's `reference`.
- **The idea line** is `idea[0]`, one sentence a 2nd grader can read.
- **Captions** aren't shown in v2. Where a caption carried something worth keeping, it moves into a narration line below.
- Placeholders use the variable names already in each `explain()`. The examples are rendered for the reference problem.
- **Steps with `state: 0`.** On Design's branch, Learn shows a step's line only once its state has played (`web/src/screens/Learn.tsx:112`). A `state: 0` line stays hidden and then pops in at the top of the list when the example finishes, which pushes every line down. Five grade 2 lessons have one: g2-coins (`look`), g2-estimate (`look`), g2-lineplot (`drop`), g2-solids (`look`), g2-shares (`cut`). Remove each of them. Anything worth keeping moves into a narration below.
- **Lessons that copy `s.explain` into the narration** (g2-coins, g2-estimate, g2-lineplot, g2-solids, g2-shares) need their own narration by step id instead. Leave `s.explain` as it is: "Show me" still uses it.

### g2-hundreds (347)
- Idea (new): `Each digit tells how many hundreds, tens or ones there are.` Today's "blocks of its size" is hard to read at this grade.
- hundreds: `The first digit counts the flats. Each flat is 100.`
- tens: `The middle digit counts the rods. Each rod is 10.`
- ones: `The last digit counts the cubes. Each cube is 1.`
- expanded: `Add up what each part is worth.`

### g2-skip (15, 20, 25, ...)
- Idea: keep it.
- jump: `${v[1]} to ${v[2]} is the same jump.` For example, "20 to 25 is the same jump."
- next1: `Hop ${by} more.` For example, "Hop 5 more."
- next2: `Same jump again.`
- next3: `One more hop of ${by}.`

### g2-evenodd (13)
- Idea: keep it.
- pairs: `Put the dots in twos.`
- left: keep it. It says it in words, not as the math line.
- evenodd: `A dot with no partner makes it odd.` or `Every dot has a partner, so it's even.`

### g2-regroup (47 + 38)
- Idea: keep it.
- ones: `Add the ones first.`
- regroup: `Too many ones! Trade 10 of them for 1 ten.` This carries the caption.
- tens: `Add the tens, and the new ten too.`
- answer: keep it ("8 tens and 5 ones is 85."). It reads the answer in words.

### g2-subregroup (52 − 27)
- Idea (new): `When there aren't enough ones, trade a ten for ten ones.` Today's line is 16 words.
- trade: `${count(ao, "one")} can't give away ${bo}, so trade 1 ten for 10 ones.` For example, "2 ones can't give away 7, so trade 1 ten for 10 ones." This carries the caption.
- ones: `Now take away the ones.`
- tens: `Take away the tens. One ten was traded.`
- answer: keep it ("2 tens and 5 ones is 25.").

### g2-within1000 (245 + 132)
- Idea (new): `Break the second number into hundreds, tens and ones, then hop by each.`
- hundreds: `Break ${b} into ${H}, ${T} and ${B.o}. ${sub ? "Hop back" : "Hop on"} ${H} first.` For example, "Break 132 into 100, 30 and 2. Hop on 100 first." This carries the caption.
- tens: `${sub ? "Hop back" : "Hop on"} the tens.`
- ones: `${sub ? "Hop back" : "Hop on"} the ones.`
- answer: `The last hop lands on the answer.`

### g2-coins (a dime and a nickel)
- Idea (new): `Size, color and edge tell coins apart, but not what they're worth.` Today's line is 17 words.
- look (state 0): remove. The idea line now says it.
- name, left, right: the coin's look only, without its name: `${coinLook(c)[0]!.toUpperCase()}${coinLook(c).slice(1)}.` with c = `p.coin` for name and left, `p.other` for right. For example, "A tiny silver coin with a bumpy edge."
- value: `That's as much as ${v} pennies.` with `const v = COIN_INFO[p.coin]!.value`. For a penny: `It's the coin worth the least.`
- more: `Go by the cents, not by the size.`

### g2-money (2 quarters, 1 dime, 1 nickel and 3 pennies)
- Idea (new): `Start with the coins worth the most, then count on.`
- Each group: keep the counting, and drop "by 10s" when there is only one coin: `${g.before ? `From ${g.before}¢, count on` : "Count"} the ${nameOf(g.value, g.count)}${g.count > 1 ? ` by ${g.value}s` : ""}: ${g.seq.join(", ")}.` For example, "Count the quarters by 25s: 25, 50." then "From 50¢, count on the dime: 60."
- The first group's math line is wrong: see section 4.

### g2-time5 (3:25)
- Idea: keep it.
- hour: m ? `The short hand is past ${h}, but not yet at the next number.` : `The short hand points right at ${h}.`
- number: `Follow the long hand out to the edge.`
- minutes: m ? `Count by 5s up to it: ${Array.from({ length: K }, (_, i) => 5 * (i + 1)).join(", ")}.` : `On 12, a new hour has just begun.` For example, "Count by 5s up to it: 5, 10, 15, 20, 25."
- time: `Hour first, then minutes.`

### g2-measure (a pencil from 2 to 9 cm)
- Idea (new): `The length is how many units fit from one end to the other.` Today's line is long and hard to read.
- start: start ? `The ${name} doesn't start at 0 this time.` : `The ${name} starts right at the 0 edge.` Today's "The pencil starts at 2" repeats the math line "Starts at 2".
- end: `Look straight down from its tip.`
- length: start ? `Count the spaces between, not the marks.` : `It starts at 0, so the end is the length.` This carries the caption.

### g2-estimate (a pencil, 6 inches)
- Idea (new): `Use something you know the size of to make a smart guess.` Today's line names a paper clip and an inch, which doesn't fit the centimeter problems.
- look (state 0): remove. Its line moves into estimate.
- estimate: `One ${u.benchOne} is about 1 ${u.one}, and ${p.len} fit along it.` For example, "One paper clip is about 1 inch, and 6 fit along it."
- measure: p.start ? `It starts at ${p.start}, so count the spaces from there.` : `It starts at 0, so read the number at its end.`

### g2-bargraph (apples 7, bananas 4: how many more?)
- Idea: keep it.
- first: `Look across from the top of the ${X} bar.`
- second: `Look across from the top of the ${Y} bar.`
- combine: more ? `The part sticking up is how many more.` : `Put both bars together.` This carries the caption.

### g2-lineplot (pencils: add one 6 inches long, then how many are 6 inches?)
- Idea (new): `Each X stands for one thing, placed above how long it is.` Today's line ends on "the tallest stack came up most", which fits only one of the four kinds of question.
- drop (state 0): remove. The idea line now says it.
- plot: `Each X sits above its own length.`
- stack: `Count the X's in that stack, the new one too.`
- mode: `The tallest stack came up most.`
- longer: `Count the X's to the right of ${p.v}.`
- max: `The longest is the X farthest right.`
- min: `The shortest is the X farthest left.`
- diff: `Take the shortest away from the longest.`
- The statement's wording is off for this kind of problem: see section 4.

### g2-arrays (3 rows of 4)
- Idea (new): `Every row has the same number, so add it once for each row.`
- rows: `Rows go across. Count them from top to bottom.`
- cols: `Count across one row. Every row is the same.`
- total: keep it ("Add 4 for every row: 4, 8, 12."). The skip count is the method.

### g2-solids (a rectangular prism)
- Idea: keep it.
- look (state 0): remove. Its line moves into faces.
- faces: `Dashed lines show the back. Count those faces too.`
- edges: `Count the solid lines and the dashed ones.`
- corners: `A corner is where edges meet. Some are at the back.`
- name, keyed by `s.kind`:
  - cube: `Every face is a square.`
  - box: `Its faces are rectangles, not all squares.`
  - pyramid: `Its side faces meet at one point at the top.`
  - triPrism: `It has a triangle at each end.`

### g2-shares (a rectangle in thirds, 2 shaded)
- Idea: keep it.
- cut (state 0): remove. The picture's first beat already shows the cut.
- same: `Cut another way, each part is still one ${one(parts)}.`
- parts: `Touch each part once. They are all the same size.`
- name: `Each part is one ${one(parts)}.` For example, "Each part is one third."
- shaded: `Count only the colored parts.`
- whole: `All the ${name} together make the whole ${shape}.` For example, "All the thirds together make the whole rectangle."

## 4. Maths and wording errors

- **g2-money, `index.ts:113`:** the first group's math line reads "50¢ = 50¢". With no amount before it, it prints the group's value twice. Make the first group's line match the step's prompt: when `g.before` is 0, use `[num(g.count), text(` ${nameOf(g.value, g.count)} = `), num(after), text("¢")]`, which gives "2 quarters = 50¢".
- **g2-lineplot, `index.ts:131`:** the statement is the last step's question. For a read-a-stack problem that is "Now how many pencils are 6 inches long?". In Watch one it is the first line, so "Now" follows nothing and the new pencil is never mentioned. Use the same text as `display` (lines 165-167) for the statement.
- **g2-evenodd, `index.ts:29`:** the tap step asks "Did every dot get a partner?", but the answers are "Even" and "Odd". Remove the `question`: the prompt already asks "Is 13 even or odd?".
- **g2-hundreds, `index.ts:40, 51, 61, 72`:** the hints say "Count the flats", "Count the rods" and "Count the cubes", but practice shows no blocks: the lesson has no `picture` or `displayCounters`. (CounterRow only draws tens and ones, so it can't simply be added.) Reword them to the digits:
  - hundreds: `The hundreds digit is the first one on the left.`
  - tens: `The tens digit is the one in the middle.`
  - ones: `The ones digit is the last one, on the right.`
  - expanded: `A hundred is worth 100 and a ten is worth 10. What are all the hundreds worth? All the tens?`
  The hint test's `UNIT_IN_HINT` note for g2-hundreds (`early-teaching.test.ts:83`) still holds, but its wording says "a flat is worth 100". Update the note to match.
- **g2-solids, `index.ts:58`:** "One corner is round the back." Use US spelling: `One corner is around the back.`
- **g2-within1000, `index.ts:101` (added 2026-10-13, found by Copy):** the adding message says "When a place makes 10 or more, carry 1 to the next place." The 2nd grade lessons say "trade" (g2-regroup: "Trade 10 of them for 1 ten"), and the other two adding messages in this lesson (lines 80 and 91) already avoid "carry". Change it to `When a place makes 10 or more, trade 10 of them for 1 in the next place.` Change the label "Forgot to carry" (lines 77, 88 and 100) to `Forgot to trade`.

## Checks for Development
- Only g2-regroup has a legacy fixture (`tests/fixtures/legacy/g2-regroup.json`), and nothing here changes its display, steps, hints or `pre`. The other grade 2 changes touch no parity test.
- The four `pre` changes go in both `catalog.ts` and the lesson file. The parity test checks they match.
- No test pins grade 2 narration or idea text. The changed hints (g2-hundreds) and the removed question (g2-evenodd) are not pinned either. Run `early-teaching.test.ts` after the hints change.
- After the change, check that no Watch one narration line contains its own math line, for these 16 lessons, and that no grade 2 explanation has a `state: 0` step.
