// Things to count and choose from: a bag of marbles in one row per colour, or n labelled dots on a circle
// with every pair joined (choosing 2) or one chosen group shown in all its orders (choosing 3).
import type { SceneDiagram } from "../scene/schema";
import { frame, poly, polar, seg, t, type Draft, type Pt } from "../geo/kit";
import { giveWay, shortUp, spreadRows } from "../scene/picture-system";

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
  const R = 60, O: Pt = [0, 0];
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
  // the orders stand beside the circle and the notes under it, centred, one row each: a picture wider than tall like the
  // box it sits in (beside it, a note at a phone's label size ran past the edge: Review, landing at 390×844). Each note
  // hangs from its top (.down). They are the worked lines, so practice leaves them to the work list (.cap); in a phone's
  // short box the three are written on one line, each taking the last one's place as it comes (shortUp)
  const cols = s.k === 2 ? 1 : 2, rows = Math.ceil(perms.length / cols);
  perms.forEach((p, i) => items.push(t(R + 30 + (i % cols) * 44, (Math.floor(i / cols) - (rows - 1) / 2) * 26, p, "sm start", { from: s.ordersBeat, enter: "rise", delay: i * 0.1, vars: spreadRows(Math.floor(i / cols), rows, 26) })));
  const y0 = R + 26;
  const notes: [string, string, number, number][] = [[s.orderedNote, "lbl", s.orderedBeat, 0], [s.ordersNote, "lbl", s.ordersBeat, 0.6], [s.groupsNote, "lbl acc", s.groupsBeat, 0]];
  notes.forEach(([note, cls, beat, delay], i) => {
    const it = t(0, y0 + i * 30, note, `${cls} down cap`, { from: beat, enter: "rise", delay, vars: shortUp(i * 30) }), next = notes[i + 1];
    // in a short box it gives way as the next note comes
    items.push(...(next ? giveWay(it, next[2], next[3], s.groupsBeat) : [it]));
  });
  return frame("marbles", items, s.alt);
}
