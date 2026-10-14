import { frac, slot, text, type MathText } from "../../curriculum/schemas/math-text";
import type { AnswerModel, AnswerSlot, AnswerStep, StepCheck } from "../../curriculum/schemas/lesson";
import { eq } from "./numbers";

/** A step as practice uses it: the answer-model step plus its numbered label and help state. */
export interface RuntimeStep {
  id: string;
  /** "Step 2 · Multiply by the ones" */
  label: string;
  /** "Multiply by the ones", used by plan-the-step choices */
  base: string;
  question?: string;
  prompt: MathText;
  note?: string;
  slots: AnswerSlot[];
  choices?: string[];
  hint: string;
  /** what to look at after a wrong answer no known slip explains */
  look?: string;
  explain: string;
  work: MathText;
  /** true for the final-answer shortcut that stands in for several steps */
  skipped?: boolean;
  /** the answer-model steps this one checks, with the suffix their box ids carry here */
  parts: { step: AnswerStep; suffix: string }[];
}

export type CheckResult = StepCheck;

/** Box ids the student types into (boxes expected to stay empty still exist, but aren't asked for). */
export const answerIds = (slots: AnswerSlot[]) => slots.filter(s => s.expected != null).map(s => s.id);

export function runtimeSteps(model: AnswerModel): RuntimeStep[] {
  return model.steps.map((s, k) => ({
    id: s.id,
    label: `Step ${k + 1} · ${s.label}`,
    base: s.label,
    ...(s.question ? { question: s.question } : {}),
    ...(s.note ? { note: s.note } : {}),
    ...(s.choices ? { choices: s.choices } : {}),
    prompt: s.prompt,
    slots: s.slots,
    hint: s.hint,
    ...(s.look ? { look: s.look } : {}),
    explain: s.explain,
    work: s.work,
    parts: [{ step: s, suffix: "" }],
  }));
}

/** Default check: every box equals its expected value (or stays empty when none is expected), then the known slips. */
export function checkAnswerStep(step: AnswerStep, values: Record<string, number | null>): CheckResult {
  if (step.check) return step.check(values);
  const right = step.slots.every(s => (s.expected == null ? values[s.id] == null : eq(values[s.id], s.expected)));
  if (right) return { ok: true };
  for (const k of step.known) {
    if (Object.entries(k.values).every(([id, v]) => eq(values[id], v))) return { ok: false, kind: k.kind, message: k.message, generic: false };
  }
  return { ok: false, kind: step.label, message: `Not quite. ${step.hint}`, generic: true };
}

/** Check a runtime step; the final-answer step checks each of its parts in turn. */
export function checkStep(step: RuntimeStep, values: Record<string, number | null>): CheckResult {
  const many = step.parts.length > 1;
  for (const { step: part, suffix } of step.parts) {
    const sub = Object.fromEntries(part.slots.map(s => [s.id, values[s.id + suffix] ?? null]));
    if (step.skipped && answerIds(part.slots).some(id => sub[id] == null)) return { ok: false, soft: true, message: "Fill in every box." };
    const r = checkAnswerStep(part, sub);
    if (!r.ok) return many && !r.soft ? { ...r, generic: false, kind: `${part.label}: ${r.kind}` } : r;
  }
  return { ok: true };
}

/** Boxes of a step that have an answer, with the expected values, using the step's own box ids. */
export const expectedValues = (step: RuntimeStep): Record<string, number> =>
  Object.fromEntries(step.parts.flatMap(({ step: s, suffix }) => s.slots.flatMap(x => (x.expected == null ? [] : [[x.id + suffix, x.expected]]))));

/** The current app's "which steps make the final answer": negative counts from the end. */
export function finalPartsOf(steps: AnswerStep[], finalParts: number[]): AnswerStep[] {
  return finalParts.map(i => steps[(i + steps.length) % steps.length]!);
}

/** The boxes of a step on their own: a fraction for a top and bottom, otherwise side by side (as the current app's slotsFor). */
function boxesOf(step: AnswerStep, suffix: string): MathText {
  const ids = answerIds(step.slots);
  if (ids.length === 2 && ids.includes("n") && ids.includes("d")) return [frac([slot("n" + suffix)], [slot("d" + suffix)])];
  // a mixed number: the small whole-number box, then the fraction, as practice lays out the step (never "?, ?, ?")
  if (ids.length === 3 && ids.includes("w") && ids.includes("n") && ids.includes("d")) return [slot("w" + suffix, true), frac([slot("n" + suffix)], [slot("d" + suffix)])];
  return ids.flatMap((id, i) => (i ? [text(", "), slot(id + suffix)] : [slot(id + suffix)]));
}

/** One "Final answer" step built from the last steps. Each part keeps its own check and mistake messages. */
export function finalStep(parts: AnswerStep[]): RuntimeStep {
  const many = parts.length > 1;
  const withSuffix = parts.map((step, j) => ({ step, suffix: many ? String(j) : "" }));
  const prompt: MathText = withSuffix.flatMap(({ step, suffix }) => [...(many ? [text(`${step.label}: `)] : []), ...boxesOf(step, suffix)]);
  return {
    id: "final",
    label: "Final answer",
    base: "Final answer",
    question: !many && parts[0]!.choices ? parts[0]!.question ?? "Pick the final answer." : "Type the final answer.",
    // a final answer that is one tap step keeps its buttons
    ...(!many && parts[0]!.choices ? { choices: parts[0]!.choices } : {}),
    prompt,
    slots: withSuffix.flatMap(({ step, suffix }) => step.slots.filter(s => s.expected != null).map(s => ({ id: s.id + suffix, expected: s.expected }))),
    hint: parts.map(p => p.hint).join(" "),
    explain: parts.map(p => p.explain).join(" "),
    work: parts.flatMap((p, i) => (i ? [text("   "), ...p.work] : p.work)),
    skipped: true,
    note: "Steps skipped. Miss it and we'll go step by step.",
    parts: withSuffix,
  };
}
