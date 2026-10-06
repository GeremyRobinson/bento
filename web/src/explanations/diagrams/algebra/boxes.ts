// Expression boxes (Curriculum fixes-02, Part B): an expression drawn as nested rounded boxes, one box per operation,
// so you can see what belongs together before you calculate. Each beat is a short series of stages: a box lights up,
// may open (a power into a repeated product, a function into its rule), then collapses into a chip holding its value,
// and the box around it now holds a simpler expression. A chip can slide from where a node sat in the stage before.
// Every tree, value and stage comes from the lesson's problem; this only lays them out and times them.
import type { Enter, SceneDiagram, SceneItem } from "../scene/schema";
import { r1 } from "../scene/helpers";

/** One piece of an expression. */
export type XNode =
  /** plain text: a number, an operator, a bracket; ink unless `cls` says otherwise */
  | { t: "text"; text: string; sup?: string; cls?: string }
  /** a value, filled in its part colour (`pq`: the answer, outlined in the accent) */
  | { t: "chip"; text: string; sup?: string; part?: string; id?: string; /** slides in from where the node with this id was in the stage before */ from?: string; pop?: boolean }
  /** an operation: a rounded box around its parts */
  | {
    t: "box"; kids: XNode[]; part?: string; id?: string;
    /** a function's name on a tab above the box, e.g. "f" */
    name?: string;
    /** a small line under the box, e.g. its rule "f(x) = 2x + 1" or "unchanged" */
    under?: string;
    /** an exponent at the box's top right, e.g. "3" in ( )³ */
    sup?: string;
    /** a dashed outline (an inside part that stays as it is) */
    dash?: boolean;
    /** outlined in the accent: the box this stage is about */
    lit?: boolean;
  };

/** One look of the expression. Stages of the same beat play one after another, `at` seconds into the beat. */
export interface XStage { beat: number; at?: number; tree: XNode[] }

const FS = 22, CH = 0.6 * FS, SUP = 0.65 * FS * 0.6, GAP = 8, PAD_X = 10, PAD_Y = 9, TAB = 22, UNDER = 28, CHIP_H = 36;
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
  const w = Math.max(inner + 2 * PAD_X, n.name ? n.name.length * CH + 24 : 0, n.under ? underW(n.under) + 8 : 0) + supW;
  return { w, up: up + (n.name ? TAB : 0) + (n.sup ? 4 : 0), down: down + (n.under ? UNDER : 0) };
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
 * Builds the picture. Within a beat each stage fades in at its `at` and gives way to the next; the last stage of a beat
 * stays, and the next beat opens on its own first stage (usually the same expression, shown without an entrance).
 */
export function buildExprBoxes(o: { stages: XStage[]; alt: string; family?: string; minWidth?: number; /** the expression as written, shown muted above the boxes the whole time */ header?: string }): SceneDiagram {
  const { stages } = o;
  if (!stages.length) throw new Error("expression boxes need a stage");
  const sizes = stages.map(s => s.tree.map(size));
  const up = Math.max(...sizes.flat().map(k => k.up)), down = Math.max(...sizes.flat().map(k => k.down));
  const HEAD = o.header ? 40 : 0;
  const W = Math.max(o.minWidth ?? 300, ...stages.map(s => width(s.tree) + 24), o.header ? o.header.length * 17 * 0.6 + 24 : 0), y = HEAD + up + 10;
  const items: SceneItem[] = [];
  if (o.header) items.push({ type: "text", x: r1(W / 2), y: 18, text: o.header, cls: "lbl muted", enter: "fade" });
  let prev: Placed[] = [];
  stages.forEach((s, i) => {
    const at = s.at ?? 0, next = stages[i + 1], sameBeat = next && next.beat === s.beat;
    const firstOfAll = i === 0, enters = firstOfAll || at > 0;
    const laid = place(s.tree, (W - width(s.tree)) / 2, y, "pw");
    // when it shows within its beat: in at `at` (a fade, or nothing when the beat opens on it), out when the next stage comes
    const timing = (it: SceneItem): SceneItem => {
      const base: SceneItem = { ...it, from: s.beat, ...(next ? { until: s.beat } : {}) };
      if (sameBeat && enters) return { ...base, enter: "flash", delay: at, vars: { ...it.vars, "--d2": `${(next.at ?? 0).toFixed(2)}s` } };
      if (sameBeat) return { ...base, cls: `${it.cls ?? ""} a-outsoon`.trim(), delay: next.at ?? 0 };
      return enters ? { ...base, enter: "fade" as Enter, delay: at } : base;
    };
    laid.items.forEach((it, k) => {
      let t = timing(it);
      const chip = laid.tags[k];
      // a chip that is this beat's result pops in; one that moves slides from where its node was in the stage before
      if (chip && !sameBeat && (enters || chip.pop || chip.from)) {
        const src = chip.from ? prev.find(p => p.id === chip.from) : undefined;
        const me = laid.at.find(p => p.id === chip.id);
        // a slide that waits (at > 0) also fades in, so the chip isn't already sitting at its start while it waits
        // (review v45 blocker 3: g's value showed over g's input from the start of the beat)
        if (src && me) t = { ...t, ...(at > 0 ? { cls: `${t.cls ?? ""} late`.trim() } : {}), enter: "slide", delay: at, vars: { "--dx": `${r1(src.cx - me.cx)}px`, "--dy": `${r1(src.cy - me.cy)}px` } };
        else if (chip.pop) t = { ...t, enter: "pop", delay: at + 0.15 };
      }
      items.push(t);
    });
    prev = laid.at;
  });
  return { kind: "scene", family: o.family ?? "expression-boxes", width: r1(W), height: r1(y + down + 10), items, alt: o.alt };
}
