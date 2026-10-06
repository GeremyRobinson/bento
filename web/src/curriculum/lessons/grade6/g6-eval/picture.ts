// The g6-eval picture (Curriculum fixes-02, Part B): ax means a copies of x, so swapping in the number makes a equal
// boxes of that size. Row 1 is a boxes of x, row 2 is b boxes of y, both on one scale (the longer product is the longer
// bar), and row 3 joins the two lengths into the total. Built on the tape.
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import type { SceneDiagram, SceneItem } from "../../../../explanations/diagrams/scene/schema";

/** Grade 6's second part colour is lime (too close to "right"), so y takes its third, orange. */
const SECOND = "p2";
/** when the letters in the boxes give way to their numbers, seconds into the beat */
const SWAP = 1.1;

export function evaluatePicture(o: { a: number; b: number; x: number; y: number; AX: number; BY: number; S: number }): SceneDiagram {
  const { a, b, x, y, AX, BY, S } = o;
  const d0 = buildTape({
    rows: [
      { length: AX, parts: a, fills: [{ a: 0, b: AX, tone: "on" }], each: [{ text: () => "x" }], label: [{ text: `x = ${x}` }], total: [{ text: `${AX}` }] },
      { length: BY, parts: b, fills: [{ a: 0, b: BY, tone: "two" }], each: [{ text: () => "y" }], label: [{ text: `y = ${y}` }], total: [{ text: `${BY}` }], from: 1 },
      { length: S, parts: 1, fills: [{ a: 0, b: AX, tone: "on" }, { a: AX, b: S, tone: "two" }], label: [{ text: "both" }], total: [{ text: `${S}`, acc: true }], from: 2 },
    ],
    guides: [{ at: AX, rows: [0, 2], from: 2 }],
    alt: `${a}x + ${b}y with x = ${x} and y = ${y}: ${a} boxes of ${x} make ${AX}, ${b} boxes of ${y} make ${BY}, and together they are ${S}.`,
  });
  const items: SceneItem[] = [];
  for (const it of d0.items) {
    // x's colour named outright, so the bar never takes a tint from around the picture
    if (it.type === "rect" && it.cls === "seg on") { items.push({ ...it, cls: "seg on p0" }); continue; }
    // y's colour
    if (it.type === "rect" && /\bseg on p1\b/.test(it.cls ?? "")) { items.push({ ...it, cls: (it.cls ?? "").replace(/\bp1\b/, SECOND) }); continue; }
    // in each box the letter shows first, then gives way to its number
    if (it.type === "text" && (it.text === "x" || it.text === "y")) {
      const beat = it.from ?? 0;
      const { enter: _e, ...still } = it;
      items.push({ ...still, until: beat, cls: `${it.cls} a-outsoon`, delay: SWAP + (it.delay ?? 0) });
      items.push({ ...it, text: String(it.text === "x" ? x : y), enter: "rise", delay: SWAP + 0.15 + (it.delay ?? 0) });
      continue;
    }
    // the products and the label show once the numbers are in
    if (it.type === "text" && /\blbl pw\b/.test(it.cls ?? "") && (it.from ?? 0) < 2) { items.push({ ...it, delay: SWAP + 0.5 }); continue; }
    items.push(it);
  }
  return { ...d0, items };
}
