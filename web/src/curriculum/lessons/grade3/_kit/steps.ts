// Step builders the 3rd grade lessons share, on top of the number-line family's oneBox and manyBoxes.
// Slips that happen to equal the right answer for a given problem are dropped, so a slip can never mark a right answer wrong.
// (This folder has no index.ts, so the lesson registry skips it.)
import { answer, frac, slot, type MathText, type MathToken } from "../../../schemas/math-text";
import type { AnswerStep, RichText, StepCheck } from "../../../schemas/lesson";
import { eq } from "../../../../engine/evaluation/numbers";
import { manyBoxes, oneBox, type OneBox } from "../../_number-line/steps";

export { expectedOf, restoreVia, wholeIn } from "../../_number-line/steps";

/** One box; slips equal to the answer (or repeated) are left out. */
export function box(o: OneBox): AnswerStep {
  const seen = new Set<number>();
  const wrong = (o.wrong ?? []).filter(([v]) => !eq(v, o.ans) && !seen.has(v) && (seen.add(v), true));
  return oneBox({ ...o, wrong });
}

type Many = Parameters<typeof manyBoxes>[0];
/** Several boxes checked together; slips equal to the answer (or repeated) are left out. */
export function boxes(o: Many): AnswerStep {
  const ids = Object.keys(o.ans), key = (v: Record<string, number>) => ids.map(id => v[id]).join(",");
  const seen = new Set<string>([key(o.ans)]);
  const wrong = (o.wrong ?? []).filter(([v]) => !seen.has(key(v)) && (seen.add(key(v)), true));
  return manyBoxes({ ...o, wrong });
}

/**
 * A fraction typed as a top box and a bottom box. The pieces are counted, so the fraction must be exactly N/D:
 * an equal fraction written another way gets a kind nudge instead of a mark.
 */
export function fracBoxes(o: {
  id: string; label: string; question?: RichText; note?: RichText;
  /** the math around the fraction; gets the fraction (boxes, or the answer for the finished line) */
  prompt: (f: MathToken) => MathText;
  N: number; D: number;
  /** slips: [top, bottom, kind, message] */
  wrong?: [number, number, string, RichText][];
  hint: RichText; explain?: RichText;
}): AnswerStep {
  const seen = new Set<string>([`${o.N}/${o.D}`]);
  const wrong = (o.wrong ?? []).filter(([n, d]) => !seen.has(`${n}/${d}`) && (seen.add(`${n}/${d}`), true));
  const check = (v: Record<string, number | null>): StepCheck => {
    const n = v.n, d = v.d;
    if (n == null || d == null) return { ok: false, soft: true, message: "Fill in the top and the bottom." };
    if (eq(n, o.N) && eq(d, o.D)) return { ok: true };
    for (const [bn, bd, kind, message] of wrong) if (eq(n, bn) && eq(d, bd)) return { ok: false, kind, message, generic: false };
    if (d !== 0 && eq(n * o.D, o.N * d)) return { ok: false, soft: true, message: `That's the same amount. Count the pieces in the picture. Write it with ${o.D} on the bottom.` };
    return { ok: false, kind: o.label, message: `Not quite. ${o.hint}`, generic: true };
  };
  return {
    id: o.id, label: o.label,
    ...(o.question ? { question: o.question } : {}),
    ...(o.note ? { note: o.note } : {}),
    prompt: o.prompt(frac([slot("n")], [slot("d")])),
    slots: [{ id: "n", expected: o.N }, { id: "d", expected: o.D }],
    known: wrong.map(([n, d, kind, message]) => ({ values: { n, d }, kind, message })),
    check,
    hint: o.hint,
    explain: o.explain ?? o.hint,
    work: o.prompt(frac([answer("n", o.N)], [answer("d", o.D)])),
  };
}

/** A tap-to-answer step: one slot "c" holding the index of the right choice, and a message for each wrong tap. */
export function choice(o: {
  id: string; label: string; question?: RichText; note?: RichText;
  prompt: MathText; choices: string[]; right: number;
  /** a kind and message for each wrong choice, by index */
  wrong: Record<number, [string, RichText]>;
  hint: RichText; explain: RichText; work: MathText;
}): AnswerStep {
  return {
    id: o.id, label: o.label,
    ...(o.question ? { question: o.question } : {}),
    ...(o.note ? { note: o.note } : {}),
    prompt: o.prompt,
    choices: o.choices,
    slots: [{ id: "c", expected: o.right }],
    known: Object.entries(o.wrong).filter(([i]) => Number(i) !== o.right).map(([i, [kind, message]]) => ({ values: { c: Number(i) }, kind, message })),
    hint: o.hint, explain: o.explain, work: o.work,
  };
}

/** "1 dot" / "3 dots". */
export const plural = (n: number, one: string, many = `${one}s`) => `${n} ${n === 1 ? one : many}`;
