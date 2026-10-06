// The g11-expeq picture (Curriculum fixes-02, Part B): the value written out as k chips of the base shows it is bᵏ;
// then x + c spans the k chips, and taking away the c chips (or adding the missing ones) leaves x.
import { buildFactorChips, type ChipFrame, type FChip, type FBracket } from "../../../../explanations/diagrams/algebra/chips";
import type { SceneDiagram } from "../../../../explanations/diagrams/scene/schema";
import { formatNumber as f } from "../../../schemas/math-text";
import { big, supText } from "../../algebra-kit/steps";

export function exponentialPicture(o: { b: number; c: number; k: number; x: number; value: number }): SceneDiagram {
  const { b, c, k, x, value } = o, B = String(b), mid = (k - 1) / 2;
  const cTxt = `${c < 0 ? "−" : "+"} ${Math.abs(c)}`;
  const head = `${B}ˣ${c < 0 ? "⁻" : "⁺"}${supText(Math.abs(c))} = ${big(value)}`;
  const row = (extra: (i: number) => Partial<FChip> = () => ({})): FChip[] => Array.from({ length: k }, (_, i) => ({ row: 1, col: i, text: B, part: "p0", ...extra(i) }));
  const span = Math.max(2, Math.min(k, Math.ceil((big(value).length * 13 + 20) / 46)));
  const valueChip: FChip = { row: 1, col: mid - (span - 1) / 2, span, text: big(value), part: "pq" };
  const whole: FBracket = { row: 1, from: 0, to: k - 1, label: `x ${cTxt}`, part: "p1" };
  // the last beat: what x is once the c chips are taken away (or the missing ones put back)
  let solve: ChipFrame;
  if (c > 0) {
    const kept = Math.max(0, k - c), extra = Math.max(0, c - k);
    solve = {
      chips: [
        ...row(i => (i < kept ? {} : { leave: 0.3 })),
        ...Array.from({ length: k - kept }, (_, j): FChip => ({ row: 1, col: kept + j + 0.5, text: B, part: "pq", from: [1, kept + j], at: 0.3 })),
        // more c chips than there are: the extra ones are x below zero, struck through
        ...Array.from({ length: extra }, (_, j): FChip => ({ row: 1, col: k + j + 0.5, text: B, part: "pq", ghost: true, at: 1.1 + 0.25 * j, strike: 1.4 + 0.25 * j })),
      ],
      brackets: [
        ...(kept ? [{ row: 1, from: 0, to: kept - 1, label: `x = ${f(x)}`, part: "p0", at: 1.2 }] : []),
        { row: 1, from: kept + 0.5, to: k - 1 + extra + 0.5, label: `${c}`, part: "pq", at: 0.9 },
      ],
      labels: [{ row: 2.45, col: (k - 1 + extra) / 2, text: `x = ${k} − ${c} = ${f(x)}`, cls: "lbl big acc", at: 1.6 + 0.25 * extra }],
    };
  } else {
    const m = -c;
    solve = {
      chips: [...row(), ...Array.from({ length: m }, (_, j): FChip => ({ row: 1, col: k + j, text: B, part: "pq", ghost: true, at: 0.3 + 0.25 * j }))],
      brackets: [
        { row: 1, from: k, to: k + m - 1, label: `${m} missing`, part: "pq", above: true, at: 0.5 + 0.25 * m },
        { row: 1, from: 0, to: k + m - 1, label: `x = ${f(x)}`, part: "p0", at: 0.8 + 0.25 * m },
      ],
      labels: [{ row: 2.45, col: (k + m - 1) / 2, text: `x = ${k} + ${m} = ${f(x)}`, cls: "lbl big acc", at: 1.2 + 0.25 * m }],
    };
  }
  const top = { row: -0.4, col: mid, text: head, cls: "lbl big pw" };
  const frames: ChipFrame[] = [
    { chips: [{ ...valueChip, at: 0.3 }], labels: [top] },
    {
      chips: [{ ...valueChip, leave: 0.3 }, ...row(i => ({ at: 0.5 + 0.3 * i }))],
      labels: [top, ...Array.from({ length: k }, (_, i) => ({ row: 0.45, col: i, text: String(i + 1), cls: "sm pq", at: 0.65 + 0.3 * i })),
        { row: 2.1, col: mid, text: `${big(value)} = ${B}${supText(k)}`, cls: "lbl big pw", at: 0.8 + 0.3 * k }],
    },
    { chips: row(), brackets: [{ ...whole, at: 0.2 }], labels: [top, { row: 2.45, col: mid, text: `x ${cTxt} = ${k}`, cls: "lbl big pw", at: 0.8 }] },
    { ...solve, labels: [{ ...top }, ...(solve.labels ?? [])] },
  ];
  return buildFactorChips(frames, `${head}: ${big(value)} is ${k} ${B}'s multiplied, so x ${cTxt} = ${k} and x = ${f(x)}.`);
}
