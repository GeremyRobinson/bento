// The decimal-shift picture (the current app's decimalShift()): a row of digit boxes and the decimal point
// hopping one place per hop. Digits, the point's start and end, and the zeros it has to write in all come from the values.
import { growDown } from "../scene/picture-system";
import type { SceneDiagram, SceneItem } from "../scene/schema";
import { lightSteps, r1 } from "../scene/helpers";
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
  /** what the first beat says before the point moves, e.g. "100 has 2 zeros: 2 hops" (in the label's place) */
  lead?: string;
  /** optional line shown on a later beat, e.g. "4.6 × 10³"; `sup` is set as an exponent */
  result?: { text: string; sup?: string; beat: number };
  alt: string;
}

/** one digit's place: a squarer box than before, so the row reads as a written number (G 2026-10-08: "cleaner and more crisp") */
const CW = 52;
/** the space between two boxes: just room for the point on the baseline */
const GAP = 12;
/** the box's height */
const BH = 52;
/** the point's radius */
const R = 4;
/** seconds from one hop to the next */
const HOP = 0.45;

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
  const W = Math.max(n * CW + 80, textWidth(spec.label, 17) + 24, spec.lead ? textWidth(spec.lead, 17) + 24 : 0, spec.result ? textWidth(spec.result.text, 22) + 40 : 0);
  const left = (W - n * CW) / 2, y = 70;
  const X = (k: number) => r1(left + k * CW);
  const items: SceneItem[] = [];
  // the worked step lit (the shared `lit` role): the point the zeros will move and the line counting them on the first
  // beat; on the move the hops and the new 0s are the step, each drawn as it happens. (The boxes hopped under stay soft:
  // a mid box under an ink digit fails contrast in dark)
  const lit = new Map<SceneItem, number>(), mark = (it: SceneItem, b: number) => { lit.set(it, b); return it; };
  const top = y - 30, base = top + BH;
  // the hop that passes under box i (each hop runs under the one box between the two gaps it joins)
  const hopUnder = (i: number) => Math.max(0, Math.min(steps - 1, dir > 0 ? i - from : from - 1 - i));
  [...digits].forEach((dg, i) => {
    // a written-in 0 is the tricky part (Review g5 #5): its card pops in, filled in the picture's colour, just as the
    // point hops under the empty place, so every hop lands on a card and the child sees the 0 being written. (An .xchip
    // is the mid-filled part; a .seg.on would glow in at once, its glow replacing the pop and so its delay)
    const isNew = added.includes(i);
    const at = isNew ? { from: spec.moveBeat, delay: r1(0.2 + hopUnder(i) * HOP) } : { from: spec.beat, delay: r1(0.1 + i * 0.05) };
    const card: SceneItem = { type: "rect", x: r1(left + i * CW + GAP / 2), y: top, w: CW - GAP, h: BH, rx: 10, cls: isNew ? "xchip" : "seg", enter: isNew ? "pop" : "fade", ...at };
    items.push(card);
    items.push({ type: "text", x: r1(left + i * CW + CW / 2), y: r1(top + BH / 2 + 2), text: dg, cls: isNew ? "big onmid" : "big", enter: isNew ? "pop" : "fade", ...at });
  });
  // the point sits on the digits' baseline in the gap between two boxes, where a written decimal point goes. Before the
  // move it's the solid point; on the move it stays behind as a faint ring, each hop is one shallow arc under the box it
  // passes with a small head, and the solid point lands at the end
  const cy = r1(base - R), foot = r1(base + 7), dip = r1(base + 24);
  items.push(mark({ type: "circle", cx: X(from), cy, r: R, cls: "dotp", enter: "pop", from: spec.beat, until: spec.moveBeat - 1 }, spec.beat));
  items.push({ type: "circle", cx: X(from), cy, r: R, cls: "hole was", enter: "fade", from: spec.moveBeat });
  for (let k = 0; k < steps; k++) {
    // each arc starts and stops a little inside the gaps, so it never touches either point
    const a = X(from + k * dir) + dir * 4, c = X(from + (k + 1) * dir) - dir * 4, mx = r1((a + c) / 2);
    items.push({ type: "path", d: `M${r1(a)} ${foot} Q${mx} ${dip} ${r1(c)} ${foot}`, cls: "ln2 arrow", enter: "draw", from: spec.moveBeat, delay: r1(k * HOP) });
    // the head: two short strokes back along the curve's last direction
    const tx = c - mx, ty = foot - dip, len = Math.hypot(tx, ty), ux = tx / len, uy = ty / len, H = 6;
    const side = (s: number) => `${r1(c - H * (ux * Math.cos(0.55) - s * uy * Math.sin(0.55)))} ${r1(foot - H * (uy * Math.cos(0.55) + s * ux * Math.sin(0.55)))}`;
    items.push({ type: "path", d: `M${side(1)} L${r1(c)} ${foot} L${side(-1)}`, cls: "ln2", enter: "fade", from: spec.moveBeat, delay: r1(0.35 + k * HOP) });
  }
  items.push({ type: "circle", cx: X(to), cy, r: R, cls: "dota", enter: "pop", from: spec.moveBeat, delay: r1(steps * HOP) });
  // the label sits close under the arcs, so the picture and its words read as one
  const ly = r1(dip + 30);
  // the first beat has its own line (how many hops), so the picture answers the first step too
  // the lines hang from the arcs (.down) and the result hangs under the label by the label's height on a phone, with room
  // for its power's raised digit, so "2.7 × 10⁷" never runs into "7 hops left" (Review 26fe1f8, g8-sci)
  if (spec.lead && spec.moveBeat > spec.beat) items.push(mark({ type: "text", x: r1(W / 2), y: r1(ly - 12), text: spec.lead, cls: "lbl down", enter: "rise", from: spec.beat, until: spec.moveBeat - 1, delay: 0.5 }, spec.beat));
  items.push({ type: "text", x: r1(W / 2), y: r1(ly - 12), text: spec.label, cls: "lbl acc down", enter: "rise", from: spec.moveBeat, delay: r1(0.2 + steps * HOP) });
  let H = ly + 14;
  if (spec.result) {
    items.push({ type: "text", x: r1(W / 2), y: r1(ly + 20), text: spec.result.text, ...(spec.result.sup ? { sup: spec.result.sup } : {}), cls: "lbl big down", enter: "rise", from: spec.result.beat, vars: growDown(1.3) });
    H = ly + 50;
  }
  return { kind: "scene", family: "decimal-shift", width: r1(W), height: H, items: lightSteps(items, it => (lit.has(it) ? [lit.get(it)!] : null), Math.max(spec.moveBeat, spec.result?.beat ?? 0)), alt: spec.alt };
}
