import { frac } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildMarbleBag } from "../../../../explanations/diagrams/marbles/build";
import { asRecord, expected, fracText, fs, mt, ns, numberField } from "../../_geometry/kit";
import { count } from "../../../text";

/** A bag of r red, b blue and g green marbles; c picks the colour asked about (0 red, 1 blue, 2 green). */
export interface ProbabilityProblem {
  kind: "probability.marbles";
  r: number;
  b: number;
  g: number;
  c: 0 | 1 | 2;
}

const NAMES = ["red", "blue", "green"] as const;

export function createProbability(r: number, b: number, g: number, c: number): ProbabilityProblem {
  if (![r, b, g].every(v => Number.isInteger(v) && v >= 0) || r + b + g === 0) throw new Error("counts are whole numbers");
  if (c !== 0 && c !== 1 && c !== 2) throw new Error("colour 0, 1 or 2");
  if ([r, b, g][c] === 0) throw new Error("the colour asked about must be in the bag");
  return { kind: "probability.marbles", r, b, g, c };
}

export function restoreProbability(raw: unknown): ProbabilityProblem | null {
  const o = asRecord(raw);
  const r = o && numberField(o, "r"), b = o && numberField(o, "b"), g = o && numberField(o, "g"), c = o && numberField(o, "c");
  if (r == null || b == null || g == null || c == null) return null;
  try { return createProbability(r, b, g, c); } catch { return null; }
}

/** " = 1/3" when want/T simplifies, else nothing */
const simp = (n: number, d: number) => { const g = gcdOf(n, d); return g > 1 ? ` = ${n / g}/${d / g}` : ""; };
const gcdOf = (a: number, b: number): number => (b ? gcdOf(b, a % b) : a);

export function probabilityAnswers(p: ProbabilityProblem): AnswerModel {
  const want = [p.r, p.b, p.g][p.c]!, name = NAMES[p.c], T = p.r + p.b + p.g;
  return {
    steps: [
      ns({ id: "want", label: "Ways to win", question: `How many marbles are ${name}?`, prompt: s => [s], ans: want, hint: `Count the ${count(name, "one")}.`,
        wrong: [[T, "Counted every marble", `Count only the ${name} ones.`]] }),
      ns({ id: "all", label: "All the ways", question: "How many marbles in all?", prompt: s => [s], ans: T, hint: "Add all three colors.",
        wrong: [[T - want, `Left out the ${name} ones`, `All the marbles means every color, the ${name} ones too.`]] }),
      { ...fs({ id: "chance", label: "Write the chance", prompt: s => mt`P(${name}) = ${s}`, N: want, D: T, hint: `How many are ${name}, out of how many in all? Write it in lowest terms.`,
        wrong: [[want, T - want, "Used the losers on the bottom", "The bottom is **all** the marbles."]] }),
        known: [{ values: { n: want, d: T - want }, kind: "Used the losers on the bottom", message: "The bottom is **all** the marbles." }],
        explain: `${want} ${name} out of ${T} in all: ${want}/${T}${simp(want, T)}.` },
    ],
    finalParts: [-1],
  };
}

export function explainProbability(p: ProbabilityProblem, answers: AnswerModel): Explanation {
  const name = NAMES[p.c], want = expected(answers, "want"), T = expected(answers, "all");
  const n = expected(answers, "chance", "n"), d = expected(answers, "chance", "d");
  const chance = fracText(n, d);
  return {
    heading: "Winners over everything",
    idea: ["The chance of a color is how many of that color, out of how many marbles in all.", "Write it as a fraction in lowest terms."],
    statement: mt`P(${name}) = ${name} ÷ all`,
    caption: `${want} of the ${T} ${want === 1 ? "is" : "are"} ${name}: P(${name}) = ${chance}.`,
    diagram: buildMarbleBag({
      groups: [{ n: p.r, cls: "red", name: "red" }, { n: p.b, cls: "blue", name: "blue" }, { n: p.g, cls: "green", name: "green" }].filter(g => g.n > 0),
      want: [p.r, p.b, p.g].slice(0, p.c).filter(x => x > 0).length,
      wantBeat: 1, allBeat: 2, chanceBeat: 3,
      wantNote: `${want} ${name}`, allNote: `${p.r} + ${p.b} + ${p.g} = ${T} in all`, chanceNote: `P(${name}) = ${want}/${T}${chance === `${want}/${T}` ? "" : ` = ${chance}`}`,
      alt: `${p.r} red, ${p.b} blue and ${p.g} green marbles. ${want} of the ${T} are ${name}, so P(${name}) = ${chance}.`,
    }),
    timeline: beats(4),
    steps: [
      { id: "bag", narration: `The bag holds ${p.r} red, ${p.b} blue and ${p.g} green marbles. You pick one without looking.`, math: mt`${p.r} red, ${p.b} blue, ${p.g} green`, state: 0 },
      { id: "want", narration: `${want} of them ${want === 1 ? "is" : "are"} ${name}: those are the ways to win.`, math: mt`${want}`, state: 1, answerStep: "want", result: want },
      { id: "all", narration: `There are ${p.r} + ${p.b} + ${p.g} = ${count(T, "marble")} in all.`, math: mt`${p.r} + ${p.b} + ${p.g} = ${T}`, state: 2, answerStep: "all", result: T },
      { id: "chance", narration: `The chance is ${want} out of ${T}${chance === `${want}/${T}` ? "" : `, which simplifies to ${chance}`}.`, math: n === want && d === T ? mt`P(${name}) = ${frac(want, T)}` : mt`P(${name}) = ${frac(want, T)} = ${frac(n, d)}`, state: 3, answerStep: "chance", result: n },
    ],
  };
}

export const lesson: LessonDefinition<ProbabilityProblem> = {
  id: "g7-prob",
  grade: 7,
  unit: "Probability",
  title: "Probability",
  reference: createProbability(3, 5, 2, 0),
  // the first three: a small bag, up to 4 of each color
  generate: (rng, index) => { const t = index < 3 ? 4 : 8; return createProbability(rng.int(1, t), rng.int(1, t), rng.int(1, t), rng.int(0, 2)); },
  restore: restoreProbability,
  display: p => mt`${p.r} red, ${p.b} blue, ${p.g} green`,
  displayNote: p => `You pick one marble without looking. What's the chance it's ${NAMES[p.c]}?`,
  answers: probabilityAnswers,
  explain: explainProbability,
};
