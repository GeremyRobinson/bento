import { formatNumber as f, num, op, sup, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildAreaGrid } from "../../../../explanations/diagrams/area-model/grid";
import { expectedOf, ms, nonZero, ns, numP, polyText, readNumbers } from "../../area-common/steps";
import { withEasyStart } from "../../easy-start";

/** (x + a)(x + b) with a and b nonzero (either may be negative). */
export interface FoilProblem { a: number; b: number }

export function createFoil(a: number, b: number): FoilProblem {
  if (![a, b].every(v => Number.isInteger(v) && v !== 0)) throw new Error("a and b are nonzero whole numbers");
  return { a, b };
}

/** Same as the current app: a and b from −9 to 9, never 0. */
export const generateFoil = (rng: Rng): FoilProblem => ({ a: nonZero(rng, -9, 9), b: nonZero(rng, -9, 9) });

const x = text("x");
/** (x + 3) or (x − 3), as the current app's binom */
const binom = (a: number): MathText => [text("("), x, op(a < 0 ? "−" : "+"), num(Math.abs(a)), text(")")];
/** a negative number in parentheses, as text */
const pf = (v: number) => (v < 0 ? `(${f(v)})` : f(v));
const sideText = (a: number) => (a < 0 ? `−${Math.abs(a)}` : `+${a}`);

export function foilAnswers({ a, b }: FoilProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "middle", label: "Outer + inner", prompt: s => [num(b), x, op("+"), ...numP(a), x, op("="), s, x], ans: a + b, hint: `Outer: x × ${f(b)}. Inner: ${f(a)} × x. Both are x terms, so add them.`, wrong: [[a * b, "Multiplied instead", "Outer and inner are two x terms side by side, so add them."]] }),
      ns({ id: "last", label: "Last", prompt: s => [...numP(a), op("×"), ...numP(b), op("="), s], ans: a * b, hint: "Multiply the two numbers.",
        wrong: [[a + b, "Added instead of multiplied", "The last terms multiply."]] }),
      ms({ id: "answer", label: "Write the answer", prompt: s => [x, sup(2), op("+"), s.p!, x, op("+"), s.q!], ans: { p: a + b, q: a * b }, hint: "First gives x². Then outer + inner is the x term, and last is the number on its own.",
        wrong: [[{ p: a * b, q: a + b }, "Swapped them", "Outer + inner goes with x; last × last is the number on its own."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainFoil(p: FoilProblem, answers: AnswerModel): Explanation {
  const { a, b } = p, mid = expectedOf(answers.steps, "middle"), last = expectedOf(answers.steps, "last");
  const X = Math.max(Math.abs(a), Math.abs(b)) + 3;
  const result = polyText([[1, "x²"], [mid, "x"], [last, ""]]);
  return {
    heading: "First, outer, inner, last",
    idea: ["Multiply each term of one factor by each term of the other: first, outer, inner, last. Then add the like terms."],
    statement: [...binom(a), ...binom(b)],
    diagram: buildAreaGrid({
      cols: [{ label: "x", size: X }, { label: sideText(b), size: Math.abs(b) }],
      rows: [{ label: "x", size: X }, { label: sideText(a), size: Math.abs(a) }],
      cells: [
        [{ text: "x", sup: "2" }, { text: polyText([[b, "x"]]), from: 1, focus: [1] }],
        [{ text: polyText([[a, "x"]]), from: 1, focus: [1] }, { text: f(last), from: 2, focus: [2], color: last < 0 ? 2 : 0 }],
      ],
      lines: [
        { text: `${polyText([[b, "x"]])} + ${polyText([[a, "x"]])} = ${polyText([[mid, "x"]])}`.replace("+ −", "− "), from: 1, until: 1 },
        { text: `${pf(a)} × ${pf(b)} = ${f(last)}`, from: 2, until: 2 },
        { text: result, from: 3 },
      ],
      alt: `An (x ${a < 0 ? "−" : "+"} ${Math.abs(a)}) by (x ${b < 0 ? "−" : "+"} ${Math.abs(b)}) area: x², ${polyText([[b, "x"]])}, ${polyText([[a, "x"]])} and ${f(last)}, which make ${result}.`,
    }),
    caption: `x² + ${polyText([[b, "x"]])} + ${polyText([[a, "x"]])} + ${f(last)}`.replace(/\+ −/g, "− ") + ` = ${result}`,
    timeline: beats(4),
    steps: [
      { id: "middle", narration: `Outer: x × ${f(b)}. Inner: ${f(a)} × x. Together ${polyText([[mid, "x"]])}.`, math: [num(b), x, op("+"), ...numP(a), x, op("="), num(mid), x], state: 1, answerStep: "middle", result: mid },
      { id: "last", narration: `Last: ${pf(a)} × ${pf(b)} = ${f(last)}.`, math: [...numP(a), op("×"), ...numP(b), op("="), num(last)], state: 2, answerStep: "last", result: last },
      { id: "answer", narration: `First is x². So it's ${result}.`, math: [...binom(a), ...binom(b), op("="), text(result)], state: 3, answerStep: "answer", result: mid },
    ],
  };
}

export const lesson: LessonDefinition<FoilProblem> = withEasyStart({
  id: "g9-foil",
  grade: 9,
  unit: "Polynomials and quadratics",
  title: "Multiply binomials",
  reference: createFoil(3, 4),
  generate: rng => generateFoil(rng),
  restore: raw => { const r = readNumbers(raw, ["a", "b"] as const); try { return r && createFoil(r.a, r.b); } catch { return null; } },
  display: p => [...binom(p.a), ...binom(p.b)],
  answers: foilAnswers,
  explain: explainFoil,
});
