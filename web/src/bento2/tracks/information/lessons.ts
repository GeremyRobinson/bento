// Information and entropy's 12 lessons, b2-in-01 to b2-in-12, built from curriculum/specs/bento2/information.md block
// by block.
import type { B2Lesson, SceneRef } from "../../model";
import { fracStep, multiStep, numStep, slip, tapStep, wholeStep } from "../../make";
import { formatAnswer, group } from "../../steps";
import type { Rng } from "../../../curriculum/generators/rng";
import {
  capacity, crossEntropy, entropy, entropyOfCounts, h2, huffman, huffmanLengthSets, kraft, log2, prefixDecode, repetitionFail, sum, syndrome,
} from "./maths";

type Fr = [number, number];
const val = (f: Fr) => f[0] / f[1];
const showFr = (f: Fr) => (f[1] === 10 ? `0.${f[0]}` : f[1] === 1 ? String(f[0]) : `${f[0]}/${f[1]}`);
const fr = (x: number) => formatAnswer(x, "fraction");
const n2 = (x: number) => group(x, 2);
const n3 = (x: number) => group(x, 3);
const isPow2 = (d: number) => d >= 1 && (d & (d - 1)) === 0;
const dyadic = (f: Fr) => f[0] === 1 && isPow2(f[1]);
const list = (xs: string[]) => xs.join(", ");
const LETTERS = "ABCDEFGH";
const SUP: Record<string, string> = { "-": "⁻", "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹" };
const sup = (n: number) => String(n).replace(/./g, d => SUP[d] ?? d);
/** "1 bits" → "1 bit" wherever a lone 1 meets a plural unit */
export const singular = (t: string) => t.replace(/(^|[^\d.,/−])1 (bits|questions|blocks)\b/g, (_m, a: string, u: string) => `${a}1 ${u.slice(0, -1)}`);
/** a typed number: whole when the answer comes out whole, else to `places` decimals */
const numOr = (id: string, label: string, answer: number, whole: boolean, places: number, c: Parameters<typeof numStep>[4]) =>
  whole ? wholeStep(id, label, answer, c) : numStep(id, label, answer, places, c);
/** a sorted, deterministic option list with the right one's index */
const options = (right: string, others: string[]) => {
  const all = [...new Set([right, ...others])].sort();
  return { all, at: all.indexOf(right) };
};

/** a random full binary tree's leaf depths, as probabilities 1/2^depth, largest first */
function dyadicTree(rng: Rng, leaves: number): Fr[] {
  let d = [0];
  while (d.length < leaves) {
    const i = rng.int(0, d.length - 1), x = d[i]!;
    d = [...d.slice(0, i), x + 1, x + 1, ...d.slice(i + 1)];
  }
  return d.sort((a, b) => a - b).map(x => [1, 2 ** x] as Fr);
}

/* ------------------------------------------------------------------ unit 1 ------------------------------------------------------------------ */

interface P01 { N: number; A: number; k: number }
export const in01: B2Lesson<P01> = {
  id: "b2-in-01", track: "in", unit: 1, title: "Bits are yes/no questions",
  youCan: "count how many yes/no questions it takes to pin down one choice out of many.",
  needs: ["g11-log"],
  tools: ["in-guess", "calc"],
  play: { scene: "in-guess", props: { mode: "number", N: 64 },
    say: "Think of a number from 1 to N and drag N from 2 to 1,024. The game asks \"is it in the top half?\" until it lands, drawing each question as a cut through the row, and the tally ticks up." },
  guess: { scene: "in-guess", props: { mode: "number", N: 1000, quiet: true }, kind: "slider", min: 1, max: 30, step: 1, start: 15, answer: 10, near: 0.5, unit: "questions",
    format: x => String(Math.round(x)),
    ask: "N is 1,000. How many questions does the game need, at most?",
    revealProps: { mode: "number", N: 1000, worst: true },
    reveal: "The game runs on its worst-case number and the tally lands on 10: 2¹⁰ = 1,024 is the first power of 2 past 1,000." },
  nameIt: {
    say: [
      "Each yes/no answer halves what's left. One answer is one **bit**.",
      "Picking one of N equally likely things takes log₂ N bits, and if you must use whole questions, round up. k independent choices from N each take k · log₂ N bits.",
    ],
    formula: ["bits = log₂ N", "questions = ⌈log₂ N⌉", "log₂ N = ln N / ln 2"],
  },
  workIt: {
    reference: { N: 100, A: 26, k: 3 },
    generate(rng, i) {
      if (i < 3) return { N: rng.pick([4, 8, 16]), A: rng.pick([2, 4, 8, 16]), k: rng.int(2, 5) };
      return { N: rng.pick([32, 64, 100, 256, 1000, 1024]), A: rng.pick([2, 4, 8, 16, 26, 32]), k: rng.int(2, 5) };
    },
    show: p => `Think of a number from 1 to **${group(p.N)}**. Then a code of **${p.k} letters**, each from an alphabet of **${p.A}**.`,
    steps(p) {
      const q = Math.ceil(log2(p.N)), b = log2(p.A), even = isPow2(p.A);
      return [
        wholeStep("q", "Questions", q, {
          ask: `Halving each time, how many yes/no questions pin down a number from 1 to ${group(p.N)}?`,
          hint: `Keep halving ${group(p.N)} until one is left: 2${sup(q)} = ${group(2 ** q)} is the first power of 2 that reaches it.`,
          slips: [
            slip("N over 2", p.N / 2, "That's after one question. Keep halving until one is left: that's log₂ N questions."),
            Number.isInteger(Math.log10(p.N)) && slip("base 10", Math.log10(p.N), `Bits use base 2, since each answer splits two ways. log₂ ${group(p.N)} ≈ ${n2(log2(p.N))}, so ${q} questions.`),
            !isPow2(p.N) && slip("rounded down", q - 1, `${q - 1} questions only reach 2${sup(q - 1)} = ${group(2 ** (q - 1))}. Round up: whole questions have to cover all ${group(p.N)}.`),
          ],
        }),
        numOr("b", "Bits for one letter, exact", b, even, 2, {
          unit: "bits", ask: even ? `One letter out of ${p.A}: log₂ ${p.A}.` : `One letter out of ${p.A}: log₂ ${p.A}, to 2 decimals.`,
          hint: `log₂ ${p.A} = ln ${p.A} / ln 2.`,
          slips: [slip("base 10", Math.log10(p.A), `Bits use base 2: log₂ ${p.A} = ln ${p.A} / ln 2.`), slip("halved", p.A / 2, "That's after one question. Bits count the halvings: log₂ of the alphabet size.")],
        }),
        numOr("k", `Bits for ${p.k} letters`, p.k * b, even, 2, {
          unit: "bits", hint: `${p.k} independent letters: ${p.k} × log₂ ${p.A}.`,
          slips: [slip("added k", p.k + b, "Independent choices multiply the possibilities, N^k, so their bits add: k · log₂ N.")],
        }),
      ];
    },
    scene: p => ({ scene: "in-guess", props: { mode: "number", N: p.N } }),
  },
  oracle: p => [Math.ceil(Math.log2(p.N)), Math.log2(p.A), p.k * Math.log2(p.A)],
  useIt: {
    say: ["How many bits does one letter of a 26-letter alphabet need with no tricks? log₂ 26 ≈ 4.70.",
      "That's `bits_flat`, the starting line every Shrinker result is compared to."],
    saves: { name: "bits_flat", value: () => Math.log2(26), unit: "bits per letter", note: "one of 26 letters, with no tricks" },
    scene: { scene: "in-guess", props: { mode: "number", N: 26 } },
  },
  deeper: [
    "Why log? Ask for a measure f(N) that adds for independent choices, f(MN) = f(M) + f(N), and grows with N. Any such f is c · log N (Cauchy's functional equation for monotone f).",
    "That's Hartley's 1928 measure, and choosing base 2 makes c = 1 bit.",
  ],
};

interface P02 { p: Fr; a: number; b: number; cmp: [Fr, Fr] }
const EASY_P: Fr[] = [[1, 2], [1, 4], [1, 8], [1, 16]];
const LATER_P: Fr[] = [[1, 32], [1, 64], [1, 6], [1, 10], [3, 4]];
const CMP_P: Fr[] = [[1, 2], [1, 3], [1, 4], [2, 5], [1, 6], [3, 10], [1, 8], [3, 8], [3, 4], [1, 10]];
const halvings = (d: number) => {
  const chain = ["1"];
  for (let x = 2; x <= d; x *= 2) chain.push(`1/${x}`);
  return chain.length > 6 ? `${chain.slice(0, 3).join(" → ")} → … → 1/${d}` : chain.join(" → ");
};
const WORD = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"];

export const in02: B2Lesson<P02> = {
  id: "b2-in-02", track: "in", unit: 1, title: "The surprise of one event",
  youCan: "turn a probability into bits of surprise.",
  needs: ["b2-in-01", "st-probrules"],
  tools: ["in-surprise", "calc"],
  play: { scene: "in-surprise", props: { mode: "one", p: 0.25 },
    say: "Drag a probability p from 1 down to 1/1,000. A spinner with a slice of size p spins, and a surprise bar beside it grows as the slice shrinks: slowly at first, then fast." },
  guess: { scene: "in-surprise", props: { mode: "one", p: 0.125, quiet: true }, kind: "slider", min: 0, max: 6, step: 0.1, start: 1, answer: 3, near: 0.25, unit: "bits",
    format: x => x.toFixed(1),
    ask: "An event with p = 1/2 is 1 bit of surprise. How surprising is p = 1/8?",
    revealProps: { mode: "one", p: 0.125, halve: true },
    reveal: "The meter fills to 3. The spinner shows 1/8 as three halvings: 1 → 1/2 → 1/4 → 1/8." },
  nameIt: {
    say: [
      "Rare things carry more news. The surprise of an outcome with probability p is how many halvings it takes to get from 1 down to p.",
      "Surprises of independent events add, because their probabilities multiply.",
    ],
    formula: ["s(p) = log₂(1/p) = −log₂ p", "s(p · q) = s(p) + s(q)"],
  },
  workIt: {
    reference: { p: [1, 16], a: 2, b: 3, cmp: [[1, 6], [1, 4]] },
    generate(rng, i) {
      const p = rng.pick(i < 3 ? EASY_P : LATER_P);
      const pool = i < 3 ? EASY_P : CMP_P;
      const x = rng.pick(pool);
      let y = rng.pick(pool);
      while (val(y) === val(x)) y = rng.pick(pool);
      return { p, a: rng.int(1, i < 3 ? 4 : 6), b: rng.int(1, i < 3 ? 4 : 6), cmp: [x, y] };
    },
    show: p => `An event has probability **p = ${showFr(p.p)}**. Two independent events have p = **1/${2 ** p.a}** and **1/${2 ** p.b}**.`,
    steps(p) {
      const s = log2(p.p[1] / p.p[0]), even = dyadic(p.p);
      const right = val(p.cmp[0]) < val(p.cmp[1]) ? 0 : 1;
      return [
        numOr("s", "Surprise", s, even, 2, {
          unit: "bits", ask: even ? `log₂(1/p) for p = ${showFr(p.p)}.` : `log₂(1/p) for p = ${showFr(p.p)}, to 2 decimals.`,
          hint: even ? `Count halvings: ${halvings(p.p[1])}.` : `log₂(${showFr([p.p[1], p.p[0]])}) = ln(${showFr([p.p[1], p.p[0]])}) / ln 2.`,
          slips: [
            slip("negative", -s, "Surprise is −log₂ p, and log₂ p is negative for p < 1, so the surprise is positive."),
            slip("one over p", p.p[1] / p.p[0], even ? `Count halvings: ${halvings(p.p[1])} is ${WORD[s] ?? s}.` : "That's 1/p itself. The surprise is its log: how many times 2 goes into it."),
            slip("p itself", val(p.p), even ? `Count halvings: ${halvings(p.p[1])} is ${WORD[s] ?? s}.` : "That's p. The surprise is log₂(1/p), which grows as p shrinks."),
          ],
        }),
        wholeStep("two", "Two independent events", p.a + p.b, {
          unit: "bits", ask: `Both happen: p = 1/${2 ** p.a} × 1/${2 ** p.b}. How surprising is that?`,
          hint: `Probabilities multiply, so surprises add: ${p.a} + ${p.b}.`,
          slips: [slip("multiplied", p.a * p.b, `Probabilities multiply, so surprises add: ${p.a} + ${p.b} = ${p.a + p.b}.`)],
        }),
        tapStep("cmp", "Which is more surprising?", p.cmp.map(f => `p = ${showFr(f)}`), right, {
          hint: "The smaller the chance, the bigger the surprise.",
          slips: [slip("likelier", 1 - right, "Rare things carry more news: the smaller p is, the bigger the surprise.")],
        }),
      ];
    },
    scene: p => ({ scene: "in-surprise", props: { mode: "one", p: val(p.p) } }),
  },
  oracle: p => [Math.log2(1 / val(p.p)), Math.log2(2 ** p.a) + Math.log2(2 ** p.b), val(p.cmp[0]) < val(p.cmp[1]) ? 0 : 1],
  useIt: {
    say: ["A weather app says 10% chance of rain, and it rains. How many bits of news was that? log₂(1/0.1) = log₂ 10 ≈ 3.32.",
      "Had it stayed dry, the news would have been log₂(1/0.9) ≈ 0.15 bits: you mostly expected that."],
    scene: { scene: "in-surprise", props: { mode: "one", p: 0.1 } },
  },
  deeper: [
    "Shannon's requirements for a surprise function (it depends only on p, it's continuous and decreasing, and it adds over independent events) force s(p) = −c log p.",
    "The natural log version is measured in nats; 1 nat = 1/ln 2 ≈ 1.443 bits. Machine learning losses are usually in nats.",
  ],
};

interface P03 { ps: Fr[]; cmp: [Fr[], Fr[]] }
const NON_DYADIC: Fr[][] = [
  [[1, 3], [1, 3], [1, 3]], [[5, 10], [3, 10], [2, 10]], [[4, 10], [3, 10], [3, 10]], [[7, 10], [2, 10], [1, 10]], [[4, 10], [4, 10], [2, 10]], [[1, 2], [1, 3], [1, 6]],
];
const CMP_DISTS: Fr[][] = [
  [[1, 2], [1, 4], [1, 4]], [[1, 4], [1, 4], [1, 4], [1, 4]], [[1, 2], [1, 2]], [[1, 2], [1, 4], [1, 8], [1, 8]], [[3, 4], [1, 4]], [[7, 10], [2, 10], [1, 10]],
  [[1, 3], [1, 3], [1, 3]], [[9, 10], [1, 10]],
];
const showDist = (d: Fr[]) => `(${d.map(showFr).join(", ")})`;
const Hd = (d: Fr[]) => entropy(d.map(val));

export const in03: B2Lesson<P03> = {
  id: "b2-in-03", track: "in", unit: 1, title: "Entropy: average surprise",
  youCan: "compute the entropy of a distribution, the average number of bits it takes.",
  needs: ["b2-in-02", "st-expected"],
  tools: ["in-surprise", "in-guess"],
  play: { scene: "in-surprise", props: { mode: "bars" },
    say: "Drag the heights of up to 8 probability bars. Under each, its surprise bar; across both, a level line at the weighted average. Flatten the bars and the line rises; pile everything on one bar and the line drops to 0." },
  guess: { scene: "in-surprise", props: { mode: "bars", preset: "half", quiet: true }, kind: "slider", min: 0, max: 2, step: 0.05, start: 1, answer: 1.5, near: 0.08, unit: "bits",
    format: x => x.toFixed(2),
    ask: "Three outcomes at 1/2, 1/4, 1/4. Where does the average surprise land?",
    revealProps: { mode: "bars", preset: "half" },
    reveal: "It settles at 1.5: half the time 1 bit, a quarter of the time 2, a quarter of the time 2." },
  nameIt: {
    say: [
      "**Entropy** is the expected surprise: each outcome's surprise times how often it happens, added up. It's the fewest bits per outcome any code can average.",
      "It's largest, log₂ n, when all n outcomes are equally likely, and 0 when one outcome is certain.",
    ],
    formula: ["H(X) = Σ p(x) · log₂(1/p(x))", "0 ≤ H ≤ log₂ n"],
  },
  workIt: {
    reference: { ps: [[1, 2], [1, 4], [1, 4]], cmp: [[[1, 2], [1, 4], [1, 4]], [[1, 4], [1, 4], [1, 4], [1, 4]]] },
    generate(rng, i) {
      const ps = i < 3 ? dyadicTree(rng, rng.int(3, 4)) : i < 6 ? dyadicTree(rng, rng.int(5, 8)) : rng.pick(NON_DYADIC);
      const pool = i < 3 ? CMP_DISTS.slice(0, 5) : CMP_DISTS;
      const a = rng.pick(pool);
      let b = rng.pick(pool);
      while (Math.abs(Hd(a) - Hd(b)) < 0.05) b = rng.pick(pool);
      return { ps, cmp: [a, b] };
    },
    show: p => `A distribution over **${p.ps.length} outcomes**: ${showDist(p.ps)}.`,
    steps(p) {
      const s = p.ps.map(f => log2(1 / val(f))), even = p.ps.every(dyadic), H = Hd(p.ps), n = p.ps.length;
      const right = Hd(p.cmp[0]) > Hd(p.cmp[1]) ? 0 : 1;
      return [
        multiStep("s", "Surprise of each outcome", s, even ? "whole" : 3, {
          boxes: p.ps.map(f => `p = ${showFr(f)}`),
          hint: even ? "Count halvings for each: 1/2 is 1 bit, 1/4 is 2, 1/8 is 3." : "Each is log₂(1/p), to 3 decimals.",
          slips: [slip("one over p", p.ps.map(f => f[1] / f[0]), "That's 1/p. The surprise is log₂(1/p): how many halvings reach p.")],
        }),
        tapStep("w", "Weight each", ["Multiply each surprise by its p", "Divide the sum by the number of outcomes", "Keep only the largest surprise"], 0, {
          hint: "An average over outcomes that happen at different rates weights each by its rate.",
          slips: [slip("unweighted", 1, "Common outcomes happen more often, so they count more. Weight each surprise by its p.")],
        }),
        numStep("H", "Entropy", H, 3, {
          unit: "bits", ask: "Add up p × surprise, to 3 decimals.",
          hint: `Σ p · log₂(1/p): ${p.ps.map((f, i) => `${showFr(f)} × ${even ? s[i] : n3(s[i]!)}`).join(" + ")}.`,
          slips: [
            slip("unweighted", sum(s) / n, "Common outcomes happen more often, so they count more. Weight each surprise by its p."),
            slip("sign", -H, "That sum is negative. Entropy uses log₂(1/p), which flips the sign."),
            slip("max", log2(n), "log₂ n is the maximum, reached only when every outcome is equally likely."),
          ],
        }),
        tapStep("cmp", "More or less?", p.cmp.map(showDist), right, {
          ask: "Which distribution has the higher entropy?",
          hint: "The flatter the chances, the more bits each outcome takes on average.",
          slips: [slip("peaked", 1 - right, "Flatter spreads carry more bits: the closer to equal the chances, the higher the entropy.")],
        }),
      ];
    },
    scene: p => ({ scene: "in-surprise", props: { mode: "bars", dist: p.ps.map(val).join(",") } }),
  },
  oracle: p => [...p.ps.map(f => Math.log2(f[1] / f[0])), 0, p.ps.reduce((a, f) => a + val(f) * Math.log2(1 / val(f)), 0), Hd(p.cmp[0]) > Hd(p.cmp[1]) ? 0 : 1],
  useIt: {
    say: ["A die roll has entropy log₂ 6 ≈ 2.585 bits; a 4-sided die has 2.",
      "So recording a game with an ordinary die needs more bits per roll: about 2.585 on average with a good code, and 3 if every roll gets its own whole number of bits."],
    scene: { scene: "in-surprise", props: { mode: "bars", dist: "1,1,1,1,1,1" } },
  },
  deeper: [
    "Prove H ≤ log₂ n with Jensen's inequality (log is concave), or with Gibbs' inequality Σ p log(p/q) ≥ 0 using q uniform.",
    "Then the chain rule H(X, Y) = H(X) + H(Y | X), and Khinchin's theorem: entropy is the only measure, up to a constant, that is continuous, maxed by the uniform distribution, and obeys the chain rule.",
  ],
};

interface P04 { p: Fr; n: number }
const COIN_EASY: Fr[] = [[1, 2], [1, 4], [3, 4]];
const COIN_LATER: Fr[] = [[1, 8], [1, 10], [2, 10], [9, 10], [8, 10], [7, 8]];

export const in04: B2Lesson<P04> = {
  id: "b2-in-04", track: "in", unit: 1, title: "The loaded coin",
  youCan: "read the entropy of a two-way choice off its curve, and say how many bits n flips need.",
  needs: ["b2-in-03"],
  tools: ["in-surprise", "graph2d"],
  play: { scene: "in-surprise", props: { mode: "coin", p: 0.7 },
    say: "Drag a coin's chance of heads p from 0 to 1. The coin flips live, a running \"bits per flip\" tally settles, and a dot rides the entropy curve: 1 at p = 1/2, falling to 0 at both ends." },
  guess: { scene: "in-surprise", props: { mode: "coin", p: 0.9, quiet: true }, kind: "choice", options: ["About 0.1", "About 0.5", "About 0.9"], answer: 1,
    ask: "At p = 0.9 the coin lands heads 9 times in 10. How many bits per flip?",
    revealProps: { mode: "coin", p: 0.9, runs: 200 },
    reveal: "The curve answers 0.469, and the tally from 200 live flips lands near it. Predictable flips are cheap, but the rare tails still cost 3.32 bits each." },
  nameIt: {
    say: [
      "A coin with heads chance p has entropy H(p). It's symmetric (p and 1 − p give the same value), and it's 1 bit only for a fair coin.",
      "A loaded coin can be recorded in fewer bits per flip: long runs of n flips need about n · H(p) bits.",
    ],
    formula: ["H(p) = p log₂(1/p) + (1 − p) log₂(1/(1 − p))"],
  },
  workIt: {
    reference: { p: [1, 10], n: 1000 },
    generate(rng, i) { return { p: rng.pick(i < 3 ? COIN_EASY : COIN_LATER), n: rng.pick([100, 1000]) }; },
    show: p => `A coin lands heads with chance **p = ${showFr(p.p)}**. You record **${group(p.n)} flips**.`,
    steps(p) {
      const x = val(p.p), sh = log2(1 / x), st = log2(1 / (1 - x)), H = h2(x), q: Fr = [p.p[1] - p.p[0], p.p[1]];
      return [
        numStep("h", "Surprise of heads", sh, 3, { unit: "bits", hint: `log₂(1/${showFr(p.p)}).`, slips: [slip("negative", -sh, "Surprise is log₂(1/p): positive for any p below 1.")] }),
        numStep("t", "Surprise of tails", st, 3, {
          unit: "bits", hint: `Tails has chance 1 − p = ${showFr(q)}: log₂(1/${showFr(q)}).`,
          slips: [slip("heads again", sh, `Tails comes with chance 1 − p = ${showFr(q)}, so its surprise is log₂(1/${showFr(q)}).`)],
        }),
        numStep("H", "H(p)", H, 3, {
          unit: "bits per flip", hint: `Weight each surprise by its chance: ${showFr(p.p)} × ${n3(sh)} + ${showFr(q)} × ${n3(st)}.`,
          slips: [
            slip("heads only", x * sh, "That's only the heads part. Add the tails part, weighted by 1 − p."),
            slip("one bit", 1, "A loaded coin is more predictable, so it carries less than 1 bit per flip."),
            slip("unweighted", (sh + st) / 2, "Heads and tails don't happen equally often: weight each surprise by its chance."),
          ],
        }),
        wholeStep("n", `Bits for ${group(p.n)} flips`, Math.round(p.n * H), {
          unit: "bits", ask: "n · H(p), to the nearest whole bit.", hint: `${group(p.n)} × ${n3(H)}.`,
          slips: [slip("one bit each", p.n, "A loaded coin is more predictable, so it carries less than 1 bit per flip.")],
        }),
      ];
    },
    scene: p => ({ scene: "in-surprise", props: { mode: "coin", p: val(p.p) } }),
  },
  oracle: p => { const x = val(p.p), H = x * Math.log2(1 / x) + (1 - x) * Math.log2(1 / (1 - x)); return [Math.log2(1 / x), Math.log2(1 / (1 - x)), H, Math.round(p.n * H)]; },
  useIt: {
    say: ["Project: your surprise profile. Type a sentence: Bento counts its letters and spaces, draws each one's surprise, and works out the entropy per letter.",
      "Save it to keep `H_msg` and `counts_msg`. That's the Shrinker's target line."],
    project: "in-profile",
  },
  deeper: [
    "The asymptotic equipartition property. Of the 2ⁿ sequences of n flips, almost all the probability sits on about 2^(n·H(p)) \"typical\" ones, each with probability about 2^(−n·H(p)).",
    "The counting version: C(n, pn) ≈ 2^(n·H(p)), from Stirling's formula. This is the engine of Shannon's source coding theorem (b2-in-07).",
  ],
};

/* ------------------------------------------------------------------ unit 2 ------------------------------------------------------------------ */

interface P05 { lens: number[]; code: string[]; bits: string }
const BASE_CODE = ["0", "10", "110", "111"];
const lettersOf = (xs: number[]) => xs.map(x => LETTERS[x]).join(" ");
/** the reader who stops at 11 and calls it the two-bit letter */
function buggyDecode(bits: string, code: string[]): number[] {
  const one = code.indexOf("0"), two = code.indexOf("10");
  const out: number[] = [];
  let i = 0;
  while (i < bits.length) {
    if (bits[i] === "0") { out.push(one); i += 1; continue; }
    if (i + 1 >= bits.length) break;
    if (bits[i + 1] === "0") { out.push(two); i += 2; continue; }
    out.push(two); i += 2;
  }
  return out;
}

export const in05: B2Lesson<P05> = {
  id: "b2-in-05", track: "in", unit: 2, title: "Codes you can read without commas",
  youCan: "tell whether a set of code lengths can work, and decode a prefix code.",
  needs: ["b2-in-01"],
  tools: ["in-codes"],
  play: { scene: "in-codes", props: { mode: "free" },
    say: "Edit codewords for four letters (like 0, 10, 110, 111) and send a bit string through. Each codeword is a leaf on a binary tree, shaded by the space it uses up. Make one codeword the start of another and the reader stalls on a fork." },
  guess: { scene: "in-codes", props: { mode: "free", lens: "1,1,2,2", quiet: true }, kind: "choice", options: ["Yes", "No"], answer: 1,
    ask: "Can 4 letters have codewords of lengths 1, 1, 2 and 2?",
    revealProps: { mode: "free", lens: "1,1,2,2", place: true },
    reveal: "No. The two 1-bit leaves take the whole tree, so the 2-bit leaves have nowhere to go: 1/2 + 1/2 + 1/4 + 1/4 = 3/2." },
  nameIt: {
    say: [
      "A **prefix code** never uses one codeword as the start of another, so a reader can split a bit stream with no commas.",
      "A codeword of length ℓ uses up 2^(−ℓ) of the tree. Lengths fit exactly when those shares add to at most 1: the **Kraft inequality**.",
    ],
    formula: ["Σ 2^(−ℓᵢ) ≤ 1"],
  },
  workIt: {
    reference: { lens: [1, 2, 3, 3], code: BASE_CODE, bits: "0110100111" },
    generate(rng, i) {
      const m = i < 3 ? rng.int(3, 4) : rng.int(3, 6), top = i < 3 ? 3 : 5;
      const lens = Array.from({ length: m }, () => rng.int(1, top)).sort((a, b) => a - b);
      const code = i < 3 ? BASE_CODE : rng.shuffle(BASE_CODE);
      for (;;) {
        const msg: number[] = [];
        let bits = "";
        while (bits.length < 8) { const x = rng.int(0, 3); msg.push(x); bits += code[x]; }
        if (bits.length <= 14 && msg.some(x => code[x]!.length === 3)) return { lens, code, bits };
      }
    },
    show: p => `Lengths **{${list(p.lens.map(String))}}**. Then the code ${p.code.map((c, i) => `${LETTERS[i]} = ${c}`).join(", ")} and the bits **${p.bits}**.`,
    steps(p) {
      const K = kraft(p.lens), fits = K <= 1;
      const right = lettersOf(prefixDecode(p.bits, p.code)!);
      const bug = lettersOf(buggyDecode(p.bits, p.code));
      const dec = prefixDecode(p.bits, p.code)!;
      const swapAt = dec.findIndex((x, i) => i > 0 && x !== dec[i - 1]);
      const swapped = swapAt > 0 ? lettersOf([...dec.slice(0, swapAt - 1), dec[swapAt]!, dec[swapAt - 1]!, ...dec.slice(swapAt + 1)]) : lettersOf([...dec].reverse());
      const shifted = lettersOf(dec.map(x => (x + 1) % 4));
      const o = options(right, [bug, swapped, shifted].filter(x => x !== right));
      return [
        fracStep("K", "Kraft sum", K, {
          ask: `Add 2^(−ℓ) for ${p.lens.length === 1 ? "the length" : "each length"}: ${p.lens.map(l => `1/${2 ** l}`).join(" + ")}.`,
          hint: "A length ℓ uses a share 1/2^ℓ of the tree: 1 bit is 1/2, 2 bits 1/4, 3 bits 1/8.",
          slips: [slip("summed lengths", sum(p.lens), "Each length ℓ uses a share 2^(−ℓ) of the tree, not ℓ. Add 1/2 + 1/4 + …")],
        }),
        tapStep("fit", "Possible?", ["Yes", "No"], fits ? 0 : 1, {
          ask: "Is there a prefix code with these lengths?",
          hint: "Kraft: the lengths fit exactly when the shares add to at most 1.",
          done: `Possible? ${fits ? `Yes: ${fr(K)} is at most 1` : `No: ${fr(K)} is more than 1`}`,
          slips: [fits
            ? slip("said no", 1, `The shares add to ${fr(K)}, at most 1, so the leaves fit: some prefix code has these lengths.`)
            : slip("said yes", 0, "Above 1 means the leaves need more room than the tree has. No prefix code fits.")],
        }),
        tapStep("dec", "Decode", o.all, o.at, {
          ask: `Read ${p.bits} left to right, stopping at each full codeword.`,
          hint: "Take bits one at a time until they spell a codeword, write its letter, and start again.",
          slips: [bug !== right && slip("stopped at 11", o.all.indexOf(bug), `${LETTERS[p.code.indexOf("10")]} is 10, and 11 isn't a codeword. Read left to right and stop at the first full codeword: 1, 11, 110 is ${LETTERS[p.code.indexOf("110")]}.`)],
        }),
      ];
    },
    scene: p => ({ scene: "in-codes", props: { mode: "free", code: p.code.join(","), bits: p.bits } }),
  },
  oracle: p => {
    const K = p.lens.reduce((a, l) => a + 2 ** -l, 0);
    // greedy decode, independently
    const out: string[] = [];
    let cur = "";
    for (const b of p.bits) { cur += b; const k = p.code.indexOf(cur); if (k >= 0) { out.push(LETTERS[k]!); cur = ""; } }
    const right = out.join(" ");
    const s = in05.workIt.steps(p)[2]!;
    return [K, K <= 1 ? 0 : 1, s.choices!.indexOf(right)];
  },
  useIt: {
    say: ["Try codeword lengths for the four most common letters in your sentence. 1, 2, 3, 3 adds to exactly 1: a perfect fit.",
      "Morse-like 1, 1, 2, 2 adds to 3/2, so no prefix code fits. Morse gets away with it by putting gaps between letters: the gap is a comma."],
    scene: { scene: "in-codes", props: { mode: "free", code: "0,1,00,01" } },
  },
  deeper: [
    "McMillan's theorem: every uniquely decodable code (not only prefix codes) obeys Kraft.",
    "Proof: raise the Kraft sum to the k-th power, count the strings of each length it can hit, and let k → ∞. So prefix codes lose nothing.",
  ],
};

interface P06 { counts: number[]; ask: number }
const HUFF_EASY = [[8, 4, 2, 2], [4, 2, 1, 1], [16, 8, 4, 4], [2, 1, 1, 4]];
/** every letter whose Huffman length doesn't depend on how ties are broken */
const steadyLetters = (counts: number[]) => huffmanLengthSets(counts).flatMap((s, i) => (s.size === 1 ? [i] : []));
const pairText = (i: number, j: number) => `${LETTERS[Math.min(i, j)]} and ${LETTERS[Math.max(i, j)]}`;
function firstMergeChoices(counts: number[]) {
  const ord = counts.map((c, i) => [c, i] as const).sort((a, b) => a[0] - b[0] || a[1] - b[1]);
  const lo = ord[0]!, lo2 = ord[1]!, hi = ord[ord.length - 1]!, hi2 = ord[ord.length - 2]!;
  const right = pairText(lo[1], lo2[1]);
  const heavy = pairText(hi[1], hi2[1]);
  const mixedPartner = [...ord].reverse().find(x => x[0] > lo2[0] && x[1] !== hi[1]) ?? hi;
  const mixed = pairText(lo[1], mixedPartner[1]);
  const o = options(right, [heavy, mixed].filter(x => x !== right));
  return { ...o, heavy };
}

export const in06: B2Lesson<P06> = {
  id: "b2-in-06", track: "in", unit: 2, title: "Huffman's tree: short codes for common letters",
  youCan: "build the shortest prefix code for a set of letter counts.",
  needs: ["b2-in-05", "b2-in-03"],
  tools: ["in-codes", "notebook"],
  play: { scene: "in-codes", props: { mode: "huffman", counts: "8,4,2,2" },
    say: "Letter tiles sit on the bench with their counts. Tap \"merge\" and the two lightest join under a new node with their total; repeat until one tree remains. The message re-encodes live as a bit strip that shortens with each merge." },
  guess: { scene: "in-codes", props: { mode: "huffman", counts: "8,4,2,2", quiet: true }, kind: "slider", min: 16, max: 32, step: 1, start: 32, answer: 28, near: 0.5, unit: "bits",
    format: x => String(Math.round(x)),
    ask: "Counts 8, 4, 2, 2 on 16 letters. A plain code uses 2 bits each, 32 bits total. How many bits will the Huffman code use?",
    revealProps: { mode: "huffman", counts: "8,4,2,2", auto: true },
    reveal: "The strip shrinks to 28: the merges weigh 4, 8 and 16, and every merge adds one bit to each letter under it." },
  nameIt: {
    say: [
      "**Huffman's rule:** keep merging the two lightest groups. Each merge adds one bit to every letter inside it, so the total length is the sum of the merged weights.",
      "No prefix code does better for those counts. When every probability is a power of 1/2, the average length equals the entropy exactly.",
    ],
    formula: ["total bits = Σ count × length = sum of all merged weights", "H ≤ average length < H + 1"],
  },
  workIt: {
    reference: { counts: [5, 2, 1, 1, 1], ask: 0 },
    generate(rng, i) {
      for (;;) {
        const counts = i < 3 ? rng.shuffle(rng.pick(HUFF_EASY)) : Array.from({ length: rng.int(5, 6) }, () => rng.int(1, 20));
        if (new Set(counts).size === 1) continue;
        const steady = steadyLetters(counts);
        if (!steady.length) continue;
        return { counts, ask: rng.pick(steady) };
      }
    },
    show: p => `Letter counts: ${p.counts.map((c, i) => `**${LETTERS[i]}** ${c}`).join(", ")}, so a message of **${sum(p.counts)} letters**.`,
    steps(p) {
      const { lengths, total, merges } = huffman(p.counts);
      const M = sum(p.counts), k = p.counts.length, len = lengths[p.ask]!;
      const fm = firstMergeChoices(p.counts);
      const most = p.counts[p.ask] === Math.max(...p.counts), fixed = Math.ceil(log2(k));
      return [
        tapStep("m1", "First merge", fm.all, fm.at, {
          ask: "Which two tiles merge first?", hint: "The two with the smallest counts.",
          slips: [slip("heaviest", fm.all.indexOf(fm.heavy), "Merge the two lightest. Rare letters should end up deep in the tree, with long codes.")],
        }),
        wholeStep("len", `Length of ${LETTERS[p.ask]}`, len, {
          unit: "bits", ask: `Build the whole tree. How deep does ${LETTERS[p.ask]} sit?`,
          hint: "Each merge that includes the letter adds one bit to its code: count the merges above it.",
          slips: [most
            ? slip("common long", Math.max(...lengths), "Depth is length. The common letter merges last, so it sits near the top with a short code.")
            : slip("rare short", Math.min(...lengths), "Depth is length. A rare letter merges early, so it sits deep in the tree with a long code.")],
        }),
        wholeStep("tot", "Total bits", total, {
          unit: "bits", hint: `Add the merged weights: ${merges.join(" + ")}.`,
          slips: [slip("sum of counts", M, "Each letter costs count × length bits, not count × 1.")],
        }),
        numStep("bpl", "Bits per letter", total / M, 2, {
          ask: "Total bits over the letters in the message, to 2 decimals.", hint: `${total} / ${M}.`,
          slips: [slip("per symbol", total / k, `Divide by the letters in the message, ${M}, not by the ${k} different letters.`)],
        }),
        wholeStep("fix", "Fixed-length size", fixed * M, {
          unit: "bits", ask: `For comparison: a code with the same length for all ${k} letters.`,
          hint: `${k} letters need ⌈log₂ ${k}⌉ = ${fixed} bits each, × ${M} letters.`,
          slips: [slip("k per letter", k * M, `A fixed code needs only enough bits to number ${k} letters: ⌈log₂ ${k}⌉ = ${fixed}.`)],
        }),
      ];
    },
    scene: p => ({ scene: "in-codes", props: { mode: "huffman", counts: p.counts.join(",") } }),
  },
  oracle: p => {
    // a heap-style Huffman, independently: repeatedly take the two smallest
    const pool = [...p.counts];
    let total = 0;
    while (pool.length > 1) { pool.sort((a, b) => a - b); const w = pool.shift()! + pool.shift()!; total += w; pool.push(w); }
    const s = in06.workIt.steps(p);
    const M = p.counts.reduce((a, b) => a + b, 0);
    return [s[0]!.answer[0]!, huffmanLengthSets(p.counts)[p.ask]!.values().next().value!, total, total / M, Math.ceil(Math.log2(p.counts.length)) * M];
  },
  useIt: {
    say: ["Project: your first code. Bento builds the Huffman code for your sentence's letter counts and shows the code table, the shrunk size, and bits per letter next to `H_msg` and 8.",
      "Save it to keep `code_msg`. That's Shrinker v1."],
    project: "in-code",
  },
  deeper: [
    "The exchange-argument proof that Huffman is optimal: in some optimal tree the two rarest letters are siblings at the deepest level, and merging them reduces to a smaller problem.",
    "Canonical Huffman codes send only the lengths. Block coding (pairs of letters) pushes the overhead from under 1 bit per letter to under 1/k.",
  ],
};

interface P07 { n: number; k: number; counts: number[]; tapH: number; tapL: [number, number, number] }
const effOf = (counts: number[]) => {
  const H = Number(entropyOfCounts(counts).toFixed(3)), L = Number((huffman(counts).total / sum(counts)).toFixed(2));
  return { H, L, e: H / L };
};
const TAP_H = [1.75, 1.5, 2.25, 1.875, 2.5, 1.585, 2.322];

export const in07: B2Lesson<P07> = {
  id: "b2-in-07", track: "in", unit: 2, title: "What can't shrink",
  youCan: "explain why no compressor shrinks every file, and say how close a code is to the entropy floor.",
  needs: ["b2-in-06", "b2-in-04"],
  tools: ["in-bits", "in-codes"],
  play: { scene: "in-bits", props: { mode: "shrink" },
    say: "Compress a sentence: the bar shrinks. Tap \"random noise\" to replace it with random bits of the same length and compress again: the bar doesn't move, or grows a little. Drag the noise's bias from 1/2 toward 0 and the bar shrinks again as the bits become predictable." },
  guess: { scene: "in-bits", props: { mode: "count", n: 20, k: 8, quiet: true }, kind: "slider", min: 0, max: 100, step: 0.1, start: 25, answer: 100 / 128, near: 1, unit: "%",
    format: x => x.toFixed(1),
    ask: "Of all 20-bit files, what share can any compressor shrink by 8 bits or more?",
    revealProps: { mode: "count", n: 20, k: 8 },
    reveal: "Under 1/128, less than 0.8%. Every string of 12 bits or fewer, laid out as boxes, covers only a sliver of the 2²⁰ files." },
  nameIt: {
    say: [
      "There are 2ⁿ files of n bits but only 2ⁿ − 1 shorter strings, so some file never shrinks, and only a tiny share can shrink much. Compression works by spending fewer bits on likely messages and more on unlikely ones.",
      "**Shannon's source coding theorem:** no code beats H bits per letter on average, and codes can get within 1 bit (within 1/k bits using blocks of k letters).",
    ],
    formula: ["#(strings shorter than n) = 2ⁿ − 1", "share shrinkable by ≥ k bits < 2^(1 − k)", "H ≤ L < H + 1"],
  },
  workIt: {
    reference: { n: 4, k: 8, counts: [3, 3, 2, 1, 1], tapH: 1.75, tapL: [1.6, 1.75, 2.8] },
    generate(rng, i) {
      const n = rng.pick(i < 3 ? [3, 4, 8, 10] : [16, 20, 32]);
      const k = rng.int(2, Math.min(10, n - 1));
      let counts: number[];
      for (;;) {
        counts = Array.from({ length: rng.int(4, 6) }, () => rng.int(1, 10));
        if (new Set(counts).size === 1) continue;
        const { e } = effOf(counts);
        const x = e * 1000;
        if (Math.abs(x - Math.floor(x) - 0.5) > 0.05) break;
      }
      const H = rng.pick(TAP_H);
      const r2 = (x: number) => Math.round(x * 100) / 100;
      const tapL: [number, number, number] = [r2(H - rng.int(10, 40) / 100), r2(H + rng.int(0, 90) / 100), r2(H + 1 + rng.int(5, 60) / 100)];
      return { n, k, counts, tapH: H, tapL };
    },
    show: p => {
      const { H, L } = effOf(p.counts);
      return `Files of **n = ${p.n} bits**, shrunk by **k = ${p.k}** or more. Then letter counts ${list(p.counts.map(String))}: entropy **H = ${n3(H)}** and Huffman average **L = ${n2(L)}** bits per letter.`;
    },
    steps(p) {
      const { H, L, e } = effOf(p.counts);
      const valid = p.tapL.findIndex(x => x >= p.tapH && x < p.tapH + 1);
      const low = p.tapL.findIndex(x => x < p.tapH), high = p.tapL.findIndex(x => x >= p.tapH + 1);
      return [
        wholeStep("f", `Files of length ${p.n}`, 2 ** p.n, {
          hint: `Each of ${p.n} bits is 0 or 1: 2${sup(p.n)}.`,
          slips: [slip("2n", 2 * p.n, "Each bit doubles the count: 2 × 2 × … × 2, not 2 + 2 + … + 2.")],
        }),
        wholeStep("s", `Strings shorter than ${p.n}`, 2 ** p.n - 1, {
          ask: "Count every length from 0 (the empty string) up to n − 1.",
          hint: `1 + 2 + 4 + … + 2${sup(p.n - 1)} = 2${sup(p.n)} − 1.`,
          slips: [slip("only n − 1", 2 ** (p.n - 1), "Add every shorter length: 1 + 2 + 4 + … + 2ⁿ⁻¹ = 2ⁿ − 1.")],
        }),
        fracStep("share", `Bound on the share shrinkable by ${p.k}`, 1 / 2 ** (p.k - 1), {
          ask: "As a fraction: 1/2^(k − 1).",
          hint: `Strings of n − ${p.k} bits or fewer number 2^(n − ${p.k - 1}) − 1, under 2${sup(p.n)}/2${sup(p.k - 1)}.`,
          slips: [slip("1 over 2^k", 1 / 2 ** p.k, `Count every string of n − ${p.k} bits or fewer: 1 + 2 + … + 2^(n − ${p.k}) is just under 2^(n − ${p.k - 1}), so the share is under 1/2${sup(p.k - 1)}.`)],
        }),
        numStep("eff", "Efficiency", e, 3, {
          ask: "H / L, to 3 decimals.", hint: `${n3(H)} / ${n2(L)}.`,
          slips: [slip("flipped", L / H, "Efficiency is the floor over what you got: H / L, which is at most 1.")],
        }),
        tapStep("L", "Possible?", p.tapL.map(x => `L = ${n2(x)}`), valid, {
          ask: `H = ${group(p.tapH, p.tapH === Number(p.tapH.toFixed(2)) ? 2 : 3)} bits. Which average length could an optimal code have?`,
          hint: "Huffman lands between H and H + 1.",
          slips: [
            slip("below H", low, "No code averages fewer bits than the entropy. L ≥ H always."),
            slip("too long", high, "An optimal code gets within 1 bit of the entropy: H ≤ L < H + 1."),
          ],
        }),
      ];
    },
    scene: p => ({ scene: "in-bits", props: { mode: "count", n: Math.min(p.n, 24), k: p.k } }),
  },
  oracle: p => {
    const M = p.counts.reduce((a, b) => a + b, 0);
    const H = p.counts.reduce((a, c) => a + (c / M) * Math.log2(M / c), 0);
    const pool = [...p.counts];
    let total = 0;
    while (pool.length > 1) { pool.sort((a, b) => a - b); const w = pool.shift()! + pool.shift()!; total += w; pool.push(w); }
    return [2 ** p.n, 2 ** p.n - 1, 1 / 2 ** (p.k - 1), Number(H.toFixed(3)) / Number((total / M).toFixed(2)), p.tapL.findIndex(x => x >= p.tapH && x < p.tapH + 1)];
  },
  useIt: {
    say: ["Run the bit counter on your sentence and on a random string of the same length. Your sentence shrinks toward `H_msg`; the noise doesn't.",
      "A compressor that shrank everything could be run again on its own output until every file was one bit long. That can't be."],
    scene: { scene: "in-bits", props: { mode: "shrink", mine: true } },
  },
  deeper: [
    "The proof of the source coding theorem goes through typical sets (b2-in-04 Deeper): index only the ~2^(nH) typical sequences.",
    "**Kolmogorov complexity** K(x) is the length of the shortest program that prints x. Most strings have K(x) ≥ |x| − c (incompressible), and K itself can't be computed (see b2-cs-14).",
  ],
};

interface P08 { msg: string; ps: Fr[]; tops: Fr[] }
const MODEL_P: Fr[] = [[1, 2], [1, 3], [2, 3], [1, 4], [3, 4], [1, 5], [2, 5], [3, 5], [4, 5], [1, 8], [3, 8], [7, 8], [1, 10], [9, 10]];
const gcd = (a: number, b: number): number => (b ? gcd(b, a % b) : a);
const prodFr = (fs: Fr[]): Fr => { let n = 1, d = 1; for (const f of fs) { n *= f[0]; d *= f[1]; const g = gcd(n, d); n /= g; d /= g; } return [n, d]; };

export const in08: B2Lesson<P08> = {
  id: "b2-in-08", track: "in", unit: 2, title: "Compression is prediction",
  youCan: "count the bits an ideal coder spends on a message from a model's predictions.",
  needs: ["b2-in-07"],
  tools: ["in-guess"],
  play: { scene: "in-guess", props: { mode: "model" },
    say: "A model reads a message one letter at a time and shows a probability bar for what comes next. The interval strip from 0 to 1 zooms into the slice of the letter that actually came. Switch the model from \"letters alone\" to \"after the last letter\" and watch the bits fall." },
  guess: { scene: "in-guess", props: { mode: "model", text: "the quick queen quit quietly", at: 11, quiet: true }, kind: "choice", options: ["About 0", "About 1", "About 5"], answer: 0,
    ask: "After a q, the model gives u a probability of 0.98. How many bits does the u cost?",
    revealProps: { mode: "model", text: "the quick queen quit quietly", at: 11, q98: true },
    reveal: "About 0: log₂(1/0.98) = 0.03 bits. The strip barely narrows, because the model was almost sure." },
  nameIt: {
    say: [
      "A coder that knows the model's probabilities can spend log₂(1/p) bits on each letter, where p is what the model gave the letter that came.",
      "**Arithmetic coding** does this by narrowing an interval: the final width is the product of the probabilities, and its bits are log₂(1/width).",
      "Better predictions mean fewer bits, so compressing and predicting are the same skill. Context helps: H(next | previous) ≤ H(next).",
    ],
    formula: ["bits = Σ log₂(1/p(xᵢ | context))", "width = Π p(xᵢ | context)"],
  },
  workIt: {
    reference: { msg: "ABAC", ps: [[1, 2], [1, 4], [1, 2], [1, 8]], tops: [[1, 2], [1, 4], [1, 2], [1, 8]] },
    generate(rng, i) {
      for (;;) {
        const L = rng.int(4, 6);
        const msg = Array.from({ length: L }, () => "ABCD"[rng.int(0, 3)]).join("");
        const pool = i < 3 ? EASY_P : MODEL_P;
        const ps = Array.from({ length: L }, () => rng.pick(pool));
        if (prodFr(ps)[1] > 10000) continue;
        const tops = ps.map(p => {
          if (rng.next() > 0.35) return p;
          const better = pool.filter(t => val(t) > val(p) && val(t) + val(p) <= 1);
          return better.length ? rng.pick(better) : p;
        });
        return { msg, ps, tops };
      }
    },
    show: p => `The message is **${[...p.msg].join(" ")}**. The model gave the letters that came: ${p.ps.map(showFr).join(", ")}.${p.tops.some((t, i) => t !== p.ps[i]) ? ` Where it liked another letter more, its top pick had ${p.tops.map((t, i) => (t !== p.ps[i] ? `${showFr(t)} (letter ${i + 1})` : "")).filter(Boolean).join(", ")}.` : ""} A flat model gives each of A, B, C, D 1/4.`,
    steps(p) {
      const bits = p.ps.map(f => log2(f[1] / f[0])), total = sum(bits), even = p.ps.every(dyadic);
      const width = prodFr(p.ps), flat = 2 * p.msg.length, saved = flat - total;
      const form = even ? "whole" : 2, form1 = even ? "whole" : 1;
      return [
        multiStep("b", "Bits per letter", bits, form, {
          boxes: [...p.msg].map((c, i) => `${i + 1}: ${c}`),
          hint: even ? "log₂(1/p) for each: 1/2 is 1 bit, 1/4 is 2, 1/8 is 3." : "log₂(1/p) for each, to 2 decimals.",
          slips: [p.tops.some((t, i) => t !== p.ps[i]) && slip("top pick", p.tops.map(f => log2(f[1] / f[0])), "You pay for what actually happened. Use p of the true next letter, even when the model liked another one more.")],
        }),
        numOr("t", "Total bits", total, even, 1, {
          unit: "bits", ask: even ? undefined : "To 1 decimal.", hint: "Probabilities multiply; bits add.",
          slips: [slip("multiplied", bits.reduce((a, b) => a * b, 1), "Probabilities multiply; bits add.")],
        }),
        fracStep("w", "Final interval width", val(width), {
          ask: "As a fraction: the product of the probabilities.",
          hint: `${p.ps.map(showFr).join(" × ")}.`,
          slips: [slip("whole number", width[1] / width[0], `The width is a slice of [0, 1], so it's the product of fractions: ${p.ps.map(showFr).join(" × ")}.`)],
        }),
        numOr("sv", "Saved against the flat model", saved, even, 1, {
          unit: "bits", ask: `The flat model spends 2 bits a letter, ${flat} in all. Type flat minus model.`,
          hint: `${flat} − ${even ? total : group(total, 1)}.`,
          done: `Saved against the flat model: ${formatAnswer(saved, form1)} bits${saved < 0 ? ". This model is worse than guessing evenly." : ""}`,
          slips: [slip("backward", -saved, "Saved is flat minus model: positive when the model spends fewer bits.")],
        }),
      ];
    },
    scene: p => ({ scene: "in-guess", props: { mode: "strip", ps: p.ps.map(val).join(","), msg: p.msg } }),
  },
  oracle: p => {
    const b = p.ps.map(f => Math.log2(1 / val(f))), t = b.reduce((a, x) => a + x, 0);
    return [...b, t, p.ps.reduce((a, f) => a * val(f), 1), 2 * p.msg.length - t];
  },
  useIt: {
    say: ["Project: predict me. Bento trains a one-letter-context model on your sentence, then you play the guessing game against it. Its bits per letter drop below `H_msg`.",
      "Save it to keep `model_msg`. That's Shrinker v2."],
    project: "in-predict",
  },
  deeper: [
    "The entropy rate of a Markov source is lim H(Xₙ | Xₙ₋₁, …, X₁). Shannon's 1951 guessing experiment put English at roughly 0.6 to 1.3 bits per letter.",
    "Prediction by partial matching, and why a better language model is a better compressor (and the other way round). Finite precision arithmetic coding with renormalization.",
  ],
};

/* ------------------------------------------------------------------ unit 3 ------------------------------------------------------------------ */

interface P09 { p: Fr[]; q: Fr[]; batch: Fr[] }
const BATCH_EASY: Fr[] = [[1, 2], [1, 4], [1, 8], [1, 1]];
const BATCH_LATER: Fr[] = [[1, 2], [1, 4], [3, 4], [1, 3], [2, 3], [9, 10], [4, 5], [1, 10], [3, 5]];

export const in09: B2Lesson<P09> = {
  id: "b2-in-09", track: "in", unit: 3, title: "Cross-entropy: scoring a model in bits",
  youCan: "score a model's predictions with cross-entropy and read the extra bits it wastes.",
  needs: ["b2-in-08"],
  tools: ["in-surprise", "graph2d"],
  play: { scene: "in-surprise", props: { mode: "cross" },
    say: "Two rows of bars: the truth p, fixed by the data, and the model q, which you drag (each q bar stops at 0.01, so the meter stays finite). The meter shows cross-entropy H(p, q) with the floor H(p) drawn as a line. Drag q toward p and the meter drops onto the floor." },
  guess: { scene: "in-surprise", props: { mode: "cross", flat: true, quiet: true }, kind: "choice", options: ["1.75 bits", "2 bits", "2.25 bits"], answer: 1,
    ask: "The truth is (1/2, 1/4, 1/8, 1/8). The model guesses all four equally. Where's the meter?",
    revealProps: { mode: "cross", flat: true },
    reveal: "It lands on 2, with the floor at 1.75 and the gap of 0.25 shaded: the bits wasted by believing the flat model." },
  nameIt: {
    say: [
      "**Cross-entropy** is the average surprise of the truth when you code with a model's probabilities: H(p, q). It's never below H(p).",
      "The gap is the **KL divergence**, the bits wasted by believing q when the world is p. Training a language model means lowering this number, letter by letter.",
    ],
    formula: ["H(p, q) = Σ p(x) log₂(1/q(x))", "D(p ‖ q) = H(p, q) − H(p) ≥ 0"],
  },
  workIt: {
    reference: { p: [[1, 2], [1, 4], [1, 8], [1, 8]], q: [[1, 4], [1, 4], [1, 4], [1, 4]], batch: [[1, 2], [1, 4], [1, 2], [1, 1]] },
    generate(rng, i) {
      if (i < 3) {
        let p: Fr[];
        do p = dyadicTree(rng, 4); while (p.every(f => f[1] === 4));
        return { p: rng.shuffle(p), q: [[1, 4], [1, 4], [1, 4], [1, 4]], batch: Array.from({ length: 4 }, () => rng.pick(BATCH_EASY)) };
      }
      const n = rng.int(3, 4);
      const p = rng.shuffle(dyadicTree(rng, n));
      let q: Fr[];
      do q = rng.shuffle(dyadicTree(rng, n)); while (q.every((f, k) => f[1] === p[k]![1]));
      return { p, q, batch: Array.from({ length: rng.int(4, 6) }, () => rng.pick(BATCH_LATER)) };
    },
    show: p => `The truth is **p = ${showDist(p.p)}** and the model says **q = ${showDist(p.q)}**. On a batch of labels, the model gave the true labels ${p.batch.map(showFr).join(", ")}.`,
    steps(p) {
      const P = p.p.map(val), Q = p.q.map(val), H = entropy(P), X = crossEntropy(P, Q), R = crossEntropy(Q, P);
      const losses = p.batch.map(f => log2(f[1] / f[0])), avg = sum(losses) / losses.length;
      return [
        numStep("H", "H(p)", H, 3, { unit: "bits", hint: "Σ p log₂(1/p), the truth's own entropy.",
          slips: [slip("sign", -H, "Entropy uses log₂(1/p), which is positive: flip the sign.")] }),
        numStep("X", "H(p, q)", X, 3, {
          unit: "bits", hint: `Σ p log₂(1/q): ${P.map((_x, k) => `${showFr(p.p[k]!)} × ${group(log2(1 / Q[k]!), 0)}`).join(" + ")}.`,
          slips: [slip("swapped", R, "Weight by how often things really happen, p, and take the surprise from the model, q.")],
        }),
        numStep("D", "KL divergence", X - H, 3, {
          unit: "bits", ask: "H(p, q) − H(p).", hint: `${n3(X)} − ${n3(H)}.`,
          slips: [slip("negative", H - X, "KL can't be negative. Coding with the wrong model never beats coding with the right one.")],
        }),
        numStep("loss", "Average loss on the batch", avg, 2, {
          unit: "bits", ask: "The average of −log₂ q over the labels, to 2 decimals.",
          hint: `(${losses.map(x => group(x, Number.isInteger(x) ? 0 : 2)).join(" + ")}) / ${losses.length}.`,
          slips: [
            slip("averaged q", sum(p.batch.map(val)) / p.batch.length, "Loss is surprise, −log₂ q, averaged, not q itself."),
            slip("total", sum(losses), `That's the total. Divide by the ${losses.length} labels for the average.`),
          ],
        }),
      ];
    },
    scene: p => ({ scene: "in-surprise", props: { mode: "cross", p: p.p.map(val).join(","), q: p.q.map(val).join(",") } }),
  },
  oracle: p => {
    const P = p.p.map(val), Q = p.q.map(val);
    const H = P.reduce((a, x) => a + x * Math.log2(1 / x), 0), X = P.reduce((a, x, k) => a + x * Math.log2(1 / Q[k]!), 0);
    return [H, X, X - H, p.batch.reduce((a, f) => a + Math.log2(1 / val(f)), 0) / p.batch.length];
  },
  useIt: {
    say: ["Score `model_msg` on your sentence: its cross-entropy in bits per letter is the Shrinker's honesty check. Save it as `xent_msg`.",
      "This is the training loss of b2-ai-07, in bits, and the log-likelihood of b2-pr-09 turned upside down."],
    scene: { scene: "in-shrinker", props: { stage: "score" } },
  },
  deeper: [
    "Gibbs' inequality D(p ‖ q) ≥ 0 comes from ln x ≤ x − 1, with equality only at q = p. Minimizing cross-entropy on data is the same as maximizing likelihood.",
    "KL isn't symmetric and isn't a distance: forward and reverse KL do different things to a fitted model (mode-covering against mode-seeking). Fisher information is the curvature of KL near q = p.",
  ],
};

interface P10 { cells: number[][]; D: number }
const EIGHTHS: number[][] = [];
for (const a of [0, 1, 2, 4]) for (const b of [0, 1, 2, 4]) for (const c of [0, 1, 2, 4]) { const d = 8 - a - b - c; if ([0, 1, 2, 4].includes(d)) EIGHTHS.push([a, b, c, d]); }
const tableH = (t: P10) => {
  const rows = t.cells.map(r => sum(r) / t.D), cols = t.cells[0]!.map((_, j) => sum(t.cells.map(r => r[j]!)) / t.D);
  return { hx: entropy(rows), hy: entropy(cols), hxy: entropy(t.cells.flat().map(c => c / t.D)) };
};
const showTable = (t: P10) => t.cells.map(r => `(${r.map(c => (c === 0 ? "0" : fr(c / t.D))).join(", ")})`).join(" over ");

export const in10: B2Lesson<P10> = {
  id: "b2-in-10", track: "in", unit: 3, title: "Mutual information: what one thing tells you about another",
  youCan: "measure how many bits one variable tells you about another.",
  needs: ["b2-in-09"],
  tools: ["in-surprise", "matrix"],
  play: { scene: "in-surprise", props: { mode: "circles" },
    say: "Edit a 2 × 2 joint probability table by dragging its cells up or down. Two overlapping circles redraw live with areas H(X) and H(Y); the overlap is what they share. Make the table diagonal and the circles merge; make the rows proportional and they pull apart." },
  guess: { scene: "in-surprise", props: { mode: "circles", cells: "2,0,0,2", quiet: true }, kind: "slider", min: 0, max: 2, step: 0.05, start: 0.5, answer: 1, near: 0.08, unit: "bits",
    format: x => x.toFixed(2),
    ask: "X is a fair bit and Y is a perfect copy of X. How big is the overlap?",
    revealProps: { mode: "circles", cells: "2,0,0,2" },
    reveal: "The circles coincide at 1 bit: knowing Y tells you all of X." },
  nameIt: {
    say: [
      "**Mutual information** I(X; Y) is how much knowing Y cuts the uncertainty about X.",
      "It's symmetric, it's 0 exactly when X and Y are independent, and it's at most the smaller entropy. An empty cell adds nothing: 0 · log₂(1/0) counts as 0.",
    ],
    formula: ["I(X; Y) = H(X) − H(X | Y)", "I(X; Y) = H(X) + H(Y) − H(X, Y)"],
  },
  workIt: {
    reference: { cells: [[4, 0], [2, 2]], D: 8 },
    generate(rng, i) {
      if (i < 3) {
        const a = rng.pick([1, 2, 3]), b = rng.pick([1, 2, 3]);
        if (rng.next() < 0.5) return { cells: [[a * b, a * (4 - b)], [(4 - a) * b, (4 - a) * (4 - b)]], D: 16 };
        return { cells: [[a, 0], [0, 4 - a]], D: 4 };
      }
      if (i < 6) {
        const b = rng.int(1, 2);
        if (b === 2) return { cells: [0, 1, 2, 3].map(x => [0, 1, 2, 3].map(y => (x === y ? 1 : 0))), D: 4 };
        const high = rng.next() < 0.5;
        return { cells: [0, 1, 2, 3].map(x => [0, 1].map(y => ((high ? x >> 1 : x & 1) === y ? 1 : 0))), D: 4 };
      }
      const c = rng.pick(EIGHTHS);
      return { cells: [[c[0]!, c[1]!], [c[2]!, c[3]!]], D: 8 };
    },
    show: p => `A joint table for X (rows) and Y (columns), ${p.cells.length} × ${p.cells[0]!.length}: **${showTable(p)}**.`,
    steps(p) {
      const { hx, hy, hxy } = tableH(p);
      const rows = p.cells.map(r => sum(r)), cols = p.cells[0]!.map((_, j) => sum(p.cells.map(r => r[j]!)));
      const cellsWrong = slip("cells", hxy, "H(X) uses the row totals, not the cells themselves.");
      return [
        numStep("hx", "H(X)", hx, 3, { unit: "bits", ask: "From the row sums, to 3 decimals.", hint: `Row sums: ${rows.map(r => fr(r / p.D)).join(", ")}.`, slips: [cellsWrong] }),
        numStep("hy", "H(Y)", hy, 3, { unit: "bits", ask: "From the column sums.", hint: `Column sums: ${cols.map(c => fr(c / p.D)).join(", ")}.`,
          slips: [slip("cells", hxy, "H(Y) uses the column totals, not the cells themselves.")] }),
        numStep("hxy", "H(X, Y)", hxy, 3, { unit: "bits", ask: "From the cells; an empty cell adds 0.", hint: "Σ over every cell of p log₂(1/p)." }),
        numStep("I", "I(X; Y)", hx + hy - hxy, 3, {
          unit: "bits", hint: `H(X) + H(Y) − H(X, Y) = ${n3(hx)} + ${n3(hy)} − ${n3(hxy)}.`,
          slips: [
            slip("conditional", hxy - hx, "That's H(Y | X), what's left of Y after knowing X. Mutual information is the shared part: H(X) + H(Y) − H(X, Y)."),
            slip("negative", hxy - hx - hy, "Shared information can't be negative. Check H(X, Y): it's never more than H(X) + H(Y)."),
          ],
        }),
      ];
    },
    scene: p => ({ scene: "in-surprise", props: { mode: "circles", cells: p.cells.flat().join(","), cols: p.cells[0]!.length } }),
  },
  oracle: p => {
    const H = (xs: number[]) => xs.reduce((a, x) => a + (x > 0 ? (x / p.D) * Math.log2(p.D / x) : 0), 0);
    const rows = p.cells.map(r => r.reduce((a, b) => a + b, 0)), cols = p.cells[0]!.map((_, j) => p.cells.reduce((a, r) => a + r[j]!, 0));
    const hx = H(rows), hy = H(cols), hxy = H(p.cells.flat());
    return [hx, hy, hxy, hx + hy - hxy];
  },
  useIt: {
    say: ["How much does the previous letter tell you about the next one in your sentence? Bento prints I(previous; next) = H(next) − H(next | previous) for it, in bits.",
      "That shared information is exactly what `model_msg` exploits."],
    scene: { scene: "in-shrinker", props: { stage: "pairs" } },
  },
  deeper: [
    "The data-processing inequality: if X → Y → Z is a chain, I(X; Z) ≤ I(X; Y), so no processing of data creates information about the source.",
    "Conditional mutual information and the chain rule; the information bottleneck view of learning (b2-ai track); and I(X; Y) as the KL divergence between the joint and the product of the marginals.",
  ],
};

type P11 = { kind: "rep"; copies: string[]; f: number; fc: number } | { kind: "ham"; word: number[]; e: number; f: number; fc: number; late: boolean };
const bitsNum = (s: string) => Number(s);
const ones = (w: number[]) => w.flatMap((b, i) => (b ? [i + 1] : []));

export const in11: B2Lesson<P11> = {
  id: "b2-in-11", track: "in", unit: 3, title: "Codes that fix their own errors",
  youCan: "find and fix a flipped bit with a Hamming code.",
  needs: ["b2-in-04", "b2-cs-04"],
  tools: ["in-errorlab", "calc"],
  play: { scene: "in-errorlab", props: { mode: "hamming" },
    say: "A 7-cell board holds a codeword, with three parity circles drawn over it. Tap any cell to flip it: the circles that now hold an odd number of 1s light up, and together they point at the flipped cell. Switch to repetition and drag the noise f to see how often triple copies fail." },
  guess: { scene: "in-errorlab", props: { mode: "hamming", flip: 5, quiet: true }, kind: "choice", options: ["Circles 1 and 2", "Circles 1 and 4", "Circles 2 and 4", "All three"], answer: 1,
    ask: "Cell 5 gets flipped. Which parity circles light up?",
    revealProps: { mode: "hamming", flip: 5 },
    reveal: "Circles 1 and 4, because 5 = 4 + 1 in binary (101). The lit circles spell the bad cell's position." },
  nameIt: {
    say: [
      "Add redundancy cleverly and a code can repair noise. **Hamming (7, 4)** puts check bits at positions 1, 2 and 4, each covering the positions whose binary form has that bit set.",
      "XOR together the positions of all the 1s (the **syndrome**): 0 means no error, anything else is the position of the flipped bit.",
      "It sends 4 data bits in 7, a rate of 4/7; triple repetition only manages 1/3. For a channel that flips each bit with chance f, no code can send more than its capacity, 1 − H(f) bits per bit.",
    ],
    formula: ["syndrome = XOR of the positions holding a 1", "repetition fails with chance 3f²(1 − f) + f³", "capacity = 1 − H(f)"],
  },
  workIt: {
    reference: { kind: "ham", word: [1, 1, 1, 0, 1, 0, 0], e: 5, f: 0.1, fc: 0.1, late: true },
    generate(rng, i) {
      if (i < 3) {
        const msg = Array.from({ length: 4 }, () => rng.int(0, 1));
        const copies = [0, 1, 2].map(() => [...msg]);
        for (let k = 0; k < 4; k++) { const c = rng.int(-1, 2); if (c >= 0) copies[c]![k] = 1 - copies[c]![k]!; }
        if (copies[0]!.every((b, k) => b === msg[k])) { const k = rng.int(0, 3); copies[0]![k] = 1 - copies[0]![k]!; copies[1]![k] = msg[k]!; copies[2]![k] = msg[k]!; }
        return { kind: "rep", copies: copies.map(c => c.join("")), f: 0.1, fc: 0.1 };
      }
      const d = Array.from({ length: 4 }, () => rng.int(0, 1));
      const w = [0, 0, d[0]!, 0, d[1]!, d[2]!, d[3]!];
      for (const p of [1, 2, 4]) w[p - 1] = [3, 5, 6, 7].filter(q => q & p).reduce((x, q) => x ^ w[q - 1]!, 0);
      const e = rng.int(1, 7);
      w[e - 1] = 1 - w[e - 1]!;
      return { kind: "ham", word: w, e, f: rng.pick([0.1, 0.2]), fc: rng.pick([0.25, 0.1]), late: i >= 6 };
    },
    show: p => p.kind === "rep"
      ? `A 4-bit message was sent three times. The copies came back as **${p.copies.join(", ")}**.`
      : `A Hamming (7, 4) word arrives as **${p.word.join("")}** (positions 1 to 7, left to right). One bit was flipped on the way.${p.late ? ` Then a channel flips each bit with chance f = ${p.f} for repetition, and f = ${p.fc === 0.25 ? "1/4" : p.fc} for its capacity.` : ""}`,
    steps(p) {
      if (p.kind === "rep") {
        const maj = [0, 1, 2, 3].map(k => (p.copies.filter(c => c[k] === "1").length >= 2 ? 1 : 0));
        const first = [...p.copies[0]!].map(Number);
        return [
          multiStep("maj", "Majority bit at each position", maj, "whole", {
            boxes: ["1st", "2nd", "3rd", "4th"], hint: "At each position, take the bit at least two of the three copies agree on.",
            slips: [slip("first copy", first, "One copy can hold the flipped bit. At each position take the bit at least two of the three copies agree on.")],
          }),
          wholeStep("msg", "Decoded message", bitsNum(maj.join("")), {
            ask: "Type the 4 bits.", hint: `The majority bits in order: ${maj.join("")}.`, done: `Decoded message: ${maj.join("")}`,
            slips: [slip("first copy", bitsNum(p.copies[0]!), "One copy can hold the flipped bit. At each position take the bit at least two of the three copies agree on.")],
          }),
        ];
      }
      const pos = ones(p.word), s = syndrome(p.word);
      const fixed = [...p.word];
      fixed[s - 1] = 1 - fixed[s - 1]!;
      const nb = s === 7 ? 6 : s + 1, wrongFix = [...p.word];
      wrongFix[nb - 1] = 1 - wrongFix[nb - 1]!;
      const right = list(pos.map(String));
      const fromZero = list(p.word.flatMap((b, i) => (b ? [i] : [])).map(String));
      const zeros = list(p.word.flatMap((b, i) => (b ? [] : [i + 1])).map(String));
      const o = options(right, [fromZero, zeros].filter(x => x && x !== right));
      const steps = [
        tapStep("pos", "Positions holding a 1", o.all, o.at, {
          hint: "Count from 1 on the left and list where the 1s are.",
          slips: [slip("from zero", o.all.indexOf(fromZero), "Positions count from 1 on the left, so the first cell is position 1.")],
        }),
        wholeStep("syn", "Syndrome", s, {
          ask: "XOR the positions, as a number from 0 to 7.", hint: `${pos.join(" ⊕ ")}: add in binary with no carries.`,
          slips: [slip("added", sum(pos), `Add in binary with no carries: that's XOR. ${pos.join(" ⊕ ")} = ${s}.`)],
        }),
        wholeStep("fix", "Fixed word", bitsNum(fixed.join("")), {
          ask: "Type all 7 bits.", hint: `Flip position ${s}.`, done: `Fixed word: ${fixed.join("")}`,
          slips: [slip("neighbor", bitsNum(wrongFix.join("")), "The syndrome is the position itself, counting from 1 on the left.")],
        }),
      ];
      if (p.late) steps.push(
        numStep("rep", "Repetition failure", repetitionFail(p.f), 3, {
          ask: `Triple repetition with f = ${p.f}: the chance the majority is fooled.`, hint: `3f²(1 − f) + f³ with f = ${p.f}.`,
          slips: [slip("f cubed", p.f ** 3, "Two flips out of three also fool the majority: add 3f²(1 − f).")],
        }),
        numStep("cap", "Capacity", capacity(p.fc), 3, {
          unit: "bits per bit", ask: `1 − H(f) for f = ${p.fc === 0.25 ? "1/4" : p.fc}.`, hint: `H(${p.fc}) = ${n3(h2(p.fc))}.`,
          slips: [slip("H not 1 − H", h2(p.fc), "That's the noise's entropy, H(f). Capacity is what's left: 1 − H(f).")],
        }),
      );
      return steps;
    },
    scene: (p): SceneRef => (p.kind === "rep" ? { scene: "in-errorlab", props: { mode: "repeat", copies: p.copies.join(",") } } : { scene: "in-errorlab", props: { mode: "hamming", word: p.word.join("") } }),
  },
  oracle: p => {
    if (p.kind === "rep") {
      const maj = [0, 1, 2, 3].map(k => [0, 1, 2].reduce((a, c) => a + Number(p.copies[c]![k]), 0) >= 2 ? 1 : 0);
      return [...maj, Number(maj.join(""))];
    }
    const s = p.word.reduce((x, b, i) => (b ? x ^ (i + 1) : x), 0);
    const fixed = p.word.map((b, i) => (i === s - 1 ? 1 - b : b));
    const st = in11.workIt.steps(p);
    const out = [st[0]!.choices!.indexOf(list(p.word.flatMap((b, i) => (b ? [String(i + 1)] : [])))), s, Number(fixed.join(""))];
    if (p.late) out.push(3 * p.f ** 2 * (1 - p.f) + p.f ** 3, 1 - (p.fc * Math.log2(1 / p.fc) + (1 - p.fc) * Math.log2(1 / (1 - p.fc))));
    return out;
  },
  useIt: {
    say: ["Wrap the Shrinker's output in Hamming (7, 4) blocks: every 4 bits of code become 7.",
      "Save `armor` to keep the rate 4/7 and the protected size of your sentence. That's Shrinker v3."],
    scene: { scene: "in-shrinker", props: { stage: "armor" } },
  },
  deeper: [
    "Shannon's noisy-channel coding theorem: below capacity C = max I(X; Y), error rates can go to 0 at a fixed rate; above it, they can't. The Hamming bound and perfect codes; Hamming (7, 4) as a linear code with a 3 × 7 parity-check matrix (the la track).",
    "Modern codes that approach capacity: LDPC, turbo and polar codes; Reed-Solomon on CDs and QR codes. Quantum error correction picks this up in the qu track.",
  ],
};

interface P12 { N: number; S: number; H: number }
export const in12: B2Lesson<P12> = {
  id: "b2-in-12", track: "in", unit: 3, title: "The Shrinker, end to end",
  youCan: "run a message through a full compress, protect and decode pipeline and account for every bit.",
  needs: ["b2-in-06", "b2-in-08", "b2-in-09", "b2-in-11"],
  tools: ["in-shrinker", "in-bits", "in-guess"],
  play: { scene: "in-shrinker", props: { stage: "full" },
    say: "Type a message. The Shrinker strip shows each stage's size: 8 bits per letter raw, then Huffman, then the context model, then the armor. Drag the noise slider to flip random bits on the way and watch the decoder repair them, or fail when two land in one block." },
  guess: { scene: "in-shrinker", props: { stage: "sizes", N: 400, S: 900, quiet: true }, kind: "slider", min: 0, max: 3200, step: 25, start: 1600, answer: 1575, near: 100, unit: "bits",
    format: x => group(x),
    ask: "Your message is 400 letters and shrinks to 900 bits. After Hamming armor, is it still smaller than the raw 3,200 bits? Drag where the armored bar lands.",
    revealProps: { stage: "sizes", N: 400, S: 900 },
    reveal: "Yes: 900 bits is 225 blocks of 4, and each block becomes 7 bits, so 1,575. Still under half the raw size." },
  nameIt: {
    say: [
      "A real compressor is a model plus a coder: the model predicts, the coder spends log₂(1/p) bits on what came, and its bits per letter are the model's cross-entropy on the message.",
      "Protection then spends some bits back to survive noise. Compression and protection pull in opposite directions; Shannon showed they can be designed separately without loss.",
    ],
    formula: ["bits per letter = compressed bits / letters", "ratio = raw bits / compressed bits", "armored = ⌈compressed / 4⌉ × 7"],
  },
  workIt: {
    reference: { N: 400, S: 900, H: 4.1 },
    generate(rng, i) {
      if (i < 3) { const S = rng.pick([200, 300, 400]); return { N: 100, S, H: Math.round(S + rng.int(50, 200)) / 100 }; }
      const N = rng.pick([100, 200, 400, 1000]), step = N === 1000 ? 20 : 4;
      const S = step * rng.int(Math.ceil((1.5 * N) / step), Math.floor((4 * N) / step));
      return { N, S, H: Math.round((S / N) * 100 + rng.int(50, 200)) / 100 };
    },
    show: p => `A message of **${group(p.N)} letters** compresses to **${group(p.S)} bits** with the context model. Its letter-by-letter entropy is **H_msg = ${n2(p.H)}** bits per letter.`,
    steps(p) {
      const raw = 8 * p.N, bpl = p.S / p.N, blocks = Math.ceil(p.S / 4);
      return [
        wholeStep("raw", "Raw bits", raw, { unit: "bits", hint: `8 bits per letter × ${group(p.N)}.`,
          slips: [slip("one bit", p.N, "Plain text stores each letter in 8 bits (one byte).")] }),
        numStep("bpl", "Bits per letter", bpl, 2, { hint: `${group(p.S)} / ${group(p.N)}.`, slips: [slip("flipped", p.N / p.S, "Bits per letter is bits over letters.")] }),
        numStep("ratio", "Ratio", raw / p.S, 2, { ask: "Raw over compressed, to 2 decimals.", hint: `${group(raw)} / ${group(p.S)}.`,
          slips: [slip("flipped", p.S / raw, "Ratio is raw over compressed. Above 1 means it shrank."), Math.abs(p.S / raw - p.N / p.S) > 0.03 && slip("no bytes", p.N / p.S, "Plain text stores each letter in 8 bits (one byte).")] }),
        wholeStep("arm", "Armored size", blocks * 7, {
          unit: "bits", hint: `${group(p.S)} / 4 = ${group(blocks)} blocks, × 7.`,
          slips: [slip("times 4/7", Math.round((p.S * 4) / 7), "Armor adds bits: 4 data bits become 7, so multiply by 7/4.")],
        }),
        numStep("gain", "Gain from context", p.H - bpl, 2, {
          unit: "bits per letter", ask: "H_msg minus the model's bits per letter.", hint: `${n2(p.H)} − ${n2(bpl)}.`,
          slips: [slip("backward", bpl - p.H, "The model beats the letter-by-letter floor, so the gain is H_msg minus the model's bits per letter.")],
        }),
      ];
    },
    scene: p => ({ scene: "in-shrinker", props: { stage: "sizes", N: p.N, S: p.S } }),
  },
  oracle: p => [8 * p.N, p.S / p.N, (8 * p.N) / p.S, Math.ceil(p.S / 4) * 7, p.H - p.S / p.N],
  useIt: {
    say: ["The build: the Shrinker. Run your own message end to end: raw, `code_msg`, `model_msg`, `armor`, received with noise, decoded.",
      "Save it to put the full ledger (`H_msg`, `xent_msg` and the final bits per letter) in your Notebook."],
    project: "in-shrinker",
  },
  deeper: [
    "Universal compression (Lempel-Ziv) approaches the entropy rate of any stationary source without knowing its model. Minimum description length and Solomonoff induction: the best explanation is the shortest program, which ties learning to Kolmogorov complexity, and why that ideal is uncomputable (b2-cs-14).",
    "Rate-distortion theory handles lossy compression, where the payoff is a curve of bits against error (b2-la-20, the image compressor).",
  ],
};

export const INFORMATION_LESSONS = [in01, in02, in03, in04, in05, in06, in07, in08, in09, in10, in11, in12];
// "1 bit", not "1 bits": a done line's unit agrees with its number
for (const l of INFORMATION_LESSONS as B2Lesson<unknown>[]) {
  const make = l.workIt.steps;
  l.workIt.steps = p => make(p).map(s => ({ ...s, done: singular(s.done) }));
}
