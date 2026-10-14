// A cylinder, or a cone inside its cylinder, drawn with the problem's radius and height in proportion.
import type { SceneDiagram } from "../scene/schema";
import { ellipse, frame, path, seg, t, M, L, type Draft } from "../geo/kit";
import { stackRows } from "../scene/picture-system";

export interface CylinderSpec {
  cone: boolean;
  r: number; h: number;
  /** lines of working beside the solid, each from its beat */
  notes: { text: string; from: number; acc?: boolean }[];
  /** beat the base is shaded (its area) and the beat the solid fills */
  baseBeat: number; fillBeat: number;
  alt: string;
}

export function buildCylinder(s: CylinderSpec): SceneDiagram {
  const { r, h } = s;
  if (!(r > 0 && h > 0)) throw new Error("radius and height must be positive");
  // drawn at about a phone strip's size (labels laid out at their phone size land where they are drawn)
  const u = Math.min(110 / (2 * r), 140 / h);
  const rx = r * u, ry = Math.max(6, rx * 0.28), H = h * u;
  const items: Draft[] = [];
  // the base, shaded at its beat: its area times the height is the volume
  items.push(path(ellipse([0, 0], rx, ry), "fill", { from: s.baseBeat, enter: "fade" }));
  if (s.cone) {
    items.push(path([M([-rx, 0]), L([-rx, -H]), M([rx, 0]), L([rx, -H])], "ln faint dash", { enter: "fade" }));
    items.push(path(ellipse([0, -H], rx, ry), "ln faint dash", { enter: "fade" }));
    items.push(path([M([-rx, 0]), L([0, -H]), L([rx, 0]), { c: "Z" }], "fillsoft", { from: s.fillBeat, enter: "fade" }));
    items.push(path([M([-rx, 0]), L([0, -H]), L([rx, 0])], "ln", { enter: "draw" }));
  } else {
    items.push(path([M([-rx, 0]), L([-rx, -H]), L([rx, -H]), L([rx, 0]), { c: "Z" }], "fillsoft", { from: s.fillBeat, enter: "growy" }));
    items.push(path([M([-rx, 0]), L([-rx, -H]), M([rx, 0]), L([rx, -H])], "ln", { enter: "draw" }));
    items.push(path(ellipse([0, -H], rx, ry), "ln", { enter: "fade", delay: 0.4 }));
  }
  items.push(path(ellipse([0, 0], rx, ry), "ln", { enter: "fade" }));
  // radius along the base, height up the left side (the working stands on the right)
  items.push(seg([0, 0], [rx, 0], "ln2", { enter: "draw", delay: 0.6 }));
  items.push(t(rx / 2, ry + 4, `r = ${r}`, "lbl acc down", { enter: "rise", delay: 0.8 }));
  items.push(seg([-rx - 16, 0], [-rx - 16, -H], "tk", { enter: "draw", delay: 0.8 }));
  items.push(t(-rx - 24, -H / 2, `h = ${h}`, "lbl acc end", { enter: "rise", delay: 1 }));
  // the working stands beside the solid, centred on its middle; on a phone the floor spreads it from the middle
  // (stackRows), and in practice it leaves for the work list (.cap)
  const x0 = rx + 26, P = 25;
  const rows = stackRows(s.notes.map(n => `lbl${n.acc ? " acc" : ""}`), P, "mid");
  s.notes.forEach((n, i) => items.push(t(x0, -H / 2 + (i - (s.notes.length - 1) / 2) * P, n.text, `lbl start cap${n.acc ? " acc" : ""}`, { from: n.from, enter: "rise", ...(rows[i]!.transform ? { vars: rows[i]! } : {}) })));
  // the working is wider than the solid: on the narrowest phone it may take more of the drawing (grow)
  return frame("cylinder", items, s.alt, 14, { grow: 1.9 });
}
