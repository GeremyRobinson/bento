// A place-value grid for adding with regrouping: a tens column of rods and a ones column of unit squares.
// Ten ones become one rod that moves over to the tens. Every block is one of the problem's tens or ones.
import type { SceneDiagram, SceneItem } from "../scene/schema";
import { r1 } from "../scene/helpers";
import { textWidth } from "./grid";

export interface RegroupBlocksSpec {
  /** the two numbers being added (two digits each, ones adding to 10 or more) */
  a: number;
  b: number;
  beats: { blocks: number; ones: number; regroup: number; tens: number; total: number };
  /** text under each column and under the picture, by beat */
  text: { ones: string; regroup: string; tens: string; total: string };
  alt: string;
}

export const BLOCK = 16;
const GAP = 8;

export function buildRegroupBlocks(spec: RegroupBlocksSpec): SceneDiagram {
  const { a, b, beats } = spec;
  const at = Math.floor(a / 10), ao = a % 10, bt = Math.floor(b / 10), bo = b % 10, O = ao + bo;
  if (O < 10) throw new Error("regroup blocks: the ones must make a ten");
  const s = BLOCK, top = 44, rodH = 10 * s;
  const rods = at + bt + 1;
  const tensW = Math.max(rods * (s + GAP) + GAP, textWidth(spec.text.tens) + 20);
  const onesW = Math.max(2 * (s + GAP) + GAP, textWidth(spec.text.ones) + 20, textWidth(spec.text.regroup) + 20);
  const tensX = 12, onesX = tensX + tensW + 10;
  const items: SceneItem[] = [];
  items.push({ type: "text", x: r1(tensX + tensW / 2), y: 20, text: "tens", cls: "sm", from: beats.blocks, enter: "rise" });
  items.push({ type: "text", x: r1(onesX + onesW / 2), y: 20, text: "ones", cls: "sm", from: beats.blocks, enter: "rise" });
  items.push({ type: "line", x1: r1(onesX - 5), y1: 8, x2: r1(onesX - 5), y2: top + rodH + 8, cls: "ax thin", from: beats.blocks, enter: "fade" });

  // a rod is a column of ten squares, from the bottom up
  const rod = (x: number, cls: string, from: number, enter: SceneItem["enter"], delay: number) => {
    for (let k = 0; k < 10; k++) items.push({ type: "rect", x: r1(x), y: r1(top + rodH - (k + 1) * s), w: s, h: s, rx: 3, cls, from, enter, delay });
  };
  const rodsLeft = tensX + (tensW - rods * (s + GAP) + GAP) / 2;
  for (let i = 0; i < at + bt; i++) rod(rodsLeft + i * (s + GAP), `cell ${i < at ? "c0" : "c1"}`, beats.blocks, "pop", 0.1 + i * 0.08);
  rod(rodsLeft + (at + bt) * (s + GAP), "sq big", beats.regroup, "rise", 0.5);

  // ones fill columns of ten from the bottom; the first full column is the ten that moves
  const onesLeft = onesX + (onesW - 2 * (s + GAP) + GAP) / 2;
  const unit = (k: number, cls: string, from: number, until: number | undefined, delay: number) => {
    const col = Math.floor(k / 10), row = k % 10;
    items.push({ type: "rect", x: r1(onesLeft + col * (s + GAP)), y: r1(top + rodH - (row + 1) * s), w: s, h: s, rx: 3, cls, from, ...(until != null ? { until } : {}), enter: "pop", delay });
  };
  for (let k = 0; k < O; k++) unit(k, `cell ${k < ao ? "c0" : "c1"}`, beats.blocks, beats.regroup - 1, 0.1 + k * 0.04);
  // the ten they make, ringed as it leaves
  items.push({ type: "rect", x: r1(onesLeft - 3), y: r1(top - 3), w: s + 6, h: rodH + 6, rx: 5, cls: "hlline", from: beats.ones, until: beats.regroup - 1, enter: "fade", delay: 0.4 });
  // what is left drops into the first column
  for (let k = 0; k < O - 10; k++) unit(k, `cell ${10 + k < ao ? "c0" : "c1"}`, beats.regroup, undefined, 0.3 + k * 0.04);

  const textY = top + rodH + 26;
  items.push({ type: "text", x: r1(onesX + onesW / 2), y: textY, text: spec.text.ones, cls: "lbl", from: beats.ones, until: beats.regroup - 1, enter: "rise" });
  items.push({ type: "text", x: r1(onesX + onesW / 2), y: textY, text: spec.text.regroup, cls: "lbl", from: beats.regroup, enter: "rise" });
  items.push({ type: "text", x: r1(tensX + tensW / 2), y: textY, text: spec.text.tens, cls: "lbl", from: beats.tens, enter: "rise" });
  const width = Math.max(onesX + onesW + 12, textWidth(spec.text.total) + 24);
  items.push({ type: "text", x: r1(width / 2), y: textY + 32, text: spec.text.total, cls: "lbl acc", from: beats.total, enter: "rise" });
  return { kind: "scene", family: "area-model", width: r1(width), height: textY + 48, items, alt: spec.alt };
}
