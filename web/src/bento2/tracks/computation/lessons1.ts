// Computation, unit 1 (Logic and circuits): b2-cs-01 to b2-cs-05, built from curriculum/specs/bento2/computation.md
// block by block.
import type { B2Lesson } from "../../model";
import { multiStep, slip, tapStep, wholeStep } from "../../make";
import { group } from "../../steps";
import { aOrAn } from "../../../curriculum/text";
import type { Rng } from "../../../curriculum/generators/rng";
import {
  And, Not, Or, bin, carries, circuitOut, circuitText, evaluate, hasOp, parse, rows, trueRows, varsOf, wideNot,
  type Ex, type Gate, type GateOpts,
} from "./maths";
import { bitsTyped, cap, options } from "./common";

const TF = ["T", "F"];
const tf = (b: boolean) => (b ? "T" : "F");
const rowText = (vars: string[], r: Record<string, boolean>) => vars.map(v => `${v} = ${tf(r[v]!)}`).join(", ");
/** the same expression with every → read as ∧ (the "false 'if' breaks the promise" slip) */
const impAsAnd = (e: Ex): Ex => (e.k === "var" ? e : e.k === "not" ? Not(impAsAnd(e.a)) : e.k === "imp" ? And(impAsAnd(e.a), impAsAnd(e.b)) : { k: e.k, a: impAsAnd(e.a), b: impAsAnd(e.b) });

/* ------------------------------------------------------------------ 01 ------------------------------------------------------------------ */

const EASY01 = ["p ∧ q", "p ∨ q", "¬p ∨ q", "p ∧ ¬q", "¬(p ∧ q)", "¬p ∧ ¬q", "p ∨ ¬q", "(p ∨ q) ∧ ¬q"];
const HARD01 = ["(p ∨ q) ∧ ¬r", "p ∧ (q ∨ r)", "(p ∧ q) ∨ r", "¬p ∨ (q ∧ r)", "(p ∨ ¬q) ∧ (q ∨ r)", "(p ∧ ¬q) ∨ r", "¬(p ∨ q) ∨ r", "(p ∨ q) ∧ (¬p ∨ r)", "p ∨ (q ∧ ¬r)", "¬(p ∧ r) ∧ q"];

interface P01 { e: string; row: number }
export const cs01: B2Lesson<P01> = {
  id: "b2-cs-01", track: "cs", unit: 1, title: "True, false and truth tables",
  youCan: "build a truth table for any statement and count when it's true.",
  needs: [],
  tools: ["cs-truth"],
  play: { scene: "cs-truth", props: { expr: "(p ∨ q) ∧ ¬r" },
    say: "Type a statement like (p ∨ q) ∧ ¬r and flip the switches for p, q and r. The output light follows, and each setting you try fills one row of a table that grows to 8 rows." },
  guess: { scene: "cs-truth", props: { expr: "(p ∨ q) ∧ ¬r", fill: true, quiet: true }, kind: "slider", min: 1, max: 20, step: 1, start: 10, answer: 16, near: 0.5, unit: "rows",
    format: x => String(Math.round(x)),
    ask: "Three switches give 8 rows. With 4 switches, how many rows does the table need?",
    revealProps: { expr: "(p ∨ q) ∧ (¬r ∨ s)", fill: true },
    reveal: "Bento adds a fourth switch, s, and the table doubles from 8 to 16: every old row now comes once with s = T and once with s = F." },
  nameIt: {
    say: [
      "A statement built from AND (∧), OR (∨) and NOT (¬) is true or false for each setting of its variables.",
      "A **truth table** lists every setting: n variables give 2ⁿ rows.",
      "OR means \"at least one\", not \"exactly one\".",
    ],
    formula: ["rows = 2ⁿ", "p ∧ q is true only when both are", "p ∨ q is false only when both are false"],
  },
  workIt: {
    reference: { e: "(p ∨ q) ∧ ¬r", row: 3 },
    generate(rng, i) {
      const e = rng.pick(i < 3 ? EASY01 : HARD01);
      return { e, row: rng.int(0, 2 ** varsOf(parse(e)!).length - 1) };
    },
    show: p => { const e = parse(p.e)!, vs = varsOf(e); return `The statement **${p.e}**, at the row **${rowText(vs, rows(vs)[p.row]!)}**.`; },
    steps(p) {
      const e = parse(p.e)!, vs = varsOf(e), n = vs.length, r = rows(vs)[p.row]!;
      const v = evaluate(e, r), right = v ? 0 : 1;
      const xorV = evaluate(e, r, { orAsXor: true }), wideV = evaluate(wideNot(e), r);
      const notOnLetter = /¬[pqr]/.test(p.e);
      return [
        wholeStep("rows", "Rows", 2 ** n, {
          ask: `The statement uses ${n} variables. How many rows does its table need?`,
          hint: `Each variable can be T or F, so each one doubles the rows: ${Array(n).fill("2").join(" × ")}.`,
          done: `Rows: 2${n === 2 ? "²" : "³"} = ${2 ** n}`,
          slips: [slip("2n", 2 * n, `Each new variable doubles the rows: ${Array(n).fill("2").join(" × ")} = ${2 ** n}, not ${Array(n).fill("2").join(" + ")}.`)],
        }),
        tapStep("value", "Value at this row", TF, right, {
          ask: `At ${rowText(vs, r)}, is ${p.e} true or false?`,
          hint: "Work from the inside out: the brackets first, then the connective that joins them.",
          done: `Value at ${rowText(vs, r)}: ${tf(v)}`,
          slips: [
            hasOp(e, "or") && xorV !== v && slip("or as exactly one", xorV ? 0 : 1, "OR is inclusive: p ∨ q is true when both are true too."),
            notOnLetter && wideV !== v && slip("not on everything", wideV ? 0 : 1, "¬ binds to the nearest thing: ¬r flips only r."),
          ],
        }),
        wholeStep("true", "True rows", trueRows(e), {
          ask: "How many of the rows make it true?",
          hint: "Flip the switches through every row and count the lit ones.",
          slips: [
            hasOp(e, "or") && slip("or as exactly one", trueRows(e, vs, { orAsXor: true }), "OR is inclusive: p ∨ q is true when both are true too."),
            notOnLetter && slip("not on everything", trueRows(wideNot(e)), "¬ binds to the nearest thing: ¬r flips only r."),
            slip("false rows", 2 ** n - trueRows(e), "That's the rows where it's false. Count the rows where the light is on."),
          ],
        }),
      ];
    },
    scene: p => ({ scene: "cs-truth", props: { expr: p.e, blank: true } }),
  },
  oracle: p => {
    const e = parse(p.e)!, vs = varsOf(e), n = vs.length;
    const env = (m: number) => Object.fromEntries(vs.map((v, k) => [v, ((m >> (n - 1 - k)) & 1) === 0]));
    let count = 0;
    for (let m = 0; m < 2 ** n; m++) if (evaluate(e, env(m))) count++;
    return [2 ** n, evaluate(e, env(p.row)) ? 0 : 1, count];
  },
  useIt: {
    say: ["A door alarm sounds if (the door is open or the window is open) and the alarm is armed: (p ∨ q) ∧ r. How many of the 8 settings sound it?",
      "Three: the alarm has to be armed, and then any of the 3 open combinations sets it off."],
    scene: { scene: "cs-truth", props: { expr: "(p ∨ q) ∧ r" } },
  },
  deeper: [
    "Every one of the 2^(2ⁿ) truth tables on n variables (16 for n = 2) can be written using only ∧, ∨ and ¬: read off its true rows (disjunctive normal form) or its false rows (conjunctive normal form).",
    "Counting those tables is the start of circuit complexity (cs-04, Deeper).",
  ],
};

/* ------------------------------------------------------------------ 02 ------------------------------------------------------------------ */

type PairKind = "converse" | "contra" | "inverse" | "same" | "demorgan-bad";
const PAIRS2: [string, string, PairKind][] = [
  ["p → q", "q → p", "converse"], ["p → q", "¬q → ¬p", "contra"], ["p → q", "¬p → ¬q", "inverse"], ["p → q", "¬p ∨ q", "same"],
  ["¬(p ∧ q)", "¬p ∨ ¬q", "same"], ["¬(p ∧ q)", "¬p ∧ ¬q", "demorgan-bad"], ["¬(p ∨ q)", "¬p ∧ ¬q", "same"], ["¬(p ∨ q)", "¬p ∨ ¬q", "demorgan-bad"],
];
const PAIRS3: [string, string, PairKind][] = [
  ["(p ∧ q) → r", "r → (p ∧ q)", "converse"], ["(p ∧ q) → r", "¬r → ¬(p ∧ q)", "contra"], ["(p ∧ q) → r", "¬r → ¬p ∨ ¬q", "contra"],
  ["p → (q ∨ r)", "¬q ∧ ¬r → ¬p", "contra"], ["p → (q ∨ r)", "(q ∨ r) → p", "converse"], ["p → (q ∨ r)", "¬p → ¬(q ∨ r)", "inverse"],
  ["¬(p ∧ q) ∨ r", "(¬p ∧ ¬q) ∨ r", "demorgan-bad"], ["¬(p ∨ q) ∧ r", "¬p ∧ ¬q ∧ r", "same"],
];
const WORDS = [
  { P: "it rained", Q: "the street is wet", nP: "it didn't rain", nQ: "the street is dry", why: "a wet street might be from a sprinkler" },
  { P: "you're in Paris", Q: "you're in France", nP: "you're not in Paris", nQ: "you're not in France", why: "you might be in Lyon" },
  { P: "it's a square", Q: "it has four sides", nP: "it isn't a square", nQ: "it doesn't have four sides", why: "a kite has four sides too" },
  { P: "Do Not Disturb is on", Q: "calls are silenced", nP: "Do Not Disturb is off", nQ: "calls ring", why: "calls might be silenced some other way" },
  { P: "the battery is dead", Q: "the phone won't turn on", nP: "the battery isn't dead", nQ: "the phone turns on", why: "a broken screen can stop it too" },
];
const wordOptions = (w: (typeof WORDS)[number]) => {
  const contra = `If ${w.nQ}, ${w.nP}.`, converse = `If ${w.Q}, ${w.P}.`, inverse = `If ${w.nP}, ${w.nQ}.`, but = `${cap(w.P)} and ${w.nQ}.`;
  const o = options(contra, [converse, inverse, but]);
  return { ...o, converse: o.all.indexOf(converse), inverse: o.all.indexOf(inverse) };
};
const differ = (a: Ex, b: Ex) => { const vs = varsOf(Or(a, b)); return rows(vs).filter(r => evaluate(a, r) !== evaluate(b, r)).length; };

interface P02 { a: string; b: string; kind: PairKind; row: number; w: number }
export const cs02: B2Lesson<P02> = {
  id: "b2-cs-02", track: "cs", unit: 1, title: "If, then: the rules of logic",
  youCan: "tell when two statements say the same thing, and spot the converse trap.",
  needs: ["b2-cs-01"],
  tools: ["cs-truth", "cs-proof"],
  play: { scene: "cs-truth", props: { expr: "p → q", expr2: "q → p" },
    say: "Two statements side by side: p → q and q → p. The rows where they disagree glow. Edit the second one until no row glows." },
  guess: { scene: "cs-truth", props: { expr: "p → q", expr2: "q → p", expr3: "¬q → ¬p", legend: "p: it rained · q: the street is wet", fill: true, quiet: true }, kind: "choice",
    options: ["If the street is wet, it rained", "If the street is dry, it didn't rain"], answer: 1,
    ask: "\"If it rained, the street is wet.\" Which says the same thing?",
    revealProps: { expr: "p → q", expr2: "q → p", expr3: "¬q → ¬p", legend: "p: it rained · q: the street is wet", fill: true },
    reveal: "The panel runs both against the original. \"If wet, then rained\" (q → p) disagrees on 2 rows; \"if dry, then no rain\" (¬q → ¬p) matches on all 4." },
  nameIt: {
    say: [
      "**p → q** is false in exactly one case: p true and q false. Its **contrapositive** ¬q → ¬p always says the same thing; its **converse** q → p doesn't.",
      "Two statements are **equivalent** when they agree on every row.",
      "De Morgan's laws flip ANDs and ORs under a NOT.",
    ],
    formula: ["p → q ≡ ¬p ∨ q ≡ ¬q → ¬p", "¬(p ∧ q) ≡ ¬p ∨ ¬q", "¬(p ∨ q) ≡ ¬p ∧ ¬q"],
  },
  workIt: {
    reference: { a: "p → q", b: "q → p", kind: "converse", row: 2, w: 0 },
    generate(rng, i) {
      const [a, b, kind] = rng.pick(i < 3 ? PAIRS2 : PAIRS3);
      return { a, b, kind, row: rng.int(0, 2 ** varsOf(Or(parse(a)!, parse(b)!)).length - 1), w: rng.int(0, WORDS.length - 1) };
    },
    show: p => {
      const vs = varsOf(Or(parse(p.a)!, parse(p.b)!)), w = WORDS[p.w]!;
      return `Compare **${p.a}** with **${p.b}**, starting at the row ${rowText(vs, rows(vs)[p.row]!)}. Then: "If ${w.P}, ${w.Q}."`;
    },
    steps(p) {
      const A = parse(p.a)!, B = parse(p.b)!, vs = varsOf(Or(A, B)), r = rows(vs)[p.row]!, n = vs.length;
      const v = evaluate(A, r), slipV = evaluate(impAsAnd(A), r);
      const d = differ(A, B), same = d === 0 ? 0 : 1;
      const w = WORDS[p.w]!, wo = wordOptions(w);
      const eqMsg: Record<PairKind, string> = {
        converse: `The converse turns it around and can fail: ${d} rows glow.`,
        inverse: "The inverse flips both sides without swapping them, and it can fail just like the converse.",
        "demorgan-bad": "Under a NOT, AND becomes OR: it's enough that one of them fails.",
        same: "They agree on every row: nothing glows, so they say the same thing.",
        contra: "They agree on every row: the contrapositive always says the same thing.",
      };
      return [
        tapStep("value", `Value of ${p.a}`, TF, v ? 0 : 1, {
          ask: `At ${rowText(vs, r)}, is ${p.a} true or false?`,
          hint: hasOp(A, "imp") ? "An arrow is false only when its left side is true and its right side is false." : "Work out the inside first, then apply the NOT.",
          done: `${p.a} at ${rowText(vs, r)}: ${tf(v)}`,
          slips: [hasOp(A, "imp") && slipV !== v && slip("false if", slipV ? 0 : 1, "A promise with a false \"if\" isn't broken. p → q is false only when p is true and q is false.")],
        }),
        wholeStep("differ", "Rows where they differ", d, {
          ask: `Of the ${2 ** n} rows, on how many do ${p.a} and ${p.b} disagree?`,
          hint: "Build both columns and count the rows where one is T and the other is F.",
          slips: [slip("agree", 2 ** n - d, "That's the rows where they agree. Count the rows that glow: where one is T and the other is F.")],
        }),
        tapStep("eq", "Equivalent?", ["Yes", "No"], same, {
          hint: "Equivalent means they agree on every row: no row glows.",
          slips: [slip(p.kind, 1 - same, p.kind === "converse" ? `The converse turns it around and can fail: ${d === 1 ? "1 row glows" : `${d} rows glow`}.` : eqMsg[p.kind])],
        }),
        tapStep("words", "Pick the same statement", wo.all, wo.at, {
          ask: `Which says the same thing as "If ${w.P}, ${w.Q}."?`,
          hint: "Swap the two sides and negate both: that's the contrapositive.",
          slips: [
            slip("converse", wo.converse, `The converse turns it around and can fail: ${w.why}.`),
            slip("inverse", wo.inverse, `That's the inverse: it negates both sides without swapping them, and it fails the same way: ${w.why}.`),
          ],
        }),
      ];
    },
    scene: p => ({ scene: "cs-truth", props: { expr: p.a, expr2: p.b, blank: true } }),
  },
  oracle: p => {
    const A = parse(p.a)!, B = parse(p.b)!, vs = varsOf(Or(A, B)), n = vs.length;
    const env = (m: number) => Object.fromEntries(vs.map((v, k) => [v, ((m >> (n - 1 - k)) & 1) === 0]));
    let d = 0;
    for (let m = 0; m < 2 ** n; m++) if (evaluate(A, env(m)) !== evaluate(B, env(m))) d++;
    return [evaluate(A, env(p.row)) ? 0 : 1, d, d === 0 ? 0 : 1, wordOptions(WORDS[p.w]!).at];
  },
  useIt: {
    say: ["A phone's rule: \"if Do Not Disturb is on, then calls are silenced.\" Which rule is equivalent, and which only sounds equivalent?",
      "\"If calls ring, Do Not Disturb is off\" is the same rule. \"If calls are silenced, Do Not Disturb is on\" is the converse: calls might be silenced some other way."],
    scene: { scene: "cs-truth", props: { expr: "p → q", expr2: "¬q → ¬p", legend: "p: Do Not Disturb is on · q: calls are silenced" } },
  },
  deeper: [
    "Soundness and completeness for propositional logic: a statement is provable from the rules exactly when it's true on every row.",
    "Resolution is a single rule that's complete for refutation, and it's the basis of SAT solvers (and so of cs-12).",
  ],
};

/* ------------------------------------------------------------------ 03 ------------------------------------------------------------------ */

type Claim = "odd" | "nat" | "pow" | "sq";
const CLAIMS: Record<Claim, { sum: string; rhs: string; first: string; term: (k: number) => number; termText: string; at: (N: number) => number; line: string; sumAt: (N: number) => string }> = {
  odd: { sum: "1 + 3 + 5 + … + (2n − 1)", rhs: "n²", first: "1", term: k => 2 * k + 1, termText: "2(k + 1) − 1 = 2k + 1", at: N => N * N,
    line: "1 + 3 + … + (2k − 1) + (2k + 1) = k² + 2k + 1", sumAt: N => `1 + 3 + … + ${2 * N - 1}` },
  nat: { sum: "1 + 2 + … + n", rhs: "n(n + 1)/2", first: "1", term: k => k + 1, termText: "k + 1", at: N => (N * (N + 1)) / 2,
    line: "1 + 2 + … + k + (k + 1) = k(k + 1)/2 + (k + 1)", sumAt: N => `1 + 2 + … + ${N}` },
  pow: { sum: "1 + 2 + 4 + … + 2ⁿ⁻¹", rhs: "2ⁿ − 1", first: "2⁰ = 1", term: k => 2 ** k, termText: "2ᵏ", at: N => 2 ** N - 1,
    line: "1 + 2 + … + 2ᵏ⁻¹ + 2ᵏ = (2ᵏ − 1) + 2ᵏ", sumAt: N => `1 + 2 + 4 + … + ${group(2 ** (N - 1))}` },
  sq: { sum: "1² + 2² + … + n²", rhs: "n(n + 1)(2n + 1)/6", first: "1² = 1", term: k => (k + 1) ** 2, termText: "(k + 1)²", at: N => (N * (N + 1) * (2 * N + 1)) / 6,
    line: "1² + … + k² + (k + 1)² = k(k + 1)(2k + 1)/6 + (k + 1)²", sumAt: N => `1² + 2² + … + ${N}²` },
};
export const REASONS = ["Algebra", "Definition", "Given", "Induction hypothesis", "What we want to prove"];

interface P03 { kind: Claim; k: number; N: number }
export const cs03: B2Lesson<P03> = {
  id: "b2-cs-03", track: "cs", unit: 1, title: "Proof steps and induction",
  youCan: "prove a statement for every whole number with induction, justifying every step.",
  needs: ["b2-cs-02", "g11-seq"],
  tools: ["cs-proof"],
  play: { scene: "cs-proof", props: { mode: "dominoes", n: 12 },
    say: "A row of dominoes, one per n. Fill the base case and the first domino tips; justify the step \"if n works, then n + 1 works\" and the whole row falls. Leave the step unjustified and the chain stops there." },
  guess: { scene: "cs-proof", props: { mode: "dominoes", n: 10, quiet: true }, kind: "slider", min: 0, max: 200, step: 1, start: 50, answer: 100, near: 0.5,
    format: x => String(Math.round(x)),
    ask: "1 + 3 + 5 + … + (2n − 1). For n = 10, what's the sum?",
    revealProps: { mode: "dominoes", n: 10, run: true },
    reveal: "The dominoes run to 10, and the odd numbers fit around each other as L shapes into a 10 × 10 square: 100." },
  nameIt: {
    say: [
      "**Induction** proves a claim P(n) for every n in two moves: prove P(1), then prove that P(n) forces P(n + 1).",
      "Every line in a proof needs a reason: a given, a definition, algebra, or the **induction hypothesis** (assuming P(n) for the step).",
    ],
    formula: ["P(1) and P(n) ⇒ P(n + 1) give P(n) for all n ≥ 1", "1 + 3 + … + (2n − 1) = n²", "1 + 2 + … + n = n(n + 1)/2", "1 + 2 + 4 + … + 2ⁿ⁻¹ = 2ⁿ − 1"],
  },
  workIt: {
    reference: { kind: "odd", k: 4, N: 10 },
    generate(rng, i) {
      const kind = rng.pick<Claim>(i < 3 ? ["odd", "nat", "pow"] : ["odd", "nat", "pow", "sq"]);
      return { kind, k: i < 3 ? rng.int(2, 6) : rng.int(5, 20), N: kind === "pow" ? rng.int(10, 20) : rng.int(10, 100) };
    },
    show: p => `Claim: **${CLAIMS[p.kind].sum} = ${CLAIMS[p.kind].rhs}** for every n ≥ 1.`,
    steps(p) {
      const c = CLAIMS[p.kind], k = p.k;
      const slips2 = p.kind === "odd" ? [slip("old term", 2 * k - 1, "The next term uses n = k + 1: 2(k + 1) − 1 = 2k + 1.")]
        : p.kind === "nat" ? [slip("old term", k, "That's the last term of P(k). The next one is k + 1.")]
        : p.kind === "pow" ? [slip("old term", 2 ** (k - 1), `That's the last term of P(k). The next one doubles it: 2${k === 1 ? "" : "ᵏ"}.`), slip("one too far", 2 ** (k + 1), "That's two terms on. Going from n = k to n = k + 1 brings in one new term: 2ᵏ.")]
        : [slip("old term", k * k, "That's the last term of P(k). The next one is (k + 1)².")];
      const slips4 = p.kind === "odd" ? [slip("last term", 2 * p.N - 1, `That's the last term, 2N − 1. Add them all up: N² = ${group(p.N * p.N)}.`)]
        : p.kind === "nat" ? [slip("n squared", p.N * p.N, "That's N². Pairing 1 with N, 2 with N − 1, and so on gives N(N + 1)/2.")]
        : p.kind === "pow" ? [slip("2 to the N", 2 ** p.N, "Check n = 1: one term, and 1 = 2¹ − 1. The sum is 2ᴺ − 1.")]
        : [slip("plain sum", (p.N * (p.N + 1)) / 2, "That's 1 + 2 + … + N. Square each term first: N(N + 1)(2N + 1)/6.")];
      return [
        wholeStep("base", "Base case", 1, {
          ask: `The left side of the claim at n = 1: just the first term.`,
          hint: `At n = 1 the sum has one term: ${c.first}.`,
          slips: [p.kind === "pow" && slip("2 to the 1", 2, "The first term is 2⁰ = 1, and 2¹ − 1 = 1 agrees.")],
        }),
        wholeStep("term", "Term added", c.term(k), {
          ask: `Going from n = ${k} to n = ${k + 1}, which number joins the sum?`,
          hint: `The new term is the formula's term at n = k + 1: ${c.termText}, with k = ${k}.`,
          slips: slips2,
        }),
        tapStep("why", "Justify the step", REASONS, 3, {
          ask: `The step's key line: ${c.line}. What lets you swap the first k terms for their total?`,
          hint: "The step may assume the claim for k, and nothing more.",
          slips: [
            slip("circular", 4, "That's circular. The step may only assume P(k), the induction hypothesis."),
            slip("algebra first", 0, "The algebra comes after. Swapping the first k terms for their total needs P(k), the induction hypothesis."),
          ],
        }),
        wholeStep("value", "Value at N", c.at(p.N), {
          ask: `Use the formula: ${c.sumAt(p.N)}, at n = ${p.N}.`,
          hint: `Put n = ${p.N} into ${c.rhs}.`,
          slips: slips4,
        }),
      ];
    },
    scene: p => ({ scene: "cs-proof", props: { mode: "dominoes", n: Math.min(20, p.k + 1), quiet: true } }),
  },
  oracle: p => {
    const term = (n: number) => (p.kind === "odd" ? 2 * n - 1 : p.kind === "nat" ? n : p.kind === "pow" ? 2 ** (n - 1) : n * n);
    let s = 0;
    for (let n = 1; n <= p.N; n++) s += term(n);
    return [term(1), term(p.k + 1), 3, s];
  },
  useIt: {
    say: ["A robot climbs stairs 1 or 2 steps at a time. Count the ways for n stairs: 1, 2, 3, 5, 8, … (10 stairs → 89).",
      "Prove by induction that the count is the Fibonacci number F(n + 1): the last move is 1 step or 2, so the ways for n + 1 stairs are the ways for n plus the ways for n − 1. The proof column goes to your Notebook."],
    scene: { scene: "cs-proof", props: { mode: "stairs", n: 10 } },
  },
  deeper: [
    "Strong induction and the well-ordering principle; structural induction on trees and programs, which is how compilers are proved correct.",
    "Proof assistants like Lean check every line by machine, which connects proofs to computation. Gödel's incompleteness theorem (cs-14, Deeper) shows where any such system must stop.",
    "Without a base case nothing falls: \"every n is bigger than itself plus 1\" has a valid step and no base.",
  ],
};

/* ------------------------------------------------------------------ 04 ------------------------------------------------------------------ */

const NANDS: Record<string, number> = { NOT: 1, AND: 2, OR: 3, XOR: 4 };
const INS = ["x", "y", "z"];
const envText = (ins: string[], env: Record<string, number>) => ins.map(v => `${v} = ${env[v]}`).join(", ");
const lightCount = (gs: Gate[], ins: string[], o: GateOpts = {}) => {
  let c = 0;
  for (let m = 0; m < 2 ** ins.length; m++) c += circuitOut(gs, Object.fromEntries(ins.map((v, k) => [v, (m >> k) & 1])), o);
  return c;
};
export const inputsOf = (gs: Gate[]) => INS.filter(v => gs.some(g => g.a === v || g.b === v));

function makeCircuit(rng: Rng, nIn: number, nGates: number): Gate[] {
  const ins = INS.slice(0, nIn);
  for (;;) {
    const gs: Gate[] = [];
    for (let k = 0; k < nGates; k++) {
      const op = rng.pick<Gate["op"]>(k === 0 ? ["AND", "OR", "XOR", "NAND"] : ["AND", "OR", "XOR", "NAND", "NOT", "XOR", "AND"]);
      if (k === 0) { gs.push({ op, a: "x", b: "y" }); continue; }
      if (op === "NOT") { if (gs[k - 1]!.op === "NOT") { k--; continue; } gs.push({ op, a: k - 1 }); continue; }
      const pool: (string | number)[] = [...ins, ...Array.from({ length: Math.max(0, k - 1) }, (_, j) => j)];
      gs.push({ op, a: k - 1, b: k === 1 && nIn === 3 ? "z" : rng.pick(pool) });
    }
    if (inputsOf(gs).length !== nIn) continue;
    const c = lightCount(gs, ins);
    if (c === 0 || c === 2 ** nIn) continue;
    return gs;
  }
}
const GATES_TEXT = (gs: Gate[]) => gs.map(g => `${g.op}:${g.a}${g.b == null ? "" : `:${g.b}`}`).join(" ");

interface P04 { gates: Gate[]; env: Record<string, number>; named: string }
export const cs04: B2Lesson<P04> = {
  id: "b2-cs-04", track: "cs", unit: 1, title: "Logic gates",
  youCan: "read a circuit of gates, and build any gate out of NANDs.",
  needs: ["b2-cs-01"],
  tools: ["cs-gates"],
  play: { scene: "cs-gates", props: { mode: "free" },
    say: "Pick a gate (AND, OR, NOT, XOR or NAND), wire it to two switches and a light, and flip the switches. 1s glow along the wires as they flow through." },
  guess: { scene: "cs-gates", props: { mode: "nand", gate: "AND", quiet: true }, kind: "slider", min: 1, max: 6, step: 1, start: 4, answer: 2, near: 0.5, unit: "NANDs",
    format: x => String(Math.round(x)),
    ask: "How many NAND gates does it take to make an AND?",
    revealProps: { mode: "nand", gate: "AND" },
    reveal: "The board builds it: a NAND, then a second NAND with both inputs tied together, used as a NOT. That's 2." },
  nameIt: {
    say: [
      "A **gate** is a truth table made physical: wires carry 1 or 0. **XOR** (⊕) is 1 when exactly one input is 1.",
      "**NAND** is NOT-AND, and it's **universal**: every other gate can be made from NANDs alone. A chip is billions of these.",
    ],
    formula: ["NOT a = a NAND a", "a AND b = NOT(a NAND b)", "a OR b = (NOT a) NAND (NOT b)", "a ⊕ b uses 4 NANDs"],
  },
  workIt: {
    reference: { gates: [{ op: "XOR", a: "x", b: "y" }, { op: "AND", a: 0, b: "x" }], env: { x: 1, y: 1 }, named: "OR" },
    generate(rng, i) {
      const nIn = i < 3 ? 2 : 3, gates = makeCircuit(rng, nIn, i < 3 ? rng.int(2, 3) : rng.int(3, 5));
      return { gates, env: Object.fromEntries(INS.slice(0, nIn).map(v => [v, rng.int(0, 1)])), named: rng.pick(i < 3 ? ["AND", "OR", "NOT"] : ["NOT", "AND", "OR", "XOR"]) };
    },
    show: p => `The circuit **${circuitText(p.gates)}**, with inputs ${envText(inputsOf(p.gates), p.env)}.`,
    steps(p) {
      const ins = inputsOf(p.gates), out = circuitOut(p.gates, p.env);
      const xo = circuitOut(p.gates, p.env, { xorAsOr: true }), na = circuitOut(p.gates, p.env, { nandAsAnd: true });
      const has = (op: string) => p.gates.some(g => g.op === op);
      const c = lightCount(p.gates, ins);
      const nand = NANDS[p.named]!;
      return [
        tapStep("out", "Output", ["0", "1"], out, {
          ask: `With ${envText(ins, p.env)}, what does the last gate send out?`,
          hint: "Go gate by gate from the inputs, writing the 1 or 0 on each wire.",
          done: `Output at ${envText(ins, p.env)}: ${out}`,
          slips: [
            has("XOR") && xo !== out && slip("xor of 1 and 1", xo, "XOR means exactly one. Two 1s give 0; that's what makes it useful for adding."),
            has("NAND") && na !== out && slip("nand as and", na, "NAND flips the AND: it's 0 only when both inputs are 1."),
          ],
        }),
        wholeStep("count", "Inputs that light it", c, {
          ask: `Of the ${2 ** ins.length} settings of ${ins.join(", ")}, how many make the output 1?`,
          hint: "Try every setting of the switches and count the ones that light the output.",
          slips: [
            has("XOR") && slip("xor of 1 and 1", lightCount(p.gates, ins, { xorAsOr: true }), "XOR means exactly one. Two 1s give 0; that's what makes it useful for adding."),
            has("NAND") && slip("nand as and", lightCount(p.gates, ins, { nandAsAnd: true }), "NAND flips the AND: it's 0 only when both inputs are 1."),
            slip("zeros", 2 ** ins.length - c, "That's the settings that give 0. Count the ones that light it."),
          ],
        }),
        wholeStep("nands", `NANDs for ${p.named}`, nand, {
          ask: `How many NAND gates make ${aOrAnWord(p.named)} ${p.named}?`,
          hint: { NOT: "Tie both inputs of one NAND together: a NAND a = NOT a.", AND: "NAND, then a NAND used as NOT to flip it back.", OR: "NOT a and NOT b first, then one NAND to combine them.", XOR: "The classic build shares one NAND between the other three." }[p.named]!,
          slips: [
            p.named === "OR" && slip("or as 2", 2, "You need NOT a and NOT b first: two NANDs, then one more NAND to combine them. That's 3."),
            p.named === "AND" && slip("and as 1", 1, "A NAND alone is NOT-AND. One more NAND, used as NOT, flips it back: 2."),
            p.named === "NOT" && slip("not as 2", 2, "Feed the same wire into both inputs: a NAND a = NOT a. One gate does it."),
            p.named === "XOR" && slip("xor as 5", 5, "One NAND of a and b is shared by the other three. XOR takes 4."),
          ],
        }),
      ];
    },
    scene: p => ({ scene: "cs-gates", props: { mode: "circuit", c: GATES_TEXT(p.gates), env: inputsOf(p.gates).map(v => p.env[v]).join(""), quiet: true } }),
  },
  oracle: p => {
    const ins = inputsOf(p.gates);
    const run = (env: Record<string, number>) => {
      const vals: number[] = [];
      for (const gt of p.gates) {
        const get = (s: string | number) => (typeof s === "number" ? vals[s]! : env[s]!);
        const a = get(gt.a), b = gt.b == null ? 0 : get(gt.b);
        vals.push({ AND: a * b, OR: Math.max(a, b), XOR: (a + b) % 2, NAND: 1 - a * b, NOT: 1 - a }[gt.op]);
      }
      return vals[vals.length - 1]!;
    };
    let c = 0;
    for (let m = 0; m < 2 ** ins.length; m++) c += run(Object.fromEntries(ins.map((v, k) => [v, (m >> k) & 1])));
    return [run(p.env), c, { NOT: 1, AND: 2, OR: 3, XOR: 4 }[p.named]!];
  },
  useIt: {
    say: ["Build XOR on the board from 4 NANDs and save it as a chip: two inputs, one output, 1 when exactly one input is 1.",
      "It's the first part of the adder: XOR is the sum bit of a column."],
    saves: { name: "xor", value: () => [0, 1, 1, 0], labels: ["0 0", "0 1", "1 0", "1 1"], note: "the XOR chip's truth table, from 4 NANDs" },
    scene: { scene: "cs-gates", props: { mode: "nand", gate: "XOR" } },
  },
  deeper: [
    "NAND is universal because the normal forms from cs-01 use only AND, OR and NOT, and each of those is a few NANDs.",
    "Shannon's counting argument: there are 2^(2ⁿ) functions on n inputs but far fewer small circuits, so most functions need about 2ⁿ/n gates. Yet no one can prove any specific function in NP needs more than a few times n gates.",
    "A single neuron with a threshold is a weighted gate. One neuron can do AND and OR but not XOR (b2-ai-04).",
  ],
};
const aOrAnWord = (w: string) => (/^[AEIOUX]/.test(w) ? "an" : "a");

/* ------------------------------------------------------------------ 05 ------------------------------------------------------------------ */

interface P05 { a: number; b: number; n: number }
export const cs05: B2Lesson<P05> = {
  id: "b2-cs-05", track: "cs", unit: 1, title: "An adder from gates",
  youCan: "build a circuit that adds binary numbers, carry by carry.",
  needs: ["b2-cs-04"],
  tools: ["cs-gates", "scratch"],
  play: { scene: "cs-gates", props: { mode: "adder", a: 11, b: 6 },
    say: "Four full adders chained into a 4-bit adder, each one a half adder's XOR and AND plus a carry. Tap the input bits to set two numbers from 0 to 15 and watch the carry ripple from right to left, one column at a time." },
  guess: { scene: "cs-gates", props: { mode: "adder", a: 11, b: 6, quiet: true }, kind: "choice",
    options: ["Column 2 only", "Columns 2, 3 and 4", "Columns 1 and 2", "No column"], answer: 1,
    ask: "1011 + 0110. Which columns will send a carry left (counting from the right)?",
    revealProps: { mode: "adder", a: 11, b: 6 },
    reveal: "The board ripples: column 2 makes 1 + 1, and its carry makes columns 3 and 4 add up to 2 as well. The carry-out light turns on: 10001 = 17." },
  nameIt: {
    say: [
      "Binary adding is column by column: the sum bit is XOR and the carry is \"at least two of the three inputs are 1\".",
      "A **half adder** adds two bits; a **full adder** adds two bits plus a carry, using 2 XOR, 2 AND and 1 OR.",
      "Chain n full adders and you can add n-bit numbers: the **ripple-carry adder**.",
    ],
    formula: ["sum = a ⊕ b ⊕ c", "carry = (a ∧ b) ∨ (c ∧ (a ⊕ b))", "gates for n bits = 5n"],
  },
  workIt: {
    reference: { a: 11, b: 6, n: 32 },
    generate(rng, i) {
      const n = rng.pick([4, 8, 16, 32, 64]);
      if (i < 3) {
        for (;;) {
          const a = rng.int(0, 7), b = rng.int(0, 7);
          if (carries(a, b).filter(c => c).length <= 1) return { a, b, n };
        }
      }
      return { a: rng.int(0, 15), b: rng.int(0, 15), n };
    },
    show: p => `**${bin(p.a, 4)} + ${bin(p.b, 4)}** on the 4-bit adder (that's ${p.a} + ${p.b}). Then a ripple-carry adder for ${aOrAn(p.n)} **${p.n}-bit** number.`,
    steps(p) {
      const a0 = p.a & 1, b0 = p.b & 1, s = p.a + p.b, low = s % 16, cout = s >> 4;
      return [
        multiStep("bottom", "Bottom column", [a0 ^ b0, a0 & b0], "whole", {
          boxes: ["sum bit", "carry"], ask: `The rightmost column adds ${a0} + ${b0}.`,
          hint: "The sum bit is 1 when exactly one is 1; the carry is 1 when both are.",
          done: `Bottom column: ${a0} + ${b0} → sum ${a0 ^ b0}, carry ${a0 & b0}`,
          slips: [a0 === 1 && b0 === 1 && slip("two", [2, 0], "In binary 1 + 1 = 10: the sum bit is 0 and the 1 carries.")],
        }),
        wholeStep("sum", "Sum bits", bitsTyped(bin(low, 4)), {
          ask: "Type the 4 sum bits, like 0101, carrying as you go.",
          hint: "Go right to left. Each column adds a, b and the carry in: write the last bit, carry the rest.",
          done: `Sum bits: ${bin(low, 4)}`,
          slips: [
            slip("no carry", bitsTyped(bin(p.a ^ p.b, 4)), "That's XOR column by column. 1 + 1 makes 0 and carries 1 to the next column."),
            cout === 1 && slip("five bits", bitsTyped(bin(s, 5)), "Four boxes, four sum bits: the fifth bit is the carry out, which comes next."),
          ],
        }),
        tapStep("cout", "Carry out", ["0", "1"], cout, {
          hint: "The leftmost column sends a carry out when it adds up to 2 or more.",
          done: `Carry out: ${cout}`,
          slips: [slip("carry out", 1 - cout, cout ? "The leftmost column adds up to 2 or more, so it sends a 1 out: the carry out." : "The leftmost column adds up to less than 2, so nothing carries out.")],
        }),
        wholeStep("dec", "In decimal", s, {
          ask: "The whole answer, carry out and all, as an ordinary number.",
          hint: `${p.a} + ${p.b}. The carry out is worth 16.`,
          slips: [cout === 1 && slip("dropped carry", low, `4 bits only hold 0 to 15. ${s} needs the carry out as a fifth bit: ${bin(s, 5)}.`)],
        }),
        wholeStep("gates", "Gates", 5 * p.n, {
          ask: `How many gates does ${aOrAn(p.n)} ${p.n}-bit ripple-carry adder use?`,
          hint: "One full adder per bit, 5 gates each.",
          slips: [slip("two per bit", 2 * p.n, "Each column needs a full adder (5 gates) to take a carry in, so 5 per bit.")],
        }),
      ];
    },
    scene: p => ({ scene: "cs-gates", props: { mode: "adder", a: p.a, b: p.b, quiet: true } }),
  },
  oracle: p => [(p.a ^ p.b) & 1, p.a & p.b & 1, bitsTyped(((p.a + p.b) % 16).toString(2)), (p.a + p.b) >> 4, p.a + p.b, 5 * p.n],
  useIt: {
    say: ["**Project: Your adder chip.** Box your 4 full adders into a chip with 8 input pins, 4 output pins and a carry.",
      "It's saved as `adder4`: the first half of the machine room."],
    project: "cs-adder",
  },
  deeper: [
    "The ripple carry takes time proportional to n. A carry-lookahead adder computes all the carries in about log₂ n gate delays using \"generate\" and \"propagate\" signals, the same prefix trick as a parallel scan.",
    "Two's complement turns the adder into a subtractor with one XOR per bit.",
  ],
};

export const UNIT1 = [cs01, cs02, cs03, cs04, cs05];
