import { answer, frac, op } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildFracGrid } from "../../../../explanations/diagrams/frac-grid/build";
import { expectedOf, finalForm, gcd, ms, readNumbers, simplifyStep } from "../../area-common/steps";
import { count } from "../../../text";

/** a/b × c/d, each fraction proper and in lowest terms. */
export interface FracTimesProblem { a: number; b: number; c: number; d: number }

export function createFracTimes(a: number, b: number, c: number, d: number): FracTimesProblem {
  if (![a, b, c, d].every(v => Number.isInteger(v) && v > 0)) throw new Error("whole numbers only");
  if (a >= b || c >= d) throw new Error("both fractions are less than one");
  return { a, b, c, d };
}

/** Same as the current app: bottoms 2–9, each top a number below its bottom that shares no factor with it. */
export function generateFracTimes(rng: Rng, index = 3): FracTimesProblem {
  const top = (den: number) => { let n: number; do n = rng.int(1, den - 1); while (gcd(n, den) !== 1); return n; };
  // the first three: halves to fifths
  const most = index < 3 ? 5 : 9, b = rng.int(2, most), d = rng.int(2, most);
  const a = top(b), c = top(d);
  return { a, b, c, d };
}

export function fracTimesAnswers({ a, b, c, d }: FracTimesProblem): AnswerModel {
  return {
    steps: [
      { ...ms({ id: "across", label: "Multiply straight across", prompt: s => [frac(a, b), op("×"), frac(c, d), op("="), frac([s.n!], [s.d!])], ans: { n: a * c, d: b * d },
        hint: "Top times top counts the squares in the overlap. Bottom times bottom counts all the squares.",
        wrong: [[{ n: a * d, d: b * c }, "Flipped like dividing", "Flipping is only for dividing. To multiply, go straight across."], [{ n: a + c, d: b + d }, "Added instead of multiplied", "Multiply top × top and bottom × bottom."]] }),
        explain: `${a} × ${c} = ${a * c} on top and ${b} × ${d} = ${b * d} on the bottom: ${a * c}/${b * d}.` },
      simplifyStep(a * c, b * d, "Simplify"),
    ],
    finalParts: [-1],
  };
}

export function explainFracTimes(p: FracTimesProblem, answers: AnswerModel): Explanation {
  const { a, b, c, d } = p;
  const N = expectedOf(answers.steps, "across", "n"), D = expectedOf(answers.steps, "across", "d");
  const F = finalForm(N, D), simple = F.num === 0 ? String(F.whole) : `${F.whole ? `${F.whole} ` : ""}${F.num}/${F.den}`;
  const simplified = !(F.den === D && F.num === N);
  const simplifyResult = answers.steps[1]!.slots.find(s => s.expected != null)!.expected!;
  return {
    heading: "Top times top, bottom times bottom",
    idea: ["Taking a fraction of a fraction cuts the pieces smaller: half of a third is a sixth.", "On the grid, top × top counts the overlap squares and bottom × bottom counts all the squares."],
    statement: [frac(a, b), op("×"), frac(c, d)],
    diagram: buildFracGrid({
      rows: b, cols: d, r: a, c,
      beats: { grid: 0, rows: 1, cols: 2, both: 3 },
      rowLabel: `${a}/${b}`, colLabel: `${c}/${d}`,
      notes: [
        { text: `${a} of ${count(b, "row")}`, from: 1, until: 1, cls: "lbl" },
        { text: `${c} of ${count(d, "column")}`, from: 2, until: 2, cls: "lbl acc" },
        { text: `${N} of ${count(D, "square")}`, from: 3, until: 3, cls: "lbl" },
        { text: simplified ? `${N}/${D} = ${simple}` : `${N}/${D} is already simplest`, from: 4, cls: "lbl acc" },
      ],
      alt: `A grid of ${count(b, "row")} and ${count(d, "column")}: ${count(a, "row")} and ${count(c, "column")} shaded overlap in ${N} of ${count(D, "square")}.`,
    }),
    caption: `${a}/${b} of the rows and ${c}/${d} of the columns overlap in ${N} of ${count(D, "square")}.`,
    timeline: beats(5),
    steps: [
      { id: "rows", narration: `Cut the whole into ${count(b, "row")} and shade ${a} of them: ${a}/${b}.`, math: [frac(a, b)], state: 1 },
      { id: "cols", narration: `Cut it into ${count(d, "column")} too and shade ${c} of them: ${c}/${d} of that part.`, math: [frac(c, d), op("×"), frac(a, b)], state: 2 },
      { id: "across", narration: `The overlap is ${a} × ${c} = ${N} of the ${b} × ${d} = ${count(D, "square")}.`, math: [frac(a, b), op("×"), frac(c, d), op("="), frac(N, D)], state: 3, answerStep: "across", result: N },
      { id: "simplify", narration: simplified ? `Divide top and bottom by ${gcd(N, D)}: ${simple}.` : `${N}/${D} can't be simplified.`, math: [frac(N, D), op("="), ...(F.num === 0 ? [answer("x", F.whole)] : [frac([answer("x", F.num)], [answer("x", F.den)])])], state: 4, answerStep: "simplify", result: simplifyResult },
    ],
  };
}

export const lesson: LessonDefinition<FracTimesProblem> = {
  id: "g5-multfrac",
  grade: 5,
  unit: "Fractions",
  title: "Multiplying fractions",
  pre: "g4-fracwhole",
  reference: createFracTimes(2, 3, 3, 4),
  generate: (rng, index) => generateFracTimes(rng, index),
  restore: raw => { const r = readNumbers(raw, ["a", "b", "c", "d"] as const); try { return r && createFracTimes(r.a, r.b, r.c, r.d); } catch { return null; } },
  display: p => [frac(p.a, p.b), op("×"), frac(p.c, p.d)],
  answers: fracTimesAnswers,
  explain: explainFracTimes,
  story: ({ a, b, c, d }) => ({ op: "×", text: `${c}/${d} of a garden is vegetables. ${a}/${b} of the vegetable part is carrots. What part of the whole garden is carrots?` }),
};
