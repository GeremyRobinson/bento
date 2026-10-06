// How Differential equations writes its numbers and formulas: real minus signs, no coefficient of 1, no "+ −".
import { formatAnswer, group } from "../../steps";

/** "−3" with a real minus sign */
export const sn = (x: number) => (x < 0 ? `−${group(-x, dec(x))}` : group(x, dec(x)));
/** as many places as the number needs, up to 4 */
const dec = (x: number) => { for (let p = 0; p < 4; p++) if (Math.abs(Math.round(x * 10 ** p) - x * 10 ** p) < 1e-9) return p; return 4; };
/** a fraction when it is one: "5/2", "−1/2", "3" */
export const fr = (x: number) => formatAnswer(x, "fraction");
/** a decimal with what it needs: 0.05, 0.0125, 2 */
export const dn = (x: number) => sn(x);

/**
 * A sum of terms written the way Bento writes them: [[3, "y′"], [2, "y"]] → "3y′ + 2y". Zero terms drop out, a
 * coefficient of 1 is left off (−1 becomes a bare minus), and a negative term reads " − " not "+ −". A term with an
 * empty symbol is a plain number.
 */
export function terms(ts: [number, string][], f: (x: number) => string = fr): string {
  let out = "";
  for (const [c, s] of ts) {
    if (c === 0) continue;
    const mag = Math.abs(c), body = s && mag === 1 ? s : `${f(mag)}${s}`;
    out += out ? (c < 0 ? ` − ${body}` : ` + ${body}`) : c < 0 ? `−${body}` : body;
  }
  return out || "0";
}
/** (y − a): "(y + 1)", "y" when a = 0 */
export const factor = (v: string, a: number) => (a === 0 ? v : a < 0 ? `(${v} + ${fr(-a)})` : `(${v} − ${fr(a)})`);
/** a 2×2 matrix as [[7, −4], [8, −5]] */
export const mat = (A: number[][]) => `[[${A.map(r => r.map(sn).join(", ")).join("], [")}]]`;
/** a point (3, −4) */
export const pt = (...xs: number[]) => `(${xs.map(sn).join(", ")})`;
/** a square written so a negative reads right: (−3)², 4² */
export const sq = (x: number) => (x < 0 ? `(${sn(x)})²` : `${sn(x)}²`);
/** a number that sits after an operator: negatives in brackets, so it reads 3 + (−2), never "+ −" */
export const pn = (x: number) => (x < 0 ? `(${fr(x)})` : fr(x));
/** how T and D come from a 2×2 matrix's entries */
export const tdHint = (a: number, b: number, c: number, d: number) => `T = ${sn(a)} + ${pn(d)}, D = ${pn(a)}·${pn(d)} − ${pn(b)}·${pn(c)}.`;
