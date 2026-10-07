// Base-ten block pictures for 2nd grade: a number as hundreds flats, tens rods and ones cubes,
// and a two-digit subtraction where one rod is traded for ten cubes before anything is taken away.
import type { SceneDiagram } from "../scene/schema";
import { frame, t, type Draft } from "../geo/kit";
import { crossOut, cube, flat, line, rect, rod } from "./kit";

/** Width of a label in the picture's font, a little generous. */
export const tw = (s: string, size = 17) => [...s].length * size * 0.6 + 6;

export interface PlaceBlocksSpec {
  hundreds: number; tens: number; ones: number;
  beats: { hundreds: number; tens: number; ones: number; total: number };
  /** the line under each column and under the picture, shown from its beat */
  text: { hundreds: string; tens: string; ones: string; total: string };
  alt: string;
}

const S = 11, F = 10 * S, RG = 5, CG = 3, COL_GAP = 30, STEP = 12;

/** A three-digit number as blocks in three labelled columns; each column is ringed and counted on its beat. */
export function buildPlaceBlocks(spec: PlaceBlocksSpec): SceneDiagram {
  const { hundreds: h, tens: tn, ones: o, beats } = spec;
  if (![h, tn, o].every(v => Number.isInteger(v) && v >= 0 && v <= 9)) throw new Error("place blocks: digits 0 to 9");
  // the flats stand in one stack, each a step up and to the right of the one in front, so 9 hundreds fit in about two
  // flats' room and the picture keeps a size a phone can read (v43: rows of three made it tiny on a phone)
  const stack = h ? F + (h - 1) * STEP : 0, top = 34;
  const blocksH = Math.max(stack, 10 * S);
  const base = top + blocksH;
  const contentW = [stack, tn * (S + RG) - RG, Math.ceil(o / 5) * (S + CG) - CG];
  const names = ["hundreds", "tens", "ones"], texts = [spec.text.hundreds, spec.text.tens, spec.text.ones];
  const widths = contentW.map((w, i) => Math.max(w, tw(names[i]!), tw(texts[i]!), 40));
  const xs: number[] = [];
  widths.reduce((x, w) => (xs.push(x), x + w + COL_GAP), 0);
  const items: Draft[] = [];
  const colBeats = [beats.hundreds, beats.tens, beats.ones];
  widths.forEach((w, i) => {
    const cx = xs[i]! + w / 2;
    items.push(t(cx, 10, names[i]!, "sm"));
    if (i) items.push(line(xs[i]! - COL_GAP / 2, 0, xs[i]! - COL_GAP / 2, base + 8, "grid"));
    // the column being counted gets a ring for its beat
    items.push(rect(xs[i]! - 8, top - 8, w + 16, blocksH + 16, "hlline", { from: colBeats[i]!, until: colBeats[i]!, enter: "fade" }, 10));
    items.push(t(cx, base + 26, texts[i]!, `lbl p${i}`, { from: colBeats[i]!, enter: "rise", delay: 0.3 }));
  });
  // flats from the back of the stack to the front, the front one on the same floor as the rods
  const left0 = xs[0]! + (widths[0]! - contentW[0]!) / 2;
  for (let k = 0; k < h; k++) {
    const back = h - 1 - k;
    items.push(...flat(left0 + back * STEP, base - F - back * STEP, F, "cell c0", { enter: "pop", delay: 0.06 * k }));
  }
  const left1 = xs[1]! + (widths[1]! - contentW[1]!) / 2;
  for (let k = 0; k < tn; k++) items.push(...rod(left1 + k * (S + RG), base - 10 * S, S, "cell c1", { enter: "pop", delay: 0.2 + 0.05 * k }));
  // ones in columns of five, from the bottom up
  const left2 = xs[2]! + (widths[2]! - contentW[2]!) / 2;
  for (let k = 0; k < o; k++) {
    const col = Math.floor(k / 5), row = k % 5;
    items.push(...cube(left2 + col * (S + CG), base - (row + 1) * (S + CG) + CG, S, "cell c2", { enter: "pop", delay: 0.35 + 0.04 * k }));
  }
  const W = xs[2]! + widths[2]!;
  items.push(t(W / 2, base + 64, spec.text.total, "lbl big acc", { from: beats.total, enter: "rise" }));
  return frame("early-g2-blocks", items, spec.alt, 14, { w: 340 });
}

export interface TradeBlocksSpec {
  /** a − b, two digits each, with fewer ones in a than in b */
  a: number; b: number;
  beats: { blocks: number; trade: number; ones: number; tens: number; total: number };
  text: { start: string; trade: string; ones: string; tens: string; total: string };
  alt: string;
}

const T = 16, TG = 8;

/** Two-digit subtraction with blocks: one rod becomes ten ones, the ones are taken, then the tens. */
export function buildTradeBlocks(spec: TradeBlocksSpec): SceneDiagram {
  const { a, b, beats } = spec;
  const at = Math.floor(a / 10), ao = a % 10, bt = Math.floor(b / 10), bo = b % 10;
  if (!(ao < bo && bt < at)) throw new Error("trade blocks: a needs fewer ones than b and more tens");
  const top = 34, rodH = 10 * T, base = top + rodH;
  const tensW = Math.max(at * (T + TG) - TG, tw("tens"), tw(spec.text.tens)) + 16;
  const onesW = Math.max(2 * (T + TG) - TG, tw(spec.text.start), tw(spec.text.trade), tw(spec.text.ones)) + 16;
  const tensX = 0, onesX = tensW + 34;
  const items: Draft[] = [];
  items.push(t(tensX + tensW / 2, 10, "tens", "sm"), t(onesX + onesW / 2, 10, "ones", "sm"));
  items.push(line(onesX - 17, 0, onesX - 17, base + 8, "grid"));

  const rodsLeft = tensX + (tensW - (at * (T + TG) - TG)) / 2;
  const rx = (k: number) => rodsLeft + k * (T + TG);
  for (let k = 0; k < at; k++) {
    const traded = k === at - 1, taken = k >= at - 1 - bt && k < at - 1;
    const o = traded ? { until: beats.trade - 1, enter: "pop" as const, delay: 0.05 * k } : taken ? { until: beats.tens - 1, enter: "pop" as const, delay: 0.05 * k } : { enter: "pop" as const, delay: 0.05 * k };
    items.push(...rod(rx(k), top, T, "cell c0", o));
    if (traded) {
      // ringed while we decide to trade it, then only its outline is left behind
      items.push(rect(rx(k) - 4, top - 4, T + 8, rodH + 8, "hlline", { from: beats.blocks, until: beats.trade - 1, enter: "fade", delay: 0.6 }, 5));
      items.push(rect(rx(k), top, T, rodH, "wire", { from: beats.trade, enter: "fade" }));
    }
    if (taken) {
      items.push(...rod(rx(k), top, T, "seg cut", { from: beats.tens, enter: "fade" }));
      items.push(line(rx(k) - 3, base + 3, rx(k) + T + 3, top - 3, "ln2", { from: beats.tens, enter: "draw", delay: 0.15 * (k - (at - 1 - bt)) }));
    }
  }
  // ones: a's ones in the first column, the traded ten as a full second column
  const onesLeft = onesX + (onesW - (2 * (T + TG) - TG)) / 2;
  const cy = (row: number) => base - (row + 1) * T;
  for (let k = 0; k < ao; k++) items.push(...cube(onesLeft, cy(k), T, "cell c1", { enter: "pop", delay: 0.3 + 0.05 * k }));
  for (let k = 0; k < 10; k++) {
    const row = k, taken = row >= 10 - bo;
    items.push(...cube(onesLeft + T + TG, cy(row), T, "sq big", { from: beats.trade, ...(taken ? { until: beats.ones - 1 } : {}), enter: "rise", delay: 0.3 + 0.05 * k }));
    if (taken) items.push(...crossOut(onesLeft + T + TG, cy(row), T, T, beats.ones, 0.1 * (9 - row)));
  }
  const textY = base + 26;
  items.push(t(onesX + onesW / 2, textY, spec.text.start, "lbl", { from: beats.blocks, until: beats.trade - 1, enter: "rise", delay: 0.5 }));
  items.push(t(onesX + onesW / 2, textY, spec.text.trade, "lbl", { from: beats.trade, until: beats.ones - 1, enter: "rise", delay: 0.6 }));
  items.push(t(onesX + onesW / 2, textY, spec.text.ones, "lbl", { from: beats.ones, enter: "rise", delay: 0.6 }));
  items.push(t(tensX + tensW / 2, textY, spec.text.tens, "lbl", { from: beats.tens, enter: "rise", delay: 0.5 }));
  items.push(t((onesX + onesW) / 2, textY + 38, spec.text.total, "lbl big acc", { from: beats.total, enter: "rise" }));
  return frame("early-g2-blocks", items, spec.alt, 14, { w: 300 });
}
