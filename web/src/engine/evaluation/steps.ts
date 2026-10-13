import { formatNumber, frac, slot, slotsIn, text, toPlainText, type MathText, type MathToken } from "../../curriculum/schemas/math-text";
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

/** The prompt's runs of answer boxes ("? ?/?" for a mixed number is one run); a run that is only an exponent box is its inside. */
export function answerGroups(prompt: MathText): MathText[] {
  const groups: MathText[] = [];
  let open = false;
  for (const tok of prompt) {
    const boxed = slotsIn([tok]).length > 0;
    if (boxed && open) groups[groups.length - 1]!.push(tok);
    else if (boxed) groups.push([tok]);
    open = boxed;
  }
  return groups.map(g => (g.length === 1 && (g[0]!.t === "sup" || g[0]!.t === "sub") ? g[0]!.v : g));
}

/** Boxes filled with values (a box with no value is left out), each value written by `as`. */
export function fillBoxes(m: MathText, values: Record<string, number | null>, as: (v: number) => MathToken = v => ({ t: "num", v })): MathText {
  return m.map((tok): MathToken => {
    switch (tok.t) {
      case "slot": { const v = values[tok.id]; return v == null ? text("") : as(v); }
      case "frac": return { ...tok, n: fillBoxes(tok.n, values, as), d: fillBoxes(tok.d, values, as) };
      case "sup": case "sub": case "sqrt": case "mark": case "muted": case "bold": case "part": return { ...tok, v: fillBoxes(tok.v, values, as) };
      default: return tok;
    }
  });
}

/**
 * An answer said the way the step shows it (Review g5 full pass, blocker 3): the step's boxes, filled with these values,
 * read as plain text, so a mixed number reads "1 1/18" and a fraction "5/6", never "1, 1, 18". Boxes that sit apart in
 * the prompt are listed with commas; an exponent box says its number; a choice step says its choice.
 */
export function sayAnswer(step: Pick<RuntimeStep, "prompt" | "choices">, values: Record<string, number | null>): string {
  if (step.choices && values.c != null) return step.choices[values.c] ?? String(values.c);
  const said = answerGroups(step.prompt).map(g => toPlainText(fillBoxes(g, values))).filter(Boolean);
  if (said.length) return said.join(", ");
  return Object.values(values).filter((x): x is number => x != null).map(formatNumber).join(", ");
}

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
