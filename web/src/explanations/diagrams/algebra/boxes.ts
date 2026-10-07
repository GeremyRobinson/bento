// Expression boxes (Curriculum fixes-02, Part B): an expression drawn as nested rounded boxes, one box per operation,
// so you can see what belongs together before you calculate. Each beat is a short series of stages: a box lights up,
// may open (a power into a repeated product, a function into its rule), then collapses into a chip holding its value,
// and the box around it now holds a simpler expression, written on the next line down like working on paper.
// Every tree, value and stage comes from the lesson's problem; this only lays them out and times them.
import type { SceneDiagram, SceneItem } from "../scene/schema";
import { r1 } from "../scene/helpers";

/** One piece of an expression. */
export type XNode =
  /** plain text: a number, an operator, a bracket; ink unless `cls` says otherwise */
  | { t: "text"; text: string; sup?: string; cls?: string }
  /** a value, filled in its part colour (`pq`: the answer, outlined in the accent) */
  | { t: "chip"; text: string; sup?: string; part?: string; id?: string; /** the node with this id in the stage before became this chip (kept for the lessons' own records) */ from?: string; pop?: boolean }
  /** an operation: a rounded box around its parts */
  | {
    t: "box"; kids: XNode[]; part?: string; id?: string;
    /** a function's name on a tab above the box, e.g. "f" */
    name?: string;
    /** a small line under the box, e.g. its rule "f(x) = 2x + 1" or "unchanged" */
    under?: string;
    /** room kept for an under line that another stage on the same line shows (not drawn) */
    room?: string;
    /** an exponent at the box's top right, e.g. "3" in ( )³ */
    sup?: string;
    /** a dashed outline (an inside part that stays as it is) */
    dash?: boolean;
    /** outlined in the accent: the box this stage is about */
    lit?: boolean;
  };

/** One look of the expression. Stages of the same beat play one after another, `at` seconds into the beat. */
export interface XStage { beat: number; at?: number; tree: XNode[] }

const ROW_GAP = 14, FS = 22, CH = 0.6 * FS, SUP = 0.65 * FS * 0.6, GAP = 8, PAD_X = 10, PAD_Y = 9, TAB = 22, UNDER = 28, CHIP_H = 36;
const textW = (s: string, sup?: string) => s.length * CH + (sup ? sup.length * SUP + 2 : 0);
const underW = (s: string) => s.length * 15 * 0.6;

interface Size { w: number; up: number; down: number }
function size(n: XNode): Size {
  if (n.t === "text") return { w: textW(n.text, n.sup), up: FS / 2 + 2, down: FS / 2 + 2 };
  if (n.t === "chip") return { w: textW(n.text, n.sup) + 22, up: CHIP_H / 2, down: CHIP_H / 2 };
  const ks = n.kids.map(size);
  const inner = ks.reduce((s, k) => s + k.w, 0) + GAP * Math.max(0, ks.length - 1);
  const up = Math.max(FS / 2, ...ks.map(k => k.up)) + PAD_Y, down = Math.max(FS / 2, ...ks.map(k => k.down)) + PAD_Y;
  const supW = n.sup ? n.sup.length * 13 + 6 : 0;
  const u = n.under ?? n.room;
  const w = Math.max(inner + 2 * PAD_X, n.name ? n.name.length * CH + 24 : 0, u ? underW(u) + 8 : 0) + supW;
  return { w, up: up + (n.name ? TAB : 0) + (n.sup ? 4 : 0), down: down + (u ? UNDER : 0) };
}

interface Placed { id?: string; cx: number; cy: number }

type Chip = Extract<XNode, { t: "chip" }>;
/** Draws one stage's tree with its left edge at x and its middle line at y; returns the items (each chip's items tagged
    with its chip) and where each id went. */
function place(nodes: XNode[], x: number, y: number, part: string): { items: SceneItem[]; tags: (Chip | undefined)[]; at: Placed[] } {
  const items: SceneItem[] = [], tags: (Chip | undefined)[] = [], at: Placed[] = [];
  let cx = x;
  for (const n of nodes) {
    const s = size(n);
    if (n.t === "text") {
      items.push({ type: "text", x: r1(cx + s.w / 2), y: r1(y), text: n.text, ...(n.sup ? { sup: n.sup } : {}), cls: n.cls ?? `lbl big pw` });
    } else if (n.t === "chip") {
      const w = s.w, cls = n.part === "pq" ? "xchip pq" : `xchip ${n.part ?? part}`;
      items.push({ type: "rect", x: r1(cx), y: r1(y - CHIP_H / 2), w: r1(w), h: CHIP_H, rx: CHIP_H / 2, cls });
      items.push({ type: "text", x: r1(cx + w / 2), y: r1(y), text: n.text, ...(n.sup ? { sup: n.sup } : {}), cls: n.part === "pq" ? "lbl big acc" : "lbl big onlbl" });
      tags[items.length - 2] = n; tags[items.length - 1] = n;
      at.push({ id: n.id, cx: cx + w / 2, cy: y });
    } else {
      const ks = n.kids.map(size), p = n.part ?? part;
      const up = Math.max(FS / 2, ...ks.map(k => k.up)) + PAD_Y, down = Math.max(FS / 2, ...ks.map(k => k.down)) + PAD_Y;
      const supW = n.sup ? n.sup.length * 13 + 6 : 0, w = s.w - supW;
      const inner = ks.reduce((t, k) => t + k.w, 0) + GAP * Math.max(0, ks.length - 1);
      if (n.lit) items.push({ type: "rect", x: r1(cx - 5), y: r1(y - up - 5), w: r1(w + 10), h: r1(up + down + 10), rx: 16, cls: "hlline" });
      items.push({ type: "rect", x: r1(cx), y: r1(y - up), w: r1(w), h: r1(up + down), rx: 12, cls: `xbox ${p}${n.dash ? " dash" : ""}` });
      if (n.name) items.push({ type: "text", x: r1(cx + 6), y: r1(y - up - TAB / 2 - 1), text: n.name, cls: `lbl start ${p}` });
      if (n.sup) items.push({ type: "text", x: r1(cx + w + 3), y: r1(y - up + 4), text: n.sup, cls: `lbl start ${p}` });
      if (n.under) items.push({ type: "text", x: r1(cx + w / 2), y: r1(y + down + UNDER / 2 + 3), text: n.under, cls: `sm ${p}` });
      const kid = place(n.kids, cx + (w - inner) / 2, y, p);
      kid.tags.forEach((c, k) => { if (c) tags[items.length + k] = c; });
      items.push(...kid.items);
      at.push({ id: n.id, cx: cx + w / 2, cy: y }, ...kid.at);
    }
    cx += s.w + GAP;
  }
  return { items, tags, at };
}

const width = (nodes: XNode[]) => nodes.map(size).reduce((s, k) => s + k.w, 0) + GAP * Math.max(0, nodes.length - 1);

/**
 * Builds the picture as written working: a stack of lines (G 19:34 "most problems should either be in a stack or a grid").
 * A stage that changes the expression writes it on a new line under the last, rising in; a stage that only lights a
 * different box lights it on its own line. Lines never move once drawn; earlier lines dim when a later beat starts.
 */
export function buildExprBoxes(o: { stages: XStage[]; alt: string; family?: string; minWidth?: number; /** the expression as written, shown muted above the boxes the whole time */ header?: string; /** a second muted line under it, e.g. the rules the boxes use */ rules?: string }): SceneDiagram {
  const { stages } = o;
  if (!stages.length) throw new Error("expression boxes need a stage");
  const HEAD = (o.header ? 40 : 0) + (o.rules ? 26 : 0);
  const W = Math.max(o.minWidth ?? 300, ...stages.map(s => width(s.tree) + 24), ...[o.header, o.rules].map(t => (t ? t.length * 17 * 0.6 + 24 : 0)));
  const items: SceneItem[] = [];
  if (o.header) items.push({ type: "text", x: r1(W / 2), y: 18, text: o.header, cls: "lbl muted", enter: "fade" });
  if (o.rules) items.push({ type: "text", x: r1(W / 2), y: (o.header ? 40 : 0) + 18, text: o.rules, cls: "lbl muted", enter: "fade" });
  // which stages share a line: the same expression, whatever box is lit
  const bare = (t: XNode[]) => JSON.stringify(t, (k, v) => (k === "lit" || k === "from" || k === "pop" || k === "id" || k === "under" || k === "room" ? undefined : v));
  const rows: { first: number; stages: number[] }[] = [];
  stages.forEach((s, i) => {
    if (!rows.length || bare(s.tree) !== bare(stages[rows.at(-1)!.first]!.tree)) rows.push({ first: i, stages: [i] });
    else rows.at(-1)!.stages.push(i);
  });
  const extent = (t: XNode[]) => { const k = t.map(size); return { up: Math.max(FS / 2, ...k.map(z => z.up)), down: Math.max(FS / 2, ...k.map(z => z.down)) }; };
  const lastBeat = Math.max(...stages.map(s => s.beat));
  let y = HEAD + 10, last = 0;
  rows.forEach((row, r) => {
    const first = stages[row.first]!, e = extent(fit(first.tree, roomFor(row.stages.map(j => stages[j]!.tree)), false));
    y += (r ? ROW_GAP : 0) + e.up;
    const B = first.beat, A = first.at ?? 0, next = rows[r + 1] ? stages[rows[r + 1]!.first]! : undefined;
    // a line dims once a later beat starts with a newer line already written
    const dimAt = next ? Math.max(B + 1, next.beat + ((next.at ?? 0) > 0 ? 1 : 0)) : undefined;
    const dimFrom = dimAt != null && dimAt <= lastBeat ? dimAt : undefined;
    // every stage on the line is laid out with the same room, so its lit box and under line land on the line's boxes
    const room = roomFor(row.stages.map(j => stages[j]!.tree));
    const shape = (t: XNode[], under: boolean) => fit(t, room, under);
    const base = shape(first.tree, false), x0 = (W - width(base)) / 2;
    const plain = place(base, x0, y, "pw");
    plain.items.forEach((it, k) => {
      const chip = plain.tags[k];
      const enter: Partial<SceneItem> = chip?.pop ? { enter: "pop", delay: A + 0.15 } : { enter: "rise", delay: A };
      items.push({ ...it, ...enter, from: B, ...(dimFrom != null ? { until: dimFrom - 1 } : {}) } as SceneItem);
      if (dimFrom != null) items.push({ ...it, cls: `${it.cls ?? ""} dimmed`.trim(), from: dimFrom } as SceneItem);
    });
    // each stage's lit box: on from its moment until the next stage's
    row.stages.forEach(j => {
      const s = stages[j]!, after = stages[j + 1], at = s.at ?? 0;
      // its lit box and its under lines (a rule, or a note like "unchanged") come and go on their own
      const lit = place(shape(s.tree, true), x0, y, "pw").items.filter(it => /\bhlline\b/.test(it.cls ?? "") || /^sm\b/.test(it.cls ?? ""));
      for (const it of lit) {
        if (!after) { items.push({ ...it, from: s.beat, enter: "fade", delay: at }); continue; }
        const out = after.at ?? 0;
        if (after.beat === s.beat) { items.push({ ...it, from: s.beat, until: s.beat, enter: "flash", delay: at, vars: { "--d2": `${out.toFixed(2)}s` } }); continue; }
        items.push({ ...it, from: s.beat, until: after.beat - 1, enter: "fade", delay: at });
        if (out > 0) items.push({ ...it, cls: `${it.cls} a-outsoon`, from: after.beat, until: after.beat, delay: out });
      }
    });
    y += e.down;
    last = y;
  });
  return { kind: "scene", family: o.family ?? "expression-boxes", width: r1(W), height: r1(last + 10), items, alt: o.alt };
}

/** the longest under line each box has across the stages of one line, by the box's place in the tree */
function roomFor(trees: XNode[][]): Map<string, string> {
  const room = new Map<string, string>();
  const walk = (t: XNode[], path: string) => t.forEach((n, i) => {
    if (n.t !== "box") return;
    const k = `${path}.${i}`;
    if (n.under && n.under.length > (room.get(k)?.length ?? 0)) room.set(k, n.under);
    walk(n.kids, k);
  });
  trees.forEach(t => walk(t, ""));
  return room;
}
/** the tree laid out with that room: no box lit, and its under lines kept (under) or only made room for */
function fit(t: XNode[], room: Map<string, string>, under: boolean, path = ""): XNode[] {
  return t.map((n, i) => {
    if (n.t !== "box") return n;
    const k = `${path}.${i}`, { under: u, ...rest } = n;
    return { ...rest, lit: under ? n.lit : false, room: room.get(k), ...(under && u ? { under: u } : {}), kids: fit(n.kids, room, under, k) };
  });
}
