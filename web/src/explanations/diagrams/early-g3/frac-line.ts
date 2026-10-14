// A number line for fractions: 0 to `wholes`, each whole cut into `den` equal spaces. The spaces of the first whole
// can be numbered, hops can count pieces from 0 to the point, and the point can be named as a stacked fraction.
import type { SceneDiagram } from "../scene/schema";
import { frame, M, path, seg, t, type Draft } from "../geo/kit";
import { growDown, roomLeft, thinOut } from "../scene/picture-system";

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

/**
 * Drawn at about a phone's picture width (the line 300 long), so its labels laid out at their phone size land where they
 * are drawn; on a tablet it grows to its box and its text grows less (SceneDiagram). Labels are held by the edge nearest
 * what they name (.up / .down) so the phone floor grows them away from it.
 */
const L = 300;

export function buildFracLine(s: FracLineSpec): SceneDiagram {
  const n = s.den * s.wholes, px = L / n;
  const X = (k: number) => k * px;
  const items: Draft[] = [seg([-14, 0], [L + 14, 0], "ax", { enter: "fade" })];
  for (let k = 0; k <= n; k++) {
    const whole = k % s.den === 0;
    items.push(seg([X(k), whole ? -11 : -7], [X(k), whole ? 11 : 7], whole ? "ax" : "tk", { enter: "fade", delay: Math.round(k * 0.02 * 100) / 100 }));
    if (whole) items.push(t(X(k), 14, String(k / s.den), "lbl pw down", { enter: "fade" }));
  }
  if (s.spacesBeat != null) {
    // a space's number stands over it; where the floor grows them into each other every other one fades (1 always shows)
    for (let k = 0; k < s.den; k++) {
      const level = (k + 1) & -(k + 1), fade = k ? { vars: thinOut(roomLeft(level * px, String(k + 1).length, 15)) } : {};
      items.push(seg([X(k) + 3, 0], [X(k + 1) - 3, 0], "hl", { from: s.spacesBeat, until: s.spacesBeat, enter: "growx", delay: Math.round(k * 0.2 * 100) / 100 }));
      items.push(t(X(k + 0.5), -9, String(k + 1), "sm up", { from: s.spacesBeat, until: s.spacesBeat, enter: "rise", delay: Math.round(k * 0.2 * 100) / 100, ...fade }));
    }
  }
  if (s.hopsBeat != null) {
    const hh = Math.min(34, px * 0.45 + 8);
    for (let k = 0; k < s.at; k++) {
      const x0 = X(k), x1 = X(k + 1);
      items.push(path([M([x0, -2]), { c: "Q", q: [(x0 + x1) / 2, -2 - 2 * hh], p: [x1, -2] }], "ln", { from: s.hopsBeat, enter: "draw", delay: Math.round(k * 0.25 * 100) / 100 }));
      if (px >= 26) items.push(t((x0 + x1) / 2, -hh - 4, String(k + 1), "xs up", { from: s.hopsBeat, enter: "rise", delay: Math.round(k * 0.25 * 100) / 100 }));
    }
  }
  // the point itself, on top of the hops
  items.push({ type: "circle", cx: X(s.at), cy: 0, r: 8, cls: "dota", enter: "pop" } as Draft);
  if (s.nameBeat != null) {
    // the stacked fraction under the whole numbers: its top stands on the bar and its bottom hangs from it, so the two
    // never meet; the whole fraction moves down by what the whole numbers' row and its own top grow on a phone
    const x = X(s.at), bar = 68, down = growDown(2);
    items.push(seg([x, 14], [x, bar - 27], "wire", { from: s.nameBeat, enter: "draw" }));
    items.push(t(x, bar - 3, String(s.at), "lbl acc up", { from: s.nameBeat, enter: "rise", vars: down }));
    items.push({ ...seg([x - 13, bar], [x + 13, bar], "ax thin", { from: s.nameBeat, enter: "draw" }), vars: down } as Draft);
    items.push(t(x, bar + 3, String(s.den), "lbl acc down", { from: s.nameBeat, enter: "rise", vars: down }));
  }
  return frame("frac-line", items, s.alt, 14, { w: L + 40 });
}
