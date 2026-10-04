// Small helpers the kindergarten lessons share: slips without repeats, tap-to-answer steps, and counting words.
import { br, num, text, type MathText } from "../../schemas/math-text";
import type { AnswerStep, RichText } from "../../schemas/lesson";

/** The number every ten frame and tens row holds. */
export const TEN = 10;

/** Slips as oneBox wants them, keeping only whole numbers 0 to 100 that differ from the answer, first one wins. */
export function slips(ans: number, list: [number, string, RichText][]): [number, string, RichText][] {
  const seen = new Set<number>([ans]);
  return list.filter(([v]) => {
    if (!Number.isInteger(v) || v < 0 || v > 100 || seen.has(v)) return false;
    seen.add(v);
    return true;
  });
}

/** A tap-to-answer step: one slot "c" holds the index of the right choice, and every wrong tap has its own message. */
export function tapStep(o: {
  id: string;
  label: string;
  question: RichText;
  prompt: MathText;
  choices: string[];
  right: number;
  /** the message for each wrong choice, by index */
  wrong: (i: number) => [string, RichText];
  hint: RichText;
  explain: RichText;
  work: MathText;
}): AnswerStep {
  if (!o.choices[o.right]) throw new Error("the right choice must be one of the choices");
  return {
    id: o.id,
    label: o.label,
    question: o.question,
    prompt: o.prompt,
    choices: o.choices,
    slots: [{ id: "c", expected: o.right }],
    known: o.choices.flatMap((_, i) => {
      if (i === o.right) return [];
      const [kind, message] = o.wrong(i);
      return [{ values: { c: i }, kind, message }];
    }),
    hint: o.hint,
    explain: o.explain,
    work: o.work,
  };
}

/** "1, 2, 3" style counting from `from` up to `to`. */
export const countUp = (from: number, to: number) => Array.from({ length: Math.max(0, to - from + 1) }, (_, i) => from + i).join(", ");

/** Checks a whole-number index into a list. */
export function indexIn(name: string, i: number, list: readonly unknown[]) {
  if (!Number.isInteger(i) || i < 0 || i >= list.length) throw new Error(`${name} must pick one of ${list.length} options, got ${i}`);
}

/**
 * Words for the big problem line, one token per word so a sentence can wrap (text tokens never break inside).
 * Numbers become number tokens; spaces sit inside the word tokens so the plain-text reading keeps them.
 */
export function words(...parts: (string | number)[]): MathText {
  const items: (string | number)[] = parts.flatMap((p): (string | number)[] => (typeof p === "number" ? [p] : p.split(" ").filter(Boolean)));
  return items.map((w, i) => {
    if (typeof w === "number") return num(w);
    return text(`${i ? " " : ""}${w}${typeof items[i + 1] === "number" ? " " : ""}`);
  });
}

/** Lines of words, one under the other. */
export const lines = (...ls: MathText[]): MathText => ls.flatMap((l, i) => (i ? [br(), ...l] : l));

/**
 * A step that also takes another right answer (adding in a different order is slower, not wrong):
 * any value in `also` passes, then the step's known slips, then the generic nudge.
 */
export function alsoAccept(step: AnswerStep, also: number[]): AnswerStep {
  const id = step.slots[0]!.id;
  return {
    ...step,
    check: values => {
      const v = values[id];
      if (v != null && (v === step.slots[0]!.expected || also.includes(v))) return { ok: true };
      for (const k of step.known) if (k.values[id] === v) return { ok: false, kind: k.kind, message: k.message, generic: false };
      return { ok: false, kind: step.label, message: step.hint, generic: true };
    },
    known: step.known.filter(k => !also.includes(k.values[id]!)),
  };
}
