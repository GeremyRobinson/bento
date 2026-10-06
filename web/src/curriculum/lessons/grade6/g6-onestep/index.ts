import { formatNumber as f, m, num, op, toPlainText, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { ns, v } from "../../algebra-kit/steps";
import { attempt, readInts, rule } from "../../algebra-kit/restore";
import { beatExplanation } from "../../../../explanations/diagrams/algebra/chain";
import { block, buildBalance, xTiles, type BalanceFrame, type Pan } from "../../../../explanations/diagrams/algebra/balance";

const round6 = (x: number) => Math.round(x * 1e6) / 1e6;

/** One operation on x: x + a, x − a, a·x or x ÷ a (the current app's type t = 0…3), equal to `rhs`. */
export interface OneStepEquation { kind: "equation.oneStep"; t: 0 | 1 | 2 | 3; a: number; x: number; rhs: number }

const RHS = [(x: number, a: number) => x + a, (x: number, a: number) => x - a, (x: number, a: number) => a * x, (x: number, a: number) => x / a] as const;

export function createOneStep(t: number, a: number, x: number): OneStepEquation {
  rule(t === 0 || t === 1 || t === 2 || t === 3, "type 0–3");
  rule(a >= 2 && x >= 1, "a ≥ 2 and x ≥ 1");
  rule(t !== 1 || x > a, "x − a stays positive");
  rule(t !== 3 || x % a === 0, "x ÷ a is whole");
  return { kind: "equation.oneStep", t: t as OneStepEquation["t"], a, x, rhs: RHS[t as 0](x, a) };
}

/** Same as the current app: a 2–9, the answer side 2–12. */
export function generateOneStep(rng: Rng): OneStepEquation {
  const t = rng.int(0, 3), a = rng.int(2, 9), r = rng.int(2, 12);
  return createOneStep(t, a, t === 1 ? r + a : t === 3 ? r * a : r);
}

export function restoreOneStep(raw: unknown): OneStepEquation | null {
  const r = readInts(raw, ["t", "a", "x"] as const);
  return r && attempt(() => createOneStep(r.t, r.a, r.x));
}

/** The left side: x + a, x − a, ax, x ÷ a. */
const lhs = ({ t, a }: OneStepEquation): MathText =>
  t === 0 ? [v(), op("+"), num(a)] : t === 1 ? [v(), op("−"), num(a)] : t === 2 ? [num(a), v()] : [v(), op("÷"), num(a)];
/** The left side with the answer in place of x, for the check. */
const checkSide = ({ t, a }: OneStepEquation, x: number): MathText =>
  t === 0 ? m(x, op("+"), a) : t === 1 ? m(x, op("−"), a) : t === 2 ? m(a, op("×"), x) : m(x, op("÷"), a);
const undoText = ({ t, a }: OneStepEquation) =>
  [`Subtract ${f(a)} from both sides.`, `Add ${f(a)} to both sides.`, `Divide both sides by ${f(a)}.`, `Multiply both sides by ${f(a)}.`][t];
const sameOperation = ({ t, a, x }: OneStepEquation) => [x + 2 * a, x - 2 * a, a * a * x, round6(x / a / a)][t]!;

export function oneStepAnswers(p: OneStepEquation): AnswerModel {
  return {
    steps: [
      ns({ id: "undo", l: "Undo it", n: undoText(p), a: s => [v(), op("="), ...s], ans: p.x, h: undoText(p)!, w: [[sameOperation(p), "Used the same operation", "Do the opposite to undo it."]] }),
      ns({ id: "check", l: "Check", a: s => [...checkSide(p, p.x), op("="), ...s], ans: p.rhs, h: "Put your x back in the equation.",
        w: [[p.x, "Wrote x again", "Work out the left side with your x in it. It should match the other side."]] }),
    ],
    finalParts: [0],
  };
}

/** The balance, one frame per beat: the equation, the opposite operation on both pans, the check. */
function frames(p: OneStepEquation): BalanceFrame[] {
  const { t, a, x, rhs } = p;
  const groups = (n: number, pan: Pan[number]): Pan => Array.from({ length: n }, () => pan);
  const eq = `${[`x + ${f(a)}`, `x − ${f(a)}`, `${f(a)}x`, `x ÷ ${f(a)}`][t]} = ${f(rhs)}`;
  const part = { kind: "part" as const, label: `x ÷ ${f(a)}` };
  switch (t) {
    case 0: return [
      { left: [xTiles(1), [block(a)]], right: [[block(rhs)]], note: eq },
      { left: [xTiles(1), [block(a, { off: true })]], right: [[block(x, { late: true })], [block(a, { off: true })]], note: `take ${f(a)} off both sides` },
      { left: [[block(x)], [block(a)]], right: [[block(rhs)]], note: `check: ${f(x)} + ${f(a)} = ${f(rhs)}` },
    ];
    case 1: return [
      { left: [xTiles(1), [block(-a)]], right: [[block(rhs)]], note: eq },
      { left: [xTiles(1), [block(-a, { off: true }), block(a, { added: true, off: true })]], right: [[block(rhs)], [block(a, { added: true })]], note: `add ${f(a)} to both sides` },
      { left: [[block(x)], [block(-a)]], right: [[block(rhs)]], note: `check: ${f(x)} − ${f(a)} = ${f(rhs)}` },
    ];
    case 2: return [
      { left: [xTiles(a)], right: [[block(rhs)]], note: eq },
      { left: groups(a, xTiles(1)), right: groups(a, [block(x, { late: true })]), note: `split both sides into ${f(a)}` },
      { left: groups(a, [block(x)]), right: [[block(rhs)]], note: `check: ${f(a)} × ${f(x)} = ${f(rhs)}` },
    ];
    case 3: return [
      { left: [[part]], right: [[block(rhs)]], note: eq },
      { left: groups(a, [part]), right: groups(a, [block(rhs)]), note: `${f(a)} times both sides: x = ${f(x)}` },
      { left: [[block(x)]], right: groups(a, [block(rhs)]), note: `check: ${f(x)} ÷ ${f(a)} = ${f(rhs)}` },
    ];
  }
}

export function explainOneStep(p: OneStepEquation, model: AnswerModel) {
  const [x, rhs] = model.steps.map(s => s.slots[0]!.expected!) as [number, number];
  const opp = ["subtract", "add", "divide by", "multiply by"][p.t]!;
  const undoes = ["+", "−", "×", "÷"][p.t]!;
  const diagram = buildBalance(frames(p), `A balance: ${f(rhs)} on one pan against the other side of the equation. Doing the opposite to both pans leaves x = ${f(x)}.`);
  return beatExplanation({
    heading: "Do the opposite",
    idea: ["An equation is a balance: both sides weigh the same, so whatever you do to one side you do to the other.", "The opposite operation undoes what was done to x and leaves it alone."],
    statement: [...lhs(p), op("="), num(p.rhs)],
    diagram,
    alt: diagram.alt,
    steps: [
      { id: "equation", narration: `x has ${undoes} ${f(p.a)} done to it, and the pans balance at ${f(p.rhs)}.`, math: [...lhs(p), op("="), num(p.rhs)] },
      { id: "undo", narration: `To undo ${undoes} ${f(p.a)}, ${opp} ${f(p.a)} on both sides: x = ${f(x)}.`, math: [v(), op("="), num(x)], answerStep: "undo", result: x },
      { id: "check", narration: `Check: put ${f(x)} back in for x. ${toPlainText(checkSide(p, x))} = ${f(rhs)}, the same as the other side. ✓`, math: [...checkSide(p, x), op("="), num(rhs)], answerStep: "check", result: rhs },
    ],
  });
}

export const lesson: LessonDefinition<OneStepEquation> = {
  id: "g6-onestep",
  grade: 6,
  unit: "Expressions and equations",
  title: "One-step equations",
  pre: "g6-eval",
  reference: createOneStep(0, 7, 8),
  generate: rng => generateOneStep(rng),
  restore: restoreOneStep,
  display: p => [...lhs(p), op("="), num(p.rhs)],
  answers: oneStepAnswers,
  explain: explainOneStep,
};
