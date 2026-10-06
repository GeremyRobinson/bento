// Things to count and choose from: a bag of marbles in one row per colour, or n labelled dots on a circle
// with every pair joined (choosing 2) or one chosen group shown in all its orders (choosing 3).
import type { SceneDiagram } from "../scene/schema";
import { frame, poly, polar, seg, t, type Draft, type Pt } from "../geo/kit";

const STEP = 34, RAD = 14;

export interface MarbleBagSpec {
  groups: { n: number; cls: string; name: string }[];
  /** index of the group we want */
  want: number;
  wantBeat: number; allBeat: number; chanceBeat: number;
  wantNote: string; allNote: string; chanceNote: string;
  alt: string;
}

export function buildMarbleBag(s: MarbleBagSpec): SceneDiagram {
  const items: Draft[] = [];
  let k = 0;
  s.groups.forEach((g, row) => {
    const y = row * 42;
    items.push(t(-14, y, `${g.n} ${g.name}`, "sm end", { enter: "rise" }));
    for (let i = 0; i < g.n; i++, k++) {
      const c = { type: "circle", cx: RAD + i * STEP, cy: y, r: RAD } as const;
      items.push({ ...c, cls: `marble ${g.cls}`, enter: "pop", delay: Math.min(1.5, k * 0.05) } as Draft);
      if (row === s.want) items.push({ ...c, cls: `marble ${g.cls} ring`, from: s.wantBeat, enter: "pop", delay: i * 0.06 } as Draft);
    }
  });
  const y = s.groups.length * 42 + 6;
  items.push(t(-80, y, s.wantNote, "lbl start", { from: s.wantBeat, until: s.allBeat - 1, enter: "rise" }));
  items.push(t(-80, y, s.allNote, "lbl start", { from: s.allBeat, until: s.chanceBeat - 1, enter: "rise" }));
  items.push(t(-80, y, s.chanceNote, "lbl acc start", { from: s.chanceBeat, enter: "rise" }));
  return frame("marbles", items, s.alt, 14, { w: 300 });
}

export interface ChooseSpec {
  n: number;
  k: 2 | 3;
  orderedBeat: number; ordersBeat: number; groupsBeat: number;
  orderedNote: string; ordersNote: string; groupsNote: string;
  alt: string;
}

const letter = (i: number) => String.fromCharCode(65 + i);

export function buildChoose(s: ChooseSpec): SceneDiagram {
  const R = 86, O: Pt = [0, 0];
  const pt = (i: number) => polar(O, R, 90 - (i * 360) / s.n);
  const items: Draft[] = [];
  // every pair joined once the repeats are removed (only drawn for pairs: groups of three would be a tangle)
  if (s.k === 2) {
    let j = 0;
    for (let a = 0; a < s.n; a++) for (let b = a + 1; b < s.n; b++, j++) items.push(seg(pt(a), pt(b), "ln thin", { from: s.groupsBeat, enter: "draw", delay: Math.min(2, j * 0.04) }));
    items.push(seg(pt(0), pt(1), "ln2", { from: s.orderedBeat, enter: "draw" }));
  } else {
    items.push(poly([pt(0), pt(1), pt(2)], "ln2 fillsoft", { from: s.orderedBeat, enter: "draw" }));
  }
  for (let i = 0; i < s.n; i++) {
    const [x, y] = pt(i);
    items.push({ type: "circle", cx: x, cy: y, r: 15, cls: "marble c0", enter: "pop", delay: i * 0.06 } as Draft);
    items.push(t(x, y, letter(i), "sm onlbl", { enter: "fade", delay: 0.1 + i * 0.06 }));
  }
  // the chosen group written in every order: they are all the same group
  const group = Array.from({ length: s.k }, (_, i) => letter(i));
  const perms = s.k === 2 ? [group.join(""), [...group].reverse().join("")] : ["ABC", "ACB", "BAC", "BCA", "CAB", "CBA"];
  const x0 = R + 46;
  items.push(t(x0, -60, s.orderedNote, "lbl start", { from: s.orderedBeat, enter: "rise" }));
  perms.forEach((p, i) => items.push(t(x0 + (i % 3) * 52, -22 + Math.floor(i / 3) * 26, p, "sm start", { from: s.ordersBeat, enter: "rise", delay: i * 0.1 })));
  items.push(t(x0, 38, s.ordersNote, "lbl start", { from: s.ordersBeat, enter: "rise", delay: 0.6 }));
  items.push(t(x0, 72, s.groupsNote, "lbl acc start", { from: s.groupsBeat, enter: "rise" }));
  return frame("marbles", items, s.alt);
}
