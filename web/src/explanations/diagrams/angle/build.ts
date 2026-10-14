// Two angles that fill a right angle or a straight line, drawn at their real sizes from a shared corner.
import type { SceneDiagram } from "../scene/schema";
import { angleLabelAt, arc, frame, path, polar, seg, t, type Draft, type Pt } from "../geo/kit";

export interface AngleSpec {
  /** 90 for a right angle, 180 for a straight line */
  total: 90 | 180;
  /** the angle we know */
  part: number;
  /** beat the whole angle is named at, and beat the missing part is found at */
  wholeBeat: number;
  missingBeat: number;
  /** the note when the whole is named, e.g. "A right angle is 90°" */
  wholeNote: string;
  alt: string;
}

/** the arms: drawn at about a phone strip's size, so labels laid out at their phone size land where they are drawn */
const R = 100;

export function buildAngle(s: AngleSpec): SceneDiagram {
  const { total, part } = s;
  if (!(part > 0 && part < total)) throw new Error("the known angle must fit inside the whole");
  const O: Pt = [0, 0];
  const rest = total - part;
  const label = (d0: number, d1: number, text: string, minR: number): Pt => angleLabelAt(O, d0, d1, text.length * 10.2, minR, R + 46);
  const items: Draft[] = [
    seg(O, polar(O, R, 0), "ax", { enter: "draw" }),
    // the far arm is faint until the whole angle is named
    seg(O, polar(O, R, total), "ln faint dash", { until: s.wholeBeat - 1 }),
    seg(O, polar(O, R, total), "ax", { from: s.wholeBeat, enter: "draw" }),
    seg(O, polar(O, R, part), "ln", { enter: "draw", delay: 0.4 }),
    path(arc(O, 44, 0, part), "ln", { enter: "draw", delay: 0.8 }),
  ];
  const pl = label(0, part, `${part}°`, 64);
  items.push(t(pl[0], pl[1], `${part}°`, "lbl", { enter: "rise", delay: 1 }));
  if (total === 90) {
    const k = 16;
    items.push(path([{ c: "M", p: [k, 0] }, { c: "L", p: [k, -k] }, { c: "L", p: [0, -k] }], "ax thin", { from: s.wholeBeat, enter: "fade" }));
  }
  items.push(path(arc(O, 58, part, total), "ln2", { from: s.missingBeat, enter: "draw" }));
  const ml = label(part, total, `${rest}°`, 82);
  items.push(t(ml[0], ml[1], `${rest}°`, "lbl acc", { from: s.missingBeat, enter: "rise", delay: 0.3 }));
  items.push(t(ml[0], ml[1], "?", "lbl acc", { until: s.missingBeat - 1, enter: "fade" }));
  // the note stands on its bottom edge just above the arms and their labels, so on a phone it grows up, away from them
  const top = Math.min(polar(O, R, total)[1], polar(O, R, part)[1], pl[1] - 14, ml[1] - 14) - 14;
  const noteAt: Pt = total === 180 ? [0, top] : [R * 0.45, top];
  items.push(t(noteAt[0], noteAt[1], s.wholeNote, "sm up cap", { from: s.wholeBeat, until: s.missingBeat - 1, enter: "rise" }));
  items.push(t(noteAt[0], noteAt[1], `${part}° + ${rest}° = ${total}°`, "lbl acc up cap", { from: s.missingBeat, enter: "rise", delay: 0.6 }));
  return frame("angle", items, s.alt, 14, { w: 240 });
}
