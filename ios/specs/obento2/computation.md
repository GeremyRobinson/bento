# Bento² · Logic, algorithms and computation (track `cs`, 15 lessons)

**What it is:** the math of step-by-step thinking. True and false, recipes a machine can follow, how fast problems get hard as they grow, and the things no computer can ever solve.

**Role:** spine, track 5. **Needs:** 12th grade. Helpful from Bento: `g11-log` (logs, for search and growth), `g11-comb` (counting, for tours and subsets), `g11-seq` and `g11-geo` (sums, for induction and recursion). Nothing is locked.

## The build: the machine room

Race algorithms, and build an adder from gates. By the end the learner owns a working 4-bit chip made of gates, a race league of algorithms timed on the same inputs, and a map of where computing hits a wall. In the last lesson the two halves meet: the chip runs an algorithm (multiplication by shift-and-add) on the Algorithm stage.

| Unit | What it adds to the machine room |
|---|---|
| 1. Logic and circuits | **The chip.** Truth tables become gates, gates become a half adder, then a full adder, then a 4-bit adder (`adder4`) built on the Logic gate board. |
| 2. Algorithms and growth | **The race league.** Search, sorting and path-finding run on the Algorithm stage with step counters. Each one's step count is saved and raced at n = 10, 1,000 and 1,000,000 items (`race_card`). |
| 3. Hard and impossible | **The wall, and the finale.** Brute force against exponential growth, P vs NP, a Turing machine, the halting problem, then `adder4` plus an algorithm becomes a multiplier (`mult4`): a program running on hardware you built. |

## Units

1. **Logic and circuits** (cs-01 to cs-05): truth tables, the rules of logic, proof steps, gates, the adder.
2. **Algorithms and growth** (cs-06 to cs-10): searching, the sorting race, the growth race, recursion, shortest paths.
3. **Hard and impossible** (cs-11 to cs-15): the traveling salesperson, P vs NP, Turing machines, the halting problem, the chip runs a program.

## Small projects

- **After cs-05: Your adder chip.** A 4-bit ripple-carry adder built from your own full adders on the Logic gate board. Type two numbers from 0 to 15 and watch the carries ripple. Saved as `adder4`.
- **After cs-08: Race card.** Pick three algorithms you've run (linear search, binary search, bubble sort, merge sort) and race them at n = 10, 1,000 and 1,000,000. The card shows each step count and its time at a billion steps per second. Saved as `race_card`.
- **After cs-12: A puzzle that's easy to check.** Make a subset-sum puzzle with a hidden answer, so anyone can check a solution in seconds but a blind search tries up to 2ⁿ subsets to find one. Saved to the Notebook as `puzzle`.
- **After cs-15: The machine room.** `adder4` driven by a shift-and-add program on the Algorithm stage (with an 8-bit register [A | Q] that shifts right after each round) multiplies two 4-bit numbers, with the gate count, the step count and the 8-bit answer. Saved as `mult4`. Build complete.

## New for Development

| What | Toolbox name | Used in |
|---|---|---|
| ★ Algorithm stage: items as bars or cards, an algorithm runs step by step (play, pause, step, scrub back), with a comparison counter and a swap counter. "×10 input" reruns on a larger random input and logs both counts. Modes: linear search, binary search, bubble sort, merge sort, Dijkstra (on Graph explorer), brute-force tour, subset search, shift-and-add. | Algorithm stage | cs-06, cs-07, cs-09, cs-10, cs-11, cs-12, cs-15 |
| Truth table panel: type an expression in p, q, r with ∧, ∨, ¬, →, ⊕; the full table builds row by row; two expressions side by side with differing rows highlighted. | new picture, part of Proof steps | cs-01, cs-02 |
| Proof steps: a column of lines, each with a rule chip (given, definition, algebra, induction hypothesis, modus ponens, contrapositive). A line without a valid justification stays gray. Induction mode shows dominoes falling as base case and step are filled. | Proof steps | cs-02, cs-03, cs-14 |
| Logic gate board: drag AND, OR, NOT, XOR, NAND onto a grid, wire them, toggle input switches, see 1s glow along wires. Save any circuit as a new chip (a box with pins) and reuse it. Gate counter. | Logic gate board | cs-04, cs-05, cs-15; shared with `in` (XOR), `qu` (circuits) |
| Growth race: curves n, n log₂ n, n², n³, 2ⁿ, n! on a graph with a log-scale toggle, a draggable n, and a "time at a billion steps per second" readout beside each. | Growth race | cs-08, cs-09, cs-11 |
| Graph explorer: dots and weighted links on a map or blank canvas; drag weights; run BFS or Dijkstra with the frontier and settled set lit; tour mode for the salesperson with tour length. | Graph explorer | cs-10, cs-11, cs-12; shared with `la` (adjacency matrix) |
| Tower of Hanoi: 1 to 10 disks, drag moves or play the recursive solution, with a move counter. | new picture, inside Algorithm stage | cs-09 |
| Machine builder: a tape of cells, a head, a state light and a rule table (state, read → write, move, next state). Step, run, and a step counter; a halt light. | Machine builder | cs-13, cs-14 |
| Diagonal table: programs down the side, inputs across, cells H (halts) or L (loops); the diagonal lights and the "trouble program" row is built by flipping it, then compared against every row. Tap any cell to flip H/L and the diagonal and trouble row rebuild live. | new picture, inside Machine builder | cs-14 |

---

## Unit 1 · Logic and circuits

### b2-cs-01 · True, false and truth tables
- **You can:** build a truth table for any statement and count when it's true.
- **Needs:** none.
- **Tool:** Truth table panel.
- **Play:** type a statement like (p ∨ q) ∧ ¬r and flip the switches for p, q and r. The output light follows, and each setting you try fills one row of a table that grows to 8 rows.
- **Guess:** "With 4 switches, how many rows does the table need?" Drag a marker from 1 to 20. Bento adds a fourth switch and the table doubles from 8 to 16.
- **Name it:** a statement built from AND (∧), OR (∨) and NOT (¬) is true or false for each setting of its variables. A **truth table** lists every setting: n variables give 2ⁿ rows. OR means "at least one", not "exactly one".
  `rows = 2ⁿ` · `p ∧ q` true only when both are · `p ∨ q` false only when both are false
- **Work it:** expressions from a template bank with 2 variables and 1 or 2 connectives for index < 3, then 3 variables and up to 4 connectives; one row picked at random for step 2.
  Steps: 1 **Rows** type 2ⁿ (3 variables → 8) · 2 **Value at this row** tap T or F (p = T, q = F, r = F in (p ∨ q) ∧ ¬r → T) · 3 **True rows** type how many rows are true ((p ∨ q) ∧ ¬r → 3).
  Slips: typed 2n (6) "Each new variable doubles the rows: 2 × 2 × 2 = 8, not 2 + 2 + 2." · read ∨ as "exactly one" "OR is inclusive: p ∨ q is true when both are true too." · applied ¬ to the whole expression instead of just r "¬ binds to the nearest thing: ¬r flips only r."
- **Oracle:** brute-force evaluation over all 2ⁿ rows.
- **Use it:** a door alarm sounds if (door open or window open) and the alarm is armed. How many of the 8 settings sound it? Not saved.
- **Deeper:** every one of the 2^(2ⁿ) truth tables on n variables (16 for n = 2) can be written using only ∧, ∨, ¬: read off its true rows (disjunctive normal form) or its false rows (conjunctive normal form). Counting those tables is the start of circuit complexity (cs-04 Deeper).

### b2-cs-02 · If, then: the rules of logic
- **You can:** tell when two statements say the same thing, and spot the converse trap.
- **Needs:** b2-cs-01.
- **Tool:** Truth table panel, Proof steps.
- **Play:** put two statements side by side in the panel, like p → q and q → p. The rows where they disagree glow. Edit the second one until no row glows.
- **Guess:** "'If it rained, the street is wet.' Which says the same thing: 'If the street is wet, it rained' or 'If the street is dry, it didn't rain'?" Tap one. The panel runs both against the original and only the second matches on all 4 rows.
- **Name it:** **p → q** is false in exactly one case: p true and q false. Its **contrapositive** ¬q → ¬p always says the same thing; its **converse** q → p doesn't. Two statements are **equivalent** when they agree on every row. De Morgan's laws flip ANDs and ORs under a NOT.
  `p → q ≡ ¬p ∨ q ≡ ¬q → ¬p` · `¬(p ∧ q) ≡ ¬p ∨ ¬q` · `¬(p ∨ q) ≡ ¬p ∧ ¬q`
- **Work it:** pairs from a bank of 2-variable statements for index < 3 (implication, converse, contrapositive, inverse, De Morgan pairs), then 3-variable pairs; word versions ("if you're over 18, you can vote") for the tap step.
  Steps: 1 **Value of p → q** at a given row tap T / F · 2 **Rows where they differ** type a count (p → q vs q → p → 2; p → q vs ¬q → ¬p → 0) · 3 **Equivalent?** tap yes / no · 4 **Pick the same statement** tap one of four word versions.
  Slips: said p → q is false when p is false "A promise with a false 'if' isn't broken. p → q is false only when p is true and q is false." · picked the converse "The converse turns it around and can fail: a wet street might be from a sprinkler." · ¬(p ∧ q) as ¬p ∧ ¬q "Under a NOT, AND becomes OR: it's enough that one of them fails."
- **Oracle:** brute-force comparison of the two tables.
- **Use it:** settings rules for a phone: "if Do Not Disturb is on, then calls are silenced." Find the rule that's equivalent and the one that only sounds equivalent. Not saved.
- **Deeper:** soundness and completeness for propositional logic: a statement is provable from the rules exactly when it's true on every row. Resolution as a single rule that's complete for refutation, the basis of SAT solvers (and so of cs-12).

### b2-cs-03 · Proof steps and induction
- **You can:** prove a statement for every whole number with induction, justifying every step.
- **Needs:** b2-cs-02, `g11-seq`.
- **Tool:** Proof steps (induction mode).
- **Play:** a row of dominoes, one per n. Fill the base case and the first domino tips; fill the step "if n works, then n + 1 works" and the whole row falls. Leave a step unjustified and the chain stops there.
- **Guess:** "1 + 3 + 5 + … + (2n − 1). For n = 10, what's the sum?" Type a number. The dominoes run to 10 and the squares picture (an L of each odd number around a square) shows 100.
- **Name it:** **induction** proves a claim P(n) for every n in two moves: prove P(1), then prove that P(n) forces P(n + 1). Every line in a proof needs a reason: a given, a definition, algebra, or the induction hypothesis (assuming P(n) for the step).
  `P(1)` and `P(n) ⇒ P(n + 1)` give `P(n)` for all n ≥ 1 · `1 + 3 + … + (2n − 1) = n²` · `1 + 2 + … + n = n(n + 1)/2` · `1 + 2 + 4 + … + 2ⁿ⁻¹ = 2ⁿ − 1`
- **Work it:** claims from the three formulas above plus `1² + 2² + … + n² = n(n + 1)(2n + 1)/6` (later); k from 2 to 6 for index < 3, then 5 to 20; N from 10 to 100, except N from 10 to 20 for the doubling sum `2ᴺ − 1` (the oracle uses BigInt).
  Steps: 1 **Base case** type the left side at n = 1 (1) · 2 **Term added** going from n = k to k + 1 (odd sum, k = 4 → 9) · 3 **Justify the step** tap the reason for "1 + 3 + … + (2k − 1) + (2k + 1) = k² + 2k + 1" (induction hypothesis) · 4 **Value at N** type (sum of the first 10 odd numbers → 100; 1 + … + 100 → 5,050; 1 + 2 + … + 2⁹ → 1,023).
  Slips: added 2k − 1 as the new term "The next term uses n = k + 1: 2(k + 1) − 1 = 2k + 1." · justified the step with "what we want to prove" "That's circular. The step may only assume P(k), the induction hypothesis." · skipped the base case "Without P(1) nothing falls. 'Every n is bigger than itself plus 1' has a valid step and no base."
- **Oracle:** direct summation for the value; fixed answers for the taps.
- **Use it:** a robot climbs stairs taking 1 or 2 steps at a time. Count the ways to climb n stairs (1, 2, 3, 5, 8, …; 10 stairs → 89), then prove by induction that the count is the Fibonacci number F(n + 1), using the two stairs before n + 1. The Proof steps column is saved to the Notebook.
- **Deeper:** strong induction and the well-ordering principle; structural induction on trees and programs (how compilers are proved correct). Proof assistants like Lean check every line by machine, which connects proofs to computation, and Gödel's incompleteness theorem (cs-14 Deeper) shows where any such system must stop.

### b2-cs-04 · Logic gates
- **You can:** read a circuit of gates, and build any gate out of NANDs.
- **Needs:** b2-cs-01.
- **Tool:** Logic gate board.
- **Play:** drag AND, OR, NOT, XOR and NAND gates onto the board, wire them to two switches and a light, and flip the switches. 1s glow along the wires as they flow through.
- **Guess:** "How many NAND gates does it take to make an AND?" Drag a number from 1 to 6. The board builds it: a NAND followed by a NAND used as NOT, so 2.
- **Name it:** a **gate** is a truth table made physical: wires carry 1 or 0. **XOR** (⊕) is 1 when exactly one input is 1. **NAND** is NOT-AND, and it's **universal**: every other gate can be made from NANDs alone. A chip is billions of these.
  `NOT a = a NAND a` · `a AND b = NOT(a NAND b)` · `a OR b = (NOT a) NAND (NOT b)` · `a ⊕ b` uses 4 NANDs
- **Work it:** random circuits with 2 inputs and 2 or 3 gates for index < 3, then 3 inputs and up to 5 gates; inputs set at random; NAND-count questions from {NOT 1, AND 2, OR 3, XOR 4}. Circuits shown as expressions render through the shared helpers (no printed coefficient 1, no plus sign before a minus sign).
  Steps: 1 **Output** tap 0 or 1 for the shown inputs · 2 **Inputs that light it** type how many of the 2ⁿ input settings give 1 · 3 **NANDs needed** type for a named gate (OR → 3).
  Slips: XOR of 1 and 1 as 1 "XOR means exactly one. Two 1s give 0; that's what makes it useful for adding." · NAND read as AND "NAND flips the AND: it's 0 only when both inputs are 1." · OR from NANDs as 2 "You need NOT a and NOT b first: two NANDs, then one more NAND to combine them. That's 3."
- **Oracle:** circuit simulation over all input settings.
- **Use it:** build XOR on the board and save it as a chip. It's the first part of the adder. Saved as chip `xor`.
- **Deeper:** proof that NAND is universal, via the normal forms from cs-01. Shannon's counting argument: there are 2^(2ⁿ) functions on n inputs but far fewer small circuits, so most functions need about 2ⁿ/n gates, yet no one can prove any specific function in NP needs more than a few times n gates. A single neuron with a threshold is a weighted gate; one neuron can do AND and OR but not XOR (links to b2-ai-04).

### b2-cs-05 · An adder from gates
- **You can:** build a circuit that adds binary numbers, carry by carry.
- **Needs:** b2-cs-04.
- **Tool:** Logic gate board, Scratch paper.
- **Play:** wire a half adder (an XOR and an AND), then chain four full adders into a 4-bit adder. Type two numbers from 0 to 15 on the input switches and watch the carry ripple from right to left, one column at a time.
- **Guess:** "1011 + 0110. Which columns will send a carry left?" Tap the columns. The board ripples and lights the carries in columns 2, 3 and 4 (from the right), and the carry-out light turns on.
- **Name it:** binary adding is column by column: the sum bit is XOR and the carry is "at least two of the three inputs are 1". A **half adder** adds two bits; a **full adder** adds two bits plus a carry, using 2 XOR, 2 AND and 1 OR. Chain n full adders and you can add n-bit numbers: the **ripple-carry adder**.
  `sum = a ⊕ b ⊕ c` · `carry = (a ∧ b) ∨ (c ∧ (a ⊕ b))` · `gates for n bits = 5n`
- **Work it:** a, b from 0 to 7 with at most one carry for index < 3, then 0 to 15 with any carries; n from {4, 8, 16, 32, 64} for the gate count.
  Steps: 1 **Bottom column** sum bit and carry (1 + 0 → 1, 0) · 2 **Sum bits** type the 4 bits (1011 + 0110 → 0001) · 3 **Carry out** tap 0 or 1 (1) · 4 **In decimal** type a + b (17) · 5 **Gates** for an n-bit adder (32 → 160).
  Slips: added each column with no carry (1101) "That's XOR column by column. 1 + 1 makes 0 and carries 1 to the next column." · ignored the carry out "4 bits only hold 0 to 15. 17 needs the carry out as a fifth bit: 10001." · counted 2 gates per bit "Each column needs a full adder (5 gates) to take a carry in, so 5 per bit."
- **Oracle:** `(a + b) % 16`, `(a + b) >> 4`, `a + b`, `5 * n`.
- **Use it:** **Project: Your adder chip.** Box your 4 full adders into a chip with 8 input pins, 4 output pins and a carry. Saved as `adder4`. This is the first half of the machine room.
- **Deeper:** the ripple carry takes time proportional to n; a carry-lookahead adder computes all carries in about log₂ n gate delays using "generate" and "propagate" signals, the same prefix trick as a parallel scan. Two's complement turns the adder into a subtractor with one XOR per bit.

## Unit 2 · Algorithms and growth

### b2-cs-06 · Searching: one by one or halving
- **You can:** count the worst-case steps for linear and binary search.
- **Needs:** `g11-log`; `in` b2-in-01 helps.
- **Tool:** ★ Algorithm stage (search modes).
- **Play:** a row of numbered cards, sorted. Pick a target and race two searchers: one turns cards from the left, the other opens the middle and throws away half. Tap "×10 input" and the first searcher's count jumps ten times; the second adds about 3.
- **Guess:** "1,000,000 sorted cards. How many cards does binary search open, at most?" Drag a marker on a log-scale strip from 1 to 1,000,000. It lands on 20.
- **Name it:** an **algorithm** is a recipe precise enough for a machine. **Linear search** checks items one at a time: n steps in the worst case. **Binary search** on sorted items checks the middle and discards half each time: the number of steps is the number of binary digits of n.
  `linear worst = n` · `binary worst = ⌊log₂ n⌋ + 1`
- **Work it:** n from {7, 15, 16, 31} for index < 3, then {100, 1,000, 1,000,000}; a sorted list of 15 numbers and a target for the trace step.
  Steps: 1 **Linear worst case** type n · 2 **Binary worst case** type (15 → 4; 16 → 5; 100 → 7; 1,000 → 10; 1,000,000 → 20) · 3 **Trace** tap the cards binary search opens, in order.
  Slips: typed log₂ n unrounded (6.64) "You can't open part of a card. Count whole halvings: ⌊log₂ n⌋ + 1." · typed n/2 for binary "That's one halving. It keeps halving what's left." · opened the target's neighbor first "Always open the middle of what's left, not where you think the target is."
- **Oracle:** `n`, `n.bit_length()`, simulated trace.
- **Use it:** a phone's contacts list has 2,000 names. How many checks does binary search need? (11.) Linear and binary search go on `race_card`.
- **Deeper:** a decision-tree lower bound: any comparison search must distinguish n outcomes with yes/no answers, so it needs ⌈log₂(n + 1)⌉ comparisons (the same count as b2-in-01). Hashing beats it on average by not comparing at all. Grover's quantum search finds an item among n unsorted ones in about √n steps (links to `qu`).

### b2-cs-07 · The sorting race
- **You can:** run bubble sort and merge sort by hand and count their comparisons.
- **Needs:** b2-cs-06.
- **Tool:** ★ Algorithm stage (sort modes), Growth race.
- **Play:** the same 1,024 shuffled bars sort twice side by side: bubble sort swaps neighbors pass after pass, while merge sort splits, sorts halves and zips them together. Comparison counters run under each. Drag the bar count from 8 to 1,024 and watch the gap widen.
- **Guess:** "For 1,024 bars, how many comparisons will bubble sort make compared with merge sort: about 2×, about 10× or about 50×?" Pick one. The worst-case counts are 523,776 and 9,217 (about 57×), shown next to the live counters for this shuffle: bubble sort (the full version, with no early exit) always makes 523,776, and merge sort makes about 8,950 (about 58×). Either way, 50× is closest.
- **Name it:** **bubble sort** compares neighbors and swaps those out of order; the full version makes n(n − 1)/2 comparisons, and its swaps equal the number of out-of-order pairs. **Merge sort** splits in half, sorts each half, and merges; for n = 2ᵏ items it makes at most n·k − n + 1 comparisons. Slow growth beats a fast start.
  `bubble = n(n − 1)/2` · `merge (n = 2ᵏ) ≤ n·k − n + 1` · `swaps = inversions`
- **Work it:** lists of 5 distinct numbers from 1 to 20 for index < 3, then 6 or 7; n for counts from {8, 16, 32, 1,024}.
  Steps: 1 **After one bubble pass** type the list ([5, 1, 4, 2, 8] → [1, 4, 2, 5, 8]) · 2 **Total swaps** type the number of out-of-order pairs (4) · 3 **Bubble comparisons** for n (8 → 28) · 4 **Merge comparisons, worst case** for n = 2ᵏ (8 → 17; 1,024 → 9,217).
  Slips: moved the smallest to the front in one pass "One pass carries the largest to the end; small items move left only one place per pass." · counted swaps as comparisons "Every neighbor pair is compared; only out-of-order ones swap." · n² for bubble (64) "Each pair is compared once: n(n − 1)/2 = 28."
- **Oracle:** simulate one pass, count inversions, `n*(n-1)//2`, `n*k - n + 1`.
- **Use it:** sort 1,000 song lengths both ways and save both step counts to `race_card`.
- **Deeper:** any comparison sort needs at least log₂(n!) ≈ n log₂ n − 1.44n comparisons (decision trees plus Stirling), so merge sort is optimal up to a small term. Quicksort's expected comparisons are 2n ln n with random pivots (links to `pr`). Counting sort and radix sort dodge the bound by not comparing.

### b2-cs-08 · The growth race
- **You can:** predict how an algorithm's running time grows when the input grows.
- **Needs:** b2-cs-07.
- **Tool:** Growth race, ★ Algorithm stage.
- **Play:** curves n, n log₂ n, n², n³ and 2ⁿ race across the graph. Drag n and the "time at a billion steps per second" readouts update beside each. Toggle the log scale to see 2ⁿ leave every other curve behind.
- **Guess:** "An n² algorithm takes 3 seconds on 1,000 items. How long on 10,000?" Drag a marker on a timeline from 1 second to 1 hour. It lands on 300 seconds (5 minutes).
- **Name it:** what matters is how steps grow with n, written **O(f(n))**: the shape, ignoring constant factors. If the time is about c · f(n), growing n changes the time by f(new) / f(old). Polynomial growth is tame; exponential growth isn't: adding 10 items to a 2ⁿ algorithm multiplies its time by 1,024.
  `new time = old time × f(n_new) / f(n_old)` · `n ≪ n log₂ n ≪ n² ≪ n³ ≪ 2ⁿ` for large n
- **Work it:** f from {n, n², n³} with n × 10 for index < 3 (old time 1 to 9 s), then f = 2ⁿ with n + 10 or n + 20, and million-item readouts at 10⁹ steps per second (round to 2 significant figures).
  Steps: 1 **Growth factor** type f(n_new)/f(n_old) (n², ×10 → 100; n³, ×10 → 1,000; 2ⁿ, +10 → 1,024) · 2 **New time** type in seconds (3 × 100 → 300) · 3 **A million items** type seconds for n² (10¹² steps → 1,000 s) · 4 **Fastest-growing** tap which of four curves wins at large n.
  Slips: scaled n² by 10 "Ten times the items, ten squared the steps: 100 times longer." · scaled 2ⁿ by 2 for +10 items "Each extra item doubles the time. Ten more items doubles it ten times: 2¹⁰ = 1,024." · thought a big constant beats growth "A 100n algorithm still beats an n² one once n passes 100."
- **Oracle:** `old_time * f(new) / f(old)`.
- **Use it:** **Project: Race card.** Pick three algorithms you've run and race them at n = 10, 1,000 and 1,000,000. Saved as `race_card`.
- **Deeper:** formal O, Ω and Θ with constants c and n₀, and limits of ratios to compare growth. The time hierarchy theorem: with more time, strictly more problems become solvable, proved by diagonalization (the same trick as cs-14).

### b2-cs-09 · Recursion: solve it by solving a smaller one
- **You can:** turn a recursive recipe into a step count.
- **Needs:** b2-cs-03, b2-cs-07.
- **Tool:** Tower of Hanoi, Growth race, ★ Algorithm stage.
- **Play:** move a tower of disks from one peg to another, never placing a big disk on a small one. Tap "solve" and the recursive solution plays: move the top n − 1 out of the way, move the biggest, move the n − 1 back on top. The move counter runs.
- **Guess:** "3 disks take 7 moves. How many for 10?" Type a number. The solver plays at speed and the counter stops at 1,023.
- **Name it:** a **recursive** algorithm solves a problem by calling itself on smaller copies. Its step count follows a **recurrence**. Hanoi doubles and adds 1, so it's exponential. Merge sort does two half-size problems plus n to merge, so it's n log₂ n.
  `H(n) = 2H(n − 1) + 1 ⇒ H(n) = 2ⁿ − 1` · `T(n) = 2T(n/2) + n, T(1) = 0 ⇒ T(n) = n log₂ n`
- **Work it:** n from 2 to 5 for index < 3, then up to 20 for Hanoi and n = 2ᵏ from 2 to 1,024 for T.
  Steps: 1 **One step up** type H(n) from H(n − 1) shown (H(3) = 7 → H(4) = 15) · 2 **Closed form** type H(n) (10 → 1,023) · 3 **Merge recurrence** type T(n), where T charges n steps for each merge (a merge of n items makes at most n − 1 comparisons, so T slightly overcounts cs-07's comparisons) (8 → 24; 16 → 64; 1,024 → 10,240).
  Slips: H(n) = 2H(n − 1) "Don't forget the one move of the biggest disk: add 1." · typed 2ⁿ "Check n = 1: one move, so it's 2ⁿ − 1." · T(n) as n²/2 "Each of the log₂ n levels does n work in total: n log₂ n." · typed 17 for n = 8 "That's cs-07's worst-case comparison count. T charges a full n for each merge, so T(8) = 8 × 3 = 24."
- **Oracle:** `2**n - 1`, `n * log2(n)`.
- **Use it:** at one move per second, how long for 64 disks? (2⁶⁴ − 1 seconds, about 585 billion years.) Not saved.
- **Deeper:** the master theorem for T(n) = aT(n/b) + f(n), comparing f(n) with n^(log_b a). Karatsuba's multiplication (3 half-size multiplies) gives n^(log₂ 3) ≈ n^1.585 and Strassen's matrix multiplication (7 half-size products) gives n^(log₂ 7) ≈ n^2.807 (links to b2-la-06).

### b2-cs-10 · Shortest paths
- **You can:** find the shortest route through a network with Dijkstra's algorithm.
- **Needs:** b2-cs-06.
- **Tool:** Graph explorer, ★ Algorithm stage.
- **Play:** a city map of dots and roads with travel times. Drag a road's time up or down and watch the shortest path from A to D light up and reroute. Run Dijkstra and see the frontier spread out from A like a ripple.
- **Guess:** "Roads: A–B 1, B–D 9, A–C 4, C–D 2. Tap the shortest route from A to D." The explorer lights A–C–D (6), and shows that grabbing the cheapest road first (A–B) costs 10.
- **Name it:** **Dijkstra's algorithm** keeps a tentative distance for every place. Each round it settles the unsettled place with the smallest distance, then updates its neighbors: new distance = settled distance + road. Grabbing the nearest next road isn't enough; the total from the start is what counts. Unweighted maps use breadth-first search.
  `d(v) ← min(d(v), d(u) + w(u, v))`
- **Work it:** unweighted graphs with 5 or 6 nodes for index < 3, then connected weighted graphs with 5 to 7 nodes and weights from 1 to 9. The generator rejects any graph with a tie for the next settled place or more than one shortest route to the target.
  Steps (weighted): 1 **Next settled** tap the place Dijkstra settles after A · 2 **Distance** type the shortest distance from A to the target · 3 **Route** tap the roads in order. Steps (unweighted, index < 3): 1 **Distance in roads** type the fewest roads from A to the target · 2 **Route** tap the roads in order.
  Slips: followed the cheapest road from each place "That's nearest-neighbor greed. A–B is cheap, but B–D is 9. Compare total distances from A." · settled a place before updating "Update the neighbors of each settled place before choosing the next." · added the road twice "Each road counts once in a route."
- **Oracle:** Dijkstra (or BFS when unweighted).
- **Use it:** find the fastest walk across a campus map you edit. Dijkstra's step count joins `race_card`.
- **Deeper:** why Dijkstra is correct (a settled distance can never improve when weights are nonnegative) and runs in O((V + E) log V) with a heap. Bellman–Ford handles negative roads and detects negative loops; A* adds a distance guess to aim the search. Powers of the adjacency matrix count walks of each length (links to `la`).

## Unit 3 · Hard and impossible

### b2-cs-11 · The traveling salesperson
- **You can:** count the possible tours and see why trying them all is hopeless.
- **Needs:** b2-cs-08, `g11-comb`.
- **Tool:** Graph explorer (tour mode), Growth race, ★ Algorithm stage.
- **Play:** drop cities on a map and tap a route that visits each once and returns home. The tour length updates as you drag cities. Tap "try them all" and the stage cycles through every tour; add one city and the counter jumps.
- **Guess:** "With 10 cities, how many different round trips are there?" Drag on a log scale from 10 to 10,000,000. It lands at 181,440.
- **Name it:** a **tour** visits every city once and returns. Fix the start, order the other n − 1, and count each loop once in each direction: (n − 1)!/2 tours. That's even worse than 2ⁿ. No one knows a fast exact method, and finding one would settle P vs NP (cs-12).
  `tours = (n − 1)!/2`
- **Work it:** n from {4, 5, 6} for index < 3, then {8, 10, 20}; 4-city distance tables with whole-number distances from 1 to 12 for step 2, with one shortest tour and, in some tables, a nearest-neighbor tour from A (no ties) that isn't the shortest; years rounded to 1 decimal with 1 year = 365 days.
  Steps: 1 **Tours** type (4 → 3; 5 → 12; 6 → 60; 8 → 2,520; 10 → 181,440) · 2 **Shortest tour** type its length (AB 2, AC 9, AD 5, BC 6, BD 4, CD 3 → A–B–C–D–A = 16; the nearest-neighbor tour A–B–D–C–A is 18) · 3 **Brute force for 20 cities** at a billion tours per second, type years (19!/2 ≈ 6.08 × 10¹⁶ tours, so 6.08 × 10⁷ s → 1.9 years).
  Slips: typed n! "Fix the starting city and the rest can go in (n − 1)! orders." · forgot to halve "A–B–C–D–A and A–D–C–B–A are the same loop driven backward. Halve it." · picked the nearest-neighbor tour as best when it isn't "Greedy tours are good guesses, not guarantees. Compare all three."
- **Oracle:** `factorial(n-1)//2`, brute-force tour search, `factorial(19)/2/1e9/(365*86400)`.
- **Use it:** plan a delivery loop for 6 stops on a real map. Brute force is still instant at 60 tours; at 20 stops it isn't. Not saved.
- **Deeper:** Held–Karp dynamic programming solves it in O(n² 2ⁿ), far better than (n − 1)! but still exponential. Christofides' algorithm guarantees a tour at most 1.5 times the best on maps obeying the triangle inequality. Stirling's formula n! ≈ √(2πn)(n/e)ⁿ shows how fast the count grows.

### b2-cs-12 · P vs NP: easy to check, hard to find
- **You can:** tell finding a solution from checking one, and say what P vs NP asks.
- **Needs:** b2-cs-11.
- **Tool:** ★ Algorithm stage (subset search), Graph explorer.
- **Play:** a pile of numbered weights and a target. Tap weights to try to hit the target exactly; any answer is checked instantly. Then tap "search all" and the stage tries every subset with a counter. Add one weight and the search doubles.
- **Guess:** "Weights 3, 7, 12, 5, 9 and target 21. How many subsets might a blind search try?" Drag from 1 to 100. It shows 32, then lights one that works (12 + 9).
- **Name it:** **P** is the problems a computer can solve in polynomial time (like n², n³). **NP** is the problems where a proposed answer can be checked in polynomial time, like subset sum, sudoku and the salesperson's "is there a tour under 100?". **NP-complete** problems are the hardest in NP: a fast method for any one would give a fast method for all. Whether P = NP is open, with a million-dollar prize.
  `subsets of n items = 2ⁿ` · `P ⊆ NP` · `P = NP?` (open)
- **Work it:** 4 or 5 weights from 1 to 15 for index < 3, then 6 to 8 weights from 1 to 30, targets chosen with at least one solution (oracle checks any submitted subset).
  Steps: 1 **Subsets** type 2ⁿ (5 → 32) · 2 **Check this answer** tap valid / not valid for a proposed subset (7 + 5 + 9 = 21 → valid; 3 + 7 + 12 = 22 → not) · 3 **Find one** tap a subset that hits the target · 4 **Which is which** tap "in P", "in NP, no fast method known" or "not known to be in NP" for short descriptions (sort a list → in P).
  Slips: typed n! for subsets "Each weight is in or out: 2 choices, n times. 2ⁿ, not n!." · accepted a subset using a weight twice "Each weight can be used once." · said NP means "not polynomial" "NP is 'checkable in polynomial time'. Every problem in P is in NP too."
- **Oracle:** `2**n`, `sum(subset) == target and subset ⊆ weights`.
- **Use it:** **Project: A puzzle that's easy to check.** Make a subset-sum puzzle with a hidden answer for someone else. Saved to the Notebook as `puzzle`.
- **Deeper:** with small whole-number weights, dynamic programming finds a subset in about n × target steps (pseudo-polynomial time), so hard puzzles need huge numbers. The Cook–Levin theorem (SAT is NP-complete) and reductions, like 3-SAT to clique, Karp's 21 problems. Most modern cryptography bets that some problems in NP are hard on average. Why it's hard to prove: relativization (Baker–Gill–Solovay) and natural proofs barriers. Beyond NP: PSPACE, and BQP for quantum computers (links to `qu`).

### b2-cs-13 · Turing machines
- **You can:** run a Turing machine by hand and read its answer off the tape.
- **Needs:** b2-cs-05.
- **Tool:** Machine builder.
- **Play:** a tape of 0s and 1s, a head, and a three-rule table. Drag the head to any cell or tap a cell to change it, then step the machine: it reads, writes, moves and changes state. Load the "add 1" machine and type any binary number: it walks left turning 1s into 0s until it finds a 0 or a blank, writes 1, and halts.
- **Guess:** "The add-1 machine starts on the right end of 1011. How many steps until it halts?" Drag from 1 to 8. It runs and halts on 1100 after 3 steps.
- **Name it:** a **Turing machine** is a tape, a head and a finite table of rules: (state, symbol read) → (symbol to write, move left or right, next state). Despite being this small, it can compute anything any computer can; that claim is the **Church–Turing thesis**. A **universal** machine reads another machine's rules from its tape and runs them, which is what a stored-program computer is.
  `rule: (q, s) → (s′, L or R, q′)`
- **Work it:** the add-1 machine on inputs of 3 or 4 bits for index < 3, then 5 to 8 bits; later a 3-rule "flip every bit" machine and a unary adder (111 + 11 → 11111).
  Steps: 1 **First rule used** tap the row · 2 **Tape at halt** type the bits (1011 → 1100; 111 → 1000) · 3 **Steps** type (trailing 1s + 1: 1011 → 3; 111 → 4) · 4 **As a number** type the result in decimal (12).
  Slips: added 1 at the left end "The head starts at the right end, the ones place." · stopped after flipping one 1 "A 1 becomes 0 and the carry moves left. Keep going until a 0 or a blank takes the 1." · forgot the new leading 1 for 111 "The blank to the left becomes 1: 111 + 1 = 1000."
- **Oracle:** simulate the rule table.
- **Use it:** load `adder4`'s job onto the machine: a machine that adds two binary numbers on its tape. The gate board and the tape compute the same thing. Not saved.
- **Deeper:** the universal Turing machine and why it implies software. Equivalence with lambda calculus and with register machines. The Busy Beaver function BB(n), the most steps an n-state halting machine can take: BB(5) = 47,176,870, proved in 2024 with a machine-checked proof, and BB grows faster than any computable function (cs-14).

### b2-cs-14 · The halting problem
- **You can:** explain why no program can decide whether every program halts.
- **Needs:** b2-cs-13, b2-cs-02.
- **Tool:** Machine builder (diagonal table), Proof steps.
- **Play:** a table lists programs down the side and inputs across, each cell H (halts) or L (loops). The diagonal lights up and the "trouble program" row below flips every diagonal cell. Tap any cell to flip it between H and L: the diagonal and the trouble row rebuild live. Try to make the trouble row match some program: each row still disagrees with it somewhere on the diagonal.
- **Guess:** "The trouble program does the opposite of program 3 on input 3. Can it be program 3?" Tap yes or no. The table puts them side by side and the third cell clashes.
- **Name it:** suppose some program `halts(P, x)` always answered correctly. Build `trouble(P)`: if `halts(P, P)` says yes, loop forever; otherwise stop. Run `trouble` on itself and either answer is wrong. So no such program exists: the **halting problem** is **undecidable**. Some questions about programs have no algorithm at all, no matter how fast the computer.
  `trouble(P) halts ⇔ P(P) loops` · `trouble(trouble) halts ⇔ trouble(trouble) loops` (contradiction)
- **Work it:** 3 × 3 tables for index < 3, then 4 × 4 and 5 × 5, H/L filled at random.
  Steps: 1 **The trouble row** type the flipped diagonal as letters (diagonal H, L, H, H → L, H, L, L) · 2 **Where it differs from program k** type the column (k) · 3 **Decidable?** tap yes / no for statements ("Does this program halt within 1,000 steps?" yes, just run it; "Does this program ever print 7?" no in general).
  Slips: copied the diagonal "Trouble does the opposite on each diagonal cell: flip every letter." · said "halts within 1,000 steps" is undecidable "With a step limit you can just run it and watch. The trouble is 'ever'." · said a faster computer would fix it "This isn't about speed. The contradiction holds for any machine."
- **Oracle:** flip the diagonal; fixed answers for the taps.
- **Use it:** why can't an app store's checker guarantee an app will never freeze? Write the one-line reason in the Notebook.
- **Deeper:** Rice's theorem: every nontrivial question about what a program computes is undecidable. Gödel's incompleteness theorems: any consistent proof system that does arithmetic has true statements it can't prove (the same diagonal trick, cs-03). Kolmogorov complexity is uncomputable (`in` b2-in-07, b2-in-12), and BB(n) outgrows every computable function.

### b2-cs-15 · The chip runs a program
- **You can:** multiply with nothing but an adder and a recipe, and count what it costs.
- **Needs:** b2-cs-05, b2-cs-09.
- **Tool:** Logic gate board, ★ Algorithm stage (shift-and-add).
- **Play:** `adder4` sits on the board next to an 8-bit register [A | Q]: A starts at 0, Q holds the multiplier and M holds the multiplicand. The stage runs a short program four rounds: if the last bit of Q is 1, `adder4` adds M into A (keeping its carry out), then the carry, A and Q all shift right one place. Step through 13 × 6 and watch the answer's bits slide into Q while the adder's carries ripple.
- **Guess:** "To multiply 11 × 5 (5 is 101 in binary), how many times does the adder run?" Drag from 0 to 8. It runs twice: once for each 1 in 101.
- **Name it:** hardware only adds and shifts; everything else is an **algorithm** on top. Binary long multiplication is **shift-and-add**: shifting left one place doubles a number, and each 1 bit of the multiplier adds one shifted copy. A 4-bit adder can't hold shifted copies as big as 52, so the chip shifts the running total right instead: each round it adds M into the top half A, then slides [carry | A | Q] right, so every add lands one place higher in the final answer. After 4 rounds [A | Q] holds the 8-bit product. Schoolbook multiplication of two n-digit numbers takes n² digit products; cleverer recursion takes fewer.
  `a × b = Σ (a shifted left by i) over each bit i of b that is 1` · `adds = number of 1s in b` · each round: `if Q₀ = 1, A ← A + M`, then shift `[C | A | Q]` right · `schoolbook = n²` · `Karatsuba (n = 2ᵏ) = 3ᵏ`
- **Work it:** a, b from 2 to 7 for index < 3, then 2 to 15; n from {4, 16, 1,024} for the race step.
  Steps: 1 **Multiplier in binary** type b (6 → 110, so Q = 0110) · 2 **Adds** type the number of 1s (2) · 3 **Each add** type A + M in decimal for each round that adds, with A read off the register (round 2: 0 + 13 = 13; round 3: 6 + 13 = 19, so carry out 1 and A = 0011) · 4 **Product** type [A | Q] at the end in decimal (0100 1110 → 78) · 5 **Digit products for n digits** schoolbook vs Karatsuba (1,024 → 1,048,576 and 59,049).
  Slips: dropped the carry out (14) "6 + 13 = 19 needs 5 bits: 1 0011. The carry out shifts into the top of A on the next shift, so keep it." · counted one add per bit, 1s and 0s "A 0 bit adds nothing, so skip it." · read 3ᵏ with k = n "k is the number of halvings: 1,024 digits is k = 10, so 3¹⁰ = 59,049."
- **Oracle:** `a * b`, `bin(b).count('1')`, a 4-round simulation of the [C | A | Q] register, `n**2`, `3**log2(n)`.
- **Use it:** **Project: The machine room.** Wire `adder4` to the shift-and-add program with the 8-bit register [A | Q] and multiply any two numbers from 0 to 15 (`adder4` runs at most 4 times, once per 1 in the multiplier). The Notebook saves the gate count, the step count and the answer as `mult4`. Build complete.
- **Deeper:** Karatsuba's trick (three multiplies instead of four) and its n^(log₂ 3) ≈ n^1.585 count; Toom–Cook and FFT methods; Harvey and van der Hoeven's 2019 O(n log n) algorithm. Integer multiplication is easy, but undoing it (factoring) isn't known to be: the best known classical methods are super-polynomial, while Shor's quantum algorithm factors in polynomial time (links to `qu`).
