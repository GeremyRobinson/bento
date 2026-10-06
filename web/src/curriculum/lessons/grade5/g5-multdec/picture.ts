// The g5-multdec picture (Curriculum fixes-02, Part B): x × y as a strip x wide and y tall laid on whole unit squares,
// each unit square cut into the small pieces the two numbers count (tenths by tenths: hundredths; tenths by wholes:
// tenths; hundredths by tenths: thousandths). The strip covers A pieces across and B up: A × B small pieces, so the
// digits of A × B count those pieces and the point goes that many places from the right. Built on the area grid.
import { buildAreaGrid } from "../../../../explanations/diagrams/area-model/grid";
import type { SceneDiagram, SceneItem } from "../../../../explanations/diagrams/scene/schema";
import { r1 } from "../../../../explanations/diagrams/scene/helpers";
import { formatNumber as f } from "../../../schemas/math-text";

const PLACE = ["ones", "tenths", "hundredths", "thousandths"];
/** a cut is drawn as lines only while they stay this far apart, in px */
const MIN_GAP = 3;

export function multiplyDecimalsPicture(o: { A: number; B: number; pa: number; pb: number; P: number; ans: number }): SceneDiagram {
  const { A, B, pa, pb, P, ans } = o;
  const sx = 10 ** -pa, sy = 10 ** -pb, x = A * sx, y = B * sy, n = pa + pb, piece = f(10 ** -n);
  const wholes = Math.ceil(x - 1e-9), tall = Math.ceil(y - 1e-9);
  const d = buildAreaGrid({
    family: "area-model",
    cols: [{ label: f(x), size: x, cls: "p0" }],
    // a strip less than 1 tall sits at the bottom of one row of unit squares; the room above it is the rest of them
    rows: y < tall ? [{ label: "", size: Math.round((tall - y) * 10) / 10 }, { label: f(y), size: y, cls: "p0" }] : [{ label: f(y), size: y, cls: "p0" }],
    cells: y < tall ? [[null], [{ from: 0, color: 0 }]] : [[{ from: 0, color: 0 }]],
    wholeOutlines: 0,
    minRow: 1,
    maxWidth: (360 * x) / wholes,
    maxHeight: tall > 1 ? 260 : 180,
    lines: [
      { text: `${A} × ${B} = ${P} small pieces`, from: 0, until: 0 },
      { text: `${f(sx)} × ${f(sy)} = ${piece}, ${n === 1 ? "one decimal place" : n === 2 ? "two decimal places" : "three decimal places"}`, from: 1, until: 1 },
      { text: `${P} ${PLACE[n]} = ${f(ans)}`, from: 2 },
    ],
    alt: `A strip ${f(x)} wide and ${f(y)} tall on whole unit squares, each cut into pieces of ${piece}. The strip covers ${A} by ${B} pieces: ${P} ${PLACE[n]}, ${f(ans)}.`,
  });
  const g = d.geometry, xs = g.left, top = g.ys[g.ys.length - 2]!, bottom = g.top + g.height;
  const items: SceneItem[] = d.items.filter(i => !(i.type === "text" && i.text === ""));
  // the cut inside the strip: a line every piece across and up, while the lines stay far enough apart to see
  const grid = (count: number, step: number, along: "x" | "y") => {
    if (step < MIN_GAP) return;
    for (let k = 1; k < count; k++) {
      const v = r1(along === "x" ? xs + k * step : top + k * step);
      items.push(along === "x"
        ? { type: "line", x1: v, y1: r1(top + 2), x2: v, y2: r1(bottom - 2), cls: "grid", from: 0, enter: "fade", delay: 0.3 }
        : { type: "line", x1: r1(xs + 2), y1: v, x2: r1(xs + g.width - 2), y2: v, cls: "grid", from: 0, enter: "fade", delay: 0.3 });
    }
  };
  const ux = g.unitX * sx, uy = g.unitY * sy;
  grid(A, ux, "x");
  grid(B, uy, "y");
  // beat 1: one piece ringed, and shown big beside the picture with its size
  const right = g.left + wholes * g.unitX, bx = right + 22, bs = 34, by = g.top;
  const rw = Math.max(ux, 4), rh = Math.max(uy, 4);
  items.push(
    { type: "rect", x: r1(xs - 3), y: r1(top - 3), w: r1(rw + 6), h: r1(rh + 6), rx: 3, cls: "xring", from: 1, until: 1, enter: "pop", delay: 0.2 },
    { type: "line", x1: r1(xs + rw + 3), y1: r1(top), x2: r1(bx), y2: r1(by + bs / 2), cls: "ln thin pq", from: 1, until: 1, enter: "draw", delay: 0.5 },
    { type: "rect", x: r1(bx), y: r1(by), w: bs, h: bs, rx: 4, cls: "xchip p0", from: 1, until: 1, enter: "pop", delay: 0.8 },
    { type: "text", x: r1(bx + bs / 2), y: r1(by + bs + 14), text: piece, cls: "sm acc", from: 1, until: 1, enter: "rise", delay: 1 },
  );
  // the count of pieces across
  items.push({ type: "text", x: r1(xs + g.width / 2), y: r1(bottom + 14), text: `${A} ${PLACE[pa]}`, cls: "lbl sm p0", from: 0, enter: "rise", delay: 0.6 });
  const width = Math.max(d.width, bx + Math.max(bs, piece.length * 9) + 14);
  return { ...d, width: r1(width), height: r1(d.height + 10), items: shiftLines(items, 10) };
}

/** moves the lines under the picture down, to make room for the count under the strip */
function shiftLines(items: SceneItem[], dy: number): SceneItem[] {
  return items.map(i => (i.type === "text" && /^lbl acc$/.test(i.cls ?? "") ? { ...i, y: r1(i.y + dy) } : i));
}
