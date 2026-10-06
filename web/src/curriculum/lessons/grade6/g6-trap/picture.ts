// The g6-trap picture (Curriculum fixes-02, Part B): a right trapezoid and its copy turned half way round make an
// (a + b) by h rectangle, so the trapezoid is half of it. Built on the area grid, like g6-tri.
import { buildAreaGrid } from "../../../../explanations/diagrams/area-model/grid";
import type { SceneDiagram, SceneItem } from "../../../../explanations/diagrams/scene/schema";
import { r1 } from "../../../../explanations/diagrams/scene/helpers";
import { aNum } from "../../../text";

export function trapezoidPicture(o: { a: number; b: number; h: number; S: number; P: number; A: number }): SceneDiagram {
  const { a, b, h, S, P, A } = o;
  const d = buildAreaGrid({
    family: "area-model",
    cols: [{ label: "", size: S }],
    rows: [{ label: `${h}`, size: h }],
    cells: [[null]],
    outlineFrom: 1,
    maxWidth: 400,
    maxHeight: 200,
    // a long flat trapezoid keeps a readable height (its height is labelled; the unit squares then stay off)
    minRow: 60,
    alt: `A trapezoid with bases ${a} and ${b} and height ${h}. A copy turned upside down fits against it to make ${aNum(S)} by ${h} rectangle of ${P}; the trapezoid is half: ${A}.`,
  });
  const g = d.geometry, u = g.unitX;
  const x0 = g.left, y0 = g.top, y1 = g.top + g.height, xr = x0 + S * u, ym = (y0 + y1) / 2;
  const pt = (x: number, y: number): [number, number] => [r1(x), r1(y)];
  const trap = [pt(x0, y1), pt(x0 + a * u, y1), pt(x0 + b * u, y0), pt(x0, y0)];
  // the copy is the trapezoid turned 180° about the middle of its slanted side
  const copy = [pt(xr, y0), pt(x0 + b * u, y0), pt(x0 + a * u, y1), pt(xr, y1)];
  const turn = { "--ox": `${r1(x0 + (S * u) / 2)}px`, "--oy": `${r1(ym)}px`, "--from": "180deg" };
  const items: SceneItem[] = [
    { type: "polygon", points: trap, cls: "tri c0", from: 0, enter: "pop" },
    { type: "polygon", points: copy, cls: "tri c2", from: 0, until: 1, enter: "swing", delay: 0.8, vars: turn },
    { type: "polygon", points: copy, cls: "hid", from: 2, enter: "fade" },
  ];
  // unit squares over both pieces, once they are one rectangle (only when a square is big enough to see)
  if (g.unitX >= 6 && g.toScale) {
    for (let k = 1; k < S; k++) items.push({ type: "line", x1: r1(x0 + k * u), y1: r1(y0), x2: r1(x0 + k * u), y2: r1(y1), cls: "grid", from: 1, until: 1, enter: "fade", delay: 0.3 });
    for (let k = 1; k < h; k++) items.push({ type: "line", x1: r1(x0), y1: r1(y0 + k * g.unitY), x2: r1(xr), y2: r1(y0 + k * g.unitY), cls: "grid", from: 1, until: 1, enter: "fade", delay: 0.3 });
  }
  const lbl = (x: number, y: number, text: string, cls: string, from: number, delay: number, until?: number): SceneItem =>
    ({ type: "text", x: r1(x), y: r1(y), text, cls, from, ...(until != null ? { until } : {}), enter: "rise", delay });
  // each piece's bases, on the side it lies on: the blue one first, the turned copy's once it lands
  items.push(
    lbl(x0 + (a * u) / 2, y1 + 16, `${a}`, "lbl p0", 0, 0.2),
    lbl(x0 + (b * u) / 2, y0 - 16, `${b}`, "lbl p0", 0, 0.3),
    lbl(x0 + a * u + (b * u) / 2, y1 + 16, `${b}`, "lbl p2", 0, 1.8, 1),
    lbl(x0 + b * u + (a * u) / 2, y0 - 16, `${a}`, "lbl p2", 0, 1.8, 1),
    // the trapezoid's area sits in its own middle once the copy is gone
    lbl(x0 + ((a + b) * u) / 4, ym, `${A}`, "lbl big acc", 2, 0.5),
  );
  // what the beat works out, under the picture
  const yLine = y1 + 46;
  items.push(
    lbl(x0 + (S * u) / 2, yLine, `${a} + ${b} = ${S}`, "lbl acc", 0, 2, 0),
    lbl(x0 + (S * u) / 2, yLine, `${S} × ${h} = ${P}`, "lbl acc", 1, 0.4, 1),
    lbl(x0 + (S * u) / 2, yLine, `${P} ÷ 2 = ${A}`, "lbl acc", 2, 0.6),
  );
  return { ...d, items: [...d.items.filter(i => !(i.type === "text" && i.text === "")), ...items], height: r1(yLine + 20) };
}
