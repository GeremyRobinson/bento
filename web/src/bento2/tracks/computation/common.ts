// Small helpers the computation lessons share: sorted option lists, bit strings typed as whole numbers, superscripts.
import { group } from "../../steps";

/** a sorted, deterministic option list with the right one's index */
export const options = (right: string, others: string[]) => {
  const all = [...new Set([right, ...others])].sort();
  return { all, at: all.indexOf(right) };
};
/** a bit string as the learner types it into a whole-number box: "0110" → 110 */
export const bitsTyped = (s: string) => Number(s.replace(/^0+(?=.)/, "") || "0");
const SUP: Record<string, string> = { "-": "⁻", "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹" };
export const sup = (n: number) => String(n).replace(/./g, d => SUP[d] ?? d);
export const cap = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);
export const LETTERS = "ABCDEFGH";
export const WORD = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen", "twenty"];
export const g = (x: number) => group(x);
/** "1 step", "3 steps" */
export const pl = (n: number, one: string, many = `${one}s`) => `${group(n)} ${n === 1 ? one : many}`;
export const factorialOf = (n: number) => { let f = 1; for (let k = 2; k <= n; k++) f *= k; return f; };
/** a time in seconds as a person would say it: "300 s (5 minutes)", "1.9 years" */
export function human(s: number): string {
  if (!Number.isFinite(s)) return "forever";
  if (s < 1e-6) return `${trim(s * 1e9)} ns`;
  if (s < 1e-3) return `${trim(s * 1e6)} µs`;
  if (s < 1) return `${trim(s * 1e3)} ms`;
  if (s < 60) return `${trim(s)} s`;
  if (s < 3600) return `${trim(s / 60)} min`;
  if (s < 86400) return `${trim(s / 3600)} h`;
  if (s < 365 * 86400) return unit(trim(s / 86400), "day");
  const y = s / (365 * 86400);
  if (y > 1.4e10) return "longer than the universe has existed";
  if (y >= 1e9) return `${trim(y / 1e9)} billion years`;
  if (y >= 1e6) return `${trim(y / 1e6)} million years`;
  return unit(trim(y), "year");
}
const unit = (v: string, one: string) => `${v} ${v === "1" ? one : `${one}s`}`;
const trim = (x: number) => (x >= 100 ? group(Math.round(x)) : x >= 10 ? String(Math.round(x * 10) / 10) : String(Math.round(x * 100) / 100));
