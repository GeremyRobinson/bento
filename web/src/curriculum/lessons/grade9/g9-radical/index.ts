import { formatNumber as f, m, mark, num, op, sqrt, sup, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { ms, ns } from "../../algebra-kit/steps";
import { attempt, readInts, rule } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { withEasyStart } from "../../easy-start";

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
      ns({ id: "square", l: "Biggest perfect square", a: s => [num(n), op("="), ...s, op("×"), num(rest)], ans: k * k, h: `Which perfect square, a whole number times itself, times ${f(rest)} makes ${f(n)}?`,
        w: [[n / rest / 2, "Halved instead", `${f(n)} ÷ ${f(rest)} is the square: ${f(rest)} times it makes ${f(n)}.`]] }),
      ns({ id: "root", l: "Its square root", a: s => [sqrt(k * k), op("="), ...s], ans: k, h: `Which whole number times itself makes ${f(k * k)}?`, w: [[k * k / 2, "Halved it", `The root is the number that times itself makes ${f(k * k)}, not half of it.`]] }),
      ms({ id: "simple", l: "Write it simply", a: S => [sqrt(n), op("="), ...S.c!, sqrt(S.r!)], ans: { c: k, r: rest }, h: `√(${f(k * k)} × ${f(rest)}) = √${f(k * k)} × √${f(rest)}. Which part is a whole number?`,
        w: [[{ c: k * k, r: rest }, "The square came out", `The square itself doesn't come out, its root does: √${f(k * k)} = ${f(k)}.`], [{ c: k, r: n }, "Left it all inside", `Once ${f(k)} is outside, only ${f(rest)} stays under the root.`]] }),
    ],
    finalParts: [-1],
  };
}

export function explainSimplifyRoot(p: SimplifyRoot, model: AnswerModel) {
  const { m: rest, n } = p;
  const [square, k] = model.steps.map(s => s.slots[0]!.expected!) as [number, number];
  return beatExplanation({
    heading: "Pull out the perfect square",
    idea: ["A square root splits over a product: √(a × b) = √a × √b. When one factor is a perfect square, its root is a whole number and moves out front.", "Use the biggest perfect square, so nothing more can come out."],
    statement: [sqrt(n)],
    caption: `${f(n)} = ${f(square)} × ${f(rest)}, and √${f(square)} = ${f(k)}.`,
    alt: `√${f(n)} = √(${f(square)} × ${f(rest)}) = ${f(k)}√${f(rest)}.`,
    steps: [
      { id: "start", narration: `Look for the biggest perfect square that divides ${f(n)}.`, math: [sqrt(n)] },
      { id: "square", narration: `${f(n)} = ${f(square)} × ${f(rest)}, and ${f(square)} is a perfect square.`, math: m(n, op("="), square, op("×"), rest), line: [sqrt([text("("), mark(square), op("×"), num(rest), text(")")])], answerStep: "square", result: square },
      { id: "root", narration: `√${f(square)} = ${f(k)}, because ${f(k)} × ${f(k)} = ${f(square)}.`, math: m(sqrt(square), op("="), k), line: [sqrt(square), op("×"), sqrt(rest)], answerStep: "root", result: k },
      { id: "simple", narration: `${f(k)} comes out, and ${f(rest)} stays under the root: ${f(k)}√${f(rest)}.`, math: [sqrt(n), op("="), num(k), sqrt(rest)], line: [mark(k), sqrt(rest)], answerStep: "simple", result: k },
      { id: "check", narration: `Check: (${f(k)}√${f(rest)})² = ${f(square)} × ${f(rest)} = ${f(n)}.`, math: [text("("), num(k), sqrt(rest), text(")"), sup(2), op("="), num(square), op("×"), num(rest), op("="), num(n)], line: null },
    ],
  });
}

export const lesson: LessonDefinition<SimplifyRoot> = withEasyStart({
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
});
