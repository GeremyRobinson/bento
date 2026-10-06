import { formatNumber as f, frac, m, mark, num, op, sup, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { ns, supText, v, xp, type Slip } from "../../algebra-kit/steps";
import { attempt, readInts, rule } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { count as countOf } from "../../../text";
import { withEasyStart } from "../../easy-start";

/**
 * One exponent rule on powers of x: t = 0 multiplies xᵃ · xᵇ, t = 1 divides xᵃ⁺ᵇ ÷ xᵇ, t = 2 raises (xᵃ)ᵇ.
 * `exponent` is the simplified exponent.
 */
export interface ExponentRule { kind: "exponents.rule"; t: 0 | 1 | 2; a: number; b: number; exponent: number }

export function createExponentRule(t: number, a: number, b: number): ExponentRule {
  rule(t === 0 || t === 1 || t === 2, "rule 0–2");
  rule(a >= 1 && b >= 1, "positive exponents");
  return { kind: "exponents.rule", t: t as ExponentRule["t"], a, b, exponent: [a + b, a, a * b][t]! };
}

/** Same ranges as the current app: a 2–4, b 2–3. */
export const generateExponentRule = (rng: Rng) => { const t = rng.int(0, 2), a = rng.int(2, 4), b = rng.int(2, 3); return createExponentRule(t, a, b); };

export function restoreExponentRule(raw: unknown): ExponentRule | null {
  const r = readInts(raw, ["t", "a", "b"] as const);
  return r && attempt(() => createExponentRule(r.t, r.a, r.b));
}

const shown = ({ t, a, b }: ExponentRule): MathText =>
  t === 0 ? [...xp(a), op("·"), ...xp(b)] : t === 1 ? [...xp(a + b), op("÷"), ...xp(b)] : [text("("), ...xp(a), text(")"), sup(b)];

const RULES = ["Multiplying powers: add the exponents.", "Dividing powers: subtract the exponents.", "A power of a power: multiply the exponents."] as const;

/** The predictable slip for each rule. Dividing the exponents is only a slip when it comes out whole. */
function slip({ t, a, b }: ExponentRule): Slip[] {
  if (t === 0) return [[a * b, "Multiplied the exponents", "When you multiply powers with the same base, add the exponents."]];
  if (t === 1) return Number.isInteger((a + b) / b) ? [[(a + b) / b, "Divided the exponents", "When you divide powers with the same base, subtract the exponents."]] : [];
  return [[a + b, "Added the exponents", "A power of a power multiplies the exponents."]];
}

export function exponentAnswers(p: ExponentRule): AnswerModel {
  const e = p.exponent;
  return {
    steps: [
      ns({ id: "exponent", l: "New exponent", a: s => [...shown(p), op("="), v(), sup(s)], ans: e, h: RULES[p.t], w: slip(p) }),
      ns({ id: "try", l: "Try x = 2", a: s => [num(2), sup(e), op("="), ...s], ans: 2 ** e, h: `Multiply ${f(e)} twos together.`,
        w: [[2 * e, "Multiplied the base by the exponent", `2${supText(e)} means ${f(e)} twos multiplied, not 2 × ${f(e)}.`]] }),
    ],
    finalParts: [0],
  };
}

/** x·x·x: a power written out. */
const written = (n: number): MathText => [text(Array.from({ length: n }, () => "x").join("·"))];

export function explainExponentRule(p: ExponentRule, model: AnswerModel) {
  const { t, a, b } = p;
  const [e, value] = model.steps.map(s => s.slots[0]!.expected!) as [number, number];
  const out: MathText =
    t === 0 ? [mark(written(a)), op("·"), mark(written(b))]
      : t === 1 ? [frac([...written(a), text("·"), mark(written(b))], [mark(written(b))])]
        : Array.from({ length: b }, (_, i) => (i ? [op("·"), mark(written(a))] : [mark(written(a))])).flat();
  const count = [
    `Count the x's: ${f(a)} + ${f(b)} = ${f(e)}.`,
    `The ${f(b)} x's on the bottom cancel ${f(b)} on the top: ${f(a + b)} − ${f(b)} = ${f(e)}.`,
    `${countOf(f(b), "group")} of ${f(a)} x's: ${f(a)} × ${f(b)} = ${f(e)}.`,
  ][t]!;
  return beatExplanation({
    heading: "Three exponent rules",
    idea: ["Multiply: add the exponents. Divide: subtract them. Power of a power: multiply them."],
    statement: shown(p),
    caption: count,
    alt: `${[`x to the ${f(a)} times x to the ${f(b)}`, `x to the ${f(a + b)} divided by x to the ${f(b)}`, `x to the ${f(a)}, all to the ${f(b)}`][t]}, written out as x's, makes x to the ${f(e)}.`,
    steps: [
      { id: "problem", narration: ["Two powers of x multiplied.", "A power of x divided by another.", "A power of x raised to a power."][t]!, math: shown(p) },
      { id: "written", narration: ["Write out the x's.", "Write out the x's: matching x's on the top and bottom cancel.", `Write out the x's: ${countOf(f(b), "copy", "copies")} of x${supText(a)}.`][t]!, math: out },
      { id: "exponent", narration: `${count} So it is x${supText(e)}.`, math: [...shown(p), op("="), ...xp(e)], answerStep: "exponent", result: e },
      { id: "try", narration: `Try x = 2: ${f(e)} twos multiplied make ${f(value)}.`, math: m(2, sup(e), op("="), value), answerStep: "try", result: value },
    ],
  });
}

export const lesson: LessonDefinition<ExponentRule> = withEasyStart({
  id: "g8-exp",
  grade: 8,
  unit: "Exponents and roots",
  title: "Exponent rules",
  reference: createExponentRule(0, 2, 3),
  generate: rng => generateExponentRule(rng),
  restore: restoreExponentRule,
  display: shown,
  displayNote: () => "Simplify, then try x = 2.",
  answers: exponentAnswers,
  explain: explainExponentRule,
});
