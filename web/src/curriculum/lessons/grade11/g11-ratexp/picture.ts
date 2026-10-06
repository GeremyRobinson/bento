// The g11-ratexp picture (Curriculum fixes-02, Part B): the bottom of the exponent splits the base into that many equal
// factors and the root picks one; the top says how many of those factors to multiply. No division sign is ever drawn.
import { buildFactorChips, type ChipFrame, type FChip } from "../../../../explanations/diagrams/algebra/chips";
import type { SceneDiagram } from "../../../../explanations/diagrams/scene/schema";
import { big, supText } from "../../algebra-kit/steps";

export function rationalExponentPicture(o: { n: number; m: number; r: number; base: number; value: number }): SceneDiagram {
  const { n, m, r, base, value } = o, R = String(r), sign = n === 2 ? "√" : "∛";
  const width = Math.max(n, m) - 1, mid = width / 2;
  const head = { row: -0.2, col: mid, text: String(base), sup: `${m}/${n}`, cls: "lbl big pw" };
  const factors = (extra: (i: number) => Partial<FChip> = () => ({})): FChip[] => Array.from({ length: n }, (_, i) => ({ row: 1, col: i, text: R, part: "p0", ...extra(i) }));
  const split = { row: 1, from: 0, to: n - 1, label: `${Array(n).fill(R).join(" × ")} = ${base}`, part: "p0" };
  const lifted: FChip = { row: 2.3, col: 0, text: R, part: "pq" };
  const frames: ChipFrame[] = [
    {
      chips: [{ row: 1, col: (n - 1) / 2 - 0.5, span: 2, text: String(base), part: "pq", at: 0.2, leave: 1.2 }, ...factors(i => ({ at: 1.3 + 0.3 * i }))],
      brackets: [{ ...split, at: 1.4 + 0.3 * n }],
      labels: [head, { row: 0.4, col: mid, text: `bottom ${n}: ${n} equal factors`, cls: "sm pw", at: 0.6 }],
    },
    {
      chips: [...factors(i => (i ? {} : { cut: true })), { ...lifted, from: [1, 0], at: 0.3 }],
      brackets: [split],
      labels: [head, { row: 2.3, col: 0.65, text: `${sign}${base} = ${R}`, cls: "lbl big acc start", at: 1.2 }],
    },
    {
      chips: [...factors(i => (i ? {} : { cut: true })), lifted, ...Array.from({ length: m }, (_, i): FChip => ({ row: 3.4, col: i, text: R, part: "p1", from: [2.3, 0], at: 0.3 + 0.35 * i }))],
      brackets: [split, { row: 3.4, from: 0, to: m - 1, label: `top ${m}: ${m} ${m === 1 ? "factor" : "factors"}`, part: "p1", at: 0.5 + 0.35 * m }],
      labels: [head, { row: 2.3, col: 0.65, text: `${sign}${base} = ${R}`, cls: "lbl big pw start" },
        { row: 3.4, col: m - 0.35, text: `${R}${supText(m)} = ${big(value)}`, cls: "lbl big acc start", at: 0.9 + 0.35 * m }],
    },
  ];
  return buildFactorChips(frames, `${base} to the ${m}/${n}: ${base} is ${n} equal factors of ${R}; one of them, ${R}, is the ${n === 2 ? "square" : "cube"} root, and ${m} of them multiply to ${big(value)}.`);
}
