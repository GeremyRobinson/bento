// The decimal-shift picture (the current app's decimalShift()): a row of digit boxes and the decimal point
// hopping one place per hop. Digits, the point's start and end, and the zeros it has to write in all come from the values.
import type { SceneDiagram, SceneItem } from "../scene/schema";
import { r1 } from "../scene/helpers";
import { textWidth } from "./build";

export interface DecimalShiftSpec {
  /** the digits as written, without the point, e.g. "837" for 8.37 */
  digits: string;
  /** how many digits sit left of the point before and after the move */
  from: number;
  to: number;
  /** beat the digits and the point first show */
  beat: number;
  /** beat the point hops on */
  moveBeat: number;
  /** what the move does, e.g. "× 1000: 3 hops right → 8370" (shown from moveBeat) */
  label: string;
  /** optional line shown on a later beat, e.g. "4.6 × 10³"; `sup` is set as an exponent */
  result?: { text: string; sup?: string; beat: number };
  alt: string;
}

const CW = 46;
/** the space between two boxes, wide enough to hold the point clear of both outlines */
const GAP = 14;
/** the point's radius */
const R = 4.5;

/**
 * Pads the digit row so the point can land on either end: zeros are written in after the last digit
 * (moving right past the end) or before the first (moving left past the start). New zeros show from the move beat.
 */
export function shiftDigits(digits: string, from: number, to: number): { digits: string; from: number; to: number; added: number[] } {
  if (!/^\d+$/.test(digits)) throw new Error(`digits must be digits, got "${digits}"`);
  let d = digits, f = from, t = to;
  const added: number[] = [];
  while (Math.max(f, t) > d.length) { added.push(d.length); d += "0"; }
  while (Math.min(f, t) < 1) { d = "0" + d; f++; t++; added.forEach((_, i) => added[i]!++); added.push(0); }
  return { digits: d, from: f, to: t, added };
}

export function buildDecimalShift(spec: DecimalShiftSpec): SceneDiagram {
  const { digits, from, to, added } = shiftDigits(spec.digits, spec.from, spec.to);
  const n = digits.length, steps = Math.abs(to - from), dir = Math.sign(to - from);
  const W = Math.max(n * CW + 80, textWidth(spec.label, 17) + 24, spec.result ? textWidth(spec.result.text, 22) + 40 : 0);
  const left = (W - n * CW) / 2, y = 70;
  const X = (k: number) => r1(left + k * CW);
  const items: SceneItem[] = [];
  [...digits].forEach((dg, i) => {
    const isNew = added.includes(i);
    const at = isNew ? { from: spec.moveBeat, delay: r1(0.3 + steps * 0.45) } : { from: spec.beat, delay: r1(0.1 + i * 0.05) };
    items.push({ type: "rect", x: r1(left + i * CW + GAP / 2), y: y - 30, w: CW - GAP, h: 56, rx: 10, cls: "seg", enter: isNew ? "pop" : "fade", ...at });
    items.push({ type: "text", x: r1(left + i * CW + CW / 2), y: y - 2, text: dg, cls: isNew ? "big acc" : "big", enter: isNew ? "pop" : "fade", ...at });
  });
  // the point sits in the gap between two boxes at the digits' foot, clear of both outlines (G 2026-10-07: it read as a
  // face when it sat on the corners). Before the move it's the solid point; on the move it stays behind as a hollow
  // ring (where it was), each hop curves under a box from one gap to the next with a small head pointing the way, and
  // the solid point lands at the end
  const cy = y + 20, foot = cy + 8;
  items.push({ type: "circle", cx: X(from), cy, r: R, cls: "dotp", enter: "pop", from: spec.beat, until: spec.moveBeat - 1 });
  items.push({ type: "circle", cx: X(from), cy, r: R, cls: "hole was", enter: "fade", from: spec.moveBeat });
  for (let k = 0; k < steps; k++) {
    const a = X(from + k * dir), c = X(from + (k + 1) * dir), mx = r1((a + c) / 2), my = y + 60;
    items.push({ type: "path", d: `M${a} ${foot} Q${mx} ${my} ${c} ${foot}`, cls: "ln2 arrow", enter: "draw", from: spec.moveBeat, delay: r1(k * 0.45) });
    // the head: two short strokes back along the curve's last direction
    const tx = c - mx, ty = foot - my, len = Math.hypot(tx, ty), ux = tx / len, uy = ty / len, H = 7;
    const side = (s: number) => `${r1(c - H * (ux * Math.cos(0.5) - s * uy * Math.sin(0.5)))} ${r1(foot - H * (uy * Math.cos(0.5) + s * ux * Math.sin(0.5)))}`;
    items.push({ type: "path", d: `M${side(1)} L${c} ${foot} L${side(-1)}`, cls: "ln2", enter: "fade", from: spec.moveBeat, delay: r1(0.35 + k * 0.45) });
  }
  items.push({ type: "circle", cx: X(to), cy, r: R, cls: "dota", enter: "pop", from: spec.moveBeat, delay: r1(steps * 0.45) });
  items.push({ type: "text", x: r1(W / 2), y: y + 84, text: spec.label, cls: "lbl acc", enter: "rise", from: spec.moveBeat, delay: r1(0.2 + steps * 0.45) });
  let H = y + 98;
  if (spec.result) {
    items.push({ type: "text", x: r1(W / 2), y: y + 116, text: spec.result.text, ...(spec.result.sup ? { sup: spec.result.sup } : {}), cls: "lbl big", enter: "rise", from: spec.result.beat });
    H = y + 134;
  }
  return { kind: "scene", family: "decimal-shift", width: r1(W), height: H, items, alt: spec.alt };
}
