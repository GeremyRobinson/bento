// Circles: the circumference unrolled into diameters, the area as r × r squares, a sector or arc as a fraction
// of the turn, angles measured in pieces of a half turn (radians), and an angle on the unit circle.
// Angles are drawn at their real size, counterclockwise from the right as in math class; labels come from the problem.
import type { SceneDiagram } from "../scene/schema";
import { angleLabelAt, arc, frame, path, polar, seg, t, M, L, Z, type Draft, type Pt } from "../geo/kit";
import { stackRows } from "../scene/picture-system";

const O: Pt = [0, 0];
const circle = (r: number, cls: string, extra: Partial<Draft> = {}): Draft => ({ type: "circle", cx: 0, cy: 0, r, cls, ...extra }) as Draft;
/** Lines of working in a column beside the picture, each from its own beat, centred on the circle's middle (y 0). On a
 * phone the label floor spreads them from the middle (stackRows); in practice they leave for the work list (.cap). */
const PITCH = 25;
const column = (x: number, lines: { text: string; cls: string; from: number; until?: number }[]): Draft[] => {
  const vars = stackRows(lines.map(l => l.cls), PITCH, "mid"), y0 = -((lines.length - 1) * PITCH) / 2;
  return lines.map((l, i) => t(x, y0 + i * PITCH, l.text, `${l.cls} start cap`, { from: l.from, ...(l.until != null ? { until: l.until } : {}), enter: "rise", delay: 0.2, ...(vars[i]!.transform ? { vars: vars[i]! } : {}) }));
};
/** A worked line broken before its last "=": the column stays narrow enough on a phone to leave the circle the room
 * ("3.14 × 9" / "= 28.26"). */
const broken = (text: string, cls: string, from: number) => {
  const k = text.lastIndexOf(" = ");
  return k < 0 ? [{ text, cls, from }] : [{ text: text.slice(0, k), cls, from }, { text: text.slice(k + 1), cls, from }];
};
/** The circle's radius: drawn at about a phone's picture size, so the column of working beside it (at the label floor)
 * leaves the circle the most of a phone's strip; on a tablet the circle grows past its text. */
const RC = 70;

export interface CircumferenceSpec {
  r: number; d: number; c: number;
  /** "3.14", the π the lesson uses */
  pi: string;
  diameterBeat: number; aroundBeat: number;
  alt: string;
}

/** The circle rolls out into a line about 3.14 diameters long. Lengths in the picture are true to each other. */
export function buildCircumference(s: CircumferenceSpec): SceneDiagram {
  const R = 56, len = 2 * Math.PI * R, y = R + 44;
  const items: Draft[] = [
    circle(R, "ln", { enter: "draw slow" }),
    seg(O, [R, 0], "ln2", { until: s.diameterBeat - 1, enter: "draw", delay: 0.6 }),
    t(R / 2, 14, `r = ${s.r}`, "lbl acc", { until: s.diameterBeat - 1, enter: "rise", delay: 0.8 }),
    seg([-R, 0], [R, 0], "ln2", { from: s.diameterBeat, enter: "draw" }),
    t(0, -14, `d = ${s.d}`, "lbl acc", { from: s.diameterBeat, enter: "rise", delay: 0.3 }),
    seg([-R, y], [-R + len, y], "ln", { from: s.aroundBeat, enter: "draw slow" }),
  ];
  for (let i = 0; i < 3; i++) {
    items.push(seg([-R + i * 2 * R, y + 16], [-R + (i + 1) * 2 * R - 3, y + 16], "ln2", { from: s.aroundBeat, enter: "draw", delay: 1 + i * 0.4 }));
    items.push(t(-R + i * 2 * R + R, y + 34, "d", "sm acc", { from: s.aroundBeat, enter: "rise", delay: 1.2 + i * 0.4 }));
  }
  items.push(seg([-R + 6 * R, y + 16], [-R + len, y + 16], "ln2", { from: s.aroundBeat, enter: "draw", delay: 2.2 }));
  items.push(t(-R + 6 * R + (len - 6 * R) / 2, y + 34, "0.14", "xs acc", { from: s.aroundBeat, enter: "rise", delay: 2.4 }));
  items.push(t(-R + len / 2, y - 22, `about ${s.pi} diameters = ${s.c}`, "lbl", { from: s.aroundBeat, enter: "rise", delay: 2.8 }));
  return { ...frame("circle", items, s.alt), camera: true };
}

export interface CircleAreaSpec {
  r: number; r2: number; area: number; pi: string;
  squareBeat: number; areaBeat: number;
  alt: string;
}

/** The r × r square on the radius; the circle holds about 3.14 of them. */
export function buildCircleArea(s: CircleAreaSpec): SceneDiagram {
  const R = RC;
  const items: Draft[] = [
    circle(R, "fill", { enter: "pop" }),
    // the square goes under the circle's edge and the radius, so the whole circle and the radius (its side) stay in view
    { type: "rect", x: 0, y: -R, w: R, h: R, cls: "sq", from: s.squareBeat, enter: "pop" } as Draft,
    // where the square overlaps the circle (a quarter of it) takes the stronger fill, as any overlap does (G 2026-10-14)
    path([M(O), ...arc(O, R, 0, 90, true), Z], "overlap", { from: s.squareBeat, enter: "pop" }),
    { type: "rect", x: 0, y: -R, w: R, h: R, cls: "sq lineonly", from: s.squareBeat, enter: "pop" } as Draft,
    circle(R, "ln", { enter: "draw" }),
    seg(O, [R, 0], "ln2", { enter: "draw", delay: 0.6 }),
    t(R / 2, 5, `r = ${s.r}`, "lbl acc down", { enter: "rise", delay: 0.8 }),
    // the square's sum and its area meet at the square's middle, each held by the edge facing the other (up / down),
    // so the floor grows them apart, toward the square's own edges
    t(R / 2, -R / 2 - 2, `${s.r} × ${s.r}`, "sm up onstep", { from: s.squareBeat, enter: "rise", delay: 0.3 }),
    t(R / 2, -R / 2 + 2, String(s.r2), "lbl big down onstep", { from: s.squareBeat, enter: "rise", delay: 0.4 }),
    ...column(R + 26, [
      { text: "The circle holds", cls: "sm", from: s.areaBeat },
      { text: `${s.pi} squares`, cls: "lbl", from: s.areaBeat },
      ...broken(`${s.pi} × ${s.r2} = ${s.area}`, "lbl acc", s.areaBeat),
    ]),
  ];
  return { ...frame("circle", items, s.alt), camera: true };
}

export interface SectorSpec {
  mode: "sector" | "arc";
  r: number;
  /** the angle in degrees */
  t: number;
  /** "1/4": the fraction of the circle */
  fraction: string;
  /** the whole circle's area or circumference, and the part */
  whole: number; part: number; pi: string;
  fractionBeat: number; wholeBeat: number; partBeat: number;
  alt: string;
}

/** A slice of the circle (its area) or a piece of its edge (its length), as a fraction of the full turn. */
export function buildSector(s: SectorSpec): SceneDiagram {
  const R = RC;
  const items: Draft[] = [circle(R, "ln faint")];
  if (s.mode === "sector") {
    items.push(circle(R, "fill", { from: s.wholeBeat, until: s.partBeat - 1, enter: "fade" }));
    // a thick stroke on a half-radius arc fills the slice and can sweep open (as thick as the radius)
    items.push(path(arc(O, R / 2, 0, s.t), "pie", { from: s.fractionBeat, enter: "sweep", vars: { "--f": 1, strokeWidth: R } }));
  } else {
    items.push(circle(R, "ln", { from: s.wholeBeat, until: s.partBeat - 1, enter: "draw slow" }));
    items.push(path(arc(O, R, 0, s.t), "arcline", { from: s.fractionBeat, enter: "sweep", vars: { "--f": 1 } }));
  }
  items.push(seg(O, [R, 0], "ln2", { enter: "draw" }));
  items.push(t(R / 2, 5, `r = ${s.r}`, "lbl acc down", { enter: "rise", delay: 0.3 }));
  items.push(seg(O, polar(O, R, s.t), "ln2", { from: s.fractionBeat, enter: "draw", delay: 0.6 }));
  items.push(path(arc(O, 20, 0, s.t), "ax thin", { from: s.fractionBeat, enter: "draw", delay: 0.9 }));
  const at = angleLabelAt(O, 0, s.t, `${s.t}°`.length * 10.2, 42, R - 12);
  items.push(t(at[0], at[1], `${s.t}°`, "lbl", { from: s.fractionBeat, enter: "rise", delay: 1 }));
  const what = s.mode === "sector" ? "area" : "edge";
  items.push(...column(R + 26, [
    { text: `${s.t}° out of 360°`, cls: "lbl", from: s.fractionBeat },
    { text: `= ${s.fraction} of the circle`, cls: "sm", from: s.fractionBeat },
    { text: `whole ${what}: ${s.whole}`, cls: "sm", from: s.wholeBeat },
    { text: `${s.fraction} of the ${what}:`, cls: "sm", from: s.partBeat },
    { text: String(s.part), cls: "lbl acc", from: s.partBeat },
  ]));
  return { ...frame("circle", items, s.alt), camera: true };
}

export interface RadianSpec {
  /** the angle in degrees */
  t: number;
  /** size of one piece in degrees; the half turn holds 180 ÷ piece of them */
  piece: number;
  pieceBeat: number; angleBeat: number;
  /** the angle's text at each stage, e.g. "120°" and "2π/3" */
  pieceNote: string;
  answerNote: string;
  alt: string;
}

/** The half turn is π. Cut it into equal pieces; the angle is so many pieces of π. */
export function buildRadians(s: RadianSpec): SceneDiagram {
  const R = RC;
  const items: Draft[] = [
    circle(R, "ln faint"),
    seg(O, [R, 0], "ax"),
    path(arc(O, R, 0, 180), "ln2 dash", { enter: "draw" }),
    t(0, -R - 18, "half turn = 180° = π", "sm acc", { enter: "rise", delay: 0.4 }),
  ];
  const n = Math.round(360 / s.piece);
  for (let i = 1; i < n; i++) {
    const a = i * s.piece;
    items.push(seg(polar(O, R - 7, a), polar(O, R + 7, a), "tk", { from: s.pieceBeat, enter: "fade", delay: Math.min(1.2, i * 0.06) }));
  }
  items.push(path(arc(O, R, 0, s.t), "arcline", { from: s.angleBeat, enter: "sweep", vars: { "--f": 1 } }));
  items.push(seg(O, polar(O, R, s.t), "ln", { from: s.angleBeat, enter: "draw", delay: 0.6 }));
  const at = angleLabelAt(O, 0, s.t, `${s.t}°`.length * 10.2, 34, R - 10);
  items.push(t(at[0], at[1], `${s.t}°`, "lbl", { from: s.angleBeat, enter: "rise", delay: 0.8 }));
  // the piece note breaks after its colon ("30° pieces:" / "6 of them make π"): on one line it ran past the card at phone size
  const notes = s.pieceNote.split(/(?<=:) /);
  items.push(...column(R + 26, [
    ...notes.map(text => ({ text, cls: "sm", from: s.pieceBeat })),
    ...broken(s.answerNote, "lbl acc", s.angleBeat),
  ]));
  return { ...frame("circle", items, s.alt), camera: true };
}

export interface UnitCircleSpec {
  t: number;
  f: "sin" | "cos";
  quadrant: number;
  ref: number;
  /** "−1/2" */
  value: string;
  quadrantBeat: number; refBeat: number; valueBeat: number;
  alt: string;
}

const ROMAN = ["I", "II", "III", "IV"];

/** An angle on the unit circle with its reference angle; sine is the point's height, cosine its distance across. */
export function buildUnitCircle(s: UnitCircleSpec): SceneDiagram {
  const R = 66, P = polar(O, R, s.t), foot: Pt = [P[0], 0];
  const toward = s.quadrant === 2 || s.quadrant === 3 ? 180 : s.quadrant === 4 ? 360 : 0;
  const items: Draft[] = [
    seg([-R - 16, 0], [R + 16, 0], "ax"), seg([0, R + 16], [0, -R - 16], "ax"),
    circle(R, "ln faint"),
  ];
  // quadrant names in the corners outside the circle, the asked one lit at its beat
  for (let q = 1; q <= 4; q++) {
    const c = polar(O, R * 1.35, 45 + (q - 1) * 90);
    if (q === s.quadrant) items.push(t(c[0], c[1], ROMAN[q - 1]!, "lbl acc", { from: s.quadrantBeat, enter: "rise" }));
    items.push(t(c[0], c[1], ROMAN[q - 1]!, "xs", q === s.quadrant ? { until: s.quadrantBeat - 1 } : {}));
  }
  items.push(path(arc(O, 18, 0, s.t), "arcline thin", { from: s.quadrantBeat, enter: "sweep", vars: { "--f": 1 } }));
  items.push(seg(O, P, "ln", { from: s.quadrantBeat, enter: "draw", delay: 0.6 }));
  items.push({ type: "circle", cx: P[0], cy: P[1], r: 7, cls: "dotp", from: s.quadrantBeat, enter: "pop", delay: 1 } as Draft);
  // the turn's label sits out along its small arc, clear of the value written by the axis near the centre; in
  // quadrant I the turn is its own reference angle, so its label sits in the reference angle's spot and the lit
  // reference label takes over there (outside the circle it met the quadrant's name and the value on a phone)
  const rl: Pt = [(2 * P[0]) / 3, P[1] / 3];
  const tl = s.quadrant === 1 ? rl : polar(O, R * 0.8, s.t / 2);
  items.push(t(tl[0], tl[1], `${s.t}°`, "lbl", { from: s.quadrantBeat, ...(s.quadrant === 1 ? { until: s.refBeat - 1 } : {}), enter: "rise", delay: 1 }));
  // the reference angle: back to the nearest side of the x-axis, labelled inside its triangle
  items.push(seg(P, foot, "ln2 dash", { from: s.refBeat, enter: "draw" }));
  const [r0, r1] = [Math.min(s.t, toward), Math.max(s.t, toward)];
  items.push(path(arc(O, 26, r0, r1), "ln2", { from: s.refBeat, enter: "draw", delay: 0.3 }));
  items.push(t(rl[0], rl[1], `${s.ref}°`, "lbl acc", { from: s.refBeat, enter: "rise", delay: 0.5 }));
  // the value: a height for sine, a distance across for cosine
  const right = P[0] > 0, up = P[1] < 0;
  if (s.f === "sin") {
    items.push(seg(foot, P, "hlline", { from: s.valueBeat, enter: "draw" }));
    items.push(t(P[0] + (right ? 12 : -12), P[1] / 2, s.value, `lbl acc ${right ? "start" : "end"}`, { from: s.valueBeat, enter: "rise", delay: 0.4 }));
  } else {
    items.push(path([M(O), L(foot)], "hlline", { from: s.valueBeat, enter: "draw" }));
    // toward the foot, so it clears the two small arcs round the centre
    items.push(t(P[0] * 0.72, up ? 20 : -20, s.value, "lbl acc", { from: s.valueBeat, enter: "rise", delay: 0.4 }));
  }
  items.push(...column(R * 1.35 + 20, [
    { text: `quadrant ${ROMAN[s.quadrant - 1]}`, cls: "lbl", from: s.quadrantBeat },
    { text: `reference ${s.ref}°`, cls: "lbl acc", from: s.refBeat },
    ...broken(`${s.f} ${s.t}° = ${s.value}`, "lbl acc", s.valueBeat),
  ]));
  return { ...frame("circle", items, s.alt), camera: true };
}
