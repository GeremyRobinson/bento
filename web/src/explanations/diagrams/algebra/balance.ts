// The balance picture (the current app's `balance()`): two pans on a beam, x tiles and number blocks on each.
// Frames are computed from the equation's values; each frame is one beat, and the same operation is done to both pans.
import { formatNumber } from "../../../curriculum/schemas/math-text";
import type { SceneDiagram, SceneItem } from "../scene/schema";

/** One thing on a pan. `off` marks what is being taken off both sides this beat (drawn struck out). */
export type Weight =
  | { kind: "x"; off?: boolean }
  /** a number block; negative numbers are drawn dashed (they pull the pan up). `late` blocks pop in after the strike-outs. */
  | { kind: "n"; value: number; off?: boolean; added?: boolean; late?: boolean }
  /** a piece of x, such as x ÷ 4 */
  | { kind: "part"; label: string; off?: boolean }
  /** a y tile in the second part colour; −y is drawn dashed (it pulls the pan up), like a negative block */
  | { kind: "y"; neg?: boolean; off?: boolean };

/** A pan's load as groups: a group stays together on one row, and groups sit a little apart. */
export type Pan = Weight[][];

export interface BalanceFrame {
  left: Pan;
  right: Pan;
  /** the line above the beam for this beat, e.g. "take 5 off both sides" */
  note: string;
}

export const BALANCE = {
  width: 540,
  panWidth: 228,
  tile: 40,
  gap: 6,
  groupGap: 14,
  noteY: 22,
  /** room above the tallest stack for the note */
  top: 44,
} as const;

const xs = (n: number): Weight[] => Array.from({ length: n }, () => ({ kind: "x" }));
/** n x tiles in one group. */
export const xTiles = (n: number, off = false): Weight[] => xs(n).map(w => (off ? { ...w, off } : w));
export const block = (value: number, extra: { off?: boolean; added?: boolean; late?: boolean } = {}): Weight => ({ kind: "n", value, ...extra });

const labelOf = (w: Weight) => (w.kind === "x" ? "x" : w.kind === "y" ? (w.neg ? "−y" : "y") : w.kind === "n" ? formatNumber(w.value) : w.label);
/** Width of a tile: x tiles are square, blocks grow with their label. */
export const weightWidth = (w: Weight) =>
  w.kind === "x" || w.kind === "y" ? BALANCE.tile : w.kind === "n" ? Math.max(BALANCE.tile, 18 + labelOf(w).length * 12) : Math.max(52, 16 + labelOf(w).length * 10);

interface Placed { w: Weight; x: number; row: number; width: number }

/** Packs groups into rows no wider than a pan, bottom row first; a group too wide for a row is split. */
export function packPan(pan: Pan): { placed: Placed[]; rows: number } {
  const { panWidth, gap, groupGap } = BALANCE;
  const units: Weight[][] = pan.flatMap(g => {
    const wid = g.reduce((s, w) => s + weightWidth(w) + gap, -gap);
    if (wid <= panWidth) return [g];
    const out: Weight[][] = [[]];
    let used = -gap;
    for (const w of g) {
      if (used + gap + weightWidth(w) > panWidth && out[out.length - 1]!.length) { out.push([]); used = -gap; }
      out[out.length - 1]!.push(w);
      used += gap + weightWidth(w);
    }
    return out;
  }).filter(g => g.length);
  const rows: Weight[][][] = [];
  let used = 0;
  for (const g of units) {
    const wid = g.reduce((s, w) => s + weightWidth(w) + gap, -gap);
    const row = rows[rows.length - 1];
    if (row && used + groupGap + wid <= panWidth) { row.push(g); used += groupGap + wid; }
    else { rows.push([g]); used = wid; }
  }
  const placed: Placed[] = [];
  rows.forEach((row, r) => {
    const total = row.reduce((s, g) => s + g.reduce((t, w) => t + weightWidth(w) + gap, -gap) + groupGap, -groupGap);
    let x = -total / 2;
    row.forEach(g => {
      g.forEach(w => { placed.push({ w, x, row: r, width: weightWidth(w) }); x += weightWidth(w) + gap; });
      x += groupGap - gap;
    });
  });
  return { placed, rows: rows.length };
}

/** Builds the balance from its frames. Frame i shows at beat i (the last frame stays). */
export function buildBalance(frames: BalanceFrame[], alt: string): SceneDiagram {
  const { width: W, panWidth, tile, gap, noteY, top } = BALANCE;
  const packed = frames.map(f => ({ left: packPan(f.left), right: packPan(f.right) }));
  const maxRows = Math.max(1, ...packed.flatMap(p => [p.left.rows, p.right.rows]));
  const beamY = top + maxRows * (tile + gap) + gap;
  const H = beamY + 110;
  const cxL = (W - 2 * panWidth - 36) / 2 + panWidth / 2, cxR = W - cxL;

  const items: SceneItem[] = [
    { type: "path", d: `M${W / 2} ${beamY} L${W / 2 - 26} ${H - 14} H${W / 2 + 26} Z`, cls: "fulcrum" },
    { type: "line", x1: cxL - panWidth / 2, y1: beamY, x2: cxR + panWidth / 2, y2: beamY, cls: "beam" },
    { type: "line", x1: cxL, y1: beamY, x2: cxL, y2: beamY + 6, cls: "ax" },
    { type: "line", x1: cxR, y1: beamY, x2: cxR, y2: beamY + 6, cls: "ax" },
  ];
  frames.forEach((f, i) => {
    const last = i === frames.length - 1;
    const when = { from: i, ...(last ? {} : { until: i }) };
    const side = (p: { placed: Placed[] }, cx: number) => {
      for (const { w, x, row, width } of p.placed) {
        const left = cx + x, y = beamY - gap - (row + 1) * tile - row * gap;
        const cls = w.kind === "n" ? `tile n${w.value < 0 ? " dash" : ""}` : w.kind === "y" ? `tile y${w.neg ? " dash" : ""}` : "tile x";
        // what is left once the same thing comes off both pans is the answer: it shows only after the strike-outs
        const late = w.kind === "n" && w.late ? { enter: "pop" as const, delay: 1 } : null;
        items.push({ type: "rect", x: left, y, w: width, h: tile, rx: 9, cls, ...when, enter: w.kind === "n" && w.added ? "pop" : "fade", ...late });
        items.push({
          type: "text", x: left + width / 2, y: y + tile / 2, text: labelOf(w),
          cls: w.kind === "x" ? "lbl onlbl" : w.kind === "y" ? (w.neg ? "lbl p1" : "lbl onlbl") : w.kind === "part" ? "sm onlbl" : w.added ? "lbl acc" : "lbl", ...when, enter: "fade", ...late,
        });
        if (w.off) items.push({ type: "line", x1: left - 3, y1: y + tile + 3, x2: left + width + 3, y2: y - 3, cls: "ln2", ...when, enter: "draw", delay: 0.5 });
      }
    };
    side(packed[i]!.left, cxL);
    side(packed[i]!.right, cxR);
    items.push({ type: "text", x: W / 2, y: noteY, text: f.note, cls: "lbl acc", ...when, enter: "fade" });
  });
  return { kind: "scene", family: "balance", width: W, height: H, items, alt };
}
