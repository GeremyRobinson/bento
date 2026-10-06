// Number lines for 2nd grade: a skip-counting line with one equal hop per count,
// and an open number line (not to scale) that hops by hundreds, then tens, then ones.
import type { SceneDiagram } from "../scene/schema";
import { frame, path, t, M, type Draft, type Pt } from "../geo/kit";
import { circle, line } from "./kit";
import { tw } from "./blocks";

const arcSegs = (x1: number, x2: number, h: number) => [M([x1, 0] as Pt), { c: "Q" as const, q: [(x1 + x2) / 2, -2 * h] as Pt, p: [x2, 0] as Pt }];

export interface SkipLineSpec {
  /** the counts in order; the first `given` are shown from the start */
  values: number[];
  given: number;
  /** the label on every hop, e.g. "+5" */
  hop: string;
  /** beat the hops between the given counts are drawn */
  jumpBeat: number;
  /** beat each hidden count is reached, in order */
  revealBeats: number[];
  alt: string;
}

const GAP = 84;

/** Equal hops between the counts; the hidden counts show "?" until their hop lands. */
export function buildSkipLine(spec: SkipLineSpec): SceneDiagram {
  const { values, given } = spec;
  if (spec.revealBeats.length !== values.length - given) throw new Error("skip line: one beat per hidden count");
  const x = (i: number) => i * GAP, H = 30;
  const items: Draft[] = [line(-30, 0, x(values.length - 1) + 30, 0, "ax", { enter: "fade" })];
  values.forEach((v, i) => {
    items.push(line(x(i), -8, x(i), 8, "tk"));
    if (i < given) {
      items.push(t(x(i), 26, String(v), "sm"));
      items.push(circle(x(i), 0, 7, "dotp", { enter: "pop", delay: 0.15 * i }));
    } else {
      const beat = spec.revealBeats[i - given]!;
      items.push(t(x(i), 26, "?", "sm acc", { until: beat - 1 }));
      items.push(t(x(i), 28, String(v), "lbl acc", { from: beat, enter: "rise", delay: 0.6 }));
    }
    if (i === 0) return;
    const beat = i < given ? spec.jumpBeat : spec.revealBeats[i - given]!;
    items.push(path(arcSegs(x(i - 1), x(i), H), "ln", { from: beat, enter: "draw", delay: i < given ? 0.3 * (i - 1) : 0 }));
    items.push(t((x(i - 1) + x(i)) / 2, -H - 14, spec.hop, "lbl", { from: beat, enter: "rise", delay: i < given ? 0.3 * (i - 1) + 0.3 : 0.3 }));
    if (i >= given) items.push(circle(x(i), 0, 7, "dota", { from: beat, enter: "pop", delay: 0.55 }));
  });
  return frame("early-g2-skip", items, spec.alt, 14, { w: 360 });
}

export interface OpenLineSpec {
  start: number;
  /** each hop: where it lands, its label ("+100") and its beat */
  hops: { to: number; label: string; beat: number }[];
  total: string;
  totalBeat: number;
  alt: string;
}

/**
 * An open number line: hops are wider for bigger jumps but never too small to read.
 * Adding hops go right; taking away hops go left.
 */
export function buildOpenLine(spec: OpenLineSpec): SceneDiagram {
  const vals = [spec.start, ...spec.hops.map(h => h.to)];
  const deltas = spec.hops.map((h, i) => h.to - vals[i]!);
  const sum = deltas.reduce((s, d) => s + Math.abs(d), 0) || 1;
  const widths = deltas.map(d => Math.max(96, (360 * Math.abs(d)) / sum));
  const xs = [0];
  deltas.forEach((d, i) => xs.push(xs[i]! + Math.sign(d || 1) * widths[i]!));
  const lo = Math.min(...xs), hi = Math.max(...xs);
  const items: Draft[] = [line(lo - 30, 0, hi + 30, 0, "ax", { enter: "fade" })];
  items.push(circle(xs[0]!, 0, 7, "dotp", { enter: "pop" }), t(xs[0]!, 28, String(spec.start), "sm"));
  spec.hops.forEach((h, i) => {
    const x1 = xs[i]!, x2 = xs[i + 1]!, ht = Math.min(48, Math.abs(x2 - x1) * 0.3 + 14);
    const last = i === spec.hops.length - 1;
    // the start is part 1 (blue); every hop is what's added or taken away (part 2, orange), its label too
    items.push(path(arcSegs(x1, x2, ht), "ln p1", { from: h.beat, enter: "draw" }));
    items.push(t((x1 + x2) / 2, -ht - 16, h.label, "lbl p1", { from: h.beat, enter: "rise", delay: 0.3 }));
    items.push(circle(x2, 0, 7, last ? "dota" : "dotp", { from: h.beat, enter: "pop", delay: 0.55 }));
    items.push(t(x2, 28, String(h.to), last ? "lbl acc" : "sm", { from: h.beat, enter: "rise", delay: 0.6 }));
  });
  items.push(t((lo + hi) / 2, 70, spec.total, "lbl big acc", { from: spec.totalBeat, enter: "rise" }));
  return frame("early-g2-open-line", items, spec.alt, 14, { w: Math.max(360, tw(spec.total, 22) + 20) });
}
