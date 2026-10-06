// Computation, unit 2 (Algorithms and growth): b2-cs-06 to b2-cs-10, built from curriculum/specs/bento2/computation.md
// block by block.
import type { B2Lesson } from "../../model";
import { multiStep, slip, tapStep, wholeStep } from "../../make";
import { group } from "../../steps";
import type { Rng } from "../../../curriculum/generators/rng";
import { binaryTrace, bitLength, bubblePass, dijkstra, greedyWalk, inversions, neighbors, routeCounts, routeLength, type Graph } from "./maths";
import { LETTERS, WORD, g, options, pl, sup } from "./common";

const isPow2 = (n: number) => (n & (n - 1)) === 0;

/* ------------------------------------------------------------------ 06 ------------------------------------------------------------------ */

/** binary search that keeps the wrong half (the "went the wrong way" slip): the values it opens */
function wrongWay(list: number[], t: number): number[] {
  const out: number[] = [];
  let lo = 0, hi = list.length - 1;
  while (lo <= hi && out.length < 5) {
    const mid = Math.floor((lo + hi) / 2);
    out.push(list[mid]!);
    if (list[mid] === t) break;
    if (list[mid]! > t) lo = mid + 1; else hi = mid - 1;
  }
  return out;
}
const arrow = (xs: number[]) => xs.join(" → ");
function traceOptions(list: number[], t: number) {
  const ti = list.indexOf(t), right = arrow(binaryTrace(list, t).map(i => list[i]!));
  const nb = arrow([list[ti > 0 ? ti - 1 : ti + 1]!, t]), lin = arrow(list.slice(0, binaryTrace(list, t).length)), wrong = arrow(wrongWay(list, t));
  const o = options(right, [nb, lin, wrong].filter(x => x !== right));
  return { ...o, nb: o.all.indexOf(nb), lin: o.all.indexOf(lin), wrong: o.all.indexOf(wrong) };
}

interface P06 { n: number; list: number[]; t: number }
export const cs06: B2Lesson<P06> = {
  id: "b2-cs-06", track: "cs", unit: 2, title: "Searching: one by one or halving",
  youCan: "count the worst-case steps for linear and binary search.",
  needs: ["g11-log", "b2-in-01"],
  tools: ["cs-stage"],
  play: { scene: "cs-stage", props: { mode: "search", n: 15 },
    say: "A row of sorted numbered cards. Pick a target and race two searchers: one turns cards from the left, the other opens the middle and throws away half. Tap \"×10 input\" and the first searcher's count jumps ten times; the second adds about 3." },
  guess: { scene: "cs-stage", props: { mode: "search", n: 1000000, quiet: true }, kind: "slider", min: 0, max: 6, step: 0.01, start: 3, answer: Math.log10(20), near: 0.12,
    format: x => group(Math.max(1, Math.round(10 ** x))),
    ask: "1,000,000 sorted cards. How many cards does binary search open, at most? Drag the marker on the log strip.",
    revealProps: { mode: "search", n: 1000000, worst: true },
    reveal: "It lands on 20: each card opened halves what's left, and 20 halvings take a million down to one." },
  nameIt: {
    say: [
      "An **algorithm** is a recipe precise enough for a machine. **Linear search** checks items one at a time: n steps in the worst case.",
      "**Binary search** on sorted items checks the middle and discards half each time: the number of steps is the number of binary digits of n.",
    ],
    formula: ["linear worst = n", "binary worst = ⌊log₂ n⌋ + 1"],
  },
  workIt: {
    reference: { n: 1000, list: [2, 5, 8, 12, 16, 23, 38, 45, 56, 72, 77, 81, 90, 94, 99], t: 23 },
    generate(rng, i) {
      const n = rng.pick(i < 3 ? [7, 15, 16, 31] : [100, 1000, 1000000, 500, 2000]);
      const pool = rng.shuffle(Array.from({ length: i < 3 ? 50 : 99 }, (_, k) => k + 1));
      const list = pool.slice(0, 15).sort((a, b) => a - b);
      return { n, list, t: list[rng.pick([0, 1, 2, 4, 5, 6, 8, 9, 10, 12, 13, 14])]! };
    },
    show: p => `**${g(p.n)}** sorted cards. Then this list of 15, searching for **${p.t}**: ${p.list.join(", ")}.`,
    steps(p) {
      const b = bitLength(p.n), lg = Math.log2(p.n), o = traceOptions(p.list, p.t);
      return [
        wholeStep("lin", "Linear worst case", p.n, {
          ask: `Card by card from the left, how many cards might it turn over among ${g(p.n)}?`,
          hint: "In the worst case the target is the last card, or missing.",
          slips: [slip("average", p.n / 2, `That's the average. In the worst case the target is last, or missing: all ${g(p.n)} cards.`)],
        }),
        wholeStep("bin", "Binary worst case", b, {
          ask: `Opening the middle each time, how many cards might it open among ${g(p.n)}?`,
          hint: `Count the binary digits of ${g(p.n)}: 2${sup(b - 1)} = ${g(2 ** (b - 1))} ≤ ${g(p.n)} < 2${sup(b)} = ${g(2 ** b)}.`,
          slips: [
            slip("one short", b - 1, isPow2(p.n) ? `log₂ ${g(p.n)} = ${b - 1} halvings leaves one card, and opening it is a step too: ${b}.` : `One more: after ${b - 1} halvings one card is left, and opening it is a step too.`),
            !Number.isInteger(lg) && slip("unrounded", Number(lg.toFixed(2)), "You can't open part of a card. Count whole halvings: ⌊log₂ n⌋ + 1."),
            slip("half", p.n / 2, "That's one halving. It keeps halving what's left."),
          ],
        }),
        tapStep("trace", "Trace", o.all, o.at, {
          ask: `Searching the list of 15 for ${p.t}, which cards does binary search open, in order?`,
          hint: "Open the middle of what's left (rounding down), keep the half the target must be in, and repeat.",
          slips: [
            o.nb >= 0 && slip("neighbor", o.nb, "Always open the middle of what's left, not where you think the target is."),
            o.lin >= 0 && slip("linear", o.lin, "That's linear search, card by card from the left. Binary search opens the middle first."),
            o.wrong >= 0 && slip("wrong half", o.wrong, "Compare with the middle card: if the target is smaller, keep the left half; if bigger, the right."),
          ],
        }),
      ];
    },
    scene: p => ({ scene: "cs-stage", props: { mode: "search", n: Math.min(p.n, 1000000), quiet: true } }),
  },
  oracle: p => {
    const opened: number[] = [];
    let lo = 0, hi = 14;
    for (;;) { const m = (lo + hi) >> 1; opened.push(p.list[m]!); if (p.list[m] === p.t) break; if (p.list[m]! < p.t) lo = m + 1; else hi = m - 1; }
    return [p.n, p.n.toString(2).length, traceOptions(p.list, p.t).all.indexOf(opened.join(" → "))];
  },
  useIt: {
    say: ["A phone's contacts list has 2,000 names. How many checks does binary search need? 2,000 has 11 binary digits, so 11.",
      "Linear and binary search both go on the race card after cs-08."],
    scene: { scene: "cs-stage", props: { mode: "search", n: 2000 } },
  },
  deeper: [
    "A decision-tree lower bound: any comparison search must tell n outcomes apart with yes/no answers, so it needs ⌈log₂(n + 1)⌉ comparisons, the same count as b2-in-01.",
    "Hashing beats it on average by not comparing at all. Grover's quantum search finds an item among n unsorted ones in about √n steps (`qu`).",
  ],
};

/* ------------------------------------------------------------------ 07 ------------------------------------------------------------------ */

const ORD = ["1st", "2nd", "3rd", "4th", "5th", "6th", "7th"];
interface P07 { list: number[]; n: number }
export const cs07: B2Lesson<P07> = {
  id: "b2-cs-07", track: "cs", unit: 2, title: "The sorting race",
  youCan: "run bubble sort and merge sort by hand and count their comparisons.",
  needs: ["b2-cs-06"],
  tools: ["cs-stage", "cs-growth"],
  play: { scene: "cs-stage", props: { mode: "sort", n: 64 },
    say: "The same shuffled bars sort twice, side by side: bubble sort swaps neighbors pass after pass, while merge sort splits, sorts halves and zips them together. Comparison counters run under each, at the same speed. Drag the bar count from 8 to 1,024 and watch the gap widen." },
  guess: { scene: "cs-stage", props: { mode: "sort", n: 1024, quiet: true }, kind: "choice", options: ["About 2×", "About 10×", "About 50×"], answer: 2,
    ask: "For 1,024 bars, how many comparisons will bubble sort make compared with merge sort?",
    revealProps: { mode: "sort", n: 1024 },
    reveal: "The worst-case counts are 523,776 and 9,217, about 57×. Bubble sort (the full version, with no early exit) always makes 523,776; merge sort makes a little under 9,217 on this shuffle. Either way, 50× is closest." },
  nameIt: {
    say: [
      "**Bubble sort** compares neighbors and swaps those out of order. The full version makes n(n − 1)/2 comparisons, and its swaps equal the number of out-of-order pairs.",
      "**Merge sort** splits in half, sorts each half, and merges; for n = 2ᵏ items its comparisons are at most n·k − n + 1.",
      "Slow growth beats a fast start.",
    ],
    formula: ["bubble = n(n − 1)/2", "merge (n = 2ᵏ) ≤ n·k − n + 1", "swaps = inversions"],
  },
  workIt: {
    reference: { list: [5, 1, 4, 2, 8], n: 8 },
    generate(rng, i) {
      const len = i < 3 ? 5 : rng.int(6, 7);
      for (;;) {
        const list = rng.shuffle(Array.from({ length: 20 }, (_, k) => k + 1)).slice(0, len);
        if (inversions(list) >= 2) return { list, n: rng.pick(i < 3 ? [8, 16] : [8, 16, 32, 1024]) };
      }
    },
    show: p => `The list **[${p.list.join(", ")}]**. Then counts for **n = ${g(p.n)}** items.`,
    steps(p) {
      const pass = bubblePass(p.list), L = p.list.length, inv = inversions(p.list), k = Math.log2(p.n);
      const min = Math.min(...p.list), toFront = [min, ...p.list.filter(x => x !== min)];
      const firstPassSwaps = countPassSwaps(p.list);
      return [
        multiStep("pass", "After one bubble pass", pass, "whole", {
          boxes: ORD.slice(0, L), ask: "Compare each neighboring pair from left to right, swapping any out of order. Type the list after one pass.",
          hint: "The largest number gets carried all the way to the end; everything it passes slides one place left.",
          done: `After one pass: [${pass.join(", ")}]`,
          slips: [
            slip("smallest first", toFront, "One pass carries the largest to the end; small items move left only one place per pass."),
            slip("all sorted", [...p.list].sort((a, b) => a - b), "That's the finished sort. One pass only carries the largest to the end."),
          ],
        }),
        wholeStep("swaps", "Total swaps", inv, {
          ask: "Sorting all the way, how many swaps will bubble sort make? Count the out-of-order pairs.",
          hint: "Each pair with the bigger number first gets swapped exactly once.",
          slips: [
            slip("comparisons", (L * (L - 1)) / 2, "Every neighbor pair is compared; only out-of-order ones swap."),
            slip("one pass", firstPassSwaps, "That's the first pass. Keep passing: every out-of-order pair swaps once in all."),
          ],
        }),
        wholeStep("bubble", "Bubble comparisons", (p.n * (p.n - 1)) / 2, {
          ask: `For n = ${g(p.n)}, how many comparisons does the full bubble sort make?`,
          hint: "Each pair of items is compared once: n(n − 1)/2.",
          slips: [
            slip("n squared", p.n * p.n, `Each pair is compared once: n(n − 1)/2 = ${g((p.n * (p.n - 1)) / 2)}.`),
            slip("not halved", p.n * (p.n - 1), "Each pair is compared once, not twice: halve it."),
          ],
        }),
        wholeStep("merge", "Merge comparisons, worst case", p.n * k - p.n + 1, {
          ask: `For n = ${g(p.n)} = 2${sup(k)}, the most comparisons merge sort can make.`,
          hint: `n·k − n + 1 with k = ${k}.`,
          slips: [
            slip("n log n", p.n * k, `That's n log₂ n, the rough size. Each merge saves at least one comparison: n·k − n + 1 = ${g(p.n * k - p.n + 1)}.`),
            slip("bubble", (p.n * (p.n - 1)) / 2, "That's bubble sort's count. Merge sort does about log₂ n levels of n comparisons."),
          ],
        }),
      ];
    },
    scene: p => ({ scene: "cs-stage", props: { mode: "sort", n: p.n, quiet: true } }),
  },
  oracle: p => {
    const a = [...p.list];
    for (let i = 0; i + 1 < a.length; i++) if (a[i]! > a[i + 1]!) { const t = a[i]!; a[i] = a[i + 1]!; a[i + 1] = t; }
    let inv = 0;
    for (let i = 0; i < p.list.length; i++) for (let j = i + 1; j < p.list.length; j++) if (p.list[i]! > p.list[j]!) inv++;
    const k = Math.round(Math.log2(p.n));
    return [...a, inv, (p.n * (p.n - 1)) / 2, p.n * k - p.n + 1];
  },
  useIt: {
    say: ["Sort 1,000 song lengths both ways. Bubble sort makes 499,500 comparisons; merge sort about 8,700.",
      "Both counts go on the race card in the next lesson's project."],
    scene: { scene: "cs-stage", props: { mode: "sort", n: 1000 } },
  },
  deeper: [
    "Any comparison sort needs at least log₂(n!) ≈ n log₂ n − 1.44n comparisons (decision trees plus Stirling), so merge sort is optimal up to a small term.",
    "Quicksort's expected comparisons are 2n ln n with random pivots (`pr`). Counting sort and radix sort dodge the bound by not comparing.",
  ],
};
function countPassSwaps(xs: number[]) {
  const a = [...xs];
  let s = 0;
  for (let i = 0; i + 1 < a.length; i++) if (a[i]! > a[i + 1]!) { [a[i], a[i + 1]] = [a[i + 1]!, a[i]!]; s++; }
  return s;
}

/* ------------------------------------------------------------------ 08 ------------------------------------------------------------------ */

type F08 = "n" | "n²" | "n³" | "2ⁿ";
const CURVES = [
  { t: "n", r: 1, big: false }, { t: "1,000n", r: 1, big: true }, { t: "n log₂ n", r: 2, big: false }, { t: "100n log₂ n", r: 2, big: true },
  { t: "n²", r: 3, big: false }, { t: "1,000n²", r: 3, big: true }, { t: "n³", r: 4, big: false }, { t: "2ⁿ", r: 5, big: false }, { t: "n!", r: 6, big: false },
];
/** log₁₀ of each curve at a million items: an independent way to see which grows fastest */
const LOG_AT_MILLION: Record<string, number> = (() => {
  const n = 1e6, l = Math.log10(n), lf = (() => { let s = 0; for (let k = 2; k <= n; k++) s += Math.log10(k); return s; })();
  return { n: l, "1,000n": 3 + l, "n log₂ n": l + Math.log10(Math.log2(n)), "100n log₂ n": 2 + l + Math.log10(Math.log2(n)), "n²": 2 * l, "1,000n²": 3 + 2 * l, "n³": 3 * l, "2ⁿ": n * Math.log10(2), "n!": lf };
})();
const MILLIONS: Record<number, string> = { 100000: "100,000", 1000000: "a million", 10000000: "10 million" };

interface P08 { f: F08; n0: number; grow: number; t0: number; M: number; curves: string[] }
const factor08 = (p: P08) => (p.f === "2ⁿ" ? 2 ** p.grow : p.f === "n" ? 10 : p.f === "n²" ? 100 : 1000);
export const cs08: B2Lesson<P08> = {
  id: "b2-cs-08", track: "cs", unit: 2, title: "The growth race",
  youCan: "predict how an algorithm's running time grows when the input grows.",
  needs: ["b2-cs-07"],
  tools: ["cs-growth", "cs-stage", "calc"],
  play: { scene: "cs-growth", props: { mode: "race", n: 20 },
    say: "Curves n, n log₂ n, n², n³ and 2ⁿ race across the graph. Drag n and the \"time at a billion steps per second\" readouts update beside each. Toggle the log scale to see 2ⁿ leave every other curve behind." },
  guess: { scene: "cs-growth", props: { mode: "timeline", t0: 3, factor: 100, quiet: true }, kind: "slider", min: 0, max: Math.log10(3600), step: 0.01, start: 1, answer: Math.log10(300), near: 0.15,
    format: x => { const s = 10 ** x; return s < 60 ? `${Math.round(s)} s` : `${Math.round(s / 6) / 10} min`; },
    ask: "An n² algorithm takes 3 seconds on 1,000 items. How long on 10,000? Drag the marker on the timeline.",
    revealProps: { mode: "timeline", t0: 3, factor: 100 },
    reveal: "It lands on 300 seconds, 5 minutes: ten times the items, ten squared the steps, so 100 times longer." },
  nameIt: {
    say: [
      "What matters is how steps grow with n, written **O(f(n))**: the shape, ignoring constant factors. If the time is about c · f(n), growing n changes the time by f(new) / f(old).",
      "Polynomial growth is tame; exponential growth isn't: adding 10 items to a 2ⁿ algorithm multiplies its time by 1,024.",
    ],
    formula: ["new time = old time × f(n_new) / f(n_old)", "n ≪ n log₂ n ≪ n² ≪ n³ ≪ 2ⁿ for large n"],
  },
  workIt: {
    reference: { f: "n²", n0: 1000, grow: 10, t0: 3, M: 1000000, curves: ["1,000n", "2ⁿ", "n log₂ n", "n²"] },
    generate(rng, i) {
      const f = i < 3 ? rng.pick<F08>(["n", "n²", "n³"]) : rng.pick<F08>(["n²", "n³", "2ⁿ", "2ⁿ"]);
      const top = rng.pick(i < 3 ? [3, 4, 5] : [3, 4, 5, 6]);
      const ranks = rng.shuffle(Array.from({ length: top - 1 }, (_, k) => k + 1)).slice(0, 3);
      while (ranks.length < 3) ranks.push(ranks[0]!);
      const bigAt = rng.int(0, Math.min(2, ranks.length - 1));
      const picks = ranks.map((r, k) => CURVES.find(c => c.r === r && c.big === (k === bigAt && CURVES.some(x => x.r === r && x.big)))!.t);
      const curves = [...new Set([CURVES.find(c => c.r === top && !c.big)!.t, ...picks])].sort();
      return {
        f, n0: f === "2ⁿ" ? rng.int(30, 50) : rng.pick([100, 1000, 500, 2000]), grow: f === "2ⁿ" ? rng.pick([10, 20]) : 10,
        t0: rng.int(1, 9), M: i < 3 ? 1000000 : rng.pick([100000, 1000000, 10000000]), curves,
      };
    },
    show: p => (p.f === "2ⁿ"
      ? `A **2ⁿ** algorithm takes **${p.t0} s** on ${p.n0} items. Then **${p.grow} more** items.`
      : `An **${p.f}** algorithm takes **${p.t0} s** on ${g(p.n0)} items. Then the input grows to **${g(p.n0 * 10)}** items.`),
    steps(p) {
      const F = factor08(p), slipF = p.f === "2ⁿ" ? 2 : 10;
      const why = p.f === "n²" ? "Ten times the items, ten squared the steps: 100 times longer."
        : p.f === "n³" ? "Ten times the items, ten cubed the steps: 1,000 times longer."
        : `Each extra item doubles the time. ${WORD[p.grow] ? WORD[p.grow]![0]!.toUpperCase() + WORD[p.grow]!.slice(1) : p.grow} more items doubles it ${p.grow} times: 2${sup(p.grow)} = ${g(2 ** p.grow)}.`;
      const big = CURVES.filter(c => c.big && p.curves.includes(c.t)).map(c => c.t);
      const right = [...p.curves].sort((a, b) => CURVES.find(c => c.t === b)!.r - CURVES.find(c => c.t === a)!.r)[0]!;
      const Mtext = MILLIONS[p.M]!;
      return [
        wholeStep("factor", "Growth factor", F, {
          ask: p.f === "2ⁿ" ? `f(n + ${p.grow}) / f(n) for f = 2ⁿ.` : `f(10n) / f(n) for f = ${p.f}.`,
          hint: p.f === "2ⁿ" ? `Each extra item doubles 2ⁿ: 2${sup(p.grow)}.` : `Put 10n into ${p.f}: the 10 comes out ${p.f === "n" ? "once" : p.f === "n²" ? "squared" : "cubed"}.`,
          slips: [p.f !== "n" && slip("scaled like n", slipF, why), p.f === "2ⁿ" && slip("added", p.grow, why)],
        }),
        wholeStep("time", "New time", p.t0 * F, {
          unit: "s", ask: "The new running time, in seconds.",
          hint: `${p.t0} s × ${g(F)}.`,
          slips: [p.f !== "n" && slip("scaled like n", p.t0 * slipF, why)],
        }),
        wholeStep("million", `${Mtext[0]!.toUpperCase()}${Mtext.slice(1)} items`, (p.M * p.M) / 1e9, {
          unit: "s", ask: `At a billion steps per second, how many seconds does an n² algorithm take on ${Mtext} items?`,
          hint: `n² = ${g(p.M)}² steps, divided by 10⁹ steps per second.`,
          slips: [
            slip("steps", p.M * p.M, "That's the steps. At a billion steps a second, divide by 10⁹."),
            slip("n steps", p.M / 1e9, `That's n steps. An n² algorithm on ${Mtext} items takes n² steps.`),
          ],
        }),
        tapStep("fastest", "Fastest-growing", p.curves, p.curves.indexOf(right), {
          ask: "Which of these grows fastest once n is large?",
          hint: "Ignore the constants and compare the shapes: n ≪ n log₂ n ≪ n² ≪ n³ ≪ 2ⁿ ≪ n!.",
          slips: big.map(b => slip("big constant", p.curves.indexOf(b), `${b} only starts bigger. ${right} grows faster and passes it once n is large enough.`)),
        }),
      ];
    },
    scene: () => ({ scene: "cs-growth", props: { mode: "race", n: 20 } }),
  },
  oracle: p => {
    const F = p.f === "2ⁿ" ? 2 ** p.grow : p.f === "n" ? 10 : p.f === "n²" ? 100 : 1000;
    let best = 0;
    p.curves.forEach((c, i) => { if (LOG_AT_MILLION[c]! > LOG_AT_MILLION[p.curves[best]!]!) best = i; });
    return [F, p.t0 * F, p.M ** 2 / 1e9, best];
  },
  useIt: {
    say: ["**Project: Race card.** Pick three algorithms you've run and race them at n = 10, 1,000 and 1,000,000.",
      "The card shows each step count and its time at a billion steps per second. It's saved as `race_card`."],
    project: "cs-race",
  },
  deeper: [
    "Formal O, Ω and Θ come with constants c and n₀; limits of ratios compare growth.",
    "The time hierarchy theorem: with more time, strictly more problems become solvable, proved by diagonalization (the same trick as cs-14).",
  ],
};

/* ------------------------------------------------------------------ 09 ------------------------------------------------------------------ */

interface P09 { h: number; N: number; T: number }
export const cs09: B2Lesson<P09> = {
  id: "b2-cs-09", track: "cs", unit: 2, title: "Recursion: solve it by solving a smaller one",
  youCan: "turn a recursive recipe into a step count.",
  needs: ["b2-cs-03", "b2-cs-07"],
  tools: ["cs-hanoi", "cs-growth", "cs-stage"],
  play: { scene: "cs-hanoi", props: { n: 4 },
    say: "Move a tower of disks from one peg to another, never placing a big disk on a small one. Tap \"Solve\" and the recursive solution plays: move the top n − 1 out of the way, move the biggest, move the n − 1 back on top. The move counter runs." },
  guess: { scene: "cs-hanoi", props: { n: 10, quiet: true }, kind: "slider", min: 1, max: 2000, step: 1, start: 100, answer: 1023, near: 10, unit: "moves",
    format: x => group(Math.round(x)),
    ask: "3 disks take 7 moves. How many for 10?",
    revealProps: { n: 10, solve: true },
    reveal: "The solver plays at speed and the counter stops at 1,023: each disk added doubles the moves and adds one, so 2¹⁰ − 1." },
  nameIt: {
    say: [
      "A **recursive** algorithm solves a problem by calling itself on smaller copies. Its step count follows a **recurrence**.",
      "Hanoi doubles and adds 1, so it's exponential. Merge sort does two half-size problems plus n to merge, so it's n log₂ n.",
    ],
    formula: ["H(n) = 2H(n − 1) + 1 ⇒ H(n) = 2ⁿ − 1", "T(n) = 2T(n/2) + n, T(1) = 0 ⇒ T(n) = n log₂ n"],
  },
  workIt: {
    reference: { h: 4, N: 10, T: 8 },
    generate(rng, i) {
      if (i < 3) return { h: rng.int(2, 5), N: rng.int(2, 5), T: rng.pick([4, 8]) };
      return { h: rng.int(6, 20), N: rng.int(6, 20), T: 2 ** rng.int(1, 10) };
    },
    show: p => `Tower of Hanoi with **${p.h}** and then **${p.N}** disks. Then merge sort's recurrence at **n = ${g(p.T)}**.`,
    steps(p) {
      const prev = 2 ** (p.h - 1) - 1, k = Math.log2(p.T);
      return [
        wholeStep("up", "One step up", 2 * prev + 1, {
          ask: `H(${p.h - 1}) = ${g(prev)}. What's H(${p.h})?`,
          hint: `Move ${pl(p.h - 1, "disk")} aside, move the biggest, move ${p.h - 1} back: 2 × ${g(prev)} + 1.`,
          done: `H(${p.h}) = 2 × ${g(prev)} + 1 = ${g(2 * prev + 1)}`,
          slips: [slip("no plus one", 2 * prev, "Don't forget the one move of the biggest disk: add 1.")],
        }),
        wholeStep("closed", "Closed form", 2 ** p.N - 1, {
          ask: `H(${p.N}), from the closed form.`,
          hint: `2ⁿ − 1 with n = ${p.N}.`,
          done: `H(${p.N}) = 2${sup(p.N)} − 1 = ${g(2 ** p.N - 1)}`,
          slips: [slip("2 to the n", 2 ** p.N, "Check n = 1: one move, so it's 2ⁿ − 1.")],
        }),
        wholeStep("T", "Merge recurrence", p.T * k, {
          ask: `T(${g(p.T)}), where T charges n steps for each merge. (A merge of n items makes at most (n − 1) comparisons, so T slightly overcounts cs-07's.)`,
          hint: `log₂ ${g(p.T)} = ${k} levels, each doing ${g(p.T)} work in all.`,
          done: `T(${g(p.T)}) = ${g(p.T)} × ${k} = ${g(p.T * k)}`,
          slips: [
            slip("n squared over 2", (p.T * p.T) / 2, "Each of the log₂ n levels does n work in total: n log₂ n."),
            slip("cs-07 count", p.T * k - p.T + 1, `That's cs-07's worst-case comparison count. T charges a full n for each merge, so T(${g(p.T)}) = ${g(p.T)} × ${k} = ${g(p.T * k)}.`),
            slip("one level", p.T, `That's one level of merging. There are log₂ ${g(p.T)} = ${k} of them.`),
          ],
        }),
      ];
    },
    scene: p => ({ scene: "cs-hanoi", props: { n: Math.min(10, p.h), quiet: true } }),
  },
  oracle: p => {
    const H = (n: number): number => (n === 0 ? 0 : 2 * H(n - 1) + 1);
    const T = (n: number): number => (n === 1 ? 0 : 2 * T(n / 2) + n);
    return [H(p.h), H(p.N), T(p.T)];
  },
  useIt: {
    say: ["At one move per second, how long for 64 disks? (2⁶⁴ − 1) seconds: about 585 billion years.",
      "That's about 40 times the age of the universe, from a recipe four lines long."],
    scene: { scene: "cs-hanoi", props: { n: 6 } },
  },
  deeper: [
    "The master theorem for T(n) = aT(n/b) + f(n), comparing f(n) with n^(log_b a).",
    "Karatsuba's multiplication (3 half-size multiplies) gives n^(log₂ 3) ≈ n^1.585, and Strassen's matrix multiplication (7 half-size products) gives n^(log₂ 7) ≈ n^2.807 (b2-la-06).",
  ],
};

/* ------------------------------------------------------------------ 10 ------------------------------------------------------------------ */

/** where each place sits in the picture (A to G), so a graph can be drawn from its edge list alone */
export const GRAPH_POS: [number, number][] = [[36, 115], [140, 40], [140, 190], [324, 115], [240, 40], [240, 190], [190, 115]];
export const POS4: [number, number][] = [[36, 115], [180, 40], [180, 190], [324, 115]];
export const posOf = (n: number) => (n === 4 ? POS4 : GRAPH_POS);
export const graphText = (gr: Graph) => `${gr.names.length}|${gr.edges.map(([a, b, w]) => `${a}-${b}-${w}`).join(",")}`;
export function graphFrom(s: string): Graph {
  const [n, es] = s.split("|");
  return { names: [...LETTERS.slice(0, Number(n))], edges: (es ?? "").split(",").filter(Boolean).map(e => e.split("-").map(Number) as [number, number, number]) };
}
const cross = (p: [number, number], q: [number, number], r: [number, number], s: [number, number]) => {
  const d = (a: [number, number], b: [number, number], c: [number, number]) => (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]);
  return d(p, q, r) * d(p, q, s) < 0 && d(r, s, p) * d(r, s, q) < 0;
};
/** every route from 0 to t that visits no place twice */
export function simplePaths(gr: Graph, t: number): number[][] {
  const out: number[][] = [];
  const walk = (p: number[]) => {
    const u = p[p.length - 1]!;
    if (u === t) { out.push(p); return; }
    for (const [v] of neighbors(gr, u)) if (!p.includes(v)) walk([...p, v]);
  };
  walk([0]);
  return out;
}
export const routeText = (gr: Graph, p: number[]) => p.map(i => gr.names[i]).join("–");
function bfs(gr: Graph) {
  const d = gr.names.map(() => Infinity);
  d[0] = 0;
  const q = [0];
  while (q.length) { const u = q.shift()!; for (const [v] of neighbors(gr, u)) if (d[v] === Infinity) { d[v] = d[u]! + 1; q.push(v); } }
  return d;
}

function makeGraph(rng: Rng, n: number, weighted: boolean): { gr: Graph; t: number } {
  const P = GRAPH_POS;
  for (;;) {
    const pairs: [number, number][] = [];
    for (let a = 0; a < n; a++) for (let b = a + 1; b < n; b++) if (Math.hypot(P[a]![0] - P[b]![0], P[a]![1] - P[b]![1]) < 215) pairs.push([a, b]);
    const edges: [number, number, number][] = [];
    for (const [a, b] of rng.shuffle(pairs)) {
      if (rng.next() > 0.6) continue;
      if (edges.some(([c, d]) => c !== a && c !== b && d !== a && d !== b && cross(P[a]!, P[b]!, P[c]!, P[d]!))) continue;
      edges.push([a, b, weighted ? rng.int(1, 9) : 1]);
    }
    const gr: Graph = { names: [...LETTERS.slice(0, n)], edges };
    const d = bfs(gr);
    if (d.some(x => x === Infinity)) continue;
    if (weighted) {
      const dj = dijkstra(gr), rc = routeCounts(gr);
      if (dj.tie) continue;
      const ts = gr.names.map((_, i) => i).filter(i => i > 0 && rc[i] === 1 && d[i]! >= 2 && dj.prev[i] !== 0);
      if (!ts.length) continue;
      return { gr, t: rng.pick(ts) };
    }
    const ts = gr.names.map((_, i) => i).filter(i => i > 0 && d[i]! >= 2 && simplePaths(gr, i).filter(p => p.length - 1 === d[i]).length === 1);
    if (!ts.length) continue;
    return { gr, t: rng.pick(ts) };
  }
}
function routeOptions(gr: Graph, t: number, weighted: boolean) {
  const len = (p: number[]) => (weighted ? routeLength(gr, p) : p.length - 1);
  const all = simplePaths(gr, t).sort((a, b) => len(a) - len(b) || a.length - b.length);
  const right = routeText(gr, all[0]!);
  const greedy = weighted ? greedyWalk(gr, t) : null;
  const gText = greedy ? routeText(gr, greedy) : "";
  const others = all.slice(1).map(p => routeText(gr, p)).filter(x => x !== gText).slice(0, gText && gText !== right ? 2 : 3);
  const o = options(right, [...(gText && gText !== right ? [gText] : []), ...others]);
  return { ...o, greedy: gText && gText !== right ? o.all.indexOf(gText) : -1 };
}

interface P10 { g: string; t: number; weighted: boolean }
const roads = (gr: Graph, weighted: boolean) => [...gr.edges].sort((x, y) => x[0] - y[0] || x[1] - y[1]).map(([a, b, w]) => `${gr.names[a]}–${gr.names[b]}${weighted ? ` ${w}` : ""}`).join(", ");
export const cs10: B2Lesson<P10> = {
  id: "b2-cs-10", track: "cs", unit: 2, title: "Shortest paths",
  youCan: "find the shortest route through a network with Dijkstra's algorithm.",
  needs: ["b2-cs-06"],
  tools: ["cs-graph", "cs-stage"],
  play: { scene: "cs-graph", props: { mode: "path" },
    say: "A city map of dots and roads with travel times. Tap a road and drag its time up or down: the shortest path from A lights up and reroutes. Run Dijkstra and watch the settled places spread out from A like a ripple." },
  guess: { scene: "cs-graph", props: { mode: "path", g: "4|0-1-1,1-3-9,0-2-4,2-3-2", t: 3, quiet: true }, kind: "choice", options: ["A–B–D", "A–C–D"], answer: 1,
    ask: "Roads: A–B 1, B–D 9, A–C 4, C–D 2. Tap the shortest route from A to D.",
    revealProps: { mode: "path", g: "4|0-1-1,1-3-9,0-2-4,2-3-2", t: 3, greedy: true },
    reveal: "The explorer lights A–C–D, 6 in all. Grabbing the cheapest road first (A–B) costs 10, because B–D is 9." },
  nameIt: {
    say: [
      "**Dijkstra's algorithm** keeps a tentative distance for every place. Each round it settles the unsettled place with the smallest distance, then updates its neighbors: new distance = settled distance + road.",
      "Grabbing the nearest next road isn't enough; the total from the start is what counts. Unweighted maps use breadth-first search.",
    ],
    formula: ["d(v) ← min(d(v), d(u) + w(u, v))"],
  },
  workIt: {
    reference: { g: "5|0-1-1,1-3-9,0-2-4,2-3-2,1-4-4,4-3-5", t: 3, weighted: true },
    generate(rng, i) {
      const weighted = i >= 3, { gr, t } = makeGraph(rng, weighted ? rng.int(5, 7) : rng.int(5, 6), weighted);
      return { g: graphText(gr), t, weighted };
    },
    show: p => { const gr = graphFrom(p.g); return `Find the shortest route from **A** to **${gr.names[p.t]}**. Roads: ${roads(gr, p.weighted)}.${p.weighted ? "" : " Every road takes the same time."}`; },
    steps(p) {
      const gr = graphFrom(p.g), T = gr.names[p.t]!, ro = routeOptions(gr, p.t, p.weighted);
      const routeStep = tapStep("route", "Route", ro.all, ro.at, {
        ask: `Which route from A to ${T} is shortest?`,
        hint: p.weighted ? "Follow each place's previous stop back from the target." : "Spread out from A one road at a time; the first wave to reach the target marks the route.",
        slips: [ro.greedy >= 0 && slip("greedy", ro.greedy, "That's nearest-neighbor greed: always the cheapest next road. Compare total distances from A.")],
      });
      if (!p.weighted) {
        const d = bfs(gr)[p.t]!;
        return [
          wholeStep("roads", "Distance in roads", d, {
            ask: `What's the fewest roads from A to ${T}?`,
            hint: "Mark A's neighbors 1, their new neighbors 2, and so on.",
            slips: [slip("places", d + 1, `Count the roads, not the places: a route through ${d + 1} places uses ${d} roads.`)],
          }),
          routeStep,
        ];
      }
      const dj = dijkstra(gr), next = dj.order[1]!, others = gr.names.map((_, i) => i).filter(i => i > 0);
      const choices = others.map(i => gr.names[i]!), nbA = neighbors(gr, 0).map(([v]) => v);
      const greedy = greedyWalk(gr, p.t), path = (() => { const q = [p.t]; while (dj.prev[q[0]!]! >= 0) q.unshift(dj.prev[q[0]!]!); return q; })();
      return [
        tapStep("next", "Next settled", choices, others.indexOf(next), {
          ask: "A is settled first, at 0. Which place does Dijkstra settle next?",
          hint: "After A, only A's neighbors have a distance: settle the smallest.",
          slips: others.map((v, k) => !nbA.includes(v) && slip("not a neighbor", k, "Only A's neighbors have a distance yet. Settle the one with the smallest.")),
        }),
        wholeStep("dist", "Distance", dj.d[p.t]!, {
          ask: `The shortest distance from A to ${T}.`,
          hint: "Settle places in order of distance, updating each settled place's neighbors.",
          slips: [
            greedy && slip("greedy", routeLength(gr, greedy), `That's nearest-neighbor greed: ${routeText(gr, greedy)}. Compare total distances from A.`),
            slip("road twice", dj.d[p.t]! + routeLength(gr, path.slice(0, 2)), "Each road counts once in a route."),
          ],
        }),
        routeStep,
      ];
    },
    scene: p => ({ scene: "cs-graph", props: { mode: "path", g: p.g, t: p.t, quiet: true, plain: !p.weighted } }),
  },
  oracle: p => {
    const gr = graphFrom(p.g), all = simplePaths(gr, p.t);
    const len = (q: number[]) => q.slice(1).reduce((s, v, i) => s + (gr.edges.find(([a, b]) => (a === q[i] && b === v) || (b === q[i] && a === v))![2]), 0);
    const best = all.reduce((b, q) => ((p.weighted ? len(q) : q.length) < (p.weighted ? len(b) : b.length) ? q : b));
    const route = routeOptions(gr, p.t, p.weighted).all.indexOf(best.map(i => gr.names[i]).join("–"));
    if (!p.weighted) return [best.length - 1, route];
    const fromA = gr.edges.filter(([a, b]) => a === 0 || b === 0).sort((x, y) => x[2] - y[2])[0]!;
    const nextName = gr.names[fromA[0] === 0 ? fromA[1] : fromA[0]]!;
    return [gr.names.slice(1).indexOf(nextName), len(best), route];
  },
  useIt: {
    say: ["Find the fastest walk across a campus map: tap any path and change its time, and the route reroutes.",
      "Dijkstra settles each place once, so on this map it finishes in 7 rounds however you set the times."],
    scene: { scene: "cs-graph", props: { mode: "path", t: 3 } },
  },
  deeper: [
    "Dijkstra is correct because a settled distance can never improve when weights are nonnegative; with a heap it runs in O((V + E) log V).",
    "Bellman–Ford handles negative roads and detects negative loops; A* adds a distance guess to aim the search. Powers of the adjacency matrix count walks of each length (`la`).",
  ],
};

export const UNIT2 = [cs06, cs07, cs08, cs09, cs10];
