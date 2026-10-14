// Two similar triangles side by side, the big one exactly k times the small one, with matching sides labelled.
import type { SceneDiagram } from "../scene/schema";
import { frame, poly, t, type Draft, type Pt } from "../geo/kit";
import { stackRows } from "../scene/picture-system";

export interface SimilarSpec {
  /** the small triangle's two sides (drawn up and across) and the scale factor */
  a: number; b: number; k: number;
  /** labels: the big triangle's known side and its missing side (before and after it is found) */
  bigA: string; bigB: string;
  factorBeat: number; missingBeat: number;
  factorNote: string; missingNote: string;
  alt: string;
}

export function buildSimilar(s: SimilarSpec): SceneDiagram {
  const { a, b, k } = s;
  if (!(a > 0 && b > 0 && k > 0)) throw new Error("sides and factor must be positive");
  // drawn at about a phone strip's size, so labels laid out at their phone size land where they are drawn
  const gap = 50;
  const u = Math.min(110 / (a * Math.max(k, 1)), 250 / (b * (1 + k)));
  const tri = (x0: number, sc: number): Pt[] => [[x0, 0], [x0 + b * u * sc, 0], [x0, -a * u * sc]];
  const x1 = b * u + gap;
  const items: Draft[] = [
    poly(tri(0, 1), "ln fillsoft", { enter: "draw" }),
    t(-10, (-a * u) / 2, String(a), "lbl end", { enter: "rise", delay: 0.4 }),
    t((b * u) / 2, 6, String(b), "lbl down", { enter: "rise", delay: 0.4 }),
    poly(tri(x1, k), "ln2 fillsoft", { enter: "draw", delay: 0.6 }),
    t(x1 - 10, (-a * u * k) / 2, s.bigA, "lbl acc end", { enter: "rise", delay: 1 }),
    t(x1 + (b * u * k) / 2, 6, "?", "lbl acc down", { until: s.missingBeat - 1, enter: "rise", delay: 1 }),
    t(x1 + (b * u * k) / 2, 6, s.bigB, "lbl acc down", { from: s.missingBeat, enter: "rise" }),
  ];
  // the working stands on its bottom edge above the triangles, the newest line on top; on a phone the floor grows the
  // lines up and apart (stackRows), and in practice they leave for the work list (.cap)
  const top = -a * u * Math.max(k, 1) - 12, rows = stackRows(["lbl acc", "lbl acc"], 25, "bottom");
  const mid = (x1 + b * u * k) / 2;
  items.push(t(mid, top, s.factorNote, "lbl acc up cap", { from: s.factorBeat, enter: "rise" }));
  items.push(t(mid, top - 25, s.missingNote, "lbl acc up cap", { from: s.missingBeat, enter: "rise", vars: rows[0]! }));
  return frame("similar", items, s.alt, 14, { w: 240 });
}
