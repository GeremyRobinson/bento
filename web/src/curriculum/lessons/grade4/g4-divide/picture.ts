// The g4-divide and g5-divide picture (Curriculum fixes-02, Part B): dividing is filling a rectangle of height dv with
// area n. A big column of T (tens) goes in first, then a column of O (ones) fills what is left; with a remainder, r unit
// squares are left beside it, too few to make another column. Built on the area grid; the columns are not to scale
// (the O column holds a readable width), but the remainder's squares are: dv of them would make a full column.
import { buildAreaGrid } from "../../../../explanations/diagrams/area-model/grid";
import type { SceneDiagram, SceneItem } from "../../../../explanations/diagrams/scene/schema";
import { r1 } from "../../../../explanations/diagrams/scene/helpers";

/** Grade 4's third part colour is rose (too close to "wrong"), so the two columns take its first two. */
const CT = 0, CO = 1;

export function divisionAreaPicture(o: { n: number; dv: number; T: number; O: number; left: number; q: number; r?: number }): SceneDiagram {
  const { n, dv, T, O, left, q, r } = o;
  const hasR = r != null;
  // with a remainder, one unit square is 18 high, so the r squares can be measured against the column's height
  const unit = hasR ? 18 : Math.min(14, 160 / dv);
  const d = buildAreaGrid({
    family: "area-model",
    cols: [{ label: `${T}`, size: T, cls: "p0" }, { label: `${O}`, size: O, from: 2, cls: "p1" }],
    rows: [{ label: `${dv}`, size: dv }],
    cells: [[{ text: `${dv * T}`, from: 0, color: CT }, { text: `${dv * O}`, from: 2, color: CO }]],
    maxWidth: hasR ? 330 : 360,
    maxHeight: 240,
    minRow: Math.max(60, dv * unit),
    alt: hasR
      ? `${n} ÷ ${dv} as a rectangle ${dv} high: a column ${T} wide holds ${dv * T}, a column ${O} wide holds ${dv * O}, and ${r} ${r === 1 ? "square is" : "squares are"} left over, too few to make another column. ${q} R ${r}.`
      : `${n} ÷ ${dv} as a rectangle ${dv} high: a column ${T} wide holds ${dv * T}, then a column ${O} wide holds the ${left} left. ${T} + ${O} = ${q}.`,
  });
  const g = d.geometry;
  const x0 = g.left, xm = g.xs[1]!, xr = g.xs[2]!, y0 = g.top, y1 = g.top + g.height;
  const items: SceneItem[] = [];
  const lbl = (x: number, y: number, text: string, cls: string, from: number, delay: number, until?: number): SceneItem =>
    ({ type: "text", x: r1(x), y: r1(y), text, cls, from, ...(until != null ? { until } : {}), enter: "rise", delay });
  // beat 1: the part still to fill is labelled with what is left
  items.push(lbl((xm + xr) / 2, (y0 + y1) / 2, `${left}`, "lbl muted", 1, 0.4, 1));
  // beat 3: the two widths join under the rectangle into the answer
  const yb = y1 + 10;
  items.push({ type: "path", d: `M${r1(x0 + 2)} ${r1(yb)} v8 H${r1(xr - 2)} v-8`, cls: "ln thin pq", from: 3, enter: "draw" });
  // the remainder: r unit squares stacked beside the rectangle, against a dashed column of dv that they cannot fill
  let right = xr;
  if (hasR) {
    const s = g.height / dv, xs = xr + 14;
    right = xs + s;
    items.push({ type: "rect", x: r1(xs), y: r1(y0), w: r1(s), h: r1(g.height), rx: 3, cls: "pend", from: 4, enter: "fade" });
    for (let k = 0; k < r!; k++) {
      items.push({ type: "rect", x: r1(xs + 1.5), y: r1(y1 - (k + 1) * s + 1.5), w: r1(s - 3), h: r1(s - 3), rx: 3, cls: "xchip pq", from: 4, enter: "pop", delay: 0.4 + 0.15 * k });
    }
    if (r! > 0) items.push(lbl(xs + s / 2, y0 - 16, `${r}`, "lbl acc", 4, 0.5 + 0.15 * r!));
  }
  // what each beat works out, one line under the picture
  const yl = yb + 34, cx = (x0 + xr) / 2;
  const lines: [string, number][] = [
    [`${dv} × ${T} = ${dv * T}`, 0],
    [`${n} − ${dv * T} = ${left}`, 1],
    [`${dv} × ${O} = ${dv * O}`, 2],
    [`${T} + ${O} = ${q}`, 3],
    ...(hasR ? [[r ? `${r} left over: ${q} R ${r}` : `0 left over: ${q} R 0`, 4] as [string, number]] : []),
  ];
  const last = lines.length - 1;
  lines.forEach(([text, b], k) => items.push(lbl(cx, yl, text, "lbl acc", b, b === 0 ? 0.6 : 0.4, k === last ? undefined : b)));
  const lineW = Math.max(...lines.map(([t]) => t.length * 17 * 0.6));
  const width = Math.max(right + 14, cx + lineW / 2 + 12);
  return { ...d, width: r1(width), height: r1(yl + 22), items: [...d.items, ...items] };
}
