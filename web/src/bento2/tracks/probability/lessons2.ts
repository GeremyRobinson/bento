// Probability, units 3 to 5 (b2-pr-09 to b2-pr-20), built from curriculum/specs/bento2/probability.md block by block.
import type { B2Lesson, SceneRef } from "../../model";
import { fracStep, multiStep, numStep, slip, tapStep, wholeStep } from "../../make";
import { formatAnswer } from "../../steps";
import { count } from "../../../curriculum/text";
import { comb, CUTOFFS, Phi, PhiInv, seeded, median, signTerm, trim } from "./maths";

const fr = (x: number) => formatAnswer(x, "fraction");
const rotate = (choices: string[], at: number): [string[], number] => {
  const k = ((at % choices.length) + choices.length) % choices.length;
  const out = [...choices.slice(1)];
  out.splice(k, 0, choices[0]!);
  return [out, k];
};
/** "3 ln p", "ln p" (never "1 ln p") */
const lnTerm = (c: number, what: string) => (c === 1 ? what : `${c} ${what}`);

/* ------------------------------------------------------------------ unit 3 ------------------------------------------------------------------ */

interface P09 { kind: "a" | "b" | "c"; n: number; k: number; xs: number[]; r1: number; r2: number }
/** whole numbers in [lo, hi] that sum to m × avg, spread out from all-equal by random moves */
function spread(rng: { int(a: number, b: number): number }, m: number, avg: number, lo: number, hi: number): number[] {
  const xs = Array.from({ length: m }, () => avg);
  for (let t = 0; t < 12; t++) {
    const i = rng.int(0, m - 1), j = rng.int(0, m - 1), d = rng.int(1, 3);
    if (i !== j && xs[i]! - d >= lo && xs[j]! + d <= hi) { xs[i]! -= d; xs[j]! += d; }
  }
  return xs;
}
const S = (xs: number[]) => xs.reduce((a, b) => a + b, 0);
const lrOf = (k: number, n: number) => ((k / n) ** k * (1 - k / n) ** (n - k)) / 0.5 ** n;

export const pr09: B2Lesson<P09> = {
  id: "b2-pr-09", track: "pr", unit: 3, title: "Maximum likelihood",
  youCan: "find the parameter value that makes your data most probable.",
  needs: ["b2-pr-05", "b2-pr-06", "c-extrema"],
  tools: ["like", "graph2d"],
  play: { scene: "like", props: { k: 7, n: 10 },
    say: "Enter k heads in n flips. The likelihood curve over p draws live; drag the marker along it and read the height. Switch to the log and the peak stays put. Raise n with the same share of heads and the curve narrows." },
  guess: { scene: "like", props: { k: 7, n: 10, quiet: true }, kind: "slider", min: 0, max: 1, step: 0.01, start: 0.4, answer: 0.7, near: 0.05, unit: "",
    format: x => `p = ${x.toFixed(2)}`,
    ask: "7 heads in 10 flips. Drag to where the likelihood curve peaks.",
    reveal: "It peaks at 0.7, the share of heads. No other p makes 7 heads in 10 as likely." },
  nameIt: {
    say: [
      "The **likelihood** says how probable your data is under each parameter value. The **maximum likelihood estimate** is the value at the peak.",
      "Taking logs turns products into sums, and setting the derivative to zero finds the peak.",
    ],
    formula: ["ℓ(p) = k ln p + (n − k) ln(1 − p)", "ℓ′(p) = 0 → p̂ = k/n", "Poisson λ̂ = x̄", "exponential λ̂ = 1/x̄"],
  },
  workIt: {
    reference: { kind: "a", n: 4, k: 3, xs: [], r1: 0, r2: 0 },
    generate(rng, i) {
      const r1 = rng.int(0, 2), r2 = rng.int(0, 2);
      if (i < 3) { const n = rng.int(4, 6); return { kind: "a", n, k: rng.int(1, n - 1), xs: [], r1, r2 }; }
      const kind = rng.pick(["a", "b", "c"] as const);
      if (kind === "a") { const n = rng.int(4, 20); return { kind, n, k: rng.int(1, n - 1), xs: [], r1, r2 }; }
      if (kind === "b") { const m = rng.int(4, 8); return { kind, n: m, k: 0, xs: spread(rng, m, rng.int(1, 6), 0, 9), r1, r2 }; }
      const m = rng.int(4, 6);
      return { kind, n: m, k: 0, xs: spread(rng, m, rng.int(2, 10), 1, 30), r1, r2 };
    },
    show: p => p.kind === "a" ? `A coin gives **${count(p.k, "head")} in ${p.n} flips**. Fit its chance of heads p.`
      : p.kind === "b" ? `Made-up daily counts: **${p.xs.join(", ")}**. Fit a Poisson rate λ.`
        : `Made-up waits, in minutes: **${p.xs.join(", ")}**. Fit an exponential rate λ.`,
    steps(p) {
      if (p.kind === "a") {
        const t = p.n - p.k;
        const [l1, i1] = rotate([`${lnTerm(p.k, "ln p")} + ${lnTerm(t, "ln(1 − p)")}`, `${lnTerm(p.k, "ln p")} − ${lnTerm(t, "ln(1 − p)")}`, lnTerm(p.k, "ln p")], p.r1);
        const [l2, i2] = rotate([`${p.k}/p − ${t}/(1 − p) = 0`, `${p.k}/p + ${t}/(1 − p) = 0`, `${p.k}/p = 0`], p.r2);
        const out = [
          tapStep("l", "Log-likelihood ℓ(p)", l1, i1, { hint: "Each head contributes ln p and each tail ln(1 − p)." }),
          tapStep("d", "Set ℓ′(p) = 0", l2, i2, { hint: "The derivative of ln(1 − p) is −1/(1 − p)." }),
          fracStep("est", "Estimate p̂", p.k / p.n, { hint: `Solve ${p.k}(1 − p) = ${t}p.`,
            slips: [slip("tails share", t / p.n, "That's the share of tails. The likelihood peaks at the share of heads, k/n.")] }),
        ];
        if (p.n <= 6) out.push(fracStep("lr", "Likelihood ratio L(p̂)/L(1/2)", lrOf(p.k, p.n), {
          hint: `(${fr(p.k / p.n)})^${p.k} (${fr(t / p.n)})^${t} over (1/2)^${p.n}.`,
          slips: [slip("flipped", 1 / lrOf(p.k, p.n), "Put the best fit on top: L(p̂) over L(1/2), so the ratio is at least 1.")] }));
        return out;
      }
      const s = S(p.xs), m = p.xs.length;
      if (p.kind === "b") {
        const [l1, i1] = rotate([`${s} ln λ − ${m}λ`, `${s} ln λ + ${m}λ`, `${s}λ − ${m} ln λ`], p.r1);
        const [l2, i2] = rotate([`${s}/λ − ${m} = 0`, `${s}/λ + ${m} = 0`, `${s} − ${m}/λ = 0`], p.r2);
        return [
          tapStep("l", "Log-likelihood ℓ(λ)", l1, i1, { hint: `Each count x adds x ln λ − λ (dropping the ln x! that doesn't depend on λ). The counts add to ${s}.` }),
          tapStep("d", "Set ℓ′(λ) = 0", l2, i2, { hint: `The derivative of ${s} ln λ is ${s}/λ.` }),
          fracStep("est", "Estimate λ̂", s / m, { hint: `${s}/${m}: the mean count.`,
            slips: [slip("one over", m / s, "For counts, λ is the mean count, so λ̂ = x̄.")] }),
        ];
      }
      const [l1, i1] = rotate([`${m} ln λ − ${s}λ`, `${m} ln λ + ${s}λ`, `${s} ln λ − ${m}λ`], p.r1);
      const [l2, i2] = rotate([`${m}/λ − ${s} = 0`, `${m}/λ + ${s} = 0`, `${s}/λ − ${m} = 0`], p.r2);
      return [
        tapStep("l", "Log-likelihood ℓ(λ)", l1, i1, { hint: `Each wait x adds ln λ − λx. The waits add to ${s}.` }),
        tapStep("d", "Set ℓ′(λ) = 0", l2, i2, { hint: `The derivative of ${m} ln λ is ${m}/λ.` }),
        fracStep("est", "Estimate λ̂", m / s, { unit: "per minute", hint: `${m}/${s}: one over the mean wait.`,
          slips: [slip("mean", s / m, `The rate is 1 over the mean wait: λ̂ = 1/${trim(s / m)}.`)] }),
      ];
    },
    scene: p => ({ scene: "like", props: p.kind === "a" ? { k: p.k, n: p.n } : { k: 7, n: 10 } }),
  },
  oracle: p => {
    const [, i1] = rotate(["", "", ""], p.r1), [, i2] = rotate(["", "", ""], p.r2);
    if (p.kind === "a") {
      // the likelihood as a product over the flips, at the share of heads and at 1/2
      const L = (q: number) => { let v = 1; for (let i = 0; i < p.n; i++) v *= i < p.k ? q : 1 - q; return v; };
      return [i1, i2, p.k / p.n, ...(p.n <= 6 ? [L(p.k / p.n) / L(0.5)] : [])];
    }
    const mean = p.xs.reduce((a, b) => a + b, 0) / p.xs.length;
    return [i1, i2, p.kind === "b" ? mean : 1 / mean];
  },
  useIt: {
    say: ["Fit a rate to a made-up week of sign-ups: 12, 9, 15, 11, 8, 14 and 8 a day. The Poisson fit is the mean, λ̂ = 77/7 = 11 a day.",
      "Raise the counts' n in the picture and watch the curve narrow: more days, a sharper estimate."],
    saves: { name: "lamHat", value: () => 11, unit: "a day", note: "sign-ups a day, fitted (made up)" },
    scene: { scene: "like", props: { k: 7, n: 10, mode: "poisson" } },
  },
  deeper: [
    "Fisher information, I(p) = n/(p(1 − p)), measures how sharp the peak is. With lots of data the MLE is close to normal with variance 1/I, and the Cramér–Rao bound says no unbiased estimator does better.",
    "The negative log-likelihood is cross-entropy, the loss AI models are trained on (links b2-in-09, b2-ai-07). When there's no formula, the peak is found by gradient steps (links b2-mv-14).",
    "The MLE can be biased: for Uniform(0, θ), θ̂ is the sample maximum, always too small. And with k = 0 or k = n, ℓ has a ln 0 term, ℓ′ never reaches 0, and the likelihood is largest at the edge, p̂ = 0 or 1.",
  ],
};

interface P10 { s2: number; n: number; A: [number, number]; B: [number, number] }
const mseOf = ([b, s]: [number, number]) => b * b + s * s;
/** "3²" or "(−3)²" */
const sq = (x: number) => (x < 0 ? `(${trim(x)})²` : `${trim(x)}²`);

export const pr10: B2Lesson<P10> = {
  id: "b2-pr-10", track: "pr", unit: 3, title: "Bias, variance and the n\u00a0−\u00a01",
  youCan: "judge an estimator by its average miss and its wobble together.",
  needs: ["b2-pr-03", "b2-pr-07"],
  tools: ["varest", "graph2d"],
  play: { scene: "varest", props: { n: 4 },
    say: "Draw many samples from a population with known variance. Each sample gives two estimates of it, one dividing by n and one by n − 1, dropped on two dot plots with running averages. One average sits low." },
  guess: { scene: "varest", props: { n: 2, quiet: true }, kind: "choice", options: ["50", "75", "100", "200"], answer: 0,
    ask: "The true variance is 100. With samples of 2, dividing by n, where does the average estimate land?",
    revealProps: { auto: true },
    reveal: "50. With n = 2, dividing by n is low by the factor (n − 1)/n = 1/2. Dividing by n − 1 lands on 100." },
  nameIt: {
    say: [
      "An estimator's typical miss splits into **bias** (where it's centered) and **variance** (how much it wobbles). The total is the **mean squared error**.",
      "Dividing by n is biased low by the factor (n − 1)/n; dividing by n − 1 removes the bias. Lower bias isn't always better if the wobble grows.",
    ],
    formula: ["MSE = bias² + variance", "E[(1/n) Σ (xᵢ − x̄)²] = ((n − 1)/n) σ²"],
  },
  workIt: {
    reference: { s2: 60, n: 4, A: [0, 5], B: [2, 3] },
    generate(rng, i) {
      const s2 = i < 3 ? 100 : rng.pick([12, 20, 30, 60, 100]);
      const n = i < 3 ? rng.pick([2, 4, 5]) : rng.pick([2, 3, 4, 5, 6, 10].filter(x => s2 % x === 0));
      for (;;) {
        const A: [number, number] = [rng.int(-3, 3), rng.int(1, 6)], B: [number, number] = [rng.int(-3, 3), rng.int(1, 6)];
        if (mseOf(A) !== mseOf(B)) return { s2, n, A, B };
      }
    },
    show: p => `A population has variance **σ² = ${p.s2}**, and samples have size **n = ${p.n}**. Two other estimators: **A** has bias ${trim(p.A[0])} and SD ${p.A[1]}; **B** has bias ${trim(p.B[0])} and SD ${p.B[1]}.`,
    steps(p) {
      const { A, B } = p, better = mseOf(A) < mseOf(B) ? 0 : 1, lowBias = Math.abs(A[0]) < Math.abs(B[0]) ? 0 : Math.abs(B[0]) < Math.abs(A[0]) ? 1 : -1;
      const both = (f: (e: [number, number]) => number) => [f(A), f(B)];
      return [
        wholeStep("avg", "Average of the divide-by-n estimate", ((p.n - 1) * p.s2) / p.n, { hint: `(n − 1)/n × σ² = ${p.n - 1}/${p.n} × ${p.s2}.`,
          slips: [slip("unbiased", p.s2, `Dividing by n runs low: on average it's (n − 1)/n of σ², here ${p.n - 1}/${p.n}.`)] }),
        wholeStep("bias", "Its bias", -p.s2 / p.n, { hint: `Average minus truth: ${((p.n - 1) * p.s2) / p.n} − ${p.s2}.`,
          slips: [slip("sign", p.s2 / p.n, "It runs low, so the bias is negative: −σ²/n.")] }),
        multiStep("mse", "MSE of A and of B", both(mseOf), "whole", { boxes: ["A", "B"], hint: `bias² + SD²: ${sq(A[0])} + ${A[1]}² and ${sq(B[0])} + ${B[1]}².`,
          slips: [slip("bias not squared", both(([b, s]) => b + s * s), "Square the bias too: MSE = bias² + SD²."),
            slip("squared the sum", both(([b, s]) => (b + s) ** 2), "Bias and wobble add in squares, not before squaring."),
            slip("SD not squared", both(([b, s]) => b * b + s), "The variance is SD², so square the SD.")] }),
        tapStep("best", "Better estimator", ["A", "B"], better, { hint: "The smaller MSE misses less on average.",
          slips: [lowBias >= 0 && lowBias !== better && slip("less bias", lowBias, "Lower bias isn't always better: compare the whole MSE.")] }),
      ];
    },
    scene: p => ({ scene: "varest", props: { n: p.n } }),
  },
  oracle: p => {
    const m = (e: [number, number]) => e[0] * e[0] + e[1] * e[1];
    return [((p.n - 1) * p.s2) / p.n, ((p.n - 1) * p.s2) / p.n - p.s2, m(p.A), m(p.B), m(p.A) < m(p.B) ? 0 : 1];
  },
  useIt: {
    say: ["A noisy average has SD 10 and no bias: MSE 100. Shrink it 20% toward a sensible guess 10 below the truth: a bias of −2 appears, but the SD drops to 8.",
      "The MSE is 4 + 64 = 68, less than 100. A little bias bought a lot less wobble."],
    saves: { name: "mse", value: () => 68, note: "the shrunk average's MSE, against 100" },
    scene: { scene: "varest", props: { n: 4 } },
  },
  deeper: [
    "Stein's paradox: estimating three or more means at once, the James–Stein estimator, which shrinks them all toward a common point, beats the plain sample means on total MSE for every possible truth.",
    "The same trade-off rules model fitting: a high-degree polynomial has low bias and huge variance, so it overfits (links b2-ai-09). Among unbiased estimators, the Cramér–Rao bound from b2-pr-09 caps how small the variance can get.",
  ],
};

interface P11 { n: number; vals: number[] }
const REF_VALS = [18, 20, 21, 21, 22, 23, 23, 24, 24, 24, 25, 25, 25, 26, 26, 26, 26, 27, 27, 27, 27, 28, 28, 28, 28, 29, 29, 29, 30, 30, 30, 31, 31, 32, 32, 33, 34, 35, 37, 40];

export const pr11: B2Lesson<P11> = {
  id: "b2-pr-11", track: "pr", unit: 3, title: "The bootstrap",
  youCan: "put error bars on almost any statistic by resampling your own data.",
  needs: ["b2-pr-10"],
  tools: ["boot"],
  play: { scene: "boot", props: {},
    say: "A data table of 10 values. Press Resample: Bento draws 10 values from your 10 with replacement and drops that resample's median on a dot plot. Press it many times: the spread of the dots is the bootstrap's guess at how much the median wobbles." },
  guess: { scene: "boot", props: { quiet: true }, kind: "choice", options: ["0%", "about 10%", "about 35%", "about 50%"], answer: 2,
    ask: "Drawing 10 from 10 with replacement, about what share of your original values get left out of a resample?",
    revealProps: { auto: true },
    reveal: "About 35%: each value is missed by all 10 draws with chance (9/10)¹⁰ ≈ 0.349." },
  nameIt: {
    say: [
      "You can't redraw from the population, so redraw from your sample as if it were the population.",
      "The spread of a statistic across resamples estimates its **standard error**, and the middle of the resample pile gives a **percentile interval**.",
    ],
    formula: ["P(a value is left out) = (1 − 1/n)ⁿ", "distinct resamples = C(2n − 1, n)"],
  },
  workIt: {
    reference: { n: 3, vals: REF_VALS },
    generate(rng, i) {
      const n = i < 3 ? rng.pick([2, 3]) : rng.pick([2, 3, 4, 5, 10]);
      for (;;) {
        const c = rng.int(24, 36), vals = Array.from({ length: 40 }, () => c + rng.int(-6, 6) + rng.int(-4, 4)).sort((a, b) => a - b);
        if (vals[1] !== vals[2] && vals[37] !== vals[38]) return { n, vals };
      }
    },
    show: p => `Resample **${p.n} values** with replacement. Then 40 resample medians, sorted: the lowest five are **${p.vals.slice(0, 5).join(", ")}** and the highest five are **${p.vals.slice(35).join(", ")}**.`,
    steps(p) {
      const out = (1 - 1 / p.n) ** p.n, v = p.vals;
      return [
        numStep("out", "Chance a given value is left out", out, 3, { hint: `Each of ${p.n} draws misses it with chance ${p.n - 1}/${p.n}: (${p.n - 1}/${p.n})^${p.n}.`,
          slips: [slip("one draw", 1 - 1 / p.n, `That's one draw. All ${p.n} draws must miss it: (1 − 1/n)ⁿ.`)] }),
        wholeStep("dist", "Distinct resamples", comb(2 * p.n - 1, p.n), { hint: `Collections of ${p.n} from ${p.n} with repeats: C(${2 * p.n - 1}, ${p.n}).`,
          slips: [slip("ordered", p.n ** p.n, "Order doesn't matter in a resample. Count the different collections: C(2n − 1, n).")] }),
        multiStep("ci", "90% interval", [v[2]!, v[37]!], "whole", { boxes: ["from", "to"], hint: "Drop the lowest 2 and the highest 2 of the 40: the 3rd and the 38th values.",
          slips: [slip("dropped one", [v[1]!, v[38]!], "Drop two from each end; the interval starts at the 3rd value.")] }),
      ];
    },
    scene: () => ({ scene: "boot", props: {} }),
  },
  oracle: p => {
    let missing = 0, total: number;
    if (p.n <= 5) {
      const seen = new Set<string>();
      total = p.n ** p.n;
      for (let c = 0; c < total; c++) {
        const draw: number[] = [];
        let x = c;
        for (let i = 0; i < p.n; i++) { draw.push(x % p.n); x = Math.floor(x / p.n); }
        if (!draw.includes(0)) missing++;
        seen.add([...draw].sort().join(","));
      }
      const s = [...p.vals].sort((a, b) => a - b);
      return [missing / total, seen.size, s[2]!, s[37]!];
    }
    const s = [...p.vals].sort((a, b) => a - b);
    return [(1 - 1 / p.n) ** p.n, comb(2 * p.n - 1, p.n), s[2]!, s[37]!];
  },
  useIt: {
    say: ["Error bars for the median of a made-up set of commute times: 22, 25, 25, 28, 30, 31, 33, 35, 41 and 58 minutes. Resample 2,000 times and take the SD of the medians.",
      "That's the bootstrap's standard error: about 3 minutes."],
    saves: { name: "bootSE", value: () => commuteSE(), unit: "minutes", note: "bootstrap SE of the median commute (made up)" },
    scene: { scene: "boot", props: { data: "commute" } },
  },
  deeper: [
    "As n grows, (1 − 1/n)ⁿ → 1/e ≈ 0.368, so a resample holds about 63.2% of the distinct values. Resampling the data is the plug-in principle: treat the empirical distribution as the population.",
    "The bootstrap fails for the sample maximum and for very heavy tails, and its plain percentile interval can be skewed; BCa intervals correct for that. Bagging and random forests average models fit to resamples (links `ai`).",
  ],
};
export const COMMUTE = [22, 25, 25, 28, 30, 31, 33, 35, 41, 58];
/** the bootstrap SE of the commute median, from a fixed seed so the shelf value is the same every time */
export function commuteSE(): number {
  const rng = seeded(11), meds: number[] = [];
  for (let b = 0; b < 2000; b++) meds.push(median(Array.from({ length: 10 }, () => COMMUTE[rng.int(0, 9)]!)));
  const m = meds.reduce((a, x) => a + x, 0) / meds.length;
  return Math.sqrt(meds.reduce((a, x) => a + (x - m) ** 2, 0) / (meds.length - 1));
}

interface P12 { a: number; b: number; n: number; k: number; later: boolean }

export const pr12: B2Lesson<P12> = {
  id: "b2-pr-12", track: "pr", unit: 3, title: "Bayesian updating with a Beta prior",
  youCan: "update a belief about a chance, flip by flip, and say where it now centers.",
  needs: ["b2-pr-04", "b2-pr-09"],
  tools: ["beta", "like"],
  play: { scene: "beta", props: { a: 2, b: 2 },
    say: "A prior curve over the coin's chance p, shaped by two handles a and b. Feed flips one at a time: each head nudges the curve right, each tail left, and it narrows. The shaded band marks the middle 95%." },
  guess: { scene: "beta", props: { a: 1, b: 1, heads: 3, tails: 0, quiet: true }, kind: "slider", min: 0, max: 1, step: 0.01, start: 0.5, answer: 0.8, near: 0.05, unit: "",
    format: x => `p = ${x.toFixed(2)}`,
    ask: "Start flat. You see 3 heads in 3 flips. Drag to where the posterior's mean lands.",
    reveal: "0.8. The curve peaks at 1, but its mean is (1 + 3)/(2 + 3) = 4/5: the flat prior counts as one head and one tail." },
  nameIt: {
    say: [
      "A **Beta(a, b)** prior works like a + b imaginary flips with a heads. Real data add to the counts.",
      "The **posterior mean** blends the prior's mean and the data's share, and the data's weight grows with n.",
    ],
    formula: ["Beta(a, b) + k heads in n → Beta(a + k, b + n − k)", "posterior mean = (a + k) / (a + b + n)", "data weight = n / (a + b + n)"],
  },
  workIt: {
    reference: { a: 2, b: 2, n: 10, k: 7, later: true },
    generate(rng, i) {
      const n = i < 3 ? rng.int(2, 5) : rng.int(2, 20);
      return { a: i < 3 ? 1 : rng.pick([1, 2, 3, 5]), b: i < 3 ? 1 : rng.pick([1, 2, 3, 5]), n, k: rng.int(0, n), later: i >= 4 };
    },
    show: p => `Prior **Beta(${p.a}, ${p.b})** for a coin's chance of heads. You see **${count(p.k, "head")} in ${p.n} flips**.`,
    steps(p) {
      const A = p.a + p.k, B = p.b + p.n - p.k, tot = p.a + p.b + p.n;
      return [
        wholeStep("a", "New a", A, { hint: `Heads add to a: ${p.a} + ${p.k}.`,
          slips: [slip("tails to a", p.a + p.n - p.k, "Heads add to a, tails to b.")] }),
        wholeStep("b", "New b", B, { hint: `Tails add to b: ${p.b} + ${p.n - p.k}.`,
          slips: [slip("heads to b", p.b + p.k, "Heads add to a, tails to b.")] }),
        fracStep("mean", "Posterior mean", A / tot, { hint: `a over a + b: ${A}/${tot}.`,
          slips: [slip("data alone", p.k / p.n, "That's the data alone. The prior counts too: (a + k)/(a + b + n)."),
            slip("heads only below", A / (p.a + p.b + p.k), "The bottom adds all n flips, heads and tails.")] }),
        ...(p.later ? [fracStep("w", "Weight on the data", p.n / tot, { hint: `n / (a + b + n) = ${p.n}/${tot}.`,
          slips: [slip("prior weight", (p.a + p.b) / tot, "That's the prior's weight. The data's is n/(a + b + n).")] })] : []),
      ];
    },
    scene: p => ({ scene: "beta", props: { a: p.a, b: p.b } }),
  },
  oracle: p => {
    // the Beta mean as B(a + 1, b)/B(a, b), with B(x, y) = (x − 1)!(y − 1)!/(x + y − 1)!
    const f = (n: number) => { let r = 1; for (let i = 2; i <= n; i++) r *= i; return r; };
    const Bf = (x: number, y: number) => (f(x - 1) * f(y - 1)) / f(x + y - 1);
    const A = p.a + p.k, B = p.b + p.n - p.k;
    return [A, B, Bf(A + 1, B) / Bf(A, B), ...(p.later ? [p.n / (p.a + p.b + p.n)] : [])];
  },
  useIt: {
    say: ["Two made-up restaurants: one has 4 reviews, all good; the other has 200, of which 190 are good. With a flat prior, the first's posterior mean is 5/6 ≈ 0.833 and the second's is 191/202 ≈ 0.946.",
      "Project: Honest error bars. One made-up data set, three answers side by side: the maximum likelihood estimate, a bootstrap interval and a Bayesian credible interval. Save it to keep `bootSE` and `postMean`: Luck detector v1."],
    saves: { name: "postMean", value: () => 191 / 202, note: "the 200-review restaurant's posterior mean" },
    project: "pr-errbars",
  },
  deeper: [
    "Conjugate pairs keep the posterior in the prior's family: Gamma–Poisson, Normal–Normal, Dirichlet–multinomial. The last one is add-one smoothing in language models.",
    "A 95% credible interval says where p is, given the data; a confidence interval is a recipe that catches p 95% of the time. With lots of data they agree: the posterior becomes a normal centered at the MLE (Bernstein–von Mises).",
    "Thompson sampling picks between options by drawing from each posterior, learning while choosing (links `ai`). Posteriors with no formula are sampled by MCMC (b2-pr-19).",
  ],
};

/* ------------------------------------------------------------------ unit 4 ------------------------------------------------------------------ */

interface P13 { T: number[]; C: number[] }
/** every way to pick 3 treated from the values, as bitmasks */
function splits3(vals: number[]): number[][] {
  const out: number[][] = [];
  for (let m = 0; m < 1 << vals.length; m++) {
    let bits = 0; for (let i = 0; i < vals.length; i++) if ((m >> i) & 1) bits++;
    if (bits === 3) out.push(vals.filter((_, i) => (m >> i) & 1));
  }
  return out;
}
const sum = (xs: number[]) => xs.reduce((a, b) => a + b, 0);

export const pr13: B2Lesson<P13> = {
  id: "b2-pr-13", track: "pr", unit: 4, title: "The shuffle test",
  youCan: "get an exact p-value by checking every way the labels could have fallen.",
  needs: ["st-testprop", "st-experiment"],
  tools: ["shuffle"],
  play: { scene: "shuffle", props: {},
    say: "Two groups of value chips, treated and control, with the gap between their means. Press Shuffle: the labels are dealt out again at random and the new gap drops onto a dot plot. Press \"List every split\" and all of them appear, with the real gap marked." },
  guess: { scene: "shuffle", props: { quiet: true }, kind: "slider", min: 0, max: 50, step: 1, start: 25, answer: 10, near: 5, unit: "%",
    ask: "Treated {10, 15, 18} beat control {5, 8, 12} by a gap of 6. Drag to guess what share of random splits do at least as well.",
    revealProps: { all: true },
    reveal: "10%: of the 20 splits, only {12, 15, 18} and {10, 15, 18} reach a gap of 6." },
  nameIt: {
    say: [
      "If the treatment did nothing, each value would have been the same under either label, so every split was equally likely.",
      "The **p-value** is the share of splits at least as extreme as the one you got. This **permutation test** needs nothing but random assignment.",
    ],
    formula: ["splits = C(n₁ + n₂, n₁)", "p = (splits at least as extreme) / (all splits)"],
  },
  workIt: {
    reference: { T: [10, 15, 18], C: [5, 8, 12] },
    generate(rng, i) {
      const total = i >= 6 ? 7 : 6;
      for (;;) {
        const vals = rng.shuffle(Array.from({ length: 20 }, (_, k) => k + 1)).slice(0, total).sort((a, b) => a - b);
        const all = splits3(vals), sums = all.map(sum);
        const ok = all.filter(t => { const c = sums.filter(s => s >= sum(t)).length; return c >= 1 && c <= 4; });
        if (!ok.length) continue;
        const T = rng.pick(ok);
        return { T, C: vals.filter(v => !T.includes(v)) };
      }
    },
    show: p => `Treated: **${p.T.join(", ")}**. Control: **${p.C.join(", ")}** (made up; higher is better). One-sided: did treated do better?`,
    steps(p) {
      const vals = [...p.T, ...p.C], all = splits3(vals), obs = sum(p.T), splits = all.length;
      const atLeast = all.filter(t => sum(t) >= obs).length, above = all.filter(t => sum(t) > obs).length;
      const gap = obs / p.T.length - sum(p.C) / p.C.length, pv = atLeast / splits;
      return [
        wholeStep("splits", "Number of splits", splits, { hint: `Choose which 3 of the ${vals.length} are treated: C(${vals.length}, 3).`,
          slips: [slip("ordered", vals.length === 6 ? 720 : 5040, `Order inside a group doesn't matter: choose which 3 are treated, C(${vals.length}, 3) = ${splits}.`)] }),
        numStep("gap", "Observed gap", gap, 2, { hint: `Mean of treated minus mean of control: ${trim(obs / 3, 2)} − ${trim(sum(p.C) / p.C.length, 2)}.` }),
        wholeStep("count", "Splits at least as extreme", atLeast, { hint: `Count the 3-value groups whose sum is ${obs} or more, the real one included.`,
          slips: [slip("only bigger", above, "At least as extreme includes the split you saw. Count ties too.")] }),
        fracStep("p", "p-value", pv, { hint: `${atLeast} out of ${splits}.`,
          slips: [slip("count", atLeast, `Divide by all ${splits} splits.`)] }),
        tapStep("call", "At α = 0.05?", ["Reject", "Don't reject"], pv <= 0.05 ? 0 : 1, { hint: `Reject when p ≤ 0.05. Here p = ${fr(pv)}.` }),
      ];
    },
    scene: p => ({ scene: "shuffle", props: { t: p.T.join(","), c: p.C.join(",") } }),
  },
  oracle: p => {
    // brute force: every bitmask over the pooled values with exactly |T| treated
    const vals = [...p.T, ...p.C], n = vals.length, obs = sum(p.T);
    let all = 0, hit = 0;
    for (let m = 0; m < 1 << n; m++) {
      const picked = vals.filter((_, i) => (m >> i) & 1);
      if (picked.length !== p.T.length) continue;
      all++; if (sum(picked) >= obs) hit++;
    }
    return [all, obs / p.T.length - sum(p.C) / p.C.length, hit, hit / all, hit / all <= 0.05 ? 0 : 1];
  },
  useIt: {
    say: ["A made-up fertilizer trial with 3 and 3 plants. Even the most lopsided split, every big plant treated, gives p = 1/20 = 0.05.",
      "Tiny experiments can't reach small p-values, however strong the effect. This is the Luck detector's test stage."],
    saves: { name: "pPerm", value: () => 1 / 20, note: "the smallest p a 3 and 3 shuffle test can give" },
    scene: { scene: "shuffle", props: { t: "14,17,19", c: "6,9,11" } },
  },
  deeper: [
    "Fisher's sharp null says the treatment changed nothing for anyone. Under random assignment every split was equally likely (exchangeability), so the p-value is exact, with no normal curve anywhere.",
    "With too many splits to list, shuffle B times at random: the p-value's error is √(p(1 − p)/B), the 1/√n rule from b2-pr-01. Rank tests (Wilcoxon–Mann–Whitney) are shuffle tests on ranks, and the t-test approximates the shuffle test as n grows.",
  ],
};

interface P14 { sigma: number; n: number; shift: number; r: number; d2: number }
const SHIFTS = [0.96, 1.46, 1.96, 2.46, 2.8, 2.96, 3.96];
const seOf = (p: P14) => p.sigma / Math.sqrt(p.n);
const nPlan = (r: number) => Math.ceil(784 * r * r / 100 - 1e-9);

export const pr14: B2Lesson<P14> = {
  id: "b2-pr-14", track: "pr", unit: 4, title: "Power: will you catch it if it's there?",
  youCan: "find the chance an experiment detects a real effect, and the sample size it needs.",
  needs: ["b2-pr-07", "st-testprop"],
  tools: ["power", "graph2d"],
  play: { scene: "power", props: {},
    say: "Two bells, one for \"no effect\" and one shifted by the real effect δ, with a cutoff line at z = 1.96. Drag δ, σ and n: the bells narrow as n grows, and the shaded area of the second bell past the cutoff, the power, grows." },
  guess: { scene: "power", props: { delta: 3.92, sigma: 20, n: 100, quiet: true }, kind: "choice", options: ["about 70%", "about 85%", "about 97%", "100%"], answer: 2,
    ask: "Power is 50% now. If you quadruple n, what does it become?",
    revealProps: { n: 400 },
    reveal: "About 97%. Four times n halves the SE, so the shift doubles from 1.96 to 3.92, and the power reads 97.5%." },
  nameIt: {
    say: [
      "**Power** is the chance your test says \"real\" when the effect is real. It grows with the effect and with √n and shrinks with σ.",
      "Plan n before you run: for a two-sided 5% test and 80% power, the effect needs to be 2.8 standard errors.",
    ],
    formula: ["SE = σ/√n", "shift = δ/SE", "power ≈ P(Z > 1.96 − shift)", "n = (1.96 + 0.84)² (σ/δ)² = 7.84 (σ/δ)²"],
  },
  workIt: {
    reference: { sigma: 20, n: 100, shift: 2.8, r: 5, d2: 2 },
    generate(rng, i) {
      const r = rng.pick([1, 2, 2.5, 5, 10]);
      return { sigma: rng.pick([10, 20, 30]), n: rng.pick([16, 25, 100, 400]), shift: rng.pick(i < 3 ? [1.96, 2.96] : SHIFTS), r, d2: r === 2.5 ? rng.pick([2, 4]) : rng.pick([1, 2, 4, 5]) };
    },
    show: p => `A test of a mean with **σ = ${p.sigma}** and **n = ${p.n}**, two-sided at 5%. The real effect is **δ = ${trim(p.shift * seOf(p), 4)}**.`,
    steps(p) {
      const se = seOf(p), delta = p.shift * se, pw = Math.round((1 - Phi(1.96 - p.shift)) * 1e4) / 1e4;
      const table = [[1, 0.1587], [0.5, 0.3085], [0, 0.5], [-0.5, 0.6915], [-0.84, 0.7995], [-1, 0.8413], [-2, 0.9772]].find(([z]) => Math.abs(z! - (1.96 - p.shift)) < 1e-9)![1]!;
      const s2 = p.r * p.d2;
      return [
        numStep("se", "SE", se, 2, { hint: `σ/√n = ${p.sigma}/√${p.n}.`,
          slips: [slip("over n", p.sigma / p.n, `Divide by √n: √${p.n} = ${Math.sqrt(p.n)}.`)] }),
        numStep("shift", "Shift", p.shift, 2, { hint: `δ/SE = ${trim(delta, 4)}/${trim(se, 2)}.`,
          slips: [slip("over σ", delta / p.sigma, `Measure the effect in standard errors: divide by SE = ${trim(se, 2)}, not σ.`)] }),
        numStep("pw", "Power", table, 4, { hint: `P(Z > 1.96 − ${trim(p.shift, 2)}) = P(Z > ${trim(1.96 - p.shift, 2)}), from the table.`,
          slips: [slip("alpha", 0.05, "α is the false-alarm chance when there's no effect. Power is the hit chance when there is one."),
            slip("wrong tail", Math.round((1 - pw) * 1e4) / 1e4, "Power is the area of the shifted bell past the cutoff, the upper side.")] }),
        wholeStep("plan", `New plan: n for 80% power with σ = ${s2} and δ = ${p.d2}`, nPlan(p.r), { hint: `7.84 × (${s2}/${p.d2})², rounded up.`,
          slips: [slip("not squared", 2.8 * p.r, "n grows with the square: (2.8 σ/δ)²."), slip("no 7.84", p.r * p.r, "Multiply by 7.84 = (1.96 + 0.84)².")] }),
      ];
    },
    scene: p => ({ scene: "power", props: { delta: p.shift * seOf(p), sigma: p.sigma, n: p.n } }),
  },
  oracle: p => [p.sigma / Math.sqrt(p.n), (p.shift * p.sigma / Math.sqrt(p.n)) / (p.sigma / Math.sqrt(p.n)), Math.round((1 - Phi(1.96 - p.shift)) * 1e4) / 1e4, Math.ceil(7.84 * p.r ** 2 - 1e-9)],
  useIt: {
    say: ["Plan a made-up experiment before running it: to catch a 2-point effect with SD 10 at 80% power, n = 7.84 × (10/2)² = 196.",
      "This is the Luck detector's plan stage: decide n first, so the data can't talk you into stopping early."],
    saves: { name: "nNeeded", value: () => 196, note: "n for 80% power, δ = 2 and σ = 10" },
    scene: { scene: "power", props: { delta: 2, sigma: 10, n: 196 } },
  },
  deeper: [
    "The winner's curse: when power is low, the results that pass the cutoff overstate the effect (a type M error), and some even get its sign wrong (type S). That's one reason fields full of small studies fail to replicate.",
    "Power curves plot power against n or δ for a fixed test. With an estimated σ, the shifted bell is a noncentral t instead of a normal.",
  ],
};

interface P15 { m: number; ps: number[]; gap: boolean }
const firstRun = (ps: number[], q: number) => { const m = ps.length; let r = 0; for (let i = 0; i < m; i++) { if (ps[i]! <= ((i + 1) * q) / m + 1e-12) r = i + 1; else break; } return r; };
const bh = (ps: number[], q: number) => { const m = ps.length; for (let i = m; i >= 1; i--) if (ps[i - 1]! <= (i * q) / m + 1e-12) return i; return 0; };

export const pr15: B2Lesson<P15> = {
  id: "b2-pr-15", track: "pr", unit: 4, title: "Many tests, many lucky winners",
  youCan: "correct for running many tests so luck doesn't pass for discovery.",
  needs: ["b2-pr-13", "st-testprop"],
  tools: ["sim", "shelf"],
  play: { scene: "sim", props: { mode: "wall", m: 20 },
    say: "Run m tests where nothing is real. Their p-values stand as a row of bars, and a few dip under 0.05 by luck. Drag m from 1 to 100, and turn on the Bonferroni line and the Benjamini–Hochberg staircase. In Peek mode, one experiment is checked after every 10 people and stopped at the first p < 0.05." },
  guess: { scene: "sim", props: { mode: "wall", m: 20, quiet: true }, kind: "slider", min: 0, max: 100, step: 1, start: 20, answer: 64.15, near: 8, unit: "%",
    ask: "20 tests, no real effects, each at α = 0.05. What's the chance at least one comes up \"significant\"?",
    revealProps: { many: true },
    reveal: "About 64%: each test stays quiet with chance 0.95, all 20 with 0.95²⁰ ≈ 0.36." },
  nameIt: {
    say: [
      "Test enough things and luck will hand you a winner. The chance of at least one false alarm is the **family-wise error rate**.",
      "**Bonferroni** tests each at α/m. **Benjamini–Hochberg** controls the share of false discoveries among your discoveries instead. Peeking is many tests in disguise.",
    ],
    formula: ["P(at least one) = 1 − (1 − α)ᵐ", "Bonferroni α/m", "BH: sort p₍₁₎ ≤ … ≤ p₍ₘ₎, find the largest i with p₍ᵢ₎ ≤ iq/m, reject 1 to i"],
  },
  workIt: {
    reference: { m: 20, ps: [0.005, 0.03, 0.035, 0.6], gap: true },
    generate(rng, i) {
      const m = i < 3 ? rng.pick([2, 5]) : rng.pick([2, 5, 10, 20, 50]);
      const m2 = rng.pick([4, 5, 6, 8]), wantGap = i >= 3 && rng.next() < 0.5;
      for (;;) {
        const th = Array.from({ length: m2 }, () => (rng.next() < 0.55 ? rng.int(1, 60) : rng.int(61, 900))).sort((a, b) => a - b);
        if (new Set(th).size < m2) continue;
        if (th.some((t, k) => Math.abs(t - (50 * (k + 1)) / m2) < 0.5 || Math.abs(t - 50 / m2) < 0.5)) continue;
        const ps = th.map(t => t / 1000);
        if ((firstRun(ps, 0.05) !== bh(ps, 0.05)) === wantGap) return { m, ps, gap: wantGap };
      }
    },
    show: p => `**${p.m} tests**, no real effects, each at α = 0.05. A second study ran **${p.ps.length} tests** and got these sorted p-values: **${p.ps.map(x => trim(x, 3)).join(", ")}** (q = 0.05).`,
    steps(p) {
      const m2 = p.ps.length, bonf = p.ps.filter(x => x <= 0.05 / m2).length, plain = p.ps.filter(x => x <= 0.05).length;
      const lines = Array.from({ length: m2 }, (_, k) => trim((0.05 * (k + 1)) / m2, 4)).join(", ");
      return [
        numStep("exp", "Expected false alarms", p.m * 0.05, 2, { hint: `m × α = ${p.m} × 0.05.`, done: `Expected false alarms: ${trim(p.m * 0.05)}` }),
        numStep("one", "P(at least one)", 1 - 0.95 ** p.m, 4, { hint: `1 − 0.95^${p.m}.`,
          slips: [slip("mα", p.m * 0.05, "mα is the expected count, and it can pass 1. The chance of at least one is 1 − (1 − α)ᵐ.")] }),
        numStep("bonf", "Bonferroni cutoff", 0.05 / p.m, 4, { hint: `α/m = 0.05/${p.m}.`, done: `Bonferroni cutoff: ${trim(0.05 / p.m, 4)}`,
          slips: [slip("plain α", 0.05, `Bonferroni splits α across all ${p.m} tests.`)] }),
        wholeStep("b2", "Second study: rejected by Bonferroni", bonf, { hint: `Count the p-values at or below 0.05/${m2} = ${trim(0.05 / m2, 4)}.`,
          slips: [slip("plain α", plain, `Bonferroni splits α across all ${m2} tests.`)] }),
        wholeStep("bh", "Second study: rejected by BH", bh(p.ps, 0.05), { hint: `The lines iq/m are ${lines}. Find the largest i whose p-value is under its line.`,
          slips: [slip("stopped early", firstRun(p.ps, 0.05), "BH takes the largest i that passes, even after a miss: reject everything up to it.")] }),
      ];
    },
    scene: p => ({ scene: "sim", props: { mode: "wall", m: p.m } }),
  },
  oracle: p => {
    let quiet = 1; for (let i = 0; i < p.m; i++) quiet *= 0.95;
    const m2 = p.ps.length;
    // BH by its rule: walk every i, keep the largest that passes
    let r = 0; p.ps.forEach((x, k) => { if (x <= (0.05 * (k + 1)) / m2 + 1e-12) r = k + 1; });
    return [p.m * 0.05, 1 - quiet, 0.05 / p.m, p.ps.filter(x => x * m2 <= 0.05 + 1e-12).length, r];
  },
  useIt: {
    say: ["A made-up dashboard tracks 12 metrics after a redesign, and two show p < 0.05: 0.003 and 0.04. BH's lines start at 0.05/12 ≈ 0.0042 and 0.0083.",
      "0.003 survives and 0.04 doesn't: one discovery, not two. This is the Luck detector's correction stage."],
    saves: { name: "fdrCut", value: () => 0.05 / 12, note: "BH's first line for 12 metrics" },
    scene: { scene: "sim", props: { mode: "wall", m: 12 } },
  },
  deeper: [
    "For independent tests, BH keeps the false discovery rate at q · m₀/m, where m₀ counts the true nulls. Holm's step-down method controls the family-wise rate and always rejects at least as much as Bonferroni.",
    "The garden of forking paths: every analysis choice made after seeing the data is a hidden test. Optional stopping inflates false alarms too: with unlimited peeks a null experiment is eventually always \"significant\". Always-valid p-values and alpha spending fix it (links b2-pr-19, martingales).",
  ],
};

interface P16 { kind: "a" | "b"; r: number; pw: number; n: number; k: number; prior: number }

export const pr16: B2Lesson<P16> = {
  id: "b2-pr-16", track: "pr", unit: 4, title: "Evidence: likelihood ratios and Bayes factors",
  youCan: "say how strongly data favor one explanation over another, and why p = 0.05 isn't a 5% chance of luck.",
  needs: ["b2-pr-04", "b2-pr-09", "b2-pr-14"],
  tools: ["bayes", "like"],
  play: { scene: "bayes", props: { mode: "ideas", real: 10, power: 80, alpha: 5 },
    say: "1,000 ideas get tested. Drag what share are really true, the power and α: the box splits them by real or not and significant or not, and boxes the significant ones. Then open the Likelihood viewer's evidence walk and watch fair against loaded play out flip by flip." },
  guess: { scene: "bayes", props: { mode: "ideas", real: 10, power: 80, alpha: 5, quiet: true }, kind: "slider", min: 0, max: 100, step: 1, start: 5, answer: 36, near: 8, unit: "%",
    ask: "10% of ideas tested are real, power is 80% and α is 5%. Of the significant results, what share are false?",
    reveal: "36%. The box lights 80 real hits and 45 false ones, and 45 of the 125 hits are false." },
  nameIt: {
    say: [
      "A p-value is the chance of data this extreme if it's luck, not the chance it's luck given the data.",
      "The **likelihood ratio** compares how well two explanations predict what you saw. Between two hypotheses it's the **Bayes factor**, and it multiplies your prior odds.",
    ],
    formula: ["false share of hits = (1 − r)α / ((1 − r)α + r · power)", "BF = P(data | H₁) / P(data | H₀)", "posterior odds = prior odds × BF"],
  },
  workIt: {
    reference: { kind: "a", r: 10, pw: 80, n: 10, k: 8, prior: 1 },
    generate(rng, i) {
      if (i < 3) return { kind: "a", r: 50, pw: rng.pick([50, 80]), n: 0, k: 0, prior: 1 };
      if (rng.next() < 0.5) return { kind: "a", r: rng.pick([10, 20, 50]), pw: rng.pick([50, 80]), n: 0, k: 0, prior: 1 };
      const n = rng.int(2, 10);
      return { kind: "b", r: 0, pw: 0, n, k: rng.int(Math.max(0, n - 3), n), prior: rng.pick([1, 4, 9]) };
    },
    show: p => p.kind === "a" ? `**1,000 ideas** get tested (made up). **${p.r}%** are really true, the power is **${p.pw}%** and α is **5%**.`
      : `A coin is either fair (p = 1/2) or loaded (p = 3/4). It shows **${count(p.k, "head")} in ${p.n} flips**. Prior odds, loaded to fair: **${p.prior === 1 ? "1" : `1/${p.prior}`}**.`,
    steps(p) {
      if (p.kind === "a") {
        const real = 10 * p.r, hits = (real * p.pw) / 100, fls = (1000 - real) * 0.05;
        return [
          wholeStep("real", "Real ideas", real, { hint: `${p.r}% of 1,000.` }),
          wholeStep("hits", "Real hits", hits, { hint: `Power catches ${p.pw}% of the ${real} real ones.`,
            slips: [slip("alpha", real * 0.05, "Real ideas pass at the power's rate, not α.")] }),
          wholeStep("false", "False hits", fls, { hint: `α lets 5% of the ${1000 - real} ideas that aren't real through.`,
            slips: [slip("all", 50, `False hits come from the ${1000 - real} ideas that aren't real, not all 1,000.`)] }),
          numStep("share", "Share of hits that are false", (100 * fls) / (fls + hits), 1, { unit: "%", done: `Share of hits that are false: ${trim((100 * fls) / (fls + hits), 1)}%`, hint: `False hits over all hits: ${fls} / ${fls + hits}.`,
            slips: [slip("alpha", 5, "α is the false-alarm rate among ideas that aren't real, not among the hits."),
              slip("true share", (100 * hits) / (fls + hits), "That's the share of hits that are real. Take the false ones.")] }),
        ];
      }
      const bf = 3 ** p.k / 2 ** p.n, odds = bf / p.prior, ch = odds / (1 + odds);
      return [
        numStep("bf", "BF", bf, 2, { hint: `(3/4)^${p.k}(1/4)^${p.n - p.k} over (1/2)^${p.n} = 3^${p.k}/2^${p.n}.`,
          slips: [slip("flipped", 1 / bf, "BF puts the loaded coin on top: P(data | p = 3/4) over P(data | p = 1/2).")] }),
        fracStep("odds", "Posterior odds", odds, { ask: "As a fraction.", hint: p.prior === 1 ? `Prior odds × BF = 1 × ${3 ** p.k}/${2 ** p.n}.` : `Prior odds × BF = ${3 ** p.k}/${2 ** p.n} × 1/${p.prior}.`,
          slips: [p.prior !== 1 && slip("no prior", bf, `Multiply by the prior odds, 1/${p.prior}.`)] }),
        numStep("ch", "Posterior chance it's loaded", ch, 3, { hint: "odds / (1 + odds).",
          slips: [slip("odds", odds, `Odds of 3 mean 3 to 1, a chance of 3/4. Divide by 1 + odds.`)] }),
      ];
    },
    scene: (p): SceneRef => p.kind === "a" ? { scene: "bayes", props: { mode: "ideas", real: p.r, power: p.pw, alpha: 5 } } : { scene: "like", props: { mode: "walk" } },
  },
  oracle: p => {
    if (p.kind === "a") {
      const r = p.r / 100, pw = p.pw / 100;
      return [1000 * r, 1000 * r * pw, 1000 * (1 - r) * 0.05, (100 * (1 - r) * 0.05) / ((1 - r) * 0.05 + r * pw)];
    }
    const L1 = 0.75 ** p.k * 0.25 ** (p.n - p.k), L0 = 0.5 ** p.n, bf = L1 / L0, odds = bf / p.prior;
    return [bf, odds, odds / (1 + odds)];
  },
  useIt: {
    say: ["A made-up headline says \"Study finds X, p = 0.04\". If 10% of ideas like X pan out and the study's power was 50%, the false share of hits is 45/(45 + 50) ≈ 47%: X is barely better than a coin flip.",
      "Project: Loaded-coin court. Plan the flips, run them, and give a verdict with a p-value, a Bayes factor and the chance the coin is loaded. Then Bento reveals the truth: Luck detector v2."],
    saves: { name: "fdrField", value: () => 45 / 95, note: "false share of hits: 10% real, 50% power" },
    project: "pr-court",
  },
  deeper: [
    "The Neyman–Pearson lemma: at a fixed α, the likelihood ratio test is the most powerful test. Wald's sequential test watches the running log likelihood ratio and stops at lines near ln((1 − β)/α) and ln(β/(1 − α)).",
    "Lindley's paradox: with huge n, a result can be \"significant\" at 5% while the Bayes factor favors the null. The Sellke–Bayarri–Berger bound, BF ≤ 1/(−e p ln p), says p = 0.05 is worth at most about 2.46 to 1. Log Bayes factors are weight of evidence in bits (links `in`).",
  ],
};

/* ------------------------------------------------------------------ unit 5 ------------------------------------------------------------------ */

interface P17 { T: number; N: number; z1: number }
const PAIRS17: [number, number][] = [[8, 8], [3, 1], [20, 5], [16, 9], [9, 16], [64, 36]];
const sd17 = (p: P17) => Math.sqrt(p.T + p.N);

export const pr17: B2Lesson<P17> = {
  id: "b2-pr-17", track: "pr", unit: 5, title: "Regression to the mean",
  youCan: "spot an \"effect\" that is really extremes drifting back toward average.",
  needs: ["b2-pr-08"],
  tools: ["retest", "cloud"],
  play: { scene: "retest", props: { skill: 0.5 },
    say: "Each person's score is skill plus luck, on two tests. Drag the share of the score that is skill. Brush the top 10% on test 1, and their test 2 scores appear beside them: lower on average, with no treatment at all." },
  guess: { scene: "retest", props: { skill: 0.5, quiet: true }, kind: "slider", min: 0, max: 3, step: 0.05, start: 2, answer: 1, near: 0.2, unit: "SDs up",
    format: x => x.toFixed(2),
    ask: "The top group averaged 2 SDs above the mean on test 1, and the tests correlate at 0.5. Drag where they land on test 2.",
    reveal: "1 SD above. They keep their skill but not their luck, so they land ρ × 2 = 1 SD up." },
  nameIt: {
    say: [
      "When two measures correlate at less than 1, people picked for being extreme on one are, on average, less extreme on the other. That's **regression to the mean**.",
      "It isn't a force; it's selecting on luck. Only a comparison group can separate it from a real effect.",
    ],
    formula: ["ρ = Var(skill) / (Var(skill) + Var(luck))", "expected z₂ = ρ z₁"],
  },
  workIt: {
    reference: { T: 16, N: 9, z1: 2 },
    generate(rng, i) {
      const [T, N] = rng.pick(i < 3 ? PAIRS17.slice(0, 2) : PAIRS17);
      return { T, N, z1: rng.pick([1, 2, 3, -2]) };
    },
    show: p => `Score = skill + luck (made up): Var(skill) = **${p.T}**, Var(luck) = **${p.N}**, and the mean is 100. A group is picked for scoring **${100 + p.z1 * sd17(p)}** on test 1.`,
    steps(p) {
      const rho = p.T / (p.T + p.N), x = 100 + p.z1 * sd17(p), y = 100 + rho * (x - 100);
      return [
        numStep("rho", "ρ", rho, 2, { hint: `The tests share the skill: ${p.T} / (${p.T} + ${p.N}).`,
          slips: [slip("squared", rho * rho, "The tests share the skill part: ρ = T/(T + N), not its square."),
            slip("T over N", p.T / p.N, "Divide by the whole variance, T + N.")] }),
        numStep("z2", "Expected z on test 2", rho * p.z1, 2, { hint: `z₁ = (${x} − 100)/${sd17(p)} = ${p.z1}; multiply by ρ.`,
          slips: [slip("kept z", p.z1, "They don't keep their luck. Expect ρz₁, closer to the mean.")] }),
        numStep("y", "Expected test 2 score", y, 1, { hint: `100 ${signTerm(rho * (x - 100), `${trim(rho, 2)} × ${Math.abs(x - 100)}`)}.`,
          slips: [slip("kept score", x, "They don't keep their luck. Expect ρz₁, closer to the mean.")] }),
        tapStep("coach", "A coach praised the top group and they got worse. Did praise hurt?", ["Yes", "No, it helped", "Can't tell without a comparison group"], 2, {
          hint: "They would drift back without any praise at all.",
          slips: [slip("blamed praise", 0, "The drop is what regression to the mean predicts with no praise at all. Only a comparison group can tell.")] }),
      ];
    },
    scene: p => ({ scene: "retest", props: { skill: p.T / (p.T + p.N) } }),
  },
  oracle: p => { const x = 100 + p.z1 * Math.sqrt(p.T + p.N), r = p.T / (p.T + p.N); return [r, (r * (x - 100)) / Math.sqrt(p.T + p.N), 100 + r * (x - 100), 2]; },
  useIt: {
    say: ["A made-up story: the 10 worst-scoring schools get a new program and improve the next year. If scores are half skill (ρ = 0.5), a group 2 SDs below average would come back halfway, to 1 SD below, with no program at all.",
      "The Luck detector raises a flag when a study picks its subjects for being extreme."],
    saves: { name: "rtmShrink", value: () => 0.5, note: "the share of an extreme group's gap that stays" },
    scene: { scene: "retest", props: { skill: 0.5, low: true } },
  },
  deeper: [
    "Kelley's formula, true score ≈ ρx + (1 − ρ)μ, is shrinkage toward the mean. Empirical Bayes generalizes it to many groups at once, the same move as James–Stein (b2-pr-10).",
    "Galton found regression with heights: very tall parents had tall children, but closer to average. It shows up in sports streaks, the \"cover jinx\" and every \"most improved\" list.",
  ],
};

interface P18 { am: number; as: number; bm: number; bs: number; ra: [number, number]; rb: [number, number] }
const r1 = (x: number) => Math.round(x * 10) / 10;

export const pr18: B2Lesson<P18> = {
  id: "b2-pr-18", track: "pr", unit: 5, title: "Simpson's paradox and confounding",
  youCan: "catch a comparison that flips once you account for a hidden group.",
  needs: ["st-probrules", "st-experiment"],
  tools: ["simpson", "shelf"],
  play: { scene: "simpson", props: {},
    say: "Two treatments, each used on mild and severe cases. Drag how many severe cases each treatment gets. The bars for mild only and severe only don't move, but the overall bars can flip. The arrows show severity pointing at both the treatment choice and the outcome." },
  guess: { scene: "simpson", props: { quiet: true, sa: 20, sb: 20 }, kind: "choice", options: ["Yes", "No"], answer: 0,
    ask: "Treatment A beats B among mild cases and among severe cases. Can B still win overall?",
    revealProps: { sa: 80, sb: 20 },
    reveal: "Yes. Give A most of the severe cases and its overall rate sinks below B's, though A wins in both groups." },
  nameIt: {
    say: [
      "A **confounder** affects both who gets a treatment and how they do. It can reverse a comparison when groups are pooled: **Simpson's paradox**.",
      "The fix is to compare within groups, then reweight to one common mix (**adjustment**). Random assignment cuts the arrow from the confounder to the treatment.",
    ],
    formula: ["adjusted rate = Σ_g P(success | treatment, g) · P(g)"],
  },
  workIt: {
    reference: { am: 20, as: 80, bm: 80, bs: 20, ra: [90, 50], rb: [80, 40] },
    generate(rng, i) {
      const wantRev = i < 3 || rng.next() < 2 / 3;
      for (;;) {
        const am = i < 3 ? rng.int(1, 9) * 10 : rng.int(1, 9) * 10, as = i < 3 ? 100 - am : rng.int(1, 9) * 10;
        const bm = i < 3 ? rng.int(1, 9) * 10 : rng.int(1, 9) * 10, bs = i < 3 ? 100 - bm : rng.int(1, 9) * 10;
        const lo = [rng.int(2, 8) * 10, rng.int(1, 6) * 10] as [number, number];
        const hi = [lo[0] + rng.int(1, 9 - lo[0] / 10) * 10, lo[1] + rng.int(1, 3) * 10] as [number, number];
        if (hi[0] > 90 || hi[1] > 90 || hi[1] >= hi[0] || lo[1] >= lo[0]) continue;
        const aWins = rng.next() < 0.5, ra = aWins ? hi : lo, rb = aWins ? lo : hi;
        const A = (am * ra[0] + as * ra[1]) / (am + as), B = (bm * rb[0] + bs * rb[1]) / (bm + bs);
        if (Math.abs(A - B) < 1) continue;
        if (((A > B) !== aWins) === wantRev) return { am, as, bm, bs, ra, rb };
      }
    },
    show: p => `Made-up results. **A**: mild ${p.am * p.ra[0] / 100} of ${p.am} recover, severe ${p.as * p.ra[1] / 100} of ${p.as}. **B**: mild ${p.bm * p.rb[0] / 100} of ${p.bm}, severe ${p.bs * p.rb[1] / 100} of ${p.bs}.`,
    steps(p) {
      const A = (p.am * p.ra[0] + p.as * p.ra[1]) / (p.am + p.as), B = (p.bm * p.rb[0] + p.bs * p.rb[1]) / (p.bm + p.bs);
      const tot = p.am + p.as + p.bm + p.bs, wm = (p.am + p.bm) / tot, ws = 1 - wm;
      const adjA = p.ra[0] * wm + p.ra[1] * ws, adjB = p.rb[0] * wm + p.rb[1] * ws;
      const better = adjA > adjB ? 0 : 1, overall = A > B ? 0 : 1;
      const pct = (lab: string, r: number, s: number, n: number) => wholeStep(lab, lab, r, { unit: "%", hint: `${s} of ${n}.`, done: `${lab}: ${r}%`,
        slips: [slip("count", s, `That's the count. As a percent: ${s}/${n}.`)] });
      return [
        pct("A, mild", p.ra[0], (p.am * p.ra[0]) / 100, p.am),
        pct("A, severe", p.ra[1], (p.as * p.ra[1]) / 100, p.as),
        pct("B, mild", p.rb[0], (p.bm * p.rb[0]) / 100, p.bm),
        pct("B, severe", p.rb[1], (p.bs * p.rb[1]) / 100, p.bs),
        multiStep("overall", "A overall and B overall", [A, B], 1, { unit: "%", boxes: ["A", "B"], hint: `Total recovered over total patients: ${(p.am * p.ra[0] + p.as * p.ra[1]) / 100} of ${p.am + p.as}, and ${(p.bm * p.rb[0] + p.bs * p.rb[1]) / 100} of ${p.bm + p.bs}.`,
          done: `Overall: ${trim(r1(A), 1)}% for A, ${trim(r1(B), 1)}% for B`,
          slips: [slip("averaged", [(p.ra[0] + p.ra[1]) / 2, (p.rb[0] + p.rb[1]) / 2], "Overall weighs groups by size: total successes over total patients.")] }),
        multiStep("adj", "Adjusted A and adjusted B", [adjA, adjB], 1, { unit: "%", boxes: ["A", "B"],
          hint: `The pooled mix is ${p.am + p.bm} mild and ${p.as + p.bs} severe out of ${tot}. Weight each treatment's two rates by it.`,
          done: `Adjusted: ${trim(r1(adjA), 1)}% for A, ${trim(r1(adjB), 1)}% for B`,
          slips: [slip("own mix", [A, B], "Adjustment uses one common mix for both, or the comparison stays tilted.")] }),
        tapStep("which", "Which is better?", ["A", "B"], better, { hint: "Compare within groups, or after adjusting.",
          slips: [overall !== better && slip("overall", overall, "The groups differ in how sick they are. Compare within groups or after adjusting.")] }),
      ];
    },
    scene: p => ({ scene: "simpson", props: { ma: p.am, sa: p.as, mb: p.bm, sb: p.bs, ram: p.ra[0], ras: p.ra[1], rbm: p.rb[0], rbs: p.rb[1] } }),
  },
  oracle: p => {
    // count patients one by one
    const rate = (groups: [number, number][]) => { let s = 0, n = 0; for (const [size, r] of groups) { s += (size * r) / 100; n += size; } return (100 * s) / n; };
    const mild = p.am + p.bm, sev = p.as + p.bs;
    const adj = (r: [number, number]) => (r[0] * mild + r[1] * sev) / (mild + sev);
    return [p.ra[0], p.ra[1], p.rb[0], p.rb[1], rate([[p.am, p.ra[0]], [p.as, p.ra[1]]]), rate([[p.bm, p.rb[0]], [p.bs, p.rb[1]]]), adj(p.ra), adj(p.rb), adj(p.ra) > adj(p.rb) ? 0 : 1];
  },
  useIt: {
    say: ["Made-up admissions: one group of applicants is admitted at a higher rate in every department, yet at a lower rate overall, because they apply more to the hard departments.",
      "Adjusted to one common mix of departments, the first group comes out ahead. The Luck detector asks \"was assignment random?\" and adjusts if not."],
    saves: { name: "adjRate", value: () => [70, 60], labels: ["A", "B"], unit: "%", note: "adjusted recovery rates, A and B" },
    scene: { scene: "simpson", props: { sa: 80, sb: 20 } },
  },
  deeper: [
    "Causal diagrams make the fix precise: adjust for the variables that block every back-door path from treatment to outcome. But never adjust for a collider, a common effect: conditioning on it creates a correlation from nothing (Berkson's paradox).",
    "Pearl's do-operator, P(y | do(x)), asks what happens if you set x. Adjustment formulas, propensity scores, inverse probability weighting and instrumental variables are ways to identify it from data. Links `cs` (graphs).",
  ],
};

interface P19 { a: number; b: number }
const PAIRS19: [number, number][] = [[1 / 2, 1 / 3], [1 / 2, 1 / 4], [1 / 2, 3 / 4], [1 / 3, 1 / 2], [1 / 3, 2 / 3], [1 / 4, 1 / 2], [1 / 4, 3 / 4], [2 / 3, 1 / 3], [3 / 4, 1 / 2], [3 / 4, 1 / 4]];

export const pr19: B2Lesson<P19> = {
  id: "b2-pr-19", track: "pr", unit: 5, title: "Random walks, streaks and Markov chains",
  youCan: "find where a chance process spends its time in the long run.",
  needs: ["b2-pr-01", "b2-la-14", "st-probrules"],
  tools: ["sim", "matrix"],
  play: { scene: "sim", props: { mode: "walk" },
    say: "A fair coin's running total wanders up and down, with a counter for the longest streak. Then switch to the Markov board: a token hops between sunny and rainy by your chances of switching, and the long-run share bars settle no matter where it started." },
  guess: { scene: "sim", props: { mode: "walk", quiet: true }, kind: "choice", options: ["about 3", "about 7", "about 15"], answer: 1,
    ask: "In 100 fair flips, about how long is the longest run of the same face?",
    revealProps: { many: true },
    reveal: "About 7. Many runs of 100 flips show the longest streak clustering around 6 to 8: long streaks in a fair coin are normal, not a hot hand." },
  nameIt: {
    say: [
      "A **Markov chain** moves by chances that depend only on where it is now. In the long run, the share of time in each state settles to a **stationary distribution** π with π = πP.",
      "With two states, if A switches to B with chance a and B to A with chance b, then π_A = b/(a + b). Linear algebra (b2-la-14) writes the same chain transposed, with columns adding to 1.",
    ],
    formula: ["π = πP", "π_A = b/(a + b)", "P(A → A in two steps) = (1 − a)² + ab"],
  },
  workIt: {
    reference: { a: 1 / 4, b: 1 / 2 },
    generate(rng, i) { const [a, b] = rng.pick(i < 3 ? PAIRS19.filter(([x, y]) => [x, y].every(v => v === 1 / 2 || v === 1 / 4)) : PAIRS19); return { a, b }; },
    show: p => `A made-up weather chain: a sunny day (A) turns rainy with chance **${fr(p.a)}**, and a rainy day (B) turns sunny with chance **${fr(p.b)}**.`,
    steps(p) {
      const piA = p.b / (p.a + p.b);
      return [
        fracStep("stay", "Chance A stays A", 1 - p.a, { hint: `1 − ${fr(p.a)}.`,
          slips: [slip("used b", 1 - p.b, `Staying in A is 1 − a; ${fr(p.b)} is the chance of leaving B.`)] }),
        fracStep("pi", "π_A", piA, { hint: `b/(a + b) = ${fr(p.b)} / (${fr(p.a)} + ${fr(p.b)}).`,
          slips: [slip("a on top", p.a / (p.a + p.b), "π_A grows with the chance of coming back to A, which is b.")] }),
        numStep("days", "Expected B days in 30", 30 * (1 - piA), 1, { unit: "days", hint: `30 × π_B = 30 × ${fr(1 - piA)}.`,
          done: `Expected B days in 30: ${trim(30 * (1 - piA), 1)}`,
          slips: [slip("A days", 30 * piA, `That's the A days. B gets the rest: 30 × ${fr(1 - piA)}.`)] }),
        fracStep("two", "A to A in two steps", (1 - p.a) ** 2 + p.a * p.b, { hint: `Stay twice, or leave and come back: (1 − ${fr(p.a)})² + ${fr(p.a)} × ${fr(p.b)}.`,
          slips: [slip("one path", (1 - p.a) ** 2, "There's a second path: A to B, then back to A, with chance ab.")] }),
      ];
    },
    scene: p => ({ scene: "sim", props: { mode: "markov", a: p.a, b: p.b } }),
  },
  oracle: p => {
    const P = [[1 - p.a, p.a], [p.b, 1 - p.b]];
    let v = [1, 0];
    for (let t = 0; t < 400; t++) v = [v[0]! * P[0]![0]! + v[1]! * P[1]![0]!, v[0]! * P[0]![1]! + v[1]! * P[1]![1]!];
    const P2 = P.map((row, i) => row.map((_, j) => P[i]![0]! * P[0]![j]! + P[i]![1]! * P[1]![j]!));
    return [P[0]![0]!, v[0]!, 30 * v[1]!, P2[0]![0]!];
  },
  useIt: {
    say: ["A made-up basketball player makes 55% of shots after a make and 55% after a miss. As a chain, a = 0.45 and b = 0.55, so π_make = 0.55: the same as no memory at all.",
      "Their streaks look hot, but a fair coin's streaks are that long too. The Luck detector's streak alarm uses this."],
    saves: { name: "piA", value: () => 0.55, note: "a shooter's long-run share of makes" },
    scene: { scene: "sim", props: { mode: "markov", a: 0.45, b: 0.55 } },
  },
  deeper: [
    "π is a left eigenvector of P with eigenvalue 1 (Perron–Frobenius), and the second eigenvalue, here 1 − a − b, sets how fast the chain forgets its start (links b2-la-14). PageRank is a Markov chain, and so is a next-word model with a fixed-length context (links b2-ai-12).",
    "Gambler's ruin: from k, a fair walk reaches N before 0 with chance k/N. That's a martingale at work, and the optional stopping theorem says no stopping rule beats a fair game, which is why peeking breaks naive p-values (b2-pr-15).",
    "The arcsine law: in a fair walk, one side usually leads for most of the time. MCMC (Metropolis–Hastings) builds a chain whose stationary distribution is a posterior with no formula (b2-pr-12). Continuous-time chains link to `de`.",
  ],
};

interface P20 { s1: number; s2: number; z: number; m: number; r: number; pw: number }
const SE_PAIRS: [number, number][] = [[0.003, 0.004], [0.006, 0.008], [0.005, 0.012], [0.009, 0.012]];
const seDiff = (p: P20) => Math.sqrt(p.s1 ** 2 + p.s2 ** 2);

export const pr20: B2Lesson<P20> = {
  id: "b2-pr-20", track: "pr", unit: 5, title: "The Luck detector",
  youCan: "give an honest verdict on an experiment: effect size, interval, correction and the chance it's real.",
  needs: ["b2-pr-03", "b2-pr-14", "b2-pr-15", "b2-pr-16"],
  tools: ["bench", "sim", "bayes", "dens"],
  play: { scene: "bench", props: {},
    say: "A made-up A/B test of two page versions, with a hidden true effect that is sometimes zero. Set the plan, run it, and step through the bench: test, correct, estimate, weigh. Press Reveal to see the truth, and run many experiments to see whether the detector's calls hold up." },
  guess: { scene: "bayes", props: { mode: "ideas", real: 10, power: 30, alpha: 5, quiet: true }, kind: "choice", options: ["More likely real", "More likely luck"], answer: 1,
    ask: "This result has p = 0.03. Power was 30%, and about 1 in 10 ideas like this are real. More likely real or luck?",
    reveal: "Luck. Of 1,000 such ideas, 30 real ones pass and 45 lucky ones do: 60% of the hits are luck." },
  nameIt: {
    say: [
      "An honest verdict uses a plan made before the data, one main test, a correction for every other look, the effect size with an interval, and the chance it's real given how often ideas pan out.",
      "Independent errors add in squares.",
    ],
    formula: ["SE_diff = √(SE₁² + SE₂²)", "z = d / SE_diff", "95% interval = d ± 1.96 SE_diff", "cutoff for m metrics: 1 → 1.96, 2 → 2.24, 5 → 2.58, 10 → 2.81"],
  },
  workIt: {
    reference: { s1: 0.006, s2: 0.008, z: 2.5, m: 5, r: 20, pw: 80 },
    generate(rng, i) {
      const [s1, s2] = i < 3 ? SE_PAIRS[1]! : rng.pick(SE_PAIRS);
      return { s1, s2, z: rng.pick([1, 1.5, 2, 2.5, 3]), m: i < 3 ? 1 : rng.pick([1, 2, 5, 10]), r: rng.pick([10, 20, 50]), pw: rng.pick([30, 50, 80]) };
    },
    show: p => `A made-up A/B test: the arms' SEs are **${trim(p.s1, 3)}** and **${trim(p.s2, 3)}**, and the difference is **d = ${trim(p.z * seDiff(p), 4)}**. You checked **${count(p.m, "metric")}**. About **${p.r}%** of ideas like this are real, and the test had **${p.pw}%** power.`,
    steps(p) {
      const se = seDiff(p), d = p.z * se, cutoff = CUTOFFS[p.m]!, clears = p.z > cutoff ? 0 : 1;
      const r = p.r / 100, pw = p.pw / 100, a = 0.05 / p.m;
      return [
        numStep("se", "SE of the difference", se, 3, { hint: `√(${trim(p.s1, 3)}² + ${trim(p.s2, 3)}²).`,
          slips: [slip("added", p.s1 + p.s2, "Independent errors add in squares, like variances (b2-pr-03): √(SE₁² + SE₂²).")] }),
        numStep("z", "z", p.z, 1, { hint: `d / SE_diff = ${trim(d, 4)} / ${trim(se, 3)}.` }),
        multiStep("ci", "95% interval", [d - 1.96 * se, d + 1.96 * se], 4, { boxes: ["from", "to"], hint: `${trim(d, 4)} ± 1.96 × ${trim(se, 3)}.`,
          slips: [slip("used z", [d - p.z * se, d + p.z * se], "The 95% interval always uses 1.96, whatever z you got.")] }),
        tapStep("clear", `Clears the bar for ${count(p.m, "metric")}?`, ["Yes", "No"], clears, { hint: `The bar for ${count(p.m, "metric")} is z > ${trim(cutoff, 2)}.`,
          slips: [p.m > 1 && p.z > 1.96 && clears === 1 && slip("one-metric bar", 0, `You checked ${p.m} metrics. The bar rises to ${trim(cutoff, 2)}.`)] }),
        numStep("real", `Chance it's real if it clears α = ${p.m === 1 ? "0.05" : `0.05/${p.m}`}`, (100 * r * pw) / (r * pw + (1 - r) * a), 1, { unit: "%",
          done: `Chance it's real: ${trim((100 * r * pw) / (r * pw + (1 - r) * a), 1)}%`,
          hint: `r · power / (r · power + (1 − r) · ${trim(a, 4)}) = ${trim(r * pw, 4)} / (${trim(r * pw, 4)} + ${trim((1 - r) * a, 4)}).`,
          slips: [p.m > 1 && slip("plain α", (100 * r * pw) / (r * pw + (1 - r) * 0.05), `With ${p.m} metrics each is tested at 0.05/${p.m}, so fewer false hits get through.`),
            slip("power", p.pw, "Power is P(clears | real). You need the reverse, P(real | clears).")] }),
      ];
    },
    scene: p => ({ scene: "bayes", props: { mode: "ideas", real: p.r, power: p.pw, alpha: 5 / p.m } }),
  },
  oracle: p => {
    const se = Math.hypot(p.s1, p.s2), d = p.z * se, cut = PhiInv(1 - 0.025 / p.m);
    const r = p.r / 100, pw = p.pw / 100;
    return [se, d / se, d - 1.96 * se, d + 1.96 * se, d / se > cut ? 0 : 1, (100 * r * pw) / (r * pw + ((1 - r) * 0.05) / p.m)];
  },
  useIt: {
    say: ["Finish the build: run the Luck detector on made-up experiments with hidden truths, and write a one-line verdict for each.",
      "Then run a hundred more and look at the calibration dots: of the calls it made at about 80% sure, how many held up? Save it to keep `luckDetector` in your Notebook."],
    project: "pr-luck",
  },
  deeper: [
    "Always-valid sequential testing with e-values and mixture likelihood ratios lets you peek as often as you like without inflating false alarms.",
    "Hierarchical (empirical) Bayes across many past experiments shrinks each new effect toward the typical one (b2-pr-17). CUPED cuts the variance by the factor 1 − ρ² using a pre-period measurement that correlates with the outcome (b2-pr-08).",
    "Calibration asks: of the calls made at \"80% sure\", were 80% right? (links b2-ai-16, \"Knowing what you don't know\").",
  ],
};

export const UNIT345 = [pr09, pr10, pr11, pr12, pr13, pr14, pr15, pr16, pr17, pr18, pr19, pr20];
