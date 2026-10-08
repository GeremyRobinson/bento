import { num, op, sup, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildAreaGrid } from "../../../../explanations/diagrams/area-model/grid";
import { expectedOf, gcd, ms, ns, polyText, readNumbers } from "../../area-common/steps";
import { withEasyStart } from "../../easy-start";

/** g·m x² + g·n x = gx(mx + n), with m and n sharing no factor. */
export interface PolyGcfProblem { g: number; m: number; n: number }

export function createPolyGcf(g: number, m: number, n: number): PolyGcfProblem {
  if (![g, m, n].every(v => Number.isInteger(v) && v > 0)) throw new Error("whole numbers only");
  if (gcd(m, n) !== 1) throw new Error("m and n must share no factor");
  return { g, m, n };
}

/** Same as the current app: m, n 1–7 sharing no factor; g 2–6. */
export function generatePolyGcf(rng: Rng): PolyGcfProblem {
  let m: number, n: number;
  do { m = rng.int(1, 7); n = rng.int(1, 7); } while (gcd(m, n) !== 1);
  return { g: rng.int(2, 6), m, n };
}

const x = text("x");
const show = ({ g, m, n }: PolyGcfProblem): MathText => [num(g * m), x, sup(2), op("+"), num(g * n), x];

export function polyGcfAnswers(p: PolyGcfProblem): AnswerModel {
  const { g, m, n } = p;
  // the biggest common factor below g, a learner's usual near miss (none when g is prime)
  let smaller = g - 1;
  while (smaller > 1 && g % smaller) smaller--;
  return {
    steps: [
      ns({ id: "number", label: "Number part", question: `What's the biggest number that divides ${g * m} and ${g * n}?`, prompt: s => [s], ans: g, hint: "Find the greatest common factor of the numbers.", wrong: smaller < 2 ? [] : [[smaller, "Not the biggest", `${smaller} divides both, but a bigger number does too.`]] }),
      ms({ id: "factor", label: "Factor it out", note: "Both terms have an x, so take out an x too.", prompt: s => [...show(p), op("="), num(g), x, text("("), s.m!, x, op("+"), s.n!, text(")")], ans: { m, n },
        hint: `Divide each term by ${g}x: what times ${g}x makes ${g * m}x², and what times ${g}x makes ${g * n}x?`,
        wrong: [[{ m: g * m, n: g * n }, "Didn't divide", `Take ${g}x out of each term: divide each by ${g}x.`], [{ m: m, n: n * g }, "Divided only the first term", `Both terms share the ${g}x, so divide both by it.`]] }),
    ],
    finalParts: [-1],
  };
}

export function explainPolyGcf(p: PolyGcfProblem, answers: AnswerModel): Explanation {
  const g = expectedOf(answers.steps, "number"), m = expectedOf(answers.steps, "factor", "m"), n = expectedOf(answers.steps, "factor", "n");
  const X = 3; // x drawn 3 units long, so every piece is to scale with the others
  const factored = `${g}x(${polyText([[m, "x"]])} + ${n})`;
  return {
    heading: "Take out what they share",
    idea: ["What every term shares can be written once, outside the parentheses."],
    statement: show(p),
    diagram: buildAreaGrid({
      cols: [{ label: polyText([[m, "x"]]), size: m * X, from: 2 }, { label: String(n), size: n, from: 2 }],
      rows: [{ label: `${g}x`, size: g * X, from: 2, cls: "acc" }],
      cells: [[{ text: `${g * m}x`, sup: "2" }, { text: `${g * n}x` }]],
      lines: [
        { text: `${g * m} and ${g * n} both divide by ${g}`, from: 1, until: 1, cls: "lbl" },
        { text: `${g * m}x² + ${g * n}x = ${factored}`, from: 2 },
      ],
      alt: `${g * m}x² and ${g * n}x side by side, both ${g}x tall: ${g}x by ${polyText([[m, "x"]])} and ${g}x by ${n}.`,
    }),
    caption: `Both terms are ${g}x tall, so ${g}x comes out: ${factored}.`,
    timeline: beats(3),
    steps: [
      { id: "number", narration: `${g} is the biggest number that divides ${g * m} and ${g * n}.`, math: [num(g * m), op("÷"), num(g), op("="), num(m), text(",  "), num(g * n), op("÷"), num(g), op("="), num(n)], state: 1, answerStep: "number", result: g },
      { id: "factor", narration: `Both terms have an x too, so take out ${g}x: ${factored}.`, math: [...show(p), op("="), text(factored)], state: 2, answerStep: "factor", result: m },
    ],
  };
}

export const lesson: LessonDefinition<PolyGcfProblem> = withEasyStart({
  id: "g9-gcf",
  grade: 9,
  unit: "Polynomials and quadratics",
  title: "Factor out the GCF",
  reference: createPolyGcf(3, 2, 3),
  generate: rng => generatePolyGcf(rng),
  restore: raw => { const r = readNumbers(raw, ["g", "m", "n"] as const); try { return r && createPolyGcf(r.g, r.m, r.n); } catch { return null; } },
  display: show,
  answers: polyGcfAnswers,
  explain: explainPolyGcf,
});
