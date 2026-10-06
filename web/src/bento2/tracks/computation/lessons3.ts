// Computation, unit 3 (Hard and impossible): b2-cs-11 to b2-cs-15, built from curriculum/specs/bento2/computation.md
// block by block.
import type { B2Lesson } from "../../model";
import { multiStep, numStep, slip, tapStep, wholeStep } from "../../make";
import { group } from "../../steps";
import type { Rng } from "../../../curriculum/generators/rng";
import { ADD1, FLIP, UNARY, bin, nearestTour, ones, ruleText, runMachine, shiftAdd, subsetsHitting, tours4, type Machine } from "./maths";
import { LETTERS, bitsTyped, factorialOf, g, options, pl, sup } from "./common";

/* ------------------------------------------------------------------ 11 ------------------------------------------------------------------ */

const YEAR = 365 * 86400;
export const tourLen = (D: number[][], r: number[]) => r.reduce((s, c, i) => s + D[c]![r[(i + 1) % r.length]!]!, 0);
const tableText = (D: number[][]) => [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3]].map(([a, b]) => `${LETTERS[a!]}${LETTERS[b!]} ${D[a!]![b!]}`).join(", ");
const tourText = (r: number[]) => [...r, r[0]!].map(i => LETTERS[i]).join("–");
function makeTable(rng: Rng, greedyMisses: boolean): number[][] {
  for (;;) {
    const D = [0, 1, 2, 3].map(() => [0, 0, 0, 0]);
    for (let a = 0; a < 4; a++) for (let b = a + 1; b < 4; b++) D[a]![b] = D[b]![a] = rng.int(1, 12);
    const ls = tours4(D).map(t => t.len), min = Math.min(...ls);
    if (ls.filter(x => x === min).length !== 1) continue;
    const nn = nearestTour(D);
    if (!nn || (tourLen(D, nn) !== min) !== greedyMisses) continue;
    return D;
  }
}

interface P11 { n: number; D: number[][]; m: number }
export const cs11: B2Lesson<P11> = {
  id: "b2-cs-11", track: "cs", unit: 3, title: "The traveling salesperson",
  youCan: "count the possible tours and see why trying them all is hopeless.",
  needs: ["b2-cs-08", "g11-comb"],
  tools: ["cs-graph", "cs-growth", "cs-stage", "calc"],
  play: { scene: "cs-graph", props: { mode: "tour", n: 5 },
    say: "Cities on a map: tap a route that visits each once and returns home, and the tour length updates as you drag cities. Tap \"Try them all\" and the stage cycles through every tour; add a city and the counter jumps." },
  guess: { scene: "cs-graph", props: { mode: "tour", n: 10, quiet: true }, kind: "slider", min: 1, max: 7, step: 0.01, start: 3, answer: Math.log10(181440), near: 0.2,
    format: x => group(Math.round(10 ** x)),
    ask: "With 10 cities, how many different round trips are there? Drag the marker on the log scale.",
    revealProps: { mode: "tour", n: 10, count: true },
    reveal: "It lands at 181,440: fix the start, order the other 9 in 9! = 362,880 ways, and halve, since each loop can be driven either way." },
  nameIt: {
    say: [
      "A **tour** visits every city once and returns. Fix the start, order the other n − 1, and count each loop once in each direction: (n − 1)!/2 tours.",
      "That's even worse than 2ⁿ. No one knows a fast exact method, and finding one would settle P vs NP (cs-12).",
    ],
    formula: ["tours = (n − 1)!/2"],
  },
  workIt: {
    reference: { n: 10, D: [[0, 2, 9, 5], [2, 0, 6, 4], [9, 6, 0, 3], [5, 4, 3, 0]], m: 20 },
    generate(rng, i) {
      return { n: rng.pick(i < 3 ? [4, 5, 6] : [8, 10, 20]), D: makeTable(rng, rng.next() < 0.5), m: i < 3 ? 20 : rng.pick([20, 21, 22]) };
    },
    show: p => `**${p.n} cities**. Then a 4-city table: **${tableText(p.D)}**. Then brute force for **${p.m} cities**.`,
    steps(p) {
      const T = factorialOf(p.n - 1) / 2, ts = tours4(p.D), best = Math.min(...ts.map(t => t.len)), nn = nearestTour(p.D)!, nnL = tourLen(p.D, nn);
      const yrs = factorialOf(p.m - 1) / 2 / 1e9 / YEAR;
      const bestT = ts.find(t => t.len === best)!;
      return [
        wholeStep("tours", "Tours", T, {
          ask: `How many different round trips visit ${p.n} cities?`,
          hint: `Fix the start, order the other ${p.n - 1} in ${p.n - 1}! ways, and halve.`,
          done: `Tours: ${p.n - 1}!/2 = ${g(T)}`,
          slips: [
            slip("n factorial", factorialOf(p.n), "Fix the starting city and the rest can go in (n − 1)! orders."),
            slip("not halved", factorialOf(p.n - 1), "A–B–C–D–A and A–D–C–B–A are the same loop driven backward. Halve it."),
          ],
        }),
        wholeStep("best", "Shortest tour", best, {
          ask: "From A, there are 3 different round trips. Which is shortest? Type its length.",
          hint: "Add up A–B–C–D–A, A–B–D–C–A and A–C–B–D–A, and take the smallest.",
          done: `Shortest tour: ${tourText(bestT.r)} = ${best}`,
          slips: [nnL !== best && slip("greedy", nnL, `${tourText(nn)} is the nearest-neighbor tour. Greedy tours are good guesses, not guarantees. Compare all three.`)],
        }),
        numStep("years", `Brute force for ${p.m} cities`, yrs, 1, {
          unit: "years", ask: `At a billion tours per second, how many years to try every tour of ${p.m} cities? (1 year = 365 days.)`,
          hint: `${p.m - 1}!/2 ≈ ${(factorialOf(p.m - 1) / 2).toExponential(2).replace(/e\+(\d+)/, (_m, e: string) => ` × 10${sup(Number(e))}`)} tours; divide by 10⁹ for seconds, then by ${g(YEAR)}.`,
          slips: [
            slip("not halved", 2 * yrs, "Each loop is counted twice, once in each direction. Halve it."),
            slip("m factorial", factorialOf(p.m) / 2 / 1e9 / YEAR, `Fix the starting city: the other ${p.m - 1} go in ${p.m - 1}! orders, not ${p.m}!.`),
          ],
        }),
      ];
    },
    scene: p => ({ scene: "cs-graph", props: { mode: "tour", n: Math.min(p.n, 8), quiet: true } }),
  },
  oracle: p => {
    let f = 1;
    for (let k = 2; k < p.n; k++) f *= k;
    const perms = [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]];
    const best = Math.min(...perms.map(q => p.D[0]![q[0]!]! + p.D[q[0]!]![q[1]!]! + p.D[q[1]!]![q[2]!]! + p.D[q[2]!]![0]!));
    let f19 = 1;
    for (let k = 2; k < p.m; k++) f19 *= k;
    return [f / 2, best, f19 / 2 / 1e9 / (365 * 86400)];
  },
  useIt: {
    say: ["Plan a delivery loop for 6 stops: 5!/2 = 60 tours, and brute force is instant.",
      "At 20 stops it's 6 × 10¹⁶ tours: almost two years at a billion a second."],
    scene: { scene: "cs-graph", props: { mode: "tour", n: 6 } },
  },
  deeper: [
    "Held–Karp dynamic programming solves it in O(n² 2ⁿ), far better than (n − 1)! but still exponential.",
    "Christofides' algorithm guarantees a tour at most 1.5 times the best on maps obeying the triangle inequality. Stirling's formula n! ≈ √(2πn)(n/e)ⁿ shows how fast the count grows.",
  ],
};

/* ------------------------------------------------------------------ 12 ------------------------------------------------------------------ */

const KINDS = ["In P", "In NP, no fast method known", "Not known to be in NP"];
export const PROBLEMS: [string, number][] = [
  ["Sort a list of names", 0], ["Find the shortest route between two places on a map", 0], ["Multiply two whole numbers", 0], ["Check whether a number is prime", 0],
  ["Pick weights that hit a target exactly", 1], ["Is there a salesperson's tour under 100 miles?", 1], ["Fill in a giant sudoku", 1], ["Color a map with 3 colors so neighbors differ", 1],
  ["Will this program ever stop?", 2], ["Find the best first move in chess on an n × n board", 2],
];
const sumText = (xs: number[]) => xs.join(" + ");
/** a list of weights is a fair answer when it hits the target and uses each weight at most as often as the pile has it */
export const fair = (ws: number[], target: number, xs: number[]) => xs.reduce((s, x) => s + x, 0) === target && xs.every(x => xs.filter(y => y === x).length <= ws.filter(y => y === x).length);
const subsetOf = (ws: number[], m: number) => ws.filter((_, i) => (m >> i) & 1);

function twiceList(ws: number[], target: number): number[] | null {
  for (const w of ws) {
    const rest = ws.filter(x => x !== w);
    for (let m = 0; m < 1 << rest.length; m++) { const r = subsetOf(rest, m); if (2 * w + r.reduce((s, x) => s + x, 0) === target && r.length <= 2) return [w, w, ...r]; }
  }
  return null;
}
function nearMiss(rng: Rng, ws: number[], target: number, avoid: string[]): number[] {
  for (let tries = 0; ; tries++) {
    const m = rng.int(1, (1 << ws.length) - 1), xs = subsetOf(ws, m), s = xs.reduce((a, x) => a + x, 0);
    if (s !== target && (tries > 200 || Math.abs(s - target) <= 4) && xs.length >= 2 && xs.length <= 4 && !avoid.includes(sumText(xs))) return xs;
  }
}

interface P12 { ws: number[]; target: number; check: number[]; find: string[]; which: number }
export const cs12: B2Lesson<P12> = {
  id: "b2-cs-12", track: "cs", unit: 3, title: "P vs NP: easy to check, hard to find",
  youCan: "tell finding a solution from checking one, and say what P vs NP asks.",
  needs: ["b2-cs-11"],
  tools: ["cs-stage", "cs-graph"],
  play: { scene: "cs-stage", props: { mode: "subset", ws: "3,7,12,5,9", target: 21 },
    say: "A pile of numbered weights and a target. Tap weights to try to hit the target exactly; any answer is checked instantly. Then tap \"Search all\" and the stage tries every subset with a counter. Add one weight and the search doubles." },
  guess: { scene: "cs-stage", props: { mode: "subset", ws: "3,7,12,5,9", target: 21, quiet: true }, kind: "slider", min: 1, max: 100, step: 1, start: 50, answer: 32, near: 0.5, unit: "subsets",
    format: x => String(Math.round(x)),
    ask: "Weights 3, 7, 12, 5 and 9, and target 21. How many subsets might a blind search try?",
    revealProps: { mode: "subset", ws: "3,7,12,5,9", target: 21, search: true },
    reveal: "The counter runs to 32: each weight is in or out, 2 × 2 × 2 × 2 × 2. Then it lights one that works, 12 + 9." },
  nameIt: {
    say: [
      "**P** is the problems a computer can solve in polynomial time (like n², n³). **NP** is the problems where a proposed answer can be checked in polynomial time, like subset sum, sudoku and the salesperson's \"is there a tour under 100?\".",
      "**NP-complete** problems are the hardest in NP: a fast method for any one would give a fast method for all.",
      "Whether P = NP is open, with a million-dollar prize.",
    ],
    formula: ["subsets of n items = 2ⁿ", "P ⊆ NP", "P = NP? (open)"],
  },
  workIt: {
    reference: { ws: [3, 7, 12, 5, 9], target: 21, check: [7, 5, 9], find: ["12 + 9", "3 + 5 + 9", "3 + 7 + 12", "7 + 9"], which: 0 },
    generate(rng, i) {
      const n = i < 3 ? rng.int(4, 5) : rng.int(6, 8), max = i < 3 ? 15 : 30;
      const ws = rng.shuffle(Array.from({ length: max }, (_, k) => k + 1)).slice(0, n);
      const size = rng.int(2, Math.min(4, n - 1));
      const target = rng.shuffle(ws).slice(0, size).reduce((s, x) => s + x, 0);
      const hits = subsetsHitting(ws, target).map(idx => idx.map(k => ws[k]!));
      const kind = rng.pick(["valid", "miss", "twice"]);
      const twice = kind === "twice" ? twiceList(ws, target) : null;
      const check = kind === "valid" ? rng.pick(hits) : twice ?? nearMiss(rng, ws, target, []);
      const right = sumText(rng.pick(hits));
      const others: string[] = [];
      const tw = twiceList(ws, target);
      if (tw && rng.next() < 0.5) others.push(sumText(tw));
      while (others.length < 3) others.push(sumText(nearMiss(rng, ws, target, [right, ...others])));
      return { ws, target, check, find: options(right, others).all, which: rng.int(0, PROBLEMS.length - 1) };
    },
    show: p => `Weights **${p.ws.join(", ")}**, each usable once, and target **${p.target}**.`,
    steps(p) {
      const n = p.ws.length, ok = fair(p.ws, p.target, p.check), s = p.check.reduce((a, x) => a + x, 0);
      const twice = s === p.target && !ok;
      const CHECK = ["Not valid", "Valid"], right = p.find.findIndex(t => fair(p.ws, p.target, t.split(" + ").map(Number)));
      const [desc, cls] = PROBLEMS[p.which]!;
      const kindMsg = (pick: number) => cls === 0
        ? pick === 1 ? "There's a fast method for this, so it's in P. (Every problem in P is in NP too.)" : "NP is \"checkable in polynomial time\". Every problem in P is in NP too."
        : cls === 1 ? pick === 0 ? "No one knows a polynomial-time method for this. But a proposed answer is quick to check, so it's in NP." : "A proposed answer is quick to check here, so it's in NP."
        : "Even a proposed answer can't be checked quickly here, so it isn't known to be in NP.";
      return [
        wholeStep("subsets", "Subsets", 2 ** n, {
          ask: `How many subsets of the ${n} weights could a blind search try?`,
          hint: `Each weight is in or out: 2 choices, ${n} times.`,
          done: `Subsets: 2${sup(n)} = ${g(2 ** n)}`,
          slips: [slip("n factorial", factorialOf(n), "Each weight is in or out: 2 choices, n times. 2ⁿ, not n!."), slip("2n", 2 * n, `Each weight doubles the count: 2${sup(n)}, not 2 × ${n}.`)],
        }),
        tapStep("check", "Check this answer", CHECK, ok ? 1 : 0, {
          ask: `Someone proposes ${sumText(p.check)}. Valid?`,
          hint: "Add it up, and check each weight is in the pile and used once.",
          done: `${sumText(p.check)} = ${s}: ${ok ? "valid" : "not valid"}`,
          slips: [slip(twice ? "used twice" : ok ? "rejected" : "accepted", ok ? 0 : 1, twice ? "Each weight can be used once." : ok ? `It adds up: ${s} = ${p.target}, and no weight is used twice.` : `Add them up: ${s}, not ${p.target}.`)],
        }),
        tapStep("find", "Find one", p.find, right, {
          ask: `Which of these hits ${p.target} exactly?`,
          hint: "Checking is quick: add each one up.",
          slips: p.find.map((t, k) => { const xs = t.split(" + ").map(Number); return k !== right && xs.reduce((a, x) => a + x, 0) === p.target && slip("used twice", k, "Each weight can be used once."); }),
        }),
        tapStep("which", "Which is which", KINDS, cls, {
          ask: `"${desc}." Where does it sit?`,
          hint: "In P: a fast method is known. In NP: a proposed answer is quick to check.",
          done: `${desc}: ${KINDS[cls]!.toLowerCase()}`,
          slips: [0, 1, 2].map(k => k !== cls && slip(cls === 0 && k === 2 ? "np as not polynomial" : "class", k, kindMsg(k))),
        }),
      ];
    },
    scene: p => ({ scene: "cs-stage", props: { mode: "subset", ws: p.ws.join(","), target: p.target, quiet: true } }),
  },
  oracle: p => {
    const fairList = (xs: number[]) => {
      if (xs.reduce((a, x) => a + x, 0) !== p.target) return false;
      const left = [...p.ws];
      for (const x of xs) { const k = left.indexOf(x); if (k < 0) return false; left.splice(k, 1); }
      return true;
    };
    return [2 ** p.ws.length, fairList(p.check) ? 1 : 0, p.find.findIndex(t => fairList(t.split(" + ").map(Number))), PROBLEMS[p.which]![1]];
  },
  useIt: {
    say: ["**Project: A puzzle that's easy to check.** Make a subset-sum puzzle with a hidden answer for someone else.",
      "Anyone can check a solution in seconds, but a blind search tries up to 2ⁿ subsets. It's saved to the Notebook as `puzzle`."],
    project: "cs-puzzle",
  },
  deeper: [
    "With small whole-number weights, dynamic programming finds a subset in about n × target steps (pseudo-polynomial time), so hard puzzles need huge numbers.",
    "The Cook–Levin theorem (SAT is NP-complete) and reductions, like 3-SAT to clique: Karp's 21 problems. Most modern cryptography bets that some problems in NP are hard on average.",
    "Why it's hard to prove: the relativization (Baker–Gill–Solovay) and natural proofs barriers. Beyond NP: PSPACE, and BQP for quantum computers (`qu`).",
  ],
};

/* ------------------------------------------------------------------ 13 ------------------------------------------------------------------ */

export const MACHINES: Record<string, Machine> = { add1: ADD1, flip: FLIP, unary: UNARY };
const rev = (s: string) => [...s].reverse().join("");
interface P13 { m: "add1" | "flip" | "unary"; input: string }
const machineShow = (p: P13) => p.m === "unary"
  ? `The **unary adder** on **${p.input}**: ${p.input.indexOf("0")} + ${p.input.length - p.input.indexOf("0") - 1} in tally marks, with a 0 between, head on the left.`
  : p.m === "add1" ? `The **add 1** machine, head on the right end of **${p.input}**.` : `The **flip every bit** machine, head on the left end of **${p.input}**.`;

export const cs13: B2Lesson<P13> = {
  id: "b2-cs-13", track: "cs", unit: 3, title: "Turing machines",
  youCan: "run a Turing machine by hand and read its answer off the tape.",
  needs: ["b2-cs-05"],
  tools: ["cs-machine"],
  play: { scene: "cs-machine", props: { m: "add1", input: "1011" },
    say: "A tape of 0s and 1s, a head, and a three-rule table. Tap a cell to change it, then step the machine: it reads, writes, moves and changes state. The \"add 1\" machine walks left turning 1s into 0s until a 0 or a blank takes the 1, and halts." },
  guess: { scene: "cs-machine", props: { m: "add1", input: "1011", quiet: true }, kind: "slider", min: 1, max: 8, step: 1, start: 4, answer: 3, near: 0.5, unit: "steps",
    format: x => String(Math.round(x)),
    ask: "The add-1 machine starts on the right end of 1011. How many steps until it halts?",
    revealProps: { m: "add1", input: "1011", run: true },
    reveal: "It runs and halts on 1100 after 3 steps: two 1s turn to 0s, then the 0 takes the 1." },
  nameIt: {
    say: [
      "A **Turing machine** is a tape, a head and a finite table of rules: (state, symbol read) → (symbol to write, move left or right, next state).",
      "Despite being this small, it can compute anything any computer can; that claim is the **Church–Turing thesis**.",
      "A **universal** machine reads another machine's rules from its tape and runs them, which is what a stored-program computer is.",
    ],
    formula: ["rule: (q, s) → (s′, L or R, q′)"],
  },
  workIt: {
    reference: { m: "add1", input: "1011" },
    generate(rng, i) {
      const bits = (n: number) => `1${Array.from({ length: n - 1 }, () => (rng.next() < 0.6 ? "1" : "0")).join("")}`;
      if (i < 3) return { m: "add1", input: bits(rng.int(3, 4)) };
      const m = rng.pick<P13["m"]>(["add1", "add1", "flip", "unary"]);
      if (m === "unary") return { m, input: `${"1".repeat(rng.int(1, 5))}0${"1".repeat(rng.int(1, 4))}` };
      return { m, input: bits(m === "add1" ? rng.int(5, 8) : rng.int(4, 7)) };
    },
    show: machineShow,
    steps(p) {
      const M = MACHINES[p.m]!, run = runMachine(M, p.input), first = run.trace[1]!.rule, out = run.out;
      const head = p.input[M.at === "right" ? p.input.length - 1 : 0]!;
      const unary = p.m === "unary", value = unary ? out.length : parseInt(out, 2);
      const tapeSlips = p.m === "add1" ? [
        slip("left end", bitsTyped(rev(runMachine(ADD1, rev(p.input)).out)), "The head starts at the right end, the ones place."),
        p.input.endsWith("1") && slip("one flip", bitsTyped(`${p.input.slice(0, -1)}0`), "A 1 becomes 0 and the carry moves left. Keep going until a 0 or a blank takes the 1."),
        !p.input.includes("0") && slip("no new 1", 0, `The blank to the left becomes 1: ${p.input} + 1 = ${out}.`),
      ] : p.m === "flip" ? [slip("unchanged", bitsTyped(p.input), "That's the input. The machine flips every bit: 0 becomes 1 and 1 becomes 0.")]
        : [slip("no trim", bitsTyped(`${out}1`), "The last rule erases one 1: turning the 0 into a 1 made one too many.")];
      return [
        tapStep("rule", "First rule used", M.rules.map(ruleText), first, {
          ask: `The machine starts in state "${M.start}" with the head on a ${head}. Which rule fires first?`,
          hint: "Find the row whose state and symbol match the start.",
          slips: M.rules.map((r, k) => k !== first && r.read !== head && slip("wrong symbol", k, `The head starts on a ${head}, so only a rule that reads ${head} applies.`)),
        }),
        wholeStep("tape", "Tape at halt", bitsTyped(out), {
          ask: "Run it to the halt. Type what's on the tape.",
          hint: "Follow the rules one step at a time until the state is halt.",
          done: `Tape at halt: ${out}`,
          slips: tapeSlips,
        }),
        wholeStep("steps", "Steps", run.steps, {
          ask: "How many steps did it take?",
          hint: "Count each rule fired, including the one that moves into halt.",
          slips: p.m === "add1" ? [
            slip("forgot last", run.steps - 1, "The step that writes the final 1 counts too."),
            slip("whole tape", p.input.length, "It stops as soon as a 0 or a blank takes the 1; it doesn't walk the whole tape."),
          ] : [slip("forgot last", run.steps - 1, p.m === "flip" ? "The last step reads the blank past the end and halts: one more." : "The last rule, which erases a 1, is a step too.")],
        }),
        wholeStep("num", "As a number", value, {
          ask: unary ? "Count the 1s: what number is on the tape?" : "Read the tape as a binary number.",
          hint: unary ? "In tally marks, each 1 is one." : `Place values from the right: 1, 2, 4, 8, …`,
          slips: unary ? [] : [slip("base ten", Number(out), `That's the tape read in base ten. Read it in binary: ${out} = ${value}.`)],
        }),
      ];
    },
    scene: p => ({ scene: "cs-machine", props: { m: p.m, input: p.input, quiet: true } }),
  },
  oracle: p => {
    const M = MACHINES[p.m]!;
    let tape = [...p.input], h = M.at === "right" ? tape.length - 1 : 0, q = M.start, steps = 0, first = -1;
    while (q !== "halt") {
      if (h < 0) { tape.unshift("_"); h = 0; }
      if (h >= tape.length) tape.push("_");
      const k = M.rules.findIndex(r => r.q === q && r.read === tape[h]);
      if (first < 0) first = k;
      const r = M.rules[k]!;
      tape[h] = r.write; h += r.move === "L" ? -1 : 1; q = r.next; steps++;
    }
    const out = tape.join("").replace(/_/g, "");
    return [first, Number(out), steps, p.m === "unary" ? out.length : parseInt(out, 2)];
  },
  useIt: {
    say: ["Give the machine `adder4`'s job: adding two numbers on its tape. The unary adder does it in tally marks: 111 0 11 becomes 11111.",
      "The gate board and the tape compute the same thing, one with wires and one with rules."],
    scene: { scene: "cs-machine", props: { m: "unary", input: "111011" } },
  },
  deeper: [
    "The universal Turing machine, and why it implies software. Equivalence with lambda calculus and with register machines.",
    "The Busy Beaver function BB(n) is the most steps an n-state halting machine can take: BB(5) = 47,176,870, proved in 2024 with a machine-checked proof. BB grows faster than any computable function (cs-14).",
  ],
};

/* ------------------------------------------------------------------ 14 ------------------------------------------------------------------ */

export const STATEMENTS: [string, number, string][] = [
  ["Does this program halt within 1,000 steps?", 1, "With a step limit you can just run it and watch. The trouble is \"ever\"."],
  ["Does this program ever print 7?", 0, "This isn't about speed. The contradiction holds for any machine."],
  ["Does this program halt on every input?", 0, "This isn't about speed. The contradiction holds for any machine."],
  ["Does this program have more than 100 lines?", 1, "That's about the code itself, not what it does when run: just count the lines."],
  ["Does this program halt within a day on this laptop?", 1, "With a time limit you can just run it and watch. The trouble is \"ever\"."],
  ["Does this program ever reach line 10?", 0, "This isn't about speed. The contradiction holds for any machine."],
];
const flipHL = (c: string) => (c === "H" ? "L" : "H");
const letters = (s: string) => [...s].join(", ");
export const diagonalOf = (T: string[]) => T.map((r, i) => r[i]!).join("");
function troubleOptions(T: string[]) {
  const diag = diagonalOf(T), right = [...diag].map(flipHL).join("");
  const anti = T.map((r, i) => flipHL(r[T.length - 1 - i]!)).join(""), row1 = [...T[0]!].map(flipHL).join("");
  const o = options(letters(right), [letters(diag), letters(anti), letters(row1)].filter(x => x !== letters(right)));
  return { ...o, diag: o.all.indexOf(letters(diag)) };
}

interface P14 { T: string[]; k: number; s: number }
export const cs14: B2Lesson<P14> = {
  id: "b2-cs-14", track: "cs", unit: 3, title: "The halting problem",
  youCan: "explain why no program can decide whether every program halts.",
  needs: ["b2-cs-13", "b2-cs-02"],
  tools: ["cs-diagonal", "cs-proof"],
  play: { scene: "cs-diagonal", props: { T: "HLLH,HLHL,LLHH,HHLH" },
    say: "Programs down the side, inputs across, each cell H (halts) or L (loops). The diagonal lights, and the trouble program's row below flips every diagonal cell. Tap any cell to flip it: try to make the trouble row match some program. Each row still disagrees with it somewhere on the diagonal." },
  guess: { scene: "cs-diagonal", props: { T: "HLLH,HLHL,LLHH,HHLH", quiet: true }, kind: "choice", options: ["Yes", "No"], answer: 1,
    ask: "The trouble program does the opposite of program 3 on input 3. Can it be program 3?",
    revealProps: { T: "HLLH,HLHL,LLHH,HHLH", k: 3 },
    reveal: "The table puts them side by side and the third cell clashes: program 3 halts on input 3, trouble loops. The same clash happens for every row." },
  nameIt: {
    say: [
      "Suppose some program halts(P, x) always answered correctly. Build trouble(P): if halts(P, P) says yes, loop forever; otherwise stop.",
      "Run trouble on itself and either answer is wrong. So no such program exists: the **halting problem** is **undecidable**.",
      "Some questions about programs have no algorithm at all, no matter how fast the computer.",
    ],
    formula: ["trouble(P) halts ⇔ P(P) loops", "trouble(trouble) halts ⇔ trouble(trouble) loops (contradiction)"],
  },
  workIt: {
    reference: { T: ["HLLH", "HLHL", "LLHH", "HHLH"], k: 3, s: 0 },
    generate(rng, i) {
      const n = i < 3 ? 3 : rng.int(4, 5);
      return { T: Array.from({ length: n }, () => Array.from({ length: n }, () => (rng.next() < 0.5 ? "H" : "L")).join("")), k: rng.int(1, n), s: rng.int(0, STATEMENTS.length - 1) };
    },
    show: p => `Programs 1 to ${p.T.length} (rows) on inputs 1 to ${p.T.length} (columns): ${p.T.map((r, i) => `program ${i + 1}: ${letters(r)}`).join("; ")}.`,
    steps(p) {
      const o = troubleOptions(p.T), trouble = [...diagonalOf(p.T)].map(flipHL).join("");
      const row = p.T[p.k - 1]!, firstClash = [...row].findIndex((c, j) => c !== trouble[j]) + 1;
      const [q, yes, why] = STATEMENTS[p.s]!;
      return [
        tapStep("row", "The trouble row", o.all, o.at, {
          ask: "Trouble does the opposite of program i on input i. What's its row?",
          hint: "Read the diagonal, cell (1, 1), (2, 2), …, and flip every letter.",
          slips: [slip("copied diagonal", o.diag, "Trouble does the opposite on each diagonal cell: flip every letter.")],
        }),
        wholeStep("col", `Where it differs from program ${p.k}`, p.k, {
          ask: `Which column is sure to clash between trouble and program ${p.k}, whatever the table says?`,
          hint: "Trouble was built from the diagonal.",
          slips: [firstClash !== p.k && slip("lucky clash", firstClash, `They differ there too, but by luck. The column built to clash in every table is column ${p.k}, on the diagonal.`)],
        }),
        tapStep("dec", "Decidable?", ["No", "Yes"], yes, {
          ask: `"${q}" Can a program always answer this?`,
          hint: "A limit you can wait out is decidable. \"Ever\" about what a program does is not.",
          done: `${q} ${yes ? "Decidable" : "Undecidable"}`,
          slips: [slip(yes ? "limit" : "speed", 1 - yes, why)],
        }),
      ];
    },
    scene: p => ({ scene: "cs-diagonal", props: { T: p.T.join(","), quiet: true } }),
  },
  oracle: p => {
    const trouble = p.T.map((r, i) => (r[i] === "H" ? "L" : "H")).join(", ");
    return [troubleOptions(p.T).all.indexOf(trouble), p.k, STATEMENTS[p.s]![1]];
  },
  useIt: {
    say: ["Why can't an app store's checker guarantee an app will never freeze? Because \"will it ever stop responding\" is a halting question: no checker can answer it for every app.",
      "Checkers can still test for a minute, or look for known bad patterns. Write your one-line reason in the Notebook."],
    scene: { scene: "cs-diagonal", props: { T: "HLH,LLH,HHL" } },
  },
  deeper: [
    "Rice's theorem: every nontrivial question about what a program computes is undecidable.",
    "Gödel's incompleteness theorems: any consistent proof system that does arithmetic has true statements it can't prove, by the same diagonal trick (cs-03).",
    "Kolmogorov complexity is uncomputable (b2-in-07, b2-in-12), and BB(n) outgrows every computable function.",
  ],
};

/* ------------------------------------------------------------------ 15 ------------------------------------------------------------------ */

interface P15 { a: number; b: number; n: number }
export const cs15: B2Lesson<P15> = {
  id: "b2-cs-15", track: "cs", unit: 3, title: "The chip runs a program",
  youCan: "multiply with nothing but an adder and a recipe, and count what it costs.",
  needs: ["b2-cs-05", "b2-cs-09"],
  tools: ["cs-mult", "cs-gates", "cs-stage"],
  play: { scene: "cs-mult", props: { a: 13, b: 6 },
    say: "adder4 sits next to an 8-bit register [A | Q]: A starts at 0, Q holds the multiplier and M the multiplicand. Each of four rounds, if the last bit of Q is 1, adder4 adds M into A (keeping its carry), then the carry, A and Q all shift right. Step through 13 × 6 and watch the answer's bits slide into Q." },
  guess: { scene: "cs-mult", props: { a: 11, b: 5, quiet: true }, kind: "slider", min: 0, max: 8, step: 1, start: 4, answer: 2, near: 0.5, unit: "adds",
    format: x => String(Math.round(x)),
    ask: "To multiply 11 × 5 (5 is 101 in binary), how many times does the adder run?",
    revealProps: { a: 11, b: 5, run: true },
    reveal: "It runs twice: once for each 1 in 101. The rounds with a 0 bit just shift." },
  nameIt: {
    say: [
      "Hardware only adds and shifts; everything else is an **algorithm** on top. Binary long multiplication is **shift-and-add**: each 1 bit of the multiplier adds one shifted copy.",
      "A 4-bit adder can't hold shifted copies as big as 52, so the chip shifts the running total right instead: each round it adds M into the top half A, then slides [carry | A | Q] right. After 4 rounds [A | Q] holds the 8-bit product.",
      "Schoolbook multiplication of two n-digit numbers takes n² digit products; cleverer recursion takes fewer.",
    ],
    formula: ["a × b = Σ (a shifted left by i) over each bit i of b that is 1", "adds = number of 1s in b", "each round: if Q₀ = 1, A ← A + M; then shift [C | A | Q] right", "schoolbook = n² · Karatsuba (n = 2ᵏ) = 3ᵏ"],
  },
  workIt: {
    reference: { a: 13, b: 6, n: 1024 },
    generate(rng, i) {
      return i < 3 ? { a: rng.int(2, 7), b: rng.int(2, 7), n: rng.pick([4, 16]) } : { a: rng.int(2, 15), b: rng.int(2, 15), n: rng.pick([4, 16, 1024]) };
    },
    show: p => `**${p.a} × ${p.b}** on the chip: M = ${p.a} (${bin(p.a, 4)}), Q = ${p.b}. Then digit products for two **${g(p.n)}-digit** numbers.`,
    steps(p) {
      const run = shiftAdd(p.a, p.b), lost = shiftAdd(p.a, p.b, false), k = Math.log2(p.n);
      const addRounds = run.rounds.map((r, i) => ({ ...r, i: i + 1 })).filter(r => r.sum != null);
      const carryRound = addRounds.find(r => r.sum! >= 16);
      const nAdds = ones(p.b);
      return [
        wholeStep("bin", "Multiplier in binary", bitsTyped(p.b.toString(2)), {
          ask: `Write ${p.b} in binary.`,
          hint: "Place values 8, 4, 2, 1: take the biggest that fits, and repeat.",
          done: `Multiplier in binary: ${p.b.toString(2)}, so Q = ${bin(p.b, 4)}`,
          slips: [slip("reversed", bitsTyped(rev(p.b.toString(2))), "That's backward: the ones place goes last, on the right.")],
        }),
        wholeStep("adds", "Adds", nAdds, {
          ask: "How many rounds run the adder?",
          hint: `One add for each 1 in ${p.b.toString(2)}.`,
          done: `Adds: ${pl(nAdds, "add")}, one per 1 in ${p.b.toString(2)}`,
          slips: [slip("every bit", p.b.toString(2).length, "A 0 bit adds nothing, so skip it."), slip("every round", 4, "A 0 bit adds nothing, so skip it.")],
        }),
        multiStep("each", "Each add", addRounds.map(r => r.sum!), "whole", {
          boxes: addRounds.map(r => `round ${r.i}`),
          ask: `For each round that adds, A + M in decimal, with A read off the register after the last shift.`,
          hint: addRounds.map(r => `round ${r.i}: ${r.before} + ${p.a}`).join("; "),
          done: `Each add: ${addRounds.map(r => `round ${r.i}: ${r.before} + ${p.a} = ${r.sum}`).join("; ")}`,
          slips: [
            slip("just M", addRounds.map(() => p.a), "Add M to what's already in A: read A off the register after the last shift."),
            slip("dropped carry", lost.adds, "Keep the carry out: it shifts into the top of A, so the next add starts from there."),
          ],
        }),
        wholeStep("product", "Product", p.a * p.b, {
          ask: "After round 4, read [A | Q] as one 8-bit number, in decimal.",
          hint: `${p.a} × ${p.b}.`,
          done: `Product: ${bin(run.product >> 4, 4)} ${bin(run.product & 15, 4)} = ${run.product}`,
          slips: [!!carryRound && slip("dropped carry", lost.product, `${carryRound.before} + ${p.a} = ${carryRound.sum} needs 5 bits: 1 ${bin(carryRound.sum! & 15, 4)}. The carry out shifts into the top of A on the next shift, so keep it.`)],
        }),
        multiStep("race", "Digit products", [p.n * p.n, 3 ** k], "whole", {
          boxes: ["schoolbook", "Karatsuba"], ask: `Multiplying two ${g(p.n)}-digit numbers: schoolbook n², and Karatsuba 3ᵏ with n = 2ᵏ.`,
          hint: `${g(p.n)} = 2${sup(k)}, so k = ${k}.`,
          slips: [slip("k as n", [p.n * p.n, 3 ** p.n], `k is the number of halvings: ${g(p.n)} digits is k = ${k}, so 3${sup(k)} = ${g(3 ** k)}.`)],
        }),
      ];
    },
    scene: p => ({ scene: "cs-mult", props: { a: p.a, b: p.b, quiet: true } }),
  },
  oracle: p => {
    let R = p.b;
    const sums: number[] = [];
    for (let r = 0; r < 4; r++) { if (R & 1) { R += p.a << 4; sums.push(R >> 4); } R >>= 1; }
    let c = 0;
    for (let x = p.b; x; x >>= 1) c += x & 1;
    return [Number(p.b.toString(2)), c, ...sums, R & 255, p.n ** 2, 3 ** Math.round(Math.log2(p.n))];
  },
  useIt: {
    say: ["**Project: The machine room.** Wire `adder4` to the shift-and-add program with the 8-bit register [A | Q] and multiply any two numbers from 0 to 15.",
      "adder4 runs at most 4 times, once per 1 in the multiplier. The Notebook saves the gate count, the step count and the answer as `mult4`. Build complete."],
    project: "cs-room",
  },
  deeper: [
    "Karatsuba's trick (three multiplies instead of four) gives n^(log₂ 3) ≈ n^1.585; Toom–Cook and FFT methods do better, and Harvey and van der Hoeven's 2019 algorithm runs in O(n log n).",
    "Multiplying is easy, but undoing it (factoring) isn't known to be: the best known classical methods are super-polynomial, while Shor's quantum algorithm factors in polynomial time (`qu`).",
  ],
};

export const UNIT3 = [cs11, cs12, cs13, cs14, cs15];
