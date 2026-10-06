// A number line for fractions: 0 to `wholes`, each whole cut into `den` equal spaces. The spaces of the first whole
// can be numbered, hops can count pieces from 0 to the point, and the point can be named as a stacked fraction.
import type { SceneDiagram } from "../scene/schema";
import { frame, M, path, seg, t, type Draft } from "../geo/kit";

export interface FracLineSpec {
  den: number;
  wholes: number;
  /** the point, in pieces from 0 (a of a/den) */
  at: number;
  /** beat the spaces of the first whole are numbered 1, 2, 3, … (omit to skip) */
  spacesBeat?: number;
  /** beat the hops from 0 to the point appear (omit to skip) */
  hopsBeat?: number;
  /** beat the point is named a/den (omit to skip) */
  nameBeat?: number;
  alt: string;
}

export function buildFracLine(s: FracLineSpec): SceneDiagram {
  const n = s.den * s.wholes, L = 460, px = L / n;
  const X = (k: number) => k * px;
  const items: Draft[] = [seg([-14, 0], [L + 14, 0], "ax", { enter: "fade" })];
  for (let k = 0; k <= n; k++) {
    const whole = k % s.den === 0;
    items.push(seg([X(k), whole ? -11 : -7], [X(k), whole ? 11 : 7], whole ? "ax" : "tk", { enter: "fade", delay: Math.round(k * 0.02 * 100) / 100 }));
    if (whole) items.push(t(X(k), 30, String(k / s.den), "lbl pw", { enter: "fade" }));
  }
  if (s.spacesBeat != null) {
    for (let k = 0; k < s.den; k++) {
      items.push(seg([X(k) + 3, 0], [X(k + 1) - 3, 0], "hl", { from: s.spacesBeat, until: s.spacesBeat, enter: "growx", delay: Math.round(k * 0.2 * 100) / 100 }));
      items.push(t(X(k + 0.5), -18, String(k + 1), "sm", { from: s.spacesBeat, until: s.spacesBeat, enter: "rise", delay: Math.round(k * 0.2 * 100) / 100 }));
    }
  }
  if (s.hopsBeat != null) {
    const hh = Math.min(34, px * 0.45 + 8);
    for (let k = 0; k < s.at; k++) {
      const x0 = X(k), x1 = X(k + 1);
      items.push(path([M([x0, -2]), { c: "Q", q: [(x0 + x1) / 2, -2 - 2 * hh], p: [x1, -2] }], "ln", { from: s.hopsBeat, enter: "draw", delay: Math.round(k * 0.25 * 100) / 100 }));
      if (px >= 26) items.push(t((x0 + x1) / 2, -hh - 14, String(k + 1), "xs", { from: s.hopsBeat, enter: "rise", delay: Math.round(k * 0.25 * 100) / 100 }));
    }
  }
  // the point itself, on top of the hops
  items.push({ type: "circle", cx: X(s.at), cy: 0, r: 8, cls: "dota", enter: "pop" } as Draft);
  if (s.nameBeat != null) {
    const x = X(s.at), y = 62;
    items.push(seg([x, 14], [x, y - 22], "wire", { from: s.nameBeat, enter: "draw" }));
    items.push(t(x, y - 10, String(s.at), "lbl acc", { from: s.nameBeat, enter: "rise" }));
    items.push(seg([x - 13, y + 2], [x + 13, y + 2], "ax thin", { from: s.nameBeat, enter: "draw" }));
    items.push(t(x, y + 15, String(s.den), "lbl acc", { from: s.nameBeat, enter: "rise" }));
  }
  return frame("frac-line", items, s.alt, 14, { w: 540 });
}
