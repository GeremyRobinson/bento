# Bento² · Probability and statistics (track `pr`, 20 lessons)

**What it is:** the math of chance and data: how likely things are, how to tell a real effect from luck, and how sure you can be from a sample.

**Role:** spine, track 2. **Needs:** 12th grade. From Bento, AP Statistics helps most (`st-probrules`, `st-expected`, `st-binomial`, `st-normal`, `st-sampdist`, `st-testprop`, `st-lsrl`), plus `g7-prob` and `g6-mean`. Nothing is locked.

**Not repeated here.** AP Statistics (`specs/wave2/ap-stats.md`) already teaches describing data, z-scores, the binomial and geometric distributions, two-way tables, one- and two-sample z and t procedures, chi-square and the regression slope test. This track starts where those stop: it asks why the tools work, what they miss, and how to avoid being fooled by luck. When a lesson needs an AP idea, "Needs" points at the `st-` lesson for a refresher.

## The build: the Luck detector

One screen that takes an experiment (two versions of something, and what happened) and gives an honest verdict: how big the effect is, how sure you can be, and how likely it is to be luck. The learner can feed it made-up experiments with a hidden truth and see, run after run, how often its calls hold up. Each unit adds a part:

| Unit | What it adds to the Luck detector |
|---|---|
| 1. Chance machines | **The null world.** A simulator that replays the experiment with no real effect, the 1/√n rule for how noisy any average is, and the Bayes box for base rates (`mcN`, `pairs`, `varAvg`, `ppv`). |
| 2. Shapes of chance | **The yardsticks.** Poisson for rare counts, the normal curve for sums and averages (via the central limit theorem), and correlation for paired measures (`lambda`, `halfLife`, `zSum`, `rho`). |
| 3. Learning from data | **The estimate with error bars.** The best-fit value (maximum likelihood), its bias and spread, a bootstrap interval and a Bayesian posterior (`lamHat`, `mse`, `bootSE`, `postMean`). |
| 4. Luck or real? | **The verdict engine.** An exact shuffle test, a power check before running, a correction for many looks, and the chance the effect is real given how often ideas pan out (`pPerm`, `nNeeded`, `fdrCut`, `fdrField`). |
| 5. Traps and the verdict | **The alarms and the final bench.** Warnings for regression to the mean, confounding and streaks, then the full pipeline on an A/B test (`rtmShrink`, `adjRate`, `piA`, `luckDetector`). |

## Units

1. **Chance machines** (pr-01 to pr-04): the law of large numbers, expectation by indicators, variance of sums, Bayes' rule.
2. **Shapes of chance** (pr-05 to pr-08): the Poisson count, densities and the exponential wait, the central limit theorem, correlation and best prediction.
3. **Learning from data** (pr-09 to pr-12): maximum likelihood, bias and variance, the bootstrap, Bayesian updating.
4. **Luck or real?** (pr-13 to pr-16): the shuffle test, power, many tests, evidence and Bayes factors.
5. **Traps and the verdict** (pr-17 to pr-20): regression to the mean, Simpson's paradox, random walks and Markov chains, the Luck detector.

## Small projects

- **After pr-04: A screening card.** Pick a made-up condition, set how rare it is and how good the test is, and the Bayes box draws 10,000 people. The card shows what a positive result really means in one sentence the learner writes. Saved as `ppv`. This is the Luck detector's base-rate dial.
- **After pr-08: The sum machine.** Draw any shape of chance (a lopsided spinner, a two-humped one), add n copies, and watch the total turn into a bell on the Galton board beside it. The card reports the mean, the SD and the 1-in-100 cutoff. Saved as `zSum`. This is the Luck detector's yardstick.
- **After pr-12: Honest error bars.** One made-up data set, three answers side by side: the maximum likelihood estimate, a bootstrap interval and a Bayesian credible interval, with a note on where they agree. Saved as `bootSE` and `postMean`. This is Luck detector v1: an estimate that knows its own wobble.
- **After pr-16: Loaded-coin court.** A coin is accused of being loaded. The learner sets the plan (how many flips, which test), runs it, and returns a verdict with a p-value, a Bayes factor and the chance it is really loaded given a stated prior. Bento reveals the hidden truth. This is Luck detector v2.
- **After pr-20: The Luck detector.** The full build, kept in the Notebook (`luckDetector`): plan, run, test, correct, estimate and weigh, on any two-version experiment.

## Tables built into the track

The track shares one small normal table (the Distribution lab can show it): upper-tail areas P(Z > z) for z = 0: 0.5000, 0.5: 0.3085, 0.84: 0.2005, 1: 0.1587, 1.28: 0.1003, 1.5: 0.0668, 1.645: 0.0500, 1.96: 0.0250, 2: 0.0228, 2.33: 0.0099, 2.5: 0.0062, 2.576: 0.0050, 3: 0.0013. Negative z uses symmetry: P(Z > −z) = 1 − P(Z > z). Every Work-it problem that needs a normal area is built so its z is on this list. Decimal answers accept ±1 in the last stated place unless a lesson says otherwise. All data sets and scenarios are generated and labeled as made up; no real survey or medical data is presented as genuine.

## New for Development

| What | Toolbox name | Used in |
|---|---|---|
| ★ Simulator, expanded: (a) running-average line with a shaded ±2σ/√n band that narrows live; (b) a "letters into envelopes" shuffler that counts matches; (c) an event rain on a time strip (random arrivals at rate λ) with counts per window; (d) a random-walk mode (running total of ±1 steps) with a longest-streak counter; (e) a two- or three-state Markov board where a token hops by the transition chances and long-run shares draw as bars; (f) a "null world" replay button that reruns any experiment with no real effect. | Simulator | pr-01, pr-02, pr-05, pr-15, pr-19, pr-20; shared with `ai`, `qu` |
| Distribution lab, expanded: exponential, Beta and a free density sketcher (drag handles; the curve is rescaled so its area stays 1); a "you already waited t" button that cuts and rescales the tail; the shared normal table. | Distribution lab | pr-05, pr-06, pr-07, pr-12, pr-14 |
| Joint cloud: a bivariate normal scatter with draggable σx, σy and ρ, its covariance ellipse, and a vertical slice at any x showing the slice's mean (the regression line) against the ellipse's long axis. | new picture, inside Distribution lab | pr-03, pr-08, pr-17; shared with `la` |
| Sample machine, expanded: draw any population, then (a) sample means of size n against a normal overlay; (b) variance estimates divided by n and by n − 1 with running averages; (c) resample-with-replacement (bootstrap) mode that stacks each resample's statistic on a dot plot. | Sample machine | pr-07, pr-10, pr-11 |
| Galton board with a "piece shape" setting so each peg can push by a lopsided amount (sums of any distribution). | Galton board | pr-07, project 2 |
| Bayes box, expanded: (a) people mode (10,000 dots split by condition and test); (b) ideas mode (1,000 tested ideas split by real or not and significant or not); (c) a "test again" button that makes the posterior the new prior. | Bayes box | pr-04, pr-16, pr-20 |
| Likelihood viewer: data in, the likelihood curve over the parameter (coin p, Poisson λ, exponential rate) with a draggable marker, a log switch, and a second marker for a likelihood ratio. | new tool | pr-09, pr-16; shared with `in`, `ai` |
| Beta updater: a prior curve with draggable a and b, flips fed one at a time, posterior redrawn with its mean and a shaded 95% credible band. | new picture, inside Distribution lab | pr-12, project 3 |
| Shuffle bench: two groups of value chips; shuffle the labels once, many times, or list every split; each split's difference drops onto a dot plot with the observed line and the "at least as extreme" share. | new tool, inside Data table | pr-13, pr-20 |
| Power bells: the null and alternative curves with the cutoff line; drag δ, σ, n and α to see the α area and the power area change, plus a power curve against n. | new picture, inside Distribution lab | pr-14, pr-20 |
| P-value wall: m tests run in the null world as a row of bars, with lines for α, Bonferroni α/m and the Benjamini–Hochberg staircase; a "peek every 10" mode. | new picture, inside Simulator | pr-15, pr-20 |
| Evidence walk: a running log likelihood ratio drawn as a walk, with stop lines above and below (the sequential test). | new picture, inside Likelihood viewer | pr-16, pr-19; shared with `in` |
| Retest pair: score = skill + luck for two tests, a slider for the skill share, a "pick the top 10%" brush on test 1, and their test 2 results shown beside. | new picture, inside Data table | pr-17 |
| Simpson table: a treatment × group × outcome table with sliders for group mix, the overall and within-group rates as bars that can flip, and a small arrow diagram (group → treatment, group → outcome). | new picture, inside Data table | pr-18; shared with `cs` (graphs) |
| Luck detector bench: one strip, plan → run → test → correct → estimate → weigh, each stage editable, with a "reveal the truth" button and a calibration picture of the detector's own calls against hidden truths (for example, of the calls it made at 80% sure, how many held up), drawn as dots, never as a number or percent about the learner. | the build | pr-04, pr-08, pr-12, pr-16, pr-20 |

Rules for every generator in this track:
- **Signed coefficients.** Any generated coefficient or term that can be negative (β in pr-03, ρ in pr-08, z₁ and ρ in pr-17) is rendered through the sign helper, so the screen shows "αX − 2Y" or "100 − 4", never a plus sign followed by a minus sign, and never a coefficient of 1.
- **Slip placeholders** name a value the generator has already computed (`pairs`, `spots`, `healthy`, `positives`, `sdProduct`, `splits`, `cutoff`), never an expression, so `${…}` always evaluates.

---

## Unit 1 · Chance machines

### b2-pr-01 · The law of large numbers and the 1/√n rule
- **You can:** say how many trials it takes to make a simulated average as precise as you need.
- **Needs:** `g6-mean`, `st-sampdist`.
- **Tool:** ★ Simulator (running-average mode), scientific calculator.
- **Play:** Set a coin's chance of heads p with a slider and run 1, 100 or 100,000 flips. The running share of heads wobbles, then flattens onto p, and a shaded band around p (±2σ/√n) narrows as n grows.
- **Guess:** "After 100 flips, the average typically lands within about 0.10 of the truth. How many flips to land within 0.05?" Pick 150, 200, 400 or 1,000. The simulator runs to 400 and the band's half-width reads 0.05.
- **Name it:** The average of n independent tries settles on the expected value. That's the **law of large numbers**. Its typical error shrinks like 1/√n, so halving the error costs four times the trials. Using random trials to compute something is a **Monte Carlo** estimate.
  `X̄ₙ → μ` · `SD(X̄ₙ) = σ / √n` · `trials for error e = (σ / e)²`
- **Work it:** Error e₀ at n₀ trials with n₀ ∈ {100, 200, 400, 500} and e₀ ∈ {0.10, 0.08, 0.06, 0.05, 0.04}; a factor k ∈ {2, 4, 5, 10} (index < 3: k = 2 and n₀ = 100); a target factor m ∈ {2, 3, 4, 5, 10}, m ≠ k. Later problems (index ≥ 4) add a fair coin, σ = 0.5, with n ∈ {100, 400, 2,500, 10,000}.
  1. **Error at n₀ · k² trials** type e₀/k (e₀ = 0.06, k = 4 → 0.015)
  2. **Trials to cut the error by m** type n₀ · m² (n₀ = 200, m = 3 → 1,800)
  3. (later) **Typical error for a fair coin** type 0.5/√n (n = 2,500 → 0.01).
  Slips: typed e₀/k² "The error falls like 1/√n, not 1/n. Multiplying the trials by k² only divides the error by k." · typed n₀ · m "Halving the error takes 4 times the trials, not 2. To cut it by m, multiply the trials by m²." · typed 0.5/n "Divide by √n: √2,500 = 50, so the error is 0.5/50 = 0.01."
- **Oracle:** `e0 / k`, `n0 * m ** 2`, `0.5 / sqrt(n)`.
- **Use it:** Estimate π by dropping random points in a square and counting the share inside the quarter circle (times 4). One drop has SD about 1.64, so about 110,000 drops are needed for a typical error of 0.005. Saved as `mcN`: the Luck detector uses this rule to say how many null-world replays it needs.
- **Deeper:** Chebyshev's inequality, P(|X̄ₙ − μ| ≥ ε) ≤ σ²/(nε²), proves the weak law in one line. The strong law (almost sure convergence) and why it needs a finite mean: the Cauchy distribution has none, and its running average never settles (try it in the simulator). Pseudo-random generators and why Monte Carlo needs good ones (links `cs`). Quantum measurement statistics use the same 1/√n rule (links `qu`).

### b2-pr-02 · Expected value by counting indicators
- **You can:** find the average of a tangled count by splitting it into yes/no pieces.
- **Needs:** `st-expected`.
- **Tool:** ★ Simulator (letters into envelopes), Number shelf.
- **Play:** Bento shuffles n letters into n addressed envelopes. Drag n from 2 to 100 and run many shuffles: the count of letters in the right envelope jumps around, but its running average sits near 1 for every n.
- **Guess:** "With 100 letters, how many land in the right envelope, on average?" Pick about 0.01, about 1, about 10 or about 50. The running average settles on 1.
- **Name it:** To average a count, write it as a sum of **indicators**: 1 if a thing happens, 0 if not. The expected value of an indicator is the chance its thing happens, and expected values add even when the pieces depend on each other. That's **linearity of expectation**.
  `X = I₁ + I₂ + … + Iₙ` · `E[Iᵢ] = P(event i)` · `E[X] = Σ P(event i)`
- **Work it:** Three generator types. (a) Shared days: n people ∈ {4, …, 30}, d days ∈ {12, 50, 100, 365}; expected number of pairs that share a day. (b) Patterns: n flips ∈ {5, …, 41}; expected number of spots where heads is followed by tails. (c) (index ≥ 6) Collecting: n coupon types ∈ {2, 3, 4, 6}; expected draws to see them all. Index < 3 uses type (b) or type (a) with n ≤ 6. The generator names pairs = C(n, 2) and spots = n − 1.
  Steps for (a) and (b):
  1. **What one indicator marks** tap (one pair matches; spot i is heads then tails)
  2. **Chance for one indicator** type 1/d or 1/4
  3. **How many indicators** type C(n, 2) or n − 1
  4. **Expected total** type the product as a fraction (n = 10, d = 50 → 45/50 = 9/10; n = 21 flips → 5).
  Steps for (c):
  1. **Expected draws for the next new type when j are found** type n/(n − j)
  2. **Expected total** type the sum as a fraction (n = 3 → 3 + 3/2 + 1 = 11/2; n = 4 → 25/3; n = 6 → 147/10).
  Slips: answered n instead of C(n, 2) "Pairs, not people: ${n} people make C(${n}, 2) = ${pairs} pairs." · used n, not n − 1, spots "A heads-then-tails spot needs two flips, so there are ${spots} spots, not ${n}." · refused because the events overlap, or multiplied chances "Linearity needs no independence. Add the expected values even when the events overlap."
- **Oracle:** For n ≤ 8 (flips) or n ≤ 6 (people), enumerate every flip string or birthday list and average the count exactly; otherwise a 10⁵-run simulation within 3 SE. Collector: a 10⁵-run simulation within 3 SE.
- **Use it:** In a class of 30, the expected number of pairs sharing a birthday is C(30, 2)/365 = 435/365 ≈ 1.19. Saved as `pairs`: the Luck detector uses the same count when it checks "two of my 30 metrics moved together, is that strange?"
- **Deeper:** The variance of a count from indicators, Var X = Σ Var Iᵢ + 2 Σ Cov(Iᵢ, Iⱼ), and the letters-in-envelopes count tending to Poisson(1), so P(no match) → 1/e. The probabilistic method: if the average is above k, some arrangement beats k (Erdős's lower bound for Ramsey numbers). Coupon collector concentration: n ln n + O(n).

### b2-pr-03 · Variance of sums and covariance
- **You can:** find the spread of a sum or difference when the parts move together.
- **Needs:** b2-pr-02, `st-expected`.
- **Tool:** ★ Simulator, Joint cloud, Matrix pad.
- **Play:** Two spinners X and Y feed a histogram of X + Y. A "link" knob makes Y lean with X, ignore it, or lean against it. The histogram of the sum widens, holds or narrows as you turn the knob.
- **Guess:** "Y tends to go down when X goes up. Is X + Y more spread out, the same, or less spread out than when they're independent?" Pick one; the two histograms appear side by side and the narrower one is the leaning-against one.
- **Name it:** Variance scales by the square of a multiplier, and for a sum it adds, plus a cross term for how the parts move together. That cross term is the **covariance**. For n independent copies, the sum's variance is nσ² and the average's is σ²/n.
  `Var(αX + s) = α² Var X` · `Var(X ± Y) = Var X + Var Y ± 2 Cov(X, Y)` · `Cov(X, Y) = E[XY] − E[X] E[Y]`
- **Work it:** Var X = a ∈ {4, 9, 16, 25}, Var Y = b ∈ {1, 4, 9, 16}, Cov c an integer with |c| ≤ √(ab) (index < 3: c = 0 or c = 2); multipliers α, β ∈ {−3, −2, 2, 3}, never printed as 1, and βY shown through the sign helper ("2X − 3Y").
  1. **Var(αX)** type α²a
  2. **Var(X + Y)** type a + b + 2c
  3. **Var(X − Y)** type a + b − 2c
  4. **Var(αX + βY)** type α²a + β²b + 2αβc (a = 9, b = 4, c = −3, α = 2, β = 3 → 36 + 36 − 36 = 36).
  Slips: typed a − b for Var(X − Y) "Variances never subtract. Var(X − Y) = Var X + Var Y − 2 Cov(X, Y)." · typed αa "Multiplying by α scales the spread by |α| and the variance by α²." · typed a + b + c "The cross term counts twice: + 2 Cov(X, Y)."
- **Oracle:** `α**2*a + β**2*b + 2*α*β*c`.
- **Use it:** Two thermometers each have error variance 4. Averaging them with independent errors gives variance (4 + 4)/4 = 2; if their errors have covariance 2, it gives (4 + 4 + 4)/4 = 3. Saved as `varAvg`. The Luck detector adds the two arms' errors this way.
- **Deeper:** The covariance matrix Σ, Var(wᵀX) = wᵀΣw ≥ 0, so Σ is positive semidefinite (links b2-la-15). Minimum-variance weights w ∝ Σ⁻¹1 (the idea behind portfolio math). Cauchy–Schwarz gives |Cov| ≤ σXσY, so correlation lives in [−1, 1]. The law of total variance, Var Y = E[Var(Y | X)] + Var(E[Y | X]).

### b2-pr-04 · Bayes' rule and the base rate
- **You can:** turn "how accurate is the test" into "how likely is it, given a positive".
- **Needs:** `st-probrules`.
- **Tool:** Bayes box (people mode), ★ Simulator.
- **Play:** 10,000 dots, one per person. Drag how rare the condition is, how often the test catches it, and how often it clears healthy people. Dots split into four colors, and the positives are boxed so you can see how many are real.
- **Guess:** "1% have it. The test catches 90% of cases and clears 90% of healthy people. Of those who test positive, what share have it?" Drag a marker from 0% to 100%. The box lights 90 true positives and 990 false ones: about 8%.
- **Name it:** To reverse a conditional chance, count the people. Of the positives, the share that really have it depends heavily on how rare the condition is. That's **Bayes' rule**. In odds form, the evidence multiplies what you believed before.
  `P(A | B) = P(B | A) P(A) / P(B)` · `posterior odds = prior odds × likelihood ratio` · `LR+ = sensitivity / (1 − specificity)`
- **Work it:** N = 10,000; prevalence ∈ {1%, 2%, 5%, 10%}; sensitivity ∈ {80%, 90%, 95%, 99%}; specificity ∈ {90%, 95%, 98%, 99%}. All counts come out whole. The generator names healthy = N − have it and positives = TP + FP. Index < 3 uses prevalence 10% and specificity 90%.
  1. **Have it** type N × prevalence
  2. **True positives** type that × sensitivity
  3. **False positives** type (N − have it) × (1 − specificity)
  4. **P(has it | positive)** type TP/(TP + FP) as a percent to 1 decimal (2%, 95%, 95% → 190 and 490 → 27.9%).
  Slips: typed the sensitivity "That's P(positive | has it). You need the reverse, P(has it | positive)." · divided by N "Only positives count here: divide by TP + FP = ${positives}." · used N in the false positives "False positives come from the healthy ${healthy}, not all ${N}."
- **Oracle:** Build the 10,000 people as an array (has it, tests positive) and count the share with it among the positives, to 1 decimal.
- **Use it:** Someone tests positive twice on independent tests. Use the first answer as the new prevalence and run the box again ("test again" button). Saved as `ppv`; with project 1 this becomes the Luck detector's base-rate dial.
- **Deeper:** Log-odds make evidence add, and log₂ of a likelihood ratio is evidence in bits (links `in`). Naive Bayes classifiers multiply likelihood ratios across features (links `ai`). Bayes' rule for a continuous parameter, posterior ∝ likelihood × prior, previews b2-pr-12.

## Unit 2 · Shapes of chance

### b2-pr-05 · The Poisson count
- **You can:** find the chance of a given number of rare, random events in a window.
- **Needs:** `st-binomial`.
- **Tool:** ★ Simulator (event rain), Distribution lab (Poisson).
- **Play:** Dots rain onto a time strip at an average rate you drag. A window slides along and a bar chart counts how many dots each window caught. A second panel shows Binomial(n, λ/n) as n grows, sliding onto the same bars.
- **Guess:** "Calls average 3 per minute. Which count is most common in a minute?" Pick 2, 3, 4, or "2 and 3 tie". The bars settle with 2 and 3 exactly level.
- **Name it:** When many tiny chances each might happen independently, the count follows a **Poisson** distribution with mean λ, where λ is the rate times the window. Its variance is also λ.
  `P(X = k) = e^(−λ) λᵏ / k!` · `E[X] = Var X = λ` · `λ = rate × time`
- **Work it:** Rate r and window t with λ = rt ∈ {0.5, 1, 1.5, 2, 3, 4} (index < 3: λ ∈ {1, 2}, given directly); k ∈ {0, …, 4}. Answers to 4 decimals.
  1. **λ for this window** type rt (2 per hour over 90 minutes → 3)
  2. **P(X = 0)** type e^(−λ) (λ = 1 → 0.3679)
  3. **P(X = k)** type e^(−λ)λᵏ/k! (λ = 2, k = 2 → 0.2707; λ = 3, k = 3 → 0.2240)
  4. (later) **P(X ≥ 1)** type 1 − e^(−λ).
  Slips: forgot the k! "Divide by k!: the ways to order k arrivals don't count as different outcomes." · used e^λ "The chance shrinks with λ for k = 0: it's e^(−λ)." · used the hourly rate as λ "λ is the mean for this window: rate × time = ${λ}."
- **Oracle:** A library Poisson pmf (`scipy.stats.poisson.pmf(k, λ)`), rounded to 4 decimals.
- **Use it:** A street averages 2 crashes a month, and this month had 6. P(X ≥ 6) = 1 − e^(−2)(1 + 2 + 2 + 4/3 + 2/3 + 4/15) ≈ 0.0166. Then: the city has 50 such streets, so the chance some street hits 6 is about 1 − 0.9834⁵⁰ ≈ 0.57. Saved as `lambda`; it sets up b2-pr-15.
- **Deeper:** The Poisson limit, (1 − λ/n)ⁿ → e^(−λ), proves Binomial(n, λ/n) → Poisson(λ). The Poisson process: gaps between arrivals are exponential (b2-pr-06), counts in disjoint windows are independent, and two processes merge by adding rates (superposition) or split by coin flips (thinning). Links `de` (birth processes).

### b2-pr-06 · Densities and the exponential wait
- **You can:** find chances for a continuous wait time as areas under a curve.
- **Needs:** b2-pr-05, `g12-defint`.
- **Tool:** Distribution lab (density sketcher, exponential), Grapher 2D.
- **Play:** Sketch any curve with handles; Bento keeps its area at 1 and shades the area between two values you drag. Then switch to the exponential wait, drag its mean, and press "you already waited t": the tail is cut off and rescaled, and it looks exactly like the curve you started with.
- **Guess:** "A part's life is exponential with mean 10 years. It has already lasted 10 years. What's its expected remaining life?" Pick 0, 5, 10 or 20. The rescaled tail matches the original: 10.
- **Name it:** For a continuous variable, chance is area under the **density** f: the chance it falls between a and b is the integral from a to b. The **exponential** wait with rate λ forgets how long you've waited: that's being **memoryless**.
  `P(a < X < b) = ∫ₐᵇ f(x) dx` · `f(x) = λe^(−λx)` · `P(X > t) = e^(−λt)` · `mean = 1/λ` · `median = ln 2 / λ`
- **Work it:** Mean m ∈ {2, 4, 5, 10}, so λ = 1/m; times t, a, b as multiples of m/2 (index < 3: t = m). Answers to 4 decimals, the median to 2.
  1. **Rate λ** type 1/m as a fraction
  2. **P(X > t)** type e^(−t/m) (t = m → 0.3679)
  3. **P(a < X < b)** type e^(−a/m) − e^(−b/m) (m = 4, a = 2, b = 4 → 0.60653 − 0.36788 = 0.2387)
  4. **Median** type m ln 2 (m = 10 → 6.93).
  Slips: typed λ = m "A mean wait of m means a rate of 1/m per unit time." · typed 1 − e^(−λt) for P(X > t) "1 − e^(−λt) is the chance it's over by t. Lasting past t is e^(−λt)." · typed the mean for the median "The curve is skewed right, so the median m ln 2 is below the mean."
- **Oracle:** Numerical integration of λe^(−λx) over the asked range (Simpson's rule, 10⁴ strips), rounded to 4 decimals; the median by bisection on the integral reaching 1/2, to 2 decimals.
- **Use it:** Carbon-14's half-life is 5,730 years, which is the median of one atom's wait. After 11,460 years, e^(−2 ln 2) = 1/4 of it is left. Saved as `halfLife`.
- **Deeper:** Inverse transform sampling, X = −ln(U)/λ for U uniform, turns any CDF into a sampler (links `cs`). The exponential is the only continuous memoryless distribution (the functional equation G(s + t) = G(s)G(t)). Hazard rates, the Weibull family, and the gamma distribution as a sum of exponential waits.

### b2-pr-07 · The central limit theorem
- **You can:** find the chance a total of many random pieces passes a cutoff, whatever the pieces look like.
- **Needs:** b2-pr-03, `st-normal`, `st-sampdist`.
- **Tool:** Sample machine, Galton board, Distribution lab (normal table).
- **Play:** Draw any population shape, even lopsided or two-humped. Drag the sample size n from 1 to 50 and watch the histogram of sample means turn into a bell and narrow. On the Galton board, set each peg's push to the same lopsided shape and the pile is still a bell.
- **Guess:** "The population SD is σ. Drag the bracket to where the middle 95% of sample means of size 25 will fall." The machine runs 10,000 samples and the true bracket appears at about ±2σ/5.
- **Name it:** A sum of many independent pieces is close to normal, whatever each piece looks like. That's the **central limit theorem**. The sum of n has mean nμ and SD σ√n; the average has mean μ and SD σ/√n.
  `Sₙ ≈ Normal(nμ, σ√n)` (mean, SD) · `z = (S − nμ) / (σ√n)`
- **Work it:** A piece with mean μ ∈ {2, …, 20} and SD σ ∈ {2, 3, 4, 5, 6, 10}; n ∈ {4, 9, 16, 25, 36, 100}; cutoff T = nμ + zσ√n with z from the table (index < 3: z ∈ {1, 2}).
  1. **Mean of the total** type nμ
  2. **SD of the total** type σ√n
  3. **z** type (T − nμ)/(σ√n)
  4. **P(total > T)** type from the table, 4 decimals (n = 25, μ = 8, σ = 5, T = 250 → 200, 25, 2, 0.0228).
  Slips: typed nσ for the SD "SDs don't add; variances do. The total's variance is nσ², so its SD is σ√n." · typed σ/√n "σ/√n is the SD of the average. For the total, it's σ√n." · typed the lower tail "You need the chance of more than T: the upper tail."
- **Oracle:** Table lookup of `(T - n*μ) / (σ*sqrt(n))`.
- **Use it:** An elevator's limit is 1,350 kg. Riders weigh 75 kg on average with SD 15 (made up). With 16 riders, the total has mean 1,200 and SD 60, z = 2.5, so the chance of overload is about 0.0062. Saved as `zSum`.
- **Deeper:** A proof sketch with moment generating functions (the log-MGF of a standardized sum tends to t²/2). The Berry–Esseen bound, error ≤ C E|X − μ|³/(σ³√n). When it fails: heavy tails with infinite variance and stable laws (Cauchy again). The Lindeberg condition for pieces that aren't identical.

### b2-pr-08 · Correlation and the best prediction
- **You can:** predict one measurement from another and say how much is left unexplained.
- **Needs:** b2-pr-03, `st-lsrl`.
- **Tool:** Distribution lab (Joint cloud), Grapher 2D.
- **Play:** A cloud of points from a two-variable bell. Drag σx, σy and the correlation ρ; the covariance ellipse stretches and tilts. Drag a thin vertical slice along x, and a dot marks the middle of the points in that slice.
- **Guess:** "With equal SDs and ρ = 0.5, place the middle of the slice at x two SDs above average." Place a point. The slice's middle lands one SD up, below the ellipse's long axis.
- **Name it:** **correlation** is covariance in SD units. The best prediction of y from x is the slice's middle, which moves only ρ SDs for each SD of x. What's left over has SD σy√(1 − ρ²).
  `ρ = Cov(X, Y) / (σx σy)` · `E[Y | X = x] = μy + ρ (σy/σx)(x − μx)` · `ẑy = ρ zx` · `leftover SD = σy √(1 − ρ²)`
- **Work it:** Integer means; σx, σy ∈ {2, 4, 5, 10, 20}; Cov chosen so ρ ∈ {0.25, 0.4, 0.5, 0.6, 0.75, 0.8, −0.5, −0.6}; x = μx + kσx with k ∈ {−2, −1, 1, 2, 3} (index < 3: ρ = 0.5, k = 2). The generator names sdProduct = σxσy; μy + ρkσy is shown through the sign helper when ρk < 0.
  1. **ρ** type Cov/(σxσy)
  2. **z of x** type k
  3. **Predicted z of y** type ρk
  4. **Predicted y** type μy + ρkσy
  5. (later, ρ = ±0.6 or ±0.8) **Leftover SD** type σy√(1 − ρ²) (σx = 10, σy = 5, Cov = 30, k = 2 → 0.6, 2, 1.2, μy + 6, then 4).
  Slips: typed z of y = z of x "The prediction is pulled toward the mean: multiply by ρ." · typed Cov/σx² "Divide by both SDs: σx σy = ${sdProduct}." · used the ellipse's long axis "The long axis overshoots. The slice's middle is the best prediction."
- **Oracle:** `μy + ρ * k * σy`.
- **Use it:** Predict a child's adult height from a parent's using made-up means, SDs and ρ = 0.5, and notice tall parents' children are predicted tall but less so. Saved as `rho`; b2-pr-17 picks this up.
- **Deeper:** The ellipse's axes are the eigenvectors of the covariance matrix, which is principal component analysis (links b2-la-19). The conditional of a multivariate normal, μ₁ + Σ₁₂Σ₂₂⁻¹(x₂ − μ₂), with variance given by the Schur complement. Why there are two regression lines (y on x and x on y).

## Unit 3 · Learning from data

### b2-pr-09 · Maximum likelihood
- **You can:** find the parameter value that makes your data most probable.
- **Needs:** b2-pr-05, b2-pr-06, `c-extrema`.
- **Tool:** Likelihood viewer, Grapher 2D.
- **Play:** Enter k heads in n flips. The likelihood curve over p draws live; drag a marker along it and read the height. Switch to the log and the peak stays put. Raise n with the same share of heads and the curve narrows.
- **Guess:** "7 heads in 10 flips. Drag to where the curve peaks." The curve draws and peaks at 0.7.
- **Name it:** The **likelihood** says how probable your data is under each parameter value. The **maximum likelihood estimate** is the value at the peak. Taking logs turns products into sums, and setting the derivative to zero finds the peak.
  `ℓ(p) = k ln p + (n − k) ln(1 − p)` · `ℓ′(p) = 0 → p̂ = k/n` · Poisson `λ̂ = x̄` · exponential `λ̂ = 1/x̄`
- **Work it:** Three types. (a) Coin: n ∈ {4, …, 20}, k ∈ {1, …, n − 1}, so the peak is inside (0, 1) and ℓ′ = 0 has a solution. (b) Poisson: 4 to 8 daily counts in 0..9 with a whole-number mean of at least 1. (c) Exponential: 4 to 6 waits with a whole-number mean m. Index < 3: type (a) with n ≤ 6.
  1. **Log-likelihood** tap the right ℓ
  2. **Set ℓ′ = 0** tap the right equation
  3. **Estimate** type p̂, λ̂ or 1/m as a fraction
  4. (type (a), n ≤ 6) **Likelihood ratio L(p̂)/L(1/2)** type a fraction (k = 3, n = 4 → (27/256)/(16/256) = 27/16).
  Slips: typed (n − k)/n "That's the share of tails. The likelihood peaks at the share of heads, k/n." · typed 1/x̄ for Poisson "For counts, λ is the mean count, so λ̂ = x̄." · typed x̄ for the exponential "The rate is 1 over the mean wait: λ̂ = 1/${m}."
- **Oracle:** `k/n`, `mean(x)`, `1/mean(x)`.
- **Use it:** Fit a rate to a made-up week of sign-ups per day. Saved as `lamHat`.
- **Deeper:** Fisher information, I(p) = n/(p(1 − p)), and the asymptotic normality of the MLE with variance 1/I. The Cramér–Rao bound. The negative log-likelihood is cross-entropy, the loss AI models are trained on (links b2-in-09, b2-ai-07), and the peak is found by gradient steps when there's no formula (links b2-mv-14). A case where the MLE is biased: Uniform(0, θ), where θ̂ = the sample maximum. When the peak is at the edge: with k = 0 or k = n, ℓ has a ln 0 term, ℓ′ never reaches 0, and the likelihood is largest at p̂ = 0 or 1.

### b2-pr-10 · Bias, variance and the n − 1
- **You can:** judge an estimator by its average miss and its wobble together.
- **Needs:** b2-pr-03, b2-pr-07.
- **Tool:** Sample machine (variance mode), Grapher 2D.
- **Play:** Draw many samples from a population with known variance. Each sample gives two estimates of it, one dividing by n and one by n − 1, dropped on two dot plots with running averages. One average sits low.
- **Guess:** "The true variance is 100. With samples of 2, dividing by n, where does the average estimate land?" Pick 50, 75, 100 or 200. The running average settles at 50.
- **Name it:** An estimator's typical miss splits into **bias** (where it's centered) and **variance** (how much it wobbles). The total is the **mean squared error**. Dividing by n is biased low by the factor (n − 1)/n; dividing by n − 1 removes the bias. Lower bias isn't always better if the wobble grows.
  `MSE = bias² + variance` · `E[(1/n) Σ (xᵢ − x̄)²] = ((n − 1)/n) σ²`
- **Work it:** (a) σ² ∈ {12, 20, 30, 60, 100} and n ∈ {2, 3, 4, 5, 6, 10} with n dividing σ². (b) Two estimators, each with an integer bias in −3..3 and an integer SD in 1..6, rejecting pairs whose MSEs are equal (106 of the 1,764 ordered pairs, counting identical ones), so step 4 always has one answer. Index < 3: σ² = 100, n ∈ {2, 4, 5}.
  1. **Average of the divide-by-n estimate** type (n − 1)σ²/n (σ² = 60, n = 4 → 45)
  2. **Its bias** type −σ²/n (→ −15)
  3. **MSE of A and of B** two boxes, bias² + SD² (A: bias 0, SD 5 → 25; B: bias 2, SD 3 → 13)
  4. **Better estimator** tap A or B (B).
  Slips: typed bias + SD² "Square the bias too: MSE = bias² + SD²." · typed (bias + SD)² "Bias and wobble add in squares, not before squaring." · typed bias² + SD "The variance is SD², so square the SD."
- **Oracle:** `(n-1)*σ2/n`, `b*b + s*s`.
- **Use it:** Shrink a noisy average toward a sensible guess and watch the MSE drop even though a bias appears. Saved as `mse`.
- **Deeper:** Stein's paradox: in 3 or more dimensions, the James–Stein estimator beats the sample mean on total MSE for every true value. The bias–variance trade-off in model fitting, where high-degree polynomials overfit (links b2-ai-09). Unbiased estimators and the Cramér–Rao bound from b2-pr-09.

### b2-pr-11 · The bootstrap
- **You can:** put error bars on almost any statistic by resampling your own data.
- **Needs:** b2-pr-10.
- **Tool:** Sample machine (bootstrap mode), Data table and stats panel.
- **Play:** A data table of 10 values. Press "resample": Bento draws 10 values from your 10 with replacement and drops that resample's median on a dot plot. Press it 1,000 times: the spread of the dots is the bootstrap's guess at how much the median wobbles.
- **Guess:** "Drawing 10 from 10 with replacement, about what share of your original values get left out of a resample?" Pick 0%, about 10%, about 35% or about 50%. The counter settles near 35%.
- **Name it:** You can't redraw from the population, so redraw from your sample as if it were the population. The spread of a statistic across resamples estimates its **standard error**, and the middle of the resample pile gives a **percentile interval**.
  `P(a value is left out) = (1 − 1/n)ⁿ` · `distinct resamples = C(2n − 1, n)`
- **Work it:** n ∈ {2, 3, 4, 5, 10} for steps 1 and 2 (index < 3: n ∈ {2, 3}); 40 sorted resample statistics (integers) generated for step 3.
  1. **Chance a given value is left out** type (1 − 1/n)ⁿ to 3 decimals (n = 2 → 0.250; n = 4 → 0.316; n = 10 → 0.349)
  2. **Distinct resamples** type C(2n − 1, n) (n = 3 → 10; n = 5 → 126)
  3. **90% interval** drop the lowest 2 and highest 2 of the 40, then type the 3rd smallest and the 38th smallest.
  Slips: typed 1 − 1/n "That's one draw. All n draws must miss it: (1 − 1/n)ⁿ." · typed nⁿ "Order doesn't matter in a resample. Count the different collections: C(2n − 1, n)." · typed the 2nd and 39th "Drop two from each end; the interval starts at the 3rd value."
- **Oracle:** For n ≤ 5, enumerate all nⁿ ordered draws: the share missing value 1 (to 3 decimals) and the number of distinct multisets; for n = 10, `round((1 - 1/n)**n, 3)` and a library `comb(2n-1, n)`.
- **Use it:** Error bars for the median of a made-up set of commute times. Saved as `bootSE`.
- **Deeper:** As n grows, (1 − 1/n)ⁿ → 1/e ≈ 0.368, so a resample holds about 63.2% of the distinct values. The plug-in principle and the empirical distribution. When the bootstrap fails (the sample maximum, very heavy tails), and BCa intervals that fix skew. Bagging and random forests average models fit to resamples (links `ai`).

### b2-pr-12 · Bayesian updating with a Beta prior
- **You can:** update a belief about a chance, flip by flip, and say where it now centers.
- **Needs:** b2-pr-04, b2-pr-09.
- **Tool:** Distribution lab (Beta updater), Likelihood viewer.
- **Play:** A prior curve over the coin's chance p, shaped by two handles a and b. Feed flips one at a time; each head nudges the curve right, each tail left, and it narrows. A shaded band marks the middle 95%.
- **Guess:** "Start flat. You see 3 heads in 3 flips. Drag to where the posterior's mean lands." The curve redraws, peaking at 1 with its mean at 0.8.
- **Name it:** A **Beta(a, b)** prior works like a + b imaginary flips with a heads. Real data add to the counts. The **posterior mean** blends the prior's mean and the data's share, and the data's weight grows with n.
  `Beta(a, b) + k heads in n → Beta(a + k, b + n − k)` · `posterior mean = (a + k) / (a + b + n)` · `data weight = n / (a + b + n)`
- **Work it:** a, b ∈ {1, 2, 3, 5}; n ∈ {2, …, 20}; k ∈ {0, …, n} (index < 3: a = b = 1, n ≤ 5).
  1. **New a** type a + k
  2. **New b** type b + n − k
  3. **Posterior mean** type a fraction (Beta(2, 2), 7 heads in 10 → Beta(9, 5), mean 9/14)
  4. (later) **Weight on the data** type n/(a + b + n) (→ 10/14 = 5/7).
  Slips: added k to b "Heads add to a, tails to b." · typed k/n "That's the data alone. The prior counts too: (a + k)/(a + b + n)." · typed (a + k)/(a + b + k) "The bottom adds all n flips, heads and tails."
- **Oracle:** A library Beta mean (`scipy.stats.beta(a + k, b + n - k).mean()`), compared as an exact fraction.
- **Use it:** Two made-up restaurants: 4 reviews, all good, against 200 reviews, 190 good. With a flat prior: 5/6 ≈ 0.833 against 191/202 ≈ 0.946. Saved as `postMean`; with project 3 it becomes the Luck detector's estimate stage.
- **Deeper:** Conjugate pairs (Gamma–Poisson, Normal–Normal, Dirichlet–multinomial, the last one being add-one smoothing in language models). Credible intervals against confidence intervals. Bernstein–von Mises: with lots of data, the posterior becomes a normal centered at the MLE. Thompson sampling for choosing between options while learning (links `ai`). MCMC for posteriors with no formula (b2-pr-19).

## Unit 4 · Luck or real?

### b2-pr-13 · The shuffle test
- **You can:** get an exact p-value by checking every way the labels could have fallen.
- **Needs:** `st-testprop`, `st-experiment`.
- **Tool:** Shuffle bench, Data table and stats panel.
- **Play:** Two groups of value chips, treated and control, with the gap between their means. Press shuffle: the labels are dealt out again at random and the new gap drops onto a dot plot. Press "list every split" and all of them appear, with the real gap marked.
- **Guess:** "The treated group beat control by this gap. Drag to guess what share of random splits do at least as well." The bench lists every split and shades the share.
- **Name it:** If the treatment did nothing, each value would have been the same under either label, so every split was equally likely. The **p-value** is the share of splits at least as extreme as the one you got. This **permutation test** needs nothing but random assignment.
  `splits = C(n₁ + n₂, n₁)` · `p = (splits at least as extreme) / (all splits)`
- **Work it:** 6 distinct whole values from 1..20, split 3 treated and 3 control, so 20 splits; the treated set is chosen so 1 to 4 splits have a treated sum at least as large (index ≥ 6: 3 and 4, so 35 splits, with the bench showing the sorted sums). One-sided: treated higher.
  1. **Number of splits** type C(6, 3) = 20
  2. **Observed gap** type mean(treated) − mean(control) to 2 decimals
  3. **Splits at least as extreme** type the count (treated {10, 15, 18}, control {5, 8, 12}: sum 43; only {12, 15, 18} = 45 and {10, 15, 18} = 43 reach it → 2)
  4. **p-value** type a fraction (2/20 = 1/10)
  5. **At α = 0.05?** tap Reject / Don't reject.
  Slips: typed 6! = 720 "Order inside a group doesn't matter: choose which 3 are treated, C(6, 3) = 20." · counted only bigger splits "At least as extreme includes the split you saw. Count ties too." · typed the count as the p-value "Divide by all ${splits} splits."
- **Oracle:** Brute force over all splits.
- **Use it:** A made-up fertilizer trial with 3 and 3 plants. Notice that even the most lopsided split gives p = 1/20 = 0.05: tiny experiments can't reach small p-values. Saved as `pPerm`; this is the Luck detector's test stage.
- **Deeper:** Fisher's sharp null and why the test is exact under random assignment (exchangeability). Monte Carlo shuffles when there are too many splits, with error √(p(1 − p)/B) from b2-pr-01. Rank tests (Wilcoxon–Mann–Whitney), and why the t-test approximates the permutation test as n grows.

### b2-pr-14 · Power: will you catch it if it's there?
- **You can:** find the chance an experiment detects a real effect, and the sample size it needs.
- **Needs:** b2-pr-07, `st-testprop`.
- **Tool:** Distribution lab (Power bells), Grapher 2D.
- **Play:** Two bells, one for "no effect" and one shifted by the real effect δ, with a cutoff line at z = 1.96. Drag δ, σ and n: the bells narrow as n grows, and the shaded area of the second bell past the cutoff (the power) grows.
- **Guess:** "Power is 50% now. If you quadruple n, what does it become?" Pick about 70%, about 85%, about 97% or 100%. The bells narrow by half and the power reads 97.5%.
- **Name it:** **power** is the chance your test says "real" when the effect is real. It grows with the effect and with √n and shrinks with σ. Plan n before you run: for a two-sided 5% test and 80% power, the effect needs to be 2.8 standard errors.
  `SE = σ/√n` · `shift = δ/SE` · `power ≈ P(Z > 1.96 − shift)` · `n = (1.96 + 0.84)² (σ/δ)² = 7.84 (σ/δ)²`
- **Work it:** σ ∈ {10, 20, 30}, n ∈ {16, 25, 100, 400} so SE is clean; shift ∈ {0.96, 1.46, 1.96, 2.46, 2.8, 2.96, 3.96} so 1.96 − shift is on the table; δ = shift × SE. For step 4, σ/δ ∈ {1, 2, 2.5, 5, 10}. Index < 3: shift ∈ {1.96, 2.96}.
  1. **SE** type σ/√n (σ = 20, n = 100 → 2)
  2. **Shift** type δ/SE (δ = 5.6 → 2.8)
  3. **Power** type P(Z > 1.96 − shift) from the table, 4 decimals (P(Z > −0.84) = 0.7995)
  4. **New plan: n for 80% power** type ⌈7.84 (σ/δ)²⌉ (σ = 10, δ = 2 → 196).
  Slips: typed α as the power "α is the false-alarm chance when there's no effect. Power is the hit chance when there is one." · typed 2.8 σ/δ for n "n grows with the square: (2.8 σ/δ)²." · took the wrong tail "Power is the area of the shifted bell past the cutoff, the upper side."
- **Oracle:** `1 - Φ(1.96 - shift)` with Φ from `erf`, not the table, to 4 decimals; `ceil(7.84 * (σ/δ)**2)`.
- **Use it:** Plan a made-up experiment before running it: what n catches a 2-point effect with SD 10? Saved as `nNeeded`; this is the Luck detector's plan stage.
- **Deeper:** The winner's curse: when power is low, the results that do pass the cutoff overstate the effect (type M error), and some even get its sign wrong (type S). Power curves and the noncentral t. Why fields full of small studies fail to replicate.

### b2-pr-15 · Many tests, many lucky winners
- **You can:** correct for running many tests so luck doesn't pass for discovery.
- **Needs:** b2-pr-13, `st-testprop`.
- **Tool:** ★ Simulator (P-value wall), Number shelf.
- **Play:** Run m tests where nothing is real. Their p-values appear as a row of bars, and a few dip under 0.05 by luck. Drag m from 1 to 100. Turn on the Bonferroni line and the Benjamini–Hochberg staircase. In "peek" mode, one experiment is checked after every 10 people and stopped at the first p < 0.05.
- **Guess:** "20 tests, no real effects, each at α = 0.05. What's the chance at least one comes up 'significant'?" Drag 0% to 100%. The wall runs 10,000 times and settles at about 64%.
- **Name it:** Test enough things and luck will hand you a winner. The chance of at least one false alarm is the **family-wise error rate**. **Bonferroni** tests each at α/m. **Benjamini–Hochberg** controls the share of false discoveries among your discoveries instead. Peeking is many tests in disguise.
  `P(at least one) = 1 − (1 − α)ᵐ` · Bonferroni `α/m` · BH: sort p₍₁₎ ≤ … ≤ p₍ₘ₎, find the largest i with p₍ᵢ₎ ≤ iq/m, reject 1..i
- **Work it:** m ∈ {2, 5, 10, 20, 50}, α = 0.05; for steps 4 and 5, m ∈ {4, 5, 6, 8} sorted p-values with q = 0.05, generated so the BH answer is 0 to m and, in about half the problems, one p-value fails its line but a later one passes (index < 3: m ∈ {2, 5}, no such gap).
  1. **Expected false alarms** type mα
  2. **P(at least one)** type 1 − 0.95ᵐ to 4 decimals (m = 20 → 0.6415; m = 5 → 0.2262)
  3. **Bonferroni cutoff** type 0.05/m
  4. **A second study, with its own m p-values: rejected by Bonferroni** type the count
  5. **Second study: rejected by BH** type the count (m = 4: 0.005, 0.03, 0.035, 0.6 against lines 0.0125, 0.025, 0.0375, 0.05 → 0.03 fails but 0.035 passes, so 3; Bonferroni at 0.0125 rejects 1).
  Slips: typed mα for step 2 "mα is the expected count, and it can pass 1. The chance of at least one is 1 − (1 − α)ᵐ." · stopped BH at the first failure "BH takes the largest i that passes, even after a miss: reject everything up to it." · used α instead of α/m "Bonferroni splits α across all ${m} tests."
- **Oracle:** `1 - 0.95**m`; BH by its rule.
- **Use it:** A made-up dashboard tracks 12 metrics after a redesign and two show p < 0.05. Which survive BH? Saved as `fdrCut`; this is the Luck detector's correction stage.
- **Deeper:** A proof sketch that BH keeps the false discovery rate at q · m₀/m for independent tests; the Holm step-down method. The garden of forking paths: analysis choices are hidden tests. Optional stopping inflates false alarms (with unlimited peeks, eventually always "significant"), and always-valid p-values and alpha spending fix it (links b2-pr-19, martingales).

### b2-pr-16 · Evidence: likelihood ratios and Bayes factors
- **You can:** say how strongly data favor one explanation over another, and why p = 0.05 isn't a 5% chance of luck.
- **Needs:** b2-pr-04, b2-pr-09, b2-pr-14.
- **Tool:** Bayes box (ideas mode), Likelihood viewer (Evidence walk).
- **Play:** 1,000 ideas get tested. Drag what share are really true, the power and α. The box splits them by real or not and significant or not, and boxes the significant ones. Then flip a coin and watch the running log likelihood ratio between "fair" and "loaded" walk toward one of two stop lines.
- **Guess:** "10% of ideas tested are real, power is 80% and α is 5%. Of the significant results, what share are false?" Drag 0% to 100%. The box lights 80 real hits and 45 false ones: 36%.
- **Name it:** A p-value is the chance of data this extreme if it's luck, not the chance it's luck given the data. The **likelihood ratio** compares how well two explanations predict what you saw; between two hypotheses it's the **Bayes factor**, and it multiplies your prior odds.
  `false share of hits = (1 − r)α / ((1 − r)α + r · power)` · `BF = P(data | H₁) / P(data | H₀)` · `posterior odds = prior odds × BF`
- **Work it:** (a) 1,000 ideas; share real r ∈ {10%, 20%, 50%}; power ∈ {50%, 80%}; α = 5%. (b) Coin: H₀ p = 1/2 against H₁ p = 3/4, n ∈ {2, …, 10}, k ∈ {max(0, n − 3), …, n}, so BF = 3ᵏ/2ⁿ; prior odds ∈ {1, 1/4, 1/9}. Index < 3: type (a) with r = 50%.
  Steps (a):
  1. **Real ideas** type 1,000r
  2. **Real hits** type that × power
  3. **False hits** type (1,000 − real) × 0.05
  4. **Share of hits that are false** type a percent to 1 decimal (r = 10%, power 80% → 100, 80, 45, 36.0%).
  Steps (b):
  1. **BF** type 3ᵏ/2ⁿ to 2 decimals (k = 8, n = 10 → 6561/1024 = 6.41)
  2. **Posterior odds** type prior odds × BF
  3. **Posterior chance** type odds/(1 + odds) to 3 decimals.
  Slips: typed α as the false share "α is the false-alarm rate among ideas that aren't real, not among the hits." · typed 1/BF "BF puts the loaded coin on top: P(data | p = 3/4) over P(data | p = 1/2)." · typed the odds as the chance "Odds of 3 mean 3 to 1, a chance of 3/4. Divide by 1 + odds."
- **Oracle:** Exact formulas.
- **Use it:** A made-up headline says "Study finds X, p = 0.04". With a stated share of ideas that pan out and the study's power, how likely is X real? Saved as `fdrField`; this is the Luck detector's weighing stage.
- **Deeper:** The Neyman–Pearson lemma: the likelihood ratio test is the most powerful test at its α. Wald's sequential probability ratio test with stop lines near ln((1 − β)/α) and ln(β/(1 − α)). Lindley's paradox. The Sellke–Bayarri–Berger bound: BF ≤ 1/(−e p ln p), so p = 0.05 gives at most about 2.46 to 1. Log Bayes factors as weight of evidence in bits (links `in`).

## Unit 5 · Traps and the verdict

### b2-pr-17 · Regression to the mean
- **You can:** spot an "effect" that is really extremes drifting back toward average.
- **Needs:** b2-pr-08.
- **Tool:** Data table (Retest pair), Distribution lab (Joint cloud).
- **Play:** Each person's score is skill plus luck, on two tests. Drag the share of the score that is skill. Brush the top 10% on test 1 and their test 2 scores appear beside them, lower on average, with no treatment at all.
- **Guess:** "The top group averaged 2 SDs above the mean on test 1, and the tests correlate at 0.5. Drag where they land on test 2." The group's test 2 average lands 1 SD above.
- **Name it:** When two measures correlate at less than 1, people picked for being extreme on one are, on average, less extreme on the other. That's **regression to the mean**. It isn't a force; it's selecting on luck. Only a comparison group can separate it from a real effect.
  `ρ = Var(skill) / (Var(skill) + Var(luck))` · `expected z₂ = ρ z₁`
- **Work it:** (Var skill, Var luck) ∈ {(8, 8), (3, 1), (20, 5), (16, 9), (9, 16), (64, 36)}, so the SD √(T + N) is whole: 4, 2, 5, 5, 5 and 10 (index < 3: (8, 8) or (3, 1)); mean 100; the group is picked at x = 100 + z₁ · SD with z₁ ∈ {1, 2, 3, −2}; 100 + ρ(x − 100) is shown through the sign helper when z₁ < 0.
  1. **ρ** type T/(T + N) (16, 9 → 0.64)
  2. **Expected z on test 2** type ρz₁
  3. **Expected test 2 score** type 100 + ρ(x − 100) (x = 110 → 106.4)
  4. **A coach praised the top group and they got worse. Did praise hurt?** tap "Yes", "No, it helped" or "Can't tell without a comparison group": "Can't tell without a comparison group".
  Slips: typed z₁ "They don't keep their luck. Expect ρz₁, closer to the mean." · typed ρ² "The tests share the skill part: ρ = T/(T + N), not its square." · typed T/N "Divide by the whole variance, T + N."
- **Oracle:** `100 + T/(T+N) * (x - 100)`.
- **Use it:** A made-up story: the worst-scoring schools get a new program and improve the next year. How much of that would happen anyway? Saved as `rtmShrink`; the Luck detector raises a flag when a study picks its subjects for being extreme.
- **Deeper:** Kelley's formula (true score ≈ ρx + (1 − ρ)μ) is shrinkage, and empirical Bayes generalizes it, connecting to James–Stein (b2-pr-10). Galton's discovery of regression with heights. Regression to the mean in sports streaks and in "most improved" lists.

### b2-pr-18 · Simpson's paradox and confounding
- **You can:** catch a comparison that flips once you account for a hidden group.
- **Needs:** `st-probrules`, `st-experiment`.
- **Tool:** Data table (Simpson table), Number shelf.
- **Play:** Two treatments, each used on mild and severe cases. Drag how many severe cases each treatment gets. The bars for "mild only" and "severe only" don't move, but the overall bars can flip. An arrow diagram shows severity pointing at both the treatment choice and the outcome.
- **Guess:** "Treatment A beats B among mild cases and among severe cases. Can B still win overall?" Pick yes or no. The sliders move until the overall bars flip: yes.
- **Name it:** A **confounder** affects both who gets a treatment and how they do. It can reverse a comparison when groups are pooled: **Simpson's paradox**. The fix is to compare within groups, then reweight to one common mix (**adjustment**). Random assignment cuts the arrow from the confounder to the treatment.
  `adjusted rate = Σ_g P(success | treatment, g) · P(g)`
- **Work it:** Per treatment, group sizes are multiples of 10 and success rates multiples of 10%; about two thirds of problems reverse, the rest don't (index < 3: always reverse, with 100 patients per treatment).
  1. **A, mild**
  2. **A, severe**
  3. **B, mild**
  4. **B, severe** (percents)
  5. **A overall** and **B overall** two boxes, percents to 1 decimal
  6. **Adjusted A** and **adjusted B** using the pooled mix, percents to 1 decimal
  7. **Which is better?** tap (A: mild 18/20, severe 40/80; B: mild 64/80, severe 8/20 → 90, 50, 80, 40; overall 58% and 72%; mix 100 mild and 100 severe gives adjusted 70% and 60%; A).
  Slips: averaged the two group rates for overall "Overall weighs groups by size: total successes over total patients." · adjusted with each treatment's own mix "Adjustment uses one common mix for both, or the comparison stays tilted." · picked the overall winner "The groups differ in how sick they are. Compare within groups or after adjusting."
- **Oracle:** Exact percents.
- **Use it:** Made-up admissions by department, where one group is admitted at a higher rate in every department and a lower rate overall. Saved as `adjRate`; the Luck detector asks "was assignment random?" and adjusts if not.
- **Deeper:** Causal diagrams and the back-door criterion; colliders, where conditioning creates a correlation from nothing (Berkson's paradox). Pearl's do-operator, P(y | do(x)), and when adjustment formulas identify it. Propensity scores and inverse probability weighting. Instrumental variables. Links `cs` (graphs).

### b2-pr-19 · Random walks, streaks and Markov chains
- **You can:** find where a chance process spends its time in the long run.
- **Needs:** b2-pr-01, b2-la-14, `st-probrules`.
- **Tool:** ★ Simulator (random walk, Markov board), Matrix pad.
- **Play:** A fair coin's running total wanders up and down, with a counter for the longest streak. Then a two-state board (sunny and rainy) with a token hopping by your chances of switching; the long-run share bars settle no matter where it started.
- **Guess:** "In 100 fair flips, about how long is the longest run of the same face?" Pick about 3, about 7 or about 15. Many runs of 100 flips show the longest run clusters around 7.
- **Name it:** A **Markov chain** moves by chances that depend only on where it is now. In the long run, the share of time in each state settles to a **stationary distribution** π with π = πP. With two states, if A switches to B with chance a and B to A with chance b, then π_A = b/(a + b). Linear algebra (b2-la-14) writes the same chain transposed: columns add to 1 and x ↦ A x. Long streaks in fair coins are normal, not signs of a hot hand.
  `π = πP` · `π_A = b/(a + b)` · `P(A → A in two steps) = (1 − a)² + ab`
- **Work it:** a, b ∈ {1/2, 1/3, 1/4, 1/5, 2/3, 3/4}, a ≠ b (index < 3: a, b ∈ {1/2, 1/4}). 30-day month for step 3: keep only pairs where 30π_B has at most 1 decimal. Ten ordered pairs (a, b) pass, with 30π_B in brackets: (1/2, 1/3) [18], (1/2, 1/4) [20], (1/2, 3/4) [12], (1/3, 1/2) [12], (1/3, 2/3) [10], (1/4, 1/2) [10], (1/4, 3/4) [7.5], (2/3, 1/3) [20], (3/4, 1/2) [18], (3/4, 1/4) [22.5].
  1. **Chance A stays A** type 1 − a
  2. **π_A** type b/(a + b) (a = 1/4, b = 1/2 → 2/3)
  3. **Expected B days in 30** type 30(1 − π_A) (→ 10)
  4. **A to A in two steps** type (1 − a)² + ab (→ 9/16 + 2/16 = 11/16).
  Slips: typed a/(a + b) "π_A grows with the chance of coming back to A, which is b." · typed (1 − a)² for step 4 "There's a second path: A to B, then back to A, with chance ab." · typed 1 − b for staying "Staying in A is 1 − a; b is the chance of leaving B."
- **Oracle:** Solve (Pᵀ − I)π = 0 with π_A + π_B = 1 exactly (or square P 50 times); the two-step chance as entry (A, A) of P² from a library `matmul`.
- **Use it:** A made-up basketball player's makes after a make and after a miss: is the hot hand bigger than a fair coin's streaks would produce? Saved as `piA`; the Luck detector's streak alarm uses this.
- **Deeper:** π is a left eigenvector of P with eigenvalue 1 (Perron–Frobenius), and the second eigenvalue sets how fast the chain mixes (links b2-la-14). PageRank is a Markov chain, and a next-word model with a fixed-length context makes one too (links b2-ai-12). Gambler's ruin: from k, a fair walk reaches N before 0 with chance k/N. Martingales and the optional stopping theorem: no stopping rule beats a fair game, and why peeking breaks naive p-values (b2-pr-15). The arcsine law for leads. MCMC (Metropolis–Hastings) samples posteriors with no formula (b2-pr-12). Continuous-time chains (links `de`).

### b2-pr-20 · The Luck detector
- **You can:** give an honest verdict on an experiment: effect size, interval, correction and the chance it's real.
- **Needs:** b2-pr-03, b2-pr-14, b2-pr-15, b2-pr-16.
- **Tool:** ★ Simulator (null world), Luck detector bench, Bayes box (ideas mode), Distribution lab.
- **Play:** A made-up A/B test of two page versions with a hidden true effect that is sometimes zero. Set the plan (n per version, the number of metrics, α), run it, and step through the bench: test, correct, estimate, weigh. Press "reveal" to see the truth, and run many experiments to see the detector's calibration: of the calls it made at about 80% sure, how many held up, drawn as dots for each call.
- **Guess:** "This result has p = 0.03. Power was 30%, and about 1 in 10 ideas like this are real. More likely real or luck?" Pick one. The ideas box lights 30 real hits and 45 false ones: luck is more likely (60%).
- **Name it:** An honest verdict uses a plan made before the data, one main test, a correction for every other look, the effect size with an interval, and the chance it's real given how often ideas pan out. Independent errors add in squares.
  `SE_diff = √(SE₁² + SE₂²)` · `z = d / SE_diff` · `95% interval = d ± 1.96 SE_diff` · cutoff for m metrics (two-sided, Bonferroni): m = 1 → 1.96, 2 → 2.24, 5 → 2.58, 10 → 2.81
- **Work it:** Arm SEs (SE₁, SE₂) from {(0.003, 0.004), (0.006, 0.008), (0.005, 0.012), (0.009, 0.012)} so SE_diff ∈ {0.005, 0.010, 0.013, 0.015}; the difference d = z × SE_diff with z ∈ {1, 1.5, 2, 2.5, 3}; m ∈ {1, 2, 5, 10}; share real r ∈ {10%, 20%, 50%}, power ∈ {30%, 50%, 80%}. Index < 3: SEs (0.006, 0.008), m = 1.
  1. **SE of the difference** type √(SE₁² + SE₂²) (0.006, 0.008 → 0.010)
  2. **z** type d/SE_diff (d = 0.025 → 2.5)
  3. **95% interval** two boxes to 4 decimals (0.0054 and 0.0446)
  4. **Clears the bar for m metrics?** tap Yes / No (m = 5, cutoff 2.58 → No)
  5. **Chance it's real if it clears α = 0.05/m (using the stated power)** type r · power / (r · power + (1 − r) · 0.05/m) as a percent to 1 decimal (r = 20%, power 80%, m = 1 → 0.16/0.20 = 80.0%).
  Slips: typed SE₁ + SE₂ "Independent errors add in squares, like variances (b2-pr-03): √(SE₁² + SE₂²)." · used z instead of 1.96 in the interval "The 95% interval always uses 1.96, whatever z you got." · cleared the bar with z > 1.96 when m > 1 "You checked ${m} metrics. The bar rises to ${cutoff}."
- **Oracle:** The arithmetic exactly, with the cutoffs from `Φ⁻¹(1 − 0.025/m)` (a library inverse normal) rather than the table.
- **Use it:** Finish the build: run the Luck detector on three made-up experiments with hidden truths and write a one-line verdict for each. Saved to the Notebook as `luckDetector`.
- **Deeper:** Always-valid sequential testing with e-values and mixture likelihood ratios, so you can peek safely. Hierarchical (empirical) Bayes across many past experiments, which shrinks each new effect toward the typical one (b2-pr-17). Variance reduction with a pre-period covariate (CUPED), cutting the variance by the factor 1 − ρ² (b2-pr-08). Calibration: of the calls you made at "80% sure", were 80% right? (links b2-ai-16, "Knowing what you don't know").
