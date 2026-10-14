// The pairing picture for arithmetic series (the current app's `pairsViz`): the terms in a row,
// arcs joining first with last, second with second-to-last, ..., each pair making the same total.
import { formatNumber } from "../../../curriculum/schemas/math-text";
import type { SceneDiagram, SceneItem } from "../scene/schema";
import { growDown } from "../scene/picture-system";

export interface PairsInput {
  first: number;
  step: number;
  count: number;
  /** beats: terms shown, last term found, first pair joined, every pair and the total */
  beats: { terms: number; last: number; pair: number; total: number };
}

/** Which terms are drawn: all of them when there are few, otherwise the first three, "…", and the last three. */
export function shownTerms(count: number): (number | null)[] {
  if (count <= 7) return Array.from({ length: count }, (_, k) => k);
  return [0, 1, 2, null, count - 3, count - 2, count - 1];
}

const fmtBig = (n: number) => n.toLocaleString("en-US");

export function buildPairs({ first, step, count, beats: b }: PairsInput): SceneDiagram {
  const term = (k: number) => first + k * step;
  const slots = shownTerms(count);
  const longest = Math.max(...slots.map(k => (k == null ? 1 : formatNumber(term(k)).length)));
  const gapX = Math.max(62, longest * 12 + 22);
  const W = 2 * 40 + (slots.length - 1) * gapX;
  const x = (i: number) => 40 + i * gapX;
  const lastLabel = slots.length - 1;
  const pairTotal = term(0) + term(count - 1), sum = (pairTotal * count) / 2;
  const items: SceneItem[] = [];

  slots.forEach((k, i) => {
    const isLast = k === count - 1 && count > 1;
    // the terms stand on their row (.up) and the term's name hangs under it (.down), so on a phone each grows away from the other
    items.push({ type: "text", x: x(i), y: 160, text: k == null ? "…" : formatNumber(term(k)), cls: isLast ? "lbl acc up" : "lbl up", from: isLast ? b.last : b.terms, enter: "rise", delay: isLast ? 0 : 0.05 * i });
  });
  items.push({ type: "text", x: x(lastLabel), y: 165, text: `term ${count}`, cls: "xs down", from: b.last, enter: "fade" });

  // pairs from the outside in: index i on screen with index (last − i)
  const pairs = Math.floor(slots.length / 2);
  for (let p = 0; p < Math.min(pairs, 3); p++) {
    const a = x(p), c = x(lastLabel - p), h = 84 - p * 22;
    if (slots[p] == null || slots[lastLabel - p] == null) continue;
    items.push({ type: "path", d: `M${a} 130 Q${(a + c) / 2} ${130 - h} ${c} 130`, cls: p ? "ln2" : "ln", from: p ? b.total : b.pair, enter: "draw", delay: p ? 0.4 * (p - 1) : 0 });
    if (!p) items.push({ type: "text", x: (a + c) / 2, y: 130 - h / 2 - 16, text: `each pair makes ${fmtBig(pairTotal)}`, cls: "sm acc", from: b.pair, enter: "rise", delay: 0.3 });
  }
  const total = count % 2 === 0
    ? `${formatNumber(count / 2)} pairs × ${fmtBig(pairTotal)} = ${fmtBig(sum)}`
    : `${formatNumber(count)} × ${fmtBig(pairTotal)} ÷ 2 = ${fmtBig(sum)}`;
  items.push({ type: "text", x: W / 2, y: 186, text: total, cls: "lbl acc down", vars: growDown(0.8), from: b.total, enter: "rise", delay: 0.8 });
  return {
    kind: "scene",
    family: "pairs",
    width: W,
    height: 222,
    items,
    alt: `The ${count} terms ${formatNumber(term(0))} to ${formatNumber(term(count - 1))} paired from the outside in; each pair makes ${formatNumber(pairTotal)}, so the sum is ${formatNumber(sum)}.`,
  };
}
