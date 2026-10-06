// Checking Work it's steps. A Bento² step becomes the regular engine's AnswerStep (one slot per box), so the same
// checkAnswerStep runs both sides; Bento² only adds the rounding rule (within one unit of the last stated place) and
// typed fractions.
import type { AnswerStep, StepCheck } from "../curriculum/schemas/lesson";
import { checkAnswerStep } from "../engine/evaluation/steps";
import { formatNumber } from "../curriculum/schemas/math-text";
import type { B2Slip, B2Step } from "./model";

/** How close a typed number must be: one unit of the last stated place; fractions and wholes exactly. */
export const toleranceOf = (form: B2Step["form"]) => (typeof form === "number" ? 10 ** -form * 1.0001 : 1e-6);
const near = (a: number | null | undefined, b: number, tol: number) => a != null && Number.isFinite(a) && Math.abs(a - b) <= tol;

/** What a box holds, as a number: "5/4", "−3", "1,234.5", "-12/5". Empty, "−" or "/" alone is no answer yet. */
export function parseTyped(s: string | null | undefined): number | null {
  if (s == null) return null;
  const t = s.replace(/[−–]/g, "-").replace(/,/g, "").replace(/\s+/g, "");
  if (!t || t === "-" || t === "/" || t === ".") return null;
  const m = /^(-?\d*\.?\d+)\/(-?\d*\.?\d+)$/.exec(t);
  if (m) { const d = Number(m[2]); return d === 0 ? null : Number(m[1]) / d; }
  if (!/^-?(\d+\.?\d*|\.\d+)$/.test(t)) return null;
  return Number(t);
}

/** The engine's view of a step: one slot per box, and a check that knows the rounding rule and the slips. */
export function toAnswerStep(step: B2Step): AnswerStep {
  const tol = step.choices ? 1e-6 : toleranceOf(step.form);
  const ids = step.answer.map((_, i) => `b${i}`);
  const check = (values: Record<string, number | null>): StepCheck => {
    const got = ids.map(id => values[id] ?? null);
    if (got.some(v => v == null)) return { ok: false, soft: true, message: step.answer.length > 1 ? "Fill in every box." : "Type an answer first." };
    if (step.answer.every((a, i) => near(got[i], a, tol))) return { ok: true };
    for (const s of step.slips) if (s.values.every((v, i) => near(got[i], v, tol))) return { ok: false, kind: s.kind, message: s.message, generic: false };
    return { ok: false, kind: step.label, message: `Not quite. ${step.hint}`, generic: true };
  };
  return {
    id: step.id, label: step.label, prompt: [], slots: ids.map((id, i) => ({ id, expected: step.answer[i]! })),
    ...(step.choices ? { choices: step.choices } : {}),
    known: step.slips.map(s => ({ kind: s.kind, message: s.message, values: Object.fromEntries(s.values.map((v, i) => [`b${i}`, v])) })),
    check, hint: step.hint, explain: step.done, work: [],
  };
}

/** Checks typed boxes (or a tapped choice index) against a step, through the regular engine. */
export function checkB2Step(step: B2Step, typed: (string | number | null)[]): StepCheck {
  const values = Object.fromEntries(typed.map((v, i) => [`b${i}`, typeof v === "number" ? v : parseTyped(v)]));
  return checkAnswerStep(toAnswerStep(step), values);
}

/** A slip that equals the right answer for these numbers is never shown: drop it, once, where steps are made. */
export function liveSlips(step: B2Step): B2Step {
  const tol = step.choices ? 1e-6 : toleranceOf(step.form);
  const seen: number[][] = [];
  const keep = (s: B2Slip) => {
    if (s.values.some(v => !Number.isFinite(v))) return false;
    if (s.values.every((v, i) => near(v, step.answer[i]!, tol))) return false;
    // two slips with the same numbers: the first one's reason is the one shown
    if (seen.some(o => o.every((v, i) => near(v, s.values[i]!, tol)))) return false;
    seen.push(s.values);
    return true;
  };
  return { ...step, slips: step.slips.filter(keep) };
}

/** The best simple fraction for x (denominator up to 10,000): 1.25 → [5, 4]. */
export function toFraction(x: number, maxDen = 10000): [number, number] {
  if (Number.isInteger(x)) return [x, 1];
  const sign = x < 0 ? -1 : 1;
  let a = Math.abs(x), h0 = 1, h1 = 0, k0 = 0, k1 = 1;
  for (let i = 0; i < 40; i++) {
    const n = Math.floor(a);
    [h0, h1] = [n * h0 + h1, h0];
    [k0, k1] = [n * k0 + k1, k0];
    if (k0 > maxDen) { [h0, k0] = [h1, k1]; break; }
    if (Math.abs(Math.abs(x) - h0 / k0) < 1e-9) break;
    a = 1 / (a - n);
    if (!Number.isFinite(a)) break;
  }
  return [sign * h0, k0];
}

/** A number written the way the step asks for it: "5/4", "−3", "67.4", "9,557". */
export function formatAnswer(x: number, form: B2Step["form"]): string {
  if (form === "fraction") {
    const [n, d] = toFraction(x);
    return d === 1 ? formatNumber(n) : `${formatNumber(n)}/${d}`;
  }
  if (form === "whole") return group(Math.round(x));
  return group(x, form);
}

/** Thousands separated with commas, a real minus sign, a fixed number of places. */
export function group(x: number, places = 0): string {
  const neg = x < 0 && Math.abs(x) >= 0.5 * 10 ** -places;
  const [i, f] = Math.abs(x).toFixed(places).split(".");
  return `${neg ? "−" : ""}${i!.replace(/\B(?=(\d{3})+(?!\d))/g, ",")}${f ? `.${f}` : ""}`;
}
