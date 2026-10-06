import { frac, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildRightTriangle, type Side } from "../../../../explanations/diagrams/right-triangle/build";
import { asRecord, expected, fracText, fs, mt, ns, numberField, TRIPLES } from "../../_geometry/kit";
import { withEasyStart } from "../../easy-start";

export type TrigFunction = "sin" | "cos" | "tan";
/** Right triangle: side a is opposite angle A, side b is next to it, c is the hypotenuse. */
export interface TrigRatioProblem {
  kind: "geometry.trigRatio";
  a: number;
  b: number;
  c: number;
  f: TrigFunction;
}

export function createTrigRatio(a: number, b: number, c: number, f: string): TrigRatioProblem {
  if (f !== "sin" && f !== "cos" && f !== "tan") throw new Error(`unknown function ${f}`);
  if (![a, b, c].every(v => v > 0) || Math.abs(a * a + b * b - c * c) > 1e-9) throw new Error("not a right triangle");
  return { kind: "geometry.trigRatio", a, b, c, f };
}

export function restoreTrigRatio(raw: unknown): TrigRatioProblem | null {
  const r = asRecord(raw);
  const a = r && numberField(r, "a"), b = r && numberField(r, "b"), c = r && numberField(r, "c");
  if (a == null || b == null || c == null || typeof r!.f !== "string") return null;
  try { return createTrigRatio(a, b, c, r!.f); } catch { return null; }
}

const sides = (p: TrigRatioProblem) => ({ top: p.f === "cos" ? p.b : p.a, bot: p.f === "tan" ? p.b : p.c });

export function trigRatioAnswers(p: TrigRatioProblem): AnswerModel {
  const { a, b, f } = p, { top, bot } = sides(p);
  return {
    steps: [
      ns({ id: "top", label: "Top of the ratio", question: f === "cos" ? "Cosine uses the adjacent side on top. Which side is that?" : "Which side is opposite angle A?",
        prompt: s => [s], ans: top, hint: "SOH CAH TOA: sin = opposite/hyp, cos = adjacent/hyp, tan = opposite/adjacent.",
        wrong: [[f === "cos" ? a : b, "Mixed up opposite and adjacent", "Opposite is across from the angle. Adjacent is next to it (not the hypotenuse)."]] }),
      ns({ id: "bottom", label: "Bottom of the ratio", question: f === "tan" ? "Tangent uses the adjacent side on the bottom. Which side?" : "Which side is the hypotenuse?",
        prompt: s => [s], ans: bot, hint: f === "tan" ? "Tangent is opposite over adjacent, so the adjacent side goes on the bottom: the side next to A that isn't the hypotenuse." : "The hypotenuse is the longest side, across from the square corner.",
        wrong: [[top, "Same side twice", "The bottom of the ratio is a different side from the top."]] }),
      fs({ id: "ratio", label: "Write the ratio", prompt: s => mt`${f} A = ${s}`, N: top, D: bot, hint: "The side you found for the top goes over the side you found for the bottom. Then divide both by any common factor.",
        wrong: [[bot, top, "Upside down", "Put the top side over the bottom side, not the other way."]] }),
    ],
    finalParts: [-1],
  };
}

const NAME: Record<TrigFunction, [string, string]> = { sin: ["opposite", "hypotenuse"], cos: ["adjacent", "hypotenuse"], tan: ["opposite", "adjacent"] };

export function explainTrigRatio(p: TrigRatioProblem, answers: AnswerModel): Explanation {
  const { a, b, c, f } = p;
  const top = expected(answers, "top"), bot = expected(answers, "bottom");
  const n = expected(answers, "ratio", "n"), d = expected(answers, "ratio", "d");
  const [topName, botName] = NAME[f];
  const sideOf = (name: string): Side => (name === "opposite" ? "a" : name === "adjacent" ? "b" : "c");
  return {
    heading: "SOH CAH TOA",
    idea: ["sin = opposite ÷ hypotenuse. cos = adjacent ÷ hypotenuse. tan = opposite ÷ adjacent.", "Opposite is across from the angle; adjacent is next to it."],
    statement: mt`${f} A = ${text(topName)} ÷ ${text(botName)}`,
    caption: `From angle A: opposite ${a}, adjacent ${b}, hypotenuse ${c}.`,
    diagram: buildRightTriangle({
      a, b,
      sides: { a: { text: `opposite ${a}` }, b: { text: `adjacent ${b}` }, c: { text: `hypotenuse ${c}` } },
      angles: [{ at: "B", text: "A" }],
      hl: [{ side: sideOf(topName), from: 1 }, { side: sideOf(botName), from: 2 }],
      alt: `A right triangle with angle A: the side opposite A is ${a}, the side next to it is ${b}, and the hypotenuse is ${c}.`,
    }),
    timeline: beats(4),
    steps: [
      { id: "triangle", narration: `Stand at angle A. Side ${a} is across from it, side ${b} runs next to it, and ${c} is the hypotenuse.`, math: mt`${f} A = ${text(topName)} ÷ ${text(botName)}`, state: 0 },
      { id: "top", narration: `${f} uses the ${topName} side on top: ${top}.`, math: mt`${text(topName)} = ${top}`, state: 1, answerStep: "top", result: top },
      { id: "bottom", narration: `On the bottom goes the ${botName}: ${bot}.`, math: mt`${text(botName)} = ${bot}`, state: 2, answerStep: "bottom", result: bot },
      { id: "ratio", narration: `So ${f} A = ${top}/${bot}${n === top ? `. ${top} and ${bot} share no factor, so it is already in lowest terms` : `, which simplifies to ${fracText(n, d)}`}.`,
        math: n === top ? mt`${f} A = ${frac(top, bot)}` : mt`${f} A = ${frac(top, bot)} = ${frac(n, d)}`, state: 3, answerStep: "ratio", result: n },
    ],
  };
}

export const lesson: LessonDefinition<TrigRatioProblem> = withEasyStart({
  id: "g10-trig",
  grade: 10,
  unit: "Right triangles and trig",
  title: "Sine, cosine and tangent",
  reference: createTrigRatio(3, 4, 5, "sin"),
  generate: rng => { const [a, b, c] = rng.pick(TRIPLES); return createTrigRatio(a, b, c, rng.pick(["sin", "cos", "tan"] as const)); },
  restore: restoreTrigRatio,
  display: p => mt`${p.f} A`,
  displayNote: p => `Right triangle: side ${p.a} is opposite angle A, side ${p.b} is next to it, hypotenuse ${p.c}.`,
  answers: trigRatioAnswers,
  explain: explainTrigRatio,
});
