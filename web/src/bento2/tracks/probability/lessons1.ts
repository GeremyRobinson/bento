// Probability, units 1 and 2 (b2-pr-01 to b2-pr-08), built from curriculum/specs/bento2/probability.md block by block.
import type { B2Lesson } from "../../model";
import { fracStep, numStep, slip, tapStep, wholeStep } from "../../make";
import { formatAnswer, group } from "../../steps";
import { binomPmf, coefOf, comb, poissonPmf, tableUpper, trim } from "./maths";

const fr = (x: number) => formatAnswer(x, "fraction");
/** the choices with the right one at position `at` (so the right answer isn't always first) */
const rotate = (choices: string[], at: number): [string[], number] => {
  const k = ((at % choices.length) + choices.length) % choices.length;
  const out = [...choices.slice(1)];
  out.splice(k, 0, choices[0]!);
  return [out, k];
};

/* ------------------------------------------------------------------ unit 1 ------------------------------------------------------------------ */

interface P01 { n0: number; e0: number; k: number; m: number; n: number | null }

export const pr01: B2Lesson<P01> = {
  id: "b2-pr-01", track: "pr", unit: 1, title: "The law of large numbers and the 1/√n rule",
  youCan: "say how many trials it takes to make a simulated average as precise as you need.",
  needs: ["g6-mean", "st-sampdist"],
  tools: ["sim", "calc"],
  play: { scene: "sim", props: { mode: "avg", p: 0.5 },
    say: "Set a coin's chance of heads and run 1, 100 or 100,000 flips. The running share of heads wobbles, then flattens onto p, and the shaded band (±2σ/√n) narrows as n grows." },
  guess: { scene: "sim", props: { mode: "avg", p: 0.5, quiet: true, upto: 100 }, kind: "choice", options: ["150", "200", "400", "1,000"], answer: 2,
    ask: "After 100 flips, the average typically lands within about 0.10 of the truth. How many flips to land within 0.05?",
    revealProps: { upto: 400, half: true },
    reveal: "400. Halving the error takes four times the flips: the band's half-width reads 0.05 at n = 400." },
  nameIt: {
    say: [
      "The average of n independent tries settles on the expected value. That's the **law of large numbers**.",
      "Its typical error shrinks like 1/√n, so halving the error costs four times the trials. Using random trials to compute something is a **Monte Carlo** estimate.",
    ],
    formula: ["X̄ₙ → μ", "SD(X̄ₙ) = σ / √n", "trials for error e = (σ / e)²"],
  },
  workIt: {
    reference: { n0: 200, e0: 0.06, k: 4, m: 3, n: 2500 },
    generate(rng, i) {
      const k = i < 3 ? 2 : rng.pick([2, 4, 5, 10]);
      const n0 = i < 3 ? 100 : rng.pick([100, 200, 400, 500]);
      const m = rng.pick([2, 3, 4, 5, 10].filter(x => x !== k && (i >= 3 || x <= 5)));
      return { n0, k, m, e0: rng.pick([0.1, 0.08, 0.06, 0.05, 0.04]), n: i >= 4 ? rng.pick([100, 400, 2500, 10000]) : null };
    },
    show: p => `After **${group(p.n0)} trials**, a simulated average is typically off by **${trim(p.e0)}**.${p.n ? " A fair coin has σ = 0.5." : ""}`,
    steps(p) {
      const big = p.n0 * p.k * p.k, e = p.e0 / p.k;
      const out = [
        numStep("e", `Typical error after ${group(big)} trials`, e, 4, {
          ask: `That's ${p.k * p.k} times the trials.`, hint: `The error shrinks like 1/√n: √${p.k * p.k} = ${p.k}, so divide ${trim(p.e0)} by ${p.k}.`,
          done: `Typical error after ${group(big)} trials: ${trim(e)}`,
          slips: [slip("divided by k²", p.e0 / (p.k * p.k), `The error falls like 1/√n, not 1/n. Multiplying the trials by ${p.k * p.k} only divides the error by ${p.k}.`)],
        }),
        wholeStep("n", `Trials to cut the error by ${p.m}`, p.n0 * p.m * p.m, {
          ask: `How many trials make the error ${p.m} times smaller than at ${group(p.n0)}?`, hint: `Trials grow with the square: ${group(p.n0)} × ${p.m}².`,
          slips: [slip("times m", p.n0 * p.m, `Halving the error takes 4 times the trials, not 2. To cut it by ${p.m}, multiply the trials by ${p.m}² = ${p.m * p.m}.`)],
        }),
      ];
      if (p.n) {
        const r = Math.sqrt(p.n), c = 0.5 / r;
        out.push(numStep("c", `Typical error for a fair coin over ${group(p.n)} flips`, c, 3, {
          hint: `σ/√n = 0.5/√${group(p.n)} = 0.5/${r}.`, done: `Typical error for a fair coin over ${group(p.n)} flips: ${trim(c)}`,
          slips: [p.n <= 2500 && slip("over n", 0.5 / p.n, `Divide by √n: √${group(p.n)} = ${r}, so the error is 0.5/${r} = ${trim(c)}.`)],
        }));
      }
      return out;
    },
    scene: () => ({ scene: "sim", props: { mode: "avg", p: 0.5 } }),
  },
  oracle: p => [p.e0 / p.k, p.n0 * p.m ** 2, ...(p.n ? [0.5 / Math.sqrt(p.n)] : [])],
  useIt: {
    say: ["Estimate π: drop random points in a square, count the share inside the quarter circle, and multiply by 4.",
      "One drop has an SD of about 1.64, so a typical error of 0.005 needs about (1.64/0.005)² ≈ 110,000 drops. The Luck detector uses this rule to say how many null-world replays it needs."],
    saves: { name: "mcN", value: () => Math.round(((4 * Math.sqrt((Math.PI / 4) * (1 - Math.PI / 4))) / 0.005) ** 2), unit: "drops", note: "drops for π to within 0.005" },
    scene: { scene: "sim", props: { mode: "pi" } },
  },
  deeper: [
    "Chebyshev's inequality, P(|X̄ₙ − μ| ≥ ε) ≤ σ²/(nε²), proves the weak law in one line: the right side goes to 0 as n grows.",
    "The strong law says the average converges with probability 1, and it needs a finite mean. The Cauchy distribution has none, and its running average never settles: every so often one huge draw throws it somewhere new.",
    "Monte Carlo is only as good as its random numbers, which is why pseudo-random generators are tested hard (links `cs`). Quantum measurement statistics shrink by the same 1/√n rule (links `qu`).",
  ],
};

interface P02 { kind: "a" | "b" | "c"; n: number; d: number; j: number; rot: number }
const H = (n: number) => { let s = 0; for (let j = 0; j < n; j++) s += n / (n - j); return s; };

export const pr02: B2Lesson<P02> = {
  id: "b2-pr-02", track: "pr", unit: 1, title: "Expected value by counting indicators",
  youCan: "find the average of a tangled count by splitting it into yes/no pieces.",
  needs: ["st-expected"],
  tools: ["sim", "shelf"],
  play: { scene: "sim", props: { mode: "env", n: 10 },
    say: "Bento shuffles n letters into n addressed envelopes. Drag n from 2 to 100 and run many shuffles: the count of letters in the right envelope jumps around, but its running average sits near 1 for every n." },
  guess: { scene: "sim", props: { mode: "env", n: 100, quiet: true }, kind: "choice", options: ["about 0.01", "about 1", "about 10", "about 50"], answer: 1,
    ask: "With 100 letters, how many land in the right envelope, on average?",
    revealProps: { auto: true },
    reveal: "About 1. Each letter has a 1/100 chance, and 100 of those chances add to 1." },
  nameIt: {
    say: [
      "To average a count, write it as a sum of **indicators**: 1 if a thing happens, 0 if not.",
      "The expected value of an indicator is the chance its thing happens, and expected values add even when the pieces depend on each other. That's **linearity of expectation**.",
    ],
    formula: ["X = I₁ + I₂ + … + Iₙ", "E[Iᵢ] = P(event i)", "E[X] = Σ P(event i)"],
  },
  workIt: {
    reference: { kind: "a", n: 10, d: 50, j: 1, rot: 0 },
    generate(rng, i) {
      const rot = rng.int(0, 2);
      if (i < 3) return rng.next() < 0.5 ? { kind: "b", n: rng.int(5, 9), d: 4, j: 1, rot } : { kind: "a", n: rng.int(4, 6), d: rng.pick([12, 50, 100]), j: 1, rot };
      const kind = i >= 6 && rng.next() < 0.5 ? "c" : rng.pick(["a", "b"] as const);
      if (kind === "c") { const n = rng.pick([2, 3, 4, 6]); return { kind, n, d: 0, j: rng.int(1, n - 1), rot }; }
      if (kind === "b") return { kind, n: rng.int(5, 41), d: 4, j: 1, rot };
      return { kind, n: rng.int(4, 30), d: rng.pick([12, 50, 100, 365]), j: 1, rot };
    },
    show: p => p.kind === "a" ? `**${p.n} people** (made up), each born on one of **${p.d} equally likely days**. On average, how many pairs share a day?`
      : p.kind === "b" ? `A fair coin is flipped **${p.n} times**. On average, how many spots have heads followed right away by tails?`
        : `Each cereal box holds one of **${p.n} toys**, all equally likely. On average, how many boxes until you have all ${p.n}?`,
    steps(p) {
      if (p.kind === "c") {
        const left = p.n - p.j, next = p.n / left, tot = H(p.n);
        return [
          fracStep("next", `Expected boxes for the next new toy when ${p.j} ${p.j === 1 ? "is" : "are"} found`, next, {
            hint: `A box is new with chance ${left}/${p.n}, so the wait averages ${p.n}/${left}.`,
            slips: [slip("chance not wait", left / p.n, `That's the chance one box is new. The wait is one over it: ${p.n}/${left}.`)],
          }),
          fracStep("E", "Expected total", tot, {
            hint: `Add the waits for each new toy: ${Array.from({ length: p.n }, (_, j) => fr(p.n / (p.n - j))).join(" + ")}.`,
            slips: [slip("one each", p.n, "Each new toy gets harder to find. Add the waits n/(n − j) for j = 0 up to n − 1.")],
          }),
        ];
      }
      const a = p.kind === "a";
      const [choices, right] = rotate(a
        ? ["one pair of people shares a day", "one person shares a day with someone", "one day has two birthdays"]
        : ["spot i is heads, then tails", "flip i is heads", "every flip so far is heads"], p.rot);
      const q = a ? 1 / p.d : 1 / 4, cnt = a ? comb(p.n, 2) : p.n - 1, E = cnt * q;
      return [
        tapStep("what", "What one indicator marks", choices, right, { hint: a ? "Count pairs: each pair either matches or doesn't." : "A spot is two flips in a row." }),
        fracStep("q", "Chance for one indicator", q, {
          hint: a ? `The second person matches the first's day with chance 1/${p.d}.` : "Heads, then tails: 1/2 × 1/2.",
          slips: [!a && slip("one flip", 1 / 2, "The spot needs two flips to go right: heads (1/2) and then tails (1/2), so 1/4.")],
        }),
        wholeStep("count", "How many indicators", cnt, {
          hint: a ? `Pairs of ${p.n} people: C(${p.n}, 2) = ${p.n} × ${p.n - 1} / 2.` : `Spots run from flip 1 to flip ${p.n - 1}.`,
          slips: [a ? slip("people not pairs", p.n, `Pairs, not people: ${p.n} people make C(${p.n}, 2) = ${cnt} pairs.`)
            : slip("n spots", p.n, `A heads-then-tails spot needs two flips, so there are ${cnt} spots, not ${p.n}.`)],
        }),
        fracStep("E", "Expected total", E, {
          hint: `Add one chance per indicator: ${cnt} × ${fr(q)}.`,
          slips: [
            a ? slip("people not pairs", p.n * q, `Pairs, not people: ${p.n} people make C(${p.n}, 2) = ${cnt} pairs.`)
              : slip("n spots", p.n * q, `A heads-then-tails spot needs two flips, so there are ${cnt} spots, not ${p.n}.`),
            slip("didn't add", q, "Linearity needs no independence. Add the expected values even when the events overlap."),
          ],
        }),
      ];
    },
    scene: p => ({ scene: "sim", props: { mode: "env", n: p.kind === "c" ? 10 : Math.min(100, p.n) } }),
  },
  oracle: p => {
    if (p.kind === "c") {
      // E[T] = Σ P(T > t), with P(all seen in t boxes) by inclusion–exclusion; the next wait as a geometric series
      let ET = 0;
      for (let t = 0; t < 4000; t++) { let all = 0; for (let k = 0; k <= p.n; k++) all += (-1) ** k * comb(p.n, k) * (1 - k / p.n) ** t; ET += 1 - all; }
      const q = (p.n - p.j) / p.n;
      let next = 0; for (let t = 1; t < 4000; t++) next += t * (1 - q) ** (t - 1) * q;
      return [next, ET];
    }
    const [, right] = rotate(["x", "y", "z"], p.rot);
    if (p.kind === "a") {
      // pairs sharing a day = Σ over days of C(count on that day, 2), each count Binomial(n, 1/d)
      let e = 0;
      for (let k = 2; k <= p.n; k++) e += comb(k, 2) * binomPmf(k, p.n, 1 / p.d);
      return [right, 1 / p.d, (p.n * (p.n - 1)) / 2, p.d * e];
    }
    // heads-then-tails spots, exactly: enumerate every string when short, else carry the expectation flip by flip
    let e = 0;
    if (p.n <= 12) {
      for (let s = 0; s < 1 << p.n; s++) { let c = 0; for (let i = 0; i + 1 < p.n; i++) if ((s >> i) & 1 && !((s >> (i + 1)) & 1)) c++; e += c; }
      e /= 2 ** p.n;
    } else { let pH = 0.5; for (let i = 1; i < p.n; i++) { e += pH * 0.5; pH = 0.5; } }
    return [right, 1 / 4, p.n - 1, e];
  },
  useIt: {
    say: ["In a class of 30, the expected number of pairs sharing a birthday is C(30, 2)/365 = 435/365 ≈ 1.19.",
      "The Luck detector uses the same count when it checks \"two of my 30 metrics moved together: is that strange?\""],
    saves: { name: "pairs", value: () => 435 / 365, note: "expected shared-birthday pairs in a class of 30" },
    scene: { scene: "sim", props: { mode: "env", n: 30 } },
  },
  deeper: [
    "The variance of a count from indicators is Var X = Σ Var Iᵢ + 2 Σ Cov(Iᵢ, Iⱼ). For letters in envelopes the count tends to Poisson(1), so P(no match) → 1/e ≈ 0.368.",
    "The probabilistic method: if the average of a count is above k, some arrangement beats k. Erdős used it for a lower bound on Ramsey numbers without building a single example.",
    "Collecting n coupons takes n(1 + 1/2 + … + 1/n) ≈ n ln n draws on average, and the total concentrates tightly around that.",
  ],
};

interface P03 { a: number; b: number; c: number; al: number; be: number }
const combo = (al: number, be: number) => `${coefOf(al, "X")} ${be < 0 ? "−" : "+"} ${coefOf(Math.abs(be), "Y")}`;

export const pr03: B2Lesson<P03> = {
  id: "b2-pr-03", track: "pr", unit: 1, title: "Variance of sums and covariance",
  youCan: "find the spread of a sum or difference when the parts move together.",
  needs: ["b2-pr-02", "st-expected"],
  tools: ["spin", "cloud", "matrix"],
  play: { scene: "spin", props: { link: 0 },
    say: "Two spinners X and Y feed a histogram of X + Y. Turn the link knob so Y leans with X, ignores it, or leans against it: the histogram of the sum widens, holds or narrows." },
  guess: { scene: "spin", props: { link: -0.7, quiet: true }, kind: "choice", options: ["More spread out", "The same", "Less spread out"], answer: 2,
    ask: "Y tends to go down when X goes up. Is X + Y more spread out, the same, or less spread out than when they're independent?",
    revealProps: { both: true },
    reveal: "Less. When Y leans against X, their ups and downs cancel, and the sum's histogram is the narrower one." },
  nameIt: {
    say: [
      "Variance scales by the square of a multiplier, and for a sum it adds, plus a cross term for how the parts move together. That cross term is the **covariance**.",
      "For n independent copies, the sum's variance is nσ² and the average's is σ²/n.",
    ],
    formula: ["Var(αX + s) = α² Var X", "Var(X ± Y) = Var X + Var Y ± 2 Cov(X, Y)", "Cov(X, Y) = E[XY] − E[X] E[Y]"],
  },
  workIt: {
    reference: { a: 9, b: 4, c: -3, al: 2, be: 3 },
    generate(rng, i) {
      const a = rng.pick([4, 9, 16, 25]), b = rng.pick([1, 4, 9, 16]), lim = Math.floor(Math.sqrt(a * b));
      const c = i < 3 ? rng.pick([0, 2]) : rng.pick(Array.from({ length: 2 * lim + 1 }, (_, k) => k - lim).filter(x => x !== 0));
      return { a, b, c, al: rng.pick([-3, -2, 2, 3]), be: rng.pick([-3, -2, 2, 3]) };
    },
    show: p => `Var X = **${p.a}**, Var Y = **${p.b}**, Cov(X, Y) = **${trim(p.c)}**.`,
    steps(p) {
      const { a, b, c, al, be } = p;
      return [
        wholeStep("ax", `Var(${coefOf(al, "X")})`, al * al * a, { hint: `Square the multiplier: (${trim(al)})² × ${a}.`,
          slips: [slip("times α", al * a, `Multiplying by ${trim(al)} scales the spread by ${Math.abs(al)} and the variance by ${al * al}.`)] }),
        wholeStep("sum", "Var(X + Y)", a + b + 2 * c, { hint: "Var X + Var Y + 2 Cov(X, Y).",
          slips: [slip("cov once", a + b + c, "The cross term counts twice: + 2 Cov(X, Y).")] }),
        wholeStep("diff", "Var(X − Y)", a + b - 2 * c, { hint: "Var X + Var Y − 2 Cov(X, Y).",
          slips: [slip("subtracted", a - b, "Variances never subtract. Var(X − Y) = Var X + Var Y − 2 Cov(X, Y)."),
            slip("cov once", a + b - c, "The cross term counts twice: − 2 Cov(X, Y).")] }),
        wholeStep("lin", `Var(${combo(al, be)})`, al * al * a + be * be * b + 2 * al * be * c, {
          hint: `α² Var X + β² Var Y + 2αβ Cov: ${al * al * a} + ${be * be * b} ${signTerm2(2 * al * be * c)}.`,
          slips: [slip("not squared", al * a + be * b + 2 * al * be * c, "Multiplying by α scales the variance by α², not α."),
            slip("cov once", al * al * a + be * be * b + al * be * c, "The cross term counts twice: + 2αβ Cov(X, Y).")],
        }),
      ];
    },
    scene: p => ({ scene: "spin", props: { link: Math.max(-0.9, Math.min(0.9, p.c / Math.sqrt(p.a * p.b))) } }),
  },
  oracle: p => {
    // wᵀ Σ w for each combination
    const S = [[p.a, p.c], [p.c, p.b]];
    const q = (w: number[]) => w.reduce((s, wi, i) => s + wi * w.reduce((t, wj, j) => t + S[i]![j]! * wj, 0), 0);
    return [q([p.al, 0]), q([1, 1]), q([1, -1]), q([p.al, p.be])];
  },
  useIt: {
    say: ["Two thermometers each have error variance 4. Averaging them with independent errors gives variance (4 + 4)/4 = 2. If their errors have covariance 2, it gives (4 + 4 + 4)/4 = 3.",
      "The Luck detector adds the two arms' errors this way."],
    saves: { name: "varAvg", value: () => [2, 3], labels: ["independent", "covariance 2"], note: "variance of the average of two thermometers" },
    scene: { scene: "spin", props: { link: 0.5 } },
  },
  deeper: [
    "Collect the variances and covariances in a matrix Σ. Then Var(wᵀX) = wᵀΣw, and since a variance can't be negative, Σ is positive semidefinite (links b2-la-15). The weights with the least variance are proportional to Σ⁻¹1: the idea behind portfolio math.",
    "Cauchy–Schwarz gives |Cov(X, Y)| ≤ σX σY, which is why correlation lives between −1 and 1. The law of total variance splits any spread in two: Var Y = E[Var(Y | X)] + Var(E[Y | X]).",
  ],
};
/** "+ 36" or "− 36" for a hint */
const signTerm2 = (x: number) => (x < 0 ? `− ${-x}` : `+ ${x}`);

interface P04 { prev: number; sens: number; spec: number }
const N = 10000;

export const pr04: B2Lesson<P04> = {
  id: "b2-pr-04", track: "pr", unit: 1, title: "Bayes' rule and the base rate",
  youCan: "turn \"how accurate is the test\" into \"how likely is it, given a positive\".",
  needs: ["st-probrules"],
  tools: ["bayes", "sim"],
  play: { scene: "bayes", props: { prev: 1, sens: 90, spec: 90 },
    say: "10,000 dots, one per person. Drag how rare the condition is, how often the test catches it, and how often it clears healthy people. The dots split four ways, and the positives are boxed so you can see how many are real." },
  guess: { scene: "bayes", props: { prev: 1, sens: 90, spec: 90, quiet: true }, kind: "slider", min: 0, max: 100, step: 1, start: 50, answer: 100 * 90 / 1080, near: 5, unit: "%",
    ask: "1% have it. The test catches 90% of cases and clears 90% of healthy people. Of those who test positive, what share have it?",
    reveal: "About 8%. The box lights 90 true positives and 990 false ones: healthy people are so many that their 10% of mistakes swamps the real cases." },
  nameIt: {
    say: [
      "To reverse a conditional chance, count the people. Of the positives, the share that really have it depends heavily on how rare the condition is. That's **Bayes' rule**.",
      "In odds form, the evidence multiplies what you believed before.",
    ],
    formula: ["P(A | B) = P(B | A) P(A) / P(B)", "posterior odds = prior odds × likelihood ratio", "LR+ = sensitivity / (1 − specificity)"],
  },
  workIt: {
    reference: { prev: 2, sens: 95, spec: 95 },
    generate(rng, i) {
      return { prev: i < 3 ? 10 : rng.pick([1, 2, 5, 10]), sens: rng.pick([80, 90, 95, 99]), spec: i < 3 ? 90 : rng.pick([90, 95, 98, 99]) };
    },
    show: p => `Out of **10,000 people** (made up), **${p.prev}%** have a condition. The test catches **${p.sens}%** of cases and clears **${p.spec}%** of healthy people.`,
    steps(p) {
      const have = (N * p.prev) / 100, healthy = N - have, TP = (have * p.sens) / 100, FP = (healthy * (100 - p.spec)) / 100, positives = TP + FP;
      return [
        wholeStep("have", "Have it", have, { unit: "people", hint: `${p.prev}% of 10,000.` }),
        wholeStep("tp", "True positives", TP, { unit: "people", hint: `The test catches ${p.sens}% of the ${group(have)}.`,
          slips: [slip("missed ones", have - TP, `That's the cases the test misses. It catches ${p.sens}% of the ${group(have)}.`)] }),
        wholeStep("fp", "False positives", FP, { unit: "people", hint: `It wrongly flags ${100 - p.spec}% of the ${group(healthy)} healthy people.`,
          slips: [slip("all N", (N * (100 - p.spec)) / 100, `False positives come from the healthy ${group(healthy)}, not all ${group(N)}.`)] }),
        numStep("ppv", "P(has it | positive)", (100 * TP) / positives, 1, { unit: "%", done: `P(has it | positive): ${trim((100 * TP) / positives, 1)}%`, hint: `True positives over all positives: ${group(TP)} / ${group(positives)}.`,
          slips: [slip("sensitivity", p.sens, "That's P(positive | has it). You need the reverse, P(has it | positive)."),
            slip("over N", (100 * TP) / N, `Only positives count here: divide by TP + FP = ${group(positives)}.`)] }),
      ];
    },
    scene: p => ({ scene: "bayes", props: { prev: p.prev, sens: p.sens, spec: p.spec } }),
  },
  oracle: p => {
    // the 10,000 people as an array: [has it, tests positive]
    const people: [boolean, boolean][] = [];
    const have = Math.round((N * p.prev) / 100), healthy = N - have;
    for (let i = 0; i < have; i++) people.push([true, i < Math.round((have * p.sens) / 100)]);
    for (let i = 0; i < healthy; i++) people.push([false, i < Math.round((healthy * (100 - p.spec)) / 100)]);
    const pos = people.filter(x => x[1]);
    return [people.filter(x => x[0]).length, pos.filter(x => x[0]).length, pos.filter(x => !x[0]).length, (100 * pos.filter(x => x[0]).length) / pos.length];
  },
  useIt: {
    say: ["Someone tests positive twice on independent tests. Use the first answer as the new prevalence and press \"Test again\": the posterior becomes the new prior.",
      "Project: make a screening card. Pick a made-up condition, set how rare it is and how good the test is, and write what a positive really means. Save it to keep `ppv`, the Luck detector's base-rate dial."],
    project: "pr-screen",
  },
  deeper: [
    "Log-odds make evidence add: each independent test adds log(LR) to the log-odds. Measured with log₂, a likelihood ratio is evidence in bits (links `in`).",
    "Naive Bayes classifiers multiply likelihood ratios across features, as if each were an independent test (links `ai`). Bayes' rule for a continuous parameter, posterior ∝ likelihood × prior, is b2-pr-12.",
  ],
};

/* ------------------------------------------------------------------ unit 2 ------------------------------------------------------------------ */

interface P05 { r: number; hourly: boolean; t: number; k: number; later: boolean }
const lamOf = (p: P05) => (p.hourly ? (p.r * p.t) / 60 : p.r * p.t);
const LAM_PAIRS: [number, number][] = [[1, 30], [2, 15], [2, 30], [4, 15], [1, 90], [3, 30], [4, 30], [1, 120], [2, 90], [6, 30], [2, 120], [8, 30]];
const window = (t: number) => (t >= 60 && t % 60 === 0 ? `${t / 60} hours` : `${t} minutes`);

export const pr05: B2Lesson<P05> = {
  id: "b2-pr-05", track: "pr", unit: 2, title: "The Poisson count",
  youCan: "find the chance of a given number of rare, random events in a window.",
  needs: ["st-binomial"],
  tools: ["sim", "dens"],
  play: { scene: "sim", props: { mode: "rain", rate: 3 },
    say: "Dots rain onto a time strip at an average rate you drag. A window slides along and the bars count how many dots each window caught. Turn on Binomial(n, λ/n) and raise n: it slides onto the same bars." },
  guess: { scene: "sim", props: { mode: "rain", rate: 3, quiet: true }, kind: "choice", options: ["2", "3", "4", "2 and 3 tie"], answer: 3,
    ask: "Calls average 3 per minute. Which count is most common in a minute?",
    revealProps: { exact: true },
    reveal: "2 and 3 tie: P(2) = P(3) = 4.5 e⁻³ ≈ 0.224. Going from 2 to 3 multiplies by λ/3 = 1." },
  nameIt: {
    say: [
      "When many tiny chances each might happen independently, the count follows a **Poisson** distribution with mean λ, where λ is the rate times the window.",
      "Its variance is also λ.",
    ],
    formula: ["P(X = k) = e^(−λ) λᵏ / k!", "E[X] = Var X = λ", "λ = rate × time"],
  },
  workIt: {
    reference: { r: 2, hourly: true, t: 90, k: 3, later: true },
    generate(rng, i) {
      if (i < 3) return { r: rng.pick([1, 2]), hourly: false, t: 1, k: rng.int(1, 3), later: false };
      const [r, t] = rng.pick(LAM_PAIRS);
      return { r, hourly: true, t, k: rng.int(1, 4), later: i >= 4 };
    },
    show: p => p.hourly ? `Arrivals at a counter average **${p.r} per hour** (made up). Look at a window of **${window(p.t)}**.`
      : `Calls average **${p.r} per minute** (made up). Look at **one minute**.`,
    steps(p) {
      const lam = lamOf(p), e0 = Math.exp(-lam), pk = poissonPmf(p.k, lam);
      return [
        numStep("lam", "λ for this window", lam, 1, { hint: p.hourly ? `Rate × time: ${p.r} per hour × ${trim(p.t / 60)} hours.` : `Rate × time: ${p.r} × 1.`,
          done: `λ for this window: ${trim(lam)}`,
          slips: [slip("hourly rate", p.r, `λ is the mean for this window: rate × time = ${trim(lam)}.`)] }),
        numStep("p0", "P(X = 0)", e0, 4, { hint: `e^(−${trim(lam)}).`,
          slips: [slip("e to the λ", Math.exp(lam), "The chance shrinks with λ for k = 0: it's e^(−λ).")] }),
        numStep("pk", `P(X = ${p.k})`, pk, 4, { hint: `e^(−${trim(lam)}) × ${trim(lam)}^${p.k} / ${p.k}!.`,
          slips: [slip("no k!", e0 * lam ** p.k, "Divide by k!: the ways to order k arrivals don't count as different outcomes.")] }),
        ...(p.later ? [numStep("p1", "P(X ≥ 1)", 1 - e0, 4, { hint: "Everything but zero: 1 − P(X = 0).",
          slips: [slip("that's zero", e0, "That's P(X = 0). At least one is everything else: 1 − e^(−λ).")] })] : []),
      ];
    },
    scene: p => ({ scene: "sim", props: { mode: "rain", rate: lamOf(p) } }),
  },
  oracle: p => {
    const lam = lamOf(p);
    // the pmf by its recursion P(k) = P(k − 1) λ / k
    const pm = [Math.exp(-lam)];
    for (let k = 1; k <= p.k; k++) pm.push((pm[k - 1]! * lam) / k);
    return [lam, pm[0]!, pm[p.k]!, ...(p.later ? [1 - pm[0]!] : [])];
  },
  useIt: {
    say: ["A street averages 2 crashes a month, and this month had 6. P(X ≥ 6) = 1 − e^(−2)(1 + 2 + 2 + 4/3 + 2/3 + 4/15) ≈ 0.0166: rare for one street.",
      "But the city has 50 such streets, so the chance some street hits 6 is about 1 − 0.9834⁵⁰ ≈ 0.57. Looking everywhere finds a rare thing somewhere (b2-pr-15)."],
    saves: { name: "lambda", value: () => 2, unit: "a month", note: "a street's crash rate" },
    scene: { scene: "sim", props: { mode: "rain", rate: 2 } },
  },
  deeper: [
    "The Poisson limit: with n slots each firing with chance λ/n, P(none) = (1 − λ/n)ⁿ → e^(−λ), and the same argument gives every Binomial(n, λ/n) probability its Poisson limit.",
    "The Poisson process: the gaps between arrivals are exponential (b2-pr-06), counts in separate windows are independent, two processes merge by adding rates, and a coin flip on each arrival splits one into two. Birth processes in `de` grow the same way.",
  ],
};

interface P06 { m: number; t: number; a: number; b: number }

export const pr06: B2Lesson<P06> = {
  id: "b2-pr-06", track: "pr", unit: 2, title: "Densities and the exponential wait",
  youCan: "find chances for a continuous wait time as areas under a curve.",
  needs: ["b2-pr-05", "g12-defint"],
  tools: ["dens", "graph2d"],
  play: { scene: "dens", props: { mode: "sketch" },
    say: "Sketch any curve with the handles: Bento keeps its area at 1 and shades the area between two values you drag. Then switch to the exponential wait, drag its mean, and press \"You already waited\": the cut-off tail, rescaled, is the curve you started with." },
  guess: { scene: "dens", props: { mode: "exp", mean: 10, quiet: true }, kind: "choice", options: ["0 years", "5 years", "10 years", "20 years"], answer: 2,
    ask: "A part's life is exponential with mean 10 years. It has already lasted 10 years. What's its expected remaining life?",
    revealProps: { waited: 10 },
    reveal: "10 years. Cut the curve at 10 and rescale what's left: it is the same curve again, so the wait starts over." },
  nameIt: {
    say: [
      "For a continuous variable, chance is area under the **density** f: the chance it falls between a and b is the integral from a to b.",
      "The **exponential** wait with rate λ forgets how long you've waited: that's being **memoryless**.",
    ],
    formula: ["P(a < X < b) = ∫ₐᵇ f(x) dx", "f(x) = λe^(−λx)", "P(X > t) = e^(−λt)", "mean = 1/λ", "median = ln 2 / λ"],
  },
  workIt: {
    reference: { m: 4, t: 4, a: 2, b: 4 },
    generate(rng, i) {
      const m = rng.pick([2, 4, 5, 10]), h = m / 2;
      const ja = rng.int(0, 3), jb = ja + rng.int(1, 3);
      return { m, t: i < 3 ? m : rng.int(1, 6) * h, a: ja * h, b: jb * h };
    },
    show: p => `A part's life is exponential with mean **${p.m} years** (made up).`,
    steps(p) {
      const e = (x: number) => Math.exp(-x / p.m);
      return [
        fracStep("lam", "Rate λ", 1 / p.m, { unit: "per year", hint: `The rate is 1 over the mean: 1/${p.m}.`,
          slips: [slip("mean as rate", p.m, `A mean wait of ${p.m} means a rate of 1/${p.m} per year.`)] }),
        numStep("tail", `P(X > ${trim(p.t)})`, e(p.t), 4, { hint: `e^(−λt) = e^(−${trim(p.t)}/${p.m}).`,
          slips: [slip("cdf", 1 - e(p.t), "1 − e^(−λt) is the chance it's over by t. Lasting past t is e^(−λt).")] }),
        numStep("ab", `P(${trim(p.a)} < X < ${trim(p.b)})`, e(p.a) - e(p.b), 4, { hint: `Past ${trim(p.a)} but not past ${trim(p.b)}: e^(−${trim(p.a)}/${p.m}) − e^(−${trim(p.b)}/${p.m}).`,
          slips: [slip("backwards", e(p.b) - e(p.a), `The earlier tail is the bigger one: e^(−${trim(p.a)}/${p.m}) − e^(−${trim(p.b)}/${p.m}).`)] }),
        numStep("med", "Median", p.m * Math.LN2, 2, { unit: "years", hint: `Solve e^(−λx) = 1/2: x = ${p.m} ln 2.`,
          slips: [slip("mean", p.m, "The curve is skewed right, so the median m ln 2 is below the mean.")] }),
      ];
    },
    scene: p => ({ scene: "dens", props: { mode: "exp", mean: p.m, lo: p.a, hi: p.b } }),
  },
  oracle: p => {
    // Simpson's rule on λe^(−λx), 10⁴ strips; the median by bisection on the area reaching 1/2
    const lam = 1 / p.m, f = (x: number) => lam * Math.exp(-lam * x);
    const area = (lo: number, hi: number) => { const n = 10000, h = (hi - lo) / n; let s = f(lo) + f(hi); for (let i = 1; i < n; i++) s += (i % 2 ? 4 : 2) * f(lo + i * h); return (s * h) / 3; };
    let lo = 0, hi = 10 * p.m;
    for (let i = 0; i < 60; i++) { const mid = (lo + hi) / 2; if (area(0, mid) < 0.5) lo = mid; else hi = mid; }
    return [lam, 1 - area(0, p.t), area(p.a, p.b), (lo + hi) / 2];
  },
  useIt: {
    say: ["Carbon-14's half-life is 5,730 years, which is the median of one atom's wait.",
      "After 11,460 years, two half-lives, e^(−2 ln 2) = 1/4 of it is left: that's how radiocarbon dating reads an age."],
    saves: { name: "halfLife", value: () => 5730, unit: "years", note: "carbon-14's half-life, the median wait" },
    scene: { scene: "dens", props: { mode: "exp", mean: 5730 / Math.LN2 } },
  },
  deeper: [
    "Inverse transform sampling: if U is uniform on (0, 1), then X = −ln(U)/λ is exponential. The same trick turns any CDF into a sampler (links `cs`).",
    "The exponential is the only continuous memoryless distribution: G(s + t) = G(s)G(t) for the tail G forces G(t) = e^(−λt). Parts that wear out have rising hazard rates instead (the Weibull family), and a sum of k exponential waits is a gamma distribution.",
  ],
};

interface P07 { mu: number; sigma: number; n: number; z: number }
const ZS_EASY = [1, 2], ZS = [0.5, 0.84, 1, 1.28, 1.5, 1.96, 2, 2.33, 2.5, 3, -0.5, -1];
const totalT = (p: P07) => p.n * p.mu + p.z * p.sigma * Math.sqrt(p.n);

export const pr07: B2Lesson<P07> = {
  id: "b2-pr-07", track: "pr", unit: 2, title: "The central limit theorem",
  youCan: "find the chance a total of many random pieces passes a cutoff, whatever the pieces look like.",
  needs: ["b2-pr-03", "st-normal", "st-sampdist"],
  tools: ["clt", "dens"],
  play: { scene: "clt", props: { shape: "lopsided", n: 1 },
    say: "Pick or drag any population shape, even lopsided or two-humped. Drag the sample size n from 1 to 50: the histogram of sample means turns into a bell and narrows. The Galton board below pushes each ball by the same lopsided piece, and its pile is still a bell." },
  guess: { scene: "clt", props: { shape: "lopsided", n: 25, quiet: true, bracket: true }, kind: "slider", min: 0, max: 10, step: 0.25, start: 6, answer: 3.92, near: 0.8, unit: "either side",
    format: x => `±${x.toFixed(2)}`,
    ask: "The population's SD is σ = 10. Drag the bracket to where the middle 95% of sample means of size 25 will fall.",
    revealProps: { auto: true },
    reveal: "About ±4: the means have SD 10/√25 = 2, and the middle 95% sits within 1.96 SDs, so ±3.92." },
  nameIt: {
    say: [
      "A sum of many independent pieces is close to normal, whatever each piece looks like. That's the **central limit theorem**.",
      "The sum of n has mean nμ and SD σ√n; the average has mean μ and SD σ/√n.",
    ],
    formula: ["Sₙ ≈ Normal(nμ, σ√n) (mean, SD)", "z = (S − nμ) / (σ√n)"],
  },
  workIt: {
    reference: { mu: 8, sigma: 5, n: 25, z: 2 },
    generate(rng, i) {
      return { mu: rng.int(2, 20), sigma: rng.pick([2, 3, 4, 5, 6, 10]), n: rng.pick([4, 9, 16, 25, 36, 100]), z: rng.pick(i < 3 ? ZS_EASY : ZS) };
    },
    show: p => `Each piece has mean **${p.mu}** and SD **${p.sigma}** (made up). Add up **${p.n}** independent pieces. What's the chance the total passes **${trim(totalT(p), 2)}**?`,
    steps(p) {
      const r = Math.sqrt(p.n), sdT = p.sigma * r, T = totalT(p), up = tableUpper(p.z);
      return [
        wholeStep("mean", "Mean of the total", p.n * p.mu, { hint: `n × μ = ${p.n} × ${p.mu}.` }),
        wholeStep("sd", "SD of the total", sdT, { hint: `σ√n = ${p.sigma} × √${p.n}.`,
          slips: [slip("nσ", p.n * p.sigma, `SDs don't add; variances do. The total's variance is ${p.n} × ${p.sigma}², so its SD is ${p.sigma} × √${p.n} = ${sdT}.`),
            slip("σ/√n", p.sigma / r, "σ/√n is the SD of the average. For the total, it's σ√n.")] }),
        numStep("z", "z", p.z, 2, { hint: `(${trim(T, 2)} − ${group(p.n * p.mu)}) / ${sdT}.` }),
        numStep("p", `P(total > ${trim(T, 2)})`, up, 4, { hint: `Look up the upper tail for z = ${trim(p.z, 2)} in the table.`,
          slips: [slip("lower tail", Math.round((1 - up) * 1e4) / 1e4, `You need the chance of more than ${trim(T, 2)}: the upper tail.`)] }),
      ];
    },
    scene: p => ({ scene: "clt", props: { shape: "lopsided", n: Math.min(50, p.n) } }),
  },
  oracle: p => {
    const z = (totalT(p) - p.n * p.mu) / (p.sigma * Math.sqrt(p.n));
    const row = [[0, 0.5], [0.5, 0.3085], [0.84, 0.2005], [1, 0.1587], [1.28, 0.1003], [1.5, 0.0668], [1.96, 0.025], [2, 0.0228], [2.33, 0.0099], [2.5, 0.0062], [3, 0.0013]]
      .find(([v]) => Math.abs(v! - Math.abs(z)) < 1e-9)!;
    return [p.n * p.mu, p.sigma * Math.sqrt(p.n), z, z >= 0 ? row[1]! : 1 - row[1]!];
  },
  useIt: {
    say: ["An elevator's limit is 1,350 kg. Riders weigh 75 kg on average with SD 15 (made up). With 16 riders, the total has mean 1,200 and SD 60, so z = 2.5.",
      "The chance of an overload is about 0.0062, whatever the shape of one rider's weight."],
    saves: { name: "zSum", value: () => 2.5, note: "the elevator's z for 16 riders" },
    scene: { scene: "clt", props: { shape: "lopsided", n: 16 } },
  },
  deeper: [
    "A proof sketch: the log of the moment generating function of a standardized sum tends to t²/2, the normal's. The Berry–Esseen bound says how fast: the error is at most C E|X − μ|³/(σ³√n).",
    "It fails without a finite variance: sums of Cauchy pieces stay Cauchy, and heavy-tailed sums go to other stable laws. Pieces that aren't identical still work under the Lindeberg condition: no single piece dominates.",
  ],
};

interface P08 { mx: number; my: number; sx: number; sy: number; rho: number; k: number }
const RHOS = [0.25, 0.4, 0.5, 0.6, 0.75, 0.8, -0.5, -0.6];
const SDS = [2, 4, 5, 10, 20];

export const pr08: B2Lesson<P08> = {
  id: "b2-pr-08", track: "pr", unit: 2, title: "Correlation and the best prediction",
  youCan: "predict one measurement from another and say how much is left unexplained.",
  needs: ["b2-pr-03", "st-lsrl"],
  tools: ["cloud", "graph2d"],
  play: { scene: "cloud", props: { rho: 0.6 },
    say: "A cloud of points from a two-variable bell. Drag σx, σy and the correlation ρ: the covariance ellipse stretches and tilts. Drag the thin slice along x, and a dot marks the middle of the points in that slice." },
  guess: { scene: "cloud", props: { rho: 0.5, slice: 2, quiet: true }, kind: "point", answer: [2, 1], near: 0.35, start: [2, 2],
    ask: "Equal SDs and ρ = 0.5. Place the middle of the slice at x two SDs above average.",
    reveal: "One SD up, below the ellipse's long axis. The best prediction moves only ρ SDs for each SD of x." },
  nameIt: {
    say: [
      "**Correlation** is covariance in SD units. The best prediction of y from x is the slice's middle, which moves only ρ SDs for each SD of x.",
      "What's left over has SD σy√(1 − ρ²).",
    ],
    formula: ["ρ = Cov(X, Y) / (σx σy)", "E[Y | X = x] = μy + ρ (σy/σx)(x − μx)", "ẑy = ρ zx", "leftover SD = σy √(1 − ρ²)"],
  },
  workIt: {
    reference: { mx: 170, my: 60, sx: 10, sy: 5, rho: 0.6, k: 2 },
    generate(rng, i) {
      for (;;) {
        const sx = rng.pick(SDS), sy = rng.pick(SDS), rho = i < 3 ? 0.5 : rng.pick(RHOS);
        const cov = rho * sx * sy;
        if (Math.abs(cov - Math.round(cov)) > 1e-9) continue;
        return { mx: rng.int(4, 18) * 10, my: rng.int(2, 12) * 10, sx, sy, rho, k: i < 3 ? 2 : rng.pick([-2, -1, 1, 2, 3]) };
      }
    },
    show: p => `Made-up measurements: x has mean **${p.mx}** and SD **${p.sx}**; y has mean **${p.my}** and SD **${p.sy}**; Cov(X, Y) = **${trim(Math.round(p.rho * p.sx * p.sy))}**. One person has **x = ${p.mx + p.k * p.sx}**.`,
    steps(p) {
      const cov = Math.round(p.rho * p.sx * p.sy), sdProduct = p.sx * p.sy, zy = p.rho * p.k, y = p.my + zy * p.sy;
      const out = [
        numStep("rho", "ρ", p.rho, 2, { hint: `Cov / (σx σy) = ${trim(cov)} / ${sdProduct}.`,
          slips: [p.sx !== p.sy && slip("over σx²", cov / (p.sx * p.sx), `Divide by both SDs: σx σy = ${sdProduct}.`)] }),
        wholeStep("zx", "z of x", p.k, { hint: `(${p.mx + p.k * p.sx} − ${p.mx}) / ${p.sx}.` }),
        numStep("zy", "Predicted z of y", zy, 2, { hint: `ρ × z of x = ${trim(p.rho)} × ${trim(p.k)}.`,
          slips: [slip("kept z", p.k, "The prediction is pulled toward the mean: multiply by ρ.")] }),
        numStep("y", "Predicted y", y, 2, { hint: `μy + (predicted z) × σy = ${p.my} ${signTerm2b(zy * p.sy)}.`,
          slips: [slip("long axis", p.my + Math.sign(p.rho) * p.k * p.sy, "The long axis overshoots. The slice's middle is the best prediction.")] }),
      ];
      if (Math.abs(p.rho) === 0.6 || Math.abs(p.rho) === 0.8) {
        out.push(numStep("left", "Leftover SD", p.sy * Math.sqrt(1 - p.rho * p.rho), 2, { hint: `σy √(1 − ρ²) = ${p.sy} × √(1 − ${trim(p.rho * p.rho)}).`,
          slips: [slip("no root", p.sy * (1 - p.rho * p.rho), "Take the square root: σy √(1 − ρ²).")] }));
      }
      return out;
    },
    scene: p => ({ scene: "cloud", props: { rho: p.rho, sx: p.sx, sy: p.sy, slice: p.k } }),
  },
  oracle: p => {
    const cov = p.rho * p.sx * p.sy, r = cov / Math.sqrt(p.sx ** 2 * p.sy ** 2), x = p.mx + p.k * p.sx;
    const out = [r, (x - p.mx) / p.sx, (r * (x - p.mx)) / p.sx, p.my + (cov / p.sx ** 2) * (x - p.mx)];
    if (Math.abs(p.rho) === 0.6 || Math.abs(p.rho) === 0.8) out.push(Math.sqrt(p.sy ** 2 - cov ** 2 / p.sx ** 2));
    return out;
  },
  useIt: {
    say: ["Predict a child's adult height from a parent's, with made-up means 170 cm, SDs 8 cm and ρ = 0.5. A parent at 186 cm, two SDs up, predicts a child at 178 cm: one SD up.",
      "Tall parents' children are predicted tall, but less so. b2-pr-17 picks this up."],
    saves: { name: "rho", value: () => 0.5, note: "parent and child heights, made up" },
    scene: { scene: "cloud", props: { rho: 0.5, slice: 2 } },
  },
  deeper: [
    "The ellipse's axes are the eigenvectors of the covariance matrix: that is principal component analysis (links b2-la-19). For a multivariate normal, the slice's middle is μ₁ + Σ₁₂Σ₂₂⁻¹(x₂ − μ₂), and its spread is the Schur complement.",
    "There are two regression lines: y on x and x on y. Both are flatter than the long axis in their own direction, because each is pulled toward its own mean.",
  ],
};
const signTerm2b = (x: number) => (x < 0 ? `− ${trim(-x)}` : `+ ${trim(x)}`);

export const UNIT12 = [pr01, pr02, pr03, pr04, pr05, pr06, pr07, pr08];
