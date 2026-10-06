// The g9-radical picture (Curriculum fixes-02, Part B): a square of area n cut into k × k tiles of area m. Each tile's
// side is √m, so the big square's side is k of them: √n = k√m. Built on the area grid; no unit squares (the tiles are
// not whole-unit squares).
import { buildAreaGrid } from "../../../../explanations/diagrams/area-model/grid";
import type { SceneDiagram, SceneItem } from "../../../../explanations/diagrams/scene/schema";
import { r1 } from "../../../../explanations/diagrams/scene/helpers";

export function simplifyRootPicture(o: { k: number; m: number; n: number; square: number }): SceneDiagram {
  const { k, m, n, square } = o;
  const side = Array.from({ length: k }, () => ({ label: `√${m}`, size: 1, from: 2 }));
  const d = buildAreaGrid({
    family: "area-model",
    cols: side,
    rows: side,
    cells: Array.from({ length: k }, () => Array.from({ length: k }, () => ({ text: `${m}`, from: 1, color: 0 }))),
    maxWidth: 260,
    maxHeight: 260,
    lines: [
      { text: `${n} = ${square} × ${m}`, from: 1, until: 1 },
      { text: `√${square} = ${k} tiles along a side`, from: 2, until: 2 },
      { text: `√${n} = ${k}√${m}`, from: 3, cls: "lbl big acc" },
      { text: `check: (${k}√${m})² = ${square} × ${m} = ${n}`, from: 4, cls: "lbl pw" },
    ],
    alt: `A square of area ${n} cut into ${k} by ${k} tiles of area ${m}. Each tile's side is √${m}, so the square's side is ${k}√${m}.`,
  });
  const g = d.geometry, x0 = g.left, y0 = g.top, x1 = g.left + g.width, y1 = g.top + g.height;
  // the tiles cut in one by one, row by row; until then the square is one piece (no waiting boxes: it is not cut yet)
  let t = 0;
  const items: SceneItem[] = d.items.filter(i => !(i.type === "rect" && i.cls === "pend")).map(i => {
    if (i.type === "rect" && /^cell /.test(i.cls ?? "")) return { ...i, delay: r1(0.2 + 0.9 * (t++ / (k * k))) };
    return i;
  });
  items.unshift(
    { type: "rect", x: r1(x0), y: r1(y0), w: r1(g.width), h: r1(g.height), rx: 8, cls: "xbox p0", from: 0, enter: "pop" },
    { type: "text", x: r1((x0 + x1) / 2), y: r1((y0 + y1) / 2), text: `area ${n}`, cls: "lbl big p0", from: 0, until: 0, enter: "rise", delay: 0.4 },
  );
  // beat 2: one row of tiles lights up, its k sides along the top
  items.push({ type: "rect", x: r1(x0 - 3), y: r1(y0 - 3), w: r1(g.width + 6), h: r1(g.ys[1]! - y0 + 6), rx: 10, cls: "hlline", from: 2, until: 2, enter: "fade", delay: 0.2 });
  // beat 4: the check squares the side back into the whole area
  items.push({ type: "rect", x: r1(x0 - 3), y: r1(y0 - 3), w: r1(g.width + 6), h: r1(g.height + 6), rx: 10, cls: "hlline", from: 4, enter: "fade", delay: 0.2 });
  // beat 3: the side joins into k√m, a bracket down the right-hand side
  const xb = x1 + 8;
  items.push(
    { type: "path", d: `M${r1(xb)} ${r1(y0 + 2)} h8 V${r1(y1 - 2)} h-8`, cls: "ln thin pq", from: 3, enter: "draw" },
    { type: "text", x: r1(xb + 16), y: r1((y0 + y1) / 2), text: `${k}√${m}`, cls: "lbl big acc start", from: 3, enter: "rise", delay: 0.4 },
  );
  const width = Math.max(d.width, xb + 16 + `${k}√${m}`.length * 22 * 0.6 + 12);
  return { ...d, width: r1(width), items };
}
