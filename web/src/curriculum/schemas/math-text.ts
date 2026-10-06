// Math as data, not HTML: every number in a prompt, a worked line or a narration sentence is a value,
// so it can be traced back to the problem model and formatted the same way everywhere.
export type Operator = "+" | "−" | "×" | "÷" | "=" | "<" | ">" | "≤" | "≥" | "≈" | "→" | "·" | "±";

export type MathToken =
  | { t: "text"; v: string }
  | { t: "num"; v: number }
  | { t: "op"; v: Operator }
  /** an answer box; small boxes are for exponents and whole parts of mixed numbers */
  | { t: "slot"; id: string; small?: boolean }
  /** a value the student found (or will find), shown bold in finished work */
  | { t: "answer"; id: string; v: number }
  | { t: "frac"; n: MathText; d: MathText }
  | { t: "sup"; v: MathText }
  | { t: "sub"; v: MathText }
  | { t: "sqrt"; v: MathText }
  /** the part of a line the explanation is pointing at */
  | { t: "mark"; v: MathText }
  /** quiet side notes such as "(× 3)" */
  | { t: "muted"; v: MathText }
  | { t: "bold"; v: MathText }
  /** a number that names a part of the picture (0 = the first part, 1 = the second): it wears that part's colour */
  | { t: "part"; k: 0 | 1; v: MathText }
  /** a line break, for problems shown as two lines (two equations, two functions) */
  | { t: "br" };

export type MathText = MathToken[];

export const text = (v: string): MathToken => ({ t: "text", v });
export const num = (v: number): MathToken => ({ t: "num", v });
export const op = (v: Operator): MathToken => ({ t: "op", v });
export const slot = (id: string, small = false): MathToken => (small ? { t: "slot", id, small } : { t: "slot", id });
export const answer = (id: string, v: number): MathToken => ({ t: "answer", id, v });
export const br = (): MathToken => ({ t: "br" });
const asText = (x: MathText | number | string): MathText =>
  typeof x === "number" ? [num(x)] : typeof x === "string" ? [text(x)] : x;
export const frac = (n: MathText | number | string, d: MathText | number | string): MathToken => ({ t: "frac", n: asText(n), d: asText(d) });
export const sup = (v: MathText | number | string): MathToken => ({ t: "sup", v: asText(v) });
export const sub = (v: MathText | number | string): MathToken => ({ t: "sub", v: asText(v) });
export const sqrt = (v: MathText | number | string): MathToken => ({ t: "sqrt", v: asText(v) });
export const mark = (v: MathText | number | string): MathToken => ({ t: "mark", v: asText(v) });
export const muted = (v: MathText | number | string): MathToken => ({ t: "muted", v: asText(v) });
export const bold = (v: MathText | number | string): MathToken => ({ t: "bold", v: asText(v) });

const round6 = (x: number) => Math.round(x * 1e6) / 1e6;

/** The one number format used on screen: a real minus sign, no float noise. */
export function formatNumber(x: number): string {
  const r = round6(x);
  return (r < 0 ? "−" : "") + String(Math.abs(r));
}

const SUPS: Record<string, string> = { "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹", "−": "⁻", "-": "⁻" };

/** Plain-text reading of a math line, used for narration, accessibility labels and tests. */
export function toPlainText(m: MathText, slotText = "?"): string {
  const one = (tok: MathToken): string => {
    switch (tok.t) {
      case "text": return tok.v;
      case "num": return formatNumber(tok.v);
      case "op": return ` ${tok.v} `;
      case "slot": return slotText;
      case "answer": return formatNumber(tok.v);
      case "frac": return `${inner(tok.n)}/${inner(tok.d)}`;
      case "sup": { const s = inner(tok.v); return [...s].every(c => SUPS[c]) ? [...s].map(c => SUPS[c]).join("") : `^${s}`; }
      case "sub": return inner(tok.v);
      case "sqrt": return `√${inner(tok.v)}`;
      case "mark": case "muted": case "bold": case "part": return tok.v.map(one).join("");
      case "br": return "; ";
    }
  };
  const inner = (x: MathText) => x.map(one).join("").replace(/\s+/g, " ").trim();
  return m.map(one).join("").replace(/\s+/g, " ").trim();
}

/** Numbers that appear in a math line, in order (answers included). */
export const numbersIn = (m: MathText): number[] =>
  m.flatMap(tok => {
    switch (tok.t) {
      case "num": case "answer": return [tok.v];
      case "frac": return [...numbersIn(tok.n), ...numbersIn(tok.d)];
      case "sup": case "sub": case "sqrt": case "mark": case "muted": case "bold": case "part": return numbersIn(tok.v);
      default: return [];
    }
  });

/** Slot ids in a math line, in reading order. */
export const slotsIn = (m: MathText): string[] =>
  m.flatMap(tok => {
    switch (tok.t) {
      case "slot": return [tok.id];
      case "frac": return [...slotsIn(tok.n), ...slotsIn(tok.d)];
      case "sup": case "sub": case "sqrt": case "mark": case "muted": case "bold": case "part": return slotsIn(tok.v);
      default: return [];
    }
  });

/** Joins math pieces with spaces handled by the renderer; strings become text tokens and numbers become num tokens. */
export function m(...parts: (MathToken | MathText | number | string)[]): MathText {
  return parts.flatMap(p => (typeof p === "number" ? [num(p)] : typeof p === "string" ? [text(p)] : Array.isArray(p) ? p : [p]));
}
