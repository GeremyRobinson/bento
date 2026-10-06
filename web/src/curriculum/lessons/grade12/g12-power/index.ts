import { answer, formatNumber as f, m, mark, num, op, slot, sup, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition, StepCheck } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { numStep, supText, v } from "../../algebra-kit/steps";
import { attempt, readInts, rule } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { powerRulePicture } from "./picture";

/** f(x) = a·xⁿ, so f′(x) = (n·a)·xⁿ⁻¹. */
export interface PowerRule { kind: "derivatives.power"; a: number; n: number }

export function createPowerRule(a: number, n: number): PowerRule {
  rule(a >= 1 && n >= 2, "a ≥ 1 and n ≥ 2");
  return { kind: "derivatives.power", a, n };
}

/** Same ranges as the current app: a 2–9, n 2–6. */
export const generatePowerRule = (rng: Rng) => { const a = rng.int(2, 9), n = rng.int(2, 6); return createPowerRule(a, n); };

export function restorePowerRule(raw: unknown): PowerRule | null {
  const r = readInts(raw, ["a", "n"] as const);
  return r && attempt(() => createPowerRule(r.a, r.n));
}

const term = (a: number, n: number | MathText): MathText => [num(a), v(), sup(n)];

export function powerRuleAnswers({ a, n }: PowerRule): AnswerModel {
  const c = a * n, e = n - 1;
  const write: AnswerStep = {
    id: "write",
    label: "Write f′(x)",
    prompt: [text("f′(x)"), op("="), slot("c"), v(), sup([slot("e", true)])],
    note: "Use your two answers.",
    slots: [{ id: "c", expected: c }, { id: "e", expected: e }],
    known: [],
    check: (vals): StepCheck => {
      if (vals.c == null || vals.e == null) return { ok: false, soft: true, message: "Fill in both boxes." };
      if (vals.c === c && vals.e === e) return { ok: true };
      if (vals.c === a) return { ok: false, kind: "Forgot to multiply", message: `Multiply ${f(a)} by the exponent ${f(n)} first.`, generic: false };
      if (vals.e === n) return { ok: false, kind: "Kept the exponent", message: "Lower the exponent by 1.", generic: false };
      return { ok: false, kind: "Power rule", message: `Coefficient ${f(a)} × ${f(n)}, exponent ${f(n)} − 1.`, generic: false };
    },
    hint: `${f(c)}x to the ${f(e)}.`,
    explain: `f′(x) = ${f(c)}x${supText(e)}.`,
    work: [text("f′(x)"), op("="), answer("c", c), v(), sup([answer("e", e)])],
  };
  return {
    steps: [
      numStep({ id: "coefficient", l: "Bring the exponent down", a: s => [num(n), op("×"), num(a), op("="), ...s], ans: c,
        w: [[a + n, "Added instead of multiplied", "Multiply the coefficient by the exponent."]], h: `${f(n)} × ${f(a)}.`, explain: `${f(n)} × ${f(a)} = ${f(c)}.`,
        work: [text("New coefficient:"), answer("x", c)] }),
      numStep({ id: "exponent", l: "Lower the exponent", a: s => [num(n), op("−"), num(1), op("="), ...s], ans: e,
        w: [[n + 1, "Raised the exponent", "For a derivative the exponent goes **down** by 1."]], h: `${f(n)} − 1.`, explain: `${f(n)} − 1 = ${f(e)}.`,
        work: [text("New exponent:"), answer("x", e)] }),
      write,
    ],
    finalParts: [-1],
  };
}

export function explainPowerRule(p: PowerRule, model: AnswerModel) {
  const { a, n } = p;
  const [c, e] = model.steps.map(s => s.slots[0]!.expected!) as [number, number];
  return beatExplanation({
    heading: "The power rule",
    statement: [text("f(x)"), op("="), ...term(a, n)],
    caption: "Bring the exponent down, then lower it by 1.",
    diagram: powerRulePicture({ a, n, c, e }),
    alt: `f(x) = ${f(a)}x${supText(n)}: ${f(n)} × ${f(a)} = ${f(c)} and ${f(n)} − 1 = ${f(e)}, so f′(x) = ${f(c)}x${supText(e)}.`,
    steps: [
      { id: "problem", narration: `The exponent ${f(n)} is what comes down.`, math: [num(a), v(), sup([mark(n)])] },
      { id: "coefficient", narration: `Bring the exponent down and multiply: ${f(n)} × ${f(a)} = ${f(c)}.`, math: m(n, op("×"), a, op("="), c),
        line: [mark(n), op("·"), num(a), v(), sup([num(n), op("−"), num(1)])], answerStep: "coefficient", result: c },
      { id: "exponent", narration: `Then lower the exponent by 1: ${f(n)} − 1 = ${f(e)}.`, math: m(n, op("−"), 1, op("="), e), line: term(c, e), answerStep: "exponent", result: e },
      { id: "write", narration: `So f′(x) = ${f(c)}x${supText(e)}.`, math: [text("f′(x)"), op("="), ...term(c, e)], line: null, answerStep: "write", result: c },
    ],
  });
}

export const lesson: LessonDefinition<PowerRule> = {
  id: "g12-power",
  grade: 12,
  unit: "Derivatives",
  title: "Power rule",
  reference: createPowerRule(3, 4),
  generate: rng => generatePowerRule(rng),
  restore: restorePowerRule,
  display: p => [text("f(x)"), op("="), ...term(p.a, p.n)],
  displayNote: () => "Find f′(x).",
  answers: powerRuleAnswers,
  explain: explainPowerRule,
};
