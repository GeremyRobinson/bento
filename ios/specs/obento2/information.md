# Bento² · Information and entropy (track `in`, 12 lessons)

**What it is:** the math of surprise. It measures how much a message really tells you, which is why files compress, codes fix their own errors, and a model learns by being less surprised by the right answer.

**Role:** spine, track 4. **Needs:** probability (track `pr`; from Bento, `st-probrules` and `st-expected`) and logs (`g11-log`, `pc-logs`). Nothing is locked.

## The build: the Shrinker

A code that shrinks a message. The learner types or pastes any message (a sentence, a poem, a page), and by the end the Shrinker measures it, builds a code for it, predicts it, scores its own predictions in bits, and wraps the result so it survives noise. Each unit adds a part:

| Unit | What it adds to the Shrinker |
|---|---|
| 1. Surprise | **The target line.** Letter counts and the message's entropy per letter, `H_msg`. This is the floor no letter-by-letter code can beat. |
| 2. Codes that shrink | **The coder.** A Huffman code built from the counts (`code_msg`), the shrunk size in bits, then a context model that predicts each letter from the one before (`model_msg`) and an ideal coder that spends −log₂ p bits per letter. |
| 3. Learning and noise | **The scorer and the armor.** Cross-entropy scores the model against the message in bits per letter, and a Hamming (7, 4) wrapper lets the shrunk file survive flipped bits. The final lesson runs the whole pipe end to end. |

## Units

1. **Surprise** (b2-in-01 to b2-in-04): bits as questions, surprise of one event, entropy, the loaded coin.
2. **Codes that shrink** (b2-in-05 to b2-in-08): prefix codes, Huffman trees, the limits of compression, prediction.
3. **Learning and noise** (b2-in-09 to b2-in-12): cross-entropy, mutual information, error-fixing codes, the Shrinker end to end.

## Small projects

- **After b2-in-04: Your surprise profile.** Type a sentence. Bento counts its letters, draws the surprise of each letter as a bar, and prints entropy per letter. Saved as `H_msg` with its counts `counts_msg`. This becomes the Shrinker's target line.
- **After b2-in-06: Your first code.** The Huffman tree for your own sentence, the code table, and the shrunk size next to 8 bits per letter. Saved as `code_msg`. This is Shrinker v1.
- **After b2-in-08: Predict me.** A one-letter-context model trained on your sentence. Play the guessing game against it and see its bits per letter fall below `H_msg`. Saved as `model_msg`. This is Shrinker v2.
- **After b2-in-12: The Shrinker.** The full build: message in, measured, modeled, coded, armored, and decoded back out with a flipped bit repaired. Kept in the Notebook.

## New for Development

| What | Toolbox name | Used in |
|---|---|---|
| ★ Guess-the-message game: three modes. (a) Number mode: think of 1 to N, the game halves the range with yes/no questions and tallies bits. (b) Letter mode: guess the next letter of a hidden message; each guess shows the bits it cost. (c) Model mode: a model guesses instead, showing its probability bar for each next letter. | Guess-the-message game | b2-in-01, b2-in-08, b2-in-12 |
| Surprise bars: a probability editor (drag bar heights, they stay summing to 1) with a second row of bars showing −log₂ p, and the weighted average drawn as a level line. | Surprise meter | b2-in-02, b2-in-03, b2-in-09; shared with `pr`, `ai` |
| Entropy curve: H(p) for a coin, with a draggable p, a coin that flips live, and a running "bits per flip" tally from real flips. | Surprise meter (signature picture 1) | b2-in-04 |
| Code builder: drag letters with counts, merge the two lightest with a tap, watch the tree grow, read the code table, and see the message re-encoded as a bit strip that shortens. Also a free mode to type a code and test the prefix rule and Kraft sum. | Code builder (Huffman tree) | b2-in-05, b2-in-06, Shrinker |
| Bit counter: a message and its compressed size side by side, with a "random noise" button that fills the message with random bits and shows the compressor failing to shrink it. | Bit counter | b2-in-07, b2-in-12 |
| Interval strip: the line from 0 to 1, cut by the model's probabilities for each next letter, zooming into the chosen slice. Width of the final slice and its bits shown live. | new picture, inside Guess-the-message game | b2-in-08 |
| Information circles: two overlapping circles whose areas are H(X) and H(Y), the overlap I(X; Y), drawn from a live joint table the learner edits: 2 × 2 in Play, and up to 4 × 4 (4 × 2 or 4 × 4) for Work it. | new picture, inside Surprise meter | b2-in-10 |
| Error-fix lab: a 7-cell Hamming board (positions 1 to 7, parity cells marked), tap to flip any bit, three parity circles light up, the syndrome reads out as a binary number pointing at the bad cell. Also a repetition mode and a noise slider f with a live failure rate. | Error-fix lab | b2-in-11, b2-in-12 |
| Shrinker panel: one strip showing message → counts → code → bits → armor → received → decoded, with sizes at every stage. | the build | b2-in-04, b2-in-06, b2-in-08, b2-in-09, b2-in-11, b2-in-12 |

---

## Unit 1 · Surprise

### b2-in-01 · Bits are yes/no questions
- **You can:** count how many yes/no questions it takes to pin down one choice out of many.
- **Needs:** `g11-log`.
- **Tool:** ★ Guess-the-message game (number mode), scientific calculator.
- **Play:** Think of a number from 1 to N and drag N from 2 to 1,024. The game asks "is it in the top half?" until it lands, drawing each question as a cut through a row of N boxes, and the question tally ticks up.
- **Guess:** "N is 1,000. How many questions does the game need, at most?" Drag a marker on a 1 to 30 strip. The game then runs on the worst-case number and the tally lands on 10.
- **Name it:** Each yes/no answer halves what's left. One answer is one **bit**. Picking one of N equally likely things takes log₂ N bits, and if you must use whole questions, round up. k independent choices from N each take k · log₂ N bits.
  `bits = log₂ N` · `questions = ⌈log₂ N⌉` · `log₂ N = ln N / ln 2`
- **Work it:** N from {4, 8, 16} for index < 3, then from {32, 64, 100, 256, 1,000, 1,024}; a follow-up with alphabet size N ∈ {2, 4, 8, 16, 26, 32} and k ∈ {2, 3, 4, 5} letters; non-powers of 2 only after index 3.
  Steps: 1 **Questions** type ⌈log₂ N⌉ (N = 100 → 7) · 2 **Bits, exact** type log₂ N to 2 decimals (N = 26 → 4.70) · 3 **Bits for k letters** type k · log₂ N (N = 32, k = 3 → 15; N = 26 → 2 decimals).
  Slips: typed N/2 "That's after one question. Keep halving until one is left: that's log₂ N questions." · typed log₁₀ N (2 for N = 100) "Bits use base 2, since each answer splits two ways. log₂ 100 ≈ 6.64, so 7 questions." · typed k + log₂ N "Independent choices multiply the possibilities, N^k, so their bits add: k · log₂ N."
- **Oracle:** `ceil(log2(N))`, `round(log2(N), 2)`, `k * log2(N)`.
- **Use it:** How many bits does one letter of a 26-letter alphabet need with no tricks? Saved as `bits_flat` (4.70), the starting line every Shrinker result is compared to.
- **Deeper:** Why log? Ask for a measure f(N) that adds for independent choices, f(MN) = f(M) + f(N), and grows with N. Any such f is c · log N (Cauchy's functional equation for monotone f). That's Hartley's 1928 measure, and choosing base 2 makes c = 1 bit.

### b2-in-02 · The surprise of one event
- **You can:** turn a probability into bits of surprise.
- **Needs:** b2-in-01, `st-probrules`.
- **Tool:** Surprise meter (surprise bars), scientific calculator.
- **Play:** Drag a probability p from 1 down to 1/1,000. A spinner with a slice of size p spins, and a surprise bar beside it grows as the slice shrinks: slowly at first, then fast.
- **Guess:** "An event with p = 1/2 is 1 bit of surprise. How surprising is p = 1/8?" Drag the surprise bar. The meter fills to 3, and the picture shows 1/8 as three halvings of the spinner.
- **Name it:** Rare things carry more news. The surprise of an outcome with probability p is how many halvings it takes to get from 1 down to p. Surprises of independent events add, because their probabilities multiply.
  `s(p) = log₂(1/p) = −log₂ p` · `s(p · q) = s(p) + s(q)`
- **Work it:** p from {1/2, 1/4, 1/8, 1/16} for index < 3, then {1/32, 1/64, 1/6, 1/10, 3/4}; a pair p, q of powers of 1/2 for the sum step. Non-powers rounded to 2 decimals.
  Steps: 1 **Surprise** type log₂(1/p) (1/16 → 4; 1/6 → 2.58; 3/4 → 0.42) · 2 **Two independent events** type s(p) + s(q) (1/4 and 1/8 → 5) · 3 **Which is more surprising?** tap one of two events shown as fractions.
  Slips: typed a negative number "Surprise is −log₂ p, and log₂ p is negative for p < 1, so the surprise is positive." · typed 1/4 or 16 for the surprise of 1/16 "Count halvings: 1 → 1/2 → 1/4 → 1/8 → 1/16 is four." · multiplied surprises "Probabilities multiply, so surprises add: 2 + 3 = 5."
- **Oracle:** `log2(1/p)`, `log2(1/p) + log2(1/q)`.
- **Use it:** A weather app says 10% chance of rain and it rains. How many bits of news was that? (3.32.) Not saved.
- **Deeper:** Shannon's requirements for a surprise function (depends only on p, continuous, decreasing, adds over independent events) force s(p) = −c log p. The natural log version is measured in nats; 1 nat = 1/ln 2 ≈ 1.443 bits. Machine learning losses are usually in nats.

### b2-in-03 · Entropy: average surprise
- **You can:** compute the entropy of a distribution, the average number of bits it takes.
- **Needs:** b2-in-02, `st-expected`.
- **Tool:** Surprise meter (surprise bars), ★ Guess-the-message game (letter mode).
- **Play:** Drag the heights of up to 8 probability bars. Under each, its surprise bar; across both, a level line at the weighted average. Flatten the bars and the line rises; pile everything on one bar and the line drops to 0.
- **Guess:** "Three outcomes at 1/2, 1/4, 1/4. Where does the average land?" Drag the level line between 0 and 2. It settles at 1.5, with the 1, 2, 2 surprise bars weighted under it.
- **Name it:** **Entropy** is the expected surprise: each outcome's surprise times how often it happens, added up. It's the fewest bits per outcome any code can average. It's largest, log₂ n, when all n outcomes are equally likely, and 0 when one outcome is certain.
  `H(X) = Σ p(x) · log₂(1/p(x))` · `0 ≤ H ≤ log₂ n`
- **Work it:** For index < 3, "dyadic" distributions built from a random binary tree with 3 or 4 leaves, so every p is a power of 1/2: (1/2, 1/4, 1/4) → 1.5, (1/2, 1/4, 1/8, 1/8) → 1.75, (1/4, 1/4, 1/4, 1/4) → 2. Then trees with 5 to 8 leaves (exact decimals, like 1.875 for 1/2, 1/4, 1/8, 1/16, 1/16), then non-dyadic (1/3, 1/3, 1/3) → 1.585 and (0.5, 0.3, 0.2) → 1.485, rounded to 3 decimals.
  Steps: 1 **Surprise of each outcome** a row of boxes · 2 **Weight each** tap "multiply by p" · 3 **Entropy** type the sum · 4 **More or less?** tap which of two shown distributions has the higher entropy.
  Slips: averaged the surprises without weights ((1 + 2 + 2)/3 = 1.67) "Common outcomes happen more often, so they count more. Weight each surprise by its p." · typed Σ p · log₂ p (−1.5) "That sum is negative. Entropy uses log₂(1/p), which flips the sign." · typed log₂ n for an uneven distribution "log₂ n is the maximum, reached only when every outcome is equally likely."
- **Oracle:** `sum(p * log2(1/p))`.
- **Use it:** The entropy of a die roll (2.585) against a 4-sided die (2). Which needs more bits per roll to record a game? Not saved.
- **Deeper:** Prove H ≤ log₂ n with Jensen's inequality (log is concave), or with Gibbs' inequality Σ p log(p/q) ≥ 0 using q uniform. Then the chain rule H(X, Y) = H(X) + H(Y | X), and Khinchin's theorem: entropy is the only measure, up to a constant, that is continuous, maxed by the uniform distribution, and obeys the chain rule.

### b2-in-04 · The loaded coin
- **You can:** read the entropy of a two-way choice off its curve, and say how many bits n flips need.
- **Needs:** b2-in-03.
- **Tool:** Surprise meter (entropy curve), Grapher 2D.
- **Play:** Drag a coin's chance of heads p from 0 to 1. The coin flips live, a running "bits per flip" tally settles, and a dot rides the entropy curve: 1 at p = 1/2, falling to 0 at both ends (where 0 · log₂(1/0) counts as 0).
- **Guess:** "At p = 0.9 the coin lands heads 9 times in 10. How many bits per flip: about 0.1, 0.5 or 0.9?" Pick one. The curve answers 0.469, and the tally from 200 live flips lands near it.
- **Name it:** A coin with heads chance p has entropy H(p). It's symmetric (p and 1 − p give the same value), it's 1 bit only for a fair coin, and a loaded coin can be recorded in fewer bits per flip. Long runs of n flips need about n · H(p) bits.
  `H(p) = p log₂(1/p) + (1 − p) log₂(1/(1 − p))`
- **Work it:** p from {1/2, 1/4, 3/4} for index < 3, then {1/8, 0.1, 0.2, 0.9, 0.8, 7/8}; n from {100, 1,000}. Answers to 3 decimals; bits for n flips rounded to the nearest whole bit.
  Steps: 1 **Surprise of heads** log₂(1/p) · 2 **Surprise of tails** log₂(1/(1 − p)) · 3 **H(p)** (1/4 → 0.811; 1/8 → 0.544; 0.1 → 0.469; 0.2 → 0.722) · 4 **Bits for n flips** n · H(p) (1,000 flips at 0.1 → 469).
  Slips: H(0.9) typed differently from H(0.1) "Swap heads and tails: the surprise is the same. H(p) = H(1 − p)." · typed only p · log₂(1/p) "That's only the heads part. Add the tails part, weighted by 1 − p." · typed 1 for any p "A loaded coin is more predictable, so it carries less than 1 bit per flip."
- **Oracle:** `p*log2(1/p) + (1-p)*log2(1/(1-p))`.
- **Use it:** **Project: Your surprise profile.** Type a sentence; Bento counts its letters and spaces and computes entropy per letter. Saved as `H_msg` and `counts_msg`. This is the Shrinker's target line.
- **Deeper:** The asymptotic equipartition property. Of the 2ⁿ sequences of n flips, almost all the probability sits on about 2^(n·H(p)) "typical" ones, each with probability about 2^(−n·H(p)). The counting version: C(n, pn) ≈ 2^(n·H(p)), from Stirling's formula. This is the engine of Shannon's source coding theorem (b2-in-07).

## Unit 2 · Codes that shrink

### b2-in-05 · Codes you can read without commas
- **You can:** tell whether a set of code lengths can work, and decode a prefix code.
- **Needs:** b2-in-01.
- **Tool:** Code builder (free mode).
- **Play:** Type codewords for four letters (like 0, 10, 110, 111) and send a bit string through. Each codeword is a leaf on a binary tree, and the tree shows the space it uses up. Make one codeword the start of another and the reader stalls on a fork.
- **Guess:** "Can 4 letters have codewords of lengths 1, 1, 2 and 2?" Tap yes or no. The tree tries to place them and runs out of room after the two 1-bit leaves.
- **Name it:** A **prefix code** never uses one codeword as the start of another, so a reader can split a bit stream with no commas. A codeword of length ℓ uses up 2^(−ℓ) of the tree. Lengths fit exactly when those shares add to at most 1: the **Kraft inequality**.
  `Σ 2^(−ℓᵢ) ≤ 1`
- **Work it:** 3 to 6 lengths from 1 to 5 (index < 3: 3 or 4 lengths from 1 to 3); a fixed code A = 0, B = 10, C = 110, D = 111 (and variants with letters shuffled) for decoding strings of 8 to 14 bits.
  Steps: 1 **Kraft sum** type as a fraction ({1, 2, 3, 3} → 1; {2, 2, 3} → 5/8; {1, 1, 2} → 5/4) · 2 **Possible?** tap yes / no · 3 **Decode** tap the letters in order (0110100111 → A C B A D).
  Slips: summed the lengths "Each length ℓ uses a share 2^(−ℓ) of the tree, not ℓ. Add 1/2 + 1/4 + …" · said yes to a sum above 1 "Above 1 means the leaves need more room than the tree has. No prefix code fits." · tapped B where the bits read 110 (stopped at 11 and called it B) "B is 10, and 11 isn't a codeword. Read left to right and stop at the first full codeword: 1, 11, 110 is C."
- **Oracle:** `sum(2**-l)`, `<= 1`, greedy prefix decode.
- **Use it:** Type codeword lengths for the four most common letters in your sentence and test them with Kraft: try 1, 2, 3, 3, then Morse-like 1, 1, 2, 2 (the sum is 3/2, so no prefix code fits). Not saved.
- **Deeper:** McMillan's theorem: every uniquely decodable code (not only prefix codes) obeys Kraft. Proof: raise the Kraft sum to the k-th power, count the strings of each length it can hit, and let k → ∞. So prefix codes lose nothing.

### b2-in-06 · Huffman's tree: short codes for common letters
- **You can:** build the shortest prefix code for a set of letter counts.
- **Needs:** b2-in-05, b2-in-03.
- **Tool:** Code builder, Notebook.
- **Play:** Drag letter tiles with counts onto the bench. Tap "merge" and the two lightest tiles join under a new node with their total; repeat until one tree remains. The message below re-encodes live as a bit strip that shortens with each merge.
- **Guess:** "Counts 8, 4, 2, 2 on 16 letters. A plain code uses 2 bits each, 32 bits total. How many bits will the Huffman code use?" Drag a marker on the bit strip. It shrinks to 28.
- **Name it:** **Huffman's rule:** keep merging the two lightest groups. Each merge adds one bit to every letter inside it, so the total length is the sum of the merged weights. No prefix code does better for those counts. When every probability is a power of 1/2, the average length equals the entropy exactly.
  `total bits = Σ count × length = sum of all merged weights` · `H ≤ average length < H + 1`
- **Work it:** 4 letters with dyadic counts for index < 3 (8, 4, 2, 2 → 28 bits; 4, 2, 1, 1 → 14 bits), then 5 or 6 letters with counts from 1 to 20 (5, 2, 1, 1, 1 → 20 bits; 16, 8, 4, 2, 1 → 56 bits). The generator rejects count sets where a tie would change any single letter's length when step 2 is asked; total bits is tie-proof and always asked.
  Steps: 1 **First merge** tap the two lightest tiles · 2 **Length of letter X** type its depth (in 16, 8, 4, 2, 1: the 1-count letter → 4) · 3 **Total bits** type (5, 2, 1, 1, 1 → 2 + 3 + 5 + 10 = 20) · 4 **Bits per letter** total / message length (letters in the message) to 2 decimals (20/10 → 2.00; 56/31 → 1.81) · 5 **Fixed-length size** ⌈log₂(letters in the alphabet)⌉ × message length, for comparison (5 different letters, message of 10 → 3 × 10 = 30).
  Slips: merged the two heaviest "Merge the two lightest. Rare letters should end up deep in the tree, with long codes." · gave the common letter the longest code "Depth is length. The common letter merges last, so it sits near the top with a short code." · total = sum of counts "Each letter costs count × length bits, not count × 1."
- **Oracle:** heap-based Huffman: total = sum of merged weights; lengths from tree depth.
- **Use it:** **Project: Your first code.** Build the Huffman code for `counts_msg`. Bento shows the code table, shrunk size, and bits per letter against `H_msg` and 8. Saved as `code_msg`. This is Shrinker v1.
- **Deeper:** The exchange-argument proof that Huffman is optimal: in some optimal tree the two rarest letters are siblings at the deepest level, and merging them reduces to a smaller problem. Then canonical Huffman codes (send only the lengths), and why block coding (pairs of letters) pushes the overhead from < 1 bit per letter to < 1/k.

### b2-in-07 · What can't shrink
- **You can:** explain why no compressor shrinks every file, and say how close a code is to the entropy floor.
- **Needs:** b2-in-06, b2-in-04.
- **Tool:** Bit counter, Code builder.
- **Play:** Load a sentence into the bit counter and compress it: the bar shrinks. Tap "random noise" to replace it with random bits of the same length and compress again: the bar doesn't move, or grows a little. Drag the noise source's bias from 1/2 toward 0 and the bar shrinks again as the bits become predictable.
- **Guess:** "Of all 20-bit files, what share can any compressor shrink by 8 bits or more?" Drag a slider from 0% to 100%. The counter lays out every shorter string as boxes next to the 2²⁰ files, and the answer shows as under 1/128 (less than 0.8%).
- **Name it:** There are 2ⁿ files of n bits but only 2ⁿ − 1 shorter strings, so some file never shrinks, and only a tiny share can shrink much. Compression works by spending fewer bits on likely messages and more on unlikely ones. **Shannon's source coding theorem:** no code beats H bits per letter on average, and codes can get within 1 bit (within 1/k bits using blocks of k letters).
  `#(strings shorter than n) = 2ⁿ − 1` · `share shrinkable by ≥ k bits < 2^(1 − k)` · `H ≤ L < H + 1`
- **Work it:** n from {3, 4, 8, 10} for index < 3, then {16, 20, 32}; k from 2 to 10 with k < n; Huffman results from b2-in-06 for the efficiency step: H is shown to 3 decimals and L to 2, and the answer is the shown H divided by the shown L, to 3 decimals. The generator rejects count sets where the shown H / L sits within 0.00005 of a rounding tie, and the answer also accepts ±0.001.
  Steps: 1 **Files of length n** type 2ⁿ (n = 4 → 16) · 2 **Strings shorter than n** type 2ⁿ − 1 (counting the empty string; n = 4 → 15) · 3 **Bound on the share shrinkable by k** type as a fraction 1/2^(k − 1) (k = 8 → 1/128) · 4 **Efficiency** H / L (counts 3, 3, 2, 1, 1: 2.171 / 2.20 → 0.987) · 5 **Possible?** tap which average lengths L could belong to an optimal code for a given H (H = 1.75: 1.75 yes, 2.8 no, 1.6 no).
  Slips: typed 2ⁿ⁻¹ for step 2 "Add every shorter length: 1 + 2 + 4 + … + 2ⁿ⁻¹ = 2ⁿ − 1." · picked L below H "No code averages fewer bits than the entropy. L ≥ H always." · thought random noise can shrink "Random bits are already as surprising as they can be: H = 1 bit per bit."
- **Oracle:** `2**n`, `2**n - 1`, `Fraction(1, 2**(k-1))`, `round(round(H, 3) / round(L, 2), 3)`, with H recomputed from the counts and L from a heap Huffman.
- **Use it:** Run the Bit counter on your sentence and on a random string of the same length. Your sentence shrinks toward `H_msg`; the noise doesn't. Not saved.
- **Deeper:** The proof of the source coding theorem through typical sets (b2-in-04 Deeper): index only the ~2^(nH) typical sequences. Then **Kolmogorov complexity** K(x), the length of the shortest program that prints x: most strings have K(x) ≥ |x| − c (incompressible), and K itself can't be computed (see `cs` b2-cs-14).

### b2-in-08 · Compression is prediction
- **You can:** count the bits an ideal coder spends on a message from a model's predictions.
- **Needs:** b2-in-07.
- **Tool:** ★ Guess-the-message game (model mode), interval strip.
- **Play:** A model reads your message one letter at a time and shows a probability bar for what comes next. The interval strip from 0 to 1 zooms into the slice of the letter that actually came; the slice's width and its bits update live. Switch the model from "letters alone" to "letter after the last one" and watch the bits fall.
- **Guess:** "After a q, the model gives u a probability of 0.98. How many bits does the u cost?" Pick: about 0, about 1, or about 5. The strip barely narrows: 0.03 bits.
- **Name it:** A coder that knows the model's probabilities can spend log₂(1/p) bits on each letter, where p is what the model gave the letter that came. **Arithmetic coding** does this by narrowing an interval: the final width is the product of the probabilities, and its bits are log₂(1/width). Better predictions mean fewer bits, so compressing and predicting are the same skill. Context helps: H(next | previous) ≤ H(next).
  `bits = Σ log₂(1/p(xᵢ | context))` · `width = Π p(xᵢ | context)`
- **Work it:** Messages of 4 to 6 letters; model probabilities from {1/2, 1/4, 1/8, 1/16} for index < 3, then any fraction from a table (rounded to 2 decimals); a flat model of 1/4 per letter for comparison.
  Steps: 1 **Bits per letter** a row of boxes (1/2, 1/4, 1/2, 1/8 → 1, 2, 1, 3) · 2 **Total bits** type (7) · 3 **Final interval width** type as a fraction (1/128) · 4 **Saved against the flat model** type flat − model (8 − 7 → 1); it can be negative, and then Bento says "This model is worse than guessing evenly."
  Slips: multiplied the bits "Probabilities multiply; bits add." · used the probability of the most likely letter instead of the one that came "You pay for what actually happened. Use p of the true next letter, even when the model liked another one more." · typed the width as a whole number "The width is a slice of [0, 1], so it's the product of fractions: 1/2 × 1/4 × 1/2 × 1/8."
- **Oracle:** `sum(log2(1/p))`, `prod(p)`.
- **Use it:** **Project: Predict me.** Train a one-letter-context model on your sentence, then play the guessing game against it. Bits per letter drop below `H_msg`. Saved as `model_msg`. This is Shrinker v2.
- **Deeper:** Entropy rate of a Markov source, lim H(Xₙ | Xₙ₋₁, …, X₁). Shannon's 1951 guessing experiment put English at roughly 0.6 to 1.3 bits per letter. Prediction by partial matching, and why a better language model is a better compressor (and the other way round). Finite precision arithmetic coding with renormalization.

## Unit 3 · Learning and noise

### b2-in-09 · Cross-entropy: scoring a model in bits
- **You can:** score a model's predictions with cross-entropy and read the extra bits it wastes.
- **Needs:** b2-in-08.
- **Tool:** Surprise meter, Grapher 2D.
- **Play:** Two rows of bars: the truth p (fixed by the data) and the model q (you drag; each q bar stops at 0.01, so the meter stays finite). The meter shows cross-entropy H(p, q) as bits per outcome, with the floor H(p) drawn as a line. Drag q toward p and the meter drops onto the floor; drag it away and the gap reopens.
- **Guess:** "The truth is (1/2, 1/4, 1/8, 1/8). The model guesses all four equally. Where's the meter: 1.75, 2 or 2.25 bits?" Tap one. It lands on 2, with the floor at 1.75 and the gap 0.25 shaded.
- **Name it:** **Cross-entropy** is the average surprise of the truth when you code with a model's probabilities: H(p, q). It's never below H(p), and the gap is the **KL divergence**, the bits wasted by believing q when the world is p. Training a language model means lowering this number, letter by letter.
  `H(p, q) = Σ p(x) log₂(1/q(x))` · `D(p ‖ q) = H(p, q) − H(p) ≥ 0`
- **Work it:** Dyadic p and q over 3 or 4 outcomes so all answers are exact (index < 3: 4 outcomes, q uniform at 1/4 each; the 3-outcome case uses a dyadic q such as (1/2, 1/4, 1/4)); later, a sequence of 4 to 6 true labels with the model's probability for each, giving training loss as average −log₂ q (2 decimals).
  Steps: 1 **H(p)** (1.75) · 2 **H(p, q)** (q uniform over 4 → 2) · 3 **KL divergence** (0.25) · 4 **Average loss on a batch** (model gave the true labels 1/2, 1/4, 1/2, 1 → (1 + 2 + 1 + 0)/4 = 1).
  Slips: swapped p and q (typed 2.25 using H(q, p) on the example where q = uniform) "Weight by how often things really happen, p, and take the surprise from the model, q." · typed a negative KL "KL can't be negative. Coding with the wrong model never beats coding with the right one." · averaged q instead of −log₂ q "Loss is surprise, −log₂ q, averaged, not q itself."
- **Oracle:** `sum(p*log2(1/q))`, `H(p,q) - H(p)`.
- **Use it:** Score `model_msg` on your sentence: its cross-entropy in bits per letter. This is the Shrinker's honesty check. Saved as `xent_msg`. Links forward to b2-ai-07 (training loss) and back to b2-pr-09 (likelihood).
- **Deeper:** Gibbs' inequality D(p ‖ q) ≥ 0 from ln x ≤ x − 1, with equality only at q = p. Minimizing cross-entropy on data is the same as maximizing likelihood. KL isn't symmetric and isn't a distance; forward vs reverse KL and what each does to a fitted model (mode-covering vs mode-seeking). Fisher information as the curvature of KL near q = p.

### b2-in-10 · Mutual information: what one thing tells you about another
- **You can:** measure how many bits one variable tells you about another.
- **Needs:** b2-in-09.
- **Tool:** Surprise meter (information circles), Matrix pad.
- **Play:** Edit a 2 × 2 joint probability table by dragging its cells. Two overlapping circles redraw live with areas H(X) and H(Y); the overlap is what they share. Make the table diagonal and the circles merge; make the rows proportional and they pull apart. An empty cell adds nothing (0 · log₂(1/0) counts as 0).
- **Guess:** "X is a fair bit and Y is a perfect copy of X. How big is the overlap?" Drag it from 0 to 2. The circles coincide at 1 bit.
- **Name it:** **Mutual information** I(X; Y) is how much knowing Y cuts the uncertainty about X. It's symmetric, it's 0 exactly when X and Y are independent, and it's at most the smaller entropy.
  `I(X; Y) = H(X) − H(X | Y) = H(X) + H(Y) − H(X, Y)`
- **Work it:** For index < 3, independent tables (I = 0) or Y = X (I = H(X)) with dyadic margins; then X uniform over 4 values (2 bits) with Y revealing b ∈ {1, 2} of its bits (I = b; a 4 × 2 or 4 × 4 table); then general 2 × 2 tables with dyadic cells, rounded to 3 decimals.
  Steps: 1 **H(X)** from the row sums · 2 **H(Y)** from the column sums · 3 **H(X, Y)** from the cells · 4 **I(X; Y)** (cells 1/2, 0, 1/4, 1/4: 1 + 0.811 − 1.5 → 0.311).
  Slips: I = H(X, Y) − H(X) "That's H(Y | X), what's left of Y after knowing X. Mutual information is the shared part: H(X) + H(Y) − H(X, Y)." · got a negative I "Shared information can't be negative. Check H(X, Y): it's never more than H(X) + H(Y)." · read row sums as cells "H(X) uses the row totals, not the four cells."
- **Oracle:** `H(rows) + H(cols) - H(cells)`.
- **Use it:** How much does the previous letter tell you about the next one in your sentence? Bento prints I(previous; next) = H(next) − H(next | previous) for it, in bits; read it off. That's exactly what `model_msg` exploits. Not saved.
- **Deeper:** The data-processing inequality: if X → Y → Z is a chain, I(X; Z) ≤ I(X; Y), so no processing of data creates information about the source. Conditional mutual information and the chain rule. The information bottleneck view of learning (links to `ai`), and I(X; Y) as the KL divergence between the joint and the product of the marginals.

### b2-in-11 · Codes that fix their own errors
- **You can:** find and fix a flipped bit with a Hamming code.
- **Needs:** b2-in-04, `cs` b2-cs-04 (XOR) helps.
- **Tool:** Error-fix lab, Logic gate board.
- **Play:** A 7-cell board holds a codeword, with three parity circles drawn over it. Tap any cell to flip it: the circles that now hold an odd number of 1s light up, and together they point at the flipped cell. Switch to repetition mode and drag the noise level f to see how often triple copies fail.
- **Guess:** "Cell 5 gets flipped. Which parity circles light up?" Tap the circles. The lab lights circles 1 and 4, because 5 = 4 + 1 in binary (101).
- **Name it:** Add redundancy cleverly and a code can repair noise. **Hamming (7, 4)** puts check bits at positions 1, 2 and 4, each covering the positions whose binary form has that bit set. XOR together the positions of all the 1s (the **syndrome**): 0 means no error, anything else is the position of the flipped bit. It sends 4 data bits in 7, a rate of 4/7; triple repetition only manages 1/3. For a channel that flips each bit with chance f, no code can send more than its capacity, 1 − H(f) bits per bit.
  `syndrome = XOR of the positions holding a 1` · `repetition fails with chance 3f²(1 − f) + f³` · `capacity = 1 − H(f)`
- **Work it:** For index < 3, triple repetition: decode 3 received copies of a 4-bit message by majority vote; then a valid Hamming codeword (positions of 1s XOR to 0) with one random position e from 1 to 7 flipped; later, failure rate for f ∈ {0.1, 0.2} (3 decimals) and capacity 1 − H(f) for f ∈ {1/4, 0.1} (3 decimals).
  Repetition steps (index < 3): R1 **Majority bit at each position** 4 taps (copies 1011, 1001, 0011 → 1, 0, 1, 1) · R2 **Decoded message** type 4 bits (1011).
  Hamming steps: 1 **Positions holding a 1** tap them (1110100 → 1, 2, 3, 5) · 2 **Syndrome** type the XOR as a number from 0 to 7 (1 ⊕ 2 ⊕ 3 ⊕ 5 = 5) · 3 **Fixed word** type 7 bits (1110000) · 4 (later) **Repetition failure** (f = 0.1 → 0.028) · 5 (later) **Capacity** (f = 0.1 → 0.531; f = 1/4 → 0.189).
  Slips: took the first copy as the message "One copy can hold the flipped bit. At each position take the bit at least two of the three copies agree on." · added positions (11) "Add in binary with no carries: that's XOR. 1 ⊕ 2 ⊕ 3 ⊕ 5 = 5." · flipped the syndrome bit's neighbor "The syndrome is the position itself, counting from 1 on the left." · repetition failure as f³ only "Two flips out of three also fool the majority: add 3f²(1 − f)."
- **Oracle:** `reduce(xor, positions_of_ones)`, `3*f**2*(1-f) + f**3`, `1 - H(f)`.
- **Use it:** Wrap the Shrinker's output in Hamming (7, 4) blocks. Shelf name `armor` stores the rate 4/7 and the protected size. Shrinker v3.
- **Deeper:** Shannon's noisy-channel coding theorem: below capacity C = max I(X; Y), error rates can go to 0 at a fixed rate; above it, they can't. The Hamming bound and perfect codes; Hamming (7, 4) as a linear code with a 3 × 7 parity-check matrix (links to `la`). Modern codes that approach capacity: LDPC, turbo and polar codes; Reed-Solomon on CDs and QR codes. Quantum error correction picks this up in `qu`.

### b2-in-12 · The Shrinker, end to end
- **You can:** run a message through a full compress, protect and decode pipeline and account for every bit.
- **Needs:** b2-in-06, b2-in-08, b2-in-09, b2-in-11.
- **Tool:** Shrinker panel, Bit counter, ★ Guess-the-message game.
- **Play:** Paste a message. The Shrinker strip shows each stage's size: 8 bits per letter raw, then Huffman, then the context model, then the armor. Drag a noise slider to flip random bits on the way and watch the decoder repair them (or fail when two land in one block).
- **Guess:** "Your message is 400 letters and shrinks to 900 bits. After Hamming armor, is it still smaller than the raw 3,200 bits?" Tap yes or no, then drag where the armored bar lands. It lands at 1,575.
- **Name it:** A real compressor is a model plus a coder: the model predicts, the coder spends log₂(1/p) bits on what came, and its bits per letter are the model's cross-entropy on the message. Protection then spends some bits back to survive noise. Compression and protection pull in opposite directions; Shannon showed they can be designed separately without loss.
  `bits per letter = compressed bits / letters` · `ratio = raw bits / compressed bits` · `armored = ⌈compressed / 4⌉ × 7`
- **Work it:** N letters from {100, 200, 400, 1,000}, compressed sizes S from 1.5N to 4N bits in multiples of 4 (index < 3: N = 100, sizes multiples of 100); `H_msg` = S/N + 0.50..2.00 (2 decimals), so the gain from context is always positive. Decimals to 2 places.
  Steps: 1 **Raw bits** 8N (3,200) · 2 **Bits per letter** (900/400 → 2.25) · 3 **Ratio** (3,200/900 → 3.56) · 4 **Armored size** (900/4 = 225 blocks × 7 → 1,575) · 5 **Gain from context** type `H_msg` minus the model's bits per letter, with `H_msg` given (4.10 − 2.25 → 1.85)
  Slips: ratio flipped (0.28) "Ratio is raw over compressed. Above 1 means it shrank." · armored as compressed × 4/7 "Armor adds bits: 4 data bits become 7, so multiply by 7/4." · forgot 8 bits per raw letter "Plain text stores each letter in 8 bits (one byte)."
- **Oracle:** `8*N`, `S/N`, `8*N/S`, `ceil(S/4)*7`, `H_msg - S/N`.
- **Use it:** **Project: The Shrinker.** Run your own message end to end: raw, `code_msg`, `model_msg`, `armor`, received with noise, decoded. The panel saves the full ledger (`H_msg`, `xent_msg`, final bits per letter) to the Notebook. Build complete.
- **Deeper:** Universal compression (Lempel-Ziv) approaches the entropy rate of any stationary source without knowing its model. Minimum description length and Solomonoff induction: the best explanation is the shortest program, which ties learning to Kolmogorov complexity, and why that ideal is uncomputable (`cs` b2-cs-14). Rate-distortion theory for lossy compression, where the payoff is a curve of bits against error (links to b2-la-20, the image compressor).
