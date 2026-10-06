// Turns rebuilt math and messages into the same plain form the legacy fixtures were recorded in,
// so the parity tests compare what a student reads, not how it is built.
import { formatNumber, type MathText, type MathToken } from "../../curriculum/schemas/math-text";
import { singular } from "./singular";

/** Fractions as (n)/(d), superscripts as ^(x), subscripts as _(x), boxes as [id]. */
export function legacyText(m: MathText): string {
  const one = (t: MathToken): string => {
    switch (t.t) {
      case "text": return t.v;
      case "num": return formatNumber(t.v);
      case "op": return ` ${t.v} `;
      case "slot": return `[${t.id}]`;
      case "answer": return formatNumber(t.v);
      case "frac": return `(${legacyText(t.n)})/(${legacyText(t.d)})`;
      case "sup": return `^(${legacyText(t.v)})`;
      case "sub": return `_(${legacyText(t.v)})`;
      case "sqrt": return `√${legacyText(t.v)}`;
      case "mark": case "muted": case "bold": case "part": return legacyText(t.v);
      case "br": return " ";
    }
  };
  return m.map(one).join("");
}

/** Message text without emphasis markers; fractions written n/d match the recorded (n)/(d). */
export const legacyRich = (s: string) => s.replace(/\*\*/g, "").replace(/(\d+)\/(\d+)/g, "($1)/($2)");

/**
 * Compare ignoring spacing, the minus sign's form and superscript/subscript styles: what differs then is real.
 * The current app's "1 dots" slips are fixed on both sides, since the rebuild says "1 dot" (reviewer, 2026-10-03).
 */
export function squash(s: string): string {
  s = singular(s);
  const sup: Record<string, string> = { "⁰": "0", "¹": "1", "²": "2", "³": "3", "⁴": "4", "⁵": "5", "⁶": "6", "⁷": "7", "⁸": "8", "⁹": "9", "⁻": "−" };
  return s
    .replace(/[⁰¹²³⁴⁵⁶⁷⁸⁹⁻]+/g, x => `^(${[...x].map(c => sup[c]).join("")})`)
    .replace(/[₀₁₂₃₄₅₆₇₈₉]+/g, x => `_(${[...x].map(c => String(c.charCodeAt(0) - 0x2080)).join("")})`)
    .replace(/\((\d+)\)\/\((\d+)\)/g, "$1/$2")
    .replace(/-/g, "−")
    .replace(/\s+/g, "")
    .replace(/[.,]$/, "");
}
