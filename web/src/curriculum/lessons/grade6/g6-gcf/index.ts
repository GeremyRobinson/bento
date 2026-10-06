import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildAreaGrid } from "../../../../explanations/diagrams/area-model/grid";
import { expectedOf, gcd, ms, ns, readNumbers, type Wrong } from "../../area-common/steps";
import { count } from "../../../text";

/** g·m + g·n, where m and n share no factor, so g is the greatest common factor. */
export interface GcfProblem { g: number; m: number; n: number }

export function createGcf(g: number, m: number, n: number): GcfProblem {
  if (![g, m, n].every(v => Number.isInteger(v) && v > 0)) throw new Error("whole numbers only");
  if (gcd(m, n) !== 1) throw new Error("m and n must share no factor");
  return { g, m, n };
}

/** Same as the current app: m, n 1–9, different and sharing no factor; g 2–9. */
export function generateGcf(rng: Rng, index = 3): GcfProblem {
  // the first three: small shared factors and small numbers left inside
  const top = index < 3 ? 5 : 9;
  let m: number, n: number;
  do { m = rng.int(1, top); n = rng.int(1, top); } while (m === n || gcd(m, n) !== 1);
  return { g: rng.int(2, index < 3 ? 5 : 9), m, n };
}

export function gcfAnswers({ g, m, n }: GcfProblem): AnswerModel {
  const A = g * m, B = g * n;
  const smaller: Wrong[] = [];
  for (let f = 2; f < g; f++) if (g % f === 0) smaller.push([f, "Common factor, but not the greatest", `${f} works, but there's a bigger one.`]);
  return {
    steps: [
      ns({ id: "gcf", label: "Greatest common factor", prompt: x => [text("GCF("), num(A), text(", "), num(B), text(")"), op("="), x], ans: g,
        hint: "Try the factors of the smaller number, biggest first. Stop at the first one that also divides the other number.",
        wrong: [...smaller, [1, "Settled for 1", "1 divides every number. Look for a bigger number that divides both."]] }),
      { ...ms({ id: "factor", label: "Factor it out", prompt: s => [num(A), op("+"), num(B), op("="), num(g), text("("), s.m!, op("+"), s.n!, text(")")], ans: { m, n },
        hint: "Divide each number by the factor you pulled out.",
        wrong: [[{ m: A, n: B }, "Left the numbers whole", `Inside goes what's left after taking out ${g}: divide each number by ${g}.`], [{ m: A - g, n: B - g }, "Subtracted the factor", `Factoring out ${g} divides by it: ${A} ÷ ${g} and ${B} ÷ ${g}.`]] }),
        explain: `${A} ÷ ${g} = ${m} and ${B} ÷ ${g} = ${n}, so ${A} + ${B} = ${g}(${m} + ${n}).` },
    ],
    finalParts: [-1],
  };
}

export function explainGcf(p: GcfProblem, answers: AnswerModel): Explanation {
  const { m, n } = p, g = expectedOf(answers.steps, "gcf"), A = g * m, B = g * n;
  const fm = expectedOf(answers.steps, "factor", "m"), fn = expectedOf(answers.steps, "factor", "n");
  return {
    heading: "Pull out the biggest shared factor",
    idea: ["Both numbers are the same factor times something, so that shared factor can be written once outside the parentheses.", "The greatest common factor leaves nothing more to pull out."],
    statement: [num(A), op("+"), num(B), op("="), num(g), text("("), num(fm), op("+"), num(fn), text(")")],
    diagram: buildAreaGrid({
      cols: [{ label: String(fm), size: m, from: 2 }, { label: String(fn), size: n, from: 2 }],
      rows: [{ label: String(g), size: g, from: 1, cls: "acc" }],
      cells: [[{ text: String(A) }, { text: String(B) }]],
      units: 1,
      lines: [{ text: `${A} + ${B} = ${g}(${fm} + ${fn})`, from: 2 }],
      alt: `Two rectangles of ${A} and ${count(B, "square")} with the same height ${g}: ${g} by ${fm} and ${g} by ${fn}.`,
    }),
    caption: `${A} and ${B} are both ${count(g, "row")} tall: ${count(g, "row")} of ${fm} and ${count(g, "row")} of ${fn}.`,
    timeline: beats(3),
    steps: [
      { id: "gcf", narration: `${g} is the biggest number that divides both ${A} and ${B}.`, math: [text("GCF("), num(A), text(", "), num(B), text(")"), op("="), num(g)], state: 1, answerStep: "gcf", result: g },
      { id: "factor", narration: `${A} ÷ ${g} = ${fm} and ${B} ÷ ${g} = ${fn}, so ${A} + ${B} = ${g}(${fm} + ${fn}).`, math: [num(A), op("+"), num(B), op("="), num(g), text("("), num(fm), op("+"), num(fn), text(")")], state: 2, answerStep: "factor", result: fm },
    ],
  };
}

export const lesson: LessonDefinition<GcfProblem> = {
  id: "g6-gcf",
  grade: 6,
  unit: "Number system",
  title: "Factor out the GCF",
  reference: createGcf(12, 2, 3),
  generate: (rng, index) => generateGcf(rng, index),
  restore: raw => { const r = readNumbers(raw, ["g", "m", "n"] as const); try { return r && createGcf(r.g, r.m, r.n); } catch { return null; } },
  display: p => [num(p.g * p.m), op("+"), num(p.g * p.n)],
  displayNote: () => "Factor out the greatest common factor.",
  answers: gcfAnswers,
  explain: explainGcf,
};
