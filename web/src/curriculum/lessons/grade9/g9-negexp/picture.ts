// The g9-negexp picture (Curriculum fixes-02, Part B): aⁿ as n chips of a. Every step down in the exponent takes one
// chip away (÷ a), down to an empty row: a⁰ = 1. Past zero the chips come back under a fraction bar: a⁻ⁿ = 1/aⁿ.
import { buildFactorChips, type ChipFrame, type FChip, type FLabel } from "../../../../explanations/diagrams/algebra/chips";
import type { SceneDiagram } from "../../../../explanations/diagrams/scene/schema";
import { supText } from "../../algebra-kit/steps";

export function negativeExponentPicture(o: { a: number; n: number; power: number }): SceneDiagram {
  const { a, n, power } = o, mid = (n - 1) / 2, A = String(a);
  const pw = (e: number) => `${A}${supText(e)}`;
  const chips = (extra: (k: number) => Partial<FChip> = () => ({})): FChip[] => Array.from({ length: n }, (_, k) => ({ row: 1, col: k, text: A, part: "p0", ...extra(k) }));
  // counting down: the k-th chip from the right goes at T(k), and the value line follows
  const T = (k: number) => 0.7 + 1.1 * k;
  const down: FLabel[] = Array.from({ length: n + 1 }, (_, k) => {
    const e = n - k, last = k === n;
    return { row: 2.15, col: mid, text: `${pw(e)} = ${a ** e}`, cls: last ? "lbl big acc" : "lbl big pw", ...(k ? { at: T(k - 1) + 0.25 } : {}), ...(last ? {} : { leave: T(k) + 0.2 }) };
  });
  const divide: FLabel[] = Array.from({ length: n }, (_, k) => ({ row: 0.42, col: n - 1 - k, text: `÷ ${A}`, cls: "sm pq", at: T(k) - 0.45, leave: T(k) + 0.35 }));
  const one = (extra: Partial<FChip> = {}): FChip => ({ row: 1, col: mid, text: "1", part: "pq", ghost: true, ...extra });
  const S = (k: number) => 0.8 + 1.0 * k;
  const up: FLabel[] = Array.from({ length: n }, (_, k) => {
    const e = k + 1, last = k === n - 1;
    return { row: 3.1, col: mid, text: `${A}${supText(-e)} = 1/${a ** e}`, cls: last ? "lbl big acc" : "lbl big pw", at: S(k) + 0.2, ...(last ? {} : { leave: S(k + 1) + 0.1 }) };
  });
  const frames: ChipFrame[] = [
    { chips: chips(k => ({ at: 0.2 + 0.3 * k })), labels: [{ row: 2.15, col: mid, text: `${pw(n)} = ${power}`, cls: "lbl big pw", at: 0.4 + 0.3 * n }] },
    { chips: [...chips(k => ({ leave: T(n - 1 - k) })), one({ at: T(n - 1) + 0.3 })], labels: [...down, ...divide] },
    {
      chips: [one(), ...Array.from({ length: n }, (_, k): FChip => ({ row: 2, col: k, text: A, part: "p1", at: S(k) }))],
      bars: [{ row: 1, from: Math.min(0, mid), to: Math.max(n - 1, mid), at: 0.3 }],
      labels: [{ row: 0.35, col: mid, text: "past 0: under the bar", cls: "sm pw", at: 0.3 }, ...up],
    },
  ];
  return buildFactorChips(frames, `${pw(n)} as ${n} chip${n === 1 ? "" : "s"} of ${A} makes ${power}. Each step down takes one ${A} away, down to ${pw(0)} = 1; then the ${A}'s come back under a fraction bar: ${A}${supText(-n)} = 1/${power}.`);
}
