import { formatNumber as f } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildSimilar } from "../../../../explanations/diagrams/similar/build";
import { asRecord, expected, mt, ns, numberField, round6 } from "../../_geometry/kit";
import { withEasyStart } from "../../easy-start";

/** A small triangle with sides a and b; the similar big one is k times bigger. */
export interface SimilarProblem {
  kind: "geometry.similar";
  a: number;
  b: number;
  k: number;
}

export const SCALE_FACTORS = [2, 3, 4, 1.5, 2.5] as const;

export function createSimilar(a: number, b: number, k: number): SimilarProblem {
  if (!(a > 0 && b > 0 && k > 0)) throw new Error("sides and factor must be positive");
  return { kind: "geometry.similar", a, b, k };
}

export function restoreSimilar(raw: unknown): SimilarProblem | null {
  const r = asRecord(raw), a = r && numberField(r, "a"), b = r && numberField(r, "b"), k = r && numberField(r, "k");
  if (a == null || b == null || k == null) return null;
  try { return createSimilar(a, b, k); } catch { return null; }
}

export function similarAnswers({ a, b, k }: SimilarProblem): AnswerModel {
  const big = round6(a * k);
  return {
    steps: [
      ns({ id: "factor", label: "Scale factor", prompt: s => mt`${big} ÷ ${a} = ${s}`, ans: k, hint: "Big side ÷ matching small side.",
        wrong: [[round6(a / (a * k)), "Divided the wrong way", "Big ÷ small, so the factor is more than 1."]] }),
      ns({ id: "missing", label: "Missing side", prompt: s => mt`${b} × ${k} = ${s}`, ans: round6(b * k), hint: "Multiply the matching small side by the scale factor.",
        wrong: [[b + a * k - a, "Added instead of multiplied", "Similar shapes scale by multiplying."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainSimilar(p: SimilarProblem, answers: AnswerModel): Explanation {
  const { a, b } = p, big = round6(a * p.k);
  const k = expected(answers, "factor"), side = expected(answers, "missing");
  return {
    heading: "Same shape, scaled",
    idea: ["Similar shapes have the same angles, and every side is scaled by the same factor."],
    statement: mt`${a} → ${big}, ${b} → ?`,
    caption: `${f(big)} ÷ ${a} = ${f(k)}, so everything is × ${f(k)}: ${b} × ${f(k)} = ${f(side)}.`,
    diagram: buildSimilar({
      a, b, k, bigA: f(big), bigB: f(side), factorBeat: 1, missingBeat: 2,
      factorNote: `× ${f(k)} everywhere`, missingNote: `${b} × ${f(k)} = ${f(side)}`,
      alt: `A small right triangle with sides ${a} and ${b}, and a similar one ${f(k)} times as big with sides ${f(big)} and ${f(side)}.`,
    }),
    timeline: beats(3),
    steps: [
      { id: "triangles", narration: `The small triangle has sides ${a} and ${b}. The big one has the same shape; its side matching ${a} is ${f(big)}.`, math: mt`${a} → ${big}`, state: 0 },
      { id: "factor", narration: `Big side ÷ matching small side: ${f(big)} ÷ ${a} = ${f(k)}. Every side is ${f(k)} times as long.`, math: mt`${big} ÷ ${a} = ${k}`, state: 1, answerStep: "factor", result: k },
      { id: "missing", narration: `So the side matching ${b} is ${b} × ${f(k)} = ${f(side)}.`, math: mt`${b} × ${k} = ${side}`, state: 2, answerStep: "missing", result: side },
    ],
  };
}

export const lesson: LessonDefinition<SimilarProblem> = withEasyStart({
  id: "g10-similar",
  grade: 10,
  unit: "Angles and triangles",
  title: "Similar triangles",
  reference: createSimilar(4, 6, 2),
  generate: rng => {
    const k = rng.pick(SCALE_FACTORS);
    let a: number, b: number;
    do { a = 2 * rng.int(2, 8); b = 2 * rng.int(2, 8); } while (a === b);
    return createSimilar(a, b, k);
  },
  restore: restoreSimilar,
  display: p => mt`small: ${p.a} and ${p.b}\nbig: ${round6(p.a * p.k)} and ?`,
  displayNote: () => "The triangles are similar. Find the missing side.",
  answers: similarAnswers,
  explain: explainSimilar,
});
