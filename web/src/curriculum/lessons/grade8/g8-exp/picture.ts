// The g8-exp picture (Curriculum fixes-02, Part B): each exponent rule is counting x's once the powers are written out.
// t = 0: a group of a x's next to a group of b; t = 1: a + b x's over a bar, b under it, pairs cancel;
// t = 2: b copies of xᵃ, one row each. The count lands as the new exponent; then every x turns into a 2.
import { buildFactorChips, type ChipFrame, type FChip, type FLabel } from "../../../../explanations/diagrams/algebra/chips";
import type { SceneDiagram } from "../../../../explanations/diagrams/scene/schema";
import { big, supText } from "../../algebra-kit/steps";

/** Grade 8's second part colour is red (wrong), so the two groups take its first and third. */
const PA = "p0", PB = "p2";

export function exponentRulePicture(o: { t: 0 | 1 | 2; a: number; b: number; e: number; value: number; shown: string }): SceneDiagram {
  const { t, a, b, e, value, shown } = o;
  const head: FLabel = { row: 0, col: 0, text: shown, cls: "lbl big pw" };
  // where each x sits: [row, col, part, struck]
  const spots: [number, number, string, boolean][] =
    t === 0 ? [...Array.from({ length: a }, (_, k) => [1, k, PA, false] as [number, number, string, boolean]), ...Array.from({ length: b }, (_, k) => [1, a + 0.4 + k, PB, false] as [number, number, string, boolean])]
      : t === 1 ? [...Array.from({ length: a + b }, (_, k) => [1, k, PA, k >= a] as [number, number, string, boolean]), ...Array.from({ length: b }, (_, k) => [2, a + k, PB, true] as [number, number, string, boolean])]
        : Array.from({ length: a * b }, (_, k) => [1 + Math.floor(k / a) * 0.95, k % a, Math.floor(k / a) % 2 ? PB : PA, false] as [number, number, string, boolean]);
  // centre the header over the chips
  const cols = spots.map(s => s[1]), mid = (Math.min(...cols) + Math.max(...cols)) / 2;
  head.col = mid;
  const lastRow = Math.max(...spots.map(s => s[0]));
  const under = lastRow + (t === 0 ? 1.25 : 0.95);
  const xs = (extra: (s: [number, number, string, boolean], k: number) => Partial<FChip> = () => ({})): FChip[] =>
    spots.map((s, k) => ({ row: s[0], col: s[1], text: "x", part: s[2], ...extra(s, k) }));
  // the x's that are left once pairs cancel, in reading order
  const kept = spots.map((s, k) => [s, k] as const).filter(([s]) => !s[3]);
  const brackets = t === 0
    ? [{ row: 1, from: 0, to: a - 1, label: `x${supText(a)}`, part: PA }, { row: 1, from: a + 0.4, to: a + 0.4 + b - 1, label: `x${supText(b)}`, part: PB }]
    : [];
  const rowLabels: FLabel[] = t === 2 ? Array.from({ length: b }, (_, g) => ({ row: 1 + g * 0.95, col: -0.85, text: `x${supText(a)}`, cls: `lbl end ${g % 2 ? PB : PA}` })) : [];
  const bar = t === 1 ? [{ row: 1, from: 0, to: a + b - 1 }] : [];
  const step = Math.min(0.35, 2.8 / spots.length);
  const strikeAt = (k: number) => 0.3 + 0.35 * (k % b);

  const frames: ChipFrame[] = [
    // 0: the problem as written
    { labels: [head] },
    // 1: the x's written out, group by group (over the bar and under it, or a row per copy)
    { labels: [head, ...rowLabels.map(l => ({ ...l, at: 0.2 }))], chips: xs((_, k) => ({ at: 0.15 + step * k })), brackets: brackets.map(br => ({ ...br, at: 0.8 })), bars: bar.map(br => ({ ...br, at: 0 })) },
    // 2: pairs cancel first (t = 1), then the x's that are left are counted; the count is the new exponent
    {
      labels: [head, ...rowLabels,
        ...kept.map(([s], i) => ({ row: s[0] - 0.58, col: s[1], text: String(i + 1), cls: "sm pq", at: (t === 1 ? 0.3 + 0.35 * b + 0.3 : 0.2) + 0.28 * i })),
        { row: under, col: mid, text: `${shown} = x${supText(e)}`, cls: "lbl big acc", at: (t === 1 ? 0.6 + 0.35 * b : 0.2) + 0.28 * kept.length + 0.2 }],
      chips: xs((s, k) => (t === 1 && s[3] ? { strike: strikeAt(k < a + b ? k - a : k - (a + b)) } : {})),
      brackets, bars: bar,
    },
    // 3: try x = 2: every x left turns into a 2
    {
      labels: [head, ...rowLabels, { row: under, col: mid, text: `2${supText(e)} = ${big(value)}`, cls: "lbl big acc", at: 0.3 + 0.18 * kept.length }],
      chips: [
        ...xs((s, k) => (s[3] ? { strike: 0, cut: true } : { leave: 0.1 + 0.18 * kept.findIndex(([, j]) => j === k) })),
        ...kept.map(([s], i) => ({ row: s[0], col: s[1], text: "2", part: s[2], at: 0.1 + 0.18 * i })),
      ],
      brackets, bars: bar,
    },
  ];
  const what = t === 0 ? `${a} x's next to ${b} x's` : t === 1 ? `${a + b} x's over ${b} x's, ${b} pairs cancelling` : `${b} rows of ${a} x's`;
  return buildFactorChips(frames, `${shown} written out as ${what}: ${e} x's, so x${supText(e)}. With x = 2 that is ${big(value)}.`);
}
