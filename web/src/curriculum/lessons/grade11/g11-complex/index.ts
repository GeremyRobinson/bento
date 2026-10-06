import { formatNumber as f, num, op, sup, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildAreaGrid } from "../../../../explanations/diagrams/area-model/grid";
import { expectedOf, nonZero, ns, numP, readNumbers } from "../../area-common/steps";
import { withEasyStart } from "../../easy-start";

/** (a + bi)(c + di), every part a nonzero whole number. */
export interface ComplexProblem { a: number; b: number; c: number; d: number }

export function createComplex(a: number, b: number, c: number, d: number): ComplexProblem {
  if (![a, b, c, d].every(v => Number.isInteger(v) && v !== 0)) throw new Error("nonzero whole numbers only");
  return { a, b, c, d };
}

/** Same as the current app: each part from −6 to 6, never 0. */
export const generateComplex = (rng: Rng): ComplexProblem => ({ a: nonZero(rng, -6, 6), b: nonZero(rng, -6, 6), c: nonZero(rng, -6, 6), d: nonZero(rng, -6, 6) });

const i = text("i");
/** b·i as math, with 1i written i and −1i written −i */
const iTerm = (b: number): MathText => (Math.abs(b) === 1 ? [text(b < 0 ? "−i" : "i")] : [num(b), i]);
/** the same in parentheses when negative, for a second factor */
const iTermP = (b: number): MathText => (b < 0 ? [text("("), ...iTerm(b), text(")")] : iTerm(b));
const factor = (re: number, im: number): MathText => [text("("), num(re), op(im < 0 ? "−" : "+"), ...iTerm(Math.abs(im)), text(")")];
const show = ({ a, b, c, d }: ComplexProblem): MathText => [...factor(a, b), ...factor(c, d)];
/** "1i" is written "i", and "−1i" is "−i". */
const oneI = (t: string) => t.replace(/(^|[^\d.])1i(?![\d])/g, (_m, pre: string) => `${pre}i`);
const complexText = (re: number, im: number) => oneI(`${f(re)} ${im < 0 ? "−" : "+"} ${Math.abs(im)}i`);
const signed = (v: number, unit: string) => `${v < 0 ? "−" : "+"}${Math.abs(v)}${unit}`;

export function complexAnswers({ a, b, c, d }: ComplexProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "first", label: "First × first", prompt: s => [num(a), op("·"), ...numP(c), op("="), s], ans: a * c, hint: "First × first is the two plain numbers multiplied.", wrong: [[a + c, "Added", "Multiply the two real parts."]] }),
      ns({ id: "last", label: "Last × last", prompt: s => [...iTerm(b), op("·"), ...iTermP(d), op("="), ...iTerm(b * d), sup(2), op("="), s], ans: -b * d, hint: "i² = −1, so flip the sign.",
        wrong: [[b * d, "Forgot i² = −1", "i × i = −1, so the sign flips."]] }),
      ns({ id: "real", label: "Real part", prompt: s => [num(a * c), op("+"), ...numP(-b * d), op("="), s], ans: a * c - b * d, hint: "The real part is every plain number together: add them.", wrong: [[a * c + b * d, "Kept i² as +1", "i² is −1, so the corner is the opposite sign."]] }),
      ns({ id: "imag", label: "Imaginary part", note: "These are the i terms.", prompt: s => [num(a), op("·"), ...numP(d), op("+"), ...numP(b), op("·"), ...numP(c), op("="), s], ans: a * d + b * c,
        hint: "Outer and inner both have one i: multiply each pair, then add them.", wrong: [[a * d - b * c, "Subtracted", "Outer and inner are both i terms side by side: add them."]] }),
    ],
    finalParts: [-2, -1],
  };
}

export function explainComplex(p: ComplexProblem, answers: AnswerModel): Explanation {
  const { a, b, c, d } = p;
  const ac = expectedOf(answers.steps, "first"), last = expectedOf(answers.steps, "last"), re = expectedOf(answers.steps, "real"), im = expectedOf(answers.steps, "imag");
  return {
    heading: "FOIL, then i² = −1",
    idea: ["Multiply every part by every part, like two binomials. Then turn i² into −1 and gather the plain numbers and the i terms."],
    statement: show(p),
    diagram: buildAreaGrid({
      cols: [{ label: f(c), size: Math.abs(c) }, { label: oneI(signed(d, "i")), size: Math.abs(d) }],
      rows: [{ label: f(a), size: Math.abs(a) }, { label: oneI(signed(b, "i")), size: Math.abs(b) }],
      cells: [
        [{ text: f(ac), from: 1, focus: [1, 3] }, { text: oneI(`${f(a * d)}i`), from: 4, focus: [4] }],
        [{ text: oneI(`${f(b * c)}i`), from: 4, focus: [4] }, { text: oneI(`${f(b * d)}i² = ${f(last)}`), from: 2, focus: [2, 3] }],
      ],
      lines: [
        { text: `real: ${f(ac)} + ${f(last)} = ${f(re)}`.replace("+ −", "− "), from: 3, until: 3 },
        { text: oneI(`i terms: ${f(a * d)}i + ${f(b * c)}i = ${f(im)}i`.replace("+ −", "− ")), from: 4, until: 4, cls: "lbl" },
        // its own sentence, so it doesn't read as "−56i = 6 − 56i"
        { text: `product: ${complexText(re, im)}`, from: 4 },
      ],
      alt: `(${complexText(a, b)}) times (${complexText(c, d)}) as an area: ${f(ac)}, ${oneI(`${f(a * d)}i`)}, ${oneI(`${f(b * c)}i`)} and ${oneI(`${f(b * d)}i²`)} = ${f(last)}. The product is ${complexText(re, im)}.`,
    }),
    caption: `${oneI(`${f(b * d)}i²`)} = ${f(last)}, so the corner joins the plain numbers: ${complexText(re, im)}.`,
    timeline: beats(5),
    steps: [
      { id: "first", narration: `First × first: ${f(a)} · ${f(c)} = ${f(ac)}.`, math: [num(a), op("·"), ...numP(c), op("="), num(ac)], state: 1, answerStep: "first", result: ac },
      { id: "last", narration: `Last × last: ${oneI(`${f(b)}i`)} · ${d < 0 ? `(${oneI(`${f(d)}i`)})` : oneI(`${f(d)}i`)} = ${oneI(`${f(b * d)}i²`)}, and i² = −1, so it's ${f(last)}.`, math: [...iTerm(b), op("·"), ...iTermP(d), op("="), ...iTerm(b * d), sup(2), op("="), num(last)], state: 2, answerStep: "last", result: last },
      { id: "real", narration: `The plain numbers make the real part: ${f(re)}.`, math: [num(ac), op("+"), ...numP(last), op("="), num(re)], state: 3, answerStep: "real", result: re },
      { id: "imag", narration: `Outer and inner are the i terms: ${oneI(`${f(im)}i`)}. So the product is ${complexText(re, im)}.`, math: [num(a), op("·"), ...numP(d), op("+"), ...numP(b), op("·"), ...numP(c), op("="), num(im)], state: 4, answerStep: "imag", result: im },
    ],
  };
}

export const lesson: LessonDefinition<ComplexProblem> = withEasyStart({
  id: "g11-complex",
  grade: 11,
  unit: "Complex numbers",
  title: "Multiplying complex numbers",
  reference: createComplex(2, 3, 1, 4),
  generate: rng => generateComplex(rng),
  restore: raw => { const r = readNumbers(raw, ["a", "b", "c", "d"] as const); try { return r && createComplex(r.a, r.b, r.c, r.d); } catch { return null; } },
  display: show,
  answers: complexAnswers,
  explain: explainComplex,
});
