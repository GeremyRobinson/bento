// Counting pictures for 2nd grade: dots put into pairs (even and odd), coins counted on by value,
// and an array of dots in rows and columns.
import type { SceneDiagram } from "../scene/schema";
import { frame, t, type Draft } from "../geo/kit";
import { circle, rect } from "./kit";
import { tw } from "./blocks";

export interface PairsSpec {
  n: number;
  beats: { pairs: number; left: number; verdict: number };
  /** the line under the pairs once they are made, the one about the leftover and the answer */
  text: { pairs: string; left: string; verdict: string };
  alt: string;
}

const PX = 38, PY = 32, R = 10;

/** n dots in one row, then the same dots in pairs (two to a column), with any leftover dot marked. */
export function buildPairs(spec: PairsSpec): SceneDiagram {
  const { n, beats } = spec;
  if (!Number.isInteger(n) || n < 1 || n > 30) throw new Error("pairs: 1 to 30 dots");
  const pairs = Math.floor(n / 2), odd = n % 2 === 1;
  const cols = pairs + (odd ? 1 : 0), W = (cols - 1) * PX;
  const items: Draft[] = [];
  // the row as counted: dots spread across the same width
  const rowGap = 26, rowLeft = W / 2 - ((n - 1) * rowGap) / 2;
  for (let k = 0; k < n; k++) items.push(circle(rowLeft + k * rowGap, PY / 2, R, "dotp", { until: beats.pairs - 1, enter: "pop", delay: 0.03 * k }));
  for (let k = 0; k < pairs; k++) {
    const x = k * PX, d = 0.12 * k;
    items.push(rect(x - R - 5, -R - 5, 2 * R + 10, PY + 2 * R + 10, "wire", { from: beats.pairs, enter: "fade", delay: d + 0.2 }, R + 5));
    items.push(circle(x, 0, R, "dotp", { from: beats.pairs, enter: "pop", delay: d }), circle(x, PY, R, "dotp", { from: beats.pairs, enter: "pop", delay: d + 0.05 }));
    items.push(t(x, PY + R + 22, String(k + 1), "xs", { from: beats.pairs, enter: "fade", delay: d + 0.3 }));
  }
  if (odd) {
    const x = pairs * PX;
    items.push(circle(x, 0, R, "dotp", { from: beats.pairs, until: beats.left - 1, enter: "pop", delay: 0.12 * pairs }));
    items.push(circle(x, 0, R, "dota", { from: beats.left, enter: "pop" }));
    items.push(rect(x - R - 5, -R - 5, 2 * R + 10, PY + 2 * R + 10, "hlline", { from: beats.left, enter: "fade", delay: 0.2 }, R + 5));
  }
  const y = PY + R + 56;
  items.push(t(W / 2, y, spec.text.pairs, "lbl", { from: beats.pairs, until: beats.left - 1, enter: "rise", delay: 0.4 }));
  items.push(t(W / 2, y, spec.text.left, "lbl", { from: beats.left, enter: "rise", delay: 0.3 }));
  items.push(t(W / 2, y + 36, spec.text.verdict, "lbl big acc", { from: beats.verdict, enter: "rise" }));
  return frame("early-g2-pairs", items, spec.alt, 14, { w: Math.max(320, tw(spec.text.left) + 30) });
}

/** The four coins, with the look each one gets: real things keep their real colors (silver, and a copper penny), not
    picture roles, so no coin looks like "the unknown" (handoff-6). */
export const COINS = {
  25: { name: "quarter", r: 30, cls: "coin ag" },
  10: { name: "dime", r: 21, cls: "coin ag" },
  5: { name: "nickel", r: 26, cls: "coin ag" },
  1: { name: "penny", r: 23, cls: "coin cu" },
} as const;
export type CoinValue = keyof typeof COINS;

export interface CoinsSpec {
  /** how many of each coin, largest value first */
  groups: { value: CoinValue; count: number; beat: number }[];
  total: string;
  totalBeat: number;
  /** a practice picture: just the coins, no counting */
  bare?: boolean;
  alt: string;
}

/** Coins in a row, biggest value first. On each group's beat the running total appears under every coin. */
export function buildCoins(spec: CoinsSpec): SceneDiagram {
  const items: Draft[] = [];
  let x = 0, running = 0, idx = 0;
  const MAXR = 30;
  spec.groups.forEach((g, gi) => {
    if (gi) x += 22;
    const c = COINS[g.value];
    const left = x;
    for (let k = 0; k < g.count; k++) {
      const cx = x + c.r;
      running += g.value;
      items.push(circle(cx, MAXR, c.r, c.cls, { enter: "pop", delay: 0.06 * idx++ }));
      items.push(t(cx, MAXR, `${g.value}¢`, "sm"));
      if (!spec.bare) items.push(t(cx, 2 * MAXR + 24, String(running), k === g.count - 1 ? "lbl acc" : "sm", { from: g.beat, enter: "rise", delay: 0.35 * k }));
      x += 2 * c.r + 8;
    }
    const name = g.count === 1 ? c.name : c.name === "penny" ? "pennies" : `${c.name}s`;
    items.push(t((left + x - 8) / 2, -14, name, "xs"));
  });
  const W = x - 8;
  if (!spec.bare) items.push(t(W / 2, 2 * MAXR + 66, spec.total, "lbl big acc", { from: spec.totalBeat, enter: "rise" }));
  return frame("early-g2-coins", items, spec.alt, 14, { w: 320 });
}

export interface ArraySpec {
  rows: number; cols: number;
  beats: { rows: number; cols: number; total: number };
  total: string;
  bare?: boolean;
  alt: string;
}

const AG = 40, AR = 11;

/** Dots in rows and columns. Rows are ringed and numbered, one row is counted, then each row adds its count. */
export function buildArray(spec: ArraySpec): SceneDiagram {
  const { rows, cols, beats } = spec;
  const items: Draft[] = [];
  const W = (cols - 1) * AG;
  for (let r = 0; r < rows; r++) {
    const y = r * AG;
    if (!spec.bare) {
      items.push(rect(-AR - 7, y - AR - 7, W + 2 * AR + 14, 2 * AR + 14, "wire", { from: beats.rows, enter: "fade", delay: 0.2 * r }, AR + 7));
      items.push(t(-AR - 30, y, `row ${r + 1}`, "xs", { from: beats.rows, enter: "fade", delay: 0.2 * r }));
      // the running total at the end of every row
      items.push(t(W + AR + 34, y, String((r + 1) * cols), r === rows - 1 ? "lbl acc" : "lbl", { from: beats.total, enter: "rise", delay: 0.35 * r }));
    }
    for (let c = 0; c < cols; c++) items.push(circle(c * AG, y, AR, "dotp", { enter: "pop", delay: 0.03 * (r * cols + c) }));
  }
  if (!spec.bare) {
    // the first row counted, one number over each dot
    items.push(rect(-AR - 7, -AR - 7, W + 2 * AR + 14, 2 * AR + 14, "hlline", { from: beats.cols, until: beats.cols, enter: "fade" }, AR + 7));
    for (let c = 0; c < cols; c++) items.push(t(c * AG, -AR - 22, String(c + 1), "sm", { from: beats.cols, until: beats.cols, enter: "rise", delay: 0.15 * c }));
    items.push(t(W / 2, (rows - 1) * AG + 54, spec.total, "lbl big acc", { from: beats.total, enter: "rise", delay: 0.35 * rows }));
  }
  return frame("early-g2-array", items, spec.alt, 14, { w: spec.bare ? 0 : Math.max(320, tw(spec.total, 22) + 20) });
}
