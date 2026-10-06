// The g5-multdec picture (Curriculum fixes-02, Part B): x × y as a strip x wide and y tall laid on whole unit squares,
// each unit square cut 10 by 10 into hundredths. The strip covers A tenths across and B tenths up: A × B tiny squares,
// each a hundredth, so the digits of A × B count hundredths. Built on the area grid with a tenth grid.
import { buildAreaGrid } from "../../../../explanations/diagrams/area-model/grid";
import type { SceneDiagram, SceneItem } from "../../../../explanations/diagrams/scene/schema";
import { r1 } from "../../../../explanations/diagrams/scene/helpers";
import { formatNumber as f } from "../../../schemas/math-text";

export function multiplyDecimalsPicture(o: { A: number; B: number; P: number; ans: number }): SceneDiagram {
  const { A, B, P, ans } = o;
  const x = A / 10, y = B / 10, wholes = Math.ceil(x);
  const d = buildAreaGrid({
    family: "area-model",
    cols: [{ label: f(x), size: x, cls: "p0" }],
    // the strip sits at the bottom of one row of unit squares; the room above it is the rest of each unit square
    rows: [{ label: "", size: Math.round((10 - B)) / 10 }, { label: f(y), size: y, cls: "p0" }],
    cells: [[null], [{ from: 0, color: 0 }]],
    units: 0,
    unitStep: 0.1,
    wholeOutlines: 0,
    minRow: 1,
    maxWidth: (360 * x) / wholes,
    maxHeight: 180,
    lines: [
      { text: `${A} × ${B} = ${P} tiny squares`, from: 0, until: 0 },
      { text: "0.1 × 0.1 = 0.01, two decimal places", from: 1, until: 1 },
      { text: `${P} hundredths = ${f(ans)}`, from: 2 },
    ],
    alt: `A strip ${f(x)} wide and ${f(y)} tall on whole unit squares, each cut into 100 tiny squares of 0.01. The strip covers ${A} by ${B} tiny squares: ${P} hundredths, ${f(ans)}.`,
  });
  const g = d.geometry, u = g.unitX / 10, xs = g.left, ys = g.ys[1]!;
  const items: SceneItem[] = d.items.filter(i => !(i.type === "text" && i.text === ""));
  // beat 1: one tiny square ringed, and shown big beside the picture: 0.01
  const right = g.left + wholes * g.unitX, bx = right + 22, bs = 34, by = g.top;
  items.push(
    { type: "rect", x: r1(xs - 3), y: r1(ys - 3), w: r1(u + 6), h: r1(u + 6), rx: 3, cls: "xring", from: 1, until: 1, enter: "pop", delay: 0.2 },
    { type: "line", x1: r1(xs + u + 3), y1: r1(ys), x2: r1(bx), y2: r1(by + bs / 2), cls: "ln thin pq", from: 1, until: 1, enter: "draw", delay: 0.5 },
    { type: "rect", x: r1(bx), y: r1(by), w: bs, h: bs, rx: 4, cls: "xchip p0", from: 1, until: 1, enter: "pop", delay: 0.8 },
    { type: "text", x: r1(bx + bs / 2), y: r1(by + bs + 14), text: "0.01", cls: "sm acc", from: 1, until: 1, enter: "rise", delay: 1 },
  );
  // the count of tiny squares across and up
  items.push(
    { type: "text", x: r1(xs + g.width / 2), y: r1(g.ys[2]! + 14), text: `${A} tenths`, cls: "lbl sm p0", from: 0, enter: "rise", delay: 0.6 },
  );
  const width = Math.max(d.width, bx + bs + 14);
  return { ...d, width: r1(width), height: r1(d.height + 10), items: shiftLines(items, 10) };
}

/** moves the lines under the picture down, to make room for the count under the strip */
function shiftLines(items: SceneItem[], dy: number): SceneItem[] {
  return items.map(i => (i.type === "text" && /^lbl acc$/.test(i.cls ?? "") ? { ...i, y: r1(i.y + dy) } : i));
}
