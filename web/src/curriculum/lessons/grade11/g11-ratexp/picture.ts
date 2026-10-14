// The g11-ratexp picture (Curriculum fixes-02, Part B): the bottom of the exponent splits the base into that many equal
// factors and the root picks one; the top says how many of those factors to multiply. No division sign is ever drawn.
import { buildFactorChips, type ChipFrame, type FChip } from "../../../../explanations/diagrams/algebra/chips";
import type { SceneDiagram } from "../../../../explanations/diagrams/scene/schema";
import { big, supText } from "../../algebra-kit/steps";

export function rationalExponentPicture(o: { n: number; m: number; r: number; base: number; value: number }): SceneDiagram {
  const { n, m, r, base, value } = o, R = String(r), sign = n === 2 ? "√" : "∛";
  // on a phone (its short box) only the power, the root and the answer are written: the working under the brackets is
  // what the step under the picture says, and with it the chips had no room left (Review 1c74c20)
  // the power and the note on what its bottom does share the top line (the power at the left, over the chips it splits),
  // so a phone's short box has room for every row (the note starts past the power at a phone's label size)
  const head = { row: 0.1, col: -0.4, text: String(base), sup: `${m}/${n}`, cls: "lbl big pw start" };
  const factors = (extra: (i: number) => Partial<FChip> = () => ({})): FChip[] => Array.from({ length: n }, (_, i) => ({ row: 1, col: i, text: R, part: "p0", ...extra(i) }));
  const split = { row: 1, from: 0, to: n - 1, label: `${Array(n).fill(R).join(" × ")} = ${base}`, part: "p0", long: true };
  // the root steps out to the right of its row (not down a row), so the picture lies wider than tall like the box it
  // sits in and a phone draws it near its own size
  const L = n + 0.6, lifted: FChip = { row: 1, col: L, text: R, part: "pq" };
  const frames: ChipFrame[] = [
    {
      chips: [{ row: 1, col: (n - 1) / 2 - 0.5, span: 2, text: String(base), part: "pq", at: 0.2, leave: 1.2 }, ...factors(i => ({ at: 1.3 + 0.3 * i }))],
      brackets: [{ ...split, at: 1.4 + 0.3 * n }],
      labels: [head, { row: 0.1, col: 0.2 + 0.7 * (String(base).length + 0.65 * `${m}/${n}`.length), text: `bottom ${n}: ${n} equal factors`, cls: "sm pw start", at: 0.6, long: true }],
    },
    {
      chips: [...factors(i => (i ? {} : { cut: true })), { ...lifted, from: [1, 0], at: 0.3 }],
      brackets: [split],
      labels: [head, { row: 1, col: L + 0.65, text: `${sign}${base} = ${R}`, cls: "lbl big acc start", at: 1.2 }],
    },
    {
      chips: [...factors(i => (i ? {} : { cut: true })), lifted, ...Array.from({ length: m }, (_, i): FChip => ({ row: 2.4, col: i, text: R, part: "p1", from: [1, L], at: 0.3 + 0.35 * i }))],
      brackets: [split, { row: 2.4, from: 0, to: m - 1, label: `top ${m}: ${m} ${m === 1 ? "factor" : "factors"}`, part: "p1", at: 0.5 + 0.35 * m, long: true }],
      labels: [head, { row: 1, col: L + 0.65, text: `${sign}${base} = ${R}`, cls: "lbl big pw start" },
        { row: 2.4, col: m - 0.35, text: `${R}${supText(m)} = ${big(value)}`, cls: "lbl big acc start", at: 0.9 + 0.35 * m }],
    },
  ];
  return buildFactorChips(frames, `${base} to the ${m}/${n}: ${base} is ${n} equal factors of ${R}; one of them, ${R}, is the ${n === 2 ? "square" : "cube"} root, and ${m} of them multiply to ${big(value)}.`);
}
