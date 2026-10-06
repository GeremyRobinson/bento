import { formatNumber as f, m, mark, num, op, sqrt, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { ms, ns } from "../../algebra-kit/steps";
import { attempt, readInts, rule } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { simplifyRootPicture } from "./picture";

/** The square-free parts the current app uses, so k² is always the biggest perfect square inside. */
export const SQUARE_FREE = [2, 3, 5, 6, 7] as const;

/** √(k²·m) = k√m. */
export interface SimplifyRoot { kind: "roots.simplify"; k: number; m: number; n: number }

export function createSimplifyRoot(k: number, m: number): SimplifyRoot {
  rule(k >= 2 && (SQUARE_FREE as readonly number[]).includes(m), "k ≥ 2 and m square-free");
  return { kind: "roots.simplify", k, m, n: k * k * m };
}

/** Same ranges as the current app: k 2–6, m one of 2, 3, 5, 6, 7. */
export const generateSimplifyRoot = (rng: Rng) => { const k = rng.int(2, 6), m = rng.pick(SQUARE_FREE); return createSimplifyRoot(k, m); };

export function restoreSimplifyRoot(raw: unknown): SimplifyRoot | null {
  const r = readInts(raw, ["k", "m"] as const);
  return r && attempt(() => createSimplifyRoot(r.k, r.m));
}

export function simplifyRootAnswers({ k, m: rest, n }: SimplifyRoot): AnswerModel {
  return {
    steps: [
      ns({ id: "square", l: "Biggest perfect square", a: s => [num(n), op("="), ...s, op("×"), num(rest)], ans: k * k, h: `Look for 4, 9, 16, 25, 36 that divide ${f(n)}.` }),
      ns({ id: "root", l: "Its square root", a: s => [sqrt(k * k), op("="), ...s], ans: k, h: `${f(k)} × ${f(k)} = ${f(k * k)}.` }),
      ms({ id: "simple", l: "Write it simply", a: S => [sqrt(n), op("="), ...S.c!, sqrt(S.r!)], ans: { c: k, r: rest }, h: `${f(k)} comes out, ${f(rest)} stays inside.` }),
    ],
    finalParts: [-1],
  };
}

export function explainSimplifyRoot(p: SimplifyRoot, model: AnswerModel) {
  const { m: rest, n } = p;
  const [square, k] = model.steps.map(s => s.slots[0]!.expected!) as [number, number];
  return beatExplanation({
    heading: "Pull out the perfect square",
    statement: [sqrt(n)],
    caption: `${f(n)} = ${f(square)} × ${f(rest)}, and √${f(square)} = ${f(k)}.`,
    diagram: simplifyRootPicture({ k, m: rest, n, square }),
    alt: `√${f(n)} = √(${f(square)} × ${f(rest)}) = ${f(k)}√${f(rest)}.`,
    steps: [
      { id: "start", narration: `Look for the biggest perfect square that divides ${f(n)}.`, math: [sqrt(n)] },
      { id: "square", narration: `${f(n)} = ${f(square)} × ${f(rest)}, and ${f(square)} is a perfect square.`, math: m(n, op("="), square, op("×"), rest), line: [sqrt([text("("), mark(square), op("×"), num(rest), text(")")])], answerStep: "square", result: square },
      { id: "root", narration: `√${f(square)} = ${f(k)}, because ${f(k)} × ${f(k)} = ${f(square)}.`, math: m(sqrt(square), op("="), k), line: [sqrt(square), op("×"), sqrt(rest)], answerStep: "root", result: k },
      { id: "simple", narration: `${f(k)} comes out, and ${f(rest)} stays under the root: ${f(k)}√${f(rest)}.`, math: [sqrt(n), op("="), num(k), sqrt(rest)], line: [mark(k), sqrt(rest)], answerStep: "simple", result: k },
    ],
  });
}

export const lesson: LessonDefinition<SimplifyRoot> = {
  id: "g9-radical",
  grade: 9,
  unit: "Exponents",
  title: "Simplify square roots",
  reference: createSimplifyRoot(6, 2),
  generate: rng => generateSimplifyRoot(rng),
  restore: restoreSimplifyRoot,
  display: p => [sqrt(p.n)],
  answers: simplifyRootAnswers,
  explain: explainSimplifyRoot,
};
